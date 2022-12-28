capture program drop rdpolboot
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
