#include <sourcemod>

// Cvar
new Handle:g_cvar_file = INVALID_HANDLE;

public Plugin:myinfo =
{
    name = "Autoresponder",
    author = "Russianeer",
    description = "Displays chat advertisements when specified text is said in player chat.",
    version = "1.0",
    url = "http://www.protf2.com/"
};

public OnPluginStart( )
{
	// Commands
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_Say);
	
	// Cvars
	g_cvar_file = CreateConVar("sm_chat_file", "chat_responses.txt", "Name of the file that contains all the advertisements");
}

public Action:Command_Say(client, args)
{
	new String:text[192];
	new String:buffers[3][64];
	new startidx = 0;
	
	GetCmdArgString(text, sizeof(text));

	if (text[0] == '"') {/* Strip the ending quote, if there is one */
		startidx = 1; 
		new len = strlen(text);
		if (text[len-1] == '"') {
			text[len-1] = '\0';
		}
	}

	ExplodeString( text[startidx], " ", buffers, 3, 64 ); 

	decl String:output[256];
	if(LoadAds(text[startidx], output, sizeof(output)))
	{
		if(StrContains(output, "{GREEN}") != -1)
			ReplaceString(output, sizeof(output), "{GREEN}", "\x04");
		if(StrContains(output, "{OLIVE}") != -1)
			ReplaceString(output, sizeof(output), "{OLIVE}", "\x05");
		if(StrContains(output, "{TEAM}") != -1)
			ReplaceString(output, sizeof(output), "{TEAM}", "\x03");
		if(StrContains(output, "{DEFAULT}") != -1)
			ReplaceString(output, sizeof(output), "{DEFAULT}", "\x01");
			
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientConnected(i) && IsClientInGame(i))
				SayText2(i, output);
		}
	}
	return Plugin_Continue;
}

bool:LoadAds(const String:command[], String:output[], maxlength)
{
	new Handle:kv = CreateKeyValues("ChatResponses");
	
	decl String:file[256], String:path[256];
	GetConVarString(g_cvar_file, file, sizeof(file));
	BuildPath(Path_SM, path, sizeof(path), "configs/%s", file);
	
	if(FileExists(path))
		FileToKeyValues(kv, path);
	else
	{
		SetFailState("File was not found: %s", path);
		return false;
	}
		
	if(!KvJumpToKey(kv, command))
		return false;
	
	KvGetString(kv, "text", output, maxlength);
	CloseHandle(kv);
	return true;
}

SayText2(to, const String:message[]) 
{
	new Handle:hBf = StartMessageOne("SayText2", to);
	
	if (hBf != INVALID_HANDLE) 
	{
		BfWriteByte(hBf, to);
		BfWriteByte(hBf, true);
		BfWriteString(hBf, message);
		
		EndMessage();
	}
}