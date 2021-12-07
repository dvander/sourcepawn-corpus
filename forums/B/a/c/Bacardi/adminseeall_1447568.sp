
new Handle:sm_adminseeall = INVALID_HANDLE;
new bool:adminseeall = false;

new Handle:sm_chat_mode = INVALID_HANDLE;
new bool:chat_mode = false;

#define CHAT_SYMBOL '@'
#define CHAT_TRIGGER '/'

public Plugin:myinfo =
{
	name = "Admin See All chat",
	author = "Bacardi",
	description = "Snippet from Super Admin Commands, admins can see all chat messages",
	version = "0.3",
	url = "www.sourcemod.net"
}



public OnPluginStart()
{
	AddCommandListener(cmd_say, "say");
	AddCommandListener(cmd_sayteam, "say_team");

	sm_adminseeall = CreateConVar("sm_adminseeall", "1", "Admins can see all chat messages, 0 = disabled, 1 = enabled", FCVAR_NONE, true, 0.0, true, 1.0);
	adminseeall = GetConVarBool(sm_adminseeall);
	HookConVarChange(sm_adminseeall, ConVarChanged);

	// SM = sm_chat_mode
	if((sm_chat_mode = FindConVar("sm_chat_mode")) != INVALID_HANDLE)
	{
		chat_mode = GetConVarBool(sm_chat_mode);
		HookConVarChange(sm_chat_mode, ConVarChanged);
	}
}

public ConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(convar == sm_adminseeall)
	{
		adminseeall = StringToInt(newValue) >= 1 ? true:false;
	}
	else if(convar == sm_chat_mode)
	{
		chat_mode = StringToInt(newValue) >= 1 ? true:false;
	}
}


		/**
			Dead players see all chat expect other teams team_chat
			Alive players see only alive players chat expect other team team_chat

			To do:
			Alive see all dead chats/team_chats and other team alive team_chat
			Dead player see all team_chats
		*/

public Action:cmd_say(client, const String:command[], argc)
{
	if(adminseeall)
	{
		if(client != 0 && !IsPlayerAlive(client))
		{

			decl String:text[192], startmessage;
			text[0] = '\0', startmessage = 0;

			GetCmdArgString(text, sizeof(text));
			StripQuotes(text);
			// Chat command silent'/'
			if(IsChatTrigger())
			{
				if(text[0] == CHAT_TRIGGER)
				{
					return;
				}
			}

			// '@' trigges
			if(text[0] == CHAT_SYMBOL)
			{
				startmessage = 1;
				if(text[1] == CHAT_SYMBOL)
				{
					startmessage = 2;
					if(text[2] == CHAT_SYMBOL)
					{
						startmessage = 3;
					}
				}

				if(startmessage == 1 && CheckCommandAccess(client, "sm_say", ADMFLAG_CHAT)) // sm_say alias)
				{
					return;
				}
				else if(startmessage == 3 && CheckCommandAccess(client, "sm_csay", ADMFLAG_CHAT)) // sm_csay alias
				{
					return;
				}
				else if(startmessage == 2 && CheckCommandAccess(client, "sm_psay", ADMFLAG_CHAT)) // sm_psay alias
				{
					return;
				}
			}

			decl String:teamtext[256];
			teamtext[0] = '\0';
			new teamnumber = GetClientTeam(client);

			switch(teamnumber)
			{
				case 0:
				{
					//Format(teamtext, sizeof(teamtext), "\x04|\x01%t%s", "Admin see all team0 say dead", "\x03", client, "\x01", text);
					Format(teamtext, sizeof(teamtext), "\x04|\x01*DEAD* \x03%N\x01 :  %s", client, text);
				}
				case 1:
				{
					//Format(teamtext, sizeof(teamtext), "\x04|\x01%t%s", "Admin see all team1 say dead",  "\x03", client, "\x01", text);
					Format(teamtext, sizeof(teamtext), "\x04|\x01*SPEC* \x03%N\x01 :  %s", client, text);
				}
				case 2:
				{
					//Format(teamtext, sizeof(teamtext), "\x04|\x01%t%s", "Admin see all team2 say dead",  "\x03", client, "\x01", text);
					Format(teamtext, sizeof(teamtext), "\x04|\x01*DEAD* \x03%N\x01 :  %s", client, text);
				}
				case 3:
				{
					//Format(teamtext, sizeof(teamtext), "\x04|\x01%t%s", "Admin see all team3 say dead",  "\x03", client, "\x01", text);
					Format(teamtext, sizeof(teamtext), "\x04|\x01*DEAD* \x03%N\x01 :  %s", client, text);
				}
			}

			for(new i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i) && CheckCommandAccess(i, "adminseeall_access", ADMFLAG_CHAT) && IsPlayerAlive(i))
				{

					new Handle:hBf; hBf = StartMessageOne("SayText2", i);	// To send the message to all players, use StartMessageAll("SayText2");
					if (hBf != INVALID_HANDLE)
					{
						BfWriteByte(hBf, client);
						BfWriteByte(hBf, 0);
						BfWriteString(hBf, teamtext);
						EndMessage();
					}
				}
			}
		}
	}
}

public Action:cmd_sayteam(client, const String:command[], argc)
{
	if(adminseeall)
	{
		decl String:text[192];
		text[0] = '\0';

		GetCmdArgString(text, sizeof(text));
		StripQuotes(text);

		// Chat command silent'/'
		if(IsChatTrigger())
		{
			if(text[0] == CHAT_TRIGGER)
			{
				return;
			}
		}

		// SM = sm_chat_mode
		if(text[0] == CHAT_SYMBOL && chat_mode)
		{
			return;
		}

		decl String:teamtext[256];
		teamtext[0] = '\0';

		new teamnumber = 4, bool:alive = false;

		if(client == 0)
		{
			Format(teamtext, sizeof(teamtext), "\x04|\x01(SERVER) %N :  %s", client, text);
		}
		else
		{
			teamnumber = GetClientTeam(client);
			alive = IsPlayerAlive(client);

			switch(teamnumber)
			{
				case 0:
				{
					//Format(teamtext, sizeof(teamtext), "\x04|\x01%t%s", "Admin see all team0 say_team dead", "\x03", client, "\x01", text);
					Format(teamtext, sizeof(teamtext), "\x04|\x01(Unassigned) \x03%N\x01 :  %s", client, text);
				}
				case 1:
				{
					//Format(teamtext, sizeof(teamtext), "\x04|\x01%t%s", "Admin see all team1 say_team dead", "\x03", client, "\x01", text);
					Format(teamtext, sizeof(teamtext), "\x04|\x01(Spectator) \x03%N\x01 :  %s", client, text);
				}
				case 2:
				{
					//alive ? Format(teamtext, sizeof(teamtext), "\x04|\x01%t%s", "Admin see all team2 say_team alive", "\x03", client, "\x01", text):Format(teamtext, sizeof(teamtext), "\x04|\x01%t%s", "Admin see all team2 say_team dead", "\x03", client, "\x01", text);
					alive ? Format(teamtext, sizeof(teamtext), "\x04|\x01(Counter-Terrorist) \x03%N\x01 :  %s", client, text):Format(teamtext, sizeof(teamtext), "\x04|\x01*DEAD*(Terrorist) \x03%N\x01 :  %s", client, text);
				}
				case 3:
				{
					//alive ? Format(teamtext, sizeof(teamtext), "\x04|\x01%t%s", "Admin see all team3 say_team alive", "\x03", client, "\x01", text):Format(teamtext, sizeof(teamtext), "\x04|\x01%t%s", "Admin see all team3 say_team dead", "\x03", client, "\x01", text);
					alive ? Format(teamtext, sizeof(teamtext), "\x04|\x01(Terrorist) \x03%N\x01 :  %s", client, text):Format(teamtext, sizeof(teamtext), "\x04|\x01*DEAD*(Counter-Terrorist) \x03%N\x01 :  %s", client, text);
				}
			}
		}

		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && CheckCommandAccess(i, "adminseeall_access", ADMFLAG_CHAT) && (IsPlayerAlive(i) && !alive || GetClientTeam(i) != teamnumber))
			{
				new Handle:hBf; hBf = StartMessageOne("SayText2", i);	// To send the message to all players, use StartMessageAll("SayText2");
				if (hBf != INVALID_HANDLE)
				{
					BfWriteByte(hBf, client);
					BfWriteByte(hBf, 0);
					BfWriteString(hBf, teamtext);
					EndMessage();
				}
			}
		}
	}
}