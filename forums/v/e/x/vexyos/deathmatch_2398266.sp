#pragma semicolon 1

#define PLUGIN_VERSION "0.1.0"

#define DMG_FALL   (1 << 5)

#include <sourcemod>
#include <SDKTools>
#include <sdkhooks>
#undef REQUIRE_EXTENSIONS
#include <cstrike>
#include <tf2>
#define REQUIRE_EXTENSIONS

new Handle:sm_deathmatch_primary = INVALID_HANDLE;
new Handle:sm_deathmatch_secondary = INVALID_HANDLE;
new Handle:sm_deathmatch_blockdrop = INVALID_HANDLE;
new Handle:sm_deathmatch_noscope = INVALID_HANDLE;
new Handle:sm_deathmatch_health = INVALID_HANDLE;
new Handle:sm_deathmatch_armor = INVALID_HANDLE;
new Handle:sm_deathmatch_respawn_time = INVALID_HANDLE;

public Plugin myinfo = 
{
	name = "Simple Deathmatch",
	author = "Vexyos",
	description = "Make very simple deathmatchs",
	version = PLUGIN_VERSION,
	url = "www.oftenplay.fr",
};

public OnPluginStart()
{
	sm_deathmatch_primary = CreateConVar("sm_deathmatch_primary", "weapon_awp", "ID of the primary weapon (Default: weapon_awp)");
	sm_deathmatch_secondary = CreateConVar("sm_deathmatch_secondary", "weapon_revolver", "ID of the primary weapon (Default: weapon_revolver)");
	sm_deathmatch_blockdrop = CreateConVar("sm_deathmatch_blockdrop", "1", "Block the drop of weapon (1 = yes, 0 = no)(Default: 1)");
	sm_deathmatch_noscope = CreateConVar("sm_deathmatch_noscope", "0", "Noscope mode (1 = yes, 0 = no)(Default: 0)");
	sm_deathmatch_health = CreateConVar("sm_deathmatch_health", "100", "Players Health on spawn (Default: 100)");
	sm_deathmatch_armor = CreateConVar("sm_deathmatch_armor", "0", "Player Armor on spawn (Default: 0)");
	sm_deathmatch_respawn_time = CreateConVar("sm_deathmatch_respawn_time", "3.0", "Time between the player's death and his respawn (Default: 3.0)");
	
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("weapon_reload", Event_WeaponReload);
	HookEvent("weapon_fire_on_empty", Event_WeaponReload);
	
	AddCommandListener(OnCommandDrop, "drop");
}


public Action:OnCommandDrop(client, const String:command[], argc)
{
	int BlockDrop = GetConVarInt(sm_deathmatch_blockdrop);
	if(BlockDrop == 1)
		return Plugin_Handled;
	
	return Plugin_Continue;
}

// Players Actions

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_WeaponDrop, OnWeaponDrop);
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (!IsClientConnected(client) || !IsClientInGame(client) || !IsPlayerAlive(client)) return Plugin_Continue;
	
	if(!(buttons & IN_ATTACK2))
	{
		return Plugin_Continue;
	}
	
	decl String:sWeapon[32];
	GetClientWeapon(client, sWeapon, sizeof(sWeapon));
		
	int NoScope = GetConVarInt(sm_deathmatch_noscope);
	
	if(NoScope == 1){
		if(StrEqual(sWeapon, "weapon_awp", false) || StrEqual(sWeapon, "weapon_scout", false))
		{
			buttons &= ~IN_ATTACK2;
			return Plugin_Changed;
		}
	}
	
	return Plugin_Continue;
}

//Hook Callbacks
public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new team = GetClientTeam(client);
	
	if(IsClientInGame(client) && (team == 2 || team == 3))
	{
		CreateTimer(GetConVarFloat(sm_deathmatch_respawn_time), RespawnPlayer, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}
public Action:OnTakeDamage(client, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (damagetype & DMG_FALL)
		return Plugin_Handled;
	
	return Plugin_Continue;
}
public Action:OnWeaponDrop(client, weapon)
{
	int BlockDrop = GetConVarInt(sm_deathmatch_blockdrop);
	if(BlockDrop == 1)
		if (weapon && IsValidEdict(weapon) && IsValidEntity(weapon))
			CreateTimer(0.1, deleteWeapon, weapon);
	
	return Plugin_Continue;
}

// Events

public Action Event_PlayerSpawn(Handle event, char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	int PlayerHealth = GetConVarInt(sm_deathmatch_health);
	int PlayerArmor = GetConVarInt(sm_deathmatch_armor);
	
	SetEntityHealth(client, PlayerHealth);
	SetEntProp(client, Prop_Send, "m_ArmorValue", PlayerArmor, 1);
	
	CreateTimer(0.1, GiveGuns, client);
}

public Action Event_WeaponReload(Handle event, char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	new PlayerWeaponIndex;
	PlayerWeaponIndex = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	
	SetEntProp(PlayerWeaponIndex, Prop_Send, "m_iPrimaryReserveAmmoCount", 100);
	
	return Plugin_Continue;
}

// Timer Callbacks

public Action GiveGuns(Handle timer, any client)
{
	decl String:PrimaryID[512];
	decl String:SecondaryID[512];
	
	GetConVarString(sm_deathmatch_primary, PrimaryID, sizeof(PrimaryID));
	GetConVarString(sm_deathmatch_secondary, SecondaryID, sizeof(SecondaryID));
	
	int HavePrimary = GetPlayerWeaponSlot(client, 0);
	if (HavePrimary != -1)
	{
		RemovePlayerItem(client, HavePrimary);
		RemoveEdict(HavePrimary);
	}
	int HaveSecondary = GetPlayerWeaponSlot(client, 1);
	if (HaveSecondary != -1)
	{
		RemovePlayerItem(client, HaveSecondary);
		RemoveEdict(HaveSecondary);
	}
	
	GivePlayerItem(client, PrimaryID, 0);
	GivePlayerItem(client, SecondaryID, 0);
}

public Action:RespawnPlayer(Handle:Timer, any:client)
{
	decl String:game[40];
	GetGameFolderName(game, sizeof(game));

	if(StrEqual(game, "cstrike") || StrEqual(game, "csgo"))
	{
		new team = GetClientTeam(client);
		if(team == 2 || team == 3) 
		{
			CS_RespawnPlayer(client);
		}
	}
}

public Action:deleteWeapon(Handle:timer, any:weapon)
{
	if (weapon && IsValidEdict(weapon) && IsValidEntity(weapon))
		RemoveEdict(weapon);
} 