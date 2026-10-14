////////////////////////////////////////////////////////////////////////////////
/* //=========================================================================//
	INDIGO Data Cleaning: Reshape
	Author: Ciel Burges
	Date of Data Extract: 17/12/2025
	Started 05/01/2026
	Stata 19
	
	V1 (12/01/2026) Leave in postcode column to check calculation of deprivation index
*/ //=========================================================================//
////////////////////////////////////////////////////////////////////////////////


* INDIGO_3_Reshape.do: 
	* This reshapes the derived dataset into long format for analysis. This also merges the therapist data onto the derived dataset and performs some last cleaning/ variable labelling steps.
	
clear
cap log close
set more off
set linesize 85

clear
cap log close
set more off

* Initialise log file
log using "$logs\INDIGO_3_Reshape$dateout", replace

* Set working directory
cd "$out"

////////////////////////////////////////////////////////////////////////////////
* Therapist data
////////////////////////////////////////////////////////////////////////////////

* Read in therapist allocation data: Uses Copy b/c original excel could not be read in
import excel "$raw\INDIGO Therapist Allocation Copy.xlsx", firstrow clear

* Extract participant ID with the P0 prefix to match trialid in data extract for merge
gen str5 trialid = substr(ParticipantID, 3, 7) if regexm(ParticipantID, "^[P]") == 1
order trialid
sort trialid
describe trialid // str5
destring trialid,replace
* Save therapist data
save "$out\INDIGO_therapist_data.dta", replace

* Merge therapist data with INDIGO data
drop ParticipantID
merge 1:1 trialid using "$out\INDIGO_derived_dataset_23022026.dta" // Not matched == 0
sort trialid
drop _merge








save "$out\INDIGO_derived_dataset_23022026_wide.dta", replace


////////////////////////////////////////////////////////////////////////////////
* Reshape to long
////////////////////////////////////////////////////////////////////////////////

* Load wide INDIGO data
use "$out\INDIGO_derived_dataset_23022026_wide.dta", clear

* Recast new_diagnosis variables to match
describe new_diagnosis*
recast strL new_diagnosis_wk8
recast strL new_diagnosis_wk24
tostring new_diagnosis_wk0, replace

* Recast stopmeds variable to match
describe stopmeds*
tostring stopmeds_wk0 stopmeds_wk8 stopmeds_wk16, replace
recast strL stopmeds_wk0 stopmeds_wk8 stopmeds_wk16

* Recast diagnosisremoved vars to match
describe diagnosisrem*
tostring diagnosisremoved_wk0 diagnosisremoved_wk16 diagnosisremoved_wk24, replace
describe diagnosisrem*
recast str52 diagnosisremoved_wk0 diagnosisremoved_wk16 diagnosisremoved_wk24

* Recast therapy filler variable
describe therapy_1*
tostring therapy_1_wk0, replace
recast strL therapy_1_wk0
describe therapy_2*
tostring therapy_2_wk0, replace
describe therapy_3*
tostring therapy_3_wk8 therapy_3_wk16, replace
recast strL therapy_3_wk8 therapy_3_wk16
describe therapy_4*
tostring therapy_4_wk0 therapy_4_wk8 therapy_4_wk16 therapy_4_wk24, replace

* other_dna_
describe other_dna*
tostring other_dna_wk0_c, replace

*recast newmeds
describe newm*
tostring newmeds_wk0, replace
recast strL newmeds_wk0

* Reshape dataset into long format
reshape long datequestionnaire_@ mfq_1_@ mfq_2_@ mfq_3_@ mfq_4_@ mfq_5_@ mfq_6_@ mfq_7_@ mfq_8_@ mfq_9_@ mfq_10_@ mfq_11_@ mfq_12_@ mfq_13_@ mfq_14_@ mfq_15_@ mfq_16_@ mfq_17_@ mfq_18_@ mfq_19_@ mfq_20_@ mfq_21_@ mfq_22_@ mfq_23_@ mfq_24_@ mfq_25_@ mfq_26_@ mfq_27_@ mfq_28_@ mfq_29_@ mfq_30_@ mfq_31_@ mfq_32_@ mfq_33_@ MFQ_TOT_@ camhslastcontact_@ qaire_pack_complete_@ rcads_1_@ rcads_3_@ rcads_4_@ rcads_5_@ rcads_7_@ rcads_8_@ rcads_9_@ rcads_10_@ rcads_12_@ rcads_13_@ rcads_14_@ rcads_16_@ rcads_17_@ rcads_18_@ rcads_20_@ rcads_22_@ rcads_23_@ rcads_24_@ rcads_26_@ rcads_27_@ rcads_28_@ rcads_30_@ rcads_31_@ rcads_32_@ rcads_33_@ rcads_34_@ rcads_35_@ rcads_36_@ rcads_37_@ rcads_38_@ rcads_39_@ rcads_41_@ rcads_42_@ rcads_43_@ rcads_44_@ rcads_45_@ rcads_46_@ RCADS_TOT_@ RCADS_SocPhob_TOT_@ RCADS_PanDis_TOT_@ RCADS_SepAnx_TOT_@ RCADS_GenAnx_TOT_@ RCADS_ObsCom_TOT_@ bads_1_@ bads_2_@ bads_3_@ bads_4_@ bads_5_@ bads_6_@ bads_7_@ bads_8_@ bads_9_@ bads_10_@ bads_11_@ bads_12_@ bads_13_@ bads_14_@ bads_15_@ bads_16_@ bads_17_@ bads_18_@ bads_19_@ bads_20_@ bads_21_@ bads_22_@ bads_23_@ bads_24_@ bads_25_@ BADS_AC_@ BADS_AR_@ BADS_WS_@ BADS_SI_@ BADS_TOT_@ ami_n2_@ ami_n3_@ ami_n4_@ ami_n5_@ ami_n6_@ ami_n7_@ ami_n8_@ ami_n9_@ ami_n10_@ ami_n11_@ ami_n12_@ ami_n13_@ ami_n14_@ ami_n15_@ AMI_n_TOT_@ ami_p2_@ ami_p3_@ ami_p4_@ ami_p5_@ ami_p6_@ ami_p7_@ ami_p8_@ ami_p9_@ ami_p10_@ ami_p11_@ ami_p12_@ ami_p13_@ ami_p14_@ ami_p15_@ AMI_p_TOT_ sppc_1_@ sppc_2_@ sppc_3_@ sppc_4_@ sppc_5_@ SPPC_TOT_@ pit_1_@ pit_2_@ pit_3_@ pit_4_@ pit_5_@ pit_6_@ pit_7_@ pit_8_@ pit_9_@ pit_10_@ pit_11_@ pit_12_@ pit_13_@ pit_14_@ PIT_POS_TOT_@ PIT_NEG_TOT_@ cries_1_@ cries_2_@ cries_3_@ cries_4_@ cries_5_@ cries_6_@ cries_7_@ cries_8_@ CRIES_INT_TOT_@ CRIES_AVO_TOT_@ scs_1_@ scs_2_@ scs_3_@ scs_4_@ scs_5_@ scs_6_@ scs_7_@ scs_8_@ scs_9_@ scs_10_@ scs_11_@ scs_12_@ SCS_TOT_@ isi_1_@ isi_2_@ isi_3_@ isi_4_@ isi_5_@ isi_6_@ isi_7_@ ISI_TOT_@ amt_p1_type_@ amt_p2_type_@ amt_p3_type_@ amt_p4_type_@ amt_p5_type_@ amt_n6_type_@ amt_n7_type_@ amt_n8_type_@ amt_n9_type_@ amt_n10_type_@ amt_p1_time_@ amt_p2_time_@ amt_p3_time_@ amt_p4_time_@ amt_p5_time_@ amt_n6_time_@ amt_n7_time_@ amt_n8_time_@ amt_n9_time_@ amt_n10_time_@ amt_qaire_complete_@ diagnosis_@ new_diagnosis_@ diagnosisremoved_@ medication_@ newmeds_@ stopmeds_@ gpvisits_@ camhs_episodes_@ camhs_open_@ therapy_number_@ ae_visits_@ current_suicide_@ history_suicide_@ current_selfharm_@ history_selfharm_@ current_toother_@ history_toother_@ current_fromother_@ history_fromother_@ suicide_imagery_@ selfharm_imagery_@ therapy_1_@ therapy_2_@ therapy_3_@ therapy_4_@ attend_@_c risk_@_c breaks_@_c length_@_c length_breaks_@_c recorded_@_c engagement_@_c ///
AMT_specific_TOT_@  CRIES_OVER_TOT_@ riskdetail_@_c norecording_reason_@_c reason_dna_@_c other_dna_@_c, i(trialid) j(week) string

* Format week as categorical variable
replace week = "0" if week == "wk0"
replace week = "8" if week == "wk8"
replace week = "16" if week == "wk16"
replace week = "24" if week == "wk24"

* Destring 
destring week, replace

* Create label for the variable 
label define week_label 0 "Baseline" 8 "Week 8" 16 "Week 16" 24 "Week 24"
label value week week_label
sort trialid week

* Rename to get rid of "_" suffix
rename *_ *

////////////////////////////////////////////////////////////////////////////////
* Variable labelling
////////////////////////////////////////////////////////////////////////////////

* Label variables before sending dataset for analysis
label var trialid "Participant ID"
label var week "Time (weeks)"
label var datequestionnaire "Date of completing questionnaire"
label var rand_date "Randomisation date (recorded in randomisation extract)"
label var randomisation_date "Randomisation date (recorded in data extract)"

label var scr_el_infosheet "Participant given stage 1 information sheet"
label var scr_el_therapist "Trial therapist has capacity for new participant"
label var scr_el_mfq "Identified as scoring above 17 on MFQ (29 items)"
label var infosheet_date "Date given information sheet (stage 1)"

label var info_sheet "Participant given info sheet:"
label var info_sheet_date "Date information sheet given"
label var eligibility_date "Date eligibility confirmed"
label var agreetoparticipate "Participant agreed to participate"
label var informedconsent_date "Date of informed consent"

label var camhslastcontact "Date of last contact with CAMHS"
label var qaire_pack_complete "Completed questionnaire pack"
label var rescheduled_num "Number of rescheduling of appointments"
label var therapy_number "Number of Psychological therapies "
label var therapy_1 "Psychological therapies 1: Provide type of therapy and location, length and approx dates"
label var therapy_2 "Psychological therapies 2: Provide type of therapy and location, length and approx dates"
label var therapy_3 "Psychological therapies 3: Provide type of therapy and location, length and approx dates"
label var therapy_4 "Psychological therapies ADDITIONAL: Provide type of therapy and location, length and approx dates"

label var diagnosis "Diagnosis. Has there been any change over the last 8 weeks? Please specify change"
label var new_diagnosis "If yes (new diagnosis) provide details"
label var diagnosisremoved "if yes (diagnosis removed) provide details"
label var medication "Medication. Has there been any change over the last 8 weeks? Please specify change"
label var newmeds "if yes (started new medication), provide details"
label var stopmeds "If yes (stopped medication), provide details"
label var gpvisits "Visits to GP about your mental health (number)"
label var camhs_episodes "Episodes of CAMHS involvement (number)"
label var camhs_open "Currently open to CAMHS?"
label var ae_visits "Visits to A&E about mental health (number)"
label var current_suicide "Current risk to self - suicide"
label var history_suicide "History of harm to self - suicide"
label var current_selfharm "Current risk to self - self harm"
label var history_selfharm "History of harm to self - self harm"
label var current_toother "Current risk to others"
label var history_toother "Historical risk to others"
label var current_fromother "Current risk from others"
label var history_fromother "Historical risk from others"
label var suicide_imagery "Current Suicidal imagery"
label var selfharm_imagery "Current Self harm imagery"

* MFQ
label var MFQ_TOT "MFQ total score"
foreach i of numlist 1/33 {
	label var mfq_`i' "MFQ questionnaire item `i'"
}

* Feedback form
foreach i of numlist 1/9 {
	label var feed_agree_`i' "Feedback form week 8"
}

* Credibility expectancy
foreach i of varlist pef_* {
	label var `i' "Credibility Expectancy Questionnaire"
}

* RCADS
foreach i of varlist rcads* {
	label var `i' "RCADS questionnaire"
}
label var RCADS_TOT "RCADS Total Score"
label var RCADS_SocPhob_TOT "RCADS Social Phobia Score"
label var RCADS_PanDis_TOT "RCADS Panic Disorder Score"
label var RCADS_SepAnx_TOT "RCADS Separation Anxiety Score"
label var RCADS_GenAnx_TOT "RCADS Generalised Anxiety Score"
label var RCADS_ObsCom_TOT "RCADS Obsessive Compulsive Score"

* BADS
foreach i of varlist bads* {
	label var `i' "BADS questionnaire"
}
label var BADS_AC "BADS Activation Score"
label var BADS_AR "BADS Avoidance/Rumination Score"
label var BADS_WS "BADS School Impairment Score"
label var BADS_SI "BADS Social Impairment Score"
label var BADS_TOT "BADS Total Score"


* AMI 
foreach i of varlist ami* {
	label var `i' "AMI-Y Questionnaire"
}
label var AMI_n_TOT "AMI-Y Negative Total Score"
label var AMI_p_TOT "AMI-Y Positive Total Score"

* SPPC
foreach i of varlist sppc_* {
	label var `i' "SPPC questionnaire"
}
label var SPPC_TOT "SPPC Total Score"

* PIT
foreach i of varlist pit_* {
	label var `i' "Prospective Imagery Task"
}
label var PIT_NEG_TOT "PIT Negative Total Score"
label var PIT_POS_TOT "PIT Positive Total Score"

* CRIES
foreach i of varlist cries_* {
	label var `i' "Child Revised Impact of Event Scale"
}
label var CRIES_AVO_TOT "CRIES avoidance score"
label var CRIES_INT_TOT "CRIES intrusion score"

* SCS
foreach i of varlist scs_* {
	label var `i' "Self-Compassion Scale"
}
label var SCS_TOT "SCS Total Score"

* ISI
foreach i of varlist isi_* {
	label var `i' "Insomnia Severity Index"
}
label var ISI_TOT "ISI Total Score"

* AMT
foreach i of varlist amt_*_time amt_*_type {
	label var `i' "Autobiographical Memory Task"
}

* session information
label var attend__c "Attended assessment"
label var risk__c "Risk issues"
label var breaks__c "Number of breaks during assessment"
label var length__c "Duration of assessment"
label var length_breaks__c "Total duration of breaks during assessment"
label var recorded__c "Audio-recorded assessment?"
label var engagement__c "Adequate engagement during assessment" 
label var riskdetail__c "IF yes, what risk issues?"
label var norecording_reason__c "Reason for no audio recording"
label var reason_dna__c "Reason didn't attend"
label var other_dna__c "OTHER reason DNA assessment"


* Save dataset in long format
save "$out\INDIGO_17122025_long.dta", replace

* #### LAST LINE ####
display "$S_TIME  $S_DATE"

* Translate and close log
log close
translate "$logs\INDIGO_3_Reshape$dateout.smcl" "$logs\INDIGO_3_Reshape$dateout.pdf", replace


*************************************************
*LAST LINE
*************************************************

display "$S_TIME $S_DATE"
