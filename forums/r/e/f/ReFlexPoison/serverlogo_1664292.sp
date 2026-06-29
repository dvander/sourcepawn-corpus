#pragma semicolon 1

// ====[ INCLUDES ]============================================================
#include <sourcemod>

// ====[ DEFINES ]=============================================================
#define PLUGIN_NAME "Server Hud Logo"
#define PLUGIN_VERSION "2.2"
#define MAX_CHANNELS 12

// ====[ HANDLES | CVARS ]=====================================================
new Handle:g_hCvarEnabled;
new Handle:g_hHudSync[MAX_CHANNELS];

// ====[ VARIABLES ]===========================================================
new bool:g_bCvarEnabled;
new String:g_strConfigFile[255];
new g_iRedValue[MAX_CHANNELS];
new g_iGreenValue[MAX_CHANNELS];
new g_iBlueValue[MAX_CHANNELS];
new g_iAlphaValue[MAX_CHANNELS];
new g_iEffectValue[MAX_CHANNELS];
new bool:g_bChannelEnabled[MAX_CHANNELS];
new bool:g_bTeamColor[MAX_CHANNELS];
new Float:g_flHoldTime[MAX_CHANNELS];
new Float:g_flXPosition[MAX_CHANNELS];
new Float:g_flYPosition[MAX_CHANNELS];
new Float:g_flStartTime[MAX_CHANNELS];
new String:g_strMessage[MAX_CHANNELS][255];

// ====[ PLUGIN ]==============================================================
public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = "ReFlex",
	description = "Add a custom hud logo for everyone to see",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1664292"
}

// ====[ EVENTS ]==============================================================
public OnPluginStart()
{
	CreateConVar("sm_logo_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);

	g_hCvarEnabled = CreateConVar("sm_logo_enabled", "1", "Enable Server Hud Logo\n0 = Disabled\n1 = Enabled", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_bCvarEnabled = GetConVarBool(g_hCvarEnabled);
	HookConVarChange(g_hCvarEnabled, ConVarChange);

	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_team", Event_PlayerChangeTeam);

	RegAdminCmd("sm_serverlogo_reload", Command_Reload, ADMFLAG_ROOT);

	for(new iChannel = 0; iChannel < MAX_CHANNELS; iChannel++)
	{
		g_hHudSync[iChannel] = CreateHudSynchronizer();
		if(g_hHudSync[iChannel] == INVALID_HANDLE)
			SetFailState("HUD synchronisation is not supported by this mod");
	}

	BuildPath(Path_SM, g_strConfigFile, sizeof(g_strConfigFile), "configs/serverhudlogo.cfg");
}

public ConVarChange(Handle:hConvar, const String:strOldValue[], const String:strNewValue[])
{
	if(hConvar == g_hCvarEnabled)
		g_bCvarEnabled = GetConVarBool(g_hCvarEnabled);
}

public OnConfigsExecuted()
{
	if(!FileExists(g_strConfigFile))
	{
		SetFailState("Configuration file %s not found!", g_strConfigFile);
		return;
	}

	new Handle:hKeyValues = CreateKeyValues("Server Hud Logo");
	if(!FileToKeyValues(hKeyValues, g_strConfigFile) || !KvGotoFirstSubKey(hKeyValues))
	{
		SetFailState("Improper structure for configuration file %s!", g_strConfigFile);
		return;
	}

	for(new iChannel = 0; iChannel < MAX_CHANNELS; iChannel++)
	{
		g_bChannelEnabled[iChannel] = false;
		g_iRedValue[iChannel] = 0;
		g_iGreenValue[iChannel] = 0;
		g_iBlueValue[iChannel] = 0;
		g_iAlphaValue[iChannel] = 0;
		g_iEffectValue[iChannel] = 0;
		g_bTeamColor[iChannel] = false;
		g_flHoldTime[iChannel] = 0.0;
		g_flXPosition[iChannel] = -1.0;
		g_flYPosition[iChannel] = -1.0;
		g_flStartTime[iChannel] = -1.0;
		strcopy(g_strMessage[iChannel], sizeof(g_strMessage[]), "");
	}

	new iChannel;
	do
	{
		g_bChannelEnabled[iChannel] = true;
		g_iRedValue[iChannel] = KvGetNum(hKeyValues, "red");
		g_iGreenValue[iChannel] = KvGetNum(hKeyValues, "green");
		g_iBlueValue[iChannel] = KvGetNum(hKeyValues, "blue");
		g_iAlphaValue[iChannel] = KvGetNum(hKeyValues, "alpha");
		g_iEffectValue[iChannel] = KvGetNum(hKeyValues, "effect");
		g_bTeamColor[iChannel] = bool:KvGetNum(hKeyValues, "teamcolor");
		g_flHoldTime[iChannel] = KvGetFloat(hKeyValues, "holdtime");
		g_flXPosition[iChannel] = KvGetFloat(hKeyValues, "xposition");
		g_flYPosition[iChannel] = KvGetFloat(hKeyValues, "yposition");
		g_flStartTime[iChannel] = KvGetFloat(hKeyValues, "startime");
		KvGetString(hKeyValues, "message", g_strMessage[iChannel], sizeof(g_strMessage[]));
		iChannel++;
	}
	while(KvGotoNextKey(hKeyValues, false));
	CloseHandle(hKeyValues);
}

public Action:Event_PlayerSpawn(Handle:hEvent, const String:strName[], bool:bBroadcast)
{
	if(!g_bCvarEnabled)
		return;

	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(!IsValidClient(iClient) || IsFakeClient(iClient))
		return;

	for(new iChannel = 0; iChannel < MAX_CHANNELS; iChannel++)
	{
		if(g_bChannelEnabled[iChannel])
		{
			new Handle:hDataPack;
			CreateDataTimer(g_flStartTime[iChannel], Timer_ServerHudLogo, hDataPack, TIMER_FLAG_NO_MAPCHANGE);
			WritePackCell(hDataPack, GetClientUserId(iClient));
			WritePackCell(hDataPack, iChannel);
		}
	}
}

public Action:Event_PlayerDeath(Handle:hEvent, const String:strName[], bool:bBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(!IsValidClient(iClient))
		return;

	for(new iChannel = 0; iChannel < MAX_CHANNELS; iChannel++)
		ClearSyncHud(iClient, g_hHudSync[iChannel]);
}

public Action:Event_PlayerChangeTeam(Handle:hEvent, const String:strName[], bool:bBroadcast)
{
	if(!g_bCvarEnabled)
		return;

	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(!IsValidClient(iClient) || IsFakeClient(iClient) || GetEventInt(hEvent, "team") > 1)
		return;

	for(new iChannel = 0; iChannel < MAX_CHANNELS; iChannel++)
	{
		ClearSyncHud(iClient, g_hHudSync[iChannel]);
		if(g_bChannelEnabled[iChannel])
		{
			new Handle:hDataPack;
			CreateDataTimer(0.2, Timer_ServerHudLogo, hDataPack, TIMER_FLAG_NO_MAPCHANGE);
			WritePackCell(hDataPack, GetClientUserId(iClient));
			WritePackCell(hDataPack, iChannel);
		}
	}
}

// ====[ COMMANDS ]============================================================
public Action:Command_Reload(iClient, iArgs)
{
	OnConfigsExecuted();
	ReplyToCommand(iClient, "[SM] Server Hud Logo config (%s) reloaded.", g_strConfigFile);
}

// ====[ TIMERS ]==============================================================
public Action:Timer_ServerHudLogo(Handle:hTimer, Handle:hDataPack)
{
	if(!g_bCvarEnabled)
		return;

	ResetPack(hDataPack);

	new iUserId = ReadPackCell(hDataPack);
	new iClient = GetClientOfUserId(iUserId);
	if(!IsValidClient(iClient))
		return;

	if(!IsPlayerAlive(iClient) && GetClientTeam(iClient) > 1)
		return;

	new iChannel = ReadPackCell(hDataPack);
	if(!g_bChannelEnabled[iChannel])
		return;

	if(g_bTeamColor[iChannel])
	{
		switch(GetClientTeam(iClient))
		{
			case 2:
			{
				if(g_flHoldTime[iChannel] >= 0 && g_flHoldTime[iChannel] < 1)
					SetHudTextParams(g_flXPosition[iChannel], g_flYPosition[iChannel], 604800.0, 255, 64, 64, g_iAlphaValue[iChannel], g_iEffectValue[iChannel]);
				else
					SetHudTextParams(g_flXPosition[iChannel], g_flYPosition[iChannel], g_flHoldTime[iChannel], 255, 64, 64, g_iAlphaValue[iChannel], g_iEffectValue[iChannel]);
			}
			case 3:
			{
				if(g_flHoldTime[iChannel] >= 0 && g_flHoldTime[iChannel] < 1)
					SetHudTextParams(g_flXPosition[iChannel], g_flYPosition[iChannel], 604800.0, 153, 204, 255, g_iAlphaValue[iChannel], g_iEffectValue[iChannel]);
				else
					SetHudTextParams(g_flXPosition[iChannel], g_flYPosition[iChannel], g_flHoldTime[iChannel], 153, 204, 255, g_iAlphaValue[iChannel], g_iEffectValue[iChannel]);
			}
			default:
			{
				if(g_flHoldTime[iChannel] >= 0 && g_flHoldTime[iChannel] < 1)
					SetHudTextParams(g_flXPosition[iChannel], g_flYPosition[iChannel], 604800.0, 204, 204, 204, g_iAlphaValue[iChannel], g_iEffectValue[iChannel]);
				else
					SetHudTextParams(g_flXPosition[iChannel], g_flYPosition[iChannel], g_flHoldTime[iChannel], 204, 204, 204, g_iAlphaValue[iChannel], g_iEffectValue[iChannel]);
			}
		}
	}
	else
	{
		if(g_flHoldTime[iChannel] >= 0 && g_flHoldTime[iChannel] < 1)
			SetHudTextParams(g_flXPosition[iChannel], g_flYPosition[iChannel], 604800.0, g_iRedValue[iChannel], g_iGreenValue[iChannel], g_iBlueValue[iChannel], g_iAlphaValue[iChannel], g_iEffectValue[iChannel]);
		else
			SetHudTextParams(g_flXPosition[iChannel], g_flYPosition[iChannel], g_flHoldTime[iChannel], g_iRedValue[iChannel], g_iGreenValue[iChannel], g_iBlueValue[iChannel], g_iAlphaValue[iChannel], g_iEffectValue[iChannel]);
	}

	ShowSyncHudText(iClient, g_hHudSync[iChannel], g_strMessage[iChannel]);
}

// ====[ STOCKS ]==============================================================
stock bool:IsValidClient(iClient)
{
	if(iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient))
		return false;
	return true;
}