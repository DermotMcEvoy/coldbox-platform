<!-----------------------------------------------------------------------********************************************************************************Copyright 2005-2007 ColdBox Framework by Luis Majano and Ortus Solutions, Corpwww.coldboxframework.com | www.luismajano.com | www.ortussolutions.com********************************************************************************Author 	    :	Luis MajanoDate        :	August 21, 2006Description :	This is a cfc that contains method implementations for the base	cfc's eventhandler and plugin. This is an action base controller,	is where all action methods will be placed.	The front controller remains lean and mean.-----------------------------------------------------------------------><cfcomponent name="frameworkSupertype" 			 hint="This is the layer supertype cfc." 			 output="false"><!------------------------------------------- CONSTRUCTOR ------------------------------------------->	<cfscript>	/* Controller Reference */	controller = structNew();	/* Instance scope */	instance = structnew();	/* Unique Instance ID for the object. */	instance.__hash = hash(createUUID());	</cfscript><!------------------------------------------- RESOURCE METHODS ------------------------------------------->	<!--- ************************************************************* --->	<cffunction name="getHash" access="public" hint="Get the instance's unique UUID" returntype="string" output="false">		<cfreturn instance.__hash>	</cffunction>		<!--- ************************************************************* --->	<cffunction name="getDatasource" access="public" output="false" returnType="any" hint="I will return to you a datasourceBean according to the alias of the datasource you wish to get from the configstruct">		<!--- ************************************************************* --->		<cfargument name="alias" type="string" hint="The alias of the datasource to get from the configstruct (alias property in the config file)">		<!--- ************************************************************* --->		<cfscript>		var datasources = controller.getSetting("Datasources");		//Check for datasources structure		if ( structIsEmpty(datasources) ){			throw("There are no datasources defined for this application.","","Framework.actioncontroller.DatasourceStructureEmptyException");		}		//Try to get the correct datasource.		if ( structKeyExists(datasources, arguments.alias) ){			return controller.getPlugin("beanFactory").create("coldbox.system.beans.datasourceBean").init(datasources[arguments.alias]);		}		else{			throw("The datasource: #arguments.alias# is not defined.","","Framework.actioncontroller.DatasourceNotFoundException");		}		</cfscript>	</cffunction>	<!--- ************************************************************* --->	<cffunction name="getfwLocale" access="public" output="false" returnType="string" hint="Get the default locale string used in the framework.">		<cfscript>			var localeStorage = controller.getSetting("LocaleStorage");			var storage = evaluate(localeStorage);			if ( localeStorage eq "" )				throw("The default settings in your config are blank. Please make sure you create the i18n elements.","","Framework.actioncontroller.i18N.DefaultSettingsInvalidException");			if ( not structKeyExists(storage,"DefaultLocale") ){				controller.getPlugin("i18n").setfwLocale(controller.getSetting("DefaultLocale"));			}			return storage["DefaultLocale"];		</cfscript>	</cffunction>	<!--- ************************************************************* --->	<cffunction name="getMailSettings" access="public" output="false" returnType="any" hint="I will return to you a mailsettingsBean modeled after your mail settings in your config file.">		<cfscript>		return controller.getPlugin("beanFactory").create("coldbox.system.beans.mailsettingsBean").init(controller.getSetting("MailServer"),controller.getSetting("MailUsername"),controller.getSetting("MailPassword"), controller.getSetting("MailPort"));		</cfscript>	</cffunction>	<!--- ************************************************************* --->	<cffunction name="getResource" access="public" output="false" returnType="string" hint="Facade to i18n.getResource">		<!--- ************************************************************* --->		<cfargument name="resource" type="string" hint="The resource to retrieve from the bundle.">		<!--- ************************************************************* --->		<cfreturn controller.getPlugin("resourceBundle").getResource("#arguments.resource#")>	</cffunction>	<!--- ************************************************************* --->	<cffunction name="getSettingsBean"  hint="Returns a configBean with all the configuration structure." access="public"  returntype="coldbox.system.beans.configBean"   output="false">		<cfset var ConfigBean = controller.getPlugin("beanFactory").create("coldbox.system.beans.configBean").init(controller.getSettingStructure(false,true))>		<cfreturn ConfigBean>	</cffunction>	<!--- ************************************************************* --->		<cffunction name="announceInterception" access="public" returntype="void" hint="Announce an interception to the system." output="false" >		<cfargument name="state" 	required="true"  type="string" hint="The interception state to execute">
		<cfargument name="metadata" required="false" type="struct" default="#structNew()#" hint="A metadata structure used to pass intercepted information.">		<cfset controller.getInterceptorService().processState(argumentCollection=arguments)>	</cffunction>		<!--- ************************************************************* --->	<!------------------------------------------- FRAMEWORK FACADES ------------------------------------------->	<!--- View Rendering Facades --->	<cffunction name="renderView"         access="public" hint="Facade" output="false" returntype="Any">		<!--- ************************************************************* --->		<cfargument name="view" required="true" type="string">		<!--- ************************************************************* --->		<cfreturn controller.getPlugin("renderer").renderView(arguments.view)>	</cffunction>	<cffunction name="renderExternalView" access="public" hint="Facade" output="false" returntype="Any">		<!--- ************************************************************* --->		<cfargument name="view" required="true" type="string">		<!--- ************************************************************* --->		<cfreturn controller.getPlugin("renderer").renderExternalView(arguments.view)>	</cffunction>	<!--- Plugin Facades --->	<cffunction name="getMyPlugin" access="public" hint="Facade" returntype="any" output="false">		<!--- ************************************************************* --->		<cfargument name="plugin" 		type="string"  required="true" >		<cfargument name="newInstance"  type="boolean" required="false" default="false">		<!--- ************************************************************* --->		<cfreturn controller.getPlugin(arguments.plugin, true, arguments.newInstance)>	</cffunction>	<cffunction name="getPlugin"   access="public" hint="Facade" returntype="any" output="false">		<!--- ************************************************************* --->		<cfargument name="plugin"       type="string" hint="The Plugin object's name to instantiate" >		<cfargument name="customPlugin" type="boolean" required="false" default="false">		<cfargument name="newInstance"  type="boolean" required="false" default="false">		<!--- ************************************************************* --->		<cfreturn controller.getPlugin(argumentCollection=arguments)>	</cffunction>	<!---Cache Facades --->	<cffunction name="getColdboxOCM" access="public" output="false" returntype="any" hint="Get ColdboxOCM">		<cfreturn controller.getColdboxOCM()/>	</cffunction>	<!--- Setting Facades --->	<cffunction name="getSettingStructure"  hint="Facade" access="public"  returntype="struct"   output="false">		<!--- ************************************************************* --->		<cfargument name="FWSetting"  	type="boolean" 	 required="false"  default="false">		<cfargument name="DeepCopyFlag" type="boolean"   required="false"  default="false">		<!--- ************************************************************* --->		<cfreturn controller.getSettingStructure(arguments.FWSetting,arguments.DeepCopyFlag)>	</cffunction>	<cffunction name="getSetting" 			hint="Facade" access="public" returntype="any"      output="false">		<!--- ************************************************************* --->		<cfargument name="name" 	    type="string"   	required="true">		<cfargument name="FWSetting"  	type="boolean" 	 	required="false"  default="false">		<!--- ************************************************************* --->		<cfreturn controller.getSetting(arguments.name,arguments.FWSetting)>	</cffunction>	<cffunction name="settingExists" 		hint="Facade" access="public" returntype="boolean"  output="false">		<!--- ************************************************************* --->		<cfargument name="name" 		type="string"  	required="true">		<cfargument name="FWSetting"  	type="boolean"  required="false"  default="false">		<!--- ************************************************************* --->		<cfreturn controller.settingExists(arguments.name,arguments.FWSetting)>	</cffunction>	<cffunction name="setSetting" 		    hint="Facade" access="public"  returntype="void"     output="false">		<!--- ************************************************************* --->		<cfargument name="name"  type="string" required="true" >		<cfargument name="value" type="any"    required="true" >		<!--- ************************************************************* --->		<cfset controller.setSetting(arguments.name,arguments.value)>	</cffunction>	<!--- Event Facades --->	<cffunction name="setNextEvent" access="public" returntype="void" hint="Facade"  output="false">		<!--- ************************************************************* --->		<cfargument name="event"  			type="string"   required="false"	default="#controller.getSetting("DefaultEvent")#" >		<cfargument name="queryString"  	type="any" 		required="No" 		default="" >		<cfargument name="addToken"			type="boolean" 	required="false" 	default="false"	>		<cfargument name="persist" 			type="string"   required="false"  	default="">		<!--- ************************************************************* --->		<cfset controller.setNextEvent(arguments.event,arguments.queryString,arguments.addToken,arguments.persist)>	</cffunction>	<cffunction name="runEvent" 	access="public" returntype="void" hint="Facade" output="false">		<!--- ************************************************************* --->		<cfargument name="event" type="string" required="no" default="">		<!--- ************************************************************* --->		<cfset controller.runEvent(arguments.event)>	</cffunction>		<!--- Debug Mode Facades --->	<cffunction name="getDebugMode" access="public" hint="Facade to get your current debug mode" returntype="boolean"  output="false">		<cfset controller.getDebuggerService().getDebugMode()>	</cffunction>	<cffunction name="setDebugMode" access="public" hint="Facade to set your debug mode" returntype="void"  output="false">		<cfargument name="mode" type="boolean" required="true" >		<cfset controller.getDebuggerService().setDebugMode(arguments.mode)>	</cffunction>		<!--- Controller Accessor/Mutators --->	<cffunction name="getcontroller" access="public" output="false" returntype="any" hint="Get controller">
		<cfreturn controller/>
	</cffunction>
	<cffunction name="setcontroller" access="public" output="false" returntype="void" hint="Set controller">
		<cfargument name="controller" type="any" required="true"/>
		<cfset variables.controller = arguments.controller/>
	</cffunction><!------------------------------------------- UTILITY METHODS ------------------------------------------->		<cffunction name="includeUDF" access="private" hint="Injects a UDF Library into the handler." output="false" returntype="void">		<!--- ************************************************************* --->		<cfargument name="udflibrary" required="true" type="string" hint="The UDF library to inject.">		<!--- ************************************************************* --->		<cfset var UDFFullPath = ExpandPath(arguments.udflibrary)>		<cfset var UDFRelativePath = ExpandPath("/" & getController().getSetting("AppMapping") & "/" & arguments.udflibrary)>				<!--- check if UDFLibraryFile is defined  --->		<cfif arguments.udflibrary neq "">			<!--- Check if file exists on declared relative --->			<cfif fileExists(UDFRelativePath)>				<cfinclude template="/#getController().getSetting("appMapping")#/#arguments.udflibrary#">			<cfelseif fileExists(UDFFullPath)>				<cfinclude template="#arguments.udflibrary#">						<cfelse>				<cfthrow type="Framework.eventhandler.UDFLibraryNotFoundException" 				         message="Error loading UDFLibraryFile. The UDF library was not found in your application's include directory or in the location you specified: <strong>#UDFCheckPath#</strong>. Please make sure you verify the file's location.">			</cfif>		</cfif>	</cffunction>		<!--- CFLOCATION Facade --->	<cffunction name="relocate" access="private" hint="Facade for cflocation" returntype="void">		<cfargument name="url" 		required="yes" 		type="string">		<cfargument name="addtoken" required="false" 	type="boolean" default="false">		<cflocation url="#arguments.url#" addtoken="#addtoken#">	</cffunction>	<!--- Throw Facade --->	<cffunction name="throw" access="private" hint="Facade for cfthrow" output="false">		<!--- ************************************************************* --->		<cfargument name="message" 	type="string" 	required="yes">		<cfargument name="detail" 	type="string" 	required="no" default="">		<cfargument name="type"  	type="string" 	required="no" default="Framework">		<!--- ************************************************************* --->		<cfthrow type="#arguments.type#" message="#arguments.message#"  detail="#arguments.detail#">	</cffunction>	<!--- Dump facade --->	<cffunction name="dump" access="private" hint="Facade for cfmx dump" returntype="void">		<cfargument name="var" required="yes" type="any">		<cfdump var="#var#">	</cffunction>	<!--- Abort Facade --->	<cffunction name="abort" access="private" hint="Facade for cfabort" returntype="void" output="false">		<cfabort>	</cffunction>	<!--- Include Facade --->	<cffunction name="include" access="private" hint="Facade for cfinclude" returntype="void" output="false">		<cfargument name="template" type="string">		<cfinclude template="#template#">	</cffunction></cfcomponent>