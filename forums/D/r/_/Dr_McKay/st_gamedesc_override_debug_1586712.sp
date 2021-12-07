#pragma semicolon 1

#include <sourcemod>
#include <steamtools>

/*#undef REQUIRE_PLUGIN
#tryinclude <updater>

#define UPDATE_URL    "http://sm.doctormckay.com/game_desc_override/plugin.txt"*/
#define PLUGIN_VERSION "1.0.0-debug"

new String:description[100];
new Handle:descriptionCvar = INVALID_HANDLE;
new String:logFile[1024];

public Plugin:myinfo = {
	name        = "[Any] SteamTools Game Description Override",
	author      = "Dr. McKay",
	description = "Overrides the default game description (i.e. \"Team Fortress\") in the server browser using SteamTools",
	version     = PLUGIN_VERSION,
	url         = "http://www.doctormckay.com"
};

/*public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) 
{ 
	MarkNativeAsOptional("Updater_AddPlugin"); 
	return APLRes_Success;
}*/ 

public OnPluginStart()
{
	BuildPath(Path_SM, logFile, sizeof(logFile), "logs/st_gamedesc_override_debug.log");
	LogToFileEx(logFile, "SteamTools Game Description Override has loaded!");
	descriptionCvar = CreateConVar("st_gamedesc_override", "", "What to override your game description to.", FCVAR_SPONLY);
	GetConVarString(descriptionCvar, description, sizeof(description));
	HookConVarChange(descriptionCvar, CvarChanged);
	Steam_SetGameDescription(description);
	LogToFileEx(logFile, "Description set to %s", description);
}

public CvarChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	GetConVarString(descriptionCvar, description, sizeof(description));
	Steam_SetGameDescription(description);
	LogToFileEx(logFile, "Cvar changed, description set to %s", description);
}

/*public OnAllPluginsLoaded()
{
	if(LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
		RegServerCmd("st_gamedesc_override_forceupdate", Command_ForceUpdate, "Force SteamTools Game Description Override to check for updates");
		new String:newVersion[10];
		Format(newVersion, sizeof(newVersion), "%sA", PLUGIN_VERSION);
		CreateConVar("st_gamedesc_override_version", newVersion, "SteamTools Game Description Override Version", FCVAR_DONTRECORD|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	} else {
		CreateConVar("st_gamedesc_override_version", PLUGIN_VERSION, "SteamTools Game Description Override Version", FCVAR_DONTRECORD|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);	
	}
}*/

/*public Action:Command_ForceUpdate(args)
{
	if(Updater_ForceUpdate() == false)
	{
		PrintToServer("[SM] SteamTools Game Description Override is not in the Updater pool.");
	}
	return;
}

public Updater_OnPluginUpdated()
{
	ReloadPlugin();
}*/
