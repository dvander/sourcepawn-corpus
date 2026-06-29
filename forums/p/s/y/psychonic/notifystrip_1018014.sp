#pragma semicolon 1
#include <sourcemod>

#define CR '\r'
#define LF '\n'
#define TAB '\t'
#define SPACE ' '
#define COMMENT '/'

public Plugin:myinfo =
{
	name = "Orangebox Notify Cvar Cleanup",
	author = "psyduck",
	description = "Strips FCVAR_NOTIFY flags from cvars that don't need it.",
	version = "1.0",
	url = "http://nicholashastings.com"
};

public OnPluginStart()
{
	decl String:szStripListPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, szStripListPath, sizeof(szStripListPath), "configs/notifystrip.txt");
	new Handle:hStriplist = OpenFile(szStripListPath, "r");
	if (hStriplist == INVALID_HANDLE)
	{
		SetFailState("File configs/notifystrip.txt Not Found");
	}
	
	do
	{
		decl String:szCvar[128];
		ReadFileLine(hStriplist, szCvar, sizeof(szCvar));
		
		// skip on comments and blank lines
		new firstchar = szCvar[0];
		if (firstchar == 0
			|| firstchar == COMMENT
			|| firstchar == LF
			|| firstchar == CR
			|| firstchar == SPACE
			|| firstchar == TAB
		)
		{
			continue;
		}
		
		//strip newlines
		for (new i = 0; i < sizeof(szCvar); i++)
		{
			new char = szCvar[i];
			if (char == 0)
			{
				break;
			}
			if (char == COMMENT
				|| char == LF
				|| char == CR
				|| char == SPACE
				|| char == TAB
			)
			{
				szCvar[i] = 0;
				break;
			}
		}
		
		new Handle:hCvar = FindConVar(szCvar);
		if (hCvar != INVALID_HANDLE)
		{
			SetConVarFlags(hCvar, GetConVarFlags(hCvar) & ~FCVAR_NOTIFY);
		}
		
	} while (!IsEndOfFile(hStriplist));
	
	CloseHandle(hStriplist);
}