#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <zombieplague>

#pragma newdecls required

public Plugin myinfo =
{
	name        	= "[ZP] Zombie Class: Smoker",
	author      	= "Extr1m (Michail) & Romeo",
	description 	= "Addon of zombie classses",
	version     	= "1.1",
	url         	= "https://sourcemod.net/"
}

// Cvars
ConVar gCV_PEnabled = null;
ConVar gCV_PAttractingCooldown = null;
ConVar gCV_PAttractingDistance = null;
ConVar gCV_PAttractingDamage = null;

// Cached cvars
bool 	gB_PEnabled = true;
float 	gF_PAttractingCooldown;
float 	gF_PAttractingDistance;
float 	gF_PAttractingDamage;

// ConVar for sound level
ConVar hSoundLevel;

Handle g_hook_timer[MAXPLAYERS+1];

bool g_InUse[MAXPLAYERS+1] = false;

float g_over_dmg[MAXPLAYERS + 1];
float g_AttractingLastTime[MAXPLAYERS + 1];

char g_sprite;

#define ZOMBIE_CLASS_NAME				"@Smoker"
#define ZOMBIE_CLASS_INFO               "" // Only will be taken from translation file ("" - disabled)
#define ZOMBIE_CLASS_MODEL				"models/player/custom_player/borodatm.ru/l4d2/smoker.mdl"	
#define ZOMBIE_CLASS_CLAW				"models/player/custom_player/zombie/zombie_bomb/hand/hand_zombie_bomb.mdl"
#define ZOMBIE_CLASS_GRENADE            "models/player/custom_player/zombie/normal_f_01/grenade/grenade_normal_f_01.mdl"	
#define ZOMBIE_CLASS_HEALTH				1400
#define ZOMBIE_CLASS_SPEED				0.9
#define ZOMBIE_CLASS_GRAVITY			1.0
#define ZOMBIE_CLASS_KNOCKBACK			1.0
#define ZOMBIE_CLASS_LEVEL				1
#define ZOMBIE_CLASS_VIP				NO
#define ZOMBIE_CLASS_DURATION			0.0
#define ZOMBIE_CLASS_COUNTDOWN			0.0
#define ZOMBIE_CLASS_REGEN_HEALTH		0
#define ZOMBIE_CLASS_REGEN_INTERVAL		0.0
#define ZOMBIE_CLASS_SOUND_DEATH        "ZOMBIE_DEATH_SOUNDS"
#define ZOMBIE_CLASS_SOUND_HURT         "ZOMBIE_HURT_SOUNDS"
#define ZOMBIE_CLASS_SOUND_IDLE         "ZOMBIE_IDLE_SOUNDS"
#define ZOMBIE_CLASS_SOUND_RESPAWN      "ZOMBIE_RESPAWN_SOUNDS"
#define ZOMBIE_CLASS_SOUND_BURN         "ZOMBIE_BURN_SOUNDS"
#define ZOMBIE_CLASS_SOUND_ATTACK       "ZOMBIE_ATTACK_SOUNDS"
#define ZOMBIE_CLASS_SOUND_FOOTSTEP     "ZOMBIE_FOOTSTEP_SOUNDS"
#define ZOMBIE_CLASS_SOUND_REGEN        "ZOMBIE_REGEN_SOUNDS"

int gZombieSmoker;
#pragma unused gZombieSmoker

/**
    * Called after a library is added that the current plugin references optionally. 
 * A library is either a plugin name or extension name, as exposed via its include file.
 **/
public void OnLibraryAdded(const char[] sLibrary)
{
	// Validate library
	if(!strcmp(sLibrary, "zombieplague", false))
	{
		// Initilizate zombie class
		gZombieSmoker = ZP_RegisterZombieClass(ZOMBIE_CLASS_NAME,
		ZOMBIE_CLASS_INFO,
		ZOMBIE_CLASS_MODEL, 
		ZOMBIE_CLASS_CLAW,  
		ZOMBIE_CLASS_GRENADE,
		ZOMBIE_CLASS_HEALTH, 
		ZOMBIE_CLASS_SPEED, 
		ZOMBIE_CLASS_GRAVITY, 
		ZOMBIE_CLASS_KNOCKBACK, 
		ZOMBIE_CLASS_LEVEL,
		ZOMBIE_CLASS_VIP, 
		ZOMBIE_CLASS_DURATION, 
		ZOMBIE_CLASS_COUNTDOWN, 
		ZOMBIE_CLASS_REGEN_HEALTH, 
		ZOMBIE_CLASS_REGEN_INTERVAL,
		ZOMBIE_CLASS_SOUND_DEATH,
		ZOMBIE_CLASS_SOUND_HURT,
		ZOMBIE_CLASS_SOUND_IDLE,
		ZOMBIE_CLASS_SOUND_RESPAWN,
		ZOMBIE_CLASS_SOUND_BURN,
		ZOMBIE_CLASS_SOUND_ATTACK,
		ZOMBIE_CLASS_SOUND_FOOTSTEP,
		ZOMBIE_CLASS_SOUND_REGEN);
	}
}

public void OnPluginStart()
{
	gCV_PEnabled 				= 	CreateConVar("zp_smoker_enabled", "1", "Responsible for the operation of the class on the server", 0, true, 0.0, true, 1.0);
	gCV_PAttractingCooldown 	= 	CreateConVar("zp_smoker_cooldown", "30.0", "Time between each use", 0, true, 0.0, true, 60.0);
	gCV_PAttractingDistance		= 	CreateConVar("zp_smoker_distance", "2000.0", "Maximum distance between attacker and victim", 0, true, 0.0, true, 10000.0);
	gCV_PAttractingDamage		= 	CreateConVar("zp_smoker_damage", "200.0", "How much damage do I need to interrupt", 0, true, 0.0, true, 5000.0);

	gCV_PEnabled.AddChangeHook(ConVarChange);
	gCV_PAttractingCooldown.AddChangeHook(ConVarChange);
	gCV_PAttractingDistance.AddChangeHook(ConVarChange);
	gCV_PAttractingDamage.AddChangeHook(ConVarChange);
	
	gB_PEnabled = gCV_PEnabled.BoolValue;
	gF_PAttractingCooldown = gCV_PAttractingCooldown.FloatValue;
	gF_PAttractingDistance = gCV_PAttractingDistance.FloatValue;
	gF_PAttractingDamage = gCV_PAttractingDamage.FloatValue;
	
	AutoExecConfig(true, "zombieplague_smoker");
	
	HookEvent("round_start", OnRoundStart);
}

public void OnMapStart()
{
	g_sprite = PrecacheModel("materials/sprites/purplelaser1.vmt");
	PrecacheSound("zbm3/drag_ability_hit.mp3");
	AddFileToDownloadsTable("sound/drag_ability_hit.mp3");

	for(int i = 1; i <= MaxClients; i++)
	{
		g_AttractingLastTime[i] = 0.0;
	}
	
	// Cvars
	hSoundLevel = FindConVar("zp_game_custom_sound_level"); 
}

public void ConVarChange(ConVar CVar, const char[] oldVal, const char[] newVal)
{
	gB_PEnabled = gCV_PEnabled.BoolValue;
	gF_PAttractingCooldown = gCV_PAttractingCooldown.FloatValue;
	gF_PAttractingDistance = gCV_PAttractingDistance.FloatValue;
	gF_PAttractingDamage = gCV_PAttractingDamage.FloatValue;
}

public void OnClientPutInServer(int clientIndex) 
{ 
    SDKHook(clientIndex, SDKHook_OnTakeDamage, OnTakeDamage);  
} 

public void OnClientDisconnect(int clientIndex)
{ 
   SDKUnhook(clientIndex, SDKHook_OnTakeDamage, OnTakeDamage);  
}  

public Action OnRoundStart(Handle event, const char[] name, bool dontBroadcast) 
{
	for (int i = 1; i <= MaxClients; i++)
	{
		g_InUse[i] = false;
		if(g_hook_timer[i])
		{
			KillTimer(g_hook_timer[i])
		}
		g_hook_timer[i] = null;
	}
	
	int clientIndex = GetClientOfUserId(GetEventInt(event, "userid"));
	if(g_InUse[clientIndex])
	{
		KillTimer(g_hook_timer[clientIndex])
		g_hook_timer[clientIndex] = null;
		g_InUse[clientIndex] = false;
	}
}

public Action OnPlayerRunCmd(int clientIndex, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{	
	if (gB_PEnabled && IsPlayerExist(clientIndex) && ZP_GetClientZombieClass(clientIndex) == gZombieSmoker)
	{
		if (!g_InUse[clientIndex] && ZP_IsPlayerZombie(clientIndex) && (buttons & (IN_RELOAD) == (IN_RELOAD)))
		{	
			if (GetGameTime() - g_AttractingLastTime[clientIndex] < gF_PAttractingCooldown) 
			{
				PrintHintText(clientIndex, "Reloading - %.1f", gF_PAttractingCooldown - (GetGameTime() - g_AttractingLastTime[clientIndex]));
				return Plugin_Continue;
			}
			
			Handle pack = CreateDataPack();
		
			int target = GetClientAimTarget(clientIndex);
			
			if(IsPlayerExist(target) && IsPlayerAlive(target) && ZP_IsPlayerZombie(target))
				return Plugin_Continue;
				
			if(IsPlayerExist(target))
			{
				float fOriginClient[3];
				float fOriginTarget[3];
				
				GetClientAbsOrigin(clientIndex, fOriginClient);
				GetClientAbsOrigin(target, fOriginTarget);
				
				float fDistance = GetVectorDistance(fOriginClient, fOriginTarget);
				
				if(fDistance > gF_PAttractingDistance)
					return Plugin_Continue;
				
				WritePackCell(pack, clientIndex);
				WritePackCell(pack, target);
				
				g_hook_timer[clientIndex] = CreateTimer(0.1, hooked, pack, TIMER_REPEAT)
				
				
				g_InUse[clientIndex] = true;
				g_AttractingLastTime[clientIndex] = GetGameTime();
				EmitSoundToAll("*/zbm3/drag_ability_hit.mp3", clientIndex, SNDCHAN_VOICE, hSoundLevel.IntValue);
			}
		}
		else if (g_InUse[clientIndex] && !(buttons & (IN_RELOAD) == (IN_RELOAD)))
		{
			if(g_hook_timer[clientIndex])
			{
				KillTimer(g_hook_timer[clientIndex])
				g_hook_timer[clientIndex] = null;
				SetEntPropFloat(clientIndex, Prop_Data, "m_flLaggedMovementValue", 1.0); 
				g_InUse[clientIndex] = false;
			}
		}
	}
	return Plugin_Continue;
}

public Action hooked(Handle timer, Handle pack)
{
	ResetPack(pack);
	
	int clientIndex = ReadPackCell(pack);
	int target = ReadPackCell(pack);
	
	if (IsClientInGame(clientIndex) && IsPlayerAlive(clientIndex) && ZP_IsPlayerZombie(clientIndex)) 
	{ 
		SetEntPropFloat(clientIndex, Prop_Data, "m_flLaggedMovementValue", 1.0); 
		if (target > 0) 
		{  
			float clientVec[3]; 
			float targetVec[3]; 
			GetClientAbsOrigin(clientIndex, clientVec); 
			GetClientAbsOrigin(target, targetVec); 

			float distance = GetVectorDistance(clientVec, targetVec);
		
			clientVec[2] += 10; 
			targetVec[2] += 10; 
			float clientEyeVec[3]; 
			float targetWepVec[3]; 
			GetClientEyePosition(clientIndex, clientEyeVec); 
			GetClientEyePosition(target, targetWepVec); 
			TE_SetupBeamPoints(clientEyeVec, targetWepVec, g_sprite, 0, 0, 0, 0.5, 3.0, 3.0, 10, 0.0, {150,90,60, 255}, 0); 
			TE_SendToAll(); 
			
			float fl_Velocity[3];
			if (distance > 40)
			{
				float fl_Time = distance / 160;
				fl_Velocity[0] = (clientVec[0] - targetVec[0]) / fl_Time;
				fl_Velocity[1] = (clientVec[1] - targetVec[1]) / fl_Time;
				fl_Velocity[2] = (clientVec[2] - targetVec[2]) / fl_Time;
			}
			else
			{
				fl_Velocity[0] = 0.0
				fl_Velocity[1] = 0.0
				fl_Velocity[2] = 0.0
			}
			
			TeleportEntity(target, NULL_VECTOR, NULL_VECTOR, fl_Velocity); 
		}  
	} 
	
	if(IsClientInGame(target) && IsPlayerAlive(target) && ZP_IsPlayerZombie(target))
	{
		if(g_hook_timer[clientIndex])
		{
			KillTimer(g_hook_timer[clientIndex])
			g_hook_timer[clientIndex] = null;
			SetEntPropFloat(target, Prop_Data, "m_flLaggedMovementValue", 1.0); 
			g_InUse[clientIndex] = false;
		}
	}
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)  
{
	g_over_dmg[victim] = g_over_dmg[victim] + damage;
	
	if(g_over_dmg[victim] >= gF_PAttractingDamage)
	{
		g_over_dmg[victim] = 0.0;

		if(g_hook_timer[victim])
		{
			KillTimer(g_hook_timer[victim]);
		}
		g_InUse[victim] = false;
		g_hook_timer[victim] = null;
		SetEntPropFloat(victim, Prop_Data, "m_flLaggedMovementValue", 1.0); 
	}
	return Plugin_Continue; 
}

public bool TraceRayPlayer(int entityhit, int mask, any self) {
	if(entityhit > 0 && entityhit <= MaxClients && IsPlayerAlive(entityhit) && entityhit != self)
	{
		return true;
	}

	return false;
}