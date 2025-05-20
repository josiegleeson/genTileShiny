
library(shiny)
library(shinyjs)
library(biomaRt)
library(GenomicRanges)
library(BSgenome.Hsapiens.UCSC.hg38)
# mouse genome
library(Biostrings)
library(data.table)
library(dplyr)

extract_sequences_server <- function(input, output, session) {
  
  # store session ID
  session_id <- session$token
  # set output dir
  outdir_guides <- paste0(session_id, "/guides_output")
  # create output dir
  system(paste0("mkdir ", outdir_guides))
  
  req(input$user_gene_list)
  
  # define gene list
  genes <- fread(input$user_gene_list$datapath, header=F)
  #genes <- fread("~/Documents/git/genTileShiny/test_genes.txt", header=F)
  genes <- genes$V1
  
  message("Number of genes found: ", length(genes))
  
  # use biomaRt to retrieve gene annotations
  mart <- useEnsembl(biomart = "genes", dataset = "hsapiens_gene_ensembl")
  
  # extract TSS and strand info
  gene_info <- getBM(
    attributes = c("hgnc_symbol", "ensembl_gene_id", "ensembl_transcript_id",
                   "chromosome_name", "transcription_start_site", "strand", "transcript_is_canonical", "transcript_mane_select"),
    filters = "hgnc_symbol",
    values = genes,
    mart = mart
  )
  
  # filter for standard chromosomes only
  # filter for canonical transcript TSS
  gene_info_canonical <- gene_info %>%
    filter(transcript_is_canonical == 1) %>%
    filter(chromosome_name %in% c(1:22, "X", "Y")) %>%
    distinct(hgnc_symbol, .keep_all = TRUE)
  
  #dist_up_tss <- 1500
  #dist_down_tss <- 500
  
  # define the region around TSS
  gene_ranges <- with(gene_info_canonical, {
    GRanges(
      seqnames = paste0("chr", chromosome_name),
      ranges = IRanges(
        start = ifelse(
          strand == 1,
          transcription_start_site - dist_up_tss,
          transcription_start_site - dist_down_tss
        ),
        end = ifelse(
          strand == 1,
          transcription_start_site + dist_down_tss - 1,
          transcription_start_site + dist_up_tss -1
        )
      ),
      strand = ifelse(strand == 1, "+", "-"),
      gene = hgnc_symbol
    )
  })
  
  # start is >=1
  start(gene_ranges) <- pmax(1, start(gene_ranges))
  
  # get genome
  genome <- BSgenome.Hsapiens.UCSC.hg38
  
  # get sequences
  seqs <- getSeq(genome, gene_ranges)
  
  # make FASTA headers
  fasta_headers <- paste0(
    gene_ranges$gene, "::",
    as.character(seqnames(gene_ranges)), ":",
    start(gene_ranges), "-",
    end(gene_ranges), "(",
    as.character(strand(gene_ranges)), ")"
  )
  
  # name sequences
  names(seqs) <- fasta_headers
  
  # write fasta out
  writeXStringSet(seqs, filepath = paste0(outdir_guides, "/sequences.fa"))
  
  # run get sequence script
  #command_get_sequence <- paste0("bin/get_sequence.sh -i ", input$user_gene_list$datapath, " -r references/hg38.fa -u ", input$dist_up_tss, " -d ", input$dist_down_tss, " -o ", outdir_guides, "/sequences.fa -v")
  #system(command_get_sequence)
  
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