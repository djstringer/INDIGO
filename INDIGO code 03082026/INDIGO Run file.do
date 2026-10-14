////////////////////////////////////////////////////////////////////////////////
/* //=========================================================================//
	INDIGO Analysis run file
	Author: Dominic Stringer
	Started: 13/01/2026
	Date of extract: 17/12/2025
	Stata 19
*/ //=========================================================================//
////////////////////////////////////////////////////////////////////////////////


global wd "C:\Users\domjs\King's College London\BHI-Trials - INDIGO\Analysis\final"
cd "$wd\code"

do "INDIGO_0_Globals.do"

* Log code 
global dateout = subinstr(c(current_date), " ", "", .)

log using "$out\logs\Indigo_0_Globals_${dateout}.log", replace

cd "$code"
do "INDIGO_1_Read.do"
cd "$code"
do "INDIGO_2_Scoring.do"
cd "$code"
do "INDIGO_3_Reshape.do"


//Analysis
cd "$code"
do "INDIGO_6_Analysis.do"


//Descriptives output
cd "$code"
do "INDIGO_7_Descriptives.do"


* Translate and close log
translate "$logs\INDIGO_6_Analysis$dateout.smcl" "$logs\INDIGO_6_Analysis$dateout.pdf", replace
translate "$logs\INDIGO_7_Descriptives$dateout.smcl" "$logs\INDIGO_7_Descriptives$dateout.pdf", replace
capture log close


* #### LAST LINE ####
display "$S_TIME  $S_DATE"
