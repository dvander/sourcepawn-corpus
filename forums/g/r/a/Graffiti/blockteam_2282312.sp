#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>

#define VERSION "1.0"

new GoodTeam = -1;
new BadTeam = -1;

public Plugin:myinfo =
{
    name = "Block Team for course maps",
    author = "Graffiti",
    description = "",
    version = VERSION,
    url = ""
};


public OnPluginStart()
{
	CreateConVar("sm_block_team_version", VERSION, "Block Team for course maps", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);
	
	HookEvent("player_team",Event_PlayerTeamSwitch,EventHookMode_Pre);
	HookEvent("jointeam_failed", Event_JoinTeamFailed, EventHookMode_Pre);
	AddCommandListener(Command_JoinTeam, "jointeam");
}

public OnConfigsExecuted()
{
	Parse_MapConfig();
}

public Action:Event_PlayerTeamSwitch(Handle:event, const String:name[], bool:dontBroadcast)
{
	new NewTeam = GetEventInt(event, "team");
	new OldTeam = GetEventInt(event, "oldteam");
	new clientID = GetClientOfUserId(GetEventInt(event, "userid"));
	if (GoodTeam != -1) 
	{
	   if ((OldTeam == CS_TEAM_NONE || OldTeam == CS_TEAM_SPECTATOR) && NewTeam == BadTeam)
	   {
			CreateTimer(0.0, Timer_SwapFirstJoin, clientID);
			return Plugin_Handled;
	   }
	   else if (OldTeam == GoodTeam && NewTeam == BadTeam)
	   {
			return Plugin_Handled;
	   }
	}
	return Plugin_Continue;
}

public Action:Event_JoinTeamFailed(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GoodTeam != -1) 
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(!client || !IsClientInGame(client))
			return Plugin_Continue;

		ChangeClientTeam(client, GoodTeam);
		return Plugin_Handled;
	}

	return Plugin_Continue;
	
}

public Action:Command_JoinTeam(client, const String:command[], args)
{
	if(!client || !IsClientInGame(client) || IsFakeClient(client))
	{
		return Plugin_Continue;
	}
	if (GoodTeam != -1) 
	{
		// Get the target team
		decl String:teamString[3];
		GetCmdArg(1, teamString, sizeof(teamString));
		new Target_Team = StringToInt(teamString);
		// Get the players current team
		new Current_Team = GetClientTeam(client);
		
		if (Current_Team == Target_Team)
		{
			return Plugin_Handled;
		}
		
		if (Current_Team == BadTeam && Target_Team == GoodTeam)
		{
			ForcePlayerSuicide(client);
			return Plugin_Continue;
		}
		
		if (Current_Team == GoodTeam && Target_Team == BadTeam)
		{
			return Plugin_Handled;
		}
		
		if (!((Target_Team == GoodTeam) || (Target_Team == BadTeam) || (Target_Team == CS_TEAM_SPECTATOR)))
		{	
			CS_SwitchTeam(client, GoodTeam);
			ForcePlayerSuicide(client);
			return Plugin_Handled;	
		}
	}
	
	return Plugin_Continue;

}

public Action:Timer_SwapFirstJoin(Handle:timer, any:client)
{
	if (client)
	{
		CS_SwitchTeam(client, GoodTeam);
		ForcePlayerSuicide(client);
	}
	return Plugin_Stop;
}


Parse_MapConfig()
{
	new Handle:hConfig = CreateKeyValues("BlockTeam_MapConfig");
	new String:sConfig[PLATFORM_MAX_PATH];
	new String:sMapName[128];
	GetCurrentMap(sMapName, sizeof(sMapName));

	BuildPath(Path_SM, sConfig, sizeof(sConfig), "configs/BlockTeam_MapConfig.cfg");

	if (FileToKeyValues(hConfig, sConfig))
	{
		if (KvJumpToKey(hConfig, sMapName))
		{
			GoodTeam = KvGetNum(hConfig, "GoodTeam", -1);
			if (GoodTeam == 2) BadTeam=3;
			else if (GoodTeam == 3) BadTeam=2;
			else BadTeam = -1;
		}
		else
		{
			GoodTeam = -1;
		}
	}
	else
	{
		GoodTeam = -1;
	}
	
	CloseHandle(hConfig);
}