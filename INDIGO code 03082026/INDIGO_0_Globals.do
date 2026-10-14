////////////////////////////////////////////////////////////////////////////////
/* //=========================================================================//
	INDIGO Data Cleaning: Globals
	Author: Ciel Burges
	Started: 05/01/2026
	Date of extract: 17/12/2025
	Stata 19
*/ //=========================================================================//
////////////////////////////////////////////////////////////////////////////////

* INDIGO_0_Globals.do: 
	* Creats global path ways to be referenced in later .do files
	* Folders must be created first.
	
* This script was developed in STATA 18
version 18


////////////////////////////////////////////////////////////////////////////////
* Setting Up STATA Environment 
////////////////////////////////////////////////////////////////////////////////

** GLOBALS **
clear
cap log close
set more off
set linesize 85

* Globals for code and output
global code "$wd\code"
global out "$wd\out"
	global tabs "$wd\tabs"
	//global plots "$out\plots"
	global logs "$out\logs"
global raw "$wd\raw"
global queries "$wd\queries"

* Set global pathways and definitions
global extractdate = 12022026
global data_entry_date="12/02/2026"

