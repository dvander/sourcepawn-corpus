#include <sourcemod>
#define TEAM_SURVIVOR 2

public Plugin:myinfo = 
{
	name = "[L4D] Delay Bots Starting Game",
	author = "Mortiegama, Thraka, mi123645",
	description = "Prevents bots from leaving the safe room via sb_all_bot_team until a survivor has loaded (or 20 seconds goes by)",
	version = "1.0",
	url = "http://forums.alliedmods.net/showthread.php?p=1107614"
}

new TimerLengthMax = 20;
new TimerLengthCurrent = 0;

public OnMapStart()
{
	CreateTimer(1.0, Timer_CheckForHumanSurvivor, _,TIMER_REPEAT);
	SetConVarInt(FindConVar("sb_stop"), 1);
}

public Action:Timer_CheckForHumanSurvivor(Handle:timer)
{
	TimerLengthCurrent++;
	new bool:shutdownTimer = false;
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			if (GetClientTeam(i) == TEAM_SURVIVOR)
			{
				shutdownTimer = true;
				break;

			}
		}
	}
	
	if (TimerLengthCurrent > TimerLengthMax || shutdownTimer)
	{
		KillTimer(timer);
		TimerLengthCurrent = 0;
		SetConVarInt(FindConVar("sb_stop"), 0);
	}
}