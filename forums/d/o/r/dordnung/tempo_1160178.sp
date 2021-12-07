#include <sourcemod>
#include <sdktools>

#define MAX_PLAYERS 256
#define PLUGIN_VERSION "1.1"

new Handle:dtimer[MAX_PLAYERS + 1], Handle:autoon, Handle:mphkmh, bool:playerw[MAX_PLAYERS + 1]


public Plugin:myinfo = 
{
	name = "Tempo Advert",
	author = "Popoklopsi",
	description = "Show your Speed",
	version = PLUGIN_VERSION,
	url = "http://pup-board.de"
}

public Action:Command_Speed(client,args)
{
    playerw[client] = !playerw[client]
    
    if(playerw[client]) 
	{
        PrintToChat(client, "\x03Tempo Advert \x08ON")
    } 
	else 
	{
        PrintToChat(client, "\x03Tempo Advert \x08OFF")
        PrintHintText(client, "Tempo Advert OFF")
    }
    
    return Plugin_Handled
}  

public OnPluginStart()
{
	CreateConVar("pup_speed_ver", PLUGIN_VERSION, "Speed Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	autoon = CreateConVar("pup_speed_autoon", "1","1 = When Joining turn on, 0 = Off",FCVAR_PLUGIN)
	mphkmh = CreateConVar("pup_speed_mphkmh", "1","1 = Kmh, 0 = Mph",FCVAR_PLUGIN)
	
	HookEvent("round_start", event_RoundStart)
	
	RegConsoleCmd("sm_speed", Command_Speed)
	
	CreateTimer(0.5, setter, _,TIMER_REPEAT)
	
	ServerCommand("exec pup_speed.cfg")
}

public event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	PrintToChatAll("\x03Type \x08!speed \x03to turn Speed Advert \x08ON/OFF")
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

public Action:setter(Handle:timer)
{
	for (new i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && IsPlayerAlive(i) && PlayerWant(i))
		{
			new Float:now[3], Handle:pack
			
			GetClientAbsOrigin(i,now)
			
			dtimer[i] = CreateDataTimer(0.4, Distance, pack)
			
			WritePackCell(pack, i)
			WritePackFloat(pack, now[0])
			WritePackFloat(pack, now[1])
			WritePackFloat(pack, now[2])
		}

    }
	return Plugin_Continue

}

public Action:Distance(Handle:timer, Handle:pack)
{
	
	new Float:now2[3], Float:now[3], Float:distance, Float:meters, Float:speed
	
	ResetPack(pack)
	
	new client = ReadPackCell(pack)
	
	now[0] = ReadPackFloat(pack)
	now[1] = ReadPackFloat(pack)
	now[2] = ReadPackFloat(pack)
	
	GetClientAbsOrigin(client, now2)
	distance = GetVectorDistance(now, now2, true)
	meters = distance * 0.000254
	
	if (GetConVarInt(mphkmh) == 1)
	{
		speed = (meters / 0.5) * 1.35
		PrintHintText(client, "%.2f KmH", speed)
	}
	else
	{
		speed = (meters / 0.5) * 1.35 * 0.63
		PrintHintText(client, "%.2f Mph", speed)
	}
	dtimer[client] = INVALID_HANDLE
}
	