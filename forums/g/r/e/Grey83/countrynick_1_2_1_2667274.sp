/*
SourceMod Country Nick Plugin
Add country of the player near his nick
 
Country Nick Plugin (C)2009-2010 A-L. All rights reserved.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

$Id: countrynick.sp 29 2009-02-23 23:45:22Z aen0 $
 */

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <geoip>

#define NAME		"Country Nick"
#define VERSION	"1.2.1"

ConVar hTagSize, hMsg;
int iTagSize;
bool bMsg;

public Plugin myinfo = {
	name		= NAME,
	author		= "Antoine LIBERT aka AeN0 (rewrited by Grey83)",
	description	= "Add country of the player near his nick",
	version		= VERSION,
	url			= "https://forums.alliedmods.net/showthread.php?p=738756"
};

public void OnPluginStart()
{
	LoadTranslations("countrynick.phrases");

	CreateConVar("countrynick_version", VERSION, NAME, FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_SPONLY|FCVAR_DONTRECORD);
	hTagSize = CreateConVar("sm_countrynick_tagsize", "3", "Size of the country tag (2 or 3 letters)", FCVAR_NONE, true, 2.0, true, 3.0);
	hMsg = CreateConVar("sm_countrynick_msg", "0", "1/0 - Switch On/Off announcement connecting of a players (and error logging)", FCVAR_NONE, true, 0.0, true, 1.0);

	RegAdminCmd("list", Cmd_List, ADMFLAG_GENERIC, "Show info about players (Admin or  non-admin, UserID, IP, Country, SteamID, Nick) on the server");

	iTagSize = GetConVarInt(hTagSize);
	bMsg = GetConVarBool(hMsg);

	HookConVarChange(hTagSize, OnConVarChanged);
	HookConVarChange(hMsg, OnConVarChanged);

	HookEvent("player_changename", Event_PlayerChangename, EventHookMode_Pre);

	AutoExecConfig(true, "countrynick");
}

public void OnConVarChanged(Handle hCVar, const char[] oldValue, const char[] newValue)
{
	if (hCVar == hTagSize) iTagSize = StringToInt(newValue);
	else if (hCVar == hMsg) bMsg = view_as<bool>(StringToInt(newValue));
}

public Action Cmd_List(int client, int args)
{
	static char seperator[] = "--+-+---+-----------------+---------------+----+-------------------------------";
	PrintToConsole(client, "%s", seperator);
	PrintToConsole(client, " # A %-3.3s %-17.17s %-15.15s %-4.4s %s", "UID", "SteamID", "IP", "From", "Nick");
	PrintToConsole(client, "%s", seperator);

	int cAdmin;
	char sIP[16];
	char sSteamID[18];
	char sNick[29];
	char sCode[4];

	int iCount;
	for(int i=1; i<=MaxClients; i++)
	{
		if (!IsClientInGame(i)) continue;
		iCount++;
		cAdmin = GetUserAdmin(i) != INVALID_ADMIN_ID ? 'A' : '-';
		GetClientAuthId(i, AuthId_SteamID64, sSteamID, sizeof(sSteamID));
		GetClientIP(i, sIP, sizeof(sIP));
		if(!GeoipCode3(sIP, sCode)) sCode = "-?-";
		GetClientName(i, sNick, sizeof(sNick));
		PrintToConsole(client, "%2.2d %c %3.3d %-17.17s %-15.15s %-4.4s %-30.30s", iCount, cAdmin, GetClientUserId(i), sSteamID, sIP, sCode, sNick);
	}
	PrintToConsole(client, "%s", seperator);
}

public void OnClientPutInServer(int client)
{
	char ip[16];
	char country[45];
	char sName[65];

	if(1 <= client <= MaxClients && !IsFakeClient(client))
	{
		if(GetClientName(client, sName, sizeof(sName))) SetNewName(client, sName);

		if(bMsg)
		{
			GetClientIP(client, ip, sizeof(ip)); 
			if(GeoipCountry(ip, country, sizeof(country))) PrintToChatAll("\x03%T", "Announcer country found", LANG_SERVER, client, country);
			else
			{
				PrintToChatAll("\x03%T", "Announcer country not found", LANG_SERVER, client);
				LogError("[Country Nick] Warning : %N uses %s that is not listed in GEOIP database", client, ip);
			}
		}
	}
}

public Action Event_PlayerChangename(Event event, const char[] name, bool dontBroadcast)
{
	char sName[65];
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsFakeClient(client)) return Plugin_Continue;

	GetEventString(event, "newname", sName, sizeof(sName));
	SetNewName(client, sName);
	return Plugin_Changed; // avoid printing the change to the chat
}

void SetNewName(int client, char[] sName)
{
	char ip[16], code[4], flag[6];
	GetClientIP(client, ip, sizeof(ip));
	if(iTagSize == 2) Format(flag, sizeof(flag), "[%2s]", GeoipCode2(ip, code) ? code : "--");
	else Format(flag, sizeof(flag), "[%3s]", GeoipCode3(ip, code) ? code : "-?-");

	if(StrContains(sName, flag, false) != 0)
	{
		Format(sName, 69, "%s%s", flag, sName);
		SetClientInfo(client, "name", sName);
	}
}