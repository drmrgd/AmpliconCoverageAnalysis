# Create a length vs median coverage scatterplot

Sys.time()
getwd()

# Get some commandline args
args <- commandArgs( trailingOnly = TRUE )
if( length( args ) !=2 ) stop( "Script requires 2 arguments: sample_name and minimum_coverage_threshold." )
sample <- args[1]
threshold <- args[2]

# Make sure we have ggplot2 installed
if(!require(ggplot2)) stop( "Need to install ggplot2" )

file <- "AllAmpliconsCoverage.tsv"
coverage_data <- read.table( file = file, sep = "\t", header = TRUE ) 

scatter <- ggplot( coverage_data, aes( x = Length, y = Median ) ) +
           theme_bw() +
           geom_point() +
           geom_hline( yintercept = as.numeric(threshold), linetype = "dashed", color = "blue" ) +
           xlab( "Length of Amplicon" ) +
           ylab( "Median Coverage for Amplicon" ) +
           ggtitle( paste0( "Coverage Versus Amplicon Length Plot for ", sample ) )

ggsave( filename = "Amp_Coverage_vs_Length_Plot.png", plot = scatter )
ggsave( filename = "Amp_Coverage_vs_Length_Plot.pdf", plot = scatter )
