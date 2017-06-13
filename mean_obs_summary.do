
clear * //clear everything including macros and matrices
*************************************
* specify data to be used
use mos, clear 
*************************************
order(*), alpha 
ds yearmonth, not 
local main_vars `r(varlist)' 
local ovars `r(varlist)' `r(varlist)' 
local ovars_len: word count `r(varlist)' 

* build dynamic collapse 
local meanx 
local countx 
foreach var in `main_vars'{
	local meanx `meanx' m`var'=`var'
	local countx `countx' c`var'=`var'
}

local matvars
foreach var in `main_vars'{
	local matvars `matvars' m`var''\
	local matvars `matvars' c`var''\
}
local matvars = substr("`matvars'",1,length("`matvars'")-1)

collapse (mean) `meanx' (count) `countx', by(yearmonth) 

generate month_string = string(yearmonth, "%tmMonCCYY")
levelsof month_string, local(levels) clean sep(" ")
drop month_string

mkmat *
clear
mat results = `matvars'
mat colnames results = `levels'
svmat results, names(col)

count
gen summary_statistic = ""
forvalues i = 1(2)`r(N)'{
	replace summary_statistic = "Mean" if _n==`i'

}

count
forvalues i = 2(2)`r(N)'{
	replace summary_statistic = "N" if _n==`i'
}

count
gen variable = ""
numlist "1(2)`r(N)'"
local zz "`r(numlist)'"

forvalues i = 1/`ovars_len'{
	local a : word `i' of `ovars'
	local b : word `i' of `zz'
	replace variable = "`a'" if _n==`b'
}

order(variable summary_statistic)

export excel using "results", firstrow(variables) replace

