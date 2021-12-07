#include <sourcemod>
#include <sdktools>

#include <scp>

#define PLUGIN_VERSION "0.95"

public Plugin:myinfo =
{
	name = "Ignore list",
	author = "FaTony",
	description = "Provides a way to ignore other client's chat.",
	version = PLUGIN_VERSION,
	url = "http://fatony.com/"
};

enum Targeting
{
	String:arg[MAX_NAME_LENGTH],
	buffer[MAXPLAYERS],
	buffersize,
	String:targetname[MAX_TARGET_LENGTH],
	bool:tn_is_ml
};

static Target[Targeting];

enum IgnoreStatus
{
	bool:Chat,
	bool:Voice
};

static bool:IgnoreMatrix[MAXPLAYERS + 1][MAXPLAYERS + 1][IgnoreStatus];

public OnPluginStart()
{
	CreateConVar("ftz_ignorelist_version", PLUGIN_VERSION, "The version of ignore list.", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	LoadTranslations("common.phrases");
	RegConsoleCmd("ftz_ignore", Command_Ignore, "Usage: ftz_ignore <#userid|name>\nToggles target ignore status.");
	RegConsoleCmd("ftz_ignore_chat", Command_IgnoreChat, "Usage: ftz_ignore <#userid|name>\nToggles target ignore status.");
	RegConsoleCmd("ftz_ignore_voice", Command_IgnoreVoice, "Usage: ftz_ignore <#userid|name>\nToggles target ignore status.");
	RegConsoleCmd("sm_ignore", Command_Ignore, "Usage: sm_ignore <#userid|name>\nToggles target ignore status.");
}

public OnClientDisconnect(client)
{
	for (new i = 0; i <= MAXPLAYERS; i++)
	{
		IgnoreMatrix[client][i][Chat] = false;
		IgnoreMatrix[client][i][Voice] = false;
	}
}

public Action:OnChatMessage(&author, Handle:recipients, String:name[], String:message[])
{
	if ((author < 0) || (author > MaxClients))
	{
		LogError("[Ignore list] Warning: author is out of bounds: %d", author);
		return Plugin_Continue;
	}
	new i = 0;
	new client;
	while (i < GetArraySize(recipients))
	{
		client = GetArrayCell(recipients, i);
		if ((client < 0) || (client > MaxClients))
		{
			LogError("[Ignore list] Warning: client is out of bounds: %d", client);
			i++;
			continue;
		}
		if (IgnoreMatrix[client][author][Chat])
		{
			RemoveFromArray(recipients, i);
		}
		else
		{
			i++;
		}
	}
	return Plugin_Changed;
}

public Action:Command_Ignore(client, args)
{
	if (args == 0)
	{
		ReplyToCommand(client, "Usage: ftz_ignore <#userid|name>");
		return Plugin_Handled;
	}
	GetCmdArg(1, Target[arg], MAX_NAME_LENGTH);
	Target[buffersize] = ProcessTargetString(Target[arg], client, Target[buffer], MAXPLAYERS, COMMAND_FILTER_CONNECTED, Target[targetname], MAX_TARGET_LENGTH, Target[tn_is_ml]);
	if (Target[buffersize] <= 0)
	{
		ReplyToTargetError(client, Target[buffersize]);
		return Plugin_Handled;
	}
	for (new i = 0; i < Target[buffersize]; i++)
	{
		ToggleIgnoreStatus(client, Target[buffer][i], true, true);		
	}
	return Plugin_Handled;
}

public Action:Command_IgnoreChat(client, args)
{
	if (args == 0)
	{
		ReplyToCommand(client, "Usage: ftz_ignore_chat <#userid|name>");
		return Plugin_Handled;
	}
	GetCmdArg(1, Target[arg], MAX_NAME_LENGTH);
	Target[buffersize] = ProcessTargetString(Target[arg], client, Target[buffer], MAXPLAYERS, COMMAND_FILTER_CONNECTED, Target[targetname], MAX_TARGET_LENGTH, Target[tn_is_ml]);
	if (Target[buffersize] <= 0)
	{
		ReplyToTargetError(client, Target[buffersize]);
		return Plugin_Handled;
	}
	for (new i = 0; i < Target[buffersize]; i++)
	{
		ToggleIgnoreStatus(client, Target[buffer][i], true, true);		
	}
	return Plugin_Handled;
}

public Action:Command_IgnoreVoice(client, args)
{
	if (args == 0)
	{
		ReplyToCommand(client, "Usage: ftz_ignore_voice <#userid|name>");
		return Plugin_Handled;
	}
	GetCmdArg(1, Target[arg], MAX_NAME_LENGTH);
	Target[buffersize] = ProcessTargetString(Target[arg], client, Target[buffer], MAXPLAYERS, COMMAND_FILTER_CONNECTED, Target[targetname], MAX_TARGET_LENGTH, Target[tn_is_ml]);
	if (Target[buffersize] <= 0)
	{
		ReplyToTargetError(client, Target[buffersize]);
		return Plugin_Handled;
	}
	for (new i = 0; i < Target[buffersize]; i++)
	{
		ToggleIgnoreStatus(client, Target[buffer][i], true, true);		
	}
	return Plugin_Handled;
}

ToggleIgnoreStatus(const client, const target, const bool:chat, const bool:voice)
{
	if (chat)
	{
		IgnoreMatrix[client][target][Chat] = !IgnoreMatrix[client][target][Chat];
		if (IgnoreMatrix[client][target][Chat])
		{
			ReplyToCommand(client, "%N's chat is now ignored.", target);
		}
		else
		{
			ReplyToCommand(client, "%N's chat is no longer ignored.", target);
		}
	}
	if (voice)
	{
		IgnoreMatrix[client][target][Voice] = !IgnoreMatrix[client][target][Voice];
		if (IgnoreMatrix[client][target][Voice])
		{
			if (!SetListenOverride(client, target, Listen_No))
			{
				return;
			}
			ReplyToCommand(client, "%N's voice is now ignored.", target);
		}
		else
		{
			if (!SetListenOverride(client, target, Listen_Default))
			{
				return;
			}
			ReplyToCommand(client, "%N's is no longer ignored.", target);
		}
	}
}