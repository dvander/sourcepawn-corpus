#include <sourcemod>
#include <sdktools_engine>
#include <sdktools_functions>
#include <sdktools_trace>
#include <sdktools_entinput>
#define PLUGIN_VERSION "2.0"

public Plugin:myinfo = 
{
	name = "cDux",
	author = "Astrak",
	description = "Spawn bonus ducks for your Duck Journal!",
	version = "1.0",
	url = ""
}

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	CreateConVar("sm_dux_version", PLUGIN_VERSION, "Spawn bonus ducks for your Duck Journal!", FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	RegAdminCmd("sm_dux", Command_Dux, ADMFLAG_ROOT, "sm_dux - Spawn some BONUS DUCKS!.");
	RegAdminCmd("sm_nodux", Command_noDux, ADMFLAG_ROOT, "sm_nodux - Remove all BONUS DUCKS! nu moar dux 4 u.");
}

public Action:Command_Dux(client,args)
{
	decl Float:start[3], Float:angle[3], Float:end[3]; 
	GetClientEyePosition(client, start); 
	GetClientEyeAngles(client, angle); 
	TR_TraceRayFilter(start, angle, MASK_SOLID, RayType_Infinite, TraceEntityFilterPlayer, client); 
	if (TR_DidHit(INVALID_HANDLE)) 
	{	 
		TR_GetEndPosition(end, INVALID_HANDLE); 
	}
	
	new dux = CreateEntityByName("tf_bonus_duck_pickup")
	
	if (client)
	{
		DispatchSpawn(dux)
		TeleportEntity(dux, end, NULL_VECTOR, NULL_VECTOR);
	}
	
	return Plugin_Handled;
}

public bool:TraceEntityFilterPlayer(entity, contentsMask, any:data)  
{ 
	return entity > MaxClients; 
}  

public Action:Command_noDux(client,args)
{
	remove_entity_all("tf_bonus_duck_pickup");

	return Plugin_Handled;
}

remove_entity_all(String:classname[])
{
	new ent = -1;
	while((ent = FindEntityByClassname(ent, classname)) != -1)
	{
		PrintToServer("classname(%s) %i", classname, ent);
		AcceptEntityInput(ent, "Kill");
	}
}