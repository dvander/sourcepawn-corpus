/*
V1.0
Initial release.

V1.1
Cleaned up the code a bit.
Added all other infected except witch.

V1.2
Added the witch.
Added show witch option to config.
Fixed display not showing properly on tank death.
Improved code performance.
*/

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1
#pragma newdecls required

char Message[32];
HintIndex[2048+1];
HintEntity[2048+1];

ConVar show_smoker;
ConVar show_boomer;
ConVar show_hunter;
ConVar show_spitter;
ConVar show_jockey;
ConVar show_charger;
ConVar show_tank;
ConVar show_witch;

public Plugin myinfo =
{
	name = "[L4D2] Infected Hud",
	author = "MasterMind420",
	description = "Infected Hud",
	version = "1.2",
	url = ""
};

public void OnPluginStart()
{
	show_smoker = CreateConVar("l4d2_show_smoker", "1", "[1 = Enable][0 = Disable] Show Instuctor Hint For Smoker");
	show_boomer = CreateConVar("l4d2_show_boomer", "1", "[1 = Enable][0 = Disable] Show Instuctor Hint For Boomer");
	show_hunter = CreateConVar("l4d2_show_hunter", "1", "[1 = Enable][0 = Disable] Show Instuctor Hint For Hunter");
	show_spitter = CreateConVar("l4d2_show_spitter", "1", "[1 = Enable][0 = Disable] Show Instuctor Hint For Spitter");
	show_jockey = CreateConVar("l4d2_show_jockey", "1", "[1 = Enable][0 = Disable] Show Instuctor Hint For Jockey");
	show_charger = CreateConVar("l4d2_show_charger", "1", "[1 = Enable][0 = Disable] Show Instuctor Hint For Charger");
	show_tank = CreateConVar("l4d2_show_tank", "1", "[1 = Enable][0 = Disable] Show Instuctor Hint For Tank");
	show_witch = CreateConVar("l4d2_show_witch", "1", "[1 = Enable][0 = Disable] Show Instuctor Hint For Witch");

	HookEvent("player_spawn", ePlayerSpawn);
	HookEvent("player_death", ePlayerDeath, EventHookMode_Pre);

	HookEvent("tank_spawn", eTankSpawn);
	HookEvent("tank_killed", eTankKilled, EventHookMode_Pre);

	HookEvent("infected_hurt", eWitchHurt);
	HookEvent("witch_spawn", eWitchSpawn);
	HookEvent("witch_killed", eWitchKilled, EventHookMode_Pre);

	AutoExecConfig(true, "l4d2_infected_hud");
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamagePost, OnTakeDamage);
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if(IsValidClient(victim) && GetClientTeam(victim) == 3 && !IsIncapped(victim))
	{
		int health = GetEntProp(victim, Prop_Send, "m_iHealth");
		Format(Message, sizeof(Message), "%d", health);

		if(GetEntProp(victim, Prop_Send, "m_zombieClass") == 1 && GetConVarInt(show_smoker) == 1)
			DisplayInstructorHint(victim, 0.0, 0.0, 0.0, true, false, "", "", "", false, {255, 255, 0}, Message);
		if(GetEntProp(victim, Prop_Send, "m_zombieClass") == 2 && GetConVarInt(show_boomer) == 1)
			DisplayInstructorHint(victim, 0.0, 0.0, 0.0, true, false, "", "", "", false, {255, 255, 0}, Message);
		if(GetEntProp(victim, Prop_Send, "m_zombieClass") == 3 && GetConVarInt(show_hunter) == 1)
			DisplayInstructorHint(victim, 0.0, 0.0, 0.0, true, false, "", "", "", false, {255, 255, 0}, Message);
		if(GetEntProp(victim, Prop_Send, "m_zombieClass") == 4 && GetConVarInt(show_spitter) == 1)
			DisplayInstructorHint(victim, 0.0, 0.0, 0.0, true, false, "", "", "", false, {255, 255, 0}, Message);
		if(GetEntProp(victim, Prop_Send, "m_zombieClass") == 5 && GetConVarInt(show_jockey) == 1)
			DisplayInstructorHint(victim, 0.0, 0.0, 0.0, true, false, "", "", "", false, {255, 255, 0}, Message);
		if(GetEntProp(victim, Prop_Send, "m_zombieClass") == 6 && GetConVarInt(show_charger) == 1)
			DisplayInstructorHint(victim, 0.0, 0.0, 0.0, true, false, "", "", "", false, {255, 255, 0}, Message);
		if(GetEntProp(victim, Prop_Send, "m_zombieClass") == 8 && GetConVarInt(show_tank) == 1)
			DisplayInstructorHint(victim, 0.0, 0.0, 0.0, true, false, "", "", "", false, {255, 255, 0}, Message);
	}

	return Plugin_Stop;
}

public void ePlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int special = GetClientOfUserId(GetEventInt(event, "userid"));

	if (IsValidClient(special) && GetClientTeam(special) == 3)
		CreateHintEntity(special);
}

public void ePlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int special = GetClientOfUserId(GetEventInt(event, "userid"));

	if (IsValidClient(special) && GetClientTeam(special) == 3)
		DestroyHintEntity(special);
}

public void eTankSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int tank = GetClientOfUserId(event.GetInt("userid"));

	if (IsValidClient(tank))
		CreateHintEntity(tank);
}

public Action eTankKilled(Event event, const char[] name, bool dontBroadcast)
{
	int tank = GetClientOfUserId(event.GetInt("userid"));

	if (IsValidClient(tank))
		DestroyHintEntity(tank);
}

public void eWitchHurt(Event event, const char[] name, bool dontBroadcast)
{
	int infected = GetEventInt(event, "entityid");

	if (IsValidEntity(infected))
	{
		char sClassName[10];
		GetEntityClassname(infected, sClassName, sizeof(sClassName));

		if(sClassName[0] != 'w' || !StrEqual(sClassName, "witch"))
			return;

		int health = GetEntProp(infected, Prop_Data, "m_iHealth");

		Format(Message, sizeof(Message), "%d", health);

		if(GetConVarInt(show_witch) == 1)
			DisplayInstructorHint(infected, 0.0, 0.0, 0.0, true, false, "", "", "", false, {255, 255, 0}, Message);
	}
}

public void eWitchSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int witch = GetEventInt(event, "witchid");

	if(IsValidEntity(witch))
		CreateHintEntity(witch);
}

public void eWitchKilled(Event event, const char[] name, bool dontBroadcast)
{
	int witch = GetEventInt(event, "witchid");

	if(IsValidEntity(witch))
		DestroyHintEntity(witch);
}

stock void DisplayInstructorHint(int target, float fTime, float fHeight, float fRange, bool bFollow, bool bShowOffScreen, char[] sIconOnScreen, char[] sIconOffScreen, char[] sCmd, bool bShowTextAlways, int iColor[3], char sText[32])
{
	char sBuffer[32];

	FormatEx(sBuffer, sizeof(sBuffer), "si_%d", target);
	DispatchKeyValue(target, "targetname", sBuffer);
	DispatchKeyValue(HintEntity[target], "hint_target", sBuffer);
	DispatchKeyValue(HintEntity[target], "hint_name", sBuffer);
	DispatchKeyValue(HintEntity[target], "hint_replace_key", sBuffer);

	FormatEx(sBuffer, sizeof(sBuffer), "%d", !bFollow);
	DispatchKeyValue(HintEntity[target], "hint_static", sBuffer);
	DispatchKeyValue(HintEntity[target], "hint_timeout", "0.0");

	FormatEx(sBuffer, sizeof(sBuffer), "%d", RoundToFloor(fHeight));
	DispatchKeyValue(HintEntity[target], "hint_icon_offset", sBuffer);

	FormatEx(sBuffer, sizeof(sBuffer), "%d", RoundToFloor(fRange));
	DispatchKeyValue(HintEntity[target], "hint_range", sBuffer);

	FormatEx(sBuffer, sizeof(sBuffer), "%d", !bShowOffScreen);
	DispatchKeyValue(HintEntity[target], "hint_nooffscreen", sBuffer);

	DispatchKeyValue(HintEntity[target], "hint_icon_onscreen", sIconOnScreen);
	DispatchKeyValue(HintEntity[target], "hint_icon_offscreen", sIconOffScreen);

	DispatchKeyValue(HintEntity[target], "hint_binding", sCmd);

	// Shows text behind walls (false limits distance of seeing hint)
	FormatEx(sBuffer, sizeof(sBuffer), "%d", bShowTextAlways);
	DispatchKeyValue(HintEntity[target], "hint_forcecaption", sBuffer);

	FormatEx(sBuffer, sizeof(sBuffer), "%d %d %d", iColor[0], iColor[1], iColor[2]);
	DispatchKeyValue(HintEntity[target], "hint_color", sBuffer);

	//ReplaceString(sText, sizeof(sText), "\n", " ");
	DispatchKeyValue(HintEntity[target], "hint_caption", sText);
	DispatchKeyValue(HintEntity[target], "hint_activator_caption", sText);

	DispatchKeyValue(HintEntity[target], "hint_flags", "0");
	DispatchKeyValue(HintEntity[target], "hint_display_limit", "0");
	DispatchKeyValue(HintEntity[target], "hint_suppress_rest", "1");
	DispatchKeyValue(HintEntity[target], "hint_instance_type", "2");
	DispatchKeyValue(HintEntity[target], "hint_auto_start", "false"); //true
	DispatchKeyValue(HintEntity[target], "hint_local_player_only", "true");
	DispatchKeyValue(HintEntity[target], "hint_allow_nodraw_target", "true");

	//DispatchKeyValue(HintEntity[target], "hint_pulseoption", "1");
	//DispatchKeyValue(HintEntity[target], "hint_alphaoption", "1");
	//DispatchKeyValue(HintEntity[target], "hint_shakeoption", "1");

	DispatchSpawn(HintEntity[target]);
	AcceptEntityInput(HintEntity[target], "ShowHint");

	HintIndex[target] = EntIndexToEntRef(HintEntity[target]);
}

void DestroyHintEntity(int client)
{
	if(IsValidEntRef(HintIndex[client]))
	{
		AcceptEntityInput(HintIndex[client], "Kill");
		HintIndex[client] = -1;
	}
}

void CreateHintEntity(int client)
{
	if(IsValidEntRef(HintIndex[client]))
	{
		AcceptEntityInput(HintIndex[client], "Kill");
		HintIndex[client] = -1;
	}

	HintEntity[client] = CreateEntityByName("env_instructor_hint");

	if(HintEntity[client] < 0)
		return;

	DispatchSpawn(HintEntity[client]);

	HintIndex[client] = EntIndexToEntRef(HintEntity[client]);
}

stock bool IsValidClient(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client));
}

stock bool IsIncapped(int client)
{
	return (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1) > 0);
}

static bool IsValidEntRef(int iEntRef)
{
    static int iEntity;
    iEntity = EntRefToEntIndex(iEntRef);
    return (iEntRef && iEntity != INVALID_ENT_REFERENCE && IsValidEntity(iEntity));
}