/**
 * =============================================================================
 * SourceMod roll the dice plugin
 * Fun plugin: roll the dice for a nice surprise
 *
 * (C)2009-2010 ata-clan.de
 *
 * for updates check: http://forums.alliedmods.net/showthread.php?t=94835
 *
 * =============================================================================
 *time
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
 * Version: $Id$
 */
 
/*
Changelog:
0.2:
	* Initial release
0.3:
	* Added some comments to code
	* Berserker kills have some extra gore and victims are knocked back
	* Plugin announcement as requested
	* Ability to enable/disable single features as requested
	* Configurable sounds
	* Added beacon to "Glow" effect
0.3.1:
	* Bug fixes
0.4.0:
	* Bug Fixes
	* Configurable dice count per map as requested
	* Configurable amount of extra gore in berserker mode
	* Added effect: infinite ammo
	* Added effect: weapon jam
	* Added effect: froggy legs
0.4.1:
	* Fixed: sounds not playing sometimes
0.5.0:
	* using ataextension (optinal: sdkhooks or none) instead of dukehacks
0.5.1:
	* using no extensions at all
0.5.2:
	* fixed announcement timer bug (thanks to dataviruset)
0.5.3b (dataviruset edit):
	* translation problems fixed
0.5.3c (dataviruset edit):
	* updated gamedata to work with Windows-servers
0.5.4:
	* merged dataviruset's changes
0.5.4b: (fix by Itaku):
	* fixed g_hBloodSpray INVALID_HANDLE error by completely removing beserker's gore since author is inactive.
*/

#pragma semicolon 1

#include <sdktools>
#include <sdktools_sound>
#include <sdktools_stringtables>
#include <ata_tools>

#define USE_DEALDAMAGE

#define PLUGIN_VERSION						"0.5.4b"

#define PLUGIN_CFGNAME						"ata_rollthedice"
#define PLUGIN_PHRASES						"ata_rollthedice.phrases"
#define PLUGIN_SMCFGFILE					"configs/ata_rollthedice.cfg"
#define GAMECONF									"ata_rollthedice.games"
#define COMMAND_RTD								"rollthedice"
#define COMMAND_RTDSHORT					"rtd"

#define MAX_ITEMS									32
#define MAX_ITEM_SIZE							64

// Didn't find a working chicken-model for CS:S yet. If you find one, let me know =)
//#define TEST_MODEL_CHANGE
//#define ENABLE_MODEL_CHANGE
#if defined(ENABLE_MODEL_CHANGE)
	#define MODEL_CHICKEN						"models/player/chicken/chicken.mdl"
	#define SOUND_CHICKEN						"ata/chicken1.mp3"
#endif

// client state flags
#define CLIENTFLAG_VAMPIRIC				0x00000001
#define CLIENTFLAG_MIRRORDAMAGE		0x00000002
#define CLIENTFLAG_SUNGLASSES			0x00000004
#define CLIENTFLAG_BERSERKER			0x00000008
#define CLIENTFLAG_INVISIBLE			0x00000010
#define CLIENTFLAG_INFINITE_AMMO	0x00000020
#define CLIENTFLAG_WEAPON_JAM			0x00000040
#define CLIENTFLAG_HIGH_JUMP			0x00000080

#define CLIENTFLAG_LOCK_ATTACKER	0x01000000

// CVar handles
new Handle:g_hPluginEnable				= INVALID_HANDLE;
new Handle:g_hAnnounceInterval		= INVALID_HANDLE;
new Handle:g_hMaxThrowsPerRound		= INVALID_HANDLE;
new Handle:g_hMaxThrowsPerMap			= INVALID_HANDLE;
new Handle:g_hGiveItems						= INVALID_HANDLE;
new Handle:g_hGiveMoneyMin				= INVALID_HANDLE;
new Handle:g_hGiveMoneyMax				= INVALID_HANDLE;
new Handle:g_hTakeMoneyMin				= INVALID_HANDLE;
new Handle:g_hTakeMoneyMax				= INVALID_HANDLE;
new Handle:g_hInvisibility				= INVALID_HANDLE;
new Handle:g_hSpeedSlow						= INVALID_HANDLE;
new Handle:g_hSpeedFast						= INVALID_HANDLE;
new Handle:g_hVampiricFactor			= INVALID_HANDLE;
new Handle:g_hMirrorDamageFactor	= INVALID_HANDLE;
new Handle:g_hBerserkerSpeed			= INVALID_HANDLE;
new Handle:g_hBerserkerHealth			= INVALID_HANDLE;
new Handle:g_hBerserkerArmor			= INVALID_HANDLE;
new Handle:g_hBerserkerKnockback	= INVALID_HANDLE;
//new Handle:g_hBerserkerExtraGore	= INVALID_HANDLE;
new Handle:g_hHighJumpBoost				= INVALID_HANDLE;
new Handle:g_hWeaponJamProbability= INVALID_HANDLE;

// gamedata file handle
new Handle:g_hGameConf						= INVALID_HANDLE;

// handle for plugin announcement timer
new Handle:g_hTimerAnnouncement		= INVALID_HANDLE;

// handle for TimerDelayedEffect()
new Handle:g_phTimerDelayedEffect[MAXPLAYERS + 1];

// offsets
new	g_iAccount										= -1;
new	g_iFlashMaxAlpha							= -1;

new g_pnClientDiceCountPerRound[MAXPLAYERS + 1];
new g_pnClientDiceCountPerMap[MAXPLAYERS + 1];
new g_pnClientFlags[MAXPLAYERS + 1];
new g_pnClientDiceIndex[MAXPLAYERS + 1];	// keep track of dice results for referencing sounds etc.

// beacon stuff
#define SOUND_BEACON							"ambient/tones/floor1.wav" //"plats/elevbell1.wav"
new Handle:g_phTimerClientBeacons[MAXPLAYERS + 1];
new g_nSpriteBeaconModel					= 0;
new g_nSpriteBeaconIndex					= 0;

// store clip 1/2 values for weapon jam
new g_pnClientClip[MAXPLAYERS + 1][2];

// extra gore handles
new Handle:g_hBloodDrips					= INVALID_HANDLE;
//new Handle:g_hBloodSpray					= INVALID_HANDLE;

// if players roll the dice, they get up- or downgrade which we'll call "effect" in the following
#define MAX_EFFECTS								20		// effects arrays size
new g_nEffectsCount								= 0;	// will be set on config load => how many effects are actually used
new g_pnEffectIDs[MAX_EFFECTS];					// array that holds internal effect IDs
new String:g_psEffectSounds[MAX_EFFECTS][PLATFORM_MAX_PATH + 1];	// string array that holds paths to sound files for each effect
new bool:g_pbEffectSoundsDownload[MAX_EFFECTS]; // should this sound file be added to download table?

// see comment for "ENABLE_MODEL_CHANGE" above
#if defined(ENABLE_MODEL_CHANGE)
	new Handle:g_hSetModel						= INVALID_HANDLE;
	new	g_iModelChicken								= -1;
	new	String:g_psPlayerModels[MAXPLAYERS + 1][128];
#endif

#if !defined(USE_DEALDAMAGE)
// attackers list to correctly account knife kills in berserker mode
new g_pnClientAttackers[MAXPLAYERS + 1];
#endif

// ----------------------------------------------------------------------------
public Plugin:myinfo = 
// ----------------------------------------------------------------------------
{
	name					= "Roll The Dice",
	author				= "ata-clan.de, dataviruset (g_hBloodSpray error fix by Itaku)",
	description		= "Roll the dice for a nice surprise",
	version				= PLUGIN_VERSION,
	url						= "http://www.ata-clan.de/"
};

// ----------------------------------------------------------------------------
public ReadEffectsConfig()
// ----------------------------------------------------------------------------
{
	// this function reads each effect from addons/sourcemod/config/ata_rollthedice.cfg
	// so you can define what effects should be used on your server by enabling/disabling them

	// build path to cfg file
	decl String:sConfigPath[PLATFORM_MAX_PATH + 1];
	BuildPath(Path_SM, sConfigPath, sizeof(sConfigPath), PLUGIN_SMCFGFILE);

	if(!FileExists(sConfigPath))
	{
		SetFailState("File \"%s\" doesn't exist!", sConfigPath);
		return false;
	}

	g_nEffectsCount = 0;

	new Handle:hConfigFile = CreateKeyValues("rollthedice");
	FileToKeyValues(hConfigFile, sConfigPath);
	KvRewind(hConfigFile);
	if(!KvGotoFirstSubKey(hConfigFile))
	{
		SetFailState("Couldn't parse \"%s\"!", sConfigPath);
		return false;
	}

	// parse effect sections
	do
	{
		// read ID and parameters for this effect
		g_pnEffectIDs[g_nEffectsCount] = KvGetNum(hConfigFile, "effect_id");
		g_psEffectSounds[g_nEffectsCount][0] = '\0';
		KvGetString(hConfigFile, "soundfile", g_psEffectSounds[g_nEffectsCount], PLATFORM_MAX_PATH);
		g_pbEffectSoundsDownload[g_nEffectsCount] = (KvGetNum(hConfigFile, "soundfile_download") == 1);

		g_nEffectsCount++;	// inrement effects count so we know the size of our dice later
	}
	while(KvGotoNextKey(hConfigFile));

	CloseHandle(hConfigFile);
	return true;
}

// ----------------------------------------------------------------------------
public OnPluginStart()
// ----------------------------------------------------------------------------
{
	// init CVars
	g_hPluginEnable				= CreateConVar("sm_rtd_enable",								"1",					"enable the plugin", _, true, 0.0, true, 1.0);
	g_hAnnounceInterval		= CreateConVar("sm_rtd_announce_interval",		"120",				"interval (in seconds) for plugin announecment, set to 0 to disable", _, true, 1.0, true, 3600.0);
	g_hMaxThrowsPerRound	= CreateConVar("sm_rtd_dices_per_round",			"1",					"how often may players throw the dice per round", _, true, 0.0, false);
	g_hMaxThrowsPerMap		= CreateConVar("sm_rtd_dices_per_map",				"0",					"how often may players throw the dice per map (0 = inifnite)", _, true, 0.0, false);
	g_hGiveItems					= CreateConVar("sm_rtd_give_items",						"weapon_usp weapon_glock weapon_deagle weapon_p228 weapon_elite weapon_fiveseven weapon_m4a1 weapon_ak47 weapon_aug weapon_sg552 weapon_galil weapon_famas weapon_scout weapon_sg550 weapon_m249 weapon_g3sg1 weapon_ump45 weapon_mp5navy weapon_m3 weapon_xm1014 weapon_tmp weapon_mac10 weapon_p90 weapon_awp weapon_smokegrenade weapon_hegrenade weapon_flashbang",			"list of possible items to give to player");
	g_hGiveMoneyMin				= CreateConVar("sm_rtd_give_money_min",				"100",				"minimum amount of money a player may win", _, true, 0.0, true, 16000.0);
	g_hGiveMoneyMax				= CreateConVar("sm_rtd_give_money_max",				"3000",				"maximum amount of money a player may win", _, true, 0.0, true, 16000.0);
	g_hTakeMoneyMin				= CreateConVar("sm_rtd_take_money_min",				"500",				"minimum amount of money a player may loose", _, true, 0.0, true, 16000.0);
	g_hTakeMoneyMax				= CreateConVar("sm_rtd_take_money_max",				"5000",				"maximum amount of money a player may loose", _, true, 0.0, true, 16000.0);
	g_hInvisibility				= CreateConVar("sm_rtd_invisibility",					"85",					"invisibility in percent (100 = completely invisible)", _, true, 0.0, true, 100.0);
	g_hSpeedSlow					= CreateConVar("sm_rtd_slowdown",							"0.5",				"player speed when slowed down", _, true, 0.1, true, 0.9);
	g_hSpeedFast					= CreateConVar("sm_rtd_speedup",							"1.5",				"player speed when speed up", _, true, 1.0, true, 3.0);
	g_hVampiricFactor			= CreateConVar("sm_rtd_vampiric_factor",			"0.5",				"adds damage given to other players to own health", _, true, 0.0, true, 10.0);
	g_hMirrorDamageFactor	= CreateConVar("sm_rtd_mirror_damage_factor",	"0.5",				"mirrors damage given to other players", _, true, 0.0, true, 10.0);
	g_hBerserkerSpeed			= CreateConVar("sm_rtd_berserker_speed",			"1.5",				"player speed when in berserker mode", _, true, 1.0, true, 3.0);
	g_hBerserkerHealth		= CreateConVar("sm_rtd_berserker_health",			"250",				"player health when in berserker mode", _, true, 1.0, true, 255.0);
	g_hBerserkerArmor			= CreateConVar("sm_rtd_berserker_armor",			"100",				"player armor when in berserker mode", _, true, 0.0, true, 100.0);
	g_hBerserkerKnockback	= CreateConVar("sm_rtd_berserker_knockback",	"500",				"victim knockback when in berserker mode", _, true, 0.0, true, 1000.0);
//	g_hBerserkerExtraGore	= CreateConVar("sm_rtd_berserker_extra_gore",	"5",					"amount of extra gore in berserker mode", _, true, 0.0, true, 10.0);
	g_hHighJumpBoost			= CreateConVar("sm_rtd_highjump_boost",				"420",				"amount of extra jump boost in frog mode", _, true, 0.0, true, 1000.0);
	g_hWeaponJamProbability= CreateConVar("sm_rtd_weapon_jam_probability", "4",				"approx. every n-th shot will force a reload", _, true, 0.0, true, 50.0);
	AutoExecConfig(true, PLUGIN_CFGNAME);

	if(GetConVarBool(g_hPluginEnable))
	{
		// load translations
		LoadTranslations("common.phrases");
		LoadTranslations(PLUGIN_PHRASES);

		// find offsets for some properties
		g_iAccount				= FindSendPropOffs("CCSPlayer", "m_iAccount");
		g_iFlashMaxAlpha	= FindSendPropOffs("CCSPlayer", "m_flFlashMaxAlpha");

		ReadEffectsConfig();

		// init SDK calls
		g_hGameConf = LoadGameConfigFile(GAMECONF);
		if(g_hGameConf == INVALID_HANDLE)
		{
			SetFailState("Couldn't load \"%s\"!", GAMECONF);
		}
		else
		{
#if defined(ENABLE_MODEL_CHANGE)
			// ..SetModel
			StartPrepSDKCall(SDKCall_Player);
			PrepSDKCall_SetFromConf(g_hGameConf, SDKConf_Virtual, "SetModel");
			PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
			g_hSetModel = EndPrepSDKCall();
			if(g_hSetModel == INVALID_HANDLE)
				SetFailState("g_hSetModel = INVALID_HANDLE!");
#endif

			// ...blood drips
			StartPrepSDKCall(SDKCall_Static);
			PrepSDKCall_SetFromConf(g_hGameConf, SDKConf_Signature, "BloodDrips");
			PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_Plain);
			PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_Plain);
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
			g_hBloodDrips = EndPrepSDKCall();
			if(g_hBloodDrips == INVALID_HANDLE)
				SetFailState("g_hBloodDrips = INVALID_HANDLE!");

			// ...blood spray
/*			StartPrepSDKCall(SDKCall_Static);
			PrepSDKCall_SetFromConf(g_hGameConf, SDKConf_Signature, "BloodSpray");
			PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_Plain);
			PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_Plain);
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
			g_hBloodSpray = EndPrepSDKCall();	
			if(g_hBloodSpray == INVALID_HANDLE)
				SetFailState("g_hBloodSpray = INVALID_HANDLE!");
*/
		}

		// init random number generator
		SetRandomSeed(RoundToFloor(GetEngineTime()));

		// register console commands
		RegConsoleCmd(COMMAND_RTD, RollTheDice, "Roll The Dice!");
		RegConsoleCmd(COMMAND_RTDSHORT, RollTheDice, "Roll The Dice!");

		// hook events
		HookEvent("player_spawn",	EventPlayerSpawn);
		HookEvent("player_blind",	EventPlayerBlind);
		HookEvent("player_hurt",	EventPlayerHurt);
#if !defined(USE_DEALDAMAGE)
		HookEvent("player_death",	EventPlayerDeath_Pre,		EventHookMode_Pre);
#endif
		HookEvent("player_death",	EventPlayerDeath);
		HookEvent("player_jump",	EventPlayerJump);
		HookEvent("item_pickup",	EventItemPickup,				EventHookMode_Post);
		HookEvent("weapon_fire",	EventWeaponFire);
	}
}

// ----------------------------------------------------------------------------
public OnMapStart()
// ----------------------------------------------------------------------------
{
	if(GetConVarBool(g_hPluginEnable))
	{
		// precache sounds, models, etc...
#if defined(ENABLE_MODEL_CHANGE)
		g_iModelChicken = PrecacheModel(MODEL_CHICKEN);
		AddFileToDownloadsTable(MODEL_CHICKEN);
#endif

		PrecacheModel("models/gibs/hgibs.mdl", true);
		PrecacheModel("models/gibs/hgibs_rib.mdl", true);
		PrecacheModel("models/gibs/hgibs_spine.mdl", true);
		PrecacheModel("models/gibs/hgibs_scapula.mdl", true);

		g_nSpriteBeaconIndex = PrecacheModel("materials/sprites/halo01.vmt");
		g_nSpriteBeaconModel = PrecacheModel("materials/sprites/laserbeam.vmt");

		for(new i=0; i<g_nEffectsCount; i++)
		{
			if(strlen(g_psEffectSounds[i]) > 0)
			{
				if(g_pbEffectSoundsDownload[i])
					AddFileToDownloadsTable(g_psEffectSounds[i]);
				PrecacheSound(g_psEffectSounds[i]);
			}
		}

		// reset dice count per round to 0 and some other stuff
		for(new i=0; i<MAXPLAYERS; i++)
		{
			g_pnClientDiceCountPerRound[i]	= 0;
			g_pnClientDiceCountPerMap[i]		= 0;
			g_phTimerClientBeacons[i]				= INVALID_HANDLE;
			g_pnClientDiceIndex[i]					= -1;
			g_phTimerDelayedEffect[i]				= INVALID_HANDLE;
		}

		// announcement timer
		if(GetConVarFloat(g_hAnnounceInterval) > 0 && g_hTimerAnnouncement == INVALID_HANDLE)
			g_hTimerAnnouncement = CreateTimer(GetConVarFloat(g_hAnnounceInterval), TimerAnnouncement, _, TIMER_REPEAT);
	}
}

// ----------------------------------------------------------------------------
public OnMapEnd()
// ----------------------------------------------------------------------------
{
	// remove beacon timers
	for(new i=0; i<MAXPLAYERS; i++)
		SafeCloseHandle(g_phTimerClientBeacons[i]);

	SafeCloseHandle(g_hTimerAnnouncement);

	// clean things up, don't know if this is really necessary
#if defined(ENABLE_MODEL_CHANGE)
	SafeCloseHandle(g_hSetModel);
#endif
	SafeCloseHandle(g_hBloodDrips);
//	SafeCloseHandle(g_hBloodSpray);
	SafeCloseHandle(g_hGameConf);
}

// ----------------------------------------------------------------------------
public Action:EventPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
// ----------------------------------------------------------------------------
{
	// get client ID of player
	new nClient = GetClientOfUserId(GetEventInt(event, "userid"));
	if(GetClientTeam(nClient) <= CSS_TEAM_SPECTATOR)
		return Plugin_Continue;

	// reset dice count and flags for this player
	g_pnClientDiceCountPerRound[nClient]		= 0;
	g_pnClientFlags[nClient]								= 0;
	g_pnClientDiceIndex[nClient]						= -1;

	g_pnClientClip[nClient][0]							= -1;
	g_pnClientClip[nClient][1]							= -1;

#if !defined(USE_DEALDAMAGE)
	g_pnClientAttackers[nClient]						= -1;
#endif

	// reset movement speed to default
	SetEntPropFloat(nClient, Prop_Data, "m_flLaggedMovementValue", 1.0);

	// remove screen overlay
	ClientCommand(nClient, "r_screenoverlay 0");

	// reset render state to default
	SetGlow(nClient);

	// remove beacon timer
	SafeCloseHandle(g_phTimerClientBeacons[nClient]);

	SafeCloseHandle(g_phTimerDelayedEffect[nClient]);

#if defined(ENABLE_MODEL_CHANGE) && defined(TEST_MODEL_CHANGE)
	// set default model
	if(g_hSetModel != INVALID_HANDLE)
	{
		EmitSoundToAll(SOUND_CHICKEN);
		SDKCall(g_hSetModel, nClient, MODEL_CHICKEN);
	}
#endif

	return Plugin_Continue;
}

// ----------------------------------------------------------------------------
public Action:EventPlayerBlind(Handle:event, const String:name[], bool:dontBroadcast)
// ----------------------------------------------------------------------------
{
	// prevent player from being blindet if he has sunglasses flag
	new nClient = GetClientOfUserId(GetEventInt(event, "userid"));
	if(GetClientTeam(nClient) > CSS_TEAM_SPECTATOR && g_pnClientFlags[nClient] & CLIENTFLAG_SUNGLASSES != 0 && g_iFlashMaxAlpha != -1)
		SetEntDataFloat(nClient, g_iFlashMaxAlpha, 0.5);

	return Plugin_Continue;
}

// ----------------------------------------------------------------------------
public Action:EventPlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
// ----------------------------------------------------------------------------
{
	// get event parameters
	new nClientVictim		= GetClientOfUserId(GetEventInt(event, "userid"));
	new nClientAttacker	= GetClientOfUserId(GetEventInt(event, "attacker"));
	new nDamage					= GetEventInt(event, "dmg_health");

	if(g_pnClientFlags[nClientAttacker] & CLIENTFLAG_VAMPIRIC)
	{
		// if attacker has vampiric flag, give him some health for shooting his victim
		new nHP = GetClientHealth(nClientAttacker) + RoundToFloor(nDamage * GetConVarFloat(g_hVampiricFactor));
		if(nHP > 100)
			nHP = 100;
		SetEntProp(nClientAttacker, Prop_Send, "m_iHealth", nHP);
	}
	if(g_pnClientFlags[nClientAttacker] & CLIENTFLAG_MIRRORDAMAGE)
	{
		// if attacker has mirror damage flag, remove some health for shooting his victim
		new nHP = GetClientHealth(nClientAttacker) - RoundToFloor(nDamage * GetConVarFloat(g_hMirrorDamageFactor));
		if(nHP < 1)
			nHP = 1;
		SetEntProp(nClientAttacker, Prop_Send, "m_iHealth", nHP);
	}
	if(g_pnClientFlags[nClientAttacker] & CLIENTFLAG_BERSERKER)
	{
		// if attacker has berserker flag...
		// ...get weapon name from event parameters (should always be knife, so this is a double check here)
		new String:sWeapon[64];
		GetEventString(event, "weapon", sWeapon, sizeof(sWeapon));
		if(StrEqual(sWeapon, "knife"))
		{
			// read knockback power from cvar
			new Float:fKnockback = GetConVarFloat(g_hBerserkerKnockback);

			// add some extra blood spray and gore
//			AddExtraGore(g_hBloodDrips, g_hBloodSpray, nClientAttacker, nClientVictim, GetConVarInt(g_hBerserkerExtraGore), fKnockback/2.0, 0.0);

			// knock the victim back
			if(fKnockback > 0.0)
				ImpactKnockback(nClientAttacker, nClientVictim, fKnockback, 23.5);

			// kill victim instantly
#if !defined(USE_DEALDAMAGE)
			if(g_pnClientFlags[nClientAttacker] & CLIENTFLAG_LOCK_ATTACKER == 0)	// g_pnClientAttackers "mutex"
			{
				g_pnClientFlags[nClientAttacker]	 |= CLIENTFLAG_LOCK_ATTACKER;
				g_pnClientAttackers[nClientVictim]	= nClientAttacker;
				CreateTimer(0.2, TimerBerserkerKill, nClientAttacker | (nClientVictim << 8));
			}
#else
			CreateTimer(0.2, TimerBerserkerKill, nClientAttacker | (nClientVictim << 8));
#endif
		}
		else
			ForcePlayerSuicide(nClientAttacker);	// berserkers have to use knife only!
	}

	return Plugin_Continue;
}

// ----------------------------------------------------------------------------
public Action:TimerBerserkerKill(Handle:timer, any:nClients)
// ----------------------------------------------------------------------------
{
	// timed death of player, so the knockback effect doesn't get prevented by the default death animation
	// this is a dirty hack, didn't find a better solution yet...
	new nClientVictim		= (nClients & 0xFF00) >> 8;
//	new nClientAttacker	= (nClients & 0x00FF);

	// unfortunately, the victims death won't be counted as knife kill by the berkerker
	// this is simulated in OnPlayerDeath instead

//	// set victims health to 0
////	new nOffsetHP = FindDataMapOffs(nClientVictim, "m_iHealth");
////	SetEntData(nClientVictim, nOffsetHP, 0, true);

#if !defined(USE_DEALDAMAGE)
	// setting health to 0 doesn't kill the player, so force suicide and set killer/weapon in EventPlayerDeath_Pre below
	ForcePlayerSuicide(nClientVictim);
#else
	new nOffsetHP = FindDataMapOffs(nClientVictim, "m_iHealth");
	SetEntData(nClientVictim, nOffsetHP, 1, true);

	new nClientAttacker	= (nClients & 0x00FF);
	DealDamage(nClientVictim, 25, nClientAttacker, DMG_SLASH, "knife");
#endif
}

#if !defined(USE_DEALDAMAGE)
// ----------------------------------------------------------------------------
public Action:EventPlayerDeath_Pre(Handle:event, const String:name[], bool:dontBroadcast)
// ----------------------------------------------------------------------------
{
	new nClientVictim		= GetClientOfUserId(GetEventInt(event, "userid"));
	new nClientAttacker	= GetClientOfUserId(GetEventInt(event, "attacker"));

//	PrintToChatAll("v: %d, a: %d, va: %d", nClientVictim, nClientAttacker, g_pnClientAttackers[nClientVictim]);

	if(	(nClientAttacker == -1 ||
			nClientAttacker == nClientVictim ||
			nClientAttacker >= MAXPLAYERS) &&					// attacker must not be a player for berserker kills (see TimerBerserkerKill above)
			g_pnClientAttackers[nClientVictim] != -1)	// victim must have an attacker assigned in EventPlayerHurt
	{
		// "real" attacker has to be in game and in berserker mode
		if(IsClientInGame(g_pnClientAttackers[nClientVictim]) && g_pnClientFlags[g_pnClientAttackers[nClientVictim]] & CLIENTFLAG_BERSERKER)
		{
			g_pnClientAttackers[nClientVictim] = -1;

			SetEventInt(event, 		"userid", GetClientUserId(nClientVictim));
			SetEventInt(event,		"attacker",	GetClientUserId(g_pnClientAttackers[nClientVictim]));
			SetEventString(event,	"weapon",		"knife");
			SetEventBool(event,		"headshot",	true);
 
//			PrintToChatAll("TEST");

			new nAttackerFrags = GetClientFrags(g_pnClientAttackers[nClientVictim]);
			if(GetClientTeam(g_pnClientAttackers[nClientVictim]) != GetClientTeam(nClientVictim))
				nAttackerFrags += 1;
			else
				nAttackerFrags -= 1;
			SetEntProp(g_pnClientAttackers[nClientVictim], Prop_Data, "m_iFrags", nAttackerFrags);

			// compensate suicide
			new nVictimFrags = GetClientFrags(nClientVictim);
			SetEntProp(nClientVictim, Prop_Data, "m_iFrags", nVictimFrags+1);
		}
	}

	return Plugin_Changed;
}
#endif

/*
// TEST
// ----------------------------------------------------------------------------
public Action:EventPlayerDeath_Pre(Handle:event, const String:name[], bool:dontBroadcast)
// ----------------------------------------------------------------------------
{
	new nClientVictim = GetEventInt(event, "userid");
	new iClientVictim = GetClientOfUserId(nClientVictim);

	new ClientRagdoll = GetEntPropEnt(iClientVictim, Prop_Send, "m_hRagdoll");

	new Float:XMultiplier = 10.0;
	new Float:YMultiplier = 10.0;
	new Float:ZMultiplier = 10.0;

	new Float:Force[3];
	GetEntPropVector(ClientRagdoll, Prop_Send, "m_vecForce", Force);
	Force[0] *= XMultiplier;
	Force[1] *= YMultiplier;
	Force[2] *= ZMultiplier;
	SetEntPropVector(ClientRagdoll, Prop_Send, "m_vecForce", Force);

	new Float:Velocity[3];
	GetEntPropVector(ClientRagdoll, Prop_Send, "m_vecRagdollVelocity", Velocity);
	Velocity[0] *= XMultiplier;
	Velocity[1] *= YMultiplier;
	Velocity[2] *= ZMultiplier;
	SetEntPropVector(ClientRagdoll, Prop_Send, "m_vecRagdollVelocity", Velocity);

	return Plugin_Continue; 
}
*/

// ----------------------------------------------------------------------------
public Action:EventPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
// ----------------------------------------------------------------------------
{
	new nClientVictim		= GetClientOfUserId(GetEventInt(event, "userid"));
//	new nClientAttacker	= GetClientOfUserId(GetEventInt(event, "attacker"));
//	new bool:bHeadShot	= GetEventBool(GetEventInt(event, "headshot"));

	SafeCloseHandle(g_phTimerDelayedEffect[nClientVictim]);

	// remove screen overlay
	ClientCommand(nClientVictim, "r_screenoverlay 0");

	// remove beacon timer
	SafeCloseHandle(g_phTimerClientBeacons[nClientVictim]);

/*
	// have been playing around with ragdoll here for the knockback effect.
	// didn't work for me so i ended up using the dirty hack mentioned above ;)
	new nOffsetRagdoll		= FindSendPropInfo("CCSPlayer", "m_hRagdoll");
	new nEntityIDRagdoll	= GetEntDataEnt2(nClientVictim, nOffsetRagdoll);
	if(nEntityIDRagdoll != -1)
//	new nEntityIDRagdoll = GetEntPropEnt(nClientVictim, Prop_Send, "m_hRagdoll");
//	if(IsValidEdict(nEntityIDRagdoll))
	{
		new Float:fKnockback = GetConVarFloat(g_hBerserkerKnockback);
		if(fKnockback > 0.0)
			ImpactKnockback(nClientAttacker, nEntityIDRagdoll, fKnockback);
	}
*/

	return Plugin_Continue;
}

// ----------------------------------------------------------------------------
public Action:EventPlayerJump(Handle:event, const String:name[], bool:dontBroadcast)
// ----------------------------------------------------------------------------
{
	new nClient = GetClientOfUserId(GetEventInt(event, "userid"));
	if(g_pnClientFlags[nClient] & CLIENTFLAG_HIGH_JUMP/* && IsPlayerAlive(nClient) && GetClientTeam(nClient) > CSS_TEAM_SPECTATOR*/)
	{
		if(g_pnClientDiceIndex[nClient] != -1)
			EmitSoundToClient(nClient, g_psEffectSounds[g_pnClientDiceIndex[nClient]]);	// play "jump" sound

		g_phTimerDelayedEffect[nClient] = CreateTimer(0.1, TimerDelayedEffect, nClient);
	}

	return Plugin_Continue;
}

// ----------------------------------------------------------------------------
public Action:EventItemPickup(Handle:event, const String:name[], bool:dontBroadcast)
// ----------------------------------------------------------------------------
{
	new nClient = GetClientOfUserId(GetEventInt(event, "userid"));
	if(GetClientTeam(nClient) > CSS_TEAM_SPECTATOR)
	{
		if(g_pnClientFlags[nClient] & CLIENTFLAG_BERSERKER)	// prevent player from picking up anything in berserker mode
			if(g_phTimerDelayedEffect[nClient] == INVALID_HANDLE)
				g_phTimerDelayedEffect[nClient] = CreateTimer(0.1, TimerDelayedEffect, nClient);
		if(g_pnClientFlags[nClient] & CLIENTFLAG_INVISIBLE)	// repeat SetPlayerAlpha() to make items picked up invisible too
			SetPlayerAlpha(nClient, 255-(GetConVarInt(g_hInvisibility) * 255 / 100));
	}

//	return Plugin_Continue;
}

// ----------------------------------------------------------------------------
public Action:EventWeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
// ----------------------------------------------------------------------------
{
	new nClient = GetClientOfUserId(GetEventInt(event, "userid"));
	decl String:sWeapon[64];
	GetEventString(event, "weapon", sWeapon, sizeof(sWeapon));
	if(GetClientTeam(nClient) > CSS_TEAM_SPECTATOR
		&& !StrEqual(sWeapon, "knife")
		&& !StrEqual(sWeapon, "smokegrenade")
		&& !StrEqual(sWeapon, "hegrenade")
		&& !StrEqual(sWeapon, "flashbang")
		&& !StrEqual(sWeapon, "c4"))
	{
		if(g_pnClientFlags[nClient] & CLIENTFLAG_INFINITE_AMMO)	// replenish ammo
		{
			new nEntityPropertyActiveWeapon = GetEntPropEnt(nClient, Prop_Send, "m_hActiveWeapon");
			SetEntProp(nEntityPropertyActiveWeapon, Prop_Send, "m_iClip1", 100);
			SetEntProp(nEntityPropertyActiveWeapon, Prop_Send, "m_iClip2", 100);
		}
		if(g_pnClientFlags[nClient] & CLIENTFLAG_WEAPON_JAM)		// jam weapon
		{
			if(GetRandomInt(0, GetConVarInt(g_hWeaponJamProbability)) == 0)
			{
				if(g_pnClientClip[nClient][0] == 1 || g_pnClientClip[nClient][1] == -1)
				{
					new nEntityPropertyActiveWeapon = GetEntPropEnt(nClient, Prop_Send, "m_hActiveWeapon");
					if(g_pnClientClip[nClient][0] == -1)
					{
						g_pnClientClip[nClient][0] = GetEntProp(nEntityPropertyActiveWeapon, Prop_Send, "m_iClip1");
						SetEntProp(nEntityPropertyActiveWeapon, Prop_Send, "m_iClip1", 1);
					}
					if(g_pnClientClip[nClient][1] == -1)
					{
						g_pnClientClip[nClient][1] = GetEntProp(nEntityPropertyActiveWeapon, Prop_Send, "m_iClip2");
						SetEntProp(nEntityPropertyActiveWeapon, Prop_Send, "m_iClip2", 1);
					}
					g_phTimerDelayedEffect[nClient] = CreateTimer(0.5, TimerDelayedEffect, nClient);
				}
			}

			// for some reason EquipKnife doesn't work here, even when using a timer...
////			EquipKnife(nClient, false);
//			if(g_phTimerDelayedEffect[nClient] == INVALID_HANDLE)
//				g_phTimerDelayedEffect[nClient] = CreateTimer(0.7, TimerDelayedEffect, nClient);
		}
	}

	return Plugin_Continue;
}

// ----------------------------------------------------------------------------
public Action:TimerDelayedEffect(Handle:timer, any:nClient)
// ----------------------------------------------------------------------------
{
	g_phTimerDelayedEffect[nClient] = INVALID_HANDLE;

	if(g_pnClientFlags[nClient] & CLIENTFLAG_BERSERKER)
		EquipKnife(nClient, true);
	else if(g_pnClientFlags[nClient] & CLIENTFLAG_HIGH_JUMP)
	{
		// give some extra boost
		decl Float:pfEyeAngles[3];
		GetClientEyeAngles(nClient, pfEyeAngles);

		new Float:fBoost = GetConVarFloat(g_hHighJumpBoost);

		decl Float:pfTeleportAngles[3];
		pfTeleportAngles[0] = FloatMul(Cosine(DegToRad(pfEyeAngles[1])), fBoost/2.0);
		pfTeleportAngles[1] = FloatMul(Sine(DegToRad(pfEyeAngles[1])), fBoost/2.0);
		pfTeleportAngles[2] = fBoost;
		TeleportEntity(nClient, NULL_VECTOR, NULL_VECTOR, pfTeleportAngles);
	}
	else if(g_pnClientFlags[nClient] & CLIENTFLAG_WEAPON_JAM)		// jam weapon
	{
//		EquipKnife(nClient, false);	// doesn't work for some reason...

		if(g_pnClientClip[nClient][0] > 0 || g_pnClientClip[nClient][1] > 0)
		{
			new nEntityPropertyActiveWeapon = GetEntPropEnt(nClient, Prop_Send, "m_hActiveWeapon");

			if(g_pnClientClip[nClient][0] > 0)
				SetEntProp(nEntityPropertyActiveWeapon, Prop_Send, "m_iClip1", g_pnClientClip[nClient][0] -1);
			if(g_pnClientClip[nClient][1] > 0)
				SetEntProp(nEntityPropertyActiveWeapon, Prop_Send, "m_iClip2", g_pnClientClip[nClient][1] -1);

			g_pnClientClip[nClient][0] = -1;
			g_pnClientClip[nClient][1] = -1;
		}
	}
}

// ----------------------------------------------------------------------------
public Action:TimerAnnouncement(Handle:timer, any:data)
// ----------------------------------------------------------------------------
{
	// announce this plugin
	PrintHintTextToAll("%t", "rtd_announce", COMMAND_RTD, COMMAND_RTDSHORT);
}

// ----------------------------------------------------------------------------
public Action:TimerBeacon(Handle:timer, any:nClient)
// ----------------------------------------------------------------------------
{
	if(IsClientConnected(nClient) && IsClientInGame(nClient) && IsPlayerAlive(nClient))
	{
		// beacon effect...
		decl Float:pfEyePosition[3];
		GetClientEyePosition(nClient, pfEyePosition);

#if defined(SOUND_BEACON)
		EmitAmbientSound(SOUND_BEACON, pfEyePosition, SOUND_FROM_WORLD, SNDLEVEL_ROCKET);
#endif

		decl Float:pfAbsOrigin[3];
		GetClientAbsOrigin(nClient, pfAbsOrigin);
		pfAbsOrigin[2] += 5.0;

		TE_Start("BeamRingPoint");
		TE_WriteVector("m_vecCenter", pfAbsOrigin);
		TE_WriteFloat("m_flStartRadius", 20.0);
		TE_WriteFloat("m_flEndRadius", 400.0);
		TE_WriteNum("m_nModelIndex", g_nSpriteBeaconModel);
		TE_WriteNum("m_nHaloIndex", g_nSpriteBeaconIndex);
		TE_WriteNum("m_nStartFrame", 0);
		TE_WriteNum("m_nFrameRate", 0);
		TE_WriteFloat("m_fLife", 1.0);
		TE_WriteFloat("m_fWidth", 3.0);
		TE_WriteFloat("m_fEndWidth", 3.0);
		TE_WriteFloat("m_fAmplitude", 0.0);
		TE_WriteNum("r", 128);
		TE_WriteNum("g", 255);
		TE_WriteNum("b", 128);
		TE_WriteNum("a", 192);
		TE_WriteNum("m_nSpeed", 100);
		TE_WriteNum("m_nFlags", 0);
		TE_WriteNum("m_nFadeLength", 0);
		TE_SendToAll();
	}
	else
	{
		KillTimer(timer);
	}
}

// ----------------------------------------------------------------------------
public Action:RollTheDice(nClient, args)
// ----------------------------------------------------------------------------
{
	if(!IsClientConnected(nClient) || !IsClientInGame(nClient) || !IsPlayerAlive(nClient) || g_nEffectsCount == 0)
		return Plugin_Handled;

	if(g_pnClientDiceCountPerRound[nClient]++ >= GetConVarInt(g_hMaxThrowsPerRound))
	{
		ReplyToCommand(nClient, "%t", "rtd_wait", GetConVarInt(g_hMaxThrowsPerRound));
		return Plugin_Handled;
	}

	new nDicesPerMap = GetConVarInt(g_hMaxThrowsPerMap);
	if(nDicesPerMap > 0 && ++g_pnClientDiceCountPerMap[nClient] > nDicesPerMap)
	{
		ReplyToCommand(nClient, "%t", "rtd_wait_map", nDicesPerMap);
		return Plugin_Handled;
	}

	// roll the dice => just get a random number...
	new nDiced		= GetRandomInt(0, g_nEffectsCount-1);
	new nEffectID	= g_pnEffectIDs[nDiced];	// get ID of the effect
	if(GetUserAdmin(nClient) != INVALID_ADMIN_ID)	// for plugin testing... do not abuse this ;)
	{
		decl String:sArg[32];
		if(args >= 1 && GetCmdArg(1, sArg, sizeof(sArg)))
			nEffectID = StringToInt(sArg);
	}

	g_pnClientDiceIndex[nClient] = nDiced;

	// if the effect has a sound file assigned, play it here
	if(strlen(g_psEffectSounds[nDiced]) != 0)
	{
//		PrintToChat(nClient, "sound: %s", g_psEffectSounds[nDiced]);
		EmitSoundToClient(nClient, g_psEffectSounds[nDiced]);
	}

	// now apply the effect:
	switch(nEffectID)
	{
		case 1:	// give health
		{
			new nHealth = GetRandomInt(1, 100);
			PrintToChatAll("\x03%t", "rtd_health_increase", nClient, nEffectID, nHealth);
			SetEntProp(nClient, Prop_Send, "m_iHealth", GetClientHealth(nClient)+nHealth);
		}

		case 2:	// take health
		{
			new nHealth = GetRandomInt(1, GetClientHealth(nClient)-1);
			PrintToChatAll("\x03%t", "rtd_health_decrease", nClient, nEffectID, nHealth);
			SlapPlayer(nClient, nHealth);
		}

		case 3:	// give money
		{
			new nAmount	= (GetRandomInt(GetConVarInt(g_hGiveMoneyMin), GetConVarInt(g_hGiveMoneyMax)) / 100) * 100;	// round to 100
			if((GetEntData(nClient, g_iAccount) + nAmount) > 16000)
				nAmount = 16000 - GetEntData(nClient, g_iAccount);
			new nTotal = GetEntData(nClient, g_iAccount) + nAmount;
			SetEntData(nClient, g_iAccount, nTotal);
			PrintToChatAll("\x03%t", "rtd_money_increase", nClient, nEffectID, nAmount);
		}

		case 4:	// take money
		{
			new nAmount	= (GetRandomInt(GetConVarInt(g_hTakeMoneyMin), GetConVarInt(g_hTakeMoneyMax)) / 100) * 100;	// round to 100
			if((GetEntData(nClient, g_iAccount) - nAmount) < 0)
				nAmount = GetEntData(nClient, g_iAccount);
			new nTotal = GetEntData(nClient, g_iAccount) - nAmount;
			SetEntData(nClient, g_iAccount, nTotal);
			PrintToChatAll("\x03%t", "rtd_money_decrease", nClient, nEffectID, nAmount);
		}

		case 5:	// give weapon
		{
			decl String:sItemsList[MAX_ITEMS * MAX_ITEM_SIZE];
			if(GetConVarString(g_hGiveItems, sItemsList, sizeof(sItemsList)))
			{
				new String:psItems[MAX_ITEMS][MAX_ITEM_SIZE];
				new nItems = ExplodeString(sItemsList, " ", psItems, MAX_ITEMS, MAX_ITEM_SIZE);
				if(nItems > 0)
				{
					new nItem = GetRandomInt(0, nItems-1);
					PrintToChatAll("\x03%t", "rtd_give_item", nClient, nEffectID, psItems[nItem]);
					GivePlayerItem(nClient, psItems[nItem]);
				}
			}
		}

		case 6:	// take weapon
		{
			decl String:sItem[32];
			if(RemoveRandomWeaponFromSlot(nClient, sItem, sizeof(sItem)))
				PrintToChatAll("\x03%t", "rtd_take_item", nClient, nEffectID, sItem);
			else
				PrintToChatAll("\x03%t", "rtd_nothing_to_loose", nClient, nEffectID);
		}

		case 7:	// speed up
		{
			SetEntPropFloat(nClient, Prop_Data, "m_flLaggedMovementValue", GetConVarFloat(g_hSpeedFast));
			PrintToChatAll("\x03%t", "rtd_faster", nClient, nEffectID);
		}

		case 8:	// slow down
		{
			SetEntPropFloat(nClient, Prop_Data, "m_flLaggedMovementValue", GetConVarFloat(g_hSpeedSlow));
			PrintToChatAll("\x03%t", "rtd_slower", nClient, nEffectID);
		}

		case 9:	// invisibility
		{
			SetPlayerAlpha(nClient, 255-(GetConVarInt(g_hInvisibility) * 255 / 100));
			g_pnClientFlags[nClient] = CLIENTFLAG_INVISIBLE;
			PrintToChatAll("\x03%t", "rtd_invisibility", nClient, nEffectID);
		}

		case 10:	// glow
		{
			SetGlow(nClient, FxNone, 0, 255, 0, Glow, 255);
			SetEntityRenderFx(nClient, RENDERFX_GLOWSHELL);
			SetEntityRenderMode(nClient, RENDER_GLOW);
			g_phTimerClientBeacons[nClient] = CreateTimer(2.0, TimerBeacon, nClient, TIMER_REPEAT);
			PrintToChatAll("\x03%t", "rtd_glow", nClient, nEffectID);
		}

		case 11:	// vampire
		{
			g_pnClientFlags[nClient] = CLIENTFLAG_VAMPIRIC;
			PrintToChatAll("\x03%t", "rtd_vampiric", nClient, nEffectID);
		}

		case 12:	// mirror damage
		{
			g_pnClientFlags[nClient] = CLIENTFLAG_MIRRORDAMAGE;
			PrintToChatAll("\x03%t", "rtd_mirrordamage", nClient, nEffectID);
		}

		case 13:	// sunglasses
		{
			g_pnClientFlags[nClient] = CLIENTFLAG_SUNGLASSES;
			PrintToChatAll("\x03%t", "rtd_sunglasses", nClient, nEffectID);
		}

		case 14:	// drugs
		{
			PrintToChatAll("\x03%t", "rtd_drugs", nClient, nEffectID);
			ClientCommand(nClient, "r_screenoverlay effects/tp_eyefx/tpeye.vmt");
		}

		case 15:	// berserker
		{
			g_pnClientFlags[nClient] = CLIENTFLAG_BERSERKER;
			EquipKnife(nClient, true);
			SetEntPropFloat(nClient, Prop_Data, "m_flLaggedMovementValue", GetConVarFloat(g_hBerserkerSpeed));
			SetEntProp(nClient, Prop_Send, "m_iHealth", GetConVarInt(g_hBerserkerHealth));
			SetEntProp(nClient, Prop_Send, "m_ArmorValue", GetConVarInt(g_hBerserkerArmor));
			SetEntProp(nClient, Prop_Send, "m_bHasHelmet", GetConVarInt(g_hBerserkerArmor) > 0);
			PrintToChatAll("\x03%t", "rtd_berserker", nClient, nEffectID);
		}

		case 16:	// infinite ammo
		{
			g_pnClientFlags[nClient] = CLIENTFLAG_INFINITE_AMMO;
			PrintToChatAll("\x03%t", "rtd_infinite_ammo", nClient, nEffectID);
		}

		case 17:	// jam weapon
		{
			g_pnClientFlags[nClient] = CLIENTFLAG_WEAPON_JAM;
			PrintToChatAll("\x03%t", "rtd_weapon_jam", nClient, nEffectID);
		}

		case 18:	// high jump
		{
			g_pnClientFlags[nClient] = CLIENTFLAG_HIGH_JUMP;
			PrintToChatAll("\x03%t", "rtd_high_jump", nClient, nEffectID);
		}

		case 99:	// turn to chicken
		{
			PrintToChatAll("\x03%t", "rtd_chicken", nClient, nEffectID);
#if defined(ENABLE_MODEL_CHANGE)
			if(g_iModelChicken > 0)
			{
				if(g_hSetModel != INVALID_HANDLE)
				{
					SDKCall(g_hSetModel, nClient, MODEL_CHICKEN);
				}
			}
#endif
		}

		default:
		{
			// this should never happen. if so, something is configured wrong
			PrintToChatAll("\x03%t", "rtd_nothing", nClient, nEffectID);
		}
	}

	if(nDicesPerMap > 0)
		ReplyToCommand(nClient, "%t", "rtd_dices_left_per_map", (nDicesPerMap - g_pnClientDiceCountPerMap[nClient]));

	return Plugin_Handled;
}
