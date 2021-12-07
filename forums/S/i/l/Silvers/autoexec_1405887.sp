#pragma semicolon			1
#define MAX_CVARS			64

static String:g_sCvars[MAX_CVARS][64], g_iCvarCount;

public OnPluginStart()
{
	decl String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "data/autoexec.cfg");
	if( !FileExists(sPath) )
	{
		SetFailState("Error: Cannot load plugin because the vital data/autoexec.cfg is missing!");
	}

	new Handle:hFile = OpenFile(sPath, "r");	
	if( hFile == INVALID_HANDLE )
	{
		SetFailState("Error: Attempted to open data/autoexec.cfg but failed!");
	}

	decl String:sLine[64];
	while( !IsEndOfFile(hFile) && g_iCvarCount <= MAX_CVARS)
	{
		ReadFileLine(hFile, sLine, sizeof(sLine));
		TrimString(sLine);
		strcopy(g_sCvars[g_iCvarCount], sizeof(sLine), sLine);
		g_iCvarCount++;
	}

	CloseHandle(hFile);
	ExecCvars();
}


ExecCvars()
{
	for( new i = 0; i <= g_iCvarCount; i++ )
	{
		ServerCommand("%s", g_sCvars[i]);
	}
}