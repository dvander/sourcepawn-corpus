#pragma semicolon 1

// ====[ TABLE OF CONTENTS ]===================================================
//
// INCLUDES - 17
// DEFINES - 22
// CVARS | HANDLES - 25
// VARIABLES - 30
// PLUGIN - 37
// FUNCTIONS - 47
// EVENTS - 83
// COMMANDS - 145
// STOCKS - 158
//
// ============================================================================

// ====[ INCLUDES ]============================================================
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

// ====[ DEFINES ]=============================================================
#define PLUGIN_VERSION			"1.0.0"

// ====[ CVARS | HANDLES ]=====================================================
new Handle:cvarEnabled;
new Handle:cvarFallDamage;
new Handle:cvarInform;

// ====[ VARIABLES ]===========================================================
new bool:g_bEnabled;
new bool:g_bFallDamage;
new bool:g_bInform;
new bool:g_bInformed			[MAXPLAYERS + 1];
new bool:g_bHopping				[MAXPLAYERS + 1];

// ====[ PLUGIN ]==============================================================
public Plugin:myinfo =
{
	name = "Simple Bunny Hop",
	author = "ReFlexPoison",
	description = "Let users Bunny Hop with simplicity",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
}

// ====[ FUNCTIONS ]===========================================================
public OnPluginStart()
{
	CreateConVar("sm_bhop_version", PLUGIN_VERSION, "Simple Bunny Hop Version", FCVAR_REPLICATED | FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);

	cvarEnabled	= CreateConVar("sm_bhop_enabled", "1", "Enable Simple Bunny Hop\n0 = Disabled\n1 = Enabled", _, true, 0.0, true, 1.0);
	g_bEnabled = GetConVarBool(cvarEnabled);
	HookConVarChange(cvarEnabled, CVarChange);

	cvarFallDamage = CreateConVar("sm_bhop_falldamage", "1", "Disable fall damage for bhoppers\n0 = Disabled\n1 = Enabled", _, true, 0.0, true, 1.0);
	g_bFallDamage = GetConVarBool(cvarFallDamage);
	HookConVarChange(cvarFallDamage, CVarChange);

	cvarInform = CreateConVar("sm_bhop_inform", "1", "Enable information notification\n0 = Disabled\n1 = Enabled", _, true, 0.0, true, 1.0);
	g_bInform = GetConVarBool(cvarInform);
	HookConVarChange(cvarInform, CVarChange);

	HookEvent("player_spawn", OnPlayerSpawn);

	RegAdminCmd("sm_bhop", BHopCmd, 0, "Enable/Disable Bunny Hopping");

	LoadTranslations("simple-bhop.phrases");

	AutoExecConfig(true, "plugin.simple-bhop");
}

public CVarChange(Handle:hConvar, const String:strOldValue[], const String:strNewValue[])
{
	if(hConvar == cvarEnabled)
		g_bEnabled = GetConVarBool(cvarEnabled);
	if(hConvar == cvarFallDamage)
		g_bFallDamage = GetConVarBool(cvarFallDamage);
	if(hConvar == cvarInform)
		g_bInform = GetConVarBool(cvarInform);
}

// ====[ EVENTS ]==============================================================
public OnClientPutInServer(iClient)
{
	g_bHopping[iClient] = false;
	g_bInformed[iClient] = false;
	SDKHook(iClient, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:OnPlayerSpawn(Handle:hEvent, String:strName[], bool:bDontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(!IsValidClient(iClient))
		return Plugin_Continue;

	if(g_bInform && !g_bInformed[iClient] && CheckCommandAccess(iClient, "sm_bhop", 0))
	{
		SetGlobalTransTarget(iClient);
		PrintToChat(iClient, "%t", "InformBHop");
		g_bInformed[iClient] = true;
	}
	return Plugin_Continue;
}

public Action:OnTakeDamage(iVictim, &iAttacker, &iInflictor, &Float:fDamage, &iType, &iWeapon, Float:fForce[3], Float:fPosition[3], iCustom)
{
	if(!IsValidClient(iVictim) || !g_bFallDamage)
		return Plugin_Continue;

	if(g_bHopping[iVictim] && GetClientButtons(iVictim) & IN_JUMP && iType == DMG_FALL)
	{
		fDamage = 0.0;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action:OnPlayerRunCmd(iClient, &iButtons, &iImpulse, Float:fVel[3], Float:fAngles[3], &iWeapon)
{
	if(!g_bEnabled || !IsValidClient(iClient))
		return Plugin_Continue;

	if(!g_bHopping[iClient] || !CheckCommandAccess(iClient, "sm_bhop", 0))
		return Plugin_Continue;

	if(IsPlayerAlive(iClient) && GetEntityFlags(iClient) & FL_ONGROUND && iButtons & IN_JUMP)
	{
		static Float:fVelocity[3];
		GetEntPropVector(iClient, Prop_Data, "m_vecVelocity", fVelocity);
		fVelocity[2] = 267.0;
		TeleportEntity(iClient, NULL_VECTOR, NULL_VECTOR, fVelocity);
	}
	return Plugin_Continue;
}

// ====[ COMMANDS ]============================================================
public Action:BHopCmd(iClient, iArgs)
{
	if(!g_bEnabled || !IsValidClient(iClient))
		return Plugin_Continue;

	if(g_bHopping[iClient])
	{
		g_bHopping[iClient] = false;
		SetGlobalTransTarget(iClient);
		ReplyToCommand(iClient, "[SM] %t", "EnableBHop");
	}
	else
	{
		g_bHopping[iClient] = true;
		SetGlobalTransTarget(iClient);
		ReplyToCommand(iClient, "[SM] %t", "DisableBHop");
	}
	return Plugin_Handled;
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