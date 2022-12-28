program define polpairpicker, eclass
	syntax anything
	tokenize "`anything'"
	local minp `1'
	local maxp `2'
	
	local polpair=`minp'+1
local elist // initialize elist
forvalues pol = `minp'/`maxp' {
	while `polpair'<=`maxp' {
		if `polpair'>`pol' {
			local elist `elist' e(amse`pol'`polpair') // add scalar to elist
		}
		local ++polpair
	}
	local polpair=`minp'+1
}

	//di "`elist'"
	ereturn local elist "`elist'"
end
