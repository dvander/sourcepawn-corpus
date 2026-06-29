#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <colors>

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo =
{
	name = "Greentexter",
	author = "Rowedahelicon",
	description = "My First Plugin - Allows users to do Greentexting",
	version = "1.0.0.0",
	url = "http://www.rowedahelicon.com"
};

public OnPluginStart()
{

        RegConsoleCmd("sm_g", greenText);	

	CreateConVar("greentext_version", PLUGIN_VERSION, "Plugin Version", FCVAR_PLUGIN|FCVAR_SPONLY|

FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

}

public IsValidClient( client ) 
{ 
    if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) ) 
        return false; 
     
    return true; 
}

public Action:greenText(client, args)
{
if(!IsValidClient(client))
return Plugin_Handled;
if(args < 1) // Not enough parameters
{
ReplyToCommand(client, "[SM] use: sm_g <text>");
return Plugin_Handled;
}

decl String:CleanText[192];
GetCmdArg(1, CleanText,sizeof(CleanText));
StripQuotes(CleanText);

CPrintToChatAllEx(client, "{teamcolor}%N: {green}>%s", client,CleanText);

return Plugin_Handled;

}
       
