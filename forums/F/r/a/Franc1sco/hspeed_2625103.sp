#pragma semicolon 1  

#include <sourcemod> 

ConVar cv_showtype;

public Plugin myinfo =  
{  
    name = "Show Horizontal Speed",  
    author = "ChauffeR",  
    description = "Show the horizontal speed of the player with a configurable HUD",  
    version = "1.1 (edited by Franc1sco franug)",  
    url = "http://hop.tf"  
}  

public void OnPluginStart()
{
	cv_showtype = CreateConVar("sm_hspeed_showtype", "1", "1 = hint text. 0 = center text.");
}

public void OnMapStart() 
{ 
    CreateTimer(0.2, Timer_ShowSpeed, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE); 
} 

public Action Timer_ShowSpeed(Handle timer, any data) 
{ 
	float velocity[3]; 
	for (int i = 1; i <= MaxClients; i++) // it's <= MaxClients, not < 
    { 
        if (IsClientInGame(i)) 
        { 
			GetEntPropVector(i, Prop_Data, "m_vecVelocity", velocity); 
             
			if(cv_showtype.BoolValue)
				PrintHintText(i, "%i", RoundToZero(SquareRoot(velocity[0] * velocity[0] + velocity[1] * velocity[1])));
			else
				PrintCenterText(i, "%i", RoundToZero(SquareRoot(velocity[0] * velocity[0] + velocity[1] * velocity[1])));
        } 
	} 
}  