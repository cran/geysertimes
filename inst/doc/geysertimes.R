## ---- echo = FALSE, message = FALSE-------------------------------------------
knitr::opts_chunk$set(collapse = T, comment = "#>")
options(tibble.print_min = 4L, tibble.print_max = 4L)

## ---- hidden_values, echo=FALSE-----------------------------------------------
default_path <- "/tmp/RtmpvSGw5Y/geysertimes/2021-01-04"
suggested_path <- "/home/spk/.local/share/GeyserTimes/2021-01-04"

## ----library------------------------------------------------------------------
suppressPackageStartupMessages(library("dplyr"))
library("geysertimes")

## ----default_get--------------------------------------------------------------
default_path <- gt_get_data()

## ----default_get_print--------------------------------------------------------
default_path

## ----gt_path------------------------------------------------------------------
gt_path()

## ----suggested_path, eval=FALSE-----------------------------------------------
#  suggested_path <- gt_get_data(dest_folder=gt_path())

## ----recommend_path_print-----------------------------------------------------
suggested_path

## ----load01-------------------------------------------------------------------
eruptions <- gt_load_eruptions()
geysers <- gt_load_geysers()

## ----look---------------------------------------------------------------------
dim(eruptions)
names(eruptions)

## ----version------------------------------------------------------------------
gt_version()

## ----version_all--------------------------------------------------------------
gt_version(all=TRUE)

## ----eruptions_counts, tibble.print_max=20L-----------------------------------
print(n=20,
eruptions %>% group_by(geyser) %>% summarise(N=n()) %>% arrange(desc(N)))

