
*********
*Smoking status
*********
*HE added new codes
forvalues i = 1/18 {
	
*Use Shah codelist for never, former, current smoking status
cd "\Data\Raw"
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

*Kiddle definition: most recent smoking status (current, ex or never)
cd "\Covariates"
merge m:1 patid using copd_diagdate, nogen keepusing(copd_diagdate)
keep if event_date <= copd_diagdate
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
save smoke_kiddle_fix`i', replace
}



use smoke_kiddle_fix1, clear
forvalues i = 2/18 {
	append using smoke_kiddle_fix`i'
	}
rename smoke_date smoke_date_k
rename smoke_status smoke_status_k
save smoke_kiddle_fix, replace