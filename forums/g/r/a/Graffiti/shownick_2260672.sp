#include <sourcemod>
#include <sdktools>
#include <cstrike>

#define PLUGIN_VERSION   "1.0"

public Plugin:myinfo =
{
	name = "Show nickname on HUD",
	author = "Graffiti",
	description = "Show nickname on HUD for CSGO",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	CreateConVar("sm_show_nickname_on_hud_version", PLUGIN_VERSION, "Show nickname on HUD", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);
	CreateTimer(0.5, Timer, _, TIMER_REPEAT);
}

stock TraceClientViewEntity(client)
{
	new Float:m_vecOrigin[3];
	new Float:m_angRotation[3];

	GetClientEyePosition(client, m_vecOrigin);
	GetClientEyeAngles(client, m_angRotation);

	new Handle:tr = TR_TraceRayFilterEx(m_vecOrigin, m_angRotation, MASK_VISIBLE, RayType_Infinite, TRDontHitSelf, client);
	new pEntity = -1;

	if (TR_DidHit(tr))
	{
		pEntity = TR_GetEntityIndex(tr);
		CloseHandle(tr);
		return pEntity;
	}

	if(tr != INVALID_HANDLE)
	{
		CloseHandle(tr);
	}
	
	return -1;
}

public bool:TRDontHitSelf(entity, mask, any:data)
{
return (1 <= entity <= MaxClients); 
}

public Action:Timer(Handle:timer)
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsPlayerAlive(i))
		{
			new target = TraceClientViewEntity(i);
			if(target > 0 && target <= MaxClients && IsClientInGame(target) && IsPlayerAlive(target))
			{
				PrintHintText(i, "Player: \"%N\"", target);
			}
		}
	}
	return Plugin_Continue; 
}