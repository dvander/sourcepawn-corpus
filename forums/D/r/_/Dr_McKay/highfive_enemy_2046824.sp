#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.3"

public Plugin:myinfo =
{
	name = "[TF2] High Five Enemies",
	author = "FlaminSarge",
	description = "Because it works.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

new Handle:spawnRadius;

public OnPluginStart()
{
	spawnRadius = CreateConVar("highfiveenemy_spawnradius", "100", "Enemies cannot high-five this close to a spawn door");
	CreateConVar("highfiveenemy_version", PLUGIN_VERSION, "[TF2] High Five Enemies version", FCVAR_NOTIFY|FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_PLUGIN);
	AddCommandListener(Taunt, "+taunt");
	AddCommandListener(Taunt, "taunt");
	AddCommandListener(Taunt, "+use_action_slot_item_server");
	AddCommandListener(Taunt, "use_action_slot_item_server");
}
stock bool:CheckPlayerHasActionTaunt(client)
{
	new i = -1;
	while ((i = FindEntityByClassname(i, "tf_wearable")) != -1)
	{
		if (GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity") != client || GetEntProp(i, Prop_Send, "m_bDisguiseWearable")) continue;
		new idx = GetEntProp(i, Prop_Send, "m_iItemDefinitionIndex");
		switch (idx)
		{
			case 167, 438, 463, 477: return true;
		}
	}
	return false;
}
public Action:Taunt(client, String:cmd[], args)
{
	if (client == 0)
	{
		return Plugin_Continue;
	}
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
	{
		return Plugin_Continue;
	}
	if (!(GetEntityFlags(client) & FL_ONGROUND))
	{
		return Plugin_Continue;
	}
	if (TF2_IsPlayerInCondition(client, TFCond_Taunting) || TF2_IsPlayerInCondition(client, TFCond_Cloaked) || TF2_IsPlayerInCondition(client, TFCond_Disguised) || TF2_IsPlayerInCondition(client, TFCond_Disguising))
	{
		return Plugin_Continue;
	}
	new bool:access = CheckCommandAccess(client, "highfive_enemy", 0, true);
	if (StrContains(cmd, "action_slot", false) != -1 && !CheckPlayerHasActionTaunt(client))
	{
		return Plugin_Continue;
	}
	decl Float:pos[3], Float:ang[3];
	decl Float:pos2[3], Float:ang2[3];
	decl Float:save[3];
	GetClientAbsOrigin(client, pos);
	GetClientAbsAngles(client, ang);
	for (new i = 1; i <= MaxClients; i++)
	{
		if (client == i) continue;
		if (!IsClientInGame(i)) continue;
		if (!IsPlayerAlive(i)) continue;
		if (!TF2_IsPlayerInCondition(i, TFCond_Taunting)) continue;
		if (!GetEntProp(i, Prop_Send, "m_bIsReadyToHighFive")) continue;
		if (GetClientTeam(i) == GetClientTeam(client)) continue;
		if (!CheckSpawnLocations(client, i)) continue;
		if (!access && !CheckCommandAccess(i, "highfive_enemy", 0, true)) continue;
		GetClientAbsOrigin(i, pos2);
		new Float:heightdiff = pos[2] - pos2[2];
		MakeVectorFromPoints(pos, pos2, save);
		new Float:dist = GetVectorLength(save);
		if (dist > 128) continue;
		ang2[1] = GetEntPropFloat(i, Prop_Send, "m_flTauntYaw");
		GetVectorAngles(save, save);
		if (save[1] > 180) save[1] -= 180.0;
		if (save[1] < -180) save[1] += 180.0;
		if (ang2[1] < 0) save[1] -= 180.0;
		if (save[1] > ang2[1] - 43 && save[1] < ang2[1] + 43 && heightdiff > -15 && heightdiff < 15)
		{
			new skin = GetEntProp(client, Prop_Send, "m_nSkin");
			SetEntProp(client, Prop_Send, "m_iTeamNum", GetClientTeam(i));
			SetEntProp(client, Prop_Send, "m_nSkin", skin);
			CreateTimer(0.0, Timer_ResetTeam, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);	//possibly swap this out with changeteam, FakeClientCommand(client, cmd);, changeteam, return Handled?
			break;
		} 
	}
	return Plugin_Continue;
}
public Action:Timer_ResetTeam(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (client <= 0 || !IsClientInGame(client)) return;
	new team = GetEntProp(client, Prop_Send, "m_iTeamNum");
	if (team <= _:TFTeam_Spectator) return;
	new newteam = (team == (_:TFTeam_Red) ? (_:TFTeam_Blue) : (_:TFTeam_Red));
	SetEntProp(client, Prop_Send, "m_iTeamNum", newteam);
	new flag = GetEntPropEnt(client, Prop_Send, "m_hItem");
	if (flag > MaxClients && IsValidEntity(flag))
	{
		new flagteam = GetEntProp(flag, Prop_Send, "m_iTeamNum");
		new flagtype = GetEntProp(flag, Prop_Send, "m_nType");
		switch (flagtype)
		{
			case 3, 4: if (flagteam > 1 && flagteam != newteam) AcceptEntityInput(flag, "ForceDrop");
			case 1, 2: if (flagteam < 2 || flagteam != newteam) AcceptEntityInput(flag, "ForceDrop");
			default: if (flagteam == newteam) AcceptEntityInput(flag, "ForceDrop");
		}
	}
}

bool:CheckSpawnLocations(client1, client2) {
	new Float:loc1[3], Float:loc2[3], Float:spawn[3];
	GetClientAbsOrigin(client1, loc1);
	GetClientAbsOrigin(client2, loc2);
	new radius = GetConVarInt(spawnRadius);
	
	new ent = -1;
	while((ent = FindEntityByClassname(ent, "func_respawnroomvisualizer")) != -1) {
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", spawn);
		if(GetVectorDistance(loc1, spawn) < radius || GetVectorDistance(loc2, spawn) < radius) {
			return false;
		}
	}
	
	return true;
}