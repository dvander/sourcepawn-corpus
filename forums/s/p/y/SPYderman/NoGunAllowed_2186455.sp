#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

// Based on the code for the suicide plugin by killroy
public Plugin:myinfo =
{
    name = "No !gun/weapon Allowed",
    author = "SPYderman",
    description = "Kills players who try to use the !gun & !weapon command.",
    version = "1.0",
    url = "http://www.sourcemod.net/"
};
 
public OnPluginStart()
{
    RegConsoleCmd("sm_gun", Command_kill);
	RegConsoleCmd("sm_weapon", Command_kill);
}

public Action:Command_kill(client, args)
{   
    if(!client)
    {
        ReplyToCommand(client, "[Error] You cannot run this command from server console");
        return Plugin_Handled;
    }
    if(!IsPlayerAlive(client))
    {
        ReplyToCommand(client, "\x04[SM] \x05You must be alive to use that command!");
        return Plugin_Handled;
    }
    
    ForcePlayerSuicide(client);           
    ReplyToCommand(client, "\x04[SM] \x05This server doesn't use that plugin. Stop trying.");                 
    return Plugin_Handled;        
}