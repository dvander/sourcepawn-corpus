#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>

#define ITEM_MAX_PRIMARY 25
#define ITEM_MAX_SECONDARY 10
#define CSGODM_VERSION "1.0"

new Handle:cvar_respawntime;
new g_Ammo = -1;
new g_ActiveWeapon = -1;
new g_PrimaryAmmoType = -1;
new Handle:g_MainMenu = INVALID_HANDLE;
new Handle:g_PrimaryMenu = INVALID_HANDLE;
new Handle:g_SecondaryMenu = INVALID_HANDLE;

new g_GunOption[MAXPLAYERS+1] = 0;

new g_PrimaryCount = 0;
new String:g_PrimaryList[ITEM_MAX_PRIMARY][32];
new String:g_PrimaryListNames[ITEM_MAX_PRIMARY][32];
new g_CurrentPrimary[MAXPLAYERS+1] = 1;

new g_SecondaryCount = 0;
new String:g_SecondaryList[ITEM_MAX_SECONDARY][32];
new String:g_SecondaryListNames[ITEM_MAX_SECONDARY][32];
new g_CurrentSecondary[MAXPLAYERS+1] = 1;

public Plugin:myinfo = 
{
	name = "CS:GO DeathMatch",
	author = "Monster Killer",
	description = "DeathMatch for CS:GO",
	version = CSGODM_VERSION,
	url = "http://MonsterProjects.org"
};

public OnClientConnected(client)
{
	g_GunOption[client] = 0;
	g_CurrentPrimary[client] = 0;
	g_CurrentSecondary[client] = 0;
}

public OnPluginStart()
{
	CreateConVar("csgodm_version", CSGODM_VERSION, "Current version of CSGO-DM", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_SPONLY|FCVAR_NOTIFY);
	cvar_respawntime = CreateConVar("csgodm_respawntime", "1.0", "The time to wait before respawning a player");
	
	Items_Load();
	
	RegConsoleCmd("sm_guns", Command_Gun, "Open guns menu");
	RegAdminCmd("sm_csgodmreload", Command_GunLoad, ADMFLAG_CONFIG, "Reload CS:GO DeathMatch gun list");
	
	g_ActiveWeapon = FindSendPropOffs("CCSPlayer", "m_hActiveWeapon");
	g_Ammo = FindSendPropOffs("CCSPlayer", "m_iAmmo");
	g_PrimaryAmmoType = FindSendPropOffs("CBaseCombatWeapon", "m_iPrimaryAmmoType");
	
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	HookEvent("weapon_reload", Event_Ammo);
	HookEvent("weapon_fire_on_empty", Event_Ammo);
	
	CreateWeaponMenu();
}

CreateWeaponMenu()
{
	g_MainMenu = CreateMenu(Menu_GunOption, MENU_ACTIONS_DEFAULT|MenuAction_DrawItem|MenuAction_DisplayItem);
	SetMenuTitle(g_MainMenu, "Weapon Options:");
	SetMenuExitButton(g_MainMenu, false);
	AddMenuItem(g_MainMenu, "", "New weapons");
	AddMenuItem(g_MainMenu, "", "Same weapons");
	AddMenuItem(g_MainMenu, "", "Same weapons every time");
}

Items_Load()
{
	new Handle:kv = CreateKeyValues("Weapons");
	decl String:file[200];
	BuildPath(Path_SM, file, sizeof(file), "configs/csgodm.weapons.txt");
	FileToKeyValues(kv, file);
	KvRewind(kv);
	
	decl String:value[30];
	new i = 1;
	
	if(KvJumpToKey(kv, "Primary")) {
		if(KvGotoFirstSubKey(kv, false)) {
			g_PrimaryMenu = INVALID_HANDLE;
			g_PrimaryMenu = CreateMenu(Menu_PrimaryGun, MenuAction_DrawItem|MenuAction_DisplayItem);
			SetMenuTitle(g_PrimaryMenu, "Primary Weapons:");
			SetMenuExitButton(g_PrimaryMenu, false);
			g_PrimaryCount = 0;
			i = 1;
			decl String:IS[3], String:WeaponName[40];
			do {
				KvGetSectionName(kv, value, sizeof(value));
				g_PrimaryList[i] = value;
				KvGetString(kv, NULL_STRING, value, sizeof(value));
				g_PrimaryListNames[i] = value;
				Format(WeaponName, sizeof(WeaponName), "weapon_%s", g_PrimaryList[i]);
				if(!IsModelPrecached(WeaponName))
					PrecacheModel(WeaponName);
				IntToString(i, IS, sizeof(IS));
				AddMenuItem(g_PrimaryMenu, IS, value);
				g_PrimaryCount++;
				i++;
			} while (KvGotoNextKey(kv, false));
		}
	}
	KvRewind(kv);
	
	if(KvJumpToKey(kv, "Secondary")) {
		if(KvGotoFirstSubKey(kv, false)) {
			g_SecondaryMenu = INVALID_HANDLE;
			g_SecondaryMenu = CreateMenu(Menu_SecondaryGun, MenuAction_DrawItem|MenuAction_DisplayItem);
			SetMenuTitle(g_SecondaryMenu, "Secondary Weapons:");
			SetMenuExitButton(g_SecondaryMenu, false);
			g_SecondaryCount = 0;
			i = 1;
			decl String:IS[2], String:WeaponNameSecondary[40];
			do {
				KvGetSectionName(kv, value, sizeof(value));
				g_SecondaryList[i] = value;
				KvGetString(kv, NULL_STRING, value, sizeof(value));
				g_SecondaryListNames[i] = value;
				Format(WeaponNameSecondary, sizeof(WeaponNameSecondary), "weapon_%s", g_SecondaryList[i]);
				if(!IsModelPrecached(WeaponNameSecondary))
					PrecacheModel(WeaponNameSecondary);
				IntToString(i, IS, sizeof(IS));
				AddMenuItem(g_SecondaryMenu, IS, value);
				g_SecondaryCount++;
				i++;
			} while (KvGotoNextKey(kv, false));
		}
	}
	
	CloseHandle(kv);
}

public ShowGunMenu(client)
{
	DisplayMenu(g_MainMenu, client, 0);
}

public ShowGunMenuPrimary(client)
{
	if(g_PrimaryMenu != INVALID_HANDLE) {
		DisplayMenu(g_PrimaryMenu, client, 0);
	}
}

public ShowGunMenuSecondary(client)
{
	if(g_SecondaryMenu != INVALID_HANDLE) {
		DisplayMenu(g_SecondaryMenu, client, 0);
	}
}

public Menu_GunOption(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select) {
		if (param2 == 0) {
			ShowGunMenuPrimary(param1);
		} else if (param2 == 1) {
			GiveSameWeapons(param1);
		} else if (param2 == 2) {
			GiveSameWeapons(param1);
			g_GunOption[param1] = 1;
		} 
	}
	return 0;
}

public Menu_PrimaryGun(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select) {
		decl String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		new GetMenuParam = StringToInt(info); 
		GivePrimary(param1, GetMenuParam);
		ShowGunMenuSecondary(param1);
	}
	return 0;
}

public Menu_SecondaryGun(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select) {
		decl String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		new GetMenuParam = StringToInt(info); 
		GiveSecondary(param1, GetMenuParam);
	}
	return 0;
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!client || !IsClientInGame(client))
		return;
	
	if(g_GunOption[client] == 0) {
		ShowGunMenu(client);
	} else if(g_GunOption[client] == 1) {
		GiveSameWeapons(client);
	}
}

public RemoveWeapon(client, slot)
{
	if(IsPlayerAlive(client))
	{
		new weaponent = GetPlayerWeaponSlot(client, slot);
		if(IsValidEntity(weaponent)) {
			AcceptEntityInput(weaponent, "Kill");
		}
	}
}

public GivePrimary(client, weaponnum)
{
	if(g_PrimaryCount > 0 && strlen(g_PrimaryList[weaponnum]) > 0 && IsPlayerAlive(client)) {
		decl String:WeaponName[40];
		Format(WeaponName, sizeof(WeaponName), "weapon_%s", g_PrimaryList[weaponnum]);
		RemoveWeapon(client, 0);
		GivePlayerItem(client, WeaponName);
		g_CurrentPrimary[client] = weaponnum;
	}
}

public GiveSecondary(client, weaponnum)
{
	if(g_SecondaryCount > 0 && strlen(g_SecondaryList[weaponnum]) > 0 && IsPlayerAlive(client)) {
		decl String:WeaponName[40];
		Format(WeaponName, sizeof(WeaponName), "weapon_%s", g_SecondaryList[weaponnum]);
		RemoveWeapon(client, 1);
		GivePlayerItem(client, WeaponName);
		g_CurrentSecondary[client] = weaponnum;
	}
}

public GiveSameWeapons(client)
{
	if(g_CurrentSecondary[client] != 0 && g_CurrentPrimary[client] != 0) {
		GiveSecondary(client, g_CurrentSecondary[client]);
		GivePrimary(client, g_CurrentPrimary[client]);
	} else {
		ShowGunMenuPrimary(client);
	}
}

public Action:Command_GunLoad(client, args)
{
	Items_Load();
	return Plugin_Continue;
}

public Action:Command_Gun(client, args)
{
	if(!client)
		return Plugin_Handled;
		
	if(IsPlayerAlive(client))
		ShowGunMenu(client);
	return Plugin_Continue;
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!client || !IsClientInGame(client))
		return;
	
	new Float:RespawnDelay = GetConVarFloat(cvar_respawntime);
	CreateTimer(RespawnDelay, Timer_PlayerSpawn, any:client);
}

public Event_Ammo(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!client || !IsClientInGame(client))
		return;
	
	if(IsPlayerAlive(client)) {
		new Entity = GetEntDataEnt2(client, g_ActiveWeapon);
		if (IsValidEdict(Entity)) {
			new AmmoType = GetEntData(Entity, g_PrimaryAmmoType);
			SetEntData(client, g_Ammo+(AmmoType<<2), 60, 4, true);
		}
	}
}

public Action:Timer_PlayerSpawn(Handle:timer, any:client)
{
	if (IsClientInGame(client) && !IsPlayerAlive(client)) {
		CS_RespawnPlayer(client);
	}
}