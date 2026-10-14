////////////////////////////////////////////////////////////////////////////////
/* //=========================================================================//
	INDIGO Data Cleaning: Reading in Data and Randomisation Extract
	Author: Ciel Burges 
	Started: 05/01/2026
	Date of extract: 17/12/2025
	Stata 19
	
	V1 (12/01/2026) Leave in postcode column to check calculation of deprivation index
*/ //=========================================================================//
////////////////////////////////////////////////////////////////////////////////

* INDIGO_1_Read.do: 
	* This creates the dataset(s) with all of the collected data from excel. 
	* These forms the basis of the dataset from which the analyses takes place. 


clear
cap log close
set more off
set linesize 85

* Initialise log file
log using "$logs/INDIGO_1_Read$dateout", replace

////////////////////////////////////////////////////////////////////////////////
* Import raw dataset (.csv) 
////////////////////////////////////////////////////////////////////////////////

* Set current working directory
cd "$raw"

* Import the raw dataset
import delimited "INDIGOVictoriaPile_DATA_2026-02-12_1309.csv", clear
describe

* ==============================================================================

* Drop empty columns
drop eligibility_and_randomisation_ti redcap_survey_identifier participant_id_timestamp general_information_questionnair /*postcode*/ assessment_log_timestamp rescheduled_assessment_log_1_tim rescheduled_assessment_log_2_tim screen_mfq_timestamp general_information_questionnair baseline_qaire_pack_timestamp baseline_amt_timestamp baseline_clinical_and_risk_ax_ti baseline_casus_02dc_timestamp baseline_he_acceptability_timest session_1_credibilityexpectancy_ week_8_qaire_pack_timestamp week_8_feedback_questionnaire_ti week_8_autobiographical_memory_t week_8_clinical_and_risk_ax_time week_8_casus_2_timestamp week_8_he_acceptability_timestam week_16_qaire_pack_timestamp week_16_amt_timestamp week_16_clinical_and_risk_ax_tim week_16_casus_2_timestamp week_16_he_acceptability_timesta week_24_qaire_pack_timestamp week_24_amt_timestamp week_24_clinical_and_risk_ax_tim week_24_casus_2_timestamp week_24_he_acceptability_timesta completion_timestamp

* Drop CA-SUS as reported outside of the primary paper (see SAP)
drop  accom_* anyabsence* absence_* overnight_* appoint_* acc_em* ambulance_* gp_* nurse* camhs_b camhs_w* camhs_n* therapy_b therapy_w* other_therapy* therapy_n_* mhw* fam_sup* senco* social_* speech_ther* helpline_* meds_*

* postcode variable largely empty: need for deprivation index

////////////////////////////////////////////////////////////////////////////////
* Variable formatting
////////////////////////////////////////////////////////////////////////////////

* Format date variables: string to datetime (+ label)

* List string variable names to identify all date variables
ds, has(type string) varwidth(32)

* Create local list storing variable names of date variables
local vlist infosheet_date date_b_r_r2 datequestionnaire_b eligibility_date date_wk8_r_r2 info_sheet_date camhslastcontact_b informedconsent_date date_wk16_r_r2 randomisation_date datequestionnaire_wk8 camhslastcontact_wk8 date_b date_wk24_r_r2 date_wk8 datequestionniare_wk16 date_wk16 camhslastcontact_wk16 date_wk24 datequestionnaire_wk24 date_b_r camhslastcontact_wk24 complete_date_1 date_wk8_r discontinue_date_1 date_wk16_r date_wk24_r

foreach var in `vlist' {
	generate date = date(`var', "DMY")
	format date %td
	order date, after(`var')
	drop `var'
	rename date `var'
}


* ==============================================================================

** Eligibility & randomisation

* Label variables
label variable scr_el_mfq "Identified as scoring above 17 on MFQ (29 items)"
label variable scr_el_therapist "Trial therapist has capacity for new participant"
label variable scr_el_infosheet "Participant given stage 1 information sheet"
label variable el2_age "Aged 16-18"
label variable el2_consent "Able to provide informed consent"
label variable el2_willing "Willing and able to engage in psychological therapy and complete assessments"
label variable el2_mfq "Scoring above clinical cut-off on Mood and Feelings Questionnaire (MFQ of 33 items; clinical cut-off=20)"
label variable el2_ld "Diagnosis of learning disability or significant head injury, neurological disorder or epilepsy"
label variable el2_english "Unable to fluently communicate in spoken English"
label variable el2_therapy "Currently receiving psychological therapy"
label variable el2_risk "Moderate to high levels of risk"
label variable el2_diagnosis "Current diagnosis of bipolar disorder, PTSD or psychosis."
label variable el2_other "Other significant conditions that mean the participant will not be able to participate in the trial (or will be put at risk by doing so)."
label variable eligible_yesno "Is the participant eligible to take part in the trial?"
label variable informedconsent "Gave written informed consent"
label variable randomised "Participant was randomised"

* Define label for eligibility items 0 = No, 1 = Yes
label define eli_label 0 "No" 1 "Yes" 

* Define list of applicable variables
local eli_list scr_el_mfq scr_el_therapist scr_el_infosheet el2_age el2_consent el2_diagnosis el2_english el2_ld el2_mfq el2_other el2_risk el2_therapy el2_willing

* Attach label to each item of list
foreach var in `eli_list' {
	label value `var' eli_label
}

* ==============================================================================

** Screening MFQ

* Label screening questionnaire items
foreach i of varlist s_mfq_* {
	label variable `i' "Screening MFQ"
}

* ==============================================================================

**# ID variables 

* Convert string to numeric
describe record_id trialid id id_wk24 id_wk16 id_wk8 id_b

* Use trialid as PIN for analyses 
tostring trialid, replace
label var trialid "Participant ID"
label var initials "Initials"
* Check for duplicates (pre-reshape to long)
distinct trialid // there are duplicates
bysort trialid: gen obs =_N
list trialid randomised randomisation_date if ob != 1
// three entries with missing trialid (not randomised). drop these as cannot be matched to randomisation extract
drop if trialid == "."
distinct trialid
* Appear to be no duplicates after removing rows with missing trialid

* Drop superfluous ids
drop record_id id id_wk24 id_wk16 id_wk8 id_b participant_id_complete
drop obs
* ==============================================================================

** General information

* Label variables
label variable age "Age"
label variable age_month "Number of months since birthday"
label variable ethnicity "Ethnicity"
label variable eal "English as first language"
label variable sex "Sex assigned at birth"
label variable gender_id "Gender identity"
label variable gcse_btech "Any GCSE/ BTECH passes"
label variable gcse "Number GCSE passes"
label variable btech "Number BTECH passes"
label variable school_meals "Receiving free school meals"
label variable healthplan "Education, Health, and Care Plan"
label variable sexual_orientation "Sexual orientation"
label variable imd "Index of Multiple Deprivation"
label variable religion "Religion"

* Format accommodation variables: label more descriptively
label var accommodation___1 "Accommodation last 6 months: Family home (owned)"
label var accommodation___2 "Accommodation last 6 months: Family home (rented)"
label var accommodation___3 "Accommodation last 6 months: Living independently (owned)"
label var accommodation___4 "Accommodation last 6 months: Foster care"
label var accommodation___5 "Accommodation last 6 months: Residential care"
label var accommodation___6 "Accommodation last 6 months: Living with friends or relatives"
label var accommodation___7 "Accommodation last 6 months: Living independently (rented)"
label var accommodation___8 "Accommodation last 6 months: Bed & Breakfast, boarding house or hotel"
label var accommodation___9 "Accommodation last 6 months: Homeless: living on the stress"
label var accommodation___10 "Accommodation last 6 months: Other"
label var accommodation___777 "Accommodation last 6 months: 777"
label var accommodation___888 "Accommodation last 6 months: 888"
label var accommodation___999 "Accommodation last 6 months: 999"

* Format housemates variables: label as more descriptive names
label var housemates___1 "Cohabiting with mother"
label var housemates___2 "Cohabiting with father"
label var housemates___3 "Cohabiting with female partner"
label var housemates___4 "Cohabiting with male partner"
label var housemates___5 "Cohabiting with female sibling(s)"
label var housemates___6 "Cohabiting with male sibling(s)"
label var housemates___7 "Cohabiting with others"
label var female_siblings_number "Number of female siblings"
label var male_siblings_number "Number of male siblings"

* ==============================================================================

** Completion

* Label variables
label variable complete_1 "Did participant complete trial?"
label variable complete_date_1 "Completed - Date of last visit"
label variable discontinue_date_1 "Discontinued - Date of withdrawal"
label var discontinue_type_1 "Type of discontinuation/withdrawal"
	// 1, Discontinue treatment (but willing to continue with assessments) | 2, Discontinue the study (but do not withdraw their data) | 3, Withdraw their consent (i.e., data provided so far is withdrawn).
label var discontinuation_reason_1 "Early discontinuation/withdrawal - please tick the most appropriate reason for participant not completing the trial:"
label var discontin_explain_1 "Please, provide further details to previous answer"

* ==============================================================================

* Correct erroneous variable name
rename datequestionniare_wk16 datequestionnaire_wk16
rename engagement_wk9 engagement_wk16

* Rename variables for consistent reshape: Manual due to avoid renaming baseline-only variables
* and check spelling is consistent across time points

* baseline
rename baseline_qaire_pack_complete qaire_pack_complete_wk0
rename v287 gen_info_questionnaire_complete
rename baseline_amt_complete amt_qaire_complete_wk0
rename baseline_clinical_and_risk_ax_co clin_risk_ax_complete_wk0
rename baseline_casus_02dc_complete casus_complete_wk0
rename baseline_he_acceptability_comple accept_complete_wk0
rename v624 cred_exp_complete
rename *_b_r_r2 *_wk0_r_r2
rename *_b_r *_wk0_r
rename *_b *_wk0


* week 8
rename week_8_qaire_pack_complete qaire_pack_complete_wk8
rename v848 amt_qaire_complete_wk8
rename week_8_clinical_and_risk_ax_comp clin_risk_ax_complete_wk8
rename week_8_casus_2_complete casus_complete_wk8
rename week_8_he_acceptability_complete accept_complete_wk8

* week 16
rename week_16_qaire_pack_complete qaire_pack_complete_wk16
rename week_16_amt_complete amt_qaire_complete_wk16
rename week_16_clinical_and_risk_ax_com clin_risk_ax_complete_wk16
rename week_16_casus_2_complete casus_complete_wk16
rename week_16_he_acceptability_complet accept_complete_wk16

* week 24
rename week_24_qaire_pack_complete qaire_pack_complete_wk24
rename week_24_amt_complete amt_qaire_complete_wk24
rename week_24_clinical_and_risk_ax_com clin_risk_ax_complete_wk24
rename week_24_casus_2_complete casus_complete_wk24
rename week_24_he_acceptability_complet accept_complete_wk24

* rename due to spelling mistakes
rename daignosisremoved_wk16 diagnosisremoved_wk16
rename daignosisremoved_wk24 diagnosisremoved_wk24
rename daignosisremoved_wk8 diagnosisremoved_wk8

* Save wide raw INDIGO data (may include some non-randomised)



save "$out\INDIGO_raw_230226.dta", replace

////////////////////////////////////////////////////////////////////////////////
* Randomisation extract
////////////////////////////////////////////////////////////////////////////////

* Read in randomisation extract
import excel "INDIGO Randomisation Unblinded Data Extract 23.02.2026.xls", cellrange(A2:V172) firstrow case(lower) clear

* Drop empty/ irrelevant columns
keep sitecode sitename pin entertheparticipantsinitials ageatconsent withdrawn treatmentarmcode treatmentarmname randomised notes

* Create randomisation date variable (to compare to rand date in data extract): extract date only
generate rand_date = dofc(randomised)
format rand_date %td
label var rand_date "Randomisation date"
rename randomised randomised_time

* Destring age at consent. note this corresponds to stage one consent. may not match REDCAP age. 
destring ageatconsent, replace
label var ageatconsent "Age at consent (stage 1) randomisation extract"
* ==============================================================================

* Code treatment arm as categorical variable

* List all unique values
tab treatmentarmname

* Replace string values with numeric values
replace treatmentarmname = "1" if treatmentarmname == "IMAGINE"
replace treatmentarmname = "0" if treatmentarmname == "NDST"

* Destring variable (to make it a numeric variable)
destring treatmentarmname, replace

* Create label for variable (clarify category)
label define interv_label 0 "Control" 1 "Imagine"

* Attach label to variable
label value treatmentarmname interv_label

* Rename variable
rename treatmentarmname treat
rename entertheparticipantsinitials initials
label var treat "Treatment arm"

* Drop treatment code after checking treatment arm is correct
list pin treatmentarmcode treat if treat == 1 & treatmentarmcode != "01."
drop treatmentarmcode

* ==============================================================================

* Code site as categorical variable

* List all unique values
levelsof sitecode

* Replace string values with numeric values
replace sitecode = "1" if sitecode == "P01"
replace sitecode = "2" if sitecode == "P02"
replace sitecode = "3" if sitecode == "P03"
replace sitecode = "4" if sitecode == "P04"
replace sitecode = "5" if sitecode == "P05"
replace sitecode = "6" if sitecode == "P06"
replace sitecode = "7" if sitecode == "P07"
replace sitecode = "8" if sitecode == "P08"

* Destring variable (to make it a numeric variable)
destring sitecode, replace

* Create label for variable (clarify category)
tab sitename
label define site_label 1 "01. Orleans Park" 2 "02. Highbury Fields" 3 "03. Elmgreen" 4 "04. Putney Ark Academy" 5 "05. Woodbridge High" 6 "06. Southfields Academy" 7 "07. Turing House" 8 "08. Kingsdale School"

* Attach label to variable
label value sitecode site_label
drop sitename
rename sitecode site

* ==============================================================================

* Extract participant ID with the P0 prefix to match trialid in data extract for merge
gen trialid = substr(pin, 3, 7) if regexm(pin, "^[P]") == 1
drop pin
rename initials rand_initials
label var rand_initials "Initials (randomisation extract)"
label var trialid "Participant ID"
* Re-order for neatness
order trialid treat rand_date randomised site ageatconsent rand_initials 

* Save randomisation data
save "$out\INDIGO_randomisation_data.dta", replace

////////////////////////////////////////////////////////////////////////////////
* Merge randomisation data and INDIGO data
////////////////////////////////////////////////////////////////////////////////

* Merge INDIGO data with randomisation data
merge 1:1 trialid using "$out\INDIGO_raw_230226.dta" // not matched = 81
drop if _merge == 2 // participant missing from randomisation extract
drop _merge

* Drop as overall completion of log marked in assessment_log variable anyway (and those automatically generated by REDCAP that are not part of offical database)
drop rescheduled_assessment_log_1_com rescheduled_assessment_log_2_com 
drop gen_info_questionnaire_complete eligibility_and_randomisation_co interrupted_* whointerrupted* screen_mfq_complete clin_risk_ax_complete_* casus_complete_* cred_exp_complete completion_complete accept_complete_* assessment_log_complete

* Save dataset
save "$out\INDIGO_dataset_23022026.dta", replace



////////////////////////////////////////////////////////////////////////////////
* Screening data
////////////////////////////////////////////////////////////////////////////////
cd "$raw"

* Import the raw dataset
import delimited "INDIGOScreenVictoria_DATA_2026-02-12_1511.csv", clear

rename id_s trialid
destring trialid,replace
cd "$out"
save INDIGO_screening.dta,replace

//add screening data needed to ran data for additonal gender id
cd "$out"
use INDIGO_dataset_23022026,replace
destring trialid,replace
merge 1:m trialid using INDIGO_screening, keepusing(trialid gender_id_s gender_id_selfdescribe_s)
replace gender_id=gender_id_s if gender_id==888
drop _merge
drop if missing(treat)

save "$out\INDIGO_dataset_23022026.dta", replace
////////////////////////////////////////////////////////////////////////////////
* Therapy/AEs
////////////////////////////////////////////////////////////////////////////////


cd "$raw"
* check therapy data for postcodes
import delimited "INDIGOTherapyDatabas_DATA_2026-02-12_1512.csv", clear // no postcode data


egen number_of_sessions_attended = rowtotal(attend_s1 attend_s2 attend_s3 attend_s4 attend_s1_r attend_s2_r attend_s3_r attend_s4_r)
replace number_of_sessions_attended=4 if number_of_sessions_attended==5

//reasons not attend?

tab1 reason_dna_s*
replace id = subinstr(id, "P0", "", 1) if substr(id,1,2)=="P0"
rename id trialid
destring trialid,replace
gen adhered_binary = (number_of_sessions_attended>=3)
replace adhered_binary=. if missing(number_of_sessions_attended)

cd "$out"
save INDIGO_therapist_attend.dta,replace




////////////////////////////////////////////////////////////////////////////////
* Protocol deviations
////////////////////////////////////////////////////////////////////////////////
cd "$raw"


* Import the raw dataset
import excel "INDIGO Status log 12.02.26.xlsx", cellrange(B3:P173) clear firstrow

gen trialid = substr(ParticipantID,3,7)
gen therapy_not_protocol = (Wastherapydeliveredtothepro=="No")

label define therapy_not_protocol 0"Therapy delivered to protocol" 1"Therapy not delivered to protocol"
label values therapy_not_protocol therapy_not_protocol
destring trialid,replace
cd "$out"
save INDIGO_prot_status.dta,replace


* #### LAST LINE ####
display "$S_TIME  $S_DATE"

* Translate and close log
log close
translate  "$logs\INDIGO_1_Read$dateout.smcl" "$logs\INDIGO_1_Read$dateout.pdf", replace


