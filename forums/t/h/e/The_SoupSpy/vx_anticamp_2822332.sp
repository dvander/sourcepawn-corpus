#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <devzones>
#include <multicolors>

#define ZONE_PREFIX "anticamp"

#define SOUND_THUNDER "ambient/explosions/explode_9.wav"
#define SOUND_ALARM "buttons/button17.wav"

#define CT 3
#define TT 2
#define ALL 0

#define reset_timeronly 0
#define reset_all 1

public Plugin myinfo = 
{
	name = "SM DEV Zones - VXAntiRush", 
	author = "Yekta.T", 
	description = "", 
	version = "0.2.4", 
	url = "vortexguys.com"
};

ConVar g_cAllowedTime;
ConVar g_cTimeBeforeReset;
ConVar g_cPluginEnabled;
ConVar g_cPrefix;

bool g_cbPluginEnabled = true;
bool g_bRoundStarted = false;

int g_cfAllowedTime;
int g_iClientTimeleft[MAXPLAYERS + 1];
int g_SmokeSprite;
int g_LightningSprite;

char prefix[66] = "{red}[ {olive}VortéX Anti-Camp {red}]";

float g_cfTimeBeforeReset;

Handle g_hClientTimer[MAXPLAYERS + 1] = { INVALID_HANDLE, ... };
Handle g_hClientLeftTimer[MAXPLAYERS + 1] = { INVALID_HANDLE, ... };

public void OnPluginStart()
{
	g_cPluginEnabled = CreateConVar("sm_vxanticamp_enable", "1", "1->Plugin enabled, 0->Plugin disabled", _, true, 0.0, true, 1.0);
	g_cAllowedTime = CreateConVar("sm_vxanticamp_time", "30", "Allowed camp time", _, true, 10.0);
	g_cTimeBeforeReset = CreateConVar("sm_vxanticamp_lefttime", "15", "Time before camp time gets reset after leaving a zone");
	g_cPrefix = CreateConVar("sm_vxanticamp_prefix", "{red}[ {olive}VortéX Anti-Camp {red}]", "Prefix");
	
	HookConVarChange(g_cAllowedTime, Callback_ConVarChange);
	HookConVarChange(g_cTimeBeforeReset, Callback_ConVarChange);
	HookConVarChange(g_cPluginEnabled, Callback_ConVarChange);
	HookConVarChange(g_cPrefix, Callback_ConVarChange);
	
	HookEvent("round_end", Callback_RoundEnd);
	HookEvent("round_start", Callback_RoundStart);
	HookEvent("player_spawn", Callback_PlayerSpawn);
	
	AutoExecConfig(true, "vx_anticamp");
	LoadTranslations("vx_anticamp.phrases");
}

public void OnMapStart()
{
	PrecacheSound(SOUND_THUNDER, true);
	PrecacheSound(SOUND_ALARM, true);
	g_SmokeSprite = PrecacheModel("sprites/steam1.vmt");
	g_LightningSprite = PrecacheModel("sprites/lgtning.vmt");
	g_bRoundStarted = true;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i, false, true))
		{
			g_iClientTimeleft[i] = g_cfAllowedTime;
		}
	}
}

public void OnConfigsExecuted()
{
	g_cfAllowedTime = GetConVarInt(g_cAllowedTime);
	g_cfTimeBeforeReset = GetConVarInt(g_cTimeBeforeReset) * 1.0;
	g_cbPluginEnabled = GetConVarBool(g_cPluginEnabled);
	GetConVarString(g_cPrefix, prefix, sizeof(prefix));
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i, false, true))
		{
			VX_ResetClient(i, reset_all);
		}
	}
}

public void OnClientPutInServer(int client)
{
	if (g_cbPluginEnabled)
		VX_ResetClient(client, reset_all);
}

public void Callback_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	g_bRoundStarted = false;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i, false, true))
		{
			VX_ResetClient(i, reset_all);
		}
	}
}

public void Callback_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_bRoundStarted = true;
}

public void Callback_PlayerSpawn(Event event, const char[] name, bool dbc)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (g_hClientTimer[client] != INVALID_HANDLE)
	{
		if (IsValidClient(client, false, false))
		{
			VX_ResetClient(client, reset_all);
		}
	}
}

char gsClientZone[MAXPLAYERS + 1][250];

public void Zone_OnClientEntry(int client, const char[] zone)
{
	if (!IsValidClient(client, false, false))return;
	
	if (StrContains(zone, ZONE_PREFIX, false) == 0)
	{
		if (!g_cbPluginEnabled)return;
		
		int iTeam = GetClientTeam(client);
		if (!(iTeam == CT || iTeam == TT))return;
		
		char sTeam[2][11]; ExplodeString(zone, ":", sTeam, 2, 11);
		if ((!StrEqual(sTeam[1], "") || !StrEqual(sTeam[1], "all")) && 
			((StrEqual(sTeam[1], "ct", false) && iTeam != CT) || 
				(StrEqual(sTeam[1], "t", false) && iTeam != TT)))
		return;
		
		VX_ResetClient(client, reset_timeronly);
		VX_DisplayTimerCountdown(client);
		FormatEx(gsClientZone[client], 250, zone);
	}
}

public Action Timer_inZone(Handle timer, any client)
{
	if (!g_cbPluginEnabled || !IsValidClient(client, false, false))
	{
		VX_ResetClient(client, reset_all);
		return Plugin_Handled;
	}
	
	if (!g_bRoundStarted)return Plugin_Handled;
	if (!Zone_IsClientInZone(client, gsClientZone[client], true, false))
	{
		VX_ResetClient(client, reset_timeronly);
	}
	
	char sztext[MAX_MESSAGE_LENGTH];
	SetGlobalTransTarget(client);
	Format(sztext, MAX_MESSAGE_LENGTH, "%t", "inAntiCampZone", --g_iClientTimeleft[client]);
	PrintCenterText(client, "%s", sztext);
	
	if (g_iClientTimeleft[client] <= 10)
		VX_PlayInformSound(client);
	
	if (g_iClientTimeleft[client] <= 0)
	{
		VX_PerformSmite(client);
		VX_ResetClient(client, reset_all);
		PrintCenterText(client, "%t", "Smote");
		char sName[32]; GetClientName(client, sName, 32);
		CPrintToChatAll("%s %t", prefix, "Smotetext", sName);
		return Plugin_Handled;
	}
	
	
	return Plugin_Handled;
}

public void Zone_OnClientLeave(int client, const char[] zone)
{
	if (!IsValidClient(client, false, false))return;
	
	if (StrContains(zone, ZONE_PREFIX, false) == 0)
	{
		if (g_hClientTimer[client] == INVALID_HANDLE)return;
		if (!g_cbPluginEnabled)return;
		
		int iTeam = GetClientTeam(client);
		if (!(iTeam == CT || iTeam == TT))return;
		
		VX_ResetClient(client, reset_timeronly);
		VX_CreateLeftTimerCountdown(client);
	}
}

public void Callback_ConVarChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (StrEqual(oldValue, newValue, false))return;
	
	if (convar == g_cAllowedTime)
	{
		g_cfAllowedTime = StringToInt(newValue);
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i, false, true))
			{
				g_iClientTimeleft[i] = g_cfAllowedTime;
			}
		}
	} else if (convar == g_cTimeBeforeReset)
	{
		g_cfTimeBeforeReset = StringToInt(newValue) * 1.0;
	} else if (convar == g_cPluginEnabled)
	{
		g_cbPluginEnabled = StringToInt(newValue) == 1 ? true:false;
	} else if (convar == g_cPrefix)
		GetConVarString(g_cPrefix, prefix, sizeof(prefix));
}

void VX_DisplayTimerCountdown(int client)
{
	PrintHintText(client, "");
	PrintCenterText(client, "%t", "inAntiCampZone", g_iClientTimeleft[client]);
	g_hClientTimer[client] = CreateTimer(1.0, Timer_inZone, client, TIMER_REPEAT);
}

void VX_CreateLeftTimerCountdown(int client)
{
	PrintCenterText(client, "");
	PrintHintText(client, "%t", "LeftZone", g_cfTimeBeforeReset);
	g_hClientLeftTimer[client] = CreateTimer(g_cfTimeBeforeReset, Timer_leftZone, client, TIMER_REPEAT);
}

public Action Timer_leftZone(Handle timer, any client)
{
	if (!g_cbPluginEnabled || !IsValidClient(client, false, true))
	{
		VX_ResetClient(client, reset_all);
		return Plugin_Handled;
	}
	
	VX_ResetClient(client, reset_all);
	
	return Plugin_Handled;
}

void VX_ResetClient(int id, int resettype = reset_all)
{
	if (resettype != reset_timeronly)
	{
		g_iClientTimeleft[id] = g_cfAllowedTime;
		FormatEx(gsClientZone[id], 250, "");
	}
	
	if (g_hClientTimer[id] != INVALID_HANDLE)
	{ KillTimer(g_hClientTimer[id]); g_hClientTimer[id] = INVALID_HANDLE; }
	
	if (g_hClientLeftTimer[id] != INVALID_HANDLE)
	{ KillTimer(g_hClientLeftTimer[id]); g_hClientLeftTimer[id] = INVALID_HANDLE; }
}

void VX_PerformSmite(int target)
{
	
	float clientpos[3];
	GetClientAbsOrigin(target, clientpos);
	clientpos[2] -= 26;
	
	int randomx = GetRandomInt(-500, 500);
	int randomy = GetRandomInt(-500, 500);
	
	float startpos[3];
	startpos[0] = clientpos[0] + randomx;
	startpos[1] = clientpos[1] + randomy;
	startpos[2] = clientpos[2] + 800;
	
	int color[4] = { 255, 255, 255, 255 };
	
	float dir[3] = { 0.0, 0.0, 0.0 };
	
	TE_SetupBeamPoints(startpos, clientpos, g_LightningSprite, 0, 0, 0, 0.2, 20.0, 10.0, 0, 1.0, color, 3);
	TE_SendToAll();
	
	TE_SetupSparks(clientpos, dir, 5000, 1000);
	TE_SendToAll();
	
	TE_SetupEnergySplash(clientpos, dir, false);
	TE_SendToAll();
	
	TE_SetupSmoke(clientpos, g_SmokeSprite, 5.0, 10);
	TE_SendToAll();
	
	EmitAmbientSound(SOUND_THUNDER, startpos, target, SNDLEVEL_RAIDSIREN);
	
	ForcePlayerSuicide(target);
}

void VX_PlayInformSound(int client)
{
	EmitSoundToClient(client, SOUND_ALARM);
}

stock bool IsValidClient(int client, bool AllowBots = false, bool AllowDead = false)
{
	if (!(1 <= client <= MaxClients) || !IsClientInGame(client) || (IsFakeClient(client) && !AllowBots) || IsClientSourceTV(client) || IsClientReplay(client) || (!AllowDead && !IsPlayerAlive(client)))
	{
		return false;
	}
	return true;
} 