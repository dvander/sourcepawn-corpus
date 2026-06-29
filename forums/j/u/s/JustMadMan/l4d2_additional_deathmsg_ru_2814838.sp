#define HUD_WIDTH	0.3
#define HUD_SLOT	4

/**
 *	[Changes]
 *	v0.1 (December-19-2023)
 *		- internal release
 *	v0.1.1 (December-21-2023)
 *		- hide SI suicide messages
 *	v1.0 (December-24-2023)
 *		- just released
 *		
 *	[Intro]
 *		- show extra death messages those not included by game
 *		- since hud shared by all players, these only be static language, if translation needed just modify yourself and compiles.
 *		- plugin required L4DD, and default used HUD element 4, would not compatible with those 'used hud element 4 plugin' or 'used all hud resource like "[L4D2] Scripted HUD"'
 *		
 * 	[Special Thanks]
 *  	- Nyamorizilla: helps me debug and test even i doesnt have any tool, the screenshot also provide by he.
 *  	- a guy i dont known how call he, this dude found this file and sent it to me after i lost data on my computer, otherwise the plugin would have been lost!
 *  	
 *  [Note]
 *  	- Since HUD resources are shared by all players, there is no translation feature (unless the translation target is dynamically selected) so there is no support for translation or time to support it
 *  	- Since my computer's L4D2 folder was reset to Vanilla status for an unknown reason, my mods and plugins were deleted to the bone, and this should be my last plugin
 *  	- Please modify the key-value pairs(ENTITY_KEYs and ENTITY_VALUEs) in the source code if you need the translation to show the new entity name.
 */

#define PLUGIN_VERSION		"1.0"
#define PLUGIN_PREFIX		"l4d2_"
#define PLUGIN_NAME			"additional_deathmsg"
#define PLUGIN_NAME_FULL	"[L4D2] Additional Death Messages on HUD"
#define PLUGIN_DESCRIPTION	"show extra death messages those not included by game"
#define PLUGIN_AUTHOR		"NoroHime"
#define PLUGIN_LINK			"https://forums.alliedmods.net/showthread.php?t=344957"

#pragma newdecls required
#pragma semicolon 1

#include <sdktools>
#include <sourcemod>
// #include <left4dhooks>
// #include <noro>

native bool L4D2_ExecVScriptCode(char[] code);
#define IsClient(%1) ((1 <= %1 <= MaxClients) && IsClientInGame(%1))

#define L4D2_ZOMBIECLASS_TANK		8

public Plugin myinfo = {
	name			= PLUGIN_NAME_FULL,
	author			= PLUGIN_AUTHOR,
	description		= PLUGIN_DESCRIPTION,
	version			= PLUGIN_VERSION,
	url				= PLUGIN_LINK
};

static const char ENTITY_KEYs[][] = {
	"Infected",
	"Witch",
	"CInferno",
	"CPipeBombProjectile",
	"CWorld",
	"CEntityFlame",
	"CInsectSwarm",
	"CBaseTrigger",
};

static const char ENTITY_VALUEs[][] = {
	"Обычный Зомби",
	"Ведьма",
	"Пламя",
	"Взрыв",
	"Мир",
	"Огонь",
	"Плевальщица",
	"Карта",
};

// noro.inc start
#define HUD_FLAG_NONE                 0     // no flag
#define HUD_FLAG_PRESTR               1     // do you want a string/value pair to start(pre) with the string (default is PRE)
#define HUD_FLAG_POSTSTR              2     // do you want a string/value pair to end(post) with the string
#define HUD_FLAG_BEEP                 4     // Makes a countdown timer blink
#define HUD_FLAG_BLINK                8     // do you want this field to be blinking
#define HUD_FLAG_AS_TIME              16    // ?
#define HUD_FLAG_COUNTDOWN_WARN       32    // auto blink when the timer gets under 10 seconds
#define HUD_FLAG_NOBG                 64    // dont draw the background box for this UI element
#define HUD_FLAG_ALLOWNEGTIMER        128   // by default Timers stop on 0:00 to avoid briefly going negative over network, this keeps that from happening
#define HUD_FLAG_ALIGN_LEFT           256   // Left justify this text
#define HUD_FLAG_ALIGN_CENTER         512   // Center justify this text
#define HUD_FLAG_ALIGN_RIGHT          768   // Right justify this text
#define HUD_FLAG_TEAM_SURVIVORS       1024  // only show to the survivor team
#define HUD_FLAG_TEAM_INFECTED        2048  // only show to the special infected team
#define HUD_FLAG_TEAM_MASK            3072  // ?
#define HUD_FLAG_UNKNOWN1             4096  // ?
#define HUD_FLAG_TEXT                 8192  // ?
#define HUD_FLAG_NOTVISIBLE           16384 // if you want to keep the slot data but keep it from displaying


stock void ScriptedHUDSetParams(int element = 0, const char[] text = "", int flags = 0, float posX = 0.0, float posY = 0.0, float width = 1.0, float height = 0.026) {
	ScriptedHUDSetPosition(posX, posY, element);
	ScriptedHUDSetSize(width, height, element);
	ScriptedHUDSetText(text, element);
	ScriptedHUDSetFlags(flags, element);
}

stock void ScriptedHUDSetPosition(float posX, float posY, int element) {
	GameRules_SetPropFloat("m_fScriptedHUDPosX", posX, element);
	GameRules_SetPropFloat("m_fScriptedHUDPosY", posY, element);
}

stock void ScriptedHUDSetSize(float width, float height, int element) {
	GameRules_SetPropFloat("m_fScriptedHUDWidth", width, element);
	GameRules_SetPropFloat("m_fScriptedHUDHeight", height, element);
}

stock void ScriptedHUDSetText(const char[] text, int element) {
	GameRules_SetPropString("m_szScriptedHUDStringSet", text, _, element);
}

stock void ScriptedHUDSetFlags(int flags, int element) {
	GameRules_SetProp("m_iScriptedHUDFlags", flags, _, element);
}

stock int ScriptedHUDGetFlags(int element) {
	return GameRules_GetProp("m_iScriptedHUDFlags", _, element);
}

stock void ScriptedHUDAddFlags(int flags, int element) {
	ScriptedHUDSetFlags(ScriptedHUDGetFlags(element) | flags, element);
}

stock void ScriptedHUDRemoveFlags(int flags, int element) {
	ScriptedHUDSetFlags(ScriptedHUDGetFlags(element) & ~flags, element);
}

stock void ScriptedHUDSetTimerBase(float time, int element) {
	GameRules_SetPropFloat("m_fScriptedHUDTimerBase", time, element);
}

stock float ScriptedHUDGetTimerBase(float time, int element) {
	return GameRules_GetPropFloat("m_fScriptedHUDTimerBase", element);
}

stock void ScriptedHUDSetTimerAdd(float time, int element) {
	GameRules_SetPropFloat("m_fScriptedHUDTimerAdd", time, element);
}

stock float ScriptedHUDGetTimerAdd(float time, int element) {
	return GameRules_GetPropFloat("m_fScriptedHUDTimerAdd", element);
}

stock void ScriptedHUDSetTimerMode(float time, int element) {
	GameRules_SetPropFloat("m_fScriptedHUDTimerMode", time, element);
}

stock float ScriptedHUDGetTimerMode(float time, int element) {
	return GameRules_GetPropFloat("m_fScriptedHUDTimerMode", element);
}

stock void ScriptedHUDSetEnabled(bool enable) {
	GameRules_SetProp("m_bChallengeModeActive", view_as<int>(enable));
}

// noro.inc end


StringMap mapNetClassToName;
public void OnPluginStart() {

	CreateConVar(PLUGIN_NAME ... "_version", PLUGIN_VERSION, "Plugin Version of " ... PLUGIN_NAME_FULL, FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);

	mapNetClassToName = new StringMap();

	for (int i = 0; i < sizeof(ENTITY_KEYs); i++)
		mapNetClassToName.SetString(ENTITY_KEYs[i], ENTITY_VALUEs[i]);

	HookEvent("player_incapacitated", OnPlayerIncapacitated);
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("witch_killed", OnWitchKilled);

}

char[] GetEntityTranslatedName(int entity) {

	static char result[32];

	if (IsClient(entity)) {

		if (GetEntProp(entity, Prop_Send, "m_zombieClass") == L4D2_ZOMBIECLASS_TANK && IsFakeClient(entity))
			result = "Tank";
		else
			FormatEx(result, sizeof(result), "%N", entity);

	} else {

		GetEntityNetClass(entity, result, sizeof(result));
		mapNetClassToName.GetString(result, result, sizeof(result));
	}

	return result;
}

public void OnMapStart() {
	L4D2_ExecVScriptCode("g_ModeScript");
	ScriptedHUDSetEnabled(true);
	CreateTimer(1.0, MapGlobalTimer, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
}

float timeDeathMessageLastDisplayed;

char output[128];

void OnWitchKilled(Event event, const char[] name, bool dontBroadcast) {

	int attacker = GetClientOfUserId(event.GetInt("userid"));

	if (IsClient(attacker)) {

		FormatEx(output, sizeof(output), " %s Killed Witch", GetEntityTranslatedName(attacker));
		ScriptedHUDSetParams(4, output, HUD_FLAG_TEXT|HUD_FLAG_BLINK|HUD_FLAG_ALIGN_LEFT, 0.01, 0.07, HUD_SLOT);
		timeDeathMessageLastDisplayed = GetEngineTime();
	}
}


void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast) {

	int victim = GetClientOfUserId(event.GetInt("userid")),
		attacker = GetClientOfUserId(event.GetInt("attacker"));

	if (attacker == 0)
		attacker = event.GetInt("attackerentid");

	if (IsClient(victim)) {

		if (!IsClient(attacker))
			FormatEx(output, sizeof(output), " %s Killed %s", GetEntityTranslatedName(attacker), GetEntityTranslatedName(victim));
		else if (attacker == victim && GetClientTeam(victim) == 2)
			FormatEx(output, sizeof(output), " %s Died by Bleeding", GetEntityTranslatedName(victim));
		else
			return;
		
		ScriptedHUDSetParams(4, output, HUD_FLAG_TEXT|HUD_FLAG_BLINK|HUD_FLAG_ALIGN_LEFT, 0.01, 0.07, HUD_SLOT);
		timeDeathMessageLastDisplayed = GetEngineTime();

	} else
		return;
}

void OnPlayerIncapacitated(Event event, const char[] name, bool dontBroadcast) {

	int victim = GetClientOfUserId(event.GetInt("userid"));

	if (IsClient(victim)) {

		int attacker = GetClientOfUserId(event.GetInt("attacker"));

		if (attacker == 0)
			attacker = event.GetInt("attackerentid");

		if (attacker == victim && GetClientTeam(attacker) == 2) {
			
			FormatEx(output, sizeof(output), " %s Incapped Self", GetEntityTranslatedName(victim));

		// player => tank
		} else if (GetEntProp(victim, Prop_Send, "m_zombieClass") == L4D2_ZOMBIECLASS_TANK) {

			FormatEx(output, sizeof(output), " %s Killed %s", GetEntityTranslatedName(attacker), GetEntityTranslatedName(victim));

		// entity => player
		} else if (!IsClient(attacker))
			FormatEx(output, sizeof(output), " %s Incapped %s", GetEntityTranslatedName(attacker), GetEntityTranslatedName(victim));
		else
			return;

		ScriptedHUDSetParams(HUD_SLOT, output, HUD_FLAG_TEXT|HUD_FLAG_BLINK|HUD_FLAG_ALIGN_LEFT, 0.01, 0.07, HUD_WIDTH);
		timeDeathMessageLastDisplayed = GetEngineTime();
	}
}

Action MapGlobalTimer(Handle timer) {

	if (GetEngineTime() - timeDeathMessageLastDisplayed > 5)
		ScriptedHUDSetFlags(HUD_FLAG_NOTVISIBLE, HUD_SLOT);

	return Plugin_Continue;
}
