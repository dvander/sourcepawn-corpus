#include <sourcemod>
#include <sdktools>
#include <hooker>

#pragma semicolon 1

#define FragColor 	{225,0,0,225}
#define FlashColor 	{225,225,225,225}
#define SmokeColor	{0,225,0,225}

new BeamSprite;
new Handle:GTrailsEnabled;

public Plugin:myinfo = 
{
	name = "Grenade Trails",
	author = "Fredd",
	description = "Adds a trail to grenades.",
	version = "1.1",
	url = "www.sourcemod.net"
}
public OnMapStart() BeamSprite = PrecacheModel("materials/sprites/crystal_beam1.vmt");

public OnPluginStart()
{
	CreateConVar("gt_version", "1.1", "Grenade Trails Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	GTrailsEnabled		= CreateConVar("gt_enables", 	"1", 		"Enables/Disables Grenade Trails");	
}
public HookerOnEntityCreated(Entity, const String:Classname[])
{
	if(GetConVarInt(GTrailsEnabled) != 1)
		return;
	
	if(strcmp(Classname, "hegrenade_projectile") == 0)
	{
		TE_SetupBeamFollow(Entity, BeamSprite,	0, Float:1.0, Float:10.0, Float:10.0, 5, FragColor);
		TE_SendToAll();
		
	} else if(strcmp(Classname, "flashbang_projectile") == 0)
	{
		TE_SetupBeamFollow(Entity, BeamSprite,	0, Float:1.0, Float:10.0, Float:10.0, 5, FlashColor);
		TE_SendToAll();
	} else if(strcmp(Classname, "smokegrenade_projectile") == 0)
	{
		TE_SetupBeamFollow(Entity, BeamSprite,	0, Float:1.0, Float:10.0, Float:10.0, 5, SmokeColor);
		TE_SendToAll();	
	}
	return;
}
