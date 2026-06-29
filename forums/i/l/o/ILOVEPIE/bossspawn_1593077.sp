#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.0.0"

new Float:g_pos[3];

public Plugin:myinfo =
{
	name = "[TF2] Boss Spawn",
	author = "(AMS-$)ILOVEPIE & Geit & DarthNinja",
	description = "Admin can spawn the Haloween Bosses",
	version = PLUGIN_VERSION,
	url = "http://sourcemod.net"
}
public OnPluginStart(){
	RegAdminCmd("sm_eyeboss", GreatBallRockets, ADMFLAG_RCON);
	RegAdminCmd("sm_horsemann", Command_Spawn, ADMFLAG_RCON);
	
	LoadTranslations("common.phrases.txt");
}
public OnMapStart()
{
	PrecacheModel("models/bots/headless_hatman.mdl");
	PrecacheModel("models/props_halloween/halloween_demoeye.mdl");
	PrecacheModel("models/props_halloween/bombonomicon.mdl");
	PrecacheModel("models/props_halloween/eyeball_projectile.mdl");
	PrecacheModel("models/weapons/c_models/c_bigaxe/c_bigaxe.mdl");
	PrecacheSound("ui/halloween_boss_summon_rumble.wav");
	PrecacheSound("vo/halloween_boss/knight_alert.wav");
	PrecacheSound("vo/halloween_boss/knight_alert01.wav");
	PrecacheSound("vo/halloween_boss/knight_alert02.wav");
	PrecacheSound("vo/halloween_boss/knight_attack01.wav");
	PrecacheSound("vo/halloween_boss/knight_attack02.wav");
	PrecacheSound("vo/halloween_boss/knight_attack03.wav");
	PrecacheSound("vo/halloween_boss/knight_attack04.wav");
	PrecacheSound("vo/halloween_boss/knight_death01.wav");
	PrecacheSound("vo/halloween_boss/knight_death02.wav");
	PrecacheSound("vo/halloween_boss/knight_dying.wav");
	PrecacheSound("vo/halloween_boss/knight_laugh01.wav");
	PrecacheSound("vo/halloween_boss/knight_laugh02.wav");
	PrecacheSound("vo/halloween_boss/knight_laugh03.wav");
	PrecacheSound("vo/halloween_boss/knight_laugh04.wav");
	PrecacheSound("vo/halloween_boss/knight_pain01.wav");
	PrecacheSound("vo/halloween_boss/knight_pain02.wav");
	PrecacheSound("vo/halloween_boss/knight_pain03.wav");
	PrecacheSound("vo/halloween_boss/knight_spawn.wav");
	PrecacheSound("vo/halloween_eyeball/eyeball_biglaugh01.wav");
	PrecacheSound("vo/halloween_eyeball/eyeball_boss_pain01.wav");
	PrecacheSound("vo/halloween_eyeball/eyeball_laugh01.wav");
	PrecacheSound("vo/halloween_eyeball/eyeball_laugh02.wav");
	PrecacheSound("vo/halloween_eyeball/eyeball_laugh03.wav");
	PrecacheSound("vo/halloween_eyeball/eyeball_mad01.wav");
	PrecacheSound("vo/halloween_eyeball/eyeball_mad02.wav");
	PrecacheSound("vo/halloween_eyeball/eyeball_mad03.wav");
	PrecacheSound("vo/halloween_eyeball/eyeball_teleport01.wav");
	PrecacheSound("vo/halloween_eyeball/eyeball01.wav");
	PrecacheSound("vo/halloween_eyeball/eyeball02.wav");
	PrecacheSound("vo/halloween_eyeball/eyeball03.wav");
	PrecacheSound("vo/halloween_eyeball/eyeball04.wav");
	PrecacheSound("vo/halloween_eyeball/eyeball05.wav");
	PrecacheSound("vo/halloween_eyeball/eyeball06.wav");
	PrecacheSound("vo/halloween_eyeball/eyeball07.wav");
	PrecacheSound("vo/halloween_eyeball/eyeball08.wav");
	PrecacheSound("vo/halloween_eyeball/eyeball09.wav");
	PrecacheSound("vo/halloween_eyeball/eyeball10.wav");
	PrecacheSound("vo/halloween_eyeball/eyeball11.wav");
	PrecacheSound("weapons/halloween_boss/knight_axe_hit.wav");
	PrecacheSound("weapons/halloween_boss/knight_axe_miss.wav");
}
public Action:Command_Spawn(client, args)
{
    if(!SetTeleportEndPoint(client))
    {
        PrintToChat(client, "[SM] Could not find spawn point.");
        return Plugin_Handled;
    }
    if(GetEntityCount() >= GetMaxEntities()-32)
    {
        PrintToChat(client, "[SM] Entity limit is reached. Can't spawn anymore pumpkin lords. Change maps.");
        return Plugin_Handled;
    }
    new entity = CreateEntityByName("headless_hatman");
    if(IsValidEntity(entity))
    {
        DispatchSpawn(entity);
        g_pos[2] -= 10.0;
        TeleportEntity(entity, g_pos, NULL_VECTOR, NULL_VECTOR);
    }
    return Plugin_Handled;
}
public Action:GreatBallRockets(client, args)
{
    if(!SetTeleportEndPoint(client))
    {
        PrintToChat(client, "[SM] Could not find spawn point.");
        return Plugin_Handled;
    }
	/*
    if(GetEntityCount() >= GetMaxEntities()-32)
    {
        PrintToChat(client, "[SM] Entity limit is reached. Can't spawn anymore Eyeballs. Change maps.");
        return Plugin_Handled;
    }
	*/
    new entity = CreateEntityByName("eyeball_boss");
    if(IsValidEntity(entity))
    {
        DispatchSpawn(entity);
        g_pos[2] -= 10.0;
        TeleportEntity(entity, g_pos, NULL_VECTOR, NULL_VECTOR);
    }
    return Plugin_Handled;
}
SetTeleportEndPoint(client)
{
	decl Float:vAngles[3];
	decl Float:vOrigin[3];
	decl Float:vBuffer[3];
	decl Float:vStart[3];
	decl Float:Distance;
	
	GetClientEyePosition(client,vOrigin);
	GetClientEyeAngles(client, vAngles);
	
    //get endpoint for teleport
	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);

	if(TR_DidHit(trace))
	{   	 
   	 	TR_GetEndPosition(vStart, trace);
		GetVectorDistance(vOrigin, vStart, false);
		Distance = -35.0;
   	 	GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
		g_pos[0] = vStart[0] + (vBuffer[0]*Distance);
		g_pos[1] = vStart[1] + (vBuffer[1]*Distance);
		g_pos[2] = vStart[2] + (vBuffer[2]*Distance);
	}
	else
	{
		CloseHandle(trace);
		return false;
	}
	
	CloseHandle(trace);
	return true;
}

public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
	return entity > GetMaxClients() || !entity;
}