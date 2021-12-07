#include <sourcemod>

#define MAX_LINE_LENGTH 64
#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo = 
{
	name = "Execute on clients",
	author = "GachL (To NouveauJouers request)",
	description = "Executes a command depending how many users are online.",
	version = PLUGIN_VERSION,
	url = "http://bloodisgood.org"
}

new Handle:cvNclientcount;
new Handle:cvPclientcount;
new Handle:cvNexec;
new Handle:cvPexec;

public OnPluginStart()
{
	CreateConVar("sm_cmexec_version", PLUGIN_VERSION, "Version of this plugin");
	HookEvent("player_connect", Event_Connect);
	cvNclientcount = CreateConVar("sm_cmexec_nclients", "0", "Execute sm_cmexec_n if theres n or less players on the server");
	cvPclientcount = CreateConVar("sm_cmexec_pclients", "0", "Execute sm_cmexec_p if theres p or less players on the server");
	cvNexec = CreateConVar("sm_cmexec_n", "", "Execute this if there are n or less players on the server");
	cvPexec = CreateConVar("sm_cmexec_p", "", "Execute this if there are p or less players on the server");
}

public Event_Connect(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iN = GetConVarInt(cvNclientcount);
	new iP = GetConVarInt(cvPclientcount);
	new String:sNexec[MAX_LINE_LENGTH];
	new String:sPexec[MAX_LINE_LENGTH];
	new iCount = GetClientCount(false);
	
	GetConVarString(cvNexec, sNexec, sizeof(sNexec));
	GetConVarString(cvPexec, sPexec, sizeof(sPexec));
	
	if (iN >= iCount)
	{
		if (iN < iP)
		{
			if (iP >= iCount)
			{
				ServerCommand(sPexec);
			}
			else
			{
				ServerCommand(sNexec);
			}
		}
		else if (iN > iP)
		{
			ServerCommand(sNexec)
		}
		else // iN == iP
		{
			ServerCommand(sNexec);
			ServerCommand(sPexec);
		}
	}
	else if (iP >= iCount)
	{
		if (iP < iN)
		{
			ServerCommand(sPexec);
		}
	}
}
