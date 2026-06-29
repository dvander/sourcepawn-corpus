#pragma semicolon 1

#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>

#define DMG_FALL   (1 << 5)

public Plugin:myinfo = 
{
	name = "[CS:S/CS:GO] No Fall Damage",
	author = "alexip121093 & Neoxx",
	description = "No Falling Damage & No Fall Damage Sound",
	version = "1.0",
	url = "www.sourcemod.net"
}

public OnPluginStart() AddNormalSoundHook(SoundHook);

public Action:SoundHook(clients[64], &numClients, String:sound[PLATFORM_MAX_PATH], &Ent, &channel, &Float:volume, &level, &pitch, &flags)
{
    if ((StrEqual(sound, "player/damage1.wav", false) || StrEqual(sound, "player/damage2.wav", false) || StrEqual(sound, "player/damage3.wav", false)) && GetClientTeam(Ent) == CS_TEAM_T) return Plugin_Stop;
    return Plugin_Continue;
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:OnTakeDamage(client, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (damagetype & DMG_FALL && GetClientTeam(client) == CS_TEAM_T)
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
