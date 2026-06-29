
#include <sourcemod>
#include <sdktools>
#include <cstrike>

public Plugin:myinfo = 
{
	name = "Score(SQL)",
	author = "펠로우즈",
	description = "Score Save",
	version = "1.0",
	url = ""
}
/*
	"score"
	{
		"driver"			"default"
		"host"				"localhost"
		"database"			"mysql"
		"user"				"root"
		"pass"				"password"
		//"timeout"			"0"
		//"port"			"0"
	}
*/
new Handle:db = INVALID_HANDLE;
new Kill[MAXPLAYERS+1];
new Death[MAXPLAYERS+1];
new HeadShot[MAXPLAYERS+1];
new BombPlanted[MAXPLAYERS+1];
new BombExplod[MAXPLAYERS+1];
new HostageRescued[MAXPLAYERS+1];
new Point[MAXPLAYERS+1];
new String:Score_Path[MAXPLAYERS+1];
new Load_Check[MAXPLAYERS+1];

new Handle:Death_Point;
new Handle:Kill_Point;
new Handle:C4_Planted_Point;
new Handle:C4_Exploded_Point;
new Handle:HeadShot_Point;
new Handle:HostageRescued_Point;
new Handle:Top_Limit;
	
new Handle:info_menu;
public OnMapStart()
{
	//Score 연결
	SQL_TConnect(Sqlcon, "score");
}
public Sqlcon(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		//아무것도없으므로 실패
		PrintToServer("Failed to connect: %s", error);
	} else
	{
		PrintToServer("Mysql Score Connected!");
		db = hndl;
		//문자 UTF-8
		SQL_TQuery(db, configcharset, "SET NAMES 'UTF8'", 0, DBPrio_High);
		//테이블체크
		SQL_TQuery(db, scoretablecheck, "show tables like 'score';", 0);
	}
}
public scoretablecheck(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(hndl == INVALID_HANDLE)
		LogError("table query exists failed %s", error);
	else if(SQL_GetRowCount(hndl) == 0)
		SQL_TQuery(db, createscoretable, "create table if not exists score(steamid varchar(64) primary key, username varchar(64), kill_score int, death_score int, headshot_score int, int, bombplanted_score int, bombexplod_score int, hostagerescued_score int, point_score int, Day DATETIME) ENGINE=MyISAM  DEFAULT CHARSET=utf8;", 0);
	//스팀번호, 이름, 킬, 데스,해드샷, 건보스킬, c4설치, c4폭파, 인질구출 포인트, 날짜
	//ENGINE=MyISAM  DEFAULT CHARSET=utf8 한글깨짐방지(Korean)
}
public createscoretable(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
		LogError("table query create failed %s", error);
}

public configcharset(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE) 
		LogError("Failed attempt to set the charset : %s", error);
}

public OnMapEnd()
{
	//데이터베이스 연결 해제
	if(db != INVALID_HANDLE)
	{
		PrintToServer("Mysql score DataBase Exit.");
		CloseHandle(db);
		db = INVALID_HANDLE;
	}
}

public OnPluginStart()
{
	CreateConVar("score_save_version", "1.0", "score save_version plugin info cvar", FCVAR_REPLICATED | FCVAR_NOTIFY);
	RegConsoleCmd("sm_rank", Command_INFO);
	HookEvent("player_death", Player_Death);
	BuildPath(Path_SM, Score_Path, MAXPLAYERS+1, "data/Score.txt");
	RegConsoleCmd("say", SayHook);
	
	Death_Point = CreateConVar("Death_Point", "-1", "Death_Point");
	Kill_Point = CreateConVar("Kill_Point", "1", " Kill_Point");
	C4_Planted_Point = CreateConVar("C4_Planted_Point", "1", "C4_Planted_Point");
	C4_Exploded_Point = CreateConVar("C4_Exploded_Point", "1", " C4_Exploded_Point");
	HeadShot_Point = CreateConVar("HeadShot_Point", "1", " HeadShot_Point");
	HostageRescued_Point = CreateConVar("HostageRescued_Point", "1", " HostageRescued_Point");
	Top_Limit = CreateConVar("Top_Limit", "10", " Top_Limit");
	AutoExecConfig(true, "Score");
	
	HookEvent("bomb_planted", Bomb_Planted); //설치됬을때
	HookEvent("bomb_exploded", Bomb_Exploded); //폭탄터짐
	HookEvent("hostage_rescued", Hostage_Rescued); //인질을 구할때
}
public Action:Hostage_Rescued(Handle:Event, const String:Name[], bool:Broadcast)
{
	new Client = GetClientOfUserId(GetEventInt(Event, "userid"));
	if(JoinCheck(Client))
	{
		if(!IsFakeClient(Client))
		{
			decl String:clientsteamid[32], String:query[256];
			GetClientAuthString(Client, clientsteamid, 32);
			HostageRescued[Client]++;
			Point[Client] += GetConVarInt(HostageRescued_Point);
			Format(query, 256, "update score set point_score = %d where steamid = '%s';", Point[Client], clientsteamid);
			SQL_TQuery(db, updatescore, query, Client);
		}
	}
}
public Action:Bomb_Planted(Handle:Event, const String:Name[], bool:Broadcast)
{
	new Client = GetClientOfUserId(GetEventInt(Event, "userid"));
	if(JoinCheck(Client))
	{
		if(!IsFakeClient(Client))
		{
			decl String:clientsteamid[32], String:query[256];
			GetClientAuthString(Client, clientsteamid, 32);
			BombPlanted[Client]++;
			Point[Client] += GetConVarInt(C4_Planted_Point);
			Format(query, 256, "update score set point_score = %d where steamid = '%s';", Point[Client], clientsteamid);
			SQL_TQuery(db, updatescore, query, Client);
		}
	}
}
public Action:Bomb_Exploded(Handle:Event, const String:Name[], bool:Broadcast)
{
	new Client = GetClientOfUserId(GetEventInt(Event, "userid"));
	if(JoinCheck(Client))
	{
		if(!IsFakeClient(Client))
		{
			decl String:clientsteamid[32], String:query[256];
			GetClientAuthString(Client, clientsteamid, 32);
			BombExplod[Client]++;
			Point[Client] += GetConVarInt(C4_Exploded_Point);
			Format(query, 256, "update score set point_score = %d where steamid = '%s';", Point[Client], clientsteamid);
			SQL_TQuery(db, updatescore, query, Client);
		}
	}
}

	
public Action:SayHook(Client, Arguments)
{
	new String:Msg[256];
	GetCmdArgString(Msg, sizeof(Msg));
	Msg[strlen(Msg)-1] = '\0';

	if(StrEqual(Msg[1], "!top", false))
	{
		decl String:bufferss[200];
		//select * from 테이블 order by `필드` desc limit 숫자
		Format(bufferss, 256, "select * from score order by `point_score` desc limit %d", GetConVarInt(Top_Limit));
		SQL_TQuery(db, Command_top, bufferss, Client);
	}
}
public Command_top(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	new Handle:Panel = CreateMenu(Menu_top);
	SetMenuTitle(Panel, "Top - Point");
	decl String:text[64],  String:top_name[256], top_point;
	new counted = SQL_GetRowCount(hndl);
	//핃드가 1개라도 잇을대
	if(counted > 0)
	{
		//그필드가 존재할때
		if (SQL_HasResultSet(hndl))
		{
			while (SQL_FetchRow(hndl))
			{
				//createtable에서 2번째칸에적어둔 name을 가져옴
				SQL_FetchString(hndl, 1, top_name, sizeof(top_name));
				//5번째칸에적어둔 point를 가져옴
				top_point = SQL_FetchInt(hndl,8);
				Format(text,127,"%s - %d", top_name, top_point);
				AddMenuItem(Panel, "", text);		
			}
		}
	}
	SetMenuExitButton(Panel, true);
	DisplayMenu(Panel, client, MENU_TIME_FOREVER);
}
public Menu_top(Handle:Menu, MenuAction:Click, Parameter1, Parameter2){}
public Action:Command_INFO(Client, Arguments)
{
	decl String:bufferss[200];
	if(Arguments < 1)
	{
		Format(bufferss, 256, "SELECT * FROM score ORDER BY point_score DESC");
		SQL_TQuery(db, Command_rank, bufferss, Client);
		CreateTimer(0.2, SendPopup, Client);
	}
	else
	{
		new String:Player_Name[32], Max, Target = -1;
		GetCmdArg(1, Player_Name, sizeof(Player_Name));
		Max = GetMaxClients();
		for(new i=1; i <= Max; i++)
		{
			if(!IsClientConnected(i))
				continue;
			new String:Other[128];
			GetClientName(i, Other, sizeof(Other));
			if(StrContains(Other, Player_Name, false) != -1)
				Target = i;
		}
		if(Target == -1)
		{
			PrintToChat(Client, "%s is not found.", Player_Name);
			return Plugin_Handled;
		}
		Format(bufferss, 256, "SELECT * FROM score ORDER BY point_score DESC");
		SQL_TQuery(db, Command_rank, bufferss, Target);
		CreateTimer(0.2, SendPopup, Client);
	}
	return Plugin_Continue;
}

public Action:SendPopup(Handle:Timer, any:Client)
{
	SendPanelToClient(info_menu, Client, info_menu_choice, MENU_TIME_FOREVER);
}
public Command_rank(Handle:owner, Handle:hndl, const String:error[], any:Client)
{
	decl String:steamid[64], String:my_steamid[64], myrank, maxrank;
	GetClientAuthString(Client, my_steamid, 32);
	new counted = SQL_GetRowCount(hndl);
	//필드가 1개라도잇을때
	if(counted > 0)
	{
		//그게존재한다면!!
		if (SQL_HasResultSet(hndl))
		{
			while (SQL_FetchRow(hndl))
			{
				//최대인원을구함 maxrank
				maxrank++;
				//테이블1번칸에 적어둔 스팀번호를 가져옴
				SQL_FetchString(hndl, 0, steamid, sizeof(steamid));
				//그게 자신의 것과 맞다면 내림차순으로인해 자신의 순위를 구할수잇슴
				if(StrEqual(steamid, my_steamid, false))
					myrank = maxrank;
			}
		}
	}
	
	new String:client_name[256], String:rank[256], String:kd[256],
	String:headshot_count[256], String:bomb_planted[256],
	String:bomb_explod[256], String:hostage_rescued[256], String:point_format[256];
	Format(client_name, sizeof(client_name), "%N", Client);
	Format(rank, sizeof(rank), "Ranking : %d/%d", myrank, maxrank);
	Format(kd, sizeof(kd), "Kill/Death : %d/%d", Kill[Client], Death[Client]);
	Format(headshot_count, sizeof(headshot_count), "HeadShot : %d", HeadShot[Client]);
	Format(bomb_planted, sizeof(bomb_planted), "C4 Planted : %d", BombPlanted[Client]);
	Format(bomb_explod, sizeof(bomb_explod), "C4 Expload : %d", BombExplod[Client]);
	Format(hostage_rescued, sizeof(hostage_rescued), "Hostage Rescued : %d", HostageRescued[Client]);
	Format(point_format, sizeof(point_format), "Point : %d", Point[Client]);
	myrank = 0;
	maxrank = 0;
	
	info_menu = CreatePanel(INVALID_HANDLE);
	SetPanelTitle(info_menu, "User Information");
	DrawPanelText(info_menu, "----------------------------");
	DrawPanelText(info_menu, client_name);
	DrawPanelText(info_menu, my_steamid);
	DrawPanelText(info_menu, "   ");
	DrawPanelText(info_menu, rank);
	DrawPanelText(info_menu, kd);
	DrawPanelText(info_menu, headshot_count);
	DrawPanelText(info_menu, bomb_planted);
	DrawPanelText(info_menu, bomb_explod);
	DrawPanelText(info_menu, hostage_rescued);
	DrawPanelText(info_menu, point_format);
	DrawPanelText(info_menu, "----------------------------");
	DrawPanelItem(info_menu, "EXIT");	
}
public info_menu_choice(Handle:menu, MenuAction:Click, client, item){}
public Action:Player_Death(Handle:Event, const String:name[], bool:dontBroadcast)
{
	new Client = GetClientOfUserId(GetEventInt(Event, "userid"));
	new Attacker = GetClientOfUserId(GetEventInt(Event, "attacker"));
	decl String:clientsteamid[32], String:query[256];
	if(JoinCheck(Attacker) == true)
	{
		if(!IsFakeClient(Attacker))
		{
			if(GetClientTeam(Client) != GetClientTeam(Attacker))
			{
				new HS = GetEventInt(Event, "headshot");
				Kill[Attacker] ++;
				Point[Attacker] += GetConVarInt(Kill_Point);
				if(HS == 1)
				{
					HeadShot[Attacker] ++;
					Point[Attacker] += GetConVarInt(HeadShot_Point);
				}
				GetClientAuthString(Attacker, clientsteamid, 32);
				Format(query, 256, "update score set point_score = %d where steamid = '%s';", Point[Attacker], clientsteamid);
				SQL_TQuery(db, updatescore, query, Attacker);
			}
		}
		if(!IsFakeClient(Client))
		{
			Death[Client] ++;
			Point[Client] += GetConVarInt(Death_Point);
			GetClientAuthString(Client, clientsteamid, 32);
			Format(query, 256, "update score set point_score = %d where steamid = '%s';", Point[Client], clientsteamid);
			SQL_TQuery(db, updatescore, query, Client);
		}
	}
}

public OnClientPutInServer(Client)
{
	if(!IsFakeClient(Client))
	{
		CreateTimer(2.0, Score_SQL_Load, Client);
	}
}
public Action:Score_SQL_Load(Handle:timer, any:Client)
{
	if(JoinCheck(Client) == true)
	{
		if(db != INVALID_HANDLE)
		{
			Load_Check[Client] = 1 ;
			decl String:clientsteamid[32], String:query[256];
			GetClientAuthString(Client, clientsteamid, 32);
			Format(query, 256, "select * from score where steamid = '%s';", clientsteamid);
			SQL_TQuery(db, existcheck, query, Client);
		}
	}
}
public existcheck(Handle:owner, Handle:hndl, const String:error[], any:Client)
{
	decl String:query[256];
	decl String:clientsteamid[32];
	GetClientAuthString(Client, clientsteamid, 32);
	//steamidtodbid(clientsteamid, 32);
	decl String:Name[256];
	GetClientName(Client, Name, sizeof(Name));
	if (hndl == INVALID_HANDLE)
	{
		//테이블이 존재하지않는다
		LogError("exist check failed %s", error);
		PrintToServer("exist check failed %s", error);
	}
	else if(SQL_GetRowCount(hndl) != 0)
	{
		SQL_TQuery(db, Load_Score, "SELECT * FROM score", Client);
	}
	else
	{
		Format(query, 256, "insert into score(steamid, Day) values('%s', now());",clientsteamid);
		SQL_TQuery(db, insertscore, query, 0);
	}
}
public insertscore(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
		LogError("query insert failed %s", error);
}
public Load_Score(Handle:owner, Handle:hndl, const String:error[], any:Client)
{
	decl String:steamid[64], String:my_steamid[64];
	GetClientAuthString(Client, my_steamid, 32);
	if(SQL_GetRowCount(hndl))
	{
		if(SQL_HasResultSet(hndl))
		{
			while(SQL_FetchRow(hndl))
			{
				SQL_FetchString(hndl, 0, steamid, sizeof(steamid));
				if(StrEqual(steamid, my_steamid, false))
				{
					//생략
					Kill[Client] = SQL_FetchInt(hndl,2);
					Death[Client] = SQL_FetchInt(hndl,3);
					HeadShot[Client] = SQL_FetchInt(hndl,4);
					BombPlanted[Client] = SQL_FetchInt(hndl,5);
					BombExplod[Client] = SQL_FetchInt(hndl,6);
					HostageRescued[Client] = SQL_FetchInt(hndl,7);
					Point[Client] = SQL_FetchInt(hndl,8);
					//스코어에 Kill수를 조절한다
					SetEntProp(Client, Prop_Data, "m_iFrags", Kill[Client]);
					//스코어에 Death수를 조절한다
					SetEntProp(Client, Prop_Data, "m_iDeaths", Death[Client]);
				}
			}
		}
	}
}
public OnClientDisconnect(Client)
{
	if(!IsFakeClient(Client))
	{
		if(Load_Check[Client] == 1)
		{
			Load_Check[Client] = 0;
			decl String:clientsteamid[64], String:clientname[64], String:query[512];
			GetClientAuthString(Client, clientsteamid, 32);
			GetClientName(Client, clientname, sizeof(clientname));
			decl String:sEscapedName[MAX_NAME_LENGTH * 2 + 1];
			SQL_EscapeString(db, clientname, sEscapedName, sizeof(sEscapedName));
			/*
			Format(query, 256, "update score set username = '%s', kill_score = %d, death_score = %d, headshot_score = %d, bombplanted_score = %d, bombexplod_score = %d, hostagerescued_score = %d, Day = now() where steamid = '%s';",
			sEscapedName, Kill[Client], Death[Client], HeadShot[Client], BombPlanted[Client], BombExplod[Client], HostageRescued[Client], clientsteamid);
			SQL_TQuery(db, updatescore, query, Client);
			*/
			Format(query, sizeof(query), "UPDATE score SET username = '%s' WHERE steamid = '%s';", sEscapedName, clientsteamid);
			SQL_TQuery(db, updatescore, query, Client);
			
			Format(query, 256, "update score set kill_score = %d, death_score = %d, headshot_score = %d, Day = now() where steamid = '%s';",
			Kill[Client], Death[Client], HeadShot[Client], clientsteamid);
			SQL_TQuery(db, updatescore, query, Client);
			
			Format(query, 256, "update score set  = %d, bombplanted_score = %d, bombexplod_score = %d, hostagerescued_score = %d where steamid = '%s';",
			BombPlanted[Client], BombExplod[Client], HostageRescued[Client], clientsteamid);
			SQL_TQuery(db, updatescore, query, Client);
			
			Kill[Client] = 0;
			Death[Client] = 0;
			HeadShot[Client] = 0;
			BombPlanted[Client] = 0;
			BombExplod[Client] = 0;
			HostageRescued[Client] = 0;
			Point[Client] = 0;
		}
	}
}

public updatescore(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
		LogError("query update failed %s", error);
}
public bool:AliveCheck(Client)
{
	if(Client > 0 && Client <= MaxClients)
		if(IsClientConnected(Client) == true)
			if(IsClientInGame(Client) == true)
				if(IsPlayerAlive(Client) == true) return true;
				else return false;
			else return false;
		else return false;
	else return false;
}
public bool:JoinCheck(Client)
{
	if(Client > 0 && Client <= MaxClients)
		if(IsClientConnected(Client) == true)
			if(IsClientInGame(Client) == true) return true;
			else return false;
		else return false;
	else return false;
}