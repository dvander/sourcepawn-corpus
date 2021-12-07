//ExplosiveMod v1.01 Made By ExplosiveTaco! 
//Any Comments/Bugs Tell Me On The SourceMod Forums!
//The Crash Cmd Can Be Disabled If Editied!
#include <sourcemod>
#include <sdktools>

//Plugin Info:
public Plugin:myinfo = 
{
	name = "ExplosiveMod",
	author = "ExplosiveTaco",
	description = "A Mod That Has Random Stuff In It Created By ExplosiveTaco",
	version = "1.0",
	url = "www.sourcemod.net"
}

//Plugin Commands:
public OnPluginStart()
{
	RegConsoleCmd("sm_hello", Command_Hello, "Type Hello");
	RegConsoleCmd("sm_info", Command_PluginInfo, "plugin info");
	RegConsoleCmd("sm_sucide", Command_KillMe, "Death Command");
	RegConsoleCmd("sm_crash", Command_Delete, "Crash Command!");
	RegConsoleCmd("sm_cmds", Command_CommandList, "Command List.");
}

//When A Client Joins:
public OnClientPutInServer(client)
{
	PrintToChat(client, "\x04[ExplosiveMod]\x01 Welcome To this Server Running ExplosiveMod. Enjoy Your Stay!");
}

//Command Hello:
public Action:Command_Hello(client, args)
{
	new String:print[32];
	GetCmdArg(1, print, sizeof(print));
	if(StrEqual(print, "hello"))
	{
		PrintToChat(client, "\x04[ExplosiveMod]\x01 Hello Player! Have Fun!");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

//Plugin Info:
public Action:Command_PluginInfo(client, args)
{
	new String:print[32];
	GetCmdArg(1, print, sizeof(print));
	if(StrEqual(print, "!info"))
	{
		PrintToChat(client, "\x04[ExplosiveMod]\x01 The Plugin ExplosiveMod Was Made By ExplosiveTaco");
		PrintToConsole(client, "[ExplosiveMod]The Command !info Was Used");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

//Sucide Command:
public Action:Command_KillMe(client, args)
{
	new String:print[32];
	GetCmdArg(1, print, sizeof(print));
	if(StrEqual(print, "!sucide"))
	{
		FakeClientCommand(client, "kill");
		PrintToChat(client, "\x04[ExplosiveMod]\x01 You Have Commited \x05Sucide\x01!");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

//Crash Command:
public Action:Command_Delete(client, args)
{
	new String:print[32];
	GetCmdArg(1, print, sizeof(print));
	if(StrEqual(print, "!crash"))
	{
	new ent = -1
	ent = GetClientAimTarget(client);
	if(IsValidEntity(ent))
	{
    AcceptEntityInput(ent, "kill");
	}
	return Plugin_Handled
	}
	return Plugin_Handled
}

//Command List:
public Action:Command_CommandList(client, args)
{
	new String:print[32];
	GetCmdArg(1, print, sizeof(print));
	if(StrEqual(print, "!cmds"))
	{
		PrintToChat(client, "Help Menu:");
		PrintToChat(client, "\x04[Welcome]\x01 -=- A Function That Greets Players On Spawn!");
		PrintToChat(client, "\x04[Hello]\x01 -=- When Someone Say hello, That Server Will Say Hi Back.");
		PrintToChat(client, "\x04[Sucide]\x01 -=- When Someone Say \x04!sucide\x01 They Will Die. :D");
		PrintToChat(client, "\x04[Crash]\x01 -=- :P When Someone Say \x04!crash\x01 While Looking At A Player, It Will Crash The Server! xD");
		PrintToChat(client, "Version: v1.01");
		return Plugin_Handled
	}
	return Plugin_Handled
}
