#include <sourcemod>
#include <scp>
#include <smlib>

Handle banned_word = INVALID_HANDLE;
Handle autorized_word = INVALID_HANDLE;
int word_index = 0;

public Plugin myinfo = 
{
	name = "Chat filter",
	author = "Arkarr",
	description = "Allow you to replace some unauthorized words in your server.",
	version = "1.0",
	url = "forums.alliedmodders.com"
}

public OnPluginStart()
{
	banned_word = CreateArray(64);
	autorized_word = CreateArray(64);
	
	RegAdminCmd("sm_reloadfilter", CMD_ReloadWords, ADMFLAG_SLAY, "Reload the chat filters.");
	
	int nbr_filter = ReloadWordList();
	
	if(nbr_filter == -1)
		PrintToServer("[CHAT FILTER] Error, chat_filter.cfg is probably missing !");
	else
		PrintToServer("[CHAT FILTER] Added %i banned words.", nbr_filter);
}

public Action OnChatMessage(&author, Handle recepients, char[] name, char[] message) 
{
	if (author > 0 && IsClientInGame(author))
	{
		char correctWord[64];
		char bannedWord[64];
		
		int tab_index = FindStringInArray(banned_word, message);
		while(tab_index != -1)
		{
			GetArrayString(banned_word, tab_index, bannedWord, sizeof(bannedWord));
			GetArrayString(autorized_word, tab_index, correctWord, sizeof(correctWord));
			ReplaceString(message, MAXLENGTH_INPUT, bannedWord, correctWord, false);
			tab_index = FindStringInArray(banned_word, message);
		}
		
		for (int i = 0; i < GetArraySize(banned_word); i++)
		{
			GetArrayString(banned_word, i, bannedWord, sizeof(bannedWord));
			GetArrayString(autorized_word, i, correctWord, sizeof(correctWord));
			ReplaceString(message, MAXLENGTH_INPUT, bannedWord, correctWord, false);
		}
		
		return Plugin_Changed;
	}
	return Plugin_Handled;
}

public Action CMD_ReloadWords(client, args)
{
	int nbr_filter = ReloadWordList();
	
	if(nbr_filter == -1)
	{
		if(client != 0)
			PrintToChat(client, "[CHAT FILTER] Error, chat_filter.cfg is probably missing !");
		else
			PrintToServer("[CHAT FILTER] Error, chat_filter.cfg is probably missing !");
	}
	else
	{
		if(client != 0)
			PrintToChat(client, "[CHAT FILTER] Added %i banned words.", nbr_filter);
		else
			PrintToServer("[CHAT FILTER] Added %i banned words.", nbr_filter);
	}
		
	return Plugin_Handled;
}

stock ReloadWordList()
{
	word_index = 0;
	ClearArray(banned_word);
	ClearArray(autorized_word);
	
	Handle kv = CreateKeyValues("Filter");
	FileToKeyValues(kv, "addons/sourcemod/configs/chat_filter.cfg");

	if (!KvGotoFirstSubKey(kv)) {
		return -1;
	}

	char word[255];
	char replace[255];

	do {
		KvGetString(kv, "word", word, sizeof(word));
		KvGetString(kv, "replace", replace, sizeof(replace));
		PushArrayString(banned_word, word);
		PushArrayString(autorized_word, replace);
		word_index++;
	} while (KvGotoNextKey(kv));

	CloseHandle(kv);
	
	return word_index;
}