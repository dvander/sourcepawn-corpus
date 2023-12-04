//Includes:
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <colors>
#include <tf2>
#include <tf2_stocks>
#pragma newdecls required

#define PLUGIN_VERSION "1.3"
#define PLAYER		  "player"

int g_piggy[MAXPLAYERS+1];
ConVar pb_method;
ConVar pb_enable;
ConVar pb_info;
ConVar g_bCvar_Piggy_AdminOnly;
char infoText[512];
int g_offsCollisionGroup;

static const char TF2Weapons[][]={"tf_weapon_fists", "tf_weapon_shovel", "tf_weapon_bat", "tf_weapon_fireaxe", "tf_weapon_bonesaw", "tf_weapon_bottle", "tf_weapon_sword", "tf_weapon_club", "tf_weapon_wrench"};	 

public Plugin myinfo = {
	name = "Piggyback",
	author = "Mecha the Slag, TonyBaretta",
	description = "Allows players to piggyback another player!",
	version = PLUGIN_VERSION,
	url = "http://mechaware.net/"
};

public void OnPluginStart() {

	Format(infoText, sizeof(infoText), "{green}You can piggyback teammates by right-clicking them with your melee out!{default} to remove piggyback press jump");
	HookEvent("player_spawn", Player_Spawn);
	HookEvent("player_death", Player_Death);
	HookEvent("teamplay_round_start", Event_Roundstart);
	g_bCvar_Piggy_AdminOnly = CreateConVar("pb_adminonly", "1", "Enable piggybacking for admin only");
	pb_method = CreateConVar("pb_method", "0", "Method to handle a piggybacking player. 1 = force view, 2 = disable shooting, 0 = do nothing (inaccurate aim)");
	pb_enable = CreateConVar("pb_enable", "1", "Enable piggybacking");
	pb_info = CreateConVar("pb_info", "120.0", "Time interval in seconds between notifications (0 for none)");
	CreateConVar("pbr_version", PLUGIN_VERSION, "Piggyback Version", FCVAR_DONTRECORD|FCVAR_NOTIFY);
	if (pb_info.FloatValue > 0.0) CreateTimer(pb_info.FloatValue, Notification);
	g_offsCollisionGroup = FindSendPropInfo("CBaseEntity", "m_CollisionGroup");
	
	for (int i = 0; i <= MaxClients; i++) {
		g_piggy[i] = -1;
	}
}

public Action Notification(Handle hTimer) {
	if (pb_info.FloatValue > 0.0) {
		if (pb_enable.BoolValue) CPrintToChatAll(infoText); 
		CreateTimer(pb_info.FloatValue, Notification);
	}
	return Plugin_Stop;
}

public void Player_Spawn(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(IsValidClient(client) && g_piggy[client]) {
		RemovePiggy(client);
	}
}
public void Event_Roundstart(Event event,const char[] name,bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++) {
		if (g_piggy[i] == i){ 
			AcceptEntityInput(i, "ClearParent");
			TF2_RespawnPlayer(i);
			g_piggy[i] = -1;
		}
	}	
}
public void Player_Death(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(IsValidClient(client) && g_piggy[client]) {
		RemovePiggy(client);
	}
	if(IsValidClient(client)){
		g_piggy[client] = -1;
	}
}
public void OnClientPutInServer(int client) {
	SDKHook(client, SDKHook_PreThink, OnPreThink);
	g_piggy[client] = -1;
}

public void OnClientDisconnect(int client)
{
	if(IsValidClient(client))
	{
		for (int iClient = 1; iClient <= MaxClients; iClient++){
			if (IsClientInGame(iClient) && g_piggy[iClient] == client){
				RemovePiggy(iClient);
			}
		}
		SDKUnhook(g_piggy[client], SDKHook_PreThink, OnPreThink);
	}
}
public Action OnPreThink(int client) {
	int iButtons = GetClientButtons(client);
	if (g_bCvar_Piggy_AdminOnly.BoolValue)
	{
		if (CheckCommandAccess(client, "piggyback_admin_override", ADMFLAG_CUSTOM1, true))
		{
			if ((iButtons & IN_ATTACK2) && (pb_enable.BoolValue)) {
				char Weapon[128];
				GetClientWeapon(client, Weapon, sizeof(Weapon));
				for (int i = 0; i < sizeof(TF2Weapons); i++) {
					if (StrEqual(Weapon,TF2Weapons[i],false)){
						TraceTarget(client);
					}
				}
			}
		}
	}
	if (!g_bCvar_Piggy_AdminOnly.BoolValue){	
		if ((iButtons & IN_ATTACK2) && (pb_enable.BoolValue)) {
			char Weapon[128];
			GetClientWeapon(client, Weapon, sizeof(Weapon));
			for (int i = 0; i < sizeof(TF2Weapons); i++) {
				if (StrEqual(Weapon,TF2Weapons[i],false)){
					TraceTarget(client);
				}
			}
		}
	}
	
	if (g_piggy[client] > -1) {
		if (pb_method.IntValue == 1) {
			float vecClientEyeAng[3];
			GetClientEyeAngles(g_piggy[client], vecClientEyeAng);
			TeleportEntity(client, NULL_VECTOR, vecClientEyeAng, NULL_VECTOR);
		}
		if (pb_method.IntValue == 2) {
			if ((iButtons & IN_ATTACK2) || (iButtons & IN_ATTACK))
			{
				iButtons &= ~IN_ATTACK;
				iButtons &= ~IN_ATTACK2;
				SetEntProp(client, Prop_Data, "m_nButtons", iButtons);
			}
		}
		if (iButtons & IN_JUMP) {
			RemovePiggy(client);
		}
		if (IsValidClient(g_piggy[client]) && !IsPlayerAlive(g_piggy[client])) {
			RemovePiggy(client);
		}
		float vPOrigin[3]; float vOrigin[3]; float vVelocity[3];
		if(g_piggy[client] > -1)
		{
			GetClientAbsOrigin(g_piggy[client], vOrigin);
			GetClientAbsOrigin(client, vPOrigin);
			vOrigin[2] += 70.0;
			GetEntPropVector(g_piggy[client], Prop_Data, "m_vecVelocity", vVelocity);
			float min[3], max[3];
			
			min[0] = vOrigin[0] - 256.0;
			min[1] = vOrigin[1] - 256.0;
			min[2] = vOrigin[2] - 128.0;
			
			max[0] = vOrigin[0] + 256.0;
			max[1] = vOrigin[1] + 256.0;
			max[2] = vOrigin[2] + 512.0; 
//			Handle trace = TR_TraceHullFilterEx(vOrigin, vPOrigin, min, max, MASK_PLAYERSOLID, TraceRayNoPlayers, client);
//			if(TR_DidHit(trace)) //|| (GetVectorDistance(vOrigin, vPOrigin) >= 2000.0)
//			{
//				RemovePiggy(client);
//				PrintToChat(client,"you are dropped to prevent you get stucked");
//				CloseHandle(trace);
//			} 
			TeleportEntity(client, vOrigin, NULL_VECTOR, vVelocity);
		}
	}
}


public int Piggy(int entity, int other) {
	//Classnames of entities
	char otherName[64];
	char classname[64];

	GetEdictClassname(entity, classname, sizeof(classname));
	GetEdictClassname(other, otherName, sizeof(otherName));
	
	if (strcmp(classname, PLAYER) == 0 && strcmp(otherName, PLAYER) == 0 && entity != other && GetClientTeam(entity) == GetClientTeam(other) && IsPlayerAlive(entity) && IsPlayerAlive(other) && (g_piggy[entity] <= -1) && (g_piggy[other] <= -1) && (g_piggy[other] != entity)) {
		if ((TF2_GetPlayerClass(other) != TFClass_Spy)) {
			float PlayerVec[3];
			float PlayerVec2[3];
			float vecClientEyeAng[3];
			float vecClientVel[3];
			vecClientVel[0] = 0.0;
			vecClientVel[1] = 0.0;
			vecClientVel[2] = 0.0;
			GetClientAbsOrigin(entity, PlayerVec2);
			GetClientAbsOrigin(other, PlayerVec);
			GetClientEyeAngles(other, vecClientEyeAng);
			float distance;
			distance = GetVectorDistance(PlayerVec2, PlayerVec, true);
			
			if(distance <= 20000.0) {
				
				if (IsPlayerAlive(other)) CPrintToChatEx(other, entity, "{teamcolor}%N{default} is on your back", entity);
				if (IsPlayerAlive(other)) CPrintToChatEx(entity, other, "You are piggybacking {teamcolor}%N{default}", other);
				SetEntData(entity, g_offsCollisionGroup, 2, 4, true);
				
				PlayerVec[2] += 20;
				TeleportEntity(entity, PlayerVec, vecClientEyeAng, vecClientVel);
				SetEntPropFloat(entity, Prop_Send, "m_flModelScale", 0.2);
				SetEntityMoveType(entity, MOVETYPE_NONE);
				
				g_piggy[entity] = other;
			}
		}
	}
}

public int RemovePiggy(int entity) {
	if(!IsValidEntity(entity))return;
	//Classnames of entities
	char classname[64];

	GetEdictClassname(entity, classname, sizeof(classname));
	
	if (strcmp(classname, PLAYER) == 0 && (g_piggy[entity] > -1)) {
	
		int other = g_piggy[entity];
	
		if (IsPlayerAlive(other)) CPrintToChatEx(other, entity, "{teamcolor}%N{default} jumped off your back", entity);

		AcceptEntityInput(entity, "SetParent", -1, -1, 0);
		SetEntityMoveType(entity, MOVETYPE_WALK);
		
		g_piggy[entity] = -1;
		
		if (IsPlayerAlive(entity)) {
			float PlayerVec[3];
			float vecClientEyeAng[3];
			float vecClientVel[3];
			vecClientVel[0] = 0.0;
			vecClientVel[1] = 0.0;
			vecClientVel[2] = 0.0;
			GetClientAbsOrigin(other, PlayerVec);
			GetClientEyeAngles(other, vecClientEyeAng); // Get the angle the player is looking
			TeleportEntity(entity, PlayerVec, NULL_VECTOR, vecClientVel);
			SetEntPropFloat(entity, Prop_Send, "m_flModelScale", 1.0);
			SetEntData(entity, g_offsCollisionGroup, 5, 4, true);
		}
	}
}

public int TraceTarget(int client) {
	char classname[64];
	float vecClientEyePos[3];
	float vecClientEyeAng[3];
	GetClientEyePosition(client, vecClientEyePos); // Get the position of the player's eyes
	GetClientEyeAngles(client, vecClientEyeAng); // Get the angle the player is looking

	//Check for colliding entities
	TR_TraceRayFilter(vecClientEyePos, vecClientEyeAng, MASK_PLAYERSOLID, RayType_Infinite, TraceRayDontHitSelf, client);

	if (TR_DidHit(INVALID_HANDLE)) {
		int TRIndex = TR_GetEntityIndex(INVALID_HANDLE);
		GetEdictClassname(TRIndex, classname, sizeof(classname));
		if (strcmp(classname, PLAYER) == 0) Piggy(client, TRIndex);
	}
}

public bool TraceRayDontHitSelf(int entity, int mask, any data) {
	if(entity == data)	{ // Check if the TraceRay hit the itself.
		return false;	// Don't let the entity be hit
	}
	return true;	// It didn't hit itself
}
stock bool IsValidClient(int client)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	return true;
}
 public bool TraceRayNoPlayers(int entity, int mask, any data) {
  if (entity == data || (entity >= 1 && entity <= MaxClients)) {
	return false;
  }
  return true;
 }