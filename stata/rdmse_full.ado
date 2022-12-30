capture program drop rdmse_full
program define rdmse_full, eclass
	syntax anything [if] [in] [, c(real 0) fuzzy(string) covs(string) vce(string) kernel(string) scaleregul(real 1) deriv(real 0)] minpol(real) maxpol(real) lowestpol(real)
	
	marksample touse
	
	preserve
	qui keep if `touse'
	
	tokenize "`anything'"
	local y `1'
	local x `2'
	
	qui count
	scalar N = r(N)
	
	if "`fuzzy'"=="" {
		forvalues pol = 1/`maxpol' {
			rdbwselect `y' `x', p(`pol') covs(`covs') vce(`vce') c(`c') kernel(`kernel') scaleregul(`scaleregul') deriv(`deriv')
			local hbw = e(h_mserd)
			local bbw = e(b_mserd)
			rdmses `y' `x', h(`hbw') b(`bbw') p(`pol') c(`c')
			scalar amse`pol' = e(amse_cl)
			* if e(amse_cl)==. scalar amse`pol'=0
		}
	}
	
	if "`fuzzy'"!="" {
		forvalues pol = 1/`maxpol' {
			rdbwselect `y' `x', p(`pol') covs(`covs') vce(`vce') c(`c') fuzzy(`fuzzy') kernel(`kernel') scaleregul(`scaleregul') deriv(`deriv')
			local hbw = e(h_mserd)
			local bbw = e(b_mserd)
			rdmsef `y' `x', h(`hbw') b(`bbw') p(`pol') c(`c') fuzzy(`fuzzy')
			scalar amse`pol' = e(amse_F_cl)
			* if e(amse_F_cl)==. scalar amse`pol'=0
		}
	}

* return amse differences of polynomial pairs and create scalar list for bootstrap procedure

	forvalues pol = `minpol'/`maxpol' {
		if `pol' != `lowestpol' {
			ereturn scalar amse`lowestpol'`pol'= amse`lowestpol' - amse`pol'
		}
	}
	
	restore
	
	ereturn scalar N = N
	
end
