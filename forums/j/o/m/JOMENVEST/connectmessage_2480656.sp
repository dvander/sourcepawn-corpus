#include <sourcemod>
#include <geoip>

#pragma newdecls required

ConVar h_connectmsg;
ConVar h_disconnectmsg;
ConVar h_steamidmsg;
ConVar h_countrymsg;
ConVar h_plusminusmsg;
ConVar h_tagmsg;
ConVar h_admintagmsg;

public Plugin myinfo = 
{
	name = "Connect/disconnect message", 
	author = "JOMENVEST", 
	description = "Shows info about connecting/disconnecting players", 
	version = "1.0", 
	url = "https://forums.alliedmods.net/member.php?u=276220"
}

public void OnPluginStart()
{
	h_connectmsg = CreateConVar("sm_connectmsg", "1", "Shows connecting messages", FCVAR_DONTRECORD, true, 0.0, true, 1.0);
	h_disconnectmsg = CreateConVar("sm_disconnectmsg", "1", "Shows disconnecting messages", FCVAR_DONTRECORD, true, 0.0, true, 1.0);
	h_steamidmsg = CreateConVar("sm_steamidmsg", "1", "Shows the STEAMID in messages", FCVAR_DONTRECORD, true, 0.0, true, 1.0);
	h_countrymsg = CreateConVar("sm_countrymsg", "1", "Shows the COUNTRY in messages", FCVAR_DONTRECORD, true, 0.0, true, 1.0);
	h_plusminusmsg = CreateConVar("sm_plusminusmsg", "0", "Shows the PLUS/MINUS in messages", FCVAR_DONTRECORD, true, 0.0, true, 1.0);
	h_tagmsg = CreateConVar("sm_tagmsg", "1", "Shows the TAG in messages", FCVAR_DONTRECORD, true, 0.0, true, 1.0);
	h_admintagmsg = CreateConVar("sm_admintagmsg", "1", "Shows the ADMIN tag for flag b in messages", FCVAR_DONTRECORD, true, 0.0, true, 1.0);
	HookEvent("player_disconnect", silent, EventHookMode_Pre);
}

public void OnClientPostAdminCheck(int client)
{
	if (h_connectmsg.BoolValue)
	{
		char authid[64], IP[16], Country[46];
		GetClientAuthId(client, AuthId_Steam2, authid, sizeof(authid));
		
		GetClientIP(client, IP, sizeof(IP), true);
		
		if (!GeoipCountry(IP, Country, sizeof Country))Format(Country, sizeof(Country), "Unknown Country");
		
		if (h_plusminusmsg.IntValue == 1 && h_tagmsg.IntValue == 0)
		{
			if (h_steamidmsg.IntValue == 1)
			{
				if (h_countrymsg.IntValue == 1)PrintToChatAll("+ \x04%N \x05[%s] \x01connected from %s", client, authid, Country);
				else PrintToChatAll("+ \x04%N \x05[%s] \x01connected", client, authid);
			}
			else
			{
				if (h_countrymsg.IntValue == 1)PrintToChatAll("+ \x04%N \x01connected from %s", client, Country);
				else PrintToChatAll("+ \x04%N \x01connected", client);
			}
		}
		else if (h_tagmsg.IntValue == 1 && h_plusminusmsg.IntValue == 0)
		{
			if (h_admintagmsg.IntValue == 1)
			{
				if (IsPlayerGenericAdmin(client))
				{
					if (h_steamidmsg.IntValue == 1)
					{
						if (h_countrymsg.IntValue == 1)PrintToChatAll("Admin \x04%N \x05[%s] \x01connected from %s", client, authid, Country);
						else PrintToChatAll("Admin \x04%N \x05[%s] \x01connected", client, authid);
					}
					else
					{
						if (h_countrymsg.IntValue == 1)PrintToChatAll("Admin \x04%N \x01connected from %s", client, Country);
						else PrintToChatAll("Admin \x04%N \x01connected", client);
					}
				}
				else
				{
					if (h_steamidmsg.IntValue == 1)
					{
						if (h_countrymsg.IntValue == 1)PrintToChatAll("Player \x04%N \x05[%s] \x01connected from %s", client, authid, Country);
						else PrintToChatAll("Player \x04%N \x05[%s] \x01connected", client, authid);
					}
					else
					{
						if (h_countrymsg.IntValue == 1)PrintToChatAll("Player \x04%N \x01connected from %s", client, Country);
						else PrintToChatAll("Player \x04%N \x01connected", client);
					}
				}
			}
		}
		else
		{
			if (h_steamidmsg.IntValue == 1)
			{
				if (h_countrymsg.IntValue == 1)PrintToChatAll(" \x04%N \x05[%s] \x01connected from %s", client, authid, Country);
				else PrintToChatAll(" \x04%N \x05[%s] \x01connected", client, authid);
			}
			else
			{
				if (h_countrymsg.IntValue == 1)PrintToChatAll(" \x04%N \x01connected from %s", client, Country);
				else PrintToChatAll(" \x04%N \x01connected", client);
			}
		}
	}
}

public Action silent(Event event, const char[] name, bool dontBroadcast)
{
	SetEventBroadcast(event, true);
	return Plugin_Continue;
}

public void OnClientDisconnect(int client)
{
	if (h_disconnectmsg.BoolValue)
	{
		char authid[64], IP[16], Country[46];
		GetClientIP(client, IP, sizeof(IP), true);
		
		if (!GeoipCountry(IP, Country, sizeof Country))Format(Country, sizeof(Country), "Unknown Country");
		
		if (h_plusminusmsg.IntValue == 1 && h_tagmsg.IntValue == 0)
		{
			if (h_steamidmsg.IntValue == 1)
			{
				GetClientAuthId(client, AuthId_Steam2, authid, sizeof(authid));
				if (h_countrymsg.IntValue == 1)PrintToChatAll("- \x04%N \x05[%s] \x01disconnected from %s", client, authid, Country);
				else PrintToChatAll("- \x04%N \x05[%s] \x01disconnected", client, authid);
			}
			else
			{
				if (h_countrymsg.IntValue == 1)PrintToChatAll("- \x04%N \x01disconnected from %s", client, Country);
				else PrintToChatAll("- \x04%N \x01disconnected", client);
			}
		}
		else if (h_tagmsg.IntValue == 1 && h_plusminusmsg.IntValue == 0)
		{
			if (h_admintagmsg.IntValue == 1)
			{
				if (IsPlayerGenericAdmin(client))
				{
					if (h_steamidmsg.IntValue == 1)
					{
						GetClientAuthId(client, AuthId_Steam2, authid, sizeof(authid));
						if (h_countrymsg.IntValue == 1)PrintToChatAll("Admin \x04%N \x05[%s] \x01disconnected from %s", client, authid, Country);
						else PrintToChatAll("Admin \x04%N \x05[%s] \x01disconnected", client, authid);
					}
					else
					{
						if (h_countrymsg.IntValue == 1)PrintToChatAll("Admin \x04%N \x01disconnected from %s", client, Country);
						else PrintToChatAll("Admin \x04%N \x01disconnected", client);
					}
				}
				else
				{
					if (h_steamidmsg.IntValue == 1)
					{
						GetClientAuthId(client, AuthId_Steam2, authid, sizeof(authid));
						if (h_countrymsg.IntValue == 1)PrintToChatAll("Player \x04%N \x05[%s] \x01disconnected from %s", client, authid, Country);
						else PrintToChatAll("Player \x04%N \x05[%s] \x01disconnected", client, authid);
					}
					else
					{
						if (h_countrymsg.IntValue == 1)PrintToChatAll("Player \x04%N \x01disconnected from %s", client, Country);
						else PrintToChatAll("Player \x04%N \x01disconnected", client);
					}
				}
			}
		}
		else
		{
			if (h_steamidmsg.IntValue == 1)
			{
				GetClientAuthId(client, AuthId_Steam2, authid, sizeof(authid));
				if (h_countrymsg.IntValue == 1)PrintToChatAll(" \x04%N \x05[%s] \x01disconnected from %s", client, authid, Country);
				else PrintToChatAll(" \x04%N \x05[%s] \x01disconnected", client, authid);
			}
			else
			{
				if (h_countrymsg.IntValue == 1)PrintToChatAll(" \x04%N \x01disconnected from %s", client, Country);
				else PrintToChatAll(" \x04%N \x01disconnected", client);
			}
		}
	}
}

bool IsPlayerGenericAdmin(int client)
{
	if (CheckCommandAccess(client, "generic_admin", ADMFLAG_GENERIC, false))return true;
	
	return false;
} 