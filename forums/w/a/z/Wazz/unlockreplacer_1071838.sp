#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#include <sdkhooks>

#undef REQUIRE_PLUGIN
#include <adminmenu>

#define PLUGIN_VERSION 		"2.6.0.1"

public Plugin:myinfo = {
	name = "Unlock Replacer",
	author = "Wazz",
	description = "Replaces unlockable weapons with their originals",
	version = PLUGIN_VERSION,
};

new Handle:hTopMenu = INVALID_HANDLE;
new Handle:GameConf = INVALID_HANDLE;
new Handle:hGiveNamedItem = INVALID_HANDLE;
new Handle:hWeaponEquip = INVALID_HANDLE;

// adt arrays for exception rules, argh horrible...
new Handle:excAmbassador;
new Handle:excAxetinguisher;
new Handle:excBackburner;
new Handle:excBonk;
new Handle:excBlutsauger;
new Handle:excCloakAndDagger;
new Handle:excDeadRinger;
new Handle:excFlaregun;
new Handle:excFAN;
new Handle:excHuntsman;
new Handle:excJarate;
new Handle:excKGB;
new Handle:excKritzkrieg;
new Handle:excNatasha;
new Handle:excSandman;
new Handle:excSandvich;
new Handle:excUbersaw;
new Handle:excRazerback;
new Handle:excEyelander;
new Handle:excTarge;
new Handle:excScottishResistance;
new Handle:excEqualizer;
new Handle:excBuffBanner;
new Handle:excTheDirectHit;
new Handle:excGunboats;
// add more handles here, one per weapon
// You must add this Handle to the getArray funcion
// You must create a table with this handle in OnPluginStart

// THE FOLLOWING 4 TABLES MUST BE KEPT IN PARALLEL
new String:weaponAlias[][] = {
	"Ambassador",
	"Axetinguisher",
	"Backburner",
	"Bonk",
	"Blutsauger",
	"Cloak and Dagger",
	"Dead Ringer",
	"Flaregun",
	"Force-A-Nature",
	"Huntsman",
	"Jarate",
	"Killing Gloves of Boxing",
	"Kritzkrieg",
	"Natascha",
	"Sandman",
	"Sandvich",
	"Ubersaw",
	"Razorback",
	"Eyelander",
	"Chargin' Targe",
	"Scottish Resistance",
	"Equalizer",
	"Buff Banner",
	"Direct Hit",
	"Gunboats"		// add more aliases here, aliases are the names used on the admin menu. MUST BE PARALLEL TO UNLOCKDEFIDX AND REPLACEMENT ARRAY
};

new bool:isBlocked[sizeof(weaponAlias)];

new unlockDefIdx[] = {
	61,
	38,		
	40,
	46,
	36,
	60,
	59,
	39,
	45,
	56,
	58,
	43,
	35,
	41,
	44,
	42,
	37,
	57,	
	132,
	131,
	130,
	128,
	129,
	127,
	133		// add more unlockable weapon indexes here, weapon indexes are used to indentify each weapon.
};

new String:replacementWeapon[][] = {
	"tf_weapon_revolver",
	"tf_weapon_fireaxe",
	"tf_weapon_flamethrower",
	"tf_weapon_pistol_scout",
	"tf_weapon_syringegun_medic",
	"tf_weapon_invis",
	"tf_weapon_invis",
	"tf_weapon_shotgun_pyro",
	"tf_weapon_scattergun",
	"tf_weapon_sniperrifle",
	"tf_weapon_smg",
	"tf_weapon_fists",
	"tf_weapon_medigun",
	"tf_weapon_minigun",
	"tf_weapon_bat",
	"tf_weapon_shotgun_hwg",
	"tf_weapon_bonesaw",
	"tf_weapon_smg",
	"tf_weapon_bottle", 
	"tf_weapon_pipebomblauncher",
	"tf_weapon_pipebomblauncher",
	"tf_weapon_shovel",
	"tf_weapon_shotgun_soldier",
	"tf_weapon_rocketlauncher",
	"tf_weapon_shotgun_soldier"		// add more replacement weapons here, this is what the server gives the client instead of their unlock.
};

new bool:CanClientReceiveMsg[MAXPLAYERS+1];

public OnPluginStart()
{
	GameConf = LoadGameConfigFile("unlock.games");

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(GameConf, SDKConf_Virtual, "GiveNamedItem");
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Plain);
	hGiveNamedItem = EndPrepSDKCall();

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(GameConf, SDKConf_Virtual, "WeaponEquip");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	hWeaponEquip = EndPrepSDKCall();
	
	RegAdminCmd("sm_unlock_block", Command_urBlock, ADMFLAG_GENERIC, "Blocks an unlock. Format as sm_unlock_block <weapon>");
	RegAdminCmd("sm_unlock_unblock", Command_urUnblock, ADMFLAG_GENERIC, "Unblocks an unlock. Format as sm_unlock_unblock <weapon>");
	RegAdminCmd("sm_unlock_exception_add", Command_urExceptionAdd, ADMFLAG_GENERIC, "Creates a new exception rule. Format as sm_unlock_exception_add <weapon name> <target>");
	RegAdminCmd("sm_unlock_exception_remove", Command_urExceptionRemove, ADMFLAG_GENERIC, "Removes an existing exception rule. Format as sm_unlock_exception_remove <weapon name> <target>");
	RegAdminCmd("sm_unlock_exception_list", Command_urExceptionList, ADMFLAG_GENERIC, "Lists the current exceptions for an unlock. Format as sm_unlock_exception_list <weapon name>");
	RegAdminCmd("sm_unlock_list", Command_urBlockList, ADMFLAG_GENERIC, "Prints a list of unlocks that are currently blocked in console");
	RegAdminCmd("sm_unlock_alias", Command_urAliasList, ADMFLAG_GENERIC, "Prints a full list of names that can be used for identifing unlocks in console");
	
	CreateConVar("sm_unlock_version", PLUGIN_VERSION, "Unlock Replacer version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	excAmbassador = CreateArray(64);
	excAxetinguisher = CreateArray(64);
	excBackburner = CreateArray(64);
	excBonk = CreateArray(64);
	excBlutsauger = CreateArray(64);
	excCloakAndDagger = CreateArray(64);
	excDeadRinger = CreateArray(64);
	excFlaregun = CreateArray(64);
	excFAN = CreateArray(64);
	excHuntsman = CreateArray(64);
	excJarate = CreateArray(64);
	excKGB = CreateArray(64);
	excKritzkrieg = CreateArray(64);
	excNatasha = CreateArray(64);
	excSandman = CreateArray(64);
	excSandvich = CreateArray(64);
	excUbersaw = CreateArray(64);
	excRazerback = CreateArray(64);
	excEyelander = CreateArray(64);
	excTarge = CreateArray(64);
	excScottishResistance = CreateArray(64);
	excEqualizer = CreateArray(64);
	excBuffBanner = CreateArray(64);
	excTheDirectHit = CreateArray(64);
	excGunboats = CreateArray(64);
	
	for(new Client=1; Client<=MaxClients; Client++)
		CanClientReceiveMsg[Client] = true;
		
	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);
	}
}

public OnMapStart()
{
	for (new Client=1; Client<=MaxClients; Client++)
	{
		CanClientReceiveMsg[Client] = true;
	}
}

public Action:Command_urBlock(Client, args)
{
	if (args != 1)
	{
		ReplyToCommand(Client, "[SM] Usage: sm_unlock_block <weapon>");
		return Plugin_Handled;	
	}
	
	new String:alias[64];
	
	GetCmdArg(1, alias, 64);
	doBlock(Client, alias);

	return Plugin_Handled;
}

public Action:Command_urUnblock(Client, args)
{
	if (args != 1)
	{
		ReplyToCommand(Client, "[SM] Usage: sm_unlock_unblock <weapon name>");
		return Plugin_Handled;	
	}
	
	new String:alias[64];
	
	GetCmdArg(1, alias, sizeof(alias));
	doUnblock(Client, alias);

	return Plugin_Handled;	
}

public Action:Command_urExceptionAdd(Client, args)
{
	if (args != 2)
	{
		ReplyToCommand(Client, "[SM] Usage: sm_unlock_exception_add <weapon name> <target>");
		return Plugin_Handled;	
	}
	
	new String:alias[64];
	GetCmdArg(1, alias, sizeof(alias));
	
	new String:target[64];
	GetCmdArg(2, target, sizeof(target));
		
	if (StrEqual(alias, "all", false))
	{
		new bool:success = true;
		for (new i=0; i<sizeof(weaponAlias); i++)
		{
			if (!createException(target, i))
			{
				ReplyToCommand(Client, "[Unlock Replacer]: Invalid target. Only steam IDs and classes are accepted.");
				success = false;
				break;
			}
		}
		if (success)
			ReplyToCommand(Client, "\x04[Unlock Replacer]:\x01 All exception rules have been set for: %s. This will take effect when the effected clients respawn or visit a weapons cabinet.", target);	
		
		return Plugin_Handled;	
	}
	
	new idx = -1;
	for (new i=0; i<sizeof(weaponAlias); i++)
	{
		if (StrEqual(weaponAlias[i], alias, false))
		{
			idx = i;
			break;
		}
	}
	
	if(idx > -1)
	{	
		if (createException(target, idx))
		{
			ReplyToCommand(Client, "[Unlock Replacer]: Exception rule set for: %s - %s. This will take effect when the effected clients respawn or visit a weapons cabinet.", alias, target);
		} else {
			ReplyToCommand(Client, "[Unlock Replacer]: Invalid target. Only steam IDs and classes are accepted.");
		}
	} else {
		ReplyToCommand(Client, "[Unlock Replacer]: That weapon is not recognised. Type sm_unlock_alias.");
	}

	return Plugin_Handled;	
}

public Action:Command_urExceptionRemove(Client, args)
{
	if (args != 2)
	{
		ReplyToCommand(Client, "[SM] Usage: sm_unlock_exception_remove <weapon name> <target>");
		return Plugin_Handled;	
	}
	
	new String:alias[64];
	GetCmdArg(1, alias, sizeof(alias));
	
	new String:target[64];
	GetCmdArg(2, target, sizeof(target));
		
	if (StrEqual(alias, "all", false))
	{
		new x;
		for (new i=0; i<sizeof(weaponAlias); i++)
		{
			if (StrEqual(target, "all", false))
			{
				ClearArray(getArray(i));
			} else {
				x = FindStringInArray(getArray(i), target);
				if (x > -1)
					RemoveFromArray(getArray(i), x);
			}
		}
		forceWeaponCheck();
		ReplyToCommand(Client, "\x04[Unlock Replacer]:\x01 All exception rules have been removed for: %s", target);	
		
		return Plugin_Handled;	
	}
	
	new idx = -1;
	for (new i=0; i<sizeof(weaponAlias); i++)
	{
		if (StrEqual(weaponAlias[i], alias, false))
		{
			idx = i;
			break;
		}
	}
	
	// shit be case sensitive, lower it all
	for (new i=0; i<sizeof(target); i++)
		CharToUpper(target[i]); // returns lower case chars, surely that should be CharToLower but hey...
		
	if (idx > -1 && StrEqual(target, "all", false))
	{
		ClearArray(getArray(idx));
		forceWeaponCheck();
		ReplyToCommand(Client, "\x04[Unlock Replacer]:\x01 All exception rules have been removed for: %s. This will take effect immediately.", alias);	
		
		return Plugin_Handled;	
	}
	
	if (idx > -1)
	{	
		new index = FindStringInArray(getArray(idx), target);
		if (index > -1)
		{
			RemoveFromArray(getArray(idx), index);
			forceWeaponCheck();
			ReplyToCommand(Client, "\x04[Unlock Replacer]:\x01  Exception rule removed for: %s - %s. This will take effect immediately.", alias, target);	
		} else {
			ReplyToCommand(Client, "\x04[Unlock Replacer]:\x01 That target cannot be found. Type sm_unlock_exceptions_list <weapon name> to print the list of current exceptions.");	
		}
	} else {
		ReplyToCommand(Client, "\x04[Unlock Replacer]:\x01 That weapon is not recognised. Type sm_unlock_alias to print a list of known weapons.");	
	}

	return Plugin_Handled;	
}

public Action:Command_urExceptionList(Client, args)
{
	if (args != 1)
	{
		ReplyToCommand(Client, "[SM] Usage: sm_unlock_exception_list <weapon name>");
		return Plugin_Handled;	
	}
	
	new String:alias[64];
	GetCmdArg(1, alias, sizeof(alias));
	
	new idx = -1;
	for (new i=0; i<sizeof(weaponAlias); i++)
	{
		if (StrEqual(weaponAlias[i], alias, false))
		{
			idx = i;
			break;
		}
	}
	
	if (idx > -1)
	{
		new String:buffer[64];
		ReplyToCommand(Client,"[Unlock Replacer]: Current exceptions for %s:", alias);
		for (new i=0; i<GetArraySize(getArray(idx)); i++)
		{
			GetArrayString(getArray(idx), i, buffer, 64);
			ReplyToCommand(Client, "                 > %s", buffer );	
		}
		ReplyToCommand(Client,"[Unlock Replacer]: End of list");
	} else {
		ReplyToCommand(Client, "\x04[Unlock Replacer]:\x01 That weapon is not recognised. Type sm_unlock_alias to print a list of known weapons.");	
	}

	return Plugin_Handled;	
}

public Action:Command_urBlockList(Client, args)
{
	ReplyToCommand(Client,"[Unlock Replacer]: Blocked Weapons:");
	for (new i=0; i<sizeof(weaponAlias); i++)
	{	
		if (isBlocked[i])
		{
			ReplyToCommand(Client, "                 > %s", weaponAlias[i] );	
		}
	}
	ReplyToCommand(Client,"[Unlock Replacer]: End of list");
	
	if(Client > 0) {
		PrintToChat(Client, "\x04[Unlock Replacer]:\x01 A list of currently blocked unlocks have been printed in your console.");
	}
	
	return Plugin_Handled;	
}

public Action:Command_urAliasList(Client, args)
{
	ReplyToCommand(Client,"[Unlock Replacer]: Weapon Indentifiers:");
	for(new i=0; i<sizeof(weaponAlias); i++ )
	{
		ReplyToCommand( Client, "                 > %s", weaponAlias[i] );
	}
	ReplyToCommand(Client,"[Unlock Replacer]: End of list");
	
	if(Client > 0) {
		PrintToChat(Client, "\x04[Unlock Replacer]:\x01 A full list of weapon identifiers have been printed in your console.");
	}
	
	return Plugin_Handled;	
}

// This is the main 'event trigger' for the plugin when stuff starts happening
public OnEntityCreated(entity, const String:classname[])
{		
	// The algorithm must be done next frame so that the entity is fully spawned
	CreateTimer(0.0, ProcessEdict, entity, TIMER_FLAG_NO_MAPCHANGE);
	
	return;
}

public Action:ProcessEdict(Handle:timer, any:edict)
{
	if (!IsValidEdict(edict))
		return Plugin_Handled;
		
	new String:netclassname[64];
	GetEntityNetClass(edict, netclassname, sizeof(netclassname));
	
	// Checking to see if its an edict with an Item Definition Index
	if (FindSendPropOffs(netclassname, "m_iItemDefinitionIndex") == -1)
		return Plugin_Handled;
		
	new defIdx = GetEntProp(edict, Prop_Send, "m_iItemDefinitionIndex");
	
	// Is this a known unlock
	new idx = -1;
	for (new i=0; i<sizeof(unlockDefIdx); i++)
	{
		if (defIdx == unlockDefIdx[i])
		{
			idx = i;
			break;
		}
	}
	
	if (idx == -1)
		return Plugin_Handled;
	
	// Is this unlock blocked
	if(!isBlocked[idx])
		return Plugin_Handled;
		
	// Unlock is blocked do further processing and exception checking
	ReplaceClientWeapons(edict, idx);
	
	return Plugin_Handled;
}

ReplaceClientWeapons(edict, idx)
{
	// Get entity owner
	new Client = GetEntPropEnt(edict, Prop_Send, "m_hOwnerEntity");
	new Float:uberPercent;
	
	// Check whether the owner is on the exceptions list, if so do nothing
	if (isExcluded(Client, idx))
		return;
		
	if (idx == 35) // Kritzkreig
	{
		// Store uber percent
		uberPercent = GetEntPropFloat(edict, Prop_Send, "m_flChargeLevel");
	}
	
	// else, remove the entity and notify the client.
	RemovePlayerItem(Client, edict);
	RemoveEdict(edict);
	
	// Replacing the client's weapon
	new newWeapon = SDKCall(hGiveNamedItem, Client, replacementWeapon[idx], 0);
	SDKCall(hWeaponEquip, Client, newWeapon);

	// Huntsman and Flaregun replacements need to be given extra ammo
	if (idx == 9) // Huntsman
		SetEntData(Client, FindSendPropInfo("CTFPlayer", "m_iAmmo") +4, 25, 1);
	if (idx == 7) // Flaregun
		SetEntData(Client, FindSendPropInfo("CTFPlayer", "m_iAmmo") +8, 32, 1);
	if (idx == 35) // Kritzkreig
		SetEntPropFloat(newWeapon, Prop_Send, "m_flChargeLevel", uberPercent); 
	
	// Send a message
	if(CanClientReceiveMsg[Client])
	{
		PrintToChat(Client, "\x04[Unlock Replacer]:\x01 One (or more) of your unlockable weapons have be replaced by the server. You may need to adjust your class loadout.");
		// Stops the client getting spammed by only sending one message every 30 seconds.
		CanClientReceiveMsg[Client] = false;
		CreateTimer(30.0, resetClientMsgStatus, Client, TIMER_FLAG_NO_MAPCHANGE);
	}
		
	return;
}

public Action:resetClientMsgStatus(Handle:timer, any:Client)
{
	CanClientReceiveMsg[Client] = true;
}

// Admin menu stuff can be found at the end of the file

doBlock(Client, const String:alias[64])
{
	new index = -1;
	for (new i=0; i<sizeof(weaponAlias); i++)
	{
		if (StrEqual(weaponAlias[i], alias, false))
		{
			index = i;
			break;
		}
	}
	
	if (StrEqual(alias, "all", false))
	{
		for (new i=0; i<sizeof(weaponAlias); i++)
			isBlocked[i] = true;
			
		ShowActivity2(Client, "\x04[Unlock Replacer]:\x01 ", "All weapons have been blocked by %N.", Client);
		forceWeaponCheck();
	} else if(index > -1)
	{		
		if (!isBlocked[index])
		{		
			isBlocked[index] = true;
			
			ShowActivity2(Client, "\x04[Unlock Replacer]:\x01 ", "%s has been blocked by %N.", alias, Client);
			
			// Removing the weapon from clients
			forceWeaponCheck();
		} else {
			ReplyToCommand(Client, "\x04[Unlock Replacer]:\x01 ", "%s is already blocked.", alias);	
		}
	} else {
		ReplyToCommand(Client, "\x04[Unlock Replacer]:\x01 That weapon is not recognised. Type sm_unlock_alias to print a list of known weapons.");	
	}
}

doUnblock(Client, const String:alias[64])
{	
	new idx = -1;
	for (new i=0; i<sizeof(weaponAlias); i++)
	{
		if (StrEqual(weaponAlias[i], alias, false))
		{
			idx = i;
			break;
		}
	}
	
	if (StrEqual(alias, "all", false))
	{
		for (new i=0; i<sizeof(weaponAlias); i++)
			isBlocked[i] = false;
			
		ShowActivity2(Client, "\x04[Unlock Replacer]:\x01 ", "All weapons have been unblocked by %N.", Client);
		forceWeaponCheck();
	} else if(idx > -1)
	{			
		if (isBlocked[idx])
		{
			isBlocked[idx] = false;
			
			ShowActivity2(Client, "\x04[Unlock Replacer]:\x01 ", "%s has been unblocked by %N.", alias, Client);
		} else {
			ReplyToCommand(Client, "\x04[Unlock Replacer]:\x01 ", "%s is not currently blocked.", alias);	
		}
	} else {
		ReplyToCommand(Client, "\x04[Unlock Replacer]:\x01 That weapon is not recognised. Type sm_unlock_alias.");
	}
}

forceWeaponCheck()
{
	new edict;
	new idx;
	
	for (new Client=1; Client<=MaxClients; Client++)
	{
		if (IsClientInGame(Client) && IsPlayerAlive(Client))
		{
			for (new x=0; x<11; x++)
			{
				if((edict = GetPlayerWeaponSlot(Client, x)) != -1)
				{
					new defIdx = GetEntProp(edict, Prop_Send, "m_iItemDefinitionIndex");
					
					// Checking the entity, similar to the algorithm from dhOnEntitySpawned
					idx = -1;
					for (new i=0; i<sizeof(unlockDefIdx); i++)
					{
						if (defIdx == unlockDefIdx[i])
						{
							idx = i;
							break;
						}
					}	
					
					if ((idx > -1) && (isBlocked[idx]))
					{
						ReplaceClientWeapons(edict, idx);
					}
				}
			}
		}
	}
	
	// Check items that dont take a slot in players inventory
	idx = 17;				// 17 = Razorback
	if (isBlocked[idx])	
	{
		edict = MaxClients+1;
		
		while((edict = FindEntityByClassname(edict, "tf_wearable_item")) != -1)
		{
			if (GetEntProp(edict, Prop_Send, "m_iItemDefinitionIndex") == 57)
			{
				new Client = GetEntPropEnt(edict, Prop_Send, "m_hOwnerEntity");
				if (!isExcluded(Client, idx))
				{	
					RemoveEdict(edict);
					
					new newWeapon = SDKCall(hGiveNamedItem, Client, replacementWeapon[idx], 0);
					SDKCall(hWeaponEquip, Client, newWeapon);
					
					if(CanClientReceiveMsg[Client])
					{
						PrintToChat(Client, "\x04[Unlock Replacer]:\x01 One (or more) of your unlockable weapons have be replaced by the server. You may need to adjust your class loadout.");
						// Stops the client getting spammed by only sending one message every 30 seconds.
						CanClientReceiveMsg[Client] = false;
						CreateTimer(30.0, resetClientMsgStatus, Client, TIMER_FLAG_NO_MAPCHANGE);
					}
				}
			}
		}
	}
	
	idx = 5;				// 5 = Cloak and Dagger
	if (isBlocked[idx])
	{
		edict = MaxClients+1;
		
		while((edict = FindEntityByClassname(edict, "tf_weapon_invis")) != -1)
		{
			if (GetEntProp(edict, Prop_Send, "m_iItemDefinitionIndex") == 60)
			{
				new Client = GetEntPropEnt(edict, Prop_Send, "m_hOwnerEntity");
				if (!isExcluded(Client, idx))
				{	
					RemoveEdict(edict);
					
					new newWeapon = SDKCall(hGiveNamedItem, Client, replacementWeapon[idx], 0);
					SDKCall(hWeaponEquip, Client, newWeapon);
					
					if(CanClientReceiveMsg[Client])
					{
						PrintToChat(Client, "\x04[Unlock Replacer]:\x01 One (or more) of your unlockable weapons have be replaced by the server. You may need to adjust your class loadout.");
						// Stops the client getting spammed by only sending one message every 30 seconds.
						CanClientReceiveMsg[Client] = false;
						CreateTimer(30.0, resetClientMsgStatus, Client, TIMER_FLAG_NO_MAPCHANGE);
					}
				}
			}
		}	
	}
	
	idx = 6;		// 6 = Dead Ringer
	if (isBlocked[idx])
	{
		edict = MaxClients+1;
		
		while((edict = FindEntityByClassname(edict, "tf_weapon_invis")) != -1)
		{
			if (GetEntProp(edict, Prop_Send, "m_iItemDefinitionIndex") == 59)
			{
				new Client = GetEntPropEnt(edict, Prop_Send, "m_hOwnerEntity");
				if (!isExcluded(Client, idx))
				{	
					RemoveEdict(edict);
					
					new newWeapon = SDKCall(hGiveNamedItem, Client, replacementWeapon[idx], 0);
					SDKCall(hWeaponEquip, Client, newWeapon);
					
					if(CanClientReceiveMsg[Client])
					{
						PrintToChat(Client, "\x04[Unlock Replacer]:\x01 One (or more) of your unlockable weapons have be replaced by the server. You may need to adjust your class loadout.");
						// Stops the client getting spammed by only sending one message every 30 seconds.
						CanClientReceiveMsg[Client] = false;
						CreateTimer(30.0, resetClientMsgStatus, Client, TIMER_FLAG_NO_MAPCHANGE);
					}
				}
			}
		}	
	}
}

createException(const String:target[64], idx)
{
	// Currently exceptions can either be done by steam ID or by class
	if (StrContains(target, "STEAM_", true) == 0) 
	{
		PushArrayString(getArray(idx), target);
		return true;
	} 
	
	for (new i=0; i<sizeof(target); i++)
		CharToUpper(target[i]);
		
	if (StrEqual(target, "scout", false))
	{
		PushArrayString(getArray(idx), target);
		return true;	
	}
	if (StrEqual(target, "sniper", false))
	{
		PushArrayString(getArray(idx), target);	
		return true;			
	}
	if (StrEqual(target, "soldier", false))
	{
		PushArrayString(getArray(idx), target);
		return true;			
	}
	if (StrEqual(target, "demoman", false))
	{
		PushArrayString(getArray(idx), target);
		return true;			
	}
	if (StrEqual(target, "medic", false))
	{
		PushArrayString(getArray(idx), target);
		return true;			
	}
	if (StrEqual(target, "heavy", false))
	{
		PushArrayString(getArray(idx), target);
		return true;			
	}
	if (StrEqual(target, "pyro", false))
	{
		PushArrayString(getArray(idx), target);
		return true;			
	}
	if (StrEqual(target, "spy", false))
	{
		PushArrayString(getArray(idx), target);
		return true;		
	}
	if (StrEqual(target, "engineer", false))
	{
		PushArrayString(getArray(idx), target);	
		return true;		
	}
	
	return false;
}

isExcluded(Client, idx)
{
	new String:steamId[64];
	
	GetClientAuthString(Client, steamId, 64);
	if (FindStringInArray(getArray(idx), steamId) > -1)
		return true;
		
	if (_:TF2_GetPlayerClass(Client) == 1)
		if (FindStringInArray(getArray(idx), "scout") > -1)
			return true;
	if (_:TF2_GetPlayerClass(Client) == 2)
		if (FindStringInArray(getArray(idx), "sniper") > -1)
			return true;
	if (_:TF2_GetPlayerClass(Client) == 3)
		if (FindStringInArray(getArray(idx), "soldier") > -1)
			return true;
	if (_:TF2_GetPlayerClass(Client) == 4)
		if (FindStringInArray(getArray(idx), "demoman") > -1)
			return true;
	if (_:TF2_GetPlayerClass(Client) == 5)
		if (FindStringInArray(getArray(idx), "medic") > -1)
			return true;
	if (_:TF2_GetPlayerClass(Client) == 6)
		if (FindStringInArray(getArray(idx), "heavy") > -1)
			return true;
	if (_:TF2_GetPlayerClass(Client) == 7)
		if (FindStringInArray(getArray(idx), "pyro") > -1)
			return true;
	if (_:TF2_GetPlayerClass(Client) == 8)
		if (FindStringInArray(getArray(idx), "spy") > -1)
			return true;
	if (_:TF2_GetPlayerClass(Client) == 9)
		if (FindStringInArray(getArray(idx), "engineer") > -1)
			return true;
	
	return false;
}

Handle:getArray(idx)
{
	switch (idx)
	{
		case 0: return excAmbassador;
		case 1: return excAxetinguisher;
		case 2: return excBackburner;
		case 3: return excBonk;
		case 4: return excBlutsauger;
		case 5: return excCloakAndDagger;
		case 6: return excDeadRinger;
		case 7: return excFlaregun;
		case 8: return excFAN;
		case 9: return excHuntsman;
		case 10: return excJarate;
		case 11: return excKGB;
		case 12: return excKritzkrieg;
		case 13: return excNatasha;
		case 14: return excSandman;
		case 15: return excSandvich;
		case 16: return excUbersaw;
		case 17: return excRazerback;
		case 18: return excEyelander;
		case 19: return excTarge;
		case 20: return excScottishResistance;
		case 21: return excEqualizer;
		case 22: return excBuffBanner;
		case 23: return excTheDirectHit;
		case 24: return excGunboats;
	}
	
	return INVALID_HANDLE;
}


//
// Admin Menu Stuff
//

public OnLibraryRemoved(const String:name[])
{
	if (strcmp(name, "adminmenu") == 0)
	{
		hTopMenu = INVALID_HANDLE;
	}
}
 
public OnAdminMenuReady(Handle:topmenu)
{
	if (topmenu == hTopMenu)
	{
		return;
	}
 
 	hTopMenu = topmenu;
 	
	new TopMenuObject:server_commands = FindTopMenuCategory(hTopMenu, ADMINMENU_SERVERCOMMANDS);
 
	if (server_commands == INVALID_TOPMENUOBJECT)
	{
		return;
	}
 
	AddToTopMenu(hTopMenu, 
		"sm_unlock_block",
		TopMenuObject_Item,
		AdminMenu_block,
		server_commands,
		"sm_unlock_block",
		ADMFLAG_GENERIC);
		
	AddToTopMenu(hTopMenu, 
		"sm_unlock_unblock",
		TopMenuObject_Item,
		AdminMenu_unblock,
		server_commands,
		"sm_unlock_unblock",
		ADMFLAG_GENERIC);
}
 
public AdminMenu_block(Handle:topmenu, 
					TopMenuAction:action,
					TopMenuObject:object_id,
					Client,
					String:buffer[],
					maxlength)
{	
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Block Unlock");

	}
	else if (action == TopMenuAction_SelectOption)
	{
		DisplayUnblockedMenu(Client);	
	}
}

public MenuHandler_ListUnblocked(Handle:menu, MenuAction:action, Client, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(hTopMenu, Client, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{		
		new String:weapon[64];

		GetMenuItem(menu, param2, weapon, 64);
		
		doBlock(Client, weapon);

		DisplayUnblockedMenu(Client);
	}
}
 
public AdminMenu_unblock(Handle:topmenu, 
					TopMenuAction:action,
					TopMenuObject:object_id,
					Client,
					String:buffer[],
					maxlength)
{	
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Unblock Unlock");

	}
	else if (action == TopMenuAction_SelectOption)
	{
		DisplayBlockedMenu(Client);	
	}
}

public MenuHandler_ListBlocked(Handle:menu, MenuAction:action, Client, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(hTopMenu, Client, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{		
		new String:weapon[64];

		GetMenuItem(menu, param2, weapon, 64);
		
		doUnblock(Client, weapon);

		DisplayBlockedMenu(Client);
	}
}

DisplayUnblockedMenu(Client)
{
	new Handle:menu = CreateMenu(MenuHandler_ListUnblocked);
	
	decl String:title[100];
	
	Format(title, sizeof(title), "Select a weapon to block:");
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	
	for (new i=0; i<sizeof(weaponAlias); i++)
	{
		if (!isBlocked[i])
		{
			AddMenuItem(menu, weaponAlias[i], weaponAlias[i]);		
		}
	}
	
	DisplayMenu(menu, Client, MENU_TIME_FOREVER);
}

DisplayBlockedMenu(Client)
{
	new Handle:menu = CreateMenu(MenuHandler_ListBlocked);
	
	decl String:title[100];
	
	Format(title, sizeof(title), "Select a weapon to unblock:");
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	
	for (new i=0; i<sizeof(weaponAlias); i++)
	{
		if (isBlocked[i])
		{
			AddMenuItem(menu, weaponAlias[i], weaponAlias[i]);		
		}
	}
	
	DisplayMenu(menu, Client, MENU_TIME_FOREVER);
}

//
// End of Menu
//
