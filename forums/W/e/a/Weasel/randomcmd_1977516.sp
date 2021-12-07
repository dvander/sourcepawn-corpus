#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define MAX_CMD_LENGTH 128
#define SIZE_OF_INT 2147483647

public Plugin:myinfo = {
	name = "Random Command",
	author = "./Moriss",
	description = "Random Command Picker",
	version = "1.0",
	url = "http://moriss.adjustmentbeaver.com"
}

public OnPluginStart()
{
	RegAdminCmd("sm_random", Command_RandomCmd, ADMFLAG_GENERIC);
}

public Action:Command_RandomCmd(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_random <filename>");
		return Plugin_Handled;
	}

	decl String:szFile[PLATFORM_MAX_PATH];
	GetCmdArgString(szFile, PLATFORM_MAX_PATH);
	StripQuotes(szFile);
	
	new Handle:hCommandList = CreateArray(PLATFORM_MAX_PATH, 0);
	
	new Handle:hFile = OpenFile(szFile, "r");

	if (hFile == INVALID_HANDLE)
	{
		ReplyToCommand(client, "[SM] Cannot open file \"%s\". Maybe file doesn't exist.", szFile);
		return Plugin_Handled;
	}

	decl String:szBuffer[MAX_CMD_LENGTH];
	Format(szBuffer, MAX_CMD_LENGTH, "");

	while (!IsEndOfFile(hFile))
	{
		ReadFileLine(hFile, szBuffer, MAX_CMD_LENGTH);
		TrimString(szBuffer);
		if ((strlen(szBuffer) > 0) && (StrContains(szBuffer, "//") == -1))
			PushArrayString(hCommandList, szBuffer);
	}

	CloseHandle(hFile);

	new iSize = GetArraySize(hCommandList);
	if (iSize < 1)
	{
		ReplyToCommand(client, "[SM] The file \"%s\" doesn't contain valid data.", szFile);
		return Plugin_Handled;
	}

	new iRandom = GetTrueRandomInt(1, iSize)-1;
	GetArrayString(hCommandList, iRandom, szBuffer, MAX_CMD_LENGTH);

	CloseHandle(hCommandList);

	if (client == 0)
	{
		ServerCommand(szBuffer);
	}
	else
	{
		FakeClientCommand(client, szBuffer);
	}

	ReplyToCommand(client, "[SM] The picked command is: %s", szBuffer);

	return Plugin_Handled;
}

// This function is from SMLIB
stock GetTrueRandomInt(iMin, iMax)
{
	new iRandom = GetURandomInt();
	
	if (iRandom == 0)
		iRandom++;

	return RoundToCeil(float(iRandom) / (float(SIZE_OF_INT) / float(iMax - iMin + 1))) + iMin - 1;
}