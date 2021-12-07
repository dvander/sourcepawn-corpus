#pragma semicolon 1
#include <sourcemod>

public Plugin myinfo = 
{
	name = "block srcds banip",
	author = "bbs.93x.net",
	description = "<- Description ->",
	version = "1.0",
	url = "<- URL ->"
}



public void OnPluginStart()
{
	RegConsoleCmd("addip", DoBlock);
	RegConsoleCmd("banip", DoBlock);
	ClearIPBanned();
}
public Action DoBlock(int client, int args)
{
	return Plugin_Handled;
}

public void OnConfigsExecuted()
{
	ClearIPBanned();
}

stock void ClearIPBanned()
{
	//Clear IP Banned File cfg/banned_ip.cfg
	char path2[PLATFORM_MAX_PATH],line2[100];
	Format(path2,sizeof(path2),"cfg/banned_ip.cfg");
	if(FileExists(path2) && FileSize(path2) >= 1)
	{
		Handle fileHandle2=OpenFile(path2,"r"); 
		while(!IsEndOfFile(fileHandle2)&&ReadFileLine(fileHandle2,line2,sizeof(line2)))
		{
			if(!StrEqual(line2,"",false))
			{
				TrimString(line2);
				StripQuotes(line2);
				char strBreak2[3][64];
				ExplodeString(line2, " ", strBreak2, sizeof(strBreak2), sizeof(strBreak2[]));
				TrimString(strBreak2[2]);
				StripQuotes(strBreak2[2]);
				ServerCommand("sm_unban %s",strBreak2[2]);
				ServerCommand("removeip %s",strBreak2[2]);
				ServerCommand("writeip");
				LogMessage("Clear IP %s",strBreak2[2]);
			}
		}
		delete fileHandle2;
	}
}
