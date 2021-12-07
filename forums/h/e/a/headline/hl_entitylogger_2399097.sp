#include <sourcemod>
#include <sdktools>

#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo = 
{
	name = "[ANY] Entity Logger",
	author = "Headline",
	description = "Saves all entity classnames to a log file when a new entity is created.",
	version = "1.0",
	url = "http://www.colosseum-gaming.com/"
};

public void OnPluginStart()
{
	AddTempEntHook("EffectDispatch", TE_EffectDispatch);  
}

public Action TE_EffectDispatch(const char[] te_name, int[] Players, int numClients, float delay)
{
	Log("hl_entityloger.log", "[HL - Entity Logger] New Effect Dispatched : %s", te_name);
}

public void OnEntityCreated(int entity, const char[] sClassname)
{
	Log("hl_entityloger.log", "[HL - Entity Logger] New Entity Created : %s, #%i", sClassname, entity);
}

void Log(char[] sPath, const char[] sMsg, any ...)
{
	char sLogFilePath[PLATFORM_MAX_PATH], sFormattedMsg[256];
	BuildPath(Path_SM, sLogFilePath, sizeof(sLogFilePath), "logs/%s", sPath);
	VFormat(sFormattedMsg, sizeof(sFormattedMsg), sMsg, 3);
	LogToFileEx(sLogFilePath, "%s", sFormattedMsg);
}