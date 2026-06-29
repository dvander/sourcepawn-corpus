#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define PL_VERSION   "1.1"
#define TEAM_S 1
#define TEAM_1 2
#define TEAM_2 3
#define PLUGIN_TAG   "[DoD status2]"

char clientTeam[][10] = { "Allied", "Axis   ", "Other   "};

public Plugin myinfo = 
{
	name        = "DoD Status 2",
	author      = "Micmacx",
	description = "Status with k/d an Team",
	version     = PL_VERSION,
	url         = "https://dods.neyone.fr"
}

public void OnPluginStart()
{
	CreateConVar("dod_status_2", PL_VERSION, "DoD Balancer Skill", FCVAR_DONTRECORD|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegAdminCmd("sm_status2", Status2, ADMFLAG_GENERIC);
}

public Action Status2(int client, int args)
{
	if (!client)
		return Plugin_Handled;

	Aff_Status2(client);

	return Plugin_Handled;
}

public void Aff_Status2(int client)
{
	char message[300];
	Format(message, sizeof(message), "———————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————");
	PrintToConsole(client, message);
	Format(message, sizeof(message), "# userid| Team		| SteamID		| kill	| Death	| ip			| Playername			");
	PrintToConsole(client, message);
	Format(message, sizeof(message), "———————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————");
	PrintToConsole(client, message);
	for(int i = 1; i <= MaxClients; i++)
	{
		if(ValidPlayer(i) && !IsFakeClient(i)) 
		{
			int index = GetClientUserId(i);

			char clientName[64];
			GetClientName(i, clientName, sizeof(clientName));
			
			char steamid[256];
			GetClientAuthId(i, AuthId_Steam3, steamid, sizeof(steamid));

			int kills = GetEntProp(i, Prop_Data, "m_iFrags");

			int deaths = GetEntProp(i, Prop_Data, "m_iDeaths");
			
			char ip[15];
			GetClientIP(i, ip, sizeof(ip));
			
			Format(message, sizeof(message), "#%i	| %s	| %s	| %i	| %i	| %s	| %s			", index, clientTeam[GetPlayerTeam(i)], steamid, kills, deaths, ip, clientName);
			PrintToConsole(client, message);
			Format(message, sizeof(message), "———————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————");
			PrintToConsole(client, message);
			
		}
	}
	Format(message, sizeof(message), "———————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————");
	PrintToConsole(client, message);
}

stock int GetPlayerTeam(int client)
{
	if(ValidPlayer(client))
	{
		if(GetClientTeam(client) == TEAM_1)
		{
			return 0;
		}
		else
		{
			if(GetClientTeam(client) == TEAM_2)
			{
				return 1;
			}
			else 
			{
				return 2;
			}
		}
	}
	return 2;
}

stock bool ValidPlayer(int client, bool check_alive = false)
{
	if(client > 0 && client <= MaxClients && IsClientInGame(client))
	{
		return true;
	}
	return false;
}