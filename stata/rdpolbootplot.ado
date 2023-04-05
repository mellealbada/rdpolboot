capture program drop rdpolbootplot
program define rdpolbootplot, eclass
	syntax anything
	
	preserve 
	
	matrix m = ci_bca \ diffs
	
	matrix m = m'
	svmat m
	
	tokenize "`anything'"
	local minpol `1'
	local maxpol `2'
	local mainpol `3'

	gen rdpolbootid = _n
	gen inc = ((m1<0) & (m2>0))
	
	local polc = 1
	forvalues pol = `minpol'/`maxpol' {
		if `pol' != `mainpol' {
			label def rdpolbootid `polc' "p`mainpol'p`pol'", modify
			local ++polc
		}
	}	

	label values rdpolbootid rdpolbootid

	local maxin = `maxpol'-`minpol'
	numlist "1/`maxin'"
	local maxinlist `r(numlist)'
	
	twoway (rcap m1 m2 rdpolbootid in 1/`maxin', horizontal xline(0)) (scatter rdpolbootid m3 in 1/`maxin' if inc==0, mcolor(black)) (scatter rdpolbootid m3 in 1/`maxin' if inc==1, mcolor(maroon)), ylabel(`maxinlist', valuelabel) xscale(range(. 0)) xlabel(#6) legend(off) ytitle("Polynomial Order Pair") xtitle("Difference in AMSE")

	restore
	
end