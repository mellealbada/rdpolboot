capture program drop rdpolboot
program define rdpolboot, eclass
	syntax anything [if] [in] [, accel_off plot c(real 0) fuzzy(string) covs(string) vce(string) kernel(string) scaleregul(real 1) deriv(real 0) minpol(real 1) maxpol(real 4) reps(real 15000)]
	
	marksample touse
	
	preserve
	qui keep if `touse'
	
	tokenize "`anything'"
	local y `1'
	local x `2'
	
	qui count
	local N = r(N)
	
	if "`kernel'"=="" local kernel "triangular"
	
	lowestamsepol `y' `x', minpol(`minpol') maxpol(`maxpol') covs(`covs') vce(`vce') fuzzy(`fuzzy') kernel(`kernel') scaleregul(`scaleregul') deriv(`deriv')
	local elist = e(elist)
	local lowestpol = e(lowest_pol)
	
	if "`accel_off'" == "" {
		bootstrap `elist', notable noheader nolegend nowarn reps(`reps') bca jackknifeopts(n(e(N))): rdmse_full `y' `x', minpol(`minpol') maxpol(`maxpol') lowestpol(`lowestpol') fuzzy(`fuzzy') covs(`covs') vce(`vce') scaleregul(`scaleregul') deriv(`deriv') kernel(`kernel')
		estat bootstrap, bca
		matrix upperbound = e(ci_bca)
	}
	else if "`accel_off'" != "" {
		bootstrap `elist', notable noheader nolegend nowarn reps(`reps'): rdmse_full `y' `x', minpol(`minpol') maxpol(`maxpol') lowestpol(`lowestpol') fuzzy(`fuzzy') covs(`covs') vce(`vce') scaleregul(`scaleregul') deriv(`deriv') kernel(`kernel')	
		estat bootstrap
		matrix upperbound = e(ci_bc)
	}
	
	local included
	local rowcount = 1
	forvalues pol = `minpol'/`maxpol' {
		if `pol'==`lowestpol' {
			local included `included' `lowestpol'
		}
		if `pol'!=`lowestpol' & upperbound[2,`rowcount']>0 {
			local included `included' `pol'
			local ++rowcount
		}
	}
	
	if `"`plot'"' != "" {
	 	rdpolbootplot `minpol' `maxpol' `lowestpol', `accel_off'
	}
	
	restore
	
	ereturn clear
	ereturn scalar N = `N'
	ereturn scalar minpol = `minpol'
	ereturn scalar maxpol = `maxpol'
	ereturn scalar lowestpol = `lowestpol'
	
	ereturn matrix amses = amses
	
	ereturn local included "`included'"
	
end
