#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

public void OnPluginStart()
{
	LoadTranslations("common.phrases.txt");
	RegAdminCmd("sm_hp", sm_hp, ADMFLAG_SLAY, "Change player health points");
}

Action sm_hp(int client, int args)
{
	if(client != 0 && !IsClientInGame(client)) return Plugin_Continue;

	if(args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_hp <name|#userid|@all> <hp|+hp|-hp>\n Set or change players health points.");
		return Plugin_Handled;
	}

	char buffer[255];
	int change_hp[2]; // {0, hp}
	change_hp[0] = 0;
	if( args >= 2 && GetCmdArg(2, buffer, sizeof(buffer)) > 0 )
	{
		int index = FindCharInString(buffer, '+');
		if( index != -1 || (index = FindCharInString(buffer, '-')) != -1 )
		{
			change_hp[0] = 1;
		}
		else
		{
			change_hp[0] = 2;
			index = 0;
		}

		change_hp[1] = StringToInt(buffer[index]);

		if(change_hp[0] == 1 && change_hp[1] <= 0)
		{
			ReplyToCommand(client, "[SM] Give bigger HP number than zero. (%s)", buffer);
			return Plugin_Handled;
		}

		//PrintToServer("buffer[%i] hp %i 0 %i", index, change_hp[1], change_hp[0]);
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

		switch(change_hp[0])
		{
			case 0:
			{
				for(int x = 0; x < number; x++)
				{
					clienthealth = GetClientHealth(targets[x]);

					if(client != 0 && replysrc == SM_REPLY_TO_CHAT)
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
			case 1:
			{
				//tn_is_ml ? ReplyToCommand(client, "[SM] You have set %t health to %i", buffer, change_hp[1]):ReplyToCommand(client, "[SM] You have set %s health to %i", buffer, change_hp[1]);
				tn_is_ml ? ShowActivity2(client,"[SM] ", "have set %t health to %i", buffer, change_hp[1]):ShowActivity2(client, "[SM] ", "have set %s health to %i", buffer, change_hp[1]);

				for(int x = 0; x < number; x++) SetTotalHP(targets[x], change_hp[1]);
			}
			case 2:
			{
				if(change_hp[1] > 0)
				{
					//tn_is_ml ? ReplyToCommand(client, "[SM] You have changed %t health by +%i", buffer, change_hp[1]):ReplyToCommand(client, "[SM] You have changed %s health by +%i", buffer, change_hp[1]);
					tn_is_ml ? ShowActivity2(client, "[SM] ", "have changed %t health by +%i", buffer, change_hp[1]):ShowActivity2(client, "[SM] ", "have changed %s health by +%i", buffer, change_hp[1]);
				}
				else
				{
					//tn_is_ml ? ReplyToCommand(client, "[SM] You have changed %t health by -%i", buffer, change_hp[1]):ReplyToCommand(client, "[SM] You have changed %s health by -%i", buffer, change_hp[1]);
					tn_is_ml ? ShowActivity2(client, "[SM] ", "have changed %t health by -%i", buffer, change_hp[1]):ShowActivity2(client, "[SM] ", "have changed %s health by -%i", buffer, change_hp[1]);
				}
				
				for(int x = 0; x < number; x++) SetTotalHP(targets[x], GetClientHealth(targets[x]) + change_hp[1]);
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

void SetTotalHP(int client, int health)
{
	if(client > 0)
	{
		SetEntProp(client, Prop_Send, "m_iMaxHealth", health);
		SetEntProp(client, Prop_Send, "m_iHealth", health);
	}
}
