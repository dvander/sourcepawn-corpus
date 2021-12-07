
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#pragma newdecls required

Handle R_Def_Maps;
Handle hRACMKvS;
char RACMKvS[128];
Handle hR_ACMHint;
bool R_ACMHint;
Handle hR_ACMDelay;
float R_ACMDelay;
char R_Next_Maps[64];
char R_Next_Name[64];

public Plugin myinfo =
{
	name = "L4D2自动换图11.0-by望夜",
	description = "L4D2 auto change Maps",
	author = "Ryanx",
	version = "L4D2自动换图1.0-by望夜",
	url = ""
};

public void OnPluginStart()
{
	CreateConVar("R_ACM_Version", "L4D2自动换图1.0-by望夜", "L4D2自动换图1.0-by望夜", 8512, false, 0.0, false, 0.0);
	R_Def_Maps = CreateConVar("R_ACM_Def_Map", "c2m1_highway", "不在列表时默认换的地图.", 0, false, 0.0, false, 0.0);
	hR_ACMHint = CreateConVar("R_ACM_Hint", "1", "自动换图时是否公告[0=关|1=开]", 0, true, 0.0, true, 1.0);
	R_ACMHint = GetConVarBool(hR_ACMHint);
	hR_ACMDelay = CreateConVar("R_ACM_delay", "30.0", "自动换图延时几秒(PS:太长游戏就退到主菜单了).", 0, true, 5.0, true, 300.0);
	R_ACMDelay = GetConVarFloat(hR_ACMDelay);
	HookEvent("finale_win", RACMEvent_FinaleWin);
	HookEvent("player_activate", RACMEvent_activate);
	hRACMKvS = CreateKeyValues("R_Auto_Change_Maps", "", "");
	AutoExecConfig(true, "R_AC_MAPS", "sourcemod");
}

public void OnMapStart()
{
	R_ACMHint = GetConVarBool(hR_ACMHint);
	R_ACMDelay = GetConVarFloat(hR_ACMDelay);
}

public Action RACMEvent_activate(Handle event, char[] name, bool dontBroadcast)
{
	if (R_ACMHint)
	{
		int Client = GetClientOfUserId(GetEventInt(event, "userid", 0));
		if (Client && !IsFakeClient(Client))
		{
			RACMLoad();
			if (strcmp(R_Next_Maps, "none", true))
			{
				CreateTimer(5.0, RACSHints, Client, 0);
			}
		}
	}
}

public Action RACSHints(Handle timer, any client)
{
	PrintToChat(client, "\x04[ACM]\x03 已是最后一个章节");
	PrintToChat(client, "\x04[ACM]\x03 下个战役: \x04%s", R_Next_Name);
	return Plugin_Continue;
}

public Action RACMEvent_FinaleWin(Handle event, char[] name, bool dontBroadcast)
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
	CreateTimer(R_ACMDelay - 3.0, RACMaps);
	return Plugin_Continue;
}

void CACMKV(Handle kvhandle)
{
	KvRewind(kvhandle);
	if (KvGotoFirstSubKey(kvhandle, true))
	{
		do {
			KvDeleteThis(kvhandle);
			KvRewind(kvhandle);
		} while (KvGotoFirstSubKey(kvhandle, true));
		KvRewind(kvhandle);
	}
}

public Action RACMaps(Handle timer)
{
	if (R_ACMHint)
	{
		PrintToChatAll("\x04[ACM]\x03 下个战役: \x04%s", R_Next_Name);
		PrintToChatAll("\x01%s", R_Next_Maps);
	}
	CreateTimer(3.0, RACMapsN);
	return Plugin_Continue;
}

public Action RACMapsN(Handle timer)
{
	ServerCommand("changelevel %s", R_Next_Maps);
	return Plugin_Continue;
}

void RACMLoad()
{
	CACMKV(hRACMKvS);
	BuildPath(Path_SM, RACMKvS, 128, "data/R_AC_MAPS.txt");
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
}

