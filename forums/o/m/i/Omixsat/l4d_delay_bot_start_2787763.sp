#include <sourcemod>
#define TEAM_SURVIVOR 2
#pragma semicolon 1;                // Force strict semicolon mode.
#pragma newdecls required;			// Force new style syntax.

public Plugin myinfo =
{
	name = "[L4D] Delay Bots Starting Game",
	author = "Mortiegama, Thraka, mi123645, Omixsat",
	description = "Prevents bots from leaving the safe room via sb_all_bot_team until a survivor has loaded or until l4d_sb_stop_time has passed",
	version = "1.2",
	url = "https://forums.alliedmods.net/showpost.php?p=1111338"
};

bool TimerActive = false;
ConVar sb_stop_time;
int TimerLengthCurrent = 0;
int TimerLengthMax = 0;

public void OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart);
	sb_stop_time = CreateConVar("l4d_sb_stop_time", "30", "How long should the bots stay idle before moving out of the safe room", FCVAR_NOTIFY|FCVAR_SPONLY);

	AutoExecConfig(true, "l4d_delay_bot_start");
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if (TimerActive == false && IsAnyClientSurvivor() == false)
	{
		TimerLengthCurrent = 0;
		SetConVarInt(FindConVar("sb_stop"), 1);
		TimerActive = true;
		TimerLengthMax = sb_stop_time.IntValue;
		CreateTimer(1.0, Timer_CheckForHumanSurvivor, _,TIMER_REPEAT);
	}
}

public Action Timer_CheckForHumanSurvivor(Handle timer)
{
	TimerLengthCurrent++;

	if (TimerLengthCurrent > TimerLengthMax || IsAnyClientSurvivor())
	{
		TimerActive = false;
		KillTimer(timer);
		SetConVarInt(FindConVar("sb_stop"), 0);
	}
}

public bool IsAnyClientSurvivor()
{
	for (int i = 1; i <= MaxClients; i++)
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