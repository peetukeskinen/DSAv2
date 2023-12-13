# Debt Sustainability Analysis (DSA) tool	
### Version 2

This repository contains Debt Sustainability Analysis (DSA) tool used in chapter 3 of Fiscal Policy Monitoring Report 2023 published by NAOF's Fiscal Policy Monitoring Unit. 
The code was successfully run with Windows 10 (64-bit) and MATLAB R2020b. The files needed to run the MATLAB code are:

#### i.	main code file DSAmodelCleanFinal.m,
#### ii.	helper function project_debt2v.m to project debt paths given yearly adjustment,
#### iii.	data file AmecoFinlandDataFinal.xlsx.

The main code DSAmodelCleanFinal.m calculates minimum yearly adjustment for four-year adjustment plan for Finland considering only criteria A (debt must be continuously declining during the 10-year period 2028-2038). Resulting output and graphs are saved in the current folder as .txt and .png files.
 
The main code produces debt projections following the implementation of the European Commission's Debt Sustainability Monitor 2022 published in April 2023. Scenarios in the code are defined as in Commission’s proposal published in May 2023 and information based on publicly available sources. In the current MATLAB implementation, I have extensively followed [analysis](https://www.bruegel.org/working-paper/quantitative-evaluation-european-commissions-fiscal-governance-proposal) and [Python code](https://github.com/lennardwelslau/eu-debt-sustainability-analysis) made by Darvas et al. (2023).

Currently, two scenarios are available: baseline adjustment scenario and lower structural primary balance (SPB) scenario. Also, stock-flow-adjustment (SFA) method can be chosen to follow Commission assumption, or an alternative assumption based on linearly declining SFA. Selection for scenario and SFA method can be made in the main code on the line 51 and 55. Parameter section sets the parameter values to match those values chosen by European Commission. User can modify parameter values to do sensitivity testing.

Main code runs by default baseline adjustment scenario with Commission SFA method. Running DSAmodelCleanFinal.m produces total of four figures. Figures included in the report are figure 1 (panel a, b), figure 4 for both scenarios 1 and 2. Only for scenario 1, figure 3 is included. Range and step size of the values for adjustment can be modified on the lines 76 and 77 (variables step_size and a). In the report, the following setting were used: 

#### i.	Figure 1ab: step_size=0.01, a= -0.5…1 (scenario 1 and 2, SFA method 0)	
#### ii.	Figure 3: step_size=0.1, a= -0.5…1 (scenario 1, SFA method 0)
#### iii.	Figure 4: step_size=0.1, a= -1…1 (scenario 1, SFA method -1 and 0)

AmecoFinlandDataFinal.xlsx contains all the necessary data to run the main code. Tab COM in the Excel file contains data and tab DataSources describes the data sources and some clarifying definitions. COM data is from Commission 2023 spring forecast round. All data is from publicly available sources expect financial market data which cannot be shared and must be separately downloaded via a Bloomberg Terminal. AMECO data can be accessed here. Variables can be found using AMECO variable codes listed in the Excel file under the tab DataSources (e.g. FIN.1.0.0.0.AYIGD). COM projections for some variables can be found here.


For comments and suggestions, please contact peetu.keskinen@vtv.fi.
