#include <sourcemod>   

public OnMapStart() 
{ 
    ServerCommand("sm_cvar sv_disable_motd 0"); 
}  