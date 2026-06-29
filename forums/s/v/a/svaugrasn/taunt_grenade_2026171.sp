#pragma semicolon 1;

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.0"

new LastUsed[MAXPLAYERS+1] = { 0, ... };

new Handle:g_time = INVALID_HANDLE;
new Handle:g_explode_time = INVALID_HANDLE;
new Handle:g_radius = INVALID_HANDLE;
new Handle:g_damage = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "Taunt Grenade",
	author = "svaugrasn",
	description = "",
	version = PLUGIN_VERSION,
	url = ""
}

public OnPluginStart()
{
	AddCommandListener(Listener_Command, "taunt");
	AddCommandListener(Listener_Command, "+taunt");

	g_time = CreateConVar("sm_grenade_time", "8", "Time between use grenade");
	g_explode_time = CreateConVar("sm_grenade_explode_time", "3.0", "Explode time");
	g_radius = CreateConVar("sm_grenade_radius", "150.0", "Explosion radius");
	g_damage = CreateConVar("sm_grenade_damage", "35", "Explosion Damage");

}

public OnMapStart(){
	PrecacheSound("player/taunt_shake_it.wav");
	PrecacheModel("models/player/gibs/gibs_duck.mdl");
}

public Action:Listener_Command(client, const String:command[], args)
{
	Command_Grenade(client, 0);
}

public Action:Command_Grenade(client, args)
{
	new currentTime = GetTime();
	if (currentTime - LastUsed[client] < GetConVarInt(g_time) || !IsValidEdict(client) || !IsClientConnected(client) || !IsPlayerAlive(client)) return Plugin_Handled;
	LastUsed[client] = currentTime;

	EmitSoundToAll("player/taunt_shake_it.wav", client);

	new duck = CreateEntityByName("prop_physics_override");
	if (IsValidEntity(duck)){
		SetEntityModel(duck, "models/player/gibs/gibs_duck.mdl");
		SetEntityMoveType(duck, MOVETYPE_VPHYSICS);
		SetEntProp(duck, Prop_Send, "m_CollisionGroup", 1);
		SetEntProp(duck, Prop_Send, "m_usSolidFlags", 16);
		DispatchSpawn(duck);

		new rint = GetRandomInt(0,100);
		decl Float:pos[3];
		decl Float:vecAngles[3], Float:vecVelocity[3];
		GetClientEyeAngles(client, vecAngles);
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", vecVelocity);
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
		pos[2] += 30;
		vecAngles[0] = DegToRad(vecAngles[0]);
		vecAngles[1] = DegToRad(vecAngles[1]);
		vecVelocity[0] = 450 * Cosine(vecAngles[0]) * Cosine(vecAngles[1]) + rint;
		vecVelocity[1] = 450 * Cosine(vecAngles[0]) * Sine(vecAngles[1]) + rint;
		vecVelocity[2] = 300.0 + rint;
		TeleportEntity(duck, pos, NULL_VECTOR, vecVelocity);

		new entid = EntIndexToEntRef(duck);

		new Handle:h_Pack;
		new String:entid_Str[64];
		IntToString(entid, entid_Str, sizeof(entid_Str));
		CreateDataTimer(GetConVarFloat(g_explode_time), ExplodeDuck, h_Pack);
		WritePackCell(h_Pack, client);
		WritePackString(h_Pack, entid_Str);
	}

	return Plugin_Continue;

}

public Action:ExplodeDuck(Handle:timer, Handle:h_Pack)
{
	new String:entid_Str[64], client;

	ResetPack(h_Pack);
	client = ReadPackCell(h_Pack);
	ReadPackString(h_Pack, entid_Str, sizeof(entid_Str));

	new entid = StringToInt(entid_Str);
	new ent = EntRefToEntIndex(entid);

	if (IsValidEdict(ent))
	{
		if (ent>MaxClients)
			AcceptEntityInput(ent, "Kill");

		new explosion = CreateEntityByName("env_explosion");
		new Float:duckPos[3];
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", duckPos);
		if (explosion)
		{
			DispatchSpawn(explosion);
			TeleportEntity(explosion, duckPos, NULL_VECTOR, NULL_VECTOR);
			AcceptEntityInput(explosion, "Explode", -1, -1, 0);
			RemoveEdict(explosion);
		}
		for (new i = 1; i <= MaxClients; i++)
		{
			if(IsValidEdict(i) && IsClientConnected(i) && IsPlayerAlive(i))
			{
				new Float:iPos[3];
				GetClientAbsOrigin(i, iPos);
				new Float:Dist = GetVectorDistance(duckPos, iPos);
				if (Dist > GetConVarFloat(g_radius)) continue;
				DoDamage(client, i, GetConVarInt(g_damage));
			}
		}

	}

}

stock DoDamage(client, target, amount) // from Goomba Stomp.
{
	new pointHurt = CreateEntityByName("point_hurt");
	if (pointHurt)
	{
		DispatchKeyValue(target, "targetname", "explodeme");
		DispatchKeyValue(pointHurt, "DamageTarget", "explodeme");
		new String:dmg[15];
		Format(dmg, 15, "%i", amount);
		DispatchKeyValue(pointHurt, "Damage", dmg);
		DispatchKeyValue(pointHurt, "DamageType", "0");

		DispatchSpawn(pointHurt);
		AcceptEntityInput(pointHurt, "Hurt", client);
		DispatchKeyValue(pointHurt, "classname", "point_hurt");
		DispatchKeyValue(target, "targetname", "");
		RemoveEdict(pointHurt);
	}
}