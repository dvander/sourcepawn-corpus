#include <sourcemod>

public Plugin:myinfo =
{
	name = "Chat command",
	author = "Arkarr",
	description	= "Execute a command depend of what the user type.",
	version	= "1.1",
	url	= "http://www.sourcemod.net"
};

static String:KVPath[PLATFORM_MAX_PATH];

public OnPluginStart() 
{ 
	AddCommandListener(HookPlayerChat, "say");
	AddCommandListener(HookPlayerChat, "say_team");
	AddCommandListener(HookPlayerChat, "say2");
	
	RegAdminCmd("sm_alias", Command_Alias, ADMFLAG_CONFIG, "Alias a command.");
	RegAdminCmd("sm_unalias", Command_Unalias, ADMFLAG_CONFIG, "Unalias a command.");
	
	BuildPath(Path_SM, KVPath, sizeof(KVPath), "configs/ChatCommand.cfg");
} 

public Action:HookPlayerChat(client, const String:command[], args)
{
	decl String:strChat[255];
	decl String:strCommand[255];
	decl String:strFlag[255];
	decl String:player_text[300];
	decl String:player_final[50];
	new  player_id;
	
	new Handle:kv = CreateKeyValues("ChatCommand");
	FileToKeyValues(kv, KVPath);
	
	if (!KvGotoFirstSubKey(kv)) {
		return;
	}
	
	do {
		KvGetString(kv, "chat", strChat, sizeof(strChat));
		KvGetString(kv, "command", strCommand, sizeof(strCommand));
		KvGetString(kv, "flag", strFlag, sizeof(strFlag));
		new flag = ReadFlagString(strFlag);
		
		if(CheckCommandAccess(client, "CommandShortcut_Override", flag, true) == true)
		{
			GetCmdArgString(player_text, sizeof(player_text));
			StripQuotes(player_text);
			if(StrEqual(player_text, strChat, true))
			{
				player_id = GetClientUserId(client);
				Format(player_final, sizeof(player_final), "#%d", player_id);
				ReplaceString(strCommand, sizeof(strCommand), "[PLAYER_NAME]", player_final);
				ServerCommand(strCommand);
			}
		}
		
	} while (KvGotoNextKey(kv));
	
	CloseHandle(kv);  
}

public Action:Command_Alias(client, args)
{
	if (args == 0)
	{
		ReplyToCommand(client, "Usage: !alias <trigger> <command_that_gets_triggered> <flag_for_trigger>");
		return Plugin_Handled;
	}
	
	new String:trigger[256], String:command[256], String:flag[10];
	
	GetCmdArg(1, trigger, sizeof(trigger));
	GetCmdArg(2, command, sizeof(command));
	GetCmdArg(3, flag, sizeof(flag));
	
	new Handle:kv = CreateKeyValues("ChatCommand");
	FileToKeyValues(kv, KVPath);
	
	if (KvJumpToKey(kv, trigger, true))
	{
		KvSetString(kv, "chat", trigger);
		KvSetString(kv, "command", command);
		KvSetString(kv, "flag", flag);
	}
	KvRewind(kv);
	KeyValuesToFile(kv, KVPath);
	CloseHandle(kv);
	
	ServerCommand("sm plugins reload CommandShortcut");
	ReplyToCommand(client, "[SM] Successfully aliased %s to %s.", command, trigger);
	return Plugin_Handled;
}

public Action:Command_Unalias(client, args)
{
	if (args == 0)
	{
		ReplyToCommand(client, "Usage: !unalias <trigger>");
		return Plugin_Handled;
	}
	
	new String:name[256];
	GetCmdArg(1, name, sizeof(name));
	
	new Handle:kv = CreateKeyValues("ChatCommand");
	FileToKeyValues(kv, KVPath);
	if (KvJumpToKey(kv, name, false))
	{
		KvDeleteThis(kv);
		KvRewind(kv);
		KeyValuesToFile(kv, KVPath);
		CloseHandle(kv);
		ServerCommand("sm plugins reload CommandShortcut");
		ReplyToCommand(client, "[SM] Successfully removed %s.", name);
		return Plugin_Handled;
	}
	KvRewind(kv);
	KeyValuesToFile(kv, KVPath);
	CloseHandle(kv);
	ReplyToCommand(client, "[SM] %s is not listed in ChatCommand.cfg!", name);
	return Plugin_Handled;
}