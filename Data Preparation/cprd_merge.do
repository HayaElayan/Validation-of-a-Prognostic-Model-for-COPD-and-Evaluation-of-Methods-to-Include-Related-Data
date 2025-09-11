********************************************************************************
*Merge files into one dataset
*File created 01/08/2023
*Last edited 13/02/2024
********************************************************************************

cd "\Data\Covariates"
use copd_diagdate, clear

*Covariates
**need to add death, constipation, smoking, IMD and ventilation status in
foreach file in uts death_1_5_10 age_diag bmi creatinine eosinophil fev ///
	haemoglobin activity ari albumin alcohol anaemia anxiety asthma atrial ///
	bereave breathless cancer ckd ctd constip cad crp dementia depression ///
	diabetes epilepsy exac exercise famhist_resp fibrinogen gender g_ulcer ///
	g_reflux heart_fail hosp hyper ihd ibs ibd flu ics liver laba lama lung_c ///
	lungfib mrc mi exac occ osteoa osteop oxygen pvd platelet pneumo pulm_e ///
	pulm_f pulm_t psychosis rheumatoid imd smoke_bloom smoke_kiddle smoke_shah ///
	stroke substance vent ///
	 {
	 	di "FILE: `file'"
		merge 1:1 patid using `file', nogen keep(1 3)
		}

cd "\Data\Covariates"
save copd_full, replace