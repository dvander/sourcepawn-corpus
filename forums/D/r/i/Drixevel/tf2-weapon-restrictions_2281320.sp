/**
* vim: set ts=4 :
* =============================================================================
* TF2 Weapon Restrictions
* Restrict TF2 Weapons to specific types or indexes from a config file
*
* Name (C)2014 Powerlord (Ross Bemrose).  All rights reserved.
* =============================================================================
*
* This program is free software; you can redistribute it and/or modify it under
* the terms of the GNU General Public License, version 3.0, as published by the
* Free Software Foundation.
* 
* This program is distributed in the hope that it will be useful, but WITHOUT
* ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
* FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
* details.
*
* You should have received a copy of the GNU General Public License along with
* this program.  If not, see <http://www.gnu.org/licenses/>.
*
* As a special exception, AlliedModders LLC gives you permission to link the
* code of this program (as well as its derivative works) to "Half-Life 2," the
* "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
* by the Valve Corporation.  You must obey the GNU General Public License in
* all respects for all other code used.  Additionally, AlliedModders LLC grants
* this exception to all derivative works.  AlliedModders LLC defines further
* exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
* or <http://www.sourcemod.net/license.php>.
*
* Version: 1.0.0
*/
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2items>
#include <tf2_stocks>
#include <morecolors>
#include <tf2idb>
#include <tf2attributes>
#include <tf2items_giveweapon>
#pragma semicolon 1

#define VERSION "1.0.1-drix"

/*
// Sniper Shields, Soldier shoes, DemoMan shoes
#define RAZORBACK	57
#define DARWIN		231
#define COZYCAMPER	642
#define GUNBOATS	133
#define MANNTREADS	444
#define BOOTIES		405
#define BOOTLEGGER	608

// Razorback, Darwin's Danger Shield, Cozy Camper, Gunboats, Manntreads, Ali Baba's Wee Booties, Bootlegger
new g_SpecialWearableIndexes = { RAZORBACK, DARWIN, COZYCAMPER, GUNBOATS, MANNTREADS, BOOTIES, BOOTLEGGER };
*/

new Handle:g_Cvar_Enabled;

new bool:g_bWhitelist = false;
new Handle:g_hAllowClassList;
new Handle:g_hAllowIndexList;
new Handle:g_hDenyClassList;
new Handle:g_hDenyIndexList;
// new Handle:g_hReplaceStuff;

new bool:g_bActionItems = true;
new bool:g_bBuildings = true;
new bool:g_AllowedBuildings[4];

// These are only the tf_wearable item indexes
new g_ActionItemIndexes[] = { 167, 241, 280, 281, 282, 283, 284, 286, 288, 362, 364, 365, 438, 463, 477, 493, 542, 1015 };
//new g_Spellbooks[] = { 1069, 1070, 5604 };
//new g_Canteens[] = { 489, 30015 };

new Handle:hGameConf;
//new Handle:hEquipWearable;
new Handle:hRemoveWearable;

new Handle:g_hChangedForward;
new Handle:g_hExecutedForward;

public Plugin:myinfo = {
	name			= "TF2 Weapon Restrictions",
	author			= "Powerlord",
	description		= "Restrict TF2 Weapons to specific types or indexes from a config file",
	version			= VERSION,
	url				= ""
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	if (GetEngineVersion() != Engine_TF2)
	{
		Format(error, err_max, "This plug-in only works for Team Fortress 2.");
		return APLRes_Failure;
	}
	
	CreateNative("WeaponRestrictions_SetConfig", Native_SetRestriction);
	CreateNative("WeaponRestrictions_CurrentConfig", Native_RetrieveRestriction);
	
	g_hChangedForward = CreateGlobalForward("WeaponRestrictions_OnChanged", ET_Ignore, Param_String);
	g_hExecutedForward = CreateGlobalForward("WeaponRestrictions_OnExecuted", ET_Ignore, Param_Cell);
	
	RegPluginLibrary("tf2weaponrestrictions");
	
	return APLRes_Success;
}

public OnPluginStart()
{
	LoadTranslations("tf2-weapon-restrictions.phrases");
	
	CreateConVar("tf2_weapon_restrictions_version", VERSION, "TF2 Weapon Restrictions version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_SPONLY);
	g_Cvar_Enabled = CreateConVar("tf2_weapon_restrictions_enable", "1", "Enable TF2 Weapon Restrictions?", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD, true, 0.0, true, 1.0);

	RegAdminCmd("weaponrestrict", Cmd_WeaponRestrict, ADMFLAG_KICK, "Change Weapon Restrictions");
	
	g_hAllowClassList = CreateArray(ByteCountToCells(64));
	g_hAllowIndexList = CreateArray();
	g_hDenyClassList = CreateArray(ByteCountToCells(64));
	g_hDenyIndexList = CreateArray();
	
	HookEvent("post_inventory_application", Event_Inventory);
	
	hGameConf = LoadGameConfigFile("equipwearable");
	
	/*
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "EquipWearable");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	hEquipWearable = EndPrepSDKCall();
	*/

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "RemoveWearable");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	hRemoveWearable = EndPrepSDKCall();
	
	HookConVarChange(g_Cvar_Enabled, CVar_Enabled);
}

public CVar_Enabled(Handle:convar, const String:oldValue[], const String:newValue[])
{
	RegeneratePlayers();
}

public Event_Inventory(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(g_Cvar_Enabled))
	{
		return;
	}
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client == 0)
	{
		return;
	}
	
	if (!g_bActionItems)
	{
		new entity = -1;
		
		while((entity = FindEntityByClassname(entity, "tf_wearable")) != -1)
		{
			new owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
			
			if (owner != client)
			{
				continue;
			}
			
			new itemIndex = GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex");
			
			for (new i = 0; i < sizeof(g_ActionItemIndexes); i++)
			{
				if (g_ActionItemIndexes[i] == itemIndex)
				{
					SDKCall(hRemoveWearable, client, entity);
					break;
				}
			}
		}
		
		entity = -1;
		
		while((entity = FindEntityByClassname(entity, "tf_powerup_bottle")) != -1)
		{
			new owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
			
			if (owner != client)
			{
				continue;
			}
			
			SDKCall(hRemoveWearable, client, entity);
		}
		
		entity = -1;
		
		while((entity = FindEntityByClassname(entity, "tf_weapon_spellbook")) != -1)
		{
			new owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
			
			if (owner != client)
			{
				continue;
			}
			
			/*
			// Since this is a CBaseCombatWeapon, remove its wearable if present, then the item
			new wearable = GetEntPropEnt(entity, Prop_Send, "m_hExtraWearable");
			if (wearable != -1)
			{
				SDKCall(hRemoveWearable, client, wearable);
			}
			*/
			
			RemovePlayerItem(client, entity);
		}		
	}
}

public OnEntityCreated(entity, const String:classname[])
{
	if (!GetConVarBool(g_Cvar_Enabled))
	{
		return;
	}
	
	if (StrEqual(classname, "tf_weapon_builder"))
	{
		SDKHook(entity, SDKHook_Spawn, BuilderSpawn);
	}
	else if (!g_AllowedBuildings[TFObject_Sentry] && StrEqual(classname, "obj_sentrygun"))
	{
		SDKHook(entity, SDKHook_Spawn, BlockBuilding);
	}
	else if (!g_AllowedBuildings[TFObject_Dispenser] && StrEqual(classname, "obj_dispenser"))
	{
		SDKHook(entity, SDKHook_Spawn, BlockBuilding);
	}
	else if (!g_AllowedBuildings[TFObject_Teleporter] && StrEqual(classname, "obj_teleporter"))
	{
		SDKHook(entity, SDKHook_Spawn, BlockBuilding);
	}
}

public Action:BlockBuilding(entity)
{
	if(IsValidEntity(entity))
	{
		AcceptEntityInput(entity, "Kill");
	}
	return Plugin_Continue;	
}

// This doesn't actually work on non-bots, but in case Valve fixes it later...
public Action:BuilderSpawn(entity)
{
	new owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	
	if (!IsValidEntity(owner))
	{
		return Plugin_Continue;
	}
	
	new TFClassType:class = TF2_GetPlayerClass(owner);
	
	switch(class)
	{
	case TFClass_Engineer:
		{
			if (!g_AllowedBuildings[TFObject_Sentry])
			{
				SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", 0, _, _:TFObject_Sentry);
			}

			if (!g_AllowedBuildings[TFObject_Dispenser])
			{
				SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", 0, _, _:TFObject_Dispenser);
			}
			
			if (!g_AllowedBuildings[TFObject_Teleporter])
			{
				SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", 0, _, _:TFObject_Teleporter);
			}
		}
		
		// Just block the sappers by index instead
	case TFClass_Spy:
		{
			if (!g_AllowedBuildings[TFObject_Sapper])
			{
				SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", 0, _, _:TFObject_Sapper);
			}
		}
	}
	// Have to return continue even though we changed props.
	return Plugin_Continue;
}

public Action:Cmd_WeaponRestrict(client, args)
{
	if (!GetConVarBool(g_Cvar_Enabled))
	{
		CReplyToCommand(client, "%t", "TWR Disabled");
		return Plugin_Handled;
	}
	
	if (args < 1)
	{
		CReplyToCommand(client, "%t", "TWR Command Usage");
		return Plugin_Handled;
	}
	
	decl String:name[PLATFORM_MAX_PATH];
	GetCmdArg(1, name, sizeof(name));

	Change_Restrictions(client, name);
	
	return Plugin_Handled;
}

Change_Restrictions(client, String:file[])
{
	if (file[0] == '\0' || StrEqual(file, "none", false))
	{
		g_bWhitelist = false;
		g_bActionItems = true;
		g_bBuildings = true;
		
		for (new i = 0; i < sizeof(g_AllowedBuildings); i++)
		{
			g_AllowedBuildings[i] = true;
		}
		
		ClearArray(g_hAllowClassList);
		ClearArray(g_hAllowIndexList);
		ClearArray(g_hDenyClassList);
		ClearArray(g_hDenyIndexList);
		
		for (new i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i) && IsFakeClient(i)) continue;
			
			decl String:standard[64];
			Format(standard, sizeof(standard), "%T", "TWR Standard", i);
			PrintToChat(i, "%t", "TWR Loaded Config", standard);
		}
		
		RegeneratePlayers();
		return;
	}
	
	decl String:path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "configs/tf2-weapon-restrictions/%s.cfg", file);
	
	if (!FileExists(path, true))
	{
		CReplyToCommand(client, "%t", "TWR Config Not Found", file);
		return;
	}

	// Process file
	new Handle:kvRestrictions = CreateKeyValues("weapon_restrictions");
	FileToKeyValues(kvRestrictions, path);
	
	decl String:name[128];
	KvGetString(kvRestrictions, "name", name, sizeof(name));
	
	decl String:listDefault[15];
	KvGetString(kvRestrictions, "default", listDefault, sizeof(listDefault), "allow");
	
	if (StrEqual(listDefault, "deny", false))
	{
		g_bWhitelist	= true;
	}
	
	g_bActionItems = bool:KvGetNum(kvRestrictions, "allow_action_items", 1);
	g_bBuildings = bool:KvGetNum(kvRestrictions, "allow_buildings", 1);
	
	if (g_bBuildings && KvJumpToKey(kvRestrictions, "buildings"))
	{
		g_AllowedBuildings[TFObject_Sentry] = KvGetNum(kvRestrictions, "sentry", 1);
		g_AllowedBuildings[TFObject_Dispenser] = KvGetNum(kvRestrictions, "dispenser", 1);
		g_AllowedBuildings[TFObject_Teleporter] = KvGetNum(kvRestrictions, "teleporter", 1);
		g_AllowedBuildings[TFObject_Sapper] = KvGetNum(kvRestrictions, "sapper", 1);
		
		KvGoBack(kvRestrictions);
	}
	
	if (KvJumpToKey(kvRestrictions, "classes") && KvGotoFirstSubKey(kvRestrictions))
	{
		do
		{
			decl String:classname[64];
			KvGetSectionName(kvRestrictions, classname, sizeof(classname));
			
			new allow = KvGetNum(kvRestrictions, "allow");
			new deny = KvGetNum(kvRestrictions, "deny");
			
			if (g_bWhitelist)
			{
				if (allow && FindStringInArray(g_hAllowClassList, classname) == -1)
				{
					PushArrayString(g_hAllowClassList, classname);
				}
				else if (deny && FindStringInArray(g_hDenyClassList, classname) == -1)
				{
					PushArrayString(g_hDenyClassList, classname);
				}
			}
			else
			{
				if (deny && FindStringInArray(g_hDenyClassList, classname) == -1)
				{
					PushArrayString(g_hDenyClassList, classname);
				}
				else if (allow && FindStringInArray(g_hAllowClassList, classname) == -1)
				{
					PushArrayString(g_hAllowClassList, classname);
				}
			}
		} while (KvGotoNextKey(kvRestrictions));
	}
	
	if (KvJumpToKey(kvRestrictions, "indexes") && KvGotoFirstSubKey(kvRestrictions))
	{
		do
		{
			decl String:sIndex[10];
			KvGetSectionName(kvRestrictions, sIndex, sizeof(sIndex));
			new index = StringToInt(sIndex);
			
			new allow = KvGetNum(kvRestrictions, "allow");
			new deny = KvGetNum(kvRestrictions, "deny");
			
			if (g_bWhitelist)
			{
				if (allow && FindValueInArray(g_hAllowIndexList, index) == -1)
				{
					PushArrayCell(g_hAllowIndexList, index);
				}
				else if (deny && FindValueInArray(g_hDenyIndexList, index) == -1)
				{
					PushArrayCell(g_hDenyIndexList, index);
				}
			}
			else
			{
				if (deny && FindValueInArray(g_hDenyIndexList, index) == -1)
				{
					PushArrayCell(g_hDenyIndexList, index);
				}
				else if (allow && FindValueInArray(g_hAllowIndexList, index) == -1)
				{
					PushArrayCell(g_hAllowIndexList, index);
				}
			}
		} while (KvGotoNextKey(kvRestrictions));
	}
	
	Call_StartForward(g_hChangedForward);
	Call_PushStringEx(file, PLATFORM_MAX_PATH, SM_PARAM_STRING_UTF8, 0);
	Call_Finish();
	
	RegeneratePlayers();
	PrintToChatAll("%t", "TWR Loaded Config", name);
}

RegeneratePlayers()
{
	for (new client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client) || !IsPlayerAlive(client)) continue;
		
		TF2_RemoveAllWeapons(client);
		TF2_RegeneratePlayer(client);
	}
}

public TF2Items_OnGiveNamedItem_Post(client, String:classname[], itemDefinitionIndex, itemLevel, itemQuality, entityIndex)
{
	if (!GetConVarBool(g_Cvar_Enabled))
	{
		return;
	}
	
	new bool:bBlocked = g_bWhitelist;
	
	if (!g_bBuildings && (StrEqual(classname, "tf_weapon_builder") || StrEqual(classname, "tf_weapon_sapper")))
	{
		bBlocked = true;
	}
	else
	{
		// Check classlists first, so that index lists can override
		// Earlier on, we only added it to one of the allow/deny lists
		// even if it was listed in both.
		if (FindStringInArray(g_hDenyClassList, classname) != -1)
		{
			bBlocked = true;
		}
		else if (FindStringInArray(g_hAllowClassList, classname) != -1)
		{
			bBlocked = false;
		}
		
		if (FindValueInArray(g_hDenyIndexList, itemDefinitionIndex)  != -1)
		{
			bBlocked = true;
		}
		else if (FindValueInArray(g_hAllowIndexList, itemDefinitionIndex)  != -1)
		{
			bBlocked = false;
		}
	}
	
	if (bBlocked)
	{
		new Handle:Pack;
		CreateDataTimer(0.1, Timer_ReplaceWeapon, Pack);
		WritePackCell(Pack, GetClientUserId(client));
		WritePackCell(Pack, itemDefinitionIndex);
		WritePackCell(Pack, entityIndex);
	}
}

public Action:Timer_ReplaceWeapon(Handle:timer, Handle:data)
{
	ResetPack(data);

	new client = GetClientOfUserId(ReadPackCell(data));
	new index = ReadPackCell(data);
	new entindex = ReadPackCell(data);
	
	if (IsClientInGame(client) && IsPlayerAlive(client) && IsValidEntity(entindex))
	{
		new Address:attr = Address:TF2Attrib_GetByName(entindex, "max health additive bonus");
		if (attr != Address_Null)
		{
			TF2Attrib_RemoveByName(client, "max health additive bonus");
		}
				
		new iSlot = _:TF2IDB_GetItemSlot(index);
		TF2_RemoveWeaponSlot(client, iSlot);
		TF2Items_GiveWeapon(client, GetDefaultIDIForClass(TF2_GetPlayerClass(client), iSlot));
		
		Call_StartForward(g_hExecutedForward);
		Call_PushCell(client);
		Call_Finish();
	}
}

public GetDefaultIDIForClass(TFClassType:xClass, iSlot)
{
	switch(xClass)
	{
	case TFClass_Scout:
		{
			switch(iSlot)
			{
			case 0: { return 13; }
			case 1: { return 23; }
			case 2: { return 0; }
			}
		}
	case TFClass_Sniper:
		{
			switch(iSlot)
			{
			case 0: { return 14; }
			case 1: { return 16; }
			case 2: { return 3; }
			}
		}
	case TFClass_Soldier:
		{
			switch(iSlot)
			{
			case 0: { return 18; }
			case 1: { return 10; }
			case 2: { return 6; }
			}
		}
	case TFClass_DemoMan:
		{
			switch(iSlot)
			{
			case 0: { return 19; }
			case 1: { return 20; }
			case 2: { return 1; }
			}
		}
	case TFClass_Medic:
		{
			switch(iSlot)
			{
			case 0: { return 17; }
			case 1: { return 29; }
			case 2: { return 8; }
			}
		}
	case TFClass_Heavy:
		{
			switch(iSlot)
			{
			case 0: { return 15; }
			case 1: { return 11; }
			case 2: { return 5; }
			}
		}
	case TFClass_Pyro:
		{
			switch(iSlot)
			{
			case 0: { return 21; }
			case 1: { return 12; }
			case 2: { return 2; }
			}
		}
	case TFClass_Spy:
		{
			switch(iSlot)
			{
			case 0: { return 24; }
			case 1: { return 735; }
			case 2: { return 4; }
			case 4: { return 30; }				
			}
		}
	case TFClass_Engineer:
		{
			switch(iSlot)
			{
			case 0: { return 9; }
			case 1: { return 22; }
			case 2: { return 7; }
			case 3: { return 25; }
			}
		}
	}

	return -1;
}

// Natives
public Native_SetRestriction(Handle:plugin, numParams)
{
	decl String:restrictionName[PLATFORM_MAX_PATH];
	GetNativeString(1, restrictionName, sizeof(restrictionName));
	
	Change_Restrictions(0, restrictionName);
}

public Native_RetrieveRestriction(Handle:plugin, numParams)
{
	
}