#pragma semicolon 1 // Force strict semicolon mode.

#include <sourcemod>
#define REQUIRE_EXTENSIONS
#include <tf2items>
#include <sdktools>

#define PLUGIN_NAME		"[TF2Items] Give Weapon"
#define PLUGIN_AUTHOR		"Asherkin (Updated by FlaminSarge)"
#define PLUGIN_VERSION		"1.4.1.2.2"
#define PLUGIN_CONTACT		"http://limetech.org/"
#define PLUGIN_DESCRIPTION	"Give any weapon to any player on command"

new g_hItems[MAXPLAYERS+1][6];
new Handle:g_hItemInfoTrie = INVALID_HANDLE;
new rnd_isenabled;

public Plugin:myinfo = {
	name			= PLUGIN_NAME,
	author			= PLUGIN_AUTHOR,
	description	= PLUGIN_DESCRIPTION,
	version		= PLUGIN_VERSION,
	url				= PLUGIN_CONTACT
};

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	CreateConVar("tf2items_giveweapon_version", PLUGIN_VERSION, "[TF2Items] Give Weapon Version", FCVAR_REPLICATED|FCVAR_NOTIFY | FCVAR_PLUGIN | FCVAR_SPONLY);
	RegAdminCmd("sm_giveweapon", Command_Weapon, ADMFLAG_CUSTOM1, "sm_giveweapon <player> <itemindex>");
	RegAdminCmd("sm_giveweapon_ex", Command_WeaponEx, ADMFLAG_CHEATS, "Give Permanent Weapon sm_giveweapon_ex <player> <itemindex>");
	RegAdminCmd("sm_givew", Command_Weapon, ADMFLAG_CHEATS, "sm_give <player> <itemindex>");
	RegAdminCmd("sm_givew_ex", Command_WeaponEx, ADMFLAG_CHEATS, "Give Permanent Weapon sm_give_ex <player> <itemindex>");
	RegAdminCmd("tf2items_giveweapon_reload", Command_ReloadCustoms, ADMFLAG_CHEATS, "Reloads custom items list");
	RegAdminCmd("sm_resetex", Command_ResetEx, ADMFLAG_CUSTOM1, "Reset the Permanent Weapons of a Player sm_resetex <target>");
	HookEvent("post_inventory_application", lockerwepreset,  EventHookMode_Post);
	CreateItemInfoTrie();
}
public OnAllPluginsLoaded()
{
	new Handle:randomizerhandle = FindConVar("tf2items_rnd_enabled");
	if (randomizerhandle != INVALID_HANDLE)
	{
		rnd_isenabled = GetConVarBool(randomizerhandle);
		HookConVarChange(randomizerhandle, cvhook_rndisenabled);
	}
}
public cvhook_rndisenabled(Handle:cvar, const String:oldVal[], const String:newVal[]) { rnd_isenabled = GetConVarBool(cvar); }
public OnClientPutInServer(client)
{
	for (new i = 0; i < 6; i++)
	{
		if (g_hItems[client][i] != -1)
		{
			g_hItems[client][i] = -1;
		}
	}
}

public OnClientDisconnect_Post(client)
{
	for (new i = 0; i < 6; i++)
	{
		if (g_hItems[client][i] != -1)
		{
			g_hItems[client][i] = -1;
		}
	}
}

public lockerwepreset(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	CreateTimer(0.1, Timer_LockerWeaponReset, any:client);
}

public Action:Timer_LockerWeaponReset(Handle:timer, any:client)
{
	for (new i = 0; i < 6; i++)
	{
		if (g_hItems[client][i] != -1)
		{
			Command_WeaponBase(client, g_hItems[client][i], i);
		}
	}
}

/*public Action:TF2Items_OnGiveNamedItem(client, String:strClassName[], iItemDefinitionIndex, &Handle:hItemOverride)
{
	new weaponSlot;
	new String:formatBuffer[32];
	Format(formatBuffer, 32, "%d_%s", iItemDefinitionIndex, "slot");
	GetTrieValue(g_hItemInfoTrie, formatBuffer, weaponSlot);
	
	if (g_hItems[client][weaponSlot] == -1)
	{
		//PrintToChat(client, "No weapon for slot %d.", weaponSlot);
		return Plugin_Continue;
	}
	
	//PrintToChat(client, "Weapon in-queue for slot %d.", weaponSlot);
	hItemOverride = PrepareItemHandle(g_hItems[client][weaponSlot]);
	new Handle:pack;
	CreateDataTimer(0.1, CheckAmmoNao, pack);
	WritePackCell(pack, client);
	WritePackCell(pack, weaponSlot);

	g_hItems[client][weaponSlot] = -1;
	return Plugin_Changed;
}

public Action:CheckAmmoNao(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new client = ReadPackCell(pack);
	new slot = ReadPackCell(pack);
	new weaponAmmo;
	new String:formatBuffer[32];
	Format(formatBuffer, 32, "%d_%s", g_hItems[client][slot], "ammo");
	GetTrieValue(g_hItemInfoTrie, formatBuffer, weaponAmmo);
	if (weaponAmmo != -1) SetSpeshulAmmo(client, slot, weaponAmmo);
}*/

public Action:Command_WeaponEx(client, args)
{
	decl String:arg1[32];
	decl String:arg2[32];
	decl String:arg3[32];
	new weaponLookupIndex = 0;
	new mode = 0;
 
	if (args != 2 && args != 3)
	{
		ReplyToCommand(client, "[TF2Items] Usage: sm_giveweapon_ex <player> <itemindex> [givenow]");
		return Plugin_Handled;
	}
	
	/* Get the arguments */
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	if (args == 3)
	{
		GetCmdArg(3, arg3, sizeof(arg3));
		mode = StringToInt(arg3);
	}
	weaponLookupIndex = StringToInt(arg2);
	mode = StringToInt(arg3);
 
	/**
	 * target_name - stores the noun identifying the target(s)
	 * target_list - array to store clients
	 * target_count - variable to store number of clients
	 * tn_is_ml - stores whether the noun must be translated
	 */
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;
 
	if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			0,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		/* This function replies to the admin with a failure message */
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
 
	for (new i = 0; i < target_count; i++)
	{
		new weaponSlot;
		new String:formatBuffer[32];
		Format(formatBuffer, 32, "%d_%s", weaponLookupIndex, "slot");
		new bool:isValidItem = GetTrieValue(g_hItemInfoTrie, formatBuffer, weaponSlot);
		
		if (!isValidItem)
		{
			ReplyToCommand(client, "[TF2Items] Invalid Weapon Index");
			return Plugin_Handled;
		}
		
		ReplyToCommand(target_list[i], "[TF2Items] Respawn or touch a locker to recieve your permanent weapon.");
		g_hItems[target_list[i]][weaponSlot] = weaponLookupIndex;
		if (mode == 1) Command_WeaponBase(target_list[i], weaponLookupIndex, weaponSlot);
		LogAction(client, target_list[i], "\"%L\" gave a permanent weapon to \"%L\"", client, weaponLookupIndex, target_list[i]);
	}
 
	if (tn_is_ml) {
		ReplyToCommand(client, "[TF2Items] ", "Weapon Given", target_name, weaponLookupIndex);
	} else {
		ReplyToCommand(client, "[TF2Items] ", "Weapon Given", target_name, weaponLookupIndex);
	}
 
	return Plugin_Handled;
}

public Action:Command_ResetEx(client, args)
{
	new String:arg1[32];
 
	if (args != 1)
	{
		ReplyToCommand(client, "[TF2Items] Usage: sm_resetex <target>");
		return Plugin_Handled;
	}
	
	/* Get the arguments */
	GetCmdArg(1, arg1, sizeof(arg1));
 
	/**
	 * target_name - stores the noun identifying the target(s)
	 * target_list - array to store clients
	 * target_count - variable to store number of clients
	 * tn_is_ml - stores whether the noun must be translated
	 */
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;
 
	if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			0, 
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		/* This function replies to the admin with a failure message */
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
 
	for (new i = 0; i < target_count; i++)
	{
		for (new slot = 0; slot < 6; slot++)
		{
			if (g_hItems[target_list[i]][slot] != -1) g_hItems[target_list[i]][slot] = -1;
		}
		LogAction(client, target_list[i], "\"%L\" reset permanent weapons for \"%L\"", client, target_list[i]);
	}
	if (tn_is_ml) {
		ReplyToCommand(client, "[TF2Items] ", "Weapons Reset", target_name);
	} else {
		ReplyToCommand(client, "[TF2Items] ", "Weapons Reset", target_name);
	}
	return Plugin_Handled;
}
public Action:Command_Weapon(client, args)
{
	new String:arg1[32];
	new String:arg2[32];
	new weaponLookupIndex = 0;
 
	if (args != 2) {
		ReplyToCommand(client, "[TF2Items] Usage: sm_giveweapon <player> <itemindex>");
		return Plugin_Handled;
	}
	
	/* Get the arguments */
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	weaponLookupIndex = StringToInt(arg2);
 
	/**
	 * target_name - stores the noun identifying the target(s)
	 * target_list - array to store clients
	 * target_count - variable to store number of clients
	 * tn_is_ml - stores whether the noun must be translated
	 */
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;
 
	if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE, /* Only allow alive players */
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		/* This function replies to the admin with a failure message */
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
 
	for (new i = 0; i < target_count; i++)
	{
		new weaponSlot;
		new String:formatBuffer[32];
		Format(formatBuffer, 32, "%d_%s", weaponLookupIndex, "slot");
		new bool:isValidItem = GetTrieValue(g_hItemInfoTrie, formatBuffer, weaponSlot);
		if (!isValidItem)
		{
			ReplyToCommand(client, "[TF2Items] Invalid Weapon Index");
			return Plugin_Handled;
		}
		Command_WeaponBase(target_list[i], weaponLookupIndex, weaponSlot);		
		LogAction(client, target_list[i], "\"%L\" gave a weapon to \"%L\"", client, weaponLookupIndex, target_list[i]);
	}
 
	if (tn_is_ml) {
		ReplyToCommand(client, "[TF2Items] ", "Weapon Given", target_name, weaponLookupIndex);
	} else {
		ReplyToCommand(client, "[TF2Items] ", "Weapon Given", target_name, weaponLookupIndex);
	}
 
	return Plugin_Handled;
}

public Action:Command_WeaponBase(client, weaponLookupIndex, weaponSlot)
{
	new weaponIndex;
	while ((weaponIndex = GetPlayerWeaponSlot(client, weaponSlot)) != -1)
	{
		RemovePlayerItem(client, weaponIndex);
		RemoveEdict(weaponIndex);
	}
	decl String:formatBuffer[32];
	new Handle:hWeapon = PrepareItemHandle(weaponLookupIndex);

	new entity = TF2Items_GiveNamedItem(client, hWeapon);
	CloseHandle(hWeapon);
	
	if (IsValidEntity(entity))
	{
		if (weaponLookupIndex == 2171) SetEntProp(entity, Prop_Send, "m_iEntityLevel", 128+13);
		EquipPlayerWeapon(client, entity);

		new weaponAmmo;
		Format(formatBuffer, 32, "%d_%s", weaponLookupIndex, "ammo");
		GetTrieValue(g_hItemInfoTrie, formatBuffer, weaponAmmo);

		if (weaponAmmo != -1)
		{
			SetSpeshulAmmo(client, weaponSlot, weaponAmmo);
		}
	}
	else
	{
		ReplyToCommand(client, "[TF2Items] Something went wrong, invalid entity created.");
	}
}

Handle:PrepareItemHandle(weaponLookupIndex)
{
	new String:formatBuffer[32];	
	new String:weaponClassname[64];
	new weaponIndex;
	new weaponSlot;
	new weaponQuality;
	new weaponLevel;
	new String:weaponAttribs[256];
	
	Format(formatBuffer, 32, "%d_%s", weaponLookupIndex, "classname");
	GetTrieString(g_hItemInfoTrie, formatBuffer, weaponClassname, 64);
	
	Format(formatBuffer, 32, "%d_%s", weaponLookupIndex, "index");
	GetTrieValue(g_hItemInfoTrie, formatBuffer, weaponIndex);
	
	Format(formatBuffer, 32, "%d_%s", weaponLookupIndex, "slot");
	GetTrieValue(g_hItemInfoTrie, formatBuffer, weaponSlot);
	
	Format(formatBuffer, 32, "%d_%s", weaponLookupIndex, "quality");
	GetTrieValue(g_hItemInfoTrie, formatBuffer, weaponQuality);
	
	Format(formatBuffer, 32, "%d_%s", weaponLookupIndex, "level");
	GetTrieValue(g_hItemInfoTrie, formatBuffer, weaponLevel);
	
	Format(formatBuffer, 32, "%d_%s", weaponLookupIndex, "attribs");
	GetTrieString(g_hItemInfoTrie, formatBuffer, weaponAttribs, 256);
	
	new String:weaponAttribsArray[32][32];
	new attribCount = ExplodeString(weaponAttribs, " ; ", weaponAttribsArray, 32, 32);
	
	new Handle:hWeapon = TF2Items_CreateItem(OVERRIDE_CLASSNAME | OVERRIDE_ITEM_DEF | OVERRIDE_ITEM_LEVEL | OVERRIDE_ITEM_QUALITY | OVERRIDE_ATTRIBUTES);

	TF2Items_SetClassname(hWeapon, weaponClassname);
	TF2Items_SetItemIndex(hWeapon, weaponIndex);
	TF2Items_SetLevel(hWeapon, weaponLevel);
	TF2Items_SetQuality(hWeapon, weaponQuality);

	if (attribCount > 0) {
		TF2Items_SetNumAttributes(hWeapon, attribCount/2);
		new i2 = 0;
		for (new i = 0; i < attribCount; i+=2) {
			TF2Items_SetAttribute(hWeapon, i2, StringToInt(weaponAttribsArray[i]), StringToFloat(weaponAttribsArray[i+1]));
			i2++;
		}
	} else {
		TF2Items_SetNumAttributes(hWeapon, 0);
	}
	
	return hWeapon;
}

public Action:Command_ReloadCustoms(client, args)
{
	if (g_hItemInfoTrie != INVALID_HANDLE)
	{
		CloseHandle(g_hItemInfoTrie);
	}
	g_hItemInfoTrie = INVALID_HANDLE;
	CreateItemInfoTrie();
	ReplyToCommand(client, "[TF2Items] Custom Weapons list for Give Weapons reloaded");
	return Plugin_Handled;
}

CustomItemsTrieSetup()
{
	decl String:strBuffer[256];
	BuildPath(Path_SM, strBuffer, sizeof(strBuffer), "configs/tf2items.givecustom.txt");
	decl String:strBuffer2[256];
	decl String:strBuffer3[256];
	new Handle:hKeyValues = CreateKeyValues("TF2ItemsGiveWeapon");
	if(FileToKeyValues(hKeyValues, strBuffer) == true)
	{
		KvGetSectionName(hKeyValues, strBuffer, sizeof(strBuffer));
		if (StrEqual("custom_give_weapons_vlolz", strBuffer) == true)
		{
			if (KvGotoFirstSubKey(hKeyValues))
			{
				do
				{
					KvGetSectionName(hKeyValues, strBuffer, sizeof(strBuffer));
					if (strBuffer[0] != '*')
					{
						Format(strBuffer2, 32, "%s_%s", strBuffer, "classname");
						KvGetString(hKeyValues, "classname", strBuffer3, sizeof(strBuffer3));
						SetTrieString(g_hItemInfoTrie, strBuffer2, strBuffer3);
						Format(strBuffer2, 32, "%s_%s", strBuffer, "index");
						SetTrieValue(g_hItemInfoTrie, strBuffer2, KvGetNum(hKeyValues, "index"));
						Format(strBuffer2, 32, "%s_%s", strBuffer, "slot");
						SetTrieValue(g_hItemInfoTrie, strBuffer2, KvGetNum(hKeyValues, "slot"));
						Format(strBuffer2, 32, "%s_%s", strBuffer, "quality");
						SetTrieValue(g_hItemInfoTrie, strBuffer2, KvGetNum(hKeyValues, "quality"));
						Format(strBuffer2, 32, "%s_%s", strBuffer, "level");
						SetTrieValue(g_hItemInfoTrie, strBuffer2, KvGetNum(hKeyValues, "level"));
						Format(strBuffer2, 256, "%s_%s", strBuffer, "attribs");
						KvGetString(hKeyValues, "attribs", strBuffer3, sizeof(strBuffer3));
						SetTrieString(g_hItemInfoTrie, strBuffer2, strBuffer3);
						Format(strBuffer2, 32, "%s_%s", strBuffer, "ammo");
						SetTrieValue(g_hItemInfoTrie, strBuffer2, KvGetNum(hKeyValues, "ammo"));
					}
				}
				while (KvGotoNextKey(hKeyValues));
				KvGoBack(hKeyValues);
			}
		}
	}
	CloseHandle(hKeyValues);
}
CreateItemInfoTrie()
{
	g_hItemInfoTrie = CreateTrie();
	decl String:strBuffer[256];
	BuildPath(Path_SM, strBuffer, sizeof(strBuffer), "configs/tf2items.givecustom.txt");
	if(FileExists(strBuffer))	CustomItemsTrieSetup();
	for (new i = 1; i < MaxClients; i++)
	{
		for (new slot = 0; slot < 6; slot++)
		{
			if (g_hItems[i][slot] != -1)
			{
				g_hItems[i][slot] = -1;
			}
		}
	}
//bat
	SetTrieString(g_hItemInfoTrie, "0_classname", "tf_weapon_bat");
	SetTrieValue(g_hItemInfoTrie, "0_index", 0);
	SetTrieValue(g_hItemInfoTrie, "0_slot", 2);
	SetTrieValue(g_hItemInfoTrie, "0_quality", 0);
	SetTrieValue(g_hItemInfoTrie, "0_level", 1);
	SetTrieString(g_hItemInfoTrie, "0_attribs", "");
	SetTrieValue(g_hItemInfoTrie, "0_ammo", -1);

//bottle
	SetTrieString(g_hItemInfoTrie, "1_classname", "tf_weapon_bottle");
	SetTrieValue(g_hItemInfoTrie, "1_index", 1);
	SetTrieValue(g_hItemInfoTrie, "1_slot", 2);
	SetTrieValue(g_hItemInfoTrie, "1_quality", 0);
	SetTrieValue(g_hItemInfoTrie, "1_level", 1);
	SetTrieString(g_hItemInfoTrie, "1_attribs", "");
	SetTrieValue(g_hItemInfoTrie, "1_ammo", -1);

//fire axe
	SetTrieString(g_hItemInfoTrie, "2_classname", "tf_weapon_fireaxe");
	SetTrieValue(g_hItemInfoTrie, "2_index", 2);
	SetTrieValue(g_hItemInfoTrie, "2_slot", 2);
	SetTrieValue(g_hItemInfoTrie, "2_quality", 0);
	SetTrieValue(g_hItemInfoTrie, "2_level", 1);
	SetTrieString(g_hItemInfoTrie, "2_attribs", "");
	SetTrieValue(g_hItemInfoTrie, "2_ammo", -1);

//kukri
	SetTrieString(g_hItemInfoTrie, "3_classname", "tf_weapon_club");
	SetTrieValue(g_hItemInfoTrie, "3_index", 3);
	SetTrieValue(g_hItemInfoTrie, "3_slot", 2);
	SetTrieValue(g_hItemInfoTrie, "3_quality", 0);
	SetTrieValue(g_hItemInfoTrie, "3_level", 1);
	SetTrieString(g_hItemInfoTrie, "3_attribs", "");
	SetTrieValue(g_hItemInfoTrie, "3_ammo", -1);

//knife
	SetTrieString(g_hItemInfoTrie, "4_classname", "tf_weapon_knife");
	SetTrieValue(g_hItemInfoTrie, "4_index", 4);
	SetTrieValue(g_hItemInfoTrie, "4_slot", 2);
	SetTrieValue(g_hItemInfoTrie, "4_quality", 0);
	SetTrieValue(g_hItemInfoTrie, "4_level", 1);
	SetTrieString(g_hItemInfoTrie, "4_attribs", "");
	SetTrieValue(g_hItemInfoTrie, "4_ammo", -1);

//fists
	SetTrieString(g_hItemInfoTrie, "5_classname", "tf_weapon_fists");
	SetTrieValue(g_hItemInfoTrie, "5_index", 5);
	SetTrieValue(g_hItemInfoTrie, "5_slot", 2);
	SetTrieValue(g_hItemInfoTrie, "5_quality", 0);
	SetTrieValue(g_hItemInfoTrie, "5_level", 1);
	SetTrieString(g_hItemInfoTrie, "5_attribs", "");
	SetTrieValue(g_hItemInfoTrie, "5_ammo", -1);

//shovel
	SetTrieString(g_hItemInfoTrie, "6_classname", "tf_weapon_shovel");
	SetTrieValue(g_hItemInfoTrie, "6_index", 6);
	SetTrieValue(g_hItemInfoTrie, "6_slot", 2);
	SetTrieValue(g_hItemInfoTrie, "6_quality", 0);
	SetTrieValue(g_hItemInfoTrie, "6_level", 1);
	SetTrieString(g_hItemInfoTrie, "6_attribs", "");
	SetTrieValue(g_hItemInfoTrie, "6_ammo", -1);

//wrench
	SetTrieString(g_hItemInfoTrie, "7_classname", "tf_weapon_wrench");
	SetTrieValue(g_hItemInfoTrie, "7_index", 7);
	SetTrieValue(g_hItemInfoTrie, "7_slot", 2);
	SetTrieValue(g_hItemInfoTrie, "7_quality", 0);
	SetTrieValue(g_hItemInfoTrie, "7_level", 1);
	SetTrieString(g_hItemInfoTrie, "7_attribs", "");
	SetTrieValue(g_hItemInfoTrie, "7_ammo", -1);

//bonesaw
	SetTrieString(g_hItemInfoTrie, "8_classname", "tf_weapon_bonesaw");
	SetTrieValue(g_hItemInfoTrie, "8_index", 8);
	SetTrieValue(g_hItemInfoTrie, "8_slot", 2);
	SetTrieValue(g_hItemInfoTrie, "8_quality", 0);
	SetTrieValue(g_hItemInfoTrie, "8_level", 1);
	SetTrieString(g_hItemInfoTrie, "8_attribs", "");
	SetTrieValue(g_hItemInfoTrie, "8_ammo", -1);

//shotgun engineer
	SetTrieString(g_hItemInfoTrie, "9_classname", "tf_weapon_shotgun_primary");
	SetTrieValue(g_hItemInfoTrie, "9_index", 9);
	SetTrieValue(g_hItemInfoTrie, "9_slot", 0);
	SetTrieValue(g_hItemInfoTrie, "9_quality", 0);
	SetTrieValue(g_hItemInfoTrie, "9_level", 1);
	SetTrieString(g_hItemInfoTrie, "9_attribs", "");
	SetTrieValue(g_hItemInfoTrie, "9_ammo", 32);

//shotgun soldier
	SetTrieString(g_hItemInfoTrie, "10_classname", "tf_weapon_shotgun_soldier");
	SetTrieValue(g_hItemInfoTrie, "10_index", 10);
	SetTrieValue(g_hItemInfoTrie, "10_slot", 1);
	SetTrieValue(g_hItemInfoTrie, "10_quality", 0);
	SetTrieValue(g_hItemInfoTrie, "10_level", 1);
	SetTrieString(g_hItemInfoTrie, "10_attribs", "");
	SetTrieValue(g_hItemInfoTrie, "10_ammo", 32);

//shotgun heavy
	SetTrieString(g_hItemInfoTrie, "11_classname", "tf_weapon_shotgun_hwg");
	SetTrieValue(g_hItemInfoTrie, "11_index", 11);
	SetTrieValue(g_hItemInfoTrie, "11_slot", 1);
	SetTrieValue(g_hItemInfoTrie, "11_quality", 0);
	SetTrieValue(g_hItemInfoTrie, "11_level", 1);
	SetTrieString(g_hItemInfoTrie, "11_attribs", "");
	SetTrieValue(g_hItemInfoTrie, "11_ammo", 32);

//shotgun pyro
	SetTrieString(g_hItemInfoTrie, "12_classname", "tf_weapon_shotgun_pyro");
	SetTrieValue(g_hItemInfoTrie, "12_index", 12);
	SetTrieValue(g_hItemInfoTrie, "12_slot", 1);
	SetTrieValue(g_hItemInfoTrie, "12_quality", 0);
	SetTrieValue(g_hItemInfoTrie, "12_level", 1);
	SetTrieString(g_hItemInfoTrie, "12_attribs", "");
	SetTrieValue(g_hItemInfoTrie, "12_ammo", 32);

//scattergun
	SetTrieString(g_hItemInfoTrie, "13_classname", "tf_weapon_scattergun");
	SetTrieValue(g_hItemInfoTrie, "13_index", 13);
	SetTrieValue(g_hItemInfoTrie, "13_slot", 0);
	SetTrieValue(g_hItemInfoTrie, "13_quality", 0);
	SetTrieValue(g_hItemInfoTrie, "13_level", 1);
	SetTrieString(g_hItemInfoTrie, "13_attribs", "");
	SetTrieValue(g_hItemInfoTrie, "13_ammo", 32);

//sniper rifle
	SetTrieString(g_hItemInfoTrie, "14_classname", "tf_weapon_sniperrifle");
	SetTrieValue(g_hItemInfoTrie, "14_index", 14);
	SetTrieValue(g_hItemInfoTrie, "14_slot", 0);
	SetTrieValue(g_hItemInfoTrie, "14_quality", 0);
	SetTrieValue(g_hItemInfoTrie, "14_level", 1);
	SetTrieString(g_hItemInfoTrie, "14_attribs", "");
	SetTrieValue(g_hItemInfoTrie, "14_ammo", 25);

//minigun
	SetTrieString(g_hItemInfoTrie, "15_classname", "tf_weapon_minigun");
	SetTrieValue(g_hItemInfoTrie, "15_index", 15);
	SetTrieValue(g_hItemInfoTrie, "15_slot", 0);
	SetTrieValue(g_hItemInfoTrie, "15_quality", 0);
	SetTrieValue(g_hItemInfoTrie, "15_level", 1);
	SetTrieString(g_hItemInfoTrie, "15_attribs", "");
	SetTrieValue(g_hItemInfoTrie, "15_ammo", 200);

//smg
	SetTrieString(g_hItemInfoTrie, "16_classname", "tf_weapon_smg");
	SetTrieValue(g_hItemInfoTrie, "16_index", 16);
	SetTrieValue(g_hItemInfoTrie, "16_slot", 1);
	SetTrieValue(g_hItemInfoTrie, "16_quality", 0);
	SetTrieValue(g_hItemInfoTrie, "16_level", 1);
	SetTrieString(g_hItemInfoTrie, "16_attribs", "");
	SetTrieValue(g_hItemInfoTrie, "16_ammo", 75);

//syringe gun
	SetTrieString(g_hItemInfoTrie, "17_classname", "tf_weapon_syringegun_medic");
	SetTrieValue(g_hItemInfoTrie, "17_index", 17);
	SetTrieValue(g_hItemInfoTrie, "17_slot", 0);
	SetTrieValue(g_hItemInfoTrie, "17_quality", 0);
	SetTrieValue(g_hItemInfoTrie, "17_level", 1);
	SetTrieString(g_hItemInfoTrie, "17_attribs", "");
	SetTrieValue(g_hItemInfoTrie, "17_ammo", 150);

//rocket launcher
	SetTrieString(g_hItemInfoTrie, "18_classname", "tf_weapon_rocketlauncher");
	SetTrieValue(g_hItemInfoTrie, "18_index", 18);
	SetTrieValue(g_hItemInfoTrie, "18_slot", 0);
	SetTrieValue(g_hItemInfoTrie, "18_quality", 0);
	SetTrieValue(g_hItemInfoTrie, "18_level", 1);
	SetTrieString(g_hItemInfoTrie, "18_attribs", "");
	SetTrieValue(g_hItemInfoTrie, "18_ammo", 20);

//grenade launcher
	SetTrieString(g_hItemInfoTrie, "19_classname", "tf_weapon_grenadelauncher");
	SetTrieValue(g_hItemInfoTrie, "19_index", 19);
	SetTrieValue(g_hItemInfoTrie, "19_slot", 0);
	SetTrieValue(g_hItemInfoTrie, "19_quality", 0);
	SetTrieValue(g_hItemInfoTrie, "19_level", 1);
	SetTrieString(g_hItemInfoTrie, "19_attribs", "");
	SetTrieValue(g_hItemInfoTrie, "19_ammo", 16);

//sticky launcher
	SetTrieString(g_hItemInfoTrie, "20_classname", "tf_weapon_pipebomblauncher");
	SetTrieValue(g_hItemInfoTrie, "20_index", 20);
	SetTrieValue(g_hItemInfoTrie, "20_slot", 1);
	SetTrieValue(g_hItemInfoTrie, "20_quality", 0);
	SetTrieValue(g_hItemInfoTrie, "20_level", 1);
	SetTrieString(g_hItemInfoTrie, "20_attribs", "");
	SetTrieValue(g_hItemInfoTrie, "20_ammo", 24);

//flamethrower
	SetTrieString(g_hItemInfoTrie, "21_classname", "tf_weapon_flamethrower");
	SetTrieValue(g_hItemInfoTrie, "21_index", 21);
	SetTrieValue(g_hItemInfoTrie, "21_slot", 0);
	SetTrieValue(g_hItemInfoTrie, "21_quality", 0);
	SetTrieValue(g_hItemInfoTrie, "21_level", 1);
	SetTrieString(g_hItemInfoTrie, "21_attribs", "");
	SetTrieValue(g_hItemInfoTrie, "21_ammo", 200);

//pistol engineer
	SetTrieString(g_hItemInfoTrie, "22_classname", "tf_weapon_pistol");
	SetTrieValue(g_hItemInfoTrie, "22_index", 22);
	SetTrieValue(g_hItemInfoTrie, "22_slot", 1);
	SetTrieValue(g_hItemInfoTrie, "22_quality", 0);
	SetTrieValue(g_hItemInfoTrie, "22_level", 1);
	SetTrieString(g_hItemInfoTrie, "22_attribs", "");
	SetTrieValue(g_hItemInfoTrie, "22_ammo", 200);

//pistol scout
	SetTrieString(g_hItemInfoTrie, "23_classname", "tf_weapon_pistol_scout");
	SetTrieValue(g_hItemInfoTrie, "23_index", 23);
	SetTrieValue(g_hItemInfoTrie, "23_slot", 1);
	SetTrieValue(g_hItemInfoTrie, "23_quality", 0);
	SetTrieValue(g_hItemInfoTrie, "23_level", 1);
	SetTrieString(g_hItemInfoTrie, "23_attribs", "");
	SetTrieValue(g_hItemInfoTrie, "23_ammo", 36);

//revolver
	SetTrieString(g_hItemInfoTrie, "24_classname", "tf_weapon_revolver");
	SetTrieValue(g_hItemInfoTrie, "24_index", 24);
	SetTrieValue(g_hItemInfoTrie, "24_slot", 0);
	SetTrieValue(g_hItemInfoTrie, "24_quality", 0);
	SetTrieValue(g_hItemInfoTrie, "24_level", 1);
	SetTrieString(g_hItemInfoTrie, "24_attribs", "");
	SetTrieValue(g_hItemInfoTrie, "24_ammo", 24);

//build pda engineer
	SetTrieString(g_hItemInfoTrie, "25_classname", "tf_weapon_pda_engineer_build");
	SetTrieValue(g_hItemInfoTrie, "25_index", 25);
	SetTrieValue(g_hItemInfoTrie, "25_slot", 3);
	SetTrieValue(g_hItemInfoTrie, "25_quality", 0);
	SetTrieValue(g_hItemInfoTrie, "25_level", 1);
	SetTrieString(g_hItemInfoTrie, "25_attribs", "");
	SetTrieValue(g_hItemInfoTrie, "25_ammo", -1);

//destroy pda engineer
	SetTrieString(g_hItemInfoTrie, "26_classname", "tf_weapon_pda_engineer_destroy");
	SetTrieValue(g_hItemInfoTrie, "26_index", 26);
	SetTrieValue(g_hItemInfoTrie, "26_slot", 4);
	SetTrieValue(g_hItemInfoTrie, "26_quality", 0);
	SetTrieValue(g_hItemInfoTrie, "26_level", 1);
	SetTrieString(g_hItemInfoTrie, "26_attribs", "");
	SetTrieValue(g_hItemInfoTrie, "26_ammo", -1);

//disguise kit spy
	SetTrieString(g_hItemInfoTrie, "27_classname", "tf_weapon_pda_spy");
	SetTrieValue(g_hItemInfoTrie, "27_index", 27);
	SetTrieValue(g_hItemInfoTrie, "27_slot", 3);
	SetTrieValue(g_hItemInfoTrie, "27_quality", 0);
	SetTrieValue(g_hItemInfoTrie, "27_level", 1);
	SetTrieString(g_hItemInfoTrie, "27_attribs", "");
	SetTrieValue(g_hItemInfoTrie, "27_ammo", -1);

//builder
	SetTrieString(g_hItemInfoTrie, "28_classname", "tf_weapon_builder");
	SetTrieValue(g_hItemInfoTrie, "28_index", 28);
	SetTrieValue(g_hItemInfoTrie, "28_slot", 5);
	SetTrieValue(g_hItemInfoTrie, "28_quality", 0);
	SetTrieValue(g_hItemInfoTrie, "28_level", 1);
	SetTrieString(g_hItemInfoTrie, "28_attribs", "");
	SetTrieValue(g_hItemInfoTrie, "28_ammo", -1);

//medigun
	SetTrieString(g_hItemInfoTrie, "29_classname", "tf_weapon_medigun");
	SetTrieValue(g_hItemInfoTrie, "29_index", 29);
	SetTrieValue(g_hItemInfoTrie, "29_slot", 1);
	SetTrieValue(g_hItemInfoTrie, "29_quality", 0);
	SetTrieValue(g_hItemInfoTrie, "29_level", 1);
	SetTrieString(g_hItemInfoTrie, "29_attribs", "");
	SetTrieValue(g_hItemInfoTrie, "29_ammo", -1);

//invis watch
	SetTrieString(g_hItemInfoTrie, "30_classname", "tf_weapon_invis");
	SetTrieValue(g_hItemInfoTrie, "30_index", 30);
	SetTrieValue(g_hItemInfoTrie, "30_slot", 4);
	SetTrieValue(g_hItemInfoTrie, "30_quality", 0);
	SetTrieValue(g_hItemInfoTrie, "30_level", 1);
	SetTrieString(g_hItemInfoTrie, "30_attribs", "");
	SetTrieValue(g_hItemInfoTrie, "30_ammo", -1);

//kritzkrieg
	SetTrieString(g_hItemInfoTrie, "35_classname", "tf_weapon_medigun");
	SetTrieValue(g_hItemInfoTrie, "35_index", 35);
	SetTrieValue(g_hItemInfoTrie, "35_slot", 1);
	SetTrieValue(g_hItemInfoTrie, "35_quality", 6);
	SetTrieValue(g_hItemInfoTrie, "35_level", 8);
	SetTrieString(g_hItemInfoTrie, "35_attribs", "18 ; 1.0 ; 10 ; 1.25");
	SetTrieValue(g_hItemInfoTrie, "35_ammo", -1);

//blutsauger
	SetTrieString(g_hItemInfoTrie, "36_classname", "tf_weapon_syringegun_medic");
	SetTrieValue(g_hItemInfoTrie, "36_index", 36);
	SetTrieValue(g_hItemInfoTrie, "36_slot", 0);
	SetTrieValue(g_hItemInfoTrie, "36_quality", 6);
	SetTrieValue(g_hItemInfoTrie, "36_level", 5);
	SetTrieString(g_hItemInfoTrie, "36_attribs", "16 ; 3.0 ; 129 ; -2.0");
	SetTrieValue(g_hItemInfoTrie, "36_ammo", 150);

//ubersaw
	SetTrieString(g_hItemInfoTrie, "37_classname", "tf_weapon_bonesaw");
	SetTrieValue(g_hItemInfoTrie, "37_index", 37);
	SetTrieValue(g_hItemInfoTrie, "37_slot", 2);
	SetTrieValue(g_hItemInfoTrie, "37_quality", 6);
	SetTrieValue(g_hItemInfoTrie, "37_level", 10);
	SetTrieString(g_hItemInfoTrie, "37_attribs", "17 ; 0.25 ; 5 ; 1.2");
	SetTrieValue(g_hItemInfoTrie, "37_ammo", -1);

//axetinguisher
	SetTrieString(g_hItemInfoTrie, "38_classname", "tf_weapon_fireaxe");
	SetTrieValue(g_hItemInfoTrie, "38_index", 38);
	SetTrieValue(g_hItemInfoTrie, "38_slot", 2);
	SetTrieValue(g_hItemInfoTrie, "38_quality", 6);
	SetTrieValue(g_hItemInfoTrie, "38_level", 10);
	SetTrieString(g_hItemInfoTrie, "38_attribs", "20 ; 1.0 ; 21 ; 0.5 ; 22 ; 1.0");
	SetTrieValue(g_hItemInfoTrie, "38_ammo", -1);

//flaregun pyro
	SetTrieString(g_hItemInfoTrie, "39_classname", "tf_weapon_flaregun");
	SetTrieValue(g_hItemInfoTrie, "39_index", 39);
	SetTrieValue(g_hItemInfoTrie, "39_slot", 1);
	SetTrieValue(g_hItemInfoTrie, "39_quality", 6);
	SetTrieValue(g_hItemInfoTrie, "39_level", 10);
	SetTrieString(g_hItemInfoTrie, "39_attribs", "25 ; 0.5");
	SetTrieValue(g_hItemInfoTrie, "39_ammo", 16);

//backburner
	SetTrieString(g_hItemInfoTrie, "40_classname", "tf_weapon_flamethrower");
	SetTrieValue(g_hItemInfoTrie, "40_index", 40);
	SetTrieValue(g_hItemInfoTrie, "40_slot", 0);
	SetTrieValue(g_hItemInfoTrie, "40_quality", 6);
	SetTrieValue(g_hItemInfoTrie, "40_level", 10);
	SetTrieString(g_hItemInfoTrie, "40_attribs", "23 ; 1.0 ; 24 ; 1.0 ; 28 ; 0.0 ; 2 ; 1.15");
	SetTrieValue(g_hItemInfoTrie, "40_ammo", 200);

//natascha
	SetTrieString(g_hItemInfoTrie, "41_classname", "tf_weapon_minigun");
	SetTrieValue(g_hItemInfoTrie, "41_index", 41);
	SetTrieValue(g_hItemInfoTrie, "41_slot", 0);
	SetTrieValue(g_hItemInfoTrie, "41_quality", 6);
	SetTrieValue(g_hItemInfoTrie, "41_level", 5);
	SetTrieString(g_hItemInfoTrie, "41_attribs", "32 ; 1.0 ; 1 ; 0.75");
	SetTrieValue(g_hItemInfoTrie, "41_ammo", 200);

//sandvich
	SetTrieString(g_hItemInfoTrie, "42_classname", "tf_weapon_lunchbox");
	SetTrieValue(g_hItemInfoTrie, "42_index", 42);
	SetTrieValue(g_hItemInfoTrie, "42_slot", 1);
	SetTrieValue(g_hItemInfoTrie, "42_quality", 6);
	SetTrieValue(g_hItemInfoTrie, "42_level", 1);
	SetTrieString(g_hItemInfoTrie, "42_attribs", "");
	SetTrieValue(g_hItemInfoTrie, "42_ammo", 1);

//killing gloves of boxing
	SetTrieString(g_hItemInfoTrie, "43_classname", "tf_weapon_fists");
	SetTrieValue(g_hItemInfoTrie, "43_index", 43);
	SetTrieValue(g_hItemInfoTrie, "43_slot", 2);
	SetTrieValue(g_hItemInfoTrie, "43_quality", 6);
	SetTrieValue(g_hItemInfoTrie, "43_level", 7);
	SetTrieString(g_hItemInfoTrie, "43_attribs", "31 ; 5.0 ; 5 ; 1.2");
	SetTrieValue(g_hItemInfoTrie, "43_ammo", -1);

//sandman
	SetTrieString(g_hItemInfoTrie, "44_classname", "tf_weapon_bat_wood");
	SetTrieValue(g_hItemInfoTrie, "44_index", 44);
	SetTrieValue(g_hItemInfoTrie, "44_slot", 2);
	SetTrieValue(g_hItemInfoTrie, "44_quality", 6);
	SetTrieValue(g_hItemInfoTrie, "44_level", 15);
	SetTrieString(g_hItemInfoTrie, "44_attribs", "38 ; 1.0 ; 125 ; -15.0");
	SetTrieValue(g_hItemInfoTrie, "44_ammo", 1);

//force a nature
	SetTrieString(g_hItemInfoTrie, "45_classname", "tf_weapon_scattergun");
	SetTrieValue(g_hItemInfoTrie, "45_index", 45);
	SetTrieValue(g_hItemInfoTrie, "45_slot", 0);
	SetTrieValue(g_hItemInfoTrie, "45_quality", 6);
	SetTrieValue(g_hItemInfoTrie, "45_level", 10);
	SetTrieString(g_hItemInfoTrie, "45_attribs", "44 ; 1.0 ; 6 ; 0.5 ; 45 ; 1.2 ; 1 ; 0.9 ; 3 ; 0.4 ; 43 ; 1.0");
	SetTrieValue(g_hItemInfoTrie, "45_ammo", 32);

//bonk atomic punch
	SetTrieString(g_hItemInfoTrie, "46_classname", "tf_weapon_lunchbox_drink");
	SetTrieValue(g_hItemInfoTrie, "46_index", 46);
	SetTrieValue(g_hItemInfoTrie, "46_slot", 1);
	SetTrieValue(g_hItemInfoTrie, "46_quality", 6);
	SetTrieValue(g_hItemInfoTrie, "46_level", 5);
	SetTrieString(g_hItemInfoTrie, "46_attribs", "");
	SetTrieValue(g_hItemInfoTrie, "46_ammo", 1);

//hunstman
	SetTrieString(g_hItemInfoTrie, "56_classname", "tf_weapon_compound_bow");
	SetTrieValue(g_hItemInfoTrie, "56_index", 56);
	SetTrieValue(g_hItemInfoTrie, "56_slot", 0);
	SetTrieValue(g_hItemInfoTrie, "56_quality", 6);
	SetTrieValue(g_hItemInfoTrie, "56_level", 10);
	SetTrieString(g_hItemInfoTrie, "56_attribs", "37 ; 0.5");
	SetTrieValue(g_hItemInfoTrie, "56_ammo", 12);

//razorback (broken)
//	SetTrieString(g_hItemInfoTrie, "57_classname", "tf_wearable_shield");
//	SetTrieValue(g_hItemInfoTrie, "57_index", 57);
//	SetTrieValue(g_hItemInfoTrie, "57_slot", 1);
//	SetTrieValue(g_hItemInfoTrie, "57_quality", 6);
//	SetTrieValue(g_hItemInfoTrie, "57_level", 10);
//	SetTrieString(g_hItemInfoTrie, "57_attribs", "52 ; 1");

//jarate
	SetTrieString(g_hItemInfoTrie, "58_classname", "tf_weapon_jar");
	SetTrieValue(g_hItemInfoTrie, "58_index", 58);
	SetTrieValue(g_hItemInfoTrie, "58_slot", 1);
	SetTrieValue(g_hItemInfoTrie, "58_quality", 6);
	SetTrieValue(g_hItemInfoTrie, "58_level", 5);
	SetTrieString(g_hItemInfoTrie, "58_attribs", "56 ; 1.0");
	SetTrieValue(g_hItemInfoTrie, "58_ammo", 1);

//dead ringer
	SetTrieString(g_hItemInfoTrie, "59_classname", "tf_weapon_invis");
	SetTrieValue(g_hItemInfoTrie, "59_index", 59);
	SetTrieValue(g_hItemInfoTrie, "59_slot", 4);
	SetTrieValue(g_hItemInfoTrie, "59_quality", 6);
	SetTrieValue(g_hItemInfoTrie, "59_level", 5);
	SetTrieString(g_hItemInfoTrie, "59_attribs", "33 ; 1.0 ; 34 ; 1.6 ; 35 ; 1.8");
	SetTrieValue(g_hItemInfoTrie, "59_ammo", -1);

//cloak and dagger
	SetTrieString(g_hItemInfoTrie, "60_classname", "tf_weapon_invis");
	SetTrieValue(g_hItemInfoTrie, "60_index", 60);
	SetTrieValue(g_hItemInfoTrie, "60_slot", 4);
	SetTrieValue(g_hItemInfoTrie, "60_quality", 6);
	SetTrieValue(g_hItemInfoTrie, "60_level", 5);
	SetTrieString(g_hItemInfoTrie, "60_attribs", "48 ; 2.0 ; 35 ; 2.0");
	SetTrieValue(g_hItemInfoTrie, "60_ammo", -1);

//ambassador
	SetTrieString(g_hItemInfoTrie, "61_classname", "tf_weapon_revolver");
	SetTrieValue(g_hItemInfoTrie, "61_index", 61);
	SetTrieValue(g_hItemInfoTrie, "61_slot", 0);
	SetTrieValue(g_hItemInfoTrie, "61_quality", 6);
	SetTrieValue(g_hItemInfoTrie, "61_level", 5);
	SetTrieString(g_hItemInfoTrie, "61_attribs", "51 ; 1.0 ; 1 ; 0.85 ; 5 ; 1.2");
	SetTrieValue(g_hItemInfoTrie, "61_ammo", 24);

//direct hit
	SetTrieString(g_hItemInfoTrie, "127_classname", "tf_weapon_rocketlauncher_directhit");
	SetTrieValue(g_hItemInfoTrie, "127_index", 127);
	SetTrieValue(g_hItemInfoTrie, "127_slot", 0);
	SetTrieValue(g_hItemInfoTrie, "127_quality", 6);
	SetTrieValue(g_hItemInfoTrie, "127_level", 1);
	SetTrieString(g_hItemInfoTrie, "127_attribs", "100 ; 0.3 ; 103 ; 1.8 ; 2 ; 1.25 ; 114 ; 1.0");
	SetTrieValue(g_hItemInfoTrie, "127_ammo", 20);

//equalizer
	SetTrieString(g_hItemInfoTrie, "128_classname", "tf_weapon_shovel");
	SetTrieValue(g_hItemInfoTrie, "128_index", 128);
	SetTrieValue(g_hItemInfoTrie, "128_slot", 2);
	SetTrieValue(g_hItemInfoTrie, "128_quality", 6);
	SetTrieValue(g_hItemInfoTrie, "128_level", 10);
	SetTrieString(g_hItemInfoTrie, "128_attribs", "115 ; 1.0");
	SetTrieValue(g_hItemInfoTrie, "128_ammo", -1);

//buff banner
	SetTrieString(g_hItemInfoTrie, "129_classname", "tf_weapon_buff_item");
	SetTrieValue(g_hItemInfoTrie, "129_index", 129);
	SetTrieValue(g_hItemInfoTrie, "129_slot", 1);
	SetTrieValue(g_hItemInfoTrie, "129_quality", 6);
	SetTrieValue(g_hItemInfoTrie, "129_level", 5);
	SetTrieString(g_hItemInfoTrie, "129_attribs", "116 ; 1");
	SetTrieValue(g_hItemInfoTrie, "129_ammo", -1);

//scottish resistance
	SetTrieString(g_hItemInfoTrie, "130_classname", "tf_weapon_pipebomblauncher");
	SetTrieValue(g_hItemInfoTrie, "130_index", 130);
	SetTrieValue(g_hItemInfoTrie, "130_slot", 1);
	SetTrieValue(g_hItemInfoTrie, "130_quality", 6);
	SetTrieValue(g_hItemInfoTrie, "130_level", 5);
	SetTrieString(g_hItemInfoTrie, "130_attribs", "6 ; 0.75 ; 119 ; 1.0 ; 121 ; 1.0 ; 78 ; 1.5 ; 88 ; 6.0 ; 120 ; 0.8");
	SetTrieValue(g_hItemInfoTrie, "130_ammo", 24);

//chargin targe (broken)
//	SetTrieString(g_hItemInfoTrie, "131_classname", "tf_unique_achievement_shield");
//	SetTrieValue(g_hItemInfoTrie, "131_index", 131);
//	SetTrieValue(g_hItemInfoTrie, "131_slot", 0);
//	SetTrieValue(g_hItemInfoTrie, "131_quality", 6);
//	SetTrieValue(g_hItemInfoTrie, "131_level", 10);
//	SetTrieString(g_hItemInfoTrie, "131_attribs", "60 ; 0.5 ; 64 ; 0.6");

//eyelander
	SetTrieString(g_hItemInfoTrie, "132_classname", "tf_weapon_sword");
	SetTrieValue(g_hItemInfoTrie, "132_index", 132);
	SetTrieValue(g_hItemInfoTrie, "132_slot", 2);
	SetTrieValue(g_hItemInfoTrie, "132_quality", 6);
	SetTrieValue(g_hItemInfoTrie, "132_level", 5);
	SetTrieString(g_hItemInfoTrie, "132_attribs", "15 ; 0 ; 125 ; -25");
	SetTrieValue(g_hItemInfoTrie, "132_ammo", -1);

//gunboats (broken)
//	SetTrieString(g_hItemInfoTrie, "133_classname", "tf_unique_blast_boots");
//	SetTrieValue(g_hItemInfoTrie, "133_index", 133);
//	SetTrieValue(g_hItemInfoTrie, "133_slot", 1);
//	SetTrieValue(g_hItemInfoTrie, "133_quality", 6);
//	SetTrieValue(g_hItemInfoTrie, "133_level", 10);
//	SetTrieString(g_hItemInfoTrie, "133_attribs", "135 ; 0.4");

//wrangler
	SetTrieString(g_hItemInfoTrie, "140_classname", "tf_weapon_laser_pointer");
	SetTrieValue(g_hItemInfoTrie, "140_index", 140);
	SetTrieValue(g_hItemInfoTrie, "140_slot", 1);
	SetTrieValue(g_hItemInfoTrie, "140_quality", 6);
	SetTrieValue(g_hItemInfoTrie, "140_level", 5);
	SetTrieString(g_hItemInfoTrie, "140_attribs", "");
	SetTrieValue(g_hItemInfoTrie, "140_ammo", -1);

//frontier justice
	SetTrieString(g_hItemInfoTrie, "141_classname", "tf_weapon_sentry_revenge");
	SetTrieValue(g_hItemInfoTrie, "141_index", 141);
	SetTrieValue(g_hItemInfoTrie, "141_slot", 0);
	SetTrieValue(g_hItemInfoTrie, "141_quality", 6);
	SetTrieValue(g_hItemInfoTrie, "141_level", 5);
	SetTrieString(g_hItemInfoTrie, "141_attribs", "136 ; 1 ; 15 ; 0 ; 3 ; 0.5");
	SetTrieValue(g_hItemInfoTrie, "141_ammo", 32);

//gunslinger
	SetTrieString(g_hItemInfoTrie, "142_classname", "tf_weapon_robot_arm");
	SetTrieValue(g_hItemInfoTrie, "142_index", 142);
	SetTrieValue(g_hItemInfoTrie, "142_slot", 2);
	SetTrieValue(g_hItemInfoTrie, "142_quality", 6);
	SetTrieValue(g_hItemInfoTrie, "142_level", 15);
	SetTrieString(g_hItemInfoTrie, "142_attribs", "124 ; 1 ; 26 ; 25.0 ; 15 ; 0");
	SetTrieValue(g_hItemInfoTrie, "142_ammo", -1);

//homewrecker
	SetTrieString(g_hItemInfoTrie, "153_classname", "tf_weapon_fireaxe");
	SetTrieValue(g_hItemInfoTrie, "153_index", 153);
	SetTrieValue(g_hItemInfoTrie, "153_slot", 2);
	SetTrieValue(g_hItemInfoTrie, "153_quality", 6);
	SetTrieValue(g_hItemInfoTrie, "153_level", 5);
	SetTrieString(g_hItemInfoTrie, "153_attribs", "137 ; 2.0 ; 138 ; 0.75 ; 146 ; 1");
	SetTrieValue(g_hItemInfoTrie, "153_ammo", -1);

//pain train
	SetTrieString(g_hItemInfoTrie, "154_classname", "tf_weapon_shovel");
	SetTrieValue(g_hItemInfoTrie, "154_index", 154);
	SetTrieValue(g_hItemInfoTrie, "154_slot", 2);
	SetTrieValue(g_hItemInfoTrie, "154_quality", 6);
	SetTrieValue(g_hItemInfoTrie, "154_level", 5);
	SetTrieString(g_hItemInfoTrie, "154_attribs", "68 ; 1 ; 67 ; 1.1");
	SetTrieValue(g_hItemInfoTrie, "154_ammo", -1);

//southern hospitality
	SetTrieString(g_hItemInfoTrie, "155_classname", "tf_weapon_wrench");
	SetTrieValue(g_hItemInfoTrie, "155_index", 155);
	SetTrieValue(g_hItemInfoTrie, "155_slot", 2);
	SetTrieValue(g_hItemInfoTrie, "155_quality", 6);
	SetTrieValue(g_hItemInfoTrie, "155_level", 20);
	SetTrieString(g_hItemInfoTrie, "155_attribs", "15 ; 0 ; 149 ; 5 ; 61 ; 1.20");
	SetTrieValue(g_hItemInfoTrie, "155_ammo", -1);

//dalokohs bar
	SetTrieString(g_hItemInfoTrie, "159_classname", "tf_weapon_lunchbox");
	SetTrieValue(g_hItemInfoTrie, "159_index", 159);
	SetTrieValue(g_hItemInfoTrie, "159_slot", 1);
	SetTrieValue(g_hItemInfoTrie, "159_quality", 6);
	SetTrieValue(g_hItemInfoTrie, "159_level", 1);
	SetTrieString(g_hItemInfoTrie, "159_attribs", "139 ; 1");
	SetTrieValue(g_hItemInfoTrie, "159_ammo", 1);

//lugermorph
	SetTrieString(g_hItemInfoTrie, "160_classname", "tf_weapon_pistol");
	SetTrieValue(g_hItemInfoTrie, "160_index", 160);
	SetTrieValue(g_hItemInfoTrie, "160_slot", 1);
	SetTrieValue(g_hItemInfoTrie, "160_quality", 3);
	SetTrieValue(g_hItemInfoTrie, "160_level", 5);
	SetTrieString(g_hItemInfoTrie, "160_attribs", "");
	SetTrieValue(g_hItemInfoTrie, "160_ammo", 36);

//big kill
	SetTrieString(g_hItemInfoTrie, "161_classname", "tf_weapon_revolver");
	SetTrieValue(g_hItemInfoTrie, "161_index", 161);
	SetTrieValue(g_hItemInfoTrie, "161_slot", 0);
	SetTrieValue(g_hItemInfoTrie, "161_quality", 6);
	SetTrieValue(g_hItemInfoTrie, "161_level", 5);
	SetTrieString(g_hItemInfoTrie, "161_attribs", "");
	SetTrieValue(g_hItemInfoTrie, "161_ammo", 24);

//crit a cola
	SetTrieString(g_hItemInfoTrie, "163_classname", "tf_weapon_lunchbox_drink");
	SetTrieValue(g_hItemInfoTrie, "163_index", 163);
	SetTrieValue(g_hItemInfoTrie, "163_slot", 1);
	SetTrieValue(g_hItemInfoTrie, "163_quality", 6);
	SetTrieValue(g_hItemInfoTrie, "163_level", 5);
	SetTrieString(g_hItemInfoTrie, "163_attribs", "144 ; 2");
	SetTrieValue(g_hItemInfoTrie, "163_ammo", 1);

//golden wrench
	SetTrieString(g_hItemInfoTrie, "169_classname", "tf_weapon_wrench");
	SetTrieValue(g_hItemInfoTrie, "169_index", 169);
	SetTrieValue(g_hItemInfoTrie, "169_slot", 2);
	SetTrieValue(g_hItemInfoTrie, "169_quality", 6);
	SetTrieValue(g_hItemInfoTrie, "169_level", 25);
	SetTrieString(g_hItemInfoTrie, "169_attribs", "150 ; 1");
	SetTrieValue(g_hItemInfoTrie, "169_ammo", -1);

//tribalmans shiv
	SetTrieString(g_hItemInfoTrie, "171_classname", "tf_weapon_club");
	SetTrieValue(g_hItemInfoTrie, "171_index", 171);
	SetTrieValue(g_hItemInfoTrie, "171_slot", 2);
	SetTrieValue(g_hItemInfoTrie, "171_quality", 6);
	SetTrieValue(g_hItemInfoTrie, "171_level", 5);
	SetTrieString(g_hItemInfoTrie, "171_attribs", "149 ; 6 ; 1 ; 0.5");
	SetTrieValue(g_hItemInfoTrie, "171_ammo", -1);

//scotsmans skullcutter
	SetTrieString(g_hItemInfoTrie, "172_classname", "tf_weapon_sword");
	SetTrieValue(g_hItemInfoTrie, "172_index", 172);
	SetTrieValue(g_hItemInfoTrie, "172_slot", 2);
	SetTrieValue(g_hItemInfoTrie, "172_quality", 6);
	SetTrieValue(g_hItemInfoTrie, "172_level", 5);
	SetTrieString(g_hItemInfoTrie, "172_attribs", "2 ; 1.2 ; 54 ; 0.85");
	SetTrieValue(g_hItemInfoTrie, "172_ammo", -1);

//The Vita-Saw
	SetTrieString(g_hItemInfoTrie, "173_classname", "tf_weapon_bonesaw");
	SetTrieValue(g_hItemInfoTrie, "173_index", 173);
	SetTrieValue(g_hItemInfoTrie, "173_slot", 2);
	SetTrieValue(g_hItemInfoTrie, "173_quality", 6);
	SetTrieValue(g_hItemInfoTrie, "173_level", 5);
	SetTrieString(g_hItemInfoTrie, "173_attribs", "188 ; 20 ; 125 ; -10");
	SetTrieValue(g_hItemInfoTrie, "173_ammo", -1);

//The Powerjack
	SetTrieString(g_hItemInfoTrie, "214_classname", "tf_weapon_fireaxe");
	SetTrieValue(g_hItemInfoTrie, "214_index", 214);
	SetTrieValue(g_hItemInfoTrie, "214_slot", 2);
	SetTrieValue(g_hItemInfoTrie, "214_quality", 6);
	SetTrieValue(g_hItemInfoTrie, "214_level", 5);
	SetTrieString(g_hItemInfoTrie, "214_attribs", "180 ; 75 ; 2 ; 1.25 ; 15 ; 0");
	SetTrieValue(g_hItemInfoTrie, "214_ammo", -1);
	
//The Degreaser
	SetTrieString(g_hItemInfoTrie, "215_classname", "tf_weapon_flamethrower");
	SetTrieValue(g_hItemInfoTrie, "215_index", 215);
	SetTrieValue(g_hItemInfoTrie, "215_slot", 0);
	SetTrieValue(g_hItemInfoTrie, "215_quality", 6);
	SetTrieValue(g_hItemInfoTrie, "215_level", 10);
	SetTrieString(g_hItemInfoTrie, "215_attribs", "178 ; 0.35 ; 72 ; 0.75");
	SetTrieValue(g_hItemInfoTrie, "215_ammo", 200);

//The Shortstop
	SetTrieString(g_hItemInfoTrie, "220_classname", "tf_weapon_handgun_scout_primary");
	SetTrieValue(g_hItemInfoTrie, "220_index", 220);
	SetTrieValue(g_hItemInfoTrie, "220_slot", 0);
	SetTrieValue(g_hItemInfoTrie, "220_quality", 6);
	SetTrieValue(g_hItemInfoTrie, "220_level", 1);
	SetTrieString(g_hItemInfoTrie, "220_attribs", "182 ; 0.5");
	SetTrieValue(g_hItemInfoTrie, "220_ammo", 36);

//The Holy Mackerel
	SetTrieString(g_hItemInfoTrie, "221_classname", "tf_weapon_bat_fish");
	SetTrieValue(g_hItemInfoTrie, "221_index", 221);
	SetTrieValue(g_hItemInfoTrie, "221_slot", 2);
	SetTrieValue(g_hItemInfoTrie, "221_quality", 6);
	SetTrieValue(g_hItemInfoTrie, "221_level", 42);
	SetTrieString(g_hItemInfoTrie, "221_attribs", "");
	SetTrieValue(g_hItemInfoTrie, "221_ammo", -1);

//Mad Milk
	SetTrieString(g_hItemInfoTrie, "222_classname", "tf_weapon_jar_milk");
	SetTrieValue(g_hItemInfoTrie, "222_index", 222);
	SetTrieValue(g_hItemInfoTrie, "222_slot", 1);
	SetTrieValue(g_hItemInfoTrie, "222_quality", 6);
	SetTrieValue(g_hItemInfoTrie, "222_level", 5);
	SetTrieString(g_hItemInfoTrie, "222_attribs", "");
	SetTrieValue(g_hItemInfoTrie, "222_ammo", 1);

//L'Etranger
	SetTrieString(g_hItemInfoTrie, "224_classname", "tf_weapon_revolver");
	SetTrieValue(g_hItemInfoTrie, "224_index", 224);
	SetTrieValue(g_hItemInfoTrie, "224_slot", 0);
	SetTrieValue(g_hItemInfoTrie, "224_quality", 6);
	SetTrieValue(g_hItemInfoTrie, "224_level", 5);
	SetTrieString(g_hItemInfoTrie, "224_attribs", "166 ; 15.0 ; 1 ; 0.8");
	SetTrieValue(g_hItemInfoTrie, "224_ammo", 24);

//Your Eternal Reward
	SetTrieString(g_hItemInfoTrie, "225_classname", "tf_weapon_knife");
	SetTrieValue(g_hItemInfoTrie, "225_index", 225);
	SetTrieValue(g_hItemInfoTrie, "225_slot", 2);
	SetTrieValue(g_hItemInfoTrie, "225_quality", 6);
	SetTrieValue(g_hItemInfoTrie, "225_level", 1);
	SetTrieString(g_hItemInfoTrie, "225_attribs", "154 ; 1.0 ; 156 ; 1.0 ; 155 ; 1.0");
	SetTrieValue(g_hItemInfoTrie, "225_ammo", -1);

//The Battalion's Backup
	SetTrieString(g_hItemInfoTrie, "226_classname", "tf_weapon_buff_item");
	SetTrieValue(g_hItemInfoTrie, "226_index", 226);
	SetTrieValue(g_hItemInfoTrie, "226_slot", 1);
	SetTrieValue(g_hItemInfoTrie, "226_quality", 6);
	SetTrieValue(g_hItemInfoTrie, "226_level", 10);
	SetTrieString(g_hItemInfoTrie, "226_attribs", "116 ; 2.0");
	SetTrieValue(g_hItemInfoTrie, "226_ammo", -1);

//The Black Box
	SetTrieString(g_hItemInfoTrie, "228_classname", "tf_weapon_rocketlauncher");
	SetTrieValue(g_hItemInfoTrie, "228_index", 228);
	SetTrieValue(g_hItemInfoTrie, "228_slot", 0);
	SetTrieValue(g_hItemInfoTrie, "228_quality", 6);
	SetTrieValue(g_hItemInfoTrie, "228_level", 5);
	SetTrieString(g_hItemInfoTrie, "228_attribs", "16 ; 15.0 ; 3 ; 0.75");
	SetTrieValue(g_hItemInfoTrie, "228_ammo", 20);

//The Sydney Sleeper
	SetTrieString(g_hItemInfoTrie, "230_classname", "tf_weapon_sniperrifle");
	SetTrieValue(g_hItemInfoTrie, "230_index", 230);
	SetTrieValue(g_hItemInfoTrie, "230_slot", 0);
	SetTrieValue(g_hItemInfoTrie, "230_quality", 6);
	SetTrieValue(g_hItemInfoTrie, "230_level", 1);
	SetTrieString(g_hItemInfoTrie, "230_attribs", "42 ; 1 ; 175 ; 8 ; 15 ; 0");
	SetTrieValue(g_hItemInfoTrie, "230_ammo", 25);

//darwin's danger shield (broken)
//	SetTrieString(g_hItemInfoTrie, "231_classname", "tf_wearable_item");
//	SetTrieValue(g_hItemInfoTrie, "231_index", 231);
//	SetTrieValue(g_hItemInfoTrie, "231_slot", 1);
//	SetTrieValue(g_hItemInfoTrie, "231_quality", 6);
//	SetTrieValue(g_hItemInfoTrie, "231_level", 10);
//	SetTrieString(g_hItemInfoTrie, "231_attribs", "26 ; 25");

//The Bushwacka
	SetTrieString(g_hItemInfoTrie, "232_classname", "tf_weapon_club");
	SetTrieValue(g_hItemInfoTrie, "232_index", 232);
	SetTrieValue(g_hItemInfoTrie, "232_slot", 2);
	SetTrieValue(g_hItemInfoTrie, "232_quality", 6);
	SetTrieValue(g_hItemInfoTrie, "232_level", 5);
	SetTrieString(g_hItemInfoTrie, "232_attribs", "179 ; 1 ; 61 ; 1.2");
	SetTrieValue(g_hItemInfoTrie, "232_ammo", -1);

//Rocket Jumper
	SetTrieString(g_hItemInfoTrie, "237_classname", "tf_weapon_rocketlauncher");
	SetTrieValue(g_hItemInfoTrie, "237_index", 237);
	SetTrieValue(g_hItemInfoTrie, "237_slot", 0);
	SetTrieValue(g_hItemInfoTrie, "237_quality", 6);
	SetTrieValue(g_hItemInfoTrie, "237_level", 1);
	SetTrieString(g_hItemInfoTrie, "237_attribs", "1 ; 0.0 ; 181 ; 1.0 ; 76 ; 3.0 ; 125 ; -100");
	SetTrieValue(g_hItemInfoTrie, "237_ammo", 60);

//gloves of running urgently 
	SetTrieString(g_hItemInfoTrie, "239_classname", "tf_weapon_fists");
	SetTrieValue(g_hItemInfoTrie, "239_index", 239);
	SetTrieValue(g_hItemInfoTrie, "239_slot", 2);
	SetTrieValue(g_hItemInfoTrie, "239_quality", 6);
	SetTrieValue(g_hItemInfoTrie, "239_level", 10);
	SetTrieString(g_hItemInfoTrie, "239_attribs", " 107 ; 1.3 ; 1 ; 0.5 ; 128 ; 1.0 ; 191 ; -6.0 ; 144 ; 2.0");
	SetTrieValue(g_hItemInfoTrie, "239_ammo", -1);

//Frying Pan (Now if only it had augment slots)
	SetTrieString(g_hItemInfoTrie, "264_classname", "tf_weapon_shovel");
	SetTrieValue(g_hItemInfoTrie, "264_index", 264);
	SetTrieValue(g_hItemInfoTrie, "264_slot", 2);
	SetTrieValue(g_hItemInfoTrie, "264_quality", 6);
	SetTrieValue(g_hItemInfoTrie, "264_level", 5);
	SetTrieString(g_hItemInfoTrie, "264_attribs", "195 ; 1");
	SetTrieValue(g_hItemInfoTrie, "264_ammo", -1);

//sticky jumper
	SetTrieString(g_hItemInfoTrie, "265_classname", "tf_weapon_pipebomblauncher");
	SetTrieValue(g_hItemInfoTrie, "265_index", 265);
	SetTrieValue(g_hItemInfoTrie, "265_slot", 1);
	SetTrieValue(g_hItemInfoTrie, "265_quality", 0);
	SetTrieValue(g_hItemInfoTrie, "265_level", 1);
	SetTrieString(g_hItemInfoTrie, "265_attribs", "1 ; 0.0 ; 181 ; 1.0 ; 78 ; 3.0 ; 125 ; -75");
	SetTrieValue(g_hItemInfoTrie, "265_ammo", 72);

//horseless headless horsemann's headtaker
	SetTrieString(g_hItemInfoTrie, "266_classname", "tf_weapon_sword");
	SetTrieValue(g_hItemInfoTrie, "266_index", 266);
	SetTrieValue(g_hItemInfoTrie, "266_slot", 2);
	SetTrieValue(g_hItemInfoTrie, "266_quality", 5);
	SetTrieValue(g_hItemInfoTrie, "266_level", 5);
	SetTrieString(g_hItemInfoTrie, "266_attribs", "15 ; 0 ; 125 ; -25");
	SetTrieValue(g_hItemInfoTrie, "266_ammo", -1);
	
//lugermorph from Poker Night
	SetTrieString(g_hItemInfoTrie, "294_classname", "tf_weapon_pistol");
	SetTrieValue(g_hItemInfoTrie, "294_index", 294);
	SetTrieValue(g_hItemInfoTrie, "294_slot", 1);
	SetTrieValue(g_hItemInfoTrie, "294_quality", 6);
	SetTrieValue(g_hItemInfoTrie, "294_level", 5);
	SetTrieString(g_hItemInfoTrie, "294_attribs", "");
	SetTrieValue(g_hItemInfoTrie, "294_ammo", 36);

//Enthusiast's Timepiece
	SetTrieString(g_hItemInfoTrie, "297_classname", "tf_weapon_invis");
	SetTrieValue(g_hItemInfoTrie, "297_index", 297);
	SetTrieValue(g_hItemInfoTrie, "297_slot", 4);
	SetTrieValue(g_hItemInfoTrie, "297_quality", 6);
	SetTrieValue(g_hItemInfoTrie, "297_level", 5);
	SetTrieString(g_hItemInfoTrie, "297_attribs", "");
	SetTrieValue(g_hItemInfoTrie, "297_ammo", -1);

//The Iron Curtain
	SetTrieString(g_hItemInfoTrie, "298_classname", "tf_weapon_minigun");
	SetTrieValue(g_hItemInfoTrie, "298_index", 298);
	SetTrieValue(g_hItemInfoTrie, "298_slot", 0);
	SetTrieValue(g_hItemInfoTrie, "298_quality", 6);
	SetTrieValue(g_hItemInfoTrie, "298_level", 5);
	SetTrieString(g_hItemInfoTrie, "298_attribs", "");
	SetTrieValue(g_hItemInfoTrie, "298_ammo", 200);

//Khopesh Climber- MECHA!
	SetTrieString(g_hItemInfoTrie, "9999_classname", "tf_weapon_club");
	SetTrieValue(g_hItemInfoTrie, "9999_index", 171);
	SetTrieValue(g_hItemInfoTrie, "9999_slot", 2);
	SetTrieValue(g_hItemInfoTrie, "9999_quality", 10);
	SetTrieValue(g_hItemInfoTrie, "9999_level", 13);
	SetTrieString(g_hItemInfoTrie, "9999_attribs", "1 ; 0.9 ; 5 ; 1.9");
	SetTrieValue(g_hItemInfoTrie, "9999_ammo", -1);
}

//DarthNinja. All right here.
stock SetSpeshulAmmo(client, wepslot, newAmmo)
{
	new weapon = GetPlayerWeaponSlot(client, wepslot);
	if (IsValidEntity(weapon))
	{
		new iOffset = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1)*4;
		new iAmmoTable = FindSendPropInfo("CTFPlayer", "m_iAmmo");
		SetEntData(client, iAmmoTable+iOffset, newAmmo, 4, true);
	}
}

public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
	if (!rnd_isenabled && StrEqual(weaponname, "tf_weapon_club") && GetEntProp(weapon, Prop_Send, "m_iEntityLevel") == -115 && GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == 171)
	{
		SickleClimbWalls(client);
	}
}

public SickleClimbWalls(client)
{
	if (!IsValidClient(client)) return;
//	if (GetPlayerClass(client) != 7) return;
//	if (!(g_iSpecialAttributes[client] & attribute_climbwalls)) return;

	decl String:classname[64];
	decl Float:vecClientEyePos[3];
	decl Float:vecClientEyeAng[3];
	GetClientEyePosition(client, vecClientEyePos);	 // Get the position of the player's eyes
	GetClientEyeAngles(client, vecClientEyeAng);	   // Get the angle the player is looking

	//Check for colliding entities
	TR_TraceRayFilter(vecClientEyePos, vecClientEyeAng, MASK_PLAYERSOLID, RayType_Infinite, TraceRayDontHitSelf, client);

	if (!TR_DidHit(INVALID_HANDLE)) return;
	
	new TRIndex = TR_GetEntityIndex(INVALID_HANDLE);
	GetEdictClassname(TRIndex, classname, sizeof(classname));
	if (!StrEqual(classname, "worldspawn")) return;
	
	decl Float:fNormal[3];
	TR_GetPlaneNormal(INVALID_HANDLE, fNormal);
	GetVectorAngles(fNormal, fNormal);
	
	//PrintToChatAll("Normal: %f", fNormal[0]);
	
	if (fNormal[0] >= 30.0 && fNormal[0] <= 330.0) return;
	if (fNormal[0] <= -30.0) return;

	decl Float:pos[3];
	TR_GetEndPosition(pos);
	new Float:distance = GetVectorDistance(vecClientEyePos, pos);
	
	//PrintToChatAll("Distance: %f", distance);
	if (distance >= 100.0) return;
	
	new Float:fVelocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVelocity);
	fVelocity[2] = 600.0;
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fVelocity);
	ClientCommand(client, "playgamesound \"%s\"", "player\\taunt_clip_spin.wav");
}

public bool:TraceRayDontHitSelf(entity, mask, any:data)
{
	return (entity != data);
}
stock bool:IsValidClient(client)
{
	if (client <= 0) return false;
	if (client > MaxClients) return false;
	if (!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}