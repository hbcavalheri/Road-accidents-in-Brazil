
## Goal

Few countries include road safety management as a regular activity and/or dedicate budget for safety road programms. Brazil is the fourth country with the highest rate of fatalities in traffic accidents and despite some effort, there is no initiative from the government to create a serious program that would allow road satefy measuments to be applied on a regular basis. 

Thus, in this project I propose to develop a computer model that identifies the probability of road accidents at certain times and locations on federal roadways in Brazil. The model will be trained using historical data collected over the past ten years by the highway patrol. This data include details of each accident that happened in federal roads in Brazil, including, weather, time, type of road, number of vehicles involved as well as victims. Furthermore, in since 2017 coordinates have started to be included, which refines even more location.  


## Downloading the data

Data was downloaded in csv format from Brazilian Highway Patrol website (https://www.prf.gov.br/portal/dados-abertos/acidentes). Data cleaning was performed to ensure that variables had the same classification across all data sets and the categories were translated to English. 

The code containing all data cleaning 'data_cleaning.R' is included on Github.

Map data was downloaded from the National Department of Transportation website (http://www.dnit.gov.br/sistema-nacional-de-viacao/sistema-nacional-de-viacao).

