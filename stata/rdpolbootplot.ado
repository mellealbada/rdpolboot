program define rdpolbootplot, eclass
	syntax anything [, accel_off]
	
	preserve 
	
	if "`accel_off'" == "" {
		matrix m = ( e(ci_bca) \ e(b) )
	}
	else if "`accel_off'" != "" {
		matrix m = ( e(ci_bc) \ e(b) )
	}
	matrix m = m'
	svmat m
	
	tempvar inc
	gen `inc' = m2>=0
	
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
	
	twoway (rcap m1 m2 rdpolbootid in 1/`maxin', lcolor(black) horizontal xline(0, lcolor(black))) ///
		(scatter rdpolbootid m3 in 1/`maxin' if `inc'==1, mcolor(maroon)) /// 
		(scatter rdpolbootid m3 in 1/`maxin' if `inc'==0, mcolor(black)) ///
		, ylabel(`maxinlist', valuelabel) xscale(range(. 0)) xlabel(#6) legend(off) ytitle("Polynomial Order Pair") xtitle("Difference in AMSE")

	restore
	
end
