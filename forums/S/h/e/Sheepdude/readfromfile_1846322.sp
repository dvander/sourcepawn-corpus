#include <sourcemod>
#pragma semicolon 1

new String:textfile[128][128];
new linecount;

public OnPluginStart()
{
	RegConsoleCmd("sm_find", FindLine);
	ReadTextFile();
}

ReadTextFile()
{
	new Handle:file = OpenFile("file.txt", "r");
	linecount = 0;
	while(!IsEndOfFile(file))
	{
		ReadFileLine(file, textfile[linecount], sizeof(textfile[]));
		TrimString(textfile[linecount]);
		linecount++;
	}
}

public Action:FindLine(client, args)
{
	decl String:clientName[MAX_NAME_LENGTH+1];
	GetClientName(client, clientName, sizeof(clientName));
	for(new i = 0; i < linecount; i++)
	{
		if(StrContains(textfile[i], clientName, false) != -1)
		{
			ReplyToCommand(client, textfile[i]);
			break;
		}
	}
}