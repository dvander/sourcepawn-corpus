/*
	[TF2] Gift Mod 
	Author: Chaosxk (Tak)
	Alliedmodders: http://forums.alliedmods.net/member.php?u=87026
	Steam Community: http://steamcommunity.com/groups/giftmod
	Current Version: 1.3.0
	
	*** = completed
	Version Log:
	1.3.0 - 
	- Uses ent-references instead of looping for each entities name (safer) ***
	- Changed a bunch of if-else statements to cases ***
	- Removed the teleporter glow when player gets a gift ***
	- Replaced all the global variables with 1 that indicates the ability with a number ***
	- Uses temp-ents instead of creating info_particle_system ***
	- Removed fireworks effect when gift spawn since it doesn't actually work/exist ***
	- Fixed clear timer on client disconnect ***
	- Big and small head is placed as a bad effect ***
	- Big and small head now uses tf2attributes ***
	- Hyper and snail now uses tf2attributes ***
	- Balls of steel slowdown uses tf2attributes ***
	- Fixed inverse effect not resetting properly ***
	- No Longer uses OnGameFrame ***
	- Fixed Funny Feeling inverse view on round-start reset ***
	- Added a maximum damage (300) for dracula blood so players don't overheal with 6000+ hp when backstabbing a saxton hale for example ***
	- Disabled ability config should reload onmapstart instead of onpluginstart ***
	- Removed pitfall (Might be the reason for crashes) ***
	- Incendiary ammo ***
	- Unusual Troll (Announce to server that you found an unusual, fake one of course)
	- Pyrovision
	- Romevision
	- Timebomb w/ sentry buster model
	- Explode
	- Ubered/Godmode
	- Fly mode
	- Crits
	- Drugged
	
	Description:
	When a player dies, they will drop a gift/present box.  
	A player can take this gift and gain an effect
	The effect can either be bad or good or so so
	
	Dependency: 
	Sourcemod 1.5 +
	Metamod 1.9 +
	TF2Attributes 1.1.0 +
	
	Morecolors.inc for compiling
	Updater optional
*/
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <morecolors>
#include <clientprefs>
#include <tf2attributes>
#undef REQUIRE_PLUGIN
#include <updater>

//Definitions
#define PLUGIN_VERSION "1.2.3"
#define MDL "models/items/tf_gift.mdl"
#define MDL2 "models/props_halloween/halloween_gift.mdl"
#define EFFECT1 "models/items/ammopack_small_bday.mdl"
#define EFFECT2 "models/items/ammopack_large_bday.mdl"
#define MDL_CONFETTI "bday_confetti"
#define SND_BRDY "misc/happy_birthday.wav"
#define MDL_NADE "models/weapons/w_models/w_cannonball.mdl"
#define spirite "spirites/zerogxplode.spr"
#define INFO "http://steamcommunity.com/groups/giftmod"
#define UPDATE_URL "http://dl.dropboxusercontent.com/u/100132876/giftupdater.txt"
////////////////////////////////////////////////////////////////////////////////////////////////////
new Handle:Enabled,
Handle:dropChance,
Handle:dieTime,
Handle:giftSize,
Handle:teamMode,
Handle:Suicide,
Handle:FakeGifts,
Handle:CoolDown,
Handle:goodChance,
Handle:adminFlag,
Handle:adminChance,
Handle:modelBoxes,
Handle:cvarDisabled,
Handle:autoUpdate,
Handle:showAds = INVALID_HANDLE;
////////////////////////////////////////////////////////////////////////////////////////////////////
new Handle:funnyFeeling,
Handle:draculaHeal,
Handle:sentryLevel,
Handle:miniHP,
Handle:alphaCamo,
Handle:featherTouch,
Handle:ballsDefence,
Handle:blindEffect,
Handle:nadeDamage,
Handle:toxicDamage,
Handle:toxicRadius,
Handle:dLevel = INVALID_HANDLE;
//Handle:jumpHeight = INVALID_HANDLE;
////////////////////////////////////////////////////////////////////////////////////////////////////
new Handle:resetKnockTimer,
Handle:resetAlphaTimer,
Handle:resetMiniCritsTimer,
Handle:resetDraculaTimer,
Handle:resetGravityTimer,
Handle:resetSentryTimer,
Handle:resetNostalgiaTimer,
Handle:resetBHeadTimer,
Handle:resetSHeadTimer,
Handle:resetSpeedTimer,
Handle:resetBrainTimer,
Handle:resetSteelTimer,
Handle:resetInverseTimer,
Handle:resetBlindTimer,
Handle:resetShakeTimer,
Handle:resetSnailTimer,
Handle:resetToxicTimer,
Handle:resetNoobTimer,
Handle:resetScaryTimer,
Handle:resetIncendiaryTimer = INVALID_HANDLE;
//Handle:resetSuperjumpTimer = INVALID_HANDLE;
////////////////////////////////////////////////////////////////////////////////////////////////////
new Handle:clientTimer[MAXPLAYERS+1] = {INVALID_HANDLE, ...};
new Handle:inverseTimer[MAXPLAYERS+1] = {INVALID_HANDLE, ...};
new Handle:tauntTimer[MAXPLAYERS+1] = {INVALID_HANDLE, ...};
new Handle:arrayCell;
////////////////////////////////////////////////////////////////////////////////////////////////////
new ability[MAXPLAYERS+1];
new bool:activeEffect[MAXPLAYERS+1];
new g_timeLeft[MAXPLAYERS+1];
new sentry[MAXPLAYERS+1];
new playerIsBurried[MAXPLAYERS+1];
////////////////////////////////////////////////////////////////////////////////////////////////////
new Float:g_Ang[3];
new Float:clientAngles[MAXPLAYERS+1][3];
new isReversed[MAXPLAYERS+1] = {0,...};
new g_sEnt[MAXPLAYERS+1] = {-1,...};
////////////////////////////////////////////////////////////////////////////////////////////////////
new NadeCounter[MAXPLAYERS+1];
new nadeEntity[MAXPLAYERS+1];
////////////////////////////////////////////////////////////////////////////////////////////////////
new playerAdCount[MAXPLAYERS+1];
new Handle:GiftCount = INVALID_HANDLE;
new playerCookie[MAXPLAYERS+1];
////////////////////////////////////////////////////////////////////////////////////////////////////
new const String:g_goodName[][] = {
	"minihp",
	"knocker",
	"hyper",
	"camoflage",
	"dracula",
	"feather",
	"sentry",
	"ballsofsteel",
	"grenade",
	"toxic",
	"dispenser",
	"scary",
	"incendiary"
	//{"superjump"}
};
////////////////////////////////////////////////////////////////////////////////////////////////////
new const String:g_badName[][] = {
	"dance",
	"funnyfeeling",
	"nostalgia",
	"onehp",
	"braindead",
	"inverse",
	"blind",
	"dejavu",
	"earthquake",
	"snail",
	"noob",
	"bighead",
	"smallhead"
};
////////////////////////////////////////////////////////////////////////////////////////////////////
new g_good[sizeof(g_goodName)+1];
new g_bad[sizeof(g_badName)+1];
////////////////////////////////////////////////////////////////////////////////////////////////////
new Float:g_pos[3];
new bool:lateLoaded;
new tauntcounter[MAXPLAYERS+1];
new bool:roundStart = false;
////////////////////////////////////////////////////////////////////////////////////////////////////
public Plugin:myinfo = {
	name = "[TF2] Gift Mod",
	description = "Collect and gain a random effect from gifts that are dropped.",
	author = "Tak (Chaosxk)",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) {
	new String:Game[32];
	GetGameFolderName(Game, sizeof(Game));
	lateLoaded = late;
	if(!StrEqual(Game, "tf")) {
		Format(error, err_max, "This plugin only works for Team Fortress 2");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

public OnPluginStart() {
	CreateConVar("sm_gift_version", PLUGIN_VERSION, "Version of Gift Mod.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	Enabled = CreateConVar("sm_gift_enabled", "1", "Enable/Disable plugin, 1/0", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	dropChance = CreateConVar("sm_gift_dropchance", "0.65", "What is the chance of dropping gifts on a player death? (Default: 0.65) [0.00 - 1.00]");
	dieTime = CreateConVar("sm_gift_removetimer", "60", "How long before gifts are removed if no one picks it up. (Default: 60)");
	giftSize = CreateConVar("sm_gift_size", "1.2", "Size of gift: (Default: 1.2)");
	teamMode = CreateConVar("sm_gift_allowedteams", "1", "Which teams are allowed to pick up gifts? (0 = none, 1 = All, 2 = Red, 3 = Blue) (Default: 1)");
	Suicide = CreateConVar("sm_gift_suicide", "0", "Allow players who suicide to drop gifts. (Default: 0)");
	FakeGifts = CreateConVar("sm_gift_fake", "1", "Spawn fake gifts when a spy faked his death with the dead ringer? (Default: 1)");
	CoolDown = CreateConVar("sm_gift_cooldown", "3", "How many seconds after the gift has dropped before it can be picked up. (Default: 3)");
	goodChance = CreateConVar("sm_gift_chance", "0.65", "Chances of a good effect being picked up? (Default: 0.65)");
	adminChance = CreateConVar("sm_gift_adminchance", "0.65", "Chances of a good effect being picked up? (Default: 0.65)");
	adminFlag = CreateConVar("sm_gift_flag", "b", "What flag should be used for sm_gift_adminchance? (Default: b)");
	modelBoxes = CreateConVar("sm_gift_models", "2", "Which model box should spawn? (0 = Christmas/Blue, 1 = Halloween/Green, 2 = Both) (Default: 1)");
	cvarDisabled = CreateConVar("sm_gift_disabled", "", "What effect should be disabled?");
	autoUpdate = CreateConVar("sm_gift_update", "1", "Allow this plugin to automatically update? (Default: 1)");
	showAds = CreateConVar("sm_gift_showads", "1", "Allow this plugin tell people who first join the server about gift mod? (Default: 1)");
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	funnyFeeling = CreateConVar("sm_gift_funnyfeeling_fov", "160", "What should the funny feeling FOV be? (Default: 160)");
	sentryLevel = CreateConVar("sm_gift_sentrylevel", "1", "What level should sentries spawn as? (Default: 1)");
	draculaHeal = CreateConVar("sm_gift_draculaheal", "0.3", "What percent of damage is healed towards you for Dracula's blood. (Default: 0.3)");
	miniHP = CreateConVar("sm_gift_health", "250", "How much health to give for Minihealth effect? (Default: 250)");
	alphaCamo = CreateConVar("sm_gift_camo_alpha", "30", "What should the alpha be for Camoflage? (Default: 30)");
	featherTouch = CreateConVar("sm_gift_feather_gravity", "0.15", "What should the gravity be for Feather's touch? (Default: 0.15)");
	ballsDefence = CreateConVar("sm_gift_ballsofsteel_defence", "0.5", "What percentage of damage does player recieved when they are hurt? (Default: 0.5)");
	blindEffect = CreateConVar("sm_gift_blind_darkness", "255", "How much to darkness should player be blind? (Default: 255)");
	nadeDamage = CreateConVar("sm_gift_nade_damage", "200", "How much damage should nades do? (Default: 200)");
	toxicDamage = CreateConVar("sm_gift_toxic_damage", "35", "How much damage should toxic do? (Default: 35)");
	toxicRadius = CreateConVar("sm_gift_toxic_radius", "350", "What is the radius of toxic? (Default: 350)");
	dLevel = CreateConVar("sm_gift_dispenserlevel", "3", "What level should dispensers spawn as? (Default: 3)");
	//jumpHeight = CreateConVar("sm_gift_superjump_height", "1.5", "How much extra height should be added to player jump with superjump? (Default: 1.5)");
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	resetMiniCritsTimer = CreateConVar("sm_gift_minihealth", "15", "How many seconds should Mini Health last? (Default: 15.0)");
	resetKnockTimer = CreateConVar("sm_gift_knockback", "15", "How many seconds should Knockers last? (Default: 15.0)");
	resetBHeadTimer = CreateConVar("sm_gift_bighead", "20.0", "How many seconds should big head reset back to normal? (Default: 20.0)");
	resetSHeadTimer = CreateConVar("sm_gift_smallhead", "20.0", "How many seconds should small head reset back to normal? (Default: 20.0)");
	resetSpeedTimer = CreateConVar("sm_gift_speed", "20.0", "How many seconds should speed reset back to normal? (Default: 20.0)");
	resetAlphaTimer = CreateConVar("sm_gift_camoflage", "15.0", "How many seconds for Camoflage to reset back to normal? (Default: 15.0)");
	resetDraculaTimer = CreateConVar("sm_gift_dracula", "15.0", "How many seconds should Dracula heart last? (Default: 15.0)");
	resetGravityTimer = CreateConVar("sm_gift_gravity", "15.0", "How many seconds should Gravity last? (Default: 15.0)");
	resetNostalgiaTimer = CreateConVar("sm_gift_nostalgia", "15.0", "How long should nostalgia last? (Default: 15.0)");
	resetSentryTimer = CreateConVar("sm_gift_sentry", "15.0", "How many seconds should the Sentry gun last? (Default: 15.0)");
	resetBrainTimer = CreateConVar("sm_gift_braindead", "5.0", "How many seconds should Brain dead last? (Default: 5.0)");
	resetSteelTimer = CreateConVar("sm_gift_ballsofsteel", "15.0", "How many seconds should Balls of Steel last? (Default: 15.0)");
	resetInverseTimer = CreateConVar("sm_gift_inverse", "15.0", "How many seconds Inverse view last? (Default: 15.0)");
	resetBlindTimer = CreateConVar("sm_gift_blind", "15.0", "How many seconds does blind last? (Default: 15.0)");
	resetShakeTimer = CreateConVar("sm_gift_shake", "15.0", "How many seconds does earthquake last? (Default: 15.0)");
	resetSnailTimer = CreateConVar("sm_gift_snail", "20.0", "How many seconds does snail last? (Default: 20.0)");
	resetToxicTimer = CreateConVar("sm_gift_toxic", "20.0", "How many seconds does toxic last? (Default: 20.0)");
	resetNoobTimer  = CreateConVar("sm_gift_noob", "20.0", "How many seconds does noob mode last? (Default: 20.0)");
	resetScaryTimer  = CreateConVar("sm_gift_scary", "20.0", "How many seconds does scary bullets last? (Default: 20.0)");
	resetIncendiaryTimer = CreateConVar("sm_gift_incendiary", "20.0", "How many seconds should incendiary ammo last? (Default: 20.0)");
	//resetSuperjumpTimer = CreateConVar("sm_gift_superjump", "20.0", "How many seconds should superjump last? (Default: 20.0)");
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
	HookEvent("player_team", OnTeamChange);
	HookEvent("teamplay_round_start", OnRoundStart);
	HookEvent("teamplay_round_win", OnRoundEnd);
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	RegAdminCmd("sm_seteffect", SetEffect, ADMFLAG_GENERIC, "Set one of the effects on yourself. (!seteffect <player> <effectname>)");
	RegAdminCmd("sm_removeeffect", RemoveEffect, ADMFLAG_GENERIC, "Removes all effect off yourself.");
	RegAdminCmd("sm_listeffect", ListEffect, ADMFLAG_GENERIC, "List the effects in console.");
	RegAdminCmd("sm_spawngift", SpawnGift, ADMFLAG_GENERIC, "Spawns a gift at your cursor.");
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	RegConsoleCmd("sm_gift", Gift, "Shows how many gift you have collected.");
	RegConsoleCmd("sm_gifthelp", GiftHelp, "Shows the Gift Community Page which has description of each effect.");
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	GiftCount = RegClientCookie("giftmodcookies", "Gift Tracker Cookies", CookieAccess_Private);
	HookConVarChange(cvarDisabled, cvarChange);
	AddCommandListener(VoiceListener, "voicemenu");
	LoadTranslations("common.phrases");
	LoadTranslations("gift.phrases");
	AutoExecConfig(true, "gift");
	ServerCommand("sm_gift_version %s", PLUGIN_VERSION);
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	if(GetConVarInt(autoUpdate) == 1) {
		if(LibraryExists("updater")) {
			Updater_AddPlugin(UPDATE_URL);
		}
	}
	arrayCell = CreateArray();
}

public OnPluginEnd() {
	for(new i = 0; i < GetArraySize(arrayCell); i++) {
		new ent = EntRefToEntIndex(GetArrayCell(arrayCell, i));
		if(IsValidEntity(ent)) {
			AcceptEntityInput(ent, "kill");
		}
	}
}

public OnLibraryAdded(const String:name[]) {
	if(GetConVarInt(autoUpdate) == 1) {
		if(StrEqual(name, "updater")) {
			Updater_AddPlugin(UPDATE_URL);
		}
	}
}

//precache on mapstart
public OnMapStart() {
	PrecacheModel(MDL, true);
	PrecacheModel(MDL2, true);
	PrecacheModel(EFFECT1, true);
	PrecacheModel(EFFECT2, true);
	PrecacheSound(SND_BRDY, true);
	PrecacheGeneric(MDL_CONFETTI, true);
	PrecacheModel(MDL_NADE, true);
	PrecacheModel(spirite, true);
	LoadDisabledAbilities();
}

//resets the variables of player number so the next connection does not recieve effect
public OnClientPostAdminCheck(client) {
	GetCookie(client);
	//hooks the ontakedamage for newly connected players
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public OnClientDisconnect_Post(client) {
	nadeEntity[client] = 0;
	playerIsBurried[client] = 0;
	playerAdCount[client] = 0;
	playerCookie[client] = 0;
	resetEffects(client);
	//removeAttribute(client, "increased jump height");
}

//used to load lateloaded stuff
public OnConfigsExecuted() {
	if(Enabled) {
		if(lateLoaded) {
			for(new i = 1; i <= MaxClients; i++) {
				if(IsValidClient(i)) {
					SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
					playerCookie[i] = 0;
					GetCookie(i);
				}
			}
			lateLoaded = false;
			roundStart = true;
		}
	}
}

//reloads when cvar changes
public cvarChange(Handle:convar, String:oldValue[], String:newValue[]) {
	if(convar == cvarDisabled) {
		LoadDisabledAbilities();
	}
}

//sets effect on a player
public Action:SetEffect(client, args) {
	if(Enabled) {
		decl String:arg1[65], String:arg2[65];
		GetCmdArg(1, arg1, sizeof(arg1));
		GetCmdArg(2, arg2, sizeof(arg2));
		
		decl String:target_name[MAX_TARGET_LENGTH];
		decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
		if((target_count = ProcessTargetString(
				arg1,
				client,
				target_list,
				MAXPLAYERS,
				COMMAND_FILTER_CONNECTED,
				target_name,
				sizeof(target_name),
				tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}
		
		if(args < 2) {
			PrintToChat(client, "%t", "Fix");
			return Plugin_Handled;
		}
		
		if(args == 2) {
			for(new i = 0; i < target_count; i++) {
				if(IsValidClient(target_list[i])) {
					startEffect(client, target_list[i], arg2);
				}
			}
		}
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

//removes the effect
public Action:RemoveEffect(client, args) {
	if(Enabled) {
		decl String:arg1[65];
		GetCmdArg(1, arg1, sizeof(arg1));
		
		decl String:target_name[MAX_TARGET_LENGTH];
		decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
		if((target_count = ProcessTargetString(
				arg1,
				client,
				target_list,
				MAXPLAYERS,
				COMMAND_FILTER_CONNECTED,
				target_name,
				sizeof(target_name),
				tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}
		
		if(args < 1) {
			PrintToChat(client, "%t", "Fix2");
			return Plugin_Handled;
		}
		
		if(args == 1) {
			for(new i = 0; i < target_count; i++) {
				if(IsValidClient(target_list[i])) {
					resetEffects(target_list[i]);
					CPrintToChat(client, "%t", "Clear");
				}
			}
		}
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

//finds the effect and enable it
public startEffect(client, target, const String:effect[]) {
	if(IsValidClient(target)) {
		if(IsPlayerAlive(target)) {
			if(activeEffect[target] == false) {
				if(StrEqual(effect, "minihp", false)) addMiniHealth(target, GetConVarInt(miniHP));
				else if(StrEqual(effect, "dance", false)) ForceTaunt(target);
				else if(StrEqual(effect, "knocker", false)) knockBackPlayer(target);
				else if(StrEqual(effect, "bighead", false)) resizeHeadBig(target);
				else if(StrEqual(effect, "smallhead", false)) resizeHeadSmall(target);
				else if(StrEqual(effect, "hyper", false)) SpeedMore(target);
				else if(StrEqual(effect, "camoflage", false)) toggleCamoflage(target);
				else if(StrEqual(effect, "funnyfeeling", false)) setFOV(target);
				else if(StrEqual(effect, "dracula", false)) draculaEnabled(target);
				else if(StrEqual(effect, "feather", false)) SetGravity(target, GetConVarFloat(featherTouch));
				else if(StrEqual(effect, "nostalgia", false)) SetNostalgia(target);
				else if(StrEqual(effect, "sentry", false)) toggleSentrySpawn(client);
				else if(StrEqual(effect, "onehp", false)) addOneHP(target);
				else if(StrEqual(effect, "braindead", false)) toggleBrainDead(target);
				else if(StrEqual(effect, "ballsofsteel", false)) toggleBallsOfSteel(target);
				else if(StrEqual(effect, "inverse", false)) toggleInverse(target);
				else if(StrEqual(effect, "blind", false)) toggleBlind(target);
				else if(StrEqual(effect, "dejavu", false)) toggleTeleport(client);
				else if(StrEqual(effect, "grenade", false)) giveNade(target);
				else if(StrEqual(effect, "earthquake", false)) shakePlayer(target);
				else if(StrEqual(effect, "snail", false)) toggleSlowdown(target);
				else if(StrEqual(effect, "toxic", false)) toggleToxic(target);
				else if(StrEqual(effect, "noob", false)) toggleNoob(target);
				else if(StrEqual(effect, "dispenser", false)) SpawnDispenser(target);
				else if(StrEqual(effect, "scary", false)) toggleScary(target);
				else if(StrEqual(effect, "incendiary", false)) toggleIncendiary(target);
				//else if(StrEqual(effect, "superjump", false)) toggleSuperjump(target);
				else {
					CPrintToChat(client, "%t", "ERROR");
				}
			}
			else {
				CPrintToChat(client, "%t", "Duplicate");
			}
		}
	}
}

//lists all effect names in console to be used with !seteffect
public Action:ListEffect(client, args) {
	if(Enabled) {
		if(IsValidClient(client)) {
			PrintToConsole(client, "%t", "List");
			PrintToChat(client, "%t", "List2");
		}
	}
	return Plugin_Handled;
}

//spawns a  gift at the player's cursor
public Action:SpawnGift(client, args) {
	if(Enabled) {
		if(IsValidClient(client)) {
			if(!SetTeleportEndPoint(client)) PrintToChat(client, "%t", "Spawn");
			g_pos[2] -= 10;
			createGift(client, g_pos, false);
		}
	}
	return Plugin_Handled;
}

public Action:Gift(client, args) {
	if(Enabled) {
		if(IsValidClient(client)) {
			CPrintToChat(client, "%t", "Collected", playerCookie[client]);
		}
	}
}

public Action:GiftHelp(client, args) {
	if(Enabled) {
		if(IsValidClient(client)) {
			new Handle:setup = CreateKeyValues("data");
			KvSetString(setup, "title", "Gift Info");
			KvSetNum(setup, "type", MOTDPANEL_TYPE_URL);
			KvSetString(setup, "msg", INFO);
			KvSetNum(setup, "customsvr", 1);
			ShowVGUIPanel(client, "info", setup, true);
			CloseHandle(setup);
		}
	}
}

//reset effects when player changes team
public Action:OnTeamChange(Handle:event, String:name[], bool:dontBroadcast) {
	if(Enabled) {
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		new team = GetEventInt(event, "team");
		if(IsValidClient(client)) {
			if(GetConVarInt(showAds) == 1) {
				if(playerAdCount[client] == 0) {
					if(team == 2 || team == 3) {
						playerAdCount[client]++;
						CPrintToChat(client, "%t", "Advertise");
					}
				}
			}
		}
	}
}

public TF2_OnWaitingForPlayersEnd() {
	for(new i = 1; i <= MaxClients; i++) {
		if(IsValidClient(i)) {
			resetEffects(i);
		}
	}
}

//prevents player from dropping gift during waiting setup time
public Action:OnRoundStart(Handle:event, String:name[], bool:dontBroadcast) {
	CreateTimer(10.0, setRoundTrue);
	for(new i = 1; i <= MaxClients; i++) {
		if(IsValidClient(i)) {
			resetEffects(i);
		}
	}
}

public Action:setRoundTrue(Handle:timer) {
	roundStart = true;
}

public Action:OnRoundEnd(Handle:event, String:name[], bool:dontBroadcast) {
	roundStart = false;
}

//called when a player dies...spawns a gift
public Action:OnPlayerDeath(Handle:event, String:name[], bool:dontBroadcast) {
	if(Enabled) {
		if(roundStart == true) {
			new client = GetClientOfUserId(GetEventInt(event, "userid"));
			new killer = GetClientOfUserId(GetEventInt(event, "attacker"));
			new deathflags = GetEventInt(event, "death_flags");
			if(IsValidClient(client)) {
				if(IsValidClient(killer)) {
					new bool:fakedeath = (deathflags == TF_DEATHFLAG_DEADRINGER);
					switch(fakedeath) {
						case true: {
							if(GetConVarInt(FakeGifts) == 1) {
								new Float:pos[3];
								GetClientAbsOrigin(client, pos);
								createGift(client, pos, true);
							}
						}
						case false: {
							if(GetRandomFloat(0.0, 1.0) <= GetConVarFloat(dropChance)) {
								if(GetConVarInt(Suicide) == 1 || GetConVarInt(Suicide) == 0 && client != killer) {
									new Float:pos[3];
									GetClientAbsOrigin(client, pos);
									createGift(client, pos, false);
								}
							}
						}
					}
				}
				resetEffects(client);
			}
		}
	}
}

public createGift(client, Float:pos[3], bool:isFake) {
	new ent = CreateEntityByName("item_ammopack_small");
	if(IsValidEntity(ent)) {
		//generate a random gift box model
		new gen;
		switch(GetConVarInt(modelBoxes)) {
			case 0: gen = 0;
			case 1: gen = 1;
			case 2: gen = GetRandomInt(0,1);
		}
		
		switch(gen) {
			case 0: {
				DispatchKeyValue(ent, "powerup_model", MDL);
				SetEntPropFloat(ent, Prop_Send, "m_flModelScale", GetConVarFloat(giftSize));
			}
			case 1: {
				DispatchKeyValue(ent, "powerup_model", MDL2);
				//makes sure it scales with the other model, not exact but its good enough
				SetEntPropFloat(ent, Prop_Send, "m_flModelScale", GetConVarFloat(giftSize)*0.70);
			}
		}

		TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR); 
		DispatchSpawn(ent); 
		ActivateEntity(ent);
		
		if(TE_SetupTFParticle(MDL_CONFETTI, pos, _, _, ent, 3, 0, false)) {
			TE_SendToAll(0.0);
		}
		
		EmitAmbientSound(SND_BRDY, pos);
		
		//so no one picks it up as ammo
		SetEntProp(ent, Prop_Send, "m_iTeamNum", 1, 4);

		if(GetConVarInt(CoolDown) > 0) {
			SetEntityRenderMode(ent, RENDER_TRANSALPHA);
			SetEntityRenderColor(ent, _, _, _, 100);
			switch(isFake) {
				case true: CreateTimer(GetConVarFloat(CoolDown), FakeTouchTimer, EntIndexToEntRef(ent));
				case false: CreateTimer(GetConVarFloat(CoolDown), StartTouchTimer, EntIndexToEntRef(ent));
			}
		}
		else {
			switch(isFake) {
				case true: SDKHook(ent, SDKHook_StartTouch, FakeTouch);
				case false: SDKHook(ent, SDKHook_StartTouch, StartTouch);
			}
		}
		PushArrayCell(arrayCell, EntIndexToEntRef(ent));
	}
}

public Action:StartTouchTimer(Handle:timer, any:entref) {
	new ent = EntRefToEntIndex(entref);
	if(IsValidEntity(ent)) {
		SDKHook(ent, SDKHook_StartTouch, StartTouch);
		SetEntityRenderMode(ent, RENDER_NORMAL);
		SetEntityRenderColor(ent, _, _, _, 255);
		CreateTimer(GetConVarFloat(dieTime), RemoveGift, EntIndexToEntRef(ent));
	}
}

public Action:FakeTouchTimer(Handle:timer, any:entref) { 
	new ent = EntRefToEntIndex(entref);
	if(IsValidEntity(ent)) {
		SDKHook(ent, SDKHook_StartTouch, FakeTouch);
		SetEntityRenderMode(ent, RENDER_NORMAL);
		SetEntityRenderColor(ent, _, _, _, 255);
		CreateTimer(GetConVarFloat(dieTime), RemoveGift, EntIndexToEntRef(ent));
	}
}

//remove gift when timer is done
public Action:RemoveGift(Handle:timer, any:entref) { 
	new ent = EntRefToEntIndex(entref); 
	if(IsValidEntity(ent)) {
		AcceptEntityInput(ent, "kill"); 
		new arrayIndex = FindValueInArray(arrayCell, entref);
		if(arrayIndex != -1) {
			RemoveFromArray(arrayCell, arrayIndex);
		}
	}
}

//this function is called and picks a random case as the random effect
public Action:StartTouch(entity, client) {
	if(Enabled) {
		if(IsValidClient(client)) {
			new getCvarTeam = GetConVarInt(teamMode);
			new getTeam = GetClientTeam(client);
			if(getCvarTeam == 1 || getCvarTeam == 2 && getTeam == 2 || getCvarTeam == 3 && getTeam == 3) {
				if(activeEffect[client] == false) {
					AcceptEntityInput(entity, "Kill");
					playerCookie[client]++;
					saveCookie(client);
					new goodCount, badCount, goodEffect, badEffect = 0;
					new bool:UpOrDown = false;
					switch(CheckAdminFlag(client)) {
						case true: {
							if(GetRandomFloat(0.0, 1.0) <= GetConVarFloat(adminChance)) {
								goodEffect = GetRandomInt(0, sizeof(g_goodName)-1);
								UpOrDown = true;
							}
							else {
								badEffect = GetRandomInt(0, sizeof(g_badName)-1);
								UpOrDown = false;
							}
						}
						case false: {
							if(GetRandomFloat(0.0, 1.0) <= GetConVarFloat(goodChance)) {
								goodEffect = GetRandomInt(0, sizeof(g_goodName)-1);
								UpOrDown = true;
							}
							else {
								badEffect = GetRandomInt(0, sizeof(g_badName)-1);
								UpOrDown = false;
							}
						}
					}
					switch(UpOrDown) {
						case true: {
							while(g_good[goodEffect] == 1) {
								goodEffect++;
								goodCount++;
								if(goodEffect == sizeof(g_goodName)) {
									goodEffect = 0;
								}
								if(goodCount == sizeof(g_goodName)) {
									goodEffect = sizeof(g_goodName);
								}
							}
							switch(goodEffect) {
								case 0: addMiniHealth(client, GetConVarInt(miniHP));
								case 1: knockBackPlayer(client);
								case 2: SpeedMore(client);
								case 3: toggleCamoflage(client);
								case 4: draculaEnabled(client);
								case 5: SetGravity(client, GetConVarFloat(featherTouch));
								case 6: toggleSentrySpawn(client);
								case 7: toggleBallsOfSteel(client);
								case 8: giveNade(client);
								case 9: toggleToxic(client);
								case 10: SpawnDispenser(client);
								case 11: toggleScary(client);
								case 12: toggleIncendiary(client);
								//case 15: toggleSuperjump(client);
								case 13: {
									//do nothing
								}
							}
						}
						case false: {
							while(g_bad[badEffect] == 1) {
								badEffect++;
								badCount++;
								if(badEffect == sizeof(g_badName)) {
									badEffect = 0;
								}
								if(badCount == sizeof(g_badName)) {
									badEffect = sizeof(g_badName);
								}
							}
							switch(badEffect) {
								case 0: ForceTaunt(client);
								case 1: setFOV(client);
								case 2: SetNostalgia(client);
								case 3: addOneHP(client);
								case 4: toggleBrainDead(client);
								case 5: toggleInverse(client);
								case 6: toggleBlind(client);
								case 7: toggleTeleport(client);
								case 8: shakePlayer(client);
								case 9: toggleSlowdown(client);
								case 10: toggleNoob(client);
								case 11: resizeHeadBig(client);
								case 12: resizeHeadSmall(client);
								case 13: {
									//do nothing
								}
							}
						}
					}
				}
			}
		}
	}
}

public Action:FakeTouch(entity, client) {
	if(Enabled) {
		if(IsValidClient(client)) {
			new getCvarTeam = GetConVarInt(teamMode);
			new getTeam = GetClientTeam(client);
			if(getCvarTeam == 1 || getCvarTeam == 2 && getTeam == 2 || getCvarTeam == 3 && getTeam == 3) {
				if(activeEffect[client] == false) {
					AcceptEntityInput(entity, "Kill");
					CPrintToChat(client, "%t", "Faked");
				}
			}
		}
	}
}

//sdkhook ontakedamage similar to onhurt event
public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3]) {
	if(Enabled) {
		if(IsValidClient(attacker) && IsValidClient(victim) && IsValidEntity(weapon)) {
			//This will cause the attacker to do a knockback slap on victim
			//Rockets/pipes does a higher jump
			switch(ability[attacker]) {
				case 3: {
					new Float:aang[3], Float:vvel[3], Float:pvec[3];
					GetClientAbsAngles(attacker, aang);
					GetEntPropVector(victim, Prop_Data, "m_vecVelocity", vvel);
					
					if (attacker == victim) {
						vvel[2] += 1000.0;
					} 
					else {
						GetAngleVectors(aang, pvec, NULL_VECTOR, NULL_VECTOR);
						vvel[0] += pvec[0] * 300.0;
						vvel[1] += pvec[1] * 300.0;
						vvel[2] = 500.0;
					}
					TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, vvel);
				}
				case 9: {
					new Float:healingdamage;
					if(damage > 300.0) {
						healingdamage = 300.0;
					}
					else if(damage > 0.0 && damage <= 300.0) {
						healingdamage = damage;
					}
					SetEntProp(attacker, Prop_Send, "m_iHealth", GetClientHealth(attacker) + RoundToNearest(healingdamage*GetConVarFloat(draculaHeal)));
				}
				case 25: TF2_StunPlayer(victim, 1.0, 0.0, TF_STUNFLAGS_GHOSTSCARE, 0);
			}
			switch(ability[victim]) {
				case 2: ForceTaunt(attacker);
				case 15: damage *= GetConVarFloat(ballsDefence);
			}
		}
	}
}

//hooks the listener to voice commands
public Action:VoiceListener(client, const String:command[], argc) {
	if(Enabled) {
		if(IsValidClient(client)) {
			decl String:arguments[32];
			GetCmdArgString(arguments, sizeof(arguments));
			//medic arguements is 0 0
			if(StrEqual(arguments, "0 0", false)) {
				switch(ability[client]) {
					case 12: {
						spawnSentry(client);
						resetAbility(client);
						return Plugin_Handled;
					}
					case 19: {
						if(NadeCounter[client] == 1) {
							ThrowNade(client);
							resetAbility(client);
							return Plugin_Handled;
						}
					}
					case 24: {
						spawnDispenser(client);
						resetAbility(client);
						return Plugin_Handled;
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

/* ----------------------------------------------------
	Stock functions effects used and is called by client methods
  -----------------------------------------------------
 */
	
//method that prints out chats stuff
stock PrintResponse(client, i) {
	switch(i) {
		case 1: CPrintToChat(client, "%t", "MiniHP", GetConVarInt(resetMiniCritsTimer));
		case 2: CPrintToChat(client, "%t", "DanceFever");
		case 3: CPrintToChat(client, "%t", "Knockers", GetConVarInt(resetKnockTimer));
		case 4: CPrintToChat(client, "%t", "BigHead", GetConVarInt(resetBHeadTimer));
		case 5: CPrintToChat(client, "%t", "SmallHead", GetConVarInt(resetSHeadTimer));
		case 6: CPrintToChat(client, "%t", "Hyper", GetConVarInt(resetSpeedTimer));
		case 7: CPrintToChat(client, "%t", "Camo", GetConVarInt(resetAlphaTimer));
		case 8: CPrintToChat(client, "%t", "Funny");
		case 9: CPrintToChat(client, "%t", "Dracula", GetConVarInt(resetDraculaTimer));
		case 10: CPrintToChat(client, "%t", "Feather", GetConVarInt(resetGravityTimer));
		case 11: CPrintToChat(client, "%t", "Nostalgia", GetConVarInt(resetNostalgiaTimer));
		case 12: CPrintToChat(client, "%t", "Sentry", GetConVarInt(resetSentryTimer));
		case 13: CPrintToChat(client, "%t", "OneHP");
		case 14: CPrintToChat(client, "%t", "BrainDead", GetConVarInt(resetBrainTimer));
		case 15: CPrintToChat(client, "%t", "BallsOfSteel", GetConVarInt(resetSteelTimer));
		case 16: CPrintToChat(client, "%t", "Inverse", GetConVarInt(resetInverseTimer));
		case 17: CPrintToChat(client, "%t", "Blind", GetConVarInt(resetBlindTimer));
		case 18: CPrintToChat(client, "%t", "Teleport");
		case 19: CPrintToChat(client, "%t", "Grenade");
		case 20: CPrintToChat(client, "%t", "Earthquake", GetConVarInt(resetShakeTimer));
		case 21: CPrintToChat(client, "%t", "Snail", GetConVarInt(resetSnailTimer));
		case 22: CPrintToChat(client, "%t", "Toxic", GetConVarInt(resetToxicTimer));
		case 23: CPrintToChat(client, "%t", "Noob", GetConVarInt(resetNoobTimer));
		case 24: CPrintToChat(client, "%t", "Dispenser");
		case 25: CPrintToChat(client, "%t", "Scary", GetConVarInt(resetScaryTimer));
		case 26: CPrintToChat(client, "%t", "Incendiary", GetConVarInt(resetIncendiaryTimer));
		//case 27: CPrintToChat(client, "%t", "Superjump", GetConVarInt(resetSuperjumpTimer));
	}
}

setAbility(client, abilityNum) {
	ability[client] = abilityNum;
	//addCond(client, 6, -1.0);
	activeEffect[client] = true;
	PrintResponse(client, abilityNum);
}

resetAbility(client) {
	ability[client] = 0;
	//removeCond(client, 6);
	activeEffect[client] = false;
	clientTimer[client] = INVALID_HANDLE;
}

 //This method is used to add health to the desired player and set up minicrits
addMiniHealth(client, health) {
	setAbility(client, 1);
	addCond(client, 31, -1.0);
	SetEntProp(client, Prop_Send, "m_iHealth", GetClientHealth(client) + health);
	clientTimer[client] = CreateTimer(GetConVarFloat(resetMiniCritsTimer), resetMiniCrits, GetClientUserId(client));
	countDown(client, GetConVarInt(resetMiniCritsTimer));
}

//resets minicrits when timer is called
public Action:resetMiniCrits(Handle:timer, any:userID) {
	new client = GetClientOfUserId(userID);
	if(IsValidClient(client)) {
		removeCond(client, 31);
		resetAbility(client);
	}
}

//This method is used to force a fake taunt command to player
ForceTaunt(client) {
	if(tauntcounter[client] == 0) {
		PrintResponse(client, 2);
		tauntcounter[client] = 1;
	}
	new bool: onGround = (GetEntityFlags(client) == FL_ONGROUND);
	switch(onGround) {
		case true: {
			FakeClientCommand(client, "taunt");
			ability[client] = 1;
			addCond(client, 6, -1.0);
		}
		case false: tauntTimer[client] = CreateTimer(0.1, tauntDetect, GetClientUserId(client));
	}
}

//call back timer for fake taunt method
//makes sure the players taunt when they land back down
public Action:tauntDetect(Handle:timer, any:userID) {
	new client = GetClientOfUserId(userID);
	if(IsValidClient(client)) {
		ForceTaunt(client);
		tauntTimer[client] = INVALID_HANDLE;
	}
}

//stock to enable knockback effect
stock knockBackPlayer(client) {
	setAbility(client, 3);
	clientTimer[client] = CreateTimer(GetConVarFloat(resetKnockTimer), resetKnockback, GetClientUserId(client));
	countDown(client, GetConVarInt(resetKnockTimer));
}

//resets the knockback after a few seconds with 
public Action:resetKnockback(Handle:timer, any:userID) {
	new client = GetClientOfUserId(userID);
	if(IsValidClient(client)) resetAbility(client);
}

//sets the player size head
stock resizeHeadBig(client) {
	setAbility(client, 4);
	AddAttribute(client, "head scale", 3.0);
	clientTimer[client] = CreateTimer(GetConVarFloat(resetBHeadTimer), resetBHead, GetClientUserId(client));
	countDown(client, GetConVarInt(resetBHeadTimer));
}

//timer resets big head
public Action:resetBHead(Handle:timer, any:userID) {
	new client = GetClientOfUserId(userID);
	if(IsValidClient(client)) {
		RemoveAttribute(client, "head scale");
		resetAbility(client);
	}
}

//sets the player size head
stock resizeHeadSmall(client) {
	setAbility(client, 5);
	AddAttribute(client, "head scale", 0.2);
	clientTimer[client] = CreateTimer(GetConVarFloat(resetSHeadTimer), resetSHead, GetClientUserId(client));
	countDown(client, GetConVarInt(resetSHeadTimer));
}

public Action:resetSHead(Handle:timer, any:userID) {
	new client = GetClientOfUserId(userID);
	if(IsValidClient(client)) {
		RemoveAttribute(client, "head scale");
		resetAbility(client);
	}
}

//sets the player speed
stock SpeedMore(client) {
	setAbility(client, 6);
	addCond(client, 32, -1.0);
	new Float:speed = GetEntPropFloat(client, Prop_Send, "m_flMaxspeed");
	AddAttribute(client, "move speed bonus", 520/speed);
	clientTimer[client] = CreateTimer(GetConVarFloat(resetSpeedTimer), resetSpeed, GetClientUserId(client));
	countDown(client, GetConVarInt(resetSpeedTimer));
}

//resets speed
public Action:resetSpeed(Handle:timer, any:userID) {
	new client = GetClientOfUserId(userID);
	if(IsValidClient(client)) {
		removeCond(client, 32);
		RemoveAttribute(client, "move speed bonus");
		resetAbility(client);
	}
}

toggleCamoflage(client) {
	setAbility(client, 7);
	setAlpha(client, GetConVarInt(alphaCamo));
	clientTimer[client] = CreateTimer(GetConVarFloat(resetAlphaTimer), resetAlpha, GetClientUserId(client));
	countDown(client, GetConVarInt(resetAlphaTimer));
}

//timer reset for alpha color
public Action:resetAlpha(Handle:timer, any:userID) {
	new client = GetClientOfUserId(userID);
	if(IsValidClient(client)) {
		removeAlpha(client, 255);
		resetAbility(client);
	}
}

//sets the FOB to the convar and creates another timer that normalizes it back to normal fov
stock setFOV(client) {
	setAbility(client, 8);
	SetEntProp(client, Prop_Send, "m_iFOV", GetConVarInt(funnyFeeling));
	clientTimer[client] = CreateTimer(0.5, normalize, GetClientUserId(client));
}

//normalize the FOV back to it's original state
public Action:normalize(Handle:timer, any:userID) {
	new client = GetClientOfUserId(userID);
	if(IsValidClient(client)) {
		if(ability[client] == 8) {
			new current = GetEntProp(client, Prop_Send, "m_iFOV");
			new exact = GetEntProp(client, Prop_Send, "m_iDefaultFOV");
			if(exact < current) {
				SetEntProp(client, Prop_Send, "m_iFOV", current - 1);
				clientTimer[client] = CreateTimer(0.5, normalize, GetClientUserId(client));
			}
			else if(exact > current) {
				SetEntProp(client, Prop_Send, "m_iFOV", current + 1);
				clientTimer[client] = CreateTimer(0.5, normalize, GetClientUserId(client));
			}
			else if(exact == current) {
				SetEntProp(client, Prop_Send, "m_iFOV", exact);
				resetAbility(client);
			}
		}
	}
}

//enables dracula's heart
stock draculaEnabled(client) {
	setAbility(client, 9);
	clientTimer[client] = CreateTimer(GetConVarFloat(resetDraculaTimer), resetDracula, GetClientUserId(client));
	countDown(client, GetConVarInt(resetDraculaTimer));
}

//timer callback to disable dracula effect when timer is done
public Action:resetDracula(Handle:timer, any:userID) {
	new client = GetClientOfUserId(userID);
	if(IsValidClient(client)) resetAbility(client);
}

//sets player gravity
stock SetGravity(client, Float:grav) {
	setAbility(client, 10);
	SetEntityGravity(client, grav);
	clientTimer[client] = CreateTimer(GetConVarFloat(resetGravityTimer), resetGravity, GetClientUserId(client));
	countDown(client, GetConVarInt(resetGravityTimer));
}

//resets gravity when timer is called
public Action:resetGravity(Handle:timer, any:userID) {
	new client = GetClientOfUserId(userID);
	if(IsValidClient(client)) {
		SetEntityGravity(client, 1.0);
		resetAbility(client);
	}
}

//sets nostalgia on player
stock SetNostalgia(client) {
	setOverlay("debug/yuv", client);
	setAbility(client, 11);
	clientTimer[client] = CreateTimer(GetConVarFloat(resetNostalgiaTimer), resetNostalgia, GetClientUserId(client));
	countDown(client, GetConVarInt(resetNostalgiaTimer));
}

//reset nostalgia effect when called
public Action:resetNostalgia(Handle:timer, any:userID) {
	new client = GetClientOfUserId(userID);
	if(IsValidClient(client)) {
		removeOverlay(client);
		resetAbility(client);
	}
}

//spawns a sentry gun
stock toggleSentrySpawn(client) {
	setAbility(client, 12);
}

//remove sentry after a few seconds
public Action:removeSentry(Handle:timer, any:userID) {
	new client = GetClientOfUserId(userID);
	if(IsValidClient(client)) {
		if(IsValidEntity(sentry[client])) {
			SetVariantInt(1000); 
			AcceptEntityInput(sentry[client], "RemoveHealth");
			resetAbility(client);
		}
	}
}

//sets client health to 1
stock addOneHP(client) {
	ability[client] = 13;
	PrintResponse(client, 13);
	SetEntProp(client, Prop_Send, "m_iHealth", 1);
}

//toggles the brain dead effect on client
stock toggleBrainDead(client) {
	setAbility(client, 14);
	addCond(client, 50, -1.0);
	TF2_StunPlayer(client, GetConVarFloat(resetBrainTimer), 0.0, TF_STUNFLAGS_NORMALBONK, 0);
	countDown(client, GetConVarInt(resetBrainTimer));
}

//for brain dead reset
public TF2_OnConditionRemoved(client, TFCond:condition) {
	if(Enabled) {
		if(IsValidClient(client)) {
			switch(ability[client]) {
				case 14: {
					removeCond(client, 50);
					resetAbility(client);
				}
				case 2: {
					if(condition == TFCond_Taunting) {
						tauntcounter[client] = 0;
						resetAbility(client);
					}
				}
			}
		}
	}
}

stock toggleBallsOfSteel(client) {
	setAbility(client, 15);
	new Float:speed = GetEntPropFloat(client, Prop_Send, "m_flMaxspeed");
	AddAttribute(client, "move speed bonus", speed*0.7);
	clientTimer[client] = CreateTimer(GetConVarFloat(resetSteelTimer), resetSteel, GetClientUserId(client));
	countDown(client, GetConVarInt(resetSteelTimer));
}

public Action:resetSteel(Handle:timer, any:userID) {
	new client = GetClientOfUserId(userID);
	if(IsValidClient(client)) {
		RemoveAttribute(client, "move speed bonus");
		resetAbility(client);
	}
}

stock toggleInverse(client) {
	setAbility(client, 16);
	Reverse(client);
	clientTimer[client] = CreateTimer(GetConVarFloat(resetInverseTimer), resetInverse, GetClientUserId(client));
	countDown(client, GetConVarInt(resetInverseTimer));
}

public Action:resetInverse(Handle:timer, any:userID) {
	new client = GetClientOfUserId(userID);
	if(IsValidClient(client)) {
		Reverse(client);
		resetAbility(client);
	}
}

stock toggleBlind(client) {
	setAbility(client, 17);
	BlindPlayer(client, GetConVarInt(blindEffect));
	clientTimer[client] = CreateTimer(GetConVarFloat(resetBlindTimer), resetBlind, GetClientUserId(client));
	countDown(client, GetConVarInt(resetBlindTimer));
}

public Action:resetBlind(Handle:timer, any:userID) {
	new client = GetClientOfUserId(userID);
	if(IsValidClient(client)) {
		BlindPlayer(client, 0);
		resetAbility(client);
	}
}

toggleTeleport(client) {
	ability[client] = 18;
	PrintResponse(client, 18);
	teleportToSpawn(client);
}

//gives a client a nade to throw at people :)
stock giveNade(client) {
	setAbility(client, 19);
	NadeCounter[client] = 1;
}

stock shakePlayer(client) {
	setAbility(client, 20);
	CreateTimer(0.25, repeatShake, GetClientUserId(client));
	clientTimer[client] = CreateTimer(GetConVarFloat(resetShakeTimer), resetShake, GetClientUserId(client));
	countDown(client, GetConVarInt(resetShakeTimer));
}

public Action:repeatShake(Handle:timer, any:userID) {
	new client = GetClientOfUserId(userID);
	if(IsValidClient(client)) {
		if(ability[client] == 20) {
			EarthQuakeEffect(client);
			CreateTimer(0.25, repeatShake, GetClientUserId(client));
		}
	}
}

public Action:resetShake(Handle:timer, any:userID) {
	new client = GetClientOfUserId(userID);
	if(IsValidClient(client)) resetAbility(client);
}

stock toggleSlowdown(client) {
	setAbility(client, 21);
	new Float:speed = GetEntPropFloat(client, Prop_Send, "m_flMaxspeed");
	AddAttribute(client, "move speed bonus", 30/speed);
	clientTimer[client] = CreateTimer(GetConVarFloat(resetSnailTimer), resetSnail, GetClientUserId(client));
	countDown(client, GetConVarInt(resetSnailTimer));
}

public Action:resetSnail(Handle:timer, any:userID) {
	new client = GetClientOfUserId(userID);
	if(IsValidClient(client)) {
		RemoveAttribute(client, "move speed bonus");
		resetAbility(client);
	}
}

stock toggleToxic(client) {
	setAbility(client, 22);
	addCond(client, 24, -1.0);
	CreateTimer(1.0, repeatToxic, GetClientUserId(client));
	clientTimer[client] = CreateTimer(GetConVarFloat(resetToxicTimer), resetToxic, GetClientUserId(client));
	countDown(client, GetConVarInt(resetToxicTimer));
}

public Action:repeatToxic(Handle:timer, any:userID) {
	new i = GetClientOfUserId(userID);
	if(IsValidClient(i)) {
		if(ability[i] == 22) {
			for(new j = 1; j <= MaxClients; j++) {
				if(i != j) {
					if(IsValidClient(j)) {
						new Float:ipos[3], Float:jpos[3];
						GetClientAbsOrigin(i, ipos);
						GetClientAbsOrigin(j, jpos);
						new Float:distance = GetVectorDistance(ipos, jpos);
						if(distance <= GetConVarInt(toxicRadius)) {
							SDKHooks_TakeDamage(j, 0, i, GetConVarFloat(toxicDamage), DMG_PREVENT_PHYSICS_FORCE|DMG_CRUSH|DMG_ALWAYSGIB);
						}
					}
				}
			}
			CreateTimer(1.0, repeatToxic, GetClientUserId(i));
		}
	}
}

public Action:resetToxic(Handle:timer, any:userID) {
	new client = GetClientOfUserId(userID);
	if(IsValidClient(client)) {
		removeCond(client, 24);
		resetAbility(client);
	}
}

stock toggleNoob(client) {
	setAbility(client, 23);
	SetEntityRenderColor(client, 0, 0, 0, _);
	SetEntProp(client, Prop_Send, "m_bGlowEnabled", 1);
	clientTimer[client] = CreateTimer(GetConVarFloat(resetNoobTimer), resetNoob, GetClientUserId(client));
	countDown(client, GetConVarInt(resetNoobTimer));
}

public Action:resetNoob(Handle:timer, any:userID) {
	new client = GetClientOfUserId(userID);
	if(IsValidClient(client)) {
		SetEntityRenderColor(client, 255, 255, 255, _);
		SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0);
		resetAbility(client);
	}
}

stock SpawnDispenser(client) {
	setAbility(client, 24);
}

stock toggleScary(client) {
	setAbility(client, 25);
	clientTimer[client] = CreateTimer(GetConVarFloat(resetScaryTimer), resetScary, GetClientUserId(client));
	countDown(client, GetConVarInt(resetScaryTimer));
}

public Action:resetScary(Handle:timer, any:userID) {
	new client = GetClientOfUserId(userID);
	if(IsValidClient(client)) resetAbility(client);
}

toggleIncendiary(client) {
	setAbility(client, 26);
	AddAttribute(client, "Set DamageType Ignite", 1.0);
	clientTimer[client] = CreateTimer(GetConVarFloat(resetIncendiaryTimer), resetIncendiary, GetClientUserId(client));
	countDown(client, GetConVarInt(resetIncendiaryTimer));
}

//resets minicrits when timer is called
public Action:resetIncendiary(Handle:timer, any:userID) {
	new client = GetClientOfUserId(userID);
	if(IsValidClient(client)) {
		RemoveAttribute(client, "Set DamageType Ignite");
		resetAbility(client);
	}
}

/*
stock toggleSuperjump(client) {
	addAttribute(client, "increased jump height", GetConVarFloat(jumpHeight));
	PrintResponse(client, 26);
	activeEffect[client] = true;
	addCond(client, 6, -1.0);
	countDown(client, GetConVarInt(resetSuperjumpTimer));
	clientTimer[client] = CreateTimer(GetConVarFloat(resetSuperjumpTimer), resetSuperjump, GetClientUserId(client));
}

public Action:resetSuperjump(Handle:timer, any:userID) {
	new client = GetClientOfUserId(userID);
	if(IsValidClient(client)) {
		removeAttribute(client, "increased jump height");
		removeCond(client, 6);
		activeEffect[client] = false;
		clientTimer[client] = INVALID_HANDLE;
	}
}*/


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
 //addCond method
stock addCond(client, condition, Float:duration) {
	if(IsValidClient(client)) {
		TF2_AddCondition(client, TFCond:condition, duration);
	}
}

//removecond method
stock removeCond(client, condition) {
	if(IsValidClient(client)) {
		TF2_RemoveCondition(client, TFCond:condition);
	}
}

//timer hinttext counter
//--------------------------------------------------------------------------------------------
stock countDown(client, time) {
	PrintHintText(client, "Duration: %d", time);
	StopSound(client, SNDCHAN_STATIC, "UI/hint.wav");
	g_timeLeft[client] = time;
	CreateTimer(1.0, Timer_Countdown, GetClientUserId(client));
}

public Action:Timer_Countdown(Handle:hTimer, any:userID) {
	new client = GetClientOfUserId(userID);
	if(IsValidClient(client)) {
		if(g_timeLeft[client] > 0 ) {
			g_timeLeft[client]--;
			PrintHintText(client, "Duration: %d", g_timeLeft[client]);
			//blocks the annoying tick sound
			StopSound(client, SNDCHAN_STATIC, "UI/hint.wav");
			CreateTimer(1.0, Timer_Countdown, GetClientUserId(client));
		}
		else {
			PrintHintText(client, "		");
			PrintHintText(client, "");
			StopSound(client, SNDCHAN_STATIC, "UI/hint.wav");
		}
		return Plugin_Continue;
	}
	return Plugin_Continue;
}

//--------------------------------------------------------------------------------------------

//emit sounds at the location
stock EmitSoundClient(String:sound[], client) {
	decl Float:pos[3];
	GetClientAbsOrigin(client, pos);
	EmitAmbientSound(sound, pos, client);
}

stock bool:TE_SetupTFParticle(String:Name[],
            Float:origin[3] = NULL_VECTOR,
            Float:start[3] = NULL_VECTOR,
            Float:angles[3] = NULL_VECTOR,
            entindex = -1,
            attachtype = -1,
            attachpoint = -1,
            bool:resetParticles = true) {
    new tblidx = FindStringTable("ParticleEffectNames");
    if (tblidx == INVALID_STRING_TABLE) {
        LogError("Could not find string table: ParticleEffectNames");
        return false;
    }
    // find particle index
    new String:tmp[256];
    new count = GetStringTableNumStrings(tblidx);
    new stridx = INVALID_STRING_INDEX;
    for (new i = 0; i < count; i++) {
        ReadStringTable(tblidx, i, tmp, sizeof(tmp));
        if (StrEqual(tmp, Name, false)) {
            stridx = i;
            break;
        }
    }
    if(stridx == INVALID_STRING_INDEX) {
        LogError("Could not find particle: %s", Name);
        return false;
    }
    TE_Start("TFParticleEffect");
    TE_WriteFloat("m_vecOrigin[0]", origin[0]);
    TE_WriteFloat("m_vecOrigin[1]", origin[1]);
    TE_WriteFloat("m_vecOrigin[2]", origin[2]);
    TE_WriteFloat("m_vecStart[0]", start[0]);
    TE_WriteFloat("m_vecStart[1]", start[1]);
    TE_WriteFloat("m_vecStart[2]", start[2]);
    TE_WriteVector("m_vecAngles", angles);
    TE_WriteNum("m_iParticleSystemIndex", stridx);
    if(entindex != -1) TE_WriteNum("entindex", entindex);
    if(attachtype != -1) TE_WriteNum("m_iAttachType", attachtype);
    if(attachpoint != -1) TE_WriteNum("m_iAttachmentPointIndex", attachpoint);
    TE_WriteNum("m_bResetParticles", resetParticles ? 1 : 0);
    return true;
}

//sets the overlay of a client
stock setOverlay(String:overlay[], client) {
	ClientCommand(client, "r_screenoverlay \"%s.vtf\"", overlay);
}

//remove the overlay from client
stock removeOverlay(client) {
	ClientCommand(client, "r_screenoverlay \"\"");
}

//spawn a sentry gun at the clients location
stock spawnSentry(client) {
	if(!SetTeleportEndPoint(client)) PrintToChat(client, "%t", "Spawn");
	new iLevel = GetConVarInt(sentryLevel);
	new iShells, iHealth, iRockets;
	switch (iLevel) {
		case 1: {
			iShells = 100;
			iHealth = 150;
		}
		case 2: {
			iShells = 120;
			iHealth = 180;
		}
		case 3: {
			iShells = 144;
			iHealth = 216;
			iRockets = 20;
		}
	}
	decl String:sShells[3],String:sHealth[3],String:sRockets[3],String:sLevel[3];
	IntToString(iShells, sShells, sizeof(sShells));
	IntToString(iHealth, sHealth, sizeof(sHealth));
	IntToString(iRockets, sRockets, sizeof(sRockets));
	IntToString(iLevel, sLevel, sizeof(sLevel));
	sentry[client] = CreateEntityByName("obj_sentrygun");
	if(IsValidEntity(sentry[client])) {
		if(GetClientTeam(client) == 3) {
			DispatchKeyValue(sentry[client], "TeamNum", "3");
		}
		else if(GetClientTeam(client) == 2) {
			DispatchKeyValue(sentry[client], "TeamNum", "2");
		}
		DispatchKeyValue(sentry[client], "m_iHealth", sHealth);
		DispatchKeyValue(sentry[client], "m_iAmmoShells", sShells);
		DispatchKeyValue(sentry[client], "m_iUpgradeLevel", sLevel);
		if(iLevel == 3) DispatchKeyValue(sentry[client], "m_iAmmoRockets", sRockets);
		g_pos[2] -= 10.0;
		TeleportEntity(sentry[client], g_pos, NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(sentry[client]);
		ActivateEntity(sentry[client]);
		SetEntPropEnt(sentry[client], Prop_Send, "m_hBuilder", client, 0);
		clientTimer[client] = CreateTimer(GetConVarFloat(resetSentryTimer), removeSentry, GetClientUserId(client));
	}
}

stock spawnDispenser(client) {
	if(!SetTeleportEndPoint(client)) PrintToChat(client, "%t", "Spawn");
	new String:strModel[100];
	decl String:name[60];
	GetClientName(client,name,sizeof(name));
	new iTeam = GetClientTeam(client);
	new iHealth;
	new iAmmo = 400;
	new iLevel = GetConVarInt(dLevel);
	switch(iLevel) {
		case 1:	{
			strcopy(strModel, sizeof(strModel), "models/buildables/dispenser.mdl");
			iHealth = 150;
		}
		case 2: {
			strcopy(strModel, sizeof(strModel), "models/buildables/dispenser_lvl2.mdl");
			iHealth = 180;
		}
		case 3:{
			strcopy(strModel, sizeof(strModel), "models/buildables/dispenser_lvl3.mdl");
			iHealth = 216;
		}
	}
	
	new iDispenser = CreateEntityByName("obj_dispenser");
	if(iDispenser > MaxClients && IsValidEntity(iDispenser)) {
		SetVariantInt(iTeam);
		AcceptEntityInput(iDispenser, "TeamNum");
		SetVariantInt(iTeam);
		AcceptEntityInput(iDispenser, "SetTeam");
		SetEntityModel(iDispenser, strModel);
		DispatchSpawn(iDispenser);
		TeleportEntity(iDispenser, g_pos, NULL_VECTOR, NULL_VECTOR);
		ActivateEntity(iDispenser);
		
		SetEntProp(iDispenser, Prop_Send, "m_iAmmoMetal", iAmmo);
		SetEntProp(iDispenser, Prop_Send, "m_iHealth", iHealth);
		SetEntProp(iDispenser, Prop_Send, "m_iMaxHealth", iHealth);
		SetEntProp(iDispenser, Prop_Send, "m_iObjectType", _:TFObject_Dispenser);
		SetEntProp(iDispenser, Prop_Send, "m_iTeamNum", iTeam);
		SetEntProp(iDispenser, Prop_Send, "m_nSkin", iTeam-2);
		SetEntProp(iDispenser, Prop_Send, "m_iHighestUpgradeLevel", iLevel);
		SetEntPropFloat(iDispenser, Prop_Send, "m_flPercentageConstructed", 1.0);
		SetEntPropEnt(iDispenser, Prop_Send, "m_hBuilder", client);		
	}
}

SetTeleportEndPoint(client) {
	decl Float:vAngles[3];
	decl Float:vOrigin[3];
	decl Float:vBuffer[3];
	decl Float:vStart[3];
	decl Float:Distance;
	
	GetClientEyePosition(client,vOrigin);
	GetClientEyeAngles(client, vAngles);
	
    //get endpoint for teleport
	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);

	if(TR_DidHit(trace)) {   	 
   	 	TR_GetEndPosition(vStart, trace);
		GetVectorDistance(vOrigin, vStart, false);
		Distance = -35.0;
   	 	GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
		g_pos[0] = vStart[0] + (vBuffer[0]*Distance);
		g_pos[1] = vStart[1] + (vBuffer[1]*Distance);
		g_pos[2] = vStart[2] + (vBuffer[2]*Distance);
	}
	else {
		CloseHandle(trace);
		return false;
	}
	CloseHandle(trace);
	return true;
}

public bool:TraceEntityFilterPlayer(entity, contentsMask) {
	return entity > GetMaxClients() || !entity;
}

//credit to rtd
stock BlindPlayer(client, iAmount) {
	new iTargets[2];
	iTargets[0] = client;
	new UserMsg:g_FadeUserMsgId = GetUserMessageId("Fade");
	new Handle:message = StartMessageEx(g_FadeUserMsgId, iTargets, 1);
	BfWriteShort(message, 1536);
	BfWriteShort(message, 1536);
	
	if(iAmount == 0) {
		BfWriteShort(message, (0x0001 | 0x0010));
	}
	else {
		BfWriteShort(message, (0x0002 | 0x0008));
	}
	
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	BfWriteByte(message, iAmount);
	
	EndMessage();
}

stock teleportToSpawn(client) {
	new Float:pos[3];
	new ent = -1;
	while((ent = FindEntityByClassname(ent, "info_player_teamspawn")) != -1) {
		if(!IsValidEntity(ent)) return;
		new disabled = GetEntProp(ent, Prop_Data, "m_bDisabled");
		if(!disabled) {
			new team = GetEntProp(ent, Prop_Data, "m_iTeamNum");
			if(team != GetClientTeam(client)) return;
			GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
			break;
		}
	}
	TeleportEntity(client, pos, NULL_VECTOR, NULL_VECTOR);
}

//Throws the nade at player
stock ThrowNade(client) {
	new nade = CreateEntityByName("prop_physics_override");
	if(IsValidEntity(nade)) {
		SetEntPropEnt(nade, Prop_Data, "m_hOwnerEntity", client);
		SetEntityMoveType(nade, MOVETYPE_VPHYSICS);
		SetEntProp(nade, Prop_Data, "m_CollisionGroup", 1);
		SetEntProp(nade, Prop_Send, "m_usSolidFlags", 16);
		SetEntPropFloat(nade, Prop_Data, "m_flFriction", 10000.0);
		SetEntPropFloat(nade, Prop_Data, "m_massScale", 100.0);
		DispatchKeyValue(nade, "targetname", "tf2nade@tak");
		SetEntityModel(nade, MDL_NADE);
		DispatchSpawn(nade);
		
		new Float:pos[3], Float:ang[3], Float:vec[3], Float:svec[3], Float:pvec[3];
		GetClientEyePosition(client, pos);
		GetClientEyeAngles(client, ang);
		
		ang[1] += 2.0;
		pos[2] -= 20.0;
		GetAngleVectors(ang, vec, svec, NULL_VECTOR);
		ScaleVector(vec, 500.0);
		ScaleVector(svec, 30.0);
		AddVectors(pos, svec, pos);
		GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", pvec);
		AddVectors(pvec, vec, vec);
		TeleportEntity(nade, pos, ang, vec);
		
		nadeEntity[client] = nade;
		CreateTimer(3.5, ExplodeNade, GetClientUserId(client));
	}
}

public Action:ExplodeNade(Handle:hTimer, any:userID) {
	new client = GetClientOfUserId(userID);
	if(IsValidClient(client)) {
		new explode = CreateEntityByName("env_explosion");
		if(IsValidEntity(explode)) {
			if(IsValidEntity(nadeEntity[client])) {
				DispatchKeyValue(explode, "targetname", "explode");	
				DispatchKeyValue(explode, "spawnflags", "2");
				DispatchKeyValue(explode, "rendermode", "5");
				DispatchKeyValue(explode, "fireballsprite", spirite);
				
				SetEntPropEnt(explode, Prop_Data, "m_hOwnerEntity", client);
				SetEntProp(explode, Prop_Data, "m_iMagnitude", GetConVarInt(nadeDamage));
				SetEntProp(explode, Prop_Data, "m_iRadiusOverride", 200);
				
				new Float:pos[3];
				GetEntPropVector(nadeEntity[client], Prop_Send, "m_vecOrigin", pos);
				TeleportEntity(explode, pos, NULL_VECTOR, NULL_VECTOR);
				DispatchSpawn(explode);
				ActivateEntity(explode);	
				AcceptEntityInput(explode, "Explode");
				AcceptEntityInput(explode, "Kill");
				AcceptEntityInput(nadeEntity[client], "Kill");
			}
		}
	}
}

stock Reverse(client) {
	new Float:ePos[3];
	if(isReversed[client]) {
		isReversed[client] = 0;
	}
	else {
		isReversed[client] = 1;
		GetClientEyeAngles(client, clientAngles[client]);
		GetClientEyePosition(client, ePos);
		new ent = CreateEntityByName("env_sprite");
		if(IsValidEntity(ent)) {
			DispatchKeyValue(ent, "model", "materials/sprites/dot.vmt");
			DispatchKeyValue(ent, "renderamt", "0");
			DispatchKeyValue(ent, "renderamt", "0");
			DispatchKeyValue(ent, "rendercolor", "0 0 0");
			DispatchSpawn(ent);
			TeleportEntity(client, NULL_VECTOR, Float:{0.0,0.0,0.0}, NULL_VECTOR);
			TeleportEntity(ent, ePos, Float:{0.0,0.0,0.0}, NULL_VECTOR);
			SetVariantString("!activator");
			AcceptEntityInput(ent, "SetParent", client, ent, 0);
			TeleportEntity(client, NULL_VECTOR, clientAngles[client], NULL_VECTOR);

			SetClientViewEntity(client, ent);
		}
		g_sEnt[client] = ent;
		inverseTimer[client] = CreateTimer(0.1, Timer_Roll, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:Timer_Roll(Handle:timer, any:userid) {
	new client = GetClientOfUserId(userid);
	if(IsValidEntity(g_sEnt[client])) {
		new Float:eAng[3];
		GetClientEyeAngles(client, g_Ang);
		//GetEntPropVector(g_sEnt[client], Prop_Send, "m_angRotation", eAng);
		if(isReversed[client]) {
			eAng[2] = 180.0;
			TeleportEntity(g_sEnt[client], NULL_VECTOR, eAng, NULL_VECTOR);
		}
		else {
			removeView(client);
			inverseTimer[client] = INVALID_HANDLE;
			return Plugin_Stop;
		}
	}
	return Plugin_Continue;
}

stock removeView(client) {
	if(IsValidEntity(g_sEnt[client])) {
		g_Ang[2] = 0.0;
		SetClientViewEntity(client, client);
		TeleportEntity(client, NULL_VECTOR, g_Ang, NULL_VECTOR);
		isReversed[client] = 0;
		AcceptEntityInput(g_sEnt[client], "Kill");//predeath setup
	}
}

//taken from rtd, credits to pheadxdll
stock EarthQuakeEffect(client) {
	new iFlags = GetCommandFlags("shake") & (~FCVAR_CHEAT);
	SetCommandFlags("shake", iFlags);
	FakeClientCommand(client, "shake");
	iFlags = GetCommandFlags("shake") | (FCVAR_CHEAT);
	SetCommandFlags("shake", iFlags);
}

//set the players alpha to a fade
stock setAlpha(client, alpha) {
	SetEntityRenderMode(client, RENDER_TRANSALPHA);
	SetEntityRenderColor(client, _, _, _, alpha);
	new hat = -1;
	while((hat = FindEntityByClassname(hat, "tf_wearable")) != -1) {
		if(IsValidEntity(hat)) {
			if(GetEntPropEnt(hat, Prop_Send, "m_hOwnerEntity") == client) {
				SetEntityRenderMode(hat, RENDER_TRANSALPHA);
				SetEntityRenderColor(hat, _, _, _, alpha);
			}
		}
	}
	for(new i = 0; i < 5; i++) {
		new weapon = GetPlayerWeaponSlot(client, i);
		if(weapon > MaxClients && IsValidEntity(weapon)) {
			SetEntityRenderMode(weapon, RENDER_TRANSALPHA);
			SetEntityRenderColor(weapon, _, _, _, alpha);
		}
	}
	new removeCan = -1;
	while((removeCan = FindEntityByClassname(removeCan, "tf_powerup_bottle")) != -1) {
		if(IsValidEntity(removeCan)) {
			if(GetEntPropEnt(removeCan, Prop_Send, "m_hOwnerEntity") == client) {
				SetEntityRenderMode(removeCan, RENDER_TRANSALPHA);
				SetEntityRenderColor(removeCan, _, _, _, alpha);
			}
		}
	}
}

//return alpha back to normal
stock removeAlpha(client, alpha) {
	SetEntityRenderMode(client, RENDER_NORMAL);
	SetEntityRenderColor(client, _, _, _, alpha);
	new hat = -1;
	while((hat = FindEntityByClassname(hat, "tf_wearable")) != -1) {
		if(IsValidEntity(hat)) {
			if(GetEntPropEnt(hat, Prop_Send, "m_hOwnerEntity") == client) {
				SetEntityRenderMode(hat, RENDER_NORMAL);
				SetEntityRenderColor(hat, _, _, _, alpha);
			}
		}
	}
	for(new i = 0; i < 5; i++) {
		new weapon = GetPlayerWeaponSlot(client, i);
		if(weapon > MaxClients && IsValidEntity(weapon)) {
			SetEntityRenderMode(weapon, RENDER_NORMAL);
			SetEntityRenderColor(weapon, _, _, _, alpha);
		}
	}
	new removeCan = -1;
	while((removeCan = FindEntityByClassname(removeCan, "tf_powerup_bottle")) != -1) {
		if(IsValidEntity(removeCan)) {
			if(GetEntPropEnt(removeCan, Prop_Send, "m_hOwnerEntity") == client) {
				SetEntityRenderMode(removeCan, RENDER_NORMAL);
				SetEntityRenderColor(removeCan, _, _, _, alpha);
			}
		}
	}
}
	
stock AddAttribute(client, String:attribute[], Float:value) {
	TF2Attrib_SetByName(client, attribute, value);
}

stock RemoveAttribute(client, String:attribute[]) {
	TF2Attrib_RemoveByName(client, attribute);
}

//resets the effects to prevent multiple effects at once and/or on death
stock resetEffects(client) {
	switch(ability[client]) {
		case 7: removeAlpha(client, 255);
		case 6: RemoveAttribute(client, "move speed bonus");
		case 15: RemoveAttribute(client, "move speed bonus");
		case 21: RemoveAttribute(client, "move speed bonus");
		case 8: SetEntProp(client, Prop_Send, "m_iFOV",  GetEntProp(client, Prop_Send, "m_iDefaultFOV"));
		case 10: SetEntityGravity(client, 1.0);
		case 11: removeOverlay(client);
		case 16: removeView(client);
		case 19: {
			NadeCounter[client] = 0;
			nadeEntity[client] = 0;
		}
		case 23: SetEntityRenderColor(client, 255, 255, 255, _);
		case 26: {
			RemoveAttribute(client, "Set DamageType Ignite");
		}
	}
	ClearTimer(clientTimer[client]);
	ClearTimer(inverseTimer[client]);
	ClearTimer(tauntTimer[client]);
	ability[client] = 0;
	activeEffect[client]  = false;
	removeCond(client, 32);
	g_timeLeft[client] = 0;
	//removeAttribute(client, "increased jump height");
}

stock ForceTimer(&Handle:timer) {
	if (timer != INVALID_HANDLE) { 
		TriggerTimer(timer);
	}
}

//taken and fixed from playpoints ability pack
stock LoadDisabledAbilities() {
	new String:disabled[258];
	GetConVarString(cvarDisabled, disabled, sizeof(disabled));
	for(new i = 0; i < sizeof(g_goodName); i++) {
		g_good[i] = 0;
		if(StrContains(disabled, g_goodName[i], false) != -1) {
			g_good[i] = 1;
		}
	}
	for(new i = 0; i < sizeof(g_badName); i++) {
		g_bad[i] = 0;
		if(StrContains(disabled, g_badName[i], false) != -1) {
			g_bad[i] = 1;
		}
	}
}

stock GetCookie(client) {
	if(IsValidClient(client)) {
		new String:cookie[PLATFORM_MAX_PATH];
		GetClientCookie(client, GiftCount, cookie, sizeof(cookie));
		playerCookie[client] = StringToInt(cookie);
	}
} 

stock saveCookie(client) {
	if(IsValidClient(client)) {
		new String:cookies[PLATFORM_MAX_PATH];
		IntToString(playerCookie[client], cookies, sizeof(cookies));
		SetClientCookie(client, GiftCount, cookies);
	}
}

stock ClearTimer(&Handle:timer) {  
	if(timer != INVALID_HANDLE) { 
		KillTimer(timer);  
	}  
	timer = INVALID_HANDLE;  
}  

//taken from rtd credit to pheadxdll
stock bool:CheckAdminFlag(client) {
	decl String:strCvar[20];
	strCvar[0] = '\0';
	GetConVarString(adminFlag, strCvar, sizeof(strCvar));
	if(strlen(strCvar) > 0) {
		if(GetUserFlagBits(client) & (ReadFlagString(strCvar) | ADMFLAG_ROOT)) {
			return true;
		}
	}
	return false;
}

//isvalidclient check to make sure the client is not invalid
stock bool:IsValidClient(iClient, bool:bReplay = true) {
	if(iClient <= 0 || iClient > MaxClients)
		return false;
	if(!IsClientInGame(iClient))
		return false;
	if(bReplay && (IsClientSourceTV(iClient) || IsClientReplay(iClient)))
		return false;
	return true;
}

/*For reference
ability[client] = 
1 - MiniCrits
2 - isTaunting
3 - knockBack
4 - headBig
5 - headSmall
6 - moreFast
7 - isAlpha
8 - FOV
9 - draculaHeart
10 - gravity
11 - Nostalgia
12 - sentrySpawn
13 - addonhp
14 - playerStunned
15 - playerSteel
16 - inverse
17 - blind
18 - teleport
19 - hasNade
20 - canShake
21 - snail
22 - toxicOn
23 - noob
24 - dispenserSpawn
25 - scarybullets
*/