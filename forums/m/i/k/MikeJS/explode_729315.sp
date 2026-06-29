#include <sourcemod>
#define PL_VERSION "1.0"
#pragma semicolon 1
new bool:exploded[MAXPLAYERS+1];
public Plugin:myinfo =
{
	name = "Explode",
	author = "Mike",
	description = "Exploits Valve's inability to write an update by making people explode on death.",
	version = PL_VERSION,
	url = "http://www.fragtastic.org.uk/"
};
public OnPluginStart() {
	CreateConVar("sm_explode", PL_VERSION, "Explode version.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	HookEvent("player_death", Event_player_death, EventHookMode_Pre);
	HookEvent("player_team", Event_player_team);
}
public OnClientConnected(client) {
	exploded[client] = false;
}
public Action:Event_player_death(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(client==attacker && !exploded[client]) {
		exploded[client] = true;
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
public Action:Event_player_team(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!exploded[client] && GetEventInt(event, "team")>1) {
		CreateTimer(0.1, ForceExplode, client);
	}
}
public Action:ForceExplode(Handle:timer, any:client) {
	if(IsClientInGame(client)) {
		if(IsPlayerAlive(client)) {
			FakeClientCommand(client, "explode");
		} else {
			CreateTimer(0.5, ForceExplode, client);
		}
	}
}