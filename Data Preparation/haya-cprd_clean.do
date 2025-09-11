********************************************************************************
*Clean CPRD GOLD, ONS, HES and IMD files for covariates
*File created 01/08/2023
*Last edited 17/10/2024 - added crd and frd dates to restrict follow-up time
********************************************************************************
/*
Additional files 3
Clinical files 18
Consultation files 18
Immunisation files 1
Patient files 1
Practice files 1
Referral files 1
Staff files 1
Test files 20
Therapy files 61
*/

*********
*UTS date
*********

cd "\Data\Raw"
use patient, clear


merge 1:1 patid using haya_gold_linkage_patid, nogen keep(1 3)

cd "\Data\Raw"
merge m:1 pracid using practice, nogen keep(1 3)

gen uts_date = date(uts, "DMY")
format uts_date %dd/n/CY

**MJR ADDED
gen lcd_date = date(lcd, "DMY")
format lcd_date %dd/n/CY

**MJR ADDED
gen crd_date = date(crd, "DMY")
format crd_date %dd/n/CY

**MJR ADDED
gen frd_date = date(frd, "DMY")
format frd_date %dd/n/CY

**SB ADDED
gen tod_date = date(tod, "DMY")
format tod_date %dd/n/CY

keep patid pracid uts_date lcd_date crd_date frd_date tod_date

cd "\Covariates"
save uts, replace


*********
*COPD
*********


import excel haya-copd_medcodes.xlsx, firstrow clear
qui levelsof medcode, local(copd_medcode) s(,)

forvalues i = 1/18 {
	cd "\Data\Raw"
	use clinical`i', clear

	keep if inlist(medcode, `copd_medcode')

	rename event_date copd_diagdate
	bys patid (copd_diagdate): gen id1 = _n		// Keep earliest COPD record
	gsort +patid -copd_diagdate
	by patid: gen id2 = _n						// Keep latest COPD record
	keep if id1 == 1 | id2 == 1
	
	
	keep patid copd_diagdate id1 id2
	qui replace id1 = 2 if id1 != 1
	qui replace id2 = 2 if id2 != 1
	drop id2
	reshape wide copd_diagdate, i(patid) j(id1)
	qui replace copd_diagdate2 = copd_diagdate1 if missing(copd_diagdate2)
	qui rename copd_diagdate1 copd_diagdate
	qui rename copd_diagdate2 copd_diagdate_last
	
	cd "\Covariates"
	save copd_diagdate`i', replace
	}
	
cd "\Covariates"
use copd_diagdate1, clear
forvalues i = 2/18 {
	append using copd_diagdate`i'
	}
bys patid (copd_diagdate): keep if _n == 1
save copd_diagdate, replace

*********
*COPD annual review
*********

forvalues i = 1/18 {
	cd "\Data\Raw"
	use clinical`i', clear

	keep if medcode == 11287					// COPD annual review

	rename event_date copd_review
	keep patid copd_review
	bys patid (copd_review): gen id = _n
	reshape wide copd_review, i(patid) j(id)
	
	cd "\Covariates"
	save copd_review`i', replace
	}
	
cd "\HE\Covariates"
use copd_review1, clear
forvalues i = 2/18 {
	append using copd_review`i'
	}
bys patid (copd_review1): keep if _n == 1
save copd_review, replace

**********
*Earliest follow-up that isn't a diagnosis
**********

import excel haya-copd_medcodes.xlsx, firstrow clear
qui levelsof medcode, local(copd_medcode) s(,)

*Consultation, Clinical, Therapy, Referral, Test, Immunisation
cd "\Data\Raw"
use immunisation, clear

cd "\Covariates"
merge m:1 patid using uts, nogen keep(3)
keep if uts_date <= event_date

keep patid event_date
keep if event_
bys patid (event_date): keep if _n == 1
		
cd "\Covariates"
save earliest_immunisation, replace

cd "\Data\Raw"
use referral, clear

cd "\Covariates"
merge m:1 patid using uts, nogen keep(3)
keep if uts_date <= event_date

keep patid event_date
bys patid (event_date): keep if _n == 1
		
cd "\Covariates"
save earliest_referral, replace

local clinical_f 18
local consultation_f 18
local test_f 20
local therapy_f 61

foreach file in clinical consultation test therapy {
	forvalues i = 1/``file'_f' {
		cd "\Data\Raw"
		use `file'`i', clear

		cd "\Covariates"
		merge m:1 patid using uts, nogen keep(3)
		keep if uts_date <= event_date
		
		cap drop if inlist(medcode, `copd_medcode')		// Remove COPD diagnoses
		
		keep patid event_date
		bys patid (event_date): keep if _n == 1
		
		cd "\Covariates"
		save earliest_`file'`i', replace
		}
		
	cd "\Covariates"
	use earliest_`file'1, clear
	forvalues i = 2/``file'_f' {
		cap append using earliest_`file'`i'
		}
	bys patid (event_date): keep if _n == 1
	save earliest_`file', replace
	}
	
cd "\Covariates"
use earliest_clinical, clear
foreach file in consultation immunisation referral test therapy {
	append using earliest_`file'
	}
bys patid (event_date): keep if _n == 1

rename event_date earliest_date
cd "\Covariates"
save earliest, replace



*********
*Outcome - mortality at 1, 5, 10 years
*********

*Deaths - ONS
cd "Data\Raw"
use ons_gold, clear
format patid %30.0f
gen death_date = date(dod, "DMY")
format death_date %dd/n/CY
keep patid death_date

cd "\Covariates"
save death_ons, replace

*Deaths - CPRD GOLD
cd "Data\Raw"
use patient, clear
gen death_date = date(deathdate, "DMY")
format death_date %dd/n/CY
keep patid death_date

cd "\Covariates"
merge 1:1 patid using death_ons, replace update nogen
gen dead = missing(death_date) == 0
save death, replace
	
	
*Latest follow-up among non-deaths
*Consultation, Clinical, Therapy, Referral, Test, Immunisation

cd "Data\Raw"
use immunisation, clear
keep patid event_date
gsort +patid -event_date
bys patid: keep if _n == 1
		
cd "\Covariates"
rename event_date event_date_immunisation
save latest_immunisation, replace

cd "Data\Raw"
use referral, clear
keep patid event_date
gsort +patid -event_date
bys patid: keep if _n == 1
		
cd "\Covariates"
rename event_date event_date_referral
save latest_referral, replace

local clinical_f 18
local consultation_f 18
local test_f 20
local therapy_f 61

foreach file in clinical consultation test therapy {
	forvalues i = 1/``file'_f' {
		cd "Data\Raw"
		use `file'`i', clear
		keep patid event_date
		gsort +patid -event_date
		bys patid: keep if _n == 1
		
		cd "\Covariates"
		rename event_date event_date_`file'
		save latest_`file'`i', replace
		}
		
	cd "\Covariates"
	use latest_`file'1, clear
	forvalues i = 2/``file'_f' {
		cap append using latest_`file'`i'
		}
	bys patid: keep if _n == 1
	save latest_`file', replace
	}

cd "\Covariates"
use death, clear
foreach file in clinical consultation immunisation referral test therapy {
	merge 1:1 patid using latest_`file', nogen keep(1 3)
	qui replace death_date = event_date_`file' if missing(death_date)
	qui replace death_date = event_date_`file' if dead == 0 & ///
		event_date_`file' > death_date & event_date_`file' != .
	}

keep patid death_date dead
cd "\Covariates"
save death, replace

*1, 5 and 10-year events including ages
cd "Data\Raw"
use patient, clear
gen dob = mdy(mob,15,yob) if mob != 0
replace dob = mdy(7,1,yob) if mob == 0
format dob %dd/n/CY
keep patid dob

cd "\Covariates"
merge 1:1 patid using death, nogen
merge 1:1 patid using copd_diagdate, nogen
foreach x in 1 5 10 {
	gen dead`x' = dead == 1 & (death_date - copd_diagdate)/365.25 < `x'
	}

*Ages
gen age_copd = (copd_diagdate - dob)/365.25
gen stime = (death_date - dob)/365.25
gen stime_copd = stime - age_copd

cd "\Covariates"
order patid dob copd_diagdate age_copd death_date stime dead stime_copd
save death_1_5_10, replace
	
********************************************************************************
*Covariates - import code lists and keep relevant patient records
********************************************************************************

*******************************************
*Continuous
*******************************************

*********
*Age
*********

*Obtain age at COPD diagnosis - extractable from dob and date of COPD diagnosis
cd "Data\Raw"
use patient, clear
gen dob = mdy(mob,15,yob) if mob != 0
replace dob = mdy(7,1,yob) if mob == 0
format dob %dd/n/CY

cd "\Covariates"
merge 1:1 patid using copd_diagdate
gen age_diag = (copd_diagdate - dob)/365.25

cd "\Covariates"
keep patid age_diag
save age_diag, replace

*********
*BMI before diagnosis (from height/weight)
*********

forvalues i = 1/18 {
	cd "Data\Raw"
	use clinical`i', clear
	
	forvalues j = 1/3 {
		merge m:m patid adid using additional`j', nogen keep(1 3)
		}

	*Obtain closest record of BMI to date of COPD diagnosis
	cd "\Covariates"
	merge m:1 patid using copd_diagdate, nogen

	keep if inlist(medcode,2,3)				// Keep heights, weights
	destring data1, replace force
	replace data1 = data1/100 if data1 > 10 & medcode == 3	// Scale heights
	drop if medcode == 3 & !inrange(data1,0.5,2)		// Keep plausible heights
	drop if medcode == 2 & !inrange(data1,10,150)	// Keep plausible weights
	keep if event_date <= copd_diagdate
	gen sort_date = - event_date
	bys patid medcode (sort_date): keep if _n == 1	// Keep closest before COPD

	*Reshape to wide format
	keep patid medcode data1 event_date
	drop if missing(data1)
	cap {
		reshape wide data1 event_date, i(patid) j(medcode)
		rename data12 wt
		rename data13 ht
		rename event_date2 wt_date
		rename event_date3 ht_date
		gen bmi = wt/(ht^2)
		gen bmi_date = min(wt_date, ht_date)
		format bmi_date %dd/n/CY
		}

	cd "\Covariates"
	save bmi`i', replace
	}
	
cd "\Covariates"
use bmi1, clear
forvalues i = 2/18 {
	append using bmi`i'
	}
bys patid (bmi_date): keep if _n == 1
save bmi, replace

*********
*BMI most recent (from height/weight)
*********

forvalues i = 1/18 {
	cd "Data\Raw"
	use clinical`i', clear
	
	forvalues j = 1/3 {
		merge m:m patid adid using additional`j', nogen keep(1 3)
		}

	*Obtain most recent record of BMI
	keep if inlist(medcode,2,3)						// Keep heights and weights
	destring data1, replace force
	replace data1 = data1/100 if data1 > 10 & medcode == 3	// Scale heights
	drop if medcode == 3 & !inrange(data1,0.5,2)		// Keep plausible heights
	drop if medcode == 2 & !inrange(data1,10,150)	// Keep plausible weights
	gen sort_date = - event_date
	bys patid medcode (sort_date): keep if _n == 1	// Keep most recent

	*Reshape to wide format
	keep patid medcode data1 event_date
	drop if missing(data1)
	cap {
		reshape wide data1 event_date, i(patid) j(medcode)
		rename data12 wt
		rename data13 ht
		rename event_date2 wt_date
		rename event_date3 ht_date
		gen bmi2 = wt/(ht^2)
		gen bmi2_date = min(wt_date, ht_date)
		format bmi2_date %dd/n/CY
		keep patid bmi2 bmi2_date
		}

	cd "\Covariates"
	save bmi2_`i', replace
	}
	
cd "\Covariates"
use bmi2_1, clear
forvalues i = 2/8 {
	append using bmi2_`i'
	}
bys patid (bmi2_date): keep if _n == 1
save bmi2, replace

*********
*BMI using medcode 8105
*********

forvalues i = 1/18 {
	cd "Data\Raw"
	use clinical`i', clear
	
	keep if medcode == 8105
	forvalues j = 1/3 {
		merge m:m patid adid using additional`j', nogen keep(1 3)
		}
	tab data3
	
	destring data3, replace force
	keep if inrange(data3,0,70)							// Keep plausible values
	bys patid (event_date): keep if _n == 1

	keep patid data3 event_date
	rename data3 bmi_new
	rename event_date bmi_new_date
	drop if missing(bmi_new)

	cd "\Covariates"
	save bmi_new`i', replace
	}
	
cd "\Covariates"
use bmi_new1, clear
forvalues i = 2/18 {
	append using bmi_new`i'
	}
bys patid (bmi_new_date): keep if _n == 1
save bmi_new, replace

*********
*C-reactive protein (CRP)
*********

forvalues i = 1/20 {
	cd "Data\Raw"
	use test`i', clear

	*Obtain closest record of C-reactive protein to date of COPD diagnosis
	cd "\Covariates"
	merge m:1 patid using copd_diagdate, nogen
	keep if enttype == 280						// Keep CRP measurements
	tab medcode
	keep if medcode == 14068				// just serum or plasma (14066) too?
	keep if event_date <= copd_diagdate
	gen sort_date = - event_date
	bys patid (sort_date): keep if _n == 1		// Keep closest before COPD
	rename data2 crp_level
	rename event_date crp_date
	keep patid crp_level crp_date

	cd "\Covariates"
	save crp`i', replace
}

cd "\Covariates"
use crp1, clear
forvalues i = 2/20 {
	append using crp`i'
	}
bys patid (crp_date): keep if _n == 1
save crp, replace

*********
*Creatinine
*********

*From Bloom paper - requested codes

forvalues i = 1/20 {
	cd "Data\Raw"
	use test`i', clear

	*Obtain closest record of creatinine to date of COPD diagnosis
	cd "\Covariates"
	merge m:1 patid using copd_diagdate, nogen
	keep if enttype == 164						// Keep creatinine measurements

	*tab medcode
	keep if inlist(medcode,13734,13735,18857)
	keep if event_date <= copd_diagdate
	gen sort_date = - event_date
	bys patid (sort_date): keep if _n == 1		// Keep closest before COPD
	rename data2 creatinine
	rename event_date creatinine_date
	keep patid creatinine creatinine_date

	cd "\Covariates"
	save creatinine`i', replace
	}

cd "\Covariates"
use creatinine1, clear
forvalues i = 2/20 {
	append using creatinine`i'
	}
bys patid (creatinine_date): keep if _n == 1
save creatinine, replace

*********
*Eosinophil
*********

*From Groves paper - requested codes

forvalues i = 1/20 {
	cd "Data\Raw"
	use test`i', clear

	*Obtain closest record of eosinophil to date of COPD diagnosis
	cd "\Covariates"
	merge m:1 patid using copd_diagdate, nogen
	keep if enttype == 168						// Keep eosinophil measurements

	*tab medcode
	keep if inlist(medcode,19760)
	keep if event_date <= copd_diagdate
	gen sort_date = - event_date
	bys patid (sort_date): keep if _n == 1		// Keep closest before COPD
	rename data2 eosinophil
	rename event_date eosinophil_date
	keep patid eosinophil eosinophil_date

	cd "\Covariates"
	save eosinophil`i', replace
	}

cd "\Covariates"
use eosinophil1, clear
forvalues i = 2/20 {
	append using eosinophil`i'
	}
bys patid (eosinophil_date): keep if _n == 1
save eosinophil, replace


*********
*FEV1
*********

*Quint/codebrowser
local fev1_codes `=10320, 107044, 14453, 19830, 23237, 43040, 43041, 99777'
local fev1pp_codes `=6091, 14454, 101079'

*From multiple papers - requested codes
forvalues i = 1/20 {
	cd "Data\Raw"
	use test`i', clear

	*Obtain closest record of FEV1 and FEV1 %pred to date of COPD diagnosis
	cd "\Covariates"
	merge m:1 patid using copd_diagdate, nogen

	keep if inlist(medcode,`fev1_codes') | inlist(medcode,`fev1pp_codes')
	qui replace medcode = 1 if inlist(medcode,`fev1_codes')
	qui replace medcode = 2 if inlist(medcode,`fev1pp_codes')
	gen sort_date = - event_date
	bys patid medcode (sort_date): keep if _n == 1		// Keep latest

	keep patid medcode data2 event_date
	reshape wide data2 event_date, i(patid) j(medcode)
	cap rename data21 fev1
	cap rename data22 fev1pp
	cap rename event_date1 fev1_date
	cap rename event_date2 fev1pp_date

	cd "\Covariates"
	save fev`i', replace
	}
	
cd "\Covariates"
use fev1, clear
forvalues i = 2/20 {
	append using fev`i'
	}
bys patid (fev1_date): keep if _n == 1
save fev, replace

*********
*Fibrinogen
*********

forvalues i = 1/20 {
	*Update code list when possible
	cd "Data\Raw"
	use test`i', clear

	*Obtain closest record of fibrinogen to date of COPD diagnosis
	cd "\Covariates"
	merge m:1 patid using copd_diagdate, nogen
	keep if medcode == 14458					// Keep fibrinogen measurements
	keep if event_date <= copd_diagdate
	gen sort_date = - event_date
	bys patid (sort_date): keep if _n == 1		// Keep closest before COPD
	rename data2 fibrinogen_level
	rename event_date fibrinogen_date
	keep patid fibrinogen_level fibrinogen_date

	cd "\Covariates"
	save fibrinogen`i', replace
	}

cd "\Covariates"
use fibrinogen1, clear
forvalues i = 2/20 {
	append using fibrinogen`i'
	}
bys patid (fibrinogen_date): keep if _n == 1
save fibrinogen, replace

*********
*Haemoglobin
*********

*From Bloom paper - requested codes
forvalues i = 1/20 {
	cd "Data\Raw"
	use test`i', clear

	*Obtain closest record of haemoglobin to date of COPD diagnosis
	cd "\Covariates"
	merge m:1 patid using copd_diagdate, nogen
	keep if enttype == 173						// Keep haemoglobin measurements
	*tab medcode
	keep if medcode == 4
	keep if event_date <= copd_diagdate
	gen sort_date = - event_date
	bys patid (sort_date): keep if _n == 1		// Keep closest before COPD
	rename data2 haemoglobin
	rename event_date haemoglobin_date
	keep patid haemoglobin haemoglobin_date

	cd "\Covariates"
	save haemoglobin`i', replace
	}

cd "\Covariates"
use haemoglobin1, clear
forvalues i = 2/20 {
	append using haemoglobin`i'
	}
bys patid (haemoglobin_date): keep if _n == 1
save haemoglobin, replace

*******************************************
*Categorical
*******************************************

*********
*Acute respiratory infection history
*********

cd "JB\CPRD\Covariates"
qui import delim "Shah\ARI.txt", clear
qui levelsof medcode, local(ari_medcode) s(,)

forvalues i = 1/18 {
	cd "Data\Raw"
	use clinical`i', clear

	*Obtain any record of ARI history prior to COPD diagnosis
	cd "\Covariates"
	merge m:1 patid using copd_diagdate, nogen
	keep if event_date <= copd_diagdate

	*Keep earliest record
	keep if inlist(medcode,`ari_medcode')
	bys patid (event_date): keep if _n == 1
	gen ari = 1
	rename event_date ari_date
	keep patid ari ari_date

	cd "\Covariates"
	save ari`i', replace
	}

cd "\Covariates"
use ari1, clear
forvalues i = 2/18 {
	append using ari`i'
	}
bys patid (ari_date): keep if _n == 1
save ari, replace


*********
*Albumin
*********

forvalues i = 1/20 {
	cd "Data\Raw"
	use test`i', clear

	*Obtain closest record of albumin to date of COPD diagnosis
	cd "\Covariates"
	merge m:1 patid using copd_diagdate, nogen
	keep if enttype == 152						// Keep albumin measurements
	*tab medcode
	keep if medcode == 23
	drop if missing(data2)
	keep if event_date <= copd_diagdate
	gen sort_date = - event_date
	bys patid (sort_date): keep if _n == 1		// Keep closest before COPD
	rename data2 albumin_level
	gen albumin = albumin_level > 35
	replace albumin = . if albumin_level == .
	rename event_date albumin_date
	keep patid albumin albumin_level albumin_date
	order patid albumin albumin_level albumin_date

	cd "\Covariates"
	save albumin`i', replace
	}

cd "\Covariates"
use albumin1, clear
forvalues i = 2/20 {
	append using albumin`i'
	}
bys patid (albumin_date): keep if _n == 1
save albumin, replace
	
*********
*Alcohol problems
*********

forvalues i = 1/18 {
	*Use Cambridge codelist
	cd "JB\CPRD\Covariates"

	qui import delim ///
		"CPRDCAM_ALC138_MC_V1-1_Oct2018\CPRDCAM_ALC138_MC_V1-1_Oct2018.csv", clear
	qui levelsof medcode, local(alc138_medcode) s(,)

	cd "Data\Raw"
	use clinical1, clear

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

*********
*Anaemia
*********

*Use LSHTM codelist
cd "JB\CPRD\Covariates"
qui import delim "LSHTM\LSHTM_ANA.txt", clear
qui levelsof medcode, local(ana_medcode) s(,)

forvalues i = 1/18 {
	cd "Data\Raw"
	use clinical`i', clear

	*Obtain any record of anaemia prior to COPD diagnosis
	cd "\Covariates"
	merge m:1 patid using copd_diagdate, nogen
	keep if event_date <= copd_diagdate

	keep if inlist(medcode, `ana_medcode')			// Keep anaemia records
	rename event_date anaemia_date
	bys patid (anaemia_date): keep if _n == 1		// Keep earliest record
	keep patid anaemia_date
	gen anaemia = 1

	cd "\Covariates"
	save anaemia`i', replace
	}

cd "\Covariates"
use anaemia1, clear
forvalues i = 2/18 {
	append using anaemia`i'
	}
bys patid (anaemia_date): keep if _n == 1
save anaemia, replace

*********
*Anxiety
*********

*Use Cambridge codelist for medcodes
cd "JB\CPRD\Covariates"

qui import delim ///
	"CPRDCAM_ANX140_MC_V1-1_Oct2018\CPRDCAM_ANX140_MC_V1-1_Oct2018.csv", clear
qui levelsof medcode, local(anx140_medcode) s(,)

forvalues i = 1/18 {
	cd "Data\Raw"
	use clinical`i', clear

	*Obtain any record of anxiety diagnosis prior to COPD diagnosis
	cd "\Covariates"
	merge m:1 patid using copd_diagdate, nogen

	keep if inlist(medcode, `anx140_medcode')		// Keep anxiety records
	keep if event_date <= copd_diagdate
	rename event_date anx_date1
	gen sort_date = - anx_date1
	bys patid (sort_date): keep if _n == 1			// Keep closest before COPD
	keep patid anx_date1
	gen anx1 = 1

	cd "\Covariates"
	save anxiety1_`i', replace
	}

cd "\Covariates"
use anxiety1_1, clear
forvalues i = 2/18 {
	append using anxiety1_`i'
	}
bys patid (anx_date1): keep if _n == 1
save anxiety1, replace


*Use Cambridge codelist for prodcodes
cd "JB\CPRD\Covariates"

qui import delim ///
	"CPRDCAM_ANX141_PC_V1-1_Oct2018\CPRDCAM_ANX141_PC_V1-1_Oct2018.csv", clear
forvalues x = 1/10 {
	local y = 200*(`x'-1)
	qui levelsof prodcode if inrange(_n,`y',`y'+199), ///
		local(anx141_prodcode`x') s(,)
	}

forvalues i = 1/61 {
	cd "Data\Raw"
	use therapy`i', clear

	*Obtain any record of anxiety diagnosis prior to COPD diagnosis
	cd "\Covariates"
	merge m:1 patid using copd_diagdate, nogen
	gen z = inlist(prodcode,`anx141_prodcode1')			// Keep anxiety records
	forvalues x = 2/10 {
		if "`anx141_prodcode`x''" != "" {
			qui replace z = 1 if inlist(prodcode,`anx141_prodcode`x'') & z == 0
			}
		}
	keep if z == 1
	drop z
	keep if event_date <= copd_diagdate
	rename event_date anx_date2
	gen sort_date = - anx_date2
	keep if (copd_diagdate - anx_date2 < 366)		// Only keep if in last year
	bys patid (anx_date2): keep if _n >= 4			// Only keep if >= 4 prescrips
	bys patid (sort_date): keep if _n == 1			// Keep most recent prescrip
	keep patid anx_date2
	gen anx2 = 1

	cd "\Covariates"
    save anxiety2_`i', replace
	}
	
cd "\Covariates"
use anxiety2_1, clear
forvalues i = 2/61 {
	append using anxiety2_`i'
	}
bys patid (anx_date2): keep if _n == 1
save anxiety2, replace

cd "\Covariates"
use anxiety1, clear
merge 1:1 patid using anxiety2, nogen
keep if anx1 == 1 | anx2 == 1
gen anxiety = 1
gen anxiety_date = anx_date1 if anx1 == 1
replace anxiety_date = anx_date2 if missing(anx_date1) | ///
	((anx_date2 > anx_date1) & !missing(anx_date2))
keep patid anxiety anxiety_date
save anxiety, replace


*********
*Asthma
*********

*Use Cambridge codelist for medcodes
cd "JB\CPRD\Covariates"

qui import delim ///
	"CPRDCAM_AST142_MC_V1-1_Oct2018\CPRDCAM_AST142_MC_V1-1_Oct2018.csv", clear
qui levelsof medcode, local(ast142_medcode) s(,)

forvalues i = 1/18 {
	cd "Data\Raw"
	use clinical`i', clear

	*Obtain any record of asthma diagnosis prior to COPD diagnosis
	cd "\Covariates"
	merge m:1 patid using copd_diagdate, nogen

	keep if inlist(medcode, `ast142_medcode')		// Keep asthma records
	keep if event_date <= copd_diagdate
	rename event_date ast_date
	gen sort_date = - ast_date
	bys patid (sort_date): keep if _n == 1			// Keep closest before COPD
	keep patid
	gen ast1 = 1

	cd "\Covariates"
	save asthma1_`i', replace
	}
	
cd "\Covariates"
use asthma1_1, clear
forvalues i = 2/18 {
	append using asthma1_`i'
	}
bys patid: keep if _n == 1
save asthma1, replace
	
*Use Cambridge codelist for prodcodes
cd "JB\CPRD\Covariates"

qui import delim ///
	"CPRDCAM_AST127_PC_V1-1_Oct2018\CPRDCAM_AST127_PC_V1-1_Oct2018.csv", clear
forvalues x = 1/10 {
	local y = 200*(`x'-1)
	qui levelsof prodcode if inrange(_n,`y',`y'+199), ///
		local(ast127_prodcode`x') s(,)
	}

forvalues i = 1/61 {
	cd "Data\Raw"
	use therapy`i', clear

	*Obtain any record of asthma diagnosis prior to COPD diagnosis
	cd "\Covariates"
	merge m:1 patid using copd_diagdate, nogen
	gen z = inlist(prodcode,`ast127_prodcode1')			// Keep asthma records
	forvalues x = 2/10 {
		if "`ast127_prodcode`x''" != "" {
			qui replace z = 1 if inlist(prodcode,`ast127_prodcode`x'') & z == 0
			}
		}
	keep if z == 1
	drop z
	keep if event_date <= copd_diagdate
	rename event_date asthma_date
	gen sort_date = - asthma_date
	bys patid (sort_date): keep if _n == 1			// Keep closest before COPD
	keep if (copd_diagdate - asthma_date < 366)		// Only keep if in last year
	keep patid asthma_date
	gen ast2 = 1

	cd "\Covariates"
	save asthma2_`i', replace
	}
	
cd "\Covariates"
use asthma2_1, clear
forvalues i = 2/61 {
	append using asthma2_`i'
	}
bys patid (asthma_date): keep if _n == 1
save asthma2, replace

cd "\Covariates"
use asthma1, replace
merge 1:1 patid using asthma2, nogen
keep if ast1 == 1 & ast2 == 1
gen asthma = 1
keep patid asthma asthma_date
save asthma, replace


*********
*Atrial fibrillation
*********

*Use Cambridge codelist
cd "JB\CPRD\Covariates"

qui import delim ///
	"CPRDCAM_ATR143_MC_V1-1_Oct2018\CPRDCAM_ATR143_MC_V1-1_Oct2018.csv", clear
qui levelsof medcode, local(atr143_medcode) s(,)

forvalues i = 1/18 {
	cd "Data\Raw"
	use clinical`i', clear

	*Obtain any record of atrial fibrillation prior to COPD diagnosis
	cd "\Covariates"
	merge m:1 patid using copd_diagdate, nogen
	keep if event_date <= copd_diagdate

	keep if inlist(medcode, `atr143_medcode')	// Keep atrial fibrillation records
	rename event_date atrial_date
	bys patid (atrial_date): keep if _n == 1		// Keep earliest record
	keep patid atrial_date
	gen atrial = 1

	cd "\Covariates"
	save atrial`i', replace
	}


cd "\Covariates"
use atrial1, clear
forvalues i = 2/18 {
	append using atrial`i'
	}
bys patid (atrial_date): keep if _n == 1
save atrial, replace


*********
*Bereavement
*********

forvalues i = 1/18 {
	*Update this codelist when possible
	cd "Data\Raw"
	use clinical`i', clear

	*Obtain any record of bereavement prior to COPD diagnosis
	cd "\Covariates"
	merge m:1 patid using copd_diagdate, nogen
	keep if event_date <= copd_diagdate

	keep if inlist(medcode, 400)					// Keep bereavement records
	rename event_date bereave_date
	bys patid (bereave_date): keep if _n == 1		// Keep earliest record
	keep patid bereave_date
	gen bereave = 1

	cd "\Covariates"
	save bereave`i', replace
	}

cd "\Covariates"
use bereave1, clear
forvalues i = 2/18 {
	append using bereave`i'
	}
bys patid (bereave_date): keep if _n == 1
save bereave, replace

*********
*Breathlessness
*********

*Use Shah codelist
cd "JB\CPRD\Covariates"

qui import delim "Shah\Shah_BRE.txt", clear
qui levelsof medcode, local(bre_medcode) s(,)


forvalues i = 1/18 {
	cd "Data\Raw"
	use clinical`i', clear

	*Obtain any record of breathlessness prior to COPD diagnosis
	cd "\Covariates"
	merge m:1 patid using copd_diagdate, nogen
	keep if event_date <= copd_diagdate

	keep if inlist(medcode, `bre_medcode')			// Keep breathlessness records
	rename event_date breathless_date
	bys patid (breathless_date): keep if _n == 1		// Keep earliest record
	keep patid breathless_date
	gen breathless = 1

	cd "\Covariates"
	save breathless`i', replace
	}

cd "\Covariates"
use breathless1, clear
forvalues i = 2/18 {
	append using breathless`i'
	}
bys patid (breathless_date): keep if _n == 1
save breathless, replace


*********
*Cancer
*********

*Use Cambridge codelist for prodcodes
cd "JB\CPRD\Covariates"

qui import delim ///
	"CPRDCAM_CAN146_MC_V1-1_Oct2018\CPRDCAM_CAN146_MC_V1-1_Oct2018.csv", clear
forvalues x = 1/10 {
	local y = 200*(`x'-1)
	qui levelsof medcode if inrange(_n,`y',`y'+199), ///
		local(can146_medcode`x') s(,)
	}

forvalues i = 1/18 {
	cd "Data\Raw"
	use clinical`i', clear

	*Obtain any record of cancer diagnosis within 5 years prior to COPD diagnosis
	cd "\Covariates"
	merge m:1 patid using copd_diagdate, nogen
	gen z = inlist(medcode,`can146_medcode1')			// Keep cancer records
	forvalues x = 2/10 {
		if "`can146_medcode`x''" != "" {
			qui replace z = 1 if inlist(medcode,`can146_medcode`x'') & z == 0
			}
		}
	keep if z == 1
	drop z
	keep if event_date <= copd_diagdate
	rename event_date cancer_date
	gen sort_date = - cancer_date
	bys patid (sort_date): keep if _n == 1			// Keep closest before COPD
	keep if (copd_diagdate - cancer_date < 1827)	// Only keep if in last 5 years
	keep patid cancer_date
	gen cancer = 1

	cd "\Covariates"
	save cancer`i', replace
}

cd "\Covariates"
use cancer1, clear
forvalues i = 2/18 {
	append using cancer`i'
	}
bys patid (cancer_date): keep if _n == 1
save cancer, replace

************
*Cancer - lung
************

cd "JB\CPRD\Covariates"

qui import delim ///
	"CPRDCAM_CAN146_MC_V1-1_Oct2018\lung_cancer.txt", clear
qui levelsof medcode, local(lung_c_medcode) s(,)

*Use Cambridge codelist
forvalues i = 1/18 {
	cd "Data\Raw"
	use clinical`i', clear

	*Obtain closest record of lung cancer to date of COPD diagnosis
	cd "\Covariates"
	merge m:1 patid using copd_diagdate, nogen
	keep if inlist(medcode, `lung_c_medcode')
	keep if event_date <= copd_diagdate
	rename event_date lung_c_date
	gen sort_date = - lung_c_date
	bys patid (sort_date): keep if _n == 1			// Keep closest before COPD
	keep patid lung_c_date
	gen lung_c = 1

	cd "\Covariates"
	save lung_c`i', replace
	}

cd "\Covariates"
use lung_c1, clear
forvalues i = 2/18 {
	append using lung_c`i'
	}
bys patid (lung_c_date): keep if _n == 1
save lung_c, replace

*********
*Chronic Kidney Disease (CKD)
*********

cd "JB\CPRD\Covariates"

qui import delim ///
	"CPRDCAM_CKD147_MC_V1-1_Oct2018\CPRDCAM_CKD147_MC_V1-1_Oct2018.csv", clear
qui levelsof medcode, local(ckd147_medcode) s(,)

*Use Cambridge codelist
forvalues i = 1/20 {
	cd "Data\Raw"
	use test`i', clear

	*Obtain closest record of eGFR to date of COPD diagnosis
	cd "\Covariates"
	merge m:1 patid using copd_diagdate, nogen
	keep if enttype == 466						// Keep haemoglobin measurements

	*tab medcode
	keep if inlist(medcode, `ckd147_medcode')
	keep if event_date <= copd_diagdate
	gen sort_date = - event_date
	bys patid (sort_date): gen n = _n
	keep if inlist(n,1,2)							// Keep closest 2 before COPD
	keep patid n event_date data2
	rename data2 ckd_level
	reshape wide ckd_level event_date, i(patid) j(n)
	keep if ckd_level1 < 60 & ckd_level2 < 60		// CKD if both < 60
	keep patid event_date2
	rename event_date2 ckd_date
	gen ckd = 1

	cd "\Covariates"
	save ckd`i', replace
	}

cd "\Covariates"
use ckd1, clear
forvalues i = 2/20 {
	append using ckd`i'
	}
bys patid (ckd_date): keep if _n == 1
save ckd, replace


*********
*Connective tissue disorders (CTD)
*********

*Use code browser list - update when possible
cd "JB\CPRD\Covariates"

qui import delim "Code_browser\gastric_ulcer.txt", clear
qui levelsof medcode, local(ctd_medcode) s(,)

forvalues i = 1/18 {
	
	cd "Data\Raw"
	use clinical`i', clear

	*Obtain any record of CTD prior to COPD diagnosis
	cd "\Covariates"
	merge m:1 patid using copd_diagdate, nogen
	keep if event_date <= copd_diagdate

	keep if inlist(medcode, `ctd_medcode')				// Keep CTD records
	rename event_date ctd_date
	bys patid (ctd_date): keep if _n == 1				// Keep earliest record
	keep patid ctd_date
	gen ctd = 1

	cd "\Covariates"
	save ctd`i', replace
	}

cd "\Covariates"
use ctd1, clear
forvalues i = 2/18 {
	append using ctd`i'
	}
bys patid (ctd_date): keep if _n == 1
save ctd, replace

*********
*Constipation
*********

*Use Cambridge codelist for prodcodes
cd "JB\CPRD\Covariates"

qui import delim ///
	"CPRDCAM_CON150_PC_V1-1_Oct2018\CPRDCAM_CON150_PC_V1-1_Oct2018.csv", clear
forvalues x = 1/10 {
	local y = 200*(`x'-1)
	qui levelsof prodcode if inrange(_n,`y',`y'+199), ///
		local(con150_prodcode`x') s(,)
	}

forvalues i = 1/61 {
	cd "Data\Raw"
	use therapy`i', clear

	*Obtain any record of constipation prior to COPD diagnosis
	cd "\Covariates"
	merge m:1 patid using copd_diagdate, nogen
	gen z = inlist(prodcode,`con150_prodcode1')		// Keep constipation records
	forvalues x = 2/10 {
		if "`con150_prodcode`x''" != "" {
			qui replace z = 1 if inlist(prodcode,`con150_prodcode`x'') & z == 0
			}
		}
	keep if z == 1
	drop z
	keep if event_date <= copd_diagdate
	rename event_date constip_date
	gen sort_date = - constip_date
	keep if (copd_diagdate - constip_date < 366)	// Only keep if in last year
	bys patid (constip_date): keep if _n >= 4		// Only keep if >= 4 prescrips
	bys patid (sort_date): keep if _n == 1			// Keep most recent prescrip
	keep patid constip_date
	gen constip = 1

	cd "\Covariates"
	save constip`i', replace
	}

cd "\Covariates"
use constip1, clear
forvalues i = 2/61 {
	append using constip`i'
	}
bys patid (constip_date): keep if _n == 1
save constip, replace

	
*********
*Coronary artery disease (CAD)/coronary heart disease (CHD)
*********

*Use Cambridge codelist for prodcodes
cd "JB\CPRD\Covariates"

qui import delim ///
	"CPRDCAM_CHD126_MC_V1-1_Oct2018\CPRDCAM_CHD126_MC_V1-1_Oct2018.csv", clear
forvalues x = 1/10 {
	local y = 200*(`x'-1)
	qui levelsof medcode if inrange(_n,`y',`y'+199), ///
		local(cad126_medcode`x') s(,)
	}

forvalues i = 1/18 {
	cd "Data\Raw"
	use clinical`i', clear

	*Obtain any record of CAD prior to COPD diagnosis
	cd "\Covariates"
	merge m:1 patid using copd_diagdate, nogen
	gen z = inlist(medcode,`cad126_medcode1')			// Keep CAD records
	forvalues x = 2/10 {
		if "`cad126_prodcode`x''" != "" {
			qui replace z = 1 if inlist(medcode,`cad126_medcode`x'') & z == 0
			}
		}
	keep if z == 1
	drop z
	keep if event_date <= copd_diagdate
	rename event_date cad_date
	bys patid (cad_date): keep if _n == 1			// Keep earliest
	keep patid cad_date
	gen cad = 1

	cd "\Covariates"
	save cad`i', replace
	}

cd "\Covariates"
use cad1, clear
forvalues i = 2/18 {
	append using cad`i'
	}
bys patid (cad_date): keep if _n == 1
save cad, replace

*********
*Dementia
*********

*Use Cambridge codelist
cd "JB\CPRD\Covariates"

qui import delim ///
	"CPRDCAM_DEM131_MC_V1-1_Oct2018\CPRDCAM_DEM131_MC_V1-1_Oct2018.csv", clear
qui levelsof medcode, local(dem131_medcode) s(,)


forvalues i = 1/18 {
	cd "Data\Raw"
	use clinical`i', clear

	*Obtain any record of dementia prior to COPD diagnosis
	cd "\Covariates"
	merge m:1 patid using copd_diagdate, nogen
	keep if event_date <= copd_diagdate

	keep if inlist(medcode, `dem131_medcode')		// Keep dementia records
	rename event_date dementia_date
	bys patid (dementia_date): keep if _n == 1		// Keep earliest record
	keep patid dementia_date
	gen dementia = 1

	cd "\Covariates"
	save dementia`i', replace
	}

cd "\Covariates"
use dementia1, clear
forvalues i = 2/18 {
	append using dementia`i'
	}
bys patid (dementia_date): keep if _n == 1
save dementia, replace

*********
*Depression
*********

*Use Cambridge codelist for medcodes
cd "JB\CPRD\Covariates"

qui import delim ///
	"CPRDCAM_DEP152_MC_V1-1_Oct2018\CPRDCAM_DEP152_MC_V1-1_Oct2018.csv", clear
qui levelsof medcode, local(dep152_medcode) s(,)

forvalues i = 1/18 {
	cd "Data\Raw"
	use clinical`i', clear

	*Obtain any record of depression diagnosis prior to COPD diagnosis
	cd "\Covariates"
	merge m:1 patid using copd_diagdate, nogen

	keep if inlist(medcode, `dep152_medcode')		// Keep depression records
	keep if event_date <= copd_diagdate
	rename event_date dep_date1
	gen sort_date = - dep_date1
	bys patid (sort_date): keep if _n == 1			// Keep closest before COPD
	keep patid dep_date1
	gen dep1 = 1

	cd "\Covariates"
	save depression1_`i', replace
	}

cd "\Covariates"
use depression1_1, clear
forvalues i = 2/18 {
	append using depression1_`i'
	}
bys patid (dep_date1): keep if _n == 1
save depression1, replace

*Use Cambridge codelist for prodcodes
cd "JB\CPRD\Covariates"

qui import delim ///
	"CPRDCAM_DEP153_PC_V1-1_Oct2018\CPRDCAM_DEP153_PC_V1-1_Oct2018.csv", clear
forvalues x = 1/10 {
	local y = 200*(`x'-1)
	qui levelsof prodcode if inrange(_n,`y',`y'+199), ///
		local(dep153_prodcode`x') s(,)
	}

forvalues i = 1/61 {
	cd "Data\Raw"
	use therapy`i', clear

	*Obtain any record of depression diagnosis prior to COPD diagnosis
	cd "\Covariates"
	merge m:1 patid using copd_diagdate, nogen
	gen z = inlist(prodcode,`dep153_prodcode1')		// Keep depression records
	forvalues x = 2/10 {
		if "`dep153_prodcode`x''" != "" {
			qui replace z = 1 if inlist(prodcode,`dep153_prodcode`x'') & z == 0
			}
		}
	keep if z == 1
	drop z
	keep if event_date <= copd_diagdate
	rename event_date dep_date2
	gen sort_date = - dep_date2
	keep if (copd_diagdate - dep_date2 < 366)		// Only keep if in last year
	bys patid (dep_date2): keep if _n >= 4			// Only keep if >= 4 prescrips
	bys patid (sort_date): keep if _n == 1			// Keep most recent prescrip
	keep patid dep_date2
	gen dep2 = 1

	cd "\Covariates"
	save depression2_`i', replace
	}

cd "\Covariates"
use depression2_1, clear
forvalues i = 2/61 {
	append using depression2_`i'
	}
bys patid (dep_date2): keep if _n == 1
save depression2, replace

cd "\Covariates"
use depression1, replace
merge 1:1 patid using depression2, nogen
keep if dep1 == 1 | dep2 == 1
gen depression = 1
gen depression_date = dep_date1 if dep1 == 1
replace depression_date = dep_date2 if dep1 == 0 | (dep_date2 > dep_date1)
keep patid depression depression_date
save depression, replace

cd "\Covariates"
use depression1, clear
merge 1:1 patid using depression2, nogen
keep if dep1 == 1 | dep2 == 1
gen depression = 1
gen depression_date = dep_date1 if dep1 == 1
replace depression_date = dep_date2 if missing(dep_date1) | ///
	((dep_date2 > dep_date1) & !missing(dep_date2))
keep patid depression depression_date
save depression, replace

*********
*Diabetes
*********

*Use Cambridge codelist for prodcodes
cd "JB\CPRD\Covariates"

qui import delim ///
	"CPRDCAM_DIB128_MC_V1-1_Oct2018\CPRDCAM_DIB128_MC_V1-1_Oct2018.csv", clear
forvalues x = 1/10 {
	local y = 200*(`x'-1)
	qui levelsof medcode if inrange(_n,`y',`y'+199), ///
		local(dib128_medcode`x') s(,)
	}

forvalues i = 1/18 {
	cd "Data\Raw"
	use clinical`i', clear

	*Obtain any record of diabetes diagnosis prior to COPD diagnosis
	cd "\Covariates"
	merge m:1 patid using copd_diagdate, nogen
	gen z = inlist(medcode,`dib128_medcode1')			// Keep diabetes records
	forvalues x = 2/10 {
		if "`dib128_medcode`x''" != "" {
			qui replace z = 1 if inlist(medcode,`dib128_medcode`x'') & z == 0
			}
		}
	keep if z == 1
	drop z
	keep if event_date <= copd_diagdate
	rename event_date diabetes_date
	gen sort_date = - diabetes_date
	bys patid (sort_date): keep if _n == 1			// Keep closest before COPD
	keep patid diabetes_date
	gen diabetes = 1

	cd "\Covariates"
	save diabetes`i', replace
	}

cd "\Covariates"
use diabetes1, clear
forvalues i = 2/18 {
	append using diabetes`i'
	}
bys patid (diabetes_date): keep if _n == 1
save diabetes, replace

*********
*DOSE index
*********

*Calculated from MRC dyspnoea score, FEV1 %pred, smoking status, #exacerbations

/*	
DOSE Index Points				0			1			2			3
MRC Dyspnea Scale score		  0–1			2			3			4
Obstruction FEV1% predicted	  >50		 30–49		  <30	
Smoking status			 Nonsmoker		 Smoker		
Exacerbations per year		  0–1		  2–3		   >3
*/

*********
*Epilepsy
*********

*Use Cambridge codelist
cd "JB\CPRD\Covariates"
qui import delim ///
	"CPRDCAM_EPI155_MC_V1-1_Oct2018\CPRDCAM_EPI155_MC_V1-1_Oct2018.csv", clear
qui levelsof medcode, local(epi155_medcode) s(,)

forvalues i = 1/18 {
	cd "Data\Raw"
	use clinical`i', clear

	*Obtain any record of epilepsy prior to COPD diagnosis
	cd "\Covariates"
	merge m:1 patid using copd_diagdate, nogen
	keep if event_date <= copd_diagdate

	keep if inlist(medcode, `epi155_medcode')		// Keep epilepsy records
	rename event_date epilepsy_date
	bys patid (epilepsy_date): keep if _n == 1		// Keep earliest record
	keep patid epilepsy_date
	gen epilepsy = 1

	cd "\Covariates"
	save epilepsy`i', replace
	}

cd "\Covariates"
use epilepsy1, clear
forvalues i = 2/18 {
	append using epilepsy`i'
	}
bys patid (epilepsy_date): keep if _n == 1
save epilepsy, replace

*********
*Family history of respiratory diseases
*********

cd "JB\CPRD\Covariates"

qui import delim "Shah\FamHistory.txt", clear
qui levelsof medcode, local(fam_medcode) s(,)

forvalues i = 1/18 {
	cd "Data\Raw"
	use clinical`i', clear
	keep if inlist(medcode, `fam_medcode')		// Keep family history records
	bys patid (event_date): keep if _n == 1		// Keep earliest record
	keep patid
	gen famhist_respiratory = 1

	cd "\Covariates"
	save famhist_resp`i', replace
	}

cd "\Covariates"
use famhist_resp1, clear
forvalues i = 2/18 {
	append using famhist_resp`i'
	}
bys patid: keep if _n == 1
save famhist_resp, replace


*********
*Gastric ulcer disease
*********

*Use code browser list - update when possible
cd "JB\CPRD\Covariates"

qui import delim "Code_browser\gastric_ulcer.txt", clear
qui levelsof medcode, local(gastric_medcode) s(,)

forvalues i = 1/18 {
	*Update this codelist when possible
	cd "Data\Raw"
	use clinical`i', clear

	*Obtain any record of gastric ulcer disesase prior to COPD diagnosis
	cd "\Covariates"
	merge m:1 patid using copd_diagdate, nogen
	keep if event_date <= copd_diagdate

	keep if inlist(medcode, `gastric_medcode')		// Keep gastric ulcer records
	bys patid (event_date): keep if _n == 1			// Keep earliest record
	rename event_date g_ulcer_date
	keep patid g_ulcer_date
	gen g_ulcer = 1

	cd "\Covariates"
	save g_ulcer`i', replace
	}

cd "\Covariates"
use g_ulcer1, clear
forvalues i = 2/18 {
	append using g_ulcer`i'
	}
bys patid: keep if _n == 1
save g_ulcer, replace


*********
*Gastro-oesophageal reflux disease
*********

forvalues i = 1/18 {
	*Update this codelist when possible
	cd "Data\Raw"
	use clinical`i', clear

	*Obtain any record of gastro-oesophageal reflux disesase prior to COPD
	cd "\Covariates"
	merge m:1 patid using copd_diagdate, nogen
	keep if event_date <= copd_diagdate

	keep if inlist(medcode, 984, 7104)			// Keep gastro-oesophageal records
	bys patid (event_date): keep if _n == 1			// Keep earliest record
	rename event_date g_reflux_date
	keep patid g_reflux_date
	gen g_reflux = 1

	cd "\Covariates"
	save g_reflux`i', replace
	}

cd "\Covariates"
use g_reflux1, clear
forvalues i = 2/18 {
	append using g_reflux`i'
	}
bys patid: keep if _n == 1
save g_reflux, replace


*********
*Gender
*********

cd "Data\Raw"
use patient, clear
keep patid gender									// males coded as 1

cd "\Covariates"
save gender, replace


*********
*GOLD stage
*********

*Determined by FEV %pred
*1 = 100 > FEV %p >= 80
*2 =  80 > FEV %p >= 50 
*3 =  50 > FEV %p >= 30
*4 =  30 > FEV %p >= 0

cd "\Covariates"
use fev, clear
keep if inrange(fev1pp,0,100)
 
egen gold_stage = cut(fev1pp), at(0 30 50 80 101) icodes
qui replace gold_stage = gold_stage + 1
keep patid gold_stage
save gold_stage, replace

*********
*Heart failure
*********

*Use Cambridge codelist
cd "JB\CPRD\Covariates"

qui import delim ///
	"CPRDCAM_HEF158_MC_V1-1_Oct2018\CPRDCAM_HEF158_MC_V1-1_Oct2018.csv", clear
qui levelsof medcode, local(hef158_medcode) s(,)

forvalues i = 1/18 {
	cd "Data\Raw"
	use clinical`i', clear

	*Obtain any record of heart failure prior to COPD diagnosis
	cd "\Covariates"
	merge m:1 patid using copd_diagdate, nogen
	keep if event_date <= copd_diagdate

	keep if inlist(medcode, `hef158_medcode')		// Keep heart failure records
	rename event_date heart_fail_date
	bys patid (heart_fail_date): keep if _n == 1		// Keep earliest record
	keep patid heart_fail_date
	gen heart_fail = 1

	cd "\Covariates"
	save heart_fail`i', replace
	}

cd "\Covariates"
use heart_fail1, clear
forvalues i = 2/18 {
	append using heart_fail`i'
	}
bys patid: keep if _n == 1
save heart_fail, replace


*********
*Hospitalisations
*********

cd "Data\Raw"
use hes_episodes_gold, clear
gen date = date(epistart, "DMY")
gen year = year(date)
collapse (count) epikey, by(patid year)
collapse (mean) epikey, by(patid)
gen hosp = inrange(epikey,0.5,2.5)
qui replace hosp = 2 if epikey > 2.5
lab def hospLab 0 "None" 1 "1-2 annually" 2 ">=3 annually"
lab val hosp hospLab
keep patid hosp

cd "\Covariates"
save hosp, replace

*********
*Hypertension
*********

*Use Cambridge codelist
cd "JB\CPRD\Covariates"

qui import delim ///
	"CPRDCAM_HYP159_MC_V1-1_Oct2018\CPRDCAM_HYP159_MC_V1-1_Oct2018.csv", clear
qui levelsof medcode, local(hyp159_medcode) s(,)

forvalues i = 1/18 {
	cd "Data\Raw"
	use clinical`i', clear

	*Obtain any record of hypertension prior to COPD diagnosis
	cd "\Covariates"
	merge m:1 patid using copd_diagdate, nogen
	keep if event_date <= copd_diagdate

	keep if inlist(medcode, `hyp159_medcode')		// Keep hypertension records
	rename event_date hyper_date
	bys patid (hyper_date): keep if _n == 1				// Keep earliest record
	keep patid hyper_date
	gen hyper = 1

	cd "\Covariates"
	save hyper`i', replace
	}

cd "\Covariates"
use hyper1, clear
forvalues i = 2/18 {
	append using hyper`i'
	}
bys patid (hyper_date): keep if _n == 1
save hyper, replace


*********
*Ischaemic heart disease (IHD)
*********

cd "JB\CPRD\Covariates"

qui import delim "Shah\IHD.txt", clear
qui levelsof medcode, local(ihd_medcode) s(,)

forvalues i = 1/18 {
	cd "Data\Raw"
	use clinical`i', clear

	*Obtain any record of IHD prior to COPD diagnosis
	cd "\Covariates"
	merge m:1 patid using copd_diagdate, nogen
	keep if event_date <= copd_diagdate

	keep if inlist(medcode, `ihd_medcode')				// Keep IHD records
	rename event_date ihd_date
	bys patid (ihd_date): keep if _n == 1				// Keep earliest record
	keep patid ihd_date
	gen ihd = 1

	cd "\Covariates"
	save ihd`i', replace
	}

cd "\Covariates"
use ihd1, clear
forvalues i = 2/18 {
	append using ihd`i'
	}
bys patid (ihd_date): keep if _n == 1
save ihd, replace


*********
*Irritable bowel syndrome (IBS)
*********

*Use Cambridge codelist for medcodes
cd "JB\CPRD\Covariates"

qui import delim ///
	"CPRDCAM_IBS161_MC_V1-1_Oct2018\CPRDCAM_IBS161_MC_V1-1_Oct2018.csv", clear
qui levelsof medcode, local(ibs161_medcode) s(,)

forvalues i = 1/18 {
cd "Data\Raw"
	use clinical`i', clear

	*Obtain any record of IBS diagnosis prior to COPD diagnosis
	cd "\Covariates"
	merge m:1 patid using copd_diagdate, nogen

	keep if inlist(medcode, `ibs161_medcode')		// Keep IBS records
	keep if event_date <= copd_diagdate
	rename event_date ibs_date1
	gen sort_date = - ibs_date1
	bys patid (sort_date): keep if _n == 1			// Keep closest before COPD
	keep patid ibs_date1
	gen ibs1 = 1

	cd "\Covariates"
	save ibs1_`i', replace
	}

cd "\Covariates"
use ibs1_1, clear
forvalues i = 2/18 {
	append using ibs1_`i'
	}
bys patid (ibs_date1): keep if _n == 1
save ibs1, replace

*Use Cambridge codelist for prodcodes
cd "JB\CPRD\Covariates"

qui import delim ///
	"CPRDCAM_IBS162_PC_V1-1_Oct2018\CPRDCAM_IBS162_PC_V1-1_Oct2018.csv", clear
qui levelsof prodcode, local(ibs162_prodcode) s(,)

forvalues i = 1/61 {
	cd "Data\Raw"
	use therapy`i', clear

	*Obtain any record of IBS diagnosis prior to COPD diagnosis
	cd "\Covariates"
	merge m:1 patid using copd_diagdate, nogen

	keep if inlist(prodcode, `ibs162_prodcode')			// Keep IBS records

	keep if event_date <= copd_diagdate
	rename event_date ibs_date2
	gen sort_date = - ibs_date2
	keep if (copd_diagdate - ibs_date2 < 366)		// Only keep if in last year
	bys patid (ibs_date2): keep if _n >= 4			// Only keep if >= 4 prescrips
	bys patid (sort_date): keep if _n == 1			// Keep most recent prescrip
	keep patid ibs_date2
	gen ibs2 = 1

	cd "\Covariates"
	save ibs2_`i', replace
	}

cd "\Covariates"
use ibs2_1, clear
forvalues i = 2/61 {
	append using ibs2_`i'
	}
bys patid (ibs_date2): keep if _n == 1
save ibs2, replace

cd "\Covariates"
use ibs1, replace
merge 1:1 patid using ibs2, nogen
keep if ibs1 == 1 | ibs2 == 1
gen ibs = 1
gen ibs_date = ibs_date1 if ibs1 == 1
replace ibs_date = ibs_date2 if missing(ibs1) | ///
	((ibs_date2 > ibs_date1) & !missing(ibs_date2))
keep patid ibs ibs_date
save ibs, replace


*********
*Inflammatory bowel disease (IBD)
*********

*Use Kiddle codelist (from old Cambridge files)
cd "JB\CPRD\Covariates"

qui import delim "Kiddle\Kiddle_IBD097.csv", clear
qui levelsof medcode, local(ibd097_medcode) s(,)

forvalues i = 1/18 {
	cd "Data\Raw"
	use clinical`i', clear

	*Obtain any record of breathlessness prior to COPD diagnosis
	cd "\Covariates"
	merge m:1 patid using copd_diagdate, nogen
	keep if event_date <= copd_diagdate

	keep if inlist(medcode, `ibd097_medcode')			// Keep IBD records
	rename event_date ibd_date
	bys patid (ibd_date): keep if _n == 1				// Keep earliest record
	keep patid ibd_date
	gen ibd = 1

	cd "\Covariates"
	save ibd`i', replace
	}

cd "\Covariates"
use ibd1, clear
forvalues i = 2/18 {
	append using ibd`i'
	}
bys patid (ibd_date): keep if _n == 1
save ibd, replace


*********
*Influenza vaccinations
*********

*Use LSHTM codelist
cd "JB\CPRD\Covariates"

qui import delim "LSHTM\LSHTM_FLU.txt", clear
qui levelsof medcode, local(flu_medcode) s(,)

forvalues i = 1/18 {
	cd "Data\Raw"
	use clinical`i', clear

	*Obtain any record of influenza vaccinations prior to COPD diagnosis
	cd "\Covariates"
	merge m:1 patid using copd_diagdate, nogen
	keep if event_date <= copd_diagdate

	keep if inlist(medcode, `flu_medcode')			// Keep influenza records
	rename event_date flu_date
	bys patid (flu_date): keep if _n == 1			// Keep earliest record
	keep patid flu_date
	gen flu = 1

	cd "\Covariates"
	save flu`i', replace
	}

cd "\Covariates"
use flu1, clear
forvalues i = 2/18 {
	append using flu`i'
	}
bys patid (flu_date): keep if _n == 1
save flu, replace


*********
*Inhaled corticosteroid use (ICS)
*********

*Use Chalmers 2018 codelist
*respiratory-research.biomedcentral.com/articles/10.1186/s12931-018-0767-2
cd "JB\CPRD\Covariates"

qui import excel "Chalmers\ics_prodcodes", firstrow clear
forvalues x = 1/2 {
	local y = 200*(`x'-1)
	qui levelsof prodcode if inrange(_n,`y',`y'+199), ///
		local(ics_prodcode`x') s(,)
	}

forvalues i = 1/61 {
	cd "Data\Raw"
	use therapy`i', clear

	*Obtain any record of influenza vaccinations prior to COPD diagnosis
	cd "\Covariates"
	merge m:1 patid using copd_diagdate, nogen
	keep if event_date <= copd_diagdate
	gen z = inlist(prodcode,`ics_prodcode1')			// Keep ICS records
	qui replace z = 1 if inlist(prodcode,`ics_prodcode2') & z == 0
	keep if z == 1
	drop z
	rename event_date ics_date
	bys patid (ics_date): keep if _n == 1			// Keep earliest record
	keep patid ics_date
	gen ics = 1

	cd "\Covariates"
	save ics`i', replace
	}

cd "\Covariates"
use ics1, clear
forvalues i = 2/61 {
	append using ics`i'
	}
bys patid (ics_date): keep if _n == 1
save ics, replace


*********
*Liver disease
*********

*Use Cambridge codelists for mild and moderate/severe liver disease
cd "JB\CPRD\Covariates"

qui import delim ///
	"CPRDCAM_C11133_MC_V1-1_Oct2018\CPRDCAM_C11133_MC_V1-1_Oct2018.csv", clear
qui levelsof medcode, local(c11133_medcode) s(,)
qui import delim ///
	"CPRDCAM_C12134_MC_V1-1_Oct2018\CPRDCAM_C12134_MC_V1-1_Oct2018.csv", clear
qui levelsof medcode, local(c12134_medcode) s(,)

forvalues i = 1/18 {
	cd "Data\Raw"
	use clinical`i', clear

	*Obtain any record of hypertension prior to COPD diagnosis
	cd "\Covariates"
	merge m:1 patid using copd_diagdate, nogen
	keep if event_date <= copd_diagdate

	keep if inlist(medcode, `c11133_medcode', `c12134_medcode')	// Keep liver
	rename event_date liver_date
	bys patid (liver_date): keep if _n == 1				// Keep earliest record
	keep patid liver_date
	gen liver = 1

	cd "\Covariates"
	save liver`i', replace
	}

cd "\Covariates"
use liver1, clear
forvalues i = 2/18 {
	append using liver`i'
	}
bys patid (liver_date): keep if _n == 1
save liver, replace


*********
*Long acting beta agonist (LABA)
*********

*Use Chalmers 2018 codelist
*respiratory-research.biomedcentral.com/articles/10.1186/s12931-018-0767-2
cd "JB\CPRD\Covariates"

qui import excel "Chalmers\laba_prodcodes", firstrow clear
qui levelsof prodcode, local(laba_prodcode) s(,)

forvalues i = 1/61 {
	cd "Data\Raw"
	use therapy`i', clear

	*Obtain any record of LABA prior to COPD diagnosis
	cd "\Covariates"
	merge m:1 patid using copd_diagdate, nogen
	keep if event_date <= copd_diagdate
	keep if inlist(prodcode,`laba_prodcode')			// Keep LABA records
	rename event_date laba_date
	bys patid (laba_date): keep if _n == 1			// Keep earliest record
	keep patid laba_date
	gen laba = 1

	cd "\Covariates"
	save laba`i', replace
	}

cd "\Covariates"
use laba1, clear
forvalues i = 2/61 {
	append using laba`i'
	}
bys patid (laba_date): keep if _n == 1
save laba, replace

*********
*Long acting muscarinic antagonist use (LAMA)
*********

*Use Chalmers 2018 codelist
*respiratory-research.biomedcentral.com/articles/10.1186/s12931-018-0767-2
cd "JB\CPRD\Covariates"

qui import excel "Chalmers\lama_prodcodes", firstrow clear
qui levelsof prodcode, local(lama_prodcode) s(,)

forvalues i = 1/61 {
	cd "Data\Raw"
	use therapy`i', clear

	*Obtain any record of LABA prior to COPD diagnosis
	cd "\Covariates"
	merge m:1 patid using copd_diagdate, nogen
	keep if event_date <= copd_diagdate
	keep if inlist(prodcode,`lama_prodcode')			// Keep LAMA records
	rename event_date lama_date
	bys patid (lama_date): keep if _n == 1			// Keep earliest record
	keep patid lama_date
	gen lama = 1

	cd "\Covariates"
	save lama`i', replace
	}

cd "\Covariates"
use lama1, clear
forvalues i = 2/61 {
	append using lama`i'
	}
bys patid (lama_date): keep if _n == 1
save lama, replace


*********
*Lung fibrosis
*********

forvalues i = 1/18 {
	*Use code browser list (search: *pulmonary fibrosis*) - need to update
	cd "Data\Raw"
	use clinical`i', clear

	*Obtain any record of MRC dyspnoea score prior to COPD diagnosis
	cd "\Covariates"
	merge m:1 patid using copd_diagdate, nogen
	keep if event_date <= copd_diagdate

	keep if inlist(medcode, 103472, 103753, 22536, 46795, 47782, 6051, 7791)
	gen sort_date = - event_date
	bys patid (sort_date): keep if _n == 1			// Keep most recent record
	rename event_date lungfib_date
	keep patid lungfib_date
	gen lungfib = 1

	cd "\Covariates"
	save lungfib`i', replace
	}

cd "\Covariates"
use lungfib1, clear
forvalues i = 2/18 {
	append using lungfib`i'
	}
bys patid (lungfib_date): keep if _n == 1
save lungfib, replace


*********
*(Modified) MRC dyspnoea score
*********

forvalues i = 1/18 {
	*Use code browser list - seems thorough as has all 5 scales
	cd "Data\Raw"
	use clinical`i', clear

	*Obtain any record of MRC dyspnoea score prior to COPD diagnosis
	cd "\Covariates"
	merge m:1 patid using copd_diagdate, nogen
	keep if event_date <= copd_diagdate

	keep if inlist(medcode, 19432, 19427, 19426, 19430, 19429)	// Keep MRC
	gen sort_date = - event_date				
	bys patid (sort_date): keep if _n == 1			// Keep most recent record
	rename event_date mrc_dyspnoea_date
	gen mrc_dyspnoea = 1 if medcode == 19432
	qui replace mrc_dyspnoea = 2 if medcode == 19427
	qui replace mrc_dyspnoea = 3 if medcode == 19426
	qui replace mrc_dyspnoea = 4 if medcode == 19430
	qui replace mrc_dyspnoea = 5 if medcode == 19429
	keep patid mrc_dyspnoea mrc_dyspnoea_date

	cd "\Covariates"
	save mrc`i', replace
	}

cd "\Covariates"
use mrc1, clear
forvalues i = 2/18 {
	append using mrc`i'
	}
bys patid (mrc_dyspnoea_date): keep if _n == 1
save mrc, replace


*********
*Myocardial infarction
*********

*Use OpenSafely codelist - update when possible
cd "JB\CPRD\Covariates"

import delimited "OpenSafe\OpenSafe_mi.csv", clear varn(1)
rename ctv3code readcode
keep if _n <= 30
cd "JB\CPRD"
merge 1:1 readcode using Gold_Medcode, nogen keep(1 3)
qui levelsof medcode, local(mi_medcode) s(,)

forvalues i = 1/18 {
	cd "Data\Raw"
	use clinical`i', clear

	*Obtain any record of myocardial infarction prior to COPD diagnosis
	cd "\Covariates"
	merge m:1 patid using copd_diagdate, nogen
	keep if event_date <= copd_diagdate

	keep if inlist(medcode, `mi_medcode')				// Keep MI records
	rename event_date mi_date
	bys patid (mi_date): keep if _n == 1				// Keep earliest record
	keep patid mi_date
	gen mi = 1

	cd "\Covariates"
	save mi`i', replace
	}

cd "\Covariates"
use mi1, clear
forvalues i = 2/18 {
	append using mi`i'
	}
bys patid (mi_date): keep if _n == 1
save mi, replace


*********
*Number of exacerbations (in 12 months prior to diagnosis)
*********

*Use Rothnie et al codes alongside Shah definition
*One of: LRTI/COPD exacerbation OR antibiotics+OCS OR symptom+(antibiotics/OCS)

*Definition 1 - LRTI or COPD exacerbation
cd "JB\CPRD\Covariates"

import excel "Rothnie\Rothnie_lrti", firstrow clear
rename Medicalcode medcode
qui levelsof medcode, local(exac1_medcode)

forvalues i = 1/18 {
	cd "Data\Raw"
	use clinical`i', clear

	*Obtain any record of exacerbations 12 months prior to COPD diagnosis
	cd "\Covariates"
	merge m:1 patid using copd_diagdate, nogen
	keep if event_date <= inrange(event_date, copd_diagdate - 366, copd_diagdate)
	keep if inlist(medcode, `exac1_medcode')		// Keep exacerbation records
	rename event_date exac1_date
	keep patid exac1_date

	cd "\Covariates"
	save exac1_`i', replace
	}

cd "\Covariates"
use exac1_1, clear
forvalues i = 2/18 {
	append using exac1_`i'
	}
save exac1, replace

*Definition 2 - antibiotics and OCS prescribed on same day
cd "JB\CPRD\Covariates"

import excel "Rothnie\Rothnie_ocs", firstrow clear
rename Productcode prodcode
qui levelsof prodcode, local(exac2_prodcode_ocs)

import excel "Rothnie\Rothnie_ab", firstrow clear
rename Productcode prodcode
forvalues x = 1/5 {
	local y = 200*(`x'-1)
	qui levelsof prodcode if inrange(_n,`y',`y'+199), ///
		local(exac2_prodcode_ab`x') s(,)
	}

forvalues i = 1/61 {
cd "Data\Raw"
	use therapy`i', clear

	*Obtain any record of exacerbations 12 months prior to COPD diagnosis
	cd "\Covariates"
	merge m:1 patid using copd_diagdate, nogen
	keep if event_date <= inrange(event_date, copd_diagdate - 366, copd_diagdate)
	gen z1 = inlist(prodcode,`exac2_prodcode_ocs')			// Keep OCS records
	gen z2 = inlist(prodcode,`exac2_prodcode_ab1')			// Keep AB records
	forvalues x = 2/5 {
		if "`exac2_prodcode_ab`x''" != "" {
			qui replace z2 = 1 if inlist(prodcode,`exac2_prodcode_ab`x'') & z2 == 0
			}
		}
	keep if z1 == 1 | z2 == 1						// Keep exacerbation records
	gen test = .						// Exacerbation if OCS and AB on same day
	local n = _N
	forvalues j = 2/`n' {
		qui replace test = 1 in `j' if event_date[`j'] == event_date[`j'-1] & ///
			patid[`j'] == patid[`j'-1] & ///
			((z1[`j'] == 1 & z2[`j'-1] == 1) | (z2[`j'] == 1 & z1[`j'-1] == 1))
		}
	keep if test == 1
	bys patid event_date (test): keep if _n == 1
	rename event_date exac2_date
	keep patid exac2_date

	cd "\Covariates"
	save exac2_`i', replace
	}

cd "\Covariates"
use exac2_1, clear
forvalues i = 2/61 {
	append using exac2_`i'
	}
save exac2, replace


*Definition 3 - 2 or more COPD symptoms
cd "JB\CPRD\Covariates"

import excel "Rothnie\Rothnie_copd_symp", firstrow clear
rename Medicalcodes medcode
forvalues x = 1/5 {
	local y = 200*(`x'-1)
	qui levelsof medcode if inrange(_n,`y',`y'+199), ///
		local(exac3_medcode`x') s(,)
	}

forvalues i = 1/18 {
	cd "Data\Raw"
	use clinical`i', clear

	*Obtain any record of exacerbations 12 months prior to COPD diagnosis
	cd "\Covariates"
	merge m:1 patid using copd_diagdate, nogen
	keep if event_date <= inrange(event_date, copd_diagdate - 366, copd_diagdate)
	gen z = inlist(medcode,`exac3_medcode1')		// Keep COPD symptom records
	forvalues x = 2/5 {
		if "`exac3_medcode`x''" != "" {
			qui replace z = 1 if inlist(medcode,`exac3_medcode`x'') & z == 0
			}
		}
	keep if z == 1
	drop z
	bys patid event_date: keep if _n == 2	// Keep if 2 or more records same day
	rename event_date exac3_date
	keep patid exac3_date

	cd "\Covariates"
	save exac3_`i', replace
	}

cd "\Covariates"
use exac3_1, clear
forvalues i = 2/18 {
	append using exac3_`i'
	}
save exac3, replace


*Count number of exacerbations per patient in last year
cd "\Covariates"
use exac1, clear
append using exac2 exac3
gen exac_date = min(exac1_date, exac2_date, exac3_date)
collapse (count) exac_date, by(patid)
save exac, replace


*********
*Osteoarthritis
*********

*Use Manchester codelist
cd "JB\CPRD\Covariates"

qui import delim "Manchester\OSA_readcodes.csv", varn(1) clear
rename code readcode
cd "JB\CPRD"
merge 1:1 readcode using Gold_Medcode, nogen keep(1 3)
qui levelsof medcode, local(osa_medcode) s(,)

forvalues i = 1/18 {
	cd "Data\Raw"
	use clinical`i', clear

	*Obtain any record of osteoporosis prior to COPD diagnosis
	cd "\Covariates"
	merge m:1 patid using copd_diagdate, nogen
	keep if event_date <= copd_diagdate

	keep if inlist(medcode, `osa_medcode')			// Keep osteoarthritis records
	rename event_date osteoa_date
	bys patid (osteoa_date): keep if _n == 1			// Keep earliest record
	keep patid osteoa_date
	gen osteoa = 1

	cd "\Covariates"
	save osteoa`i', replace
	}

use osteoa1, clear
forvalues i = 2/18 {
	append using osteoa`i'
	}
save osteoa, replace


*********
*Osteoporosis
*********

*Use Manchester codelist
cd "JB\CPRD\Covariates"

qui import delim "Manchester\OSP_readcodes.csv", varn(1) clear
rename code readcode
bys readcode: keep if _n == 1
cd "JB\CPRD"
merge 1:1 readcode using Gold_Medcode, nogen keep(1 3)
qui levelsof medcode, local(osp_medcode) s(,)

forvalues i = 1/18 {
	cd "Data\Raw"
	use clinical`i', clear

	*Obtain any record of osteoporosis prior to COPD diagnosis
	cd "\Covariates"
	merge m:1 patid using copd_diagdate, nogen
	keep if event_date <= copd_diagdate

	keep if inlist(medcode, `osp_medcode')			// Keep osteoporosis records
	rename event_date osteop_date
	bys patid (osteop_date): keep if _n == 1			// Keep earliest record
	keep patid osteop_date
	gen osteop = 1

	cd "\Covariates"
	save osteop`i', replace
	}

use osteop1, clear
forvalues i = 2/18 {
	append using osteop`i'
	}
save osteop, replace


*********
*Oxygen therapy
*********

forvalues i = 1/18 {
	*LSHTM list - update this codelist when possible
	cd "Data\Raw"
	use clinical`i', clear

	*Obtain any record of oxygen therapy prior to COPD diagnosis
	cd "\Covariates"
	merge m:1 patid using copd_diagdate, nogen
	keep if event_date <= copd_diagdate

	keep if inlist(medcode, 26435, 32889, 18115)	// Keep oxygen therapy records
	bys patid (event_date): keep if _n == 1			// Keep earliest record
	rename event_date oxygen_date
	keep patid oxygen_date
	gen oxygen = 1

	cd "\Covariates"
	save oxygen`i', replace
	}

use oxygen1, clear
forvalues i = 2/18 {
	append using oxygen`i'
	}
save oxygen, replace


*********
*Peripheral vascular disorder (PVD)
*********

*Use Cambridge codelist
cd "JB\CPRD\Covariates"

qui import delim ///
	"CPRDCAM_PVD168_MC_V1-1_Oct2018\CPRDCAM_PVD168_MC_V1-1_Oct2018.csv", clear
qui levelsof medcode, local(pvd168_medcode) s(,)

forvalues i = 1/18 {
	cd "Data\Raw"
	use clinical`i', clear

	*Obtain any record of peripheral vascular disorder prior to COPD diagnosis
	cd "\Covariates"
	merge m:1 patid using copd_diagdate, nogen
	keep if event_date <= copd_diagdate

	keep if inlist(medcode, `pvd168_medcode')		// Keep PVD records
	rename event_date pvd_date
	bys patid (pvd_date): keep if _n == 1			// Keep earliest record
	keep patid pvd_date
	gen pvd = 1

	cd "\Covariates"
	save pvd`i', replace
	}

use pvd1, clear
forvalues i = 2/18 {
	append using pvd`i'
	}
save pvd, replace


*********
*Platelets
*********

forvalues i = 1/20 {
	cd "Data\Raw"
	use test`i', clear

	*Obtain closest record of albumin to date of COPD diagnosis
	cd "\Covariates"
	merge m:1 patid using copd_diagdate, nogen
	keep if enttype == 189						// Keep platelet measurements
	*tab medcode
	keep if medcode == 7
	keep if event_date <= copd_diagdate
	gen sort_date = - event_date
	bys patid (sort_date): keep if _n == 1		// Keep closest before COPD
	rename data2 platelet_level
	gen platelet = platelet_level > 150
	qui replace platelet = 2 if platelet_level > 400
	qui replace platelet = platelet + 1
	qui replace platelet = . if platelet_level == .
	lab def platLab 1 "< 150x10^9 /L" 2 "150-400x10^9 /L" 3 ">= 400x10^9 /L"
	lab val platelet platLab
	rename event_date platelet_date
	keep patid platelet platelet_level platelet_date
	order patid platelet platelet_level platelet_date

	cd "\Covariates"
	save platelet`i', replace
	}

use platelet1, clear
forvalues i = 2/18 {
	append using platelet`i'
	}
save platelet, replace


*********
*Pneumococcal vaccinations
*********

*Use LSHTM codelist
cd "JB\CPRD\Covariates"

qui import delim "LSHTM\LSHTM_PPV.txt", clear
qui levelsof medcode, local(ppv_medcode) s(,)

forvalues i = 1/18 {
	cd "Data\Raw"
	use clinical`i', clear

	*Obtain any record of pneumonococcal vaccinations prior to COPD diagnosis
	cd "\Covariates"
	merge m:1 patid using copd_diagdate, nogen
	keep if event_date <= copd_diagdate

	keep if inlist(medcode, `ppv_medcode')			// Keep pneumo records
	rename event_date pneumo_date
	bys patid (pneumo_date): keep if _n == 1			// Keep earliest record
	keep patid pneumo_date
	gen pneumo = 1

	cd "\Covariates"
	save pneumo`i', replace
	}

use pneumo1, clear
forvalues i = 2/18 {
	append using pneumo`i'
	}
save pneumo, replace

*********
*Pulmonary embolism
*********

*Use HDR UK codelist
cd "JB\CPRD\Covariates"

qui import delim "HDR\HDR_pulm", clear
rename code medcode
qui levelsof medcode, local(pulm_medcode) s(,)

forvalues i = 1/18 {
	cd "Data\Raw"
	use clinical`i', clear

	*Obtain any record of pulmonary embolism prior to COPD diagnosis
	cd "\Covariates"
	merge m:1 patid using copd_diagdate, nogen
	keep if event_date <= copd_diagdate

	keep if inlist(medcode, `pulm_medcode')			// Keep pulmonary embolisms
	rename event_date pulm_e_date
	bys patid (pulm_e_date): keep if _n == 1			// Keep earliest record
	keep patid pulm_e_date
	gen pulm_e = 1

	cd "\Covariates"
	save pulm_e`i', replace
	}

use pulm_e1, clear
forvalues i = 2/18 {
	append using pulm_e`i'
	}
save pulm_e, replace

*********
*Pulmonary fibrosis
*********

forvalues i = 1/18 {
	*Use Strongman et al (2018) codelist
	cd "Data\Raw"
	use clinical`i', clear

	*Obtain any record of pulmonary fibrosis prior to COPD diagnosis
	cd "\Covariates"
	merge m:1 patid using copd_diagdate, nogen
	keep if event_date <= copd_diagdate

	keep if inlist(medcode, 6051, 103472, 63174)  // Keep pulmonary fibroses
	rename event_date pulm_f_date
	bys patid (pulm_f_date): keep if _n == 1			// Keep earliest record
	keep patid pulm_f_date
	gen pulm_f = 1

	cd "\Covariates"
	save pulm_f`i', replace
	}

use pulm_f1, clear
forvalues i = 2/18 {
	append using pulm_f`i'
	}
save pulm_f, replace

*********
*Pulmonary tuberculosis
*********

*Use Shah codelist
cd "JB\CPRD\Covariates"

qui import delim "Shah\PTB.txt", clear
qui levelsof medcode, local(ptb_medcode) s(,)

forvalues i = 1/18 {
	cd "Data\Raw"
	use clinical`i', clear

	*Obtain any record of pulmonary tuberculosis prior to COPD diagnosis
	cd "\Covariates"
	merge m:1 patid using copd_diagdate, nogen
	keep if event_date <= copd_diagdate

	keep if inlist(medcode, `ptb_medcode')	// Keep pulmonary TB records
	rename event_date pulm_t_date
	bys patid (pulm_t_date): keep if _n == 1			// Keep earliest record
	keep patid pulm_t_date
	gen pulm_t = 1

	cd "\Covariates"
	save pulm_t`i', replace
	}

use pulm_t1, clear
forvalues i = 2/18 {
	append using pulm_t`i'
	}
save pulm_t, replace


*********
*Psychosis/bipolar
*********

*Use Cambridge codelist for medcodes
cd "JB\CPRD\Covariates"
qui import delim ///
	"CPRDCAM_SCZ175_MC_V1-1_Oct2018\CPRDCAM_SCZ175_MC_V1-1_Oct2018.csv", clear
qui levelsof medcode, local(scz175_medcode) s(,)

forvalues i = 1/18 {
	cd "Data\Raw"
	use clinical`i', clear

	*Obtain any record of psychosis/bipolar diagnosis prior to COPD diagnosis
	cd "\Covariates"
	merge m:1 patid using copd_diagdate, nogen

	keep if inlist(medcode, `scz175_medcode')		// Keep psychosis/bipolar
	keep if event_date <= copd_diagdate
	rename event_date psychosis_date1
	bys patid (psychosis_date1): keep if _n == 1	// Keep earliest record
	keep patid psychosis_date1
	gen psychosis1 = 1

	cd "\Covariates"
	save psychosis1_`i', replace
	}

use psychosis1_1, clear
forvalues i = 2/18 {
	append using psychosis1_`i'
	}
save psychosis1, replace

*Use Cambridge codelist for prodcodes
cd "JB\CPRD\Covariates"

qui import delim ///
	"CPRDCAM_SCZ176_PC_V1-1_Oct2018\CPRDCAM_SCZ176_PC_V1-1_Oct2018.csv", clear
qui levelsof prodcode, local(scz176_prodcode) s(,)

forvalues i = 1/61 {
	cd "Data\Raw"
	use therapy`i', clear

	*Obtain any record of psychosis/bipolar diagnosis prior to COPD diagnosis
	cd "\Covariates"
	merge m:1 patid using copd_diagdate, nogen
	keep if inlist(prodcode,`scz176_prodcode')
	keep if event_date <= copd_diagdate
	rename event_date psychosis_date2
	bys patid (psychosis_date2): keep if _n == 1	// Keep earliest prescription
	keep patid psychosis_date2
	gen psychosis2 = 1

	cd "\Covariates"
	save psychosis2_`i', replace
	}

use psychosis2_1, clear
forvalues i = 2/61 {
	append using psychosis2_`i'
	}
save psychosis2, replace

cd "\Covariates"
use psychosis1, replace
merge 1:1 patid using psychosis2, nogen
keep if psychosis1 == 1 | psychosis2 == 1
gen psychosis = 1
gen psychosis_date = psychosis_date1 if psychosis1 == 1
replace psychosis_date = psychosis_date2 if missing(psychosis_date1) | ///
	((psychosis_date2 > psychosis_date1) & !missing(psychosis_date2))
keep patid psychosis psychosis_date
save psychosis, replace


*********
*Rheumatoid arthritis
*********

*Use Cambridge codelist
cd "JB\CPRD\Covariates"

qui import delim ///
	"CPRDCAM_RHE174_MC_V1-1_Oct2018\CPRDCAM_RHE174_MC_V1-1_Oct2018.csv", clear
qui levelsof medcode, local(rhe174_medcode) s(,)

forvalues i = 1/18 {
	cd "Data\Raw"
	use clinical`i', clear

	*Obtain any record of rheumatoid arthritis prior to COPD diagnosis
	cd "\Covariates"
	merge m:1 patid using copd_diagdate, nogen
	keep if event_date <= copd_diagdate

	keep if inlist(medcode, `rhe174_medcode')	// Keep rheumatoid arthritis
	rename event_date rheumatoid_date
	bys patid (rheumatoid_date): keep if _n == 1		// Keep earliest record
	keep patid rheumatoid_date
	gen rheumatoid = 1

	cd "\Covariates"
	save rheumatoid`i', replace
	}

use rheumatoid1, clear
forvalues i = 2/18 {
	append using rheumatoid`i'
	}
save rheumatoid, replace


*********
*Socioeconomic status
*********

cd "Data\Raw"
use patient_imd_gold, clear
rename e2019_imd_5 imd
keep patid imd

cd "\Covariates"
save imd, replace

*********
*Smoking status
*********
*HE added new codes
forvalues i = 1/18 {
	
*Use Shah codelist for never, former, current smoking status
cd "Data\Raw"
use clinical`i', clear

*Obtain any record of never smoking
gen smoke_n = inlist(medcode, 33, 98177)

*Obtain any record of former smoking
gen smoke_f = inlist(medcode, 97210,12946,230314,221248,276052,99838,72700,7130, ///
102361,12878,266945,12955,43433,776,12956,97973,98447,72706, ///
19488,26470,100963,12961,90,12959,12957,239315,10898,248528, ///
101338,294328,103955,100099,100495,62686)

*Obtain any record of current smoking
gen smoke_c = inlist(medcode, 46321,12952,248526,101519,93,74907,68658,46300, ///
98154,12951,12944,70746,95610,30762,9045,294327,257726,98347,203207,32687,12947, ///
12943,53101,90522,54,40418,12941,1823,1822,41979,1878,18926,12966,31114, ///
104310,12945,203208,276050,10742,309558,12964,10558,257725,11713,42288, ///
2111,35055,10184,12958,12954,3568,12965,41042,266944,12960,12240, ///
30423,276051,285187,12967,12963,26096,12942)
	
**********

preserve
*Bloom definition: history of smoking (current or ex) prior to COPD diagnosis
cd "\Covariates"
merge m:1 patid using copd_diagdate, nogen
keep if event_date <= copd_diagdate
keep if smoke_c == 1 | smoke_f == 1

*Keep most recent record of smoking history
gen sort_date = - event_date
bys patid (sort_date): keep if _n == 1
rename event_date smoke_date
keep patid smoke_date
gen smoke_status = 1

cd "\Covariates"
save smoke_bloom`i', replace
restore

**********

preserve
*Kiddle definition: most recent smoking status (current, ex or never)
cd "\Covariates"
merge m:1 patid using copd_diagdate, nogen
keep if smoke_c == 1 | smoke_f == 1 | smoke_n == 1

*Keep most recent record of smoking history
gen sort_date = - event_date
bys patid (sort_date): keep if _n == 1
rename event_date smoke_date
gen smoke_status = smoke_n + 2*smoke_f + 3*smoke_c
keep patid smoke_date smoke_status
lab def smokeLab 1 "Never" 2 "Former" 3 "Current"
lab val smoke_status smokeLab

cd "\Covariates"
save smoke_kiddle`i', replace
restore

**********

preserve
*Shah definition: model over time
*Keep all records of smoking status to use in FSM
keep if smoke_c == 1 | smoke_f == 1 | smoke_n == 1
rename event_date smoke_date
keep patid smoke_*

cd "\Covariates"
save smoke_shah`i', replace
restore
}

use smoke_bloom1, clear
forvalues i = 2/18 {
	append using smoke_bloom`i'
	}
rename smoke_date smoke_date_b
rename smoke_status smoke_status_b
save smoke_bloom, replace

use smoke_shah1, clear
forvalues i = 2/18 {
	append using smoke_shah`i'
	}
rename smoke_date smoke_date_s
rename smoke_n smoke_n_s
rename smoke_f smoke_f_s
rename smoke_c smoke_c_s
save smoke_shah, replace

use smoke_kiddle1, clear
forvalues i = 2/18 {
	append using smoke_kiddle`i'
	}
rename smoke_date smoke_date_k
rename smoke_status smoke_status_k
save smoke_kiddle, replace

*Create FSM structure for Shah smoking status
cd "\Covariates"
use smoke_shah, clear
gen smoke_status_s = 0*smoke_n_s + 1*smoke_f_s + 2*smoke_c_s
lab def smoke_shah 0 "Never" 1 "Former" 2 "Current"
lab val smoke_status_s smoke_shah
drop smoke_n_s smoke_f_s smoke_c_s

*remove all "never smoked" from patients who have more than 1 smoking record
bys patid (smoke_date_s): drop if smoke_s == 0 & _n > 1

*remove multiple entries from same day
bys patid smoke_date_s: drop if _n > 1

*only keep transitions between smoking statuses
duplicates drop patid smoke_status_s, force

bys patid (smoke_date_s): gen j = _n
reshape wide smoke_date_s smoke_status_s, i(patid) j(j)
save smoke_shah, replace


*********
*Stroke
*********

*Use Cambridge codelist
cd "JB\CPRD\Covariates"

qui import delim ///
	"CPRDCAM_STR130_MC_V1-1_Oct2018\CPRDCAM_STR130_MC_V1-1_Oct2018.csv", clear
qui levelsof medcode, local(str130_medcode) s(,)

forvalues i = 1/18 {
	cd "Data\Raw"
	use clinical`i', clear

	*Obtain any record of stroke prior to COPD diagnosis
	cd "\Covariates"
	merge m:1 patid using copd_diagdate, nogen
	keep if event_date <= copd_diagdate

	keep if inlist(medcode, `str130_medcode')		// Keep stroke records
	rename event_date stroke_date
	bys patid (stroke_date): keep if _n == 1		// Keep earliest record
	keep patid stroke_date
	gen stroke = 1

	cd "\Covariates"
	save stroke`i', replace
	}

use stroke1, clear
forvalues i = 2/18 {
	append using stroke`i'
	}
save stroke, replace


*********
*Substance abuse
*********

*Use Cambridge codelist
cd "JB\CPRD\Covariates"

qui import delim ///
	"CPRDCAM_PSM173_MC_V1-1_Oct2018\CPRDCAM_PSM173_MC_V1-1_Oct2018.csv", clear
qui levelsof medcode if _n <= 200, local(psm173_medcode1) s(,)
qui levelsof medcode if _n > 200, local(psm173_medcode2) s(,)

forvalues i = 1/18 {
	cd "Data\Raw"
	use clinical`i', clear

	*Obtain any record of stroke prior to COPD diagnosis
	cd "\Covariates"
	merge m:1 patid using copd_diagdate, nogen
	keep if event_date <= copd_diagdate
	gen z = inlist(medcode, `psm173_medcode1')	// Keep substance abuse records
	qui replace z = 1 if inlist(medcode, `psm173_medcode2')
	keep if z == 1
	drop z
	rename event_date substance_date
	bys patid (substance_date): keep if _n == 1		// Keep earliest record
	keep patid substance_date
	gen substance = 1

	cd "\Covariates"
	save substance`i', replace
	}

use substance1, clear
forvalues i = 2/18 {
	append using substance`i'
	}
save substance, replace


*********
*Ventilation use
*********

cd "Data\Raw"
use hes_procedures_epi_gold, clear
gen vent_date = date(epistart, "DMY")
format vent_date %dd/n/CY

*Obtain any record of ventilation prior to COPD diagnosis
cd "\Covariates"
merge m:1 patid using copd_diagdate, nogen
keep if vent_date <= copd_diagdate
gen vent = strpos(opcs, "E85")
drop if vent == 0
bys patid (vent_date): keep if _n == 1
keep patid vent vent_date
order patid vent vent_date

cd "\Covariates"
save vent, replace

********************************************************************************

*Shah extra covariates

*********
*Exercise
*********

*Use CPRD codebrowser codelist

forvalues i = 1/18 {
	cd "Data\Raw"
	use clinical`i', clear

	*Obtain any record of exercise prior to COPD diagnosis
	cd "\Covariates"
	merge m:1 patid using copd_diagdate, nogen
	keep if event_date <= copd_diagdate

	keep if inlist(medcode, 13083, 13084, 13085, 26526)	// Keep exercise records
	rename event_date exercise_date
	bys patid (exercise_date): keep if _n == 1		// Keep earliest record
	keep patid exercise_date
	gen exercise = 1

	cd "\Covariates"
	save exercise`i', replace
	}

use exercise1, clear
forvalues i = 2/18 {
	append using exercise`i'
	}
save exercise, replace

*********
*Occupational exposure
*********

*Use CPRD codebrowser codelist

forvalues i = 1/18 {
	cd "Data\Raw"
	use clinical`i', clear

	*Obtain any record of exercise prior to COPD diagnosis
	cd "\Covariates"
	merge m:1 patid using copd_diagdate, nogen
	keep if event_date <= copd_diagdate

	keep if inlist(medcode, 10169, 28986)			// Keep occupation records
	rename event_date occ_date
	bys patid (occ_date): keep if _n == 1			// Keep earliest record
	keep patid occ_date
	gen occ = 1

	cd "\Covariates"
	save occ`i', replace
	}

use occ1, clear
forvalues i = 2/18 {
	append using occ`i'
	}
save occ, replace

*********
*No physical activity
*********

*Use CPRD codebrowser codelist

forvalues i = 1/18 {
	cd "Data\Raw"
	use clinical`i', clear

	*Obtain any record of exercise prior to COPD diagnosis
	cd "\Covariates"
	merge m:1 patid using copd_diagdate, nogen
	keep if event_date <= copd_diagdate

	keep if inlist(medcode, 17696, 13807, 26506)	// Keep no activity records
	rename event_date activity_date
	bys patid (activity_date): keep if _n == 1			// Keep earliest record
	keep patid activity_date
	gen activity = 0

	cd "\Covariates"
	save activity`i', replace
	}

use activity1, clear
forvalues i = 2/18 {
	append using activity`i'
	}
save activity, replace

*********
*Exacerbations (0, 1, >=2 in year before diagnosis
*********

*Use CPRD codebrowser codelist

forvalues i = 1/18 {
	cd "Data\Raw"
	use clinical`i', clear

	*Obtain any record of exacerbations in 1 year prior to COPD diagnosis
	cd "\Covariates"
	merge m:1 patid using copd_diagdate, nogen
	keep if inrange(event_date, copd_diagdate - 366, copd_diagdate)

	keep if inlist(medcode, 1446, 7884)			// Keep exacerbations
	rename event_date exac_date
	keep patid exac_date
	collapse (count) exac_date, by(patid)
	gen exac = exac_date
	keep patid exac
	qui replace exac = 2 if exac > 2 & !missing(exac)

	cd "\Covariates"
	save exac`i', replace
	}

use exac1, clear
forvalues i = 2/18 {
	append using exac`i'
	}
save exac, replace
