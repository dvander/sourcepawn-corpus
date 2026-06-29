#pragma semicolon 1
#define PLUGIN_VERSION "1.1"
#include <sourcemod>
#include <sdktools>

new Handle:g_hTimelimit = INVALID_HANDLE; //handle to get cvar
new g_iTimeLeft;		//saved time left before it resets

new g_iNumT = 0;
new g_iNumCT = 0;
new g_iRestoreInProgress = 0;	//safe check against restoring map time left during a restore (when it has been reset already by the map)

public Plugin:myinfo =
{
	name = "TOG Timeleft",
	author = "That One Guy",
	description = "Restores remaining map time after a player joins an empty team (which causes a round draw and map restart.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net"
}

public OnPluginStart()
{
	CreateConVar("togtimeleft_version", PLUGIN_VERSION, "TOG Timeleft: Version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AddCommandListener(Command_JoinTeam, "jointeam");
}

public Action:Command_JoinTeam(client, const String:command[], argc) 
{
	CountTeamPlayers();
	
	//this is called before they change team, so no round draw will occur if both teams already have players
	if((g_iNumT > 0) && (g_iNumCT > 0))
	{
		return Plugin_Continue;
	}
	
	decl String:sNewTeam[3];
	GetCmdArg(1, sNewTeam, sizeof(sNewTeam));
	new iNewTeam = StringToInt(sNewTeam);
	
	if(((iNewTeam == 2) && (g_iNumT == 0)) || ((iNewTeam == 3) && (g_iNumCT == 0)))
	{
		if(!g_iRestoreInProgress)
		{
			GetMapTimeLeft(g_iTimeLeft);
			g_iTimeLeft = RoundToCeil(float(g_iTimeLeft)/60);
			PrintToChatAll("[TOG Timeleft] Round draw is about to occur! Map time will be restored to %i minutes, if it changes.", g_iTimeLeft);
			if(g_iTimeLeft < 2) //if less than a minute, it reads it as 0, thus sets timeleft to 0 (infinity). This overrides that.
			{
				if(g_iTimeLeft == 0) //assume it is a glitch, and set it to 15.
				{
					g_iTimeLeft = 15;
				}
				else //1-2 minutes left gets set to 1
				{
					g_iTimeLeft = 1;
				}
			}
			g_iRestoreInProgress = 1; //toggle this so that it doesnt try to restore during a restore.
			CreateTimer(8.0, ReSetMapTimeLeft_TimerMonitor, _, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	return Plugin_Continue;
}

CountTeamPlayers()
{
	//reset count
	g_iNumT = 0;
	g_iNumCT = 0;
	
	//count players
	for(new i = 1; i <= MaxClients; i++)
	{	
		if(IsValidClient(i))
		{
			if(!IsFakeClient(i))
			{
				if(GetClientTeam(i) == 2)
				{
					g_iNumT++;
				}
				if(GetClientTeam(i) == 3)
				{
					g_iNumCT++;
				}
			}
		}
		continue;
	}
}

public Action:ReSetMapTimeLeft_TimerMonitor(Handle:timer)
{
	new iTimeLeft;
	GetMapTimeLeft(iTimeLeft);
	iTimeLeft = RoundToCeil(float(iTimeLeft)/60);
	if((iTimeLeft - g_iTimeLeft) > 2)
	{
		g_hTimelimit = FindConVar("mp_timelimit");
		SetConVarInt(g_hTimelimit, g_iTimeLeft);
		PrintToChatAll("[TOG Timeleft] Map time left has been restored to %i minutes!", g_iTimeLeft);
		g_iRestoreInProgress = 0;
	}
	return Plugin_Continue;
}

bool:IsValidClient(client)
{
	if (!(1 <= client <= MaxClients) || !IsClientInGame(client) || IsFakeClient(client))
	{
		return false;
	}
	return true;
}