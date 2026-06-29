/**
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

#pragma semicolon 1

#include <sourcemod>

#define PERCENT 37
#define NAME "Color Strip"
#define VERSION "1.0"

public Plugin:myinfo = {
	name = NAME,
	author = "psychonic",
	description = "Stops players from sneaking color into their chat messages",
	version = VERSION,
	url = "http://www.nicholashastings.com"
};

public OnPluginStart()
{
	CreateConVar("sm_colorstrip_version", VERSION, NAME, FCVAR_PLUGIN|FCVAR_NOTIFY);
	RegConsoleCmd("say", ParseChat);
	RegConsoleCmd("say_team", ParseChat);
}

public Action:ParseChat(client, args)
{
	if (client == 0 || IsChatTrigger())
	{
		return Plugin_Continue;
	}
	
	decl String:szOrigChatMsg[192];
	GetCmdArgString(szOrigChatMsg, sizeof(szOrigChatMsg));
	
	if (szOrigChatMsg[0] == 0)
	{
		return Plugin_Continue;
	}
	
	decl String:szCommand[9];
	GetCmdArg(0, szCommand, sizeof(szCommand));
	
	decl String:szNewChatMsg[384];
	new j = 0;
	new bool:bFoundColor;
	for (new i = 0; i < sizeof(szOrigChatMsg); i++)
	{
		new char = szOrigChatMsg[i];
		if (char < 7 && char > 0)
		{
			bFoundColor = true;
			continue;
		}
		
		szNewChatMsg[j] = szOrigChatMsg[i];
		if (char == 0)
		{
			break;
		}
		j++;
		if (char == PERCENT)
		{
			szNewChatMsg[j] = PERCENT;
			j++;
		}
	}
	
	if (!bFoundColor)
	{
		return Plugin_Continue;
	}
	
	FakeClientCommand(client, "%s %s", szCommand, szNewChatMsg);
	return Plugin_Stop;
}