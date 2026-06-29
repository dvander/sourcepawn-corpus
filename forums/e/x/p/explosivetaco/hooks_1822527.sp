#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = {
name = "Hooks",
author = "Explodingtaco",
description = "Chat Trigger",
version = "1.0",
url = "www.sourcemod.net"
};

public OnPluginStart()
{
	RegConsoleCmd("say", Commandsay, "say hook");
}

public Action:Commandsay(client, args)
{
new String:hookcmd[32];
GetCmdArg(1, hookcmd, sizeof(hookcmd));

	if(StrEqual(hookcmd,"!fly")) 
    	{ 
        FakeClientCommand(client,"noclip"); 
        PrintToChat(client, "\x04[Fly]\x01 You Have Used !fly. It May Be On Or Off.");return Plugin_Handled 
    	}  
	return Plugin_Continue;
}