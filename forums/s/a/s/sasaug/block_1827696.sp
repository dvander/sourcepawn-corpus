//////////////////////////
//G L O B A L  S T U F F//
//////////////////////////
#include <sourcemod>
new Handle:cvar_leave;
new Handle:cvar_msg;


////////////////////////
//P L U G I N  I N F O//
////////////////////////
public Plugin:myinfo = 
{
	name = "Merasmus, Do Not Leave!",
	author = "sasaug",
	description = "Prevent merasmus from running away. Now you stay!",
	version = "1.0.0",
	url = "http://www.lyngaming.com"
}

//////////////////////////
//P L U G I N  S T A R T//
//////////////////////////
public OnPluginStart()
{
	// G A M E  C H E C K //
	decl String:game[32];
	GetGameFolderName(game, sizeof(game));
	if(!(StrEqual(game, "tf")))
	{
		SetFailState("This plugin is not designed for %s", game);
	}
	
	
	cvar_leave = CreateConVar("merasmus_allow_boss_leave", "0", "Allow or disallow merasmus from leaving, 0 to prevent him from leaving");
	cvar_msg = CreateConVar("merasmus_leave_warning", "0", "Enable warning message, 0 to disable");
	
	HookEvent("merasmus_escaped", Event_Merasmus_Escaped, EventHookMode_Pre);
	HookEvent("merasmus_escape_warning", Event_Merasmus_Escape_Warning, EventHookMode_Pre);
}

public Action:Event_Merasmus_Escaped(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!GetConVarInt(cvar_leave))	//Block if 0
		return Plugin_Handled;
	else
		return Plugin_Continue;
}

public Action:Event_Merasmus_Escape_Warning(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!GetConVarInt(cvar_msg))	//Block if 0
		return Plugin_Handled;
	else
		return Plugin_Continue;
}
