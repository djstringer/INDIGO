////////////////////////////////////////////////////////////////////////////////
/* //=========================================================================//
	INDIGO Analysis
	Author: D Stringer
	Started: 13/01/26
	Date of extract: 17/12/2025
	Stata 19
*/ //=========================================================================//
////////////////////////////////////////////////////////////////////////////////


* Initialise log file
capture log close
log using "$logs\INDIGO_6_Analysis$dateout", replace



//Sort out secondary outcome labelling
set graphics off

//Function to output adjusted results
capture program drop frame_output_results
program define frame_output_results
args mtname name
frame change results
clear
svmat r(`mtname'), names(col)
gen name = "`name'"
gen time = "Week 8"
replace time = "Week 16" if _n==2
replace time = "Week 24" if _n==3
rename c1 b
rename c2 se
rename c3 p
rename c4 lci
rename c5 uci
rename c6 cd
rename c7 cdlci
rename c8 cduci
order name time b se p lci uci cd cdlci cduci
cd "$tabs"
append using results_output.dta
save "results_output",replace
frame change default
end

capture program drop run_mixed
program define run_mixed,rclass
    version 18
    args outcome

    *---------------------------------------
    * Reshape to long
    *---------------------------------------
    rename `outcome'_wk0 bl_`outcome'
	rename `outcome'_wk8 `outcome'8
	rename `outcome'_wk16 `outcome'16
	rename `outcome'_wk24 `outcome'24

    reshape long `outcome', i(trialid) j(week)

    *---------------------------------------
    * Get baseline SD
    *---------------------------------------
    local bl = "bl_`outcome'"
    quietly summarize `bl'
    local sd = r(sd)

    *---------------------------------------
    * Mixed model
    *---------------------------------------
    mixed `outcome' i.treat i.week i.week#i.treat `bl' i.site ///
        || therapistcode: || trialid:

    *---------------------------------------
    * ICC
    *---------------------------------------
    estat icc

    *---------------------------------------
    * diagnostic plots
    *---------------------------------------
    
//needs amending to check level 1 and level 2 residuals
		predict res_`outcome',res
		predict fitted_`outcome',fitted

		cd "$tab"
		qnorm res_`outcome', saving("`outcome'_res_qnorm.gph",replace) ///
		title("`outcome' qnorm check of residuals")   //normality of residuals
		graph export `outcome'_res_qnorm.png, replace

	stripplot res_`outcome', over(week) ///
    yline(0) ///
    vertical ///
    jitter(4) ///
    title("Residuals by week (strip plot)") ///
    ytitle("Residuals") ///
    		saving("`outcome'_res_over_time.gph",replace)
    		graph export `outcome'_resovertime.png, replace


putdocx paragraph
putdocx text ("`outcome' residual plots")
putdocx paragraph
putdocx image `outcome'_res_qnorm.png
putdocx paragraph
putdocx image `outcome'_resovertime.png

    *---------------------------------------
    * Treatment effects
    *---------------------------------------
    lincom 1.treat + 1.treat#8.week
    scalar `outcome't8_est = r(estimate)
    scalar `outcome't8_est_cd = r(estimate)/`sd'
    scalar `outcome't8_se = r(se)
    scalar `outcome't8_p = r(p)
    scalar `outcome't8_lci = r(lb)
    scalar `outcome't8_uci = r(ub)
    scalar `outcome't8_lci_cd = r(lb)/`sd'
    scalar `outcome't8_uci_cd = r(ub)/`sd'
    lincom 1.treat + 1.treat#16.week
    scalar `outcome't16_est = r(estimate)
    scalar `outcome't16_est_cd = r(estimate)/`sd'
    scalar `outcome't16_se = r(se)
    scalar `outcome't16_p = r(p)
    scalar `outcome't16_lci = r(lb)
    scalar `outcome't16_uci = r(ub)
    scalar `outcome't16_lci_cd = r(lb)/`sd'
    scalar `outcome't16_uci_cd = r(ub)/`sd'
    lincom 1.treat + 1.treat#24.week
    scalar `outcome't24_est = r(estimate)
    scalar `outcome't24_est_cd = r(estimate)/`sd'
    scalar `outcome't24_se = r(se)
    scalar `outcome't24_p = r(p)
    scalar `outcome't24_lci = r(lb)
    scalar `outcome't24_uci = r(ub)
    scalar `outcome't24_lci_cd = r(lb)/`sd'
    scalar `outcome't24_uci_cd = r(ub)/`sd'

matrix  `outcome'_results = J(3, 8, .)

matrix `outcome'_results[1,1] =  `outcome't8_est
matrix `outcome'_results[1,2] = `outcome't8_se
matrix `outcome'_results[1,3] = `outcome't8_p
matrix `outcome'_results[1,4] = `outcome't8_lci
matrix `outcome'_results[1,5] = `outcome't8_uci
matrix `outcome'_results[1,6] = `outcome't8_est_cd
matrix `outcome'_results[1,7] = `outcome't8_lci_cd
matrix `outcome'_results[1,8] = `outcome't8_uci_cd
matrix `outcome'_results[2,1] = `outcome't16_est
matrix `outcome'_results[2,2] = `outcome't16_se
matrix `outcome'_results[2,3] = `outcome't16_p
matrix `outcome'_results[2,4] = `outcome't16_lci
matrix `outcome'_results[2,5] = `outcome't16_uci
matrix `outcome'_results[2,6] = `outcome't16_est_cd
matrix `outcome'_results[2,7] = `outcome't16_lci_cd
matrix `outcome'_results[2,8] = `outcome't16_uci_cd
matrix `outcome'_results[3,1] = `outcome't24_est
matrix `outcome'_results[3,2] = `outcome't24_se
matrix `outcome'_results[3,3] = `outcome't24_p
matrix `outcome'_results[3,4] = `outcome't24_lci
matrix `outcome'_results[3,5] = `outcome't24_uci
matrix `outcome'_results[3,6] = `outcome't24_est_cd
matrix `outcome'_results[3,7] = `outcome't24_lci_cd
matrix `outcome'_results[3,8] = `outcome't24_uci_cd
return matrix `outcome' = `outcome'_results
end


capture program drop run_mixed_bl_miss
program define run_mixed_bl_miss,rclass
    version 18
    args outcome

    *---------------------------------------
    * Reshape to long
    *---------------------------------------
    rename `outcome'_wk0 bl_`outcome'
	rename `outcome'_wk8 `outcome'8
	rename `outcome'_wk16 `outcome'16
	rename `outcome'_wk24 `outcome'24
	gen bl_miss_`outcome' = missing(bl_`outcome')
    reshape long `outcome', i(trialid) j(week)
	local bl = "bl_`outcome'"
    quietly summarize `bl'
    local sd = r(sd)
	local mean = r(mean)
	replace bl_`outcome' = `mean' if missing(bl_`outcome')
    *---------------------------------------
    * Get baseline SD
    *---------------------------------------
  
	
    *---------------------------------------
    * Mixed model
    *---------------------------------------
    mixed `outcome' i.treat i.week i.week#i.treat `bl' i.bl_miss_`outcome' i.site ///
        || therapistcode: || trialid:

    *---------------------------------------
    * ICC
    *---------------------------------------
    estat icc

    *---------------------------------------
    * diagnostic plots
    *---------------------------------------
    
//needs amending to check level 1 and level 2 residuals
		predict res_`outcome',res
		predict fitted_`outcome',fitted

		cd "$tab"
		qnorm res_`outcome', saving("`outcome'_res_qnorm.gph",replace) ///
		title("`outcome' qnorm check of residuals")   //normality of residuals
		graph export `outcome'_res_qnorm.png, replace

	stripplot res_`outcome', over(week) ///
    yline(0) ///
    vertical ///
    jitter(4) ///
    title("Residuals by week (strip plot)") ///
    ytitle("Residuals") ///
    		saving("`outcome'_res_over_time.gph",replace)
    		graph export `outcome'_resovertime.png, replace


putdocx paragraph
putdocx text ("`outcome' residual plots")
putdocx paragraph
putdocx image `outcome'_res_qnorm.png
putdocx paragraph
putdocx image `outcome'_resovertime.png

    *---------------------------------------
    * Treatment effects
    *---------------------------------------
    lincom 1.treat + 1.treat#8.week
    scalar `outcome't8_est = r(estimate)
    scalar `outcome't8_est_cd = r(estimate)/`sd'
    scalar `outcome't8_se = r(se)
    scalar `outcome't8_p = r(p)
    scalar `outcome't8_lci = r(lb)
    scalar `outcome't8_uci = r(ub)
    scalar `outcome't8_lci_cd = r(lb)/`sd'
    scalar `outcome't8_uci_cd = r(ub)/`sd'
    lincom 1.treat + 1.treat#16.week
    scalar `outcome't16_est = r(estimate)
    scalar `outcome't16_est_cd = r(estimate)/`sd'
    scalar `outcome't16_se = r(se)
    scalar `outcome't16_p = r(p)
    scalar `outcome't16_lci = r(lb)
    scalar `outcome't16_uci = r(ub)
    scalar `outcome't16_lci_cd = r(lb)/`sd'
    scalar `outcome't16_uci_cd = r(ub)/`sd'
    lincom 1.treat + 1.treat#24.week
    scalar `outcome't24_est = r(estimate)
    scalar `outcome't24_est_cd = r(estimate)/`sd'
    scalar `outcome't24_se = r(se)
    scalar `outcome't24_p = r(p)
    scalar `outcome't24_lci = r(lb)
    scalar `outcome't24_uci = r(ub)
    scalar `outcome't24_lci_cd = r(lb)/`sd'
    scalar `outcome't24_uci_cd = r(ub)/`sd'

matrix  `outcome'_results = J(3, 8, .)

matrix `outcome'_results[1,1] =  `outcome't8_est
matrix `outcome'_results[1,2] = `outcome't8_se
matrix `outcome'_results[1,3] = `outcome't8_p
matrix `outcome'_results[1,4] = `outcome't8_lci
matrix `outcome'_results[1,5] = `outcome't8_uci
matrix `outcome'_results[1,6] = `outcome't8_est_cd
matrix `outcome'_results[1,7] = `outcome't8_lci_cd
matrix `outcome'_results[1,8] = `outcome't8_uci_cd
matrix `outcome'_results[2,1] = `outcome't16_est
matrix `outcome'_results[2,2] = `outcome't16_se
matrix `outcome'_results[2,3] = `outcome't16_p
matrix `outcome'_results[2,4] = `outcome't16_lci
matrix `outcome'_results[2,5] = `outcome't16_uci
matrix `outcome'_results[2,6] = `outcome't16_est_cd
matrix `outcome'_results[2,7] = `outcome't16_lci_cd
matrix `outcome'_results[2,8] = `outcome't16_uci_cd
matrix `outcome'_results[3,1] = `outcome't24_est
matrix `outcome'_results[3,2] = `outcome't24_se
matrix `outcome'_results[3,3] = `outcome't24_p
matrix `outcome'_results[3,4] = `outcome't24_lci
matrix `outcome'_results[3,5] = `outcome't24_uci
matrix `outcome'_results[3,6] = `outcome't24_est_cd
matrix `outcome'_results[3,7] = `outcome't24_lci_cd
matrix `outcome'_results[3,8] = `outcome't24_uci_cd
return matrix `outcome' = `outcome'_results
end



cd "$tabs"
putdocx clear
putdocx begin

* Create new frames and datasets to store results
frame change default
capture frame drop results
frame create results str30(name time) double(b se p lci uci)  // Modify based on matrix dimensions
frame change results
cd "$tabs"
save "results_output",replace

//Primary
cd "$out"

use "INDIGO_derived_dataset_23022026_wide.dta",replace
encode(Therapist), gen(therapistcode)
rename rand_date ran_date
save "INDIGO_data_for_analysis.dta",replace


preserve

rename MFQ_TOT_wk0 bl_MFQ 
rename MFQ_TOT_wk8 MFQ_TOT8
rename MFQ_TOT_wk16 MFQ_TOT16
rename MFQ_TOT_wk24 MFQ_TOT24

keep bl_MFQ MFQ_TOT8 MFQ_TOT16 MFQ_TOT24 initials ageatconsent randomised site ran_date week trialid treat Therapist therapistcode sex ISI_TOT_wk0 CRIES_OVER_TOT_wk0 

mvpatterns bl_MFQ MFQ_TOT8 MFQ_TOT16 MFQ_TOT24

bysort treat: sum bl_MFQ MFQ_TOT8 MFQ_TOT16 MFQ_TOT24


collapse (mean) mean0=bl_MFQ mean8=MFQ_TOT8 ///
mean16=MFQ_TOT16  mean24=MFQ_TOT24 /// 
(semean) se0=bl_MFQ se8=MFQ_TOT8 ///
se16=MFQ_TOT16 se24=MFQ_TOT24  ///
, by(treat)

gen id = _n

reshape long mean se, j(week) i(id)

gen lci = mean - 1.96*se
gen uci = mean + 1.96*se


twoway (rcap lci uci week if treat==0 , color(blue%60) ) ///
       (connected mean week if treat==0, lwidth(medium) lcolor(blue) mcolor(blue)) ///
       (rcap lci uci week if treat==1, color(red%60) jitter(5)) ///
       (connected mean week if treat==1, lwidth(medium) lcolor(red) mcolor(red) msymbol(D)) ///
       , legend(order(2 "NDS" 4 "IMAGINE")) ///
       ytitle("Mean MFQ total score") ///
       xlabel(0(8)24) ///
       ylabel(20(2)36) ///
       caption("Graph showing raw means by trial treat over time with 95% confidence intervals.",size(3)) ///
       scheme(s1color)
cd "$tabs"
graph export MFQ_raw_means_over_time.png, replace
restore


run_mixed MFQ_TOT
cd "$tabs"
frame_output_results "MFQ_TOT" "MFQ_TOT"

cd "$out"

use "INDIGO_derived_dataset_23022026_wide.dta",replace
encode(Therapist), gen(therapistcode)
rename rand_date ran_date
save "INDIGO_data_for_analysis.dta",replace

preserve
run_mixed MFQ_TOT
predict double xbu,xb
bysort treat week: sum xbu

* Step 1: Collapse data to mean and CI by treat-week
collapse (mean) mean_xbu = xbu (semean) se_xbu = xbu (count) n = xbu, by(treat week)

//bl NDST 30.8
//bl IMAGINE 31.9
set obs 8
replace week = 0 in 7
replace treat = 0 in 7

replace week = 0 in 8
replace treat = 1 in 8
replace mean_xbu = 30.8 in 7
replace mean_xbu = 31.9 in 8

gsort week

* Step 2: Compute standard error and 95% CI

gen lci  = mean_xbu - 1.96*se_xbu
gen uci = mean_xbu + 1.96*se_xbu

* Step 3: Plot with CIs using twoway
twoway (rcap lci uci week if treat==0 , color(blue%60) ) ///
       (connected mean week if treat==0, lwidth(medium) lcolor(blue) mcolor(blue)) ///
       (rcap lci uci week if treat==1, color(red%60)) ///
       (connected mean week if treat==1, lwidth(medium) lcolor(red) mcolor(red) msymbol(D)) ///
       , legend(order(2 " NDS" 4 "IMAGINE")) ///
       ytitle("Mean MFQ total score") ///
       xlabel(0(8)24) ///
       ylabel(18(2)32) ///
       caption("Graph showing predicted means by trial treat over time with 95% confidence intervals.",size(3)) ///
       scheme(s1color)
cd "$tabs"
graph export MFQ_estimated_means_over_time.png, replace	   
restore



//Sensitvities etc
/*Method for handling non-compliance (per protocol analysis)
The Per Protocol Population (PPP) will be assessed and excludes participants defined as protocol violators (those that
fail fidelity). The PPP will analyse the primary outcome using the same analysis described in 3.2.1 above and will
exclude participants who have not adhered to the intervention, i.e. participants who have not completed 3 or more
sessions of the programme will be excluded from the analysis
*/

//Identify sessions
cd "$out"

use "INDIGO_data_for_analysis.dta",replace
merge m:1 trialid using INDIGO_therapist_attend.dta, keepusing(trialid number_of_sessions_attended adhered_binary)

drop if missing(trialid)



merge 1:1 trialid using INDIGO_prot_status.dta, keepusing(trialid therapy_not_protocol) gen(m_prot)



//keep adherers per sessions
keep if adhered_binary==1
//drop those adherers who otherwise did not follow intervention protocol
drop if therapy_not_protocol==1
preserve
run_mixed MFQ_TOT
cd "$tabs"
frame_output_results "MFQ_TOT" "MFQ_TOT_adhere"
restore

preserve
run_mixed MFQ_TOT
predict double xbu,xb
bysort treat week: sum xbu

* Step 1: Collapse data to mean and CI by treat-week
collapse (mean) mean_xbu = xbu (semean) se_xbu = xbu (count) n = xbu, by(treat week)

//bl NDST 30.8
//bl IMAGINE 31.9
set obs 8
replace week = 0 in 7
replace treat = 0 in 7

replace week = 0 in 8
replace treat = 1 in 8
replace mean_xbu = 30.8 in 7
replace mean_xbu = 31.9 in 8

gsort week

* Step 2: Compute standard error and 95% CI

gen lci  = mean_xbu - 1.96*se_xbu
gen uci = mean_xbu + 1.96*se_xbu

* Step 3: Plot with CIs using twoway
twoway (rcap lci uci week if treat==0 , color(blue%60) ) ///
       (connected mean week if treat==0, lwidth(medium) lcolor(blue) mcolor(blue)) ///
       (rcap lci uci week if treat==1, color(red%60)) ///
       (connected mean week if treat==1, lwidth(medium) lcolor(red) mcolor(red) msymbol(D)) ///
       , legend(order(2 " NDS" 4 "IMAGINE")) ///
       ytitle("Mean MFQ total score") ///
       xlabel(0(8)24) ///
       ylabel(18(2)32) ///
       caption("Graph showing predicted means by trial treat over time with 95% confidence intervals.",size(3)) ///
       scheme(s1color)
cd "$tabs"
graph export MFQ_estimated_means_over_time_PP.png, replace	   
restore

//CACE exploratory
cd "$out"

use "INDIGO_data_for_analysis.dta",replace
merge m:1 trialid using INDIGO_therapist_attend.dta, keepusing(trialid number_of_sessions_attended adhered_binary)

drop if missing(trialid)

merge 1:1 trialid using INDIGO_prot_status.dta, keepusing(trialid therapy_not_protocol) gen(m_prot)

drop if missing(treat)
gen complier = (adhered_binary==1 & therapy_not_protocol!=1)
tab complier treat

sum  MFQ_TOT_wk0
local sd = r(sd)
replace complier=0 if treat==0
ivregress 2sls MFQ_TOT_wk8 MFQ_TOT_wk0 i.site (i.complier=i.treat)
lincom 1.complier
scalar MFQ_CACEt8_est = r(estimate)
scalar MFQ_CACEt8_est_cd = r(estimate)/`sd'
scalar MFQ_CACEt8_se = r(se)
scalar MFQ_CACEt8_p = r(p)
scalar MFQ_CACEt8_lci = r(lb)
scalar MFQ_CACEt8_uci = r(ub)
scalar MFQ_CACEt8_lci_cd = r(lb)/`sd'
scalar MFQ_CACEt8_uci_cd = r(ub)/`sd'
ivregress 2sls MFQ_TOT_wk16 MFQ_TOT_wk0 i.site (i.complier=i.treat)
    lincom 1.complier
	scalar MFQ_CACEt16_est = r(estimate)
    scalar MFQ_CACEt16_est_cd = r(estimate)/`sd'
    scalar MFQ_CACEt16_se = r(se)
    scalar MFQ_CACEt16_p = r(p)
    scalar MFQ_CACEt16_lci = r(lb)
    scalar MFQ_CACEt16_uci = r(ub)
    scalar MFQ_CACEt16_lci_cd = r(lb)/`sd'
    scalar MFQ_CACEt16_uci_cd = r(ub)/`sd'
ivregress 2sls MFQ_TOT_wk24 MFQ_TOT_wk0 i.site (i.complier=i.treat)
    lincom 1.complier
    scalar MFQ_CACEt24_est = r(estimate)
    scalar MFQ_CACEt24_est_cd = r(estimate)/`sd'
    scalar MFQ_CACEt24_se = r(se)
    scalar MFQ_CACEt24_p = r(p)
    scalar MFQ_CACEt24_lci = r(lb)
    scalar MFQ_CACEt24_uci = r(ub)
    scalar MFQ_CACEt24_lci_cd = r(lb)/`sd'
    scalar MFQ_CACEt24_uci_cd = r(ub)/`sd'


matrix  MFQ_CACE_results = J(3, 8, .)

matrix MFQ_CACE_results[1,1] =  MFQ_CACEt8_est
matrix MFQ_CACE_results[1,2] = MFQ_CACEt8_se
matrix MFQ_CACE_results[1,3] = MFQ_CACEt8_p
matrix MFQ_CACE_results[1,4] = MFQ_CACEt8_lci
matrix MFQ_CACE_results[1,5] = MFQ_CACEt8_uci
matrix MFQ_CACE_results[1,6] = MFQ_CACEt8_est_cd
matrix MFQ_CACE_results[1,7] = MFQ_CACEt8_lci_cd
matrix MFQ_CACE_results[1,8] = MFQ_CACEt8_uci_cd
matrix MFQ_CACE_results[2,1] = MFQ_CACEt16_est
matrix MFQ_CACE_results[2,2] = MFQ_CACEt16_se
matrix MFQ_CACE_results[2,3] = MFQ_CACEt16_p
matrix MFQ_CACE_results[2,4] = MFQ_CACEt16_lci
matrix MFQ_CACE_results[2,5] = MFQ_CACEt16_uci
matrix MFQ_CACE_results[2,6] = MFQ_CACEt16_est_cd
matrix MFQ_CACE_results[2,7] = MFQ_CACEt16_lci_cd
matrix MFQ_CACE_results[2,8] = MFQ_CACEt16_uci_cd
matrix MFQ_CACE_results[3,1] = MFQ_CACEt24_est
matrix MFQ_CACE_results[3,2] = MFQ_CACEt24_se
matrix MFQ_CACE_results[3,3] = MFQ_CACEt24_p
matrix MFQ_CACE_results[3,4] = MFQ_CACEt24_lci
matrix MFQ_CACE_results[3,5] = MFQ_CACEt24_uci
matrix MFQ_CACE_results[3,6] = MFQ_CACEt24_est_cd
matrix MFQ_CACE_results[3,7] = MFQ_CACEt24_lci_cd
matrix MFQ_CACE_results[3,8] = MFQ_CACEt24_uci_cd

frame change results
clear
svmat MFQ_CACE_results, names(col)
gen name = "MFQ_CACE"
gen time = "Week 8"
replace time = "Week 16" if _n==2
replace time = "Week 24" if _n==3
rename c1 b
rename c2 se
rename c3 p
rename c4 lci
rename c5 uci
rename c6 cd
rename c7 cdlci
rename c8 cduci
order name time b se p lci uci cd cdlci cduci
cd "$tabs"
append using results_output.dta
save "results_output",replace
frame change default


/*Sensitivity analyses
A sensitivity analysis will be carried out on the primary outcome to assess the effect of treatment when assessment
timepoints fall outside of the +/- 4-week visit window. We will create an indicator variable: 1=within +/- 4-week visit
window, 0=not within +/- 4-week window, and then re-run the primary analysis model (for the MFQ) for only those
with the indicator variable=1.
*/

preserve
// Exclude outside visit
replace MFQ_TOT_wk8=. if visit_win_8==0
replace MFQ_TOT_wk16=. if visit_win_16==0
replace MFQ_TOT_wk24=. if visit_win_24==0

run_mixed MFQ_TOT
cd "$tabs"
frame_output_results "MFQ_TOT" "MFQ_TOT_visit"
restore


//ICC for therapist
rename MFQ_TOT_wk0 bl_MFQ 
rename MFQ_TOT_wk8 MFQ_TOT8
rename MFQ_TOT_wk16 MFQ_TOT16
rename MFQ_TOT_wk24 MFQ_TOT24

reshape long MFQ_TOT, i(trialid) j(week)
mixed MFQ_TOT i.treat bl_MFQ ///
||therapistcode: if week==8
estat icc

//0.006

//ICC for school

mixed MFQ_TOT i.treat bl_MFQ ///
||site: if week==8
estat icc

/*
Planned exploratory analyses
The study is not formally powered for moderation analyses or subgroup analysis, but we will investigate in an
exploratory fashion whether 8-week depression (as measured by the MFQ) intervention effects differ by the below
variables:
1. Sex at birth, 2 groups: male; female.
*/

preserve

sum bl_MFQ
local sd = r(sd)


mixed MFQ_TOT i.treat i.week bl_MFQ i.site i.sex##i.week##i.treat ///
||therapistcode:||trialid:

estat icc


//test over interaction
margins r.sex, dydx(treat) at(week=8) contrast

//lincom 1.treat + 1.treat#1.sex + 1.treat#8.week + 1.treat#8.week#1.sex
//lincom 1.treat + 1.treat#2.sex + 1.treat#8.week + 1.treat#8.week#2.sex
restore


/*
2. Levels of baseline depression, 2 groups based on a higher baseline MFQ cut-off score of 29 (Daviss et al.,
2006; Eg et al., 2018): score of 20 to 28; score of 29 or above.
*/

/// MFQ depression
gen bl_depression_cat = bl_MFQ>=29
replace bl_depression_cat =. if missing(bl_MFQ) 

tab bl_depression_cat

preserve

sum bl_MFQ
local sd = r(sd)


mixed MFQ_TOT i.treat i.week bl_MFQ i.site i.bl_depression_cat##i.week##i.treat ///
||therapistcode:||trialid:

estat icc


//test over interaction
margins r.bl_depression_cat, dydx(treat) at(week=8) contrast

//lincom 1.treat + 1.treat#1.sex + 1.treat#8.week + 1.treat#8.week#1.sex
//lincom 1.treat + 1.treat#2.sex + 1.treat#8.week + 1.treat#8.week#2.sex
restore

/*
3. Insomnia severity, 2 groups based on an ISI cut-off score of 15 at baseline (Bastien et al., 2001): score of 14
or below; score of 15 and above relating to moderate and severe difficulties.
*/
gen bl_insomnia_cat = ISI_TOT_wk0>=15
replace bl_insomnia_cat  =. if missing(ISI_TOT_wk0) 

preserve

sum bl_MFQ
local sd = r(sd)


mixed MFQ_TOT i.treat i.week bl_MFQ i.site i.bl_insomnia_cat##i.week##i.treat ///
||therapistcode:||trialid:

estat icc


//test over interaction
margins r.bl_insomnia_cat, dydx(treat) at(week=8) contrast

//lincom 1.treat + 1.treat#1.sex + 1.treat#8.week + 1.treat#8.week#1.sex
//lincom 1.treat + 1.treat#2.sex + 1.treat#8.week + 1.treat#8.week#2.sex
restore
/*
4. Levels of baseline CRIES score, 2 groups based on a cut-off score of 17 (Perrin et al., 2005): score of 16 and
below; score of 17 and above.
*/

gen bl_cries_cat = CRIES_OVER_TOT_wk0>=17
replace bl_cries_cat =. if missing(CRIES_OVER_TOT_wk0) 

preserve

sum bl_MFQ
local sd = r(sd)


mixed MFQ_TOT i.treat i.week bl_MFQ i.site i.bl_cries_cat##i.week##i.treat ///
||therapistcode:||trialid:

estat icc


//test over interaction
margins r.bl_cries_cat, dydx(treat) at(week=8) contrast

//lincom 1.treat + 1.treat#1.sex + 1.treat#8.week + 1.treat#8.week#1.sex
//lincom 1.treat + 1.treat#2.sex + 1.treat#8.week + 1.treat#8.week#2.sex
restore

drop if missing(treat)

//MNAR exploratory
xi: rctmiss, sens(i.treat) pmmdelta(-8/8): reg MFQ_TOT i.treat bl_MFQ i.site if week==8

cd "$tabs"
graph export mnar_week8.png, replace

xi: rctmiss, sens(i.treat) pmmdelta(-8/8): reg MFQ_TOT i.treat bl_MFQ i.site if week==16
xi: rctmiss, sens(i.treat) pmmdelta(-8/8): reg MFQ_TOT i.treat bl_MFQ i.site if week==24
*/



//Secondary
/*
• Anxiety (RCADS) at 8, 16 and 24 weeks after randomisation.
*/
cd "$out"

use "INDIGO_data_for_analysis.dta",replace

mvpatterns RCADS_TOT*

run_mixed RCADS_TOT
cd "$tabs"
frame_output_results "RCADS_TOT" "RCADS_TOT"

/*
• Self-worth (SPPC) at 8, 16 and 24 weeks after randomisation.INDIGO SAP Version 1 Page 12 of 28
*/

cd "$out"

use "INDIGO_data_for_analysis.dta",replace

mvpatterns SPPC_TOT*

run_mixed SPPC_TOT
cd "$tabs"
frame_output_results "SPPC_TOT" "SPPC_TOT"

//• Sleep difficulties (ISI) at 8, 16 and 24 weeks after randomisation.
cd "$out"

use "INDIGO_data_for_analysis.dta",replace

mvpatterns ISI_TOT*

run_mixed_bl_miss ISI_TOT
cd "$tabs"
frame_output_results "ISI_TOT" "ISI_TOT"

// Activity levels, rumination, school and social impairment (BADS – 25 item) at 8, 16 and 24 weeks after
//randomisation.
cd "$out"

use "INDIGO_data_for_analysis.dta",replace

mvpatterns BADS_TOT*

run_mixed_bl_miss BADS_TOT

frame_output_results "BADS_TOT" "BADS_TOT"
cd "$out"

use "INDIGO_data_for_analysis.dta",replace

run_mixed_bl_miss BADS_AC

cd "$tabs"
frame_output_results "BADS_AC" "BADS_AC"

cd "$out"

use "INDIGO_data_for_analysis.dta",replace

run_mixed_bl_miss BADS_AR

cd "$tabs"
frame_output_results "BADS_AR" "BADS_AR"
cd "$out"

use "INDIGO_data_for_analysis.dta",replace

run_mixed_bl_miss BADS_WS

cd "$tabs"
frame_output_results "BADS_WS" "BADS_WS"
cd "$out"

use "INDIGO_data_for_analysis.dta",replace

run_mixed_bl_miss BADS_SI

cd "$tabs"
frame_output_results "BADS_SI" "BADS_SI"
//• Distress/post-traumatic stress symptoms to a negative event (CRIES-8) at 8, 16 and 24 weeks after
//randomisation.
cd "$out"

use "INDIGO_data_for_analysis.dta",replace

mvpatterns CRIES_INT_TOT*

run_mixed_bl_miss CRIES_INT_TOT
cd "$tabs"
frame_output_results "CRIES_INT_TOT" "CRIES_INT_TOT"

cd "$out"

use "INDIGO_data_for_analysis.dta",replace

mvpatterns CRIES_AVO_TOT*

run_mixed_bl_miss CRIES_AVO_TOT
cd "$tabs"
frame_output_results "CRIES_AVO_TOT" "CRIES_AVO_TOT"

cd "$out"

use "INDIGO_data_for_analysis.dta",replace

mvpatterns CRIES_OVER_TOT*

run_mixed_bl_miss CRIES_OVER_TOT
cd "$tabs"
frame_output_results "CRIES_OVER_TOT" "CRIES_OVER_TOT"


//AMT - specific memories
cd "$out"

use "INDIGO_data_for_analysis.dta",replace
mvpatterns AMT_specific_TOT*

preserve
    rename AMT_specific_TOT_wk0 bl_AMT_specific_TOT


nbreg AMT_specific_TOT_wk8 i.treat bl_AMT_specific_TOT i.site,irr
nbreg AMT_specific_TOT_wk16 i.treat bl_AMT_specific_TOT i.site,irr
nbreg AMT_specific_TOT_wk24 i.treat bl_AMT_specific_TOT i.site,irr
//reshape long AMT_specific_TOT, i(trialid) j(week)
//THIS MODEL DIDNT CONVERGE
//menbreg AMT_specific_TOT i.treat i.week i.week#i.treat bl_AMT_specific_TOT i.site ///
    //    || trialid:

restore
*/
run_mixed AMT_specific_TOT 
cd "$tabs"
frame_output_results "AMT_specific_TOT" "AMT_specific_TOT"


//• Mental Imagery (AMI-Y; positive and negative subscales) at 8, 16 and 24 weeks after randomisation.
cd "$out"

use "INDIGO_data_for_analysis.dta",replace

mvpatterns AMI_n_TOT*

run_mixed AMI_n_TOT
cd "$tabs"
frame_output_results "AMI_n_TOT" "AMI_n_TOT"


cd "$out"

use "INDIGO_data_for_analysis.dta",replace

mvpatterns AMI_p_TOT*

run_mixed AMI_p_TOT
cd "$tabs"
frame_output_results "AMI_p_TOT" "AMI_p_TOT"

//• Future imagery vividness (PIT; positive and negative subscales) at 8, 16 and 24 weeks after randomisation.
cd "$out"

use "INDIGO_data_for_analysis.dta",replace

mvpatterns PIT_POS_TOT*

run_mixed_bl_miss PIT_POS_TOT
cd "$tabs"
frame_output_results "PIT_POS_TOT" "PIT_POS_TOT"

cd "$out"

use "INDIGO_data_for_analysis.dta",replace

mvpatterns PIT_NEG_TOT*

run_mixed_bl_miss PIT_NEG_TOT
cd "$tabs"
frame_output_results "PIT_NEG_TOT" "PIT_NEG_TOT"

//• Memory specificity (AMT) at 8, 16 and 24 weeks after randomisation.

//TO QUERY SCORING

//• Self-Compassion (SCS) at 8, 16 and 24 weeks after randomisation
*/
cd "$out"

use "INDIGO_data_for_analysis.dta",replace

mvpatterns SCS_TOT*

run_mixed_bl_miss SCS_TOT
cd "$tabs"
frame_output_results "SCS_TOT" "SCS_TOT"

//Close off putdocx for diagnostic plots
cd "$tab"
putdocx save INDIGO_diag_plots_v01.docx, replace


//Forest plot 
* Generate an identifier for sorting and referencing
use results_output,replace

gen r=1 if inlist(name,"BADS_TOT","BADS_AC","BADS_AR","BADS_WS","BADS_SI","SPPC_TOT")
replace r=1 if inlist(name,"AMI_p_TOT","PIT_POS_TOT","AMT_specific_TOT","SCS_TOT")
gen s=1 if inlist(name,"RCADS_TOT","SPPC_TOT","ISI_TOT","BADS_WS","BADS_SI","CRIES_AVO_TOT","CRIES_INT_TOT")
gen m=1 if inlist(name,"PIT_NEG_TOT","PIT_POS_TOT","AMI_p_TOT","AMI_n_TOT","AMT_specific_TOT","SCS_TOT","BADS_AC","BADS_AR")
replace name = "Self-Compassion Scale Total" if name == "SCS_TOT"
replace name = "FIT Negative score" if name == "PIT_NEG_TOT"
replace name = "FIT Positive score" if name == "PIT_POS_TOT"
replace name = "AMI-Y Positive Imagery Score" if name == "AMI_p_TOT"
replace name = "AMI-Y Negative Imagery Score " if name == "AMI_n_TOT"
replace name = "AMT total specific memories" if name == "AMT_specific_TOT"
replace name = "CRIES Total" if name == "CRIES_OVER_TOT"
replace name = "CRIES Avoidance score" if name == "CRIES_AVO_TOT"
replace name = "CRIES Intrusion score" if name == "CRIES_INT_TOT"
replace name = "BADS Total" if name == "BADS_TOT"
replace name = "BADS Activity subscale" if name == "BADS_AC"
replace name = "BADS Rumination subscale" if name == "BADS_AR"
replace name = "BADS School Impairment subscale" if name == "BADS_WS"
replace name = "BADS Social impairment subscale" if name == "BADS_SI"
replace name = "Insomnia Severity Index Total" if name == "ISI_TOT"
replace name = " Self-Perception Scale self worth subscale" if name == "SPPC_TOT"
replace name = "RCADS Anxiety Total" if name == "RCADS_TOT"
replace name = "MFQ Total" if name == "MFQ_TOT"



save results_output_labelled,replace
use results_output_labelled,replace
//replace id = _n  
keep if time=="Week 8"

//gsort -id

drop if missing(b)
* Store variable names dynamically in a local macro
local labels
levelsof name, local(varlist)  
local i = 1  
foreach var of local varlist {  
    local labels `labels' cd#`i' = "`var'"  
    local ++i  
}  

drop if name=="MFQ_TOT_visit"|name=="MFQ_TOT_adhere"|name=="MFQ_CACE"
keep if s==1

encode name, gen(id2)

//reserve items for forest plot
gen cd_r     = cd
gen cdlci_r  = cdlci
gen cduci_r  = cduci
replace cd_r    = -cd    if r==1
replace cdlci_r = -cdlci if r==1
replace cduci_r = -cduci if r==1

* Forest plot
//currently assumes negative is better


twoway ///
    (rcap cdlci_r cduci_r id2, horizontal lcolor(black)) /// Confidence intervals
    (scatter id2 cd_r, mcolor(blue) msize(medium)), /// Point estimates
    xlabel(-1(0.2)1) /// Adjust X-axis range based on values
    ylabel(#7,valuelabel) ///
    yscale(reverse) ///
    xline(0, lcolor(red) lpattern(dash)) /// Reference line at zero
    title("Forest Plot of Secondary Clinical Outcomes  - Week 8",size(medsmall)) ///
    xtitle("Cohen's D") ytitle("") ///
    text(6 -0.7 "Favours IMAGINE", place(c) size(small)) ///
    text(6 0.7 "Favours NDS", place(c) size(small)) ///
    legend(off)
cd "$tabs"
graph export forestplot_wk8_clinical.png, replace


cd "$tabs"
use results_output_labelled,replace
//replace id = _n  
keep if time=="Week 16"
drop if name=="MFQ_TOT_visit"|name=="MFQ_TOT_adhere"|name=="MFQ_CACE"
//gsort -id
keep if s==1
drop if missing(b)
* Store variable names dynamically in a local macro
local labels
levelsof name, local(varlist)  
local i = 1  
foreach var of local varlist {  
    local labels `labels' cd#`i' = "`var'"  
    local ++i  
}  

encode name, gen(id2)

//reserve items for forest plot
gen cd_r     = cd
gen cdlci_r  = cdlci
gen cduci_r  = cduci
replace cd_r    = -cd    if r==1
replace cdlci_r = -cdlci if r==1
replace cduci_r = -cduci if r==1
* Forest plot

twoway ///
    (rcap cdlci_r cduci_r id2, horizontal lcolor(black)) /// Confidence intervals
    (scatter id2 cd_r, mcolor(blue) msize(medium)), /// Point estimates
    xlabel(-1(0.2)1) /// Adjust X-axis range based on values
    ylabel(#7,valuelabel) ///
    yscale(reverse) ///
    xline(0, lcolor(red) lpattern(dash)) /// Reference line at zero
    title("Forest Plot of Secondary Clinical Outcomes  - Week 16",size(medsmall)) ///
    xtitle("Cohen's D") ytitle("") ///
    text(6 -0.7 "Favours IMAGINE", place(c) size(small)) ///
    text(6 0.7 "Favours NDS", place(c) size(small)) ///
    legend(off)
cd "$tabs"
graph export forestplot_wk16_clinical.png, replace




cd "$tabs"
use results_output_labelled,replace
//replace id = _n  
keep if time=="Week 24"
drop if name=="MFQ_TOT_visit"|name=="MFQ_TOT_adhere"|name=="MFQ_CACE"
//gsort -id
keep if s==1
drop if missing(b)
* Store variable names dynamically in a local macro
local labels
levelsof name, local(varlist)  
local i = 1  
foreach var of local varlist {  
    local labels `labels' cd#`i' = "`var'"  
    local ++i  
}  

encode name, gen(id2)

//reserve items for forest plot where +ve is higher
gen cd_r     = cd
gen cdlci_r  = cdlci
gen cduci_r  = cduci
replace cd_r    = -cd    if r==1
replace cdlci_r = -cdlci if r==1
replace cduci_r = -cduci if r==1
* Forest plot
//currently assumes negative is better

twoway ///
    (rcap cdlci_r cduci_r id2, horizontal lcolor(black)) /// Confidence intervals
    (scatter id2 cd_r, mcolor(blue) msize(medium)), /// Point estimates
    xlabel(-1(0.2)1) /// Adjust X-axis range based on values
    ylabel(#7,valuelabel) ///
    yscale(reverse) ///
    xline(0, lcolor(red) lpattern(dash)) /// Reference line at zero
    title("Forest Plot of Secondary Clinical Outcomes  - Week 24",size(medsmall)) ///
    xtitle("Cohen's D") ytitle("") ///
    text(6 -0.7 "Favours IMAGINE", place(c) size(small)) ///
    text(6 0.7 "Favours NDS", place(c) size(small)) ///
    legend(off)
cd "$tabs"
graph export forestplot_wk24_clinical.png, replace


use results_output_labelled,replace
//replace id = _n  
keep if time=="Week 8"

//gsort -id

drop if missing(b)
* Store variable names dynamically in a local macro
local labels
levelsof name, local(varlist)  
local i = 1  
foreach var of local varlist {  
    local labels `labels' cd#`i' = "`var'"  
    local ++i  
}  

drop if name=="MFQ_TOT_visit"|name=="MFQ_TOT_adhere"|name=="MFQ_CACE"
keep if m==1

encode name, gen(id2)

//reserve items for forest plot
gen cd_r     = cd
gen cdlci_r  = cdlci
gen cduci_r  = cduci
replace cd_r    = -cd    if r==1
replace cdlci_r = -cdlci if r==1
replace cduci_r = -cduci if r==1

* Forest plot
//currently assumes negative is better


twoway ///
    (rcap cdlci_r cduci_r id2, horizontal lcolor(black)) /// Confidence intervals
    (scatter id2 cd_r, mcolor(blue) msize(medium)), /// Point estimates
    xlabel(-1(0.2)1) /// Adjust X-axis range based on values
    ylabel(#8,valuelabel) ///
    yscale(reverse) ///
    xline(0, lcolor(red) lpattern(dash)) /// Reference line at zero
    title("Forest Plot of Secondary Mechanism Outcomes  - Week 8",size(medsmall)) ///
    xtitle("Cohen's D") ytitle("") ///
    text(7 -0.7 "Favours IMAGINE", place(c) size(small)) ///
    text(7 0.7 "Favours NDS", place(c) size(small)) ///
    legend(off)
cd "$tabs"
graph export forestplot_wk8_mechanism.png, replace


cd "$tabs"
use results_output_labelled,replace
//replace id = _n  
keep if time=="Week 16"
drop if name=="MFQ_TOT_visit"|name=="MFQ_TOT_adhere"|name=="MFQ_CACE"
//gsort -id
keep if m==1
drop if missing(b)
* Store variable names dynamically in a local macro
local labels
levelsof name, local(varlist)  
local i = 1  
foreach var of local varlist {  
    local labels `labels' cd#`i' = "`var'"  
    local ++i  
}  

encode name, gen(id2)

//reserve items for forest plot
gen cd_r     = cd
gen cdlci_r  = cdlci
gen cduci_r  = cduci
replace cd_r    = -cd    if r==1
replace cdlci_r = -cdlci if r==1
replace cduci_r = -cduci if r==1
* Forest plot
//need to reverse interpretation where relevant 
//currently assumes negative is better

twoway ///
    (rcap cdlci_r cduci_r id2, horizontal lcolor(black)) /// Confidence intervals
    (scatter id2 cd_r, mcolor(blue) msize(medium)), /// Point estimates
    xlabel(-1(0.2)1) /// Adjust X-axis range based on values
    ylabel(#8,valuelabel) ///
    yscale(reverse) ///
    xline(0, lcolor(red) lpattern(dash)) /// Reference line at zero
    title("Forest Plot of Secondary Mechanism Outcomes  - Week 16",size(medsmall)) ///
    xtitle("Cohen's D") ytitle("") ///
    text(7 -0.7 "Favours IMAGINE", place(c) size(small)) ///
    text(7 0.7 "Favours NDS", place(c) size(small)) ///
    legend(off)
cd "$tabs"
graph export forestplot_wk16_mechanism.png, replace




cd "$tabs"
use results_output_labelled,replace
//replace id = _n  
keep if time=="Week 24"
drop if name=="MFQ_TOT_visit"|name=="MFQ_TOT_adhere"|name=="MFQ_CACE"
//gsort -id
keep if m==1
drop if missing(b)
* Store variable names dynamically in a local macro
local labels
levelsof name, local(varlist)  
local i = 1  
foreach var of local varlist {  
    local labels `labels' cd#`i' = "`var'"  
    local ++i  
}  

encode name, gen(id2)

//reserve items for forest plot where +ve is higher
gen cd_r     = cd
gen cdlci_r  = cdlci
gen cduci_r  = cduci
replace cd_r    = -cd    if r==1
replace cdlci_r = -cdlci if r==1
replace cduci_r = -cduci if r==1
* Forest plot
//currently assumes negative is better

twoway ///
    (rcap cdlci_r cduci_r id2, horizontal lcolor(black)) /// Confidence intervals
    (scatter id2 cd_r, mcolor(blue) msize(medium)), /// Point estimates
    xlabel(-1(0.2)1) /// Adjust X-axis range based on values
    ylabel(#8,valuelabel) ///
    yscale(reverse) ///
    xline(0, lcolor(red) lpattern(dash)) /// Reference line at zero
    title("Forest Plot of Secondary Mechanism Outcomes  - Week 24",size(medsmall)) ///
    xtitle("Cohen's D") ytitle("") ///
    text(7 -0.7 "Favours IMAGINE", place(c) size(small)) ///
    text(7 0.7 "Favours NDS", place(c) size(small)) ///
    legend(off)
cd "$tabs"
graph export forestplot_wk24_mechanism.png, replace



/******************************
2 - OUTPUT TABLES
*******************************/
cd "$tabs"

putdocx clear
putdocx begin
putdocx paragraph

use results_output_labelled,replace
rename name outcome
keep if time=="Week 8" 
drop if missing(b)
putdocx paragraph
putdocx text ("Table 1 - Outcomes Week 8") 
putdocx table tb2= data(outcome b se p lci uci cd cdlci cduci), varnames
putdocx table tb2(.,.),nformat(%9.3f)

putdocx paragraph
putdocx text ("Figure 1 - Forest plot of Secondary clinical outcomes at Week 8") 
putdocx image forestplot_wk8_clinical.png

putdocx paragraph
putdocx text ("Figure 1 - Forest plot of Secondary mechanism outcomes at Week 8") 
putdocx image forestplot_wk8_mechanism.png

cd "$tabs"
use results_output_labelled,replace
rename name outcome
keep if time=="Week 16" 
drop if missing(b)
putdocx paragraph
putdocx text ("Table 2 - Outcomes Week 16") 
putdocx table tb2= data(outcome b se p lci uci cd cdlci cduci), varnames
putdocx table tb2(.,.),nformat(%9.3f)

putdocx paragraph
putdocx text ("Figure 1 - Forest plot of Secondary clinical outcomes at Week 16") 
putdocx image forestplot_wk16_clinical.png

putdocx paragraph
putdocx text ("Figure 1 - Forest plot of Secondary mechanism outcomes at Week 16") 
putdocx image forestplot_wk16_mechanism.png


cd "$tabs"
use results_output_labelled,replace
rename name outcome
keep if time=="Week 24" 
drop if missing(b)
putdocx paragraph
putdocx text ("Table 3 - Outcomes Week 24") 
putdocx table tb2= data(outcome b se p lci uci cd cdlci cduci), varnames
putdocx table tb2(.,.),nformat(%9.3f)

putdocx paragraph
putdocx text ("Figure 1 - Forest plot of Secondary clinical outcomes at Week 24") 
putdocx image forestplot_wk24_clinical.png

putdocx paragraph
putdocx text ("Figure 1 - Forest plot of Secondary mechanism outcomes at Week 24") 
putdocx image forestplot_wk24_mechanism.png


putdocx paragraph
putdocx text ("Figure 4 - raw MFQ means over time") 
putdocx image MFQ_raw_means_over_time.png

putdocx paragraph
putdocx text ("Figure 5 - estimated MFQ means over time") 
putdocx image MFQ_estimated_means_over_time.png

putdocx paragraph
putdocx text ("Figure 6 - estimated MFQ means over time in PP pop") 
putdocx image MFQ_estimated_means_over_time_PP.png


putdocx paragraph
putdocx text ("Figure 7 - Missing not at random potential scenarios") 
putdocx image mnar_week8.png




cd "$tabs"
putdocx save INDIGO_analysis_tables_v01.docx, replace


*************************************************
*LAST LINE
*************************************************

display "$S_TIME $S_DATE"
