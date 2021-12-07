#pragma semicolon 1
#pragma newdecls required
//#define DEBUG

#define PLUGIN_NAME			  "[L4D/2] Incapped Pickup Items"
#define PLUGIN_AUTHOR		  "xZk"
#define PLUGIN_DESCRIPTION	  "incapped survivors can pickup items and weapons"
#define PLUGIN_VERSION		  "1.3.0"
#define PLUGIN_URL			  "https://forums.alliedmods.net/showthread.php?t=320828"

#include <sourcemod>
#include <sdktools>

ConVar g_cvarEnable;
ConVar g_cvarDistance;
ConVar g_cvarScavengeItem;

bool g_bIsOnUse[MAXPLAYERS+1];

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public void OnPluginStart()
{
	g_cvarEnable = CreateConVar("incapped_pickup", "1", "0:Disable, 1:Enable plugin");
	g_cvarDistance = CreateConVar("incapped_pickup_distance", "101.8", "Use pickup distance limit");
	g_cvarScavengeItem = CreateConVar("incapped_pickup_scavenge", "0", "0:Disable pickup scavenge items, 1:Allow pickup gascans, 2: Allow pickup colas, 3:All");
	AutoExecConfig(true, "l4d_incapped_pickup");
}

public void OnClientDisconnect_Post(int client)
{
	g_bIsOnUse[client] = false;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if(!g_cvarEnable.BoolValue)
		return Plugin_Continue;
	
	if(!IsValidSurvivor(client))
		return Plugin_Continue;
		
	if(!IsPlayerAlive(client))
		return Plugin_Continue;
		
	if(!IsPlayerIncapped(client) || IsPlayerHanding(client) || IsPlayerCapped(client))
		return Plugin_Continue;
	
	if ((buttons & IN_USE) && !g_bIsOnUse[client]) 
	{
		g_bIsOnUse[client] = true;
		float vecOrigin[3],item_pos[3];
		GetClientEyePosition(client, vecOrigin);
		int itemtarget = GetClientAimTarget(client, false);
		float distance = g_cvarDistance.FloatValue;
		if (!IsValidItemPickup(itemtarget))
			itemtarget = GetItemOnFloor(client, "weapon_*", distance);
		if (IsValidItemPickup(itemtarget))
		{
			int owneritem = GetEntPropEnt(itemtarget, Prop_Data, "m_hOwnerEntity");
			GetEntPropVector(itemtarget, Prop_Data, "m_vecAbsOrigin", item_pos);
			if ((owneritem == client || owneritem == -1) && GetVectorDistance(vecOrigin, item_pos) <= distance && IsVisibleTo(vecOrigin, item_pos)) {
				AcceptEntityInput(itemtarget, "Use", client, itemtarget);
			}
		}
	}
	else if(!(buttons & IN_USE) && g_bIsOnUse[client])
	{
		g_bIsOnUse[client] = false;
	}
	return Plugin_Continue;
}

bool IsValidItemPickup(int item){
		
	if(IsValidWeapon(item)){
		if(IsWeaponGascan(item) && (g_cvarScavengeItem.IntValue & 1)){
			return true;
		}else if(IsWeaponColaBottles(item) && (g_cvarScavengeItem.IntValue & 2)){
			return true;
		}else if(IsWeaponGascan(item) || IsWeaponColaBottles(item)){
			return false;
		}
		return true;
		
	}
	return false;
}

//https://forums.alliedmods.net/showthread.php?t=318185
int GetItemOnFloor(int client, char[] sClassname, float fDistance=101.8, float fRadius=25.0)
{
	float vecEye[3], vecTarget[3], vecDir1[3], vecDir2[3], ang[3];
	float dist, MAX_ANG_DELTA, ang_delta, ang_min = 0.0;
	int ent=-1, entity = -1;
	GetClientEyePosition(client, vecEye);
	while (-1 != (ent = FindEntityByClassname(ent, sClassname))) {
		if (!IsValidEnt(ent))
			continue;
			
		//GetEntPropVector(ent, Prop_Data, "m_vecOrigin", vecTarget);
		GetEntPropVector(ent, Prop_Data, "m_vecAbsOrigin", vecTarget);//for weapons parented
		dist = GetVectorDistance(vecEye, vecTarget);
		
		if (dist <= fDistance)
		{
			// get directional angle between eyes and target
			SubtractVectors(vecTarget, vecEye, vecDir1);
			NormalizeVector(vecDir1, vecDir1);
		
			// get directional angle of eyes view
			GetClientEyeAngles(client, ang);
			GetAngleVectors(ang, vecDir2, NULL_VECTOR, NULL_VECTOR);
			
			// get angle delta between two directional angles
			ang_delta = GetAngle(vecDir1, vecDir2); // RadToDeg
			
			MAX_ANG_DELTA = ArcTangent(fRadius / dist); // RadToDeg
			
			if (ang_delta <= MAX_ANG_DELTA)
			{
				if(ang_delta < ang_min || ang_min == 0.0)
				{
					ang_min = ang_delta;
					entity = ent;
				}
			}
		}
	}
	return entity;
}

float GetAngle(float x1[3], float x2[3]) // by Pan XiaoHai
{
	return ArcCosine(GetVectorDotProduct(x1, x2)/(GetVectorLength(x1)*GetVectorLength(x2)));
}

// credits = "AtomicStryker"
bool IsVisibleTo(float position[3], float targetposition[3])
{
	static float vAngles[3], vLookAt[3];

	MakeVectorFromPoints(position, targetposition, vLookAt); // compute vector from start to target
	GetVectorAngles(vLookAt, vAngles); // get angles from vector for trace

	// execute Trace
	static Handle trace;
	trace = TR_TraceRayFilterEx(position, vAngles, MASK_ALL, RayType_Infinite, _TraceFilter);
	
	static bool isVisible;
	isVisible = false;

	if( TR_DidHit(trace) )
	{
		static float vStart[3];
		TR_GetEndPosition(vStart, trace); // retrieve our trace endpoint

		if( (GetVectorDistance(position, vStart, false) + 25.0 ) >= GetVectorDistance(position, targetposition))
		{
			isVisible = true; // if trace ray length plus tolerance equal or bigger absolute distance, you hit the target
		}
	}
	delete trace;

	return isVisible;
}

public bool _TraceFilter(int entity, int contentsMask)
{
	if( entity <= MaxClients || !IsValidEntity(entity) )
		return false;
	return true;
}

stock bool IsWeaponSpawner(int weapon){
	if(IsValidWeapon(weapon)){
		char class_name[64];
		GetEntityClassname(weapon, class_name, sizeof(class_name));
		return (strncmp(class_name[strlen(class_name)-6], "_spawn", 7) == 0);
	}
	return false;
}

stock bool IsWeaponGascan(int weapon){
	if(IsValidWeapon(weapon)){
		char class_name[64];
		GetEntityClassname(weapon, class_name, sizeof(class_name));
		return (strcmp(class_name, "weapon_gascan") == 0);
	}
	return false;
}

stock bool IsWeaponColaBottles(int weapon){
	if(IsValidWeapon(weapon)){
		char class_name[64];
		GetEntityClassname(weapon, class_name, sizeof(class_name));
		return (strcmp(class_name, "weapon_cola_bottles") == 0);
	}
	return false;
}

stock bool IsValidWeapon(int weapon){
	if (IsValidEnt(weapon)) {
		char class_name[64];
		GetEntityClassname(weapon,class_name,sizeof(class_name));
		return (strncmp(class_name, "weapon_", 7) == 0);
	}
	return false;
}

//https://forums.alliedmods.net/showthread.php?t=303716
stock bool IsPlayerCapped(int client)
{	
	if(GetEntPropEnt(client, Prop_Send, "m_pounceAttacker") > 0)
		return true;
	if(GetEntPropEnt(client, Prop_Send, "m_tongueOwner") > 0)
		return true;
	//only l4D2
	if(HasEntProp(client, Prop_Send, "m_pummelAttacker") && GetEntPropEnt(client, Prop_Send, "m_pummelAttacker") > 0)
		return true;
	if(HasEntProp(client, Prop_Send, "m_carryAttacker") && GetEntPropEnt(client, Prop_Send, "m_carryAttacker") > 0)
		return true;
	if(HasEntProp(client, Prop_Send, "m_jockeyAttacker") && GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker") > 0)
		return true;
	
	return false;
} 

stock bool IsPlayerHanding(int client){
	return (GetEntProp(client, Prop_Send, "m_isHangingFromLedge", 1) == 1);
}

stock bool IsPlayerIncapped(int client){
	return (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1) == 1);
}

stock bool IsValidSpect(int client){ 
	return (IsValidClient(client) && GetClientTeam(client) == 1 );
}

stock bool IsValidSurvivor(int client){
	return (IsValidClient(client) && GetClientTeam(client) == 2 );
}

stock bool IsValidInfected(int client){
	return (IsValidClient(client) && GetClientTeam(client) == 3 );
}

stock bool IsValidClient(int client){
	return (client > 0 && client <= MaxClients && IsClientInGame(client));
}

stock bool IsValidEnt(int entity){
	return (entity > MaxClients && IsValidEntity(entity) && entity != INVALID_ENT_REFERENCE);
}
