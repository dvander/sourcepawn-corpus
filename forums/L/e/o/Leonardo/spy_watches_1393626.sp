#pragma semicolon 1

#define AUTOLOAD_EXTENSIONS
#define REQUIRE_EXTENSIONS
#include <sourcemod>
#include <tf2items>

#define PLUGIN_VERSION "1.0.0"

new Handle:g_cvVersion = INVALID_HANDLE;
new Handle:g_cvEnable = INVALID_HANDLE;

public Plugin:myinfo = {
	name = "[TF2V] Default Spy Watches",
	author = "Leonardo",
	description = "Removing special attributes for spywatches",
	version = PLUGIN_VERSION,
	url = "http://xpenia.pp.ru"
};

public OnPluginStart()
{
	g_cvVersion = CreateConVar("sm_tf2v_dsw_version", PLUGIN_VERSION, "TF2V Default Spy Watches version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED);
	SetConVarString(g_cvVersion, PLUGIN_VERSION, true, true);
	
	g_cvEnable = CreateConVar("sm_tf2v_dsw_enable", "1", "Enable/disable plugin", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED);
	
	new String:sGameType[64];
	GetGameFolderName(sGameType, sizeof(sGameType));
	if(!StrEqual(sGameType, "tf", false))
		SetFailState("This plugin for Team Fortress 2 only!");
}

public OnMapStart()
{
	if(GuessSDKVersion()==SOURCE_SDK_EPISODE2VALVE)
		SetConVarString(g_cvVersion, PLUGIN_VERSION, true, true);
}

public Action:TF2Items_OnGiveNamedItem(iClient, String:sClassName[], iItemDefinitionIndex, &Handle:hItemOverride)
{
	if(iClient<=0 || iClient>MaxClients || !IsClientConnected(iClient) || !IsClientInGame(iClient) || GetClientTeam(iClient)<=1 || !IsPlayerAlive(iClient))
		return Plugin_Continue;
	
	if(hItemOverride != INVALID_HANDLE)
		return Plugin_Continue;
	
	if(!GetConVarBool(g_cvEnable))
		return Plugin_Continue;
	
	if(iItemDefinitionIndex==59 || iItemDefinitionIndex==60 || iItemDefinitionIndex==212)
	{
		new Handle:hItem = TF2Items_CreateItem(OVERRIDE_ATTRIBUTES);
		TF2Items_SetNumAttributes(hItem, 0);
		
		if(hItem!=INVALID_HANDLE)
		{
			hItemOverride = hItem;
			//CloseHandle(hItem);
			return Plugin_Changed;
		}
	}
	
	return Plugin_Continue;
}