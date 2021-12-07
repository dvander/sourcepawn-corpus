/**
 * ====================
 *        Sprint
 *   Author: Berni
 * ==================== 
 */

#pragma semicolon 1
#include <sourcemod>

#define VERSION "1.3"




public Plugin:myinfo =
{
    name = "sv_infinite_aux_power - cheatflag removal",
    author = "Berni",
    description = "sv_infinite_aux_power - cheatflag removal",
    version = VERSION,
    url = ""
};

public OnPluginStart()
{   
	
    new Handle:cvarInfiniteSprint = FindConVar("sv_infinite_aux_power");
    if (cvarInfiniteSprint != INVALID_HANDLE)
    {
        new flags = GetConVarFlags(cvarInfiniteSprint);
        
        flags &= ~FCVAR_CHEAT;
        SetConVarFlags(cvarInfiniteSprint, flags);
    }
	
}

