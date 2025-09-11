
* 18/10/24: SB added to just keep those with linkage

********************************************************************************
*Obtain patient IDs for linkage request
********************************************************************************

*Read in txt files containing patient IDs eligible for linking
*Gold
cd "\Linkage\January_2022_Source_GOLD"
import delimited GOLD_enhanced_eligibility_January_2022.txt, clear

cd ""
format patid %30.0f
save haya_gold_linkage_patid, replace


********************************************************************************

*Identify eligible patients for linkage

*Merge and keep only COPD patients
cd ""
use haya_gold_linkage_patid, clear

cd "\Data\Raw"
merge 1:1 patid using patient, keep(2 3) gen(merge1)

*Keep patient IDs, practice IDs and whether linkage is available in HES/ONS
keep patid pracid hes_apc_e ons_death_e lsoa_e merge1

*Indicate which patients cannot be linked
replace hes_apc_e = 0 if hes_apc_e == .
replace ons_death_e = 0 if ons_death_e == .
replace lsoa_e = 0 if lsoa_e == .

*See how much linkage is available
tab hes_apc_e
tab ons_death_e
tab lsoa_e
*Merge with practice IDs to see how many are England-based
cd "\Data\Raw"
merge m:1 pracid using practice, gen(merge2)

*Keep patients eligible for linkage
keep if inlist(merge2, 1, 3)
tab region hes_apc_e, m

* SB added
keep if hes_apc_e == 1 & ons_death_e == 1 & lsoa_e == 1
*Export to tab delimited text file
cd ""
save haya_gold_link_merged, replace
