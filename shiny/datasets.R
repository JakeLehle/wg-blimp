library(data.table)
library(yaml)

shiny.wgbs.loadDataTable <- function (fileName) {

  if(file.exists(fileName)) {
    return(fread(fileName))
  }

  return(NULL)
}

shiny.wgbs.loadDataset <- function (configFile) {

  configYaml <- read_yaml(configFile)

  datasetRootPath <- configYaml$output_dir

  bamFileDirectory <- "alignment/"
  multiqcMetricsSubPath <- "qc/multiqc_data/multiqc_general_stats.txt"
  methylationMetricsSubPath <- "qc/methylation_metrics.csv"
  multiqcReportSubPath <- "qc/multiqc_report.html"
  annotatedDmrSubPath <- "dmr/annotated-dmrs.csv"
  qualimapSubPath <- "qc/qualimap"
  segmentationSubDir <- "segmentation/"
  umrLmrSubPath <- paste0(segmentationSubDir, "umr-lmr-all.csv")
  pmdSubPath <- paste0(segmentationSubDir, "pmd-all.csv")

  multiqcColumnsOfInterest <- c(
    "Sample",
    "FastQC_mqc-generalstats-fastqc-percent_duplicates",
    "QualiMap_mqc-generalstats-qualimap-percentage_aligned",
    "QualiMap_mqc-generalstats-qualimap-median_coverage"
  )

  renamedMultiqcColumns <- c(
    "sample",
    "duplication",
    "aligned",
    "coverage"
  )

  multiqcMetrics     <- fread(paste(datasetRootPath, multiqcMetricsSubPath, sep = "/"))
  methylationMetrics <- fread(paste(datasetRootPath, methylationMetricsSubPath, sep = "/"))

  annotatedDmrPath <- paste(datasetRootPath, annotatedDmrSubPath, sep = "/")
  umrLmrPath <- paste(datasetRootPath, umrLmrSubPath, sep = "/")
  pmdPath <- paste(datasetRootPath, pmdSubPath, sep = "/")

  annotatedDmrs <- shiny.wgbs.loadDataTable(annotatedDmrPath)
  umrLmrAll <- shiny.wgbs.loadDataTable(umrLmrPath)
  pmdAll <- shiny.wgbs.loadDataTable(pmdPath)

  snakemakeConfig <- readLines(configFile)

  # WORKAROUND: there are issues with prism.js highlighting yaml syntax with the first
  # paragraph indented by one additional tab. This can't be fixed in a 'shiny' way, so we just
  # add an additional newline to the configuration, making the erroneus additional tab
  # invisible. Also see https://github.com/PrismJS/prism/issues/1447
  snakemakeConfigContent <- paste0("\n", paste(snakemakeConfig, collapse = "\n"))

  selectedMultiqcMetrics <- multiqcMetrics[,multiqcColumnsOfInterest, with = FALSE]
  colnames(selectedMultiqcMetrics) <- renamedMultiqcColumns
  selectedMultiqcMetrics$duplication <- selectedMultiqcMetrics$duplication / 100

  combinedMetrics <- merge(selectedMultiqcMetrics, methylationMetrics, by = "sample")

  return(list(
    summary = combinedMetrics,
    dmrs = annotatedDmrs,
    config = snakemakeConfigContent,
    bamDirectory = paste(datasetRootPath, bamFileDirectory, sep = "/"),
    qualimapDirectory = paste(datasetRootPath, qualimapSubPath, sep = "/"),
    fullReport = paste(datasetRootPath, multiqcReportSubPath, sep = "/"),
    segmentationDirectory = paste(datasetRootPath, segmentationSubDir, sep = "/"),
    umrLmrAll = umrLmrAll,
    pmdAll = pmdAll
  ))
}

shiny.wgbs.loadDatasets <- function (configPathsFile) {

  configFiles <- readLines(configPathsFile)

  datasets <- lapply(configFiles, shiny.wgbs.loadDataset)
  names(datasets) <- basename(dirname(configFiles))

  return(datasets)
}
