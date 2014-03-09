#!/bin/bash
# Copyright (C) 2011 Ion Torrent Systems, Inc. All Rights Reserved

#*! @function
#  @param  $*  the command to be executed

# Function to log command level errors
run ()
{
    if [ "$PLUGIN_DEV_FULL_LOG" -gt 0 ]; then
        echo "\$ $*" >&2
    fi
    local EXIT_CODE=0
    eval $* >&2 || EXIT_CODE="$?"
    if [ ${EXIT_CODE} != 0 ]; then
        echo -e "ERROR: Status code '${EXIT_CODE}' while running\n\$$*" >&2
        if [[ "$CONTINUE_AFTER_BARCODE_ERROR" -eq 0 ]]; then
            # partially produced barcode html might be useful but is left in an auto-update mode
            rm -f "${TSP_FILEPATH_PLUGIN_DIR}/${HTML_RESULTS}" "$JSON_RESULTS"
        fi
        # still have to produce error here to prevent calling code from continuing
        exit 1
    fi
}
export -f run

# produces a title with fly-over help showing users parameters
write_page_title ()
{
    echo "<h1><center><span style=\"cursor:help\" title=\"Minumum Coverage='${PLUGINCONFIG__MINCOVERAGE}'    Amplicon Regions='${PLUGINCONFIG__TARGETREGIONS_ID}'   ${OPTIONS}\">Amplicon Coverage Analysis Report</span></center></h1>" >> "$1"
}

# Calls /html/header.sh
write_page_header ()
{
    local HEADFILE="$1"
    local HTML="${TSP_FILEPATH_PLUGIN_DIR}/header"
    if [ -n "$2" ]; then
        HTML="$2"
    fi
    cat "$HEADFILE" > "$HTML"
    if [ -n "$INPUT_SNP_BED_FILE" ]; then
       echo "<script src=\"lifegrid/AllAmpliconsCoverage.js\"></script>" >> "$HTML"
    fi
    echo '<title>Amplicon Coverage Analysis Report</title>' >> "$HTML"
    echo '</head>' >> "$HTML"
    echo '<body>' >> "$HTML"
    # Calls /html/logo.sh
	print_html_logo >> "$HTML";
    echo "<div class=\"center\" style=\"width:100%;height:100%\">" >> "$HTML"
    write_page_title "$HTML";
}

# Calls /html/footer.sh
write_page_footer ()
{
    local HTML="${TSP_FILEPATH_PLUGIN_DIR}/footer"
    if [ -n "$1" ]; then
        HTML="$1"
    fi
    print_html_footer >> "$HTML"
    echo '<br/><br/></div>' >> "$HTML"
    echo '</body></html>' >> "$HTML"
}

# old header/footer code - still used for barcodes table
write_html_header ()
{
    local HTML="${TSP_FILEPATH_PLUGIN_DIR}/header"
    if [ -n "$1" ]; then
        HTML="$1"
    fi
    local REFRESHRATE=0
    if [ -n "$2" ]; then
	REFRESHRATE=$2
    fi
    echo '<?xml version="1.0" encoding="iso-8859-1"?>' > "$HTML"
    echo '<!DOCTYPE html>' >> "$HTML"
    echo '<html>' >> "$HTML"
    print_html_head $REFRESHRATE >> "$HTML"
    echo '<title>Amplicon Coverage Analysis Report</title>' >> "$HTML"
    echo '<body>' >> "$HTML"
    print_html_logo >> "$HTML";

    if [ -z "$COV_PAGE_WIDTH" ];then
	echo '<div id="inner">' >> "$HTML"
    else
	echo "<div style=\"width:${COV_PAGE_WIDTH}px;margin-left:auto;margin-right:auto;height:100%\">" >> "$HTML"
    fi
    write_page_title "$HTML";
}

write_html_footer ()
{
    local HTML="${TSP_FILEPATH_PLUGIN_DIR}/footer"
    if [ -n "$1" ]; then
        HTML="$1"
    fi
    print_html_end_javascript >> "$HTML"
    print_html_footer >> "$HTML"
    echo '<br/><br/></div>' >> "$HTML"
    echo '</body></html>' >> "$HTML"
}

display_static_progress ()
{
    local HTML="${TSP_FILEPATH_PLUGIN_DIR}/${HTML_RESULTS}"
    if [ -n "$1" ]; then
        HTML="$1"
    fi
    echo "<br/><h3 style=\"text-align:center;color:red\">*** Analysis is not complete ***</h3>" >> "$HTML"
    echo "<a href=\"javascript:document.location.reload();\" ONMOUSEOVER=\"window.status='Refresh'; return true\">" >> "$HTML"
    echo "<div style=\"text-align:center\">Click here to refresh</div></a>" >> "$HTML"
}

write_json_header ()
{
    local haveBC="false"
    if [ -n "$1" ]; then
		if [ $1 -eq 0 ]; then
	    	haveBC="false"
		else
	    	haveBC="true"
		fi
    fi
    echo "{" > "$JSON_RESULTS"
    echo "  \"Target Regions\" : \"$PLUGINCONFIG__TARGETREGIONS_ID\"," >> "$JSON_RESULTS"
	echo "  \"Minimum Coverage\" : \"$PLUGINCONFIG__MINCOVERAGE\"," >> "$JSON_RESULTS"
    echo "  \"barcoded\" : \"$haveBC\"," >> "$JSON_RESULTS"

    if [ "$haveBC" = "true" ]; then
        echo "  \"barcodes\" : {" >> "$JSON_RESULTS"
    fi
}

write_json_footer ()
{
    if [ -n "$1" ]; then
		if [ $1 -ne 0 ]; then
	    	echo -e "\n  }" >> "$JSON_RESULTS"
        fi
    fi
    echo -e "\n}" >> "$JSON_RESULTS"
}

write_json_inner ()
{
    local DATADIR=$1 # Plugin Barcode output dir
    local DATASET=$2 # $PLUGIN_OUT_COVERAGE_STATS => statTable.txt
    local BLOCKID=$3 # "'coverage_statistics'"
    local INDENTLEV=$4 # '6'
    if [ -f "${DATADIR}/${DATASET}" ];then
	append_to_json_results "$JSON_RESULTS" "${DATADIR}/${DATASET}" "$BLOCKID" $INDENTLEV;
    fi
}

#*! @function
#  @param $1 Name of JSON file to append to
#  @param $2 Path to file composed of <name>:<value> lines
#  @param $3 block name (e.g. "filtered_reads")
#  @param $4 printing indent level. Default: 2
append_to_json_results ()
{
    local JSONFILE="$1"  
    local DATAFILE="$2"  # Plugin Barcode output dir/statTable.txt
    local DATASET="$3"   # 'coverage_statistics' 
    local INDENTLEV="$4"
    if [ -z $INDENTLEV ]; then
        INDENTLEV=2
    fi
    local JSONCMD="${SCRIPTSDIR}/coverage_analysis_json.pl -a -I $INDENTLEV -B \"$DATASET\" \"$DATAFILE\" \"$JSONFILE\""
    eval "$JSONCMD || echo \"WARNING: Failed to write to JSON from $DATAFILE\"" >&2
}
