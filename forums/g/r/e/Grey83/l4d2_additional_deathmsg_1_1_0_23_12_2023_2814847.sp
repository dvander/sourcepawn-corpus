#pragma newdecls required
#pragma semicolon 1

#if SOURCEMOD_V_MAJOR == 1 && SOURCEMOD_V_MINOR < 11
	#error For compilation you need SM1.11+
	#endinput
#endif

#include <sdktools_gamerules>

#define PL_VERSION		"1.1.0_23.12.2023"
#define PL_PREFIX		"l4d2_"
#define PL_NAME			"additional_deathmsg"
#define PL_NAME_FULL	"[L4D2] Additional Death Messages on HUD"
#define PL_DESCRIPTION	"show extra death messages those not included by game"
#define PL_AUTHOR		"NoroHime, Grey83"
#define PL_LINK			"https://forums.alliedmods.net/showthread.php?t=344957"

#define HUD_WIDTH	0.3
#define HUD_SLOT	4

#define L4D2_ZOMBIECLASS_TANK	8

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


native bool L4D2_ExecVScriptCode(char[] code);

public Plugin myinfo = {
	name		= PL_NAME_FULL,
	author		= PL_AUTHOR,
	description	= PL_DESCRIPTION,
	version		= PL_VERSION,
	url			= PL_LINK
}

static const char
	ENTITY_KEYs[][] = {
	"Infected",
	"Witch",
	"CInferno",
	"CPipeBombProjectile",
	"CWorld",
	"CEntityFlame",
	"CInsectSwarm",
	"CBaseTrigger",
},
	ENTITY_VALUEs[][] = {
	"Zombie",
	"Witch",
	"Fire",
	"Blast",
	"World",
	"Fire",
	"Spitter",
	"Map",
};

StringMap
	mapNetClassToName;
float
	fTime;
char
	output[128];

// noro.inc start
#define HUD_FLAG_NONE			0		// no flag
#define HUD_FLAG_PRESTR			1		// do you want a string/value pair to start(pre) with the string (default is PRE)
#define HUD_FLAG_POSTSTR		2		// do you want a string/value pair to end(post) with the string
#define HUD_FLAG_BEEP			4		// Makes a countdown timer blink
#define HUD_FLAG_BLINK			8		// do you want this field to be blinking
#define HUD_FLAG_AS_TIME		16		// ?
#define HUD_FLAG_COUNTDOWN_WARN	32		// auto blink when the timer gets under 10 seconds
#define HUD_FLAG_NOBG			64		// dont draw the background box for this UI element
#define HUD_FLAG_ALLOWNEGTIMER	128		// by default Timers stop on 0:00 to avoid briefly going negative over network, this keeps that from happening
#define HUD_FLAG_ALIGN_LEFT		256		// Left justify this text
#define HUD_FLAG_ALIGN_CENTER	512		// Center justify this text
#define HUD_FLAG_ALIGN_RIGHT	768		// Right justify this text
#define HUD_FLAG_TEAM_SURVIVORS	1024	// only show to the survivor team
#define HUD_FLAG_TEAM_INFECTED	2048	// only show to the special infected team
#define HUD_FLAG_TEAM_MASK		3072	// ?
#define HUD_FLAG_UNKNOWN1		4096	// ?
#define HUD_FLAG_TEXT			8192	// ?
#define HUD_FLAG_NOTVISIBLE		16384	// if you want to keep the slot data but keep it from displaying


stock void ScriptedHUDSetParams(int element = 0, const char[] text = "", int flags = 0, float posX = 0.0, float posY = 0.0, float width = 1.0, float height = 0.026) {
	fTime = GetEngineTime();

	GameRules_SetPropFloat("m_fScriptedHUDPosX", posX, element);
	GameRules_SetPropFloat("m_fScriptedHUDPosY", posY, element);

	GameRules_SetPropFloat("m_fScriptedHUDWidth", width, element);
	GameRules_SetPropFloat("m_fScriptedHUDHeight", height, element);

	GameRules_SetPropString("m_szScriptedHUDStringSet", text, _, element);

	ScriptedHUDSetFlags(flags, element);
}

stock void ScriptedHUDSetFlags(int flags, int element) {
	GameRules_SetProp("m_iScriptedHUDFlags", flags, _, element);
}

stock void ScriptedHUDSetEnabled(bool enable) {
	GameRules_SetProp("m_bChallengeModeActive", view_as<int>(enable));
}
// noro.inc end

public void OnPluginStart() {

	CreateConVar(PL_NAME ... "_version", PL_VERSION, "Plugin Version of " ... PL_NAME_FULL, FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_SPONLY);

	mapNetClassToName = new StringMap();

	for (int i; i < sizeof(ENTITY_KEYs); i++)
	{
		FormatEx(output, sizeof(output), "%T", ENTITY_VALUEs[i], LANG_SERVER);
		mapNetClassToName.SetString(ENTITY_KEYs[i], output);
	}

	HookEvent("player_incapacitated", OnPlayerIncapacitated);
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("witch_killed", OnWitchKilled);

	LoadTranslations(PL_NAME);
}

char[] GetEntityTranslatedName(int entity) {

	static char result[MAX_NAME_LENGTH];
	if (!IsClientValid(entity)) {
		GetEntityNetClass(entity, result, sizeof(result));
		mapNetClassToName.GetString(result, result, sizeof(result));
	} else {
		if (GetEntProp(entity, Prop_Send, "m_zombieClass") == L4D2_ZOMBIECLASS_TANK && IsFakeClient(entity))
			FormatEx(result, sizeof(result), "%T", "Tank", LANG_SERVER);
		else FormatEx(result, sizeof(result), "%N", entity);
	}

	return result;
}

public void OnMapStart() {
	L4D2_ExecVScriptCode("g_ModeScript");
	ScriptedHUDSetEnabled(true);
	CreateTimer(1.0, MapGlobalTimer, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
}

void OnWitchKilled(Event event, const char[] name, bool dontBroadcast) {

	int attacker = GetClientOfUserId(event.GetInt("userid"));
	if (IsClientValid(attacker)) {
		FormatEx(output, sizeof(output), " %T", "Killed Witch", LANG_SERVER, GetEntityTranslatedName(attacker));
		ScriptedHUDSetParams(HUD_SLOT, output, HUD_FLAG_TEXT|HUD_FLAG_BLINK|HUD_FLAG_ALIGN_LEFT, 0.01, 0.07, HUD_WIDTH);
	}
}


void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast) {

	int victim = GetClientOfUserId(event.GetInt("userid")),
		attacker = GetClientOfUserId(event.GetInt("attacker"));
	if (attacker == 0)
		attacker = event.GetInt("attackerentid");

	if (IsClientValid(victim)) {
		if (!IsClientValid(attacker))
			FormatEx(output, sizeof(output), " %T", "Kill", LANG_SERVER, GetEntityTranslatedName(attacker), GetEntityTranslatedName(victim));
		else if (attacker == victim && GetClientTeam(victim) == 2)
			FormatEx(output, sizeof(output), " %T", "Bleeding", LANG_SERVER, GetEntityTranslatedName(victim));
		else
			return;

		ScriptedHUDSetParams(HUD_SLOT, output, HUD_FLAG_TEXT|HUD_FLAG_BLINK|HUD_FLAG_ALIGN_LEFT, 0.01, 0.07, HUD_WIDTH);
	}
}

void OnPlayerIncapacitated(Event event, const char[] name, bool dontBroadcast) {

	int victim = GetClientOfUserId(event.GetInt("userid"));
	if (IsClientValid(victim)) {
		int attacker = GetClientOfUserId(event.GetInt("attacker"));
		if (attacker == 0)
			attacker = event.GetInt("attackerentid");

		if (attacker == victim && GetClientTeam(attacker) == 2) {
			FormatEx(output, sizeof(output), " %T", "IncappedSelf", LANG_SERVER, GetEntityTranslatedName(victim));
		// player => tank
		} else if (GetEntProp(victim, Prop_Send, "m_zombieClass") == L4D2_ZOMBIECLASS_TANK) {
			FormatEx(output, sizeof(output), " %T", "Kill", LANG_SERVER, GetEntityTranslatedName(attacker), GetEntityTranslatedName(victim));
		// entity => player
		} else if (!IsClientValid(attacker))
			FormatEx(output, sizeof(output), " %T", "Incapped", LANG_SERVER, GetEntityTranslatedName(attacker), GetEntityTranslatedName(victim));
		else
			return;

		ScriptedHUDSetParams(HUD_SLOT, output, HUD_FLAG_TEXT|HUD_FLAG_BLINK|HUD_FLAG_ALIGN_LEFT, 0.01, 0.07, HUD_WIDTH);
	}
}

Action MapGlobalTimer(Handle timer) {

	if (GetEngineTime() - fTime > 5)
		ScriptedHUDSetFlags(HUD_FLAG_NOTVISIBLE, HUD_SLOT);

	return Plugin_Continue;
}

stock bool IsClientValid(int client)
{
	return 0 < client && client <= MaxClients && IsClientInGame(client);
}