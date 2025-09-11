*Quint/codebrowser
*local fev1_codes `=14453, 8512, 10320, 14455 ,14456 ,19830 ,19832, 19830 , 23237, 23285, 23284, 27141, 43040, 43041, 58632, 58633, 88887, 99777, 100391, 107044, 6118, 10336, 10337, 10420, 10492, 13683, 14453, 19428, 26241, 29015, 45993, 102522'
*local fev1pp_codes `=6091, 14454, 101079, 11078, 25083'
cd ""
import excel fev1_codes.xlsx, firstrow clear
qui levelsof medcode, local(fev1_codes) s(,)

import excel fev1pp_codes.xlsx, firstrow clear
qui levelsof medcode, local(fev1pp_codes) s(,)


*From multiple papers - requested codes
forvalues i = 1/20 {
	cd "\Data\Raw"
	use test`i', clear

	*Obtain closest record of FEV1 and FEV1 %pred to date of COPD diagnosis
	cd "\Covariates"
	merge m:1 patid using copd_diagdate, nogen
	
	keep if inlist(medcode,`fev1_codes') | inlist(medcode,`fev1pp_codes')
	qui replace medcode = 1 if inlist(medcode,`fev1_codes')
	qui replace medcode = 2 if inlist(medcode,`fev1pp_codes')
	keep if event_date <= copd_diagdate
	gen sort_date = - event_date
	bys patid medcode (sort_date): keep if _n == 1		// Keep latest

	keep patid medcode data2 event_date
	reshape wide data2 event_date, i(patid) j(medcode)
	cap rename data21 fev1
	cap rename data22 fev1pp
	cap rename event_date1 fev1_date
	cap rename event_date2 fev1pp_date

	cd "\Covariates"
	save fev_fix`i', replace
	}
	
cd "\Covariates"
use fev_fix1, clear
forvalues i = 2/20 {
	append using fev_fix`i'
	}
bys patid (fev1_date): keep if _n == 1
save fev_fix, replace
