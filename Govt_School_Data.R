###FOR GOVERNMENT SCHOOLS

# Clear environment
rm(list=ls())
gc()

#install.packages('magick')
#install.packages('tesseract')

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
library(magick)
library(tesseract)
library(readr)

#Storing the UDISE unique Codes 

govtsl <- list("07040123707", "07040123806", "07040123503", "07040122601", "07040123706", "07040122502", "07040123804", "07040123704", "07040123805", "07040123702")

####################
# Start Session
####################

url_rc <- "https://src.udiseplus.gov.in/home"

rD <- rsDriver(browser="chrome",
               chromever ="128.0.6613.84",
               port=free_port(), 
               verbose=F)

# Get started with RSelenium 
remDr <- rD[["client"]]

# Opening up the browser
remDr$open()

# Define the maximum number of retries
max_retries <- 5

# Function to read CAPTCHA and submit
read_and_submit_captcha <- function(remDr, url_rc, udise_code, retries_left) {
  tryCatch({
    # Navigating to the website
    remDr$navigate(url_rc)
    
    # Step 1: Searching the RCs by UDISE Code
    uc_search <- remDr$findElement(using = 'xpath', '//input[@placeholder="UDISE Code"]')
    uc_search$clickElement()
    uc_search$sendKeysToElement(list(udise_code))
    
    Sys.sleep(1)  # Wait for the page to update
    
    # Step 2: Get Captcha Elements
    captcha_element <- remDr$findElement(using = 'xpath', '//img[@id="captchaId"]')
    
    # Retrieve individual attributes
    width <- captcha_element$getElementAttribute('naturalWidth')[[1]]
    height <- captcha_element$getElementAttribute('naturalHeight')[[1]]
    x <- captcha_element$getElementAttribute('x')[[1]]
    y <- captcha_element$getElementAttribute('y')[[1]]
    
    # Take a screenshot of the entire page
    screenshot_path <- tempfile(fileext = ".png")
    remDr$screenshot(file = screenshot_path)
    
    # Read the screenshot with magick
    full_img <- image_read(screenshot_path)
    
    # Crop the screenshot to the CAPTCHA image location
    captcha_img <- image_crop(full_img, paste0(width, "x", height, "+", x, "+", y))
    ocr_engine <- tesseract("eng")  # English language
    captcha_text <- ocr(captcha_img, engine = ocr_engine)
    
    # Clean and format the CAPTCHA text
    captcha_text <- captcha_text %>%
      gsub("[^a-zA-Z0-9]", "", .) %>%  # Remove non-alphanumeric characters
      tolower() %>%                    # Convert to lowercase
      trimws()                         # Trim any extra whitespace
    
    # Step 3: Clicking Captcha
    captcha_input <- remDr$findElement(using = 'xpath', '//input[@placeholder="Captcha"]')
    captcha_input$clickElement()
    captcha_input$sendKeysToElement(list(captcha_text))
    
    # Step 4: Clicking the search button
    remDr$findElement(using = 'id', 'homeSearchBtn')$clickElement()
    
    # Step 5: Clicking on the Report Card Button
    remDr$findElement(using = 'xpath', '//*[@id="example"]/tbody/tr/td[7]/button[1]')$clickElement()
    
    # If successful, exit the function
    message("Captcha submitted successfully for UDISE code: ", udise_code)
    return(TRUE)
  }, error = function(e) {
    message("Error encountered for UDISE code ", udise_code, ": ", e$message)
    if (retries_left > 0) {
      message("Retrying... (", retries_left, " attempts left)")
      Sys.sleep(3)  # Wait a bit before retrying
      return(read_and_submit_captcha(remDr, url_rc, udise_code, retries_left - 1))
    } else {
      message("Failed after maximum retries for UDISE code: ", udise_code)
      return(FALSE)
    }
  })
}

# Loop over each UDISE code in the dataset
for (udise_code in govtsl) {
  # Print the current UDISE code for debugging
  print(paste("Processing UDISE code:", udise_code))
  
  # Call the function with the current UDISE code
  result <- read_and_submit_captcha(remDr, url_rc, udise_code, max_retries)
  
  # Optionally, print the result of the function call
  print(paste("Result for UDISE code", udise_code, ":", result))
  
  # Optionally, add a delay between requests to avoid overwhelming the server
  Sys.sleep(2)  # Sleep for 2 seconds
}

# Close the session
remDr$close()
rD$server$stop()
