#include <sourcemod>
#include <sdktools>
#pragma semicolon 1
#define PLUGIN_VERSION "1.75"
new Handle:cvar_Gamemode = INVALID_HANDLE;
new Handle:PanelModeCVAR = INVALID_HANDLE;
new Handle:PanelDisplayCVAR = INVALID_HANDLE;
new Handle:PanelDeadCVAR = INVALID_HANDLE;
new Handle:PanelSeCVAR = INVALID_HANDLE;
new Handle:SedCVAR = INVALID_HANDLE;
new Handle:AutoDisableCVAR = INVALID_HANDLE;
new Handle:showscoreCVAR = INVALID_HANDLE;
new Handle:timeoutCVAR = INVALID_HANDLE;
new Handle:ADSCVAR = INVALID_HANDLE;
new propinfoghost;
new bool:dp[MAXPLAYERS + 1];
new bool:se[MAXPLAYERS + 1];
public Plugin:myinfo =
{
	name = "L4D Team Displayer",
	author = "hihi1210,鮑",
	description = "This plug-in display a team panel.",
	version = "1.75",
	url = "http://kdt.poheart.com"
}

public OnPluginStart()
{
	decl String:game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));
	if (!StrEqual(game_name, "left4dead", false))
	{
		SetFailState("L4D Team Displayer supports Left 4 Dead only.");
	}
	CreateConVar("l4d_teampanel_version", PLUGIN_VERSION, " Version of L4D Team Viewer", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	PanelModeCVAR 		= CreateConVar("l4d_teampanel_mode", 					"2", "0: Выкл, 1: Показать панель без автообновления, 2: показать с автообновлением", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 2.0);
	PanelDisplayCVAR 	= CreateConVar("l4d_teampanel_display", 				"2", "0: показать всю информацию обоих команд, 1: показать никнэйм, здоровье и статус только игроков своей команды, 2: как '1' и ники игроков других команд", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 2.0);
	PanelDeadCVAR		= CreateConVar("l4d_teampanel_deadautodisplay", 		"1", "автоматически включать панель игроков погибшим игрокам", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	PanelSeCVAR 		= CreateConVar("l4d_teampanel_Spectatorautodisplay", 	"1", "автоматически включать панель игроков Зрителям", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	SedCVAR 			= CreateConVar("l4d_teampanel_Spectatordisplay", 		"1", "показывать Зрителей в панели", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	AutoDisableCVAR 	= CreateConVar("l4d_teampanel_AutoDisable", 			"1", "автоматически выключать панель игроков когда игрок ожил (работает только при l4d2_teampanel_mode 2)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	ADSCVAR 			= CreateConVar("l4d_teampanel_ads", 					"1", "рекламировать команду (3=показать chat и hint сообщение, 2=только hint сообщение, 1=только chat сообщение, 0=Выкл сообщение)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 3.0);
	showscoreCVAR  		= CreateConVar("l4d_teampanel_Autoshowafterscore", 		"0", "автоматически включать панель игроков когда игрок увидит таблицу подсчёта очков", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	timeoutCVAR 		= CreateConVar("l4d_teampanel_timeout", 				"1", "сколько секунд панель игроков будет исчезать (не остановит панель, когда она автоматически обновляется)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 999.0);
	RegConsoleCmd("sm_showteam", Command_Say);
	AutoExecConfig(true, "l4d_teamdisplay");
	cvar_Gamemode = FindConVar("mp_gamemode");
	propinfoghost = FindSendPropInfo("CTerrorPlayer", "m_isGhost");
}
public OnMapStart()
{
	if (GetConVarInt(PanelDeadCVAR) == 1)
	{
		HookEvent("player_death", Event_Death);
	}
	if (GetConVarInt(PanelSeCVAR) == 1)
	{
		HookEvent("player_team", Event_Team);
	}
	if (GetConVarInt(AutoDisableCVAR) == 1)
	{
		HookEvent("player_spawn", PlayerSpawn);
	}
}
public PlayerSpawn(Handle:Event, const String:Name[], bool:Broadcast)
{
	if (GetConVarInt(AutoDisableCVAR) == 1)
	{
		decl Client;
		Client = GetClientOfUserId(GetEventInt(Event, "userid"));
		if (Client == 0) return;
		if (IsFakeClient(Client)) return;
		if (dp[Client])
		{
			dp[Client] = false;
		}
	}
}
public Action:Event_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(PanelDeadCVAR) == 1)
	{
		new Victim = GetClientOfUserId(GetEventInt(event, "userid"));
		if (Victim == 0) return;
		if (IsFakeClient(Victim)) return;
		if (GetConVarInt(PanelModeCVAR) == 2)
		{
			if (dp[Victim]) return;
		}
		FakeClientCommand(Victim, "sm_showteam");
		if (GetConVarInt(PanelModeCVAR) == 1)
		{
			if (GetConVarInt(ADSCVAR) == 1 || GetConVarInt(ADSCVAR) == 3)
			{
				PrintToChat(Victim,"\x04 [TD]\x01 Впиши в чат\x03 !showteam\x01 чтобы увидеть панель команд");
			}
			if (GetConVarInt(ADSCVAR) == 2 || GetConVarInt(ADSCVAR) == 3)
			{
				PrintHintText(Victim,"[TD] Впиши в чат !showteam чтобы увидеть панель команд");
			}
		}
	}
}
public Action:Event_Team(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(PanelSeCVAR) == 1)
	{
		new Victim = GetClientOfUserId(GetEventInt(event, "userid"));
		if (Victim == 0) return;
		if (IsFakeClient(Victim)) return;
		if (GetEventInt(event, "team") !=1) return;
		if (GetConVarInt(PanelModeCVAR) == 2)
		{
			if (dp[Victim]) return;
		}
		FakeClientCommand(Victim, "sm_showteam");
		if (GetConVarInt(PanelModeCVAR) == 1)
		{
			if (GetConVarInt(ADSCVAR) == 1 || GetConVarInt(ADSCVAR) == 3)
			{
				PrintToChat(Victim,"\x04 [TD]\x01 Впиши в чат\x03 !showteam\x01 чтобы увидеть экран команд");
			}
			if (GetConVarInt(ADSCVAR) == 2 || GetConVarInt(ADSCVAR) == 3)
			{
				PrintHintText(Victim,"[TD] Впиши в чат !showteam чтобы увидеть экран команд");
			}
		}
	}
}
public OnClientPostAdminCheck(client)
{
	dp[client] = false;
	se[client] = false;
}
public OnClientDisconnect(client)
{
	dp[client] = false;
	se[client] = false;
}

public Action:Command_Say(client, args)
{
	if (GetConVarInt(PanelModeCVAR) == 1)
	{
		Teampanel(client);
	}
	else if (GetConVarInt(PanelModeCVAR) == 0)
	{
		return;
	}
	else if (GetConVarInt(PanelModeCVAR) == 2)
	{
		if (dp[client] == false)
		{
			dp[client] = true;
			if (GetConVarInt(ADSCVAR) == 1 || GetConVarInt(ADSCVAR) == 3)
			{
				PrintToChat(client,"\x04 [TD]\x01 Впиши в чат\x03 !showteam\x01 для вкл/выкл экрана команд");
			}
			if (GetConVarInt(ADSCVAR) == 2 || GetConVarInt(ADSCVAR) == 3)
			{
				PrintHintText(client,"[TD] Впиши в чат !showteam для вкл/выкл экрана команд");
			}
			CreateTimer(1.0, PAd,client, TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		{
			dp[client] = false;
			return;
		}
	}
	else
	{
		return;
	}
}

public Action:PAd(Handle:Timer, any:client)
{
	if(dp[client])
	{
		Teampanel(client);
		CreateTimer(1.0, PAd,client, TIMER_FLAG_NO_MAPCHANGE);
		return;
	}
	else
	{
		dp[client] = false;
		return;
	}
}
public Teampanel(client)
{
	new surcount = 0;
	new infcount = 0;
	new sepcount = 0;
	new surbotcount = 0;
	new infbotcount = 0;
	new String:CurrentMode[16];
	GetConVarString(cvar_Gamemode, CurrentMode, sizeof(CurrentMode));
	new Handle:downtownrun = FindConVar("l4d_maxplayers");
	new Handle:toolzrun = FindConVar("sv_maxplayers");
	new maxcl;
	if (downtownrun == INVALID_HANDLE)
	{
		//Nothing
	}
	if (downtownrun != INVALID_HANDLE)
	{
		new downtown = GetConVarInt(FindConVar("l4d_maxplayers"));
		if (downtown >= 1)
		{
			maxcl = (GetConVarInt(FindConVar("l4d_maxplayers")));
		}
	}
	if (toolzrun == INVALID_HANDLE)
	{
		//Nothing
	}
	if (toolzrun != INVALID_HANDLE)
	{
		new toolz = GetConVarInt(FindConVar("sv_maxplayers"));
		if (toolz >= 1)
		{
			maxcl = GetConVarInt(FindConVar("sv_maxplayers"));
		}
	}
	if (downtownrun == INVALID_HANDLE && toolzrun == INVALID_HANDLE)
	{
		maxcl = (MaxClients);
	}
	new maxplayers = GetMaxClients();
	for (new i = 1; i <= maxplayers; i++)
	{
		if(!IsClientInGame(i)) continue;
		if(GetClientTeam(i) != 2) continue;
		if(!IsFakeClient(i)) continue;
		surbotcount++;
	}
	for (new i = 1; i <= maxplayers; i++)
	{
		if(!IsClientInGame(i)) continue;
		if(GetClientTeam(i) != 3) continue;
		if(!IsFakeClient(i)) continue;
		infbotcount++;
	}
	if(GetClientTeam(client) == 2 || GetClientTeam(client) == 1)
	{
		new Handle:TeamPanel = CreatePanel();
		SetPanelTitle(TeamPanel, "L4D Экран команд");
		DrawPanelText(TeamPanel, " \n");
		DrawPanelText(TeamPanel, "Выжившые:");
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if(!IsClientInGame(i)) continue;
			if(!IsPlayerAlive(i)) continue;
			if(IsPlayerIncapped(i)) continue;
			if(GetClientTeam(i) != 2) continue;
			new String:name[64];
			surcount++;
			GetClientName(i, name, sizeof(name));
			new hp = GetClientHealth(i);
			new String:addoutput[128];
			Format(addoutput, sizeof(addoutput), "%s HP:%d", name, hp);
			DrawPanelText(TeamPanel, addoutput);
		}
		for (new i = 1; i <= maxplayers; i++)
		{
			if(!IsClientInGame(i)) continue;
			if(!IsPlayerAlive(i)) continue;
			if(!IsPlayerIncapped(i)) continue;
			if(GetClientTeam(i) != 2) continue;
			new String:name[64];
			GetClientName(i, name, sizeof(name));
			new hp = GetClientHealth(i);
			surcount++;
			new String:addoutput[128];
			Format(addoutput, sizeof(addoutput), "%s (Упал) HP:%d", name, hp);
			DrawPanelText(TeamPanel, addoutput);
		}
		for (new i = 1; i <= maxplayers; i++)
		{
			if(!IsClientInGame(i)) continue;
			if(IsPlayerAlive(i)) continue;
			if(GetClientTeam(i) != 2) continue;
			new String:name[64];
			GetClientName(i, name, sizeof(name));
			surcount++;
			new String:addoutput[128];
			Format(addoutput, sizeof(addoutput), "%s (Умер) ", name);
			DrawPanelText(TeamPanel, addoutput);
		}
		if (GetConVarInt(PanelDisplayCVAR) == 2 && GetClientTeam(client) !=1)
		{
			DrawPanelText(TeamPanel, " \n");
			DrawPanelText(TeamPanel, "Заражённые:");
			for (new i = 1; i <= maxplayers; i++)
			{
				if(!IsClientInGame(i)) continue;
				if(GetClientTeam(i) != 3) continue;
				new String:name[64];
				GetClientName(i, name, sizeof(name));
				infcount++;
				DrawPanelText(TeamPanel, name);
			}
		}
		if (GetConVarInt(PanelDisplayCVAR) == 0 || GetClientTeam(client) == 1)
		{
			DrawPanelText(TeamPanel, " \n");
			DrawPanelText(TeamPanel, "Заражённые:");
			for (new i = 1; i <= maxplayers; i++)
			{
				if(!IsClientInGame(i)) continue;
				if(!IsPlayerAlive(i)) continue;
				if(IsPlayerSpawnGhost(i)) continue;
				if(GetClientTeam(i) != 3) continue;
				new String:name[64];
				GetClientName(i, name, sizeof(name));
				infcount++;
				new String:addoutput[128];
				new hp = GetClientHealth(i);
				Format(addoutput, sizeof(addoutput), "%s HP:%d", name, hp);
				DrawPanelText(TeamPanel, addoutput);
			}
			for (new i = 1; i <= maxplayers; i++)
			{
				if(!IsClientInGame(i)) continue;
				if(!IsPlayerAlive(i)) continue;
				if(!IsPlayerSpawnGhost(i)) continue;
				if(GetClientTeam(i) != 3) continue;
				new String:name[64];
				GetClientName(i, name, sizeof(name));
				infcount++;
				new String:addoutput[128];
				Format(addoutput, sizeof(addoutput), "%s (ПРИЗРАК)", name);
				DrawPanelText(TeamPanel, addoutput);
			}
			for (new i = 1; i <= maxplayers; i++)
			{
				if(!IsClientInGame(i)) continue;
				if(IsPlayerAlive(i)) continue;
				if(GetClientTeam(i) != 3) continue;
				new String:name[64];
				GetClientName(i, name, sizeof(name));
				new String:addoutput[128];
				infcount++;
				Format(addoutput, sizeof(addoutput), "%s (Умер)", name);
				DrawPanelText(TeamPanel, addoutput);
			}
		}
		if (GetConVarInt(SedCVAR) == 1)
		{
			DrawPanelText(TeamPanel, " \n");
			DrawPanelText(TeamPanel, "Зрители:");
			for (new i = 1; i <= maxplayers; i++)
			{
				if(!IsClientInGame(i)) continue;
				if(GetClientTeam(i) != 1) continue;
				new String:name[64];
				GetClientName(i, name, sizeof(name));
				sepcount++;
				DrawPanelText(TeamPanel, name);
			}
		}
		DrawPanelText(TeamPanel, " \n");
		new String:addoutput1[128];
		new total = surcount + infcount + sepcount;
		new surreal = surcount - surbotcount;
		new infreal = infcount - infbotcount;
		new totalreal =  surreal + infreal + sepcount;
		if (GetConVarInt(PanelDisplayCVAR) != 1 || GetClientTeam(client) == 1)
		{
			if (GetConVarInt(SedCVAR) == 1)
			{
				if (StrContains(CurrentMode, "versus", false) != -1 || StrContains(CurrentMode, "scavenge", false) != -1  || StrContains(CurrentMode, "mutation12", false) != -1)
				{
					Format(addoutput1, sizeof(addoutput1), "Всего: %d(%d)/%d ВЫЖ: %d(%d)/%d ЗРЖ: %d(%d)/%d ЗРТЛ: %d", total, totalreal,maxcl, surcount,surreal,GetConVarInt(FindConVar("survivor_limit")), infcount,infreal,GetConVarInt(FindConVar("z_max_player_zombies")), sepcount);
				}
				else
				{
					Format(addoutput1, sizeof(addoutput1), "Всего: %d(%d) ВЫЖ: %d(%d)/%d ЗРЖ: %d(%d) ЗРТЛ: %d", total, totalreal, surcount,surreal,maxcl, infcount,infreal, sepcount);
				}
			}
			else
			{
				if (StrContains(CurrentMode, "versus", false) != -1 || StrContains(CurrentMode, "scavenge", false) != -1  || StrContains(CurrentMode, "mutation12", false) != -1)
				{
					Format(addoutput1, sizeof(addoutput1), "Всего: %d(%d)/%d ВЫЖ: %d(%d)/%d ЗРЖ: %d(%d)/%d", total, totalreal,maxcl, surcount,surreal,GetConVarInt(FindConVar("survivor_limit")), infcount,infreal,GetConVarInt(FindConVar("z_max_player_zombies")));
				}
				else
				{
					Format(addoutput1, sizeof(addoutput1), "Total: %d(%d) ВЫЖ: %d(%d)/%d ЗРЖ: %d(%d)", total, totalreal, surcount,surreal, maxcl, infcount,infreal);
				}
			}
		}
		else
		{
			if (GetConVarInt(SedCVAR) == 1)
			{
				if (StrContains(CurrentMode, "versus", false) != -1 || StrContains(CurrentMode, "scavenge", false) != -1  || StrContains(CurrentMode, "mutation12", false) != -1)
				{
					Format(addoutput1, sizeof(addoutput1), "ВЫЖ: %d(%d)/%d ЗРТЛ: %d", surcount,surreal,GetConVarInt(FindConVar("survivor_limit")), sepcount);
				}
				else
				{
					Format(addoutput1, sizeof(addoutput1), "ВЫЖ: %d(%d)/%d ЗРТЛ: %d", surcount,surreal,maxcl, sepcount);
				}
			}
			else
			{
				if (StrContains(CurrentMode, "versus", false) != -1 || StrContains(CurrentMode, "scavenge", false) != -1  || StrContains(CurrentMode, "mutation12", false) != -1)
				{
					Format(addoutput1, sizeof(addoutput1), "ВЫЖ: %d(%d)/%d", surcount,surreal,GetConVarInt(FindConVar("survivor_limit")));
				}
				else
				{
					Format(addoutput1, sizeof(addoutput1), "ВЫЖ: %d(%d)/%d", surcount,surreal,maxcl);
				}
			}
		}
		DrawPanelText(TeamPanel, addoutput1);
		SendPanelToClient(TeamPanel, client, TeamPanelHandler, GetConVarInt(timeoutCVAR));
		CloseHandle(TeamPanel);
	}
	else if(GetClientTeam(client) == 3)
	{
		new Handle:TeamPanel = CreatePanel();
		SetPanelTitle(TeamPanel, "L4D Экран команд");
		DrawPanelText(TeamPanel, " \n");
		DrawPanelText(TeamPanel, "Заражённые:");
		for (new i = 1; i <= maxplayers; i++)
		{
			if(!IsClientInGame(i)) continue;
			if(!IsPlayerAlive(i)) continue;
			if(IsPlayerSpawnGhost(i)) continue;
			if(GetClientTeam(i) != 3) continue;
			new String:name[64];
			infcount++;
			GetClientName(i, name, sizeof(name));
			new String:addoutput[128];
			new hp = GetClientHealth(i);
			Format(addoutput, sizeof(addoutput), "%s HP:%d", name, hp);
			DrawPanelText(TeamPanel, addoutput);
		}
		for (new i = 1; i <= maxplayers; i++)
		{
			if(!IsClientInGame(i)) continue;
			if(!IsPlayerAlive(i)) continue;
			if(!IsPlayerSpawnGhost(i)) continue;
			if(GetClientTeam(i) != 3) continue;
			infcount++;
			new String:name[64];
			GetClientName(i, name, sizeof(name));
			new String:addoutput[128];
			Format(addoutput, sizeof(addoutput), "%s (ПРИЗРАК)", name);
			DrawPanelText(TeamPanel, addoutput);
		}
		for (new i = 1; i <= maxplayers; i++)
		{
			if(!IsClientInGame(i)) continue;
			if(IsPlayerAlive(i)) continue;
			if(GetClientTeam(i) != 3) continue;
			new String:name[64];
			GetClientName(i, name, sizeof(name));
			new String:addoutput[128];
			infcount++;
			Format(addoutput, sizeof(addoutput), "%s (Умер)", name);
			DrawPanelText(TeamPanel, addoutput);
		}
		if (GetConVarInt(PanelDisplayCVAR) == 2 && GetClientTeam(client) != 1)
		{
			DrawPanelText(TeamPanel, " \n");
			DrawPanelText(TeamPanel, "Выжившые:");
			for (new i = 1; i <= maxplayers; i++)
			{
				if(!IsClientInGame(i)) continue;
				if(GetClientTeam(i) != 2) continue;
				new String:name[64];
				GetClientName(i, name, sizeof(name));
				surcount++;
				DrawPanelText(TeamPanel, name);
			}
		}
		if (GetConVarInt(PanelDisplayCVAR) == 0 || GetClientTeam(client) == 1)
		{
			DrawPanelText(TeamPanel, " \n");
			DrawPanelText(TeamPanel, "Выжившые:");

			for (new i = 1; i <= maxplayers; i++)
			{
				if(!IsClientInGame(i)) continue;
				if(!IsPlayerAlive(i)) continue;
				if(IsPlayerIncapped(i)) continue;
				if(GetClientTeam(i) != 2) continue;
				new String:name[64];
				GetClientName(i, name, sizeof(name));
				new hp = GetClientHealth(i);
				new String:addoutput[128];
				surcount++;
				Format(addoutput, sizeof(addoutput), "%s HP:%d", name, hp);
				DrawPanelText(TeamPanel, addoutput);
			}
			for (new i = 1; i <= maxplayers; i++)
			{
				if(!IsClientInGame(i)) continue;
				if(!IsPlayerAlive(i)) continue;
				if(!IsPlayerIncapped(i)) continue;
				if(GetClientTeam(i) != 2) continue;
				new String:name[64];
				GetClientName(i, name, sizeof(name));
				new hp = GetClientHealth(i);
				surcount++;
				new String:addoutput[128];
				Format(addoutput, sizeof(addoutput), "%s (Упал) HP:%d", name, hp);
				DrawPanelText(TeamPanel, addoutput);
			}
			for (new i = 1; i <= maxplayers; i++)
			{
				if(!IsClientInGame(i)) continue;
				if(IsPlayerAlive(i)) continue;
				if(GetClientTeam(i) != 2) continue;
				new String:name[64];
				GetClientName(i, name, sizeof(name));
				surcount++;
				new String:addoutput[128];
				Format(addoutput, sizeof(addoutput), "%s (Умер) ", name);
				DrawPanelText(TeamPanel, addoutput);
			}
		}
		if (GetConVarInt(SedCVAR) == 1)
		{
			DrawPanelText(TeamPanel, " \n");
			DrawPanelText(TeamPanel, "Зрители:");
			for (new i = 1; i <= maxplayers; i++)
			{
				if(!IsClientInGame(i)) continue;
				if(GetClientTeam(i) != 1) continue;
				new String:name[64];
				GetClientName(i, name, sizeof(name));
				sepcount++;
				DrawPanelText(TeamPanel, name);
			}
		}
		DrawPanelText(TeamPanel, " \n");
		new String:addoutput1[128];
		new total = surcount + infcount + sepcount;
		new surreal = surcount - surbotcount;
		new infreal = infcount - infbotcount;
		new totalreal =  surreal + infreal + sepcount;
		if (GetConVarInt(PanelDisplayCVAR) != 1 || GetClientTeam(client) == 1)
		{
			if (GetConVarInt(SedCVAR) == 1)
			{

				if (StrContains(CurrentMode, "versus", false) != -1 || StrContains(CurrentMode, "scavenge", false) != -1  || StrContains(CurrentMode, "mutation12", false) != -1)
				{
					Format(addoutput1, sizeof(addoutput1), "Всего: %d(%d)/%d ВЫЖ: %d(%d)/%d ЗРЖ: %d(%d)/%d ЗРТЛ: %d", total, totalreal,maxcl, surcount,surreal,GetConVarInt(FindConVar("survivor_limit")), infcount,infreal,GetConVarInt(FindConVar("z_max_player_zombies")), sepcount);
				}
				else
				{
					Format(addoutput1, sizeof(addoutput1), "Всего: %d(%d) ВЫЖ: %d(%d)/%d ЗРЖ: %d(%d) ЗРТЛ: %d", total, totalreal, surcount,surreal, maxcl, infcount,infreal, sepcount);
				}
			}
			else
			{
				if (StrContains(CurrentMode, "versus", false) != -1 || StrContains(CurrentMode, "scavenge", false) != -1  || StrContains(CurrentMode, "mutation12", false) != -1)
				{
					Format(addoutput1, sizeof(addoutput1), "Всего: %d(%d)/%d ВЫЖ: %d(%d)/%d ЗРЖ: %d(%d)/%d", total, totalreal,maxcl, surcount,surreal,GetConVarInt(FindConVar("survivor_limit")), infcount,infreal,GetConVarInt(FindConVar("z_max_player_zombies")));
				}
				else
				{
					Format(addoutput1, sizeof(addoutput1), "Всего: %d(%d) ВЫЖ: %d(%d)/%d ЗРЖ: %d(%d)", total, totalreal, surcount,surreal,maxcl, infcount,infreal);
				}
			}
		}

		else
		{
			if (GetConVarInt(SedCVAR) == 1)
			{
				if (StrContains(CurrentMode, "versus", false) != -1 || StrContains(CurrentMode, "scavenge", false) != -1  || StrContains(CurrentMode, "mutation12", false) != -1)
				{
					Format(addoutput1, sizeof(addoutput1), "ЗРЖ: %d(%d)/%d ЗРТЛ: %d", infcount,infreal,GetConVarInt(FindConVar("z_max_player_zombies")), sepcount);
				}
				else
				{
					Format(addoutput1, sizeof(addoutput1), "ЗРЖ: %d(%d) ЗРТЛ: %d", infcount,infreal, sepcount);
				}
			}
			else
			{
				if (StrContains(CurrentMode, "versus", false) != -1 || StrContains(CurrentMode, "scavenge", false) != -1  || StrContains(CurrentMode, "mutation12", false) != -1)
				{
					Format(addoutput1, sizeof(addoutput1), "ЗРЖ: %d(%d)/%d", infcount,infreal,GetConVarInt(FindConVar("z_max_player_zombies")));
				}
				else
				{
					Format(addoutput1, sizeof(addoutput1), "ЗРЖ: %d(%d)", infcount,infreal);
				}
			}
		}
		DrawPanelText(TeamPanel, addoutput1);
		SendPanelToClient(TeamPanel, client, TeamPanelHandler, GetConVarInt(timeoutCVAR));
		CloseHandle(TeamPanel);
	}
}
public TeamPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		dp[param1] = false;
	}
}
stock bool:IsPlayerIncapped(client)
{
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1)) return true;
	return false;
}
bool:IsPlayerSpawnGhost(client)
{
	if(GetEntData(client, propinfoghost, 1)) return true;
	else return false;
}
public Action:Reset(Handle:Timer, any:client)
{
	if (se[client])
	{
		se[client] = false;
	}
}
public Action:PAe(Handle:Timer, any:client)
{
	Teampanel(client);
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	// Check if its a valid player
	if (client == 0 || !IsClientInGame(client) || IsFakeClient(client)) return;
	if (GetConVarInt(showscoreCVAR) == 1)
	{
		if (buttons & IN_SCORE)
		{
			if (se[client]) return;
			if (se[client] == false)
			{
				se[client] = true;
				CreateTimer(2.0, PAe,client, TIMER_FLAG_NO_MAPCHANGE);
				CreateTimer(3.0, PAe,client, TIMER_FLAG_NO_MAPCHANGE);
				CreateTimer(4.0, PAe,client, TIMER_FLAG_NO_MAPCHANGE);
				CreateTimer(5.0, PAe,client, TIMER_FLAG_NO_MAPCHANGE);
				CreateTimer(6.0, PAe,client, TIMER_FLAG_NO_MAPCHANGE);
				CreateTimer(7.0, PAe,client, TIMER_FLAG_NO_MAPCHANGE);
				CreateTimer(8.0, PAe,client, TIMER_FLAG_NO_MAPCHANGE);

				CreateTimer(8.1, Reset,client, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}  
}  

