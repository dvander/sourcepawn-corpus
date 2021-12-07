#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

public Plugin myinfo =
{
	name = "[L4D2] Health Abuse Fix (Ledge Hang)",
	author = "bullet28",
	description = "Disabling abuse method of receiving free health",
	version = "1",
	url = ""
}

int lastHealth[MAXPLAYERS+1];
float fLastTempHealth[MAXPLAYERS+1];
float fFrameTempHealth[MAXPLAYERS+1];

public void OnPluginStart() {
	HookEvent("revive_success", eventReviveSucess);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon) {
	if (isPlayerAliveSurvivor(client) && !isHangingLedge(client)) {
		lastHealth[client] = GetEntProp(client, Prop_Data, "m_iHealth");
		fLastTempHealth[client] = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	}
}

public Action eventReviveSucess(Event event, const char[] name, bool dontBroadcast) {
	if (!event.GetBool("ledge_hang")) return;
	
	int client = GetClientOfUserId(event.GetInt("subject"));
	if (lastHealth[client] != 1) return;

	fFrameTempHealth[client] = fLastTempHealth[client];
	CreateTimer(0.0, delayedReviveSuccess, client);
}

public Action delayedReviveSuccess(Handle timer, any client) {
	if (!isPlayerAliveSurvivor(client)) return;

	int health = GetEntProp(client, Prop_Data, "m_iHealth");
	if (health != 1) return;

	float tempHealth = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	if (fFrameTempHealth[client] > 3.0 && tempHealth <= fFrameTempHealth[client]) return;
	
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0.0);
}

bool isPlayerAliveSurvivor(int client) {
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client);
}

bool isHangingLedge(int client) {
	return GetEntProp(client, Prop_Send, "m_isHangingFromLedge") == 1;
}
