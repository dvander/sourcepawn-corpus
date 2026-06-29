#pragma semicolon 1   // preprocessor?  whatever, no idea what it does. but im leaving 
#pragma newdecls required
#include <sourcemod>  //  bleh. i figure i need this.
#include <sdktools>   // not even sure i need this, but im leaving it

#define PLUGIN_VERSION "0.1b"
#define PLUGIN_NAME "We're not Immune"

int GameMode = 2;

public Plugin myinfo = 
{
	name = "We're not Immune",  // just a name
	author = "xyster", // aka steve seguin
	description = "Survivors turn undead on death",
	version = PLUGIN_VERSION,  //  whatever; variable called earlier
	url = "http://wassh.us"  // my clan site
};

public void OnPluginStart()      //  The pimp function, cause it calls all the hookers
{
	CreateConVar("l4d2_WNI_version", PLUGIN_VERSION, " Version of WereNotImmune plugin on this server ", FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD); // add version info to cfg file

	HookEvent("player_say", Event_PlayerSay); 				 // catch anything any player says
	HookEvent("versus_round_start", Event_RoundStart, EventHookMode_PostNoCopy);   // I have no idea why postnocopy is used here, but whatever
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post); 	// In case someone dies, run function
	//HookEvent("player_team", EventPlayerTeamChange, EventHookMode_Pre);
}

public void OnMapStart()   // safe room event?
{
	if (GameMode == 2)
	{
	    char mapname[128];
	    GetCurrentMap(mapname, sizeof(mapname));
	    int counter = 0;

	    if (StrContains(mapname, "m1", false) > 0)  // if first map of a campaign, reset all counters
	    {
	   		for (int i = 1; i <= MaxClients; i++) 
	   		{ 
	        	if (GetClientTeam(i) != 2)  // 3=infected team, 2=surv team, 1=spec, >4=classes
	        	{ 
	         	   	ChangeClientTeam(i, 2);  // set all players on new camp to survivors
	        	}
	    	}
	    }
	    else
	    {
			for (int i = 1; i <= MaxClients; i++) 
	   		{ 
	        	if (GetClientTeam(i) == 2)  // 3=infected team, 2=surv team, 1=spec, >4=classes
	        	{ 
	         	   counter++;  // how many survivors are there
	        	}
	    	}

			if (counter == 0)  // if there are no survivors on map start...
			{
		 		for (int t = 1; t <= MaxClients; t++) 
		 		{ 
					ChangeClientTeam(t, 2);  // set all players to survivors
				}  	
			}
		}
	}
}

public Action SayStuff(Handle timer) //  lets people know the plugin is enabled and explains the concept briefly after round start
{
	if (GameMode == 2)
	{
		PrintToChatTeam(2, "You are not immune to the infection.  Survive or be turned!");
	}
}

public Action DamageEffect(int target)
{
	if (GameMode == 2)
	{
		int pointHurt = CreateEntityByName("point_hurt");			// Create point_hurt
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

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)   // EVENT: The round has started
{
	GameMode = 2;
	CreateTimer(40.0, SayStuff);  ////  lets people know the plugin is enabled and explains the concept briefly after round start
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)   // EVENT: A player has died. oh noes.
{
	if (GameMode == 2)
	{
		int client = GetClientOfUserId(GetEventInt(event, "userid"));     	  // find out who died
		int iCurrentTeam = GetClientTeam(client);       			 // what team were they on?

		if (iCurrentTeam == 2)  // If dead guy = survivior.. ;;;  3=infected team, 2=surv team, 1=spec, >4=classes
		{                  			
			PrintToChatAll("\x04%N\x01 has succumb to the infection. Beware!", client); // announce the player has died.
			ChangeClientTeam(client, 3);  // Move dead guy to zombie team.
		}
	}
}

public Action Event_PlayerSay(Event event, const char[] name, bool dontBroadcast)  // catches everything every player says
{
	char text[200];
	GetEventString(event, "text", text, 200);  // what did they say
	//  do nothing.  This function just here in case I need to add any chat commands down the road.
}

void PrintToChatTeam(int team, const char[] message)   // a function used for chating to just one team, and not both; 3=infected, 2=surv, 1=spec, >4=classes
{
	if (GameMode == 2)
	{
	    for (int i = 1; i <= MaxClients; i++) 
	    { 
	        if (GetClientTeam(i) == team) 
	        {
	            PrintToChat(i, message); 
	        } 
	    }
	}
}
