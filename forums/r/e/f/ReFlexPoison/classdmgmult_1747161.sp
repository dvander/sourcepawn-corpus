#pragma semicolon 1

// ====[ TABLE OF CONTENTS ]===================================================
//
// INCLUDES - 17
// DEFINES - 22
// CVARS | HANDLES - 25
// VARIABLES - 31
// PLUGIN - 37
// FUNCTIONS - 47
// COMMANDS - 108
// EVENTS - 116
// STOCKS - 146
//
// ============================================================================

// ====[ INCLUDES ]============================================================
#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>

// ====[ DEFINES ]=============================================================
#define PLUGIN_VERSION		"1.2.0"

// ====[ CVARS | HANDLES ]=====================================================
new Handle:cvarEnabled;
new Handle:cvarTeam;
new Handle:cvarAdmins;
new Handle:cvarDamage		[10];

// ====[ VARIABLES ]===========================================================
new bool:g_bEnabled;
new g_iTeam;
new bool:g_bAdmins;
new Float:g_fDamage			[10];

// ====[ PLUGIN ]==============================================================
public Plugin:myinfo =
{
	name = "Class Damage Multiplier",
	author = "ReFlexPoison",
	description = "Multiply damage dealt from specific classes",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
}

// ====[ FUNCTIONS ]===========================================================
public OnPluginStart()
{
	CreateConVar("sm_dmgmult_version", PLUGIN_VERSION, "Class Damage Multiplier Version", FCVAR_REPLICATED | FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);

	cvarEnabled = CreateConVar("sm_dmgmult_enabled", "1", "Enable Class Damage Multiplier\n0 = Disabled\n1 = Enabled", _, true, 0.0, true, 1.0);
	HookConVarChange(cvarEnabled, CVarChange);
	g_bEnabled = GetConVarBool(cvarEnabled);

	cvarTeam = CreateConVar("sm_dmgmult_team", "0", "Damage multiplier for specified teams\n0 = Both\n1 = Red\n2 = Blue", _, true, 0.0, true, 2.0);
	HookConVarChange(cvarTeam, CVarChange);
	g_iTeam = GetConVarInt(cvarTeam);

	cvarAdmins = CreateConVar("sm_dmgmult_admins", "0", "Damage multiplier for admins only\n0 = Disabled\n1 = Enabled", _, true, 0.0, true, 1.0);
	HookConVarChange(cvarAdmins, CVarChange);
	g_bAdmins = GetConVarBool(cvarAdmins);

	cvarDamage[1] = CreateConVar("sm_dmgmult_scout", "1.0", "Damage multiplier for scouts", _, true, 0.0);
	cvarDamage[3] = CreateConVar("sm_dmgmult_soldier", "1.0", "Damage multiplier for soldiers", _, true, 0.0);
	cvarDamage[7] = CreateConVar("sm_dmgmult_pyro", "1.0", "Damage multiplier for pyros", _, true, 0.0);
	cvarDamage[4] = CreateConVar("sm_dmgmult_demoman", "1.0", "Damage multiplier for demomans", _, true, 0.0);
	cvarDamage[6] = CreateConVar("sm_dmgmult_heavy", "1.0", "Damage multiplier for heavys", _, true, 0.0);
	cvarDamage[9] = CreateConVar("sm_dmgmult_engineer", "1.0", "Damage multiplier for engineers", _, true, 0.0);
	cvarDamage[5] = CreateConVar("sm_dmgmult_medic", "1.0", "Damage multiplier for medics", _, true, 0.0);
	cvarDamage[2] = CreateConVar("sm_dmgmult_sniper", "1.0", "Damage multiplier for snipers", _, true, 0.0);
	cvarDamage[8] = CreateConVar("sm_dmgmult_spy", "1.0", "Damage multiplier for spys", _, true, 0.0);
	for(new i = 1; i <= 9; i++)
	{
		HookConVarChange(cvarDamage[i], CVarChange);
		g_fDamage[i] = GetConVarFloat(cvarDamage[i]);
	}

	RegAdminCmd("sm_dmgmult_reset", DmgMultResetCmd, ADMFLAG_ROOT, "Reset all values of Class Damage Multifier to normal");

	for(new i = 1; i <= MaxClients; i++) if(IsValidClient(i))
		SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);

	AutoExecConfig(true, "plugin.dmgmult");
}

public CVarChange(Handle:hConvar, const String:strOldValue[], const String:strNewValue[])
{
	if(hConvar == cvarEnabled)
		g_bEnabled = GetConVarBool(cvarEnabled);
	if(hConvar == cvarAdmins)
		g_bAdmins = GetConVarBool(cvarAdmins);
	if(hConvar == cvarTeam)
		g_iTeam = GetConVarInt(cvarTeam);
	else
	{
		for(new i = 1; i <= 9; i++)
		{
			if(hConvar == cvarDamage[i])
			{
				g_fDamage[i] = GetConVarFloat(cvarDamage[i]);
				break;
			}
		}
	}
}

// ====[ COMMANDS ]============================================================
public Action:DmgMultResetCmd(iClient, iArgs)
{
	for(new i = 1; i <= 9; i++)
		SetConVarFloat(cvarDamage[i], 1.0);
	ReplyToCommand(iClient, "[SM] Damage multiplication reset.");
}

// ====[ EVENTS ]==============================================================
public OnClientPutInServer(iClient)
{
	SDKHook(iClient, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:OnTakeDamage(iVictim, &iAttacker, &iInflictor, &Float:fDamage, &iType)
{
	if(!g_bEnabled || !IsValidClient(iAttacker))
		return Plugin_Continue;

	if(iVictim == iAttacker)
		return Plugin_Continue;

	if(g_bAdmins && !CheckCommandAccess(iAttacker, "sm_dmgmult_flag", ADMFLAG_GENERIC, false))
		return Plugin_Continue;

	new iTeam = GetClientTeam(iAttacker);
	if((g_iTeam == 1 && iTeam != 2) || (g_iTeam == 2 && iTeam != 3))
		return Plugin_Continue;

	new TFClassType:iClass = TF2_GetPlayerClass(iAttacker);
	if(iClass == TFClass_Unknown)
		return Plugin_Continue;

	new Float:fDmgMult = g_fDamage[iClass];
	if(fDmgMult == 1.0)
		return Plugin_Continue;

	fDamage *= fDmgMult;
	return Plugin_Changed;
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