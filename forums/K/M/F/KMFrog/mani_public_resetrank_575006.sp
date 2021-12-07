/*
Mani Reset Rank
Written by: [KM] + FROG +
Url: http://www.clan-km.com
*/
//------------------------------------------------------------------------------

//all lines must end with ;
#pragma semicolon 1
//Includes
#include <sourcemod>
#undef REQUIRE_PLUGIN
//Plugin Version
new const String:PLUGIN_VERSION[] = "0.0.1";
//Plugin Info
public Plugin:myinfo =
{
	name = "Mani Reset Rank",
	author = "Written by [KM] + FROG +",
	description = "Allows any player to reset their mani rank",
	version = PLUGIN_VERSION,
	url = "http://www.clan-km.com/"
};
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------

//OnPluginStart (Use: called when the plugin is loaded)
//------------------------------------------------------------------------------
public OnPluginStart()
{
	//Setup say command hooks
	RegConsoleCmd("say", Command_ChatHook_Say);
	RegConsoleCmd("say_team", Command_ChatHook_Say);
	//Setup cvars
	CreateConVar("mrr_plugin_version", PLUGIN_VERSION, "Mani Reset Rank", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	CreateConVar("mrr_plugin_url", "http://www.clan-km.com", "http://www.clan-km.com", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	CreateConVar("mrr_plugin_author", "[KM] + FROG +", "[KM] + FROG +", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
}
//------------------------------------------------------------------------------

//Command_ChatHook_Say (Use: The main chat hook)
//------------------------------------------------------------------------------
public Action:Command_ChatHook_Say(client, args)
{
	//Vars
	decl String:text[200];
	decl String:message[200];
	
	//Read the args into text
	if (GetCmdArgString(text, sizeof(text)) < 1)
	{
	    //No chat message, Ignore
		return Plugin_Continue;
	}

	//Get the chat message in ""
	BreakString(text,message,sizeof(message));
	
	//Check for the !resetrank
	if (strcmp(message, "!resetrank", false) == 0)
	{
		decl String:steamID[100];
		GetClientAuthString(client, steamID, sizeof(steamID));
		LogToGame("[Mani-Rank-Reset] Running: ma_resetrank \"%s\"", steamID);
		ServerCommand("ma_resetrank \"%s\"", steamID);
		PrintToChat(client, "[Mani-Rank-Reset] Your rank has been reset!");
		return Plugin_Handled;
	}
	
	//Was not a reset rank message, continue
	return Plugin_Continue;
}
//------------------------------------------------------------------------------
