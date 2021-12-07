#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#include <tf2items>
#include <tf2attributes>

#define PLUGIN_VERSION "Beta 2"

public Plugin:myinfo = {
	name = "Custom Weapons 3",
	author = "MasterOfTheXP (original cw2 developer), Theray070696 (rewrote cw2 into cw3)",
	description = "Allows players to create and use custom-made weapons.",
	version = PLUGIN_VERSION,
	url = "http://mstr.ca/"
};

#define MAX_STEAMIDS_PER_WEAPON 5    // How many people's steamIDs can be listed on a weapon to give Self-Made quality to
#define MAX_STEAMAUTH_LENGTH    21
#define MAX_COMMUNITYID_LENGTH  18

// TF2 Weapon qualities
enum 
{
	TFQual_None = -1,       // Probably should never actually set an item's quality to this
	TFQual_Normal = 0,
	TFQual_NoInspect = 0,   // Players cannot see your attributes
	TFQual_Rarity1,
	TFQual_Genuine = 1,
	TFQual_Rarity2,
	TFQual_Level = 2,       //  Same color as "Level # Weapon" text in description
	TFQual_Vintage,
	TFQual_Rarity3,         //  Is actually 4 - sort of brownish
	TFQual_Rarity4,
	TFQual_Unusual = 5,
	TFQual_Unique,
	TFQual_Community,
	TFQual_Developer,
	TFQual_Selfmade,
	TFQual_Customized,
	TFQual_Strange,
	TFQual_Completed,
	TFQual_Haunted,         //  13
	TFQual_Collectors,
	TFQual_Decorated
}

enum (<<= 1)
{
	EF_BONEMERGE = (1 << 0),    // Merges bones of names shared with a parent entity to the position and direction of the parent's.
	EF_BRIGHTLIGHT,             // Emits a dynamic light of RGB(250,250,250) and a random radius of 400 to 431 from the origin.
	EF_DIMLIGHT,                // Emits a dynamic light of RGB(100,100,100) and a random radius of 200 to 231 from the origin.
	EF_NOINTERP,                // Don't interpolate on the next frame.
	EF_NOSHADOW,                // Don't cast a shadow. To do: Does this also apply to shadow maps?
	EF_NODRAW,                  // Entity is completely ignored by the client. Can cause prediction errors if a player proceeds to collide with it on the server.
	EF_NORECEIVESHADOW,         // Don't receive dynamic shadows.
	EF_BONEMERGE_FASTCULL,      // For use with EF_BONEMERGE. If set, the entity will use its parent's origin to calculate whether it is visible; if not set, it will set up parent's bones every frame even if the parent is not in the PVS.
	EF_ITEM_BLINK,              // Blink an item so that the user notices it. Added for Xbox 1, and really not very subtle.
	EF_PARENT_ANIMATES          // Assume that the parent entity is always animating. Causes it to realign every frame.
}

enum (<<= 1) // SolidFlags_t
{
	FSOLID_CUSTOMRAYTEST  = (1 << 0),   // Ignore solid type + always call into the entity for ray tests
	FSOLID_CUSTOMBOXTEST,               // Ignore solid type + always call into the entity for swept box tests
	FSOLID_NOT_SOLID,                   // Are we currently not solid?
	FSOLID_TRIGGER,                     // This is something may be collideable but fires touch functions
										// even when it's not collideable (when the FSOLID_NOT_SOLID flag is set)
	FSOLID_NOT_STANDABLE,               // You can't stand on this
	FSOLID_VOLUME_CONTENTS,             // Contains volumetric contents (like water)
	FSOLID_FORCE_WORLD_ALIGNED,         // Forces the collision rep to be world-aligned even if it's SOLID_BSP or SOLID_VPHYSICS
	FSOLID_USE_TRIGGER_BOUNDS,          // Uses a special trigger bounds separate from the normal OBB
	FSOLID_ROOT_PARENT_ALIGNED,         // Collisions are defined in root parent's local coordinate space
	FSOLID_TRIGGER_TOUCH_DEBRIS,        // This trigger will touch debris objects

	FSOLID_MAX_BITS = 10
};

/*
	m_collisiongroup

	* Generally I only see the following get used for TF2
	1  = No collide with anything but the world itself. Prevents map trigger_ entities from firing Touch outputs.
	2  = No collide with players, certain projectiles, airblast, - But bullets/hitscan still collide
	5  = Normal
	10 = No collide with players, certain projectiles, airblast, bullets. Does not prevent map trigger_ outputs.
*/
#if !defined _smlib_included
enum // Collision_Group_t in const.h
{
	COLLISION_GROUP_NONE  = 0,
	COLLISION_GROUP_DEBRIS,         // Collides with nothing but world and static stuff
	COLLISION_GROUP_DEBRIS_TRIGGER, // Same as debris, but hits triggers
	COLLISION_GROUP_INTERACTIVE_DEBRIS, // Collides with everything except other interactive debris or debris
	COLLISION_GROUP_INTERACTIVE,    // Collides with everything except interactive debris or debris
	COLLISION_GROUP_PLAYER,
	COLLISION_GROUP_BREAKABLE_GLASS,
	COLLISION_GROUP_VEHICLE,
	COLLISION_GROUP_PLAYER_MOVEMENT,  // For HL2, same as Collision_Group_Player, for
										// TF2, this filters out other players and CBaseObjects
	COLLISION_GROUP_NPC,            // Generic NPC group
	COLLISION_GROUP_IN_VEHICLE,     // for any entity inside a vehicle
	COLLISION_GROUP_WEAPON,         // for any weapons that need collision detection
	COLLISION_GROUP_VEHICLE_CLIP,   // vehicle clip brush to restrict vehicle movement
	COLLISION_GROUP_PROJECTILE,     // Projectiles!
	COLLISION_GROUP_DOOR_BLOCKER,   // Blocks entities not permitted to get near moving doors
	COLLISION_GROUP_PASSABLE_DOOR,  // ** sarysa TF2 note: Must be scripted, not passable on physics prop (Doors that the player shouldn't collide with)
	COLLISION_GROUP_DISSOLVING,     // Things that are dissolving are in this group
	COLLISION_GROUP_PUSHAWAY,       // ** sarysa TF2 note: I could swear the collision detection is better for this than NONE. (Nonsolid on client and server, pushaway in player code)

	COLLISION_GROUP_NPC_ACTOR,      // Used so NPCs in scripts ignore the player.
	COLLISION_GROUP_NPC_SCRIPTED,   // USed for NPCs in scripts that should not collide with each other

	LAST_SHARED_COLLISION_GROUP
};
#endif

new Handle:aItems[10][5];
new Handle:fOnWeaponGive;
new Handle:fOnWeaponEntCreated;
new Handle:fOnWeaponSwitch;

new TFClassType:BrowsingClass[MAXPLAYERS + 1];
new BrowsingSlot[MAXPLAYERS + 1];
new LookingAtItem[MAXPLAYERS + 1];
new Handle:hEquipTimer[MAXPLAYERS + 1];
new Handle:hBotEquipTimer[MAXPLAYERS + 1];
new bool:InRespawnRoom[MAXPLAYERS + 1];
new SavedWeapons[MAXPLAYERS + 1][10][5];
new Handle:hSavedWeapons[MAXPLAYERS + 1][10][5];
new bool:OKToEquipInArena[MAXPLAYERS + 1];

new g_iEntRefOfCustomWearable[MAXPLAYERS + 1][5];
new g_iWeaponOfExtraWearable[2049];
new bool:g_bHasExtraWearable[2049];

new g_iTheWeaponSlotIWasLastHitBy[MAXPLAYERS + 1] = {-1,...};

new bool:IsCustom[2049];

new String:WeaponName[MAXPLAYERS + 1][5][64];
new String:WeaponDescription[MAXPLAYERS + 1][5][512];

new Handle:CustomConfig[2049];

new Handle:cvarEnabled;
new Handle:cvarOnlyInSpawn;
new Handle:cvarArenaSeconds;
new Handle:cvarBots;
new Handle:cvarMenu;
new Handle:cvarSetHealth;
new Handle:cvarOnlyTeam;

new bool:roundRunning = true, Float:arenaEquipUntil;
new weaponcount, modulecount;

// TODO: Delete this once the wearables plugin is released!
// [
new tiedEntity[2049]; // Entity to tie the wearable to.
new wearableOwner[2049]; // Who owns this wearable.
new bool:onlyVisIfActive[2049]; // NOT "visible weapon". If true, this wearable is only shown if the weapon is active.
new bool:hasWearablesTied[2049]; // If true, this entity has (or did have) at least one wearable tied to it.

new bool:g_bSdkStarted = false;
new Handle:g_hSdkEquipWearable;
// ]

new bool:NativeControl = false;

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	fOnWeaponGive = CreateGlobalForward("CW3_OnWeaponSpawned", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	fOnWeaponEntCreated = CreateGlobalForward("CW3_OnWeaponEntCreated", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Any, Param_Any);
	fOnWeaponSwitch = CreateGlobalForward("CW3_OnWeaponSwitch", ET_Ignore, Param_Cell, Param_Cell);
	
	CreateNative("CW3_GetClientWeapon", Native_GetClientWeapon);
	CreateNative("CW3_GetWeaponConfig", Native_GetWeaponConfig);
	CreateNative("CW3_IsCustom", Native_IsCustom);
	CreateNative("CW3_GetClientWeaponName", Native_GetClientWeaponName);
	
	CreateNative("CW3_EquipItem", Native_EquipItem);
	CreateNative("CW3_EquipItemByIndex", Native_EquipItemIndex);
	CreateNative("CW3_EquipItemByName", Native_EquipItemName);
	
	CreateNative("CW3_GetNumItems", Native_GetNumItems);
	CreateNative("CW3_GetItemConfigByIndex", Native_GetItemConfig);
	CreateNative("CW3_GetItemNameByIndex", Native_GetItemName);
	CreateNative("CW3_FindItemByName", Native_FindItemByName);
	
	CreateNative("CW3_ControlCW3", Native_ControlCW3);
	
	RegPluginLibrary("cw3");
	return APLRes_Success;
}

public OnPluginStart()
{
	RegAdminCmd("sm_custom", Command_Custom, 0);
	RegAdminCmd("sm_cus", Command_Custom, 0);
	RegAdminCmd("sm_c", Command_Custom, 0);
	
	cvarEnabled = CreateConVar("sm_cw3_enable", "1", "Enable Custom Weapons. When set to 0, custom weapons will be removed from all players.");
	cvarOnlyInSpawn = CreateConVar("sm_cw3_onlyinspawn", "1", "Custom weapons can only be equipped from within a spawn room.");
	cvarArenaSeconds = CreateConVar("sm_cw3_arena_time", "20", "Time, in seconds, after spawning in Arena, that players can still equip custom weapons.");
	cvarBots = CreateConVar("sm_cw3_bots", "0.15", "Percent chance, for each slot, that bots will equip a custom weapon each time they spawn.");
	cvarMenu = CreateConVar("sm_cw3_menu", "1", "Clients are allowed to say /custom to equip weapons manually. Set to 0 to disable manual weapon selection without disabling the entire plugin.");
	cvarSetHealth = CreateConVar("sm_cw3_sethealth", "1", "When a custom weapon is equipped, the user's health will be set to their maximum.");
	cvarOnlyTeam = CreateConVar("sm_cw3_onlyteam", "0", "If non-zero, custom weapons can only be equipped by one team; 2 = RED, 3 = BLU.");
	CreateConVar("sm_cw3_version", PLUGIN_VERSION, "Change anything you want, but please don't change this!");
	
	HookEvent("post_inventory_application", Event_Resupply);
	HookEvent("player_hurt", Event_Hurt);
	HookEvent("player_death", Event_Death, EventHookMode_Pre);
	HookEvent("teamplay_round_start", Event_RoundStart);
	HookEvent("teamplay_round_win", Event_RoundEnd);
	HookEvent("teamplay_round_stalemate", Event_RoundEnd);
	
	TF2_SdkStartup();
	
	CreateTimer(1.0, Timer_OneSecond, _, TIMER_REPEAT);
	
	if (IsValidEntity(0)) Event_RoundStart(INVALID_HANDLE, "teamplay_round_start", false);
	
	if(!NativeControl)
	{
		PrintToChatAll("[SM] Custom Weapons 3 has been updated.\n Please use /c and a resupply locker to re-equip.");
	}
}

public OnClientPostAdminCheck(client)
{
	BrowsingClass[client] = TFClass_Unknown;
	BrowsingSlot[client] = 0;
	LookingAtItem[client] = 0;
	hEquipTimer[client] = INVALID_HANDLE;
	hBotEquipTimer[client] = INVALID_HANDLE;
	InRespawnRoom[client] = false;
	OKToEquipInArena[client] = false;
	for (new class = 0; class <= _:TFClass_Engineer; class++)
	{
		for (new slot = 0; slot <= 4; slot++)
		{
			SavedWeapons[client][class][slot] = -1;
			hSavedWeapons[client][class][slot] = INVALID_HANDLE;
		}
	}
	
	SDKHook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitch);
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public OnMapStart()
{
	for (new i = 1; i <= MaxClients; i++) // MaxClients is only guaranteed to be initialized by the time OnMapStart() fires.
	{
		if (IsClientInGame(i))
		{
			OnClientPostAdminCheck(i);
		}
	}
	
	new String:Root[PLATFORM_MAX_PATH];
	weaponcount = 0, modulecount = 0;
	BuildPath(Path_SM, Root, sizeof(Root), "configs/customweapons");
	if (!DirExists(Root)) SetFailState("Custom Weapons' weapon directory (%s) does not exist! Would you kindly install it?", Root);
	new Handle:hDir = OpenDirectory(Root), String:FileName[PLATFORM_MAX_PATH], FileType:type;
	for (new TFClassType:class = TFClass_Scout; class <= TFClass_Engineer; class++)
	{
		for (new slot = 0; slot <= 4; slot++)
		{
			if (INVALID_HANDLE == aItems[class][slot]) aItems[class][slot] = CreateArray();
			else ClearArray(aItems[class][slot]);
		}
	}
	while ((ReadDirEntry(hDir, FileName, sizeof(FileName), type)))
	{
		if (FileType_File != type) continue;
		Format(FileName, sizeof(FileName), "%s/%s", Root, FileName);
		new Handle:hFile = CreateKeyValues("Whyisthisneeded");
		if (!FileToKeyValues(hFile, FileName))
		{
			PrintToServer("[Custom Weapons 3] WARNING! Something seems to have gone wrong with opening %s. It won't be added to the weapons list.", FileName);
			CloseHandle(hDir);
			continue;
		}
		if (!KvJumpToKey(hFile, "classes"))
		{
			PrintToServer("[Custom Weapons 3] WARNING! Weapon config %s does not have any classes marked as being able to use the weapon.", FileName);
			CloseHandle(hDir);
			continue;
		}
		new numClasses;
		for (new TFClassType:class = TFClass_Scout; class <= TFClass_Engineer; class++)
		{
			new value;
			switch (class)
			{
				case TFClass_Scout: value = KvGetNum(hFile, "scout", -1);
				case TFClass_Soldier: value = KvGetNum(hFile, "soldier", -1);
				case TFClass_Pyro: value = KvGetNum(hFile, "pyro", -1);
				case TFClass_DemoMan: value = KvGetNum(hFile, "demoman", -1);
				case TFClass_Heavy: value = KvGetNum(hFile, "heavy", -1);
				case TFClass_Engineer: value = KvGetNum(hFile, "engineer", -1);
				case TFClass_Medic: value = KvGetNum(hFile, "medic", -1);
				case TFClass_Sniper: value = KvGetNum(hFile, "sniper", -1);
				case TFClass_Spy: value = KvGetNum(hFile, "spy", -1);
			}
			if (value == -1) continue;
			PushArrayCell(aItems[class][value], hFile);
			numClasses++;
		}
		if (!numClasses)
		{
			PrintToServer("[Custom Weapons 3] WARNING! Weapon config %s does not have any classes marked as being able to use the weapon.", FileName);
			CloseHandle(hDir);
			continue;
		}
		
		weaponcount++;
	}
	
	CloseHandle(hDir);
	
	if (!weaponcount)
		PrintToServer("[Custom Weapons 3] WARNING! You don't have any custom weapons installed! You should download some from https://forums.alliedmods.net/showthread.php?t=236242 or make your own.");
	
	new String:Dir[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, Dir, sizeof(Dir), "plugins/cw3/modules");
	if (!DirExists(Dir)) PrintToServer("[Custom Weapons 3] Warning! Custom Weapons' module directory (%s) does not exist! You'll be limited to just stock config options, which is boring.", Root);
	else {
	
	hDir = OpenDirectory(Dir);
	while (ReadDirEntry(hDir, FileName, sizeof(FileName), type))
	{
		if (FileType_File != type) continue;
		if (StrContains(FileName, ".smx") == -1) continue;
		Format(FileName, sizeof(FileName), "cw3/modules/%s", FileName);
		ServerCommand("sm plugins load %s", FileName);
		modulecount++;
	}
	CloseHandle(hDir); }
	
	PrintToServer("[Custom Weapons 3] Custom Weapons 3 loaded successfully with %i weapons, %i modules.", weaponcount, modulecount);
}

public OnPluginEnd()
{
	RemoveAllCustomWeapons(); // "Your custom weapons have been removed because the Custom Weapons plugin is unloading."

	new String:Dir[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, Dir, sizeof(Dir), "plugins/cw3/modules");
	if (!DirExists(Dir)) PrintToServer("[Custom Weapons 3] WARNING! Custom Weapons' module directory (%s) does not exist, so any running attribute modules will not be unloaded.", Dir);
	else {
		new Handle:hDir = OpenDirectory(Dir), String:FileName[PLATFORM_MAX_PATH], FileType:type;
		while (ReadDirEntry(hDir, FileName, sizeof(FileName), type))
		{
			if (FileType_File != type) continue;
			if (StrContains(FileName, ".smx") == -1) continue;
			Format(FileName, sizeof(FileName), "cw3/modules/%s", FileName);
			ServerCommand("sm plugins unload %s", FileName);
		}
		CloseHandle(hDir); }
}

public Action:Command_Custom(client, args)
{
	if (!client)
	{
		PrintToServer("[Custom Weapons 3] Custom Weapons is loaded with %i weapons, %i modules.", weaponcount, modulecount);
		return Plugin_Handled;
	}
	
	if (args == 1 && CheckCommandAccess(client, "", ADMFLAG_ROOT, true)) // Allows server owner to reload the plugin dynamically
	{
		decl String:szOption[7];
		GetCmdArgString(szOption, sizeof(szOption));
		if (StrEqual(szOption, "reload"))
		{
			ReplyToCommand(client, "[CW3] Reloading main plugin, all modules and attribute plugins.");
			ServerCommand("sm plugins reload cw3");
			return Plugin_Handled;
		}
	}

	CustomMainMenu(client);
	return Plugin_Handled;
}

stock CustomMainMenu(client)
{
	if (NativeControl || !GetConVarBool(cvarMenu)) return;
	new Handle:menu = CreateMenu(CustomMainHandler);
	
	new counts[5];
	new _:class;
	if (IsPlayerAlive(client)) class = _:TF2_GetPlayerClass(client);
	else class = GetEntProp(client, Prop_Send, "m_iDesiredPlayerClass");
	
	SetMenuTitle(menu, "Custom Weapons 3 Beta");
	
	for (new iWeaponSlot = 0; iWeaponSlot < 5; iWeaponSlot++)
	{
		counts[iWeaponSlot] = GetArraySize(aItems[class][iWeaponSlot]);
		if (counts[iWeaponSlot]) // If there are weapons for this slot, add a menu select for them.
		{
			switch (iWeaponSlot)
			{
				case 0: AddMenuItem(menu, "0", "- Primary -");   // First string is the weapon slot it applies to, second string is what's displayed in the menu.
				case 1: AddMenuItem(menu, "1", "- Secondary -"); // This is necessary because it's possible to have custom primaries, but no custom secondaries.
				case 2: AddMenuItem(menu, "2", "- Melee -");
				case 3:
				{
					switch (class)
					{
						case TFClass_Engineer:  AddMenuItem(menu, "3", "- Build PDA -");
						case TFClass_Spy:       AddMenuItem(menu, "3", "- Disguise Kit -");
					}
				}
				case 4:
				{
					switch (class)
					{
						case TFClass_Engineer:  AddMenuItem(menu, "4", "- Destroy PDA -");
						case TFClass_Spy:       AddMenuItem(menu, "4", "- Cloak -");
					}
				}
			}
		}
	}
	
	//AddMenuItem(menu, "5", "- Recommended Loadouts -");
	
	/*for (new i = 0; i < 5; i++)
	{
		counts[i] = GetArraySize(aItems[class][i]);
		if (counts[i])
		{
			switch (i)
			{
				case 0: SetMenuTitle(menu, "Custom Weapons 3 Indev\n- Primary -");
				case 1: SetMenuTitle(menu, "Custom Weapons 3 Indev\n- Secondary -");
				case 2: SetMenuTitle(menu, "Custom Weapons 3 Indev\n- Melee -");
				case 3: SetMenuTitle(menu, "Custom Weapons 3 Indev\n- PDA -");
				case 4: SetMenuTitle(menu, "Custom Weapons 3 Indev\n- PDA 2 -");
			}
			break;
		}
	}
	
	for (new slot = 0; slot <= 4; slot++)
	{
		if (!counts[slot]) continue;
		new saved = SavedWeapons[client][class][slot];
		for (new i = 0; i < counts[slot]; i++)
		{
			new Handle:hWeapon = GetArrayCell(aItems[class][slot], i), String:Name[64], String:Index[10], String:flags[64], bool:canUseWeapon = false;
			
			KvRewind(hWeapon);
			KvGetString(hWeapon, "flags", flags, sizeof(flags));
			
			if(StrEqual(flags, ""))
			{
				KvRewind(hWeapon);
				KvGetString(hWeapon, "flag", flags, sizeof(flags));
			}
			
			KvRewind(hWeapon);
			if(KvJumpToKey(hWeapon, "flags") || KvJumpToKey(hWeapon, "flag"))
			{
				new AdminId:adminID = GetUserAdmin(client);
				if(adminID != INVALID_ADMIN_ID)
				{
					new AdminFlag:adminFlags[AdminFlags_TOTAL];
					new flagBits = ReadFlagString(flags);
					FlagBitsToArray(flagBits, adminFlags, AdminFlags_TOTAL);
					
					for(new j = 0; j < AdminFlags_TOTAL; j++)
					{
						if(GetAdminFlag(adminID, adminFlags[j]) && !canUseWeapon)
						{
							canUseWeapon = true;
						}
					}
				} else
				{
					canUseWeapon = false;
				}
			} else
			{
				canUseWeapon = true;
			}
			
			if(!canUseWeapon)
			{
				continue;
			}
			
			KvRewind(hWeapon);
			KvGetSectionName(hWeapon, Name, sizeof(Name));
			if (saved == i) Format(Name, sizeof(Name), "%s ✓", Name);
			Format(Index, sizeof(Index), "%i %i", slot, i);
			if (i == counts[slot]-1 && slot < 4)
			{
				new nextslot;
				for (new j = slot+1; j <= 4; j++)
				{
					if (counts[j])
					{
						nextslot = j;
						break;
					}
				}
				switch (nextslot)
				{
					case 1: Format(Name, sizeof(Name), "%s\n- Secondary -", Name);
					case 2: Format(Name, sizeof(Name), "%s\n- Melee -", Name);
					case 3: Format(Name, sizeof(Name), "%s\n- PDA -", Name);
					case 4: Format(Name, sizeof(Name), "%s\n- PDA 2 -", Name);
				}
			}
			AddMenuItem(menu, Index, Name);
		}
	}*/
	
	if (!GetMenuItemCount(menu))
		PrintToChat(client, "\x01\x07FFA07AThis server doesn't have any custom weapons for your class yet. Sorry!");
	
	BrowsingClass[client] = TFClassType:class;
	SetMenuPagination(menu, MENU_NO_PAGINATION);
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}
public CustomMainHandler(Handle:menu, MenuAction:action, client, item)
{
	if (action == MenuAction_Select)
	{
		if(item == 5)
		{
			PrintToChat(client, "This feature is currently a WiP, sorry!");
			CustomMainMenu(client);
			return;
		}
		
		if (BrowsingClass[client] != TF2_GetPlayerClass(client))
		{
			CustomMainMenu(client);
			return;
		}
		/*new String:sel[20], String:sIdxs[2][10];
		GetMenuItem(menu, item, sel, sizeof(sel));
		ExplodeString(sel, " ", sIdxs, sizeof(sIdxs), sizeof(sIdxs));
		WeaponInfoMenu(client, BrowsingClass[client], StringToInt(sIdxs[0]), StringToInt(sIdxs[1]));*/
		
		new String:szSlot[2];
		GetMenuItem(menu, item, szSlot, sizeof(szSlot));
		new iSlot = StringToInt(szSlot);
		
		WeaponSelectMenu(client, iSlot);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

WeaponSelectMenu(iClient, iSlot)
{
	if(iSlot == -1 || iClient == -1) return;
	
	new counts[5];
	counts[iSlot] = GetArraySize(aItems[BrowsingClass[iClient]][iSlot]);
	
	new Handle:hWeaponSelectMenu = CreateMenu(WeaponSelectHandler);
	
	switch (iSlot)
	{
		case 0: SetMenuTitle(hWeaponSelectMenu, "- Primary Custom Weapons -");   // First string is the weapon slot it applies to, second string is what's displayed in the menu.
		case 1: SetMenuTitle(hWeaponSelectMenu, "- Secondary Custom Weapons -"); // This is necessary because it's possible to have custom primaries, but no custom secondaries.
		case 2: SetMenuTitle(hWeaponSelectMenu, "- Melee Custom Weapons -");
		case 3:
		{
			switch (BrowsingClass[iClient])
			{
				case TFClass_Engineer:  SetMenuTitle(hWeaponSelectMenu, "- Build PDA Custom Weapons -");
				case TFClass_Spy:       SetMenuTitle(hWeaponSelectMenu, "- Disguise Kit Custom Weapons -");
			}
		}
		case 4:
		{
			switch (BrowsingClass[iClient])
			{
				case TFClass_Engineer:  SetMenuTitle(hWeaponSelectMenu, "- Destroy PDA Custom Weapons -");
				case TFClass_Spy:       SetMenuTitle(hWeaponSelectMenu, "- Cloak Custom Weapons -");
			}
		}
	}

	new saved = SavedWeapons[iClient][BrowsingClass[iClient]][iSlot];
	for (new i = 0; i < counts[iSlot]; i++) // Loop through the number of weapons for this slot
	{
		new Handle:hWeapon = GetArrayCell(aItems[BrowsingClass[iClient]][iSlot], i), String:Name[64], String:Index[40];
		KvRewind(hWeapon);
		KvGetSectionName(hWeapon, Name, sizeof(Name)); // Get the name of the weapon
		if (saved == i) Format(Name, sizeof(Name), "%s ✓", Name);
		Format(Index, sizeof(Index), "%i %i", iSlot, i);
		/*if (i == counts[iSlot]-1 && iSlot < 4)
		{
			new nextslot;
			for (new j = iSlot+1; j <= 4; j++)
			{
				if (counts[j])
				{
					nextslot = j;
					break;
				}
			}
			switch (nextslot)
			{
				case 1: Format(Name, sizeof(Name), "%s\n- Secondary -", Name);
				case 2: Format(Name, sizeof(Name), "%s\n- Melee -", Name);
				case 3: Format(Name, sizeof(Name), "%s\n- PDA -", Name);
				case 4: Format(Name, sizeof(Name), "%s\n- PDA 2 -", Name);
			}
		}*/
		AddMenuItem(hWeaponSelectMenu, Index, Name);
	}

	SetMenuExitBackButton(hWeaponSelectMenu, true);

	DisplayMenu(hWeaponSelectMenu, iClient, MENU_TIME_FOREVER);
}

public WeaponSelectHandler(Handle:hMenu, MenuAction:iAction, iClient, iItem)
{
	switch (iAction)
	{
		case MenuAction_Select:
		{
			if (BrowsingClass[iClient] != TF2_GetPlayerClass(iClient))
			{
				CustomMainMenu(iClient);
				return;
			}
			new String:sel[40], String:sIdxs[2][40];
			GetMenuItem(hMenu, iItem, sel, sizeof(sel));

			if (StringToInt(sel) == -1) // Chose to return to Main menu.
			{
				CustomMainMenu(iClient);
				return;
			}

			ExplodeString(sel, " ", sIdxs, sizeof(sIdxs), sizeof(sIdxs[]));
			WeaponInfoMenu(iClient, BrowsingClass[iClient], StringToInt(sIdxs[0]), StringToInt(sIdxs[1]));
		}
		case MenuAction_End:
		{
			CloseHandle(hMenu);
		}
		case MenuAction_Cancel:
		{
			if (iItem == MenuCancel_ExitBack)
			{
				CustomMainMenu(iClient);
			}
		}
	}
}

stock WeaponInfoMenu(client, TFClassType:class, slot, weapon, Float:delay = -1.0)
{
	if (!GetConVarBool(cvarMenu)) return;
	if (delay != -1.0)
	{
		new Handle:data;
		CreateDataTimer(delay, Timer_WeaponInfoMenu, data, TIMER_FLAG_NO_MAPCHANGE);
		WritePackCell(data, GetClientUserId(client));
		WritePackCell(data, _:class);
		WritePackCell(data, slot);
		WritePackCell(data, weapon);
		ResetPack(data);
		return;
	}
	if (class != TF2_GetPlayerClass(client))
	{
		CustomMainMenu(client);
		return;
	}
	new Handle:menu = CreateMenu(WeaponInfoHandler);
	new Handle:hWeapon = GetArrayCell(aItems[class][slot], weapon);
	new String:Name[64], String:description[512];
	KvRewind(hWeapon);
	KvGetSectionName(hWeapon, Name, sizeof(Name));
	KvSetEscapeSequences(hWeapon, true);
	KvGetString(hWeapon, "description", description, sizeof(description));
	KvSetEscapeSequences(hWeapon, false);
	ReplaceString(description, sizeof(description), "\\n", "\n");
	SetMenuTitle(menu, "%s\n \n%s\n ", Name, description);
	//AddMenuItem(menu, "", "Use", ITEMDRAW_DEFAULT);
	if (IsPlayerAlive(client))
	{
		if (hWeapon != hSavedWeapons[client][class][slot])
		{
			new bool:equipped;
			for (new i = 0; i <= 2; i++)
			{
				new wep = GetPlayerWeaponSlot(client, i);
				if (wep == -1) continue;
				if (!IsCustom[wep]) continue;
				if (CustomConfig[wep] != hWeapon) continue;
				equipped = true;
				break;
			}
			if (equipped) AddMenuItem(menu, "", "Save", ITEMDRAW_DEFAULT);
			else AddMenuItem(menu, "", "Save & Equip", ITEMDRAW_DEFAULT);
		}
		else AddMenuItem(menu, "", "Unequip", ITEMDRAW_DEFAULT);
	}
	else
	{
		if (hWeapon != hSavedWeapons[client][class][slot]) AddMenuItem(menu, "", "Save", ITEMDRAW_DEFAULT);
		else AddMenuItem(menu, "", "Unequip", ITEMDRAW_DEFAULT);
	}
	AddMenuItem(menu, "", "", ITEMDRAW_SPACER);
	AddMenuItem(menu, "", "Prev Weapon", weapon ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	AddMenuItem(menu, "", "Next Weapon", weapon != GetArraySize(aItems[class][slot])-1 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	BrowsingClass[client] = class;
	BrowsingSlot[client] = slot;
	LookingAtItem[client] = weapon;
	strcopy(WeaponName[client][slot], sizeof(Name), Name);
	strcopy(WeaponDescription[client][slot], sizeof(description), description);
}

public WeaponInfoHandler(Handle:menu, MenuAction:action, client, item)
{
	if (action == MenuAction_Cancel && item == MenuCancel_ExitBack)
	{
		CustomMainMenu(client);
	}
	else if (action == MenuAction_Select)
	{
		switch (item)
		{
			/*case 0:
			{
				new TFClassType:class = TF2_GetPlayerClass(client);
				new onlyteam = GetConVarInt(cvarOnlyTeam);
				
				if (!IsPlayerAlive(client))
				{
					PrintToChat(client, "You must be alive in order to equip custom weapons.");
//					return;
				}
				else if (!InRespawnRoom[client] && GetConVarBool(cvarOnlyInSpawn) && !IsArenaActive())
				{
					PrintToChat(client, "You must be in a resupply room order to equip custom weapons.");
//					return;
				}
				else if (IsArenaActive() && (!OKToEquipInArena[client] || arenaEquipUntil < GetTickedTime()))
				{
					PrintToChat(client, "You can only equip custom weapons immediately after spawning in Arena Mode.");
//					return;
				}
				else if (onlyteam && onlyteam != GetClientTeam(client))
				{
					PrintToChat(client, "Your team can't equip custom weapons.");
//					return;
				}
				else if (DoesClientAlreadyHaveCustomWeapon(client, GetArrayCell(aItems[class][BrowsingSlot[client]], LookingAtItem[client])))
				{
//					PrintToChat(client, "You already have that weapon equipped.");
				}
				else GiveCustomWeaponByIndex(client, class, BrowsingSlot[client], LookingAtItem[client]);
				WeaponInfoMenu(client, class, BrowsingSlot[client], LookingAtItem[client], 0.2);
			}
			case 1:*/
			case 0:
			{
				new TFClassType:class = BrowsingClass[client];
				new slot = BrowsingSlot[client];
				new index = LookingAtItem[client];
				new onlyteam = GetConVarInt(cvarOnlyTeam);
				new Handle:hWeaponConfig = GetArrayCell(aItems[class][slot], index);
				
				if(hWeaponConfig != INVALID_HANDLE)
				{
					new String:adminFlagsStr[10], bool:canUseWeapon;
					KvRewind(hWeaponConfig);
					KvGetString(hWeaponConfig, "flags", adminFlagsStr, sizeof(adminFlagsStr));
					
					if(StrEqual(adminFlagsStr, ""))
					{
						KvRewind(hWeaponConfig);
						KvGetString(hWeaponConfig, "flag", adminFlagsStr, sizeof(adminFlagsStr));
					}
					
					KvRewind(hWeaponConfig);
					if(KvJumpToKey(hWeaponConfig, "flags") || KvJumpToKey(hWeaponConfig, "flag"))
					{
						new AdminId:adminID = GetUserAdmin(client);
						if(adminID != INVALID_ADMIN_ID)
						{
							new AdminFlag:adminFlags[AdminFlags_TOTAL];
							new flagBits = ReadFlagString(adminFlagsStr);
							FlagBitsToArray(flagBits, adminFlags, AdminFlags_TOTAL);
							
							for(new j = 0; j < AdminFlags_TOTAL; j++)
							{
								if(GetAdminFlag(adminID, adminFlags[j]) && !canUseWeapon)
								{
									canUseWeapon = true;
								}
							}
						} else
						{
							canUseWeapon = false;
						}
					} else
					{
						canUseWeapon = true;
					}
					
					if(!canUseWeapon)
					{
						PrintToChat(client, "[CW3] Sorry! This weapon is restricted so only certain people can use it!");
						return;
					}
				}
				
				if (index != SavedWeapons[client][class][slot])
				{
					SavedWeapons[client][class][slot] = index;
					hSavedWeapons[client][class][slot] = GetArrayCell(aItems[class][slot], index);
					new bool:equipped, wep = GetPlayerWeaponSlot(client, slot);
					if (wep > -1)
					{
						if (IsCustom[wep] && CustomConfig[wep] == hSavedWeapons[client][class][slot])
							equipped = true;
					} // This might be confusing, but here we go...
					if (!equipped && IsPlayerAlive(client) && // They don't have it equipped, they're alive, and...
					(!onlyteam || onlyteam == GetClientTeam(client)) && // "OnlyTeam" is off, or their team is the only team that can equip, and...
					(InRespawnRoom[client] || !GetConVarBool(cvarOnlyInSpawn) || // they're in a respawn room, OR they can equip weapons whenever, OR...
					(IsArenaActive() && OKToEquipInArena[client] && arenaEquipUntil >= GetTickedTime()))) // it's the beginning of an Arena round.
						GiveCustomWeaponByIndex(client, class, slot, index);
				}
				else
				{
					SavedWeapons[client][class][slot] = -1;
					hSavedWeapons[client][class][slot] = INVALID_HANDLE;
					WeaponName[client][slot][0] = '\0';
					WeaponDescription[client][slot][0] = '\0';
				}
				WeaponInfoMenu(client, class, slot, index, 0.2);
			}
			case 2: WeaponInfoMenu(client, BrowsingClass[client], BrowsingSlot[client], LookingAtItem[client] - 1);
			case 3: WeaponInfoMenu(client, BrowsingClass[client], BrowsingSlot[client], LookingAtItem[client] + 1);
		}
	}
	else if (action == MenuAction_End) CloseHandle(menu);
}

public Action:Timer_WeaponInfoMenu(Handle:timer, Handle:data)
{
	new client = GetClientOfUserId(ReadPackCell(data));
	if (!client) return;
	new TFClassType:class = TFClassType:ReadPackCell(data);
	new slot = ReadPackCell(data);
	new weapon = ReadPackCell(data);
	WeaponInfoMenu(client, class, slot, weapon);
}

stock GiveCustomWeaponByIndex(client, TFClassType:class, slot, weapon, bool:makeActive = true, bool:checkClass = true)
{
	if (checkClass && class != TF2_GetPlayerClass(client)) return -1;
	new Handle:hConfig = GetArrayCell(aItems[class][slot], weapon);
	if (hConfig == INVALID_HANDLE)
	{
		ThrowError("Weapon %i in slot %i for class %i is invalid", weapon, slot, class);
		return -1;
	}
	return GiveCustomWeapon(client, hConfig, makeActive);
}

stock GiveCustomWeapon(client, Handle:hConfig, bool:makeActive = true)
{
	if(!IsValidClient(client)) return -1;
	
	new TFClassType:class = TF2_GetPlayerClass(client);
	
	new String:adminFlagsStr[10], bool:canUseWeapon;
	KvRewind(hConfig);
	KvGetString(hConfig, "flags", adminFlagsStr, sizeof(adminFlagsStr));
	
	if(StrEqual(adminFlagsStr, ""))
	{
		KvRewind(hConfig);
		KvGetString(hConfig, "flag", adminFlagsStr, sizeof(adminFlagsStr));
	}
	
	KvRewind(hConfig);
	if(KvJumpToKey(hConfig, "flags") || KvJumpToKey(hConfig, "flag"))
	{
		new AdminId:adminID = GetUserAdmin(client);
		if(adminID != INVALID_ADMIN_ID)
		{
			new AdminFlag:adminFlags[AdminFlags_TOTAL];
			new flagBits = ReadFlagString(adminFlagsStr);
			FlagBitsToArray(flagBits, adminFlags, AdminFlags_TOTAL);
			
			for(new j = 0; j < AdminFlags_TOTAL; j++)
			{
				if(GetAdminFlag(adminID, adminFlags[j]) && !canUseWeapon)
				{
					canUseWeapon = true;
				}
			}
		} else
		{
			canUseWeapon = false;
		}
	} else
	{
		canUseWeapon = true;
	}
	
	if(!canUseWeapon)
	{
		return -1;
	}
	
	KvRewind(hConfig);
	
	new String:name[96], String:baseClass[64], baseIndex, itemQuality, itemLevel, String:szSteamIDList[(MAX_STEAMAUTH_LENGTH * MAX_STEAMIDS_PER_WEAPON) + (MAX_STEAMIDS_PER_WEAPON * 2)], bool:forcegen, mag, ammo, metal;
	
	KvGetSectionName(hConfig, name, sizeof(name));
	KvGetString(hConfig, "baseclass", baseClass, sizeof(baseClass));
	baseIndex = KvGetNum(hConfig, "baseindex", -1);
	itemQuality = KvGetNum(hConfig, "quality", TFQual_Customized);
	itemLevel = KvGetNum(hConfig, "level", -1);
	KvGetString(hConfig, "steamids", szSteamIDList, sizeof(szSteamIDList));
	forcegen = bool:KvGetNum(hConfig, "forcegen", _:false);
	mag = KvGetNum(hConfig, "mag", -1);
	if (mag == -1)
	{
		mag = KvGetNum(hConfig, "clip", -1); // add support for using clip instead of magazine
	}
	ammo = KvGetNum(hConfig, "ammo", -1);
	metal = KvGetNum(hConfig, "metal", -1);

	decl String:szExplode[5][MAX_STEAMAUTH_LENGTH]; // SteamIDs are separated by commas,,,,
	ExplodeString(szSteamIDList, ",", szExplode, sizeof(szExplode), sizeof(szExplode[]));

	for (new i = 0; i < MAX_STEAMIDS_PER_WEAPON; i++) // Give selfmade quality to creators of weapons, regardless of whatever quality was set.
	{
		if (IsClientID(client, szExplode[i], GetSteamIdAuthType(szExplode[i])))
		{
			itemQuality = TFQual_Selfmade;
			break;
		}
	}
	
	new slot = -1;
	if (KvJumpToKey(hConfig, "classes"))
	{
		new String:myClass[10];
		TF2_GetPlayerClassString(client, myClass, sizeof(myClass));
		slot = KvGetNum(hConfig, myClass, -1);
		if (slot == -1)
		{
			for (new TFClassType:i = TFClass_Scout; i <= TFClass_Engineer; i++)
			{
				TF2_GetClassString(i, myClass, sizeof(myClass));
				slot = KvGetNum(hConfig, myClass, -1);
				if (slot != -1) break;
			}
		}
		if (slot == -1) ThrowError("Slot could not be determined for weapon \"%s\"", name);
	}
	KvRewind(hConfig);
	
	if (ammo == -1)
	{
		if (KvJumpToKey(hConfig, "ammo-classes"))
		{
			new String:myClass[10];
			TF2_GetPlayerClassString(client, myClass, sizeof(myClass));
			ammo = KvGetNum(hConfig, myClass, -1);
		}
		KvRewind(hConfig);
	}
	
	new bool:bWearable = false;

	if (StrEqual(baseClass, "wearable_demoshield", false))
	{
		bWearable = bool:2;
	}
	else if (StrEqual(baseClass, "wearable", false))
	{
		bWearable = true;
	}
	
	if (!bWearable)
	{
		if (StrEqual(baseClass, "saxxy", false))
		{
			switch (class)
			{
				case TFClass_Scout: Format(baseClass, sizeof(baseClass), "bat");
				case TFClass_Soldier: Format(baseClass, sizeof(baseClass), "shovel");
				case TFClass_DemoMan: Format(baseClass, sizeof(baseClass), "bottle");
				case TFClass_Engineer: Format(baseClass, sizeof(baseClass), "wrench");
				case TFClass_Medic: Format(baseClass, sizeof(baseClass), "bonesaw");
				case TFClass_Sniper: Format(baseClass, sizeof(baseClass), "club");
				case TFClass_Spy: Format(baseClass, sizeof(baseClass), "knife");
				default: Format(baseClass, sizeof(baseClass), "fireaxe");
			}
		}
		else if (StrEqual(baseClass, "shotgun", false))
		{
			switch (class)
			{
				case TFClass_Scout: Format(baseClass, sizeof(baseClass), "scattergun");
				case TFClass_Soldier, TFClass_DemoMan: Format(baseClass, sizeof(baseClass), "shotgun_soldier");
				case TFClass_Pyro: Format(baseClass, sizeof(baseClass), "shotgun_pyro");
				case TFClass_Heavy: Format(baseClass, sizeof(baseClass), "shotgun_hwg");
				default: Format(baseClass, sizeof(baseClass), "shotgun_primary");
			}
		}
		else if (StrEqual(baseClass, "pistol", false) && TFClass_Scout == class)
		{
			Format(baseClass, sizeof(baseClass), "pistol_scout");
		}

		Format(baseClass, sizeof(baseClass), "tf_weapon_%s", baseClass);
	}
	else
	{
		Format(baseClass, sizeof(baseClass), "tf_%s", baseClass);
	}
	
	new flags = OVERRIDE_ALL| OVERRIDE_ATTRIBUTES | PRESERVE_ATTRIBUTES;
	if (forcegen) flags |= FORCE_GENERATION;
	new Handle:hWeapon = TF2Items_CreateItem(flags);
	TF2Items_SetClassname(hWeapon, baseClass);
	TF2Items_SetItemIndex(hWeapon, baseIndex);
	
	if (KvJumpToKey(hConfig, "level")) {
		TF2Items_SetLevel(hWeapon, itemLevel);
	}
	else {
		TF2Items_SetLevel(hWeapon, 1);
	}
	KvRewind(hConfig);

	TF2Items_SetQuality(hWeapon, itemQuality);

	new numAttributes;
	if (KvJumpToKey(hConfig, "attributes"))
	{
		KvGotoFirstSubKey(hConfig);
		do {
			new String:szPlugin[64];
			KvGetString(hConfig, "plugin", szPlugin, sizeof(szPlugin));
			if (!StrEqual(szPlugin, "tf2items", false)) continue;
			
			new String:Att[64], String:Value[64];
			KvGetSectionName(hConfig, Att, sizeof(Att));
			KvGetString(hConfig, "value", Value, sizeof(Value));
			
			TF2Items_SetAttribute(hWeapon, numAttributes++, StringToInt(Att), StringToFloat(Value));
		} while (KvGotoNextKey(hConfig));
	}
	KvRewind(hConfig);
	
	TF2Items_SetNumAttributes(hWeapon, numAttributes);
	
	TF2_RemoveWeaponSlot(client, slot);
	if (!slot || slot == 1) // primary and secondary
	{
		new i = -1;
		while ((i = FindEntityByClassname(i, "tf_wearable*")) != -1)
		{
			if (client != GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity")) continue;
			if (GetEntProp(i, Prop_Send, "m_bDisguiseWearable")) continue;
			if (!slot)
			{
				switch (GetEntProp(i, Prop_Send, "m_iItemDefinitionIndex"))
				{   case 405, 608: TF2_RemoveWearable(client, i);   }
			}
			else
			{
				switch (GetEntProp(i, Prop_Send, "m_iItemDefinitionIndex"))
				{   case 57, 231, 642, 133, 444, 131, 406, 1099, 1144: TF2_RemoveWearable(client, i);   }
			}
		}
	}
	
	new ent = TF2Items_GiveNamedItem(client, hWeapon);
	CloseHandle(hWeapon);
	
	g_iEntRefOfCustomWearable[client][slot] = -1;

	if (bWearable)
	{
		switch (bWearable)
		{
			case 2:
			{
				if (KvJumpToKey(hConfig, "worldmodel"))
				{
					decl String:ModelName[PLATFORM_MAX_PATH];
					KvGetString(hConfig, "modelname", ModelName, sizeof(ModelName));
					if (ModelName[0] != '\0' && FileExists(ModelName, true))
					{
						SetModelIndex(ent, ModelName);
						CreateWearable(client, ModelName, true);
					}
				}
				KvRewind(hConfig);
			}
			case 1:
			{
				if (KvJumpToKey(hConfig, "worldmodel"))
				{
					decl String:ModelName[PLATFORM_MAX_PATH];
					KvGetString(hConfig, "modelname", ModelName, sizeof(ModelName));
					if (ModelName[0] != '\0' && FileExists(ModelName, true))
					{
						SetModelIndex(ent, ModelName);
						g_iEntRefOfCustomWearable[client][slot] = EntIndexToEntRef(ent);
					}
				}
				KvRewind(hConfig);
			}
		}
		TF2_EquipWearable(client, ent);

		ClientCommand(client, "slot3"); // Switch to melee
		OnWeaponSwitch(client, GetPlayerWeaponSlot(client, TFWeaponSlot_Melee));
	}
	else
	{
		EquipPlayerWeapon(client, ent);
	}
	
	if (itemQuality == TFQual_Selfmade && !KvJumpToKey(hConfig, "nosparkle")) // If nosparkle is defined at all, it'll block adding the two attributes - useful if we need to conserve on the 15 attribute limit or if you use attach particle for something else
	{
		TF2Attrib_SetByName(ent, "attach particle effect", 4.0);
		TF2Attrib_SetByName(ent, "selfmade description", 1.0);
	}
	
	if (ammo != -1) SetAmmo_Weapon(ent, ammo);
	if (mag != -1) SetClip_Weapon(ent, mag);
	if (metal != -1) SetEntProp(client, Prop_Data, "m_iAmmo", metal, 4, 3);
	
	KvRewind(hConfig);
	if (KvJumpToKey(hConfig, "backpack"))
	{
		decl String:szModelName[PLATFORM_MAX_PATH];
		KvGetString(hConfig, "modelname", szModelName, sizeof(szModelName));
		if (szModelName[0] != '\0' && FileExists(szModelName, true))
		{
			new iExtraWearable = EquipWearable(client, szModelName, false, 0, false);
			if (iExtraWearable != -1)
			{
				g_iWeaponOfExtraWearable[iExtraWearable] = ent;

				new effects = GetEntProp(iExtraWearable, Prop_Send, "m_fEffects");
				SetEntProp(iExtraWearable, Prop_Send, "m_fEffects", effects & ~EF_NODRAW); // Ensures that it'll be visible
			}

			g_bHasExtraWearable[ent] = true;

			new attachment = KvGetNum(hConfig, "attachment", -1);
			if (attachment > -1)
			{
				SetEntProp(iExtraWearable, Prop_Send, "m_fEffects", 0);
				SetEntProp(iExtraWearable, Prop_Send, "m_iParentAttachment", attachment);
				new Float:offs[3], Float:angOffs[3], Float:scale;
				KvGetVector(hConfig, "pos", offs);
				KvGetVector(hConfig, "ang", angOffs);
				scale = KvGetFloat(hConfig, "scale", 1.0);
				SetEntPropVector(iExtraWearable, Prop_Send, "m_vecOrigin", offs);
				SetEntPropVector(iExtraWearable, Prop_Send, "m_angRotation", angOffs);
				if (scale != 1.0) SetEntPropFloat(iExtraWearable, Prop_Send, "m_flModelScale", scale);
			}

			new m_hExtraWearable = GetEntPropEnt(ent, Prop_Send, "m_hExtraWearable");
			if (IsValidEntity(m_hExtraWearable))
			{
				new replace = KvGetNum(hConfig, "replace", 1);
				if (replace == 1)
				{
					SetEntityRenderMode(m_hExtraWearable, RENDER_TRANSCOLOR);
					SetEntityRenderColor(m_hExtraWearable, 0, 0, 0, 0);
				}
				else if (replace == 2)
				{
					SetEntPropFloat(m_hExtraWearable, Prop_Send, "m_flModelScale", 0.0);
				}
				else if (replace == 3)
				{
					SetEntPropEnt(ent, Prop_Send, "m_hExtraWearable", iExtraWearable);
					TF2_RemoveWearable(client, m_hExtraWearable);
				}
			}
		}
	}
	
	IsCustom[ent] = true;
	CustomConfig[ent] = hConfig;
	
	Call_StartForward(fOnWeaponEntCreated);
	Call_PushCell(ent);
	Call_PushCell(slot);
	Call_PushCell(client);
	Call_PushCell(_:bWearable);
	Call_PushCell(_:makeActive);
	Call_Finish();
	
	if (StrEqual(baseClass, "tf_weapon_sapper", false) || StrEqual(baseClass, "tf_weapon_builder", false))
	{
		SetEntProp(ent, Prop_Send, "m_iObjectType", 3);
		SetEntProp(ent, Prop_Data, "m_iSubType", 3);
	}
	
	if (GetConVarBool(cvarSetHealth))
	{
		CreateTimer(0.1, Timer_SetHealth, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
	
	if(!bWearable)
	{
		if(makeActive && !StrEqual(baseClass, "tf_weapon_invis", false))
		{
			ClientCommand(client, "slot%i", slot+1);
			OnWeaponSwitch(client, ent);
		} else
		{
			OnWeaponSwitch(client, GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon"));
		}
	}
	
	new Action:act = Plugin_Continue;
	Call_StartForward(fOnWeaponGive);
	Call_PushCell(ent);
	Call_PushCell(slot);
	Call_PushCell(client);
	Call_Finish(act);
	
	return ent;
}

public OnWeaponSwitch(client, weapon)
{
	if (!IsValidEntity(weapon)) return;
	
	Call_StartForward(fOnWeaponSwitch);
	Call_PushCell(client);
	Call_PushCell(weapon);
	Call_Finish();
	
	// TODO: Delete this once the wearables plugin is released!
	new i = -1;
	while ((i = FindEntityByClassname(i, "tf_wearable*")) != -1)
	{
		if (!onlyVisIfActive[i]) continue;
		if (client != wearableOwner[i]) continue;
		new effects = GetEntProp(i, Prop_Send, "m_fEffects");
		if (weapon == tiedEntity[i]) SetEntProp(i, Prop_Send, "m_fEffects", effects & ~32);
		else SetEntProp(i, Prop_Send, "m_fEffects", effects |= 32);
	}
}

public Action:Timer_SetHealth(Handle:timer, any:uid)
{
	new client = GetClientOfUserId(uid);
	if (!client) return;
	SetEntityHealth(client, GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMaxHealth", _, client));
}

public OnEntityDestroyed(ent)
{
	if (ent <= 0 || ent > 2048) return;
	IsCustom[ent] = false;
	CustomConfig[ent] = INVALID_HANDLE;
	
	g_iWeaponOfExtraWearable[ent] = -1;
	g_bHasExtraWearable[ent] = false;
	
	// TODO: Delete this once the wearables plugin is released!
	if (ent <= 0 || ent > 2048) return;
	if (hasWearablesTied[ent])
	{   
		new i = -1;
		while ((i = FindEntityByClassname(i, "tf_wearable*")) != -1)
		{
			if (ent != tiedEntity[i]) continue;
			if (IsValidClient(wearableOwner[ent]))
			{
				TF2_RemoveWearable(wearableOwner[ent], i);
			}
			else
			{
				AcceptEntityInput(i, "Kill"); // This can cause graphical glitches
			}
		}
		hasWearablesTied[ent] = false;
	}
	tiedEntity[ent] = 0;
	wearableOwner[ent] = 0;
	onlyVisIfActive[ent] = false;
}

public Action:Event_Resupply(Handle:event, const String:name[], bool:dontBroadcast)
{
	new uid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(uid);
	if (!client) return;
	if (!GetConVarBool(cvarEnabled)) return;
	hEquipTimer[client] = CreateTimer(0.0, Timer_CheckEquip, uid, TIMER_FLAG_NO_MAPCHANGE);
	hBotEquipTimer[client] = CreateTimer(GetRandomFloat(0.0, 1.5), Timer_CheckBotEquip, uid, TIMER_FLAG_NO_MAPCHANGE);
	
	for (new i = 0; i < 5; i++)
	{
		g_iEntRefOfCustomWearable[client][i] = -1;
	}
}

public Action:OnTakeDamage(iVictim, &iAtker, &iInflictor, &Float:flDamage, &iDmgType, &iWeapon, Float:vDmgForce[3], Float:vDmgPos[3], iDmgCustom)
{
	if (0 < iAtker && iAtker <= MaxClients)
	{
		g_iTheWeaponSlotIWasLastHitBy[iVictim] = GetSlotFromPlayerWeapon(iAtker, iWeapon);
	}
	return Plugin_Continue;
}

// Displays a menu describing what weapon the victim was killed by
DisplayDeathMenu(iKiller, iVictim, TFClassType:iAtkClass, iAtkSlot)
{
	if (iAtkSlot == -1 || iAtkSlot > 4 || iAtkClass == TFClass_Unknown || iKiller == iVictim || !IsValidClient(iKiller)) // In event_death, iVictim will surely be valid at this point
	{
		return;
	}
	
	new weapon = GetPlayerWeaponSlot(iKiller, iAtkSlot);
	
	if(weapon == -1 || !IsCustom[weapon] || WeaponName[iKiller][iAtkSlot][0] == '\0' || WeaponDescription[iKiller][iAtkSlot][0] == '\0')
	{
		return;
	}
	
	new Handle:hMenu = CreateMenu(MenuHandler_Null);
	SetMenuTitle(hMenu, "%s\n \n%s", WeaponName[iKiller][iAtkSlot], WeaponDescription[iKiller][iAtkSlot]);
	AddMenuItem(hMenu, "exit", "Close");
	SetMenuPagination(hMenu, MENU_NO_PAGINATION);
	SetMenuExitButton(hMenu, false);
	DisplayMenu(hMenu, iVictim, 8); // 8 second lasting menu
}

public Action:Event_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsValidClient(client))
	{
		return Plugin_Continue;
	}

	new iKiller = GetClientOfUserId(GetEventInt(event, "attacker"));

	if (iKiller && IsValidClient(iKiller) && g_iTheWeaponSlotIWasLastHitBy[client] != -1) // TODO: Test this vs environmental deaths and whatnot.
	{
		decl String:szWeaponLogClassname[64];
		GetValueFromConfig(iKiller, g_iTheWeaponSlotIWasLastHitBy[client], "logname", szWeaponLogClassname, sizeof(szWeaponLogClassname));
		if (szWeaponLogClassname[0] != '\0')
		{
			SetEventString(event, "weapon_logclassname", szWeaponLogClassname);
		}
	}

	if (GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER) return Plugin_Continue;
	
	if(IsValidClient(iKiller))
	{
		DisplayDeathMenu(iKiller, client, TF2_GetPlayerClass(iKiller), g_iTheWeaponSlotIWasLastHitBy[client]);
	}

	g_iTheWeaponSlotIWasLastHitBy[client] = -1;

	return Plugin_Continue;
}

public MenuHandler_Null(Handle:hMenu, MenuAction:iAction, iClient, iParam)
{
	if (iAction == MenuAction_End)
	{
		CloseHandle(hMenu);
	}
}

public Action:Event_Hurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (victim) OKToEquipInArena[victim] = false;
	if (attacker) OKToEquipInArena[attacker] = false;
}

bool:GetValueFromConfig(iClient, iSlot, const String:szKey[], String:szValue[], iszValueSize)
{
	new iClass = _:TF2_GetPlayerClass(iClient);

	if (!IsValidClient(iClient) || iSlot > 4 || SavedWeapons[iClient][iClass][iSlot] == -1 || aItems[iClass][iSlot] == INVALID_HANDLE)
	{
		return false;
	}

	new Handle:hConfig = GetArrayCell(aItems[iClass][iSlot], SavedWeapons[iClient][iClass][iSlot]);
	if (hConfig == INVALID_HANDLE)
	{
		return false;
	}

	KvRewind(hConfig);

	if (StrEqual(szKey, "name"))
	{
		return KvGetSectionName(hConfig, szValue, iszValueSize);
	}
	else
	{
		KvGetString(hConfig, szKey, szValue, iszValueSize);
	}

	return false;
}

public Action:Timer_CheckEquip(Handle:timer, any:uid)
{
	new client = GetClientOfUserId(uid);
	if (!client) return;
	if (timer != hEquipTimer[client]) return;
	if (!GetConVarBool(cvarEnabled)) return;
	if (!IsPlayerAlive(client)) return;
	
	new TFClassType:class = TF2_GetPlayerClass(client);
	for (new slot = 0; slot <= 4; slot++)
		if (SavedWeapons[client][class][slot] > -1)
			GiveCustomWeaponByIndex(client, class, slot, SavedWeapons[client][class][slot], false);
}

public Action:Timer_CheckBotEquip(Handle:timer, any:uid)
{
	if(NativeControl) return;
	new client = GetClientOfUserId(uid);
	if (!client) return;
	if (timer != hBotEquipTimer[client]) return;
	if (!GetConVarBool(cvarEnabled)) return;
	if (IsFakeClient(client) && IsPlayerAlive(client))
	{
		new TFClassType:class = TF2_GetPlayerClass(client);
		new maxSlots = (class == TFClass_Engineer || class == TFClass_Spy) ? 4 : 2;
		new Float:weaponChance = GetConVarFloat(cvarBots);
		for (new slot = 0; slot <= maxSlots; slot++)
		{
			if (GetRandomFloat(0.0, 1.0) > weaponChance) continue;
			
			new numItems = GetArraySize(aItems[class][slot]);
			if (!numItems) continue;
			
			new Handle:aOptions = CreateArray();
			for (new i = 0; i < numItems; i++)
			{
				new Handle:hConfig = GetArrayCell(aItems[class][slot], i);
				KvRewind(hConfig);
				if (KvGetNum(hConfig, "nobots")) continue;
				PushArrayCell(aOptions, i);
			}
			
			new numOptions = GetArraySize(aOptions);
			if (!numOptions) continue;
			
			new choice = GetArrayCell(aOptions, GetRandomInt(0, numOptions-1));
			CloseHandle(aOptions);
			
			GiveCustomWeaponByIndex(client, class, slot, choice, false);
		}
	}
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	roundRunning = true;
	
	for (new client = 1; client <= MaxClients; client++)
		InRespawnRoom[client] = false;
	
	new i = -1;
	while ((i = FindEntityByClassname(i, "func_respawnroom")) != -1)
	{
		SDKHook(i, SDKHook_TouchPost, OnTouchRespawnRoom);
		SDKHook(i, SDKHook_StartTouchPost, OnTouchRespawnRoom);
		SDKHook(i, SDKHook_EndTouch, OnEndTouchRespawnRoom);
	}
	
	if (event != INVALID_HANDLE && IsArenaActive())
	{
		arenaEquipUntil = GetTickedTime() + GetConVarFloat(cvarArenaSeconds);
		for (new client = 1; client <= MaxClients; client++)
			OKToEquipInArena[client] = true;
	}
}

// All of this spawn-check code is from Dr. McKay's No Enemies In Spawn
// https://forums.alliedmods.net/showthread.php?p=1847458
// :3

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
	roundRunning = false;

public OnTouchRespawnRoom(entity, other)
{
	if (other < 1 || other > MaxClients) return;
	if (!IsClientInGame(other)) return;
	if (!IsPlayerAlive(other)) return;
	if (!roundRunning) return;
	
	InRespawnRoom[other] = true;
}

public OnEndTouchRespawnRoom(entity, other)
{
	if (other < 1 || other > MaxClients) return;
	if (!IsClientInGame(other)) return;
	if (!IsPlayerAlive(other)) return;
	if (!roundRunning) return;
	
	InRespawnRoom[other] = false;
}

public Action:Timer_OneSecond(Handle:timer)
{
	for (new client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client)) continue;
		if (IsFakeClient(client)) continue; // DON'T show hint text to bot players.
		if (!IsPlayerAlive(client)) continue;
		if (GetEntProp(client, Prop_Send, "m_nNumHealers") > 0)
		{
			new String:customHealers[256], numCustomHealers;
			for (new i = 1; i <= MaxClients; i++)
			{
				if (client == i) continue;
				if (!IsClientInGame(i)) continue;
				if (!IsPlayerAlive(i)) continue;
				if (client != GetMediGunPatient(i)) continue;
				new medigun = GetPlayerWeaponSlot(i, 1);
				if (!IsCustom[medigun]) continue;
				KvRewind(CustomConfig[medigun]);
				new String:name[64];
				KvGetSectionName(CustomConfig[medigun], name, sizeof(name));
				Format(customHealers, sizeof(customHealers), "%s%s%N is using: %s", customHealers, numCustomHealers++ ? "\n" : "", i, name);
			}
			if (numCustomHealers) PrintHintText(client, customHealers);
		}
	}
}

// NATIVES

public Native_GetClientWeapon(Handle:plugin, args)
{
	new client = GetNativeCell(1), slot = GetNativeCell(2);
	if (!NativeCheck_IsClientValid(client)) return (_:INVALID_HANDLE);
	
	new wep = GetPlayerWeaponSlot(client, slot);
	return IsCustom[wep] ? (_:CustomConfig[wep]) : (_:INVALID_HANDLE);
}

public Native_GetWeaponConfig(Handle:plugin, args)
{
	new weapon = GetNativeCell(1);
	if (weapon == -1) return (_:INVALID_HANDLE);
	
	return IsCustom[weapon] ? (_:CustomConfig[weapon]) : (_:INVALID_HANDLE);
}

public Native_IsCustom(Handle:plugin, args)
{
	new wep = GetNativeCell(1);
	if(wep <= -1) return false;
	
	return IsCustom[wep];
}

public Native_GetClientWeaponName(Handle:plugin, args)
{
	new client = GetNativeCell(1), slot = GetNativeCell(2), namelen = GetNativeCell(4);
	if (!NativeCheck_IsClientValid(client)) return false;
	
	new wep = GetPlayerWeaponSlot(client, slot);
	if (!IsCustom[wep])
	{
		SetNativeString(3, "", GetNativeCell(4));
		return false;
	}
	
	new String:name[namelen];
	KvRewind(CustomConfig[wep]);
	KvGetSectionName(CustomConfig[wep], name, namelen);
	SetNativeString(3, name, namelen);
	return true;
}

public Native_EquipItem(Handle:plugin, args)
{
	new client = GetNativeCell(1), Handle:weapon = Handle:GetNativeCell(2), bool:makeActive = GetNativeCell(3);
	if (!NativeCheck_IsClientValid(client)) return -1;
	
	return GiveCustomWeapon(client, weapon, makeActive);
}

public Native_EquipItemIndex(Handle:plugin, args)
{
	new client = GetNativeCell(1), TFClassType:class = TFClassType:GetNativeCell(2), slot = GetNativeCell(3), index = GetNativeCell(4),
	bool:makeActive = GetNativeCell(5), bool:checkClass = GetNativeCell(6);
	if (!NativeCheck_IsClientValid(client)) return -1;
	if (!NativeCheck_IsClassValid(class)) return -1;
	
	return GiveCustomWeaponByIndex(client, class, slot, index, makeActive, checkClass);
}

public Native_EquipItemName(Handle:plugin, args)
{
	new client = GetNativeCell(1), String:name[96], bool:makeActive = GetNativeCell(3);
	GetNativeString(2, name, sizeof(name));
	if (!NativeCheck_IsClientValid(client)) return 0;
	
	new TFClassType:myClass = TF2_GetPlayerClass(client), TFClassType:class2; // Loop through all classes -- first by the player's class, then other classes in order
	do {
		new TFClassType:class = (class2 == TFClassType:0 ? myClass : class2);
		if (class2 == myClass) continue;
		
		for (new i = 0; i <= 4; i++) // Slots
		{
			new num = GetArraySize(aItems[class][i]);
			for (new j = 0; j < num; j++)
			{
				new Handle:hConfig = GetArrayCell(aItems[class][i], j);
				KvRewind(hConfig);
				
				new String:jName[96];
				KvGetSectionName(hConfig, jName, sizeof(jName));
				
				if (StrEqual(name, jName, false)) return GiveCustomWeapon(client, hConfig, makeActive);
			}
		}
	} while (++class2 < TFClassType:10);
	
	return -1;
}

public Native_GetNumItems(Handle:plugin, args)
{
	new TFClassType:class = TFClassType:GetNativeCell(1), slot = GetNativeCell(2);
	if (!NativeCheck_IsClassValid(class)) return -1;
	
	return GetArraySize(aItems[class][slot]);
}

public Native_GetItemConfig(Handle:plugin, args)
{
	new TFClassType:class = TFClassType:GetNativeCell(1), slot = GetNativeCell(2), index = GetNativeCell(3);
	if (!NativeCheck_IsClassValid(class)) return -1;
	
	return GetArrayCell(aItems[class][slot], index);
}

public Native_GetItemName(Handle:plugin, args)
{
	new TFClassType:class = TFClassType:GetNativeCell(1), slot = GetNativeCell(2), index = GetNativeCell(3), namelen = GetNativeCell(5);
	if (!NativeCheck_IsClassValid(class)) return -1;
	
	new Handle:hWeapon = GetArrayCell(aItems[class][slot], index);
	KvRewind(hWeapon);
	
	new String:name[namelen], bytes;
	KvGetSectionName(hWeapon, name, namelen);
	SetNativeString(4, name, namelen, _, bytes);
	return bytes;
}

public Native_FindItemByName(Handle:plugin, args)
{
	new String:name[96];
	GetNativeString(1, name, sizeof(name));
	
	for (new TFClassType:class = TFClass_Scout; class <= TFClass_Engineer; class++)
	{
		for (new i = 0; i < 5; i++) // Slots
		{
			new num = GetArraySize(aItems[class][i]);
			for (new j = 0; j < num; j++)
			{
				new Handle:hConfig = GetArrayCell(aItems[class][i], j);
				KvRewind(hConfig);
				
				new String:jName[96];
				KvGetSectionName(hConfig, jName, sizeof(jName));
				
				if (StrEqual(name, jName, false)) return _:hConfig;
			}
		}
	}
	
	return _:INVALID_HANDLE;
}

public Native_ControlCW3(Handle:plugin, args)
{
	NativeControl = GetNativeCell(1);
}

// STOCKS

stock GetClientSlot(client)
{
	if (!IsValidClient(client)) return -1;
	if (!IsPlayerAlive(client)) return -1;
	
	decl String:strActiveWeapon[32];
	GetClientWeapon(client, strActiveWeapon, sizeof(strActiveWeapon));
	new slot = GetWeaponSlot(strActiveWeapon);
	return slot;
}

// From chdata.inc
stock GetSlotFromPlayerWeapon(iClient, iWeapon)
{
	if(!IsValidClient(iClient)) return -1;
	
	for (new i = 0; i <= 5; i++)
	{
		if (iWeapon == GetPlayerWeaponSlot(iClient, i))
		{
			return i;
		}
	}
	return -1;
}

stock SetAmmo_Weapon(weapon, newAmmo)
{
	new owner = GetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity");
	if (owner == -1) return;
	new iOffset = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1)*4;
	new iAmmoTable = FindSendPropInfo("CTFPlayer", "m_iAmmo");
	SetEntData(owner, iAmmoTable+iOffset, newAmmo, 4, true);
}

stock SetClip_Weapon(weapon, newClip)
{
	new iAmmoTable = FindSendPropInfo("CTFWeaponBase", "m_iClip1");
	SetEntData(weapon, iAmmoTable, newClip, 4, true);
}

stock TF2_GetClassString(TFClassType:class, String:str[], maxlen, bool:proper = false)
{
	switch (class)
	{
		case TFClass_Scout: Format(str, maxlen, "scout");
		case TFClass_Soldier: Format(str, maxlen, "soldier");
		case TFClass_Pyro: Format(str, maxlen, "pyro");
		case TFClass_DemoMan: Format(str, maxlen, "demoman");
		case TFClass_Heavy: Format(str, maxlen, "heavy");
		case TFClass_Engineer: Format(str, maxlen, "engineer");
		case TFClass_Medic: Format(str, maxlen, "medic");
		case TFClass_Sniper: Format(str, maxlen, "sniper");
		case TFClass_Spy: Format(str, maxlen, "spy");
	}
	if (proper) str[0] = CharToUpper(str[0]);
}

stock TF2_GetPlayerClassString(client, String:str[], maxlen, bool:proper = false)
	TF2_GetClassString(TF2_GetPlayerClass(client), str, maxlen, proper);

stock RemoveAllCustomWeapons() // const String:reason[]
{
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client))
		{
			TF2_RegeneratePlayer(client);
		}
	}
}

stock GetMediGunPatient(client)
{
	new wep = GetPlayerWeaponSlot(client, 1);
	if (wep == -1 || wep != GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon")) return -1;
	new String:class[15];
	GetEdictClassname(wep, class, sizeof(class));
	if (StrContains(class, "tf_weapon_med", false)) return -1;
	return GetEntProp(wep, Prop_Send, "m_bHealing") ? GetEntPropEnt(wep, Prop_Send, "m_hHealingTarget") : -1;
}

// Kinda bad stock name...
stock bool:DoesClientAlreadyHaveCustomWeapon(client, Handle:weapon)
{
	new i = -1;
	while ((i = FindEntityByClassname(i, "tf_weapon*")) != -1)
	{
		if (!IsCustom[i]) continue;
		if (CustomConfig[i] != weapon) continue;
		if (client != GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity")) continue;
		if (GetEntProp(i, Prop_Send, "m_bDisguiseWeapon")) continue;
		return true;
	}
	
	i = -1;
	while ((i = FindEntityByClassname(i, "tf_wearable*")) != -1)
	{
		if (!IsCustom[i]) continue;
		if (CustomConfig[i] != weapon) continue;
		if (client != GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity")) continue;
		if (GetEntProp(i, Prop_Send, "m_bDisguiseWearable")) continue;
		return true;
	}
	
	return false;
}

stock IsArenaActive()
	return FindEntityByClassname(-1, "tf_logic_arena") != -1;

public NativeCheck_IsClientValid(client)
{
	if (!IsValidClient(client)) return ThrowNativeError(SP_ERROR_NATIVE, "Client index %i is invalid", client);
	return true;
}

public NativeCheck_IsClassValid(TFClassType:class)
{
	if (class < TFClass_Scout || class > TFClass_Engineer) return ThrowNativeError(SP_ERROR_NATIVE, "Player class index %i is invalid", class);
	return true;
}

// Wearable crap, ripped out of my bad private wearables plugin
// TODO: Create a nice public plugin to make this into a native which all plugins can use.

stock EquipWearable(client, String:Mdl[], bool:vm, weapon = 0, bool:visactive = true)
{ // ^ bad name probably
	new wearable = CreateWearable(client, Mdl, vm);
	if (wearable == -1) return -1;
	wearableOwner[wearable] = client;
	if (weapon > MaxClients)
	{
		tiedEntity[wearable] = weapon;
		hasWearablesTied[weapon] = true;
		onlyVisIfActive[wearable] = visactive;
		
		new effects = GetEntProp(wearable, Prop_Send, "m_fEffects");
		if (weapon == GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon")) SetEntProp(wearable, Prop_Send, "m_fEffects", effects & ~32);
		else SetEntProp(wearable, Prop_Send, "m_fEffects", effects |= 32);
	}
	return wearable;
}

stock CreateWearable(client, String:model[], bool:vm) // Randomizer code :3
{
	new ent = CreateEntityByName(vm ? "tf_wearable_vm" : "tf_wearable");
	if (!IsValidEntity(ent)) return -1;
	SetEntProp(ent, Prop_Send, "m_nModelIndex", PrecacheModel(model));
	SetEntProp(ent, Prop_Send, "m_fEffects", 129);
	SetEntProp(ent, Prop_Send, "m_iTeamNum", GetClientTeam(client));
	SetEntProp(ent, Prop_Send, "m_usSolidFlags", 4);
	SetEntProp(ent, Prop_Send, "m_CollisionGroup", 11);
	DispatchSpawn(ent);
	SetVariantString("!activator");
	ActivateEntity(ent);
	TF2_EquipWearable(client, ent); // urg
	return ent;
}

// *sigh*
stock TF2_EquipWearable(client, Ent)
{
	if (g_bSdkStarted == false || g_hSdkEquipWearable == INVALID_HANDLE)
	{
		TF2_SdkStartup();
		LogMessage("Error: Can't call EquipWearable, SDK functions not loaded! If it continues to fail, reload plugin or restart server. Make sure your gamedata is intact!");
	}
	else
	{
		SDKCall(g_hSdkEquipWearable, client, Ent);
	}
}

stock bool:TF2_SdkStartup()
{
	new Handle:hGameConf = LoadGameConfigFile("tf2items.randomizer");
	if (hGameConf == INVALID_HANDLE)
	{
		LogMessage("Couldn't load SDK functions (GiveWeapon). Make sure tf2items.randomizer.txt is in your gamedata folder! Restart server if you want wearable weapons.");
		return false;
	}
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "CTFPlayer::EquipWearable");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hSdkEquipWearable = EndPrepSDKCall();

	CloseHandle(hGameConf);
	g_bSdkStarted = true;
	return true;
}

// Common stocks from chdata.inc below

/*
	Common check that says whether or not a client index is occupied.
*/
stock bool:IsValidClient(iClient)
{
	return (0 < iClient && iClient <= MaxClients && IsClientInGame(iClient));
}

stock bool:IsClientID(iClient, String:szSteamId[MAX_STEAMAUTH_LENGTH], AuthIdType:iAuthId = AuthId_Steam2)
{
	if (!IsClientAuthorized(iClient))
	{
		return false;
	}

	decl String:szClientAuth[MAX_STEAMAUTH_LENGTH];
	GetClientAuthId(iClient, iAuthId, szClientAuth, sizeof(szClientAuth));
	return StrEqual(szClientAuth, szSteamId);
}

stock AuthIdType:GetSteamIdAuthType(const String:szId[])
{
	if (StrStarts(szId, "STEAM_0:"))
	{
		return AuthId_Steam2;
	}
	else if (StrStarts(szId, "[U:1:"))
	{
		return AuthId_Steam3;
	}
	else if (StrStarts(szId, "7656119"))
	{
		return AuthId_SteamID64;
	}
	return AuthIdType:-1;
}

stock bool:StrStarts(const String:szStr[], const String:szSubStr[], bool:bCaseSensitive = true)
{
	return !StrContains(szStr, szSubStr, bCaseSensitive);
}

stock SetModelIndex(ent, String:model[])
{
	if(ent == -1) return;
	
	SetEntProp(ent, Prop_Send, "m_nModelIndex", PrecacheModel(model));
}