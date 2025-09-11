 
cd "R:\LRWE_Proj93\Shared"
 
* Re-create table 1 from the Kiddle paper
use "R:\LRWE_Proj93\Shared\HE\kiddle_data_before_missing.dta", clear

* Add labels
label define gender 1 "Male" 2 "Female"
label values gender gender

* Add missing categories
gen bmi_miss = 0 
replace bmi_miss = 1 if bmi==.

gen fev1pp_miss = 0 
replace fev1pp_miss = 1 if fev1pp==.

gen imd_miss = 0 
replace imd_miss = 1 if imd==.

replace smoke_status_k = 4 if smoke_status_k==.
label define smoke_status_k 1 "Never smoker" 2 "Ex smoker" 3 "Current smoker" 4 "Not recorded"
label values smoke_status_k smoke_status_k 
 
dtable i.gender age_diag bmi i.bmi_miss i.smoke_status_k fev1pp i.fev1pp_miss imd i.imd_miss i.dead5, continuous(age_diag bmi fev1pp imd, statistics(median q1 q3)) nformat(%3.0f) export(baselinetable.docx,replace)