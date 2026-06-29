#include <sourcemod>
#define Plugin_Version "1.1.7"
public Plugin:myinfo = {
	name = "Simple Command Blocker",
	author = "noBrain",
	description = "Block Commands Permanently.",
	version = Plugin_Version,
};
public OnPluginStart()
{
	RegServerCmd("sm_blockcmd", Command_block);
	RegServerCmd("sm_kickcmd", Command_kick);
	RegServerCmd("sm_bancmd", Command_ban);
}
public Action Command_block(int args)
{
	if(args != 1)
	{
		PrintToServer("[SM] Usage:  sm_blockcmd Command");
		return Plugin_Handled;
	}
	new String:Command[64];
	GetCmdArg(1, Command, sizeof(Command));
	RegConsoleCmd(Command, Cmd_Block);
	PrintToServer("Command %s Has Been Blocked!", Command);
}
public Action Cmd_Block(int client, int args)
{
	new String:StrPlayerName[MAX_NAME_LENGTH], String:StrPlayerSteamId[32];
	GetClientAuthString(client, StrPlayerSteamId , sizeof(StrPlayerSteamId));
	GetClientName(client, StrPlayerName, sizeof(StrPlayerName));
	PrintToChatAll("[SM] Player \x02%s \x10[%s]\x01 Has Used A Blocked Command!", StrPlayerName, StrPlayerSteamId);
	PrintToServer("Command is Restricted!");
	return Plugin_Handled;
}
public Action Command_ban(int args)
{
	if(args != 1)
	{
		PrintToServer("[SM] Usage: sm_bancmd Command");
		return Plugin_Handled;
	}
	new String:Command[64];
	GetCmdArg(1, Command, sizeof(Command));
	RegConsoleCmd(Command, Cmd_ban);
	PrintToServer("Command %s Has Been Banned!", Command);
}
public Action Cmd_ban(int client, int args)
{
	new String:StrPlayerName[MAX_NAME_LENGTH];
	GetClientName(client, StrPlayerName, sizeof(StrPlayerName));
	BanClient(client, 0, BANFLAG_AUTO, "[SM] You Have Used A Banned Command And You Permanently Banned From The Server!", 
	"[SM] You Have Used A Banned Command And You Permanently Banned From The Server!");
	PrintToChatAll("[SM] Client \x02%s \x01 Banned Due Using Banned Command!", StrPlayerName);
	return Plugin_Handled;
}
public Action Command_kick(int args)
{
	if(args != 1)
	{
		PrintToServer("[SM] Usage:  sm_kickcmd Command");
		return Plugin_Handled;
	}
	new String:Command[64];
	GetCmdArg(1, Command, sizeof(Command));
	RegConsoleCmd(Command, Cmd_kick);
	PrintToServer("Command %s Has Been Kicked!", Command);
}
public Action Cmd_kick(int client, int args)
{
	new String:StrPlayerName[MAX_NAME_LENGTH];
	GetClientName(client, StrPlayerName, sizeof(StrPlayerName));
	PrintToChatAll("[SM] Player \x02%s \x01 Has Used A Kicked Command!", StrPlayerName);
	KickClient(client, "[SM] You Have Kicked Due To Using A Kicked Command!");
	PrintToServer("Command is Restricted!");
	return Plugin_Handled;
}