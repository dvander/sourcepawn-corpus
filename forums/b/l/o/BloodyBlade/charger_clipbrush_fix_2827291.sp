#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.1"
#define CVAR_FLAGS FCVAR_NOTIFY

public Plugin myinfo =
{
	name = "[L4D2] Charger Invisible Wall Grab FIX",
	author = "AntiQar & Spumer",
	description = "",
	version = PLUGIN_VERSION,
	url = "http://zo-zo.org/"
}

static ConVar hPluginOn;
static bool bHooked = false;
static float g_fChargers[33][3], vPos[3], vMin[3], vMax[3], vVec[3];

public void OnPluginStart()
{
	CreateConVar("l4d2_ciwgf_version", PLUGIN_VERSION, "[L4D2] Charger Invisible Wall Grab FIX plugin version.", CVAR_FLAGS|FCVAR_DONTRECORD);
	hPluginOn = CreateConVar("l4d2_ciwgf_plugin_on", "1", "Plugin On/Off.", CVAR_FLAGS);
	hPluginOn.AddChangeHook(OnConVarChanged_Allow);
	AutoExecConfig(true, "l4d2_ciwgf");
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

void OnConVarChanged_Allow(ConVar cvar, const char[] sOldValue, const char[] sNewValue)
{
	IsAllowed();
}

void IsAllowed()
{
	bool bPluginOn = hPluginOn.BoolValue;
	if(bPluginOn && !bHooked)
	{
		bHooked = true;
		HookEvent("charger_carry_start", Event_HookStart, EventHookMode_Pre);
		HookEvent("charger_carry_end", Event_HookEnd);
	}
	else if(!bPluginOn && bHooked)
	{
		bHooked = false;
		UnhookEvent("charger_carry_start", Event_HookStart, EventHookMode_Pre);
		UnhookEvent("charger_carry_end", Event_HookEnd);
	}
}

Action Event_HookStart(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("userid"));
	if (attacker > 0)
	{
		int victim = GetClientOfUserId(event.GetInt("victim"));
		if (victim > 0) GetClientAbsOrigin(victim, vPos);
		g_fChargers[attacker] = vPos;
	}
	return Plugin_Continue;
}

void Event_HookEnd(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client > 0)
	{
		GetClientMins(client, vMin);
		GetClientMaxs(client, vMax);
		GetClientAbsOrigin(client, vVec);
		vVec[2] += 64.0;

		Handle hTrace = TR_TraceHullEx(vVec, vVec, vMin, vMax, CONTENTS_PLAYERCLIP);
		if(TR_DidHit(hTrace) && GetVectorDistance(vVec, g_fChargers[client]) <= 150.0)
		{
			TeleportEntity(client, g_fChargers[client], NULL_VECTOR, NULL_VECTOR);
		}
		CloseHandle(hTrace);
	}
}
