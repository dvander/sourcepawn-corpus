#pragma semicolon 1

#include <morecolors>

#define PLUGIN_VERSION "1.2"

new Handle:cvarEnabled;
new bool:gEnabled;

public Plugin:myinfo =
{
	name = "[TF2] Improved Join Team Messages",
	author = "Oshizu",
	description = "Improves messages that appear when player joins team.",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net",
}

public OnPluginStart()
{
	CreateConVar("sm_jointeam_version", PLUGIN_VERSION, "Improved Join Team Messages Version", FCVAR_REPLICATED | FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);
	
	cvarEnabled = CreateConVar("sm_jointeam_enabled", "1", "Enable Improved Join Team Messages", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	gEnabled = GetConVarBool(cvarEnabled);
	
	HookConVarChange(cvarEnabled, CVarChange);

	HookEvent("player_team", Event_PlayerTeam, EventHookMode_Pre);
}

public CVarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(convar == cvarEnabled) gEnabled = GetConVarBool(cvarEnabled);
}

public Action:Event_PlayerTeam(Handle:event, const String:szEventName[], bool:bDontBroadcast)
{
	if(!gEnabled) return Plugin_Continue;

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!IsValidClient(client)) return Plugin_Continue;

	new oldteam = GetEventInt(event, "oldteam");
	new newteam = GetEventInt(event, "team");

	SetEventBroadcast(event, true);

	switch(oldteam)
	{
		case 0, 1:
		{
			switch(newteam)
			{
				case 0: CPrintToChatAll("Player {gray}%N joined team unassigned", client);
				case 1: CPrintToChatAll("Player {gray}%N{DEFAULT} joined team {gray}Spectator", client);
				case 2: CPrintToChatAll("Player {gray}%N{DEFAULT} joined team {red}Red", client);
				case 3: CPrintToChatAll("Player {gray}%N{DEFAULT} joined team {blue}Blu", client);
			}
		}
		case 2:
		{
			switch(newteam)
			{
				case 0: CPrintToChatAll("Player {red}%N joined team unassigned", client);
				case 1: CPrintToChatAll("Player {red}%N{DEFAULT} joined team {gray}Spectator", client);
				case 2: CPrintToChatAll("Player {red}%N{DEFAULT} joined team {red}Red", client);
				case 3: CPrintToChatAll("Player {red}%N{DEFAULT} joined team {blue}Blu", client);
			}
		}
		case 3:
		{
			switch(newteam)
			{
				case 0: CPrintToChatAll("Player {blue}%N joined team unassigned", client);
				case 1: CPrintToChatAll("Player {blue}%N{DEFAULT} joined team {gray}Spectator", client);
				case 2: CPrintToChatAll("Player {blue}%N{DEFAULT} joined team {red}Red", client);
				case 3: CPrintToChatAll("Player {blue}%N{DEFAULT} joined team {blue}Blu", client);
			}
		}
	}
	return Plugin_Continue;
}

stock bool:IsValidClient(client, bool:replay = true)
{
	if(client <= 0 || client > MaxClients || !IsClientInGame(client)) return false;
	if(replay && (IsClientSourceTV(client) || IsClientReplay(client))) return false;
	return true;
}