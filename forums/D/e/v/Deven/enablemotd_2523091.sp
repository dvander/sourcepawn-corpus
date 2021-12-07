#include <sourcemod>   

#pragma semicolon 1 

public OnMapStart() 
{ 
    ServerCommand("sm_cvar sv_disable_motd 0"); 
}  