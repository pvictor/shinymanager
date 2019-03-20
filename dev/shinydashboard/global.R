

# Global ------------------------------------------------------------------

library(shiny)
library(shinymanager)
library(shinydashboard)


# data.frame with credentials info
credentials <- data.frame(
  user = c("fanny", "victor", "benoit"),
  password = c("azerty", "12345", "azerty"),
  comment = c("alsace", "auvergne", "bretagne"),
  stringsAsFactors = FALSE
)

# Function to authenticate user
check_credentials_p <- purrr::partial(
  check_credentials_df,
  credentials_df = credentials # set default df to use
)
