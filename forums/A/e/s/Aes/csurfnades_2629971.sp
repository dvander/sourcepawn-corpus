#pragma semicolon 1 
#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>
#include <autoexecconfig>

#define LoopAllPlayers(%1) for(int %1=1;%1<=MaxClients;++%1)\
if(IsClientInGame(%1))

enum Collision_Group_t
{
    COLLISION_GROUP_NONE  = 0,        // Default; collides with static and dynamic objects
    COLLISION_GROUP_DEBRIS,            // Collides with nothing but world and static stuff
    COLLISION_GROUP_DEBRIS_TRIGGER, // Same as debris, but hits triggers
    COLLISION_GROUP_INTERACTIVE_DEBRIS,    // Collides with everything except other interactive debris or debris
    COLLISION_GROUP_INTERACTIVE,    // Collides with everything except interactive debris or debris
    COLLISION_GROUP_PLAYER,            // Collision group for player
    COLLISION_GROUP_BREAKABLE_GLASS,// Special group for glass debris
    COLLISION_GROUP_VEHICLE,        // Collision group for driveable vehicles
    COLLISION_GROUP_PLAYER_MOVEMENT,      //For singleplayer, same as Collision_Group_Player, for multiplayer, this filters out other players and CBaseObjects
    COLLISION_GROUP_NPC,            // Generic NPC group
    COLLISION_GROUP_IN_VEHICLE,        // for any entity inside a vehicle
    COLLISION_GROUP_WEAPON,            // for any weapons that need collision detection
    COLLISION_GROUP_VEHICLE_CLIP,    // vehicle clip brush to restrict vehicle movement
    COLLISION_GROUP_PROJECTILE,        // Projectiles!
    COLLISION_GROUP_DOOR_BLOCKER,    // Blocks entities not permitted to get near moving doors
    COLLISION_GROUP_PASSABLE_DOOR,    // Doors that the player shouldn't collide with
    COLLISION_GROUP_DISSOLVING,        // Things that are dissolving are in this group
    COLLISION_GROUP_PUSHAWAY,        // Nonsolid on client and server, pushaway in player code

    COLLISION_GROUP_NPC_ACTOR,        // Used so NPCs in scripts ignore the player.
    COLLISION_GROUP_NPC_SCRIPTED,    // USed for NPCs in scripts that should not collide with each other

    LAST_SHARED_COLLISION_GROUP
};

Handle gOnPlayerHit;

Handle g_SnowTimer[MAXPLAYERS + 1];

Handle hNadeEnabled;
Handle hNadeTrajectoryEnabled;
Handle hNadeTrajectorySpeed;
Handle hNadeKnockbackEnabled;
Handle hNadeHEKnockbackRadius;
Handle hNadeHEKnockbackPushspeed;
Handle hNadeFlashKnockbackRadius;
Handle hNadeFlashKnockbackPushspeed;
Handle hNadeHEAirTime;
Handle hNadeExplodeBounce;
Handle hNadeFlashAirTime;
Handle hNadeFlashDisableBlind;
Handle hNadeTailsEnabled;
Handle hNadePlayerCollision;
Handle hNadeSnowballEnabled;
Handle hNadeSnowballDamage;

bool bNadeEnabled,
	bNadeTrajectoryEnabled,
	bNadeKnockbackEnabled,
	bNadeFlashDisableBlind,
	bNadeTailsEnabled,
	bNadePlayerCollision,
	bNadeSnowballEnabled;
float fNadeTrajectorySpeed,
	fNadeHEKnockbackRadius,
	fNadeHEKnockbackPushspeed,
	fNadeFlashKnockbackRadius,
	fNadeFlashKnockbackPushspeed,
	fNadeHEAirTime,
	fNadeFlashAirTime,
	fNadeSnowballDamage;
int iNadeExplodeBounce;

int i_LaserSprite;

char sProjectiles[6][32] = {"flashbang_projectile", "hegrenade_projectile", "snowball_projectile", "smokegrenade_projectile", "decoy_projectile", "molotov_projectile"};


public Plugin myinfo =
{
	name = "Combat Surf Custom Grenades",
	author = "Aes",
	description = "Makes grenades usable in combat surf",
	version = "0.0.1",
	url = "https://forums.alliedmods.net"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("csurfnades");
	gOnPlayerHit = CreateGlobalForward("CSurfNades_OnPlayerHit", 	ET_Ignore, Param_Cell, Param_Cell);	
	return APLRes_Success;
}

void CreateConfigs()
{
	AutoExecConfig_SetFile("csurfnades");
	HookConVarChange(hNadeEnabled = AutoExecConfig_CreateConVar("sm_csn_enable", "1", "Enable this plugin"), OnCvarChanged);
	HookConVarChange(hNadeTrajectoryEnabled = AutoExecConfig_CreateConVar("sm_csn_trajectory_enable", "1", "Enable the alternate trajectory system"), OnCvarChanged);
	HookConVarChange(hNadeTrajectorySpeed = AutoExecConfig_CreateConVar("sm_csn_trajectory_speed", "1250","The base speed given to the grenade"), OnCvarChanged);
	HookConVarChange(hNadeKnockbackEnabled = AutoExecConfig_CreateConVar("sm_csn_kb_enable", "1","Enable the grenades knockback"), OnCvarChanged);
	HookConVarChange(hNadeHEKnockbackRadius = AutoExecConfig_CreateConVar("sm_csn_he_kb_radius", "384","The HE grenade knockback radius"),	OnCvarChanged);
	HookConVarChange(hNadeHEKnockbackPushspeed = AutoExecConfig_CreateConVar("sm_csn_he_kb_pushspeed", "1500","The speed given by the HE knockback"), OnCvarChanged);
	HookConVarChange(hNadeFlashKnockbackRadius = AutoExecConfig_CreateConVar("sm_csn_flash_kb_radius", "250","The Flashbang knockback radius"), OnCvarChanged);
	HookConVarChange(hNadeFlashKnockbackPushspeed = AutoExecConfig_CreateConVar("sm_csn_flash_kb_pushspeed", "750","The speed given by the flashbang"), OnCvarChanged);
	HookConVarChange(hNadeHEAirTime = AutoExecConfig_CreateConVar("sm_csn_he_airtime", "10","How long will the HE stays in air before exploding"), OnCvarChanged);
	HookConVarChange(hNadeFlashAirTime = AutoExecConfig_CreateConVar("sm_csn_flash_airtime", "10","How long will the flash stays in air before exploding"), OnCvarChanged);
	HookConVarChange(hNadeExplodeBounce = AutoExecConfig_CreateConVar("sm_csn_bounces", "1","How much bounces before exploding"), OnCvarChanged);
	HookConVarChange(hNadeFlashDisableBlind = AutoExecConfig_CreateConVar("sm_csn_flash_disable_blind", "1","Disable the white screen from the flashbang"), OnCvarChanged);
	HookConVarChange(hNadeTailsEnabled = AutoExecConfig_CreateConVar("sm_csn_tails_enable", "1","Enable Grenade tails"), 	OnCvarChanged);
	HookConVarChange(hNadePlayerCollision = AutoExecConfig_CreateConVar("sm_csn_player_collision", "1","Turn noblock on for players but allows grenade hitting"), OnCvarChanged);
	HookConVarChange(hNadeSnowballEnabled = AutoExecConfig_CreateConVar("sm_csn_snowball_enable", "1","Enable unlimited freezing snowballs"), OnCvarChanged);
	HookConVarChange(hNadeSnowballDamage = AutoExecConfig_CreateConVar("sm_csn_snowball_damage", "30","Add damages to the snowball"), OnCvarChanged);
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
}

public void OnCvarChanged(Handle hConvar, const char[] chOldValue, const char[] chNewValue)
{
	UpdateConvars();
}

public void UpdateConvars()
{
	bNadeEnabled = GetConVarBool(hNadeEnabled);
	bNadeTrajectoryEnabled = GetConVarBool(hNadeTrajectoryEnabled);
	fNadeTrajectorySpeed = GetConVarFloat(hNadeTrajectorySpeed);
	bNadeKnockbackEnabled = GetConVarBool(hNadeKnockbackEnabled);
	fNadeHEKnockbackRadius = GetConVarFloat(hNadeHEKnockbackRadius);
	fNadeHEKnockbackPushspeed = GetConVarFloat(hNadeHEKnockbackPushspeed);
	fNadeFlashKnockbackRadius = GetConVarFloat(hNadeFlashKnockbackRadius);
	fNadeFlashKnockbackPushspeed = GetConVarFloat(hNadeFlashKnockbackPushspeed);
	fNadeHEAirTime = GetConVarFloat(hNadeHEAirTime);
	iNadeExplodeBounce = GetConVarInt(hNadeExplodeBounce);
	fNadeFlashAirTime = GetConVarFloat(hNadeFlashAirTime);
	bNadeFlashDisableBlind = GetConVarBool(hNadeFlashDisableBlind);
	bNadeTailsEnabled = GetConVarBool(hNadeTailsEnabled);
	bNadePlayerCollision = GetConVarBool(hNadePlayerCollision);
	bNadeSnowballEnabled = GetConVarBool(hNadeSnowballEnabled);
	fNadeSnowballDamage = GetConVarFloat(hNadeSnowballDamage);
}

public void OnPluginStart() 
{
	CreateConfigs();
	UpdateConvars();
	PrecacheSound("physics/glass/glass_impact_bullet4.wav", true);
	i_LaserSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
	HookEvent("grenade_bounce", OnGrenadeBounce);
	HookEvent("player_blind", OnPlayerBlind, EventHookMode_Pre);
	HookEvent("player_spawn", OnPlayerSpawn);
} 
public void OnMapStart(){
	PrecacheSound("physics/glass/glass_impact_bullet4.wav", true);
	i_LaserSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
}

public Action OnPlayerBlind(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!client || !IsClientInGame(client) || !bNadeEnabled || !bNadeFlashDisableBlind)
		return Plugin_Continue;
	SetEntPropFloat(client, Prop_Send, "m_flFlashMaxAlpha", 0.0);
	return Plugin_Continue;
}

public Action OnGrenadeBounce(Handle event, const char[] name, bool dontBroadcast)
{
	if(!bNadeEnabled) return Plugin_Continue;
	int iClient = GetEventInt(event, "userid");
	RequestFrame(Frame_GrenadeBounce, iClient);
	return Plugin_Continue;
}

public Action OnPlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	SetEntProp(client, Prop_Data, "m_CollisionGroup", ( bNadePlayerCollision ? COLLISION_GROUP_INTERACTIVE_DEBRIS : COLLISION_GROUP_PLAYER ));
	if(bNadeSnowballEnabled)
		//GivePlayerItem(client, "weapon_snowball");
	return Plugin_Continue;
}

public void Frame_GrenadeBounce(int iClient){
	iClient = GetClientOfUserId(iClient);
	int iGrenade = GetGrenade(iClient);
	char sClass[32];
	float gPos[3];
	if(IsValidEntity(iGrenade))
	{
		GetEdictClassname(iGrenade, sClass, sizeof(sClass));
		GetEntPropVector(iGrenade, Prop_Send, "m_vecOrigin", gPos);
		if(IsGrenadeProjectile(sClass))
		{
			SetEntityMoveType(iGrenade, MOVETYPE_NONE);
			SetEntProp(iGrenade, Prop_Data, "m_takedamage", 2);
			SetEntProp(iGrenade, Prop_Data, "m_iHealth", 1);
			SDKHooks_TakeDamage(iGrenade, 0, 0, 1.0);
			SetEntProp(iGrenade, Prop_Data, "m_nNextThinkTick", 1);
			if(bNadeKnockbackEnabled)
			{
				if(StrEqual(sClass, "hegrenade_projectile"))
				{
					KnockBack(gPos, iGrenade, fNadeHEKnockbackRadius, fNadeHEKnockbackPushspeed);
				}
				else if(StrEqual(sClass, "flashbang_projectile"))
				{
					KnockBack(gPos, iGrenade, fNadeFlashKnockbackRadius, fNadeFlashKnockbackPushspeed);
				}
			}
		}
	}
}

int GetGrenade(int iClient)
{
	for(int i = 0, iGrenade = -1; i < sizeof(sProjectiles); i++)
	{
		while((iGrenade = FindEntityByClassname(iGrenade, sProjectiles[i])) != -1)
		{
			if(GetEntPropEnt(iGrenade, Prop_Send, "m_hThrower") == iClient && GetEntProp(iGrenade, Prop_Send, "m_nBounces") >= iNadeExplodeBounce)
				return iGrenade;
		}
	}
	return -1;
}

void KnockBack(float pos[3], int entity, float radius, float pushspeed){
	float distance;
	float vPos[3];
	float vDir[3];
	float vTPos[3], vTAng[3], vTVel[3];
	LoopAllPlayers(i)
	{
		GetClientAbsOrigin(i,vPos);
		MakeVectorFromPoints(pos,vPos,vDir);
		distance = GetVectorLength(vDir,false);
		if(distance <= radius){
			//---
			Call_StartForward(gOnPlayerHit);
			Call_PushCell(i);
			Call_PushCell(entity);
			Call_Finish();
			//---
			GetClientAbsOrigin(i,vTPos);
			GetClientEyeAngles(i,vTAng);
			GetEntPropVector(i, Prop_Data, "m_vecVelocity", vTVel);
			NormalizeVector(vDir,vDir);    
			ScaleVector(vDir, pushspeed);
			AddVectors(vTVel,vDir,vTVel);
			TeleportEntity(i, vTPos, vTAng, vTVel);
		}
	}
	
}

public OnEntityCreated(entity, const char[] classname)
{
	if(IsValidEdict(entity) && bNadeEnabled)
	{
		if(IsGrenadeProjectile(classname))
		{
			SDKHook(entity, SDKHook_SpawnPost, OnGrenadeSpawnPost);			
		}
	}
}

void OnGrenadeSpawnPost(int entity){
	RequestFrame(Frame_Grenade,entity);
}

public void Frame_Grenade(int entity){
	if(IsValidEntity(entity))
	{
		float vEye[3];
		int client;
		char sClass[32];
		float fAirTime = 0;
		GetEdictClassname(entity, sClass, sizeof(sClass));
		//SetEntProp(entity, Prop_Data, "m_CollisionGroup", 5);
		if(StrEqual(sClass, "hegrenade_projectile"))
			fAirTime = fNadeHEAirTime;
		else if(StrEqual(sClass, "flashbang_projectile"))
			fAirTime = fNadeFlashAirTime;
		
		if(fAirTime != 0)
			SetEntDataFloat(entity, FindSendPropInfo("CBaseCSGrenadeProjectile", "m_hThrower") + 36, GetGameTime() + fAirTime, true);
		//GetEntPropVector(entity, Prop_Send, "m_vecVelocity", gVelocity);
		client = GetEntPropEnt(entity, Prop_Send, "m_hThrower");
		if(IsValidClient(client) && bNadeTrajectoryEnabled)
		{
			float fAbsVelocity[3]; GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", fAbsVelocity);
			GetClientEyeAngles(client,vEye);			
			float fCurrentSpeed = SquareRoot(Pow(fAbsVelocity[0], 2.0) + Pow(fAbsVelocity[1], 2.0));
			GetAngleVectors(vEye, vEye, NULL_VECTOR, NULL_VECTOR);
			NormalizeVector(vEye,vEye);  
			ScaleVector(vEye, fCurrentSpeed + fNadeTrajectorySpeed);
			TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, vEye);
		}
		if(bNadeTailsEnabled)
		{
			if(!IsModelPrecached("materials/sprites/laserbeam.vmt"))
				i_LaserSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
			if(StrEqual(sClass, "hegrenade_projectile"))
			{
				TE_SetupBeamFollow(entity, i_LaserSprite, 0, 1.0, 1.0, 1.0, 5, {255, 0, 0, 255});
				TE_SendToAll();
			}
			else if(StrEqual(sClass, "flashbang_projectile"))
			{
				TE_SetupBeamFollow(entity, i_LaserSprite, 0, 1.0, 1.0, 1.0, 5, {0, 0, 255, 255});
				TE_SendToAll();
			}
			else if(StrEqual(sClass, "snowball_projectile"))
			{
				TE_SetupBeamFollow(entity, i_LaserSprite, 0, 1.0, 1.0, 1.0, 5, {255, 255, 255, 255});
				TE_SendToAll();
			}
		}
		if(bNadeSnowballEnabled && StrEqual(sClass, "snowball_projectile"))
		{
			SDKHook(entity, SDKHook_StartTouch, Snowball_StartTouch);
			GivePlayerItem(client, "weapon_snowball"); 
		}
	}
}


void Snowball_StartTouch(int iEntity, int iVictim)
{
	int iAttacker = GetEntPropEnt(iEntity, Prop_Send, "m_hThrower");
	float fPos[3]; GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fPos);
	if(IsValidClient(iAttacker) && IsValidClient(iVictim))
	{
		SDKHooks_TakeDamage(iVictim, iAttacker, iAttacker, fNadeSnowballDamage, DMG_CRUSH);
		SetEntityMoveType(iVictim, MOVETYPE_NONE);
		SetEntityRenderColor(iVictim, 0, 157, 255, 255);
		g_SnowTimer[iVictim] = CreateTimer(1.2, FreezeClientTimer, GetClientUserId(iVictim), TIMER_FLAG_NO_MAPCHANGE);
		EmitAmbientSound("physics/glass/glass_impact_bullet4.wav", fPos, iEntity);
	}
}


public Action FreezeClientTimer(Handle hTimer, any iClient)
{
	iClient = GetClientOfUserId(iClient);
	if(IsValidClient(iClient) && IsPlayerAlive(iClient))
	{
		SetEntityMoveType(iClient, MOVETYPE_WALK);
		SetEntityRenderColor(iClient, 255, 255, 255, 255);
	}

	g_SnowTimer[iClient] = null;
	return Plugin_Stop;
}

bool IsGrenadeProjectile(const char[] classname)
{
	for(int i = 0; i < sizeof(sProjectiles); i++)
	{
		if(StrEqual(classname,sProjectiles[i]))
			return true;
	}
	return false;
}

bool IsValidClient(int client)
{
	if(client < 1 || client > MaxClients + 1)
		return false;
	
	if(!IsClientInGame(client) || !IsPlayerAlive(client))
		return false;
	
	return true;
}




