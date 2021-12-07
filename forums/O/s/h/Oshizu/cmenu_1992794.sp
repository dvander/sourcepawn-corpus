public PlVers:__version =
{
	version = 5,
	filevers = "1.6.0-dev+3935",
	date = "07/17/2013",
	time = "10:26:27"
};
new Float:NULL_VECTOR[3];
new String:NULL_STRING[4];
public Extension:__ext_core =
{
	name = "Core",
	file = "core",
	autoload = 0,
	required = 0,
};
new MaxClients;
public Extension:__ext_sdktools =
{
	name = "SDKTools",
	file = "sdktools.ext",
	autoload = 1,
	required = 1,
};
public Extension:__ext_cstrike =
{
	name = "cstrike",
	file = "games/game.cstrike.ext",
	autoload = 0,
	required = 1,
};
new String:CTag[6][0];
new String:CTagCode[6][16] =
{
	"",
	"\x04",
	"\x03",
	"\x03",
	"\x03",
	"\x05"
};
new bool:CTagReqSayText2[6] =
{
	0, 0, 1, 1, 1, 0
};
new bool:CEventIsHooked;
new bool:CSkipList[66];
new bool:CProfile_Colors[6] =
{
	1, 1, 0, 0, 0, 0
};
new CProfile_TeamIndex[6] =
{
	-1, ...
};
new bool:CProfile_SayText2;
public Plugin:myinfo =
{
	name = "Warden - Menu",
	description = "Warden - menu",
	author = "Killer Boy",
	version = "1.0",
	url = ""
};
public __ext_core_SetNTVOptional()
{
	MarkNativeAsOptional("GetFeatureStatus");
	MarkNativeAsOptional("RequireFeature");
	MarkNativeAsOptional("AddCommandListener");
	MarkNativeAsOptional("RemoveCommandListener");
	MarkNativeAsOptional("BfWriteBool");
	MarkNativeAsOptional("BfWriteByte");
	MarkNativeAsOptional("BfWriteChar");
	MarkNativeAsOptional("BfWriteShort");
	MarkNativeAsOptional("BfWriteWord");
	MarkNativeAsOptional("BfWriteNum");
	MarkNativeAsOptional("BfWriteFloat");
	MarkNativeAsOptional("BfWriteString");
	MarkNativeAsOptional("BfWriteEntity");
	MarkNativeAsOptional("BfWriteAngle");
	MarkNativeAsOptional("BfWriteCoord");
	MarkNativeAsOptional("BfWriteVecCoord");
	MarkNativeAsOptional("BfWriteVecNormal");
	MarkNativeAsOptional("BfWriteAngles");
	MarkNativeAsOptional("BfReadBool");
	MarkNativeAsOptional("BfReadByte");
	MarkNativeAsOptional("BfReadChar");
	MarkNativeAsOptional("BfReadShort");
	MarkNativeAsOptional("BfReadWord");
	MarkNativeAsOptional("BfReadNum");
	MarkNativeAsOptional("BfReadFloat");
	MarkNativeAsOptional("BfReadString");
	MarkNativeAsOptional("BfReadEntity");
	MarkNativeAsOptional("BfReadAngle");
	MarkNativeAsOptional("BfReadCoord");
	MarkNativeAsOptional("BfReadVecCoord");
	MarkNativeAsOptional("BfReadVecNormal");
	MarkNativeAsOptional("BfReadAngles");
	MarkNativeAsOptional("BfGetNumBytesLeft");
	MarkNativeAsOptional("PbReadInt");
	MarkNativeAsOptional("PbReadFloat");
	MarkNativeAsOptional("PbReadBool");
	MarkNativeAsOptional("PbReadString");
	MarkNativeAsOptional("PbReadColor");
	MarkNativeAsOptional("PbReadAngle");
	MarkNativeAsOptional("PbReadVector");
	MarkNativeAsOptional("PbReadVector2D");
	MarkNativeAsOptional("PbGetRepeatedFieldCount");
	MarkNativeAsOptional("PbReadRepeatedInt");
	MarkNativeAsOptional("PbReadRepeatedFloat");
	MarkNativeAsOptional("PbReadRepeatedBool");
	MarkNativeAsOptional("PbReadRepeatedString");
	MarkNativeAsOptional("PbReadRepeatedColor");
	MarkNativeAsOptional("PbReadRepeatedAngle");
	MarkNativeAsOptional("PbReadRepeatedVector");
	MarkNativeAsOptional("PbReadRepeatedVector2D");
	MarkNativeAsOptional("PbSetInt");
	MarkNativeAsOptional("PbSetFloat");
	MarkNativeAsOptional("PbSetBool");
	MarkNativeAsOptional("PbSetString");
	MarkNativeAsOptional("PbSetColor");
	MarkNativeAsOptional("PbSetAngle");
	MarkNativeAsOptional("PbSetVector");
	MarkNativeAsOptional("PbSetVector2D");
	MarkNativeAsOptional("PbAddInt");
	MarkNativeAsOptional("PbAddFloat");
	MarkNativeAsOptional("PbAddBool");
	MarkNativeAsOptional("PbAddString");
	MarkNativeAsOptional("PbAddColor");
	MarkNativeAsOptional("PbAddAngle");
	MarkNativeAsOptional("PbAddVector");
	MarkNativeAsOptional("PbAddVector2D");
	MarkNativeAsOptional("PbReadMessage");
	MarkNativeAsOptional("PbReadRepeatedMessage");
	MarkNativeAsOptional("PbAddMessage");
	VerifyCoreVersion();
	return 0;
}

bool:StrEqual(String:str1[], String:str2[], bool:caseSensitive)
{
	return strcmp(str1, str2, caseSensitive) == 0;
}

Handle:StartMessageOne(String:msgname[], client, flags)
{
	new players[1];
	players[0] = client;
	return StartMessage(msgname, players, 1, flags);
}

CPrintToChat(client, String:szMessage[])
{
	if (client <= 0)
	{
		ThrowError("Invalid client index %d", client);
	}
	if (!IsClientInGame(client))
	{
		ThrowError("Client %d is not in game", client);
	}
	decl String:szBuffer[252];
	decl String:szCMessage[252];
	SetGlobalTransTarget(client);
	Format(szBuffer, 250, "", szMessage);
	VFormat(szCMessage, 250, szBuffer, 3);
	new index = CFormat(szCMessage, 250, -1);
	if (index == -1)
	{
		PrintToChat(client, szCMessage);
	}
	else
	{
		CSayText2(client, index, szCMessage);
	}
	return 0;
}

CFormat(String:szMessage[], maxlength, author)
{
	if (!CEventIsHooked)
	{
		CSetupProfile();
		HookEvent("server_spawn", CEvent_MapStart, EventHookMode:2);
		CEventIsHooked = 1;
	}
	new iRandomPlayer = -1;
	if (author != -1)
	{
		if (CProfile_SayText2)
		{
			ReplaceString(szMessage, maxlength, "{teamcolor}", "\x03", true);
			iRandomPlayer = author;
		}
		else
		{
			ReplaceString(szMessage, maxlength, "{teamcolor}", CTagCode[1][0], true);
		}
	}
	else
	{
		ReplaceString(szMessage, maxlength, "{teamcolor}", "", true);
	}
	new i;
	while (i < 6)
	{
		if (!(StrContains(szMessage, CTag[i][0][0], true) == -1))
		{
			if (!CProfile_Colors[i][0][0])
			{
				ReplaceString(szMessage, maxlength, CTag[i][0][0], CTagCode[1][0], true);
			}
			else
			{
				if (!CTagReqSayText2[i][0][0])
				{
					ReplaceString(szMessage, maxlength, CTag[i][0][0], CTagCode[i][0][0], true);
				}
				if (!CProfile_SayText2)
				{
					ReplaceString(szMessage, maxlength, CTag[i][0][0], CTagCode[1][0], true);
				}
				if (iRandomPlayer == -1)
				{
					iRandomPlayer = CFindRandomPlayerByTeam(CProfile_TeamIndex[i][0][0]);
					if (iRandomPlayer == -2)
					{
						ReplaceString(szMessage, maxlength, CTag[i][0][0], CTagCode[1][0], true);
					}
					else
					{
						ReplaceString(szMessage, maxlength, CTag[i][0][0], CTagCode[i][0][0], true);
					}
				}
				ThrowError("Using two team colors in one message is not allowed");
			}
		}
		i++;
	}
	return iRandomPlayer;
}

CFindRandomPlayerByTeam(color_team)
{
	if (color_team)
	{
		new i = 1;
		while (i <= MaxClients)
		{
			if (IsClientInGame(i))
			{
				return i;
			}
			i++;
		}
		return -2;
	}
	return 0;
}

CSayText2(client, author, String:szMessage[])
{
	new Handle:hBuffer = StartMessageOne("SayText2", client, 0);
	BfWriteByte(hBuffer, author);
	BfWriteByte(hBuffer, 1);
	BfWriteString(hBuffer, szMessage);
	EndMessage();
	return 0;
}

CSetupProfile()
{
	decl String:szGameName[32];
	GetGameFolderName(szGameName, 30);
	if (StrEqual(szGameName, "cstrike", false))
	{
		CProfile_Colors[2] = 1;
		CProfile_Colors[3] = 1;
		CProfile_Colors[4] = 1;
		CProfile_Colors[5] = 1;
		CProfile_TeamIndex[2] = 0;
		CProfile_TeamIndex[3] = 2;
		CProfile_TeamIndex[4] = 3;
		CProfile_SayText2 = 1;
	}
	else
	{
		if (StrEqual(szGameName, "tf", false))
		{
			CProfile_Colors[2] = 1;
			CProfile_Colors[3] = 1;
			CProfile_Colors[4] = 1;
			CProfile_Colors[5] = 1;
			CProfile_TeamIndex[2] = 0;
			CProfile_TeamIndex[3] = 2;
			CProfile_TeamIndex[4] = 3;
			CProfile_SayText2 = 1;
		}
		if (StrEqual(szGameName, "left4dead", false))
		{
			CProfile_Colors[2] = 1;
			CProfile_Colors[3] = 1;
			CProfile_Colors[4] = 1;
			CProfile_Colors[5] = 1;
			CProfile_TeamIndex[2] = 0;
			CProfile_TeamIndex[3] = 3;
			CProfile_TeamIndex[4] = 2;
			CProfile_SayText2 = 1;
		}
		if (StrEqual(szGameName, "hl2mp", false))
		{
			if (GetConVarBool(FindConVar("mp_teamplay")))
			{
				CProfile_Colors[3] = 1;
				CProfile_Colors[4] = 1;
				CProfile_Colors[5] = 1;
				CProfile_TeamIndex[3] = 3;
				CProfile_TeamIndex[4] = 2;
				CProfile_SayText2 = 1;
			}
			else
			{
				CProfile_SayText2 = 0;
				CProfile_Colors[5] = 1;
			}
		}
		if (StrEqual(szGameName, "dod", false))
		{
			CProfile_Colors[5] = 1;
			CProfile_SayText2 = 0;
		}
		if (GetUserMessageId("SayText2") == -1)
		{
			CProfile_SayText2 = 0;
		}
		CProfile_Colors[3] = 1;
		CProfile_Colors[4] = 1;
		CProfile_TeamIndex[3] = 2;
		CProfile_TeamIndex[4] = 3;
		CProfile_SayText2 = 1;
	}
	return 0;
}

public Action:CEvent_MapStart(Handle:event, String:name[], bool:dontBroadcast)
{
	CSetupProfile();
	new i = 1;
	while (i <= MaxClients)
	{
		CSkipList[i] = 0;
		i++;
	}
	return Action:0;
}

public OnPluginStart()
{
	RegConsoleCmd("sm_cmenu", Afficher_Menu_Bhop, "", 0);
	return 0;
}

public Action:OnPlayerSpawn(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	CPrintToChat(client, "");
	return Action:0;
}

public Action:Afficher_Menu_Bhop(client, args)
{
	if (GetClientTeam(client) == 3)
	{
		new Handle:menu = CreateMenu(bhopvip, MenuAction:28);
		SetMenuTitle(menu, "Warden Menu");
		AddMenuItem(menu, "option1", "Free Day", 0);
		AddMenuItem(menu, "option2", "HNS", 0);
		AddMenuItem(menu, "option3", "WAR", 0);
		AddMenuItem(menu, "option4", "Simon Says", 0);
		SetMenuExitButton(menu, true);
		DisplayMenu(menu, client, 0);
	}
	else
	{
		PrintToChat(client, "You are not in team CT");
	}
	return Action:3;
}

public bhopvip(Handle:menu, MenuAction:action, client, itemNum)
{
	if (action == MenuAction:4)
	{
		switch (itemNum)
		{
			case 0:
			{
				FakeClientCommand(client, "say /free");
			}
			case 1:
			{
				FakeClientCommand(client, "say /open");
				FakeClientCommand(client, "say @[WARDEN] Go and Hide It HNS");
			}
			case 2:
			{
				FakeClientCommand(client, "say /open");
				FakeClientCommand(client, "say @[WARDEN] Det är War Ts Hämta Vapen!");
			}
			case 3:
			{
				FakeClientCommand(client, "say /simon");
			}
			default:
			{
			}
		}
	}
	else
	{
		if (action == MenuAction:16)
		{
			CloseHandle(menu);
		}
	}
	return 0;
}

