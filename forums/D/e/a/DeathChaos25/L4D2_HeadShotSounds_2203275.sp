#include <sourcemod>
#include <sdktools>

#define SOUND_HEADSHOT		"UI/LittleReward.wav"

public Plugin:myinfo = { 
	name        = "[L4D2] Headshot sounds", 
	author        = "DeathChaos25", 
	description    = "Players will hear a sound when they perform a Headshot", 
	version        = "1.0", 
	url        = "https://forums.alliedmods.net/showthread.php?t=248751" 
}

public OnPluginStart()
{
	HookEvent("player_death", PlayerDeath_Event) 
	HookEvent("infected_death", InfectedDeath_Event) 
	HookEvent("hunter_headshot", HunterHeadshot_Event) 
}

public OnMapStart()
{
	PrecacheSound(SOUND_HEADSHOT) 
}
public PlayerDeath_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "attacker")) 
	new bool:IsHeadshot = GetEventBool(event, "headshot") 
	if (IsSurvivor(client) && IsHeadshot == true) {
		PlaySound(client, SOUND_HEADSHOT)
	}
}

public InfectedDeath_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "attacker")) 
	new bool:IsHeadshot = GetEventBool(event, "headshot") 
	
	if (IsSurvivor(client) && IsHeadshot == true) {
		PlaySound(client, SOUND_HEADSHOT)
	}
}

public HunterHeadshot_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid")) 
	
	if (IsSurvivor(client)) {
		PlaySound(client, SOUND_HEADSHOT)
	}
}

stock bool:IsSurvivor(client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2)
	{
		return true;
	}
	return false;
}

/* Taken from Gear Transfer, credits to SilverShot for that*/
stock PlaySound(client, const String:s_Sound[32]) {
	EmitSoundToClient(client, s_Sound, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0) 
}
