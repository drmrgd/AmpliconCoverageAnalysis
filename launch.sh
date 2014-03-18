#!/bin/bash
# Launch script for the AmpliconCoverageAnalysis plugin.  This project forked from the full AmpliconCoveragePlots
# plugin project in order to create a more lightweight and faster tool for routine QC analysis.  Still retaining
# barcode vs non-barcode functionality along with similar output. 
#
# 3/3/2014 - D Sims
#
#autorundisable
######################################################################################################################

VERSION="0.6.031814"

# Set up ENV vars to be used throughout
export PLUGIN_DEV_FULL_LOG=0  # 0 => off; 1 => simple logging; 2 => xtrace logging 
export PLUGIN_DEV_KEEP_INTERMEDIATE_FILES=0 # Get rid of extra dev files; 1 for on, 0 for off

export MINBAMSIZE="200000" 
export SCRIPTSDIR="${DIRNAME}/scripts"
export PLUGIN_BAM_FILE=$(echo "$TSP_FILEPATH_BAM" | sed -e 's/^.*\///')
export PLUGIN_BAM_NAME=$(basename $PLUGIN_BAM_FILE)

export PLUGIN_RUN_NAME="$TSP_RUN_NAME"

export PLUGIN_OUT_COVERAGE_STATS="stat_table.txt"
export pluginAmpCovTable="AllAmpliconsCoverage.tsv" # Amplicon Coverage Table
export pluginLowAmpTable="LowCoverageAmplicons.tsv" # Low coverage amplicons table
export STRAND_COVERAGE_PLOT="all_coverage_bias.png" # Amplicon strand coverage plot
export HIGH_BIAS_PLOT="strand_bias.png" # Plot of high variable amplicons
export PLUGIN_SCATTER_PLOT_PNG="Amp_Coverage_vs_Length_Plot.png" # Scatterplot generated by R Script
export PLUGIN_SCATTER_PLOT_PDF="Amp_Coverage_vs_Length_Plot.pdf" # Scatterplot generated by R Script
export PLUGIN_OUT_FILELINKS="filelinks.xls" # => Use for links to data for download.

export BARCODES_LIST="${TSP_FILEPATH_PLUGIN_DIR}/barcodeList.txt";
export JSON_RESULTS="${TSP_FILEPATH_PLUGIN_DIR}/results.json"

export PLUGIN_OUT_COVERAGE_HTML="coverage.html" 
export HTML_BLOCK="AmpliconCoverageAnalysis_block.html";
export HTML_RESULTS="${PLUGINNAME}.html"
export HTML_ROWSUMS="${PLUGINNAME}_rowsum"


# Source the HTML files for shell functions and define others below  
for HTML_FILE in $(find ${DIRNAME}/html/ | grep .sh$)
do
    source ${HTML_FILE};
done

# Get the Plugin Conf Variables and make sure they're valid
if [[ ! -e "$PLUGINCONFIG__TARGETREGIONS" ]]; then
	echo "ERROR: You failed to select a Regions BED file or the file can not be found!"
	exit 1
else
    export INPUT_BED_FILE="$PLUGINCONFIG__TARGETREGIONS"
    echo "Regions BED file found: $INPUT_BED_FILE"
fi

if [[ "$PLUGINCONFIG__MINCOVERAGE" -le 0 ]]; then
	echo "ERROR:  You failed to enter a value for the minimum coverage threshold.  Please enter a threshold greater than zero"
	exit 1
else
	export MINCOVERAGE=$PLUGINCONFIG__MINCOVERAGE
	echo "The minimum coverage threshold has been set to: $MINCOVERAGE"
fi

# Grab a local copy of the Regions BED file
export REGIONS_BED=$(echo "$INPUT_BED_FILE" | sed -e 's/^.*\///')
printf "\nMaking a local copy of the Regions BED file: %s\n\n" $REGIONS_BED
run "cp -f ${INPUT_BED_FILE} ${RESULTS_DIR}/$REGIONS_BED"

# Set up logging options for commands
export ERROUT="2> /dev/null"
export LOGOPT=""
if [[ "$PLUGIN_DEV_FULL_LOG" -gt 0 ]]; then
	ERROUT=""
	LOGOPT="-l"
	if [[ "$PLUGIN_DEV_FULL_LOG" -gt 1 ]]; then
		set -o xtrace
	fi
fi

export LOG4CXX_CONFIGURATION="${DIRNAME}/log4j.properties";
export PLUGIN_OUT_VCTRACE="acp.log"
export PLUGIN_OUT_VCWARN="acp.warn"

#####-------------------------------- START OF HTML FOMATTING SECTION ----------------------------------######

# These are only used to define HTML layouts (handled below)
LIFEGRIDDIR="${DIRNAME}/lifegrid"
BC_SUM_ROWS=8
BC_COV_PAGE_WIDTH=1200
COV_PAGE_WIDTH=1200
BC_COL_TITLE[0]="Sample Name"
BC_COL_TITLE[1]="Mapped Reads"
BC_COL_TITLE[2]="Number of Amplicons"
BC_COL_TITLE[3]="Number Below Threshold"
BC_COL_TITLE[4]="Percent Below Threshold"
BC_COL_TITLE[5]="25% Quartile"
BC_COL_TITLE[6]="50% Quartile"
BC_COL_TITLE[7]="75% Quartile"
BC_COL_HELP[0]="Name of the sample derived from the run plan."
BC_COL_HELP[1]="Number of reads that were mapped to the reference for this barcode run."
BC_COL_HELP[2]="The total number of amplicons in the panel"
BC_COL_HELP[3]="The total number of amplicons that fell below the threshold."
BC_COL_HELP[4]="The percent of the amplicons that fell below the threshold."
BC_COL_HELP[5]="The 25% quartile coverage."
BC_COL_HELP[6]="The 50% quartile coverage."
BC_COL_HELP[7]="The 75% quartile coverage."

# Set by barcode iterator if there is a failure of any single barcode
BC_ERROR=0

write_html_results ()
{
    local RUNID=${1}
    local OUTDIR=${2}
    local OUTURL=${3}
    local BAMFILE=${4}
    # Create softlink to js/css folders and php script
	run "ln -sf \"${DIRNAME}/slickgrid\" \"${OUTDIR}/\"";
    run "ln -sf \"${DIRNAME}/lifegrid\" \"${OUTDIR}/\"";
    run "ln -sf ${DIRNAME}/scripts/*.php3 \"${OUTDIR}/\"";

	# Create the html report page
    printf "\nGenerating html report...\n" >&2
    local HTMLOUT="${OUTDIR}/${HTML_RESULTS}";
	write_page_header "$LIFEGRIDDIR/ACP.head.html" "$HTMLOUT"; # function in  /html/common.sh
    cat "${OUTDIR}/$PLUGIN_OUT_COVERAGE_HTML" >> "$HTMLOUT"
	echo "<div><img class=\"scatterplot\" src=\"${PLUGIN_SCATTER_PLOT_PNG}\" width=\"600\" height=\"600\"></div><br/><br/>" >> "$HTMLOUT"
	echo "<div><img class=\"scatterplot\" src=\"${STRAND_COVERAGE_PLOT}\" width=\"900\" height=\"450\"></div><br/><br/>" >> "$HTMLOUT"
	echo "<div><img class=\"scatterplot\" src=\"${HIGH_BIAS_PLOT}\" width=\"900\" height=\"450\"></div><br/><br/>" >> "$HTMLOUT"
	echo "<div id=\"LowAmpliconsCoverage\" fileurl=\"${pluginLowAmpTable}\" class=\"center\"></div><br/>" >> "$HTMLOUT"
	echo "<div id=\"AllAmpliconsCoverage\" fileurl=\"${pluginAmpCovTable}\" class=\"center\"></div><br/>" >> "$HTMLOUT"
    
	# output warning messages, if any
    local KEEP_TMP_FILES="$PLUGIN_DEV_KEEP_INTERMEDIATE_FILES"
    if [ -f "${OUTDIR}/$PLUGIN_OUT_VCWARN" ];then
        echo "<h3 style=\"text-align:center;color:red\">Warning: " >> "$HTMLOUT"
        run "cat \"${OUTDIR}/$PLUGIN_OUT_VCWARN\" >> \"$HTMLOUT\""
        echo "</h3><br/>" >> "$HTMLOUT"
        KEEP_TMP_FILES=1
    fi
    
	write_file_links "$OUTDIR" "$PLUGIN_OUT_FILELINKS" >> "$HTMLOUT";
    echo "<div id=\"fileLinksTable\" fileurl=\"${PLUGIN_OUT_FILELINKS}\" class=\"center\"></div>" >> "$HTMLOUT"
    write_page_footer "$HTMLOUT";
    return 0
}

PLUGIN_CHECKBC=1
# Local copy of sorted barcode list file
if [ ! -f $TSP_FILEPATH_BARCODE_TXT ]; then
   PLUGIN_CHECKBC=0
fi
if [[ $PLUGIN_CHECKBC -eq 1 ]]; then
	echo "$TSP_FILEPATH_BARCODE_TXT" | sort -t ' ' -k 2n,2 > "$BARCODES_LIST"
fi

# Make links to js/css used for barcodes table and empty results page
run "ln -sf \"${DIRNAME}/js\" \"${TSP_FILEPATH_PLUGIN_DIR}/\"";
run "ln -sf \"${DIRNAME}/css\" \"${TSP_FILEPATH_PLUGIN_DIR}/\"";

# Run for barcodes or single page
if [[ $PLUGIN_CHECKBC -eq 1 ]]; then
    printf "Barcoded run detected.  Checking for barcodes to be processed...\n"
    # barcode funtion in html/barcode.sh
	barcode;  # run barcode method in html/barcode.sh
else
    # Write a front page for non-barcode run 
    # TODO: add non-barcode run functionality just in case
	printf "Non-barcoded run detected.\n"
    echo
    echo "**** The plugin is not yet capable of a non-barcoded run *****"
    echo
    exit 1
      #printf "Processing file %s...\n" "${TSP_FILEPATH_BAM}"
  	echo "Processing file $PLUGIN_BAM_FILE..." 
	HTML="${TSP_FILEPATH_PLUGIN_DIR}/${HTML_RESULTS}"
    write_html_header "$HTML" 15;
    echo "<h3><center>${PLUGIN_RUN_NAME}</center></h3>" >> "$HTML"
    display_static_progress "$HTML";
    write_html_footer "$HTML";
    RT=0 
	
	# Size up BAM file
	export BFSIZE=$(samtools view -c -F 4 $PLUGIN_BAM_FILE)

	printf "\nSUMMARY OF ANALYSIS SETTINGS\n"
	printf "Number of reads in BAM file: \t\t%d\n" $BFSIZE
	printf "Using minimum coverage threshold: \t%s\n" $minCoverage
	printf "Using Regions BED file: \t\t%s\n" $pluginRegionsBED
	
	# call R script on non-barcoded run
	printf "Running coverage analysis on BAM file...\n"
    echo "*** END of SCRIPT.  PATCH IN NEW ANALYSIS SCRIPTS HERE ***"
    # TODO put in new scripts here

    run "${SCRIPTSDIR}/amplicon_coverage.pl -r $BFSIZE -t $MINCOVERAGE $REGIONS_BED $PLUGIN_BAM_FILE" || RT=$?
    run "Rscript ${SCRIPTSDIR}/coverage_scatter.R sample $MINCOVERAGE" || RT=$?

    if [ $RT -ne 0 ]; then
        write_html_header "$HTML";
        echo "<h3><center>${PLUGIN_RUN_NAME}</center></h3>" >> "$HTML"
        echo "<br/><h3 style=\"text-align:center;color:red\">*** An error occurred - check Log File for details ***</h3><br/>" >> "$HTML"
        write_html_footer "$HTML";
        exit 1
    fi

	# Generate coverage statistics for BAM file for HTML Report output
    # TODO modify this call to point to a new call
    run "eval \"${SCRIPTSDIR}/coverage_statistics.sh\" \"$PLUGIN_RUN_NAME\" \"$TSP_FILEPATH_PLUGIN_DIR\" \".\" \"$TSP_FILEPATH_BAM\""

    # Collect results for detail html report and clean up
	write_html_results "$PLUGIN_RUN_NAME" "$TSP_FILEPATH_PLUGIN_DIR" "." "$PLUGIN_BAM_FILE"

	# Write json output
    write_json_header 0;

    write_json_inner "$TSP_FILEPATH_PLUGIN_DIR" "$PLUGIN_OUT_COVERAGE_STATS" "coverage_statistics" 2;
    write_json_footer;

    if [ "$PLUGIN_DEV_KEEP_INTERMEDIATE_FILES" -eq 0 ]; then
        printf "\nFinalizing and cleaning up intermediate files...\n"
		run "rm -f ${TSP_FILEPATH_PLUGIN_DIR}/*_stats.txt \"${TSP_FILEPATH_PLUGIN_DIR}/$HTML_ROWSUMS\"" 
		run "rm -f \"${PLUGIN_OUT_COVERAGE_HTML}\" \"${TSP_FILEPATH_PLUGIN_DIR}/Rplots.pdf\""
	fi
    echo "...done!"
    echo
fi
