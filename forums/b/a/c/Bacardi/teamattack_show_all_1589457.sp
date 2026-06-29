public Plugin:myinfo = {
	name = "[Cs:s & Cs:go]Teammate attack show all",
	author = "Bacardi",
	description = "Show all players team attacker in chat",
	version = "1.0",
	url = "http://forums.alliedmods.net/showthread.php?t=171252"
};

new Handle:mp_friendlyfire = INVALID_HANDLE;

public OnPluginStart()
{
	if((mp_friendlyfire = FindConVar("mp_friendlyfire")) == INVALID_HANDLE)
	{
		SetFailState("Missing mp_friendlyfire");
	}
	HookConVarChange(mp_friendlyfire, convar_change);

	LoadTranslations("teamattack_show_all.phrases");

	if(GetConVarBool(mp_friendlyfire))
	{
		convar_change(mp_friendlyfire, "0", "1");
	}
}

public convar_change(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(convar == mp_friendlyfire)
	{
		new bool:oldv, bool:friendlyfire;
		oldv = StringToInt(oldValue) != 0;

		if((friendlyfire = GetConVarBool(mp_friendlyfire)) != oldv)
        {
			if(friendlyfire)
			{
				HookUserMessage(GetUserMessageId("TextMsg"), TextMsg, true);
			}
			else
			{
				UnhookUserMessage(GetUserMessageId("TextMsg"), TextMsg, true);
			}
		}
	}
}

public Action:TextMsg(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	if(!reliable)
	{
		return Plugin_Continue;
	}

	new UserMessageType:msgtype = GetUserMessageType();
	new String:buffer[100];

	msgtype == UM_Protobuf ? PbReadString(bf, "params", buffer, sizeof(buffer), 0):BfReadString(bf, buffer, sizeof(buffer), false);

	if(StrContains(buffer, "Game_teammate_attack") != -1)
	{
		msgtype == UM_Protobuf ? PbReadString(bf, "params", buffer, sizeof(buffer), 1):BfReadString(bf, buffer, sizeof(buffer), false);

		new String:name[MAX_NAME_LENGTH];
		GetClientName(players[0], name, sizeof(name));

		if(StrEqual(buffer, name))
		{
			CreateTimer(0.0, msg, GetClientUserId(players[0]), TIMER_FLAG_NO_MAPCHANGE);
		}
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:msg(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);

	if(client != 0 && IsClientInGame(client))
	{
		new String:buffer[128], Handle:hBf;
		new team = GetClientTeam(client);

		new UserMessageType:msgtype = GetUserMessageType();

		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && !IsFakeClient(i))
			{
				hBf = msgtype == UM_Protobuf ? StartMessageOne("SayText", i, USERMSG_BLOCKHOOKS):StartMessageOne("SayText2", i, USERMSG_BLOCKHOOKS);

				if (hBf != INVALID_HANDLE)
				{
					if (msgtype == UM_Protobuf)
					{
						Format(buffer, sizeof(buffer), " \x10[SM] %T", "teammate attack", i, team == 2 ? "\x02":"\x03", client, "\x10");
						PbSetInt(hBf, "ent_idx", client);
						PbSetBool(hBf, "chat", true);
						PbSetString(hBf, "text", buffer);
						PbSetBool(hBf, "textallchat", true);
					}
					else
					{
						Format(buffer, sizeof(buffer), "\x01[SM] %T", "teammate attack", i, "\x03", client, "\x01");
						BfWriteByte(hBf, client);
						BfWriteByte(hBf, 0);
						BfWriteString(hBf, buffer);
					}
					EndMessage();
				}
			}
		}
	}
}