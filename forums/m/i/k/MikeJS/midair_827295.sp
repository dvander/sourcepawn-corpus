#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <tf2damage>
new Handle:g_hDist = INVALID_HANDLE;
new Float:g_fDist = 60.0;
new Float:g_vecDown[3] = {90.0, 0.0, 0.0};
public OnPluginStart() {
	g_hDist = CreateConVar("sm_midair_dist", "60.0", "Distance off ground players have to be to receive damage.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	HookConVarChange(g_hDist, Cvar_dist);
}
public OnConfigsExected() {
	g_fDist = GetConVarFloat(g_hDist);
}
public Cvar_dist(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_fDist = GetConVarFloat(g_hDist);
}
public Action:TF2_PlayerHurt(client, attacker, damage, health) {
	if(DistFromGround(client)<g_fDist)
		return Plugin_Handled;
	return Plugin_Continue;
}
Float:DistFromGround(ent) {
	decl Float:vecOrigin[3], Float:vecPos[3], Float:dist; 
	GetEntPropVector(ent, Prop_Send, "m_vecOrigin", vecOrigin);
	new Handle:trace = TR_TraceRayFilterEx(vecOrigin, g_vecDown, CONTENTS_SOLID|CONTENTS_MOVEABLE, RayType_Infinite, TraceEntityFilterPlayers, ent); 
	if(TR_DidHit(trace)) { 
		TR_GetEndPosition(vecPos, trace);
		dist = vecOrigin[2]-vecPos[2];
	} else {
		dist = -1.0;
	}
	CloseHandle(trace);
	return dist;
}
public bool:TraceEntityFilterPlayers(entity, contentsMask, any:ent) {
	return entity>MaxClients;
}