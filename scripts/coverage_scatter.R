# Create a length vs median coverage scatterplot

Sys.time()
getwd()

# Get some commandline args
args <- commandArgs( trailingOnly = TRUE )
if( length( args ) !=3 ) stop( "Script requires 3 arguments: sample_name, minimum_coverage_threshold, and output dir." )
sample <- args[1]
threshold <- args[2]
outdir <- args[3]

# Make sure we have ggplot2 installed
if(!require(ggplot2)) stop( "Need to install ggplot2" )

file <- paste0( outdir, "/AllAmpliconsCoverage.tsv" )
coverage_data <- read.table( file = file, sep = "\t", header = TRUE ) 

scatter <- ggplot( coverage_data, aes( x = Length, y = Median ) ) +
           theme_bw() +
           geom_point() +
           geom_hline( yintercept = as.numeric(threshold), linetype = "dashed", color = "blue" ) +
           xlab( "Length of Amplicon" ) +
           ylab( "Median Coverage for Amplicon" ) +
           ggtitle( paste0( "Coverage Versus Amplicon Length Plot for ", sample ) )

ggsave( filename = paste0( outdir, "/Amp_Coverage_vs_Length_Plot.png" ), plot = scatter )
ggsave( filename = paste0( outdir, "/Amp_Coverage_vs_Length_Plot.pdf" ), plot = scatter )
