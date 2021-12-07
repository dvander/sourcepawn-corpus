/* Explosive Oildrum Spawner by KTM! */

#include <sourcemod>
#include <sdktools> 
#include "dbi.inc"
#include "menus.inc"

new g_BeamSprite;
new g_HaloSprite;

new redColor[4]	= {200, 25, 25, 255};

//plugin info
public Plugin:myinfo = 
{
	name = "Explosive_oildrums_pawner",
	author = "KTM",
	description = "Spawns an oildrum",
	version = "1.2",
	url = "http://www.alliedmodders.com"
}

public OnPluginStart()
{
	CreateConVar("explosive_oildrum_version", "1.2", "KTM's explosive oildrum spawner!",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);

	RegAdminCmd("sm_spawndrum", Command_Spawndrum, ADMFLAG_SLAY,"Spawns an Oildrum");	
}

//Map Start:
public OnMapStart()
{
	g_BeamSprite = PrecacheModel("materials/sprites/laser.vmt");
	g_HaloSprite = PrecacheModel("materials/sprites/halo01.vmt");	
}

//Oildrum Spawner-Command for Hl2-Based Games

public Action:Command_Spawndrum(Client, args)
{
	//Declare:
	decl Drum;
	new Float:AbsAngles[3], Float:ClientOrigin[3], Float:Origin[3], Float:pos[3], Float:beampos[3], Float:FurnitureOrigin[3], Float:EyeAngles[3];
	decl String:Name[255], String:SteamId[255];
	//Initialize:
	
	GetClientAbsOrigin(Client, ClientOrigin);
	GetClientEyeAngles(Client, EyeAngles);
	GetClientAbsAngles(Client, AbsAngles);
	
	
	
	GetCollisionPoint(Client, pos);
	
	FurnitureOrigin[0] = pos[0];
	FurnitureOrigin[1] = pos[1];
	FurnitureOrigin[2] = (pos[2] + 15);
	
	beampos[0] = pos[0];
	beampos[1] = pos[1];
	beampos[2] = (FurnitureOrigin[2] + 20);
	
	//Spawn Drum:
	Drum = CreateEntityByName("prop_physics_override");
	TeleportEntity(Drum, FurnitureOrigin, AbsAngles, NULL_VECTOR);
	
	DispatchKeyValue(Drum, "model", "models/props_c17/oildrum001_explosive.mdl");
	
	DispatchKeyValue(Drum, "health", "20");
	DispatchKeyValue(Drum, "ExplodeDamage","120");
	DispatchKeyValue(Drum, "ExplodeRadius","256");
	DispatchKeyValue(Drum, "spawnflags","8192");
	DispatchSpawn(Drum);
	ActivateEntity(Drum);
	
	//Log
	GetClientAuthString(Client, SteamId, 255);
	GetClientName(Client, Name, 255);
	LogAction(Client, Client, "Client %s <%s> spawned an oildrum!", SteamId, Name);
	PrintToServer("Client %s <%s> spawned an oildrum!", SteamId, Name);
	
	//Send BeamRingPoint:
	GetEntPropVector(Drum, Prop_Data, "m_vecOrigin", Origin);
	TE_SetupBeamRingPoint(FurnitureOrigin, 10.0, 150.0, g_BeamSprite, g_HaloSprite, 0, 10, 0.6, 10.0, 0.5, redColor, 20, 0);
	TE_SendToAll();
	
	return Plugin_Handled;
}

stock GetCollisionPoint(client, Float:pos[3])
{
	decl Float:vOrigin[3], Float:vAngles[3];
	
	GetClientEyePosition(client, vOrigin);
	GetClientEyeAngles(client, vAngles);
	
	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SOLID, RayType_Infinite, TraceEntityFilterPlayer);
	
	if(TR_DidHit(trace))
	{
		TR_GetEndPosition(pos, trace);
		CloseHandle(trace);
		
		return;
	}
	
	CloseHandle(trace);
}

public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
	return entity > MaxClients;
}