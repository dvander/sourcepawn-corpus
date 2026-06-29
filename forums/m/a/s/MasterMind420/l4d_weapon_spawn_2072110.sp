#define PLUGIN_VERSION 		"1.1"

/*=======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] Weapon Spawn
*	Author	:	SilverShot
*	Descrp	:	Spawns a single weapon fixed in position, these can be temporary or saved for auto-spawning.
*	Link	:	http://forums.alliedmods.net/showthread.php?t=222934

========================================================================================
	Change Log:

1.1 (18-Aug-2013)
	- Added cvar "l4d_weapon_spawn_count" to set how many times a spawner gives items/weapons before disappearing.
	- Added cvar "l4d_weapon_spawn_randomise" cvar to randomise the spawns based on a chance out of 100.

1.0 (09-Aug-2013)
	- Initial release.

========================================================================================
	Thanks:

	This plugin was made using source code from the following plugins.
	If I have used your code and not credited you, please let me know.

*	"Zuko & McFlurry" for "[L4D2] Weapon/Zombie Spawner" - Modified SetTeleportEndPoint function.
	http://forums.alliedmods.net/showthread.php?t=109659

*	Thanks to "Boikinov" for "[L4D] Left FORT Dead builder" - RotateYaw function to rotate ground flares
	http://forums.alliedmods.net/showthread.php?t=93716

======================================================================================*/

#pragma semicolon 			1

#include <sourcemod>
#include <sdktools>

#define CVAR_FLAGS			FCVAR_PLUGIN|FCVAR_NOTIFY
#define CHAT_TAG			"\x04[\x05Weapon Spawn\x04] \x01"
#define CONFIG_SPAWNS		"data/l4d_spawn_weapon.cfg"
#define MAX_SPAWNS			32
#define	MAX_WEAPONS			5
#define	MAX_WEAPONS2		15

static	Handle:g_hCvarMPGameMode, Handle:g_hCvarModes, Handle:g_hCvarModesOff, Handle:g_hCvarModesTog, Handle:g_hCvarAllow,
		Handle:g_hCvarCount, Handle:g_hCvarRandom, Handle:g_hCvarRandomise, g_iCvarCount, g_iCvarRandom, g_iCvarRandomise,
		Handle:g_hMenuList, Handle:g_hMenuAng, Handle:g_hMenuPos, bool:g_bLeft4Dead2, bool:g_bLoaded, bool:g_bCvarAllow,
		g_iPlayerSpawn, g_iRoundStart, g_iSpawnCount, g_iSpawns[MAX_SPAWNS][2], g_iSave[MAXPLAYERS+1];

static	Handle:g_hAmmoGL, Handle:g_hAmmoRifle, Handle:g_hAmmoShotgun, Handle:g_hAmmoSmg, Handle:g_hAmmoChainsaw,
		Handle:g_hAmmoAutoShot, Handle:g_hAmmoM60, Handle:g_hAmmoSniper, Handle:g_hAmmoHunting,
		g_iAmmoGL, g_iAmmoRifle, g_iAmmoShotgun, g_iAmmoSmg, g_iAmmoChainsaw, g_iAmmoAutoShot, g_iAmmoM60, g_iAmmoSniper, g_iAmmoHunting;

static String:g_sWeaponNames[MAX_WEAPONS][] =
{
	"Rifle",
	"Auto Shotgun",
	"Hunting Rifle",
	"SMG",
	"Pump Shotgun",
	//"Pistol",
	//"Molotov",
	//"Pipe Bomb",
	//"First Aid Kit",
	//"Pain Pills"
};
static String:g_sWeapons[MAX_WEAPONS][] =
{
	"weapon_rifle",
	"weapon_autoshotgun",
	"weapon_hunting_rifle",
	"weapon_smg",
	"weapon_pumpshotgun",
	//"weapon_pistol",
	//"weapon_molotov",
	//"weapon_pipe_bomb",
	//"weapon_first_aid_kit",
	//"weapon_pain_pills"
};
static String:g_sWeaponModels[MAX_WEAPONS][] =
{
	"models/w_models/weapons/w_rifle_m16a2.mdl",
	"models/w_models/weapons/w_autoshot_m4super.mdl",
	"models/w_models/weapons/w_sniper_mini14.mdl",
	"models/w_models/weapons/w_smg_uzi.mdl",
	"models/w_models/weapons/w_pumpshotgun_A.mdl",
	//"models/w_models/weapons/w_pistol_a.mdl",
	//"models/w_models/weapons/w_eq_molotov.mdl",
	//"models/w_models/weapons/w_eq_pipebomb.mdl",
	//"models/w_models/weapons/w_eq_medkit.mdl",
	//"models/w_models/weapons/w_eq_painpills.mdl"
};
static String:g_sWeaponNames2[MAX_WEAPONS2][] =
{
	"Rifle",
	"Auto Shotgun",
	"Hunting Rifle",
	"SMG",
	"Pump Shotgun",
	//"Pistol",
	//"Molotov",
	//"Pipe Bomb",
	//"First Aid Kit",
	//"Pain Pills",

	"Shotgun Chrome",
	"Rifle Desert",
	//"Grenade Launcher",
	//"M60",
	"AK47",
	"SG552",
	"Shotgun Spas",
	"SMG Silenced",
	"SMG MP5",
	"Sniper AWP",
	"Sniper Military",
	"Sniper Scout",
	//"Chainsaw",
	//"Pistol Magnum",
	//"VomitJar",
	//"Defibrillator",
	//"Upgradepack Explosive",
	//"Upgradepack Incendiary",
	//"Adrenaline"
};
static String:g_sWeapons2[MAX_WEAPONS2][] =
{
	"weapon_rifle",
	"weapon_autoshotgun",
	"weapon_hunting_rifle",
	"weapon_smg",
	"weapon_pumpshotgun",
	//"weapon_pistol",
	//"weapon_molotov",
	//"weapon_pipe_bomb",
	//"weapon_first_aid_kit",
	//"weapon_pain_pills",

	"weapon_shotgun_chrome",
	"weapon_rifle_desert",
	//"weapon_grenade_launcher",
	//"weapon_rifle_m60",
	"weapon_rifle_ak47",
	"weapon_rifle_sg552",
	"weapon_shotgun_spas",
	"weapon_smg_silenced",
	"weapon_smg_mp5",
	"weapon_sniper_awp",
	"weapon_sniper_military",
	"weapon_sniper_scout",
	//"weapon_chainsaw",
	//"weapon_pistol_magnum",
	//"weapon_vomitjar",
	//"weapon_defibrillator",
	//"weapon_upgradepack_explosive",
	//"weapon_upgradepack_incendiary",
	//"weapon_adrenaline"
};
static String:g_sWeaponModels2[MAX_WEAPONS2][] =
{
	"models/w_models/weapons/w_rifle_m16a2.mdl",
	"models/w_models/weapons/w_autoshot_m4super.mdl",
	"models/w_models/weapons/w_sniper_mini14.mdl",
	"models/w_models/weapons/w_smg_uzi.mdl",
	"models/w_models/weapons/w_pumpshotgun_A.mdl",
	//"models/w_models/weapons/w_pistol_a.mdl",
	//"models/w_models/weapons/w_eq_molotov.mdl",
	//"models/w_models/weapons/w_eq_pipebomb.mdl",
	//"models/w_models/weapons/w_eq_medkit.mdl",
	//"models/w_models/weapons/w_eq_painpills.mdl",

	"models/w_models/weapons/w_shotgun.mdl",
	"models/w_models/weapons/w_desert_rifle.mdl",
	//"models/w_models/weapons/w_grenade_launcher.mdl",
	//"models/w_models/weapons/w_m60.mdl",
	"models/w_models/weapons/w_rifle_ak47.mdl",
	"models/w_models/weapons/w_rifle_sg552.mdl",
	"models/w_models/weapons/w_shotgun_spas.mdl",
	"models/w_models/weapons/w_smg_a.mdl",
	"models/w_models/weapons/w_smg_mp5.mdl",
	"models/w_models/weapons/w_sniper_awp.mdl",
	"models/w_models/weapons/w_sniper_military.mdl",
	"models/w_models/weapons/w_sniper_scout.mdl",
	//"models/weapons/melee/w_chainsaw.mdl",
	//"models/w_models/weapons/w_desert_eagle.mdl",
	//"models/w_models/weapons/w_eq_bile_flask.mdl",
	//"models/w_models/weapons/w_eq_defibrillator.mdl",
	//"models/w_models/weapons/w_eq_explosive_ammopack.mdl",
	//"models/w_models/weapons/w_eq_incendiary_ammopack.mdl",
	//"models/w_models/weapons/w_eq_adrenaline.mdl"
};



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin:myinfo =
{
	name = "[L4D & L4D2] Weapon Spawn",
	author = "SilverShot",
	description = "Spawns a weapon in a weapon crate/locker, these can be temporary or saved for auto-spawning.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=222934"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	decl String:sGameName[12];
	GetGameFolderName(sGameName, sizeof(sGameName));
	if( strcmp(sGameName, "left4dead", false) == 0 ) g_bLeft4Dead2 = false;
	else if( strcmp(sGameName, "left4dead2", false) == 0 ) g_bLeft4Dead2 = true;
	else
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public OnPluginStart()
{
	g_hCvarAllow =		CreateConVar(	"l4d_weapon_spawn_allow",			"1",			"0=Plugin off, 1=Plugin on.", CVAR_FLAGS );
	g_hCvarModes =		CreateConVar(	"l4d_weapon_spawn_modes",			"",				"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff =	CreateConVar(	"l4d_weapon_spawn_modes_off",		"",				"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog =	CreateConVar(	"l4d_weapon_spawn_modes_tog",		"0",			"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	g_hCvarCount =		CreateConVar(	"l4d_weapon_spawn_count",			"1",			"0=Infinite. How many items/weapons to give from 1 spawner.", CVAR_FLAGS );
	g_hCvarRandom =		CreateConVar(	"l4d_weapon_spawn_random",			"-1",			"-1=All, 0=None. Otherwise randomly select this many weapons to spawn from the maps config.", CVAR_FLAGS );
	g_hCvarRandomise =	CreateConVar(	"l4d_weapon_spawn_randomise",		"25",			"0=Off. Chance out of 100 to randomise the type of item/weapon regardless of what it's set to.", CVAR_FLAGS );
	CreateConVar(						"l4d_weapon_spawn_version",			PLUGIN_VERSION, "Weapon Spawn plugin version.", CVAR_FLAGS|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	AutoExecConfig(true,				"l4d_weapon_spawn");

	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	HookConVarChange(g_hCvarMPGameMode,		ConVarChanged_Allow);
	HookConVarChange(g_hCvarAllow,			ConVarChanged_Allow);
	HookConVarChange(g_hCvarModes,			ConVarChanged_Allow);
	HookConVarChange(g_hCvarModesOff,		ConVarChanged_Allow);
	HookConVarChange(g_hCvarModesTog,		ConVarChanged_Allow);
	HookConVarChange(g_hCvarCount,			ConVarChanged_Cvars);
	HookConVarChange(g_hCvarRandom,			ConVarChanged_Cvars);
	HookConVarChange(g_hCvarRandomise,		ConVarChanged_Cvars);


	g_hAmmoRifle =			FindConVar("ammo_assaultrifle_max");
	g_hAmmoShotgun =		FindConVar("ammo_shotgun_max");
	g_hAmmoSmg =			FindConVar("ammo_smg_max");
	g_hAmmoHunting =		FindConVar("ammo_huntingrifle_max");

	HookConVarChange(g_hAmmoRifle,		ConVarChanged_Cvars);
	HookConVarChange(g_hAmmoShotgun,	ConVarChanged_Cvars);
	HookConVarChange(g_hAmmoSmg,		ConVarChanged_Cvars);
	HookConVarChange(g_hAmmoHunting,	ConVarChanged_Cvars);

	if( g_bLeft4Dead2 )
	{
		g_hAmmoGL =			FindConVar("ammo_grenadelauncher_max");
		g_hAmmoChainsaw =	FindConVar("ammo_chainsaw_max");
		g_hAmmoAutoShot =	FindConVar("ammo_autoshotgun_max");
		g_hAmmoM60 =		FindConVar("ammo_m60_max");
		g_hAmmoSniper =		FindConVar("ammo_sniperrifle_max");

		HookConVarChange(g_hAmmoGL,				ConVarChanged_Cvars);
		HookConVarChange(g_hAmmoChainsaw,		ConVarChanged_Cvars);
		HookConVarChange(g_hAmmoAutoShot,		ConVarChanged_Cvars);
		HookConVarChange(g_hAmmoM60,			ConVarChanged_Cvars);
		HookConVarChange(g_hAmmoSniper,			ConVarChanged_Cvars);
	}

	RegAdminCmd("sm_weapon_spawn",			CmdSpawnerTemp,		ADMFLAG_ROOT, 	"Opens a menu of weapons/items to spawn. Spawns a temporary weapon at your crosshair.");
	RegAdminCmd("sm_weapon_spawn_save",		CmdSpawnerSave,		ADMFLAG_ROOT, 	"Opens a menu of weapons/items to spawn. Spawns a weapon at your crosshair and saves to config.");
	RegAdminCmd("sm_weapon_spawn_del",		CmdSpawnerDel,		ADMFLAG_ROOT, 	"Removes the weapon you are pointing at and deletes from the config if saved.");
	RegAdminCmd("sm_weapon_spawn_clear",	CmdSpawnerClear,	ADMFLAG_ROOT, 	"Removes all weapons spawned by this plugin from the current map.");
	RegAdminCmd("sm_weapon_spawn_wipe",		CmdSpawnerWipe,		ADMFLAG_ROOT, 	"Removes all weapons spawned by this plugin from the current map and deletes them from the config.");
	RegAdminCmd("sm_weapon_spawn_glow",		CmdSpawnerGlow,		ADMFLAG_ROOT, 	"Toggle to enable glow on all weapons to see where they are placed.");
	RegAdminCmd("sm_weapon_spawn_list",		CmdSpawnerList,		ADMFLAG_ROOT, 	"Display a list weapon positions and the total number of.");
	RegAdminCmd("sm_weapon_spawn_tele",		CmdSpawnerTele,		ADMFLAG_ROOT, 	"Teleport to a weapon (Usage: sm_weapon_spawn_tele <index: 1 to MAX_SPAWNS (32)>).");
	RegAdminCmd("sm_weapon_spawn_ang",		CmdSpawnerAng,		ADMFLAG_ROOT, 	"Displays a menu to adjust the weapon angles your crosshair is over.");
	RegAdminCmd("sm_weapon_spawn_pos",		CmdSpawnerPos,		ADMFLAG_ROOT, 	"Displays a menu to adjust the weapon origin your crosshair is over.");



	g_hMenuList = CreateMenu(ListMenuHandler);
	new max = MAX_WEAPONS;
	if( g_bLeft4Dead2 ) max = MAX_WEAPONS2;
	for( new i = 0; i < max; i++ )
	{
		if( g_bLeft4Dead2 )
			AddMenuItem(g_hMenuList, "", g_sWeaponNames2[i]);
		else
			AddMenuItem(g_hMenuList, "", g_sWeaponNames[i]);
	}
	SetMenuTitle(g_hMenuList, "Spawn Weapon");
	SetMenuExitBackButton(g_hMenuList, true);
}

public OnPluginEnd()
{
	ResetPlugin();
}

public OnMapStart()
{
	new max = MAX_WEAPONS;
	if( g_bLeft4Dead2 ) max = MAX_WEAPONS2;
	for( new i = 0; i < max; i++ )
	{
		if( g_bLeft4Dead2 )
			PrecacheModel(g_sWeaponModels2[i], true);
		else
			PrecacheModel(g_sWeaponModels[i], true);
	}
}

public OnMapEnd()
{
	ResetPlugin(false);
}



// ====================================================================================================
//					CVARS
// ====================================================================================================
public OnConfigsExecuted()
	IsAllowed();

public ConVarChanged_Cvars(Handle:convar, const String:oldValue[], const String:newValue[])
	GetCvars();

public ConVarChanged_Allow(Handle:convar, const String:oldValue[], const String:newValue[])
	IsAllowed();

GetCvars()
{
	g_iCvarCount = GetConVarInt(g_hCvarCount);
	g_iCvarRandom = GetConVarInt(g_hCvarRandom);
	g_iCvarRandomise = GetConVarInt(g_hCvarRandomise);

	g_iAmmoRifle		= GetConVarInt(g_hAmmoRifle);
	g_iAmmoShotgun		= GetConVarInt(g_hAmmoShotgun);
	g_iAmmoSmg			= GetConVarInt(g_hAmmoSmg);
	g_iAmmoHunting		= GetConVarInt(g_hAmmoHunting);

	if( g_bLeft4Dead2 )
	{
		g_iAmmoGL			= GetConVarInt(g_hAmmoGL);
		g_iAmmoChainsaw		= GetConVarInt(g_hAmmoChainsaw);
		g_iAmmoAutoShot		= GetConVarInt(g_hAmmoAutoShot);
		g_iAmmoM60			= GetConVarInt(g_hAmmoM60);
		g_iAmmoSniper		= GetConVarInt(g_hAmmoSniper);
	}
}

IsAllowed()
{
	new bool:bCvarAllow = GetConVarBool(g_hCvarAllow);
	new bool:bAllowMode = IsAllowedGameMode();
	GetCvars();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		LoadSpawns();
		g_bCvarAllow = true;
		HookEvent("player_spawn",		Event_PlayerSpawn,	EventHookMode_PostNoCopy);
		HookEvent("round_start",		Event_RoundStart,	EventHookMode_PostNoCopy);
		HookEvent("round_end",			Event_RoundEnd,		EventHookMode_PostNoCopy);
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		ResetPlugin();
		g_bCvarAllow = false;
		UnhookEvent("player_spawn",		Event_PlayerSpawn,	EventHookMode_PostNoCopy);
		UnhookEvent("round_start",		Event_RoundStart,	EventHookMode_PostNoCopy);
		UnhookEvent("round_end",		Event_RoundEnd,		EventHookMode_PostNoCopy);
	}
}

static g_iCurrentMode;

bool:IsAllowedGameMode()
{
	if( g_hCvarMPGameMode == INVALID_HANDLE )
		return false;

	new iCvarModesTog = GetConVarInt(g_hCvarModesTog);
	if( iCvarModesTog != 0 )
	{
		g_iCurrentMode = 0;

		new entity = CreateEntityByName("info_gamemode");
		DispatchSpawn(entity);
		HookSingleEntityOutput(entity, "OnCoop", OnGamemode, true);
		HookSingleEntityOutput(entity, "OnSurvival", OnGamemode, true);
		HookSingleEntityOutput(entity, "OnVersus", OnGamemode, true);
		HookSingleEntityOutput(entity, "OnScavenge", OnGamemode, true);
		AcceptEntityInput(entity, "PostSpawnActivate");
		AcceptEntityInput(entity, "Kill");

		if( g_iCurrentMode == 0 )
			return false;

		if( !(iCvarModesTog & g_iCurrentMode) )
			return false;
	}

	decl String:sGameModes[64], String:sGameMode[64];
	GetConVarString(g_hCvarMPGameMode, sGameMode, sizeof(sGameMode));
	Format(sGameMode, sizeof(sGameMode), ",%s,", sGameMode);

	GetConVarString(g_hCvarModes, sGameModes, sizeof(sGameModes));
	if( strcmp(sGameModes, "") )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if( StrContains(sGameModes, sGameMode, false) == -1 )
			return false;
	}

	GetConVarString(g_hCvarModesOff, sGameModes, sizeof(sGameModes));
	if( strcmp(sGameModes, "") )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if( StrContains(sGameModes, sGameMode, false) != -1 )
			return false;
	}

	return true;
}

public OnGamemode(const String:output[], caller, activator, Float:delay)
{
	if( strcmp(output, "OnCoop") == 0 )
		g_iCurrentMode = 1;
	else if( strcmp(output, "OnSurvival") == 0 )
		g_iCurrentMode = 2;
	else if( strcmp(output, "OnVersus") == 0 )
		g_iCurrentMode = 4;
	else if( strcmp(output, "OnScavenge") == 0 )
		g_iCurrentMode = 8;
}



// ====================================================================================================
//					EVENTS
// ====================================================================================================
public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	ResetPlugin(false);
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if( g_iPlayerSpawn == 1 && g_iRoundStart == 0 )
		CreateTimer(1.0, tmrStart);
	g_iRoundStart = 1;
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if( g_iPlayerSpawn == 0 && g_iRoundStart == 1 )
		CreateTimer(1.0, tmrStart);
	g_iPlayerSpawn = 1;
}

public Action:tmrStart(Handle:timer)
{
	ResetPlugin();
	LoadSpawns();
}



// ====================================================================================================
//					LOAD SPAWNS
// ====================================================================================================
LoadSpawns()
{
	if( g_bLoaded || g_iCvarRandom == 0 ) return;
	g_bLoaded = true;

	decl String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "%s", CONFIG_SPAWNS);
	if( !FileExists(sPath) )
		return;

	// Load config
	new Handle:hFile = CreateKeyValues("spawns");
	if( !FileToKeyValues(hFile, sPath) )
	{
		CloseHandle(hFile);
		return;
	}

	// Check for current map in the config
	decl String:sMap[64];
	GetCurrentMap(sMap, 64);

	if( !KvJumpToKey(hFile, sMap) )
	{
		CloseHandle(hFile);
		return;
	}

	// Retrieve how many weapons to display
	new iCount = KvGetNum(hFile, "num", 0);
	if( iCount == 0 )
	{
		CloseHandle(hFile);
		return;
	}

	// Spawn only a select few weapons?
	new iIndexes[MAX_SPAWNS+1];
	if( iCount > MAX_SPAWNS )
		iCount = MAX_SPAWNS;


	// Spawn saved weapons or create random
	new iRandom = g_iCvarRandom;
	if( iRandom == -1 || iRandom > iCount)
		iRandom = iCount;
	if( iRandom != -1 )
	{
		for( new i = 1; i <= iCount; i++ )
			iIndexes[i-1] = i;

		SortIntegers(iIndexes, iCount, Sort_Random);
		iCount = iRandom;
	}

	// Get the weapon origins and spawn
	decl String:sTemp[10], Float:vPos[3], Float:vAng[3];
	new index, iMod;
	for( new i = 1; i <= iCount; i++ )
	{
		if( iRandom != -1 ) index = iIndexes[i-1];
		else index = i;

		IntToString(index, sTemp, sizeof(sTemp));

		if( KvJumpToKey(hFile, sTemp) )
		{
			KvGetVector(hFile, "ang", vAng);
			KvGetVector(hFile, "pos", vPos);
			iMod = KvGetNum(hFile, "mod");

			if( vPos[0] == 0.0 && vPos[1] == 0.0 && vPos[2] == 0.0 ) // Should never happen...
				LogError("Error: 0,0,0 origin. Iteration=%d. Index=%d. Random=%d. Count=%d.", i, index, iRandom, iCount);
			else
				CreateSpawn(vPos, vAng, index, iMod, true);
			KvGoBack(hFile);
		}
	}

	CloseHandle(hFile);
}



// ====================================================================================================
//					CREATE SPAWN
// ====================================================================================================
CreateSpawn(const Float:vOrigin[3], const Float:vAngles[3], index = 0, model = 0, autospawn = false)
{
	if( g_iSpawnCount >= MAX_SPAWNS )
		return;

	new iSpawnIndex = -1;
	for( new i = 0; i < MAX_SPAWNS; i++ )
	{
		if( g_iSpawns[i][0] == 0 )
		{
			iSpawnIndex = i;
			break;
		}
	}

	if( iSpawnIndex == -1 )
		return;


	if( autospawn && g_iCvarRandomise && GetRandomInt(0, 100) <= g_iCvarRandomise )
	{
		if( g_bLeft4Dead2 )
		{
			model = GetRandomInt(0, MAX_WEAPONS2-1);

			if( model == 15 || model == 18 )		model = GetRandomInt(0, 14);
			else if( model == 19 || model == 21 )	model = GetRandomInt(22, 28);
		} else {
			model = GetRandomInt(0, MAX_WEAPONS-1);
		}
	}

	decl String:classname[64];
	if( g_bLeft4Dead2 )
		strcopy(classname, sizeof(classname), g_sWeapons2[model]);
	else
		strcopy(classname, sizeof(classname), g_sWeapons[model]);

	if( g_iCvarCount != 1 )
		StrCat(classname, sizeof(classname), "_spawn");


	new entity_weapon = -1;
	entity_weapon = CreateEntityByName(classname);
	if( entity_weapon == -1 )
		ThrowError("Failed to create entity '%s'", classname);

	DispatchKeyValue(entity_weapon, "solid", "6");
	if( g_bLeft4Dead2 )
		DispatchKeyValue(entity_weapon, "model", g_sWeaponModels2[model]);
	else
		DispatchKeyValue(entity_weapon, "model", g_sWeaponModels[model]);
	DispatchKeyValue(entity_weapon, "rendermode", "3");
	DispatchKeyValue(entity_weapon, "disableshadows", "1");

	if( g_iCvarCount <= 0 ) // Infinite
	{
		DispatchKeyValue(entity_weapon, "spawnflags", "8");
	}
	else if( g_iCvarCount != 1 )
	{
		decl String:sCount[5];
		IntToString(g_iCvarCount, sCount, sizeof(sCount));
		DispatchKeyValue(entity_weapon, "count", sCount);
	}

	decl Float:vAng[3], Float:vPos[3];
	vPos = vOrigin;
	vAng = vAngles;
	if( model == 8 ) // First aid
	{
		vAng[0] += 90.0;
		vPos[2] += 1.0;
	}
	else if( g_bLeft4Dead2 && model == 28 ) // Adrenaline
	{
		vAng[1] -= 90.0;
		vAng[2] -= 90.0;
		vPos[2] += 1.0;
	}
	else if( g_bLeft4Dead2 && (model == 25 || model == 26 || model == 27 )) // Defib + Upgrades
	{
		vAng[1] -= 90.0;
		vAng[2] += 90.0;
	}
	else if( g_bLeft4Dead2 && model == 22 ) // Chainsaw
	{
		vPos[2] += 3.0;
	}

	TeleportEntity(entity_weapon, vPos, vAng, NULL_VECTOR);
	DispatchSpawn(entity_weapon);

	if( g_iCvarCount == 1 )
	{
		new ammo;

		if( model == 3 )						ammo = g_iAmmoSmg;
		else if( model == 0 )					ammo = g_iAmmoRifle;
		else if( model == 4 )					ammo = g_iAmmoShotgun;
		else if( model == 1 )					ammo = g_iAmmoAutoShot;
		else if( model == 2 )					ammo = g_iAmmoHunting;
		else if( g_bLeft4Dead2 )
		{
			if( model == 17 || model == 18 )								ammo = g_iAmmoSmg;
			else if( model == 11 || model == 14 || model == 15 )			ammo = g_iAmmoRifle;
			else if( model == 10 )											ammo = g_iAmmoShotgun;
			else if( model == 16 )											ammo = g_iAmmoAutoShot;
			else if( model == 22 )											ammo = g_iAmmoChainsaw;
			else if( model == 13 )											ammo = g_iAmmoM60;
			else if( model == 12 )											ammo = g_iAmmoGL;
			else if( model == 19 || model == 20 || model == 21 )			ammo = g_iAmmoSniper;
		}

		SetEntProp(entity_weapon, Prop_Send, "m_iExtraPrimaryAmmo", ammo, 4);
	}
	SetEntityMoveType(entity_weapon, MOVETYPE_NONE);

	g_iSpawns[iSpawnIndex][0] = EntIndexToEntRef(entity_weapon);
	g_iSpawns[iSpawnIndex][1] = index;

	g_iSpawnCount++;
}



// ====================================================================================================
//					COMMANDS
// ====================================================================================================
//					sm_weapon_spawn
// ====================================================================================================
public ListMenuHandler(Handle:menu, MenuAction:action, client, index)
{
	if( action == MenuAction_Select )
	{
		if( g_iSave[client] == 0 )
		{
			CmdSpawnerTempMenu(client, index);
		} else {
			CmdSpawnerSaveMenu(client, index);
		}

		DisplayMenu(g_hMenuList, client, MENU_TIME_FOREVER);
	}
}

public Action:CmdSpawnerTemp(client, args)
{
	if( !client )
	{
		ReplyToCommand(client, "[Weapon Spawn] Commands may only be used in-game on a dedicated server..");
		return Plugin_Handled;
	}
	else if( g_iSpawnCount >= MAX_SPAWNS )
	{
		PrintToChat(client, "%sError: Cannot add anymore weapons. Used: (\x05%d/%d\x01).", CHAT_TAG, g_iSpawnCount, MAX_SPAWNS);
		return Plugin_Handled;
	}

	g_iSave[client] = 0;
	DisplayMenu(g_hMenuList, client, MENU_TIME_FOREVER);

	return Plugin_Handled;
}

CmdSpawnerTempMenu(client, weapon)
{
	if( !client )
	{
		ReplyToCommand(client, "[Weapon Spawn] Commands may only be used in-game on a dedicated server..");
		return;
	}
	else if( g_iSpawnCount >= MAX_SPAWNS )
	{
		PrintToChat(client, "%sError: Cannot add anymore weapons. Used: (\x05%d/%d\x01).", CHAT_TAG, g_iSpawnCount, MAX_SPAWNS);
		return;
	}

	new Float:vPos[3], Float:vAng[3];
	if( !SetTeleportEndPoint(client, vPos, vAng) )
	{
		PrintToChat(client, "%sCannot place weapon, please try again.", CHAT_TAG);
		return;
	}

	CreateSpawn(vPos, vAng, 0, weapon);
	return;
}

// ====================================================================================================
//					sm_weapon_spawn_save
// ====================================================================================================
public Action:CmdSpawnerSave(client, args)
{
	if( !client )
	{
		ReplyToCommand(client, "[Weapon Spawn] Commands may only be used in-game on a dedicated server..");
		return Plugin_Handled;
	}
	else if( g_iSpawnCount >= MAX_SPAWNS )
	{
		PrintToChat(client, "%sError: Cannot add anymore weapons. Used: (\x05%d/%d\x01).", CHAT_TAG, g_iSpawnCount, MAX_SPAWNS);
		return Plugin_Handled;
	}

	g_iSave[client] = 1;
	DisplayMenu(g_hMenuList, client, MENU_TIME_FOREVER);

	return Plugin_Handled;
}

CmdSpawnerSaveMenu(client, weapon)
{
	decl String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "%s", CONFIG_SPAWNS);
	if( !FileExists(sPath) )
	{
		new Handle:hCfg = OpenFile(sPath, "w");
		WriteFileLine(hCfg, "");
		CloseHandle(hCfg);
	}

	// Load config
	new Handle:hFile = CreateKeyValues("spawns");
	if( !FileToKeyValues(hFile, sPath) )
	{
		PrintToChat(client, "%sError: Cannot read the weapon config, assuming empty file. (\x05%s\x01).", CHAT_TAG, sPath);
	}

	// Check for current map in the config
	decl String:sMap[64];
	GetCurrentMap(sMap, 64);
	if( !KvJumpToKey(hFile, sMap, true) )
	{
		PrintToChat(client, "%sError: Failed to add map to weapon spawn config.", CHAT_TAG);
		CloseHandle(hFile);
		return;
	}

	// Retrieve how many weapons are saved
	new iCount = KvGetNum(hFile, "num", 0);
	if( iCount >= MAX_SPAWNS )
	{
		PrintToChat(client, "%sError: Cannot add anymore weapons. Used: (\x05%d/%d\x01).", CHAT_TAG, iCount, MAX_SPAWNS);
		CloseHandle(hFile);
		return;
	}

	// Save count
	iCount++;
	KvSetNum(hFile, "num", iCount);

	decl String:sTemp[10];

	IntToString(iCount, sTemp, sizeof(sTemp));

	if( KvJumpToKey(hFile, sTemp, true) )
	{
		new Float:vPos[3], Float:vAng[3];
		// Set player position as weapon spawn location
		if( !SetTeleportEndPoint(client, vPos, vAng) )
		{
			PrintToChat(client, "%sCannot place weapon, please try again.", CHAT_TAG);
			CloseHandle(hFile);
			return;
		}

		// Save angle / origin
		KvSetVector(hFile, "ang", vAng);
		KvSetVector(hFile, "pos", vPos);
		KvSetNum(hFile, "mod", weapon);

		CreateSpawn(vPos, vAng, iCount, weapon);

		// Save cfg
		KvRewind(hFile);
		KeyValuesToFile(hFile, sPath);

		PrintToChat(client, "%s(\x05%d/%d\x01) - Saved at pos:[\x05%f %f %f\x01] ang:[\x05%f %f %f\x01]", CHAT_TAG, iCount, MAX_SPAWNS, vPos[0], vPos[1], vPos[2], vAng[0], vAng[1], vAng[2]);
	}
	else
		PrintToChat(client, "%s(\x05%d/%d\x01) - Failed to save weapon.", CHAT_TAG, iCount, MAX_SPAWNS);

	CloseHandle(hFile);
}

// ====================================================================================================
//					sm_weapon_spawn_del
// ====================================================================================================
public Action:CmdSpawnerDel(client, args)
{
	if( !g_bCvarAllow )
	{
		ReplyToCommand(client, "[Weapon Spawn] Plugin turned off.");
		return Plugin_Handled;
	}

	if( !client )
	{
		ReplyToCommand(client, "[Weapon Spawn] Commands may only be used in-game on a dedicated server..");
		return Plugin_Handled;
	}

	new entity = GetClientAimTarget(client, false);
	if( entity == -1 ) return Plugin_Handled;
	entity = EntIndexToEntRef(entity);

	new cfgindex, index = -1;
	for( new i = 0; i < MAX_SPAWNS; i++ )
	{
		if( g_iSpawns[i][0] == entity )
		{
			index = i;
			break;
		}
	}

	if( index == -1 )
		return Plugin_Handled;

	cfgindex = g_iSpawns[index][1];
	if( cfgindex == 0 )
	{
		RemoveSpawn(index);
		return Plugin_Handled;
	}

	for( new i = 0; i < MAX_SPAWNS; i++ )
	{
		if( g_iSpawns[i][1] > cfgindex )
			g_iSpawns[i][1]--;
	}

	g_iSpawnCount--;

	// Load config
	decl String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "%s", CONFIG_SPAWNS);
	if( !FileExists(sPath) )
	{
		PrintToChat(client, "%sError: Cannot find the weapon config (\x05%s\x01).", CHAT_TAG, CONFIG_SPAWNS);
		return Plugin_Handled;
	}

	new Handle:hFile = CreateKeyValues("spawns");
	if( !FileToKeyValues(hFile, sPath) )
	{
		PrintToChat(client, "%sError: Cannot load the weapon config (\x05%s\x01).", CHAT_TAG, sPath);
		CloseHandle(hFile);
		return Plugin_Handled;
	}

	// Check for current map in the config
	decl String:sMap[64];
	GetCurrentMap(sMap, 64);

	if( !KvJumpToKey(hFile, sMap) )
	{
		PrintToChat(client, "%sError: Current map not in the weapon config.", CHAT_TAG);
		CloseHandle(hFile);
		return Plugin_Handled;
	}

	// Retrieve how many weapons
	new iCount = KvGetNum(hFile, "num", 0);
	if( iCount == 0 )
	{
		CloseHandle(hFile);
		return Plugin_Handled;
	}

	new bool:bMove;
	decl String:sTemp[16];

	// Move the other entries down
	for( new i = cfgindex; i <= iCount; i++ )
	{
		IntToString(i, sTemp, sizeof(sTemp));

		if( KvJumpToKey(hFile, sTemp) )
		{
			if( !bMove )
			{
				bMove = true;
				KvDeleteThis(hFile);
				RemoveSpawn(index);
			}
			else
			{
				IntToString(i-1, sTemp, sizeof(sTemp));
				KvSetSectionName(hFile, sTemp);
			}
		}

		KvRewind(hFile);
		KvJumpToKey(hFile, sMap);
	}

	if( bMove )
	{
		iCount--;
		KvSetNum(hFile, "num", iCount);

		// Save to file
		KvRewind(hFile);
		KeyValuesToFile(hFile, sPath);

		PrintToChat(client, "%s(\x05%d/%d\x01) - weapon removed from config.", CHAT_TAG, iCount, MAX_SPAWNS);
	}
	else
		PrintToChat(client, "%s(\x05%d/%d\x01) - Failed to remove weapon from config.", CHAT_TAG, iCount, MAX_SPAWNS);

	CloseHandle(hFile);
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_weapon_spawn_clear
// ====================================================================================================
public Action:CmdSpawnerClear(client, args)
{
	if( !client )
	{
		ReplyToCommand(client, "[Weapon Spawn] Commands may only be used in-game on a dedicated server..");
		return Plugin_Handled;
	}

	ResetPlugin();

	PrintToChat(client, "%s(0/%d) - All weapons removed from the map.", CHAT_TAG, MAX_SPAWNS);
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_weapon_spawn_wipe
// ====================================================================================================
public Action:CmdSpawnerWipe(client, args)
{
	if( !client )
	{
		ReplyToCommand(client, "[Weapon Spawn] Commands may only be used in-game on a dedicated server..");
		return Plugin_Handled;
	}

	decl String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "%s", CONFIG_SPAWNS);
	if( !FileExists(sPath) )
	{
		PrintToChat(client, "%sError: Cannot find the weapon config (\x05%s\x01).", CHAT_TAG, sPath);
		return Plugin_Handled;
	}

	// Load config
	new Handle:hFile = CreateKeyValues("spawns");
	if( !FileToKeyValues(hFile, sPath) )
	{
		PrintToChat(client, "%sError: Cannot load the weapon config (\x05%s\x01).", CHAT_TAG, sPath);
		CloseHandle(hFile);
		return Plugin_Handled;
	}

	// Check for current map in the config
	decl String:sMap[64];
	GetCurrentMap(sMap, 64);

	if( !KvJumpToKey(hFile, sMap, false) )
	{
		PrintToChat(client, "%sError: Current map not in the weapon config.", CHAT_TAG);
		CloseHandle(hFile);
		return Plugin_Handled;
	}

	KvDeleteThis(hFile);
	ResetPlugin();

	// Save to file
	KvRewind(hFile);
	KeyValuesToFile(hFile, sPath);
	CloseHandle(hFile);

	PrintToChat(client, "%s(0/%d) - All weapons removed from config, add with \x05sm_weapon_spawn_save\x01.", CHAT_TAG, MAX_SPAWNS);
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_weapon_spawn_glow
// ====================================================================================================
public Action:CmdSpawnerGlow(client, args)
{
	static bool:glow;
	glow = !glow;
	PrintToChat(client, "%sGlow has been turned %s", CHAT_TAG, glow ? "on" : "off");

	VendorGlow(glow);
	return Plugin_Handled;
}

VendorGlow(glow)
{
	new ent;

	for( new i = 0; i < MAX_SPAWNS; i++ )
	{
		ent = g_iSpawns[i][0];
		if( IsValidEntRef(ent) )
		{
			SetEntProp(ent, Prop_Send, "m_iGlowType", glow ? 3 : 0);
			if( glow )
			{
				SetEntProp(ent, Prop_Send, "m_glowColorOverride", 255);
				SetEntProp(ent, Prop_Send, "m_nGlowRange", glow ? 0 : 50);
			}
		}
	}
}

// ====================================================================================================
//					sm_weapon_spawn_list
// ====================================================================================================
public Action:CmdSpawnerList(client, args)
{
	decl Float:vPos[3];
	new count;
	for( new i = 0; i < MAX_SPAWNS; i++ )
	{
		if( IsValidEntRef(g_iSpawns[i][0]) )
		{
			count++;
			GetEntPropVector(g_iSpawns[i][0], Prop_Data, "m_vecOrigin", vPos);
			PrintToChat(client, "%s%d) %f %f %f", CHAT_TAG, i+1, vPos[0], vPos[1], vPos[2]);
		}
	}
	PrintToChat(client, "%sTotal: %d.", CHAT_TAG, count);
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_weapon_spawn_tele
// ====================================================================================================
public Action:CmdSpawnerTele(client, args)
{
	if( args == 1 )
	{
		decl String:arg[16];
		GetCmdArg(1, arg, 16);
		new index = StringToInt(arg) - 1;
		if( index > -1 && index < MAX_SPAWNS && IsValidEntRef(g_iSpawns[index][0]) )
		{
			decl Float:vPos[3];
			GetEntPropVector(g_iSpawns[index][0], Prop_Data, "m_vecOrigin", vPos);
			vPos[2] += 20.0;
			TeleportEntity(client, vPos, NULL_VECTOR, NULL_VECTOR);
			PrintToChat(client, "%sTeleported to %d.", CHAT_TAG, index + 1);
			return Plugin_Handled;
		}

		PrintToChat(client, "%sCould not find index for teleportation.", CHAT_TAG);
	}
	else
		PrintToChat(client, "%sUsage: sm_weapon_spawn_tele <index 1-%d>.", CHAT_TAG, MAX_SPAWNS);
	return Plugin_Handled;
}

// ====================================================================================================
//					MENU ANGLE
// ====================================================================================================
public Action:CmdSpawnerAng(client, args)
{
	ShowMenuAng(client);
	return Plugin_Handled;
}

ShowMenuAng(client)
{
	CreateMenus();
	DisplayMenu(g_hMenuAng, client, MENU_TIME_FOREVER);
}

public AngMenuHandler(Handle:menu, MenuAction:action, client, index)
{
	if( action == MenuAction_Select )
	{
		if( index == 6 )
			SaveData(client);
		else
			SetAngle(client, index);
		ShowMenuAng(client);
	}
}

SetAngle(client, index)
{
	new aim = GetClientAimTarget(client, false);
	if( aim != -1 )
	{
		new Float:vAng[3], entity;
		aim = EntIndexToEntRef(aim);

		for( new i = 0; i < MAX_SPAWNS; i++ )
		{
			entity = g_iSpawns[i][0];

			if( entity == aim  )
			{
				GetEntPropVector(entity, Prop_Send, "m_angRotation", vAng);

				if( index == 0 ) vAng[0] += 2.0;
				else if( index == 1 ) vAng[1] += 2.0;
				else if( index == 2 ) vAng[2] += 2.0;
				else if( index == 3 ) vAng[0] -= 2.0;
				else if( index == 4 ) vAng[1] -= 2.0;
				else if( index == 5 ) vAng[2] -= 2.0;

				TeleportEntity(entity, NULL_VECTOR, vAng, NULL_VECTOR);

				PrintToChat(client, "%sNew angles: %f %f %f", CHAT_TAG, vAng[0], vAng[1], vAng[2]);
				break;
			}
		}
	}
}

// ====================================================================================================
//					MENU ORIGIN
// ====================================================================================================
public Action:CmdSpawnerPos(client, args)
{
	ShowMenuPos(client);
	return Plugin_Handled;
}

ShowMenuPos(client)
{
	CreateMenus();
	DisplayMenu(g_hMenuPos, client, MENU_TIME_FOREVER);
}

public PosMenuHandler(Handle:menu, MenuAction:action, client, index)
{
	if( action == MenuAction_Select )
	{
		if( index == 6 )
			SaveData(client);
		else
			SetOrigin(client, index);
		ShowMenuPos(client);
	}
}

SetOrigin(client, index)
{
	new aim = GetClientAimTarget(client, false);
	if( aim != -1 )
	{
		new Float:vPos[3], entity;
		aim = EntIndexToEntRef(aim);

		for( new i = 0; i < MAX_SPAWNS; i++ )
		{
			entity = g_iSpawns[i][0];

			if( entity == aim  )
			{
				GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vPos);

				if( index == 0 ) vPos[0] += 0.5;
				else if( index == 1 ) vPos[1] += 0.5;
				else if( index == 2 ) vPos[2] += 0.5;
				else if( index == 3 ) vPos[0] -= 0.5;
				else if( index == 4 ) vPos[1] -= 0.5;
				else if( index == 5 ) vPos[2] -= 0.5;

				TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);

				PrintToChat(client, "%sNew origin: %f %f %f", CHAT_TAG, vPos[0], vPos[1], vPos[2]);
				break;
			}
		}
	}
}

SaveData(client)
{
	new entity, index;
	new aim = GetClientAimTarget(client, false);
	if( aim == -1 )
		return;

	aim = EntIndexToEntRef(aim);

	for( new i = 0; i < MAX_SPAWNS; i++ )
	{
		entity = g_iSpawns[i][0];

		if( entity == aim  )
		{
			index = g_iSpawns[i][1];
			break;
		}
	}

	if( index == 0 )
		return;

	// Load config
	decl String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "%s", CONFIG_SPAWNS);
	if( !FileExists(sPath) )
	{
		PrintToChat(client, "%sError: Cannot find the Weapon Spawn config (\x05%s\x01).", CHAT_TAG, CONFIG_SPAWNS);
		return;
	}

	new Handle:hFile = CreateKeyValues("spawns");
	if( !FileToKeyValues(hFile, sPath) )
	{
		PrintToChat(client, "%sError: Cannot load the Weapon Spawn config (\x05%s\x01).", CHAT_TAG, sPath);
		CloseHandle(hFile);
		return;
	}

	// Check for current map in the config
	decl String:sMap[64];
	GetCurrentMap(sMap, 64);

	if( !KvJumpToKey(hFile, sMap) )
	{
		PrintToChat(client, "%sError: Current map not in the Weapon Spawn config.", CHAT_TAG);
		CloseHandle(hFile);
		return;
	}

	decl Float:vAng[3], Float:vPos[3], String:sTemp[32];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vPos);
	GetEntPropVector(entity, Prop_Send, "m_angRotation", vAng);

	IntToString(index, sTemp, sizeof(sTemp));
	if( KvJumpToKey(hFile, sTemp) )
	{
		KvSetVector(hFile, "ang", vAng);
		KvSetVector(hFile, "pos", vPos);

		// Save cfg
		KvRewind(hFile);
		KeyValuesToFile(hFile, sPath);

		PrintToChat(client, "%sSaved origin and angles to the data config", CHAT_TAG);
	}
}

CreateMenus()
{
	if( g_hMenuAng == INVALID_HANDLE )
	{
		g_hMenuAng = CreateMenu(AngMenuHandler);
		AddMenuItem(g_hMenuAng, "", "X + 2.0");
		AddMenuItem(g_hMenuAng, "", "Y + 2.0");
		AddMenuItem(g_hMenuAng, "", "Z + 2.0");
		AddMenuItem(g_hMenuAng, "", "X - 2.0");
		AddMenuItem(g_hMenuAng, "", "Y - 2.0");
		AddMenuItem(g_hMenuAng, "", "Z - 2.0");
		AddMenuItem(g_hMenuAng, "", "SAVE");
		SetMenuTitle(g_hMenuAng, "Set Angle");
		SetMenuExitButton(g_hMenuAng, true);
	}

	if( g_hMenuPos == INVALID_HANDLE )
	{
		g_hMenuPos = CreateMenu(PosMenuHandler);
		AddMenuItem(g_hMenuPos, "", "X + 0.5");
		AddMenuItem(g_hMenuPos, "", "Y + 0.5");
		AddMenuItem(g_hMenuPos, "", "Z + 0.5");
		AddMenuItem(g_hMenuPos, "", "X - 0.5");
		AddMenuItem(g_hMenuPos, "", "Y - 0.5");
		AddMenuItem(g_hMenuPos, "", "Z - 0.5");
		AddMenuItem(g_hMenuPos, "", "SAVE");
		SetMenuTitle(g_hMenuPos, "Set Position");
		SetMenuExitButton(g_hMenuPos, true);
	}
}



// ====================================================================================================
//					STUFF
// ====================================================================================================
bool:IsValidEntRef(entity)
{
	if( entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE )
		return true;
	return false;
}

ResetPlugin(bool:all = true)
{
	g_bLoaded = false;
	g_iSpawnCount = 0;
	g_iRoundStart = 0;
	g_iPlayerSpawn = 0;

	if( all )
		for( new i = 0; i < MAX_SPAWNS; i++ )
			RemoveSpawn(i);
}

RemoveSpawn(index)
{
	new entity, client;

	entity = g_iSpawns[index][0];
	g_iSpawns[index][0] = 0;
	g_iSpawns[index][1] = 0;

	if( IsValidEntRef(entity) )
	{
		client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
		if( client < 0 || client > MaxClients || !IsClientInGame(client) )
		{
			AcceptEntityInput(entity, "kill");
		}
	}
}



// ====================================================================================================
//					POSITION
// ====================================================================================================
Float:GetGroundHeight(Float:vPos[3])
{
	new Float:vAng[3], Handle:trace = TR_TraceRayFilterEx(vPos, Float:{ 90.0, 0.0, 0.0 }, MASK_ALL, RayType_Infinite, _TraceFilter);
	if( TR_DidHit(trace) )
		TR_GetEndPosition(vAng, trace);

	CloseHandle(trace);
	return vAng[2];
}

// Taken from "[L4D2] Weapon/Zombie Spawner"
// By "Zuko & McFlurry"
SetTeleportEndPoint(client, Float:vPos[3], Float:vAng[3])
{
	GetClientEyePosition(client, vPos);
	GetClientEyeAngles(client, vAng);

	new Handle:trace = TR_TraceRayFilterEx(vPos, vAng, MASK_SHOT, RayType_Infinite, _TraceFilter);

	if(TR_DidHit(trace))
	{
		decl Float:vNorm[3];
		new Float:degrees = vAng[1];
		TR_GetEndPosition(vPos, trace);
		GetGroundHeight(vPos);
		vPos[2] += 1.0;
		TR_GetPlaneNormal(trace, vNorm);
		GetVectorAngles(vNorm, vAng);
		if( vNorm[2] == 1.0 )
		{
			vAng[0] = 0.0;
			vAng[1] = degrees + 180;
		}
		else
		{
			if( degrees > vAng[1] )
				degrees = vAng[1] - degrees;
			else
				degrees = degrees - vAng[1];
			vAng[0] += 90.0;
			RotateYaw(vAng, degrees + 180);
		}
	}
	else
	{
		CloseHandle(trace);
		return false;
	}
	CloseHandle(trace);

	vAng[1] += 90.0;
	vAng[2] -= 90.0;
	return true;
}

public bool:_TraceFilter(entity, contentsMask)
{
	return entity > MaxClients || !entity;
}



//---------------------------------------------------------
// do a specific rotation on the given angles
//---------------------------------------------------------
RotateYaw( Float:angles[3], Float:degree )
{
	decl Float:direction[3], Float:normal[3];
	GetAngleVectors( angles, direction, NULL_VECTOR, normal );

	new Float:sin = Sine( degree * 0.01745328 );	 // Pi/180
	new Float:cos = Cosine( degree * 0.01745328 );
	new Float:a = normal[0] * sin;
	new Float:b = normal[1] * sin;
	new Float:c = normal[2] * sin;
	new Float:x = direction[2] * b + direction[0] * cos - direction[1] * c;
	new Float:y = direction[0] * c + direction[1] * cos - direction[2] * a;
	new Float:z = direction[1] * a + direction[2] * cos - direction[0] * b;
	direction[0] = x;
	direction[1] = y;
	direction[2] = z;

	GetVectorAngles( direction, angles );

	decl Float:up[3];
	GetVectorVectors( direction, NULL_VECTOR, up );

	new Float:roll = GetAngleBetweenVectors( up, normal, direction );
	angles[2] += roll;
}

//---------------------------------------------------------
// calculate the angle between 2 vectors
// the direction will be used to determine the sign of angle (right hand rule)
// all of the 3 vectors have to be normalized
//---------------------------------------------------------
Float:GetAngleBetweenVectors( const Float:vector1[3], const Float:vector2[3], const Float:direction[3] )
{
	decl Float:vector1_n[3], Float:vector2_n[3], Float:direction_n[3], Float:cross[3];
	NormalizeVector( direction, direction_n );
	NormalizeVector( vector1, vector1_n );
	NormalizeVector( vector2, vector2_n );
	new Float:degree = ArcCosine( GetVectorDotProduct( vector1_n, vector2_n ) ) * 57.29577951;   // 180/Pi
	GetVectorCrossProduct( vector1_n, vector2_n, cross );

	if ( GetVectorDotProduct( cross, direction_n ) < 0.0 )
		degree *= -1.0;

	return degree;
}