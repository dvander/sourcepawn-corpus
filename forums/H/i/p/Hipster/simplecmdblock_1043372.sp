#include <sourcemod> 
  
public Plugin:myinfo = 
{ 
    name = "Simple Cmd Block", 
    author = "Hipster", 
    description = "This plugin blocks a command", 
    version = "1.0.2", 
    url = "http://forums.alliedmods.net/showthread.php?t=114430" 
}; 

public OnPluginStart() 
{ 
    RegConsoleCmd("physics_budget", Command_Block) 
} 
  
public Action:Command_Block(args, client) 
{ 
    return Plugin_Handled 
}