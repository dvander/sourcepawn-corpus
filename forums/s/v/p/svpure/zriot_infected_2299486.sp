#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <zriot>
#pragma semicolon 1

#define VERSION "1.0"

//////////////////////////DEFINES////////////////////////////////////////////////////////////////////////////////////////////////
#define SMOKERMODEL "models/player/kuristaja/wraith/wraith.mdl" 						//Smoker	(Pull target)
#define BOOMER "models/player/knifelemon/speed_zombie_origin.mdl"						//Boomer	(Explode on death)
#define GIGANTEMODEL "models/player/mapeadores/morell/amnesia/grunt/grunt.mdl"		//Tank		(Shake/Push)
#define DOOMDOG "models/player/kuristaja/octabrain/octaking.mdl"						//Slime		(Teleport/Invisibility)
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

new Float:slimerTargetVec[3];
new g_SmokeModel;
new Handle:repeatTimer;
new g_sprite;


public Plugin:myinfo =
{
	name = "Zriot Infections",
	author = "Tarnish",
	description = "Infected",
	version = VERSION
};

public OnPluginStart()
{
	repeatTimer = CreateTimer(0.5, DotInfo, _, TIMER_REPEAT);
	HookEvent("player_death", PlayerDeath);
}

public OnPluginEnd()
{
	if (repeatTimer != INVALID_HANDLE)
		KillTimer(repeatTimer);
	repeatTimer = INVALID_HANDLE;
}

public OnMapStart()
{
	g_sprite = PrecacheModel("materials/sprites/dg/smoker_tongue.vmt");
}

public Action:DotInfo(Handle:timer) 
{    
	new String:model[256]; 
	for (new client = 1; client < MaxClients; client++) 
	{ 
		if (!IsValidEdict(client))
		continue;  
    
		if (IsClientInGame(client) && IsPlayerAlive(client) && ZRiot_IsClientZombie(client)) 
		{ 
			
			GetClientModel(client, model, sizeof(model));
			if (StrEqual(model, SMOKERMODEL))
			{
				new target; 
				target = GetClientAimTarget(client, true); 
				SetEntityRenderColor(client, 128, 0, 128, 255);
				SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.25);
				SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
				if (target > 0) 
				{ 
					if(ZRiot_IsClientZombie(target)) 
						continue; 


					new Float:clientVec[3]; 
					new Float:targetVec[3]; 
					GetClientAbsOrigin(client, clientVec); 
					GetClientAbsOrigin(target, targetVec); 
                
					if (GetVectorDistance(clientVec, targetVec) < 500) //Distance
					{ 
						clientVec[2] += 10; 
						targetVec[2] += 10; 
						new Float:clientEyeVec[3]; 
						new Float:targetWepVec[3]; 
						GetClientEyePosition(client, clientEyeVec); 
						GetClientEyePosition(target, targetWepVec); 
						TE_SetupBeamPoints(clientEyeVec, targetWepVec, g_sprite, 0, 0, 0, 0.5, 3.0, 3.0, 10, 0.0, {92,51,23,255}, 0); //{9,127,187,187}
						TE_SendToAll(); 
						
						new Float:eyeVec[3]; 
						new Float:speedVec[3]; 
						GetClientEyeAngles(client, eyeVec); 
						GetAngleVectors(eyeVec, speedVec, NULL_VECTOR, NULL_VECTOR); 
						speedVec[0]*=-500;  
						speedVec[1]*=-500;  
						speedVec[2]*=550; 
						SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 0.0); 
						TeleportEntity(target, NULL_VECTOR, NULL_VECTOR, speedVec); 
					} 
				} 
				continue; 
			}
			else if (StrEqual(model, GIGANTEMODEL))
			{
				new target;
				target = GetClientAimTarget(client, true);
				
				if (target > 0) 
				{
					if(ZRiot_IsClientZombie(target)) 
						continue; 
				
					new Float:clientVec[3];
					new Float:targetVec[3];
					GetClientAbsOrigin(client, clientVec);
					GetClientAbsOrigin(target, targetVec);
					
					if (GetVectorDistance(clientVec, targetVec) < 120)
					{
						new Float:eyeAngles[3];
						new Float:push[3];
						GetClientEyeAngles(client, eyeAngles);
						push[0] = (2500.0 * Cosine(DegToRad(eyeAngles[1])));
						push[1] = (2500.0 * Sine(DegToRad(eyeAngles[1])));
						push[2] = 1500.0;
						TeleportEntity(target, NULL_VECTOR, NULL_VECTOR, push);
						ScreenShake(target);
						
						new targetHealth = (GetClientHealth(target) - 25);
					
						if ((targetHealth) <= 0)
							ForcePlayerSuicide(target);
						else
							SetEntityHealth(target, targetHealth);
					}
					
					if (GetRandomInt(1, 6) == 4)
					{
						ScreenShake(target);
					}
				}
				continue; 
			}
			else if (StrEqual(model, DOOMDOG))
			{
				new randomNum2 = GetRandomInt(1, 8);
				if (randomNum2 == 4)
				{
					new target = GetClientAimTarget(client, true);
					if (target > 0)
					{
						SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 0.0);
						GetClientAbsOrigin(target, slimerTargetVec);
						CreateTimer(0.1, DelayedSlimerTeleport, client);
					}
				}
			}
		}
	} 
} 

public PlayerDeath(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
   	new String:model[256];
   	GetClientModel(client, model, sizeof(model));
   	if (StrEqual(model, BOOMER))
   	{
		new ExplosionIndex = CreateEntityByName("env_explosion");
		if (ExplosionIndex != -1)
		{
			SetEntProp(ExplosionIndex, Prop_Data, "m_spawnflags", 16384);
			SetEntProp(ExplosionIndex, Prop_Data, "m_iMagnitude", 300);
			SetEntProp(ExplosionIndex, Prop_Data, "m_iRadiusOverride", 400);

			DispatchSpawn(ExplosionIndex);
			ActivateEntity(ExplosionIndex);
		
			new Float:playerEyes[3];
			GetClientEyePosition(client, playerEyes);
			new clientTeam = GetEntProp(client, Prop_Send, "m_iTeamNum");

			TeleportEntity(ExplosionIndex, playerEyes, NULL_VECTOR, NULL_VECTOR);
			SetEntPropEnt(ExplosionIndex, Prop_Send, "m_hOwnerEntity", client);
			SetEntProp(ExplosionIndex, Prop_Send, "m_iTeamNum", clientTeam);

			AcceptEntityInput(ExplosionIndex, "Explode");
			AcceptEntityInput(ExplosionIndex, "Kill");
		}
	}
}

public ScreenShake(client)
{
	new Handle:msg;
	msg = StartMessageOne("Shake", client);
	
	PbSetInt(msg, "command", 0); 
	PbSetFloat(msg, "local_amplitude", 20.0);
	PbSetFloat(msg, "frequency", 100.0);
	PbSetFloat(msg, "duration", 3.0);
	EndMessage();
}

public Action:DelayedSlimerTeleport(Handle:timer, any:client)
{
	new Float:slimerVec[3];
	GetClientAbsOrigin(client, slimerVec);
	TE_SetupSmoke(slimerVec, g_SmokeModel, 50.0, 2);
	TE_SendToAll();
	slimerTargetVec[2]+= 30.0; //+= 10.0
	slimerTargetVec[1]-= 30.0;
	TeleportEntity(client, slimerTargetVec, NULL_VECTOR, NULL_VECTOR);
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 2.0);
}