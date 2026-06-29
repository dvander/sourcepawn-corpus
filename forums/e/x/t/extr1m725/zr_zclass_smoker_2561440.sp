#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <zr_tools>
#include <zombiereloaded>

public Plugin myinfo =
{
	name        	= "[ZP] Zombie Class: Smoker",
	author      	= "Extr1m (Michail)",
	description 	= "Adds a unique class of zombies",
	version     	= "1.0",
	url         	= "https://sourcemod.net/"
}

ConVar gCV_PEnabled = null;
ConVar gCV_PAttractingCooldown = null;
ConVar gCV_PAttractingDistance = null;
ConVar gCV_PAttractingDamage = null;

bool 	gB_PEnabled = true;
float 	gF_PAttractingCooldown;
float 	gF_PAttractingDistance;
float 	gF_PAttractingDamage;


new Handle:g_hook_timer[MAXPLAYERS+1];

new bool:g_InUse[MAXPLAYERS+1];
new bool:g_LeapClassEnable[MAXPLAYERS + 1]
new Float:g_over_dmg[MAXPLAYERS + 1];
new Float:g_AttractingLastTime[MAXPLAYERS + 1];

new String:g_sprite;

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
	
	AutoExecConfig(true, "zr_class_smoker", "zombiereloaded");
	
	HookEvent("round_start", OnRoundStart);
}

public void OnMapStart()
{
	g_sprite = PrecacheModel("materials/sprites/purplelaser1.vmt"); 

	for (new i = 1; i <= MaxClients; i++)
	{
		g_AttractingLastTime[i] = INVALID_HANDLE;
	}
}

public void ConVarChange(ConVar CVar, const char[] oldVal, const char[] newVal)
{
	gB_PEnabled = gCV_PEnabled.BoolValue;
	gF_PAttractingCooldown = gCV_PAttractingCooldown.FloatValue;
	gF_PAttractingDistance = gCV_PAttractingDistance.FloatValue;
	gF_PAttractingDamage = gCV_PAttractingDamage.FloatValue;
}

public ZR_OnClientInfected(client, attacker, bool:motherInfect, bool:respawnOverride, bool:respawn)
{
	decl String:buffer[64];
	ZRT_GetClientAttributeString(client, "class_zombie", buffer, sizeof(buffer));
	
	if(StrEqual(buffer, "smoker", false))
		g_LeapClassEnable[client] = true;
	else
		g_LeapClassEnable[client] = false;
}

public void OnClientPutInServer(client) 
{ 
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);  
} 

public OnClientDisconnect(client) 
{ 
   SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);  
}  

public OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast) 
{
	for (new i = 1; i <= MaxClients; i++)
	{
		g_InUse[i] = INVALID_HANDLE;
		if(g_hook_timer[i])
		{
			KillTimer(g_hook_timer[i])
		}
		g_hook_timer[i] = null;
	}
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(g_InUse[client])
	{
		KillTimer(g_hook_timer[client])
		g_hook_timer[client] = null;
		g_InUse[client] = INVALID_HANDLE;
	}
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon, &subtype, &cmdnum, &tickcount, &seed, mouse[2])
{
	if (gB_PEnabled && IsPlayerAlive(client) && IsValidClient(client) && ZR_IsClientZombie(client) && (GetEntityFlags(client) & FL_ONGROUND))
	{
		if(g_LeapClassEnable[client])
		{
			if (!g_InUse[client] && (buttons & (IN_RELOAD) == (IN_RELOAD)))
			{	
				if (GetGameTime() - g_AttractingLastTime[client] < gF_PAttractingCooldown) 
				{
					PrintHintText(client, "Reloading - %.1f", gF_PAttractingCooldown - (GetGameTime() - g_AttractingLastTime[client]));
					return Plugin_Continue;
				}
				
				new Handle:pack = CreateDataPack();
			
				new target = TraceToPlayer(client);
				
				if(IsValidClient(target) && IsPlayerAlive(target) && ZR_IsClientZombie(target))
					return Plugin_Continue;
					
				if(target != 0)
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
	}
	return Plugin_Continue;
}
 
public Action:hooked(Handle:timer, Handle:pack)
{
	ResetPack(Handle:pack);
	
	new client = ReadPackCell(pack);
	new target = ReadPackCell(pack);
	
	if (IsClientInGame(client) && IsPlayerAlive(client) && ZR_IsClientZombie(client)) 
	{ 
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0); 
		if (target > 0) 
		{  
			new Float:clientVec[3]; 
			new Float:targetVec[3]; 
			GetClientAbsOrigin(client, clientVec); 
			GetClientAbsOrigin(target, targetVec); 

			new Float:distance = GetVectorDistance(clientVec, targetVec);
		
			clientVec[2] += 10; 
			targetVec[2] += 10; 
			new Float:clientEyeVec[3]; 
			new Float:targetWepVec[3]; 
			GetClientEyePosition(client, clientEyeVec); 
			GetClientEyePosition(target, targetWepVec); 
			TE_SetupBeamPoints(clientEyeVec, targetWepVec, g_sprite, 0, 0, 0, 0.5, 3.0, 3.0, 10, 0.0, {150,90,60, 255}, 0); 
			TE_SendToAll(); 
			
			new Float:fl_Velocity[3];
			if (distance > 40)
			{
				new Float:fl_Time = distance / 160;
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
	
	if(IsClientInGame(target) && IsPlayerAlive(target) && ZR_IsClientZombie(target))
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

public Action:OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)  
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

public TraceToPlayer(client)
{
	new Float:vecClientEyePos[3], Float:vecClientEyeAng[3];
	GetClientEyePosition(client, vecClientEyePos);
	GetClientEyeAngles(client, vecClientEyeAng);

	TR_TraceRayFilter(vecClientEyePos, vecClientEyeAng, MASK_PLAYERSOLID, RayType_Infinite, TraceRayPlayer, client);

	if (TR_DidHit(INVALID_HANDLE))
	{
                new ent = TR_GetEntityIndex(INVALID_HANDLE);
                if(ent != 0)
                {
                        return ent;
                }
	}

	return 0;
}

public bool:TraceRayPlayer(entityhit, mask, any:self) {
	if(entityhit > 0 && entityhit <= MaxClients && IsPlayerAlive(entityhit) && entityhit != self)
	{
		return true;
	}

	return false;
}

bool IsValidClient(int client) 
{ 
	if (client < 1) 
		return false; 
	if (client > MaxClients) 
		return false; 
	if (!IsClientInGame(client)) 
		return false;     
	if (!IsPlayerAlive(client))
		return false; 

	return true; 
}