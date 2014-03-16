#!/bin/bash
# Modified from Life Tech fileLinks.sh script to generate file links for download from AmpliconCoveragePlots plugin
# Created 10/27/2012

write_file_links()
{
local OUTDIR="$TSP_FILEPATH_PLUGIN_DIR"
if [ -n ${1} ]; then
    OUTDIR=${1}
fi
local FILENAME="filelinks.xls"
if [ -n ${2} ]; then
    FILENAME=${2}
fi
local OUTFILE="${OUTDIR}/${FILENAME}"

echo -e "Text\tLink" > "$OUTFILE"
if [ -f "${OUTDIR}/$pluginAmpCovTable" ]; then
	echo -e "Download median coverage data for all amplicons as a table file.\t${pluginAmpCovTable}" >> "$OUTFILE"
fi
if [ -f "${OUTDIR}/$pluginLowAmpTable" ]; then
	echo -e "Download median coverage data for amplicons below minimum coverage threshold as a table file.\t${pluginLowAmpTable}" >> "$OUTFILE"
fi
if [ -f "${OUTDIR}/$PLUGIN_SCATTER_PLOT_PDF" ]; then
	echo -e "Download scatter plot of all amplicons median coverage vs length of amplicon as a pdf file.\t$PLUGIN_SCATTER_PLOT_PDF" >> "$OUTFILE"
fi
if [ -f "${OUTDIR}/$STRAND_COVERAGE_PLOT" ]; then
	echo -e "Download bar plot image file of read strand information for all amplicons.\t$STRAND_COVERAGE_PLOT" >> "$OUTFILE"
fi
if [ -f "${OUTDIR}/$HIGH_BIAS_PLOT" ]; then
	echo -e "Download bar plot image file of read strand information for amplicons showing strand bias.\t$HIGH_BIAS_PLOT" >> "$OUTFILE"
fi
}
