#include <sourcemod>
#include <sdktools>

#define MAX_PLAYERS 256
#define PLUGIN_VERSION "1.1"

new Handle:autoon, bool:playerw[MAX_PLAYERS + 1]

public Plugin:myinfo = 
{
	name = "Time Advert",
	author = "Popoklopsi",
	description = "Show the Time",
	version = PLUGIN_VERSION,
	url = "http://pup-board.de"
};

public OnPluginStart()
{
	CreateConVar("pup_time_ver", PLUGIN_VERSION, "Time Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	autoon = CreateConVar("pup_time_autoon", "1","1 = When Joining turn on, 0 = Off",FCVAR_PLUGIN)
	
	RegConsoleCmd("sm_time", Command_time)
	
	ServerCommand("exec pup_time.cfg")
	
	HookEvent("round_start", event_RoundStart)
	
	CreateTimer(1.0, shower, _,TIMER_REPEAT)
}

public event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	PrintToChatAll("\x03Type \x08!time \x03to turn Time Advert \x08ON/OFF")
}

public Action:Command_time(client,args)
{
    playerw[client] = !playerw[client]
    
    if(playerw[client]) 
	{
        PrintToChat(client, "\x03Time Advert \x08ON")
    } 
	else 
	{
        PrintToChat(client, "\x03Time Advert \x08OFF")
        PrintHintText(client, "Time Advert OFF")
    }
    
    return Plugin_Handled
}  

public PlayerWant(client)
{
	if (!playerw[client])
	{
		return false
	}
	else
	
	{
		return true
	}
}

public OnClientAuthorized(client, const String:auth[])
{
	if(!IsFakeClient(client) && client != 0)
	{
		if (!GetConVarInt(autoon))
		{
			playerw[client] = false
		}
		else
		{
			playerw[client] = true
		}
	}
}

public Action:shower(Handle:timer)
{
	for (new i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && PlayerWant(i))
		{
			new time = GetTime()
			new String:nowtime[255]
			FormatTime(nowtime, sizeof(nowtime), "%H:%M:%S", time)
			PrintHintText(i, "Time: %s", nowtime)
		}

    }
	return Plugin_Continue
}

	