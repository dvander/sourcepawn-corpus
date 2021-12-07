#pragma semicolon 1
#define PLUGIN_VERSION "1.0.0"

#include <sourcemod>
new Handle:g_hIgnored = INVALID_HANDLE;
new Handle:g_hArray_Ignored = INVALID_HANDLE;
new String:g_sPath[PLATFORM_MAX_PATH];

public Plugin:myinfo =
{
	name = "[CS:GO] Log Motd Panels",
	author = "Panduh (AlliedMods: thetwistedpanda)",
	description = "Logs information to /logs/motdlogs.log when a MOTD panel is created.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmodders.com"
}

public OnPluginStart()
{
	if(GetUserMessageType() != UM_Protobuf || GetEngineVersion() != Engine_CSGO)
	{
		SetFailState("Counter-Strike: Global Offensive Only!");
	}

	decl String:sExplode[32][PLATFORM_MAX_PATH];
	decl String:sBuffer[(PLATFORM_MAX_PATH * 32)];
	g_hArray_Ignored = CreateArray(PLATFORM_MAX_PATH / 4);

	CreateConVar("csgo_motdlog_version", PLUGIN_VERSION, "[CS:GO] Log Motd Panels: Version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	g_hIgnored = CreateConVar("csgo_motdlog_ignored", "motd", "Up to 32 valid motd addresses that Log MOTDs will ignore. Separate multiple URLs with |", FCVAR_NONE);
	GetConVarString(g_hIgnored, sBuffer, sizeof(sBuffer));
	new iUrls = ExplodeString(sBuffer, "|", sExplode, sizeof(sExplode), sizeof(sExplode[]));
	for(new i = 0; i < iUrls; i++)
	{
		PushArrayString(g_hArray_Ignored, sExplode[i]);
	}

	AutoExecConfig(true, "csgo_motdlog");
	/*
	RegAdminCmd("csgo_testmotd", Command_Test, ADMFLAG_GENERIC);
	*/
	BuildPath(Path_SM, g_sPath, sizeof(g_sPath), "logs/motdlogs.log");
	HookUserMessage(GetUserMessageId("VGUIMenu"), UserMessageHook_VMenu, true);
}

/*
public Action:Command_Test(client, args)
{
	new Handle:hKeyValues = CreateKeyValues("data", "", "");
	KvSetString(hKeyValues, "title", "Log Motd Panels");
	KvSetNum(hKeyValues, "type", 2);
	KvSetString(hKeyValues, "msg", "http://google.com");
	KvSetNum(hKeyValues, "cmd", 5);
	if (IsClientInGame(client))
	{
		static bool:bSwap;
		ShowVGUIPanel(client, "info", hKeyValues, (bSwap = !bSwap));
	}
	CloseHandle(hKeyValues);

	return Plugin_Handled;
}
*/

public Action:UserMessageHook_VMenu(UserMsg:msg_id, Handle:msg, const players[], playersNum, bool:reliable, bool:init)
{
	new String:sType[10];
	PbReadString(msg, "name", sType, sizeof(sType));
	if(!StrEqual(sType, "info", false))
	{
		return Plugin_Continue;
	}

	decl String:sKey[128];
	decl String:sName[128];
	new String:sBuffer[512];
	new iSubKeys = PbGetRepeatedFieldCount(msg, "subkeys");
	for(new i = 0; i < iSubKeys; i++)
	{
		new Handle:submsg = PbReadRepeatedMessage(msg, "subkeys", i);

		PbReadString(submsg, "name", sName, sizeof(sName));
		PbReadString(submsg, "str", sKey, sizeof(sKey));
		if(StrEqual(sName, "msg", false))
		{
			if(FindStringInArray(g_hArray_Ignored, sKey) != -1)
			{
				return Plugin_Continue;
			}
		}

		if(i > 0)
		{
			Format(sBuffer, sizeof(sBuffer), "%s, ", sBuffer);
		}

		Format(sBuffer, sizeof(sBuffer), "%s[%s]: `%s`", sBuffer, sName, sKey);
	}

	if(strlen(sBuffer))
	{
		LogToFileEx(g_sPath, sBuffer);
	}

	return Plugin_Continue;
}