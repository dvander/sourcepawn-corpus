#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <geoip>

#define PLUGIN_VERSION "2.0.5h"

ConVar cf_mode;
bool g_mode = false;

ConVar cf_alphacode;
bool g_alphacode = false;

ConVar cf_chatusecode;
bool g_chatusecode = false;

ConVar cf_countries;

ConVar cf_adminimmunity;
bool g_adminimmunity = false;

ConVar cf_allowlan;
bool g_allowlan = false;

ConVar cf_allowunidentified;
bool g_allowunidentified = false;

ConVar cf_chatannouncements;
int g_chatannouncements;

public Plugin myinfo =
{
	name = "Country Filter 2nd Edition",
	author = "Bacardi modded by Huck",
	description = "Allow or reject certain countries from connecting to your server.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showpost.php?p=2844242&postcount=123"
};

public void OnPluginStart()
{
	LoadTranslations("country_filter_2nd_edition.phrases");

	cf_mode = CreateConVar(
		"cf_mode",
		"0",
		"0 = Allow all except cf_countries\n1 = Allow only cf_countries",
		FCVAR_NONE,
		true,
		0.0,
		true,
		1.0
	);

	g_mode = cf_mode.BoolValue;
	cf_mode.AddChangeHook(ConVarChanged);

	cf_alphacode = CreateConVar(
		"cf_alphacode",
		"2",
		"Choose what code type use in cf_countries\n2 = ISO 3166-1 alpha-2 codes (GB JP US)\n3 = ISO 3166-1 alpha-3 codes (GBR JPN USA)\nhttp://en.wikipedia.org/wiki/ISO_3166-1#Current_codes",
		FCVAR_NONE,
		true,
		2.0,
		true,
		3.0
	);

	g_alphacode = (cf_alphacode.IntValue == 2);
	cf_alphacode.AddChangeHook(ConVarChanged);

	cf_countries = CreateConVar(
		"cf_countries",
		"",
		"List countries\nexample alpha 2 codes: \"GB JP US\"\nexample alpha 3 codes: \"GBR JPN USA\"",
		FCVAR_NONE
	);

	cf_chatusecode = CreateConVar(
		"cf_chatusecode",
		"1",
		"Print country name in chat using, 0 = Country name, 1 = Country code",
		FCVAR_NONE,
		true,
		0.0,
		true,
		1.0
	);

	g_chatusecode = cf_chatusecode.BoolValue;
	cf_chatusecode.AddChangeHook(ConVarChanged);

	cf_adminimmunity = CreateConVar(
		"cf_adminimmunity",
		"1",
		"Admin immunity, 0 = Disabled, 1 = Enabled",
		FCVAR_NONE,
		true,
		0.0,
		true,
		1.0
	);

	g_adminimmunity = cf_adminimmunity.BoolValue;
	cf_adminimmunity.AddChangeHook(ConVarChanged);

	cf_allowlan = CreateConVar(
		"cf_allowlan",
		"1",
		"Allow players connect from LAN, 0 = Disabled, 1 = Enabled\nIP 10.x.x.x\nIP 127.x.x.x\nIP 169.254.x.x\nIP 192.168.x.x\nIP 172.16.x.x - 172.31.x.x",
		FCVAR_NONE,
		true,
		0.0,
		true,
		1.0
	);

	g_allowlan = cf_allowlan.BoolValue;
	cf_allowlan.AddChangeHook(ConVarChanged);

	cf_allowunidentified = CreateConVar(
		"cf_allowunidentified",
		"0",
		"Allow players connect from unidentified country, 0 = Disabled, 1 = Enabled",
		FCVAR_NONE,
		true,
		0.0,
		true,
		1.0
	);

	g_allowunidentified = cf_allowunidentified.BoolValue;
	cf_allowunidentified.AddChangeHook(ConVarChanged);

	cf_chatannouncements = CreateConVar(
		"cf_chatannouncements",
		"3",
		"Print chat announcements to all players\nUsage 1+2 = 3 (Print allowed and rejected country connections)\n0 = Off\n1 = Allowed connections\n2 = Rejected connections\n4 = Allowed LAN connections\n8 = Rejected LAN connections",
		FCVAR_NONE,
		true,
		0.0,
		true,
		15.0
	);

	g_chatannouncements = cf_chatannouncements.IntValue;
	cf_chatannouncements.AddChangeHook(ConVarChanged);

	AutoExecConfig(true, "country_filter_2nd_edition");
}

public void ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (convar == cf_mode)
	{
		g_mode = (StringToInt(newValue) == 1);
	}
	else if (convar == cf_alphacode)
	{
		g_alphacode = (StringToInt(newValue) == 2);
	}
	else if (convar == cf_chatusecode)
	{
		g_chatusecode = (StringToInt(newValue) == 1);
	}
	else if (convar == cf_adminimmunity)
	{
		g_adminimmunity = (StringToInt(newValue) == 1);
	}
	else if (convar == cf_allowlan)
	{
		g_allowlan = (StringToInt(newValue) == 1);
	}
	else if (convar == cf_allowunidentified)
	{
		g_allowunidentified = (StringToInt(newValue) == 1);
	}
	else if (convar == cf_chatannouncements)
	{
		g_chatannouncements = StringToInt(newValue);
	}
}

public void OnClientConnected(int client)
{
	if (!g_adminimmunity && !IsFakeClient(client))
	{
		CheckConnection(client);
	}
}

public void OnClientPostAdminCheck(int client)
{
	if (
		g_adminimmunity &&
		!IsFakeClient(client) &&
		!CheckCommandAccess(client, "cf_immunity", ADMFLAG_RESERVATION)
	)
	{
		CheckConnection(client);
	}
}

void CheckConnection(int client)
{
	char IP[16];
	GetClientIP(client, IP, sizeof(IP));

	if (StrEqual(IP, "loopback"))
	{
		return;
	}

	char CODE[4];
	bool found = false;

	if (g_alphacode)
	{
		char code2[3];

		found = GeoipCode2(IP, code2);

		strcopy(CODE, sizeof(CODE), code2);
	}
	else
	{
		found = GeoipCode3(IP, CODE);
	}

	if (found)
	{
		char str[257];
		char expcodes[64][4];

		cf_countries.GetString(str, sizeof(str));

		bool reject = g_mode;

		if (str[0] != '\0')
		{
			int total = ExplodeString(str, " ", expcodes, 64, 4);

			for (int i = 0; i < total; i++)
			{
				if (StrEqual(CODE, expcodes[i]))
				{
					reject = g_mode ? false : true;
					break;
				}
			}
		}

		char countryname[45];
		GeoipCountry(IP, countryname, sizeof(countryname));

		if (reject)
		{
			if (g_chatannouncements & 2)
			{
				PrintToChatAll(
					"%t",
					"Country not allowed join",
					client,
					g_chatusecode ? CODE : countryname
				);
			}

			KickClient(
				client,
				"%t",
				"Country not allowed join kick",
				countryname
			);
		}
		else
		{
			if (g_chatannouncements & 1)
			{
				PrintToChatAll(
					"%t",
					"Country allowed join",
					client,
					g_chatusecode ? CODE : countryname
				);
			}
		}
	}
	else
	{
		bool islan = false;

		char expip[4][16];
		ExplodeString(IP, ".", expip, sizeof(expip), sizeof(expip[]));

		int ip1st = StringToInt(expip[0]);
		int ip2nd = StringToInt(expip[1]);

		if (ip1st == 10 || ip1st == 127)
		{
			islan = true;
		}
		else if (
			(ip1st == 192 && ip2nd == 168) ||
			(ip1st == 169 && ip2nd == 254)
		)
		{
			islan = true;
		}
		else if (ip1st == 172 && ip2nd >= 16 && ip2nd <= 31)
		{
			islan = true;
		}

		if (islan)
		{
			if (!g_allowlan)
			{
				if (g_chatannouncements & 8)
				{
					PrintToChatAll(
						"%t",
						"LAN not allowed join",
						client,
						IP
					);
				}

				KickClient(
					client,
					"%t",
					"LAN not allowed join kick",
					IP
				);
			}
			else
			{
				if (g_chatannouncements & 4)
				{
					PrintToChatAll(
						"%t",
						"LAN allowed join",
						client,
						IP
					);
				}
			}
		}
		else
		{
			if (!g_allowunidentified)
			{
				if (g_chatannouncements & 2)
				{
					PrintToChatAll(
						"%t",
						"Unidentified not allowed join",
						client
					);
				}

				KickClient(
					client,
					"%t",
					"Unidentified not allowed join kick"
				);
			}
			else
			{
				if (g_chatannouncements & 1)
				{
					PrintToChatAll(
						"%t",
						"Unidentified allowed join",
						client
					);
				}
			}
		}
	}
}