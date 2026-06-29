#pragma semicolon 1
#include <sdktools>
#include <sourcemod>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.31"
#define spirite "spirites/zerogxplode.spr"

new Handle:g_Enabled = INVALID_HANDLE;
new Handle:g_Dmg = INVALID_HANDLE;
new Handle:g_Radius = INVALID_HANDLE;
new Handle:g_Join = INVALID_HANDLE;
//new Handle:g_Flag = INVALID_HANDLE;
new Handle:g_Type = INVALID_HANDLE;
new Handle:g_Delay = INVALID_HANDLE;

new Float:g_pos[3];
new Float:deathpos[MAXPLAYERS + 1][3];
new bool:g_Arrows[MAXPLAYERS+1];

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) {
	new String:Game[32];
	GetGameFolderName(Game, sizeof(Game));
	if(!StrEqual(Game, "tf")) {
		Format(error, err_max, "This plugin only works for Team Fortress 2");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

public Plugin:myinfo = {
	name = "[TF2] Explosive Arrows",
	author = "Tak (Chaosxk)",
	description = "Are your arrows too weak? Buff them up!",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=203146"
}

public OnPluginStart() {
	CreateConVar("explarrows_version", PLUGIN_VERSION, "Version of this plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
//	CreateConVar("arrows_version", PLUGIN_VERSION, "Version of this plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	g_Enabled = CreateConVar("sm_explarrows_enabled", "1", "Enables/Disables explosive arrows.");
	g_Dmg = CreateConVar("sm_explarrows_damage", "50", "How much damage should the arrows do?");
	g_Radius = CreateConVar("sm_explarrows_radius", "200", "What should the radius of damage be?");
	g_Join = CreateConVar("sm_explarrows_join", "0", "Should explosive arrows be on when joined? Off = 0, Public = 1, Admins = 2");
//	g_Flag = CreateConVar("sm_explarrows_flag", "b", "What admin flag should be associated with sm_explarrowsme and sm_explarrows_join?");
	g_Type = CreateConVar("sm_explarrows_type", "0", "What type of arrows to explode? (0 - Both, 1 - Huntsman arrows, 2 - Crusader's crossbow bolts");
	g_Delay = CreateConVar("sm_explarrows_delay", "0", "Delay before arrow explodes");

	RegConsoleCmd("sm_explarrowsme", Command_ArrowsMe, "Turn on explosive arrows for yourself.");
	RegAdminCmd("sm_explarrows", Command_Arrows, ADMFLAG_GENERIC, "Usage: sm_explarrows <client> <On: 1 ; Off = 0>.");

//	HookEvent("player_spawn", Player_Spawn);
	HookEvent("player_death", Player_Death);

	LoadTranslations("common.phrases");
	AutoExecConfig(true, "explosivearrows");
}

public OnMapStart() {
	PrecacheModel(spirite, true);
}

public Action:Player_Death(Handle:event, const String:name[], bool:dontBroadcast) {
	if (!g_Enabled)
		return;
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsValidClient(client))
		return;
	GetClientAbsOrigin(client, deathpos[client]);
}
public OnClientPostAdminCheck(client) {
	g_Arrows[client] = false;
	deathpos[client][0] = 0.0;
	deathpos[client][1] = 0.0;
	deathpos[client][2] = 0.0;
	new joincvar = GetConVarInt(g_Join);
	switch (joincvar) {
		case 2: {
			g_Arrows[client] = CheckCommandAccess(client, "sm_explarrows_join_access", ADMFLAG_GENERIC, true);
		}
		case 1: {
			g_Arrows[client] = true;
		}
	}
}
public Action:Command_ArrowsMe(client, args) {
	if(!g_Enabled)
		return Plugin_Handled;
	if(!IsValidClient(client))
		return Plugin_Handled;
	g_Arrows[client] = !g_Arrows[client];
	ReplyToCommand(client, "[SM] You have %s explosive arrows.", g_Arrows[client] ? "enabled" : "disabled");
	return Plugin_Handled;
}

public Action:Command_Arrows(client, args) {
	if(!g_Enabled)
		return Plugin_Handled;
	if(!IsValidClient(client))
		return Plugin_Handled;
	decl String:arg1[65], String:arg2[65];

	if(args < 2) {
		ReplyToCommand(client, "Usage: sm_explarrows <client> <On: 1 ; Off = 0>");
		return Plugin_Handled;
	}

	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	new bool:button = !!StringToInt(arg2);

	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	if((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_CONNECTED,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for(new i = 0; i < target_count; i++) {
		g_Arrows[target_list[i]] = button;
	}
	if (tn_is_ml)
		ShowActivity2(client, "[SM] ", "%N has %s %t explosive arrows.", client, button ? "given" : "removed", target_name);
	else
		ShowActivity2(client, "[SM] ", "%N has %s %s explosive arrows.", client, button ? "given" : "removed", target_name);
	return Plugin_Handled;
}

public OnEntityCreated(entity, const String:classname[]) {
	if(!g_Enabled)
		return;
	new bool:arrow = StrEqual(classname, "tf_projectile_arrow");
	new bool:bolt = StrEqual(classname, "tf_projectile_healing_bolt");
	if (!bolt && !arrow)
		return;
	new type = GetConVarInt(g_Type);
	if (!type || (type == 1 && arrow) || (type == 2 && bolt)) {
		SDKHook(entity, SDKHook_StartTouchPost, OnEntityTouch);
	}
}

public Action:OnEntityTouch(entity, other) {
	new client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	new Float:pos2[3];
	if(!IsValidClient(client))
		return Plugin_Continue;
	if(!g_Arrows[client])
		return Plugin_Continue;
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", g_pos);
	if (other > 0 && other <= MaxClients)
		GetClientAbsOrigin(other, pos2);
	new Handle:pack;
	CreateDataTimer(GetConVarFloat(g_Delay), Timer_Explode, pack, TIMER_FLAG_NO_MAPCHANGE);
	WritePackCell(pack, GetClientUserId(client));
	WritePackCell(pack, (other > 0 && other <= MaxClients) ? GetClientUserId(other) : INVALID_ENT_REFERENCE);
	WritePackCell(pack, (other > 0 && other <= MaxClients) ? GetEntProp(other, Prop_Send, "m_iDeaths") : 0);
	WritePackFloat(pack, g_pos[0]);
	WritePackFloat(pack, g_pos[1]);
	WritePackFloat(pack, g_pos[2]);
	WritePackFloat(pack, pos2[0]);
	WritePackFloat(pack, pos2[1]);
	WritePackFloat(pack, pos2[2]);
	return Plugin_Continue;
}
public Action:Timer_Explode(Handle:timer, Handle:pack) {
	ResetPack(pack);
	decl Float:pos1[3];
	decl Float:pos2[3];
	new client = GetClientOfUserId(ReadPackCell(pack));
	new victim = GetClientOfUserId(ReadPackCell(pack));
	new deaths = ReadPackCell(pack);
	pos1[0] = ReadPackFloat(pack);
	pos1[1] = ReadPackFloat(pack);
	pos1[2] = ReadPackFloat(pack);
	pos2[0] = ReadPackFloat(pack);
	pos2[1] = ReadPackFloat(pack);
	pos2[2] = ReadPackFloat(pack);
	if (victim > 0 && victim <= MaxClients && IsClientInGame(victim) && IsPlayerAlive(victim)) {
		if (deaths < GetEntProp(victim, Prop_Send, "m_iDeaths")) { 	//should probably use spawncount instead but whatever
			pos2[0] = deathpos[victim][0];
			pos2[1] = deathpos[victim][1];
			pos2[2] = deathpos[victim][2];
		}
		SubtractVectors(pos1, pos2, pos1);	//somebody please doublecheck that this gets relative position correctly. It *should* but I might have negated it accidentally
		GetClientAbsOrigin(victim, pos2);
		AddVectors(pos1, pos2, pos1);
	}
	DoExplosion(client, GetConVarInt(g_Dmg), GetConVarInt(g_Radius), pos1);
}
stock DoExplosion(owner, damage, radius, Float:pos[3]) {
	new explode = CreateEntityByName("env_explosion");
	if(!IsValidEntity(explode))
		return;
	DispatchKeyValue(explode, "targetname", "explode");
	DispatchKeyValue(explode, "spawnflags", "2");
	DispatchKeyValue(explode, "rendermode", "5");
	DispatchKeyValue(explode, "fireballsprite", spirite);

	SetEntPropEnt(explode, Prop_Data, "m_hOwnerEntity", owner);
	SetEntProp(explode, Prop_Data, "m_iMagnitude", damage);
	SetEntProp(explode, Prop_Data, "m_iRadiusOverride", radius);

	TeleportEntity(explode, pos, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(explode);
	ActivateEntity(explode);
	AcceptEntityInput(explode, "Explode");
	AcceptEntityInput(explode, "Kill");
}
stock bool:IsValidClient(iClient, bool:bReplay = true) {
	if(iClient <= 0 || iClient > MaxClients)
		return false;
	if(!IsClientInGame(iClient))
		return false;
	if(bReplay && (IsClientSourceTV(iClient) || IsClientReplay(iClient)))
		return false;
	return true;
}