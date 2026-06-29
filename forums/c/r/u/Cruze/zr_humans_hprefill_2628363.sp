#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

Handle gH_HpRefillTime = null;

public Plugin myinfo = 
{
	name        = "[ZR] HP Refill after x seconds",
	author      = "Cruze",
	description = "HP Refill after x seconds for humans",
	version     = "1.0",
	url         = ""
};

public void OnPluginStart()
{
	gH_HpRefillTime = CreateConVar("sm_zr_hp_refill_time", "30", "Time between hp refill for humans?");
}

public void OnMapStart()
{
	CreateTimer(GetConVarFloat(gH_HpRefillTime), TIMER_REFILL, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action TIMER_REFILL(Handle timer)
{
	for(int c = 1; c <= MaxClients; c++)
	{
		if(GetClientTeam(c) == 3 && IsClientInGame(c))
		{
			PrintToChat(c, "[ZR] Your hp has been refilled!");
			SetEntProp(c, Prop_Data, "m_iHealth", 100);
		}
	}
}