/* ----- Global Includes ----- */
#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#include <tf2>
#include <sdkhooks>

/* ----- Enable Strict Semicolon Bread ----- */
#pragma semicolon 1

#define PLUGIN_VERSION "1.0"

/* ----- BREAD! ----- */
#define Bread1 "models/weapons/c_models/c_bread/c_bread_baguette.mdl"
#define Bread2 "models/weapons/c_models/c_bread/c_bread_burnt.mdl"
#define Bread3 "models/weapons/c_models/c_bread/c_bread_cinnamon.mdl"
#define Bread4 "models/weapons/c_models/c_bread/c_bread_cornbread.mdl"
#define Bread5 "models/weapons/c_models/c_bread/c_bread_crumpet.mdl"
#define Bread6 "models/weapons/c_models/c_bread/c_bread_plainloaf.mdl"
#define Bread7 "models/weapons/c_models/c_bread/c_bread_pretzel.mdl"
#define Bread8 "models/weapons/c_models/c_bread/c_bread_ration.mdl"
#define Bread9 "models/weapons/c_models/c_bread/c_bread_russianblack.mdl"

//new Handle:hSetAmmoVelocity;

/* ----- Bread Information ----- */
public Plugin:myinfo =
{
	name = "BREAD BREAD BREAD BREAD",
	author = "abrandnewday",
	description = "BREAAAAAAD",
	version = PLUGIN_VERSION
}

public OnPluginStart()
{
	CreateConVar("sm_bread_version", PLUGIN_VERSION, "Bread Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	RegAdminCmd("sm_bread", Command_BreadBreadBread, ADMFLAG_GENERIC, "bread bread bread i love bread do you love bread i hope you do");
	
}

/* ----- Bread Has Started ----- */
public OnMapStart()
{
	PrecacheModel(Bread1);
	PrecacheModel(Bread2);
	PrecacheModel(Bread3);
	PrecacheModel(Bread4);
	PrecacheModel(Bread5);
	PrecacheModel(Bread6);
	PrecacheModel(Bread7);
	PrecacheModel(Bread8);
	PrecacheModel(Bread9);
}

/* ----- Spawn much bread ----- */
public Action:Command_BreadBreadBread(client, args)
{
	SpawnMuchBread(client, Bread1, 1);
	SpawnMuchBread(client, Bread2, 1);
	SpawnMuchBread(client, Bread3, 1);
	SpawnMuchBread(client, Bread4, 1);
	SpawnMuchBread(client, Bread5, 1);
	SpawnMuchBread(client, Bread6, 1);
	SpawnMuchBread(client, Bread7, 1);
	SpawnMuchBread(client, Bread8, 1);
	SpawnMuchBread(client, Bread9, 1);
}

/* ----- dis spawns da bread ----- */
stock SpawnMuchBread(client, String:model[], skin=0, num=1, Float:offsz = 30.0)
{
	decl Float:pos[3], Float:vel[3], Float:ang[3];
	ang[0] = 90.0;
	ang[1] = 0.0;
	ang[2] = 0.0;
	GetClientAbsOrigin(client, pos);
	pos[2] += offsz;
	for (new i = 0; i < num; i++)
	{
		vel[0] = GetRandomFloat(-400.0, 400.0);
		vel[1] = GetRandomFloat(-400.0, 400.0);
		vel[2] = GetRandomFloat(300.0, 500.0);
		pos[0] += GetRandomFloat(-5.0, 5.0);
		pos[1] += GetRandomFloat(-5.0, 5.0);
		new ent = CreateEntityByName("tf_ammo_pack");
		if (!IsValidEntity(ent)) continue;
		SetEntityModel(ent, model);
		DispatchKeyValue(ent, "OnPlayerTouch", "!self,Kill,,0,-1");	//for safety, but it shouldn't act like a normal ammopack
		SetEntProp(ent, Prop_Send, "m_nSkin", skin);
		SetEntProp(ent, Prop_Send, "m_nSolidType", 6);
		SetEntProp(ent, Prop_Send, "m_usSolidFlags", 152);
		SetEntProp(ent, Prop_Send, "m_triggerBloat", 24);
		SetEntProp(ent, Prop_Send, "m_CollisionGroup", 1);
		SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client);
		SetEntProp(ent, Prop_Send, "m_iTeamNum", 2);
		TeleportEntity(ent, pos, ang, vel);
		DispatchSpawn(ent);
		TeleportEntity(ent, pos, ang, vel);
		SetEntProp(ent, Prop_Data, "m_iHealth", 900);
		new offs = GetEntSendPropOffs(ent, "m_vecInitialVelocity", true);
		SetEntData(ent, offs-4, 1, _, true);
	}
}