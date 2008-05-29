<!-----------------------------------------------------------------------
********************************************************************************
Copyright 2005-2008 ColdBox Framework by Luis Majano and Ortus Solutions, Corp
www.coldboxframework.com | www.luismajano.com | www.ortussolutions.com
********************************************************************************

Author     :	Luis Majano
Date        :	10/16/2007
Description :
	This component is the coldbox remote proxy used for model operation.
	This will convert the framework into a model framework rather than a 
	HTML MVC framework.	
----------------------------------------------------------------------->
<cfcomponent name="ColdboxProxy" output="false" hint="This component is the coldbox remote proxy used for model operation." >
	
<!------------------------------------------- PUBLIC ------------------------------------------->	

	<!--- process a remote call --->
	<cffunction name="process" output="false" access="remote" returntype="any" hint="Process a remote call into ColdBox's event model and return data/objects back.">
		<!--- There are no arguments defined as they come in as a collection of arguments. --->
		<cfscript>
			var cbController = "";
			var event = "";
			var results = "";
			
			/* Get ColdBox Controller */
			cbController = getController();
			
			try{
				//Create the request context
				Event = cbController.getRequestService().requestCapture();
				
				/* Test Event Name */
				if( not structKeyExists(arguments, "#event.getEventName()#") ){
					throwit("Event not detected","The #event.geteventName()# variable does not exist in the arguments.");
				}
				
				//Append the arguments to the collection
				Event.collectionAppend(arguments,true);
				//Set that this is a proxy request.
				Event.setProxyRequest();
				
				//Execute the app start handler if not fired already
				if ( cbController.getSetting("ApplicationStartHandler") neq "" and (not cbController.getAppStartHandlerFired()) ){
					cbController.runEvent(cbController.getSetting("ApplicationStartHandler"),true);
					cbController.setAppStartHandlerFired(true);
				}
				
				//Execute a pre process interception.
				cbController.getInterceptorService().processState("preProcess");
				
				//Request Start Handler if defined
				if ( cbController.getSetting("RequestStartHandler") neq "" ){
					cbController.runEvent(cbController.getSetting("RequestStartHandler"),true);
				}
					
				//Execute the Event
				results = cbController.runEvent();
				
				//Request END Handler if defined
				if ( cbController.getSetting("RequestEndHandler") neq "" ){
					cbController.runEvent(cbController.getSetting("RequestEndHandler"),true);
				}
				
				//Execute the post process interceptor
				cbController.getInterceptorService().processState("postProcess");
			}
			catch(Any e){
				//Log Exception
				cbController.getExceptionService().ExceptionHandler(e,"coldboxproxy","Process Exception");
				/* Verify stacktrace */
				if( not structKeyExists(e,"stacktrace") ){
					e.stacktrace = "";
				}
				/* Request Profilers */
				pushTimers(cbController);
			
				/* Custom throw. */
				throwit(e.message.toString(),e.detail.toString() & e.stacktrace.toString());
			}
			
			/* Request Profilers */
			pushTimers(cbController);
				
			//Determine what to return via the setting
			if ( cbController.getSetting("ProxyReturnCollection") ){
				//Return request collection
				return Event.getCollection();
			}
			else{
				//Return results from handler
				return results;
			}
		</cfscript>		
	</cffunction>
	
	<!--- process an interception --->
	<cffunction name="announceInterception" output="false" access="remote" returntype="boolean" hint="Process a remote interception.">
		<!--- ************************************************************* --->
		<cfargument name="state" 			type="string" 	required="true" hint="The intercept state"/>
		<cfargument name="interceptData"    type="any" 	    required="false" default="" hint="This method will take the contents and embedded into a structure"/>
		<!--- ************************************************************* --->
		<cfscript>
			var cbController = "";
			var interceptionStructure = structnew();
			
			/* Get ColdBox Controller */
			cbController = getController();
			
			/* emded contents */
			interceptionStructure.interceptData = arguments.interceptData;
			
			//Intercept
			try{
				cbController.getInterceptorService().processState(arguments.state,interceptionStructure);
			}
			catch(Any e){
				//Log Exception
				cbController.getExceptionService().ExceptionHandler(e,"coldboxproxy","Interception Exception");
				/* Request Profilers */
				pushTimers(cbController);
				/* Return */
				return false;
			}
			
			/* Request Profilers */
			pushTimers(cbController);
			
			/* Return */
			return true;
		</cfscript>
	</cffunction>
	
<!------------------------------------------- PRIVATE ------------------------------------------->	
	
	<!--- Push Timers --->
	<cffunction name="pushTimers" access="private" returntype="void" hint="Push timers into debugging stack" output="false" >
		<cfargument name="cbController" required="true" type="any" hint="the coldbox controller">
		<cfscript>
			var dService = arguments.cbController.getDebuggerService();
			
			/* Request Profilers */
			if ( dService.getDebuggerConfigBean().getPersistentRequestProfiler() and
				 structKeyExists(request,"debugTimers") ){
				/* Push timers */
				dService.pushProfiler(request.DebugTimers);
			}
		</cfscript>
	</cffunction>
	
	<!--- verifyColdBox --->
	<cffunction name="verifyColdBox" output="false" access="private" returntype="boolean" hint="Verify the coldbox app">
		<cfscript>
		//Verify the coldbox app is ok, else throw
		if ( not structKeyExists(application,"cbController") ){
			throwit("ColdBox Controller Not Found", "The coldbox main controller has not been initialized");
		}
		else
			return true;
		</cfscript>
	</cffunction>
	
	<!--- Get the ColdBox Controller. --->
	<cffunction name="getController" output="false" access="private" returntype="any" hint="Get the controller from application scope.">
		<cfscript>
			/* Verify ColdBox */
			verifyColdBox();
			/* Return it. */
			return application.cbController;
		</cfscript>
	</cffunction>
	
	<!--- Facade: Get a plugin --->
	<cffunction name="getPlugin" access="private" returntype="any" hint="Plugin factory, returns a new or cached instance of a plugin." output="true">
		<!--- ************************************************************* --->
		<cfargument name="plugin" 		type="string"  hint="The Plugin object's name to instantiate" >
		<cfargument name="customPlugin" type="boolean" required="false" default="false" hint="Used internally to create custom plugins.">
		<cfargument name="newInstance"  type="boolean" required="false" default="false" hint="If true, it will create and return a new plugin. No caching or persistance.">
		<!--- ************************************************************* --->
		<cfreturn getController().getPlugin(argumentCollection=arguments)>
	</cffunction>
	
	<!--- Interceptor Facade --->
	<cffunction name="getInterceptor" access="private" output="false" returntype="any" hint="Get an interceptor">
		<!--- ************************************************************* --->
		<cfargument name="interceptorClass" required="true" type="string" hint="The qualified class of the itnerceptor to retrieve">
		<!--- ************************************************************* --->
		<cfreturn getController().getInterceptorService().getInterceptor(arguments.interceptorClass)>
	</cffunction>
	
	<!--- Facade: Get the IOC Plugin. --->
	<cffunction name="getIoCFactory" output="false" access="private" returntype="any" hint="Gets the IOC Factory in usage: coldspring or lightwire">
		<cfreturn getController().getPlugin("ioc").getIoCFactory()>
	</cffunction>
	
	<!--- Facade: Get the an ioc bean --->
	<cffunction name="getBean" output="false" access="private" returntype="any" hint="Get a bean from the ioc plugin.">
		<cfargument name="beanName" type="string" required="true" hint="The bean name to get."/>
		<cfreturn getController().getPlugin("ioc").getBean(arguments.beanName)>
	</cffunction>
	
	<!--- Facade: Get COldBox OCM --->
	<cffunction name="getColdboxOCM" access="private" output="false" returntype="any" hint="Get ColdboxOCM: coldbox.system.cache.cacheManager">
		<cfreturn getController().getColdboxOCM()/>
	</cffunction>
	
	<!--- Bootstrapper LoadColdBox --->
	<cffunction name="loadColdbox" access="private" output="false" returntype="void" hint="Load a coldbox application, and place the coldbox controller in application scope for usage. If the application is already running, then it will not re-do it, unless you specify the reload argument or the application expired.">
		<!--- ************************************************************* --->
		<cfargument name="appRootPath" 		type="string"  required="true" hint="The absolute location of the root of the coldbox application. This is usually where the Application.cfc is and where the conventions are read from."/>
		<cfargument name="configLocation" 	type="string"  required="false" default="" 		hint="The absolute location of the config file to override, if not passed, it will try to locate it by convention."/>
		<cfargument name="reloadApp" 		type="boolean" required="false" default="false" hint="Flag to reload the application or not"/>
		<!--- ************************************************************* --->
		<cfset var cbController = "">
		<cfset var appHash = hash(getBaseTemplatePath())>
		
		<!--- Reload Checks --->
		<cfif not structKeyExists(application,"cbController") or not application.cbController.getColdboxInitiated() or arguments.reloadApp>
			<cflock type="exclusive" name="#appHash#" timeout="30" throwontimeout="true">
				<cfscript>
				if ( not structkeyExists(application,"cbController") or not application.cbController.getColdboxInitiated() or arguments.reloadApp ){
					/* Cleanup, Just in Case */
					if( structKeyExists(application,"cbController") ){
						structDelete(application,"cbController");
					}
					/* Load it Up baby!! */
					cbController = CreateObject("component", "coldbox.system.controller").init( appRootPath );
					cbController.getLoaderService().setupCalls(arguments.configLocation);
					/* Put in Scope */
					application.cbController = cbController;
				}				
				</cfscript>
			</cflock>
		</cfif>		
		
		<!--- Application Startup. --->
		<cfif cbController.getSetting("ApplicationStartHandler") neq "" and (not cbController.getAppStartHandlerFired())>
			<cfset cbController.runEvent(cbController.getSetting("ApplicationStartHandler"),true)>
			<cfset cbController.setAppStartHandlerFired(true)>
		</cfif>
	</cffunction>

	<!--- Throw Facade --->
	<cffunction name="throwit" access="private" hint="Facade for cfthrow" output="false">
		<!--- ************************************************************* --->
		<cfargument name="message" 	type="any" 	required="yes">
		<cfargument name="detail" 	type="any" 	required="no" default="">
		<!--- ************************************************************* --->
		<cfthrow type="coldboxproxyException" message="#arguments.message#"  detail="#arguments.detail#">
	</cffunction>	
	<!--- Dump it Facade --->
	<cffunction name="dumpit" access="private" hint="Facade for cfmx dump" returntype="void">
		<cfargument name="var" required="yes" type="any">
		<cfdump var="#var#">
	</cffunction>	
	<!--- Abort it facade --->
	<cffunction name="abortit" access="private" hint="Facade for cfabort" returntype="void" output="false">
		<cfabort>
	</cffunction>
	
</cfcomponent>