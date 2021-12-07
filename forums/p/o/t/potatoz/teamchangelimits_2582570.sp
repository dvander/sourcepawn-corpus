#pragma semicolon 1
#include <sourcemod>

#define VERSION "1.0"

int teamchangecount[MAXPLAYERS+1];
ConVar cvar_teamchangelimit,
	cvar_excludespec;

public Plugin:myinfo =
{
	name = "Team Change Limit",
	author = "Potatoz",
	description = "Limits the times of which a player can change team",
	version = VERSION,
	url = ""
};

public OnPluginStart()
{
	cvar_teamchangelimit = CreateConVar("sm_teamchange_limit", "1", "Sets how many times a player may switch between teams. Default = 1");
	cvar_excludespec = CreateConVar("sm_teamchange_excludespec", "1", "Should we exclude counting team changes to spectators? 0 = Disable");
	
	AddCommandListener(OnJoinTeam, "jointeam");
}

public OnClientPutInServer(int client) 
{
	if(!IsFakeClient(client) && IsClientInGame(client))
		teamchangecount[client] = 0;
}

public Action OnJoinTeam(int client, char[] commands, int args)
{
	if(!IsClientInGame(client) || IsFakeClient(client))
		return Plugin_Continue;
		
	if(teamchangecount[client] == cvar_teamchangelimit.IntValue)
	{
		PrintToChat(client, "[SM] You have reached the limit for amount of times which you may switch teams.");
		return Plugin_Handled;
	}
		
	char arg1[3];
	GetCmdArg(1, arg1, sizeof(arg1));
	new target_team = StringToInt(arg1);
	new current_team = GetClientTeam(client);
	
	if(target_team == current_team)
		return Plugin_Handled;
	else if(target_team > 1 && cvar_excludespec.IntValue >= 1)
		teamchangecount[client]++;
	else if(cvar_excludespec.IntValue < 1)
		teamchangecount[client]++;
	
	return Plugin_Continue;
}