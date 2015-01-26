<!DOCTYPE html>
<html>
<head>
	<meta http-equiv="content-type" content="text/html; charset=utf-8"/>
	<meta name="copyright" content="2013, Web Solutions"/>
	<meta http-equiv="X-UA-Compatible" content="IE=edge" >
	<title>File Renamer</title>
	<style type="text/css">
		body
		{
			padding-top: 60px;
			padding-bottom: 40px;
		}
	</style>
	<link rel="stylesheet" href="css/bootstrap.min.css" />
	<script type="text/javascript" src="js/jquery-1.10.2.min.js"></script>
	<script type="text/javascript" src="js/bootstrap.min.js"></script>
	<script type="text/javascript" src="rqlconnector/Rqlconnector.js"></script>
	<script type="text/javascript" src="js/jquery.blockUI.js"></script>
	<script type="text/javascript" src="js/handlebars.js"></script>
	<script id="entry-template" type="text/x-handlebars-template">
		<tr>
			<td>
				<label class="checkbox">
					<input type="checkbox"> {{title}}
				</label>
			</td>
			<td><input class="filename" type="text" value="{{filename}}" id="{{guid}}"></td>
			<td>{{id}}</td>
		</tr>
	</script>
	<script type="text/javascript">
		var source   = $("#entry-template").html();
		var template = Handlebars.compile(source);
		var LoginGuid = '<%= session("loginguid") %>';
		var SessionKey = '<%= session("sessionkey") %>';
		var RqlConnectorObj = new RqlConnector(LoginGuid, SessionKey);
		
		$(document).ready(function() {
			InitialSearch('<%= session("TreeGuid") %>');
			
			InitResultsCheckBox();
		});
		
		function InitialSearch(ContentClassGuid)
		{
			var strRQLXML = '<PAGE action="xsearch" orderby="headline" orderdirection="ASC" pagesize="-1" maxhits="-1"><SEARCHITEMS><SEARCHITEM key="contentclassguid" value="' + ContentClassGuid + '" operator="eq"></SEARCHITEM></SEARCHITEMS></PAGE>';
			
			RqlConnectorObj.SendRql(strRQLXML, false, function(data){
				$(data).find("PAGE").each(function(){
					GetFileName($(this).attr("guid"));
				});
			});
		}
		
		function GetFileName(PageGuid)
		{
			var strRQLXML = '<PAGE action="load" guid="' + PageGuid + '"/>';
			
			RqlConnectorObj.SendRql(strRQLXML, false, function(data){
				AddResult(	$(data).find("PAGE").attr("headline"),
							$(data).find("PAGE").attr("guid"),
							$(data).find("PAGE").attr("id"),
							$(data).find("PAGE").attr("name")
						);
			});
		}
		
		function CopyHeadlineToInput()
		{
			$('#results').find('input[type=checkbox]:checked').each(function(){
				var PageHeadline = $(this).parent().text();
				PageHeadline = $.trim(PageHeadline);
				$(this).parents('tr').find("input[type=text]").val(PageHeadline);
			});
		}
		
		function LowerCaseFileName()
		{
			$('#results').find('input[type=checkbox]:checked').each(function(){
				var PageHeadline = $(this).parents('tr').find("input[type=text]").val();
				PageHeadline = PageHeadline.toLowerCase();
				$(this).parents('tr').find("input[type=text]").val(PageHeadline);
			});
		}
		
		function SEOFiendlyFileName()
		{
			$('#results').find('input[type=checkbox]:checked').each(function(){
				var CurrentFileName = $(this).parents('tr').find("input[type=text]").val();
				CurrentFileName = CurrentFileName.replace(/[^a-zA-Z0-9_-]+/g, "-");
				CurrentFileName = CurrentFileName.replace(/(^-)|(-$)/g, "");
				$(this).parents('tr').find("input[type=text]").val(CurrentFileName);
			});
		}
		
		
		function ClearFileName()
		{
			$('#results').find('input[type=checkbox]:checked').each(function(){
				$(this).parents('tr').find("input[type=text]").val('');
			});
		}
		
		function SaveFileName()
		{
			$('#results').find('input[type=checkbox]:checked').each(function(){
				var FileName = $(this).parents('tr').find("input[type=text]").val();
				var PageGuid = $(this).parents('tr').find("input[type=text]").attr("id");
				
				if(FileName == "")
				{
					FileName = '#' + SessionKey;
				}
				
				var LabelDOM = $(this).parents('tr').find("label");
				BlockUI(LabelDOM);

				var strRQLXML = '<PAGE action="save" guid="' + PageGuid + '" name="' + FileName + '"/>';
				
				RqlConnectorObj.SendRql(strRQLXML, false, function(data){
					// saved
					UnblockUI(LabelDOM);
				});
			});
		}
		
		function BlockUI(DOM)
		{
			$(DOM).block({ 
				message: '<div><i class="icon-refresh"></i> Saving</div>' 
			}); 
		}
		
		function UnblockUI(DOM)
		{
			$(DOM).unblock();

			ToggleCheckBox($(DOM).find('input[type=checkbox]'), false);
		}
		
		function ToggleResults(Checked)
		{
			$('#results').find('input[type=checkbox]').each(function(){
				ToggleCheckBox($(this), Checked);
			});
			
			return false;
		}
		
		function ToggleCheckBox(DOM, Checked)
		{
			$(DOM).attr('checked', Checked).trigger('change');
		}
		
		function InitResultsCheckBox()
		{
			$('#results').on('change', 'input[type=checkbox]', function(){
				if($(this).is(':checked'))
				{
					$(this).parents('tr').addClass('alert');
				} else {
					$(this).parents('tr').removeClass('alert');
				}
			});
		}
		
		function AddResult(PageHeadline, PageGuid, PageId, PageFileName)
		{
			var PageObject = new Object();
			PageObject.title = PageHeadline;
			PageObject.guid = PageGuid;
			PageObject.id = PageId;
			PageObject.filename = PageFileName;
			var html = template(PageObject);
			$('#results tbody').append(html);
		}
	</script>
</head>
<body>
	<div class="navbar navbar-inverse navbar-fixed-top">
		<div class="navbar-inner">
			<div class="container">
				<div class="btn-group">
					<a class="btn btn-info dropdown-toggle" data-toggle="dropdown" href="#">
						Selections
						<span class="caret"></span>
					</a>
					<ul class="dropdown-menu" id="data-action">
						<li><a href="#" onclick="ToggleResults(true);">Check All</a></li>
						<li><a href="#" onclick="ToggleResults(false);">Uncheck All</a></li>
					</ul>
				</div>
				<div class="pull-right">
					<button class="btn btn-warning" title="Use headline as file name for selected entries on this page" onclick="CopyHeadlineToInput();"><i class="icon-edit icon-white"></i></button>
					<button class="btn btn-warning" title="Convert file name to lowercase for selected entries on this page" onclick="LowerCaseFileName();"><i class="icon-text-height icon-white"></i></button>
					<button class="btn btn-warning" title="Convert to SEO friendly file name for selected entries on this page" onclick="SEOFiendlyFileName();"><i class="icon-check icon-white"></i></button>
					<button class="btn btn-danger" title="Clear file name for selected entries on this page" onclick="ClearFileName();"><i class="icon-remove-circle icon-white"></i></button>
					<button class="btn btn-success" title="Save file name for selected entries on this page" onclick="SaveFileName();"><i class="icon-circle-arrow-down icon-white"></i></button>
				</div>
			</div>
		</div>
	</div>
	<div class="container">
		<div id="results">
			<table id="datatable" class="table table-hover table-condensed"> 
				<thead> 
					<tr>
						<th>Headline</th> 
						<th>File Name</th> 
						<th>Page ID</th>
					</tr> 
				</thead>
				<tbody>
				</tbody> 
			</table>
		</div>
	</div>
</body>
</html>
