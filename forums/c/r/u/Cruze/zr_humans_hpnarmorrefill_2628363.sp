#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

Handle gH_HpRefillTime = null;
Handle gH_ArmorHelmetRefillTime = null;

public Plugin myinfo = 
{
	name        = "[ZR] HP and Armor Refill",
	author      = "Cruze",
	description = "HP and Armor Refill after x seconds for humans",
	version     = "1.1",
	url         = ""
};

public void OnPluginStart()
{
	gH_HpRefillTime = CreateConVar("sm_zr_hp_refill_time", "30.0", "Time between hp refill for humans?");
	gH_ArmorHelmetRefillTime = CreateConVar("sm_zr_armor_refill_time", "30.0", "Time between armor refill for humans?");
}

public void OnMapStart()
{
	CreateTimer(GetConVarFloat(gH_HpRefillTime), TIMER_REFILL, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(GetConVarFloat(gH_ArmorHelmetRefillTime), TIMER_REFILL2, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action TIMER_REFILL(Handle timer)
{
	if(!GetConVarFloat(gH_HpRefillTime))
		return;
	
	for(int c = 1; c <= MaxClients; c++)
	{
		if(IsClientInGame(c) && GetClientTeam(c) == 3)
		{
			PrintToChat(c, "[ZR] Your hp has been refilled!");
			SetEntProp(c, Prop_Data, "m_iHealth", 100);
		}
	}
}
public Action TIMER_REFILL2(Handle timer)
{
	if(!GetConVarFloat(gH_ArmorHelmetRefillTime))
		return;

	for(int c = 1; c <= MaxClients; c++)
	{
		if(IsClientInGame(c) && GetClientTeam(c) == 3)
		{
			PrintToChat(c, "[ZR] Your armor has been refilled!");
			SetEntProp(c, Prop_Send, "m_ArmorValue", 100);
			SetEntProp(c, Prop_Send, "m_bHasHelmet", 1);
		}
	}
}