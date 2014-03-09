#!/bin/bash
# Driver script for barcoded runs.  

barcode_load_list ()
{
    local ROWSUM_NODATA=""
    local NTAB
    for((NTAB=1;NTAB<${BC_SUM_ROWS};NTAB++)); do
        ROWSUM_NODATA="${ROWSUM_NODATA}<td style=\"text-align: center\">N/A</td> "
    done
    
    local BCN=0
    local BFSIZE
    local barcodeBAM
    local barcodeName
	local bamToProcess=()

    #local FILTERCMD="grep ^barcode $BARCODES_LIST | cut -d -f2"
	for barcodeName in $(cat ${TSP_FILEPATH_BARCODE_TXT} | grep "^barcode" | cut -d, -f2)
    do
        BARCODES[$BCN]=${barcodeName} 
        # TODO: uncomment
        #BARCODE_ROWSUM[$BCN]="<td style=\"text-align:center\">N/A</td> $ROWSUM_NODATA"
        barcodeBAM="${ANALYSIS_DIR}/${barcodeName}_${PLUGIN_BAM_NAME}"
        if [ -f "$barcodeBAM" ]; then
            # test file size
			BFSIZE=$(samtools view -c -F 4 $barcodeBAM)
			if [[ $BFSIZE -ge $MINBAMSIZE ]]; then
				printf "%s is large enough to be processed.\n\n" $barcodeBAM
				BARCODES_OK[${BCN}]=1
				bamToProcess+=("$barcodeBAM")
                BAMSIZE[$barcodeName]=$BFSIZE
            else
                printf "%s does not have enough reads to be processed.  Skipping...\n\n" $barcodeBAM
                # TODO: uncomment
                #BARCODE_ROWSUM[$BCN]="<td style=\"text-align:center\">${BFSIZE}</td> $ROWSUM_NODATA"
                BARCODES_OK[${BCN}]=3
            fi
        else
            BARCODES_OK[${BCN}]=0
        fi
        BCN=`expr ${BCN} + 1`
    done
	if [[ ${#bamToProcess[@]} == 0 ]]; then
		printf "WARNING: There were no BAM files with enough reads to be processed (at least $bamMinSize reads).\n"
	  	printf "\t You may need to adjust the minimum number of reads to a lower threshold\n"
		exit 1
	else
		printf "There are %s barcoded BAM files to be processed...\n\n" ${#bamToProcess[@]}
	fi
}

barcode_partial_table ()
{
    local HTML="${TSP_FILEPATH_PLUGIN_DIR}/${HTML_RESULTS}"
    if [ -n "$1" ]; then
        HTML="$1"
    fi
    local NLINES=0
    if [ -n "$2" ]; then
        NLINES="$2"
    fi
    local REFRESHRATE=5
    if [ $NLINES -eq $NBARCODES ]; then
	    REFRESHRATE=0
    fi
    write_html_header "$HTML" $REFRESHRATE
    #barcode_links "$HTML" $NLINES 0
    barcode_links "$HTML" $NLINES 1
    write_html_footer "$HTML"

    # Write table to block output.
    echo "" > "${HTML_BLOCK}" # Truncate existing file - barcode_links only appends as it is used above
    barcode_links "$HTML_BLOCK" $NLINES 1
}

barcode_links ()
{
    local HTML="${TSP_FILEPATH_PLUGIN_DIR}/${HTML_RESULTS}"
    if [ -n "1" ]; then
        HTML="$1"
    fi
    local NLINES=-1;  # -1 => all, 0 => none
    if [ -n "$2" ]; then
        NLINES="$2"
    fi
    local IS_BLOCK=0;
    if [ -n "$3" ]; then
        IS_BLOCK="$3"
    fi
    
    if [ $IS_BLOCK -eq 1 ]; then
        echo "<!DOCTYPE html>" >> $HTML
        echo "<html lang=\"en\">" >> $HTML
        echo "  <head>" >> $HTML
        echo "    <base target=\"_parent\"/>" >> $HTML
        echo "    <link rel=\"stylesheet\" media=\"all\" href=\"/site_media/resources/bootstrap/css/bootstrap.min.css\">" >> $HTML
        echo "    <style type=\"text/css\">" >> "$HTML"
        echo "      table {font-family: "Lucida Sans Unicode", \"Lucida Grande\", Sans-Serif; font-size: 12px; cellspacing: 0; cellpadding: 0}" >> "$HTML"
        echo "      td{border: 0px solid #BBB;overflow: visible;color: black}" >> "$HTML"
        echo "      th{border: 1px solid #BBB;overflow: visible;background-color: #E4E5E4;}" >> "$HTML"
        echo "      p, ul{font-family: \"Lucida Sans Unicode\", \"Lucida Grande\", Sans-Serif;}" >> "$HTML"
        echo "      .zebra {  background-color: #E1EFFA;}" >> "$HTML"
        echo "      .table_hover{	color: #009;	background-color: #6DBCEE;}" >> "$HTML"
        echo "    </style></head><body>" >> "$HTML"
    else
        echo "   <div id=\"BarcodeList\" class=\"report_block\"/>" >> "$HTML"
        echo "    <h2>Individual Barcode Coverage Report</h2>" >> "$HTML"
        echo "    <div>" >> "$HTML"
        echo "     <br/>" >> "$HTML"
        echo "     <style type=\"text/css\">" >> "$HTML"
        echo "      th {text-align:center;width=100%}" >> "$HTML"
        echo "      td {text-align:right;width=100%}" >> "$HTML"
        echo "      .help {cursor:help; border-bottom: 1px dotted #A9A9A9}" >> "$HTML"
        echo "     </style>" >> "$HTML"
    fi

    echo "     <table class=\"noheading\" style=\"table-layout:fixed\">" >> "$HTML"
    echo "      <tr>" >> "$HTML"
    echo "      <th style=\"width:150px !important\"><span class=\"help\" title=\"The barcode ID for each set of reads.\">Amplicon Coverage Analysis Reports</span></th>" >> "$HTML"

    echo "       <th style=\"width:150px !important\"><span class=\"help\" title=\"${BC_COL_HELP[0]}\">${BC_COL_TITLE[0]}</span></th>" >> "$HTML"
    local BCN
    for((BCN=1;BCN<${BC_SUM_ROWS};BCN++))
    do
        echo "       <th style=\"width:86px !important\"><span class=\"help\" title=\"${BC_COL_HELP[$BCN]}\">${BC_COL_TITLE[$BCN]}</span></th>" >> "$HTML"
    done
    echo "      </tr>" >> "$HTML"

    local BARCODE
    local UNFIN=0
    for((BCN=0;BCN<${#BARCODES[@]};BCN++))
    do
        if [ $NLINES -ge 0 -a $BCN -ge $NLINES ]; then
            UNFIN=1
            break
        fi
        if [ $IS_BLOCK -eq 1 ]; then
          if [ ${BARCODES_OK[$BCN]} -ne 1 ]; then
            continue
          fi
        fi
        BARCODE=${BARCODES[$BCN]}
        echo "      <tr>" >> "$HTML"
        if [ ${BARCODES_OK[$BCN]} -eq 1 ]; then
            # TODO: continue to work on this section for formatting.  Looking good so far!
            if [ $IS_BLOCK -eq 1 ]; then
				echo "       <td style=\"text-align:center\">" >> $HTML
                echo "          <a href=\"${BARCODE}/${HTML_RESULTS}\" style=\"cursor:help\">" >> $HTML
                echo "             <span title=\"Coverage report for barcode ${BARCODE}\">" >> $HTML
                echo "                <b>${BARCODE}</b>" >> $HTML
                echo "             </span></td>" >> "$HTML"
                echo "          </a>" >> $HTML
            else
               echo "       <td style=\"text-align:left\"><a style=\"cursor:help\" href=\"${BARCODE}/${HTML_RESULTS}\"><span title=\"Click to view the detailed coverage report for barcode ${BARCODE}\">${BARCODE}</span></a></td>" >> "$HTML"
            fi   
            #TODO: see if I can remove this too.  Not going to display null data in the report
        elif [ ${BARCODES_OK[$BCN]} -eq 2 ]; then
            echo "       <td style=\"text-align:left\"><span class=\"help\" title=\"Barcode ${BARCODE} was not processed. Check Log File.\" style=\"color:red\">${BARCODE}</span></td>" >> "$HTML"
        elif [ ${BARCODES_OK[$BCN]} -eq 3 ]; then
            echo "       <td style=\"text-align:left\"><span class=\"help\" title=\"Barcode ${BARCODE} was not processed. Number of mapped reads was too few for Coverage Analysis.\" style=\"color:grey\">${BARCODE}</span></td>" >> "$HTML"
        else
            echo "       <td style=\"text-align:left\"><span class=\"help\" title=\"No Data for barcode ${BARCODE}\" style=\"color:grey\">${BARCODE}</span></td>" >> "$HTML"
        fi
        echo "           ${BARCODE_ROWSUM[$BCN]}" >> "$HTML"
        echo "      </tr>" >> "$HTML"
    done

    echo "     </table></div>" >> "$HTML"
    if [ $UNFIN -eq 1 ]; then
          if [ $IS_BLOCK -eq 1 ]; then
	echo "<p>Analysis in progress...</p>" >> "$HTML"
          else
	display_static_progress "$HTML"          
          fi	
    fi
    echo "   </div>" >> "$HTML"
}

barcode_append_to_json_results ()
{
    local BARCODE=$1
    if [ -n "$2" ]; then
        if [ "$2" -gt 1 ]; then
            echo "," >> "$JSON_RESULTS"
        fi
    fi
    echo "    \"$BARCODE\" : {" >> "$JSON_RESULTS"
    write_json_inner "$BARCODE_DIR" "$PLUGIN_OUT_COVERAGE_STATS" "coverage_statistics" 6;
    echo -n "    }" >> "$JSON_RESULTS"
}

barcode ()
{
    # Load bar code ID and check for corresponding BAM files
    local BARCODES
    local BARCODE_IDS
    local BARCODES_OK
    local BARCODE_ROWSUM

    declare -A BAMSIZE

    barcode_load_list;
    NBARCODES=${#BARCODES[@]}

    # Start json file
    write_json_header 1;

    # Empty Table - BARCODE set because header file expects this load javascript
    local BARCODE="TOCOME"
    local HTMLOUT="${TSP_FILEPATH_PLUGIN_DIR}/${HTML_RESULTS}"
    barcode_partial_table "$HTMLOUT";
    
    # Go through the barcodes 
    local BARCODE_DIR
    local BARCODE_BAM
    local NLINE
    local BCN
    local BC_DONE
    local NJSON=0
    local samplekey_file="${TSP_FILEPATH_PLUGIN_DIR}/samplekey.txt"
    declare -A SAMPLEKEY

    for((BCN=0;BCN<${NBARCODES};BCN++))
    do
        BARCODE=${BARCODES[$BCN]}
        export BARCODE_DIR="${TSP_FILEPATH_PLUGIN_DIR}/${BARCODE}"
        BARCODE_URL="."
        export BARCODE_BAM="${ANALYSIS_DIR}/${BARCODE}_${PLUGIN_BAM_NAME}"
		NLINE=`expr ${BCN} + 1`

		if [[ ${BARCODES_OK[$BCN]} -eq 1 ]]; then
        	# perform coverage anaysis and write content
			printf "\nProcessing BAM file: %s...\n\n" $BARCODE_BAM
        	printf "Creating output results directory: %s/...\n" ${BARCODE_DIR}
			run "mkdir -p \"${BARCODE_DIR}\""
        	local RT=0

            # Get the sample names from the run plan
            run "sampleKeyGen -f ${ANALYSIS_DIR}/basecaller_results/datasets_pipeline.json -o $samplekey_file" 
            while read -a sample;
            do
                SAMPLEKEY[${sample[0]}]=${sample[1]}
            done < $samplekey_file

			# Quick summary of what we're running.
			printf "\nSUMMARY OF ANALYSYS SETTINGS\n"
			printf "Using barcode suffix: \t\t\t%s\n" $BARCODE
            printf "Sample name: \t\t\t\t%s\n" ${SAMPLEKEY[$BARCODE]}
            printf "Number of reads: \t\t\t%d\n" ${BAMSIZE[$BARCODE]}
			printf "Using minimum coverage threshold: \t%s\n" $MINCOVERAGE
			printf "Using Regions BED file: \t\t%s\n\n" $REGIONS_BED
			printf "Running coverage analysis on BAM file...\n"
            
            # TODO: add new scripts here.
            run "eval \"$SCRIPTSDIR/amplicon_coverage.pl -s ${SAMPLEKEY[$BARCODE]} -t $MINCOVERAGE -r ${BAMSIZE[$BARCODE]} -o $BARCODE_DIR $REGIONS_BED $BARCODE_BAM\"" || RT=0
            run "eval \"Rscript $SCRIPTSDIR/coverage_scatter.R ${SAMPLEKEY[$BARCODE]} $MINCOVERAGE $BARCODE_DIR\"" || RT=0

            # Check return code for errors
			if [[ $RT -ne 0 ]]; then
        		BC_ERROR=1
        		if [[ "$CONTINUE_AFTER_BARCODE_ERROR" -eq 0 ]]; then
            		exit 1
            	else
            		BARCODES_OK[${BCN}]=2
                fi
            else
				# Generate coverage statistics for Barcoded BAM file for HTML Report output
                # Variables for the HTML output and reports
                local secondary_title="${BARCODE}:${SAMPLEKEY[$BARCODE]}"
                local barcode_rowsumfile="${BARCODE_DIR}/${HTML_ROWSUMS}"
                local outhtml="${BARCODE_DIR}/$PLUGIN_OUT_COVERAGE_HTML"
                local stats="${BARCODE_DIR}/$PLUGIN_OUT_COVERAGE_STATS"

                # Non-block output
                run "eval \"$SCRIPTSDIR/coverage_analysis_report.pl -t $secondary_title -T $barcode_rowsumfile -d $PLUGIN_DEV_FULL_LOG $outhtml $stats\""

                # Block output 
                run "eval \"$SCRIPTSDIR/coverage_analysis_report.pl -t $secondary_title -T $barcode_rowsumfile -d $PLUGIN_DEV_FULL_LOG -b 1 $HTML_BLOCK $stats\""

				# process all result files to detailed html page and clean up
            	write_html_results "$secondary_title" "$BARCODE_DIR" "$BARCODE_URL" "$BARCODE_BAM"

            	# collect table summary results
            	if [ -f "$barcode_rowsumfile" ]; then
                	BARCODE_ROWSUM[$BCN]=`cat "$barcode_rowsumfile"`
            	fi
            	NJSON=`expr ${NJSON} + 1`
	    	    barcode_append_to_json_results $BARCODE $NJSON;
        	fi
			if [[ "$PLUGIN_DEV_KEEP_INTERMEDIATE_FILES" -eq 0 ]]; then
				if [ -e "$barcode_rowsumfile" ]; then	
                    run "rm \"$barcode_rowsumfile\""
				fi
			fi
		fi
	barcode_partial_table "$HTMLOUT" $NLINE
    done

    # finish up with json
    write_json_footer 1;
    if [[ "$BC_ERROR" -ne 0 ]]; then
        exit 1
    fi

	# Cleanup
    # TODO set cleanup
	#if [[ "$PLUGIN_DEV_KEEP_INTERMIDIATE_FILES" -eq 0 ]]; then
		#printf "\nFinalizing and cleaning up intermediate files...\n"
		#run "rm \"${RESULTS_DIR}/Rplots.pdf\""
		#run "rm \"${RESULTS_DIR}/barcodeList.txt\""
		#printf "...done!\n"
	#fi
}
