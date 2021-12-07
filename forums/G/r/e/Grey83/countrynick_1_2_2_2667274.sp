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

#include <sdktools>
#include <geoip>

static const char	NAME[]		= "Country Nick",
					VERSION[]	= "1.2.2",
					seperator[]	= "--+-+---+-----------------+---------------+----+-------------------------------";

bool bLongTag,
	bMsg;

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

	ConVar CVar;
	(CVar = CreateConVar("sm_countrynick_tagsize", "1", "Size of the country tag ('0' = 2 letters, '1' = 3 letters)", _, true, _, true, 1.0)).AddChangeHook(CVarChanged_Size);
	bLongTag = CVar.BoolValue;

	(CVar = CreateConVar("sm_countrynick_msg", "1", "1/0 - Switch On/Off announcement connecting of a players (and error logging)", _, true, _, true, 1.0)).AddChangeHook(CVarChanged_Msg);
	bMsg = CVar.BoolValue;

	RegAdminCmd("list", Cmd_List, ADMFLAG_GENERIC, "Show info about players (Admin or  non-admin, UserID, IP, Country, SteamID, Nick) on the server");

	HookEvent("player_changename", Event_PlayerChangename, EventHookMode_Pre);

	AutoExecConfig(true, "countrynick");
}

public void CVarChanged_Size(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	if(bLongTag == (bLongTag = CVar.BoolValue)) return;

	char name[65];
	for(int i = 1; i <= MaxClients; i++) if(IsClientInGame(i) && !IsFakeClient(i) && GetClientName(i, name, sizeof(name)))
		SetNewName(i, name);
}

public void CVarChanged_Msg(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	bMsg = CVar.BoolValue;
}

public Action Cmd_List(int client, int args)
{
	PrintToConsole(client, seperator);
	PrintToConsole(client, " # A %-3.3s %-17.17s %-15.15s %-4.4s %s", "UID", "SteamID", "IP", "From", "Nick");
	PrintToConsole(client, seperator);

	bool bot, find;
	int cAdmin;
	char sIP[16], sSteamID[18], sNick[29], sCode[4];

	for(int i = 1, iCount; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i))
			continue;
		bot = IsFakeClient(i);

		iCount++;

		if(!bot)
		{
			cAdmin = GetUserAdmin(i) == INVALID_ADMIN_ID ? '-' : 'A';
			GetClientIP(i, sIP, sizeof(sIP));
			find = GeoipCode3(sIP, sCode);
			GetClientAuthId(i, AuthId_SteamID64, sSteamID, sizeof(sSteamID));
		}
		else
		{
			// Bot != INVALID_ADMIN_ID
			cAdmin = ' ';
			strcopy(sIP, 16, "Bot");
			find = true;
			sCode[0] = 0;
			// Bot == "STEAM_ID_STOP_IGN"
			sSteamID[0] = 0;
		}
		GetClientName(i, sNick, sizeof(sNick));
		PrintToConsole(client, "%2.2d %c %3.3d %-17.17s %-15.15s %-4.4s %-30.30s", iCount, cAdmin, GetClientUserId(i), sSteamID, sIP, find ? sCode : "-?-", sNick);
	}
	PrintToConsole(client, seperator);
}

public void OnClientPutInServer(int client)
{
	if(0 < client <= MaxClients && !IsFakeClient(client))
	{
		if(bMsg)
		{
			char ip[16], country[45];
			GetClientIP(client, ip, sizeof(ip)); 
			if(GeoipCountry(ip, country, sizeof(country)))
				PrintToChatAll("\x03%T", "Announcer country found", LANG_SERVER, client, country);
			else
			{
				PrintToChatAll("\x03%T", "Announcer country not found", LANG_SERVER, client);
				LogError("[Country Nick] Warning : %N uses %s that is not listed in GEOIP database", client, ip);
			}
		}

		char name[65];
		if(GetClientName(client, name, sizeof(name))) SetNewName(client, name);
	}
}

public Action Event_PlayerChangename(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsFakeClient(client))
		return Plugin_Continue;

	char new_name[65];
	GetEventString(event, "newname", new_name, sizeof(new_name));
	SetNewName(client, new_name);
	// avoid printing the change to the chat
	return Plugin_Changed;
}

stock void SetNewName(int client, char[] name)
{
	static char ip[16], code[4], flag[2][6];
	if(!GetClientIP(client, ip, sizeof(ip)))
		return;

	Format(flag[0], sizeof(flag[]), "[%2s]", GeoipCode2(ip, code) ? code : "--");
	ReplaceString(name, 69, flag[0], "");
	Format(flag[1], sizeof(flag[]), "[%3s]", GeoipCode3(ip, code) ? code : "-?-");
	ReplaceString(name, 69, flag[1], "");

	Format(name, 69, "%s%s", flag[view_as<int>(bLongTag)], name);
	SetClientInfo(client, "name", name);
}