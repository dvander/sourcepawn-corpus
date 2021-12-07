#pragma semicolon 1
#include <sourcemod>
#include <basestock>
#include <database>
#include <sdktools>
/**
 * =============================================================================
 * ImDawe plugin
 * www.neogames.eu Plugin / Mod request section for plugin request
 * SourceMod (C)2004-2007 AlliedModders LLC.  All rights reserved.
 * CONTACT:
 * MSN/MAIL: imdawe@hotmail.com
 * STEAM: csokikola
 * Add me if you have any question
 * =============================================================================
 */
 
/***************
	DEFINES
***************/
#define VERSION 		"1.0"
#define NAME 			"[CSS] !TURREt"
#define AUTHOR	 		"ImDawe"
#define DESCRIPTION 	"!TURRET"

/***************
	CVARS
***************/

/***************
	VARIABLES
***************/
new g_Turrets[MAXPLAYERS+1]={-1,...};
new bool:g_TurretCanShoot[MAXPLAYERS+1]={true,...};
new Float:g_fTurretAim[MAXPLAYERS+1]={0.0,...};
new bool:g_bTurretAim[MAXPLAYERS+1]={true,...};
new Float:MinNadeHull[3] = {-2.5, -2.5, -2.5};
new Float:MaxNadeHull[3] = {5.5, 5.5, 5.5};
new bool:g_BringTurret[MAXPLAYERS+1]={false,...};
new g_BeamSprite;
new g_HaloSprite;
/***************
	INCLUDES
***************/

/***************
	REGISTER PLUGIN
***************/

public Plugin:myinfo =
{
	name = NAME,
	author = AUTHOR,
	description = DESCRIPTION,
	version = VERSION,
	url = ""
};

public OnPluginStart()
{

	
	RegisterConVar("sm_turret_version", VERSION, "Version of x plugin", TYPE_STRING);

	RegConsoleCmd("sm_turret", CreateTurret);

	HookEvent("round_start", OnRoundStart);
	PrecacheSound("player/damage1.wav");
	PrecacheSound("player/damage2.wav");
	PrecacheSound("player/damage3.wav");
	g_BeamSprite = PrecacheModel("materials/sprites/laser.vmt");
	g_HaloSprite = PrecacheModel("materials/sprites/halo01.vmt");
}


public Action:OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(new i=0;i<64;++i)
	{
		g_Turrets[i]=-1;
		g_TurretCanShoot[i]=true;
		g_BringTurret[i]=false;
	}
	return Plugin_Continue;
}


/***************
	FUNCTIONS
***************/


public Action:CreateTurret(client, args)
{
	if(g_Turrets[client] != -1)
	{
		PrintToChat(client, "You have a turret already!");
		return Plugin_Handled;
	}
	new ent = CreateEntityByName("prop_physics_override");
	if(ent != -1)
	{
		PrecacheModel("models/Combine_turrets/floor_turret.mdl");
		SetEntityModel(ent, "models/Combine_turrets/floor_turret.mdl");
		DispatchSpawn(ent);
		
		SetEntPropFloat(ent, Prop_Send, "m_flCycle", 0.1);
		
		decl Float:pos[3], Float:angle[3], Float:vecDir[3];
		
		GetClientEyeAngles(client, angle);
		GetAngleVectors(angle, vecDir, NULL_VECTOR, NULL_VECTOR);
		GetClientEyePosition(client, pos); 
		
		pos[0]+=vecDir[0]*100.0;
		pos[1]+=vecDir[1]*100.0;
		pos[2]-=60.0;
		angle[0]=0.0;
		TeleportEntity(ent, pos, angle, NULL_VECTOR);
		g_Turrets[client]=ent;
	}else{
		PrintToChat(client, "Invalid enttiy:(");
	}
}

public OnGameFrame()
{
	LoopIngamePlayers(i)
	{
		if(g_Turrets[i]!=-1)
		{
			TickTurret(i);
		}
	}
}

TickTurret(client)
{
	new ClosestEnemy;
	new Float:EnemyDistance;
	decl Float:TurretPos[3];
	
	GetEntPropVector(g_Turrets[client], Prop_Send, "m_vecOrigin", TurretPos);
	new iTeam = GetClientTeam(client);
	for(new i=1;i<MaxClients;++i)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i))
		if (GetClientTeam(i) != iTeam)
		{
			decl Float:EnemyPos[3];
			GetClientEyePosition(i, EnemyPos);
			new Float:m_vecMins[3];
			new Float:m_vecMaxs[3];
			GetEntPropVector(g_Turrets[client], Prop_Send, "m_vecMins", m_vecMins);
			GetEntPropVector(g_Turrets[client], Prop_Send, "m_vecMaxs", m_vecMaxs);
			
			TR_TraceHullFilter(TurretPos, EnemyPos, m_vecMins, m_vecMaxs, MASK_SOLID, DontHitOwnerOrNade, client);
			if(TR_GetEntityIndex() == i)
			{
				TurretTickFollow(client, i);
				return;
			}
		}
	}
	TurretTickIdle(client);
}

TurretTickIdle(client)
{
	if(g_fTurretAim[client] <= 0.1)
	{
		g_bTurretAim[client]=true;
	}	
	if(g_fTurretAim[client] >= 0.9)
	{
		g_bTurretAim[client]=false;	
	}
	
	
	
	if(g_bTurretAim[client])
	{
		g_fTurretAim[client]=FloatAdd(g_fTurretAim[client], 0.01);
	}
	else{
		g_fTurretAim[client]=FloatSub(g_fTurretAim[client], 0.01);
	}
	SetEntPropFloat(g_Turrets[client], Prop_Send, "m_flPoseParameter", g_fTurretAim[client], 0);
	SetEntPropFloat(g_Turrets[client], Prop_Send, "m_flPoseParameter", 0.5, 1);
}

TurretTickFollow(owner, player)
{
	decl Float:TurretPos[3], EnemyPos[3], Float:EnemyAngle[3], Float:TuretAngle[3], Float:vecDir[3];
	
	GetEntPropVector(g_Turrets[owner], Prop_Send, "m_angRotation", TuretAngle);
	GetEntPropVector(g_Turrets[owner], Prop_Send, "m_vecOrigin", TurretPos);
	GetClientAbsOrigin(player, EnemyPos);

	MakeVectorFromPoints(EnemyPos, TurretPos, vecDir);
	GetVectorAngles(EnemyPos, EnemyAngle);
	GetVectorAngles(vecDir, vecDir);
	vecDir[2]=0.0;

	TuretAngle[1]+=180.0;

	new Float:m_iDegreesY = 0.0;
	new Float:m_iDegreesX= (((vecDir[1]-TuretAngle[1])+30.0)/60.0);
	
	if(m_iDegreesX < 0.0 || m_iDegreesX > 1.0)
	{
		TurretTickIdle(owner);
		return;
	}
	g_fTurretAim[owner] = m_iDegreesX;
	SetEntPropFloat(g_Turrets[owner], Prop_Send, "m_flPoseParameter", m_iDegreesX, 0);
	SetEntPropFloat(g_Turrets[owner], Prop_Send, "m_flPoseParameter", m_iDegreesY, 1);
	
	if(g_TurretCanShoot[owner])
	{
		TurretPos[2]+=50.0;
		EnemyPos[2]=FloatAdd(EnemyPos[2], GetRandomFloat(10.0, 40.0));
		EnemyPos[0]=FloatAdd(EnemyPos[0], GetRandomFloat(-5.0, 5.0));
		EnemyPos[1]=FloatAdd(EnemyPos[1], GetRandomFloat(-5.0, 5.0));
		TE_SetupBeamPoints(TurretPos, EnemyPos, g_BeamSprite, g_HaloSprite, 0, 30, GetRandomFloat(0.1, 0.3), 1.0, 1.0, 0, 1.0, {255,250,0, 100}, 0);
		TE_SendToAll();
		new hp = GetClientHealth(player)-15;
		if(hp <= 0.0)
		{
			ForcePlayerSuicide(player);
		}else{
			SetEntityHealth(player, hp);
			decl String:szFile[128];
			Format(szFile, sizeof(szFile), "player/damage%d.wav", GetRandomInt(1, 3));
			EmitSoundToClient(player, szFile);
			EmitAmbientSound("weapons/sg550/sg550-1.wav", TurretPos);
		}
		g_TurretCanShoot[owner]=false;
		CreateTimer(0.1, TurretSetState, owner);
	}
}

public Action:TurretSetState(Handle:Timer, any:data)
{
	g_TurretCanShoot[data]=true;
	
}

public bool:DontHitOwnerOrNade(entity, contentsMask, any:data)
{
	if(entity > 0 && entity < 65 && IsClientInGame(entity))
		return true;
	return false;
}
 
 
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(g_BringTurret[client] && IsPlayerAlive(client))
	{
		if(buttons & IN_USE)
		{
			g_BringTurret[client]=false;
		}else{
			decl Float:pos[3], Float:angle[3], Float:vecDir[3];
			
			GetClientEyeAngles(client, angle);
			GetAngleVectors(angle, vecDir, NULL_VECTOR, NULL_VECTOR);
			GetClientEyePosition(client, pos); 
			
			pos[0]+=vecDir[0]*100.0;
			pos[1]+=vecDir[1]*100.0;
			pos[2]-=60.0;
			angle[0]=0.0;
			TeleportEntity(g_Turrets[client], pos, angle, NULL_VECTOR);
		}
	}else{
		if(buttons & IN_USE	)
		{
			new ent = GetClientAimTarget(client, false);
			if(g_Turrets[client]==ent && ent != -1)
			{
				g_BringTurret[client]=true;
			}
		}
	}
	
}

public OnMapStart()
{
	PrecacheSound("weapons/sg550/sg550-1.wav");
	PrecacheSound("player/damage1.wav");
	PrecacheSound("player/damage2.wav");
	PrecacheSound("player/damage3.wav");
	g_BeamSprite = PrecacheModel("materials/sprites/laser.vmt");
	g_HaloSprite = PrecacheModel("materials/sprites/halo01.vmt");
}
/***************
	NATIVES
***************/
