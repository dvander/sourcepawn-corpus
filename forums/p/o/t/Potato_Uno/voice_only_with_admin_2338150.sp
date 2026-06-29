#pragma semicolon 1 
#include <sourcemod> 

public void OnClientDisconnect(int client) { 
    CheckForAdmins(); 
} 

public void OnClientPostAdminCheck(int client) { 
    if (GetUserAdmin(client) != INVALID_ADMIN_ID) 
        SetConVarInt(FindConVar("sv_voiceenable"), 1); 
} 

stock void CheckForAdmins() { 
    for (int i = 1; i <= MaxClients; i++) { 
        if (!IsClientInGame(i)) continue; 
        if (GetUserAdmin(i) != INVALID_ADMIN_ID) { 
            SetConVarInt(FindConVar("sv_voiceenable"), 1); 
            return; 
        } 
    } 
    SetConVarInt(FindConVar("sv_voiceenable"), 0); 
}  