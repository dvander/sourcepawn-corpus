/* [ Includes ] */
#include <sourcemod>

/* [ Compiler Options ] */
#pragma newdecls required
#pragma semicolon		1

/* [ Defines ] */
#define MAX_MESSAGE_LENGTH 512

/* [ Chars ] */
static const char g_sSymbols[][] =  { "", "", "", "", "", "", "", "", "", "", "", "	" };
// White | Green | Blue | Darkblue | Darkred | Gold | Grey | Lightgreen | Lightred | Lime | Purple | Yellow

/* [ Plugin Author And Informations ] */
public Plugin myinfo =  {
	name = "[CS:GO] Pawel - [ Block Color Chat ]", 
	author = "Pawel", 
	description = "Block color messages for CS:GO servers by Pawel.", 
	version = "1.0.0", 
	url = "https://steamcommunity.com/id/pawelsteam"
};

/* [ Message Modify ] */
public Action OnChatMessage(int &iAuthor, Handle hRecipients, char[] sName, char[] sMessage) {
	for (int i = 0; i < sizeof(g_sSymbols); i++) {
		while (StrContains(sMessage, g_sSymbols[i]) != -1) {
			ReplaceString(sMessage, MAX_MESSAGE_LENGTH, g_sSymbols[i], "");
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}
