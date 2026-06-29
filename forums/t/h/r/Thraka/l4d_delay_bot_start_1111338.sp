#include <sourcemod>
#define TEAM_SURVIVOR 2

public Plugin:myinfo = 
{
	name = "[L4D] Delay Bots Starting Game",
	author = "Mortiegama, Thraka, mi123645",
	description = "Prevents bots from leaving the safe room via sb_all_bot_team until a survivor has loaded (or 20 seconds goes by)",
	version = "1.1",
	url = "http://forums.alliedmods.net/showthread.php?p=1107614"
}

new TimerLengthMax = 20;
new TimerLengthCurrent = 0;
new bool:TimerActive = false;

public OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart);
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (TimerActive == false && IsAnyClientSurvivor() == false)
	{
		TimerLengthCurrent = 0;
		SetConVarInt(FindConVar("sb_stop"), 1);
		TimerActive = true;
		CreateTimer(1.0, Timer_CheckForHumanSurvivor, _,TIMER_REPEAT);
	}
}

public Action:Timer_CheckForHumanSurvivor(Handle:timer)
{
	TimerLengthCurrent++;

	if (TimerLengthCurrent > TimerLengthMax || IsAnyClientSurvivor())
	{
		TimerActive = false;
		KillTimer(timer);
		SetConVarInt(FindConVar("sb_stop"), 0);
	}
}

public bool:IsAnyClientSurvivor()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			if (GetClientTeam(i) == TEAM_SURVIVOR)
			{
				return true;
			}
		}
	}
	
	return false;
}