#include <sourcemod>

new Handle:Array_AuthID = INVALID_HANDLE;

new String:g_Filename[PLATFORM_MAX_PATH];

public APLRes AskPluginLoad2(Handle myself, bool bLate, char[] error, int length)
{
	CreateNative("IsHighManagement", Native_IsHighManagement);
}

// native bool IsHighManagement(int client)

public int Native_IsHighManagement(Handle caller, int numParams)
{
	new client = GetNativeCell(1);
	
	new String:AuthId[35];
	GetClientAuthId(client, AuthId_Engine, AuthId, sizeof(AuthId));
	
	return FindStringInArray(Array_AuthID, AuthId) != -1;
}
public OnPluginStart()
{		
	Array_AuthID = CreateArray(35);
	
	ReadHighManagement();
	
	AddCommandListener(Listener_ReloadAdmins, "sm_reloadadmins");
}

public Action:Listener_ReloadAdmins(client, const String:command[], args)
{
	if(!CheckCommandAccess(client, "sm_reloadadmins", ADMFLAG_GENERIC))
		return Plugin_Continue;
		
	ReadHighManagement();

	return Plugin_Continue;
}

ReadHighManagement()
{
	ClearArray(Array_AuthID);
	
	BuildPath(Path_SM, g_Filename, sizeof(g_Filename), "configs/high_management.ini");
	
	File file = OpenFile(g_Filename, "rt");
	
	if (!file)
	{
		UC_CreateEmptyFile(g_Filename);
		return;
	}
	
	while (!file.EndOfFile())
	{
		char line[255];
		if (!file.ReadLine(line, sizeof(line)))
			break;
		
		/* Trim comments */
		int len = strlen(line);
		bool ignoring = false;
		for (int i=0; i<len; i++)
		{
			if (ignoring)
			{
				if (line[i] == '"')
					ignoring = false;
			} else {
				if (line[i] == '"')
				{
					ignoring = true;
				} else if (line[i] == ';') {
					line[i] = '\0';
					break;
				} else if (line[i] == '/'
							&& i != len - 1
							&& line[i+1] == '/')
				{
					line[i] = '\0';
					break;
				}
			}
		}
		
		TrimString(line);
		
		if ((line[0] == '/' && line[1] == '/')
			|| (line[0] == ';' || line[0] == '\0'))
		{
			continue;
		}
	
		PushArrayString(Array_AuthID, line);
	}
	
	file.Close();
}

stock void UC_CreateEmptyFile(const char[] Path)
{
	CloseHandle(OpenFile(Path, "a"));
}
