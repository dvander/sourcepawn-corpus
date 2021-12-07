#pragma semicolon 1

#include <sourcemod>
#include <sdktools_functions>
#include <sdktools_entinput>
#include <sdktools_entoutput>

public Plugin:myinfo = 
{
	name	= "Fire Effect",
	author	= "wS / Schmidt",
	version	= "1.0",
	url		= "http://world-source.ru/"
};

enum FireEffectValue
{
	Float:wS_start_pos[3],
	Float:wS_direction[3],
	Float:wS_end_pos_dist,
	Float:wS_move_speed,
	Float:wS_rotator_speed,
	Float:wS_fire_dist,
	Float:wS_life
};

new Float:g_Effect[101][FireEffectValue];
new g_EffectCount;

public OnPluginStart()
{
	HookEvent("round_start", round_start, EventHookMode_PostNoCopy);
}


///


public OnMapStart()
{
	g_EffectCount = 0;

	decl String:Info[150]; GetCurrentMap(Info, 150);
	new Handle:kv = CreateKeyValues(Info);
	Format(Info, 150, "cfg/fire_effect/%s.txt", Info);
	if (!FileToKeyValues(kv, Info) || !KvGotoFirstSubKey(kv, true))
	{
		CloseHandle(kv);
		return;
	}
	new X = 0;
	decl Float:coords[3];
	do
	{
		X++;

		KvGetVector(kv, "start_pos",	coords); g_Effect[X][wS_start_pos] = coords;
		KvGetVector(kv, "direction",	coords); g_Effect[X][wS_direction] = coords;
		g_Effect[X][wS_end_pos_dist]	= KvGetFloat(kv, "end_pos_dist");
		g_Effect[X][wS_move_speed]		= KvGetFloat(kv, "move_speed");
		g_Effect[X][wS_rotator_speed]	= KvGetFloat(kv, "rotator_speed");
		g_Effect[X][wS_fire_dist]		= KvGetFloat(kv, "fire_dist");
		g_Effect[X][wS_life]			= KvGetFloat(kv, "life");

		if (X > 99)						break;
	}
	while (KvGotoNextKey(kv, true));
	CloseHandle(kv);

	g_EffectCount = X;
}


///


public round_start(Handle:event, const String:name[], bool:silent)
{
	if (g_EffectCount < 1)
		return;

	decl ent_move, ent_rotr, ent_fire;
	decl String:MovelinearName[25], String:RotatorName[25], String:OutputCmd[55];
	decl Float:coords[3];
	for (new i = 1; i <= g_EffectCount; i++)
	{
		if ((ent_move = CreateEntityByName("func_movelinear")) < 1)
			continue;

		if ((ent_rotr = CreateEntityByName("func_rotating")) < 1)
		{
			AcceptEntityInput(ent_move,		"Kill");
			continue;
		}

		if ((ent_fire = CreateEntityByName("env_fire_trail")) < 1)
		{
			AcceptEntityInput(ent_move,		"Kill");
			AcceptEntityInput(ent_rotr,		"Kill");
			continue;
		}

		// func_movelinear
		Format(MovelinearName,	25,			"mvlnr_%d",			ent_move);
		DispatchKeyValue(ent_move,			"targetname",		MovelinearName);
		coords[0] = g_Effect[i][wS_start_pos][0];
		coords[1] = g_Effect[i][wS_start_pos][1];
		coords[2] = g_Effect[i][wS_start_pos][2];
		DispatchKeyValueVector(ent_move,	"origin",			coords);
		coords[0] = g_Effect[i][wS_direction][0];
		coords[1] = g_Effect[i][wS_direction][1];
		coords[2] = g_Effect[i][wS_direction][2];
		DispatchKeyValueVector(ent_move,	"movedir",			coords);
		DispatchKeyValueFloat(ent_move,		"BlockDamage",		0.0);
		DispatchKeyValueFloat(ent_move,		"StartPosition",	0.0);
		DispatchKeyValueFloat(ent_move,		"MoveDistance",		g_Effect[i][wS_end_pos_dist]);
		SetEntPropFloat(ent_move,			Prop_Data,			"m_flSpeed",	g_Effect[i][wS_move_speed]);
		DispatchKeyValue(ent_move,			"spawnflags",		"8");
		DispatchSpawn(ent_move);

		// func_rotating
		Format(RotatorName,		25,			"rttr_%d",			ent_rotr);
		DispatchKeyValue(ent_rotr,			"targetname",		RotatorName);
		coords[0] = g_Effect[i][wS_start_pos][0];
		coords[1] = g_Effect[i][wS_start_pos][1];
		coords[2] = g_Effect[i][wS_start_pos][2];
		DispatchKeyValueVector(ent_rotr,	"origin",			coords);
		DispatchKeyValue(ent_rotr,			"spawnflags",		"64");
		DispatchKeyValue(ent_rotr,			"friction",			"20");
		SetEntPropFloat(ent_rotr,			Prop_Data,			"m_flMaxSpeed",	g_Effect[i][wS_rotator_speed]);
		DispatchKeyValue(ent_rotr,			"dmg",				"0");
		DispatchKeyValue(ent_rotr,			"solid",			"0");
		DispatchSpawn(ent_rotr);
		SetVariantString(MovelinearName);
		AcceptEntityInput(ent_rotr,			"SetParent");

		// env_fire_trail
		coords[1] += g_Effect[i][wS_fire_dist];
		DispatchKeyValueVector(ent_fire,	"origin",			coords);
		DispatchKeyValue(ent_fire,			"solid",			"0");
		DispatchSpawn(ent_fire);
		SetVariantString(RotatorName);
		AcceptEntityInput(ent_fire,			"SetParent");

		AcceptEntityInput(ent_move,			"Open");
		AcceptEntityInput(ent_rotr,			"Start");

		HookSingleEntityOutput(ent_move,	"OnFullyOpen",		OnFullyOpen);
		HookSingleEntityOutput(ent_move,	"OnFullyClosed",	OnFullyClosed);

		if (g_Effect[i][wS_life] > 0.9)
		{
			Format(OutputCmd, 55, "OnUser1 !self:kill::%f:1", g_Effect[i][wS_life]); SetVariantString(OutputCmd);
			AcceptEntityInput(ent_move, "AddOutput"); AcceptEntityInput(ent_move, "FireUser1");
		}
	}
}


///


public OnFullyOpen(const String:output[],	caller, activator, Float:delay) AcceptEntityInput(caller, "Close");
public OnFullyClosed(const String:output[],	caller, activator, Float:delay) AcceptEntityInput(caller, "Open");
