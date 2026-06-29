#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#pragma semicolon 1

new Handle:g_Cvar_MaxZKnock = INVALID_HANDLE;
new Handle:g_Cvar_HeKnock = INVALID_HANDLE;

public Plugin:myinfo ={
	name = "Z:R Grenade Boost",
	author = "Marica Stevens",
	description = "Pushes zombies upwards when hit by a grenade.",
	version = "1.0.0",
	url = "http://maricascripters.com"
};

public OnPluginStart()
{
	g_Cvar_MaxZKnock = CreateConVar("sm_max_zknock", "32.0", "Knock in Z");
	g_Cvar_HeKnock = CreateConVar("sm_he_knock", "320.0", "Max Knock in Z");
	HookEvent("player_hurt", Event_HandleNadeDamage); 
}

public OnPluginEnd()
{ 	
	UnhookEvent("player_hurt", Event_HandleNadeDamage); 
}

public Event_HandleNadeDamage(Handle:event, const String:name[], bool:dontBroadcast)
{ 
	new clientid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(clientid);
	new damage = GetEventInt(event,"dmg_health");
	decl String:weapon[32];
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	if(GetClientTeam(client)==2 && StrEqual("hegrenade", weapon))
	{
		new Float:vector[3];
		vector[0] = 0.0;
		vector[1] = 0.0;
		vector[2] = GetConVarFloat(g_Cvar_HeKnock)*damage;
		
		if(vector[2]> GetConVarFloat(g_Cvar_MaxZKnock))
		{
			vector[2] = GetConVarFloat(g_Cvar_MaxZKnock);
		}
		new g_iBaseVelocityOffset = FindSendPropOffs("CBasePlayer","m_vecBaseVelocity");
		SetEntDataVector(client, g_iBaseVelocityOffset, vector, true);
	}
}