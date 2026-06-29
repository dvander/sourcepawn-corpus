#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#pragma semicolon 1
#pragma newdecls required
#define TEAM_SURVIVOR 2
#define PLUGIN_VERSION "1.0"
int ent_dynamic_door1;
int ent_dynamic_door2;

public Plugin myinfo =
{
    name = "L4D1 No Mercy Elevator sb unstick",
    author = "",
    description = "",
    version = PLUGIN_VERSION,
    url = ""
};

public void OnMapStart()
{
}

public void OnPluginStart()
{
	PrecacheModel("models/props_exteriors/lighthouserailing_03_break04.mdl");
	HookEvent("round_freeze_end", event_round_freeze_end, EventHookMode_PostNoCopy);
}

public void event_round_freeze_end(Event event, const char[] name, bool dontBroadcast)
{
	static char sMap[32], sName[64];
	int entity = -1;
	float pos[3];    

	GetCurrentMap(sMap, sizeof(sMap));

	if (strcmp(sMap, "l4d_vs_hospital04_interior") == 0 || strcmp(sMap, "l4d_hospital04_interior") == 0  || strcmp(sMap, "c8m4_interior") == 0)
        {
		while (-1 != (entity = FindEntityByClassname(entity, "func_button")))
		{
		GetEntPropString(entity, Prop_Data, "m_iName", sName, sizeof(sName));
		if (strcmp(sName, "elevator_button") == 0)
		{
                HookSingleEntityOutput(entity, "OnPressed",  OnReachedBottom, true);
                break;
		}
		}
	}
 
	pos[0] = 13464.0;
	pos[1] = 15108.0;
	pos[2] = 424.0;


	ent_dynamic_door1 = CreateEntityByName("prop_dynamic"); 

	DispatchKeyValue(ent_dynamic_door1, "model", "models/props_exteriors/lighthouserailing_03_break04.mdl");
	//DispatchKeyValue(ent_dynamic_door1, "spawnflags", "264");
	DispatchKeyValue(ent_dynamic_door1, "solid", "6");
	DispatchKeyValue(ent_dynamic_door1, "disableshadows", "1");

	DispatchSpawn(ent_dynamic_door1);
	TeleportEntity(ent_dynamic_door1, pos, NULL_VECTOR, NULL_VECTOR);


	pos[0] = 13398.0;
	pos[1] = 15108.0;
	pos[2] = 424.0;

	ent_dynamic_door2 = CreateEntityByName("prop_dynamic"); 

	DispatchKeyValue(ent_dynamic_door2, "model", "models/props_exteriors/lighthouserailing_03_break04.mdl");
	//DispatchKeyValue(ent_dynamic_door2, "spawnflags", "264");
	DispatchKeyValue(ent_dynamic_door2, "solid", "6");
	DispatchKeyValue(ent_dynamic_door2, "disableshadows", "1");

	DispatchSpawn(ent_dynamic_door2);
	TeleportEntity(ent_dynamic_door2, pos, NULL_VECTOR, NULL_VECTOR);

		
	SDKHook(ent_dynamic_door1, SDKHook_Touch, OnTouch);
	SDKHook(ent_dynamic_door2, SDKHook_Touch, OnTouch);

}


stock void OnReachedBottom(const char[] output, int caller, int activator, float delay)
{    
PrintToChatAll ("Unstick now 1");
SetConVarInt(FindConVar("sb_unstick"), 1);
} 

public void OnTouch(int client, int other)
{


//PrintToChatAll("TEST");
if(other > 0 && other <= MaxClients){

if(IsClientInGame(other) && IsFakeClient(other) && GetClientTeam(other) == 2)
{
SetConVarInt(FindConVar("sb_unstick"), 0);
PrintToChatAll ("Unstick now 0");
SDKUnhook(ent_dynamic_door1, SDKHook_Touch, OnTouch);
SDKUnhook(ent_dynamic_door2, SDKHook_Touch, OnTouch);
}

}
}
