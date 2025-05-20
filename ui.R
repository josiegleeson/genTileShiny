library(shiny)
library(shinydashboard)
library(shinyjs)

ui <- dashboardPage(
  dashboardHeader(title = "genTile"),
  # tabs
  dashboardSidebar(
    sidebarMenu(menuItem("Welcome", tabName = "welcome"),
                menuItem("Design guide RNAs", tabName = "generate_guides"),
                menuItem("Visualization", tabName = "visualization")
    )
  ),
  # body
  dashboardBody(
    useShinyjs(),  # shinyjs
    tags$head(
      tags$style(HTML("
        .spinner {
          margin: 0 auto;
          width: 30px;
          height: 30px;
          border: 6px solid #ccc;
          border-top: 6px solid #333;
          border-radius: 50%;
          animation: spin 1s linear infinite;
        }
  
        @keyframes spin {
          0% { transform: rotate(0deg); }
          100% { transform: rotate(360deg); }
        }
  
        .loading-container {
          display: none;
          text-align: center;
          margin-top: 20px;
        }
        
        #downloadResults {
          background-color: #4CAF50; /* Green */
          border: none;
          color: white;
          padding: 15px 32px;
          text-align: center;
          text-decoration: none;
          display: inline-block;
          font-size: 12px;
        }
        
        #downloadResults:disabled {
          background-color: #d3d3d3; /* Gray */
          color: #a9a9a9; /* Dark gray */
        }
        
        .spacing {
          margin-top: 20px;
        }
      ")),
      tags$script(HTML("
        Shiny.addCustomMessageHandler('disableButton', function(params) {
          var button = document.getElementById(params.id);
          button.disabled = true;
          button.style.backgroundColor = 'grey';
          button.style.borderColor = 'grey';
          document.getElementById(params.spinnerId).style.display = 'block';
        });
  
        Shiny.addCustomMessageHandler('enableButton', function(params) {
          var button = document.getElementById(params.id);
          button.disabled = false;
          button.style.backgroundColor = '';
          button.style.borderColor = '';
          document.getElementById(params.spinnerId).style.display = 'none';
        });
      "))
    ),
    tabItems(
      tabItem(tabName = "welcome",
              fluidRow(
                column(12,
                       div(class = "box box-primary", style = "padding-right: 5%; padding-left: 5%; font-size:110%",
                           div(class = "box-body", shiny::includeMarkdown("welcome-page-text.md"))
                       )
                )
              )
      ),
      tabItem(tabName = "generate_guides", 
              h2("Design a CRISPR guide RNA library"),
              h5("This tool is for designing optimally spaced CRISPR guide libraries for precise dosage modulation across gene targets."),
              fluidRow(
                column(6,

                       # Options
                       fileInput("user_gene_list", "Upload list of genes:", NULL, buttonLabel = "Browse...", multiple = FALSE),
                       numericInput("dist_up_tss", 
                                    label = "Distance upstream of TSS (nt):", 
                                    value = 1500),
                       numericInput("dist_down_tss", 
                                    label = "Distance downstream of TSS (nt):", 
                                    value = 500),
                       sliderInput("exclusion_zone", 
                                   label = "Exclusion zone around each guide (nt):", 
                                   min = 0, max = 300, value = 50, step = 50),
                       numericInput("min_hsu_score", 
                                    label = "Minimum Hsu score:", 
                                    value = 60),
                       numericInput("flashfry_memory", 
                                    label = "Memory available for FlashFry (GB):", 
                                    value = 8),
                       actionButton("guide_submit_button", "Submit", class = "btn btn-primary")
                ),
                column(6,
                       HTML("<h3>Download your results:</h3>"),
                       downloadButton("guide_download_button", "Download results (zip)", disabled = TRUE, style = "width:70%;"), # initially disabled
                       div(id = "guide-loading-container", class = "loading-container", div(class = "spinner"))
                )
              )
      ),
      tabItem(tabName = "visualization", 
              fluidRow(
                column(12, 
                       h2("Visualize results", align = "left") 
                )
              ),
              # fluidRow(
              #   column(4,
              #          fileInput("user_vis_gtf_file", "Upload 'combined_annotations.gtf' file:", NULL, buttonLabel = "Browse...", multiple = FALSE),
              #          fileInput("user_vis_tx_count_file", "Upload 'bambu_transcript_counts.txt' (optional):", NULL, buttonLabel = "Browse...", multiple = FALSE),
              #          fileInput("user_pep_count_file", "Upload peptide intensities file (optional):", NULL, buttonLabel = "Browse...", multiple = FALSE),
              #          actionButton("vis_submit_button", "Submit", class = "btn btn-primary")
              #   ),
              #   column(8,
              #          selectInput("gene_selector", "Select a gene:", choices = NULL),
              #          actionLink("toggle_filters", "▼ Gene list filtering options", class = "toggle-filters"), # toggle filtering options
              #          div(id = "filters_container", style = "display:none;", # hidden by default
              #              p("UMP = uniquely mapped peptide. Peptides that only mapped to a single protein entry in the protein database."),
              #              checkboxInput("uniq_map_peptides", "ORFs with UMPs", value = FALSE),
              #              checkboxInput("lncRNA_peptides", "long non-coding RNAs with UMPs", value = FALSE),
              #              checkboxInput("novel_txs", "novel transcript isoforms with UMPs", value = FALSE),
              #              checkboxInput("novel_txs_distinguished", "novel transcript isoforms distinguished by UMPs", value = FALSE),
              #              checkboxInput("unann_orfs", "unannotated ORFs with UMPs", value = FALSE),
              #              checkboxInput("uorf_5", "5' uORFs with UMPs", value = FALSE),
              #              checkboxInput("dorf_3", "3' dORFs with UMPs", value = FALSE)
              #          ),
              #          div(id = "vis-loading-container", class = "loading-container", div(class = "spinner")),
              #          plotOutput("plot"),
              #          downloadButton("vis_download_button", "Download plot", disabled = TRUE, class = "spacing")
              #   )
              # )
      )
    )
  ),  
  skin = "blue"
)
