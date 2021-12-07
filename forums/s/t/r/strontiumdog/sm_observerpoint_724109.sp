//
// SourceMod Script
//
// Developed by <eVa>Dog
// December 2008
// http://www.theville.org
//

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.100"

new Handle:g_Enabled = INVALID_HANDLE 

public Plugin:myinfo = 
{
	name = "Observer Point",
	author = "<eVa>Dog",
	description = "Adds an info_observer_point to maps that may not have one",
	version = PLUGIN_VERSION,
	url = "http://www.theville.org"
}

public OnPluginStart()
{
	CreateConVar("sm_observerpoint_version", PLUGIN_VERSION, "Version of Observer Point", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	g_Enabled  = CreateConVar("sm_observerpoint_enabled", "1", "- Enables/Disables the plugin")
	
	HookEvent("teamplay_round_start", RoundStartEvent)
}

public OnEventShutdown()
{
	UnhookEvent("teamplay_round_start", RoundStartEvent)
}

public RoundStartEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(g_Enabled))
	{
		new edict_index = FindEntityByClassname(-1, "info_observer_point")
		if (edict_index == -1)
		{			
			new Float:vecresult[3]
			new Float:camangle[3]
			
			new Float:vPos1[3]
			vPos1[0] = GetRandomFloat(0.1, 1.0) * 2000 
			vPos1[1] = GetRandomFloat(0.1, 1.0) * 2000 
			vPos1[2] = 0.0
			
			new Float:vPos2[3]
			vPos2[0] = 0.0
			vPos2[1] = 0.0
			vPos2[2] = 1000.0
			
			MakeVectorFromPoints(vPos2, vPos1, vecresult)
			GetVectorAngles(vecresult, camangle)
			
			new g_iop = CreateEntityByName("info_observer_point")
			DispatchKeyValue(g_iop, "Angles", "90 0 0")
			DispatchKeyValue(g_iop, "TeamNum", "0")
			DispatchKeyValue(g_iop, "StartDisabled", "0")
			DispatchSpawn(g_iop)
			AcceptEntityInput(g_iop, "Enable")
			TeleportEntity(g_iop, vPos2, camangle, NULL_VECTOR)
			
			PrintToServer("[SM] Added info_observer_point: %i", g_iop)
		}
	}
}