#pragma semicolon 1;

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.2.0"


public Plugin:myinfo =
{
	name = "Dispenser Here",
	author = "svaugrasn",
	description = "",
	version = PLUGIN_VERSION,
	url = ""
}

new String:voicemenu1[4];
new String:voicemenu2[4];

new LastUsed[MAXPLAYERS+1] = { 0, ... };	// from http://forums.alliedmods.net/showthread.php?t=204626
new Building[MAXPLAYERS+1] = { 0, ... };	// from http://forums.alliedmods.net/showthread.php?t=204626


new Handle:g_blueprint = INVALID_HANDLE;
new Handle:g_restriction = INVALID_HANDLE;
new Handle:g_remove = INVALID_HANDLE;
new Handle:g_limit = INVALID_HANDLE;

new Handle:g_admin = INVALID_HANDLE;

public OnPluginStart()
{
	RegConsoleCmd("voicemenu", Command_Voicemenu);

	g_blueprint = CreateConVar("sm_disp_blueprint", "1", "Enable/Disable the blueprint");
	g_restriction = CreateConVar("sm_disp_time", "1", "Time between spawn the model");
	g_remove = CreateConVar("sm_disp_remove", "10.0", "Time to remove the model");

	g_limit = CreateConVar("sm_disp_limit", "0", "building per person. 0 to disable checking.");
	g_admin = CreateConVar("sm_disp_admin", "0", "Enable/disable Admin flag check");
}

public OnMapStart(){
	PrecacheModel("models/buildables/teleporter.mdl");
	PrecacheModel("models/buildables/dispenser_lvl3.mdl");
	PrecacheModel("models/buildables/sentry3.mdl");
	PrecacheModel("models/buildables/teleporter_blueprint_enter.mdl.mdl");
	PrecacheModel("models/buildables/dispenser_blueprint.mdl");
	PrecacheModel("models/buildables/sentry1_blueprint.mdl");


	for(new i = 1; i <= MaxClients; i++)
	{
		Building[i] = 0;
	}

}

public Action:Command_Voicemenu(client, args)
{
	if(IsPlayerAlive(client))
	{
		GetCmdArg(1, voicemenu1, sizeof(voicemenu1));
		GetCmdArg(2, voicemenu2, sizeof(voicemenu2));
		
		if(StringToInt(voicemenu1) == 1)		// http://forums.alliedmods.net/showpost.php?p=2026382&postcount=7
		{
			new type = StringToInt(voicemenu2);
			if(type >= 3 && type <= 5)
			{
				Command_Prop(client, type-3);
			}
		}
	}
}

public Action:Command_Prop(client, args)
{
	new currentTime = GetTime();
	if (currentTime - LastUsed[client] < GetConVarInt(g_restriction)) return Plugin_Handled;
	LastUsed[client] = currentTime;

	if(GetConVarInt(g_admin) == 1 && !(GetUserFlagBits(client) & ADMFLAG_GENERIC)) return Plugin_Handled;
	if(GetConVarInt(g_limit) != 0 && Building[client] >= GetConVarInt(g_limit)) return Plugin_Handled;

	Building[client]++;

	decl String:Prop_Model[64];
	decl String:Prop_Model_Blueprint[64];
	if(args == 0){
		Prop_Model = "models/buildables/teleporter.mdl";
		Prop_Model_Blueprint = "models/buildables/teleporter_blueprint_enter.mdl";
	}
	if(args == 1){
		Prop_Model = "models/buildables/dispenser_lvl3.mdl";
		Prop_Model_Blueprint = "models/buildables/dispenser_blueprint.mdl";
	}
	if(args == 2){
		Prop_Model = "models/buildables/sentry3.mdl";
		Prop_Model_Blueprint = "models/buildables/sentry1_blueprint.mdl";
	}

	new prop = CreateEntityByName("prop_physics_override");
	if (IsValidEntity(prop)){
		SetEntityModel(prop, Prop_Model);
		SetEntityMoveType(prop, MOVETYPE_VPHYSICS);
		SetEntProp(prop, Prop_Send, "m_CollisionGroup", 1);
		SetEntProp(prop, Prop_Send, "m_usSolidFlags", 16);
		DispatchSpawn(prop);

		decl Float:pos[3];
		decl Float:vecVelocity[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
		pos[2]+=30;
		vecVelocity[0] = 0.0;
		vecVelocity[1] = 0.0;
		vecVelocity[2] = 500.0;
		TeleportEntity(prop, pos, NULL_VECTOR, vecVelocity);

		CreateTimer(GetConVarFloat(g_remove), RemoveEnt, EntIndexToEntRef(prop));
	}

	if (GetConVarBool(g_blueprint)){
		new prop2 = CreateEntityByName("prop_physics_override");
		if (IsValidEntity(prop2)){
			SetEntityModel(prop2, Prop_Model_Blueprint);
			SetEntityMoveType(prop2, MOVETYPE_NONE);
			DispatchSpawn(prop2);
	
			decl Float:pos[3];
			GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
			TeleportEntity(prop2, pos, NULL_VECTOR, NULL_VECTOR);
	
			CreateTimer(GetConVarFloat(g_remove), RemoveEnt, EntIndexToEntRef(prop2));
		}
	}

	return Plugin_Handled;

}

public Action:RemoveEnt(Handle:timer, any:entid)	// from ff2_1st_set_abilities.
{
	new ent=EntRefToEntIndex(entid);
	if (IsValidEdict(ent))
	{
		if (ent>MaxClients)
			AcceptEntityInput(ent, "Kill");
	}
}