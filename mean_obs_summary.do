
clear * //clear everything including macros and matrices
*************************************
* specify data to be used
use mos, clear 
*************************************


*************************************
* build primary macros
*************************************
* order all variables in alphabetical order
order(*), alpha 

* create macro r(varlist) that contains the names for all variables NOT including yearmonth 
ds yearmonth, not 

* main_vars local is a simple list of the main_vars
local main_vars `r(varlist)' 

* get the number of variables in dataset NOT including yearmonth
local n_vars: word count `r(varlist)' 

*************************************
* dynamic collapse 
*************************************

* establish blank macros
local meanx 
local countx 

* loop through main variables and create a list ready to be fed into the collapse command
* ex: variable 'prc' will generate 'mprc=prc'; variable 'div' will gen 'mdiv=div'
foreach var in `main_vars'{
	local meanx `meanx' m`var'=`var'
	local countx `countx' c`var'=`var'
}

* collapse with dataset by month feeding in formatted meanx and countx strings
collapse (mean) `meanx' (count) `countx', by(yearmonth) 

*************************************
*************************************

*************************************
* create the table from a matrix
*************************************

* --Month--
* generate a formatted string version of the month
generate month_string = string(yearmonth, "%tmMonCCYY")

* generate a local 'levels' that stores each entry from the formatted string month variable
levelsof month_string, local(levels) clean sep(" ")
drop month_string

* --Matrixing--
* save each variable as an individual vector and clear out the dataset
* ex: if main vars are 'prc' and 'div', we will have matrices: mprc cprc mdiv cdiv
mkmat *
clear

* loop through main variables to create list that will be used to create the matrix holding values
* ex: main vars 'prc' and 'div' will gen the following string:  
* " mprc' \ cprc' \ mdiv' \ cdiv' "
* the ' mark transpose the vector to a row
* the \ concatenates the vectors
local matvars
foreach var in `main_vars'{
	local matvars `matvars' m`var''\
	local matvars `matvars' c`var''\
}
* we chop off the final '\'
local matvars = substr("`matvars'",1,length("`matvars'")-1)

* create a big matrix that contains each variables 'm' and 'c' summary statistic variables
* ex: matvars = " mprc' \ cprc' \ mdiv' \ cdiv' "
mat results = `matvars'

* name each variable in the matrix with the formatted string month
mat colnames results = `levels'

* print the matrix to the datasheet with the column names fo months
svmat results, names(col)

*************************************
* final formatting
*************************************

* count to get r(N)
count

* --Summary Statistics--
* replace blank summary statistic with "Mean" for every other row
gen summary_statistic = ""
forvalues i = 1(2)`r(N)'{
	replace summary_statistic = "Mean" if _n==`i'

}
* replace blank summary statistic with "N" for every other row
count
forvalues i = 2(2)`r(N)'{
	replace summary_statistic = "N" if _n==`i'
}

* --Variable--
* we have macro 'main_vars'; ex: 'prc shr div' indexed as '1 2 3'
* but we want to map these to every other row on the results table (because we have Mean and N for each variable)
* so we need to map main_vars[1]:results[1], main_vars[2]:results[3], main_vars[3]:results[5]
* to get the second index for results we get a sequence of numbers that counts by 2 until _N
numlist "1(2)`r(N)'"
local seq2 "`r(numlist)'"

count
gen variable = ""
* now we loop through the by-2 sequence and main_vars until we get to the end of main_vars
forvalues i = 1/`n_vars'{
	* ex: word 2 of main_vars would be the second variable
	local a : word `i' of `main_vars'
	* ex: word 2 of seq2 would be the number '3'
	local b : word `i' of `seq2'
	* ex: replace variable with the second variable on row 3
	replace variable = "`a'" if _n==`b'
}

* order the variables
order(variable summary_statistic)

* export to excel
export excel using "results", firstrow(variables) replace

