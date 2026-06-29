#pragma semicolon 1
#include <tf2_stocks>
#include <sdkhooks>
#include <tf2items>
#include <tf2attributes>

#define PLUGIN_VERSION "beta 2"

public Plugin:myinfo = {
    name = "Custom Weapons 2",
    author = "MasterOfTheXP",
    description = "Allows players to use custom-made weapons.",
    version = PLUGIN_VERSION,
    url = "http://mstr.ca/"
};

new Handle:aItems[10][5];
new Handle:fOnAddAttribute;

new TFClassType:BrowsingClass[MAXPLAYERS + 1];
new BrowsingSlot[MAXPLAYERS + 1];
new LookingAtItem[MAXPLAYERS + 1];
new Handle:hEquipTimer[MAXPLAYERS + 1];
new Handle:hBotEquipTimer[MAXPLAYERS + 1];
new bool:InRespawnRoom[MAXPLAYERS + 1];
new SavedWeapons[MAXPLAYERS + 1][10][5];
new Handle:hSavedWeapons[MAXPLAYERS + 1][10][5];
new bool:OKToEquipInArena[MAXPLAYERS + 1];

new bool:IsCustom[2049];
new Handle:CustomConfig[2049];
new bool:HasCustomViewmodel[2049];
new ViewmodelOfWeapon[2049];
new bool:HasCustomWorldmodel[2049];
new WorldmodelOfWeapon[2049];
new bool:HasCustomSounds[2049];

new Handle:cvarEnabled;
new Handle:cvarOnlyInSpawn;
new Handle:cvarArenaSeconds;
new Handle:cvarBots;
new Handle:cvarMenu;
new Handle:cvarKillWearablesOnDeath;
new Handle:cvarSetHealth;
new Handle:cvarOnlyTeam;

new bool:roundRunning = true, Float:arenaEquipUntil;
new weaponcount, plugincount, modelcount;

// TODO: Delete this once the wearables plugin is released!
// [
new tiedEntity[2049]; // Entity to tie the wearable to.
new wearableOwner[2049]; // Who owns this wearable.
new bool:onlyVisIfActive[2049]; // NOT "visible weapon". If true, this wearable is only shown if the weapon is active.
new bool:hasWearablesTied[2049]; // If true, this entity has (or did have) at least one wearable tied to it.

new bool:g_bSdkStarted = false;
new Handle:g_hSdkEquipWearable;
// ]

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	fOnAddAttribute = CreateGlobalForward("CustomWeaponsTF_OnAddAttribute", ET_Event, Param_Cell, Param_Cell, Param_String, Param_String, Param_String);
	
	CreateNative("CusWepsTF_GetClientWeapon", Native_GetClientWeapon);
	CreateNative("CusWepsTF_GetClientWeaponName", Native_GetClientWeaponName);
	
	CreateNative("CusWepsTF_EquipItem", Native_EquipItem);
	CreateNative("CusWepsTF_EquipItemByIndex", Native_EquipItemIndex);
	CreateNative("CusWepsTF_EquipItemByName", Native_EquipItemName);
	
	CreateNative("CusWepsTF_GetNumItems", Native_GetNumItems);
	CreateNative("CusWepsTF_GetItemConfigByIndex", Native_GetItemConfig);
	CreateNative("CusWepsTF_GetItemNameByIndex", Native_GetItemName);
	CreateNative("CusWepsTF_FindItemByName", Native_FindItemByName);
	
	RegPluginLibrary("customweaponstf");
	return APLRes_Success;
}

public OnPluginStart()
{
	RegAdminCmd("custom", Command_Custom, 0);
	RegAdminCmd("cus", Command_Custom, 0);
	RegAdminCmd("c", Command_Custom, 0);
	RegAdminCmd("custom_addattribute", Command_AddAttribute, ADMFLAG_CHEATS);
	
	cvarEnabled = CreateConVar("sm_customweapons_enable", "1", "Enable Custom Weapons. When set to 0, custom weapons will be removed from all players.");
	cvarOnlyInSpawn = CreateConVar("sm_customweapons_onlyinspawn", "1", "Custom weapons can only be equipped from within a spawn room.");
	cvarArenaSeconds = CreateConVar("sm_customweapons_arena_time", "20", "Time, in seconds, after spawning in Arena, that players can still equip custom weapons.");
	cvarBots = CreateConVar("sm_customweapons_bots", "0.15", "Percent chance, for each slot, that bots will equip a custom weapon each time they spawn.");
	cvarMenu = CreateConVar("sm_customweapons_menu", "1", "Clients are allowed to say /custom to equip weapons manually. Set to 0 to disable manual weapon selection without disabling the entire plugin.");
	cvarKillWearablesOnDeath = CreateConVar("sm_customweapons_killwearablesondeath", "1", "Removes custom weapon models when the user dies. Recommended unless bad things start happening.");
	cvarSetHealth = CreateConVar("sm_customweapons_sethealth", "1", "When a custom weapon is equipped, the user's health will be set to their maximum.");
	cvarOnlyTeam = CreateConVar("sm_customweapons_onlyteam", "0", "If non-zero, custom weapons can only be equipped by one team; 2 = RED, 3 = BLU.");
	CreateConVar("sm_customweaponstf_version", PLUGIN_VERSION, "Change anything you want, but please don't change this!");
	
	HookEvent("post_inventory_application", Event_Resupply);
	HookEvent("player_hurt", Event_Hurt);
	HookEvent("player_death", Event_Death);
	HookEvent("teamplay_round_start", Event_RoundStart);
	HookEvent("teamplay_round_win", Event_RoundEnd);
	HookEvent("teamplay_round_stalemate", Event_RoundEnd);

	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i)) continue;
		OnClientPutInServer(i);
	}
	
	AddNormalSoundHook(SoundHook);
	
	CreateTimer(1.0, Timer_OneSecond, _, TIMER_REPEAT);
	
	if (IsValidEntity(0)) Event_RoundStart(INVALID_HANDLE, "teamplay_round_start", false);
	
	TF2_SdkStartup();
}

public OnClientPutInServer(client)
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
}

public OnMapStart()
{
	new String:Root[PLATFORM_MAX_PATH];
	weaponcount = 0, plugincount = 0, modelcount = 0;
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
			PrintToServer("[Custom Weapons] WARNING! Something seems to have gone wrong with opening %s. It won't be added to the weapons list.", FileName);
			CloseHandle(hDir);
			continue;
		}
		if (!KvJumpToKey(hFile, "classes"))
		{
			PrintToServer("[Custom Weapons] WARNING! Weapon config %s does not have any classes marked as being able to use the weapon.", FileName);
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
			PrintToServer("[Custom Weapons] WARNING! Weapon config %s does not have any classes marked as being able to use the weapon.", FileName);
			CloseHandle(hDir);
			continue;
		}
		weaponcount++;
	}
	CloseHandle(hDir);
	
	if (!weaponcount)
		PrintToServer("[Custom Weapons] WARNING! You don't have any custom weapons installed! You should download some from https://forums.alliedmods.net/showthread.php?t=236242 or make your own.");
	
	new String:Dir[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, Dir, sizeof(Dir), "plugins/customweaponstf");
	if (!DirExists(Dir)) PrintToServer("[Custom Weapons] Warning! Custom Weapons' plugin directory (%s) does not exist! You'll be limited to just stock TF2 attributes, which are boring.", Root);
	else {
	
	hDir = OpenDirectory(Dir);
	while (ReadDirEntry(hDir, FileName, sizeof(FileName), type))
	{
		if (FileType_File != type) continue;
		if (StrContains(FileName, ".smx") == -1) continue;
		Format(FileName, sizeof(FileName), "customweaponstf/%s", FileName);
		ServerCommand("sm plugins load %s", FileName);
		plugincount++;
	}
	CloseHandle(hDir); }
	
	//PrintToServer("[Custom Weapons] Custom Weapons loaded successfully with %i weapons, %i plugins, %i models.", weaponcount, plugincount, modelcount);
	PrintToServer("[Custom Weapons] Custom Weapons loaded successfully with %i weapons, %i plugins.", weaponcount, plugincount, modelcount);
}

public OnPluginEnd()
{
	RemoveAllCustomWeapons("Your custom weapons have been removed because the Custom Weapons plugin is unloading.");
	
	new String:Dir[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, Dir, sizeof(Dir), "plugins/customweaponstf");
	if (!DirExists(Dir)) PrintToServer("[Custom Weapons] WARNING! Custom Weapons' plugin directory (%s) does not exist, so any running attribute plugins will not be unloaded. If you're removing Custom Weapons (goodbye!) any running attribute plugins will likely still show up as <ERROR> in your server's plugin list.", Dir);
	else {
		new Handle:hDir = OpenDirectory(Dir), String:FileName[PLATFORM_MAX_PATH], FileType:type;
		while (ReadDirEntry(hDir, FileName, sizeof(FileName), type))
		{
			if (FileType_File != type) continue;
			if (StrContains(FileName, ".smx") == -1) continue;
			Format(FileName, sizeof(FileName), "customweaponstf/%s", FileName);
			ServerCommand("sm plugins unload %s", FileName);
		}
		CloseHandle(hDir); }
}

public Action:Command_Custom(client, args)
{
	if (!client)
	{
		PrintToServer("[Custom Weapons] Custom Weapons is loaded with %i weapons, %i plugins.", weaponcount, plugincount, modelcount);
		return Plugin_Handled;
	}
	CustomMainMenu(client);
	return Plugin_Handled;
}

stock CustomMainMenu(client)
{
	if (!GetConVarBool(cvarMenu)) return;
	new Handle:menu = CreateMenu(CustomMainHandler);
	new counts[5], bool:first = true;
	new _:class;
	if (IsPlayerAlive(client)) class = _:TF2_GetPlayerClass(client);
	else class = GetEntProp(client, Prop_Send, "m_iDesiredPlayerClass");
	
	SetMenuTitle(menu, "Custom Weapons 2 Beta");
	for (new i = 0; i < 5; i++)
	{
		counts[i] = GetArraySize(aItems[class][i]);
		if (counts[i] && first)
		{
			switch (i)
			{
				case 0: SetMenuTitle(menu, "Custom Weapons 2 Beta\n- Primary -");
				case 1: SetMenuTitle(menu, "Custom Weapons 2 Beta\n- Secondary -");
				case 2: SetMenuTitle(menu, "Custom Weapons 2 Beta\n- Melee -");
				case 3: SetMenuTitle(menu, "Custom Weapons 2 Beta\n- PDA -");
				case 4: SetMenuTitle(menu, "Custom Weapons 2 Beta\n- PDA 2 -");
			}
			first = false;
		}
	}
	
	for (new slot = 0; slot <= 4; slot++)
	{
		if (!counts[slot]) continue;
		new saved = SavedWeapons[client][class][slot];
		for (new i = 0; i < counts[slot]; i++)
		{
			new Handle:hWeapon = GetArrayCell(aItems[class][slot], i), String:Name[64], String:Index[10];
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
	}
	
	if (!GetMenuItemCount(menu))
		PrintToChat(client, "\x01\x07FFA07AThis server doesn't have any custom weapons for your class yet. Sorry!");
	
	BrowsingClass[client] = TFClassType:class;
	SetMenuPagination(menu, MENU_NO_PAGINATION);
	SetMenuExitButton(menu, true);
	DisplayMenuAtItem(menu, client, 0, MENU_TIME_FOREVER);
}
public CustomMainHandler(Handle:menu, MenuAction:action, client, item)
{
	if (action == MenuAction_Select)
	{
		if (BrowsingClass[client] != TF2_GetPlayerClass(client))
		{
			CustomMainMenu(client);
			return;
		}
		new String:sel[20], String:sIdxs[2][10];
		GetMenuItem(menu, item, sel, sizeof(sel));
		ExplodeString(sel, " ", sIdxs, sizeof(sIdxs), sizeof(sIdxs));
		WeaponInfoMenu(client, BrowsingClass[client], StringToInt(sIdxs[0]), StringToInt(sIdxs[1]));
	}
	else if (action == MenuAction_End) CloseHandle(menu);
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
	AddMenuItem(menu, "", "Use", ITEMDRAW_DEFAULT);
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
		else AddMenuItem(menu, "", "Unsave", ITEMDRAW_DEFAULT);
	}
	else
	{
		if (hWeapon != hSavedWeapons[client][class][slot]) AddMenuItem(menu, "", "Save", ITEMDRAW_DEFAULT);
		else AddMenuItem(menu, "", "Unsave", ITEMDRAW_DEFAULT);
	}
	AddMenuItem(menu, "", "", ITEMDRAW_SPACER);
	AddMenuItem(menu, "", "Prev Weapon", weapon ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	AddMenuItem(menu, "", "Next Weapon", weapon != GetArraySize(aItems[class][slot])-1 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	BrowsingClass[client] = class;
	BrowsingSlot[client] = slot;
	LookingAtItem[client] = weapon;
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
			case 0:
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
			case 1:
			{
				new TFClassType:class = BrowsingClass[client];
				new slot = BrowsingSlot[client];
				new index = LookingAtItem[client];
				new onlyteam = GetConVarInt(cvarOnlyTeam);
				
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
				}
				WeaponInfoMenu(client, class, slot, index, 0.2);
			}
			case 3: WeaponInfoMenu(client, BrowsingClass[client], BrowsingSlot[client], LookingAtItem[client] - 1);
			case 4: WeaponInfoMenu(client, BrowsingClass[client], BrowsingSlot[client], LookingAtItem[client] + 1);
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
	new TFClassType:class = TF2_GetPlayerClass(client);
	
	KvRewind(hConfig);
	new String:name[96], String:baseClass[64], baseIndex, String:logName[64], String:killIcon[64], bool:forcegen, mag, ammo, metal;
	
	KvGetSectionName(hConfig, name, sizeof(name));
	KvGetString(hConfig, "baseclass", baseClass, sizeof(baseClass));
	baseIndex = KvGetNum(hConfig, "baseindex", -1);
	KvGetString(hConfig, "logname", logName, sizeof(logName));
	KvGetString(hConfig, "killicon", killIcon, sizeof(killIcon));
	forcegen = bool:KvGetNum(hConfig, "forcegen", _:false);
	mag = KvGetNum(hConfig, "mag", -1);
	ammo = KvGetNum(hConfig, "ammo", -1);
	metal = KvGetNum(hConfig, "metal", -1);
	
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
	
	if (StrEqual(baseClass, "saxxy", false))
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
	else if (StrEqual(baseClass, "shotgun", false))
		switch (class)
		{
			case TFClass_Scout: Format(baseClass, sizeof(baseClass), "scattergun");
			case TFClass_Soldier, TFClass_DemoMan: Format(baseClass, sizeof(baseClass), "shotgun_soldier");
			case TFClass_Pyro: Format(baseClass, sizeof(baseClass), "shotgun_pyro");
			case TFClass_Heavy: Format(baseClass, sizeof(baseClass), "shotgun_hwg");
			default: Format(baseClass, sizeof(baseClass), "shotgun_primary");
		}
	else if (StrEqual(baseClass, "pistol", false) &&
			TFClass_Scout == class) Format(baseClass, sizeof(baseClass), "pistol_scout");
	
	Format(baseClass, sizeof(baseClass), "tf_weapon_%s", baseClass);
	
	new flags = OVERRIDE_ALL;
	if (forcegen) flags |= FORCE_GENERATION;
	new Handle:hWeapon = TF2Items_CreateItem(flags);
	TF2Items_SetClassname(hWeapon, baseClass);
	TF2Items_SetItemIndex(hWeapon, baseIndex);
	TF2Items_SetLevel(hWeapon, 1);
	TF2Items_SetQuality(hWeapon, 10);
	
	new numAttributes;
	if (KvJumpToKey(hConfig, "attributes"))
	{
		KvGotoFirstSubKey(hConfig);
		do {
			new String:Plugin[64];
			KvGetString(hConfig, "plugin", Plugin, sizeof(Plugin));
			if (!StrEqual(Plugin, "tf2items", false)) continue;
			
			new String:Att[64], String:Value[64];
			KvGetSectionName(hConfig, Att, sizeof(Att));
			KvGetString(hConfig, "value", Value, sizeof(Value));
			
			TF2Items_SetAttribute(hWeapon, numAttributes++, StringToInt(Att), StringToFloat(Value));
		} while (KvGotoNextKey(hConfig));
	}
	KvRewind(hConfig);
	
	TF2Items_SetNumAttributes(hWeapon, numAttributes);
	
	TF2_RemoveWeaponSlot(client, slot);
	if (!slot || slot == 1)
	{
		new i = -1;
		while ((i = FindEntityByClassname(i, "tf_wearable*")) != -1)
		{
			if (client != GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity")) continue;
			if (GetEntProp(i, Prop_Send, "m_bDisguiseWearable")) continue;
			if (!slot)
			{
				switch (GetEntProp(i, Prop_Send, "m_iItemDefinitionIndex"))
				{	case 405, 608: AcceptEntityInput(i, "Kill");	}
			}
			else
			{
				switch (GetEntProp(i, Prop_Send, "m_iItemDefinitionIndex"))
				{	case 57, 131, 133, 231, 406, 444, 642: AcceptEntityInput(i, "Kill");	}
			}
		}
	}
	
	new ent = TF2Items_GiveNamedItem(client, hWeapon);
	CloseHandle(hWeapon);
	
	if (ammo != -1) SetAmmo_Weapon(ent, ammo);
	EquipPlayerWeapon(client, ent);
	if (mag != -1) SetClip_Weapon(ent, mag);
	if (ammo != -1) SetAmmo_Weapon(ent, ammo);
	if (metal != -1) SetEntProp(client, Prop_Data, "m_iAmmo", metal, 4, 3);
	
	if (StrEqual(baseClass, "tf_weapon_sapper", false) || StrEqual(baseClass, "tf_weapon_builder", false))
	{
		SetEntProp(ent, Prop_Send, "m_iObjectType", 3);
		SetEntProp(ent, Prop_Data, "m_iSubType", 3);
	}
	
	if (KvJumpToKey(hConfig, "attributes"))
	{
		KvGotoFirstSubKey(hConfig);
		do {
			new String:Att[64], String:Plugin[64], String:Value[64];
			KvGetSectionName(hConfig, Att, sizeof(Att));
			KvGetString(hConfig, "plugin", Plugin, sizeof(Plugin));
			KvGetString(hConfig, "value", Value, sizeof(Value));
			
			if (!StrEqual(Plugin, "tf2attributes", false) && !StrEqual(Plugin, "tf2attributes.int", false) && !StrEqual(Plugin, "tf2items", false))
			{
				new Action:act = Plugin_Continue;
				Call_StartForward(fOnAddAttribute);
				Call_PushCell(ent);
				Call_PushCell(client);
				Call_PushString(Att);
				Call_PushString(Plugin);
				Call_PushString(Value);
				Call_Finish(act);
				if (!act) PrintToServer("[Custom Weapons] WARNING! Attribute \"%s\" (value \"%s\" plugin \"%s\") seems to have been ignored by all attributes plugins. It's either an invalid attribute, incorrect plugin, an error occured in the att. plugin, or the att. plugin forgot to return Plugin_Handled.", Att, Value, Plugin);
			}
			else if (!StrEqual(Plugin, "tf2items", false))
			{
				if (StrEqual(Plugin, "tf2attributes", false)) TF2Attrib_SetByName(ent, Att, StringToFloat(Value));
				else TF2Attrib_SetByName(ent, Att, Float:StringToInt(Value));
			}
			
		} while (KvGotoNextKey(hConfig));
	}
	
	KvRewind(hConfig);
	if (KvJumpToKey(hConfig, "viewmodel"))
	{
		new String:ModelName[PLATFORM_MAX_PATH];
		KvGetString(hConfig, "modelname", ModelName, sizeof(ModelName));
		if (StrContains(ModelName, "models/", false)) Format(ModelName, sizeof(ModelName), "models/%s", ModelName);
		if (-1 == StrContains(ModelName, ".mdl", false)) Format(ModelName, sizeof(ModelName), "%s.mdl", ModelName);
		if (strlen(ModelName) && FileExists(ModelName, true))
		{
			PrecacheModel(ModelName, true);
			new vm = EquipWearable(client, ModelName, true, ent, true);
			if (vm > -1) ViewmodelOfWeapon[vm] = ent;
			new String:arms[PLATFORM_MAX_PATH];
			switch (class)
			{
				case TFClass_Scout: Format(arms, sizeof(arms), "models/weapons/c_models/c_scout_arms.mdl");
				case TFClass_Soldier: Format(arms, sizeof(arms), "models/weapons/c_models/c_soldier_arms.mdl");
				case TFClass_Pyro: Format(arms, sizeof(arms), "models/weapons/c_models/c_pyro_arms.mdl");
				case TFClass_DemoMan: Format(arms, sizeof(arms), "models/weapons/c_models/c_demo_arms.mdl");
				case TFClass_Heavy: Format(arms, sizeof(arms), "models/weapons/c_models/c_heavy_arms.mdl");
				case TFClass_Engineer: Format(arms, sizeof(arms), "models/weapons/c_models/c_engineer_arms.mdl");
				case TFClass_Medic: Format(arms, sizeof(arms), "models/weapons/c_models/c_medic_arms.mdl");
				case TFClass_Sniper: Format(arms, sizeof(arms), "models/weapons/c_models/c_sniper_arms.mdl");
				case TFClass_Spy: Format(arms, sizeof(arms), "models/weapons/c_models/c_spy_arms.mdl");
			}
			if (strlen(arms) && FileExists(arms, true))
			{
				PrecacheModel(arms, true);
				new armsVm = EquipWearable(client, arms, true, ent, true);
				if (armsVm > -1) ViewmodelOfWeapon[armsVm] = ent;
			}
			HasCustomViewmodel[ent] = true;
			new attachment = KvGetNum(hConfig, "attachment", -1);
			if (attachment > -1)
			{
				SetEntProp(vm, Prop_Send, "m_fEffects", 0);
				SetEntProp(vm, Prop_Send, "m_iParentAttachment", attachment);
				new Float:offs[3], Float:angOffs[3], Float:scale;
				KvGetVector(hConfig, "pos", offs);
				KvGetVector(hConfig, "ang", angOffs);
				scale = KvGetFloat(hConfig, "scale", 1.0);
				SetEntPropVector(vm, Prop_Send, "m_vecOrigin", offs);
				SetEntPropVector(vm, Prop_Send, "m_angRotation", angOffs);
				if (scale != 1.0) SetEntPropFloat(vm, Prop_Send, "m_flModelScale", scale);
			}
		}
	}
	
	KvRewind(hConfig);
	if (KvJumpToKey(hConfig, "worldmodel"))
	{
		new String:ModelName[PLATFORM_MAX_PATH];
		KvGetString(hConfig, "modelname", ModelName, sizeof(ModelName));
		if (StrContains(ModelName, "models/", false)) Format(ModelName, sizeof(ModelName), "models/%s", ModelName);
		if (-1 == StrContains(ModelName, ".mdl", false)) Format(ModelName, sizeof(ModelName), "%s.mdl", ModelName);
		if (strlen(ModelName) && FileExists(ModelName, true))
		{
			PrecacheModel(ModelName, true);
			new wr = EquipWearable(client, ModelName, false, ent, true);
			if (wr > -1) WorldmodelOfWeapon[wr] = ent;
			HasCustomWorldmodel[ent] = true;
			new attachment = KvGetNum(hConfig, "attachment", -1);
			if (attachment > -1)
			{
				SetEntProp(wr, Prop_Send, "m_fEffects", 0);
				SetEntProp(wr, Prop_Send, "m_iParentAttachment", attachment);
				new Float:offs[3], Float:angOffs[3], Float:scale;
				KvGetVector(hConfig, "pos", offs);
				KvGetVector(hConfig, "ang", angOffs);
				scale = KvGetFloat(hConfig, "scale", 1.0);
				SetEntPropVector(wr, Prop_Send, "m_vecOrigin", offs);
				SetEntPropVector(wr, Prop_Send, "m_angRotation", angOffs);
				if (scale != 1.0) SetEntPropFloat(wr, Prop_Send, "m_flModelScale", scale);
			}
			new replace = KvGetNum(hConfig, "replace", 1);
			if (replace == 1)
			{
				SetEntityRenderMode(ent, RENDER_TRANSCOLOR);
				SetEntityRenderColor(ent, 0, 0, 0, 0);
			}
			else if (replace == 2)
			{
				SetEntPropFloat(ent, Prop_Send, "m_flModelScale", 0.0);
			}
		}
	}
	
	KvRewind(hConfig);
	if (KvJumpToKey(hConfig, "sound"))
		HasCustomSounds[ent] = true;
	
	IsCustom[ent] = true;
	CustomConfig[ent] = hConfig;
	
	if (makeActive && !StrEqual(baseClass, "tf_weapon_invis", false))
	{
		ClientCommand(client, "slot%i", slot+1);
		OnWeaponSwitch(client, ent);
	}
	else OnWeaponSwitch(client, GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon"));
	
	if (GetConVarBool(cvarSetHealth))
	{
		CreateTimer(0.1, Timer_SetHealth, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
	
	return ent;
}

public Action:Timer_SetHealth(Handle:timer, any:uid)
{
	new client = GetClientOfUserId(uid);
	if (!client) return;
	SetEntityHealth(client, GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMaxHealth", _, client));
}

public Action:SoundHook(clients[64], &numClients, String:sound[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	if (entity > 0 && entity <= MaxClients)
	{
		if (IsClientInGame(entity))
		{
			new client = entity;
			new wep = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if (wep <= 0 || wep > 2048) return Plugin_Continue;
			if (!HasCustomSounds[wep]) return Plugin_Continue;
			new Handle:hConfig = CustomConfig[wep];
			KvRewind(hConfig);
			KvJumpToKey(hConfig, "sound");
			KvGotoFirstSubKey(hConfig);
			do {
				new String:section[64];
				KvGetSectionName(hConfig, section, sizeof(section));
				if (StrEqual(section, "player", false))
				{
					new String:find[PLATFORM_MAX_PATH], String:replace[PLATFORM_MAX_PATH];
					KvGetString(hConfig, "find", find, sizeof(find));
					KvGetString(hConfig, "replace", replace, sizeof(replace));
					if (StrEqual(sound, find, false))
					{
						Format(sound, sizeof(sound), replace);
						PrecacheSound(sound);
						EmitSoundToClient(client, sound, _, channel, KvGetNum(hConfig, "level", level), flags, KvGetFloat(hConfig, "volume", volume), KvGetNum(hConfig, "pitch", pitch));
						return Plugin_Changed;
					}
				}
			} while (KvGotoNextKey(hConfig));
		}
	}
	return Plugin_Continue;
}

public OnWeaponSwitch(client, Wep)
{
	if (!IsValidEntity(Wep)) return;
	if (HasCustomViewmodel[Wep])
		SetEntProp(GetEntPropEnt(client, Prop_Send, "m_hViewModel"), Prop_Send, "m_fEffects", 32);
	
	// TODO: Delete this once the wearables plugin is released!
	new i = -1;
	while ((i = FindEntityByClassname(i, "tf_wearable*")) != -1)
	{
		if (!onlyVisIfActive[i]) continue;
		if (client != wearableOwner[i]) continue;
		new effects = GetEntProp(i, Prop_Send, "m_fEffects");
		if (Wep == tiedEntity[i]) SetEntProp(i, Prop_Send, "m_fEffects", effects & ~32);
		else SetEntProp(i, Prop_Send, "m_fEffects", effects |= 32);
	}
}

public OnEntityDestroyed(ent)
{
	if (ent <= 0 || ent > 2048) return;
	IsCustom[ent] = false;
	CustomConfig[ent] = INVALID_HANDLE;
	HasCustomViewmodel[ent] = false;
	ViewmodelOfWeapon[ent] = 0;
	HasCustomSounds[ent] = false;
	HasCustomWorldmodel[ent] = false;
	WorldmodelOfWeapon[ent] = 0;
	
	// TODO: Delete this once the wearables plugin is released!
	if (ent <= 0 || ent > 2048) return;
	if (hasWearablesTied[ent])
	{	
		new i = -1;
		while ((i = FindEntityByClassname(i, "tf_wearable*")) != -1)
		{
			if (ent != tiedEntity[i]) continue;
			AcceptEntityInput(i, "Kill");
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
}

public Action:Event_Hurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (victim) OKToEquipInArena[victim] = false;
	if (attacker) OKToEquipInArena[attacker] = false;
}

public Action:Event_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!client) return;
	if (GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER) return;
	
	if (!GetConVarBool(cvarKillWearablesOnDeath)) return;
	
	new i = -1;
	while ((i = FindEntityByClassname(i, "tf_wearable*")) != -1)
	{
		if (!tiedEntity[i]) continue;
		if (client != GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity")) continue;
		if (GetEntProp(i, Prop_Send, "m_bDisguiseWearable")) continue;
		AcceptEntityInput(i, "Kill");
	}
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

public Action:Command_AddAttribute(client, args)
{
	if (args < 3)
	{
		ReplyToCommand(client, "[SM] Usage: custom_addattribute <client> <slot> <\"attribute name\"> <\"value\"> <\"plugin\"> - Sets an attribute onto a user's weapon.");
		return Plugin_Handled;
	}
	
	new String:target_arg[MAX_TARGET_LENGTH], slot, String:strslot[10], String:attribute[64], String:value[64], String:plugin[64];
	GetCmdArg(1, target_arg, sizeof(target_arg));
	GetCmdArg(2, strslot, sizeof(strslot));
	GetCmdArg(3, attribute, sizeof(attribute));
	GetCmdArg(4, value, sizeof(value));
	GetCmdArg(5, plugin, sizeof(plugin));
	slot = StringToInt(strslot);
	
	new String:target_name[MAX_TARGET_LENGTH], target_list[MAXPLAYERS], target_count, bool:tn_is_ml;

	if ((target_count = ProcessTargetString(target_arg, client, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	for (new i = 0; i < target_count; i++)
	{
		new wep = GetPlayerWeaponSlot(target_list[i], slot);
		if (wep == -1) continue;
		new Action:act = Plugin_Continue;
		Call_StartForward(fOnAddAttribute);
		Call_PushCell(wep);
		Call_PushCell(target_list[i]);
		Call_PushString(attribute);
		Call_PushString(plugin);
		Call_PushString(value);
		Call_Finish(act);
		if (!act)
		{
			ReplyToCommand(client, "Error: Attribute \"%s\" does not exist in attributes plugin \"%s\".", attribute, plugin);
			return Plugin_Handled;
		}
	}
	
	return Plugin_Handled;
}

// NATIVES

public Native_GetClientWeapon(Handle:plugin, args)
{
	new client = GetNativeCell(1), slot = GetNativeCell(2);
	if (!NativeCheck_IsClientValid(client)) return (_:INVALID_HANDLE);
	
	new wep = GetPlayerWeaponSlot(client, slot);
	return IsCustom[wep] ? (_:CustomConfig[wep]) : (_:INVALID_HANDLE);
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

// STOCKS

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

stock RemoveAllCustomWeapons(const String:reason[])
{
	for (new client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client)) continue;
		new bool:removed, bool:removedSlot[5];
		for (new slot = 0; slot <= 4; slot++)
		{
			new wep = GetPlayerWeaponSlot(client, slot);
			if (wep == -1) continue;
			if (!IsCustom[wep]) continue;
			TF2_RemoveWeaponSlot(client, slot);
			removed = true;
		}
		if (!removed) continue;
		for (new slot = 0; slot <= 4; slot++)
		{
			if (removedSlot[slot]) continue;
			ClientCommand(client, "slot%i", slot+1);
			break;
		}
		if (removed) PrintToChat(client, reason);
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
	if (client <= 0 || client > MaxClients) return ThrowNativeError(SP_ERROR_NATIVE, "Client index %i is invalid", client);
	if (!IsClientInGame(client)) return ThrowNativeError(SP_ERROR_NATIVE, "Client %i is not in game", client);
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