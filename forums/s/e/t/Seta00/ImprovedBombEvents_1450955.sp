/**
 * vim: set ts=4 :
 * ==============================================================================
 * Improved Bomb Events Copyright 2011 Reuben 'Seta00' Morais <reuben@seta00.com>
 * ==============================================================================
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
 * exceptions, found in <http://www.sourcemod.net/license.php> (as of this
 * writing, version JULY-31-2007).
 *
 */
 
#include <sourcemod>
#include <textparse>
#include <sdktools_sound>
#include <sdktools_stringtables>

#define PLUGIN_VERSION "1.3"

public Plugin:myinfo = {
	name = "ImprovedBombEvents",
	author = "Seta00",
	description = "Custom sounds and messages on bomb events",
	version = PLUGIN_VERSION,
	url = "http://seta00.com/"
};

enum BombEvent {
	Bomb_BeginPlant
	,Bomb_AbortPlant
	,Bomb_Planted
	
	,Bomb_BeginDefuse
	,Bomb_AbortDefuse
	,Bomb_Defused
	
	,Bomb_Exploded
	,Bomb_Dropped
	,Bomb_Pickup
};

#define MAX_EVENT_MESSAGE_LENGTH 255

enum EventConfigs {
	bool:Event_Announce
	,String:Event_Message[MAX_EVENT_MESSAGE_LENGTH]
	,Event_MessageType
	,String:Event_Sound[PLATFORM_MAX_PATH]
	,String:Event_Target[33]
};

new g_Confs[BombEvent][EventConfigs]
	,bool:g_firstPickup
	,bool:g_lateLoaded
	;
	
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) {
	g_lateLoaded = late;
	return APLRes_Success;
}

public OnPluginStart() {
	LoadTranslations("common.phrases");
	
	CreateConVar("improved_bomb_events_version", PLUGIN_VERSION, "", FCVAR_NOTIFY); 

	HookEvent("bomb_beginplant", OnBombEvent);
	HookEvent("bomb_abortplant", OnBombEvent);
	HookEvent("bomb_planted", OnBombEvent);
	HookEvent("bomb_begindefuse", OnBombEvent);
	HookEvent("bomb_abortdefuse", OnBombEvent);
	HookEvent("bomb_defused", OnBombEvent);
	HookEvent("bomb_exploded", OnBombEvent);
	HookEvent("bomb_dropped", OnBombEvent);
	HookEvent("bomb_pickup", OnBombEvent);
	
	HookEvent("round_end", OnRoundEnd);
}

public OnMapStart() {
	decl String:filePath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, filePath, sizeof filePath, "configs/ImprovedBombEvents.cfg");
	if (!FileExists(filePath)) {
		SetFailState("Couldn't find config file %s.", filePath);
	}

	// Parse config file
	new Handle:confParser = SMC_CreateParser();
	SMC_SetReaders(confParser, ConfParser_OnNewSection, ConfParser_OnKeyValue, SMC_EndSection:0);
	new SMCError:rc = SMC_ParseFile(confParser, filePath);
	if (rc != SMCError_Okay) {
		LogError("Config file parsing failed (%d).", rc);
	}

	g_firstPickup = !g_lateLoaded;
}

public OnMapEnd() {
	g_lateLoaded = false;
}

public OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast) {
	g_firstPickup = true;
}

public OnBombEvent(Handle:event, const String:name[], bool:dontBroadcast) {
	new BombEvent:id = EventNameToEventId(name);
	if (!g_Confs[id][Event_Announce]) {
		return;
	}
	
	if (id == Bomb_Pickup && g_firstPickup) {
		g_firstPickup = false;
		return;
	}
	
	new bool:hasMessage = !!strlen(g_Confs[id][Event_Message]);
	new bool:hasSound = !!strlen(g_Confs[id][Event_Sound]);
	
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MaxClients], target_count;
	new bool:tn_is_ml;

	if ((target_count = ProcessTargetString(
			g_Confs[id][Event_Target],
			0, // from server
			target_list,
			MaxClients,
			COMMAND_FILTER_NO_BOTS,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		return;
	}

	for (new i = 0, client; i < target_count; client = target_list[i++])
	{
		if (hasMessage) {
			new messageType = g_Confs[id][Event_MessageType];
			decl String:playerName[32];

			GetClientName(GetClientOfUserId(GetEventInt(event, "userid")), playerName, sizeof playerName);

			if (messageType & 1) { // hint text
				PrintHintText(client, g_Confs[id][Event_Message], playerName);
			}
			if (messageType & 2) { // chat message
				PrintToChat(client, g_Confs[id][Event_Message], playerName);
			}
			if (messageType & 4) { // center text
				PrintCenterText(client, g_Confs[id][Event_Message], playerName);
			}
		}
		
		if (hasSound) {
			ClientCommand(client, "play %s", g_Confs[id][Event_Sound]);
		}
	}
}

BombEvent:EventNameToEventId(const String:eventName[]) {
	if (StrEqual(eventName, "bomb_dropped")) {
		return Bomb_Dropped;
	} else if(StrEqual(eventName, "bomb_pickup")) {
		return Bomb_Pickup;
	} else if(StrEqual(eventName, "bomb_beginplant")) {
		return Bomb_BeginPlant;
	} else if (StrEqual(eventName, "bomb_begindefuse")) {
		return Bomb_BeginDefuse;
	} else if (StrEqual(eventName, "bomb_abortdefuse")) {
		return Bomb_AbortDefuse;
	} else if (StrEqual(eventName, "bomb_planted")) {
		return Bomb_Planted;
	} else if (StrEqual(eventName, "bomb_exploded")) {
		return Bomb_Exploded;
	} else if (StrEqual(eventName, "bomb_defused")) {
		return Bomb_Defused;
	} else {
		return Bomb_AbortPlant;
	}
}

// Parser stuff
new BombEvent:g_CurrentEvent;

public SMCResult:ConfParser_OnNewSection(Handle:smc, const String:sectionName[], bool:opt_quotes) {
	g_CurrentEvent = EventNameToEventId(sectionName);
}

public SMCResult:ConfParser_OnKeyValue(Handle:smc, const String:key[], const String:value[], bool:key_quotes, bool:value_quotes) {
	if (StrEqual(key, "enabled")) { // should we ignore this event?
		g_Confs[g_CurrentEvent][Event_Announce] = StrEqual(value, "yes");
	} else if (StrEqual(key, "message")) {
		strcopy(g_Confs[g_CurrentEvent][Event_Message], MAX_EVENT_MESSAGE_LENGTH, value);
	} else if (StrEqual(key, "messageType")) {
		g_Confs[g_CurrentEvent][Event_MessageType] = StringToInt(value);
	} else if (StrEqual(key, "sound")) {
		strcopy(g_Confs[g_CurrentEvent][Event_Sound], PLATFORM_MAX_PATH, value);
		decl String:buffer[256];
		if (value[0] != 0) {
			Format(buffer, sizeof buffer, "sound/%s", value);
			AddFileToDownloadsTable(buffer);
		}
	} else if (StrEqual(key, "target")) {
		if (value[0] != 0)
			strcopy(g_Confs[g_CurrentEvent][Event_Target], 33, value);
		else
			strcopy(g_Confs[g_CurrentEvent][Event_Target], 33, "@all");
	}
}
