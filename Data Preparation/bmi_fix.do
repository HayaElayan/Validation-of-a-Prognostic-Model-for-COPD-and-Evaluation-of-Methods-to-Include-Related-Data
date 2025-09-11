*BMI before diagnosis (from height/weight)
*********

forvalues i = 10/18 {
	cd "\Data\Raw"
	use clinical`i', clear
	
	forvalues j = 1/3 {
		merge m:m patid adid using additional`j', nogen keep(1 3)
		}

	*Obtain closest record of BMI to date of COPD diagnosis
	cd "\Covariates"
	merge m:1 patid using copd_diagdate, nogen

	keep if inlist(medcode,2,3)				// Keep heights, weights
	destring data1, replace force
	destring data3, replace force
	replace data1 = data1/100 if data1 > 10 & medcode == 3	// Scale heights
	drop if medcode == 3 & !inrange(data1,0.5,2)		// Keep plausible heights
	drop if medcode == 2 & !inrange(data1,10,150)	// Keep plausible weights
	keep if event_date <= copd_diagdate
	gen sort_date = - event_date
	bys patid medcode (sort_date): keep if _n == 1	// Keep closest before COPD

	*Reshape to wide format
	keep patid medcode data1 data3 event_date
	cap {
		reshape wide data1 data3 event_date, i(patid) j(medcode)
		rename data12 wt
		rename data13 ht
		rename event_date2 wt_date
		rename event_date3 ht_date
		gen bmi = wt/(ht^2)
		gen bmi_date = min(wt_date, ht_date)
		replace bmi = data32 if missing(bmi)
		format bmi_date %dd/n/CY
		}

	cd "\Covariates"
	save bmi_fix`i', replace
	*count if missing(bmi)
	}
	
cd "\Covariates"
use bmi_fix1, clear
forvalues i = 2/18 {
	append using bmi_fix`i'
	}
bys patid (event_date): keep if _n == 1
save bmi_fix, replace

