//                          =======================================================================
//	                    |     Plugin By Tair Azoulay                                          |
//                          |                                                                     |
//                          |     Profile : http://steamcommunity.com/profiles/76561198013150925/ |                                         |
//                          |                                                                     |
//	                    |     Name : Grenades On Spawn                                        |
//                          |                                                                     |
//	                    |     Version : 1.0                                                   |
//                          |                                                                     |
//	                    |     Description : Players can report on bugs.                       |     
//                          =======================================================================


#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = 
{
	name = "Bug Report",
	author = "Tair",
	description = "players can report bugs.",
	version = "1.0",
	url = "Www.sourcemod.net"
}


public OnPluginStart()
{
	RegConsoleCmd("sm_bug", Command_BugReport);
	RegConsoleCmd("sm_bugreport", Command_BugReport);

}

public Action:Command_BugReport(client, args)
{

	if(args < 1)
	{
		ReplyToCommand(client, " \x04[SM] \x01Usage: sm_bug <Bug Info>");
		return Plugin_Handled;
	}

	new String:buginfo[64];
	GetCmdArg(1, buginfo, sizeof(buginfo));
        new String:date[50];
        new String:time[50];
	new String:szFile[256];
	BuildPath(Path_SM, szFile, sizeof(szFile), "configs/Bugs.ini");
        decl String:Name[32]; 
        GetClientName(client, Name, sizeof(Name));
  
	new String:Msg[256];
	GetCmdArgString(Msg, sizeof(Msg));
	Msg[strlen(Msg)-0] = '\0';
 
	new Handle:hFile = OpenFile(szFile, "at");
	FormatTime(date, 50, "%d/%m/%Y");
	FormatTime(time, 50, "%H:%M:%S");
        WriteFileLine(hFile, "----------------------");
	WriteFileLine(hFile, "Reporter : %s", Name);
        WriteFileLine(hFile, "Bug : %s", Msg);
        WriteFileLine(hFile, "Date : %s", date);
        WriteFileLine(hFile, "Time : %s", time);
        WriteFileLine(hFile, "----------------------");
        WriteFileLine(hFile, "                      ");
	PrintToChat(client, " \x04[Bug] \x01Thanks for your report !");
	CloseHandle(hFile);
	return Plugin_Handled;
}