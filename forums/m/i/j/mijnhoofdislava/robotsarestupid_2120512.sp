#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

// Based on the code for the suicide plugin by killroy
public Plugin:myinfo =
{
    name = "Robots are Stupid",
    author = "mijnhoofdislava",
    description = "They should all go die in a fire.",
    version = "1.0",
    url = "http://tiny.cc/PIJN"
};
 
public OnPluginStart()
{
    RegConsoleCmd("sm_robot", Command_killme);
	RegConsoleCmd("sm_tobor", Command_killme);
	RegConsoleCmd("sm_betherobot", Command_killme);
	RegConsoleCmd("sm_berobot", Command_killme);
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
        ReplyToCommand(client, "\x04[SM] \x05You must be alive to be the robot!");
        return Plugin_Handled;
    }
    
    ForcePlayerSuicide(client);           
    ReplyToCommand(client, "\x04[SM] \x05Robots are stupid");                 
    return Plugin_Handled;        
}