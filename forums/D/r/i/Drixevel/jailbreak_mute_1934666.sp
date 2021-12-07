#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
//#include <basecomm>
#include <tf2>

public Plugin:myinfo =
{
	name        = "[TF2] Jailbreak Auto-Mute",
	author      = "Dr. McKay",
	description = "https://forums.alliedmods.net/showthread.php?t=212566",
	version     = "1.0.1",
	url         = "http://www.doctormckay.com"
};

new Handle:cvarMuteTime;
new Handle:checkTimer;
new muteTime;

public OnPluginStart()
{
	cvarMuteTime = CreateConVar("jailbreak_automute_time", "30", "Time to mute everyone on RED for at the start of the round");
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("arena_round_start", Event_RoundStart);
	HookEvent("teamplay_round_start", Event_RoundStart);
	HookEvent("teamplay_round_win", Event_RoundEnd);
	HookEvent("teamplay_round_stalemate", Event_RoundEnd);
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	muteTime = GetConVarInt(cvarMuteTime);
	checkTimer = CreateTimer(1.0, Timer_CheckMute, _, TIMER_REPEAT);
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i))
		{
			continue;
		}
		if(CheckCommandAccess(i, "NoJailbreakMute", ADMFLAG_RESERVATION))
		{
			continue; // immune
		}
		if(TFTeam:GetClientTeam(i) == TFTeam_Red)
		{
			MutePlayer(i);
		}
	}
}

public Action:Timer_CheckMute(Handle:timer)
{
	muteTime--;
	if(muteTime <= 0)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(!IsClientInGame(i))
			{
				continue;
			}
			if(TFTeam:GetClientTeam(i) == TFTeam_Red)
			{
				UnmutePlayer(i);
			}
		}
		checkTimer = INVALID_HANDLE;
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(muteTime > 0 && TFTeam:GetClientTeam(client) == TFTeam_Red)
	{
		MutePlayer(client);
		return; // Timer hasn't expired yet
	}
	
	UnmutePlayer(client); // Unmute
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(!CheckCommandAccess(client, "NoJailbreakMute", ADMFLAG_RESERVATION))
	{
		MutePlayer(client);
	}
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			UnmutePlayer(i);
		}
	}
	if(checkTimer != INVALID_HANDLE)
	{
		CloseHandle(checkTimer);
		checkTimer = INVALID_HANDLE;
	}
}

stock MutePlayer(client)
{
	SetClientListeningFlags(client, VOICE_MUTED);
}

stock UnmutePlayer(client)
{
	SetClientListeningFlags(client, VOICE_NORMAL);
}