#pragma semicolon 1

#include <sourcemod>
#include <tf2>
#include <tf2_stocks>

#define PLUGIN_VERSION	"1.0.0"

#define MAX_WEAPON_ID	1200 // As of 7/28/15 the highest weapon ID is 1153
#define SetBit(%1,%2)      (%1[%2>>5] |= (1<<(%2 & 31)))		// Thank you to Bugsy for this bitwise operation code!
#define ClearBit(%1,%2)    (%1[%2>>5] &= ~(1<<(%2 & 31)))		// https://forums.alliedmods.net/showthread.php?t=139916
#define CheckBit(%1,%2)    (%1[%2>>5] & (1<<(%2 & 31)))  		//

public Plugin:myinfo = 
{
	name = "SelectiveCrits",
	author = "GooseMonkey",
	description = "Only allows selected weapons to randomly crit. Only Melees by default.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=238668"
}




/////////////////
// Declaration //
/////////////////

// Handles
new Handle:hConfig;
new Handle:hConfigOverrides;
// Cvars
new Handle:g_tf_weapon_criticals;
new Handle:g_qp;
new Handle:g_qpreset;


// Internal
new g_Weapons[( MAX_WEAPON_ID / 32 ) + 1]; // Also from Bugsy.
new bool:UndefinedCrits;
// new bool:UsingOverrides = false;


// ID passed should have already been fixed
bool:getDoesWeaponCrit(id)
{
	if (id == 142) // Special case: Gunslinger, doesn't random crit and disabling crits breaks the 3-hit combo. So, just always "allow" it to crit
		return true;
		
	if (id > MAX_WEAPON_ID)
	{
		PrintToServer("[SC] Error! Weapon ID %i is greater than the maximum possible weapon ID. Nag the developer or SelectiveCrits! Error ID: 1200", id);
		return UndefinedCrits;
	}
	
	if (CheckBit(g_Weapons, id))
		return true;
	else
		return false;
}




///////////////////
// Configuration //
///////////////////

public OnPluginStart()
{
	CreateConVar("selectivecrits_version", PLUGIN_VERSION, "SelectiveCrits Plugin Version", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);
	// AddServerTag("selectivecrits"); // Apparently doesn't do anything
	
	RegConsoleCmd("sm_sccheck", Command_sc, "Checks if a weapon will get random crits"); // Debug Command
	RegAdminCmd("sm_screload", Command_reload, ADMFLAG_SLAY, "Reloads the SelectiveCrits Configuration");

	g_tf_weapon_criticals = FindConVar("tf_weapon_criticals");
	
	g_qp = FindConVar("tf_server_identity_disable_quickplay");
	g_qpreset = CreateConVar("sm_sc_resetquickplay", "0", "Sets whether setting tf_weapon_criticals to 1 or 0 will re-add the server to quickplay automatically", FCVAR_PROTECTED);

	HookConVarChange(g_tf_weapon_criticals, OnCriticalsCvarChange);
	
	if (GetConVarInt(g_tf_weapon_criticals) >= 2)
	{
		ParseConfig(GetConVarInt(g_tf_weapon_criticals));
	}
}

public OnCriticalsCvarChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	new iVal = StringToInt(newVal);
	new iOldVal = StringToInt(oldVal);
	
	if (iVal < 0)
	{
		PrintToServer("[SC] Cvar tf_weapon_criticals has not been changed from %s.", oldVal);
		SetConVarString(g_tf_weapon_criticals, oldVal);
	}

	if (iVal < 2 && iVal >= 0 && (iOldVal >= 2 || iOldVal < 0)) // SC is being turned from on to off
	{
		if (GetConVarBool(g_qpreset))
		{
			PrintToServer("[SC] Server has been re-added to quickplay!");
			SetConVarBool(g_qp, false, false, true);
		}
		else
		{
			PrintToServer("[SC] Server is still out of the quickplay pool. Set tf_server_identity_disable_quickplay = 0 to make this server eligible for matchmaking.");
		}
	}

	if (iVal >= 0 && iVal < 2)
	{
		PrintToServer("[SC] SelectiveCrits is disabled.");
		return;
	}

	if (!ParseConfig(iVal))
	{
		PrintToServer("[SC] Cvar tf_weapon_criticals has not been changed from %s.", oldVal);
		SetConVarString(g_tf_weapon_criticals, oldVal);
	}
	else
	{
		SetConVarBool(g_qp, true, false, true);
		PrintToServer("[SC] Server has been removed from quickplay!");
	}
}

bool:ParseConfig(key) // Returns whether the configuration ID is valid
{
	new String:keyS[5];
	IntToString(key, keyS, 4);

	PrintToServer("[SC] Loading SelectiveCrits Configuration for tf_weapon_criticals = %i....", key);

	new String:strPath[192];
	BuildPath(Path_SM, strPath, sizeof(strPath), "configs/selectivecrits.cfg");
	
	if(!FileExists(strPath))
	{
		PrintToServer("[SC] Missing or corrupt configs/selectivecrits.cfg!");
		return false;
	}
	
	hConfig = CreateKeyValues("SelectiveCritsConfigv1");
	FileToKeyValues(hConfig, strPath);

	new String:weaponsSect[10] = "Weapons";
	StrCat(weaponsSect, 9, keyS);

	if (!KvJumpToKey(hConfig, weaponsSect))
	{
		PrintToServer("[SC] Missing config section \"%s\" from configs/selectivecrits.cfg!", weaponsSect);
		return false;
	}

	UndefinedCrits = bool:KvGetNum(hConfig, "Default");

	new handled = 0;

	for (new i = 1; i < MAX_WEAPON_ID; i++)
	{
		new String:iString[6];
		IntToString(i, iString, 6);
		new result = KvGetNum(hConfig, iString, -1);
		
		if (result == 0)
		{
			ClearBit(g_Weapons, i);
			handled++;
		}
		else if (result == 1)
		{
			SetBit(g_Weapons, i);
			handled++;
		}
		else // Config value does not exist
		{
			if (UndefinedCrits)
			{
				SetBit(g_Weapons, i);
			}
			else
			{
				ClearBit(g_Weapons, i);
			}
		}

		// PrintToServer("Handled ID %i, result %i", i, result);
	}
	
	// Handle the Nostromo Napalmer.
	{
		new nnResult = KvGetNum(hConfig, "30474", -1);
		if (nnResult == 0)
		{
			ClearBit(g_Weapons, 700);
			handled++;
		}
		else if (nnResult == 1)
		{
			SetBit(g_Weapons, 700);
			handled++;
		}
		else // Config value does not exist
		{
			if (UndefinedCrits)
			{
				SetBit(g_Weapons, 700);
			}
			else
			{
				ClearBit(g_Weapons, 700);
			}
		}
	}
	// End Nostromo Napalmer

	PrintToServer("[SC] SelectiveCrits: %i weapons loaded from \"Weapons%i\" in selectivecrits.cfg.", handled, key);

	CloseHandle(hConfig);
	
	
	
	// Overrides - To be added
	new String:strPathOverrides[192];
	BuildPath(Path_SM, strPath, sizeof(strPath), "configs/selectivecrits-mapping-override.cfg");
	if(!FileExists(strPath))
	{
		PrintToServer("[SC] Using inbuilt weapon remapping. You're good to go!");
		return true;
	}

	PrintToServer("[SC] Using custom weapon remapping.");
	hConfigOverrides = CreateKeyValues("SelectiveCritsMappingOverridev1");
	FileToKeyValues(hConfigOverrides, strPathOverrides);



	return true;	
}




//////////////
// Commands //
//////////////

public Action:Command_sc(client, args)
{
	if (args < 1 && !client)
		return Plugin_Handled;
	
	new id;
	
	if (args == 0)
	{
		new weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		id = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
	}
	else
	{
		new String:arg[128];
		GetCmdArg(1, arg, 127);

		id = StringToInt(arg);
	}
	
	new fixedId = fixIndices(id);
	
	new String:mappedTo[24];
	
	if (fixedId != id)
	{
		Format(mappedTo, 24, " (mapped from %i)", id);
	}
	
	if (!client)
	{
		if (getDoesWeaponCrit(fixedId))
			PrintToServer("[SC] Weapon %i%s DOES roll for random crits.", fixedId, mappedTo);
		else
			PrintToServer("[SC] Weapon %i%s DOES NOT roll for random crits.", fixedId, mappedTo);
	}
	else
	{
		if (getDoesWeaponCrit(fixedId))
			PrintToConsole(client, "[SC] Weapon %i%s DOES roll for random crits.", fixedId, mappedTo);
		else
			PrintToConsole(client, "[SC] Weapon %i%s DOES NOT roll for random crits.", fixedId, mappedTo);
	}
	
	return Plugin_Handled;
}

public Action:Command_reload(client, args)
{
	new set = GetConVarInt(g_tf_weapon_criticals);

	if (!(set >= 2))
	{
		PrintToConsole(client, "[SC] SelectiveCrits isn't enabled. Set tf_weapon_criticals to 2 or higher.");
		return;
	}

	ParseConfig(set);
}




///////////////
// Listeners //
///////////////

public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
	if (GetConVarInt(g_tf_weapon_criticals) < 2)
	{
		return Plugin_Continue;
	}

	new index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");

	// Allow the crit if the player is Crit Boosted
	if (TF2_IsPlayerInCondition(client, TFCond_CritCanteen) || TF2_IsPlayerInCondition(client, TFCond_CritMmmph) || TF2_IsPlayerInCondition(client, TFCond_CritOnKill) || TF2_IsPlayerInCondition(client, TFCond_CritOnWin) ||
		TF2_IsPlayerInCondition(client, TFCond_CritOnFirstBlood) || TF2_IsPlayerInCondition(client, TFCond_HalloweenCritCandy) || TF2_IsPlayerInCondition(client, TFCond_CritOnFlagCapture) ||
		TF2_IsPlayerInCondition(client, TFCond_Kritzkrieged) || TF2_IsPlayerInCondition(client, TFCond_CritDemoCharge) || TF2_IsPlayerInCondition(client, TFCond_CritOnDamage))
		return Plugin_Continue;

	index = fixIndices(index);

	if (getDoesWeaponCrit(index))
	{
		return Plugin_Continue;
	}
	else
	{
		result = false;

		return Plugin_Handled;
	}
}

fixIndices(int index)
{
	// TODO: Customizable fixIndices
	
	// Fix shotgun and pistol mirrors
	if (index >= 9 && index <= 12)
		index = 9;
	
	if (index == 23)
		index = 22;
	
	// Fix the Renamed/Strange mirrors
	if (index >= 190 && index <= 199)
		index = index - 190;
	
	if (index >= 200 && index <= 209)
		index = index - 187;
	
	if (index == 210)
		index = 24;
	
	if (index >= 211 && index <= 212)
		index = index - 182;
	
	// Fix Botkiller, Festive mirrors
	if (index == 792 || index == 801 || index == 881 || index == 890 || index == 899 || index == 908 || index == 957 || index == 966 || index == 664) // Sniper Rifles
		index = 14;

	if (index == 793 || index == 802 || index == 882 || index == 891 || index == 900 || index == 909 || index == 958 || index == 967 || index == 654) // Miniguns
		index = 15;
		
	if (index == 794 || index == 803 || index == 883 || index == 892 || index == 901 || index == 910 || index == 959 || index == 968 || index == 665) // Knives
		index = 4;
		
	if (index == 795 || index == 804 || index == 884 || index == 893 || index == 902 || index == 911 || index == 960 || index == 969 || index == 662) // Wrenches
		index = 7;
	
	if (index == 796 || index == 805 || index == 885 || index == 894 || index == 903 || index == 912 || index == 961 || index == 970 || index == 663) // Mediguns
		index = 29;
	
	if (index == 797 || index == 806 || index == 886 || index == 895 || index == 904 || index == 913 || index == 962 || index == 971 || index == 661) // Sticky Launchers
		index = 20;
	
	if (index == 798 || index == 807 || index == 887 || index == 896 || index == 905 || index == 914 || index == 963 || index == 972 || index == 659) // Flamethrowers
		index = 21;
	
	if (index == 799 || index == 808 || index == 888 || index == 897 || index == 906 || index == 915 || index == 964 || index == 973 || index == 669) // Scatterguns
		index = 13;
	
	if (index == 800 || index == 809 || index == 889 || index == 898 || index == 907 || index == 916 || index == 965 || index == 974 || index == 658) // Rocket Launchers
		index = 18;
	
	if (index == 660) // F. Bat
		index = 0;
		
	// 2012
	if (index == 999) // F. Mackerel
		index = 221;
	
	if (index == 1000) // F. Axtinguisher
		index = 38;
	
	if (index == 1001) // F. Buff Banner
		index = 129;
	
	if (index == 1002) // F. Sandvich
		index = 42;
	
	if (index == 1003) // F. Ubersaw
		index = 37;
	
	if (index == 1004) // F. Frontier Justice
		index = 141;
	
	if (index == 1005) // F. Huntsman
		index = 56;
	
	if (index == 1006) // F. Ambassador
		index = 61;
	
	if (index == 1007) // F. Grenade Launcher
		index = 19;
	
	// 2013
	if (index == 1078) // F. FaN
		index = 45;
	
	if (index == 1079) // F. Crusader's Crossbow
		index = 305;
	
	if (index == 1080) // F. Sapper
		index = 735;
	
	if (index == 1081) // F. Flare Gun
		index = 39;
	
	if (index == 1082) // F. Eyelander
		index = 132;
	
	if (index == 1083) // F. Jarate
		index = 58;
	
	if (index == 1084) // F. GRU
		index = 239;
	
	if (index == 1085) // F. Black Box
		index = 228;
	
	if (index == 1086) // F. Wrangler
		index = 140;
	
	// 2014
	if (index == 1141) // F. Shotgun
		index = 9;
	
	if (index == 1142) // F. Revolver
		index = 24;
		
	if (index == 1143) // F. Bonesaw
		index = 8;
	
	if (index == 1144) // F. Targe
		index = 131;
		
	if (index == 1145) // F. Bonk
		index = 46;
	
	if (index == 1146) // F. Backburner
		index = 40;
	
	if (index == 1149) // F. SMG
		index = 16;
	
	// Fix GunMettle Skinned weapons
	if (index == 15003 || index == 15016 || index == 15044 || index == 15047) // All shotguns
		index = 9;
	
	if (index == 15013 || index == 15018 || index == 15035 || index == 15041 || index == 15046 || index == 15056) // All pistols
		index = 22;
		
	if (index == 15000 || index == 15007 || index == 15019 || index == 15023 || index == 15033 || index == 15059) // All sniper rifles
		index = 14;

	if (index == 15001 || index == 15022 || index == 15032 || index == 15037 || index == 15058) // All SMGs
		index = 16;

	if (index == 15002 || index == 15015 || index == 15021 || index == 15029 || index == 15036 || index == 15053) // All Scatterguns
		index = 13;
		
	if (index == 15004 || index == 15020 || index == 15026 || index == 15031 || index == 15040 || index == 15055) // All Miniguns
		index = 15;
		
	if (index == 15006 || index == 15014 || index == 15028 || index == 15043 || index == 15052 || index == 15057) // All Rocket Launchers
		index = 18;
		
	if (index == 15008 || index == 15010 || index == 15025 || index == 15039 || index == 15050) // All Mediguns
		index = 29;
		
	if (index == 15005 || index == 15017 || index == 15030 || index == 15034 || index == 15049 || index == 15054) // All Flamethrowers
		index = 21;
		
	if (index == 15009 || index == 15012 || index == 15024 || index == 15038 || index == 15045 || index == 15048) // All Sticky Launchers
		index = 20;
		
	if (index == 15011 || index == 15027 || index == 15042 || index == 15051) // All Revolvers
		index = 24;
		
	// Special Cases: "Valve IDs" - because it was a good idea to jump up 30,000 IDs for a single weapon.
	if (index == 30474) // Nostromo Napalmer
		index = 700;

	return index;
}