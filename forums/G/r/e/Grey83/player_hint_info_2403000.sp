#include <sourcemod>
#include <sdktools>
#include <cstrike>

#define PLUGIN_VERSION		"1.0.0"
#define PLUGIN_NAME		"[CS:GO] Player Hint Info"

new Handle:hTimer[MAXPLAYERS+1] = INVALID_HANDLE,
	Handle:hEnable = INVALID_HANDLE, iEnable;

public Plugin:myinfo =
{
	name				= PLUGIN_NAME,
	author				= "Grey83",
	description				= "Show player info on HUD for spectators in CS:GO",
	version				= PLUGIN_VERSION,
	url					= "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	decl String:game[8];
	GetGameFolderName(game, sizeof(game));
	if(strcmp(game, "csgo", false) != 0) SetFailState("Unsupported game!");

	CreateConVar("csgo_player_hint_info_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	hEnable = CreateConVar("sm_player_hint_info", "2", "0 - Not show info, 1 - Show HP to all, 2 - Show HP only to allies", FCVAR_PLUGIN, true, 0.0, true, 2.0);

	iEnable = GetConVarInt(hEnable);

	HookConVarChange(hEnable, OnConVarChange);
}

public OnConVarChange(Handle:hCvar, const String:oldValue[], const String:newValue[])
{
	iEnable = StringToInt(newValue);
	if (!iEnable)
		for(new i = 1; i <= GetMaxClients(); i++) OnClientDisconnect(i);
	else
		for(new i = 1; i <= GetMaxClients(); i++) OnClientPostAdminCheck(i);
}

public OnClientPostAdminCheck(client)
{
	if(hTimer[client] == INVALID_HANDLE) hTimer[client] = CreateTimer(0.5, Timer, client, TIMER_REPEAT);
}

public OnClientDisconnect(client)
{
	if (hTimer[client] != INVALID_HANDLE)
	{
		KillTimer(hTimer[client]);
		hTimer[client] = INVALID_HANDLE;
	}
}

public Action:Timer(Handle:timer, any:client)
{
	if (IsClientInGame(client) && !IsPlayerAlive(client))
	{
		new target = GetClientAimTarget(client, true); 
		if(target < 1 || target > MaxClients || target == client) return Plugin_Continue;		//maybe needed

		if(IsClientInGame(target) && IsPlayerAlive(target))
		{
			new client_team = GetClientTeam(client);
			new target_team = GetClientTeam(target);
			new String:sTeam[35];
			if (client_team == target_team) sTeam = "<font color='#00ff00'>ally</font>";
			else sTeam ="<font color='#ff0000'>enemy</font>";

			if (iEnable == 2 && client_team != target_team && client_team > 1) PrintHintText(client, "%N<br/>%s", target, sTeam);
			else
			{
				if (client_team > 1) PrintHintText(client, "%N<br/><b>%d</b> HP<br/>%s", target, GetClientHealth(target), sTeam);
				else PrintHintText(client, "%N<br/><b>%d</b> HP", target, GetClientHealth(target));
			}
		}
	}

	return Plugin_Continue; 
}