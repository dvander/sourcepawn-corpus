#include <sourcemod>
#include <sdktools>
#include <sdktools_functions>

#define PLUGIN_VERSION  "1.1"
#include soundscapes.inc

new gEnabled = false;
new gClocktownRelays[6]; //Clocktown relay entities
new Handle:gDayStartTimer = INVALID_HANDLE;

public Plugin:myinfo = {
	name = "[TF2] Clocktown Soundscape Fixer",
	author = "Jim",
	description = "Fixes the dynamic soundscapes on clocktown. Requires [TF2] Soundscape Fixer",
	version = PLUGIN_VERSION,
	url = ""
};

public OnPluginStart() {
	HookEvent("teamplay_round_start", Event_RoundStart);
}

public OnMapStart() {
	new String:map[50];
	GetCurrentMap(map, sizeof(map));

	if(StrContains(map, "trade_clocktown_", false) == 0) {
		gEnabled = true;
	}
}

//Set up the clocktown day timers
public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast) {
	if(gEnabled) {
		FindTimers();
		HookEntityOutput("logic_relay", "OnTrigger", OnTrigger);

		if(gDayStartTimer != INVALID_HANDLE) {
			KillTimer(gDayStartTimer);
			gDayStartTimer = INVALID_HANDLE;
		}
	}
}

public OnSoundscapesLoaded() {
	EnableSoundscapesByName("clocktown.day1");
}

//Handle clocktown day changes
//Adpated from the ct-watch plugin
public OnTrigger(const String:output[], caller, activator, Float:delay) {
	new day = 1;

	if(caller == gClocktownRelays[0]) {
		day = 1;
	} else if(caller == gClocktownRelays[2]) {
		day = 2;
	} else if(caller == gClocktownRelays[4]) {
		day = 3;
	} else if(caller == gClocktownRelays[1]) {
		day = 11;
	} else if(caller == gClocktownRelays[3]) {
		day = 12;
	} else if(caller == gClocktownRelays[5]) {
		day = 13;
		CreateTimer(270.0, FinalNightSoundscape);
	} else {
		return;
	}

	DisableSoundscapesByName("clocktown.day1");
	DisableSoundscapesByName("clocktown.day2");
	DisableSoundscapesByName("clocktown.day3");
	DisableSoundscapesByName("clocktown.day4");
	DisableSoundscapesByName("clocktown.night");
	DisableSoundscapesByName("field.music");
	EnableSoundscapesByName("clocktown.daystart");

	if(day < 10) {
		CreateTimer(17.0, UpdateDaySoundscape, day);
	} else {
		UpdateDaySoundscape(INVALID_HANDLE, day);
	}
}

//Enable/disable soundscapes appropriately for clocktown days
public Action:UpdateDaySoundscape(Handle:timer, any:day) {
	gDayStartTimer = INVALID_HANDLE;

	DisableSoundscapesByName("clocktown.day1");
	DisableSoundscapesByName("clocktown.day2");
	DisableSoundscapesByName("clocktown.day3");
	DisableSoundscapesByName("clocktown.day4");
	DisableSoundscapesByName("clocktown.night");
	DisableSoundscapesByName("field.music");
	DisableSoundscapesByName("clocktown.daystart");

	switch(day) {
		case 1 :
			EnableSoundscapesByName("clocktown.day1");
		case 2 :
			EnableSoundscapesByName("clocktown.day2");
		case 3 :
			EnableSoundscapesByName("clocktown.day3");
		case 11 :
			EnableSoundscapesByName("clocktown.night");
		case 12 :
			EnableSoundscapesByName("clocktown.night");
		case 13 :
			EnableSoundscapesByName("clocktown.night");
		case 14 :
			EnableSoundscapesByName("clocktown.day4");
		default :
			return;
	}

	LogMessage("Clocktown: new day %d, updating soundscapes", day);

	if(day < 10) {
		EnableSoundscapesByName("field.music");
	}
}

//Play the clocktown final night soundscape
public Action:FinalNightSoundscape(Handle:timer, any:data) {
	UpdateDaySoundscape(INVALID_HANDLE, 14);
}

//Find the clocktown entities that manage the days
//Taken from the ct-watch plugin
public FindTimers() {
	new index = -1;
	while ((index = FindEntityByClassname(index, "logic_relay")) != -1) {
		new String:entityName[35];
		GetEntPropString(index, Prop_Data, "m_iName", entityName, sizeof(entityName));
		if (StrEqual(entityName, "day1relay")) gClocktownRelays[0] = index;
		else if (StrEqual(entityName, "night1relay")) gClocktownRelays[1] = index;
		else if (StrEqual(entityName, "day2relay")) gClocktownRelays[2] = index;
		else if (StrEqual(entityName, "night2relay")) gClocktownRelays[3] = index;
		else if (StrEqual(entityName, "day3relay")) gClocktownRelays[4] = index;
		else if (StrEqual(entityName, "night3relay")) gClocktownRelays[5] = index;
	}
}