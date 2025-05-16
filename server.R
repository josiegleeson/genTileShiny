
library(shiny)
library(shinyjs)

extract_sequences_server <- function(input, output, session) {
  
  # store session ID
  session_id <- session$token
  # set output dir
  outdir_guides <- paste0(session_id, "/guides_output")
  # create output dir
  system(paste0("mkdir ", outdir_guides))
  
  req(input$user_gene_list)
  
  # run get sequence script
  command_get_sequence <- paste0("bin/get_sequence.sh -i ", input$user_gene_list$datapath, " -r references/hg38.fa -u ", input$dist_up_tss, " -d ", input$dist_down_tss, " -o ", outdir_guides, "/sequences.fa -v")
  system(command_get_sequence)
  
}

design_guides_server <- function(input, output, session) {
  
  # store session ID
  session_id <- session$token
  # set output dir
  outdir_guides <- paste0(session_id, "/guides_output")
  
  # run design guides script
  command_design_guides <- paste0("bin/design_guides.sh -i ", outdir_guides, "/sequences.fa --flashfry bin/FlashFry-assembly-1.15.jar --database references/hg38 --output ", outdir_guides, "/scored_guides.txt")
  system(command_design_guides)
  
}

select_guides_server <- function(input, output, session) {
  
  # store session ID
  session_id <- session$token
  # set output dir
  outdir_guides <- paste0(session_id, "/guides_output")
  
  # run select guides script
  command_select_guides <- paste0("bin/select_guides.sh --input ",  outdir_guides, "/scored_guides.txt -z ", input$exclusion_zone, " -m ", input$min_hsu_score, " --output ", outdir_guides, "/selected_guides.txt")
  system(command_select_guides)
  
  # get the top level dir
  top_level_dir <- getwd()
  
  # zip all results files
  if (file.exists(paste0(outdir_guides, "/selected_guides.txt")) && file.exists(paste0(outdir_guides, "/selected_guides.bed"))) {
    
    # create a zip file with results
    files_to_zip <- c("selected_guides.txt", "selected_guides.bed", "scored_guides.txt", "sequences.fa")
    
    # set the path to the ZIP file (in the session_id directory)
    zipfile_path <- file.path("../results.zip")
    
    # temp change the working dir to outdir_guides
    tmp_wd <- setwd(outdir_guides)
    
    # zip files
    zip(zipfile = zipfile_path, files = files_to_zip)
    
    # go back to starting dir
    setwd(top_level_dir)
    
  }
}


# main shiny app server
server <- function(input, output, session) {
  
  # store session ID
  # create session id tmp directory each time app is run
  session_id <- session$token
  print(paste0("Session: ", session_id))
  # create the dir
  system(paste0("mkdir ", session_id))
  
  # create reactive value for the database zip
  file_available_guides <- reactiveVal(FALSE)
  
  # run database function when submit is pressed
  observeEvent(input$guide_submit_button, {
    
    # ensure download button remains greyed out (if submit is re-pressed)
    shinyjs::disable("guide_download_button")
    shinyjs::runjs("document.getElementById('guide_download_button').style.backgroundColor = '#d3d3d3';")
    # disable submit button after it is pressed
    session$sendCustomMessage("disableButton", list(id = "guide_submit_button", spinnerId = "guide-loading-container"))
    
    # run servers
    extract_sequences_server(input, output, session)
    
    # check above ran
    design_guides_server(input, output, session)
    
    # check above ran
    select_guides_server(input, output, session)
    
    # check if the zip file is created
    if (file.exists(paste0(session_id, "/results.zip"))) {
      file_available_guides(TRUE)
    }
  })
  
  # enable download once files are available
  observe({
    if (file_available_guides()) {
      shinyjs::enable("guide_download_button")
      shinyjs::runjs("document.getElementById('guide_download_button').style.backgroundColor = '#4CAF50';")
      session$sendCustomMessage("enableButton", list(id = "guide_submit_button", spinnerId = "guide-loading-container")) # re-enable submit button
    }
  })
  
  # download handler for the database results.zip file
  output$guide_download_button <- downloadHandler(
    filename = function() {
      paste0(Sys.Date(), "_", format(Sys.time(), "%H%M"), "_results.zip")
    },
    content = function(file) {
      file.copy(paste0(session_id, "/results.zip"), file)
    }
  )
  
  # remove session id tmp directory created each time app is run
  session$onSessionEnded(function() {
    if (dir.exists(session_id)) {
      unlink(session_id, recursive = TRUE)
    }
  })
  
}