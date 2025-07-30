# Import Libraries
library(dplyr)
library(raster)
library(sf)
library(zip)

# Read Subsonus Log and extract the relevant columns
# Create a shaefile and zip the shapefile
#This section of code will be to parse data from the Subsonus log file

# Changes:
# write filename as UTC time

# User entered UTC date as "MMDDYYYY"
UTC_date <- "07272025"

# Set the working directory to the Subsonus log folder
setwd(file.path("D:/CNMI", UTC_date, "Subsonus", paste0("subsonus_log_", UTC_date)))
getwd()

# Create "Zip" directory if it does not exist
if (!dir.exists("Zip")) {
  dir.create("Zip")
}

# Get the list of folders in the directory
subsonus_folders <- list.dirs(path = getwd(), full.names = TRUE, recursive = FALSE)
# Print the folder names
print(subsonus_folders)
# Extract the folder names without the full path
folder_names <- basename(subsonus_folders)
# Print the folder names
print(folder_names)

# Create an empty dataframe to store the Subsonus log data
subsonus_log_df <- data.frame()

# Create for loop to iterate through the folders to generate shapefiles and zip them
for (folder in subsonus_folders) {
  # Extract the log number and date from the folder name
  log_number <- sub(".*_(\\d{6})_.*", "\\1", folder)
  log_date <- sub(".*_(\\d{4}_\\d{2}_\\d{2})_.*", "\\1", folder)
  
  # Print the log number and date
  print(paste("Log Number:", log_number))
  print(paste("Log Date:", log_date))
  # Create filename based on log number and date for Local and Remote position data
  subsonus_log_filename <- paste0("LocalTrack_", log_number,"_", log_date)
  subsonus_tag_log_filename <- paste0("RemoteTrack_", log_number,"_", log_date)
  
  # Read the Subsonus log csv file
  RemTrack_files <- list.files(path = folder, pattern = "RemoteTrack")
  # Check if the file exists
  if (length(RemTrack_files) == 0) {
    print(paste("No LocalTrack file found in", folder))
    next
  }
  
  for(file in RemTrack_files) {
    print(paste("Processing file:", file))
    # Get the basename of the file
    file_basename <- tools::file_path_sans_ext(basename(file))
    # Parse the number at the end of the basename using "_"
    file_number <- sub(".*_(\\d+)$", "\\1", file_basename)
    
    # Read the Subsonus log file
    subsonus_log <- read.csv(file.path(folder, file), header = TRUE)
    # Extract the relevant columns
    subsonus_data <- subsonus_log %>%
      dplyr::select(Human.Timestamp, Local.Latitude, Local.Longitude, Remote.Position.Corrected.X, Remote.Position.Corrected.Y, Remote.Position.Corrected.Z,
                    Remote.Depth, Remote.Height, Remote.Latitude, Remote.Longitude)
    # Convert the Human.Timestamp to POSIXct
    timestamp_clean <- sub(" PDT", "", subsonus_data$Human.Timestamp)
    subsonus_data$Human.Timestamp.convert <- as.POSIXct(timestamp_clean, format = "%a %b %d %H:%M:%S %Y", tz = "America/Los_Angeles")
    subsonus_data$Human.Timestamp.convert <- format(subsonus_data$Human.Timestamp.convert, tz = "UTC", usetz = TRUE)
    # print(datetime_utc_str)
    # Extract the UTC date from the first timestamp as MMDDYYYY
    # UTC_date <- format(subsonus_data$Human.Timestamp.convert[1], "%m-%d-%Y")
    
    # Shorten names for each attribute header
    colnames(subsonus_data) <- c(
      "PDT_Time", "Loc_Lat", "Loc_Long", "Rem_X", "Rem_Y", "Rem_Z",
      "Rem_Depth", "Rem_Height", "Rem_Lat", "Rem_Long", "UTC_Time"
    )
    # Add subsonus_data to the main dataframe
    subsonus_log_df <- rbind(subsonus_log_df, subsonus_data)
    
    #Create directory called Shape in the folder path
    if (!dir.exists(file.path(folder, "Shape"))) {
      dir.create(file.path(folder, "Shape"))
    }
    
    # Create a shapefile with local position data
    coordinates(subsonus_data) <- ~ Loc_Long + Loc_Lat
    crs(subsonus_data) <- "+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0"
    
    # Save the shapefile
    raster::shapefile(subsonus_data, file.path(folder, "Shape", paste0(subsonus_log_filename,"_", file_number,".shp")), overwrite=TRUE)
    
    loc_shp_files <- list.files(path = file.path(folder, "Shape"), pattern = paste0(subsonus_log_filename,"_", file_number), full.names = TRUE)
    print(loc_shp_files)
    # Get the file name without the extension
    loc_fname <- tools::file_path_sans_ext(basename(loc_shp_files[1]))
    print(loc_fname)
    # Zip the files
    zip::zipr(file.path(getwd(), "Zip", paste0(loc_fname,".zip")), loc_shp_files)

    # Create a shapefile with remote position data
    subsonus_data <- as.data.frame(subsonus_data)
    coordinates(subsonus_data) <- ~ Rem_Long + Rem_Lat
    crs(subsonus_data) <- "+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0"
    # Save the shapefile
    raster::shapefile(subsonus_data, file.path(folder, "Shape", paste0(subsonus_tag_log_filename,"_", file_number,".shp")), overwrite=TRUE)

    rem_shp_files <- list.files(path = file.path(folder, "Shape"), pattern = paste0(subsonus_tag_log_filename,"_", file_number), full.names = TRUE)
    rem_fname <- tools::file_path_sans_ext(basename(rem_shp_files[1]))
    zip::zipr(file.path(getwd(), "Zip", paste0(rem_fname,".zip")), rem_shp_files)

  }
  # Write subsonus_log_df to csv file
  write.csv(subsonus_log_df, paste0("RemoteTrack_", UTC_date, ".csv", row.names = FALSE)) 
  
}

# Future edit: Merge all the shapefiles into one shapefile


