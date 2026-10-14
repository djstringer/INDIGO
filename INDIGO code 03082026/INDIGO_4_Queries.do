////////////////////////////////////////////////////////////////////////////////
/* //=========================================================================//
	INDIGO Data Cleaning: Queries
	Author: Ciel Burges
	Date of Data Extract: 17/12/2025
	Started 05/01/2026
	Stata 19
*/ //=========================================================================//
////////////////////////////////////////////////////////////////////////////////


* INDIGO_4_Queries.do: 
	* Querying data to check for potential data entry errors or inconsistencies.
	* Creates excel spreadsheet with final queries to be sent to study team.
	
* This script was developed in STATA 19
version 19
clear
cap log close
set more off
set linesize 85

* This script was developed in STATA 19
version 19

clear
cap log close
set more off

* Initialise log file
log using "$logs\INDIGO_4_Queries$dateout", replace


////////////////////////////////////////////////////////////////////////////////
* Define Query Function
////////////////////////////////////////////////////////////////////////////////

capture program drop queries

program define queries
	syntax varlist(min=1 max=2) [if], QUERYname(string) 
	
	preserve
		marksample touse, novarlist
		qui drop if `touse' == 0
		local count: word count `varlist'
		
		if `count' == 1 {
			qui {
				keep trialid site `1'
				decode site, gen(site2) // site to string
				drop site //
				rename site2 site //
				gen question1 = "`varlist'"
				local label : var label `1'
				gen label1 = "`label'"
				gen query = "`queryname'"
				rename `1' value1
				labdtch _all
				tostring value1,replace force
				order trialid site question1 label1 value1 query
				local n = _n
				noi di _n _n "Queries collated, number of queries = `n'"
			}
		}
		
		if `count' == 2 {
			qui {
				tokenize `varlist'
				keep trialid site `1' `2'
				decode site, gen(site2) // site to string
				drop site //
				rename site2 site //
				gen question1 = "`1'"
				gen question2 = "`2'"
				local label1 : var label `1'
				local label2 : var label `2'
				gen label1 = "`label1'"
				gen label2 = "`label2'"
				gen query = "`queryname'"
				rename `1' value1
				rename `2' value2
				labdtch _all
				tostring value1 value2, replace force
				order trialid site question1 label1 value1 question2 label2 value2 query
				local n = _n
				noi di _n _n "Queries collated, number of queries = `n'"
			}
		}
		
		cd "$queries"
		
		if `count' == 2 {
			qui {
				local i = 0
			
				if (fileexists("query_`1'_`2'.dta") == 1) {
					noi di "File already exists in folder, additional file created"
					local i = `i' + 1
				}
				else {
					noi di "File does not exist currently in folder"
				}
			
				foreach y of numlist 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 {
					if (fileexists("query_`1'_`2'_`y'.dta") == 1) {
						local i = `i' + 1
					}	
				}
				
				local n = _n
				
				if (`n' == 0) {
					noi di "No entries in queries file, file will not be created"
				}
				
				if (`n' != 0) {
					if (`i' == 0) {
						save "query_`1'_`2'.dta", replace
					}
					else {
						save "query_`1'_`2'_`i'.dta", replace
					}
				}
			}
		}
		
		if `count' == 1 {
			qui {
				di "Count == 1"
				local i = 0
				di "Local set to 0"
					if (fileexists("query_`1'.dta") == 1) {
						noi di "File already exists in folder, additional file created"
						local i = `i' + 1
					}
					else {
						noi di "File does not exist currently in folder"
					}
				
					foreach y of numlist 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 {
						if (fileexists("query_`1'_`y'.dta") == 1) {
							local i = `i' + 1
						}
					}
				
				local n = _n
				
				if (`n' == 0) {
					noi di "No entries in queries file, file will not be created"
				}
				
				if (`n' != 0) {
					if (`i' == 0) {
						save "query_`1'.dta", replace
					}
					else {
						save "query_`1'_`i'.dta", replace
					}
				}
			}
		}
	restore
end

////////////////////////////////////////////////////////////////////////////////
**# Confirm randomisation and data extract are matched
////////////////////////////////////////////////////////////////////////////////

* Load INDIGO data in long format
use "$out\INDIGO_17122025_long.dta", clear

* Check for duplicate IDs 
sort trialid week
quietly by trialid week:  gen duplicate = cond(_N==1,0,_n)
tab duplicate

* Verify there are not duplicates of Participant ID at each visit (i.e., one ppt observation per time point)
foreach num in 0 8 16 24 {
	preserve
	keep if week == `num'
	queries duplicate week if duplicate != 0, queryname("There is a duplicate of this participant ID at time point `num'. Please confirm that there are no duplicate observations per participant ID per visit point.")
	restore
}

drop duplicate

// =============================================================================

* Check that randomisation date (randomisation vs data extract) match

preserve

	keep if week == 0 
	queries randomisation_date rand_date if randomisation_date != rand_date, queryname("Randomisation dates recorded in randomisation and data extracts respectively do not match. Please confirm the correct date of randomisation.")
	
restore

// =============================================================================

* Check that participant initials match between randomisation and data extracts
preserve
	keep if week == 0
	queries initials rand_initials if initials != rand_initials, queryname("Participant initials recorded in randomisation extract and data extract do not match. Please correct initials.")
restore

* Check that age at consent (randomisation extract) is the same as age in questionnaire (data extract)
* NOTE: these ages stem from different stages of the consent process (stage 1 vs stage 2. Thus, there are small differences to be expected. Queries in excel will be removed if discrepancies were previously approved by CI.
** Update 06/01/2026: all age discrepancies confirmed by VP except for P010061. To confirm randomisation note should be added, see age check against screener age below.

/*
preserve
	keep if week == 0
	queries ageatconsent age if age != ageatconsent, queryname("Age at consent provided in randomisation extract does not match participant age at baseline from data extract. Confirm that this difference is due to ages measured at different stages?.")
restore
*/

// =============================================================================

**# Update 06/01/2026: VP sent Screener data with 17-12-2025 extract, which includes school and stage 1 screener data. 

	* Merge variable age from screener data onto randomisation data
	import delimited "$raw\INDIGOScreenVictoria_DATA_2025-12-17_1044.csv", clear
		* age stage 1 var (screener data) called age_s
		drop if missing(id_s)
		sort id_s
		drop if initials == ""
		drop if initials == "888"
		rename id_s trialid
		tostring trialid, replace
		save "$out\INDIGOScreener_17122025.dta", replace
		
	use "$out\INDIGO_randomisation_data.dta", clear // ageatconsent
	merge 1:1 trialid using "$out\INDIGOScreener_17122025.dta", keepusing(age_s)
	drop if _merge==2 // drop if not randomised; 4 missing screener data (rely on rand data)
	
	* Confirm (mostly for P010061 randomisation note purposes) match of stage 1 age (rand extract) and stage 1 age (screener data)
	list trialid ageatconsent age_s if ageatconsent != age_s & !missing(age_s) & age_s != 888
	
	// NON-MATCHING stage 1 ages: 10061 51078 61317 71736. As noted by VP, 10061 ageatconsent in rand data should be 17 (not 16)
	
	* Official query of stage 1 ages
	label var age_s "Age (stage 1) screener data"
	queries ageatconsent age_s if ageatconsent != age_s & !missing(age_s) & age_s != 888, queryname("Age at consent provided in randomisation extract does not match participant age at recorded in screener data (assuming both stage 1 of consent). Please note which age in which data is correct. If age in randomisation extract is incorrect, please add note in actio box that statistician should request a note to randomisation system.")


////////////////////////////////////////////////////////////////////////////////
**# Participant eligibility
////////////////////////////////////////////////////////////////////////////////

* Load INDIGO data in long format
use "$out\INDIGO_17122025_long.dta", clear

preserve

	keep if week == 0
	
	* Age 16-18
	queries age if !inrange(age, 16, 18) & !missing(age), queryname("Participant age does not satisfy age inclusion criterion. Confirm?")

	queries age if missing(age), queryname("Participant age is missing or was not recorded. Confirm?")

	* Provided informed consent
	queries informedconsent if informedconsent != 1, queryname("Participant did not provide informed consent. Confirm?")

	* Agreed to particpate
	queries agreetoparticipate if agreetoparticipate != 1, queryname("Participant did not agree to participate. Confirm?")

	* Screening 29-item MFQ total score > 17
	egen s_mfq29_tot = rowtotal(s_mfq_*)
	label var s_mfq29_tot "29-item MFQ Total Score (Screener)"
queries s_mfq29_tot if s_mfq29_tot < 17, queryname("Participant scored below the clinical cut-off of 17 on the 29-item MFQ screener. Confirm?")

	* No diagnosis of learning disability or significant head injury, neurological disorder or epilepsy
	queries el2_ld if el2_ld != 0, queryname("Exclusion criterion violated (diagnosis of learning disability or significant head injury, neurological disorder or epilepsy). Confirm?")

	* Ability to communicate fluently in English
	queries el2_english if el2_english != 0 , queryname("Exclusion criterion violated (fluent communication in English). Confirm?")

	* No other current psychological interventions
	queries el2_therapy if el2_therapy != 0, queryname("Exclusion criterion violated (receipt of other psychological interventions). Confirm?")

	* Not moderate to high risk
	queries el2_risk if el2_risk != 0, queryname("Exclusion criterion violated (moderate to high levels of risk). Confirm?")

	* No current diagnosis of bipolar disorder, PTSD or psychosis.
	queries el2_diagnosis if el2_diagnosis != 0, queryname("Exclusion criterion violated (current diagnosis of bipolar disorder, PTSD or psychosis). Confirm?")

	* No other significant conditions that mean the participant will not be able to participate in the trial (or will be put at risk by doing so).
	queries el2_other if el2_other != 0, queryname("Exclusion criterion violated (other significant conditions that mean the participant will not be able to participate in the trial). Confirm?")

	* Score > 20 on 33-item baseline MFQ
	queries MFQ_TOT if MFQ_TOT < 20 & !missing(MFQ_TOT), queryname("Participant's baseline MFQ total score was below the clinical cut-off point of 20. Confirm?")

restore


////////////////////////////////////////////////////////////////////////////////
**# Date checks
////////////////////////////////////////////////////////////////////////////////

* Run only once per participant
preserve

	keep if week == 0

	* Confirm eligibility date is before randomisation date
	queries eligibility_date randomisation_date if eligibility_date > randomisation_date & !missing(randomisation_date) & !missing(eligibility_date), queryname("Recorded date of eligibility confirmation is after recorded randomisation date. Confirm?")

	* Confirm consent date is before randomisation date
	queries informedconsent_date randomisation_date if informedconsent_date > randomisation_date & !missing(informedconsent_date) & !missing(randomisation_date), queryname("Recorded date of consent is after recorded randomisation date. Confirm?")

	* Confirm baseline questionnaire was completed before randomisation
	queries datequestionnaire randomisation_date if datequestionnaire > randomisation_date & !missing(datequestionnaire) & !missing(randomisation_date), queryname("Baseline assessment was completed after randomisation. Confirm?")
	
	* Confirm completion date is after randomisation date
	queries randomisation_date complete_date_1 if randomisation_date > complete_date_1 & !missing(complete_date_1) & !missing(randomisation_date), queryname("Randomisation date recorded after completion date: Completion date must be after randomisation date. Confirm?")

restore

* Order of dates: check that the questionnaire follow-up dates line up correctly
use "$out\INDIGO_derived_dataset_17122025_wide.dta", clear

label var datequestionnaire_wk0 "Date of completing baseline questionnaire"
label var datequestionnaire_wk8 "Date of completing week 8 questionnaire"
label var datequestionnaire_wk16 "Date of completing week 16 questionnaire"
label var datequestionnaire_wk24 "Date of completing week 24 questionnaire"

* Check randomisation date before week 8
queries rand_date datequestionnaire_wk8 if rand_date > datequestionnaire_wk8 & !missing(datequestionnaire_wk8), queryname("Randomisation date should be before week 8 visit date according to protocol. However, the randomisation date recorded is after the recorded week 8 visit date. Confirm?")

* Check week 8 date before week 16
queries datequestionnaire_wk8 datequestionnaire_wk16 if datequestionnaire_wk8 > datequestionnaire_wk16 & !missing(datequestionnaire_wk8) & !missing(datequestionnaire_wk16), queryname("Week 8 assessment date should be before week 16 assessment date according to protocol. However, the week 8 assessment date recorded is after the recorded week 16 visit date. Please confirm or correct dates.")

* Check week 16 date before week 24
queries datequestionnaire_wk16 datequestionnaire_wk24 if datequestionnaire_wk16 > datequestionnaire_wk24 & !missing(datequestionnaire_wk16) & !missing(datequestionnaire_wk24), queryname("Week 16 visit date should be before week 24 visit date according to protocol. However, the week 16 visit date recorded is after the recorded week 24 visit date. PLease confirm or correct dates.")

* Check that all assessment dates are before extract date (not in future)
foreach var of varlist datequestionnaire_wk0 datequestionnaire_wk8 datequestionnaire_wk16 datequestionnaire_wk24 {
	queries `var' if `var' > td(17122025) & !missing(`var'), queryname("Assessment date was after extract date - please check date entered.")
}

* Check that all randomisation dates before extract date (not in future)
queries rand_date if rand_date > td(17122025) & !missing(rand_date), queryname("Randomisation date was after extract date - please check dates entered.")


////////////////////////////////////////////////////////////////////////////////
**# Visit windows
////////////////////////////////////////////////////////////////////////////////


* Load INDIGO data in long format
use "$out\INDIGO_17122025_long.dta", clear

* Confirm follow-up time points within correct time window: 8-week follow up date is 8 weeks (+/-4 weeks) after randomisation
* corresponds to 28 days to 84 days after randomisation)
preserve

	keep if week == 8

	* Generate time diffference between randomisation date and week 8 assessment date
	gen rand_2_wk8 = datediff(randomisation_date,datequestionnaire, "day")
	label variable rand_2_wk8 "Time from Randomisation to 8-Week Follow Up Visit (in days)"

	* Generate missingness indicator
	gen rand_2_wk8_miss = 1 if missing(datequestionnaire) | missing(randomisation_date)
	label variable rand_2_wk8_miss "Missing dates: Time from Randomisation to week 8 follow-up"

	queries rand_2_wk8 if (rand_2_wk8 < 28 | rand_2_wk8 > 84) & rand_2_wk8_miss != 1, queryname("This participant observation did not adhere to 8-week follow-up visit window (4-12 weeks or 28-84 days after randomisation). Please enter confirm if this date is correct?")

restore


* Confirm follow-up time points within correct time window: 16-week follow up date is 16 weeks (+/-4 weeks) after randomisation
* corresponds to 84 days to 140 days after randomisation)
preserve

	keep if week == 16

	* Generate time diffference between randomisation date and week 16 assessment date
	gen rand_2_wk16 = datediff(randomisation_date,datequestionnaire, "day")
	label variable rand_2_wk16 "Time from Randomisation to 16-weeks Follow Up Visit (in days)"

	* Generate missingness indicator
	gen rand_2_wk16_miss = 1 if missing(datequestionnaire) | missing(randomisation_date)
	label variable rand_2_wk16_miss "Missing dates: Time from Randomisation to week 16 follow-up"

	queries rand_2_wk16 if (rand_2_wk16 < 84 | rand_2_wk16 > 140) & rand_2_wk16_miss != 1, queryname("This participant observation did not adhere to 16-week follow-up visit window (12-20 weeks or 84-140 days after randomisation). Please enter confirm if this date is correct?")

restore


* Confirm follow-up time points within correct time window: 16-week follow up date is 24 weeks (+/-4 weeks) after randomisation
* corresponds to 140 days to 196 days after randomisation)
preserve

	keep if week == 24

	* Generate time diffference between randomisation date and week 24 assessment date
	gen rand_2_wk24 = datediff(randomisation_date,datequestionnaire, "day")
	label variable rand_2_wk24 "Time from Randomisation to 24-weeks Follow Up Visit (in days)"

	* Generate missingness indicator
	gen rand_2_wk24_miss = 1 if missing(datequestionnaire) | missing(randomisation_date)
	label variable rand_2_wk24_miss "Missing dates: Time from Randomisation to week 24 follow-up"

	queries rand_2_wk24 if (rand_2_wk24 < 140 | rand_2_wk24 > 196) & rand_2_wk24_miss != 1, queryname("This participant observation did not adhere to 24-week follow-up visit window (20-28 weeks or 140-196 days after randomisation). Please enter confirm if this date is correct?")

restore

////////////////////////////////////////////////////////////////////////////////
* Data completeness checks: primary and secondary outcome (essential questionnaires only)
////////////////////////////////////////////////////////////////////////////////

* MFQ
queries MFQ_TOT qaire_pack_complete if missing(MFQ_TOT) & qaire_pack_complete == 2, queryname("Indicated that the questionnaire pack was completed but MFQ total score is missing. Confirm?")

* RCADS
queries RCADS_TOT qaire_pack_complete if missing(RCADS_TOT) & qaire_pack_complete == 2, queryname("Indicated that the questionnaire pack was completed but RCADS total score is missing. Confirm?.")

* AMT
* calculate AMT missingness indicator
egen amt_missing = rownonmiss(amt_*_type amt_*_time)
replace amt_missing = 20 - amt_missing

queries amt_missing amt_qaire_complete if amt_missing == 20 & amt_qaire_complete == 2, queryname("Indicated that the questionnaire pack was completed but AMT score is missing. Please check data completeness for this participant.")

drop amt_missing

* Week 8 feedback
egen w8_feed_present = rownonmiss(feed_*)

queries w8_feed_present week_8_feedback_questionnaire_co if w8_feed_present == 0 & week_8_feedback_questionnaire_co == 2, queryname("Indicated that the questionnaire pack was completed but week 8 feedback form data is missing . Please check data completeness for this participant.")

drop w8_feed_present

* Check about participants missing completion information of study
preserve

	keep if week == 0
	
	queries complete_1 if missing(complete_1), queryname("The question: Did participant complete the trial (yes/no)? was not answered for this participant. Meaning, there is no completion or discontinuation date recorded. Please update the completion information accordingly or confirm loss to follow up/ missing information.")

restore

////////////////////////////////////////////////////////////////////////////////
* MFQ 
////////////////////////////////////////////////////////////////////////////////

* For each clinical measure:
	* check items are within range
	* check total scores are within range
	
* Check that item scores are in possible range (0, 1, 2)
foreach i of numlist 1/33 {
	queries mfq_`i' week if !inrange(mfq_`i', 0, 2) & !missing(mfq_`i'), queryname("MFQ Questionnaire item `i' not in expected range (0, 1, 2)")
		}
		
* MFQ total score (33 items; each item 0-2; total score range 0-66)
queries MFQ_TOT if !inrange(MFQ_TOT, 0, 66) & !missing(MFQ_TOT), queryname("MFQ (33-item version) total score: Score not in expected range (0-66).")


////////////////////////////////////////////////////////////////////////////////
* RCADS
////////////////////////////////////////////////////////////////////////////////

* Check that items score are in possible range (0, 1, 2, 3)
foreach i of numlist 1 3/5 7/9 10 12/14 16/18 20 22/24 26/28 30/39 41/46 {
	queries rcads_`i' week if !inrange(rcads_`i', 0, 3) & !missing(rcads_`i'), queryname("RCADS Questionnaire item `i' not in expected range (0, 1, 2, 3)")
		}
		
* RCADS total scores in range
* Social phobia
queries RCADS_SocPhob_TOT if !inrange(RCADS_SocPhob_TOT, 0, 27) & !missing(RCADS_SocPhob_TOT), queryname("RCADS Social Phobia total score: Score not in expected range (0-27).")

* Panic disorder
queries RCADS_PanDis_TOT if !inrange(RCADS_PanDis_TOT, 0, 27) & !missing(RCADS_PanDis_TOT), queryname("RCADS Panic Disorder total score: Score not in expected range (0-27).")

* Separation anxiety
queries RCADS_SepAnx_TOT if !inrange(RCADS_SepAnx_TOT, 0, 21) & !missing(RCADS_SepAnx_TOT), queryname("RCADS Separation Anxiety total score: Score not in expected range (0-21).")

* Generalised anxiety
queries RCADS_GenAnx_TOT if !inrange(RCADS_GenAnx_TOT, 0, 18) & !missing(RCADS_GenAnx_TOT), queryname("RCADS Generalised Anxiety total score: Score not in expected range (0-18).")

* Obsessive compulsive scale
queries RCADS_ObsCom_TOT if !inrange(RCADS_ObsCom_TOT, 0, 18) & !missing(RCADS_ObsCom_TOT), queryname("RCADS Obsessive-Compulsive subscale total score: Score not in expected range (0-18).")

////////////////////////////////////////////////////////////////////////////////
* BADS
////////////////////////////////////////////////////////////////////////////////

* Check that items score are in possible range (0, 1, 2, 3, 4, 5, 6)
foreach i of numlist 1/25 {
	queries bads_`i' week if !inrange(bads_`i', 0, 6) & !missing(bads_`i'), queryname("BADS Questionnaire item `i' not in expected range (0, 1, 2, 3, 4, 5, 6)")
		}
		
* BADS total scores in range
* AC
queries BADS_AC if !inrange(BADS_AC, 0, 42) & !missing(BADS_AC), queryname("BADS Activation total score: Score not in expected range (0-42).")

* AR
queries BADS_AR if !inrange(BADS_AR, 0, 48) & !missing(BADS_AR), queryname("BADS Avoidance/ Rumination total score: Score not in expected range (0-48).")

* SI
queries BADS_SI if !inrange(BADS_SI, 0, 30) & !missing(BADS_SI), queryname("BADS Social Impairment total score: Score not in expected range (0-30).")

* WS
queries BADS_WS if !inrange(BADS_WS, 0, 30) & !missing(BADS_WS), queryname("BADS School Impairment total score: Score not in expected range (0-30).")

////////////////////////////////////////////////////////////////////////////////
* AMI
////////////////////////////////////////////////////////////////////////////////

* Check that items score are in possible range (0, 1, 2, 3, 4)
foreach i of numlist 4/15 {
	queries ami_p`i' week if !inrange(ami_p`i', 0, 4) & !missing(ami_p`i'), queryname("AMI-Y Questionnaire item `i' from positive image scale not in expected range (0, 1, 2, 3, 4)")
	queries ami_n`i' week if !inrange(ami_n`i', 0, 4) & !missing(ami_n`i'), queryname("AMI-Y Questionnaire item `i' from negative image scale not in expected range (0, 1, 2, 3, 4)")
		}
		
* Item 2: 1, 2, 3, 4, 5
queries ami_p2 week if !inrange(ami_p2, 1, 5) & !missing(ami_p2), queryname("AMI-Y Questionnaire item 2 from positive image scale not in expected range (1, 2, 3, 4, 5)")
	queries ami_n2 week if !inrange(ami_n2, 1, 5) & !missing(ami_n2), queryname("AMI-Y Questionnaire item 2 from negative image scale not in expected range (1, 2, 3, 4, 5)")
	
* AMI negative scale total score in range
queries AMI_n_TOT if !inrange(AMI_n_TOT, 0, 53) & !missing(AMI_n_TOT), queryname("AMI-Y negative image scale: Total score not in expected range (0-53).")

* AMI positive scale total score in range
queries AMI_p_TOT if !inrange(AMI_p_TOT, 0, 53) & !missing(AMI_p_TOT), queryname("AMI-Y positive image scale: Total score not in expected range (0-53).")

////////////////////////////////////////////////////////////////////////////////
* SPPC
////////////////////////////////////////////////////////////////////////////////

* Check that items score are in possible range (1, 2, 3, 4)
foreach i of numlist 1/5 {
	queries sppc_`i' week if !inrange(sppc_`i', 1, 4) & !missing(sppc_`i'), queryname("SPPC Questionnaire item `i' not in expected range (1, 2, 3, 4)")
		}
		
* SPPC total score in range
queries SPPC_TOT if !inrange(SPPC_TOT, 1, 20) & !missing(SPPC_TOT), queryname("SPPC questionnaire: Total score not in expected range (1-20).")

////////////////////////////////////////////////////////////////////////////////
* PIT
////////////////////////////////////////////////////////////////////////////////

* Check that items score are in possible range (1, 2, 3, 4, 5)
foreach i of numlist 1/14 {
	queries pit_`i' week if !inrange(pit_`i', 1, 5) & !missing(pit_`i'), queryname("PIT Questionnaire item `i' not in expected range (1, 2, 3, 4, 5)")
		}
		
* PIT negative scale total score in range
queries PIT_NEG_TOT if !inrange(PIT_NEG_TOT, 1, 30) & !missing(PIT_NEG_TOT), queryname("PIT negative scale: Total score not in expected range (1-30).")

* PIT positive scale total score in range
queries PIT_POS_TOT if !inrange(PIT_POS_TOT, 1, 40) & !missing(PIT_POS_TOT), queryname("PIT positive scale: Total score not in expected range (1-40).")

////////////////////////////////////////////////////////////////////////////////
* CRIES
////////////////////////////////////////////////////////////////////////////////

* Check that items score are in possible range (0, 1, 3, 5)
foreach i of numlist 1/8 {
	queries cries_`i' week if !inrange(cries_`i', 0, 5) & !missing(cries_`i'), queryname("CRIES Questionnaire item `i' not in expected range (0, 1, 3, 5)")
		}
		
* CRIES intrusion total score in range
queries CRIES_INT_TOT if !inrange(CRIES_INT_TOT, 0, 20) & !missing(CRIES_INT_TOT), queryname("CRIES intrusion subscale: Total score not in expected range (0-20).")

* CRIES avoidance total score in range
queries CRIES_AVO_TOT if !inrange(CRIES_AVO_TOT, 0, 20) & !missing(CRIES_AVO_TOT), queryname("CRIES avoidance subscale: Total score not in expected range (0-20).")

////////////////////////////////////////////////////////////////////////////////
* SCS
////////////////////////////////////////////////////////////////////////////////

* Check that items score are in possible range (1, 2, 3, 4, 5)
foreach i of numlist 1/12 {
	queries scs_`i' week if !inrange(scs_`i', 1, 5) & !missing(scs_`i'), queryname("SCS Questionnaire item `i' not in expected range (1, 2, 3, 4, 5)")
		}
		
* SCS total score in range
queries SCS_TOT if !inrange(SCS_TOT, 1, 60) & !missing(SCS_TOT), queryname("SCS questionnaire: Total score not in expected range (1-60).")

////////////////////////////////////////////////////////////////////////////////
* ISI
////////////////////////////////////////////////////////////////////////////////

* Check that items score are in possible range (0, 1, 2, 3, 4)
foreach i of numlist 1/7 {
	queries isi_`i' week if !inrange(isi_`i', 0, 4) & !missing(isi_`i'), queryname("ISI Questionnaire item `i' not in expected range (0, 1, 2, 3, 4)")
		}
		
* ISI total score in range
queries ISI_TOT if !inrange(ISI_TOT, 0, 28) & !missing(ISI_TOT), queryname("ISI questionnaire: Total score not in expected range (0-28).")

////////////////////////////////////////////////////////////////////////////////
* AMT
////////////////////////////////////////////////////////////////////////////////

* Check that items score are in possible range (1, 2, 3, 4, 5)
foreach i in p1 p2 p3 p4 p5 n6 n7 n8 n9 n10 {
	queries amt_`i'_type week if !inrange(amt_`i'_type, 1, 5) & !missing(amt_`i'_type), queryname("AMT Questionnaire item `i' not in expected range (1, 2, 3, 4, 5)")
		}


////////////////////////////////////////////////////////////////////////////////
**# Save Queries as Spreadsheet
////////////////////////////////////////////////////////////////////////////////

cd "$queries"

	clear
	set obs 0
	
	gen str255 trialid = ""
	gen str255 site = ""
	gen str255 question1 = ""
	gen str255 label1 = ""
	gen str255 value1 = ""
	gen str255 question2 = ""
	gen str255 label2 = ""
	gen str255 value2 = ""
	gen str255 query = ""


* Append all the query files
	local filelist: dir . files "query*.dta"
	foreach file of local filelist {
		dis "`file'"
		  append using "`file'", force
	}

* Sort by the pin and site
sort trialid site

* Output to spreadsheet tab by site
levelsof site, local(levels)
foreach l of local levels {
	export excel using "data_queries_$S_DATE.xlsx" if site =="`l'", sheet("`l'") firstrow(variables) sheetreplace
	}
	
* Export to excel in one spreadsheet
*export excel using "data_queries_$S_DATE.xlsx", sheet("Queries") firstrow(variables) sheetreplace


* #### LAST LINE ####
display "$S_TIME  $S_DATE"

* Translate and close log
log close
cd "$logs"
translate "INDIGO_4_Queries$dateout.smcl" "INDIGO_4_Queries$dateout.pdf", replace

