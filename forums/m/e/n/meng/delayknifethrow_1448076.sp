#include <sourcemod>

new Handle:g_hCVarDelay;
new g_bNoThrow[MAXPLAYERS+1];

public OnPluginStart() {

	g_hCVarDelay = CreateConVar("sm_throwingknives_delay", "2.5", "Delay in seconds between knife throws.", _, true, 0.9, true, 29.9);
}

public Action:OnKnifeThrow(client) {

	if (g_bNoThrow[client])
		return Plugin_Handled;

	g_bNoThrow[client] = true;
	CreateTimer(GetConVarFloat(g_hCVarDelay), AllowThrow, client);
	return Plugin_Continue;
}

public Action:AllowThrow(Handle:timer, any:client) {

	g_bNoThrow[client] = false;
	return Plugin_Continue;
}