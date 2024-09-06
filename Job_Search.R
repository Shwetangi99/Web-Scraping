### LIST OF JOBS AVAILABLE AT DELOITTE

# Clear environment
rm(list=ls())
gc()

# Load in Libraries 
library(tidyverse) ## for data manipulation (various packages)
library(robotstxt) ## to get robotstxt protocols
library(rvest) ## for scraping
library(polite) # polite scraping check
library(httr)
library(dplyr)
library(RSelenium)
library(wdman)
library(future.apply)
library(netstat)
library(stringr)
library(data.table)

####################
# Start Session
####################

url_rc <- "https://www2.deloitte.com/in/en.html"

rD <- rsDriver(browser="chrome",
               chromever ="128.0.6613.84",
               port=free_port(), 
               verbose=F)

# Get started with RSelenium 
remDr <- rD[["client"]]

# Opening up the browser
remDr$open()

# Navigating to the website
remDr$navigate(url_rc)

# Clicking on the "Decline Optional Cookies" option
remDr$findElement(using= 'xpath', '//*[@id="onetrust-reject-all-handler"]')$clickElement()

Sys.sleep(1)

# Clicking the career dropdown button
remDr$findElement(using= 'xpath', '//*[@id="list3"]/a')$clickElement()

# Clicking the link text of the job search
remDr$findElement(using = 'xpath', '//a[@href="https://jobsindia.deloitte.com?icid=top_"]')$clickElement()

# Now switching the next tab for further web scrapping
remDr$getCurrentUrl()

myswitch <- function (remDr, windowId)
{
  qpath <- sprintf("%s/session/%s/window", remDr$serverURL,
                   remDr$sessionInfo[["id"]])
  remDr$queryRD(qpath, "POST", qdata = list(handle = windowId))
}

my_handles <- remDr$getWindowHandles()
myswitch(remDr, my_handles[[2]])
remDr$getCurrentUrl()

# Accepting all the cookies from the next page
remDr$findElement(using= 'xpath', '//*[@id="cookie-accept"]')$clickElement()

# Searching for a job post of Data Scientist in Bengaluru
search_job <- remDr$findElement(using='xpath', '//input[@class="keywordsearch-q columnized-search"]')
search_job$sendKeysToElement(list('Data Scientist'))
search_city <- remDr$findElement(using='xpath', '//input[@class="keywordsearch-locationsearch columnized-search"]')
search_city$sendKeysToElement(list('Bengaluru', key='enter'))

######### RUNNING THE LOOP TO GET THE TABLE ##############

# Initialize a variable to control the loop
cond <- TRUE

# Initialize an empty data table to store all scraped data
all_data <- data.table()

# Loop through the page titles
for (i in 1:6) {
  # Construct the title for the page
  page_title <- paste0("Page ", i)
  
  # Clicking on each page to scrape data (because the "next button" leads to the last page)
  tryCatch(
    {
      # Click the link for the current page
      remDr$findElement(using='xpath', paste0('//a[@title="', page_title, '"]'))$clickElement()
      
      # Wait for the page to load
      Sys.sleep(1)
      
      # Scrape the data from the current page
      get_html_table <- remDr$getPageSource()
      page <- read_html(get_html_table %>% unlist())
      table <- html_table(page) %>%.[[1]]
      
      # Process the table as needed
      final_table <- table[(3:27), (1:3)]
      all_data <- rbindlist(list(all_data, final_table))
      
    },
    error = function(e) {
      print(paste("Error on page", i, ":", e$message))
      cond <<- FALSE
      return(NULL)  # Exit the loop if an error occurs
    }
  )
  
  # Break the loop if condition is FALSE
  if (!cond) {
    break
  }
}

####### CLEAN THE TABLE AS REQUIRED ###########

all_data <- all_data %>%
  mutate(X1 = gsub("\\n.*", "", X1))

all_data <- all_data [(1:138),]

col_name <- table[2, 1:3] %>% unlist()
colnames(all_data) <- col_name

# Close the session
remDr$close()
rD$server$stop()
