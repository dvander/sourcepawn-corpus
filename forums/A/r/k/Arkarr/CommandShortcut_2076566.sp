#include <sourcemod>

public Plugin:myinfo =
{
	name = "Chat command",
	author = "Arkarr",
	description	= "Execute a command depend of what the user type.",
	version	= "1.1",
	url	= "http://www.sourcemod.net"
};

public OnPluginStart() 
{ 
	AddCommandListener(HookPlayerChat, "say");
	AddCommandListener(HookPlayerChat, "say_team");
	AddCommandListener(HookPlayerChat, "say2");
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
	FileToKeyValues(kv, "addons/sourcemod/configs/ChatCommand.cfg");
	
	if (!KvGotoFirstSubKey(kv)) {
		return;
	}
	
	do {
		KvGetString(kv, "chat", strChat, sizeof(strChat));
		KvGetString(kv, "command", strCommand, sizeof(strCommand));
		KvGetString(kv, "flag", strFlag, sizeof(strFlag));
		new flag = ReadFlagString(strFlag);
		
		if(CheckCommandAccess(client, "sm_admin", flag, true) == true)
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
	