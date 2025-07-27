# CNMI-GVAA-Data-Processing
R Code for processing Ground Validation imagery and positioning data collected in Tinian and Saipan during 2025 field work 

## CNMI_Subsonus_process.R
This code will: 
* Read the RemoteTrack.csv extracted from an Advanced Navigation Subsonus ANPP Log and create a dataframe with selected columns,
* Create a point shapefile of position data for both the Local XY (Subsonus) and the Remote XY (Subsonus Tag or Hydrus), and 
* Zip the point shapefiles for Remote and Local individually
