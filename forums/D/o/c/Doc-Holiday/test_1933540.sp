#include <sourcemod>
#include <adminmenu>
#include <rtf-api>

new const String:PLUGIN_VERSION[] = "1.0.0";

public Plugin:myinfo = 
{
	name = "RTF API Examples",
	author = "SavSin",
	description = "RTF API Usage Examples",
	version = PLUGIN_VERSION,
	url = "http://www.norcalbots.com/"
};

public OnPluginStart()
{
	/* Public Version Convar */
	CreateConVar("rtf_apiue_version", PLUGIN_VERSION, "Version of RTF apiue", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	RegConsoleCmd("sm_test", Command_Test, "Test the Native");
}

public RTF_OnPlayerReported(reporter, reported, const String:authid[], const String:category[], const String:reason[], const String:description[])
{
	PrintToServer("%N Reported %N %s %s %s %s", reporter, reported, authid, category, reason, description);
}

public Action:Command_Test(iClient, iArg)
{
	decl String:szName[MAX_NAME_LENGTH], String:szAuthID[32], String:szIP[32];
	GetClientName(iClient, szName, sizeof(szName));
	GetClientAuthString(iClient, szAuthID, sizeof(szAuthID));
	GetClientIP(iClient, szIP, sizeof(szIP));
	
	ReportPlayer(0, iClient, "RTF Test API", "", "", szName, szAuthID, szIP, "Native Test", "Native Test Reason", "Sav is better than you");
}