#include <sourcemod>
#include <cstrike>
#pragma semicolon 1

new Handle:AFKTimers[MAXPLAYERS+1] = INVALID_HANDLE;
new Float:iClafkTime = 30.0;

#define PLUGIN_VERSION "1.9-dev"

public Plugin:myinfo =
{
	name = "ClanTag AFK",
	author = "KK",
	description = "Check than a player is AFK by looking at his Clan",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=1446625"
};


public OnPluginStart()
{
	LoadTranslations("clafk.phrases");
	CreateConVar("sm_clafk_version", PLUGIN_VERSION, "ClanTag AFK version", FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_CHEAT);
	new Handle:hClafkTime = CreateConVar("sm_clafk_time", "30", "Sets time without client have run commands, changed cvar or position before status are set to AFK");
	HookConVarChange(hClafkTime, OnClafkTimeChange);
}

public OnClafkTimeChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	iClafkTime = StringToFloat(newValue);
}

public OnClientPutInServer(client)
{
	resetTimer(client);
}

public OnClientDisconnect(client)
{
	if (AFKTimers[client] != INVALID_HANDLE)
	{
		CloseHandle(AFKTimers[client]);
		AFKTimers[client] = INVALID_HANDLE;
	}
}

public Action:OnClientCommand(client)
{
	resetTimer(client);
	return Plugin_Continue;
}

public OnClientSettingsChanged(client)
{
	resetTimer(client);
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	static LastButtons[MAXPLAYERS+1];
	if (LastButtons[client] != buttons)
	{
		resetTimer(client);
	}
	LastButtons[client] = buttons;
	return Plugin_Continue;
}

public Action:OnClientSayCommand(client, const String:command[], const String:sArgs[])
{
	resetTimer(client);
}

resetTimer(client)
{
	if (IsClientInGame(client))
	{
		decl String:buffer[64];
		CS_GetClientClanTag(client, buffer, sizeof(buffer));
		if (StrEqual(buffer, "AFK"))
		{
			PrintToChatAll("\x04[AFK]\x01 %t", "are now online", client);
		}

		if (AFKTimers[client] != INVALID_HANDLE)
		{
			CloseHandle(AFKTimers[client]);
		}
		AFKTimers[client] = CreateTimer(iClafkTime, StatusAFK, client);
		CS_SetClientClanTag(client, "ONLINE");
	}
}

public Action:StatusAFK(Handle:timer, any:client)
{
	CS_SetClientClanTag(client, "AFK");
	PrintToChatAll("\x04[AFK]\x01 %t", "is now AFK", client);
	AFKTimers[client] = INVALID_HANDLE;
}
