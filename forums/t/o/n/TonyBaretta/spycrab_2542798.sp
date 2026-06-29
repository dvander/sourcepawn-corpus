#pragma semicolon 1
#include <steamtools>
#include <sourcemod>
#include <tf2_stocks>
#include <sdktools>
#include <sdkhooks>
#include <tf2items>
#include <tf2items_giveweapon>
#define PLUGIN_VERSION "2.0.2"


public Plugin:myinfo = {
	name		= "Crabmod",
	author		= "EnigmatiK,TonyBaretta",
	description = "RARE ENDANGERED SPYCRAB MURDER!",
	version		= PLUGIN_VERSION,
	url			= "http://www.wantedgov.it"
}

/*
RED: Snipers, Huntsman only
BLU: Spies, Disguise Kit only
*/

#define SOUND_DING 0
#define SOUND_ACHIEVED 1

#define SOUND_BEGIN 2
#define SOUND_STREAK 3
#define SOUND_EPICWIN 4
#define SOUND_LASTONE 5
#define SOUND_NOKILLS 6
#define SOUND_1STBLOOD 7
#define SOUND_EPICFAIL 8
#define SOUND_SCRAMBLE 9

#define SOUND_NOCRAB 10
#define SOUND_SPYDOM 11
#define SOUND_SPYJEER 12
#define SOUND_SPYLAUGH 13

#define SOUND_NEGVOCAL 14
#define SOUND_NICESHOT 15
#define SOUND_DOMINATOR 16

#define SOUND_COUNT 17
#define AMBIENT "ui/gamestartup11.mp3"
#define SOUNDEXCEPT_MUSIC 0

static const String:soundfiles[SOUND_COUNT][] = {
// misc
/* SOUND_DING */ "ui/scored.wav",
/* SOUND_ACHIEVED */ "misc/achievement_earned.wav",

// announcer
/* SOUND_BEGIN */ "vo/announcer_am_gamestarting04.mp3",
/* SOUND_STREAK */ "vo/announcer_am_killstreak02.mp3|vo/announcer_am_killstreak03.mp3|vo/announcer_am_killstreak04.mp3|vo/announcer_am_killstreak05.mp3|vo/announcer_am_killstreak06.mp3",
/* SOUND_EPICWIN */ "vo/announcer_am_flawlessvictory03.mp3|vo/announcer_am_flawlessvictory02.mp3",
/* SOUND_LASTONE */ "vo/announcer_am_lastmanalive01.mp3|vo/announcer_am_lastmanalive04.mp3",
/* SOUND_NOKILLS */ "vo/announcer_am_flawlessdefeat03.mp3|vo/announcer_am_flawlessdefeat04.mp3",
/* SOUND_1STBLOOD */ "vo/announcer_am_firstblood01.mp3|vo/announcer_am_firstblood02.mp3|vo/announcer_am_firstblood04.mp3|vo/announcer_am_firstblood05.mp3",
/* SOUND_EPICFAIL */ "vo/announcer_am_flawlessdefeat02.mp3",
/* SOUND_SCRAMBLE */ "vo/announcer_am_teamscramble02.mp3",

// spy
/* SOUND_NOCRAB */ "vo/spy_no01.mp3|vo/spy_no02.mp3|vo/spy_no03.mp3",
/* SOUND_SPYDOM */ "vo/spy_DominationSniper03.mp3|vo/spy_DominationSniper04.mp3|vo/spy_DominationSniper06.mp3|vo/spy_DominationSniper07.mp3",
/* SOUND_SPYJEER */ "vo/spy_jeers02.mp3|vo/spy_jeers03.mp3|vo/spy_jeers04.mp3|vo/spy_jeers05.mp3",
/* SOUND_SPYLAUGH */ "vo/spy_laughhappy01.mp3|vo/spy_laughhappy02.mp3|vo/spy_laughhappy03.mp3",

// sniper
/* SOUND_NEGVOCAL */ "vo/sniper_jeers01.mp3|vo/sniper_negativevocalization01.mp3|vo/sniper_negativevocalization02.mp3|vo/sniper_negativevocalization03.mp3",
/* SOUND_NICESHOT */ "vo/sniper_niceshot01.mp3|vo/sniper_niceshot02.mp3|vo/sniper_niceshot03.mp3",
/* SOUND_DOMINATOR */ "vo/sniper_laughlong01.mp3|vo/sniper_laughlong02.mp3"
};
static const soundlistsize[SOUND_COUNT] = {1, 1, 1, 5, 2, 2, 2, 4, 1, 1, 3, 4, 4, 4, 3, 3, 2};

new lastsniper[33];
new headshots[33];
new killcount[33];
new enabled = true;
new killed = false;
new win = false;
new player_crabduck[33];
new player_crablook[33];
new player_crabslot[33];
new Float:ang[3];

new bool:g_bSteamTools = false;

new Handle:enabled_cvar = INVALID_HANDLE;
new Handle:bufflastspy	= INVALID_HANDLE;
new Handle:checkmapname = INVALID_HANDLE;
new Handle:forceduck	= INVALID_HANDLE;
new Handle:forcelook	= INVALID_HANDLE;
new Handle:forcelookang = INVALID_HANDLE;
new Handle:forcelooktol = INVALID_HANDLE;
new Handle:friendlyfire = INVALID_HANDLE;
new Handle:g_Cvar_GameDescription = INVALID_HANDLE;
//new Handle:maxcrabspeed = INVALID_HANDLE;
new Handle:sniperratio	= INVALID_HANDLE;
new Handle:g_ClientTimers[MAXPLAYERS+1] = { INVALID_HANDLE, ...};
new bool:g_bGiveHuntsman;
new Handle:g_hGiveHuntsman = INVALID_HANDLE;




new offs_iClip;

new status;

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	MarkNativeAsOptional("Steam_SetGameDescription");
	return APLRes_Success;
}

public OnPluginStart() {
	// cvars
	

	g_Cvar_GameDescription = CreateConVar("crabmod_gamedescription", "1.0", "If SteamTools is loaded, set the Game Description to CrabMod2014?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	CreateConVar("crabmod2_version", PLUGIN_VERSION, "Crabmod game mode for TF2 by EnigmatiK.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	enabled_cvar = CreateConVar("crabmod_enabled", "1", "Enable/disable the Crabmod game mode.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	bufflastspy	 = CreateConVar("crabmod_bufflastspy", "1", "Grant an additional 120 health to the last living Spycrab.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	checkmapname = CreateConVar("crabmod_checkmapname", "1", "Disables Crabmod on maps that do not start with 'crab_'.", FCVAR_PLUGIN);
	forceduck	 = CreateConVar("crabmod_forceduck", "1", "Force Spycrabs to crouch.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	forcelook	 = CreateConVar("crabmod_forcelook", "2", "Force Spycrabs to look up; 1 restricts movement, 2 resets view.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	forcelookang = CreateConVar("crabmod_forcelookang", "35.0", "Spycrabs must look above this angle.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	forcelooktol = CreateConVar("crabmod_forcelooktol", "5.0", "Reset Spycrab view to this much above the crabmod_forcelookang angle.", FCVAR_PLUGIN);
	friendlyfire = CreateConVar("crabmod_friendlyfire", "1", "Sets mp_friendlyfire to 1 when Snipers win.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	//maxcrabspeed = CreateConVar("crabmod_maxcrabspeed", "100", "Maximum speed for Spycrabs.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	sniperratio	 = CreateConVar("crabmod_sniperratio", "3", "Ratio of number of all players per Sniper.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hGiveHuntsman = CreateConVar("crabmod_huntsman", "0", "1 for Enable huntsman , 0 for sniper rifle", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_bGiveHuntsman = GetConVarBool(g_hGiveHuntsman);
	SetConVarBounds(forcelookang, ConVarBound_Lower, true, 0.0);
	SetConVarBounds(forcelookang, ConVarBound_Upper, true, 89.0);
	SetConVarBounds(forcelooktol, ConVarBound_Lower, true, 0.0);
	SetConVarBounds(sniperratio, ConVarBound_Lower, true, 1.0);	
	AutoExecConfig(true, "CrabModv2");

	// hooks
	
	HookConVarChange(enabled_cvar, cvar_enabled);
	HookConVarChange(g_Cvar_GameDescription, Cvar_GameDescription);
	//HookEvent("player_team", player_team, EventHookMode_Pre);
	HookEvent("player_death", player_death);
	HookEvent("player_spawn", player_spawn);	
	HookEvent("teamplay_round_start", round_start, EventHookMode_PostNoCopy);
	HookEvent("teamplay_round_win", round_win);
	HookEvent("teamplay_setup_finished", setup_finished, EventHookMode_PostNoCopy);
	RegConsoleCmd("explode", cmd_kill);
	RegConsoleCmd("jointeam", cmd_jointeam);
	RegConsoleCmd("kill", cmd_kill);	
	PrecacheSound(AMBIENT);
	
	offs_iClip = FindSendPropInfo("CTFWeaponBase", "m_iClip10");
}
public OnAllPluginsLoaded()
{
	g_bSteamTools = LibraryExists("SteamTools");
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "SteamTools", false))
	{
		g_bSteamTools = true;
	}
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "SteamTools", false))
	{
		g_bSteamTools = false;
	}
}
public OnConfigsExecuted()
{	
		UpdateGameDescription(true);
}
public Cvar_GameDescription(Handle:convar, const String:oldValue[], const String:newValue[])
{
	UpdateGameDescription();
}
UpdateGameDescription(bool:bAddOnly=false)
{
	if (g_bSteamTools)
	{
		new String:gamemode[64];
		if (GetConVarBool(g_Cvar_GameDescription))
		{
			Format(gamemode, sizeof(gamemode), "CrabMod v.%s", PLUGIN_VERSION);
		}
		else if (bAddOnly)
		{
			
			return;
		}
		else
		{
			strcopy(gamemode, sizeof(gamemode), "Team Fortress");
		}
		Steam_SetGameDescription(gamemode);
	}
}
/**************
 * OnMapStart *
 **************/
public OnMapStart() {
	for (new i = 1; i <= MaxClients; i++) {
		if (isValid(i)) {
			SetEntProp(i, Prop_Send, "m_iHideHUD", 0);
			SetEntProp(i, Prop_Send, "m_bDrawViewmodel", 1);
		}
	}
	Precache();
	status = 2;
	enabled = GetConVarBool(enabled_cvar);
	// Check map name (if necessary).
	if (enabled && GetConVarBool(checkmapname)) {
		decl String:prefix[6];
		GetCurrentMap(prefix, sizeof(prefix));
		enabled = StrEqual(prefix, "crab_", false);
	}
	if (!enabled) return;
	ServerCommand("mp_autoteambalance 0");
	ServerCommand("tf_damage_disablespread 1");
	ServerCommand("mp_teams_unbalance_limit 0");
	SetConVarFloat(FindConVar("tf_spy_cloak_regen_rate"), 0.0, true);
	// FRIENDLY FIRE //
	new Handle:mp_friendlyfire = FindConVar("mp_friendlyfire");
	SetConVarFlags(mp_friendlyfire, GetConVarFlags(mp_friendlyfire) & (~FCVAR_NOTIFY));
	
}
public OnMapEnd()
{
	ServerCommand("crabmod_gamedescription 0.0");
	for (new i = 1; i <= MaxClients; i++) {
		if (isValid(i)) {
			SetEntProp(i, Prop_Send, "m_iHideHUD", 0);
			SetEntProp(i, Prop_Send, "m_bDrawViewmodel", 1);
		}
	}
}

/***********************
 * OnClientPutInServer *
 ***********************/
public OnClientPutInServer(client) {
	if (!enabled) return;
	lastsniper[client] = 1;
	PrintToChat(client, "\x01This Server run \x03CrabMod2014 %s \x01 by\x03 EnigmatiK\x01,\x03TonyBaretta ", PLUGIN_VERSION);
	
}
/************
 * Commands *
 ************/
public Action:cmd_jointeam(client, args) {
	if (!enabled) return Plugin_Continue;
	decl String:team[9];
	GetCmdArg(1, team, sizeof(team));
	if (StrEqual(team, "spectate")) return Plugin_Continue;
	if (GetClientTeam(client) > 1) {
		PrintToChat(client, "Teamswitching is not allowed.");
		return Plugin_Handled;
	} else {
		if (status < 1) {
			if (!GetClientTeam(client)) {
				CreateTimer(0.2, timer_makespy, client);
			} else {
				PrintToChat(client, "\x03Joining in the middle of a round is disabled.");
				PrintToChat(client, "\x03Please wait until the round ends before joining.");
				PrintCenterText(client, "Please wait until the round ends before joining.");
			}
			return Plugin_Handled;
		} else {
			lastsniper[client] = 1;
			return Plugin_Continue;
		}
	}
}

public Action:cmd_kill(client, args) {
	return (!enabled || status == 2) ? Plugin_Continue : Plugin_Handled;
}



/***********
 * ConVars *
 ***********/
public cvar_enabled(Handle:convar, const String:oldValue[], const String:newValue[]) {
	enabled &= (StringToInt(newValue) & 1);
}



/*******************
 * Sound Functions *
 *******************/
Precache() {
	// This is simple but incredibly inefficient.
	for (new i = 0; i < SOUND_COUNT; i++) {
		if (StrContains(soundfiles[i], "|")) {
			new String:files[5][64]; // Luckily, this function isn't called too often.
			ExplodeString(soundfiles[i], "|", files, 5, 64);
			for (new j = 0; j < 5; j++) if (strlen(files[j])) PrecacheSound(files[j], true);
		} else {
			PrecacheSound(soundfiles[i], true);
		}
	}
}

play_sound(client, type) {
	new size = soundlistsize[type];
	decl String:list[size][64];
	ExplodeString(soundfiles[type], "|", list, size, 64);
	if (type == SOUND_DING)
		EmitSoundToClient(client, list[GetRandomInt(0, size - 1)], _, _, SNDLEVEL_HOME);
	else
		EmitSoundToClient(client, list[GetRandomInt(0, size - 1)]);
}

play_sound_delay(Float:time, client, type) {
	new Handle:data = CreateDataPack();
	CreateDataTimer(time, timer_playsound, data);
	WritePackCell(data, client);
	WritePackCell(data, type);
}
public Action:timer_playsound(Handle:timer, Handle:data) {
	ResetPack(data);
	new client = ReadPackCell(data);
	if (isValid(client)) play_sound(client, ReadPackCell(data));
}

public Action:timer_playsniperlaugh(Handle:timer, any:client) {
	if (isValid(client)) {
		decl String:path[26];
		Format(path, sizeof(path), "vo/sniper_laughlong0%d.mp3", GetRandomInt(1, 2));
		EmitSoundToAll(path, client);
		EmitSoundToAll(path, client);
	}
}

play_sound_to_all(String:type) {
	for (new i = 1; i <= MaxClients; i++) if (isValid(i)) play_sound(i, type);
}



/***************
 * OnGameFrame *
 ***************/
public OnGameFrame() {
	if (!enabled) return;
	// Variable initialization.
	new Float:min = GetConVarFloat(forcelookang) * -1;
	decl String:weapon[18];
	new duck, look, slot;

	// Loop through all players.
	for (new i = 1; i <= MaxClients; i++) {
		if (isPlaying(i) && IsPlayerAlive(i) && !IsFakeClient(i)) {
			if (TFClassType:TF2_GetPlayerClass(i) == TFClass_Spy) {
				// Remove cloak and disguise.				
				if (status < 2) {					
					TF2_RemovePlayerDisguise(i);
					new cond = GetEntProp(i, Prop_Send, "m_nPlayerCond");					 
					if((cond & 16))
					{
						g_ClientTimers[i] = CreateTimer(1.5, OneSec, i);	
					}					
					
				}

				// Check duck, look, & slot.
				if (status == 1) {
					duck = (!GetConVarBool(forceduck) || (GetEntData(i, FindSendPropOffs("CTFPlayer", "m_fFlags")) & 2));
					look = true;
					GetClientWeapon(i, weapon, sizeof(weapon));
					slot = StrEqual(weapon, "tf_weapon_pda_spy");
					if (GetConVarBool(forcelook)) {
						GetClientEyeAngles(i, ang);
						if (GetConVarInt(forcelook) == 1) {
							look = (ang[0] < -1 * GetConVarFloat(forcelookang)); // if false, freeze
						} else if (ang[0] > min) {
							ang[0] = min - GetConVarFloat(forcelooktol);
							TeleportEntity(i, NULL_VECTOR, ang, NULL_VECTOR);
						}
					}
					if (duck != player_crabduck[i] || look != player_crablook[i] || slot != player_crabslot[i]) {
						if (GetEntityMoveType(i) == MOVETYPE_WALK) {
							PrintHintText(i, "Spycrabs must CROUCH and LOOK UP with the disguise kit!");
							play_sound(i, SOUND_NOCRAB);
						}
						SetEntityMoveType(i, (duck && look && slot) ? MOVETYPE_WALK : MOVETYPE_NONE);
						player_crabduck[i] = duck;
						player_crablook[i] = look;
						player_crabslot[i] = slot;
					}
				}
			}
		}
	}
}



/****************
 * player_death *
 ****************/
public player_death(Handle:event, const String:name[], bool:dontBroadcast) {
	if (!enabled || status != 1) return;
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!client) return; // Error-checking
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	if (GetClientTeam(client) == 3 && attacker) { // Spy died.
		if (!killed)
		{		
			if(	 GetEventInt( event, "death_flags" ) & TF_DEATHFLAG_DEADRINGER )		
			return;		
		
		}else{
			killed = true;
			play_sound_to_all(SOUND_1STBLOOD);
			play_sound_delay(3.5, client, SOUND_SPYJEER);
		}
		new alive = -1, i;
		for (i = 1; i <= MaxClients; i++)if (isValid(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i)) alive++;
		if (!alive) { // Last spycrab, so it's a win.
				win = true;
		} else {
			CreateTimer(3.0, timer_makesniper, client); // Turn into a Sniper.
			if (alive == 1) { // Play sound to last one alive.
				for (i = 1; i <= MaxClients; i++) {
					if (isValid(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i) && i != client) {
						if (GetConVarBool(bufflastspy)) SetEntityHealth(i, GetClientHealth(i) + 120); // health buff
						play_sound(i, SOUND_LASTONE); // "Your friends are all dead... Good luck!"
						break;
					}
				}
			}
		}
		if (isValid(client)) {
			SetEntProp(client, Prop_Send, "m_iHideHUD", 0);
			SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
		}
	}
		// Sniper stuff.
	if (attacker && isPlaying(attacker) && attacker != client) {
		if (GetEventInt(event, "customkill") == 1) {
			play_sound_delay(0.3, attacker, SOUND_NICESHOT); // "Good shot, mate!"
			headshots[attacker]++;
		}
		play_sound(attacker, SOUND_DING);
			
		killcount[attacker]++;
	}
}



/****************
 * player_spawn *
 ****************/
public player_spawn(Handle:event, const String:name[], bool:dontBroadcast) {
	if (!enabled) return;

	// Error-checking
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!client) return;
	new TFClassType:class = TF2_GetPlayerClass(client);
	if (class == TFClass_Unknown) return;

	// Do stuff
	new team = GetClientTeam(client);
	new TFClassType:designated = (team == 2 ? TFClass_Sniper : TFClass_Spy);
	if (class != designated) {
		TF2_SetPlayerClass(client, designated, false, true);
		TF2_RespawnPlayer(client);
		return;
	}
	if (team == 3) {
		SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 0); // Hide the view model.
		//SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", GetConVarFloat(maxcrabspeed) / 100);
	} else {
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
	}
	CreateTimer(1.0, timer_stripweapons, client);
}


/***************
 * round_start *
 ***************/
public round_start(Handle:event, const String:name[], bool:dontBroadcast) {
	// 0: Change some variables.
	status = 0;	
	killed = false;
	win = false;
	g_bGiveHuntsman = GetConVarBool(g_hGiveHuntsman);
	if (!enabled) return;

	// FRIENDLY FIRE //
	SetConVarBool(FindConVar("mp_friendlyfire"), false);

	// 1: Disable resupply lockers (if necessary) and modify tf_gamerules.
	new index = -1;
	while ((index = FindEntityByClassname(index, "func_regenerate")) != -1) AcceptEntityInput(index, "Disable");

	index = FindEntityByClassname(index, "tf_gamerules");
	if (index == -1) index = CreateEntityByName("tf_gamerules");
	SetVariantString("Snipe the crabspies with your Huntsman! If you do not have the Huntsman equipped, you may use Jarate.");
	AcceptEntityInput(index, "SetRedTeamGoalString");
	SetVariantString("Crabspy your way to the end! To crabspy, you must CROUCH and LOOK UP with your disguise kit out.");
	AcceptEntityInput(index, "SetBlueTeamGoalString");	

	// 2: Scramble teams.
	new count = GetTeamClientCount(2) + GetTeamClientCount(3);
	if (!count) return; // If nobody's playing, it doesn't matter.
	play_sound_to_all(SOUND_SCRAMBLE); // Teams are being scrambled!
	new playerlist[MaxClients], i;
	if (count > 1) { // If there's more than one player, ...
		new snipers = RoundToCeil(float(count) / GetConVarFloat(sniperratio));
		// Calculate total weight.
		new weight = 0, reset = 0, id = 0;
		for (i = 1; i <= MaxClients; i++) {
			if (isPlaying(i)) {
				weight += lastsniper[i];
				playerlist[id++] = i;
				// While we're here, reset headshots and killcount.
				headshots[i] = 0;
				killcount[i] = 0;
			}
		}
		// If there are no weights, set everyone's to 1.
		if (!weight) {
			for (i = 0; i < id; i++) lastsniper[playerlist[i]] = 1;
			weight = id;
			reset = 1;
		}
		// Populate weighted array.
		new Float:players[MaxClients + 1], player; // God damn it. Why must player indices start with 1!?
		for (i = 0; i < id; i++) {
			player = playerlist[i];
			PrintToChat(player, "your sniper chance: %d/%d (%.2f)", lastsniper[player], weight, float(lastsniper[player]) / weight);
			new Float:rand = GetRandomFloat();
			players[player] = (weight && rand ? float(lastsniper[player]) / weight / rand : 0.0);
			if (!reset) lastsniper[player]++;
		}
		// Pick Snipers.
		new Float:max, chosen[snipers];
		id = 0;
		do {
			max = 0.0;
			for (i = 1; i <= MaxClients; i++) {
				if (players[i] > max) {
					max = players[i];
					player = i;
				}
			}
			setTeam(player, 2);
			// Reset vars.
			lastsniper[player] = 0;
			players[player] = 0.0;
			chosen[id++] = player;
		} while (--snipers);
		// 2: Set everyone else to Spy.
		for (i = 1; i <= MaxClients; i++) {
			if (!isPlaying(i) || !lastsniper[i]) continue;
			// Not a Sniper, so...
			setTeam(i, 3);
			//SetEntDataFloat(i, FindSendPropOffs("CTFPlayer", "m_flMaxspeed"), 400.0);
		}
	} else { // If there's only one player, limit him to Spy.
		for (i = 1; i <= MaxClients; i++) {
			if (isPlaying(i)) {
				setTeam(i, 3);
				break;
			}
		}
	}
}



/*************
 * round_win *
 *************/
public round_win(Handle:event, const String:name[], bool:dontBroadcast) {
	status = 2;	
	if (!enabled) return;

	new i;
	if (GetEventInt(event, "team") == 3) { // SPIES WIN
		new wpn, fail, count = 0;
		for (i = 1; i <= MaxClients; i++) if (isValid(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i)) count++;
		fail = (!killed || count == 1);
		for (i = 1; i <= MaxClients; i++) {
			if (isPlaying(i) && IsPlayerAlive(i)) {
				if (GetClientTeam(i) == 3) { // Oh my God you're a SPY!
					// Give back HUD, viewmodel, and movement.
					SetEntProp(i, Prop_Send, "m_iHideHUD", 0);
					SetEntProp(i, Prop_Send, "m_bDrawViewmodel", 1);
					if (GetEntityMoveType(i) == MOVETYPE_NONE) SetEntityMoveType(i, MOVETYPE_WALK);
					// Give back weapons.
					wpn = TF2Items_GiveWeapon(i, 161);
					EquipPlayerWeapon(i, wpn);
					// Give cloak.
					SetEntPropFloat(i, Prop_Send, "m_flCloakMeter", 100.0);
					// If they failed, play a sound.
					if (fail) {
						if (GetRandomInt(0, 3)) { // 75% chance of spy laugh
							play_sound_delay(0.8, i, SOUND_SPYLAUGH);
						} else { // 25% of domination sound
							play_sound_delay(0.8, i, SOUND_SPYDOM);
						}
					}
				} else {
					if (fail) { // Sniper who failed.
						play_sound_delay(1.3, i, SOUND_EPICFAIL); // "Humiliating defeat!"
						if (!lastsniper[i] && !killcount[i]) play_sound_delay(7.0, i, SOUND_NOKILLS); // "You didn't kill any of them!"
					} else {
						play_sound_delay(1.5, i, SOUND_NEGVOCAL);
					}
				}
				
			}
		}
	} else if (GetEventInt(event, "team") == 2) { // SNIPERS WIN
		// FRIENDLY FIRE
		if (GetConVarBool(friendlyfire)) SetConVarBool(FindConVar("mp_friendlyfire"), true);
		// Okay, moving on...
		new players = GetTeamClientCount(2) + GetTeamClientCount(3);
		if (players < RoundToCeil(GetConVarFloat(sniperratio))) return; // Minimum amount of players to get Crazed Huntsman.
		// Loop through all players and pick the one who killed the most.
		// While we're here, get information for score verifications.
		new dominator = 0, max = 0, score, scores[MaxClients];
		for (i = 1; i <= MaxClients; i++) {
			score = killcount[i] + 2 * RoundToFloor(float(headshots[i]) / 2);
			scores[i - 1] = score;
			if (score > max) {
				dominator = i;
				max = score;
			}
		}
		// If this person is valid...
		if (dominator && isPlaying(dominator) && IsPlayerAlive(dominator)) {
			new snipers = RoundToCeil(float(players) / GetConVarFloat(sniperratio));
			SortIntegers(scores, MaxClients, Sort_Descending);
			if (scores[0] < 5) return; // Check if he has at least 5 points.
			if (scores[1] && scores[0] < scores[1] + snipers) return; // Check if he killed all or has (snipers) more points than second highest.
			// This guy is a crazed huntsman!
			new particle = CreateEntityByName("info_particle_system");
			if (IsValidEdict(particle)) {
				// Make him invulnerable.
				SetEntProp(dominator, Prop_Data, "m_takedamage", 0, 1);
				// Send colored message.
				decl String:message[64];
				Format(message, sizeof(message), "\x03%N\x01 is a\x05 Crazed Sniper\x01!", dominator);
				new Handle:buffer = StartMessageAll("SayText2");
				if (buffer != INVALID_HANDLE) {
					BfWriteByte(buffer, dominator);
					BfWriteByte(buffer, true);
					BfWriteString(buffer, message);
					EndMessage();
				}
				// Make the achievement sprite.
				decl String:target[128];
				new Float:pos[3];
				GetEntPropVector(dominator, Prop_Send, "m_vecOrigin", pos);
				TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
				Format(target, sizeof(target), "target%i", dominator);
				DispatchKeyValue(dominator, "targetname", target);
				DispatchKeyValue(particle, "targetname", "tf2particle");
				DispatchKeyValue(particle, "parentname", target);
				DispatchKeyValue(particle, "effect_name", "achieved");
				DispatchSpawn(particle);
				SetVariantString(target);
				AcceptEntityInput(particle, "SetParent");
				SetVariantString("head");
				AcceptEntityInput(particle, "SetParentAttachment");
				ActivateEntity(particle);
				AcceptEntityInput(particle, "start");
				SetVariantString("OnUser1 !self:kill:0:5:1");
				AcceptEntityInput(particle, "AddOutput");
				AcceptEntityInput(particle, "FireUser1");
				// Play sounds.
				EmitSoundToAll("misc/achievement_earned.wav");
				CreateTimer(1.5, timer_playsniperlaugh, dominator);
				play_sound_delay(3.5, dominator, SOUND_STREAK);
			}
		}		
	}
}



/******************
 * setup_finished *
 ******************/
public setup_finished(Handle:event, const String:name[], bool:dontBroadcast) {
	status = 1; // Let's play!
	if (!enabled) return;	

	for (new i = 1; i <= MaxClients; i++) {
		if (isValid(i)) {
			play_sound(i, SOUND_BEGIN); // "Let the games begin!"
			if (GetClientTeam(i) == 3) {
				SetEntProp(i, Prop_Send, "m_iHideHUD", 0);			
				player_crabduck[i] = true;
				player_crablook[i] = true;
				player_crabslot[i] = true;				
			}
		}
	}
	CreateTimer(1.0, timer_checkwin, _, TIMER_REPEAT);
}



/**********
 * Timers *
 **********/
// Check if Snipers are winrar.
public Action:timer_checkwin(Handle:timer) {
	if (!enabled || status != 1) return Plugin_Stop;
	new RED = GetTeamClientCount(2);
	new BLU = GetTeamClientCount(3);
	if (!RED && !BLU) return Plugin_Stop;
	if (RED + BLU > 1) {
		if ((!RED && BLU) || !BLU || win) {
			new ent = CreateEntityByName("game_round_win");
			DispatchKeyValue(ent, "force_map_reset", "1");
			DispatchSpawn(ent);
			if (!BLU || win) {
				SetVariantInt(2);
				AcceptEntityInput(ent, "SetTeam");
			}
			AcceptEntityInput(ent, "RoundWin");
			AcceptEntityInput(ent, "Kill");
			win = false;
			return Plugin_Stop;
		}
	}
	return Plugin_Continue;	
}

// You're one of THEM, now.
public Action:timer_makesniper(Handle:timer, any:client) {
	if (!enabled || !isPlaying(client) || status != 1) return;
	setTeam(client, 2);
}

// This should only be called on newcomers.
public Action:timer_makespy(Handle:timer, any:client) {
	if (!enabled || !isValid(client) || GetClientTeam(client) == 3) return;
	setTeam(client, 3);
}

// Restrict weapons.
public Action:timer_stripweapons(Handle:timer, any:client) {
	if (!enabled) return Plugin_Continue;
	if (isValid(client) && !IsClientObserver(client)) {
		new TFClassType:class = TF2_GetPlayerClass(client);
		if (class == TFClass_Sniper) {
			TF2_RemoveWeaponSlot(client, 0);
			TF2_RemoveWeaponSlot(client, 1);
			if(!g_bGiveHuntsman){
				TF2Items_GiveWeapon(client, 14);
			}
			if(g_bGiveHuntsman){
				TF2Items_GiveWeapon(client, 56);
			}
			TF2Items_GiveWeapon(client, 58);
			new weapon = GetPlayerWeaponSlot(client, 1);
			if (weapon == -1 || GetEntProp(weapon, Prop_Send, "m_iEntityLevel") == 5) { // tf_weapon_sniperrifle equipped								
				TF2Items_GiveWeapon(client, 58);

			} else {				
				TF2_RemoveWeaponSlot(client, 1);
				TF2Items_GiveWeapon(client, 58);
				SetEntData(weapon, offs_iClip, 1);
			}
		} else if (class == TFClass_Spy) {
			TF2_RemoveWeaponSlot(client, 4);
			setSlot(client, 3);
			SetEntProp(client, Prop_Send, "m_iHideHUD", 0);
			SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
			//setCloakValueRegen(client);			
			TF2Items_GiveWeapon(client, 59);
			TF2Items_GiveWeapon(client, 27);
			//setCloakValueDeath(client);	
			setSlot(client, 3);	
			PrintCenterText(client, "PRESS MOUSE2 FOR EQUIP THE DEAD RINGER !");
			TF2_RemoveWeaponSlot(client, 0);
			TF2_RemoveWeaponSlot(client, 1);
			TF2_RemoveWeaponSlot(client, 2);
			TF2_RemovePlayerDisguise(client);
		}
	}
	return Plugin_Handled;
}

// SPYCRABS ONLY.
public Action:timer_forcecrab(Handle:timer) {
	if (!enabled || status == 2) return Plugin_Stop;
	for (new i = 1; i <= MaxClients; i++) {
		if (isValid(i) && IsPlayerAlive(i) && GetClientTeam(i) == 3) {
			if (!player_crabslot[i]) {
				ClientCommand(i, "slot4");
			}
		}
	}
	return Plugin_Continue;
}
/*******************
 * Misc. Functions *
 *******************/
isValid(client) { // Valid player check.
	return (IsValidEntity(client) && IsClientInGame(client));
}

isPlaying(client) {
	return (isValid(client) && GetClientTeam(client) > 1);
}

setSlot(client, slot) {
	SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GetPlayerWeaponSlot(client, slot));
}

setTeam(client, team) {
	if (!isValid(client)) return;
	if (team > 1) {
		SetEntProp(client, Prop_Send, "m_lifeState", 2); // Mark dead.
		ChangeClientTeam(client, team); // Switch team.
		TF2_SetPlayerClass(client, (team == 2 ? TFClass_Sniper : TFClass_Spy), false, true); // Switch class.
		TF2_RespawnPlayer(client); // Respawn.
		SetEntProp(client, Prop_Send, "m_lifeState", 0); // Mark alive.
	} else {
		ChangeClientTeam(client, team);
	}
}
public Action:OneSec(Handle:timer, any:i) 
{
	SetEntPropFloat(i, Prop_Send, "m_flCloakMeter", 0.0);
	SetEntProp(i, Prop_Send, "m_iHideHUD", 64); // Remove Spy's cloak meter.
	SetEntProp(i, Prop_Data, "m_iMaxHealth", 125);
	SetEntityHealth(i, 125);
	g_ClientTimers[i] = INVALID_HANDLE;
	return Plugin_Handled;
} 