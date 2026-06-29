/*
 * In-Chat Scrolling Rules
 * Written by Zirconium (nerzirconium@gmail.com)
 *
 * Licensed under the GPL version 2 or above
 *
 *  By default the plugin reads the rules from an usual translation file:
 *=========================================================================================
 *
 *		 "Rules"
 *		{
 *			"Rule01"
 *			{
 *				"en"        "{RED}This are our Server Rules !"
 *				"de"		"{RED}Dass sind unsere Regeln !"
 *				"fr"		"{RED}Ceci sont nos règles !" 
 *			}
 *			"Rule02"
 *			{
 *				"en"        "Follow them or you'll be kicked from Server"
 *				"de"		"Beobachtet Sie oder sie werden vom Server gekickt"
 *				"fr"		"observez-les ou vous serez kické du Serveur"
 *			}
 *			....
 *			"Rule10"
 *			{
 *				"en"		"=================================================="
 *				"de"		"=================================================="
 *				"fr"		"=================================================="
 *          ...
 *		}
 *
 *==========================================================================================
 *
 * Version 0.0.2 :	No more using LoadTranslations for the rules, but using Kv file instead to read translations files.
 * Version 0.0.3 :	No more limit for number of rules.
 * Version 0.0.4 :	Again using translations file but as KV file. 
 * Version 0.0.5 :	Fixed index problem in SendToAllMsg
 * Version 0.0.6 :	Fixed warning error "KillTimer" on OnMapStart
 * Version 0.0.7 :	Using PrintToChat and CPrintToChat translation capabilities and added a scrolllingrules_howto_delay var
 * Version 0.0.8 :	Fixed Global warning error with "KillTimer" 
 * Version 0.0.9 :  	Fixed some other timer bugs
 * Version 0.1.0 :  	using morecolors instead of colors
 * Version 0.1.1 :	Removed unnecessary FCVAR_PLUGIN + added use of CGetTeamColor(client) to get {teamcolor}
 * Version 1.0.0 :      Corrected  issue with {teamcolor} not working in welcome message
 */

#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_NAME             "TF2 ScrollingRules"
#define PLUGIN_AUTHOR           "Zirconium [NER] Clan"
#define PLUGIN_DESCRIPTION      "Scrolls the rules on demand and automaticaly."
#define PLUGIN_URL              "https://forums.alliedmods.net/showthread.php?p=1545113"

#define PLUGIN_VERSION "1.0.0"
/*
* Uncomment/comment for color support or not in the chat messages.
*
* You need  colors.inc file to compile it WITH #define USECOLORS uncommented
*
* SINCE VERSION 0.1.0
* You need  morecolors.inc file to compile it WITH #define USECOLORS uncommented
*/
#define USECOLORS

//#if defined USECOLORS
//#include <colors>
//#endif

#if defined USECOLORS
	#include <morecolors>
#endif

enum ChatCommand {
        String:command[32],
        String:description[255]
}

new String:sFileDir[256];

// CVars
new Handle:g_hEnabled;
new Handle:g_hRulesFile;
new Handle:g_hDelay;
new Handle:g_hAutoDelay;

// For Automatic Scrolling rules
new Handle:g_hInterval;
new Handle:g_hAutoTimer=INVALID_HANDLE;
new Handle:g_hMsgTimer2;
new Handle:g_hSectionName2;

// Specific for "sm_rules" command
new Handle:g_hSectionName;
new Handle:g_hMsgTimer;
new Handle:g_hUserIdQueue;
new Handle:g_hHowTo;
new Handle:g_hHowToDelay;

// Added to have morecolors working with older version of SourceMod !!
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) {
    MarkNativeAsOptional("GetUserMessageType");
    return APLRes_Success;
}  

public Plugin:myinfo =
{
	name = "ScrollingRules",
	author = "Zirconium",
	description = "Displays the Server Rules to users each X seconds or on demand",
	version = PLUGIN_VERSION,
	url = "http://www.ner-clan.org"
};

public OnPluginStart() 
{
	sFileDir = "translations";
	LoadTranslations("scrollingrules.phrases");
	LoadTranslations("scrollingrulesdata.phrases");
	g_hSectionName =CreateArray(250);
	g_hSectionName2 =CreateArray(250);
	g_hUserIdQueue = CreateArray();

        CreateConVar("scrollingrules_version", PLUGIN_VERSION,"Version of currently loaded [TF2] ScrollingRules plugin", FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_SPONLY);


//	CreateConVar("scrollingrules_version", PLUGIN_VERSION, "In-Chat Scrolling Rules version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);


	g_hEnabled          = CreateConVar("scrollingrules_enabled",  "1", "Enable/disable displaying scrollingrules.");
	g_hHowTo            = CreateConVar("scrollingrules_howto", "1", "Show the plugin's \"How to\" message.");
	g_hHowToDelay       = CreateConVar("scrollingrules_howto_delay", "20", "Amount of seconds before the \"How to\" message is shown.");
	g_hRulesFile        = CreateConVar("scrollingrules_file", "scrollingrulesdata.phrases.txt", "File to read the scrolling rules from, located in /translations dir .");
	g_hInterval         = CreateConVar("scrollingrules_interval", "300", "Amount of seconds between each group of rules scrolling automaticaly in chat.");
	g_hDelay            = CreateConVar("scrollingrules_delay", "0.2", "Amount of seconds between each rule line scrolling in chat when sm_rules is used.");
	g_hAutoDelay        = CreateConVar("scrollingrules_autodelay", "0.5", "Amount of seconds between each rule line scrolling in chat for Auto Scrolling.");

	
//	RegConsoleCmd("sm_rules", Command_PrintRulesToChat, "Display the Server Rules to the current player.", FCVAR_PLUGIN);
	RegConsoleCmd("sm_rules", Command_PrintRulesToChat, "Display the Server Rules to the current player.");

	AutoExecConfig(true, "scrollingrules");

	//Register:
	PrintToConsole(0, "[SM] ScrollingRules %s loaded successfully!", PLUGIN_VERSION);

	HookConVarChange(g_hInterval, ConVarChange_Interval);
	HookConVarChange(g_hAutoDelay, ConVarChange_AutoDelay);


}

public OnMapStart() {
	if (GetConVarBool(g_hEnabled)){
		g_hAutoTimer = CreateTimer(GetConVarInt(g_hInterval) * 1.0, Timer_DisplayAutoRules, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);	
	}
}

public ConVarChange_Interval(Handle:convar, const String:oldValue[], const String:newValue[]) {
	if (GetConVarBool(g_hEnabled)){
		if (g_hAutoTimer == INVALID_HANDLE) {
			g_hAutoTimer = CreateTimer(GetConVarInt(g_hInterval) * 1.0, Timer_DisplayAutoRules, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);	
		} else {
			KillTimer(g_hAutoTimer);
			g_hAutoTimer = INVALID_HANDLE;
		}
	}
}

public ConVarChange_AutoDelay(Handle:convar, const String:oldValue[], const String:newValue[]) {
	if (GetConVarBool(g_hEnabled)){
		if (g_hAutoTimer == INVALID_HANDLE) {
			g_hAutoTimer = CreateTimer(GetConVarInt(g_hInterval) * 1.0, Timer_DisplayAutoRules, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);	
		} else {
			KillTimer(g_hAutoTimer);
			g_hAutoTimer = INVALID_HANDLE;
		}
	}
}

public OnClientPutInServer(client) {
	if (GetConVarBool(g_hEnabled)){
		if (GetConVarBool(g_hHowTo)) {
			CreateTimer(GetConVarInt(g_hHowToDelay) * 1.0, Timer_HowToMessage, client);
		}
	}
}

public Action:Timer_HowToMessage(Handle:timer, any:client) {
	if (GetConVarBool(g_hHowTo)) {
		if (IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client)) {
			decl String:sClientName[32];
			GetClientName(client, sClientName, sizeof(sClientName));
			#if defined USECOLORS
				CPrintToChatEx(client, client, "%t", "Welcome_message" , sClientName);
			#else
				PrintToChat(client, "%t", "Welcome_message", sClientName);
			#endif
		}
	}
	return Plugin_Handled;
}


public Action:Command_PrintRulesToChat(client, args) {
	if (IsPlaying(client)) {
		DisplayRulesToClient(client);
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action:DisplayRulesToClient(client) {
	decl String:sFile[256], String:sPath[256], String:sClientLangCode[3], String:sClientLangName[256], String:sSectionName[64];
	// Get the Client's language
	GetLanguageInfo(GetClientLanguage(client), sClientLangCode, sizeof(sClientLangCode), sClientLangName, sizeof(sClientLangName));
	new Handle:g_hRules = CreateKeyValues("Phrases");
	// Get the File name and Search for the file
	GetConVarString(g_hRulesFile, sFile, sizeof(sFile));
	BuildPath(Path_SM, sPath, sizeof(sPath), "%s/%s", sFileDir ,sFile);

	if (FileExists(sPath)) {
		FileToKeyValues(g_hRules, sPath);
		// Moves to the FIRST SubKey level before reading
		KvGotoFirstSubKey(g_hRules);
		// Loop for reading all the Rules 
		do 
		{
			// Get the Section's Name to use it for getting translations 
			KvGetSectionName(g_hRules, sSectionName, sizeof(sSectionName));
			// Send the rule text to client's message queue if the current section name contains "Rule"
			if (StrContains(sSectionName, "Rule", true) != -1 ) {
				AddMsgToQueue(client, sSectionName);
			} 
		} while (KvGotoNextKey(g_hRules));
	} else {
		SetFailState("File Not Found (client) : %s", sPath);
		return Plugin_Handled;
	}
	if (g_hRules != INVALID_HANDLE) {
		CloseHandle(g_hRules);
	}
	return Plugin_Handled;
}

public Action:Timer_DisplayAutoRules(Handle:timer) {
	new Handle:g_hAllRules = CreateKeyValues("Phrases");
	decl String:sFile[256], String:sPath[256], String:sSectionName2[256];
	// Search for the file
	GetConVarString(g_hRulesFile, sFile, sizeof(sFile));
	BuildPath(Path_SM, sPath, sizeof(sPath), "%s/%s", sFileDir ,sFile);
	
	if (FileExists(sPath)) {
		FileToKeyValues(g_hAllRules, sPath);
		// Moves to the first SubKey before reading
		KvGotoFirstSubKey(g_hAllRules);
		// Loop for reading all rules
		do
		{
			KvGetSectionName(g_hAllRules, sSectionName2, sizeof(sSectionName2));
			if (StrContains(sSectionName2, "Rule", true) != -1 ) {
				AddMsgToAllQueue(sSectionName2);
			}
		} while (KvGotoNextKey(g_hAllRules));
	} else {
		SetFailState("File Not Found (all): %s", sPath);
	}
	if (g_hAllRules != INVALID_HANDLE) {
		CloseHandle(g_hAllRules);
	}
	return Plugin_Handled;
}

// This function checks if the client is a player or not.
stock bool:IsPlaying(client)
{
    if ((client > 0 && client <= MaxClients) && IsClientInGame(client) && !IsFakeClient(client)) return true;
    else return false;
}  

// This function adds a message to the client's message queue.
stock bool:AddMsgToQueue(iClient, const String:szSectionName[], any:...) {
	if (!IsClientInGame(iClient)) {
		return false;
	}
	PushArrayCell(g_hUserIdQueue, GetClientUserId(iClient));
	PushArrayString(g_hSectionName, szSectionName);
	if (g_hMsgTimer == INVALID_HANDLE) {
        g_hMsgTimer = CreateTimer(GetConVarFloat(g_hDelay) * 1.0, Timer_SendMsg, _, TIMER_REPEAT);
    }
	return true;
}

// This function adds a message to the client's message queue.
stock bool:AddMsgToAllQueue(const String:szSectionName2[],any:...) {
	PushArrayString(g_hSectionName2, szSectionName2);
	if (g_hMsgTimer2 == INVALID_HANDLE) {
		g_hMsgTimer2 = CreateTimer(GetConVarFloat(g_hAutoDelay) * 1.0, Timer_SendMsgToAll, _, TIMER_REPEAT);
    }
	return true;
}

// Reads the client's Message queue ans send it's content to the Chat for the client.
public Action:Timer_SendMsg(Handle:timer) {
	if (!GetArraySize(g_hSectionName)) {
		g_hMsgTimer = INVALID_HANDLE;
		return Plugin_Stop;
	}
	new String:szSectionName[250];
	GetArrayString(g_hSectionName, 0, szSectionName, sizeof(szSectionName));
	new iClient = GetClientOfUserId(GetArrayCell(g_hUserIdQueue, 0));
	if (IsPlaying(iClient)) {
		#if defined USECOLORS
			CPrintToChatEx(iClient, iClient, "%t", szSectionName);
		#else
			PrintToChat(iClient, "%t", szSectionName);
		#endif		
    }
	RemoveFromArray(g_hUserIdQueue, 0);
	RemoveFromArray(g_hSectionName, 0);
	return Plugin_Handled;
}  

// Reads the Message queue ans send it's content to the Chat for all the clients.
public Action:Timer_SendMsgToAll(Handle:timer) {
	if (!GetArraySize(g_hSectionName2)) {
		g_hMsgTimer2 = INVALID_HANDLE;
		return Plugin_Stop;
	}
	new String:szSectionName2[250];
	GetArrayString(g_hSectionName2, 0, szSectionName2, sizeof(szSectionName2));
	#if defined USECOLORS
		CPrintToChatAll("%t", szSectionName2);
	#else
		PrintToChatAll("%t", szSectionName2);
	#endif		
	RemoveFromArray(g_hSectionName2, 0);
	return Plugin_Continue;
}  
