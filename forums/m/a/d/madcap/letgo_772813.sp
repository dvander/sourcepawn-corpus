
/* relevant cvars you may want to consider

fall_speed_fatal,ConVar ,,,720
fall_speed_safe,ConVar ,,,560
mp_falldamage,ConVar ,notify,,0
survivor_incap_max_fall_damage,ConVar ,,Taking falling damage greater than this will kill survivors outright instead of incapacitating them,200
survivor_ledge_grab_health,ConVar ,,,300
survivor_ledge_scales_health,ConVar ,cheat,,1
z_debug_falling_damage,ConVar ,cheat,,0
z_debug_ledges,ConVar ,cheat,,0
z_grab_force,ConVar ,cheat,For testing - always grab ledges regardless of estimated falling damage,0

*/



#pragma semicolon 1

#include <sourcemod>

#define VERSION	"0.1"
#define _DEBUG 1


public Plugin:myinfo =
{
    name = "Let Go",
    author = "Madcap",
    description = "Allow players to let go when hanging from a ledge.",
    version = VERSION,
    url = "http://maats.org"
};



new bool:isHanging[MAXPLAYERS+1];
new bool:preventDeath[MAXPLAYERS+1];
new preHangHP[MAXPLAYERS+1];


public OnPluginStart()
{
	HookEvent("player_ledge_grab", eventGrab, EventHookMode_Pre);
	HookEvent("player_ledge_release", eventRelease, EventHookMode_Pre);
	HookEvent("revive_success", eventRevive);
	HookEvent("round_start", eventRoundStart);
	
	HookEvent("player_death", eventPlayerDeath, EventHookMode_Pre);
	
	RegConsoleCmd("drop",Drop);
}



public Action:eventPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{

	//player_death  
	//short  userid  
	//long  entityid  
	//short  attacker  
	//string  attackername  
	//long  attackerentid  
	//bool  headshot  
	//boot  attackerisbot  
	//string  victimname  
	//bool  victimisbot  
	//bool  abort  
	//long  type  
	//float  victim_x  
	//float  victim_y  
	//float  victim_z  
 
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	/*if (preventDeath[client])
	{
		PrintToChat(client, "Trying to stop you from dieing.");
		preventDeath[client]=false;
		return Plugin_Handled;
	}*/	
	
	return Plugin_Continue;

}



public Action:Drop(client, args)
{ 

	if (isHanging[client])
	{

		PrintToChat(client, "Attempting to make you let go...");
	
		// do stuff here to make them let go
		
		// idea 1 - set player's health to 0 (or a low amount)
		
		SetEntityHealth(client, 0);
		CreateTimer(1.0, HPRestore, client);
		
			
		PrintToChat(client, "Done, I hope you let go successfully.");
	
	}
	
	return Plugin_Handled;
}


public eventGrab(Handle:event, const String:name[], bool:dontBroadcast)
{
	// someone started hanging
	
	//player_ledgegrab  
	//short  userid  
	//short  causer  
	//bool  has_upgrade  
	 
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	isHanging[client]=true;
	preHangHP[client]=GetClientHealth(client);
	PrintToChat(client, "You started hanging from a ledge.");
}

public Action:HPRestore(Handle:timer, any:client){
	SetEntityHealth(client, preHangHP[client]);
}

public eventRelease(Handle:event, const String:name[], bool:dontBroadcast)
{
	// someone let go (fell to death)
	
	//player_ledge_release  
	//short  userid  
 
 	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	preventDeath[client]=true;
	isHanging[client]=false;
	PrintToChat(client, "You let go of the ledge.");
}

public eventRevive(Handle:event, const String:name[], bool:dontBroadcast)
{
	// someone was revived from hanging
	
	//revive_success  
	//short  userid  
	//short  subject  
	//bool  lastlife  
	//bool  ledge_hang  
 
	if (GetEventBool(event, "ledge_hang"))
	{
 
 		new client = GetClientOfUserId(GetEventInt(event, "userid"));
 		isHanging[client]=false;
		preventDeath[client]=false;
		PrintToChat(client, "You were rescued from a ledge.");
		
	}
}


public eventRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	// start of round, reset all isHanging values
	
	for(new i=0;i<(MAXPLAYERS+1);i++)
	{
		isHanging[i]=false;
		preventDeath[i]=false;
	}
}


















