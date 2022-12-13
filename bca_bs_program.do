putexcel set results, sheet(coefs) replace
putexcel A1 = "polynomial"
putexcel B1 = "estimate"
putexcel C1 = "std_err"
putexcel D1 = "pvalue"
putexcel E1 = "ci_left"
putexcel F1 = "ci_right"
putexcel G1 = "bandwidth"
putexcel H1 = "observations"

forvalues pol = 1/4 {
	rdrobust left_school dist_from_cut, vce(cluster clustervar) p(`pol') covs($controls)
	scalar est = e(tau_cl)
	scalar stderr = e(se_tau_cl)
	scalar pval = e(pv_rb)
	scalar ci_l = e(ci_l_rb)
	scalar ci_r = e(ci_r_rb)
	scalar bw = e(h_l)
	scalar obs = e(N_h_l) + e(N_h_r)
	local row = `pol'+1
	putexcel A`row' = `pol'
	putexcel B`row' = est
	putexcel C`row' = stderr
	putexcel D`row' = pval
	putexcel E`row' = ci_l
	putexcel F`row' = ci_r
	putexcel G`row' = bw
	putexcel H`row' = obs
}

program drop _all
program define rdmse_full, eclass
	syntax anything [if] [in] [, c(real 0) covs(string) vce(string) fuzzy(string)]
	
	marksample touse
	
	preserve
	qui keep if `touse'
	
	tokenize "`anything'"
	local y `1'
	local x `2'
	
	qui count
	scalar N = r(N)
	
	if "`fuzzy'"=="" {
		forvalues pol = 1/4 {
			rdbwselect `y' `x', p(`pol') covs(`covs') vce(`vce') c(`c')
			local hbw = e(h_mserd)
			local bbw = e(b_mserd)
			rdmses `y' `x', h(`hbw') b(`bbw') p(`pol') c(`c')
			scalar amse`pol' = e(amse_cl)
			if e(amse_cl)==. scalar amse`pol'=0
		}
	}
	
	if "`fuzzy'"!="" {
		forvalues pol = 1/4 {
			rdbwselect `y' `x', p(`pol') covs(`covs') vce(`vce') c(`c') fuzzy(`fuzzy')
			local hbw = e(h_mserd)
			local bbw = e(b_mserd)
			rdmsef `y' `x', h(`hbw') b(`bbw') p(`pol') c(`c') fuzzy(`fuzzy')
			scalar amse`pol' = e(amse_F_cl)
			if e(amse_F_cl)==. scalar amse`pol'=0
		}
	}
	
	
	ereturn clear
	
	ereturn scalar amse12 = amse1 - amse2
	ereturn scalar amse13 = amse1 - amse3
	ereturn scalar amse14 = amse1 - amse4
	ereturn scalar amse23 = amse2 - amse3
	ereturn scalar amse24 = amse2 - amse4
	ereturn scalar amse34 = amse3 - amse4
	
	ereturn scalar N = N
	
	restore
end

bootstrap e(amse12) e(amse13) e(amse14) e(amse23) e(amse24) e(amse34), reps(15000) bca jackknifeopts(n(e(N))) saving(lindo_bs, replace): rdmse_full left_school dist_from_cut, vce(cluster clustervar) covs($controls)
estat bootstrap

putexcel set results, sheet(cis) modify

putexcel A1 = "original"
matrix coef = e(b)'
matrix ci = e(ci_bca)'
putexcel A2 = matrix(coef)
putexcel B1 = matrix(ci), colnames

putexcel set results, sheet(output) modify
putexcel A1 = emat


/*
// rdmse_full hischshr1520f iwm94

local hbw = e(h_l)
local bbw = e(b_l)
rdmses leader_next winmargin_loc if winmargin_loc!=0 & (electionmargin_loc==-1|electionmargin_loc==0), p(`pol') h(`hbw') b(`bbw')
*/
