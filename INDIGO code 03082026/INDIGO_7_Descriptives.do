////////////////////////////////////////////////////////////////////////////////
/* //=========================================================================//
	INDIGO Descriptives and output
	Author: D Stringer
	Started: 20/01/2026
	Date of extract: 17/12/2025
	Stata 19
*/ //=========================================================================//
////////////////////////////////////////////////////////////////////////////////

//================================
// TEMPORARY SETUP
//==================================
version 18.0
clear
clear matrix

// ===========================
// INSTALL NECESSARY PACKAGES 
// ===========================
*Install Gordon's automated reporting function
//net install post_table, from("https://raw.githubusercontent.com/GForb/post_table_base/master") replace

// ===========================
// SETUP LOGGING
//============================
cd "$logfiles"
* Initialise log file
capture log close
log using "$logs\INDIGO_7_Descriptives$dateout", replace


//============================
// SET UP AUTOMATION OF TABLES
//============================
	cap prog drop putx_tab
	prog  putx_tab
	syntax , filename(string) table_no(integer) [title(string) header_rows(integer 1) header_cols(integer 1) width(integer -1)]  
		use  "`filename'", clear
		local b_outside  border(top) border(bottom)
		*Processing width
		if `width' == -1 {
			local layout layout(autofitw)
			local width 
		}
		else {
			local width width(`width'cm)
		}
		local layout layout(autofitc)
		
		*Table title
		if "`title'" != ""{
			putdocx paragraph, halign(left) 
			putdocx text ("Table `table_no' - `title'"), bold
		}

		*Table
		putdocx table table`table_no' = data(_all) , halign(left)  `layout' `width' cellmargin(top, 1pt)   headerrow(`header_rows')
		putdocx table table`table_no'(.,.), font(calibri, 10) // font for table
		qui putdocx describe table`table_no' 
		local n_col =  r(ncols)
		local n_row = r(nrows)
		
		*Formating header rows
		putdocx table table`table_no'(1 (1) `header_rows' ,.), bold valign(center) halign(center) shading(lightgray)     // font, alignment and shading for header rows can be updated here
		
		
		*Formatting "header columns"
		putdocx table table`table_no'(.,1 (1) `header_cols'), halign(left)  // font and alignment for non header colums can be updated here

		*Formating body of table
		local body_col1 = `header_cols' + 1
		local body_row1 = `header_rows' + 1
		putdocx table table`table_no'(`body_row1' (1) `n_row',`body_col1' (1) `n_col'), halign(right)  // font and alignment for non header colums can be updated here
		

	end

	capture program drop pt_ae
	prog define pt_ae
	version 15.1
	syntax varname [if] [in] , POSTname(string) ///
		[ ///
		over(string) ///
		over_grps(numlist) ///
		overall(string) ///
		gap(integer 0) /// adds empty rows to baseline table after each variable
		row_lab(string) /// Overides default variable label
		comment(string) /// adds column to end of table with text contained in string
		]

	*************IF****************
	if "`if'" != "" | "`in'" != "" {
		preserve
		keep `if' `in'	
	}

	*Setting default for over and extracting the levels of `over'
	if "`over'" != "" {
		if "`over_grps'" == "" levelsof `over', local(over_grps)
		if "`overall'" == "first" local over_grps overall `over_grps'
		if "`overall'" == "last" local over_grps  `over_grps' overall
	}
	if "`over'" == "" local over_grps overall	

	*Comments
	if "`comment'" != "" & "`comment'" != "no comment" local comment2 ("`comment'")
	if "`comment'" == "no comment" local comment2 ("")


	 
	if "`row_lab'" == "" local row_lab "Adverse events"

	tempvar pickone
	egen `pickone' = tag(`varlist')
	 
	foreach i in `over_grps' {
		if "`i'" == "overall" {
			count 
			local n_events = r(N) 
			count if `pickone' ==1
			local n_participants = r(N)
			local summaries `summaries' ("`n_events' (`n_participants')")
		} 
		else {
			count if `over' == `i'
			local n_events = r(N) 
			count if `pickone' ==1 & `over' == `i'
			local n_participants = r(N)
			local summaries `summaries' ("`n_events' (`n_participants')")
		}
	}	

	*Posting
	post `postname' ("    `row_lab'")  `summaries' `comment2'

	*Gaps
	local summaries ""
	foreach i in `over_grps' {
		local summaries `summaries' ("")	
		if "`comment'" != "" local comment2 ("")
	}

	if `gap' > 0 {
		forvalues i = 1 (1) `gap' {
			post `postname' ("")  `summaries' `comment2'
		}
	}

	*************IF****************
	if "`if'" != "" | "`in'" != ""  restore

	end

clear
postutil clear
putdocx clear
putdocx begin, pagenum(decimal) footer(npage)
* Add page number to footer
putdocx paragraph, tofooter(npage) halign(center)
putdocx pagenumber

putdocx paragraph, style(Heading1)
putdocx text ("INDIGO Descriptives Report")



//========================
// PRODUCE TABLE 1
// =======================

cd "$out"

use "INDIGO_data_for_analysis.dta",replace


//Value labels
*--------------------------------------------------
* Ethnicity
*--------------------------------------------------
label define ethnicity_lbl ///
1 "Asian: Indian" ///
2 "Asian: Pakistani" ///
3 "Asian: Bangladeshi" ///
4 "Asian: Chinese" ///
5 "Asian: Any other Asian background" ///
6 "Black: African" ///
7 "Black: Caribbean" ///
8 "Black: Any other Black / African / Caribbean background" ///
9 "Mixed: White and Black Caribbean" ///
10 "Mixed: White and Black African" ///
11 "Mixed: White and Asian" ///
12 "Mixed: Any other mixed / multiple ethnic background" ///
13 "White: English / Welsh / Scottish / Northern Irish / British" ///
14 "White: Irish" ///
15 "White: Gypsy or Irish Traveller" ///
16 "White: Any other White background" ///
17 "Arab" ///
18 "Any other ethnic group"

label values ethnicity ethnicity_lbl

recode ethnicity ///
(1/5 = 1 "Asian") ///
(6/8 = 2 "Black") ///
(9/12 = 3 "Mixed") ///
(13/16 = 4 "White") ///
(17/18 = 5 "Other"), ///
gen(ethnicity_super)

*--------------------------------------------------
* English as first language
*--------------------------------------------------
label define eal_lbl ///
1 "Yes" ///
0 "No" ///
2 "Prefer not to say"

label values eal eal_lbl


*--------------------------------------------------
* Sex
*--------------------------------------------------
label define sex_lbl ///
1 "Male" ///
2 "Female" ///
3 "Prefer to self-describe" ///
4 "Prefer not to say"

label values sex sex_lbl


*--------------------------------------------------
* Gender identity
*--------------------------------------------------
label define gender_id_lbl ///
1 "Woman" ///
2 "Man" ///
3 "Non-binary or genderqueer" ///
4 "Trans woman (Male to female)" ///
5 "Trans man (Female to male)" ///
6 "Gender fluid" ///
7 "Cross-dresser" ///
8 "Agender" ///
9 "Gender identity not listed" ///
10 "Don't know" ///
11 "Prefer not to say"

label values gender_id gender_id_lbl


*--------------------------------------------------
* GCSEs / BTechs
*--------------------------------------------------
label define gcse_btech_lbl ///
1 "GCSE" ///
2 "BTech" ///
3 "Both"

label values gcse_btech gcse_btech_lbl


*--------------------------------------------------
* Free school meals
*--------------------------------------------------
label define school_meals_lbl ///
1 "Yes" ///
0 "No" ///
2 "Prefer not to say"

label values school_meals school_meals_lbl


*--------------------------------------------------
* Education, Health and Care Plan
*--------------------------------------------------
label define healthplan_lbl ///
1 "Yes" ///
0 "No" ///
2 "Prefer not to say"

label values healthplan healthplan_lbl


*--------------------------------------------------
* Sexual orientation
*--------------------------------------------------
label define sexual_orientation_lbl ///
1 "Heterosexual (straight)" ///
2 "Lesbian" ///
3 "Gay" ///
4 "Bisexual" ///
5 "Pansexual" ///
6 "Queer" ///
7 "Asexual" ///
8 "Questioning" ///
9 "Sexual orientation not listed above" ///
10 "Prefer not to say" ///
11 "Not sure"

label values sexual_orientation sexual_orientation_lbl


*--------------------------------------------------
* Accommodation (checkbox variables)
*--------------------------------------------------
* Create empty variable
gen accommodation_cat = .

* Assign category based on which checkbox == 1
replace accommodation_cat = 1 if accommodation___1 == 1
replace accommodation_cat = 2 if accommodation___2 == 1
replace accommodation_cat = 3 if accommodation___3 == 1
replace accommodation_cat = 4 if accommodation___4 == 1
replace accommodation_cat = 5 if accommodation___5 == 1
replace accommodation_cat = 6 if accommodation___6 == 1
replace accommodation_cat = 7 if accommodation___7 == 1
replace accommodation_cat = 8 if accommodation___8 == 1
replace accommodation_cat = 9 if accommodation___9 == 1
replace accommodation_cat = 10 if accommodation___10 == 1


* Define value labels
label define accommodation_cat_lbl ///
1 "Family home (owned)" ///
2 "Family home (rented)" ///
3 "Living independently (owned)" ///
4 "Foster care" ///
5 "Residential care" ///
6 "Living with friends or relatives" ///
7 "Living independently (rented)" ///
8 "Bed & breakfast / boarding house / hotel" ///
9 "Homeless: living on the streets" ///
10 "Other"

label values accommodation_cat accommodation_cat_lbl

*--------------------------------------------------
* Family home composition (checkbox variables)
*--------------------------------------------------

/*label define housemates_lbl ///
1 "Mother" ///
2 "Father" ///
3 "Female partner" ///
4 "Male partner" ///
5 "Female siblings" ///
6 "Male siblings" ///
7 "Others"
*/

label define housemates_lbl ///
1 "Yes" ///
0 "No" 

label values housemates___1 housemates_lbl
label values housemates___2 housemates_lbl
label values housemates___3 housemates_lbl
label values housemates___4 housemates_lbl
label values housemates___5 housemates_lbl
label values housemates___6 housemates_lbl
label values housemates___7 housemates_lbl


*--------------------------------------------------
* Religion
*--------------------------------------------------
label define religion_lbl ///
1 "No religion" ///
2 "Christian (all denominations)" ///
3 "Buddhist" ///
4 "Hindu" ///
5 "Jewish" ///
6 "Muslim" ///
7 "Sikh" ///
8 "Any other religion" ///
9 "Prefer not to say"

label values religion religion_lbl


preserve
* Postfile
postfile table1 str150(col1 col2 col3 col4) using "table1", replace

* Table header
post table1 ("Baseline values") ("IMAGINE") ("NDST") ("Overall") 


	pt_base age, postname(table1) type(cont) over(treat) over_grps(1 0) overall(last)

	pt_base age ethnicity ethnicity_super eal sex gender_id, postname(table1) type(cat) over(treat) over_grps(1 0) overall(last)

	pt_base gcse, postname(table1) type(cont) over(treat) over_grps(1 0) overall(last)

	pt_base gcse_btech school_meals healthplan sexual_orientation, postname(table1) type(cat) over(treat) over_grps(1 0) overall(last)

	pt_base imd, postname(table1) type(cont) over(treat) over_grps(1 0) overall(last)
 
	pt_base accommodation_cat ///
housemates___1 housemates___2 housemates___3 housemates___4 housemates___5 housemates___6 housemates___7 ///
religion, postname(table1) type(cat) over(treat) over_grps(1 0) overall(last)

* Post close
postclose table1

* Label table
putdocx paragraph, halign(left)
putdocx text ("Table 1. Demographics by whether completed study"), bold underline font(calibri, 12) 

* Insert table
putx_tab, filename("table1") table_no(1)

restore 
label define complete 1 "Completed" 0"Withdrew from data collection"
label values complete_1 complete

* Postfile
postfile table11 str150(col1 col2 col3 col4) using "table11", replace

* Table header
post table11 ("Baseline values") ("Completed") ("Withdrawn") ("Overall") 


	pt_base age, postname(table11) type(cont) over(complete_1) over_grps(1 0) overall(last)

	pt_base ethnicity_super eal sex, postname(table11) type(cat) over(complete_1) over_grps(1 0) overall(last)

	pt_base gcse imd MFQ_TOT_wk0, postname(table11) type(cont) over(complete_1) over_grps(1 0) overall(last)

* Post close
postclose table11

* Label table
putdocx paragraph, halign(left)
putdocx text ("Table 1b. Demographics by missingness"), bold underline font(calibri, 12) 

* Insert table
putx_tab, filename("table11") table_no(11)


//OUTCOME DESCRIPTIVES


/*
Then, by intervention group, the number of young people completing the programmes, the
number not beginning the programme or discontinuing the programme, the numbers at each assessment time point
and the numbers analysed */
cd "$out"
use INDIGO_derived_dataset_23022026.dta,replace

tab discontinue_type_1 treat
tab discontinuation_reason_1 treat if discontinue_type_1==1
tab discontinuation_reason_1 treat if discontinue_type_1==2

tab1 attend_wk*_c




/*We will separately summarise the number and proportion of participants who actively withdraw from the trial and, if
possible, their reasons for withdrawal, overall and by group. (In line with our ethical informed consent procedure,
participants can discontinue or withdraw from the study at any time without giving a reason) */

//To add visit windows TO DO
cd "$out"
use INDIGO_derived_dataset_23022026.dta,replace



//date randomised
//date of visits


/*
Loss to follow-up and other missing data
The number and proportion of participants missing each primary and secondary outcome variable will be presented
by intervention group and overall, at each time point
*/

/*
Adverse event reporting
The number of serious adverse events and adverse events will be presented as the number of events and number of
individuals with events. These will be provided separately for each randomised group. Adverse events will only be
presented descriptively. 
*/



cd "$out"
use INDIGO_AEs.dta, replace
merge m:1 trialid using INDIGO_data_for_analysis.dta, keepusing(treat) 


* Any event on this row
gen has_event = !missing(e)

* Serious event on this row
gen has_serious = has_event & serious_yes_ == 2

bysort trialid treat: egen n_events = total(has_event)
bysort trialid treat: egen n_serious_events = total(has_serious)

bysort trialid treat: gen any_event = n_events > 0
bysort trialid treat: gen any_serious_event = n_serious_events > 0


tab treat descr if has_event==1,miss

decode descr, gen(event_description) 

replace event_description = other_selfdescribe_ if event_description=="Other"


********************************************************************************
*Event descr table
********************************************************************************

preserve

bysort trialid: keep if _n == 1

collapse ///
    (sum) n_events n_serious_events ///
    (sum) any_event any_serious_event, ///
    by(treat)

* Generate percentages out of 85
gen pct_any_event = (any_event/85)*100
gen pct_any_serious_event = (any_serious_event/85)*100

label variable n_events "Number of events"
label variable any_event "Participants with ≥1 event"
label variable n_serious_events "Number of serious events"
label variable any_serious_event "Participants with ≥1 serious event"

putdocx paragraph, style(Heading1)
putdocx text ("AEs by trial arm")

* Table: header row + one row per group; 5 columns
local n = _N
putdocx table t1 = (`= `n' + 1', 5), border(all)

* Header row
putdocx table t1(1,1) = ("Trial Arm")
putdocx table t1(1,2) = ("Number of events")
putdocx table t1(1,3) = ("Participants with ≥1 event n (%)")
putdocx table t1(1,4) = ("Number of serious events")
putdocx table t1(1,5) = ("Participants with ≥1 serious event n (%)")

* Fill table rows
forvalues i = 1/`n' {
    local r = `i' + 1

    * group may be numeric or string; handle both
    capture confirm string variable treat
    if _rc == 0 {
        local g = treat[`i']
        putdocx table t1(`r',1) = ("`g'")
    }
    else {
        local g = treat[`i']
        putdocx table t1(`r',1) = ("`=string(`g')'")
    }

    putdocx table t1(`r',2) = (n_events[`i'])

    * Format n (%)
    local ae = any_event[`i']
    local ae_pct : display %4.1f pct_any_event[`i']
    putdocx table t1(`r',3) = ("`ae' (`ae_pct'%)")

    putdocx table t1(`r',4) = (n_serious_events[`i'])

    local sae = any_serious_event[`i']
    local sae_pct : display %4.1f pct_any_serious_event[`i']
    putdocx table t1(`r',5) = ("`sae' (`sae_pct'%)")
}

* Optional formatting
putdocx table t1(.,.), halign(center)
putdocx table t1(1,.), bold
putdocx table t1(.,1), halign(left)

restore

preserve

* Keep one row per trial if required
bysort trialid: keep if _n == 1

* Collapse by AE type and trial arm
collapse ///
    (sum) n_events n_serious_events ///
    (sum) any_event any_serious_event, ///
    by(event_description treat)



* Store original arm labels
levelsof treat, local(arms)
local arm1 : word 1 of `arms'
local arm2 : word 2 of `arms'

* Reshape wide (arms become suffixes 1 and 2)
reshape wide n_events any_event n_serious_events any_serious_event, ///
    i(event_description) j(treat)

* Number of AE types
local n = _N

putdocx paragraph, style(Heading1)
putdocx text ("AEs by AE type and trial arm")

* 1 AE column + 4 columns per arm = 9 columns
putdocx table t2 = (`= `n' + 1', 9), border(all)

* Header row
putdocx table t2(1,1) = ("AE Type")

putdocx table t2(1,2) = ("`arm1': Number of events")
putdocx table t2(1,3) = ("`arm1': Participants with ≥1 event")
putdocx table t2(1,4) = ("`arm1': Number of serious events")
putdocx table t2(1,5) = ("`arm1': Participants with ≥1 serious event")

putdocx table t2(1,6) = ("`arm2': Number of events")
putdocx table t2(1,7) = ("`arm2': Participants with ≥1 event")
putdocx table t2(1,8) = ("`arm2': Number of serious events")
putdocx table t2(1,9) = ("`arm2': Participants with ≥1 serious event")

* Fill table rows
forvalues i = 1/`n' {
    local r = `i' + 1

    putdocx table t2(`r',1) = ("`=event_description[`i']'")

    putdocx table t2(`r',2) = (n_events0[`i'])
    putdocx table t2(`r',3) = (any_event0[`i'])
    putdocx table t2(`r',4) = (n_serious_events0[`i'])
    putdocx table t2(`r',5) = (any_serious_event0[`i'])

    putdocx table t2(`r',6) = (n_events1[`i'])
    putdocx table t2(`r',7) = (any_event1[`i'])
    putdocx table t2(`r',8) = (n_serious_events1[`i'])
    putdocx table t2(`r',9) = (any_serious_event1[`i'])
}

* Formatting
putdocx table t2(.,.), halign(center)
putdocx table t2(1,.), bold
putdocx table t2(.,1), halign(left)

restore


preserve


* Keep one row per trial if required
bysort trialid: keep if _n == 1

* Collapse by AE type and trial arm
collapse ///
    (sum) n_events n_serious_events ///
    (sum) any_event any_serious_event, ///
    by(ae_intensity treat)



* Store original arm labels
levelsof treat, local(arms)
local arm1 : word 1 of `arms'
local arm2 : word 2 of `arms'

* Reshape wide (arms become suffixes 1 and 2)
reshape wide n_events any_event n_serious_events any_serious_event, ///
    i(ae_intensity) j(treat)

drop if missing(ae_intensity_)
* Number of AE types
local n = _N

putdocx paragraph, style(Heading1)
putdocx text ("AEs by AE intensity and trial arm")

* 1 AE column + 4 columns per arm = 9 columns
putdocx table t3 = (`= `n' + 1', 9), border(all)

* Header row
putdocx table t3(1,1) = ("AE Intensity")

putdocx table t3(1,2) = ("`arm1': Number of events")
putdocx table t3(1,3) = ("`arm1': Participants with ≥1 event")
putdocx table t3(1,4) = ("`arm1': Number of serious events")
putdocx table t3(1,5) = ("`arm1': Participants with ≥1 serious event")

putdocx table t3(1,6) = ("`arm2': Number of events")
putdocx table t3(1,7) = ("`arm2': Participants with ≥1 event")
putdocx table t3(1,8) = ("`arm2': Number of serious events")
putdocx table t3(1,9) = ("`arm2': Participants with ≥1 serious event")

* Fill table rows
forvalues i = 1/`n' {
    local r = `i' + 1

    putdocx table t3(`r',1) = ("`=eae_intensity[`i']'")

    putdocx table t3(`r',2) = (n_events0[`i'])
    putdocx table t3(`r',3) = (any_event0[`i'])
    putdocx table t3(`r',4) = (n_serious_events0[`i'])
    putdocx table t3(`r',5) = (any_serious_event0[`i'])

    putdocx table t3(`r',6) = (n_events1[`i'])
    putdocx table t3(`r',7) = (any_event1[`i'])
    putdocx table t3(`r',8) = (n_serious_events1[`i'])
    putdocx table t3(`r',9) = (any_serious_event1[`i'])
}

* Formatting
putdocx table t3(.,.), halign(center)
putdocx table t3(1,.), bold
putdocx table t3(.,1), halign(left)

restore
********************************************************************************

//number of AEs
//number of ARs
//number of SAEs

//AE type

//SAE line listing

/*
Additional descriptive analysis on Quality of Life and Service Use (reported outside of primary paper)
NOTE NOT DONE HERE
*/

/*TO DO
//Adherence to allocated intervention and intervention fidelity

The range and average number of sessions completed, total contact time and homework adherence.

*/
cd "$out"
use "INDIGO_data_for_analysis.dta",replace
merge m:1 trialid using INDIGO_therapist_scores.dta, keepusing(trialid number_of_sessions_attended adhered_binary contact_time)

drop if missing(trialid)
//number of attended sessions


gen discontinue_treat = (discontinue_type_1==1)
encode discontin_explain_1, gen(wd_reason)
//gen discontinue_treat_reason =

tab discontinue_treat
merge 1:1 trialid using INDIGO_prot_status.dta, keepusing(trialid therapy_not_protocol) gen(m_prot)


//adherence
replace adhered=0 if therapy_not_protocol==1
//adhered_binary
putdocx paragraph, style(Heading1)
putdocx text ("Adherence to intervention")
* Postfile
postfile table61 str300(col1 col2 col3 col4 col5 col6 col7) using "table61", replace

* Table header
post table61 ("Adherence variable") ("IMAGINE") ("IMAGINE") ("NDST") ("NDST") ("Overall") ("Overall")


	pt_base number_of_sessions_attended contact_time, postname(table61) type(cont) over(treat) over_grps(1 0) overall(last) order(group_over) n_analysis(cols)
	pt_base adhered_binary discontinue_treat, postname(table61) type(cat) over(treat) over_grps(1 0) overall(last) order(group_over) n_analysis(cols)
	pt_base discontinuation_reason_1 wd_reason if discontinue_treat==1, postname(table61) type(cat) over(treat) over_grps(1 0) overall(last) order(group_over) n_analysis(cols)
	pt_base discontinuation_reason_1 if discontinue_treat==1 & discontinuation_reason_1==7, postname(table61) type(cat) over(treat) over_grps(1 0) overall(last) order(group_over) n_analysis(cols)
	pt_base number_of_sessions_attended therapy_not_protocol, postname(table61) type(cat) over(treat) over_grps(1 0) overall(last) order(group_over) n_analysis(cols)
* Post close
postclose table61

* Label table
putdocx paragraph, halign(left)
putdocx text (" Adherence"), bold underline font(calibri, 12) 

* Insert table
putx_tab, filename("table61") table_no(61)
/*
cd "$out"
use "INDIGO_data_for_analysis.dta",replace
merge m:1 trialid using INDIGO_therapist_attend.dta, keepusing(trialid number_of_sessions_attended adhered_binary)

drop if missing(trialid)






//adherence
//adhered_binary
putdocx paragraph, style(Heading1)
putdocx text ("Adherence to intervention")
* Postfile
postfile table71 str300(col1 col2 col3 col4 col5 col6 col7) using "table71", replace

* Table header
post table71 ("Adherence variable") ("IMAGINE") ("IMAGINE") ("NDST") ("NDST") ("Overall") ("Overall")


	pt_base therapy_not_protocol, postname(table71) type(cat) over(treat) over_grps(1 0) overall(last) order(group_over) n_analysis(cols)
	pt_base number_of_sessions_attended if therapy_not_protocol==1, postname(table71) type(cat) over(treat) over_grps(1 0) overall(last) order(group_over) n_analysis(cols)
* Post close
postclose table71

* Label table
putdocx paragraph, halign(left)
putdocx text ("Therapy not following protocol"), bold underline font(calibri, 12) 

* Insert table
putx_tab, filename("table71") table_no(71)
*/

cd "$out"
use "INDIGO_data_for_analysis.dta",replace
merge m:1 trialid using INDIGO_therapist_scores.dta, keepusing(trialid number_of_sessions_attended adhered_binary contact_time)


replace wd_time = 0 if missing(wd_time)
label define wd_time 0"Completed trial",modify
drop if missing(treat)


tab wd_time
preserve
putdocx paragraph, style(Heading1)
putdocx text ("Withdrawal timing")
* Postfile
postfile table7 str150(col1 col2 col3 col4 col5 col6 col7) using "table7", replace

* Table header
post table7 ("Withdrawal") ("IMAGINE") ("IMAGINE") ("NDST") ("NDST") ("Overall") ("Overall")


	pt_base wd_time, postname(table7) type(cat) over(treat) over_grps(1 0) overall(last) n_analysis(cols) order(group_over)
* Post close
postclose table7

* Label table
putdocx paragraph, halign(left)
putdocx text (" Withdrawal time"), bold underline font(calibri, 12) 

putx_tab, filename("table7") table_no(7)
restore

preserve
encode discontin_explain_1, gen(wd_reason)
putdocx paragraph, style(Heading1)
putdocx text ("Withdrawal reasons")
* Postfile
postfile table8 str150(col1 col2 col3 col4) using "table8", replace

* Table header
post table8 ("Withdrawal reason") ("IMAGINE") ("NDST") ("Overall")


	pt_base discontinuation_reason_1 if wd_time>0, postname(table8) type(cat) over(treat) over_grps(1 0) overall(last) order(group_over)
	pt_base wd_reason if discontinuation_reason_1==7, postname(table8) type(cat) over(treat) over_grps(1 0) overall(last)  order(group_over)
		pt_base discontinuation_reason_1 if wd_time==1, postname(table8) type(cat) over(treat) over_grps(1 0) overall(last) order(group_over)
	pt_base wd_reason if discontinuation_reason_1==7 & wd_time==1, postname(table8) type(cat) over(treat) over_grps(1 0) overall(last)  order(group_over)
		pt_base discontinuation_reason_1 if wd_time==2, postname(table8) type(cat) over(treat) over_grps(1 0) overall(last) order(group_over)
	pt_base wd_reason if discontinuation_reason_1==7 & wd_time==2, postname(table8) type(cat) over(treat) over_grps(1 0) overall(last)  order(group_over)
		pt_base discontinuation_reason_1 if wd_time==3, postname(table8) type(cat) over(treat) over_grps(1 0) overall(last) order(group_over)
	pt_base wd_reason if discontinuation_reason_1==7 & wd_time==3, postname(table8) type(cat) over(treat) over_grps(1 0) overall(last)  order(group_over)
	pt_base wd_reason if wd_time>0, postname(table8) type(cat) over(treat) over_grps(1 0) overall(last)  order(group_over)
	pt_base wd_reason if wd_time==1, postname(table8) type(cat) over(treat) over_grps(1 0) overall(last)  order(group_over)
	pt_base wd_reason if wd_time==2|wd_time==3, postname(table8) type(cat) over(treat) over_grps(1 0) overall(last)  order(group_over)
* Post close
postclose table8

* Label table
putdocx paragraph, halign(left)
putdocx text ("Withdrawal reason"), bold underline font(calibri, 12) 

putx_tab, filename("table8") table_no(8)
restore

preserve
use INDIGO_derived_dataset_23022026.dta,replace
drop if missing(treat)
putdocx paragraph, style(Heading1)
putdocx text ("")
* Postfile
postfile table9 str150(col1 col2 col3 col4 col5 col6 col7) using "table9", replace

* Table header
post table9 ("Visit") ("IMAGINE") ("IMAGINE") ("NDST") ("NDST") ("Overall") ("Overall")


	pt_base days_wk8 days_wk16 days_wk24, postname(table9) type(cont) over(treat) over_grps(1 0) overall(last) order(group_over) n_analysis(cols)
	pt_base visit_win_8 visit_win_16 visit_win_24, postname(table9) type(cat) over(treat) over_grps(1 0) overall(last) order(group_over) n_analysis(cols)
postclose table9

* Label table
putdocx paragraph, halign(left)
putdocx text ("Visit windows"), bold underline font(calibri, 12) 

putx_tab, filename("table9") table_no(9)
restore

//========================
// PRODUCE TABLE 2
// =======================

cd "$out"

use "INDIGO_data_for_analysis.dta",replace

label var MFQ_TOT_wk0 "Baseline MFQ total"

* Postfile
postfile table2 str150(col1 col2 col3 col4 col5 col6 col7) using "table2", replace

* Table header
post table2 ("Baseline values") ("IMAGINE") ("IMAGINE") ("NDST") ("NDST") ("Overall") ("Overall")

	pt_base MFQ_TOT_wk0 RCADS_TOT_wk0 SPPC_TOT_wk0 ISI_TOT_wk0 BADS_AC_wk0  BADS_AR_wk0  BADS_WS_wk0  BADS_SI_wk0  BADS_TOT_wk0  BADS_TOT_wk0 CRIES_INT_TOT_wk0 CRIES_AVO_TOT_wk0 CRIES_OVER_TOT_wk0 ///
	AMT_specific_TOT_wk0 AMI_n_TOT_wk0 AMI_p_TOT_wk0 PIT_POS_TOT_wk0 PIT_NEG_TOT_wk0 SCS_TOT_wk0 , postname(table2) type(cont) over(treat) over_grps(1 0) overall(last) n_analysis(cols) order(group_over)

* Post close
postclose table2

* Label table
putdocx paragraph, halign(left)
putdocx text ("Baseline values of outcome measures"), bold underline font(calibri, 12) 

* Insert table
putx_tab, filename("table2") table_no(2)






******************************************
**# Table. 3: Primary outcome follow up **	
******************************************
//==================================
// PREPARE DATASET
//==================================
cd "$out"

use "INDIGO_data_for_analysis.dta",replace
// ===============================
//RENAME VARIABLES
// ===============================


// ====================
// PRODUCE TABLE 3
// ====================		
				
		*Postfile
			postfile table3 str150(col1 col2 col3 col4 col5 col6 col7) using "table3", replace
			
		*Table header
			post table3 ("Primary Outcome timepoint") ("IMAGINE") ("IMAGINE") ("NDST") ("NDST") ("Overall") ("Overall")
		

			pt_base MFQ_TOT_wk8 MFQ_TOT_wk16 MFQ_TOT_wk24, postname(table3) type(cont) over(treat) over_grps(1 0) overall(last) n_analysis(cols) order(group_over)

	*Post close
		postclose table3
	
	*Label table
		putdocx paragraph, halign(left)
		putdocx text ("Follow up outcomes of Primary Outcome measure"), bold underline font(calibri, 12)  
			
	*Insert table
		putx_tab, filename("table3") table_no(3)



// ====================
// PRODUCE TABLE 3b - per protocol means
// ====================		
				cd "$out"

use "INDIGO_data_for_analysis.dta",replace
merge m:1 trialid using INDIGO_therapist_attend.dta, keepusing(trialid number_of_sessions_attended adhered_binary)
drop if missing(trialid)
merge 1:1 trialid using INDIGO_prot_status.dta, keepusing(trialid therapy_not_protocol) gen(m_prot)
//keep adherers per sessions
keep if adhered_binary==1
//drop those adherers who otherwise did not follow intervention protocol
drop if therapy_not_protocol==1
		*Postfile
			postfile table3b str150(col1 col2 col3 col4 col5 col6 col7) using "table3b", replace
			
		*Table header
			post table3b ("Primary Outcome timepoint") ("IMAGINE") ("IMAGINE") ("NDST") ("NDST") ("Overall") ("Overall")
		

			pt_base MFQ_TOT_wk0 MFQ_TOT_wk8 MFQ_TOT_wk16 MFQ_TOT_wk24, postname(table3b) type(cont) over(treat) over_grps(1 0) overall(last) n_analysis(cols) order(group_over)

	*Post close
		postclose table3b
	
	*Label table
		putdocx paragraph, halign(left)
		putdocx text ("Follow up outcomes of Primary Outcome measure - PP"), bold underline font(calibri, 12)  
			
	*Insert table
		putx_tab, filename("table3b") table_no(30)
		
********************************************
**# Table. 4: Secondary outcome follow up ** 	
********************************************
//==================================
// PREPARE DATASET
//==================================
cd "$out"

use "INDIGO_data_for_analysis.dta",replace
	
// ===============================
//RENAME VARIABLES
// ===============================


//Child-rated Strength and Difficulties Questionnaire (SDQ) ADHD subscore 
//	label variable w4_sdq_hyper_score "Child-rated SDQ ADHD subscore"
	//label variable m6_sdq_hyper_score "Child-rated SDQ ADHD subscore"

// ====================
// PRODUCE TABLE 4
// ====================		
preserve
	postfile table4 str150(col1 col2 col3 col4 col5 col6 col7) using "table4", replace
			
		*Table header
	post table4 ("Secondary outcome follow-up") ("IMAGINE") ("IMAGINE") ("NDST") ("NDST") ("Overall") ("Overall")
		

	pt_base RCADS_TOT_wk8 SPPC_TOT_wk8 ISI_TOT_wk8 BADS_AR_wk8 BADS_AC_wk8 BADS_WS_wk8 BADS_SI_wk8 BADS_TOT_wk8 CRIES_INT_TOT_wk8 CRIES_AVO_TOT_wk8 CRIES_OVER_TOT_wk8 ///
	AMT_specific_TOT_wk8 AMI_n_TOT_wk8 AMI_p_TOT_wk8 PIT_POS_TOT_wk8 PIT_NEG_TOT_wk8 SCS_TOT_wk8, postname(table4) type(cont) over(treat) over_grps(1 0) overall(last) n_analysis(cols) order(group_over)

			
	*Post close
		postclose table4
	
	*Label table
		putdocx paragraph, halign(left)
		putdocx text ("Follow up values of secondary outcome measures at week 8"), bold underline font(calibri, 12)  
	
	*Insert table
		putx_tab, filename("table4") table_no(4)	

restore
			// ====================
// PRODUCE TABLE 5
// ====================		
	preserve
	postfile table5 str150(col1 col2 col3 col4 col5 col6 col7) using "table5", replace
			
		*Table header
	post table5 ("Secondary outcome follow-up") ("IMAGINE") ("IMAGINE") ("NDST") ("NDST") ("Overall") ("Overall")
		
		
	pt_base RCADS_TOT_wk16 SPPC_TOT_wk16 ISI_TOT_wk16 BADS_AR_wk16 BADS_AC_wk16 BADS_WS_wk16 BADS_SI_wk16 BADS_TOT_wk16 CRIES_INT_TOT_wk16 CRIES_AVO_TOT_wk16 CRIES_OVER_TOT_wk16 ///
	AMT_specific_TOT_wk16 AMI_n_TOT_wk16 AMI_p_TOT_wk16 PIT_POS_TOT_wk16 PIT_NEG_TOT_wk16 SCS_TOT_wk16, postname(table5) type(cont) over(treat) over_grps(1 0) overall(last) n_analysis(cols) order(group_over)

			
	*Post close
		postclose table5
	
	*Label table
		putdocx paragraph, halign(left)
		putdocx text ("Follow up values of secondary outcome measures at week 16"), bold underline font(calibri, 12)  
	
	*Insert table
		putx_tab, filename("table5") table_no(5)	
		
		
restore
// ====================
// PRODUCE TABLE 6
// ====================		
		preserve
		postfile table6 str150(col1 col2 col3 col4 col5 col6 col7) using "table6", replace
			
		*Table header
			post table6 ("Secondary outcome follow-up") ("IMAGINE") ("IMAGINE") ("NDST") ("NDST") ("Overall") ("Overall")
		
		

	pt_base RCADS_TOT_wk24 SPPC_TOT_wk24 ISI_TOT_wk24 BADS_AR_wk24 BADS_AC_wk24 BADS_WS_wk24 BADS_SI_wk24 BADS_TOT_wk24 CRIES_INT_TOT_wk24 CRIES_AVO_TOT_wk24 CRIES_OVER_TOT_wk24 ///
	AMT_specific_TOT_wk24 AMI_n_TOT_wk24 AMI_p_TOT_wk24 PIT_POS_TOT_wk24 PIT_NEG_TOT_wk24 SCS_TOT_wk24, postname(table6) type(cont) over(treat) over_grps(1 0) overall(last) n_analysis(cols) order(group_over)

			
	*Post close
		postclose table6
	
	*Label table
		putdocx paragraph, halign(left)
		putdocx text ("Follow up values of secondary outcome measures at week 24"), bold underline font(calibri, 12)  
	
	*Insert table
		putx_tab, filename("table6") table_no(8)	
	restore

	
// ====================
// TABLE 7 
// ====================	
cd "$out"

use "INDIGO_data_for_analysis.dta",replace
merge 1:1 trialid using INDIGO_therapist_scores.dta,gen(m_t)	



		preserve
		postfile table7 str150(col1 col2 col3 col4 col5 col6 col7) using "table7", replace
			
		*Table header
			post table7 ("Secondary outcome follow-up") ("IMAGINE") ("IMAGINE") ("NDST") ("NDST") ("Overall") ("Overall")
		
		

	pt_base therapist_MFQ_1 therapist_MFQ_2 therapist_MFQ_3 therapist_MFQ_4, postname(table7) type(cont) over(treat) over_grps(1 0) overall(last) n_analysis(cols) order(group_over)
pt_base riskphq_s1 riskphq_s2 riskphq_s3 riskphq_s4, postname(table7) type(cat) over(treat) over_grps(1 0) overall(last) n_analysis(cols) order(group_over)
pt_base riskphq_s1 riskphq_s2 riskphq_s3 riskphq_s4, postname(table7) type(cont) over(treat) over_grps(1 0) overall(last) n_analysis(cols) order(group_over)		
	*Post close
		postclose table7
	
	*Label table
		putdocx paragraph, halign(left)
		putdocx text ("MFQ 12 scores and PHQ suicide risk at each therapist session"), bold underline font(calibri, 12)  
	
	*Insert table
		putx_tab, filename("table7") table_no(9)	
	restore

	
		
// ====================
// TABLE 8 
// ====================	
cd "$out"

use "INDIGO_data_for_analysis.dta",replace

gen bl_depression_cat = MFQ_TOT_wk0>=29
replace bl_depression_cat =. if missing(MFQ_TOT_wk0) 

label define de_cat 1"MFQ>=29" 0"MFQ<29"
label values bl_depression_cat de_cat


gen bl_insomnia_cat = ISI_TOT_wk0>=15
replace bl_insomnia_cat  =. if missing(ISI_TOT_wk0) 

label define in_cat 1"ISI Score>=15" 0"ISI Score<15"
label values bl_insomnia_cat in_cat


gen bl_cries_cat = CRIES_OVER_TOT_wk0>=17
replace bl_cries_cat =. if missing(CRIES_OVER_TOT_wk0) 

label define cries_cat 1"CRIES score >=17" 0"CRIES score<17"
label values bl_cries_cat cries_cat


preserve
* Postfile
postfile table8 str150(col1 col2 col3 col4) using "table8", replace

* Table header
post table8("Baseline values") ("IMAGINE") ("NDST") ("Overall") 

pt_base bl_depression_cat bl_insomnia_cat bl_cries_cat, postname(table8) type(cat) over(treat) over_grps(1 0) overall(last)

* Post close
postclose table8

* Label table
putdocx paragraph, halign(left)
putdocx text ("Table 8 - exploratory analyses categories"), bold underline font(calibri, 12) 

* Insert table
putx_tab, filename("table8") table_no(8)
restore

// ====================
// TABLE 9 -CEQ
// ====================	
cd "$out"

use "INDIGO_derived_dataset_23022026.dta",replace

* Postfile
postfile table9 str150(col1 col2 col3 col4) using "table9", replace

* Table header
post table9("Score") ("IMAGINE") ("NDST") ("Overall") 

pt_base credibility_score expectancy_score, postname(table9) type(cont) over(treat) over_grps(1 0) overall(last)

* Post close
postclose table9

* Label table
putdocx paragraph, halign(left)
putdocx text ("Table 9 - CEQ"), bold underline font(calibri, 12) 

* Insert table
putx_tab, filename("table9") table_no(9)


// ====================
// TABLE 10 -FEEDBACK QUESTIONNAIRE
// ====================	
cd "$out"

use "INDIGO_derived_dataset_23022026.dta",replace

* Postfile
postfile table10 str150(col1 col2 col3 col4) using "table10", replace

* Table header
post table10("Week 8") ("IMAGINE") ("NDST") ("Overall") 
pt_base feed_agree_1 feed_agree_2 feed_agree_3 feed_agree_9, postname(table10) type(cat) over(treat) over_grps(1 0) overall(last)
pt_base feed_agree_1 feed_agree_2 feed_agree_3 feed_agree_9 therapist_mot_score therapist_rel_score feed_discuss, postname(table10) type(cont) over(treat) over_grps(1 0) overall(last)
pt_base feed_discuss, postname(table10) type(cat) over(treat) over_grps(1 0) overall(last)
* Post close
postclose table10

* Label table
putdocx paragraph, halign(left)
putdocx text ("Table 10 -feedback questionnaire"), bold underline font(calibri, 12) 

* Insert table
putx_tab, filename("table10") table_no(10)


// ====================
// TABLE 11 -HE QUESTIONS
// ====================	
cd "$out"

use "INDIGO_derived_dataset_23022026.dta",replace

* Postfile
postfile table11 str150(col1 col2 col3 col4) using "table11", replace
post table11 ("Variable") ("IMAGINE") ("NDST") ("Overall") 
pt_base eq_5d_5l_explain_wk0 eq_5d_5l_explain_wk8 eq_5d_5l_explain_wk16 eq_5d_5l_explain_wk24, postname(table11) type(cat) over(treat) over_grps(1 0) overall(last)
pt_base reqol_explain_wk0 reqol_explain_wk8 reqol_explain_wk16 reqol_explain_wk24, postname(table11) type(cat) over(treat) over_grps(1 0) overall(last)
pt_base he_pref_wk0 he_pref_wk8 he_pref_wk16 he_pref_wk24, postname(table11) type(cat) over(treat) over_grps(1 0) overall(last)
* Post close
postclose table11

* Label table
putdocx paragraph, halign(left)
putdocx text ("Table 11 -HE acceptability Qs"), bold underline font(calibri, 12) 

* Insert table
putx_tab, filename("table11") table_no(11)


// ====================
// TABLE 12 -Baseline Diagnoses
// ====================	
//reshape 3 diagnosis variables
//list

cd "$out"

use "INDIGO_derived_dataset_23022026.dta",replace
keep trialid diagnosis1_b diagnosis2_b diagnosis3_b diagnosis4_b
rename diagnosis*_b diagnosis*

reshape long diagnosis, i(trialid) j(diagnosis_number)
drop if diagnosis=="0"|diagnosis==""
drop if diagnosis==".a"
drop if diagnosis=="None"|diagnosis=="No"|diagnosis=="no"



// ====================
// TABLE 13 CON MEDS
// ====================	

cd "$out"

use "INDIGO_derived_dataset_23022026.dta",replace
tab1 med*_b

tab1 medication_wk0 medication_wk8 medication_wk16 medication_wk24

keep trialid med1_b med2_b med3_b 
//med_4 empty
rename med*_b med*

reshape long med, i(trialid) j(medication_number)
drop if med=="0"|med==""
drop if med==".a"
drop if med=="None"|med=="No"|med=="no"|med=="o"

cd "$out"

use "INDIGO_derived_dataset_23022026.dta",replace
keep trialid newmeds_wk*
drop newmeds_wk0
//med_4 empty
rename newmeds_wk* newmeds*

reshape long newmeds, i(trialid) j(week)
drop if newmeds=="0"|newmeds==""
drop if newmeds==".a"
drop if newmeds=="None"|newmeds=="No"|newmeds=="no"|newmeds=="o"
// ====================
// TABLE 14 CON THERAPIES
// ====================	
cd "$out"

use "INDIGO_derived_dataset_23022026.dta",replace
tab1 med*_b

tab1 therapy_number_*

tab1 therapy_*_wk*

keep trialid therapy_*_wk*

drop therapy_3_wk8 therapy_4_wk8 therapy_3_wk16 therapy_4_wk0 therapy_4_wk16  therapy_4_wk24  

drop *number*

rename therapy_*_wk0 therapy_wk0_*
rename therapy_*_wk8 therapy_wk8_*
rename therapy_*_wk16 therapy_wk16_*
rename therapy_*_wk24 therapy_wk24_*


reshape long therapy_wk0_ therapy_wk8_ therapy_wk16_ therapy_wk24_, i(trialid) j(therapy_number)
rename therapy_wk*_ therapy*
reshape long therapy, i(therapy_number trialid) j(week)

drop if therapy=="0"|therapy==""
drop if therapy==".a"|therapy==".b"
drop if therapy=="None"|therapy=="No"|therapy=="no"|therapy=="o"

order trialid week therapy_number therapy
cd "$tabs"
putdocx save "INDIGO_Descriptives_Report_$S_DATE.docx", replace


*************************************************
*LAST LINE
*************************************************

display "$S_TIME $S_DATE"

