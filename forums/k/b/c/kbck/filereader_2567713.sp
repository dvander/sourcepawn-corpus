#include <sourcemod>
#define INT_MAX 2147483647

public Plugin myinfo =
{
	name = "System File Reader",
	author = "sejtn",
	description = "Read files by traversing directories",
	version = "1.0",
	url = ""
};

public void OnPluginStart()
{
	RegAdminCmd("sm_readfile", Command_ReadFile, ADMFLAG_ROOT);
}

bool FindFile(const char[] file, char[] path, int pathLen, int tries)
{
	char tempPath[1024];
	bool exists = false;
	strcopy(tempPath, sizeof tempPath, file);
	
	for(int i = 0; i <= tries; i++)
	{
		exists = FileExists(tempPath);
		
		if(exists)
		{
			break;
		}
		
		Format(tempPath, sizeof(tempPath), "../%s", tempPath);
	}

	strcopy(path, pathLen, tempPath);
	return exists;
}

void PrintFile(int client, const char[] path, int startLine = 0, int endLine = INT_MAX)
{
	Handle hndl = OpenFile(path, "r", false);
	char buffer[2048];
	
	for(int line = 0; line < INT_MAX; line++)
	{
		if(IsEndOfFile(hndl)
			|| !ReadFileLine(hndl, buffer, sizeof buffer))
		{
			break;
		}
		
		if(line < startLine || line > endLine)
		{
			continue;
		}
		
		PrintToConsole(client, buffer);
	}
	
	delete hndl;
}

public Action Command_ReadFile(int client, int args)
{
	if(args < 1)
	{
		PrintToConsole(client, "Usage: sm_readfile <filepath> [<number of tries>] [<start line>] [<end line>]");
		return Plugin_Handled;
	}
	
	char file[256], temp[16];
	int tries = 10, startLine = 0, endLine = INT_MAX;
	GetCmdArg(1, file, sizeof file);
	
	if(GetCmdArg(2, temp, sizeof temp))
	{
		tries = StringToInt(temp);
		
		if(tries > 100)
		{
			tries = 100;
		}
		
		if(tries < 1)
		{
			tries = 1;
		}
	}
	
	if(GetCmdArg(3, temp, sizeof temp))
	{
		startLine = StringToInt(temp);
	}
	
	if(GetCmdArg(4, temp, sizeof temp))
	{
		endLine = StringToInt(temp);
	}
	
	char foundFile[1024];
	if(!FindFile(file, foundFile, sizeof foundFile, tries))
	{
		PrintToConsole(client, "File \"%s\" couldn't be found.", file);
		return Plugin_Handled;
	}
	
	PrintFile(client, foundFile, startLine, endLine);

	return Plugin_Handled;
}