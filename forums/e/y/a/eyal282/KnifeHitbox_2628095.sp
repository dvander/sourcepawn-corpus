#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#define ANGLES_TO_HEART_FROM_ABS Float:{277.1434, 352.1014, 0.0000}
#define DISTANCE_TO_HEART_FROM_ABS_SQUARE 2658.2695

// Angles and distance from ABS is something I already did, Distance allowed from hitpoint to heart center is the margin of error you can set yourself.

#define DISTANCE_ALLOWED_FROM_HITPOINT_TO_HEARTCENTER_SQUARE 9.0

new const String:PLUGIN_VERSION[] = "1.2";

public Plugin:myinfo = 
{
	name = "Knife Headshot",
	author = "Eyal282",
	description = "Doubles inflicted damage with knife on a heart hit.",
	version = PLUGIN_VERSION,
	url = "None."
}

new LastHitGroup[MAXPLAYERS+1][MAXPLAYERS+1]; // First is victim, second is attacker.

new Handle:hcv_Enabled = INVALID_HANDLE;
new Handle:hcv_Multiplier = INVALID_HANDLE;

public OnPluginStart()
{
	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Pre);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	
	hcv_Enabled = CreateConVar("knife_heartshot_enabled", "1", "Determines if to allow knife heartshots", FCVAR_NOTIFY);
	hcv_Multiplier = CreateConVar("knife_heartshot_multiplier", "2.0", "Determines how much to multiply knife heartshot damage", FCVAR_NOTIFY);
	
	SetConVarString(CreateConVar("knife_heartshot_version", PLUGIN_VERSION, "", FCVAR_NOTIFY), PLUGIN_VERSION);
	
	for(new i=1;i <= MaxClients;i++) // If plugin gets reloaded...
	{
		if(!IsClientInGame(i))
			continue;
			
		OnClientPutInServer(i);
	}
}
public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, Event_OnTakeDamage);
}

// https://forums.alliedmods.net/showpost.php?p=2565252&postcount=6

// https://forums.alliedmods.net/showpost.php?p=2565443&postcount=10

// His code is broken so don't use it but I gotta give credit for it :). Also trace to only hit victim is safer than don't hit self.

// The second guy is the fix for the broken code.

public Action:Event_PlayerHurt(Handle:hEvent, const String:Name[], bool:dontBroadcast)
{
	if(!GetConVarBool(hcv_Enabled))
		return Plugin_Continue;
		
	new attacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	
	if(attacker == 0)
		return Plugin_Continue;
		
	new victim = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if(victim == attacker)
		return Plugin_Continue;
		
	new String:WeaponName[50];
	
	GetEventString(hEvent, "weapon", WeaponName, sizeof(WeaponName));
	
	if(!strncmp(WeaponName, "weapon_knife", 12))
		return Plugin_Continue;
	
	new Float:Position[3], Float:Angles[3];
	
	GetClientEyePosition(attacker, Position); 
	GetClientEyeAngles(attacker, Angles); 
	
	TR_TraceRayFilter(Position, Angles, MASK_SHOT, RayType_Infinite, Trace_HitVictimOnly, victim); //Start the trace 
     
	new HitGroup = TR_GetHitGroup(); //Get the hit group 
	
	SetEventInt(hEvent, "hitgroup", HitGroup); // Would be nice to have Chest and legs instead of just Body.
	
	if(HitGroup == 1)
		SetEventBool(hEvent, "headshot", true);
		
	LastHitGroup[victim][attacker] = HitGroup;
		
	return Plugin_Continue;
}

public Action:Event_PlayerDeath(Handle:hEvent, const String:Name[], bool:dontBroadcast)
{
	if(!GetConVarBool(hcv_Enabled))
		return Plugin_Continue;
		
	new attacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	
	if(attacker == 0)
		return Plugin_Continue;
		
	new victim = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if(victim == attacker)
		return Plugin_Continue;
		
	new String:WeaponName[50];
	
	GetEventString(hEvent, "weapon", WeaponName, sizeof(WeaponName));
	
	if(!strncmp(WeaponName, "weapon_knife", 12))
		return Plugin_Continue;
	
	
	if(LastHitGroup[victim][attacker] == 1)
	{
		SetEventBool(hEvent, "headshot", true);
	}
		
	return Plugin_Continue;
}

public Action:Event_OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup)
{
	if(!GetConVarBool(hcv_Enabled))
		return Plugin_Continue;
		
	else if(attacker == victim)
		return Plugin_Continue;
	
	else if(!IsPlayer(inflictor))
		return Plugin_Continue;
		
	new ActiveWeapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
	
	if(ActiveWeapon == -1)
		return Plugin_Continue;
		
	new String:Classname[64];
	GetEdictClassname(ActiveWeapon, Classname, sizeof(Classname));
	
	if(strncmp(Classname, "weapon_knife", 12) != 0)
		return Plugin_Continue;
		
	new Float:Position[3], Float:Angles[3];
	GetClientEyePosition(attacker, Position); 
	GetClientEyeAngles(attacker, Angles); 
	
	TR_TraceRayFilter(Position, Angles, MASK_SHOT, RayType_Infinite, Trace_HitVictimOnly, victim); //Start the trace 

	new Float:Origin[3];
	TR_GetEndPosition(Origin); //Get the hit group 
	
	GetClientAbsOrigin(victim, Position);
	GetAngleBetweenOrigins(Position, Origin, Angles);
	
	new Float:HeartCenterOrigin[3];
	
	//AddDistanceToOriginByAngles(Position, Angles, Distance, HeartCenterOrigin);
	//PrintToChatAll("%.4f, %.4f, %.4f, %.4f", Angles[0], Angles[1], Angles[2], GetVectorDistance(Position, Origin, true)); // Prints 277.1434, 352.1014, 0.0000, 2658.2695
	
	GetClientAbsOrigin(victim, Position);
	AddDistanceToOriginByAngles(Position, ANGLES_TO_HEART_FROM_ABS, Pow(DISTANCE_TO_HEART_FROM_ABS_SQUARE, 0.5), HeartCenterOrigin);
	
	if(GetVectorDistance(Origin, HeartCenterOrigin, true) > DISTANCE_ALLOWED_FROM_HITPOINT_TO_HEARTCENTER_SQUARE)
		return Plugin_Continue;

	damage *= GetConVarFloat(hcv_Multiplier);
	PrintToChatAll("HEART SHOT");
	return Plugin_Changed;
}

public bool:Trace_HitVictimOnly(entity, contentsMask, victim) 
{ 
	return entity == victim; 
}  

stock GetAngleBetweenOrigins(const Float:Origin1[3], const Float:Origin2[3], Float:Angles[3], bool:Negate = true)
{
	new Float:Result[3]; 
	SubtractVectors(Origin1, Origin2, Result); 
	NormalizeVector(Result, Result); 
	
	if(Negate)
		NegateVector(Result);
		
	GetVectorAngles(Result, Angles);  
}

stock AddDistanceToOriginByAngles(const Float:Origin[3], const Float:Angles[3], Float:Distance, Float:Result[3])
{
	new Float:TempOrigin[3], Float:TempAngles[3];
	TempOrigin = Origin; TempAngles = Angles;
	GetAngleVectors(TempAngles, TempAngles, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(TempAngles, TempAngles);  
	ScaleVector(TempAngles, Distance); // distance
	AddVectors(TempOrigin, TempAngles, Result); // vEnd is ur endpoint
}


stock bool:IsPlayer(entity)
{
	if(entity > MaxClients)
		return false;

	else if(entity < 1)
		return false;
		
	return true;
}