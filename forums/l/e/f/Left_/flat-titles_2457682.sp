#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <chat-processor>
#include <adt_array>

static char filepath[PLATFORM_MAX_PATH];
static ArrayList Titles; 
public Plugin myinfo =
{
	name = "Flat Titles",
	author = "Left",
	description = "Instead of using a database to store titles, it uses a flat file (plaintext)",
	version = "1.0",
	url = "http://steamcommunity.com/id/pylo/"
}

public void OnPluginStart()
{
	CreateDirectory("addons/sourcemod/data", 3);
	BuildPath(Path_SM, filepath, sizeof(filepath), "data/flat-titles.txt");
}

public void OnPluginEnd()
{
	ClearArray(Titles);
}

public void OnMapStart()
{
	Titles = CreateArray(64);
	LoadTitles();
}

public void LoadTitles()
{
	//Reads Titles.txt and pushes all the lines into an ArrayList
	File file = OpenFile(filepath, "r");
	int length;
	char line[32];
	ClearArray(Titles);	
	
	if (file == null)
	{
		PrintToServer("Cannot load Titles.txt");
		return;
	}
	
	while (!IsEndOfFile(file))
	{
		ReadFileLine(file, line, sizeof(line));

		length = strlen(line);
		
		if (line[length-1] == '\n')
		{
			line[--length] = '\0';
		}
		
		if (line[0] != '/' && line[1] != '/')
		{
			PushArrayString(Titles, line);
		} else {
			continue;
		}
	}
	CloseHandle(file);
}

public bool getTitle(int& client, char[] title, int maxlen)
{
	//Gets the SteamID from clientID and matches it to the ArrayList, if a match is found, 
	// titles will be set to the equivalent title.
	// Returns true if successful and false if none found
	char line[64];
	char pTitle[2][32];
	char SteamID[32];
	int index;
	GetClientAuthId(client, AuthId_Steam2, SteamID, 32);
	index = FindPartialStringInArray(Titles, SteamID);
	if (index < 0)
	{
		return false;
	} else {
		char activeTitle[32];
		GetArrayString(Titles, index, line, 64);
		ExplodeString(line, " = ", pTitle,2,32);
		activeTitle = pTitle[1];
		Format(title, maxlen, activeTitle);
		return true;
	}

}

int FindPartialStringInArray(ArrayList array, char[] item)
{
	//Returns the index of the array where the item is a partial match to the whole string
	//e.g. "Hello, World","Dog is cat" will return 0 if item = "rld"
	//
	//Will return -1 if not found
	char string[64];
	for (int i = 0; i < array.Length;i++)
	{
		GetArrayString(array, i, string, 64);
		if (StrContains(string, item, false) >= 0)
		{
			return i;
		}
	} 
	return -1;
}

public Action OnChatMessage(int& author, ArrayList recipients, eChatFlags& flag, char[] name, char[] message, bool& bProcessColors, bool& bRemoveColors)
{
	static char title[32];
	getTitle(author, title, 32);
	Format(name, MAXLENGTH_NAME,"{orange}%s{teamcolor} %s", title, name);
	Format(message, MAXLENGTH_MESSAGE, "{white}%s", message);
	return Plugin_Changed;
}

public void OnChatMessagePost(int author, ArrayList recipients, eChatFlags flag, const char[] name, const char[] message, bool bProcessColors, bool bRemoveColors)
{
	PrintToServer("[FlatTitles] %s: %s [%b/%b]", name, message, bProcessColors, bRemoveColors);
}
