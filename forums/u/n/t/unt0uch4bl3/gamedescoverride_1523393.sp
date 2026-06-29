#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>

#define NAME "Game Description Override"
#define VERSION "1.2"

new String:g_szGameDesc[64] = "";
new Handle:g_hCvarGameDesc = INVALID_HANDLE;
new Handle:g_hCvarManiFix = INVALID_HANDLE;
new bool:g_bChangeGameDesc = false;
new bool:g_bMapRoaded = false;
new bool:g_bManiFix = false;

public Plugin:myinfo = {
	name = NAME,
	author = "psychonic",
	description = "Allows changing of displayed game type in server browser",
	version = VERSION,
	url = "http://www.nicholashastings.com"
};

public OnPluginStart()
{
	CreateConVar("gamedesc_override_version", VERSION, NAME, FCVAR_PLUGIN|FCVAR_DONTRECORD|FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hCvarGameDesc = CreateConVar("gamedesc_override", "", "Game Description Override (set blank \"\" for default no override)", FCVAR_PLUGIN);
	g_hCvarManiFix = CreateConVar("gamedesc_manifix", "0", "Mani Fix. Enable if 3rd party plugins have trouble detecting gametype. 0-Disabled (default), 1-Enabled", FCVAR_PLUGIN);
	HookConVarChange(g_hCvarGameDesc, CvarChange_GameDesc);
	HookConVarChange(g_hCvarManiFix, CvarChange_ManiFix);
}

public OnAllPluginsLoaded()
{
	if (LibraryExists("sdkhooks.ext"))
	{
		SDKHooksFail();
	}
}

public OnLibraryRemoved(const String:name[])
{
	if (strcmp(name, "sdkhooks.ext") == 0)
	{
		SDKHooksFail();
	}
}

SDKHooksFail()
{
	SetFailState("SDKHooks is required for Game Description Override");
}

public OnMapStart()
{
	g_bMapRoaded = true;
}

public OnMapEnd()
{
	g_bMapRoaded = false;
}

public Action:OnGetGameDescription(String:gameDesc[64])
{
	if (g_bChangeGameDesc && (g_bMapRoaded || !g_bManiFix))
	{
		strcopy(gameDesc, sizeof(gameDesc), g_szGameDesc);
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

public CvarChange_GameDesc(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	strcopy(g_szGameDesc, sizeof(g_szGameDesc), newVal);
	if (newVal[0] > 0)
	{
		g_bChangeGameDesc = true;
	}
	else
	{
		g_bChangeGameDesc = false;
	}
}

public CvarChange_ManiFix(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	g_bManiFix = bool:StringToInt(newVal);
}