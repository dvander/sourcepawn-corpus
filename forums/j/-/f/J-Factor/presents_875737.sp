/**
 * vim: set ts=4 :
 * =============================================================================
 * Presents! by J-Factor
 * Adds presents to Team Fortress 2 that give temporary special effects
 * 
 * Credits:
 *			L. Duke					Particles foundation
 *			naris					Saving Health / GetDamage foundation
 *			The JCS and Muridas		BuildSentry code
 *			labelmaker				Knockback foundation
 *			forums.alliedmods.net	Lots of stuff
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
 */

#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
// Make the admin menu plugin optional
#undef REQUIRE_PLUGIN
#include <adminmenu>

/* Notepad ################################################################# */

/*

Effect ideas:

	TNT
		"Your fuse is lit! Don't let it catch you!"
	Lights a fuse that chases you around. If you stay still for too long you explode.
	
	Nuke
		"It's a bomb! Duck and cover!"
	Turns you into a Nuke. You start ticking and flashing wildly, while slowed to spun-up
	Heavy speed. Explodes anyone near you after 10 seconds IF they are not crouching!
	[crouch jumps?]
	
	Blue Shell
	
	Something that gives you godmode but you can't attack
	
	Pitfall? (burys anyone you hurt in the ground where they are)
	
	<item from brawl/mario-kart/snowboard-kids/diddy-kong-racing>

Code for creating particles at a random position on the outer faces of a cube:

	new Float:pos[3];
	new face;
	
	GetEntPropVector(ammopack, Prop_Send, "m_vecOrigin", pos);
	
	face = GetRandomInt(0, 2);
	
	for (new i = 0; i <= 2; i++) {
		if (i == face) {
			pos[i] += 10.0 * (GetRandomInt(0, 1) == 1 ? 1 : -1);
		} else {
			pos[i] += GetRandomFloat(-10.0, 10.0);
		}
	}
	
Code for teleporting to skybox:

	GetEntPropVector(client, Prop_Send, "m_skybox3d.origin", pos);
	TeleportEntity(client, pos, NULL_VECTOR, NULL_VECTOR);

How to find if you're in water:
	
	m_nWaterLevel: 0 = normal, 1 = feet in water, 2 = waist in water, 3 = underwater
	
Code for stopping death:

	new victimFlags = GetEntProp(victim, Prop_Data, "m_fFlags", victimFlags);
	
	if (victimFlags & FL_KILLME)  {
		victimFlags &= ~FL_KILLME;
		SetEntProp(victim, Prop_Data, "m_fFlags", victimFlags); 
	}
	
** Overlays:
**
** Team Fortress 2
** --------------------------------------------------
** Blu Uber                 = effects/invuln_overlay_blue
** Red Uber                 = effects/invuln_overlay_red
** Jarate                   = effects/jarate_overlay
** On fire                  = effects/imcookin
** Underwater               = effects/water_warp
** Blurry Underwater        = effects/water_warp_2fort
** Greeny Blurry Underwater = effects/water_warp_well
** Warped Edges (Bonk)      = effects/dodge_overlay
**
** Other
** --------------------------------------------------
** Blue Terminator-like     = effects/combine_binocoverlay
** Blurry                   = effects/water_warp01
** Green Tele shimmer       = effects/tp_eyefx/tpeye
** Red Tele shimmer         = effects/tp_eyefx/tpeye2
** Blue Tele shimmer        = effects/tp_eyefx/tpeye3
** Drugged distortion       = effects/tp_eyefx/tp_eyefx
** Red/yellow/green scroll  = models/effects/portalfunnel_sheet
** Green downward haze      = models/props_combine/portalball001_sheet
** Black & White            = debug/yuv
** Shield                   = effects/com_shield002a


Acid-like (boomer?) = Effects\tp_refract.vmt

*/

/* Constants ############################################################### */
#define PLUGIN_VERSION "0.5.1"

// Configs --------------------------------------------------------------------
#define CONFIG_MAPS "configs/presents/maps.cfg"
#define CONFIG_EFFECTS "configs/presents/effects.cfg"

// Models ---------------------------------------------------------------------
#define MODEL_AMMOPACK "models/items/ammopack_small.mdl"
#define MODEL_PRESENT "models/effects/bday_gib01.mdl"

// Effect models
#define MODEL_CONE "models/props_gameplay/orange_cone001.mdl"

// Sounds ---------------------------------------------------------------------
#define SOUND_PRESENT "misc/happy_birthday.wav"

// Effect sounds
#define SOUND_LUCKY 			"vo/SandwichEat09.wav"
#define SOUND_HOTAIR 			"vo/scout_apexofjump01.wav"
#define SOUND_SENTRY 			"vo/engineer_specialcompleted06.wav"
#define SOUND_INKPOT 			"weapons/jar_explode.wav"
#define SOUND_RUNNINGSHOES 		"vo/scout_invincible03.wav"
#define SOUND_RUNNINGSHOES_END 	"player/pl_scout_dodge_tired.wav"
#define SOUND_CURRY 			"vo/pyro_laughevil01.wav"
#define SOUND_INVISIBLE 		"player/spy_cloak.wav"
#define SOUND_INVISIBLE_END 	"player/spy_uncloak.wav"
#define SOUND_STRANGE 			"ambient/cow1.wav"
#define SOUND_DANCEFEVER 		"vo/engineer_cheers02.wav"
#define SOUND_CONE 				"ambient/thunder4.wav"
#define SOUND_HOTHEAD 			"misc/flame_engulf.wav"
#define SOUND_QUAKE				"ambient/atmosphere/terrain_rumble1.wav"
#define SOUND_FLUBBER			"player/pl_scout_jump1.wav"
#define SOUND_SPRING 			"weapons/airboat/airboat_gun_energy1.wav"
#define SOUND_TELEPORT			"weapons/teleporter_send.wav"
#define SOUND_TELEPORT_END		"weapons/teleporter_receive.wav"
#define SOUND_NOSTALGIA			"ui/tv_tune.wav"
#define SOUND_DRACULA			"vo/medic_laughevil05.wav"
#define SOUND_CONFLICT			"misc/tf_domination.wav"

// Player Color ---------------------------------------------------------------
#define BLACK      {0,0,0,255}
#define RED        {255,0,0,255}
#define INVISIBLE  {255,255,255,10}
#define NORMAL     {255,255,255,255}

// Player Condition  ----------------------------------------------------------
#define PLAYER_ONFIRE   (1 << 17)
#define PLAYER_SLOW     (1 << 0)
#define PLAYER_TAUNTING (1 << 7)

// Particle Attachment Types  -------------------------------------------------
#define NO_ATTACH		0
#define ATTACH_NORMAL	1
#define ATTACH_HEAD		2

// Text Color -----------------------------------------------------------------

// Plugin name
#define C_PLUGIN  0x05
// Player name
#define C_NAME    0x03
// Effect name
#define C_EFFECT  0x05
// Normal text
#define C_NORMAL  0x01

// Teams ----------------------------------------------------------------------
#define TEAM_RED 2
#define TEAM_BLU 3

// Targets --------------------------------------------------------------------
#define TARGET_RED	-1
#define TARGET_BLU	-2
#define TARGET_ALL	-3

// Effects --------------------------------------------------------------------
#define RANDOM_EFFECT		0

#define NO_EFFECT 			0

#define EFFECT_LUCKY 		1
#define EFFECT_HOTAIR 		2
#define EFFECT_SENTRY 		3
#define EFFECT_INKPOT 		4
#define EFFECT_RUNNING 		5
#define EFFECT_CURRY 		6
#define EFFECT_INVISIBLE 	7
#define EFFECT_STRANGE 		8
#define EFFECT_DANCE 		9
#define EFFECT_CONE 		10
#define EFFECT_HOTHEAD 		11
#define EFFECT_QUAKE 		12
#define EFFECT_FLUBBER 		13
#define EFFECT_TELEPORT 	14
#define EFFECT_NOSTALGIA 	15
#define EFFECT_DRACULA 		16
#define EFFECT_CONFLICT 	17

#define EFFECT_TESTING1		99
#define EFFECT_TESTING2		100

#define NUM_EFFECTS 17

/* Global Variables ######################################################## */

// Convars --------------------------------------------------------------------
new Handle:cvEnable = INVALID_HANDLE;
new Handle:cvDropEnable = INVALID_HANDLE;
new Handle:cvDropChance = INVALID_HANDLE;
new Handle:cvArenaDropChance = INVALID_HANDLE;
new Handle:cvAnnounce = INVALID_HANDLE;
new Handle:cvMapsOnly = INVALID_HANDLE;

// General --------------------------------------------------------------------
new bool:pluginEnabled = false;
new Handle:kvMaps = INVALID_HANDLE;
new Handle:kvEffects = INVALID_HANDLE;

new Float:dropChance = 0.2;

// Index of present model
new modelIndex = -1;

// Effects --------------------------------------------------------------------
new String:effectName[NUM_EFFECTS][32] = {
	"EFFECT_LUCKY",
	"EFFECT_HOTAIR",
	"EFFECT_SENTRY",
	"EFFECT_INKPOT",
	"EFFECT_RUNNING",
	"EFFECT_CURRY",
	"EFFECT_INVISIBLE",
	"EFFECT_STRANGE",
	"EFFECT_DANCE",
	"EFFECT_CONE",
	"EFFECT_HOTHEAD",
	"EFFECT_QUAKE",
	"EFFECT_FLUBBER",
	"EFFECT_TELEPORT",
	"EFFECT_NOSTALGIA",
	"EFFECT_DRACULA",
	"EFFECT_CONFLICT"
};

// Whether an effect is enabled
new bool:effectEnabled[NUM_EFFECTS];

// Pool from which enabled effects are randomly selected
new effectPool[NUM_EFFECTS];
new effectPoolNum = NUM_EFFECTS;

// Player ---------------------------------------------------------------------

// Player's current effect, see effect constants
new clientEffect[MAXPLAYERS + 1];

// Timers for effect:
//		0 = Effect duration
//		1 = Extra timer for effect (usually for recurring particle effects)
new Handle:clientEffectTimer[MAXPLAYERS + 1][2];

// Previous client positions
new Float:clientPos[MAXPLAYERS + 1][2][3];

// Number of taunts a client has been forced to do for Dance Fever
new clientTaunts[MAXPLAYERS + 1];

// Whether a client is having an overlay shown
new bool:clientOverlay[MAXPLAYERS + 1];

// Misc -----------------------------------------------------------------------

// Timer for blocking overlay command (cheat flags)
new Handle:overlayTimer = INVALID_HANDLE;

// Offsets
new offsDominatingMe = -1;
new offsDominated = -1;

// Save health to track damage
stock savedHealth[MAXPLAYERS + 1];

// Maptype (0 = normal, 1 = arena)
new mapType = 0;

// Admin Menu -----------------------------------------------------------------
new Handle:hTopMenu = INVALID_HANDLE;
new TopMenuObject:oPresentsMenu;
new adminGiveEffect[MAXPLAYERS + 1];

/* Plugin info ############################################################# */
public Plugin:myinfo =
{
	name = "Presents",
	author = "J-Factor",
	description = "Adds presents that give special effects",
	version = PLUGIN_VERSION,
	url = "http://j-factor.com/"
};

/* Events ################################################################## */

/* OnPluginStart()
**
** When the plugin is loaded.
** ------------------------------------------------------------------------- */
public OnPluginStart()
{
	// Translations
	LoadTranslations("common.phrases");
	LoadTranslations("presents.phrases");
	
	// Convars
	CreateConVar("sm_presents_version", PLUGIN_VERSION, "Presents! version", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvEnable = CreateConVar("sm_presents_enable", "1", "Enable Presents!", FCVAR_PLUGIN);
	HookConVarChange(cvEnable, Event_EnableChange);
	cvDropEnable = CreateConVar("sm_presents_drop_enable", "1", "Enable presents randomly dropping", FCVAR_PLUGIN);
	HookConVarChange(cvDropEnable, Event_DropEnableChange);
	cvDropChance = CreateConVar("sm_presents_drop_chance", "0.2", "Chance of a present dropping on kill", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvArenaDropChance = CreateConVar("sm_presents_arena_drop_chance","0.5", "Chance of a present dropping on kill in arena", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(cvDropChance, Event_DropChanceChange);
	HookConVarChange(cvArenaDropChance, Event_ArenaDropChanceChange);
	cvAnnounce = CreateConVar("sm_presents_announce", "2", "Mode for announcing present effects in chat (0 = off, 1 = player only, 2 = all)", FCVAR_PLUGIN);
	cvMapsOnly = CreateConVar("sm_presents_maps_only", "0", "Enable random present drops only on maps specified in the maps config", FCVAR_PLUGIN);
	
	// Commands (for testing)
	RegAdminCmd("sm_present", Command_Present, ADMFLAG_SLAY);
	RegAdminCmd("sm_effect", Command_Effect, ADMFLAG_SLAY);
	
	// Global vars
	for (new i = 0; i < MAXPLAYERS + 1; i++) {
		clientEffect[i] = NO_EFFECT;
		clientEffectTimer[i][0] = INVALID_HANDLE;
		clientEffectTimer[i][1] = INVALID_HANDLE;
		
		clientTaunts[i] = 0;
		clientOverlay[i] = false;
		
		adminGiveEffect[i] = 0;
	}
	
	// Offsets
	offsDominatingMe = FindSendPropInfo("CTFPlayer", "m_bPlayerDominatingMe");
	offsDominated = FindSendPropInfo("CTFPlayer", "m_bPlayerDominated");
	
	// Configuration
	kvMaps = CreateKeyValues("Maps");
	kvEffects = CreateKeyValues("Effects");
	
	decl String:file[128];
	
	BuildPath(Path_SM, file, sizeof(file), CONFIG_MAPS);
	FileToKeyValues(kvMaps, file);
	
	BuildPath(Path_SM, file, sizeof(file), CONFIG_EFFECTS);
	FileToKeyValues(kvEffects, file);
	
	// Admin Menu
	new Handle:topmenu;
	
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE)) {
		OnAdminMenuReady(topmenu);
	}
}

/* OnMapStart()
**
** When the a map starts. Handles precaching resources.
** ------------------------------------------------------------------------- */
public OnMapStart()
{
	// Precache the model of the ammopack/healthkit we're using as the present
	PrecacheModel(MODEL_AMMOPACK, true);
	
	// The actual present model. We store the modelindex so we can easily check
	// if an ammopack/healthkit is a present
	modelIndex = PrecacheModel(MODEL_PRESENT, true);
	
	// Effect models
	PrecacheModel(MODEL_CONE, true);
	
	// Grab present sound
	PrecacheSound(SOUND_PRESENT, true);
	
	// Effect sounds
	PrecacheSound(SOUND_LUCKY, true);
	PrecacheSound(SOUND_HOTAIR, true);
	PrecacheSound(SOUND_SENTRY, true);
	PrecacheSound(SOUND_INKPOT, true);
	PrecacheSound(SOUND_RUNNINGSHOES, true);
	PrecacheSound(SOUND_RUNNINGSHOES_END, true);
	PrecacheSound(SOUND_CURRY, true);
	PrecacheSound(SOUND_INVISIBLE_END, true);
	PrecacheSound(SOUND_STRANGE, true);
	PrecacheSound(SOUND_DANCEFEVER, true);
	PrecacheSound(SOUND_CONE, true);
	PrecacheSound(SOUND_HOTHEAD, true);
	PrecacheSound(SOUND_QUAKE, true);
	PrecacheSound(SOUND_FLUBBER, true);
	PrecacheSound(SOUND_SPRING, true);
	PrecacheSound(SOUND_TELEPORT, true);
	PrecacheSound(SOUND_TELEPORT_END, true);
	PrecacheSound(SOUND_NOSTALGIA, true);
	PrecacheSound(SOUND_DRACULA, true);
	PrecacheSound(SOUND_CONFLICT, true);
	
	// Initialize enabled effects
	for (new i = 0; i < NUM_EFFECTS; i++) {
		effectEnabled[i] = false;
	}
	
	// Load effect configuration from "configs/presents/effects.cfg"
	LoadEffectConfig();
	
	// Load map configuration from "configs/presents/maps.cfg"
	LoadMapConfig();
	
	// Initialize
	Initialize(GetConVarBool(cvEnable));
}

/* Event_EnableChange()
**
** When the plugin is enabled/disabled.
** ------------------------------------------------------------------------- */
public Event_EnableChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	Initialize(strcmp(newValue, "1") == 0);
}

/* Event_DropEnableChange()
**
** When the random drops is enabled/disabled.
** ------------------------------------------------------------------------- */
public Event_DropEnableChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (strcmp(oldValue, newValue) != 0) {
		PrintToChatAll("%c[SM] %cRandom Present drops%c are %s!", C_NORMAL, C_NAME, C_NORMAL, StrEqual(newValue, "1") ? "enabled" : "disabled");
	}
}

/* Event_DropChanceChange()
**
** When the drop chance is changed.
** ------------------------------------------------------------------------- */
public Event_DropChanceChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (mapType == 0) {
		dropChance = StringToFloat(newValue);
	}
}

/* Event_ArenaDropChanceChange()
**
** When the arena drop chance is changed.
** ------------------------------------------------------------------------- */
public Event_ArenaDropChanceChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (mapType == 1) {
		dropChance = StringToFloat(newValue);
	}
}

/* Event_PlayerHurt()
**
** When a player is hurt.
** ------------------------------------------------------------------------- */
public Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim = GetClientOfUserId(GetEventInt(event,"userid"));
	new damage = GetDamage(event);
	
	new vcond = GetEntProp(victim, Prop_Send, "m_nPlayerCond");
	
	if (attacker) {
		if (attacker != victim) {
			// Superspicy Curry
			if ((clientEffect[attacker] == EFFECT_CURRY) && !(vcond & PLAYER_ONFIRE)) {
				TF2_IgnitePlayer(victim, attacker);
			}
			
			// Dance Fever
			if ((clientEffect[victim] == EFFECT_DANCE) && (clientEffect[attacker] != EFFECT_DANCE)) {
				GiveEffect(attacker, EFFECT_DANCE);
			}
			
			// Dracula's Heart
			if (clientEffect[attacker] == EFFECT_DRACULA) {
				new health = GetClientHealth(attacker);
				new max = GetEntProp(attacker, Prop_Data, "m_iMaxHealth");
				new heal = RoundToCeil(damage/2.0);
				
				if (heal > 0) {
					if (health < max - heal) {
						SetEntityHealth(attacker, health + heal);
					} else {
						SetEntityHealth(attacker, max);
					}
				}
			}
		}
		
		// Flubber Bullets
		if (clientEffect[attacker] == EFFECT_FLUBBER) {
			new Float:aang[3], Float:vvel[3], Float:pvec[3];
			
			// Knockback
			GetClientAbsAngles(attacker, aang);
			GetEntPropVector(victim, Prop_Data, "m_vecVelocity", vvel);
			
			if (attacker == victim) {
				vvel[2] += 1000.0;
			} else {
				GetAngleVectors(aang, pvec, NULL_VECTOR, NULL_VECTOR);
			
				vvel[0] += pvec[0] * 300.0;
				vvel[1] += pvec[1] * 300.0;
				vvel[2] = 500.0;
			}
			
			TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, vvel);
			EmitSoundClient(SOUND_SPRING, victim);
		}
	}
}

/* OnClientDisconnect()
**
** When a client disconnects.
** ------------------------------------------------------------------------- */
public OnClientDisconnect(client)
{
	if (pluginEnabled) {
		StopEffect(client);
	}
}

/* Event_PlayerSpawn()
**
** When a player spawns.
** ------------------------------------------------------------------------- */
public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (pluginEnabled) {
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		
		SaveHealth(client);
		StopEffect(client);
	}
}

/* TF2_CalcIsAttackCritical()
**
** Calculates whether an attack is a critical.
** ------------------------------------------------------------------------- */
public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
	if (pluginEnabled) {
		/* That's one lucky sandwich */
		if (clientEffect[client] == EFFECT_LUCKY) {
			result = true;
			
			clientEffect[client] = NO_EFFECT;
			ShowEffectWornOff(client, EFFECT_LUCKY);
			
			return Plugin_Handled;
		} else {
			return Plugin_Continue;
		}
	} else {
		return Plugin_Continue;	
	}
}

/* Event_PlayerDeath()
**
** When a player dies.
** ------------------------------------------------------------------------- */
public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (pluginEnabled) {
		new victim = GetClientOfUserId(GetEventInt(event, "userid"));
		new killer = GetClientOfUserId(GetEventInt(event, "attacker"));
		new deathFlags = GetEventInt(event, "death_flags");
		
		// Stop the victim's effect
		StopEffect(victim);
		
		// If this wasn't a suicide or dead ringer
		if ((victim != killer) && (!(deathFlags & 32)) && GetConVarBool(cvDropEnable)) {
			// Drop a present based on chance for the killer
			if (GetRandomFloat() < dropChance) {
				DropPresent(victim, killer);
			}
		}
	}
	
	return Plugin_Continue;
}

/* Event_PlayerDisconnect()
**
** When a player disconnects.
** ------------------------------------------------------------------------- */
public Action:Event_PlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (pluginEnabled) {
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		
		StopEffect(client);
	}
	
	return Plugin_Continue;
}

/* Event_RoundStart()
**
** When a round starts.
** ------------------------------------------------------------------------- */
public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (pluginEnabled) {
		ClearPresents();
	}
	
	return Plugin_Continue;
}

/* Command_Present()
**
** When a client calls "sm_present".
** ------------------------------------------------------------------------- */
public Action:Command_Present(client, args)
{
	if (pluginEnabled) {
		DropPresent(client);
	} else {
		ReplyToCommand(client, "[SM] Presents must be enabled to use sm_present!");
	}
	
	return Plugin_Handled;
}

/* Command_Effect()
**
** When a client calls "sm_effect".
** ------------------------------------------------------------------------- */
public Action:Command_Effect(client, args)
{
	if (pluginEnabled) {
		decl String:target[65];
		decl String:target_name[MAX_TARGET_LENGTH];
		decl target_list[MAXPLAYERS];
		decl target_count;
		decl bool:tn_is_ml;
		decl String:eff[4];
		
		if (args < 2) {
			ReplyToCommand(client, "[SM] Usage: sm_effect <#userid|name> <effect>");
			return Plugin_Handled;
		}
		
		GetCmdArg(1, target, sizeof(target));
		GetCmdArg(2, eff, sizeof(eff));
		
		if ((target_count = ProcessTargetString(
				target,
				client,
				target_list,
				MAXPLAYERS,
				0,
				target_name,
				sizeof(target_name),
				tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}
			
		for (new i = 0; i < target_count; i++) {
			if (IsClientInGame(target_list[i]) && IsPlayerAlive(target_list[i])) {
				GiveEffect(target_list[i], StringToInt(eff));
			}
		}
	} else {
		ReplyToCommand(client, "[SM] Presents must be enabled to use sm_effect!");
	}
	
	return Plugin_Handled;
}

/* OnGameFrame()
**
** Used to spin the presents and track health.
** ------------------------------------------------------------------------- */
public OnGameFrame()
{
	if (pluginEnabled) {
		new ammopack = -1, Float:ang[3];
		
		// Spin presents!
		while ((ammopack = FindEntityByClassname(ammopack, "item_ammopack_small")) != -1) {
			if (IsValidEntity(ammopack)) {
				if (GetEntProp(ammopack, Prop_Data, "m_nModelIndex") == modelIndex) {
					// Found a present
					GetEntPropVector(ammopack, Prop_Send, "m_angRotation", ang);
					
					// SourceMod doesn't support modulus on floats?
					ang[1]++;
					
					if (ang[1] >= 360.0) {
						ang[1] = 0.0;
					}
					
					TeleportEntity(ammopack, NULL_VECTOR, ang, NULL_VECTOR);
				}
			}
		}
		
		// Keep track of health for damage tracking
		SaveAllHealth();
	}
}

/* Functions --------------------------------------------------------------- */

/* Initialize()
**
** Initializes/uninitializes Presents.
** ------------------------------------------------------------------------- */
public Initialize(bool:enable)
{
	if (enable && !pluginEnabled) {
		// Initialize Presents
		HookEvent("player_hurt", Event_PlayerHurt);
		HookEvent("player_spawn", Event_PlayerSpawn);
		HookEvent("player_death", Event_PlayerDeath);
		
		HookEvent("teamplay_round_active", Event_RoundStart);
		HookEvent("teamplay_restart_round", Event_RoundStart);
		HookEvent("arena_round_start", Event_RoundStart);
		
		HookEvent("player_disconnect", Event_PlayerDisconnect);
		
		ClearPresents();
		
		pluginEnabled = true;
		PrintToChatAll("%c[SM] %cPresents!%c is enabled! %cRandom Present drops%c are %s!", C_NORMAL, C_PLUGIN, C_NORMAL, C_NAME, C_NORMAL, GetConVarBool(cvDropEnable) == true ? "enabled" : "disabled");
	} else if (!enable && pluginEnabled) {
		// Uninitialize Presents
		UnhookEvent("player_hurt", Event_PlayerHurt);
		UnhookEvent("player_spawn", Event_PlayerSpawn);
		UnhookEvent("player_death", Event_PlayerDeath);
		
		UnhookEvent("teamplay_round_active", Event_RoundStart);
		UnhookEvent("teamplay_restart_round", Event_RoundStart);
		UnhookEvent("arena_round_start", Event_RoundStart);
		
		UnhookEvent("player_disconnect", Event_PlayerDisconnect);
		
		ClearPresents();
		
		// Reset player's effects
		for (new i = 1; i <= MaxClients; i++) {
			if (IsClientConnected(i) && IsClientInGame(i) && !IsClientInKickQueue(i) && IsPlayerAlive(i)) {
				StopEffect(i);
				ResetPlayer(i);
			}
		}
		
		pluginEnabled = false;
		PrintToChatAll("%c[SM] %cPresents!%c is disabled!", C_NORMAL, C_PLUGIN, C_NORMAL);
	}
}

/* LoadEffectConfig()
**
** Loads the configuration for effects.
** ------------------------------------------------------------------------- */
public LoadEffectConfig()
{
	for (new i = 0; i < NUM_EFFECTS; i++) {
		if (KvJumpToKey(kvEffects, effectName[i])) {
			// Effect found
			decl String:val[2];
			KvGetString(kvEffects, "enabled", val, sizeof(val), "1");
			
			effectEnabled[i] = StrEqual(val, "1");
			
			KvGoBack(kvEffects);
		} else {
			// Assume default values for effect
			effectEnabled[i] = true;
		}
	}

	KvRewind(kvEffects);
}

/* LoadMapConfig()
**
** Loads the configuration for the current map.
** ------------------------------------------------------------------------- */
public LoadMapConfig()
{
	// Read the map name
	decl String:map[128];
	GetCurrentMap(map, sizeof(map));
	
	// Map type (normal/arena) for different drop chances
	if (StrContains(map, "arena_", false) == 0) {
		mapType = 1;
		dropChance = GetConVarFloat(cvArenaDropChance);
	} else {
		mapType = 0;
		dropChance = GetConVarFloat(cvDropChance);
	}
	
	// Check for map in config
	if (KvJumpToKey(kvMaps, map)) {
		// Map found
		decl String:enabled[255], String:disabled[255];
		
		// Whether to enable random drops or not
		if (KvGetNum(kvMaps, "enabled", 1) == 1) {
			SetConVarBool(cvDropEnable, true);
		} else {
			SetConVarBool(cvDropEnable, false);
		}
	
		// Map specific drop chance
		dropChance = KvGetFloat(kvMaps, "chance", dropChance);
		
		// Map specific effects enable/disable
		if (KvJumpToKey(kvMaps, "effects")) {
			KvGetString(kvMaps, "enabled", enabled, sizeof(enabled), "");
			KvGetString(kvMaps, "disabled", disabled, sizeof(disabled), "");
			
			for (new i = 0; i < NUM_EFFECTS; i++) {
				if (StrContains(enabled, effectName[i]) != -1) {
					effectEnabled[i] = true;
				}
				
				if (StrContains(disabled, effectName[i]) != -1) {
					effectEnabled[i] = false;
				}
			}
		
			KvGoBack(kvMaps);
		}
		
		KvGoBack(kvMaps);
	} else {
		// Assume default values for map
		if (GetConVarBool(cvMapsOnly)) {
			SetConVarBool(cvDropEnable, false);
		} else {
			SetConVarBool(cvDropEnable, true);
		}
	}

	KvRewind(kvMaps);
	
	// Create effect pool based on effectEnabled[]
	effectPoolNum = 0;
	
	for (new i = 0; i < NUM_EFFECTS; i++) {
		if (effectEnabled[i]) {
			effectPool[effectPoolNum++] = i + 1;
		}
	}
}

/* EntityOutput_GrabPresent()
**
** When a present might have been grabbed.
** ------------------------------------------------------------------------- */
public Action:EntityOutput_GrabPresent(const String:output[], caller, activator, Float:delay)
{
	if (pluginEnabled) {
		// Is the player really here and not about to be kicked
		if ((activator > 0) && (activator <= MaxClients) && IsClientInGame(activator) && !IsClientInKickQueue(activator)) {
			// Are they already enjoying an effect?
			if (clientEffect[activator] == NO_EFFECT) {
				new owner = GetEntProp(caller, Prop_Send, "m_hOwnerEntity");
				
				if ((owner == activator) || (owner == 0)) {
					new effect = GetEntProp(caller, Prop_Send, "m_hEffectEntity");
					
					GiveEffect(activator, effect);
					
					AcceptEntityInput(caller, "Kill");
				} else {
					// Not allowed to grab it
				}
			} else {
				// Already has an effect
			}
		}
	}
}

/* DropPresent()
**
** Drops a present where a player is.
** ------------------------------------------------------------------------- */
stock DropPresent(client, owner=-1, effect=RANDOM_EFFECT)
{
	new present, Float:pos[3];
	
	// Where the player is
	GetClientAbsOrigin(client, pos);
	pos[2] += 16;
	
	// Presents are actually small ammopacks! The more you know...
	present = CreateEntityByName("item_ammopack_small");
	
	if (present) {
		// Drop it where the player is, spawn early because we need to change the model, etc
		TeleportEntity(present, pos, NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(present);
		
		// Set its TeamNum to be spectator. This prevents either RED or BLU from grabbing the present for ammo
		SetEntProp(present, Prop_Send, "m_iTeamNum", 1, 4);
		
		// OnCacheInteraction is called when a player touches the present - not when they pick it up for ammo
		HookSingleEntityOutput(present, "OnCacheInteraction", EntityOutput:EntityOutput_GrabPresent);
		
		// Make it look like a present
		SetEntityModel(present, MODEL_PRESENT);
		// This gives the present a random skin out of the two Valve included
		// TODO: Keep this or use it for bad presents?
		//SetEntProp(present, Prop_Send, "m_nSkin", GetRandomInt(0, 100) % 2);
		
		// Player that caused the present to drop has 3 seconds to grab it before anyone else can
		// During this time the present is transparent
		SetEntProp(present, Prop_Send, "m_hOwnerEntity", owner);
		
		// Send a pack of the present entity index + unique target name in case it gets picked up
		if (owner != 0) {
			SetEntityRenderColor(present, 255, 255, 255, 128);
			SetEntityRenderMode(present, RENDER_TRANSTEXTURE);
			
			CreateTimer(3.0, Timer_PresentOwner, present);
		}
		
		// Gee, I hope Valve doesn't mind me reusing these attributes. Also I hope they don't do anything to ammopacks
		// (stores the effect the present gives you, in case you hadn't figured it out)
		// Another note: If the stored effect is >= 0 it refers to the pool of currently enabled effects (effectPool[])
		// If the stored effect is < 0 it can use any effect even if it's not enabled for the map
		if ((effect == RANDOM_EFFECT) && (effectPoolNum > 0)) {
			SetEntProp(present, Prop_Send, "m_hEffectEntity", effectPool[GetRandomInt(0, 100) % effectPoolNum]);
		} else {
			SetEntProp(present, Prop_Send, "m_hEffectEntity", effect);
		}
		
		// All entities created should have a targetname of 'present' to make cleaning up easier
		DispatchKeyValue(present, "targetname", "present");
		
		// Play a sound to let everyone know a present spawned
		EmitAmbientSound(SOUND_PRESENT, pos);
		
		// Make it pretty
		CreateParticle("mini_fireworks", 5.0, present);
		CreateParticle("bday_confetti", 5.0, present);
	} else {
		// Present not created - uh oh
		
		// TODO: Output error message?
	}
}

/* Timer_PresentOwner()
**
** Sets the owner of a present to allow anyone to grab it.
** ------------------------------------------------------------------------- */
public Action:Timer_PresentOwner(Handle:timer, any:present)
{
	if (IsValidEntity(present)) {
		decl String:classname[64];
		GetEdictClassname(present, classname, sizeof(classname));
		
		if (StrEqual(classname, "item_ammopack_small")) {
			// Hopefully this is our present
			SetEntityRenderColor(present, 255, 255, 255, 255);
			SetEntProp(present, Prop_Send, "m_hOwnerEntity", 0);
		}
	}
}

/* ClearPresents()
**
** Clears the map of all presents.
** ------------------------------------------------------------------------- */
public ClearPresents()
{
	new ammopack = -1;
		
	while ((ammopack = FindEntityByClassname(ammopack, "item_ammopack_small")) != -1) {
		if (IsValidEntity(ammopack)) {
			// NOTE: If multiple models are ever added, maybe change this to use targetname (Prop_Data, m_iName)
			if (GetEntProp(ammopack, Prop_Data, "m_nModelIndex") == modelIndex) {
				AcceptEntityInput(ammopack, "Kill");
			}
		}
	}
}

/* GiveEffect()
**
** Gives an effect to a client.
** ------------------------------------------------------------------------- */
stock GiveEffect(target, effect=RANDOM_EFFECT)
{
	if (target < 0) {
		// Special target
		for (new i = 1; i <= MaxClients; i++) {
			if (IsClientConnected(i) && IsClientInGame(i) && !IsClientInKickQueue(i) && IsPlayerAlive(i)) {
				new team = GetClientTeam(i);
				
				if (((target == TARGET_RED) && (team == TEAM_RED)) ||
					((target == TARGET_BLU) && (team == TEAM_BLU)) ||
					(target == TARGET_ALL)) {
					GiveEffect(i, effect);
				}
			}
		}
	} else {
		// Stop any effect they currently have
		StopEffect(target);
		
		switch (effect) {
			case RANDOM_EFFECT: 		GiveEffect				(target, (GetRandomInt(0, 100) % NUM_EFFECTS) + 1);
			
			case EFFECT_LUCKY: 			EffectLuckySandwich		(target);
			case EFFECT_HOTAIR: 		EffectHotAir			(target);
			case EFFECT_SENTRY: 		EffectSentry			(target);
			case EFFECT_INKPOT: 		EffectInkPot			(target);
			case EFFECT_RUNNING:		EffectRunningShoes		(target);
			case EFFECT_CURRY: 			EffectSuperspicyCurry	(target);
			case EFFECT_INVISIBLE:		EffectInvisible			(target);
			case EFFECT_STRANGE:		EffectFeelingStrange	(target);
			case EFFECT_DANCE: 			EffectDanceFever		(target);
			case EFFECT_CONE: 			EffectCone				(target);
			case EFFECT_HOTHEAD: 		EffectHotHead			(target);
			case EFFECT_QUAKE: 			EffectQuake				(target);
			case EFFECT_FLUBBER: 		EffectFlubber			(target);
			case EFFECT_TELEPORT: 		EffectTeleport			(target);
			case EFFECT_NOSTALGIA: 		EffectNostalgia			(target);
			case EFFECT_DRACULA: 		EffectDracula			(target);
			case EFFECT_CONFLICT:		EffectConflict			(target);
			
			case EFFECT_TESTING1:		EffectTesting1			(target);
			case EFFECT_TESTING2:		EffectTesting2			(target);
		}
		
		ShowEffectText(target, effect);
	}
}

/* EffectTesting1()
**
** Thing for testing.
** ------------------------------------------------------------------------- */
public EffectTesting1(client)
{

}

/* EffectTesting2()
**
** Another thing for testing.
** ------------------------------------------------------------------------- */
public EffectTesting2(client)
{

}

/* StopEffect()
**
** Stops any effects on a given client.
** ------------------------------------------------------------------------- */
public StopEffect(client)
{
	clientEffect[client] = NO_EFFECT;
	
	// First trigger main timer so that it may clean up extra timer if needed
	if (clientEffectTimer[client][0] != INVALID_HANDLE) {
		TriggerTimer(clientEffectTimer[client][0]);
		clientEffectTimer[client][0] = INVALID_HANDLE;
	}
	
	// Kill extra timer
	if (clientEffectTimer[client][1] != INVALID_HANDLE) {
		KillTimer(clientEffectTimer[client][1]);
		clientEffectTimer[client][1] = INVALID_HANDLE;
	}
}

/* ResetPlayer()
**
** Resets a player - attempts to undo any effects on them.
** ------------------------------------------------------------------------- */
public ResetPlayer(client)
{
	// Reset color
	ColorizePlayer(client, NORMAL);
	
	// Reset gravity
	SetEntDataFloat(client, FindDataMapOffs(client, "m_flGravity"), 1.0);
	
	// Reset speed
	new cond = GetEntProp(client, Prop_Send, "m_nPlayerCond");
		
	if (cond & (PLAYER_SLOW)) {
		SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 80.0);
	} else {
		SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", TF2_GetClassSpeed(TF2_GetPlayerClass(client)));
	}
	
	// Reset FOV & DFOV
	if (GetEntProp(client, Prop_Send, "m_iFOV") == 160) {
		SetEntProp(client, Prop_Send, "m_iFOV", 75);
	}
	
	if (GetEntProp(client, Prop_Send, "m_iDefaultFOV") == 160) {
		SetEntProp(client, Prop_Send, "m_iDefaultFOV", 75);
	}
	
	// Reset movetype
	SetEntityMoveType(client, MOVETYPE_WALK);
}

/* ShowEffectText()
**
** Shows text for when you gain an effect.
** ------------------------------------------------------------------------- */
public ShowEffectText(client, effect)
{
	if ((effect > 0) && (effect <= NUM_EFFECTS)) {
		new announcemode = 0;
		decl String:desc[48];
		
		SetHudTextParams(-1.0, 0.4, 5.0, 255, 255, 255, 255);
		
		// TODO: Make this use CreateHudSynchronizer()
		//       Not sure if I need a seperate object per client
		Format(desc, sizeof(desc), "%s_DESC", effectName[effect - 1]);
		ShowHudText(client, 3, "%t\n\n\n\n\n%t",
					effectName[effect - 1],
					desc);
		
		// Announce "Player was gifted: Effect" in chat?
		if ((announcemode = GetConVarInt(cvAnnounce))) {
			decl String:cname[64];
			decl String:mess[200];
			GetClientName(client, cname, 64);
			
			Format(mess, sizeof(mess), "%c[SM] %c%s%c was gifted: %c%T%c", C_NORMAL, C_NAME, cname, C_NORMAL, C_EFFECT, effectName[effect - 1], LANG_SERVER, C_NORMAL);
			
			if (announcemode == 1) {
				// Announce to single client
				SayText2Single(client, mess);
			} else {
				// Announce to everyone
				SayText2(client, mess);
			}
		}
	}
}

/* ShowEffectWornOff()
**
** Shows that an effect has worn off.
** ------------------------------------------------------------------------- */
public ShowEffectWornOff(client, effect)
{
	if ((effect > 0) && (effect <= NUM_EFFECTS)) {
		SetHudTextParams(-1.0, 0.4, 5.0, 255, 255, 255, 200);
		ShowHudText(client, 3, "%t has worn off", effectName[effect - 1]);
	}
}

/* ShowEffectInfo()
**
** Shows misc info for effects.
** ------------------------------------------------------------------------- */
public ShowEffectInfo(client, const String:text[])
{
	SetHudTextParams(-1.0, 0.4, 5.0, 255, 128, 128, 200);
	ShowHudText(client, 3, "%s", text);
}

/* Effects ################################################################# */

/* EffectLuckySandwich()
**
** Effect: Heals you by 50 hp and makes your next shot a crit.
** ------------------------------------------------------------------------- */
public EffectLuckySandwich(client)
{
	clientEffect[client] = EFFECT_LUCKY;
	
	SetEntityHealth(client, GetClientHealth(client) + 100);
	
	CreateParticle("healhuff_blu", 5.0, client, ATTACH_HEAD);
	CreateParticle("healhuff_red", 5.0, client, ATTACH_HEAD);
	
	EmitSoundClient(SOUND_LUCKY, client);
}

/* EffectHotAir()
**
** Effect: Low gravity.
** ------------------------------------------------------------------------- */
public EffectHotAir(client)
{
	clientEffect[client] = EFFECT_HOTAIR;
	clientEffectTimer[client][0] = CreateTimer(15.0, Timer_HotAir, client);
	clientEffectTimer[client][1] = CreateTimer(2.0, Timer_HotAirBalloons, client, TIMER_REPEAT);
	
	SetEntityGravity(client, 0.15);
	
	CreateParticle("bday_balloon02", 5.0, client);
	
	EmitSoundClient(SOUND_HOTAIR, client);
}

/* Timer_HotAirBalloons()
**
** Creates Balloon particles periodically.
** ------------------------------------------------------------------------- */
public Action:Timer_HotAirBalloons(Handle:timer, any:client)
{
	if (clientEffect[client] != EFFECT_HOTAIR) {
		return Plugin_Stop;
	} else {
		CreateParticle("bday_1balloon", 5.0, client, NO_ATTACH, GetRandomFloat(0.0, 32.0) - 16.0, GetRandomFloat(0.0, 32.0) - 16.0);
		
		return Plugin_Continue;
	}
}

/* Timer_HotAir()
**
** Timer for Hot Air Balloon effect.
** ------------------------------------------------------------------------- */
public Action:Timer_HotAir(Handle:timer, any:client)
{
	if (clientEffectTimer[client][1] != INVALID_HANDLE) {
		KillTimer(clientEffectTimer[client][1]);
		clientEffectTimer[client][1] = INVALID_HANDLE;
	}
	
	clientEffect[client] = NO_EFFECT;
	clientEffectTimer[client][0] = INVALID_HANDLE;
	
	if (client && IsClientInGame(client) && !IsClientInKickQueue(client)) {
		SetEntityGravity(client, 1.0);
		
		ShowEffectWornOff(client, EFFECT_HOTAIR);
	}
}

/* EffectSentry()
**
** Effect: Spawns a Level 1 Sentry where you are standing.
** ------------------------------------------------------------------------- */
public EffectSentry(client)
{
	new Float:pos[3], Float:ang[3] = {0.0, 0.0, 0.0}, sentry, Handle:pack;
	
	clientEffect[client] = EFFECT_SENTRY;
	clientEffectTimer[client][0] = CreateDataTimer(10.0, Timer_Sentry, pack);
	
	GetClientAbsOrigin(client, pos);
	
	sentry = BuildSentry(client, pos, ang);
	
	WritePackCell(pack, client);
	WritePackCell(pack, sentry);
	
	// Make it noclip so you don't get stuck
	SetEntProp(sentry, Prop_Data, "m_CollisionGroup", 5);
	SetEntData(sentry, FindSendPropOffs("CObjectSentrygun", "m_iAmmoShells"), 8, 4, true);

	EmitSoundClient(SOUND_SENTRY, client);
}

/* Timer_Sentry()
**
** Timer for Sentry effect.
** ------------------------------------------------------------------------- */
public Action:Timer_Sentry(Handle:timer, Handle:pack)
{
	new client, sentry;
	ResetPack(pack);
	client = ReadPackCell(pack);
	sentry = ReadPackCell(pack);
	
	clientEffect[client] = NO_EFFECT;
	clientEffectTimer[client][0] = INVALID_HANDLE;
	
	if (IsValidEntity(sentry)) {
		DestroyBuilding(sentry);
	}
	
	if (client && IsClientInGame(client) && !IsClientInKickQueue(client)) {
		ShowEffectWornOff(client, EFFECT_SENTRY);
	}
}

/* EffectInkPot()
**
** Effect: You get covered in ink for 20 seconds.
** ------------------------------------------------------------------------- */
public EffectInkPot(client)
{
	clientEffect[client] = EFFECT_INKPOT;
	clientEffectTimer[client][0] = CreateTimer(20.0, Timer_InkPot, client);
	
	ColorizePlayer(client, BLACK);
	
	// Create a bunch of oil droplet particles
	CreateParticle("lowV_oildroplets", 5.0, client, ATTACH_HEAD);
	CreateParticle("lowV_oildroplets", 5.0, client, ATTACH_HEAD);
	CreateParticle("lowV_oildroplets", 5.0, client, ATTACH_HEAD);
	CreateParticle("lowV_oildroplets", 5.0, client, ATTACH_HEAD);
	
	EmitSoundClient(SOUND_INKPOT, client);
}

/* Timer_InkPot()
**
** Timer for Ink Pot effect.
** ------------------------------------------------------------------------- */
public Action:Timer_InkPot(Handle:timer, any:client)
{
	clientEffect[client] = NO_EFFECT;
	clientEffectTimer[client][0] = INVALID_HANDLE;
	
	if (client && IsClientInGame(client) && !IsClientInKickQueue(client)) {
		ColorizePlayer(client, NORMAL);
		
		ShowEffectWornOff(client, EFFECT_INKPOT);
	}
}

/* EffectRunningShoes()
**
** Effect: Double speed for 10 seconds.
** ------------------------------------------------------------------------- */
public EffectRunningShoes(client)
{
	clientEffect[client] = EFFECT_RUNNING;
	clientEffectTimer[client][0] = CreateTimer(20.0, Timer_RunningShoes, client);
	clientEffectTimer[client][1] = CreateTimer(0.1, Timer_RunningShoesTrail, client, TIMER_REPEAT);
	
	SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 400.0);
	
	EmitSoundClient(SOUND_RUNNINGSHOES, client);
}

/* Timer_RunningShoesTrail()
**
** Creates a trail of fire behind you for the Running Shoes.
** ------------------------------------------------------------------------- */
public Action:Timer_RunningShoesTrail(Handle:timer, any:client)
{
	if (clientEffect[client] != EFFECT_RUNNING) {
		return Plugin_Stop;
	} else {
		// Allows Heavys/Snipers/Grabbing-Intel to not reduce your speed
		SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 400.0);
		
		CreateParticle("burningplayer_corpse", 0.5, client, NO_ATTACH, GetRandomFloat(0.0, 32.0) - 16.0, GetRandomFloat(0.0, 32.0) - 16.0);
		
		return Plugin_Continue;
	}
}

/* Timer_RunningShoes()
**
** Timer for Running Shoes effect.
** ------------------------------------------------------------------------- */
public Action:Timer_RunningShoes(Handle:timer, any:client)
{
	if (clientEffectTimer[client][1] != INVALID_HANDLE) {
		KillTimer(clientEffectTimer[client][1]);
		clientEffectTimer[client][1] = INVALID_HANDLE;
	}

	clientEffect[client] = NO_EFFECT;
	clientEffectTimer[client][0] = INVALID_HANDLE;
	
	if (client && IsClientInGame(client) && !IsClientInKickQueue(client)) {
		new cond = GetEntProp(client, Prop_Send, "m_nPlayerCond");
		
		// Ensures spun-up Heavys/Snipers don't return to their normal movement speed!
		if (cond & (PLAYER_SLOW)) {
			SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 80.0);
		} else {
			SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", TF2_GetClassSpeed(TF2_GetPlayerClass(client)));
		}
	
		EmitSoundClient(SOUND_RUNNINGSHOES_END, client);
		ShowEffectWornOff(client, EFFECT_RUNNING);
	}
}

/* EffectSuperspicyCurry()
**
** Effect: You and everyone (on the other team) around you get ignited constantly for 10 seconds.
** ------------------------------------------------------------------------- */
public EffectSuperspicyCurry(client)
{
	clientEffect[client] = EFFECT_CURRY;
	clientEffectTimer[client][0] = CreateTimer(10.0, Timer_SuperspicyCurry, client);
	
	SetEntityHealth(client, GetClientHealth(client) + 50);
	
	ColorizePlayer(client, RED);
	TF2_IgnitePlayer(client, client);
	
	EmitSoundClient(SOUND_CURRY, client);
}

/* Timer_SuperspicyCurry()
**
** Timer for Superspicy Curry effect.
** ------------------------------------------------------------------------- */
public Action:Timer_SuperspicyCurry(Handle:timer, any:client)
{
	clientEffect[client] = NO_EFFECT;
	clientEffectTimer[client][0] = INVALID_HANDLE;
	
	if (client && IsClientInGame(client) && !IsClientInKickQueue(client)) {
		ColorizePlayer(client, NORMAL);
		
		ShowEffectWornOff(client, EFFECT_CURRY);
	}
}

/* EffectInvisible()
**
** Effect: Invisibility for 15 seconds.
** ------------------------------------------------------------------------- */
public EffectInvisible(client)
{
	clientEffect[client] = EFFECT_INVISIBLE;
	clientEffectTimer[client][0] = CreateTimer(10.0, Timer_Invisible, client);
	
	ColorizePlayer(client, INVISIBLE);
	
	for (new i = 0; i < 5; i++) {
		CreateParticle("electrocuted_gibbed_blue", 2.0, client, ATTACH_NORMAL, GetRandomFloat(0.0, 64.0) - 32.0, GetRandomFloat(0.0, 64.0) - 32.0, GetRandomFloat(0.0, 64.0) - 32.0 + 32.0);
	}
	
	// Remove fire
	SetEntProp(client, Prop_Send, "m_nPlayerCond", GetEntProp(client, Prop_Send, "m_nPlayerCond") & (~PLAYER_ONFIRE));
	
	EmitSoundClient(SOUND_INVISIBLE, client);
}

/* Timer_Invisible()
**
** Timer for Invisible effect.
** ------------------------------------------------------------------------- */
public Action:Timer_Invisible(Handle:timer, any:client)
{
	clientEffect[client] = NO_EFFECT;
	clientEffectTimer[client][0] = INVALID_HANDLE;
	
	if (client && IsClientInGame(client) && !IsClientInKickQueue(client)) {
		ColorizePlayer(client, NORMAL);
		
		for (new i = 0; i < 5; i++) {
			CreateParticle("electrocuted_gibbed_blue", 2.0, client, ATTACH_NORMAL, GetRandomFloat(0.0, 64.0) - 32.0, GetRandomFloat(0.0, 64.0) - 32.0, GetRandomFloat(0.0, 64.0) - 32.0 + 32.0);
		}
		
		EmitSoundClient(SOUND_INVISIBLE_END, client);
		ShowEffectWornOff(client, EFFECT_INVISIBLE);
	}
}

/* EffectFeelingStrange()
**
** Effect: You felt a little strange...
** ------------------------------------------------------------------------- */
public EffectFeelingStrange(client)
{
	new Handle:pack;
	
	clientEffect[client] = EFFECT_STRANGE;
	clientEffectTimer[client][0] = CreateDataTimer(20.0, Timer_FeelingStrange, pack);
	
	// Remember the client's FOV (incase they had a number higher than 75)
	WritePackCell(pack, client);
	WritePackCell(pack, GetEntProp(client, Prop_Send, "m_iFOV"));
	WritePackCell(pack, GetEntProp(client, Prop_Send, "m_iDefaultFOV"));
	
	SetEntProp(client, Prop_Send, "m_iFOV", 160);
	SetEntProp(client, Prop_Send, "m_iDefaultFOV", 160);
	
	EmitSoundClient(SOUND_STRANGE, client);
}

/* Timer_FeelingStrange()
**
** Timer for Feeling Strange effect.
** ------------------------------------------------------------------------- */
public Action:Timer_FeelingStrange(Handle:timer, Handle:pack)
{
	new client, fov, dfov;
	
	ResetPack(pack);
	client = ReadPackCell(pack);
	fov    = ReadPackCell(pack);
	dfov   = ReadPackCell(pack);
	
	clientEffect[client] = NO_EFFECT;
	clientEffectTimer[client][0] = INVALID_HANDLE;
	
	if (client && IsClientInGame(client) && !IsClientInKickQueue(client)) {
		SetEntProp(client, Prop_Send, "m_iFOV", fov);
		SetEntProp(client, Prop_Send, "m_iDefaultFOV", dfov);
		
		ShowEffectWornOff(client, EFFECT_STRANGE);
	}
}

/* EffectDanceFever()
**
** Effect: You've caught dance fever! Watch out, it's contagious.
** ------------------------------------------------------------------------- */
public EffectDanceFever(client)
{
	clientEffect[client] = EFFECT_DANCE;
	// Note: Dance Fever no longer has a main timer. Its duration is until the client 
	//       has been forced to taunt twice.
	clientEffectTimer[client][1] = CreateTimer(0.1, Timer_Dance, client, TIMER_REPEAT);
	
	// Number of times they've taunted
	clientTaunts[client] = 0;
	
	if (GetEntityFlags(client) & FL_ONGROUND) {
		FakeClientCommand(client, "taunt");
		clientTaunts[client]++;
	}
	
	EmitSoundClient(SOUND_DANCEFEVER, client);
}

/* Timer_Dance()
**
** Timer that forces you to dance.
** ------------------------------------------------------------------------- */
public Action:Timer_Dance(Handle:timer, any:client)
{
	if (clientEffect[client] != EFFECT_DANCE) {
		return Plugin_Stop;
	}
	
	if (client && IsClientInGame(client) && !IsClientInKickQueue(client)) {
		new cond = GetEntProp(client, Prop_Send, "m_nPlayerCond");
		
		if (!(cond & PLAYER_TAUNTING)) {
			if (clientTaunts[client] >= 2) {
				// End effect
				clientEffect[client] = NO_EFFECT;
				clientEffectTimer[client][1] = INVALID_HANDLE;
				
				ShowEffectWornOff(client, EFFECT_DANCE);
				
				return Plugin_Stop;
			} else if (GetEntityFlags(client) & FL_ONGROUND) {
				FakeClientCommand(client, "taunt");
				clientTaunts[client]++;
			}
		}
	} else {
		clientEffect[client] = NO_EFFECT;
		clientEffectTimer[client][1] = INVALID_HANDLE;
		
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

/* EffectCone()
**
** Effect: Traffic Cone.
** ------------------------------------------------------------------------- */
public EffectCone(client)
{
	new Handle:pack, Float:dpos[3], Float:dang[3],
					  Float:pos[3], Float:ang[3];
	
	clientEffect[client] = EFFECT_CONE;
	clientEffectTimer[client][0] = CreateDataTimer(20.0, Timer_Cone, pack);
	
	GetClientAbsAngles(client, ang);
	GetClientAbsOrigin(client, pos);
	
	dpos[0] = pos[0] + Sine(DegToRad(ang[1]));
	dpos[1] = pos[1] + Cosine(DegToRad(ang[1]));
	dpos[2] = pos[2] - 8.0;
	
	dang[0] = 0.0;
	dang[1] = 0.0;
	dang[2] = 0.0;
	
	new cone = CreateEntityByName("prop_dynamic_override");
	
	if (IsValidEntity(cone)) {
		TeleportEntity(cone, dpos, dang, NULL_VECTOR);
		
		SetVariantString("!activator");
		AcceptEntityInput(cone, "SetParent", client, cone, false);
		
		SetVariantString("partyhat");
		AcceptEntityInput(cone, "SetParentAttachmentMaintainOffset");
		
		DispatchKeyValue(cone, "model", MODEL_CONE);
		DispatchKeyValue(cone, "solid", "0");
		
		DispatchSpawn(cone);
		
		AcceptEntityInput(cone, "TurnOn");
	}
	
	WritePackCell(pack, client);
	WritePackCell(pack, cone);
	
	EmitSoundClient(SOUND_CONE, client);
}

/* Timer_Cone()
**
** Timer for cone effect.
** ------------------------------------------------------------------------- */
public Action:Timer_Cone(Handle:timer, Handle:pack)
{
	new client, cone;
	
	ResetPack(pack);
	client = ReadPackCell(pack);
	cone = ReadPackCell(pack);
	
	clientEffect[client] = NO_EFFECT;
	clientEffectTimer[client][0] = INVALID_HANDLE;
	
	if (IsValidEntity(cone)) {
		RemoveEdict(cone);
	}
	
	if (client && IsClientInGame(client) && !IsClientInKickQueue(client)) {
		ShowEffectWornOff(client, EFFECT_CONE);
	}
}

/* EffectHotHead()
**
** Effect: Your head spontaneously combusted.
** ------------------------------------------------------------------------- */
public EffectHotHead(client)
{
	clientEffect[client] = EFFECT_HOTHEAD;
	clientEffectTimer[client][0] = CreateTimer(20.0, Timer_HotHead, client);
	// Note: Here we are giving the particle a lifetime of 30.0. However, the effect's duration is 20.0
	//       Once the effect ends we manually trigger the deletion timer for the particle
	clientEffectTimer[client][1] = CreateParticle("smoke_blackbillow_skybox", 30.0, client, ATTACH_HEAD);
	
	
	EmitSoundClient(SOUND_HOTHEAD, client);
}

/* Timer_HotHead()
**
** Timer for Hot Head effect.
** ------------------------------------------------------------------------- */
public Action:Timer_HotHead(Handle:timer, any:client)
{
	clientEffect[client] = NO_EFFECT;
	clientEffectTimer[client][0] = INVALID_HANDLE;
	
	// Force the particle to be deleted
	TriggerTimer(clientEffectTimer[client][1]);
	clientEffectTimer[client][1] = INVALID_HANDLE;
	
	if (client && IsClientInGame(client) && !IsClientInKickQueue(client)) {
		ShowEffectWornOff(client, EFFECT_HOTHEAD);
	}
}

/* EffectQuake()
**
** Effect: Shakes the screen for awhile.
** ------------------------------------------------------------------------- */
public EffectQuake(client)
{
	clientEffect[client] = EFFECT_QUAKE;
	clientEffectTimer[client][0] = CreateTimer(15.0, Timer_Quake, client);
	clientEffectTimer[client][1] = CreateTimer(0.25, Timer_QuakeShake, client, TIMER_REPEAT);
	
	Shake(client);
	
	EmitSoundClient(SOUND_QUAKE, client);
}

/* Timer_QuakeShake()
**
** Shakes the screen periodically.
** ------------------------------------------------------------------------- */
public Action:Timer_QuakeShake(Handle:timer, any:client)
{
	if (clientEffect[client] != EFFECT_QUAKE) {
		return Plugin_Stop;
	} else {
		Shake(client);
		
		return Plugin_Continue;
	}
}

/* Timer_Quake()
**
** Timer for Quake effect.
** ------------------------------------------------------------------------- */
public Action:Timer_Quake(Handle:timer, any:client)
{
	if (clientEffectTimer[client][1] != INVALID_HANDLE) {
		KillTimer(clientEffectTimer[client][1]);
		clientEffectTimer[client][1] = INVALID_HANDLE;
	}

	clientEffect[client] = NO_EFFECT;
	clientEffectTimer[client][0] = INVALID_HANDLE;
	
	if (client && IsClientInGame(client) && !IsClientInKickQueue(client)) {
		ShowEffectWornOff(client, EFFECT_QUAKE);
	}
}

/* EffectFlubber()
**
** Effect: Boing.
** ------------------------------------------------------------------------- */
public EffectFlubber(client)
{
	clientEffect[client] = EFFECT_FLUBBER;
	clientEffectTimer[client][0] = CreateTimer(20.0, Timer_SpringShot, client);
	
	EmitSoundClient(SOUND_FLUBBER, client);
}

/* Timer_SpringShot()
**
** Timer for Spring Shot effect.
** ------------------------------------------------------------------------- */
public Action:Timer_SpringShot(Handle:timer, any:client)
{
	clientEffect[client] = NO_EFFECT;
	clientEffectTimer[client][0] = INVALID_HANDLE;
	
	if (client && IsClientInGame(client) && !IsClientInKickQueue(client)) {
		ShowEffectWornOff(client, EFFECT_FLUBBER);
	}
}

/* EffectTeleport()
**
** Effect: Teleport.
** ------------------------------------------------------------------------- */
public EffectTeleport(client)
{
	clientEffect[client] = EFFECT_TELEPORT;
	clientEffectTimer[client][0] = INVALID_HANDLE;
	clientEffectTimer[client][1] = CreateTimer(1.0, Timer_TeleportWarp, client);
	
	GetClientAbsOrigin(client, clientPos[client][0]);
	
	CreateParticle("teleported_blue", 2.0, client);
	CreateParticle("teleported_red", 2.0, client);
	
	EmitSoundClient(SOUND_TELEPORT, client);
}

/* Timer_TeleportWarp()
**
** Timer for Teleport effect.
** ------------------------------------------------------------------------- */
public Action:Timer_TeleportWarp(Handle:timer, any:client)
{
	clientEffect[client] = NO_EFFECT;
	clientEffectTimer[client][0] = INVALID_HANDLE;
	clientEffectTimer[client][1] = INVALID_HANDLE;
	
	if (client && IsClientInGame(client) && !IsClientInKickQueue(client)) {
		// TODO: Make it so you don't warp to presents?
		//       Nah...
		new String:class[6][32] = { "item_ammopack_small",
									"item_ammopack_medium",
									"item_ammopack_full",
									"item_healthkit_small",
									"item_healthkit_medium",
									"item_healthkit_full" };
		new e = -1, ei = 0, ci = 0;
		new ent[128], Float:pos[3];
		
		do {
			while ((e = FindEntityByClassname(e, class[ci])) != -1) {
				if (IsValidEntity(e)) {
					ent[ei++] = e;
				}
			}
		} while ((ci = (ci + 1) % 6));
		
		if (ei > 0) {
			GetEntPropVector(ent[GetRandomInt(0, 100) % ei], Prop_Send, "m_vecOrigin", pos);
			TeleportEntity(client, pos, NULL_VECTOR, NULL_VECTOR);
			
			CreateParticle("teleportedin_blue", 2.0, client, ATTACH_NORMAL);
			CreateParticle("teleportedin_red", 2.0, client, ATTACH_NORMAL);

			CreateParticle("teleporter_red_charged", 10.0, client, NO_ATTACH, 0.0, 0.0, -16.0);
			CreateParticle("teleporter_blue_charged", 10.0, client, NO_ATTACH, 0.0, 0.0, -16.0);
			
			GetClientAbsOrigin(client, clientPos[client][1]);
			
			EmitSoundClient(SOUND_TELEPORT_END, client);
			clientEffectTimer[client][1] = CreateTimer(10.0, Timer_TeleportStuck, client);
		}
		
		ShowEffectWornOff(client, EFFECT_TELEPORT);
	}
}

/* Timer_TeleportStuck()
**
** Timer for Teleport effect.
** ------------------------------------------------------------------------- */
public Action:Timer_TeleportStuck(Handle:timer, any:client)
{
	clientEffectTimer[client][1] = INVALID_HANDLE;
	
	if (client && IsClientInGame(client) && !IsClientInKickQueue(client)) {
		new Float:pos[3];
		
		GetClientAbsOrigin(client, pos);
		
		if (FloatAbs(clientPos[client][1][0] - pos[0]) + FloatAbs(clientPos[client][1][1] - pos[1]) + FloatAbs(clientPos[client][1][2] - pos[2]) < 50.0) {
			// Stuck? Teleport back
			clientEffectTimer[client][1] = CreateTimer(1.0, Timer_TeleportBack, client);
			
			CreateParticle("teleported_blue", 2.0, client);
			CreateParticle("teleported_red", 2.0, client);
			
			EmitSoundClient(SOUND_TELEPORT, client);
		}
	}
}

/* Timer_TeleportBack()
**
** Timer for Teleport effect.
** ------------------------------------------------------------------------- */
public Action:Timer_TeleportBack(Handle:timer, any:client)
{
	clientEffectTimer[client][1] = INVALID_HANDLE;
	
	if (client && IsClientInGame(client) && !IsClientInKickQueue(client)) {
		TeleportEntity(client, clientPos[client][0], NULL_VECTOR, NULL_VECTOR);
		
		CreateParticle("teleported_blue", 2.0, client);
		CreateParticle("teleported_red", 2.0, client);
		
		EmitSoundClient(SOUND_TELEPORT_END, client);
	}
}

/* EffectNostalgia()
**
** Effect: Boom.
** ------------------------------------------------------------------------- */
public EffectNostalgia(client)
{
	clientEffect[client] = EFFECT_NOSTALGIA;
	clientEffectTimer[client][0] = CreateTimer(20.0, Timer_Nostalgia, client);
	
	ShowOverlay(client, "debug/yuv", 20.0);
	
	EmitSoundClient(SOUND_NOSTALGIA, client);
}

/* Timer_Nostalgia()
**
** Timer for Nostalgia effect.
** ------------------------------------------------------------------------- */
public Action:Timer_Nostalgia(Handle:timer, any:client)
{
	clientEffect[client] = NO_EFFECT;
	clientEffectTimer[client][0] = INVALID_HANDLE;
	
	clientOverlay[client] = false;
	
	if (client && IsClientInGame(client) && !IsClientInKickQueue(client)) {
		ShowEffectWornOff(client, EFFECT_NOSTALGIA);
	}
}

/* EffectDracula()
**
** Effect: Blutsauger-like.
** ------------------------------------------------------------------------- */
public EffectDracula(client)
{
	clientEffect[client] = EFFECT_DRACULA;
	clientEffectTimer[client][0] = CreateTimer(15.0, Timer_Dracula, client);
	clientEffectTimer[client][1] = CreateTimer(0.1, Timer_DraculaBlood, client, TIMER_REPEAT);
	
	EmitSoundClient(SOUND_DRACULA, client);
}

/* Timer_DraculaBlood()
**
** Timer for spurting blood.
** ------------------------------------------------------------------------- */
public Action:Timer_DraculaBlood(Handle:timer, any:client)
{
	if (clientEffect[client] != EFFECT_DRACULA) {
		return Plugin_Stop;
	} else {
		CreateParticle("blood_impact_red_01_chunk", 0.1, client, ATTACH_HEAD);
		
		return Plugin_Continue;
	}
}

/* Timer_Dracula()
**
** Timer for Dracula effect.
** ------------------------------------------------------------------------- */
public Action:Timer_Dracula(Handle:timer, any:client)
{
	clientEffect[client] = NO_EFFECT;
	clientEffectTimer[client][0] = INVALID_HANDLE;
	clientEffectTimer[client][1] = INVALID_HANDLE;
	
	if (client && IsClientInGame(client) && !IsClientInKickQueue(client)) {
		ShowEffectWornOff(client, EFFECT_DRACULA);
	}
}

/* EffectConflict()
**
** Effect: Makes everyone think you're dominating them.
** ------------------------------------------------------------------------- */
public EffectConflict(client)
{
	clientEffect[client] = EFFECT_CONFLICT;
	clientEffectTimer[client][0] = CreateTimer(20.0, Timer_Conflict, client);
	
	new clientCount = GetClientCount();

	for (new i = 1; i <= clientCount; i++) {
		if (IsClientConnected(i) && IsClientInGame(i)) {
			SetEntData(i, 	   offsDominatingMe + client, 1, 1, true);
			SetEntData(i, 	   offsDominated 	+ client, 1, 1, true);
			SetEntData(client, offsDominatingMe + i, 	  1, 1, true);
			SetEntData(client, offsDominated 	+ i, 	  1, 1, true);
		}
	}
	
	EmitSoundClient(SOUND_CONFLICT, client);
}

/* Timer_Conflict()
**
** Timer for Conflict effect.
** ------------------------------------------------------------------------- */
public Action:Timer_Conflict(Handle:timer, any:client)
{
	clientEffect[client] = NO_EFFECT;
	clientEffectTimer[client][0] = INVALID_HANDLE;
	
	new clientCount = GetClientCount();

	for (new i = 1; i <= clientCount; i++) {
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientInKickQueue(i)) {
			SetEntData(i, 	   offsDominatingMe + client, 0, 1, true);
			SetEntData(i, 	   offsDominated 	+ client, 0, 1, true);
			SetEntData(client, offsDominatingMe + i, 	  0, 1, true);
			SetEntData(client, offsDominated 	+ i,	  0, 1, true);
		}
	}
	
	if (client && IsClientInGame(client) && !IsClientInKickQueue(client)) {
		ShowEffectWornOff(client, EFFECT_CONFLICT);
	}
}

/* ADMIN MENU ############################################################## */

/* OnAdminMenuReady()
**
** When the Admin Menu is ready.
** ------------------------------------------------------------------------- */
public OnAdminMenuReady(Handle:topmenu)
{
	// Block this from being called twice
	if (topmenu == hTopMenu) {
		return;
	}
 
	// Save the Handle
	hTopMenu = topmenu;
		
	oPresentsMenu = AddToTopMenu(hTopMenu,
		"Presents!",
		TopMenuObject_Category,
		AdminMenu_CategoryHandler,
		INVALID_TOPMENUOBJECT);
	
	AddToTopMenu(hTopMenu, 
		"sm_presents_enable",
		TopMenuObject_Item,
		AdminMenu_Enable,
		oPresentsMenu,
		"sm_presents_enable",
		ADMFLAG_KICK);
		
	AddToTopMenu(hTopMenu, 
		"sm_presents_drop_enable",
		TopMenuObject_Item,
		AdminMenu_DropEnable,
		oPresentsMenu,
		"sm_presents_drop_enable",
		ADMFLAG_KICK);
		
	AddToTopMenu(hTopMenu, 
		"sm_effect",
		TopMenuObject_Item,
		AdminMenu_GiveEffect,
		oPresentsMenu,
		"sm_effect",
		ADMFLAG_KICK);
		
	AddToTopMenu(hTopMenu, 
		"sm_present",
		TopMenuObject_Item,
		AdminMenu_DropPresent,
		oPresentsMenu,
		"sm_present",
		ADMFLAG_KICK);
}

/* AdminMenu_CategoryHandler()
**
** Handles the "Presents Commands" category.
** ------------------------------------------------------------------------- */
public AdminMenu_CategoryHandler(Handle:topmenu, 
			TopMenuAction:action,
			TopMenuObject:object_id,
			param,
			String:buffer[],
			maxlength)
{
	if (action == TopMenuAction_DisplayTitle) {
		Format(buffer, maxlength, "Presents!");
	} else if (action == TopMenuAction_DisplayOption) {
		Format(buffer, maxlength, "Presents!");
	}
}

/* AdminMenu_Enable()
**
** Handles the "sm_presents_enable" option.
** ------------------------------------------------------------------------- */
public AdminMenu_Enable(Handle:topmenu, 
			TopMenuAction:action,
			TopMenuObject:object_id,
			param,
			String:buffer[],
			maxlength)
{
	if (action == TopMenuAction_DisplayOption) {
		if (pluginEnabled) {
			Format(buffer, maxlength, "[ Disable Presents! ]");
		} else {
			Format(buffer, maxlength, "[ Enable Presents! ]");
		}
	} else if (action == TopMenuAction_SelectOption) {
		SetConVarBool(cvEnable, !pluginEnabled);
		RedisplayAdminMenu(hTopMenu, param);
	}
}

/* AdminMenu_DropEnable()
**
** Handles the "sm_presents_drop_enable" option.
** ------------------------------------------------------------------------- */
public AdminMenu_DropEnable(Handle:topmenu, 
			TopMenuAction:action,
			TopMenuObject:object_id,
			param,
			String:buffer[],
			maxlength)
{
	if (action == TopMenuAction_DisplayOption) {
		if (GetConVarBool(cvDropEnable)) {
			Format(buffer, maxlength, "[ Disable Random Drops ]");
		} else {
			Format(buffer, maxlength, "[ Enable Random Drops ]");
		}
	} else if (action == TopMenuAction_SelectOption) {
		SetConVarBool(cvDropEnable, !GetConVarBool(cvDropEnable));
		RedisplayAdminMenu(hTopMenu, param);
	} else if (action == TopMenuAction_DrawOption) {
		buffer[0] = (pluginEnabled ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	}
}

/* AdminMenu_GiveEffect()
**
** Handles the "Give player an Effect" option.
** ------------------------------------------------------------------------- */
public AdminMenu_GiveEffect(Handle:topmenu, 
			TopMenuAction:action,
			TopMenuObject:object_id,
			param,
			String:buffer[],
			maxlength)
{
	if (action == TopMenuAction_DisplayOption) {
		Format(buffer, maxlength, "Give player an effect");
	} else if (action == TopMenuAction_SelectOption) {
		if (pluginEnabled) {
			DisplayGiveEffectMenu(param);
		} else {
			RedisplayAdminMenu(hTopMenu, param);
		}
	} else if (action == TopMenuAction_DrawOption) {
		buffer[0] = (pluginEnabled ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	}
}

/* DisplayGivePresentEffectMenu()
**
** Displays the GivePresentEffect menu for selecting effects.
** ------------------------------------------------------------------------- */
DisplayGiveEffectMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_GiveEffect);
	
	SetMenuTitle(menu, "Select effect:");
	SetMenuExitBackButton(menu, true);
	
	AddEffectsToMenu(menu, client);
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

/* MenuHandler_GiveEffect()
**
** Handles input for the GiveEffect menu.
** ------------------------------------------------------------------------- */
public MenuHandler_GiveEffect(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End) {
		CloseHandle(menu);
	} else if (action == MenuAction_Cancel) {
		if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE) {
			DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
		}
	} else if (action == MenuAction_Select) {
		adminGiveEffect[param1] = param2;
		
		DisplayGiveEffectTargetMenu(param1, 0);
	}
}

/* DisplayGiveEffectTargetMenu()
**
** Displays the GivePresentTarget menu for selecting players.
** ------------------------------------------------------------------------- */
DisplayGiveEffectTargetMenu(client, item)
{
	new Handle:menu = CreateMenu(MenuHandler_GiveEffectTarget);
	
	SetMenuTitle(menu, "Select player:");
	SetMenuExitBackButton(menu, true);
	
	AddTargetsToMenu(menu, client, true, true);
	AddMenuItem(menu, "-1", "[ RED Team ]");
	AddMenuItem(menu, "-2", "[ BLU Team ]");
	AddMenuItem(menu, "-3", "[ Everyone ]");
	
	if (item == 0) {
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	} else {
		DisplayMenuAtItem(menu, client, item, MENU_TIME_FOREVER);
	}
}

/* MenuHandler_GivePresentTarget()
**
** Handles input for the 'Give player a Present' menu.
** ------------------------------------------------------------------------- */
public MenuHandler_GiveEffectTarget(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End) {
		CloseHandle(menu);
	} else if (action == MenuAction_Cancel) {
		if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE) {
			DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
		}
	} else if (action == MenuAction_Select) {
		decl String:info[32];
		new userid, target;
		
		GetMenuItem(menu, param2, info, sizeof(info));
		userid = StringToInt(info);

		if ((userid > 0) && ((target = GetClientOfUserId(userid)) == 0)) {
			PrintToChat(param1, "[SM] %t", "Player no longer available");
		} else if ((userid > 0) &&(!CanUserTarget(param1, target))) {
			PrintToChat(param1, "[SM] %t", "Unable to target");
		} else {
			if (userid > 0) {
				GiveEffect(target, adminGiveEffect[param1]);
			} else {
				GiveEffect(userid, adminGiveEffect[param1]);
			}
		}
		
		/* Re-draw the menu if they're still valid */
		if (IsClientInGame(param1) && !IsClientInKickQueue(param1)) {
			DisplayGiveEffectTargetMenu(param1, GetMenuSelectionPosition());
		}
	}
}

/* AdminMenu_DropPresent()
**
** Handles the "Drop a Present" option.
** ------------------------------------------------------------------------- */
public AdminMenu_DropPresent(Handle:topmenu, 
			TopMenuAction:action,
			TopMenuObject:object_id,
			param,
			String:buffer[],
			maxlength)
{
	if (action == TopMenuAction_DisplayOption) {
		Format(buffer, maxlength, "Drop a present");
	} else if (action == TopMenuAction_SelectOption) {
		if (pluginEnabled) {
			DropPresent(param);
			RedisplayAdminMenu(hTopMenu, param);
		}
	} else if (action == TopMenuAction_DrawOption) {
		buffer[0] = (pluginEnabled ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	}
}

/* AddEffectsToMenu()
**
** Adds the effects to the given menu.
** ------------------------------------------------------------------------- */
AddEffectsToMenu(Handle:menu, client)
{
	decl String:name[64];
	Format(name, sizeof(name), "[ %T ]", "Random", client);
	
	AddMenuItem(menu, "Random", name);
	
	for (new i = 0; i < NUM_EFFECTS; i++) {
		Format(name, sizeof(name), "%T", effectName[i], client);
		AddMenuItem(menu, effectName[i], name);
	}
}

/* UTILITY FUNCTIONS ####################################################### */

/* TeleportPlayerToSkybox()
**
** Teleports a player to the skybox if it exits. Returns success.
** ------------------------------------------------------------------------- */
stock bool:TeleportPlayerToSkybox(client)
{
	new Float:pos[3];
	
	GetEntPropVector(client, Prop_Send, "m_skybox3d.origin", pos);
	
	if ((pos[0] != 0.0) || (pos[1] != 0.0) || (pos[2] != 0.0)) {
		// Skybox exists
		TeleportEntity(client, pos, NULL_VECTOR, NULL_VECTOR);
		return true;
	} else {
		// No 3D Skybox
		return false;
	}
}

/* ShowOverlay()
**
** Shows an overlay.
** ------------------------------------------------------------------------- */
public ShowOverlay(client, String:overlay[], Float:time)
{	
	new Handle:pack;
	
	clientOverlay[client] = true;
	
	OverlayCommand(client, overlay);
	
	CreateDataTimer(0.1, Timer_MaintainOverlay, pack, TIMER_REPEAT);
	
	WritePackCell(pack, client);
	WritePackString(pack, overlay);
	WritePackFloat(pack, time);
}

/* OverlayCommand()
**
** Runs r_screenoverlay on a client (removing cheat flags and then adding them again quickly).
** ------------------------------------------------------------------------- */
public OverlayCommand(client, String:overlay[])
{	
	if (client && IsClientInGame(client) && !IsClientInKickQueue(client)) {
		new flags; 
		
		flags  = GetCommandFlags("r_screenoverlay") & (~FCVAR_CHEAT);
		SetCommandFlags("r_screenoverlay", flags);

		ClientCommand(client, "r_screenoverlay %s", overlay);
		
		if (overlayTimer != INVALID_HANDLE) {
			KillTimer(overlayTimer);
		}
		
		overlayTimer = CreateTimer(0.1, Timer_OverlayBlockCommand);
	}
}

/* Timer_MaintainOverlay()
**
** Maintains an overlay on a client for a given time. Otherwise it gets reset by fire, etc.
** ------------------------------------------------------------------------- */
public Action:Timer_MaintainOverlay(Handle:timer, Handle:pack)
{
	new client, String:overlay[64], Float:time;
	
	ResetPack(pack);
	client = ReadPackCell(pack);
	ReadPackString(pack, overlay, 64);
	time = ReadPackFloat(pack);
	
	if (client && IsClientInGame(client) && !IsClientInKickQueue(client)) {
		time -= 0.1;
		
		if ((RoundToFloor(time * 10) <= 0) || !clientOverlay[client]) {
			OverlayCommand(client, "\"\"");
			clientOverlay[client] = false;
			
			return Plugin_Stop;
		}
		
		OverlayCommand(client, overlay);
		
		ResetPack(pack);
		WritePackCell(pack, client);
		WritePackString(pack, overlay);
		WritePackFloat(pack, time);
		
		return Plugin_Continue;
	} else {
		return Plugin_Stop;
	}
}

/* Timer_OverlayBlockCommand()
**
** Blocks r_screenoverlay command.
** ------------------------------------------------------------------------- */
public Action:Timer_OverlayBlockCommand(Handle:timer)
{
	overlayTimer = INVALID_HANDLE;
	
	new flags = GetCommandFlags("r_screenoverlay") | (FCVAR_CHEAT);
	SetCommandFlags("r_screenoverlay", flags);
}

/* Shake()
**
** Shakes the client's screen.
** ------------------------------------------------------------------------- */
stock Shake(client)
{	
	new flags = GetCommandFlags("shake") & (~FCVAR_CHEAT);
	SetCommandFlags("shake", flags);

	FakeClientCommand(client, "shake");
	
	// Timer not needed because we're using FakeClientCommand
	flags = GetCommandFlags("shake") | (FCVAR_CHEAT);
	SetCommandFlags("shake", flags);
}

/* EmitSoundClient()
**
** Emits an ambient sound near a client.
** ------------------------------------------------------------------------- */
stock EmitSoundClient(String:sound[], client)
{
	decl Float:pos[3];
	
	GetClientAbsOrigin(client, pos);
	
	EmitAmbientSound(sound, pos, client);
}

/* BuildSentry()
**
** Builds a sentry.
**
** Credit to The JCS and Muridas.
** ------------------------------------------------------------------------- */
stock BuildSentry(iBuilder, Float:fOrigin[3], Float:fAngle[3], iLevel=1)
{
	new Float:fBuildMaxs[3] = {24.0, 24.0, 66.0};
	new Float:fMdlWidth[3] = {1.0, 0.5, 0.0};

	new String:sModel[64];
	new iTeam = GetClientTeam(iBuilder);
	new iShells, iHealth, iRockets;

	switch (iLevel) {
		case 1: {
			sModel = "models/buildables/sentry1.mdl";
			iShells = 100;
			iHealth = 150;
		}
		case 2: {
			sModel = "models/buildables/sentry2.mdl";
			iShells = 120;
			iHealth = 180;
		}
		case 3: {
			sModel = "models/buildables/sentry3.mdl";
			iShells = 144;
			iHealth = 216;
			iRockets = 20;
		}
	}

	new iSentry = CreateEntityByName("obj_sentrygun");
	
	if (IsValidEdict(iSentry)) {
		// TODO: Clean this up, are all these attributes needed?
		TeleportEntity(iSentry, fOrigin, fAngle, NULL_VECTOR);
		DispatchSpawn(iSentry);

		SetEntityModel(iSentry,sModel);

		SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_flAnimTime"),                 51, 4 , true);
		SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_nNewSequenceParity"),         4, 4 , true);
		SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_nResetEventsParity"),         4, 4 , true);
		SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_iAmmoShells") ,                 iShells, 4, true);
		SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_iMaxHealth"),                 iHealth, 4, true);
		SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_iHealth"),                     iHealth, 4, true);
		SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_bBuilding"),                 0, 2, true);
		SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_bPlacing"),                     0, 2, true);
		SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_bDisabled"),                 0, 2, true);
		SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_iObjectType"),                 3, true);
		SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_iState"),                     1, true);
		SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_iUpgradeMetal"),             0, true);
		SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_bHasSapper"),                 0, 2, true);
		SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_nSkin"),                     (iTeam-2), 1, true);
		SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_bServerOverridePlacement"),     1, 1, true);
		SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_iUpgradeLevel"),             iLevel, 4, true);
		SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_iAmmoRockets"),                 iRockets, 4, true);

		SetEntDataEnt2(iSentry, FindSendPropOffs("CObjectSentrygun","m_nSequence"), 0, true);
		SetEntDataEnt2(iSentry, FindSendPropOffs("CObjectSentrygun","m_hBuilder"), iBuilder, true);

		SetEntDataFloat(iSentry, FindSendPropOffs("CObjectSentrygun","m_flCycle"),                     0.0, true);
		SetEntDataFloat(iSentry, FindSendPropOffs("CObjectSentrygun","m_flPlaybackRate"),             1.0, true);
		SetEntDataFloat(iSentry, FindSendPropOffs("CObjectSentrygun","m_flPercentageConstructed"),     1.0, true);

		SetEntDataVector(iSentry, FindSendPropOffs("CObjectSentrygun","m_vecOrigin"),             fOrigin, true);
		SetEntDataVector(iSentry, FindSendPropOffs("CObjectSentrygun","m_angRotation"),         fAngle, true);
		SetEntDataVector(iSentry, FindSendPropOffs("CObjectSentrygun","m_vecBuildMaxs"),         fBuildMaxs, true);
		SetEntDataVector(iSentry, FindSendPropOffs("CObjectSentrygun","m_flModelWidthScale"),     fMdlWidth, true);

		SetVariantInt(iTeam);
		AcceptEntityInput(iSentry, "TeamNum", -1, -1, 0);

		SetVariantInt(iTeam);
		AcceptEntityInput(iSentry, "SetTeam", -1, -1, 0); 
	}

	return iSentry;
}

/* DestroyBuilding()
**
** Destroys a building.
** ------------------------------------------------------------------------- */
stock DestroyBuilding(building)
{
	SetVariantInt(1000);
	AcceptEntityInput(building, "RemoveHealth");
}

/* TF2_GetClassSpeed()
**
** Returns a class' base speed.
** ------------------------------------------------------------------------- */
stock Float:TF2_GetClassSpeed(TFClassType:class)
{
    switch (class) {
        case TFClass_Scout:     return 400.0;
        case TFClass_Soldier:   return 240.0;
        case TFClass_DemoMan:   return 280.0;
        case TFClass_Medic:     return 320.0;
        case TFClass_Pyro:      return 300.0;
        case TFClass_Spy:       return 300.0;
        case TFClass_Engineer:  return 300.0;
        case TFClass_Sniper:    return 300.0;
        case TFClass_Heavy:     return 230.0;
    }
	
    return 0.0;
}

/* ColorizePlayer()
**
** Colorizes a client.
**
** Credit to linux_lower.
** ------------------------------------------------------------------------- */
public ColorizePlayer(client, color[4])
{
	new maxents = GetMaxEntities();
	// Colorize player and weapons
	new m_hMyWeapons = FindSendPropOffs("CBasePlayer", "m_hMyWeapons");	
	new g_ownerOffset = FindSendPropInfo("CTFWearableItem", "m_hOwnerEntity");
	
	for(new i = 0, weapon; i < 47; i += 4)
	{
		weapon = GetEntDataEnt2(client, m_hMyWeapons + i);
	
		if(weapon > -1 )
		{
			SetEntityRenderMode(weapon, RENDER_TRANSCOLOR);
			SetEntityRenderColor(weapon, color[0], color[1],color[2], color[3]);
		}
	}
	
	SetEntityRenderMode(client, RENDER_TRANSCOLOR);	
	SetEntityRenderColor(client, color[0], color[1], color[2], color[3]);
	
	// Colorize any wearable items
	for (new i = MaxClients + 1; i <= maxents; i++) {
		if (!IsValidEntity(i)) continue;
		
		decl String:netclass[32];
		GetEntityNetClass(i, netclass, sizeof(netclass));
		
		if (strcmp(netclass, "CTFWearableItem") == 0) {
			if (GetEntDataEnt2(i, g_ownerOffset) == client) {
				SetEntityRenderMode(i, RENDER_TRANSCOLOR);
				SetEntityRenderColor(i, color[0], color[1], color[2], color[3]);
			}
		}
	}
}

// Particles ------------------------------------------------------------------

/* CreateParticle()
**
** Creates a particle at an entity's position. Attach determines the attachment
** type (0 = not attached, 1 = normal attachment, 2 = head attachment). Allows
** offsets from the entity's position. Returns the handle of the timer that
** deletes the particle (should you wish to trigger it early).
** ------------------------------------------------------------------------- */
stock Handle:CreateParticle(String:type[], Float:time, entity, attach=NO_ATTACH, Float:xOffs=0.0, Float:yOffs=0.0, Float:zOffs=0.0)
{
	new particle = CreateEntityByName("info_particle_system");
	
	// Check if it was created correctly
	if (IsValidEdict(particle)) {
		decl Float:pos[3];

		// Get position of entity
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
		
		// Add position offsets
		pos[0] += xOffs;
		pos[1] += yOffs;
		pos[2] += zOffs;
		
		// Teleport, set up
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(particle, "effect_name", type);

		if (attach != NO_ATTACH) {
			SetVariantString("!activator");
			AcceptEntityInput(particle, "SetParent", entity, particle, 0);
		
			if (attach == ATTACH_HEAD) {
				SetVariantString("head");
				AcceptEntityInput(particle, "SetParentAttachmentMaintainOffset", particle, particle, 0);
			}
		}
		
		// All entities in presents are given a targetname to make clean up easier
		DispatchKeyValue(particle, "targetname", "present");

		// Spawn and start
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "Start");
		
		return CreateTimer(time, DeleteParticle, particle);
	} else {
		LogError("Presents (CreateParticle): Could not create info_particle_system");
	}
	
	return INVALID_HANDLE;
}

/* DeleteParticle()
**
** Deletes a particle.
** ------------------------------------------------------------------------- */
public Action:DeleteParticle(Handle:timer, any:particle)
{
	if (IsValidEdict(particle)) {
		new String:classname[64];
		GetEdictClassname(particle, classname, sizeof(classname));
		
		if (StrEqual(classname, "info_particle_system", false)) {
			RemoveEdict(particle);
		}
	}
}

/* SaveHealth()
**
** Saves a client's health. From damage.inc.
** ------------------------------------------------------------------------- */
stock SaveHealth(client)
{
	if (client && IsClientInGame(client) && !IsClientInKickQueue(client) && IsPlayerAlive(client)) {
		savedHealth[client] = GetClientHealth(client);
	}
}

/* GetSavedHealth()
**
** Returns a client's saved health. From damage.inc.
** ------------------------------------------------------------------------- */
stock GetSavedHealth(client)
{
    return savedHealth[client];
}

/* SaveAllHealth()
**
** Saves all client's health. From damage.inc (fixed not checking IsClientInGame).
** ------------------------------------------------------------------------- */
stock SaveAllHealth()
{
    new clientCount = GetClientCount();
	
    for (new i = 1; i <= clientCount; i++) {
		SaveHealth(i);
    }
}

/* GetDamage()
**
** Gets damage from player_hurt event. From damage.inc (modified).
** ------------------------------------------------------------------------- */
stock GetDamage(Handle:event)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new prevHealth = savedHealth[victim]; 
	
	if (prevHealth) {
		return prevHealth - GetEventInt(event, "health");
	}
	
	return 0;
}

/* SayText2()
**
** Says text to everyone. Allows better colours.
** ------------------------------------------------------------------------- */
stock SayText2(author_index, const String:mess[])
{
    new Handle:buffer = StartMessageAll("SayText2");
    if (buffer != INVALID_HANDLE) {
        BfWriteByte(buffer, author_index);
        BfWriteByte(buffer, true);
        BfWriteString(buffer, mess);
        EndMessage();
    }
}

/* SayText2Single()
**
** Says text to one player. Allows better colours.
** ------------------------------------------------------------------------- */
stock SayText2Single(author_index, const String:mess[])
{
    new Handle:buffer = StartMessageOne("SayText2", author_index);
    if (buffer != INVALID_HANDLE) {
        BfWriteByte(buffer, author_index);
        BfWriteByte(buffer, true);
        BfWriteString(buffer, mess);
        EndMessage();
    }
}

/* TF2_SetPlayerDominated()
**
** Sets a player as dominating another player.
** ------------------------------------------------------------------------- */
stock TF2_SetPlayerDominated(dominator, victim, bool:value=true)
{
	SetEntData(dominator, offsDominated + victim, value, 1, true);
	SetEntData(victim, offsDominatingMe + dominator, value, 1, true);
}