/**
 * =============================================================================
 * Ready Up - Reloaded - Map Rotation (C)2015 Jessica "jess" Henderson
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
 */

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include "left4downtown.inc"

#undef REQUIRE_PLUGIN
#include "readyup.inc"

public Plugin:myinfo = { name = "readyup reloaded - map rotation", author = "url", description = "readyup reloaded map rotation / map vote plugin", version = "alpha hf2", url = "url", };

new Handle:a_MapList;
new Handle:a_MapListVote;
new Handle:hAllowVoting;
new Handle:hChangeMap;
new String:s_Mapname[32];
new String:cfgPath[64];
new String:s_Mapvote[MAXPLAYERS+1][32];
new pos_;


public OnPluginStart() {

	CreateConVar("rur_maprotation_version", "alpha", "version header");
	hAllowVoting	= CreateConVar("rur_maprotation_voting","1","is voting for the next campaign allowed, using the !mapvote command.");
	hChangeMap	= CreateConVar("rur_maprotation_delay","3","How long of a delay before the map changes. A notice will be sent out as well.");
	RegConsoleCmd("mapvote", cmd_Mapvote);

	LoadTranslations("readyup_rotation.phrases");

	a_MapList	= CreateArray(8);
	a_MapListVote	= CreateArray(8);
}

/*


			In this new system, players can vote at any time during the final map of a campaign, up until the map is about to end.
			This means that in a versus match, votes can continue to be cast/withdrawn/changed during the 2nd round of the map.


*/
public OnAllClientsLoaded() {

	if (L4D_IsMissionFinalMap()) { PrintToChatAll("%t", "map rotation vote"); }
}

public OnClientPostAdminCheck(client) { Format(s_Mapvote[client], sizeof(s_Mapvote[]), "none"); }

public Action:cmd_Mapvote(client, args) {

	if (L4D_IsMissionFinalMap()) { BuildMenu(client); }
}


/*
			

			When the OnMapAboutToEnd forward fires, we want to tally up every players vote, if voting is allowed, and set the
			new filename for s_Mapname. If voting is disabled, it will already be set to the next map in the rotation.


*/
public OnMapAboutToEnd() {

	if (L4D_IsMissionFinalMap()) {
		new newpos	= -1;

		if (GetConVarInt(hAllowVoting) == 1) {

			new curvotes = 0;
			new prevotes = 0;
			decl String:t_Mapname[32];
			decl String:t_Mapvote[32];
			for (new i = 0; i < GetArraySize(a_MapList); i++) {

				GetArrayString(Handle:a_MapList, i, t_Mapname, sizeof(t_Mapname));
				GetArrayString(Handle:a_MapListVote, i, t_Mapvote, sizeof(t_Mapvote));
				if (StringToInt(t_Mapvote) == 0) { continue; }	//	If the server owner doesn't want this campaign / map to be voted on, set to 0.

				curvotes	= 0;	//	Reset the current votes before new vote tally.
				for (new client = 1; client <= MaxClients; client++) {

					if (IsClientInGame(client) && StrEqual(t_Mapname, s_Mapvote[client], false)) { curvotes++; }
				}

				if (curvotes > prevotes) {

					// The current mapname has more votes than the previous one.
					// Note:	If votes are < 1 or <= prevotes, it won't store the vote count or map pos.
					prevotes	= curvotes;
					newpos	= i;	// i is the mapname position in the array. Store it, because it's currently winning the race.
				} else if (curvotes == prevotes) {		// If two maps had the same number of votes, neither wins. This is the case for all ties.

					newpos	= -1;
				}
				curvotes	= 0;
			}
		}
		if (newpos != -1) { pos_ = newpos; }
		GetArrayString(Handle:a_MapList, pos_, s_Mapname, sizeof(s_Mapname));
		if (pos_ + 1 > GetArraySize(a_MapList) - 1) { pos_ = 0; } else { pos_++; }
		PrintToChatAll("%t", "change map", s_Mapname, GetConVarInt(hChangeMap));
		CreateTimer(GetConVarInt(hChangeMap) * 1.0, timerChangeMap, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:timerChangeMap(Handle:Timer) {

	ServerCommand("changelevel %s", s_Mapname);
	return Plugin_Stop;
}

/*


			See Ready up Reloaded Core for information regarding parsing.


*/
public OnConfigsExecuted() {

	ClearArray(Handle:a_MapList);
	ClearArray(Handle:a_MapListVote);

	AutoExecConfig(true, "readyup_rotation");

	BuildPath(Path_SM, cfgPath, sizeof(cfgPath), "configs/rur_rotation.cfg");
	if (!FileExists(cfgPath)) { SetFailState("I cannot find %s and I really need this file...", cfgPath); }

	if (!ParseConfigFile(cfgPath)) { SetFailState("I cannot read %s properly. Please double-check the file formatting.", cfgPath); }
}

stock bool:ParseConfigFile(const String:file[]) {

	new Handle:hParser = SMC_CreateParser();
	new String:error[128];
	new line = 0;
	new col = 0;

	SMC_SetReaders(hParser, Config_NewSection, Config_KeyValue, Config_EndSection);
	SMC_SetParseEnd(hParser, Config_End);

	new SMCError:result = SMC_ParseFile(hParser, file, line, col);
	CloseHandle(hParser);

	if (result != SMCError_Okay) {

		SMC_GetErrorString(result, error, sizeof(error));
		SetFailState("Problem reading %s, line %d, col %d - error: %s", file, line, col, error);
	}

	return (result == SMCError_Okay);
}

public SMCResult:Config_NewSection(Handle:parser, const String:section[], bool:quotes) { return SMCParse_Continue; }

public SMCResult:Config_KeyValue(Handle:parser, const String:key[], const String:value[], bool:ley_quotes, bool:value_quotes) {

	PushArrayString(a_MapList, key);
	PushArrayString(a_MapListVote, value);

	return SMCParse_Continue;
}

public SMCResult:Config_EndSection(Handle:parser) {

	return SMCParse_Continue;
}

public Config_End(Handle:parser, bool:halted, bool:failed) {

	if (failed) { SetFailState("Plugin configuration error"); }
}

/*


			The following code is associated with the vote menu that appears when a player types the !mapvote command on a finale map.
			It builds a menu based on the config of mapnames, using the left column (key, mapname) to load a translations file of the
			map name.
			Note:	Players can continue to cast / modify their ballot during both rounds in a versus campaign, or until the survivors
			escape the finale in coop.


*/
stock BuildMenu(client) {

	new Handle:menu		= CreateMenu(BuildMenuHandle);

	decl String:text[64], String:t_Mapname[64];
	for (new i = 0; i < GetArraySize(a_MapList); i++) {

		GetArrayString(Handle:a_MapListVote, i, t_Mapname, sizeof(t_Mapname));
		if (StrEqual(t_Mapname, "0", false)) { continue; }		//	This map isn't allowed to be voted for, so don't display it in the menu.
		Format(text, sizeof(text), "%T", "%s", client, t_Mapname);
		AddMenuItem(menu, text, text);
	}

	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, 0);
}

public BuildMenuHandle(Handle:menu, MenuAction:action, client, slot) {

	if (action == MenuAction_Select) {

		decl String:t_Mapname[64];
		new spos		= -1;
		for (new i = 0; i < GetArraySize(a_MapList); i++) {

			GetArrayString(a_MapListVote, i, t_Mapname, sizeof(t_Mapname));
			if (StrEqual(t_Mapname, "0", false)) { continue; }
			
			GetArrayString(a_MapList, i, t_Mapname, sizeof(t_Mapname));		//	The player is allowed to vote for this specific map / campaign, so lets get the actual mapname.
			spos++;

			if (spos == slot) { break; }
		}
		if (!StrEqual(t_Mapname, s_Mapvote[client], false)) {

			Format(s_Mapvote[client], sizeof(s_Mapvote[]), "%s", t_Mapname);
			decl String:Name[32];
			GetClientName(client, Name, sizeof(Name));
			PrintToChatAll("%t", "vote submission", t_Mapname, Name);		//	We want to notify the players in the server that a ballot has been cast.
		}
	}
	else if (action == MenuAction_End) {

		CloseHandle(menu);
	}
}