#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#undef REQUIRE_EXTENSIONS
#tryinclude <tf2items>

#define PLUGIN_NAME		"Ready Steady Pan Setup"
#define PLUGIN_AUTHOR		"FlaminSarge"
#define PLUGIN_VERSION		"1.3"
#define PLUGIN_CONTACT		"http://pan.int.tf"

public Plugin:myinfo =
{
	name			= PLUGIN_NAME,
	author			= PLUGIN_AUTHOR,
	description	= PLUGIN_NAME,
	version		= PLUGIN_VERSION,
	url				= PLUGIN_CONTACT
};
new iWhitelist[] = {
	264,	//pan
	0,		//stock bat
	1,		//stock bottle
	2,		//stock fire axe
	3,		//stock kukri
	4,		//stock knife
	5,		//stock fists
	6,		//stock shovel
	7,		//stock wrench
	8,		//stock bonesaw
	46,		//Bonk Atomic Punch
	163,	//Crit-a-Cola
	222,	//Mad Milk
	237,	//Rocket Jumper
	265,	//Sticky Jumper
	58,		//Jarate
//	159,	//Dalokohs Bar
//	311,	//Buffalo Steak Sandvich
//	433,	//Fishcake
//	474,	//Conscientious Objector? Is this supposed to be here? It's in the whitelist...
};
new bool:tf2items = false;
new panmodel = 0;
new Handle:g_hCvarEnabled;
new bool:givepan[MAXPLAYERS + 1];
new String:cfg[32] = "rsp_standard";
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
#if defined _tf2items_included
	MarkNativeAsOptional("TF2Items_SetItemIndex");
	MarkNativeAsOptional("TF2Items_SetNumAttributes");
	MarkNativeAsOptional("TF2Items_CreateItem");
	MarkNativeAsOptional("TF2Items_SetClassname");
	MarkNativeAsOptional("TF2Items_SetLevel");
	MarkNativeAsOptional("TF2Items_SetQuality");
	MarkNativeAsOptional("TF2Items_GiveNamedItem");
#endif
	return APLRes_Success;
}
public OnPluginStart()
{
	CreateConVar("rsp_setup_version", PLUGIN_VERSION, "Ready Steady Pan Items Setup plugin", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED);
	g_hCvarEnabled = CreateConVar("rsp_setup_enabled", "1", "Ready Steady Pan Setup enabled", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED);
	RegAdminCmd("sm_pan", NoPan, 0, "If you don't have a pan, type !pan");
	HookEvent("post_inventory_application", Event_PostInventoryApplication);
	HookConVarChange(g_hCvarEnabled, EnabledChange);
	tf2items = false;
}
public EnabledChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (GetConVarBool(g_hCvarEnabled)) 	ServerCommand("exec %s", cfg);
	else if (StringToInt(oldValue) && !StringToInt(newValue)) ServerCommand("exec rsp_off");
}
public OnConfigsExecuted()
{
	if (GetConVarBool(g_hCvarEnabled)) 	ServerCommand("exec %s", cfg);
}
public OnMapStart()
{
	panmodel = PrecacheModel("models/weapons/c_models/c_frying_pan/c_frying_pan.mdl", true);
	decl String:map[64];
	GetCurrentMap(map, sizeof(map));
	if (strncmp(map, "koth_", 5, false) == 0) strcopy(cfg, sizeof(cfg), "rsp_koth");
	else if (StrEqual(map, "cp_gravelpit", false) || strncmp(map, "cp_junction", 11, false) == 0) strcopy(cfg, sizeof(cfg), "rsp_stopwatch");
	else if (strncmp(map, "cp_", 3, false) == 0) strcopy(cfg, sizeof(cfg), "rsp_standard");
}
public Action:NoPan(client, args)
{
	if (!IsValidClient(client)) return Plugin_Handled;
	givepan[client] = !givepan[client];
	if (givepan[client])
		ReplyToCommand(client, "[RSP] If you have a pan, equip it, else you will receive a pan if your melee weapon fails the whitelist. Touch a locker to refresh your weapons.");
	else
		ReplyToCommand(client, "[RSP] You will no longer automatically receive a pan.");
	return Plugin_Handled;
}
#if defined _tf2items_included
public Action:TF2Items_OnGiveNamedItem(client, String:classname[], iItemDefinitionIndex, &Handle:hItem)
{
	tf2items = true;
	static Handle:hWeapon;
	if (hWeapon == INVALID_HANDLE)
	{
		hWeapon = TF2Items_CreateItem(OVERRIDE_ITEM_DEF|OVERRIDE_ATTRIBUTES);
		TF2Items_SetItemIndex(hWeapon, 264);
		TF2Items_SetNumAttributes(hWeapon, 0);
	}
	if (!GetConVarBool(g_hCvarEnabled)) return Plugin_Continue;
	if (strncmp(classname, "tf_wearable", 11, false) == 0)
	{
		switch (iItemDefinitionIndex)
		{
			case 57, 444, 642, 231, 131, 406, 583: return Plugin_Handled;	//Disallow Mantreads, Danger Shield, Targe, Screen, Bombonomicon, Razorback
		}
		return Plugin_Continue;
	}
	for (new i = 0; i < sizeof(iWhitelist); i++)
	{
		if (iItemDefinitionIndex == iWhitelist[i]) return Plugin_Continue;
	}
	if (IsMeleeWeapon(classname))
	{
		if (givepan[client])
		{
			decl String:wep[64];
			FindClassPanWeapon(TF2_GetPlayerClass(client), wep, sizeof(wep));
			if (StrEqual(wep, classname, false))
			{
				hItem = hWeapon;
				return Plugin_Changed;
			}
			else CreateTimer(0.0, Timer_GiveStock, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		{
			PrintToChat(client, "[RSP] Please equip the pan or type !pan to receive a pan.");
			return Plugin_Continue;
		}
	}
	return Plugin_Handled;
}
#endif
stock bool:IsValidClient(client)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	return !(IsClientSourceTV(client) || IsClientReplay(client));
}
public Action:Timer_GiveStock(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (!IsValidClient(client)) return;
	GiveStockMeleeWeapon(client);
}
stock GiveStockMeleeWeapon(client)
{
	if (!tf2items)
	{
		GiveStockWeaponNoTF2I(client);
		return;
	}
#if defined _tf2items_included
	new Handle:hWeapon = TF2Items_CreateItem(OVERRIDE_ALL);
	TF2Items_SetClassname(hWeapon, "saxxy");
	TF2Items_SetItemIndex(hWeapon, 264);
	TF2Items_SetLevel(hWeapon, 5);
	TF2Items_SetQuality(hWeapon, 6);
	TF2Items_SetNumAttributes(hWeapon, 0);
	new weapon = TF2Items_GiveNamedItem(client, hWeapon);
	CloseHandle(hWeapon);
	EquipPlayerWeapon(client, weapon);
#endif
}
stock GiveStockWeaponNoTF2I(client)
{
	new String:wep[64];
	FindClassPanWeapon(TF2_GetPlayerClass(client), wep, sizeof(wep));
	new weapon = GivePlayerItem(client, wep);
	SetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex", 264);
	SetEntProp(weapon, Prop_Send, "m_iEntityLevel", 5);
	SetEntProp(weapon, Prop_Send, "m_iEntityQuality", 6);
	SetEntProp(weapon, Prop_Send, "m_iWorldModelIndex", panmodel);
	SetEntProp(weapon, Prop_Send, "m_nModelIndexOverrides", panmodel, _, 0);
	SetEntProp(weapon, Prop_Send, "m_bInitialized", 1);
	SetEntProp(weapon, Prop_Send, "m_hExtraWearable", -1);
	EquipPlayerWeapon(client, weapon);
	CreateTimer(0.0, SwitchWeps, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}
stock FindClassPanWeapon(TFClassType:class, String:wep[], len)
{
	switch (class)
	{
		case TFClass_Scout: strcopy(wep, len, "tf_weapon_bat");
		case TFClass_DemoMan: strcopy(wep, len, "tf_weapon_bottle");
		case TFClass_Engineer: strcopy(wep, len, "tf_weapon_wrench");
		case TFClass_Spy: strcopy(wep, len, "tf_weapon_knife");
		case TFClass_Medic: strcopy(wep, len, "tf_weapon_bonesaw");
		case TFClass_Pyro, TFClass_Heavy: strcopy(wep, len, "tf_weapon_fireaxe");
		case TFClass_Soldier: strcopy(wep, len, "tf_weapon_shovel");
		case TFClass_Sniper: strcopy(wep, len, "tf_weapon_club");
	}
}
stock IsMeleeWeapon(const String:weaponname[])
{
	if (StrEqual(weaponname, "tf_weapon_knife")
		|| StrEqual(weaponname, "tf_weapon_wrench")
		|| StrEqual(weaponname, "tf_weapon_shovel")
		|| StrEqual(weaponname, "tf_weapon_bottle")
		|| StrEqual(weaponname, "tf_weapon_fists")
		|| StrEqual(weaponname, "tf_weapon_bat")
		|| StrEqual(weaponname, "tf_weapon_bonesaw")
		|| StrEqual(weaponname, "tf_weapon_sword")
		|| StrEqual(weaponname, "tf_weapon_fireaxe")
		|| StrEqual(weaponname, "tf_weapon_robot_arm")
		|| StrEqual(weaponname, "tf_weapon_bat_wood")
		|| StrEqual(weaponname, "tf_weapon_club")
		|| StrEqual(weaponname, "tf_weapon_bat_fish")
		|| StrEqual(weaponname, "tf_weapon_stickbomb")
		|| StrEqual(weaponname, "tf_weapon_katana"))
		return true;
	else return false;
}
stock TF2_GetMaxHealth(client)
{
	new maxhealth = TF2_GetPlayerResourceData(client, TFResource_MaxHealth);
	return ((maxhealth == -1 || maxhealth == 80896) ? GetEntProp(client, Prop_Data, "m_iMaxHealth") : maxhealth);
}
public Action:Event_PostInventoryApplication(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(g_hCvarEnabled)) return;
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	RemovePlayerBack(client, { 231, 642, 583, 444 }, 4);
	RemovePlayerTarge(client);
	if (tf2items)
	{
		new wep = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
		if (!IsValidEntity(wep)) CreateTimer(0.0, Timer_GiveStock, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		else
		{
			new idx = GetEntProp(wep, Prop_Send, "m_iItemDefinitionIndex");
			for (new i = 0; i < sizeof(iWhitelist); i++)
			{
				if (idx == iWhitelist[i])
				{
					return;
				}
			}
			if (givepan[client])
			{
				TF2_RemoveWeaponSlot(client, TFWeaponSlot_Melee);
				CreateTimer(0.0, Timer_GiveStock, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
			}
		}
		return;
	}
	new ent = -1;
	RemovePlayerBack(client, { 231, 642, 583, 444 }, 4);
	RemovePlayerTarge(client);
	for (new z = 0; z <= 5; z++)
	{
		ent = GetPlayerWeaponSlot(client, z);
		if (IsValidEntity(ent))
		{
			new idx = GetEntProp(ent, Prop_Send, "m_iItemDefinitionIndex");
			new bool:found = false;
			for (new i = 0; i < sizeof(iWhitelist); i++)
			{
				if (idx == iWhitelist[i])
				{
					found = true;
				}
			}
			if (!found)
			{
				if (z == TFWeaponSlot_Melee)
				{
					if (givepan[client])
					{
//						new extra = GetEntPropEnt(ent, Prop_Send, "m_hExtraWearable");
//						if (IsValidEntity(extra)) AcceptEntityInput(extra, "Kill");
						RemovePlayerItem(client, ent);
						AcceptEntityInput(ent, "Kill");
						CreateTimer(0.0, Timer_GiveStock, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
					}
					else
					{
						PrintToChat(client, "[RSP] Please equip the pan or type !pan to receive a pan.");
					}
				}
				else
				{
//					new extra = GetEntPropEnt(ent, Prop_Send, "m_hExtraWearable");
//					if (IsValidEntity(extra)) AcceptEntityInput(extra, "Kill");
					RemovePlayerItem(client, ent);
					AcceptEntityInput(ent, "Kill");
				}
			}
		}
		else if (z == TFWeaponSlot_Melee) CreateTimer(0.0, Timer_GiveStock, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
	CreateTimer(0.0, SwitchWeps, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}
public Action:SwitchWeps(Handle:timer, any:userid)
{
	decl String:wep[64];
	new client = GetClientOfUserId(userid);
	if (!IsValidClient(client)) return;
	if (!IsPlayerAlive(client)) return;
	if (!IsValidEntity(GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon")))
	{
		FindClassPanWeapon(TF2_GetPlayerClass(client), wep, sizeof(wep));
		FakeClientCommandEx(client, "use %s", wep);
	}
}
stock RemovePlayerTarge(client)
{
	new edict = MaxClients+1;
	while((edict = FindEntityByClassname2(edict, "tf_wearable_demoshield")) != -1)
	{
		if (GetEntPropEnt(edict, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(edict, Prop_Send, "m_bDisguiseWearable"))
		{
			AcceptEntityInput(edict, "Kill");
		}
	}
}
stock RemovePlayerBack(client, indices[], len)
{
	if (len <= 0) return;
	new edict = MaxClients+1;
	while ((edict = FindEntityByClassname2(edict, "tf_wearable")) != -1)
	{
		decl String:netclass[32];
		if (GetEntityNetClass(edict, netclass, sizeof(netclass)) && StrEqual(netclass, "CTFWearable"))
		{
			new idx = GetEntProp(edict, Prop_Send, "m_iItemDefinitionIndex");
			if (GetEntPropEnt(edict, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(edict, Prop_Send, "m_bDisguiseWearable"))
			{
				for (new i = 0; i < len; i++)
				{
					if (idx == indices[i]) AcceptEntityInput(edict, "Kill");
				}
			}
		}
	}
}
stock FindEntityByClassname2(startEnt, const String:classname[])
{
	/* If startEnt isn't valid shifting it back to the nearest valid one */
	while (startEnt > -1 && !IsValidEntity(startEnt)) startEnt--;
	return FindEntityByClassname(startEnt, classname);
}