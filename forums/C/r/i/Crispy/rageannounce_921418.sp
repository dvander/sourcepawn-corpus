/**
 * vim: set ts=4 :
 * =============================================================================
 * Rage Quit Announce Plugin for SourceMod
 * Announces rage quits ala Unreal Tournament.
 *
 * SourceMod (C)2004-2008 AlliedModders LLC.  All rights reserved.
 * =============================================================================
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
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 *
 * Version: $Id$
 */

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo =
{
	name = "Rage Quit Announce",
	author = "Crispy, Clan XOR",
	description = "Announces rage quits ala Unreal Tournament",
	version = PLUGIN_VERSION,
	url = "http://xor.clanservers.com/"
};

new rage_count;
new bool:first_blood;
new bool:round_ending; 
new bool:end_of_round;
new team[MAXPLAYERS];
new frags[MAXPLAYERS];
new deaths[MAXPLAYERS];
new dominated[MAXPLAYERS];
new round_losses[MAXPLAYERS];
new Handle:rage_timer = INVALID_HANDLE;
new Handle:clear_count_timer = INVALID_HANDLE;
new Handle:announce = INVALID_HANDLE;
new String:rage_text[6][32];
new String:rage_sound[6][32];


public OnPluginStart()
{

	for (new i = 0; i < MAXPLAYERS; i++) {
		team[i] = 0;
		frags[i] = 0;
		deaths[i] = 0;
		dominated[i] = 0;
		round_losses[i] = 0;
	}

	rage_text[1] = "RAGE QUIT!";
	rage_text[2] = "MULTI RAGE QUIT!";
	rage_text[3] = "MONSTER RAGE QUIT!";
	rage_text[4] = "UNSTOPPABLE RAGE QUIT!";
	rage_text[5] = "GODLIKE RAGE QUIT!";

	rage_sound[1] = "ragequit/ragequit.wav";
	rage_sound[2] = "ragequit/multi.wav";
	rage_sound[3] = "ragequit/monster.wav";
	rage_sound[4] = "ragequit/unstoppable.wav";
	rage_sound[5] = "ragequit/godlike.wav";

	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_disconnect", Event_PlayerDisconnect);
	HookEvent("teamplay_round_win", Event_RoundWin);
	HookEvent("teamplay_setup_finished", ClearRoundEndingFlag, EventHookMode_PostNoCopy);
	HookEvent("teamplay_point_captured", ClearRoundEndingFlag, EventHookMode_PostNoCopy);
	HookEntityOutput("team_round_timer", "On30SecRemain", EntityOutput_RoundEnding);

	announce = CreateConVar("sm_rage_quit_announce", "1", "Enable or disable rage quit announcements.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
}


public OnMapStart()
{
	rage_count = 0;
	first_blood = false;
	round_ending = false;
	end_of_round = false;
	rage_timer = INVALID_HANDLE;
	clear_count_timer = INVALID_HANDLE;

	// precache sounds
	for (new i = 1; i <= 5; i++)
		PrecacheSound(rage_sound[i], true);

	// make sounds downloadable
	AddFileToDownloadsTable("sound/ragequit/godlike.wav");
	AddFileToDownloadsTable("sound/ragequit/monster.wav");
	AddFileToDownloadsTable("sound/ragequit/multi.wav");
	AddFileToDownloadsTable("sound/ragequit/ragequit.wav");
	AddFileToDownloadsTable("sound/ragequit/unstoppable.wav");
}


public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if ((client > 0) && IsClientConnected(client) && IsClientInGame(client))
		team[client] = GetClientTeam(client);
}


public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	if ((client > 0) && IsClientConnected(client) && IsClientInGame(client)) {
		team[client] = GetClientTeam(client);
		frags[client] = GetClientFrags(client);
		deaths[client] = GetClientDeaths(client);
		dominated[client] = PlayersDominatingMe(client);
	}

	if ((attacker > 0) && (attacker != client))
		first_blood = true;
}


public EntityOutput_RoundEnding(const String:output[], caller, activator, Float:delay)
{
	round_ending = true;
}


public ClearRoundEndingFlag(Handle:event, const String:name[], bool:dontBroadcast)
{
	round_ending = false;
}


public Action:Event_RoundWin(Handle:event, const String:name[], bool:dontBroadcast)
{
	new losing_team = GetEventInt(event, "team") ^ 1;
	for (new i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && !IsFakeClient(i) && (team[i] == losing_team))
			round_losses[i]++;
		else
			round_losses[i] = 0;
	}
	CreateTimer(60.0, ClearEndOfRoundFlag, TIMER_FLAG_NO_MAPCHANGE);
	round_ending = false;
	end_of_round = true;
	first_blood = false;
}


public Action:ClearEndOfRoundFlag(Handle:timer, any:client)
{
	end_of_round = false;
}


public Action:Event_PlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	decl String:reason[20];
	GetEventString(event, "reason", reason, 19);

	new bool:client_is_valid = ((client > 0) && StrEqual(reason, "Disconnect by user", false));

	if (GetConVarBool(announce) && client_is_valid) {
		new bool:rage = false;
		new Float:kd = (deaths[client] > 0) ? (float(frags[client]) / float(deaths[client])) : 1.0;

		if (team[client] > 1) {
			if (end_of_round) {
				if (round_losses[client] > 0)
					rage = true;
			}
			else if (
			(kd < 0.1) ||
			(round_ending && first_blood) ||
			(dominated[client] > 2) ||
			(GetTeamFrags(team[client] ^ 1) > (3 * GetTeamFrags(team[client]))) ||
			(round_losses[client] > 2))
				rage = true;

			if (rage) {
				rage_count++;
				if (clear_count_timer != INVALID_HANDLE)
					KillTimer(clear_count_timer);
				clear_count_timer = CreateTimer(30.0, Clear_RageCount, TIMER_FLAG_NO_MAPCHANGE);
				if (rage_timer != INVALID_HANDLE)
					KillTimer(rage_timer);
				rage_timer = CreateTimer(1.5, Rage_Announce, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}

	team[client] = 0;
	frags[client] = 0;
	deaths[client] = 0;
	dominated[client] = 0;
	round_losses[client] = 0;
}


public Action:Clear_RageCount(Handle:timer, any:client)
{
	rage_count = 0;
	clear_count_timer = INVALID_HANDLE;
}


public Action:Rage_Announce(Handle:timer, any:client)
{
	if (rage_count > 0) {

		new j = (rage_count > 5) ? 5 : rage_count;
		EmitSoundToAll(rage_sound[j], SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
		PrintCenterTextAll("%s", rage_text[j]);
//		for (new i = 1; i <= MaxClients; i++) {
//			if (IsClientInGame(i) && !IsFakeClient(i)) {
//				EmitSoundToClient(i, rage_sound[j], SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
//				PrintCenterText(i, "%s", rage_text[j]);
//			}
//		}
	}

	rage_timer = INVALID_HANDLE;
}


stock PlayersDominatingMe(client)
{
	new domination_count = 0;
	new offset = FindSendPropInfo("CTFPlayer", "m_bPlayerDominatingMe");
	for (new i = 1; i <= MaxClients; i++) {
		if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i)) {
			if (GetEntData(client, offset+i) == 1)
				domination_count++;
		}
	}

	return domination_count;
}  


stock GetTeamFrags(team_id)
{
	new team_frags = 0;
	for (new i = 1; i <= MaxClients; i++) {
		if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i)) {
			if (GetClientTeam(i) == team_id)
				team_frags += GetClientFrags(i);
		}			
	}

	return team_frags;
}

