#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.2.2"

#define TEAM_UNASSIGNED 0
#define TEAM_SPECTATE 1
#define TEAM_SURVIVORS 2
#define TEAM_INFECTED 3

public Plugin:myinfo =
{
	name = "Team Change Manager",
	author = "Sheepdude",
	description = "Provides Management To Team Changes.",
	version = PLUGIN_VERSION,
	url = "http://www.clan-psycho.com"
};

new Handle:h_cvarVersion;

public OnPluginStart() 
{
	AddCommandListener(JoinTeamCmd, "jointeam");
	
	h_cvarVersion = CreateConVar("team_change_manager_version", PLUGIN_VERSION, "Team Change Manager Version", FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_SPONLY);
	HookConVarChange(h_cvarVersion, OnConvarChanged);
	
	AutoExecConfig(true, "team_change_manager");
}

public Action:JoinTeamCmd(client, const String:command[], argc)
{ 
	if (!IsValidClient(client) || argc < 1)
	{
		return Plugin_Handled;
	}
	
	decl String:arg[4];
	GetCmdArg(1, arg, sizeof(arg));
	new toteam = StringToInt(arg);
	if (toteam == TEAM_SURVIVORS)
	{
		if (GetClientTeam(client) == TEAM_SURVIVORS)
		{
			PrintHintText(client, "[JBTP] Already In Survivors Team!");
		}
		else
		{
			if (GetEntProp(client, Prop_Send, "m_iObserverMode") == 5)
			{
				return Plugin_Handled;
			}
			else
			{
				if (GetTotalPlayers(TEAM_SURVIVORS) == GetTotalPlayers(TEAM_INFECTED))
				{
					if (GetTotalPlayers(TEAM_SURVIVORS) == 0 && GetTotalPlayers(TEAM_INFECTED) == 0)
					{
						PrintToChatAll("\x03[JBTP] \x04%N\x01 Joined \x05Survivors Team\x01!", client);
						
						new aBot = FindAvailableBot();
						if (aBot != -1)
						{
							new flags = GetCommandFlags("sb_takecontrol");
							SetCommandFlags("sb_takecontrol", flags & ~FCVAR_CHEAT);
							FakeClientCommand(client, "sb_takecontrol");
							SetCommandFlags("sb_takecontrol", flags);
						}
					}
					else
					{
						PrintHintText(client, "[JBTP] Teams Are Balanced!");
					}
				}
				else if (GetTotalPlayers(TEAM_SURVIVORS) > GetTotalPlayers(TEAM_INFECTED))
				{
					PrintHintText(client, "[JBTP] That's Unfair!");
				}
				else
				{
					PrintToChatAll("\x03[JBTP] \x04%N\x01 Joined \x05Survivors Team\x01!", client);
					
					new aBot = FindAvailableBot();
					if (aBot != -1)
					{
						new flags = GetCommandFlags("sb_takecontrol");
						SetCommandFlags("sb_takecontrol", flags & ~FCVAR_CHEAT);
						FakeClientCommand(client, "sb_takecontrol");
						SetCommandFlags("sb_takecontrol", flags);
					}
				}
			}
			return Plugin_Handled;
			}
	}
	else if (toteam == TEAM_INFECTED)
	{
		if (GetClientTeam(client) == TEAM_INFECTED)
		{
			PrintHintText(client, "[JBTP] Already In Infected Team!");
		}
		else
		{
			if (GetTotalPlayers(TEAM_SURVIVORS) == GetTotalPlayers(TEAM_INFECTED))
			{
				if (GetTotalPlayers(TEAM_INFECTED) == 0 && GetTotalPlayers(TEAM_SURVIVORS) == 0)
				{
					ChangeClientTeam(client, TEAM_INFECTED);
					PrintToChatAll("\x03[JBTP] \x04%N\x01 Joined \x05Infected Team\x01!", client);
				}
				else
				{
					PrintHintText(client, "[JBTP] Teams Are Balanced!");
				}
			}
			else if (GetTotalPlayers(TEAM_SURVIVORS) < GetTotalPlayers(TEAM_INFECTED))
			{
				PrintHintText(client, "[JBTP] That's Unfair!");
			}
			else
			{
				ChangeClientTeam(client, TEAM_INFECTED);
				PrintToChatAll("\x03[JBTP] \x04%N\x01 Joined \x05Infected Team\x01!", client);
			}
		}
		return Plugin_Handled;
	}
	else if (toteam == TEAM_SPECTATE)
	{
		if (GetClientTeam(client) == TEAM_SPECTATE)
		{
			PrintHintText(client, "[JBTP] Already In Spectators Team!");
		}
		else
		{
			ChangeClientTeam(client, TEAM_SPECTATE);
		}
		return Plugin_Handled;
	}
	
	return Plugin_Handled;
}

GetTotalPlayers(selectedTeam)
{
	new total = 0;
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == selectedTeam && !IsFakeClient(i))
		{
			total++;
		}
	}
	if (total < 1)
	{
		return 0;
	}
	
	return total;
}

public OnConvarChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if (cvar == h_cvarVersion)
	{
		ResetConVar(h_cvarVersion);
	}
}

stock IsValidClient(client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client))
	{
		return true;
	}
	return false;
}

stock FindAvailableBot()
{
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && GetClientTeam(client) == TEAM_SURVIVORS && IsFakeClient(client))
		{
			return client;
		}
	}
	return -1;
}

