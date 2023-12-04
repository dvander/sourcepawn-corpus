#pragma semicolon 1 

#include <sourcemod>
#include <sdktools>

public Plugin myinfo = {
	name        = "Build in spawn",
	author      = "Bucky420",
	description = "Allows buildings to be placed in spawn by moving it up LOOOOL this if for tf2 btw .....",
	version     = "0.0.1",
	url         = "http://bucksbackyard.us.to/"
};

ConVar g_enabled;
ConVar g_offset;

public OnPluginStart(){
	g_offset = CreateConVar("sm_buildinspawn_offset", "80.0", "change the hight to move spawn for the map 0 to disable");
	g_offset.AddChangeHook(change);
	HookEvent("teamplay_round_start", EventRoundStart);
}

 public void change(ConVar convar, const char[] oldValue, const char[] newValue){
 	movespawn();
 }


public OnMapStart(){
	PrecacheModel("models/error.mdl",true);
}

public Action EventRoundStart(Event event, const char[] name, bool dontBroadcast)
{ 
movespawn();
}

public movespawn(){
	PrintToServer("Bucky is here!");
	new float:offset[3]={0.0,0.0,80.0};
	offset[2]=GetConVarFloat(g_offset);
	PrintToServer("offset: %f",offset[2]);
  	int ent = -1;
    while ((ent = FindEntityByClassname(ent, "func_respawnroom")) != -1)
    {
    new float:min[3];
    new float:max[3];
 	//GetEntPropVector(ent, Prop_Data, "m_vecAbsOrigin",pos);
 	//PrintToServer("pos: %f,%f,%f",pos[0],pos[1],pos[2]);
 	TeleportEntity(ent,offset, NULL_VECTOR, NULL_VECTOR);
 	
 	GetEntPropVector(ent, Prop_Send, "m_vecMins",min);
 	GetEntPropVector(ent, Prop_Send, "m_vecMaxs",max);
	//PrintToServer("max start: %f,%f,%f",max[0],max[1],max[2]);
	//PrintToServer("min start: %f,%f,%f",min[0],min[1],min[2]);
 	PrintToServer("moved min: %f,%f,%f",min[0],min[1],min[2]);
 	PrintToServer("moved max: %f,%f,%f",max[0],max[1],max[2]);
    }	
}  

