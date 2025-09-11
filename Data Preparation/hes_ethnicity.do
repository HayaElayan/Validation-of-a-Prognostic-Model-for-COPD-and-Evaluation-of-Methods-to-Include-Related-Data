
*Ethnicity	
cd "\Data\Raw"
use hes_episodes_gold, clear
cap drop ethnos_n ethgr
encode ethnos, gen(ethnos_n)
bysort patid: egen ethnos_check=min(ethnos_n)
count if ethnos_check!=ethnos_n

*code ethnic group into a smaller number of groups
/*  1: White/white British
	2: Asian/Asian British
	3: Black/black British
	4: Other/mixed  */
recode ethnos_n 1=2 2/4=3 5/6=2 7/9=4 10=2 11=5 12=1

*allocate the most commonly ethnic group to a person
*give precedence to known over unknown values
bysort patid: egen ethgr=mode(ethnos_n)

lab def ethgr 1"white" 2"Asian" 3"black" 4"other/mixed" 5"NK/NS"
lab val ethgr ethgr
keep patid ethgr

bys patid: keep if _n == 1

cd "\Data\Covariates"
save eth_hes, replace
