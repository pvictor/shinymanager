

#' @importFrom billboarder billboarderOutput
#' @importFrom shiny NS fluidRow column icon
#' @importFrom htmltools tagList tags
logs_UI <- function(id) {

  ns <- NS(id)

  lan <- use_language()

  tagList(
    fluidRow(
      column(
        width = 8, offset = 2,

        tags$h3(icon("users"), lan$get("Number of connections per user"), class = "text-primary"),
        tags$hr(),
        billboarderOutput(outputId = ns("graph_conn_users")),

        tags$br(),

        tags$h3(icon("calendar"), lan$get("Number of connections per day"), class = "text-primary"),
        tags$hr(),
        billboarderOutput(outputId = ns("graph_conn_days"))
      )
    )
  )
}

#' @importFrom billboarder renderBillboarder billboarder bb_barchart
#'  bb_y_grid bb_data bb_legend bb_labs bb_linechart bb_colors_manual
#'  bb_x_axis bb_zoom %>%
#' @importFrom shiny reactiveValues observe req
logs <- function(input, output, session, sqlite_path, passphrase) {

  ns <- session$ns
  jns <- function(x) {
    paste0("#", ns(x))
  }

  lan <- use_language()

  logs_rv <- reactiveValues(logs = NULL, users = NULL)

  observe({
    conn <- dbConnect(SQLite(), dbname = sqlite_path)
    on.exit(dbDisconnect(conn))
    logs_rv$logs <- read_db_decrypt(conn = conn, name = "logs", passphrase = passphrase)
    logs_rv$users <- read_db_decrypt(conn = conn, name = "credentials", passphrase = passphrase)
  })

  output$graph_conn_users <- renderBillboarder({
    req(logs_rv$logs)

    nb_log <- as.data.frame(table(user = logs_rv$logs$user), stringsAsFactors = FALSE)
    nb_log <- merge(x = logs_rv$users[, "user", drop = FALSE], y = nb_log, by = "user", all.x = TRUE)
    nb_log <- nb_log[order(nb_log$Freq, decreasing = TRUE), ]

    billboarder() %>%
      bb_barchart(data = nb_log, color = "#4582ec", rotated = TRUE) %>%
      bb_y_grid(show = TRUE) %>%
      bb_data(names = list(Freq = "Nb logged")) %>%
      bb_legend(show = FALSE) %>%
      bb_labs(
        # title = "Number of connection by user",
        y = lan$get("Total number of connection")
      )
  })


  output$graph_conn_days <- renderBillboarder({
    req(logs_rv$logs)

    nb_log_day <- as.data.frame(table(day = substr(logs_rv$logs$server_connected, 1, 10)), stringsAsFactors = FALSE)
    nb_log_day$day <- as.Date(nb_log_day$day)
    nb_log_day <- merge(
      x = data.frame(day = seq(
        from = min(nb_log_day$day) - 1, to = max(nb_log_day$day) + 1, by = "1 day"
      )),
      y = nb_log_day, by = "day", all.x = TRUE
    )
    nb_log_day$Freq[is.na(nb_log_day$Freq)] <- 0

    billboarder() %>%
      bb_linechart(data = nb_log_day, type = "area-step") %>%
      bb_colors_manual(list(Freq = "#4582ec")) %>%
      bb_x_axis(type = "timeseries", tick = list(fit = FALSE), max = max(nb_log_day$day) + 1) %>%
      bb_y_grid(show = TRUE) %>%
      bb_data(names = list(Freq = "Nb logged")) %>%
      bb_legend(show = FALSE) %>%
      bb_labs(
        # title = "Number of connection by user",
        y = lan$get("Total number of connection")
      ) %>%
      # bb_bar(width = list(ratio = 1, max = 30)) %>%
      bb_zoom(
        enabled = list(type = "drag"),
        resetButton = list(text = "Unzoom")
      )
  })

}


