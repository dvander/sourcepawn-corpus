#include <sourcemod>
#include <sdktools>
#include <left4downtown>

new Handle:mapActive = INVALID_HANDLE;
static Handle:tankSacrmodel = INVALID_HANDLE;
new bool:g_bPlgTPDisabled = true;

public OnPluginStart()
{
	mapActive = CreateConVar("l4d2_tankproh_map", "", "Set the map for which the plugin should be activated");
	tankSacrmodel = CreateConVar("l4d2_tankproh_sacrmodel", "0", "Replace tank model to one from Sacrifice.");

	HookEvent("tank_spawn", Event_TankSpawn);
}

public OnMapStart()
{
	g_bPlgTPDisabled = true;
	
	decl String:sCurrentMap[64], String:sMap[256];
	GetCurrentMap(sCurrentMap, sizeof(sCurrentMap));
	GetConVarString(mapActive, sMap, sizeof(sMap));
	
	if(StrContains(sMap, sCurrentMap) >= 0)
	{
		g_bPlgTPDisabled = false;
	}
	
	if(!IsModelPrecached("models/infected/hulk_dlc3.mdl"))
	{
		PrecacheModel("models/infected/hulk_dlc3.mdl");
	}
}

public Event_TankSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(tankSacrmodel) && g_bPlgTPDisabled)
	{
		new tankmod = GetClientOfUserId(GetEventInt(event, "userid"));
	
		if (tankmod && IsClientInGame(tankmod))
		{
			SetEntityModel(tankmod, "models/infected/hulk_dlc3.mdl");
		}
	}
}

public Action:L4D_OnSpawnTank(const Float:vector[3], const Float:qangle[3])
{
	if(!g_bPlgTPDisabled)
	{
		return Plugin_Handled;
	}
	else
	{
		return Plugin_Continue;
	}
}
	//return Plugin_Continue;
	//return Plugin_Handled;