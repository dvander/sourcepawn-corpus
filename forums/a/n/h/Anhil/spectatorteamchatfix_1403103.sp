#pragma semicolon 1

#include <sourcemod>

new bool:ffa = true;

public Plugin:myinfo = 
{
	name = "Spectator Team Chat Fix",
	author = "Anhil",
	description = "Fixes team chat for spectators, when teamplay is off.",
	version = "1.03",
	url = "http://forums.alliedmods.net/"
};

public OnPluginStart()
{
	LoadTranslations("spectatorteamchat.phrases");
	decl String:gameFolder[PLATFORM_MAX_PATH];
	GetGameFolderName(gameFolder,sizeof(gameFolder));
	if(!StrEqual(gameFolder,"hl2mp",false))
		SetFailState("This plugin is for HL2:DM only.");
	RegConsoleCmd("say_team", Command_SayTeam);
}

public OnMapStart()
{
	new String:GameDescription[128];
	GetGameDescription(GameDescription, sizeof(GameDescription));
	ffa = StrEqual(GameDescription, "Deathmatch");
}

public Action:Command_SayTeam(client, args)
{
	if(ffa)
	{
		if(GetClientTeam(client) == 1)
		{
			new String:text[192];
			GetCmdArgString(text, sizeof(text));
			
			// Remove the quotes - start.
			new startindex = 0;
			if (text[0] == '"')
			{
				startindex = 1;
				new len = strlen(text);
				if (text[len-1] == '"')
				{
					text[len-1] = '\0';
				}
			}
			// Remove the quotes - end.
			
			if(text[startindex] == '@') 
				return Plugin_Continue; // Checking if it is admin only chat
				
			// Checking if it is command - start
			if(text[startindex] == '/') // no reason for looping, if it doesn't even start with "/"
			{
				decl String:cmdName[64];
				new Flags;
				new Handle:CmdIter = GetCommandIterator();
				while (ReadCommandIterator(CmdIter, cmdName, sizeof(cmdName), Flags))
				{
					ReplaceStringEx(cmdName, sizeof(cmdName), "sm_", "/");
					if (StrContains(text, cmdName) == startindex)
					{
						CloseHandle(CmdIter);
						return Plugin_Continue;
					}
					ReplaceStringEx(cmdName, sizeof(cmdName), "/", "/sm_");
					if (StrContains(text, cmdName) == startindex)
					{
						CloseHandle(CmdIter);
						return Plugin_Continue;
					}
				}
				CloseHandle(CmdIter);
			}
			// Checking if it is command - end
			
			for (new target = 1; target <= MaxClients; target++)
				if (IsClientInGame(target) && (GetClientTeam(target) == 1) && (client != target) && !IsFakeClient(target))
					PrintToChat(target, "(%t) %N : %s", "Spectator Team", client, text[startindex]);
		}
	}
	return Plugin_Continue;
}