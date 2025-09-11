
forvalues i = 1/18 {
	*Use Cambridge codelist
	cd "\CPRD\Covariates"

	qui import delim ///
		"CPRDCAM_ALC138_MC_V1-1_Oct2018\CPRDCAM_ALC138_MC_V1-1_Oct2018.csv", clear
	qui levelsof medcode, local(alc138_medcode) s(,)

	cd "\Data\Raw"
	use clinical`i', clear

	*Obtain any record of alcohol problems prior to COPD diagnosis
	cd "\Covariates"
	merge m:1 patid using copd_diagdate, nogen
	keep if event_date <= copd_diagdate

	keep if inlist(medcode, `alc138_medcode')		// Keep alcohol records
	rename event_date alcohol_date
	bys patid (alcohol_date): keep if _n == 1		// Keep earliest record
	keep patid alcohol_date
	gen alcohol = 1

	cd "\Covariates"
	save alcohol`i', replace
	}

cd "\Covariates"
use alcohol1, clear
forvalues i = 2/18 {
	append using alcohol`i'
	}
bys patid (alcohol_date): keep if _n == 1
save alcohol, replace