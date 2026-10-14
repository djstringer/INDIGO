////////////////////////////////////////////////////////////////////////////////
/* //=========================================================================//
	INDIGO Data Cleaning: Scoring 
	Author: Ciel Burges
	Date of Data Extract: 17/12/2025
	Started 05/01/2026
	Stata 19
	
	V1 (12/01/2026) Leave in postcode column to check calculation of deprivation index
*/ //=========================================================================//
////////////////////////////////////////////////////////////////////////////////


* INDIGO_2_Score.do: 
	* This creates the derived field for the dataset: pro-rating and calculating 
	* total scores

* Definitions of missing data:
	* 666 (.e) Not assessed (for eligibility form)
	* 777 (.a) Not available or not applicable 
	* 888 (.b) Not done 
	* 999 (.c) Unknown 
	
* This script was developed in STATA 19
version 18
clear
cap log close
set more off
set linesize 85

clear
cap log close
set more off

* Initialise log file
log using "$logs\INDIGO_2_Score$dateout", replace

* Set working directory
cd "$out"

* Load INDIGO data (wide format)
use "$out\INDIGO_dataset_23022026.dta", clear

////////////////////////////////////////////////////////////////////////////////
* Set Missing data codes 777, 888 and 999 to .a, .b and .c
////////////////////////////////////////////////////////////////////////////////

* Identify var list of numeric vars
ds, not(type string) // Run with below code 

foreach var of varlist `r(varlist)' {
	replace `var' = .a if `var' == 777 | `var' == 777.7 | `var' == 777.77 | `var' == 777.777 | `var' == 7777 | (`var' > 777 & `var' < 778)
	replace `var' = .b if `var' == 888 | `var' == 888.8 | `var' == 888.88 | `var' == 888.888 | `var' == 8888 | (`var' > 888 & `var' < 889)
	replace `var' = .c if `var' == 999 | `var' == 999.9 | `var' == 999.99 | `var' == 999.999 | `var' == 9999 | (`var' > 999 & `var' < 1000)
}

* Identify var list of string vars
ds, not(type numeric) // Run with below code 
foreach var of varlist `r(varlist)' {
	replace `var' = ".a" if `var' == "777" | `var' == "777.7" | `var' == "777.77" | `var' == "777.777" | `var' == "7777" 
	replace `var' = ".b" if `var' == "888" | `var' == "888.8" | `var' == "888.88" | `var' == "888.888" | `var' == "8888" 
	replace `var' = ".c" if `var' == "999" | `var' == "999.9" | `var' == "999.99" | `var' == "999.999" | `var' == "9999"
}

* Special 666 missing code for eligibility form
local eli_list scr_el_mfq scr_el_therapist scr_el_infosheet el2_age el2_consent el2_diagnosis el2_english el2_ld el2_mfq el2_other el2_risk el2_therapy el2_willing

foreach var in `eli_list' {
	replace `var' = .e if `var' == 666
}

////////////////////////////////////////////////////////////////////////////////
* Create subset of data by measure
////////////////////////////////////////////////////////////////////////////////


* Instead of keeping this variables separate by rescheduling, combine assessment log and rescheduled assessment log. Visit date (rather than scheduled visit) will indicate adherence to time frame

* Create new assessment log variables: 
foreach i in wk0 wk8 wk16 wk24 {
	// attend
	gen attend_`i'_c = 1 if attend_`i' == 1 | attend_`i'_r == 1 | attend_`i'_r_r2 == 1
	replace attend_`i'_c = 0 if attend_`i' == 0 & (attend_`i'_r == 0 | missing(attend_`i'_r)) & (attend_`i'_r_r2 == 0 | missing(attend_`i'_r_r2))
	label var attend_`i'_c "Attended assessment or rescheduled assessment (yes=1)"
	order attend_`i'_r attend_`i'_r_r2 attend_`i'_c, after(attend_`i')
}	


foreach i in wk0 wk8 wk16 wk24 {
	// risk
	gen risk_`i'_c = 0 if risk_`i' == 0 | risk_`i'_r == 0 | risk_`i'_r_r2 == 0
	replace risk_`i'_c = 1 if risk_`i' == 1 | risk_`i'_r == 1 | risk_`i'_r_r2 == 1
	label var risk_`i'_c "Risk issues (yes=1)"
	* Order
	order risk_`i'_r risk_`i'_r_r2 risk_`i'_c, after(risk_`i')
}	


	// breaks
foreach i in wk0 wk8 wk16 wk24 {
	gen breaks_`i'_c = breaks_`i' if !missing(breaks_`i') & missing(breaks_`i'_r) & missing(breaks_`i'_r_r2)
	replace breaks_`i'_c = breaks_`i'_r if !missing(breaks_`i'_r)
	replace breaks_`i'_c = breaks_`i'_r_r2 if !missing(breaks_`i'_r_r2)
	label var breaks_`i'_c "Number of breaks in assessment"
	
	order breaks_`i'_r breaks_`i'_r_r2 breaks_`i'_c, after(breaks_`i')
	
	// length
	gen length_`i'_c = length_`i' if !missing(length_`i') & missing(length_`i'_r) & missing(length_`i'_r_r2)
	replace length_`i'_c = length_`i'_r if !missing(length_`i'_r)
	replace length_`i'_c = length_`i'_r_r2 if !missing(length_`i'_r_r2)
	label var length_`i'_c "Length of assessment"
	
	order length_`i'_r length_`i'_r_r2 length_`i'_c, after(length_`i')
	
	// length breaks
	gen length_breaks_`i'_c = length_breaks_`i' if !missing(length_breaks_`i') & missing(length_breaks_`i'_r) & missing(length_breaks_`i'_r_r2)
	replace length_breaks_`i'_c = length_breaks_`i'_r if !missing(length_breaks_`i'_r)
	replace length_breaks_`i'_c = length_breaks_`i'_r_r2 if !missing(length_breaks_`i'_r_r2)
	label var length_breaks_`i'_c "If breaks, total duration of breaks"
	
	order length_breaks_`i'_r length_breaks_`i'_r_r2 length_breaks_`i'_c, after(length_breaks_`i')
	
	// recorded
	gen recorded_`i'_c = 0 if recorded_`i' == 0 | recorded_`i'_r == 0 | recorded_`i'_r_r2 == 0
	replace recorded_`i'_c = 1 if recorded_`i' == 1 | recorded_`i'_r == 1 | recorded_`i'_r_r2 == 1
	label var recorded_`i'_c "Audio-recorded assessment (yes=1)"
	
	order recorded_`i'_r recorded_`i'_r_r2 recorded_`i'_c, after(recorded_`i')
	
	// engagement
	gen engagement_`i'_c = 0 if engagement_`i' == 0 | engagement_`i'_r == 0 | engagement_`i'_r_r2 == 0
	replace engagement_`i'_c = 1 if engagement_`i' == 1 | engagement_`i'_r == 1 | engagement_`i'_r_r2 == 1
	label var engagement_`i'_c "Adequate engagement with assessment (yes=1)"
	
	order engagement_`i'_r engagement_`i'_r_r2 engagement_`i'_c, after(engagement_`i')
}

	// reason dna
	describe reason_dna*
foreach i in wk0 wk8 wk16 wk24 {
	gen reason_dna_`i'_c = .
	// if did not attend last rescheduled meeting (i.e., did not attend at all), replace with reason dna
	replace reason_dna_`i'_c = reason_dna_`i' if attend_`i'_c == 0 & attend_`i' == 0 & missing(attend_`i'_r) & missing(attend_`i'_r_r2)
	replace reason_dna_`i'_c = reason_dna_`i'_r if attend_`i'_c == 0 & attend_`i'_r == 0 & missing(attend_`i'_r_r2)
	replace reason_dna_`i'_c = reason_dna_`i'_r_r2 if attend_`i'_c == 0 & attend_`i'_r_r2 == 0 
	label var reason_dna_`i'_c "Reason participant did not attend (final rescheduled) assessment"
	order reason_dna_`i'_r reason_dna_`i'_r_r2 reason_dna_`i'_c, after(reason_dna_`i')
}

	// only keep other_dna for ppts who did not attend time point at all (attend_`i'_c == 0)
foreach i in wk0 wk8 wk16 wk24 {
	gen other_dna_`i'_c = other_dna_`i' if attend_`i'_c == 0
	label var other_dna_`i'_c "Other reason participant did not attend (final rescheduled) assessment"
	order other_dna_`i'_c, after(other_dna_`i')
}

	// norecording_reason
foreach i in wk0 wk8 wk16 wk24 {
	gen norecording_reason_`i'_c = .
	replace norecording_reason_`i'_c = norecording_reason_`i' if recorded_`i'_c == 0 & attend_`i'_c == 1 & attend_`i' == 1
	replace norecording_reason_`i'_c = norecording_reason_`i'_r if recorded_`i'_c == 0 & attend_`i'_c == 1 & attend_`i'_r == 1
	replace norecording_reason_`i'_c = norecording_reason_`i'_r_r2 if recorded_`i'_c == 0 & attend_`i'_c == 1 & attend_`i'_r_r2 == 1
	
	label var norecording_reason_`i'_c "Reason for no audio recording at assessment"
	order norecording_reason_`i'_r norecording_reason_`i'_r_r2 norecording_reason_`i'_c, after(norecording_reason_`i')
}
	
* Drop old (rescheduled) assessment log vars
foreach i in wk0 wk8 wk16 wk24 {
	foreach m in attend risk breaks length length_breaks recorded engagement reason_dna other_dna norecording_reason {
		drop `m'_`i' `m'_`i'_r `m'_`i'_r_r2
	}
}



* ==============================================================================

* Check (rescheduled) date of assessment variables
order eligibility_date informedconsent_date randomisation_date date_wk0 date_wk0_r date_wk0_r_r2 datequestionnaire_wk0 date_wk8 date_wk8_r date_wk8_r_r2 datequestionnaire_wk8 date_wk16 date_wk16_r date_wk16_r_r2 datequestionnaire_wk16 date_wk24 date_wk24_r date_wk24_r_r2 datequestionnaire_wk24, after(infosheet_date)

* Drop scheduling dates as time of actual visit encoded in datequestionnaire variables
drop date_wk0 date_wk0_r date_wk0_r_r2 date_wk8 date_wk8_r date_wk8_r_r2 date_wk16 date_wk16_r date_wk16_r_r2 date_wk24 date_wk24_r date_wk24_r_r2


////////////////////////////////////////////////////////////////////////////////
* MFQ and baseline info
////////////////////////////////////////////////////////////////////////////////

* For each measure at each time point:
	* Pro-rate according to SAP/ protocol
	* Calculate total scores as described in SAP/ protocol
	* Rename variables for consistency for reshape

* Pro-rate MFQ outcome according to SAP/ protocol
* MFQ at baseline, week 8, week 16, week 24
rename *_w8 *_wk8
foreach num in wk0 wk8 wk16 wk24 {
	local vlist`num' mfq_1_`num' mfq_2_`num' mfq_3_`num' mfq_4_`num' mfq_5_`num' mfq_6_`num' mfq_7_`num' mfq_8_`num' mfq_9_`num' mfq_10_`num' mfq_11_`num' mfq_12_`num' mfq_13_`num' mfq_14_`num' mfq_15_`num' mfq_16_`num' mfq_17_`num' mfq_18_`num' mfq_19_`num' mfq_20_`num' mfq_21_`num' mfq_22_`num' mfq_23_`num' mfq_24_`num' mfq_25_`num' mfq_26_`num' mfq_27_`num' mfq_28_`num' mfq_29_`num' mfq_30_`num' mfq_31_`num' mfq_32_`num' mfq_33_`num'
	local min_obs`num' 27 // 20 % max missing
	egen count`num' = rownonmiss(`vlist`num'')
	egen mean`num' = rowmean(`vlist`num'')
	foreach var in `vlist`num'' {
		replace `var' = mean`num' if count`num' >= `min_obs`num'' & `var'== .
	}
	egen MFQ_TOT_`num' = rowtotal(`vlist`num'') if count`num' >= `min_obs`num''
	drop count`num' mean`num'	
}


* Re-order total scores for better readability
order MFQ_TOT_wk0, after(mfq_33_wk0)
order MFQ_TOT_wk8, after(mfq_33_wk8)
order MFQ_TOT_wk16, after(mfq_33_wk16)
order MFQ_TOT_wk24, after(mfq_33_wk24)


////////////////////////////////////////////////////////////////////////////////
* RCADS
////////////////////////////////////////////////////////////////////////////////


* Pro-rate RCADS according to SAP and calculate total score (sum of all items). Prorate if less than 20% of scale missing: 30 of 37 items at least non-missing
foreach num in wk0 wk8 wk16 wk24 {
	local vlist`num' rcads_1_`num' rcads_3_`num' rcads_4_`num' rcads_5_`num' rcads_7_`num' rcads_8_`num' rcads_9_`num' rcads_10_`num' rcads_12_`num' rcads_13_`num' rcads_14_`num' rcads_16_`num' rcads_17_`num' rcads_18_`num' rcads_20_`num' rcads_22_`num' rcads_23_`num' rcads_24_`num' rcads_26_`num' rcads_27_`num' rcads_28_`num' rcads_30_`num' rcads_31_`num' rcads_32_`num' rcads_33_`num' rcads_34_`num' rcads_35_`num' rcads_36_`num' rcads_37_`num' rcads_38_`num' rcads_39_`num' rcads_41_`num' rcads_42_`num' rcads_43_`num' rcads_44_`num' rcads_45_`num' rcads_46_`num'
	local min_obs`num' 30
	egen count`num' = rownonmiss(`vlist`num'')
	egen mean`num' = rowmean(`vlist`num'')
	foreach var in `vlist`num'' {
		replace `var' = mean`num' if count`num' >= `min_obs`num'' & `var'== .
	}
	egen RCADS_TOT_`num' = rowtotal(`vlist`num'') if count`num' >= `min_obs`num''
	drop mean`num'	
}


* Calculate subscale total scores: 
	* social phobia: 4, 7, 8, 12, 20, 30, 32, 38, 43
	* panic disorder: 3, 14, 24, 26, 28, 34, 36, 39, 41
	* separation anxiety: 5, 9, 17, 18, 33, 45, 46
	* Generalised anxiety: 1, 13, 22, 27, 35, 37
	* obsessive compulsive: 10, 16, 23, 31, 42, 44

foreach i in wk0 wk8 wk16 wk24 {
	local min_obs`i' 30
	egen RCADS_SocPhob_TOT_`i' = rowtotal(rcads_4_`i' rcads_7_`i' rcads_8_`i' rcads_12_`i' rcads_20_`i' rcads_30_`i' rcads_32_`i' rcads_38_`i' rcads_43_`i') if count`i' >= `min_obs`i''
	egen RCADS_PanDis_TOT_`i' = rowtotal(rcads_3_`i' rcads_14_`i' rcads_24_`i' rcads_26_`i' rcads_28_`i' rcads_34_`i' rcads_36_`i' rcads_39_`i' rcads_41_`i') if count`i' >= `min_obs`i''
	egen RCADS_SepAnx_TOT_`i' = rowtotal(rcads_5_`i' rcads_9_`i' rcads_17_`i' rcads_18_`i' rcads_33_`i' rcads_45_`i' rcads_46_`i') if count`i' >= `min_obs`i''
	egen RCADS_GenAnx_TOT_`i' = rowtotal(rcads_1_`i' rcads_13_`i' rcads_22_`i' rcads_27_`i' rcads_35_`i' rcads_37_`i') if count`i' >= `min_obs`i''
	egen RCADS_ObsCom_TOT_`i' = rowtotal(rcads_10_`i' rcads_16_`i' rcads_23_`i' rcads_31_`i' rcads_42_`i' rcads_44_`i') if count`i' >= `min_obs`i''
	drop count`i'
}

* Re-order for readability 
foreach i in wk0 wk8 wk16 wk24 {
	order RCADS_TOT_`i' RCADS_SocPhob_TOT_`i' RCADS_PanDis_TOT_`i' RCADS_SepAnx_TOT_`i' RCADS_GenAnx_TOT_`i' RCADS_ObsCom_TOT_`i', after(rcads_46_`i')
}

////////////////////////////////////////////////////////////////////////////////
* BADS
////////////////////////////////////////////////////////////////////////////////


* Pro-rate items by subscale and calculate subscale total scores according to SAP: items should only be reverse coded for BADS total score. Thus, not reverse coded as no indication for use of total score in SAP
	* AC: 3 4 5 7 11 12 23 (7 items)
	* AR: 8 9 10 13 14 15 24 25 (8 items) 
	* WS: 1 2 6 21 22  (5 items)
	* SI: 16 17 18 19 20 (5 items)

foreach num in wk0 wk8 wk16 wk24 {
	
}
	
* Calculate total score (including reverse coding of al items not on activation scale) just in case

foreach num in wk0 wk8 wk16 wk24 {
	recode bads_8_`num' bads_9_`num' bads_10_`num' bads_13_`num' bads_14_`num' bads_15_`num' bads_24_`num' bads_25_`num' bads_1_`num' bads_2_`num' bads_6_`num' bads_21_`num' bads_22_`num' bads_16_`num' bads_17_`num' bads_18_`num' bads_19_`num' bads_20_`num' (6=0) (5=1) (4=2) (3=3) (2=4) (1=5) (0=6), pre(r_)

	// AC subscale
	local AC_list`num' bads_3_`num' bads_4_`num' bads_5_`num' bads_7_`num' bads_11_`num' bads_12_`num' bads_23_`num'
	local AC_min_obs`num' 6
	egen AC_count`num' = rownonmiss(`AC_list`num'')
	egen AC_mean`num' = rowmean(`AC_list`num'')
	foreach var in `AC_list`num'' {
		replace `var' = AC_mean`num' if AC_count`num' >= `AC_min_obs`num'' & `var'== .
	}
	egen BADS_AC_`num' = rowtotal(`AC_list`num'') if AC_count >= `AC_min_obs`num''
	drop AC_count`num' AC_mean`num'
	
	// AR subscale
	local AR_list`num' r_bads_8_`num' r_bads_9_`num' r_bads_10_`num' r_bads_13_`num' r_bads_14_`num' r_bads_15_`num' r_bads_24_`num' r_bads_25_`num'
	local AR_min_obs`num' 7
	egen AR_count`num' = rownonmiss(`AR_list`num'')
	egen AR_mean`num' = rowmean(`AR_list`num'')
	foreach var in `AR_list`num'' {
		replace `var' = AR_mean`num' if AR_count`num' >= `AR_min_obs`num'' & `var'== .
	}
	egen BADS_AR_`num' = rowtotal(`AR_list`num'') if AR_count >= `AR_min_obs`num''
	drop AR_count`num' AR_mean`num'
	
	// WS subscale
	local WS_list`num' r_bads_1_`num' r_bads_2_`num' r_bads_6_`num' r_bads_21_`num' r_bads_22_`num' 
	local WS_min_obs`num' 4
	egen WS_count`num' = rownonmiss(`WS_list`num'')
	egen WS_mean`num' = rowmean(`WS_list`num'')
	foreach var in `WS_list`num'' {
		replace `var' = WS_mean`num' if WS_count`num' >= `WS_min_obs`num'' & `var'== .
	}
	egen BADS_WS_`num' = rowtotal(`WS_list`num'') if WS_count >= `WS_min_obs`num''
	drop WS_count`num' WS_mean`num'
	
	// SI subscale 
	local SI_list`num' r_bads_16_`num' r_bads_17_`num' r_bads_18_`num' r_bads_19_`num' r_bads_20_`num' 
	local SI_min_obs`num' 4
	egen SI_count`num' = rownonmiss(`SI_list`num'')
	egen SI_mean`num' = rowmean(`SI_list`num'')
	foreach var in `SI_list`num'' {
		replace `var' = SI_mean`num' if SI_count`num' >= `SI_min_obs`num'' & `var'== .
	}
	egen BADS_SI_`num' = rowtotal(`SI_list`num'') if SI_count >= `SI_min_obs`num''
	drop SI_count`num' SI_mean`num'
	
	egen BADS_TOT_`num' = rowtotal(bads_8_`num' bads_9_`num' bads_10_`num' bads_13_`num' bads_14_`num' bads_15_`num' bads_24_`num' bads_25_`num'  r_bads_8_`num' r_bads_9_`num' r_bads_10_`num' r_bads_13_`num' r_bads_14_`num' r_bads_15_`num' r_bads_24_`num' r_bads_25_`num' r_bads_1_`num' r_bads_2_`num' r_bads_6_`num' r_bads_21_`num' r_bads_22_`num' r_bads_16_`num' r_bads_17_`num' r_bads_18_`num' r_bads_19_`num' r_bads_20_`num') if !missing(BADS_SI_`num') & !missing(BADS_AR_`num') & !missing(BADS_AC_`num') & !missing(BADS_WS_`num')
	drop r_bads*`num'
}

* Re-order variables for better readability
foreach i in wk0 wk8 wk16 wk24 {
	order BADS_AC_`i' BADS_AR_`i' BADS_WS_`i' BADS_SI_`i' BADS_TOT_`i', after(bads_25_`i')
	sum BADS_AC_`i' BADS_AR_`i' BADS_WS_`i' BADS_SI_`i' BADS_TOT_`i'
}


////////////////////////////////////////////////////////////////////////////////
* AMI
////////////////////////////////////////////////////////////////////////////////

* Positive and negative AMI scales. Items 1 and 3 are descriptive and are not included in the total score (see SAP). 


* Prorate and calculate total scores if 2 items or less missing for postive and negative AMI scales separately (20% prorating)
foreach num in wk0 wk8 wk16 wk24 {
	foreach val in n p {
		local `val'_list`num' ami_`val'2_`num' ami_`val'4_`num' ami_`val'5_`num' ami_`val'6_`num' ami_`val'7_`num' ami_`val'8_`num' ami_`val'9_`num' ami_`val'10_`num' ami_`val'11_`num' ami_`val'12_`num' ami_`val'13_`num' ami_`val'14_`num' ami_`val'15_`num'
		local `val'_min_obs`num' 11
		egen `val'_count`num' = rownonmiss(``val'_list`num'')
		egen `val'_mean`num' = rowmean(``val'_list`num'')
		foreach var in ``val'_list`num'' {
			replace `var' = `val'_mean`num' if `val'_count`num' >= ``val'_min_obs`num'' & `var'== .
		}
		egen AMI_`val'_TOT_`num' = rowtotal(``val'_list`num'') if `val'_count`num' >= ``val'_min_obs`num''
		drop `val'_count`num' `val'_mean`num'	
		order AMI_`val'_TOT_`num', after(ami_`val'15_`num')
	}
}


////////////////////////////////////////////////////////////////////////////////
* SPPC
////////////////////////////////////////////////////////////////////////////////


* Prorate and calculate total score according to SAP
foreach num in wk0 wk8 wk16 wk24 {
	local vlist`num' sppc_1_`num' sppc_2_`num' sppc_3_`num' sppc_4_`num' sppc_5_`num'
	local min_obs`num' 4
	egen count`num' = rownonmiss(`vlist`num'')
	egen mean`num' = rowmean(`vlist`num'')
	foreach var in `vlist`num'' {
		replace `var' = mean`num' if count`num' >= `min_obs`num'' & `var'== .
	}
	egen SPPC_TOT_`num' = rowtotal(`vlist`num'') if count`num' >= `min_obs`num''
	drop count`num' mean`num'	
	order SPPC_TOT_`num', after(sppc_5_`num')
}

////////////////////////////////////////////////////////////////////////////////
* PIT
////////////////////////////////////////////////////////////////////////////////

//Positive items: 3, 5, 6, 8, 9, 12 and 13. 
//Negative: 1, 2, 4, 7, 10, 11 and 14.

//DS corrected 190126

* Prorate and calculate total scores for positive and negative scales separately
* Positive scale
foreach num in wk0 wk8 wk16 wk24 {
	local vlist`num' pit_3_`num' pit_5_`num' pit_6_`num' pit_8_`num' pit_9_`num' pit_12_`num' pit_13_`num'
	local min_obs`num' 6
	egen count`num' = rownonmiss(`vlist`num'')
	egen mean`num' = rowmean(`vlist`num'')
	foreach var in `vlist`num'' {
		replace `var' = mean`num' if count`num' >= `min_obs`num'' & `var'== .
	}
	egen PIT_POS_TOT_`num' = rowtotal(`vlist`num'') if count`num' >= `min_obs`num''
	drop count`num' mean`num'	
	order PIT_POS_TOT_`num', after(pit_14_`num')
}

* Negative scale
foreach num in wk0 wk8 wk16 wk24 {
	local vlist`num'  pit_1_`num' pit_2_`num' pit_4_`num' pit_7_`num' pit_10_`num' pit_11_`num' pit_14_`num' 
	local min_obs`num' 6
	egen count`num' = rownonmiss(`vlist`num'')
	egen mean`num' = rowmean(`vlist`num'')
	foreach var in `vlist`num'' {
		replace `var' = mean`num' if count`num' >= `min_obs`num'' & `var'== .
	}
	egen PIT_NEG_TOT_`num' = rowtotal(`vlist`num'') if count`num' >= `min_obs`num''
	drop count`num' mean`num'	
	order PIT_NEG_TOT_`num', after(PIT_POS_TOT_`num')
}

////////////////////////////////////////////////////////////////////////////////
* CRIES
////////////////////////////////////////////////////////////////////////////////


* Prorate and calculate total scores for intrusion and avoidance scales separately (20% pro-rating)
	
	* intrusion subscale
foreach num in wk0 wk8 wk16 wk24 {
	local vlist`num' cries_1_`num' cries_3_`num' cries_6_`num' cries_7_`num'
	local min_obs`num' 4
	egen count`num' = rownonmiss(`vlist`num'')
	egen mean`num' = rowmean(`vlist`num'')
	foreach var in `vlist`num'' {
		replace `var' = mean`num' if count`num' >= `min_obs`num'' & `var'== .
	}
	egen CRIES_INT_TOT_`num' = rowtotal(`vlist`num'') if count`num' >= `min_obs`num''
	drop count`num' mean`num'	
	order CRIES_INT_TOT_`num', after(cries_8_`num')
}

	* avoidance scale
foreach num in wk0 wk8 wk16 wk24 {
	local vlist`num' cries_2_`num' cries_4_`num' cries_5_`num' cries_8_`num'
	local min_obs`num' 4
	egen count`num' = rownonmiss(`vlist`num'')
	egen mean`num' = rowmean(`vlist`num'')
	foreach var in `vlist`num'' {
		replace `var' = mean`num' if count`num' >= `min_obs`num'' & `var'== .
	}
	egen CRIES_AVO_TOT_`num' = rowtotal(`vlist`num'') if count`num' >= `min_obs`num''
	drop count`num' mean`num'	
	order CRIES_AVO_TOT_`num', after(CRIES_INT_TOT_`num')
}


	* overall scale
foreach num in wk0 wk8 wk16 wk24 {
	local vlist`num' cries_1_`num' cries_3_`num' cries_6_`num' cries_7_`num' ///
	cries_2_`num' cries_4_`num' cries_5_`num' cries_8_`num'
	local min_obs`num' 8
	egen count`num' = rownonmiss(`vlist`num'')
	egen mean`num' = rowmean(`vlist`num'')
	foreach var in `vlist`num'' {
		replace `var' = mean`num' if count`num' >= `min_obs`num'' & `var'== .
	}
	egen CRIES_OVER_TOT_`num' = rowtotal(`vlist`num'') if count`num' >= `min_obs`num''
	drop count`num' mean`num'	
	order CRIES_OVER_TOT_`num', after(CRIES_AVO_TOT_`num')
}



////////////////////////////////////////////////////////////////////////////////
* SCS
////////////////////////////////////////////////////////////////////////////////

* Reverse score relevant items
foreach i in wk0 wk8 wk16 wk24 {
	foreach num in 1 4 8 9 11 12 {
		recode scs_`num'_`i' (1=5) (2=4) (3=3) (4=2) (5=1), pre(r_) 
	}
}

* Prorate and calculate total score according to SAP (20% pro-rating)
foreach num in wk0 wk8 wk16 wk24 {
	local vlist`num' r_scs_1_`num' scs_2_`num' scs_3_`num' r_scs_4_`num' scs_5_`num' scs_6_`num' scs_7_`num' r_scs_8_`num' r_scs_9_`num' scs_10_`num' r_scs_11_`num' r_scs_12_`num'
	local min_obs`num' 10
	egen count`num' = rownonmiss(`vlist`num'')
	egen mean`num' = rowmean(`vlist`num'')
	foreach var in `vlist`num'' {
		replace `var' = mean`num' if count`num' >= `min_obs`num'' & `var'== .
	}
	egen SCS_TOT_`num' = rowtotal(`vlist`num'') if count`num' >= `min_obs`num''
	drop count`num' mean`num'	
	order SCS_TOT_`num', after(scs_12_`num')
}

* Drop recoded items again
drop r_scs*

////////////////////////////////////////////////////////////////////////////////
* ISI
////////////////////////////////////////////////////////////////////////////////
* Prorate and calculate total score according to SAP
foreach num in wk0 wk8 wk16 wk24 {
	local vlist`num' isi_1_`num' isi_2_`num' isi_3_`num' isi_4_`num' isi_5_`num' isi_6_`num' isi_7_`num' 
	local min_obs`num' 6
	egen count`num' = rownonmiss(`vlist`num'')
	egen mean`num' = rowmean(`vlist`num'')
	foreach var in `vlist`num'' {
		replace `var' = mean`num' if count`num' >= `min_obs`num'' & `var'== .
	}
	egen ISI_TOT_`num' = rowtotal(`vlist`num'') if count`num' >= `min_obs`num''
	drop count`num' mean`num'	
	order ISI_TOT_`num', after(isi_7_`num')
}

////////////////////////////////////////////////////////////////////////////////
* AMT
////////////////////////////////////////////////////////////////////////////////
foreach num in wk0 wk8 wk16 wk24 {
	local vlist`num' amt_p1_type_`num' amt_p3_type_`num' amt_p4_type_`num' amt_p5_type_`num' ///
	amt_n6_type_`num' amt_n7_type_`num' amt_n8_type_`num' amt_n9_type_`num' amt_n10_type_`num'
	egen AMT_specific_TOT_`num' =anycount(`vlist`num''),values(1)
	local min_obs`num' 10
	egen count`num' = rownonmiss(`vlist`num'')
	replace AMT_specific_TOT_`num' = . if count`num'<8
	label var AMT_specific_TOT_`num' "AMT `num' total specific memories"
}



////////////////////////////////////////////////////////////////////////////////
* Clinical risk acceptability
////////////////////////////////////////////////////////////////////////////////

* EDIT VAR NAMES: where baseline is the only timepoint and needs to be maintained as separate variable in long format: 
	* diagnosis1_b diagnosis2_b diagnosis3_b diagnosis4_b
	* med1_b med2_b med3_b med4_b pastmed1_b pastmed2_b pastmed3_b pastmed4_b

rename diagnosis1_wk0 diagnosis1_b
rename diagnosis2_wk0 diagnosis2_b
rename diagnosis3_wk0 diagnosis3_b
rename diagnosis4_wk0 diagnosis4_b
rename med1_wk0 med1_b
rename med2_wk0 med2_b
rename med3_wk0 med3_b
rename med4_wk0 med4_b
rename pastmed1_wk0 pastmed1_b
rename pastmed2_wk0 pastmed2_b
rename pastmed3_wk0 pastmed3_b
rename pastmed4_wk0 pastmed4_b

* Label baseline only clinical and risk items
label var diagnosis1_b "Baseline diagnosis 1"
label var diagnosis2_b "Baseline diagnosis 2"
label var diagnosis3_b "Baseline diagnosis 3"
label var diagnosis4_b "Additional baseline diagnosis"
label var med1_b "Medication 1 (Name, dose, start date)"
label var med2_b "Medication 2 (Name, dose, start date)"
label var med3_b "Medication 3 (Name, dose, start date)"
label var med4_b "Additional medication (Name, dose, start date)"
label var pastmed1_b "Past medication 1 for mental health (Name, dose, start and end date)"
label var pastmed2_b "Past medication 2 for mental health (Name, dose, start and end date)"
label var pastmed3_b "Past medication 3 for mental health (Name, dose, start and end date)"
label var pastmed4_b "Past medication ADDITIONAL for mental health (Name, dose, start and end date)"

* Create empty dummy variables for smoother reshape


order therapy_1_wk0, before(therapy_2_wk0)
gen diagnosis_wk0 = .
gen new_diagnosis_wk0 = .
gen diagnosisremoved_wk0 = .
gen medication_wk0 = .
gen stopmeds_wk0 = .
gen newmeds_wk0 =.
order diagnosis_wk0 new_diagnosis_wk0 diagnosisremoved_wk0 medication_wk0 stopmeds_wk0, after(pastmed4_b)
*gen new_diagnosis_wk24 = .
order new_diagnosis_wk24, after(diagnosis_wk24)


//participant flow - TO DO
//identify visit completion variables
//identify withdrawal variable


//attend variables
tab1 attend_wk* 
//reasons for not attending

label define dna_reason 1"Therapist cancelled" 2 "Pt declined" 3 "Pt in other meeting" 4  "Pt DNA" 5 "Other"
label values reason_dna_wk*_c dna_reason

tab1 reason_dna_wk*_c other_dna_wk*_c

//generate visit time variables from randomisation - TO DO
// datequestionnaire_wk0 datequestionnaire_wk8 datequestionnaire_wk16 datequestionnaire_wk24

label define withdrawal ///
    1 "Discontinue treatment (but willing to continue with assessments)" ///
    2 "Discontinue the study (but do not withdraw their data)" ///
    3 "Withdraw their consent (i.e., data provided so far is withdrawn)"

label define with_reason ///
    1 "Adverse events related" ///
    2 "Participant's decision" ///
    3 "Investigator's decision" ///
    4 "Sponsor's decision" ///
    5 "Participant moved school or out of area" ///
    6 "Lost to follow-up" ///
    7 "Other"

label values discontinue_type_1 withdrawal
label values discontinuation_reason_1 with_reason

tab1 discontinue_date_1 discontinue_type_1 discontinuation_reason_1 discontin_explain_1

tab discontinue_type_1 treat
tab discontinuation_reason_1 treat if discontinue_type_1==1
tab discontinuation_reason_1 treat if discontinue_type_1==2


tab discontin_explain_1 if discontinuation_reason_1==7

//generate timing - both for discontinue treatment and study
// datequestionnaire_wk0 datequestionnaire_wk8 datequestionnaire_wk16 datequestionnaire_wk24


gen discontinue_treat_time = 0 if discontinue_date_1 < datequestionnaire_wk0 & discontinue_type_1==1 &  !missing(datequestionnaire_wk0)
replace discontinue_treat_time = 1 if discontinue_date_1 < datequestionnaire_wk8 & discontinue_type_1==1 & missing(discontinue_treat_time) &  !missing(datequestionnaire_wk0)
replace discontinue_treat_time = 2 if discontinue_date_1 < datequestionnaire_wk16 & discontinue_type_1==1 & missing(discontinue_treat_time) &  !missing(datequestionnaire_wk8)
replace discontinue_treat_time = 3 if discontinue_date_1 < datequestionnaire_wk24 & discontinue_type_1==1 & missing(discontinue_treat_time) &  !missing(datequestionnaire_wk16)
replace discontinue_treat_time = 4 if discontinue_date_1 >= datequestionnaire_wk24 & discontinue_type_1==1 & missing(discontinue_treat_time)&  !missing(datequestionnaire_wk24)

label define discontinue_treat_time 0"Prior to Baseline" 1"Between baseline and Week 8" 2"Between Week 8 and Week 16" 3"Between Week 16 and Week 24" 4"After Week 24"
label values discontinue_treat_time discontinue_treat_time

gen wd_time = 0 if discontinue_date_1 < datequestionnaire_wk0 & discontinue_type_1==2 &  !missing(datequestionnaire_wk0)
replace wd_time = 1 if discontinue_date_1 < datequestionnaire_wk8 & discontinue_type_1==2 & missing(wd_time) &  !missing(datequestionnaire_wk0)
replace wd_time = 2 if discontinue_date_1 < datequestionnaire_wk16 & discontinue_type_1==2 & missing(wd_time) &  !missing(datequestionnaire_wk8)
replace wd_time = 3 if discontinue_date_1 < datequestionnaire_wk24 & discontinue_type_1==2 & missing(wd_time) &  !missing(datequestionnaire_wk16)
replace wd_time = 4 if discontinue_date_1 >= datequestionnaire_wk24 & discontinue_type_1==2 & missing(wd_time) &  !missing(datequestionnaire_wk24)


replace wd_time = 4 if trialid==51096
label define wd_time 0"Prior to Baseline" 1"Between baseline and Week 8" 2"Between Week 8 and Week 16" 3"Between Week 16 and Week 24" 4"After Week 24"
label values wd_time wd_time 


li trialid qaire_pack_complete_wk8 wd_time datequestionnaire_wk8 if qaire_pack_complete_wk8==0
li trialid qaire_pack_complete_wk16 wd_time datequestionnaire_wk16 if qaire_pack_complete_wk16==0
li trialid qaire_pack_complete_wk24 wd_time datequestionnaire_wk24 if qaire_pack_complete_wk24==0

gen wk8_status = 0 if qaire_pack_complete_wk8==2
replace wk8_status = 1 if wd_time==1
replace wk8_status = 5 if wd_time!=1 & qaire_pack_complete_wk8==0 

gen wk16_status = 0 if qaire_pack_complete_wk16==2
replace wk16_status = 1 if wd_time==1
replace wk16_status = 2 if wd_time==2
replace wk16_status = 5 if (wd_time!=1 & wd_time!=2) & qaire_pack_complete_wk16==0 

gen wk24_status = 0 if qaire_pack_complete_wk24==2
replace wk24_status = 1 if wd_time==1
replace wk24_status = 2 if wd_time==2
replace wk24_status = 3 if wd_time==3
replace wk24_status = 5 if (wd_time!=1 & wd_time!=2 & wd_time!=3) & qaire_pack_complete_wk24==0 

label define status 0"Visit complete"  1" WD Between baseline and Week 8" 2"WD Between Week 8 and Week 16" 3"WD Between Week 16 and Week 24" 5"Visit missed but not WD"
label values wk8_status wk16_status wk24_status status
tab1 *status


tab attend_wk8_c wk8_status
tab attend_wk16_c wk16_status
tab attend_wk24_c wk24_status

br trialid *wk24_c if attend_wk24==0 & wk24_status==0


foreach wk in wk0 wk8 wk16 wk24 {
    gen days_`wk' = datequestionnaire_`wk' - rand_date
}

//visit windows
    gen visit_win_8 = (days_wk8<=84 & days_wk8>=28)
	replace visit_win_8=. if missing(datequestionnaire_wk8)
    gen visit_win_16 = (days_wk16<=140 & days_wk16>=84)
	replace visit_win_16=. if missing(datequestionnaire_wk16)
    gen visit_win_24 = (days_wk24<=196 & days_wk24>=140)
	replace visit_win_24=. if missing(datequestionnaire_wk24)

label define visitwin 0"Outside visit window" 1"Within visit window"
label values visit_win_8 visit_win_16 visit_win_24 visitwin

tab1 visit_win*

sum days*
bysort treat:sum days*


br discontinue_type_1 discontinue_date_1 *status if !missing(discontinue_type_1)
//ignore complete variable as this includes discontinuation due to treatment

foreach var of varlist MFQ_TOT_wk0 MFQ_TOT_wk8 MFQ_TOT_wk16 MFQ_TOT_wk24 {
label var `var' "Mood and Feelings Questionnaire Total Score"
}


foreach var of varlist RCADS_TOT_wk0 RCADS_TOT_wk8 RCADS_TOT_wk16 RCADS_TOT_wk24 {
label var `var' "RCADS Anxiety Score"
}

foreach var of varlist SPPC_TOT_wk0 SPPC_TOT_wk8 SPPC_TOT_wk16 SPPC_TOT_wk24 {
    label var `var' "Self-worth subscale of the Harter Self-Perception Scale total score"
}

foreach var of varlist ISI_TOT_wk0 ISI_TOT_wk8 ISI_TOT_wk16 ISI_TOT_wk24 {
    label var `var' "Insomnia Severity Index total score"
}

foreach var of varlist BADS_TOT_wk0 BADS_TOT_wk8 BADS_TOT_wk16 BADS_TOT_wk24 {
    label var `var' "Behavioural Activation for Depression Scale total score"
}

foreach var of varlist CRIES_INT_TOT_wk0 CRIES_INT_TOT_wk8 CRIES_INT_TOT_wk16 CRIES_INT_TOT_wk24 {
    label var `var' "CRIES Intrusion Score"
}

foreach var of varlist CRIES_AVO_TOT_wk0 CRIES_AVO_TOT_wk8 CRIES_AVO_TOT_wk16 CRIES_AVO_TOT_wk24 {
    label var `var' "CRIES Avoidance Score"
}

foreach var of varlist CRIES_OVER_TOT_wk0 CRIES_OVER_TOT_wk8 CRIES_OVER_TOT_wk16 CRIES_OVER_TOT_wk24 {
    label var `var' "CRIES Total Score"
}

foreach var of varlist AMI_n_TOT_wk0 AMI_n_TOT_wk8 AMI_n_TOT_wk16 AMI_n_TOT_wk24 {
    label var `var' "AMI-Y Negative Imagery Score"
}

foreach var of varlist AMI_p_TOT_wk0 AMI_p_TOT_wk8 AMI_p_TOT_wk16 AMI_p_TOT_wk24 {
    label var `var' "AMI-Y Positive Imagery Score"
}

foreach var of varlist PIT_POS_TOT_wk0 PIT_POS_TOT_wk8 PIT_POS_TOT_wk16 PIT_POS_TOT_wk24 {
    label var `var' "FIT Positive Score"
}

foreach var of varlist PIT_NEG_TOT_wk0 PIT_NEG_TOT_wk8 PIT_NEG_TOT_wk16 PIT_NEG_TOT_wk24 {
    label var `var' "FIT Negative Score"
}

foreach var of varlist SCS_TOT_wk0 SCS_TOT_wk8 SCS_TOT_wk16 SCS_TOT_wk24 {
    label var `var' "Self-Compassion Scale total score"
}




//Credibility
//pef_logic pef_useful pef_recommend

tab1 pef_improvement pef_feel1 pef_feel2 pef_logic pef_useful pef_recommend

gen pef_improvement_conversion = (pef_improvement/100)*9
gen pef_feel2_conversion = (pef_feel2/100)*9

tab1 pef_improvement_conversion pef_feel2_conversion

egen credibility_score = rowtotal(pef_logic pef_useful pef_recommend)
replace credibility_score=. if missing(pef_logic)|missing(pef_useful)|missing(pef_recommend)
//Expectancy
//pef_improvement pef_feel1 pef_feel2
egen expectancy_score = rowtotal(pef_improvement_conversion pef_feel1 pef_feel2_conversion)
replace expectancy_score=. if missing(pef_improvement)|missing(pef_feel1)|missing(pef_feel2)



//Feedback Q

label define feed_agree 0"Strongly disagree" 1"Disagree" 2"Neither agree nor disagree" 3"Agree" 4"Strongly agree"
label values feed_agree_1 feed_agree_2 feed_agree_3 feed_agree_9 feed_agree


//individual
//feed_agree_1
//feed_agree_2
//feed_agree_3
//feed_agree_9

//therapist motivation
//feed_agree_4
//feed_agree_7
egen therapist_mot_score = rowmean(feed_agree_4 feed_agree_7)
replace therapist_mot_score=. if missing(feed_agree_4)|missing(feed_agree_7)
//therapist relationship
//feed_agree_5
//feed_agree_6
//feed_agree_8
egen therapist_rel_score = rowmean(feed_agree_5 feed_agree_6 feed_agree_8)
replace therapist_rel_score=. if missing(feed_agree_5)|missing(feed_agree_6)|missing(feed_agree_8)
//frequency count - spoke to someone else
//feed_discuss

replace feed_discuss=. if feed_discuss==888
label define feed_discuss 0"No" 1"Yes"
label values feed_discuss feed_discuss

//li trialid if attend_wk24_c==1 & complete_1==0

* Save dataset
save "$out\INDIGO_derived_dataset_23022026.dta", replace






////////////////////////////////////////////////////////////////////////////////
//AEs
////////////////////////////////////////////////////////////////////////////////
cd "$out"
use INDIGO_therapist_attend.dta,replace


keep trialid school ae_and_sae_reporting_form_timest-v356
br if !missing(date)
keep if !missing(event_n)|!missing(event_n_e2)|!missing(event_n_e3)



//label variables
* Relation
* Relation
label define relation_lbl ///
    1 "Participant" ///
    2 "Assessor" ///
    3 "Therapist"
label values relation relation_lbl
label values relation_e2 relation_lbl
label values relation_e3 relation_lbl

* Description
label define descr_lbl ///
    1 "Low risk act of self-harm (not requiring medical attention)" ///
    2 "High risk acts of self-harm (requiring medical attention, but not medical hospital admission)" ///
    3 "Voluntary admission to psychiatric hospital" ///
    4 "Significant and sustained deterioration of pre-existing mental health condition requiring immediate intervention" ///
    5 "Sectioned under the Mental Health Act" ///
    6 "Suicidal behaviour" ///
    7 "A serious safeguarding issue" ///
    8 "Death by suicide" ///
    9 "Other"
label values descr descr_lbl
label values descr_e2 descr_lbl
label values descr_e3 descr_lbl

* Unexpected
label define unexpected_lbl ///
    1 "Yes" ///
    0 "No"
label values unexpected unexpected_lbl
label values unexpected_e2 unexpected_lbl
label values unexpected_e3 unexpected_lbl

* PI outcome
label define pi_outcome_lbl ///
    1 "Resolved" ///
    2 "Resolved with sequelae" ///
    3 "Ongoing" ///
    4 "Fatal" ///
    5 "Unknown"
label values pi_outcome pi_outcome_lbl
label values pi_outcome_e2 pi_outcome_lbl
label values pi_outcome_e3 pi_outcome_lbl

* PI action
label define pi_action_lbl ///
    1 "Continued with study" ///
    0 "Discontinued study"
label values pi_action pi_action_lbl
label values pi_action_e2 pi_action_lbl
label values pi_action_e3 pi_action_lbl

* AE intensity
label define ae_intensity_lbl ///
    1 "Mild" ///
    2 "Moderate" ///
    3 "Severe"
label values ae_intensity ae_intensity_lbl
label values ae_intensity_e2 ae_intensity_lbl
label values ae_intensity_e3 ae_intensity_lbl

* Location
label define location_lbl ///
    1 "Hospital" ///
    2 "Out-Patient Clinic" ///
    3 "Home" ///
    4 "School" ///
    5 "Other Location"
label values location location_lbl
label values location_e2 location_lbl
label values location_e3 location_lbl

* Causality 1
label define causality1_lbl ///
    1 "Definitely related" ///
    2 "Likely to be related" ///
    3 "Possibly related" ///
    4 "Unlikely to be related" ///
    5 "Unrelated" ///
    6 "Not able to tell"
label values causality1 causality1_lbl
label values causality1_e2 causality1_lbl
label values causality1_e3 causality1_lbl


//reshape events

* 1) Rename the “base” (no suffix) variables to _e1 so all three waves match a pattern
rename relation             relation_e1
rename descr                descr_e1
rename unexpected           unexpected_e1
rename pi_outcome           pi_outcome_e1
rename pi_action            pi_action_e1
rename ae_intensity         ae_intensity_e1
rename location             location_e1
rename causality1           causality1_e1
rename causality2           causality2_e1
rename serious_yes          serious_yes_e1
rename saes_seriousness     saes_seriousness_e1
rename saes_intensity       saes_intensity_e1
rename saes_intensity_no    saes_intensity_no_e1
rename saes_causal          saes_causal_e1
rename saes_causal_no       saes_causal_no_e1
rename saes_relevance       saes_relevance_e1
rename saes_relevance_no    saes_relevance_no_e1
rename saes_expectedness    saes_expectedness_e1
rename saes_expectedness_no saes_expectedness_no_e1


rename event_n event_n_e1
rename pi_id pi_id_e1
rename other_selfdescribe other_selfdescribe_e1
rename event_startdate event_startdate_e1
rename event_awaredate event_awaredate_e1
rename death_date death_date_e1
rename date_resolved date_resolved_e1


drop saes_document_leaf* saes_document_cons* saes_document_*
rename *_e1 *_1
rename *_e2 *_2
rename *_e3 *_3
replace pi_id_1 = "40809" if pi_id_1=="P040809"
destring pi_id_1,replace

keep trialid event_n* pi_id* other_selfdescribe* event_startdate* event_awaredate* death_date* date_resolved* ///
    relation* descr* unexpected* pi_outcome* pi_action* ae_intensity* location* ///
    causality1* causality2* serious_yes* ///
    saes_seriousness* saes_intensity* saes_intensity_no* ///
    saes_causal* saes_causal_no* ///
    saes_relevance* saes_relevance_no* ///
    saes_expectedness* saes_expectedness_no*



tostring date_resolved_2 date_resolved_3  other_selfdescribe_3 event_startdate_3 event_awaredate_3 ,replace
*    Reshape wide -> long
reshape long ///
   event_n_ pi_id_ other_selfdescribe_ event_startdate_ event_awaredate_ death_date_ date_resolved_ ///
    relation_ descr_ unexpected_ pi_outcome_ pi_action_ ae_intensity_ location_ ///
    causality1_ causality2_ serious_yes_ ///
    saes_seriousness_ saes_intensity_ saes_intensity_no_ ///
    saes_causal_ saes_causal_no_ ///
    saes_relevance_ saes_relevance_no_ ///
    saes_expectedness_ saes_expectedness_no_ ///
    , i(trialid) j(e)

* SAES seriousness (flag)
label define saes_seriousness_lbl ///
    1 "Yes" ///
    0 "No"
label values saes_seriousness_ saes_seriousness_lbl

* SAES intensity (flag)
label define saes_intensity_lbl ///
    1 "Yes" ///
    0 "No"
label values saes_intensity_ saes_intensity_lbl

* SAES intensity (detail)
label define saes_intensity_no_lbl ///
    1 "Mild" ///
    2 "Moderate" ///
    3 "Severe" ///
    4 "Downgraded" ///
    5 "Upgraded"
label values saes_intensity_no_ saes_intensity_no_lbl

* SAES causal (flag)
label define saes_causal_lbl ///
    1 "Yes" ///
    0 "No"
label values saes_causal_ saes_causal_lbl

* SAES causal (detail)
label define saes_causal_no_lbl ///
    1 "Definitely related*" ///
    2 "Likely to be related*" ///
    3 "Possibly related*" ///
    4 "Unlikely to be related" ///
    5 "Definitely not related" ///
    6 "Not able to tell"
label values saes_causal_no_ saes_causal_no_lbl

* SAES relevance (detail)
label define saes_relevance_no_lbl ///
    1 "Treatment" ///
    2 "Assessments" ///
    3 "Time burden" ///
    4 "Other"
label values saes_relevance_no_ saes_relevance_no_lbl

* SAES expectedness (detail)
label define saes_expectedness_no_lbl ///
    1 "Expected" ///
    2 "Unexpected" ///
    3 "Unclear*"
label values saes_expectedness_no_ saes_expectedness_no_lbl

* Causality 2 (underscore version)
label define causality2u_lbl ///
    1 "The treatment" ///
    2 "The assessments" ///
    3 "The time burden of the study" ///
    4 "Other"
label values causality2_ causality2u_lbl

* Serious (yes options – underscore version)
label define serious_yesu_lbl ///
    1 "Results in death" ///
    2 "Is life-threatening" ///
    3 "Required overnight hospital admission or prolongation of existing hospitalisation (does not include A&E attendance and discharge without admission)" ///
    4 "Results in persistent or significant disability/incapacity" ///
    5 "Consists of a congenital anomaly or birth defect" ///
    6 "Other"
label values serious_yes_ serious_yesu_lbl

* SAES relevance (flag – underscore version)
label define saes_relevanceu_lbl ///
    1 "Yes" ///
    0 "No"
label values saes_relevance_  saes_expectedness_  saes_relevanceu_lbl



*rder/label the index
label define e_lbl 1 "e1" 2 "e2" 3 "e3"
label values e e_lbl
order trialid e, first

drop if missing(event_n_)


save "$out\INDIGO_AEs.dta", replace
//check timing of events within ran - last visit

////////////////////////////////////////////////////////////////////////////////
//Therapist MFQs and additional risk item from PHQ9
////////////////////////////////////////////////////////////////////////////////
cd "$out"
use INDIGO_therapist_attend.dta,replace

foreach var of varlist smfq* riskphq_s1 riskphq_s2 riskphq_s3 riskphq_s4 {
	replace `var' = .a if `var' == 777 | `var' == 777.7 | `var' == 777.77 | `var' == 777.777 | `var' == 7777 | (`var' > 777 & `var' < 778)
	replace `var' = .b if `var' == 888 | `var' == 888.8 | `var' == 888.88 | `var' == 888.888 | `var' == 8888 | (`var' > 888 & `var' < 889)
	replace `var' = .c if `var' == 999 | `var' == 999.9 | `var' == 999.99 | `var' == 999.999 | `var' == 9999 | (`var' > 999 & `var' < 1000)
}


foreach num in 1 2 3 4 {
	local tlist`num' smfq_1_s`num' smfq_2_s`num' smfq_3_s`num' smfq_4_s`num' smfq_5_s`num' smfq_6_s`num' smfq_7_s`num' smfq_8_s`num' smfq_9_s`num' smfq_10_s`num' smfq_11_s`num' smfq_12_s`num'
	local min_obs`num' 12 // 20 % max missing
	dis "test1"
	egen count`num' = rownonmiss(`tlist`num'')
	dis "test2"
	egen mean`num' = rowmean(`tlist`num'')
	dis "test3"
	foreach var in `tlist`num'' {
		replace `var' = mean`num' if count`num' >= `min_obs`num'' & `var'== .
	}
	dis "test4"
	egen therapist_MFQ_`num' = rowtotal(`tlist`num'') if count`num' >= `min_obs`num''
	drop count`num' mean`num'	
}

sum therapist_MFQ*
label var therapist_MFQ_1 "Session 1 - MFQ-12 score"
label var therapist_MFQ_2 "Session 2 - MFQ-12 score"
label var therapist_MFQ_3 "Session 3 - MFQ-12 score"
label var therapist_MFQ_4 "Session 4 - MFQ-12 score"

label define riskq 0"Not at all" 1"Several days" 2"More than half the days" 3"Nearly ever day"

label values riskphq_s1 riskphq_s2 riskphq_s3 riskphq_s4 riskq
tab1 riskphq_s1 riskphq_s2 riskphq_s3 riskphq_s4

label var riskphq_s1 "Session 1 - PHQ suicide risk question"
label var riskphq_s2 "Session 2 - PHQ suicide risk question"
label var riskphq_s3 "Session 3 - PHQ suicide risk question"
label var riskphq_s4 "Session 4 - PHQ suicide risk question"

replace length_s2 = "80" if length_s2=="8-"
destring length_s2,replace
egen contact_time = rowtotal(length_s1 length_s2 length_s3 length_s4 length_s1_r length_s2_r length_s3_r)


save "$out\INDIGO_therapist_scores.dta", replace

* #### LAST LINE ####
display "$S_TIME  $S_DATE"

* Translate and close log
log close
translate "$logs\INDIGO_2_Score$dateout.smcl" "$logs\INDIGO_2_Score$dateout.pdf", replace


////////////////////////////////////////////////////////////////////////////////
*credibility/expectancy questionnaire
////////////////////////////////////////////////////////////////////////////////

use "$out\INDIGO_dataset_23022026.dta", clear



*************************************************
*LAST LINE
*************************************************

display "$S_TIME $S_DATE"

