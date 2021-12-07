#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Psycheat"
#define PLUGIN_VERSION "1.0"

#include <sourcemod>
#include <sdktools>
#include <cstrike>

new Handle:sm_teampanel;
new Handle:sm_teamdeath;
new Handle:CounterTerroristPanel;
new Handle:TerroristPanel;
new String:tlist[512];
new String:ctlist[512];

new String:clientname[MAXPLAYERS + 1][32];
new bool:IsAlive[MAXPLAYERS + 1];
new bool:IsBot[MAXPLAYERS + 1];
new clientteam[MAXPLAYERS + 1];

new bool:InGame;

public Plugin:myinfo = 
{
	name = "TeamStatus",
	author = PLUGIN_AUTHOR,
	description = "Show teammates status and announce clientteammate death location.",
	version = PLUGIN_VERSION,
	url = ""
};

public OnPluginStart()
{
	sm_teamdeath = CreateConVar("sm_death", "1.0", "Enable/Disable Death Notification", FCVAR_NOTIFY|FCVAR_DONTRECORD, true, 0.0, true, 1.0);
	HookConVarChange(sm_teamdeath, TeamDeathChange);
	sm_teampanel = CreateConVar("sm_teampanel", "1.0", "Enable/Disable Teampanel", FCVAR_NOTIFY|FCVAR_DONTRECORD, true, 0.0, true, 1.0);
	HookConVarChange(sm_teampanel, TeamPanelChange);
	
	HookEvent("player_death", NotifyDeath);
	
	HookEvent("player_spawn", OnPlayerSpawn);
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("player_team", OnPlayerChangeTeam);
	HookEvent("player_changename", OnPlayerChangeName);
	
	HookEvent("round_freeze_end", OnRoundFreezeEnd);
	HookEvent("round_end", OnRoundEnd);
}

public OnPluginEnd()
{
	CancelAllPanel();
}

public TeamDeathChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (GetConVarBool(convar))
		HookEvent("player_death", NotifyDeath);
	else
		UnhookEvent("player_death", NotifyDeath);
}

public TeamPanelChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (GetConVarBool(convar))
	{
		HookEvent("player_spawn", OnPlayerSpawn);
		HookEvent("player_death", OnPlayerDeath);
		HookEvent("player_team", OnPlayerChangeTeam);
		HookEvent("player_changename", OnPlayerChangeName);
		
		CreateTeamList(CS_TEAM_T);
		CreateTeamList(CS_TEAM_CT);
		CreateTeamPanel(CS_TEAM_T);
		CreateTeamPanel(CS_TEAM_CT);
	}
	else
	{
		UnhookEvent("player_spawn", OnPlayerSpawn);
		UnhookEvent("player_death", OnPlayerDeath);
		UnhookEvent("player_team", OnPlayerChangeTeam);
		UnhookEvent("player_changename", OnPlayerChangeName);
		
		CancelAllPanel();
	}
}

public Action:NotifyDeath(Handle:event, const String:eventname[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	decl String:location[64];
	decl String:message[64];
	GetEntPropString(client, Prop_Send, "m_szLastPlaceName", location, sizeof(location));
	Format(message, sizeof(message), "ALERT: %N is dead!    Location: %s", client, location);
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == clientteam[client] && !IsBot[i] && IsAlive[i] && i != client)
			PrintHintText(i, "%s", message);
	}
}

public OnClientPutInServer(client)
{
	GetClientName(client, clientname[client], 32);
	IsBot[client] = IsFakeClient(client);
}

public OnClientDisconnect(client)
{
	CancelClientMenu(client, true, INVALID_HANDLE);
	
	clientname[client] = NULL_STRING;
	clientteam[client] = CS_TEAM_NONE;
	IsAlive[client] = false;
	IsBot[client] = false;
	
	CreateTeamList(clientteam[client]);
	CreateTeamPanel(clientteam[client]);
}

public Action:OnPlayerSpawn(Handle:event, const String:eventname[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	IsAlive[client] = IsPlayerAlive(client);
	clientteam[client] = GetClientTeam(client);
	
	CreateTeamList(clientteam[client]);
	CreateTeamPanel(clientteam[client]);
}

public Action:OnPlayerDeath(Handle:event, const String:eventname[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	CancelClientMenu(client, true, INVALID_HANDLE);
	IsAlive[client] = false;
	
	CreateTeamList(clientteam[client]);
	CreateTeamPanel(clientteam[client]);
}

public Action:OnPlayerChangeTeam(Handle:event, const String:eventname[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	CancelClientMenu(client, true, INVALID_HANDLE);
	clientteam[client] = GetEventInt(event, "clientteam");
	
	CreateTeamList(GetEventInt(event, "team"));
	CreateTeamList(GetEventInt(event, "oldteam"));
	CreateTeamPanel(GetEventInt(event, "team"));
	CreateTeamPanel(GetEventInt(event, "oldteam"));
}

public Action:OnPlayerChangeName(Handle:event, const String:eventname[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	GetEventString(event, "newname", clientname[client], 32);
	
	CreateTeamList(clientteam[client]);
	CreateTeamPanel(clientteam[client]);
}

public Action:OnRoundFreezeEnd(Handle:event, const String:eventname[], bool:dontBroadcast)
{
	InGame = true;
	CreateTeamList(CS_TEAM_T);
	CreateTeamList(CS_TEAM_CT);
	CreateTeamPanel(CS_TEAM_T);
	CreateTeamPanel(CS_TEAM_CT);
}

public Action:OnRoundEnd(Handle:event, const String:eventname[], bool:dontBroadcast)
{
	InGame = false;
	CancelAllPanel();
}

CreateTeamList(int team)
{
	if (!InGame)
	return;
	
	decl String:buffer[32];
	new count = 1;
	
	switch (team)
	{
		case CS_TEAM_T:
		{
			tlist = "";
			
			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && clientteam[i] == CS_TEAM_T && IsAlive[i])
				{
					Format(buffer, sizeof(buffer), "\n%d. %s", count, clientname[i]);
					StrCat(tlist, sizeof(tlist), buffer);
					count++;
				}
			}
	
			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && clientteam[i] == CS_TEAM_T && !IsAlive[i])
				{
					Format(buffer, sizeof(buffer), "\n%d. *DEAD* %s", count, clientname[i]);
					StrCat(tlist, sizeof(tlist), buffer);
					count++;
				}
			}
		}
		
		case CS_TEAM_CT:
		{
			ctlist = "";
			
			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && clientteam[i] == CS_TEAM_CT && IsAlive[i])
				{
					Format(buffer, sizeof(buffer), "\n%d. %s", count, clientname[i]);
					StrCat(ctlist, sizeof(ctlist), buffer);
					count++;
				}
			}
	
			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && clientteam[i] == CS_TEAM_CT && !IsAlive[i])
				{
					Format(buffer, sizeof(buffer), "\n%d. *DEAD* %s", count, clientname[i]);
					StrCat(ctlist, sizeof(ctlist), buffer);
					count++;
				}
			}
		}
	}
}

CreateTeamPanel(int team)
{
	if (!InGame)
	return;
	
	switch (team)
	{
		case CS_TEAM_T:
		{
			ClearPanel(TerroristPanel);
			TerroristPanel = CreatePanel(GetMenuStyleHandle(MenuStyle_Radio));
			SetPanelKeys(TerroristPanel, 0 | (1 << 0) | (1 << 1) | (1 << 2) | (1 << 3) | (1 << 4) | (1 << 5) | (1 << 6) | (1 << 7) | (1 << 8) | (1 << 9));
			SetPanelTitle(TerroristPanel, "TERRORIST");
			DrawPanelText(TerroristPanel, tlist);
	
			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && clientteam[i] == CS_TEAM_T && !IsBot[i] && IsAlive[i])
					SendPanelToClient(TerroristPanel, i, TeamPanelHandler, MENU_TIME_FOREVER);
			}
		}
		
		case CS_TEAM_CT:
		{
			ClearPanel(CounterTerroristPanel);
			CounterTerroristPanel = CreatePanel(GetMenuStyleHandle(MenuStyle_Radio));
			SetPanelKeys(CounterTerroristPanel, 0 | (1 << 0) | (1 << 1) | (1 << 2) | (1 << 3) | (1 << 4) | (1 << 5) | (1 << 6) | (1 << 7) | (1 << 8) | (1 << 9));
			SetPanelTitle(CounterTerroristPanel, "COUNTER-TERRORIST");
			DrawPanelText(CounterTerroristPanel, ctlist);
	
			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && clientteam[i] == CS_TEAM_CT && !IsBot[i] && IsAlive[i])
					SendPanelToClient(CounterTerroristPanel, i, TeamPanelHandler, MENU_TIME_FOREVER);
			}
		}
	}
}

public TeamPanelHandler(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		decl String:classname[64];
		new weapon = GetPlayerWeaponSlot(client, param - 1);
		if (weapon != -1 && GetEntityClassname(weapon, classname, sizeof(classname)))
			FakeClientCommand(client, "use %s", classname);
		
		switch (clientteam[client])
		{
			case CS_TEAM_T:SendPanelToClient(TerroristPanel, client, TeamPanelHandler, MENU_TIME_FOREVER);
			case CS_TEAM_CT:SendPanelToClient(CounterTerroristPanel, client, TeamPanelHandler, MENU_TIME_FOREVER);
		}
	}
}

stock ClearPanel(&Handle:panel)
{
	if (panel != INVALID_HANDLE)
	{
		CloseHandle(panel);
		panel = INVALID_HANDLE;
	}
}

CancelAllPanel()
{
	for (new i = 1; i <= MaxClients; i++)
		CancelClientMenu(i, true, INVALID_HANDLE);
}
