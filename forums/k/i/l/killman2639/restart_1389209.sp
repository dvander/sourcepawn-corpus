#include <sourcemod>
#include <sdktools>

new RESTART_ROUND = 6;
new timer_restart;
new String:admin[32], String:adminid[32];

public Plugin:myinfo = 
{
name = "round restart",
author = "[GR|IPM] ThE_HeLl_DuDe {A|O}",
description = "Restarts the round without changing the map",
version = "1.0",
url = "www.ipmservers.co.cc"
};


public OnPluginStart()
 {
	CreateTimer(1.0, restart_timer, _, TIMER_REPEAT);
	RegAdminCmd("sm_restart", Command_Restart,	ADMFLAG_SLAY, "restart round");
	RegAdminCmd("sm_restart_map", Command_RestartMap,	ADMFLAG_SLAY, "restarts the map");
	RegAdminCmd("sm_restart_mapc", Command_RestartMapConsole,	ADMFLAG_SLAY, "restarts the map From Console");
 }
 
public OnMapStart()
{
AddFileToDownloadsTable("sound/ipmsounds/timer_5.wav");
AddFileToDownloadsTable("sound/ipmsounds/timer_4.wav");
AddFileToDownloadsTable("sound/ipmsounds/timer_3.wav");
AddFileToDownloadsTable("sound/ipmsounds/timer_2.wav");
AddFileToDownloadsTable("sound/ipmsounds/timer_1.wav");
 }


public Action:Command_Restart(client, args)
{
ReplyToCommand(client, "[SM] The round will restart in 5 seconds!!!.");
GetClientName(client, admin, 32);
GetClientAuthString(client, adminid, 32);
LogToFile("cfg/restart_info.cfg", "Admin %s (%s) restarted the round.", admin,adminid);
PrintToChatAll("\x04[SM] %s restarted the round", admin);
PrintToServer("[RESTART] Admin %s restarted the round!", admin);
ServerCommand("mp_restartgame 5");
timer_restart = RESTART_ROUND;
return Plugin_Handled;
}

public Action:restart_timer(Handle:timer)
{
	
	timer_restart -=1;
    new maxclients = GetMaxClients();

	if (timer_restart > 0)
	{
	
	for(new i=1; i <= maxclients; i++) 
{
if(IsClientConnected(i) && IsClientInGame(i))
{
ClientCommand(i, "play ipmsounds/timer_%d.wav", timer_restart);
}
}

        if(timer_restart == 5)
		{
			PrintToChatAll("\x04[SM] The round will restart in 5 seconds.");
	    }
		if(timer_restart == 4)
		{
			PrintToChatAll("\x04[SM] The round will restart in 4 seconds.");
		}
		if(timer_restart == 3)
		{
			PrintToChatAll("\x04[SM] The round will restart in 3 seconds.");
		}
		if(timer_restart == 2)
		{
			PrintToChatAll("\x04[SM] The round will restart in 2 seconds.");
		}
		if(timer_restart == 1)
		{
			PrintToChatAll("\x04[SM] The round will restart in 1 second.");
		}
	    if(timer_restart == 0)
	    {
	     return Plugin_Stop;
	    }
    }	
    return Plugin_Handled;
}	
public Action:Command_RestartMap(client, args)
{
if(client && IsClientInGame(client))
{
  GetClientName(client, admin, 32);
  GetClientAuthString(client, adminid, 32);
  PrintToChatAll("\x04[SM] Admin %s restarted the map.", admin);
  LogToFile("cfg/restart_info.cfg", "Admin %s (%s) restarted the map.", admin,adminid);
  ServerCommand("wait 700;changelevel gm_flatgrass_ipm_v4");
}else{
PrintToConsole(client,"[RESTART] You must be in-game to run this command!")
return Plugin_Continue;
}
  return Plugin_Handled;
}
public Action:Command_RestartMapConsole(client, args)
{
if(client && IsClientInGame(client))
{
PrintToConsole(client,"[RESTART] This command cant be used in the client console!");
return Plugin_Continue;
}else{
  PrintToChatAll("\x04[SM] Server Console restarted the map.");
  ServerCommand("wait 700;changelevel gm_flatgrass_ipm_v4");
 }
return Plugin_Handled;
}

