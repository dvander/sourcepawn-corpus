#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#define PLUGIN_VERSION "1.0"

new spawnpoints[2][40];
new pointsnum[2];
new spnum[MAXPLAYERS] = {0};

public Plugin:myinfo = 
{
	name = "random point spawn",
	author = "Nail",
        version = "1.0",
	description = "Spawn players in random spawn points", version = PLUGIN_VERSION,
	url = "dcmagnets.ru"
};
public OnMapStart()
{
	for(new i = 0; i < 40; i++) spawnpoints[0][i] = 0;
	for(new i = 0; i < 40; i++) spawnpoints[1][i] = 0;
	for(new i = 0; i < MAXPLAYERS; i++) spnum[i] = 0;

	new String:name[128]; 
	new entCount = GetEntityCount();
	pointsnum[0] = 0; pointsnum[1] = 0;
	for (new b=1; b<entCount; b++) 
	{ 
		if (IsValidEntity(b) && IsValidEdict(b)) 
		{ 
			GetEntPropString(b, Prop_Data, "m_iClassname", name, sizeof(name));  
			if (StrEqual(name, "info_player_terrorist") && pointsnum[0] >= 40) 
			{
				spawnpoints[0][pointsnum[0]] = b;
				++pointsnum[0];
			} 
			if (StrEqual(name, "info_player_counterterrorist") && pointsnum[1] >= 40) 
			{
				spawnpoints[1][pointsnum[1]] = b;
				++pointsnum[1];
			} 
		} 
	} 
}
public OnPluginStart()
{
	HookEvent("player_spawn", EventPlayerSpawn, EventHookMode_Post);
	HookEvent("round_start", Event_RoundStart);
}
public  Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(new i = 0; i < MAXPLAYERS; i++) spnum[i] = 0;
}
public Action:EventPlayerSpawn(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,  "userid"));
	if (spnum[client] == 0) ++spnum[client];
	else CreateTimer(0.1,PlayerRespawn, client);
}
public Action:PlayerRespawn(Handle:timer, any:client)
{
	new team = GetClientTeam(client); new point;
	if (team == 2) point = GetRandomInt(0, pointsnum[0] - 1); //t
	if (team == 3) point = GetRandomInt(0, pointsnum[1] - 1); //ct

	new Float:vOrigin[3]; 
	new Float:vAngel[3]; 
	GetEntPropVector(point, Prop_Send, "m_vecOrigin", vOrigin); 
	GetEntPropVector(point, Prop_Send, "m_angRotation", vAngel);

	TeleportEntity(client, vOrigin, vAngel, NULL_VECTOR);
}