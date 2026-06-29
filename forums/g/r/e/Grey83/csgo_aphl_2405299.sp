#include <sourcemod>
#include <sdktools>
#include <cstrike>

#define PLUGIN_VERSION		"1.0.0"
#define PLUGIN_NAME		"[CS:GO] Alive Players Hint List"

new Handle:hTimer[MAXPLAYERS+1] = INVALID_HANDLE,
	Handle:hEnable = INVALID_HANDLE, iEnable;

public Plugin:myinfo =
{
	name				= PLUGIN_NAME,
	author				= "Grey83",
	description				= "Show alive players list on HUD for spectators in CS:GO",
	version				= PLUGIN_VERSION,
	url					= ""
};

public OnPluginStart()
{
	decl String:game[8];
	GetGameFolderName(game, sizeof(game));
	if(strcmp(game, "csgo", false) != 0) SetFailState("Unsupported game!");

	CreateConVar("csgo_aphl_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	hEnable = CreateConVar("sm_aphl_enable", "1", "1/0 - On/Off show alive players list", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	iEnable = GetConVarInt(hEnable);
	HookConVarChange(hEnable, OnConVarChange);
}

public OnConVarChange(Handle:hCvar, const String:oldValue[], const String:newValue[])
{
	if(hCvar == hEnable)
	{
		iEnable = StringToInt(newValue);
		if (!iEnable) for(new i = 1; i <= GetMaxClients(); i++) OnClientDisconnect(i);
		else for(new i = 1; i <= GetMaxClients(); i++) OnClientPostAdminCheck(i);
	}
}

public OnClientPostAdminCheck(client)
{
	if(hTimer[client] == INVALID_HANDLE) hTimer[client] = CreateTimer(1.0, Timer, client, TIMER_REPEAT);
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
	if (0 < client <= MaxClients && IsClientInGame(client))
	{
		if (GetClientTeam(client) == 1 || !IsPlayerAlive(client))
		{
			new num;
			decl String:sBuffer[256];
			sBuffer[0] = '\0';
			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && IsPlayerAlive(i))
				{
					if (GetClientTeam(i) > 1)
					{
						Format(sBuffer, 256, " %s%N,", sBuffer, i);
						num++;
					}
				}
			}
			if (num > 0) PrintHintText(client, "Alive (%d):%s", num, sBuffer);
		}
	}

	return Plugin_Continue; 
}