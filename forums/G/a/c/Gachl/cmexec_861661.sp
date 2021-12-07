#include <sourcemod>

#define MAX_LINE_LENGTH 64
#define PLUGIN_VERSION "1.1.0"

public Plugin:myinfo = 
{
	name = "Execute on clients",
	author = "GachL (To NouveauJoueurs request)",
	description = "Executes a command depending how many users are online.",
	version = PLUGIN_VERSION,
	url = "http://bloodisgood.org"
}

new Handle:cvNclientcount;
new Handle:cvPclientcount;
new Handle:cvNexec;
new Handle:cvPexec;
new Handle:cvE1clientcount;
new Handle:cvE2clientcount;
new Handle:cvE1exec;
new Handle:cvE2exec;

public OnPluginStart()
{
	CreateConVar("sm_cmexec_version", PLUGIN_VERSION, "Version of this plugin");
	HookEvent("player_connect", Event_Connect);
	cvNclientcount = CreateConVar("sm_cmexec_nclients", "0", "Execute sm_cmexec_n if theres n or less players on the server");
	cvPclientcount = CreateConVar("sm_cmexec_pclients", "0", "Execute sm_cmexec_p if theres p or less players on the server");
	cvNexec = CreateConVar("sm_cmexec_n", "", "Execute this if there are n or less players on the server");
	cvPexec = CreateConVar("sm_cmexec_p", "", "Execute this if there are p or less players on the server");
	cvE1clientcount = CreateConVar("sm_cmexec_e1clients", "0", "Execute sm_cmexec_e1 if theres e1 players on the server");
	cvE2clientcount = CreateConVar("sm_cmexec_e2clients", "0", "Execute sm_cmexec_e2 if theres e2 players on the server");
	cvE1exec = CreateConVar("sm_cmexec_e1", "", "Execute this if there are e1 players on the server");
	cvE2exec = CreateConVar("sm_cmexec_e2", "", "Execute this if there are e2 players on the server");
}

public Event_Connect(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iN = GetConVarInt(cvNclientcount);
	new iP = GetConVarInt(cvPclientcount);
	new iE1 = GetConVarInt(cvE1clientcount);
	new iE2 = GetConVarInt(cvE2clientcount);
	new String:sNexec[MAX_LINE_LENGTH];
	new String:sPexec[MAX_LINE_LENGTH];
	new String:sE1exec[MAX_LINE_LENGTH];
	new String:sE2exec[MAX_LINE_LENGTH];
	new iCount = GetClientCount(false);
	
	GetConVarString(cvNexec, sNexec, sizeof(sNexec));
	GetConVarString(cvPexec, sPexec, sizeof(sPexec));
	GetConVarString(cvE1exec, sE1exec, sizeof(sE1exec));
	GetConVarString(cvE2exec, sE2exec, sizeof(sE2exec));

	if (iE1 == iCount)
	{
		ServerCommand(sE1exec);
	}

	if (iE2 == iCount)
	{
		ServerCommand(sE2exec);
	}
	
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
