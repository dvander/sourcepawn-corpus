#include <sourcemod>

#define VERSION "1.0.0"

new Handle:g_bantime;
new Handle:g_unconnected;
new Handle:g_unconnected_reason;
new Handle:g_banbanned;

public Plugin:myinfo = {
	name = "Ban Spam Prevention/Unconnected Block",
	author = "BlackOps7799",
	description = "IP ban players that are steamid banned to prevent join spamming/Kick players that have the name of 'unconnected'",
	version = VERSION,
	url = ""
};


public OnPluginStart()
{
	CreateConVar("sm_unconnectedblock_version", VERSION, "Current version of this plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	HookEvent("player_disconnect", Player_Disconnected);
	HookEvent("player_connect", Player_Connected);
	
	g_bantime = CreateConVar("sm_bantime", "5");
	g_unconnected = CreateConVar("sm_unconnected_kick", "1");
	g_unconnected_reason = CreateConVar("sm_unconnected_reason", "You cannot connect to this server without a name!");
	g_banbanned = CreateConVar("sm_spam_ban", "1");
}

public Action:Player_Connected(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarBool(g_unconnected) == true)
	{
		new userid = GetEventInt(event, "userid");
		
		decl String:Name[64];
		GetEventString(event, "name",Name,sizeof(Name));
		
		if(StrEqual(Name,"") == true)
		{
			decl String:KickReason[128];
			GetConVarString(g_unconnected_reason, KickReason, sizeof(KickReason))
			
			ServerCommand("kickid %i \"%s\"",userid,KickReason);
			LogToGame("kicked player for using unconnected exploit");
		}
	}
	
	return Plugin_Continue;
}

public Action:Player_Disconnected(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarBool(g_banbanned) == true)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		decl String:Reason[64],String:NetID[64],String:ReasonTable[3][64],String:ImplodedReason[64],String:IP[16];
		GetEventString(event, "reason",Reason,sizeof(Reason));
		GetEventString(event, "networkid",NetID,sizeof(NetID));

		if(client)
		{
			ReasonTable[0] = "STEAM UserID";
			ReasonTable[1] = NetID;
			ReasonTable[2] = "is banned";
			ImplodeStrings(ReasonTable, 3, " ", ImplodedReason, sizeof(ImplodedReason));
			if(StrEqual(Reason,ImplodedReason) == true)
			{
				GetClientIP(client, IP, sizeof(IP)); 
				ServerCommand("addip %i %s",GetConVarInt(g_bantime), IP);
				ServerCommand("writeip");
				LogToGame("Player (%s) IP banned (%s) for %i minutes for connecting while banned.", NetID, IP, GetConVarInt(g_bantime));
			}
		}
	}

	return Plugin_Continue;
}