#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.12"
public Plugin:myinfo = 
{
    name = "L4D Versus Only",
    author = "Pathfinder",
    description = "If a co-op game is detected, all players are returned to lobby",
    version = PLUGIN_VERSION,
    url = "http://www.sourcemod.net"
}

new bool:consolereturntolobby = false
new Handle:g_director_no_human_zombies = INVALID_HANDLE
new Handle:g_hEnforced = INVALID_HANDLE
new Handle:g_messagetimer = INVALID_HANDLE
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
    g_hEnforced = CreateConVar("sm_versus_enforced",  "1", "Enforce Versus Mode [0]Off [1]On")
    RegAdminCmd("returntolobby", Command_Retconsole, ADMFLAG_BAN, "returntolobby")
}

public OnMapStart()
{
    consolereturntolobby = false
    g_director_no_human_zombies = FindConVar("director_no_human_zombies")
    
    if ( (GetConVarInt(g_director_no_human_zombies) == 1) && (GetConVarInt(g_hEnforced) == 1) )
    {
        Starttimer()    
    }
}

public Action:Command_Retconsole(client, args)
{
    consolereturntolobby = true
    for (new i = 0; i < 3; i++) 
    {
        PrintToChatAll(message2[i])
    }
    CurrentInterval = 1.0
    Starttimer()
    return Plugin_Handled
}
	
public Starttimer()
{
    g_messagetimer = CreateTimer(CurrentInterval, SendMessageAndVote,_, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE)
}

public Action:SendMessageAndVote(Handle:timer)
{
    if ( (GetConVarInt(g_hEnforced) != 1) && (!consolereturntolobby) )
    {
        return
    }
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
            PrintToServer("L4D Versus Only MOD: ... %s ... is returning to lobby",curusername)
            LogToGame("L4D Versus Only MOD: ... %s ... is returning to lobby",curusername)
            KillTimer(g_messagetimer)
            consolereturntolobby = false
        }	
    }    
}
