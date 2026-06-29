#pragma semicolon 1
#include <sourcemod>
#include <geoip>

#define PLUGIN_VERSION "1.1"
#define PLUGIN_DESCRIPTION "Prints useful information about connected clients."

public Plugin:myinfo =
{
    name 		=		"Player Information",			// http://www.youtube.com/watch?v=YM5xJzFhbW8&hd=1
    author		=		"Kyle Sanderson", 
    description	=		PLUGIN_DESCRIPTION, 
    version		=		PLUGIN_VERSION, 
    url			=		"http://SourceMod.net"
};

public OnPluginStart()
{
	CreateConVar("sm_playerinformation_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegAdminCmd("sm_pinfo", OnPInfo, ADMFLAG_GENERIC, "Prints information about Clients");
}

public Action:OnPInfo(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "\x05[Player Information]\04 <Target Name | #userid >");
		return Plugin_Handled;
	}
		
	decl String:sArg[128], String:sGeoIP[64], String:sIP[17], String:sSteamID[54], String:sTargetName[MAXPLAYERS+1];
	decl target_list[MAXPLAYERS+1];
	decl bool:target_ml;
	
	GetCmdArgString(sArg, sizeof(sArg));
	
	new ListSize = ProcessTargetString(sArg, client, target_list, MAXPLAYERS, COMMAND_FILTER_NO_BOTS, sTargetName, sizeof(sTargetName), target_ml);
	if (ListSize > 0)
	{
		new target;
		ReplyToCommand(client, "\x05[Player Information]");
		for (new i = 0; i < ListSize; i++)
		{
			target = target_list[i];
			
			if (!GetClientIP(target, sIP, sizeof(sIP))) // This trap should never work...
			{
				continue;
			}
			
			switch (GeoipCountry(sIP, sGeoIP, sizeof(sGeoIP)))
			{
				case 0:
				{
					switch (GetClientAuthString(target, sSteamID, sizeof(sSteamID)))
					{
						case 0:
						{
							ReplyToCommand(client, "\x04Name: \x05%N\x04\nIP Address: \x05%s", target, sIP);
						}
						
						case 1:
						{
							ReplyToCommand(client, "\x04Name: \x05%N\x04\nIP Address: \x05%s\x04\nSteam ID: \x05%s\x04\nConnection Time: \x05%d Minutes.", target, sIP, sSteamID, (RoundToFloor(GetClientTime(target_list[i])) / 60));
						}
					}
				}
				
				case 1:
				{
					switch (GetClientAuthString(target, sSteamID, sizeof(sSteamID)))
					{
						case 0:
						{
							ReplyToCommand(client, "\x04Name: \x05%N\x04\nCountry: \x05%s\x04\nIP Address: \x05%s", target, sGeoIP, sIP);
						}
						
						case 1:
						{
							ReplyToCommand(client, "\x04Name: \x05%N\x04\nCountry: \x05%s\x04\nIP Address: \x05%s\x04\nSteam ID: \x05%s\x04\nConnection Time: \x05%d Minutes.", target, sGeoIP, sIP, sSteamID, (RoundToFloor(GetClientTime(target_list[i])) / 60));
						}
					}
				}
			}
		}
		return Plugin_Handled;
	}
	ReplyToCommand(client, "\x05[PlayerInfo]\x04 Couldn't find %s.", sArg);
	return Plugin_Handled;
}