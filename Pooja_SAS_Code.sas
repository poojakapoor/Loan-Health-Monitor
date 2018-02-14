*Step 1: Import the file;
PROC IMPORT datafile = "S:\Project 423\Loan_Pooja.csv" out = loan replace;
delimiter=','; 
datarow = 2;
getnames = yes;
RUN;


*Step 2: Get 1000 records;
proc surveyselect data=loan seed=13579 samprate=0.2645 out=loan_new;
run;


*Step 3: Create Dummy Variables;
*Grade;
data loan_new;
set loan_new;
medium_grade= (grade="Medium");
bad_grade= (grade="Bad");
run;

*Home_Ownership;
data loan_new;
set loan_new;
mortgage_home= (home_ownership="MORTGAGE");
rent_home = (home_ownership= "RENT");
run;

*Loan_status;
data loan_new;
set loan_new;
loan_status_new = 0;
if loan_status = "Default" then loan_status_new= 1;
run;

*Purpose;
data loan_new;
set loan_new;
car_purpose= (purpose= "car");
credit_card_purpose= (purpose= "credit_card");
run;
proc print;
run;


*Step 4: Fit the Model, Check for diagnostics (Multicollinearity, Outliers, Influential Points);
proc logistic data=loan_new;
model loan_status_new(event='1')=loan_amnt term int_rate medium_grade bad_grade emp_length mortgage_home rent_home annual_inc car_purpose credit_card_purpose tot_cur_bal /stb corrb influence iplots;
run;

*Step 5: Split the data;
proc surveyselect data=loan_new out=train seed=232323
samprate=0.75 outall;
run;
 
proc print data=train;
run;
* check to see if the train/test split was done correctly;
Title 'Split the data';
proc freq data=train;
tables selected;
run;
*Step 6: Create New Variable (Y);
*create new variable new_y = Loan_Status_1 for training set, and = NA for testing set;
data train;
set train;
if selected then train_y=loan_status_new;
run;

proc print data=train;
run;
*Step 7: Run Selection Method on the model with new Y variable;
*run selection method on training set, use train_y instead of Loan_status_new variable/ Stepwise;
Title 'Model Selection on Training:Stepwise';
proc logistic data=train;
model train_y(event='1')=loan_amnt term int_rate medium_grade bad_grade emp_length mortgage_home rent_home annual_inc car_purpose credit_card_purpose tot_cur_bal /selection= stepwise;
Run;

Title 'Model Selection on Training:Backward';
proc logistic data=train;
model train_y(event='1')=loan_amnt term int_rate medium_grade bad_grade emp_length mortgage_home rent_home annual_inc car_purpose credit_card_purpose tot_cur_bal /selection= backward;
Run;

Title 'Model Selection on Training:Forward';
proc logistic data=train;
model train_y(event='1')=loan_amnt term int_rate medium_grade bad_grade emp_length mortgage_home rent_home annual_inc car_purpose credit_card_purpose tot_cur_bal /selection= forward;
Run;

Title 'Model Selection on Training: Influential Predictor ';
proc logistic data=train;
model train_y(event='1')=int_rate emp_length mortgage_home /stb;
Run;

*Step 8: fit the final model, compute predicted value on training set, obtain the cut-off value for p;
Title 'Fit the Final Model for Training ';
proc logistic data=train;
model train_y(event='1')= int_rate emp_length mortgage_home /ctable pprob= (0.2 to 0.75 by 0.050);
*save predictions in sas dataset "pred";
output out=pred(where=(train_y=.))  p=phat lower=lcl upper=ucl
             predprob=(individual);
run;
proc print data= probs;
run;
Title 'Classification matrix';
data probs;
set pred;
pred_dis=0;
threshold=0.250; *modify threshold here;
if phat>threshold then pred_dis=1;
run;
* compute classification matrix;
proc freq data=probs;
tables loan_status_new*pred_dis/norow nocol nopercent;
run;

