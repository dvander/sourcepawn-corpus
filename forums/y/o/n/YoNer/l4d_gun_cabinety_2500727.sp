#define PLUGIN_VERSION 		"1.1"

/*=======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] Gun Cabinet
*	Author	:	SilverShot - Temp Cabinet mod by YoNer
*	Descrp	:	Spawns a gun cabinet with various weapons and items of your choosing.
*	Link	:	http://forums.alliedmods.net/showthread.php?t=222931

========================================================================================
	Change Log:
	
1.1y(03-Mar-2017)
    - Udpated to work like most other plugins by Silver. sm_gun_cabinet no spawns a temp cabinet
	 while sm_gun_cabinet_save creates a saved cabinet.
	- Fixed Cabinet limit counter error (would not let spawn any more cabinets after 5 even after clearing all,
	  this issue required to reload the plugin to be able to spawn new cabinets)

1.1 (20-Nov-2015)
	- Fixed Auto Shotgun ammo in L4D1 not filling.

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

#define CVAR_FLAGS			FCVAR_NOTIFY
#define CHAT_TAG			"\x04[\x05Gun Cabinet\x04] \x01"
#define CONFIG_SPAWNS		"data/l4d_gun_cabinet.cfg"
#define CONFIG_WEAPONS		"data/l4d_gun_cabinet_presets.cfg"
#define MAX_SPAWNS			5
#define MAX_DOORS			4
#define	MAX_WEAPONS			10
#define	MAX_WEAPONS2		29
#define	MAX_PRESETS			7
#define	MAX_SLOTS			16
#define	MODEL_CABINET		"models/props_unique/guncabinet01_main.mdl"
#define	MODEL_CRATE			"models/props_crates/supply_crate02_gib2.mdl"

static	Handle:g_hCvarMPGameMode, Handle:g_hCvarModes, Handle:g_hCvarModesOff, Handle:g_hCvarModesTog, Handle:g_hCvarAllow,
		Handle:g_hCvarCSS, Handle:g_hCvarGlow, Handle:g_hCvarGlowCol, Handle:g_hCvarMaxGun, Handle:g_hCvarMaxPistol, Handle:g_hCvarMaxItem,
		g_iCvarCSS, g_iCvarGlow, g_iCvarGlowCol, Handle:g_hCvarRandom, g_iCvarMaxGun, g_iCvarMaxPistol, g_iCvarMaxItem,
		bool:g_bCvarAllow, g_iCvarRandom, bool:g_bLeft4Dead2, bool:g_bLoaded, g_iPlayerSpawn, g_iRoundStart, g_iSpawnCount,
		g_iPresets[MAX_PRESETS][MAX_SLOTS], g_iSpawns[MAX_SPAWNS][MAX_SLOTS + 2], g_iDoors[MAX_SPAWNS][MAX_DOORS],
		Handle:g_hMenuList, Handle:g_hMenuAng, Handle:g_hMenuPos, g_iSave[MAXPLAYERS+1];


static	Handle:g_hAmmoGL, Handle:g_hAmmoRifle, Handle:g_hAmmoShotgun, Handle:g_hAmmoSmg, Handle:g_hAmmoChainsaw,
		Handle:g_hAmmoAutoShot, Handle:g_hAmmoM60, Handle:g_hAmmoSniper, Handle:g_hAmmoHunting,
		g_iAmmoGL, g_iAmmoRifle, g_iAmmoShotgun, g_iAmmoSmg, g_iAmmoChainsaw, g_iAmmoAutoShot, g_iAmmoM60, g_iAmmoSniper, g_iAmmoHunting;

static String:g_sWeapons[MAX_WEAPONS][] =
{
	"weapon_rifle",
	"weapon_autoshotgun",
	"weapon_hunting_rifle",
	"weapon_smg",
	"weapon_pumpshotgun",
	"weapon_pistol",
	"weapon_molotov",
	"weapon_pipe_bomb",
	"weapon_first_aid_kit",
	"weapon_pain_pills"
};
static String:g_sWeaponModels[MAX_WEAPONS][] =
{
	"models/w_models/weapons/w_rifle_m16a2.mdl",
	"models/w_models/weapons/w_autoshot_m4super.mdl",
	"models/w_models/weapons/w_sniper_mini14.mdl",
	"models/w_models/weapons/w_smg_uzi.mdl",
	"models/w_models/weapons/w_pumpshotgun_A.mdl",
	"models/w_models/weapons/w_pistol_a.mdl",
	"models/w_models/weapons/w_eq_molotov.mdl",
	"models/w_models/weapons/w_eq_pipebomb.mdl",
	"models/w_models/weapons/w_eq_medkit.mdl",
	"models/w_models/weapons/w_eq_painpills.mdl"
};
static String:g_sWeapons2[MAX_WEAPONS2][] =
{
	"weapon_rifle",
	"weapon_autoshotgun",
	"weapon_hunting_rifle",
	"weapon_smg",
	"weapon_pumpshotgun",
	"weapon_shotgun_chrome",
	"weapon_rifle_desert",
	"weapon_grenade_launcher",
	"weapon_rifle_m60",
	"weapon_rifle_ak47",
	"weapon_shotgun_spas",
	"weapon_smg_silenced",
	"weapon_sniper_military",
	"weapon_chainsaw",
	"weapon_rifle_sg552",
	"weapon_smg_mp5",
	"weapon_sniper_awp",
	"weapon_sniper_scout",
	"weapon_pistol",
	"weapon_pistol_magnum",
	"weapon_molotov",
	"weapon_pipe_bomb",
	"weapon_vomitjar",
	"weapon_first_aid_kit",
	"weapon_defibrillator",
	"weapon_pain_pills",
	"weapon_adrenaline",
	"weapon_upgradepack_explosive",
	"weapon_upgradepack_incendiary"
};
static String:g_sWeaponModels2[MAX_WEAPONS2][] =
{
	"models/w_models/weapons/w_rifle_m16a2.mdl",
	"models/w_models/weapons/w_autoshot_m4super.mdl",
	"models/w_models/weapons/w_sniper_mini14.mdl",
	"models/w_models/weapons/w_smg_uzi.mdl",
	"models/w_models/weapons/w_pumpshotgun_A.mdl",
	"models/w_models/weapons/w_shotgun.mdl",
	"models/w_models/weapons/w_desert_rifle.mdl",
	"models/w_models/weapons/w_grenade_launcher.mdl",
	"models/w_models/weapons/w_m60.mdl",
	"models/w_models/weapons/w_rifle_ak47.mdl",
	"models/w_models/weapons/w_shotgun_spas.mdl",
	"models/w_models/weapons/w_smg_a.mdl",
	"models/w_models/weapons/w_sniper_military.mdl",
	"models/weapons/melee/w_chainsaw.mdl",
	"models/w_models/weapons/w_rifle_sg552.mdl",
	"models/w_models/weapons/w_smg_mp5.mdl",
	"models/w_models/weapons/w_sniper_awp.mdl",
	"models/w_models/weapons/w_sniper_scout.mdl",
	"models/w_models/weapons/w_pistol_a.mdl",
	"models/w_models/weapons/w_desert_eagle.mdl",
	"models/w_models/weapons/w_eq_molotov.mdl",
	"models/w_models/weapons/w_eq_pipebomb.mdl",
	"models/w_models/weapons/w_eq_bile_flask.mdl",
	"models/w_models/weapons/w_eq_medkit.mdl",
	"models/w_models/weapons/w_eq_defibrillator.mdl",
	"models/w_models/weapons/w_eq_painpills.mdl",
	"models/w_models/weapons/w_eq_adrenaline.mdl",
	"models/w_models/weapons/w_eq_explosive_ammopack.mdl",
	"models/w_models/weapons/w_eq_incendiary_ammopack.mdl"
};



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin:myinfo =
{
	name = "[L4D & L4D2] Gun Cabinet",
	author = "SilverShot",
	description = "Spawns a gun cabinet with various weapons and items of your choosing.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=222931"
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
	g_hCvarAllow =		CreateConVar(	"l4d_gun_cabinet_allow",			"1",			"0=Plugin off, 1=Plugin on.", CVAR_FLAGS );
	g_hCvarCSS =		CreateConVar(	"l4d_gun_cabinet_css",				"0",			"0=Off, 1=Allow spawning CSS weapons when using the 'random' value in the preset config.", CVAR_FLAGS );
	g_hCvarGlow =		CreateConVar(	"l4d_gun_cabinet_glow",				"0",			"0=Off, Sets the max range at which the cabinet glows.", CVAR_FLAGS );
	g_hCvarGlowCol =	CreateConVar(	"l4d_gun_cabinet_glow_color",		"255 0 0",		"0=Default glow color. Three values between 0-255 separated by spaces. RGB: Red Green Blue.", CVAR_FLAGS );
	g_hCvarModes =		CreateConVar(	"l4d_gun_cabinet_modes",			"",				"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff =	CreateConVar(	"l4d_gun_cabinet_modes_off",		"",				"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog =	CreateConVar(	"l4d_gun_cabinet_modes_tog",		"0",			"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	g_hCvarMaxGun =		CreateConVar(	"l4d_gun_cabinet_max_gun",			"8",			"Minimum number of primary weapons to spawn. (max is 10).", CVAR_FLAGS );
	g_hCvarMaxPistol =	CreateConVar(	"l4d_gun_cabinet_max_pistol",		"2",			"Maximum number of pistols to spawn (max is 4).", CVAR_FLAGS );
	g_hCvarMaxItem =	CreateConVar(	"l4d_gun_cabinet_max_item",			"1",			"Maximum number of items to spawn (max is 2).", CVAR_FLAGS );
	g_hCvarRandom =		CreateConVar(	"l4d_gun_cabinet_random",			"-1",			"-1=All, 0=None. Otherwise randomly select this many Gun Cabinets to spawn from the maps confg.", CVAR_FLAGS );
	CreateConVar(						"l4d_gun_cabinet_version",			PLUGIN_VERSION, "Gun Cabinet plugin version.", CVAR_FLAGS|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	AutoExecConfig(true,				"l4d_gun_cabinet");

	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	HookConVarChange(g_hCvarMPGameMode,		ConVarChanged_Allow);
	HookConVarChange(g_hCvarAllow,			ConVarChanged_Allow);
	HookConVarChange(g_hCvarModes,			ConVarChanged_Allow);
	HookConVarChange(g_hCvarModesOff,		ConVarChanged_Allow);
	HookConVarChange(g_hCvarModesTog,		ConVarChanged_Allow);
	HookConVarChange(g_hCvarCSS,			ConVarChanged_Cvars);
	HookConVarChange(g_hCvarGlow,			ConVarChanged_Cvars);
	HookConVarChange(g_hCvarGlowCol,		ConVarChanged_Cvars);
	HookConVarChange(g_hCvarRandom,			ConVarChanged_Cvars);
	HookConVarChange(g_hCvarMaxGun,			ConVarChanged_Cvars);
	HookConVarChange(g_hCvarMaxPistol,		ConVarChanged_Cvars);
	HookConVarChange(g_hCvarMaxItem,		ConVarChanged_Cvars);

	g_hAmmoRifle =			FindConVar("ammo_assaultrifle_max");
	g_hAmmoShotgun =		g_bLeft4Dead2 ? FindConVar("ammo_shotgun_max") : FindConVar("ammo_buckshot_max");
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

		HookConVarChange(g_hAmmoGL,			ConVarChanged_Cvars);
		HookConVarChange(g_hAmmoChainsaw,	ConVarChanged_Cvars);
		HookConVarChange(g_hAmmoAutoShot,	ConVarChanged_Cvars);
		HookConVarChange(g_hAmmoM60,		ConVarChanged_Cvars);
		HookConVarChange(g_hAmmoSniper,		ConVarChanged_Cvars);
	}

	RegAdminCmd("sm_gun_cabinet",			CmdCabinetTemp,	ADMFLAG_ROOT, 	"Opens a menu to spawn a temporary Gun Cabinet.");
	RegAdminCmd("sm_gun_cabinet_save",		CmdCabinetSave,	ADMFLAG_ROOT, 	"Opens a menu to spawn and save a Gun Cabinet to the data config for auto spawning.");
	RegAdminCmd("sm_gun_cabinet_del",		CmdCabinetDel,		ADMFLAG_ROOT, 	"Removes the Gun Cabinet you are pointing at and deletes from the config.");
	RegAdminCmd("sm_gun_cabinet_clear",		CmdCabinetClear,	ADMFLAG_ROOT, 	"Removes all Gun Cabinets from the current map.");
	RegAdminCmd("sm_gun_cabinet_wipe",		CmdCabinetWipe,		ADMFLAG_ROOT, 	"Removes all Gun Cabinets from the current map and deletes them from the config.");
	RegAdminCmd("sm_gun_cabinet_glow",		CmdCabinetGlow,		ADMFLAG_ROOT, 	"Toggle to enable glow on all Gun Cabinets to see where they are placed.");
	RegAdminCmd("sm_gun_cabinet_list",		CmdCabinetList,		ADMFLAG_ROOT, 	"Display a list of Gun Cabinet positions and the total number of.");
	RegAdminCmd("sm_gun_cabinet_reload",	CmdCabinetReload,	ADMFLAG_ROOT, 	"Reloads the plugin, reads the preset data config and spawns any save Gun Cabinets.");
	RegAdminCmd("sm_gun_cabinet_tele",		CmdCabinetTele,		ADMFLAG_ROOT, 	"Teleport to a Gun Cabinet (Usage: sm_gun_cabinet_tele <index: 1 to MAX_SPAWNS (5)>).");
	RegAdminCmd("sm_gun_cabinet_ang",		CmdCabinetAng,		ADMFLAG_ROOT, 	"Displays a menu to adjust the Gun Cabinet angles your crosshair is over.");
	RegAdminCmd("sm_gun_cabinet_pos",		CmdCabinetPos,		ADMFLAG_ROOT, 	"Displays a menu to adjust the Gun Cabinet origin your crosshair is over.");

	LoadPresets();
}

public OnPluginEnd()
{
	ResetPlugin();
}

public OnMapStart()
{
	PrecacheModel(MODEL_CABINET);
	PrecacheModel(MODEL_CRATE);

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

GetColor(Handle:cvar)
{
	decl String:sTemp[12], String:sColors[3][4];
	GetConVarString(cvar, sTemp, sizeof(sTemp));
	ExplodeString(sTemp, " ", sColors, 3, 4);

	new color;
	color = StringToInt(sColors[0]);
	color += 256 * StringToInt(sColors[1]);
	color += 65536 * StringToInt(sColors[2]);
	return color;
}

LoadPresets()
{
	decl String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "%s", CONFIG_WEAPONS);
	if( !FileExists(sPath) )
	{
		SetFailState("Error: Missing required preset config: %s", sPath);
	}

	new Handle:hFile = CreateKeyValues("presets");
	if( !FileToKeyValues(hFile, sPath) )
	{
		SetFailState("Error: Cannot read the preset config: %s", sPath);
	}

	g_hMenuList = CreateMenu(ListMenuHandler);
	SetMenuTitle(g_hMenuList, "Spawn Cabinet");
	SetMenuExitButton(g_hMenuList, true);

	decl String:sBuff[64], String:sTemp[64];
	for( new preset = 0; preset < MAX_PRESETS; preset++ )
	{
		Format(sTemp, sizeof(sTemp), "preset%d", preset + 1);
		if( KvJumpToKey(hFile, sTemp) )
		{
			KvGetString(hFile, "name", sBuff, sizeof(sBuff));
			IntToString(preset + 1, sTemp, sizeof(sTemp));
			AddMenuItem(g_hMenuList, sTemp, sBuff);

			for( new slot = 0; slot < MAX_SLOTS; slot++ )
			{
				Format(sTemp, sizeof(sTemp), "slot%d", slot + 1);
				KvGetString(hFile, sTemp, sBuff, sizeof(sBuff));

				if( strcmp(sBuff, "") )
				{
					if( g_bLeft4Dead2 )
					{
						if( strcmp(sBuff, "random") == 0 )
						{
							if( slot < 10 )
							{
								if( g_iCvarCSS )
								{
									g_iPresets[preset][slot] = GetRandomInt(1, 18);		// Random primary - all
								} else {
									g_iPresets[preset][slot] = GetRandomInt(1, 14);		// Random primary - no css
								}
							}

							if( slot >= 10 && slot <= 13 )		g_iPresets[preset][slot] = GetRandomInt(19, 20);	// Random pistol
							if( slot >= 14 && slot <= 16 )		g_iPresets[preset][slot] = GetRandomInt(21, 29);	// Random medical/grenade
						} else {
							Format(sBuff, sizeof(sBuff), "weapon_%s", sBuff);

							for( new i = 0; i < MAX_WEAPONS2; i++ )
							{
								if( strcmp(sBuff, g_sWeapons2[i]) == 0 )
								{
									g_iPresets[preset][slot] = i + 1;
									break;
								}
							}
						}
					} else {
						if( strcmp(sBuff, "random") == 0 )
						{
							if( slot < 10 )						g_iPresets[preset][slot] = GetRandomInt(1, 5);		// Random primary
							if( slot >= 11 && slot <= 14 )		g_iPresets[preset][slot] = 6;
							if( slot >= 15 && slot <= 16 )		g_iPresets[preset][slot] = GetRandomInt(7, 10);		// Random medical/grenade
						} else {
							Format(sBuff, sizeof(sBuff), "weapon_%s", sBuff);

							for( new i = 0; i < MAX_WEAPONS; i++ )
							{
								if( strcmp(sBuff, g_sWeapons[i]) == 0 )
								{
									g_iPresets[preset][slot] = i + 1;
									break;
								}
							}
						}
					}
				}
			}
		}

		KvRewind(hFile);
	}

	CloseHandle(hFile);
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
	g_iCvarCSS			= GetConVarInt(g_hCvarCSS);
	g_iCvarGlow			= GetConVarInt(g_hCvarGlow);
	g_iCvarGlowCol		= GetColor(g_hCvarGlowCol);
	g_iCvarRandom		= GetConVarInt(g_hCvarRandom);

	g_iCvarMaxGun		= GetConVarInt(g_hCvarMaxGun);
	g_iCvarMaxPistol	= GetConVarInt(g_hCvarMaxPistol);
	g_iCvarMaxItem		= GetConVarInt(g_hCvarMaxItem);

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

	// Retrieve how many anymore weapons to display
	new iCount = KvGetNum(hFile, "num", 0);
	if( iCount == 0 )
	{
		CloseHandle(hFile);
		return;
	}

	// Spawn only a select few Gun Cabinets?
	new iIndexes[MAX_SPAWNS+1];
	if( iCount > MAX_SPAWNS )
		iCount = MAX_SPAWNS;


	// Spawn saved Gun Cabinets or create random
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
	new index, preset;

	for( new i = 1; i <= iCount; i++ )
	{
		if( iRandom != -1 ) index = iIndexes[i-1];
		else index = i;

		IntToString(index, sTemp, sizeof(sTemp));

		if( KvJumpToKey(hFile, sTemp) )
		{
			KvGetVector(hFile, "ang", vAng);
			KvGetVector(hFile, "pos", vPos);
			preset = KvGetNum(hFile, "preset");

			if( vPos[0] == 0.0 && vPos[1] == 0.0 && vPos[2] == 0.0 ) // Should never happen...
				LogError("Error: 0,0,0 origin. Iteration=%d. Index=%d. Random=%d. Count=%d.", i, index, iRandom, iCount);
			else
				CreateSpawn(vPos, vAng, index, preset-1);
			KvGoBack(hFile);
		}
	}

	CloseHandle(hFile);
}



// ====================================================================================================
//					CREATE SPAWN
// ====================================================================================================
CreateSpawn(const Float:vOrigin[3], const Float:vAngles[3], index, preset)
{
	if( g_iSpawnCount >= MAX_SPAWNS )
		return;

	if( preset + 1 > MAX_PRESETS ) // preset starts from 0 so >= matches 7 (default)
	{
		LogError("Cannot spawn index '%d' which wants to load preset '%d', maximum presets set to '%d', recompile the plugin changing MAX_PRESETS to increase or fix your config.", index, preset + 1, MAX_PRESETS);
		return;
	}

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

	new entity = CreateEntityByName("prop_dynamic_override");
	DispatchKeyValue(entity, "solid", "0");
	SetEntityModel(entity, MODEL_CABINET);
	TeleportEntity(entity, vOrigin, vAngles, NULL_VECTOR);
	DispatchSpawn(entity);
	g_iSpawns[iSpawnIndex][0] = EntIndexToEntRef(entity);
	g_iSpawns[iSpawnIndex][1] = index;

	if( g_iCvarGlow )
	{
		SetEntProp(entity, Prop_Send, "m_nGlowRange", g_iCvarGlow);
		SetEntProp(entity, Prop_Send, "m_iGlowType", 1);
		SetEntProp(entity, Prop_Send, "m_glowColorOverride", g_iCvarGlowCol);
		AcceptEntityInput(entity, "StartGlowing");
	}


	decl Float:vPos[3], Float:vAng[3];

	// ROOF
	vPos = vOrigin;
	vAng = vAngles;
	vPos[2] += 78.0;
	entity = CreateEntityByName("prop_dynamic_override");
	DispatchKeyValue(entity, "solid", "6");
	SetEntityModel(entity, MODEL_CRATE);
	TeleportEntity(entity, vPos, vAng, NULL_VECTOR);
	SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
	SetEntityRenderColor(entity, 0, 0, 0, 0);
	DispatchSpawn(entity);
	g_iDoors[iSpawnIndex][0] = EntIndexToEntRef(entity);

	// BACK
	vPos = vOrigin;
	vAng = vAngles;
	vPos[2] += 40.0;
	MoveForward(vPos, vAng, vPos, -12.0);
	vAng[0] += 90.0;
	entity = CreateEntityByName("prop_dynamic_override");
	DispatchKeyValue(entity, "solid", "6");
	SetEntityModel(entity, MODEL_CRATE);
	TeleportEntity(entity, vPos, vAng, NULL_VECTOR);
	SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
	SetEntityRenderColor(entity, 0, 0, 0, 0);
	DispatchSpawn(entity);
	g_iDoors[iSpawnIndex][1] = EntIndexToEntRef(entity);

	// RIGHT
	vPos = vOrigin;
	vAng = vAngles;
	vPos[2] += 40.0;
	MoveSideway(vPos, vAng, vPos, -23.0);
	vAng[2] += 90.0;
	entity = CreateEntityByName("prop_dynamic_override");
	DispatchKeyValue(entity, "solid", "6");
	SetEntityModel(entity, MODEL_CRATE);
	TeleportEntity(entity, vPos, vAng, NULL_VECTOR);
	SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
	SetEntityRenderColor(entity, 0, 0, 0, 0);
	DispatchSpawn(entity);
	g_iDoors[iSpawnIndex][2] = EntIndexToEntRef(entity);

	// LEFT
	vPos = vOrigin;
	vAng = vAngles;
	vPos[2] += 40.0;
	MoveSideway(vPos, vAng, vPos, 23.0);
	vAng[2] += 90.0;
	entity = CreateEntityByName("prop_dynamic_override");
	DispatchKeyValue(entity, "solid", "6");
	SetEntityModel(entity, MODEL_CRATE);
	SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
	SetEntityRenderColor(entity, 0, 0, 0, 0);
	TeleportEntity(entity, vPos, vAng, NULL_VECTOR);
	DispatchSpawn(entity);
	g_iDoors[iSpawnIndex][3] = EntIndexToEntRef(entity);


	// ARRAYS
	new iGuns[10];
	new iPist[4];
	new iItem[2];

	// MODEL TYPE
	for( new slot = 0; slot < 10; slot++ )
		iGuns[slot] = g_iPresets[preset][slot];
	for( new slot = 10; slot < 14; slot++ )
		iPist[slot-10] = g_iPresets[preset][slot];
	for( new slot = 14; slot < 16; slot++ )
		iItem[slot-14] = g_iPresets[preset][slot];

	// INDEX HOLDER
	new iAmGuns[10];
	new iAmPist[4];
	new iAmItem[2];

	// VALID COUNT
	new iCountGun;
	new iCountPis;
	new iCountIte;

	// VALIDATE AND PUSH INDEX HOLDER
	for( new i = 0; i < 10; i++ )
		if( iGuns[i] != 0 ) iAmGuns[iCountGun++] = i;
	for( new i = 0; i < 4; i++ )
		if( iPist[i] != 0 ) iAmPist[iCountPis++] = i;
	for( new i = 0; i < 2; i++ )
		if( iItem[i] != 0 ) iAmItem[iCountIte++] = i;

	new count, dex;
	if( iCountGun && g_iCvarMaxGun )
	{
		SortIntegers(iAmGuns, iCountGun, Sort_Random);
	
		if( g_iCvarMaxGun > iCountGun ) count = iCountGun;
		else count = g_iCvarMaxGun;

		for( new x = 0; x < count; x++ )
		{
			dex = iAmGuns[x];
			CreateWeapon(iSpawnIndex, dex, iGuns[dex] -1, vOrigin, vAngles);
		}
	}

	if( iCountPis && g_iCvarMaxPistol )
	{
		SortIntegers(iAmPist, iCountPis, Sort_Random);
	
		if( g_iCvarMaxPistol > iCountPis ) count = iCountPis;
		else count = g_iCvarMaxPistol;

		for( new x = 0; x < count; x++ )
		{
			dex = iAmPist[x];
			CreateWeapon(iSpawnIndex, dex + 10, iPist[dex] -1, vOrigin, vAngles);
		}
	}

	if( iCountIte && g_iCvarMaxItem )
	{
		SortIntegers(iAmItem, iCountIte, Sort_Random);
	
		if( g_iCvarMaxItem > iCountIte ) count = iCountIte;
		else count = g_iCvarMaxItem;

		for( new x = 0; x < count; x++ )
		{
			dex = iAmItem[x];
			CreateWeapon(iSpawnIndex, dex + 14, iItem[dex] -1, vOrigin, vAngles);
		}
	}


	// SPAWN ALL
	// new model;
	// for( new slot = 0; slot < MAX_SLOTS; slot++ )
	// {
		// model = g_iPresets[preset][slot];
		// if( model != 0 )
		// {
			// CreateWeapon(iSpawnIndex, slot, model -1, vOrigin, vAngles);
		// }
	// }

	g_iSpawnCount++;
}

public SortFunc(x[], y[], array[][], Handle:data)
{
	if( x[1] > y[1])
		return -1;
	else if (x[1] < y[1])
		return 1;
	return 0;
}

CreateWeapon(index, slot, model, const Float:vOrigin[3], const Float:vAngles[3])
{
	// if( position < 4 ) model = 5;

	decl String:classname[64];
	if( g_bLeft4Dead2 )
		strcopy(classname, sizeof(classname), g_sWeapons2[model]);
	else
		strcopy(classname, sizeof(classname), g_sWeapons[model]);


	new entity_weapon = -1;
	entity_weapon = CreateEntityByName(classname);
	if( entity_weapon == -1 )
	{
		LogError("Failed to create entity '%s'", classname);
		return -1;
	}

	DispatchKeyValue(entity_weapon, "solid", "6");
	if( g_bLeft4Dead2 )
		DispatchKeyValue(entity_weapon, "model", g_sWeaponModels2[model]);
	else
		DispatchKeyValue(entity_weapon, "model", g_sWeaponModels[model]);
	DispatchKeyValue(entity_weapon, "rendermode", "3");
	DispatchKeyValue(entity_weapon, "disableshadows", "1");

	decl Float:vPos[3], Float:vAng[3];

	vPos = vOrigin;
	vAng = vAngles;

	new fix;
	if( slot < 10 )
	{
		if( g_bLeft4Dead2 )
		{
			if( strcmp("weapon_grenade_launcher", g_sWeapons2[model]) == 0 )	fix = 1;
			else if( strcmp("weapon_rifle_m60", g_sWeapons2[model]) == 0 )		fix = 2;
		}

		vPos = vOrigin;
		vAng = vAngles;

		if( fix == 1 )
		{
			vPos[2] += 16.0;
		} 
		else if( fix == 2 )
		{
			vPos[2] += 23.0;
			MoveForward(vPos, vAng, vPos, 1.0);
		} else {
			vPos[2] += 13.0;
		}

		if( g_bLeft4Dead2 )
		{
			if( strcmp("weapon_shotgun_chrome", g_sWeapons2[model]) == 0 )
			{
				MoveForward(vPos, vAng, vPos, 3.0);
				vPos[2] += 2.0;
			}
			else if( strcmp("weapon_pumpshotgun", g_sWeapons2[model]) == 0 )
			{
				MoveForward(vPos, vAng, vPos, 5.0);
				vPos[2] += 2.0;
			}
		} else {
			if( strcmp("weapon_shotgun_chrome", g_sWeapons[model]) == 0 )
			{
				MoveForward(vPos, vAng, vPos, 3.0);
				vPos[2] += 2.0;
			}
			else if( strcmp("weapon_pumpshotgun", g_sWeapons[model]) == 0 )
			{
				MoveForward(vPos, vAng, vPos, 5.0);
				vPos[2] += 2.0;
			}
		}
	}

	switch( slot )
	{
		case 0:
		{
			// RACK #1
			MoveForward(vPos, vAng, vPos, -0.1);
			MoveSideway(vPos, vAng, vPos, 19.0);
		}

		case 1:
		{
			// RACK #2
			MoveForward(vPos, vAng, vPos, -0.1);
			MoveSideway(vPos, vAng, vPos, 15.5);
		}

		case 2:
		{
			// RACK #3
			MoveForward(vPos, vAng, vPos, -0.1);
			MoveSideway(vPos, vAng, vPos, 11.25);
		}

		case 3:
		{
			// RACK #4
			MoveForward(vPos, vAng, vPos, 1.0);
			MoveSideway(vPos, vAng, vPos, 7.7);
		}

		case 4:
		{
			// RACK #5
			MoveForward(vPos, vAng, vPos, 1.0);
			MoveSideway(vPos, vAng, vPos, 4.0);
		}

		case 5:
		{
			// RACK #6
			MoveForward(vPos, vAng, vPos, 1.0);
			MoveSideway(vPos, vAng, vPos, 0.4);
		}

		case 6:
		{
			// RACK #7
			MoveForward(vPos, vAng, vPos, -5.5);
			MoveSideway(vPos, vAng, vPos, -4.5);
		}

		case 7:
		{
			// RACK #8
			MoveForward(vPos, vAng, vPos, -5.4);
			MoveSideway(vPos, vAng, vPos, -8.4);
		}

		case 8:
		{
			// RACK #9
			MoveForward(vPos, vAng, vPos, -5.4);
			MoveSideway(vPos, vAng, vPos, -12.05);
		}

		case 9:
		{
			// RACK #10
			MoveForward(vPos, vAng, vPos, -5.4);
			MoveSideway(vPos, vAng, vPos, -15.8);
		}

		case 10:
		{
			// RACK PISTOL #1 - TL
			vPos = vOrigin;
			vAng = vAngles;
			if( g_bLeft4Dead2 && strcmp("weapon_pistol_magnum", g_sWeapons2[model]) == 0 )
			{
				vPos[2] += 54.0;
				MoveForward(vPos, vAng, vPos, -10.0);
				MoveSideway(vPos, vAng, vPos, 9.0);
				vAng[1] -= 90.0;
			} else {
				vPos[2] += 56.0;
				MoveForward(vPos, vAng, vPos, -10.0);
				MoveSideway(vPos, vAng, vPos, 8.0);
				vAng[1] -= 90.0;
			}
		}

		case 11:
		{
			// RACK PISTOL #2 - BL
			vPos = vOrigin;
			vAng = vAngles;
			if( g_bLeft4Dead2 && strcmp("weapon_pistol_magnum", g_sWeapons2[model]) == 0 )
			{
				vPos[2] += 45.3;
				MoveForward(vPos, vAng, vPos, -10.0);
				MoveSideway(vPos, vAng, vPos, 9.0);
				vAng[1] -= 90.0;
			} else {
				vPos[2] += 48.0;
				MoveForward(vPos, vAng, vPos, -10.0);
				MoveSideway(vPos, vAng, vPos, 8.0);
				vAng[1] -= 90.0;
			}
		}

		case 12:
		{
			// RACK PISTOL #3 - TR
			vPos = vOrigin;
			vAng = vAngles;
			if( g_bLeft4Dead2 && strcmp("weapon_pistol_magnum", g_sWeapons2[model]) == 0 )
			{
				vPos[2] += 54.0;
				MoveForward(vPos, vAng, vPos, -10.0);
				MoveSideway(vPos, vAng, vPos, -6.0);
				vAng[1] -= 90.0;
			} else {
				vPos[2] += 56.0;
				MoveForward(vPos, vAng, vPos, -10.0);
				MoveSideway(vPos, vAng, vPos, -7.5);
				vAng[1] -= 90.0;
			}
		}

		case 13:
		{
			// RACK PISTOL #4 - BR
			vPos = vOrigin;
			vAng = vAngles;
			if( g_bLeft4Dead2 && strcmp("weapon_pistol_magnum", g_sWeapons2[model]) == 0 )
			{
				vPos[2] += 45.3;
				MoveForward(vPos, vAng, vPos, -10.0);
				MoveSideway(vPos, vAng, vPos, -6.0);
				vAng[1] -= 90.0;
			} else {
				vPos[2] += 48.0;
				MoveForward(vPos, vAng, vPos, -10.0);
				MoveSideway(vPos, vAng, vPos, -7.5);
				vAng[1] -= 90.0;
			}
		}

		case 14:
		{
			// ITEM #1 BOTTOM
			if( (!g_bLeft4Dead2 && strcmp("weapon_first_aid_kit", g_sWeapons[model]) == 0 )
				||
				(g_bLeft4Dead2 && (
				strcmp("weapon_first_aid_kit", g_sWeapons2[model]) == 0 ||
				strcmp("weapon_upgradepack_explosive", g_sWeapons2[model]) == 0 ||
				strcmp("weapon_upgradepack_incendiary", g_sWeapons2[model]) == 0
				))
			)
			{
				vPos = vOrigin;
				vAng = vAngles;
				vPos[2] += 45.0;
				MoveForward(vPos, vAng, vPos, -9.0);
				MoveSideway(vPos, vAng, vPos, -18.5);
				vAng[1] += 180.0;
				vAng[2] -= 90.0;
			} else if( (!g_bLeft4Dead2 && strcmp("weapon_molotov", g_sWeapons[model]) == 0)
				||
				(g_bLeft4Dead2 && strcmp("weapon_molotov", g_sWeapons2[model]) == 0)
			)
			{
				vPos = vOrigin;
				vAng = vAngles;
				vPos[2] += 45.0;
				MoveForward(vPos, vAng, vPos, -10.0);
				MoveSideway(vPos, vAng, vPos, -15.0);
				// vAng[1] -= 90.0;
			} else if( g_bLeft4Dead2 && strcmp("weapon_defibrillator", g_sWeapons2[model]) == 0 )
			{
				vPos = vOrigin;
				vAng = vAngles;
				vPos[2] += 45.0;
				MoveForward(vPos, vAng, vPos, -11.0);
				MoveSideway(vPos, vAng, vPos, -14.5);
				vAng[0] += 190.0;
				vAng[1] -= 90.0;
				vAng[2] -= 90.0;
			} else if( strcmp("weapon_pain_pills", g_sWeapons2[model]) == 0 || (g_bLeft4Dead2 && strcmp("weapon_adrenaline", g_sWeapons2[model]) == 0) )
			{
				vPos = vOrigin;
				vAng = vAngles;
				vPos[2] += 45.0;
				MoveForward(vPos, vAng, vPos, -10.0);
				MoveSideway(vPos, vAng, vPos, -14.5);
				vAng[1] += 180.0;
			} else {
				vPos = vOrigin;
				vAng = vAngles;
				vPos[2] += 45.0;
				MoveForward(vPos, vAng, vPos, -10.0);
				MoveSideway(vPos, vAng, vPos, -15.0);
				vAng[1] -= 90.0;
			}
		}

		case 15:
		{
			// ITEM #2 TOP
			if( (!g_bLeft4Dead2 && strcmp("weapon_first_aid_kit", g_sWeapons[model]) == 0)
				||
				(g_bLeft4Dead2 && strcmp("weapon_first_aid_kit", g_sWeapons2[model]) == 0)
			)
			{
				vPos = vOrigin;
				vAng = vAngles;
				vPos[2] += 63.0;
				MoveForward(vPos, vAng, vPos, -3.0);
				MoveSideway(vPos, vAng, vPos, -12.0);
				vAng[1] += 180.0;
			}
			else
			if( (!g_bLeft4Dead2 && strcmp("weapon_molotov", g_sWeapons[model]) == 0)
				||
				(g_bLeft4Dead2 && strcmp("weapon_molotov", g_sWeapons2[model]) == 0)
			)
			{
				vPos = vOrigin;
				vAng = vAngles;
				vPos[2] += 64.5;
				MoveForward(vPos, vAng, vPos, -1.0);
				MoveSideway(vPos, vAng, vPos, -14.0);
				vAng[0] -= 90.0;
				vAng[1] += 90.0;
			}
			else if(
				(!g_bLeft4Dead2 && strcmp("weapon_first_aid_kit", g_sWeapons[model]) == 0) ||
				(g_bLeft4Dead2 && (
				strcmp("weapon_defibrillator", g_sWeapons2[model]) == 0 ||
				strcmp("weapon_adrenaline", g_sWeapons2[model]) == 0 ||
				strcmp("weapon_upgradepack_explosive", g_sWeapons2[model]) == 0 ||
				strcmp("weapon_upgradepack_incendiary", g_sWeapons2[model]) == 0
				))
			)
			{
				vPos = vOrigin;
				vAng = vAngles;
				vPos[2] += 63.0;
				MoveForward(vPos, vAng, vPos, -3.0);
				MoveSideway(vPos, vAng, vPos, -12.0);
			}
			else if(
				(!g_bLeft4Dead2 && strcmp("weapon_pain_pills", g_sWeapons[model]) == 0)
				||
				(g_bLeft4Dead2 && strcmp("weapon_pain_pills", g_sWeapons2[model]) == 0)
			)
			{
				vPos = vOrigin;
				vAng = vAngles;
				vPos[2] += 63.0;
				MoveForward(vPos, vAng, vPos, -3.0);
				MoveSideway(vPos, vAng, vPos, -12.0);
				vAng[1] += 150.0;
			} else {
				vPos = vOrigin;
				vAng = vAngles;
				vPos[2] += 68.0;
				MoveForward(vPos, vAng, vPos, -3.0);
				MoveSideway(vPos, vAng, vPos, -12.0);
			}
		}
	}

	if( slot < 10 )
	{
		if( fix == 2 )
		{
			vAng = vAngles;
			vAng[0] -= 110.0;
			vAng[2] -= 180.0;
		} else {
			vAng[0] -= 110.0;
			vAng[2] -= 180.0;
		}
	} else {
		if( g_bLeft4Dead2 && slot == 14 && strcmp("weapon_adrenaline", g_sWeapons2[model]) == 0 )
		{
			vAng[1] += 180.0;
			vAng[2] -= 90.0;
		}
	}

	TeleportEntity(entity_weapon, vPos, vAng, NULL_VECTOR);
	DispatchSpawn(entity_weapon);

	new ammo;

	if( !g_bLeft4Dead2 ) g_iAmmoAutoShot = g_iAmmoShotgun;

	if( strcmp(classname, "weapon_smg") == 0 )															ammo = g_iAmmoSmg;
	else if( strcmp(classname, "weapon_rifle") == 0 || strcmp(classname, "smg") == 0 )					ammo = g_iAmmoRifle;
	else if( strcmp(classname, "weapon_pumpshotgun") == 0 )												ammo = g_iAmmoShotgun;
	else if( strcmp(classname, "weapon_autoshotgun") == 0 )												ammo = g_iAmmoAutoShot;
	else if( strcmp(classname, "weapon_hunting_rifle") == 0 )											ammo = g_iAmmoHunting;
	else if( ammo == 0 && g_bLeft4Dead2 )
	{
		if( strcmp(classname, "weapon_smg_mp5") == 0 || strcmp(classname, "weapon_smg_silenced") == 0 )		ammo = g_iAmmoSmg;
		else if( strcmp(classname, "weapon_rifle_desert") == 0 ||
				strcmp(classname, "weapon_rifle_ak47") == 0 ||
				strcmp(classname, "weapon_rifle_sg552") == 0 )												ammo = g_iAmmoRifle;
		else if( strcmp(classname, "weapon_shotgun_chrome") == 0 )											ammo = g_iAmmoShotgun;
		else if( strcmp(classname, "weapon_shotgun_spas") == 0 )											ammo = g_iAmmoAutoShot;
		else if( strcmp(classname, "weapon_grenade_launcher") == 0 )										ammo = g_iAmmoChainsaw;
		else if( strcmp(classname, "weapon_rifle_m60") == 0 )												ammo = g_iAmmoM60;
		else if( strcmp(classname, "weapon_chainsaw") == 0 )												ammo = g_iAmmoGL;
		else if( strcmp(classname, "weapon_sniper_awp") == 0 ||
				strcmp(classname, "weapon_sniper_military") == 0 ||
				strcmp(classname, "weapon_sniper_scout") == 0 )												ammo = g_iAmmoSniper;
	}

	// SetEntProp(entity_weapon, Prop_Send, "m_iGlowType", 2);
	// SetEntProp(entity_weapon, Prop_Send, "m_glowColorOverride", 2);
	SetEntProp(entity_weapon, Prop_Send, "m_iExtraPrimaryAmmo", ammo, 4);
	SetEntityMoveType(entity_weapon, MOVETYPE_NONE);

	g_iSpawns[index][slot+2] = EntIndexToEntRef(entity_weapon);

	return entity_weapon;
}

MoveForward(const Float:vPos[3], const Float:vAng[3], Float:vReturn[3], Float:fDistance)
{
	decl Float:vDir[3];
	GetAngleVectors(vAng, vDir, NULL_VECTOR, NULL_VECTOR);
	vReturn = vPos;
	vReturn[0] += vDir[0] * fDistance;
	vReturn[1] += vDir[1] * fDistance;
	vReturn[2] += vDir[2] * fDistance;
}

MoveSideway(const Float:vPos[3], const Float:vAng[3], Float:vReturn[3], Float:fDistance)
{
	decl Float:vDir[3];
	GetAngleVectors(vAng, NULL_VECTOR, vDir, NULL_VECTOR);
	vReturn = vPos;
	vReturn[0] += vDir[0] * fDistance;
	vReturn[1] += vDir[1] * fDistance;
	vReturn[2] += vDir[2] * fDistance;
}



// ====================================================================================================
//					COMMANDS
// ====================================================================================================
//					sm_gun_cabinet
// ====================================================================================================
public ListMenuHandler(Handle:menu, MenuAction:action, client, index)
{
	if( action == MenuAction_Select )
	{
		decl String:sTemp[4];
		GetMenuItem(menu, index, sTemp, sizeof(sTemp));
		index = StringToInt(sTemp);
		
		if( g_iSave[client] == 0 )
		{
			CmdCabinetTempMenu(client, index);
		} else {
			CmdCabinetSaveMenu(client, index);
		}
		

		DisplayMenu(g_hMenuList, client, MENU_TIME_FOREVER);
	}
}
public Action:CmdCabinetTemp(client, args)
{
	if( !client )
	{
		ReplyToCommand(client, "[Gun Cabinet] Commands may only be used in-game on a dedicated server..");
		return Plugin_Handled;
	}
	else if( g_iSpawnCount >= MAX_SPAWNS )
	{
		PrintToChat(client, "%sError: Cannot add anymore Gun Cabinets. Used: (\x05%d/%d\x01).", CHAT_TAG, g_iSpawnCount, MAX_SPAWNS);
		return Plugin_Handled;
	}
	
	
	g_iSave[client] = 0;
   
	DisplayMenu(g_hMenuList, client, MENU_TIME_FOREVER);

	return Plugin_Handled;
}

CmdCabinetTempMenu(client, preset)
{
	if( !client )
	{
		ReplyToCommand(client, "[Weapon Spawn] Commands may only be used in-game on a dedicated server..");
		return;
	}
	else if( g_iSpawnCount >= MAX_SPAWNS )
	{
		PrintToChat(client, "%sError: Cannot add anymore Gun Cabinets. Used: (\x05%d/%d\x01).", CHAT_TAG, g_iSpawnCount, MAX_SPAWNS);
		return;
	}

	new Float:vPos[3], Float:vAng[3];
	if( !SetTeleportEndPoint(client, vPos, vAng) )
	{
		PrintToChat(client, "%sCannot place weapon, please try again.", CHAT_TAG);
		return;
	}
		
	CreateSpawn(vPos, vAng, 0, preset-1);
	return;
}

// ====================================================================================================
//					sm_gun_cabinet_save
// ====================================================================================================

public Action:CmdCabinetSave(client, args)
{
	if( !client )
	{
		ReplyToCommand(client, "[Gun Cabinet] Commands may only be used in-game on a dedicated server..");
		return Plugin_Handled;
	}
	else if( g_iSpawnCount >= MAX_SPAWNS )
	{
		PrintToChat(client, "%sError: Cannot add anymore Gun Cabinets. Used: (\x05%d/%d\x01).", CHAT_TAG, g_iSpawnCount, MAX_SPAWNS);
		return Plugin_Handled;
	}
	g_iSave[client] = 1;
	DisplayMenu(g_hMenuList, client, MENU_TIME_FOREVER);

	return Plugin_Handled;
}



CmdCabinetSaveMenu(client, preset)
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
		PrintToChat(client, "%sError: Cannot read the Gun Cabinet config, assuming empty file. (\x05%s\x01).", CHAT_TAG, sPath);
	}

	// Check for current map in the config
	decl String:sMap[64];
	GetCurrentMap(sMap, 64);
	if( !KvJumpToKey(hFile, sMap, true) )
	{
		PrintToChat(client, "%sError: Failed to add map to Gun Cabinet spawn config.", CHAT_TAG);
		CloseHandle(hFile);
		return;
	}

	// Retrieve how many Gun Cabinets are saved
	new iCount = KvGetNum(hFile, "num", 0);
	if( iCount >= MAX_SPAWNS )
	{
		PrintToChat(client, "%sError: Cannot add anymore Gun Cabinets. Used: (\x05%d/%d\x01).", CHAT_TAG, iCount, MAX_SPAWNS);
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
		// Set player Gun Cabinet spawn location
		if( !SetTeleportEndPoint(client, vPos, vAng) )
		{
			PrintToChat(client, "%sCannot place Gun Cabinet, please try again.", CHAT_TAG);
			CloseHandle(hFile);
			return;
		}

		// Save angle / origin
		KvSetVector(hFile, "ang", vAng);
		KvSetVector(hFile, "pos", vPos);
		KvSetNum(hFile, "preset", preset);

		CreateSpawn(vPos, vAng, iCount, preset-1);

		// Save cfg
		KvRewind(hFile);
		KeyValuesToFile(hFile, sPath);

		PrintToChat(client, "%s(\x05%d/%d\x01) - Saved at pos:[\x05%f %f %f\x01] ang:[\x05%f %f %f\x01]", CHAT_TAG, iCount, MAX_SPAWNS, vPos[0], vPos[1], vPos[2], vAng[0], vAng[1], vAng[2]);
	}
	else
		PrintToChat(client, "%s(\x05%d/%d\x01) - Failed to save Gun Cabinet.", CHAT_TAG, iCount, MAX_SPAWNS);

	CloseHandle(hFile);
}

// ====================================================================================================
//					sm_gun_cabinet_del
// ====================================================================================================
public Action:CmdCabinetDel(client, args)
{
	if( !g_bCvarAllow )
	{
		ReplyToCommand(client, "[Gun Cabinet] Plugin turned off.");
		return Plugin_Handled;
	}

	if( !client )
	{
		ReplyToCommand(client, "[Gun Cabinet] Commands may only be used in-game on a dedicated server..");
		return Plugin_Handled;
	}

	new entity = GetClientAimTarget(client, false);
	if( entity == -1 ) return Plugin_Handled;
	entity = EntIndexToEntRef(entity);

	new cfgindex, index = -1;
	for( new x = 0; x < MAX_SPAWNS; x++ )
	{
		for( new i = 0; i < MAX_DOORS; i++ )
		{
			if( g_iDoors[x][i] == entity )
			{
				index = x;
				break;
			}
		}
	}

	if( index == -1 )
	{
		return Plugin_Handled;
	}

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


	// Load config
	decl String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "%s", CONFIG_SPAWNS);
	if( !FileExists(sPath) )
	{
		PrintToChat(client, "%sError: Cannot find the Gun Cabinet config (\x05%s\x01).", CHAT_TAG, CONFIG_SPAWNS);
		return Plugin_Handled;
	}

	new Handle:hFile = CreateKeyValues("spawns");
	if( !FileToKeyValues(hFile, sPath) )
	{
		PrintToChat(client, "%sError: Cannot load the Gun Cabinet config (\x05%s\x01).", CHAT_TAG, sPath);
		CloseHandle(hFile);
		return Plugin_Handled;
	}

	// Check for current map in the config
	decl String:sMap[64];
	GetCurrentMap(sMap, 64);

	if( !KvJumpToKey(hFile, sMap) )
	{
		PrintToChat(client, "%sError: Current map not in the Gun Cabinet config.", CHAT_TAG);
		CloseHandle(hFile);
		return Plugin_Handled;
	}

	// Retrieve how many Gun Cabinets
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

		PrintToChat(client, "%s(\x05%d/%d\x01) - Gun Cabinet removed from config.", CHAT_TAG, iCount, MAX_SPAWNS);
	}
	else
		PrintToChat(client, "%s(\x05%d/%d\x01) - Failed to remove Gun Cabinet from config.", CHAT_TAG, iCount, MAX_SPAWNS);

	CloseHandle(hFile);
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_gun_cabinet_clear
// ====================================================================================================
public Action:CmdCabinetClear(client, args)
{
	if( !client )
	{
		ReplyToCommand(client, "[Gun Cabinet] Commands may only be used in-game on a dedicated server..");
		return Plugin_Handled;
	}

	ResetPlugin();

	PrintToChat(client, "%s(0/%d) - All Gun Cabinets removed from the map.", CHAT_TAG, MAX_SPAWNS);
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_gun_cabinet_wipe
// ====================================================================================================
public Action:CmdCabinetWipe(client, args)
{
	if( !client )
	{
		ReplyToCommand(client, "[Gun Cabinet] Commands may only be used in-game on a dedicated server..");
		return Plugin_Handled;
	}

	decl String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "%s", CONFIG_SPAWNS);
	if( !FileExists(sPath) )
	{
		PrintToChat(client, "%sError: Cannot find the Gun Cabinet config (\x05%s\x01).", CHAT_TAG, sPath);
		return Plugin_Handled;
	}

	// Load config
	new Handle:hFile = CreateKeyValues("spawns");
	if( !FileToKeyValues(hFile, sPath) )
	{
		PrintToChat(client, "%sError: Cannot load the Gun Cabinet config (\x05%s\x01).", CHAT_TAG, sPath);
		CloseHandle(hFile);
		return Plugin_Handled;
	}

	// Check for current map in the config
	decl String:sMap[64];
	GetCurrentMap(sMap, 64);

	if( !KvJumpToKey(hFile, sMap, false) )
	{
		PrintToChat(client, "%sError: Current map not in the Gun Cabinet config.", CHAT_TAG);
		CloseHandle(hFile);
		return Plugin_Handled;
	}

	KvDeleteThis(hFile);
	ResetPlugin();

	// Save to file
	KvRewind(hFile);
	KeyValuesToFile(hFile, sPath);
	CloseHandle(hFile);

	PrintToChat(client, "%s(0/%d) - All Gun Cabinets removed from config, add with \x05sm_gun_cabinet_save\x01.", CHAT_TAG, MAX_SPAWNS);
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_gun_cabinet_glow
// ====================================================================================================
public Action:CmdCabinetGlow(client, args)
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
				SetEntProp(ent, Prop_Send, "m_glowColorOverride", 65535);
				SetEntProp(ent, Prop_Send, "m_nGlowRange", 0);
			}
		}
	}
}

// ====================================================================================================
//					sm_gun_cabinet_list
// ====================================================================================================
public Action:CmdCabinetList(client, args)
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
//					sm_gun_cabinet_reload
// ====================================================================================================
public Action:CmdCabinetReload(client, args)
{
	CloseHandle(g_hMenuList);

	for( new preset = 0; preset < MAX_PRESETS; preset++ )
	{
		for( new slot = 0; slot < MAX_SLOTS; slot++ )
		{
			g_iPresets[preset][slot] = 0;
		}
	}

	g_bCvarAllow = false;
	ResetPlugin(true);
	LoadPresets();
	IsAllowed();
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_gun_cabinet_tele
// ====================================================================================================
public Action:CmdCabinetTele(client, args)
{
	if( args == 1 )
	{
		decl String:arg[16];
		GetCmdArg(1, arg, 16);
		new index = StringToInt(arg) - 1;
		if( index > -1 && index < MAX_SPAWNS && IsValidEntRef(g_iSpawns[index][0]) )
		{
			decl Float:vPos[3], Float:vAng[3];
			GetEntPropVector(g_iSpawns[index][0], Prop_Data, "m_vecOrigin", vPos);
			GetEntPropVector(g_iSpawns[index][0], Prop_Send, "m_angRotation", vAng);
			MoveForward(vPos, vAng, vPos, 30.0);
			vPos[2] += 20.0;
			TeleportEntity(client, vPos, NULL_VECTOR, NULL_VECTOR);
			PrintToChat(client, "%sTeleported to %d.", CHAT_TAG, index + 1);
			return Plugin_Handled;
		}

		PrintToChat(client, "%sCould not find index for teleportation.", CHAT_TAG);
	}
	else
		PrintToChat(client, "%sUsage: sm_gun_cabinet_tele <index 1-%d>.", CHAT_TAG, MAX_SPAWNS);
	return Plugin_Handled;
}

// ====================================================================================================
//					MENU ANGLE
// ====================================================================================================
public Action:CmdCabinetAng(client, args)
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
			for( new x = 0; x < MAX_DOORS; x++ )
			{
				entity = g_iDoors[i][x];

				if( entity == aim  )
				{
					entity = g_iSpawns[i][0];

					GetEntPropVector(entity, Prop_Send, "m_angRotation", vAng);

					if( index == 0 ) vAng[0] += 5.0;
					else if( index == 1 ) vAng[1] += 1.0;
					else if( index == 2 ) vAng[2] += 1.0;
					else if( index == 3 ) vAng[0] -= 1.0;
					else if( index == 4 ) vAng[1] -= 1.0;
					else if( index == 5 ) vAng[2] -= 1.0;

					TeleportEntity(entity, NULL_VECTOR, vAng, NULL_VECTOR);

					PrintToChat(client, "%sNew angles: %f %f %f", CHAT_TAG, vAng[0], vAng[1], vAng[2]);
					break;
				}
			}
		}
	}
}

// ====================================================================================================
//					MENU ORIGIN
// ====================================================================================================
public Action:CmdCabinetPos(client, args)
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
			for( new x = 0; x < MAX_DOORS; x++ )
			{
				entity = g_iDoors[i][x];

				if( entity == aim  )
				{
					entity = g_iSpawns[i][0];

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
}

SaveData(client)
{
	new entity = GetClientAimTarget(client, false);
	if( entity == -1 )
		return;

	entity = EntIndexToEntRef(entity);

	new cfgindex, index = -1;
	for( new x = 0; x < MAX_SPAWNS; x++ )
	{
		for( new i = 0; i < MAX_DOORS; i++ )
		{
			if( g_iDoors[x][i] == entity )
			{
				entity = g_iSpawns[x][0];
				cfgindex = g_iSpawns[x][1];
				index = x;
				break;
			}
		}
	}

	if( index == -1 )
	{
		PrintToChat(client, "%sError: Cannot find the target.", CHAT_TAG, CONFIG_SPAWNS);
		return;
	}

	// Load config
	decl String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "%s", CONFIG_SPAWNS);
	if( !FileExists(sPath) )
	{
		PrintToChat(client, "%sError: Cannot find the Gun Cabinet config (\x05%s\x01).", CHAT_TAG, CONFIG_SPAWNS);
		return;
	}

	new Handle:hFile = CreateKeyValues("spawns");
	if( !FileToKeyValues(hFile, sPath) )
	{
		PrintToChat(client, "%sError: Cannot load the Gun Cabinet config (\x05%s\x01).", CHAT_TAG, sPath);
		CloseHandle(hFile);
		return;
	}

	// Check for current map in the config
	decl String:sMap[64];
	GetCurrentMap(sMap, 64);

	if( !KvJumpToKey(hFile, sMap) )
	{
		PrintToChat(client, "%sError: Current map not in the Gun Cabinet config.", CHAT_TAG);
		CloseHandle(hFile);
		return;
	}

	decl Float:vAng[3], Float:vPos[3], String:sTemp[32];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vPos);
	GetEntPropVector(entity, Prop_Send, "m_angRotation", vAng);

	IntToString(cfgindex, sTemp, sizeof(sTemp));
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
		AddMenuItem(g_hMenuAng, "", "X + 1.0");
		AddMenuItem(g_hMenuAng, "", "Y + 1.0");
		AddMenuItem(g_hMenuAng, "", "Z + 1.0");
		AddMenuItem(g_hMenuAng, "", "X - 1.0");
		AddMenuItem(g_hMenuAng, "", "Y - 1.0");
		AddMenuItem(g_hMenuAng, "", "Z - 1.0");
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
	if( all )
	for( new i = 0; i < MAX_SPAWNS; i++ )
		RemoveSpawn(i);
	g_bLoaded = false;
	g_iSpawnCount = 0;
	g_iRoundStart = 0;
	g_iPlayerSpawn = 0;


}

RemoveSpawn(index)
{
	new entity, client;

	for( new x = 0; x < MAX_SLOTS + 2; x++ )
	{
		entity = g_iSpawns[index][x];
		g_iSpawns[index][x] = 0;

		if( x != 1 && IsValidEntRef(entity) )
		{
			if( x > 1 )
			{
				client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
				if( client < 0 || client > MaxClients || !IsClientInGame(client) )
				{
					AcceptEntityInput(entity, "kill");
				}
			} else {
				AcceptEntityInput(entity, "kill");
			}
		}
	}

	for( new i = 0; i < MAX_DOORS; i++ )
	{
		entity = g_iDoors[index][i];
		g_iDoors[index][i] = 0;
		if( IsValidEntRef(entity) )	AcceptEntityInput(entity, "kill");
	}
	g_iSpawnCount--;

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