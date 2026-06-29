#pragma semicolon 1 
#pragma newdecls required 

#include <sourcemod> 

 public Plugin myinfo =
{
    name = "Prevent !knife !ws !gloves",
    author = "Fig Newtons (Aaronpierce)",
    description = "Any player that executes commands: !knife !ws etc are greeted with a message saying those plugins aren't allowed.",
    version = "1.1",
    url = ""
};

public void OnPluginStart() 
{ 
    RegConsoleCmd("sm_knife", Command_Print);
    RegConsoleCmd("sm_ws", Command_Print);  
    RegConsoleCmd("sm_gloves", Command_Print);  
} 

public Action Command_Print(int client, int args) 
{
    if (IsClientInGame(client))
    {
        PrintToChat(client, "We do not have this plugin because it's against Valve's TOS. We are children of Jesus."); 
    }
    return Plugin_Handled; 
}  