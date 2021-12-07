#include <sourcemod>
#include <sdktools>

#include <sdkhooks>

#define VERSION "1.1"

#define COLLISION_GROUP_PLAYER 5

#pragma semicolon 1

public Plugin:myinfo =
{
	name = "NoBlock with Team Filter",
	author = "Samantha",
	description = "Players dont collide if there on the same team.",
	version = VERSION,
	url = "www.foxyden.com"
};

public OnPluginStart()
{
	CreateConVar( "sm_noblockteam_version", VERSION, "Version of Noblock Team Filter", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY );

	HookEvent("player_spawn", Event_Playerspawn);
}

public OnClientPutInServer( Client )
{
	SDKHook( Client, SDKHook_ShouldCollide, ShouldCollide );
}


public Action:Event_Playerspawn(Handle:Event, const String:name[], bool:dontbroadcast)
{
	new Client = GetClientOfUserId(GetEventInt( Event, "userid") );
	SetEntProp(Client, Prop_Data, "m_CollisionGroup", 2);
}

public Action:ShouldCollide( Client, &Collisiongroup, &Contentsmask, &bool:Result)
{
	if ( Contentsmask & CONTENTS_TEAM2  )
	{
		Result = true;
		return Plugin_Changed;
	}

	return Plugin_Continue;
}