#include <sourcemod>
#undef REQUIRE_PLUGIN 
//#include <autoupdate>

#define PLUGIN_VERSION "1.0.2"

public Plugin:myinfo = 
{
	name = "Bomb Score Modifier",
	author = "exvel",
	description = "Allows you to change the score that player gets for planting/exploding/defusing the bomb",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.net"
}

// CVars' handles
new Handle:cvar_bomb_score = INVALID_HANDLE;
new Handle:cvar_bomb_score_exploding_bonus = INVALID_HANDLE;
new Handle:cvar_bomb_score_defusing_bonus = INVALID_HANDLE;
new Handle:cvar_bomb_score_planting_bonus = INVALID_HANDLE;

// Cvars' varibles
new bool:bomb_score = true;
new bomb_score_exploding_bonus = 3;
new bomb_score_defusing_bonus = 3;
new bomb_score_planting_bonus = 0;

public OnPluginStart()
{
	// Checking that game is CS
	decl String:gameName[30];
	GetGameFolderName(gameName, sizeof(gameName));
	
	if (!StrEqual(gameName, "cstrike", false))
	{
		SetFailState("This plugin is only for Counter-Strike: Source.");
	}
	
	CreateConVar("sm_bomb_score_version", PLUGIN_VERSION, "Bomb Score Modifier Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	cvar_bomb_score = CreateConVar("sm_bomb_score", "1", "Enabled/Disabled bomb score modifier functionality, 0 = off/1 = on", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_bomb_score_exploding_bonus = CreateConVar("sm_bomb_score_exploding_bonus", "3", "Amount of frags that player gets for exploding the bomb", FCVAR_PLUGIN);
	cvar_bomb_score_defusing_bonus = CreateConVar("sm_bomb_score_defusing_bonus", "3", "Amount of frags that player gets for defusing the bomb", FCVAR_PLUGIN);
	cvar_bomb_score_planting_bonus = CreateConVar("sm_bomb_score_planting_bonus", "0", "Amount of frags that player gets for planting the bomb", FCVAR_PLUGIN);
	
	// Hooking cvar change
	HookConVarChange(cvar_bomb_score, OnCVarChange);
	HookConVarChange(cvar_bomb_score_exploding_bonus, OnCVarChange);
	HookConVarChange(cvar_bomb_score_defusing_bonus, OnCVarChange);
	HookConVarChange(cvar_bomb_score_planting_bonus, OnCVarChange);
	
	// Hooking events
	HookEvent("bomb_exploded", Event_BombExploded);
	HookEvent("bomb_defused", Event_BombDefused);
	HookEvent("bomb_planted", Event_BombPlanted);
	
	AutoExecConfig(true, "plugin.bombscore");
}

public Action:Event_BombExploded(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (bomb_score && client != 0 && IsClientInGame(client))
	{
		new score = GetClientFrags(client) - 3 + bomb_score_exploding_bonus;
		SetEntProp(client, Prop_Data, "m_iFrags", score);
	}
	
	return Plugin_Continue;
}

public Action:Event_BombDefused(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (bomb_score && IsClientInGame(client))
	{
		new score = GetClientFrags(client) - 3 + bomb_score_defusing_bonus;
		SetEntProp(client, Prop_Data, "m_iFrags", score);
	}
	
	return Plugin_Continue;
}

public Action:Event_BombPlanted(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (bomb_score && IsClientInGame(client))
	{
		new score = GetClientFrags(client) + bomb_score_planting_bonus;
		SetEntProp(client, Prop_Data, "m_iFrags", score);
	}
	
	return Plugin_Continue;
}

public OnCVarChange(Handle:convar_hndl, const String:oldValue[], const String:newValue[])
{
	GetCVars();
}

public OnConfigsExecuted()
{
	GetCVars();
}

GetCVars()
{
	bomb_score = GetConVarBool(cvar_bomb_score);
	bomb_score_exploding_bonus = GetConVarInt(cvar_bomb_score_exploding_bonus);
	bomb_score_defusing_bonus = GetConVarInt(cvar_bomb_score_defusing_bonus);
	bomb_score_planting_bonus = GetConVarInt(cvar_bomb_score_planting_bonus);
}

/*
// Marking native functions
public bool:AskPluginLoad(Handle:myself, bool:late, String:error[], err_max)
{
	//MarkNativeAsOptional("AutoUpdate_AddPlugin");
	//MarkNativeAsOptional("AutoUpdate_RemovePlugin");
	return true;
}

// Creating auto-updater
public OnAllPluginsLoaded()
{
	if (LibraryExists("pluginautoupdate"))
	{
		//AutoUpdate_AddPlugin("bombscore.googlecode.com", "/svn/version.xml", PLUGIN_VERSION);
	}
}

public OnPluginEnd()
{
	if (LibraryExists("pluginautoupdate"))
	{
		//AutoUpdate_RemovePlugin();
	}
}
*/