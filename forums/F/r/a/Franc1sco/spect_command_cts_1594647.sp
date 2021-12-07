#pragma semicolon 1

#include <sourcemod>
#include <cstrike>

public Plugin:myinfo =
{
    name = "SM Simple spectator command",
    author = "Franc1sco steam: franug",
    description = "Go to spectator for CTs",
    version = "1.0",
    url = "http://servers-cfg.foroactivo.com/"
};


public OnPluginStart()
{

        RegConsoleCmd("sm_spectator", GoToSpectator);
}



public Action:GoToSpectator(client,args)
{
         if (GetClientTeam(client) == 3)
         {

             CS_SwitchTeam(client, 1);
         }
         else
         {
             PrintToChat(client, "Sorry, only CTs can use this command.");
         }
}