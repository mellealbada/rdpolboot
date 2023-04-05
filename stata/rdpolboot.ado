capture program drop rdpolboot
program define rdpolboot, eclass
	syntax anything [if] [in] [, mainpol(real -1) groups(real 0) groupreps(real 1) plot c(real 0) fuzzy(string) covs(string) vce(string) kernel(string) scaleregul(real 1) deriv(real 0) alpha(real 0.05)] minpol(real) maxpol(real) reps(real)
		
	marksample touse
	
	qui keep if `touse'
	
	tokenize "`anything'"
	local y `1'
	local x `2'
	
	lowestamsepol `y' `x', mainpol(`mainpol') minpol(`minpol') maxpol(`maxpol') covs(`covs') vce(`vce') fuzzy(`fuzzy') kernel(`kernel') scaleregul(`scaleregul') deriv(`deriv')

	local scalarlist = e(scalarlist)
	local namelist = e(namelist)
	local mainpol = e(mainpol)
	
	* original data set
	qui tempfile original
	qui save `original', replace
	
	* sample differences
	tempname memhold_sample
	qui tempfile sample
	qui postfile `memhold_sample' `namelist' using `sample', replace

	forvalues pol = `minpol'/`maxpol' {
		qui rdrobust `y' `x', p(`pol') c(`c') covs(`covs') vce(`vce') kernel(`kernel') fuzzy(`fuzzy') scaleregul(`scaleregul') deriv(`deriv')
		scalar amse`pol' = (e(tau_cl)-e(tau_bc))^2 + e(se_tau_cl)^2
	}

	local totalpairs = `maxpol'-`minpol'
	matrix diffs = J(1,`totalpairs',.)

	local counter = 1
	forvalues pol = `minpol'/`maxpol' {
		if `pol' != `mainpol' {
			scalar amse`mainpol'`pol'= amse`mainpol' - amse`pol'
			scalar samse`mainpol'`pol' = amse`mainpol'`pol' // separate scalar to compare for bs dummies
			matrix diffs[1,`counter'] = amse`mainpol'`pol'
			local ++counter
		}
	}

	post `memhold_sample' `scalarlist'
	postclose `memhold_sample'

	* jackknife differences
	tempname memhold_jk
	tempfile jk
	qui postfile `memhold_jk' grouprep jkrep `namelist' using `jk', replace

	local N = _N
	if `groups'==0 local groups = `N' // error if groups = 1
	
	_dots 0, title(jackknife - `groupreps' group repetition(s))
	forvalues grouprep = 1/`groupreps' {
		
		_dots `grouprep' 0
		
		use `original', replace
		
		scalar grouprep = `grouprep'
		
		qui tempfile jk_id
		tempvar sortvar jk_clustervar
		gen `sortvar' = rnormal()
		sort `sortvar'
		local size = ceil(`N'/`groups')
		egen `jk_clustervar' = seq(), f(1) t(`groups') b(`size')
		qui save `jk_id', replace
		
		forvalues jkrep = 1/`groups' {

			qui if `groups' == `N' keep if `jk_clustervar' != `jkrep'
			qui else keep if `jk_clustervar' == `jkrep'
			
			forvalues pol = `minpol'/`maxpol' {
				capture rdrobust `y' `x', p(`pol') c(`c') covs(`covs') vce(`vce') kernel(`kernel') fuzzy(`fuzzy') scaleregul(`scaleregul') deriv(`deriv')
				if _rc==0 scalar amse`pol' = (e(tau_cl)-e(tau_bc))^2 + e(se_tau_cl)^2
				else scalar amse`pol' = .
			}

			forvalues pol = `minpol'/`maxpol' {
				if `pol' != `mainpol' {
				scalar amse`mainpol'`pol'= amse`mainpol' - amse`pol'
			}
		}
		
		scalar jkrep = `jkrep'
		
		post `memhold_jk' (grouprep) (jkrep) `scalarlist'
		
		use `jk_id', replace
		}	
	}

	postclose `memhold_jk'
	use `jk', replace
	
	scalar N_jk_old = _N
	foreach var of varlist _all { 
		qui drop if missing(`var') 
	}
	scalar N_jk_new = _N
	
	* acceleration factors
	foreach var in `namelist' {
		bysort grouprep: egen meandiff_`var' = mean(`var')
		bysort grouprep: egen atop_`var' = total((meandiff_`var'-`var')^3)
		bysort grouprep: egen abot_`var' = total((meandiff_`var'-`var')^2)
		qui bysort grouprep: replace abot_`var' = 6*(abot_`var')^(3/2)
		bysort grouprep: gen acc_`var' = atop_`var'/abot_`var'
	}

	matrix acc = J(`groupreps',`totalpairs',.)

	forvalues rowcounter = 1/`groupreps' {
		local colcounter = 1
		foreach var in `namelist' {
		qui sum acc_`var' if grouprep==`rowcounter'
		matrix acc[`rowcounter',`colcounter'] = r(mean)
		local ++colcounter
		}
	}

	matrix U = J(rowsof(acc),1,1)
	matrix sum = U'*acc
	matrix meanacc = sum/rowsof(acc)

	* bootstrap differences
	use `original', replace

	tempname memhold_bs
	tempfile bs
	qui postfile `memhold_bs' `namelist' using `bs', replace
	
	di ""
	_dots 0, title(bootstrapping - `reps' repetitions)
	forvalues i = 1/`reps' {
		
		use `original', replace
		bsample _N
		
		_dots `i' 0
		
		forvalues pol = `minpol'/`maxpol' {
			capture rdrobust `y' `x', p(`pol') c(`c') covs(`covs') vce(`vce') kernel(`kernel') fuzzy(`fuzzy') scaleregul(`scaleregul') deriv(`deriv')
			if _rc==0 scalar amse`pol' = (e(tau_cl)-e(tau_bc))^2 + e(se_tau_cl)^2
			else scalar amse`pol' = .
		}

		forvalues pol = `minpol'/`maxpol' {
			if `pol' != `mainpol' {
			scalar amse`mainpol'`pol'= amse`mainpol' - amse`pol'
		}
	}

	post `memhold_bs' `scalarlist'

	}
	postclose `memhold_bs'
	use `bs', replace
	
	scalar N_bs_old = _N
	foreach var of varlist _all { 
		qui drop if missing(`var') 
	}
	scalar N_bs_new = _N

	* bias correction factors
	matrix z0 = J(1,`totalpairs',.)

	local counter = 1
	foreach var in `namelist' {
		gen dummydiff_`var' = (`var'<=s`var')
		qui sum dummydiff_`var'
		matrix z0[1,`counter'] = invnormal(r(mean))
		local ++counter
	}

	local counter = 1
	local alpha = `alpha'/2
	matrix alphas = J(2,`totalpairs', .)
	forvalues i = 1/`totalpairs' {
		matrix alphas[1,`counter'] = normal(z0[1,`counter']+(z0[1,`counter'] + invnormal(`alpha'))/(1-meanacc[1,`counter']*(z0[1,`counter'] + invnormal(`alpha'))))
		matrix alphas[2,`counter'] = normal(z0[1,`counter']+(z0[1,`counter'] + invnormal(1-`alpha'))/(1-meanacc[1,`counter']*(z0[1,`counter'] + invnormal(1-`alpha'))))
		local ++counter
	}

	* bca cis
	use `bs', replace
		
	matrix ci_bca = J(2,`totalpairs',.)
	local counter = 1
	foreach var of varlist _all {
		local centile = 100*alphas[1,`counter']
		qui centile `var', centile(`centile')
		matrix ci_bca[1,`counter'] = r(c_1)
		
		local centile = 100*alphas[2,`counter']
		qui centile `var', centile(`centile')
		matrix ci_bca[2,`counter'] = r(c_1)
		local ++counter
	}

	matrix colnames ci_bca = `namelist'
	matrix rownames ci_bca = left right
	matrix list ci_bca
	
	* plot
	local included
	local colcount = 1
	forvalues pol = `minpol'/`maxpol' {
		if `pol'==`mainpol' {
			local included `included' `lowestpol'
		}
		if (`pol'!=`mainpol') & (ci_bca[1,`colcount']<0) & (ci_bca[2,`colcount']>0) {
			local included `included' `pol'
			local ++colcount
		}
	}
	
	if `"`plot'"' != "" {
	 	rdpolbootplot `minpol' `maxpol' `mainpol'
	}
	
	use `original', replace
	
	* returns
	ereturn clear
	ereturn scalar N = `N'
	ereturn scalar minpol = `minpol'
	ereturn scalar maxpol = `maxpol'
	ereturn scalar mainpol = `mainpol'
	ereturn scalar missings_bs = N_bs_old-N_bs_new
	ereturn scalar missings_jk = N_jk_old-N_jk_new
	
	ereturn matrix ci_bca = ci_bca
	ereturn matrix amses = amses
	
	ereturn local included "`included'"
	
end