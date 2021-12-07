/**
 *
 *	Bodyshot Punishment
 *	by WakiMiko
 *		
 *	Allows you to punish snipers for having bad aim.
 *	
 * 
 *	--Changelog--
 *		
 *		0.1
 *			Initial Release
 *
 *		0.2
 *			Added the possiblity to play sound files to clients upon punishment
 *
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */
 
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "0.2"
#define PREFIX "\x04[BS]\x01 "
#define MAX_PLAYERS 25
#define NAME_LENGTH 32
#define MAX_FILE_LEN 80
#define SOUND "sourcemod/bodyshot.wav"
 
new Handle:sm_bs_count = INVALID_HANDLE;
new Handle:sm_bs_action = INVALID_HANDLE;
new Handle:sm_bs_slap_damage = INVALID_HANDLE;
new Handle:sm_bs_reset = INVALID_HANDLE;
new Handle:sm_bs_sound = INVALID_HANDLE;
new counter[MAX_PLAYERS];

public Plugin:myinfo = {
	name = "Bodyshot Punishment",
	author = "WakiMiko",
	description = "Performs various actions against bodyshot offenders",
	version = PLUGIN_VERSION,
	url = "http://wakimiko.wwwchan.com"
}

public OnPluginStart() {
	sm_bs_count = CreateConVar("sm_bs_count", "1", "Trigger action after this many violations, 0 to disable plugin");
	sm_bs_action = CreateConVar("sm_bs_action", "0", "Action to perform against offenders: 0 = slay, 1 = slap (see sm_bs_slap_damage), 2 = kick");
	sm_bs_slap_damage = CreateConVar("sm_bs_slap_damage", "50", "Slap damage");
	sm_bs_reset = CreateConVar("sm_bs_reset", "0", "Reset violation counter after each headshot?");
	sm_bs_sound = CreateConVar("sm_bs_sound", "1", "Play sound when a player gets punished?");
	CreateConVar("sm_bs_version", PLUGIN_VERSION, "", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY);
	AutoExecConfig(true, "bodyshot");
	
	HookEvent("player_death", Event_PlayerDeath);
}

public OnMapStart() {	
	if(GetConVarInt(sm_bs_sound) == 1) {
		decl String:buffer[MAX_FILE_LEN];
		PrecacheSound(SOUND, true);
		Format(buffer, sizeof(buffer), "sound/%s", SOUND);
		PrecacheSound(buffer);
		AddFileToDownloadsTable(buffer);
	}
}

public OnClientDisconnect(client) {
	reset(client);
}

 
public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast) {	
	if(GetConVarInt(sm_bs_count) == 0) 
		return;
		
	new attacker_id = GetEventInt(event, "attacker");
	new attacker = GetClientOfUserId(attacker_id);
	new type =  GetEventInt(event, "customkill");
		
	if(type == 11)
		punish(attacker);	
	else if(type == 1 && GetConVarInt(sm_bs_reset) == 1 && counter[attacker] >= 1)
		reward(attacker);
}

punish(attacker) {
	new max = GetConVarInt(sm_bs_count);
	counter[attacker]++;

	if(counter[attacker] >= max) {	
		new String:aname[NAME_LENGTH];
		GetClientName(attacker, aname, sizeof(aname));
		
		switch(GetConVarInt(sm_bs_action)) {
			case 1: {
				SlapPlayer(attacker, GetConVarInt(sm_bs_slap_damage), true);
				PrintToChat(attacker, "%s%s has been slapped with %d damage for bodyshotting.", PREFIX, aname, GetConVarInt(sm_bs_slap_damage));
			}			
			case 2: {
				KickClient(attacker, "You have been kicked for bodyshotting.");
				PrintToChatAll("%s%s has been kicked for for bodyshotting.", PREFIX, aname);
			}
			default: { 
				ForcePlayerSuicide(attacker);
				PrintToChatAll("%s%s has been slain for for bodyshotting.", PREFIX, aname);
			}		
		}

		if(GetConVarInt(sm_bs_sound) == 1)
			EmitSoundToAll(SOUND);
			
		reset(attacker);	
	}
	else {
		new remaining = max - counter[attacker];
		if(remaining > 1)
			PrintToChat(attacker, "%s%d bodyshots remaining until you are punished.", PREFIX, remaining);
		else
			PrintToChat(attacker, "%sYou will be punished on your next bodyshot.", PREFIX);
	}
}

reward(attacker) {
	PrintToChat(attacker, "%sGood boy, your bodyshot counter has been reset.", PREFIX);	
	reset(attacker);
}

reset(client) {
	counter[client] = 0;
}