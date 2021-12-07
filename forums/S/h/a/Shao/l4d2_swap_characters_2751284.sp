#define PLUGIN_VERSION		"1.1"

/*=======================================================================================
	Plugin Info:

*	Name	:	[L4D2] Swap Characters
*	Author	:	SilverShot
*	Descrp	:	Swap between L4D1 and L4D2 characters on command.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=321454
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.1 (21-Mar-2020)
	- Now changes the bots names to their characters. This is for SourceMod menu lists (e.g. kick) and "status" command.
	- Names above their heads change anyway without this.

1.0 (11-Feb-2020)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define MODEL_FRANCIS			"models/survivors/survivor_biker.mdl"
#define MODEL_LOUIS				"models/survivors/survivor_manager.mdl"
#define MODEL_ZOEY				"models/survivors/survivor_teenangst.mdl"
#define MODEL_BILL				"models/survivors/survivor_namvet.mdl"

#define MODEL_NICK 				"models/survivors/survivor_gambler.mdl"
#define MODEL_ROCHELLE			"models/survivors/survivor_producer.mdl"
#define MODEL_COACH				"models/survivors/survivor_coach.mdl"
#define MODEL_ELLIS				"models/survivors/survivor_mechanic.mdl"

#define SET_NICK				0, 4, MODEL_BILL
#define SET_ROCHELLE			1, 5, MODEL_ZOEY
#define SET_COACH				2, 7, MODEL_LOUIS
#define SET_ELLIS				3, 6, MODEL_FRANCIS

#define SET_BILL				4, 0, MODEL_NICK
#define SET_ZOEY				5, 1, MODEL_ROCHELLE
#define SET_FRANCIS				6, 3, MODEL_ELLIS
#define SET_LOUIS				7, 2, MODEL_COACH



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo = {
	name = "[L4D2] Swap Characters",
	author = "SilverShot",
	description = "Swap between L4D1 and L4D2 characters on command.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=321454"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnMapStart()
{
	PrecacheModel(MODEL_FRANCIS);
	PrecacheModel(MODEL_LOUIS);
	PrecacheModel(MODEL_ZOEY);
	PrecacheModel(MODEL_BILL);

	PrecacheModel(MODEL_NICK);
	PrecacheModel(MODEL_ROCHELLE);
	PrecacheModel(MODEL_COACH);
	PrecacheModel(MODEL_ELLIS);
}

public void OnPluginStart()
{
	RegAdminCmd("sm_l4d1",	CmdL4D1, ADMFLAG_ROOT, "Swap to L4D1 characters.");
	RegAdminCmd("sm_l4d2",	CmdL4D2, ADMFLAG_ROOT, "Swap to L4D2 characters.");

	CreateConVar("l4d2_swap_characters_version", PLUGIN_VERSION, "Swap Characters plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
}

public Action CmdL4D1(int client, int args)
{
	SwapCharacters(true);
	return Plugin_Handled;
}

public Action CmdL4D2(int client, int args)
{
	SwapCharacters(false);
	return Plugin_Handled;
}

void SwapCharacters(bool l4d1)
{
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && GetClientTeam(i) == 2 )
		{
			if( l4d1 )
			{
				DoSwap(i, SET_NICK);
				DoSwap(i, SET_ROCHELLE);
				DoSwap(i, SET_COACH);
				DoSwap(i, SET_ELLIS);
			} else {
				DoSwap(i, SET_BILL);
				DoSwap(i, SET_ZOEY);
				DoSwap(i, SET_FRANCIS);
				DoSwap(i, SET_LOUIS);
			}
		}
	}
}

void DoSwap(int client, int from, int to, const char[] sTo)
{
	if( from == GetEntProp(client, Prop_Send, "m_survivorCharacter") )
	{
		if( IsFakeClient(client) )
		{
			switch( to )
			{
				case 0: SetClientName(client, "Nick");
				case 1: SetClientName(client, "Rochelle");
				case 2: SetClientName(client, "Coach");
				case 3: SetClientName(client, "Ellis");
				case 4: SetClientName(client, "Bill");
				case 5: SetClientName(client, "Zoey");
				case 6: SetClientName(client, "Francis");
				case 7: SetClientName(client, "Louis");
			}
		}

		SetEntProp(client, Prop_Send, "m_survivorCharacter", to);
		SetEntityModel(client, sTo);
		ReEquipWeapons(client);
	}
}

// *********************************************************************************
// Reequip weapons functions
// *********************************************************************************

enum()
{
	iClip = 0,
	iAmmo,
	iUpgrade,
	iUpAmmo,
};

// ------------------------------------------------------------------
// Save weapon details, remove weapon, create new weapons with exact same properties
// Needed otherwise there will be animation bugs after switching characters due to different weapon mount points
// ------------------------------------------------------------------
void ReEquipWeapons(int client)
{
	int i_Weapon = GetEntDataEnt2(client, FindSendPropInfo("CBasePlayer", "m_hActiveWeapon"));
	
	// Don't bother with the weapon fix if dead or unarmed
	if (!IsPlayerAlive(client) || !IsValidEdict(i_Weapon) || !IsValidEntity(i_Weapon))  return;

	int iSlot0 = GetPlayerWeaponSlot(client, 0);  	int iSlot1 = GetPlayerWeaponSlot(client, 1);	
	int iSlot2 = GetPlayerWeaponSlot(client, 2);  	int iSlot3 = GetPlayerWeaponSlot(client, 3);
	int iSlot4 = GetPlayerWeaponSlot(client, 4);  	

	
	char sWeapon[64];
	GetClientWeapon(client, sWeapon, sizeof(sWeapon));
	
	//  Protection against grenade duplication exploit (throwing grenade then quickly changing character)
	if (iSlot2 > 0 && strcmp(sWeapon, "weapon_vomitjar", true) && strcmp(sWeapon, "weapon_pipe_bomb", true) && strcmp(sWeapon, "weapon_molotov", true ))
	{
		GetEdictClassname(iSlot2, sWeapon, 64);
		DeletePlayerSlot(client, iSlot2);
		CheatCommand(client, "give", sWeapon, "");
	}
	if (iSlot3 > 0)
	{
		GetEdictClassname(iSlot3, sWeapon, 64);
		DeletePlayerSlot(client, iSlot3);
		CheatCommand(client, "give", sWeapon, "");
	}
	if (iSlot4 > 0)
	{
		GetEdictClassname(iSlot4, sWeapon, 64);
		DeletePlayerSlot(client, iSlot4);
		CheatCommand(client, "give", sWeapon, "");
	}
	if (iSlot1 > 0) ReEquipSlot1(client, iSlot1);
	if (iSlot0 > 0) ReEquipSlot0(client, iSlot0);
}

// --------------------------------------
// Extra work to save/load ammo details
// --------------------------------------	
void ReEquipSlot0(int client, int iSlot0)
{
	int iWeapon0[4];
	char sWeapon[64];
	
	GetEdictClassname(iSlot0, sWeapon, 64);
		
	iWeapon0[iClip] = GetEntProp(iSlot0, Prop_Send, "m_iClip1", 4);
	iWeapon0[iAmmo] = GetClientAmmo(client, sWeapon);
	iWeapon0[iUpgrade] = GetEntProp(iSlot0, Prop_Send, "m_upgradeBitVec", 4);
	iWeapon0[iUpAmmo]  = GetEntProp(iSlot0, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", 4);
		
	DeletePlayerSlot(client, iSlot0);
	CheatCommand(client, "give", sWeapon, "");
		
	iSlot0 = GetPlayerWeaponSlot(client, 0);
	if (iSlot0 > 0)
	{
		SetEntProp(iSlot0, Prop_Send, "m_iClip1", iWeapon0[iClip], 4);
		SetClientAmmo(client, sWeapon, iWeapon0[iAmmo]);
		SetEntProp(iSlot0, Prop_Send, "m_upgradeBitVec", iWeapon0[iUpgrade], 4);
		SetEntProp(iSlot0, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", iWeapon0[iUpAmmo], 4);
	}			
}

// --------------------------------------
// Extra work to identify melee weapon, & save/load ammo details
// --------------------------------------
void ReEquipSlot1(int client, int iSlot1)
{
	char className[64];
	char modelName[64];
	
	char sWeapon[64]; 	sWeapon[0] = '\0'  ;
	int Ammo = -1;
	int iSlot = -1;
	
	GetEdictClassname(iSlot1, className, sizeof(className));
	
	// Try to find weapon name without models
	if 		(!strcmp(className, "weapon_melee", true))   GetEntPropString(iSlot1, Prop_Data, "m_strMapSetScriptName", sWeapon, 64);
	else if (strcmp(className, "weapon_pistol", true))   GetEdictClassname(iSlot1, sWeapon, 64);
	
	// IF model checking is required
	if (sWeapon[0] == '\0')
	{
		GetEntPropString(iSlot1, Prop_Data, "m_ModelName", modelName, sizeof(modelName));

		if 		(StrContains(modelName, "v_pistolA.mdl",         true) != -1)	sWeapon = "weapon_pistol";
		else if (StrContains(modelName, "v_dual_pistolA.mdl",    true) != -1)	sWeapon = "dual_pistol";
		else if (StrContains(modelName, "v_desert_eagle.mdl",    true) != -1)	sWeapon = "weapon_pistol_magnum";
		else if (StrContains(modelName, "v_bat.mdl",             true) != -1)	sWeapon = "baseball_bat";
		else if (StrContains(modelName, "v_cricket_bat.mdl",     true) != -1)	sWeapon = "cricket_bat";
		else if (StrContains(modelName, "v_crowbar.mdl",         true) != -1)	sWeapon = "crowbar";
		else if (StrContains(modelName, "v_fireaxe.mdl",         true) != -1)	sWeapon = "fireaxe";
		else if (StrContains(modelName, "v_katana.mdl",          true) != -1)	sWeapon = "katana";
		else if (StrContains(modelName, "v_golfclub.mdl",        true) != -1)	sWeapon = "golfclub";
		else if (StrContains(modelName, "v_machete.mdl",         true) != -1)	sWeapon = "machete";
		else if (StrContains(modelName, "v_tonfa.mdl",           true) != -1)	sWeapon = "tonfa";
		else if (StrContains(modelName, "v_electric_guitar.mdl", true) != -1)	sWeapon = "electric_guitar";
		else if (StrContains(modelName, "v_frying_pan.mdl",      true) != -1)	sWeapon = "frying_pan";
		else if (StrContains(modelName, "v_knife_t.mdl",         true) != -1)	sWeapon = "knife";
		else if (StrContains(modelName, "v_chainsaw.mdl",        true) != -1)	sWeapon = "weapon_chainsaw";
		else if (StrContains(modelName, "v_riotshield.mdl",      true) != -1)	sWeapon = "alliance_shield";
		else if (StrContains(modelName, "v_fubar.mdl",           true) != -1)	sWeapon = "fubar";
		else if (StrContains(modelName, "v_paintrain.mdl",       true) != -1)	sWeapon = "nail_board";
		else if (StrContains(modelName, "v_sledgehammer.mdl",    true) != -1)	sWeapon = "sledgehammer";
	}

	// IF Weapon properly identified, save then delete then reequip
	if (sWeapon[0] != '\0')
	{
		// IF Weapon uses ammo, save it
		if (!strcmp(sWeapon, "dual_pistol", true)   || !strcmp(sWeapon, "weapon_pistol", true)
		|| !strcmp(sWeapon, "weapon_pistol_magnum", true) || !strcmp(sWeapon, "weapon_chainsaw", true))
		{
			Ammo = GetEntProp(iSlot1, Prop_Send, "m_iClip1", 4);
		}	
	
		DeletePlayerSlot(client, iSlot1);
		
		// Reequip weapon (special code for dual pistols)
		if (!strcmp(sWeapon, "dual_pistol", true))
		{
			 CheatCommand(client, "give", "weapon_pistol", "");
			 CheatCommand(client, "give", "weapon_pistol", "");
		}
		else CheatCommand(client, "give", sWeapon, "");
		
		// Restore ammo
		if (Ammo >= 0)
		{
			iSlot = GetPlayerWeaponSlot(client, 1);
			if (iSlot > 0) SetEntProp(iSlot, Prop_Send, "m_iClip1", Ammo, 4);
		}
	}
}

void DeletePlayerSlot(int client, int weapon)
{		
	if(RemovePlayerItem(client, weapon)) AcceptEntityInput(weapon, "Kill");
}

void CheatCommand(int client, const char[] command, const char[] argument1, const char[] argument2)
{
	int userFlags = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	int flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s %s", command, argument1, argument2);
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, userFlags);
}

// *********************************************************************************
// Get/Set ammo
// *********************************************************************************

int GetClientAmmo(int client, char[] weapon)
{
	int weapon_offset = GetWeaponOffset(weapon);
	int iAmmoOffset = FindSendPropInfo("CTerrorPlayer", "m_iAmmo");
	
	return weapon_offset > 0 ? GetEntData(client, iAmmoOffset+weapon_offset) : 0;
}

void SetClientAmmo(int client, char[] weapon, int count)
{
	int weapon_offset = GetWeaponOffset(weapon);
	int iAmmoOffset = FindSendPropInfo("CTerrorPlayer", "m_iAmmo");
	
	if (weapon_offset > 0) SetEntData(client, iAmmoOffset+weapon_offset, count);
}

int GetWeaponOffset(char[] weapon)
{
	int weapon_offset;

	if (StrEqual(weapon, "weapon_rifle") || StrEqual(weapon, "weapon_rifle_sg552") || StrEqual(weapon, "weapon_rifle_desert") || StrEqual(weapon, "weapon_rifle_ak47"))
	{
		weapon_offset = 12;
	}
	else if (StrEqual(weapon, "weapon_rifle_m60"))
	{
		weapon_offset = 24;
	}
	else if (StrEqual(weapon, "weapon_smg") || StrEqual(weapon, "weapon_smg_silenced") || StrEqual(weapon, "weapon_smg_mp5"))
	{
		weapon_offset = 20;
	}
	else if (StrEqual(weapon, "weapon_pumpshotgun") || StrEqual(weapon, "weapon_shotgun_chrome"))
	{
		weapon_offset = 28;
	}
	else if (StrEqual(weapon, "weapon_autoshotgun") || StrEqual(weapon, "weapon_shotgun_spas"))
	{
		weapon_offset = 32;
	}
	else if (StrEqual(weapon, "weapon_hunting_rifle"))
	{
		weapon_offset = 36;
	}
	else if (StrEqual(weapon, "weapon_sniper_scout") || StrEqual(weapon, "weapon_sniper_military") || StrEqual(weapon, "weapon_sniper_awp"))
	{
		weapon_offset = 40;
	}
	else if (StrEqual(weapon, "weapon_grenade_launcher"))
	{
		weapon_offset = 68;
	}

	return weapon_offset;
}