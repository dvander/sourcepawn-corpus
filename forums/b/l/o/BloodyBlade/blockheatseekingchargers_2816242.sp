/* -------------------CHANGELOG--------------------
 1.2
 - Implemented new method of blocking charger`s auto-aim, now it just continues charging instead of stopping the attack (thanks to dcx2)

 1.1
 - Fixed possible non-changer infected detecting as heatseeking charger
 
 1.0
 - Initial release
^^^^^^^^^^^^^^^^^^^^CHANGELOG^^^^^^^^^^^^^^^^^^^^ */
#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>

bool IsInCharge[MAXPLAYERS + 1] = false;

#define PL_VERSION "1.2"
#define CVAR_FLAGS FCVAR_NOTIFY

ConVar g_hCvarAllow;

public Plugin myinfo =
{
	name = "Blocks heatseeking chargers",
	version = PL_VERSION,
	author = "sheo",
}

public void OnPluginStart()
{
	CreateConVar("l4d2_block_heatseeking_chargers_version", PL_VERSION, "Block heatseeking chargers fix version", CVAR_FLAGS | FCVAR_DONTRECORD);
	g_hCvarAllow = CreateConVar("l4d2_melee_swing_allow", "1", "0 = Plugin off, 1 = Plugin on.", CVAR_FLAGS, true, 0.0, true, 1.0);

	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);

	AutoExecConfig(true, "l4d2_block_heatseeking_chargers");
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

void ConVarChanged_Allow(ConVar convar, const char[] oldValue, const char[] newValue)
{
	IsAllowed();
}

void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	if(bCvarAllow)
	{
		HookEvent("player_bot_replace", BotReplacesPlayer);
		HookEvent("charger_charge_start", Event_ChargeStart);
		HookEvent("charger_charge_end", Event_ChargeEnd);
		HookEvent("player_spawn", Event_ChargeEnd);
		HookEvent("player_death", Event_ChargeEnd);
	}
	else
	{
		UnhookEvent("player_bot_replace", BotReplacesPlayer);
		UnhookEvent("charger_charge_start", Event_ChargeStart);
		UnhookEvent("charger_charge_end", Event_ChargeEnd);
		UnhookEvent("player_spawn", Event_ChargeEnd);
		UnhookEvent("player_death", Event_ChargeEnd);
	}
}

public void Event_ChargeStart(Event event, const char[] name, bool dontBroadcast)
{
    IsInCharge[GetClientOfUserId(event.GetInt("userid"))] = true;
}

public void Event_ChargeEnd(Event event, const char[] name, bool dontBroadcast)
{
    IsInCharge[GetClientOfUserId(event.GetInt("userid"))] = false;
}

public Action BotReplacesPlayer(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("player"));
	if (IsInCharge[client])
	{
		//SetEntityMoveType(GetClientOfUserId(event.GetInt("bot")), MOVETYPE_NONE); //Old method, by me
		int bot = GetClientOfUserId(event.GetInt("bot"));
		SetEntProp(bot, Prop_Send, "m_fFlags", GetEntProp(bot, Prop_Send, "m_fFlags") | FL_FROZEN); //New method, by dcx2
		IsInCharge[client] = false;
	}
}
