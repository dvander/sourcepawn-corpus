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
 Handle hBasicTankHP;
 Handle hAddTankHP;
 int TankBasicHP;
 int TankAddHP;
 Handle hTankHPSH;
 int TankHPSH;
public Plugin myinfo =
{
	name = "L4D2 Tank hp ",
	description = "L4D2 Tank hp ",
	author = "Ryanx",
	version = "L4D2 tank life automatically set by the number of players",
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

public float operator*(Float:,_:)(float oper1, int oper2)
{
	return FloatMul(oper1, float(oper2));
}

public bool StrEqual(char str1[], char str2[], bool caseSensitive)
{
	return strcmp(str1, str2, caseSensitive) == 0;
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
	CreateConVar("L4D2_TANK_HP_version", "L4D2 tank health settings", "Note: The following values are added to the normal difficulty of the Tank blood volume, the experts should be *2 again", 8512, false, 0, false, 0);
	hBasicTankHP = CreateConVar("l4d2_basic_hp", "4000", "Tank basic health (<=4 players)", 0, true, 1, true, 100000);
	hAddTankHP = CreateConVar("l4d2_add_hp", "1000", ">For 4 players, each additional player Tank increases the health (example: Normal: 7 is 7-4=3*1k+4k=7k; Expert: Value is *2 7k*2=1.4w)", 0, true, 1, true, 100000);
	hTankHPSH = CreateConVar("l4d2_show_hp", "2", "Tips Tank Health [0 pass, 1 player starts, 2 players join, 3=1+2]", 0, true, 0, true, 3);
	TankBasicHP = GetConVarInt(hBasicTankHP);
	TankAddHP = GetConVarInt(hAddTankHP);
	TankHPSH = GetConVarInt(hTankHPSH);
	HookEvent("player_activate", EventHook 7, EventHookMode 1);
	HookEvent("player_disconnect", EventHook 9, EventHookMode 1);
	HookEvent("round_start", EventHook 11, EventHookMode 2);
	AutoExecConfig(true, "l4d2_tank_hp", "sourcemod");
	return void 0;
}

public void OnMapStart()
{
	TankBasicHP = GetConVarInt(hBasicTankHP);
	TankAddHP = GetConVarInt(hAddTankHP);
	TankHPSH = GetConVarInt(hTankHPSH);
	return void 0;
}

public int Event_TKHPRoundStart(Handle event, char name[], bool dontBroadcast)
{
	int var1;
	if (TankHPSH == 1)
	{
		CreateTimer(5, TankhpshowDelays, any 0, 0);
	}
	return 0;
}

public Action TankhpshowDelays(Handle timer)
{
	char GameDIFF[32];
	TankBasicHP = GetConVarInt(hBasicTankHP);
	TankAddHP = GetConVarInt(hAddTankHP);
	int SetTankHP = 0;
	int DisTankHP = 0;
	int numPlayers = 0;
	int i = 1;
	while (i <= MaxClients)
	{
		int var1;
		if (IsClientInGame(i))
		{
			numPlayers++;
			i++;
		}
		i++;
	}
	if (numPlayers <= 4)
	{
		numPlayers = 4;
	}
	SetTankHP = TankAddHP * numPlayers + -4 + TankBasicHP;
	SetConVarInt(FindConVar("z_tank_health"), SetTankHP, false, false);
	GetConVarString(FindConVar("z_difficulty"), GameDIFF, 32);
	if (StrEqual(GameDIFF, "Easy", true))
	{
		DisTankHP = RoundToCeil(1061158912 * SetTankHP);
	}
	else
	{
		if (StrEqual(GameDIFF, "Normal", true))
		{
			DisTankHP = SetTankHP;
		}
		DisTankHP = SetTankHP * 2;
	}
	PrintToChatAll("\x04[!Tips!]\x05 The number of survivors changed,\x03 %s \x05Difficulty, Tank health is now\x03 %d", GameDIFF, DisTankHP);
	return Action 0;
}

public Action Event_PlayerAct(Handle event, char name[], bool dontBroadcast)
{
	int checkhplayer = GetClientOfUserId(GetEventInt(event, "userid", 0));
	if (!IsFakeClient(checkhplayer))
	{
		CreateTimer(0.1, TankHPsetStartDelays, any 0, 0);
	}
	return Action 0;
}

public Action Event_RPlayerDisct(Handle event, char name[], bool dontBroadcast)
{
	int checkhplayer = GetClientOfUserId(GetEventInt(event, "userid", 0));
	int var1;
	if (checkhplayer)
	{
		CreateTimer(3, TankHPsetStartDelays, any 0, 0);
	}
	return Action 0;
}

public Action TankHPsetStartDelays(Handle timer)
{
	char GameDIFF[32];
	TankBasicHP = GetConVarInt(hBasicTankHP);
	TankAddHP = GetConVarInt(hAddTankHP);
	int SetTankHP = 0;
	int DisTankHP = 0;
	int numPlayers = 0;
	int i = 1;
	while (i <= MaxClients)
	{
		int var1;
		if (IsClientInGame(i))
		{
			numPlayers++;
			i++;
		}
		i++;
	}
	if (numPlayers <= 4)
	{
		numPlayers = 4;
	}
	SetTankHP = TankAddHP * numPlayers + -4 + TankBasicHP;
	SetConVarInt(FindConVar("z_tank_health"), SetTankHP, false, false);
	GetConVarString(FindConVar("z_difficulty"), GameDIFF, 32);
	if (StrEqual(GameDIFF, "Easy", true))
	{
		DisTankHP = RoundToCeil(1061158912 * SetTankHP);
	}
	else
	{
		if (StrEqual(GameDIFF, "Normal", true))
		{
			DisTankHP = SetTankHP;
		}
		DisTankHP = SetTankHP * 2;
	}
	if (TankHPSH > 1)
	{
		PrintToChatAll("\x04[!Tips!]\x05 The number of survivors changed,\x03 %s \x05Difficulty, Tank health is now\x03 %d", GameDIFF, DisTankHP);
	}
	return Action 0;
}

