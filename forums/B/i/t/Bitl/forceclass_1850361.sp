#include <sourcemod>
#include <tf2_stocks>

new Handle:sm_fcc_class;
 
public Plugin:myinfo =
{
	name = "[TF2] Force Change Class",
	author = "Bitl",
	description = "Forces all users to be a class.",
	version = "1.2",
	url = ""
}
 
public OnPluginStart()
{
	sm_fcc_class = CreateConVar( "sm_fcc_class", "0", "Forces all users to change to a class. 1 - Scout, 2 - Soldier, 3 - Pyro, 4 - Demoman, 5 - Heavy, 6 - Engineer, 7 - Medic, 8 - Sniper, 9 - Spy", FCVAR_NOTIFY, true, 0.0, true, 9.0 );
	
	HookEvent("player_spawn", event_PlayerSpawn);
}

public event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	switch(GetConVarInt(sm_fcc_class)) 
	{ 
		case 1: TF2_SetPlayerClass(client, TFClass_Scout); 
		case 2: TF2_SetPlayerClass(client, TFClass_Soldier);
		case 3: TF2_SetPlayerClass(client, TFClass_Pyro);		
		case 4: TF2_SetPlayerClass(client, TFClass_DemoMan); 
		case 5: TF2_SetPlayerClass(client, TFClass_Heavy);
		case 6: TF2_SetPlayerClass(client, TFClass_Engineer);
		case 7: TF2_SetPlayerClass(client, TFClass_Medic);
		case 8: TF2_SetPlayerClass(client, TFClass_Sniper);
		case 9: TF2_SetPlayerClass(client, TFClass_Spy);
	}
}