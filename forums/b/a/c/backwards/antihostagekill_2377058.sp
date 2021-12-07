#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = 
{
	name = "AntiHostageKill",
	author = "shuter",
	description = "Prevents Hostages From Taking Damage.",
	version = "1.0",
	url = "http://steamcommunity.com/id/Evgshuter"
};

public OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart);
}

public Event_RoundStart( Handle:Death_Event, const String:Death_Name[], bool:Death_Broadcast )
{
	GodModeHostages();
}

GodModeHostages()
{
	new maxEnt = GetMaxEntities();
	decl String:sClassName[64];
	for (new i = MaxClients; i < maxEnt; i++)
		if (IsValidEdict(i) && IsValidEntity(i) && GetEdictClassname(i, sClassName, sizeof(sClassName)))
			if (StrEqual(sClassName, "hostage_entity"))
				SetEntProp(i, Prop_Data, "m_takedamage", 1);
}