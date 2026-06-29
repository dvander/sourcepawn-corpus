#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <zombieplague>
//#include <emitsoundany>

#pragma newdecls required

public Plugin ZombieClassGirl =
{
	name        	= "[ZP] Zombie Class: Smoker",
	author      	= "Extr1m (Michail)",
	description 	= "Addon of zombie classses",
	version     	= "1.0",
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


Handle g_hook_timer[MAXPLAYERS+1];

bool g_InUse[MAXPLAYERS+1] = false;

float g_over_dmg[MAXPLAYERS + 1];
float g_AttractingLastTime[MAXPLAYERS + 1];

char g_sprite;

int gZombieSmoker;
#pragma unused gZombieSmoker

public void OnPluginStart()
{
	gCV_PEnabled 				= 	CreateConVar("sm_smoker_enabled", "1", "Responsible for the operation of the class on the server", 0, true, 0.0, true, 1.0);
	gCV_PAttractingCooldown 	= 	CreateConVar("sm_smoker_cooldown", "18.0", "Time between each use", 0, true, 0.0, true, 60.0);
	gCV_PAttractingDistance		= 	CreateConVar("sm_smoker_distance", "2000.0", "Maximum distance between attacker and victim", 0, true, 0.0, true, 10000.0);
	gCV_PAttractingDamage		= 	CreateConVar("sm_smoker_damage", "700.0", "How much damage do I need to interrupt", 0, true, 0.0, true, 5000.0);

	gCV_PEnabled.AddChangeHook(ConVarChange);
	gCV_PAttractingCooldown.AddChangeHook(ConVarChange);
	gCV_PAttractingDistance.AddChangeHook(ConVarChange);
	gCV_PAttractingDamage.AddChangeHook(ConVarChange);
	
	gB_PEnabled = gCV_PEnabled.BoolValue;
	gF_PAttractingCooldown = gCV_PAttractingCooldown.FloatValue;
	gF_PAttractingDistance = gCV_PAttractingDistance.FloatValue;
	gF_PAttractingDamage = gCV_PAttractingDamage.FloatValue;
	
	AutoExecConfig(true, "zr_class_smoker", "sourcemod/zp_class");
	
	HookEvent("round_start", OnRoundStart);
}

public void OnLibraryAdded(const char[] sLibrary)
{
    // Validate library
    if (!strcmp(sLibrary, "zombieplague", false))
    {
        // If map loaded, then run custom forward
        if (ZP_IsMapLoaded())
        {
            // Execute it
            ZP_OnEngineExecute();
        }
    }
}

public void ZP_OnEngineExecute(/*void*/)
{
    gZombieSmoker = ZP_GetClassNameID("zsmoker");
}

public void OnMapStart()
{
	g_sprite = PrecacheModel("materials/sprites/purplelaser1.vmt"); 

	for(int i = 1; i <= MaxClients; i++)
	{
		g_AttractingLastTime[i] = 0.0;
	}
}

public void ConVarChange(ConVar CVar, const char[] oldVal, const char[] newVal)
{
	gB_PEnabled = gCV_PEnabled.BoolValue;
	gF_PAttractingCooldown = gCV_PAttractingCooldown.FloatValue;
	gF_PAttractingDistance = gCV_PAttractingDistance.FloatValue;
	gF_PAttractingDamage = gCV_PAttractingDamage.FloatValue;
}

public void OnClientPutInServer(int client) 
{ 
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);  
} 

public void OnClientDisconnect(int client)
{ 
   SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);  
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
	
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(g_InUse[client])
	{
		KillTimer(g_hook_timer[client])
		g_hook_timer[client] = null;
		g_InUse[client] = false;
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{	
	if (gB_PEnabled && IsPlayerExist(client) && ZP_GetClientClass(client) == gZombieSmoker)
	{
		if (!g_InUse[client] && (buttons & (IN_RELOAD) == (IN_RELOAD)))
		{	
			if (GetGameTime() - g_AttractingLastTime[client] < gF_PAttractingCooldown) 
			{
				PrintHintText(client, "Reloading - %.1f", gF_PAttractingCooldown - (GetGameTime() - g_AttractingLastTime[client]));
				return Plugin_Continue;
			}
			
			Handle pack = CreateDataPack();
		
			int target = GetClientAimTarget(client);
			
			if(IsPlayerExist(target) && IsPlayerAlive(target) && ZP_IsPlayerZombie(target))
				return Plugin_Continue;
				
			if(IsPlayerExist(target))
			{
				float fOriginClient[3];
				float fOriginTarget[3];
				
				GetClientAbsOrigin(client, fOriginClient);
				GetClientAbsOrigin(target, fOriginTarget);
				
				float fDistance = GetVectorDistance(fOriginClient, fOriginTarget);
				
				if(fDistance > gF_PAttractingDistance)
					return Plugin_Continue;
				
				WritePackCell(pack, client);
				WritePackCell(pack, target);
				
				g_hook_timer[client] = CreateTimer(0.1, hooked, pack, TIMER_REPEAT)
				
				
				g_InUse[client] = true;
				g_AttractingLastTime[client] = GetGameTime();
			}
		}
		else if (g_InUse[client] && !(buttons & (IN_RELOAD) == (IN_RELOAD)))
		{
			if(g_hook_timer[client])
			{
				KillTimer(g_hook_timer[client])
				g_hook_timer[client] = null;
				SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0); 
				g_InUse[client] = false;
			}
		}
	}
	return Plugin_Continue;
}

public Action hooked(Handle timer, Handle pack)
{
	ResetPack(pack);
	
	int client = ReadPackCell(pack);
	int target = ReadPackCell(pack);
	
	if (IsClientInGame(client) && IsPlayerAlive(client) && ZP_IsPlayerZombie(client)) 
	{ 
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0); 
		if (target > 0) 
		{  
			float clientVec[3]; 
			float targetVec[3]; 
			GetClientAbsOrigin(client, clientVec); 
			GetClientAbsOrigin(target, targetVec); 

			float distance = GetVectorDistance(clientVec, targetVec);
		
			clientVec[2] += 10; 
			targetVec[2] += 10; 
			float clientEyeVec[3]; 
			float targetWepVec[3]; 
			GetClientEyePosition(client, clientEyeVec); 
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
			
			SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 0.0); 
			TeleportEntity(target, NULL_VECTOR, NULL_VECTOR, fl_Velocity); 
		}  
	} 
	
	if(IsClientInGame(target) && IsPlayerAlive(target) && ZP_IsPlayerZombie(target))
	{
		if(g_hook_timer[client])
		{
			KillTimer(g_hook_timer[client])
			g_hook_timer[client] = null;
			SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0); 
			SetEntPropFloat(target, Prop_Data, "m_flLaggedMovementValue", 1.0); 
			g_InUse[client] = false;
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