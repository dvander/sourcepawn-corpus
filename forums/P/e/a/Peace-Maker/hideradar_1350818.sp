#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.1"

new g_Radar;
new g_Bomb;
new g_PlayerManager;

public Plugin:myinfo = 
{
    name = "Hide Radar",
    author = "Jannik 'Peace-Maker' Hartung, javalia",
    description = "Hides enemies from being shown on the radar.",
    version = PLUGIN_VERSION,
    url = "http://www.wcfan.de/"
}

public OnPluginStart()
{
	CreateConVar("sm_hideradar_version", PLUGIN_VERSION, "Hides the radar", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	HookEvent("round_start", Event_OnRoundStart);
	g_Radar = FindSendPropOffs("CCSPlayerResource", "m_bPlayerSpotted");
	if(g_Radar == -1)
		SetFailState("Couldnt find the m_bPlayerSpotted offset!");
	
	g_Bomb = FindSendPropOffs("CCSPlayerResource", "m_bBombSpotted");
	if(g_Bomb == -1)
		SetFailState("Couldnt find the m_bBombSpotted offset!");
}

public Action:Event_OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_PlayerManager = FindEntityByClassname(0, "cs_player_manager");
	
	SDKHook(g_PlayerManager, SDKHook_PreThink, OnPrePostThink);
	SDKHook(g_PlayerManager, SDKHook_Think, OnPrePostThink);
	SDKHook(g_PlayerManager, SDKHook_PreThinkPost, OnPrePostThink);
	SDKHook(g_PlayerManager, SDKHook_PostThink, OnPrePostThink);
	SDKHook(g_PlayerManager, SDKHook_PostThinkPost, OnPrePostThink);
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_PreThink, OnPrePostThink);
	SDKHook(client, SDKHook_Think, OnPrePostThink);
	SDKHook(client, SDKHook_PreThinkPost, OnPrePostThink);
	SDKHook(client, SDKHook_PostThink, OnPrePostThink);
	SDKHook(client, SDKHook_PostThinkPost, OnPrePostThink);
}

public OnPrePostThink(client)
{	
	for(new target = 1; target < 65; target++){
		SetEntData(g_PlayerManager, g_Radar + target, 0, 4, true);
	}
	SetEntData(g_PlayerManager, g_Bomb, 0, 4, true);
}