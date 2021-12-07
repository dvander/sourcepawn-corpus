#pragma semicolon 1
#include <sourcemod>

/* Defines */
#define VERSION "1.1b"

public Plugin:myinfo =
{
	name		=		"Chat Fixer/WorkAround", // http://www.youtube.com/watch?v=S-rZdfZfMPw
	author		=		"Kyle Sanderson",
	description =		"Prevents clients from triggering a chat bug.",
	version		=		VERSION,
	url			=		"http://SourceMod.net"
};

public OnPluginStart()
{
	CreateConVar("sm_chatfixer_version", VERSION, "Workaround for a Chat bug.", FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AddCommandListener(SayHook, "say");
	AddCommandListener(SayHook, "say_team");
}

public Action:SayHook(client, const String:command[], argc)
{
	new iSpaceNum, i;
	decl String:SayNum[96];
	GetCmdArgString(SayNum, sizeof(SayNum));
	while(SayNum[i] != '\0')
	{
		if(SayNum[i] == ' ' || IsCharMB(SayNum[i]))
		{
			if(iSpaceNum++ == 32)
			{
				PrintToChat(client, "\x04[Chat Fixer]\x03 Sorry, I'm unable to send this message as it will disrupt chat.");
				return Plugin_Handled;
			}
		}
		i++;
	}
	return Plugin_Continue;
}