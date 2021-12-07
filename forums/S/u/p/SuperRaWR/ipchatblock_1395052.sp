#pragma semicolon 1

#include <sourcemod>
#include <regex>

#define PLUGIN_VERSION		"1.4"

new Handle:ipcb_Enabled = INVALID_HANDLE;
new Handle:ipcb_WhitelistTrie = INVALID_HANDLE;
new Handle:ipcb_Regex = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "IP Chat Block",
	author = "SuperRaWR",
	description = "Blocks people from posting an IP address in chat.",
	version = PLUGIN_VERSION,
	url = "http://www.wdzclan.com"
};

public OnPluginStart()
{
	LoadTranslations("common.phrases");	
	CreateConVar("sm_ipchatblock_version", PLUGIN_VERSION, "IP Chat Block Version", FCVAR_NOTIFY | FCVAR_DONTRECORD | FCVAR_CHEAT);
	RegAdminCmd("sm_ipchatblock_reload", Command_ReloadWhitelist, ADMFLAG_ROOT, "Reloads the whitelist config file for IP's allowed to be said in chat.");
	ipcb_Enabled = CreateConVar("sm_ipchatblock_enabled", "1", "Enable/Disable IP Chat Block plugin (1/0)", 0, true, 0.0, true, 1.0);
		
	RegConsoleCmd("say", Command_SayChat);
	RegConsoleCmd("say_team", Command_SayChat);
	
	ipcb_Regex = CompileRegex("\\d+\\.\\d+\\.\\d+\\.\\d+(:\\d+)?");
	
	CreateWhitelistTrie();
}

//Hook say, and say_team command
public Action:Command_SayChat(client, args)
{	
	if (GetConVarBool(ipcb_Enabled) && client > 0 && (GetUserFlagBits(client) <= 0)) {
		decl String:text[192];
		GetCmdArgString(text, sizeof(text));
		//Regular Expression for an IP address
		if (MatchRegex(ipcb_Regex, text) > 0) {			
			GetRegexSubString(ipcb_Regex, 0, text, 32);		
			//An IP was posted, log action and block say command with Plugin_Handled
			
			if (ipcb_WhitelistTrie == INVALID_HANDLE) { //Not using a whitelist, but we're blocking IP's anyways...				
				LogAction(client, -1, "IP in text chat was blocked!");
				return Plugin_Handled;				
			} else if (!GetTrieString(ipcb_WhitelistTrie, text, text, sizeof(text))) { //Using a whitelist, not on whitelist, so block.			
				LogAction(client, -1, "IP in text chat was blocked!");
				return Plugin_Handled;
			} 
		}			
	}
	return Plugin_Continue;	
}

//Functions for IP whitelist support

CreateWhitelistTrie()
{	
	
	decl String:strBuffer[256];
	BuildPath(Path_SM, strBuffer, sizeof(strBuffer), "configs/ipcb_whitelist.txt");	
	if(FileExists(strBuffer)) {
		decl String:strBuffer2[256];
		ipcb_WhitelistTrie = CreateTrie();
		//Parse keyvalues to build whitelist trie
		new Handle:hKeyValues = CreateKeyValues("ipcb_keyvalues");
		if(FileToKeyValues(hKeyValues, strBuffer) == true)
		{
			KvGetSectionName(hKeyValues, strBuffer, sizeof(strBuffer));
			if (StrEqual("ipcb_whitelist", strBuffer) == true)
			{				
				if (KvGotoFirstSubKey(hKeyValues))
				{
					do
					{
						KvGetString(hKeyValues, "ip", strBuffer2, sizeof(strBuffer2));
						SetTrieString(ipcb_WhitelistTrie, strBuffer2, strBuffer2, false);
					}				
					while (KvGotoNextKey(hKeyValues));
					KvGoBack(hKeyValues);
				}
			}		
			
		}
	} else {
		LogError("IP Chat Block Whitelist Config file not found.");
	}	
}

public Action:Command_ReloadWhitelist(client, args)
{
	
	if (ipcb_WhitelistTrie != INVALID_HANDLE) { //Ensure that the trie exists (e.g. a file was loaded previous) before trying to clear it!
		//Reset Trie
		ClearTrie(ipcb_WhitelistTrie);
	}
	CreateWhitelistTrie();	
}