#include <sourcemod> 
#include <colors> 


bool trigger; 

ConVar autobunnyhopping; 
ConVar enableautobunnyhopping; 
ConVar abner;

public void OnPluginStart() 
{ 
    RegAdminCmd("sm_autobhop", Trigger_AutoBhop, ADMFLAG_ROOT); 
     
   autobunnyhopping = FindConVar("sv_autobunnyhopping"); 
   enableautobunnyhopping = FindConVar("sv_enablebunnyhopping"); 
   abner = FindConVar("abner_autobhop"); 
} 

public Action Trigger_AutoBhop(int client, int args) 
{ 
    if(!trigger) // Bhop On 
    { 
        SetConVarInt(autobunnyhopping, 1);
		SetConVarInt(enableautobunnyhopping, 1);
		SetConVarInt(abner, 1);
        
        ServerCommand("sm plugins load shavit-core"); 
        trigger=true; 
        CPrintToChat(client, "Bhop {green}On"); 
    } 
    else // Bhop Off 
    { 
         SetConVarInt(autobunnyhopping, 0);
		SetConVarInt(enableautobunnyhopping, 0);
		SetConVarInt(abner, 0);
        ServerCommand("sm plugins unload shavit-core"); 
        trigger=false; 
        CPrintToChat(client, "Bhop {darkred}Off");
    }
    return; 
     
}  