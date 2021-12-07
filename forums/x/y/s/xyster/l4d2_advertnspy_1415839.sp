#pragma semicolon 1   // preprocessor?  whatever, no idea what it does. but im leaving it
#include <sourcemod>  //  bleh. i figure i need this.
#include <sdktools>   // not even sure i need this, but im leaving it

#define PLUGIN_VERSION "0.2b"
#define PLUGIN_NAME "Simple advertiser and Responder"


new Handle:message0 = INVALID_HANDLE;
new Handle:message1 = INVALID_HANDLE;
new Handle:trigger1 = INVALID_HANDLE;
new Handle:message2 = INVALID_HANDLE;
new Handle:trigger2 = INVALID_HANDLE;
new Handle:message3 = INVALID_HANDLE;
new Handle:trigger3 = INVALID_HANDLE;
new Handle:message4 = INVALID_HANDLE;
new Handle:trigger4 = INVALID_HANDLE;
new Handle:spyon = INVALID_HANDLE;
new Handle:spyoff = INVALID_HANDLE;
new Handle:spysteamID = INVALID_HANDLE;


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

	CreateConVar("l4d2_advertnspy_version", PLUGIN_VERSION, " Version of L4D2 Tank the Vote on this server ", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD); // add version info to cfg file

	message0 = CreateConVar("l4d2_advertnspy_message0", "Visit our website for hints and upcoming events: http://wassh.us", " The message displayed 25 seconds after round start ");

	message1 = CreateConVar("l4d2_advertnspy_message1", "Hi!", " Message #1 ");
	trigger1 = CreateConVar("l4d2_advertnspy_trigger1", "hi", " Chat string trigger for message #1. Exact string match.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	message2 = CreateConVar("l4d2_advertnspy_message2", "Visit our website to download our custom server maps: http://wassh.us", " Message #2 ", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	trigger2 = CreateConVar("l4d2_advertnspy_trigger2", "custom maps", " Chat string trigger for message #2. Chat string Contains this string. ", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	message3 = CreateConVar("l4d2_advertnspy_message3", "Visit our website for server and group info: http://wassh.us", " Message #3 ", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	trigger3 = CreateConVar("l4d2_advertnspy_trigger3", "server ip", " Chat string trigger for message #3. Chat string Contains this string.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	message4 = CreateConVar("l4d2_advertnspy_message4", "Visit our website for server and group info: http://wassh.us", " Message #4 ", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	trigger4 = CreateConVar("l4d2_advertnspy_trigger4", "website", " Chat string trigger for message #4. Chat string Contains this string.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);

	spyon = CreateConVar("l4d2_advertnspy_spyontrigger", " 0n ", " Turn on the chat spy feature using this string trigger. caps matter. default is space zero n space  ");
	spyoff = CreateConVar("l4d2_advertnspy_spyofftrigger", " 0ff ", " Turn off the chat spy feature using this string trigger ");

	spysteamID = CreateConVar("l4d2_advertnspy_spysteamID", "STEAM_0:1:808785", " Auto-enable the spy chat feature for this steam-id-enabled player; default is plugin is me. ");

	AutoExecConfig(true, "l4d2_advertnspy"); // load the config file i guess

	HookEvent("player_say", Event_PlayerSay);  // catch anything any player says
	HookEvent("round_start", EventRoundStart, EventHookMode_PostNoCopy);   // I have no idea why postnocopy is used here, but whatever

}


//public OnMapStart ()   // safe room event
//{ 
//    
//} 

public Action:SayStuff(Handle:timer)
{
	new String:tempp[200];
	GetConVarString(message0, tempp, 200);
	PrintToChatAll(tempp);
}
	

public EventRoundStart(Handle:event, const String:name[], bool:dontBroadcast)   // EVENT: The round has started
{
	myclientid=0;
	CreateTimer(25.0, SayStuff);
	
}
 

public Action:Event_PlayerSay(Handle:event, const String:name[], bool:dontBroadcast)       // catches everything every player says
{
	new String:tempp[200];
	new String:temp1[200];
	new String:temp2[200];
	new String:temp3[200];
	new String:temp4[200];
	new String:temp5[200];
	new String:temp6[200];
	GetConVarString(trigger1, temp1, 200);
	GetConVarString(trigger2, temp2, 200);
	GetConVarString(trigger3, temp3, 200);
	GetConVarString(trigger4, temp4, 200);
	GetConVarString(spyon, temp5, 200);
	GetConVarString(spyoff, temp6, 200);

	new client = GetClientOfUserId(GetEventInt(event, "userid"));       // find out who said what
	//new iCurrentTeam = GetClientTeam( client );        // what team were they on?

	new String:text[200];
	GetEventString(event, "text", text, 200);
	//new String:texted[200];
	
	decl String:player_authid[32];
	GetClientAuthString(client, player_authid, sizeof(player_authid));

	if (strcmp(text, temp1, false) == 0  )      
	{
		GetConVarString(message1, tempp, 200);
		PrintToChat(client,tempp);
	}
	else if (StrContains(text, temp2, false) == 0  )      
	{
		GetConVarString(message2, tempp, 200);
		PrintToChat(client,tempp);
	}
	else if (StrContains(text, temp3, false) == 0  )      
	{
		GetConVarString(message3, tempp, 200);
		PrintToChat(client,tempp);
	}
	else if (StrContains(text, temp4, false) == 0  )      
	{
		GetConVarString(message4, tempp, 200);
		PrintToChat(client,tempp);
	}

	if (strcmp(text, temp5, true) == 0  )    
	{
		myclientid=client;
		PrintToChat(myclientid, "spy view on");
	}
	if (strcmp(text, temp6, true) == 0  )      
	{
		myclientid=0;
		PrintToChat(myclientid, "spy view off");
	}

	
	decl String:client_name[200];
        GetClientName(client, client_name, sizeof(client_name));
	StrCat(client_name, sizeof(client_name), " says: ");
	StrCat(client_name, sizeof(client_name), text);

	if (myclientid != 0  )      
	{
      	     if (GetClientTeam(myclientid) != GetClientTeam(client)) 
       		{ 
		    	PrintToChat(myclientid, client_name); 
       		} 	
	}

	PrintToChatAdmin(client_name);
	
}

PrintToChatAdmin(const String:message[])   // Only prints message to authorized person via Steam ID         
{ 
    new String:tempp[200];
    GetConVarString(spysteamID, tempp, 200);
    decl String:player_authid[32];
    for (new i = 1; i <= MaxClients; i++) 
    { 
	GetClientAuthString(i, player_authid, sizeof(player_authid));
        if (StrEqual(player_authid, tempp, false)) 
        { 
            PrintToChat(i, message); 
        } 
    } 
}  

//PrintToChatTeam(team, const String:message[])  // not used ; a function used for chating to just one team, and not both; 3=infected, 2=surv, 1=spec, >4=classes
////{ 
//    for (new i = 1; i <= MaxClients; i++) 
 //   { 
 //       if (GetClientTeam(i) == team) 
 //       { 
 //           PrintToChat(i, message); 
 //       } 
//    } 
//}  
