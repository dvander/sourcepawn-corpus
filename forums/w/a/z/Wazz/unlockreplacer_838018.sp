#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#include <sdkhooks>

#undef REQUIRE_PLUGIN
#include <adminmenu>

#define PLUGIN_VERSION 		"2.6.0.5"

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
new Handle:excPainTrain;
new Handle:excDalokohsBar;
new Handle:excHomewrecker;
// add more handles here, one per weapon
// You must add this Handle to the GetArray funcion
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
	"Gunboats",
	"Pain Train",
	"Dalokohs Bar",
	"Homewrecker"	// add more aliases here, aliases are the names used on the admin menu. MUST BE PARALLEL TO UNLOCKDEFIDX AND REPLACEMENT ARRAY
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
	133,
	154,
	159,
	153	// add more unlockable weapon indexes here, weapon indexes are used to indentify each weapon.
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
	"tf_weapon_shotgun_soldier",
	"tf_weapon_shovel",
	"tf_weapon_shotgun_hwg",
	"tf_weapon_fireaxe"		// add more replacement weapons here, this is what the server gives the client instead of their unlock.
};

new Float:g_fClientUberPercent[MAXPLAYERS + 1];
new bool:g_bCanClientReceiveMsg[MAXPLAYERS+1];

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
	excPainTrain = CreateArray(64);
	excDalokohsBar = CreateArray(64);
	excHomewrecker = CreateArray(64);
	
	for(new client=1; client<=MaxClients; client++)
		g_bCanClientReceiveMsg[client] = true;
		
	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);
	}
	
	HookEvent("player_spawn", OnPlayerSpawn);
}

public OnclientPutInServer(client)
{
	g_fClientUberPercent[client] = 0.0;
}

public OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_fClientUberPercent[GetClientOfUserId(GetEventInt(event, "userid"))] = 0.0;
}

public OnMapStart()
{
	for (new client=1; client<=MaxClients; client++)
	{
		g_bCanClientReceiveMsg[client] = true;
	}
}

public Action:Command_urBlock(client, args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_unlock_block <weapon>");
		return Plugin_Handled;	
	}
	
	new String:alias[64];
	
	GetCmdArg(1, alias, 64);
	DoBlock(client, alias);

	return Plugin_Handled;
}

public Action:Command_urUnblock(client, args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_unlock_unblock <weapon name>");
		return Plugin_Handled;	
	}
	
	new String:alias[64];
	
	GetCmdArg(1, alias, sizeof(alias));
	DoUnblock(client, alias);

	return Plugin_Handled;	
}

public Action:Command_urExceptionAdd(client, args)
{
	if (args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_unlock_exception_add <weapon name> <target>");
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
			if (!CreateException(target, i))
			{
				ReplyToCommand(client, "[Unlock Replacer]: Invalid target. Only steam IDs and classes are accepted.");
				success = false;
				break;
			}
		}
		if (success)
			ReplyToCommand(client, "\x04[Unlock Replacer]:\x01 All exception rules have been set for: %s. This will take effect when the effected clients respawn or visit a weapons cabinet.", target);	
		
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
		if (CreateException(target, idx))
		{
			ReplyToCommand(client, "[Unlock Replacer]: Exception rule set for: %s - %s. This will take effect when the effected clients respawn or visit a weapons cabinet.", alias, target);
		} else {
			ReplyToCommand(client, "[Unlock Replacer]: Invalid target. Only steam IDs and classes are accepted.");
		}
	} else {
		ReplyToCommand(client, "[Unlock Replacer]: That weapon is not recognised. Type sm_unlock_alias.");
	}

	return Plugin_Handled;	
}

public Action:Command_urExceptionRemove(client, args)
{
	if (args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_unlock_exception_remove <weapon name> <target>");
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
				ClearArray(GetArray(i));
			} else {
				x = FindStringInArray(GetArray(i), target);
				if (x > -1)
					RemoveFromArray(GetArray(i), x);
			}
		}
		ForceWeaponCheck();
		ReplyToCommand(client, "\x04[Unlock Replacer]:\x01 All exception rules have been removed for: %s", target);	
		
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
		ClearArray(GetArray(idx));
		ForceWeaponCheck();
		ReplyToCommand(client, "\x04[Unlock Replacer]:\x01 All exception rules have been removed for: %s. This will take effect immediately.", alias);	
		
		return Plugin_Handled;	
	}
	
	if (idx > -1)
	{	
		new index = FindStringInArray(GetArray(idx), target);
		if (index > -1)
		{
			RemoveFromArray(GetArray(idx), index);
			ForceWeaponCheck();
			ReplyToCommand(client, "\x04[Unlock Replacer]:\x01  Exception rule removed for: %s - %s. This will take effect immediately.", alias, target);	
		} else {
			ReplyToCommand(client, "\x04[Unlock Replacer]:\x01 That target cannot be found. Type sm_unlock_exceptions_list <weapon name> to print the list of current exceptions.");	
		}
	} else {
		ReplyToCommand(client, "\x04[Unlock Replacer]:\x01 That weapon is not recognised. Type sm_unlock_alias to print a list of known weapons.");	
	}

	return Plugin_Handled;	
}

public Action:Command_urExceptionList(client, args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_unlock_exception_list <weapon name>");
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
		ReplyToCommand(client,"[Unlock Replacer]: Current exceptions for %s:", alias);
		for (new i=0; i<GetArraySize(GetArray(idx)); i++)
		{
			GetArrayString(GetArray(idx), i, buffer, 64);
			ReplyToCommand(client, "                 > %s", buffer );	
		}
		ReplyToCommand(client,"[Unlock Replacer]: End of list");
	} else {
		ReplyToCommand(client, "\x04[Unlock Replacer]:\x01 That weapon is not recognised. Type sm_unlock_alias to print a list of known weapons.");	
	}

	return Plugin_Handled;	
}

public Action:Command_urBlockList(client, args)
{
	ReplyToCommand(client,"[Unlock Replacer]: Blocked Weapons:");
	for (new i=0; i<sizeof(weaponAlias); i++)
	{	
		if (isBlocked[i])
		{
			ReplyToCommand(client, "                 > %s", weaponAlias[i] );	
		}
	}
	ReplyToCommand(client,"[Unlock Replacer]: End of list");
	
	if(client > 0) {
		PrintToChat(client, "\x04[Unlock Replacer]:\x01 A list of currently blocked unlocks have been printed in your console.");
	}
	
	return Plugin_Handled;	
}

public Action:Command_urAliasList(client, args)
{
	ReplyToCommand(client,"[Unlock Replacer]: Weapon Indentifiers:");
	for(new i=0; i<sizeof(weaponAlias); i++ )
	{
		ReplyToCommand( client, "                 > %s", weaponAlias[i] );
	}
	ReplyToCommand(client,"[Unlock Replacer]: End of list");
	
	if(client > 0) {
		PrintToChat(client, "\x04[Unlock Replacer]:\x01 A full list of weapon identifiers have been printed in your console.");
	}
	
	return Plugin_Handled;	
}

public OnEntityDestroyed(entity)
{
	new String:classname[64];
	GetEdictClassname(entity, classname, sizeof(classname));

	// If the weapons is a medigun, store its uber percent
	if (StrEqual(classname, "tf_weapon_medigun"))
	{
		new owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
		
		if (owner > 0 && owner <= MaxClients)
		{
			g_fClientUberPercent[owner] = GetEntPropFloat(entity, Prop_Send, "m_flChargeLevel");
		}
	}
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
	new client = GetEntPropEnt(edict, Prop_Send, "m_hOwnerEntity");
	
	// Check whether the owner is on the exceptions list, if so do nothing
	if (client == -1 || IsExcluded(client, idx))
		return;
	
	// else, remove the entity and notify the client.
	RemovePlayerItem(client, edict);
	RemoveEdict(edict);
	
	// Replacing the client's weapon
	new newWeapon = SDKCall(hGiveNamedItem, client, replacementWeapon[idx], 0);
	SDKCall(hWeaponEquip, client, newWeapon);

	// Huntsman and Flaregun replacements need to be given extra ammo
	if (idx == 9) // Huntsman
		SetEntData(client, FindSendPropInfo("CTFPlayer", "m_iAmmo") +4, 25, 1);
	if (idx == 7) // Flaregun
		SetEntData(client, FindSendPropInfo("CTFPlayer", "m_iAmmo") +8, 32, 1);
	if (idx == 12) // Kritzkreig
		SetEntPropFloat(newWeapon, Prop_Send, "m_flChargeLevel", g_fClientUberPercent[client]); // Give them their uber percent back 
	
	// Send a message
	if(g_bCanClientReceiveMsg[client])
	{
		PrintToChat(client, "\x04[Unlock Replacer]:\x01 One (or more) of your unlockable weapons have be replaced by the server. You may need to adjust your class loadout.");
		// Stops the client getting spammed by only sending one message every 30 seconds.
		g_bCanClientReceiveMsg[client] = false;
		CreateTimer(30.0, ResetClientMsgStatus, client, TIMER_FLAG_NO_MAPCHANGE);
	}
		
	return;
}

public Action:ResetClientMsgStatus(Handle:timer, any:client)
{
	g_bCanClientReceiveMsg[client] = true;
}

// Admin menu stuff can be found at the end of the file

DoBlock(client, const String:alias[64])
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
			
		ShowActivity2(client, "\x04[Unlock Replacer]:\x01 ", "All weapons have been blocked by %N.", client);
		ForceWeaponCheck();
	} else if(index > -1)
	{		
		if (!isBlocked[index])
		{		
			isBlocked[index] = true;
			
			ShowActivity2(client, "\x04[Unlock Replacer]:\x01 ", "%s has been blocked by %N.", alias, client);
			
			// Removing the weapon from clients
			ForceWeaponCheck();
		} else {
			ReplyToCommand(client, "\x04[Unlock Replacer]:\x01 ", "%s is already blocked.", alias);	
		}
	} else {
		ReplyToCommand(client, "\x04[Unlock Replacer]:\x01 That weapon is not recognised. Type sm_unlock_alias to print a list of known weapons.");	
	}
}

DoUnblock(client, const String:alias[64])
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
			
		ShowActivity2(client, "\x04[Unlock Replacer]:\x01 ", "All weapons have been unblocked by %N.", client);
		ForceWeaponCheck();
	} else if(idx > -1)
	{			
		if (isBlocked[idx])
		{
			isBlocked[idx] = false;
			
			ShowActivity2(client, "\x04[Unlock Replacer]:\x01 ", "%s has been unblocked by %N.", alias, client);
		} else {
			ReplyToCommand(client, "\x04[Unlock Replacer]:\x01 ", "%s is not currently blocked.", alias);	
		}
	} else {
		ReplyToCommand(client, "\x04[Unlock Replacer]:\x01 That weapon is not recognised. Type sm_unlock_alias.");
	}
}

ForceWeaponCheck()
{
	new edict;
	new idx;
	
	for (new client=1; client<=MaxClients; client++)
	{
		if (IsClientInGame(client) && IsPlayerAlive(client))
		{
			for (new x=0; x<11; x++)
			{
				if((edict = GetPlayerWeaponSlot(client, x)) != -1)
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
				new client = GetEntPropEnt(edict, Prop_Send, "m_hOwnerEntity");
				if (!IsExcluded(client, idx))
				{	
					RemoveEdict(edict);
					
					new newWeapon = SDKCall(hGiveNamedItem, client, replacementWeapon[idx], 0);
					SDKCall(hWeaponEquip, client, newWeapon);
					
					if(g_bCanClientReceiveMsg[client])
					{
						PrintToChat(client, "\x04[Unlock Replacer]:\x01 One (or more) of your unlockable weapons have be replaced by the server. You may need to adjust your class loadout.");
						// Stops the client getting spammed by only sending one message every 30 seconds.
						g_bCanClientReceiveMsg[client] = false;
						CreateTimer(30.0, ResetClientMsgStatus, client, TIMER_FLAG_NO_MAPCHANGE);
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
				new client = GetEntPropEnt(edict, Prop_Send, "m_hOwnerEntity");
				if (!IsExcluded(client, idx))
				{	
					RemoveEdict(edict);
					
					new newWeapon = SDKCall(hGiveNamedItem, client, replacementWeapon[idx], 0);
					SDKCall(hWeaponEquip, client, newWeapon);
					
					if(g_bCanClientReceiveMsg[client])
					{
						PrintToChat(client, "\x04[Unlock Replacer]:\x01 One (or more) of your unlockable weapons have be replaced by the server. You may need to adjust your class loadout.");
						// Stops the client getting spammed by only sending one message every 30 seconds.
						g_bCanClientReceiveMsg[client] = false;
						CreateTimer(30.0, ResetClientMsgStatus, client, TIMER_FLAG_NO_MAPCHANGE);
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
				new client = GetEntPropEnt(edict, Prop_Send, "m_hOwnerEntity");
				if (!IsExcluded(client, idx))
				{	
					RemoveEdict(edict);
					
					new newWeapon = SDKCall(hGiveNamedItem, client, replacementWeapon[idx], 0);
					SDKCall(hWeaponEquip, client, newWeapon);
					
					if(g_bCanClientReceiveMsg[client])
					{
						PrintToChat(client, "\x04[Unlock Replacer]:\x01 One (or more) of your unlockable weapons have be replaced by the server. You may need to adjust your class loadout.");
						// Stops the client getting spammed by only sending one message every 30 seconds.
						g_bCanClientReceiveMsg[client] = false;
						CreateTimer(30.0, ResetClientMsgStatus, client, TIMER_FLAG_NO_MAPCHANGE);
					}
				}
			}
		}	
	}
}

CreateException(const String:target[64], idx)
{
	// Currently exceptions can either be done by steam ID or by class
	if (StrContains(target, "STEAM_", true) == 0) 
	{
		PushArrayString(GetArray(idx), target);
		return true;
	} 
	
	for (new i=0; i<sizeof(target); i++)
		CharToUpper(target[i]);
		
	if (StrEqual(target, "scout", false))
	{
		PushArrayString(GetArray(idx), target);
		return true;	
	}
	if (StrEqual(target, "sniper", false))
	{
		PushArrayString(GetArray(idx), target);	
		return true;			
	}
	if (StrEqual(target, "soldier", false))
	{
		PushArrayString(GetArray(idx), target);
		return true;			
	}
	if (StrEqual(target, "demoman", false))
	{
		PushArrayString(GetArray(idx), target);
		return true;			
	}
	if (StrEqual(target, "medic", false))
	{
		PushArrayString(GetArray(idx), target);
		return true;			
	}
	if (StrEqual(target, "heavy", false))
	{
		PushArrayString(GetArray(idx), target);
		return true;			
	}
	if (StrEqual(target, "pyro", false))
	{
		PushArrayString(GetArray(idx), target);
		return true;			
	}
	if (StrEqual(target, "spy", false))
	{
		PushArrayString(GetArray(idx), target);
		return true;		
	}
	if (StrEqual(target, "engineer", false))
	{
		PushArrayString(GetArray(idx), target);	
		return true;		
	}
	
	return false;
}

IsExcluded(client, idx)
{
	new String:steamId[64];
	
	GetClientAuthString(client, steamId, 64);
	if (FindStringInArray(GetArray(idx), steamId) > -1)
		return true;
		
	if (_:TF2_GetPlayerClass(client) == 1)
		if (FindStringInArray(GetArray(idx), "scout") > -1)
			return true;
	if (_:TF2_GetPlayerClass(client) == 2)
		if (FindStringInArray(GetArray(idx), "sniper") > -1)
			return true;
	if (_:TF2_GetPlayerClass(client) == 3)
		if (FindStringInArray(GetArray(idx), "soldier") > -1)
			return true;
	if (_:TF2_GetPlayerClass(client) == 4)
		if (FindStringInArray(GetArray(idx), "demoman") > -1)
			return true;
	if (_:TF2_GetPlayerClass(client) == 5)
		if (FindStringInArray(GetArray(idx), "medic") > -1)
			return true;
	if (_:TF2_GetPlayerClass(client) == 6)
		if (FindStringInArray(GetArray(idx), "heavy") > -1)
			return true;
	if (_:TF2_GetPlayerClass(client) == 7)
		if (FindStringInArray(GetArray(idx), "pyro") > -1)
			return true;
	if (_:TF2_GetPlayerClass(client) == 8)
		if (FindStringInArray(GetArray(idx), "spy") > -1)
			return true;
	if (_:TF2_GetPlayerClass(client) == 9)
		if (FindStringInArray(GetArray(idx), "engineer") > -1)
			return true;
	
	return false;
}

Handle:GetArray(idx)
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
		case 25: return excPainTrain;
		case 26: return excDalokohsBar;
		case 27: return excHomewrecker;
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
					client,
					String:buffer[],
					maxlength)
{	
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Block Unlock");

	}
	else if (action == TopMenuAction_SelectOption)
	{
		DisplayUnblockedMenu(client);	
	}
}

public MenuHandler_ListUnblocked(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(hTopMenu, client, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{		
		new String:weapon[64];

		GetMenuItem(menu, param2, weapon, 64);
		
		DoBlock(client, weapon);

		DisplayUnblockedMenu(client);
	}
}
 
public AdminMenu_unblock(Handle:topmenu, 
					TopMenuAction:action,
					TopMenuObject:object_id,
					client,
					String:buffer[],
					maxlength)
{	
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Unblock Unlock");

	}
	else if (action == TopMenuAction_SelectOption)
	{
		DisplayBlockedMenu(client);	
	}
}

public MenuHandler_ListBlocked(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(hTopMenu, client, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{		
		new String:weapon[64];

		GetMenuItem(menu, param2, weapon, 64);
		
		DoUnblock(client, weapon);

		DisplayBlockedMenu(client);
	}
}

DisplayUnblockedMenu(client)
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
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

DisplayBlockedMenu(client)
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
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

//
// End of Menu
//
