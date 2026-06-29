#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <cstrike>

new bool:respawn;

public Plugin:myinfo = 
{
	name = "New Plugin",
	author = "Unknown",
	description = "<- Description ->",
	version = "1.0",
	url = "<- URL ->"
}

public OnPluginStart()
{
	HookEvent("round_end", RoundEndEvent, EventHookMode_Pre);
	AddCommandListener(Command_JoinTeam, "jointeam");
}

public OnMapStart()
{
    respawn = false;
}

public RoundEndEvent(Handle: event , const String: name[] , bool: dontBroadcast)
{
	if(!respawn)
	{
		respawn = true;
	}
}

public Action:Command_JoinTeam(client, const String:command[], argc)
{
	if(client != 0 && !respawn)
    {        
		decl String:TeamNum[5];
        GetCmdArgString(TeamNum, sizeof(TeamNum));
        new team = StringToInt(TeamNum);
		
		if(team == CS_TEAM_T)
        {
			ChangeClientTeam(client, CS_TEAM_CT);
			return Plugin_Handled;
        }
		else if(team == CS_TEAM_CT)
		{
			ChangeClientTeam(client, CS_TEAM_T);
			return Plugin_Handled;
		}
    }
    return Plugin_Continue;
}