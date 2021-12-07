/**
 *
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
 *
 * -----
 * I have replaced the precompiled array with a file parsing function,
 * This is still untested
 * Dutchmeat
 * -----
 */

#include <sourcemod>

new String: bad_words[50][30];

public Plugin:myinfo = {
	name = "Word Filter Plugin",
	author = "Tobi17",
	description = "Blocks bad language from the chat area",
	version = "1.0.0.0",
	url = "http://www.hlstatsx.com"
};

public OnPluginStart() 
{
	RegConsoleCmd("say",          block_bad_language);
	RegConsoleCmd("say_team",     block_bad_language);
	ReadBadWords();
}

public LineToArray(const String:line[]){
	if (strlen(line) > 1){
		for(new i = 0;i < 50;i++){
			if(strlen(bad_words[i]) < 1 && !StrEqual(bad_words[i],line) )
				strcopy(bad_words[i], 30, line);
		}
	}
}

public ReadBadWords()
{
	new String:g_Filename[PLATFORM_MAX_PATH]
	BuildPath(Path_SM, g_Filename, sizeof(g_Filename), "configs/bad_words.ini");
	
	new Handle:file = OpenFile(g_Filename, "rt");
	if (file == INVALID_HANDLE)
	{
		PrintToServer("Could not open file!");
		return;
	}
	
	while (!IsEndOfFile(file))
	{
		decl String:line[255];
		if (!ReadFileLine(file, line, sizeof(line)))
		{
			break;
		}
		
		if ((line[0] == '/' && line[1] == '/')
			|| (line[0] == ';' || line[0] == '\0'))
		{
			continue;
		}
	
		LineToArray(line);
	}
	
	CloseHandle(file);
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

			new command_blocked = is_bad_word(user_command[start_index]);
			if (command_blocked > 0) {

				if ((!IsFakeClient(client)) && (IsClientConnected(client))) {
					decl String:display_message[192];
					Format(display_message, 192, "\x01 %s", "Watch your language!");

					decl Handle:hBf;
					hBf = StartMessageOne("SayText2", client);
					if (hBf != INVALID_HANDLE) {
						BfWriteByte(hBf, 1); 
						BfWriteByte(hBf, 0); 
						BfWriteString(hBf, display_message);
						EndMessage();
					}

					decl String:player_name[64];
					if (!GetClientName(client, player_name, 64))	{
						strcopy(player_name, 64, "UNKNOWN");
					}

					decl String:player_authid[64];
					GetClientAuthString(client, player_authid, 64);
					if (!GetClientAuthString(client, player_authid, 64)){
						strcopy(player_authid, 64, "UNKNOWN");
					}

					new player_userid = GetClientUserId(client);

					new String:player_team[32] = "";

					LogToGame("\"%s<%d><%s><%s>\" triggered \"bad_language\"", player_name, player_userid, player_authid, player_team); 

				}
				return Plugin_Handled;
			}
		}
	}
 
	return Plugin_Continue;
}

stock StrToken(const String:inputstr[],tokennum,String:outputstr[],maxlen)
{
    new String:buf[]="";
    new cur_idx;
    new idx;
    new curind;
    idx=StrBreak(inputstr,buf,maxlen);
    if(tokennum==1)
    {
        strcopy(outputstr,maxlen,buf);
        return;
    }
    curind=1;
    while (idx!=-1)
    {
        cur_idx+=idx;
        idx=StrBreak(inputstr[cur_idx],buf,maxlen);
        curind++;
        if(tokennum==curind)
        {
            strcopy(outputstr,maxlen,buf);
            break;
        }
    }
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1043\\ f0\\ fs16 \n\\ par }
*/
