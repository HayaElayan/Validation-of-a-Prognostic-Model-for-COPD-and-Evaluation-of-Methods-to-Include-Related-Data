********************************************************************************
*Check variables and tidy up (replace missing values where appropriate)
*File created 13/02/2024
********************************************************************************

*******************************************
*Outcome
*******************************************

cd "\Covariates"
use haya_copd_full, clear

*Proportion alive/dead at each follow-up


*Count deaths since 2018
tab dead if death_date > mdy(1,1,2018)

*Prepare dataset for final cleaning
cd ""
save haya_copd_cleaning, replace


*******************************************
*Continuous
*******************************************

*********
*Age
*********

cd ""
use haya_copd_cleaning, clear

*hist copd_diagdate
*hist age_diag
count if copd_diagdate < dob		
count if age_diag > 100				
count if copd_diagdate < mdy(1,1,1960) & inrange(age_diag,0,100)	
drop if copd_diagdate < dob | age_diag > 100 | copd_diagdate < mdy(1,1,1960)
*hist copd_diagdate
*hist age_diag
*sumage_diag

save haya_copd_cleaning, replace

*********
*BMI
*********

cd ""
use haya_copd_cleaning, clear

*Remove erroneous observations (consistent with Kiddle)
replace bmi = . if !inrange(bmi,0,70)		
*hist bmi
*sumbmi

save haya_copd_cleaning, replace

*********
*C-reactive protein (CRP)
*********

cd ""
use haya_copd_cleaning, clear

*Remove erroneous observations (consistent with Kiddle)
replace crp_level = . if !inrange(crp_level,0,370)	
*hist crp_level
*sumcrp_level

save haya_copd_cleaning, replace

*********
*Creatinine
*********

cd ""
use haya_copd_cleaning, clear

*Remove erroneous observations
replace creatinine = . if !inrange(creatinine,0,5000)	
*hist creatinine
*sumcreatinine

save haya_copd_cleaning, replace

*********
*Eosinophil
*********

cd ""
use haya_copd_cleaning, clear

*Remove erroneous observations
replace eosinophil = . if !inrange(eosinophil,0,10)		
*hist eosinophil
*sumeosinophil

save haya_copd_cleaning, replace

*********
*FEV1
*********

cd ""
use haya_copd_cleaning, clear

*Remove erroneous observations (consistent with Kiddle)

*qui replace fev1 = (fev1/1000)*100 if fev1 > 5
replace fev1 = . if !inrange(fev1,0,5)		
*hist fev1
*sumfev1

save haya_copd_cleaning, replace

*********
*FEV1 %pred
*********

cd ""
use haya_copd_cleaning, clear

*Remove erroneous observations
replace fev1pp = . if !inrange(fev1pp,0,200)		
*hist fev1pp
*sumfev1pp

save haya_copd_cleaning, replace

*********
*Fibrinogen
*********

cd ""
use haya_copd_cleaning, clear

*Remove erroneous observations (consistent with Kiddle)
replace fibrinogen_level = . if !inrange(fibrinogen_level,0,700)  
*hist fibrinogen_level
*sumfibrinogen_level

save haya_copd_cleaning, replace

*********
*Haemoglobin
*********

cd ""
use haya_copd_cleaning, clear

*Remove erroneous observations
replace haemoglobin = . if !inrange(haemoglobin,0,200)		
*hist haemoglobin
*sumhaemoglobin

save haya_copd_cleaning, replace

*********
*Albumin
*********

cd ""
use haya_copd_cleaning, clear

*Remove erroneous observations (consistent with Kiddle)
replace albumin = . if !inrange(albumin_level,0,70)  
replace albumin_level = . if !inrange(albumin_level,0,70)  
*hist albumin_level
*sumalbumin_level
*tab albumin, m

save haya_copd_cleaning, replace

*******************************************
*Categorical
*******************************************

*********
*Covariates where missing value indicate level 0 of covariate
*********

cd ""
use haya_copd_cleaning, clear

qui replace activity = 1 if missing(activity)
*tab activity, m

foreach cov in ari alcohol anaemia anxiety asthma atrial bereave ///
	breathless cancer ckd ctd constip cad dementia depression diabetes ///
	epilepsy exac exercise famhist_respiratory g_ulcer g_reflux heart_fail ///
	hosp hyper ihd ibs ibd flu ics liver laba lama lungfib mi occ osteoa ///
	osteop oxygen pvd pneumo pulm_e pulm_f pulm_t psychosis rheumatoid ///
	stroke substance vent {

		qui replace `cov' = 0 if missing(`cov')
		*tab `cov', m
	}
	
save haya_copd_cleaning, replace




