#include <sourcemod>
#include <hattrick_csgo>
#include <GeoResolver>

native Handle GetMainDbHandle();

public Plugin myinfo =
{
	name = "sodstats",
	author = "Hattrick (HKS)",
	description = "New Statistics",
	version = "3.0",
	url = "http://hattrick.go.ro/"
};

Handle g_pDb = INVALID_HANDLE;
char g_Qry[PLATFORM_MAX_PATH * 8];
int g_Id[PLATFORM_MAX_PATH] = { -1, ... };
int g_Total = 0;
int g_Kills[PLATFORM_MAX_PATH] = { 0, ... };
int g_Deaths[PLATFORM_MAX_PATH] = { 0, ... };
int g_Time[PLATFORM_MAX_PATH] = { 0, ... };
bool g_bEnableVChatInfo = false;
bool g_bEnableKChatInfo = false;
int g_lastVictim[MAXPLAYERS + 1] = { INVALID_ENT_REFERENCE, ... };

public APLRes AskPluginLoad2(Handle pMyself, bool bLate, char[] Error, int maxLen)
{
	CreateNative("GetMinsOfPlr", __GetMinsOfPlr);

	RegPluginLibrary("sodstats");

	return APLRes_Success;
}

public int __GetMinsOfPlr(Handle pPlugin, int Params)
{
	return g_Time[GetNativeCell(1)];
}

public void OnCnx(Handle pOwner, Handle pChild, const char[] Error, any Data)
{
	g_pDb = pChild;

	if (strlen(Error) == 0)
	{
		SQL_SetCharset(g_pDb, "utf8");
	}
}

public void OnClientPutInServer(int Id)
{
	g_Id[Id] = -1;
	g_Time[Id] = 0;
	
	g_lastVictim[Id] = INVALID_ENT_REFERENCE;
	
	CreateTimer(1.0, timerCreate, Id, TIMER_FLAG_NO_MAPCHANGE);
}

public void OnMapStart()
{
	g_bEnableVChatInfo = hCSGO_GetOptFromFileInt("configs/hattrick.core.txt", \
													"m_bEnableVictimChatInfo") ? true : false;
	g_bEnableKChatInfo = hCSGO_GetOptFromFileInt("configs/hattrick.core.txt", \
													"m_bEnableKillerChatInfo") ? true : false;
}

bool CanUseChatCommands()
{
	static char szBuffer[PLATFORM_MAX_PATH] = "";

	BuildPath(Path_SM, szBuffer, sizeof(szBuffer), "plugins/hlstats.smx");
	if (FileExists(szBuffer))
		return false;

	BuildPath(Path_SM, szBuffer, sizeof(szBuffer), "plugins/hlstatsx.smx");
	if (FileExists(szBuffer))
		return false;

	BuildPath(Path_SM, szBuffer, sizeof(szBuffer), "plugins/hlstatsce.smx");
	if (FileExists(szBuffer))
		return false;

	BuildPath(Path_SM, szBuffer, sizeof(szBuffer), "plugins/hlstatsxce.smx");
	if (FileExists(szBuffer))
		return false;

	BuildPath(Path_SM, szBuffer, sizeof(szBuffer), "plugins/ckSurf.smx");
	if (FileExists(szBuffer))
		return false;

	BuildPath(Path_SM, szBuffer, sizeof(szBuffer), "plugins/cksurf.smx");
	if (FileExists(szBuffer))
		return false;

	return true;
}

public Action CommandSay(int Client, int Args)
{
	static char Raw[PLATFORM_MAX_PATH], Command[PLATFORM_MAX_PATH];

	if (Client > 0 && IsClientInGame(Client))
	{
		GetCmdArgString(Raw, sizeof(Raw));

		if (hCSGO_PureChatCommand(Raw, Command, sizeof(Command)) >= 3)
		{
			if (!strcmp(Command, "Rank", false) || !strcmp(Command[1], "Rank", false) || \
				!strcmp(Command, "Rang", false) || !strcmp(Command[1], "Rang", false))
			{
				if (CanUseChatCommands() && g_pDb != INVALID_HANDLE && g_Id[Client] != -1)
				{
					FormatEx(g_Qry, sizeof(g_Qry), "select kills from ss_players;");
					SQL_TQuery(g_pDb, __readtotal, g_Qry);
					FormatEx(g_Qry, sizeof(g_Qry), "select kills, deaths from ss_players where id = %d;", g_Id[Client]);
					SQL_TQuery(g_pDb, __rootrank, g_Qry, Client);
				}
			}

			else if (!strcmp(Command, "Top", false) || !strcmp(Command[1], "Top", false) || \
					!strcmp(Command, "Top10", false) || !strcmp(Command[1], "Top10", false) || \
					!strcmp(Command, "Top15", false) || !strcmp(Command[1], "Top15", false))
			{
				if (CanUseChatCommands())
				{
					FormatEx(g_Qry, sizeof(g_Qry), "select name, kills, deaths from ss_players order by kills desc;");
					SQL_TQuery(g_pDb, __printtop, g_Qry, Client);
				}
			}
		}
	}
}

public void __readtotal(Handle pDb, Handle pQuery, char[] Error, any Data)
{
	if (g_pDb != INVALID_HANDLE && \
			pQuery != INVALID_HANDLE && \
				pDb != INVALID_HANDLE && \
					SQL_HasResultSet(pQuery) && \
						(g_Total = SQL_GetRowCount(pQuery)) > 0)
	{

	}
}

public void __printtop(Handle pDb, Handle pQuery, char[] Error, any Data)
{
	static Handle pMenu = INVALID_HANDLE;
	static char name[PLATFORM_MAX_PATH];
	static char id_s[PLATFORM_MAX_PATH];
	static int k, d, Iter;
	static float kpd = 0.0;

	if (IsClientInGame(Data) && \
			g_pDb != INVALID_HANDLE && \
				pQuery != INVALID_HANDLE && \
					pDb != INVALID_HANDLE && \
						SQL_HasResultSet(pQuery) && \
							SQL_GetRowCount(pQuery) > 0)
	{
		Iter = 0;

		pMenu = CreateMenu(Handler);
		if (pMenu != INVALID_HANDLE)
		{
			SetMenuTitle(pMenu, "★ BEST PLAYERS ★");

			while (SQL_FetchRow(pQuery))
			{
				SQL_FetchString(pQuery, 0, name, sizeof(name));
				k = SQL_FetchInt(pQuery, 1);
				d = SQL_FetchInt(pQuery, 2);
				
				hCSGO_AddCommas(++Iter, id_s, sizeof(id_s));
				
				if (d == 0)
					kpd = float(k);
				else
					kpd = float(k) / float(d);
				
				FormatEx(g_Qry, sizeof(g_Qry), "%s — %s — %.2f K/D", id_s, name, kpd);
				AddMenuItem(pMenu, "", g_Qry);
			}
			DisplayMenu(pMenu, Data, MENU_TIME_FOREVER);
		}
	}
}

public int Handler(Handle pMenu, MenuAction pAction, int plrid, int opt)
{
	if (pAction == MenuAction_End)
		CloseHandle(pMenu);
}

public void __rootrank(Handle pDb, Handle pQuery, char[] Error, any Data)
{
	if (IsClientInGame(Data) && \
			g_pDb != INVALID_HANDLE && \
				pQuery != INVALID_HANDLE && \
					pDb != INVALID_HANDLE && \
						SQL_HasResultSet(pQuery) && \
							SQL_GetRowCount(pQuery) > 0 && \
								SQL_FetchRow(pQuery))
	{
		g_Kills[Data] = SQL_FetchInt(pQuery, 0);
		g_Deaths[Data] = SQL_FetchInt(pQuery, 1);
		
		FormatEx(g_Qry, sizeof(g_Qry), "select distinct kills from ss_players where kills >= %d order by kills asc;", g_Kills[Data]);
		SQL_TQuery(g_pDb, __printrank, g_Qry, Data);
	}
}

public void __rootrankpriv(Handle pDb, Handle pQuery, char[] Error, any Data)
{
	if (IsClientInGame(Data) && \
			g_pDb != INVALID_HANDLE && \
				pQuery != INVALID_HANDLE && \
					pDb != INVALID_HANDLE && \
						SQL_HasResultSet(pQuery) && \
							SQL_GetRowCount(pQuery) > 0 && \
								SQL_FetchRow(pQuery))
	{
		g_Kills[Data] = SQL_FetchInt(pQuery, 0);
		g_Deaths[Data] = SQL_FetchInt(pQuery, 1);
		
		FormatEx(g_Qry, sizeof(g_Qry), "select distinct kills from ss_players where kills >= %d order by kills asc;", g_Kills[Data]);
		SQL_TQuery(g_pDb, __printrankpriv, g_Qry, Data);
	}
}

public void __printrank(Handle pDb, Handle pQuery, char[] Error, any Data)
{
	static int r = 0;
	static char r_s[PLATFORM_MAX_PATH];
	static char t_s[PLATFORM_MAX_PATH];
	static char k_s[PLATFORM_MAX_PATH];
	static char d_s[PLATFORM_MAX_PATH];
	
	if (g_Total > 0 && \
			IsClientInGame(Data) && \
				g_pDb != INVALID_HANDLE && \
					pQuery != INVALID_HANDLE && \
						pDb != INVALID_HANDLE && \
							SQL_HasResultSet(pQuery) && \
								(r = SQL_GetRowCount(pQuery)) > 0)
	{
		hCSGO_AddCommas(r, r_s, sizeof(r_s));
		hCSGO_AddCommas(g_Kills[Data], k_s, sizeof(k_s));
		hCSGO_AddCommas(g_Deaths[Data], d_s, sizeof(d_s));
		hCSGO_AddCommas(g_Total, t_s, sizeof(t_s));

		PrintToChatAll("\x01*\x04 %N\x01's rank is\x03 %s\x01/\x03 %s\x01 with\x04 %s K\x01 and\x04 %s D", \
							Data, r_s, t_s, k_s, d_s);
	}
}

public void __printrankpriv(Handle pDb, Handle pQuery, char[] Error, any Data)
{
	static int r = 0;
	static char r_s[PLATFORM_MAX_PATH];
	static char t_s[PLATFORM_MAX_PATH];
	static char k_s[PLATFORM_MAX_PATH];
	static char d_s[PLATFORM_MAX_PATH];
	static char Steam[PLATFORM_MAX_PATH];
	
	if (g_Total > 0 && \
			IsClientInGame(Data) && \
				g_pDb != INVALID_HANDLE && \
					pQuery != INVALID_HANDLE && \
						pDb != INVALID_HANDLE && \
							SQL_HasResultSet(pQuery) && \
								(r = SQL_GetRowCount(pQuery)) > 0)
	{
		hCSGO_AddCommas(r, r_s, sizeof(r_s));
		hCSGO_AddCommas(g_Kills[Data], k_s, sizeof(k_s));
		hCSGO_AddCommas(g_Deaths[Data], d_s, sizeof(d_s));
		hCSGO_AddCommas(g_Total, t_s, sizeof(t_s));

		PrintToChat(Data, "* Welcome [\x04 %N\x01 ]", Data);
		PrintToChat(Data, "* Your rank is\x03 %s\x01/\x03 %s\x01 with\x04 %s K\x01 and\x04 %s D", \
							r_s, t_s, k_s, d_s);
		__STEAM(Data, Steam, sizeof(Steam));
		FormatEx(g_Qry, sizeof(g_Qry), "select mins from ore where steam = '%s';", Steam);
		SQL_TQuery(g_pDb, __printore, g_Qry, Data);
	}
}

public void __printore(Handle pDb, Handle pQuery, char[] Error, any Data)
{
	static int m = 0;
	static char time_s[PLATFORM_MAX_PATH];
	
	if (IsClientInGame(Data) && \
			g_pDb != INVALID_HANDLE && \
				pQuery != INVALID_HANDLE && \
					pDb != INVALID_HANDLE && \
						SQL_HasResultSet(pQuery) && \
							SQL_GetRowCount(pQuery) > 0 && \
								SQL_FetchRow(pQuery))
	{
		m = SQL_FetchInt(pQuery, 0);
		
		hCSGO_GetTimeStringMinutes(m, time_s, sizeof(time_s));
		
		g_Time[Data] = m;

		PrintToChat(Data, "* You spent\x04 %s\x01. Add\x03 us\x01 to your favorites!", time_s);
	}
}

public Action timerCreate(Handle pTimer, any Id)
{
	if (IsClientInGame(Id))
	{
		Create(Id);
		CreateTimer(GetRandomFloat(8.0, 12.0), printRankChat, Id, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action printRankChat(Handle pTimer, any Id)
{
	static char Steam[PLATFORM_MAX_PATH];
	if (IsClientInGame(Id))
	{
		FormatEx(g_Qry, sizeof(g_Qry), "select kills from ss_players;");
		SQL_TQuery(g_pDb, __readtotal, g_Qry);
		if (g_Id[Id] != -1)
		{
			FormatEx(g_Qry, sizeof(g_Qry), "select kills, deaths from ss_players where id = %d;", g_Id[Id]);
		}
		else
		{
			__STEAM(Id, Steam, sizeof(Steam));
			FormatEx(g_Qry, sizeof(g_Qry), "select kills, deaths from ss_players where steam = '%s';", Steam);
		}
		SQL_TQuery(g_pDb, __rootrankpriv, g_Qry, Id);
	}
}

public void OnPluginStart()
{
	if (GetFeatureStatus(FeatureType_Native, "GetMainDbHandle") != FeatureStatus_Available)
	{
		SQL_TConnect(OnCnx, "main_db");
	}

	else
	{
		g_pDb = GetMainDbHandle();

		if (!g_pDb)
		{
			SQL_TConnect(OnCnx, "main_db");
		}
	}

	HookEventEx("round_mvp", OnRoundMVP);
	HookEventEx("player_death", OnPlayerDeath);
	HookEventEx("round_start", OnRoundStart);
	
	HookEventEx("bomb_planted", OnBombPlanted);
	HookEventEx("bomb_defused", OnBombDefused);
	
	RegConsoleCmd("say", CommandSay);
	RegConsoleCmd("say_team", CommandSay);
}

public void OnRoundStart(Handle event, const char[] name, bool nobcast)
{
	static int x = 0;
	static float time = 0.0;
	
	time = 0.0;
	
	for (x = 1; x <= MaxClients; x++)
	{
		if (IsClientInGame(x))
		{
			time += 0.444;
			CreateTimer(time, updTimer, x, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public Action updTimer(Handle pTimer, any Data)
{
	if (IsClientInGame(Data))
		Update(Data);
}

public void OnBombDefused(Handle event, const char[] name, bool nobcast)
{
	static int x = 0;
	x = GetClientOfUserId(GetEventInt(event, "userid"));
	if (x > 0 && IsClientInGame(x))
	{
		PrintToChatAll(">>\x0B %N\x01 has defused the bomb!", x);
	}
}

public void OnBombPlanted(Handle event, const char[] name, bool nobcast)
{
	static int x = 0;
	x = GetClientOfUserId(GetEventInt(event, "userid"));
	if (x > 0 && IsClientInGame(x))
	{
		PrintToChatAll(">>\x09 %N\x01 has planted the bomb!", x);
	}
}

public void OnRoundMVP(Handle event, const char[] name, bool nobcast)
{
	static int x = 0;
	x = GetClientOfUserId(GetEventInt(event, "userid"));
	if (x > 0 && IsClientInGame(x))
	{
		AddMVP(x);
		PrintToChatAll(">>\x04 %N\x01 is the most valuable player!", x);
	}
}

public void OnPlayerDeath(Handle event, const char[] name, bool nobcast)
{
	static int v = 0, k = 0;
	static float vO[3], kO[3], d;
	v = GetClientOfUserId(GetEventInt(event, "userid"));
	k = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (v > 0 && k > 0 && IsClientInGame(v) && IsClientInGame(k))
	{
		if (v==k)
		{
			if (v != g_lastVictim[k])
				AddDeath(v);
		}
		else if (g_lastVictim[k] != v)
		{
			AddKill(k);
			AddDeath(v);
			if (GetEventBool(event, "headshot"))
			{
				AddHS(k);
			}
			if (IsPlayerAlive(k))
			{
				GetClientAbsOrigin(k, kO);
				GetClientAbsOrigin(v, vO);
			
				d = GetVectorDistance(kO, vO);
			
				d /= 39.37;

				if (g_bEnableVChatInfo)
				{
					PrintToChat(v, ">>\x04 %N\x01 @\x03 %.2f m\x01 &\x04 %d HP", k, d, GetClientHealth(k));
				}
				if (g_bEnableKChatInfo)
				{
					PrintToChat(k, ">>\x03 %N\x01 @\x04 %.2f m", v, d);
				}
			}
		}
		
		g_lastVictim[k] = v;
		
		CreateTimer(1.0, Timer_Reset, k, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Timer_Reset(Handle pTimer, any _Data)
{
	g_lastVictim[_Data] = INVALID_ENT_REFERENCE;
}

void __STEAM(int Id, char[] Out, int Size)
{
	if (IsFakeClient(Id))
		FormatEx(Out, Size, "BOT@%N", Id);

	else
		GetClientAuthId(Id, AuthId_Engine, Out, Size);
}

void Update(int Client)
{
	static char Steam[PLATFORM_MAX_PATH];
	static char Name[PLATFORM_MAX_PATH];
	static char newName[PLATFORM_MAX_PATH];
	static char Addr[PLATFORM_MAX_PATH];
	static char Code[PLATFORM_MAX_PATH];
	static char Cntry[PLATFORM_MAX_PATH];

	if (g_Id[Client] == -1)
	{
		__STEAM(Client, Steam, sizeof(Steam));
		GetClientName(Client, Name, sizeof(Name));
		GetClientIP(Client, Addr, sizeof(Addr));
		GeoR_Code(Addr, Code, sizeof(Code));
		GeoR_Country(Addr, Cntry, sizeof(Cntry));

		if (g_pDb != INVALID_HANDLE)
			SQL_EscapeString(g_pDb, Name, newName, sizeof(newName));
		else
			newName = "N/A";

		FormatEx(g_Qry, sizeof(g_Qry), "update ss_players set name = '%s', addr = '%s', code = '%s', cntry = '%s', seen = %d where steam = '%s';", \
					newName, Addr, Code, Cntry, GetTime(), Steam);
		if (g_pDb != INVALID_HANDLE)
			SQL_TQuery(g_pDb, __empty, g_Qry);
	}
	else
	{
		GetClientName(Client, Name, sizeof(Name));
		GetClientIP(Client, Addr, sizeof(Addr));
		GeoR_Code(Addr, Code, sizeof(Code));
		GeoR_Country(Addr, Cntry, sizeof(Cntry));

		if (g_pDb != INVALID_HANDLE)
			SQL_EscapeString(g_pDb, Name, newName, sizeof(newName));
		else
			newName = "N/A";

		FormatEx(g_Qry, sizeof(g_Qry), "update ss_players set name = '%s', addr = '%s', code = '%s', cntry = '%s', seen = %d where id = %d;", \
					newName, Addr, Code, Cntry, GetTime(), g_Id[Client]);
		if (g_pDb != INVALID_HANDLE)
			SQL_TQuery(g_pDb, __empty, g_Qry);
	}
}

void Create(int Client)
{
	static char Steam[PLATFORM_MAX_PATH];
	static char Name[PLATFORM_MAX_PATH];
	static char newName[PLATFORM_MAX_PATH];
	static char Addr[PLATFORM_MAX_PATH];
	static char Code[PLATFORM_MAX_PATH];
	static char Cntry[PLATFORM_MAX_PATH];

	__STEAM(Client, Steam, sizeof(Steam));
	GetClientName(Client, Name, sizeof(Name));
	GetClientIP(Client, Addr, sizeof(Addr));
	GeoR_Code(Addr, Code, sizeof(Code));
	GeoR_Country(Addr, Cntry, sizeof(Cntry));

	if (g_pDb != INVALID_HANDLE)
		SQL_EscapeString(g_pDb, Name, newName, sizeof(newName));
	else
		newName = "N/A";

	FormatEx(g_Qry, sizeof(g_Qry), "insert into ss_players (steam, name, addr, code, cntry, kills, deaths, hs, seen, mvp, kpd, mins, hsp) \
													values ('%s',  '%s', '%s', '%s', '%s',  0,     0,      0,  %d,   0,   0.0, 0,    0.0);", \
				Steam, newName, Addr, Code, Cntry, GetTime());
	if (g_pDb != INVALID_HANDLE)
		SQL_TQuery(g_pDb, __empty, g_Qry);

	FormatEx(g_Qry, sizeof(g_Qry), "select id from ss_players where steam = '%s' limit 1;", Steam);
	if (g_pDb != INVALID_HANDLE)
		SQL_TQuery(g_pDb, __getid, g_Qry, Client);
}

public void __empty(Handle pDb, Handle pQuery, char[] Error, any Data)
{
}

public void __getid(Handle pDb, Handle pQuery, char[] Error, any Data)
{
	if (IsClientInGame(Data) && \
			g_pDb != INVALID_HANDLE && \
				pQuery != INVALID_HANDLE && \
					pDb != INVALID_HANDLE && \
						SQL_HasResultSet(pQuery) && \
							SQL_GetRowCount(pQuery) > 0 && \
								SQL_FetchRow(pQuery))
	{
		g_Id[Data] = SQL_FetchInt(pQuery, 0);
	}
}

void AddKill(int Client)
{
	static char Steam[PLATFORM_MAX_PATH];
	
	if (g_Id[Client] == -1)
	{
		__STEAM(Client, Steam, sizeof(Steam));

		FormatEx(g_Qry, sizeof(g_Qry), "update ss_players set kills = kills + 1, seen = %d where steam = '%s';", GetTime(), Steam);
		if (g_pDb != INVALID_HANDLE)
			SQL_TQuery(g_pDb, __empty, g_Qry);
	}
	else
	{
		FormatEx(g_Qry, sizeof(g_Qry), "update ss_players set kills = kills + 1, seen = %d where id = %d;", GetTime(), g_Id[Client]);
		if (g_pDb != INVALID_HANDLE)
			SQL_TQuery(g_pDb, __empty, g_Qry);
	}
}

void AddMVP(int Client)
{
	static char Steam[PLATFORM_MAX_PATH];

	if (g_Id[Client] == -1)
	{
		__STEAM(Client, Steam, sizeof(Steam));

		FormatEx(g_Qry, sizeof(g_Qry), "update ss_players set mvp = mvp + 1, seen = %d where steam = '%s';", GetTime(), Steam);
		if (g_pDb != INVALID_HANDLE)
			SQL_TQuery(g_pDb, __empty, g_Qry);
	}
	else
	{
		FormatEx(g_Qry, sizeof(g_Qry), "update ss_players set mvp = mvp + 1, seen = %d where id = %d;", GetTime(), g_Id[Client]);
		if (g_pDb != INVALID_HANDLE)
			SQL_TQuery(g_pDb, __empty, g_Qry);
	}
}

void AddDeath(int Client)
{
	static char Steam[PLATFORM_MAX_PATH];
	
	if (g_Id[Client] == -1)
	{
		__STEAM(Client, Steam, sizeof(Steam));

		FormatEx(g_Qry, sizeof(g_Qry), "update ss_players set deaths = deaths + 1, seen = %d where steam = '%s';", GetTime(), Steam);
		if (g_pDb != INVALID_HANDLE)
			SQL_TQuery(g_pDb, __empty, g_Qry);
	}
	else
	{
		FormatEx(g_Qry, sizeof(g_Qry), "update ss_players set deaths = deaths + 1, seen = %d where id = %d;", GetTime(), g_Id[Client]);
		if (g_pDb != INVALID_HANDLE)
			SQL_TQuery(g_pDb, __empty, g_Qry);
	}
}

void AddHS(int Client)
{
	static char Steam[PLATFORM_MAX_PATH];

	if (g_Id[Client] == -1)
	{
		__STEAM(Client, Steam, sizeof(Steam));

		FormatEx(g_Qry, sizeof(g_Qry), "update ss_players set hs = hs + 1, seen = %d where steam = '%s';", GetTime(), Steam);
		if (g_pDb != INVALID_HANDLE)
			SQL_TQuery(g_pDb, __empty, g_Qry);
	}
	else
	{
		FormatEx(g_Qry, sizeof(g_Qry), "update ss_players set hs = hs + 1, seen = %d where id = %d;", GetTime(), g_Id[Client]);
		if (g_pDb != INVALID_HANDLE)
			SQL_TQuery(g_pDb, __empty, g_Qry);
	}
}
