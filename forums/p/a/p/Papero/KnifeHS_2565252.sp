#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_AUTHOR         "Hexah"
#define PLUGIN_VERSION        "1.0"

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
	name = "KnifeHS",
	author = PLUGIN_AUTHOR,
	description = "",
	version = PLUGIN_VERSION,
	url = "csitajb.it"
};

public void OnPluginStart()
{
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	char sWeapon[32];
	event.GetString("weapon", sWeapon, sizeof(sWeapon)); //Get weapon name
	
	if (StrContains(sWeapon, "knife", false) != -1) //If the weapon isn't a knife
		return Plugin_Continue;
		
	int client = GetClientOfUserId(event.GetInt("attacker")); //Get client index
	
	float vPos[3];
	float vAng[3];
	
	GetClientAbsOrigin(client, vAng);
	GetClientAbsAngles(client, vAng);
	TR_TraceRayFilter(vPos, vAng, MASK_SHOT, RayType_Infinite, Trace_DontHitSelf, client); //Start the trace
	
	int iHitGroup = TR_GetHitGroup(); //Get the hit group
	
	if (iHitGroup == 1) //Not sure if '1' for it's okay. (For HS hitgroup)
	{
		event.SetBool("headshot", true);
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public bool Trace_DontHitSelf(int entity, int contentsMask, any data)
{
	return entity != data;
}

