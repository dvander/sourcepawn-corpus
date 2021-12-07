#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

#define SOUND "music/headshotsound.mp3"

public Plugin myinfo =
{
	name = "SM Show iDamage as Fortnite",
	author = "Franc1sco Steam: franug",
	description = "",
	version = "1.0",
	url = "http://steamcommunity.com/id/franug"
};

public void OnPluginStart()
{
	HookEvent("player_hurt", Event_PlayerHurt);
}

/* uncomment for use sound

public void OnMapStart()
{
	PrecacheSound(SOUND);
	
	char temp[128];
	Format(temp, sizeof(temp), "sound/%s", SOUND);
	
	AddFileToDownloadsTable(temp);
}

*/

public Action Event_PlayerHurt(Handle event, const char[] name, bool dontBroadcast)
{	
	int iAttacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	int iVictim = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(iVictim == iAttacker || iAttacker < 1 || iAttacker > MaxClients || !IsClientInGame(iAttacker) || IsFakeClient(iAttacker)) // check Attacker
		return;

	int iDamage = GetEventInt(event, "dmg_health"); 
	int iHitgroup = GetEventInt(event, "hitgroup");
	
	if(iHitgroup == 1) // headshot
	{
		SetHudTextParams(-1.0, 0.45, 2.0, 255, 117, 20, 200, 1); // orange
		
		// EmitSoundToClient(iAttacker, SOUND); // emit sound
	}
	else
	{
		SetHudTextParams(-1.0, 0.45, 2.0, 255, 0, 0, 200, 1); // red
	}
	
	ShowHudText(iAttacker, 5, "%i", iDamage); // same channel for prevent overlap
}