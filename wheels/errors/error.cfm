<cfoutput>
<h1>#arguments.exception.cause.type#</h1>
<p><strong>#arguments.exception.cause.message#</strong></p>
<h2>Suggested action</h2>
<p>#arguments.exception.cause.extendedInfo#</p>
<cftry>
	<cfsavecontent variable="loc.errorLocation">
		<h2>Error location</h2>
		<p>Line #arguments.exception.cause.tagContext[3].line# in #Replace(arguments.exception.cause.tagContext[3].template, getDirectoryFromPath(getBaseTemplatePath()), "")#</p>
		<cfset loc.pos = 0><pre><code><cfloop file="#arguments.exception.cause.tagContext[3].template#" index="loc.i"><cfset loc.pos = loc.pos + 1><cfif loc.pos GTE (arguments.exception.cause.tagContext[3].line-2) AND loc.pos LTE (arguments.exception.cause.tagContext[3].line+2)><cfif loc.pos IS arguments.exception.cause.tagContext[3].line><span style="color: red;">#loc.pos#: #HTMLEditFormat(loc.i)#</span><cfelse>#loc.pos#: #HTMLEditFormat(loc.i)#</cfif>
		</cfif></cfloop></code></pre>
	</cfsavecontent>
	#loc.errorLocation#
<cfcatch>
</cfcatch>
</cftry>
</cfoutput>