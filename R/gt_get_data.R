gt_get_data <- function(dest_folder = file.path(tempdir(), "geysertimes"),
  overwrite=FALSE, quiet=FALSE, version=lubridate::today()) {
  if(missing(dest_folder)) {
    if(!quiet) {
      message("Set dest_folder to geysertimes::gt_path() so that data persists between R sessions.\n")
    }
  }

  # eruption data determine actual version (date):
  downloaded_file <- eruptions_file(version)
  actual_version <- tools::file_path_sans_ext(
    basename(downloaded_file), compression=TRUE)
  actual_version <- gsub("geysertimes_eruptions_complete_", "", actual_version)

  # paths for saving the data:
  outpathdir <- file.path(dest_folder, actual_version)
  outpath_eruptions <- file.path(outpathdir, "eruptions_data.rds")
  outpath_geysers <- file.path(outpathdir, "geysers_data.rds")
  if(file.exists(outpathdir) && !overwrite) {
    warning("geysertimes data for this version already exists on the local machine. Use the 'overwrite' argument to re-download if neccessary.")
    return(invisible(outpathdir))
  }
  if(!dir.exists(outpathdir)) {
    dir.create(outpathdir, recursive=TRUE)
  }

  eruptions <- read_eruptions_file(downloaded_file)
  saveRDS(eruptions, file=outpath_eruptions)

  # geysers data:
  geysers <- get_geysers(version)
  saveRDS(geysers, file=outpath_geysers)
  invisible(outpathdir)
}

eruptions_file <- function(version) {
  # eruptions data:
  base_url <- "https://geysertimes.org/archive/complete/"
  download_tmp <- tempdir()
  # Try specified version:
  raw_data_file <- paste0("geysertimes_eruptions_complete_", version, ".tsv.gz")
  download_data_file_path <- file.path(download_tmp, raw_data_file)
  data_url <- paste0(base_url, raw_data_file)
  trydownload <- suppressWarnings(try(
    download.file(data_url, destfile=download_data_file_path, quiet=TRUE), 
      silent=TRUE))
  # Try one day before specified version:
  if(trydownload != 0) {
    version <- version - 1
    raw_data_file <- paste0("geysertimes_eruptions_complete_", version, ".tsv.gz")
    download_data_file_path <- file.path(download_tmp, raw_data_file)
    data_url <- paste0(base_url, raw_data_file)
    trydownload <- suppressWarnings(try(
      download.file(data_url, destfile=download_data_file_path, quiet=TRUE), 
        silent=TRUE))
  }
  # Try one day after specified version:
  if(trydownload != 0) {
    version <- version + 1
    raw_data_file <- paste0("geysertimes_eruptions_complete_", version, ".tsv.gz")
    download_data_file_path <- file.path(download_tmp, raw_data_file)
    data_url <- paste0(base_url, raw_data_file)
    trydownload <- suppressWarnings(try(
      download.file(data_url, destfile=download_data_file_path, quiet=TRUE), 
        silent=TRUE))
  }
  if(trydownload != 0) {
    stop("Cannot download ", data_url)
  }
  download_data_file_path
}

read_eruptions_file <- function(path) {
  eruptions <- readr::read_tsv(gzfile(path),
    col_types=c("dcddddddddddddcccccccdddc"), quote="", progress=FALSE)
  if(nrow(eruptions) == 0) {
    stop("Eruptions data is unavailable for download at this time")
  }
  # rename columns:
  indx_name <- match(names(eruptions), names(gt_new_names))
  stopifnot(!any(is.na(indx_name)))
  names(eruptions) <- gt_new_names[indx_name]
  # convert to datetime:
  eruptions[["time"]] <-
    lubridate::as_datetime(eruptions[["time"]])
  eruptions[["time_updated"]] <- lubridate::as_datetime(eruptions[["time_updated"]])
  eruptions[["time_entered"]] <- lubridate::as_datetime(eruptions[["time_entered"]])
  # convert NULL to NA:
  eruptions[["duration_seconds"]] <- replace(eruptions[["duration_seconds"]],
    which(eruptions[["duration_seconds"]] == 0), NA)
  eruptions[["duration_resolution"]] <- replace(eruptions[["duration_resolution"]],
    which(eruptions[["duration_resolution"]] == 0), NA)
  eruptions[["duration_modifier"]] <- replace(eruptions[["duration_modifier"]],
    which(eruptions[["duration_modifier"]] == 0), NA)
  # convert duration_seconds from character to numeric:
  # first convert "NULL" to NA:
  indxNULL <- which(eruptions[["duration_seconds"]] == "NULL")
  if(length(indxNULL) > 0) {
    eruptions[indxNULL, "duration_seconds"] <- NA_character_
  }
  eruptions[["duration_seconds"]] <- as.numeric(eruptions[["duration_seconds"]])
  # convert 0/1 to logical FALSE/TRUE
  eruptions[["has_seconds"]] <- ifelse(eruptions[["has_seconds"]] == 1, TRUE, FALSE)
  eruptions[["exact"]] <- ifelse(eruptions[["exact"]] == 1, TRUE, FALSE)
  eruptions[["near_start"]] <- ifelse(eruptions[["near_start"]] == 1, TRUE, FALSE)
  eruptions[["in_eruption"]] <- ifelse(eruptions[["in_eruption"]] == 1, TRUE, FALSE)
  eruptions[["electronic"]] <- ifelse(eruptions[["electronic"]] == 1, TRUE, FALSE)
  eruptions[["approximate"]] <- ifelse(eruptions[["approximate"]] == 1, TRUE, FALSE)
  eruptions[["webcam"]] <- ifelse(eruptions[["webcam"]] == 1, TRUE, FALSE)
  eruptions[["initial"]] <- ifelse(eruptions[["initial"]] == 1, TRUE, FALSE)
  eruptions[["major"]] <- ifelse(eruptions[["major"]] == 1, TRUE, FALSE)
  eruptions[["minor"]] <- ifelse(eruptions[["minor"]] == 1, TRUE, FALSE)
  eruptions[["questionable"]] <- ifelse(eruptions[["questionable"]] == 1, TRUE, FALSE)
  eruptions
}

get_geysers <- function(version) {
  geysers_df <- try(jsonlite::fromJSON(
    "https://www.geysertimes.org/api/v5/geysers")$geysers, silent=TRUE)
  if(class(geysers_df) == "try-error") {
    stop("Download of geysers data failed") 
  }
  geysers_df[["longitude"]] <- as.numeric(geysers_df[["longitude"]])
  geysers_df[["latitude"]] <- as.numeric(geysers_df[["latitude"]])
  geysers_df[["longitude"]] <- replace(geysers_df[["longitude"]],
    which(geysers_df[["longitude"]] == 0), NA)
  geysers_df[["latitude"]] <- replace(geysers_df[["latitude"]],
    which(geysers_df[["latitude"]] == 0), NA)
  geysers_df
}
