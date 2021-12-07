#include <sourcemod> 

new Handle:FF;

public Plugin:myinfo =  
{ 
    name = "Friendly fire shortcut", 
    author = "Kotori17", 
    description = "shortcut for FF", 
    version = "1.0", 
    url = "http://steamcommunity.com/id/kotori17/" 
} 

public OnPluginStart() 
{ 
    RegAdminCmd("sm_ffopen", Command_openff, ADMFLAG_GENERIC);
    RegAdminCmd("sm_ffclose", Command_closeff, ADMFLAG_GENERIC);
    FF = FindConVar("mp_friendlyfire");
} 

public Action:Command_openff(client, args)
{
   SetConVarInt(FF, 1);
   return Plugin_Handled;
}

public Action:Command_closeff(client, args)
{
	SetConVarInt(FF, 0);
	return Plugin_Handled;
}