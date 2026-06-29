#pragma semicolon 1 

#include <sourcemod> 
#include sdktools_functions.inc
#include sdktools_entinput.inc
#include admin.inc

public Plugin myinfo = {
	name        = "Build Anywhere",
	author      = "Mr. Random",
	description = "Allows buildings to be placed anywhere (cart, cliffs, ect) but not off the map",
	version     = "0.0.2",
	url         = ":("
};

ConVar g_enabled;
ConVar g_repetitions;

public OnPluginStart(){
	RegAdminCmd("sm_buildanywhere_refresh",killBrushesCmdResponse,ADMFLAG_GENERIC,"Removes nobuild brushes from the map");
	g_enabled = CreateConVar("sm_buildanywhere_enabled","1","Enables/Disables Plugin");
	g_repetitions = CreateConVar("sm_buildanywhere_repetitions","1000","Times the plugin attemps removes the brushes");
	ServerCommand("sm_cvar sm_buildanywhere_enabled 1");
	ServerCommand("sm_cvar sm_buildanywhere_repetitions 3000");
}

public OnMapStart() { 
	killBrushes();
}  
public Action:killBrushesCmdResponse(client, args){
	PrintToServer("command used");
	if(g_enabled.IntValue = 0)
	{
		ServerCommand("sm_cvar sm_buildanywhere_enabled 1");
	}
	killBrushes();
}


public void killBrushes(){
    PrintToServer("Starting!");
    if(g_enabled.IntValue = 0)
    {
    	PrintToServer("Enable the plugin!");
	return;
    }
    new i = -1; 
    new brush = 0; 
    for (new j = 0; j <= g_repetitions.IntValue; j++) 
    { 
        brush = FindEntityByClassname(i, "func_nobuild"); 
        if (brush != -1) 
        { 
                if(AcceptEntityInput(brush, "Kill") == true)
		{
			PrintToServer("Brush killed");
		}
		if(AcceptEntityInput(brush, "kill") == true)
		{
			PrintToServer("Brush killed");
		}
                i ++; 
        } 
        else
	{
		PrintToServer("Loop finished");
		break; 
	}
    } 
    PrintToServer("Loop finished");
}