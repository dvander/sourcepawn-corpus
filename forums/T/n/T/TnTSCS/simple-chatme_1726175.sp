/************************************************************************
*************************************************************************
Simple Chat Me
Description:
		Allows for 3rd person action chat with /me trigger. 
*************************************************************************
*************************************************************************
This file is part of Simple Plugins project.

This plugin is free software: you can redistribute 
it and/or modify it under the terms of the GNU General Public License as
published by the Free Software Foundation, either version 3 of the License, or
later version. 

This plugin is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this plugin.  If not, see <http://www.gnu.org/licenses/>.
*************************************************************************
*************************************************************************
File Information
$Id: simple-chatalldead.sp 175 2011-09-07 00:42:17Z antithasys $
$Author: antithasys $
$Revision: 175 $
$Date: 2011-09-06 19:42:17 -0500 (Tue, 06 Sep 2011) $
$LastChangedBy: antithasys $
$LastChangedDate: 2011-09-06 19:42:17 -0500 (Tue, 06 Sep 2011) $
$URL: https://sm-simple-plugins.googlecode.com/svn/trunk/Simple%20Chat%20Processor/addons/sourcemod/scripting/simple-chatalldead.sp $
$Copyright: (c) Simple Plugins 2008-2009$
*************************************************************************
*************************************************************************
*/

#include <sourcemod>
#include <sdktools>
#include <scp>
#include <smlib>

#define PLUGIN_VERSION				"1.0.0b" // Added admin check for /me command // removed the PrintToChat

public Plugin:myinfo =
{
	name = "Simple Chat Me",
	author = "Simple Plugins",
	description = "Allows for 3rd person action chat with /me trigger.",
	version = PLUGIN_VERSION,
	url = "http://www.simple-plugins.com"
};

public OnPluginStart()
{
	CreateConVar("scme_version", PLUGIN_VERSION, "Simple Chat Me", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "scp"))
	{
		SetFailState("Simple Chat Processor Unloaded.  Plugin Disabled.");
	}
}

public Action:OnChatMessage(&author, Handle:recipients, String:name[], String:message[])
{
	decl String:sMessageBuffer[MAXLENGTH_INPUT];
	decl String:sWords[64][MAXLENGTH_INPUT];
	Color_StripFromChatText(message, sMessageBuffer, MAXLENGTH_INPUT);
	ExplodeString(sMessageBuffer, " ", sWords, sizeof(sWords), sizeof(sWords[]));
	TrimString(sWords[0]);
	if (StrEqual(sWords[0], "/me") && CheckCommandAccess(author, "allow_cmd_me", ADMFLAG_GENERIC))
	{
		new userid = GetClientUserId(author);
		new Handle:hPack;
		new numClients = GetArraySize(recipients);
		CreateDataTimer(0.001, Timer_MeAction, hPack, TIMER_FLAG_NO_MAPCHANGE);
		WritePackCell(hPack, userid);
		WritePackString(hPack, message);
		WritePackCell(hPack, numClients);
		for (new i = 0; i < numClients; i++)
		{
			new x = GetArrayCell(recipients, i);
			WritePackCell(hPack, x);
		}
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action:Timer_MeAction(Handle:timer, any:pack)
{
	ResetPack(pack);
	new client	= GetClientOfUserId(ReadPackCell(pack));
	if (client == 0)
	{
		return Plugin_Stop;
	}
	
	decl String:message[MAXLENGTH_INPUT];
	ReadPackString(pack, message, sizeof(message));
	ReplaceString(message, sizeof(message), "/me", "");
	new numClients = ReadPackCell(pack);
	new clients[numClients];
	
	for (new i = 0; i < numClients; i++)
	{
		clients[i] = ReadPackCell(pack);
	}
	
	decl String:sAction[MAXLENGTH_INPUT];
	decl String:sClientName[MAXLENGTH_NAME];
	GetClientName(client, sClientName, sizeof(sClientName));
	Color_StripFromChatText(message, sAction, sizeof(sAction));
	TrimString(sAction);
	Format(sAction, sizeof(sAction), "{T}%s %s", sClientName, sAction);
	
	Color_ChatSetSubject(client);
	for (new i = 0; i < numClients; i++)
	{
		if (Client_IsValid(clients[i]))
		{
			Client_PrintToChat(clients[i], true, sAction);
		}
	}
	Color_ChatClearSubject();
	
	return Plugin_Stop;
}