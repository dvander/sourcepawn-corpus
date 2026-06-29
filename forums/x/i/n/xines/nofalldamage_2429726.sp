#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>

#define DMG_FALL   (1 << 5)

public Plugin myinfo = 
{
	name = "[CS:S/CS:GO] No Fall Damage",
	author = "alexip121093 & Neoxx",
	description = "No Falling Damage & No Fall Damage Sound",
	version = "1.0",
	url = "www.sourcemod.net"
}

public void OnPluginStart() {AddNormalSoundHook(SoundHook);}
public void OnClientPostAdminCheck(int client) {SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);}

public Action SoundHook(int clients[64], int &numClients, char sound[PLATFORM_MAX_PATH], int &Ent, int &channel, float &volume, int &level, int &pitch, int &flags)
{
	if(Ent > 0 && Ent <= MaxClients && IsClientInGame(Ent) && GetClientTeam(Ent) == CS_TEAM_T)
		for (int i = 1; i < 3; i++) {
			if(StrEqual(sound, "player/damage%i.wav", false), i) return Plugin_Stop;
		}
	return Plugin_Continue;
}

public Action OnTakeDamage(int client, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (damagetype & DMG_FALL && GetClientTeam(client) == CS_TEAM_T) {return Plugin_Handled;}
	return Plugin_Continue;
}