/*	=============================================
*	- NAME:
*	  + FF HUD Clock
*
*	- DESCRIPTION:
*	  + This plugin adds a digital clock to the clients hud.
*	  + 
*	  + The server admin can change the clock from 12 to 24 hour
*	  + format, and change the timezone offset.
*
* 	
*	-------------
*	Server cvars:
*	-------------
*	- sv_clockoffset <timezone offset>
*	 + Set the servers timezone offset (does not use daylight savings time).
*	
*	- sv_clocktype <12 or 24>
*	 + Set if the clock should be in 12 or 24 hour format.
*	
* 	
*	-------------
*	Client commands:
*	-------------
*	- say /settime
*	 + Lets players change their personal clock time offset and hour format.
*	
* 	
*	----------
*	Changelog:
*	----------
*	Version 1.0 ( 07-14-2008 )
*	-- Initial release.
*	
*	Version 1.1 ( 09-11-2008 )
*	-- Added country time offset checking.
*	-- Added method for players to set their own time offset and hour format.
* 	-- Added message on players first spawn that tells how to change their personal clock.
*	-- Changed the size of the clock to be a bit smaller.
*	
*	Version 1.2 ( 12-07-2008 )
*	-- Changed how players time is loaded.
*	-- Fixed the hud images for the latest FF update.
*	-- Fixed so players can use the 0 offset for GMT time.
*	
*	Version 1.3 ( 03-05-2009 )
*	-- Added color to the connect information message.
* 	
*/

#include <sourcemod>
#include <sdktools_stringtables>
#include <geoip>

#define FILE_PREFIX		"clock_d"
#define COLON_NAME		"clock_dcolon"
#define CLOCK_WIDTH		9
#define CLOCK_HEIGHT	9
#define COLON_WIDTH		7
#define CLOCK_XOFFSET	125
#define CLOCK_YOFFSET	3
#define CLOCK_SPACER	2

#define MAX_PLAYERS		22
new g_iOldLeftHour[MAX_PLAYERS+1], g_iOldRightHour[MAX_PLAYERS+1];
new g_iOldLeftMinute[MAX_PLAYERS+1], g_iOldRightMinute[MAX_PLAYERS+1];
new Handle:g_hClockOffset = INVALID_HANDLE;
new Handle:g_hClockType = INVALID_HANDLE;
new g_iMaxPlayers;
new g_iPlayerTimeZone[MAX_PLAYERS+1];
new g_iPlayerHourFormat[MAX_PLAYERS+1];
new g_iHasSpawned[MAX_PLAYERS+1];

#define VERSION "1.3"
public Plugin:myinfo = 
{
	name = "FF Hud Clock",
	author = "hlstriker",
	description = "Displays a clock on the clients hud",
	version = VERSION,
	url = "None"
}

public OnPluginStart()
{
	CreateConVar("sv_ffhudclockver", VERSION, "The version of FFHudClock.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	HookEvent("player_spawn", hook_spawn, EventHookMode_Post);
	RegConsoleCmd("say", hook_say);
}

public OnMapStart()
{
	g_iMaxPlayers = GetMaxClients();
	g_hClockOffset = CreateConVar("sv_clockoffset", "-4.0");
	g_hClockType = CreateConVar("sv_clocktype", "12.0");
	
	new String:szBuffer[32];
	Format(szBuffer, sizeof(szBuffer), "materials/vgui/%s.vtf", COLON_NAME);
	if(FileExists(szBuffer))
		AddFileToDownloadsTable(szBuffer);
	Format(szBuffer, sizeof(szBuffer), "materials/vgui/%s.vmt", COLON_NAME);
	if(FileExists(szBuffer))
		AddFileToDownloadsTable(szBuffer);
	
	for(new i=0; i<=9; i++)
	{
		Format(szBuffer, sizeof(szBuffer), "materials/vgui/%s%i.vtf", FILE_PREFIX, i);
		if(FileExists(szBuffer))
			AddFileToDownloadsTable(szBuffer);
		Format(szBuffer, sizeof(szBuffer), "materials/vgui/%s%i.vmt", FILE_PREFIX, i);
		if(FileExists(szBuffer))
			AddFileToDownloadsTable(szBuffer);
	}
}

public OnClientAuthorized(iClient, const String:szAuthID[])
{
	g_iHasSpawned[iClient] = false;
	
	// Check if players steam id is saved in info buffer
	new String:szOffset[16], String:szHour[16];
	GetClientInfo(iClient, "cl_team", szOffset, sizeof(szOffset));
	GetClientInfo(iClient, "cl_class", szHour, sizeof(szHour));
	
	if(!StrEqual(szOffset, "default", false))
		g_iPlayerTimeZone[iClient] = StringToInt(szOffset);
	else
		g_iPlayerTimeZone[iClient] = get_country_offset(iClient);
	
	if(!StrEqual(szHour, "default", false))
		g_iPlayerHourFormat[iClient] = StringToInt(szHour);
	else
		g_iPlayerHourFormat[iClient] = GetConVarInt(g_hClockType);
}

public Action:hook_say(iClient, iArgs)
{
	decl String:szArg1[48];
	GetCmdArg(1, szArg1, sizeof(szArg1)-1);
	
	if(szArg1[0] != '/')
		return Plugin_Continue;
	
	if(StrContains(szArg1, "/settime", false) != -1)
	{
		new String:szSplit[3][24];
		static iTimeZone, iHourFormat;
		ExplodeString(szArg1, " ", szSplit, sizeof(szSplit), sizeof(szSplit[]));
		
		iTimeZone = StringToInt(szSplit[1]);
		
		if(!(iHourFormat = StringToInt(szSplit[2])))
		{
			PrintToChat(iClient, "[Error] Usage: /settime TimeOffset HourFormat[12-24]");
			PrintToChat(iClient, "[Error] Example: /settime -4 12");
			return Plugin_Handled;
		}
		
		if(iTimeZone < -12 || iTimeZone > 14)
		{
			PrintToChat(iClient, "[Error] Invalid time offset.");
			return Plugin_Handled;
		}
		
		if(iHourFormat > 15)
			iHourFormat = 24;
		else
			iHourFormat = 12;
		
		g_iPlayerHourFormat[iClient] = iHourFormat;
		g_iPlayerTimeZone[iClient] = iTimeZone;
		
		PrintToChat(iClient, "Your time offset is now [%i] and your hour format is [%i].", iTimeZone, iHourFormat);
		
		UpdateTime(iClient, true);
		
		// Save the clients time to their setinfo
		ClientCommand(iClient, "cl_team %i", iTimeZone);
		ClientCommand(iClient, "cl_class %i", iHourFormat);
		
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action:hook_spawn(Handle:handle_event, const String:szEventName[], bool:isDontBroadcast)
{
	static iUserID;
	
	iUserID = GetClientOfUserId(GetEventInt(handle_event, "userid"));
	UpdateTime(iUserID, true);
	
	if(!g_iHasSpawned[iUserID])
	{
		SayText("^5[Clock] ^7If your time is wrong; say ^3'/settime' ^7to change it.", 1, iUserID);
		g_iHasSpawned[iUserID] = true;
	}
	
	return Plugin_Continue;
}

public OnConfigsExecuted()
	CreateTimer(15.0, timer_CheckTime, 0, TIMER_REPEAT);

public Action:timer_CheckTime(Handle:hTimer)
{
	for(new i=1; i<=g_iMaxPlayers; i++)
	{
		if(IsClientInGame(i))
			UpdateTime(i, false);
	}
}

public UpdateTime(const iClient, const bool:mOnSpawn)
{
	static iHour, iMinute, iSecond, String:szTemp[3], String:szTemp2[2];
	static iLeftHour, iRightHour, iLeftMinute, iRightMinute;
	static String:szString[24], Handle:hBf, iXPos;
	
	iSecond = GetTime() + (3600 * g_iPlayerTimeZone[iClient]);
	iMinute = iSecond / 60;
	iHour   = (iMinute / 60) % 24;
	iMinute = iMinute % 60;
	iSecond = iSecond % 60;
	
	if(g_iPlayerHourFormat[iClient] == 12 && iHour > 12)
	{
		switch(iHour)
		{
			case 13: iHour = 1;
			case 14: iHour = 2;
			case 15: iHour = 3;
			case 16: iHour = 4;
			case 17: iHour = 5;
			case 18: iHour = 6;
			case 19: iHour = 7;
			case 20: iHour = 8;
			case 21: iHour = 9;
			case 22: iHour = 10;
			case 23: iHour = 11;
			case 24: iHour = 12;
		}
	}
	else if(g_iPlayerHourFormat[iClient] == 12 && iHour == 0)
		iHour = 12;
	
	IntToString(iHour, szTemp, sizeof(szTemp));
	szTemp2[0] = szTemp[0];
	iLeftHour = StringToInt(szTemp2);
	szTemp2[0] = szTemp[1];
	iRightHour = StringToInt(szTemp2);
	
	if(iHour < 10)
	{
		iSecond = iRightHour;
		iRightHour = iLeftHour;
		iLeftHour = iSecond;
	}
	
	IntToString(iMinute, szTemp, sizeof(szTemp));
	szTemp2[0] = szTemp[0];
	iLeftMinute = StringToInt(szTemp2);
	szTemp2[0] = szTemp[1];
	iRightMinute = StringToInt(szTemp2);
	
	if(iMinute < 10)
	{
		iSecond = iRightMinute;
		iRightMinute = iLeftMinute;
		iLeftMinute = iSecond;
	}
	
	if(mOnSpawn)
	{
		hBf = StartMessageOne("FF_HudLua", iClient);
		BfWriteString(hBf, "0x03hour0");
		EndMessage();
		
		hBf = StartMessageOne("FF_HudLua", iClient);
		BfWriteString(hBf, "0x03hour1");
		EndMessage();
		
		hBf = StartMessageOne("FF_HudLua", iClient);
		BfWriteString(hBf, "0x03colon");
		EndMessage();
		
		hBf = StartMessageOne("FF_HudLua", iClient);
		BfWriteString(hBf, "0x03minute0");
		EndMessage();
		
		hBf = StartMessageOne("FF_HudLua", iClient);
		BfWriteString(hBf, "0x03minute1");
		EndMessage();
	}
	
	// In 2.1 they made the right allignment backwards?
	// Now we have to set the clock in reverse order...
	
	iXPos = CLOCK_XOFFSET;
	if(iRightMinute != g_iOldRightMinute[iClient] || mOnSpawn)
	{
		FormatEx(szString, sizeof(szString), "%s%i.vmt", FILE_PREFIX, iRightMinute);
		hBf = StartMessageOne("FF_HudLua", iClient);
		BfWriteString(hBf, "");
		BfWriteString(hBf, "minute1");
		BfWriteShort(hBf, iXPos);
		BfWriteShort(hBf, CLOCK_YOFFSET);
		BfWriteString(hBf, szString);
		BfWriteShort(hBf, CLOCK_WIDTH);
		BfWriteShort(hBf, CLOCK_HEIGHT);
		BfWriteShort(hBf, 3);
		EndMessage();
	}
	
	iXPos += CLOCK_WIDTH + CLOCK_SPACER;
	if(iLeftMinute != g_iOldLeftMinute[iClient] || mOnSpawn)
	{
		FormatEx(szString, sizeof(szString), "%s%i.vmt", FILE_PREFIX, iLeftMinute);
		hBf = StartMessageOne("FF_HudLua", iClient);
		BfWriteString(hBf, "");
		BfWriteString(hBf, "minute0");
		BfWriteShort(hBf, iXPos);
		BfWriteShort(hBf, CLOCK_YOFFSET);
		BfWriteString(hBf, szString);
		BfWriteShort(hBf, CLOCK_WIDTH);
		BfWriteShort(hBf, CLOCK_HEIGHT);
		BfWriteShort(hBf, 3);
		EndMessage();
	}
	
	iXPos += CLOCK_WIDTH + CLOCK_SPACER - 1;
	if(mOnSpawn)
	{
		FormatEx(szString, sizeof(szString), "%s.vmt", COLON_NAME);
		hBf = StartMessageOne("FF_HudLua", iClient);
		BfWriteString(hBf, "");
		BfWriteString(hBf, "colon");
		BfWriteShort(hBf, iXPos);
		BfWriteShort(hBf, CLOCK_YOFFSET);
		BfWriteString(hBf, szString);
		BfWriteShort(hBf, COLON_WIDTH);
		BfWriteShort(hBf, CLOCK_HEIGHT);
		BfWriteShort(hBf, 3);
		EndMessage();
	}
	
	iXPos += COLON_WIDTH + CLOCK_SPACER - 1;
	if(iRightHour != g_iOldRightHour[iClient] || mOnSpawn)
	{
		FormatEx(szString, sizeof(szString), "%s%i.vmt", FILE_PREFIX, iRightHour);
		hBf = StartMessageOne("FF_HudLua", iClient);
		BfWriteString(hBf, "");
		BfWriteString(hBf, "hour1");
		BfWriteShort(hBf, iXPos);
		BfWriteShort(hBf, CLOCK_YOFFSET);
		BfWriteString(hBf, szString);
		BfWriteShort(hBf, CLOCK_WIDTH);
		BfWriteShort(hBf, CLOCK_HEIGHT);
		BfWriteShort(hBf, 3);
		EndMessage();
	}
	
	iXPos += CLOCK_WIDTH + CLOCK_SPACER;
	if(iLeftHour != g_iOldLeftHour[iClient] || mOnSpawn)
	{
		FormatEx(szString, sizeof(szString), "%s%i.vmt", FILE_PREFIX, iLeftHour);
		hBf = StartMessageOne("FF_HudLua", iClient);
		BfWriteString(hBf, "");
		BfWriteString(hBf, "hour0");
		BfWriteShort(hBf, iXPos);
		BfWriteShort(hBf, CLOCK_YOFFSET);
		BfWriteString(hBf, szString);
		BfWriteShort(hBf, CLOCK_WIDTH);
		BfWriteShort(hBf, CLOCK_HEIGHT);
		BfWriteShort(hBf, 3);
		EndMessage();
	}
	
	g_iOldLeftHour[iClient] = iLeftHour;
	g_iOldRightHour[iClient] = iRightHour;
	g_iOldLeftMinute[iClient] = iLeftMinute;
	g_iOldRightMinute[iClient] = iRightMinute;
}

stock get_country_offset(iClient)
{
	new String:szIP[16], String:szCode[3], iOffset;
	GetClientIP(iClient, szIP, sizeof(szIP));
	GeoipCode2(szIP, szCode);
	
	if(StrEqual(szCode, "US")) // United States
		iOffset = -4;
	else if(StrEqual(szCode, "CA")) // Canada
		iOffset = -5;
	else if(StrEqual(szCode, "AL")) // Albania
		iOffset = 2;
	else if(StrEqual(szCode, "AR")) // Argentina
		iOffset = -3;
	else if(StrEqual(szCode, "AU")) // Australia
		iOffset = 10;
	else if(StrEqual(szCode, "BH")) // Bahrain
		iOffset = 3;
	else if(StrEqual(szCode, "BE")) // Belgium
		iOffset = 1;
	else if(StrEqual(szCode, "BO")) // Bolivia
		iOffset = -4;
	else if(StrEqual(szCode, "BG")) // Bulgaria
		iOffset = 2;
	else if(StrEqual(szCode, "CM")) // Cameroon
		iOffset = 1;
	else if(StrEqual(szCode, "CN")) // China
		iOffset = 8;
	else if(StrEqual(szCode, "CR")) // Costa Rica
		iOffset = -6;
	else if(StrEqual(szCode, "CZ")) // Czech Republic
		iOffset = 1;
	else if(StrEqual(szCode, "EG")) // Egypt
		iOffset = 2;
	else if(StrEqual(szCode, "EE")) // Estonia
		iOffset = 2;
	else if(StrEqual(szCode, "FI")) // Finland
		iOffset = 2;
	else if(StrEqual(szCode, "PF")) // French Polynesia (Tahiti)
		iOffset = -10;
	else if(StrEqual(szCode, "GI")) // Gibraltar
		iOffset = 1;
	else if(StrEqual(szCode, "HN")) // Honduras
		iOffset = -6;
	else if(StrEqual(szCode, "IS")) // Iceland
		iOffset = 0;
	else if(StrEqual(szCode, "IR")) // Iran
		iOffset = 4;
	else if(StrEqual(szCode, "IL")) // Israel
		iOffset = 2;
	else if(StrEqual(szCode, "JP")) // Japan
		iOffset = 9;
	else if(StrEqual(szCode, "KP") || StrEqual(szCode, "KR")) // Korea (N. and S.)
		iOffset = 9;
	else if(StrEqual(szCode, "LV")) // Latvia
		iOffset = 2;
	else if(StrEqual(szCode, "LY")) // Libya
		iOffset = 1;
	else if(StrEqual(szCode, "LU")) // Luxembourg
		iOffset = 1;
	else if(StrEqual(szCode, "MW")) // Malawi
		iOffset = 2;
	else if(StrEqual(szCode, "MX")) // Mexico
		iOffset = 6;
	else if(StrEqual(szCode, "MZ")) // Mozambique
		iOffset = 2;
	else if(StrEqual(szCode, "NP")) // Nepal
		iOffset = 6;
	else if(StrEqual(szCode, "NZ")) // New Zealand (Aotearoa)
		iOffset = -12;
	else if(StrEqual(szCode, "NO")) // Norway
		iOffset = 1;
	else if(StrEqual(szCode, "PA")) // Panama
		iOffset = -5;
	else if(StrEqual(szCode, "PH")) // Philippines
		iOffset = 8;
	else if(StrEqual(szCode, "RO")) // Romania
		iOffset = 2;
	else if(StrEqual(szCode, "SN")) // Senegal
		iOffset = 0;
	else if(StrEqual(szCode, "SI")) // Slovenia
		iOffset = 1;
	else if(StrEqual(szCode, "LK")) // Sri Lanka
		iOffset = 6;
	else if(StrEqual(szCode, "CH")) // Switzerland
		iOffset = 1;
	else if(StrEqual(szCode, "TZ")) // Tanzania
		iOffset = 3;
	else if(StrEqual(szCode, "TR")) // Turkey
		iOffset = 2;
	else if(StrEqual(szCode, "AE")) // United Arab Emirates
		iOffset = 4;
	else if(StrEqual(szCode, "VA")) // Vatican City State (Holy See)
		iOffset = 1;
	else if(StrEqual(szCode, "YE")) // Yemen
		iOffset = 3;
	else if(StrEqual(szCode, "ZM")) // Zambia
		iOffset = 2;
	else if(StrEqual(szCode, "DZ")) // Algeria
		iOffset = 1;
	else if(StrEqual(szCode, "AM")) // Armenia
		iOffset = 3;
	else if(StrEqual(szCode, "AT")) // Austria
		iOffset = 1;
	else if(StrEqual(szCode, "BD")) // Bangladesh
		iOffset = 6;
	else if(StrEqual(szCode, "BZ")) // Belize
		iOffset = -6
	else if(StrEqual(szCode, "BA")) // Bosnia and Herzegovina
		iOffset = 1;
	else if(StrEqual(szCode, "BI")) // Burundi
		iOffset = 2;
	else if(StrEqual(szCode, "CF")) // Central African Republic
		iOffset = 1;
	else if(StrEqual(szCode, "CO")) // Colombia
		iOffset = -5;
	else if(StrEqual(szCode, "HR")) // Croatia (Hrvatska)
		iOffset = 1;
	else if(StrEqual(szCode, "DK")) // Denmark
		iOffset = 1;
	else if(StrEqual(szCode, "SV")) // El Salvador
		iOffset = -6;
	else if(StrEqual(szCode, "ET")) // Ethiopia
		iOffset = 3;
	else if(StrEqual(szCode, "FR")) // France
		iOffset = 1;
	else if(StrEqual(szCode, "GE")) // Georgia
		iOffset = 3;
	else if(StrEqual(szCode, "GR")) // Greece
		iOffset = 2;
	else if(StrEqual(szCode, "GT")) // Guatemala
		iOffset = -6;
	else if(StrEqual(szCode, "HK")) // Hong Kong
		iOffset = 8;
	else if(StrEqual(szCode, "IN")) // India
		iOffset = 6;
	else if(StrEqual(szCode, "IQ")) // Iraq
		iOffset = 3;
	else if(StrEqual(szCode, "IT")) // Italy
		iOffset = 1;
	else if(StrEqual(szCode, "JO")) // Jordan
		iOffset = 2;
	else if(StrEqual(szCode, "KW")) // Kuwait
		iOffset = 3;
	else if(StrEqual(szCode, "LB")) // Lebanon
		iOffset = 2;
	else if(StrEqual(szCode, "LI")) // Liechtenstein
		iOffset = 1;
	else if(StrEqual(szCode, "MO")) // Macau
		iOffset = 8;
	else if(StrEqual(szCode, "MY")) // Malaysia
		iOffset = 8;
	else if(StrEqual(szCode, "MC")) // Monaco
		iOffset = 1;
	else if(StrEqual(szCode, "MM")) // Myanmar
		iOffset = 7;
	else if(StrEqual(szCode, "NL")) // Netherlands
		iOffset = 1;
	else if(StrEqual(szCode, "NI")) // Nicaragua
		iOffset = -6;
	else if(StrEqual(szCode, "OM")) // Oman
		iOffset = 4;
	else if(StrEqual(szCode, "PY")) // Paraguay
		iOffset = -3;
	else if(StrEqual(szCode, "PL")) // Poland
		iOffset = 1;
	else if(StrEqual(szCode, "RU")) // Russian Federation
		iOffset = 3;
	else if(StrEqual(szCode, "SG")) // Singapore
		iOffset = 8;
	else if(StrEqual(szCode, "ZA")) // South Africa
		iOffset = 2;
	else if(StrEqual(szCode, "SR")) // Suriname
		iOffset = -3;
	else if(StrEqual(szCode, "SY")) // Syria
		iOffset = 3;
	else if(StrEqual(szCode, "TH")) // Thailand
		iOffset = 7;
	else if(StrEqual(szCode, "UG")) // Uganda
		iOffset = 3;
	else if(StrEqual(szCode, "UK")) // United Kingdom
		iOffset = 0;
	else if(StrEqual(szCode, "VE")) // Venezuela
		iOffset = -4;
	else if(StrEqual(szCode, "YU")) // Yugoslavia
		iOffset = 1;
	else if(StrEqual(szCode, "ZW")) // Zimbabwe
		iOffset = 2;
	else if(StrEqual(szCode, "AO")) // Angola
		iOffset = 1;
	else if(StrEqual(szCode, "AW")) // Aruba
		iOffset = -4;
	else if(StrEqual(szCode, "AZ")) // Azerbaijan
		iOffset = 3;
	else if(StrEqual(szCode, "BY")) // Belarus
		iOffset = 3;
	else if(StrEqual(szCode, "BJ")) // Benin
		iOffset = 1;
	else if(StrEqual(szCode, "BR")) // Brazil
		iOffset = -3;
	else if(StrEqual(szCode, "KH")) // Cambodia
		iOffset = 7;
	else if(StrEqual(szCode, "CL")) // Chile
		iOffset = -4;
	else if(StrEqual(szCode, "CG")) // Congo
		iOffset = 1;
	else if(StrEqual(szCode, "CY")) // Cyprus
		iOffset = 2;
	else if(StrEqual(szCode, "EC")) // Ecuador
		iOffset = -5;
	else if(StrEqual(szCode, "ER")) // Eritrea
		iOffset = 3;
	else if(StrEqual(szCode, "FJ")) // Fiji
		iOffset = -12;
	else if(StrEqual(szCode, "DE")) // Germany
		iOffset = 1;
	else if(StrEqual(szCode, "GU")) // Guam
		iOffset = -10;
	else if(StrEqual(szCode, "HT")) // Haiti
		iOffset = -5;
	else if(StrEqual(szCode, "HU")) // Hungary
		iOffset = 1;
	else if(StrEqual(szCode, "ID")) // Indonesia
		iOffset = 7;
	else if(StrEqual(szCode, "IE")) // Ireland
		iOffset = 0;
	else if(StrEqual(szCode, "CI")) // Cote D'Ivoire (Ivory Coast)
		iOffset = 0;
	else if(StrEqual(szCode, "KE")) // Kenya
		iOffset = 3;
	else if(StrEqual(szCode, "LA")) // Laos
		iOffset = 7;
	else if(StrEqual(szCode, "LR")) // Liberia
		iOffset = 0;
	else if(StrEqual(szCode, "LT")) // Lithuania
		iOffset = 2;
	else if(StrEqual(szCode, "MK")) // F.Y.R.O.M. (Macedonia)
		iOffset = 2;
	else if(StrEqual(szCode, "MT")) // Malta
		iOffset = 1;
	else if(StrEqual(szCode, "MA")) // Morocco
		iOffset = 1;
	else if(StrEqual(szCode, "NA")) // Namibia
		iOffset = 2;
	else if(StrEqual(szCode, "AN")) // Netherlands Antilles
		iOffset = -4;
	else if(StrEqual(szCode, "NG")) // Nigeria
		iOffset = 1;
	else if(StrEqual(szCode, "PK")) // Pakistan
		iOffset = 5;
	else if(StrEqual(szCode, "PE")) // Peru
		iOffset = -5;
	else if(StrEqual(szCode, "PT")) // Portugal
		iOffset = 1;
	else if(StrEqual(szCode, "SA")) // Saudi Arabia
		iOffset = 3;
	else if(StrEqual(szCode, "CS")) // Czechoslovakia
		iOffset = 1;
	else if(StrEqual(szCode, "ES")) // Spain
		iOffset = -1;
	else if(StrEqual(szCode, "SE")) // Sweden
		iOffset = 1;
	else if(StrEqual(szCode, "TW")) // Taiwan
		iOffset = 8;
	else if(StrEqual(szCode, "TN")) // Tunisia
		iOffset = 1;
	else if(StrEqual(szCode, "UA")) // Ukraine
		iOffset = 2;
	else if(StrEqual(szCode, "UY")) // Uruguay
		iOffset = -3;
	else if(StrEqual(szCode, "VN")) // Viet Nam
		iOffset = 7;
	else if(StrEqual(szCode, "ZR")) // Zaire
		iOffset = 1;
	else
		iOffset = GetConVarInt(g_hClockOffset);
	
	return iOffset;
}

stock SayText(const String:szText[], const iColor=1, const iClient=0)
{
	new String:szFormat[1024];
	FormatEx(szFormat, sizeof(szFormat)-1, "\x02%s\x0D\x0A", szText);
	
	new Handle:hBf;
	if(iClient <= 0)
		hBf = StartMessageAll("SayText");
	else
		hBf = StartMessageOne("SayText", iClient);
	BfWriteString(hBf, szFormat);
	BfWriteByte(hBf, iColor);
	EndMessage();
}