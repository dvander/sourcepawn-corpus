// This made code more "cleaner".
#pragma semicolon 1

// Include SM headers.
#include <sourcemod>
#include <sdktools>
#include <cstrike>

// Include other headers.
#include <sdkhooks>

// Defines.
#define _V "1.0.2"
#define MAX_PREFIXES 16

#define _MAXENT 2048

public Plugin:myinfo =
{
	name		= "Props Mod",
	author		= "Vladislav Dolgov",
	description	= "Props mod for counter-strike source.",
	version		= _V,
	url			= "http://www.elistor.ru"
}

// Primary enableswitch.
new bool:_active = true;

// Create handles for configurable variables.
new Handle:p_cfg_enable;
new Handle:p_cfg_fly;
new Handle:p_cfg_iter;
new Handle:p_cfg_btime;
new Handle:p_cfg_dattack;
new Handle:p_cfg_godmode;
new Handle:p_cfg_ctwmenu;
new Handle:p_cfg_wcolor;
new Handle:p_cfg_wpickup;
new Handle:p_cfg_mcheck;
new Handle:p_cfg_mprefixes;
new Handle:p_cfg_lslay;

new bool:building;
new Handle:btimer;

// HSay timer.
new Handle:hs_timer;
new round_start_time;

// Weapons menu.
new Handle:menu_weapons;

// Drop weapons.
new bool:weapon_team[_MAXENT+1];


public OnPluginStart()
{
	CreateConVar("sm_props_version", _V, "Props mod version.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	// Creating plugin variables.
	p_cfg_enable	= CreateConVar("sm_props_enable",				"1",				"Enable or disable Props modification. (0 - disable, 1 - enable; default: 1)",						FCVAR_PLUGIN, true, 0.0, true, 1.0);
	p_cfg_fly		= CreateConVar("sm_props_fly",					"2",				"Which team can fly? (0 - Disabled, 1 - All, 2 - Terrorists, 3 - Counter-Terrorists; default: 2)",	FCVAR_PLUGIN, true, 0.0, true, 3.0);
	p_cfg_iter		= CreateConVar("sm_props_invisible",			"1",				"If this enabled CT can't see T in building time. (0 - disable, 1 - enable; default: 1)",			FCVAR_PLUGIN, true, 0.0, true, 1.0);
	p_cfg_btime		= CreateConVar("sm_props_buildtime",			"210",				"How long building? (Default: 180 (3 minutes), in seconds)",										FCVAR_PLUGIN, true, 0.0, true, 540.0);
	p_cfg_dattack	= CreateConVar("sm_props_attack",				"0",				"Enable +attack and +attack2 in building time? (0 - disable, 1 - enable; default: 1)",				FCVAR_PLUGIN, true, 0.0, true, 1.0);
	p_cfg_godmode	= CreateConVar("sm_props_godmode",				"1",				"Enable godmode in building time? (0 - disable, 1 - enable; default: 1)",							FCVAR_PLUGIN, true, 0.0, true, 1.0);
	p_cfg_ctwmenu	= CreateConVar("sm_props_ctweapons",			"1",				"Enable or disable weapons menu for CT. (0 - disable, 1 - enable; default: 1)",						FCVAR_PLUGIN, true, 0.0, true, 1.0);
	p_cfg_wcolor	= CreateConVar("sm_props_weaponcolor",			"1",				"Enable or disable changing color for dropped weapons. (0 - disable, 1 - enable; default: 1)",		FCVAR_PLUGIN, true, 0.0, true, 1.0);
	p_cfg_wpickup	= CreateConVar("sm_props_weaponpickup", 		"1",				"If enabled CT can't pickup T weapons. (0 - disable, 1 - enable; default: 1)",						FCVAR_PLUGIN, true, 0.0, true, 1.0);
	p_cfg_mcheck	= CreateConVar("sm_deathrun_mapcheck",			"1",				"Enable or disable check for map prefixes; 0 - disabled, 1 - enabled.",								FCVAR_PLUGIN, true, 0.0, true, 1.0);
	p_cfg_mprefixes	= CreateConVar("sm_deathrun_mapprefix",			"dr_,deathrun_",	"Map prefixes for check; default: dr_,deathrun_, max 4 prefixes.",									FCVAR_PLUGIN);
	p_cfg_lslay		= CreateConVar("sm_deathrun_ladderautoslay",	"1",				"Enable or disable killing CT who attack T who on ladder?; 0 - disabled, 1 - enabled.",				FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	// Hook events.
	HookEvent("round_start",	Event_RoundStart);
	HookEvent("round_end",		Event_RoundEnd);
	HookEvent("player_spawn",	Event_PlayerSpawn);
	
	// Admin commands.
	RegAdminCmd("sm_props_reload_weapons", ReloadWeapons, ADMFLAG_RCON, "Reload whe weapons list from file.");
	
	// Register console (and chat) commands.
	
	LoadTranslations("plugin.props");
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (!GetConVarBool(p_cfg_enable))
		return Plugin_Continue;
	
	if(GetConVarBool(p_cfg_lslay) && attacker && victim && attacker != victim && (GetClientTeam(attacker) == CS_TEAM_CT) && (GetClientTeam(victim) == CS_TEAM_T))
	{
		new MoveType:movetype = GetEntityMoveType(CS_TEAM_T);
		if (movetype == MOVETYPE_LADDER)
		{
			ForcePlayerSuicide(attacker);
			PrintToChat(attacker, "\x04%t \x01>\x03 %t", "props", "ladder autoslay");
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

// Reload weapons function.
public Action:ReloadWeapons(client, args)
{
	if (!_active)
		return Plugin_Continue;
	
	if (menu_weapons != INVALID_HANDLE)
	{
		CloseHandle(menu_weapons);
		menu_weapons = INVALID_HANDLE;
	}	
	
	BuildWeaponsMenu();
	
	ReplyToCommand(client, "Props: Weapons list reloaded.");
	
	return Plugin_Handled;
}

// Weapon pickup.
public Action:OnWeaponCanUse(client, weapon)
{
	// Allow only CTs to use a weapon
	if (_active && GetConVarBool(p_cfg_enable) && GetConVarBool(p_cfg_wpickup))
	{
		if ((GetClientTeam(client) == CS_TEAM_CT) && weapon_team[weapon])
			return Plugin_Handled;
	}
	return Plugin_Continue;
}

// If weapon dropped.
public Action:OnWeaponDrop(client, weapon)
{
	if (!_active)
		return Plugin_Continue;
	
	if (!IsClientInGame(client))
		return Plugin_Continue;
	
	SetEntityRenderMode(weapon, RENDER_TRANSCOLOR);
	if (GetClientTeam(client) == CS_TEAM_CT)
	{
		if (GetConVarBool(p_cfg_wcolor))
			SetEntityRenderColor(weapon, 0, 0, 255, 255);
		
		weapon_team[weapon] = false;
	}
	else if (GetClientTeam(client) == CS_TEAM_T)
	{
		if (GetConVarBool(p_cfg_wcolor))
			SetEntityRenderColor(weapon, 255, 0, 0, 255);
		
		weapon_team[weapon] = true;
	}
	
	return Plugin_Continue;
}

// This executes on map starting.
public OnMapStart()
{
	// Check for plugin enabled.
	if (!GetConVarBool(p_cfg_enable) && !_active)
		return;
	
	decl String:map[64], String:buffer[64];
	GetCurrentMap(map, sizeof(map));
	if (GetConVarBool(p_cfg_mcheck))
	{
		decl String:_mapprefix[MAX_PREFIXES][64];
		GetConVarString(p_cfg_mprefixes, buffer, sizeof(buffer));
		ExplodeString(buffer, ",", _mapprefix, sizeof(_mapprefix), sizeof(_mapprefix[]));
		
		for (new i = 0; i <= sizeof(_mapprefix) - 1; i++)
		{
			if (StrContains(map, _mapprefix[i], false) == -1)
				_active = false;
			else
				_active = true;
		}
	}
	
	// Build weapons menu.
	BuildWeaponsMenu();
}

// This executes on map end.
public OnMapEnd()
{
	// Check for plugin enabled.
	if (!GetConVarBool(p_cfg_enable) && !_active)
		return;
	
	if (menu_weapons != INVALID_HANDLE)
	{
		CloseHandle(menu_weapons);
		menu_weapons = INVALID_HANDLE;
	}
}

// Handler of props list menu.
public menu_weapons_h(Handle:menu, MenuAction:action, client, pos)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(menu, pos, info, sizeof(info));
		GivePlayerItem(client, info);
	}
}

// Build weapons menu for CT.
BuildWeaponsMenu()
{
	// If menu not already created - create it.
	if (menu_weapons == INVALID_HANDLE)
		menu_weapons = CreateMenu(menu_weapons_h);
	
	decl String:buffer[255], String:buffer2[255];
	
	// Setting menu title.
	Format(buffer, sizeof(buffer), "%t", "select weapon");
	SetMenuTitle(menu_weapons, buffer);
	
	// Adding items to menu from file.
	new Handle:kv = CreateKeyValues("weapons");
	BuildPath(Path_SM, buffer, sizeof(buffer), "configs/props/weapons.cfg");
	FileToKeyValues(kv, buffer);
	
	if (!KvGotoFirstSubKey(kv))
		return;
	
	do
	{
		KvGetSectionName(kv, buffer, sizeof(buffer));
		KvGetString(kv, "entity", buffer2, sizeof(buffer2));
		AddMenuItem(menu_weapons, buffer2, buffer);
	} while (KvGotoNextKey(kv));
 
	CloseHandle(kv);
}

// Timer for hsay.
public Action:hsay_timer(Handle:timer)
{
	new sec_tmp = GetConVarInt(p_cfg_btime) + round_start_time - GetTime();
	new min = RoundToFloor(float(sec_tmp) / 60.0);
	new sec = sec_tmp - min * 60;
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
			break;
		
		decl String:buffer[255];
		
		Format(buffer, sizeof(buffer), "");
		if (building && ((min > 0) || (sec > 0)))
		{
			if (sec < 10)
				Format(buffer, sizeof(buffer), "%d:0%d\n", min, sec);
			else
				Format(buffer, sizeof(buffer), "%d:%d\n", min, sec);
		}
		
		if (!IsPlayerAlive(i) || GetClientTeam(i) != CS_TEAM_CT || !building)
			Format(buffer, sizeof(buffer), "%s%t", buffer, "you cant building");
		else
			Format(buffer, sizeof(buffer), "%s%t", buffer, "you can building");
			
		PrintHintText(i, buffer);
	}
	
	hs_timer = CreateTimer(0.1, hsay_timer);
}

// Executes on player spawn.
public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	// If plugin disabled do nothing.
	if (!GetConVarBool(p_cfg_enable) && !_active)
		return Plugin_Continue;
	
	// Create victim and attacker variables.
	new client	= GetClientOfUserId(GetEventInt(event, "userid"));
	
	if ((GetClientTeam(client) != CS_TEAM_T) && (GetClientTeam(client) != CS_TEAM_CT))
		return Plugin_Continue;
	
	// Godmode enable.
	if (GetConVarBool(p_cfg_godmode) && building)
		SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
	
	// Weapon management.
	new weaponIndex;
	if (GetClientTeam(client) == CS_TEAM_CT)
	{
		for (new i = 0; i <= 4; i++)
		{
			while ((weaponIndex = GetPlayerWeaponSlot(client, i)) != -1)
			{
				RemovePlayerItem(client, weaponIndex);
				RemoveEdict(weaponIndex);
			}
		}
	}
	
	GivePlayerItem(client, "weapon_knife");
	
	if (GetConVarBool(p_cfg_ctwmenu) && GetClientTeam(client) == CS_TEAM_CT)
		DisplayMenu(menu_weapons, client, MENU_TIME_FOREVER);
	
	return Plugin_Continue;
}

// Executes on round end.
public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	// If plugin disabled do nothing.
	if (!GetConVarBool(p_cfg_enable) && !_active)
		return Plugin_Continue;
	
	// Manage building timer.
	if (btimer != INVALID_HANDLE) {
		KillTimer(btimer);
		btimer = INVALID_HANDLE;
	}
	
	// Manage hsay timer.
	if (hs_timer != INVALID_HANDLE) {
		KillTimer(hs_timer);
		hs_timer = INVALID_HANDLE;
	}
	
	return Plugin_Continue;
}

// Building end timer.
public Action:building_timer(Handle:timer)
{
	building	= false;
	btimer		= INVALID_HANDLE;
	
	// Godmode disable.
	for (new i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i) && IsPlayerAlive(i) && _active)
				SetEntProp(i, Prop_Data, "m_takedamage", 2, 1);
}

// Executes in round start.
public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	// If plugin disabled do nothing.
	if (!GetConVarBool(p_cfg_enable) && !_active)
		return Plugin_Continue;
	
	// Managing build time.
	building	= true;
	btimer		= CreateTimer(GetConVarFloat(p_cfg_btime), building_timer);
	
	// Manage hsay timer.
	round_start_time	= GetTime();
	hs_timer			= CreateTimer(0.2, hsay_timer);
	
	return Plugin_Continue;
}

// Transmit hook from SDKHooks.
public Action:Hook_SetTransmit(entity, entity2)
{
	// Check for plugin enabled.
	if (!GetConVarBool(p_cfg_enable) && !_active)
		return Plugin_Continue;
	
	if (GetConVarBool(p_cfg_iter) && (entity > 0 && entity <= MAXPLAYERS) && (entity2 > 0 && entity2 <= MAXPLAYERS) && building && (GetClientTeam(entity) == CS_TEAM_T) && (GetClientTeam(entity2) == CS_TEAM_CT))
		return Plugin_Handled;
	
	return Plugin_Continue;
}

// Executes on player joined to server.
public OnClientPutInServer(client)
{
	// Check for plugin enabled.
	if (!GetConVarBool(p_cfg_enable) && !_active)
		return;
	
	// If enabled invisible terrorist.
	if (GetConVarBool(p_cfg_iter))
		SDKHook(client, SDKHook_SetTransmit, Hook_SetTransmit);
	
	SDKHook(client, SDKHook_WeaponDrop,		OnWeaponDrop);
	SDKHook(client, SDKHook_WeaponCanUse,	OnWeaponCanUse);
	SDKHook(client, SDKHook_OnTakeDamage,	OnTakeDamage);
}

// If player use some cmd (use, attack, etc).
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	// Check for plugin enabled.
	if (!GetConVarBool(p_cfg_enable) && !_active)
		return Plugin_Continue;
	
	// Check fly is enabled for player team and player alive.
	if ((GetConVarInt(p_cfg_fly) == 1 || (GetClientTeam(client) == GetConVarInt(p_cfg_fly))) && IsPlayerAlive(client))
	{
		if (buttons & IN_USE)
			SetEntityMoveType(client, MOVETYPE_FLY);
		else
			SetEntityMoveType(client, MOVETYPE_WALK);
		return Plugin_Changed;
	}
	
	// Disable attack in building time.
	if (GetConVarBool(p_cfg_dattack) && building && ((buttons & IN_ATTACK) || (buttons & IN_ATTACK2)))
	{
		buttons &= ~IN_ATTACK;
		buttons &= ~IN_ATTACK2;
	}
	
	return Plugin_Continue;
}