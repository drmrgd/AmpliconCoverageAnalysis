// Javascript for Low Amplicons Slickgrid table 
document.write('\
<div id="LA-tablecontent" style="display:none">\
  <div id="LA-titlebar" class="grid-header">\
    <span id="LA-collapseGrid" style="float:left" class="ui-icon ui-icon ui-icon-triangle-1-n" title="Collapse view"></span>\
    <span class="table-title">Coverage Data for All Amplicons in the Panel</span>\
	<span id="LA-toggleFilter" style="float:right" class="ui-icon ui-icon-search" title="Toggle search/filter panel"></span>\
	<span id="LA-message" class="message"></span>\
  </div>\
  <div id="LA-grid" class="grid-body"></div>\
  <div id="LA-pager" class="grid-footer"></div>\
  <p class="grid-text"/>\
</div>\
<div id="LA-filterpanel" class="filter-panel" style="display:none">\
	<table style="width:100%"><tr><td>\
		<span class="nwrap">Amplicon ID <input type="text" id="LA-txtSearchAmpID" class="txtSearch" size=7 value=""></span>\
		<span class="nwrap">Gene Name <input type="text" id="LA-txtSearchGeneID" class="txtSerch" size=7 value=""></span>\
		<span class="nwrap">Median &le; <input type="text" id="LA-txtSearchCovMin" class="numSearch" size=7 value=""></span>\
		<span class="nwrap">Forward Proportion Between <input type="text" id="LA-txtSearchFpropMin" class="numSearch" size=7 value="0.000"></span>\
            and <input type="text" id="LA-txtSearchFpropMax" class="numSearch" size=7 value="1.000"></span>\
		<span class="nwrap">Reverse Proportion Between <input type="text" id="LA-txtSearchRpropMin" class="numSearch" size=7 value="0.000"></span>\
            and <input type="text" id="LA-txtSearchRpropMax" class="numSearch" size=7 value="1.000"></span>\
		<span class="nwrap">Amplicon Length Between <input type="text" class="numSearch" id="LA-txtSearchLengthMin" size=4 value="0">\
			and <input type="text" id="LA-txtSearchLengthMax" size=4 value="250"></span>\
		</td><td style="float:right;padding-right:8px">\
			<input type="button" id="LA-clearSelected" value="Clear Filters" title="Clear all current filters."><br/>\
			<input type="button" id="LA-checkSelected" class="checkoff" value="Selected"\
			   title="Display only selected rows. Other filters are ignored and disabled while this filter is checked.">\
		</td></tr></table>\
</div>\
<div id="LA-mask" class="grid-mask"></div>\
<div id="LA-dialog" class="tools-dialog" style="display:none">\
<div id="LA-dialog-title" class="title">Export Selected</div>\
<div id="LA-dialog-content" class="content">...</div>\
<div id="LA-dialog-buttons" class="buttons">\
	<input type="button" value="OK" id="LA-exportOK">\
	<input type="button" value="Cancel" onclick="$(\'#LA-dialog\').hide();$(\'#LA-mask\').hide();">\
</div>\
</div>\
');

$(function () {

var disableTitleBar = false;

$("#LA-collapseGrid").click(function(e) {
  if( disableTitleBar ) return;
  if( $('#LA-grid').is(":visible") ) {
    $(this).attr("class","ui-icon ui-icon-triangle-1-s");
    $(this).attr("title","Expand view");
    $('#LA-pager').slideUp();
	$('#LA-filterpanel').slideUp();
    $('#LA-grid').slideUp('slow',function(){
        $('#LA-titlebar').css("border","1px solid grey");
		$('#LA-toggleFilter').attr("class","");
    });
  } else {
    $(this).attr("class","ui-icon ui-icon-triangle-1-n");
    $(this).attr("title","Collapse view");
    $('#LA-titlebar').css("border-bottom","0");
    $('#LA-pager').slideDown();
    $('#LA-grid').slideDown('slow',function(){
		$('#LA-toggleFilter').attr("class","ui-icon ui-icon-search");
	});
  }
});

$("#LA-toggleFilter").click(function(e) {
		if( disableTitleBar ) return;
		if( $('#LA-filterpanel').is(":visible") ) {
		   $('#LA-filterpanel').slideUp();
		} else if( $('#LA-grid').is(":visible") ){
		   $('#LA-filterpanel').slideDown();
		}
});

var filterSettings = {};

function resetFilterSettings() {
	filterSettings = {
	   searchSelected: true,
 	   searchStringAmpID: "",
	   searchStringGeneID: "",
	   searchStringMedian: Number(0),
       searchStringFpropStart: Number(0.000),
       searchStringFpropEnd: Number(1.000),
       searchStringRpropStart: Number(0.000),
       searchStringRpropEnd: Number(1.000),
	   searchStringLengthStart: Number(0),
	   searchStringLengthEnd: Number(250)
	}
}

function updateFilterSettings() {
	updateSelectedFilter(false);
	$("#LA-txtSearchAmpID").attr('value',filterSettings['searchStringAmpID']);
	$("#LA-txtSearchGeneID").attr('value',filterSettings['searchStringGeneID']);
	$("#LA-txtSearchCovMin").attr('value',filterSettings['searchStringMedian'] ? "" : filterSettings['searchStringMedian']);
    $("#LA-txtSearchFpropMin").attr('value',filterSettings['searchStringFpropStart'] ? "" : filterSettings['searchStringFpropStart']);
    $("#LA-txtSearchFpropMax").attr('value',filterSettings['searchStringFpropEnd'] ? "" : filterSettings['searchStringFpropEnd']);
    $("#LA-txtSearchRpropMin").attr('value',filterSettings['searchStringRpropStart'] ? "" : filterSettings['searchStringRpropStart']);
    $("#LA-txtSearchRpropMax").attr('value',filterSettings['searchStringRpropEnd'] ? "" : filterSettings['searchStringRpropEnd']);
	$("#LA-txtSearchLengthMin").attr('value',filterSettings['searchStringLengthStart'] ? "" : filterSettings['searchStringLengthStart']);
	$("LA-txtSearchLengthMax").attr('value',filterSettings['searchStringLengthEnd'] ? "" : filterSettings['searchStringLengthEnd']);
}

function updateSelectedFilter(turnOn) {
	filterSettings['searchSelected'] = turnOn;
	$('#LA-checkSelected').attr('class',turnOn ? 'checkOn' : 'checkOff');
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
  if( rangeNoMatch( item["fprop"], args.searchStringFpropStart, args.searchStringFpropEnd ) ) return false;
  if( rangeNoMatch( item["rprop"], args.searchStringRpropStart, args.searchStringRpropEnd ) ) return false;
  if( rangeNoMatch( item["length"], args.searchStringLengthStart, args.searchStringLengthEnd ) ) return false;
  return true;
}

function exportTools() {
  var items = dataView.getItems();
  var numSelected = 0;
  for( var i = 0; i < items.length; ++i ) {
    if( items[i]['check'] ) ++numSelected;
  }
  var $content = $('#LA-dialog-content');
  $content.html('Rows selected: '+numSelected+'<br/>');
  if( numSelected == 0 ) {
    $content.append('<p>You must first select rows of the table data to export.</p>');
    $('#LA-exportOK').hide();
  } else {
    // extra code here preempts additional export options
    $content.append('<p>\
      <input type="radio" name="exportTool" id="LA-ext1" value="table" checked="checked"/>\
        <label for="LA-ext1">Download table file of selected rows.</label><p/>');
    $('#LA-exportOK').show();
  }
  // open dialog over masked out table
  var pos = $('#LA-pager').offset();
  var x = pos.left+22;
  var y = pos.top-$('#LA-dialog').height()+3;
  $('#LA-dialog').css({ left:x, top:y });
  pos = $('#LA-tablecontent').offset();
  var hgt = $('#LA-tablecontent').height()-$('#LA-footnote').height()-9;
  var wid = $('#LA-tablecontent').width()+2;
  $('#LA-mask').css({ left:pos.left, top:pos.top, width:wid, height:hgt });
  $('#LA-mask').show();
  $('#LA-dialog').show();
}

$('#LA-exportOK').click(function(e) {
  $('#LA-dialog').hide();
  var items = dataView.getItems();
  var checkList = [];
  for( var i = 0; i < items.length; ++i ) {
    if( items[i]['check'] ) {
      checkList.push(items[i]['id']);
    }
  }
  var rows = checkList.sort(function(a,b){return a-b;})+",";
  $('#LA-mask').hide();
  var op = $("input[@name=exportTool]:checked").val();
  if( op == "table" ) {
    window.open("subtable.php3?dataFile="+dataFile+"&rows="+rows);
  }
});

// Column Headers
var columns = [];
var checkboxSelector = new Slick.CheckboxSelectColumn();
columns.push(checkboxSelector.getColumnDefinition());
columns.push({
id: "ampid", name: "Amplicon ID", field: "ampid", width: 120, minWidth: 40, maxWidth: 150, sortable: true,
  toolTip: "ID name of amplicon in the panel" });
columns.push({
id: "geneid", name: "Gene Name", field: "geneid", width: 100, minWidth: 50, maxWidth: 100, sortable: true,
  toolTip: "ID name of the gene in the panel" });
columns.push({
id: "median", name: "Median", field: "median", width: 100, minWidth: 38, maxWidth: 110, sortable: true,
  toolTip: "The median coverage across the amplicon." });
columns.push({
id: "forward", name: "Forward", field: "forward", width: 100, minWidth: 38, maxWidth: 110, sortable: true,
  toolTip: "The number of forward strand reads." });
columns.push({
id: "reverse", name: "Reverse", field: "reverse", width: 100, minWidth: 38, maxWidth: 110, sortable: true,
  toolTip: "The number of reverse strand reads." });
columns.push({
id: "fprop", name: "Forward Proportion", field: "fprop", width: 100, minWidth: 38, maxWidth: 110, sortable: true, 
  toolTip: "The proportion of forward strand reads in the population." });
columns.push({
id: "rprop", name: "Reverse Proportion", field: "rprop", width: 100, minWidth: 38, maxWidth: 110, sortable: true,
  toolTip: "The proportion of reverse strand reads in the population." });
columns.push({
id: "length", name: "Length", field: "length", width: 80, minWidth: 38, maxWidth: 110, sortable: true,
  toolTip: "The total length of the amplicon." });

$("#LowAmpliconsCoverage").css('width','828px');

// define the grid and attach head/foot of the table
var options = {
  editable: true,
  autoEdit: false,
  enableCellNavigation: true,
  multiColumnSort: true
};
var dataView = new Slick.Data.DataView({inlineFilters: true});
var grid = new Slick.Grid("#LA-grid", dataView, columns, options);
grid.setSelectionModel( new Slick.RowSelectionModel({selectActiveRow: false}) );
grid.registerPlugin(checkboxSelector);

var pager = new Slick.Controls.Pager(dataView, grid, exportTools, $("#LA-pager"));
var columnpicker = new Slick.Controls.ColumnPicker(columns, grid, options);

$("#LA-tablecontent").appendTo('#LowAmpliconsCoverage');
$("#LA-tablecontent").show();
$("#LA-filterpanel").appendTo('#LA-titlebar');

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
$("#LA-checkSelected").click(function(e) {
  var turnOn = ($(this).attr('class') === 'checkOff');
  updateSelectedFilter(turnOn);
  updateFilter();
  dataView.setPagingOptions({pageNum: 0});
});

$("#LA-clearSelected").click(function(e) {
  resetFilterSettings();  
  updateFilterSettings();
  updateFilter();
});

$("#LA-txtSearchAmpID").keyup(function(e) {
  Slick.GlobalEditorLock.cancelCurrentEdit();
  if( e.which == 27 ) { this.value = ""; }
  filterSettings['searchStringAmpID'] = this.value.toUpperCase();
  updateFilter();
});

$("#LA-txtSearchGeneID").keyup(function(e) {
  Slick.GlobalEditorLock.cancelCurrentEdit();
  if( e.which == 27 ) { this.value = ""; }
  filterSettings['searchStringGeneID'] = this.value.toUpperCase();
  updateFilter();
});

$("#LA-txtSearchLengthMin").keyup(function(e) {
  Slick.GlobalEditorLock.cancelCurrentEdit();
  if( e.which == 27 ) { this.value = ""; }
  this.value = this.value.replace(/\D/g,"");
  filterSettings['searchStringLengthStart'] = Number( this.value == "" ? 0 : this.value );
  updateFilter();
});

$("#LA-txtSearchCovMin").keyup(function(e) {
  Slick.GlobalEditorLock.cancelCurrentEdit();
  if( e.which == 27 ) { this.value = ""; }
  this.value = this.value.replace(/\D/g,"");
  filterSettings['searchStringMedian'] = Number( this.value == "" ? 0 : this.value );
  updateFilter();
});

$("#LA-txtSearchLengthMax").keyup(function(e) {
  Slick.GlobalEditorLock.cancelCurrentEdit();
  if( e.which == 27 ) { this.value = ""; }
  this.value = this.value.replace(/\D/g,"");
  filterSettings['searchStringLengthEnd'] = Number( this.value == "" ? 0 : this.value );
  updateFilter();
});

$("#LA-txtSearchFpropMin").keyup(function(e) {
  Slick.GlobalEditorLock.cancelCurrentEdit();
  if( e.which == 27 ) { this.value = ""; }
  //this.value = this.value.replace(/\D/g,"");
  filterSettings['searchStringFpropStart'] = Number( this.value == "" ? 0 : this.value );
  updateFilter();
});

$("#LA-txtSearchFpropMax").keyup(function(e) {
  Slick.GlobalEditorLock.cancelCurrentEdit();
  if( e.which == 27 ) { this.value = ""; }
  //this.value = this.value.replace(/\D/g,"");
  filterSettings['searchStringFpropEnd'] = Number( this.value == "" ? 0 : this.value );
  updateFilter();
});

$("#LA-txtSearchRpropMin").keyup(function(e) {
  Slick.GlobalEditorLock.cancelCurrentEdit();
  if( e.which == 27 ) { this.value = ""; }
  //this.value = this.value.replace(/\D/g,"");
  filterSettings['searchStringRpropStart'] = Number( this.value == "" ? 0 : this.value );
  updateFilter();
});

$("#LA-txtSearchRpropMax").keyup(function(e) {
  Slick.GlobalEditorLock.cancelCurrentEdit();
  if( e.which == 27 ) { this.value = ""; }
  //this.value = this.value.replace(/\D/g,"");
  filterSettings['searchStringRpropEnd'] = Number( this.value == "" ? 0 : this.value );
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
$("#LA-grid").css('height','27px');
$("#LA-grid").resizable({
  alsoResize: "#LowAmpliconsCoverage",
  minWidth:300,
  handles:"e,s,se",
  stop:function(e,u) {
    $("#LowAmpliconsCoverage").css('height','auto');
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
var dataFile = $("#LowAmpliconsCoverage").attr("fileurl");

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
      $("#LA-grid").css('height',(numDataRows*25+27)+'px');
    }
    dataView.setItems(data);
    grid.resizeCanvas();
    grid.render();
  }

  function onLoadSuccess() {
    onLoadPartial();
    $('#LA-message').html('');
  }

  function onLoadError() {
    if( errorTrace <= 1 ) {
      disableTitleBar = true;
      $('#LA-pager').hide();
      $('#LA-grid').hide();
      $('#LA-titlebar').css("border","1px solid grey");
      $('#LA-collapseGrid').attr('class','ui-icon ui-icon-alert');
      $('#LA-collapseGrid').attr("title","Failed to load data.");
      $('#LA-toggleFilter').attr('class','ui-icon ui-icon-alert');
      $('#LA-toggleFilter').attr("title","Failed to load data.");      
    }
    if( errorTrace < 0 ) {
      alert("Could open Low Amplicons Coverage Summary table data file\n'"+dataFile+"'.");
    } else {
      alert("An error occurred loading Low Amplicons Coverage Summary data from file\n'"+dataFile+"' at line "+errorTrace);
    }
    $('#LA-message').append('<span style="color:red;font-style:normal">ERROR</span>');
  }
  
  $('#LA-message').html('Loading...');
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
            forward : Number(fields[2]),
            reverse : Number(fields[3]),
            fprop : Number(fields[4]),
            rprop : Number(fields[5]),
	  		median : Number(fields[6]),
	  		length : Number(fields[7])
			};
        ++numRecords;
		if( loadUpdate > 0 && numRecords % loadUpdate == 0 ) onLoadPartial();
		}
      });
  }).success(onLoadSuccess).error(onLoadError);
}
postPageLoadMethods.push({callback: loadtable, priority: 10});

});
