#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Leeson"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma newdecls required

EngineVersion g_Game;
bool holiday;

public Plugin myinfo =  {
	name = "Gift Grab Achievement Fix",
	author = PLUGIN_AUTHOR,
	description = "Enables gift drops. Picked up drops will count towards the Gift Grab achievement.",
	version = PLUGIN_VERSION,
	url = "https://github.com/ItsMeLeeson"
};

public void OnPluginStart() {
	g_Game = GetEngineVersion();
	if (g_Game != Engine_CSS) {
		SetFailState("This plugin is for CSS only.");	
	}
	
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("christmas_gift_grab", Event_GiftGrab);
	
	PrintToServer("[Gift Grab] Plugin Loaded");
}

public void OnMapStart() {
	char month[30];
	char dayOfYear[30];
	FormatTime(month, sizeof(month), "%b", GetTime());
	FormatTime(dayOfYear, sizeof(dayOfYear), "%j", GetTime());
	int day = StringToInt(dayOfYear);

	if ((strcmp(month, "Dec") == 0) || day == 1) {
		PrintToServer("[Gift Grab] Holiday Active");
		holiday = true;
	} else {
		PrintToServer("[Gift Grab] Holiday Inactive");
		holiday = false;
	}
}

public void OnMapEnd() {
	holiday = false;
}

public bool IsHolidayActive() {
	return holiday;
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) {
	if ((FindConVar("mp_holiday_nogifts").BoolValue == false) && IsHolidayActive()) {
		int userid = event.GetInt("userid");
		int client = GetClientOfUserId(userid);
		
		float deathPos[3];
		GetClientAbsOrigin(client, deathPos);
		
		if (GetRandomInt(0, 100) < 20) {
			SpawnGift(deathPos);
		}
	}
}

public void Event_GiftGrab(Event event, const char[] name, bool dontBroadcast) {
	if (IsHolidayActive()) {
		int userid = event.GetInt("userid");
		int client = GetClientOfUserId(userid);
		
		Handle bf = StartMessageOne("AchievementEvent", client, USERMSG_RELIABLE);
		BfWriteNum(bf, 5039);
		EndMessage();
	}
}

public void SpawnGift(float position[3]) {
	int pGift = CreateEntityByName("holiday_gift");

	//Thanks to Zephyrus on AlliedModders for rotation code
	//https://forums.alliedmods.net/showthread.php?t=175185
	if (pGift != -1) {
		DispatchSpawn(pGift);

		TeleportEntity(pGift, position, NULL_VECTOR, NULL_VECTOR);

		int pRotator = CreateEntityByName("func_rotating");
		DispatchKeyValueVector(pRotator, "origin", position);
		DispatchKeyValue(pRotator, "maxspeed", "200");
		DispatchKeyValue(pRotator, "friction", "0");
		DispatchKeyValue(pRotator, "dmg", "0");
		DispatchKeyValue(pRotator, "solid", "0");
		DispatchKeyValue(pRotator, "spawnflags", "64");
		DispatchSpawn(pRotator);
		
		SetVariantString("!activator");
		AcceptEntityInput(pGift, "SetParent", pRotator);
		AcceptEntityInput(pRotator, "Start");
		
		SetEntPropEnt(pGift, Prop_Send, "m_hEffectEntity", pRotator);
	}
}