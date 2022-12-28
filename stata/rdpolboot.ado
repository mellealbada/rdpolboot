* install sub commands
	* rdmse
	* rdbwselect
* bootstrap options
* create graph
* warning if there are missing amses (and how many of each pol)
* error list:
	* error if minpol or maxpol are not set
	* follow errors from sub commands? 
* ereturn scalar command
* new ado's for sub commands
* clean bootstrap results table

set seed 5234234

cd "D:\RDData\RDHonest\Meyersson"
use regdata0.dta, clear
gen x = rnormal()
// drop if x > -1.3

program drop _all

program define lowestamsepol, eclass
	syntax anything [, c(real 0) fuzzy(string) covs(string) vce(string) kernel(string)] minpol(real) maxpol(real)
	tokenize "`anything'"
	
	local y `1'
	local x `2'
	
	scalar lowestamse = .
	scalar lowestpol = .

	if "`fuzzy'"=="" {
		forvalues pol = `minpol'/`maxpol' {
			qui rdbwselect `y' `x', p(`pol') c(`c') covs(`covs') vce(`vce') kernel(`kernel')
			local hbw = e(h_mserd)
			local bbw = e(b_mserd)
			qui rdmses `y' `x', h(`hbw') b(`bbw') p(`pol') c(`c')
		
			scalar amse_p`pol' = e(amse_cl)
			di "AMSE for polynomial order `pol' is " amse_p`pol'
		
			if e(amse_cl) < lowestamse {
				scalar lowestamse = e(amse_cl)
				scalar lowestpol = `pol'
			}
		}
	}
	
	if "`fuzzy'"!="" {
		forvalues pol = `minpol'/`maxpol' {
			qui rdbwselect `y' `x', p(`pol') c(`c') covs(`covs') vce(`vce') kernel(`kernel')
			local hbw = e(h_mserd)
			local bbw = e(b_mserd)
			qui rdmsef `y' `x', h(`hbw') b(`bbw') p(`pol') c(`c')
		
			scalar amse_p`pol' = e(amse_F_cl)
			di "AMSE for polynomial order `pol' is " amse_p`pol'
		
			if e(amse_cl) < lowestamse {
				scalar lowestamse = e(amse_F_cl)
				scalar lowestpol = `pol'
			}
		}
	}
	
	ereturn clear
	
	ereturn scalar lowest_amse = lowestamse
	ereturn scalar lowest_pol = lowestpol
	
	local lowestpol = lowestpol
	local elist // initialize elist

	forvalues pol = `minpol'/`maxpol' {
		if `pol' != `lowestpol' {
			local elist `elist' e(amse`lowestpol'`pol') // add scalar to elist
		}
	}

	ereturn local elist "`elist'"

end

program define rdmse_full, eclass
	syntax anything [if] [in] [, c(real 0) fuzzy(string) covs(string) vce(string) kernel(string) scalepar(real 1) deriv(real 0)] minpol(real) maxpol(real) lowestpol(real)
	
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
			rdbwselect `y' `x', p(`pol') covs(`covs') vce(`vce') c(`c') kernel(`kernel')
			local hbw = e(h_mserd)
			local bbw = e(b_mserd)
			rdmses `y' `x', h(`hbw') b(`bbw') p(`pol') c(`c')
			scalar amse`pol' = e(amse_cl)
			if e(amse_cl)==. scalar amse`pol'=0
		}
	}
	
	if "`fuzzy'"!="" {
		forvalues pol = 1/`maxpol' {
			rdbwselect `y' `x', p(`pol') covs(`covs') vce(`vce') c(`c') fuzzy(`fuzzy')
			local hbw = e(h_mserd)
			local bbw = e(b_mserd)
			rdmsef `y' `x', h(`hbw') b(`bbw') p(`pol') c(`c') fuzzy(`fuzzy')
			scalar amse`pol' = e(amse_F_cl)
			if e(amse_F_cl)==. scalar amse`pol'=0
		}
	}
	
	
	ereturn clear

* return amse differences of polynomial pairs and create scalar list for bootstrap procedure

	forvalues pol = `minpol'/`maxpol' {
		if `pol' != `lowestpol' {
			ereturn scalar amse`lowestpol'`pol'= amse`lowestpol' - amse`pol'
		}
	}

	ereturn scalar N = N
	
	restore
	
end

program define rdpolbootplot, eclass
	syntax anything [, accell_off]
	
	preserve 
	
	if "`accell_off'" == "" {
		matrix m = ( e(ci_bca) \ e(b) )
	}
	else if "`accell_off'" == "" {
		matrix m = ( e(ci_bc) \ e(b) )
	}
	matrix m = m'
	svmat m
	
	tokenize "`anything'"
	local minpol `1'
	local maxpol `2'
	local lowestpol `3'

	gen rdpolbootid = _n
	
	local polc = 1
	forvalues pol = `minpol'/`maxpol' {
		if `pol' != `lowestpol' {
			label def rdpolbootid `polc' "p`lowestpol'p`pol'", modify
			local ++polc
		}
	}	

	label values rdpolbootid rdpolbootid

	local maxin = `maxpol'-`minpol'
	numlist "1/`maxin'"
	local maxinlist `r(numlist)'
	
	twoway (rcap m1 m2 rdpolbootid in 1/`maxin', horizontal xline(0)) (scatter rdpolbootid m3 in 1/`maxin'), ylabel(`maxinlist', valuelabel) legend(off) ytitle("Polynomial Order Pair") xtitle("Difference in AMSE")

	restore
	
end

program define rdpolboot, eclass
	syntax anything [if] [in] [, accell_off plot c(real 0) fuzzy(string) covs(string) vce(string) kernel(string) scalepar(real 1) deriv(real 0)] minpol(real) maxpol(real) reps(real)
	
	marksample touse
	
	preserve
	qui keep if `touse'
	
	tokenize "`anything'"
	local y `1'
	local x `2'
	
	lowestamsepol `y' `x', minpol(`minpol') maxpol(`maxpol')
	local elist = e(elist)
	local lowestpol = e(lowest_pol)
	
	if "`accell_off'" == "" {
		bootstrap `elist', notable noheader nolegend nowarn reps(`reps') bca jackknifeopts(n(e(N))): rdmse_full `y' `x', minpol(`minpol') maxpol(`maxpol') lowestpol(`lowestpol')
		estat bootstrap, bca
	}
	else if "`accell_off'" != "" {
		bootstrap `elist', notable noheader nolegend nowarn reps(`reps'): rdmse_full `y' `x', minpol(`minpol') maxpol(`maxpol') lowestpol(`lowestpol')		
		estat bootstrap
	}
	
	if `"`plot'"' != "" {
	 	rdpolbootplot `minpol' `maxpol' `lowestpol', `accell_off'
	}
		
	restore
	
end

rdpolboot hischshr1520f iwm94, minpol(1) maxpol(4) reps(500) plot accell_off
