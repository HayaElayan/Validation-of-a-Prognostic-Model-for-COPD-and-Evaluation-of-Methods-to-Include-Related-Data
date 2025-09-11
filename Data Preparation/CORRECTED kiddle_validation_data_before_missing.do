
frame change default

cd ""
use haya_copd_cleaning, clear



gen dob_edit = dob+(35*365)
format dob_edit %dd_m_y

gen startID = max(dob_edit, uts_date, crd_date) 
format startID %dd_m_y
*All up to standard from diagnosis date onwards
gen startDate= max(uts_date, crd_date) 
format startDate %dd_m_y
 
gen endID =min(death_date, tod_date, lcd_date) 
format endID %dd_m_y

keep if  (startID < copd_diagdate) 
keep if (startID < endID)
*for 5 years survival 
keep if inrange(copd_diagdate, dmy(20,9,2012), dmy(30,12,2014))

 
keep if  (endID > copd_diagdate)
keep if age_diag >= 35
keep if  (copd_diagdate - startDate ) >= 365 


*Eligible for linkage
cd ""
merge 1:1 patid using haya_gold_link_merged, nogen keep(3)
*(filtered on LSOA = 1 in addition to HES and ONS)
drop if gender == 3
qui replace fev1pp = fev1pp*100 if fev1pp < 5
qui replace fev1pp = . if !inrange(fev1pp,0,200)



*Merge in ethnicity to calculate FEV1%pred
cd "\Data\Covariates"
merge 1:1 patid using eth_hes, nogen keep(1 3)
cd "\Data\Clean"

cap drop fev1pp2



*White males
gen fev1pp2 = 0.5536 - 0.01303*age_diag - 0.000172*age_diag^2 + ///
	0.00014098*(100*ht)^2 if ethgr == 1 & gender == 1
	
*White females
qui replace fev1pp2 = 0.4333 - 0.00361*age_diag - 0.000194*age_diag^2 + ///
	0.00011496*(100*ht)^2 if ethgr == 1 & gender == 2
	
*Black males
qui replace fev1pp2 = 0.3411 - 0.02309*age_diag + 0.00013194*(100*ht)^2 ///
	if ethgr == 3 & gender == 1
	
*Black females
qui replace fev1pp2 = 0.3433 - 0.01283*age_diag - 0.000097*age_diag^2 + ///
	0.00010846*(100*ht)^2 if ethgr == 3 & gender == 2

qui replace fev1pp2 = 100*(fev1/fev1pp2)
qui replace fev1pp2 = . if !inrange(fev1pp2,0,200)

tw (scatter fev1pp2 fev1pp, m(Oh)) (function y=x, range(0 200)), ///
	xtitle("Observed FEV1%pred") ytitle("Predicted FEV1%pred") ///
	legend(off) name(fev1pp_comp, replace)
twoway (histogram fev1pp, start(0) width(2) ///
    col("3 144 214%50") freq) ///
	(histogram fev1pp2 if missing(fev1pp), start(0) width(2) ///
	col("249 155 69%50") freq xtitle("FEV1%pred") ///
	legend(order(1 "Observed FEV1%pred" 2 "Missing -> Predicted FEV1%pred") ///
	symxsize(3) ring(0) pos(3)) ///
	xlabel(, format(%3.1f)) name(fev1pp_comp2, replace))

qui replace fev1pp = fev1pp2 if missing(fev1pp)


sum bmi, d
di 100*(_N - r(N))/_N

tab smoke_status_k, m

cd ""
save kiddle_validation_data_before_missing, replace
