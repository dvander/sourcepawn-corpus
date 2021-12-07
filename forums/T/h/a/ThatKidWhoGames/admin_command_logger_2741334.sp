#include <sourcemod>

ConVar g_cvSmOnly = null;

char g_sLogFile[PLATFORM_MAX_PATH];

public void OnPluginStart()
{
	g_cvSmOnly = CreateConVar("sm_admin_command_logger_sm_only", "1", "Only log commands starting with sm_", _, true, 0.0, true, 1.0);

	BuildPath(Path_SM, g_sLogFile, sizeof(g_sLogFile), "logs/admin_commands.txt");

	AddCommandListener(Command_Listener);
}

public Action Command_Listener(int iClient, const char[] sCommand, int iArgC)
{
	if (CheckCommandAccess(iClient, "sm_admin", ADMFLAG_GENERIC) && !(g_cvSmOnly.BoolValue && StrContains(sCommand, "sm_", false) == -1))
	{
		if (iArgC > 0)
		{
			char sArgString[256];
			GetCmdArgString(sArgString, sizeof(sArgString));

			LogToFile(g_sLogFile, "\"%L\" used command (\"%s %s\")", iClient, sCommand, sArgString);
		}
		else
		{
			LogToFile(g_sLogFile, "\"%L\" used command (\"%s\")", iClient, sCommand);
		}
	}

	return Plugin_Continue;
}