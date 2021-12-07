/**
 * Small Plugin to block bad language. If a "bad word" is detected
 * a player action will be display ingame to the affected player and
 * the action will be logged accordingly to the valve logging standard.
 *
 * Copyright (C) 2007 Tobias Oetzel (tobi@hlstatsx.com)
 *
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

#include <sourcemod>

public Plugin:myinfo = {
	name = "Word Filter Plugin",
	author = "Tobi17",
	description = "Blocks bad language from the chat area",
	version = "1.1",
	url = "http://www.hlstatsx.com"
};


new String: bad_words[][] = 
{ 
	"hure", "nutte", "wichser", "wixxer", "arschloch", "jude", "juden", "hitler",
	"penis", "fick", "fuck", "maul", "mowl", "arsch", "fresse", "behindert", "schwuler",
	"gimp", "anal", "penis", "fotze", "nap", "noob", "n00b", "n.oob", "n-oob", "noo-b",
	"no-ob", "noo-b", "camper", "c.amper", "c-amper", "low", "pointer", "huso", "hurn",
	"moron", "moroon"
}


new String: blocked_words[][] = 
{ 
	"admin", "admin_menu"
}

new String: team_list[16][64];

public OnPluginStart() 
{
	RegConsoleCmd("say",          block_bad_language);
	RegConsoleCmd("say_team",     block_bad_language);
}

stock is_bad_word(String: command[])
{
	new bad_word = 0;
	new word_index = 0;
	while ((bad_word == 0) && (word_index < sizeof(bad_words))) {
		if (StrContains(command, bad_words[word_index], false) > -1) {
			bad_word++;
		}
		word_index++;
	}
	if (bad_word > 0) {
		return 1;
	}
	return 0;
}


stock is_blocked_word(String: command[])
{
	new blocked_word = 0;
	new word_index = 0;
	while ((blocked_word == 0) && (word_index < sizeof(blocked_words))) {
		if (strcmp(command, blocked_words[word_index]) == 0) {
			blocked_word++;
		}
		word_index++;
	}
	if (blocked_word > 0) {
		return 1;
	}
	return 0;
}


public Action:block_bad_language(client, args)
{
	if (client) {

		decl String:user_command[192];
		GetCmdArgString(user_command, 192);

		new start_index = 0
		new command_length = strlen(user_command);
		if (command_length > 0) {
			if (user_command[0] == 34)	{
				start_index = 1;
				if (user_command[command_length - 1] == 34)	{
					user_command[command_length - 1] = 0;
				}
			}
			
			if (user_command[start_index] == 47)	{
				start_index++;
			}

			ReplaceString(user_command, 192, ".", "");
			ReplaceString(user_command, 192, "-", "");
			ReplaceString(user_command, 192, ";", "");
			ReplaceString(user_command, 192, ":", "");
			ReplaceString(user_command, 192, "/", "");
			new command_blocked = is_bad_word(user_command[start_index]);
			if (command_blocked > 0) {

				if ((!IsFakeClient(client)) && (IsClientConnected(client))) {
					new String:display_message[192];
					Format(display_message, 192, "\x01 %s", "Watch your language!");

					new Handle:hBf;
					hBf = StartMessageOne("SayText2", client);
					if (hBf != INVALID_HANDLE) {
						BfWriteByte(hBf, 1); 
						BfWriteByte(hBf, 0); 
						BfWriteString(hBf, display_message);
						EndMessage();
					}

					new String:player_name[64];
					if (!GetClientName(client, player_name, 64))	{
						strcopy(player_name, 64, "UNKNOWN");
					}

					new String:player_authid[64];
					if (!GetClientAuthString(client, player_authid, 64)){
						strcopy(player_authid, 64, "UNKNOWN");
					}

					new player_team_index = GetClientTeam(client);
					new String:player_team[64];
					player_team = team_list[player_team_index];

					new player_userid = GetClientUserId(client);
					LogToGame("\"%s<%d><%s><%s>\" triggered \"bad_language\"", player_name, player_userid, player_authid, player_team); 

				}
				return Plugin_Handled;
			}

			new word_blocked = is_blocked_word(user_command[start_index]);
			if (word_blocked > 0) {
				if ((!IsFakeClient(client)) && (IsClientConnected(client))) {

					new String:player_name[64];
					if (!GetClientName(client, player_name, 64))	{
						strcopy(player_name, 64, "UNKNOWN");
					}

					new String:player_authid[64];
					if (!GetClientAuthString(client, player_authid, 64)){
						strcopy(player_authid, 64, "UNKNOWN");
					}

					new player_team_index = GetClientTeam(client);
					new String:player_team[64];
					player_team = team_list[player_team_index];

					new player_userid = GetClientUserId(client);
					LogToGame("\"%s<%d><%s><%s>\" say \"%s\"", player_name, player_userid, player_authid, player_team, user_command[start_index]); 
				}
				return Plugin_Handled;
			}

		}
	}
 
	return Plugin_Continue;
}
