#pragma semicolon 1   // preprocessor?  whatever, no idea what it does. but im leaving it
#include <sourcemod>  //  bleh. i figure i need this.
#include <sdktools>   // not even sure i need this, but im leaving it

#define PLUGIN_VERSION "0.1b"
#define PLUGIN_NAME "We're not Immune"

new GameMode = 2;

public Plugin:myinfo = 
{
	name = "We're not Immune",  // just a name
	author = "xyster", // aka steve seguin
	description = "Survivors turn undead on death",
	version = PLUGIN_VERSION,  //  whatever; variable called earlier
	url = "http://wassh.us"  // my clan site
};

public OnPluginStart()      //  The pimp function, cause it calls all the hookers
{
	
	CreateConVar("l4d2_WNI_version", PLUGIN_VERSION, " Version of WereNotImmune plugin on this server ", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD); // add version info to cfg file
	

	HookEvent("player_say", Event_PlayerSay); 				 // catch anything any player says
	HookEvent("versus_round_start", Event_RoundStart, EventHookMode_PostNoCopy);   // I have no idea why postnocopy is used here, but whatever
        HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post ); 	// In case someone dies, run function
	HookEvent("revive_begin", Event_StartRevive, EventHookMode_Pre);
	HookEvent("revive_end", Event_EndRevive, EventHookMode_Pre);
	HookEvent("revive_success", Event_EndRevive, EventHookMode_Pre);
	HookEvent("player_incapacitated", Event_Incap);
	HookEvent("player_hurt", Event_PlayerHurt);
	//HookEvent("player_team", EventPlayerTeamChange, EventHookMode_Pre);
	
}

public OnMapStart ()   // safe room event?
{ 
if (GameMode==2){
    decl String:mapname[128];
    GetCurrentMap(mapname, sizeof(mapname));
    new counter = 0;

    if (StrContains( mapname, "m1", false) > 0 )  // if first map of a campaign, reset all counters
    {
   	for (new i = 1; i <= MaxClients; i++) 
   	{ 
        	if (GetClientTeam(i) != 2 )  // 3=infected team, 2=surv team, 1=spec, >4=classes
        	{ 
			 
         	   		ChangeClientTeam(i, 2);  // set all players on new camp to survivors
			
        	} 
    	} 
    }
    else
    {
	for (new i = 1; i <= MaxClients; i++) 
   	{ 
        	if (GetClientTeam(i) == 2 )  // 3=infected team, 2=surv team, 1=spec, >4=classes
        	{ 
         	   counter++;  // how many survivors are there
        	} 
    	} 
	if (counter == 0)  // if there are no survivors on map start...
	{
	 	for (new t = 1; t <= MaxClients; t++) 
   		{ 
         	 
				ChangeClientTeam(t, 2);  // set all players to survivors
			
        	}  	
	}

    }
}
} 


public Action:SayStuff(Handle:timer)          //  lets people know the plugin is enabled and explains the concept briefly after round start
{
if (GameMode==2){

		PrintToChatTeam(2, "You are not immune to the infection.  Survive or be turned!");
}
}	

public Event_StartRevive(Handle:event, const String:name[], bool:dontBroadcast)   // EVENT:  Trying to revive a player. no no no.!
{
if (GameMode==2){
	new client = GetClientOfUserId(GetEventInt(event, "userid")); // player doing the reviving
	PrintToChat(client, "It looks like they are already turning!  I wouldn't get too close if I were you...");
}
}

public Event_EndRevive(Handle:event, const String:name[], bool:dontBroadcast)   // EVENT:  Trying to revive a player. no no no.!
{
if (GameMode==2){
   //  deal damage to the person who tried to res
   //  tell person he just got bit. 
   //  stop the trigger from working.

	new client = GetClientOfUserId(GetEventInt(event, "userid"));  // player doing the reviving
	PrintToChat(client, "OUCH!  THEY BIT YOU!  They must have already turned!");

	DamageEffect(client); // damage effect so they know they got hit
	new hardhp = GetEntProp(client, Prop_Data, "m_iHealth") +2;  // get health
	SetEntityHealth(client, hardhp - 10);  // deal 10 dmg
	return Plugin_Handled;  // do not revive the player.
}
}

public Action:DamageEffect(target)
{
if (GameMode==2){
	new pointHurt = CreateEntityByName("point_hurt");			// Create point_hurt
	DispatchKeyValue(target, "targetname", "hurtme");				// mark target (client), with the key "targetname" with the value "hurtme"
	DispatchKeyValue(pointHurt, "Damage", "0");					// No Damage, just HUD display. Does stop Reviving though (mark the pointHurt with damage key of 0)
	DispatchKeyValue(pointHurt, "DamageTarget", "hurtme");		// Target Assignment (mark pointHurt with a target, using the previously set value on the client)
	DispatchKeyValue(pointHurt, "DamageType", "DMG_BLAST");			// Type of damage (set type on the pointHurt)
	DispatchSpawn(pointHurt);										// Spawn descriped point_hurt
	AcceptEntityInput(pointHurt, "Hurt"); 						// Trigger point_hurt execute (use predefined Hurt command to do damage to target)
	AcceptEntityInput(pointHurt, "Kill"); 						// Remove point_hurt
	DispatchKeyValue(target, "targetname",	"cake");			// Clear target's mark (ie, not the target next time)
}
}

public Event_Incap(Handle:event, const String:name[], bool:dontBroadcast)   // EVENT:  Trying to revive a player. no no no.!
{
	// just in case i want to use it
}

public Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new iCurrentTeam = GetClientTeam( client );  
	new hardhp = GetEntProp(client, Prop_Data, "m_iHealth") + 2;  // get health
	if (hardhp < 25 && hardhp > 0 && iCurrentTeam == 2)
	{
		PrintToChatTeam(2, "One of your teammates is beginning to feel very ill. Keep a close eye on them.");
	}
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)   // EVENT: The round has started
{
	GameMode=2;
	CreateTimer(40.0, SayStuff);	  //  //  lets people know the plugin is enabled and explains the concept briefly after round start
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)   // EVENT: A player has died. oh noes.
{
if (GameMode==2){
	new client = GetClientOfUserId(GetEventInt(event, "userid"));     	  // find out who died
	new iCurrentTeam = GetClientTeam( client );       			 // what team were they on?
	
	if (iCurrentTeam == 2)  			// If dead guy = survivior.. ;;;  3=infected team, 2=surv team, 1=spec, >4=classes
	{                  			
		PrintToChatAll("\x04%N\x01 has succumb to the infection. Beware!", client); // announce the player has died.
		ChangeClientTeam(client, 3);      // Move dead guy to zombie team.
		
	}
}
}

public Action:Event_PlayerSay(Handle:event, const String:name[], bool:dontBroadcast)       // catches everything every player says
{

	new client = GetClientOfUserId(GetEventInt(event, "userid"));       // find out who said what
	new iCurrentTeam = GetClientTeam( client );        // what team were they on?

	new String:text[200];
	GetEventString(event, "text", text, 200);  // what did they say
	
	//  do nothing.  This function just here in case I need to add any chat commands down the road.
}

PrintToChatTeam(team, const String:message[])   // a function used for chating to just one team, and not both; 3=infected, 2=surv, 1=spec, >4=classes
{ 
if (GameMode==2){
    for (new i = 1; i <= MaxClients; i++) 
    { 
        if (GetClientTeam(i) == team) 
        { 
            PrintToChat(i, message); 
        } 
    } 
}
}  
