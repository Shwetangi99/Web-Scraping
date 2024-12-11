# Clear environment
rm(list=ls())
gc()

library(RSelenium)
library(wdman) #helps in setting up browser
library(netstat) #Gives free port
library(rvest) ## for scraping
library(dplyr)  # For data manipulation
library(httr)
library(jsonlite)
install.packages('writexl')
library(writexl)

binman::list_versions("chromedriver")
rD <- rsDriver(browser="chrome",
               chromever ="130.0.6723.92",
               port=free_port(), 
               verbose=F)

# Get started with RSelenium 
remDr <- rD[["client"]]

remDr$close()

# Opening up the browser
remDr$open()

main_url<- "https://www.moneycontrol.com/"

remDr$navigate(main_url)

Sys.sleep(20)

search_box<-remDr$findElement(using="xpath", '//*[@id="search_str"]')
search_box$getElementAttribute("id")
search_box$clickElement()
search_box$sendKeysToElement(list("Trent"))

Sys.sleep(1.5)

remDr$findElement(using='xpath', '//*[@id="autosuggestlist"]/ul/li[1]/a')$clickElement()

grurl <- "https://www.moneycontrol.com/mc/widget/stockdetails/getChartInfo?classic=true&scId=L&type=N"

response <- GET(grurl)

# Check if the request was successful
if (status_code(response) == 200) {
  # Parse the JSON response
  graph_data <- content(response, "text")
  graph_data <- fromJSON(graph_data, flatten = TRUE)
  
  # View the data (you can skip this if you don't want to print it)
  print(graph_data)
} else {
  message("Request failed!")
}

print(graph_data$chartActulaData)

df <- as.data.frame(graph_data$chartActulaData)