#include <sourcemod>
#pragma semicolon 1

new bool:LaserCheck[MAXPLAYERS + 1];
new bool:SilencerCheck[MAXPLAYERS + 1];
new bool:NightCheck[MAXPLAYERS + 1];
new bool:ReloadCheck[MAXPLAYERS + 1];

new Handle:upSilencerEnable;
new Handle:upLaserEnable;
new Handle:upNightVisionEnable;
new Handle:upFastReloadEnable;

public Plugin:myinfo =
{
	name = "[L4D] Useful Upgrades",
	description = "Include 4 useful upgrades Laser Sight, Silencer, Night Vision and Fast Reload",
	author = "Figa",
	version = "1.1",
	url = "http://fiksiki.3dn.ru"
};

public OnPluginStart()
{
	HookEvent("player_death", player_death, EventHookMode_Post);
	HookEvent("player_spawn", player_death, EventHookMode_Post);
	HookEvent("round_end", round_end, EventHookMode_Pre);
	HookEvent("map_transition", round_end, EventHookMode_Pre);
	
	RegConsoleCmd("sm_silent", ToggleSilencer, "sm_silent - Toggle Silencer");
	RegConsoleCmd("sm_laser", ToggleLaser, "sm_laser - Toggle Laser Sight");
	RegConsoleCmd("sm_night", ToggleNightVision, "sm_night - Toggle Night Vision");
	RegConsoleCmd("sm_reload", ToggleFastReload, "sm_reload - Toggle Fast Reload");
	
	upSilencerEnable = CreateConVar( "l4d_enable_silencer", "1", "1 - Enable Toggle Silencer Upgrade; 0 - Disable This Upgrade", FCVAR_PLUGIN);
	upLaserEnable = CreateConVar( "l4d_enable_laser_sight", "1", "1 - Enable Toggle Laser Sight Upgrade; 0 - Disable This Upgrade", FCVAR_PLUGIN);
	upNightVisionEnable = CreateConVar( "l4d_enable_night_vision", "1", "1 - Enable Toggle Night Vision Upgrade; 0 - Disable This Upgrade", FCVAR_PLUGIN);
	upFastReloadEnable = CreateConVar( "l4d_enable_fast_reload", "1", "1 - Enable Toggle Fast Reload Upgrade; 0 - Disable This Upgrade", FCVAR_PLUGIN);
	
	HookUserMessage(GetUserMessageId("SayText"), SayTextHook, true);
	
	LoadTranslations("l4d_luu.phrases");
}
/*public OnClientPostAdminCheck(client)
{
	ClientCommand(client, "bind l sm_laser; bind k sm_silent; bind n sm_night; bind j sm_reload");
}*/
public Action:round_end(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(new i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i)) DisableAllUpgrades(i);
	}
}
public Action:player_death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client > 0 && IsClientInGame(client) && GetClientTeam(client) == 2) DisableAllUpgrades(client);
}
public OnClientPutInServer(client)
{
	if (IsFakeClient(client) || (!client)) return;
	DisableAllUpgrades(client);
}
stock DisableAllUpgrades(client)
{
	SetEntProp(client, Prop_Send, "m_upgradeBitVec", 0, 4);
	SetEntProp(client, Prop_Send, "m_bNightVisionOn", 0, 4);
	SetEntProp(client, Prop_Send, "m_bHasNightVision", 0, 4);
	LaserCheck[client] = false;
	SilencerCheck[client] = false;
	NightCheck[client] = false;
	ReloadCheck[client] = false;
}
public Action:ToggleSilencer(client, args)
{
	if (GetConVarBool(upSilencerEnable) && IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
	{
		new cl_upgrades = GetEntProp(client, Prop_Send, "m_upgradeBitVec");
		if (!SilencerCheck[client])
		{
			SetEntProp(client, Prop_Send, "m_upgradeBitVec", cl_upgrades + 262144, 4);
			SilencerCheck[client] = true;
			PrintToChat(client, "%t", "Silencer_On");
		}
		else
		{
			SetEntProp(client, Prop_Send, "m_upgradeBitVec", cl_upgrades - 262144, 4);
			SilencerCheck[client] = false;
			PrintToChat(client, "%t", "Silencer_Off");
		}
	}
	return Plugin_Handled;
}
public Action:ToggleLaser(client, args)
{
	if (GetConVarBool(upLaserEnable) && IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
	{
		new cl_upgrades = GetEntProp(client, Prop_Send, "m_upgradeBitVec");
		if (!LaserCheck[client])
		{
			SetEntProp(client, Prop_Send, "m_upgradeBitVec", cl_upgrades + 131072, 4);
			LaserCheck[client] = true;
			PrintToChat(client, "%t", "Laser_On");
		}
		else
		{
			SetEntProp(client, Prop_Send, "m_upgradeBitVec", cl_upgrades - 131072, 4);
			LaserCheck[client] = false;
			PrintToChat(client, "%t", "Laser_Off");
		}
	}
	return Plugin_Handled;
}
public Action:ToggleNightVision(client, args)
{
	if (GetConVarBool(upNightVisionEnable) && IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
	{
		new cl_upgrades = GetEntProp(client, Prop_Send, "m_upgradeBitVec");
		if (!NightCheck[client])
		{
			SetEntProp(client, Prop_Send, "m_upgradeBitVec", cl_upgrades + 4194304, 4);
			SetEntProp(client, Prop_Send, "m_bNightVisionOn", 1, 4);
			SetEntProp(client, Prop_Send, "m_bHasNightVision", 1, 4);
			NightCheck[client] = true;
			PrintToChat(client, "%t", "NightVision_On");
		}
		else
		{
			SetEntProp(client, Prop_Send, "m_upgradeBitVec", cl_upgrades - 4194304, 4);
			SetEntProp(client, Prop_Send, "m_bNightVisionOn", 0, 4);
			SetEntProp(client, Prop_Send, "m_bHasNightVision", 0, 4);
			NightCheck[client] = false;
			PrintToChat(client, "%t", "NightVision_Off");
		}
	}
	return Plugin_Handled;
}
public Action:ToggleFastReload(client, args)
{
	if (GetConVarBool(upFastReloadEnable) && IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
	{
		new cl_upgrades = GetEntProp(client, Prop_Send, "m_upgradeBitVec");
		if (!ReloadCheck[client])
		{
			SetEntProp(client, Prop_Send, "m_upgradeBitVec", cl_upgrades + 536870912, 4);
			ReloadCheck[client] = true;
			PrintToChat(client, "%t", "Reload_On");
		}
		else
		{
			SetEntProp(client, Prop_Send, "m_upgradeBitVec", cl_upgrades - 536870912, 4);
			ReloadCheck[client] = false;
			PrintToChat(client, "%t", "Reload_Off");
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