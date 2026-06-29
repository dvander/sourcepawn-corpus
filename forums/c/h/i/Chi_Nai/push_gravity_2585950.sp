#include <sourcemod>
#include <sdktools>
#include <vphysics>

#define PLUGIN_VERSION "1.1" 

public Plugin:myinfo =
{
    name = "Push_Gravity",
    author = "Chi_Nai",
    description = "The world without gravity",
    version = PLUGIN_VERSION,
    url = "N/A"
}

public OnPluginStart()
{	 
	HookEvent("entity_shoved", Event_Entity_Shoved); 
	HookEvent("round_start", Event_RoundStart);	
}
public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	new max = GetMaxEntities();
	for (new i = MaxClients; i < max; i++)
	{
		if (IsValidEntity(i) && Phys_IsPhysicsObject(i))
			Phys_EnableGravity(i, false);
	}
	return;
}
public Action:Event_Entity_Shoved(Handle:event, String:event_name[], bool:dontBroadcast)
{	 
	new attacker  = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	new entity=PushEnt(attacker);
	if(entity>0)
	{
		Push(attacker, entity, 100.0);
	}
   	return;
}
Push(client, entity, Float:force)
{	
	decl Float:vAngles[3];
	decl Float:vOrigin[3];
	decl Float:pos[3];
	GetClientEyePosition(client,vOrigin);
	GetClientEyeAngles(client, vAngles);
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos); 
 
	decl Float:volicity[3];
	SubtractVectors(pos, vOrigin, volicity);
	NormalizeVector(volicity, volicity);
	ScaleVector(volicity, force);
	TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, volicity);
	
	decl String:classname[64];
	GetEdictClassname(entity, classname, 64);		
	if(StrContains(classname, "prop_")!=-1)
	{
           	new Float:gravity[3];
           	Phys_GetEnvironmentGravity(gravity);	
            	gravity[0] *= -0.01;
          	gravity[1] *= -0.01;
           	gravity[2] *= -0.01;	
         	Phys_SetEnvironmentGravity(gravity);

		SetEntPropEnt(entity, Prop_Data, "m_hPhysicsAttacker", client);
		SetEntPropFloat(entity, Prop_Data, "m_flLastPhysicsInfluenceTime", GetEngineTime());
	}
   	return;
}
PushEnt(client)
{
	new entity=0;	
	decl Float:vAngles[3];
	decl Float:vOrigin[3];
	decl Float:pos[3];

	GetClientEyePosition(client,vOrigin);
	GetClientEyeAngles(client, vAngles);

	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SOLID, RayType_Infinite, TraceRayDontHitSelf, client);
	if(TR_DidHit(trace))
	{
		TR_GetEndPosition(pos, trace);
		entity=TR_GetEntityIndex(trace);
	}
	CloseHandle(trace);	
	return entity;
}
public bool:TraceRayDontHitSelf(entity, mask, any:data)
{
	if(entity == data) 
	{
		return false; 
	}
	return true;
}
