#include <sourcemod> 
#include <sdktools> 
#include <sdkhooks> 

#define PLUGIN_AUTHOR     "Arkarr, thedudeguy1" 
#define PLUGIN_VERSION     "1.3" 

bool Marked[MAXPLAYERS + 1]; 

public Plugin myinfo =  
{ 
    name = "[ANY] Knife Attack Delay",  
    author = PLUGIN_AUTHOR,  
    description = "Set a delay between each attack on the same player.",  
    version = PLUGIN_VERSION,  
    url = "https://forums.alliedmods.net/showpost.php?p=2499248&postcount=6" 
}; 

public void OnPluginStart() 
{ 
    for (new i = 1; i <= MaxClients; i++) 
    { 
        if (IsClientInGame(i)) 
            SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage); 
    } 
} 

public void OnClientPutInServer(int client) 
{ 
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage); 
} 

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype) 
{ 
    if (victim < 1 || victim > MaxClients || attacker < 1 || attacker > MaxClients) 
        return Plugin_Continue; 
		
    char weapon[64]; 
    GetClientWeapon(attacker, weapon, sizeof(weapon)); 
     
    if (StrEqual(weapon, "weapon_knife", false)) 
    { 
        if (!Marked[victim]) 
        { 
            ImmunePlayer(victim);     
        }             
        else 
        { 
            return Plugin_Handled; 
        } 
    } 
     
    return Plugin_Continue; 
} 

public void ImmunePlayer(int client) 
{ 
    Marked[client] = true; 
    SetEntityRenderMode(client, RENDER_TRANSCOLOR); 
    SetEntityRenderColor(client, 100, 255, 100, 200); 
     
    CreateTimer(3.0, TMR_Unmark, client); 
} 

public Action TMR_Unmark(Handle tmr, any client) 
{ 
    Marked[client] = false; 
    SetEntityRenderMode(client, RENDER_TRANSCOLOR); 
    SetEntityRenderColor(client, 255, 255, 255, 255); 
} 