#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    https://shiny.posit.co/
#

library(shiny)

# app.R
# ======================
# Packages
# ======================
suppressPackageStartupMessages({
  library(shiny)
  library(shinyWidgets)
  library(dplyr)
  library(tidyr)
  library(readr)
  library(lubridate)
  library(ggplot2)
  library(plotly)
  library(DT)
  library(stringr)
})

# ======================
# LOAD DATA
# ======================
# ======================
# USER INPUTS (EDIT ONLY HERE)
# ======================

data_file <- "2025_fall_scrimmage_data.csv"  # Raw TrackMan data
run_date  <- "2025-10-11"                             # Stuff+ run date (YYYY-MM-DD)

raw <- read_csv(data_file, show_col_types = FALSE) %>%
  mutate(
    gameDate_chr = as.character(Date),
    gameDate = as.Date(ymd(gameDate_chr)),
    playerFullName = as.character(Pitcher),
    pitchType = coalesce(
      as.character(TaggedPitchType),
      as.character(AutoPitchType)
    ),
    Vel        = RelSpeed,
    Spin       = SpinRate,
    HorzBrk    = HorzBreak,
    IndVertBrk = InducedVertBreak
  ) %>%
  select(-gameDate_chr)

# Stuff+ outputs (STATIC TABLES)
stuff_results <- read_csv(
  paste0("stuff_results_", run_date, ".csv"),
  show_col_types = FALSE
)

stuff_top5 <- read_csv(
  paste0("stuff_top5_leaderboard_", run_date, ".csv"),
  show_col_types = FALSE
)

# ======================
# COLUMN DETECTION
# ======================

has_plate_cols <- all(c("PlateLocSide", "PlateLocHeight") %in% names(raw))
x_col <- if (has_plate_cols) "PlateLocSide" else "HorzBrk"
y_col <- if (has_plate_cols) "PlateLocHeight" else "IndVertBrk"

stat_choices <- c(
  "Velocity (mph)" = "Vel",
  "Spin Rate (rpm)" = "Spin",
  "Extension (ft)" = "Extension",
  "Horizontal Break (in)" = "HorzBrk",
  "Induced Vertical Break (in)" = "IndVertBrk",
  "Vertical Approach Angle" = "VertApprAngle"
)
stat_choices <- stat_choices[stat_choices %in% names(raw)]

# ======================
# UI
# ======================

ui <- fluidPage(
  tags$head(tags$style(HTML("
    .card { background:#e6f0fa; padding:12px; border-radius:12px; }
    .card-red { background:#e86f61; color:white; padding:12px; border-radius:12px; }
    .panel-title { font-weight:600; font-size:18px; margin-bottom:8px; }
  "))),
  
  titlePanel("Pitt Pitchers — Interactive Pitch Dashboard"),
  
  fluidRow(
    column(3, pickerInput("stat","Statistic", choices = stat_choices,
                          options = list(`live-search`=TRUE))),
    column(3, pickerInput("player","Pitcher",
                          choices = sort(unique(raw$playerFullName)),
                          options = list(`live-search`=TRUE))),
    column(3, pickerInput("pitch","Pitch Type", choices = NULL,
                          options = list(`live-search`=TRUE))),
    column(3, pickerInput("date","Date", choices = NULL,
                          options = list(`live-search`=TRUE)))
  ),
  
  br(),
  
  fluidRow(
    column(6, div(class="card",
                  div(class="panel-title","Longitudinal Plot"),
                  plotlyOutput("ts_plot", height = 380))),
    column(6, div(class="card",
                  div(class="panel-title",
                      if (has_plate_cols) "Strike Zone Plot" else "Movement Map"),
                  plotlyOutput("sz_plot", height = 380)))
  ),
  
  br(),
  
  fluidRow(
    column(6, div(class="card-red",
                  div(class="panel-title","Stuff+ Results (All Pitchers)"),
                  DTOutput("model_tbl"))),
    column(6, div(class="card-red",
                  div(class="panel-title","Stuff+ Top 5 Leaderboard"),
                  DTOutput("pitch_tbl")))
  )
)

# ======================
# SERVER
# ======================

server <- function(input, output, session) {
  
  rv <- reactiveValues(reset_left = TRUE)
  
  observeEvent(input$player, {
    pitch_opts <- raw %>%
      filter(playerFullName == input$player) %>%
      distinct(pitchType) %>%
      arrange(pitchType) %>%
      pull(pitchType)
    
    updatePickerInput(session, "pitch", choices = pitch_opts)
    
    date_opts <- raw %>%
      filter(playerFullName == input$player) %>%
      distinct(gameDate) %>%
      arrange(desc(gameDate)) %>%
      pull(gameDate)
    
    updatePickerInput(session, "date",
                      choices = format(date_opts, "%Y-%m-%d")
    )
    
    rv$reset_left <- TRUE
  }, ignoreInit = TRUE)
  
  observeEvent(input$pitch, rv$reset_left <- FALSE, ignoreInit = TRUE)
  observeEvent(input$stat,  rv$reset_left <- FALSE, ignoreInit = TRUE)
  
  # ======================
  # REACTIVES (PLOTS ONLY)
  # ======================
  
  left_df <- reactive({
    req(input$player, input$pitch)
    raw %>%
      filter(playerFullName == input$player,
             pitchType == input$pitch) %>%
      arrange(gameDate)
  })
  
  right_df <- reactive({
    req(input$player, input$pitch, input$date)
    raw %>%
      filter(playerFullName == input$player,
             pitchType == input$pitch,
             gameDate == ymd(input$date))
  })
  
  # ======================
  # LONGITUDINAL PLOT
  # ======================
  
  output$ts_plot <- renderPlotly({
    validate(need(!rv$reset_left, "Select Player & Pitch Type"))
    df <- left_df()
    
    p <- ggplot(df, aes(x = gameDate, y = .data[[input$stat]])) +
      geom_line() +
      geom_point() +
      theme_minimal(base_size = 12) +
      labs(x = "Date", y = input$stat)
    
    ggplotly(p)
  })
  
  # ======================
  # STRIKE ZONE / MOVEMENT
  # ======================
  
  output$sz_plot <- renderPlotly({
    req(input$player, input$pitch, input$date)
    df <- right_df()
    validate(need(nrow(df) > 0, "No pitches for this date"))
    
    p <- ggplot(df, aes(x = .data[[x_col]], y = .data[[y_col]])) +
      geom_point(alpha = 0.75, size = 2, color = "#1f78b4") +
      theme_minimal(base_size = 12) +
      labs(
        x = if (has_plate_cols) "Plate X (ft)" else "Horizontal Break (in)",
        y = if (has_plate_cols) "Plate Z (ft)" else "Induced Vertical Break (in)",
        title = paste(input$player, "—", input$pitch, "—", input$date)
      )
    
    if (has_plate_cols) {
      p <- p + annotate(
        "rect",
        xmin = -0.708, xmax = 0.708,
        ymin = 1.5, ymax = 3.5,
        color = "red",
        fill = NA,
        linetype = "dashed",
        size = 1
      )
    }
    
    ggplotly(p)
  })
  
  # ======================
  # TABLES (NO FILTERING)
  # ======================
  
  output$model_tbl <- renderDT({
    stuff_results %>%
      select(
        pitch_type,
        player_name,
        avg_stuff_plus,
        csw_percent,
        avg_velocity,
        n_pitches
      ) %>%
      arrange(desc(avg_stuff_plus)) %>%
      datatable(
        rownames = FALSE,
        options = list(pageLength = 10)
      )
  })
  
  output$pitch_tbl <- renderDT({
    stuff_top5 %>%
      select(
        pitch_type,
        player_name,
        avg_stuff_plus,
        csw_percent,
        avg_velocity,
        n_pitches
      ) %>%
      arrange(pitch_type, desc(avg_stuff_plus)) %>%
      datatable(
        rownames = FALSE,
        options = list(pageLength = 10)
      )
  })
}

shinyApp(ui, server)