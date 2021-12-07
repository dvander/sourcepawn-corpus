#pragma semicolon 1

// ====[ INCLUDES ]============================================================
#include <sourcemod>

// ====[ DEFINES ]=============================================================
#define PLUGIN_VERSION "2.1.2"

// ====[ HANDLES | CVARS ]=====================================================
new Handle:cvarEnabled;
new Handle:cvarTeamcolor;
new Handle:cvarPhrase;
new Handle:cvarXPos;
new Handle:cvarYPos;
new Handle:cvarStarttime;
new Handle:cvarEffect;
new Handle:cvarHoldtime;
new Handle:cvarRed;
new Handle:cvarGreen;
new Handle:cvarBlue;
new Handle:cvarAlpha;
new Handle:g_hHud;
new Handle:g_hTimer[MAXPLAYERS + 1];

// ====[ VARIABLES ]===========================================================
new bool:g_bEnabled;
new g_iRed;
new g_iGreen;
new g_iBlue;
new g_iAlpha;
new g_iEffect;
new bool:g_bTeamColor;
new Float:g_fHoldTime;
new Float:g_fXPos;
new Float:g_fYPos;
new Float:g_fStartTime;
new String:g_strPhase[255];

// ====[ PLUGIN ]==============================================================
public Plugin:myinfo =
{
	name = "Server Hud Logo",
	author = "ReFlexPoison",
	description = "Add a custom hud logo for everyone to see",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1664292"
}

// ====[ FUNCTIONS ]===========================================================
public OnPluginStart()
{
	CreateConVar("sm_logo_version", PLUGIN_VERSION, "Version of Server Hud Logo", FCVAR_REPLICATED | FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);

	cvarEnabled = CreateConVar("sm_logo_enabled", "1", "Enable Server Hud Logo\n0 = Disabled\n1 = Enabled", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_bEnabled = GetConVarBool(cvarEnabled);

	cvarTeamcolor = CreateConVar("sm_logo_teamcolor", "0", "Use team colored logos\n0 = Disabled\n1 = Enabled", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_bTeamColor = GetConVarBool(cvarTeamcolor);

	cvarPhrase = CreateConVar("sm_logo_phrase", "Server Logo", "Logo phrase", FCVAR_PLUGIN);
	GetConVarString(cvarPhrase, g_strPhase, sizeof(g_strPhase));

	cvarXPos = CreateConVar("sm_logo_xvalue", "0.18", "X logo position\n-1 = Center", FCVAR_PLUGIN, true, -1.0, true, 1.0);
	g_fXPos = GetConVarFloat(cvarXPos);
	if(g_fXPos != -1.0 && g_fXPos < 0.0)
	{
		g_fXPos = 0.18;
		SetConVarFloat(cvarXPos, 0.18);
		PrintToServer("Invalid convar value for convar 'sm_logo_xvalue' (Set to default)");
	}

	cvarYPos = CreateConVar("sm_logo_yvalue", "0.9", "Y logo position\n-1 = Center", FCVAR_PLUGIN, true, -1.0, true, 1.0);
	g_fYPos = GetConVarFloat(cvarYPos);
	if(g_fYPos != -1.0 && g_fYPos < 0.0)
	{
		g_fYPos = 0.9;
		SetConVarFloat(cvarYPos, 0.9);
		PrintToServer("Invalid convar value for convar 'sm_logo_yvalue' (Set to default)");
	}

	cvarStarttime = CreateConVar("sm_logo_spawntime", "2", "Time after spawn to display logo", FCVAR_PLUGIN, true, 1.0, true, 60.0);
	g_fStartTime = GetConVarFloat(cvarStarttime);

	cvarEffect = CreateConVar("sm_logo_effect", "0", "Logo effect\n0 = Fade In\n1 = Fade In/Out \n2 = Type", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	g_iEffect = GetConVarInt(cvarEffect);

	cvarHoldtime = CreateConVar("sm_logo_holdtime", "0", "Logo duration\n0 = Infinite", FCVAR_PLUGIN, true, 0.0);
	g_fHoldTime = GetConVarFloat(cvarHoldtime);

	cvarRed = CreateConVar("sm_logo_red", "255", "Red logo color value", FCVAR_PLUGIN, true, 0.0, true, 255.0);
	g_iRed = GetConVarInt(cvarRed);

	cvarGreen = CreateConVar("sm_logo_green", "255", "Green logo color value", FCVAR_PLUGIN, true, 0.0, true, 255.0);
	g_iGreen = GetConVarInt(cvarGreen);

	cvarBlue = CreateConVar("sm_logo_blue", "255", "Blue logo color value", FCVAR_PLUGIN, true, 0.0, true, 255.0);
	g_iBlue = GetConVarInt(cvarBlue);

	cvarAlpha = CreateConVar("sm_logo_alpha", "255", "Alpha transparency value", FCVAR_PLUGIN, true, 0.0, true, 255.0);
	g_iAlpha = GetConVarInt(cvarAlpha);

	HookConVarChange(cvarEnabled, CVarChange);
	HookConVarChange(cvarTeamcolor, CVarChange);
	HookConVarChange(cvarPhrase, CVarChange);
	HookConVarChange(cvarXPos, CVarChange);
	HookConVarChange(cvarYPos, CVarChange);
	HookConVarChange(cvarStarttime, CVarChange);
	HookConVarChange(cvarEffect, CVarChange);
	HookConVarChange(cvarHoldtime, CVarChange);
	HookConVarChange(cvarRed, CVarChange);
	HookConVarChange(cvarGreen, CVarChange);
	HookConVarChange(cvarBlue, CVarChange);
	HookConVarChange(cvarAlpha, CVarChange);

	HookEvent("player_spawn", OnPlayerSpawn);
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("player_team", OnPlayerChangeTeam);

	AutoExecConfig(true, "plugin.serverlogo");

	g_hHud = CreateHudSynchronizer();
	if(g_hHud == INVALID_HANDLE)
		SetFailState("HUD synchronisation is not supported by this mod");
}

public CVarChange(Handle:hConvar, const String:strOldValue[], const String:strNewValue[])
{
	if(hConvar == cvarEnabled)
		g_bEnabled = GetConVarBool(cvarEnabled);
	if(hConvar == cvarTeamcolor)
		g_bTeamColor = GetConVarBool(cvarTeamcolor);
	if(hConvar == cvarPhrase)
		GetConVarString(cvarPhrase, g_strPhase, sizeof(g_strPhase));
	if(hConvar == cvarXPos)
	{
		g_fXPos = GetConVarFloat(cvarXPos);
		if(g_fXPos != -1.0 && g_fXPos < 0.0)
		{
			g_fXPos = 0.18;
			SetConVarFloat(cvarXPos, 0.18);
			PrintToServer("Invalid convar value for convar 'sm_logo_xvalue' (Set to default)");
		}
	}
	if(hConvar == cvarYPos)
	{
		g_fYPos = GetConVarFloat(cvarYPos);
		if(g_fYPos != -1.0 && g_fYPos < 0.0)
		{
			g_fYPos = 0.9;
			SetConVarFloat(cvarYPos, 0.9);
			PrintToServer("Invalid convar value for convar 'sm_logo_yvalue' (Set to default)");
		}
	}
	if(hConvar == cvarStarttime)
		g_fStartTime = GetConVarFloat(cvarStarttime);
	if(hConvar == cvarEffect)
		g_iEffect = GetConVarInt(cvarEffect);
	if(hConvar == cvarHoldtime)
		g_fHoldTime = GetConVarFloat(cvarHoldtime);
	if(hConvar == cvarRed)
		g_iRed = GetConVarInt(cvarRed);
	if(hConvar == cvarGreen)
		g_iGreen = GetConVarInt(cvarGreen);
	if(hConvar == cvarBlue)
		g_iBlue = GetConVarInt(cvarBlue);
	if(hConvar == cvarAlpha)
		g_iAlpha = GetConVarInt(cvarAlpha);
}

public OnClientDisconnect(iClient)
{
	if(IsValidClient(iClient))
		ClearTimer(g_hTimer[iClient]);
}

public OnMapEnd()
{
	for(new i = 1; i <= MaxClients; i++)
		ClearTimer(g_hTimer[i]);
}

public Action:OnPlayerSpawn(Handle:hEvent, const String:strName[], bool:bBroadcast)
{
	if(!g_bEnabled)
		return Plugin_Continue;

	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(!IsValidClient(iClient) || IsFakeClient(iClient))
		return Plugin_Continue;

	ClearTimer(g_hTimer[iClient]);
	g_hTimer[iClient] = CreateTimer(g_fStartTime, Timer_Hud, iClient);
	return Plugin_Continue;
}

public Action:OnPlayerDeath(Handle:hEvent, const String:strName[], bool:bBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(!IsValidClient(iClient))
		return Plugin_Continue;

	ClearSyncHud(iClient, g_hHud);
	ClearTimer(g_hTimer[iClient]);
	return Plugin_Continue;
}

public Action:OnPlayerChangeTeam(Handle:hEvent, const String:strName[], bool:bBroadcast)
{
	if(!g_bEnabled)
		return Plugin_Continue;

	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(!IsValidClient(iClient) || IsFakeClient(iClient) || GetEventInt(hEvent, "team") > 1)
		return Plugin_Continue;

	ClearSyncHud(iClient, g_hHud);
	ClearTimer(g_hTimer[iClient]);
	g_hTimer[iClient] = CreateTimer(g_fStartTime, Timer_Hud, iClient);
	return Plugin_Continue;
}

// ====[ TIMERS ]==============================================================
public Action:Timer_Hud(Handle:hTimer, any:iClient)
{
	g_hTimer[iClient] = INVALID_HANDLE;

	if(!g_bEnabled || !IsValidClient(iClient))
		return Plugin_Continue;

	if(g_bTeamColor)
	{
		switch(GetClientTeam(iClient))
		{
			case 2:
			{
				if(g_fHoldTime >= 0 && g_fHoldTime < 1)
					SetHudTextParams(g_fXPos, g_fYPos, 604800.0, 255, 64, 64, g_iAlpha, g_iEffect);
				else
					SetHudTextParams(g_fXPos, g_fYPos, g_fHoldTime, 255, 64, 64, g_iAlpha, g_iEffect);
			}
			case 3:
			{
				if(g_fHoldTime >= 0 && g_fHoldTime < 1)
					SetHudTextParams(g_fXPos, g_fYPos, 604800.0, 153, 204, 255, g_iAlpha, g_iEffect);
				else
					SetHudTextParams(g_fXPos, g_fYPos, g_fHoldTime, 153, 204, 255, g_iAlpha, g_iEffect);
			}
			default:
			{
				if(g_fHoldTime >= 0 && g_fHoldTime < 1)
					SetHudTextParams(g_fXPos, g_fYPos, 604800.0, 204, 204, 204, g_iAlpha, g_iEffect);
				else
					SetHudTextParams(g_fXPos, g_fYPos, g_fHoldTime, 204, 204, 204, g_iAlpha, g_iEffect);
			}
		}
	}
	else
	{
		if(g_fHoldTime >= 0 && g_fHoldTime < 1)
			SetHudTextParams(g_fXPos, g_fYPos, 604800.0, g_iRed, g_iGreen, g_iBlue, g_iAlpha, g_iEffect);
		else
			SetHudTextParams(g_fXPos, g_fYPos, g_fHoldTime, g_iRed, g_iGreen, g_iBlue, g_iAlpha, g_iEffect);
	}
	ShowSyncHudText(iClient, g_hHud, g_strPhase);
	return Plugin_Continue;
}

// ====[ STOCKS ]==============================================================
stock bool:IsValidClient(iClient, bool:bReplay = true)
{
	if(iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient))
		return false;
	if(bReplay && (IsClientSourceTV(iClient) || IsClientReplay(iClient)))
		return false;
	return true;
}

stock ClearTimer(&Handle:hTimer)
{
	if(hTimer != INVALID_HANDLE)
	{
		KillTimer(hTimer);
		hTimer = INVALID_HANDLE;
	}
}