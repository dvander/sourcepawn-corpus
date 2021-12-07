/*
 *	Plugin: Level A Charge
 *
 *	Version History:
 *		1.0 -	Initial Release based upon http://forums.alliedmods.net/showthread.php?t=125326
 *				Wasn't a separate plugin at this stage
 *		1.1 -	Improved chat display (each person gets their own)
 *				Added Colors.inc (see above for reason)
 *				Made into seperate plugin
 */

#include <sourcemod>
#include <sdktools>
#include <colors>

#pragma semicolon 1

#define PLUGIN_VERSION "1.1"

#define TAG_LEVEL	"{lightgreen}[Level]{default} "

new Handle:g_hEnabled		=	INVALID_HANDLE;
new bool:g_bEnabled			=	true;
new bool:eventsHooked;
new bool:pluginDisabling;

new String:Weapon0[] = "an {olive}unknown weapon{default}";
new String:Weapon1[] = "a {olive}baseball bat{default}";
new String:Weapon2[] = "a {olive}cricket bat{default}";
new String:Weapon3[] = "a {olive}crowbar{default}";
new String:Weapon4[] = "an {olive}electric guitar{default}";
new String:Weapon5[] = "a {olive}fireaxe{default}";
new String:Weapon6[] = "a {olive}frying pan{default}";
new String:Weapon7[] = "a {olive}katana{default}";
new String:Weapon8[] = "a {olive}knife{default}";
new String:Weapon9[] = "a {olive}machete{default}";
new String:Weapon10[] = "a {olive}tonfa{default}";
new String:Weapon11[] = "a {olive}golf club{default}";

public Plugin:myinfo = 
{
	name = "[L4D2] Level A Charge",
	author = "Dirka_Dirka",
	description = "Displays a message when someone Levels A Charge.",
	version = PLUGIN_VERSION,
	url = ""
}

public OnPluginStart()
{
	// Require Left 4 Dead 2
	decl String:game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));
	if (!StrEqual(game_name, "left4dead2", false))
	{		
		SetFailState("[Level] Plugin supports Left 4 Dead 2 only.");
	}
	
	// Create plugin version info
	CreateConVar("l4d2_levelacharge_ver", PLUGIN_VERSION, "Version of the Level a Charge plugin.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	// Create plugin cvars
	g_hEnabled = CreateConVar("l4d2_levelacharge_enable", "1", "Enable this plugin, which announces Charger Leveling and Killer Tank HP.", FCVAR_NOTIFY|FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	// Hook convar changes & read values from them
	HookConVarChange(g_hEnabled, ConVarChanged_Enable);
	g_bEnabled = GetConVarBool(g_hEnabled);
	
	_LevelACharge_ModuleEnabled();
}

public OnPluginEnd()
{
	if (g_bEnabled)
	{
		_LevelACharge_ModuleDisabled();
		pluginDisabling = true;
	}
	else return;
}

public ConVarChanged_Enable(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_bEnabled = GetConVarBool(g_hEnabled);
	
	if (g_bEnabled)
		_LevelACharge_ModuleEnabled();
	else
		_LevelACharge_ModuleDisabled();
}

_LevelACharge_ModuleEnabled()
{
	if (!pluginDisabling)
	{
		HookEvent("charger_killed", ChargerKilled_Event);
		eventsHooked = true;
	}
}

_LevelACharge_ModuleDisabled()
{
	if ((pluginDisabling)  && eventsHooked)
	{
		UnhookEvent("charger_killed", ChargerKilled_Event);
		eventsHooked = false;
	}
}

public ChargerKilled_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_bEnabled) return;
	
	new bool:IsCharging = GetEventBool(event, "charging");
	new bool:IsMelee = GetEventBool(event, "melee");
	
	if (!IsMelee || !IsCharging) return;
	
	new survivor = GetClientOfUserId(GetEventInt(event, "attacker"));
	new charger = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!survivor || !charger) return;
	
	decl String:weaponname[64];
	GetClientWeapon(survivor, weaponname, sizeof(weaponname));
	
	new String:weapon[64] = "";
	
	if (StrEqual(weaponname, "weapon_melee"))
	{
		GetEntPropString(GetPlayerWeaponSlot(survivor, 1), Prop_Data, "m_strMapSetScriptName", weaponname, sizeof(weaponname));
	}
	else return;
	
	if (StrEqual(weaponname, "baseball_bat")) StrCat(String:weapon, sizeof(Weapon1), String:Weapon1);
	else if (StrEqual(weaponname, "cricket_bat")) StrCat(String:weapon, sizeof(Weapon2), String:Weapon2);
	else if (StrEqual(weaponname, "crowbar")) StrCat(String:weapon, sizeof(Weapon3), String:Weapon3);
	else if (StrEqual(weaponname, "electric_guitar")) StrCat(String:weapon, sizeof(Weapon4), String:Weapon4);
	else if (StrEqual(weaponname, "fireaxe")) StrCat(String:weapon, sizeof(Weapon5), String:Weapon5);
	else if (StrEqual(weaponname, "frying_pan")) StrCat(String:weapon, sizeof(Weapon6), String:Weapon6);
	else if (StrEqual(weaponname, "katana")) StrCat(String:weapon, sizeof(Weapon7), String:Weapon7);
	else if (StrEqual(weaponname, "knife")) StrCat(String:weapon, sizeof(Weapon8), String:Weapon8);
	else if (StrEqual(weaponname, "machete")) StrCat(String:weapon, sizeof(Weapon9), String:Weapon9);
	else if (StrEqual(weaponname, "tonfa")) StrCat(String:weapon, sizeof(Weapon10), String:Weapon10);
	else if (StrEqual(weaponname, "golf_club")) StrCat(String:weapon, sizeof(Weapon11), String:Weapon11);
	else StrCat(String:weapon, sizeof(Weapon0), String:Weapon0);
	
	CSkipNextClient(survivor);
	CSkipNextClient(charger);
	CPrintToChatAll("%s{green}%N {olive}LevelCharged{default} on {green}%N{default} with %s!!", TAG_LEVEL, survivor, charger, weapon);
	CPrintToChat(survivor, "%sYou just {olive}LevelCharged{default} on {green}%N{default} with %s!!", TAG_LEVEL, charger, weapon);
	CPrintToChat(charger, "%sYou just got {olive}LevelCharged{default} by {green}%N{default} with %s!!", TAG_LEVEL, survivor, weapon);
}
