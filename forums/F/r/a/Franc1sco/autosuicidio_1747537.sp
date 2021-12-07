
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "v1.1 by Franc1sco Steam: franug (Made in Spain)"

#pragma semicolon 1

public Plugin:myinfo =
{
	name = "SM Auto Suicidio",
	author = "Franc1sco Steam: franug",
	description = "para suicidarse",
	version = PLUGIN_VERSION,
	url = "www.servers-cfg.foroactivo.com"
};

public OnPluginStart()
{
	CreateConVar("sm_AutoSuicidio", PLUGIN_VERSION, "version del plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

        RegConsoleCmd("sm_kill", Matarse);
        RegConsoleCmd("kill", Matarse2);
}



public Action:Matarse(client,args)
{
                 if (GetClientTeam(client) > 1)
                 {
                   if (IsPlayerAlive(client))
                   {
                      PrintToChatAll("\x04[SM_AutoSuicidio] \x05El jugador\x03 %N \x05se ha suicidado!", client);
                      ForcePlayerSuicide(client);
                   }
                   else
                   {
                      PrintToChat(client, "\x04[SM_AutoSuicidio] \x05Tienes que estar vivo para poder suicidarte!");
                   }
                  }
                  else
                  {
                     PrintToChat(client, "\x04[SM_AutoSuicidio] \x05Los espectadores no se pueden suicidar!");
                  }
}

public Action:Matarse2(client,args)
{
                 if (GetClientTeam(client) > 1)
                 {
                   if (IsPlayerAlive(client))
                   {
                      PrintToChatAll("\x04[SM_AutoSuicidio] \x05El jugador\x03 %N \x05se ha suicidado!", client);
                   }
                   else
                   {
                      PrintToChat(client, "\x04[SM_AutoSuicidio] \x05Tienes que estar vivo para poder suicidarte!");
                   }
                  }
                  else
                  {
                     PrintToChat(client, "\x04[SM_AutoSuicidio] \x05Los espectadores no se pueden suicidar!");
                  }
}