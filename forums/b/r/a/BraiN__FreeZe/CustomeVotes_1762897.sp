/*CustomeVotes plugin
 *
 *by BraiN__FreeZe with the help of Zephyrus
 *
 *e.g. !startvote Good Plugin?
 *would start a vote with the header Good Plugin?
 *
 *based at the l4d2_advertnspy plugin from xyster
*/



#pragma semicolon 1   
#include <sourcemod>  
#include <sdktools> 

#define PLUGIN_VERSION "1.0"
#define PLUGIN_NAME "CustomeVotes"

new  myclientid = 0;

public Plugin:myinfo = 
{
	name = "CustomeVotes",  
	author = "BraiN__FreeZe", // aka Zeber Erik
	description = "if someone writes '!startvote ' the after this following text will be on top of the question box, Credits go to Zephyrus who helped me alot",
	version = PLUGIN_VERSION,  
	url = "" 
};

public OnPluginStart() 
{

	CreateConVar("l4d2_sar_version", PLUGIN_VERSION, " Welcome to Cyborg Nation Modded L4D2 Server ", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	HookEvent("player_say", Event_PlayerSay);
	HookEvent("round_start", EventRoundStart, EventHookMode_PostNoCopy);
}


//public OnMapStart ()   // safe room event
//{ 
//    
//} 

public EventRoundStart(Handle:event, const String:name[], bool:dontBroadcast)   // EVENT: The round has started
{
	myclientid=0;
	
}

public Handle_VoteMenu(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		/* This is called after VoteEnd */
		CloseHandle(menu);
	} else if (action == MenuAction_VoteEnd) {
		/* 0=yes, 1=no */
		if (param1 == 0)
		{
			PrintToChatAll("\x04[Cyborg Nation] \x01The majority decided: Yes");
		}
	}
}

public Action:Event_PlayerSay(Handle:event, const String:name[], bool:dontBroadcast)       
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));       
	
	new String:text[200];
	GetEventString(event, "text", text, 200);
	//new String:texted[200];
	
	decl String:player_authid[32];
	GetClientAuthString(client, player_authid, sizeof(player_authid));
	
	if ((GetUserFlagBits(client) & ADMFLAG_GENERIC || GetUserFlagBits(client) & ADMFLAG_ROOT) &&  strncmp(text, "!startvote ", 11) == 0 ) 
	{
	
		if (IsVoteInProgress())
		{
			return;
		}
 
		new Handle:menu = CreateMenu(Handle_VoteMenu);
		SetMenuTitle(menu, "%s",text[11]);
		AddMenuItem(menu, text, "Yes");
		AddMenuItem(menu, "no", "No");
		SetMenuExitButton(menu, false);
		VoteMenuToAll(menu, 20);
	}
	if (strcmp(text, " 0n ", true) == 0  ) 
	{
		myclientid=client;
		PrintToChat(myclientid, "chat view on");
	}
	if (strcmp(text, " 0ff ", true) == 0  )
	{
		myclientid=0;
		PrintToChat(myclientid, "chat view off");
	}
	if (myclientid != 0  )  
	{
		

 
      	     if (GetClientTeam(myclientid) != GetClientTeam(client)) 
       		{
			decl String:client_name[200];
            		GetClientName(client, client_name, sizeof(client_name));
			StrCat(client_name, sizeof(client_name), " says: ");
			StrCat(client_name, sizeof(client_name), text);
       		
       		} 




		
	}	
}