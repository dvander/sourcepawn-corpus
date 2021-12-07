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
 Extension __ext_sdktools = 2224;
 Handle R_Def_Maps;
 Handle hRACMKvS;
 char RACMKvS[32];
 Handle hR_ACMHint;
 bool R_ACMHint;
 Handle hR_ACMDelay;
 float R_ACMDelay;
 char R_Next_Maps[16];
 char R_Next_Name[16];
public Plugin myinfo =
{
	name = "L4D2自动换图",
	description = "L4D2 auto change Maps",
	author = "Ryanx",
	version = "L4D2自动换图",
	url = ""
};
public void __ext_core_SetNTVOptional()
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
	return void 0;
}

public void PrintToChatAll(char format[])
{
	char buffer[256];
	int i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			SetGlobalTransTarget(i);
			VFormat(buffer, 254, format, 2);
			PrintToChat(i, "%s", buffer);
			i++;
		}
		i++;
	}
	return void 0;
}

public void OnPluginStart()
{
	CreateConVar("R_ACM_Version", "L4D2自动换图", "L4D2自动换图", 8512, false, 0, false, 0);
	R_Def_Maps = CreateConVar("R_ACM_Def_Map", "c2m1_highway", "不在列表时默认换的地图.", 0, false, 0, false, 0);
	hR_ACMHint = CreateConVar("R_ACM_Hint", "1", "自动换图时是否公告[0=关|1=开]", 0, true, 0, true, 1);
	R_ACMHint = GetConVarBool(hR_ACMHint);
	hR_ACMDelay = CreateConVar("R_ACM_delay", "5.0", "自动换图延时几秒(PS:太长游戏就退到主菜单了).", 0, true, 5, true, 300);
	R_ACMDelay = GetConVarFloat(hR_ACMDelay);
	HookEvent("finale_win", EventHook 11, EventHookMode 2);
	HookEvent("player_activate", EventHook 13, EventHookMode 1);
	hRACMKvS = CreateKeyValues("R_Auto_Change_Maps", "", "");
	AutoExecConfig(true, "R_AC_MAPS", "sourcemod");
	return void 0;
}

public void OnMapStart()
{
	R_ACMHint = GetConVarBool(hR_ACMHint);
	R_ACMDelay = GetConVarFloat(hR_ACMDelay);
	return void 0;
}

public int RACMEvent_activate(Handle event, char name[], bool dontBroadcast)
{
	if (R_ACMHint)
	{
		int Client = GetClientOfUserId(GetEventInt(event, "userid", 0));
		int var1;
		if (Client)
		{
			RACMLoad();
			if (strcmp(R_Next_Maps, "none", true))
			{
				CreateTimer(5, RACSHints, Client, 0);
			}
		}
	}
	return 0;
}

public Action RACSHints(Handle timer, any client)
{
	PrintToChat(client, "\x04[ACM]\x03 已是最后一个章节");
	PrintToChat(client, "\x04[ACM]\x03 下个战役: \x04%s", R_Next_Name);
	return Action 0;
}

public Action RACMEvent_FinaleWin(Handle event, char name[], bool dontBroadcast)
{
	RACMLoad();
	if (!strcmp(R_Next_Maps, "none", true))
	{
		GetConVarString(R_Def_Maps, R_Next_Maps, 64);
		GetConVarString(R_Def_Maps, R_Next_Name, 64);
	}
	if (R_ACMHint)
	{
		char ACMHdelayS[12];
		FloatToString(R_ACMDelay, ACMHdelayS, 12);
		int ACMHdelayT = StringToInt(ACMHdelayS, 10);
		PrintToChatAll("\x04[ACM]\x03 已完成本战役");
		PrintToChatAll("\x04[ACM]\x03 %d秒后将自动换图", ACMHdelayT);
	}
	CreateTimer(FloatSub(R_ACMDelay, 3), RACMaps, any 0, 0);
	return Action 0;
}

public int CACMKV(Handle kvhandle)
{
	KvRewind(kvhandle);
	if (KvGotoFirstSubKey(kvhandle, true))
	{
		do
{
			KvDeleteThis(kvhandle);
			KvRewind(kvhandle);
		}
		while (KvGotoFirstSubKey(kvhandle, true));
		KvRewind(kvhandle);
	}
	return 0;
}

public Action RACMaps(Handle timer)
{
	if (R_ACMHint)
	{
		PrintToChatAll("\x04[ACM]\x03 下个战役: \x04%s", 2484);
		PrintToChatAll("\x01%s", 2420);
	}
	CreateTimer(3, RACMapsN, any 0, 0);
	return Action 0;
}

public Action RACMapsN(Handle timer)
{
	ServerCommand("changelevel %s", R_Next_Maps);
	return Action 0;
}

public int RACMLoad()
{
	CACMKV(hRACMKvS);
	BuildPath(PathType 0, RACMKvS, 128, "data/R_AC_MAPS.txt");
	if (!FileToKeyValues(hRACMKvS, RACMKvS))
	{
		PrintToChatAll("\x04[!出错!]\x01 无法读取data/R_AC_MAPS.txt");
	}
	char nrcurrent_map[64];
	GetCurrentMap(nrcurrent_map, 64);
	KvRewind(hRACMKvS);
	if (KvJumpToKey(hRACMKvS, nrcurrent_map, false))
	{
		KvGetString(hRACMKvS, "R_ACM_Next_Maps", R_Next_Maps, 64, "none");
		KvGetString(hRACMKvS, "R_ACM_Next_Name", R_Next_Name, 64, "none");
	}
	KvRewind(hRACMKvS);
	return 0;
}

