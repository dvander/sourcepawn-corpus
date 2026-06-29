/***********INFO***********
-> Changelog:
1.3 - Added pln_steamid and pln_ip cvars.
1.2 - Added changelog and version cvar.
1.1 - Added green colors to the chat.
1.0 - First version.
*******************************/
#include <sourcemod>
#pragma semicolon 1
#define PLUGIN_VERSION "1.3"
#define num1 "1"
//Handles
new Handle:pln_version;
new Handle:pln_steamid;
new Handle:pln_ip;

public Plugin:myinfo =
{
	name = "Player Load Notify",
	author = "iloveportalz0r",
	description = "Says when clients finish loading.",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
}

public OnPluginStart()
{
	//Make CVars
	pln_version = CreateConVar("pln_version", PLUGIN_VERSION, "Player Load Notify version", FCVAR_DONTRECORD|FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED);
	pln_steamid = CreateConVar("pln_steamid", "1", "Show SteamID in PLN?", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED);
	pln_ip = CreateConVar("pln_ip", "1", "Show IP Address in PLN?", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED);
	//Set CVar values
	SetConVarString(pln_version, PLUGIN_VERSION);
	SetConVarString(pln_steamid, num1);
	SetConVarString(pln_ip, num1);
	//Hook the player load event
	HookEvent("player_activate",PlayerSpawnEvent);
}

public PlayerSpawnEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	//Get the client info stuff
	new clyent=GetClientOfUserId(GetEventInt(event, "userid"));
	decl String:steamid_show[100];
	//If pln_steamid is 1
	if(GetConVarBool(pln_steamid))
	{
		decl String:steamid[64];
		GetClientAuthString(clyent,steamid,64);
		steamid_show = ("(%s) ", steamid);
	}
	else //If pln_steamid is 0
	{
		steamid_show = ("");
	}

	decl String:ip_show[100];
	//If pln_ip is 1
	if(GetConVarBool(pln_ip))
	{
		decl String:ip[32];
		GetClientIP(clyent,ip,32);
		ip_show = (" from IP %s", ip);
	}
	else //If pln_ip is 0
	{
		ip_show = ("");
	}

	decl String:steamid2[64];
	decl String:ip2[32];
	decl String:iname[256];
	GetClientAuthString(clyent,steamid2,64);
	GetClientName(clyent,iname,256);
	GetClientIP(clyent,ip2,32);
	//If a player is unnamed, rename them
	if(StrContains(iname, "unnamed", false) != -1)
	{
		ClientCommand(clyent, "name PwneD by SourceMod");
	}
	//Print the info to all players
	PrintToChatAll("\x04%s\x01 \x04%s\x01finished loading\x04%s\x01", iname, steamid_show, ip_show);
	//Print the info to the server console
	PrintToServer("[SM] %s (%s) finished loading from IP %s", iname, steamid2, ip2);
}
