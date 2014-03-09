// html for AllAmplicons Coverage table container - note these are invisible and moved into position later
document.write('\
<div id="AA-tablecontent" style="display:none">\
  <div id="AA-titlebar" class="grid-header">\
    <span id="AA-collapseGrid" style="float:left" class="ui-icon ui-icon ui-icon-triangle-1-n" title="Collapse view"></span>\
    <span class="table-title">Coverage Data for All Amplicons in the Panel</span>\
	<span id="AA-toggleFilter" style="float:right" class="ui-icon ui-icon-search" title="Toggle search/filter panel"></span>\
	<span id="AA-message" class="message"></span>\
  </div>\
  <div id="AA-grid" class="grid-body"></div>\
  <div id="AA-pager" class="grid-footer"></div>\
  <p class="grid-text"/>\
</div>\
<div id="AA-filterpanel" class="filter-panel" style="display:none">\
	<table style="width:100%"><tr><td>\
		<span class="nwrap">Amplicon ID <input type="text" id="AA-txtSearchAmpID" class="txtSearch" size=7 value=""></span>\
		<span class="nwrap">Gene Name <input type="text" id="AA-txtSearchGeneID" class="tstSerch" size=7 value=""></span>\
		<span class="nwrap">Median &le; <input type="text" id="AA-txtSearchCovMin" class="numSearch" size=7 value=""></span>\
		<span class="nwrap">Amplicon Length Between <input type="text" class="numSearch" id="AA-txtSearchLengthMin" size=4 value="0">\
			and <input type="text" id="AA-txtSearchLengthMax" size=4 value="250"></span>\
		</td><td style="float:right;padding-right:8px">\
			<input type="button" id="AA-clearSelected" value="Clear Filters" title="Clear all current filters."><br/>\
			<input type="button" id="AA-checkSelected" class="checkoff" value="Selected"\
			   title="Display only selected rows. Other filters are ignored and disabled while this filter is checked.">\
		</td></tr></table>\
</div>\
<div id="AA-mask" class="grid-mask"></div>\
<div id="AA-dialog" class="tools-dialog" style="display:none">\
<div id="AA-dialog-title" class="title">Export Selected</div>\
<div id="AA-dialog-content" class="content">...</div>\
<div id="AA-dialog-buttons" class="buttons">\
	<input type="button" value="OK" id="AA-exportOK">\
	<input type="button" value="Cancel" onclick="$(\'#AA-dialog\').hide();$(\'#AA-mask\').hide();">\
</div>\
</div>\
');

$(function () {

var disableTitleBar = false;

$("#AA-collapseGrid").click(function(e) {
  if( disableTitleBar ) return;
  if( $('#AA-grid').is(":visible") ) {
    $(this).attr("class","ui-icon ui-icon-triangle-1-s");
    $(this).attr("title","Expand view");
    $('#AA-pager').slideUp();
	$('#AA-filterpanel').slideUp();
    $('#AA-grid').slideUp('slow',function(){
        $('#AA-titlebar').css("border","1px solid grey");
		$('#AA-toggleFilter').attr("class","");
    });
  } else {
    $(this).attr("class","ui-icon ui-icon-triangle-1-n");
    $(this).attr("title","Collapse view");
    $('#AA-titlebar').css("border-bottom","0");
    $('#AA-pager').slideDown();
    $('#AA-grid').slideDown('slow',function(){
		$('#AA-toggleFilter').attr("class","ui-icon ui-icon-search");
	});
  }
});

$("#AA-toggleFilter").click(function(e) {
		if( disableTitleBar ) return;
		if( $('#AA-filterpanel').is(":visible") ) {
		   $('#AA-filterpanel').slideUp();
		} else if( $('#AA-grid').is(":visible") ){
		   $('#AA-filterpanel').slideDown();
		}
});

var filterSettings = {};

function resetFilterSettings() {
	filterSettings = {
	   searchSelected: true,
 	   searchStringAmpID: "",
	   searchStringGeneID: "",
	   searchStringMedian: Number(0),
	   searchStringLengthStart: Number(0),
	   searchStringLengthEnd: Number(250)
	}
}

function updateFilterSettings() {
	updateSelectedFilter(false);
	$("#AA-txtSearchAmpID").attr('value',filterSettings['searchStringAmpID']);
	$("#AA-txtSearchGeneID").attr('value',filterSettings['searchStringGeneID']);
	$("#AA-txtSearchCovMin").attr('value',filterSettings['searchStringMedian'] ? "" : filterSettings['searchStringMedian']);
	$("#AA-txtSearchLengthMin").attr('value',filterSettings['searchStringLengthStart'] ? "" : filterSettings['searchStringLengthStart']);
	$("AA-txtSearchLengthMax").attr('value',filterSettings['searchStringLengthEnd'] ? "" : filterSettings['searchStringLengthEnd']);
}

function updateSelectedFilter(turnOn) {
	filterSettings['searchSelected'] = turnOn;
	$('#AA-checkSelected').attr('class',turnOn ? 'checkOn' : 'checkOff');
	$('.txtSearch').attr('disabled',turnOn);
	$('.numSearch').attr('disabled',turnOn);
	checkboxSelector.setFilterSelected(turnOn);
}

function myFilter(item,args) {
  // for selected only filtering ignore all other filters
  if( args.searchSelected ) return item["check"];
  if( strNoMatch( item["ampid"].toUpperCase(), args.searchStringAmpID ) ) return false;
  if( strNoMatch( item["geneid"].toUpperCase(), args.searchStringGeneID ) ) return false;
  if( rangeMore( item["median"], args.searchStringMedian ) ) return false;
  if( rangeNoMatch( item["length"], args.searchStringLengthStart, args.searchStringLengthEnd ) ) return false;
  return true;
}

function exportTools() {
  var items = dataView.getItems();
  var numSelected = 0;
  for( var i = 0; i < items.length; ++i ) {
    if( items[i]['check'] ) ++numSelected;
  }
  var $content = $('#AA-dialog-content');
  $content.html('Rows selected: '+numSelected+'<br/>');
  if( numSelected == 0 ) {
    $content.append('<p>You must first select rows of the table data to export.</p>');
    $('#AA-exportOK').hide();
  } else {
    // extra code here preempts additional export options
    $content.append('<p>\
      <input type="radio" name="exportTool" id="AA-ext1" value="table" checked="checked"/>\
        <label for="AA-ext1">Download table file of selected rows.</label><p/>');
    $('#AA-exportOK').show();
  }
  // open dialog over masked out table
  var pos = $('#AA-pager').offset();
  var x = pos.left+22;
  var y = pos.top-$('#AA-dialog').height()+3;
  $('#AA-dialog').css({ left:x, top:y });
  pos = $('#AA-tablecontent').offset();
  var hgt = $('#AA-tablecontent').height()-$('#AA-footnote').height()-9;
  var wid = $('#AA-tablecontent').width()+2;
  $('#AA-mask').css({ left:pos.left, top:pos.top, width:wid, height:hgt });
  $('#AA-mask').show();
  $('#AA-dialog').show();
}

$('#AA-exportOK').click(function(e) {
  $('#AA-dialog').hide();
  var items = dataView.getItems();
  var checkList = [];
  for( var i = 0; i < items.length; ++i ) {
    if( items[i]['check'] ) {
      checkList.push(items[i]['id']);
    }
  }
  var rows = checkList.sort(function(a,b){return a-b;})+",";
  $('#AA-mask').hide();
  var op = $("input[@name=exportTool]:checked").val();
  if( op == "table" ) {
    window.open("subtable.php3?dataFile="+dataFile+"&rows="+rows);
  }
});

// Load up the index of PDFs from the JSON file
var pdfIndex =  [];
$.getJSON("pdf_index.json", function(data) {
	pdfIndex = data;
});

// Link directly to PDF files to view them on the fly
function CovPlotsView(row, cell, value, columnDef, dataContext) {
	var amplicon = grid.getData().getItem(row)['ampid'];
	var locpath = window.location.pathname.substring(0,window.location.pathname.lastIndexOf('/'));
	var plotsFolder = window.location.protocol + "//" + window.location.host + locpath + "/CovPlots/";
	var href = plotsFolder + pdfIndex[amplicon];
	return "<a href='" + href + "'>" + value + "</a>";
}

// Column Headers
var columns = [];
var checkboxSelector = new Slick.CheckboxSelectColumn();
columns.push(checkboxSelector.getColumnDefinition());
columns.push({
id: "ampid", name: "Amplicon ID", field: "ampid", width: 150, minWidth: 40, maxWidth: 150, sortable: true, formatter: CovPlotsView,
  toolTip: "ID name of amplicon in the panel" });
columns.push({
id: "geneid", name: "Gene Name", field: "geneid", width: 100, minWidth: 50, maxWidth: 100, sortable: true,
  toolTip: "ID name of the gene in the panel" });
columns.push({
id: "median", name: "Median", field: "median", width: 100, minWidth: 38, maxWidth: 110, sortable: true,
  toolTip: "The median coverage across the amplicon." });
columns.push({
id: "length", name: "Length", field: "length", width: 100, minWidth: 54, maxWidth: 110, sortable: true,
  toolTip: "The total length of the amplicon." });

$("#AllAmpliconsCoverage").css('width','490px');

// define the grid and attach head/foot of the table
var options = {
  editable: true,
  autoEdit: false,
  enableCellNavigation: true,
  multiColumnSort: true
};
var dataView = new Slick.Data.DataView({inlineFilters: true});
var grid = new Slick.Grid("#AA-grid", dataView, columns, options);
grid.setSelectionModel( new Slick.RowSelectionModel({selectActiveRow: false}) );
grid.registerPlugin(checkboxSelector);

var pager = new Slick.Controls.Pager(dataView, grid, exportTools, $("#AA-pager"));
var columnpicker = new Slick.Controls.ColumnPicker(columns, grid, options);

$("#AA-tablecontent").appendTo('#AllAmpliconsCoverage');
$("#AA-tablecontent").show();
$("#AA-filterpanel").appendTo('#AA-titlebar');

grid.onSort.subscribe(function(e,args) {
    var cols = args.sortCols;

	dataView.sort(function (dataRow1, dataRow2) {
		for( var i = 0, l = cols.length; i < l; i++ ) {
		    var field = cols[i].sortCol.field;
			var sign = cols[i].sortAsc ? 1 : -1;
			var value1 = dataRow1[field], value2 = dataRow2[field];
			var result = (value1 == value2 ? 0 : (value1 > value2 ? 1 : -1)) * sign;
			if ( result != 0 ) {
			    return result;
			}
		}
		return 0;
	});
});


// wire up model events to drive the grid
dataView.onRowCountChanged.subscribe(function (e, args) {
  grid.updateRowCount();
  grid.render();
});

dataView.onRowsChanged.subscribe(function (e, args) {
  grid.invalidateRows(args.rows);
  grid.render();
  checkboxSelector.checkAllSelected();
});

// --- filter panel methods
$("#AA-checkSelected").click(function(e) {
  var turnOn = ($(this).attr('class') === 'checkOff');
  updateSelectedFilter(turnOn);
  updateFilter();
  dataView.setPagingOptions({pageNum: 0});
});

$("#AA-clearSelected").click(function(e) {
  resetFilterSettings();  
  updateFilterSettings();
  updateFilter();
});

$("#AA-txtSearchAmpID").keyup(function(e) {
  Slick.GlobalEditorLock.cancelCurrentEdit();
  if( e.which == 27 ) { this.value = ""; }
  filterSettings['searchStringAmpID'] = this.value.toUpperCase();
  updateFilter();
});

$("#AA-txtSearchGeneID").keyup(function(e) {
  Slick.GlobalEditorLock.cancelCurrentEdit();
  if( e.which == 27 ) { this.value = ""; }
  filterSettings['searchStringGeneID'] = this.value.toUpperCase();
  updateFilter();
});

$("#AA-txtSearchLengthMin").keyup(function(e) {
  Slick.GlobalEditorLock.cancelCurrentEdit();
  if( e.which == 27 ) { this.value = ""; }
  this.value = this.value.replace(/\D/g,"");
  filterSettings['searchStringLengthStart'] = Number( this.value == "" ? 0 : this.value );
  updateFilter();
});

$("#AA-txtSearchLengthMax").keyup(function(e) {
  Slick.GlobalEditorLock.cancelCurrentEdit();
  if( e.which == 27 ) { this.value = ""; }
  this.value = this.value.replace(/\D/g,"");
  filterSettings['searchStringLengthEnd'] = Number( this.value == "" ? 0 : this.value );
  updateFilter();
});

$("#AA-txtSearchCovMin").keyup(function(e) {
  Slick.GlobalEditorLock.cancelCurrentEdit();
  if( e.which == 27 ) { this.value = ""; }
  this.value = this.value.replace(/\D/g,"");
  filterSettings['searchStringMedian'] = Number( this.value == "" ? 0 : this.value );
  updateFilter();
});

function updateFilter() {
  dataView.setFilterArgs(filterSettings);
  dataView.refresh();
}
checkboxSelector.setUpdateFilter(updateFilter);
resetFilterSettings();  
updateFilterSettings();

// set to default to 0 rows, including header
$("#AA-grid").css('height','27px');
$("#AA-grid").resizable({
  alsoResize: "#AllAmpliconsCoverage",
  minWidth:300,
  handles:"e,s,se",
  stop:function(e,u) {
    $("#AllAmpliconsCoverage").css('height','auto');
  }
});
grid.resizeCanvas();

// initialize the model after all the events have been hooked up
var data = []; // defined by file load later
dataView.beginUpdate();
dataView.setItems(data);
dataView.setFilterArgs(filterSettings);
dataView.setFilter(myFilter);
dataView.endUpdate();
dataView.syncGridSelection(grid, true);

// define function to load the table data and add to onload call list
var dataFile = $("#AllAmpliconsCoverage").attr("fileurl");

function loadtable() {
  var errorTrace = -1;
  var loadUpdate = 10000;
  var firstPartialLoad = true;
  var numRecords = 0;
  var initialRowDisplay = 10;

  function onLoadPartial() {
    if( firstPartialLoad ) {
      firstPartialLoad = false;
      var numDataRows = (numRecords < initialRowDisplay) ? numRecords : initialRowDisplay;
      $("#AA-grid").css('height',(numDataRows*25+27)+'px');
    }
    dataView.setItems(data);
    grid.resizeCanvas();
    grid.render();
  }

  function onLoadSuccess() {
    onLoadPartial();
    $('#AA-message').html('');
  }

  function onLoadError() {
    if( errorTrace <= 1 ) {
      disableTitleBar = true;
      $('#AA-pager').hide();
      $('#AA-grid').hide();
      $('#AA-titlebar').css("border","1px solid grey");
      $('#AA-collapseGrid').attr('class','ui-icon ui-icon-alert');
      $('#AA-collapseGrid').attr("title","Failed to load data.");
      $('#AA-toggleFilter').attr('class','ui-icon ui-icon-alert');
      $('#AA-toggleFilter').attr("title","Failed to load data.");      
    }
    if( errorTrace < 0 ) {
      alert("Could open All Amplicons Coverage Summary table data file\n'"+dataFile+"'.");
    } else {
      alert("An error occurred loading All Amplicons Coverage Summary data from file\n'"+dataFile+"' at line "+errorTrace);
    }
    $('#AA-message').append('<span style="color:red;font-style:normal">ERROR</span>');
  }
  
  $('#AA-message').html('Loading...');
  if( dataFile == null || dataFile == undefined || dataFile == "" ) {
    return onLoadError();
  }

  $.get(dataFile, function(mem) {
    var lines = mem.split("\n");
    $.each(lines, function(n,row) {
      errorTrace = n;
      var fields = $.trim(row).split('\t');
	  var ampid = fields[0];
	  if( ampid == '' ) return true; 
	  if(n > 0 ) {
	  	data[numRecords] = {
	  		id: Number(numRecords),
			check : false,
	  		ampid : ampid,
			geneid : fields[1],
	  		median : Number(fields[2]),
	  		length : Number(fields[3])
			};
        ++numRecords;
		if( loadUpdate > 0 && numRecords % loadUpdate == 0 ) onLoadPartial();
		}
      });
  }).success(onLoadSuccess).error(onLoadError);
}
postPageLoadMethods.push({callback: loadtable, priority: 10});

});
