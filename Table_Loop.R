#Web Scraping using Rselenium

#Clear enviromnent
rm(list=ls())
gc()

#loading libraries
library(tidyverse)
library(robotstxt)
library(rvest)
library(polite)
library(httr)
library(dplyr)
library(wdman)
library(RSelenium)
library(future)
library(future.apply)
library(netstat)
library(stringr)
library(data.table)

#binman::list_versions("chromedriver")
rD <- rsDriver(browser="chrome",
               chromever="128.0.6613.84",
               port=free_port(),
               verbose=F)

# Get started with RSelenium
remDr <- rD$"client"
remDr$open()

# navigating to the webpage
remDr$navigate("https://tablepress.org/demo/")

#getting the table
data_table <- remDr$findElement(using='xpath', '//*[@id="tablepress-demo_wrapper"]')

#Clicking the next button
remDr$findElement(using='xpath', '//*[@id="tablepress-demo_next"]')$clickElement()
remDr$goBack()

#Get html code for the table
data_table_html <- data_table$getPageSource()
page <- read_html(data_table_html %>% unlist())
final_table <- html_table(page) %>%.[[2]]
final_table <- final_table[-1, ]

##############NOW FOR ALL FINAL DATA WE WILL PREPARE A LOOP######################

all_data <- list()
cond <- TRUE

while(cond==TRUE){
  
data_table_html <- data_table$getPageSource()
page <- read_html(data_table_html %>% unlist())
final_table <- html_table(page) %>%.[[2]]
final_table <- final_table[-1, ]
all_data <- rbindlist(list(all_data, final_table))

Sys.sleep(0.2)
#Running the loop and catching the error which might be caused when reach the 200th page where NEXT button is disables
tryCatch(
  {
    remDr$findElement(using='xpath', '//*[@id="tablepress-demo_next"]')$clickElement()
      }, 
  error=function(e) {
    print("Script Complete!")
    cond <<- FALSE
    }
)
if (cond==FALSE){
  break
  }
}
all_data$Amount <- gsub("\\$", "", all_data$Amount)
all_data$Amount <- gsub(",", "", all_data$Amount)
all_data$Amount = as.numeric(all_data$Amount)
mean(all_data$Amount)

#Renaming the column
colnames(all_data)[colnames(all_data) == "Amount"] <- "Amount (in $)"