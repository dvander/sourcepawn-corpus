public PlVers:__version =
{
	version = 5,
	filevers = "1.7.3-dev+5290",
	date = "04/01/2016",
	time = "01:17:09"
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
public Plugin:myinfo =
{
	name = "Admin Chat",
	description = "Admin Chat match",
	author = "",
	version = "1.0",
	url = ""
};
new String:C_Tag[18][] =
{
	"{default}",
	"{darkred}",
	"{green}",
	"{lightgreen}",
	"{red}",
	"{blue}",
	"{olive}",
	"{lime}",
	"{lightred}",
	"{purple}",
	"{grey}",
	"{orange}",
	"{bluegrey}",
	"{lightblue}",
	"{darkblue}",
	"{grey2}",
	"{orchid}",
	"{lightred2}"
};
new String:C_TagCode[18][16] =
{
	"\x01",
	"\x02",
	"\x04",
	"\x03",
	"\x03",
	"\x03",
	"\x05",
	"\x06",
	"\x07",
	"\x03",
	"\x08",
	"\x09",
	"\n",
	"\x0B",
	"\x0C",
	"\r",
	"\x0E",
	"\x0F"
};
new bool:C_TagReqSayText2[18] =
{
	0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
};
new bool:C_EventIsHooked;
new bool:C_SkipList[66];
new bool:C_Profile_Colors[18] =
{
	1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
};
new C_Profile_TeamIndex[18] =
{
	-1, ...
};
new bool:C_Profile_SayText2;
public Extension:__ext_regex =
{
	name = "Regex Extension",
	file = "regex.ext",
	autoload = 1,
	required = 1,
};
new bool:MC_SkipList[66];
new Handle:MC_Trie;
new MC_TeamColors[1][3] =
{
	{
		13421772, 5077314, 16728128
	}
};
new Handle:sm_show_activity = 1635151433;
new bool:g_bCFixColors;
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
	MarkNativeAsOptional("BfWrite.WriteBool");
	MarkNativeAsOptional("BfWrite.WriteByte");
	MarkNativeAsOptional("BfWrite.WriteChar");
	MarkNativeAsOptional("BfWrite.WriteShort");
	MarkNativeAsOptional("BfWrite.WriteWord");
	MarkNativeAsOptional("BfWrite.WriteNum");
	MarkNativeAsOptional("BfWrite.WriteFloat");
	MarkNativeAsOptional("BfWrite.WriteString");
	MarkNativeAsOptional("BfWrite.WriteEntity");
	MarkNativeAsOptional("BfWrite.WriteAngle");
	MarkNativeAsOptional("BfWrite.WriteCoord");
	MarkNativeAsOptional("BfWrite.WriteVecCoord");
	MarkNativeAsOptional("BfWrite.WriteVecNormal");
	MarkNativeAsOptional("BfWrite.WriteAngles");
	MarkNativeAsOptional("BfRead.ReadBool");
	MarkNativeAsOptional("BfRead.ReadByte");
	MarkNativeAsOptional("BfRead.ReadChar");
	MarkNativeAsOptional("BfRead.ReadShort");
	MarkNativeAsOptional("BfRead.ReadWord");
	MarkNativeAsOptional("BfRead.ReadNum");
	MarkNativeAsOptional("BfRead.ReadFloat");
	MarkNativeAsOptional("BfRead.ReadString");
	MarkNativeAsOptional("BfRead.ReadEntity");
	MarkNativeAsOptional("BfRead.ReadAngle");
	MarkNativeAsOptional("BfRead.ReadCoord");
	MarkNativeAsOptional("BfRead.ReadVecCoord");
	MarkNativeAsOptional("BfRead.ReadVecNormal");
	MarkNativeAsOptional("BfRead.ReadAngles");
	MarkNativeAsOptional("BfRead.GetNumBytesLeft");
	MarkNativeAsOptional("PbReadInt");
	MarkNativeAsOptional("PbReadFloat");
	MarkNativeAsOptional("PbReadBool");
	MarkNativeAsOptional("PbReadString");
	MarkNativeAsOptional("PbReadColor");
	MarkNativeAsOptional("PbReadAngle");
	MarkNativeAsOptional("PbReadVector");
	MarkNativeAsOptional("PbReadVector2D");
	MarkNativeAsOptional("PbGetRepeatedFieldCount");
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
	MarkNativeAsOptional("PbRemoveRepeatedFieldValue");
	MarkNativeAsOptional("PbReadMessage");
	MarkNativeAsOptional("PbReadRepeatedMessage");
	MarkNativeAsOptional("PbAddMessage");
	MarkNativeAsOptional("Protobuf.ReadInt");
	MarkNativeAsOptional("Protobuf.ReadFloat");
	MarkNativeAsOptional("Protobuf.ReadBool");
	MarkNativeAsOptional("Protobuf.ReadString");
	MarkNativeAsOptional("Protobuf.ReadColor");
	MarkNativeAsOptional("Protobuf.ReadAngle");
	MarkNativeAsOptional("Protobuf.ReadVector");
	MarkNativeAsOptional("Protobuf.ReadVector2D");
	MarkNativeAsOptional("Protobuf.GetRepeatedFieldCount");
	MarkNativeAsOptional("Protobuf.SetInt");
	MarkNativeAsOptional("Protobuf.SetFloat");
	MarkNativeAsOptional("Protobuf.SetBool");
	MarkNativeAsOptional("Protobuf.SetString");
	MarkNativeAsOptional("Protobuf.SetColor");
	MarkNativeAsOptional("Protobuf.SetAngle");
	MarkNativeAsOptional("Protobuf.SetVector");
	MarkNativeAsOptional("Protobuf.SetVector2D");
	MarkNativeAsOptional("Protobuf.AddInt");
	MarkNativeAsOptional("Protobuf.AddFloat");
	MarkNativeAsOptional("Protobuf.AddBool");
	MarkNativeAsOptional("Protobuf.AddString");
	MarkNativeAsOptional("Protobuf.AddColor");
	MarkNativeAsOptional("Protobuf.AddAngle");
	MarkNativeAsOptional("Protobuf.AddVector");
	MarkNativeAsOptional("Protobuf.AddVector2D");
	MarkNativeAsOptional("Protobuf.RemoveRepeatedFieldValue");
	MarkNativeAsOptional("Protobuf.ReadMessage");
	MarkNativeAsOptional("Protobuf.ReadRepeatedMessage");
	MarkNativeAsOptional("Protobuf.AddMessage");
	VerifyCoreVersion();
	return 0;
}

CharToLower(chr)
{
	if (IsCharUpper(chr))
	{
		return chr | 32;
	}
	return chr;
}

Handle:StartMessageOne(String:msgname[], client, flags)
{
	new players[1];
	players[0] = client;
	return StartMessage(msgname, players, 1, flags);
}

C_PrintToChatEx(client, author, String:szMessage[])
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
	new var2;
	if (author < 0 || author > MaxClients)
	{
		ThrowError("Invalid client index %d", author);
	}
	decl String:szBuffer[252];
	decl String:szCMessage[252];
	SetGlobalTransTarget(client);
	Format(szBuffer, 250, "\x01%s", szMessage);
	VFormat(szCMessage, 250, szBuffer, 4);
	new index = C_Format(szCMessage, 250, author);
	if (index == -1)
	{
		PrintToChat(client, "%s", szCMessage);
	}
	else
	{
		C_SayText2(client, author, szCMessage);
	}
	return 0;
}

C_PrintToChatAllEx(author, String:szMessage[])
{
	new var1;
	if (author < 0 || author > MaxClients)
	{
		ThrowError("Invalid client index %d", author);
	}
	if (!IsClientInGame(author))
	{
		ThrowError("Client %d is not in game", author);
	}
	decl String:szBuffer[252];
	new i = 1;
	while (i <= MaxClients)
	{
		new var2;
		if (IsClientInGame(i) && !IsFakeClient(i) && !C_SkipList[i])
		{
			SetGlobalTransTarget(i);
			VFormat(szBuffer, 250, szMessage, 3);
			C_PrintToChatEx(i, author, "%s", szBuffer);
		}
		C_SkipList[i] = 0;
		i++;
	}
	return 0;
}

C_ColorAllowed(C_Colors:color)
{
	if (!C_EventIsHooked)
	{
		C_SetupProfile();
		C_EventIsHooked = true;
	}
	return C_Profile_Colors[color];
}

C_ReplaceColor(C_Colors:color, C_Colors:newColor)
{
	if (!C_EventIsHooked)
	{
		C_SetupProfile();
		C_EventIsHooked = true;
	}
	C_Profile_Colors[color] = C_Profile_Colors[newColor];
	C_Profile_TeamIndex[color] = C_Profile_TeamIndex[newColor];
	C_TagReqSayText2[color] = C_TagReqSayText2[newColor];
	Format(C_TagCode[color], 4, C_TagCode[newColor]);
	return 0;
}

C_Format(String:szMessage[], maxlength, author)
{
	if (!C_EventIsHooked)
	{
		C_SetupProfile();
		HookEvent("server_spawn", C_Event_MapStart, EventHookMode:2);
		C_EventIsHooked = true;
	}
	new iRandomPlayer = -1;
	if (GetEngineVersion() == 12)
	{
		Format(szMessage, maxlength, " %s", szMessage);
	}
	if (author != -1)
	{
		if (C_Profile_SayText2)
		{
			ReplaceString(szMessage, maxlength, "{teamcolor}", "\x03", false);
			iRandomPlayer = author;
		}
		else
		{
			ReplaceString(szMessage, maxlength, "{teamcolor}", C_TagCode[2], false);
		}
	}
	else
	{
		ReplaceString(szMessage, maxlength, "{teamcolor}", "", false);
	}
	new i;
	while (i < 18)
	{
		if (!(StrContains(szMessage, C_Tag[i], false) == -1))
		{
			if (!C_Profile_Colors[i])
			{
				ReplaceString(szMessage, maxlength, C_Tag[i], C_TagCode[2], false);
			}
			else
			{
				if (!C_TagReqSayText2[i])
				{
					ReplaceString(szMessage, maxlength, C_Tag[i], C_TagCode[i], false);
				}
				if (!C_Profile_SayText2)
				{
					ReplaceString(szMessage, maxlength, C_Tag[i], C_TagCode[2], false);
				}
				if (iRandomPlayer == -1)
				{
					iRandomPlayer = C_FindRandomPlayerByTeam(C_Profile_TeamIndex[i]);
					if (iRandomPlayer == -2)
					{
						ReplaceString(szMessage, maxlength, C_Tag[i], C_TagCode[2], false);
					}
					else
					{
						ReplaceString(szMessage, maxlength, C_Tag[i], C_TagCode[i], false);
					}
				}
				ThrowError("Using two team colors in one message is not allowed");
			}
		}
		i++;
	}
	return iRandomPlayer;
}

C_FindRandomPlayerByTeam(color_team)
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

C_SayText2(client, author, String:szMessage[])
{
	new Handle:hBuffer = StartMessageOne("SayText2", client, 132);
	new var1;
	if (GetFeatureStatus(FeatureType:0, "GetUserMessageType") && GetUserMessageType() == 1)
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

C_SetupProfile()
{
	new EngineVersion:engine = GetEngineVersion();
	if (engine == EngineVersion:13)
	{
		C_Profile_Colors[3] = 1;
		C_Profile_Colors[4] = 1;
		C_Profile_Colors[5] = 1;
		C_Profile_Colors[6] = 1;
		C_Profile_TeamIndex[3] = 0;
		C_Profile_TeamIndex[4] = 2;
		C_Profile_TeamIndex[5] = 3;
		C_Profile_SayText2 = true;
	}
	else
	{
		if (engine == EngineVersion:12)
		{
			C_Profile_Colors[4] = 1;
			C_Profile_Colors[5] = 1;
			C_Profile_Colors[6] = 1;
			C_Profile_Colors[1] = 1;
			C_Profile_Colors[7] = 1;
			C_Profile_Colors[8] = 1;
			C_Profile_Colors[9] = 1;
			C_Profile_Colors[10] = 1;
			C_Profile_Colors[11] = 1;
			C_Profile_Colors[12] = 1;
			C_Profile_Colors[13] = 1;
			C_Profile_Colors[14] = 1;
			C_Profile_Colors[15] = 1;
			C_Profile_Colors[16] = 1;
			C_Profile_Colors[17] = 1;
			C_Profile_TeamIndex[4] = 2;
			C_Profile_TeamIndex[5] = 3;
			C_Profile_SayText2 = true;
		}
		if (engine == EngineVersion:17)
		{
			C_Profile_Colors[3] = 1;
			C_Profile_Colors[4] = 1;
			C_Profile_Colors[5] = 1;
			C_Profile_Colors[6] = 1;
			C_Profile_TeamIndex[3] = 0;
			C_Profile_TeamIndex[4] = 2;
			C_Profile_TeamIndex[5] = 3;
			C_Profile_SayText2 = true;
		}
		new var1;
		if (engine == EngineVersion:4 || engine == EngineVersion:7)
		{
			C_Profile_Colors[3] = 1;
			C_Profile_Colors[4] = 1;
			C_Profile_Colors[5] = 1;
			C_Profile_Colors[6] = 1;
			C_Profile_TeamIndex[3] = 0;
			C_Profile_TeamIndex[4] = 3;
			C_Profile_TeamIndex[5] = 2;
			C_Profile_SayText2 = true;
		}
		if (engine == EngineVersion:15)
		{
			if (GetConVarBool(FindConVar("mp_teamplay")))
			{
				C_Profile_Colors[4] = 1;
				C_Profile_Colors[5] = 1;
				C_Profile_Colors[6] = 1;
				C_Profile_TeamIndex[4] = 3;
				C_Profile_TeamIndex[5] = 2;
				C_Profile_SayText2 = true;
			}
			else
			{
				C_Profile_SayText2 = false;
				C_Profile_Colors[6] = 1;
			}
		}
		if (engine == EngineVersion:16)
		{
			C_Profile_Colors[6] = 1;
			C_Profile_SayText2 = false;
		}
		if (GetUserMessageId("SayText2") == -1)
		{
			C_Profile_SayText2 = false;
		}
		C_Profile_Colors[4] = 1;
		C_Profile_Colors[5] = 1;
		C_Profile_TeamIndex[4] = 2;
		C_Profile_TeamIndex[5] = 3;
		C_Profile_SayText2 = true;
	}
	return 0;
}

public Action:C_Event_MapStart(Handle:event, String:name[], bool:dontBroadcast)
{
	C_SetupProfile();
	new i = 1;
	while (i <= MaxClients)
	{
		C_SkipList[i] = 0;
		i++;
	}
	return Action:0;
}

MC_PrintToChatAllEx(author, String:message[])
{
	MC_CheckTrie();
	new var1;
	if (author <= 0 || author > MaxClients)
	{
		ThrowError(sm_show_activity, author);
	}
	if (!IsClientInGame(author))
	{
		ThrowError("Client %i is not in game", author);
	}
	decl String:buffer[1024];
	decl String:buffer2[1024];
	new i = 1;
	while (i <= MaxClients)
	{
		new var2;
		if (!IsClientInGame(i) || MC_SkipList[i])
		{
			MC_SkipList[i] = 0;
		}
		else
		{
			SetGlobalTransTarget(i);
			Format(buffer, 1024, "\x01%s", message);
			VFormat(buffer2, 1024, buffer, 3);
			MC_ReplaceColorCodes(buffer2, author, false, 1024);
			MC_SendMessage(i, buffer2, author);
		}
		i++;
	}
	return 0;
}

MC_SendMessage(client, String:message[], author)
{
	if (!author)
	{
		author = client;
	}
	decl String:buffer[256];
	strcopy(buffer, 256, message);
	new UserMsg:index = GetUserMessageId("SayText2");
	if (index == UserMsg:-1)
	{
		if (GetEngineVersion() == 16)
		{
			new team = GetClientTeam(author);
			if (team)
			{
				decl String:temp[16];
				new var2 = MC_TeamColors;
				Format(temp, 16, "\x07%06X", var2[0][var2][team + -1]);
				ReplaceString(buffer, 256, "\x03", temp, false);
			}
			else
			{
				ReplaceString(buffer, 256, "\x03", "\x04", false);
			}
		}
		PrintToChat(client, "%s", buffer);
		return 0;
	}
	new Handle:buf = StartMessageOne("SayText2", client, 132);
	new var1;
	if (GetFeatureStatus(FeatureType:0, "GetUserMessageType") && GetUserMessageType() == 1)
	{
		PbSetInt(buf, "ent_idx", author, -1);
		PbSetBool(buf, "chat", true, -1);
		PbSetString(buf, "msg_name", buffer, -1);
		PbAddString(buf, "params", "");
		PbAddString(buf, "params", "");
		PbAddString(buf, "params", "");
		PbAddString(buf, "params", "");
	}
	else
	{
		BfWriteByte(buf, author);
		BfWriteByte(buf, 1);
		BfWriteString(buf, buffer);
	}
	EndMessage();
	return 0;
}

MC_CheckTrie()
{
	if (!MC_Trie)
	{
		MC_Trie = MC_InitColorTrie();
	}
	return 0;
}

MC_ReplaceColorCodes(String:buffer[], author, bool:removeTags, maxlen)
{
	MC_CheckTrie();
	if (!removeTags)
	{
		ReplaceString(buffer, maxlen, "{default}", "\x01", false);
	}
	else
	{
		ReplaceString(buffer, maxlen, "{default}", "", false);
		ReplaceString(buffer, maxlen, "{teamcolor}", "", false);
	}
	new var1;
	if (author && !removeTags)
	{
		new var2;
		if (author < 0 || author > MaxClients)
		{
			ThrowError("Invalid client index %i", author);
		}
		if (!IsClientInGame(author))
		{
			ThrowError("Client %i is not in game", author);
		}
		ReplaceString(buffer, maxlen, "{teamcolor}", "\x03", false);
	}
	new cursor;
	new value;
	decl String:tag[32];
	decl String:buff[32];
	decl output[maxlen];
	strcopy(output, maxlen, buffer);
	new Handle:regex = CompileRegex("{[a-zA-Z0-9]+}", 0, "", 0, 0);
	new i;
	while (i < 1000)
	{
		if (MatchRegex(regex, buffer[cursor], 0) < 1)
		{
			CloseHandle(regex);
			strcopy(buffer, maxlen, output);
			return 0;
		}
		GetRegexSubString(regex, 0, tag, 32);
		MC_StrToLower(tag);
		cursor = StrContains(buffer[cursor], tag, false) + cursor + 1;
		strcopy(buff, 32, tag);
		ReplaceString(buff, 32, "{", "", true);
		ReplaceString(buff, 32, "}", "", true);
		if (GetTrieValue(MC_Trie, buff, value))
		{
			if (removeTags)
			{
				ReplaceString(output, maxlen, tag, "", false);
			}
			else
			{
				Format(buff, 32, "\x07%06X", value);
				ReplaceString(output, maxlen, tag, buff, false);
			}
		}
		i++;
	}
	LogError("[MORE COLORS] Infinite loop broken.");
	return 0;
}

MC_StrToLower(String:buffer[])
{
	new len = strlen(buffer);
	new i;
	while (i < len)
	{
		buffer[i] = CharToLower(buffer[i]);
		i++;
	}
	return 0;
}

Handle:MC_InitColorTrie()
{
	new Handle:hTrie = CreateTrie();
	SetTrieValue(hTrie, "aliceblue", any:15792383, true);
	SetTrieValue(hTrie, "allies", any:5077314, true);
	SetTrieValue(hTrie, "ancient", any:15420235, true);
	SetTrieValue(hTrie, "antiquewhite", any:16444375, true);
	SetTrieValue(hTrie, "aqua", any:65535, true);
	SetTrieValue(hTrie, "aquamarine", any:8388564, true);
	SetTrieValue(hTrie, "arcana", any:11396444, true);
	SetTrieValue(hTrie, "axis", any:16728128, true);
	SetTrieValue(hTrie, "azure", any:32767, true);
	SetTrieValue(hTrie, "beige", any:16119260, true);
	SetTrieValue(hTrie, "bisque", any:16770244, true);
	SetTrieValue(hTrie, "black", any:0, true);
	SetTrieValue(hTrie, "blanchedalmond", any:16772045, true);
	SetTrieValue(hTrie, "blue", any:10079487, true);
	SetTrieValue(hTrie, "blueviolet", any:9055202, true);
	SetTrieValue(hTrie, "brown", any:10824234, true);
	SetTrieValue(hTrie, "burlywood", any:14596231, true);
	SetTrieValue(hTrie, "cadetblue", any:6266528, true);
	SetTrieValue(hTrie, "chartreuse", any:8388352, true);
	SetTrieValue(hTrie, "chocolate", any:13789470, true);
	SetTrieValue(hTrie, "collectors", any:11141120, true);
	SetTrieValue(hTrie, "common", any:11584473, true);
	SetTrieValue(hTrie, "community", any:7385162, true);
	SetTrieValue(hTrie, "coral", any:16744272, true);
	SetTrieValue(hTrie, "cornflowerblue", any:6591981, true);
	SetTrieValue(hTrie, "cornsilk", any:16775388, true);
	SetTrieValue(hTrie, "corrupted", any:10693678, true);
	SetTrieValue(hTrie, "crimson", any:14423100, true);
	SetTrieValue(hTrie, "cyan", any:65535, true);
	SetTrieValue(hTrie, "darkblue", any:139, true);
	SetTrieValue(hTrie, "darkcyan", any:35723, true);
	SetTrieValue(hTrie, "darkgoldenrod", any:12092939, true);
	SetTrieValue(hTrie, "darkgray", any:11119017, true);
	SetTrieValue(hTrie, "darkgrey", any:11119017, true);
	SetTrieValue(hTrie, "darkgreen", any:25600, true);
	SetTrieValue(hTrie, "darkkhaki", any:12433259, true);
	SetTrieValue(hTrie, "darkmagenta", any:9109643, true);
	SetTrieValue(hTrie, "darkolivegreen", any:5597999, true);
	SetTrieValue(hTrie, "darkorange", any:16747520, true);
	SetTrieValue(hTrie, "darkorchid", any:10040012, true);
	SetTrieValue(hTrie, "darkred", any:9109504, true);
	SetTrieValue(hTrie, "darksalmon", any:15308410, true);
	SetTrieValue(hTrie, "darkseagreen", any:9419919, true);
	SetTrieValue(hTrie, "darkslateblue", any:4734347, true);
	SetTrieValue(hTrie, "darkslategray", any:3100495, true);
	SetTrieValue(hTrie, "darkslategrey", any:3100495, true);
	SetTrieValue(hTrie, "darkturquoise", any:52945, true);
	SetTrieValue(hTrie, "darkviolet", any:9699539, true);
	SetTrieValue(hTrie, "deeppink", any:16716947, true);
	SetTrieValue(hTrie, "deepskyblue", any:49151, true);
	SetTrieValue(hTrie, "dimgray", any:6908265, true);
	SetTrieValue(hTrie, "dimgrey", any:6908265, true);
	SetTrieValue(hTrie, "dodgerblue", any:2003199, true);
	SetTrieValue(hTrie, "exalted", any:13421773, true);
	SetTrieValue(hTrie, "firebrick", any:11674146, true);
	SetTrieValue(hTrie, "floralwhite", any:16775920, true);
	SetTrieValue(hTrie, "forestgreen", any:2263842, true);
	SetTrieValue(hTrie, "frozen", any:4817843, true);
	SetTrieValue(hTrie, "fuchsia", any:16711935, true);
	SetTrieValue(hTrie, "fullblue", any:255, true);
	SetTrieValue(hTrie, "fullred", any:16711680, true);
	SetTrieValue(hTrie, "gainsboro", any:14474460, true);
	SetTrieValue(hTrie, "genuine", any:5076053, true);
	SetTrieValue(hTrie, "ghostwhite", any:16316671, true);
	SetTrieValue(hTrie, "gold", any:16766720, true);
	SetTrieValue(hTrie, "goldenrod", any:14329120, true);
	SetTrieValue(hTrie, "gray", any:13421772, true);
	SetTrieValue(hTrie, "grey", any:13421772, true);
	SetTrieValue(hTrie, "green", any:4128574, true);
	SetTrieValue(hTrie, "greenyellow", any:11403055, true);
	SetTrieValue(hTrie, "haunted", any:3732395, true);
	SetTrieValue(hTrie, "honeydew", any:15794160, true);
	SetTrieValue(hTrie, "hotpink", any:16738740, true);
	SetTrieValue(hTrie, "immortal", any:14986803, true);
	SetTrieValue(hTrie, "indianred", any:13458524, true);
	SetTrieValue(hTrie, "indigo", any:4915330, true);
	SetTrieValue(hTrie, "ivory", any:16777200, true);
	SetTrieValue(hTrie, "khaki", any:15787660, true);
	SetTrieValue(hTrie, "lavender", any:15132410, true);
	SetTrieValue(hTrie, "lavenderblush", any:16773365, true);
	SetTrieValue(hTrie, "lawngreen", any:8190976, true);
	SetTrieValue(hTrie, "legendary", any:13839590, true);
	SetTrieValue(hTrie, "lemonchiffon", any:16775885, true);
	SetTrieValue(hTrie, "lightblue", any:11393254, true);
	SetTrieValue(hTrie, "lightcoral", any:15761536, true);
	SetTrieValue(hTrie, "lightcyan", any:14745599, true);
	SetTrieValue(hTrie, "lightgoldenrodyellow", any:16448210, true);
	SetTrieValue(hTrie, "lightgray", any:13882323, true);
	SetTrieValue(hTrie, "lightgrey", any:13882323, true);
	SetTrieValue(hTrie, "lightgreen", any:10092441, true);
	SetTrieValue(hTrie, "lightpink", any:16758465, true);
	SetTrieValue(hTrie, "lightsalmon", any:16752762, true);
	SetTrieValue(hTrie, "lightseagreen", any:2142890, true);
	SetTrieValue(hTrie, "lightskyblue", any:8900346, true);
	SetTrieValue(hTrie, "lightslategray", any:7833753, true);
	SetTrieValue(hTrie, "lightslategrey", any:7833753, true);
	SetTrieValue(hTrie, "lightsteelblue", any:11584734, true);
	SetTrieValue(hTrie, "lightyellow", any:16777184, true);
	SetTrieValue(hTrie, "lime", any:65280, true);
	SetTrieValue(hTrie, "limegreen", any:3329330, true);
	SetTrieValue(hTrie, "linen", any:16445670, true);
	SetTrieValue(hTrie, "magenta", any:16711935, true);
	SetTrieValue(hTrie, "maroon", any:8388608, true);
	SetTrieValue(hTrie, "mediumaquamarine", any:6737322, true);
	SetTrieValue(hTrie, "mediumblue", any:205, true);
	SetTrieValue(hTrie, "mediumorchid", any:12211667, true);
	SetTrieValue(hTrie, "mediumpurple", any:9662680, true);
	SetTrieValue(hTrie, "mediumseagreen", any:3978097, true);
	SetTrieValue(hTrie, "mediumslateblue", any:8087790, true);
	SetTrieValue(hTrie, "mediumspringgreen", any:64154, true);
	SetTrieValue(hTrie, "mediumturquoise", any:4772300, true);
	SetTrieValue(hTrie, "mediumvioletred", any:13047173, true);
	SetTrieValue(hTrie, "midnightblue", any:1644912, true);
	SetTrieValue(hTrie, "mintcream", any:16121850, true);
	SetTrieValue(hTrie, "mistyrose", any:16770273, true);
	SetTrieValue(hTrie, "moccasin", any:16770229, true);
	SetTrieValue(hTrie, "mythical", any:8931327, true);
	SetTrieValue(hTrie, "navajowhite", any:16768685, true);
	SetTrieValue(hTrie, "navy", any:128, true);
	SetTrieValue(hTrie, "normal", any:11711154, true);
	SetTrieValue(hTrie, "oldlace", any:16643558, true);
	SetTrieValue(hTrie, "olive", any:10404687, true);
	SetTrieValue(hTrie, "olivedrab", any:7048739, true);
	SetTrieValue(hTrie, "orange", any:16753920, true);
	SetTrieValue(hTrie, "orangered", any:16729344, true);
	SetTrieValue(hTrie, "orchid", any:14315734, true);
	SetTrieValue(hTrie, "palegoldenrod", any:15657130, true);
	SetTrieValue(hTrie, "palegreen", any:10025880, true);
	SetTrieValue(hTrie, "paleturquoise", any:11529966, true);
	SetTrieValue(hTrie, "palevioletred", any:14184595, true);
	SetTrieValue(hTrie, "papayawhip", any:16773077, true);
	SetTrieValue(hTrie, "peachpuff", any:16767673, true);
	SetTrieValue(hTrie, "peru", any:13468991, true);
	SetTrieValue(hTrie, "pink", any:16761035, true);
	SetTrieValue(hTrie, "plum", any:14524637, true);
	SetTrieValue(hTrie, "powderblue", any:11591910, true);
	SetTrieValue(hTrie, "purple", any:8388736, true);
	SetTrieValue(hTrie, "rare", any:4942335, true);
	SetTrieValue(hTrie, "red", any:16728128, true);
	SetTrieValue(hTrie, "rosybrown", any:12357519, true);
	SetTrieValue(hTrie, "royalblue", any:4286945, true);
	SetTrieValue(hTrie, "saddlebrown", any:9127187, true);
	SetTrieValue(hTrie, "salmon", any:16416882, true);
	SetTrieValue(hTrie, "sandybrown", any:16032864, true);
	SetTrieValue(hTrie, "seagreen", any:3050327, true);
	SetTrieValue(hTrie, "seashell", any:16774638, true);
	SetTrieValue(hTrie, "selfmade", any:7385162, true);
	SetTrieValue(hTrie, "sienna", any:10506797, true);
	SetTrieValue(hTrie, "silver", any:12632256, true);
	SetTrieValue(hTrie, "skyblue", any:8900331, true);
	SetTrieValue(hTrie, "slateblue", any:6970061, true);
	SetTrieValue(hTrie, "slategray", any:7372944, true);
	SetTrieValue(hTrie, "slategrey", any:7372944, true);
	SetTrieValue(hTrie, "snow", any:16775930, true);
	SetTrieValue(hTrie, "springgreen", any:65407, true);
	SetTrieValue(hTrie, "steelblue", any:4620980, true);
	SetTrieValue(hTrie, "strange", any:13593138, true);
	SetTrieValue(hTrie, "tan", any:13808780, true);
	SetTrieValue(hTrie, "teal", any:32896, true);
	SetTrieValue(hTrie, "thistle", any:14204888, true);
	SetTrieValue(hTrie, "tomato", any:16737095, true);
	SetTrieValue(hTrie, "turquoise", any:4251856, true);
	SetTrieValue(hTrie, "uncommon", any:11584473, true);
	SetTrieValue(hTrie, "unique", any:16766720, true);
	SetTrieValue(hTrie, "unusual", any:8802476, true);
	SetTrieValue(hTrie, "valve", any:10817401, true);
	SetTrieValue(hTrie, "vintage", any:4678289, true);
	SetTrieValue(hTrie, "violet", any:15631086, true);
	SetTrieValue(hTrie, "wheat", any:16113331, true);
	SetTrieValue(hTrie, "white", any:16777215, true);
	SetTrieValue(hTrie, "whitesmoke", any:16119285, true);
	SetTrieValue(hTrie, "yellow", any:16776960, true);
	SetTrieValue(hTrie, "yellowgreen", any:10145074, true);
	return hTrie;
}

CPrintToChatAllEx(author, String:message[])
{
	decl String:buffer[252];
	VFormat(buffer, 250, message, 3);
	if (!g_bCFixColors)
	{
		CFixColors();
	}
	if (GetEngineVersion() == 12)
	{
		C_PrintToChatAllEx(author, buffer);
	}
	else
	{
		MC_PrintToChatAllEx(author, buffer);
	}
	return 0;
}

CFixColors()
{
	g_bCFixColors = true;
	if (!C_ColorAllowed(C_Colors:3))
	{
		if (C_ColorAllowed(C_Colors:7))
		{
			C_ReplaceColor(C_Colors:3, C_Colors:7);
		}
		if (C_ColorAllowed(C_Colors:6))
		{
			C_ReplaceColor(C_Colors:3, C_Colors:6);
		}
	}
	return 0;
}

public void:OnPluginStart()
{
	AddCommandListener(SayHook, "say");
	return void:0;
}

public Action:SayHook(client, String:command[], args)
{
	new AdminId:AdminID = GetUserAdmin(client);
	if (AdminID == AdminId:-1)
	{
		return Action:0;
	}
	decl String:Name[32];
	decl String:Msg[256];
	GetClientName(client, Name, 32);
	GetCmdArgString(Msg, 256);
	Msg[strlen(Msg) + -1] = MissingTAG:0;
	CPrintToChatAllEx(client, "{default}[{green}ADMIN{default}] {teamcolor}%s: {default}%s", Name, Msg[0]);
	return Action:3;
}

