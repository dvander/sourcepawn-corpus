#include <sourcemod> 

public void OnPluginStart() 
{ 
    RegConsoleCmd("sm_steamid", GetSteam); 
} 

public Action GetSteam(int client, int args) 
{ 
    if(args != 1) 
    { 
        ReplyToCommand(client, "Bad usage, !steamid <name>"); 
        return Plugin_Handled; 
    } 
    char arg1[64]; 
    GetCmdArg(1, arg1, sizeof(arg1)); 
    int target = FindTarget(client, arg1); 
    if(target == -1) 
    { 
        ReplyToCommand(client, "Client wasn't founded"); 
        return Plugin_Handled; 
    } 
    char SteamID[64]; 
    GetClientAuthId(target, AuthId_Steam2, SteamID, sizeof(SteamID)); 
    PrintToChat(client, "Player: %N - %s", target, SteamID); 
    return Plugin_Handled; 
}  