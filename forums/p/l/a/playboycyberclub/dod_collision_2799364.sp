#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>

#define PL_VERSION "1.0"

public Plugin:myinfo = 
{
	name = "DoD:S Player Collision",
	author = "BenSib, playboycyberclub",
	description = "reenable player collision (disabled by palermo update)",
	version = PL_VERSION,
	url = "http://www.dodsplugins.com"
}

public OnPluginStart()
{
	CreateConVar("dod_collision_version", PL_VERSION, "DoD:S Player Collision", FCVAR_DONTRECORD|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	SetConVarString(FindConVar("dod_collision_version"),PL_VERSION);
}

public OnClientPostAdminCheck(client)
{
	if(IsClientInGame(client))
	{
		SDKHook(client, SDKHook_ShouldCollide, OnShouldCollide);
	}
}

public bool:OnShouldCollide(client, collisionGroup, contentsMask, bool:originalResult)
{
	return true;
}
