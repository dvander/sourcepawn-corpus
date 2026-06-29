#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

// Plugin definitions
#define PLUGIN_VERSION		"1.2_fix_no_random"
#define PLUGIN_NAME		"[CS:GO] Gun Menu"

public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = "LumiStance(adapting by Grey83)",
	version = PLUGIN_VERSION,
	description = "Lets players select from a menu of allowed weapons.",
	url = "https://forums.alliedmods.net/showthread.php?p=2271029"
};

// Constants
enum Slots
{
	Slot_Primary,
	Slot_Secondary,
	Slot_Knife,
	Slot_Grenade,
	Slot_C4,
	Slot_None
};
enum Teams
{
	CS_TEAM_NONE,
	CS_TEAM_SPECTATOR,
	CS_TEAM_T,
	CS_TEAM_CT
};

// Console Variables
// Configuration
new bool:bLateLoad,
	bool:bIsAdmin[MAXPLAYERS + 1],
	g_ConfigTimeStamp = -1,
	String:g_szFragSound[PLATFORM_MAX_PATH],
	bool:g_MenuOnSpawn,
	bool:g_AllowBuyMenu,
	bool:g_AllowBomb,
	bool:g_AllowGunMenu,
	bool:g_AllowCT,
	bool:g_AllowT,
	bool:g_AllowBots,
	g_SpawnArmor,
	bool:g_SpawnHelmet,
	g_SpawnFlash,
	bool:g_SpawnSmoke,
	bool:g_SpawnHE,
	bool:g_SpawnInc,
	bool:g_SpawnTA,
	g_SpawnHS,
	bool:g_SpawnDefuser;
// Weapon Entity Members and Data
new m_ArmorValue = -1,
	m_bHasHelmet = -1,
	m_bHasDefuser = -1;
// Weapon Menu Configuration
#define MAX_WEAPON_COUNT 32
#define RANDOM_WEAPON 0x63
#define SHOW_MENU -1
new g_PrimaryGunCount,
	g_SecondaryGunCount,
	String:g_PrimaryGuns[MAX_WEAPON_COUNT][32],
	String:g_SecondaryGuns[MAX_WEAPON_COUNT][32];
// Menus
new bool:g_MenuOpen[MAXPLAYERS+1],
	Handle:g_PrimaryMenu,
	Handle:g_SecondaryMenu;
// Player Settings
new g_PlayerPrimary[MAXPLAYERS+1] = {-1, ...},
	g_PlayerSecondary[MAXPLAYERS+1] = {-1, ...};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	bLateLoad = late;
}

public OnPluginStart()
{
	new String:sGameName[5];
	GetGameFolderName(sGameName,sizeof(sGameName));

	if(StrContains(sGameName, "csgo", true) != 0) SetFailState("This game is not supported");

	CreateConVar("csgo_gunmenu_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	// Cache Send Property Offsets
	m_ArmorValue = FindSendPropOffs("CCSPlayer", "m_ArmorValue");
	m_bHasHelmet = FindSendPropOffs("CCSPlayer", "m_bHasHelmet");
	m_bHasDefuser = FindSendPropOffs("CCSPlayer", "m_bHasDefuser");
	if(m_ArmorValue == -1 || m_bHasHelmet == -1 || m_bHasDefuser == -1) SetFailState("\nFailed to retrieve entity member offsets");

	// Client Commands
	RegConsoleCmd("sm_guns", Command_GunMenu);
	RegConsoleCmd("sm_gunmenu", Command_GunMenu);

	// Event Hooks
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("bomb_pickup", Event_BombPickup);
	HookEvent("player_team", Event_PlayerTeam);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);

	if(bLateLoad)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(!IsClientInGame(i)) continue;

			OnClientPutInServer(i);
		}
	}
}

public OnPluginEnd()
{
	CancelMenu(g_PrimaryMenu);
	CheckCloseHandle(g_PrimaryMenu);
	CancelMenu(g_SecondaryMenu);
	CheckCloseHandle(g_SecondaryMenu);
}

public OnMapStart()
{
	// Load configuration
	CheckConfig("configs/gunmenu.ini");

	// Remove buy zones from map to disable the buy menu
	if(!g_AllowBuyMenu) RemoveBuyZones();

	// Handle late load
	if(GetClientCount(true))
		for(new client_index = 1; client_index <= MaxClients; ++client_index)
			if(IsClientInGame(client_index))
			{
				OnClientPutInServer(client_index);
				if(IsPlayerAlive(client_index)) CreateTimer(0.1, Event_HandleSpawn, GetClientUserId(client_index));
			}
}

// Must be manually replayed for late load
public OnClientPutInServer(client_index)
{
	g_MenuOpen[client_index]=false;

	// Give bots random guns
	if(IsFakeClient(client_index))
		g_PlayerPrimary[client_index] = g_PlayerSecondary[client_index] = RANDOM_WEAPON;
	else g_PlayerPrimary[client_index] = g_PlayerSecondary[client_index] = SHOW_MENU;
}

public OnClientPostAdminCheck(client)
{
	if(1 <= client <= MaxClients) bIsAdmin[client] = CheckCommandAccess(client, "sm_admin", ADMFLAG_GENERIC);
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(new i = 1; i <= MaxClients; i++) g_PlayerPrimary[i] = g_PlayerSecondary[i] = SHOW_MENU;
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(0.1, Event_HandleSpawn, GetEventInt(event, "userid"));
}

// Did a player get a kill?
public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_szFragSound[0])
	{
		new victim_index = GetClientOfUserId(GetEventInt(event, "userid"));
		new attacker_index = GetClientOfUserId(GetEventInt(event, "attacker"));

		if(0 < attacker_index && attacker_index <= MaxClients && attacker_index != victim_index && !IsFakeClient(attacker_index)) EmitSoundToClient(attacker_index, g_szFragSound, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
	}
}

public Action:Event_BombPickup( Handle:event, const String:name[], bool:dontBroadcast )
{
	if(!g_AllowBomb) RemoveWeaponBySlot(GetClientOfUserId(GetEventInt(event, "userid")), Slot_C4);
}

// If player spectated close any gun menus
public Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client_index = GetClientOfUserId(GetEventInt(event, "userid"));

	if(g_MenuOpen[client_index] &&(Teams:GetEventInt(event, "team") == CS_TEAM_SPECTATOR))
	{
		CancelClientMenu(client_index);		// Delayed
		g_MenuOpen[client_index] = false;
	}
}

stock CheckConfig(const String:ini_file[])
{
	decl String:file[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, file, sizeof(file), ini_file);

	new timestamp = GetFileTime(file, FileTime_LastChange);

	if(timestamp == -1) SetFailState("\nCould not stat config file: %s.", file);

	if(timestamp != g_ConfigTimeStamp)
	{
		InitializeMenus();
		if(ParseConfigFile(file))
		{

			if(g_szFragSound[0]) CacheSoundFile(g_szFragSound);

			g_ConfigTimeStamp = timestamp;
		}
	}
}

stock CacheSoundFile(String:sound[])
{
	decl String:buffer[PLATFORM_MAX_PATH];
	PrecacheSound(sound, true);
	Format(buffer, sizeof(buffer), "sound/%s", sound);
	AddFileToDownloadsTable(buffer);
}

stock InitializeMenus()
{
	g_PrimaryGunCount=0;
	CheckCloseHandle(g_PrimaryMenu);
	g_PrimaryMenu = CreateMenu(MenuHandler_ChoosePrimary, MenuAction_Display|MenuAction_Select|MenuAction_Cancel);
	SetMenuTitle(g_PrimaryMenu, "Choose a Primary Weapon:");

	g_SecondaryGunCount=0;
	CheckCloseHandle(g_SecondaryMenu);
	g_SecondaryMenu = CreateMenu(MenuHandler_ChooseSecondary, MenuAction_Display|MenuAction_Select|MenuAction_Cancel);
	SetMenuTitle(g_SecondaryMenu, "Choose a Secondary Weapon:");
}

bool:ParseConfigFile(const String:file[]) {
	// Set Defaults
	g_szFragSound[0] = 0;
	g_AllowBuyMenu = false;
	g_AllowBomb = false;

	new Handle:parser = SMC_CreateParser();
	SMC_SetReaders(parser, Config_NewSection, Config_UnknownKeyValue, Config_EndSection);
	SMC_SetParseEnd(parser, Config_End);

	new line = 0;
	new col = 0;
	new String:error[128];
	new SMCError:result = SMC_ParseFile(parser, file, line, col);
	CloseHandle(parser);

	if(result != SMCError_Okay) {
		SMC_GetErrorString(result, error, sizeof(error));
		LogError("%s on line %d, col %d of %s", error, line, col, file);
	}

	return(result == SMCError_Okay);
}

new g_configLevel;
public SMCResult:Config_NewSection(Handle:parser, const String:section[], bool:quotes)
{
	g_configLevel++;
	if(g_configLevel==2)
	{
		if(StrEqual("Settings", section, false)) SMC_SetReaders(parser, Config_NewSection, Config_SettingsKeyValue, Config_EndSection);
		else if(StrEqual("SpawnItems", section, false)) SMC_SetReaders(parser, Config_NewSection, Config_SpawnItemsKeyValue, Config_EndSection);
		else if(StrEqual("PrimaryMenu", section, false)) SMC_SetReaders(parser, Config_NewSection, Config_PrimaryKeyValue, Config_EndSection);
		else if(StrEqual("SecondaryMenu", section, false)) SMC_SetReaders(parser, Config_NewSection, Config_SecondaryKeyValue, Config_EndSection);
	}
	else SMC_SetReaders(parser, Config_NewSection, Config_UnknownKeyValue, Config_EndSection);
	return SMCParse_Continue;
}

public SMCResult:Config_UnknownKeyValue(Handle:parser, const String:key[], const String:value[], bool:key_quotes, bool:value_quotes)
{
	SetFailState("\nDidn't recognize configuration: Level %i %s=%s", g_configLevel, key, value);
	return SMCParse_Continue;
}

public SMCResult:Config_SettingsKeyValue(Handle:parser, const String:key[], const String:value[], bool:key_quotes, bool:value_quotes)
{
	if(StrEqual("frag_sound", key, false)) strcopy(g_szFragSound, sizeof(g_szFragSound), value);
	else if(StrEqual("on_spawn", key, false)) g_MenuOnSpawn = StrEqual("yes", value, false);
	else if(StrEqual("allow_c4", key, false)) g_AllowBomb = StrEqual("yes", value, false);
	else if(StrEqual("buy_zones", key, false)) g_AllowBuyMenu = StrEqual("yes", value, false);
	else if(StrEqual("for_all", key, false)) g_AllowGunMenu = StrEqual("yes", value, false);
	else if(StrEqual("allow_t", key, false)) g_AllowT = StrEqual("yes", value, false);
	else if(StrEqual("allow_ct", key, false)) g_AllowCT = StrEqual("yes", value, false);
	else if(StrEqual("allow_bots", key, false)) g_AllowBots = StrEqual("yes", value, false);
	return SMCParse_Continue;
}

public SMCResult:Config_SpawnItemsKeyValue(Handle:parser, const String:key[], const String:value[], bool:key_quotes, bool:value_quotes)
{
	if(StrEqual("armor", key, false)) g_SpawnArmor = StringToInt(value);
	else if(StrEqual("helmet", key, false)) g_SpawnHelmet = StrEqual("yes", value, false);
	else if(StrEqual("flashbangs", key, false)) g_SpawnFlash = StringToInt(value);
	else if(StrEqual("smokegrenade", key, false)) g_SpawnSmoke = StrEqual("yes", value, false);
	else if(StrEqual("hegrenade", key, false)) g_SpawnHE = StrEqual("yes", value, false);
	else if(StrEqual("incgrenade", key, false)) g_SpawnInc = StrEqual("yes", value, false);
	else if(StrEqual("tagrenade", key, false)) g_SpawnTA = StrEqual("yes", value, false);
	else if(StrEqual("healthshot", key, false)) g_SpawnHS = StringToInt(value);
	else if(StrEqual("defusekits", key, false)) g_SpawnDefuser = StrEqual("yes", value, false);
	return SMCParse_Continue;
}

public SMCResult:Config_PrimaryKeyValue(Handle:parser, const String:weapon_class[], const String:weapon_name[], bool:key_quotes, bool:value_quotes) {
	if(g_PrimaryGunCount>=MAX_WEAPON_COUNT) SetFailState("\nToo many weapons declared!");

	decl String:weapon_id[4];
	strcopy(g_PrimaryGuns[g_PrimaryGunCount], sizeof(g_PrimaryGuns[]), weapon_class);
	Format(weapon_id, sizeof(weapon_id), "%02.2X", g_PrimaryGunCount++);
	AddMenuItem(g_PrimaryMenu, weapon_id, weapon_name);
	return SMCParse_Continue;
}

public SMCResult:Config_SecondaryKeyValue(Handle:parser, const String:weapon_class[], const String:weapon_name[], bool:key_quotes, bool:value_quotes)
{
	if(g_SecondaryGunCount>=MAX_WEAPON_COUNT) SetFailState("\nToo many weapons declared!");

	decl String:weapon_id[4];
	strcopy(g_SecondaryGuns[g_SecondaryGunCount], sizeof(g_SecondaryGuns[]), weapon_class);
	Format(weapon_id, sizeof(weapon_id), "%02.2X", g_SecondaryGunCount++);
	AddMenuItem(g_SecondaryMenu, weapon_id, weapon_name);
	return SMCParse_Continue;
}

public SMCResult:Config_EndSection(Handle:parser)
{
	g_configLevel--;
	SMC_SetReaders(parser, Config_NewSection, Config_UnknownKeyValue, Config_EndSection);
	return SMCParse_Continue;
}

public Config_End(Handle:parser, bool:halted, bool:failed)
{
	if(failed) SetFailState("\nPlugin configuration error");
}

// Set Player's Primary Weapon
public MenuHandler_ChoosePrimary(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Display) g_MenuOpen[param1] = true;
	else if(action == MenuAction_Select)
	{
		new client_index = param1;
		decl String:weapon_id[4];
		GetMenuItem(menu, param2, weapon_id, sizeof(weapon_id));
		new weapon_index = StringToInt(weapon_id, 16);

		g_PlayerPrimary[client_index] = weapon_index;
		if(Teams:GetClientTeam(client_index) > CS_TEAM_SPECTATOR) GivePrimary(client_index);

		DisplayMenu(g_SecondaryMenu, client_index, MENU_TIME_FOREVER);
	}
	else if(action == MenuAction_Cancel)
	{
		g_MenuOpen[param1] = false;
		if(param2 == MenuCancel_Exit)	// CancelClientMenu sends MenuCancel_Interrupted reason
		{
			if(g_SecondaryMenu != INVALID_HANDLE) DisplayMenu(g_SecondaryMenu, param1, MENU_TIME_FOREVER);
		}
	}
}

// Set Player's Secondary Weapon
public MenuHandler_ChooseSecondary(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Display) g_MenuOpen[param1] = true;
	else if(action == MenuAction_Select)
	{
		new client_index = param1;
		decl String:weapon_id[4];
		GetMenuItem(menu, param2, weapon_id, sizeof(weapon_id));
		new weapon_index = StringToInt(weapon_id, 16);

		g_PlayerSecondary[client_index] = weapon_index;
		if(Teams:GetClientTeam(client_index) > CS_TEAM_SPECTATOR) GiveSecondary(client_index);
	}
	else if(action == MenuAction_Cancel) g_MenuOpen[param1] = false;
}

// After Delay, Show Menu or Give Weapons
public Action:Event_HandleSpawn(Handle:timer, any:user_index)
{
	// This event implies client is in-game while GetClientOfUserId() checks IsClientConnected()
	new client_index = GetClientOfUserId(user_index);
	if(!client_index) return;
	if(IsFakeClient(client_index) && !g_AllowBots) return;
	if(!g_AllowGunMenu && !bIsAdmin[client_index]) return;
	new Teams:client_team = Teams:GetClientTeam(client_index);
	if((((client_team == CS_TEAM_T) && !g_AllowT) ||((client_team == CS_TEAM_CT) && !g_AllowCT)) && !bIsAdmin[client_index]) return;

	// Vest Armor
	if(g_SpawnArmor) SetEntData(client_index, m_ArmorValue, g_SpawnArmor, 1, true);
	// Helmet
	SetEntData(client_index, m_bHasHelmet, 1&_:g_SpawnHelmet, 1, true);
	// Remove any nades
	StripNades(client_index);
	// Flash Bangs
	if(g_SpawnFlash)
		for(new i = 1; i <= g_SpawnFlash; i++)
			GivePlayerItem(client_index, "weapon_flashbang");
	// Smoke Grenade
	if(g_SpawnSmoke) GivePlayerItem(client_index, "weapon_smokegrenade");
	// HE Grenade
	if(g_SpawnHE) GivePlayerItem(client_index, "weapon_hegrenade");
	// Incendiary Grenade
	if(g_SpawnInc)
		if(client_team == CS_TEAM_CT) GivePlayerItem(client_index, "weapon_incgrenade");
		else if(client_team == CS_TEAM_T) GivePlayerItem(client_index, "weapon_molotov");
	// TA Grenade
	if(g_SpawnTA) GivePlayerItem(client_index, "weapon_tagrenade");
	// Health Shots
	if(g_SpawnHS)
		for(new i = 1; i <= g_SpawnHS; i++)
			GivePlayerItem(client_index, "weapon_healthshot");
	// Defuser Kit
	if(client_team == CS_TEAM_CT) SetEntData(client_index, m_bHasDefuser, 1&_:g_SpawnDefuser, 1, true);
	
	// Show Menu or Give Guns
	if(g_MenuOnSpawn)
	{
		if(g_PlayerPrimary[client_index]==SHOW_MENU || g_PlayerSecondary[client_index]==SHOW_MENU)
		{
			if(g_PlayerPrimary[client_index]==SHOW_MENU && g_PrimaryMenu != INVALID_HANDLE) DisplayMenu(g_PrimaryMenu, client_index, MENU_TIME_FOREVER);
			else if(g_PlayerSecondary[client_index]==SHOW_MENU && g_SecondaryMenu != INVALID_HANDLE) DisplayMenu(g_SecondaryMenu, client_index, MENU_TIME_FOREVER);
		}
		else
		{
			GivePrimary(client_index);
			GiveSecondary(client_index);
		}
	}
}

stock GivePrimary(client_index)
{
	new weapon_index = g_PlayerPrimary[client_index];
	RemoveWeaponBySlot(client_index, Slot_Primary);
	if(weapon_index == RANDOM_WEAPON) weapon_index = GetRandomInt(0, g_PrimaryGunCount-1);
	if(weapon_index >= 0 && weapon_index < g_PrimaryGunCount) GivePlayerItem(client_index, g_PrimaryGuns[weapon_index]);
}

stock GiveSecondary(client_index)
{
	new weapon_index = g_PlayerSecondary[client_index];
	RemoveWeaponBySlot(client_index, Slot_Secondary);
	if(weapon_index == RANDOM_WEAPON) weapon_index = GetRandomInt(0, g_SecondaryGunCount-1);
	if(weapon_index >= 0 && weapon_index < g_SecondaryGunCount) GivePlayerItem(client_index, g_SecondaryGuns[weapon_index]);
}

public Action:Command_GunMenu(client_index, args)
{
	if(g_PlayerPrimary[client_index]!=SHOW_MENU && g_PlayerSecondary[client_index]!=SHOW_MENU)
		return Plugin_Handled;

	new Teams:client_team = Teams:GetClientTeam(client_index);
	if(IsClientInGame(client_index) &&(((client_team == CS_TEAM_T) && g_AllowT) ||((client_team == CS_TEAM_CT) && g_AllowCT)))
	{
		if(g_PlayerPrimary[client_index]==SHOW_MENU && g_PrimaryMenu != INVALID_HANDLE) DisplayMenu(g_PrimaryMenu, client_index, MENU_TIME_FOREVER);
		else if(g_PlayerSecondary[client_index]==SHOW_MENU && g_SecondaryMenu != INVALID_HANDLE) DisplayMenu(g_SecondaryMenu, client_index, MENU_TIME_FOREVER);
	}
	return Plugin_Continue;
}

stock CheckCloseHandle(&Handle:handle)
{
	if(handle != INVALID_HANDLE)
	{
		CloseHandle(handle);
		handle = INVALID_HANDLE;
	}
}

stock StripNades(client_index)
{
	while(RemoveWeaponBySlot(client_index, Slot_Grenade)) {}
}

stock bool:RemoveWeaponBySlot(client_index, Slots:slot)
{
	new entity_index = GetPlayerWeaponSlot(client_index, _:slot);
	if(entity_index > 0)
	{
		RemovePlayerItem(client_index, entity_index);
		AcceptEntityInput(entity_index, "Kill");
		return true;
	}
	return false;
}

stock RemoveBuyZones()
{
	new MaxEntities = GetMaxEntities();
	decl String:sz_classname[16];

	for(new entity_index = MaxClients+1; entity_index < MaxEntities; ++entity_index)
	{
		if(IsValidEdict(entity_index))
		{
			GetEdictClassname(entity_index, sz_classname, sizeof(sz_classname));
			if(StrEqual(sz_classname, "func_buyzone")) AcceptEntityInput(entity_index, "Kill");
		}
	}
}