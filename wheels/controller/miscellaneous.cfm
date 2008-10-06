<cffunction name="URLFor" returntype="string" access="private" output="false" hint="View, Helper, Creates an internal URL based on supplied arguments.">
	<cfargument name="route" type="string" required="false" default="" hint="Name of a route that you have configured in 'config/routes.cfm'.">
	<cfargument name="controller" type="string" required="false" default="" hint="Name of the controller to include in the URL.">
	<cfargument name="action" type="string" required="false" default="" hint="Name of the action to include in the URL.">
	<cfargument name="key" type="string" required="false" default="" hint="Key(s) to include in the URL.">
	<cfargument name="params" type="string" required="false" default="" hint="Any additional params to be set in the query string.">
	<cfargument name="anchor" type="string" required="false" default="" hint="Sets an anchor name to be appended to the path.">
	<cfargument name="onlyPath" type="boolean" required="false" default="true" hint="If true, returns only the relative URL (no protocol, host name or port).">
	<cfargument name="host" type="string" required="false" default="" hint="Set this to override the current host.">
	<cfargument name="protocol" type="string" required="false" default="" hint="Set this to override the current protocol.">
	<cfargument name="port" type="numeric" required="false" default="0" hint="Set this to override the current port number.">

	<!---
		EXAMPLES:
		#URLFor(text="Log Out", controller="account", action="logOut")#
		-> /account/logout

		RELATED:
		 * [LinkingPages Linking Pages] (chapter)
		 * [buttonTo buttonTo()] (function)
		 * [linkTo linkTo()] (function)
	--->

	<cfscript>
		var loc = {};
		if (application.settings.environment != "production")
		{
			if (!Len(arguments.route) && !Len(arguments.controller) && !Len(arguments.action))
				$throw(type="Wheels.IncorrectArguments", message="The 'route', 'controller' or 'action' argument is required.", extendedInfo="Pass in either the name of a 'route' you have configured in 'confirg/routes.cfm' or a 'controller' / 'action' / 'key' combination.");
			if (Len(arguments.route) && (Len(arguments.controller) || Len(arguments.action) || Len(arguments.key)))
				$throw(type="Wheels.IncorrectArguments", message="The 'route' argument is mutually exclusive with the 'controller', 'action' and 'key' arguments.", extendedInfo="Choose whether to use a pre-configured 'route' or 'controller' / 'action' / 'key' combination.");
			if (arguments.onlyPath && (Len(arguments.host) || Len(arguments.protocol)))
				$throw(type="Wheels.IncorrectArguments", message="Can't use the 'host' or 'protocol' arguments when 'onlyPath' is 'true'.", extendedInfo="Set 'onlyPath' to 'false' so that linkTo will create absolute URLs and thus allowing you to set the 'host' and 'protocol' on the link.");
		}
		// build the link
		loc.returnValue = application.wheels.webPath & ListLast(cgi.script_name, "/") & "?";
		if (Len(arguments.route))
		{
			// link for a named route
			loc.route = application.wheels.routes[application.wheels.namedRoutePositions[arguments.route]];
			if (application.wheels.URLRewriting == "Off")
			{
				loc.returnValue = loc.returnValue & "controller=" & loc.route.controller;
				loc.returnValue = loc.returnValue & "&amp;action=" & loc.route.action;
				loc.iEnd = ListLen(loc.route.variables);
				for (loc.i=1; loc.i <= loc.iEnd; loc.i++)
				{
					loc.property = ListGetAt(loc.route.variables, loc.i);
					loc.returnValue = loc.returnValue & "&amp;" & loc.property & "=" & URLEncodedFormat(arguments[loc.property]);
				}		
			}
			else
			{
				loc.iEnd = ListLen(loc.route.pattern, "/");
				for (loc.i=1; loc.i <= loc.iEnd; loc.i++)
				{
					loc.property = ListGetAt(loc.route.pattern, loc.i, "/");
					if (loc.property Contains "[")
						loc.returnValue = loc.returnValue & "/" & URLEncodedFormat(arguments[Mid(loc.property, 2, Len(loc.property)-2)]); // get param from arguments
					else
						loc.returnValue = loc.returnValue & "/" & loc.property; // add hard coded param from route
				}		
			}
		}
		else
		{
			// link based on controller/action/key
			if (Len(arguments.controller))
				loc.returnValue = loc.returnValue & "controller=" & arguments.controller; // add controller from arguments
			else
				loc.returnValue = loc.returnValue & "controller=" & variables.params.controller; // keep the controller name from the current request
			if (Len(arguments.action))
				loc.returnValue = loc.returnValue & "&amp;action=" & arguments.action;
			if (Len(arguments.key))
			{
				if (application.settings.obfuscateURLs)
					loc.returnValue = loc.returnValue & "&amp;key=" & obfuscateParam(URLEncodedFormat(arguments.key));
				else
					loc.returnValue = loc.returnValue & "&amp;key=" & URLEncodedFormat(arguments.key);
			}
		}

		if (application.wheels.URLRewriting != "Off")
		{
			loc.returnValue = Replace(loc.returnValue, "?controller=", "/");
			loc.returnValue = Replace(loc.returnValue, "&amp;action=", "/");
			loc.returnValue = Replace(loc.returnValue, "&amp;key=", "/");
		}
		if (application.wheels.URLRewriting == "On")
		{
			loc.returnValue = Replace(loc.returnValue, "rewrite.cfm/", "");
		}

		if (Len(arguments.params))
			loc.returnValue = loc.returnValue & $constructParams(arguments.params);
		if (Len(arguments.anchor))
			loc.returnValue = loc.returnValue & "##" & arguments.anchor;
				
		if (!arguments.onlyPath)
		{
			if (arguments.port != 0)
				loc.returnValue = ":" & arguments.port & loc.returnValue;
			else if (cgi.server_port != 80)
				loc.returnValue = ":" & cgi.server_port & loc.returnValue;
			if (Len(arguments.host))
				loc.returnValue = arguments.host & loc.returnValue;
			else
				loc.returnValue = cgi.server_name & loc.returnValue;
			if (Len(arguments.protocol))
				loc.returnValue = arguments.protocol & "://" & loc.returnValue;
			else
				loc.returnValue = SpanExcluding(cgi.server_protocol, "/") & "://" & loc.returnValue;
		}
		loc.returnValue = LCase(loc.returnValue);
	</cfscript>
	<cfreturn loc.returnValue>
</cffunction>

<cffunction name="isGet" returntype="boolean" access="public" output="false" hint="Controller, Request, Returns whether the request was a normal (GET) request or not.">

	<!---
		HISTORY:
		-

		USAGE:
		-

		EXAMPLES:
		<cfset requestIsGet = isGet()>

		RELATED:
		 * [isPost isPost()] (function)
		 * [isAjax isAjax()] (function)
	--->

	<cfif cgi.request_method IS "get">
		<cfreturn true>
	<cfelse>
		<cfreturn false>
	</cfif>
</cffunction>

<cffunction name="isPost" returntype="boolean" access="public" output="false" hint="Controller, Request, Returns whether the request came from a form submission or not.">

	<!---
		HISTORY:
		-

		USAGE:
		-

		EXAMPLES:
		<cfset requestIsPost = isPost()>

		RELATED:
		 * [isGet isGet()] (function)
		 * [isAjax isAjax()] (function)
	--->

	<cfif cgi.request_method IS "post">
		<cfreturn true>
	<cfelse>
		<cfreturn false>
	</cfif>
</cffunction>

<cffunction name="isAjax" returntype="boolean" access="public" output="false" hint="Controller, Request, Returns whether the page was called from JavaScript or not.">

	<!---
		HISTORY:
		-

		USAGE:
		-

		EXAMPLES:
		<cfset requestIsAjax = isAjax()>

		RELATED:
		 * [isGet isGet()] (function)
		 * [isPost isPost()] (function)
	--->

	<cfif cgi.http_x_requested_with IS "XMLHTTPRequest">
		<cfreturn true>
	<cfelse>
		<cfreturn false>
	</cfif>
</cffunction>

<cffunction name="sendEmail" returntype="void" access="public" output="false">
	<cfargument name="template" type="string" required="true">
	<cfargument name="layout" type="any" required="false" default="false">
	<cfset var loc = {}>

	<cfsavecontent variable="request.wheels.response">
		<cfinclude template="../../#application.wheels.viewPath#/email/#ReplaceNoCase(arguments.template, '.cfm', '')#.cfm">
	</cfsavecontent>

	<cfif (IsBoolean(arguments.layout) AND arguments.layout) OR (arguments.layout IS NOT "false")>
		<cfif NOT IsBoolean(arguments.layout)>
			<cfsavecontent variable="request.wheels.response">
				<cfinclude template="../../#application.wheels.viewPath#/layouts/#Replace(arguments.layout, ' ', '', 'all')#.cfm">
			</cfsavecontent>
		<cfelse>
			<cfsavecontent variable="request.wheels.response">
				<cfinclude template="../../#application.wheels.viewPath#/layouts/email.cfm">
			</cfsavecontent>
		</cfif>
	</cfif>

	<cfset loc.attributes = structCopy(arguments)>
	<cfset loc.cfmailAttributes = "from,to,bcc,cc,charset,debug,failto,group,groupcasesensitive,mailerid,maxrows,mimeattach,password,port,priority,query,replyto,server,spoolenable,startrow,subject,timeout,type,username,useSSL,useTLS,wraptext">
	<cfloop collection="#loc.attributes#" item="loc.i">
		<cfif ListFindNoCase(loc.cfmailAttributes, loc.i) IS 0>
			<cfset StructDelete(loc.attributes, loc.i)>
		</cfif>
	</cfloop>
	<cfmail attributecollection="#loc.attributes#">#trim(request.wheels.response)#</cfmail>

	<!--- delete the response so that Wheels does not think we have rendered an actual response to the browser --->
	<cfset StructDelete(request.wheels, "response")>

</cffunction>

<cffunction name="sendFile" returntype="void" access="public" output="false">
	<cfargument name="file" type="string" required="true">
	<cfargument name="name" type="string" required="false" default="">
	<cfargument name="type" type="string" required="false" default="">
	<cfargument name="disposition" type="string" required="false" default="attachment">
	<cfset var loc = {}>

	<cfset arguments.file = Replace(arguments.file, "\", "/", "all")>
	<cfset loc.path = Reverse(ListRest(Reverse(arguments.file), "/"))>
	<cfset loc.folder = application.wheels.filePath>
	<cfif Len(loc.path) IS NOT 0>
		<cfset loc.folder = loc.folder & "/" & loc.path>
		<cfset loc.file = Replace(arguments.file, loc.path, "")>
		<cfset loc.file = Right(loc.file, Len(loc.file)-1)>
	<cfelse>
		<cfset loc.file = arguments.file>
	</cfif>
	<cfset loc.folder = ExpandPath(loc.folder)>
	<cfif NOT FileExists(loc.folder & "/" & loc.file)>
		<cfdirectory action="list" directory="#loc.folder#" name="loc.match" filter="#loc.file#.*">
		<cfif loc.match.recordcount IS 0>
			<cfthrow type="Wheels.FileNotFound" message="File Not Found" extendedInfo="Make sure a file with the name <tt>#loc.file#</tt> exists in the <tt>#loc.folder#</tt> folder.">
		</cfif>
		<cfset loc.file = loc.file & "." & ListLast(loc.match.name, ".")>
	</cfif>

	<cfset loc.fullPath = loc.folder & "/" & loc.file>

	<cfif Len(arguments.name) IS NOT 0>
		<cfset loc.name = arguments.name>
	<cfelse>
		<cfset loc.name = loc.file>
	</cfif>

	<cfset loc.extension = listLast(loc.file, ".")>
	<cfif loc.extension IS "txt">
		<cfset loc.type = "text/plain">
	<cfelseif loc.extension IS "gif">
		<cfset loc.type = "image/gif">
	<cfelseif loc.extension IS "jpg">
		<cfset loc.type = "image/jpg">
	<cfelseif loc.extension IS "png">
		<cfset loc.type = "image/png">
	<cfelseif loc.extension IS "wav">
		<cfset loc.type = "audio/wav">
	<cfelseif loc.extension IS "mp3">
		<cfset loc.type = "audio/mpeg3">
	<cfelseif loc.extension IS "pdf">
		<cfset loc.type = "application/pdf">
	<cfelseif loc.extension IS "zip">
		<cfset loc.type = "application/zip">
	<cfelseif loc.extension IS "ppt">
		<cfset loc.type = "application/powerpoint">
	<cfelseif loc.extension IS "doc">
		<cfset loc.type = "application/word">
	<cfelseif loc.extension IS "xls">
		<cfset loc.type = "application/excel">
	<cfelse>
		<cfset loc.type = "application/octet-stream">
	</cfif>

	<cfheader name="content-disposition" value="#arguments.disposition#; filename=""#loc.name#""">
	<cfcontent type="#loc.type#" file="#loc.fullPath#">

</cffunction>