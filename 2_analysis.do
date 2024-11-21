
global main_directory "{YOUR_PATH}"

*********************************
**Data files used:
*********************************


*This is the original file : it is a panel containing startups that engaged with OSCs on GitHub and startups that did not
use "$main_directory\Crunchbase\Output/dataset_08102020_II.dta",clear
*This file is the main file where we have matched startups engaged with OSCs on GitHub with a max of 5 startups
use "$main_directory\Crunchbase\Output\final_analyses", replace
*This file is the file containg Product Hunt data
use "$main_directory/Crunchbase/Output/product_hunt_domain_2.dta", replace
*This is file where we have matched startups engaged having a GitHub count with a max of 5 startups with no such account
use "$main_directory\Crunchbase\Output\dataset_08102020_X_int_1_internal_panel.dta", replace
*This is file whit the variable on the level of competition in a market
use  "$main_directory/Crunchbase/Output/firm_types_contested", replace
*This is file with the novelty measure
use  "$main_directory/Crunchbase/Output/novelty_anna", replace
*This is file with top team information
use "$main_directory/workingdata/people.dta", replace
*This is file with the software share variable
use "$main_directory/Crunchbase/output/software_related", replace




**************************************************************************
/****Table 1a******/
**************************************************************************

use "$main_directory\Crunchbase\Output/dataset_08102020_II.dta",clear

gen temp=last_funding_on==""
replace temp=1-temp
bys company_uuid: egen raised=max(temp)
duplicates drop company_domain, force
drop temp
keep company_uuid company_domain company_category_groups_list company_state_code founding_year raised venture_capital accelerator acquired went_public_on funding_round_uuid round_announced_on investor_count round_raised_amount_usd

merge m:1 company_domain using "$main_directory/github/data/repos_meta.dta"
gen nogithub=_merge==1
drop if _merge==2
drop _merge
merge m:1 company_uuid using "$main_directory/workingdata/people.dta"
drop if _merge==2
drop _merge
merge m:1 company_uuid using "$main_directory/Crunchbase/output/software_related"
drop if _merge==2
drop _merge


*************
*Generate sectors

gen ai=0
replace ai=1 if strpos(company_category_groups_list, "Artificial Intelligence")>0 
gen data_analytics=0
replace data_analytics=1 if strpos(company_category_groups_list, "Data and Analytics")>0 
gen privacy_security=0
replace privacy_security=1 if strpos(company_category_groups_list, "Privacy and Security")>0 
gen information_technology=0
replace information_technology=1 if strpos(company_category_groups_list, "Information Technology")>0
gen internet_services=0
replace internet_services=1 if strpos(company_category_groups_list, "Internet Services")>0 
gen mobile=0
replace mobile=1 if strpos(company_category_groups_list, "Mobile")>0 
gen software=0
replace software=1 if strpos(company_category_groups_list, "Software")>0 
gen software_it=0
replace software_it=1 if software==1 & information_technology==1
gen biotechnology=0
replace biotechnology=1 if strpos(company_category_groups_list, "Biotechnology")>0 
gen health_care=0
replace health_care=1 if strpos(company_category_groups_list, "Health Care")>0 
**
gen great_recession=founding_year==2009 | founding_year==2008
**
gen startup_hub=company_state_code=="CA" | company_state_code=="MA" | company_state_code=="NY"
**

**Hub
gen ca=company_state_code=="CA"
gen ma=company_state_code=="MA"
gen ny=company_state_code=="NY"

foreach var in forks open_issues size watchers {
	gen ln_`var'=ln1p(`var')
}

gen industry=0
replace industry=1 if ai==1
replace industry=2 if data_analytics==1
replace industry=3 if privacy_security==1
replace industry=4 if information_technology==1
replace industry=5 if internet_services==1
replace industry=6 if mobile==1
replace industry=7 if software==1


gen github=1-nogithub
gen startup_hub_=startup_hub

label variable github "GitHub"
label variable top1000 "Top-Team"
label variable ln_forks "Ln Forks"
label variable ln_open_issues "Ln Open Issues"
label variable ln_size "Ln Size"
label variable ln_watchers "Ln Watchers"
label variable permissive "Permissive"
label variable copyleft "Copyleft"
label variable otherlicense "Other License"

replace top1000=0 if top1000==.



reghdfe raised github top1000 ca ma ny ai data_analytics information_technology internet_services mobile software , cluster( founding_year) absorb(founding_year)
gen esample=e(sample)
tab github if esample==1
tab github if software==1 & esample==1
tab software if github==1 & esample==1


keep if esample==1
gen ipo=went_public_on!=""
gen acquired= acquired_on!=""
gen category_groups_list = length(trim(company_category_groups_list))-length(trim(subinstr(company_category_groups_list,",","",.)))
gen group_g=category_groups_list+1
sutex2 raised ipo acquired  github top1000 ipo acquired ai data_analytics information_technology internet_services mobile software group_g share_keywords_software ca ma ny, digits(3)  minmax perc(50)


*
preserve
use "$main_directory/Crunchbase/Output/dataset_08102020_II.dta",replace
duplicates drop company_domain, force
keep if founding_year>2011
merge m:1 company_domain using "$main_directory/Crunchbase/Output/product_hunt_domain_2_temp.dta"
keep if _merge==1 | _merge==3
drop _merge
replace product_launched=0 if product_launched==.
sum product_launched
restore


**************************************
*Table 3a: Summary statistics - Matched sample
**************************************

use "$main_directory\Crunchbase\Output\final_analyses", replace
preserve
bys company_domain_n: egen raised=max(raised_round)
duplicates drop company_domain, force
merge m:1 company_uuid using "$main_directory\Crunchbase\Output\merge_acquisition"
keep if _merge==1 | _merge==3
drop _merge
merge m:1 company_uuid using "$main_directory\Crunchbase\Output\merge_ipo"
keep if _merge==1 | _merge==3
drop _merge
gen ipo=went_public_on!=""
gen acquired= acquired_on!=""
gen category_groups_list = length(trim(company_category_groups_list))-length(trim(subinstr(company_category_groups_list,",","",.)))
gen group_g=category_groups_list+1
gen github=is_treated
gen ca=company_state_code=="CA"
gen ma=company_state_code=="MA"
gen ny=company_state_code=="NY"
sutex2 raised ipo acquired  github top_team ipo acquired ai da it is mob soft group_g share_keywords_software ca ma ny, digits(3)  minmax perc(50)
restore

preserve
use "$main_directory/Crunchbase/Output/product_hunt_domain_2.dta", replace
keep product_launched company_domain
by company_domain, sort: egen mproduct_launched=max(product_launched)
duplicates drop company_domain, force
drop product_launched
rename mproduct_launched product_launched
save "$main_directory/Crunchbase/Output/product_hunt_domain_2_temp.dta", replace
restore


preserve
duplicates drop company_domain, force
keep if founding_year>2011
merge m:1 company_domain using "$main_directory/Crunchbase/Output/product_hunt_domain_2_temp.dta"
keep if _merge==1 | _merge==3
drop _merge
replace product_launched=0 if product_launched==.
sum product_launched
restore




**************************************
*Table 3b: Descriptive statistics of matched startups
**************************************
use "$main_directory\Crunchbase\Output\final_analyses", replace

preserve
gen high_suc=cum_number_successinv_5year>=20
gen high_amount=round_raised_amount_usd>=1785415 

bys company_domain_n: egen max_raised_round=max(raised_round)
bys company_domain_n: egen max_venture_capital=max(venture_capital)
bys company_domain_n: egen max_amount=max(high_amount)
bys company_domain_n: egen max_high_suc=max(high_suc)


keep company_domain_n is_treated max_raised_round max_venture_capital max_amount max_high_suc
duplicates drop company_domain_n, force


eststo Treatement: quietly estpost summarize ///
    max_raised_round max_venture_capital max_high_suc max_amount  if is_treated==1
eststo NoTreatment: quietly estpost summarize ///
    max_raised_round max_venture_capital max_high_suc max_amount  if is_treated==0
eststo diff: quietly estpost ttest ///
    max_raised_round max_venture_capital max_high_suc max_amount  , by(is_treated) unequal
 
esttab Treatement NoTreatment   diff using "$main_directory\Table3b.tex", ///
cells("mean(pattern(1 1 0) fmt(4)) sd(pattern(1 1 0) fmt(4))  b(star pattern(0 0 1) fmt(4)) ")  ///
label
restore



preserve
keep if founding_year>2011
merge m:1 company_domain date_for_panel using "C:\Users\annamaria.conti\Dropbox\Project_Hunt_Anna_Juan\Analysis\LISTSTARTUPSCRUNCHBASE\product_hunt_domain"
keep if _merge==1 | _merge==3
drop _merge
replace product_launched=0 if product_launched==.
bys company_domain_n: egen max_product_launched=max(product_launched)
duplicates drop company_domain_n, force
ttest max_product_launched, by (is_treated)
restore




*****************************************************
*Table 2: Startups engaging with OSCs on GitHub
******************************************************

*This is a cross-section
use "$main_directory\Crunchbase\Output/dataset_08102020_II.dta",clear

gen temp=last_funding_on==""
replace temp=1-temp
bys company_uuid: egen raised=max(temp)
duplicates drop company_domain, force
drop temp
keep  company_uuid company_domain company_category_groups_list company_state_code founding_year raised venture_capital accelerator acquired went_public_on funding_round_uuid round_announced_on investor_count round_raised_amount_usd

merge m:1 company_domain using "$main_directory/github/data/repos_meta.dta"
gen nogithub=_merge==1
drop if _merge==2
drop _merge
merge m:1 company_uuid using "$main_directory/workingdata/people.dta"
drop if _merge==2
drop _merge
merge m:1 company_uuid using "$main_directory/Crunchbase/output/software_related"
drop if _merge==2
drop _merge

*Generate sectors

gen ai=0
replace ai=1 if strpos(company_category_groups_list, "Artificial Intelligence")>0 
gen data_analytics=0
replace data_analytics=1 if strpos(company_category_groups_list, "Data and Analytics")>0 
gen privacy_security=0
replace privacy_security=1 if strpos(company_category_groups_list, "Privacy and Security")>0 
gen information_technology=0
replace information_technology=1 if strpos(company_category_groups_list, "Information Technology")>0
gen internet_services=0
replace internet_services=1 if strpos(company_category_groups_list, "Internet Services")>0 
gen mobile=0
replace mobile=1 if strpos(company_category_groups_list, "Mobile")>0 
gen software=0
replace software=1 if strpos(company_category_groups_list, "Software")>0 
gen software_it=0
replace software_it=1 if software==1 & information_technology==1
gen biotechnology=0
replace biotechnology=1 if strpos(company_category_groups_list, "Biotechnology")>0 
gen health_care=0
replace health_care=1 if strpos(company_category_groups_list, "Health Care")>0 
**
gen great_recession=founding_year==2009 | founding_year==2008
**
gen startup_hub=company_state_code=="CA" | company_state_code=="MA" | company_state_code=="NY"
**

**Hub
gen ca=company_state_code=="CA"
gen ma=company_state_code=="MA"
gen ny=company_state_code=="NY"

foreach var in forks open_issues size watchers {
	gen ln_`var'=ln1p(`var')
}

gen industry=0
replace industry=1 if ai==1
replace industry=2 if data_analytics==1
replace industry=3 if privacy_security==1
replace industry=4 if information_technology==1
replace industry=5 if internet_services==1
replace industry=6 if mobile==1
replace industry=7 if software==1


gen github=1-nogithub
gen startup_hub_=startup_hub

label variable github "GitHub"
label variable top1000 "Top-Team"
label variable ln_forks "Ln Forks"
label variable ln_open_issues "Ln Open Issues"
label variable ln_size "Ln Size"
label variable ln_watchers "Ln Watchers"
label variable permissive "Permissive"
label variable copyleft "Copyleft"
label variable otherlicense "Other License"

replace top1000=0 if top1000==.


preserve
use "$main_directory/github/data/all_activity_company_panel.dta", replace
bys company_domain: egen max_external=max(external)
duplicates drop company_domain, force
keep company_domain max_external
save "$main_directory/github/data/max_ext.dta", replace
restore

preserve
use "$main_directory/github/data/all_activity_company_panel.dta", replace
bys company_domain: egen max_internal=max(internal)
duplicates drop company_domain, force
keep company_domain max_internal
save "$main_directory/github/data/max_int.dta", replace
restore

merge m:1 company_domain using "$main_directory/github/data/max_ext.dta"
keep if _merge==1 | _merge==3
drop _merge
replace max_external=0 if max_external==.
replace max_external=1 if max_external>0


reghdfe  max_external accelerator top1000 ca ma ny ai data_analytics information_technology internet_services mobile software, cluster( founding_year) absorb(founding_year)
estimate store a0
esttab a0, label replace booktabs title(Startups engaging with OSCs on GitHub)  nobaselevels noconstant star(* 0.10 ** 0.05 *** 0.01) se stats(N r2 , labels("Observations" "R2")) compress, using Table2.tex


**************************************
*Table 4: Baseline - Raising a financing round
**************************************

use "$main_directory\Crunchbase\Output\final_analyses", replace


reghdfe raised_round  after##c.is_treated if pair_set_id!=., absorb(pair_set_id date_for_panel company_domain_n)  vce(cluster pair_set_id)
estimate store a1
gen esample=e(sample)
sum raised_round if esample==1
drop esample

reghdfe raised_round  after##c.is_treated if pair_set_id!=., absorb(pair_set_id##date_for_panel company_domain_n)  vce(cluster pair_set_id)
estimate store a2
gen esample=e(sample)
sum raised_round if esample==1
drop esample

reghdfe raised_round  after##c.is_treated if pair_set_id!=., absorb(pair_set_id##date_for_panel company_domain_n apps##date_for_panel ai##date_for_panel ce##date_for_panel da##date_for_panel design##date_for_panel fs##date_for_panel game##date_for_panel hard##date_for_panel it##date_for_panel is##date_for_panel mt##date_for_panel mob##date_for_panel pay##date_for_panel plat##date_for_panel ps##date_for_panel soft##date_for_panel)  vce(cluster pair_set_id)
estimate store a3
gen esample=e(sample)
sum raised_round if esample==1
drop esample

reghdfe raised_round  after##c.is_treated if pair_set_id!=., absorb(pair_set_id##date_for_panel company_domain_n apps##date_for_panel ai##date_for_panel ce##date_for_panel da##date_for_panel design##date_for_panel fs##date_for_panel game##date_for_panel hard##date_for_panel it##date_for_panel is##date_for_panel mt##date_for_panel mob##date_for_panel pay##date_for_panel plat##date_for_panel ps##date_for_panel soft##date_for_panel company_domain_n##company_age)  vce(cluster pair_set_id)
estimate store a4
gen esample=e(sample)
sum raised_round if esample==1
drop esample


esttab a1 a2 a3 a4, label replace booktabs title(Raising a financing round) keep(1.after is_treated  1.after#c.is_treated) nobaselevels noconstant star(* 0.10 ** 0.05 *** 0.01) se stats(N r2 , labels("Observations" "R2")) compress, using Table4.tex



**********************************************************************
* Table 5: Raising a financing round: By timing of involvement with OSCs
**************************************************************************

use "$main_directory\Crunchbase\Output\final_analyses", replace


by company_domain_n (date_for_panel), sort: gen cohort_treatment=_n if after==1
replace cohort_treatment=0 if cohort_treatment==.

by company_domain_n (date_for_panel), sort: gen cohort_raised_round=_n if raised_round==1
replace cohort_raised_round=0 if cohort_raised_round==.
by company_domain_n (date_for_panel), sort: egen is_funded=max(raised_round)


gen test=cohort_treatment-cohort_raised_round
gen flag=test<0

by company_domain_n (date_for_panel), sort: egen max_flag=max(flag)
by pair_set_id (date_for_panel), sort: egen max_max_flag=max(max_flag)


*Replicates the same analysis as in column 4 of Table 4, excluding from the sample startups active with OSCs on GitHub that became active before raising their first financing round
reghdfe raised_round  after##c.is_treated if pair_set_id!=. & max_max_flag==1, absorb(pair_set_id##date_for_panel company_domain_n apps##date_for_panel ai##date_for_panel ce##date_for_panel da##date_for_panel design##date_for_panel fs##date_for_panel game##date_for_panel hard##date_for_panel it##date_for_panel is##date_for_panel mt##date_for_panel mob##date_for_panel pay##date_for_panel plat##date_for_panel ps##date_for_panel soft##date_for_panel company_domain_n##company_age)  vce(cluster pair_set_id)

estimate store a1
gen esample=e(sample)
sum raised_round if esample==1
drop esample

*Replicates the same analysis as in column 4 of Table 4, excluding from the sample startups active with OSCs on GitHub that became active after raising their first financing round
reghdfe raised_round  after##c.is_treated if pair_set_id!=. & max_max_flag==0, absorb(pair_set_id##date_for_panel company_domain_n apps##date_for_panel ai##date_for_panel ce##date_for_panel da##date_for_panel design##date_for_panel fs##date_for_panel game##date_for_panel hard##date_for_panel it##date_for_panel is##date_for_panel mt##date_for_panel mob##date_for_panel pay##date_for_panel plat##date_for_panel ps##date_for_panel soft##date_for_panel company_domain_n##company_age)  vce(cluster pair_set_id)

estimate store a2
gen esample=e(sample)
sum raised_round if esample==1
drop esample


esttab a1 a2, label replace booktabs title(Raising a financing round: By timing of involvement with OSCs) keep(1.after is_treated  1.after#c.is_treated) nobaselevels noconstant star(* 0.10 ** 0.05 *** 0.01) se stats(N r2 , labels("Observations" "R2")) compress, using Table5.tex



**************************************
*Table 6: Internal and External Activities
**************************************
preserve

use "$main_directory\Crunchbase\Output\dataset_08102020_X_int_1_internal_panel.dta", replace
drop if pair_set_id==.

drop raised_round
gen raised_round=edate_round_announced_on==date_for_panel & yes_round==1


*
bys company_domain (date_for_panel): gen test=sum(raised_round)
drop raised_round
rename test raised_round


*Generate sectors
gen  apps=strpos(company_category_groups_list, "Apps")>0
gen  ai=strpos(company_category_groups_list, "Artificial Intelligence")>0
gen  ce=strpos(company_category_groups_list, "Consumer Electronics")>0
gen  da=strpos(company_category_groups_list, "Data and Analytics")>0
gen  design=strpos(company_category_groups_list, "Design")>0
gen  fs=strpos(company_category_groups_list, "Financial Services")>0
gen  game=strpos(company_category_groups_list, "Gaming")>0
gen  hard=strpos(company_category_groups_list, "Hardware")>0
gen  it=strpos(company_category_groups_list, "Information Technology")>0
gen  is=strpos(company_category_groups_list, "Internet Services")>0
gen  mt=strpos(company_category_groups_list, "Messaging and Telecommunications")>0
gen  mob=strpos(company_category_groups_list, "Mobile")>0
gen  pay=strpos(company_category_groups_list, "Payments")>0
gen  plat=strpos(company_category_groups_list, "Platforms")>0
gen  ps=strpos(company_category_groups_list, "Privacy and Security")>0
gen  soft=strpos(company_category_groups_list, "Software")>0


**

bys company_domain: egen is_treated =max(activity_q_b)
bysort pair_set_id: egen set_is_treated = max(is_treated)
gen aftert=activity_q_bcum>0
bysort pair_set_id date_for_panel: egen after= max(aftert)

bysort pair_set_id company_domain (date_for_panel): gen test= sum(after)
replace test=1 if test>1
drop after
rename test after

egen company_domain_n=group(company_domain)
***
bys cid: egen test=max(after)
drop if test==0
drop test


reghdfe raised_round external_q_bcum internal_q_bcum if pair_set_id!=., absorb(pair_set_id##date_for_panel company_domain_n apps##date_for_panel ai##date_for_panel ce##date_for_panel da##date_for_panel design##date_for_panel fs##date_for_panel game##date_for_panel hard##date_for_panel it##date_for_panel is##date_for_panel mt##date_for_panel mob##date_for_panel pay##date_for_panel plat##date_for_panel ps##date_for_panel soft##date_for_panel)  vce(cluster pair_set_id)
gen esample=e(sample)
sum raised_round if esample==1
test external_q_bcum==internal_q_bcum
restore 



*************************************************************
* Table 7: Heterogeneity in raising a financing round - By technology novelty and the level of market competition
***************************************************************
use "$main_directory\Crunchbase\Output\final_analyses", replace

**Add variable on the level of competition
merge m:1 company_uuid date_for_panel using "$main_directory/Crunchbase/Output/firm_types_contested"
keep if _merge==1 | _merge==3
drop _merge

**Add variable on the level of novelty of a technology
merge m:1 company_uuid using "$main_directory/Crunchbase/Output/novelty_anna"
keep if _merge==1 | _merge==3
drop _merge



reghdfe raised_round  after##c.is_treated##novel1 if pair_set_id!=., absorb(pair_set_id##date_for_panel company_domain_n date_for_panel##novel1)  vce(cluster pair_set_id)
estimate store a1

reghdfe raised_round  after##c.is_treated##contested if pair_set_id!=., absorb(pair_set_id##date_for_panel company_domain_n date_for_panel##contested)  vce(cluster pair_set_id)
estimate store a2


esttab a1 a2, label replace booktabs title(Heterogeneity in raising a financing round - By technology novelty and the level of market competition) keep( 1.after#c.is_treated 1.contested  1.after#1.contested 1.contested#c.is_treated 1.after#1.contested#c.is_treated 1.after#1.novel1 1.after#1.novel1#c.is_treated) nobaselevels noconstant star(* 0.10 ** 0.05 *** 0.01) se stats(N r2 , labels("Observations" "R2")) compress, using Table7.tex


***************************************
****Table 8: Innovation: Product launches
***************************************
use "$main_directory\Crunchbase\Output\final_analyses", replace


*Add data on product launches 
preserve
capture drop _merge 
keep if founding_year>2011
merge m:1 company_domain date_for_panel using "$main_directory/Crunchbase/Output/product_hunt_domain_2.dta"
keep if _merge==1 | _merge==3
drop _merge
replace product_launched=0 if product_launched==.
gen high_quality_product=Rating_75==1 | upvotes_75==1 | comments_75==1
replace first_launch=0 if first_launch==.

bys pair_set_id company_domain_n (date_for_panel): gen cum_product_launched=sum(product_launched)
tab cum_product_launched 
tab product_launched


preserve
by company_domain, sort: egen max_product_launched=max(product_launched)
duplicates drop company_domain, force
tab max_product_launched
sum max_product_launched
restore 


reghdfe cum_product_launched  after##c.is_treated if pair_set_id!=., absorb(pair_set_id date_for_panel company_domain_n)  vce(cluster pair_set_id)
estimate store a1
gen esample=e(sample)
sum cum_product_launched if esample==1
drop esample

reghdfe cum_product_launched  after##c.is_treated if pair_set_id!=., absorb(pair_set_id##date_for_panel company_domain_n)  vce(cluster pair_set_id)
estimate store a2
gen esample=e(sample)
sum cum_product_launched if esample==1
drop esample

reghdfe cum_product_launched  after##c.is_treated if pair_set_id!=., absorb(pair_set_id##date_for_panel company_domain_n apps##date_for_panel ai##date_for_panel ce##date_for_panel da##date_for_panel design##date_for_panel fs##date_for_panel game##date_for_panel hard##date_for_panel it##date_for_panel is##date_for_panel mt##date_for_panel mob##date_for_panel pay##date_for_panel plat##date_for_panel ps##date_for_panel soft##date_for_panel)  vce(cluster pair_set_id)
estimate store a3
gen esample=e(sample)
sum cum_product_launched if esample==1
drop esample

reghdfe cum_product_launched  after##c.is_treated if pair_set_id!=., absorb(pair_set_id##date_for_panel company_domain_n apps##date_for_panel ai##date_for_panel ce##date_for_panel da##date_for_panel design##date_for_panel fs##date_for_panel game##date_for_panel hard##date_for_panel it##date_for_panel is##date_for_panel mt##date_for_panel mob##date_for_panel pay##date_for_panel plat##date_for_panel ps##date_for_panel soft##date_for_panel company_domain_n##company_age)  vce(cluster pair_set_id)
estimate store a4
gen esample=e(sample)
sum counter if esample==1
drop esample


esttab a1 a2 a3 a4, label replace booktabs title(Innovation: Product launches) keep(1.after is_treated  1.after#c.is_treated) nobaselevels noconstant star(* 0.10 ** 0.05 *** 0.01) se stats(N r2 , labels("Observations" "R2")) compress, using Table8.tex
restore


***********************************************************************************************
*****Table 9: Technology development or simply enhancing the visibility of a technology?
***********************************************************************************************

preserve
use "$main_directory\Crunchbase\Output\dataset_08102020_X_int_1_internal_panel.dta", replace
drop if pair_set_id==.

drop raised_round
gen raised_round=edate_round_announced_on==date_for_panel & yes_round==1

*
bys company_domain (date_for_panel): gen test=sum(raised_round)
drop raised_round
rename test raised_round


*Generate sectors
gen  apps=strpos(company_category_groups_list, "Apps")>0
gen  ai=strpos(company_category_groups_list, "Artificial Intelligence")>0
gen  ce=strpos(company_category_groups_list, "Consumer Electronics")>0
gen  da=strpos(company_category_groups_list, "Data and Analytics")>0
gen  design=strpos(company_category_groups_list, "Design")>0
gen  fs=strpos(company_category_groups_list, "Financial Services")>0
gen  game=strpos(company_category_groups_list, "Gaming")>0
gen  hard=strpos(company_category_groups_list, "Hardware")>0
gen  it=strpos(company_category_groups_list, "Information Technology")>0
gen  is=strpos(company_category_groups_list, "Internet Services")>0
gen  mt=strpos(company_category_groups_list, "Messaging and Telecommunications")>0
gen  mob=strpos(company_category_groups_list, "Mobile")>0
gen  pay=strpos(company_category_groups_list, "Payments")>0
gen  plat=strpos(company_category_groups_list, "Platforms")>0
gen  ps=strpos(company_category_groups_list, "Privacy and Security")>0
gen  soft=strpos(company_category_groups_list, "Software")>0


**

bys company_domain: egen is_treated =max(activity_q_b)
bysort pair_set_id: egen set_is_treated = max(is_treated)
gen aftert=activity_q_bcum>0
bysort pair_set_id date_for_panel: egen after= max(aftert)

bysort pair_set_id company_domain (date_for_panel): gen test= sum(after)
replace test=1 if test>1
drop after
rename test after

egen company_domain_n=group(company_domain)
***
bys cid: egen test=max(after)
drop if test==0
drop test


replace readme_q_bcum=0 if internal_q_bcum==0
gen no_readme_q_bcum=readme_q_bcum==0 & internal_q_bcum==1

*readme_q_bcum: (0/1) indicator: It becomes 1 from the moment a startup creates or modifies a readme file
*no_readme_q_bcum: (0/1) indicator: It becomes 1 from the moment a startup engages in any internal activity unrelated to creating or modifying a readme file
*external_q_bcum: (0/1) indicator: It becomes 1 from the moment a startup becomes engaged with OSCs on GitHub 

reghdfe raised_round external_q_bcum readme_q_bcum no_readme_q_bcum if pair_set_id!=., absorb(pair_set_id##date_for_panel company_domain_n apps##date_for_panel ai##date_for_panel ce##date_for_panel da##date_for_panel design##date_for_panel fs##date_for_panel game##date_for_panel hard##date_for_panel it##date_for_panel is##date_for_panel mt##date_for_panel mob##date_for_panel pay##date_for_panel plat##date_for_panel ps##date_for_panel soft##date_for_panel)  vce(cluster pair_set_id)
estimate store a1
gen esample=e(sample)
sum counter if esample==1
drop esample

esttab a1, label replace booktabs title(Technology development or simply enhancing the visibility of a technology?) keep(external_q_bcum readme_q_bcum no_readme_q_bcum) nobaselevels noconstant star(* 0.10 ** 0.05 *** 0.01) se stats(N r2 , labels("Observations" "R2")) compress, using Table9.tex


restore 


**************************************
*Table 10: Investor Heterogeneity
**************************************

use "$main_directory\Crunchbase\Output\final_analyses", replace

**Amount raised
preserve
gen test=edate_round_announced_on==date_for_panel & yes_round==1
sum round_raised_amount_usd if test==1 & yes_round==1, detail
gen high_amount=round_raised_amount_usd>=1295000 & raised_round==1 & yes_round==1
gen low_amount=high_amount==0 & raised_round==1 & yes_round==1

bys company_domain (date_for_panel): gen testh=sum(high_amount)
bys company_domain (date_for_panel): gen testl=sum(low_amount)
replace testl=1 if testl>0
replace testl=0 if testh==1

drop high_amount low_amount
rename testh high_amount
rename testl low_amount


reghdfe high_amount  after##c.is_treated if pair_set_id!=., absorb(pair_set_id##date_for_panel company_domain_n apps##date_for_panel ai##date_for_panel ce##date_for_panel da##date_for_panel design##date_for_panel fs##date_for_panel game##date_for_panel hard##date_for_panel it##date_for_panel is##date_for_panel mt##date_for_panel mob##date_for_panel pay##date_for_panel plat##date_for_panel ps##date_for_panel soft##date_for_panel)  vce(cluster pair_set_id)
estimate store a1
gen esample=e(sample)
sum high_amount if esample==1
drop esample


reghdfe low_amount  after##c.is_treated if pair_set_id!=., absorb(pair_set_id##date_for_panel company_domain_n apps##date_for_panel ai##date_for_panel ce##date_for_panel da##date_for_panel design##date_for_panel fs##date_for_panel game##date_for_panel hard##date_for_panel it##date_for_panel is##date_for_panel mt##date_for_panel mob##date_for_panel pay##date_for_panel plat##date_for_panel ps##date_for_panel soft##date_for_panel)  vce(cluster pair_set_id)
estimate store a2
gen esample=e(sample)
sum low_amount if esample==1
drop esample

*Venture capital raised
gen raised_round_no_vc=test==1 & venture_capital==0 & yes_round==1
bys company_domain (date_for_panel): gen testvc=sum(venture_capital)
bys company_domain (date_for_panel): gen testnovc=sum(raised_round_no_vc)
replace testnovc=1 if testnovc>0
replace testnovc=0 if testvc==1

drop raised_round_no_vc venture_capital

rename testvc venture_capital
rename testnovc raised_round_no_vc

reghdfe venture_capital  after##c.is_treated if pair_set_id!=., absorb(pair_set_id##date_for_panel company_domain_n apps##date_for_panel ai##date_for_panel ce##date_for_panel da##date_for_panel design##date_for_panel fs##date_for_panel game##date_for_panel hard##date_for_panel it##date_for_panel is##date_for_panel mt##date_for_panel mob##date_for_panel pay##date_for_panel plat##date_for_panel ps##date_for_panel soft##date_for_panel)  vce(cluster pair_set_id)
estimate store a3
gen esample=e(sample)
sum venture_capital if esample==1
drop esample

reghdfe raised_round_no_vc  after##c.is_treated if pair_set_id!=., absorb(pair_set_id##date_for_panel company_domain_n apps##date_for_panel ai##date_for_panel ce##date_for_panel da##date_for_panel design##date_for_panel fs##date_for_panel game##date_for_panel hard##date_for_panel it##date_for_panel is##date_for_panel mt##date_for_panel mob##date_for_panel pay##date_for_panel plat##date_for_panel ps##date_for_panel soft##date_for_panel)  vce(cluster pair_set_id)
estimate store a4
gen esample=e(sample)
sum raised_round_no_vc if esample==1
drop esample

*Raised round from successful investor
sum  cum_number_successinv_5year if test==1 & yes_round==1, detail
gen high_suc=cum_number_successinv_5year>=17 & raised_round==1 & yes_round==1
gen low_suc=high_suc==0 & raised_round==1 & yes_round==1


bys company_domain (date_for_panel): gen testsuc=sum(high_suc)
bys company_domain (date_for_panel): gen testnosuc=sum(low_suc)
replace testnosuc=1 if testnosuc>1
replace testnosuc=0 if testsuc==1

drop high_suc low_suc
rename testsuc high_suc
rename testnosuc low_suc


reghdfe high_suc  after##c.is_treated if pair_set_id!=., absorb(pair_set_id##date_for_panel company_domain_n apps##date_for_panel ai##date_for_panel ce##date_for_panel da##date_for_panel design##date_for_panel fs##date_for_panel game##date_for_panel hard##date_for_panel it##date_for_panel is##date_for_panel mt##date_for_panel mob##date_for_panel pay##date_for_panel plat##date_for_panel ps##date_for_panel soft##date_for_panel)  vce(cluster pair_set_id)
estimate store a5
gen esample=e(sample)
sum  high_suc if esample==1
drop esample

reghdfe low_suc  after##c.is_treated if pair_set_id!=., absorb(pair_set_id##date_for_panel company_domain_n apps##date_for_panel ai##date_for_panel ce##date_for_panel da##date_for_panel design##date_for_panel fs##date_for_panel game##date_for_panel hard##date_for_panel it##date_for_panel is##date_for_panel mt##date_for_panel mob##date_for_panel pay##date_for_panel plat##date_for_panel ps##date_for_panel soft##date_for_panel)  vce(cluster pair_set_id)
estimate store a6
sum low_suc
gen esample=e(sample)
sum  low_suc if esample==1
drop esample

esttab a1 a2 a3 a4 a5 a6, label replace booktabs title(Investor Heterogeneity) keep(1.after#c.is_treated) nobaselevels noconstant star(* 0.10 ** 0.05 *** 0.01) se stats(N r2 , labels("Observations" "R2")) compress, using Table10.tex
restore

**************************************
*Figures
**************************************

***************************************************************************************
*Figure 2: Startups' first engagements with OSCs on GitHub and rounds raised
****************************************************************************************


use "$main_directory\Crunchbase\Output\final_analyses", replace


preserve
gen raised_roundy=edate_round_announced_on==date_for_panel & yes_round==1
by company_domain_n (date_for_panel), sort: gen time=_n
by company_domain_n (date_for_panel), sort: gen cohort_treatment=_n if is_treated==1 & after==1
replace cohort_treatment=0 if cohort_treatment==.
by company_domain_n (date_for_panel), sort: egen cohort_treatment_min=min(cohort_treatment) if cohort_treatment>0
gen cohort_treatment2=cohort_treatment==cohort_treatment_min  


set scheme s1color
twoway (hist  time if cohort_treatment2==1, bin(20) color(red%40) density) ///
       (hist  time if raised_roundy==1, bin(20) color(blue%40) density) ///
	   , ///
	   legend(order(1 "Engaged with OSC for the first time" 2 "Raised round")) ///
	   xtitle("Quarters since startup inception", size(medsmall)) ///
	   ytitle("Density", size(medsmall))   ///
	   saving(histogram, replace)  
	   graph export figure_2_histogram.png, replace	
restore


***************************************************************************************
*Figure 3: Baseline Results - Event study for raising a first round
****************************************************************************************

use "$main_directory\Crunchbase\Output\final_analyses", replace


reghdfe raised_round ib99.years_to_treatment##c.is_treated if pair_set_id!=. & inrange(years_to_treatment, 96,107), absorb(pair_set_id date_for_panel company_domain_n)  vce(cluster pair_set_id)

coefplot, keep(*.years_to_treatment#c.is_treated) level(99) mcolor(black) ciopts(lcolor(black)) rename(*.years_to_treatment#c.is_treated="") vertical base omitted  yline(0,lcolor(black) lpattern(solid)) xline(5,lpattern(dash) lcolor(black)) scheme(s2color) ylabel(-0.04(0.04)0.24,grid  glcolor(gs15)) graphregion(fcolor(white) ifcolor(white) ilcolor(white))  xlabel(1 "-4" 2 "-3" 3 "-2" 4 "-1" 5 "0" 6 "1 " 7 "2 " 8 "3 " 9 "4" 10 "5 " 11 "6 " 12 " 7 ",grid  glcolor(gs15)) ytitle("Parameter estimate and 99% CI") xtitle("Quarters to/since engaging with OSCs")
	graph export "figure_3.pdf" , replace
	
***************************************************************************************
*Figure 4: Correlations between startup domains and technology use-cases on GitHubAI & Blockchain startups
****************************************************************************************

use "$main_directory\Crunchbase\Output\final_analyses", replace


bys company_domain_n: egen  ext_ui=max(ext_ui_q_bcum)
bys company_domain_n: egen  ext_productivity=max(ext_productivity_q_bcum)
bys company_domain_n: egen  ext_ml=max(ext_ml_q_bcum)
bys company_domain_n: egen  ext_api=max(ext_api_q_bcum)


gen out=is_treated==1 & (ext_ui==0 & ext_productivity==0 & ext_ml==0 & ext_api==0)
bys pair_set_id: egen max_out=max(out)


gen gh_type_crunAPI=""
replace gh_type_crunAPI="API" if regexm(company_category_list,"Application Performance Management")
replace gh_type_crunAPI="API" if regexm(company_category_list,"Developer APIs")
replace gh_type_crunAPI="API" if regexm(company_category_list,"Data Integration")
*



gen gh_type_crunUI=""
replace gh_type_crunUI="UI" if regexm(company_category_list,"Graphic Design") 
replace gh_type_crunUI="UI" if regexm(company_category_list,"Web Design") 
replace gh_type_crunUI="UI" if regexm(company_category_list,"Product Design")  
replace gh_type_crunUI="UI" if regexm(company_category_list,"Creative Agency") 
replace gh_type_crunUI="UI" if regexm(company_category_list,"UX Design") 
replace gh_type_crunUI="UI" if regexm(company_category_list,"Human Computer Interaction") 
replace gh_type_crunUI="UI" if regexm(company_category_list,"Augmented Reality") 
*


gen gh_type_crunML=""
replace gh_type_crunML="ML" if regexm(company_category_list,"Image Recognition")
replace gh_type_crunML="ML" if regexm(company_category_list,"Speech Recognition")
replace gh_type_crunML="ML" if regexm(company_category_list,"Natural Language Processing")
replace gh_type_crunML="ML" if regexm(company_category_list,"Virtual Currency")
replace gh_type_crunML="ML" if regexm(company_category_list,"Computer Vision")
replace gh_type_crunML="ML" if regexm(company_category_list,"Machine Learning")
replace gh_type_crunML="ML" if regexm(company_category_list,"Data Mining")
replace gh_type_crunML="ML" if regexm(company_category_list,"FinTech")
replace gh_type_crunML="ML" if regexm(company_category_list,"Analytics")
replace gh_type_crunML="ML" if regexm(company_category_list,"Blockchain")
replace gh_type_crunML="ML" if regexm(company_category_list,"Ethereum")
replace gh_type_crunML="ML" if regexm(company_category_list,"Text Analytics")
replace gh_type_crunML="ML" if regexm(company_category_list,"Assistive Technology")
replace gh_type_crunML="ML" if regexm(company_category_list,"Drone Management")
replace gh_type_crunML="ML" if regexm(company_category_list,"Autonomous Vehicles")
replace gh_type_crunML="ML" if regexm(company_category_list,"Fraud Detection")
replace gh_type_crunML="ML" if regexm(company_category_list,"Data Storage")
replace gh_type_crunML="ML" if regexm(company_category_list,"Cryptocurrency")
replace gh_type_crunML="ML" if regexm(company_category_list,"Quantum Computing")
replace gh_type_crunML="ML" if regexm(company_category_list,"Bitcoin")
replace gh_type_crunML="ML" if regexm(company_category_list,"Artificial Intelligence")
replace gh_type_crunML="ML" if regexm(company_category_list,"Big Data")
replace gh_type_crunML="ML" if regexm(company_category_list,"Predictive Analytics")
replace gh_type_crunML="ML" if regexm(company_category_list,"Data Center Automation")
replace gh_type_crunML="ML" if regexm(company_category_list,"Facial Recognition")
replace gh_type_crunML="ML" if regexm(company_category_list,"Data Visualization")
replace gh_type_crunML="ML" if regexm(company_category_list,"Drones")
*


gen gh_type_crunSD=""
replace gh_type_crunSD="SD/BE" if regexm(company_category_list,"Software Engineering")
replace gh_type_crunSD="SD/BE" if regexm(company_category_list,"Cloud Data Services")
replace gh_type_crunSD="SD/BE" if regexm(company_category_list,"Cloud Management")
replace gh_type_crunSD="SD/BE" if regexm(company_category_list,"Data Center")
replace gh_type_crunSD="SD/BE" if regexm(company_category_list,"SaaS")
replace gh_type_crunSD="SD/BE" if regexm(company_category_list,"IaaS")
replace gh_type_crunSD="SD/BE" if regexm(company_category_list,"Virtual Desktop")
replace gh_type_crunSD="SD/BE" if regexm(company_category_list,"ISP")
replace gh_type_crunSD="SD/BE" if regexm(company_category_list,"Usability Testing")
replace gh_type_crunSD="SD/BE" if regexm(company_category_list,"Cloud Security")
replace gh_type_crunSD="SD/BE" if regexm(company_category_list,"A/B Testing")
replace gh_type_crunSD="SD/BE" if regexm(company_category_list,"Developer Platform")
replace gh_type_crunSD="SD/BE" if regexm(company_category_list,"Developer Tools")
replace gh_type_crunSD="SD/BE" if regexm(company_category_list,"Content Delivery Network")
replace gh_type_crunSD="SD/BE" if regexm(company_category_list,"Open Source")
replace gh_type_crunSD="SD/BE" if regexm(company_category_list,"Web Development")
replace gh_type_crunSD="SD/BE" if regexm(company_category_list,"QR Codes")
replace gh_type_crunSD="SD/BE" if regexm(company_category_list,"Productivity Tools")
replace gh_type_crunSD="SD/BE" if regexm(company_category_list,"Cloud Computing")
replace gh_type_crunSD="SD/BE" if regexm(company_category_list,"Embedded Systems")
*


gen counter_api=gh_type_crunAPI=="API" 
gen counter_ui= gh_type_crunUI=="UI" & (gh_type_crunAPI!="API")
gen counter_ml= gh_type_crunML=="ML" & (gh_type_crunAPI!="API" & gh_type_crunUI!="UI"  & gh_type_crunSD!="SD/BE")
gen counter_sd= gh_type_crunSD=="SD/BE" & (gh_type_crunAPI!="API" & gh_type_crunUI!="UI"  & gh_type_crunML!="ML")

bys company_domain_n: egen  mext_ui=max(ext_ui_q_bcum)
bys company_domain_n: egen  mext_productivity=max(ext_productivity_q_bcum)
bys company_domain_n: egen  mext_ml=max(ext_ml_q_bcum)
bys company_domain_n: egen  mext_api=max(ext_api_q_bcum)


preserve
duplicates drop company_domain_n, force
sum mext_u mext_productivity mext_ml mext_api
reghdfe  mext_ui  counter_ml counter_ui counter_api counter_sd if pair_set_id!=., absorb(pair_set_id founding_year )  vce(cluster pair_set_id)
estimate store a1
reghdfe  mext_productivity  counter_ml counter_ui counter_api counter_sd if pair_set_id!=., absorb(pair_set_id founding_year)  vce(cluster pair_set_id)
estimate store a2
reghdfe  mext_ml  counter_ml counter_ui counter_api counter_sd if pair_set_id!=., absorb(pair_set_id founding_year)  vce(cluster pair_set_id)
estimate store a3
reghdfe  mext_api  counter_ml counter_ui counter_api counter_sd if pair_set_id!=., absorb(pair_set_id founding_year)  vce(cluster pair_set_id)
estimate store a4

summarize mext_ui, meanonly
scalar m_mext_ui_t= 1/r(mean)
coefplot a1,   transform(*="(@)*m_mext_ui_t") level(99)  nolabel drop(_cons) xline(0) msymbol(S) xtitle(Panel A: Engagement with external UI Repositories) coeflabels(counter_ml = "AI & Blockchain startups"; counter_ui  = "Consumer-facing startups" ; counter_api  = "Platform startups" ; counter_sd  = "Software tools startups") graphregion(fcolor(white) ifcolor(white) ilcolor(white)) saving(ui, replace)



summarize  mext_productivity, meanonly
scalar m_mext_productivity_t= 1/r(mean)
coefplot a2,   transform(*="(@)*m_mext_productivity_t") level(99)  nolabel drop(_cons) xline(0) msymbol(S) xtitle(Panel B: Engagement with external SD Repositories) coeflabels(counter_ml = "AI & Blockchain startups"; counter_ui  = "Consumer-facing startups" ; counter_api  = "Platform startups" ; counter_sd  = "Software tools startups")  graphregion(fcolor(white) ifcolor(white) ilcolor(white)) saving(sd, replace)


summarize  mext_ml, meanonly
scalar m_mext_ml_t= 1/r(mean)
coefplot a3,   transform(*="(@)*m_mext_ml_t") level(99)  nolabel drop(_cons) xline(0) msymbol(S) xtitle(Panel C: Engagement with external ML Repositories) coeflabels(counter_ml = "AI & Blockchain startups"; counter_ui  = "Consumer-facing startups" ; counter_api  = "Platform startups" ; counter_sd  = "Software tools startups") graphregion(fcolor(white) ifcolor(white) ilcolor(white)) saving(ml, replace)


summarize  mext_api, meanonly
scalar m_mext_api_t= 1/r(mean)
coefplot a4,   transform(*="(@)*m_mext_api_t") level(99)  nolabel drop(_cons) xline(0) msymbol(S) xtitle(Panel D: Engagement with external API Repositories) coeflabels(counter_ml = "AI & Blockchain startups"; counter_ui  = "Consumer-facing startups" ; counter_api  = "Platform startups" ; counter_sd  = "Software tools startups") graphregion(fcolor(white) ifcolor(white) ilcolor(white)) saving(api, replace)

graph combine ui.gph sd.gph ml.gph api.gph, cols(2) ycommon xcommon iscale(.5)
graph save activites_github, replace
graph export "$main_directory/figure_4.pdf", replace
restore


***************************************************************************************
*Figure 5: Relationship between engaging with OSCs and funding: By startup domain
****************************************************************************************

use "$main_directory\Crunchbase\Output\final_analyses", replace

bys company_domain_n: egen  ext_ui=max(ext_ui_q_bcum)
bys company_domain_n: egen  ext_productivity=max(ext_productivity_q_bcum)
bys company_domain_n: egen  ext_ml=max(ext_ml_q_bcum)
bys company_domain_n: egen  ext_api=max(ext_api_q_bcum)


gen out=is_treated==1 & (ext_ui==0 & ext_productivity==0 & ext_ml==0 & ext_api==0)
bys pair_set_id: egen max_out=max(out)


gen gh_type_crunAPI=""
replace gh_type_crunAPI="API" if regexm(company_category_list,"Application Performance Management")
replace gh_type_crunAPI="API" if regexm(company_category_list,"Developer APIs")
replace gh_type_crunAPI="API" if regexm(company_category_list,"Data Integration")
*

gen gh_type_crunUI=""
replace gh_type_crunUI="UI" if regexm(company_category_list,"Graphic Design") 
replace gh_type_crunUI="UI" if regexm(company_category_list,"Web Design") 
replace gh_type_crunUI="UI" if regexm(company_category_list,"Product Design")  
replace gh_type_crunUI="UI" if regexm(company_category_list,"Creative Agency") 
replace gh_type_crunUI="UI" if regexm(company_category_list,"UX Design") 
replace gh_type_crunUI="UI" if regexm(company_category_list,"Human Computer Interaction") 
replace gh_type_crunUI="UI" if regexm(company_category_list,"Augmented Reality") 
*


gen gh_type_crunML=""
replace gh_type_crunML="ML" if regexm(company_category_list,"Image Recognition")
replace gh_type_crunML="ML" if regexm(company_category_list,"Speech Recognition")
replace gh_type_crunML="ML" if regexm(company_category_list,"Natural Language Processing")
replace gh_type_crunML="ML" if regexm(company_category_list,"Virtual Currency")
replace gh_type_crunML="ML" if regexm(company_category_list,"Computer Vision")
replace gh_type_crunML="ML" if regexm(company_category_list,"Machine Learning")
replace gh_type_crunML="ML" if regexm(company_category_list,"Data Mining")
replace gh_type_crunML="ML" if regexm(company_category_list,"FinTech")
replace gh_type_crunML="ML" if regexm(company_category_list,"Analytics")
replace gh_type_crunML="ML" if regexm(company_category_list,"Blockchain")
replace gh_type_crunML="ML" if regexm(company_category_list,"Ethereum")
replace gh_type_crunML="ML" if regexm(company_category_list,"Text Analytics")
replace gh_type_crunML="ML" if regexm(company_category_list,"Assistive Technology")
replace gh_type_crunML="ML" if regexm(company_category_list,"Drone Management")
replace gh_type_crunML="ML" if regexm(company_category_list,"Autonomous Vehicles")
replace gh_type_crunML="ML" if regexm(company_category_list,"Fraud Detection")
replace gh_type_crunML="ML" if regexm(company_category_list,"Data Storage")
replace gh_type_crunML="ML" if regexm(company_category_list,"Cryptocurrency")
replace gh_type_crunML="ML" if regexm(company_category_list,"Quantum Computing")
replace gh_type_crunML="ML" if regexm(company_category_list,"Bitcoin")
replace gh_type_crunML="ML" if regexm(company_category_list,"Artificial Intelligence")
replace gh_type_crunML="ML" if regexm(company_category_list,"Big Data")
replace gh_type_crunML="ML" if regexm(company_category_list,"Predictive Analytics")
replace gh_type_crunML="ML" if regexm(company_category_list,"Data Center Automation")
replace gh_type_crunML="ML" if regexm(company_category_list,"Facial Recognition")
replace gh_type_crunML="ML" if regexm(company_category_list,"Data Visualization")
replace gh_type_crunML="ML" if regexm(company_category_list,"Drones")
*


gen gh_type_crunSD=""
replace gh_type_crunSD="SD/BE" if regexm(company_category_list,"Software Engineering")
replace gh_type_crunSD="SD/BE" if regexm(company_category_list,"Cloud Data Services")
replace gh_type_crunSD="SD/BE" if regexm(company_category_list,"Cloud Management")
replace gh_type_crunSD="SD/BE" if regexm(company_category_list,"Data Center")
replace gh_type_crunSD="SD/BE" if regexm(company_category_list,"SaaS")
replace gh_type_crunSD="SD/BE" if regexm(company_category_list,"IaaS")
replace gh_type_crunSD="SD/BE" if regexm(company_category_list,"Virtual Desktop")
replace gh_type_crunSD="SD/BE" if regexm(company_category_list,"ISP")
replace gh_type_crunSD="SD/BE" if regexm(company_category_list,"Usability Testing")
replace gh_type_crunSD="SD/BE" if regexm(company_category_list,"Cloud Security")
replace gh_type_crunSD="SD/BE" if regexm(company_category_list,"A/B Testing")
replace gh_type_crunSD="SD/BE" if regexm(company_category_list,"Developer Platform")
replace gh_type_crunSD="SD/BE" if regexm(company_category_list,"Developer Tools")
replace gh_type_crunSD="SD/BE" if regexm(company_category_list,"Content Delivery Network")
replace gh_type_crunSD="SD/BE" if regexm(company_category_list,"Open Source")
replace gh_type_crunSD="SD/BE" if regexm(company_category_list,"Web Development")
replace gh_type_crunSD="SD/BE" if regexm(company_category_list,"QR Codes")
replace gh_type_crunSD="SD/BE" if regexm(company_category_list,"Productivity Tools")
replace gh_type_crunSD="SD/BE" if regexm(company_category_list,"Cloud Computing")
replace gh_type_crunSD="SD/BE" if regexm(company_category_list,"Embedded Systems")
*


gen counter_api=gh_type_crunAPI=="API" 
gen counter_ui= gh_type_crunUI=="UI" & (gh_type_crunAPI!="API")
gen counter_ml= gh_type_crunML=="ML" & (gh_type_crunAPI!="API" & gh_type_crunUI!="UI"  & gh_type_crunSD!="SD/BE")
gen counter_sd= gh_type_crunSD=="SD/BE" & (gh_type_crunAPI!="API" & gh_type_crunUI!="UI"  & gh_type_crunML!="ML")

bys company_domain_n: egen  mext_ui=max(ext_ui_q_bcum)
bys company_domain_n: egen  mext_productivity=max(ext_productivity_q_bcum)
bys company_domain_n: egen  mext_ml=max(ext_ml_q_bcum)
bys company_domain_n: egen  mext_api=max(ext_api_q_bcum)


preserve
reghdfe raised_round  after##c.counter_ml after##c.counter_sd after##c.counter_ui after##c.counter_api c.external_q_bcum c.external_q_bcum##c.counter_ml c.external_q_bcum##c.counter_ui c.external_q_bcum##c.counter_sd c.external_q_bcum##c.counter_api  if pair_set_id!=., absorb(pair_set_id date_for_panel#counter_sd date_for_panel#counter_ml date_for_panel#counter_api date_for_panel#counter_ui company_domain_n)  vce(cluster pair_set_id)
estimate store a1


summarize  raised_round, meanonly
scalar m_raised_round= 1/r(mean)
coefplot a1,   transform(*="(@)*m_raised_round") level(99) nolabel drop(_cons) xline(0) msymbol(S) xtitle(Coefficient and 99% CI) coeflabels(1.after="Post GitHub"; 1.after#c.counter_ml="Post GitHub x AI & Blockchain"; 1.after#c.counter_sd="Post GitHub x Software tools"; 1.after#c.counter_ui="Post GitHub x Consumer-facing"; 1.after#c.counter_api="Post GitHub x Platform"; external_q_bcum="Eng.WithOSC"; c.external_q_bcum#c.counter_ml  = "Post GitHub x Eng.WithOSC x AI & Blockchain"; c.external_q_bcum#c.counter_ui  = "Post GitHub x Eng.WithOSC x Consumer-facing"; c.external_q_bcum#c.counter_api  = "Post GitHub x Eng.WithOSC x Platform" ; c.external_q_bcum#c.counter_sd  = "Post GitHub x Eng.WithOSC x Software tools") graphregion(fcolor(white) ifcolor(white) ilcolor(white)) saving(panel, replace)
graph export "$main_directory/figure_5.pdf", replace
restore



***************************************************************************************
*Figure 6: Relationship between engaging with OSCs and funding: By technology use-cases
****************************************************************************************

use "$main_directory\Crunchbase\Output\final_analyses", replace

bys company_domain_n: egen  ext_ui=max(ext_ui_q_bcum)
bys company_domain_n: egen  ext_productivity=max(ext_productivity_q_bcum)
bys company_domain_n: egen  ext_ml=max(ext_ml_q_bcum)
bys company_domain_n: egen  ext_api=max(ext_api_q_bcum)


gen out=is_treated==1 & (ext_ui==0 & ext_productivity==0 & ext_ml==0 & ext_api==0)
bys pair_set_id: egen max_out=max(out)


gen gh_type_crunAPI=""
replace gh_type_crunAPI="API" if regexm(company_category_list,"Application Performance Management")
replace gh_type_crunAPI="API" if regexm(company_category_list,"Developer APIs")
replace gh_type_crunAPI="API" if regexm(company_category_list,"Data Integration")
*

gen gh_type_crunUI=""
replace gh_type_crunUI="UI" if regexm(company_category_list,"Graphic Design") 
replace gh_type_crunUI="UI" if regexm(company_category_list,"Web Design") 
replace gh_type_crunUI="UI" if regexm(company_category_list,"Product Design")  
replace gh_type_crunUI="UI" if regexm(company_category_list,"Creative Agency") 
replace gh_type_crunUI="UI" if regexm(company_category_list,"UX Design") 
replace gh_type_crunUI="UI" if regexm(company_category_list,"Human Computer Interaction") 
replace gh_type_crunUI="UI" if regexm(company_category_list,"Augmented Reality") 
*


gen gh_type_crunML=""
replace gh_type_crunML="ML" if regexm(company_category_list,"Image Recognition")
replace gh_type_crunML="ML" if regexm(company_category_list,"Speech Recognition")
replace gh_type_crunML="ML" if regexm(company_category_list,"Natural Language Processing")
replace gh_type_crunML="ML" if regexm(company_category_list,"Virtual Currency")
replace gh_type_crunML="ML" if regexm(company_category_list,"Computer Vision")
replace gh_type_crunML="ML" if regexm(company_category_list,"Machine Learning")
replace gh_type_crunML="ML" if regexm(company_category_list,"Data Mining")
replace gh_type_crunML="ML" if regexm(company_category_list,"FinTech")
replace gh_type_crunML="ML" if regexm(company_category_list,"Analytics")
replace gh_type_crunML="ML" if regexm(company_category_list,"Blockchain")
replace gh_type_crunML="ML" if regexm(company_category_list,"Ethereum")
replace gh_type_crunML="ML" if regexm(company_category_list,"Text Analytics")
replace gh_type_crunML="ML" if regexm(company_category_list,"Assistive Technology")
replace gh_type_crunML="ML" if regexm(company_category_list,"Drone Management")
replace gh_type_crunML="ML" if regexm(company_category_list,"Autonomous Vehicles")
replace gh_type_crunML="ML" if regexm(company_category_list,"Fraud Detection")
replace gh_type_crunML="ML" if regexm(company_category_list,"Data Storage")
replace gh_type_crunML="ML" if regexm(company_category_list,"Cryptocurrency")
replace gh_type_crunML="ML" if regexm(company_category_list,"Quantum Computing")
replace gh_type_crunML="ML" if regexm(company_category_list,"Bitcoin")
replace gh_type_crunML="ML" if regexm(company_category_list,"Artificial Intelligence")
replace gh_type_crunML="ML" if regexm(company_category_list,"Big Data")
replace gh_type_crunML="ML" if regexm(company_category_list,"Predictive Analytics")
replace gh_type_crunML="ML" if regexm(company_category_list,"Data Center Automation")
replace gh_type_crunML="ML" if regexm(company_category_list,"Facial Recognition")
replace gh_type_crunML="ML" if regexm(company_category_list,"Data Visualization")
replace gh_type_crunML="ML" if regexm(company_category_list,"Drones")
*


gen gh_type_crunSD=""
replace gh_type_crunSD="SD/BE" if regexm(company_category_list,"Software Engineering")
replace gh_type_crunSD="SD/BE" if regexm(company_category_list,"Cloud Data Services")
replace gh_type_crunSD="SD/BE" if regexm(company_category_list,"Cloud Management")
replace gh_type_crunSD="SD/BE" if regexm(company_category_list,"Data Center")
replace gh_type_crunSD="SD/BE" if regexm(company_category_list,"SaaS")
replace gh_type_crunSD="SD/BE" if regexm(company_category_list,"IaaS")
replace gh_type_crunSD="SD/BE" if regexm(company_category_list,"Virtual Desktop")
replace gh_type_crunSD="SD/BE" if regexm(company_category_list,"ISP")
replace gh_type_crunSD="SD/BE" if regexm(company_category_list,"Usability Testing")
replace gh_type_crunSD="SD/BE" if regexm(company_category_list,"Cloud Security")
replace gh_type_crunSD="SD/BE" if regexm(company_category_list,"A/B Testing")
replace gh_type_crunSD="SD/BE" if regexm(company_category_list,"Developer Platform")
replace gh_type_crunSD="SD/BE" if regexm(company_category_list,"Developer Tools")
replace gh_type_crunSD="SD/BE" if regexm(company_category_list,"Content Delivery Network")
replace gh_type_crunSD="SD/BE" if regexm(company_category_list,"Open Source")
replace gh_type_crunSD="SD/BE" if regexm(company_category_list,"Web Development")
replace gh_type_crunSD="SD/BE" if regexm(company_category_list,"QR Codes")
replace gh_type_crunSD="SD/BE" if regexm(company_category_list,"Productivity Tools")
replace gh_type_crunSD="SD/BE" if regexm(company_category_list,"Cloud Computing")
replace gh_type_crunSD="SD/BE" if regexm(company_category_list,"Embedded Systems")
*


gen counter_api=gh_type_crunAPI=="API" 
gen counter_ui= gh_type_crunUI=="UI" & (gh_type_crunAPI!="API")
gen counter_ml= gh_type_crunML=="ML" & (gh_type_crunAPI!="API" & gh_type_crunUI!="UI"  & gh_type_crunSD!="SD/BE")
gen counter_sd= gh_type_crunSD=="SD/BE" & (gh_type_crunAPI!="API" & gh_type_crunUI!="UI"  & gh_type_crunML!="ML")

bys company_domain_n: egen  mext_ui=max(ext_ui_q_bcum)
bys company_domain_n: egen  mext_productivity=max(ext_productivity_q_bcum)
bys company_domain_n: egen  mext_ml=max(ext_ml_q_bcum)
bys company_domain_n: egen  mext_api=max(ext_api_q_bcum)

preserve

gen after_api=ext_api_q_bcum>0
bysort pair_set_id date_for_panel: egen Aafter_api= max(after_api)

gen after_ui=ext_ui_q_bcum>0
bysort pair_set_id date_for_panel: egen Aafter_ui= max(after_ui)

gen after_productivity=ext_productivity_q_bcum>0
bysort pair_set_id date_for_panel: egen Aafter_productivity= max(after_productivity)

gen after_ml=ext_ml_q_bcum>0
bysort pair_set_id date_for_panel: egen Aafter_ml= max(after_ml)

gen ext_other_q_bcum=external_q_bcum==1 & (ext_ui_q_bcum==0 & ext_productivity_q_bcum==0 & ext_ml_q_bcum==0 & ext_api_q_bcum==0 )

gen after_other=ext_other_q_bcum>0
bysort pair_set_id date_for_panel: egen Aafter_other= max(after_other)



reghdfe raised_round  after ext_ui_q_bcum ext_productivity_q_bcum ext_ml_q_bcum ext_api_q_bcum ext_other_q_bcum if pair_set_id!=. , absorb(pair_set_id date_for_panel#counter_sd date_for_panel#counter_ml date_for_panel#counter_api date_for_panel#counter_ui company_domain_n)  vce(cluster pair_set_id)
estimate store a1

summarize  raised_round if e(sample)==1, meanonly
scalar m_raised_round= 1/r(mean)

coefplot a1,   transform(*="(@)*m_raised_round") level(99) nolabel drop(_cons) xline(0) msymbol(S) xtitle(Panel A: All startups) keep(ext_ui_q_bcum ext_productivity_q_bcum ext_ml_q_bcum ext_api_q_bcum) coeflabels(after="Post GitHub"; ext_api_q_bcum  = "Post GitHub x Eng.WithAPI"; ext_ui_q_bcum  = "Post GitHub x Eng.WithUI"; ext_productivity_q_bcum  = "Post GitHub x Eng.WithSD" ; ext_ml_q_bcum  = "Post GitHub x Eng.WithML" ) graphregion(fcolor(white) ifcolor(white) ilcolor(white)) saving(all, replace)


*****
reghdfe raised_round after ext_ui_q_bcum ext_productivity_q_bcum ext_ml_q_bcum ext_api_q_bcum ext_other_q_bcum if pair_set_id!=. & counter_ml==1, absorb(pair_set_id date_for_panel#counter_sd date_for_panel#counter_ml date_for_panel#counter_api date_for_panel#counter_ui company_domain_n)  vce(cluster pair_set_id)
estimate store a2

summarize  raised_round if e(sample)==1, meanonly
scalar m_raised_round= 1/r(mean)

coefplot a2,   transform(*="(@)*m_raised_round") level(99) nolabel drop(_cons) xline(0) msymbol(S) xtitle(Panel B: AI & Blockchain) keep(ext_ui_q_bcum ext_productivity_q_bcum ext_ml_q_bcum ext_api_q_bcum) coeflabels(after="Post GitHub"; ext_api_q_bcum  = "Post GitHub x Eng.WithAPI"; ext_ui_q_bcum  = "Post GitHub x Eng.WithUI"; ext_productivity_q_bcum  = "Post GitHub x Eng.WithSD" ; ext_ml_q_bcum  = "Post GitHub x Eng.WithML" ) graphregion(fcolor(white) ifcolor(white) ilcolor(white)) saving(ml, replace)


graph combine  all.gph ml.gph , cols(2) ycommon xcommon iscale(.5)
graph save use_cases_impact, replace
graph export "$main_directory/figure_6.pdf", replace

restore
