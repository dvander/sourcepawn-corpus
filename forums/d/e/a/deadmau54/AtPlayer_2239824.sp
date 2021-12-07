#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = {
	name = "At Player",
	author = "The Count",
	description = "Allows players to get attention of other players by using @.",
	version = "1",
	url = "http://steamcommunity.com/profiles/76561197983205071/"
}

#define COLOR_BLUE		"\x0797CFDC"
#define COLOR_RED		"\x07FF4B4B"
#define COLOR_SPEC		"\x07CCCCCC"

public OnPluginStart(){
	LoadTranslations("common.phrases");
	
	AddCommandListener(Event_Say, "say");
}

public Action:Event_Say(client, const String:command[], argc){
	decl String:text[192], String:user[MAX_NAME_LENGTH];
	GetClientName(client, user, sizeof(user));
	GetCmdArgString(text, sizeof(text));
	StripQuotes(text);
	TrimString(text);
	if(FindCharInString(text, '/') == 0 || FindCharInString(text, '!') == 0){
		return Plugin_Continue;
	}
	if(FindCharInString(text, '@') == -1){
		return Plugin_Continue;
	}
	new String:message[500], String:charsList[100][55], any:targ = 0, String:username[MAX_NAME_LENGTH];
	GetClientName(client, username, sizeof(username));
	if(IsPlayerAlive(client) == false){
		Format(message, sizeof(message), "*DEAD* ");
	}
	if(GetClientTeam(client) == 2){
		Format(message, sizeof(message), "\x01%s%s%s\x01 :", message, COLOR_RED, username);
	}else{
		if(GetClientTeam(client) == 3){
			Format(message, sizeof(message), "\x01%s%s%s\x01 :", message, COLOR_BLUE, username);
		}else{
			Format(message, sizeof(message), "\x01%s*SPEC* %s\x01 :", COLOR_SPEC, username);
		}
	}
	ExplodeString(text, " ", charsList, sizeof(charsList), sizeof(charsList[]));
	for(new i=0;i<sizeof(charsList);i++){
		if(FindCharInString(charsList[i], '@') == 0){
			targ = FindTarget(client, charsList[i][1], false, false);
			if(targ == -1){
				continue;
			}
			ClientCommand(targ, "playgamesound ui/item_acquired.wav");
			GetClientName(targ, username, sizeof(username));
			if(GetClientTeam(targ) == 2){
				Format(charsList[i], sizeof(charsList[]), "%s%s\x01", COLOR_RED, username);
			}else{
				if(GetClientTeam(targ) == 3){
					Format(charsList[i], sizeof(charsList[]), "%s%s\x01", COLOR_BLUE, username);
				}else{
					Format(charsList[i], sizeof(charsList[]), "%s%s", COLOR_SPEC, username);
				}
			}
		}
		if(StrEqual(charsList[i], "", false) == false){
			Format(message, sizeof(message), "%s %s", message, charsList[i]);
		}
	}
	PrintToChatAll("%s", message);
	return Plugin_Handled;
}