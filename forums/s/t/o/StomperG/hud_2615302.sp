#include <sourcemod>  
#include <cstrike>  

public Plugin myinfo =  
{  
    name = "HudMessage",  
    author = "StomperG",  
    description = "Put a simple message on top of screen",  
    version = "1.0",  
    url = "http://hiddengaming.gq"  
};  

public OnPluginStart()  
{  
    CreateTimer(5.0, HUD, _, TIMER_REPEAT);  
}  

public Action HUD(Handle timer)  
{  
    for (new i = 1; i <= MaxClients; i++)  
    {  
        if (IsClientInGame(i))  
        {  
            SetHudTextParams(-1.0, 0.1, 5.0, 255, 255, 255, 255, 0, 0.1, 0.1, 0.1);  
            ShowHudText(i, 5, "★ Put name here ★");  
        }  
    }  
}