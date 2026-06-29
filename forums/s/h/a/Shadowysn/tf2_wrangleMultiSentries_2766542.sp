#define PLUGIN_NAME		"[TF2] Wrangle Multiple Sentries"
#define PLUGIN_AUTHOR		"FlaminSarge, lobnico, Shadowysn"
#define PLUGIN_DESC		"Allows clients that 'own' multiple sentries to use the Wrangler on all of them properly"
#define PLUGIN_VERSION	"1.12" // as of March 06, 2013
#define PLUGIN_URL		"https://forums.alliedmods.net/showpost.php?p=2766542&postcount=7"
#define PLUGIN_NAME_SHORT	"Wrangle Multiple Sentries"
#define PLUGIN_NAME_TECH	"wranglemultiple"

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <tf2_stocks>

#pragma semicolon 1
#pragma newdecls required

#define AUTOEXEC_CFG "wranglemultiple"

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESC,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
}

bool g_bLateLoad = false;
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion ev = GetEngineVersion();
	if (ev == Engine_TF2)
	{
		g_bLateLoad = late;
		return APLRes_Success;
	}
	strcopy(error, err_max, "Plugin only supports Team Fortress 2.");
	return APLRes_SilentFailure;
}

ConVar hCvarEnabled;
bool bEnabled;
bool bIsWranglerEquipped[MAXPLAYERS+1];

public void OnPluginStart()
{
	static char desc_str[64];
	Format(desc_str, sizeof(desc_str), "%s version.", PLUGIN_NAME_SHORT);
	static char cmd_str[64];
	Format(cmd_str, sizeof(cmd_str), "%s_version", PLUGIN_NAME_TECH);
	ConVar version_cvar = CreateConVar(cmd_str, PLUGIN_VERSION, desc_str, FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	if (version_cvar != null)
		SetConVarString(version_cvar, PLUGIN_VERSION);
	
	Format(cmd_str, sizeof(cmd_str), "%s_enabled", PLUGIN_NAME_TECH);
	hCvarEnabled = CreateConVar(cmd_str, "1", "Enable/Disable wrangling multiple sentries", FCVAR_NONE, true, 0.0, true, 1.0);
	hCvarEnabled.AddChangeHook(CC_WM_Enabled);
	
	AutoExecConfig(true, AUTOEXEC_CFG);
	SetCvarValues();
	
	if (g_bLateLoad)
	{
		for (int client = 1; client <= MAXPLAYERS; client++)
		{
			if (!IsValidClient(client, true, true)) continue;
			CheckWrangler(client);
		}
	}
	
	HookEvent("player_spawn", player_spawn, EventHookMode_Pre);
}

void CC_WM_Enabled(ConVar convar, const char[] oldValue, const char[] newValue)	{ bEnabled =		convar.BoolValue;	}
void SetCvarValues()
{
	CC_WM_Enabled(hCvarEnabled, "", "");
}

void player_spawn(Event event, const char[] name, bool dontBroadcast)
{
	if (!bEnabled) return;
	
	int client = GetClientOfUserId(event.GetInt("userid", 0));
	if (!IsValidClient(client)) return;
	
	SDKHook(client, SDKHook_WeaponSwitch, WeaponSwitch);
}

Action WeaponSwitch(int client, int weapon)
{
	CheckWrangler(client);
	return Plugin_Continue;
}
void CheckWrangler(int client)
{
	bIsWranglerEquipped[client] = false;
	
	static char wep[24];
	GetClientWeapon(client, wep, sizeof(wep));
	if (strcmp(wep, "tf_weapon_laser_pointer", false) != 0) return;
	
	bIsWranglerEquipped[client] = true;
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float ang[3], int& weapon)
{
	if (!bEnabled || !bIsWranglerEquipped[client]) return Plugin_Continue;
	if (!IsValidClient(client, true, true) || !IsPlayerAlive(client)) return Plugin_Continue;
	
	int offs = FindSendPropInfo("CObjectSentrygun", "m_hEnemy");
	int wepent = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	
	if (!RealValidEntity(wepent) || view_as<bool>(GetEntProp(client, Prop_Send, "m_bFeignDeathReady"))) return Plugin_Continue;
	
	if (TF2_IsPlayerInCondition(client, TFCond_Cloaked) || TF2_IsPlayerInCondition(client, TFCond_Bonked)) return Plugin_Continue;
	if (TF2_IsPlayerInCondition(client, TFCond_Dazed) && GetEntProp(client, Prop_Send, "m_iStunFlags") & (TF_STUNFLAG_BONKSTUCK|TF_STUNFLAG_THIRDPERSON)) return Plugin_Continue;
	
	float time = GetGameTime();
	if (time < GetEntPropFloat(client, Prop_Send, "m_flNextAttack")
	|| time < GetEntPropFloat(client, Prop_Send, "m_flStealthNoAttackExpire"))
		return Plugin_Continue;
	
	bool nextprim = time >= GetEntPropFloat(wepent, Prop_Send, "m_flNextPrimaryAttack");
	bool nextsec = time >= GetEntPropFloat(wepent, Prop_Send, "m_flNextSecondaryAttack");
	if (!nextprim && !nextsec) return Plugin_Continue;
	
	int i = -1;
	while ((i = FindEntityByClassname(i, "obj_sentrygun")) != -1)
	{
		if (!RealValidEntity(i)) continue;
		if (GetEntPropEnt(i, Prop_Send, "m_hBuilder") != client || view_as<bool>(GetEntProp(i, Prop_Send, "m_bDisabled"))) continue;
		
		int level = GetEntProp(i, Prop_Send, "m_iUpgradeLevel");
		if (nextsec && level == 3 && buttons & IN_ATTACK2) SetEntData(i, offs+5, 1, 1, true);
		if (nextprim && buttons & IN_ATTACK) SetEntData(i, offs+4, 1, 1, true);
	}
	return Plugin_Continue;
}

bool RealValidEntity(int entity)
{ return (entity > 0 && IsValidEntity(entity)); }

bool IsValidClient(int client, bool replaycheck = true, bool isLoop = false)
{
	if ((isLoop || client > 0 && client <= MaxClients) && IsClientInGame(client) && 
	!GetEntProp(client, Prop_Send, "m_bIsCoaching")) // TF2
	{
		if (replaycheck)
		{
			if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
		}
		return true;
	}
	return false;
}
