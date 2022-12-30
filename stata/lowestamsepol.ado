capture program drop lowestamsepol
program define lowestamsepol, eclass
	syntax anything [, c(real 0) fuzzy(string) covs(string) vce(string) kernel(string) scaleregul(real 1) deriv(real 0)] minpol(real) maxpol(real)
	tokenize "`anything'"
	
	local y `1'
	local x `2'
	
	scalar lowestamse = .
	scalar lowestpol = .
	
	if "`fuzzy'"=="" {
		forvalues pol = `minpol'/`maxpol' {
			qui rdbwselect `y' `x', p(`pol') c(`c') covs(`covs') vce(`vce') kernel(`kernel') scaleregul(`scaleregul') deriv(`deriv')
			local hbw = e(h_mserd)
			local bbw = e(b_mserd)
			qui rdmses `y' `x', h(`hbw') b(`bbw') p(`pol') c(`c')
		
			scalar amse_p`pol' = e(amse_cl)
			di "AMSE for polynomial order `pol' is " amse_p`pol'
			
			if `pol'==`minpol' {
				matrix amses = `pol', e(amse_cl)
			}
			else matrix amses = amses \ `pol', e(amse_cl)
		
			if e(amse_cl) < lowestamse {
				scalar lowestamse = e(amse_cl)
				scalar lowestpol = `pol'
			}
		}
	}
	
	if "`fuzzy'"!="" {
		forvalues pol = `minpol'/`maxpol' {
			qui rdbwselect `y' `x', p(`pol') c(`c') covs(`covs') vce(`vce') fuzzy(`fuzzy') kernel(`kernel') scaleregul(`scaleregul') deriv(`deriv')
			local hbw = e(h_mserd)
			local bbw = e(b_mserd)
			qui rdmsef `y' `x', h(`hbw') b(`bbw') p(`pol') c(`c') fuzzy(`fuzzy')
		
			scalar amse_p`pol' = e(amse_F_cl)
			di "AMSE for polynomial order `pol' is " amse_p`pol'
			
			if `pol'==`minpol' {
				matrix amses = `pol', e(amse_F_cl)
			}
			else matrix amses = amses \ `pol', e(amse_F_cl)
		
			if e(amse_cl) < lowestamse {
				scalar lowestamse = e(amse_F_cl)
				scalar lowestpol = `pol'
			}
		}
	}
	
	matrix colnames amses = polynomial amse

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
