#pragma semicolon 1
#define PLUGIN_VERSION "1.0"

#include <sourcemod>

public Plugin:myinfo =
{
	name = "TOG Case Commands",
	author = "That One Guy",
	description = "Converts chat triggers to lowercase so that they work",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net"
}

public OnPluginStart()
{
	CreateConVar("togcasecommands_version", PLUGIN_VERSION, "TOG Case Commands: Version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	AddCommandListener(Command_Say, "say");
	AddCommandListener(Command_Say, "say2");
	AddCommandListener(Command_Say, "say_team");
}

public Action:Command_Say(client, const String:command[], argc)
{
	if(!IsValidClient(client))
	{
		return Plugin_Continue;
	}
	
	decl String:sText[300];
	GetCmdArgString(sText, sizeof(sText));
	StripQuotes(sText);

	if((sText[0] == '!') || (sText[0] == '/'))
	{
		if(IsCharUpper(sText[1]))
		{
			for(new i = 0; i <= strlen(sText); ++i)
			{
				sText[i] = CharToLower(sText[i]);
			}

			FakeClientCommand(client, "say %s", sText);
			return Plugin_Handled;
		}
	}
		
	return Plugin_Continue;
}

public bool:IsValidClient(client)
{
	if (!(1 <= client <= MaxClients) || !IsClientInGame(client) || IsFakeClient(client))
	{
		return false;
	}
	return true;
}