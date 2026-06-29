#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#pragma semicolon 1
#pragma newdecls required

//#define PLUGIN_VERSION "1.1"
#define PLUGIN_VERSION "1.1 BETA 1"
#define MODEL_PROPANE "models/props_junk/propanecanister001a.mdl"
#define SPRITE_EXPLOSION "sprites/ar2_muzzle2b"
#define INF_SMOKER	1
#define INF_BOOMER	2
#define INF_HUNTER	4
#define INF_WITCH	8
#define INF_TANK	16


public Plugin myinfo =
{
	name = "L4D1 No Mercy Elevator Doors",
	author = "Axel Juan Nieves",
	description = "",
	version = PLUGIN_VERSION,
	url = ""
};

Handle l4d_nomercy_elevator_enable;
Handle l4d_nomercy_elevator_fall;
Handle l4d_nomercy_elevator_infected;
Handle l4d_nomercy_elevator_open_manually;
Handle l4d_nomercy_elevator_quick_upwards;
//char sInfectedName[6][8] = {"", "Smoker", "Boomer", "Hunter", "Witch", "Tank"};
//int g_iInfectedEnt = INVALID_ENT_REFERENCE;
int g_iElevator = INVALID_ENT_REFERENCE;

public void OnMapStart()
{
	PrecacheModel(MODEL_PROPANE);
	PrecacheModel(SPRITE_EXPLOSION);
}

public void OnPluginStart()
{
	CreateConVar("l4d_nomercy_elevator_version", PLUGIN_VERSION, "", FCVAR_DONTRECORD|FCVAR_NOTIFY);
	l4d_nomercy_elevator_enable = CreateConVar("l4d_nomercy_elevator_enable", "1", "Enable/disable this plugin", 0);
	l4d_nomercy_elevator_fall = CreateConVar("l4d_nomercy_elevator_fall", "1", "Break elevator on reaching top floor?", 0);
	l4d_nomercy_elevator_infected = CreateConVar("l4d_nomercy_elevator_infected", "31", "Spawn an infected on elevator. 0=None, 1=Smoker, 2=Boomer, 4=Hunter, 8=Witch, 16=Tank", 0, true, 0.0, true, 31.0);
	l4d_nomercy_elevator_open_manually = CreateConVar("l4d_nomercy_elevator_open_manually", "1", "Opens elevator's door as long as it arrives to floor?", 0);
	l4d_nomercy_elevator_quick_upwards = CreateConVar("l4d_nomercy_elevator_quick_upwards", "1", "Make elevator go faster upside direction?", 0);
	
	AutoExecConfig(true, "l4d_nomercy_elevator");
	//LoadTranslations("l4d_nomercy_elevator");
	
	HookEvent("round_freeze_end", event_round_freeze_end, EventHookMode_PostNoCopy);
}

public void event_round_freeze_end(Event event, const char[] name, bool dontBroadcast)
{
	char buffer[64];
	GetCurrentMap(buffer, sizeof(buffer));
	int entity = INVALID_ENT_REFERENCE;

	if ( strcmp(buffer, "l4d_hospital04_interior")!=0 )
		return;
	
	while ( (entity = FindEntityByClassname(entity, "func_elevator"))!=INVALID_ENT_REFERENCE )
	{
		//Hook reach bottom...
		HookSingleEntityOutput(entity, "OnReachedBottom", OnReachedBottom, true);
		
		//increase upwards speed...
		SetVariantString("OnReachedBottom !self:SetSpeed:600.0:0.0:-1"); 
		AcceptEntityInput(entity, "AddOutput");
		g_iElevator = EntIndexToEntRef(entity); //make it global
		break;
	}
		
	//prepare a zombie to spawn on elevator later...
	entity = CreateEntityByName("commentary_zombie_spawner");
	if ( IsValidEntity(entity) )
	{
		DispatchKeyValue(entity, "targetname", "elev_infected");
		DispatchSpawn(entity);
		TeleportEntity(entity, view_as<float>({13440.0, 15260.0, 470.0}), view_as<float>({0.0, 270.0, 0.0}), NULL_VECTOR); //tank
		//g_iInfectedEnt = EntIndexToEntRef(entity);
	}
}

stock void OnReachedBottom(const char[] output, int caller, int activator, float delay)
{
	if ( !GetConVarBool(l4d_nomercy_elevator_enable) )
		return;
	
	char classname[32], sCommand[64];
	int entity;
	int infected = GetConVarInt(l4d_nomercy_elevator_infected);
	char sInfectedName[5][8] = {"Smoker", "Boomer", "Hunter", "Witch", "Tank"};
	
	//prepare doors to be open manually...
	entity = INVALID_ENT_REFERENCE;
	while ( (entity=FindEntityByClassname(entity, "logic_relay"))!=INVALID_ENT_REFERENCE )
	{
		GetEntPropString(entity, Prop_Data, "m_iName", classname, sizeof(classname));
		if ( strcmp(classname, "elevator_bottom_relay")==0 )
		{
			//lock doors temporary, so they dont open automatically...
			SetVariantString("OnTrigger door_elev*:Lock::1.0:-1");
			AcceptEntityInput(entity, "AddOutput");
			break;
		}
	}
	
	//open doors whenever they try to close...
	entity = INVALID_ENT_REFERENCE;
	while ( (entity=FindEntityByClassname(entity, "func_door"))!=INVALID_ENT_REFERENCE )
	{
		GetEntPropString(entity, Prop_Data, "m_iName", classname, sizeof(classname));
	
		SetVariantString("OnClose !self:Open::1.8:-1");
		AcceptEntityInput(entity, "AddOutput");
	}
	
	entity = INVALID_ENT_REFERENCE;
	while ( (entity=FindEntityByClassname(entity, "func_button"))!=INVALID_ENT_REFERENCE )
	{
		GetEntPropString(entity, Prop_Data, "m_iName", classname, sizeof(classname));
		
		//we need to respawn button to make it usable again...
		//but we will Lock it to prevent firing extra panic events...
		AcceptEntityInput(entity, "Lock");
		DispatchKeyValue(entity, "wait", "-1");
		DispatchSpawn(entity);
		
		if ( infected )
		{
			int rand;
			//force choose a random infected of desired ones in l4d_nomercy_elevator_infected...
			while ( (rand=GetRandomInt(0, 4))!=5 )
			{
				if ( (1<<rand) & infected )
				{
					//Spawn random special infected...
					FormatEx(sCommand, sizeof(sCommand), "OnUseLocked elev_infected:SpawnZombie:%s:0.0:1", sInfectedName[rand]);
					SetVariantString(sCommand);
					AcceptEntityInput(entity, "AddOutput");
					break;
				}
			}
		}
		//unlock doors...
		SetVariantString("OnUseLocked door_elev*:Unlock::0.0:-1");
		AcceptEntityInput(entity, "AddOutput");
		
		//open doors manually...
		SetVariantString("OnUseLocked door_elev*:Open::1.0:-1");
		AcceptEntityInput(entity, "AddOutput");
		break;
	}
	
	//remove ceiling....
	entity = INVALID_ENT_REFERENCE;
	while ( (entity=FindEntityByClassname(entity, "prop_dynamic"))!=INVALID_ENT_REFERENCE )
	{
		GetEntPropString(entity, Prop_Data, "m_iName", classname, sizeof(classname));
		if ( strcmp(classname, "elevator_model")==0 )
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
	//----------------------------------------------------------------------------------------------
	
	//create a witch on duct...
	entity = CreateEntityByName("witch");
	if ( IsValidEntity(entity) )
	{	
		TeleportEntity(entity, view_as<float>({13440.0, 15053.0, 670.0}), view_as<float>({0.0, 90.0, 0.0}), NULL_VECTOR); //tank
		SetEntPropFloat(entity, Prop_Send, "m_rage", 0.0); // Rage!!
		SetEntProp(entity, Prop_Data, "m_nSequence", 4); // Sit
		DispatchSpawn(entity);
	}
	
	int elevator = EntRefToEntIndex(g_iElevator);
	if ( !IsValidEntity(elevator) )
	{
		PrintToServer("Invalid elevator, NOT hooking");
		PrintToChatAll("Invalid elevator, NOT hooking");
		return;
	}
	
	//Increase upwards speed...
	if ( GetConVarBool(l4d_nomercy_elevator_quick_upwards) )
	{
		if ( IsValidEntity(elevator) )
		{
			DispatchKeyValue(elevator, "acceleration", "50");
			DispatchKeyValue(elevator, "speed", "650");
		}
	}
	
	//hook reach top floor...
	if ( GetConVarBool(l4d_nomercy_elevator_fall) )
	{
		HookSingleEntityOutput(elevator, "OnReachedTop", OnReachedTop, true);
	}
}

//----------------------------------------------------------------------------------
//----------------------------------------------------------------------------------
//----------------------------------------------------------------------------------
//----------------------------------------------------------------------------------

stock void OnReachedTop(const char[] output, int caller, int activator, float delay)
{
	if ( !GetConVarBool(l4d_nomercy_elevator_enable) )
		return;
	if ( !GetConVarBool(l4d_nomercy_elevator_fall) )
		return;
	
	int elevator = EntRefToEntIndex(g_iElevator);
	if ( !IsValidEntity(elevator) )
	{
		LogError("OnReachedTop() invalid elevator entity");
		return;
	}
	
	//create an explosion...
	int explosion = CreateEntityByName("env_explosion");
	if ( IsValidEntity(explosion) )
	{
		SetEntPropString(explosion, Prop_Data, "m_iName", "elevator_explosion");
		DispatchKeyValue(explosion, "iMagnitude", "40.0");
		DispatchKeyValue(explosion, "fireballsprite", SPRITE_EXPLOSION);
		DispatchKeyValue(explosion, "rendermode", "Normal");
		DispatchSpawn(explosion);
		SetVariantString("!activator");
		AcceptEntityInput(explosion, "SetParent", elevator);
		TeleportEntity(explosion, view_as<float>({0.0, 0.0, 0.0}), view_as<float>({0.0, 0.0, 0.0}), NULL_VECTOR);
		ActivateEntity(explosion);
		SetVariantString("OnUser1 !self:Explode::5.0:1");
		AcceptEntityInput(explosion, "AddOutput");
		AcceptEntityInput(explosion, "FireUser1");
	}
	
	//Make elevator fall down...
	/*DispatchKeyValue(elevator, "acceleration", "999");
	DispatchKeyValue(elevator, "speed", "700");
	
	SetVariantString("OnUser1 !self:MoveToFloor:bottom:5.6:1");
	AcceptEntityInput(elevator, "AddOutput");
	AcceptEntityInput(elevator, "FireUser1");*/
	SetEntityMoveType(elevator, MOVETYPE_NOCLIP);
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