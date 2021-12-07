#include <sourcemod> 

#pragma semicolon 1 
#pragma newdecls required 

#define PLUGIN_VERSION "1.0" 

ConVar Cvar_TeamSwitches; 

public Plugin myinfo = 
{ 
    name = "[L4D2] Play as Team 4", 
    author = "Xanaguy/MasterMe", 
    description = "Play on the hidden Team 4!", 
    version = PLUGIN_VERSION, 
    url = "https://forums.alliedmods.net/showthread.php?t=311185" 
}; 

public void OnPluginStart() 
{ 
    CreateConVar("team4version", PLUGIN_VERSION, "\"Play as Team 4\" plugin version", FCVAR_NOTIFY|FCVAR_DONTRECORD); 
    Cvar_TeamSwitches    =    FindConVar("vs_max_team_switches"); 
     
    RegAdminCmd("sm_team4", ClientToTeam4, ADMFLAG_ROOT, "Switch to Team 4."); 
    RegAdminCmd("sm_team3", ClientToTeam3, ADMFLAG_ROOT, "Switch to Team 3."); 
    RegAdminCmd("sm_team2", ClientToTeam2, ADMFLAG_ROOT, "Switch to Team 2.");

	RegConsoleCmd("sm_codexana", ClientToTeam4);
	RegConsoleCmd("sm_spec", ClientToSpec);
	RegConsoleCmd("sm_codelyoko", ClientToTeam2);
} 

public Action ClientToTeam4(int client, int args) 
{ 
    ChangeClientTeam(client, 4); 
    return Plugin_Handled; 
} 

public Action ClientToSpec(int client, int args) 
{ 
	if (GetClientTeam(client) == 4)
	{
		ChangeClientTeam(client, 1);
	}
	return Plugin_Handled; 
} 

public Action ClientToTeam2(int client, int args) 
{ 
    SwitchTeam(client, 1); 
    return Plugin_Handled; 
} 


public Action ClientToTeam3(int client, int args) 
{ 
    SwitchTeam(client, 2); 
    return Plugin_Handled; 
} 

stock void SwitchTeam(int client, int team) 
{     
    Cvar_TeamSwitches.SetInt(9999); 
    switch(team) 
    { 
        case 1: FakeClientCommand(client, "jointeam 2"); 
        case 2: FakeClientCommand(client, "jointeam 3"); 
    } 
    Cvar_TeamSwitches.SetInt(1); 
}  
