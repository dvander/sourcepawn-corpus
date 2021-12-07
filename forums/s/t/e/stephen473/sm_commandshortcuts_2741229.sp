#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Hardy`(stephen473)"
#define PLUGIN_VERSION "1.1"

#include <sourcemod>
#include <sdktools>

#pragma newdecls required

ConVar g_cNotification;
ConVar g_cPublicInfo;

ArrayList g_aCommands = null;
ArrayList g_aShortCuts = null;

public Plugin myinfo = 
{
	name = "Command Shortcuts",
	author = PLUGIN_AUTHOR,
	description = "Allows players to execute server/client commands via shortcuts",
	version = PLUGIN_VERSION,
	url = "http://pluginsatis.com"
};

public void OnPluginStart()
{
	g_cNotification = CreateConVar("sm_commandshortcuts_notification", "1", "Display a message when a command shortcut triggered. 1 = Enabled, 0 = Disabled");
	g_cPublicInfo = CreateConVar("sm_commandshortcuts_publicinfo", "1", "Allow all clients to lookup command shortcuts info by typing !commandshortcuts. 1 = All Clients, 0 = Only Admins(who have access to ban)");

	RegAdminCmd("sm_reloadshortcuts", Command_ReloadShortCuts, ADMFLAG_RCON);
	RegConsoleCmd("sm_commandshortcuts", Command_CommandShortcuts);

	g_aCommands = new ArrayList(1);
	g_aShortCuts = new ArrayList(ByteCountToCells(32));
	
	AutoExecConfig(true, "sm_commandshortcuts");
}

public void OnMapStart()
{
	ReadCFG();
}

public Action Command_ReloadShortCuts(int client, int args)
{
	ReadCFG();
	ReplyToCommand(client, "[SM] Command shortcuts reloaded.");
}

public Action Command_CommandShortcuts(int client, int args)
{
	if (!IsClientInGame(client) || !g_cPublicInfo.BoolValue && !CheckCommandAccess(client, "sm_commandshortcuts", ADMFLAG_BAN, true))
		return Plugin_Handled;
	
	PrintToChat(client, " [SM] Printed \x04%d command shortcuts \x01to your console.", g_aCommands.Length);
	PrintToConsole(client, "Command Shortcuts");
	PrintToConsole(client, "--------------------------------");
	
	char sShortCut[32], sFlag[32], sCommand[32];
	int iCommandType;
	
	for (int i = 0; i < g_aCommands.Length; i++)
	{
		StringMap hCommand = view_as<StringMap>(CloneHandle(g_aCommands.Get(i)));
		
		hCommand.GetString("shortcut", sShortCut, sizeof(sShortCut));
		hCommand.GetString("flag", sFlag, sizeof(sFlag));
		hCommand.GetString("command", sCommand, sizeof(sCommand));		
		hCommand.GetValue("type", iCommandType);		
		
		PrintToConsole(client, "Shortcut: %s | Flags: %s | Command: %s | Type: %s", sShortCut, sFlag, sCommand, iCommandType == 1 ? "Server Command":"Client Command");	
		
		delete hCommand;
	}
	
	PrintToConsole(client, "--------------------------------");

	return Plugin_Continue;
}	

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	if (!IsClientInGame(client) || IsCommandRegistered(sArgs))
		return;
		
	SearchCommandInArg(client, sArgs);
}

public Action Command_ShortCutTrigger(int client, int args)
{
	if (!IsClientInGame(client))
		return Plugin_Handled;

	char sArg[32];
	GetCmdArg(0, sArg, 32);
	
	SearchCommandInArg(client, sArg);	
	
	return Plugin_Continue;
}

public void SearchCommandInArg(int client, const char[] sArg)
{
	int iCommand = g_aShortCuts.FindString(sArg);
	
	if (iCommand == -1)
	return;
	
	StringMap hCommand = view_as<StringMap>(CloneHandle(g_aCommands.Get(iCommand)));	
	
	char sFlag[32];
	hCommand.GetString("flag", sFlag, sizeof(sFlag));
			
	int iFlag = ReadFlagString(sFlag);
			
	if (!CheckCommandAccess(client, "sm_commandshortcuts", iFlag, true))
	return;
	
	char sCommand[32];
	int iCommandType;
			
	hCommand.GetString("command", sCommand, sizeof(sCommand));		
	hCommand.GetValue("type", iCommandType);		
	
	if (StrContains(sCommand, "{player}") != -1)
	{
		char sIndex[12];		
		Format(sIndex, sizeof(sIndex), "#%d", GetClientUserId(client));		
		ReplaceString(sCommand, sizeof(sCommand), "{player}", sIndex);
	}
	
	iCommandType == 1 ? ServerCommand(sCommand):ClientCommand(client, sCommand);
	
	if (g_cNotification.BoolValue)
		PrintToChatAll(" [SM] Player \x03%N \x01triggered an shortcut! \x04(%s)", client, sArg);		
		
	delete hCommand;			
}

bool IsCommandRegistered(const char[] sArg)
{
	int iCommand = g_aShortCuts.FindString(sArg);
	
	if(iCommand == -1)
	return false;
	
	StringMap hCommand = view_as<StringMap>(CloneHandle(g_aCommands.Get(iCommand)));	

	int iRegisterCommand;
	hCommand.GetValue("registershortcut", iRegisterCommand);
	
	delete hCommand;
	
	return iRegisterCommand == 1;
}

public void ReadCFG()
{
	g_aCommands.Clear();
	g_aShortCuts.Clear();
	
	KeyValues hKv = new KeyValues("commandshortcuts");
	hKv.ImportFromFile("addons/sourcemod/configs/commandshortcuts.cfg");
	
	if (!hKv.GotoFirstSubKey()) {
		SetFailState("[Command Shortcuts] File commandshortcuts.cfg is corrupted.");
	}
	
	char sShortCut[32], sFlag[32], sCommand[32];
	
	do {
		hKv.GetString("shortcut", sShortCut, sizeof(sShortCut));
		hKv.GetString("flag", sFlag, sizeof(sFlag));
		hKv.GetString("command", sCommand, sizeof(sCommand));
		
		int iCommandType = hKv.GetNum("type");
		int iRegisterCommand = hKv.GetNum("registershortcut");
		
		StringMap hCommand = new StringMap();
		
		hCommand.SetString("shortcut", sShortCut);
		hCommand.SetString("flag", sFlag);
		hCommand.SetString("command", sCommand);		
		hCommand.SetValue("type", iCommandType);		
		hCommand.SetValue("registershortcut", iRegisterCommand);
		
		g_aShortCuts.PushString(sShortCut);
		g_aCommands.Push(hCommand);
		
		if (iRegisterCommand == 1 && GetCommandFlags(sShortCut) == INVALID_FCVAR_FLAGS)
		{
			RegConsoleCmd(sShortCut, Command_ShortCutTrigger);
			PrintToServer("[Command Shortcuts] Registered command %s to execute real command %s", sShortCut, sCommand);
		}	
		
	} while (hKv.GotoNextKey());
	
	hKv.Rewind();
	delete hKv;
}