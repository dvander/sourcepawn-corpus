/***********INFO***********
I will try to include helpful comments in the next version!
-> Changelog:
1.2 - Added changelog and version cvar.
1.1 - Added green colors to the chat
1.0 - First version.
*******************************/
#include <sourcemod>
#pragma semicolon 1
#define PLUGIN_VERSION "1.2"
new Handle:pln_version;

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
	pln_version = CreateConVar("pln_version", PLUGIN_VERSION, "Player Load Notify version", FCVAR_DONTRECORD|FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED);
	SetConVarString(pln_version, PLUGIN_VERSION);
	HookEvent("player_activate",PlayerSpawnEvent);
}

public PlayerSpawnEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	new clyent=GetClientOfUserId(GetEventInt(event, "userid"));
	decl String:ip[32];
	decl String:steamid[64];
	decl String:iname[256];
	GetClientIP(clyent,ip,32);
	GetClientAuthString(clyent,steamid,64);
	GetClientName(clyent,iname,256);
	if(StrContains(iname, "unnamed", false) != -1)
	{
		ClientCommand(clyent, "name PwneD by SourceMod");
	}
	PrintToChatAll("\x04%s\x01 (\x04%s\x01) finished loading from IP \x04%s\x01", iname, steamid, ip);
	PrintToServer("[SM] %s (%s) finished loading from IP %s", iname, steamid, ip);
}
