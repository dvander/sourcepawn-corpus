#include <sourcemod>

public Action OnClientSayCommand(int client, const char[] command, const char[] argc) 
{ 
    if (IsChatTrigger()) 
        return Plugin_Handled; 
         
    return Plugin_Continue; 
}