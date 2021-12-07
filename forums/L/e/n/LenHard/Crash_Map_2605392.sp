#include <sourcemod>

#pragma newdecls required
#pragma semicolon 1

bool gB_Late;

public Plugin myinfo =
{
	name = "[Any] Crash Map",
	author = "LenHard",
	description = "Changes the map back to where it was after crash.",
	version = "1.0",
	url = "http://steamcommunity.com/id/TheOfficalLenHard/"
};

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErr_max)
{
	gB_Late = bLate;
	return APLRes_Success;
}

public void OnPluginStart()
{
	if (gB_Late)
		return;
		
	char[] sPath = new char[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, PLATFORM_MAX_PATH, "logs/map.txt");
	
	File fFile = OpenFile(sPath, "r");
	
	if (fFile != null)
	{
		char[] sLine = new char[100];
		fFile.ReadLine(sLine, 100);
		ReplaceString(sLine, 100, "\n", "");

		if (IsMapValid(sLine)) 
		{
			DataPack hPack = new DataPack();
			CreateDataTimer(1.0, Timer_ChangeMap, hPack); 
			hPack.WriteString(sLine);
			hPack.Reset();
		}
	}
}

public void OnConfigsExecuted()
{
	char[] sMap = new char[100];
	GetCurrentMap(sMap, 100);
	
	char[] sPath = new char[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, PLATFORM_MAX_PATH, "logs/map.txt");
	
	File fFile = OpenFile(sPath, "w");
	fFile.WriteLine(sMap);
	fFile.Close();
}

public Action Timer_ChangeMap(Handle hTimer, DataPack hPack)
{
	char[] sMap = new char[100];
	hPack.ReadString(sMap, 100);	
	
	ForceChangeLevel(sMap, "Server crashed, changing it back...");
	LogMessage("Changing the map back to \"%s\" due to crashing.", sMap);
}