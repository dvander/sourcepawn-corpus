/* Spark Effects plugin */

#include <sourcemod>
#include <sdktools>


new Float:Origin[3];
new Float:Direction[3];


public Plugin:myinfo = 
{
	name = "Spark Effects",
	author = "Gruzilkin",
	description = "Adds spark effects to bullet impacts",
	version = "1.0",
	url = "http://www.sourcemod.net/"
}

public OnPluginStart()
{
	HookEvent("bullet_impact",BulletImpact);
}

public BulletImpact(Handle:event,const String:name[],bool:dontBroadcast)
{
	Origin[0] = GetEventFloat(event,"x");
	Origin[1] = GetEventFloat(event,"y");
	Origin[2] = GetEventFloat(event,"z");
	
	Direction[0] = GetRandomFloat(-1.0, 1.0);
	Direction[1] = GetRandomFloat(-1.0, 1.0);
	Direction[2] = GetRandomFloat(-1.0, 1.0);
	
	TE_SetupMetalSparks(Origin, Direction);
	TE_SendToAll();
}