// This plugin is based on "Survivor Thirdperson" by "SilverShot". | 此插件大部分代码来源于 "SilverShot" 的 "Survivor Thirdperson".

public Plugin myinfo =
{
    name        = "[L4D2] Melee Auto Thirdperson",
    author      = "yuzumi",
    description = "Switch to thirdperson when using melee weapons.",
    version     = "1.0.0",
    url         = "https://github.com/joyrhyme/L4D2-Plugins/tree/main/Melee_Auto_Thirdperson"
}

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <clientprefs>

#define PLUGIN_VERSION				"1.0.0"
#define DEBUG 						0
#define CVAR_FLAGS					FCVAR_NOTIFY
#define CVAR_FLAGS_PLUGIN_VERSION	FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_SPONLY
#define SEQUENCE_NI					667	// Nick
#define SEQUENCE_RO					674	// Rochelle, Adawong
#define SEQUENCE_CO					656	// Coach
#define SEQUENCE_EL					671	// Ellis
#define SEQUENCE_BI					759	// Bill
#define SEQUENCE_ZO					819	// Zoey
#define SEQUENCE_FR					762	// Francis
#define SEQUENCE_LO					759	// Louis
#define TEAM_SPECTATOR				1 // 旁观者
#define TEAM_SURVIVOR				2 // 幸存者
#define TEAM_INFECTED				3 // 感染者
#define TEAM_HOLDOUT				4 // 1代NPC(消逝 桥上的1代支援NPC)
//#define TRANSLATION					"melee_auto_thirdperson.phrases"

ConVar 
    g_hCvar_Enabled,
    g_hCvar_EnabledChainsaw;

bool 
    g_bInited,
    g_bCvarEnabled,
    g_bCvarEnableChainsaw,
    g_bThirdView[MAXPLAYERS+1],
    g_bMountedGun[MAXPLAYERS+1],
    g_bAutoSwitch[MAXPLAYERS+1] = {true, ...};

Handle
	g_hCookies,
    g_hTimerReset[MAXPLAYERS+1],
    g_hTimerGun;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	//LoadTranslations(TRANSLATION);

	CreateConVar("l4d2_third_version", PLUGIN_VERSION, "Melee Auto Thirdperson plugin version.", CVAR_FLAGS_PLUGIN_VERSION);
	g_hCvar_Enabled =			CreateConVar("melee_auto_3th_enable",		"1",		"0=Plugin off, 1=Plugin on.", CVAR_FLAGS);
	g_hCvar_EnabledChainsaw =	CreateConVar("melee_auto_3th_chainsaw",		"1",		"Enable auto third when using chainsaw", CVAR_FLAGS);
	//AutoExecConfig(true, "l4d2_melee_auto_3th");

	// 注册cookies数据库
	g_hCookies = RegClientCookie("melee_auto_third", "Melee Auto Thirdperson", CookieAccess_Protected);
	RegConsoleCmd("sm_auto_third", Command_SwitchStatus, "Switch thirdperson status");

	g_hCvar_Enabled.AddChangeHook(Event_ConVarChanged);
	g_hCvar_EnabledChainsaw.AddChangeHook(Event_ConVarChanged);
}

public void OnPluginEnd()
{
	ResetPlugin();
}

public void OnConfigsExecuted()
{
    Init();
}

void Event_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    Init();
}

void Init()
{
	g_bCvarEnabled = g_hCvar_Enabled.BoolValue;
	g_bCvarEnableChainsaw = g_hCvar_EnabledChainsaw.BoolValue;

    // 如果没进行过初始化且插件状态为开启
	if(!g_bInited && g_bCvarEnabled)
	{
		for(int i = 1; i <= MaxClients; ++i)
		{
            // TODO 加载数据库信息写入autoswitch

			if(IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == TEAM_SURVIVOR && IsPlayerAlive(i))
			{
				ClientHooks(i);
			}
		}

		HookEvent("player_spawn",			Event_PlayerSpawn);
		HookEvent("round_start",			Event_RoundStart,	EventHookMode_PostNoCopy);
		HookEvent("round_end",				Event_RoundEnd,		EventHookMode_PostNoCopy);
		HookEvent("mounted_gun_start",		Event_MountedGun);
		HookEvent("charger_impact",			Event_ChargerImpact);

		g_bInited = true;
	}
    // 如果已初始化过切插件状态为关闭
	else if (g_bInited && !g_bCvarEnabled)
	{
        // 重置插件
		ResetPlugin();
        // 移除计时器
		delete g_hTimerGun;

		UnhookEvent("player_spawn",			Event_PlayerSpawn);
		UnhookEvent("round_start",			Event_RoundStart,	EventHookMode_PostNoCopy);
		UnhookEvent("round_end",			Event_RoundEnd,		EventHookMode_PostNoCopy);
		UnhookEvent("mounted_gun_start",	Event_MountedGun);
		UnhookEvent("charger_impact",		Event_ChargerImpact);

		g_bInited = false;
	}
}

void ResetPlugin()
{
	for( int i = 1; i <= MaxClients; ++i )
	{
		if(IsClientInGame(i) && IsPlayerAlive(i))
		{
			g_bMountedGun[i] = false;
			g_bThirdView[i] = false;
			Set1stPerson(i);
		}
	}
}

public void OnMapEnd()
{
	ResetPlugin();
}

public void OnClientPutInServer(int client)
{
	if (!IsFakeClient(client))
	{
		ClientHooks(client);
	}
}

public void OnClientDisconnect(int client)
{
	delete g_hTimerReset[client];

	if (!IsFakeClient(client) && AreClientCookiesCached(client)) {
		char sCookie[2];
		IntToString(g_bAutoSwitch[client], sCookie, sizeof(sCookie));
		SetClientCookie(client, g_hCookies, sCookie);
	}

	g_bMountedGun[client] = false;
	g_bThirdView[client] = false;
	g_bAutoSwitch[client] = true;
}

public void OnClientCookiesCached(int client)
{
	if (IsFakeClient(client))
		return;

	char sCookie[2];
	GetClientCookie(client, g_hCookies, sCookie, sizeof(sCookie));

	g_bAutoSwitch[client] = view_as<bool>(StringToInt(sCookie));
}

void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	g_bThirdView[client] = false;
	g_bMountedGun[client] = false;

	if (!IsFakeClient(client) && GetClientTeam(client) == TEAM_SURVIVOR)
	{
		ClientHooks(client, true);
	}
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	delete g_hTimerGun;

	for( int i = 1; i <= MaxClients; i++ )
	{
		g_bThirdView[i] = false;
		g_bMountedGun[i] = false;
	}
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	delete g_hTimerGun;
}

void Event_MountedGun(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(g_bThirdView[client])
	{
		g_bMountedGun[client] = true;
		SetEntPropFloat(client, Prop_Send, "m_TimeForceExternalView", 0.0);

		if(g_hTimerGun == null)
		{
			g_hTimerGun = CreateTimer(0.5, TimerCheck, _, TIMER_REPEAT);
		}
	}
}

void Event_ChargerImpact(Event event, const char[] name, bool dontBroadcast)
{
	int userid = event.GetInt("victim");
	int client = GetClientOfUserId(userid);
	if (client)
	{
		if (g_bThirdView[client])
		{
			Set3thPerson(client);
		}
	}
}

Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (g_bThirdView[victim] && damagetype == DMG_CLUB && victim > 0 && victim <= MaxClients && attacker > 0 && attacker <= MaxClients && GetClientTeam(victim) == TEAM_SURVIVOR && GetClientTeam(attacker) == TEAM_INFECTED)
	{
		delete g_hTimerReset[victim];
		g_hTimerReset[victim] = CreateTimer(1.0, TimerReset, GetClientUserId(victim), TIMER_REPEAT);
		Set3thPerson(victim);
	}

	return Plugin_Continue;
}

void OnWeaponSwitchPost(int client, int weapon)
{
	if (!g_bCvarEnabled || !g_bAutoSwitch[client] || GetClientTeam(client) != TEAM_SURVIVOR)
		return;
	
	int playerWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (playerWeapon != weapon)
		return;

	char weaponClassname[36];
	GetEntityClassname(playerWeapon, weaponClassname, sizeof(weaponClassname));

	if (StrEqual(weaponClassname, "weapon_melee") || (g_bCvarEnableChainsaw && StrEqual(weaponClassname, "weapon_chainsaw"))) {
		Set3thPerson(client);
		return;
	} else {
		Set1stPerson(client);
		return;
	}
}

Action TimerReset(Handle timer, any client)
{
	client = GetClientOfUserId(client);
	if(client && g_bThirdView[client])
	{
		Set3thPerson(client);

		// Repeat timer if still in stumble animation
		static char sModel[32];

		GetEntPropString(client, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
		int anim = GetEntProp(client, Prop_Send, "m_nSequence");

		switch( sModel[29] )
		{
			case 'b': // Nick
			{
				if( anim == SEQUENCE_NI ) return Plugin_Continue;
			}
			case 'd', 'w': // Rochelle, Adawong
			{
				if( anim == SEQUENCE_RO ) return Plugin_Continue;
			}
			case 'c': // Coach
			{
				if( anim == SEQUENCE_CO ) return Plugin_Continue;
			}
			case 'h': // Ellis
			{
				if( anim == SEQUENCE_EL ) return Plugin_Continue;
			}
			case 'v': // Bill
			{
				if( anim == SEQUENCE_BI ) return Plugin_Continue;
			}
			case 'n': // Zoey
			{
				if( anim == SEQUENCE_ZO ) return Plugin_Continue;
			}
			case 'e': // Francis
			{
				if( anim == SEQUENCE_FR ) return Plugin_Continue;
			}
			case 'a': // Louis
			{
				if( anim == SEQUENCE_LO ) return Plugin_Continue;
			}
		}
	}

	g_hTimerReset[client] = null;
	return Plugin_Stop;
}

Action TimerCheck(Handle timer)
{
	int count;
	for(int i = 1; i <= MaxClients; ++i)
	{
		if(g_bMountedGun[i] && IsClientInGame(i) && IsPlayerAlive(i))
		{
			if( GetEntProp(i, Prop_Send, "m_usingMountedWeapon") )
			{
				count++;
			}
			else
			{
				Set3thPerson(i);
				g_bMountedGun[i] = false;
			}
		}
	}

	if( count )
		return Plugin_Continue;

	g_hTimerGun = null;
	return Plugin_Stop;
}

void ClientHooks(int client, bool unHookFirst = false)
{
	if (unHookFirst) {
		SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		SDKUnhook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitchPost);
	}
	SDKHook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitchPost);
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

void Set3thPerson(int client)
{
	g_bThirdView[client] = true;
	SetEntPropFloat(client, Prop_Send, "m_TimeForceExternalView", 99999.3);
}

void Set1stPerson(int client)
{
	g_bThirdView[client] = false;
	SetEntPropFloat(client, Prop_Send, "m_TimeForceExternalView", 0.0);
}

Action Command_SwitchStatus(int client, int args)
{
	if(g_bCvarEnabled && client && IsPlayerAlive(client) && GetClientTeam(client) == TEAM_SURVIVOR)
	{
		if (g_bThirdView[client])
			Set1stPerson(client);

		g_bAutoSwitch[client] = !g_bAutoSwitch[client];
		if(g_bAutoSwitch[client])
			PrintToChat(client, "近战自动切换第三人称 已启用. 如果无效请重新切换到近战");
		else
			PrintToChat(client, "近战自动切换第三人称 已禁用.");
	}

	return Plugin_Handled;
}
