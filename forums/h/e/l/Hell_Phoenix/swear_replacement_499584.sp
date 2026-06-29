/*
Swear Replacement
Hell Phoenix
http://www.charliemaurice.com/plugins

This plugin is based on kaboomkazoom's amxx swear replacement plugin.  It allows you to do 3 different replacement
modes.  It also sends a warning to the user that foul language is not allowed.  It also checks a players name to 
make sure that it doesnt have any bad words in it.

Mode 1 replaces what the user said with a random phrase.  
Mode 2 shows just **** (or whatever you set the cvar to) instead of the word (filters it)
Mode 3 doesnt display the users chat at all

	
Versions:
	1.0
		* First Public Release!
	1.1
		* Added Insurgency Mod Support!
		* Added Cvar to turn off name checking
		* Added custom word replacement (use mode 2)
		* Changed Maxplayers from a define to GetMaxClients();
		* Log now only logs the original message
		* Team say now stays in the team chat instead of getting moved to global chat
	1.2
		* Fixed some errors from the console/log
	1.3
		* Fixed crashing
	1.4
		* Fixed a major loop that caused crashes sometimes (thanks Bailopan)

Todo:
	
Notes:
	The client name doesnt appear in the team color for any mod other than Insurgency.  Not sure this will ever be possible 
	to fix.	The only thing you can do if you dont want the persons name to show up all white is to use mode 3 and not 
	allow it to	show at all.
	
	Make sure that badwords.txt and replacements.txt are in your sourcemod/configs/ directory!
 
Cvarlist (default value):
	sm_swear_replace_mode 1 <1|2|3> are valid options
	sm_swear_name_check 1 <0|1> are valid options
	sm_swear_replace **** <change this to whatever string you want to replace the word if you dont want stars (for mode 2)>

Admin Commands:
	None

 
*/


#include <sourcemod>

#pragma semicolon 1

#define PLUGIN_VERSION "1.4"

// Plugin definitions
public Plugin:myinfo = 
{
	name = "Swear Replacement",
	author = "Hell Phoenix",
	description = "Swear Replacement",
	version = PLUGIN_VERSION,
	url = "http://www.charliemaurice.com/plugins/"
};

#define MAX_WORDS 200
#define MAX_REPLACE 50

new Handle:cvarswearmode;
new Handle:cvarswearname;
new Handle:cvarswearreplace;
new String:badwordfile[PLATFORM_MAX_PATH];
new String:replacefile[PLATFORM_MAX_PATH];
new String:g_swearwords[MAX_WORDS][32];
new String:g_replaceLines[MAX_REPLACE][191];
new MAX_PLAYERS;
new g_swearNum;
new g_replaceNum;

public OnPluginStart(){
	CreateConVar("sm_swearreplace_version", PLUGIN_VERSION, "Swear Replace Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvarswearmode = CreateConVar("sm_swear_replace_mode","1","Options are 1 (replace), 2 (stars), or 3 (eat the text).",FCVAR_PLUGIN);
	cvarswearname = CreateConVar("sm_swear_name_check","1","1 is on, 0 is off.",FCVAR_PLUGIN);
	cvarswearreplace = CreateConVar("sm_swear_replace","****","You can use any word here...this is what replaces the swear word in mode 2",FCVAR_PLUGIN);
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say2", Command_InsurgencySay);
	RegConsoleCmd("say_team", Command_TeamSay);
}

public OnMapStart(){
	CreateTimer(0.1, Read_Files);
	MAX_PLAYERS = GetMaxClients();
}

public OnMapEnd(){
	g_swearNum = 0;
	g_replaceNum = 0;
}

public Action:Read_Files(Handle:timer){
	BuildPath(Path_SM,badwordfile,sizeof(badwordfile),"configs/badwords.txt");
	BuildPath(Path_SM,replacefile,sizeof(replacefile),"configs/replacements.txt");
	if(!FileExists(badwordfile)) {
		LogMessage("badwords.txt not parsed...file doesnt exist!");
	}else{
		new Handle:badwordshandle = OpenFile(badwordfile, "r");
		new i = 0;
		while( i < MAX_WORDS && !IsEndOfFile(badwordshandle)){
			ReadFileLine(badwordshandle, g_swearwords[i], sizeof(g_swearwords[]));
			TrimString(g_swearwords[i]);
			i++;
			g_swearNum++;
		}
		CloseHandle(badwordshandle);
	}
	
	if(!FileExists(replacefile)) {
		LogMessage("replacements.txt not parsed...file doesnt exist!");
	}else{
		new Handle:replacehandle = OpenFile(replacefile, "r");
		new i = 0;
		while( i < MAX_WORDS && !IsEndOfFile(replacehandle)){
			ReadFileLine(replacehandle, g_replaceLines[i], sizeof(g_replaceLines[]));
			TrimString(g_replaceLines[i]);
			i++;
			g_replaceNum++;
		}	
		CloseHandle(replacehandle);	
	}
}

public OnClientPutInServer(client){
	if (GetConVarInt(cvarswearname) == 1){
		if(client != 0){
			decl String:clientName[64];
			GetClientName(client,clientName,64);
			string_cleaner(clientName, sizeof(clientName));
			
			new i = 0;
			while (i < g_swearNum){
				if (StrContains(clientName, g_swearwords[i], false) != -1 ){
					LogMessage("[Swear Replacement] Named changed from %s", clientName);
					ClientCommand(client,"name %s", "IhadaBadName");
				}
				i++;
			}	
		}
	}
}

public OnClientSettingsChanged(client){
	if (GetConVarInt(cvarswearname) == 1){
		if(client != 0){
			decl String:clientName[64];
			GetClientName(client,clientName,64);
			string_cleaner(clientName, sizeof(clientName));
			
			new i = 0;
			while (i < g_swearNum){
				if (StrContains(clientName, g_swearwords[i], false) != -1 ){
					LogMessage("[Swear Replacement] Named changed from %s", clientName);
					ClientCommand(client,"name %s", "IhadaBadName");
				}
				i++;
			}	
		}
	}
}

public Action:Command_Say(client,args){
	if(client != 0){
		decl String:speech[191];
		decl String:clientname[64];
		GetClientName(client,clientname,64);
		GetCmdArgString(speech,sizeof(speech));
		
		
		new startidx = 0;
		if (speech[0] == '"'){
			startidx = 1;
			/* Strip the ending quote, if there is one */
			new len = strlen(speech);
			if (speech[len-1] == '"'){
					speech[len-1] = '\0';
			}
		}
		
		decl String:originalstring[191];
		strcopy(originalstring, sizeof(speech), speech[startidx]);
		string_cleaner(speech[startidx], sizeof(speech) - startidx);
		
		new i = 0;
		new found;
		while (i < g_swearNum){
			if (StrContains(speech[startidx], g_swearwords[i], false) != -1 ){
				new String:replacement[32];
				GetConVarString(cvarswearreplace, replacement, 32);
				ReplaceString(speech, strlen(speech), g_swearwords[i], replacement);
				found = true;
			}
			i++;
		}
		if (found){
			LogMessage("[Swear Replacement] %s : %s",clientname, originalstring);
			if (GetConVarInt(cvarswearmode) == 1){
				new random_replace = GetRandomInt(0, g_replaceNum);
				strcopy(speech[startidx], sizeof(g_replaceLines[]), g_replaceLines[random_replace]);
				PrintToChatAll("%s: %s", clientname, speech[startidx]);
				PrintToChat(client, "Please do not use foul language here!");
				return Plugin_Handled;
			}else if (GetConVarInt(cvarswearmode) == 2){
				PrintToChatAll("%s: %s", clientname, speech[startidx]);
				PrintToChat(client, "Please do not use foul language here!");
				return Plugin_Handled;
			}else if (GetConVarInt(cvarswearmode) == 3){
				PrintToChat(client, "Please do not use foul language here!");
				return Plugin_Handled;
			}
		}
		
	}
	return Plugin_Continue;
}

public Action:Command_TeamSay(client,args){
	if(client != 0){
		decl String:speech[191];
		decl String:clientname[64];
		GetClientName(client,clientname,64);
		GetCmdArgString(speech,sizeof(speech));
		
		new startidx = 0;
		if (speech[0] == '"'){
			startidx = 1;
			/* Strip the ending quote, if there is one */
			new len = strlen(speech);
			if (speech[len-1] == '"'){
					speech[len-1] = '\0';
			}
		}
		decl String:originalstring[191];
		strcopy(originalstring, sizeof(speech), speech[startidx]);
		
		string_cleaner(speech[startidx], sizeof(speech) - startidx);
		
		new i = 0;
		new found;
		while (i < g_swearNum){
			if (StrContains(speech[startidx], g_swearwords[i], false) != -1 ){
				new String:replacement[32];
				GetConVarString(cvarswearreplace, replacement, 32);
				ReplaceString(speech, strlen(speech), g_swearwords[i], replacement);
				found = true;
			}
			i++;
		}
		if (found){
			LogMessage("[Swear Replacement] %s : %s",clientname, originalstring);
			if (GetConVarInt(cvarswearmode) == 1){
				new random_replace = GetRandomInt(0, g_replaceNum);
				strcopy(speech[startidx], sizeof(g_replaceLines[]), g_replaceLines[random_replace]);
				for (new j = 1; j < MAX_PLAYERS; j++){
					if(IsClientConnected(j)){
						if(GetClientTeam(j) == GetClientTeam(client)){
							PrintToChat(j, "(Team) %s: %s", clientname, speech[startidx]);
						}
					}
				}
				PrintToChat(client, "Please do not use foul language here!");
				return Plugin_Handled;
			}else if (GetConVarInt(cvarswearmode) == 2){
				for (new j = 1; j < MAX_PLAYERS; j++){
					if(IsClientConnected(j)){
						if(GetClientTeam(j) == GetClientTeam(client)){
							PrintToChat(j, "(Team) %s: %s", clientname, speech[startidx]);
						}
					}
				}
				PrintToChat(client, "Please do not use foul language here!");
				return Plugin_Handled;
			}else if (GetConVarInt(cvarswearmode) == 3){
				PrintToChat(client, "Please do not use foul language here!");
				return Plugin_Handled;
			}
		}
		
	}
	return Plugin_Continue;
}

public Action:Command_InsurgencySay(client,args){
	if(client != 0){
		decl String:speech[191];
		decl String:clientname[64];
		GetClientName(client,clientname,64);
		GetCmdArgString(speech,sizeof(speech));
		
		new startidx = 0;
		if (speech[0] == '"'){
			startidx = 1;
			/* Strip the ending quote, if there is one */
			new len = strlen(speech);
			if (speech[len-1] == '"'){
					speech[len-1] = '\0';
			}
		}
		
		decl String:originalstring[191];
		strcopy(originalstring, sizeof(speech), speech[startidx]);
		string_cleaner(speech[startidx], sizeof(speech) - startidx);
		
		new i = 0;
		new found;
		while (i < g_swearNum){
			if (StrContains(speech[startidx], g_swearwords[i], false) != -1 ){
				new String:replacement[32];
				GetConVarString(cvarswearreplace, replacement, 32);
				ReplaceString(speech, strlen(speech), g_swearwords[i], replacement);
				found = true;
			}
			i++;
		}
		if (found){
			LogMessage("[Swear Replacement] %s : %s",clientname, originalstring);
			if (GetConVarInt(cvarswearmode) == 1){
				new random_replace = GetRandomInt(0, g_replaceNum);
				strcopy(speech[startidx], sizeof(g_replaceLines[]), g_replaceLines[random_replace]);
				ClientCommand(client,"say2 %s",speech[startidx]);
				PrintToChat(client, "Please do not use foul language here!");
				return Plugin_Handled;
			}else if (GetConVarInt(cvarswearmode) == 2){
				ClientCommand(client,"say2 %s",speech[startidx]);
				PrintToChat(client, "Please do not use foul language here!");
				return Plugin_Handled;
			}else if (GetConVarInt(cvarswearmode) == 3){
				PrintToChat(client, "Please do not use foul language here!");
				return Plugin_Handled;
			}
		}
		
	}
	return Plugin_Continue;
}

string_cleaner(String:str[], maxlength){
	new i, len = strlen(str);
	if (GetConVarInt(cvarswearmode) != 2){
			ReplaceString ( str, maxlength, " ", "" );
	}

	ReplaceString(str, maxlength, "|<", "k");
	ReplaceString(str, maxlength, "|>", "p");
	ReplaceString(str, maxlength, "()", "o");
	ReplaceString(str, maxlength, "[]", "o");
	ReplaceString(str, maxlength, "{}", "o");

	for(i = 0; i < len; i++)
	{
		if(str[i] == '@')
			str[i] = 'a';

		if(str[i] == '$')
			str[i] = 's';

		if(str[i] == '0')
			str[i] = 'o';

		if(str[i] == '7')
			str[i] = 't';

		if(str[i] == '3')
			str[i] = 'e';

		if(str[i] == '5')
			str[i] = 's';

		if(str[i] == '<')
			str[i] = 'c';

		if(GetConVarInt(cvarswearmode) != 2){
			if(str[i] == '3')
				str[i] = 'e';
		}
		
	}
}