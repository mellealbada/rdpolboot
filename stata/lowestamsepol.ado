capture program drop lowestamsepol
program define lowestamsepol, eclass
	syntax anything [, mainpol(real -1) c(real 0) fuzzy(string) covs(string) vce(string) kernel(string) scaleregul(real 1) deriv(real 0)] minpol(real) maxpol(real)
	tokenize "`anything'"
	
	local y `1'
	local x `2'
	
	scalar lowestamse = .
	scalar lowestpol = .

	forvalues pol = `minpol'/`maxpol' {
		
		qui rdrobust `y' `x', p(`pol') c(`c') covs(`covs') vce(`vce') kernel(`kernel') fuzzy(`fuzzy') scaleregul(`scaleregul') deriv(`deriv')
		scalar amse_p`pol' = (e(tau_cl)-e(tau_bc))^2 + e(se_tau_cl)^2
		
		di "AMSE for polynomial order `pol' is " amse_p`pol'
		
		if `pol'==`minpol' {
			matrix amses = `pol', amse_p`pol'
		}
		else matrix amses = amses \ `pol', amse_p`pol'
	
		if amse_p`pol' < lowestamse {
			scalar lowestamse = amse_p`pol'
			scalar lowestpol = `pol'

		}
	}
	
	matrix colnames amses = polynomial amse
	
	if `mainpol'==-1 local mainpol = lowestpol
	local scalarlist
	local namelist

	forvalues pol = `minpol'/`maxpol' {
		if `pol' != `mainpol' {
			local scalarlist `scalarlist' (amse`mainpol'`pol')
			local namelist `namelist' amse`mainpol'`pol' 
		}
	}

	ereturn clear
	
	ereturn scalar lowest_amse = lowestamse
	ereturn scalar lowest_pol = lowestpol
	ereturn scalar mainpol = `mainpol'
	
	ereturn local scalarlist "`scalarlist'"
	ereturn local namelist "`namelist'"

end

