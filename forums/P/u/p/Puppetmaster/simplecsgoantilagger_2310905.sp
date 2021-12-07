#include <dbi>
#include <sourcemod> 
#include <cstrike>
#include <clientprefs>
#include <sdktools>
//#include <smlib>

#define PLUGIN_VERSION "0.0.0"

float lag[320];

//convars
ConVar sm_simplecsgoantilagger_kicktype

//begin
public Plugin:myinfo =
{
	name = "SimpleCSGOAntiLagger",
	author = "Puppetmaster",
	description = "SimpleCSGOAntiLagger Addon",
	version = PLUGIN_VERSION,
	url = "http://gamingzone.ddns.net/"
};

//called at start of plugin, sets everything up.
public OnPluginStart()
{
	sm_simplecsgoantilagger_kicktype = CreateConVar("sm_simplecsgoantilagger_kicktype", "1", "Sets whether to kick to spec (1) or to kick out of match (2)")
	HookEvent("round_poststart", Event_RoundStart) //new round
}


public Action:Event_RoundStart (Handle:event, const String:name[], bool:dontBroadcast){
	updateLag();
	return Plugin_Continue;
}

public Action:Timer_AntiLag(Handle:timer)
{
	checkPositions();
	return Plugin_Continue;
}

public Action:Timer_AntiLagWarning(Handle:timer)
{
	checkPositionsWarning();
	return Plugin_Continue;
}

public updateLag(){
	PrintToServer("New Round, Getting players ping times for checking");
	new maxclients = GetMaxClients()
	for(new i=1; i <= maxclients; i++)
	{
		if(IsClientInGame(i)) 
		{
			lag[i] = GetClientAvgLatency(i, NetFlow_Outgoing)
		}
	}
	CreateTimer(31.0, Timer_AntiLag);
	CreateTimer(10.0, Timer_AntiLagWarning);
}

public checkPositions(){
	new maxclients = GetMaxClients()
	int kickType;
	decl String:name1[64];
	for(new i=1; i <= maxclients; i++)
	{
		if(IsClientInGame(i)) 
		{
			if(lag[i] > 0.2) //heavily nested so that additional logic checks will not be done unless atleast the first bit is done
			{
				if(GetClientTeam(i) > 1 && IsPlayerAlive(i) && GetClientAvgLatency(i, NetFlow_Outgoing) > 0.2) 
				{
					kickType = GetConvar() //load the convar kick type
					if(kickType == 1)
					{
						ChangeClientTeam(i, 1); //move to spec
						GetClientName(i, name1, sizeof(name1));
						PrintToChatAll("Player %s moved to spectator for lagging.", name1);
						PrintToServer("Player %s moved to spectator for lagging.", name1);
					}
					else
					{
						GetClientName(i, name1, sizeof(name1));
						PrintToChatAll("Player %s was kicked for lagging.", name1);
						PrintToServer("Player %s was kicked for lagging.", name1);
						KickClientEx(i, "Kicked for lagging.");
					}
				}
			}
		}
	}
}

public checkPositionsWarning(){
	new maxclients = GetMaxClients()
	int kickType;
	for(new i=1; i <= maxclients; i++)
	{
		if(IsClientInGame(i)) 
		{
			if(lag[i] > 0.2) //heavily nested so that additional logic checks will not be done unless atleast the first bit is done
			{
				if(GetClientTeam(i) > 1 && IsPlayerAlive(i) && GetClientAvgLatency(i, NetFlow_Outgoing) > 0.2) 
				{
					//tell player they will be kicked in 10 seconds
					kickType = GetConvar() //load the convar kick type
					if(kickType == 1)
					{
						PrintToChat(i, "You will be moved to spectator if you do not fix your ping soon.");
					}
					else
					{
						PrintToChat(i, "You will be kicked if you do not fix your ping soon.");
					}
				}
			}
		}
	}
}

public int GetConvar()
{
	char buffer[128]
 
	sm_simplecsgoantilagger_kicktype.GetString(buffer, 128)
 
	return StringToInt(buffer)
}
