#pragma semicolon 1

#include <sdktools>

// Plugin definitions
#define PLUGIN_VERSION		"1.2_fix2"
#define PLUGIN_NAME		"[CS:GO] Gun Menu"

public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = "LumiStance(adapting by Grey83)",
	version = PLUGIN_VERSION,
	description = "Lets players select from a menu of allowed weapons.",
	url = "https://forums.alliedmods.net/showthread.php?p=2271029"
}

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
	// Cache Send Property Offsets
	if((m_ArmorValue = FindSendPropOffs("CCSPlayer", "m_ArmorValue") == -1))
		SetFailState("Failed to retrieve CCSPlayer::m_ArmorValue offset");
	if((m_bHasHelmet = FindSendPropOffs("CCSPlayer", "m_bHasHelmet") == -1))
		SetFailState("Failed to retrieve CCSPlayer::m_bHasHelmet offset");
	if((m_bHasDefuser = FindSendPropOffs("CCSPlayer", "m_bHasDefuser") == -1))
		SetFailState("Failed to retrieve CCSPlayer::m_bHasDefuser offset");

	bLateLoad = late;
}

public OnPluginStart()
{
	new String:game[8];
	GetGameFolderName(game, sizeof(game));
	if(strcmp(game, "csgo", true)) SetFailState("This game is not supported");

	CreateConVar("csgo_gunmenu_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_SPONLY);

	// Client Commands
	RegConsoleCmd("sm_guns", Command_GunMenu);
	RegConsoleCmd("sm_gunmenu", Command_GunMenu);

	// Event Hooks
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("bomb_pickup", Event_BombPickup);
	HookEvent("player_team", Event_PlayerTeam);

	if(!bLateLoad) return;

	bLateLoad = false;
	for(new i = 1; i <= MaxClients; i++) if(IsClientInGame(i)) OnClientPutInServer(i);
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
		for(new client = 1; client <= MaxClients; ++client) if(IsClientInGame(client))
		{
			OnClientPutInServer(client);
			if(IsPlayerAlive(client)) CreateTimer(0.1, Event_HandleSpawn, GetClientUserId(client));
		}
}

// Must be manually replayed for late load
public OnClientPutInServer(client)
{
	g_MenuOpen[client]=false;

	// Give bots random guns
	g_PlayerPrimary[client] = g_PlayerSecondary[client] = IsFakeClient(client) ? RANDOM_WEAPON : SHOW_MENU;
}

public OnClientPostAdminCheck(client)
{
	if(client) bIsAdmin[client] = !IsFakeClient(client) && CheckCommandAccess(client, "sm_admin", ADMFLAG_GENERIC);
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
		new client = GetClientOfUserId(GetEventInt(event, "attacker"));
		if(client && client != GetClientOfUserId(GetEventInt(event, "userid")) && !IsFakeClient(client))
			EmitSoundToClient(client, g_szFragSound, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
	}
}

public Action:Event_BombPickup( Handle:event, const String:name[], bool:dontBroadcast )
{
	if(!g_AllowBomb) RemoveWeaponBySlot(GetClientOfUserId(GetEventInt(event, "userid")), Slot_C4);
}

// If player spectated close any gun menus
public Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(g_MenuOpen[client] && Teams:GetEventInt(event, "team") == CS_TEAM_SPECTATOR)
	{
		CancelClientMenu(client);		// Delayed
		g_MenuOpen[client] = false;
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
			FinalizeMenus();

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
	AddMenuItem(g_PrimaryMenu, "63", "Random");

	g_SecondaryGunCount=0;
	CheckCloseHandle(g_SecondaryMenu);
	g_SecondaryMenu = CreateMenu(MenuHandler_ChooseSecondary, MenuAction_Display|MenuAction_Select|MenuAction_Cancel);
	SetMenuTitle(g_SecondaryMenu, "Choose a Secondary Weapon:");
	AddMenuItem(g_SecondaryMenu, "63", "Random");
}

stock FinalizeMenus()
{
	AddMenuItem(g_PrimaryMenu, "FF", "None");
	AddMenuItem(g_SecondaryMenu, "FF", "None");
}

bool:ParseConfigFile(const String:file[])
{
	// Set Defaults
	g_szFragSound[0] = 0;
	g_AllowBuyMenu = false;
	g_AllowBomb = false;

	new Handle:parser = SMC_CreateParser();
	SMC_SetReaders(parser, Config_NewSection, Config_UnknownKeyValue, Config_EndSection);
	SMC_SetParseEnd(parser, Config_End);

	new line, col, String:error[128];
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
		if(!strcmp("Settings", section, false)) SMC_SetReaders(parser, Config_NewSection, Config_SettingsKeyValue, Config_EndSection);
		else if(!strcmp("SpawnItems", section, false)) SMC_SetReaders(parser, Config_NewSection, Config_SpawnItemsKeyValue, Config_EndSection);
		else if(!strcmp("PrimaryMenu", section, false)) SMC_SetReaders(parser, Config_NewSection, Config_PrimaryKeyValue, Config_EndSection);
		else if(!strcmp("SecondaryMenu", section, false)) SMC_SetReaders(parser, Config_NewSection, Config_SecondaryKeyValue, Config_EndSection);
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
	if(!strcmp("frag_sound", key, false))		strcopy(g_szFragSound, sizeof(g_szFragSound), value);
	else if(!strcmp("on_spawn", key, false))	g_MenuOnSpawn = !strcmp("yes", value, false);
	else if(!strcmp("allow_c4", key, false))	g_AllowBomb = !strcmp("yes", value, false);
	else if(!strcmp("buy_zones", key, false))	g_AllowBuyMenu = !strcmp("yes", value, false);
	else if(!strcmp("for_all", key, false))		g_AllowGunMenu = !strcmp("yes", value, false);
	else if(!strcmp("allow_t", key, false))		g_AllowT = !strcmp("yes", value, false);
	else if(!strcmp("allow_ct", key, false))	g_AllowCT = !strcmp("yes", value, false);
	else if(!strcmp("allow_bots", key, false))	g_AllowBots = !strcmp("yes", value, false);
	return SMCParse_Continue;
}

public SMCResult:Config_SpawnItemsKeyValue(Handle:parser, const String:key[], const String:value[], bool:key_quotes, bool:value_quotes)
{
	if(!strcmp("armor", key, false))			g_SpawnArmor = StringToInt(value);
	else if(!strcmp("helmet", key, false))		g_SpawnHelmet = !strcmp("yes", value, false);
	else if(!strcmp("flashbangs", key, false))	g_SpawnFlash = StringToInt(value);
	else if(!strcmp("smokegrenade", key, false))g_SpawnSmoke = !strcmp("yes", value, false);
	else if(!strcmp("hegrenade", key, false))	g_SpawnHE = !strcmp("yes", value, false);
	else if(!strcmp("incgrenade", key, false))	g_SpawnInc = !strcmp("yes", value, false);
	else if(!strcmp("tagrenade", key, false))	g_SpawnTA = !strcmp("yes", value, false);
	else if(!strcmp("healthshot", key, false))	g_SpawnHS = StringToInt(value);
	else if(!strcmp("defusekits", key, false))	g_SpawnDefuser = !strcmp("yes", value, false);
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
public MenuHandler_ChoosePrimary(Handle:menu, MenuAction:action, client, param2)
{
	if(action == MenuAction_Display) g_MenuOpen[client] = true;
	else if(action == MenuAction_Select)
	{
		decl String:weapon_id[4];
		GetMenuItem(menu, param2, weapon_id, sizeof(weapon_id));
		new weapon_index = StringToInt(weapon_id, 16);

		g_PlayerPrimary[client] = weapon_index;
		if(Teams:GetClientTeam(client) > CS_TEAM_SPECTATOR) GivePrimary(client);

		DisplayMenu(g_SecondaryMenu, client, MENU_TIME_FOREVER);
	}
	else if(action == MenuAction_Cancel)
	{
		g_MenuOpen[client] = false;
		if(param2 == MenuCancel_Exit && g_SecondaryMenu)	// CancelClientMenu sends MenuCancel_Interrupted reason
			DisplayMenu(g_SecondaryMenu, client, MENU_TIME_FOREVER);
	}
}

// Set Player's Secondary Weapon
public MenuHandler_ChooseSecondary(Handle:menu, MenuAction:action, client, param2)
{
	if(action == MenuAction_Display) g_MenuOpen[client] = true;
	else if(action == MenuAction_Select)
	{
		decl String:weapon_id[4];
		GetMenuItem(menu, param2, weapon_id, sizeof(weapon_id));
		new weapon_index = StringToInt(weapon_id, 16);

		g_PlayerSecondary[client] = weapon_index;
		if(Teams:GetClientTeam(client) > CS_TEAM_SPECTATOR) GiveSecondary(client);
	}
	else if(action == MenuAction_Cancel) g_MenuOpen[client] = false;
}

// After Delay, Show Menu or Give Weapons
public Action:Event_HandleSpawn(Handle:timer, any:user_index)
{
	// This event implies client is in-game while GetClientOfUserId() checks IsClientConnected()
	new client = GetClientOfUserId(user_index);
	if(!client || !IsClientInGame(client) || !g_AllowBots && IsFakeClient(client) || !g_AllowGunMenu && !bIsAdmin[client])
		return;
	new Teams:team = Teams:GetClientTeam(client);
	if(team < CS_TEAM_T || (team == CS_TEAM_T && !g_AllowT || team == CS_TEAM_CT && !g_AllowCT) && !bIsAdmin[client])
		return;

	// Vest Armor
	if(g_SpawnArmor) SetEntData(client, m_ArmorValue, g_SpawnArmor, 1, true);
	// Helmet
	SetEntData(client, m_bHasHelmet, 1&_:g_SpawnHelmet, 1, true);
	// Remove any nades
	StripNades(client);
	// Flash Bangs
	if(g_SpawnFlash)
		for(new i = 1; i <= g_SpawnFlash; i++)
			GivePlayerItem(client, "weapon_flashbang");
	// Smoke Grenade
	if(g_SpawnSmoke) GivePlayerItem(client, "weapon_smokegrenade");
	// HE Grenade
	if(g_SpawnHE) GivePlayerItem(client, "weapon_hegrenade");
	// Incendiary Grenade
	if(g_SpawnInc) GivePlayerItem(client, team == CS_TEAM_CT ? "weapon_incgrenade" : "weapon_molotov");
	// TA Grenade
	if(g_SpawnTA) GivePlayerItem(client, "weapon_tagrenade");
	// Health Shots
	if(g_SpawnHS)
		for(new i = 1; i <= g_SpawnHS; i++)
			GivePlayerItem(client, "weapon_healthshot");
	// Defuser Kit
	if(team == CS_TEAM_CT) SetEntData(client, m_bHasDefuser, 1&_:g_SpawnDefuser, 1, true);

	// Show Menu or Give Guns
	if(g_MenuOnSpawn)
	{
		if(g_PlayerPrimary[client]==SHOW_MENU && g_PlayerSecondary[client]==SHOW_MENU)
		{
			if(g_PrimaryMenu) DisplayMenu(g_PrimaryMenu, client, MENU_TIME_FOREVER);
			else if(g_SecondaryMenu) DisplayMenu(g_SecondaryMenu, client, MENU_TIME_FOREVER);
		}
		else
		{
			GivePrimary(client);
			GiveSecondary(client);
		}
	}
}

stock GivePrimary(client)
{
	new weapon_index = g_PlayerPrimary[client];
	RemoveWeaponBySlot(client, Slot_Primary);
	if(weapon_index == RANDOM_WEAPON) weapon_index = GetRandomInt(0, g_PrimaryGunCount-1);
	if(weapon_index >= 0 && weapon_index < g_PrimaryGunCount) GivePlayerItem(client, g_PrimaryGuns[weapon_index]);
}

stock GiveSecondary(client)
{
	new weapon_index = g_PlayerSecondary[client];
	RemoveWeaponBySlot(client, Slot_Secondary);
	if(weapon_index == RANDOM_WEAPON) weapon_index = GetRandomInt(0, g_SecondaryGunCount-1);
	if(weapon_index >= 0 && weapon_index < g_SecondaryGunCount) GivePlayerItem(client, g_SecondaryGuns[weapon_index]);
}

public Action:Command_GunMenu(client, args)
{
	new Teams:team = Teams:GetClientTeam(client);
	if(IsClientInGame(client) && (team == CS_TEAM_T && g_AllowT || team == CS_TEAM_CT && g_AllowCT))
	{
		if(g_PrimaryMenu) DisplayMenu(g_PrimaryMenu, client, MENU_TIME_FOREVER);
		else if(g_SecondaryMenu) DisplayMenu(g_SecondaryMenu, client, MENU_TIME_FOREVER);
	}
	return Plugin_Handled;
}

stock CheckCloseHandle(&Handle:handle)
{
	if(handle)
	{
		CloseHandle(handle);
		handle = INVALID_HANDLE;
	}
}

stock StripNades(client)
{
	while(RemoveWeaponBySlot(client, Slot_Grenade)) {}
}

stock bool:RemoveWeaponBySlot(client, Slots:slot)
{
	new ent = GetPlayerWeaponSlot(client, _:slot);
	return ent > MaxClients && RemovePlayerItem(client, ent) && AcceptEntityInput(ent, "Kill");
}

stock RemoveBuyZones()
{
	new ent = MaxClients+1;
	while((ent = FindEntityByClassname(ent, "func_buyzone")) != -1) if(IsValidEntity(ent)) AcceptEntityInput(ent, "Kill");
}