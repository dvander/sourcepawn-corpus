// Code based on https://forums.alliedmods.net/showthread.php?p=1767585

#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <clientprefs>

#define VERSION "1.0"

new TotalTime[MAXPLAYERS+1];
new iTeam[MAXPLAYERS+1];

new Handle:c_GameTime = INVALID_HANDLE;

new Handle:cvar_needed = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "Jailbreak - CT Restriction by PlayTime",
	author = "Franc1sco franug",
	description = "",
	version = VERSION,
	url = "http://steamcommunity.com/id/franug"
}

public OnPluginStart()
{
	c_GameTime = 	RegClientCookie("PlayTimeT", 	"PlayTimeT", CookieAccess_Private);
	CreateTimer(1.0, CheckTime, _, TIMER_REPEAT);
	
	cvar_needed = CreateConVar("sm_terroristplaytime_needed", "60", "Time in minutes needed in Ts team for play in the CT team");
	
	HookEvent("player_team", Event_Team);
	HookEvent("player_spawn", Event_Spawn);
	
	CreateConVar("jailbreakctrestriction_version", VERSION, "Version", FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_CHEAT);	
	for(new client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			iTeam[client] = GetClientTeam(client);
			if(AreClientCookiesCached(client))
			{
				OnClientCookiesCached(client);
			}
		}
		else
		{
			iTeam[client] = 0;
		}
	}
}
public OnPluginEnd()
{
	for(new client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			OnClientDisconnect(client);
		}
	}
}

public Action:Event_Team(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	iTeam[client] = GetEventInt(event, "team");
}

public Action:Event_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (GetUserAdmin(client) != INVALID_ADMIN_ID)return;
	
	if (iTeam[client] != CS_TEAM_CT) return;
	
	if (TotalTime[client] >= (GetConVarInt(cvar_needed) * 60))return;
		
	ChangeClientTeam(client, CS_TEAM_T);
	PrintToChat(client, "You need more time played in Terrorist team for join to CT team.");
}

public Action:CheckTime(Handle:timer)
{
	for(new client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			if(iTeam[client] == CS_TEAM_T)
			{
				TotalTime[client]++;
				//PrintToChat(client, "Total Time: %i", TotalTime[client]);
			}
		}
	}
	return Plugin_Continue;
}
public OnClientCookiesCached(client)
{
	new String:TimeString[12]; //Big number, i know this is just incase people play for a year total.
	GetClientCookie(client, c_GameTime, TimeString, sizeof(TimeString));
	TotalTime[client]  = StringToInt(TimeString);
}
public OnClientDisconnect(client)
{
	if(AreClientCookiesCached(client))
	{
		new String:TimeString[12];
		Format(TimeString, sizeof(TimeString), "%i", TotalTime[client]);
		SetClientCookie(client, c_GameTime, TimeString);
	}
}