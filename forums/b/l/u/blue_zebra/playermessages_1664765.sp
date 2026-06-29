#include <sourcemod>

new Handle:trie = INVALID_HANDLE;

public Plugin:myinfo =
{
    name = "Messages to Players",
    author = "Doodil",
};

public OnPluginStart()
{
	trie = CreateTrie();
	decl String:path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM,path,PLATFORM_MAX_PATH,"configs/playermessages.cfg");
	new Handle:file = OpenFile(path, "r");
	new String:line[255];
	new String:temp[255];
	if (file == INVALID_HANDLE)
	{
		PrintToServer("messages.cfg not found!");
	}
	else
	{
		while(!IsEndOfFile(file) && ReadFileLine(file, line, sizeof(line)))
        {
			if(StrContains(line,"STEAM_",false)>=0)
			{
				temp=line;
				TrimString(temp);
				ReadFileLine(file,line,sizeof(line));
				SetTrieString(trie,temp,line);
			}
		}
	}
	CloseHandle(file);
}

public OnClientPutInServer(client)
{
	new String:auth[255];
	GetClientAuthString(client, auth, sizeof(auth));
	new String:message[255];
	TrimString(auth);

	if(GetTrieString(trie,auth,message,sizeof(message)))
	{
		PrintToChat(client,message);
	}
}

public OnPluginEnd()
{
	CloseHandle(trie);
}
