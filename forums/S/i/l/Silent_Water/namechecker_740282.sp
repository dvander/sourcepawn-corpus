/************************************************
 * Name Checker
 *----------------------------------------------*
 * Author: silentspam2000@yahoo.de
 *----------------------------------------------*
 * Date: 07/20/2009
 *----------------------------------------------*
 * Credits:  Max Krivanek aka Kigen
 * used some code snippets
 * from his Anti-Cheat-Tool
 ************************************************

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

    **** DO NOT MODIFY THE ABOVE NOTICES PLEASE! (Unless just to note additions.) ****

*/

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.5"

new Handle:g_hPlugin;
new String:g_sNames[MAXPLAYERS+1][64];
new String:g_sInvalid[MAXPLAYERS+1][64];
new g_iChanges[MAXPLAYERS+1] = {0, ...};
new g_iMaxPlayers = MAXPLAYERS;
new Handle:g_hCVarChangeCount = INVALID_HANDLE;
new Handle:g_hCVarCopySize = INVALID_HANDLE;
new Handle:g_hCVarCopyDiff = INVALID_HANDLE;
new Handle:g_hCVarChangeAction = INVALID_HANDLE;
new Handle:g_hCVarCheckAction = INVALID_HANDLE;
new Handle:g_hCVarBanTime = INVALID_HANDLE;
new Handle:g_hCVarSpecialChars = INVALID_HANDLE;
new Handle:g_hCVarMultiByte = INVALID_HANDLE;
new Handle:g_hBadNameList = INVALID_HANDLE;
new Handle:g_hCVarMinSize = INVALID_HANDLE;
new Handle:g_hCVarMaxSize = INVALID_HANDLE;
new Handle:g_hCVarTellDetails = INVALID_HANDLE;
new String:g_sDetails[][] = {
	"OK",
	"name is too short", // 1
	"name is too long", // 2
	"name contains control chars", // 3
	"name contains quotes", // 4
	"name has too many special chars", // 5
	"name has too many special chars", // 6
	"name has too many non-latin chars", // 7
	"name is too similar to another on this server", // 8
	"name contains '{INVALID}' which is not allowed" // 9
};


public Plugin:myinfo =
{
    name = "Name Checker",
    author = "Silent_Water",
    description = "Stops players from doing bad things with their names",
    version = PLUGIN_VERSION,
    url = "http://www.crazy-platoon.de/"
};

public OnPluginStart()
{
	g_hPlugin = GetMyHandle();
	g_iMaxPlayers = GetMaxClients();
	if ( !HookEventEx("player_changename", EventNameChange, EventHookMode_Pre) )
		LogError("Unable to hook player_changename");

	CreateConVar("sm_name_checker", PLUGIN_VERSION, "Name Checker version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_hCVarChangeCount = CreateConVar("sm_name_change_count", "4", "Blocks name changes more than x times per map", 0, true, 1.0, true, 100.0);
	g_hCVarCopySize = CreateConVar("sm_name_copy_size", "16", "The first x characters of the name must be unique", 0, true, 3.0, true, 63.0);
	g_hCVarCopyDiff = CreateConVar("sm_name_copy_diff", "2", "How many characters must be different at least (0 = disable)", 0, true, 0.0, true, 63.0);
	g_hCVarBanTime = CreateConVar("sm_name_ban_time", "5", "How long should be banned - in minutes (0 = permanent)", 0, true, 0.0, true, 43200.0);
	g_hCVarSpecialChars = CreateConVar("sm_name_special_chars", "16", "How many special characters (not readable) are allowed", 0, true, 0.0, true, 63.0);
	g_hCVarMultiByte = CreateConVar("sm_name_multi_byte", "31", "How many multi-byte characters (arabian, chinese, ...) are allowed", 0, true, 0.0, true, 31.0);
	g_hCVarChangeAction = CreateConVar("sm_name_change_action", "kick", "What action is to be done if a player changes his name to often? (deny|kick|ban)");
	g_hCVarCheckAction = CreateConVar("sm_name_invalid_action", "kick", "What action is to be done if a player has an invalid name? (deny|kick|ban)");
	g_hCVarTellDetails = CreateConVar("sm_name_tell_details", "1", "Tell the player the detailled reason (1 = yes|0=no)", 0, true, 0.0, true, 1.0);
	g_hCVarMinSize = CreateConVar("sm_name_min_size", "1", "Minimum required length of a name", 0, true, 1.0, true, 63.0);
	g_hCVarMaxSize = CreateConVar("sm_name_max_size", "63", "Maximum allowed length of a name", 0, true, 1.0, true, 63.0);
	AutoExecConfig(true, "namechecker");
	ReadBadNames();
}

public OnPluginEnd()
{
	new maxclients = GetMaxClients();
	for(new i=1;i<maxclients;i++)
		g_iChanges[i] = 0;
}

public OnMapEnd()
{
	new maxclients = GetMaxClients();
	for(new i=1;i<maxclients;i++)
		g_iChanges[i] = 0;
}

public OnMapStart()
{
	new maxclients = GetMaxClients();
	for(new i=1;i<maxclients;i++)
		g_iChanges[i] = 0;
}

public bool:OnClientConnect(client, String:rejectmsg[], maxlen)
{
	new result = 0;
	decl String:sAction[10];
	GetConVarString(g_hCVarCheckAction, sAction, sizeof(sAction));

	if ( IsFakeClient(client) )
	{
		return true;
	}
	decl String:name[64];
	GetClientName(client, name, sizeof(name));
	if ( (result = CheckName(client,name)) != 0 )
	{
		if (strcmp(sAction,"ban")==0) {
			CreateTimer(1.0, Timed_Ban, (client << 8)|result, TIMER_FLAG_NO_MAPCHANGE);
		} else if (strcmp(sAction,"kick")==0) {
			CreateTimer(0.2, Timed_Kick, (client << 8)|result, TIMER_FLAG_NO_MAPCHANGE);
		} else {
			return false; // deny connection :)
		}
	}
	strcopy(g_sNames[client][0],64,name);
	return true;
}

public OnClientDisconnect(client)
{
	g_iChanges[client] = 0;
	g_sNames[client][0] = '\0';
}

ReadBadNames()
{
	new Handle:fh = INVALID_HANDLE;
	new iArraySize = ByteCountToCells(64);
	decl String:sBadNamesFile[PLATFORM_MAX_PATH];
	decl String:sLine[64];

	g_hBadNameList = CreateArray(iArraySize);

	BuildPath(Path_SM, sBadNamesFile, sizeof(sBadNamesFile), "configs/badnames.txt");

	fh = OpenFile(sBadNamesFile, "rt");

	if (fh == INVALID_HANDLE)
	{
		// if file does not exist create one with default value "unnamed"
		fh = OpenFile(sBadNamesFile, "a+t");
		if ( (fh == INVALID_HANDLE) || (!WriteFileLine(fh, "%s", "unnamed") && CloseHandle(fh)) ) {
			LogError("Could not open file \"%s\"", sBadNamesFile);
			return false;
		}
	}
	FileSeek(fh, 0, SEEK_SET);
	while ( (!IsEndOfFile(fh)) && (ReadFileLine(fh, sLine, sizeof(sLine))) )
	{
		TrimString(sLine);
		if (strlen(sLine) < 1)
			continue;
		PushArrayString(g_hBadNameList, sLine);
		if(IsPluginDebugging(g_hPlugin))
			LogMessage("Read bad name: \"%s\"", sLine);
	}

	CloseHandle(fh);

	return true;
}

public EventNameChange(Handle:event, const String:name[], bool:dontBroadcast)
{
	new result = 0;
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new iBanTime = GetConVarInt(g_hCVarBanTime);
	decl String:sChangeAction[10];
	decl String:sCheckAction[10];
	GetConVarString(g_hCVarChangeAction, sChangeAction, sizeof(sChangeAction));
	GetConVarString(g_hCVarCheckAction, sCheckAction, sizeof(sCheckAction));
	
	if ( !client || !IsClientConnected(client) || IsClientInKickQueue(client) || IsFakeClient(client) )
		return;
	decl String:oldName[64], String:newName[64];
	GetEventString(event, "oldname", oldName, sizeof(oldName));
	GetEventString(event, "newname", newName, sizeof(newName));
	if ( (result = CheckName(client,newName)) != 0 )
	{
		decl String:authString[30], String:reason[255], String:details[255];
		GetClientAuthString(client, authString, sizeof(authString));
		if (strcmp(sCheckAction,"ban")==0) {
			FormatEx(reason, sizeof(reason), "%s (%s) has been banned for attempting to name hack (%s).", oldName, authString, g_sDetails[result]);
			ReplaceString(reason, sizeof(details), "{INVALID}", g_sInvalid[client]);
			if(GetConVarBool(g_hCVarTellDetails))
				FormatEx(details, sizeof(details), "Banned for name exploit (%s)", g_sDetails[result]);
			else
				FormatEx(details, sizeof(details), "Banned for name exploit.");
			ReplaceString(details, sizeof(details), "{INVALID}", g_sInvalid[client]);
			DoBan(client, iBanTime, details, details);
		} else if (strcmp(sCheckAction,"kick")==0) {
			FormatEx(reason, sizeof(reason), "%s (%s) has been kicked for attempting to name hack (%s).", oldName, authString, g_sDetails[result]);
			ReplaceString(reason, sizeof(details), "{INVALID}", g_sInvalid[client]);
			if(GetConVarBool(g_hCVarTellDetails))
				FormatEx(details, sizeof(details), "Your %s", g_sDetails[result]);
			else
				FormatEx(details, sizeof(details), "Your name is invalid (%d).", result);
			ReplaceString(details, sizeof(details), "{INVALID}", g_sInvalid[client]);
			if ( IsClientConnected(client) && !IsFakeClient(client) && !IsClientInKickQueue(client) )
				KickClient(client, "%s", details);
		} else {
			FormatEx(reason, sizeof(reason), "%s (%s) has been blocked for attempting to name hack (%s).", oldName, authString, g_sDetails[result]);
			ReplaceString(reason, sizeof(details), "{INVALID}", g_sInvalid[client]);
			if(GetConVarBool(g_hCVarTellDetails))
				FormatEx(details, sizeof(details), "Name change not allowed (%s)", g_sDetails[result]);
			else
				FormatEx(details, sizeof(details), "Name change not allowed.");
			ReplaceString(details, sizeof(details), "{INVALID}", g_sInvalid[client]);
			if ( IsClientConnected(client) && !IsFakeClient(client) ) {
				strcopy(g_sNames[client][0],64,oldName);
				CreateTimer(0.1, Timed_Rename, client, TIMER_FLAG_NO_MAPCHANGE);
				PrintToChat(client, "\x04[NAMECHECKER]\x01 %s", details);
			}
		}
		LogMessage(reason);
		PrintToAdmins(reason);
		return;
	}
	if (g_iChanges[client] >= GetConVarInt(g_hCVarChangeCount)) {
		decl String:authString[30], String:reason[255], String:details[255];
		GetClientAuthString(client, authString, sizeof(authString));
		if (strcmp(sChangeAction,"ban")==0) {
			FormatEx(reason, sizeof(reason), "%s (%s) has been banned for attempting to change his name too often.", oldName, authString);
			FormatEx(details, sizeof(details), "Banned for too many name changes.");
			DoBan(client, iBanTime, details, details);
		} else if (strcmp(sChangeAction,"kick")==0) {
			FormatEx(reason, sizeof(reason), "%s (%s) has been kicked for attempting to change his name too often.", oldName, authString);
			FormatEx(details, sizeof(details), "You have changed your name too often");
			if ( IsClientConnected(client) && !IsFakeClient(client) && !IsClientInKickQueue(client) )
				KickClient(client, "%s", "You have changed your name too often");
			g_iChanges[client] = 0;
		} else {
			FormatEx(reason, sizeof(reason), "%s (%s) has been blocked for attempting to change his name too often.", oldName, authString);
			FormatEx(details, sizeof(details), "You may not change your name.");
			if ( IsClientConnected(client) && !IsFakeClient(client) ) {
				strcopy(g_sNames[client][0],64,oldName);
				CreateTimer(0.1, Timed_Rename, client, TIMER_FLAG_NO_MAPCHANGE);
				PrintToChat(client, "\x04[NAMECHECKER]\x01 %s", details);
			}
			// g_iChanges[client] = 0;
		}
		LogMessage(reason);
		PrintToAdmins(reason);
		return;
	}
	g_iChanges[client]++;
	return;
}

public Action:Timed_Kick(Handle:timer,any:code)
{
	new client = 0;
	client = (code >> 8);
	new result = 0;
	result = (code & 255);
	decl String:details[255];
	if(GetConVarBool(g_hCVarTellDetails))
		FormatEx(details, sizeof(details), "%s", g_sDetails[result]);
	else
		FormatEx(details, sizeof(details), "Change your name");
	ReplaceString(details, sizeof(details), "INVALID", g_sInvalid[client]);
	decl String:authString[30], String:reason[255], String:name[64];
	if ( client > 0 && IsClientConnected(client) && !IsFakeClient(client) && !IsClientInKickQueue(client) ) {
		GetClientName(client, name, sizeof(name));
		GetClientAuthString(client, authString, sizeof(authString));
		KickClient(client, "%s", details);
		FormatEx(reason, sizeof(reason), "%s (%s) has been kicked for his bad name (%s)", name, authString, details);
		ReplaceString(reason, sizeof(details), "{INVALID}", g_sInvalid[client]);
		LogMessage(reason);
	}
}

public Action:Timed_Ban(Handle:timer,any:code)
{
	new client = (code >> 8);
	new result = (code & 255);
	decl String:details[255];
	if(GetConVarBool(g_hCVarTellDetails))
		FormatEx(details, sizeof(details), "%s", g_sDetails[result]);
	else
		FormatEx(details, sizeof(details), "You have been banned for name exploiting.");
	ReplaceString(details, sizeof(details), "{INVALID}", g_sInvalid[client]);
	decl String:reason[255];
	new iBanTime = GetConVarInt(g_hCVarBanTime);
	FormatEx(reason, sizeof(reason), "Banned for name exploit (%s)", details);
	ReplaceString(reason, sizeof(details), "{INVALID}", g_sInvalid[client]);
	if ( client > 0 && IsClientConnected(client) && !IsFakeClient(client) )
		DoBan(client, iBanTime, reason, details);
}

DoBan(client, time, String:IReason[], String:EReason[])
{
	if ( !IsClientConnected(client) || IsFakeClient(client) )
		return;
	decl String:authString[30], Handle:t_ConVar, bool:test;
	test = GetClientAuthString(client, authString, sizeof(authString));
	if ( !test || StrEqual(authString, "STEAM_ID_LAN") )
	{
		BanClient(client, time, BANFLAG_IP, IReason, EReason);
		return;
	}
	else
	{
		t_ConVar = FindConVar("sb_version");
		if ( t_ConVar != INVALID_HANDLE )
		{
			ServerCommand("sm_ban #%d \"%d\" \"%s\"", GetClientUserId(client), time, IReason);
			return;
		}
		t_ConVar = FindConVar("mysql_bans_version");
		if ( t_ConVar != INVALID_HANDLE )
		{
			ServerCommand("mysql_ban #%d %d %s", GetClientUserId(client), time, IReason);
			return;
		}
		BanClient(client, time, BANFLAG_AUTO, IReason, EReason);
	}
	return;
}

public Action:Timed_Rename(Handle:timer,any:target)
{
	SetClientInfo(target, "name", g_sNames[target]);
	LogMessage("renamed \"%L\" to \"%s\")", target, g_sNames[target]);
}

CheckName(client,const String:text[])
{
	new iCopySize = GetConVarInt(g_hCVarCopySize);
	new iCopyDiff = GetConVarInt(g_hCVarCopyDiff);
	new iSpecialChars = GetConVarInt(g_hCVarSpecialChars);
	new iMultiByte = GetConVarInt(g_hCVarMultiByte);
	new iBadNames = GetArraySize(g_hBadNameList);
	new iMinSize = GetConVarInt(g_hCVarMinSize);
	new iMaxSize = GetConVarInt(g_hCVarMaxSize);
	new FoundSpecial = 0;
	new FoundMB = 0;
	decl String:name[64];
	decl String:name2[64];

	strcopy(name,sizeof(name),text);
	g_sInvalid[client][0] = '\0';

	// empty names are not allowed
	TrimString(name);
	if(strlen(name)<iMinSize)
		return 1;
	// name too long
	if(strlen(name)>iMaxSize)
		return 2;

	for(new i=0;i<strlen(name);i++) {

		// no control characters allowed
		if (name[i]<32)
			return 3;

		// no quotes allowed!
		if (name[i]==34 && !IsCharMB(name[i]))
			return 4;

		if (!IsCharAlpha(name[i]) && !IsCharNumeric(name[i]) && !IsCharMB(name[i]))
			FoundSpecial++;

		if (IsCharMB(name[i]))
			FoundMB++;

	}

	// only special characters
	if(strlen(name)<=FoundSpecial)
		return 5;

	// no more than x special chars allowed
	if (FoundSpecial > iSpecialChars)
		return 6;

	// no more than x multi-byte chars allowed
	if (FoundMB > iMultiByte)
		return 7;

	name[iCopySize] = '\0';
	for(new i=0;i<g_iMaxPlayers;i++) {
		strcopy(name2,iCopySize,g_sNames[i][0]);
		TrimString(name2);
		if ((i!=client) && (strlen(name2)>3) && (StringDiff(name,name2) < iCopyDiff))
			return 8;
	}

	// check for bad names
	for(new i=0;i<iBadNames;i++) {
		GetArrayString(g_hBadNameList, i, name2, sizeof(name2));
		if (StrContains(name, name2, false) != -1) {
			name2[63] = '\0';
			strcopy(g_sInvalid[client][0],64,name2);
			return 9;
		}
	}

	if(IsPluginDebugging(g_hPlugin))
		LogMessage("Checked Name: %s (Size: %d)", name, strlen(name));

	return 0;
}

StringDiff(String:str1[], String:str2[])
{
	new len, diff = 0;
	len = strlen(str1);
	if (len > strlen(str2)) {
		diff = len - strlen(str2);
		len = strlen(str2);
	} else {
		diff = strlen(str2)-len;
	}
	for(new i=0; i < len; i++) {
		if (str1[i] != str2[i])
			diff++;
	}
	return diff;
}

PrintToAdmins(String:text[])
{
	decl clientFlags;
	new maxclients = GetMaxClients();
	for(new i=1;i<maxclients;i++)
		if ( IsClientInGame(i) && GetUserAdmin(i) != INVALID_ADMIN_ID ) {
			clientFlags = GetUserFlagBits(i);
			if(clientFlags & ADMFLAG_BAN)
				PrintToChat(i, "\x04[NAMECHECKER]\x01 %s", text);
		}
}
