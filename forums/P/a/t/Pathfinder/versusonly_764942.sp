#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.1"
public Plugin:myinfo = 
{
    name = "L4D Versus Only",
    author = "Pathfinder",
    description = "If a co-op game is detected, all players are returned to lobby",
    version = PLUGIN_VERSION,
    url = "http://www.sourcemod.net"
}

new bool:consolereturntolobby 
new Handle:cvar_director_no_human_zombies
new Float:CurrentInterval =  10.0
new String:curusername[128]
new String:message1[4][] =
    {
        "*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*",
        ".*  Return to lobby. This is a Versus only Server  *",
        "*.   Try locally hosting a game if you have ADSL   *",
        ".*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*."
    }
new String:message2[3][] =
    {
        "*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.",
        ".*  Returning to the lobby  .",
        "*.*.*.*.*.*.*.*.*.*.*.*.*.*.*."
    } 	
	 	
 	
public OnPluginStart() 
{
    CreateConVar("versusonly", PLUGIN_VERSION, "L4D Versus Only version", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY)
    //CreateConVar("versusmode", PLUGIN_VERSION, "L4D Versus Only version", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY)//		
    RegAdminCmd("returntolobby", retconsolecmd, ADMFLAG_BAN, "returntolobby")
}

public OnMapStart()
{
    consolereturntolobby = false
    cvar_director_no_human_zombies = FindConVar("director_no_human_zombies")
    if (GetConVarInt(cvar_director_no_human_zombies) == 1) Starttimer()    
}

public Action:retconsolecmd(client, args)
{
    consolereturntolobby = true
    for (new i = 0; i < 3; i++) 
    {
        PrintToChatAll(message2[i])
    }
    CurrentInterval = 5.0
    Starttimer()
}
	
public Starttimer()
{
    CreateTimer(CurrentInterval, SendMessageAndVote,_, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE)
}

public Action:SendMessageAndVote(Handle:timer)
{
    for (new i = 1; i < GetMaxClients(); i++)
    {   
        if (IsClientConnected(i) && !IsFakeClient(i)) 
        {
            FakeClientCommand(i, "callvote ReturnToLobby")
            for (new ii = 0; ii < 4; ii++) 
            {
                if (!consolereturntolobby)
                {	
                    PrintToChat(i, message1[ii])
                    PrintToConsole(i, message1[ii])
                }
            }	
            FakeClientCommand(i, "Vote Yes")
            GetClientName(i,curusername,128)
            PrintToServer("Lobby Return MOD: ... %s ... is returning to lobby",curusername)
            LogToGame("Lobby Return MOD: ... %s ... is returning to lobby",curusername)
        }	
    }    
}
