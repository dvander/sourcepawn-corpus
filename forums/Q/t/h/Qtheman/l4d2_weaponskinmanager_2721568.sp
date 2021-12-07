/*
// ===========================================================================
L4D2 WEAPON SKIN MANAGER PLUGIN
-------------------------------
Handles weapon spawn skin randomization on map start, multiple pistol skins,
grenade launchers and M60s not applying the correct skin when picked up, and
adds client menus for selecting skins. This plugin is written to be easily
extensible with a few simple config/text files.

Changelog:
v1.0 (Oct. 16th, 2020)
	- First release
// ===========================================================================
*/

// ===========================================================================
// PLUGIN INFO
// ===========================================================================

#define PLUGIN_VERSION "1.0"

public Plugin myinfo =
{
	name = 			"[L4D2] Weapon Skin Manager",
	author = 		"KyuuGryphon",
	description =	"Plugin for managing weapon skins as of the Last Stand Update. Randomized skins, client menus, bugfixes, and more.",
	version =		PLUGIN_VERSION,
	url =			""
}

// ===========================================================================
// INCLUDES & DEFINES
// ===========================================================================

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define MAX_STRING_LENGTH 4096
#define TEAM_SURVIVOR 2
#define TRANSLATIONS_FILE "l4d2_wsm_translations"

// ===========================================================================
// CVAR HANDLES
// ===========================================================================

new Handle:h_EnablePlugin				// Enable plugin functionality
new Handle:h_EnableRandomSkins			// Enable randomized weapon skin spawns
new Handle:h_EnableSkinMenus			// Enable client menus for skin selection
new Handle:h_EnableFirearmSkins			// Enable skin randomization for firearm spawns
new Handle:h_EnableMeleeSkins			// Enable skin randomization for melee spawns
new Handle:h_EnableItemSkins			// Enable skin randomization for item spawns
new Handle:h_EnablePistolManagement		// Enable management of dual pistol skins
new Handle:h_EnableGrenadeManagement	// Enable management of throw grenade skins
new Handle:h_EnableSpawnMessage			// Enable introductory message when player first joins
new Handle:h_MeleeMode					// Select melee weapon slot mode - 0 = slot1 (default), 1 = slot6
new Handle:h_StartPistolSkins			// Randomize starting pistol skins at the start of a campaign
new Handle:h_PistolSkinCount			// Number of skins a single pistol has, 1-based index
new Handle:h_PistolSkinMode				// Dual pistol skin calculation mode
new Handle:h_ReportToConsole			// Print information to console. 0 = off, 1 = basic, 2 = advanced

// ===========================================================================
// GLOBAL INTS/STRINGS/BOOLS
// ===========================================================================

char List_FileStartMaps[PLATFORM_MAX_PATH];		// Path to textfile list of each campaign's first map
char List_FileFirearmSkins[PLATFORM_MAX_PATH];	// Path to text file for firearm skin list
char List_FileMeleeSkins[PLATFORM_MAX_PATH];	// Path to text file for melee skin list
char List_FileItemSkins[PLATFORM_MAX_PATH];		// Path to text file for item skin list
char List_SkinMenuOptions[8][16];				// List of menu options for the skin select menu

int iMenuSelectSlot = 0;						// Index for selected weapon in skin menu
int iValidMenuSlots[8];							// Numbers for valid weapon slots in menu

int iRightPistolSkin[MAXPLAYERS+1];				// Selected right-hand pistol skin per client
int iLeftPistolSkin[MAXPLAYERS+1];				// Selected left-hand pistol skin per client
int iGrenadeSkin[MAXPLAYERS+1];					// Selected grenade skin per client
int iCurrentGrenade[MAXPLAYERS+1];				// Currently equipped grenade per client

int iNumericFirearmIDs[32][2];					// Integer list of numeric firearm IDs
int iEntIndexOfDroppedPistol = -1;				// Ent index of the most recent CREATED pistol

bool bIsStartingMap = false;					// If we've just started a new campaign...
bool bPlayerGrabbedSecondPistol[MAXPLAYERS+1];	// If the player already has two pistols...
bool bPlayerHasGrenadeLauncher[MAXPLAYERS+1];	// If the player already has a grenade launcher...
bool bPlayerHasM60[MAXPLAYERS+1];				// If the player already has an M60...
bool bClientSawStartMessage[MAXPLAYERS+1];		// If the client hasn't seen the startup message...

bool bServerHasSpawned = false;					// If the server's fully booted...

bool bPlayerHasDualPistols(int iClient)			// Function to check if the player has two pistols or not
{
	int iSlot1 = GetPlayerWeaponSlot(iClient, 1)
	char strWeaponClassname[32];
	if (iSlot1 > 0)
	{
		GetEdictClassname(iSlot1, strWeaponClassname, sizeof(strWeaponClassname));
		if (StrEqual(strWeaponClassname, "weapon_pistol"))
		{
			char strWeaponModelName[64];
			GetEntPropString(iSlot1, Prop_Data, "m_ModelName", strWeaponModelName, sizeof(strWeaponModelName));
			if (StrContains(strWeaponModelName, "v_dual_pistolA.mdl") != -1) return true;
		}
	}
	bPlayerGrabbedSecondPistol[iClient] = false;
	return false;
}

// ===========================================================================
// STRINGMAPS/ARRAYS
// ===========================================================================

ArrayList aStartMaps;			// String array for campaign starting maps
StringMap sm_AllWeaponSkins;	// Stringmap for ALL weapon/item skins, by name and count

// ===========================================================================
// PLUGIN START
// ===========================================================================
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "[L4D2WSM] This plugin only works on Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	aStartMaps = new ArrayList(MAX_STRING_LENGTH);
	
	LoadTranslationsFile();
	
	bServerHasSpawned = false;
	
	h_EnablePlugin = CreateConVar("l4d2_wsm_enabled", "1", "Enable plugin functionality.")
	
	h_EnableRandomSkins = CreateConVar("l4d2_wsm_rngskins", "1", "Enable weapon skin spawn randomization.")
	h_EnableFirearmSkins = CreateConVar("l4d2_wsm_gunskins", "1", "Enable randomized firearm skins. Only works if l4d2_wsm_rngskins is set to 1, and requires the skin list to be reloaded if changed in-game (l4d2_wsm_reloadskins).")
	h_EnableMeleeSkins = CreateConVar("l4d2_wsm_meleeskins", "1", "Enable randomized melee weapon skins. Only works if l4d2_wsm_rngskins is set to 1, and requires the skin list to be reloaded if changed in-game (l4d2_wsm_reloadskins).")
	h_EnableItemSkins = CreateConVar("l4d2_wsm_itemskins", "0", "Enable randomized item skins (e.g. defibs, first aid kits, etc.) Only works if l4d2_wsm_rngskins is set to 1, and requires the skin list to be reloaded if changed in-game (l4d2_wsm_reloadskins).")
	h_EnablePistolManagement = CreateConVar("l4d2_wsm_pistols", "0", "Enable pistol/dual pistol skin management. Anything relating to non-magnum pistols is disabled unless this is set to 1.")
	h_EnableGrenadeManagement = CreateConVar("l4d2_wsm_grenades", "1", "Enable grenade (molotov, pipe bomb, bile jar) skin management. Thrown grenades will always show the default skin if this is disabled.")
	h_EnableSkinMenus = CreateConVar("l4d2_wsm_skinmenu", "1", "Enable weapon skin selection menus.")
	h_EnableSpawnMessage = CreateConVar("l4d2_wsm_spawnmsg", "1", "Display a chat message explaining the plugin to clients after they join the game.")
	
	h_MeleeMode = CreateConVar("l4d2_wsm_meleemode", "0", "The mode to use for melee weapon skin handling. 0 = Secondary slot (default), 1 = Slot 7 (modded). Default = 0.")
	h_StartPistolSkins = CreateConVar("l4d2_wsm_startpistols", "0", "Enable randomized pistol skins per survivor at the beginning of a new campaign.")
	h_PistolSkinCount = CreateConVar("l4d2_wsm_pistolskincount", "4", "The number of skins each pistol has. This is NOT a 0-based index!")
	h_PistolSkinMode = CreateConVar("l4d2_wsm_pistolskinmode", "0", "Which dual pistol skin calculation method to use. This should be set based on how the server's pistol skin addon is set up. If 1, the left-hand pistol cycles first, e.g.: (L1, R1), (L2, R1), (L1, R2), etc.")
	
	h_ReportToConsole = CreateConVar("l4d2_wsm_printtoconsole", "1", "How much detailed information to print to the server console. 0 = off, 1 = basic, 2 = detailed. Mainly for debugging purposes.")

	RegAdminCmd("sm_wsm_reloadskins", RecreateSkinList, ADMFLAG_ROOT, "Reload the weapon/item skin list.");
	RegAdminCmd("sm_wsm_reloadmaps", RecreateMapList, ADMFLAG_ROOT, "Reload the starting map list.");
	RegAdminCmd("sm_wsm_randomize", RandomizeSkinCmd, ADMFLAG_ROOT, "Randomize weapon spawn skins without reloading the map.");
	RegAdminCmd("sm_wsm_rehook", ReHookCmd, ADMFLAG_ROOT, "Re-run code that normally only runs when a player first spawns into the game. Mainly for debugging purposes.");
	
	RegConsoleCmd("sm_wsm_skin", SetClientSlotSkinCmd, "Manually select a skin for a slot's weapon. Does not work on pistols. Format: !wskin/!wsm_skin [slot] [skin]");
	RegConsoleCmd("sm_wsm_pistol_r", SetClientPistolRightCmd, "Manually select a skin for your right-hand pistol. Only works if you have a pistol (dual or singular) equipped. Format: !pistol_r/!wsm_pistol_r [skin ID]");
	RegConsoleCmd("sm_wsm_pistol_l", SetClientPistolLeftCmd, "Manually select a skin for your left-hand pistol. Only works if you have two pistols equipped. Format: !pistol_l/!wsm_pistol_l [skin ID]");
	RegConsoleCmd("sm_wsm_menu", OpenMainSkinMenu, "Open the main skin selection menu.");
	RegConsoleCmd("sm_wsm_pistols", OpenPistolSkinMenu, "Open the pistol skin selection menu.");

	RegConsoleCmd("sm_wskin", SetClientSlotSkinCmd, "Manually select a skin for a slot's weapon. Does not work on pistols. Format: !wskin/!wsm_skin [slot] [skin]");
	RegConsoleCmd("sm_pistol_r", SetClientPistolRightCmd, "Manually select a skin for your right-hand pistol. Only works if you have a pistol (dual or singular) equipped. Format: !pistol_r/!wsm_pistol_r [skin ID]");
	RegConsoleCmd("sm_pistol_l", SetClientPistolLeftCmd, "Manually select a skin for your left-hand pistol. Only works if you have two pistols equipped. Format: !pistol_l/!wsm_pistol_l [skin ID]");
	RegConsoleCmd("sm_skins", OpenMainSkinMenu, "Open the main skin selection menu.");
	RegConsoleCmd("sm_pistols", OpenPistolSkinMenu, "Open the pistol skin selection menu.");

	AutoExecConfig(true, "l4d2_weaponskinmanager");
	HookEvent("round_start", Event_RoundStarted);
	HookEvent("player_first_spawn", Event_PlayerFirstSpawned);
	HookEvent("player_use", Event_PickupWeapon);
	HookEvent("weapon_drop", Event_PlayerDroppedWeapon);
	HookEvent("defibrillator_used", Event_PlayerDefibbed);
	HookEvent("survivor_rescued", Event_PlayerRescuedFromCloset);

	for (new i; i < MAXPLAYERS; i++)
	{
		iRightPistolSkin[i] = 0;
		iLeftPistolSkin[i] = 0;
		iGrenadeSkin[i] = 0;
	}
}

// Load translations
void LoadTranslationsFile()
{
	char strTranslationPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, strTranslationPath, sizeof(strTranslationPath), "translations/%s.txt", TRANSLATIONS_FILE);
	if (FileExists(strTranslationPath)) LoadTranslations(TRANSLATIONS_FILE);
	else SetFailState("Translation file not found at \"translations/%s.txt\". Make sure the file exists, or re-download it if it doesn't.", TRANSLATIONS_FILE);
} 

// Create the weapon stringmap from file(s), or create the files if they don't exist
public void CreateSkinList()
{
	BuildPath(Path_SM, List_FileFirearmSkins, sizeof(List_FileFirearmSkins), "configs/l4d2_wsm_firearmlist.txt");
	BuildPath(Path_SM, List_FileMeleeSkins, sizeof(List_FileMeleeSkins), "configs/l4d2_wsm_meleelist.txt");
	BuildPath(Path_SM, List_FileItemSkins, sizeof(List_FileItemSkins), "configs/l4d2_wsm_itemlist.txt");
	
	if (!FileExists(List_FileFirearmSkins))
	{
		LogMessage("%T", "Firearm_ListFile_Create", LANG_SERVER);
		File newList = OpenFile(List_FileFirearmSkins, "w+");
		newList.WriteLine("pistol_magnum; 2");
		newList.WriteLine("smg; 1");
		newList.WriteLine("smg_silenced; 1");
		newList.WriteLine("pumpshotgun; 1");
		newList.WriteLine("shotgun_chrome; 1");
		newList.WriteLine("rifle; 2");
		newList.WriteLine("rifle_ak47; 2");
		newList.WriteLine("autoshotgun; 1");
		newList.WriteLine("hunting_rifle; 1");
		delete newList;
	}
	if (!FileExists(List_FileMeleeSkins))
	{
		LogMessage("%T", "Melee_ListFile_Create", LANG_SERVER);
		File newList = OpenFile(List_FileMeleeSkins, "w+");
		newList.WriteLine("cricket_bat; 1");
		newList.WriteLine("crowbar; 1");
		delete newList;
	}
	if (!FileExists(List_FileItemSkins))
	{
		LogMessage("%T", "Item_ListFile_Create", LANG_SERVER);
		File newList = OpenFile(List_FileItemSkins, "w+");
		delete newList;
	}
	
	char line[48];
	char buffer_split[2][24];
	
	sm_AllWeaponSkins = CreateTrie();
	if (GetConVarInt(h_EnableFirearmSkins) == 1)
	{
		int iGunIndex = 0;
		int iGunSkinCount;
		File FirearmList_LoadFile = OpenFile(List_FileFirearmSkins, "r");
		while (FirearmList_LoadFile.ReadLine(line, sizeof(line)) && !FirearmList_LoadFile.EndOfFile())
		{
			ExplodeString(line, ";", buffer_split, 2, 24);
			int iGunNumber;
			iGunSkinCount = StringToInt(buffer_split[1], 10);
			sm_AllWeaponSkins.SetValue(buffer_split[0], iGunSkinCount);
			if (StrEqual(buffer_split[0], "pistol")) 				iGunNumber = 1;
			else if (StrEqual(buffer_split[0], "smg")) 				iGunNumber = 2;
			else if (StrEqual(buffer_split[0], "pumpshotgun"))		iGunNumber = 3;
			else if (StrEqual(buffer_split[0], "autoshotgun")) 		iGunNumber = 4;
			else if (StrEqual(buffer_split[0], "rifle")) 			iGunNumber = 5;
			else if (StrEqual(buffer_split[0], "hunting_rifle")) 	iGunNumber = 6;
			else if (StrEqual(buffer_split[0], "smg_silenced")) 	iGunNumber = 7;
			else if (StrEqual(buffer_split[0], "shotgun_chrome")) 	iGunNumber = 8;
			else if (StrEqual(buffer_split[0], "rifle_desert")) 	iGunNumber = 9;
			else if (StrEqual(buffer_split[0], "sniper_military")) 	iGunNumber = 10;
			else if (StrEqual(buffer_split[0], "shotgun_spas")) 	iGunNumber = 11;
			else if (StrEqual(buffer_split[0], "grenade_launcher")) iGunNumber = 21;
			else if (StrEqual(buffer_split[0], "rifle_ak47")) 		iGunNumber = 26;
			else if (StrEqual(buffer_split[0], "pistol_magnum")) 	iGunNumber = 32;
			else if (StrEqual(buffer_split[0], "smg_mp5")) 			iGunNumber = 33;
			else if (StrEqual(buffer_split[0], "rifle_sg552")) 		iGunNumber = 34;
			else if (StrEqual(buffer_split[0], "sniper_awp")) 		iGunNumber = 35;
			else if (StrEqual(buffer_split[0], "sniper_scout")) 	iGunNumber = 36;
			else if (StrEqual(buffer_split[0], "rifle_m60")) 		iGunNumber = 37;
			
			iNumericFirearmIDs[iGunIndex][0] = iGunNumber;
			iNumericFirearmIDs[iGunIndex][1] = iGunSkinCount;
			iGunIndex++;
		}
		FirearmList_LoadFile.Close();
		if (GetConVarInt(h_ReportToConsole) >= 1) LogMessage("%T", "Firearm_List_Built", LANG_SERVER, sm_AllWeaponSkins.Size);
	}
	if (GetConVarInt(h_EnableMeleeSkins) == 1)
	{
		int iMeleeCount = 0;
		int iMeleeSkinCount;
		File MeleeList_LoadFile = OpenFile(List_FileMeleeSkins, "r");
		while (MeleeList_LoadFile.ReadLine(line, sizeof(line)) && !MeleeList_LoadFile.EndOfFile())
		{
			ExplodeString(line, ";", buffer_split, 2, 24);
			iMeleeSkinCount = StringToInt(buffer_split[1], 10);
			sm_AllWeaponSkins.SetValue(buffer_split[0], iMeleeSkinCount);
			iMeleeCount++;
		}
		MeleeList_LoadFile.Close();
		if (GetConVarInt(h_ReportToConsole) >= 1) LogMessage("%T", "Melee_List_Built", LANG_SERVER, iMeleeCount, sm_AllWeaponSkins.Size);
	}
	if (GetConVarInt(h_EnableItemSkins) == 1)
	{
		int iItemCount = 0;
		int iItemSkinCount;
		File ItemList_LoadFile = OpenFile(List_FileItemSkins, "r");
		while (ItemList_LoadFile.ReadLine(line, sizeof(line)) && !ItemList_LoadFile.EndOfFile())
		{
			ExplodeString(line, ";", buffer_split, 2, 24);
			iItemSkinCount = StringToInt(buffer_split[1], 10);
			sm_AllWeaponSkins.SetValue(buffer_split[0], iItemSkinCount);
			iItemCount++;
		}
		ItemList_LoadFile.Close();
		if (GetConVarInt(h_ReportToConsole) >= 1) LogMessage("%T", "Item_List_Built", LANG_SERVER, iItemCount, sm_AllWeaponSkins.Size);
	}
	if (GetConVarInt(h_ReportToConsole) >= 1) LogMessage("%T", "SkinList_Built_Complete", LANG_SERVER, sm_AllWeaponSkins.Size);
}

// Create the starting map array from file, or create the file if it doesn't exist
public void CreateMapList()
{
	aStartMaps.Clear();
	BuildPath(Path_SM, List_FileStartMaps, sizeof(List_FileStartMaps), "configs/l4d2_wsm_maplist.txt");
	
	if (!FileExists(List_FileStartMaps))
	{
		LogMessage("%T", "StartMap_ListFile_Create", LANG_SERVER);
		File newList = OpenFile(List_FileStartMaps, "w+");
		newList.WriteLine("c1m1_hotel");
		newList.WriteLine("c2m1_highway");
		newList.WriteLine("c3m1_plankcountry");
		newList.WriteLine("c4m1_milltown_a");
		newList.WriteLine("c5m1_waterfront");
		newList.WriteLine("c6m1_riverbank");
		newList.WriteLine("c7m1_docks");
		newList.WriteLine("c8m1_apartments");
		newList.WriteLine("c9m1_alleys");
		newList.WriteLine("c10m1_caves");
		newList.WriteLine("c11m1_greenhouse");
		newList.WriteLine("c12m1_hilltop");
		newList.WriteLine("c13m1_alpinecreek");
		newList.WriteLine("c14m1_junkyard");
		delete newList;
	}
	char line[48];
	File MapList_LoadFile = OpenFile(List_FileStartMaps, "r");
	while (MapList_LoadFile.ReadLine(line, sizeof(line)) && !MapList_LoadFile.EndOfFile())
	{
		aStartMaps.PushString(line);
	}
	MapList_LoadFile.Close();
	if (GetConVarInt(h_ReportToConsole) >= 1) LogMessage("%T", "StartMapList_Built_Complete", LANG_SERVER, aStartMaps.Length);
}

// Clear startup message flag when client disconnects
public void OnClientDisconnect(int iClient)
{
	bClientSawStartMessage[iClient] = false;
}

// ===========================================================================
// EVENT HOOKS
// ===========================================================================

// Round started
public void Event_RoundStarted(Handle hEvent, const char[] strName, bool bDontBroadcast)
{
	if (GetConVarInt(h_EnablePlugin) == 1)
	{
		if (!bServerHasSpawned)
		{
			LogMessage("%T", "Report_ServerSpawned", LANG_SERVER);
			CreateSkinList();
			CreateMapList();
		}
		if (GetConVarInt(h_ReportToConsole) >= 1) LogMessage("%T", "Report_RoundStart", LANG_SERVER);
		if (GetConVarInt(h_ReportToConsole) >= 1) LogMessage("%T", "Report_CheckingMapList", LANG_SERVER);
		if (GetConVarInt(h_EnableRandomSkins) == 1) RandomizeSkins();
		char strCurrentMap[32];
		char strArrayMap[32];
		GetCurrentMap(strCurrentMap, sizeof(strCurrentMap));
		for (new i = 0; i < aStartMaps.Length; i++)
		{
			aStartMaps.GetString(i, strArrayMap, sizeof(strArrayMap));
			ReplaceString(strArrayMap, sizeof(strArrayMap), "\n", "");
			if (StrEqual(strCurrentMap, strArrayMap))
			{
				bIsStartingMap = true;
				if (GetConVarInt(h_ReportToConsole) >= 1) LogMessage("%T", "Report_CurrentMapFound", LANG_SERVER, strCurrentMap);
				break;
			}
			else bIsStartingMap = false;
		}
		if (bIsStartingMap)
		{
			for (new i; i < MAXPLAYERS; i++) bPlayerGrabbedSecondPistol[i] = false;
		}
	}
}

public void OnConfigsExecuted()
{
	if (GetConVarInt(h_EnablePlugin) == 1)
	{
		if (!bServerHasSpawned)
		{
			LogMessage("%T", "Report_ServerSpawned", LANG_SERVER);
			CreateSkinList();
			CreateMapList();
			bServerHasSpawned = true;
		}
		if (GetConVarInt(h_EnableRandomSkins) == 1) RandomizeSkins();
	}
}

// Player spawned into game
public void Event_PlayerFirstSpawned(Event hEvent, const char[] strName, bool bDontBroadcast)
{
	if (GetConVarInt(h_EnablePlugin) == 1)
	{
		int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
		if ((GetConVarInt(h_EnablePistolManagement) == 1) && (GetConVarInt(h_StartPistolSkins) == 1) && bIsStartingMap)
		{
			if ((GetClientTeam(iClient) == TEAM_SURVIVOR) && (IsClientInGame(iClient)))
			{
				int iSlot1 = GetPlayerWeaponSlot(iClient, 1);
				int iRandSkin = GetRandomInt(0, (GetConVarInt(h_PistolSkinCount) - 1));
				if (iSlot1 > 0) SetEntProp(iSlot1, Prop_Send, "m_nSkin", iRandSkin);
				int iActiveWeapon = GetEntPropEnt(iClient, Prop_Data, "m_hActiveWeapon");
				if (iSlot1 == iActiveWeapon)
				{
					int iViewWeapon = GetEntPropEnt(iClient, Prop_Send, "m_hViewModel");
					SetEntProp(iViewWeapon, Prop_Send, "m_nSkin", iRandSkin);
				}
				if (GetConVarInt(h_ReportToConsole) == 2) LogMessage("%T", "Report_SurvivorSpawnedPistolSet", LANG_SERVER, iClient, iRandSkin);
				iRightPistolSkin[iClient] = iRandSkin;
			}
		}
		if ((GetClientTeam(iClient) == TEAM_SURVIVOR) && (IsClientInGame(iClient)) && (GetConVarInt(h_EnableSpawnMessage) == 1) && (!bClientSawStartMessage[iClient])) CreateTimer(10.0, SpawnMessageTimer, iClient, TIMER_FLAG_NO_MAPCHANGE);
		if (GetConVarInt(h_EnableGrenadeManagement) == 1)
		{
			int iSlot2 = GetPlayerWeaponSlot(iClient, 2);
			int iGrenade = 0;
			if (iSlot2 > 0)
			{
				char strWepClassname[32];
				GetEdictClassname(iSlot2, strWepClassname, sizeof(strWepClassname));
				if (StrEqual(strWepClassname, "weapon_pipe_bomb")) iGrenade = 1;
				else if (StrEqual(strWepClassname, "weapon_molotov")) iGrenade = 2;
				else if (StrEqual(strWepClassname, "weapon_vomitjar")) iGrenade = 3;
			}
			iCurrentGrenade[iClient] = iGrenade;
		}
	}
}

// Player picked up weapon. I don't like hooking the player_use event like this, but there's no other way to check dropped weapons.
public void Event_PickupWeapon(Event hEvent, const char[] strName, bool bDontBroadcast)
{
	if (GetConVarInt(h_EnablePlugin) == 1)
	{
		char strEdictClassname[32];
		int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
		int iEntID = hEvent.GetInt("targetID")
		GetEntityClassname(iEntID, strEdictClassname, sizeof(strEdictClassname));
		if ((StrContains(strEdictClassname, "weapon_") == 0) && (StrContains(strEdictClassname, "melee") == -1))
		{
			int iEntSkin = GetEntProp(iEntID, Prop_Send, "m_nSkin");
			int iWeaponID;
			if (StrEqual(strEdictClassname, "weapon_spawn")) iWeaponID = GetEntProp(iEntID, Prop_Send, "m_weaponID");
			if (((StrEqual(strEdictClassname, "weapon_pistol_spawn")) || ((StrEqual(strEdictClassname, "weapon_spawn")) && (iWeaponID == 1)) || (StrEqual(strEdictClassname, "weapon_pistol"))) && (GetConVarInt(h_EnablePistolManagement) == 1))
			{
				if (iEntSkin >= GetConVarInt(h_PistolSkinCount))
				{
					if (GetConVarInt(h_ReportToConsole) == 2) LogMessage("%T", "Report_SurvivorGetInvalidPistol", LANG_SERVER, iClient);
					iEntSkin = 0;
				}
				if (!bPlayerHasDualPistols(iClient))
				{
					iRightPistolSkin[iClient] = iEntSkin;
				}
				else if ((bPlayerHasDualPistols(iClient)) && (!bPlayerGrabbedSecondPistol[iClient]))
				{
					bPlayerGrabbedSecondPistol[iClient] = true;
					SetClientPistolLeft(iClient, iEntSkin);
				}
			}
			else if (((StrContains(strEdictClassname, "grenade_launcher") != -1) || (StrEqual(strEdictClassname, "weapon_spawn")) && (iWeaponID == 21)) && (!bPlayerHasGrenadeLauncher[iClient]))
			{
				int iSlot0 = GetPlayerWeaponSlot(iClient, 0);
				SetEntProp(iSlot0, Prop_Send, "m_nSkin", iEntSkin);
				int iActiveWeapon = GetEntPropEnt(iClient, Prop_Data, "m_hActiveWeapon");
				if (iSlot0 == iActiveWeapon)
				{
					int iViewWeapon = GetEntPropEnt(iClient, Prop_Send, "m_hViewModel");
					SetEntProp(iViewWeapon, Prop_Send, "m_nSkin", iEntSkin);
				}
				bPlayerHasGrenadeLauncher[iClient] = true;
				if (GetConVarInt(h_ReportToConsole) == 2) LogMessage("%T", "Report_SurvivorGetGrenadeLauncher", LANG_SERVER, iClient, iEntSkin);
			}
			else if (((StrContains(strEdictClassname, "rifle_m60") != -1) || (StrEqual(strEdictClassname, "weapon_spawn")) && (iWeaponID == 37)) && (!bPlayerHasM60[iClient]))
			{
				int iSlot0 = GetPlayerWeaponSlot(iClient, 0);
				SetEntProp(iSlot0, Prop_Send, "m_nSkin", iEntSkin);
				int iActiveWeapon = GetEntPropEnt(iClient, Prop_Data, "m_hActiveWeapon");
				if (iSlot0 == iActiveWeapon)
				{
					int iViewWeapon = GetEntPropEnt(iClient, Prop_Send, "m_hViewModel");
					SetEntProp(iViewWeapon, Prop_Send, "m_nSkin", iEntSkin);
				}
				bPlayerHasM60[iClient] = true;
				if (GetConVarInt(h_ReportToConsole) == 2) LogMessage("%T", "Report_SurvivorGetM60", LANG_SERVER, iClient, iEntSkin);
			}
			else if (GetConVarInt(h_EnableGrenadeManagement) == 1)
			{
				if (((StrContains(strEdictClassname, "pipe_bomb") != -1) && (iCurrentGrenade[iClient] != 1)) || ((StrContains(strEdictClassname, "molotov") != -1) && (iCurrentGrenade[iClient] != 2)) || ((StrContains(strEdictClassname, "vomitjar") != -1) && (iCurrentGrenade[iClient] != 3)))
				{
					int iSlot2 = GetPlayerWeaponSlot(iClient, 2);
					iGrenadeSkin[iClient] = GetEntProp(iSlot2, Prop_Send, "m_nSkin");
					if (StrContains(strEdictClassname, "pipe_bomb") != -1) iCurrentGrenade[iClient] = 1;
					else if (StrContains(strEdictClassname, "molotov") != -1) iCurrentGrenade[iClient] = 2;
					else if (StrContains(strEdictClassname, "vomitjar") != -1) iCurrentGrenade[iClient] = 3;
					if (GetConVarInt(h_ReportToConsole) == 2) LogMessage("%T", "Report_SurvivorGetGrenade", LANG_SERVER, iClient, strEdictClassname, iGrenadeSkin[iClient]);
				}
			}
		}
	}
}

// Player dropped weapon
public void Event_PlayerDroppedWeapon(Event hEvent, const char[] strName, bool bDontBroadcast)
{
	if (GetConVarInt(h_EnablePlugin) == 1)
	{
		int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
		char strDroppedItem[32];
		hEvent.GetString("item", strDroppedItem, sizeof(strDroppedItem));
		if ((StrEqual(strDroppedItem, "pistol")) && (GetConVarInt(h_EnablePistolManagement) == 1))
		{
			int iDroppedItem = hEvent.GetInt("propid");
			int iDroppedSkin = iRightPistolSkin[iClient];
			SetEntProp(iDroppedItem, Prop_Send, "m_nSkin", iDroppedSkin);
			if (GetConVarInt(h_ReportToConsole) == 2) LogMessage("%T", "Report_SurvivorDroppedPistol", LANG_SERVER, iClient, iDroppedSkin);
			CreateTimer(0.1, TimerCheckSecondPistol, iClient);
		}
		if (StrEqual(strDroppedItem, "grenade_launcher"))
		{
			bPlayerHasGrenadeLauncher[iClient] = false;
			if (GetConVarInt(h_ReportToConsole) == 2) LogMessage("%T", "Report_SurvivorDropGrenadeLauncher", LANG_SERVER, iClient);
		}
		else if (StrEqual(strDroppedItem, "rifle_m60"))
		{
			bPlayerHasM60[iClient] = false;
			if (GetConVarInt(h_ReportToConsole) == 2) LogMessage("%T", "Report_SurvivorDropM60", LANG_SERVER, iClient);
		}
	}
}

public Action TimerCheckSecondPistol(Handle timer, int iClient)
{
	if (IsValidEdict(iEntIndexOfDroppedPistol))
	{
		char strDroppedItem[32];
		GetEdictClassname(iEntIndexOfDroppedPistol, strDroppedItem, sizeof(strDroppedItem));
		if ((StrEqual(strDroppedItem, "weapon_pistol")) && (GetEntPropEnt(iEntIndexOfDroppedPistol, Prop_Send, "m_hOwnerEntity") == -1))
		{
			SetEntProp(iEntIndexOfDroppedPistol, Prop_Send, "m_nSkin", iLeftPistolSkin[iClient]);
			if (GetConVarInt(h_ReportToConsole) == 2) LogMessage("%T", "Report_SurvivorDroppedSecondPistol", LANG_SERVER, iClient, iLeftPistolSkin[iClient]);
		}
	}
}

// Player revived via defib
public void Event_PlayerDefibbed(Event hEvent, const char[] strName, bool bDontBroadcast)
{
	if ((GetConVarInt(h_EnablePlugin) == 1) && (GetConVarInt(h_EnablePistolManagement) == 1))
	{
		int iRevivedClient = GetClientOfUserId(hEvent.GetInt("subject"));
		int iSlot1 = GetPlayerWeaponSlot(iRevivedClient, 1);
		char strEdictClassname[32];
		GetEdictClassname(iSlot1, strEdictClassname, sizeof(strEdictClassname));
		if (StrEqual(strEdictClassname, "weapon_pistol"))
		{
			SetEntProp(iSlot1, Prop_Send, "m_nSkin", iRightPistolSkin[iRevivedClient]);
			if (GetConVarInt(h_ReportToConsole) >= 1) LogMessage("%T", "Report_SurvivorDefibbed", LANG_SERVER, iRevivedClient, iRightPistolSkin[iRevivedClient]);
		}
	}
}

// Player rescued from closet
public void Event_PlayerRescuedFromCloset(Event hEvent, const char[] strName, bool bDontBroadcast)
{
	if ((GetConVarInt(h_EnablePlugin) == 1) && (GetConVarInt(h_EnablePistolManagement) == 1))
	{
		int iRevivedClient = GetClientOfUserId(hEvent.GetInt("victim"));
		int iSlot1 = GetPlayerWeaponSlot(iRevivedClient, 1);
		char strEdictClassname[32];
		GetEdictClassname(iSlot1, strEdictClassname, sizeof(strEdictClassname));
		if (StrEqual(strEdictClassname, "weapon_pistol"))
		{
			SetEntProp(iSlot1, Prop_Send, "m_nSkin", iRightPistolSkin[iRevivedClient]);
			if (GetConVarInt(h_ReportToConsole) >= 1) LogMessage("%T", "Report_SurvivorRescued", LANG_SERVER, iRevivedClient, iRightPistolSkin[iRevivedClient]);
		}
	}
}

// Entity created. Used for setting grenade skins when thrown and fixing dropped secondary pistol skins
public void OnEntityCreated(int iEntity, const char[] strClassname)
{
	if (GetConVarInt(h_EnablePlugin) != 1) return;
	if (iEntity < 1) return;
	if (StrContains(strClassname, "_projectile") != -1)
	{
		SDKHook(iEntity, SDKHook_SpawnPost, SpawnPost_Projectile);
	}
	else if ((StrEqual(strClassname, "weapon_pistol")) && (GetConVarInt(h_EnablePistolManagement) == 1))
	{
		SDKHook(iEntity, SDKHook_SpawnPost, SpawnPost_DroppedPistol);
	}
}

public SpawnPost_Projectile(iEntity)
{
	char strClassname[32];
	GetEdictClassname(iEntity, strClassname, sizeof(strClassname));
	int iClient = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity");
	if ((IsClientInGame(iClient)) && (GetClientTeam(iClient) == TEAM_SURVIVOR))
	{
		if ((StrEqual(strClassname, "pipe_bomb_projectile")) && (iCurrentGrenade[iClient] == 1)) SetEntProp(iEntity, Prop_Send, "m_nSkin", iGrenadeSkin[iClient]);
		else if ((StrEqual(strClassname, "molotov_projectile")) && (iCurrentGrenade[iClient] == 2)) SetEntProp(iEntity, Prop_Send, "m_nSkin", iGrenadeSkin[iClient]);
		else if ((StrEqual(strClassname, "vomitjar_projectile")) && (iCurrentGrenade[iClient] == 3)) SetEntProp(iEntity, Prop_Send, "m_nSkin", iGrenadeSkin[iClient]);
		if (GetConVarInt(h_ReportToConsole) == 2) LogMessage("%T", "Report_SurvivorThrewGrenade", LANG_SERVER, iClient, strClassname, iGrenadeSkin[iClient]);
		iCurrentGrenade[iClient] = 0;
		iGrenadeSkin[iClient] = 0;
	}
}

public SpawnPost_DroppedPistol(iEntity)
{
	if (GetConVarInt(h_EnablePlugin) != 1) return;
	iEntIndexOfDroppedPistol = iEntity;
}

// ===========================================================================
// FUNCTION CODE
// ===========================================================================

// Randomize weapon spawns on the current map
public void RandomizeSkins()
{
	char strEdictClassname[32];
	int iSkinUpperBound;
	int iGunAndItemSpawnCount = 0;
	int iMeleeSpawnCount = 0;
	
	for (new i = 0; i <= GetEntityCount(); i++)
	{
		if (IsValidEntity(i))
		{
			GetEdictClassname(i, strEdictClassname, sizeof(strEdictClassname));
			if (((StrContains(strEdictClassname, "_spawn") != -1) && (!StrEqual(strEdictClassname, "weapon_spawn")) && (!StrEqual(strEdictClassname, "weapon_melee_spawn"))) || ((StrEqual(strEdictClassname, "weapon_pistol_spawn") && (GetConVarInt(h_EnablePistolManagement) == 1))))
			{
				char strCompareName[32];
				char strResultSkin[4];
				int iResultSkin;
				Format(strCompareName, sizeof(strCompareName), strEdictClassname[7]);
				ReplaceString(strCompareName, sizeof(strCompareName), "_spawn", "");
				if (sm_AllWeaponSkins.GetValue(strCompareName, iSkinUpperBound))
				{
					iResultSkin = GetRandomInt(0, iSkinUpperBound);
					IntToString(iResultSkin, strResultSkin, sizeof(strResultSkin));
					SetEntProp(i, Prop_Send, "m_nSkin", iResultSkin);
					DispatchKeyValue(i, "weaponskin", strResultSkin);
					if (GetConVarInt(h_ReportToConsole) == 2) LogMessage("%T", "Report_RNGSkinsFoundSpawn", LANG_SERVER, strEdictClassname, strResultSkin);
					iGunAndItemSpawnCount++;
				}
			}
			else if (StrEqual(strEdictClassname, "weapon_spawn"))
			{
				char strResultSkin[4];
				int iResultSkin;
				int iWeaponID = GetEntProp(i, Prop_Send, "m_weaponID")
				for (new j = 0; j < sizeof(iNumericFirearmIDs); j++)
				{
					if (iWeaponID == iNumericFirearmIDs[j][0])
					{
						if ((iWeaponID == 1) && (GetConVarInt(h_EnablePistolManagement) == 0))
						{
							if (GetConVarInt(h_ReportToConsole) == 2) LogMessage("%T", "Report_RNGSkinsFoundPistolDisabled", LANG_SERVER);
						}
						else
						{
							iResultSkin = GetRandomInt(0, iNumericFirearmIDs[j][1]);
							IntToString(iResultSkin, strResultSkin, sizeof(strResultSkin));
							SetEntProp(i, Prop_Send, "m_nSkin", iResultSkin);
							DispatchKeyValue(i, "weaponskin", strResultSkin);
							if (GetConVarInt(h_ReportToConsole) == 2) LogMessage("%T", "Report_RNGSkinsFoundSpawn", LANG_SERVER, strEdictClassname, strResultSkin);
							iGunAndItemSpawnCount++;
						}
						break;
					}
				}
			}
			else if (StrEqual(strEdictClassname, "weapon_melee_spawn"))
			{
				char strModelName[256];
				char strResultSkin[4];
				char strCompareName[32];
				char strRemoveString[8];
				int iResultSkin;
				int iStartCell = 23;
				
				strRemoveString = ".mdl";
				GetEntPropString(i, Prop_Data, "m_ModelName", strModelName, sizeof(strModelName));
				if (StrContains(strModelName, "knife_t.mdl") != -1)
				{
					iStartCell = 26;
					strRemoveString = "_t.mdl";
				}
				Format(strCompareName, sizeof(strCompareName), strModelName[iStartCell]);
				ReplaceString(strCompareName, sizeof(strCompareName), strRemoveString, "");
				if (StrEqual(strCompareName, "bat")) strCompareName = "baseball_bat";
				if (sm_AllWeaponSkins.GetValue(strCompareName, iSkinUpperBound))
				{
					iResultSkin = GetRandomInt(0, iSkinUpperBound);
					IntToString(iResultSkin, strResultSkin, sizeof(strResultSkin));
					SetEntProp(i, Prop_Send, "m_nSkin", iResultSkin);
					DispatchKeyValue(i, "weaponskin", strResultSkin);
					if (GetConVarInt(h_ReportToConsole) == 2) LogMessage("%T", "Report_RNGSkinsFoundSpawn", LANG_SERVER, strCompareName, strResultSkin);
					iMeleeSpawnCount++;
				}
			}
		}
	}
	if (GetConVarInt(h_ReportToConsole) >= 1) LogMessage("%T", "Report_RNGSkinsFinished", LANG_SERVER, iGunAndItemSpawnCount, iMeleeSpawnCount);
}

// Calculate dual pistol skin index for the correct right-hand pistol
public void SetClientPistolRight(int iClient, int iNewSkin)
{
	int iSlot1 = GetPlayerWeaponSlot(iClient, 1);
	if (iSlot1 > 0)
	{
		char strEdictClassname[32];
		GetEdictClassname(iSlot1, strEdictClassname, sizeof(strEdictClassname));
		if (!StrEqual(strEdictClassname, "weapon_pistol")) ReplyToCommand(iClient, "[L4D2WSM] %T", "CMD_ClientNoPistol", iClient);
		else
		{
			if (iNewSkin >= GetConVarInt(h_PistolSkinCount)) ReplyToCommand(iClient, "[L4D2WSM] %T", "CMD_ClientBadSkinIndex", iClient);
			else
			{
				if (!bPlayerHasDualPistols(iClient)) SetEntProp(iSlot1, Prop_Send, "m_nSkin", iNewSkin);
				else CalcPistolSkin(iClient, iNewSkin, iSlot1, false);
			}
			iRightPistolSkin[iClient] = iNewSkin;
		}
	}
}

// Calculate dual pistol skin index for the correct left-hand pistol
public void SetClientPistolLeft(int iClient, int iNewSkin)
{
	int iSlot1 = GetPlayerWeaponSlot(iClient, 1);
	if (iSlot1 > 0)
	{
		char strEdictClassname[32];
		GetEdictClassname(iSlot1, strEdictClassname, sizeof(strEdictClassname));
		if (!StrEqual(strEdictClassname, "weapon_pistol")) ReplyToCommand(iClient, "[L4D2WSM] %T", "CMD_ClientNoPistol", iClient);
		else
		{
			if (iNewSkin >= GetConVarInt(h_PistolSkinCount)) ReplyToCommand(iClient, "[L4D2WSM] %T", "CMD_ClientBadSkinIndex", iClient);
			else
			{
				if (!bPlayerHasDualPistols(iClient)) ReplyToCommand(iClient, "[L4D2WSM] %T", "CMD_ClientOnlyOnePistol", iClient);
				else CalcPistolSkin(iClient, iNewSkin, iSlot1, true);
			}
			iLeftPistolSkin[iClient] = iNewSkin;
		}
	}
}

// Actual pistol skin calculation code
public void CalcPistolSkin(int iClient, int iInputSkin, int iSlot1, bool bLeftPistol)
{
	int iOutputSkin;
	if (GetConVarInt(h_PistolSkinMode) == 1)
	{
		LogMessage("%T", "Report_PistolSkinCalculationL", LANG_SERVER, GetConVarInt(h_PistolSkinMode));
		if (!bLeftPistol)
		{
			iOutputSkin = iInputSkin * GetConVarInt(h_PistolSkinCount);
			iOutputSkin = iOutputSkin + iLeftPistolSkin[iClient];
		}
		else
		{
			iOutputSkin = iRightPistolSkin[iClient] * GetConVarInt(h_PistolSkinCount);
			iOutputSkin = iOutputSkin + iInputSkin;
		}
	}
	else
	{
		LogMessage("%T", "Report_PistolSkinCalculationR", LANG_SERVER, GetConVarInt(h_PistolSkinMode));
		if (!bLeftPistol)
		{
			iOutputSkin = iLeftPistolSkin[iClient] * GetConVarInt(h_PistolSkinCount);
			iOutputSkin = iOutputSkin + iInputSkin;
		}
		else
		{
			iOutputSkin = iInputSkin * GetConVarInt(h_PistolSkinCount);
			iOutputSkin = iOutputSkin + iRightPistolSkin[iClient];
		}
	}
	SetEntProp(iSlot1, Prop_Send, "m_nSkin", iOutputSkin);
	int iActiveWeapon = GetEntPropEnt(iClient, Prop_Data, "m_hActiveWeapon");
	if (iSlot1 == iActiveWeapon)
	{
		int iViewWeapon = GetEntPropEnt(iClient, Prop_Send, "m_hViewModel");
		SetEntProp(iViewWeapon, Prop_Send, "m_nSkin", iOutputSkin);
	}
	if (GetConVarInt(h_ReportToConsole) == 2) LogMessage("%T", "Report_PistolSkinCalcComplete", LANG_SERVER, iInputSkin, iRightPistolSkin[iClient], iLeftPistolSkin[iClient], iOutputSkin);
	return;
}

// Selecting a weapon skin from the menu/via command
public void SetClientWeaponSkin(int iClient, int iSlot, int iSkin)
{
	if (iSlot > 0)
	{
		char strEdictClassname[32];
		GetEdictClassname(iSlot, strEdictClassname, sizeof(strEdictClassname));
		if (StrEqual(strEdictClassname, "weapon_pistol")) ReplyToCommand(iClient, "[L4D2WSM] %T", "CMD_WrongPistolsCmd", LANG_SERVER);
		else 
		{
			SetEntProp(iSlot, Prop_Send, "m_nSkin", iSkin);
			int iActiveWeapon = GetEntPropEnt(iClient, Prop_Data, "m_hActiveWeapon");
			if (iSlot == iActiveWeapon)
			{
				int iViewWeapon = GetEntPropEnt(iClient, Prop_Send, "m_hViewModel");
				SetEntProp(iViewWeapon, Prop_Send, "m_nSkin", iSkin);
			}
			if (GetConVarInt(h_ReportToConsole) == 2)
			{
				LogMessage("%T", "Report_ClientChangedWepSkin", LANG_SERVER, iClient, iSlot, iSkin);
				if (iSlot == GetPlayerWeaponSlot(iClient, 2)) LogMessage("%T", "Report_ClientChangedGrenadeSkin", LANG_SERVER, iClient, iSkin);
			}
			if (iSlot == GetPlayerWeaponSlot(iClient, 2))
			{
				iGrenadeSkin[iClient] = iSkin;
			}
		}
	}
	else LogMessage("%T", "Report_ClientChangedInvalidSlot", LANG_SERVER);
}

// Spawn message timer
public Action SpawnMessageTimer(Handle timer, int iClient)
{
	if (GetConVarInt(h_EnablePlugin) != 1) return;
	if (!IsClientInGame(iClient)) return;
	if (IsFakeClient(iClient)) return;
	if (GetConVarInt(h_EnableSkinMenus) == 1)
	{
		if (GetConVarInt(h_EnablePistolManagement) == 1) PrintToChat(iClient, "[L4D2WSM] %T", "IntroMsg_Full", iClient);
		else PrintToChat(iClient, "[L4D2WSM] %T", "IntroMsg_NoPistols", iClient);
	}
	bClientSawStartMessage[iClient] = true;
}

// ===========================================================================
// COMMANDS
// ===========================================================================

// Run player spawn code again, debugging purposes
public Action ReHookCmd(int iClient, int args)
{
	if (GetConVarInt(h_EnablePlugin) == 1)
	{
		if ((GetConVarInt(h_EnablePistolManagement) == 1) && bIsStartingMap)
		{
			if ((GetClientTeam(iClient) == TEAM_SURVIVOR) && (IsClientInGame(iClient)))
			{
				int iSlot1 = GetPlayerWeaponSlot(iClient, 1);
				int iRandSkin = GetRandomInt(0, (GetConVarInt(h_PistolSkinCount) - 1));
				if (iSlot1 > 0) SetEntProp(iSlot1, Prop_Send, "m_nSkin", iRandSkin);
				int iActiveWeapon = GetEntPropEnt(iClient, Prop_Data, "m_hActiveWeapon");
				if (iSlot1 == iActiveWeapon)
				{
					int iViewWeapon = GetEntPropEnt(iClient, Prop_Send, "m_hViewModel");
					SetEntProp(iViewWeapon, Prop_Send, "m_nSkin", iRandSkin);
				}
				if (GetConVarInt(h_ReportToConsole) == 2) LogMessage("%T", "Report_SurvivorSpawnedPistolSet", LANG_SERVER, iClient, iRandSkin);
				iRightPistolSkin[iClient] = iRandSkin;
			}
		}
		if ((GetClientTeam(iClient) == TEAM_SURVIVOR) && (IsClientInGame(iClient)) && (GetConVarInt(h_EnableSpawnMessage) == 1) && (!bClientSawStartMessage[iClient])) CreateTimer(10.0, SpawnMessageTimer, iClient, TIMER_FLAG_NO_MAPCHANGE);
		if (GetConVarInt(h_EnableGrenadeManagement) == 1)
		{
			int iSlot2 = GetPlayerWeaponSlot(iClient, 2);
			int iGrenade = 0;
			if (iSlot2 > 0)
			{
				char strWepClassname[32];
				GetEdictClassname(iSlot2, strWepClassname, sizeof(strWepClassname));
				if (StrEqual(strWepClassname, "weapon_pipe_bomb")) iGrenade = 1;
				else if (StrEqual(strWepClassname, "weapon_molotov")) iGrenade = 2;
				else if (StrEqual(strWepClassname, "weapon_vomitjar")) iGrenade = 3;
			}
			iCurrentGrenade[iClient] = iGrenade;
		}
	}
}

// Randomize skins on current map
public Action RandomizeSkinCmd(int iClient, int args)
{
	if (GetConVarInt(h_EnablePlugin) != 1)
	{
		ShowActivity2(iClient, "[L4D2WSM]", " %T", "Adm_PluginDisabled", iClient);
		return Plugin_Handled;
	}
	RandomizeSkins();
	if (iClient > 0) ShowActivity2(iClient, "[L4D2WSM]", " %T", "Adm_WepSkinsRandomized", iClient);
	return Plugin_Handled;
}

// Refresh the weapon skin list
public Action RecreateSkinList(int iClient, int args)
{
	if (GetConVarInt(h_EnablePlugin) != 1)
	{
		ShowActivity2(iClient, "[L4D2WSM]", " %T", "Adm_PluginDisabled", iClient);
		return Plugin_Handled;
	}
	CreateSkinList();
	if (iClient > 0) ShowActivity2(iClient, "[L4D2WSM]", " %T", "Adm_SkinListRefreshed", iClient);
	return Plugin_Handled;
}

// Refresh the start map list
public Action RecreateMapList(int iClient, int args)
{
	if (GetConVarInt(h_EnablePlugin) != 1)
	{
		ShowActivity2(iClient, "[L4D2WSM]", " %T", "Adm_PluginDisabled", iClient);
		return Plugin_Handled;
	}
	CreateMapList();
	if (iClient > 0) ShowActivity2(iClient, "[L4D2WSM]", " %T", "Adm_MapListRefreshed", iClient);
	return Plugin_Handled;
}

// Command to set right-hand pistol skin
public Action SetClientPistolRightCmd(int iClient, int args)
{
	if (GetConVarInt(h_EnablePlugin) != 1)
	{
		ReplyToCommand(iClient, "[L4D2WSM] %T", "CMD_PluginDisabled", iClient);
		return Plugin_Handled;
	}
	if (GetConVarInt(h_EnablePistolManagement) != 1)
	{
		ReplyToCommand(iClient, "[L4D2WSM] %T", "CMD_PistolsDisabled", iClient);
		return Plugin_Handled;
	}
	if (args != 1)
	{
		ReplyToCommand(iClient, "[L4D2WSM] %T", "CMD_PistolsBadSyntax", iClient, "r");
		return Plugin_Handled;
	}
	char strSkin[4];
	GetCmdArg(1, strSkin, sizeof(strSkin));
	int iSkin = StringToInt(strSkin, 10);
	SetClientPistolRight(iClient, iSkin);
	return Plugin_Handled;
}

// Command to set left-hand pistol skin
public Action SetClientPistolLeftCmd(int iClient, int args)
{
	if (GetConVarInt(h_EnablePlugin) != 1)
	{
		ReplyToCommand(iClient, "[L4D2WSM] %T", "CMD_PluginDisabled", iClient);
		return Plugin_Handled;
	}
	if (GetConVarInt(h_EnablePistolManagement) != 1)
	{
		ReplyToCommand(iClient, "[L4D2WSM] %T", "CMD_PistolsDisabled", iClient);
		return Plugin_Handled;
	}
	if (args != 1)
	{
		ReplyToCommand(iClient, "[L4D2WSM] %T", "CMD_PistolsBadSyntax", iClient, "l");
		return Plugin_Handled;
	}
	char strSkin[4];
	GetCmdArg(1, strSkin, sizeof(strSkin));
	int iSkin = StringToInt(strSkin, 10);
	SetClientPistolLeft(iClient, iSkin);
	return Plugin_Handled;
}

// Command to set weapon skin manually
public Action SetClientSlotSkinCmd(int iClient, int args)
{
	if (GetConVarInt(h_EnablePlugin) != 1)
	{
		ReplyToCommand(iClient, "[L4D2WSM] %T", "CMD_PluginDisabled", iClient);
		return Plugin_Handled;
	}
	if (args != 2)
	{
		ReplyToCommand(iClient, "[L4D2WSM] %T", "CMD_SkinBadSyntax", iClient);
		return Plugin_Handled;
	}
	char strSlotArg[4];
	GetCmdArg(1, strSlotArg, sizeof(strSlotArg));
	int iSlotArg = StringToInt(strSlotArg, 10);
	if (((iSlotArg > 4) && (GetConVarInt(h_MeleeMode) == 0)) || (((iSlotArg > 6) || (iSlotArg == 5)) && (GetConVarInt(h_MeleeMode) == 1)))
	{
		ReplyToCommand(iClient, "[L4D2WSM] %T", "CMD_SkinBadSlot", iClient, GetConVarInt(h_MeleeMode) == 1 ? 6 : 4);
		return Plugin_Handled;
	}
	char strSkinArg[4];
	GetCmdArg(2, strSkinArg, sizeof(strSkinArg));
	int iSkinArg = StringToInt(strSkinArg, 10);
	
	int iSlot = GetPlayerWeaponSlot(iClient, iSlotArg);
	if (iSlot > 0)
	{
		char strEdictClassname[32];
		char strCompareName[32];
		int iSkinUpperBound;
		GetEdictClassname(iSlot, strEdictClassname, sizeof(strEdictClassname));
		if (!StrEqual(strEdictClassname, "weapon_melee")) Format(strCompareName, sizeof(strCompareName), strEdictClassname[7]);
		else GetEntPropString(iSlot, Prop_Data, "m_strMapSetScriptName", strCompareName, sizeof(strCompareName));
		if (sm_AllWeaponSkins.GetValue(strCompareName, iSkinUpperBound))
		{
			if (iSkinArg > iSkinUpperBound) ReplyToCommand(iClient, "[L4D2WSM] %T", "CMD_ClientBadSkinIndex", iClient);
			else SetClientWeaponSkin(iClient, iSlot, iSkinArg);
		}
		else ReplyToCommand(iClient, "[L4D2WSM] %T", "CMD_NoSkinsForWeapon", iClient);
	}
	else ReplyToCommand(iClient, "[L4D2WSM] %T", "CMD_EmptySlot", iClient);
	return Plugin_Handled;
}

// ===========================================================================
// MENUS
// ===========================================================================

// Main skin menu code
public Action OpenMainSkinMenu(int iClient, int args)
{
	if (GetConVarInt(h_EnablePlugin) != 1)
	{
		ReplyToCommand(iClient, "[L4D2WSM] %T", "CMD_PluginDisabled", iClient);
		return;
	}
	if (GetConVarInt(h_EnableSkinMenus) != 1)
	{
		ReplyToCommand(iClient, "[L4D2WSM] %T", "CMD_MenusDisabled", iClient);
		return;
	}
	Handle menu = CreateMenu(MainSkinMenuHandler);
	SetMenuTitle(menu, "%T", "Menu_MainName", iClient);

	int iSlot0 = GetPlayerWeaponSlot(iClient, 0);
	int iSlot1 = GetPlayerWeaponSlot(iClient, 1);
	int iSlot2 = GetPlayerWeaponSlot(iClient, 2);
	int iSlot3 = GetPlayerWeaponSlot(iClient, 3);
	int iSlot4 = GetPlayerWeaponSlot(iClient, 4);
	int iSlot6 = 0;
	if (GetConVarInt(h_MeleeMode) == 1) iSlot6 = GetPlayerWeaponSlot(iClient, 6);
	
	int index = 0;
	int iSkinUpperBound;
	char strCompareName[32];
	char strBuffer[8];
 	
	if (iSlot0 > 0)
	{
		char strSlot0[32];
		GetEdictClassname(iSlot0, strSlot0, sizeof(strSlot0));
		Format(strCompareName, sizeof(strCompareName), strSlot0[7]);
		if (sm_AllWeaponSkins.GetValue(strCompareName, iSkinUpperBound))
		{
			Format(strBuffer, sizeof(strBuffer), "%T", "Menu_SlotName", iClient, 1);
			List_SkinMenuOptions[index] = strBuffer;
			iValidMenuSlots[index] = 0;
			index++;
		}
	}
	if (iSlot1 > 0)
	{
		char strSlot1[32];
		GetEdictClassname(iSlot1, strSlot1, sizeof(strSlot1));
		if (!StrEqual(strSlot1, "weapon_pistol"))
		{
			if (!StrEqual(strSlot1, "weapon_melee")) Format(strCompareName, sizeof(strCompareName), strSlot1[7]);
			else if ((StrEqual(strSlot1, "weapon_melee")) && (GetConVarInt(h_MeleeMode) == 0)) GetEntPropString(iSlot1, Prop_Data, "m_strMapSetScriptName", strCompareName, sizeof(strCompareName));
			if (sm_AllWeaponSkins.GetValue(strCompareName, iSkinUpperBound))
			{
				Format(strBuffer, sizeof(strBuffer), "%T", "Menu_SlotName", iClient, 2);
				List_SkinMenuOptions[index] = strBuffer;
				iValidMenuSlots[index] = 1;
				index++;
			}
		}
	}
	if (iSlot2 > 0)
	{
		char strSlot2[32];
		GetEdictClassname(iSlot2, strSlot2, sizeof(strSlot2));
		Format(strCompareName, sizeof(strCompareName), strSlot2[7]);
		if (sm_AllWeaponSkins.GetValue(strCompareName, iSkinUpperBound))
		{
			Format(strBuffer, sizeof(strBuffer), "%T", "Menu_SlotName", iClient, 3);
			List_SkinMenuOptions[index] = strBuffer;
			iValidMenuSlots[index] = 2;
			index++;
		}
	}
	if (iSlot3 > 0)
	{
		char strSlot3[32];
		GetEdictClassname(iSlot3, strSlot3, sizeof(strSlot3));
		Format(strCompareName, sizeof(strCompareName), strSlot3[7]);
		if (sm_AllWeaponSkins.GetValue(strCompareName, iSkinUpperBound))
		{
			Format(strBuffer, sizeof(strBuffer), "%T", "Menu_SlotName", iClient, 4);
			List_SkinMenuOptions[index] = strBuffer;
			iValidMenuSlots[index] = 3;
			index++;
		}
	}
	if (iSlot4 > 0)
	{
		char strSlot4[32];
		GetEdictClassname(iSlot4, strSlot4, sizeof(strSlot4));
		Format(strCompareName, sizeof(strCompareName), strSlot4[7]);
		if (sm_AllWeaponSkins.GetValue(strCompareName, iSkinUpperBound))
		{
			Format(strBuffer, sizeof(strBuffer), "%T", "Menu_SlotName", iClient, 5);
			List_SkinMenuOptions[index] = strBuffer;
			iValidMenuSlots[index] = 4;
			index++;
		}
	}
	if ((iSlot6 > 0) && (GetConVarInt(h_MeleeMode) == 1))
	{
		char strSlot6[32];
		GetEdictClassname(iSlot6, strSlot6, sizeof(strSlot6));
		if (StrEqual(strSlot6, "weapon_melee"))
		{
			GetEntPropString(iSlot6, Prop_Data, "m_strMapSetScriptName", strCompareName, sizeof(strCompareName));
			if (sm_AllWeaponSkins.GetValue(strCompareName, iSkinUpperBound))
			{
				Format(strBuffer, sizeof(strBuffer), "%T", "Menu_SlotMelee", iClient);
				List_SkinMenuOptions[index] = strBuffer;
				iValidMenuSlots[index] = 6;
				index++;
			}
		}
	}
	if (index > 0)
	{
		char strTemp[4];
		for (new i = 0; i < index; i++)
		{
			FormatEx(strTemp, sizeof(strTemp), "%i", index + 1);
			AddMenuItem(menu, strTemp, List_SkinMenuOptions[i]);
		}
		
		SetMenuExitButton(menu, true);
		DisplayMenu(menu, iClient, MENU_TIME_FOREVER);
	}
	else
	{
		ReplyToCommand(iClient, "[L4D2WSM] %T", "CMD_NoAltSkins", iClient);
		return;
	}
}

// Main skin menu handler
public int MainSkinMenuHandler(Handle menu, MenuAction action, int iClient, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			OpenSkinSelectMenu(iClient, iValidMenuSlots[param2]);
		}
		case (MenuAction_Cancel || MenuAction_End):
		{
			CloseHandle(menu);
		}
	}
}

// Skin selection menu code
public int OpenSkinSelectMenu(int iClient, int param2)
{
	iMenuSelectSlot = GetPlayerWeaponSlot(iClient, param2);
	if (iMenuSelectSlot > 0)
	{
		int iSkinUpperBound;
		char strEdictClassname[32];
		char strCompareName[32];
		char strOption[12];
		char strIndex[4];
		GetEdictClassname(iMenuSelectSlot, strEdictClassname, sizeof(strEdictClassname));
		Handle menu = CreateMenu(SkinSelectMenuHandler);
		SetMenuTitle(menu, "%T", "Menu_SkinSelName", iClient, param2 + 1);
		
		if (!StrEqual(strEdictClassname, "weapon_melee")) Format(strCompareName, sizeof(strCompareName), strEdictClassname[7]);
		else GetEntPropString(iMenuSelectSlot, Prop_Data, "m_strMapSetScriptName", strCompareName, sizeof(strCompareName));
		if (sm_AllWeaponSkins.GetValue(strCompareName, iSkinUpperBound))
		{
			int iCurrentSkin = GetEntProp(iMenuSelectSlot,  Prop_Send, "m_nSkin");
			int iSkinCount;
			sm_AllWeaponSkins.GetValue(strCompareName, iSkinCount);
			for (new i = 0; i <= iSkinCount; i++)
			{
				Format(strOption, sizeof(strOption), "%T", "Menu_SkinSelEntry", iClient, i + 1);
				IntToString(i + 1, strIndex, sizeof(strIndex));
				AddMenuItem(menu, strIndex, strOption, iCurrentSkin == i ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
			}
			SetMenuExitButton(menu, true);
			DisplayMenu(menu, iClient, MENU_TIME_FOREVER);
		}
	}
}

// Skin selection menu handler
public int SkinSelectMenuHandler(Handle menu, MenuAction action, int iClient, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			SetClientWeaponSkin(iClient, iMenuSelectSlot, param2);
		}
		case (MenuAction_Cancel || MenuAction_End):
		{
			CloseHandle(menu);
		}
	}
}

// Main pistol menu code
public Action OpenPistolSkinMenu(int iClient, int args)
{
	if (GetConVarInt(h_EnablePlugin) != 1)
	{
		ReplyToCommand(iClient, "[L4D2WSM] %T", "CMD_PluginDisabled", iClient);
		return;
	}
	if (GetConVarInt(h_EnableSkinMenus) != 1)
	{
		ReplyToCommand(iClient, "[L4D2WSM] %T", "CMD_MenusDisabled", iClient);
		return;
	}
	if (GetConVarInt(h_EnablePistolManagement) != 1)
	{
		ReplyToCommand(iClient, "[L4D2WSM] %T", "CMD_PistolsDisabled", iClient);
		return;
	}
	if (bPlayerHasDualPistols(iClient))
	{
		Handle menu = CreateMenu(PistolMainMenuHandler);
		SetMenuTitle(menu, "%T", "Menu_PistolName", iClient);
		
		char strBuffer01[32];
		char strBuffer02[32];
		
		Format(strBuffer01, sizeof(strBuffer01), "%T", "Menu_PistolRightEntry", iClient);
		Format(strBuffer02, sizeof(strBuffer02), "%T", "Menu_PistolLeftEntry", iClient);
		AddMenuItem(menu, "1", strBuffer01);
		AddMenuItem(menu, "2", strBuffer02);
		
		SetMenuExitButton(menu, true);
		DisplayMenu(menu, iClient, MENU_TIME_FOREVER);
	}
	else
	{
		int iPistolSlot = GetPlayerWeaponSlot(iClient, 1);
		char strEdictClassname[32];
		GetEdictClassname(iPistolSlot, strEdictClassname, sizeof(strEdictClassname));
		if (StrEqual(strEdictClassname, "weapon_pistol")) OpenPistolRightMenu(iClient);
		else ReplyToCommand(iClient, "[L4D2WSM] %T", "CMD_ClientNoPistol", iClient);
	}
}

// Main pistol menu handler
public int PistolMainMenuHandler(Handle menu, MenuAction action, int iClient, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			if (param2 == 0)
			{
				OpenPistolRightMenu(iClient);
			}
			else if (param2 == 1)
			{
				OpenPistolLeftMenu(iClient);
			}
		}
		case (MenuAction_Cancel || MenuAction_End):
		{
			CloseHandle(menu);
		}
	}
}

// Right-hand pistol menu code
public Action OpenPistolRightMenu(int iClient)
{
	if (GetConVarInt(h_EnablePistolManagement) != 1)
	{
		ReplyToCommand(iClient, "[L4D2WSM] %T", "CMD_PistolsDisabled", iClient);
		return;
	}
	Handle menu = CreateMenu(PistolRightMenuHandler);
	SetMenuTitle(menu, "%T", "Menu_SelectPistolRightName", iClient);
	
	char strMenuOption[32];
	char strMenuIndex[4];
	
	int iCurrentSkin = iRightPistolSkin[iClient];
	
	for (int i = 0; i < GetConVarInt(h_PistolSkinCount); i++)
	{
		Format(strMenuOption, sizeof(strMenuOption), "%T", "Menu_SkinSelEntry", iClient, i + 1);
		IntToString(i + 1, strMenuIndex, sizeof(strMenuIndex));
		AddMenuItem(menu, strMenuIndex, strMenuOption, iCurrentSkin == i ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	}
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, iClient, MENU_TIME_FOREVER);
}

// Right-hand pistol menu handler
public int PistolRightMenuHandler(Menu menu, MenuAction action, int iClient, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			int iSelectedSkin = param2;
			SetClientPistolRight(iClient, iSelectedSkin);
		}
		case (MenuAction_Cancel || MenuAction_End):
		{
			CloseHandle(menu);
		}
	}
}

// Left-hand pistol menu code
public Action OpenPistolLeftMenu(int iClient)
{
	if (GetConVarInt(h_EnablePistolManagement) != 1)
	{
		ReplyToCommand(iClient, "[L4D2WSM] %T", "CMD_PistolsDisabled", iClient);
		return;
	}
	Handle menu = CreateMenu(PistolLeftMenuHandler);
	SetMenuTitle(menu, "%T", "Menu_SelectPistolLeftName", iClient);
	
	char strMenuOption[32];
	char strMenuIndex[4];
	
	int iCurrentSkin = iLeftPistolSkin[iClient];
	
	for (int i = 0; i < GetConVarInt(h_PistolSkinCount); i++)
	{
		Format(strMenuOption, sizeof(strMenuOption), "%T", "Menu_SkinSelEntry", iClient, i + 1);
		IntToString(i + 1, strMenuIndex, sizeof(strMenuIndex));
		AddMenuItem(menu, strMenuIndex, strMenuOption, iCurrentSkin == i ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	}
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, iClient, MENU_TIME_FOREVER);
}

// Left-hand pistol menu handler
public int PistolLeftMenuHandler(Menu menu, MenuAction action, int iClient, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			int iSelectedSkin = param2;
			SetClientPistolLeft(iClient, iSelectedSkin);
		}
		case (MenuAction_Cancel || MenuAction_End):
		{
			CloseHandle(menu);
		}
	}
}