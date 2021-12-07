#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PUBLIC_CHAT_TRIGGER '!'
#define SILENT_CHAT_TRIGGER '/'

#define MESSAGE_NOTIFY "ui/message_update.wav"

new Handle:g_Cvar_Deadtalk = INVALID_HANDLE;

public Plugin:myinfo = {
	name = "Chat Sound Notification",
	author = "Leonardo",
	description = "Play sound on new chat message",
	version = "1.0",
	url = "http://www.xpenia.org/"
};

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	
	AddCommandListener(Command_Say, "say");
	AddCommandListener(Command_Say, "say2");
	AddCommandListener(Command_Say, "say_team");
}

public OnAllPluginsLoaded()
{
	g_Cvar_Deadtalk = FindConVar("sm_deadtalk");
}

public OnMapStart()
{
	PrecacheSound(MESSAGE_NOTIFY);
}

public Action:Command_Say(client, const String:command[], argc)
{
	decl String:text[192];
	new startidx = 0;
	if (GetCmdArgString(text, sizeof(text)) < 1)
	{
		return Plugin_Continue;
	}
	
	if (text[strlen(text)-1] == '"')
	{
		text[strlen(text)-1] = '\0';
		startidx = 1;
	}

	if (strcmp(command, "say2", false) == 0)
		startidx += 4;

	if( text[startidx] != PUBLIC_CHAT_TRIGGER && text[startidx] != SILENT_CHAT_TRIGGER )
	{
		new bool:bDeadTalk = GetConVarBool(g_Cvar_Deadtalk);
		if(strcmp(command, "say_team", false) == 0)
		{
			for( new other = 1; other <= MaxClients; other++ )
				if( IsClientInGame(other) && GetClientTeam(other) == GetClientTeam(client) )
					if( IsPlayerAlive(client) || !IsPlayerAlive(client) && ( bDeadTalk || !IsPlayerAlive(other) ) )
						EmitSoundToClient(other, MESSAGE_NOTIFY);
		}
		else
		{
			if( client == 0 || IsPlayerAlive(client) )
				EmitSoundToAll( MESSAGE_NOTIFY );
			else
				for( new other = 1; other <= MaxClients; other++ )
					if( IsClientInGame(other) && ( !IsPlayerAlive(other) || GetClientTeam(other) == 1 ) )
						EmitSoundToClient(other, MESSAGE_NOTIFY);
		}
	}
	
	return Plugin_Continue;
}

