#include <sourcemod>
#include <dhooks>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
	name = "BSP ConVar Custom Whitelist",
	author = "Vauff",
	description = "Changes the file that CS:GO reads the BSP cvar whitelist from",
	version = "1.1",
	url = "https://github.com/Vauff/bspconvar_custom_whitelist"
};

Handle g_hIsWhiteListedCmd;
KeyValues g_kvWhitelist;

char g_sMapName[PLATFORM_MAX_PATH];

public void OnPluginStart()
{
	if (GetEngineVersion() != Engine_CSGO)
		SetFailState("This plugin only runs on CS:GO!");

	RegAdminCmd("sm_reloadwhitelist", Command_ReloadWhitelist, ADMFLAG_RCON, "Manually reloads the bsp convar whitelist mid-map");

	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "gamedata/bspconvar_custom_whitelist.games.txt");

	if (!FileExists(path))
		SetFailState("Can't find bspconvar_custom_whitelist.games.txt gamedata");

	Handle gameData = LoadGameConfigFile("bspconvar_custom_whitelist.games");
	
	if (gameData == INVALID_HANDLE)
		SetFailState("Can't find bspconvar_custom_whitelist.games.txt gamedata");

	g_hIsWhiteListedCmd = DHookCreateFromConf(gameData, "IsWhiteListedCmd");
	CloseHandle(gameData);

	if (!g_hIsWhiteListedCmd)
		SetFailState("Failed to setup detour for IsWhiteListedCmd");

	if (!DHookEnableDetour(g_hIsWhiteListedCmd, false, Detour_IsWhiteListedCmd))
		SetFailState("Failed to detour IsWhiteListedCmd");
}

public void OnMapStart()
{
	ReloadWhitelist();
	GetCurrentMap(g_sMapName, sizeof(g_sMapName));
}

public Action Command_ReloadWhitelist(int client, int args)
{
	ReloadWhitelist();
	ReplyToCommand(client, "%sBSP convar whitelist successfully reloaded!", (client == 0) ? "[SM] " : " \x04[SM] \x05");

	return Plugin_Handled;
}

public MRESReturn Detour_IsWhiteListedCmd(DHookReturn hReturn, DHookParam hParams)
{
	char command[128];
	DHookGetParamString(hParams, 1, command, sizeof(command));

	if (GetMapWhitelistValue(command) == 1)
		DHookSetReturn(hReturn, true);
	else if (GetMapWhitelistValue(command) == 0)
		DHookSetReturn(hReturn, false);
	else if (g_kvWhitelist.GetNum(command) == 1)
		DHookSetReturn(hReturn, true);
	else
		DHookSetReturn(hReturn, false);

	return MRES_Supercede;
}

void ReloadWhitelist()
{
	if (g_kvWhitelist != null)
		CloseHandle(g_kvWhitelist);

	g_kvWhitelist = new KeyValues("convars");

	if (!g_kvWhitelist.ImportFromFile("bspconvar_custom_whitelist.txt"))
		SetFailState("Can't find bspconvar_custom_whitelist.txt, make sure you've made a copy of the default whitelist using this filename");
}

int GetMapWhitelistValue(const char[] convar)
{
	if (g_kvWhitelist.JumpToKey(g_sMapName))
	{
		int retValue = g_kvWhitelist.GetNum(convar, -1);
		g_kvWhitelist.Rewind();
		return retValue;
	}

	return -1;
}