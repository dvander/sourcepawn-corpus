#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
	name 			= 		"Bomb Beacon",
	author 			= 		"Someone",
	version 		= 		"1.0",
	url 			= 		"https://hlmod.ru | https://discord.gg/UfD3dSa"
};

Handle g_hTimer;
int g_iBeamIndex;

public void OnPluginStart()
{
	HookEvent("bomb_dropped", 	Event_BombDropped							);
	HookEvent("bomb_pickup", 	Event_BombPickUp, 	EventHookMode_PostNoCopy);
}

public void OnMapStart() 
{
	g_iBeamIndex = PrecacheModel("materials/sprites/laserbeam.vmt", true);
	g_hTimer = null;
}

public void Event_BombDropped(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	g_hTimer = CreateTimer(1.0, TimerBeacon, EntIndexToEntRef(hEvent.GetInt("entindex")), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public void Event_BombPickUp(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	if(g_hTimer)	delete g_hTimer;
}

public Action TimerBeacon(Handle hTimer, int iEnt)
{
	if((iEnt = EntRefToEntIndex(iEnt)) != INVALID_ENT_REFERENCE)
	{
		float fPos[3];
		GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", fPos);
		int iColor[4];
		
		for(; iColor[3] < 4; iColor[3]++)
		{
			iColor[iColor[3]] = GetRandomInt(0, 255);
		}
		
		TE_SetupBeamRingPoint(fPos, 10.0, 600.0, g_iBeamIndex, -1, 0, 30, 1.0, 10.0, 1.0, iColor, 0, 0);
		TE_SendToAll();
		return Plugin_Continue;
	}
	
	g_hTimer = null;
	return Plugin_Stop;
}
