#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

public Plugin:myinfo =
{
	name = "[L4D2] Charger Invisible Wall Grab FIX",
	author = "AntiQar & Spumer",
	description = "",
	version = "1.0.1",
	url = "http://zo-zo.org/"
}


static Float:g_fChargers[33][3];

public OnPluginStart() {
	HookEvent("charger_carry_start", Event_HookStart, EventHookMode_Pre);
	HookEvent("charger_carry_end", Event_HookEnd);
}

public Action:Event_HookStart(Handle:event, const String:name[], bool:dontBroadcast) {
	new Float:vPos[3];

	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (attacker > 0) {
		new victim = GetClientOfUserId(GetEventInt(event, "victim"));
		if (victim > 0) {
			GetClientAbsOrigin(victim, vPos);
		}
		g_fChargers[attacker] = vPos;
	}

	return Plugin_Continue;
}

public Event_HookEnd(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client == 0) {
		return;
	}

	decl Float:vMin[3], Float:vMax[3];
	GetClientMins(client, vMin);
	GetClientMaxs(client, vMax);

	decl Float:vVec[3];

	GetClientAbsOrigin(client, vVec);
	vVec[2] += 64.0;

	new Handle:hTrace = TR_TraceHullEx(vVec, vVec, vMin, vMax, CONTENTS_PLAYERCLIP);
	if(TR_DidHit(hTrace)) {
		if(GetVectorDistance(vVec, g_fChargers[client]) <= 150.0)
			TeleportEntity(client, g_fChargers[client], NULL_VECTOR, NULL_VECTOR);
	}
	CloseHandle(hTrace);
}
