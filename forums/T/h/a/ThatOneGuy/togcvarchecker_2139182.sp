#pragma semicolon 1
#define PLUGIN_VERSION "1.0.0"
#include <sourcemod>
#include <autoexecconfig>	//https://github.com/Impact123/AutoExecConfig or https://forums.alliedmods.net/showthread.php?p=1862459
#pragma newdecls required

ConVar g_cAccessFlag = null;
char g_sAccessFlag[120];

public Plugin myinfo =
{
	name = "TOG CVar Checker",
	author = "That One Guy",
	description = "Check CVar values of players",
	version = PLUGIN_VERSION,
	url = "http://www.togcoding.com"
}

public void OnPluginStart()
{
	AutoExecConfig_SetFile("togcvarchecker");
	AutoExecConfig_CreateConVar("togcvarchecker_version", PLUGIN_VERSION, "TOG CVar Checker: Version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	g_cAccessFlag = AutoExecConfig_CreateConVar("togcvar_accessflag", "", "Defines admin flag(s) for generic plugin use.", FCVAR_NONE);
	g_cAccessFlag.GetString(g_sAccessFlag, sizeof(g_sAccessFlag));
	g_cAccessFlag.AddChangeHook(OnCVarChange);
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();

	RegConsoleCmd("sm_checkcvar", Cmd_CheckCVar, "Check cvar value of a player.");
	RegConsoleCmd("sm_checkinfo", Cmd_CheckInfo, "Check replicated cvar info of a player.");
	RegConsoleCmd("sm_cvarlist", Cmd_CheckCVarList, "Check list of cvar values for a player.");
}

public void OnCVarChange(ConVar hCVar, const char[] sOldValue, const char[] sNewValue)
{
	if(hCVar == g_cAccessFlag)
	{
		g_cAccessFlag.GetString(g_sAccessFlag, sizeof(g_sAccessFlag));
	}
}

public Action Cmd_CheckCVar(int client, int iArgs)
{
	if(iArgs != 2)
	{
		ReplyToCommand(client, "Command Usage: sm_checkcvar <target> <cvar>");
		return Plugin_Handled;
	}
	
	if(IsValidClient(client))
	{
		if(!HasFlags(client, g_sAccessFlag))
		{
			ReplyToCommand(client, "You do not have access to this command!");
			return Plugin_Handled;
		}
	}
	
	char sTarget[65], sTargetName[MAX_TARGET_LENGTH], sCVar[65];
	GetCmdArg(1, sTarget, sizeof(sTarget));
	GetCmdArg(2, sCVar, sizeof(sCVar));
	int a_iTargets[MAXPLAYERS], iTargetCount;
	bool bTN_ML;
	if((iTargetCount = ProcessTargetString(sTarget, client, a_iTargets, MAXPLAYERS, COMMAND_FILTER_NO_IMMUNITY|COMMAND_FILTER_NO_BOTS, sTargetName, sizeof(sTargetName), bTN_ML)) <= 0)
	{
		ReplyToCommand(client, "Not found or invalid parameter.");
		return Plugin_Handled;
	}
	
	if(IsValidClient(client))
	{
		PrintToChat(client, "[TOGs CVar Checker] Check console for output!");
		PrintToConsole(client, "=============================== TOGs CVar Checker ===============================");
	}
	
	for(int i = 0; i < iTargetCount; i++)
	{
		int target = a_iTargets[i];
		if(IsValidClient(target))
		{
			QueryClientConVar(target, sCVar, view_as<ConVarQueryFinished>(CVarQueryCB), GetClientUserId(client));
		}
	}
	return Plugin_Handled;
}

public int CVarQueryCB(QueryCookie hCookie, int target, ConVarQueryResult result, const char[] sCVar, const char[] sCVarValue, int iUserID)
{
	int client = GetClientOfUserId(iUserID);
	char sMsg[128];
	if(hCookie == QUERYCOOKIE_FAILED)
	{
		Format(sMsg, sizeof(sMsg), "Query cookie failed!");
	}
	else if(result == ConVarQuery_NotFound)
	{
		Format(sMsg, sizeof(sMsg), "CVar not found!");
	}
	else if(result == ConVarQuery_NotValid)
	{
		Format(sMsg, sizeof(sMsg), "Argument is not a CVar. Console command found with same name.");
	}
	else if(result == ConVarQuery_Protected)
	{
		Format(sMsg, sizeof(sMsg), "CVar is protected! Value cannot be retrieved.");
	}
	else
	{
		Format(sMsg, sizeof(sMsg), "%N's CVar value: %s = %s", target, sCVar, sCVarValue);
	}
	
	if(IsValidClient(client))
	{
		PrintToConsole(client, sMsg);
	}
	else
	{
		LogToGame(sMsg);
	}
}

public Action Cmd_CheckInfo(int client, int iArgs)
{
	if(iArgs != 2)
	{
		ReplyToCommand(client, "Command Usage: sm_checkinfo <target> <cvar>");
		return Plugin_Handled;
	}
	
	if(IsValidClient(client))
	{
		if(!HasFlags(client, g_sAccessFlag))
		{
			ReplyToCommand(client, "You do not have access to this command!");
			return Plugin_Handled;
		}
	}
	
	char sTarget[65], sTargetName[MAX_TARGET_LENGTH], sCVar[65], sMsg[128];
	GetCmdArg(1, sTarget, sizeof(sTarget));
	GetCmdArg(2, sCVar, sizeof(sCVar));
	int a_iTargets[MAXPLAYERS], iTargetCount;
	bool bTN_ML;
	if((iTargetCount = ProcessTargetString(sTarget, client, a_iTargets, MAXPLAYERS, COMMAND_FILTER_NO_IMMUNITY|COMMAND_FILTER_NO_BOTS, sTargetName, sizeof(sTargetName), bTN_ML)) <= 0)
	{
		ReplyToCommand(client, "Not found or invalid parameter.");
		return Plugin_Handled;
	}
	
	if(IsValidClient(client))
	{
		PrintToChat(client, "[TOGs CVar Checker] Check console for output!");
		PrintToConsole(client, "=============================== TOGs CVar Checker ===============================");
	}
	
	for(int i = 0; i < iTargetCount; i++)
	{
		int target = a_iTargets[i];
		if(IsValidClient(target))
		{
			char sCVarValue[128];
			if(GetClientInfo(target, sCVar, sCVarValue, sizeof(sCVarValue)))
			{
				Format(sMsg, sizeof(sMsg), "%N's CVar value: %s = %s", target, sCVar, sCVarValue);
				if(IsValidClient(client))
				{
					PrintToConsole(client, sMsg);
				}
				else
				{
					LogToGame(sMsg);
				}
			}
			else
			{
				ReplyToCommand(client, "Unable to retrieve client info!");
			}
		}
	}
	return Plugin_Handled;
}

public Action Cmd_CheckCVarList(int client, int iArgs)
{
	if(iArgs != 1)
	{
		ReplyToCommand(client, "Command Usage: sm_cvarlist <target>");
		return Plugin_Handled;
	}
	
	if(IsValidClient(client))
	{
		if(!HasFlags(client, g_sAccessFlag))
		{
			ReplyToCommand(client, "You do not have access to this command!");
			return Plugin_Handled;
		}
	}
	
	char sTarget[65], sTargetName[MAX_TARGET_LENGTH], sCVar[65];
	GetCmdArg(1, sTarget, sizeof(sTarget));
	GetCmdArg(2, sCVar, sizeof(sCVar));
	int a_iTargets[MAXPLAYERS], iTargetCount;
	bool bTN_ML;
	if((iTargetCount = ProcessTargetString(sTarget, client, a_iTargets, MAXPLAYERS, COMMAND_FILTER_NO_IMMUNITY|COMMAND_FILTER_NO_BOTS, sTargetName, sizeof(sTargetName), bTN_ML)) <= 0)
	{
		ReplyToCommand(client, "Not found or invalid parameter.");
		return Plugin_Handled;
	}
	
	if(IsValidClient(client))
	{
		PrintToChat(client, "[TOGs CVar Checker] Check console for output!");
		PrintToConsole(client, "=============================== TOGs CVar Checker ===============================");
	}
	
	for(int i = 0; i < iTargetCount; i++)
	{
		int target = a_iTargets[i];
		if(IsValidClient(target))
		{
			QueryClientConVar(target, "fps_max", view_as<ConVarQueryFinished>(CVarQueryCB), GetClientUserId(client));
			QueryClientConVar(target, "cl_updaterate", view_as<ConVarQueryFinished>(CVarQueryCB), GetClientUserId(client));
			QueryClientConVar(target, "cl_cmdrate", view_as<ConVarQueryFinished>(CVarQueryCB), GetClientUserId(client));
			QueryClientConVar(target, "rate", view_as<ConVarQueryFinished>(CVarQueryCB), GetClientUserId(client));
			QueryClientConVar(target, "cl_interp", view_as<ConVarQueryFinished>(CVarQueryCB), GetClientUserId(client));
			QueryClientConVar(target, "cl_interp_ratio", view_as<ConVarQueryFinished>(CVarQueryCB), GetClientUserId(client));
			QueryClientConVar(target, "cl_smooth", view_as<ConVarQueryFinished>(CVarQueryCB), GetClientUserId(client));
			QueryClientConVar(target, "cl_smoothtime", view_as<ConVarQueryFinished>(CVarQueryCB), GetClientUserId(client));
			QueryClientConVar(target, "cl_lagcompensation", view_as<ConVarQueryFinished>(CVarQueryCB), GetClientUserId(client));
			QueryClientConVar(target, "mat_dxlevel", view_as<ConVarQueryFinished>(CVarQueryCB), GetClientUserId(client));
		}
	}
	return Plugin_Handled;
}

bool IsValidClient(int client, bool bAllowBots = false, bool bAllowDead = true)
{
	if(!(1 <= client <= MaxClients) || !IsClientInGame(client) || (IsFakeClient(client) && !bAllowBots) || (!IsPlayerAlive(client) && !bAllowDead))
	{
		return false;
	}
	return true;
}

bool HasFlags(int client, char[] sFlags)
{
	if(StrEqual(sFlags, "public", false) || StrEqual(sFlags, "", false))
	{
		return true;
	}
	else if(StrEqual(sFlags, "none", false))	//useful for some plugins
	{
		return false;
	}
	else if(!client)	//if rcon
	{
		return true;
	}
	else if(CheckCommandAccess(client, "sm_not_a_command", ADMFLAG_ROOT, true))
	{
		return true;
	}
	
	AdminId id = GetUserAdmin(client);
	if(id == INVALID_ADMIN_ID)
	{
		return false;
	}
	int flags, clientflags;
	clientflags = GetUserFlagBits(client);
	
	if(StrContains(sFlags, ";", false) != -1) //check if multiple strings
	{
		int i = 0, iStrCount = 0;
		while(sFlags[i] != '\0')
		{
			if(sFlags[i++] == ';')
			{
				iStrCount++;
			}
		}
		iStrCount++; //add one more for stuff after last comma
		
		char[][] a_sTempArray = new char[iStrCount][30];
		ExplodeString(sFlags, ";", a_sTempArray, iStrCount, 30);
		bool bMatching = true;
		
		for(i = 0; i < iStrCount; i++)
		{
			bMatching = true;
			flags = ReadFlagString(a_sTempArray[i]);
			for(int j = 0; j <= 20; j++)
			{
				if(bMatching)	//if still matching, continue loop
				{
					if(flags & (1<<j))
					{
						if(!(clientflags & (1<<j)))
						{
							bMatching = false;
						}
					}
				}
			}
			if(bMatching)
			{
				return true;
			}
		}
		return false;
	}
	else
	{
		flags = ReadFlagString(sFlags);
		for(int i = 0; i <= 20; i++)
		{
			if(flags & (1<<i))
			{
				if(!(clientflags & (1<<i)))
				{
					return false;
				}
			}
		}
		return true;
	}
}

stock void Log(char[] sPath, const char[] sMsg, any ...)		//TOG logging function - path is relative to logs folder.
{
	char sLogFilePath[PLATFORM_MAX_PATH], sFormattedMsg[1500];
	BuildPath(Path_SM, sLogFilePath, sizeof(sLogFilePath), "logs/%s", sPath);
	VFormat(sFormattedMsg, sizeof(sFormattedMsg), sMsg, 3);
	LogToFileEx(sLogFilePath, "%s", sFormattedMsg);
}

/*
CHANGELOG:
	1.0.0
		* Initial creation. In this case, it was actually combining two similar plugins of mine and recoding them a bit, while converting to new syntax.
		
*/