#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

// thank you to Azelphur for helping me waffle up my code
public Plugin:myinfo =
{
    name = "Killme",
    author = "killjoy",
    description = "A simple way for players to die...",
    version = "2.0.1",
    url = "http://www.epic-nation.com"
};
 
public OnPluginStart()
{
    RegConsoleCmd("sm_kill", Command_killme); 
}

public Action:Command_killme(client, args)
{   
    if(!client)
    {
        ReplyToCommand(client, "[Error] You cannot run this command from server console");
        return Plugin_Handled;
    }
    if(!IsPlayerAlive(client))
    {
        ReplyToCommand(client, "\x04[Server] \x05Last time i checked, your already dead.");
        return Plugin_Handled;
    }
    
    ForcePlayerSuicide(client);           
    ReplyToCommand(client, "\x04[Server] \x05You killed yourself...");                 
    return Plugin_Handled;        
}