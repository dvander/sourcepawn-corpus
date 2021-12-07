public PlVers:__version =
{
	version = 5,
	filevers = "1.6.0-dev+3958",
	date = "08/29/2014",
	time = "01:11:41"
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
public Extension:__ext_sdkhooks =
{
	name = "SDKHooks",
	file = "sdkhooks.ext",
	autoload = 1,
	required = 1,
};
new String:CTag[6][0];
new String:CTagCode[6][16] =
{
	"\x01",
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
new autobhop_player[66];
new Handle:sm_bhop_enabled;
new bhop_enabled;
new Handle:sm_bhop_autobhop;
new bhop_autobhop;
public Plugin:myinfo =
{
	name = "Auto_BunnyHop",
	description = "Auto_BunnyHop",
	author = "H.se",
	version = "1.0",
	url = "n/a"
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

MoveType:GetEntityMoveType(entity)
{
	static bool:gotconfig;
	static String:datamap[32];
	if (!gotconfig)
	{
		new Handle:gc = LoadGameConfigFile("core.games");
		new bool:exists = GameConfGetKeyValue(gc, "m_MoveType", datamap, 32);
		CloseHandle(gc);
		if (!exists)
		{
			strcopy(datamap, 32, "m_MoveType");
		}
		gotconfig = true;
	}
	return GetEntProp(entity, PropType:1, datamap, 4, 0);
}

CPrintToChat(client, String:szMessage[])
{
	new var1;
	if (client <= 0 || client > MaxClients)
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
	Format(szBuffer, 250, "\x01%s", szMessage);
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
		CEventIsHooked = true;
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
			ReplaceString(szMessage, maxlength, "{teamcolor}", CTagCode[1], true);
		}
	}
	else
	{
		ReplaceString(szMessage, maxlength, "{teamcolor}", "", true);
	}
	new i;
	while (i < 6)
	{
		if (!(StrContains(szMessage, CTag[i], true) == -1))
		{
			if (!CProfile_Colors[i])
			{
				ReplaceString(szMessage, maxlength, CTag[i], CTagCode[1], true);
			}
			else
			{
				if (!CTagReqSayText2[i])
				{
					ReplaceString(szMessage, maxlength, CTag[i], CTagCode[i], true);
				}
				if (!CProfile_SayText2)
				{
					ReplaceString(szMessage, maxlength, CTag[i], CTagCode[1], true);
				}
				if (iRandomPlayer == -1)
				{
					iRandomPlayer = CFindRandomPlayerByTeam(CProfile_TeamIndex[i]);
					if (iRandomPlayer == -2)
					{
						ReplaceString(szMessage, maxlength, CTag[i], CTagCode[1], true);
					}
					else
					{
						ReplaceString(szMessage, maxlength, CTag[i], CTagCode[i], true);
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
			new var1;
			if (IsClientInGame(i) && color_team == GetClientTeam(i))
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
	if (GetUserMessageType() == 1)
	{
		PbSetInt(hBuffer, "ent_idx", author, -1);
		PbSetBool(hBuffer, "chat", true, -1);
		PbSetString(hBuffer, "msg_name", szMessage, -1);
		PbAddString(hBuffer, "params", "");
		PbAddString(hBuffer, "params", "");
		PbAddString(hBuffer, "params", "");
		PbAddString(hBuffer, "params", "");
	}
	else
	{
		BfWriteByte(hBuffer, author);
		BfWriteByte(hBuffer, 1);
		BfWriteString(hBuffer, szMessage);
	}
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
		CProfile_SayText2 = true;
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
			CProfile_SayText2 = true;
		}
		new var1;
		if (StrEqual(szGameName, "left4dead", false) || StrEqual(szGameName, "left4dead2", false))
		{
			CProfile_Colors[2] = 1;
			CProfile_Colors[3] = 1;
			CProfile_Colors[4] = 1;
			CProfile_Colors[5] = 1;
			CProfile_TeamIndex[2] = 0;
			CProfile_TeamIndex[3] = 3;
			CProfile_TeamIndex[4] = 2;
			CProfile_SayText2 = true;
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
				CProfile_SayText2 = true;
			}
			else
			{
				CProfile_SayText2 = false;
				CProfile_Colors[5] = 1;
			}
		}
		if (StrEqual(szGameName, "dod", false))
		{
			CProfile_Colors[5] = 1;
			CProfile_SayText2 = false;
		}
		if (GetUserMessageId("SayText2") == -1)
		{
			CProfile_SayText2 = false;
		}
		CProfile_Colors[3] = 1;
		CProfile_Colors[4] = 1;
		CProfile_TeamIndex[3] = 2;
		CProfile_TeamIndex[4] = 3;
		CProfile_SayText2 = true;
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
	sm_bhop_enabled = CreateConVar("sm_bhop_enabled", "1", "", 0, false, 0.0, false, 0.0);
	bhop_enabled = GetConVarInt(sm_bhop_enabled);
	HookConVarChange(sm_bhop_enabled, BhopSettingChanged);
	sm_bhop_autobhop = CreateConVar("sm_bhop_autobhop", "1", "", 0, false, 0.0, false, 0.0);
	bhop_autobhop = GetConVarInt(sm_bhop_autobhop);
	HookConVarChange(sm_bhop_autobhop, BhopSettingChanged);
	RegConsoleCmd("sm_autobhop", Cmd_autobhop, "Command to activate Easy Bunny on ourselves", 0);
	return 0;
}

public BhopSettingChanged(Handle:convar, String:oldValue[], String:newValue[])
{
	if (sm_bhop_enabled == convar)
	{
		bhop_enabled = GetConVarInt(sm_bhop_enabled);
	}
	else
	{
		if (sm_bhop_autobhop == convar)
		{
			bhop_autobhop = GetConVarInt(sm_bhop_autobhop);
		}
	}
	return 0;
}

public OnClientAuthorized(client)
{
	if (bhop_enabled == 1)
	{
		Keys_create(client);
	}
	return 0;
}

Keys_create(client)
{
	autobhop_player[client] = 1;
	return 0;
}

public Action:Cmd_autobhop(client, args)
{
	if (bhop_enabled == 1)
	{
		if (bhop_autobhop == 1)
		{
			if (autobhop_player[client] == 1)
			{
				autobhop_player[client] = 0;
				CPrintToChat(client, "{blue}Auto_BunyHop {olive}disabled");
			}
			if (!autobhop_player[client])
			{
				autobhop_player[client] = 1;
				CPrintToChat(client, "{blue}Auto_BunyHop {olive}enabled");
			}
		}
	}
	return Action:3;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (bhop_enabled == 1)
	{
		if (bhop_autobhop == 1)
		{
			new var1;
			if (autobhop_player[client] == 1 && IsPlayerAlive(client))
			{
				if (buttons & 2)
				{
					if (!GetEntityFlags(client) & 1)
					{
						if (!GetEntityMoveType(client) & 9)
						{
							new iType = GetEntProp(client, PropType:1, "m_nWaterLevel", 4, 0);
							if (iType <= 1)
							{
								buttons = buttons & -3;
							}
						}
					}
				}
			}
		}
	}
	return Action:0;
}

