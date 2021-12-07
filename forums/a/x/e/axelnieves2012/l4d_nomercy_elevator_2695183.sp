#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.0"

#define MODEL_PROPANE "models/props_junk/propanecanister001a.mdl"

public Plugin myinfo =
{
	name = "L4D1 No Mercy Elevator Doors",
	author = "Axel Juan Nieves",
	description = "",
	version = PLUGIN_VERSION,
	url = ""
};

Handle l4d_nomercy_elevator_enable;

public void OnMapStart()
{
	PrecacheModel(MODEL_PROPANE);
}

public void OnPluginStart()
{
	CreateConVar("l4d_nomercy_elevator_version", PLUGIN_VERSION, "", FCVAR_DONTRECORD|FCVAR_NOTIFY);
	l4d_nomercy_elevator_enable = CreateConVar("l4d_nomercy_elevator_enable", "1", "Enable/disable this plugin", 0);
	
	AutoExecConfig(true, "l4d_nomercy_elevator");
	//LoadTranslations("l4d_nomercy_elevator");
	
	HookEvent("round_freeze_end", event_round_freeze_end, EventHookMode_PostNoCopy);
}

public void event_round_freeze_end(Event event, const char[] name, bool dontBroadcast)
{
	char mapname[32];
	int entity = INVALID_ENT_REFERENCE;

	GetCurrentMap(mapname, sizeof(mapname));

	if ( strcmp(mapname, "l4d_hospital04_interior")==0 )
	{
		while ( (entity = FindEntityByClassname(entity, "func_elevator"))!=INVALID_ENT_REFERENCE )
		{
			PrintToChatAll("Hooking elevator");
			HookSingleEntityOutput(entity, "OnReachedBottom", OnReachedBottom, true);
			break;
		}
	}
}

stock void OnReachedBottom(const char[] output, int caller, int activator, float delay)
{
	if ( !GetConVarBool(l4d_nomercy_elevator_enable) )
		return;
	
	//Remove every door:
	int entity = INVALID_ENT_REFERENCE;
	while ( (entity = FindEntityByClassname(entity, "func_door"))!=INVALID_ENT_REFERENCE )
	{
		//Create an explosion on Door...
		int explosion = CreateEntityByName("prop_physics");
		if ( IsValidEntity(explosion) )
		{
			//PrintToChatAll("EXPLOSION CREATED");
			DispatchKeyValue(explosion, "physdamagescale", "0.0");
			DispatchKeyValue(explosion, "model", MODEL_PROPANE);
			DispatchSpawn(explosion); //spawn a propane tank
			SetEntityRenderMode(explosion, RENDER_NONE); //make propane tank invisible
			SetVariantString("!activator");
			AcceptEntityInput(explosion, "SetParent", entity);
			TeleportEntity(explosion, view_as<float>({0.0, 0.0, 0.0}), view_as<float>({0.0, 0.0, 0.0}), NULL_VECTOR);
			SetEntityMoveType(explosion, MOVETYPE_VPHYSICS);
			AcceptEntityInput(explosion, "Break"); //detonate propane tank
			AcceptEntityInput(explosion, "ClearParent");
			RemoveEntity(explosion);//remove it from world
		}
		
		//PrintToChatAll("REMOVING DOOR");
		if ( IsValidEntity(entity) )
			RemoveEntity(entity);
	}
	
	//Remove ceiling:
	char name[16];
	entity = INVALID_ENT_REFERENCE;
	while ( (entity = FindEntityByClassname(entity, "prop_dynamic"))!=INVALID_ENT_REFERENCE )
	{
		GetEntPropString(entity, Prop_Data, "m_iName", name, sizeof(name));
		if ( strcmp(name, "elevator_model")==0 )
		{
			RemoveEntity(entity);
			break;
		}
	}
	
	//create an "invisible wall" to prevent go out from elevator thru ventilation duct
	entity = CreateEntityByName("trigger_push");
	if ( IsValidEntity(entity) )
	{	
		DispatchKeyValue(entity, "pushdir", "0 90 0");  
		DispatchKeyValue(entity, "speed", "500");   //push speed
		DispatchKeyValue(entity, "spawnflags", "1");
		DispatchKeyValue(entity, "StartDisabled", "0");
		DispatchSpawn(entity);
		ActivateEntity(entity);
		TeleportEntity(entity, view_as<float>({13432.0, 15112.0, 664.0}), NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(entity, MODEL_PROPANE);
		SetEntProp(entity, Prop_Send, "m_nSolidType", 2);
	}
} 

stock int IsValidClientInGame(int client)
{
	if (IsValidClientIndex(client))
	{
		if (IsClientInGame(client))
			return 1;
	}
	return 0;
}

stock int IsValidClientIndex(int index)
{
	if (index>0 && index<=MaxClients)
	{
		return 1;
	}
	return 0;
}