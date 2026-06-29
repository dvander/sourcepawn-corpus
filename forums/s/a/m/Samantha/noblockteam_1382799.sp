#include <sourcemod>
#include <sdktools>

#include <sdkhooks>

#define VERSION "1.0"

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

}

public OnClientPutInServer( Client )
{
	SDKHook( Client, SDKHook_StartTouch, OnTouch );
}

public OnTouch( Client, Ent )
{
	if( Ent > 0 && Ent <= MaxClients )
	{
		if( GetClientTeam( Client ) == GetClientTeam( Ent ) )
		{
			SetEntProp(Client, Prop_Data, "m_CollisionGroup", 2);
		}
		else
			SetEntProp(Client, Prop_Data, "m_CollisionGroup", 5);
	}
	else
		SetEntProp(Client, Prop_Data, "m_CollisionGroup", 5);
}