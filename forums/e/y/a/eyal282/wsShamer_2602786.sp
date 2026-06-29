#include <sourcemod>

new String:StoleOrTried[15];

new const String:WSPluginName[] = "Weapons & Knives";

new const String:PluginVersion[] = "1.1";

public Plugin:myinfo = {
    name = "WS Shamer",
    author = "Eyal282",
    description = "If someone uses any command of !ws family he gets shamed on chat.",
    version = PluginVersion,
	url = "None."
}

public OnPluginStart()
{
	RegConsoleCmd("sm_ws", Command_WS);
	RegConsoleCmd("sm_knife", Command_WS);
	RegConsoleCmd("sm_nametag", Command_WS);
	RegConsoleCmd("sm_wslang", Command_WS);
	RegConsoleCmd("sm_gloves", Command_WS);
	
	SetConVarString(CreateConVar("ws_shamer_version", PluginVersion, "", FCVAR_NOTIFY), PluginVersion);
	
	if(FindPluginByName(WSPluginName))
		StoleOrTried = "stole";
		
	else
		StoleOrTried = "tried to steal";
}
public Action:Command_WS(client, args)
{

	new String:CommandName[50];
	
	GetCmdArg(0, CommandName, sizeof(CommandName));
	ReplaceStringEx(CommandName, sizeof(CommandName), "/", "");
	ReplaceStringEx(CommandName, sizeof(CommandName), "sm_", "");
	
	PrintToChatAll(" \x03%N\x01 %s\x03 Gaben\x01's gold by using the command\x04 !%s", client, StoleOrTried, CommandName);
	
	return Plugin_Handled;
}

stock bool:FindPluginByName(const String:PluginName[], bool:Sensitivity=true, bool:Contains=false)
{
	new Handle:iterator = GetPluginIterator();
	
	new Handle:PluginID;
	
	new String:curName[PLATFORM_MAX_PATH];
	
	while(MorePlugins(iterator))
	{
		PluginID = ReadPlugin(iterator)
		GetPluginInfo(PluginID, PlInfo_Name, curName, sizeof(curName));

		if(StrEqual(PluginName, curName, Sensitivity) || (Contains && StrContains(PluginName, curName, Sensitivity) != -1))
		{
			CloseHandle(iterator);
			return true;
		}
	}
	
	CloseHandle(iterator);
	return false;
}