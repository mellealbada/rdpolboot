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
