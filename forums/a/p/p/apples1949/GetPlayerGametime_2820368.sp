#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <SteamWorks>
#include <left4dhooks>

#define DEBUG 0

public Plugin myinfo =
{
	name		= "get player real gametime",
	author		= "apples1949 , 豆瓣酱な , deepseek",
	description = "",
	version		= "1.4.2",
	url			= "https://github.com/apples1949",
};

int	   i_Count[MAXPLAYERS + 1];
int	   i_PlayerTime[MAXPLAYERS + 1];
bool   CheckPluginLate = false;
int	   i_ShowGametimeMode;
int	   i_CheckPlayerGameCount;
int	   b_LimitPlayer;
int	   i_LimitPlayerMinGametime;
int	   i_LimitPlayerMaxGametime;
int	   i_LimitPlayerMode;
bool   b_Enable;
bool   b_ShowPlayerLerp;
bool   b_LPWRequesting;
bool   b_LPLateload;
int	   i_LPMWFailureGet;
bool   b_SPLMode;
bool   b_IfNeedLogKickMsg;
bool   hasTranslations;
ConVar c_ShowGametimeMode;
ConVar c_CheckPlayerGameCount;
ConVar c_LimitPlayer;
ConVar c_LimitPlayerMinGametime;
ConVar c_LimitPlayerMaxGametime;
ConVar c_LimitPlayerMode;
ConVar c_Enable;
ConVar c_ShowPlayerLerp;
ConVar c_LPWRequesting;
ConVar c_LPLateload;
ConVar c_LPMWFailureGet;
ConVar c_SPLMode;
ConVar c_IfNeedLogKickMsg;

char   chatFile[128];

ConVar
	g_cvMinUpdateRate  = null,
	g_cvMaxUpdateRate  = null,
	g_cvMinInterpRatio = null,
	g_cvMaxInterpRatio = null;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CheckPluginLate = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, PLATFORM_MAX_PATH, "translations/GetPlayerGametime.phrases.txt");
	hasTranslations = FileExists(path);
	if (hasTranslations) LoadTranslations("GetPlayerGametime.phrases");
	else LogError("Not translations file GetPlayerGametime.phrases.txt found yet!");

	if (GetExtensionFileStatus("SteamWorks.ext") != 1)
	{
		LogError("SteamWorks isn't installed or failed to load. Grenade Trails will be disabled. Please install SteamWorks. (https://forums.alliedmods.net/showthread.php?t=229556)");
		return;
	}

	c_Enable				 = CreateConVar("GetPlayerGametimeEnable", "1", "Enable plugin?,0:disable", FCVAR_NOTIFY, true, 0.0, true, 1.0);																																		   //这个都看不懂建议别玩插件捏
	c_ShowGametimeMode		 = CreateConVar("ShowGametimeMode", "2", "What type of game duration is displayed to players? 1:hour and minute  2=Hours rounded to two decimal places", FCVAR_NOTIFY, true, 1.0, true, 2.0);															   //向玩家显示什么类型的游戏时长? 1:小时分钟 2=小时带两位小数
	c_CheckPlayerGameCount	 = CreateConVar("CheckPlayerGameCount", "8", "If for any possible reason it fails to get the player's real gametime, how many times should it be repeated to get the player's game time? 0:Disabled", FCVAR_NOTIFY, true, 0.0);							   //如果因可能的各种原因导致获取玩家的真实游戏时长失败,那么重复多少次获取玩家游戏时长? 0:禁用
	c_LPWRequesting			 = CreateConVar("LPWRequesting", "0", "If the player's real gametime is being acquired repeatedly. Does it move the player to spec? 0:disable", FCVAR_NOTIFY, true, 0.0, true, 1.0);																	   //如果正在反复获取玩家的真实游戏时长的情况下。是否将玩家移动到旁观？0:禁用
	c_LPMWFailureGet		 = CreateConVar("LPMWFailureGet", "0", "How to deal with players if repeatedly getting player real playtime fails?0:disable, 1:kick 2=move to spec", FCVAR_NOTIFY, true, 0.0, true, 2.0);																   //如果反复获取玩家真实游戏时长失败，如何处理玩家？0:禁用，1:踢出 2=移动到旁观
	c_LPLateload			 = CreateConVar("LPLateload", "1", "If LimitPlayer=1 and the plugin is not activated properly, does it cancel the behavior of various plugins that restrict the player due to real playertime?0:disable 1:enable", FCVAR_NOTIFY, true, 0.0, true, 1.0);	   //如果LimitPlayer=1且插件未正常启动的情况下，是否取消各种因真实游戏时长而限制玩家的插件行为？0:禁用
	c_LimitPlayer			 = CreateConVar("LimitPlayer", "1", "Are players who meet the gametime criteria prohibited from entering the server or entering the game? 0:disable 1:enable", FCVAR_NOTIFY, true, 0.0, true, 1.0);														   //是否禁止符合时长条件的玩家进入服务器或进入对局? 0:禁用 1:启用
	c_LimitPlayerMinGametime = CreateConVar("LimitPlayerMinGametime", "1", "How long is the minimum prohibition for gametime players to enter the server or enter the game", FCVAR_NOTIFY, true, 1.0);																				   //最低禁止多少秒的玩家进入服务器或进入对局(小时乘3600)
	c_LimitPlayerMaxGametime = CreateConVar("LimitPlayerMaxGametime", "36000", "How long is the maximum prohibition for gametime players to enter the server or enter the game", FCVAR_NOTIFY, true, 1.0);
	c_LimitPlayerMode		 = CreateConVar("LimitPlayerMode", "2", "If LimitPlayer is not 0, how will eligible players be processed? 1:kick out, 2=move to spec", FCVAR_NOTIFY, true, 1.0, true, 2.0);		 //如果LimitPlayer不为0,则如何处理符合时长区间的玩家? 1:踢出,2=移动到旁观
	c_ShowPlayerLerp		 = CreateConVar("ShowPlayerLerp", "1", "Show Player Lerp with gametime? 0:disable 1:enable", FCVAR_NOTIFY, true, 0.0, true, 1.0);												 //是否显示玩家的lerp值，0:禁用，1:启用
	c_SPLMode				 = CreateConVar("SPLMode", "1", "Whether to display player real playtime and Lerp information by player team 0:Output in player order.", FCVAR_NOTIFY, true, 0.0, true, 1.0);	 //是否按照玩家阵营显示玩家真实玩家时长及Lerp信息 0:按照玩家顺序输出
	c_IfNeedLogKickMsg		 = CreateConVar("IfNeedLogKickMsg", "1", "Need Log Kick Auto Kick Player Message? 0:disable", FCVAR_NOTIFY, true, 0.0, true, 1.0);												 //是否记录踢出玩家的信息？

	g_cvMinUpdateRate		 = FindConVar("sv_minupdaterate");
	g_cvMaxUpdateRate		 = FindConVar("sv_maxupdaterate");
	g_cvMinInterpRatio		 = FindConVar("sv_client_min_interp_ratio");
	g_cvMaxInterpRatio		 = FindConVar("sv_client_max_interp_ratio");

	GetCvars();
	c_Enable.AddChangeHook(ConVarChanged);
	c_ShowGametimeMode.AddChangeHook(ConVarChanged);
	c_CheckPlayerGameCount.AddChangeHook(ConVarChanged);
	c_LPWRequesting.AddChangeHook(ConVarChanged);
	c_LPMWFailureGet.AddChangeHook(ConVarChanged);
	c_LPLateload.AddChangeHook(ConVarChanged);
	c_LimitPlayer.AddChangeHook(ConVarChanged);
	c_LimitPlayerMinGametime.AddChangeHook(ConVarChanged);
	c_LimitPlayerMaxGametime.AddChangeHook(ConVarChanged);
	c_LimitPlayerMode.AddChangeHook(ConVarChanged);
	c_ShowPlayerLerp.AddChangeHook(ConVarChanged);
	c_SPLMode.AddChangeHook(ConVarChanged);
	c_IfNeedLogKickMsg.AddChangeHook(ConVarChanged);

	HookEvent("player_team", Event_PlayerTeam);

	RegConsoleCmd("sm_playertime", cmdplayertime);

	AutoExecConfig(true, "GetPlayerGametime");

	if (CheckPluginLate)
	{
		lateload();
	}
}

void ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
#if DEBUG
	colors_print_to_chat_all("cvar is change,requite all player gametime");
#endif
	GetCvars();
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientAuthorized(i) && IsClientInGame(i)) OnClientPostAdminCheck(i);
	}
}

void GetCvars()
{
	b_Enable				 = c_Enable.BoolValue;
	i_ShowGametimeMode		 = c_ShowGametimeMode.IntValue;
	i_CheckPlayerGameCount	 = c_CheckPlayerGameCount.IntValue;
	b_LPWRequesting			 = c_LPWRequesting.BoolValue;
	i_LPMWFailureGet		 = c_LPMWFailureGet.IntValue;
	b_LPLateload			 = c_LPLateload.BoolValue;
	b_LimitPlayer			 = c_LimitPlayer.BoolValue;
	i_LimitPlayerMaxGametime = c_LimitPlayerMaxGametime.IntValue;
	i_LimitPlayerMinGametime = c_LimitPlayerMinGametime.IntValue;
	i_LimitPlayerMode		 = c_LimitPlayerMode.IntValue;
	b_ShowPlayerLerp		 = c_ShowPlayerLerp.BoolValue;
	b_SPLMode				 = c_SPLMode.BoolValue;
	b_IfNeedLogKickMsg		 = c_IfNeedLogKickMsg.BoolValue;
}

public void OnClientPostAdminCheck(int client)
{
	if (!b_Enable) return;
	if (IsValidClient(client) && !IsFakeClient(client) && IsClientConnected(client))
	{
		i_Count[client]		 = 0;
		i_PlayerTime[client] = 0;
		if (!GetPlayerGameTime(client))
		{
			i_PlayerTime[client] = -1;
#if DEBUG
			colors_print_to_chat_all("failure get player %N gametime", client);
#endif
			// colors_print_to_chat_all("{green}[{olive}!{green}]{default}玩家{olive} %N {default}已连接,正在获取玩家的实际游戏时长.", client);
			// colors_print_to_chat_all("%t", "PlayerConnect", client);
			LimitPlayer(client);
			CreateTimer(1.0, MoreGetPlayerGameTime, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		{
#if DEBUG
			colors_print_to_chat_all("get player %N gametime success", client);
#endif
			AnnouncePlayerTime(client);
			LimitPlayer(client);
		}
	}
}

Action MoreGetPlayerGameTime(Handle timer, any client)
{
	if ((client = GetClientOfUserId(client)) && IsValidClient(client) && !IsFakeClient(client))
	{
#if DEBUG
		colors_print_to_chat_all("%N Need More Get PlayerGametime%d/%d", client, i_Count[client], i_CheckPlayerGameCount);
#endif
		i_Count[client] += 1;
		if (i_Count[client] >= i_CheckPlayerGameCount)
		{
			i_PlayerTime[client] = -2;
			LimitPlayer(client);
			return Plugin_Stop;
		}
		else
		{
			if (!GetPlayerGameTime(client))
			{
				i_PlayerTime[client] = -1;
				LimitPlayer(client);
				CreateTimer(1.0, MoreGetPlayerGameTime, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
			}
			else
			{
				AnnouncePlayerTime(client);
				LimitPlayer(client);
			}
		}
		return Plugin_Continue;
	}
	return Plugin_Stop;
}

Action cmdplayertime(int client, int args)
{
#if DEBUG
	colors_print_to_chat_all("Command executed successfully");
#endif
	if (b_SPLMode)
	{
		int survivorCount  = 0;
		int infectedCount  = 0;
		int spectatorCount = 0;
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i))
			{
				if (GetClientTeam(i) == 2) survivorCount = 1;
				if (GetClientTeam(i) == 3) infectedCount = 1;
				if (GetClientTeam(i) == 1) spectatorCount = 1;
			}
		}
		if (survivorCount == 1) colors_print_to_chat_all("{olive}-------------------------------------------------------------------");
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i) && IsClientConnected(i) && GetClientTeam(i) == 2)
			{
				AnnouncePlayerTime(i);
			}
		}
		if (survivorCount == 1) colors_print_to_chat_all("{olive}-------------------------------------------------------------------");
		if (infectedCount == 1) colors_print_to_chat_all("{green}-------------------------------------------------------------------");
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i) && IsClientConnected(i) && GetClientTeam(i) == 3)
			{
				AnnouncePlayerTime(i);
			}
		}
		if (infectedCount == 1) colors_print_to_chat_all("{green}-------------------------------------------------------------------");
		if (spectatorCount == 1) colors_print_to_chat_all("-------------------------------------------------------------------");
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i) && IsClientConnected(i) && GetClientTeam(i) == 1)
			{
				AnnouncePlayerTime(i);
			}
		}
		if (spectatorCount == 1) colors_print_to_chat_all("-------------------------------------------------------------------");
	}
	else
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i) && !IsFakeClient(i))
			{
				AnnouncePlayerTime(i);
			}
		}
	}

	return Plugin_Handled;
}

void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	if (!b_Enable && b_LimitPlayer) return;
	int client	= GetClientOfUserId(event.GetInt("userid"));
	int oldteam = event.GetInt("oldteam");
	int iTeam	= event.GetInt("team");

	if (IsValidClient(client) && !IsFakeClient(client) && (oldteam == 1 || iTeam == 1))
	{
		LimitPlayer(client);
	}
}

bool GetPlayerGameTime(int client)
{
	SteamWorks_RequestStats(client, 550);
	bool b_gametime = SteamWorks_GetStatCell(client, "Stat.TotalPlayTime.Total", i_PlayerTime[client]);
#if DEBUG
	colors_print_to_chat_all("Get %N Real GameTime bool:%d gametime is:%d", client, b_gametime, i_PlayerTime[client]);
#endif
	return b_gametime;
}

bool IsValidClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client);
}

bool CheckPlayerGametime(int client)
{
#if DEBUG
	PrintToChatAll("Check Player %N Gametime", client);
#endif
	if (i_PlayerTime[client] > i_LimitPlayerMinGametime && i_PlayerTime[client] < i_LimitPlayerMaxGametime)
	{
#if DEBUG
		colors_print_to_chat_all("%d %d %d %N,CheckPlayerGametime is ture", i_PlayerTime[client], i_LimitPlayerMinGametime, i_LimitPlayerMaxGametime, client);
#endif
		return true;
	}
#if DEBUG
	colors_print_to_chat_all("%d %d %d %N,CheckPlayerGametime is false", i_PlayerTime[client], i_LimitPlayerMinGametime, i_LimitPlayerMaxGametime, client);
#endif
	return false;
}

/*
void CheckPlayerGametime(int client)
{
	#if DEBUG
	PrintToChatAll("Check Player %N Gametime",client);
	#endif
	if (i_PlayerTime[client] > i_LimitPlayerMinGametime && i_PlayerTime[client] < i_LimitPlayerMaxGametime && (i_LimitPlayerMode != 0))
	{
		if(b_LPLateload && CheckPluginLate)return;
		#if DEBUG
		colors_print_to_chat_all("%d %d %d %N,CheckPlayerGametime is ture", i_PlayerTime[client], i_LimitPlayerMinGametime, i_LimitPlayerMaxGametime, client);
		#endif
		if (i_LimitPlayerMode == 1)
		{
			float f_LimitPlayerMinGametime = float(i_LimitPlayerMinGametime) / 3600;
			float f_LimitPlayerMaxGametime = float(i_LimitPlayerMaxGametime) / 3600;
			// KickClient(client, "你因游戏时长不符合服务器规则(%.2f - %.2f)而被自动踢出!",i_LimitPlayerMinGametime,i_LimitPlayerMaxGametime);
			KickClient(client, "%t", "kickplayerUnqualified", f_LimitPlayerMinGametime, f_LimitPlayerMaxGametime);
			LogKickPlayer(client, 2);
		}
		else
		{
			ChangeClientToSpec(client);
			// colors_print_to_chat_all("{green}[{olive}!{green}]{default}玩家{olive} %N 因游戏时长不符合服务器规则而被强制移动到旁观!", client);
			colors_print_to_chat_all("%t", "forcespecplayerUnqualified", client);
		}
	}
	#if DEBUG
	colors_print_to_chat_all("%d %d %d %N,CheckPlayerGametime is false", i_PlayerTime[client], i_LimitPlayerMinGametime, i_LimitPlayerMaxGametime, client);
	#endif
}
*/
void LimitPlayer(int client)
{
	if (!IsValidClient(client)) return;
	if (!b_Enable || !b_LimitPlayer || i_PlayerTime[client] == 0) return;
#if DEBUG
	PrintToChatAll("%N i_PlayerTime=%d", client, i_PlayerTime[client]);
#endif
	if (i_PlayerTime[client] == -1)
	{
		if (i_Count[client] < i_CheckPlayerGameCount)
		{
			if (!b_LPWRequesting || (b_LPLateload && CheckPluginLate)) return;
			ChangeClientToSpec(client);
			// colors_print_to_chat_all("{green}[{olive}!{green}]{default}因正在获取玩家{olive} %N {default}的真实游戏时长.服务器暂时将其移动到旁观.请等待至成功获取真实游戏时长再加入对局.请求次数%d/%d",client,i_Count[client], i_CheckPlayerGameCount);
			colors_print_to_chat_all("%t", "forcespecplayerRequesting", client, i_Count[client], i_CheckPlayerGameCount);
		}
		else
		{
			// colors_print_to_chat_all("{green}[{olive}!{green}]{default}正在获取玩家{olive} %N {default}的游戏时长,请求次数{2}/{3}", client, client,i_Count[client], i_CheckPlayerGameCount);
			colors_print_to_chat_all("%t", "RequestingPlayerGametime", client, i_Count[client] + 1, i_CheckPlayerGameCount);
		}
	}
	else if (i_PlayerTime[client] == -2)
	{
		if ((i_Count[client] >= i_CheckPlayerGameCount) && (i_LPMWFailureGet != 0))
		{
			if (b_LPLateload && CheckPluginLate) return;
			if (i_LPMWFailureGet == 1)
			{
				// KickClient(client, "你因服务器获取真实游戏时长失败而被自动踢出!");
				KickClient(client, "%t", "kickplayerFailureGet");
				LogKickPlayer(client, 1);
			}
			else if (i_LPMWFailureGet == 2)
			{
				ChangeClientToSpec(client);
				// colors_print_to_chat_all("{green}[{olive}!{green}]{default}玩家{olive} %N 因获取真实游戏时长失败而被强制移动到旁观!", client);
				colors_print_to_chat_all("%t", "forcespecplayerFailureGet", client);
			}
		}
		else if ((i_Count[client] >= i_CheckPlayerGameCount) && (i_LPMWFailureGet == 0))
		{
			// colors_print_to_chat_all("{green}[{olive}!{green}]{default}获取玩家{olive} %N {default}的游戏时长失败", client);
			colors_print_to_chat_all("%t", "FailureGetPlayerGametime", client);
		}
	}
	else if (CheckPlayerGametime(client) && (i_LimitPlayerMode != 0))
	{
#if DEBUG
		PrintToChatAll("Check b_LPLateload && CheckPluginLate: %d&&%d", b_LPLateload, CheckPluginLate);
#endif
		if (b_LPLateload && CheckPluginLate) return;
#if DEBUG
		PrintToChatAll("LimitPlayerMode is %d", i_LimitPlayerMode);
#endif
		if (i_LimitPlayerMode == 1)
		{
			PrintToChatAll("try to kick %N", client);
			float f_LimitPlayerMinGametime = float(i_LimitPlayerMinGametime) / 3600;
			float f_LimitPlayerMaxGametime = float(i_LimitPlayerMaxGametime) / 3600;
			// KickClient(client, "你因游戏时长不符合服务器规则(%.2f - %.2f)而被自动踢出!",i_LimitPlayerMinGametime,i_LimitPlayerMaxGametime);
			KickClient(client, "%t", "kickplayerUnqualified", f_LimitPlayerMinGametime, f_LimitPlayerMaxGametime);
			LogKickPlayer(client, 2);
		}
		else
		{
			PrintToChatAll("try to chance %N team", client);
			ChangeClientToSpec(client);
			// colors_print_to_chat_all("{green}[{olive}!{green}]{default}玩家{olive} %N 因游戏时长不符合服务器规则而被强制移动到旁观!", client);
			colors_print_to_chat_all("%t", "forcespecplayerUnqualified", client);
		}
	}
}

void AnnouncePlayerTime(int client)
{
	if (!b_Enable) return;
	if (i_PlayerTime[client] > 0)
	{
		char g_lerp[64];
		char g_playertime[64];
		if (b_ShowPlayerLerp)
		{
			// FormatEx(g_lerp, sizeof(g_lerp), ", Lerp值为 %.1f", GetPlayerLerp(client) * 1000);
			FormatEx(g_lerp, sizeof(g_lerp), "%t", "showlerp", GetPlayerLerp(client) * 1000);
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i))
				{
					FormatEx(g_lerp, sizeof(g_lerp), "%t", "showlerp", GetPlayerLerp(client) * 1000);
				}
			}
		}
		else FormatEx(g_lerp, sizeof(g_lerp), " ");
		float gametime = float(i_PlayerTime[client]);
		if (i_ShowGametimeMode == 1)
		{
			// FormatEx(g_playertime, sizeof(g_playertime), "{olive} %d{default} 小时{olive} %d{default} 分钟.", i_PlayerTime[client] / 3600, i_PlayerTime[client] / 60 % 60);
			FormatEx(g_playertime, sizeof(g_playertime), "%t", "announcegametimemode1", i_PlayerTime[client] / 3600, i_PlayerTime[client] / 60 % 60);
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i))
				{
					FormatEx(g_playertime, sizeof(g_playertime), "%t", "announcegametimemode1", i_PlayerTime[client] / 3600, i_PlayerTime[client] / 60 % 60);
				}
			}
		}
		else
		{
			// FomatEX(g_playertime, sizeof(g_playertime), "{olive} %.2f {default}小时", gametime / 3600);
			FormatEx(g_playertime, sizeof(g_playertime), "%t", "announcegametimemode2", gametime / 3600);
		}
#if DEBUG
		colors_print_to_chat_all("%N %d %dh%dm %.2fh", client, i_PlayerTime[client], i_PlayerTime[client] / 3600, i_PlayerTime[client] / 60 % 60, gametime / 3600);
#endif
		colors_print_to_chat_all("%t", "announcegametime", client, g_playertime, g_lerp);
	}
	else if ((i_PlayerTime[client] == -1 && i_Count[client] < i_CheckPlayerGameCount))
	{
		// colors_print_to_chat_all("{green}[{olive}!{green}]{default}正在获取玩家{olive} %N {default}的游戏时长,请求次数{2}/{3}", client, client,i_Count[client], i_CheckPlayerGameCount);
		colors_print_to_chat_all("%t", "RequestingPlayerGametime", client, i_Count[client] + 1, i_CheckPlayerGameCount);
	}
	else if ((i_PlayerTime[client] == -2 && i_Count[client] >= i_CheckPlayerGameCount))
	{
		// colors_print_to_chat_all("{green}[{olive}!{green}]{default}获取玩家{olive} %N {default}的游戏时长失败", client);
		colors_print_to_chat_all("%t", "FailureGetPlayerGametime", client);
	}
}

void lateload()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientAuthorized(i) && IsClientInGame(i)) OnClientPostAdminCheck(i);
	}
}
// https://github.com/TouchMe-Inc/l4d2_player_info/blob/main/addons/sourcemod/scripting/player_info.sp#L146
float GetPlayerLerp(int iClient)
{
	char  buffer[32];
	float fLerpRatio, fLerpAmount, fUpdateRate;

	if (GetClientInfo(iClient, "cl_interp_ratio", buffer, sizeof(buffer)))
	{
		fLerpRatio = StringToFloat(buffer);
	}

	if (g_cvMinInterpRatio != null && g_cvMaxInterpRatio != null && GetConVarFloat(g_cvMinInterpRatio) != -1.0)
	{
		fLerpRatio = clamp(fLerpRatio, GetConVarFloat(g_cvMinInterpRatio), GetConVarFloat(g_cvMaxInterpRatio));
	}

	if (GetClientInfo(iClient, "cl_interp", buffer, sizeof(buffer)))
	{
		fLerpAmount = StringToFloat(buffer);
	}

	if (GetClientInfo(iClient, "cl_updaterate", buffer, sizeof(buffer)))
	{
		fUpdateRate = StringToFloat(buffer);
	}

	fUpdateRate = clamp(fUpdateRate, GetConVarFloat(g_cvMinUpdateRate), GetConVarFloat(g_cvMaxUpdateRate));

	return max(fLerpAmount, fLerpRatio / fUpdateRate);
}

float max(float a, float b)
{
	return (a > b) ? a : b;
}

float clamp(float inc, float low, float high)
{
	return (inc > high) ? high : ((inc < low) ? low : inc);
}

void LogKickPlayer(int client, int Mode)
{
	if (b_IfNeedLogKickMsg)
	{
		char Msg[256], Time[32];
		IsCreateLogFile();
		FormatTime(Time, sizeof(Time), "%Y-%m-%d %H:%M:%S", -1);
		char KickMsg[220];
		if (Mode == 1) Format(KickMsg, sizeof(KickMsg), "%N were auto kicked because failed to get playtime!", client);
		else
		{
			float f_LimitPlayerMinGametime = float(i_LimitPlayerMinGametime) / 3600;
			float f_LimitPlayerMaxGametime = float(i_LimitPlayerMaxGametime) / 3600;
			float gametime				   = float(i_PlayerTime[client]) / 3600;
			Format(KickMsg, sizeof(KickMsg), "%N kicked : %.2fh (%.2f h - %.2f h)!", client, gametime, f_LimitPlayerMinGametime, f_LimitPlayerMaxGametime);
		}
		Format(Msg, sizeof(Msg), "[%s] %s", Time, KickMsg);
		IsSaveMessage(Msg);
	}
}

void IsCreateLogFile()
{
	char Date[32], logFile[128];
	FormatTime(Date, sizeof(Date), "%y%m%d", -1);
	Format(logFile, sizeof(logFile), "/logs/GetPlayerGameTime%s.log", Date);
	BuildPath(Path_SM, chatFile, PLATFORM_MAX_PATH, logFile);
}

void IsSaveMessage(const char[] Message)
{
	File fileHandle = OpenFile(chatFile, "a"); /* Append */
	fileHandle.WriteLine(Message);
	delete fileHandle;
}

//thank sorallll
void ChangeClientToSpec(int client)
{
	if (GetClientTeam(client) == 1 && GetBotOfIdlePlayer(client)) L4D_TakeOverBot(client);
	ChangeClientTeam(client, 1);
}

int GetBotOfIdlePlayer(int client) {
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && IsFakeClient(i) && GetClientTeam(i) == 2 && GetIdlePlayerOfBot(i) == client)
			return i;
	}
	return 0;
}

int GetIdlePlayerOfBot(int client) {
	if (!HasEntProp(client, Prop_Send, "m_humanSpectatorUserID"))
		return 0;

	return GetClientOfUserId(GetEntProp(client, Prop_Send, "m_humanSpectatorUserID"));
}

// by litter fory:https://forums.alliedmods.net/member.php?u=311461
void colors_replace(char[] str, int max_len)
{
	static const char color_tag_and_codes[][2][32] = {
		{"{default}",
		  "\x01"},
		{ "{lightgreen}",
		  "\x03"},
		{ "{olive}",
		  "\x04"},
		{ "{green}",
		  "\x05"},
	};
	for (int i = 0; i < sizeof(color_tag_and_codes); i++)
	{
		ReplaceString(str, max_len, color_tag_and_codes[i][0], color_tag_and_codes[i][1]);
	}
}
/*
void colors_print_to_chat(int client, const char[] format, any...)
{
	char buffer[256];
	VFormat(buffer, sizeof(buffer), format, 3);
	colors_replace(buffer, sizeof(buffer));
	PrintToChat(client, "%s", buffer);
}
*/
void colors_print_to_chat_all(const char[] format, any...)
{
	char buffer[256];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			SetGlobalTransTarget(i);
			VFormat(buffer, sizeof(buffer), format, 2);
			colors_replace(buffer, sizeof(buffer));
			PrintToChat(i, "%s", buffer);
		}
	}
}
