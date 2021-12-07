/****************************************************************************************************
[CSGO] CSGO Items
*****************************************************************************************************
Credits: 
		NeuroToxin:
					I have learnt a lot from a lot from your previous work and that has helped create this.
****************************************************************************************************
CHANGELOG
****************************************************************************************************
	0.1 ~ 
		- Many changes which I did not even log..
	0.2 ~ 
	
		- Added the ability to get weapon team(s).
		- Added ability to get weapon clip size.
		- Added ability to refill weapon clip size.
		- Added ability to check if a weapon edict is valid.
	0.3 ~ 
	
		- Added CSGOItems_GiveWeapon
							This function is a replacement for GivePlayerItem, it fixes players not getting loadout skins when the weapon team is the opposite of the player.
							This function also automatically equips knives, so you don't need to use EquipPlayerWeapon.
							Example: CSGOItems_GiveWeapon(iClient, "weapon_ak47"); Player team = CT.
							Outcome: Player will recieve an AK47 with his loadout skin.
							Return: Weapon edict index or -1 if failed.
	0.4 ~
		
		- Added CSGOItems_RemoveWeapon
							This function will properly remove a weapon from a client and automatically kill the entity.
							Example: CSGOItems_RemoveWeapon(iClient, iWeapon);
							TBD: CSGOItems_RemoveWeaponSlot(iClient, CS_SLOT_PRIMARY);
							Outcome: The players weapon will be completely removed.
							Return: True on success or false if the weapon is invalid.
		
		- Improved CSGOItems_GiveWeapon
							- Added the ability to set custom reserve / clip ammo (Only for guns for obvious reasons :P).
								- Example: CSGOItems_GiveWeapon("weapon_ak47", 10, 30); 10 reserve + 30 clip, if nothing defined it will use games default values.
							- Improved team switching functionality.
							- Improved equip functionality to remove animations, This is still WIP and does not yet work for all weapons.
		
		- Added CSGOItems_SetWeaponAmmo (Thanks Zipcore for the suggestion)
							This function allows you to set the ammo if any valid weapon entity index.
							Example: CSGOItems_SetWeaponAmmo(iWeapon, 30, 30); 30 Reserve / 30 Clip.
							Usage: You can use -1 to skip setting a certain type of ammo, CSGOItems_SetWeaponAmmo(iWeapon, -1, 30); would skip changing the reserve ammo.
							Outcome: The weapon Reserve and / or clip ammo will be changed if the weapon index is valid.
							Return: True on success or false if the weapon is invalid.
							
		0.5 ~
			- Will add a changelog later, too tired for it now :P
		
		0.6 ~ 
			- Fixed Reserve and Clip ammo functionality.
			- Fixed a bug which caused KV Iteration to fail in some cases.
			- Fixed error spam related to m_iZoomLevel.
			- Added CSGOItems_RemoveKnife. (This function will remove the players knife without removing the Zeus if he has one.)
			- Added CSGOItems_RefillReserveAmmo.
			- Added Reserve ammo natives (For retrieving the values).
			- General Cleanup.
		0.7 ~
			- Removed System2.
			- Using SteamWorks now to retrieve language file.
			- Fixed potential infinite loop / crash.
		0.8 ~
			- General optimization / cleanup.
			- Added CSGOItems_GetRandomSkin
							This function will return a random skin defindex.		
			
			- Added CSGOItems_SetAllWeaponsAmmo
							This function will loop through all spawned weapons of a specific classname and set clip/reserve ammo.
		0.9 ~
			- Added CSGOItems_GetActiveWeaponCount
							This function will return the number of actively equipped weapons by classname.
							
							Example 1, Get number of players with AWP equipped on CT: 
									CSGOItems_GetActiveWeaponCount("weapon_awp", CS_TEAM_CT);
							
							Example 2, Get number of players with AWP equipped on T: 
									CSGOItems_GetActiveWeaponCount("weapon_awp", CS_TEAM_T);
									
							Example 3, Get number of players with AWP equipped on any team: 
									CSGOItems_GetActiveWeaponCount("weapon_awp");
									
			- Added CSGOItems_GetWeaponKillAward(ByDefIndex, ByClassName, ByWeaponNum)
							These functions will return the kill award for the specified weapon.
			
			- Fixed some logic errors with variables / loops.
			- Fixed a rare issue where CSGOItems_GiveWeapon would fail when it shouldn't of.
		1.0 ~
			- New method for Removing player weapons, this should fix some crashes!
		
		1.0.1 ~
			- Added CSGOItems_RemoveAllWeapons
					This function will safely remove all the weapons a client has got equipped, with an option to skip a certain slot.
					
					Example 1, Remove all clients weapons.
							CSGOItems_RemoveAllWeapons(iClient);
					
					Example 2, Remove all clients weapons but leave the knife slot.
							CSGOItems_RemoveAllWeapons(iClient, CS_SLOT_KNIFE);
							
					Return: Number of weapons sucessfully removed from client.
					
			- Implemented Bacardi's weapon looping, Very nice, credits to him! (This is a lot safer and more efficient than my old method.)
			- Added an extra validation check before removing client weapons.
		1.1 ~
			- Fixed a bug when retrieving Language would not automatically rename the newly retrieved file.
			- Implemented a new API which retrieves a fixed version of the Item schema which can be iterated without issues, (Thanks Valve, you forced me to spend a day coding in PHP)
		1.2 ~
			- Updated item schema url.
			- Improved validation before removing weapons now.
		1.3 ~
			- Added some experimental and untested support for CSGO Item sets (Still needs some work)
			- Fix item sync not happening on plugin start if late loaded.
			- Fixed a rare case where players hud would disappear.
			- Improved and cleaned up KV Iteration.
			- Improved give weapon, remove weapon and switch weapon code and added more validation (Should help fix some crashes and strange issues which occur)
			- General code cleanup and improvements.
			
		1.3.1 ~
			- Added CSGOItems_DropWeapon
					This function will safely drop a weapon which the client has equipped, what makes this different is it will prevent errors if the weapon does not belong to the client.
					
					Example:
						(BOOL) CSGOItems_DropWeapon(iClient, iWeapon);
				
					Return: True on success
					
			- Fixed netprops for last csgo update.
			- Added CSGOItems_GetWeaponViewModel & CSGOItems_GetWeaponWorldModel natives.
			- General logic improvements / fixes in the natives.
		
		1.3.2 ~
			- Added CSGOItems_GetWeaponSpread natives.
					These natives will return the spread value as a float.
		1.3.3 ~
			- Added CSGOItems_GetWeaponCycleTime natives.
					These natives will return the spread value as a float.
			- Fixed tag mismatches in new natives.
			
		1.3.4 ~
			- Improved RemoveWeapon, now removes the weapon world entity to help prevent crashes.
			- Added Vanilla & Default to skin list.
			- Make sure / Wait for SteamWorks to be loaded before retrieving language / item schema.
			- General validation improvements.
			
		1.3.5 ~
			- Added gloves & spray support.
			- Added experimental support for giving certain weapons in special scenarios when it would give the wrong weapon (Example giving USP when client has P2K in loadout) (PTAH is required)
			- Fixed translation url.
			- Fixed SteamWorks loading late.
			- Fixed a bug where the SwitchTo was being incorrectly determined in CSGOItems_GiveWeapon
			- Added CSGOItems_OnWeaponGiven forward
					public void CSGOItems_OnWeaponGiven(int iClient, int iWeapon, const char[] szClassName, int iDefIndex, int iWeaponSlot, bool bSkinnable, bool bIsKnife)
			- Increased Cell array sizes (I really need to implement Dynamic at some point..)
			- Prevent giving knives to avoid GLST bans (It will now automatically set it to weapon_knife or weapon_knife_t dependent of the client team.)
			- Many other fixes / code cleanup (Please avoid indenting the code using Spedit it will break a few things) (Ignore the compile warnings.)
		1.3.6 ~
			- Removed PTAH completely.
			- Made sprays feature optional, if you create a spray plugin then you will want to enable the cvar csgoitems_spraysenabled.
			- Improved weapon removal method.
			- A few other misc fixes.
		1.3.7 ~
			- Update language url.
		1.3.8 ~
			- Fixed crash related to null being passed in forward when a definition index was out of bounds.
			- Removed the horrible backward slashes which were causing indentation to fuck up, Apparently they were not needed and a forward slash is fine.
				- If you utilize the spray natives then you will notice the folder will be regenerated as csgoitemsv2 in order to fix any pure mismatches with clients.
				- You will have to reupload the new files to your FastDL server.
			- Fixed CSGOItems_IsSkinnableDefIndex throwing an error when the input was out of bounds.
				- It will now also throw an error if the defindex goes over 700 (Which is the current max size of the cell arrays) Just incase volvo add new weapons eventually.
			- Removed some left over code and variables which is no longer used.
			- Fixed WeaponDefIndex and WeaponNum potentially being incorrect inside the CSGOItems_GiveWeapon native.
		1.3.9 ~
			- Improved detection for CSGOItems_IsNativeSkin 
					Example:
						(BOOL) CSGOItems_IsNativeSkin(iWeaponNum, iSkinNum);
				
					Return: True if the skin is for the weapon.
			- Misc code tweaks / cleanup.
		1.4.0 ~
			- Improved knife sequence manipulation in CSGOItems_GiveWeapon 
			- Fixed a potential visual glitch in CSGOItems_DropWeapon
		1.4.1 ~
			- Optimized & cleaned CSGOItems_GiveWeapon.
			- Added anti GLST ban.
				- Added alternative methods for giving knives which evade GLST bans.
				- Added PTAH detection, if PTAH is installed then it will be used to give knives.
				- Added FollowGuideLines detection (Thanks ESK0 for the string help).
			- Added CSGOItems_RespawnWeapon & CSGOItems_RespawnWeaponBySlot (Thanks ESK0 for suggestion)
				- Example: CSGOItems_RespawnWeapon(iClient, iWeapon);
				- Example: CSGOItems_RespawnWeaponBySlot(iClient, CS_SLOT_KNIFE);
			- Fixed a couple of scenarios where CSGOItems_GiveWeapon could fail improperly.
		1.4.2 ~
			- Optimized code, Removed natives calling natives.
			- Improved validation.
		1.4.3 ~
			- Added CSGOItems_GetWeaponNumBySkinNum.
			- Added CSGOItems_GetGlovesNumBySkinNum.
			- Added CSGOItems_FindWeaponByWeaponNum.
			- Added CSGOItems_FindWeaponByDefIndex.
			- Added CSGOItems_GetWeaponNumByWeapon.
			- Added CSGOItems_GetWeaponDisplayNameByWeapon.
			- Added CSGOItems_GetWeaponViewModelByWeapon.
			- Added CSGOItems_GetWeaponWorldModelByWeapon.
			- Added CSGOItems_GetWeaponTeamByWeapon.
			- Added CSGOItems_GetWeaponSlotByWeapon.
			- Added CSGOItems_GetWeaponClipAmmoByWeapon.
			- Added CSGOItems_GetWeaponReserveAmmoByWeapon.
			- Added CSGOItems_GetWeaponKillAwardByWeapon.
			- Added CSGOItems_GetWeaponSpreadByWeapon.
			- Added CSGOItems_GetWeaponCycleTimeByWeapon.
			- Fixed weapon to skin sync
			- Cleaned Knife logic inside CSGOItems_GiveWeapon.
			- Added SoundHook to block Equip Sound when CSGOItems_GiveWeapon is called.
			- Several optimizations.
			- Improved validation in some areas.
		1.4.4 ~
			- Fixed Regex mem leak (Thanks Bara)
			- Removed unnecessary precache logic.
			- Fixed error with skin num going out of bounds.
			- Sync will wait when its the end of round to prevent crashes.
			- Remove a couple of useless things.
			- Next version will rework iteration logic.
		1.4.5 ~
			- Added GiveNamedItem hook from PTAH to automatically Equip knives.
			- Added duplicate Equip call prevention.
			- Fixed handle errors caused by closing them wrongly.
		1.4.6 ~
			- Increased buffer sizes to fix an out of bounds error.
			- Reset other variables on resync.
			- Added back spray precaching.
			- Fixed a few variables defaults.
		1.4.7 ~
			- Massively reduced Item syncing time.
			- Fix an issue where native skins boolean could potentially get set to false after its already true.
		1.4.8 ~
			- Fixed CSGOItems_IsNativeSkin
				- It now has an extra parameter to specify the item type (Currently ITEMTYPE_WEAPON OR ITEMTYPE_GLOVES).
				- For example CSGOItems_IsNativeSkin(iSkinNum, iWeaponNum, ITEMTYPE_WEAPON) or CSGOItems_IsNativeSkin(iSkinNum, iGlovesNum, ITEMTYPE_GLOVES)
			- Slight improvement to sync speed again.
			- Replaced Format with FormatEx as its faster.
		1.4.8.1 ~
			- Disable hibernation during sync and automatically enable it afterwards (If it was enabled in the first place).
		1.4.9 ~
			- Fixed sync issues.
		1.5.0 ~
			- Completely reworked item iteration and implemented the Prefaberator, this will recursively scan inner prefabs dynamically for missed keys, less guess work, more dynamicness!
			- Fixed Buffer sizes cutting display names short.
			- Made the plugin safety checks a less strict.
			- Fixed CSGOItems_RemoveAllWeapons - I had a few complaints and can confirm it was broken, but it should function normally now.
			- Fixed view sequence resetting when giving a weapon, specifically the same one in cases such as CSGOItems_RespawnWeapon.
			- Added future support for quality / rarity.
			- Removed hardcoded guess work for prefabs which were previousally missed, Prefaberator will pick those up now.
			- Cleaned up some code.
			
****************************************************************************************************
INCLUDES
***************************************************************************************************/
#include <sourcemod>
#include <sdktools>
#include <cstrike> 
#include <sdkhooks> 
#include <profiler>
#include <csgoitems> 
#include <autoexecconfig> 
#include <regex>
#include <dynamic>

/****************************************************************************************************
DEFINES
*****************************************************************************************************/
#define VERSION "1.5.0"

#define 	DEFINDEX 		0
#define 	CLASSNAME 		1
#define 	DISPLAYNAME 	2
#define 	SLOT 			3
#define 	TEAM 			4
#define 	CLIPAMMO 		5
#define 	RESERVEAMMO 	6
#define 	TYPE 			7
#define 	KILLAWARD 		8
#define 	ITEMNAME        9
#define     RARITY			10
#define     SKIN_WEAPON		11
#define     SKIN_CASE		12
#define     VIEWMODEL		13
#define     WORLDMODEL		14
#define     DROPMODEL		14
#define     VIEWMATERIAL	15
#define     WORLDMATERIAL	16
#define     SPREAD			17
#define     CYCLETIME		18
#define     VMTPATH			19
#define     VTFPATH			20
#define     QUALITY			21

/****************************************************************************************************
ETIQUETTE.
*****************************************************************************************************/
#pragma newdecls required // To be moved before includes one day.
#pragma semicolon 1

/****************************************************************************************************
PLUGIN INFO.
*****************************************************************************************************/
public Plugin myinfo = 
{
	name = "CSGO Items", 
	author = "SM9", 
	version = VERSION, 
	url = "http://www.fragdeluxe.com"
};

/****************************************************************************************************
HANDLES.
*****************************************************************************************************/
Handle g_hItemsKv = null;
Handle g_hOnItemsSynced = null;
Handle g_hOnPluginEnd = null;
Handle g_hSwitchWeaponCall = null;
Handle g_hOnWeaponGiven = null;
ConVar g_hCvarSpraysEnabled = null;
ConVar g_hCvarHibernation = null;

/****************************************************************************************************
BOOLS.
*****************************************************************************************************/
bool g_bIsDefIndexKnife[1000];
bool g_bIsDefIndexSkinnable[1000];
bool g_bSkinNumGloveApplicable[1000];
bool g_bItemsSynced;
bool g_bItemsSyncing;
bool g_bGivingWeapon[MAXPLAYERS + 1];
bool g_bIsNativeSkin[3][1000][1000];
bool g_bIsSkinInSet[1000][1000];
bool g_bRoundEnd = false;
bool g_bSpraysEnabled = false;
bool g_bFollowGuidelines = false;
bool g_bWeaponEquipped[MAXPLAYERS + 1][2049];
bool g_bHibernation = false;

/****************************************************************************************************
STRINGS.
*****************************************************************************************************/
char g_szWeaponInfo[1000][22][48];
char g_szPaintInfo[1000][22][192];
char g_szMusicKitInfo[1000][3][48];
char g_szGlovesInfo[1000][22][192];
char g_szSprayInfo[1000][22][128];
char g_szItemSetInfo[1000][3][48];
char g_szLangPhrases[21982192];
char g_szSchemaPhrases[21982192];
char g_szCDNPhrases[2000][384];

/****************************************************************************************************
INTS.
*****************************************************************************************************/
int g_iPaintCount = 0;
int g_iWeaponCount = 0;
int g_iMusicKitCount = 0;
int g_iGlovesCount = 0;
int g_iGlovesPaintCount = 0;
int g_iItemSetCount = 0;
int g_iSprayCount = 0;
int g_iLanguageDownloadAttempts = 0;
int g_iSchemaDownloadAttempts = 0;

#define CSGOItems_LoopWeapons(%1) for(int %1 = 0; %1 < g_iWeaponCount; %1++)
#define CSGOItems_LoopSkins(%1) for(int %1 = 0; %1 < g_iPaintCount; %1++)
#define CSGOItems_LoopGloves(%1) for(int %1 = 0; %1 < g_iGlovesCount; %1++)
#define CSGOItems_LoopSprays(%1) for(int %1 = 0; %1 < g_iSprayCount; %1++)
#define CSGOItems_LoopMusicKits(%1) for(int %1 = 0; %1 < g_iMusicKitCount; %1++)
#define CSGOItems_LoopItemSets(%1) for(int %1 = 0; %1 < g_iItemSetCount; %1++)
#define CSGOItems_LoopWeaponSlots(%1) for(int %1 = 0; %1 < 6; %1++)
#define CSGOItems_LoopValidWeapons(%1) for(int %1 = MaxClients; %1 < 2048; %1++) if(IsValidWeapon(%1))
#define CSGOItems_LoopValidClients(%1) for(int %1 = 1; %1 < MaxClients; %1++) if(IsValidClient(%1))

public void OnPluginStart()
{
	if (GetEngineVersion() != Engine_CSGO) {
		Call_StartForward(g_hOnPluginEnd);
		Call_Finish();
		SetFailState("This plugin is for CSGO only.");
	}
	
	/****************************************************************************************************
											--FORWARDS--
	*****************************************************************************************************/
	g_hOnItemsSynced = CreateGlobalForward("CSGOItems_OnItemsSynced", ET_Ignore);
	g_hOnPluginEnd = CreateGlobalForward("CSGOItems_OnPluginEnd", ET_Ignore);
	g_hOnWeaponGiven = CreateGlobalForward("CSGOItems_OnWeaponGiven", ET_Ignore, Param_Cell, Param_Cell, Param_String, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
	
	Handle hConfig = LoadGameConfigFile("sdkhooks.games");
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hConfig, SDKConf_Virtual, "Weapon_Switch");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	
	g_hSwitchWeaponCall = EndPrepSDKCall();
	
	delete hConfig;
	
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("round_poststart", OnRoundStart);
	HookEvent("cs_pre_restart", OnRoundEnd);
	
	AutoExecConfig_SetFile("plugin.csgoitems");
	g_hCvarSpraysEnabled = AutoExecConfig_CreateConVar("csgoitems_spraysenabled", "0", "Should CSGO Items add support for sprays / make clients download them?");
	g_hCvarSpraysEnabled.AddChangeHook(OnCvarChanged);
	AutoExecConfig_CleanFile(); AutoExecConfig_ExecuteFile();
	
	AddNormalSoundHook(OnNormalSoundPlayed);
	FindAndHookHibernation();

	RetrieveLanguage();
}

public void OnCvarChanged(ConVar hConVar, const char[] szOldValue, const char[] szNewValue)
{
	if (hConVar == g_hCvarSpraysEnabled) {
		g_bSpraysEnabled = view_as<bool>(StringToInt(szNewValue));
	} else if (hConVar == g_hCvarHibernation && view_as<bool>(StringToInt(szNewValue)) && !g_bItemsSynced) {
		g_hCvarHibernation.BoolValue = false;
		g_bHibernation = true;
	}
}

public void OnPluginEnd()
{
	Call_StartForward(g_hOnPluginEnd);
	Call_Finish();
}

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] szError, int iErrMax)
{
	/****************************************************************************************************
											--GENERAL NATIVES--
	*****************************************************************************************************/
	
	// Item Counts
	CreateNative("CSGOItems_GetWeaponCount", Native_GetWeaponCount);
	CreateNative("CSGOItems_GetSkinCount", Native_GetSkinCount);
	CreateNative("CSGOItems_GetGlovesCount", Native_GetGlovesCount);
	CreateNative("CSGOItems_GetSprayCount", Native_GetSprayCount);
	CreateNative("CSGOItems_GetGlovesPaintCount", Native_GetGlovesPaintCount);
	CreateNative("CSGOItems_GetMusicKitCount", Native_GetMusicKitCount);
	CreateNative("CSGOItems_GetItemSetCount", Native_GetItemSetCount);
	CreateNative("CSGOItems_AreItemsSynced", Native_AreItemsSynced);
	CreateNative("CSGOItems_AreItemsSyncing", Native_AreItemsSyncing);
	CreateNative("CSGOItems_ReSync", Native_Resync);
	CreateNative("CSGOItems_GetActiveWeaponCount", Native_GetActiveWeaponCount);
	
	/****************************************************************************************************
											--WEAPON NATIVES--
	*****************************************************************************************************/
	
	// Weapon Numbers
	CreateNative("CSGOItems_GetWeaponNumByDefIndex", Native_GetWeaponNumByDefIndex);
	CreateNative("CSGOItems_GetWeaponNumByClassName", Native_GetWeaponNumByClassName);
	CreateNative("CSGOItems_GetWeaponNumByWeapon", Native_GetWeaponNumByWeapon);
	
	// Weapon Definition Indexes
	CreateNative("CSGOItems_GetWeaponDefIndexByWeaponNum", Native_GetWeaponDefIndexByWeaponNum);
	CreateNative("CSGOItems_GetWeaponDefIndexByClassName", Native_GetWeaponDefIndexByClassName);
	CreateNative("CSGOItems_GetWeaponDefIndexByWeapon", Native_GetWeaponDefIndexByWeapon);
	
	// Weapon Class Names
	CreateNative("CSGOItems_GetWeaponClassNameByWeaponNum", Native_GetWeaponClassNameByWeaponNum);
	CreateNative("CSGOItems_GetWeaponClassNameByDefIndex", Native_GetWeaponClassNameByDefIndex);
	CreateNative("CSGOItems_GetWeaponClassNameByWeapon", Native_GetWeaponClassNameByWeapon);
	
	// Weapon Display Names
	CreateNative("CSGOItems_GetWeaponDisplayNameByDefIndex", Native_GetWeaponDisplayNameByDefIndex);
	CreateNative("CSGOItems_GetWeaponDisplayNameByClassName", Native_GetWeaponDisplayNameByClassName);
	CreateNative("CSGOItems_GetWeaponDisplayNameByWeaponNum", Native_GetWeaponDisplayNameByWeaponNum);
	CreateNative("CSGOItems_GetWeaponDisplayNameByWeapon", Native_GetWeaponDisplayNameByWeapon);
	
	// Weapon Models
	CreateNative("CSGOItems_GetWeaponViewModelByWeaponNum", Native_GetWeaponViewModelByWeaponNum);
	CreateNative("CSGOItems_GetWeaponViewModelByDefIndex", Native_GetWeaponViewModelByDefIndex);
	CreateNative("CSGOItems_GetWeaponViewModelByClassName", Native_GetWeaponViewModelByClassName);
	CreateNative("CSGOItems_GetWeaponViewModelByWeapon", Native_GetWeaponViewModelByWeapon);
	
	CreateNative("CSGOItems_GetWeaponWorldModelByWeaponNum", Native_GetWeaponWorldModelByWeaponNum);
	CreateNative("CSGOItems_GetWeaponWorldModelByDefIndex", Native_GetWeaponWorldModelByDefIndex);
	CreateNative("CSGOItems_GetWeaponWorldModelByClassName", Native_GetWeaponWorldModelByClassName);
	CreateNative("CSGOItems_GetWeaponWorldModelByWeapon", Native_GetWeaponWorldModelByWeapon);
	
	// Weapon Teams
	CreateNative("CSGOItems_GetWeaponTeamByDefIndex", Native_GetWeaponTeamByDefIndex);
	CreateNative("CSGOItems_GetWeaponTeamByClassName", Native_GetWeaponTeamByClassName);
	CreateNative("CSGOItems_GetWeaponTeamByWeaponNum", Native_GetWeaponTeamByWeaponNum);
	CreateNative("CSGOItems_GetWeaponTeamByWeapon", Native_GetWeaponTeamByWeapon);
	
	// Weapon Slots
	CreateNative("CSGOItems_GetWeaponSlotByWeaponNum", Native_GetWeaponSlotByWeaponNum);
	CreateNative("CSGOItems_GetWeaponSlotByClassName", Native_GetWeaponSlotByClassName);
	CreateNative("CSGOItems_GetWeaponSlotByDefIndex", Native_GetWeaponSlotByDefIndex);
	CreateNative("CSGOItems_GetWeaponSlotByWeapon", Native_GetWeaponSlotByWeapon);
	
	// Weapon Ammo
	CreateNative("CSGOItems_GetWeaponClipAmmoByDefIndex", Native_GetWeaponClipAmmoByDefIndex);
	CreateNative("CSGOItems_GetWeaponClipAmmoByClassName", Native_GetWeaponClipAmmoByClassName);
	CreateNative("CSGOItems_GetWeaponClipAmmoByWeaponNum", Native_GetWeaponClipAmmoByWeaponNum);
	CreateNative("CSGOItems_GetWeaponClipAmmoByWeapon", Native_GetWeaponClipAmmoByWeapon);
	CreateNative("CSGOItems_GetWeaponReserveAmmoByDefIndex", Native_GetWeaponReserveAmmoByDefIndex);
	CreateNative("CSGOItems_GetWeaponReserveAmmoByClassName", Native_GetWeaponReserveAmmoByClassName);
	CreateNative("CSGOItems_GetWeaponReserveAmmoByWeaponNum", Native_GetWeaponReserveAmmoByWeaponNum);
	CreateNative("CSGOItems_GetWeaponReserveAmmoByWeapon", Native_GetWeaponReserveAmmoByWeapon);
	CreateNative("CSGOItems_SetWeaponAmmo", Native_SetWeaponAmmo);
	CreateNative("CSGOItems_SetAllWeaponsAmmo", Native_SetAllWeaponsAmmo);
	CreateNative("CSGOItems_RefillClipAmmo", Native_RefillClipAmmo);
	CreateNative("CSGOItems_RefillReserveAmmo", Native_RefillReserveAmmo);
	
	// Weapon Cash
	CreateNative("CSGOItems_GetWeaponKillAwardByDefIndex", Native_GetWeaponKillAwardByDefIndex);
	CreateNative("CSGOItems_GetWeaponKillAwardByClassName", Native_GetWeaponKillAwardByClassName);
	CreateNative("CSGOItems_GetWeaponKillAwardByWeaponNum", Native_GetWeaponKillAwardByWeaponNum);
	CreateNative("CSGOItems_GetWeaponKillAwardByWeapon", Native_GetWeaponKillAwardByWeapon);
	
	// Weapon Spread
	CreateNative("CSGOItems_GetWeaponSpreadByDefIndex", Native_GetWeaponSpreadByDefIndex);
	CreateNative("CSGOItems_GetWeaponSpreadByClassName", Native_GetWeaponSpreadByClassName);
	CreateNative("CSGOItems_GetWeaponSpreadByWeaponNum", Native_GetWeaponSpreadByWeaponNum);
	CreateNative("CSGOItems_GetWeaponSpreadByWeapon", Native_GetWeaponSpreadByWeapon);
	
	// Weapon Cycle Time
	CreateNative("CSGOItems_GetWeaponCycleTimeByDefIndex", Native_GetWeaponCycleTimeByDefIndex);
	CreateNative("CSGOItems_GetWeaponCycleTimeByClassName", Native_GetWeaponCycleTimeByClassName);
	CreateNative("CSGOItems_GetWeaponCycleTimeByWeaponNum", Native_GetWeaponCycleTimeByWeaponNum);
	CreateNative("CSGOItems_GetWeaponCycleTimeByWeapon", Native_GetWeaponCycleTimeByWeapon);
	
	// Misc
	CreateNative("CSGOItems_IsDefIndexKnife", Native_IsDefIndexKnife);
	CreateNative("CSGOItems_GetActiveClassName", Native_GetActiveClassName);
	CreateNative("CSGOItems_GetActiveWeaponDefIndex", Native_GetActiveWeaponDefIndex);
	CreateNative("CSGOItems_GetActiveWeaponNum", Native_GetActiveWeaponNum);
	CreateNative("CSGOItems_GetActiveWeapon", Native_GetActiveWeapon);
	CreateNative("CSGOItems_FindWeaponByClassName", Native_FindWeaponByClassName);
	CreateNative("CSGOItems_FindWeaponByWeaponNum", Native_FindWeaponByWeaponNum);
	CreateNative("CSGOItems_FindWeaponByDefIndex", Native_FindWeaponByDefIndex);
	CreateNative("CSGOItems_IsValidWeapon", Native_IsValidWeapon);
	CreateNative("CSGOItems_GiveWeapon", Native_GiveWeapon);
	CreateNative("CSGOItems_RespawnWeapon", Native_RespawnWeapon);
	CreateNative("CSGOItems_RespawnWeaponBySlot", Native_RespawnWeaponBySlot);
	CreateNative("CSGOItems_RemoveWeapon", Native_RemoveWeapon);
	CreateNative("CSGOItems_DropWeapon", Native_DropWeapon);
	CreateNative("CSGOItems_RemoveAllWeapons", Native_RemoveAllWeapons);
	CreateNative("CSGOItems_RemoveKnife", Native_RemoveKnife);
	CreateNative("CSGOItems_SetActiveWeapon", Native_SetActiveWeapon);
	CreateNative("CSGOItems_GetActiveWeaponSlot", Native_GetActiveWeaponSlot);
	
	/****************************************************************************************************
											--SKIN NATIVES--
	*****************************************************************************************************/
	// Skin Numbers
	CreateNative("CSGOItems_GetSkinNumByDefIndex", Native_GetSkinNumByDefIndex);
	
	// Skin Definition Indexes
	CreateNative("CSGOItems_GetSkinDefIndexBySkinNum", Native_GetSkinDefIndexBySkinNum);
	
	// Skin Display Names
	CreateNative("CSGOItems_GetSkinDisplayNameByDefIndex", Native_GetSkinDisplayNameByDefIndex);
	CreateNative("CSGOItems_GetSkinDisplayNameBySkinNum", Native_GetSkinDisplayNameBySkinNum);
	
	// Misc
	CreateNative("CSGOItems_IsSkinnableDefIndex", Native_IsSkinnableDefIndex);
	CreateNative("CSGOItems_IsSkinNumGloveApplicable", Native_IsSkinNumGloveApplicable);
	CreateNative("CSGOItems_GetRandomSkin", Native_GetRandomSkin);
	CreateNative("CSGOItems_GetSkinVmtPathBySkinNum", Native_GetSkinVmtPathBySkinNum);
	CreateNative("CSGOItems_IsNativeSkin", Native_IsNativeSkin);
	CreateNative("CSGOItems_GetWeaponNumBySkinNum", Native_GetWeaponNumBySkinNum);
	
	
	/****************************************************************************************************
											--MUSIC KIT NATIVES--
	*****************************************************************************************************/
	
	// Music Kit Numbers
	CreateNative("CSGOItems_GetMusicKitNumByDefIndex", Native_GetMusicKitNumByDefIndex);
	
	// Music Kit Definition Indexes
	CreateNative("CSGOItems_GetMusicKitDefIndexByMusicKitNum", Native_GetMusicKitDefIndexByMusicKitNum);
	
	// Music Kit Display Names
	CreateNative("CSGOItems_GetMusicKitDisplayNameByDefIndex", Native_GetMusicKitDisplayNameByDefIndex);
	CreateNative("CSGOItems_GetMusicKitDisplayNameByWeaponNum", Native_GetMusicKitDisplayNameByMusicKitNum);
	
	/****************************************************************************************************
											--ITEM SET NATIVES--
	*****************************************************************************************************/
	
	// Item Set Numbers
	CreateNative("CSGOItems_GetItemSetNumByClassName", Native_GetItemSetNumByClassName);
	
	// Set Names
	CreateNative("CSGOItems_GetItemSetDisplayNameByClassName", Native_GetItemSetDisplayNameByClassName);
	CreateNative("CSGOItems_GetItemSetDisplayNameByItemSetNum", Native_GetItemSetDisplayNameByItemSetNum);
	
	/****************************************************************************************************
											--GLOVES NATIVES--
	*****************************************************************************************************/
	
	// Gloves Numbers
	CreateNative("CSGOItems_GetGlovesNumByDefIndex", Native_GetGlovesNumByDefIndex);
	CreateNative("CSGOItems_GetGlovesNumByClassName", Native_GetGlovesNumByClassName);
	
	// Gloves Definition Indexes
	CreateNative("CSGOItems_GetGlovesDefIndexByGlovesNum", Native_GetGlovesDefIndexByGlovesNum);
	
	// Gloves Display Names
	CreateNative("CSGOItems_GetGlovesDisplayNameByDefIndex", Native_GetGlovesDisplayNameByDefIndex);
	CreateNative("CSGOItems_GetGlovesDisplayNameByGlovesNum", Native_GetGlovesDisplayNameByGlovesNum);
	
	// Gloves Models
	CreateNative("CSGOItems_GetGlovesViewModelByGlovesNum", Native_GetGlovesViewModelByGlovesNum);
	CreateNative("CSGOItems_GetGlovesViewModelByDefIndex", Native_GetGlovesViewModelByDefIndex);
	
	CreateNative("CSGOItems_GetGlovesWorldModelByGlovesNum", Native_GetGlovesWorldModelByGlovesNum);
	CreateNative("CSGOItems_GetGlovesWorldModelByDefIndex", Native_GetGlovesWorldModelByDefIndex);
	CreateNative("CSGOItems_GetGlovesNumBySkinNum", Native_GetGlovesNumBySkinNum);
	
	/****************************************************************************************************
											--SPRAY NATIVES--
	*****************************************************************************************************/
	
	// Spray Numbers
	CreateNative("CSGOItems_GetSprayNumByDefIndex", Native_GetSprayNumByDefIndex);
	
	// Spray Indexes
	CreateNative("CSGOItems_GetSprayDefIndexBySprayNum", Native_GetSprayDefIndexBySprayNum);
	
	// Spray Display Names
	CreateNative("CSGOItems_GetSprayDisplayNameByDefIndex", Native_GetSprayDisplayNameByDefIndex);
	CreateNative("CSGOItems_GetSprayDisplayNameBySprayNum", Native_GetSprayDisplayNameBySprayNum);
	
	// Spray Textures
	CreateNative("CSGOItems_GetSprayVMTBySprayNum", Native_GetSprayVMTBySprayNum);
	CreateNative("CSGOItems_GetSprayVMTByDefIndex", Native_GetSprayVMTByDefIndex);
	
	CreateNative("CSGOItems_GetSprayVTFBySprayNum", Native_GetSprayVTFBySprayNum);
	CreateNative("CSGOItems_GetSprayVTFByDefIndex", Native_GetSprayVTFByDefIndex);
	
	CreateNative("CSGOItems_GetSprayCacheIndexBySprayNum", Native_GetSprayCacheIndexBySprayNum);
	CreateNative("CSGOItems_GetSprayCacheIndexDefIndex", Native_GetSprayCacheIndexByDefIndex);
	
	RegPluginLibrary("CSGO_Items");
	
	return APLRes_Success;
}

public Action OnRoundStart(Handle hEvent, char[] szName, bool bDontBroadcast) { g_bRoundEnd = false; }
public Action OnRoundEnd(Handle hEvent, char[] szName, bool bDontBroadcast) { g_bRoundEnd = true; }

public void OnClientPutInServer(int iClient)
{
	SDKHook(iClient, SDKHook_WeaponEquip, OnWeaponEquip);
	SDKHook(iClient, SDKHook_WeaponEquipPost, OnWeaponEquipPost);
	SDKHook(iClient, SDKHook_WeaponDropPost, OnWeaponDropPost);
	
	for (int i = 0; i < 2048; i++) {
		g_bWeaponEquipped[iClient][i] = false;
	}
}

public void OnClientDisconnect(int iClient)
{
	for (int i = 0; i < 2048; i++) {
		g_bWeaponEquipped[iClient][i] = false;
	}
}

public void OnEntityDestroyed(int iEntity)
{
	if (iEntity < 0 || iEntity > 2048) {
		return;
	}
	
	for (int i = 1; i <= MaxClients; i++) {
		g_bWeaponEquipped[i][iEntity] = false;
	}
}

public Action OnWeaponEquip(int iClient, int iWeapon)
{
	if (g_bWeaponEquipped[iClient][iWeapon]) {
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public void OnWeaponEquipPost(int iClient, int iWeapon)
{
	g_bWeaponEquipped[iClient][iWeapon] = true;
	
	for (int i = 1; i <= MaxClients; i++) {
		if (i == iClient) {
			continue;
		}
		
		g_bWeaponEquipped[i][iWeapon] = false;
	}
}

public void OnWeaponDropPost(int iClient, int iWeapon)
{
	if (iClient < 1 || iClient > MaxClients) {
		return;
	}
	
	if (iWeapon < 0 || iWeapon > 2048) {
		iWeapon = EntRefToEntIndex(iWeapon);
	}
	
	if (!IsValidWeapon(iWeapon)) {
		return;
	}
	
	g_bWeaponEquipped[iClient][iWeapon] = false;
}

public bool RetrieveLanguage()
{
	FindAndHookHibernation();

	if (g_bItemsSyncing) {
		return false;
	}
	
	if (g_bRoundEnd) {
		CreateTimer(0.0, Timer_Wait1, _, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
		return true;
	}
	
	CreateTimer(0.2, Timer_SyncLanguage);
	
	return false;
}

public Action Timer_Wait1(Handle hTimer)
{
	if (g_bItemsSyncing) {
		return Plugin_Stop;
	}
	
	if (g_bRoundEnd) {
		return Plugin_Continue;
	}
	
	RetrieveLanguage();
	
	return Plugin_Stop;
}

public Action Timer_SyncLanguage(Handle hTimer)
{
	if (g_bRoundEnd) {
		return Plugin_Continue;
	}

	ConvertResourceFile("english");
	
	Handle hLanguageFile = OpenFile("resource/csgo_english.txt.utf8", "r");
	
	if (hLanguageFile != null) {
		ReadFileString(hLanguageFile, g_szLangPhrases, 21982192);
	}
	else {
		delete hLanguageFile;
		
		DeleteFile("resource/csgo_english.txt.utf8");
		
		if (g_iLanguageDownloadAttempts < 10) {
			RetrieveLanguage();
			return Plugin_Stop;
		} else {
			Call_StartForward(g_hOnPluginEnd);
			Call_Finish();
			SetFailState("UTF-8 language file is corrupted, failed after %d attempts.", g_iLanguageDownloadAttempts);
		}
	}
	
	delete hLanguageFile;
	
	g_iLanguageDownloadAttempts = 0;
	LogMessage("UTF-8 language file successfully processed, retrieving item schema.");
	
	RetrieveItemSchema();
	
	return Plugin_Stop;
}

public bool RetrieveItemSchema()
{
	if (g_bItemsSyncing) {
		return false;
	}
	
	if (g_bRoundEnd) {
		CreateTimer(0.0, Timer_Wait2, _, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
		return true;
	}
	
	CreateTimer(0.2, Timer_SyncSchema);
	
	return false;
}

public Action Timer_Wait2(Handle hTimer)
{
	if (g_bItemsSyncing) {
		return Plugin_Stop;
	}
	
	if (g_bRoundEnd) {
		return Plugin_Continue;
	}
	
	RetrieveItemSchema();
	
	return Plugin_Stop;
}

public Action Timer_SyncSchema(Handle hTimer)
{
	if (g_bRoundEnd) {
		return Plugin_Continue;
	}

	RebaseItemsGame();
	
	Handle hSchemaFile = OpenFile("scripts/items/items_game_dynamic.txt", "r");
	
	if (hSchemaFile != null) {
		ReadFileString(hSchemaFile, g_szSchemaPhrases, 21982192);
	} else {
		g_bItemsSyncing = false;
		
		delete hSchemaFile;
		
		DeleteFile("scripts/items/items_game_dynamic.txt");
		
		if (g_iSchemaDownloadAttempts < 10) {
			RetrieveItemSchema();
			return Plugin_Stop;
		} else {
			Call_StartForward(g_hOnPluginEnd);
			Call_Finish();
			SetFailState("Item schema is corrupted, failed after %d attempts.", g_iSchemaDownloadAttempts);
		}
	}
	
	delete hSchemaFile;
	
	g_iSchemaDownloadAttempts = 0;
	
	int iStart = GetTime();
	
	LogMessage("Item Schema successfully processed, syncing item data.");
	
	SyncItemData();
	
	int iEnd = GetTime();
	LogMessage("Item data synced in %d seconds.", iEnd - iStart);
	
	if (g_hCvarHibernation != null && g_bHibernation) {
		g_hCvarHibernation.BoolValue = true;
	}
	
	return Plugin_Stop;
}

public Action PK_ReadDynamicKeyValue(Dynamic obj, const char[] member, int depth)
{
	// Allow the basekey (depth=0) to be loaded
	if (depth == 0)
		return Plugin_Continue;
	
	// Check all subkeys (depth=1) within the basekey (depth=0)
	if (depth == 1)
	{
		// Allow these subkeys (depth=1) in the basekey (depth=0) to load
		if (StrEqual(member, "items"))
			return Plugin_Continue;
		if (StrEqual(member, "paint_kits"))
			return Plugin_Continue;
		if (StrEqual(member, "music_definitions"))
			return Plugin_Continue;
		if (StrEqual(member, "item_sets"))
			return Plugin_Continue;
		if (StrEqual(member, "sticker_kits"))
			return Plugin_Continue;
		if (StrEqual(member, "paint_kits_rarity"))
			return Plugin_Continue;
		if (StrEqual(member, "used_by_classes"))
			return Plugin_Continue;
		if (StrEqual(member, "attributes"))
			return Plugin_Continue;
		if (StrEqual(member, "prefabs"))
			return Plugin_Continue;

		else
		{
			// Block all other subkeys (depth=1)
			return Plugin_Stop;
		}
	}
	
	// Let all subkeys in higher depths load (depth>1)
	return Plugin_Continue;
}

public void SyncItemData()
{
	File hFile = OpenFile("scripts/items/items_game_cdn.txt", "r");
	
	int iCDNPhraseCount = 0;
	
	if (hFile != null) {
		char szBuffer[384];
		int iLen;
		
		while (hFile.ReadLine(szBuffer, sizeof(szBuffer))) {
			iLen = strlen(szBuffer);
			
			if (szBuffer[iLen - 1] == '\n') {
				szBuffer[--iLen] = '\0';
			}
			
			TrimString(szBuffer);
			SplitString(szBuffer, "=", szBuffer, sizeof(szBuffer));
			strcopy(g_szCDNPhrases[iCDNPhraseCount++], sizeof(g_szCDNPhrases[]), szBuffer);
			
			if (hFile.EndOfFile()) {
				break;
			}
		}
	}
	
	delete hFile;
	
	g_bItemsSyncing = true;
	g_iPaintCount = 0;
	g_iWeaponCount = 0;
	g_iMusicKitCount = 0;
	g_iGlovesCount = 0;
	g_iGlovesPaintCount = 0;
	g_iItemSetCount = 0;
	g_iSprayCount = 0;
	
	g_hItemsKv = CreateKeyValues("items_game");
	
	if (!FileToKeyValues(g_hItemsKv, "scripts/items/items_game_dynamic.txt")) {
		Call_StartForward(g_hOnPluginEnd);
		Call_Finish();
		SetFailState("Unable to Process Item Schema");
	} KvRewind(g_hItemsKv);
	
	if (!KvJumpToKey(g_hItemsKv, "items") || !KvGotoFirstSubKey(g_hItemsKv, false)) {
		Call_StartForward(g_hOnPluginEnd);
		Call_Finish();
		SetFailState("Unable to find Item keyvalues");
	}
	
	char szBuffer[256]; char szBuffer2[256]; char szBuffer3[192][192];
	int iDefIndex = 0;
	
	do {
		KvGetString(g_hItemsKv, "name", szBuffer2, sizeof(szBuffer2));
		KvGetString(g_hItemsKv, "prefab", szBuffer, sizeof(szBuffer));
		
		bool bGloves = StrEqual(szBuffer, "hands", false) || StrEqual(szBuffer, "hands_paintable", false);
		
		if (!IsValidWeaponClassName(szBuffer2) && !bGloves) {
			continue;
		}
		
		int iItemType = bGloves ? ITEMTYPE_GLOVES : ITEMTYPE_WEAPON;
		
		KvGetSectionName(g_hItemsKv, iItemType == ITEMTYPE_WEAPON ? g_szWeaponInfo[g_iWeaponCount][DEFINDEX] : g_szGlovesInfo[g_iGlovesCount][DEFINDEX], 192);
		strcopy(iItemType == ITEMTYPE_WEAPON ? g_szWeaponInfo[g_iWeaponCount][CLASSNAME] : g_szGlovesInfo[g_iGlovesCount][CLASSNAME], sizeof(szBuffer2), szBuffer2);
		
		char szItemName[192]; Prefaberator(iItemType, -1, -1, -1, -1.0, -1.0, szItemName);
		
		GetItemName(szItemName, iItemType == ITEMTYPE_WEAPON ? g_szWeaponInfo[g_iWeaponCount][DISPLAYNAME] : g_szGlovesInfo[g_iGlovesCount][DISPLAYNAME], 192);
		
		if (bGloves) {
			g_iGlovesCount++;
		} else {
			g_iWeaponCount++;
		}
		
	} while (KvGotoNextKey(g_hItemsKv)); KvRewind(g_hItemsKv);
	
	if (!KvJumpToKey(g_hItemsKv, "paint_kits") || !KvGotoFirstSubKey(g_hItemsKv, false)) {
		Call_StartForward(g_hOnPluginEnd);
		Call_Finish();
		SetFailState("Unable to find Paintkit keyvalues (KvJumpToKey: %d, KvGotoFirstSubKey: %d)", KvJumpToKey(g_hItemsKv, "paint_kits"), KvGotoFirstSubKey(g_hItemsKv, false));
	}
	
	do {
		KvGetSectionName(g_hItemsKv, szBuffer, sizeof(szBuffer));
		int iSkinDefIndex = StringToInt(szBuffer);
		
		if (iSkinDefIndex == 9001) {
			strcopy(szBuffer, sizeof(szBuffer), "1");
			iSkinDefIndex = 1;
		}
		
		strcopy(g_szPaintInfo[g_iPaintCount][DEFINDEX], sizeof(szBuffer), szBuffer);
		
		if (iSkinDefIndex == 0) {
			strcopy(g_szPaintInfo[g_iPaintCount][DISPLAYNAME], 192, "Default");
		} else if (iSkinDefIndex == 1) {
			strcopy(g_szPaintInfo[g_iPaintCount][DISPLAYNAME], 192, "Vanilla");
		} else {
			KvGetString(g_hItemsKv, "name", g_szPaintInfo[g_iPaintCount][ITEMNAME], 192);
			KvGetString(g_hItemsKv, "description_tag", szBuffer, sizeof(szBuffer));
			
			GetItemName(szBuffer, g_szPaintInfo[g_iPaintCount][DISPLAYNAME], 192);
		}
		
		KvGetString(g_hItemsKv, "vmt_path", g_szPaintInfo[g_iPaintCount][VMTPATH], 192);
		
		g_bSkinNumGloveApplicable[g_iPaintCount] = StrContains(g_szPaintInfo[g_iPaintCount][VMTPATH], "paints_gloves", false) > -1;
		
		CSGOItems_LoopWeapons(iWeaponNum) {
			if (g_bIsNativeSkin[ITEMTYPE_WEAPON][g_iPaintCount][iWeaponNum]) {
				break;
			}
			
			if (!GetWeaponClassNameByWeaponNum(iWeaponNum, szBuffer2, sizeof(szBuffer2))) {
				continue;
			}
			
			iDefIndex = GetWeaponDefIndexByClassName(szBuffer2);
			
			if (!IsSkinnableDefIndex(iDefIndex)) {
				continue;
			}
			
			FormatEx(szBuffer, sizeof(szBuffer), "%s_%s", szBuffer2, g_szPaintInfo[g_iPaintCount][ITEMNAME]);
			
			for (int i = 0; i < iCDNPhraseCount; i++) {
				if (g_bIsNativeSkin[ITEMTYPE_WEAPON][g_iPaintCount][iWeaponNum]) {
					break;
				}
				
				g_bIsNativeSkin[ITEMTYPE_WEAPON][g_iPaintCount][iWeaponNum] = StrEqual(g_szCDNPhrases[i], szBuffer, false);
				
				if (g_bIsNativeSkin[ITEMTYPE_WEAPON][g_iPaintCount][iWeaponNum]) {
					break;
				}
			}
		}
		
		CSGOItems_LoopGloves(iGlovesNum) {
			if (g_bIsNativeSkin[ITEMTYPE_GLOVES][g_iPaintCount][iGlovesNum]) {
				break;
			}
			
			FormatEx(szBuffer, sizeof(szBuffer), "%s_%s", g_szGlovesInfo[iGlovesNum][CLASSNAME], g_szPaintInfo[g_iPaintCount][ITEMNAME]);
			
			for (int i = 0; i < iCDNPhraseCount; i++) {
				if (g_bIsNativeSkin[ITEMTYPE_GLOVES][g_iPaintCount][iGlovesNum]) {
					break;
				}
				
				g_bIsNativeSkin[ITEMTYPE_GLOVES][g_iPaintCount][iGlovesNum] = StrEqual(g_szCDNPhrases[i], szBuffer, false);
				
				if (g_bIsNativeSkin[ITEMTYPE_GLOVES][g_iPaintCount][iGlovesNum]) {
					break;
				}
			}
		}
		
		if (g_bSkinNumGloveApplicable[g_iPaintCount]) {
			g_iGlovesPaintCount++;
		}
		
		g_iPaintCount++;
		
	} while (KvGotoNextKey(g_hItemsKv)); KvRewind(g_hItemsKv);
	
	if (!KvJumpToKey(g_hItemsKv, "music_definitions") || !KvGotoFirstSubKey(g_hItemsKv, false)) {
		Call_StartForward(g_hOnPluginEnd);
		Call_Finish();
		SetFailState("Unable to find Music Kit keyvalues");
	}
	
	do {
		KvGetSectionName(g_hItemsKv, szBuffer, sizeof(szBuffer));
		int iMusicDefIndex = StringToInt(szBuffer);
		
		if (iMusicDefIndex < 3) {
			continue;
		}
		
		strcopy(g_szMusicKitInfo[g_iMusicKitCount][DEFINDEX], 192, szBuffer);
		KvGetString(g_hItemsKv, "loc_name", szBuffer2, sizeof(szBuffer2));
		GetItemName(szBuffer2, g_szMusicKitInfo[g_iMusicKitCount][DISPLAYNAME], 192);
		
		g_iMusicKitCount++;
	} while (KvGotoNextKey(g_hItemsKv)); KvRewind(g_hItemsKv);
	
	if (!KvJumpToKey(g_hItemsKv, "item_sets") || !KvGotoFirstSubKey(g_hItemsKv, false)) {
		Call_StartForward(g_hOnPluginEnd);
		Call_Finish();
		SetFailState("Unable to find Item Sets keyvalues");
	}
	
	do {
		KvGetString(g_hItemsKv, "name", g_szItemSetInfo[g_iItemSetCount][CLASSNAME], 192);
		GetItemName(g_szItemSetInfo[g_iItemSetCount][CLASSNAME], g_szItemSetInfo[g_iItemSetCount][DISPLAYNAME], 192);
		
		if (KvJumpToKey(g_hItemsKv, "items")) {
			if (KvGotoFirstSubKey(g_hItemsKv, false)) {
				do {
					KvGetSectionName(g_hItemsKv, szBuffer, sizeof(szBuffer));
					ExplodeString(szBuffer, "]", szBuffer3, 192, 192); ReplaceString(szBuffer3[0], 192, "[", ""); ReplaceString(szBuffer3[1], 192, "]", "");
					
					CSGOItems_LoopSkins(iSkinNum) {
						if (StrEqual(szBuffer3[0], g_szPaintInfo[iSkinNum][ITEMNAME])) {
							g_bIsSkinInSet[g_iItemSetCount][iSkinNum] = true;
						}
					}
				}
				while (KvGotoNextKey(g_hItemsKv, false));
				KvGoBack(g_hItemsKv);
			}
		}
		KvGoBack(g_hItemsKv);
		g_iItemSetCount++;
	} while (KvGotoNextKey(g_hItemsKv)); KvRewind(g_hItemsKv);
	
	if (!KvJumpToKey(g_hItemsKv, "sticker_kits") || !KvGotoFirstSubKey(g_hItemsKv, false)) {
		Call_StartForward(g_hOnPluginEnd);
		Call_Finish();
		SetFailState("Unable to find Stickerkit keyvalues");
	}
	
	do {
		KvGetString(g_hItemsKv, "name", szBuffer, sizeof(szBuffer));
		
		if (StrContains(szBuffer, "spray", false) < 0) {
			continue;
		}
		
		KvGetString(g_hItemsKv, "sticker_material", szBuffer, sizeof(szBuffer));
		
		FormatEx(g_szSprayInfo[g_iSprayCount][VTFPATH], PLATFORM_MAX_PATH, "decals/sprays/%s.vtf", szBuffer);
		
		KvGetString(g_hItemsKv, "item_name", szBuffer2, sizeof(szBuffer2));
		
		if (StrEqual(szBuffer2, "#StickerKit_comm01_rekt", false)) {
			strcopy(g_szSprayInfo[g_iSprayCount][DISPLAYNAME], 192, "Rekt");
		} else {
			GetItemName(szBuffer2, g_szSprayInfo[g_iSprayCount][DISPLAYNAME], 192);
		}
		
		KvGetSectionName(g_hItemsKv, szBuffer2, sizeof(szBuffer2));
		strcopy(g_szSprayInfo[g_iSprayCount][DEFINDEX], 192, szBuffer2);
		
		char szExplode[2][64]; ExplodeString(szBuffer, "/", szExplode, 2, 64);
		
		CreateSprayVMT(g_iSprayCount, szExplode[0], szExplode[1], g_szSprayInfo[g_iSprayCount][VTFPATH]);
		
		g_iSprayCount++;
		
	} while (KvGotoNextKey(g_hItemsKv)); KvRewind(g_hItemsKv);
	
	if (!KvJumpToKey(g_hItemsKv, "paint_kits_rarity")) {
		Call_StartForward(g_hOnPluginEnd);
		Call_Finish();
		SetFailState("Unable to find Paint rarity keyvalues");
	}
	
	do {
		CSGOItems_LoopSkins(iSkinNum) {
			KvGetString(g_hItemsKv, g_szPaintInfo[iSkinNum][ITEMNAME], g_szPaintInfo[iSkinNum][RARITY], 192);
		}
	} while (KvGotoNextKey(g_hItemsKv)); delete g_hItemsKv;
	
	Call_StartForward(g_hOnItemsSynced);
	Call_Finish();
	
	g_bItemsSynced = true;
	g_bItemsSyncing = false;
}

stock void Prefaberator(int iItemType, int iClipAmmo, int iReserveAmmo, int iKillAward, float fSpread, float fCycleTime, char szItemName[192])
{
	char szPrefab[192]; KvGetString(g_hItemsKv, "prefab", szPrefab, sizeof(szPrefab));
	
	if (iItemType == ITEMTYPE_GLOVES && StrEqual(g_szGlovesInfo[g_iGlovesCount][TYPE], "", false)) {
		strcopy(g_szGlovesInfo[g_iGlovesCount][TYPE], 192, szPrefab);
	} else if (iItemType == ITEMTYPE_WEAPON && StrEqual(g_szWeaponInfo[g_iWeaponCount][TYPE], "", false)) {
		strcopy(g_szWeaponInfo[g_iWeaponCount][TYPE], 192, szPrefab);
	}
	
	if (StrEqual(szItemName, "", false)) {
		KvGetString(g_hItemsKv, "item_name", szItemName, sizeof(szItemName));
	}
	
	if (iItemType == ITEMTYPE_GLOVES && StrEqual(g_szGlovesInfo[g_iGlovesCount][VIEWMODEL], "", false)) {
		KvGetString(g_hItemsKv, "model_player", g_szGlovesInfo[g_iGlovesCount][VIEWMODEL], PLATFORM_MAX_PATH);
	} else if (iItemType == ITEMTYPE_WEAPON && StrEqual(g_szWeaponInfo[g_iWeaponCount][VIEWMODEL], "", false)) {
		KvGetString(g_hItemsKv, "model_player", g_szWeaponInfo[g_iWeaponCount][VIEWMODEL], PLATFORM_MAX_PATH);
	}
	
	if (iItemType == ITEMTYPE_GLOVES && StrEqual(g_szGlovesInfo[g_iGlovesCount][WORLDMODEL], "", false)) {
		KvGetString(g_hItemsKv, "model_world", g_szGlovesInfo[g_iGlovesCount][WORLDMODEL], PLATFORM_MAX_PATH);
	} else if (iItemType == ITEMTYPE_WEAPON && StrEqual(g_szWeaponInfo[g_iWeaponCount][WORLDMODEL], "", false)) {
		KvGetString(g_hItemsKv, "model_world", g_szWeaponInfo[g_iWeaponCount][WORLDMODEL], PLATFORM_MAX_PATH);
	}
	
	if (iItemType == ITEMTYPE_GLOVES && StrEqual(g_szGlovesInfo[g_iGlovesCount][RARITY], "", false)) {
		KvGetString(g_hItemsKv, "item_rarity", g_szGlovesInfo[g_iGlovesCount][RARITY], PLATFORM_MAX_PATH);
	} else if (iItemType == ITEMTYPE_WEAPON && StrEqual(g_szWeaponInfo[g_iWeaponCount][RARITY], "", false)) {
		KvGetString(g_hItemsKv, "item_rarity", g_szWeaponInfo[g_iWeaponCount][RARITY], PLATFORM_MAX_PATH);
	}
	
	if (iItemType == ITEMTYPE_GLOVES && StrEqual(g_szGlovesInfo[g_iGlovesCount][QUALITY], "", false)) {
		KvGetString(g_hItemsKv, "item_quality", g_szGlovesInfo[g_iGlovesCount][QUALITY], PLATFORM_MAX_PATH);
	} else if (iItemType == ITEMTYPE_WEAPON && StrEqual(g_szWeaponInfo[g_iWeaponCount][QUALITY], "", false)) {
		KvGetString(g_hItemsKv, "item_quality", g_szWeaponInfo[g_iWeaponCount][QUALITY], PLATFORM_MAX_PATH);
	}
	
	if (iItemType == ITEMTYPE_GLOVES && StrEqual(g_szGlovesInfo[g_iGlovesCount][SLOT], "", false)) {
		KvGetString(g_hItemsKv, "item_slot", g_szGlovesInfo[g_iGlovesCount][SLOT], PLATFORM_MAX_PATH);
	} else if (iItemType == ITEMTYPE_WEAPON && StrEqual(g_szWeaponInfo[g_iWeaponCount][SLOT], "", false)) {
		KvGetString(g_hItemsKv, "item_slot", g_szWeaponInfo[g_iWeaponCount][SLOT], PLATFORM_MAX_PATH);
	}
	
	if (iItemType == ITEMTYPE_WEAPON && !g_bIsDefIndexSkinnable[StringToInt(g_szWeaponInfo[g_iWeaponCount][DEFINDEX])] && KvJumpToKey(g_hItemsKv, "capabilities")) {
		g_bIsDefIndexSkinnable[StringToInt(g_szWeaponInfo[g_iWeaponCount][DEFINDEX])] = KvGetBool(g_hItemsKv, "paintable");
		
		KvGoBack(g_hItemsKv);
	}
	
	if (iItemType == ITEMTYPE_WEAPON && !g_bIsDefIndexKnife[StringToInt(g_szWeaponInfo[g_iWeaponCount][DEFINDEX])]) {
		g_bIsDefIndexKnife[StringToInt(g_szWeaponInfo[g_iWeaponCount][DEFINDEX])] = StrContains(szPrefab, "melee", false) != -1;
	}
	
	if (KvJumpToKey(g_hItemsKv, "used_by_classes")) {
		if ((iItemType == ITEMTYPE_GLOVES && StrEqual(g_szGlovesInfo[g_iGlovesCount][TEAM], "", false)) || (iItemType == ITEMTYPE_WEAPON && StrEqual(g_szWeaponInfo[g_iWeaponCount][TEAM], "", false))) {
			bool bTerrorist = KvGetBool(g_hItemsKv, "terrorists");
			bool bCounterTerrorist = KvGetBool(g_hItemsKv, "counter-terrorists");
			bool bBothTeams = bTerrorist && bCounterTerrorist;
			
			if (bBothTeams) {
				if (iItemType == ITEMTYPE_GLOVES) {
					g_szGlovesInfo[g_iGlovesCount][TEAM] = "0";
				} else if (iItemType == ITEMTYPE_WEAPON) {
					g_szWeaponInfo[g_iWeaponCount][TEAM] = "0";
				}
			}
			
			else if (bTerrorist) {
				if (iItemType == ITEMTYPE_GLOVES) {
					g_szGlovesInfo[g_iGlovesCount][TEAM] = "2";
				} else if (iItemType == ITEMTYPE_WEAPON) {
					g_szWeaponInfo[g_iWeaponCount][TEAM] = "2";
				}
			}
			
			else if (bCounterTerrorist) {
				if (iItemType == ITEMTYPE_GLOVES) {
					g_szGlovesInfo[g_iGlovesCount][TEAM] = "3";
				} else if (iItemType == ITEMTYPE_WEAPON) {
					g_szWeaponInfo[g_iWeaponCount][TEAM] = "3";
				}
			}
		}
		
		KvGoBack(g_hItemsKv);
	}
	
	if (iItemType == ITEMTYPE_WEAPON && KvJumpToKey(g_hItemsKv, "attributes")) {
		if (iClipAmmo == -1) {
			iClipAmmo = KvGetNum(g_hItemsKv, "primary clip size", -1);
		}
		
		if (iReserveAmmo == -1) {
			iReserveAmmo = KvGetNum(g_hItemsKv, "primary reserve ammo max", -1);
		}
		
		if (iKillAward == -1) {
			iKillAward = KvGetNum(g_hItemsKv, "kill award", -1);
		}
		
		if (fSpread == -1.0) {
			fSpread = KvGetFloat(g_hItemsKv, "spread", -1.0);
		}
		
		if (fCycleTime == -1.0) {
			fCycleTime = KvGetFloat(g_hItemsKv, "cycletime", -1.0);
		}
		
		KvGoBack(g_hItemsKv);
	}
	
	KvRewind(g_hItemsKv);
	
	if (StrEqual(szPrefab, "", false)) {
		if (iItemType == ITEMTYPE_WEAPON) {
			IntToString(iClipAmmo, g_szWeaponInfo[g_iWeaponCount][CLIPAMMO], 192);
			IntToString(iReserveAmmo, g_szWeaponInfo[g_iWeaponCount][RESERVEAMMO], 192);
			IntToString(iKillAward, g_szWeaponInfo[g_iWeaponCount][KILLAWARD], 192);
			
			FloatToString(fSpread, g_szWeaponInfo[g_iWeaponCount][SPREAD], 192);
			FloatToString(fCycleTime, g_szWeaponInfo[g_iWeaponCount][CYCLETIME], 192);
		}
		
		KvJumpToKey(g_hItemsKv, "items");
		
		if (iItemType == ITEMTYPE_WEAPON) {
			KvJumpToKey(g_hItemsKv, g_szWeaponInfo[g_iWeaponCount][DEFINDEX]);
		} else if (iItemType == ITEMTYPE_GLOVES) {
			KvJumpToKey(g_hItemsKv, g_szGlovesInfo[g_iGlovesCount][DEFINDEX]);
		}
		
	} else {
		KvJumpToKey(g_hItemsKv, "prefabs");
		KvJumpToKey(g_hItemsKv, szPrefab);
		
		Prefaberator(iItemType, iClipAmmo, iReserveAmmo, iKillAward, fSpread, fCycleTime, szItemName);
	}
}

stock bool CreateSprayVMT(int iSprayNum, const char[] szDirectory, const char[] szFile, const char[] szTexturePath)
{
	char szFullDirectory[PLATFORM_MAX_PATH]; FormatEx(szFullDirectory, PLATFORM_MAX_PATH, "materials/csgoitemsv2/sprays/%s", szDirectory);
	char szFullFile[PLATFORM_MAX_PATH]; FormatEx(szFullFile, PLATFORM_MAX_PATH, "%s/%s.vmt", szFullDirectory, szFile);
	char szPieces[32][PLATFORM_MAX_PATH];
	char szPath[PLATFORM_MAX_PATH];
	char szTexturePathFormat[128];
	//char szOutFile[PLATFORM_MAX_PATH];
	
	int iNumPieces = ExplodeString(szFullDirectory, "/", szPieces, sizeof(szPieces), sizeof(szPieces[]));
	
	for (int i = 0; i < iNumPieces; i++) {
		FormatEx(szPath, sizeof(szPath), "%s/%s", szPath, szPieces[i]);
		
		if (DirExists(szPath)) {
			continue;
		}
		
		CreateDirectory(szPath, FPERM_U_READ|FPERM_U_WRITE|FPERM_U_EXEC|FPERM_G_READ|FPERM_G_EXEC|FPERM_O_READ|FPERM_O_EXEC);
	}

	if (!FileExists(szFullFile)) {
		File fFile = OpenFile(szFullFile, "w");

		if (fFile == null) {
			return false;
		}

		FormatEx(szTexturePathFormat, 128, "\"$basetexture\"	\"%s\"", szTexturePath);
		ReplaceString(szTexturePathFormat, 128, ".vtf", "", false);
		
		fFile.WriteLine("LightmappedGeneric");
		fFile.WriteLine("{");
		fFile.WriteLine(szTexturePathFormat);
		fFile.WriteLine("	\"$translucent\" \"1\"");
		fFile.WriteLine("	\"$decal\" \"1\"");
		fFile.WriteLine("	\"$mappingwidth\" \"48\"");
		fFile.WriteLine("	\"$mappingheight\" \"48\"");
		fFile.WriteLine("}");

		/*
		FormatEx(szOutFile, PLATFORM_MAX_PATH, "%s.bz2", szFullFile);
		
		DataPack dPack = CreateDataPack();
		dPack.WriteString(szDirectory);
		dPack.Reset();
		
		BZ2_CompressFile(szFullFile, szOutFile, 9, Compressed_File);  
		*/
		delete fFile;
	}

	FormatEx(g_szSprayInfo[iSprayNum][VMTPATH], PLATFORM_MAX_PATH, szFullFile);
	
	return true;
}

/*
public int Compressed_File(BZ_Error iError, const char[] sIn, const char[] sOut, DataPack dPack) 
{
	dPack.Reset(); char szDirectory[PLATFORM_MAX_PATH]; dPack.ReadString(szDirectory, PLATFORM_MAX_PATH);
	delete dPack;
	
	if(iError == BZ_OK) {
		LogMessage("%s successfully compressed", sIn);
		EasyFTP_UploadFile("csgoitems", sOut, szDirectory, Uploaded_File);  
	} else {
		LogBZ2Error(iError);
	}
}

public int Uploaded_File(const char[] sTarget, const char[] sLocalFile, const char[] sRemoteFile, int iErrorCode, any data) 
{ 
    if(iErrorCode == 0) { 
        LogMessage("%s successfully uploaded", sLocalFile); 
    } else { 
        LogMessage("%s failed uploading", sLocalFile);   
    } 
}
*/

public void OnConfigsExecuted()
{
	g_bSpraysEnabled = g_hCvarSpraysEnabled.BoolValue;
	
	char szBuffer[10000];
	BuildPath(Path_SM, szBuffer, sizeof(szBuffer), "configs/core.cfg");
	
	File fFile = OpenFile(szBuffer, "r");
	
	if (fFile == null) {
		return;
	}
	
	while (fFile.ReadLine(szBuffer, sizeof(szBuffer))) {
		if (StrContains(szBuffer, "\"FollowCSGOServerGuidelines\"", false) < 0) {
			continue;
		}
		
		ReplaceString(szBuffer, sizeof(szBuffer), "\"FollowCSGOServerGuidelines\"", ""); TrimString(szBuffer); StripQuotes(szBuffer);
		g_bFollowGuidelines = StrContains(szBuffer, "yes", false) > -1;
		break;
	}
	
	delete fFile;
	
	FindAndHookHibernation();
}

public void OnMapStart()
{
	if (!g_bItemsSynced || g_bItemsSyncing) {
		return;
	}
	
	if (g_bSpraysEnabled) {
		CSGOItems_LoopSprays(iSprayNum) {
			AddFileToDownloadsTable(g_szSprayInfo[iSprayNum][VMTPATH]);
			
			char szBuffer[PLATFORM_MAX_PATH]; strcopy(szBuffer, PLATFORM_MAX_PATH, g_szSprayInfo[iSprayNum][VMTPATH]);
			
			ReplaceString(szBuffer, PLATFORM_MAX_PATH, "materials/", "", false);
			ReplaceString(szBuffer, PLATFORM_MAX_PATH, ".vmt", "", false);
			
			SafePrecacheDecal(szBuffer, true);
			PrecacheMaterial(szBuffer);
		}
	}
}

public void FindAndHookHibernation()
{
	if (g_hCvarHibernation == null) {
		g_hCvarHibernation = FindConVar("sv_hibernate_when_empty");
		
		if (g_hCvarHibernation != null) {
			g_hCvarHibernation.AddChangeHook(OnCvarChanged);
		}
	}
	
	if (g_hCvarHibernation == null) {
		return;
	}
	
	if (g_hCvarHibernation.BoolValue) {
		g_bHibernation = true;
		
		if (!g_bItemsSynced) {
			g_hCvarHibernation.BoolValue = false;
		}
	}
}

public Action Event_PlayerDeath(Handle hEvent, const char[] szName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	g_bGivingWeapon[iClient] = false;
	
	return Plugin_Continue;
}

stock void GetItemName(char[] szPhrase, char[] szBuffer, int iLength)
{
	int iPos = StrContains(g_szLangPhrases, szPhrase[1], false);
	
	if (iPos < 0) {
		strcopy(szBuffer, iLength, "");
		return;
	}
	
	int iLen = strlen(szPhrase);
	
	iPos += iLen + 1;
	iPos += StrContains(g_szLangPhrases[iPos], "\"") + 1;
	iLen = StrContains(g_szLangPhrases[iPos], "\"") + 1;
	
	strcopy(szBuffer, iLen, g_szLangPhrases[iPos]);
}

stock bool IsValidWeaponClassName(const char[] szClassName)
{
	if (!g_bItemsSynced || g_bItemsSyncing) {
		return StrContains(szClassName, "weapon_") > -1 && StrContains(szClassName, "base") < 0 && StrContains(szClassName, "case") < 0;
	}
	
	char szBuffer[48];
	
	CSGOItems_LoopWeapons(iWeaponNum) {
		if (!GetWeaponClassNameByWeaponNum(iWeaponNum, szBuffer, 48)) {
			continue;
		}
		
		if (!StrEqual(szClassName, szBuffer, false)) {
			continue;
		}
		
		return true;
	}
	
	return false;
}

stock bool IsSpecialPrefab(char[] szPrefabName) {
	return StrContains(szPrefabName, "_prefab") < 0;
}

stock bool GetClassNameFromIconPath(char[] szIconPath, char[] szReturn)
{
	Regex rRegex = CompileRegex("weapon(?:(?:_[^\\W_]+)+(?=_[^\\W_]{2}_)|(?:(?!_[^\\W_]{2}_)_[^\\W_]+)+)");
	
	if (rRegex.Match(szIconPath) < 1) {
		delete rRegex;
		return false;
	}
	
	if (!rRegex.GetSubString(0, szReturn, 48)) {
		delete rRegex;
		return false;
	}
	
	delete rRegex;
	
	return true;
}

stock bool IsValidClient(int iClient)
{
	if (iClient <= 0 || iClient > MaxClients) {
		return false;
	}
	
	return IsClientInGame(iClient);
}

stock int SlotNameToNum(const char[] szSlotName)
{
	if (StrContains(szSlotName, "rifle") > -1 || StrContains(szSlotName, "heavy") > -1 || StrContains(szSlotName, "smg") > -1) {
		return CS_SLOT_PRIMARY;
	}
	
	else if (StrContains(szSlotName, "secondary") > -1) {
		return CS_SLOT_SECONDARY;
	}
	
	else if (StrContains(szSlotName, "c4") > -1) {
		return CS_SLOT_C4;
	}
	
	else if (StrContains(szSlotName, "melee") > -1) {
		return CS_SLOT_KNIFE;
	}
	
	else if (StrContains(szSlotName, "grenade") > -1) {
		return CS_SLOT_GRENADE;
	}
	
	return -1;
}

stock bool KvGetBool(Handle hKv, const char[] szKey, bool bDefaultValue = false) {
	return view_as<bool>(KvGetNum(hKv, szKey, bDefaultValue ? 1 : 0));
}

public int Native_GetWeaponCount(Handle hPlugin, int iNumParams) {
	return g_iWeaponCount;
}

public int Native_GetSkinCount(Handle hPlugin, int iNumParams) {
	return g_iPaintCount;
}

public int Native_GetGlovesCount(Handle hPlugin, int iNumParams) {
	return g_iGlovesCount;
}

public int Native_GetSprayCount(Handle hPlugin, int iNumParams) {
	return g_iSprayCount;
}

public int Native_GetGlovesPaintCount(Handle hPlugin, int iNumParams) {
	return g_iGlovesPaintCount;
}

public int Native_GetMusicKitCount(Handle hPlugin, int iNumParams) {
	return g_iMusicKitCount;
}

public int Native_GetItemSetCount(Handle hPlugin, int iNumParams) {
	return g_iItemSetCount;
}

public int Native_GetWeaponNumByDefIndex(Handle hPlugin, int iNumParams)
{
	int iDefIndex = GetNativeCell(1);
	
	if (iDefIndex < 0 || iDefIndex > 700) {
		return -1;
	}
	
	return GetWeaponNumByDefIndex(iDefIndex);
}

stock int GetWeaponNumByDefIndex(int iDefIndex)
{
	if (iDefIndex < 0 || iDefIndex > 700) {
		return -1;
	}
	
	CSGOItems_LoopWeapons(iWeaponNum) {
		if (StringToInt(g_szWeaponInfo[iWeaponNum][DEFINDEX]) == iDefIndex) {
			return iWeaponNum;
		}
	}
	
	return -1;
}

public int Native_GetWeaponTeamByDefIndex(Handle hPlugin, int iNumParams)
{
	int iDefIndex = GetNativeCell(1);
	
	if (iDefIndex < 0 || iDefIndex > 700) {
		return -1;
	}
	
	CSGOItems_LoopWeapons(iWeaponNum) {
		if (StringToInt(g_szWeaponInfo[iWeaponNum][DEFINDEX]) == iDefIndex) {
			return StringToInt(g_szWeaponInfo[iWeaponNum][TEAM]);
		}
	}
	
	return -1;
}

public int Native_GetWeaponTeamByClassName(Handle hPlugin, int iNumParams)
{
	char szBuffer[48]; GetNativeString(1, szBuffer, 48);
	
	return GetWeaponTeamByClassName(szBuffer);
}

stock int GetWeaponTeamByClassName(const char[] szClassName)
{
	CSGOItems_LoopWeapons(iWeaponNum) {
		if (StrEqual(g_szWeaponInfo[iWeaponNum][CLASSNAME], szClassName, false)) {
			return StringToInt(g_szWeaponInfo[iWeaponNum][TEAM]);
		}
	}
	
	return -1;
}

public int Native_GetWeaponViewModelByWeaponNum(Handle hPlugin, int iNumParams)
{
	int iWeaponNum = GetNativeCell(1);
	
	if (iWeaponNum < 0 || iWeaponNum > g_iWeaponCount) {
		return false;
	}
	
	if (StrEqual(g_szWeaponInfo[iWeaponNum][VIEWMODEL], "", false)) {
		return false;
	}
	
	return SetNativeString(2, g_szWeaponInfo[iWeaponNum][VIEWMODEL], GetNativeCell(3)) == SP_ERROR_NONE;
}

public int Native_GetWeaponViewModelByWeapon(Handle hPlugin, int iNumParams)
{
	int iWeapon = GetNativeCell(1);
	int iWeaponNum = GetWeaponNumByWeapon(iWeapon);
	
	if (iWeaponNum < 0 || iWeaponNum > g_iWeaponCount) {
		return false;
	}
	
	if (StrEqual(g_szWeaponInfo[iWeaponNum][VIEWMODEL], "", false)) {
		return false;
	}
	
	return SetNativeString(2, g_szWeaponInfo[iWeaponNum][VIEWMODEL], GetNativeCell(3)) == SP_ERROR_NONE;
}

public int Native_GetWeaponViewModelByDefIndex(Handle hPlugin, int iNumParams)
{
	int iDefIndex = GetNativeCell(1);
	
	if (iDefIndex < 0 || iDefIndex > 700) {
		return false;
	}
	
	CSGOItems_LoopWeapons(iWeaponNum) {
		if (StringToInt(g_szWeaponInfo[iWeaponNum][DEFINDEX]) == iDefIndex) {
			
			if (StrEqual(g_szWeaponInfo[iWeaponNum][VIEWMODEL], "", false)) {
				return false;
			}
			
			return SetNativeString(2, g_szWeaponInfo[iWeaponNum][VIEWMODEL], GetNativeCell(3)) == SP_ERROR_NONE;
		}
	}
	
	return false;
}

public int Native_GetGlovesViewModelByGlovesNum(Handle hPlugin, int iNumParams)
{
	int iGlovesNum = GetNativeCell(1);
	
	if (iGlovesNum < 0 || iGlovesNum > g_iGlovesCount) {
		return false;
	}
	
	if (StrEqual(g_szGlovesInfo[iGlovesNum][VIEWMODEL], "", false)) {
		return false;
	}
	
	return SetNativeString(2, g_szGlovesInfo[iGlovesNum][VIEWMODEL], GetNativeCell(3)) == SP_ERROR_NONE;
}

public int Native_GetGlovesViewModelByDefIndex(Handle hPlugin, int iNumParams)
{
	int iDefIndex = GetNativeCell(1);
	
	CSGOItems_LoopGloves(iGlovesNum) {
		if (StringToInt(g_szGlovesInfo[iGlovesNum][DEFINDEX]) == iDefIndex) {
			
			if (StrEqual(g_szGlovesInfo[iGlovesNum][VIEWMODEL], "", false)) {
				return false;
			}
			
			return SetNativeString(2, g_szGlovesInfo[iGlovesNum][VIEWMODEL], GetNativeCell(3)) == SP_ERROR_NONE;
		}
	}
	
	return false;
}

public int Native_GetGlovesWorldModelByGlovesNum(Handle hPlugin, int iNumParams)
{
	int iGlovesNum = GetNativeCell(1);
	
	if (iGlovesNum < 0 || iGlovesNum > g_iGlovesCount) {
		return false;
	}
	
	if (StrEqual(g_szGlovesInfo[iGlovesNum][WORLDMODEL], "", false)) {
		return false;
	}
	
	return SetNativeString(2, g_szGlovesInfo[iGlovesNum][WORLDMODEL], GetNativeCell(3)) == SP_ERROR_NONE;
}

public int Native_GetGlovesWorldModelByDefIndex(Handle hPlugin, int iNumParams)
{
	int iDefIndex = GetNativeCell(1);
	
	CSGOItems_LoopGloves(iGlovesNum) {
		if (StringToInt(g_szGlovesInfo[iGlovesNum][DEFINDEX]) == iDefIndex) {
			
			if (StrEqual(g_szGlovesInfo[iGlovesNum][WORLDMODEL], "", false)) {
				return false;
			}
			
			return SetNativeString(2, g_szGlovesInfo[iGlovesNum][WORLDMODEL], GetNativeCell(3)) == SP_ERROR_NONE;
		}
	}
	
	return false;
}

public int Native_GetWeaponViewModelByClassName(Handle hPlugin, int iNumParams)
{
	char szBuffer[48]; GetNativeString(1, szBuffer, 48);
	
	CSGOItems_LoopWeapons(iWeaponNum) {
		if (StrEqual(g_szWeaponInfo[iWeaponNum][CLASSNAME], szBuffer, false)) {
			
			if (StrEqual(g_szWeaponInfo[iWeaponNum][VIEWMODEL], "", false)) {
				return false;
			}
			
			return StringToInt(g_szWeaponInfo[iWeaponNum][VIEWMODEL]);
		}
	}
	
	return false;
}

public int Native_GetWeaponWorldModelByWeaponNum(Handle hPlugin, int iNumParams)
{
	int iWeaponNum = GetNativeCell(1);
	
	if (iWeaponNum < 0 || iWeaponNum > g_iWeaponCount) {
		return false;
	}
	
	if (StrEqual(g_szWeaponInfo[iWeaponNum][WORLDMODEL], "", false)) {
		return false;
	}
	
	return SetNativeString(2, g_szWeaponInfo[iWeaponNum][WORLDMODEL], GetNativeCell(3)) == SP_ERROR_NONE;
}

public int Native_GetWeaponWorldModelByWeapon(Handle hPlugin, int iNumParams)
{
	int iWeapon = GetNativeCell(1);
	int iWeaponNum = GetWeaponNumByWeapon(iWeapon);
	
	if (iWeaponNum < 0 || iWeaponNum > g_iWeaponCount) {
		return false;
	}
	
	if (StrEqual(g_szWeaponInfo[iWeaponNum][WORLDMODEL], "", false)) {
		return false;
	}
	
	return SetNativeString(2, g_szWeaponInfo[iWeaponNum][WORLDMODEL], GetNativeCell(3)) == SP_ERROR_NONE;
}

public int Native_GetWeaponWorldModelByDefIndex(Handle hPlugin, int iNumParams)
{
	int iDefIndex = GetNativeCell(1);
	
	if (iDefIndex < 0 || iDefIndex > 700) {
		return false;
	}
	
	CSGOItems_LoopWeapons(iWeaponNum) {
		if (StringToInt(g_szWeaponInfo[iWeaponNum][DEFINDEX]) == iDefIndex) {
			
			if (StrEqual(g_szWeaponInfo[iWeaponNum][WORLDMODEL], "", false)) {
				return false;
			}
			
			return SetNativeString(2, g_szWeaponInfo[iWeaponNum][WORLDMODEL], GetNativeCell(3)) == SP_ERROR_NONE;
		}
	}
	
	return false;
}

public int Native_GetWeaponWorldModelByClassName(Handle hPlugin, int iNumParams)
{
	char szBuffer[48]; GetNativeString(1, szBuffer, 48);
	
	CSGOItems_LoopWeapons(iWeaponNum) {
		if (StrEqual(g_szWeaponInfo[iWeaponNum][CLASSNAME], szBuffer, false)) {
			
			if (StrEqual(g_szWeaponInfo[iWeaponNum][WORLDMODEL], "", false)) {
				return false;
			}
			
			return StringToInt(g_szWeaponInfo[iWeaponNum][WORLDMODEL]);
		}
	}
	
	return false;
}

public int Native_GetWeaponTeamByWeaponNum(Handle hPlugin, int iNumParams)
{
	int iWeaponNum = GetNativeCell(1);
	
	if (iWeaponNum < 0 || iWeaponNum > g_iWeaponCount) {
		return -1;
	}
	
	return StringToInt(g_szWeaponInfo[iWeaponNum][TEAM]);
}

public int Native_GetWeaponTeamByWeapon(Handle hPlugin, int iNumParams)
{
	int iWeapon = GetNativeCell(1);
	int iWeaponNum = GetWeaponNumByWeapon(iWeapon);
	
	if (iWeaponNum < 0 || iWeaponNum > g_iWeaponCount) {
		return -1;
	}
	
	return StringToInt(g_szWeaponInfo[iWeaponNum][TEAM]);
}

public int Native_GetWeaponClipAmmoByDefIndex(Handle hPlugin, int iNumParams)
{
	int iDefIndex = GetNativeCell(1);
	
	if (iDefIndex < 0 || iDefIndex > 700) {
		return -1;
	}
	
	CSGOItems_LoopWeapons(iWeaponNum) {
		if (StringToInt(g_szWeaponInfo[iWeaponNum][DEFINDEX]) == iDefIndex) {
			return StringToInt(g_szWeaponInfo[iWeaponNum][CLIPAMMO]);
		}
	}
	
	return -1;
}

public int Native_GetWeaponClipAmmoByClassName(Handle hPlugin, int iNumParams)
{
	char szBuffer[48]; GetNativeString(1, szBuffer, 48);
	
	CSGOItems_LoopWeapons(iWeaponNum) {
		if (StrEqual(g_szWeaponInfo[iWeaponNum][CLASSNAME], szBuffer, false)) {
			return StringToInt(g_szWeaponInfo[iWeaponNum][CLIPAMMO]);
		}
	}
	
	return -1;
}

public int Native_GetWeaponClipAmmoByWeaponNum(Handle hPlugin, int iNumParams)
{
	int iWeaponNum = GetNativeCell(1);
	
	if (iWeaponNum < 0 || iWeaponNum > g_iWeaponCount) {
		return -1;
	}
	
	return StringToInt(g_szWeaponInfo[iWeaponNum][CLIPAMMO]);
}

public int Native_GetWeaponClipAmmoByWeapon(Handle hPlugin, int iNumParams)
{
	int iWeapon = GetNativeCell(1);
	int iWeaponNum = GetWeaponNumByWeapon(iWeapon);
	
	if (iWeaponNum < 0 || iWeaponNum > g_iWeaponCount) {
		return -1;
	}
	
	return StringToInt(g_szWeaponInfo[iWeaponNum][CLIPAMMO]);
}

public int Native_GetWeaponKillAwardByDefIndex(Handle hPlugin, int iNumParams)
{
	int iDefIndex = GetNativeCell(1);
	
	if (iDefIndex < 0 || iDefIndex > 700) {
		return -1;
	}
	
	CSGOItems_LoopWeapons(iWeaponNum) {
		if (StringToInt(g_szWeaponInfo[iWeaponNum][DEFINDEX]) == iDefIndex) {
			return StringToInt(g_szWeaponInfo[iWeaponNum][KILLAWARD]);
		}
	}
	
	return -1;
}

public int Native_GetWeaponKillAwardByClassName(Handle hPlugin, int iNumParams)
{
	char szBuffer[48]; GetNativeString(1, szBuffer, 48);
	
	CSGOItems_LoopWeapons(iWeaponNum) {
		if (StrEqual(g_szWeaponInfo[iWeaponNum][CLASSNAME], szBuffer, false)) {
			return StringToInt(g_szWeaponInfo[iWeaponNum][KILLAWARD]);
		}
	}
	
	return -1;
}

public int Native_GetWeaponKillAwardByWeaponNum(Handle hPlugin, int iNumParams)
{
	int iWeaponNum = GetNativeCell(1);
	
	if (iWeaponNum < 0 || iWeaponNum > g_iWeaponCount) {
		return -1;
	}
	
	return StringToInt(g_szWeaponInfo[iWeaponNum][KILLAWARD]);
}

public int Native_GetWeaponKillAwardByWeapon(Handle hPlugin, int iNumParams)
{
	int iWeapon = GetNativeCell(1);
	int iWeaponNum = GetWeaponNumByWeapon(iWeapon);
	
	if (iWeaponNum < 0 || iWeaponNum > g_iWeaponCount) {
		return -1;
	}
	
	return StringToInt(g_szWeaponInfo[iWeaponNum][KILLAWARD]);
}

public int Native_GetWeaponSpreadByDefIndex(Handle hPlugin, int iNumParams)
{
	int iDefIndex = GetNativeCell(1);
	
	if (iDefIndex < 0 || iDefIndex > 700) {
		return view_as<int>(-1.0);
	}
	
	CSGOItems_LoopWeapons(iWeaponNum) {
		if (StringToInt(g_szWeaponInfo[iWeaponNum][DEFINDEX]) == iDefIndex) {
			return view_as<int>(StringToFloat(g_szWeaponInfo[iWeaponNum][SPREAD]));
		}
	}
	
	return view_as<int>(-1.0);
}

public int Native_GetWeaponSpreadByClassName(Handle hPlugin, int iNumParams)
{
	char szBuffer[48]; GetNativeString(1, szBuffer, 48);
	
	CSGOItems_LoopWeapons(iWeaponNum) {
		if (StrEqual(g_szWeaponInfo[iWeaponNum][CLASSNAME], szBuffer, false)) {
			return view_as<int>(StringToFloat(g_szWeaponInfo[iWeaponNum][SPREAD]));
		}
	}
	
	return view_as<int>(-1.0);
}

public int Native_GetWeaponSpreadByWeaponNum(Handle hPlugin, int iNumParams)
{
	int iWeaponNum = GetNativeCell(1);
	
	if (iWeaponNum < 0 || iWeaponNum > g_iWeaponCount) {
		return view_as<int>(-1.0);
	}
	
	return view_as<int>(StringToFloat(g_szWeaponInfo[iWeaponNum][SPREAD]));
}

public int Native_GetWeaponSpreadByWeapon(Handle hPlugin, int iNumParams)
{
	int iWeapon = GetNativeCell(1);
	int iWeaponNum = GetWeaponNumByWeapon(iWeapon);
	
	if (iWeaponNum < 0 || iWeaponNum > g_iWeaponCount) {
		return -1;
	}
	
	return view_as<int>(StringToFloat(g_szWeaponInfo[iWeaponNum][SPREAD]));
}

public int Native_GetWeaponCycleTimeByDefIndex(Handle hPlugin, int iNumParams)
{
	int iDefIndex = GetNativeCell(1);
	
	if (iDefIndex < 0 || iDefIndex > 700) {
		return view_as<int>(-1.0);
	}
	
	CSGOItems_LoopWeapons(iWeaponNum) {
		if (StringToInt(g_szWeaponInfo[iWeaponNum][DEFINDEX]) == iDefIndex) {
			return view_as<int>(StringToFloat(g_szWeaponInfo[iWeaponNum][CYCLETIME]));
		}
	}
	
	return view_as<int>(-1.0);
}

public int Native_GetWeaponCycleTimeByClassName(Handle hPlugin, int iNumParams)
{
	char szBuffer[48]; GetNativeString(1, szBuffer, 48);
	
	CSGOItems_LoopWeapons(iWeaponNum) {
		if (StrEqual(g_szWeaponInfo[iWeaponNum][CLASSNAME], szBuffer, false)) {
			return view_as<int>(StringToFloat(g_szWeaponInfo[iWeaponNum][CYCLETIME]));
		}
	}
	
	return view_as<int>(-1.0);
}

public int Native_GetWeaponCycleTimeByWeaponNum(Handle hPlugin, int iNumParams)
{
	int iWeaponNum = GetNativeCell(1);
	
	if (iWeaponNum < 0 || iWeaponNum > g_iWeaponCount) {
		return view_as<int>(-1.0);
	}
	
	return view_as<int>(StringToFloat(g_szWeaponInfo[iWeaponNum][CYCLETIME]));
}

public int Native_GetWeaponCycleTimeByWeapon(Handle hPlugin, int iNumParams)
{
	int iWeapon = GetNativeCell(1);
	int iWeaponNum = GetWeaponNumByWeapon(iWeapon);
	
	if (iWeaponNum < 0 || iWeaponNum > g_iWeaponCount) {
		return -1;
	}
	
	return view_as<int>(StringToFloat(g_szWeaponInfo[iWeaponNum][CYCLETIME]));
}

public int Native_GetWeaponReserveAmmoByDefIndex(Handle hPlugin, int iNumParams)
{
	int iDefIndex = GetNativeCell(1);
	
	if (iDefIndex < 0 || iDefIndex > 700) {
		return view_as<int>(-1.0);
	}
	
	CSGOItems_LoopWeapons(iWeaponNum) {
		if (StringToInt(g_szWeaponInfo[iWeaponNum][DEFINDEX]) == iDefIndex) {
			return StringToInt(g_szWeaponInfo[iWeaponNum][RESERVEAMMO]);
		}
	}
	
	return view_as<int>(-1.0);
}

public int Native_GetWeaponReserveAmmoByClassName(Handle hPlugin, int iNumParams)
{
	char szBuffer[48]; GetNativeString(1, szBuffer, 48);
	
	CSGOItems_LoopWeapons(iWeaponNum) {
		if (StrEqual(g_szWeaponInfo[iWeaponNum][CLASSNAME], szBuffer, false)) {
			return StringToInt(g_szWeaponInfo[iWeaponNum][RESERVEAMMO]);
		}
	}
	
	return view_as<int>(-1.0);
}

public int Native_GetWeaponReserveAmmoByWeaponNum(Handle hPlugin, int iNumParams)
{
	int iWeaponNum = GetNativeCell(1);
	
	if (iWeaponNum < 0 || iWeaponNum > g_iWeaponCount) {
		return -1;
	}
	
	return StringToInt(g_szWeaponInfo[iWeaponNum][RESERVEAMMO]);
}

public int Native_GetWeaponReserveAmmoByWeapon(Handle hPlugin, int iNumParams)
{
	int iWeapon = GetNativeCell(1);
	int iWeaponNum = GetWeaponNumByWeapon(iWeapon);
	
	if (iWeaponNum < 0 || iWeaponNum > g_iWeaponCount) {
		return -1;
	}
	
	return StringToInt(g_szWeaponInfo[iWeaponNum][RESERVEAMMO]);
}

public int Native_SetWeaponAmmo(Handle hPlugin, int iNumParams)
{
	int iWeapon = GetNativeCell(1);
	int iReserveAmmo = GetNativeCell(2);
	int iClipAmmo = GetNativeCell(3);
	
	return SetWeaponAmmo(iWeapon, iReserveAmmo, iClipAmmo);
}

stock bool SetWeaponAmmo(int iWeapon, int iReserveAmmo, int iClipAmmo)
{
	if (iReserveAmmo < 0 && iClipAmmo < 0) {
		return false;
	}
	
	if (iReserveAmmo > -1) {
		SetEntProp(iWeapon, Prop_Send, "m_iPrimaryReserveAmmoCount", iReserveAmmo);
	}
	
	if (iClipAmmo > -1) {
		SetEntProp(iWeapon, Prop_Send, "m_iClip1", iClipAmmo);
	}
	
	return true;
}

public int Native_RefillClipAmmo(Handle hPlugin, int iNumParams)
{
	int iWeapon = GetNativeCell(1);
	int iDefIndex = GetWeaponDefIndexByWeapon(iWeapon);
	
	if (iDefIndex < 0 || iDefIndex > 700) {
		return false;
	}
	
	CSGOItems_LoopWeapons(iWeaponNum) {
		if (StringToInt(g_szWeaponInfo[iWeaponNum][DEFINDEX]) == iDefIndex) {
			int iClipAmmo = StringToInt(g_szWeaponInfo[iWeaponNum][CLIPAMMO]);
			return SetWeaponAmmo(iWeapon, -1, iClipAmmo > 0 ? iClipAmmo : -1);
		}
	}
	
	return false;
}

public int Native_RefillReserveAmmo(Handle hPlugin, int iNumParams)
{
	int iWeapon = GetNativeCell(1);
	int iDefIndex = GetWeaponDefIndexByWeapon(iWeapon);
	
	if (iDefIndex < 0 || iDefIndex > 700) {
		return false;
	}
	
	CSGOItems_LoopWeapons(iWeaponNum) {
		if (StringToInt(g_szWeaponInfo[iWeaponNum][DEFINDEX]) == iDefIndex) {
			int iReserveAmmo = StringToInt(g_szWeaponInfo[iWeaponNum][RESERVEAMMO]);
			return SetWeaponAmmo(iWeapon, iReserveAmmo > 0 ? iReserveAmmo : -1, -1);
		}
	}
	
	return false;
}

public int Native_GetWeaponNumByClassName(Handle hPlugin, int iNumParams)
{
	char szBuffer[48]; GetNativeString(1, szBuffer, 48);
	
	CSGOItems_LoopWeapons(iWeaponNum) {
		if (StrEqual(g_szWeaponInfo[iWeaponNum][CLASSNAME], szBuffer, false)) {
			return iWeaponNum;
		}
	}
	
	return -1;
}

public int Native_GetWeaponNumByWeapon(Handle hPlugin, int iNumParams)
{
	int iWeapon = GetNativeCell(1);
	return GetWeaponNumByWeapon(iWeapon);
}

stock int GetWeaponNumByWeapon(int iWeapon)
{
	int iDefIndex = GetWeaponDefIndexByWeapon(iWeapon);
	
	if (iDefIndex < 0) {
		return -1;
	}
	
	CSGOItems_LoopWeapons(iWeaponNum) {
		if (StringToInt(g_szWeaponInfo[iWeaponNum][DEFINDEX]) == iDefIndex) {
			return iWeaponNum;
		}
	}
	
	return -1;
}

public int Native_GetGlovesNumByClassName(Handle hPlugin, int iNumParams)
{
	char szBuffer[48]; GetNativeString(1, szBuffer, 48);
	
	CSGOItems_LoopGloves(iGlovesNum) {
		if (StrEqual(g_szGlovesInfo[iGlovesNum][CLASSNAME], szBuffer, false)) {
			return iGlovesNum;
		}
	}
	
	return -1;
}

public int Native_GetSkinNumByDefIndex(Handle hPlugin, int iNumParams)
{
	int iDefIndex = GetNativeCell(1);
	
	CSGOItems_LoopSkins(iSkinNum) {
		if (StringToInt(g_szPaintInfo[iSkinNum][DEFINDEX]) == iDefIndex) {
			return iSkinNum;
		}
	}
	
	return -1;
}

public int Native_GetGlovesNumByDefIndex(Handle hPlugin, int iNumParams)
{
	int iDefIndex = GetNativeCell(1);
	
	CSGOItems_LoopGloves(iGlovesNum) {
		if (StringToInt(g_szGlovesInfo[iGlovesNum][DEFINDEX]) == iDefIndex) {
			return iGlovesNum;
		}
	}
	
	return -1;
}

public int Native_GetSprayNumByDefIndex(Handle hPlugin, int iNumParams)
{
	int iDefIndex = GetNativeCell(1);
	
	CSGOItems_LoopSprays(iSprayNum) {
		if (StringToInt(g_szSprayInfo[iSprayNum][DEFINDEX]) == iDefIndex) {
			return iSprayNum;
		}
	}
	
	return -1;
}

public int Native_GetMusicKitNumByDefIndex(Handle hPlugin, int iNumParams)
{
	int iDefIndex = GetNativeCell(1);
	
	CSGOItems_LoopMusicKits(iMusicKitNum) {
		if (StringToInt(g_szMusicKitInfo[iMusicKitNum][DEFINDEX]) == iDefIndex) {
			return iMusicKitNum;
		}
	}
	
	return -1;
}

public int Native_GetItemSetNumByClassName(Handle hPlugin, int iNumParams)
{
	char szBuffer[48]; GetNativeString(1, szBuffer, 48);
	
	CSGOItems_LoopItemSets(iSetNum) {
		if (StrEqual(g_szItemSetInfo[iSetNum][CLASSNAME], szBuffer, false)) {
			return iSetNum;
		}
	}
	
	return -1;
}

public int Native_GetWeaponDefIndexByWeaponNum(Handle hPlugin, int iNumParams)
{
	int iWeaponNum = GetNativeCell(1);
	
	if (iWeaponNum < 0 || iWeaponNum > g_iWeaponCount) {
		return -1;
	}
	
	return GetWeaponDefIndexByWeaponNum(iWeaponNum);
}

stock int GetWeaponDefIndexByWeaponNum(int iWeaponNum)
{
	if (iWeaponNum < 0 || iWeaponNum > g_iWeaponCount) {
		return -1;
	}
	
	return StringToInt(g_szWeaponInfo[iWeaponNum][DEFINDEX]);
}

public int Native_GetWeaponDefIndexByClassName(Handle hPlugin, int iNumParams)
{
	char szBuffer[48]; GetNativeString(1, szBuffer, 48);
	
	return GetWeaponDefIndexByClassName(szBuffer);
}

stock int GetWeaponDefIndexByClassName(const char[] szClassName)
{
	CSGOItems_LoopWeapons(iWeaponNum) {
		if (StrEqual(g_szWeaponInfo[iWeaponNum][CLASSNAME], szClassName, false)) {
			return StringToInt(g_szWeaponInfo[iWeaponNum][DEFINDEX]);
		}
	}
	
	return -1;
}

public int Native_GetSkinDefIndexBySkinNum(Handle hPlugin, int iNumParams)
{
	int iSkinNum = GetNativeCell(1);
	
	if (iSkinNum < 0 || iSkinNum > g_iPaintCount) {
		return -1;
	}
	
	return StringToInt(g_szPaintInfo[iSkinNum][DEFINDEX]);
}

public int Native_GetGlovesDefIndexByGlovesNum(Handle hPlugin, int iNumParams) {
	return StringToInt(g_szGlovesInfo[GetNativeCell(1)][DEFINDEX]);
}

public int Native_GetSprayDefIndexBySprayNum(Handle hPlugin, int iNumParams) {
	return StringToInt(g_szSprayInfo[GetNativeCell(1)][DEFINDEX]);
}

public int Native_GetMusicKitDefIndexByMusicKitNum(Handle hPlugin, int iNumParams) {
	return StringToInt(g_szMusicKitInfo[GetNativeCell(1)][DEFINDEX]);
}

public int Native_GetWeaponClassNameByWeaponNum(Handle hPlugin, int iNumParams)
{
	int iWeaponNum = GetNativeCell(1);
	
	if (iWeaponNum < 0 || iWeaponNum > g_iWeaponCount) {
		return false;
	}
	
	char szBuffer[48];
	
	if (!GetWeaponClassNameByWeaponNum(iWeaponNum, szBuffer, 48)) {
		return false;
	}
	
	return SetNativeString(2, szBuffer, GetNativeCell(3)) == SP_ERROR_NONE;
}

stock bool GetWeaponClassNameByWeaponNum(int iWeaponNum, char[] szBuffer, int iSize)
{
	if (iWeaponNum < 0 || iWeaponNum > g_iWeaponCount) {
		return false;
	}
	
	return strcopy(szBuffer, iSize, g_szWeaponInfo[iWeaponNum][CLASSNAME]) > 0;
}

public int Native_GetWeaponClassNameByDefIndex(Handle hPlugin, int iNumParams)
{
	int iDefIndex = GetNativeCell(1);
	
	if (iDefIndex < 0 || iDefIndex > 700) {
		return false;
	}
	
	char szBuffer[48];
	
	if (!GetWeaponClassNameByDefIndex(iDefIndex, szBuffer, 48)) {
		return false;
	}
	
	return SetNativeString(2, szBuffer, GetNativeCell(3)) == SP_ERROR_NONE;
}

stock bool GetWeaponClassNameByDefIndex(int iDefIndex, char[] szBuffer, int iSize)
{
	if (iDefIndex < 0 || iDefIndex > 700) {
		return false;
	}
	
	CSGOItems_LoopWeapons(iWeaponNum) {
		if (StringToInt(g_szWeaponInfo[iWeaponNum][DEFINDEX]) == iDefIndex) {
			return strcopy(szBuffer, iSize, g_szWeaponInfo[iWeaponNum][CLASSNAME]) > 0;
		}
	}
	
	return false;
}

public int Native_GetWeaponDisplayNameByDefIndex(Handle hPlugin, int iNumParams)
{
	int iDefIndex = GetNativeCell(1);
	
	if (iDefIndex < 0 || iDefIndex > 700) {
		return false;
	}
	
	CSGOItems_LoopWeapons(iWeaponNum) {
		if (StringToInt(g_szWeaponInfo[iWeaponNum][DEFINDEX]) == iDefIndex) {
			return SetNativeString(2, g_szWeaponInfo[iWeaponNum][DISPLAYNAME], GetNativeCell(3)) == SP_ERROR_NONE;
		}
	}
	
	return false;
}

public int Native_GetSkinDisplayNameByDefIndex(Handle hPlugin, int iNumParams)
{
	int iDefIndex = GetNativeCell(1);
	
	CSGOItems_LoopSkins(iSkinNum) {
		if (StringToInt(g_szPaintInfo[iSkinNum][DEFINDEX]) == iDefIndex) {
			return SetNativeString(2, g_szPaintInfo[iSkinNum][DISPLAYNAME], GetNativeCell(3)) == SP_ERROR_NONE;
		}
	}
	
	return false;
}

public int Native_GetSprayDisplayNameByDefIndex(Handle hPlugin, int iNumParams)
{
	int iDefIndex = GetNativeCell(1);
	
	CSGOItems_LoopSprays(iSprayNum) {
		if (StringToInt(g_szSprayInfo[iSprayNum][DEFINDEX]) == iDefIndex) {
			return SetNativeString(2, g_szSprayInfo[iSprayNum][DISPLAYNAME], GetNativeCell(3)) == SP_ERROR_NONE;
		}
	}
	
	return false;
}

public int Native_GetSprayVMTByDefIndex(Handle hPlugin, int iNumParams)
{
	int iDefIndex = GetNativeCell(1);
	
	CSGOItems_LoopSprays(iSprayNum) {
		if (StringToInt(g_szSprayInfo[iSprayNum][DEFINDEX]) == iDefIndex) {
			return SetNativeString(2, g_szSprayInfo[iSprayNum][VMTPATH], GetNativeCell(3)) == SP_ERROR_NONE;
		}
	}
	
	return false;
}

public int Native_GetSprayVTFByDefIndex(Handle hPlugin, int iNumParams)
{
	int iDefIndex = GetNativeCell(1);
	
	CSGOItems_LoopSprays(iSprayNum) {
		if (StringToInt(g_szSprayInfo[iSprayNum][DEFINDEX]) == iDefIndex) {
			return SetNativeString(2, g_szSprayInfo[iSprayNum][VTFPATH], GetNativeCell(3)) == SP_ERROR_NONE;
		}
	}
	
	return false;
}

public int Native_GetSprayDisplayNameBySprayNum(Handle hPlugin, int iNumParams) {
	return SetNativeString(2, g_szSprayInfo[GetNativeCell(1)][DISPLAYNAME], GetNativeCell(3)) == SP_ERROR_NONE;
}

public int Native_GetSprayVMTBySprayNum(Handle hPlugin, int iNumParams) {
	return SetNativeString(2, g_szSprayInfo[GetNativeCell(1)][VMTPATH], GetNativeCell(3)) == SP_ERROR_NONE;
}

public int Native_GetSprayCacheIndexBySprayNum(Handle hPlugin, int iNumParams)
{
	char szBuffer[PLATFORM_MAX_PATH];
	strcopy(szBuffer, PLATFORM_MAX_PATH, g_szSprayInfo[GetNativeCell(1)][VMTPATH]);
	
	ReplaceString(szBuffer, PLATFORM_MAX_PATH, "materials/", "", false);
	ReplaceString(szBuffer, PLATFORM_MAX_PATH, ".vmt", "", false);
	
	PrecacheMaterial(szBuffer);
	return SafePrecacheDecal(szBuffer, true);
}

public int Native_GetSprayVTFBySprayNum(Handle hPlugin, int iNumParams) {
	return SetNativeString(2, g_szSprayInfo[GetNativeCell(1)][VTFPATH], GetNativeCell(3)) == SP_ERROR_NONE;
}

public int Native_GetSprayCacheIndexByDefIndex(Handle hPlugin, int iNumParams)
{
	int iDefIndex = GetNativeCell(1);
	
	CSGOItems_LoopSprays(iSprayNum) {
		if (StringToInt(g_szSprayInfo[iSprayNum][DEFINDEX]) == iDefIndex) {
			char szBuffer[PLATFORM_MAX_PATH]; strcopy(szBuffer, PLATFORM_MAX_PATH, g_szSprayInfo[iSprayNum][VMTPATH]);
			
			ReplaceString(szBuffer, PLATFORM_MAX_PATH, "materials/", "", false);
			ReplaceString(szBuffer, PLATFORM_MAX_PATH, ".vmt", "", false);
			
			PrecacheMaterial(szBuffer);
			return SafePrecacheDecal(szBuffer, true);
		}
	}
	
	return -1;
}

public int Native_GetGlovesDisplayNameByDefIndex(Handle hPlugin, int iNumParams)
{
	int iDefIndex = GetNativeCell(1);
	
	CSGOItems_LoopGloves(iGlovesNum) {
		if (StringToInt(g_szGlovesInfo[iGlovesNum][DEFINDEX]) == iDefIndex) {
			return SetNativeString(2, g_szGlovesInfo[iGlovesNum][DISPLAYNAME], GetNativeCell(3)) == SP_ERROR_NONE;
		}
	}
	
	return false;
}

public int Native_GetWeaponDisplayNameByClassName(Handle hPlugin, int iNumParams)
{
	char szBuffer[48]; GetNativeString(1, szBuffer, 48);
	
	CSGOItems_LoopWeapons(iWeaponNum) {
		if (StrEqual(g_szWeaponInfo[iWeaponNum][CLASSNAME], szBuffer, false)) {
			return SetNativeString(2, g_szWeaponInfo[iWeaponNum][DISPLAYNAME], GetNativeCell(3)) == SP_ERROR_NONE;
		}
	}
	
	return false;
}

public int Native_GetMusicKitDisplayNameByDefIndex(Handle hPlugin, int iNumParams)
{
	int iDefIndex = GetNativeCell(1);
	
	CSGOItems_LoopMusicKits(iMusicKitNum) {
		if (StringToInt(g_szMusicKitInfo[iMusicKitNum][DEFINDEX]) == iDefIndex) {
			return SetNativeString(2, g_szMusicKitInfo[iMusicKitNum][DISPLAYNAME], GetNativeCell(3)) == SP_ERROR_NONE;
		}
	}
	
	return false;
}

public int Native_GetItemSetDisplayNameByClassName(Handle hPlugin, int iNumParams)
{
	char szBuffer[48]; GetNativeString(1, szBuffer, 48);
	
	CSGOItems_LoopItemSets(iSetNum) {
		if (StrEqual(g_szItemSetInfo[iSetNum][CLASSNAME], szBuffer, false)) {
			return SetNativeString(2, g_szItemSetInfo[iSetNum][DISPLAYNAME], GetNativeCell(3)) == SP_ERROR_NONE;
		}
	}
	
	return false;
}

public int Native_GetWeaponDisplayNameByWeaponNum(Handle hPlugin, int iNumParams)
{
	int iWeaponNum = GetNativeCell(1);
	
	if (iWeaponNum < 0 || iWeaponNum > g_iWeaponCount) {
		return -1;
	}
	
	return SetNativeString(2, g_szWeaponInfo[iWeaponNum][DISPLAYNAME], GetNativeCell(3)) == SP_ERROR_NONE;
}

public int Native_GetWeaponDisplayNameByWeapon(Handle hPlugin, int iNumParams)
{
	int iWeapon = GetNativeCell(1);
	int iWeaponNum = GetWeaponNumByWeapon(iWeapon);
	
	if (iWeaponNum < 0) {
		return false;
	}
	
	return SetNativeString(2, g_szWeaponInfo[iWeaponNum][DISPLAYNAME], GetNativeCell(3)) == SP_ERROR_NONE;
}

public int Native_GetSkinDisplayNameBySkinNum(Handle hPlugin, int iNumParams)
{
	int iSkinNum = GetNativeCell(1);
	
	if (iSkinNum < 0 || iSkinNum > g_iPaintCount) {
		return false;
	}
	
	return SetNativeString(2, g_szPaintInfo[iSkinNum][DISPLAYNAME], GetNativeCell(3)) == SP_ERROR_NONE;
}

public int Native_GetSkinVmtPathBySkinNum(Handle hPlugin, int iNumParams)
{
	int iSkinNum = GetNativeCell(1);
	
	if (iSkinNum < 0 || iSkinNum > g_iPaintCount) {
		return false;
	}
	
	return SetNativeString(2, g_szPaintInfo[iSkinNum][VMTPATH], GetNativeCell(3)) == SP_ERROR_NONE;
}

public int Native_IsNativeSkin(Handle hPlugin, int iNumParams)
{
	int iSkinNum = GetNativeCell(1);
	int iItemNum = GetNativeCell(2);
	int iItemType = GetNativeCell(3);
	
	if (iItemType < 0 || iItemType > 1) {
		return false;
	}
	
	return g_bIsNativeSkin[iItemType][iSkinNum][iItemNum];
}

public int Native_GetWeaponNumBySkinNum(Handle hPlugin, int iNumParams)
{
	int iSkinNum = GetNativeCell(1);
	
	if (iSkinNum < 0 || iSkinNum > g_iPaintCount) {
		return -1;
	}
	
	CSGOItems_LoopWeapons(iWeaponNum) {
		if (g_bIsNativeSkin[ITEMTYPE_WEAPON][iSkinNum][iWeaponNum]) {
			return iWeaponNum;
		}
	}
	
	return -1;
}

public int Native_GetGlovesNumBySkinNum(Handle hPlugin, int iNumParams)
{
	int iSkinNum = GetNativeCell(1);
	
	if (iSkinNum < 0 || iSkinNum > g_iPaintCount) {
		return -1;
	}
	
	CSGOItems_LoopGloves(iGlovesNum) {
		if (g_bIsNativeSkin[ITEMTYPE_GLOVES][iSkinNum][iGlovesNum]) {
			return iGlovesNum;
		}
	}
	
	return -1;
}

public int Native_GetGlovesDisplayNameByGlovesNum(Handle hPlugin, int iNumParams) {
	return SetNativeString(2, g_szGlovesInfo[GetNativeCell(1)][DISPLAYNAME], GetNativeCell(3)) == SP_ERROR_NONE;
}

public int Native_GetMusicKitDisplayNameByMusicKitNum(Handle hPlugin, int iNumParams) {
	return SetNativeString(2, g_szMusicKitInfo[GetNativeCell(1)][DISPLAYNAME], GetNativeCell(3)) == SP_ERROR_NONE;
}

public int Native_GetItemSetDisplayNameByItemSetNum(Handle hPlugin, int iNumParams) {
	return SetNativeString(2, g_szItemSetInfo[GetNativeCell(1)][DISPLAYNAME], GetNativeCell(3)) == SP_ERROR_NONE;
}

public int Native_IsDefIndexKnife(Handle hPlugin, int iNumParams)
{
	int iDefIndex = GetNativeCell(1);
	
	if (iDefIndex < 0 || iDefIndex > 700) {
		return false;
	}
	
	return IsDefIndexKnife(iDefIndex);
}

stock bool IsDefIndexKnife(int iDefIndex)
{
	if (iDefIndex < 0 || iDefIndex > 700) {
		return false;
	}
	
	return g_bIsDefIndexKnife[iDefIndex];
}

public int Native_GetActiveClassName(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	
	int iDefIndex = GetActiveWeaponDefIndex(iClient);
	
	if (iDefIndex < 0 || iDefIndex > 700) {
		return false;
	}
	
	char szBuffer[48];
	
	if (GetWeaponClassNameByDefIndex(iDefIndex, szBuffer, 48)) {
		return SetNativeString(2, szBuffer, GetNativeCell(3)) == SP_ERROR_NONE;
	}
	
	return false;
}

public int Native_GetActiveWeaponDefIndex(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	int iActiveWeapon = GetActiveWeapon(iClient);
	
	if (iActiveWeapon < 0) {
		return -1;
	}
	
	return GetWeaponDefIndexByWeapon(iActiveWeapon);
}

stock int GetActiveWeaponDefIndex(int iClient)
{
	int iActiveWeapon = GetActiveWeapon(iClient);
	
	if (iActiveWeapon < 0) {
		return -1;
	}
	
	return GetWeaponDefIndexByWeapon(iActiveWeapon);
}

public int Native_GetActiveWeaponNum(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	
	int iDefIndex = GetActiveWeaponDefIndex(iClient);
	
	if (iDefIndex < 0 || iDefIndex > 700) {
		return -1;
	}
	
	return GetWeaponNumByDefIndex(iDefIndex);
}

public int Native_GetActiveWeapon(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	
	return GetActiveWeapon(iClient);
}

stock int GetActiveWeapon(int iClient)
{
	if (!IsValidClient(iClient)) {
		return -1;
	}
	
	if (!IsPlayerAlive(iClient)) {
		return -1;
	}
	
	return GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
}

public int Native_GetWeaponDefIndexByWeapon(Handle hPlugin, int iNumParams)
{
	int iWeapon = GetNativeCell(1);
	return GetWeaponDefIndexByWeapon(iWeapon);
}

stock int GetWeaponDefIndexByWeapon(int iWeapon)
{
	if (!IsValidWeapon(iWeapon)) {
		return -1;
	}
	
	return GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex");
}

public int Native_IsSkinnableDefIndex(Handle hPlugin, int iNumParams)
{
	int iDefIndex = GetNativeCell(1);
	
	if (iDefIndex < 0 || iDefIndex > 700) {
		return false;
	}
	
	return IsSkinnableDefIndex(iDefIndex);
}

stock bool IsSkinnableDefIndex(int iDefIndex)
{
	if (iDefIndex < 0 || iDefIndex > 700) {
		return false;
	}
	
	return g_bIsDefIndexSkinnable[iDefIndex];
}

public int Native_IsSkinNumGloveApplicable(Handle hPlugin, int iNumParams)
{
	int iSkinNum = GetNativeCell(1);
	
	if (iSkinNum < 0 || iSkinNum > g_iPaintCount) {
		return false;
	}
	
	return g_bSkinNumGloveApplicable[iSkinNum];
}

public int Native_FindWeaponByClassName(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	
	char szBuffer[48]; GetNativeString(2, szBuffer, 48);
	
	return FindWeaponByClassName(iClient, szBuffer);
}

public int Native_FindWeaponByDefIndex(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	int iDefIndex = GetNativeCell(2);
	
	return FindWeaponByDefIndex(iClient, iDefIndex);
}

public int Native_FindWeaponByWeaponNum(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	int iWeaponNum = GetNativeCell(2);
	
	return FindWeaponByWeaponNum(iClient, iWeaponNum);
}

stock int FindWeaponByDefIndex(int iClient, int iDefIndex)
{
	if (iDefIndex < 0 || iDefIndex > 700) {
		return -1;
	}
	
	char szBuffer[48];
	
	if (!GetWeaponClassNameByDefIndex(iDefIndex, szBuffer, 48)) {
		return -1;
	}
	
	return FindWeaponByClassName(iClient, szBuffer);
}

stock int FindWeaponByWeaponNum(int iClient, int iWeaponNum)
{
	if (iWeaponNum < 0 || iWeaponNum > g_iWeaponCount) {
		return -1;
	}
	
	char szBuffer[48];
	
	if (!GetWeaponClassNameByWeaponNum(iWeaponNum, szBuffer, 48)) {
		return -1;
	}
	
	return FindWeaponByClassName(iClient, szBuffer);
}

stock int FindWeaponByClassName(int iClient, const char[] szClassName)
{
	if (!IsValidClient(iClient)) {
		return -1;
	}
	
	if (!IsPlayerAlive(iClient)) {
		return -1;
	}
	
	char szBuffer[48];
	int iOriginalDefIndex = GetWeaponDefIndexByClassName(szClassName);
	
	if (iOriginalDefIndex < 0) {
		return -1;
	}
	
	int iWeapon = -1;
	int iCurrentDefIndex = -1;
	
	for (int i = 0; i < GetEntPropArraySize(iClient, Prop_Send, "m_hMyWeapons"); i++) {
		iWeapon = GetEntPropEnt(iClient, Prop_Send, "m_hMyWeapons", i);
		
		if (!CSGOItems_IsValidWeapon(iWeapon)) {
			continue;
		}
		
		iCurrentDefIndex = GetWeaponDefIndexByWeapon(iWeapon);
		
		if (iCurrentDefIndex == iOriginalDefIndex) {
			return iWeapon;
		}
		
		if (!GetEntityClassname(iWeapon, szBuffer, 48)) {
			continue;
		}
		
		if (StrEqual(szClassName, szBuffer, false)) {
			return iWeapon;
		}
		
		if (GetWeaponDefIndexByClassName(szBuffer) == iOriginalDefIndex) {
			return iWeapon;
		}
		
		if (!GetWeaponClassNameByWeapon(iWeapon, szBuffer, 48)) {
			continue;
		}
		
		if (StrEqual(szClassName, szBuffer, false)) {
			return iWeapon;
		}
		
		if (GetWeaponDefIndexByClassName(szBuffer) == iOriginalDefIndex) {
			return iWeapon;
		}
	}
	
	return -1;
}

public int Native_GetWeaponSlotByWeaponNum(Handle hPlugin, int iNumParams)
{
	int iWeaponNum = GetNativeCell(1);
	
	if (iWeaponNum < 0 || iWeaponNum > g_iWeaponCount) {
		return -1;
	}
	
	return SlotNameToNum(g_szWeaponInfo[iWeaponNum][SLOT]);
}

public int GetWeaponSlotByWeapon(int iWeapon)
{
	int iWeaponNum = GetWeaponNumByWeapon(iWeapon);
	
	if (iWeaponNum < 0 || iWeaponNum > g_iWeaponCount) {
		return -1;
	}
	
	return SlotNameToNum(g_szWeaponInfo[iWeaponNum][SLOT]);
}

public int Native_GetWeaponSlotByWeapon(Handle hPlugin, int iNumParams)
{
	int iWeapon = GetNativeCell(1);
	
	return GetWeaponSlotByWeapon(iWeapon);
}

public int Native_GetWeaponSlotByDefIndex(Handle hPlugin, int iNumParams)
{
	int iDefIndex = GetNativeCell(1);
	
	if (iDefIndex < 0 || iDefIndex > 700) {
		return -1;
	}
	
	return GetWeaponSlotByDefIndex(iDefIndex);
}

stock int GetWeaponSlotByDefIndex(int iDefIndex)
{
	if (iDefIndex < 0 || iDefIndex > 700) {
		return -1;
	}
	
	CSGOItems_LoopWeapons(iWeaponNum) {
		if (StringToInt(g_szWeaponInfo[iWeaponNum][DEFINDEX]) == iDefIndex) {
			return SlotNameToNum(g_szWeaponInfo[iWeaponNum][SLOT]);
		}
	}
	
	return -1;
}

public int Native_GetWeaponSlotByClassName(Handle hPlugin, int iNumParams)
{
	char szBuffer[48]; GetNativeString(1, szBuffer, 48);
	return GetWeaponSlotByClassName(szBuffer);
}

stock int GetWeaponSlotByClassName(const char[] szClassName)
{
	CSGOItems_LoopWeapons(iWeaponNum) {
		if (StrEqual(g_szWeaponInfo[iWeaponNum][CLASSNAME], szClassName, false)) {
			return SlotNameToNum(g_szWeaponInfo[iWeaponNum][SLOT]);
		}
	}
	
	return -1;
}

public int Native_GetWeaponClassNameByWeapon(Handle hPlugin, int iNumParams)
{
	int iWeapon = GetNativeCell(1);
	char szBuffer[48];
	
	if (GetWeaponClassNameByWeapon(iWeapon, szBuffer, 48)) {
		return false;
	}
	
	return SetNativeString(2, szBuffer, GetNativeCell(3)) == SP_ERROR_NONE;
}

stock bool GetWeaponClassNameByWeapon(int iWeapon, char[] szBuffer, int iSize)
{
	int iDefIndex = GetWeaponDefIndexByWeapon(iWeapon);
	
	if (iDefIndex < 0 || iDefIndex > 700) {
		return false;
	}
	
	char szWeaponClassName[48];
	
	if (GetWeaponClassNameByDefIndex(iDefIndex, szWeaponClassName, 48)) {
		return strcopy(szBuffer, iSize, szWeaponClassName) > 0;
	}
	
	return false;
}

public int Native_IsValidWeapon(Handle hPlugin, int iNumParams)
{
	int iWeapon = GetNativeCell(1);
	
	return IsValidWeapon(iWeapon);
}

stock bool IsValidWeapon(int iWeapon)
{
	if (!IsValidEntity(iWeapon) || !IsValidEdict(iWeapon) || iWeapon < 0) {
		return false;
	}
	
	if (!HasEntProp(iWeapon, Prop_Send, "m_hOwnerEntity")) {
		return false;
	}
	
	char szBuffer[48]; GetEntityClassname(iWeapon, szBuffer, 48);
	
	return IsValidWeaponClassName(szBuffer);
}

public int Native_GiveWeapon(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	char szClassName[48]; GetNativeString(2, szClassName, 48);
	
	int iReserveAmmo = GetNativeCell(3);
	int iClipAmmo = GetNativeCell(4);
	int iSwitchTo = GetNativeCell(5);
	
	return GiveWeapon(iClient, szClassName, iReserveAmmo, iClipAmmo, iSwitchTo);
}

stock int GiveWeapon(int iClient, const char[] szBuffer, int iReserveAmmo, int iClipAmmo, int iSwitchTo)
{
	if (!IsValidClient(iClient)) {
		return -1;
	}
	
	if (!IsPlayerAlive(iClient)) {
		return -1;
	}
	
	char szClassName[48]; strcopy(szClassName, 48, szBuffer);
	int iClientTeam = GetClientTeam(iClient);
	
	if (iClientTeam < 2 || iClientTeam > 3) {
		return -1;
	}
	
	int iViewModel = GetEntPropEnt(iClient, Prop_Send, "m_hViewModel");
	int iViewSequence = -1;
	
	if (iViewModel > -1 && IsValidEntity(iViewModel)) {
		iViewSequence = GetEntProp(iViewModel, Prop_Send, "m_nSequence");
	}
	
	if (!IsValidWeaponClassName(szClassName)) {
		return -1;
	}
	
	int iWeaponTeam = GetWeaponTeamByClassName(szClassName);
	int iWeaponDefIndex = GetWeaponDefIndexByClassName(szClassName);
	int iLookingAtWeapon = GetEntProp(iClient, Prop_Send, "m_bIsLookingAtWeapon");
	int iHoldingLookAtWeapon = GetEntProp(iClient, Prop_Send, "m_bIsHoldingLookAtWeapon");
	int iReloadVisuallyComplete = -1;
	int iWeaponSilencer = -1;
	int iWeaponMode = -1;
	int iRecoilIndex = -1;
	int iIronSightMode = -1;
	int iZoomLevel = -1;
	int iCurrentSlot = GetWeaponSlotByClassName(szClassName);
	int iCurrentWeapon = GetPlayerWeaponSlot(iClient, iCurrentSlot);
	int iHudFlags = GetEntProp(iClient, Prop_Send, "m_iHideHUD");
	
	float fNextPlayerAttackTime = GetEntPropFloat(iClient, Prop_Send, "m_flNextAttack");
	float fDoneSwitchingSilencer = -1.0;
	float fNextPrimaryAttack = -1.0;
	float fNextSecondaryAttack = -1.0;
	float fTimeWeaponIdle = -1.0;
	float fAccuracyPenalty = -1.0;
	float fLastShotTime = -1.0;
	
	char szCurrentClassName[48];
	bool bKnife = IsDefIndexKnife(iWeaponDefIndex);
	
	if (IsValidWeapon(iCurrentWeapon)) {
		GetWeaponClassNameByWeapon(iCurrentWeapon, szCurrentClassName, 48);
		
		if (HasEntProp(iCurrentWeapon, Prop_Send, "m_flNextPrimaryAttack")) {
			fNextPrimaryAttack = GetEntPropFloat(iCurrentWeapon, Prop_Send, "m_flNextPrimaryAttack");
		}
		if (HasEntProp(iCurrentWeapon, Prop_Send, "m_flNextSecondaryAttack")) {
			fNextSecondaryAttack = GetEntPropFloat(iCurrentWeapon, Prop_Send, "m_flNextSecondaryAttack");
		}
		if (HasEntProp(iCurrentWeapon, Prop_Send, "m_flTimeWeaponIdle")) {
			fTimeWeaponIdle = GetEntPropFloat(iCurrentWeapon, Prop_Send, "m_flTimeWeaponIdle");
		}
		if (HasEntProp(iCurrentWeapon, Prop_Send, "m_fAccuracyPenalty")) {
			fAccuracyPenalty = GetEntPropFloat(iCurrentWeapon, Prop_Send, "m_fAccuracyPenalty");
		}
		if (HasEntProp(iCurrentWeapon, Prop_Send, "m_bReloadVisuallyComplete")) {
			iReloadVisuallyComplete = GetEntProp(iCurrentWeapon, Prop_Send, "m_bReloadVisuallyComplete");
		}
		if (HasEntProp(iCurrentWeapon, Prop_Send, "m_bSilencerOn")) {
			iWeaponSilencer = GetEntProp(iCurrentWeapon, Prop_Send, "m_bSilencerOn");
		}
		if (HasEntProp(iCurrentWeapon, Prop_Send, "m_weaponMode")) {
			iWeaponMode = GetEntProp(iCurrentWeapon, Prop_Send, "m_weaponMode");
		}
		if (HasEntProp(iCurrentWeapon, Prop_Send, "m_iRecoilIndex")) {
			iRecoilIndex = GetEntProp(iCurrentWeapon, Prop_Send, "m_iRecoilIndex");
		}
		if (HasEntProp(iCurrentWeapon, Prop_Send, "m_iIronSightMode")) {
			iIronSightMode = GetEntProp(iCurrentWeapon, Prop_Send, "m_iIronSightMode");
		}
		if (HasEntProp(iCurrentWeapon, Prop_Send, "m_flDoneSwitchingSilencer")) {
			fDoneSwitchingSilencer = GetEntPropFloat(iCurrentWeapon, Prop_Send, "m_flDoneSwitchingSilencer");
		}
		if (HasEntProp(iCurrentWeapon, Prop_Send, "m_fLastShotTime")) {
			fLastShotTime = GetEntPropFloat(iCurrentWeapon, Prop_Send, "m_fLastShotTime");
		}
		if (HasEntProp(iCurrentWeapon, Prop_Send, "m_zoomLevel")) {
			iZoomLevel = GetEntProp(iCurrentWeapon, Prop_Send, "m_zoomLevel");
		}
		
		if (bKnife) {
			if (!RemoveKnife(iClient)) {
				g_bGivingWeapon[iClient] = false;
				return -1;
			}
		} else if (!RemoveWeapon(iClient, iCurrentWeapon)) {
			g_bGivingWeapon[iClient] = false;
			return -1;
		}
	}
	
	if (iClientTeam != iWeaponTeam && iWeaponTeam > 1) {
		SetEntProp(iClient, Prop_Send, "m_iTeamNum", iWeaponTeam);
	}
	
	g_bGivingWeapon[iClient] = true;
	
	int iWeapon = -1;
	bool bGiven = false;
	
	if (!bGiven) {
		if (bKnife && g_bFollowGuidelines) {
			strcopy(szClassName, 48, iClientTeam == CS_TEAM_T ? "weapon_knife_t" : "weapon_knife");
		}
		
		iWeapon = GivePlayerItem(iClient, szClassName);
		bGiven = IsValidWeapon(iWeapon);
	}
	
	if (!IsValidWeapon(iWeapon) || !bGiven) {
		if (iWeaponTeam > 1 && GetClientTeam(iClient) != iClientTeam) {
			SetEntProp(iClient, Prop_Send, "m_iTeamNum", iClientTeam);
		}
		
		g_bGivingWeapon[iClient] = false;
		
		if (iWeapon > 0 && IsValidEdict(iWeapon) && IsValidEntity(iWeapon)) {
			AcceptEntityInput(iWeapon, "Kill");
		}
		
		return -1;
	}
	
	iWeaponDefIndex = GetWeaponDefIndexByWeapon(iWeapon);
	
	if (!bKnife) {
		SetWeaponAmmo(iWeapon, iReserveAmmo, iClipAmmo);
	} else {
		EquipPlayerWeapon(iClient, iWeapon);
	}
	
	int iSwitchWeapon = -1;
	
	if (iSwitchTo > -1 && iSwitchTo <= 4) {
		iSwitchWeapon = GetPlayerWeaponSlot(iClient, iSwitchTo);
		
		if (IsValidWeapon(iSwitchWeapon)) {
			SetActiveWeapon(iClient, iSwitchWeapon);
		}
	}
	
	int iActiveWeapon = GetActiveWeapon(iClient);
	
	if (iActiveWeapon == iWeapon) {
		if (iSwitchWeapon == iWeapon) {
			if (StrEqual(szClassName, szCurrentClassName, false)) {
				if (iLookingAtWeapon > -1 && HasEntProp(iClient, Prop_Send, "m_bIsLookingAtWeapon")) {
					SetEntProp(iClient, Prop_Send, "m_bIsLookingAtWeapon", iLookingAtWeapon);
				}
				if (iHoldingLookAtWeapon > -1 && HasEntProp(iClient, Prop_Send, "m_bIsHoldingLookAtWeapon")) {
					SetEntProp(iClient, Prop_Send, "m_bIsHoldingLookAtWeapon", iHoldingLookAtWeapon);
				}
				if (fNextPlayerAttackTime > -1.0 && HasEntProp(iClient, Prop_Send, "m_flNextAttack")) {
					SetEntPropFloat(iClient, Prop_Send, "m_flNextAttack", fNextPlayerAttackTime);
				}
				if (fNextPrimaryAttack > -1.0 && HasEntProp(iCurrentWeapon, Prop_Send, "m_flNextPrimaryAttack")) {
					SetEntPropFloat(iWeapon, Prop_Send, "m_flNextPrimaryAttack", fNextPrimaryAttack);
				}
				if (fNextSecondaryAttack > -1.0 && HasEntProp(iCurrentWeapon, Prop_Send, "m_flNextSecondaryAttack")) {
					SetEntPropFloat(iWeapon, Prop_Send, "m_flNextSecondaryAttack", fNextSecondaryAttack);
				}
				if (fTimeWeaponIdle > -1.0 && HasEntProp(iCurrentWeapon, Prop_Send, "m_flTimeWeaponIdle")) {
					SetEntPropFloat(iWeapon, Prop_Send, "m_flTimeWeaponIdle", fTimeWeaponIdle);
				}
				if (fAccuracyPenalty > -1.0 && HasEntProp(iCurrentWeapon, Prop_Send, "m_fAccuracyPenalty")) {
					SetEntPropFloat(iWeapon, Prop_Send, "m_fAccuracyPenalty", fAccuracyPenalty);
				}
				if (fDoneSwitchingSilencer > -1.0 && HasEntProp(iCurrentWeapon, Prop_Send, "m_flDoneSwitchingSilencer")) {
					SetEntPropFloat(iWeapon, Prop_Send, "m_flDoneSwitchingSilencer", fDoneSwitchingSilencer);
				}
				if (fLastShotTime > -1.0 && HasEntProp(iCurrentWeapon, Prop_Send, "m_fLastShotTime")) {
					SetEntPropFloat(iWeapon, Prop_Send, "m_fLastShotTime", fLastShotTime);
				}
				if (iReloadVisuallyComplete > -1 && HasEntProp(iCurrentWeapon, Prop_Send, "m_bReloadVisuallyComplete")) {
					SetEntProp(iWeapon, Prop_Send, "m_bReloadVisuallyComplete", iReloadVisuallyComplete);
				}
				if (iWeaponSilencer > -1 && HasEntProp(iCurrentWeapon, Prop_Send, "m_bSilencerOn")) {
					SetEntProp(iWeapon, Prop_Send, "m_bSilencerOn", iWeaponSilencer);
				}
				if (iWeaponMode > -1 && HasEntProp(iCurrentWeapon, Prop_Send, "m_weaponMode")) {
					SetEntProp(iWeapon, Prop_Send, "m_weaponMode", iWeaponMode);
				}
				if (iRecoilIndex > -1 && HasEntProp(iCurrentWeapon, Prop_Send, "m_iRecoilIndex")) {
					SetEntProp(iWeapon, Prop_Send, "m_iRecoilIndex", iRecoilIndex);
				}
				if (iIronSightMode > -1 && HasEntProp(iCurrentWeapon, Prop_Send, "m_iIronSightMode")) {
					SetEntProp(iWeapon, Prop_Send, "m_iIronSightMode", iIronSightMode);
				}
				
				if (iZoomLevel > -1 && HasEntProp(iCurrentWeapon, Prop_Send, "m_zoomLevel")) {
					SetEntProp(iWeapon, Prop_Send, "m_zoomLevel", iZoomLevel);
				}
			}
			
			if (bKnife) {
				switch (iWeaponDefIndex) {
					case 515 :  {  // Butterfly
						iViewSequence = SEQUENCE_BUTTERFLY_IDLE1;
					}
					
					case 512 :  {  // Falchion
						iViewSequence = SEQUENCE_FALCHION_IDLE1;
					}
					
					case 516: {  // Butt Plugs
						iViewSequence = SEQUENCE_DAGGERS_IDLE1;
					}
					
					case 514: {  // Bowie
						iViewSequence = SEQUENCE_BOWIE_IDLE1;
					}
					
					default: {
						iViewSequence = SEQUENCE_DEFAULT_IDLE2;
					}
				}
			} else if (StrEqual(szClassName, "weapon_m4a1_silencer", false)) {
				iViewSequence = 1;
			} else {
				iViewSequence = 0;
			}
		}
	}
	
	if (!IsValidEntity(iViewModel)) {
		iViewModel = GetEntPropEnt(iClient, Prop_Send, "m_hViewModel");
	}
	
	if (IsValidEntity(iViewModel) && iViewSequence > -1) {
		SetEntProp(iViewModel, Prop_Send, "m_nSequence", iViewSequence);
	}
	
	SetEntProp(iClient, Prop_Send, "m_iHideHUD", iHudFlags);
	
	if (iWeaponTeam > 1 && GetClientTeam(iClient) != iClientTeam) {
		SetEntProp(iClient, Prop_Send, "m_iTeamNum", iClientTeam);
	}
	
	g_bGivingWeapon[iClient] = false;
	
	Call_StartForward(g_hOnWeaponGiven);
	Call_PushCell(iClient);
	Call_PushCell(iWeapon);
	Call_PushString(szClassName);
	Call_PushCell(iWeaponDefIndex);
	Call_PushCell(GetWeaponSlotByDefIndex(iWeaponDefIndex));
	Call_PushCell(IsSkinnableDefIndex(iWeaponDefIndex));
	Call_PushCell(bKnife);
	Call_Finish();
	
	return iWeapon;
}

public Action OnNormalSoundPlayed(int iClients[64], int &iNumClients, char szSample[PLATFORM_MAX_PATH], int &iEntity, int &iChannel, float &iVolume, int &iLevel, int &iPitch, int &iFlags)
{
	if (StrContains(szSample, "itempickup.wav", false) > -1 || StrContains(szSample, "ClipEmpty_Rifle.wav", false) > -1 || StrContains(szSample, "buttons/", false) > -1) {
		CSGOItems_LoopValidClients(iClient) {
			if (g_bGivingWeapon[iClient]) {
				return Plugin_Handled;
			}
		}
	}
	
	return Plugin_Continue;
}

public int Native_RespawnWeapon(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	int iWeapon = GetNativeCell(2);
	
	return RespawnWeapon(iClient, iWeapon);
}

stock int RespawnWeapon(int iClient, int iWeapon)
{
	if (!IsValidClient(iClient)) {
		return -1;
	}
	
	if (!IsPlayerAlive(iClient)) {
		return -1;
	}
	
	int iDefIndex = GetWeaponDefIndexByWeapon(iWeapon);
	
	if (iDefIndex < 0 || iDefIndex > 700) {
		return -1;
	}
	
	int iWeaponSlot = GetWeaponSlotByDefIndex(iDefIndex);
	
	if (iWeaponSlot < 0) {
		return -1;
	}
	
	if (iWeapon != GetPlayerWeaponSlot(iClient, iWeaponSlot)) {
		return -1;
	}
	
	char szClassName[48];
	
	if (!GetWeaponClassNameByDefIndex(iDefIndex, szClassName, 48)) {
		return -1;
	}
	
	int iReserveAmmo = -1;
	int iClipAmmo = -1;
	
	if (HasEntProp(iWeapon, Prop_Send, "m_iPrimaryReserveAmmoCount")) {
		iReserveAmmo = GetEntProp(iWeapon, Prop_Send, "m_iPrimaryReserveAmmoCount");
	}
	
	if (HasEntProp(iWeapon, Prop_Send, "m_iClip1")) {
		iClipAmmo = GetEntProp(iWeapon, Prop_Send, "m_iClip1");
	}
	
	return GiveWeapon(iClient, szClassName, iReserveAmmo, iClipAmmo, GetActiveWeaponSlot(iClient));
}

public int Native_RespawnWeaponBySlot(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	return RespawnWeapon(iClient, GetPlayerWeaponSlot(iClient, GetNativeCell(2)));
}

public int Native_RemoveWeapon(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	int iWeapon = GetNativeCell(2);
	
	return RemoveWeapon(iClient, iWeapon);
}

stock bool RemoveWeapon(int iClient, int iWeapon)
{
	if (!IsValidClient(iClient)) {
		return false;
	}
	
	if (!IsPlayerAlive(iClient)) {
		return false;
	}
	
	if (g_bRoundEnd) {
		return false;
	}
	
	int iDefIndex = GetWeaponDefIndexByWeapon(iWeapon);
	
	if (iDefIndex < 0 || iDefIndex > 700) {
		return false;
	}
	
	int iWeaponSlot = GetWeaponSlotByDefIndex(iDefIndex);
	
	if (iWeaponSlot < 0) {
		return false;
	}
	
	if (GetPlayerWeaponSlot(iClient, iWeaponSlot) != iWeapon) {
		return false;
	}
	
	if (!RemovePlayerItem(iClient, iWeapon)) {
		if (!DropWeapon(iClient, iWeapon)) {
			return false;
		}
	}
	
	AcceptEntityInput(iWeapon, "Kill");
	
	return true;
}

public int Native_DropWeapon(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	int iWeapon = GetNativeCell(2);
	
	return DropWeapon(iClient, iWeapon);
}

stock bool DropWeapon(int iClient, int iWeapon)
{
	if (!IsValidClient(iClient)) {
		return false;
	}
	
	if (!IsPlayerAlive(iClient)) {
		return false;
	}
	
	if (g_bRoundEnd) {
		return false;
	}
	
	int iDefIndex = GetWeaponDefIndexByWeapon(iWeapon);
	
	if (iDefIndex < 0 || iDefIndex > 700) {
		return false;
	}
	
	int iWeaponSlot = GetWeaponSlotByDefIndex(iDefIndex);
	
	if (iWeaponSlot < 0) {
		return false;
	}
	
	if (GetPlayerWeaponSlot(iClient, iWeaponSlot) != iWeapon) {
		return false;
	}
	
	int iHudFlags = GetEntProp(iClient, Prop_Send, "m_iHideHUD");
	int iOwnerEntity = GetEntPropEnt(iWeapon, Prop_Send, "m_hOwnerEntity");
	
	if (iOwnerEntity != iClient) {
		SetEntPropEnt(iWeapon, Prop_Send, "m_hOwnerEntity", iClient);
	}
	
	if (iWeapon == GetActiveWeapon(iClient)) {
		SetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon", -1);
	}
	
	CS_DropWeapon(iClient, iWeapon, false, true);
	
	if (iOwnerEntity != iClient) {
		SetEntPropEnt(iWeapon, Prop_Send, "m_hOwnerEntity", iOwnerEntity);
	}
	
	SetEntProp(iClient, Prop_Send, "m_iHideHUD", iHudFlags);
	
	return true;
}

public int Native_RemoveAllWeapons(Handle hPlugin, int iNumParams)
{
	if (g_bRoundEnd) {
		return false;
	}
	
	int iClient = GetNativeCell(1);
	
	if (!IsValidClient(iClient)) {
		return -1;
	}
	
	if (!IsPlayerAlive(iClient)) {
		return -1;
	}
	
	int iSkipSlot = GetNativeCell(2);
	
	int iRemovedWeapons = 0;
	int iWeaponSlot = -1;
	int iWeapon = -1;
	
	for (int i = 0; i < GetEntPropArraySize(iClient, Prop_Send, "m_hMyWeapons"); i++) {
		iWeapon = GetEntPropEnt(iClient, Prop_Send, "m_hMyWeapons", i);
		
		if (!CSGOItems_IsValidWeapon(iWeapon)) {
			continue;
		}
		
		iWeaponSlot = GetWeaponSlotByWeapon(iWeapon);
		
		if (iWeaponSlot < 0) {
			continue;
		}
		
		if (iWeaponSlot == iSkipSlot && iSkipSlot > -1) {
			continue;
		}
		
		if (RemoveWeapon(iClient, iWeapon)) {
			iRemovedWeapons++;
		}
	}
	
	return iRemovedWeapons;
}

public int Native_SetActiveWeapon(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	int iWeapon = GetNativeCell(2);
	
	return SetActiveWeapon(iClient, iWeapon);
}

stock bool SetActiveWeapon(int iClient, int iWeapon)
{
	if (!IsValidClient(iClient)) {
		return false;
	}
	
	if (!IsPlayerAlive(iClient)) {
		return false;
	}
	
	int iDefIndex = GetWeaponDefIndexByWeapon(iWeapon);
	
	if (iDefIndex < 0 || iDefIndex > 700) {
		return false;
	}
	
	int iWeaponSlot = GetWeaponSlotByDefIndex(iDefIndex);
	
	if (iWeaponSlot < 0) {
		return false;
	}
	
	if (GetPlayerWeaponSlot(iClient, iWeaponSlot) != iWeapon) {
		return false;
	}
	
	int iHudFlags = GetEntProp(iClient, Prop_Send, "m_iHideHUD");
	
	char szWeapon[48]; GetEntityClassname(iWeapon, szWeapon, 48);
	
	FakeClientCommandEx(iClient, "use %s", szWeapon);
	SDKCall(g_hSwitchWeaponCall, iClient, iWeapon, 0);
	SetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon", iWeapon);
	SetEntProp(iClient, Prop_Send, "m_iHideHUD", iHudFlags);
	
	return true;
}

public int Native_AreItemsSynced(Handle hPlugin, int iNumParams) {
	return g_bItemsSynced;
}

public int Native_AreItemsSyncing(Handle hPlugin, int iNumParams) {
	return g_bItemsSyncing;
}

public int Native_Resync(Handle hPlugin, int iNumParams) {
	return RetrieveLanguage();
}

public int Native_GetActiveWeaponSlot(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	return GetActiveWeaponSlot(iClient);
}

stock int GetActiveWeaponSlot(int iClient)
{
	if (!IsValidClient(iClient)) {
		return -1;
	}
	
	if (!IsPlayerAlive(iClient)) {
		return -1;
	}
	
	CSGOItems_LoopWeaponSlots(iSlot) {
		if (GetPlayerWeaponSlot(iClient, iSlot) == GetActiveWeapon(iClient)) {
			return iSlot;
		}
	}
	
	return -1;
}

public int Native_RemoveKnife(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	
	return RemoveKnife(iClient);
}

stock bool RemoveKnife(int iClient)
{
	if (!IsValidClient(iClient)) {
		return false;
	}
	
	if (!IsPlayerAlive(iClient)) {
		return false;
	}
	
	int iWeapon = -1;
	int iDefIndex = -1;
	
	for (int i = 0; i < GetEntPropArraySize(iClient, Prop_Send, "m_hMyWeapons"); i++) {
		iWeapon = GetEntPropEnt(iClient, Prop_Send, "m_hMyWeapons", i);
		
		if (!CSGOItems_IsValidWeapon(iWeapon)) {
			continue;
		}
		
		iDefIndex = GetWeaponDefIndexByWeapon(iWeapon);
		
		if (!IsDefIndexKnife(iDefIndex)) {
			continue;
		}
		
		return RemoveWeapon(iClient, iWeapon);
	}
	
	return false;
}

public int Native_GetActiveWeaponCount(Handle hPlugin, int iNumParams)
{
	char szBuffer[48]; GetNativeString(1, szBuffer, 48);
	
	int iTeam = GetNativeCell(2);
	int iCount = 0;
	int iWeaponSlot = GetWeaponSlotByClassName(szBuffer);
	
	if (iWeaponSlot < 0) {
		return -1;
	}
	
	CSGOItems_LoopValidClients(iClient) {
		if (iTeam < 2 || iTeam > 3 || GetClientTeam(iClient) != iTeam) {
			continue;
		}
		
		if (FindWeaponByClassName(iClient, szBuffer) < 0) {
			continue;
		}
		
		iCount++;
	}
	
	return iCount;
}

public int Native_SetAllWeaponsAmmo(Handle hPlugin, int iNumParams)
{
	char szClassName[48]; char szBuffer[48]; GetNativeString(1, szClassName, 48);
	int iReserveAmmo = GetNativeCell(2);
	int iClipAmmo = GetNativeCell(3);
	
	CSGOItems_LoopValidWeapons(iWeapon) {
		if (!GetWeaponClassNameByWeapon(iWeapon, szBuffer, 48)) {
			continue;
		}
		
		if (!StrEqual(szClassName, szBuffer, false)) {
			continue;
		}
		
		SetWeaponAmmo(iWeapon, iReserveAmmo, iClipAmmo);
	}
}

public int Native_GetRandomSkin(Handle hPlugin, int iNumParams) {
	return StringToInt(g_szPaintInfo[GetRandomInt(1, g_iPaintCount)][DEFINDEX]);
}

stock int PrecacheMaterial(const char[] szMaterial)
{
	if (StrEqual(szMaterial, "", false || strlen(szMaterial) <= 0)) {
		return INVALID_STRING_INDEX;
	}
	
	static int materialNames = INVALID_STRING_TABLE;
	
	if (materialNames == INVALID_STRING_TABLE) {
		if ((materialNames = FindStringTable("Materials")) == INVALID_STRING_TABLE) {
			return INVALID_STRING_INDEX;
		}
	}
	
	int index = FindStringIndex2(materialNames, szMaterial);
	
	if (index == INVALID_STRING_INDEX) {
		int numStrings = GetStringTableNumStrings(materialNames);
		
		if (numStrings >= GetStringTableMaxStrings(materialNames)) {
			return INVALID_STRING_INDEX;
		}
		
		AddToStringTable(materialNames, szMaterial);
		index = numStrings;
	}
	
	return index;
}

stock int SafePrecacheModel(char[] szModel, bool bPreLoad = false)
{
	TrimString(szModel); StripQuotes(szModel);
	
	if (StrEqual(szModel, "", false || strlen(szModel) <= 0)) {
		return -1;
	}
	
	return PrecacheModel(szModel, bPreLoad);
}

stock int SafePrecacheDecal(char[] szModel, bool bPreLoad = false)
{
	TrimString(szModel); StripQuotes(szModel);
	
	if (StrEqual(szModel, "", false || strlen(szModel) <= 0)) {
		return -1;
	}
	
	return PrecacheDecal(szModel, bPreLoad);
}

stock int FindStringIndex2(int tableidx, const char[] str)
{
	char buf[1024];
	
	int numStrings = GetStringTableNumStrings(tableidx);
	for (int i = 0; i < numStrings; i++) {
		ReadStringTable(tableidx, i, buf, sizeof(buf));
		
		if (StrEqual(buf, str)) {
			return i;
		}
	}
	
	return INVALID_STRING_INDEX;
} 

void RebaseItemsGame()
{
    LogMessage("Rebase `items_game.txt`");

    Profiler profiler = new Profiler();
    profiler.Start();

    Dynamic dItemsGame = Dynamic();
    dItemsGame.ReadKeyValues("scripts/items/items_game.txt", PLATFORM_MAX_PATH, ReadDynamicKeyValue);
    dItemsGame.GetDynamic("items");
    dItemsGame.GetDynamic("paint_kits");
    dItemsGame.GetDynamic("music_definitions");
    dItemsGame.GetDynamic("item_sets");
    dItemsGame.GetDynamic("sticker_kits");
    dItemsGame.GetDynamic("paint_kits_rarity");
    dItemsGame.GetDynamic("used_by_classes");
    dItemsGame.GetDynamic("attributes");
    dItemsGame.GetDynamic("prefabs");
    dItemsGame.WriteKeyValues("scripts/items/items_game_dynamic.txt", "items_game");
    dItemsGame.Dispose(true);

    profiler.Stop();
    float fTime = profiler.Time;
    delete profiler;

    LogMessage("RebaseItemsGame took %f seconds.", fTime);
}

public Action ReadDynamicKeyValue(Dynamic obj, const char[] member, int depth)
{
    if (depth == 0)
    {
        return Plugin_Continue;
    }
    
    if (depth == 1)
    {
        if (StrEqual(member, "items"))
        {
            return Plugin_Continue;
        }
        else if (StrEqual(member, "paint_kits"))
        {
            return Plugin_Continue;
        }
        else if (StrEqual(member, "music_definitions"))
        {
            return Plugin_Continue;
        }
        else if (StrEqual(member, "item_sets"))
        {
            return Plugin_Continue;
        }
        else if (StrEqual(member, "sticker_kits"))
        {
            return Plugin_Continue;
        }
        else if (StrEqual(member, "paint_kits_rarity"))
        {
            return Plugin_Continue;
        }
        else if (StrEqual(member, "used_by_classes"))
        {
            return Plugin_Continue;
        }
        else if (StrEqual(member, "attributes"))
        {
            return Plugin_Continue;
        }
        else if (StrEqual(member, "prefabs"))
        {
            return Plugin_Continue;
        }
        else
        {
            return Plugin_Stop;
        }
    }
    
    return Plugin_Continue;
}

void ConvertResourceFile(const char[] language)
{
    Profiler profiler = new Profiler();
    profiler.Start();

    LogMessage("Converting `csgo_%s.txt` to UTF-8", language);

    char sOriginal[PLATFORM_MAX_PATH + 1];
    Format(sOriginal, sizeof(sOriginal), "resource/csgo_%s.txt", language);

    char sModified[PLATFORM_MAX_PATH + 1];
    Format(sModified, sizeof(sModified), "resource/csgo_%s.txt.utf8", language);

    File fiOriginal = OpenFile(sOriginal, "rb");
    File fiModified = OpenFile(sModified, "wb");
    
    int iBytes;
    int iBuffer[4096];
    
    fiOriginal.Read(iBuffer, 1, 2);
    
    int iByte = 0;
    int iLasteByte = 0;
    
    while ((iBytes = fiOriginal.Read(iBuffer, sizeof(iBuffer), 2)) != 0)
    {
        for (int i = 0; i < iBytes; i++)
        {
            iByte = iBuffer[i];
            if (iByte > 255)
                iBuffer[i] = 32;
            
            if (iLasteByte == 92 && iByte == 34)
            {
                iBuffer[i-1] = 32;
                iBuffer[i] = 39;
            }
            
            iLasteByte = iBuffer[i];
        }
        fiModified.Write(iBuffer, iBytes, 1);
    }
    
    delete fiOriginal;
    delete fiModified;

    profiler.Stop();
    float fTime = profiler.Time;
    delete profiler;

    LogMessage("ConvertResourceFile took %f seconds.", fTime);
}
