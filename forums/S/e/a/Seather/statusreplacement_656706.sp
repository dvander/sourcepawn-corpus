
//http://forums.alliedmods.net/showthread.php?t=63202
//http://bugs.alliedmods.net/index.php?do=details&task_id=1196&opened=484&status[]=

/*
todo: command to remove target user form the list
todo: statistics for each person? short term. tk, name changes, kills, deaths
*/
#pragma semicolon 1
#include <sourcemod>

public Plugin:myinfo =
{
	name = "StatusReplacement",
	author = "seather",
	description = "Replaces the bulit in 'status' command with a near duplicate that can be manipulated",
	version = "0.1.0",
	url = "http://www.sourcemod.net/"
};

new Handle:g_Cvar_HostName = INVALID_HANDLE;
new Handle:sm_hidesteamids = INVALID_HANDLE;

public OnPluginStart()
{
	//This command gets disabled.
	RegConsoleCmd("status", Command_Status);
	
	//Alternatives provided.
	RegConsoleCmd("status2", Command_Status2);
	RegAdminCmd("status3", Command_Status3, ADMFLAG_RCON, "status3 - status with IP addresses");
	
	g_Cvar_HostName = FindConVar("hostname");
	sm_hidesteamids = CreateConVar("sm_hidesteamids", "1", "Removes STEAMIDs from 'status' command", 0, true, 0.0, true, 1.0);

}

public Action:Command_Status(client, args)
{
	new maxplayers = GetMaxClients();
	for (new i=0; i<=maxplayers; i++)
	{
		if (i != 0 && !IsClientConnected(i))
		{
			continue;
		}
		PrintToConsole(i,"'status' is disabled, use 'status2', 'status3' for rcon admins");
	}
	//Block standard status command output
	return Plugin_Handled;
}

public Action:Command_Status2(client, args)
{
	if(GetConVarInt(sm_hidesteamids) == 1)
	{
		Status_Blob(client,false,false);
	} 
	else
	{
		Status_Blob(client);
	}
	return Plugin_Handled;
}

public Action:Command_Status3(client, args)
{
	Status_Blob(client,true);
	return Plugin_Handled;
}

Status_Blob(client,bool:show_ips = false,bool:show_steamids = true)
{
	//Print Hostname
	decl String:hostname[64];
	if (g_Cvar_HostName != INVALID_HANDLE) {
		GetConVarString(g_Cvar_HostName, hostname, sizeof(hostname));
	} else {
		Format(hostname, sizeof(hostname), "?");
	}
	PrintToConsole(client,"hostname:  %s",hostname);

	//Print Version
	decl String:version[64];
	Format(hostname, sizeof(version), "?");
	PrintToConsole(client,"version : %s",version);
	
	//Print IP/Port
	PrintToConsole(client,"udp/ip  :  %s",version);

	//Print name of current map
	decl String:map[64];
	GetCurrentMap(map, sizeof(map));
	PrintToConsole(client,"map     :  %s",map);
	
	//Print number and max of player
	PrintToConsole(client,"players :  %s (%i max)",version,GetMaxClients());

	//List players header
	PrintToConsole(client,"# userid name uniqueid connected ping loss state adr");
	
	//List players
	new maxplayers = GetMaxClients();
	for (new i=1; i<=maxplayers; i++)
	{
		if (!IsClientConnected(i))
		{
			continue;
		}
		
		//userid
		new userid = GetClientUserId(i);
		
		//name
		decl String:name[32];
		GetClientName(i, name, sizeof(name));
		
		//steamid
		decl String:uniqueid[32];
		if(show_steamids) {
			if(!GetClientAuthString(i, uniqueid, sizeof(uniqueid))){
				Format(uniqueid, sizeof(uniqueid), "?");
			}
		} else {
			Format(uniqueid, sizeof(uniqueid), "-");
		}
		
		//time in game
		decl String:time[12];
		if (!IsFakeClient(i))
		{
			new time_sec = RoundToNearest(GetClientTime(i));//seconds
			new mins = time_sec / 60;
			new secs = time_sec % 60;
			Format(time, sizeof(time), "%02d:%02d", mins, secs);
		} else {
			Format(time, sizeof(time), "-");
		}
		
		//ping
		new ping = 0;
		if (!IsFakeClient(i))
		{
			new Float:float_ping = GetClientAvgLatency(i, NetFlow_Outgoing);//seconds
			ping = RoundToNearest(float_ping * 1000.0);
		}
		
		//loss
		new loss = 0;
		if (!IsFakeClient(i))
		{
			new Float:float_loss = GetClientAvgLoss(i, NetFlow_Outgoing);//percent, 0 to 1
			loss = RoundToNearest(float_loss * 100.0);
		}
		
		//state
		decl String:cstate[16];
		Format(cstate, sizeof(cstate), "?");
		
		//address
		decl String:address[64];
		if(show_ips && !IsFakeClient(i)) {
			if(!GetClientIP(i, address, sizeof(address), false)){
				Format(address, sizeof(address), "?");
			}
		} else {
			Format(address, sizeof(address), "-");
		}
		
		//Print the full line
		PrintToConsole(client,"# %d \"%s\" %s %s %d %d %s %s",userid,name,uniqueid,time,ping,loss,cstate,address);
		
	}
	
}