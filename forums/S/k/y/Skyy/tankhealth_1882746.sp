#include <sourcemod>

#define PLUGIN_VERSION						"c."
#define PLUGIN_AUTHOR						"Sky"

#define ZOMBIECLASS_TANK					8
#define TEAM_SURVIVOR						2
#define TEAM_INFECTED						3

public Plugin:myinfo = {
	name = "Tank Health Panel",
	author = "skyrpg.donations@gmail.com",
	description = "A detailed tank health panel",
	version = PLUGIN_VERSION,
	url = PLUGIN_AUTHOR
}

new String:white[4];
new String:green[4];
new bool:IsPanelEnabled[MAXPLAYERS + 1];
new Handle:TankTimer												=	INVALID_HANDLE;
new TankHealth[MAXPLAYERS + 1];

public OnPluginStart()
{
	CreateConVar("thp_version", PLUGIN_VERSION, "version header");

	HookEvent("tank_spawn", Event_TankSpawn);
	
	RegConsoleCmd("thp", CMDTankHealthPanel);

	Format(white, sizeof(white), "\x01");
	Format(green, sizeof(green), "\x05");

	LoadTranslations("common.phrases");
	LoadTranslations("thp.phrases");
}

public OnClientDisconnect(client)
{
	if (IsClientInGame(client) && GetClientTeam(client) == TEAM_INFECTED && FindZombieClass(client) == ZOMBIECLASS_TANK)
	{
		CreateTimer(1.0, Timer_ClientIsTankDisconnecting, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:Timer_ClientIsTankDisconnecting(Handle:timer, any:client)
{
	if (IsClientInGame(client)) return Plugin_Continue;
	CheckIfTankTimerIsInvalid();
	return Plugin_Stop;
}

stock bool:IsClientActual(client)
{
	if (client < 1 || client > MaxClients || !IsClientInGame(client)) return false;
	return true;
}

stock bool:IsClientHuman(client)
{
	if (IsClientActual(client) && !IsFakeClient(client)) return true;
	return false;
}

//psim
stock SendPanelToClientAndClose(Handle:panel, client, MenuHandler:handler, time)
{
	SendPanelToClient(panel, client, handler, time);
	CloseHandle(panel);
}

stock FindZombieClass(client)
{
	return GetEntProp(client, Prop_Send, "m_zombieClass");
}

stock bool:IsAnyTanksAlive()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientActual(i) && GetClientTeam(i) == TEAM_INFECTED && !IsIncapacitated(i) && IsPlayerAlive(i) && FindZombieClass(i) == ZOMBIECLASS_TANK) return true;
	}
	return false;
}

stock String:HealthBar(client)
{
	new String:eBar[128];
	new Float:ePct = ((GetClientHealth(client) * 1.0) / (TankHealth[client] * 1.0)) * 100.0;
	new Float:eCnt = 0.0;
	Format(eBar, sizeof(eBar), "[........................................]");
	for (new i = 1; i + 1 <= strlen(eBar); i++)
	{
		if (eCnt < ePct)
		{
			eBar[i] = '|';
			eCnt += 2.5;
		}
	}
	return eBar;
}

//Berni
stock String:AddCommasToString(value) 
{
	new String:buffer[128];
	new String:separator[1];
	separator = ",";
	buffer[0] = '\0'; 
	new divisor = 1000; 
	
	while (value >= 1000 || value <= -1000)
	{
		new offcut = value % divisor;
		value = RoundToFloor(float(value) / float(divisor));
		Format(buffer, sizeof(buffer), "%s%03.d%s", separator, offcut, buffer); 
	}
	
	Format(buffer, sizeof(buffer), "%d%s", value, buffer);
	return buffer;
}

stock bool:IsIncapacitated(client)
{
	return bool:GetEntProp(client, Prop_Send, "m_isIncapacitated");
}

public Action:CMDTankHealthPanel(client, args)
{
	if (IsPanelEnabled[client])
	{
		IsPanelEnabled[client] = false;
		PrintToChat(client, "%T", "Tank Panel Disabled", client, white, green, white, green, white);
	}
	else if (!IsPanelEnabled[client])
	{
		IsPanelEnabled[client] = true;
		PrintToChat(client, "%T", "Tank Panel Enabled", client, white, green, white, green, white);
	}
}

public OnMapStart()
{
	TankTimer = INVALID_HANDLE;
}

public Action:Event_TankSpawn(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client				=	GetClientOfUserId(GetEventInt(event, "userid"));

	if (IsClientActual(client))
	{
		TankHealth[client] = -1;
		CreateTimer(1.0, Timer_HealthModifierSet, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
	CheckIfTankTimerIsInvalid();
}

stock CheckIfTankTimerIsInvalid()
{
	if (TankTimer == INVALID_HANDLE)
	{
		TankTimer = CreateTimer(1.0, Timer_TankHealthPanel, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientHuman(i) && GetClientTeam(i) == TEAM_SURVIVOR && !IsPanelEnabled[i])
			{
				PrintToChat(i, "%T", "Tank Panel Disabled", i, white, green, white, green, white);
			}
		}
	}
}

public Action:Timer_HealthModifierSet(Handle:timer, any:client)
{
	if (IsClientActual(client) && !IsGhost(client) && IsPlayerAlive(client) && GetClientTeam(client) == TEAM_INFECTED && GetClientHealth(client) > 0 && TankHealth[client] == -1)
	{
		TankHealth[client] = GetClientHealth(client);
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action:Timer_TankHealthPanel(Handle:timer)
{
	if (!IsAnyTanksAlive())
	{
		TankTimer = INVALID_HANDLE;
		return Plugin_Stop;
	}
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientHuman(i) && GetClientTeam(i) == TEAM_SURVIVOR && IsPanelEnabled[i])
		{
			SendPanelToClientAndClose(TankHealthPanel(i), i, TankHealthPanel_Handler, 1);
		}
	}
	return Plugin_Continue;
}

public Handle:TankHealthPanel(client)
{
	new Handle:menu			=	CreatePanel();

	new String:text[512];
	new String:Name[512];
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientActual(i) && GetClientTeam(i) == TEAM_INFECTED && !IsIncapacitated(i) && IsPlayerAlive(i) && FindZombieClass(i) == ZOMBIECLASS_TANK)
		{
			GetClientName(i, Name, sizeof(Name));
			Format(text, sizeof(text), "%s %s %s/%s", Name, HealthBar(i), AddCommasToString(GetClientHealth(i)), AddCommasToString(TankHealth[i]));
			DrawPanelText(menu, text);
		}
	}

	return menu;
}

public TankHealthPanel_Handler(Handle:topmenu, MenuAction:action, client, param2)
{
	if (topmenu != INVALID_HANDLE) CloseHandle(topmenu);
}

stock bool:IsGhost(client)
{
	return bool:GetEntProp(client, Prop_Send, "m_isGhost", 1);
}