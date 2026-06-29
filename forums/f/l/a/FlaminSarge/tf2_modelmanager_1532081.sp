//Keeping in mind almost all of this is converted from Damizean's TF2 Equipment
//Manager, uh... Good luck and happy reading!
// *********************************************************************************
// PREPROCESSOR
// *********************************************************************************
#pragma semicolon 1				  // Force strict semicolon mode.

// *********************************************************************************
// INCLUDES
// *********************************************************************************
#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <clientprefs>
#include <morecolors>

// *********************************************************************************
// CONSTANTS
// *********************************************************************************
// ---- Plugin-related constants ---------------------------------------------------
#define PLUGIN_NAME				"[TF2] Model Manager"
#define PLUGIN_AUTHOR			"FlaminSarge (based on Damizean's TF2 Equipment Manager)"
#define PLUGIN_VERSION			"1.0.4" //RIP Attachables
#define PLUGIN_CONTACT			"http://forums.alliedmods.net/"
#define CVAR_FLAGS				FCVAR_PLUGIN|FCVAR_NOTIFY

//#define DEBUG					// Uncomment this for debug.information

// ---- Items management -----------------------------------------------------------
#define MAX_ITEMS				256
#define MAX_SLOTS				1
#define MAX_LENGTH				256

// ---- Wearables flags ------------------------------------------------------------
#define PLAYER_ADMIN				(1 << 0)		// Player is admin.
#define PLAYER_OVERRIDE				(1 << 1)		// Player is overriding the restrictions of the items.
#define PLAYER_LOCK					(1 << 2)		// Player has it's equipment locked

#define FLAG_ADMIN_ONLY				(1 << 0)		// Only admins can use this item.
#define FLAG_USER_DEFAULT			(1 << 1)		// This is the forced default for users.
#define FLAG_ADMIN_DEFAULT			(1 << 2)		// This is the forced default for admins.
#define FLAG_HIDDEN					(1 << 3)		// Hidden from list
#define FLAG_INVISIBLE				(1 << 4)		// Invisible! INVISIBLE!
#define FLAG_NO_ANIM				(1 << 5)
#define FLAG_HIDE_HATS				(1 << 6)
#define FLAG_REQUIRES_STEAMID		(1 << 7)
#define FLAG_HIDE_WEAPONS			(1 << 8)		//Not in use yet

// ---- Bodygroup setting flags ----------------------------------------------------
#define FLAG_HIDE_SCOUT_HAT			(1 << 0)
#define FLAG_HIDE_SCOUT_HEADPHONES	(1 << 1)
#define FLAG_HIDE_SCOUT_FEET		(1 << 2)
#define FLAG_HIDE_SCOUT_DOGTAGS		(1 << 3)

#define FLAG_SHOW_SOLDIER_ROCKET	(1 << 4)
#define FLAG_HIDE_SOLDIER_HELMET	(1 << 5)
#define FLAG_HIDE_SOLDIER_GRENADES	(1 << 6)

#define FLAG_HIDE_PYRO_HEAD			(1 << 7)
#define FLAG_HIDE_PYRO_GRENADES		(1 << 8)

#define FLAG_SHOW_DEMO_SMILE		(1 << 9)
#define FLAG_HIDE_DEMO_FEET			(1 << 10)

#define FLAG_HIDE_HEAVY_HANDS		(1 << 11)

#define FLAG_HIDE_ENGINEER_HELMET	(1 << 12)
#define FLAG_SHOW_ENGINEER_ARM		(1 << 13)

#define FLAG_HIDE_MEDIC_BACKPACK	(1 << 14)

#define FLAG_SHOW_SNIPER_ARROWS		(1 << 15)
#define FLAG_HIDE_SNIPER_HAT		(1 << 16)
#define FLAG_SHOW_SNIPER_DARTS		(1 << 17)

#define FLAG_SHOW_SPY_MASK			(1 << 18)

// classes and teams
#define CLASS_UNKNOWN				(1 << 0)
#define CLASS_SCOUT					(1 << 1)
#define CLASS_SNIPER				(1 << 2)
#define CLASS_SOLDIER				(1 << 3)
#define CLASS_DEMOMAN				(1 << 4)
#define CLASS_MEDIC					(1 << 5)
#define CLASS_HEAVY					(1 << 6)
#define CLASS_PYRO					(1 << 7)
#define CLASS_SPY					(1 << 8)
#define CLASS_ENGINEER				(1 << 9)
#define CLASS_ALL					(0b1111111111)

//First two unused
#define TEAM_UNASSIGNED				(1 << 0)
#define TEAM_SPECTATOR				(1 << 1)
#define TEAM_RED					(1 << 2)
#define TEAM_BLU					(1 << 3)

// ---- Engine flags ---------------------------------------------------------------
#define EF_BONEMERGE				(1 << 0)
#define EF_BRIGHTLIGHT				(1 << 1)
#define EF_DIMLIGHT					(1 << 2)
#define EF_NOINTERP					(1 << 3)
#define EF_NOSHADOW					(1 << 4)
#define EF_NODRAW					(1 << 5)
#define EF_NORECEIVESHADOW			(1 << 6)
#define EF_BONEMERGE_FASTCULL		(1 << 7)
#define EF_ITEM_BLINK				(1 << 8)
#define EF_PARENT_ANIMATES			(1 << 9)

// ---- Game bodygroups ------------------------------------------------------------
#define BODYGROUP_SCOUT_HAT				(1 << 0)
#define BODYGROUP_SCOUT_HEADPHONES		(1 << 1)
#define BODYGROUP_SCOUT_SHOESSOCKS		(1 << 2)
#define BODYGROUP_SCOUT_DOGTAGS			(1 << 3)

#define BODYGROUP_SOLDIER_ROCKET		(1 << 0)
#define BODYGROUP_SOLDIER_HELMET		(1 << 1)
#define BODYGROUP_SOLDIER_MEDAL			(1 << 2)
#define BODYGROUP_SOLDIER_GRENADES		(1 << 3)

#define BODYGROUP_PYRO_HEAD				(1 << 0)
#define BODYGROUP_PYRO_GRENADES			(1 << 1)

#define BODYGROUP_DEMO_SMILE			(1 << 0)
#define BODYGROUP_DEMO_SHOES			(1 << 1)

#define BODYGROUP_HEAVY_HANDS			(1 << 0)

#define BODYGROUP_ENGINEER_HELMET		(1 << 0)
#define BODYGROUP_ENGINEER_ARM			(1 << 1)

#define BODYGROUP_MEDIC_BACKPACK		(1 << 0)

#define BODYGROUP_SNIPER_ARROWS			(1 << 0)
#define BODYGROUP_SNIPER_HAT			(1 << 1)
#define BODYGROUP_SNIPER_BULLETS		(1 << 2)

#define BODYGROUP_SPY_MASK				(1 << 0)

// *********************************************************************************
// VARIABLES
// *********************************************************************************

// ---- Player variables -----------------------------------------------------------
new g_iPlayerItem[MAXPLAYERS+1] = { -1, ... };
new g_iPlayerFlags[MAXPLAYERS+1];
new g_iPlayerBGroups[MAXPLAYERS+1];
new bool:g_bRotationTauntSet[MAXPLAYERS + 1] = { false, ... };
new TFClassType:g_iPlayerSpawnClass[MAXPLAYERS + 1] = { TFClass_Unknown, ... };

// ---- Item variables -------------------------------------------------------------
//new g_iSlotsCount;
//new String:g_strSlots[MAX_SLOTS][MAX_LENGTH];			// In a future, perhaps? I THINK NOT.

new g_iItemCount;
new String:g_strItemName[MAX_ITEMS][MAX_LENGTH];
new String:g_strItemModel[MAX_ITEMS][PLATFORM_MAX_PATH];
new g_iItemFlags[MAX_ITEMS];
new g_iItemBodygroupFlags[MAX_ITEMS];
new g_iItemClasses[MAX_ITEMS];
new g_iItemTeams[MAX_ITEMS];
new String:g_strItemAdmin[MAX_ITEMS][256];
new String:g_strItemSteamID[MAX_ITEMS][2048];

// ---- Cvars ----------------------------------------------------------------------
new Handle:g_hCvarVersion			  = INVALID_HANDLE;
//new Handle:g_hCvarAdminOnly			= INVALID_HANDLE;
new Handle:g_hCvarAdminFlags		   = INVALID_HANDLE;
new Handle:g_hCvarAdminOverride		= INVALID_HANDLE;
new Handle:g_hCvarAnnounce			 = INVALID_HANDLE;
new Handle:g_hCvarAnnouncePlugin	   = INVALID_HANDLE;
new Handle:g_hCvarForceDefaultOnUsers  = INVALID_HANDLE;
new Handle:g_hCvarForceDefaultOnAdmins = INVALID_HANDLE;
new Handle:g_hCvarDelayOnSpawn		 = INVALID_HANDLE;
new Handle:g_hCvarBlockTriggers		= INVALID_HANDLE;
new Handle:g_hCvarFileList			= INVALID_HANDLE;

// ---- Others ---------------------------------------------------------------------
//_: tag stops compiler warnings
new Handle:g_hCookies[TFClassType] = { _:INVALID_HANDLE, ... };

//new bool:g_bAdminOnly	  = false;
new bool:g_bAdminOverride  = false;
new bool:g_bAnnounce	   = false;
new bool:g_bAnnouncePlugin = false;
new bool:g_bForceUsers	 = false;
new bool:g_bForceAdmins	= false;
new bool:g_bBlockTriggers  = false;
new Float:g_fSpawnDelay	= 0.0;
new String:g_strAdminFlags[32];
new String:g_strConfigFilePath[PLATFORM_MAX_PATH];

new Handle:g_hMenuMain   = INVALID_HANDLE;
//new Handle:g_hMenuEquip  = INVALID_HANDLE;
//new Handle:g_hMenuRemove = INVALID_HANDLE;

// *********************************************************************************
// PLUGIN
// *********************************************************************************
public Plugin:myinfo =
{
	name		= PLUGIN_NAME,
	author	  = PLUGIN_AUTHOR,
	description = PLUGIN_NAME,
	version	 = PLUGIN_VERSION,
	url		 = PLUGIN_CONTACT
};
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	//morecolors.inc should really just be a plugin at this point
	MarkNativeAsOptional("GetUserMessageType");
	MarkNativeAsOptional("PbSetInt");
	MarkNativeAsOptional("PbSetBool");
	MarkNativeAsOptional("PbSetString");
	MarkNativeAsOptional("PbAddString");
	return APLRes_Success;
}
// *********************************************************************************
// METHODS
// *********************************************************************************

// =====[ BASIC PLUGIN MANAGEMENT ]========================================

// ------------------------------------------------------------------------
// OnPluginStart()
// ------------------------------------------------------------------------
// At plugin start, create and hook all the proper events to manage the
// wearable items.
// ------------------------------------------------------------------------
public OnPluginStart()
{

	LoadTranslations("common.phrases");

	// Plugin is TF2 only, so make sure it's ran on TF
	decl String:strModName[32]; GetGameFolderName(strModName, sizeof(strModName));
	if (!StrEqual(strModName, "tf"))
	{
		SetFailState("[SM] TF2 Model Manager is only for, of course, TF2.");
		return;
	}

	// Create plugin cvars
	g_hCvarVersion				= CreateConVar("tf_models_version", PLUGIN_VERSION, PLUGIN_NAME, CVAR_FLAGS|FCVAR_SPONLY);
	g_hCvarAdminFlags			= CreateConVar("tf_models_admin_flags",		"b",	"Only users with one of these flags are considered administrators.",	CVAR_FLAGS);
//	g_hCvarAdminOnly			= CreateConVar("tf_models_admin",			"0",	"Only administrators can use the models.",								CVAR_FLAGS);
	g_hCvarAdminOverride		= CreateConVar("tf_models_admin_override",	"0",	"Administrators with access to tf_models_admin_override_access will see all items in the list, not just their class/team", CVAR_FLAGS);
	g_hCvarAnnounce				= CreateConVar("tf_models_announce",		"1",	"Announces usage and tips about equippable models.",					CVAR_FLAGS);
	g_hCvarAnnouncePlugin		= CreateConVar("tf_models_announce_plugin",	"1",	"Announces information of the plugin when joining.",					CVAR_FLAGS);
	g_hCvarForceDefaultOnUsers	= CreateConVar("tf_models_force_users",		"0",	"Forces the default model for common users.",							CVAR_FLAGS);
	g_hCvarForceDefaultOnAdmins	= CreateConVar("tf_models_force_admins",	"0",	"Forces the default model for admin users.",							CVAR_FLAGS);
	g_hCvarDelayOnSpawn			= CreateConVar("tf_models_delayonspawn",	"0.1",	"Amount of time to wait to re-equip models after spawn.",				CVAR_FLAGS);
	g_hCvarBlockTriggers		= CreateConVar("tf_models_blocktriggers",	"1",	"!commands won't appear in chat.",										CVAR_FLAGS);
	g_hCvarFileList				= CreateConVar("tf_models_list", "tf2_modellist",	"Which file to use as the model list, relative to sourcemod/configs/tf2modelmanager/ folder", CVAR_FLAGS);

	// Create cookies; the _: tags are just to stop compiler warnings, and shouldn't cause an issue
	g_hCookies[TFClass_DemoMan]		= _:RegClientCookie("tf_modelmanager_demoman", "", CookieAccess_Protected);
//	g_hCookies[TFClass_DemoMan][1]  = RegClientCookie("tf_modelmanager_demoman_1", "", CookieAccess_Protected);
//	g_hCookies[TFClass_DemoMan][2]  = RegClientCookie("tf_modelmanager_demoman_2", "", CookieAccess_Protected);

	g_hCookies[TFClass_Engineer]	= _:RegClientCookie("tf_modelmanager_engineer", "", CookieAccess_Protected);
//	g_hCookies[TFClass_Engineer][1] = RegClientCookie("tf_modelmanager_engineer_1", "", CookieAccess_Protected);
//	g_hCookies[TFClass_Engineer][2] = RegClientCookie("tf_modelmanager_engineer_2", "", CookieAccess_Protected);

	g_hCookies[TFClass_Heavy]		= _:RegClientCookie("tf_modelmanager_heavy", "", CookieAccess_Protected);
//	g_hCookies[TFClass_Heavy][1]	= RegClientCookie("tf_modelmanager_heavy_1", "", CookieAccess_Protected);
//	g_hCookies[TFClass_Heavy][2]	= RegClientCookie("tf_modelmanager_heavy_2", "", CookieAccess_Protected);

	g_hCookies[TFClass_Medic]		= _:RegClientCookie("tf_modelmanager_medic", "", CookieAccess_Protected);
//	g_hCookies[TFClass_Medic][1]	= RegClientCookie("tf_modelmanager_medic_1", "", CookieAccess_Protected);

	g_hCookies[TFClass_Pyro]		= _:RegClientCookie("tf_modelmanager_pyro", "", CookieAccess_Protected);
//	g_hCookies[TFClass_Pyro][1]	 = RegClientCookie("tf_modelmanager_pyro_1", "", CookieAccess_Protected);

	g_hCookies[TFClass_Scout]		= _:RegClientCookie("tf_modelmanager_scout", "", CookieAccess_Protected);
//	g_hCookies[TFClass_Scout][1]	= RegClientCookie("tf_modelmanager_scout_1", "", CookieAccess_Protected);

	g_hCookies[TFClass_Sniper]		= _:RegClientCookie("tf_modelmanager_sniper", "", CookieAccess_Protected);
//	g_hCookies[TFClass_Sniper][1]   = RegClientCookie("tf_modelmanager_sniper_1", "", CookieAccess_Protected);

	g_hCookies[TFClass_Soldier]		= _:RegClientCookie("tf_modelmanager_soldier", "", CookieAccess_Protected);
//	g_hCookies[TFClass_Soldier][1]  = RegClientCookie("tf_modelmanager_soldier_1", "", CookieAccess_Protected);

	g_hCookies[TFClass_Spy]			= _:RegClientCookie("tf_modelmanager_spy", "", CookieAccess_Protected);
//	g_hCookies[TFClass_Spy][1]	  = RegClientCookie("tf_modelmanager_spy_1", "", CookieAccess_Protected);

	// Startup extended stocks
//	TF2_SdkStartup();

	// Register console commands
	RegAdminCmd("tf_models",			Cmd_Menu, 0, "Shows the model manager menu");
	RegAdminCmd("equipmodels",			Cmd_Menu, 0, "Shows the model manager menu");
	RegAdminCmd("equip",				Cmd_Menu, 0, "Shows the model manager menu");
	RegAdminCmd("mm",					Cmd_Menu, 0, "Shows the model manager menu");
	RegAdminCmd("em",					Cmd_Menu, 0, "Shows the model manager menu");
	RegAdminCmd("tf_models_equip",	Cmd_EquipItem,		 ADMFLAG_CHEATS, "Forces to equip a model onto a client.");
	RegAdminCmd("tf_models_remove",   Cmd_RemoveItem,		ADMFLAG_CHEATS, "Forces to remove a model on the client.");
	RegAdminCmd("tf_models_lock",	 Cmd_LockEquipment,	 ADMFLAG_CHEATS, "Locks/unlocks the client's model so it can't be changed.");
	RegAdminCmd("tf_models_override", Cmd_OverrideEquipment, ADMFLAG_CHEATS, "Enables restriction overriding for the client.");
	RegAdminCmd("tf_models_reload",   Cmd_Reload,			ADMFLAG_CHEATS, "Reparses the items file and rebuilds the model list.");
	AddCommandListener(Cmd_BlockTriggers, "say");
	AddCommandListener(Cmd_BlockTriggers, "say_team");
//	RegConsoleCmd("say", Cmd_BlockTriggers);
//	RegConsoleCmd("say_team", Cmd_BlockTriggers);

	// Hook the proper events and cvars
	HookEvent("post_inventory_application", Event_EquipItem,  EventHookMode_Post);
	HookEvent("player_spawn", Event_RemoveItem,  EventHookMode_Post);
//	HookEvent("player_changeclass", Event_RemoveItem,  EventHookMode_Pre);
//	HookEntityOutput("prop_dynamic", "OnAnimationBegun", Entity_Resupply);
	HookConVarChange(g_hCvarAdminFlags,		   Cvar_UpdateCfg);
//	HookConVarChange(g_hCvarAdminOnly,			Cvar_UpdateCfg);
	HookConVarChange(g_hCvarAdminOverride,		Cvar_UpdateCfg);
	HookConVarChange(g_hCvarAnnounce,			 Cvar_UpdateCfg);
	HookConVarChange(g_hCvarAnnouncePlugin,	   Cvar_UpdateCfg);
	HookConVarChange(g_hCvarForceDefaultOnUsers,  Cvar_UpdateCfg);
	HookConVarChange(g_hCvarForceDefaultOnAdmins, Cvar_UpdateCfg);
	HookConVarChange(g_hCvarDelayOnSpawn,		 Cvar_UpdateCfg);
//	HookConVarChange(g_hCvarFileList,		Cvar_UpdateCfg);

	// Load translations for this plugin
	LoadTranslations("tf2_modelmanager.phrases");

	// Execute configs.
	AutoExecConfig(true, "tf2_modelmanager");

	// Create announcement timer.
	CreateTimer(900.0, Timer_Announce, _, TIMER_REPEAT);
}

// ------------------------------------------------------------------------
// OnPluginEnd()
// ------------------------------------------------------------------------
public OnPluginEnd()
{
	// Destroy all entities for everyone, if possible.
	for (new client=1; client<=MaxClients; client++)
	{
		if (!IsValidClient(client)) continue;
		if (g_iPlayerItem[client] == -1) continue;
		SetVariantString("");
		AcceptEntityInput(client, "SetCustomModel");
	}
}

// ------------------------------------------------------------------------
// Event_RemoveItem()
// ------------------------------------------------------------------------
// On player's death destroy the entity that's meant to be visible for the
// other players.
// ------------------------------------------------------------------------
public Event_RemoveItem(Handle:hEvent, String:strName[], bool:bDontBroadcast)
{
	new flags = GetEventInt(hEvent, "death_flags");
	if (flags & TF_DEATHFLAG_DEADRINGER) return;
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	Item_Remove(client);
}

// ------------------------------------------------------------------------
// OnConfigsExecuted()
// ------------------------------------------------------------------------
public OnConfigsExecuted()
{
	// Determine if the version of the cfg is the correct one
	new String:strVersion[16]; GetConVarString(g_hCvarVersion, strVersion, sizeof(strVersion));
	if (!StrEqual(strVersion, PLUGIN_VERSION, false))
	{
		LogError("[TF2] Model Manager: WARNING- Your config file might be outdated! This may lead to conflicts with \
		the plugin and non-working cfg. Fix this by backing up then deleting your current config and changing the \
		map. It'll generate a new config with the default cfg, after which you can put in your settings.");
	}
	SetConVarString(g_hCvarVersion, PLUGIN_VERSION);
	// Force Cfg update
	Cvar_UpdateCfg(INVALID_HANDLE, "", "");
	Configs_ItemListParse();	//Item list, hopefully this is before clients join
}

// ------------------------------------------------------------------------
// UpdateCfg()
// ------------------------------------------------------------------------
public Cvar_UpdateCfg(Handle:hHandle, String:strOldVal[], String:strNewVal[])
{
//	g_bAdminOnly	  = GetConVarBool(g_hCvarAdminOnly);
	g_bAdminOverride  = GetConVarBool(g_hCvarAdminOverride);
	g_bAnnounce	   = GetConVarBool(g_hCvarAnnounce);
	g_bAnnouncePlugin = GetConVarBool(g_hCvarAnnouncePlugin);
	g_bForceUsers	 = GetConVarBool(g_hCvarForceDefaultOnUsers);
	g_bForceAdmins	= GetConVarBool(g_hCvarForceDefaultOnAdmins);
	g_fSpawnDelay	 = GetConVarFloat(g_hCvarDelayOnSpawn);
	g_bBlockTriggers  = GetConVarBool(g_hCvarBlockTriggers);
	GetConVarString(g_hCvarAdminFlags, g_strAdminFlags, sizeof(g_strAdminFlags));
//	for (new i = 1; i <= MaxClients; i++)
//	{
//		if (!IsValidClient(i)) continue;
//		OnClientPostAdminCheck(i);
//	}
//	GetConVarString(g_hCvarFileList, g_strConfigFilePath, sizeof(g_strConfigFilePath));
}

// ------------------------------------------------------------------------
// Used to be OnMapStart()
// ------------------------------------------------------------------------
// At map start, make sure to reset all the values for all the clients
// to the default. Also, reparse the items list and rebuild the
// basic menus.
// ------------------------------------------------------------------------
public Configs_ItemListParse()
{
	// Reset player's slots
	for (new client=1; client<=MaxClients; client++)
	{
		g_iPlayerFlags[client] = 0;
		g_iPlayerItem[client] = -1;
	}

	// Reparse and re-build the menus
	GetConVarString(g_hCvarFileList, g_strConfigFilePath, sizeof(g_strConfigFilePath));
	Item_ParseList();
	g_hMenuMain   = Menu_BuildMain();
//	g_hMenuEquip  = Menu_BuildSlots("EquipItem");
//	g_hMenuRemove = Menu_BuildSlots("RemoveSlot");
}

// ------------------------------------------------------------------------
// OnMapEnd()
// ------------------------------------------------------------------------
// At map end, destroy all the built menus.
// ------------------------------------------------------------------------
public OnMapEnd()
{
	// Destroy menus
	if (g_hMenuMain   != INVALID_HANDLE) { CloseHandle(g_hMenuMain);   g_hMenuMain   = INVALID_HANDLE; }
//	if (g_hMenuEquip  != INVALID_HANDLE) { CloseHandle(g_hMenuEquip);  g_hMenuEquip  = INVALID_HANDLE; }
//	if (g_hMenuRemove != INVALID_HANDLE) { CloseHandle(g_hMenuRemove); g_hMenuRemove = INVALID_HANDLE; }
}

// ------------------------------------------------------------------------
// OnClientPutInServer()
// ------------------------------------------------------------------------
// When a client is put in server, greet the player and show off information
// about the plugin.
// ------------------------------------------------------------------------
public OnClientPutInServer(client)
{
	g_bRotationTauntSet[client] = false;
	g_iPlayerSpawnClass[client] = TFClass_Unknown;
	g_iPlayerFlags[client] = 0;
	g_iPlayerItem[client] = -1;
	g_iPlayerBGroups[client] = 0;
	if (g_bAnnouncePlugin)
	{
		CreateTimer(30.0, Timer_Welcome, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
}
/*
// ------------------------------------------------------------------------
// OnClientPostAdminCheck()
// ------------------------------------------------------------------------
// Identify the client that just connected, checking if at least one of the
// flags listed in the cvar.
// ------------------------------------------------------------------------
public OnClientPostAdminCheck(client)
{
	//Delay this so that any changes made to admins on PostAdminCheck are applied
	CreateTimer(0.1, Timer_CheckUserAdmin, GetClientUserId(client));
}
public Action:Timer_CheckUserAdmin(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (!IsValidClient(client)) return;
	// Retrieve needed flags and determine if the player is an admin.
	new ibFlags = ReadFlagString(g_strAdminFlags);

	// Test and setup flag if so.
	new AdminId:admin = GetUserAdmin(client);
	if (admin == INVALID_ADMIN_ID) return;
	if (GetAdminFlags(admin, Access_Effective) & (ibFlags|ADMFLAG_ROOT))	g_iPlayerFlags[client] |= PLAYER_ADMIN;
}*/
public TF2_OnConditionAdded(client, TFCond:condition)
{
	if (condition == TFCond_Taunting && GetEntProp(client, Prop_Send, "m_bCustomModelRotates") && !g_bRotationTauntSet[client])
	{
		SetEntProp(client, Prop_Send, "m_bCustomModelRotates", 0);
		g_bRotationTauntSet[client] = true;
	}
}
public TF2_OnConditionRemoved(client, TFCond:condition)
{
	if (condition == TFCond_Taunting && !GetEntProp(client, Prop_Send, "m_bCustomModelRotates") && g_bRotationTauntSet[client])
	{
		SetEntProp(client, Prop_Send, "m_bCustomModelRotates", 1);
		g_bRotationTauntSet[client] = false;
	}
}
// ------------------------------------------------------------------------
// Event_EquipItem()
// ------------------------------------------------------------------------
// On the player spawn (or any other event that requires re-equipment) we
// requip the items the player had selected. If none are found, we also check
// if we should force one upon the player.
// ------------------------------------------------------------------------
public Event_EquipItem(Handle:hEvent, String:strName[], bool:bDontBroadcast)
{
	new userid = GetEventInt(hEvent, "userid");
	new client = GetClientOfUserId(userid);
	if (IsValidClient(client))
	{
		new TFClassType:class = TF2_GetPlayerClass(client);
		if (class != TFClass_Unknown && class != g_iPlayerSpawnClass[client])
		{
			Item_Remove(client);
		}
		g_iPlayerSpawnClass[client] = class;
		CreateTimer(g_fSpawnDelay, Timer_EquipItem, userid, TIMER_FLAG_NO_MAPCHANGE);
		RemoveValveHat(client, true);
		HideWeapons(client, true);
	}
}

public Action:Timer_EquipItem(Handle:hTimer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (!IsValidClient(client)) return Plugin_Continue;
	if (!IsPlayerAlive(client)) return Plugin_Continue;

	// Retrieve current player bodygroups status.
	g_iPlayerBGroups[client] = GetEntProp(client, Prop_Send, "m_nBody");

	// Retrieve the proper cookie value
	g_iPlayerItem[client] = Item_RetrieveSlotCookie(client);

	// Determine if the hats are still valid for the
	// client.
	if (!Item_IsWearable(client, g_iPlayerItem[client]))
	{
		Item_Remove(client);
		g_iPlayerItem[client] = Item_FindDefaultItem(client);
	}

	// Equip the player with the selected item.
	Item_Equip(client, g_iPlayerItem[client]);

	return Plugin_Continue;
}

// ------------------------------------------------------------------------
// OnClientDisconnect()
// ------------------------------------------------------------------------
// When the client disconnects, remove it's equipped items and reset all
// the flags.
// ------------------------------------------------------------------------
public OnClientDisconnect(client)
{
	Item_Remove(client, false);
	g_iPlayerFlags[client] = 0;
	g_bRotationTauntSet[client] = false;
	g_iPlayerSpawnClass[client] = TFClass_Unknown;
	g_iPlayerFlags[client] = 0;
	g_iPlayerBGroups[client] = 0;
}

// ------------------------------------------------------------------------
// Item_Equip
// ------------------------------------------------------------------------
// Equip the desired item onto a client.
// ------------------------------------------------------------------------
Item_Equip(client, iItem)
{
	// Assert if the player is alive.
	if (!IsValidClient(client)) return;
	if (!Item_IsWearable(client, iItem)) return;

	// If the player's alive...
	if (IsPlayerAlive(client))
	{
		// Remove the previous entities if it's possible.
		Item_Remove(client, false);

		// If we're about to equip an invisible item, there's no need
		// to generate entities.
		if (!(g_iItemFlags[iItem] & FLAG_INVISIBLE))
		{
			SetVariantString(g_strItemModel[iItem]);
			AcceptEntityInput(client, "SetCustomModel");
			SetEntProp(client, Prop_Send, "m_bCustomModelRotates", !!(g_iItemFlags[iItem] & FLAG_NO_ANIM));
			SetEntProp(client, Prop_Send, "m_bUseClassAnimations", !(g_iItemFlags[iItem] & FLAG_NO_ANIM));
		}

		// Change player's item index
		g_iPlayerItem[client] = iItem;

		// Change the visible body parts.
		//SetEntProp(client, Prop_Send, "m_nBody", g_iPlayerBGroups[client] | Item_DetermineBodyGroups(client));
		SetEntProp(client, Prop_Send, "m_nBody", CalculateBodyGroups(client));

		if (g_iItemFlags[iItem] & FLAG_HIDE_HATS) RemoveValveHat(client);
		if (g_iItemFlags[iItem] & FLAG_HIDE_WEAPONS) HideWeapons(client);
	}
}
Item_Equip_Admin_Force(client, iItem)
{
	// Assert if the player is alive.
	if (!IsValidClient(client)) return;
	if (!Item_IsWearable_Admin_Force(client, iItem)) return;

	if (IsPlayerAlive(client))
	{
		// Remove the previous entities if it's possible.
		Item_Remove(client, false);

		// If we're about to equip an invisible item, there's no need
		// to generate entities.
		if (!(g_iItemFlags[iItem] & FLAG_INVISIBLE))
		{
			SetVariantString(g_strItemModel[iItem]);
			AcceptEntityInput(client, "SetCustomModel");
			SetEntProp(client, Prop_Send, "m_bCustomModelRotates", !!(g_iItemFlags[iItem] & FLAG_NO_ANIM));
			SetEntProp(client, Prop_Send, "m_bUseClassAnimations", !(g_iItemFlags[iItem] & FLAG_NO_ANIM));
		}

		// Change player's item index
		g_iPlayerItem[client] = iItem;

		// Change the visible body parts.
		//SetEntProp(client, Prop_Send, "m_nBody", g_iPlayerBGroups[client] | Item_DetermineBodyGroups(client));
		SetEntProp(client, Prop_Send, "m_nBody", CalculateBodyGroups(client));

		if (g_iItemFlags[iItem] & FLAG_HIDE_HATS) RemoveValveHat(client);
		if (g_iItemFlags[iItem] & FLAG_HIDE_WEAPONS) HideWeapons(client);
	}
}

// ------------------------------------------------------------------------
// Item_Remove
// ------------------------------------------------------------------------
// Remove the item equipped at the selected slot.
// ------------------------------------------------------------------------
Item_Remove(client, bool:bCheck = true)
{
	// Assert if the player is valid.
	if (bCheck == true && !IsValidClient(client)) return;
	if (g_iPlayerItem[client] == -1) return;
	if (IsValidClient(client))
	{
		SetVariantString("");
		AcceptEntityInput(client, "SetCustomModel");
		SetEntProp(client, Prop_Send, "m_bCustomModelRotates", 0);
		SetVariantString("ParticleEffectStop");
		AcceptEntityInput(client, "DispatchEffect");

		// Recalculate body groups, probably entirely unnecessary
		SetEntProp(client, Prop_Send, "m_nBody", CalculateBodyGroups(client));
	}
	g_iPlayerItem[client] = -1;
}

// ------------------------------------------------------------------------
// Item_ParseList()
// ------------------------------------------------------------------------
// Parse the items list and precache all the needed models through the
// dependencies file.
// ------------------------------------------------------------------------
Item_ParseList()
{
	// Parse the objects list key values text to acquire all the possible
	// wearable items.
	new Handle:kvItemList = CreateKeyValues("tf2_modelmanager");
	new Handle:hStream = INVALID_HANDLE;
	new String:strLocation[256];
	new String:strDependencies[256];
	new String:strLine[256];
	new String:strExtraError[128];

	// Load the key files.

	BuildPath(Path_SM, strLocation, sizeof(strLocation), "configs/tf2modelmanager/%s.cfg", g_strConfigFilePath);
	if (!FileExists(strLocation, false) && !FileExists(strLocation, true)) { SetFailState("Error, file containing item list not found : %s", strLocation); return; }
	FileToKeyValues(kvItemList, strLocation);

	// Check if the parsed values are correct
	if (!KvGotoFirstSubKey(kvItemList)) { SetFailState("Error, found item list file, but can't read it : %s", strLocation); return; }
	g_iItemCount = 0;

	#if defined DEBUG
	LogMessage("Parsing item list {");
	#endif

	// Iterate through all keys.
	do
	{
		// Retrieve section name, which is pretty much the name of the wearable. Also, parse the model.
		KvGetSectionName(kvItemList,		g_strItemName[g_iItemCount],  MAX_LENGTH);
		KvGetString(kvItemList, "model",	g_strItemModel[g_iItemCount], PLATFORM_MAX_PATH);
		KvGetString(kvItemList, "flags",	strLine, sizeof(strLine)); g_iItemFlags[g_iItemCount]   = Item_ParseFlags(strLine);
		KvGetString(kvItemList, "bodygroups",	strLine, sizeof(strLine)); g_iItemBodygroupFlags[g_iItemCount]   = Item_ParseBodygroupFlags(strLine);
		KvGetString(kvItemList, "classes", strLine, sizeof(strLine)); g_iItemClasses[g_iItemCount] = Item_ParseClasses(strLine);
		KvGetString(kvItemList, "teams",   strLine, sizeof(strLine)); g_iItemTeams[g_iItemCount]   = Item_ParseTeams(strLine);
		KvGetString(kvItemList, "admin", strLine, sizeof(strLine)); Item_ParseAdmin(g_strItemAdmin[g_iItemCount], 256, strLine);
		KvGetString(kvItemList, "steamid", g_strItemSteamID[g_iItemCount], 2048, "");
		if (strlen(g_strItemSteamID[g_iItemCount]) != 0)
			g_iItemFlags[g_iItemCount] |= FLAG_REQUIRES_STEAMID;
//		if (g_iItemFlags[g_iItemCount] & FLAG_INVISREQ) g_Invis_Req[g_iItemCount] = 1;

		#if defined DEBUG
		LogMessage("	Found item -> %s", g_strItemName[g_iItemCount]);
		LogMessage("		- Model : \"%s\"", g_strItemModel[g_iItemCount]);
		LogMessage("		- Flags : %b", g_iItemFlags[g_iItemCount]);
		LogMessage("		- Bodygroups : %b", g_iItemBodygroupFlags[g_iItemCount]);
		LogMessage("		- Class : %08b", g_iItemClasses[g_iItemCount]);
		LogMessage("		- Teams : %02b", g_iItemTeams[g_iItemCount]);
		LogMessage("		- Admin : %s", g_strItemAdmin[g_iItemCount]);
		LogMessage("		- SteamID : %s", g_strItemSteamID[g_iItemCount]);
		#endif

		// If it's invisible, skip. Damizean, what was the point of this, even, in the original Equipment Manager?
		if (!(g_iItemFlags[g_iItemCount] & FLAG_INVISIBLE))
		{
			// Check if model exists, so we can prevent crashes.
			if (!FileExists(g_strItemModel[g_iItemCount], true))
			{
				LogError("[TF2] Model Manager: File \"%s\" not found. Excluding from list.", g_strItemModel[g_iItemCount]);
				continue;
			}

			// Check if the admin wants to use a Valve model, warn them that it breaks hats. This is moot now.
//			if (CheckOfficialValveModel(g_strItemModel[g_iItemCount]))
//			{
//				LogError("[TF2] Model Manager: Trying to access an official Valve hat model file (\"%s\").\n	Be warned, this may cause all instances of that hat (even legitimate ones) to become invisible.", g_strItemModel[g_iItemCount]);
//			}

			// Retrieve dependencies file and open if possible.
			Format(strDependencies, sizeof(strDependencies), "%s.dep", g_strItemModel[g_iItemCount]);
			if (FileExists(strDependencies, true))
			{
				#if defined DEBUG
				LogMessage("		- Found dependencies file. Trying to read.");
				#endif

				// Open stream, if possible
				hStream = OpenFile(strDependencies, "r");
				if (hStream == INVALID_HANDLE)
				{
					if (!FileExists(strDependencies)) Format(strExtraError, sizeof(strExtraError), " The .dep file must be moved to tf/%s.dep, if it is in the tf/custom/ folder.", g_strItemModel[g_iItemCount]);
					else strExtraError = "";
					LogError("[TF2] Model Manager: Error, can't read file containing model dependencies (\"%s.dep\").%s", g_strItemModel[g_iItemCount], strExtraError);
					return;
				}

				while(!IsEndOfFile(hStream))
				{
					// Try to read line. If EOF has been hit, exit.
					ReadFileLine(hStream, strLine, sizeof(strLine));

					// Cleanup line
					CleanString(strLine);

					#if defined DEBUG
					LogMessage("			+ File: \"%s\"", strLine);
					#endif
					// If file exists...
					if (!FileExists(strLine, true))
					{
						continue;
					}

					// Precache depending on type, and add to download table
					if (StrContains(strLine, ".vmt", false) != -1)	  PrecacheDecal(strLine, true);
					else if (StrContains(strLine, ".mdl", false) != -1) PrecacheModel(strLine, true);
					else if (StrContains(strLine, ".pcf", false) != -1) PrecacheGeneric(strLine, true);
					AddFileToDownloadsTable(strLine);
				}

				// Close file
				CloseHandle(hStream);
			}
			PrecacheModel(g_strItemModel[g_iItemCount], true);
		}

		// Go to next.
		g_iItemCount++;
	}
	while (KvGotoNextKey(kvItemList) && g_iItemCount < MAX_ITEMS);
	if (g_iItemCount == MAX_ITEMS) LogMessage("[TF2] Model Manager: Max number of models (%d) found, no more will be added to the list to help prevent overflowing server precache tables", MAX_ITEMS);

	CloseHandle(kvItemList);
	#if defined DEBUG
	LogMessage("}");
	#endif
}
stock bool:CheckOfficialValveModel(String:model[])
{
	if (strncmp(model, "models/player/items", 19, false) != 0) return false;
	if (StrContains(model, "shield", false) != -1) return false;
	if (StrContains(model, "guitar", false) != -1) return false;
	if (StrContains(model, "tankerboots", false) != -1) return false;
	if (StrContains(model, "pegleg", false) != -1) return false;
	if (StrContains(model, "booties", false) != -1) return false;
	return true;
}
// ------------------------------------------------------------------------
// Item_ParseFlags()
// ------------------------------------------------------------------------
// Parses the items flags, duh.
// ------------------------------------------------------------------------
Item_ParseFlags(String:strFlags[])
{
	new Flags;
	if (StrContains(strFlags, "USER_DEFAULT", false)			!= -1) 	Flags |= FLAG_USER_DEFAULT;
	if (StrContains(strFlags, "ADMIN_DEFAULT", false)			!= -1) 	Flags |= FLAG_ADMIN_DEFAULT;
	if (StrContains(strFlags, "ADMIN_ONLY", false)				!= -1) 	Flags |= FLAG_ADMIN_ONLY;
	if (StrContains(strFlags, "HIDDEN", false)					!= -1)	Flags |= FLAG_HIDDEN;
	if (StrContains(strFlags, "INVISIBLE", false)				!= -1)	Flags |= FLAG_INVISIBLE;
	if (StrContains(strFlags, "REMOVE_VALVE", false)			!= -1)	Flags |= FLAG_HIDE_HATS;
	if (StrContains(strFlags, "HIDE_HATS", false)				!= -1)	Flags |= FLAG_HIDE_HATS;
	if (StrContains(strFlags, "NO_ANIM", false)					!= -1)	Flags |= FLAG_NO_ANIM;
	if (StrContains(strFlags, "HIDE_WEAPONS", false)			!= -1)	Flags |= FLAG_HIDE_WEAPONS;

	return Flags;
}

Item_ParseBodygroupFlags(String:strFlags[])
{
	new bgFlags;
	if (StrContains(strFlags, "HIDE_SCOUT_HAT", false)			!= -1)	bgFlags |= FLAG_HIDE_SCOUT_HAT;
	if (StrContains(strFlags, "HIDE_SCOUT_HEADPHONES", false)	!= -1)	bgFlags |= FLAG_HIDE_SCOUT_HEADPHONES;
	if (StrContains(strFlags, "HIDE_SCOUT_FEET", false)			!= -1)	bgFlags |= FLAG_HIDE_SCOUT_FEET;
	if (StrContains(strFlags, "HIDE_SCOUT_DOGTAGS", false)		!= -1)	bgFlags |= FLAG_HIDE_SCOUT_DOGTAGS;

	if (StrContains(strFlags, "SHOW_SOLDIER_ROCKET", false)		!= -1)	bgFlags |= FLAG_SHOW_SOLDIER_ROCKET;
	if (StrContains(strFlags, "HIDE_SOLDIER_HELMET", false)		!= -1)	bgFlags |= FLAG_HIDE_SOLDIER_HELMET;
	if (StrContains(strFlags, "HIDE_SOLDIER_GRENADES", false)	!= -1)	bgFlags |= FLAG_HIDE_SOLDIER_GRENADES;

	if (StrContains(strFlags, "HIDE_PYRO_HEAD", false)			!= -1)	bgFlags |= FLAG_HIDE_PYRO_HEAD;
	if (StrContains(strFlags, "HIDE_PYRO_GRENADES", false)		!= -1)	bgFlags |= FLAG_HIDE_PYRO_GRENADES;

	if (StrContains(strFlags, "SHOW_DEMO_SMILE", false)			!= -1)	bgFlags |= FLAG_SHOW_DEMO_SMILE;
	if (StrContains(strFlags, "HIDE_DEMO_FEET", false)			!= -1)	bgFlags |= FLAG_HIDE_DEMO_FEET;

	if (StrContains(strFlags, "HIDE_HEAVY_HANDS", false)		!= -1)	bgFlags |= FLAG_HIDE_HEAVY_HANDS;

	if (StrContains(strFlags, "HIDE_ENGINEER_HELMET", false)	!= -1)	bgFlags |= FLAG_HIDE_ENGINEER_HELMET;
	if (StrContains(strFlags, "SHOW_ENGINEER_ROBOTARM", false)	!= -1)	bgFlags |= FLAG_SHOW_ENGINEER_ARM;

	if (StrContains(strFlags, "HIDE_MEDIC_BACKPACK", false)		!= -1)	bgFlags |= FLAG_HIDE_MEDIC_BACKPACK;

	if (StrContains(strFlags, "SHOW_SNIPER_ARROWS", false)		!= -1)	bgFlags |= FLAG_SHOW_SNIPER_ARROWS;
	if (StrContains(strFlags, "HIDE_SNIPER_HAT", false)			!= -1)	bgFlags |= FLAG_HIDE_SNIPER_HAT;
	if (StrContains(strFlags, "SHOW_SNIPER_DARTS", false)		!= -1)	bgFlags |= FLAG_SHOW_SNIPER_DARTS;

	if (StrContains(strFlags, "SHOW_SPY_MASK", false)			!= -1)	bgFlags |= FLAG_SHOW_SPY_MASK;

	return bgFlags;
}
// ------------------------------------------------------------------------
// Item_ParseClasses()
// ------------------------------------------------------------------------
// Parses the wearable classes, duh.
// ------------------------------------------------------------------------
Item_ParseClasses(String:strClasses[])
{
	new iFlags;
	if (StrContains(strClasses, "SCOUT",	false)	!= -1) iFlags |= CLASS_SCOUT;
	if (StrContains(strClasses, "SNIPER",	false)	!= -1) iFlags |= CLASS_SNIPER;
	if (StrContains(strClasses, "SOLDIER",	false)	!= -1) iFlags |= CLASS_SOLDIER;
	if (StrContains(strClasses, "DEMOMAN",	false)	!= -1) iFlags |= CLASS_DEMOMAN;
	if (StrContains(strClasses, "MEDIC",	false)	!= -1) iFlags |= CLASS_MEDIC;
	if (StrContains(strClasses, "HEAVY",	false)	!= -1) iFlags |= CLASS_HEAVY;
	if (StrContains(strClasses, "PYRO",		false)	!= -1) iFlags |= CLASS_PYRO;
	if (StrContains(strClasses, "SPY",		false)	!= -1) iFlags |= CLASS_SPY;
	if (StrContains(strClasses, "ENGINEER",	false)	!= -1) iFlags |= CLASS_ENGINEER;
	if (StrContains(strClasses, "ALL",		false)	!= -1) iFlags |= CLASS_ALL;

	return iFlags;
}
// ------------------------------------------------------------------------
// Item_ParseTeams()
// ------------------------------------------------------------------------
// Parses the wearable teams, duh.
// ------------------------------------------------------------------------
Item_ParseTeams(String:strTeams[])
{
	new iFlags;
	if (StrContains(strTeams, "RED", false) != -1 ) iFlags |= TEAM_RED;
	if (StrContains(strTeams, "BLU", false) != -1) iFlags |= TEAM_BLU;
	if (StrContains(strTeams, "ALL", false) != -1)  iFlags |= TEAM_RED|TEAM_BLU;

	return iFlags;
}
// ------------------------------------------------------------------------
// Item_ParseAdmin()
// ------------------------------------------------------------------------
// Parses the admin overrides for an item.
// ------------------------------------------------------------------------
Item_ParseAdmin(String:destination[], size, String:strOverrides[])
{
	new count = ReplaceString(strOverrides, 256, " ", ";;");
	strcopy(destination, size, strOverrides);
	return count + 1;
}

// ------------------------------------------------------------------------
// Item_IsWearable()
// ------------------------------------------------------------------------
// Determines if the selected item is wearable by a player (that means,
// the player has the right admin level, is the correct class, etc. These
// Cfg can be overriden if the player has the override flag, though.
// ------------------------------------------------------------------------
bool:Item_IsWearable(client, item)
{
	// If the selected item is not valid, it can't be wearable! Rargh!
	if (item < 0 || item >= g_iItemCount)
		return false;

	// Determine if the client has the override flag, let them do ANYTHING.
	if (g_iPlayerFlags[client] & PLAYER_OVERRIDE)
		return true;

	if (!ClientHasItemAccess(client, item))
		return false;
	if (g_bAdminOverride && CheckCommandAccess(client, "tf_models_admin_override_access", ADMFLAG_ROOT, true))
		return true;
/*	else
	{
		if (g_iItemFlags[item] & FLAG_ADMIN_ONLY)
			return false;
	}*/

	if (!(Client_ClassFlags(client) & g_iItemClasses[item]))
		return false;
	if (!(Client_TeamFlags(client) & g_iItemTeams[item]))
		return false;

	decl String:strSteamID[20]; GetClientAuthString(client, strSteamID, sizeof(strSteamID));
	if (g_strItemSteamID[item][0] != '\0' && StrContains(g_strItemSteamID[item], strSteamID, false) == -1)
		return false;

	// Success!
	return true;
}
// Client must have ALL of the overrides present in the override stuff.
stock bool:ClientHasItemAccess(client, item)
{
	decl String:strBuffers[16][32];	//16 overrides should be enough, neh?
	new count = ExplodeString(g_strItemAdmin[item], ";;", strBuffers, 16, 32);
	for (new i = 0; i < count; i++)
	{
		if (strBuffers[i][0] == '\0') continue;	//ignore screwups in the config if somebody put nine spaces between the flags
		if (!CheckCommandAccess(client, strBuffers[i], 0))
			return false;
	}
	return true;
}
bool:Item_IsWearable_Admin_Force(client, item)
{
	// If the selected item is not valid, it can't be wearable! Rargh!
	if (item < 0 || item >= g_iItemCount)
		return false;

	if (g_iPlayerFlags[client] & PLAYER_OVERRIDE)
		return true;

	if (!(Client_ClassFlags(client) & g_iItemClasses[item]))
		return false;
	if (!(Client_TeamFlags(client) & g_iItemTeams[item]))
		return false;

//	decl String:strSteamID[20]; GetClientAuthString(client, strSteamID, sizeof(strSteamID));
//	if ((g_iItemFlags[item] & FLAG_REQUIRES_STEAMID) && (StrContains(g_strItemSteamID[item], strSteamID, false) == -1)) return false;

	// Success!
	return true;
}
// ------------------------------------------------------------------------
// Item_FindDefaultItem()
// ------------------------------------------------------------------------
Item_FindDefaultItem(client)
{
	new iFlagsFilter;
	if (g_bForceAdmins && IsUserAdmin(client))	iFlagsFilter = FLAG_ADMIN_DEFAULT;
	else if (g_bForceUsers)									iFlagsFilter = FLAG_USER_DEFAULT;

	if (iFlagsFilter)
	{
		for (new j=0; j<g_iItemCount; j++)
		{
			if (!(g_iItemFlags[j] & iFlagsFilter)) continue;
			if (!Item_IsWearable(client, j))	  continue;

			return j;
		}
	}

	return -1;
}

// ------------------------------------------------------------------------
// Item_DetermineBodyGroups()
// ------------------------------------------------------------------------
/*Item_DetermineBodyGroups(client)
{
	// Determine bodygroups across all the equiped items
	new BodyGroups = 0;
	for (new Slot=0; Slot<MAX_SLOTS; Slot++)
	{
		new Item = g_iPlayerItem[client][Slot];
		if (Item == -1) continue;

		new Flags = g_iItemFlags[Item];

		switch(TF2_GetPlayerClass(client))
		{
			case TFClass_Engineer:
			{
				if (Flags & FLAG_HIDE_ENGINEER_HELMET) BodyGroups |= BODYGROUP_ENGINEER_HELMET;
			}
			case TFClass_Scout:
			{
				if (Flags & FLAG_HIDE_SCOUT_HAT) BodyGroups |= BODYGROUP_SCOUT_HAT;
				if (Flags & FLAG_HIDE_SCOUT_HEADPHONES) BodyGroups |= BODYGROUP_SCOUT_HEADPHONES;
			}
			case TFClass_Sniper:
			{
				if (Flags & FLAG_HIDE_SNIPER_HAT) BodyGroups |= BODYGROUP_SNIPER_HAT;
			}
			case TFClass_Soldier:
			{
				if (Flags & FLAG_HIDE_SOLDIER_HELMET) BodyGroups |= BODYGROUP_SOLDIER_HELMET;
				if (Flags & FLAG_SHOW_SOLDIER_MEDAL) BodyGroups |= BODYGROUP_SOLDIER_MEDAL;
			}
		}
	}

	return BodyGroups;
}
*/

// ------------------------------------------------------------------------
// Item_RetrieveSlotCookie()
// ------------------------------------------------------------------------
Item_RetrieveSlotCookie(client)
{
	if (IsFakeClient(client)) return -1;
	// If the cookies aren't cached, return.
	if (!AreClientCookiesCached(client)) return -1;

	// Retrieve current class
	new TFClassType:Class = TF2_GetPlayerClass(client);
	if (Class == TFClass_Unknown) return -1;

	// Retrieve the class cookie
	decl String:strCookie[64];
	GetClientCookie(client, g_hCookies[Class], strCookie, sizeof(strCookie));

	// If it's void, return -1
	if (StrEqual(strCookie, "")) return -1;

	// Otherwise, return the cookie value
	return StringToInt(strCookie);
}

// ------------------------------------------------------------------------
// Item_SetSlotCookie()
// ------------------------------------------------------------------------
Item_SetSlotCookie(client)
{
	if (IsFakeClient(client)) return;
	// If the cookies aren't cached, return.
	if (!AreClientCookiesCached(client)) return;

	// Retrieve current class
	new TFClassType:Class;
	if (IsPlayerAlive(client)) Class = TF2_GetPlayerClass(client);
	else Class = TFClassType:GetEntProp(client, Prop_Send, "m_iDesiredPlayerClass");
	if (Class == TFClass_Unknown) return;

	// Set the class cookie
	decl String:strCookie[64];
	IntToString(g_iPlayerItem[client], strCookie, sizeof(strCookie));	//Format(strCookie, sizeof(strCookie), "%i", g_iPlayerItem[client]);
	SetClientCookie(client, g_hCookies[Class], strCookie);
}


// ------------------------------------------------------------------------
// Client_ClassFlags()
// ------------------------------------------------------------------------
// Calculates the current class flags and returns them
// ------------------------------------------------------------------------
Client_ClassFlags(client)
{
	new TFClassType:class;
	if (IsPlayerAlive(client)) class = TF2_GetPlayerClass(client);
	else class = TFClassType:GetEntProp(client, Prop_Send, "m_iDesiredPlayerClass");
	return (1 << (_:class));
/*	switch(class)
	{
		case TFClass_DemoMan:		return CLASS_DEMOMAN;
		case TFClass_Engineer:		return CLASS_ENGINEER;
		case TFClass_Heavy:		return CLASS_HEAVY;
		case TFClass_Medic:		return CLASS_MEDIC;
		case TFClass_Pyro:		return CLASS_PYRO;
		case TFClass_Scout:		return CLASS_SCOUT;
		case TFClass_Sniper:		return CLASS_SNIPER;
		case TFClass_Soldier:		return CLASS_SOLDIER;
		case TFClass_Spy:			return CLASS_SPY;
	}

	return 0;*/
}

// ------------------------------------------------------------------------
// Client_TeamFlags()
// ------------------------------------------------------------------------
// Calculates the current team flags and returns them
// ------------------------------------------------------------------------
Client_TeamFlags(client)
{
	return (1 << GetClientTeam(client));
/*	switch(GetClientTeam(client))
	{
		case TFTeam_Blue: return TEAM_BLU;
		case TFTeam_Red:  return TEAM_RED;
	}

	return 0;*/
}

// ------------------------------------------------------------------------
// Menu_BuildMain()
// ------------------------------------------------------------------------
// Builds the main menu, displaying the options for the wearable
// items.
// ------------------------------------------------------------------------
Handle:Menu_BuildMain()
{
	// Create menu handle
	new Handle:hMenu = CreateMenu(Menu_Manager, MenuAction_DisplayItem|MenuAction_Display);

	// Add the different options
	AddMenuItem(hMenu, "", "Menu_Equip");
	AddMenuItem(hMenu, "", "Menu_Remove");
//	AddMenuItem(hMenu, "", "Menu_RemoveAll");

	// Setup title
	SetMenuTitle(hMenu, "Menu_Main");
	return hMenu;
}

// ------------------------------------------------------------------------
// Menu_BuildSlots()
// ------------------------------------------------------------------------
// Builds the select slots menu. Nothing fancy, just the slots.
// ------------------------------------------------------------------------
/*Handle:Menu_BuildSlots(String:StrTitle[])
{
	// Create menu handle
	new Handle:hMenu = CreateMenu(Menu_Manager, MenuAction_Display);

	AddMenuItem(hMenu, "", "There's only one model slot!");

	// Setup title
	SetMenuTitle(hMenu, StrTitle);
	return hMenu;
}*/

// ------------------------------------------------------------------------
// Menu_BuildItemList(client, Slot)
// ------------------------------------------------------------------------
// This method builds and specific menu for the client, based on it's
// current state, class and flags.
// ------------------------------------------------------------------------
Handle:Menu_BuildItemList(client)
{
	// Create the menu Handle
	new Handle:Menu = CreateMenu(Menu_Manager);
	new String:strBuffer[64];

	// Add all objects
	for (new i=0; i<g_iItemCount; i++)
	{
		// Skip if not a correct item
		if (!Item_IsWearable(client, i)) continue;
		if (g_iItemFlags[i] & FLAG_HIDDEN)  continue;

		Format(strBuffer, sizeof(strBuffer), "%i", i);
		AddMenuItem(Menu, strBuffer, g_strItemName[i]);
	}

	// Set the menu title
	SetMenuTitle(Menu, "%T", "Menu_SelectItem", client);

	return Menu;
}

// ------------------------------------------------------------------------
// Menu_Manager()
// ------------------------------------------------------------------------
// The master menu manager. Manages the different menu usages and
// makes sure to translate the options when necessary.
// ------------------------------------------------------------------------
public Menu_Manager(Handle:hMenu, MenuAction:maState, iParam1, iParam2)
{
	new String:strBuffer[64];

	switch(maState)
	{
		case MenuAction_Select:
		{
			// First, check if the player is alive and ingame. If not, do nothing.
			if (!IsValidClient(iParam1)) return 0;

			if (hMenu == g_hMenuMain)
			{
				switch (iParam2)
				{
					case 0:
					{
						new Handle:hListMenu = Menu_BuildItemList(iParam1);
						DisplayMenu(hListMenu, iParam1, MENU_TIME_FOREVER);
					}
//						DisplayMenu(g_hMenuEquip,  iParam1, MENU_TIME_FOREVER);

					case 1:
					{
						Item_Remove(iParam1);
						RemoveValveHat(iParam1, true);
						HideWeapons(iParam1, true);
						Item_SetSlotCookie(iParam1);
						CPrintToChat(iParam1, "%t", "Message_RemovedItem");
					}
				}
			}
//			else if (hMenu == g_hMenuEquip)
//			{
//				new Handle:hListMenu = Menu_BuildItemList(iParam1);
//				DisplayMenu(hListMenu,  iParam1, MENU_TIME_FOREVER);
//			}
//			else if (hMenu == g_hMenuRemove)
//			{
//				Item_Remove(iParam1);
//				Item_SetSlotCookie(iParam1);
//				CPrintToChat(iParam1, "%t", "Message_RemovedItem");
//			}
			else
			{
				GetMenuItem(hMenu, iParam2, strBuffer, sizeof(strBuffer));
				new Item = StringToInt(strBuffer);
				Item_Equip(iParam1, Item);
				Item_SetSlotCookie(iParam1);
				CPrintToChat(iParam1, "%t", "Message_EquippedItem", g_strItemName[Item]);
			}
		}

		case MenuAction_DisplayItem:
		{
			// Get the display string, we'll use it as a translation phrase
			decl String:strDisplay[64]; GetMenuItem(hMenu, iParam2, "", 0, _, strDisplay, sizeof(strDisplay));
			decl String:strTranslation[255]; Format(strTranslation, sizeof(strTranslation), "%T", strDisplay, iParam1);
			return RedrawMenuItem(strTranslation);
		}

		case MenuAction_Display:
		{
			// Retrieve panel
			new Handle:Panel = Handle:iParam2;

			// Translate title
			decl String:strTranslation[255];
			if (hMenu == g_hMenuMain)		{ Format(strTranslation, sizeof(strTranslation), "%T", "Menu_Main",   iParam1); }
//			else if (hMenu == g_hMenuEquip)	{ Format(strTranslation, sizeof(strTranslation), "%T", "Menu_Equip",  iParam1); }
//			else if (hMenu == g_hMenuRemove)	{ Format(strTranslation, sizeof(strTranslation), "%T", "Menu_Remove", iParam1); }

			// Set title.
			SetPanelTitle(Panel, strTranslation);
		}

		case MenuAction_End:
		{
			if (hMenu != g_hMenuMain)
				CloseHandle(hMenu);
		}
	}

	return 1;
}

// ------------------------------------------------------------------------
// Cmd_BlockTriggers()
// ------------------------------------------------------------------------
public Action:Cmd_BlockTriggers(client, String:command[], args)
{
	if (!g_bBlockTriggers) return Plugin_Continue;
	if (client < 1 || client > MaxClients) return Plugin_Continue;
	if (args < 1) return Plugin_Continue;

	// Retrieve the first argument and check it's a valid trigger
	decl String:strArgument[64]; GetCmdArg(1, strArgument, sizeof(strArgument));
	if (StrEqual(strArgument, "!tf_models", true)) return Plugin_Handled;
	if (StrEqual(strArgument, "!equip", true)) return Plugin_Handled;
	if (StrEqual(strArgument, "!equipmodels", true)) return Plugin_Handled;
	if (StrEqual(strArgument, "!mm", true)) return Plugin_Handled;
	if (StrEqual(strArgument, "!em", true)) return Plugin_Handled;

	// If no valid argument found, pass
	return Plugin_Continue;
}

// ------------------------------------------------------------------------
// Cmd_Menu()
// ------------------------------------------------------------------------
// Shows menu to clients, if the client is able to: The plugin isn't set
// to admin only or his equipment is locked.
// ------------------------------------------------------------------------
public Action:Cmd_Menu(client, args)
{
	// Not allowed if not ingame.
	if (!IsValidClient(client)) { ReplyToCommand(client, "[TF2] Command is in-game only."); return Plugin_Handled; }
	if (!CheckCommandAccess(client, "tf_models", 0))
	{
		CPrintToChat(client, "%t", "Error_AccessLevel");
		return Plugin_Handled;
	}
	// Check if the user doesn't have permission. If not, ignore command.
	if (!IsUserAdmin(client))
	{
//		if (g_bAdminOnly)
//		{
//			CPrintToChat(client, "%t", "Error_AccessLevel");
//			return Plugin_Handled;
//		}
		if (g_iPlayerFlags[client] & PLAYER_LOCK)
		{
			CPrintToChat(client, "%t", "Error_EquipmentLocked");
			return Plugin_Handled;
		}
	}

	// Display menu.
	DisplayMenu(g_hMenuMain, client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

// ------------------------------------------------------------------------
// Cmd_EquipItem()
// ------------------------------------------------------------------------
// Force a client to equip an specific items.
// ------------------------------------------------------------------------
public Action:Cmd_EquipItem(client, args)
{
	if (args < 2) { ReplyToCommand(client, "[TF2] Usage: tf_models_equip <#id|name> <item name>."); return Plugin_Handled; }
	decl String:strArgs[128]; GetCmdArgString(strArgs, sizeof(strArgs));
	// Retrieve arguments
	decl String:strTarget[32];
	new position = BreakString(strArgs, strTarget, sizeof(strTarget));
	if (position == -1) { ReplyToCommand(client, "[TF2] Usage: tf_models_equip <#id|name> <item name>."); return Plugin_Handled; }
	new String:strItem[128];
	strcopy(strItem, sizeof(strItem), strArgs[position]);

	new iItem = -1;

	// Check if item exists and if so, grab index
	new foundcount = 0;
	new String:names[128];
	for (new i=0; i<g_iItemCount; i++)
	{
		if (StrEqual(g_strItemName[i], strItem, false))
		{
			iItem = i;
			foundcount = 1;
			break;
		}
		else if (StrContains(g_strItemName[i], strItem, false) != -1)	//StrEqual(g_strItemName[i], strItem, false))
		{
			foundcount++;
			iItem = i;
			if (foundcount == 1) strcopy(names, sizeof(names), g_strItemName[i]);
			else
			{
				decl String:buffer[32];
				Format(buffer, sizeof(buffer), ", %s", g_strItemName[i]);
				StrCat(names, sizeof(names), buffer);
			}
		}
	}
	if (iItem == -1) { ReplyToCommand(client, "[TF2] Unknown item : \"%s\"", strItem); return Plugin_Handled; }
	if (foundcount != 1)
	{
		ReplyToCommand(client, "[TF2] Found multiple items matching search string.\nTry: %s", names);
		return Plugin_Handled;
	}

	// Process the targets
	decl String:strTargetName[MAX_TARGET_LENGTH];
	decl iTargetList[MAXPLAYERS], iTargetCount;
	decl bool:bTargetTranslate;

	if ((iTargetCount = ProcessTargetString(strTarget, client, iTargetList, MAXPLAYERS, COMMAND_FILTER_CONNECTED,
	strTargetName, sizeof(strTargetName), bTargetTranslate)) <= 0)
	{
		ReplyToTargetError(client, iTargetCount);
		return Plugin_Handled;
	}

	// Apply to all targets
	decl String:message[MAX_MESSAGE_LENGTH];
	SetGlobalTransTarget(client);
	for (new i = 0; i < iTargetCount; i++)
	{
		if (!IsValidClient(iTargetList[i])) continue;

		// If item isn't wearable, for the client.
		if (!Item_IsWearable_Admin_Force(iTargetList[i], iItem)) {
//			decl String:strName[64]; GetClientName(iTargetList[i], strName, sizeof(strName));
			if (client != 0) CPrintToChat(client, "%t", "Error_CantWear", iTargetList[i]);
			else
			{
				FormatEx(message, sizeof(message), "%t", "Error_CantWear", iTargetList[i]);
				CRemoveTags(message, sizeof(message));
				ReplyToCommand(client, message);
			}
			continue;
		}

		// Equip item and tell to client.
		Item_Equip_Admin_Force(iTargetList[i], iItem);
		Item_SetSlotCookie(iTargetList[i]);
		CPrintToChat(iTargetList[i], "%t", "Message_ForcedEquip", g_strItemName[iItem]);
	}
	if (bTargetTranslate)
		ReplyToCommand(client, "[TF2] Forced model '%s' on %t", g_strItemName[iItem], strTargetName);
	else
		ReplyToCommand(client, "[TF2] Forced model '%s' on %s", g_strItemName[iItem], strTargetName);

	return Plugin_Handled;
}

// ------------------------------------------------------------------------
// Cmd_RemoveItem()
// ------------------------------------------------------------------------
public Action:Cmd_RemoveItem(client, args)
{
	// Determine if the number of arguments is valid
	if (args < 1) { ReplyToCommand(client, "[TF2] Usage: tf_models_remove <#id|name>."); return Plugin_Handled; }

	// Retrieve arguments
	decl String:strTarget[32]; GetCmdArg(1, strTarget, sizeof(strTarget));

	// Process the targets
	decl String:strTargetName[MAX_TARGET_LENGTH];
	decl iTargetList[MAXPLAYERS], iTargetCount;
	decl bool:bTargetTranslate;

	if ((iTargetCount = ProcessTargetString(strTarget, client, iTargetList, MAXPLAYERS, COMMAND_FILTER_CONNECTED,
	strTargetName, sizeof(strTargetName), bTargetTranslate)) <= 0)
	{
		ReplyToTargetError(client, iTargetCount);
		return Plugin_Handled;
	}

	// Apply to all targets
	for (new i = 0; i < iTargetCount; i++)
	{
		if (!IsValidClient(iTargetList[i])) continue;

		Item_Remove(iTargetList[i]);
		Item_SetSlotCookie(iTargetList[i]);
		CPrintToChat(iTargetList[i], "%t", "Message_ForcedRemove");
	}

	// Done
	return Plugin_Handled;
}

// ------------------------------------------------------------------------
// Cmd_LockEquipment()
// ------------------------------------------------------------------------
public Action:Cmd_LockEquipment(client, args)
{
	// Determine if the number of arguments is valid
	if (args < 2) { ReplyToCommand(client, "[TF2] Usage: tf_models_lock <#id|name> <state>"); return Plugin_Handled; }

	// Retrieve arguments
	decl String:strTarget[32]; GetCmdArg(1, strTarget, sizeof(strTarget));
	decl String:strState[8];   GetCmdArg(2, strState,  sizeof(strState));

	// Process the targets
	decl String:strTargetName[MAX_TARGET_LENGTH];
	decl iTargetList[MAXPLAYERS], iTargetCount;
	decl bool:bTargetTranslate;

	if ((iTargetCount = ProcessTargetString(strTarget, client, iTargetList, MAXPLAYERS, COMMAND_FILTER_CONNECTED,
	strTargetName, sizeof(strTargetName), bTargetTranslate)) <= 0)
	{
		ReplyToTargetError(client, iTargetCount);
		return Plugin_Handled;
	}

	// Apply to all targets
	new bState = !!StringToInt(strState);
	if (bState)
		for (new i = 0; i < iTargetCount; i++)
		{
			if (!IsValidClient(iTargetList[i])) continue;
			if (IsUserAdmin(iTargetList[i])) continue;

			g_iPlayerFlags[iTargetList[i]] |= PLAYER_LOCK;
			CPrintToChat(iTargetList[i], "%t", "Message_Locked");
		}
	else
		for (new i = 0; i < iTargetCount; i++)
		{
			if (!IsValidClient(iTargetList[i])) continue;
	//		g_iPlayerFlags[iTargetList[i]] &= ~PLAYER_LOCK;
			if (IsUserAdmin(iTargetList[i])) continue;

			g_iPlayerFlags[iTargetList[i]] &= ~PLAYER_LOCK;
			CPrintToChat(iTargetList[i], "%t", "Message_Unlocked");
		}
	if (bTargetTranslate)
		ReplyToCommand(client, "[TF2] %s model for %t", bState ? "Locked" : "Unlocked", strTargetName);
	else
		ReplyToCommand(client, "[TF2] %s model for %s", bState ? "Locked" : "Unlocked", strTargetName);

	// Done
	return Plugin_Handled;
}

// ------------------------------------------------------------------------
// Cmd_OverrideEquipment()
// ------------------------------------------------------------------------
public Action:Cmd_OverrideEquipment(client, args)
{
	// Determine if the number of arguments is valid
	if (args < 2) { ReplyToCommand(client, "[TF2] Usage: tf_models_override <#id|name> <state>"); return Plugin_Handled; }

	// Retrieve arguments
	decl String:strTarget[32]; GetCmdArg(1, strTarget, sizeof(strTarget));
	decl String:strState[8];   GetCmdArg(2, strState,  sizeof(strState));

	// Process the targets
	decl String:strTargetName[MAX_TARGET_LENGTH];
	decl iTargetList[MAXPLAYERS], iTargetCount;
	decl bool:bTargetTranslate;

	if ((iTargetCount = ProcessTargetString(strTarget, client, iTargetList, MAXPLAYERS, COMMAND_FILTER_CONNECTED,
	strTargetName, sizeof(strTargetName), bTargetTranslate)) <= 0)
	{
		ReplyToTargetError(client, iTargetCount);
		return Plugin_Handled;
	}

	// Apply to all targets
	new bState = !!StringToInt(strState);

	if (bState)
		for (new i = 0; i < iTargetCount; i++)
		{
			if (!IsValidClient(iTargetList[i])) continue;

			g_iPlayerFlags[iTargetList[i]] |= PLAYER_OVERRIDE;
			CPrintToChat(iTargetList[i], "%t", "Message_Override_On");
		}
	else
		for (new i = 0; i < iTargetCount; i++)
		{
			if (!IsValidClient(iTargetList[i])) continue;

			g_iPlayerFlags[iTargetList[i]] &= ~PLAYER_OVERRIDE;
			CPrintToChat(iTargetList[i], "%t", "Message_Override_Off");
		}
	if (bTargetTranslate)
		ReplyToCommand(client, "[TF2] %s model override for %t", bState ? "Enabled" : "Disabled", strTargetName);
	else
		ReplyToCommand(client, "[TF2] %s model override for %s", bState ? "Enabled" : "Disabled", strTargetName);

	// Done
	return Plugin_Handled;
}

// ------------------------------------------------------------------------
// Cmd_Reload()
// ------------------------------------------------------------------------
public Action:Cmd_Reload(client, args)
{
	GetConVarString(g_hCvarFileList, g_strConfigFilePath, sizeof(g_strConfigFilePath));
	// Reparse item list
	Item_ParseList();
	ReplyToCommand(client, "[TF2] Model Manager: model list reloaded, found %d models.", g_iItemCount);
	// Done
	return Plugin_Handled;
}
stock bool:IsUserAdmin(client)
{
	new ibFlags = ReadFlagString(g_strAdminFlags);
	new AdminId:admin = GetUserAdmin(client);
	if (admin == INVALID_ADMIN_ID) return false;
	if (GetAdminFlags(admin, Access_Effective) & (ibFlags|ADMFLAG_ROOT))	return true;
	return false;
}
// ------------------------------------------------------------------------
// Timer_Welcome
// ------------------------------------------------------------------------
public Action:Timer_Welcome(Handle:hTimer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (!IsValidClient(client)) return Plugin_Stop;

	CPrintToChat(client, "%t", "Announce_Plugin", PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);
	return Plugin_Continue;
}

// ------------------------------------------------------------------------
// Timer_Announce
// ------------------------------------------------------------------------
public Action:Timer_Announce(Handle:hTimer)
{
	if (!g_bAnnounce) return Plugin_Continue;

	for (new client=1; client<=MaxClients; client++)
	{
		if (!IsValidClient(client)) continue;
		if (!CheckCommandAccess(client, "tf_models", 0)) continue;
		CPrintToChat(client, "%t", "Announce_Command");
	}

	return Plugin_Continue;
}

// ------------------------------------------------------------------------
// CleanString
// ------------------------------------------------------------------------
stock CleanString(String:strBuffer[])
{
	// Cleanup any illegal characters
	new Length = strlen(strBuffer);
	for (new iPos=0; iPos<Length; iPos++)
	{
		switch(strBuffer[iPos])
		{
			case '\r': strBuffer[iPos] = ' ';
			case '\n': strBuffer[iPos] = ' ';
			case '\t': strBuffer[iPos] = ' ';
		}
	}

	// Trim string
	TrimString(strBuffer);
}

// ------------------------------------------------------------------------
// IsValidClient
// ------------------------------------------------------------------------
stock bool:IsValidClient(client)
{
	if (client <= 0) return false;
	if (client > MaxClients) return false;
//	if (!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}
// ------------------------------------------------------------------------
// FindEntityByClassnameSafe
// ------------------------------------------------------------------------
// By Exvel
// ------------------------------------------------------------------------
stock FindEntityByClassnameSafe(iStart, const String:strClassname[])
{
	while (iStart > -1 && !IsValidEntity(iStart)) iStart--;
	return FindEntityByClassname(iStart, strClassname);
}

// ------------------------------------------------------------------------
// CalculateBodyGroups
// ------------------------------------------------------------------------
CalculateBodyGroups(client)
{
	new iBodyGroups = g_iPlayerBGroups[client];
	new iItemGroups = 0;

	if (g_iPlayerItem[client] != -1)
		iItemGroups |= g_iItemBodygroupFlags[g_iPlayerItem[client]];
	new TFClassType:class = TF2_GetPlayerClass(client);
	switch(class)
	{
		case TFClass_Scout:
		{
			if (iItemGroups & FLAG_HIDE_SCOUT_HAT)			iBodyGroups |= BODYGROUP_SCOUT_HAT;
			if (iItemGroups & FLAG_HIDE_SCOUT_HEADPHONES)	iBodyGroups |= BODYGROUP_SCOUT_HEADPHONES;
			if (iItemGroups & FLAG_HIDE_SCOUT_FEET)			iBodyGroups |= BODYGROUP_SCOUT_SHOESSOCKS;
			if (iItemGroups & FLAG_HIDE_SCOUT_DOGTAGS)		iBodyGroups |= BODYGROUP_SCOUT_DOGTAGS;
		}
		case TFClass_Soldier:
		{
			if (iItemGroups & FLAG_SHOW_SOLDIER_ROCKET)		iBodyGroups |= BODYGROUP_SOLDIER_ROCKET;
			if (iItemGroups & FLAG_HIDE_SOLDIER_HELMET)		iBodyGroups |= BODYGROUP_SOLDIER_HELMET;
			if (iItemGroups & FLAG_HIDE_SOLDIER_GRENADES)	iBodyGroups |= BODYGROUP_SOLDIER_GRENADES;
		}
		case TFClass_Pyro:
		{
			if (iItemGroups & FLAG_HIDE_PYRO_HEAD)			iBodyGroups |= BODYGROUP_PYRO_HEAD;
			if (iItemGroups & FLAG_HIDE_PYRO_GRENADES)		iBodyGroups |= BODYGROUP_PYRO_GRENADES;
		}
		case TFClass_DemoMan:
		{
			if (iItemGroups & FLAG_SHOW_DEMO_SMILE)			iBodyGroups |= BODYGROUP_DEMO_SMILE;
			if (iItemGroups & FLAG_HIDE_DEMO_FEET)			iBodyGroups |= BODYGROUP_DEMO_SHOES;
		}
		case TFClass_Heavy:
		{
			if (iItemGroups & FLAG_HIDE_HEAVY_HANDS)			iBodyGroups = BODYGROUP_HEAVY_HANDS;
		}
		case TFClass_Engineer:
		{
			if (iItemGroups & FLAG_HIDE_ENGINEER_HELMET)		iBodyGroups |= BODYGROUP_ENGINEER_HELMET;
			if (iItemGroups & FLAG_SHOW_ENGINEER_ARM)		iBodyGroups |= BODYGROUP_ENGINEER_ARM;
		}
		case TFClass_Medic:
		{
			if (iItemGroups & FLAG_HIDE_MEDIC_BACKPACK)		iBodyGroups |= BODYGROUP_MEDIC_BACKPACK;
		}
		case TFClass_Sniper:
		{
			if (iItemGroups & FLAG_SHOW_SNIPER_ARROWS)		iBodyGroups |= BODYGROUP_SNIPER_ARROWS;
			if (iItemGroups & FLAG_HIDE_SNIPER_HAT)			iBodyGroups |= BODYGROUP_SNIPER_HAT;
			if (iItemGroups & FLAG_SHOW_SNIPER_DARTS)		iBodyGroups |= BODYGROUP_SNIPER_BULLETS;
		}
		case TFClass_Spy:
		{
			if (iItemGroups & FLAG_SHOW_SPY_MASK)			iBodyGroups |= BODYGROUP_SPY_MASK;
		}
	}

	return iBodyGroups;
}
stock HideWeapons(client, bool:unhide = false)
{
	HideWeaponWearables(client, unhide);
	new m_hMyWeapons = FindSendPropOffs("CTFPlayer", "m_hMyWeapons");	

	for (new i = 0, weapon; i < 47; i += 4)
	{
		weapon = GetEntDataEnt2(client, m_hMyWeapons + i);
		decl String:classname[64];
		if (weapon > MaxClients && IsValidEdict(weapon) && GetEdictClassname(weapon, classname, sizeof(classname)) && StrContains(classname, "weapon") != -1)
		{
			SetEntityRenderMode(weapon, (unhide ? RENDER_NORMAL : RENDER_TRANSCOLOR));
			SetEntityRenderColor(weapon, 255, 255, 255, (unhide ? 255 : 5));
		}
	}
}
stock HideWeaponWearables(client, bool:unhide = false)
{
	new edict = MaxClients+1;
	while((edict = FindEntityByClassnameSafe(edict, "tf_wearable")) != -1)
	{
		decl String:netclass[32];
		if (GetEntityNetClass(edict, netclass, sizeof(netclass)) && strcmp(netclass, "CTFWearable") == 0)
		{
			new idx = GetEntProp(edict, Prop_Send, "m_iItemDefinitionIndex");
			if (idx != 57 && idx != 133 && idx != 231 && idx != 444 && idx != 405 && idx != 608 && idx != 642) continue;
			if (GetEntPropEnt(edict, Prop_Send, "m_hOwnerEntity") == client)
			{
				SetEntityRenderMode(edict, (unhide ? RENDER_NORMAL : RENDER_TRANSCOLOR));
				SetEntityRenderColor(edict, 255, 255, 255, (unhide ? 255 : 0));
			}
		}
	}
}
stock RemoveValveHat(client, bool:unhide = false)
{
	new edict = MaxClients+1;
	while((edict = FindEntityByClassnameSafe(edict, "tf_wearable")) != -1)
	{
		decl String:netclass[32];
		if (GetEntityNetClass(edict, netclass, sizeof(netclass)) && strcmp(netclass, "CTFWearable") == 0)
		{
			new idx = GetEntProp(edict, Prop_Send, "m_iItemDefinitionIndex");
			if (idx != 57 && idx != 133 && idx != 231 && idx != 444 && idx != 405 && idx != 608 && idx != 642 && GetEntPropEnt(edict, Prop_Send, "m_hOwnerEntity") == client)
			{
				SetEntityRenderMode(edict, (unhide ? RENDER_NORMAL : RENDER_TRANSCOLOR));
				SetEntityRenderColor(edict, 255, 255, 255, (unhide ? 255 : 0));
			}
		}
	}
	edict = MaxClients+1;
	while((edict = FindEntityByClassnameSafe(edict, "tf_powerup_bottle")) != -1)
	{
		decl String:netclass[32];
		if (GetEntityNetClass(edict, netclass, sizeof(netclass)) && strcmp(netclass, "CTFPowerupBottle") == 0)
		{
			new idx = GetEntProp(edict, Prop_Send, "m_iItemDefinitionIndex");
			if (idx != 57 && idx != 133 && idx != 231 && idx != 444 && idx != 405 && idx != 608 && idx != 642 && GetEntPropEnt(edict, Prop_Send, "m_hOwnerEntity") == client)
			{
				SetEntityRenderMode(edict, (unhide ? RENDER_NORMAL : RENDER_TRANSCOLOR));
				SetEntityRenderColor(edict, 255, 255, 255, (unhide ? 255 : 0));
			}
		}
	}
}
