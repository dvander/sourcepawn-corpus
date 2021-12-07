/*
** ATTENTION
** THE PRODUCED CODE, IS NOT ABLE TO COMPILE!
** THE DECOMPILER JUST TRIES TO GIVE YOU A POSSIBILITY
** TO LOOK HOW A PLUGIN DOES IT'S JOB AND LOOK FOR
** POSSIBLE MALICIOUS CODE.
**
** ALL CONVERSIONS ARE WRONG! AT EXAMPLE:
** SetEntityRenderFx(client, RenderFx 0);  →  SetEntityRenderFx(client, view_as<RenderFx>0);  →  SetEntityRenderFx(client, RENDERFX_NONE);
*/

 PlVers __version = 5;
 float NULL_VECTOR[3];
 char NULL_STRING[1];
 Extension __ext_core = 68;
 int MaxClients;
 Extension __ext_sdktools = 188;
 Extension __ext_sdkhooks = 232;
 Extension __ext_topmenus = 276;
 SharedPlugin __pl_adminmenu = 320;
 char CTag[7][0];
 char CTagCode[7][4] =
{
	"\x01",
	"\x04",
	"\x04",
	"\x03",
	"\x03",
	"\x03",
	"\x05"
}
 bool CTagReqSayText2[7] =
{
	0, 0, 0, 1, 1, 1, 0
}
 bool CEventIsHooked;
 bool CProfile_Colors[7] =
{
	1, 1, 1, 0, 0, 0, 0
}
 int CProfile_TeamIndex[7] =
{
	-1, ...
}
 bool CProfile_SayText2;
 char map[32];
 Handle SetModel;
 Handle SetJiGuan;
 Handle SetTimer;
 bool IsModel;
 int IsPlayerLimit;
 int waittime;
 float pos2[3];
 float ang2[3];
public int __ext_core_SetNTVOptional()
{
	MarkNativeAsOptional("GetFeatureStatus");
	MarkNativeAsOptional("RequireFeature");
	MarkNativeAsOptional("AddCommandListener");
	MarkNativeAsOptional("RemoveCommandListener");
	VerifyCoreVersion();
	return 0;
}

int RoundFloat(float value)
{
	return RoundToNearest(value);
}

float operator*(Float:,_:)(float oper1, int oper2)
{
	return FloatMul(oper1, float(oper2));
}

bool operator<(Float:,Float:)(float oper1, float oper2)
{
	return FloatCompare(oper1, oper2) < 0;
}

bool StrEqual(char str1[], char str2[], bool caseSensitive)
{
	return strcmp(str1, str2, caseSensitive) == 0;
}

Handle StartMessageOne(char msgname[], int client, int flags)
{
	int players[1];
	players[0] = client;
	return StartMessage(msgname, players, 1, flags);
}

int PrintHintTextToAll(char format[])
{
	char buffer[192];
	int i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			SetGlobalTransTarget(i);
			VFormat(buffer, 192, format, 2);
			PrintHintText(i, "%s", buffer);
			i++;
		}
		i++;
	}
	return 0;
}


/* ERROR! Unrecognized opcode genarray_z */
 function "EmitSoundToAll" (number 7)
int CPrintToChat(int client, char szMessage[])
{
	int var1;
	if (client <= 0)
	{
		ThrowError("Invalid client index %d", client);
	}
	if (!IsClientInGame(client))
	{
		ThrowError("Client %d is not in game", client);
	}
	char szBuffer[252];
	char szCMessage[252];
	SetGlobalTransTarget(client);
	Format(szBuffer, 250, "\x01%s", szMessage);
	VFormat(szCMessage, 250, szBuffer, 3);
	int index = CFormat(szCMessage, 250, -1);
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

int CPrintToChatAll(char szMessage[])
{
	int i = 1;
	while (i <= MaxClients)
	{
		int var1;
		if (IsClientInGame(i))
		{
			char szBuffer[252];
			SetGlobalTransTarget(i);
			VFormat(szBuffer, 250, szMessage, 2);
			CPrintToChat(i, szBuffer);
			i++;
		}
		i++;
	}
	return 0;
}

int CFormat(char szMessage[], int maxlength, int author)
{
	if (!CEventIsHooked)
	{
		CSetupProfile();
		HookEvent("server_spawn", EventHook 1, EventHookMode 2);
		CEventIsHooked = 1;
	}
	int iRandomPlayer = -1;
	if (author != -1)
	{
		if (CProfile_SayText2)
		{
			ReplaceString(szMessage, maxlength, "{teamcolor}", "\x03", true);
			iRandomPlayer = author;
		}
		else
		{
			ReplaceString(szMessage, maxlength, "{teamcolor}", CTagCode[4][0], true);
		}
	}
	else
	{
		ReplaceString(szMessage, maxlength, "{teamcolor}", "", true);
	}
	int i = 0;
	while (i < 7)
	{
		if (!(StrContains(szMessage, CTag[i][0][0], true) == -1))
		{
			if (!CProfile_Colors[i][0][0])
			{
				ReplaceString(szMessage, maxlength, CTag[i][0][0], CTagCode[4][0], true);
			}
			else
			{
				if (!CTagReqSayText2[i][0][0])
				{
					ReplaceString(szMessage, maxlength, CTag[i][0][0], CTagCode[i][0][0], true);
				}
				if (!CProfile_SayText2)
				{
					ReplaceString(szMessage, maxlength, CTag[i][0][0], CTagCode[4][0], true);
				}
				if (iRandomPlayer == -1)
				{
					iRandomPlayer = CFindRandomPlayerByTeam(CProfile_TeamIndex[i][0][0]);
					if (iRandomPlayer == -2)
					{
						ReplaceString(szMessage, maxlength, CTag[i][0][0], CTagCode[4][0], true);
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

int CFindRandomPlayerByTeam(int color_team)
{
	if (color_team)
	{
		int i = 1;
		while (i <= MaxClients)
		{
			int var1;
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

int CSayText2(int client, int author, char szMessage[])
{
	Handle hBuffer = StartMessageOne("SayText2", client, 0);
	BfWriteByte(hBuffer, author);
	BfWriteByte(hBuffer, 1);
	BfWriteString(hBuffer, szMessage);
	EndMessage();
	return 0;
}

int CSetupProfile()
{
	char szGameName[32];
	GetGameFolderName(szGameName, 30);
	if (StrEqual(szGameName, "cstrike", false))
	{
		CProfile_Colors[12] = 1;
		CProfile_Colors[16] = 1;
		CProfile_Colors[20] = 1;
		CProfile_TeamIndex[12] = 0;
		CProfile_TeamIndex[16] = 2;
		CProfile_TeamIndex[20] = 3;
		CProfile_SayText2 = 1;
	}
	else
	{
		if (StrEqual(szGameName, "tf", false))
		{
			CProfile_Colors[12] = 1;
			CProfile_Colors[16] = 1;
			CProfile_Colors[20] = 1;
			CProfile_Colors[24] = 1;
			CProfile_TeamIndex[12] = 0;
			CProfile_TeamIndex[16] = 2;
			CProfile_TeamIndex[20] = 3;
			CProfile_SayText2 = 1;
		}
		if (StrEqual(szGameName, "left4dead", false))
		{
			CProfile_Colors[12] = 1;
			CProfile_Colors[16] = 1;
			CProfile_Colors[20] = 1;
			CProfile_Colors[24] = 1;
			CProfile_TeamIndex[12] = 0;
			CProfile_TeamIndex[16] = 3;
			CProfile_TeamIndex[20] = 2;
			CProfile_SayText2 = 1;
		}
		if (StrEqual(szGameName, "hl2mp", false))
		{
			if (GetConVarBool(FindConVar("mp_teamplay")))
			{
				CProfile_Colors[16] = 1;
				CProfile_Colors[20] = 1;
				CProfile_TeamIndex[16] = 3;
				CProfile_TeamIndex[20] = 2;
				CProfile_SayText2 = 1;
			}
			else
			{
				CProfile_SayText2 = 0;
			}
		}
		if (StrEqual(szGameName, "dod", false))
		{
			CProfile_Colors[24] = 1;
			CProfile_SayText2 = 0;
		}
		if (GetUserMessageId("SayText2") == -1)
		{
			CProfile_SayText2 = 0;
		}
		CProfile_Colors[16] = 1;
		CProfile_Colors[20] = 1;
		CProfile_TeamIndex[16] = 2;
		CProfile_TeamIndex[20] = 3;
		CProfile_SayText2 = 1;
	}
	return 0;
}

public Action CEvent_MapStart(Handle event, char name[], bool dontBroadcast)
{
	CSetupProfile();
	return Action 0;
}

public int OnPluginStart()
{
	HookEvent("round_start", EventHook 5, EventHookMode 1);
	HookEvent("round_end", EventHook 3, EventHookMode 1);
	return 0;
}

public int OnMapStart()
{
	PrecacheModel("models/props_urban/fence_gate001_256.mdl", false);
	PrecacheModel("models/props_interiors/makeshift_stove_battery.mdl", false);
	PrecacheSound("music/flu/jukebox/all_i_want_for_xmas.wav", true);
	GetCurrentMap(map, 128);
	return 0;
}

public Action Event_RoundStart(Handle event, char event_name[], bool dontBroadcast)
{
	IsModel = 0;
	IsPlayerLimit = 0;
	waittime = 0;
	if (SetModel)
	{
		KillTimer(SetModel, false);
		SetModel = 0;
	}
	if (SetJiGuan)
	{
		SetJiGuan = 0;
	}
	if (SetTimer)
	{
		KillTimer(SetTimer, false);
		SetTimer = 0;
	}
	CreateTimer(5, Timer_SetModel, any 0, 0);
	return Action 0;
}

public int Event_RoundEnd(Handle event, char name[], bool dontBroadcast)
{
	return 0;
}

public Action Timer_SetModel(Handle timer)
{
	SetConVarInt(FindConVar("director_panic_forever"), 0, false, false);
	int ent = CreateEntityByName("prop_dynamic", -1);
	float pos[3];
	float ang[3];
	if (StrEqual(map, "c1m1_hotel", false))
	{
		SetVector(pos2, 1594, 4548, 1205);
		SetVector(ang2, 0, -125, 0);
		DropBullet(pos2, ang2);
		SetVector(pos, 1831, 4589, 1184);
		SetVector(ang, 0, 0, 0);
		DispatchKeyValue(ent, "model", "models/props_urban/fence_gate001_256.mdl");
		SetEntProp(ent, PropType 0, "m_nSolidType", any 6, 4);
		DispatchSpawn(ent);
		TeleportEntity(ent, pos, ang, NULL_VECTOR);
		SetModel = CreateTimer(1, SetModel_Romve, ent, 1);
		CPrintToChatAll("\x01[Sys]：\x04The radio is already loaded");
	}
	if (StrEqual(map, "c1m2_streets", false))
	{
		SetVector(pos2, -5091, 977, 672);
		SetVector(ang2, 0, 30, 0);
		DropBullet(pos2, ang2);
		SetVector(pos, -5123, 808, 672);
		SetVector(ang, 0, -91, 0);
		DispatchKeyValue(ent, "model", "models/props_urban/fence_gate001_256.mdl");
		SetEntProp(ent, PropType 0, "m_nSolidType", any 6, 4);
		DispatchSpawn(ent);
		TeleportEntity(ent, pos, ang, NULL_VECTOR);
		SetModel = CreateTimer(1, SetModel_Romve, ent, 1);
		CPrintToChatAll("\x01[Sys]：\x04The radio is already loaded");
	}
	if (StrEqual(map, "c1m3_mall", false))
	{
		SetVector(pos2, -670, -4105, 536);
		SetVector(ang2, 0, 177, 0);
		DropBullet(pos2, ang2);
		SetVector(pos, -2049, -4515, 536);
		SetVector(ang, 0, -88, 0);
		DispatchKeyValue(ent, "model", "models/props_urban/fence_gate001_256.mdl");
		SetEntProp(ent, PropType 0, "m_nSolidType", any 6, 4);
		DispatchSpawn(ent);
		TeleportEntity(ent, pos, ang, NULL_VECTOR);
		SetModel = CreateTimer(1, SetModel_Romve, ent, 1);
		CPrintToChatAll("\x01[Sys]：\x04The radio is already loaded");
	}
	if (StrEqual(map, "c2m1_highway", false))
	{
		SetVector(pos2, -1107, -1947, -1036);
		SetVector(ang2, 0, 103, 0);
		DropBullet(pos2, ang2);
		SetVector(pos, -973, -2463, -1084);
		SetVector(ang, 0, -1, 0);
		DispatchKeyValue(ent, "model", "models/props_urban/fence_gate001_256.mdl");
		SetEntProp(ent, PropType 0, "m_nSolidType", any 6, 4);
		DispatchSpawn(ent);
		TeleportEntity(ent, pos, ang, NULL_VECTOR);
		SetModel = CreateTimer(1, SetModel_Romve, ent, 1);
		CPrintToChatAll("\x01[Sys]：\x04The radio is already loaded");
	}
	if (StrEqual(map, "c2m2_fairgrounds", false))
	{
		SetVector(pos2, -2908, -1882, -88);
		SetVector(ang2, 0, -89, 0);
		DropBullet(pos2, ang2);
		SetVector(pos, -2826, -1981, -128);
		SetVector(ang, 0, 176, 0);
		DispatchKeyValue(ent, "model", "models/props_urban/fence_gate001_256.mdl");
		SetEntProp(ent, PropType 0, "m_nSolidType", any 6, 4);
		DispatchSpawn(ent);
		TeleportEntity(ent, pos, ang, NULL_VECTOR);
		SetModel = CreateTimer(1, SetModel_Romve, ent, 1);
		CPrintToChatAll("\x01[Sys]：\x04The radio is already loaded");
	}
	if (StrEqual(map, "c2m3_coaster", false))
	{
		SetVector(pos2, -4120, 1902, 160);
		SetVector(ang2, 0, 89, 0);
		DropBullet(pos2, ang2);
		SetVector(pos, -4992, 1668, 4);
		SetVector(ang, 0, 179, 0);
		DispatchKeyValue(ent, "model", "models/props_urban/fence_gate001_256.mdl");
		SetEntProp(ent, PropType 0, "m_nSolidType", any 6, 4);
		DispatchSpawn(ent);
		TeleportEntity(ent, pos, ang, NULL_VECTOR);
		SetModel = CreateTimer(1, SetModel_Romve, ent, 1);
		CPrintToChatAll("\x01[Sys]：\x04The radio is already loaded");
	}
	if (StrEqual(map, "c2m4_barns", false))
	{
		SetVector(pos2, -1937, 843, -152);
		SetVector(ang2, 0, -2, 0);
		DropBullet(pos2, ang2);
		SetVector(pos, -2016, 258, -192);
		SetVector(ang, 0, -89, 0);
		DispatchKeyValue(ent, "model", "models/props_urban/fence_gate001_256.mdl");
		SetEntProp(ent, PropType 0, "m_nSolidType", any 6, 4);
		DispatchSpawn(ent);
		TeleportEntity(ent, pos, ang, NULL_VECTOR);
		SetModel = CreateTimer(1, SetModel_Romve, ent, 1);
		CPrintToChatAll("\x01[Sys]：\x04The radio is already loaded");
	}
	if (StrEqual(map, "c3m1_plankcountry", false))
	{
		SetVector(pos2, -991, 5050, 180);
		SetVector(ang2, 0, -1, 0);
		DropBullet(pos2, ang2);
		SetVector(pos, -1018, 4642, 144);
		SetVector(ang, 0, -90, 0);
		DispatchKeyValue(ent, "model", "models/props_urban/fence_gate001_256.mdl");
		SetEntProp(ent, PropType 0, "m_nSolidType", any 6, 4);
		DispatchSpawn(ent);
		TeleportEntity(ent, pos, ang, NULL_VECTOR);
		SetModel = CreateTimer(1, SetModel_Romve, ent, 1);
		CPrintToChatAll("\x01[Sys]：\x04The radio is already loaded");
	}
	if (StrEqual(map, "c3m2_swamp", false))
	{
		SetVector(pos2, 7672, -707, 127);
		SetVector(ang2, 0, -63, 0);
		DropBullet(pos2, ang2);
		SetVector(pos, 7534, -788, 136);
		SetVector(ang, 0, -91, 0);
		DispatchKeyValue(ent, "model", "models/props_urban/fence_gate001_256.mdl");
		SetEntProp(ent, PropType 0, "m_nSolidType", any 6, 4);
		DispatchSpawn(ent);
		TeleportEntity(ent, pos, ang, NULL_VECTOR);
		SetModel = CreateTimer(1, SetModel_Romve, ent, 1);
		CPrintToChatAll("\x01[Sys]：\x04The radio is already loaded");
	}
	if (StrEqual(map, "c3m3_shantytown", false))
	{
		SetVector(pos2, 4108, -4115, 260);
		SetVector(ang2, 0, 89, 0);
		DropBullet(pos2, ang2);
		SetVector(pos, 5011, -3888, 350);
		SetVector(ang, 0, 88, 0);
		DispatchKeyValue(ent, "model", "models/props_urban/fence_gate001_256.mdl");
		SetEntProp(ent, PropType 0, "m_nSolidType", any 6, 4);
		DispatchSpawn(ent);
		TeleportEntity(ent, pos, ang, NULL_VECTOR);
		SetModel = CreateTimer(1, SetModel_Romve, ent, 1);
		CPrintToChatAll("\x01[Sys]：\x04The radio is already loaded");
	}
	if (StrEqual(map, "c3m4_plantation", false))
	{
		SetVector(pos2, 1525, -664, 432);
		SetVector(ang2, 0, 178, 0);
		DropBullet(pos2, ang2);
		SetVector(pos, 2120, -571, 418);
		SetVector(ang, 0, 88, 0);
		DispatchKeyValue(ent, "model", "models/props_urban/fence_gate001_256.mdl");
		SetEntProp(ent, PropType 0, "m_nSolidType", any 6, 4);
		DispatchSpawn(ent);
		TeleportEntity(ent, pos, ang, NULL_VECTOR);
		SetModel = CreateTimer(1, SetModel_Romve, ent, 1);
		CPrintToChatAll("\x01[Sys]：\x04The radio is already loaded");
	}
	if (StrEqual(map, "c4m1_milltown_a", false))
	{
		SetVector(pos2, 3156, -1326, 184);
		SetVector(ang2, 0, 137, 0);
		DropBullet(pos2, ang2);
		SetVector(pos, 3980, -1431, 232);
		SetVector(ang, 0, -90, 0);
		DispatchKeyValue(ent, "model", "models/props_urban/fence_gate001_256.mdl");
		SetEntProp(ent, PropType 0, "m_nSolidType", any 6, 4);
		DispatchSpawn(ent);
		TeleportEntity(ent, pos, ang, NULL_VECTOR);
		SetModel = CreateTimer(1, SetModel_Romve, ent, 1);
		CPrintToChatAll("\x01[Sys]：\x04The radio is already loaded");
	}
	if (StrEqual(map, "c4m2_sugarmill_a", false))
	{
		SetVector(pos2, -1203, -9376, 608);
		SetVector(ang2, 0, 1, 0);
		DropBullet(pos2, ang2);
		SetVector(pos, -1479, -9477, 624);
		SetVector(ang, 0, -91, 0);
		DispatchKeyValue(ent, "model", "models/props_urban/fence_gate001_256.mdl");
		SetEntProp(ent, PropType 0, "m_nSolidType", any 6, 4);
		DispatchSpawn(ent);
		TeleportEntity(ent, pos, ang, NULL_VECTOR);
		SetModel = CreateTimer(1, SetModel_Romve, ent, 1);
		CPrintToChatAll("\x01[Sys]：\x04The radio is already loaded");
	}
	if (StrEqual(map, "c4m3_sugarmill_b", false))
	{
		SetVector(pos2, 3832, -2113, 162);
		SetVector(ang2, 0, -17, 0);
		DropBullet(pos2, ang2);
		SetVector(pos, 3906, -1977, 104);
		SetVector(ang, 0, 88, 0);
		DispatchKeyValue(ent, "model", "models/props_urban/fence_gate001_256.mdl");
		SetEntProp(ent, PropType 0, "m_nSolidType", any 6, 4);
		DispatchSpawn(ent);
		TeleportEntity(ent, pos, ang, NULL_VECTOR);
		SetModel = CreateTimer(1, SetModel_Romve, ent, 1);
		CPrintToChatAll("\x01[Sys]：\x04The radio is already loaded");
	}
	if (StrEqual(map, "c4m4_milltown_b", false))
	{
		SetVector(pos2, -3131, 7443, 158);
		SetVector(ang2, 0, 178, 0);
		DropBullet(pos2, ang2);
		SetVector(pos, -2856, 7899, 120);
		SetVector(ang, 0, -179, 0);
		DispatchKeyValue(ent, "model", "models/props_urban/fence_gate001_256.mdl");
		SetEntProp(ent, PropType 0, "m_nSolidType", any 6, 4);
		DispatchSpawn(ent);
		TeleportEntity(ent, pos, ang, NULL_VECTOR);
		SetModel = CreateTimer(1, SetModel_Romve, ent, 1);
		CPrintToChatAll("\x01[Sys]：\x04The radio is already loaded");
	}
	if (StrEqual(map, "c5m1_waterfront", false))
	{
		SetVector(pos2, 229, 985, -376);
		SetVector(ang2, 0, -92, 0);
		DropBullet(pos2, ang2);
		SetVector(pos, -415, 383, -372);
		SetVector(ang, 0, -178, 0);
		DispatchKeyValue(ent, "model", "models/props_urban/fence_gate001_256.mdl");
		SetEntProp(ent, PropType 0, "m_nSolidType", any 6, 4);
		DispatchSpawn(ent);
		TeleportEntity(ent, pos, ang, NULL_VECTOR);
		SetModel = CreateTimer(1, SetModel_Romve, ent, 1);
		CPrintToChatAll("\x01[Sys]：\x04The radio is already loaded");
	}
	if (StrEqual(map, "c5m2_park", false))
	{
		SetVector(pos2, -8538, -3785, -248);
		SetVector(ang2, 0, 178, 0);
		DropBullet(pos2, ang2);
		SetVector(pos, -8585, -3265, -248);
		SetVector(ang, 0, -179, 0);
		DispatchKeyValue(ent, "model", "models/props_urban/fence_gate001_256.mdl");
		SetEntProp(ent, PropType 0, "m_nSolidType", any 6, 4);
		DispatchSpawn(ent);
		TeleportEntity(ent, pos, ang, NULL_VECTOR);
		SetModel = CreateTimer(1, SetModel_Romve, ent, 1);
		CPrintToChatAll("\x01[Sys]：\x04The radio is already loaded");
	}
	if (StrEqual(map, "c5m3_cemetery", false))
	{
		SetVector(pos2, 4440, 3221, 60);
		SetVector(ang2, 0, 91, 0);
		DropBullet(pos2, ang2);
		SetVector(pos, 3466, 2730, 176);
		SetVector(ang, 0, 180, 0);
		DispatchKeyValue(ent, "model", "models/props_urban/fence_gate001_256.mdl");
		SetEntProp(ent, PropType 0, "m_nSolidType", any 6, 4);
		DispatchSpawn(ent);
		TeleportEntity(ent, pos, ang, NULL_VECTOR);
		SetModel = CreateTimer(1, SetModel_Romve, ent, 1);
		CPrintToChatAll("\x01[Sys]：\x04The radio is already loaded");
	}
	if (StrEqual(map, "c5m4_quarter", false))
	{
		SetVector(pos2, 1236, -2652, 62);
		SetVector(ang2, 0, -127, 0);
		DropBullet(pos2, ang2);
		SetVector(pos, 1450, -2694, 63);
		SetVector(ang, 0, -73, 0);
		DispatchKeyValue(ent, "model", "models/props_urban/fence_gate001_256.mdl");
		SetEntProp(ent, PropType 0, "m_nSolidType", any 6, 4);
		DispatchSpawn(ent);
		TeleportEntity(ent, pos, ang, NULL_VECTOR);
		SetModel = CreateTimer(1, SetModel_Romve, ent, 1);
		CPrintToChatAll("\x01[Sys]：\x04The radio is already loaded");
	}
	if (StrEqual(map, "c6m1_riverbank", false))
	{
		SetVector(pos2, -3852, 1810, 744);
		SetVector(ang2, 0, -180, 0);
		DropBullet(pos2, ang2);
		SetVector(pos, -3881, 1382, 728);
		SetVector(ang, 0, -178, 0);
		DispatchKeyValue(ent, "model", "models/props_urban/fence_gate001_256.mdl");
		SetEntProp(ent, PropType 0, "m_nSolidType", any 6, 4);
		DispatchSpawn(ent);
		TeleportEntity(ent, pos, ang, NULL_VECTOR);
		SetModel = CreateTimer(1, SetModel_Romve, ent, 1);
		CPrintToChatAll("\x01[Sys]：\x04The radio is already loaded");
	}
	if (StrEqual(map, "c6m2_bedlam", false))
	{
		SetVector(pos2, 1242, 5046, 32);
		SetVector(ang2, 0, 93, 0);
		DropBullet(pos2, ang2);
		SetVector(pos, 1405, 4690, -160);
		SetVector(ang, 0, 88, 0);
		DispatchKeyValue(ent, "model", "models/props_urban/fence_gate001_256.mdl");
		SetEntProp(ent, PropType 0, "m_nSolidType", any 6, 4);
		DispatchSpawn(ent);
		TeleportEntity(ent, pos, ang, NULL_VECTOR);
		SetModel = CreateTimer(1, SetModel_Romve, ent, 1);
		CPrintToChatAll("\x01[Sys]：\x04The radio is already loaded");
	}
	if (StrEqual(map, "c6m3_port", false))
	{
		SetVector(pos2, -750, -744, 320);
		SetVector(ang2, 0, 5, 0);
		DropBullet(pos2, ang2);
		SetVector(pos, -837, -582, 320);
		SetVector(ang, 0, 0, 0);
		DispatchKeyValue(ent, "model", "models/props_urban/fence_gate001_256.mdl");
		SetEntProp(ent, PropType 0, "m_nSolidType", any 6, 4);
		DispatchSpawn(ent);
		TeleportEntity(ent, pos, ang, NULL_VECTOR);
		SetModel = CreateTimer(1, SetModel_Romve, ent, 1);
		CPrintToChatAll("\x01[Sys]：\x04The radio is already loaded");
	}
	if (StrEqual(map, "c7m1_docks", false))
	{
		SetVector(pos2, 8883, 943, 52);
		SetVector(ang2, 0, -180, 0);
		DropBullet(pos2, ang2);
		SetVector(pos, 7028, 636, 169);
		SetVector(ang, 0, 150, 0);
		DispatchKeyValue(ent, "model", "models/props_urban/fence_gate001_256.mdl");
		SetEntProp(ent, PropType 0, "m_nSolidType", any 6, 4);
		DispatchSpawn(ent);
		TeleportEntity(ent, pos, ang, NULL_VECTOR);
		SetModel = CreateTimer(1, SetModel_Romve, ent, 1);
		CPrintToChatAll("\x01[Sys]：\x04The radio is already loaded");
	}
	if (StrEqual(map, "c7m2_barge", false))
	{
		SetVector(pos2, -2856, 732, 229);
		SetVector(ang2, 0, -180, 0);
		DropBullet(pos2, ang2);
		SetVector(pos, -5450, 625, 622);
		SetVector(ang, 0, -70, 0);
		DispatchKeyValue(ent, "model", "models/props_urban/fence_gate001_256.mdl");
		SetEntProp(ent, PropType 0, "m_nSolidType", any 6, 4);
		DispatchSpawn(ent);
		TeleportEntity(ent, pos, ang, NULL_VECTOR);
		SetModel = CreateTimer(1, SetModel_Romve, ent, 1);
		CPrintToChatAll("\x01[Sys]：\x04The radio is already loaded");
	}
	return Action 0;
}

public Action SetModel_Romve(Handle timer, any ent)
{
	if (IsModel)
	{
		RemoveEdict(ent);
		KillTimer(timer, false);
		SetModel = 0;
	}
	return Action 0;
}

int DropBullet(float pos[3], float ang[3])
{
	int ent = CreateEntityByName("prop_dynamic", -1);
	if (ent != -1)
	{
		DispatchKeyValueFloat(ent, "fademindist", 10000);
		DispatchKeyValueFloat(ent, "fademaxdist", 20000);
		DispatchKeyValueFloat(ent, "fadescale", 0);
		DispatchKeyValue(ent, "model", "models/props_interiors/makeshift_stove_battery.mdl");
		SetEntProp(ent, PropType 0, "m_nSolidType", any 6, 4);
		DispatchSpawn(ent);
		SetEntProp(ent, PropType 0, "m_CollisionGroup", any 1, 4);
		int glowcolor = RGB_TO_INT(80, 80, 225);
		SetEntProp(ent, PropType 0, "m_iGlowType", any 3, 4);
		SetEntProp(ent, PropType 0, "m_nGlowRange", any 0, 4);
		SetEntProp(ent, PropType 0, "m_glowColorOverride", glowcolor, 4);
		TeleportEntity(ent, pos, ang, NULL_VECTOR);
		int button = CreateButton(ent);
		SetEntPropFloat(button, PropType 0, "m_fadeMaxDist", 1065353216 * ent);
		SetJiGuan = CreateTimer(1, Timer_JiGuanGM, ent, 3);
	}
	return 0;
}

public Action Timer_JiGuanGM(Handle timer, any ent)
{
	if (IsValidEntity(ent))
	{
		if (IsModel)
		{
			KillTimer(timer, false);
			SetJiGuan = 0;
		}
		int player = 0;
		float myPos[3];
		float hePos[3];
		float hePos1[3];
		GetEntPropVector(ent, PropType 0, "m_vecOrigin", myPos);
		int i = 1;
		while (i <= MaxClients)
		{
			if (IsValidPlayer(i, true, true))
			{
				GetEntPropVector(i, PropType 0, "m_vecOrigin", hePos);
				if (GetVectorDistance(myPos, hePos, false) < 1140457472)
				{
					SetGM(i, "Please turn on the radio and wait for the rescue to eliminate the barbed wire");
					i++;
				}
				i++;
			}
			i++;
		}
		int i = 1;
		while (i <= MaxClients)
		{
			if (IsValidPlayer(i, true, true))
			{
				int var1;
				if (GetClientTeam(i) == 2)
				{
					GetEntPropVector(i, PropType 0, "m_vecOrigin", hePos1);
					if (GetVectorDistance(myPos, hePos1, false) < 1140457472)
					{
						player++;
						i++;
					}
					i++;
				}
				i++;
			}
			i++;
		}
		IsPlayerLimit = player;
	}
	else
	{
		KillTimer(timer, false);
		SetJiGuan = 0;
	}
	return Action 0;
}

int CreateButton(int entity)
{
	char sTemp[16];
	int button = 0;
	bool type = 0;
	if (type)
	{
		button = CreateEntityByName("func_button", -1);
	}
	else
	{
		button = CreateEntityByName("func_button_timed", -1);
	}
	Format(sTemp, 16, "target%d", button);
	DispatchKeyValue(entity, "targetname", sTemp);
	DispatchKeyValue(button, "glow", sTemp);
	DispatchKeyValue(button, "rendermode", "3");
	if (type)
	{
		DispatchKeyValue(button, "spawnflags", "1025");
		DispatchKeyValue(button, "wait", "5");
	}
	else
	{
		DispatchKeyValue(button, "spawnflags", "0");
		DispatchKeyValue(button, "auto_disable", "1");
		Format(sTemp, 16, "%f", 1084227584);
		DispatchKeyValue(button, "use_time", sTemp);
	}
	DispatchSpawn(button);
	AcceptEntityInput(button, "Enable", -1, -1, 0);
	ActivateEntity(button);
	Format(sTemp, 16, "ft%d", button);
	DispatchKeyValue(entity, "targetname", sTemp);
	SetVariantString(sTemp);
	AcceptEntityInput(button, "SetParent", button, button, 0);
	TeleportEntity(button, 4592, NULL_VECTOR, NULL_VECTOR);
	SetEntProp(button, PropType 0, "m_nSolidType", any 0, 1);
	SetEntProp(button, PropType 0, "m_usSolidFlags", any 4, 2);
	float vMins[3];
	float vMaxs[3];
	SetEntPropVector(button, PropType 0, "m_vecMins", vMins);
	SetEntPropVector(button, PropType 0, "m_vecMaxs", vMaxs);
	SetEntProp(button, PropType 1, "m_CollisionGroup", any 1, 4);
	SetEntProp(button, PropType 0, "m_CollisionGroup", any 1, 4);
	if (type)
	{
		HookSingleEntityOutput(button, "OnPressed", EntityOutput 15, false);
	}
	else
	{
		SetVariantString("OnTimeUp !self:Enable::1:-1");
		AcceptEntityInput(button, "AddOutput", -1, -1, 0);
		HookSingleEntityOutput(button, "OnTimeUp", EntityOutput 15, false);
	}
	return button;
}

public int OnPressed(char output[], int caller, int activator, float delay)
{
	float f = GetEntPropFloat(caller, PropType 0, "m_fadeMaxDist");
	int ent = RoundFloat(f);
	f = GetEntPropFloat(ent, PropType 0, "m_fadeMaxDist");
	int var1;
	if (activator > 0)
	{
		int connectnum = GetAllPlayerCount();
		if (IsPlayerLimit >= connectnum)
		{
			SetConVarInt(FindConVar("director_panic_forever"), 1, false, false);
			RemoveEdict(ent);
			SetMusic();
			SpawModel();
			SetGM(activator, "The institution has been opened, protect yourself, and must survive to the end.");
			SetTimer = CreateTimer(1, StartTimer, any 0, 1);
		}
		else
		{
			SetGM(activator, "Wait for other players to get together to open the agency");
		}
	}
	return 0;
}

public Action StartTimer(Handle timer, any data)
{
	waittime += 1;
	int connectnum = GetAllPlayerCount();
	int players = 0;
	if (connectnum <= 4)
	{
		players = 120;
	}
	else
	{
		int var1;
		if (connectnum <= 8)
		{
			players = 180;
		}
		if (connectnum > 8)
		{
			players = 300;
		}
	}
	PrintHintTextToAll("The security net is still destroyed by %d seconds. Please stick to it.", players - waittime);
	int var2;
	if (waittime == 30)
	{
		int Client = 0;
		int i = 1;
		while (i <= MaxClients)
		{
			if (IsValidPlayer(i, true, true))
			{
				int var3;
				if (!IsFakeClient(i))
				{
					Client = i;
					i++;
				}
				i++;
			}
			i++;
		}
		CheatCommand(Client, "z_spawn", "tank");
		TriggerPanicEvent();
	}
	if (waittime >= players)
	{
		IsModel = 1;
		waittime = 0;
		KillTimer(timer, false);
		SetTimer = 0;
		SetConVarInt(FindConVar("director_panic_forever"), 0, false, false);
		PrintHintTextToAll("The security net has been broken, everyone rushed out together.");
		int i = 1;
		while (i <= MaxClients)
		{
			if (IsValidPlayer(i, true, true))
			{
				SetGM(i, "The security net has been broken, everyone is fast moving into the safe house.");
				i++;
			}
			i++;
		}
	}
	return Action 0;
}

int SetMusic()
{
	int i = 1;
	while (i <= MaxClients)
	{
		if (IsValidPlayer(i, true, true))
		{
			EmitSoundToAll("music/flu/jukebox/all_i_want_for_xmas.wav", i, 0, 75, 0, 1, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0);
			i++;
		}
		i++;
	}
	return 0;
}

int SpawModel()
{
	int ent1 = CreateEntityByName("prop_dynamic", -1);
	DispatchKeyValue(ent1, "model", "models/props_interiors/makeshift_stove_battery.mdl");
	SetEntProp(ent1, PropType 0, "m_nSolidType", any 6, 4);
	DispatchSpawn(ent1);
	TeleportEntity(ent1, pos2, ang2, NULL_VECTOR);
	return 0;
}

public int TriggerPanicEvent()
{
	int flager = GetAnyClient();
	if (flager == -1)
	{
		return 0;
	}
	int flag = GetCommandFlags("director_force_panic_event");
	SetCommandFlags("director_force_panic_event", flag & -16385);
	FakeClientCommand(flager, "director_force_panic_event");
	return 0;
}

public int GetAnyClient()
{
	int i = 1;
	while (i <= MaxClients)
	{
		int var1;
		if (IsValidEntity(i))
		{
			return i;
		}
		i++;
	}
	return -1;
}

bool IsValidPlayer(int Client, bool AllowBot, bool AllowDeath)
{
	int var1;
	if (Client < 1)
	{
		return false;
	}
	int var2;
	if (!IsClientConnected(Client))
	{
		return false;
	}
	if (!AllowBot)
	{
		if (IsFakeClient(Client))
		{
			return false;
		}
	}
	if (!AllowDeath)
	{
		if (!IsPlayerAlive(Client))
		{
			return false;
		}
	}
	return true;
}

public int SetGM(int client, char sBuffer[256])
{
	Handle h_RemovePack;
	char sTemp[32];
	int entity = CreateEntityByName("env_instructor_hint", -1);
	FormatEx(sTemp, 32, "hint%d", client);
	ReplaceString(sBuffer, 256, "\n", " ", true);
	DispatchKeyValue(client, "targetname", sTemp);
	DispatchKeyValue(entity, "hint_target", sTemp);
	DispatchKeyValue(entity, "hint_timeout", "1");
	DispatchKeyValue(entity, "hint_range", "0.01");
	DispatchKeyValue(entity, "hint_color", "255, 255, 255");
	DispatchKeyValue(entity, "hint_caption", sBuffer);
	DispatchSpawn(entity);
	AcceptEntityInput(entity, "ShowHint", -1, -1, 0);
	h_RemovePack = CreateDataPack();
	WritePackCell(h_RemovePack, client);
	WritePackCell(h_RemovePack, entity);
	CreateTimer(1, RemoveInstructorHint, h_RemovePack, 0);
	return 0;
}

public Action RemoveInstructorHint(Handle h_Timer, Handle h_Pack)
{
	int i_Ent;
	ResetPack(h_Pack, false);
	i_Ent = ReadPackCell(h_Pack);
	CloseHandle(h_Pack);
	if (IsValidEntity(i_Ent))
	{
		RemoveEdict(i_Ent);
	}
	return Action 0;
}

public int GetAllPlayerCount()
{
	int count = 0;
	int i = 1;
	while (i <= MaxClients)
	{
		int var1;
		if (IsValidPlayer(i, true, true))
		{
			count++;
			i++;
		}
		i++;
	}
	return count;
}

int CheatCommand(int Client, char command[], char arguments[])
{
	if (!Client)
	{
		return 0;
	}
	int admindata = GetUserFlagBits(Client);
	SetUserFlagBits(Client, 16384);
	int flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & -16385);
	FakeClientCommand(Client, "%s %s", command, arguments);
	SetCommandFlags(command, flags);
	SetUserFlagBits(Client, admindata);
	return 0;
}

int RGB_TO_INT(int red, int green, int blue)
{
	return green * 256 + blue * 65536 + red;
}

int SetVector(float target[3], float x, float y, float z)
{
	target[0] = x;
	target[4] = y;
	target[8] = z;
	return 0;
}

