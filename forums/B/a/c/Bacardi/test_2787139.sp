



char Messages[][][] =
{
	{"kiss", "kissed"},
	{"hug", "hugged"},
	{"slap", "slapped"},
	{"smile", "smiled"},
	{"like", "liked"},
}

#define MESSAGE_PREFIX	"[Mail]   "

enum
{
	MailTo = 0,
	MailFrom,
	MailMessage,
	MailBoxMax
}

ArrayList MailBox;


public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	HookEvent("player_disconnect", player_disconnect);

	MailBox = new ArrayList(MailBoxMax);

	//RegConsoleCmd("sm_test", test);
}

public void player_disconnect(Event event, const char[] name, bool dontBroadcast)
{
	int Me = event.GetInt("userid");

	int letterscount = MailBox.Length;
	int letter[MailBoxMax];

	for(int x = 0; x < letterscount; x++)
	{
		MailBox.GetArray(x, letter, sizeof(letter));

		if(!(letter[MailTo] == Me ||
			letter[MailFrom] == Me))
				continue;

		MailBox.Erase(x--);
		letterscount--;
	}
}



public Action test(int client, int args)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i) || i == client)
			continue;
		
		if(GetRandomInt(0,1))
		{
			SendLetter(GetRandomInt(0,1), i, client);
		}
		else
		{
			SendLetter(GetRandomInt(0,1), client, i);
		}
	}

	return Plugin_Handled;
}

public void OnClientSayCommand_Post(int client, const char[] command, const char[] sArgs)
{
	if(!client)
		return;

	int MsgSize = sizeof(Messages);
	int index;

	for(int MsgIndex = 0; MsgIndex < MsgSize; MsgIndex++)
	{
		if(sArgs[0] != Messages[MsgIndex][0][0] ||
			StrContains(sArgs, Messages[MsgIndex][0], true) != 0)
				continue;

		index = strlen(Messages[MsgIndex][0]);

		if(sArgs[index] == ' ' && strlen(sArgs[index+1]))
		{
			index++;

			ReplySource OldReplySource = SetCmdReplySource(SM_REPLY_TO_CHAT);

			int target = FindTarget(client, sArgs[index], .immunity = false);

			SetCmdReplySource(OldReplySource);

			if(target != -1)
			{
				SendLetter(MsgIndex, client, target);
			}

			break;
		}
		else if(sArgs[index] == '\0')
		{
			ListLetters(MsgIndex, client);
			
			break;
		}
	}
}



void SendLetter(int MsgIndex, int From, int To)
{
	int Me = GetClientUserId(From);
	int You = GetClientUserId(To);

	int letterscount = MailBox.Length;
	int letter[MailBoxMax];
	int MsgBit = (1<<MsgIndex);


	//PrintToServer("-SendLetter %b %N %N", (1<<MsgIndex), From, To);

	// Look letters to me from you, first
	for(int x = 0; x < letterscount; x++)
	{
		MailBox.GetArray(x, letter, sizeof(letter));

		// bypass only match
		if(!(letter[MailTo] == Me &&
			letter[MailFrom] == You &&
			letter[MailMessage] & MsgBit))
				continue;

		letter[MailMessage] &= ~MsgBit;

		if(letter[MailMessage])
		{
			MailBox.SetArray(x, letter, sizeof(letter));
		}
		else
		{
			MailBox.Erase(x--);
			letterscount--;
		}

		ReplyToLetter(MsgIndex, From, To);

		return;
	}


	// Me already sent letter to you
	for(int x = 0; x < letterscount; x++)
	{
		MailBox.GetArray(x, letter, sizeof(letter));

		if(!(letter[MailTo] == You &&
			letter[MailFrom] == Me))
				continue;


		if(letter[MailMessage] & MsgBit)
		{
			PrintToChatAll("%s%N %s %N   mOAR!", MESSAGE_PREFIX,
												From,
												Messages[MsgIndex][1],
												To);
			return;
		}

		// Message updated
		letter[MailMessage] |= MsgBit;
		MailBox.SetArray(x, letter, sizeof(letter));

		PrintToChatAll("%s%N %s %N!", MESSAGE_PREFIX,
									From,
									Messages[MsgIndex][1],
									To);

		return;
	}

	// Message sended
	letter[MailFrom]			= Me;
	letter[MailTo]			= You;
	letter[MailMessage]		= MsgBit;

	MailBox.PushArray(letter, sizeof(letter));

	PrintToChatAll("%s%N %s %N!", MESSAGE_PREFIX,
								From,
								Messages[MsgIndex][1],
								To);
}

void ReplyToLetter(int MsgIndex, int From, int To)
{
	PrintToChatAll("%s  %N %s %N back!", MESSAGE_PREFIX,
										From,
										Messages[MsgIndex][1],
										To);
}

void ListLetters(int MsgIndex, int From)
{
	PrintToChat(From, "Look your console to see list of your sended %s", Messages[MsgIndex][0]);

	PrintToConsole(From, "\n- List of your %s:\n", Messages[MsgIndex][0]);

	int Me = GetClientUserId(From);

	int To;
	int[] Tos = new int[MaxClients];
	int TosCount;

	int letterscount = MailBox.Length;
	int letter[MailBoxMax];
	int MsgBit = (1<<MsgIndex);



	for(int x = 0; x < letterscount; x++)
	{
		MailBox.GetArray(x, letter, sizeof(letter));

		if(!(letter[MailFrom] == Me &&
			letter[MailMessage] & MsgBit))
				continue;

		To = GetClientOfUserId(letter[MailTo]);

		if(!To)
		{
			MailBox.Erase(x--);
			letterscount--;
			continue;
		}

		Tos[TosCount++] = To;
	}

	int messagesize = MAX_NAME_LENGTH*3 + 10;
	char[] message = new char[messagesize];
	int len;

	for(int x = 0; x < TosCount; x++)
	{
		if(len < messagesize)
		{
			len = Format(message, messagesize, "%s%N\n", message, Tos[x]);
		}
		else
		{
			PrintToConsole(From, "%s", message);
			message[0] = '\0';
			len = 0;
			x--;
		}
	}

	if(strlen(message))
		PrintToConsole(From, "%s", message);
}




