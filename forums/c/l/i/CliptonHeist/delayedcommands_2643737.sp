#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

char g_sFilePath[256];

public Plugin myinfo = 
{
    name = "Delayed Command Exec", 
    author = "The Doggy", 
    description = "Executes commands x seconds after round start", 
    version = "1.0.0",
    url = "coldcommunity.com"
};

public void OnPluginStart()
{
	BuildPath(Path_SM, g_sFilePath, sizeof(g_sFilePath), "data/delayedcommands.txt");
	HookEvent("round_start", Event_RoundStart);
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	// Does file exist?
	if(!FileExists(g_sFilePath))
	{
		LogError("Delayed commands file %s does not exist!", g_sFilePath);
		return;
	}

	// Open file to read
	File fCommandFile = OpenFile(g_sFilePath, "r");

	// Do this until we reach the end of the file
	while(!fCommandFile.EndOfFile())
	{
		float fTime;
		char sCurrentLine[64], sBuffer[2][64];

		fCommandFile.ReadLine(sCurrentLine, sizeof(sCurrentLine));

		// Get time and command arguments from readline
		ExplodeString(sCurrentLine, "\"", sBuffer, sizeof(sBuffer), sizeof(sBuffer[]));
		
		// Sanitize input
		StripQuotes(sBuffer[0]);
		StripQuotes(sBuffer[1]);
		TrimString(sBuffer[0]);
		TrimString(sBuffer[1]);

		// Replace single quotes with double quotes after 1st quote strip
		ReplaceString(sBuffer[1], sizeof(sBuffer[]), "'", "\"");

		// Get time delay for command
		fTime = StringToFloat(sBuffer[0]);

		// Check float is valid
		if(fTime == 0.0)
		{
			LogError("Error while reading file %s: file is not formatted correctly.", g_sFilePath);
			return;
		}

		// Create DataPack to pass command string to the timer
		DataPack commandPack = new DataPack();
		commandPack.WriteString(sBuffer[1]);

		CreateTimer(fTime, Timer_DelayedExec, commandPack);
	}

	fCommandFile.Close();
}

public Action Timer_DelayedExec(Handle hTimer, DataPack commandPack)
{
	// Get Command
	char sCommand[64];
	commandPack.Reset();
	commandPack.ReadString(sCommand, sizeof(sCommand));
	delete commandPack;

	// Execute Command
	ServerCommand(sCommand);
	LogMessage("DelayedCommands Executed Command %s", sCommand);

	return Plugin_Stop;
}