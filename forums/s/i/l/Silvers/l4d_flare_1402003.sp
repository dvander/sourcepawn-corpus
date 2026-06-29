#define PLUGIN_VERSION 		"1.0.3"

/*=======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] Flare and Light Package
*	Author	:	SilverShot
*	Version	:	1.0.3
*	Descrp	:	Creates flares, attaches an extra flashlight to survivors and converts the grenade launcher into a flare gun.
*	Link	:	http://forums.alliedmods.net/showthread.php?t=148760

========================================================================================
	Change Log:

*	1.0.3
	- Added "l4d_flare_gun_bounce 3" to make grenade launcher projectiles stick to surfaces.
	- Added "l4d_flare_gun_bounce 4" to do the same as above and explode after "l4d_flare_gun_time".
	- Added a new cvar to change the grenade launcher projectile bounciness (l4d_flare_gun_elasticity).

*	1.0.2
	- Fixed the Flare Gun hint text displaying when the game mode is disallowed.

*	1.0.2
	- Fixed the Flare Gun hint text displaying when the game mode is disallowed.

*	1.0.1
	- Fixed Flare Gun hint text displaying when Flare Gun is off.
	- Change the default Flare Gun Speed (l4d_flare_gun_speed) cvar from 600 to 1000.

*	1.0
	- Initial release.

========================================================================================

	This plugin was made using source code from the following plugins.
	If I have used your code and not credited you, please let me know.

*	Thanks to "honorcode23" for "PrecacheParticle" function
	http://forums.alliedmods.net/showpost.php?p=1314807&postcount=21

*	Thanks to "DJ_WEST" for "[L4D/L4D2] Incapped Grenade (Pipe/Molotov/Vomitjar)" - Used for particle effects
	http://forums.alliedmods.net/showthread.php?p=1127479

*	Thanks to "AtomicStryker" for "[L4D & L4D2] Smoker Cloud Damage" - Modified the IsVisibleTo() for GetGroundAngles()
	http://forums.alliedmods.net/showthread.php?p=866613

*	Thanks to "Boikinov" for "[L4D] Left FORT Dead builder" - RotateYaw function to rotate ground flares
	http://forums.alliedmods.net/showthread.php?t=93716

*	Thanks to "pimpinjuice" for a "Proper way to deal damage without extensions" - Used by AtomicStryker below
	http://forums.alliedmods.net/showthread.php?t=111684

*	Thanks to "AtomicStryker" for "[L4D & L4D2] Boomer Splash Damage" - Where the damage code is from
	http://forums.alliedmods.net/showthread.php?t=98794

*	Thanks to "nakashimakun" for "[L4D & L4D2] Kill Counters." - Where the clientprefs code is from
	http://forums.alliedmods.net/showthread.php?t=140000

*	Thanks to "FoxMulder" for "[SNIPPET] Kill Entity in Seconds" - Used to delete flare models (should really use for all entities instead of using timers)
	http://forums.alliedmods.net/showthread.php?t=129135

======================================================================================*/



#pragma semicolon 1

#include <sourcemod>
#include <clientprefs>
#include <sdktools>
#include <sdkhooks>
#include <colors>

// Plugin defines
#define CVAR_FLAGS			FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
#define TAG_CHAT			"\x04[\x05Flare & Light\x04] \x01"
// Flare / Flashlight
#define ATTACH_GRENADE		"grenade"
#define ATTACH_PILLS		"pills"
#define MODEL_FLARE			"models/props_lighting/light_flares.mdl"
#define MODEL_LIGHT			"models/props_lighting/flashlight_dropped_01.mdl"
#define PARTICLE_FLARE		"flare_burning"
#define PARTICLE_FUSE		"weapon_pipebomb_fuse"
// Flare gun
#define MODEL_NADE			"models/w_models/weapons/w_HE_grenade.mdl"
#define MODEL_SPRITE		"models/sprites/glow01.spr"
#define PARTICLE_SMOKE		"RPG_Parent"
#define PARTICLE_SPARKS		"fireworks_sparkshower_01e"
#define PARTICLE_TRAIL		"weapon_grenadelauncher_trail"
#define PROJECTILE			"grenade_launcher_projectile"
// Sound
#define SOUND_CRACKLE		"ambient/fire/fire_small_loop2.wav"



static
	// Attached Flare cvar handles
	Handle:g_hSelfCmdAllow, Handle:g_hSelfCmdFlags, Handle:g_hSelfFuse, Handle:g_hSelfLight, Handle:g_hSelfLColour, Handle:g_hSelfStock,
	// Flashlight cvar handles
	Handle:g_hLightOn, Handle:g_hLightFlags, Handle:g_hLightAlpha, Handle:g_hLightColour,
	// Ground Flare cvar handles
	Handle:g_hGrndCmdAllow, Handle:g_hGrndCmdFlags, Handle:g_hGrndFuse, Handle:g_hGrndLight, Handle:g_hGrndLAlpha, Handle:g_hGrndLColour,
	Handle:g_hGrndSmoke, Handle:g_hGrndSAlpha, Handle:g_hGrndSColour, Handle:g_hGrndSHeight, Handle:g_hGrndStock,
	// Grenade Launcher Flare Gun cvar handles
	Handle:g_hGunAllow,  Handle:g_hGunBounce, Handle:g_hGunElasticity, Handle:g_hGunGravity, Handle:g_hGunHurt, Handle:g_hGunHurtSI,
	Handle:g_hGunLight, Handle:g_hGunLightCols, Handle:g_hGunMaxSpawn, Handle:g_hGunSparks, Handle:g_hGunSpeed, Handle:g_hGunSmoke,
	Handle:g_hGunSprite, Handle:g_hGunSpriteCols, Handle:g_hGunTimeout,
	// Main plugin cvar handles
	Handle:g_hEnable, Handle:g_hHint, Handle:g_hModes, Handle:g_hTime, Handle:g_hIncapped, Handle:g_hIntro, Handle:g_hLockedCols,
	Handle:g_hMaxFlares, Handle:g_hMaxForAdm,

	// Attached Flare / Flashlight cvar variables
	g_iSelfCmdAllow, String:g_sSelfFlags[16], bool:g_bSelfFuse, bool:g_bSelfLight, String:g_sSelfLCols[12], bool:g_bSelfStock,
	// Flashlight
	bool:g_bLightOn, g_iLightAlpha, String:g_sLightCols[12], String:g_sLightFlags[12],
	// Ground Flare cvar variables
	g_iGrndCmdAllow, String:g_sGrndFlags[16], bool:g_bGrndFuse, g_iGrndLight, g_iGrndLAlpha, String:g_sGrndLCols[12], bool:g_bGrndSmokeOn, g_iGrndSAlpha,
	String:g_sGrndSCols[12], g_iGrndSHeight, bool:g_bGrndStock,
	// Grenade Launcher Flare Gun cvar variables
	bool:g_bGunAllow, g_iGunBounce, Float:g_fGunElasticity, Float:g_fGunGravity, g_iGunHurt, g_iGunHurtSI, bool:g_bGunLight, String:g_sGunCols[12],
	g_iGunMaxSpawn, bool:g_bGunSparks, g_iGunSpeed, g_iGunSpeedDefault, g_iGunSmoke, bool:g_bGunSprite, String:g_sSpriteCols[12], Float:g_fGunTimeout,
	// Main plugin cvar variables
	bool:g_bEnabled, bool:g_bHint, Float:g_fTime, g_iIncapped, Float:g_fIntro, bool:g_bLockedCols, g_iMaxFlares, g_iMaxForAdm,

	// Plugin Variables
	Handle:g_hMPGameMode, bool:g_bRoundOver, bool:g_bModeOk, bool:g_bLeft4Dead, g_iGrenadeLimit, g_iFlareCount,
	// Grenade Launcher
	Handle:g_hNadeVelocity, Handle:g_hCookie, bool:g_bBlockHook, bool:g_bBounce[MAXPLAYERS], bool:g_bDisplayed[MAXPLAYERS], Float:g_fLastHurt[MAXPLAYERS],
	// Flashlight arrays
	g_iLightIndex[MAXPLAYERS], g_iModelIndex[MAXPLAYERS], String:g_sPlayerModel[MAXPLAYERS][42],
	// Flare variables
	bool:g_bBlockAutoFlare[MAXPLAYERS], bool:g_bFlareTimeout[MAXPLAYERS], bool:g_bFlareAttached[MAXPLAYERS], g_iAdminMaxFlares[MAXPLAYERS], g_iAttachedFlare[MAXPLAYERS],
	Float:g_fFlareAngle, Handle:g_hFlareTimerHandles[40]; // 40 = 1 (timer handle used to remove flare ents) * 32 (max limit)   +   8 (max timer handles for flare gun)



public Plugin:myinfo =
{
	name = "[L4D & L4D2] Flare and Light Package",
	author = "SilverShot",
	description = "Creates flares, attaches an extra flashlight to survivors and converts the grenade launcher into a flare gun.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=148760"
}



// ====================================================================================================
//					P L U G I N   S T A R T
// ====================================================================================================
public OnPluginStart()
{
	// Game check.
	decl String:sGameName[16];
	GetGameFolderName(sGameName, sizeof(sGameName));

	if( StrEqual(sGameName, "left4dead2", false) ) g_bLeft4Dead = false;
	else if( StrEqual(sGameName, "left4dead", false) ) g_bLeft4Dead = true;
	else SetFailState("Plugin only supports Left4Dead 1 & 2.");

	// Translations
	LoadTranslations("common.phrases");
	LoadTranslations("core.phrases");

	decl String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, PLATFORM_MAX_PATH, "%s", "translations/flare.phrases.txt");
	if( FileExists(sPath) )
		LoadTranslations("flare.phrases");
	else
		SetFailState("Missing required 'translations/flare.phrases.txt', please re-download.");

	// Cvars
	g_hSelfCmdAllow = CreateConVar(	"l4d_flare_attach_cmd_allow",		"2",			"0=Disable sm_self command. 1=Incapped only (not admins). 2=Any time.",		CVAR_FLAGS, true, 0.0, true, 2.0);
	g_hSelfCmdFlags = CreateConVar(	"l4d_flare_attach_cmd_flags",		"",				"Players with these flags may use the sm_flareme command. (Empty = all).",	CVAR_FLAGS );
	g_hSelfFuse = CreateConVar(		"l4d_flare_attach_fuse",			"1",			"Adds the pipebomb fuse particles to the flare.",							CVAR_FLAGS );
	g_hSelfLight = CreateConVar(	"l4d_flare_attach_light_allow",		"1",			"0=Off, 1=Attaches light_dynamic glow to the player.",						CVAR_FLAGS );
	g_hSelfLColour = CreateConVar(	"l4d_flare_attach_light_colour",	"200 20 15",	"Defines the light colour. RGB (red, green, blue) values (0-255).",			CVAR_FLAGS );
	g_hSelfStock = CreateConVar(	"l4d_flare_attach_stock",			"1",			"0=Off, 1=Adds The Sacrifice flare smoke particles.",						CVAR_FLAGS );

	g_hLightOn = CreateConVar(		"l4d_flare_flashlight_allow",		"1",			"0=Off, 1=Attaches a flashlight model and light_dynamic to each survivor.",	CVAR_FLAGS );
	g_hLightAlpha = CreateConVar(	"l4d_flare_flashlight_bright",		"255.0",		"Brightness of the light <10-255> (changes Distance value).",				CVAR_FLAGS, true, 10.0, true, 255.0 );
	g_hLightColour = CreateConVar(	"l4d_flare_flashlight_colour",		"200 20 15",	"Defines the light colour. RGB (red, green, blue) values (0-255).",			CVAR_FLAGS );
	g_hLightFlags = CreateConVar(	"l4d_flare_flashlight_flags",		"",				"Players with these flags may use the sm_light command. (Empty = all).",	CVAR_FLAGS );

	g_hGrndCmdAllow = CreateConVar(	"l4d_flare_ground_cmd_allow",		"2",			"0=Disable sm_flare command. 1=Incapped only (not admins). 2=Any time.",	CVAR_FLAGS );
	g_hGrndCmdFlags = CreateConVar(	"l4d_flare_ground_cmd_flags",		"",				"Players with these flags may use the sm_flare command. Empty = all.",		CVAR_FLAGS );
	g_hGrndFuse = CreateConVar(		"l4d_flare_ground_fuse",			"1",			"Adds the pipebomb fuse particles to the flare.",							CVAR_FLAGS );
	g_hGrndLight = CreateConVar(	"l4d_flare_ground_light_allow",		"1",			"Light glow around flare. 0=Off, 1=light_dynamic, 2=point_spotlight.",		CVAR_FLAGS, true, 0.0, true, 2.0);
	g_hGrndLAlpha = CreateConVar(	"l4d_flare_ground_light_bright",	"255",			"Brightness of the light <10-255>.",										CVAR_FLAGS, true, 10.0, true, 255.0 );
	g_hGrndLColour = CreateConVar(	"l4d_flare_ground_light_colour",	"200 20 15",	"Defines the light colour. RGB (red, green, blue) values (0-255).",			CVAR_FLAGS );
	g_hGrndSmoke = CreateConVar(	"l4d_flare_ground_smoke_allow",		"0",			"0=Off, 1=Adds extra smoke to the flare (env_steam).",						CVAR_FLAGS );
	g_hGrndSAlpha = CreateConVar(	"l4d_flare_ground_smoke_alpha",		"60",			"Transparency of the extra smoke (10-255).",								CVAR_FLAGS, true, 10.0, true, 255.0 );
	g_hGrndSColour = CreateConVar(	"l4d_flare_ground_smoke_colour",	"200 20 15",	"Defines the extra smoke colour. RGB values must be between 0-255.",		CVAR_FLAGS );
	g_hGrndSHeight = CreateConVar(	"l4d_flare_ground_smoke_height",	"100",			"How tall the extra smoke should rise.",									CVAR_FLAGS );
	g_hGrndStock = CreateConVar(	"l4d_flare_ground_stock",			"1",			"0=Off, 1=Adds The Sacrifice flare smoke particles.",						CVAR_FLAGS );

	g_hGunAllow = CreateConVar(		"l4d_flare_gun_allow",				"1",			"0=Off, 1=Converts the Grenade Launcher into a Flare Gun.",					CVAR_FLAGS );
	g_hGunBounce = CreateConVar(	"l4d_flare_gun_bounce",				"1",			"0=Stock, 1=Bounce and ignite, 2=Forced bounce, 3=Stick, 4=Stick&Explode.",	CVAR_FLAGS );
	g_hGunElasticity = CreateConVar("l4d_flare_gun_elasticity",			"1.0",			"Changes the projectile bounciness. Valve default: 1.0.",					CVAR_FLAGS );
	g_hGunGravity = CreateConVar(	"l4d_flare_gun_gravity",			"0.4",			"Changes the projectile gravity, negative numbers make it fly upwards!",	CVAR_FLAGS );
	g_hGunHurt = CreateConVar(		"l4d_flare_gun_hurt",				"15",			"0=Off, Hurt survivors this much and ignite zombies/infected/explosives etc. Bounce cvar must be enabled. This enables the cvar below.",	CVAR_FLAGS, true, 0.0, true, 99.0 );
	g_hGunHurtSI = CreateConVar(	"l4d_flare_gun_hurt_infected",		"30",			"Hurt special infected this much when they touch the flare. As with the above cvar, the damage is limited to twice a second on multiple touches.",	CVAR_FLAGS, true, 1.0, true, 99.0 );
	g_hGunLight = CreateConVar(		"l4d_flare_gun_light",				"1",			"Turn on/off the attached light_dynamic glow.",								CVAR_FLAGS );
	g_hGunLightCols = CreateConVar(	"l4d_flare_gun_light_colour",		"200 20 15",	"Defines the extra light colour. RGB values must be between 0-255.",		CVAR_FLAGS );
	g_hGunMaxSpawn = CreateConVar(	"l4d_flare_gun_max",				"8",			"Limit the total number of simultaneous grenade flares to this many.",		CVAR_FLAGS, true, 1.0, true, 8.0);
	g_hGunSparks = CreateConVar(	"l4d_flare_gun_sparks",				"1",			"Turn on/off the attached firework particle effect.",						CVAR_FLAGS );
	g_hGunSpeed = CreateConVar(		"l4d_flare_gun_speed",				"1000",			"Changes the grenade launcher projectile speed (Valve's default: 1600).",	CVAR_FLAGS );
	g_hGunSmoke = CreateConVar(		"l4d_flare_gun_smoke",				"1",			"0=Off, 1=The Sacrifice flare smoke, 2=Attach RPG smoke (FPS intensive).",	CVAR_FLAGS, true, 0.0, true, 2.0);
	g_hGunSprite = CreateConVar(	"l4d_flare_gun_sprite",				"1",			"Turn on/off the attached glowing sprite.",									CVAR_FLAGS );
	g_hGunSpriteCols = CreateConVar("l4d_flare_gun_sprite_colour",		"200 20 15",	"Set the glowing sprite colour.",											CVAR_FLAGS );
	g_hGunTimeout = CreateConVar(	"l4d_flare_gun_time",				"10.0",			"How many seconds should the grenade launcher projectile flare burn for.",	CVAR_FLAGS );

	g_hIncapped = CreateConVar(		"l4d_flare_incapped",				"1",			"Display flare when incapped. 0=Off, 1=On ground, 2=Attach to player.",		CVAR_FLAGS );
	g_hIntro = CreateConVar(		"l4d_flare_intro",					"35.0",			"0=Off, Show intro message in chat this many seconds after joining.",		CVAR_FLAGS, true, 0.0, true, 120.0);
	g_hLockedCols = CreateConVar(	"l4d_flare_lock_colours",			"0",			"0=Let players edit light/smoke colours, 1=Force to cvar specified.",		CVAR_FLAGS );
	g_hMaxForAdm = CreateConVar(	"l4d_flare_max_admin",				"16",			"Allow root admins to spawn this many max ground flares.",					CVAR_FLAGS, true, 1.0, true, 32.0);
	g_hMaxFlares = CreateConVar(	"l4d_flare_max_total",				"32",			"Limit the total number of simultaneous flares.",							CVAR_FLAGS, true, 1.0, true, 32.0);
	g_hModes = CreateConVar(		"l4d_flare_modes",					"coop,realism",	"Enable plugin on these gamemodes, separate by commas. (Empty = all)",		CVAR_FLAGS );
	g_hHint = CreateConVar(			"l4d_flare_notify",					"1",			"0=Off, 1=Print hints to chat (requires translation file provided).",		CVAR_FLAGS );
	g_hEnable = CreateConVar(		"l4d_flare_on",						"1",			"0=Plugin off, 1=Plugin on.",												CVAR_FLAGS );
	g_hTime = CreateConVar(			"l4d_flare_time",					"10.0", 		"How long the flares should burn, blocks non-admins making flares also.",	CVAR_FLAGS, true, 1.0, true, 120.0 );
	CreateConVar(					"l4d_flare_version",				PLUGIN_VERSION,	"Flare plugin version.",	CVAR_FLAGS|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	AutoExecConfig(true,			"l4d_flare");


	// Hooks
	GetCvars();
	if( g_bEnabled )
		HookEvents();

	HookConVarChange(g_hEnable, ConVarChanged_Enable);
	// Flashlight brightness and on/off hook to delete ents
	HookConVarChange(g_hLightOn, ConVarChanged_LightOn);
	HookConVarChange(g_hLightAlpha, ConVarChanged_LightAlpha);
	HookConVarChange(g_hLightColour, ConVarChanged_Self);
	HookConVarChange(g_hLightFlags, ConVarChanged_Self);
	// Attached flare
	HookConVarChange(g_hSelfCmdAllow, ConVarChanged_Self);
	HookConVarChange(g_hSelfCmdFlags, ConVarChanged_Self);
	HookConVarChange(g_hSelfFuse, ConVarChanged_Self);
	HookConVarChange(g_hSelfLight, ConVarChanged_Self);
	HookConVarChange(g_hSelfLColour, ConVarChanged_Self);
	HookConVarChange(g_hSelfStock, ConVarChanged_Self);
	// Ground Flares
	HookConVarChange(g_hGrndCmdAllow, ConVarChanged_Grnd);
	HookConVarChange(g_hGrndCmdFlags, ConVarChanged_Grnd);
	HookConVarChange(g_hGrndFuse, ConVarChanged_Grnd);
	HookConVarChange(g_hGrndLight, ConVarChanged_Grnd);
	HookConVarChange(g_hGrndLAlpha, ConVarChanged_Grnd);
	HookConVarChange(g_hGrndLColour, ConVarChanged_Grnd);
	HookConVarChange(g_hGrndSmoke, ConVarChanged_Grnd);
	HookConVarChange(g_hGrndSAlpha, ConVarChanged_Grnd);
	HookConVarChange(g_hGrndSColour, ConVarChanged_Grnd);
	HookConVarChange(g_hGrndSHeight, ConVarChanged_Grnd);
	HookConVarChange(g_hGrndStock, ConVarChanged_Grnd);
	// Grenade Launcher Flare Gun
	HookConVarChange(g_hGunAllow, ConVarChanged_GunSpeed);
	HookConVarChange(g_hGunBounce, ConVarChanged_Gun);
	HookConVarChange(g_hGunElasticity, ConVarChanged_Gun);
	HookConVarChange(g_hGunGravity, ConVarChanged_Gun);
	HookConVarChange(g_hGunHurt, ConVarChanged_Gun);
	HookConVarChange(g_hGunHurtSI, ConVarChanged_Gun);
	HookConVarChange(g_hGunLight, ConVarChanged_Gun);
	HookConVarChange(g_hGunLightCols, ConVarChanged_Gun);
	HookConVarChange(g_hGunMaxSpawn, ConVarChanged_Gun);
	HookConVarChange(g_hGunSparks, ConVarChanged_Gun);
	HookConVarChange(g_hGunSpeed, ConVarChanged_GunSpeed);
	HookConVarChange(g_hGunSmoke, ConVarChanged_Gun);
	HookConVarChange(g_hGunSprite, ConVarChanged_Gun);
	HookConVarChange(g_hGunSpriteCols, ConVarChanged_Gun);
	HookConVarChange(g_hGunTimeout, ConVarChanged_Gun);
	// Other plugin cvars
	HookConVarChange(g_hIncapped, ConVarChanged_Main);
	HookConVarChange(g_hIntro, ConVarChanged_Main);
	HookConVarChange(g_hLockedCols, ConVarChanged_Main);
	HookConVarChange(g_hMaxForAdm, ConVarChanged_Main);
	HookConVarChange(g_hMaxFlares, ConVarChanged_Main);
	HookConVarChange(g_hHint, ConVarChanged_Main);
	HookConVarChange(g_hTime, ConVarChanged_Main);

	g_hMPGameMode = FindConVar("mp_gamemode");
	g_hNadeVelocity = FindConVar("grenadelauncher_velocity");
	if( g_hNadeVelocity != INVALID_HANDLE )
	{
		g_iGunSpeedDefault = GetConVarInt(g_hNadeVelocity);
		if( g_bGunAllow )
			SetConVarInt(g_hNadeVelocity, g_iGunSpeed);
	}
	if( g_hMPGameMode != INVALID_HANDLE ) HookConVarChange(g_hMPGameMode, ConVarChanged_Mode);
	HookConVarChange(g_hModes, ConVarChanged_Mode);

	// Commands
	RegAdminCmd("sm_flareclient", CmdFlareAttach, ADMFLAG_ROOT, "Create a flare attached to the specified target");
	RegAdminCmd("sm_flareground", CmdFlareGround, ADMFLAG_ROOT, "Create a flare on the ground next to specified target");
	RegAdminCmd("sm_lightclient", CmdLightAttach, ADMFLAG_ROOT, "Create and toggle flashlight attachment on the specified target");
	RegConsoleCmd("sm_flaregun", CmdFlareGun, "Create a flare on the ground");
	RegConsoleCmd("sm_flare", CmdFlare, "Create a flare on the ground");
	RegConsoleCmd("sm_flareme", CmdFlareSelf, "Create a flare attached to yourself");
	RegConsoleCmd("sm_light", CmdLight, "Toggle the attached flashlight");

	IsAllowedGameMode();

	// Used to save client options if the grenade launcher flare gun bounces/explodes on impact
	if( !g_bLeft4Dead )
	{
		g_hCookie = RegClientCookie("l4d_flare_gun_bounce", "Flare Gun Bounce", CookieAccess_Protected);
		SetCookieMenuItem(Menu_Status, 0, "Flare Gun Bounce");
	}

	// In-case the plugin is reloaded whilst clients are connected.
	for( new i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) )
		{
			// Hook WeaponEquip and get player cookies
			if( !g_bLeft4Dead && !IsFakeClient(i) )
			{
				CreateTimer(1.0, tmrCookies, GetClientUserId(i));
				SDKHook(i, SDKHook_WeaponEquip, OnWeaponEquip);
			}

			// Re-create attached flashlight
			if( g_bLightOn && IsFlareValidNow() && IsValidForFlare(i) )
				CreateLight(i);
		}
	}
}



// ====================================================================================================
//					O T H E R   S T A R T  /  E N D
// ====================================================================================================
public OnMapStart()
{
	if( !IsModelPrecached(MODEL_FLARE) )
		PrecacheModel(MODEL_FLARE);
	if( !IsModelPrecached(MODEL_LIGHT) )
		PrecacheModel(MODEL_LIGHT);
	if( !IsModelPrecached(MODEL_NADE) )
		PrecacheModel(MODEL_NADE);
	if( !IsModelPrecached(MODEL_SPRITE) )
		PrecacheModel(MODEL_SPRITE);
	if( !IsSoundPrecached(SOUND_CRACKLE) )
		PrecacheSound(SOUND_CRACKLE);

	PrecacheParticle(PARTICLE_FLARE);
	PrecacheParticle(PARTICLE_FUSE);
	PrecacheParticle(PARTICLE_SMOKE);
	PrecacheParticle(PARTICLE_SPARKS);
	PrecacheParticle(PARTICLE_TRAIL);
}



public OnPluginEnd()
{
	// Reset grenade launcher projectile speed
	if( g_hNadeVelocity != INVALID_HANDLE )
		SetConVarInt(g_hNadeVelocity, g_iGunSpeedDefault);

	// Delete attached flashlights (models and light_dynamic)
	new i;
	for( i = 1; i < MaxClients; i++ )
		DeleteLight(i);

	// Needed to trigger the flaregun timer to kill itself
	g_bRoundOver = true;

	// Delete flare ents
	new Handle:hTemp = INVALID_HANDLE;
	for( i = 0; i < sizeof(g_hFlareTimerHandles); i++ )
	{
		hTemp = g_hFlareTimerHandles[i];
		if( hTemp != INVALID_HANDLE )
			TriggerTimer(hTemp);
	}
}



// ====================================================================================================
//					I N T R O   /   C O O K I E S
// ====================================================================================================
public OnClientPostAdminCheck(client)
{
	g_bBounce[client] = true;
	g_bBlockAutoFlare[client] = false;
	g_bFlareAttached[client] = false;
	g_bFlareTimeout[client] = false;

	if( !IsFlareValidNow() || IsFakeClient(client) )
		return;

	new clientID = GetClientUserId(client);
	if( !g_bLeft4Dead )
	{
		SDKHook(client, SDKHook_WeaponEquip, OnWeaponEquip);
		CreateTimer(1.0, tmrCookies, clientID);
	}

	// Display intro / welcome message
	new Float:fTime = g_fIntro;
	if( fTime )
		CreateTimer(fTime, tmrIntro, clientID);
}



public Action:tmrIntro(Handle:timer, any:client)
{
	client = GetClientOfUserId(client);
	if( client && IsClientInGame(client) && GetClientTeam(client) == 2 )
		CPrintToChat(client, "%s%T", TAG_CHAT, "Flare Intro", client);
}



public Action:tmrCookies(Handle:timer, any:client)
{
	client = GetClientOfUserId(client);
	if( client && IsClientInGame(client) )
	{
		new String:sCookie[3];
		GetClientCookie(client, g_hCookie, sCookie, sizeof(sCookie));

		//If the cookie is empty, throw some data into it. If the cookie is disabled, we turn off the client's setting
		if(StrEqual(sCookie, ""))
			SetClientCookie(client, g_hCookie, "1");
		else if(StrEqual(sCookie, "0"))
			g_bBounce[client] = false;
		else
			g_bBounce[client] = true;
	}
}



public Menu_Status(client, CookieMenuAction:action, any:info, String:buffer[], maxlen) 
{
	if( g_iGunBounce != 1 ) // Only let them change the settings if not forced bounce
		return;

	switch(action)
	{
		case CookieMenuAction_DisplayOption:
			Format(buffer, maxlen, "Flare Gun Bounce");
		case CookieMenuAction_SelectOption:
			CreateMenuStatus(client);
	}
}



//Menu that appears when a user types !settings
stock CreateMenuStatus(client)
{
	new Handle:menu = CreateMenu(Menu_StatusDisplay);
	decl String:text[64];

	//The title of the menu
	Format(text, sizeof(text), "Flare Gun Bounce");
	SetMenuTitle(menu, text);

	//Since their status is already saved, use it to determine the change
	if( g_bBounce[client] )
		AddMenuItem(menu, "FlareGun", "Disable Flare Gun Bounce (original explosion)");
	else
		AddMenuItem(menu, "FlareGun", "Enable Flare Gun Bounce (ignites entities)");

	//Give the menu a back button, and make it display on the client
	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 15);
}



public Menu_StatusDisplay(Handle:menu, MenuAction:action, param1, param2)
{
	switch( action )
	{
		case MenuAction_Select:
			FlareGun(param1);
		case MenuAction_Cancel: 
		{
			switch (param2) 
			{
				case MenuCancel_ExitBack:
					ShowCookieMenu(param1);
			}
		}
		case MenuAction_End:
			CloseHandle(menu);
	}
}



// ====================================================================================================
//					C V A R   C H A N G E S
// ====================================================================================================
public ConVarChanged_Mode(Handle:convar, const String:oldValue[], const String:newValue[])
{
	IsAllowedGameMode();
}



public ConVarChanged_Enable(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if( StringToInt(newValue) == 1 )
	{
		g_bEnabled = true;
		HookEvents();
	}
	else
	{
		g_bEnabled = false;
		UnhookEvents();
	}
}



public ConVarChanged_LightOn(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if( StringToInt(newValue) == 0 )
	{
		g_bLightOn = false;
		new i;
		for( i = 1; i < MaxClients; i++ )
			DeleteLight(i);
	}
	else
		g_bLightOn = true;
}



public ConVarChanged_LightAlpha(Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i, iEnt;
	g_iLightAlpha = GetConVarInt(g_hLightAlpha);

	// Loop through players and change their brightness
	for( i = 1; i <= MaxClients; i++ )
	{
		iEnt = g_iLightIndex[i];
		if( IsValidEntRef(iEnt) )
		{
			SetVariantEntity(iEnt);
			SetVariantInt(g_iLightAlpha);
			AcceptEntityInput(iEnt, "distance");
		}
	}
}



public ConVarChanged_GunSpeed(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_bGunAllow = GetConVarBool(g_hGunAllow);
	if( g_bGunAllow )
	{
		g_iGunSpeed = GetConVarInt(g_hGunSpeed);
		SetConVarInt(g_hNadeVelocity, g_iGunSpeed);
	}
	else
	{
		SetConVarInt(g_hNadeVelocity, g_iGunSpeedDefault);
	}
}



public ConVarChanged_Self(Handle:convar, const String:oldValue[], const String:newValue[])
	GetCvars(1);

public ConVarChanged_Grnd(Handle:convar, const String:oldValue[], const String:newValue[])
	GetCvars(2);

public ConVarChanged_Gun(Handle:convar, const String:oldValue[], const String:newValue[])
	GetCvars(3);

public ConVarChanged_Main(Handle:convar, const String:oldValue[], const String:newValue[])
	GetCvars(4);



GetCvars(iGroup = 0) // 0 = All, for plugin start
{
	if( iGroup == 0 || iGroup == 1 ) // Attached flare
	{
		g_iSelfCmdAllow = GetConVarInt(g_hSelfCmdAllow);
		GetConVarString(g_hSelfCmdFlags, g_sSelfFlags, sizeof(g_sSelfFlags));
		g_bSelfFuse = GetConVarBool(g_hSelfFuse);
		g_bSelfLight = GetConVarBool(g_hSelfLight);
		GetConVarString(g_hSelfLColour, g_sSelfLCols, sizeof(g_sSelfLCols));
		g_bSelfStock = GetConVarBool(g_hSelfStock);
		GetConVarString(g_hLightColour, g_sLightCols, sizeof(g_sLightCols)); // Flashlight cvars
		GetConVarString(g_hLightFlags, g_sLightFlags, sizeof(g_sLightFlags));
		if( iGroup ) return;
	}

	if( iGroup == 0 || iGroup == 2 ) // Ground flare
	{
		g_iGrndCmdAllow = GetConVarInt(g_hGrndCmdAllow);
		GetConVarString(g_hGrndCmdFlags, g_sGrndFlags, sizeof(g_sGrndFlags));
		g_bGrndFuse = GetConVarBool(g_hGrndFuse);
		g_iGrndLight = GetConVarInt(g_hGrndLight);
		g_iGrndLAlpha = GetConVarInt(g_hGrndLAlpha);
		GetConVarString(g_hGrndLColour, g_sGrndLCols, sizeof(g_sGrndLCols));
		g_bGrndSmokeOn = GetConVarBool(g_hGrndSmoke);
		g_iGrndSAlpha = GetConVarInt(g_hGrndSAlpha);
		GetConVarString(g_hGrndSColour, g_sGrndSCols, sizeof(g_sGrndSCols));
		g_iGrndSHeight = GetConVarInt(g_hGrndSHeight);
		g_bGrndStock = GetConVarBool(g_hGrndStock);
		if( iGroup ) return;
	}

	if( iGroup == 0 || iGroup == 3 ) // Flare gun
	{
		g_iGunBounce = GetConVarInt(g_hGunBounce);
		g_fGunElasticity = GetConVarFloat(g_hGunElasticity);
		g_fGunGravity = GetConVarFloat(g_hGunGravity);
		g_iGunHurt = GetConVarInt(g_hGunHurt);
		g_iGunHurtSI = GetConVarInt(g_hGunHurtSI);
		g_bGunLight = GetConVarBool(g_hGunLight);
		GetConVarString(g_hGunLightCols, g_sGunCols, sizeof(g_sGunCols));
		g_iGunMaxSpawn = GetConVarInt(g_hGunMaxSpawn);
		g_bGunSparks = GetConVarBool(g_hGunSparks);
		g_iGunSmoke = GetConVarInt(g_hGunSmoke);
		g_bGunSprite = GetConVarBool(g_hGunSprite);
		GetConVarString(g_hGunSpriteCols, g_sSpriteCols, sizeof(g_sSpriteCols));
		g_fGunTimeout = GetConVarFloat(g_hGunTimeout);
		if( iGroup ) return;
	}

	if( iGroup == 0 || iGroup == 4 ) // Main cvars
	{
		g_iIncapped = GetConVarInt(g_hIncapped);
		g_fIntro = GetConVarFloat(g_hIntro);
		g_bLockedCols = GetConVarBool(g_hLockedCols);
		g_iMaxForAdm = GetConVarInt(g_hMaxForAdm);
		g_iMaxFlares = GetConVarInt(g_hMaxFlares);
		g_bHint = GetConVarBool(g_hHint);
		g_fTime = GetConVarFloat(g_hTime);
		if( iGroup ) return;
	}

	if( iGroup == 0 ) // Other cvars which have their own change hooks
	{
		g_bGunAllow = GetConVarBool(g_hGunAllow);
		g_bLightOn = GetConVarBool(g_hLightOn);
		g_bEnabled = GetConVarBool(g_hEnable);
		g_iLightAlpha = GetConVarInt(g_hLightAlpha);
		g_iGunSpeed = GetConVarInt(g_hGunSpeed);
	}
}



// ====================================================================================================
//					E V E N T S (mostly for auto flare spawn)
// ====================================================================================================
HookEvents()
{
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_spawn", Event_Spawn);
	HookEvent("player_team", Event_Team);
	HookEvent("player_incapacitated", Event_PlayerIncapped);
	HookEvent("revive_success", Event_ReviveSuccess);
	HookEvent("lunge_pounce", Event_BlockStart);
	HookEvent("pounce_end", Event_BlockEnd);
	HookEvent("tongue_grab", Event_BlockStart);
	HookEvent("tongue_release", Event_BlockEnd);

	if( g_bLeft4Dead ) return;
	HookEvent("charger_pummel_start", Event_BlockStart);
	HookEvent("charger_carry_start", Event_BlockStart);
	HookEvent("charger_carry_end", Event_BlockEnd);
	HookEvent("charger_pummel_end", Event_BlockEnd);
}



UnhookEvents()
{
	UnhookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	UnhookEvent("round_end", Event_RoundEnd);
	UnhookEvent("player_death", Event_PlayerDeath);
	UnhookEvent("player_spawn", Event_Spawn);
	UnhookEvent("player_team", Event_Team);
	UnhookEvent("player_incapacitated", Event_PlayerIncapped);
	UnhookEvent("revive_success", Event_ReviveSuccess);
	UnhookEvent("lunge_pounce", Event_BlockStart);
	UnhookEvent("pounce_end", Event_BlockEnd);
	UnhookEvent("tongue_grab", Event_BlockStart);
	UnhookEvent("tongue_release", Event_BlockEnd);

	if( g_bLeft4Dead ) return;
	UnhookEvent("charger_pummel_start", Event_BlockStart);
	UnhookEvent("charger_carry_start", Event_BlockStart);
	UnhookEvent("charger_carry_end", Event_BlockEnd);
	UnhookEvent("charger_pummel_end", Event_BlockEnd);
}



public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_bRoundOver = false;
	IsAllowedGameMode();
}



public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_bRoundOver = true;

	for( new i = 1; i < MaxClients; i++ )
		DeleteLight(i);
}



public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if( !client || GetClientTeam(client) != 2 )
		return;

	g_bBlockAutoFlare[client] = true;
	DeleteLight(client); // Delete attached flashlight
}



public Action:Event_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new clientID = GetEventInt(event, "userid");
	new client = GetClientOfUserId(client);
	DeleteLight(client);
	g_bBlockAutoFlare[client] = false;

	// Needed because round_start event occurs AFTER player_spawn, so IsFlareValidNow() fails...
	CreateTimer(0.5, tmrDelayCreateLight, clientID);
}



public Action:Event_Team(Handle:event, const String:name[], bool:dontBroadcast)
{
	new clientID = GetEventInt(event, "userid");
	new client = GetClientOfUserId(clientID);
	DeleteLight(client);
	CreateTimer(0.1, tmrDelayCreateLight, clientID);
}



public Action:tmrDelayCreateLight(Handle:timer, any:client)
{
	client = GetClientOfUserId(client);
	if( client && g_bLightOn && IsFlareValidNow() && IsValidForFlare(client) ) // Re-create attached flashlight
		CreateLight(client);
}



public Action:Event_PlayerIncapped(Handle:event, const String:name[], bool:dontBroadcast)
{
	if( !IsFlareValidNow() || !g_iIncapped )
		return;

	new clientID = GetEventInt(event, "userid");
	new client = GetClientOfUserId(clientID);
	if( IsValidForFlare(client) )
		CreateTimer(2.0, tmrCreateFlare, clientID); // Auto spawn flare if allowed
}



public Action:Event_ReviveSuccess(Handle:event, const String:name[], bool:dontBroadcast)
{
	if( !IsFlareValidNow() || !g_iIncapped )
		return;

	new client = GetClientOfUserId(GetEventInt(event, "subject"));
	if( IsValidForFlare(client) )
		g_bBlockAutoFlare[client] = false;
}



public Action:Event_BlockStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if( !IsFlareValidNow() || !g_iIncapped )
		return;

	new client = GetClientOfUserId(GetEventInt(event, "victim"));
	if( IsValidForFlare(client) )
		g_bBlockAutoFlare[client] = true;
}



public Action:Event_BlockEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if( !IsFlareValidNow() || !g_iIncapped )
		return;

	new clientID = GetEventInt(event, "victim");
	new client = GetClientOfUserId(clientID);
	if( IsValidForFlare(client) )
	{
		g_bBlockAutoFlare[client] = false;
		CreateTimer(2.0, tmrCreateFlare, clientID); // Auto spawn flare if allowed
	}
}



// Call from incap events
public Action:tmrCreateFlare(Handle:timer, any:client)
{
	// Must be incapped and valid to spawn a flare
	client = GetClientOfUserId(client);
	if( !IsFlareValidNow() || !IsValidForFlare(client) || g_bFlareTimeout[client] || g_bBlockAutoFlare[client] || !IsIncapped(client) || g_iFlareCount >= g_iMaxFlares )
		return;

	// Auto flare on ground or attached?
	if( g_iIncapped == 1 )
		CreateFlare(client, g_sGrndLCols, g_sGrndSCols, true);
	else if( g_iIncapped == 2 )
		CreateFlare(client, g_sGrndLCols, g_sGrndSCols, false);
	else
		return;

	g_bFlareTimeout[client] = true;
	CreateTimer(g_fTime, tmrFlareTimeout, GetClientUserId(client));

	// Display hint if they are still incapped
	if( !IsFakeClient(client) )
		CreateTimer(g_fTime, tmrFlareHintMsg, client);
}



public Action:tmrFlareHintMsg(Handle:timer, any:client)
{
	// Don't affect players who left, maybe a new client
	client = GetClientOfUserId(client);

	if( !IsFlareValidNow || !IsValidForFlare(client) )
		return;

	// Display hint message if they are still incapped
	if( g_bHint && IsIncapped(client) )
	{
		if( g_iGrndCmdAllow )
			CPrintToChat(client, "%s%T", TAG_CHAT, "Flare Cmd Ground", client);
		else if( g_iSelfCmdAllow )
			CPrintToChat(client, "%s%T", TAG_CHAT, "Flare Cmd Attach", client);		
	}
}



// ====================================================================================================
//					A D M I N   C O M M A N D S (sm_lightclient / sm_flareclient / sm_flareground)
// ====================================================================================================
// Attach flashlight onto specified client / change colours
public Action:CmdLightAttach(client, args)
{
	decl String:sArg[25];
	GetCmdArg(1, sArg, sizeof(sArg));

	new target = FindTarget(client, sArg, false, false);
	if( target != -1 )
	{
		if( args > 1 )
		{
			GetCmdArgString(sArg, sizeof(sArg));
			// Send the args without target name
			new pos = StrContains(sArg, " ");
			if( pos != -1 )
			{
				Format(sArg, sizeof(sArg), "%s", sArg[pos+1]);
				TrimString(sArg);
				CommandLight(target, args -1, sArg);
			}
		}
		else
		{
			CommandLight(target, 0, "");
		}
	}

	return Plugin_Handled;
}



public Action:CmdFlareAttach(client, args)
{
	decl String:sArg[25];
	GetCmdArg(1, sArg, sizeof(sArg));

	new target = FindTarget(client, sArg, false, false);
	if( target != -1 )
	{
		GetCmdArgString(sArg, sizeof(sArg));
		CommandForceFlare(client, target, args, sArg, false);
	}

	return Plugin_Handled;
}



public Action:CmdFlareGround(client, args)
{
	decl String:sArg[25];
	GetCmdArg(1, sArg, sizeof(sArg));

	new target = FindTarget(client, sArg, false, false);
	if( target != -1 )
	{
		GetCmdArgString(sArg, sizeof(sArg));
		CommandForceFlare(client, target, args, sArg, true);
	}

	return Plugin_Handled;
}



CommandForceFlare(client, target, args, const String:sArg[], bool:bGroundFlare)
{
	// Must be valid time to spawn flare
	if( !IsFlareValidNow() )
	{
		CPrintToChat(client, "%s%T", TAG_CHAT, "Flare Invalid Now", client);
		return;
	}


	// Must be valid target
	if( target == -1 || !IsValidForFlare(target) )
	{
		CPrintToChat(client, "%s%T", TAG_CHAT, "Flare Invalid Target", client);
		return;
	}


	// Wrong number of arguments
	if( args != 1 && args != 4 && args != 7 )
	{
		CPrintToChat(client, "%s%T", TAG_CHAT, "Flare Invalid Args", client);
		return;
	}


	// Do not spawn flares when maximum reached
	if( g_iFlareCount >= g_iMaxFlares )
	{
		CPrintToChat(client, "%s%T", TAG_CHAT, "Flare Max", client);
		return;
	}


	// Stop admins spawning more than 1 attached flare on targets
	if( !bGroundFlare && g_bFlareAttached[target] )
	{
		CPrintToChat(client, "%s%T", TAG_CHAT, "Flare Wait", client);
		return;
	}


	// Passed the checks, lets create the flare. Args specify the light/extra smoke (env_steam) colour
	decl String:sTempL[12], String:sTempS[12], String:sBuffers[8][6];
	ExplodeString(sArg, " ", sBuffers, args, 6);

	if( args == 4 )
	{
		Format(sTempL, sizeof(sTempL), "%s %s %s", sBuffers[1], sBuffers[2], sBuffers[3]);
		strcopy(sTempS, sizeof(sTempS), sTempL);
	}
	else if( args == 7 )
	{
		Format(sTempL, sizeof(sTempL), "%s %s %s", sBuffers[1], sBuffers[2], sBuffers[3]);
		Format(sTempS, sizeof(sTempS), "%s %s %s", sBuffers[4], sBuffers[5], sBuffers[6]);
	}
	else // No args, use default colours from cvars
	{
		if( bGroundFlare )
		{
			strcopy(sTempL, sizeof(sTempL), g_sGrndLCols);
			strcopy(sTempS, sizeof(sTempS), g_sGrndSCols);
		}
		else
		{
			GetConVarString(g_hSelfLColour, sTempL, sizeof(sTempL));
		}
	}


	if( bGroundFlare )
		CreateFlare(target, sTempL, sTempS, true);
	else
		CreateFlare(target, sTempL, _, false);
}



// ====================================================================================================
//					F L A R E   C O M M A N D (sm_flare / sm_flareme)
// ====================================================================================================
public Action:CmdFlare(client, args)
{
	decl String:sArg[25];
	GetCmdArgString(sArg, sizeof(sArg));
	CmdCreateFlare(client, args, sArg, true);
	return Plugin_Handled;
}



public Action:CmdFlareSelf(client, args)
{
	decl String:sArg[25];
	GetCmdArgString(sArg, sizeof(sArg));
	CmdCreateFlare(client, args, sArg, false);
	return Plugin_Handled;
}



CmdCreateFlare(client, args, const String:sArg[], bool:bGroundFlare)
{
	// Must be valid
	if( !IsFlareValidNow() || !IsValidForFlare(client) )
		return;

	// Must be enabled
	if( bGroundFlare && !g_iGrndCmdAllow || !bGroundFlare && !g_iSelfCmdAllow )
	{
		CPrintToChat(client, "[SM] %T.", "No Access", client);
		return;
	}

	// Make sure the user has the correct permissions
	new flag;
	if( bGroundFlare )
		flag = ReadFlagString(g_sGrndFlags);
	else
		flag = ReadFlagString(g_sSelfFlags);

	if( bGroundFlare && !CheckCommandAccess(client, "sm_flare", flag) || !bGroundFlare && !CheckCommandAccess(client, "sm_flareme", flag) )
	{
		CPrintToChat(client, "[SM] %T.", "No Access", client);
		return;
	}

	// Do not spawn flares when maximum reached
	if( g_iFlareCount >= g_iMaxFlares )
	{
		CPrintToChat(client, "%s%T", TAG_CHAT, "Flare Max", client);
		return;
	}

	// Only attach 1 flare to players
	if( !bGroundFlare && g_bFlareAttached[client] )
	{
		CPrintToChat(client, "%s%T", TAG_CHAT, "Flare Wait", client);
		return;
	}

	// Only allow ROOT admins to spawn multiple flares
	new flags = GetUserFlagBits(client);
	if( flags & ADMFLAG_ROOT )
	{
		// Do not let root admins spawn more than cvar set max flare (default 8)
		if( g_iAdminMaxFlares[client] >= g_iMaxForAdm )
		{
			CPrintToChat(client, "%s%T", TAG_CHAT, "Flare Wait", client);
			return;
		}

		g_iAdminMaxFlares[client]++;
		CreateTimer(g_fTime, tmrAdminMaxFlares, client);
	}
	else
	{
		// Limit players to 1 flare
		if( g_bFlareTimeout[client] )
		{
			if( g_bHint )
				CPrintToChat(client, "%s%T", TAG_CHAT, "Flare Wait", client);
			return;
		}

		// Don't allow players access to sm_flare command if cvar set only for incapped
		if( bGroundFlare && g_iGrndCmdAllow == 1 && !IsIncapped(client)
		|| !bGroundFlare && g_iSelfCmdAllow == 1 && !IsIncapped(client) )
		{
			if( g_bHint )
				CPrintToChat(client, "%s%T", TAG_CHAT, "Flare Incapped", client);
			return;
		}
	}

	// Wrong number of arguments
	if( args != 0 && args != 3 && args != 6 )
	{
		// Display usage help if translation exists and hints turned on
		if( g_bHint )
			CPrintToChat(client, "%s%T", TAG_CHAT, "Flare Usage", client);
		return;
	}

	// Passed the checks, lets create the flare
	decl String:sTempL[12], String:sTempS[12];

	// Specified colours
	if( !(flags & ADMFLAG_ROOT) && g_bLockedCols )
		flag = 0;
	else
		flag = 1;


	if( args == 3 && flag )
	{
		strcopy(sTempL, sizeof(sTempL), sArg);
		strcopy(sTempS, sizeof(sTempS), sTempL);
	}
	else if( args == 6 && flag )
	{
		decl String:sBuffers[6][4];
		ExplodeString(sArg, " ", sBuffers, 6, 4);

		Format(sTempL, sizeof(sTempL), "%s %s %s", sBuffers[0], sBuffers[1], sBuffers[2]);
		Format(sTempS, sizeof(sTempS), "%s %s %s", sBuffers[3], sBuffers[4], sBuffers[5]);
	}
	else
	{
		if( bGroundFlare )
		{
			strcopy(sTempL, sizeof(sTempL), g_sGrndLCols);
			strcopy(sTempS, sizeof(sTempS), g_sGrndSCols);
		}
		else
		{
			strcopy(sTempL, sizeof(sTempL), g_sSelfLCols);
		}
	}

	// Create flare
	if( bGroundFlare )
		CreateFlare(client, sTempL, sTempS, true);
	else
		CreateFlare(client, sTempL, _, false);
}



public Action:tmrAdminMaxFlares(Handle:timer, any:client)
{
	g_iAdminMaxFlares[client]--;
}



// ====================================================================================================
//					F L A R E
// ====================================================================================================
// Create flare Attached / Ground, called from incap events and sm_flare commands.
CreateFlare(client, const String:sColourL[], const String:sColourS[]="", bool:bGroundFlare=false)
{
	// Do not spawn flares when maximum reached
	if( g_iFlareCount >= g_iMaxFlares )
	{
		if( g_bHint )
			CPrintToChat(client, "%s%T", TAG_CHAT, "Flare Max", client);
		return;
	}

	// Place on ground
	if( bGroundFlare )
	{
		new Float:fAngles[3], Float:fOrigin[3];

		// Flare position
		if( !MakeFlarePosition(client, fOrigin, fAngles) )
		{
			CPrintToChat(client, "%s%T", TAG_CHAT, "Flare Invalid Place", client);
			return;	// Could not place after 12 attempts?!
		}

		MakeFlare(fAngles, fOrigin, sColourL, sColourS);
	}
	// Attach to survivor
	else
	{
		if( !AttachFlare(client, sColourL) )
			return;

		// Attached flare timeout
		g_bFlareAttached[client] = true;
		CreateTimer(g_fTime, tmrFlareAttach, GetClientUserId(client));
	}

	// Max flares timeout
	g_iFlareCount++;
	CreateTimer(g_fTime, tmrFlareCount);
}



public Action:tmrFlareTimeout(Handle:timer, any:client)
{
	client = GetClientOfUserId(client);
	if( client && IsClientInGame(client) )
		g_bFlareTimeout[client] = false;
}



public Action:tmrFlareAttach(Handle:timer, any:client)
{
	client = GetClientOfUserId(client);
	if( client && IsClientInGame(client) )
		g_bFlareAttached[client] = false;
}



public Action:tmrFlareCount(Handle:timer)
{
	g_iFlareCount--;
}



bool:MakeFlarePosition(client, Float:fOrigin[3], Float:fAngles[3])
{
	new Float:i, Float:iLoop, Float:fRadius=30.0, Float:fAngle, Float:fTargetOrigin[3];

	GetClientAbsOrigin(client, fOrigin);
	iLoop = GetRandomFloat(1.0, 360.0); // Random circle starting point

	// Loop through 12 positions around the player to find a good flare position
	for (i = iLoop; i <= iLoop + 6.0; i += 0.5)
	{
		fTargetOrigin = fOrigin;
		fAngle = i * 360.0 / 12.0; // Divide circle into 12
		fRadius -= GetRandomFloat(0.0, 10.0); // Randomise circle radius

		// Draw in a circle around player
		fTargetOrigin[0] += fRadius * (Sine(fAngle));
		fTargetOrigin[1] += fRadius * (Cosine(fAngle));

		// Trace from target origin and get ground positon/angles for placement
		GetGroundAngles(fTargetOrigin, fAngles);

		// Make sure the flare is within a resonable height and distance
		fRadius = fTargetOrigin[2] - fOrigin[2];
		if( (fRadius >= -60.0 && fRadius <= 5.0) && GetVectorDistance(fTargetOrigin, fOrigin) <= 100.0)
		{
			fOrigin = fTargetOrigin;
			return true;
		}
	}

	return false;
}



GetGroundAngles(Float:fOrigin[3], Float:fAngles[3])
{
	decl Float:vAngles[3], Float:vLookAt[3], Float:fTargetOrigin[3];

	fTargetOrigin = fOrigin;
	fTargetOrigin[2] -= 20.0; // Point to the floor
	MakeVectorFromPoints(fOrigin, fTargetOrigin, vLookAt);
	GetVectorAngles(vLookAt, vAngles); // get angles from vector for trace

	// execute Trace
	new Handle:trace = TR_TraceRayFilterEx(fOrigin, vAngles, MASK_ALL, RayType_Infinite, _TraceFilter);

	if( TR_DidHit(trace) )
	{
		decl Float:vStart[3], Float:vNorm[3];
		TR_GetEndPosition(vStart, trace); // retrieve our trace endpoint
		TR_GetPlaneNormal(trace, vNorm); // Ground angles
		GetVectorAngles(vNorm, fAngles);

		new Float:fRandom = GetRandomFloat(1.0, 360.0); // Random angle

		if( vNorm[2] == 1.0 ) // Is flat on ground
		{
			fAngles[0] = 0.0;
			fAngles[1] = fRandom;			// Rotate the prop in a random direction
		}
		else
		{
			fAngles[0] += 90.0;
			RotateYaw(fAngles, fRandom);	// Rotate the prop in a random direction
		}

		fOrigin = vStart;
	}
	CloseHandle(trace);
}



public bool:_TraceFilter(entity, contentsMask)
{
	if( !entity || entity <= MaxClients || !IsValidEntity(entity) ) // dont let WORLD, or invalid entities be hit
		return false;
	return true;
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



// ====================================================================================================
//					G R O U N D   F L A R E
// ====================================================================================================
// After getting the flare position, we make it, at last... jump from CreateFlare()
MakeFlare(Float:fAngles[3], Float:fOrigin[3], const String:sColourL[], const String:sColourS[])
{
	decl String:sTemp[4];
	new iEnt, iValidEnt, Handle:hPack, Handle:hTimer;
	hTimer = CreateDataTimer(g_fTime, tmrDeleteEnts, hPack, TIMER_DATA_HNDL_CLOSE);
	FlareTimerHandler(hTimer);


	// Flare model
	iEnt = CreateEntityByName("prop_dynamic");
	if( iEnt == -1 )
	{
		LogError("Failed to create 'prop_dynamic'");
	}
	else
	{
		SetEntityModel(iEnt, MODEL_FLARE);
		SetVariantString("OnUser1 !self:kill::120:1");
		AcceptEntityInput(iEnt, "AddOutput");
		AcceptEntityInput(iEnt, "FireUser1");
		DispatchSpawn(iEnt);
		TeleportEntity(iEnt, fOrigin, fAngles, NULL_VECTOR);
	}


	// Light
	iEnt = 0;
	if( g_iGrndLight )
	{
		if( g_iGrndLight == 1 )
		{
			fOrigin[2] += 15.0;
			iEnt = MakeLightDynamic(fOrigin, Float:{ 90.0, 0.0, 0.0 }, sColourL, g_iGrndLAlpha);
			fOrigin[2] -= 15.0;

			if( iEnt )
				iEnt = EntIndexToEntRef(iEnt);
		}
		else
		{
			iEnt = CreateEntityByName("point_spotlight");
			if( iEnt == -1)
			{
				LogError("Failed to create 'point_spotlight'");
			}
			else
			{
				DispatchKeyValue(iEnt, "rendercolor", sColourL);
				DispatchKeyValue(iEnt, "rendermode", "9");
				DispatchKeyValue(iEnt, "spotlightwidth", "1");
				DispatchKeyValue(iEnt, "spotlightlength", "3");
				IntToString(g_iGrndLAlpha, sTemp, sizeof(sTemp));
				DispatchKeyValue(iEnt, "renderamt", sTemp);
				DispatchKeyValue(iEnt, "spawnflags", "1");
				DispatchSpawn(iEnt);
				AcceptEntityInput(iEnt, "TurnOn");

				DispatchKeyValue(iEnt, "angles", "90 0 0");
				fOrigin[2] += 0.4;
				TeleportEntity(iEnt, fOrigin, NULL_VECTOR, NULL_VECTOR);
				fOrigin[2] -= 0.4;

				if( iEnt )
					iEnt = EntIndexToEntRef(iEnt);
			}
		}
	}
	WritePackCell(hPack, iEnt);
	if( iValidEnt == 0 && iEnt != 0 )
		iValidEnt = iEnt;


	// Position particles / smoke
	iEnt = 0;
	if( g_fFlareAngle == 0.0 )
		g_fFlareAngle = GetRandomFloat(1.0, 360.0);
	fAngles[1] = g_fFlareAngle;
	fAngles[0] = -80.0;
	fOrigin[0] += (1.0 * (Cosine(DegToRad(fAngles[1]))));
	fOrigin[1] += (1.5 * (Sine(DegToRad(fAngles[1]))));
	fOrigin[2] += 1.0;


	// Flare particles
	iEnt = 0;
	if( g_bGrndStock )
	{
		iEnt = DisplayParticle(PARTICLE_FLARE, fOrigin, fAngles);

		if( iEnt )
			iEnt = EntIndexToEntRef(iEnt);
	}
	WritePackCell(hPack, iEnt);
	if( iValidEnt == 0 && iEnt != 0 )
		iValidEnt = iEnt;


	// Fuse particles
	iEnt = 0;
	if( g_bGrndFuse )
	{
		iEnt = DisplayParticle(PARTICLE_FUSE, fOrigin, fAngles);

		if( iEnt )
		{
			iEnt = EntIndexToEntRef(iEnt);
		}
	}
	WritePackCell(hPack, iEnt);
	if( iValidEnt == 0 && iEnt != 0 )
		iValidEnt = iEnt;


	// Smoke
	iEnt = 0;
	if( g_bGrndSmokeOn )
	{
		fAngles[0] = -85.0;
		iEnt = MakeEnvSteam(fOrigin, fAngles, sColourS, g_iGrndSAlpha, g_iGrndSHeight);

		if( iEnt )
			iEnt = EntIndexToEntRef(iEnt);
	}
	WritePackCell(hPack, iEnt);
	if( iValidEnt == 0 && iEnt != 0 )
		iValidEnt = iEnt;

	iValidEnt = EntRefToEntIndex(iValidEnt);
	WritePackCell(hPack, iValidEnt);
	PlaySound(iValidEnt, g_fTime);
}



// ====================================================================================================
//					A T T A C H E D   F L A R E
// ====================================================================================================
// Jump from CreateFlare()
bool:AttachFlare(client, const String:sColourL[])
{
	// Get survivor model
	decl String:sModel[48], iType;
	GetEntPropString(client, Prop_Data, "m_ModelName", sModel, sizeof(sModel));

	if( StrEqual(sModel, "models/survivors/survivor_coach.mdl") ) iType = 1;
	else if( StrEqual(sModel, "models/survivors/survivor_gambler.mdl") ) iType = 1;
	else if( StrEqual(sModel, "models/survivors/survivor_mechanic.mdl") ) iType = 3;
	else if( StrEqual(sModel, "models/survivors/survivor_producer.mdl") ) iType = 1;
	else if( StrEqual(sModel, "models/survivors/survivor_namvet.mdl") ) iType = 2;
	else if( StrEqual(sModel, "models/survivors/survivor_biker.mdl") ) iType = 4;
	else if( StrEqual(sModel, "models/survivors/survivor_manager.mdl") ) iType = 2;
	else if( StrEqual(sModel, "models/survivors/survivor_teenangst.mdl") ) iType = 5;
	else
	{
		LogError("Invalid model: %s", sModel);
		return false;
	}

	decl String:sTemp[16];
	new iEnt, Float:fOrigin[3], Float:fAngles[3];

	new Handle:hPack = INVALID_HANDLE, Handle:hTimer = INVALID_HANDLE;
	hTimer = CreateDataTimer(g_fTime, tmrDeleteEnts, hPack, TIMER_DATA_HNDL_CLOSE);
	FlareTimerHandler(hTimer);


	// Flare model
	iEnt = CreateEntityByName("prop_dynamic");
	if( iEnt == -1 )
	{
		iEnt = 0;
		LogError("Failed to create 'prop_dynamic'");
	}
	else
	{
		SetEntityModel(iEnt, MODEL_FLARE);
		DispatchSpawn(iEnt);

		// Attach to survivor
		Format(sTemp, sizeof(sTemp), "FLR%i%i", iEnt, client);
		DispatchKeyValue(client, "targetname", sTemp);
		SetVariantString(sTemp);
		AcceptEntityInput(iEnt, "SetParent", iEnt, iEnt, 0);
		SetVariantString(ATTACH_PILLS);
		AcceptEntityInput(iEnt, "SetParentAttachment");

		// Rotate to hide small parts of flare model and point upside down, so burning flare part at top
		if( iType == 1 )		// REST
		{
			fAngles = Float: { 20.0, 90.0, -90.0 };
			fOrigin = Float: { 3.0, 1.5, 8.0 };
		}
		else if( iType == 2 )	// NICK
		{
			fAngles = Float: { 20.0, 90.0, -90.0 };
			fOrigin = Float: { 2.5, 2.0, 8.0 };
		}
		else if( iType == 3 )	// ELLIS
		{
			fAngles = Float: { 20.0, 90.0, -90.0 };
			fOrigin = Float: { 2.5, 2.0, 8.0 };
		}
		else if( iType == 4 )	// FRANCIS
		{
			fAngles = Float: { 20.0, 90.0, -90.0 };
			fOrigin = Float: { 4.0, 2.0, 8.0 };
		}
		else if( iType == 5 )	// ZOEY
		{
			fAngles = Float: { 10.0, -30.0, -110.0 };
			fOrigin = Float: { -2.5, -6.5, 8.0 };
		}

		TeleportEntity(iEnt, fOrigin, fAngles, NULL_VECTOR);
		SDKHook(iEnt, SDKHook_SetTransmit, Hook_SetTransmit);
		iEnt = EntIndexToEntRef(iEnt);
		g_iAttachedFlare[client] = iEnt;
	}
	WritePackCell(hPack, iEnt);


	// Position light and particles
	if( iType == 5 ) // Zoey
	{
		fOrigin = Float: { -2.0, -7.0, 7.0 };
		fAngles = Float: { -90.0, -180.0, 90.0 };
	}
	else
	{
		fOrigin[2] = 7.0;
		// fOrigin = Float: { 2.5, 3.0, 7.0 };
		fAngles = Float: { -110.0, -80.0, 90.0 };
	}


	// Light_Dynamic
	iEnt = 0;
	if( g_bSelfLight )
	{
		iEnt = MakeLightDynamic(fOrigin, fAngles, sColourL, g_iGrndLAlpha, true, client, ATTACH_PILLS);
		if( iEnt )
			iEnt = EntIndexToEntRef(iEnt);
	}
	WritePackCell(hPack, iEnt);


	// Flare particles
	iEnt = 0;
	if( g_bSelfStock )
	{
		iEnt = DisplayParticle(PARTICLE_FLARE, fOrigin, fAngles, client, ATTACH_PILLS);

		if( iEnt )
			iEnt = EntIndexToEntRef(iEnt);
	}
	WritePackCell(hPack, iEnt);


	// Fuse particles
	iEnt = 0;
	if( g_bSelfFuse )
	{
		iEnt = DisplayParticle(PARTICLE_FUSE, fOrigin, NULL_VECTOR, client, ATTACH_PILLS);

		if( iEnt )
			iEnt = EntIndexToEntRef(iEnt);
	}
	WritePackCell(hPack, iEnt);
	WritePackCell(hPack, client);
	PlaySound(client, g_fTime);

	return true;
}



// ====================================================================================================
//					F L A S H L I G H T
// ====================================================================================================
public Action:CmdLight(client, args)
{
	decl String:sArg[25];
	GetCmdArgString(sArg, sizeof(sArg));
	CommandLight(client, args, sArg);
	return Plugin_Handled;
}



CommandLight(client, args, const String:sArg[])
{
	// Must be valid
	if( !IsFlareValidNow() || !IsValidForFlare(client) )
		return;

	// Must be enabled
	if( !g_bLightOn )
	{
		CPrintToChat(client, "[SM] %T.", "No Access", client);
		return;
	}

	// Make sure the user has the correct permissions
	new flag = ReadFlagString(g_sLightFlags);

	if( !CheckCommandAccess(client, "sm_light", flag) )
	{
		CPrintToChat(client, "[SM] %T.", "No Access", client);
		return;
	}

	// Wrong number of arguments
	if( args != 0 && args != 3 )
	{
		// Display usage help if translation exists and hints turned on
		if( g_bHint )
			CPrintToChat(client, "%s%T", TAG_CHAT, "Flare Usage", client);
		return;
	}

	decl String:sTempStr[42];
	// Delete flashlight and re-make if the players model has changed, CSM plugin fix...
	GetClientModel(client, sTempStr, sizeof(sTempStr));
	if( strcmp(g_sPlayerModel[client], sTempStr) != 0 )
	{
		DeleteLight(client);
		strcopy(g_sPlayerModel[client], 42, sTempStr);
	}

	// Check if they have a light, or try to create
	new iEnt = g_iLightIndex[client];	
	if( !IsValidEntRef(iEnt) )
	{
		CreateLight(client);

		iEnt = g_iLightIndex[client];
		if( !IsValidEntRef(iEnt) )
			return;
	}

	// Toggle or set light colour and turn on.
	if( args == 3 )
	{
		// Specified colours
		decl String:sTempL[12];
		strcopy(sTempL, sizeof(sTempL), sArg);
		SetVariantEntity(iEnt);
		SetVariantString(sTempL);
		AcceptEntityInput(iEnt, "color");
	}

	AcceptEntityInput(iEnt, "toggle");
}



// Called to attach permanent light.
CreateLight(client)
{
	DeleteLight(client);

	// Declares
	new iEnt, Float:fOrigin[3], Float:fAngles[3];
	decl String:sTemp[16];

	// Flashlight model
	iEnt = CreateEntityByName("prop_dynamic");
	if( iEnt == -1 )
	{
		LogError("Failed to create 'prop_dynamic'");
	}
	else
	{
		SetEntityModel(iEnt, MODEL_LIGHT);
		DispatchSpawn(iEnt);

		fOrigin = Float: { 0.0, 0.0, -2.0 };
		fAngles = Float: { 180.0, 9.0, 90.0 };

		// Attach to survivor
		Format(sTemp, sizeof(sTemp), "FLR%i%i", iEnt, client);
		DispatchKeyValue(client, "targetname", sTemp);
		SetVariantString(sTemp);
		AcceptEntityInput(iEnt, "SetParent", iEnt, iEnt, 0);
		SetVariantString(ATTACH_GRENADE);
		AcceptEntityInput(iEnt, "SetParentAttachment");
	
		TeleportEntity(iEnt, fOrigin, fAngles, NULL_VECTOR);
		SDKHook(iEnt, SDKHook_SetTransmit, Hook_SetTransmit);
		g_iModelIndex[client] = EntIndexToEntRef(iEnt);
	}

	// Position light
	fOrigin = Float: { 0.5, -1.5, -7.5 };
	fAngles = Float: { -45.0, -45.0, 90.0 };

	// Light_Dynamic
	iEnt = MakeLightDynamic(fOrigin, fAngles, g_sLightCols, g_iLightAlpha, false, client, ATTACH_GRENADE);
	AcceptEntityInput(iEnt, "TurnOff");
	g_iLightIndex[client] = EntIndexToEntRef(iEnt);
}



// ====================================================================================================
// 					F L A R E   G U N
// ====================================================================================================
public Action:CmdFlareGun(client, args)
{
	if( !g_bLeft4Dead && g_bGunAllow && g_iGunBounce == 1 && IsFlareValidNow() )
		FlareGun(client);
	return Plugin_Handled;
}



FlareGun(client)
{
	if( g_bBounce[client] )
	{
		SetClientCookie(client, g_hCookie, "0");
		CPrintToChat(client, "%sYou've disabled Flare Gun bounces.", TAG_CHAT);
	}
	else
	{
		SetClientCookie(client, g_hCookie, "1");
		CPrintToChat(client, "%sYou've enabled Flare Gun bounces.", TAG_CHAT);
	}

	g_bBounce[client] = !g_bBounce[client];
}



// Display hint when picking up grenade_launcher that the flare gun bounce can be disabled, but only show once to survivors if the bounce is enabled (not forced).
public Action:OnWeaponEquip(client, weapon)
{
	if( !g_bLeft4Dead && g_bGunAllow && g_iGunBounce == 1 && IsFlareValidNow() && !g_bDisplayed[client] && GetClientTeam(client) == 2 )
	{
		decl String:sWeapon[25];
		GetEdictClassname(weapon, sWeapon, sizeof(sWeapon));
		if( StrEqual(sWeapon, "weapon_grenade_launcher") )
		{
			CPrintToChat(client, "%s%T", TAG_CHAT, "Flare Gun Bounce", client);
			g_bDisplayed[client] = true;
		}
	}
	return Plugin_Continue;
}



// Called when someone shoots a grenade launcher projectile
public OnEntityCreated(entity, const String:classname[])
{
	if( g_bLeft4Dead || !g_bGunAllow || g_bBlockHook || !IsFlareValidNow() || g_iGrenadeLimit >= g_iGunMaxSpawn || !StrEqual(classname, PROJECTILE) )
		return;

	// Because SDKHook_Spawn doesnt have any entity info... would prefer to replace or some how permanently stop explosions.
	CreateTimer(0.01, tmrMakeGrenade, EntIndexToEntRef(entity));
}



public Action:tmrMakeGrenade(Handle:timer, any:iEnt)
{
	if( !IsValidEntRef(iEnt) )
		return;
	iEnt = EntRefToEntIndex(iEnt);

	new iOwner, iEnt1, iEnt2, iEnt3, iEnt4;

	// Save owner
	iOwner = GetEntPropEnt(iEnt, Prop_Send, "m_hOwnerEntity");
	if( iOwner < 0 || iOwner > MaxClients ) iOwner = 0;

	// Stop the bounce according to cvar/clientprefs.
	new bool:bBounce = true;
	if( g_iGunBounce == 3 || g_iGunBounce == 4 ) // Stick
		bBounce = true;
	else if( g_iGunBounce == 0 || g_iGunBounce == 1 && !g_bBounce[iOwner] )
		bBounce = false;

	// Can't find how to disable explosins so delete old projectile and create new so it bounces
	if( bBounce )
	{
		new Float:fPos[3], Float:fAng[3], Float:fVel[3];
		// Save origin and velocity
		GetEntPropVector(iEnt, Prop_Data, "m_angRotation", fAng);
		GetEntPropVector(iEnt, Prop_Data, "m_vecAbsOrigin", fPos);
		GetEntPropVector(iEnt, Prop_Data, "m_vecAbsVelocity", fVel);
		RemoveEdict(iEnt);

		// Create new projectile
		g_bBlockHook = true;
		iEnt = CreateEntityByName(PROJECTILE);
		if( iEnt == -1 )
		{
			g_bBlockHook = false;
			return;
		}

		g_bBlockHook = false;
		g_iGrenadeLimit++;

		// Set origin, velocity and owner
		SetEntPropVector(iEnt, Prop_Data, "m_angRotation", fAng);
		SetEntPropVector(iEnt, Prop_Data, "m_vecAbsOrigin", fPos);
		SetEntPropVector(iEnt, Prop_Data, "m_vecAbsVelocity", fVel);
		SetEntPropEnt(iEnt, Prop_Send, "m_hOwnerEntity", iOwner);

		DispatchSpawn(iEnt);
		ActivateEntity(iEnt);
	}

	// Set gravity and elasticity
	SetEntPropFloat(iEnt, Prop_Data, "m_flGravity", g_fGunGravity);
	SetEntPropFloat(iEnt, Prop_Data, "m_flElasticity", g_fGunElasticity);

	// Attach particles etc
	if( g_iGunSmoke == 1 )
		iEnt1 = DisplayParticle(PARTICLE_FLARE, Float:{ 0.0, 0.0, 0.0 }, Float:{ 180.0, 0.0, 90.0 }, iEnt);

	if( g_bGunSparks )
		iEnt2 = DisplayParticle(PARTICLE_SPARKS,  Float:{ 0.0, 0.0, 0.0 }, Float:{ 180.0, 0.0, 90.0 }, iEnt);

	if( g_bGunLight )
		iEnt3 = MakeLightDynamic( Float:{ 0.0, 0.0, 0.0 }, Float:{ 180.0, 0.0, 90.0 }, g_sGunCols, 255, true, iEnt);

	if( g_bGunSprite )
		iEnt4 = MakeEnvSprite( Float:{ 0.0, 0.0, 0.0 }, Float:{ 180.0, 0.0, 90.0 }, g_sSpriteCols, iEnt);

	// Timer to delete entity / loop RPG smoke
	new Handle:hPack = INVALID_HANDLE, Handle:hTimer = INVALID_HANDLE;
	hTimer = CreateDataTimer(0.1, tmrCreateSmoke, hPack, TIMER_REPEAT|TIMER_DATA_HNDL_CLOSE);
	FlareTimerHandler(hTimer);

	WritePackCell(hPack, EntIndexToEntRef(iEnt));
	WritePackCell(hPack, EntIndexToEntRef(iEnt1));
	WritePackCell(hPack, EntIndexToEntRef(iEnt2));
	WritePackCell(hPack, EntIndexToEntRef(iEnt3));
	WritePackCell(hPack, EntIndexToEntRef(iEnt4));
	WritePackCell(hPack, 0);
	WritePackFloat(hPack, 0.0);

	if( bBounce && g_iGunHurt ) // Hook touch to ignite stuff!
		SDKHook(iEnt, SDKHook_Touch, SDKHook_Touch_Callback);
}



public Action:tmrCreateSmoke(Handle:timer, Handle:hPack)
{
	new iEnt, iEnt1, iEnt2, iEnt3, iEnt4, iTick, Float:fTick;
	ResetPack(hPack);
	iEnt = ReadPackCell(hPack);
	iEnt1 = ReadPackCell(hPack);
	iEnt2 = ReadPackCell(hPack);
	iEnt3 = ReadPackCell(hPack);
	iEnt4 = ReadPackCell(hPack);
	iTick = ReadPackCell(hPack); // Counts how many times we delete and re-create the RPG smoke
	fTick = ReadPackFloat(hPack);

	// Check grenade is valid and delete stuff after this amount of time (cvar * 0.7s)
	if( g_bRoundOver || EntRefToEntIndex(iEnt) == INVALID_ENT_REFERENCE || fTick >= g_fGunTimeout )
	{
		if( g_iGunBounce == 4 ) // Sticky grenade, create explosion
		{
			decl Float:fPos[3];
			GetEntPropVector(iEnt, Prop_Data, "m_vecAbsOrigin", fPos);
			new iExplosion = CreateEntityByName("prop_physics");
			SetEntPropVector(iExplosion, Prop_Data, "m_vecAbsOrigin", fPos);
			DispatchKeyValue(iExplosion, "physdamagescale", "0.0");
			DispatchKeyValue(iExplosion, "model", "models/props_junk/propanecanister001a.mdl");
			DispatchSpawn(iExplosion);
			AcceptEntityInput(iExplosion, "Break");
		}

		FlareTimerHandler(timer, true);
		g_iGrenadeLimit--;
		DeleteEntity(iEnt);
		DeleteEntity(iEnt1);
		DeleteEntity(iEnt2);
		DeleteEntity(iEnt3);
		DeleteEntity(iEnt4);
		return Plugin_Stop;
	}

	// Delete RPG smoke and create every 0.7 seconds to make it look like one piece of smoke
	if( g_iGunSmoke == 2 && (fTick >= (iTick * 0.7)) )
	{
		DeleteEntity(iEnt1);
		iEnt1 = EntIndexToEntRef( DisplayParticle(PARTICLE_SMOKE, Float:{ 0.0, 0.0, 0.0 }, Float:{ 180.0, 0.0, 90.0 }, EntRefToEntIndex(iEnt)) );
		iTick ++;
	}

	fTick += 0.1;
	ResetPack(hPack);
	WritePackCell(hPack, iEnt);
	WritePackCell(hPack, iEnt1);
	WritePackCell(hPack, iEnt2);
	WritePackCell(hPack, iEnt3);
	WritePackCell(hPack, iEnt4);
	WritePackCell(hPack, iTick);
	WritePackFloat(hPack, fTick);
	return Plugin_Continue;
}



public SDKHook_Touch_Callback(entity, victim)
{
	decl String:sClass[16];
	GetEntityNetClass(victim, sClass, 16);

	if( victim == 0 )
	{
		if( g_iGunBounce == 3 || g_iGunBounce == 4 ) // Make the nade stick
		{
			if( StrEqual("CWorld", sClass) )
			{
				SetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", Float:{ 0.0, 0.0, 0.0 });
				SetEntityMoveType(entity, MOVETYPE_NONE);
			}
		}

		return;
	}

	// Only damage these types (survivors, common, special, explosives).
	if( !StrEqual(sClass, "Player") && !StrEqual(sClass, "CTerrorPlayer") && !StrEqual(sClass, "SurvivorBot") && !StrEqual(sClass, "Infected") &&
		!StrEqual(sClass, "Boomer") && !StrEqual(sClass, "Charger") && !StrEqual(sClass, "Hunter") && !StrEqual(sClass, "Jockey") && 
		!StrEqual(sClass, "Smoker") && !StrEqual(sClass, "Spitter") && !StrEqual(sClass, "Tank") && !StrEqual(sClass, "Witch") && 
		!StrEqual(sClass, "CPhysicsProp") && !StrEqual(sClass, "CGasCan") ) //&& !StrEqual(sClass, "CFireworkCrate") &&
		// !StrEqual(sClass, "COxygenTank") && !StrEqual(sClass, "CPropaneTank") )
		return;

	// Only damage players once per second.
	new bool:bInfected;
	if( victim <= MaxClients )
	{
		new Float:fEngineTime = GetGameTime();
		if( fEngineTime - g_fLastHurt[victim] <= 0.5 ) // How often to hurt the player (once every 0.5 secs)
			return;
		g_fLastHurt[victim] = fEngineTime;

		if( GetClientTeam(victim) == 3 )
			bInfected = true;
	}

	decl Float:fPos[3];
	GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", fPos);

	// Set up hurt point
	new iEnt = CreateEntityByName("point_hurt");
	if( iEnt == -1 )
		return;

	// Create point_hurt
	Format(sClass, sizeof(sClass), "hurtme%d", victim);
	DispatchKeyValue(victim, "targetname", sClass);
	DispatchKeyValue(iEnt, "DamageTarget", sClass);
	if( bInfected )
	{
		IntToString(g_iGunHurtSI, sClass, 3);
		DispatchKeyValue(iEnt, "Damage", sClass);
	}
	else
	{
		IntToString(g_iGunHurt, sClass, 3);
		DispatchKeyValue(iEnt, "Damage", sClass);
	}
	DispatchKeyValue(iEnt, "DamageType", "8");
	TeleportEntity(iEnt, fPos, NULL_VECTOR, NULL_VECTOR);

	new iOwner;
	iOwner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	iOwner = (iOwner > 0 && iOwner < MaxClients && IsClientInGame(iOwner)) ? iOwner : -1;
	AcceptEntityInput(iEnt, "Hurt", iOwner);

	// Delete point_hurt
	DispatchKeyValue(iEnt, "classname", "point_hurt");
	DispatchKeyValue(victim, "targetname", "null");
	RemoveEdict(iEnt);
}



// ====================================================================================================
//					P A R T I C L E S
// ====================================================================================================
PrecacheParticle(const String:ParticleName[])
{
	new Particle = CreateEntityByName("info_particle_system");
	if(IsValidEntity(Particle) && IsValidEdict(Particle))
	{
		DispatchKeyValue(Particle, "effect_name", ParticleName);
		DispatchSpawn(Particle);
		ActivateEntity(Particle);
		AcceptEntityInput(Particle, "start");
		Particle = EntIndexToEntRef(Particle);
		CreateTimer(0.3, tmrDeleteEntity, Particle);
	}
}



DisplayParticle(String:sParticle[], Float:fPos[3], Float:fAng[3], client=0, const String:sAttachment[] = "")
{
	new iEnt = CreateEntityByName("info_particle_system");

	if( iEnt != -1 && IsValidEdict(iEnt) )
	{
		DispatchKeyValue(iEnt, "effect_name", sParticle);
		DispatchSpawn(iEnt);
		ActivateEntity(iEnt);
		AcceptEntityInput(iEnt, "start");

		if( client )
		{
			// Attach to survivor
			decl String:sTemp[16];
			Format(sTemp, sizeof(sTemp), "FLR%i%i", iEnt, client);
			DispatchKeyValue(client, "targetname", sTemp);
			SetVariantString(sTemp);
			AcceptEntityInput(iEnt, "SetParent", iEnt, iEnt, 0);

			if( strlen(sAttachment) != 0 )
			{
				SetVariantString(sAttachment);
				AcceptEntityInput(iEnt, "SetParentAttachment");
			}
		}

		TeleportEntity(iEnt, fPos, fAng, NULL_VECTOR);
	
		return iEnt;
	}

	return 0;
}



// ====================================================================================================
//					M A K E   L I G H T S   E T C
// ====================================================================================================
MakeLightDynamic(Float:fOrigin[3], Float:fAngles[3], const String:sColour[], iDist, bool:bFlicker = true, client = 0, const String:sAttachment[] = "")
{
	new iEnt = CreateEntityByName("light_dynamic");
	if( iEnt == -1)
	{
		LogError("Failed to create 'light_dynamic'");
		return 0;
	}

	decl String:sStyle[16];
	if( bFlicker )
		Format(sStyle, sizeof(sStyle), "6");
	else
		Format(sStyle, sizeof(sStyle), "0");

	decl String:sTemp[16];
	Format(sTemp, sizeof(sTemp), "%s 255", sColour);
	DispatchKeyValue(iEnt, "_light", sTemp);
	DispatchKeyValue(iEnt, "brightness", "0");
	DispatchKeyValueFloat(iEnt, "spotlight_radius", 32.0);
	DispatchKeyValueFloat(iEnt, "distance", float(iDist));
	DispatchKeyValue(iEnt, "style", sStyle);
	DispatchSpawn(iEnt);
	AcceptEntityInput(iEnt, "TurnOn");

	// Attach to survivor
	new len = strlen(sAttachment);
	if( client )
	{
		if( len == 0 )
			Format(sTemp, sizeof(sTemp), "FLRG%i%i", iEnt, client);
		else
			Format(sTemp, sizeof(sTemp), "FLRL%i%i", iEnt, client);
		DispatchKeyValue(client, "targetname", sTemp);
		SetVariantString(sTemp);
		AcceptEntityInput(iEnt, "SetParent", iEnt, iEnt, 0);

		if( len != 0 )
		{
			SetVariantString(sAttachment);
			AcceptEntityInput(iEnt, "SetParentAttachment");
		}
	}

	TeleportEntity(iEnt, fOrigin, fAngles, NULL_VECTOR);
	return iEnt;
}



MakeEnvSprite(Float:fOrigin[3], Float:fAngles[3], const String:sColour[], client = 0)
{
	new iEnt = CreateEntityByName("env_sprite");
	if( iEnt == -1)
	{
		LogError("Failed to create 'env_sprite'");
		return 0;
	}

	decl String:sTemp[16];
	DispatchKeyValue(iEnt, "rendercolor", sColour);
	DispatchKeyValue(iEnt, "model", MODEL_SPRITE);
	DispatchKeyValue(iEnt, "spawnflags", "3");
	DispatchKeyValue(iEnt, "rendermode", "9");
	DispatchKeyValue(iEnt, "GlowProxySize", "256.0");
	DispatchKeyValue(iEnt, "renderamt", "120");
	DispatchKeyValue(iEnt, "scale", "256.0");
	DispatchSpawn(iEnt);

	// Attach to survivor
	if( client )
	{
		Format(sTemp, sizeof(sTemp), "FLR%i%i", iEnt, client);
		DispatchKeyValue(client, "targetname", sTemp);
		SetVariantString(sTemp);
		AcceptEntityInput(iEnt, "SetParent", iEnt, iEnt, 0);
	}

	TeleportEntity(iEnt, fOrigin, fAngles, NULL_VECTOR);
	return iEnt;
}



MakeEnvSteam(Float:fOrigin[3], Float:fAngles[3], const String:sColour[], iAlpha, iLength)
{
	new iEnt = CreateEntityByName("env_steam");
	if( iEnt == -1 )
	{
		LogError("Failed to create 'env_steam'");
		return 0;
	}

	decl String:sTemp[5];
	DispatchKeyValue(iEnt, "SpawnFlags", "1");
	DispatchKeyValue(iEnt, "rendercolor", sColour);
	DispatchKeyValue(iEnt, "SpreadSpeed", "1.0");
	DispatchKeyValue(iEnt, "Speed", "15");
	DispatchKeyValue(iEnt, "StartSize", "1");
	DispatchKeyValue(iEnt, "EndSize", "3");
	DispatchKeyValue(iEnt, "Rate", "10");
	IntToString(iLength, sTemp, sizeof(sTemp));
	DispatchKeyValue(iEnt, "JetLength", sTemp);
	IntToString(iAlpha, sTemp, sizeof(sTemp));
	DispatchKeyValue(iEnt, "renderamt", sTemp);
	DispatchKeyValue(iEnt, "InitialState", "1");
	DispatchSpawn(iEnt);
	AcceptEntityInput(iEnt, "TurnOn");

	TeleportEntity(iEnt, fOrigin, fAngles, NULL_VECTOR);
	return iEnt;
}



// ====================================================================================================
//						S O U N D
// ====================================================================================================
PlaySound(iEnt, Float:fTime)
{
	EmitSoundToAll(SOUND_CRACKLE, 
		iEnt,
		SNDCHAN_AUTO,
		SNDLEVEL_DISHWASHER,
		SND_SHOULDPAUSE,
		SNDVOL_NORMAL,
		SNDPITCH_HIGH,
		-1,
		NULL_VECTOR,
		NULL_VECTOR);

	CreateTimer(fTime, tmrStopSound, iEnt);
}



public Action:tmrStopSound(Handle:timer, any:iEnt)
{
	StopSound(iEnt, SNDCHAN_AUTO, SOUND_CRACKLE);
}



// ====================================================================================================
//					D E L E T E   E N T I T Y S
// ====================================================================================================
DeleteLight(client)
{
	new iEnt = g_iLightIndex[client];
	DeleteEntity(iEnt);
	g_iLightIndex[client] = 0;

	iEnt = g_iModelIndex[client];
	DeleteEntity(iEnt);
	g_iModelIndex[client] = 0;
}



DeleteEntity(iEnt)
{
	if( IsValidEntRef(iEnt) )
	{
		decl String:sClass[50];
		GetEdictClassname(iEnt, sClass, sizeof(sClass));

		if( StrEqual(sClass, "info_particle_system") )
		{
			AcceptEntityInput(iEnt, "Kill");
		}
		else if( StrEqual(sClass, "light_dynamic") )
		{
			AcceptEntityInput(iEnt, "Kill");
		}
		else if( StrEqual(sClass, "point_spotlight") )
		{
			AcceptEntityInput(iEnt, "TurnOff");
			CreateTimer(0.1, tmrDeleteEntity, iEnt);
		}
		else if( StrEqual(sClass, "env_sprite") )
		{
			AcceptEntityInput(iEnt, "Kill");
		}
		else if( StrEqual(sClass, PROJECTILE) )
		{
			AcceptEntityInput(iEnt, "Kill");
		}
		else if( StrEqual(sClass, "env_steam") )
		{
			AcceptEntityInput(iEnt, "TurnOff");
			CreateTimer(10.0, tmrDeleteEntity, iEnt);
		}
		else if( StrEqual(sClass, "prop_dynamic") )
		{
			GetEntPropString(iEnt, Prop_Data, "m_ModelName", sClass, sizeof(sClass));
			if( StrEqual(MODEL_FLARE, sClass) || StrEqual(MODEL_LIGHT, sClass) )
			{
				AcceptEntityInput(iEnt, "Kill");
			}
		}
	}
}



public Action:tmrDeleteEntity(Handle:timer, any:iEnt)
{
	if( IsValidEntRef(iEnt) )
		AcceptEntityInput(iEnt, "kill");
}



public Action:tmrDeleteEnts(Handle:timer, Handle:hPack)
{
	new iEnt;
	FlareTimerHandler(timer, true);
	ResetPack(hPack);

	iEnt = ReadPackCell(hPack);
	DeleteEntity(iEnt);
	iEnt = ReadPackCell(hPack);
	DeleteEntity(iEnt);
	iEnt = ReadPackCell(hPack);
	DeleteEntity(iEnt);
	iEnt = ReadPackCell(hPack);
	DeleteEntity(iEnt);

	iEnt = ReadPackCell(hPack);
	iEnt = EntRefToEntIndex(iEnt);
	if( iEnt != INVALID_ENT_REFERENCE )
		StopSound(iEnt, SNDCHAN_AUTO, SOUND_CRACKLE);
}



FlareTimerHandler(Handle:hTimer, bool:bRemove = false)
{
	for( new i = 0; i < sizeof(g_hFlareTimerHandles); i++ )
	{
		if( bRemove )
		{
			if( g_hFlareTimerHandles[i] == hTimer )
			{
				g_hFlareTimerHandles[i] = INVALID_HANDLE;
				return;
			}
		}
		else
		{
			if( g_hFlareTimerHandles[i] == INVALID_HANDLE )
			{
				g_hFlareTimerHandles[i] = hTimer;
				return;
			}
		}
	}
}



// ====================================================================================================
//					B O O L E A N S
// ====================================================================================================
bool:IsAllowedGameMode()
{
	if( g_hMPGameMode == INVALID_HANDLE )
		return false;

	decl String:sGameMode[32], String:sGameModes[64];

	GetConVarString(g_hModes, sGameModes, sizeof(sGameModes));
	if( strlen(sGameModes) == 0 )
		return g_bModeOk = true;

	GetConVarString(g_hMPGameMode, sGameMode, sizeof(sGameMode));
	Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
	Format(sGameMode, sizeof(sGameMode), ",%s,", sGameMode);
	g_bModeOk = (StrContains(sGameModes, sGameMode) != -1);
	return g_bModeOk;
}



bool:IsValidEntRef(iEnt)
{
	if( iEnt && EntRefToEntIndex(iEnt) != INVALID_ENT_REFERENCE )
		return true;
	return false;
}



bool:IsValidForFlare(client)
{
	if( !client || !IsClientInGame(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client) )
		return false;
	return true;
}



bool:IsFlareValidNow()
{
	if( !g_bModeOk || g_bRoundOver || !g_bEnabled )
		return false;
	return true;
}



bool:IsIncapped(client)
{
	return bool:GetEntProp(client, Prop_Send, "m_isIncapacitated", 1);
}



// ====================================================================================================
//					S D K H O O K S   T R A N S M I T
// ====================================================================================================
public Action:Hook_SetTransmit(entity, client)
{
	if( IsFakeClient(client) )
		return Plugin_Continue;

	new iFlare = g_iAttachedFlare[client];
	new iLight = g_iModelIndex[client];

	if( iFlare && EntRefToEntIndex(iFlare) == entity || iLight && EntRefToEntIndex(iLight) == entity )
		return Plugin_Handled;
	return Plugin_Continue;
}