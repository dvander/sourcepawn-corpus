/**
	Original Country Filter by Knagg0 http://forums.alliedmods.net/showthread.php?t=56188



	Country Filter 2nd Edition, Version 2.0.4
	- Re-write whole crab 18.3.2011
*/

#include <sourcemod>
#include <geoip>

new Handle:cf_mode = INVALID_HANDLE;
new bool:g_mode = false;

new Handle:cf_alphacode = INVALID_HANDLE;
new bool:g_alphacode = false;

new Handle:cf_chatusecode = INVALID_HANDLE;
new bool:g_chatusecode = false;

new Handle:cf_countries = INVALID_HANDLE;

new Handle:cf_adminimmunity = INVALID_HANDLE;
new bool:g_adminimmunity = false;

new Handle:cf_allowlan = INVALID_HANDLE;
new bool:g_allowlan = false;

new Handle:cf_allowunidentified = INVALID_HANDLE;
new bool:g_allowunidentified = false;

new Handle:cf_chatannouncements = INVALID_HANDLE;
new g_chatannouncements;

public Plugin:myinfo =
{
	name = "Country Filter 2nd Edition",
	author = "Bacardi",
	description = "Allow or reject certain countries connect to your server.",
	version = "2.0.4",
	url = "http://www.sourcemod.net/"
}

public OnPluginStart()
{
	LoadTranslations("country_filter_2nd_edition.phrases");

	cf_mode = CreateConVar("cf_mode", "0", "0 = Allow all expect cf_countries\n1 = Allow only cf_countries", FCVAR_NONE, true, 0.0, true, 1.0);
	g_mode = GetConVarBool(cf_mode);
	HookConVarChange(cf_mode, ConVarChanged);

	cf_alphacode = CreateConVar("cf_alphacode", "2", "Choose what code type use in cf_countries\n2 = ISO 3166-1 alpha-2 codes (GB JP US)\n3 = ISO 3166-1 alpha-3 codes (GBR JPN USA)\nhttp://en.wikipedia.org/wiki/ISO_3166-1#Current_codes", FCVAR_NONE, true, 2.0, true, 3.0);
	g_alphacode = GetConVarInt(cf_alphacode) == 2 ? true: false;
	HookConVarChange(cf_alphacode, ConVarChanged);

	cf_countries = CreateConVar("cf_countries", "", "List countries\nexample alpha 2 codes: \"GB JP US\"\nexample alpha 3 codes: \"GBR JPN USA\"", FCVAR_NONE);

	cf_chatusecode = CreateConVar("cf_chatusecode", "0", "Print country name in chat using, 0 = Country name, 1 = Country code", FCVAR_NONE, true, 0.0, true, 1.0);
	g_chatusecode = GetConVarBool(cf_chatusecode);
	HookConVarChange(cf_chatusecode, ConVarChanged);

	cf_adminimmunity = CreateConVar("cf_adminimmunity", "0", "Admin immunity, 0 = Disabled, 1 = Enabled", FCVAR_NONE, true, 0.0, true, 1.0);
	g_adminimmunity = GetConVarBool(cf_adminimmunity);
	HookConVarChange(cf_adminimmunity, ConVarChanged);

	cf_allowlan = CreateConVar("cf_allowlan", "0", "Allow players connect from LAN, 0 = Disabled, 1 = Enabled\nIP 10.x.x.x\nIP 127.x.x.x\nIP 169.254.x.x\nIP 192.168.x.x\nIP 172.16.x.x - 172.31.x.x", FCVAR_NONE, true, 0.0, true, 1.0);
	g_allowlan = GetConVarBool(cf_allowlan);
	HookConVarChange(cf_allowlan, ConVarChanged);

	cf_allowunidentified = CreateConVar("cf_allowunidentified", "0", "Allow players connect from unidentified country, 0 = Disabled, 1 = Enabled", FCVAR_NONE, true, 0.0, true, 1.0);
	g_allowunidentified = GetConVarBool(cf_allowunidentified);
	HookConVarChange(cf_allowunidentified, ConVarChanged);

	cf_chatannouncements = CreateConVar("cf_chatannouncements", "1", "Print chat announcements to all players\nUsage 1+2 = 3 (Print allowed and rejected country connections)\n0 = Off\n1 = Allowed connections\n2 = Rejected connections\n4 = Allowed LAN connections\n8 = Rejected LAN connections", FCVAR_NONE, true, 0.0, true, 15.0);
	g_chatannouncements = GetConVarInt(cf_chatannouncements);
	HookConVarChange(cf_chatannouncements, ConVarChanged);
	// 0 off
	// 1 allow country
	// 2 denied country
	// 4 allow lan
	// 8 denied lan

	AutoExecConfig(true, "country_filter_2nd_edition");
}

public ConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(convar == cf_mode)
	{
		g_mode = StringToInt(newValue) == 1 ? true:false;
	}

	if(convar == cf_alphacode)
	{
		g_alphacode = StringToInt(newValue) == 2 ? true:false;
	}

	if(convar == cf_chatusecode)
	{
		g_chatusecode = StringToInt(newValue) == 1 ? true:false;
	}

	if(convar == cf_adminimmunity)
	{
		g_adminimmunity = StringToInt(newValue) == 1 ? true:false;
	}

	if(convar == cf_allowlan)
	{
		g_allowlan = StringToInt(newValue) == 1 ? true:false;
	}

	if(convar == cf_allowunidentified)
	{
		g_allowunidentified = StringToInt(newValue) == 1 ? true:false;
	}

	if(convar == cf_chatannouncements)
	{
		g_chatannouncements = StringToInt(newValue);
	}
}

public OnClientConnected(client)
{
	if(!g_adminimmunity && !IsFakeClient(client))
	{
		CheckConnection(client);
	}
}

public OnClientPostAdminCheck(client)
{
	if(g_adminimmunity && !IsFakeClient(client) && !CheckCommandAccess(client, "cf_immunity", ADMFLAG_RESERVATION))
	{
		CheckConnection(client);
	}
}

CheckConnection(client)
{
	decl String:IP[16];
	IP[0] = '\0';
	GetClientIP(client, IP, sizeof(IP));

	if(StrEqual(IP, "loopback"))	// Player is listenserver
	{
		return;
	}

	decl String:CODE[4];
	CODE[0] = '\0';

	if(g_alphacode ? GeoipCode2(IP, CODE):GeoipCode3(IP, CODE))
	{
		// Country found from GeoIP.dat

		decl String:str[257], String:expcodes[64][4];
		str[0] = '\0';
		GetConVarString(cf_countries, str, sizeof(str));	// Get list cf_countries

		new bool:reject = g_mode ? true:false;	// Default if country not found from cf_countries

		if(str[0] != '\0')	// cf_countries should contain something
		{
			new total = ExplodeString(str, " ", expcodes, 64, 4);	// Separate cf_countries codes
	
			for(new i = 0; i < total; i++)	// Loop amount of cf_countries codes
			{
				if(StrEqual(CODE, expcodes[i]))	// Player country match from cf_countries list
				{
					reject = g_mode ? false:true;	// Will we reject this country ? Depend cf_mode.
					break;
				}
			}
		}

		decl String:countryname[45];
		countryname[0] = '\0';
		GeoipCountry(IP, countryname, sizeof(countryname));

		switch(reject)
		{
			case true:	// Reject
			{
				if(g_chatannouncements & 2)
				{
					PrintToChatAll("%t", "Country not allowed join chat", client, g_chatusecode ? CODE:countryname);
				}
				KickClient(client, "%t", "Country not allowed join kick", countryname);
			}
			case false:	// Pass
			{
				if(g_chatannouncements & 1)
				{
					PrintToChatAll("%t", "Country allowed join chat", client, g_chatusecode ? CODE:countryname);
				}
			}
		}
	}
	else
	{
		// Country not found from GeoIP.dat
		// Failed identify player country (Reason for this could be old GeoIP.dat file or one of LAN IP addresses)

		new bool:islan = false;
		decl String:expip[4][2];
		ExplodeString(IP, ".", expip, 2, 4);
		new ip1st = StringToInt(expip[0]), ip2nd = StringToInt(expip[1]);

		if(ip1st == 10 || ip1st == 127)	// 10.x.x.x | 127.x.x.x
		{
			islan = true;
		}
		else if(ip1st == 192 && ip2nd == 168 || ip1st == 169 && ip2nd == 254)	// 192.168.x.x | 169.254.x.x
		{
			islan = true;
		}
		else if(ip1st == 172 && ip2nd >= 16 && ip2nd <= 31)	// 172.16.x.x - 172.31.x.x
		{
			islan = true;
		}

		switch(islan)
		{
			case true:
			{
				if(!g_allowlan)
				{
					if(g_chatannouncements & 8)
					{
						PrintToChatAll("%t", "LAN not allowed join chat", client, IP);
					}
					KickClient(client, "%t", "LAN not allowed join kick", IP);
				}
				else
				{
					if(g_chatannouncements & 4)
					{
						PrintToChatAll("%t", "LAN allowed join chat", client, IP);
					}
				}
			}
			case false:
			{
				if(!g_allowunidentified)
				{
					if(g_chatannouncements & 2)
					{
						PrintToChatAll("%t", "Unidentified not allowed join chat", client);
					}
					KickClient(client, "%t", "Unidentified not allowed join kick");
				}
				else
				{
					if(g_chatannouncements & 1)
					{
						PrintToChatAll("%t", "Unidentified allowed join chat", client);
					}
				}
			}
		}
	}
}