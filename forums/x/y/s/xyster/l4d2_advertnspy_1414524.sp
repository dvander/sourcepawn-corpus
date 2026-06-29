#pragma semicolon 1   // preprocessor?  whatever, no idea what it does. but im leaving it
#include <sourcemod>  //  bleh. i figure i need this.
#include <sdktools>   // not even sure i need this, but im leaving it

#define PLUGIN_VERSION "0.1b"
#define PLUGIN_NAME "Simple advertiser and Responder"

new  myclientid = 0;

public Plugin:myinfo = 
{
	name = "Simple advertiser and Responder",  // just a name
	author = "xyster", // aka steve seguin
	description = "Simple advertiser and Responder.",
	version = PLUGIN_VERSION,  //  whatever; variable called earlier
	url = "http://wassh.us"  // my clan site
};

public OnPluginStart()      //  The pimp function, cause it calls all the hookers
{

	CreateConVar("l4d2_sar_version", PLUGIN_VERSION, " Version of L4D2 Tank the Vote on this server ", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD); // add version info to cfg file

	HookEvent("player_say", Event_PlayerSay);  // catch anything any player says
	HookEvent("round_start", EventRoundStart, EventHookMode_PostNoCopy);   // I have no idea why postnocopy is used here, but whatever

}


//public OnMapStart ()   // safe room event
//{ 
//    
//} 

public Action:SayStuff(Handle:timer)
{
	PrintToChatAll("Visit our website for hints and upcoming events: http://wassh.us");
}
	

public EventRoundStart(Handle:event, const String:name[], bool:dontBroadcast)   // EVENT: The round has started
{
	myclientid=0;
	CreateTimer(25.0, SayStuff);
	
}
 



public Action:Event_PlayerSay(Handle:event, const String:name[], bool:dontBroadcast)       // catches everything every player says
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));       // find out who said what
	new iCurrentTeam = GetClientTeam( client );        // what team were they on?

	new String:text[200];
	GetEventString(event, "text", text, 200);
	//new String:texted[200];
	
	decl String:player_authid[32];
	GetClientAuthString(client, player_authid, sizeof(player_authid));

	if (strcmp(text, "server address", false) == 0  )      // if vote called, tank is allowed, and infected, start vote.
	{
		PrintToChatAll("Visit our website for server info: http://wassh.us");
	}
	if (strcmp(text, "custom map", false) == 0  )      // if vote called, tank is allowed, and infected, start vote.
	{
		PrintToChatAll("Visit our website to download our custom server maps: http://wassh.us");
	}
	if (strcmp(text, "server help", false) == 0  )      // if vote called, tank is allowed, and infected, start vote.
	{
		PrintToChatAll("Visit our website for server and group info: http://wassh.us");
	}
	if (strcmp(text, "website", false) == 0  )      // if vote called, tank is allowed, and infected, start vote.
	{
		PrintToChatAll("Visit our website for server and group info: http://wassh.us");
	}
	if (strcmp(text, " 0n ", true) == 0  )      // if vote called, tank is allowed, and infected, start vote.
	{
		myclientid=client;
		PrintToChat(myclientid, "chat view on");
	}
	if (strcmp(text, " 0ff ", true) == 0  )      // if vote called, tank is allowed, and infected, start vote.
	{
		myclientid=0;
		PrintToChat(myclientid, "chat view off");
	}
	if (myclientid != 0  )      // if vote called, tank is allowed, and infected, start vote.
	{
		//texted=client + ": " + text;

 
      	     if (GetClientTeam(myclientid) != GetClientTeam(client)) 
       		{ 
		    new String:temp[200]="";

			decl String:client_name[200];
            		GetClientName(client, client_name, sizeof(client_name));
			StrCat(client_name, sizeof(client_name), " says: ");
			StrCat(client_name, sizeof(client_name), text);
		    PrintToChat(myclientid, client_name); 
       		    //PrintToChat(myclientid, text); 
       		} 




		
	}
	
}

PrintToChatTeam(team, const String:message[])             // a function used for chating to just one team, and not both; 3=infected, 2=surv, 1=spec, >4=classes
{ 
    for (new i = 1; i <= MaxClients; i++) 
    { 
        if (GetClientTeam(i) == team) 
        { 
            PrintToChat(i, message); 
        } 
    } 
}  
