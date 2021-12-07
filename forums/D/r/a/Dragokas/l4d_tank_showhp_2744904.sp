#define PLUGIN_VERSION "1.2"

#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>

#define CVAR_FLAGS FCVAR_NOTIFY
#define DEBUG 0

#define COMPONENT_LABEL 		1
#define COMPONENT_BAR 			2
#define COMPONENT_CURRENT_HP 	4
#define COMPONENT_MAX_HP 		8
#define COMPONENT_NAME 			16
#define COMPONENT_ALL 			31

public Plugin myinfo =
{
	name = "[L4D1 & L4D2] Tank Show HP",
	author = "Alex Dragokas",
	description = "Show tank's HP on the center screen when you are shooting him",
	version = PLUGIN_VERSION,
	url = "http://dragokas.com/"
};

/*
	ChangeLog:
	
	1.0
	 - First release
	 
	1.1 (27-Apr-2020)
	 - Fixed to show more than 65536 hp
	 
	1.2 (25-Apr-2021)
	 - Added late loading support.
	 - Added ConVar "l4d_showtankhp_components" - HP line components (1 - label 'HP', 2 - Bar, 4 - Current HP, 8 - Max HP, 16 - Tank name. You can combine)
	 - Added ConVar "l4d_showtankhp_kill_msg" - Show tank kill message? (1 - Yes, 0 - No)
*/

ConVar g_hCvarEnable, g_hCvarComponents, g_hCvarKillMsg;
bool g_bEnabled, g_bLeft4Dead2, g_bKillMsg, g_bLateload;
char g_sScale[40][41];
int g_iScaleSize, g_iComponents, g_iPrevHP[MAXPLAYERS+1] = {999999, ...};
float g_fLastTime[MAXPLAYERS+1];

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if (test == Engine_Left4Dead2) {
		g_bLeft4Dead2 = true;		
	}
	else if (test != Engine_Left4Dead) {
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	g_bLateload = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("l4d_showtankhp_version", PLUGIN_VERSION, "L4D Infected HP version", CVAR_FLAGS | FCVAR_DONTRECORD);

	g_hCvarEnable 		= CreateConVar("l4d_showtankhp_enable", 		"1", 	"Enable plugin (1 - Yes, 0 - No)", CVAR_FLAGS );
	g_hCvarComponents 	= CreateConVar("l4d_showtankhp_components", 	"31", 	"HP line components (1 - label 'HP', 2 - Bar, 4 - Current HP, 8 - Max HP, 16 - Tank name. You can combine)", CVAR_FLAGS );
	g_hCvarKillMsg 		= CreateConVar("l4d_showtankhp_kill_msg", 		"1", 	"Show tank kill message? (1 - Yes, 0 - No)", CVAR_FLAGS );
	
	AutoExecConfig(true, "l4d_showtankhp");
	
	for( int i = 0; i < sizeof(g_sScale); i++ ) // prepare progressbar strings in advance (pre-cache)
	{
		for( int k = 0; k < i; k++ )
		{
			g_sScale[i][k] = '#';
		}
		for( int k = i; k < sizeof(g_sScale); k++ )
		{
			g_sScale[i][k] = '-';
		}
	}
	
	g_iScaleSize = sizeof(g_sScale);
	
	GetCvars();

	g_hCvarEnable.AddChangeHook(OnCvarChanged);
	g_hCvarComponents.AddChangeHook(OnCvarChanged);
	g_hCvarKillMsg.AddChangeHook(OnCvarChanged);
	
	if( g_bLateload )
	{
		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsTank(i) )
			{
				g_iPrevHP[i] = GetEntProp(i, Prop_Data, "m_iHealth");
			}
		}
	}
}


public void OnCvarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_bEnabled = g_hCvarEnable.BoolValue;
	g_iComponents = g_hCvarComponents.IntValue;
	g_bKillMsg = g_hCvarKillMsg.BoolValue;
	InitHook();
}

void InitHook()
{
	static bool bHooked;
	
	if( g_bEnabled ) {
		if( !bHooked ) {
			HookEvent("player_hurt", 		Event_OnPlayerHurt	);
			HookEvent("tank_spawn", 		Event_OnTankSpawned	);
			HookEvent("tank_killed", 		Event_OnTankKilled 	);
			bHooked = true;
		}
	} else {
		if( bHooked ) {
			UnhookEvent("player_hurt", 		Event_OnPlayerHurt	);
			UnhookEvent("tank_spawn", 		Event_OnTankSpawned	);
			UnhookEvent("tank_killed", 		Event_OnTankKilled	);
			bHooked = false;
		}
	}
}

public void Event_OnTankSpawned(Event event, const char[] name, bool dontBroadcast)
{
	int tank = GetClientOfUserId(event.GetInt("userid"));
	g_iPrevHP[tank] = 999999;
}

public void Event_OnPlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	float fNow = GetEngineTime();
	
	if( fNow - g_fLastTime[attacker] < 1.0 )
	{
		return;
	}
	g_fLastTime[attacker] = fNow;

	if( !attacker || !IsClientInGame(attacker) || IsFakeClient(attacker) )
	{
		return;
	}
	
	int tank = GetClientOfUserId(event.GetInt("userid"));
	if ( !IsTank(tank) )
	{
		return;
	}
	
	if( g_iPrevHP[tank] == 0 )
	{
		return;
	}

	int nowHP = event.GetInt("health");
	if( nowHP < 0 ) {
		nowHP = 0;
	}
	
	int maxHP = GetEntProp(tank, Prop_Data, "m_iMaxHealth");
	if( maxHP < 1) {
		maxHP = 1;
	}

	if( nowHP > (g_iPrevHP[tank] + 2000) )
	{
		g_iPrevHP[tank] = 0;
		return;
	}
	g_iPrevHP[tank] = nowHP;
	
	int idx = nowHP * (g_iScaleSize - 1) / maxHP;
	
	#if DEBUG
	if( GetUserFlagBits(attacker) & ADMFLAG_ROOT )
	{
		PrintToChat(attacker, "idx: %i. now: %i. Max: %i", idx, nowHP, maxHP);
	}
	#endif
	
	if( idx >= g_iScaleSize )
	{
		idx = 0;
	}
	
	if( g_iComponents == COMPONENT_ALL )
	{
		PrintCenterText(attacker, "HP: |%s|  [%d / %d]  %N", g_sScale[idx], nowHP, maxHP, tank);
	}
	else {
		char bar[128];
		if( g_iComponents & COMPONENT_LABEL )
		{
			StrCat(bar, sizeof(bar), "HP: ");
		}
		if( g_iComponents & COMPONENT_BAR )
		{
			Format(bar, sizeof(bar), "%s|%s|", bar, g_sScale[idx]);
		}
		if( g_iComponents & COMPONENT_CURRENT_HP )
		{
			Format(bar, sizeof(bar), "%s  [%d", bar, nowHP);
		}
		if( g_iComponents & COMPONENT_MAX_HP )
		{
			Format(bar, sizeof(bar), "%s / %d]", bar, maxHP);
		}
		else {
			StrCat(bar, sizeof(bar), "]");
		}
		if( g_iComponents & COMPONENT_NAME )
		{
			Format(bar, sizeof(bar), "%s  %N", bar, tank);
		}
		PrintCenterText(attacker, bar);
	}
}

public void Event_OnTankKilled(Event event, const char[] name, bool dontBroadcast)
{
	if( !g_bKillMsg )
		return;

	int tank = GetClientOfUserId(event.GetInt("userid"));
	
	if( tank && IsClientInGame(tank) )
	{
		PrintHintTextToAll("++ %N is DEAD ++", tank);
	}
}

stock bool IsTank(int client)
{
	if( 0 < client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3 )
	{
		int class = GetEntProp(client, Prop_Send, "m_zombieClass");
		if( class == (g_bLeft4Dead2 ? 8 : 5 ) )
			return true;
	}
	return false;
}