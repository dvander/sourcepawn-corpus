#include <sourcemod>

public Plugin:myinfo =
{
	name = "[INSURGENCY] Admin Chat Tag",
	author = "John B.",
	description = "Adds a tag to admins' chat messages",
	version = "1.0.0",
	url = "www.sourcemod.net",	
}

public OnPluginStart()
{
	RegConsoleCmd("say", Command_SendToAll);
	RegConsoleCmd("say_team", Command_SendToTeam);	
}

public Action:Command_SendToAll(client, args)
{
	//Name
	decl String:Name[64];
	GetClientName(client, Name, sizeof(Name));

	//Team
	new team = GetClientTeam(client);

	//Message
	decl String:TextToAll[256];
	GetCmdArgString(TextToAll, sizeof(TextToAll));
	StripQuotes(TextToAll);

	//Flags
	new flags = GetUserFlagBits(client);

	if(flags != 0)
	{
		//Player is alive and have team (no spec)
		if(IsPlayerAlive(client) && team == 2 || team == 3)
		{
			PrintToChatAll("[Admin] %s :  %s", Name, TextToAll);
		}
		//Player isn't alive and have team (no spec)
		else if(!IsPlayerAlive(client) && team == 2 || team == 3)
		{
			PrintToChatAll("*DEAD* [Admin] %s :  %s", Name, TextToAll);
		}
		//Player is in spectate
		else if(!IsPlayerAlive(client) && team != 2 && team != 3)
		{
			PrintToChatAll("*SPEC* [Admin] %s :  %s", Name, TextToAll);
		}
	}
	else
	{
		return Plugin_Continue;
	}

	return Plugin_Handled;
}

public Action:Command_SendToTeam(client, args)
{
	//Name
	decl String:Name[64];
	GetClientName(client, Name, sizeof(Name));

	//Team
	new team = GetClientTeam(client);

	//Message
	decl String:TextToTeam[256];
	GetCmdArgString(TextToTeam, sizeof(TextToTeam));
	StripQuotes(TextToTeam);

	//Flags
	new flags = GetUserFlagBits(client);

	if(flags != 0)
	{
		//Player is alive and have team (no spec)
		if(IsPlayerAlive(client) && team == 2 || team == 3)
		{
			for(new i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i))
				{
					new PlayersTeam = GetClientTeam(i);
					if (PlayersTeam & team)
					{
						PrintToChat(i, "(TEAM) [Admin] %s :  %s", Name, TextToTeam);
					}
				}
			}
		}
		//Player isn't alive and have team (no spec)
		else if(!IsPlayerAlive(client) && team == 2 || team == 3)
		{
			for(new i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i))
				{
					new PlayersTeam = GetClientTeam(i);
					if (PlayersTeam & team)
					{
						PrintToChat(i, "*DEAD*(TEAM) [Admin] %s :  %s", Name, TextToTeam);
					}
				}
			}
		}
		//Player is in spectate
		else if(!IsPlayerAlive(client) && team != 2 && team != 3)
		{
			for(new i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i))
				{
					new PlayersTeam = GetClientTeam(i);
					if (PlayersTeam & team)
					{
						PrintToChat(i, "(Spectator) [Admin] %s :  %s", Name, TextToTeam);
					}
				}
			}
		}
	}
	else
	{
		return Plugin_Continue;
	}

	return Plugin_Handled;
}