#pragma semicolon 1
#pragma newdecls required;
#include <sourcemod>
#include <sdktools>

static char path[256];

ConVar g_hPenalty, g_hThirdperson, g_hWarnings;
int g_iPenalty;
int g_iWarnings[MAXPLAYERS + 1];

int timertick;

public Plugin myinfo =
{
	name = "[L4D] Anti-Cvar Cheat",
	author = "The 9th Survivor",
	description = "Control all ConVars used for cheating",
	version = "1.4",
	url = "N/A"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion engine = GetEngineVersion();
	if (engine == Engine_Left4Dead || engine == Engine_Left4Dead2)
	{
		return APLRes_Success;
	}
	else
	{
		strcopy(error, err_max, "This plugin only runs in \"Left 4 Dead 1 & 2\" game");
		return APLRes_SilentFailure;
	}
}

public void OnPluginStart()
{
	g_hPenalty = CreateConVar("l4d_cheat_penalty_case", "1", "0: record players in log file, 1: kick clients, other value: ban minutes");
	g_hThirdperson = CreateConVar("l4d_cheat_third_enable", "1", "Enable third person check penalty to kicking client");
	g_hWarnings = CreateConVar("l4d_cheat_third_warnig", "10", "How many warnings should plugin warn before kicking client");
	
	g_iPenalty = g_hPenalty.IntValue;
	g_hPenalty.AddChangeHook(ConVarChanged_Cvars);
	
	AddCommandListener(ReportEntities, "report_entities");
	AddCommandListener(ReportTouchlinks, "report_touchlinks");
	AddCommandListener(Reloadresponsesystems, "rr_reloadresponsesystems");
	AddCommandListener(SoundscapeFlush, "soundscape_flush");
	
	BuildPath(Path_SM, path, sizeof(path), "logs/AntiCvarCheat.txt");
	
	CreateTimer(1.0, CheckClients, _, TIMER_REPEAT);
	
	LoadTranslations("anticvarcheat.phrases");
}

void ConVarChanged_Cvars(Handle convar, const char[] oldValue, const char[] newValue)
{
	g_iPenalty = g_hPenalty.IntValue;
}

stock bool IsClientValid(int client)
{
	if (IsClientSourceTV(client) || IsClientReplay(client) || IsFakeClient(client))
	{
		return false;
	}
	return true;
}

public Action CheckClients(Handle timer)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && IsClientValid(client))
		{
			QueryClientConVar(client, "mat_texture_list", ClientQueryCallback);
			QueryClientConVar(client, "mat_queue_mode", ClientQueryCallback_AntiVomit);
			QueryClientConVar(client, "mat_hdr_level", ClientQueryCallback_HDRLevel);
			QueryClientConVar(client, "mat_postprocess_enable", ClientQueryCallback_PostPrecess);
			QueryClientConVar(client, "mat_monitorgamma_tv_enabled", ClientQueryCallback_MonitorGammaTV);
			QueryClientConVar(client, "mat_fullbright", ClientQueryCallback_FullBright);
			QueryClientConVar(client, "mat_wireframe", ClientQueryCallback_WireFrame);
			QueryClientConVar(client, "r_drawothermodels", ClientQueryCallback_DrawModels);
			QueryClientConVar(client, "r_minlightmap", ClientQueryCallback_LightMap);
			QueryClientConVar(client, "l4d_bhop", ClientQueryCallback_l4d_bhop); //ban auto bhop from dll
			QueryClientConVar(client, "l4d_bhop_autostrafe", ClientQueryCallback_l4d_bhop_autostrafe); //ban auto bhop from dll
			QueryClientConVar(client, "cl_fov", ClientQueryCallback_cl_fov);
			QueryClientConVar(client, "sv_cheats", ClientQueryCallback_SvCheats);
			QueryClientConVar(client, "host_timescale", ClientQueryCallback_TimeScale);
			QueryClientConVar(client, "net_fakejitter", ClientQueryCallback_FakeJitter);
			QueryClientConVar(client, "net_fakelag", ClientQueryCallback_FakeLag);
			QueryClientConVar(client, "net_fakeloss", ClientQueryCallback_FakeLoss);
			timertick += 1;
			if (timertick >= 5)
			{
				if (GetClientTeam(client) == 2 || GetClientTeam(client) == 3)
				{
					QueryClientConVar(client, "spec_allowroaming", ClientQueryCallback_AllowRoaming);
					if (g_hThirdperson.BoolValue) //Makes it possible to disable third-person checking on co-op servers
					{
						QueryClientConVar(client, "c_thirdpersonshoulder", ClientQueryCallback_ThirdPerson);
					}
				}
				timertick = 0;
			}
		}
	}	
	return Plugin_Continue;
}

void ClientQueryCallback(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue)
{
	if (!IsClientInGame(client)) return;

	switch (view_as<int>(result))
	{
		case 0:
		{
			int mathax = StringToInt(cvarValue);
			if (mathax > 0)
			{
				static char name[MAX_NAME_LENGTH];
				static char SteamID[32];
				GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID));
				
				LogToFile(path, ".:[Name: %N | STEAMID: %s | r_drawothermodels: %d]:.", client, SteamID, mathax);
				
				if (g_iPenalty == 1)
				{
					PrintToChatAll("\x01[\x05L4D\x01] \x03%s \x01has been kicked for using \x04mathack: mat_texture_list\x01!", name);
					KickClient(client, "ConVar mat_texture_list violation");
				}
				else if (g_iPenalty > 1)
				{
					PrintToChatAll("\x01[\x05L4D\x01] \x03%N \x01has been banned for using \x04mathack: mat_texture_list\x01!", client);
					static char reason[255];
					FormatEx(reason, sizeof(reason), "%s", "Banned for using mat_texture_list violation");

					BanClient(client, g_iPenalty, BANFLAG_AUTHID, reason, reason);
					ServerCommand("sm_exbanid %d \"%s\"", g_iPenalty, SteamID);
				}

			}
		}
		case 1:
		{
			KickClient(client, "ConVarQuery_NotFound");
		}
		case 2:
		{
			KickClient(client, "ConVarQuery_NotValid");
		}
		case 3:
		{
			KickClient(client, "ConVarQuery_Protected");
		}
	}
}

void ClientQueryCallback_DrawModels(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue)
{	
	if (!IsClientInGame(client)) return;

	int clientCvarValue = StringToInt(cvarValue);

	if (clientCvarValue != 1)
	{
		static char name[MAX_NAME_LENGTH];
		GetClientName(client, name, MAX_NAME_LENGTH);

		static char SteamID[32];
		GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID));

		LogToFile(path, ".:[Name: %N | STEAMID: %s | r_drawothermodels: %d]:.", client, SteamID, clientCvarValue);

		if (g_iPenalty == 1)
		{
			PrintToChatAll("\x01[\x05L4D\x01] \x03%s \x01has been kicked for using \x04mathack: r_drawothermodels\x01!", name);
			KickClient(client, "ConVar r_drawothermodels violation");
		}
		else if (g_iPenalty > 1)
		{
			PrintToChatAll("\x01[\x05L4D\x01] \x03%N \x01has been banned for using \x04mathack: r_drawothermodels\x01!", client);
			static char reason[255];
			FormatEx(reason, sizeof(reason), "%s", "Banned for using r_drawothermodels violation");
			
			BanClient(client, g_iPenalty, BANFLAG_AUTHID, reason, reason);
			ServerCommand("sm_exbanid %d \"%s\"", g_iPenalty, SteamID);
		}
	}
}

void ClientQueryCallback_LightMap(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue)
{	
	if (!IsClientInGame(client)) return;

	int clientCvarValue = StringToInt(cvarValue);

	if (clientCvarValue != 0)
	{
		static char name[MAX_NAME_LENGTH];
		GetClientName(client, name, MAX_NAME_LENGTH);

		static char SteamID[32];
		GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID));

		LogToFile(path, ".:[Name: %N | STEAMID: %s | r_minlightmap: %d]:.", client, SteamID, clientCvarValue);

		if (g_iPenalty == 1)
		{
			PrintToChatAll("\x01[\x05L4D\x01] \x03%s \x01has been kicked for using \x04lightmaphack: r_minlightmap\x01!", name);
			KickClient(client, "ConVar r_minlightmap violation");
		}
		else if (g_iPenalty > 1)
		{
			PrintToChatAll("\x01[\x05L4D\x01] \x03%N \x01has been banned for using \x04lightmaphack: r_minlightmap\x01!", client);
			static char reason[255];
			FormatEx(reason, sizeof(reason), "%s", "Banned for using r_minlightmap violation");
			
			BanClient(client, g_iPenalty, BANFLAG_AUTHID, reason, reason);
			ServerCommand("sm_exbanid %d \"%s\"", g_iPenalty, SteamID);
		}
	}
}

void ClientQueryCallback_PostPrecess(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue)
{	
	if (!IsClientInGame(client)) return;

	int clientCvarValue = StringToInt(cvarValue);

	if (clientCvarValue != 1)
	{
		static char name[MAX_NAME_LENGTH];
		GetClientName(client, name, MAX_NAME_LENGTH);

		static char SteamID[32];
		GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID));

		LogToFile(path, ".:[Name: %N | STEAMID: %s | mat_postprocess_enable: %d]:.", client, SteamID, clientCvarValue);

		if (g_iPenalty == 1)
		{
			PrintToChatAll("\x01[\x05L4D\x01] \x03%N \x01has been kicked for using \x04mathack: mat_postprocess_enable\x01!", client);
			KickClient(client, "ConVar mat_postprocess_enable violation");
		}
		else if (g_iPenalty > 1)
		{
			PrintToChatAll("\x01[\x05L4D\x01] \x03%N \x01has been banned for using \x04mathack: mat_postprocess_enable\x01!", client);
			static char reason[255];
			FormatEx(reason, sizeof(reason), "%s", "Banned for using mat_postprocess_enable violation");
			
			BanClient(client, g_iPenalty, BANFLAG_AUTHID, reason, reason);
			ServerCommand("sm_exbanid %d \"%s\"", g_iPenalty, SteamID);
		}
	}
}

void ClientQueryCallback_MonitorGammaTV(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue)
{	
	if (!IsClientInGame(client)) return;

	int clientCvarValue = StringToInt(cvarValue);

	if (clientCvarValue != 0)
	{
		static char name[MAX_NAME_LENGTH];
		GetClientName(client, name, MAX_NAME_LENGTH);

		static char SteamID[32];
		GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID));

		LogToFile(path, ".:[Name: %N | STEAMID: %s | mat_monitorgamma_tv_enabled: %d]:.", client, SteamID, clientCvarValue);

		if (g_iPenalty == 1)
		{
			PrintToChatAll("\x01[\x05L4D\x01] \x03%N \x01has been kicked for using \x04mathack: mat_monitorgamma_tv_enabled\x01!", client);
			KickClient(client, "ConVar mat_monitorgamma_tv_enabled violation");
		}
		else if (g_iPenalty > 1)
		{
			PrintToChatAll("\x01[\x05L4D\x01] \x03%N \x01has been banned for using \x04mathack: mat_monitorgamma_tv_enabled\x01!", client);
			static char reason[255];
			FormatEx(reason, sizeof(reason), "%s", "Banned for using mat_monitorgamma_tv_enabled violation");
			
			BanClient(client, g_iPenalty, BANFLAG_AUTHID, reason, reason);
			ServerCommand("sm_exbanid %d \"%s\"", g_iPenalty, SteamID);
		}
	}
}

void ClientQueryCallback_FullBright(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue)
{	
	if (!IsClientInGame(client)) return;

	int clientCvarValue = StringToInt(cvarValue);

	if (clientCvarValue != 0)
	{
		static char name[MAX_NAME_LENGTH];
		GetClientName(client, name, MAX_NAME_LENGTH);

		static char SteamID[32];
		GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID));

		LogToFile(path, ".:[Name: %N | STEAMID: %s | mat_fullbright: %d]:.", client, SteamID, clientCvarValue);

		if (g_iPenalty == 1)
		{
			PrintToChatAll("\x01[\x05L4D\x01] \x03%N \x01has been kicked for using \x04mathack: mat_fullbright\x01!", client);
			KickClient(client, "ConVar mat_fullbright violation");
		}
		else if (g_iPenalty > 1)
		{
			PrintToChatAll("\x01[\x05L4D\x01] \x03%N \x01has been banned for using \x04mathack: mat_fullbright\x01!", client);
			static char reason[255];
			FormatEx(reason, sizeof(reason), "%s", "Banned for using mat_fullbright violation");
			
			BanClient(client, g_iPenalty, BANFLAG_AUTHID, reason, reason);
			ServerCommand("sm_exbanid %d \"%s\"", g_iPenalty, SteamID);
		}
	}
}

void ClientQueryCallback_WireFrame(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue)
{	
	if (!IsClientInGame(client)) return;

	int clientCvarValue = StringToInt(cvarValue);

	if (clientCvarValue != 0)
	{
		static char name[MAX_NAME_LENGTH];
		GetClientName(client, name, MAX_NAME_LENGTH);

		static char SteamID[32];
		GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID));

		LogToFile(path, ".:[Name: %N | STEAMID: %s | mat_wireframe: %d]:.", client, SteamID, clientCvarValue);

		if (g_iPenalty == 1)
		{
			PrintToChatAll("\x01[\x05L4D\x01] \x03%N \x01has been kicked for using \x04mathack: mat_wireframe\x01!", client);
			KickClient(client, "ConVar mat_wireframe violation");
		}
		else if (g_iPenalty > 1)
		{
			PrintToChatAll("\x01[\x05L4D\x01] \x03%N \x01has been banned for using \x04mathack: mat_wireframe\x01!", client);
			static char reason[255];
			FormatEx(reason, sizeof(reason), "%s", "Banned for using mat_wireframe violation");
			
			BanClient(client, g_iPenalty, BANFLAG_AUTHID, reason, reason);
			ServerCommand("sm_exbanid %d \"%s\"", g_iPenalty, SteamID);
		}
	}
}

void ClientQueryCallback_AntiVomit(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue)
{	
	if (!IsClientInGame(client)) return;

	int clientCvarValue = StringToInt(cvarValue);

	if (clientCvarValue >= 3)
	{
		static char name[MAX_NAME_LENGTH];
		GetClientName(client, name, MAX_NAME_LENGTH);

		static char SteamID[32];
		GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID));
	
		LogToFile(path, ".:[Name: %N | STEAMID: %s | mat_queue_mode: %d]:.", client, SteamID, clientCvarValue);

		if (g_iPenalty == 1)
		{
			PrintToChatAll("\x01[\x05L4D\x01] \x03%N \x01has been kicked for using \x04mathack: mat_queue_mode\x01!", client);
			KickClient(client, "ConVar mat_queue_mode violation");
		}
		else if (g_iPenalty > 1)
		{
			PrintToChatAll("\x01[\x05L4D\x01] \x03%N \x01has been banned for using \x04mathack: mat_queue_mode\x01!", client);
			static char reason[255];
			FormatEx(reason, sizeof(reason), "%s", "Banned for using mat_queue_mode violation");
			
			BanClient(client, g_iPenalty, BANFLAG_AUTHID, reason, reason);
			ServerCommand("sm_exbanid %d \"%s\"", g_iPenalty, SteamID);
		}
	}
}

void ClientQueryCallback_HDRLevel(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue)
{	
	if (!IsClientInGame(client)) return;

	int clientCvarValue = StringToInt(cvarValue);

	if (clientCvarValue != 2)
	{
		static char name[MAX_NAME_LENGTH];
		GetClientName(client, name, MAX_NAME_LENGTH);

		static char SteamID[32];
		GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID));
	
		LogToFile(path, ".:[Name: %N | STEAMID: %s | mat_hdr_level: %d]:.", client, SteamID, clientCvarValue);

		if (g_iPenalty == 1)
		{
			PrintToChatAll("\x01[\x05L4D\x01] \x03%N \x01has been kicked for using \x04mathack: mat_hdr_level\x01!", client);
			KickClient(client, "ConVar mat_hdr_level violation");
		}
		else if (g_iPenalty > 1)
		{
			PrintToChatAll("\x01[\x05L4D\x01] \x03%N \x01has been banned for using \x04mathack: mat_hdr_level\x01!", client);
			static char reason[255];
			FormatEx(reason, sizeof(reason), "%s", "Banned for using mat_hdr_level violation");
			
			BanClient(client, g_iPenalty, BANFLAG_AUTHID, reason, reason);
			ServerCommand("sm_exbanid %d \"%s\"", g_iPenalty, SteamID);
		}
	}
}

void ClientQueryCallback_l4d_bhop(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue)
{	
	if (!IsClientInGame(client)) return;

	int clientCvarValue = StringToInt(cvarValue);

	if (clientCvarValue > 0)
	{
		static char name[MAX_NAME_LENGTH];
		GetClientName(client, name, MAX_NAME_LENGTH);
		
		static char SteamID[32];
		GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID));
	
		LogToFile(path, ".:[Name: %N | STEAMID: %s | l4d_bhop: %d]:.", client, SteamID, clientCvarValue);

		if (g_iPenalty == 1)
		{
			PrintToChatAll("\x01[\x05L4D\x01] \x03%N \x01has been kicked for using \x04l4dbhop.dll: l4d_bhop\x01!", client);
			KickClient(client, "ConVar l4d_bhop violation");
		}
		else if (g_iPenalty > 1)
		{
			PrintToChatAll("\x01[\x05L4D\x01] \x03%N \x01has been banned for using \x04l4dbhop.dll: l4d_bhop\x01!", client);
			static char reason[255];
			FormatEx(reason, sizeof(reason), "%s", "Banned for using l4dbhop.dll");
			
			BanClient(client, g_iPenalty, BANFLAG_AUTHID, reason, reason);
			ServerCommand("sm_exbanid %d \"%s\"", g_iPenalty, SteamID);
		}
	}
}

void ClientQueryCallback_l4d_bhop_autostrafe(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue)
{	
	if (!IsClientInGame(client)) return;

	int clientCvarValue = StringToInt(cvarValue);

	if (clientCvarValue > 0)
	{
		static char name[MAX_NAME_LENGTH];
		GetClientName(client, name, MAX_NAME_LENGTH);

		static char SteamID[32];
		GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID));
	
		LogToFile(path, ".:[Name: %N | STEAMID: %s | l4d_bhop: %d]:.", client, SteamID, clientCvarValue);

		if (g_iPenalty == 1)
		{
			PrintToChatAll("\x01[\x05L4D\x01] \x03%N \x01has been kicked for using \x04l4dbhop.dll: l4d_bhop_autostrafe\x01!", client);
			KickClient(client, "ConVar l4d_bhop_autostrafe violation");
		}
		else if (g_iPenalty > 1)
		{
			PrintToChatAll("\x01[\x05L4D\x01] \x03%N \x01has been banned for using \x04l4dbhop.dll: l4d_bhop_autostrafe\x01!", client);
			static char reason[255];
			FormatEx(reason, sizeof(reason), "%s", "Banned for using l4dbhop.dll");
			
			BanClient(client, g_iPenalty, BANFLAG_AUTHID, reason, reason);
			ServerCommand("sm_exbanid %d \"%s\"", g_iPenalty, SteamID);
		}
	}
}

void ClientQueryCallback_cl_fov(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue)
{	
	if (!IsClientInGame(client)) return;

	int clientCvarValue = StringToInt(cvarValue);

	if (clientCvarValue > 120 || clientCvarValue < 75)
	{
		static char name[MAX_NAME_LENGTH];
		GetClientName(client, name, MAX_NAME_LENGTH);
		
		static char SteamID[32];
		GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID));
	
		LogToFile(path, ".:[Name: %N | STEAMID: %s | cl_fov: %d]:.", client, SteamID, clientCvarValue);

		if (g_iPenalty == 1)
		{
			PrintToChatAll("\x01[\x05L4D\x01] \x03%N \x01has been kicked for using \x04cl_fov %d\x01!", client, clientCvarValue);
			KickClient(client, "ConVar cl_fov violation (must be 75~120)");
		}
		else if (g_iPenalty > 1)
		{
			PrintToChatAll("\x01[\x05L4D\x01] \x03%N \x01has been banned for using \x04cl_fov %d\x01!", client, clientCvarValue);
			static char reason[255];
			FormatEx(reason, sizeof(reason), "%s", "Banned for using cl_fov %d (must be 75~120)", clientCvarValue);
			
			BanClient(client, g_iPenalty, BANFLAG_AUTHID, reason, reason);
			ServerCommand("sm_exbanid %d \"%s\"", g_iPenalty, SteamID);
		}
	}
}

void ClientQueryCallback_SvCheats(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue)
{	
	if (!IsClientInGame(client)) return;

	int clientCvarValue = StringToInt(cvarValue);

	if (clientCvarValue != 0)
	{
		static char name[MAX_NAME_LENGTH];
		GetClientName(client, name, MAX_NAME_LENGTH);

		static char SteamID[32];
		GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID));

		LogToFile(path, ".:[Name: %N | STEAMID: %s | sv_cheats: %d]:.", client, SteamID, clientCvarValue);

		if (g_iPenalty == 1)
		{
			PrintToChatAll("\x01[\x05L4D\x01] \x03%s \x01has been kicked for using \x04svcheatshack: sv_cheats\x01!", name);
			KickClient(client, "ConVar sv_cheats violation");
		}
		else if (g_iPenalty > 1)
		{
			PrintToChatAll("\x01[\x05L4D\x01] \x03%N \x01has been banned for using \x04svcheatshack: sv_cheats\x01!", client);
			static char reason[255];
			FormatEx(reason, sizeof(reason), "%s", "Banned for using sv_cheats violation");
			
			BanClient(client, g_iPenalty, BANFLAG_AUTHID, reason, reason);
			ServerCommand("sm_exbanid %d \"%s\"", g_iPenalty, SteamID);
		}
	}
}

void ClientQueryCallback_TimeScale(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue)
{	
	if (!IsClientInGame(client)) return;

	int clientCvarValue = StringToInt(cvarValue);

	if (clientCvarValue != 1)
	{
		static char name[MAX_NAME_LENGTH];
		GetClientName(client, name, MAX_NAME_LENGTH);

		static char SteamID[32];
		GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID));

		LogToFile(path, ".:[Name: %N | STEAMID: %s | host_timescale: %d]:.", client, SteamID, clientCvarValue);

		if (g_iPenalty == 1)
		{
			PrintToChatAll("\x01[\x05L4D\x01] \x03%s \x01has been kicked for using \x04speedhack: host_timescale\x01!", name);
			KickClient(client, "ConVar host_timescale violation");
		}
		else if (g_iPenalty > 1)
		{
			PrintToChatAll("\x01[\x05L4D\x01] \x03%N \x01has been banned for using \x04speedhack: host_timescale\x01!", client);
			static char reason[255];
			FormatEx(reason, sizeof(reason), "%s", "Banned for using host_timescale violation");
			
			BanClient(client, g_iPenalty, BANFLAG_AUTHID, reason, reason);
			ServerCommand("sm_exbanid %d \"%s\"", g_iPenalty, SteamID);
		}
	}
}

void ClientQueryCallback_FakeJitter(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue)
{	
	if (!IsClientInGame(client)) return;

	int clientCvarValue = StringToInt(cvarValue);

	if (clientCvarValue != 0)
	{
		static char name[MAX_NAME_LENGTH];
		GetClientName(client, name, MAX_NAME_LENGTH);

		static char SteamID[32];
		GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID));

		LogToFile(path, ".:[Name: %N | STEAMID: %s | net_fakejitter: %d]:.", client, SteamID, clientCvarValue);

		if (g_iPenalty == 1)
		{
			PrintToChatAll("\x01[\x05L4D\x01] \x03%s \x01has been kicked for using \x04nethack: net_fakejitter\x01!", name);
			KickClient(client, "ConVar net_fakejitter violation");
		}
		else if (g_iPenalty > 1)
		{
			PrintToChatAll("\x01[\x05L4D\x01] \x03%N \x01has been banned for using \x04nethack: net_fakejitter\x01!", client);
			static char reason[255];
			FormatEx(reason, sizeof(reason), "%s", "Banned for using net_fakejitter violation");
			
			BanClient(client, g_iPenalty, BANFLAG_AUTHID, reason, reason);
			ServerCommand("sm_exbanid %d \"%s\"", g_iPenalty, SteamID);
		}
	}
}

void ClientQueryCallback_FakeLag(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue)
{	
	if (!IsClientInGame(client)) return;

	int clientCvarValue = StringToInt(cvarValue);

	if (clientCvarValue != 0)
	{
		static char name[MAX_NAME_LENGTH];
		GetClientName(client, name, MAX_NAME_LENGTH);

		static char SteamID[32];
		GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID));

		LogToFile(path, ".:[Name: %N | STEAMID: %s | net_fakejitter: %d]:.", client, SteamID, clientCvarValue);

		if (g_iPenalty == 1)
		{
			PrintToChatAll("\x01[\x05L4D\x01] \x03%s \x01has been kicked for using \x04nethack: net_fakejitter\x01!", name);
			KickClient(client, "ConVar net_fakejitter violation");
		}
		else if (g_iPenalty > 1)
		{
			PrintToChatAll("\x01[\x05L4D\x01] \x03%N \x01has been banned for using \x04nethack: net_fakejitter\x01!", client);
			static char reason[255];
			FormatEx(reason, sizeof(reason), "%s", "Banned for using net_fakejitter violation");
			
			BanClient(client, g_iPenalty, BANFLAG_AUTHID, reason, reason);
			ServerCommand("sm_exbanid %d \"%s\"", g_iPenalty, SteamID);
		}
	}
}

void ClientQueryCallback_FakeLoss(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue)
{	
	if (!IsClientInGame(client)) return;

	int clientCvarValue = StringToInt(cvarValue);

	if (clientCvarValue != 0)
	{
		static char name[MAX_NAME_LENGTH];
		GetClientName(client, name, MAX_NAME_LENGTH);

		static char SteamID[32];
		GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID));

		LogToFile(path, ".:[Name: %N | STEAMID: %s | net_fakejitter: %d]:.", client, SteamID, clientCvarValue);

		if (g_iPenalty == 1)
		{
			PrintToChatAll("\x01[\x05L4D\x01] \x03%s \x01has been kicked for using \x04nethack: net_fakejitter\x01!", name);
			KickClient(client, "ConVar net_fakejitter violation");
		}
		else if (g_iPenalty > 1)
		{
			PrintToChatAll("\x01[\x05L4D\x01] \x03%N \x01has been banned for using \x04nethack: net_fakejitter\x01!", client);
			static char reason[255];
			FormatEx(reason, sizeof(reason), "%s", "Banned for using net_fakejitter violation");
			
			BanClient(client, g_iPenalty, BANFLAG_AUTHID, reason, reason);
			ServerCommand("sm_exbanid %d \"%s\"", g_iPenalty, SteamID);
		}
	}
}

void ClientQueryCallback_ThirdPerson(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue)
{	
	if (!IsClientInGame(client)) return;

	int clientCvarValue = StringToInt(cvarValue);

	if (clientCvarValue != 0)
	{
		PrintToChat(client, "%t", "thirdperson_warning");
		g_iWarnings[client] += 1;
		if (g_iWarnings[client] >= GetConVarInt(g_hWarnings))
		{
			g_iWarnings[client] = 0;
			static char name[MAX_NAME_LENGTH];
			GetClientName(client, name, MAX_NAME_LENGTH);

			static char SteamID[32];
			GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID));

			LogToFile(path, ".:[Name: %N | STEAMID: %s | c_thirdpersonshoulder: %d]:.", client, SteamID, clientCvarValue);

			if (g_iPenalty == 1)
			{
				PrintToChatAll("\x01[\x05L4D\x01] \x03%s \x01has been kicked for using \x04thirdpersonhack: c_thirdpersonshoulder\x01!", name);
				KickClient(client, "ConVar c_thirdpersonshoulder violation");
			}
			else if (g_iPenalty > 1)
			{
				PrintToChatAll("\x01[\x05L4D\x01] \x03%N \x01has been banned for using \x04thirdpersonhack: c_thirdpersonshoulder\x01!", client);
				static char reason[255];
				FormatEx(reason, sizeof(reason), "%s", "Banned for using c_thirdpersonshoulder violation");
				
				BanClient(client, g_iPenalty, BANFLAG_AUTHID, reason, reason);
				ServerCommand("sm_exbanid %d \"%s\"", g_iPenalty, SteamID);
			}
		}
	}
}

void ClientQueryCallback_AllowRoaming(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue)
{	
	if (!IsClientInGame(client)) return;

	int clientCvarValue = StringToInt(cvarValue);

	if (clientCvarValue != 0)
	{
		PrintToChat(client, "%t", "allowroaming_warning");
		g_iWarnings[client] += 1;
		if (g_iWarnings[client] >= GetConVarInt(g_hWarnings))
		{
			g_iWarnings[client] = 0;
			static char name[MAX_NAME_LENGTH];
			GetClientName(client, name, MAX_NAME_LENGTH);

			static char SteamID[32];
			GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID));

			LogToFile(path, ".:[Name: %N | STEAMID: %s | spec_allowroaming: %d]:.", client, SteamID, clientCvarValue);

			if (g_iPenalty == 1)
			{
				PrintToChatAll("\x01[\x05L4D\x01] \x03%s \x01has been kicked for using \x04roaminghack: spec_allowroaming\x01!", name);
				KickClient(client, "ConVar spec_allowroaming violation");
			}
			else if (g_iPenalty > 1)
			{
				PrintToChatAll("\x01[\x05L4D\x01] \x03%N \x01has been banned for using \x04roaminghack: spec_allowroaming\x01!", client);
				static char reason[255];
				FormatEx(reason, sizeof(reason), "%s", "Banned for using spec_allowroaming violation");
				
				BanClient(client, g_iPenalty, BANFLAG_AUTHID, reason, reason);
				ServerCommand("sm_exbanid %d \"%s\"", g_iPenalty, SteamID);
			}
		}
	}
}

public Action ReportEntities(int client, const char[] command, int args)
{	
	if (client > 0 && IsClientInGame(client))
	{
		static char name[MAX_NAME_LENGTH];
		GetClientName(client, name, MAX_NAME_LENGTH);
		
		static char SteamID[32];
		GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID));
		
		LogToFile(path, ".:[Name: %N | STEAMID: %s | report_entities: Attempt to saturate the server]:.", client, SteamID);
		
		PrintToChatAll("\x01[\x05L4D\x01] \x03%s \x01has been kicked for trying \x04saturate the server\x01!", name);
		KickClient(client, "Attempt to saturate the server");
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action ReportTouchlinks(int client, const char[] command, int args)
{	
	if (client > 0 && IsClientInGame(client))
	{
		static char name[MAX_NAME_LENGTH];
		GetClientName(client, name, MAX_NAME_LENGTH);
		
		static char SteamID[32];
		GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID));
		
		LogToFile(path, ".:[Name: %N | STEAMID: %s | report_touchlinks: Attempt to saturate the server]:.", client, SteamID);
		
		PrintToChatAll("\x01[\x05L4D\x01] \x03%s \x01has been kicked for trying \x04saturate the server\x01!", name);
		KickClient(client, "Attempt to saturate the server");
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action Reloadresponsesystems(int client, const char[] command, int args)
{	
	if (client > 0 && IsClientInGame(client))
	{
		static char name[MAX_NAME_LENGTH];
		GetClientName(client, name, MAX_NAME_LENGTH);
		
		static char SteamID[32];
		GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID));
		
		LogToFile(path, ".:[Name: %N | STEAMID: %s | rr_reloadresponsesystems: Attempt to saturate the server]:.", client, SteamID);
		
		PrintToChatAll("\x01[\x05L4D\x01] \x03%s \x01has been kicked for trying \x04saturate the server\x01!", name);
		KickClient(client, "Attempt to saturate the server");
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action SoundscapeFlush(int client, const char[] command, int args)
{	
	if (client > 0 && IsClientInGame(client))
	{
		static char name[MAX_NAME_LENGTH];
		GetClientName(client, name, MAX_NAME_LENGTH);
		
		static char SteamID[32];
		GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID));
		
		LogToFile(path, ".:[Name: %N | STEAMID: %s | soundscape_flush: Attempt to saturate the server]:.", client, SteamID);
		
		PrintToChatAll("\x01[\x05L4D\x01] \x03%s \x01has been kicked for trying \x04saturate the server\x01!", name);
		KickClient(client, "Attempt to saturate the server");
		return Plugin_Handled;
	}
	return Plugin_Continue;
}