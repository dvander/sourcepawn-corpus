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
#include <tf2>
#include <tf2_stocks>
#include <morecolors>
#pragma semicolon 1

#define VERSION "1.0.0"

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

public Plugin:myinfo = {
	name			= "TF2 Weapon Restrictions",
	author			= "Powerlord",
	description		= "Restrict TF2 Weapons to specific types or indexes from a config file",
	version			= VERSION,
	url				= ""
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	new EngineVersion:version = GetEngineVersion();
	
	if (version != Engine_TF2)
	{
		strcopy(error, err_max, "Only supported on TF2");
		return APLRes_Failure;
	}
	
	CreateNative("TF2WeaponRestrictions_SetRestriction", Native_SetRestriction);
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
	
	g_hChangedForward = CreateGlobalForward("TF2WeaponRestrictions_RestrictionChanged", ET_Ignore, Param_String);
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

public Action:Cmd_WeaponRestrict(client, args)
{
	if (!GetConVarBool(g_Cvar_Enabled))
	{
		CReplyToCommand(client, "%t", "TWR Disabled");
		return Plugin_Handled;
	}
	
	if (args == 0)
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
			if (IsClientInGame(i) && !IsFakeClient(i))
			{
				decl String:standard[64];
				Format(standard, sizeof(standard), "%T", "TWR Standard", i);
				PrintToChat(i, "%t", "TWR Loaded Config", standard);
			}
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
	
	g_bActionItems		= bool:KvGetNum(kvRestrictions, "allow_action_items", 1);
	g_bBuildings		= bool:KvGetNum(kvRestrictions, "allow_buildings", 1);
	
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
				else
				if (deny && FindStringInArray(g_hDenyClassList, classname) == -1)
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
				else
				if (allow && FindStringInArray(g_hAllowClassList, classname) == -1)
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
				else
				if (deny && FindValueInArray(g_hDenyIndexList, index) == -1)
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
				else
				if (allow && FindValueInArray(g_hAllowIndexList, index) == -1)
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
		if (IsClientInGame(client) && IsPlayerAlive(client))
		{
			TF2_RemoveAllWeapons(client);
			TF2_RegeneratePlayer(client);
		}
	}
}

public Action:TF2Items_OnGiveNamedItem(client, String:classname[], iItemDefinitionIndex, &Handle:hItem)
{
	/*
	// For doing replacements
	static Handle:item = INVALID_HANDLE;
	if (item != INVALID_HANDLE)
	{
		CloseHandle(item);
	}
	*/
	
	if (!GetConVarBool(g_Cvar_Enabled))
	{
		return Plugin_Continue;
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
		else
		if (FindStringInArray(g_hAllowClassList, classname) != -1)
		{
			bBlocked = false;
		}
		
		if (FindValueInArray(g_hDenyIndexList, iItemDefinitionIndex)  != -1)
		{
			bBlocked = true;
		}
		else
		if (FindValueInArray(g_hAllowIndexList, iItemDefinitionIndex)  != -1)
		{
			bBlocked = false;
		}
		
		// Replace logic should happen in here somewhere, too, but replace is not currently supported
	}
	
	if (bBlocked)
	{
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

// Natives

public Native_SetRestriction(Handle:plugin, numParams)
{
	decl String:restrictionName[PLATFORM_MAX_PATH];
	GetNativeString(1, restrictionName, sizeof(restrictionName));
	
	Change_Restrictions(0, restrictionName);
}