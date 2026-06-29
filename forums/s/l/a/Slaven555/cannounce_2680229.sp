#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <geoip>
#pragma newdecls required
#undef REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN
#include <adminmenu>
//#include <colors>

#define VERSION "1.8.1"

Handle hTopMenu = INVALID_HANDLE;
char g_fileset[128];
char g_filesettings[128];
int g_iSColors[5] =  { 1, 3, 4, 6, 5 };
char g_sSColors[5][13] =  { "{DEFAULT}", "{LIGHTGREEN}", "{GREEN}", "{YELLOW}", "{OLIVE}" };

Handle g_CvarConnectDisplayType = INVALID_HANDLE;

#include "cannounce/countryshow.sp"
#include "cannounce/joinmsg.sp"
#include "cannounce/geolist.sp"
#include "cannounce/suppress.sp"

public Plugin myinfo =
{
	name = "Connect Announce",
	author = "Arg! [Edited by Dosergen]",
	description = "Replacement of default player connection message, allows for custom connection messages",
	version = VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=77306"
};

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("cannounce.phrases");
	
	CreateConVar("sm_cannounce_version", VERSION, "Connect announce replacement", FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	g_CvarConnectDisplayType = CreateConVar("sm_ca_connectdisplaytype", "1", "[1|0] if 1 then displays connect message after admin check and allows the {PLAYERTYPE} placeholder. If 0 displays connect message on client auth (earlier) and disables the {PLAYERTYPE} placeholder");
	
	BuildPath(Path_SM, g_fileset, 128, "data/cannounce_messages.txt");
	BuildPath(Path_SM, g_filesettings, 128, "data/cannounce_settings.txt");
	
	//event hooks
	HookEvent("player_disconnect", event_PlayerDisconnect, EventHookMode_Pre);
	
	
	//country show
	SetupCountryShow();
	
	//custom join msg
	SetupJoinMsg();
	
	//geographical player list
	SetupGeoList();
	
	//suppress standard connection message
	SetupSuppress();
	
	//Account for late loading
	Handle topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);
	}
	
	//create config file if not exists
	//AutoExecConfig(true, "cannounce");
}

public void OnMapStart()
{
	//get, precache and set downloads for player custom sound files
	LoadSoundFilesCustomPlayer();
	
	//precahce and set downloads for sounds files for all players
	LoadSoundFilesAll();
	
	OnMapStart_JoinMsg();
}

public void OnClientAuthorized(int client, const char[] auth)
{
	if (GetConVarInt(g_CvarConnectDisplayType) == 0)
	{
		if (!IsFakeClient(client) && GetClientCount(true) < MaxClients)
		{
			OnPostAdminCheck_CountryShow(client);
			
			OnPostAdminCheck_JoinMsg(auth);
		}
	}
}

public void OnClientPostAdminCheck(int client)
{
	char auth[32];
	
	if (GetConVarInt(g_CvarConnectDisplayType) == 1)
	{
		GetClientAuthId(client, AuthId_Steam2, auth, sizeof(auth));
		
		if (!IsFakeClient(client) && GetClientCount(true) < MaxClients)
		{
			OnPostAdminCheck_CountryShow(client);
			
			OnPostAdminCheck_JoinMsg(auth);
		}
	}
}

public void OnPluginEnd()
{
	OnPluginEnd_JoinMsg();
	
	OnPluginEnd_CountryShow();
}


public void OnAdminMenuReady(Handle topmenu)
{
	//Block us from being called twice
	if (topmenu == hTopMenu)
	{
		return;
	}
	
	//Save the Handle
	hTopMenu = topmenu;
	
	OnAdminMenuReady_JoinMsg();
}

public Action event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (client && !IsFakeClient(client) && !dontBroadcast)
	{
		event_PlayerDisc_CountryShow(event, name, dontBroadcast);
		
		OnClientDisconnect_JoinMsg();
	}
	
	
	return event_PlayerDisconnect_Suppress(event, name, dontBroadcast);
}

bool IsLanIP(char src[16])
{
	char ip4[4][4];
	int ipnum;
	
	if (ExplodeString(src, ".", ip4, 4, 4) == 4)
	{
		ipnum = StringToInt(ip4[0]) * 65536 + StringToInt(ip4[1]) * 256 + StringToInt(ip4[2]);
		
		if ((ipnum >= 655360 && ipnum < 655360 + 65535) || (ipnum >= 11276288 && ipnum < 11276288 + 4095) || (ipnum >= 12625920 && ipnum < 12625920 + 255))
		{
			return true;
		}
	}
	
	return false;
}

void PrintFormattedMessageToAll(char rawmsg[301], int client)
{
	char message[301];
	
	GetFormattedMessage(rawmsg, client, message, sizeof(message));
	
	PrintToChatAll("%s", message);
}

void PrintFormattedMessageToAdmins(char rawmsg[301], int client)
{
	char message[301];
	
	GetFormattedMessage(rawmsg, client, message, sizeof(message));
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && CheckCommandAccess(i, "", ADMFLAG_GENERIC, true))
		{
			PrintToChat(i, "%s", message);
		}
	}
}

void PrintFormattedMsgToNonAdmins(char rawmsg[301], int client)
{
	char message[301];
	
	GetFormattedMessage(rawmsg, client, message, sizeof(message));
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !CheckCommandAccess(i, "", ADMFLAG_GENERIC, true))
		{
			PrintToChat(i, "%s", message);
		}
	}
}

//GetFormattedMessage - based on code from the DJ Tsunami plugin Advertisements - http://forums.alliedmods.net/showthread.php?p=592536
void GetFormattedMessage(char rawmsg[301], int client, char[] outbuffer, int outbuffersize)
{
	char buffer[256];
	char ip[16];
	char city[46];
	char region[46];
	char country[46];
	char ccode[3];
	char ccode3[4];
	char sColor[4];
	char sPlayerAdmin[32];
	char sPlayerPublic[32];
	bool bIsLanIp;
	
	AdminId aid;
	
	if (client > -1)
	{
		GetClientIP(client, ip, sizeof(ip));
		
		//detect LAN ip
		bIsLanIp = IsLanIP(ip);
		
		// Using GeoIP extension
		{
			if (!GeoipCity(ip, city, sizeof(city)))
			{
				if (bIsLanIp)
				{
					Format(city, sizeof(city), "%T", "LAN City Desc", LANG_SERVER);
				}
				else
				{
					Format(city, sizeof(city), "%T", "Unknown City Desc", LANG_SERVER);
				}
			}
			
			if (!GeoipRegion(ip, region, sizeof(region)))
			{
				if (bIsLanIp)
				{
					Format(region, sizeof(region), "%T", "LAN Region Desc", LANG_SERVER);
				}
				else
				{
					Format(region, sizeof(region), "%T", "Unknown Region Desc", LANG_SERVER);
				}
			}
			
			if (!GeoipCountry(ip, country, sizeof(country)))
			{
				if (bIsLanIp)
				{
					Format(country, sizeof(country), "%T", "LAN Country Desc", LANG_SERVER);
				}
				else
				{
					Format(country, sizeof(country), "%T", "Unknown Country Desc", LANG_SERVER);
				}
			}
			
			if (!GeoipCode2(ip, ccode))
			{
				if (bIsLanIp)
				{
					Format(ccode, sizeof(ccode), "%T", "LAN Country Short", LANG_SERVER);
				}
				else
				{
					Format(ccode, sizeof(ccode), "%T", "Unknown Country Short", LANG_SERVER);
				}
			}
			
			if (!GeoipCode3(ip, ccode3))
			{
				if (bIsLanIp)
				{
					Format(ccode3, sizeof(ccode3), "%T", "LAN Country Short 3", LANG_SERVER);
				}
				else
				{
					Format(ccode3, sizeof(ccode3), "%T", "Unknown Country Short 3", LANG_SERVER);
				}
			}
		}
		
		// Fallback for unknown/empty location strings
		if (StrEqual(city, ""))
		{
			Format(city, sizeof(city), "%T", "Unknown City Desc", LANG_SERVER);
		}
		
		if (StrEqual(region, ""))
		{
			Format(region, sizeof(region), "%T", "Unknown Region Desc", LANG_SERVER);
		}
		
		if (StrEqual(country, ""))
		{
			Format(country, sizeof(country), "%T", "Unknown Country Desc", LANG_SERVER);
		}
		
		if (StrEqual(ccode, ""))
		{
			Format(ccode, sizeof(ccode), "%T", "Unknown Country Short", LANG_SERVER);
		}
		
		if (StrEqual(ccode3, ""))
		{
			Format(ccode3, sizeof(ccode3), "%T", "Unknown Country Short 3", LANG_SERVER);
		}
		
		// Add "The" in front of certain countries
		if (StrContains(country, "United", false) != -1 || 
			StrContains(country, "Republic", false) != -1 || 
			StrContains(country, "Federation", false) != -1 || 
			StrContains(country, "Island", false) != -1 || 
			StrContains(country, "Netherlands", false) != -1 || 
			StrContains(country, "Isle", false) != -1 || 
			StrContains(country, "Bahamas", false) != -1 || 
			StrContains(country, "Maldives", false) != -1 || 
			StrContains(country, "Philippines", false) != -1 || 
			StrContains(country, "Vatican", false) != -1)
		{
			Format(country, sizeof(country), "The %s", country);
		}
		
		if (StrContains(rawmsg, "{PLAYERNAME}") != -1)
		{
			GetClientName(client, buffer, sizeof(buffer));
			ReplaceString(rawmsg, sizeof(rawmsg), "{PLAYERNAME}", buffer);
		}
		
		if (StrContains(rawmsg, "{STEAMID}") != -1)
		{
			GetClientAuthId(client, AuthId_Steam2, buffer, sizeof(buffer));
			ReplaceString(rawmsg, sizeof(rawmsg), "{STEAMID}", buffer);
		}
		
		if (StrContains(rawmsg, "{PLAYERCOUNTRY}") != -1)
		{
			ReplaceString(rawmsg, sizeof(rawmsg), "{PLAYERCOUNTRY}", country);
		}
		
		if (StrContains(rawmsg, "{PLAYERCOUNTRYSHORT}") != -1)
		{
			ReplaceString(rawmsg, sizeof(rawmsg), "{PLAYERCOUNTRYSHORT}", ccode);
		}
		
		if (StrContains(rawmsg, "{PLAYERCOUNTRYSHORT3}") != -1)
		{
			ReplaceString(rawmsg, sizeof(rawmsg), "{PLAYERCOUNTRYSHORT3}", ccode3);
		}
		
		if (StrContains(rawmsg, "{PLAYERCITY}") != -1)
		{
			ReplaceString(rawmsg, sizeof(rawmsg), "{PLAYERCITY}", city);
		}
		
		if (StrContains(rawmsg, "{PLAYERREGION}") != -1)
		{
			ReplaceString(rawmsg, sizeof(rawmsg), "{PLAYERREGION}", region);
		}
		
		if (StrContains(rawmsg, "{PLAYERIP}") != -1)
		{
			ReplaceString(rawmsg, sizeof(rawmsg), "{PLAYERIP}", ip);
		}
		
		if (StrContains(rawmsg, "{PLAYERTYPE}") != -1 && GetConVarInt(g_CvarConnectDisplayType) == 1)
		{
			aid = GetUserAdmin(client);
			
			if (GetAdminFlag(aid, Admin_Generic))
			{
				Format(sPlayerAdmin, sizeof(sPlayerAdmin), "%T", "CA Admin", LANG_SERVER);
				ReplaceString(rawmsg, sizeof(rawmsg), "{PLAYERTYPE}", sPlayerAdmin);
			}
			else
			{
				Format(sPlayerPublic, sizeof(sPlayerPublic), "%T", "CA Public", LANG_SERVER);
				ReplaceString(rawmsg, sizeof(rawmsg), "{PLAYERTYPE}", sPlayerPublic);
			}
		}
	}
	for (int c = 0; c < sizeof(g_iSColors); c++)
	{
		if (StrContains(rawmsg, g_sSColors[c]) != -1)
		{
			Format(sColor, sizeof(sColor), "%c", g_iSColors[c]);
			ReplaceString(rawmsg, sizeof(rawmsg), g_sSColors[c], sColor);
		}
	}
	
	Format(outbuffer, outbuffersize, "%s", rawmsg);
} 