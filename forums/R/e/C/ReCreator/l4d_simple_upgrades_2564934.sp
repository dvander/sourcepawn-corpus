#include <colors>
#include <sourcemod>
#pragma semicolon 1

new bool:LaserCheck[MAXPLAYERS + 1];
new bool:SpeedCheck[MAXPLAYERS + 1];
new bool:SilencerCheck[MAXPLAYERS + 1];
new bool:ReloadCheck[MAXPLAYERS + 1];
new bool:MagazineCheck[MAXPLAYERS + 1];

public Plugin:myinfo =
{
	name = "Simple UpGrades",
	description = "Laser/Silencer/Reloading/Speed/Magazine",
	author = "Figa, Re:Creator",
	version = "1.0",
	url = "None"
};

public OnPluginStart()
{
	HookEvent("round_end", round_end, EventHookMode_Pre);
	HookEvent("map_transition", round_end, EventHookMode_Pre);
	
	RegConsoleCmd("sm_silent", ToggleSilencer, "sm_silent - Toggle Silencer");
	RegConsoleCmd("sm_laser", ToggleLaser, "sm_laser - Toggle Laser Sight");
	RegConsoleCmd("sm_reload", ToggleFastReload, "sm_reload - Toggle Fast Reload");
	RegConsoleCmd("sm_speed", ToggleSpeed, "sm_speed - Toggle Speed");
	RegConsoleCmd("sm_magazine", ToggleMagazine, "sm_magazine - Toggle magazine");
	RegConsoleCmd("sm_upgrades", EnableUpgrades, "sm_upgrades - Enable All Upgrades");
	RegConsoleCmd("sm_perks", PlayerPanel, "Player menu.");
	
	HookUserMessage(GetUserMessageId("SayText"), SayTextHook, true);
	
	LoadTranslations("l4d_su.phrases");
}
public Action:round_end(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(new i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i)) DisableAllUpgrades(i);
	}
}
public OnClientPutInServer(client)
{
	if (IsFakeClient(client) || (!client)) return;
	DisableAllUpgrades(client);
}
stock DisableAllUpgrades(client)
{
	SetEntProp(client, Prop_Send, "m_upgradeBitVec", 0, 4);
	LaserCheck[client] = false;
	SilencerCheck[client] = false;
	ReloadCheck[client] = false;
	SpeedCheck[client] = false;
	MagazineCheck[client] = false;
}
public Action:EnableUpgrades(client, args)
{
ToggleSilencer(client, args);
ToggleLaser(client, args);
ToggleFastReload(client, args);
ToggleSpeed(client, args);
}

public Action:ToggleSilencer(client, args)
{
	if (IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
	{
		new cl_upgrades = GetEntProp(client, Prop_Send, "m_upgradeBitVec");
		if (!SilencerCheck[client])
		{
			SetEntProp(client, Prop_Send, "m_upgradeBitVec", cl_upgrades + 262144, 4);
			SilencerCheck[client] = true;
			CPrintToChat(client, "%t", "Silencer_On");
		}
		else
		{
			SetEntProp(client, Prop_Send, "m_upgradeBitVec", cl_upgrades - 262144, 4);
			SilencerCheck[client] = false;
			CPrintToChat(client, "%t", "Silencer_Off");
		}
	}
	return Plugin_Handled;
}
public Action:ToggleLaser(client, args)
{
	if (IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
	{
		new cl_upgrades = GetEntProp(client, Prop_Send, "m_upgradeBitVec");
		if (!LaserCheck[client])
		{
			SetEntProp(client, Prop_Send, "m_upgradeBitVec", cl_upgrades + 131072, 4);
			LaserCheck[client] = true;
			CPrintToChat(client, "%t", "Laser_On");
		}
		else
		{
			SetEntProp(client, Prop_Send, "m_upgradeBitVec", cl_upgrades - 131072, 4);
			LaserCheck[client] = false;
			CPrintToChat(client, "%t", "Laser_Off");
		}
	}
	return Plugin_Handled;
}
public Action:ToggleFastReload(client, args)
{
	if (IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
	{
		new cl_upgrades = GetEntProp(client, Prop_Send, "m_upgradeBitVec");
		if (!ReloadCheck[client])
		{
			SetEntProp(client, Prop_Send, "m_upgradeBitVec", cl_upgrades + 536870912, 4);
			ReloadCheck[client] = true;
			CPrintToChat(client, "%t", "Reload_On");
		}
		else
		{
			SetEntProp(client, Prop_Send, "m_upgradeBitVec", cl_upgrades - 536870912, 4);
			ReloadCheck[client] = false;
			CPrintToChat(client, "%t", "Reload_Off");
		}
	}
	return Plugin_Handled;
}
public Action:ToggleSpeed(client, args)
{
	if (IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
	{
		new cl_upgrades = GetEntProp(client, Prop_Send, "m_upgradeBitVec");
		if (!SpeedCheck[client])
		{
			SetEntProp(client, Prop_Send, "m_upgradeBitVec", cl_upgrades + 32768, 4);
			SpeedCheck[client] = true;
			CPrintToChat(client, "%t", "Speed_On");
		}
		else
		{
			SetEntProp(client, Prop_Send, "m_upgradeBitVec", cl_upgrades - 32768, 4);
			SpeedCheck[client] = false;
			CPrintToChat(client, "%t", "Speed_Off");
		}
	}
	return Plugin_Handled;
}
public Action:ToggleMagazine(client, args)
{
	if (IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
	{
		new cl_upgrades = GetEntProp(client, Prop_Send, "m_upgradeBitVec");
		if (!MagazineCheck[client])
		{
			SetEntProp(client, Prop_Send, "m_upgradeBitVec", cl_upgrades + 1048576, 4);
			MagazineCheck[client] = true;
			CPrintToChat(client, "%t", "Magazine_On");
		}
		else
		{
			SetEntProp(client, Prop_Send, "m_upgradeBitVec", cl_upgrades - 1048576, 4);
			MagazineCheck[client] = false;
			CPrintToChat(client, "%t", "Magazine_Off");
		}
	}
	return Plugin_Handled;
}
public Action:SayTextHook(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	BfReadShort(bf);
	BfReadShort(bf);
	new String:g_msgType[64];
	BfReadString(bf, g_msgType, sizeof(g_msgType), false);
	if(StrContains(g_msgType, "laser_sight_expire") != -1 || StrContains(g_msgType, "reloader_expire") != -1)
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
public Action:PlayerPanel(client, args)
{
	new Handle:PlayerMenu = CreateMenu(PlayerMenuHandler);
	decl String:MenulTitle[32];
	Format(MenulTitle, sizeof(MenulTitle), "%T\n \n", "MenuTitle", client);
	SetMenuTitle(PlayerMenu, MenulTitle);
	new String:Value[40];
	
	Format(Value, sizeof(Value), "%T", "Silencer", client);
	AddMenuItem(PlayerMenu, "0", Value);

	Format(Value, sizeof(Value), "%T", "Laser", client);
	AddMenuItem(PlayerMenu, "1", Value);

	Format(Value, sizeof(Value), "%T", "Reload", client);
	AddMenuItem(PlayerMenu, "2", Value);
	
	Format(Value, sizeof(Value), "%T", "Speed", client);
	AddMenuItem(PlayerMenu, "3", Value);
	
	Format(Value, sizeof(Value), "%T", "Magazine", client);
	AddMenuItem(PlayerMenu, "4", Value);
	
	Format(Value, sizeof(Value), "%T", "AllM", client);
	AddMenuItem(PlayerMenu, "5", Value);
	
	SetMenuExitButton(PlayerMenu, true);
	DisplayMenu(PlayerMenu, client, 30);

	return Plugin_Handled;
}

public PlayerMenuHandler(Handle:PlayerMenu, MenuAction:action, client, option)
{
	if (action == MenuAction_Select)
	{
		switch (option)
		{
			case 0: ClientCommand(client, "sm_silent");
			case 1: ClientCommand(client, "sm_laser");
			case 2: ClientCommand(client, "sm_reload");
			case 3: ClientCommand(client, "sm_speed");
			case 4: ClientCommand(client, "sm_magazine");			
			case 5: ClientCommand(client, "sm_upgrades");
		}
	}
}