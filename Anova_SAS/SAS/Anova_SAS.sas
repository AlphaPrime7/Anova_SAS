/******************
Written by:Tingwei Adeck
Date: October 10th 2022
Description: Data for one-way anova with post-hoc analysis. Check for assumptions before running ANOVA
In this case assumptions are met. Power level should be good using the scheffe' post-hoc test.

Input: anova.sav
Output: Anova_SAS.pdf
******************/

%let path=/home/u40967678/sasuser.v94;

filename anova
	"&path/biostats/anova/anova.sav";
	
libname OANOVA
	"/home/u40967678/sasuser.v94/biostats/anova";	
	
ods pdf file=
    "&path/sas_umkc/output/Anova_SAS.pdf";
    
options papersize=(8in 4in) nonumber nodate;


proc import file= anova
    out=oanova.anova
    dbms=SAV
    replace;
run;

proc print data=oanova.anova (obs=5);
run;

    
proc format; /*if else formatting can be used here*/
   value wgformat
     low-100 = 1
     101-125 = 2
     126-150 = 3
     151-175 = 4
     176-200 = 5
     201-high = 6;
run;

data oanova.anova_recode;
    set oanova.anova;
    Weight_group_recode = put(Weight, wgformat.);
run;
	
/*
title "Anova model using PROC GLM with levene's test for homoscedasticity (Weight-Cholesterol)";
proc glm data=oanova.anova plots=diagnostics;
class Weight_group;
model Cholesterol = Weight_group;
output out = wgout r = residual;
means Weight_group / hovtest=levene(type=abs) welch;
means Weight_group / LSD; /*the more powerful post-hoc test
lsmeans Weight_group /pdiff adjust=tukey plot=meanplot(connect cl) lines;
run;
ods graphics off;
*/


/*perform one-way ANOVA (Wg vs Cholesterol) with Scheffe's post-hoc test*/
title "Anova using PROC ANOVA (Weight-Cholesterol)";
proc ANOVA data=oanova.anova;
class Weight_group;
model Cholesterol = Weight_group;
means Weight_group / scheffe cldiff;
run;

/*perform one-way ANOVA (Wg_num vs Cholesterol) with Scheffe's post-hoc test*/
title "Anova using PROC ANOVA (Weight_num-Cholesterol)";
proc ANOVA data=oanova.anova_recode;
class Weight_group_recode;
model Cholesterol = Weight_group_recode;
means Weight_group_recode / scheffe cldiff; 
run;



/*the first step to writing a macro that can help with outliers in each group
1. have the first step in a format that can be iterated over
2. Use a proc sql statement to get cholesterol values for each i(wg iterand)
3. Calculate IQ ranges and use that to detect outliers then remove them
3.5 Use a union join to then rejoin the data and have a dataset without outliers
4. Follow up later on this macro project
*/
proc sql;
    select distinct(Weight_group)
    from oanova.anova;
quit;

/*dealing with outliers in base SAS*/
/*verfiy outliers with Outliers = Observations > Q3 + 1.5*IQR  or < Q1 – 1.5*IQR*/

%macro ODSOff(); /* Call prior to BY-group processing */
ods graphics off;
ods exclude all;
ods noresults;
%mend;
 
%macro ODSOn(); /* Call after BY-group processing */
ods graphics on;
ods exclude none;
ods results;
%mend;

/*exclude showing everything here but data is in the pdf*/
%ODSOff
ods output sgplot= oanova.Output;   
proc sgplot data=oanova.anova;
    vbox Cholesterol / category=Weight_group group=Weight_group;
    keylegend / title="Weight_group" location=inside position=topleft across=1;
run;

%ODSOn
/*view updated dataset*/
proc print data=oanova.output (OBS=10);

/*some hardcoding in removing outliers*/
data oanova.Anova_no_outliers;
    set oanova.anova_recode;
    if Cholesterol >= 292.0 or Cholesterol < 150 and Weight_group_recode =6 then delete;
    if Cholesterol >= 300.0 and Weight_group_recode =5 then delete;
    if Cholesterol >= 300.0 or Cholesterol < 50 and Weight_group_recode =3 then delete;
run;

/*check >201 for outlier dropped*/
proc sgplot data=oanova.Anova_no_outliers;
    vbox Cholesterol / category=Weight_group_recode group=Weight_group;
    keylegend / title="Weight_group" location=inside position=topleft across=1;
run;

ods pdf close;

