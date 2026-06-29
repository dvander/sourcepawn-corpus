#include <sourcemod>
#include <regex>

#define RX_PAT "^#ENTNAME\\[\\d+\\](.+)"

public Plugin:myinfo = {
	name = "[Cs:s & Cs:go]Teammate attack show all",
	author = "Bacardi & VieuxGnome",
	description = "Show all players team attacker in chat",
	version = "1.1",
	url = "http://forums.alliedmods.net/showthread.php?t=171252"
};

Handle mp_friendlyfire = INVALID_HANDLE;
Handle regName = INVALID_HANDLE;

public void OnPluginStart()
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
	regName = CompileRegex(RX_PAT);
}

public void convar_change(Handle convar, const char[] oldValue, const char[] newValue)
{
	if(convar == mp_friendlyfire)
	{
		bool oldv, friendlyfire;
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

public Action TextMsg(UserMsg msg_id, BfRead bf, const int[] players, int playersNum, bool reliable, bool init)
{
	if(!reliable)
	{
		return Plugin_Continue;
	}

	UserMessageType msgtype = GetUserMessageType();
	char buffer[100];

	if(msgtype == UM_Protobuf)
	{
		//LogMessage("[TA Debug] MsgType == Protobuf");
		PbReadString(bf, "params", buffer, sizeof(buffer), 0);
		//LogMessage("[TA Debug] PbGetRepeatedFieldCount = %d", PbGetRepeatedFieldCount(bf, "params"));
	}
	else
	{
		//LogMessage("[TA Debug] MsgType == BitBuffer");
		BfReadString(bf, buffer, sizeof(buffer), false);
	}

	if(StrContains(buffer, "Game_teammate_attack") != -1)
	{
                char name[MAX_NAME_LENGTH];
                GetClientName(players[0], name, sizeof(name));
		char attackername[MAX_NAME_LENGTH] = "";
		if(msgtype == UM_Protobuf)
		{
			PbReadString(bf, "params", buffer, sizeof(buffer), 1);
			if(regName != INVALID_HANDLE)
			{
				int numSubstr = MatchRegex(regName, buffer);
				if(numSubstr > 0)
				{
					GetRegexSubString(regName, 1, attackername, sizeof(attackername));
				}
			}
			if(StrEqual(attackername, name))
			{
				CreateTimer(0.0, msg, GetClientUserId(players[0]), TIMER_FLAG_NO_MAPCHANGE);
			}
		}
		else
		{
			BfReadString(bf, buffer, MAX_NAME_LENGTH, false);
	                if(StrEqual(buffer, name))
	                {
                	        CreateTimer(0.0, msg, GetClientUserId(players[0]), TIMER_FLAG_NO_MAPCHANGE);
	                }
		}

		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action msg(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);

	if(client != 0 && IsClientInGame(client))
	{
		char buffer[128];
		Handle hBf;
		int team = GetClientTeam(client);

		UserMessageType msgtype = GetUserMessageType();

		for(int i = 1; i <= MaxClients; i++)
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

