********************************************************************************
*Extract CPRD GOLD, ONS, HES and IMD files
*File created 01/08/2023
*Last edited 30/01/2024
********************************************************************************



********************************************************************************
*Process raw Gold txt files
********************************************************************************

*Read in and save all files as Stata files

*Patient
cd "\CPRD_GOLD_Raw_Data_25.01.2024"
import delimited "COPD_GOLD_Extract_Patient_001.txt", varn(1) clear
format patid %30.0f

cd "\Data\Raw"
save patient, replace

*Practice
cd "\CPRD_GOLD_Raw_Data_25.01.2024"
import delimited "COPD_GOLD_Extract_Practice_001.txt", varn(1) clear

cd "\Data\Raw"
save practice, replace

*Staff
cd "\CPRD_GOLD_Raw_Data_25.01.2024"
import delimited "COPD_GOLD_Extract_Staff_001.txt", varn(1) clear

cd "\Data\Raw"
save staff, replace

*Consultation
forvalues i = 1/18 {
	cd "\CPRD_GOLD_Raw_Data_25.01.2024"
	
	if `i' < 10 {
	  import delimited "COPD_GOLD_Extract_Consultation_00`i'.txt", varn(1) clear
	  format patid %30.0f
	  gen event_date = date(eventdate, "DMY")
	  format event_date %dd/n/CY
		}
		
	if `i' > 9 {
	  import delimited "COPD_GOLD_Extract_Consultation_0`i'.txt", varn(1) clear
	  format patid %30.0f
	  gen event_date = date(eventdate, "DMY")
	  format event_date %dd/n/CY
		}

	cd "\Data\Raw"
	save consultation`i', replace
	}
	
*Clinical
forvalues i = 1/18 {
	cd "\CPRD_GOLD_Raw_Data_25.01.2024"
	
	if `i' < 10 {
	  import delimited "COPD_GOLD_Extract_Clinical_00`i'.txt", varn(1) clear
	  format patid %30.0f
	  gen event_date = date(eventdate, "DMY")
	  format event_date %dd/n/CY
		}
		
	if `i' > 9 {
	  import delimited "COPD_GOLD_Extract_Clinical_0`i'.txt", varn(1) clear
	  format patid %30.0f
	  gen event_date = date(eventdate, "DMY")
	  format event_date %dd/n/CY
		}

	cd "\Data\Raw"
	save clinical`i', replace
	}
	
*Additional
forvalues i = 1/3 {
	cd "\CPRD_GOLD_Raw_Data_25.01.2024"
	
	import delimited "COPD_GOLD_Extract_Additional_00`i'.txt", varn(1) clear
	format patid %30.0f

	cd "\Data\Raw"
	save additional`i', replace
	}
	
*Referral
cd "\CPRD_GOLD_Raw_Data_25.01.2024"
import delimited "COPD_GOLD_Extract_Referral_001.txt", varn(1) clear
format patid %30.0f
gen event_date = date(eventdate, "DMY")
format event_date %dd/n/CY

cd "\Data\Raw"
save referral, replace

*Immunisation
cd "\CPRD_GOLD_Raw_Data_25.01.2024"
import delimited "COPD_GOLD_Extract_Immunisation_001.txt", varn(1) clear
format patid %30.0f
gen event_date = date(eventdate, "DMY")
format event_date %dd/n/CY

cd "\Data\Raw"
save immunisation, replace

*Test
forvalues i = 1/20 {
	cd "\CPRD_GOLD_Raw_Data_25.01.2024"
	
	if `i' < 10 {
	  import delimited "COPD_GOLD_Extract_Test_00`i'.txt", varn(1) clear
	  format patid %30.0f
	  gen event_date = date(eventdate, "DMY")
	  format event_date %dd/n/CY
		}
		
	if `i' > 9 {
	  import delimited "COPD_GOLD_Extract_Test_0`i'.txt", varn(1) clear
	  format patid %30.0f
	  gen event_date = date(eventdate, "DMY")
	  format event_date %dd/n/CY
		}

	cd "\Data\Raw"
	save test`i', replace
	}
	
*Therapy
forvalues i = 1/61 {
	cd "\CPRD_GOLD_Raw_Data_25.01.2024"
	
	if `i' < 10 {
	  import delimited "COPD_GOLD_Extract_Therapy_00`i'.txt", varn(1) clear
	  format patid %30.0f
	  gen event_date = date(eventdate, "DMY")
	  format event_date %dd/n/CY
		}
		
	if `i' > 9 {
	  import delimited "COPD_GOLD_Extract_Therapy_0`i'.txt", varn(1) clear
	  format patid %30.0f
	  gen event_date = date(eventdate, "DMY")
	  format event_date %dd/n/CY
		}

	cd "\Data\Raw"
	save therapy`i', replace
	}
	

********************************************************************************
*Process raw ONS, HES and IMD text files
********************************************************************************

*Import GOLD ONS death data
cd "\Data\Linkage\23_003180\Results\GOLD_linked\Final"
import delimited death_patient_23_003180.txt, clear

cd "\Data\Raw"
save ons_gold, replace

*Import GOLD HES data files
foreach file in acp ccare diagnosis_epi diagnosis_hosp episodes hospital ///
	hrg maternity patient primary_diag_hosp procedures_epi {
	cd "\Data\Linkage\23_003180\Results\GOLD_linked\Final"
	import delimited hes_`file'_23_003180.txt, clear

	cd "\Data\Raw"
	save hes_`file'_gold, replace
	}

*Import GOLD patient deprivation statuses
cd "\Data\Linkage\23_003180\Results\GOLD_linked\Final"
import delimited patient_2019_imd_23_003180.txt, clear

cd "\Data\Raw"
save patient_imd_gold, replace
