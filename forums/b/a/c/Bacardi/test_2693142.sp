

enum {
	show,
	set,
	add
};

enum {
	mode,
	hp
};

public void OnPluginStart()
{
	LoadTranslations("common.phrases.txt");

	RegAdminCmd("sm_hp", sm_hp, ADMFLAG_SLAY, "Change player health points");
}


public Action sm_hp(int client, int args)
{
	if(client != 0 && !IsClientInGame(client)) return Plugin_Continue;

	if(args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_hp <name|#userid|@all> <hp|+hp|-hp>\n Set or change players health points.");

		return Plugin_Handled;
	}

	char buffer[255];
	int change_hp[2]; // {mode, hp}


	change_hp[mode] = show;

	if( args >= 2 && GetCmdArg(2, buffer, sizeof(buffer)) > 0 )
	{
		int index = FindCharInString(buffer, '+');

		if( index != -1 || (index = FindCharInString(buffer, '-')) != -1 )
		{
			change_hp[mode] = add;
		}
		else
		{
			change_hp[mode] = set;
			index = 0;
		}

		change_hp[hp] = StringToInt(buffer[index]);
		
		if(change_hp[mode] == set && change_hp[hp] <= 0)
		{
			ReplyToCommand(client, "[SM] Give bigger HP number than zero. (%s)", buffer);
			return Plugin_Handled;
		}
		

		//PrintToServer("buffer[%i] hp %i  mode %i", index, change_hp[hp], change_hp[mode]);
	}



	bool tn_is_ml;
	GetCmdArg(1, buffer, sizeof(buffer));
	int number;
	int[] targets = new int[MaxClients];

	
	if( (number = ProcessTargetString(buffer, client,
									targets, MaxClients,
									COMMAND_FILTER_ALIVE,
									buffer, sizeof(buffer),
									tn_is_ml)) > COMMAND_TARGET_NONE )
	{						

		ReplySource replysrc = GetCmdReplySource();
		int clienthealth;

		switch(change_hp[mode])
		{
			case show:
			{
				for(int x = 0; x < number; x++)
				{
					clienthealth = GetClientHealth(targets[x]);

					if(client != 0 && replysrc ==  SM_REPLY_TO_CHAT)
					{
						if(number < 3)
						{
							if(x == 0)
							{
								tn_is_ml ? ReplyToCommand(client, "[SM] %t health:", buffer):ReplyToCommand(client, "[SM] %s health:", buffer);
							}

							ReplyToCommand(client, "%N hp %i", targets[x], clienthealth);
						}
						else if(x == 0)
						{
							ReplyToCommand(client, "[SM] Too many targets to show in chat, see console output message");
						}
					}
					PrintToConsole(client, "- %N hp %i", targets[x], clienthealth);
				}
			}
			case set:
			{
				//tn_is_ml ? ReplyToCommand(client, "[SM] You have set %t health to %i", buffer, change_hp[hp]):ReplyToCommand(client, "[SM] You have set %s health to %i", buffer, change_hp[hp]);
				tn_is_ml ? ShowActivity2(client,"[SM] ", "have set %t health to %i", buffer, change_hp[hp]):ShowActivity2(client, "[SM] ", "have set %s health to %i", buffer, change_hp[hp]);

				for(int x = 0; x < number; x++) SetEntityHealth(targets[x], change_hp[hp]);
			}
			case add:
			{
				if(change_hp[hp] > 0)
				{
					//tn_is_ml ? ReplyToCommand(client, "[SM] You have changed %t health by +%i", buffer, change_hp[hp]):ReplyToCommand(client, "[SM] You have changed %s health by +%i", buffer, change_hp[hp]);
					tn_is_ml ? ShowActivity2(client, "[SM] ", "have changed %t health by +%i", buffer, change_hp[hp]):ShowActivity2(client, "[SM] ", "have changed %s health by +%i", buffer, change_hp[hp]);
				}
				else
				{
					//tn_is_ml ? ReplyToCommand(client, "[SM] You have changed %t health by -%i", buffer, change_hp[hp]):ReplyToCommand(client, "[SM] You have changed %s health by -%i", buffer, change_hp[hp]);
					tn_is_ml ? ShowActivity2(client, "[SM] ", "have changed %t health by -%i", buffer, change_hp[hp]):ShowActivity2(client, "[SM] ", "have changed %s health by -%i", buffer, change_hp[hp]);
				}

				for(int x = 0; x < number; x++) SetEntityHealth(targets[x], GetClientHealth(targets[x]) + change_hp[hp]);
			}
		}


	}
	else // error
	{
		ReplyToTargetError(client, number);
		return Plugin_Handled;
	}

	return Plugin_Handled;
}