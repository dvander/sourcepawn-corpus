#pragma semicolon 1

// ====[ TABLE OF CONTENTS ]===================================================
//
// INCLUDES - 17
// DEFINES - 20
// CVARS | HANDLES - 23
// VARIABLES - 30
// PLUGIN - 36
// FUNCTIONS - 58
// EVENTS - 104
// TIMERS - 121
// STOCKS - 139
//
// ============================================================================

// ====[ INCLUDES ]============================================================
#include <sourcemod>

// ====[ DEFINES ]=============================================================
#define PLUGIN_VERSION		"1.1.0"

// ====[ CVARS | HANDLES ]=====================================================
new Handle:cvarEnabled;
new Handle:cvarTime;
new Handle:cvarAmount;
new Handle:cvarAdmins;
new Handle:g_hTimerCash;

// ====[ VARIABLES ]===========================================================
new bool:g_bEnabled;
new g_iAmount;
new bool:g_bAdmins;
new Float:g_fTime;

// ====[ PLUGIN ]==============================================================
public APLRes:AskPluginLoad2(Handle:hMyself, bool:bLate, String:strError[], iMax)
{
	decl String:strGame[32];
	GetGameFolderName(strGame, sizeof(strGame));
	if(!StrEqual(strGame, "tf"))
	{
		Format(strError, iMax, "This plugin only works for Team Fortress 2");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

public Plugin:myinfo =
{
	name = "MvM Cash Regen",
	author = "ReFlexPoison",
	description = "Regenerates player's cash overtime during MvM rounds",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
}

// ====[ FUNCTIONS ]===========================================================
public OnPluginStart()
{
	CreateConVar("sm_cashregen_version", PLUGIN_VERSION, "MvM Cash Regen Version", FCVAR_REPLICATED | FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);

	cvarEnabled = CreateConVar("sm_cashregen_enabled", "1", "Enable MvM Cash Regen\n0 = Disabled\n1 = Enabled", _, true, 0.0, true, 1.0);
	HookConVarChange(cvarEnabled, CVarChange);
	g_bEnabled = GetConVarBool(cvarEnabled);

	cvarAmount = CreateConVar("sm_cashregen_amount", "5", "Amount of money generated per increment", _, true, 0.0, true, 1000.0);
	HookConVarChange(cvarAmount, CVarChange);
	g_iAmount = GetConVarInt(cvarAmount);

	cvarAdmins = CreateConVar("sm_cashregen_admins", "0", "Money regen for admins only\n0 = Disabled\n1 = Enabled", _, true, 0.0, true, 1.0);
	HookConVarChange(cvarAdmins, CVarChange);
	g_bAdmins = GetConVarBool(cvarAdmins);

	cvarTime = CreateConVar("sm_cashregen_time", "5", "Time between cash regens", _, true, 0.0);
	HookConVarChange(cvarTime, CVarChange);
	g_fTime = GetConVarFloat(cvarTime);

	HookEvent("mvm_begin_wave", OnRoundStart);
	HookEvent("mvm_wave_complete", OnRoundEnd);

	AutoExecConfig(true, "plugin.cashregen");
}

public CVarChange(Handle:hConvar, const String:strOldValue[], const String:strNewValue[])
{
	if(hConvar == cvarEnabled)
		g_bEnabled = GetConVarBool(cvarEnabled);
	if(hConvar == cvarAmount)
		g_iAmount = GetConVarInt(cvarAmount);
	if(hConvar == cvarAdmins)
		g_bAdmins = GetConVarBool(cvarAdmins);
	if(hConvar == cvarTime)
	{
		g_fTime = GetConVarFloat(cvarTime);
		if(g_hTimerCash != INVALID_HANDLE)
		{
			ClearTimer(g_hTimerCash);
			g_hTimerCash = CreateTimer(g_fTime, Timer_Cash, _, TIMER_REPEAT);
		}
	}
}

// ====[ EVENTS ]==============================================================
public OnMapEnd()
{
	ClearTimer(g_hTimerCash);
}

public OnRoundStart(Handle:hEvent, const String:strName[], bool:bBroadcast)
{
	ClearTimer(g_hTimerCash);
	g_hTimerCash = CreateTimer(g_fTime, Timer_Cash, _, TIMER_REPEAT);
}

public OnRoundEnd(Handle:hEvent, const String:strName[], bool:bBroadcast)
{
	ClearTimer(g_hTimerCash);
}

// ====[ TIMERS ]==============================================================
public Action:Timer_Cash(Handle:hTimer)
{
	if(!g_bEnabled)
		return Plugin_Continue;

	for(new i = 1; i <= MaxClients; i++) if(IsValidClient(i))
	{
		new iCurrentCash = GetEntProp(i, Prop_Send, "m_nCurrency");
		if(!g_bAdmins || (CheckCommandAccess(i, "sm_cashregen_flag", ADMFLAG_GENERIC, false) && g_bAdmins))
		{
			if(iCurrentCash <= 32767 - g_iAmount)
				SetEntProp(i, Prop_Send, "m_nCurrency", iCurrentCash + g_iAmount);
		}
	}
	return Plugin_Continue;
}

// ====[ STOCKS ]==============================================================
stock IsValidClient(iClient, bool:bReplay = true)
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