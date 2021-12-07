#pragma semicolon 1

#include <sdktools_entinput>
#include <sdktools_functions>
#include <sdktools_sound>
#include <sdktools_stringtables>

// Plugin definitions
#define PL_VER	"1.2.1 (NoRandom)"
#define PL_NAME	"[CS:GO] Gun Menu"

// Constants
enum
{
	Slot_Primary,
	Slot_Secondary,
	Slot_Knife,
	Slot_Grenade,
	Slot_C4,
	Slot_None
};
enum
{
	CS_TEAM_NONE,
	CS_TEAM_SPECTATOR,
	CS_TEAM_T,
	CS_TEAM_CT
};

public Plugin:myinfo =
{
	name		= PL_NAME,
	version		= PL_VER,
	description	= "Lets players select from a menu of allowed weapons.",
	author		= "LumiStance(adapting by Grey83)",
	url			= "https://forums.alliedmods.net/showthread.php?p=2271029"
}

// Weapon Menu Configuration
#define MAX_WEAPON_COUNT 32
#define RANDOM_WEAPON 0x63
#define SHOW_MENU -1
// Weapon Entity Members and Data
new m_ArmorValue = -1,
	m_bHasHelmet = -1,
	m_bHasDefuser = -1;

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

new g_GunCount[2],
	String:g_Guns[2][MAX_WEAPON_COUNT][32];
// Menus
new bool:g_MenuOpen[MAXPLAYERS+1],
	Handle:g_PrimaryMenu,
	Handle:g_SecondaryMenu;
// Player Settings
new g_PlayerWpn[2][MAXPLAYERS+1] = {{-1, ...}, {-1, ...}};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	if(GetEngineVersion() != Engine_CSGO) SetFailState("This game is not supported");

	bLateLoad = late;
}

public OnPluginStart()
{
	// Cache Send Property Offsets
	if((m_ArmorValue = FindSendPropInfo("CCSPlayer", "m_ArmorValue") < 1))
		LogError("Failed to retrieve CCSPlayer::m_ArmorValue offset");
	if((m_bHasHelmet = FindSendPropInfo("CCSPlayer", "m_bHasHelmet") < 1))
		LogError("Failed to retrieve CCSPlayer::m_bHasHelmet offset");
	if((m_bHasDefuser = FindSendPropInfo("CCSPlayer", "m_bHasDefuser") < 1))
		LogError("Failed to retrieve CCSPlayer::m_bHasDefuser offset");

	CreateConVar("csgo_gunmenu_version", PL_VER, PL_NAME, FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_SPONLY);

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

	new i;
	// Remove buy zones from map to disable the buy menu
	if(!g_AllowBuyMenu)
	{
		i = MaxClients+1;
		while((i = FindEntityByClassname(i, "func_buyzone")) != -1) if(IsValidEntity(i)) AcceptEntityInput(i, "Kill");
	}

	// Handle late load
	if(!GetClientCount(true)) return;

	for(i = 1; i <= MaxClients; ++i) if(IsClientInGame(i))
	{
		OnClientPutInServer(i);
		if(IsPlayerAlive(i)) CreateTimer(0.1, Timer_Spawn, GetClientUserId(i));
	}
}

// Must be manually replayed for late load
public OnClientPutInServer(client)
{
	g_MenuOpen[client]=false;

	// Give bots random guns
	g_PlayerWpn[Slot_Primary][client] = g_PlayerWpn[Slot_Secondary][client] = IsFakeClient(client) ? RANDOM_WEAPON : SHOW_MENU;
}

public OnClientPostAdminCheck(client)
{
	if(client) bIsAdmin[client] = !IsFakeClient(client) && CheckCommandAccess(client, "sm_admin", ADMFLAG_GENERIC);
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(0.1, Timer_Spawn, GetEventInt(event, "userid"));
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

public Event_BombPickup(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!g_AllowBomb) RemoveWeaponBySlot(GetClientOfUserId(GetEventInt(event, "userid")), Slot_C4);
}

// If player spectated close any gun menus
public Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client && !IsFakeClient(client) && g_MenuOpen[client] && GetEventInt(event, "team") == CS_TEAM_SPECTATOR)
	{
		CancelClientMenu(client);	// Delayed
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

			if(g_szFragSound[0])
			{
				decl String:buffer[PLATFORM_MAX_PATH];
				PrecacheSound(g_szFragSound, true);
				Format(buffer, sizeof(buffer), "sound/%s", g_szFragSound);
				AddFileToDownloadsTable(buffer);
			}

			g_ConfigTimeStamp = timestamp;
		}
	}
}

stock InitializeMenus()
{
	g_GunCount[Slot_Primary] = 0;
	CheckCloseHandle(g_PrimaryMenu);
	g_PrimaryMenu = CreateMenu(MenuHandler_ChoosePrimary, MenuAction_Display|MenuAction_Select|MenuAction_Cancel);
	SetMenuTitle(g_PrimaryMenu, "Choose a Primary Weapon:");

	g_GunCount[Slot_Secondary] = 0;
	CheckCloseHandle(g_SecondaryMenu);
	g_SecondaryMenu = CreateMenu(MenuHandler_ChooseSecondary, MenuAction_Display|MenuAction_Select|MenuAction_Cancel);
	SetMenuTitle(g_SecondaryMenu, "Choose a Secondary Weapon:");
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

	if(result != SMCError_Okay)
	{
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
		if(!strcmp("Settings", section, false))
			SMC_SetReaders(parser, Config_NewSection, Config_SettingsKeyValue, Config_EndSection);
		else if(!strcmp("SpawnItems", section, false))
			SMC_SetReaders(parser, Config_NewSection, Config_SpawnItemsKeyValue, Config_EndSection);
		else if(!strcmp("PrimaryMenu", section, false))
			SMC_SetReaders(parser, Config_NewSection, Config_PrimaryKeyValue, Config_EndSection);
		else if(!strcmp("SecondaryMenu", section, false))
			SMC_SetReaders(parser, Config_NewSection, Config_SecondaryKeyValue, Config_EndSection);
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

public SMCResult:Config_PrimaryKeyValue(Handle:parser, const String:class[], const String:name[], bool:key_quotes, bool:value_quotes)
{
	FillMenu(Slot_Primary, class, name);
	return SMCParse_Continue;
}

public SMCResult:Config_SecondaryKeyValue(Handle:parser, const String:class[], const String:name[], bool:key_quotes, bool:value_quotes)
{
	FillMenu(Slot_Secondary, class, name);
	return SMCParse_Continue;
}

stock FillMenu(slot, const String:cls[], const String:name[])
{
	if(g_GunCount[slot] >= MAX_WEAPON_COUNT) SetFailState("\nToo many weapons declared!");

	decl String:id[4];
	strcopy(g_Guns[slot][g_GunCount[slot]], sizeof(g_Guns[][]), cls);
	Format(id, sizeof(id), "%02.2X", g_GunCount[slot]++);
	AddMenuItem(slot ? g_SecondaryMenu : g_PrimaryMenu, id, name);
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
		decl String:id[4];
		GetMenuItem(menu, param2, id, sizeof(id));
		SaveWeapon(client, Slot_Primary, StringToInt(id, 16));

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
		decl String:id[4];
		GetMenuItem(menu, param2, id, sizeof(id));
		SaveWeapon(client, Slot_Secondary, StringToInt(id, 16));
	}
	else if(action == MenuAction_Cancel) g_MenuOpen[client] = false;
}

stock SaveWeapon(client, slot, id)
{
	g_PlayerWpn[slot][client] = id;
	if(GetClientTeam(client) > CS_TEAM_SPECTATOR) GiveWeapon(client, slot);
}

GiveWeapon(client, slot)
{
	RemoveWeaponBySlot(client, slot);
	new wpn = g_PlayerWpn[slot][client];
	if(wpn == RANDOM_WEAPON) wpn = GetRandomInt(0, g_GunCount[slot]-1);
	if(wpn >= 0 && wpn < g_GunCount[slot]) GivePlayerItem(client, g_Guns[slot][wpn]);
}

// After Delay, Show Menu or Give Weapons
public Action:Timer_Spawn(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	// This event implies client is in-game while GetClientOfUserId() checks IsClientConnected()
	if(!client || !IsClientInGame(client) || !g_AllowBots && IsFakeClient(client)
	|| !g_AllowGunMenu && !bIsAdmin[client])
		return;

	new team = GetClientTeam(client);
	if(team < CS_TEAM_T || (team == CS_TEAM_T && !g_AllowT || team == CS_TEAM_CT && !g_AllowCT) && !bIsAdmin[client])
		return;

	if(g_SpawnArmor && m_ArmorValue > 0)		// Vest Armor
		SetEntData(client, m_ArmorValue, g_SpawnArmor, 1, true);
	if(m_bHasHelmet > 0)						// Helmet
		SetEntData(client, m_bHasHelmet, 1&_:g_SpawnHelmet, 1, true);
	while(RemoveWeaponBySlot(client, Slot_Grenade)) {}	// Remove any nades
	if(g_SpawnFlash)							// Flash Bangs
		for(new i; i < g_SpawnFlash; i++) GivePlayerItem(client, "weapon_flashbang");
	if(g_SpawnSmoke)							// Smoke Grenade
		GivePlayerItem(client, "weapon_smokegrenade");
	if(g_SpawnHE)								// HE Grenade
		GivePlayerItem(client, "weapon_hegrenade");
	if(g_SpawnInc)								// Incendiary Grenade or Molotov
		GivePlayerItem(client, team == CS_TEAM_CT ? "weapon_incgrenade" : "weapon_molotov");
	if(g_SpawnTA)								// TA Grenade
		GivePlayerItem(client, "weapon_tagrenade");
	if(g_SpawnHS)								// Health Shots
		for(new i; i < g_SpawnHS; i++) GivePlayerItem(client, "weapon_healthshot");
	if(team == CS_TEAM_CT && m_bHasDefuser > 0)	// Defuser Kit
		SetEntData(client, m_bHasDefuser, 1&_:g_SpawnDefuser, 1, true);

	if(g_MenuOnSpawn && !DisplayWeaponMenus(client))	// Show Menu or Give Guns
	{
		GiveWeapon(client, Slot_Primary);
		GiveWeapon(client, Slot_Secondary);
	}
}

public Action:Command_GunMenu(client, args)
{
	if(!client || !IsClientInGame(client))
		return Plugin_Handled;

	new team = GetClientTeam(client);
	if(team == CS_TEAM_T && g_AllowT || team == CS_TEAM_CT && g_AllowCT)
		DisplayWeaponMenus(client);

	return Plugin_Handled;
}

stock bool:DisplayWeaponMenus(client)
{
	if(g_PlayerWpn[Slot_Primary][client] == SHOW_MENU && g_PrimaryMenu)
		DisplayMenu(g_PrimaryMenu, client, MENU_TIME_FOREVER);
	else if(g_PlayerWpn[Slot_Secondary][client] == SHOW_MENU && g_SecondaryMenu)
		DisplayMenu(g_SecondaryMenu, client, MENU_TIME_FOREVER);
	else return false;

	return true;
}

stock CheckCloseHandle(&Handle:handle)
{
	if(handle)
	{
		CloseHandle(handle);
		handle = INVALID_HANDLE;
	}
}

stock bool:RemoveWeaponBySlot(client, slot)
{
	new ent = GetPlayerWeaponSlot(client, slot);
	return ent > MaxClients && RemovePlayerItem(client, ent) && AcceptEntityInput(ent, "Kill");
}