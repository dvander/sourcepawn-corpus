#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#define PLUGIN_VERSION		"1.0.0"

ConVar bEnabled, cvUber;

float vecSpawns[2][3];	// 0 for red, 1 for blue

public void OnPluginStart()
{
	bEnabled = CreateConVar("sm_teamporter_enable", "1", "Enable the TF2 Teamporter plugin?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvUber = CreateConVar("sm_teamporter_uber", "3.0", "Seconds to add ubercharge after teleportation. 0 to disable", FCVAR_NOTIFY, true, 0.0);
	CreateConVar("sm_teamporter_version", PLUGIN_VERSION, "TF2 Teamporter plugin version", FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_SPONLY | FCVAR_DONTRECORD);

	AutoExecConfig(true, "TF2 Teamporters");

	HookEvent("player_spawn", OnPlayerSpawn);
	HookEvent("teamplay_round_start", OnNeedReset);
	HookEvent("teamplay_point_captured", OnNeedReset);
}

public void OnNeedReset(Event event, const char[] name, bool dontBroadcast)
{
	int spawnteam, ent = -1;
	ArrayList redspawn = new ArrayList();
	ArrayList bluspawn = new ArrayList();

	while ((ent = FindEntityByClassname(ent, "info_player_teamspawn")) != -1)
	{
		spawnteam = GetEntProp(ent, Prop_Send, "m_iTeamNum");
		if (spawnteam == 2)	// Push ents to according team arraylist
			redspawn.Push(ent);
		else if (spawnteam == 3)
			bluspawn.Push(ent);
	}

	ent = redspawn.Get( GetRandomInt(0, redspawn.Length-1) );	// This may be an issue on custom maps with wacky spawn locations, so random one will do
	GetEntPropVector(ent, Prop_Send, "m_vecOrigin", vecSpawns[0]);
	ent = bluspawn.Get( GetRandomInt(0, bluspawn.Length-1) );
	GetEntPropVector(ent, Prop_Send, "m_vecOrigin", vecSpawns[1]);

	delete redspawn;
	delete bluspawn;
}

public Action OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if (!bEnabled.BoolValue)
		return Plugin_Continue;

	int client = GetClientOfUserId(event.GetInt("userid"));
	int team = GetClientTeam(client);

	if (team <= 1)
		return Plugin_Continue;

	int ent = -1;
	float vecSpawn[3];
	float vecIsActuallyGoingToSpawn[3] = {-9999.0, -9999.0, -9999.0};
	float dist, otherdist = GetVectorDistance(vecIsActuallyGoingToSpawn, vecSpawns[team == 2 ? 1 : 0]);
	float vecRotation[3];

	while ((ent = FindEntityByClassname(ent, "obj_teleporter")) != -1)
	{
		if (GetEntProp(ent, Prop_Send, "m_iTeamNum") != team)
			continue;
		if (GetEntProp(ent, Prop_Send, "m_bBuilding"))	// If being built
			continue;
		if (GetEntProp(ent, Prop_Send, "m_bCarried"))	// If being carried
			continue;
		if (GetEntProp(ent, Prop_Send, "m_iObjectMode") != 1)	// If not exit
			continue;
		if (!IsValidEntity(GetEntDataEnt2(ent, FindSendPropInfo("CObjectTeleporter", "m_bMatchBuilding")+4)))	// Props to Pelipoika
			continue;

		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", vecSpawn);
		dist = GetVectorDistance(vecSpawn, vecSpawns[team-2]);
		if (dist < otherdist)
		{
			otherdist = dist;
			vecIsActuallyGoingToSpawn = vecSpawn;
			GetEntPropVector(ent, Prop_Send, "m_angRotation", vecRotation);	// Force players to look in the direction of teleporter on spawn
		}
	}
	if (GetVectorDistance(vecIsActuallyGoingToSpawn, vecSpawns[team == 2 ? 1 : 0]) >= 7000)	// If no teleporters found
		return Plugin_Continue;

	vecIsActuallyGoingToSpawn[2] += 15.0;	// Don't get stuck inside of teleporter
	TeleportEntity(client, vecIsActuallyGoingToSpawn, vecRotation, NULL_VECTOR);

	float oober = cvUber.FloatValue;
	if (oober != 0.0)
		TF2_AddCondition(client, TFCond_Ubercharged, oober);
	return Plugin_Continue;
}
