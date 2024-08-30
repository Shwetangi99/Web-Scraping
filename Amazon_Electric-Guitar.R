#Web Scraping using Rselenium

#Clear enviromnent
rm(list=ls())
gc()

#installing the packages
#install.packages("tidyverse")       #for data manipulation
#install.packages("robotstxt")       #to get robotstxt protocol
#install.packages("rvest")           # for scraping
#install.packages("polite")          # polite scraping check  
#install.packages("httr")
#install.packages("dplyr")           # for data manipulation
#install.packages("wdman")
#install.packages("RSelenium")
#install.packages("future.apply")
#install.packages("netstat")
#install.packages("stringr")

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

#selenium()

#binman::list_versions("chromedriver")
rD <- rsDriver(browser="chrome",
               chromever="128.0.6613.84",
               port=free_port(),
               verbose=F)

# Get started with RSelenium
remDr <- rD$"client"
remDr$open()

# navigating to the webpage
remDr$navigate("https://www.amazon.in/")

# finding element
electronic <- remDr$findElement(using='link text', value= 'Electronics')$clickElement()
electronic$getElementAttribute('href')
remDr$goBack()

# Searching for an item
search_box <- remDr$findElement(using='id', 'twotabsearchtextbox')
search_box$sendKeysToElement(list('Electric Guitars', key='enter'))

#Scrolling through the website using the java script command -https://scrapeops.io/selenium-web-scraping-playbook/python-selenium-scroll-page/#:~:text=TLDR%3A%20How%20To%20Scroll%20Page%20Using%20Selenium%E2%80%8B&text=Execute%20JavaScript%20code%20to%20scroll,to%20the%20bottom%20or%20top.&text=Use%20JavaScript%20Executor%20to%20scroll%20to%20a%20specific%20element%20on%20the%20page.&text=Utilize%20keyboard%20keys%20(e.g.%2C%20PAGE_DOWN,PAGE_UP)%20to%20scroll%20the%20page.
remDr$executeScript("window.scrollTo(0, document.body.scrollHeight)")

#Filtering the items
brand <- remDr$findElement(using= 'link text', 'Fender')
brand$getElementAttribute("href")
brand$clickElement()

remDr$goBack()

#Alternative way to filter out
brand_fen <- remDr$findElement(using= 'xpath', '//*[@id="p_123/240021"]/span/a/div/label/i')
brand_fen$clickElement()

#Setting the price range
    #1. Lower Limit

#lprice <- remDr$findElement(using='xpath', '//input[@aria-valuetext="???650"]')
lprice <- remDr$findElement(using='xpath', '//*[@id="p_36/range-slider_slider-item_lower-bound-slider"]')

js_code <- "
var lprice = arguments[0];
lprice.value = arguments[1];
lprice.dispatchEvent(new Event('change'));  // Trigger the change event
"
# Execute the script to change the slider value
remDr$executeScript(js_code, list(lprice, 50))

    #2. Upper Limit

uprice <- remDr$findElement(using='xpath', '//*[@id="p_36/range-slider_slider-item_upper-bound-slider"]')

js_code_up <- "
var uprice = arguments[0];
uprice.value = arguments[1];
uprice.dispatchEvent(new Event('change'));  // Trigger the change event
"
# Execute the script to change the slider value
remDr$executeScript(js_code, list(uprice, 100))

remDr$findElement(using='xpath', '//*[@id="a-autoid-25"]/span/input')$clickElement()

#Extracting prices of each element
#price$getElementText()
prices <- remDr$findElements(using='class', 'a-price-whole')
length(prices)

price_list <- lapply(prices, function (x) x$getElementText()) %>%
  unlist() %>%
  str_remove_all(",")    #To Remove Rs. sign if any

#Need to drop unnecessary values
#price_list = price_list[-4]
unlist(price_list)
price_list = as.numeric(price_list)
mean(price_list)

#Terminate the selenium server
system('taskkill /im java.exe /f')

# remDr$close()
# stop the selenium server
# rD[["server"]]$stop()
