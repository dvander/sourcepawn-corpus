#pragma semicolon 1

// ====[ INCLUDES ]============================================================
#include <sourcemod>

// ====[ DEFINES ]=============================================================
#define PLUGIN_VERSION "1.1.0"

// ====[ HANDLES | CVARS ]=====================================================
new Handle:cvarEnabled;
new Handle:cvarWeapons;

// ====[ VARIABLES ]===========================================================
new g_iEnabled;
new String:g_strWeapons[256];

// ====[ PLUGIN ]==============================================================
public Plugin:myinfo =
{
	name = "Weapon Taunt Block",
	author = "ReFlexPoison",
	description = "Block taunting for specific weapons",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
}

// ====[ FUNCTIONS ]===========================================================
public APLRes:AskPluginLoad2(Handle:hMyself, bool:bLate, String:strError[], iErr_Max)
{
	new String:strGame[32];
	GetGameFolderName(strGame, sizeof(strGame));
	if(!StrEqual(strGame, "tf"))
	{
		Format(strError, iErr_Max, "This plugin only works for Team Fortress 2");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

public OnPluginStart()
{
	CreateConVar("sm_tauntblock_version", PLUGIN_VERSION, "Weapon Taunt Block Version", FCVAR_REPLICATED | FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);

	cvarEnabled = CreateConVar("sm_tauntblock_enabled", "1", "Enable Weapon Taunt Block\n0 = Disabled\n1 = Blacklist(Blocked Weapons)\n2 = Whitelist(Unblocked Weapons)", FCVAR_NONE, true, 0.0, true, 2.0);
	cvarWeapons = CreateConVar("sm_tauntblock_weapons", "", "Weapons (indices) to disable taunting\nDivide with comma(s)\nExample: 1,5,7", FCVAR_NONE);

	g_iEnabled = GetConVarInt(cvarEnabled);
	GetConVarString(cvarWeapons, g_strWeapons, sizeof(g_strWeapons));

	HookConVarChange(cvarEnabled, CVarChange);
	HookConVarChange(cvarWeapons, CVarChange);

	AutoExecConfig(true, "plugin.tauntblock");

	AddCommandListener(TauntCmd, "taunt");
	AddCommandListener(TauntCmd, "+taunt");
}

public CVarChange(Handle:hConvar, const String:strOldValue[], const String:strNewValue[])
{
	if(hConvar == cvarEnabled)
		g_iEnabled = GetConVarInt(cvarEnabled);
	if(hConvar == cvarWeapons)
		GetConVarString(cvarWeapons, g_strWeapons, sizeof(g_strWeapons));
}

// ====[ COMMANDS ]============================================================
public Action:TauntCmd(iClient, const String:strCommand[], iArgs)
{
	if(g_iEnabled <= 0 || !IsValidClient(iClient))
		return Plugin_Continue;

	new iWeapon = GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
	if(iWeapon > MaxClients && IsValidEntity(iWeapon))
	{
		new iIndex = GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex");
		new String:strBuffer[255][8];
		ExplodeString(g_strWeapons, ",", strBuffer, sizeof(strBuffer), sizeof(strBuffer[]));

		new iCount;
		for(new i = 0; i < sizeof(strBuffer); i++)
		{
			if(StringToInt(strBuffer[i]) == iIndex)
				iCount++;
		}
		if(g_iEnabled == 1 && iCount > 0)
			return Plugin_Handled;
		else if(g_iEnabled == 2 && iCount == 0)
			return Plugin_Handled;
	}
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