/************************************************************************************************************

Settings file autocreated in : cfg/sourcemod/BotsManager.cfg
Файл настроек автоматически сгенерируется, если его не существует по адресу : cfg/sourcemod/BotsManager.cfg

главное меню : !bpl - в чате, или bpl в консоле, или в админке > управление сервером > БОТЫ
main menu : !bpl - in chat, or bpl in console, or in admin menu > management server > BOTS

все дефолтные ники ботов меняются в файле botsprofile.db!
all bots nicknames you may changed on file botsprofile.db!

etc...

***********************************************************************************************************/

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <topmenus>
#define PLUGIN_VERSION "5.0"
#undef REQUIRE_PLUGIN
#include <adminmenu>

//максимальная длина префикса. (по умолчанию полностью имя может содержать 31 символ)
//maximum length of the prefix. (by default completely name can contain 31 symbols)
#define MAX_PREFIX_LEN	20

//teams. DONT CHANGE!
#define BOT_TEAM_TR		2
#define BOT_TEAM_CT		3

new	g_HealthOffset = -1;
new	g_ArmorOffset = -1;
new	g_HelmOffset = -1;
new	g_LifeOffset = -1;
new	g_PingOffset = -1;
new	g_GameManagerOffset = -1;
new	Handle:hTopMenu = INVALID_HANDLE;
new	Handle:g_CvarHumRespHp = INVALID_HANDLE;
new	Handle:g_CvarHumRespArmr = INVALID_HANDLE;
new	Handle:g_CvarHumRespHelmet = INVALID_HANDLE;
new	Handle:g_CvarBotRespHp = INVALID_HANDLE;
new	Handle:g_CvarBotRespArmr = INVALID_HANDLE;
new	Handle:g_CvarBotRespHelmet = INVALID_HANDLE;
new	Handle:g_CvarBotPingEnable = INVALID_HANDLE;
new	Handle:g_CvarBotPingMinimum = INVALID_HANDLE;
new	Handle:g_CvarBotPingMaximum = INVALID_HANDLE;
new	Handle:g_CvarBotPingInterval = INVALID_HANDLE;
new	Handle:g_CvarAutoKill = INVALID_HANDLE;
new	Handle:g_CvarPrefixCT = INVALID_HANDLE;
new	Handle:g_CvarPrefixTR = INVALID_HANDLE;
new	Handle:g_CvarPrefixEnable = INVALID_HANDLE;
new Handle:g_CvarAutoKillBombPlanted = INVALID_HANDLE;
new Handle:g_CvarAutoKillDelay = INVALID_HANDLE;
new bool:g_CTItemSelected = false;
new bool:g_TRItemSelected = false;
new bool:g_CTNamesDefault = true;
new bool:g_TRNamesDefault = true;
new g_CTPrefixLen;
new g_TRPrefixLen;
new	Handle:g_CvarDifficulty = INVALID_HANDLE;
new	Handle:g_CvarAllowMGS = INVALID_HANDLE;
new	Handle:g_CvarAllowPistols = INVALID_HANDLE;
new	Handle:g_CvarAllowRifles = INVALID_HANDLE;
new	Handle:g_CvarAllowShotguns = INVALID_HANDLE;
new	Handle:g_CvarAllowSMGS = INVALID_HANDLE;
new	Handle:g_CvarAllowSnipers = INVALID_HANDLE;
new	Handle:g_CvarAllowGrenades = INVALID_HANDLE;
new	Handle:g_CvarChat = INVALID_HANDLE;
new	Handle:g_CvarBalance = INVALID_HANDLE;
new	g_MaxClients;
new	Float:g_Timer = 0.0;
new Float:g_AutoKillDelayMax = 9.0;
new g_CurrnetCtModel = -1;
new g_CurrnetTrModel = -1;
new bool:g_BombPlanted = false;
new g_iBotCt = 0;
new g_iBotTr = 0;
static const String:CtModels[4][] = {"models/player/ct_urban.mdl", "models/player/ct_gsg9.mdl", "models/player/ct_sas.mdl", "models/player/ct_gign.mdl"};
static const String:TrModels[4][] = {"models/player/t_phoenix.mdl", "models/player/t_leet.mdl", "models/player/t_arctic.mdl", "models/player/t_guerilla.mdl"};

public Plugin:myinfo = 
{
	name = "BotsManager",
	author = "t*Q",
	description = "Counter-Strike Source Bots Manager and extra settings",
	version = PLUGIN_VERSION,
	url = "www.hlmod.ru"
};

public OnPluginStart()
{
	LoadTranslations("plugin.BotsManager");

	RegAdminCmd("bm", BotsMenu_show, ADMFLAG_CONVARS, "BotsManager Меню | BotsManager Menu");
	RegConsoleCmd("say_team", SayTeamCmd);
	RegConsoleCmd("say", SayCmd);

	CreateConVar("bm_version", PLUGIN_VERSION, "Bots plugin version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	g_CvarPrefixCT = CreateConVar("bm_prefix_ct", "t*Q [CT] | ", "Префикс ботов [КТ] <...>|[CT] bots prefix <...>", ADMFLAG_CONVARS);

	g_CvarPrefixTR = CreateConVar("bm_prefix_t", "t*Q [T] | ", "Префикс ботов [Т] <...>|[T] bots prefix <...>", ADMFLAG_CONVARS);

	g_CvarPrefixEnable = CreateConVar("bm_prefix_enable", "0", "Вкл/Выкл префикс ботов <1|0>|Enable/disable bots prefix <1|0>", ADMFLAG_CONVARS);

	g_CvarBotPingEnable = CreateConVar("bm_ping_enable", "1", "Включить/Выключить пинг Ботов <1|0>|oN/oFF Bots Ping <1|0>", ADMFLAG_CONVARS);

	g_CvarBotPingMinimum = CreateConVar("bm_ping_min", "50", "Минимальный пинг Ботов <...>|Minimal Bots Ping <...>", ADMFLAG_CONVARS);

	g_CvarBotPingMaximum = CreateConVar("bm_ping_max", "95", "Максимальный пинг Ботов <...>|Maximal Bots Ping <...>", ADMFLAG_CONVARS);

	g_CvarBotPingInterval = CreateConVar("bm_ping_interval", "4", "Интервал в секундах между сменой пинга <...>|Interval Changed Bots ping (sec) <...>", ADMFLAG_CONVARS);

	g_CvarBotRespHp = CreateConVar("bm_bots_health", "100", "Количество хп у Ботов (на каждом респе)<...>|Bots Health amount on spawn <...>", ADMFLAG_CONVARS);

	g_CvarBotRespArmr = CreateConVar("bm_bots_armr", "100", "Количество Брони у Ботов (при покупке) <...>|Bots Armour amount (on buying) <...>", ADMFLAG_CONVARS);

	g_CvarBotRespHelmet = CreateConVar("bm_bots_helmet", "1", "Запретить|Разрешить Ботам шлем (при покупке) <1|0>|Enable|Disable Bots helmet (on buying) <1|0>", ADMFLAG_CONVARS);
	g_CvarHumRespHp = CreateConVar("bm_humans_health", "100", "Количество хп у людей (на каждом респе)|Humans Health amount on spawn <...>", ADMFLAG_CONVARS);

	g_CvarHumRespArmr = CreateConVar("bm_humans_armr", "100", "Количество Брони у людей (при покупке) <...>|Humans Armour amount (on buying) <...>", ADMFLAG_CONVARS);

	g_CvarHumRespHelmet= CreateConVar("bm_humans_helmet", "1", "Запретить|Разрешить Людям шлем (при покупке)<1|0>|Enable|Disable Humans helmet (on buying)<1|0>", ADMFLAG_CONVARS);
	g_CvarAutoKill = CreateConVar("bm_autokill", "1", "Убивать Ботов если все люди убиты? <1|0>|Auto Kill Bots if all humans died? <1|0>", ADMFLAG_CONVARS);
	
	g_CvarAutoKillBombPlanted = CreateConVar("bm_autokill_bomb_planted", "0", "Убивать Ботов если установлена бомба? <1|0>|Auto Kill Bots if bomb planted? <1|0>", ADMFLAG_CONVARS);

	g_CvarAutoKillDelay = CreateConVar("bm_autokill_delay", "2.0", "задержка в секундах, перед тем как убить ботов (min 0.5 | max 9.0) <...>|Bots Auto Kill delay <...> (min 0.5 | max 9.0)", ADMFLAG_CONVARS);

	HookConVarChange(g_CvarAutoKill, OnSettingChanged);
	HookConVarChange(g_CvarHumRespHelmet, OnSettingChanged);
	HookConVarChange(g_CvarHumRespArmr, OnSettingChanged);
	HookConVarChange(g_CvarHumRespHp, OnSettingChanged);
	HookConVarChange(g_CvarBotRespHelmet, OnSettingChanged);
	HookConVarChange(g_CvarBotRespArmr, OnSettingChanged);
	HookConVarChange(g_CvarBotRespHp, OnSettingChanged);
	HookConVarChange(g_CvarBotPingInterval, OnSettingChanged);
	HookConVarChange(g_CvarBotPingMaximum, OnSettingChanged);
	HookConVarChange(g_CvarBotPingMinimum, OnSettingChanged);
	HookConVarChange(g_CvarBotPingEnable, OnSettingChanged);
	HookConVarChange(g_CvarPrefixEnable, OnSettingChanged);
	HookConVarChange(g_CvarPrefixTR, OnSettingChanged);
	HookConVarChange(g_CvarPrefixCT, OnSettingChanged);

	g_CvarDifficulty = FindConVar("bot_difficulty");
	g_CvarChat = FindConVar("bot_chatter");
	g_CvarAllowMGS = FindConVar("bot_allow_machine_guns");
	g_CvarAllowPistols = FindConVar("bot_allow_pistols");
	g_CvarAllowRifles = FindConVar("bot_allow_rifles");
	g_CvarAllowShotguns = FindConVar("bot_allow_shotguns");
	g_CvarAllowSMGS = FindConVar("bot_allow_sub_machine_guns");
	g_CvarAllowSnipers = FindConVar("bot_allow_snipers");
	g_CvarAllowGrenades = FindConVar("bot_allow_grenades");
	g_CvarBalance = FindConVar("mp_autoteambalance");

	g_HealthOffset = FindSendPropOffs("CCSPlayer", "m_iHealth");
	g_ArmorOffset = FindSendPropOffs("CCSPlayer", "m_ArmorValue");
	g_HelmOffset = FindSendPropOffs("CCSPlayer", "m_bHasHelmet");
	g_LifeOffset = FindSendPropOffs("CBasePlayer", "m_lifeState");
	g_PingOffset = FindSendPropOffs("CPlayerResource", "m_iPing");

	HookEvent("player_spawn", SpawnEvent);
	HookEvent("round_start",  RoundStartEvent);
	HookEvent("player_team", PlayerTeamEvent);
	HookEvent("item_pickup", ItemPickUpEvent);
	HookEvent("player_death", DeathEvent);
	HookEvent("bomb_planted", BombPlantedEvent, EventHookMode_PostNoCopy);
	HookEvent("round_end", RoundEndEvent, EventHookMode_PostNoCopy);
	
	PrintToServer("Bots Manager loaded!");
}

public OnMapStart()
{
	g_MaxClients = GetMaxClients();
	g_GameManagerOffset = FindEntityByClassname(g_MaxClients + 1, "cs_player_manager");
	g_Timer = 0.0;
	g_iBotCt = 0;
	g_iBotTr = 0;

	PrecacheSound("ambient/sheep.wav", true);
	PrecacheSound("ambient/animal/dog_growl_behind_wall_2.wav", true);
	PrecacheSound("ambient/animal/horse_6.wav", true);
	PrecacheSound("ambient/animal/cow.wav", true);
	PrecacheSound("ambient/misc/metal7.wav", true);
	PrecacheSound("ambient/misc/metal6.wav", true);
	PrecacheSound("music/HL2_song23_SuitSong3.mp3", true);
	PrecacheSound("physics/glass/glass_cup_break2.wav", true);
	PrecacheSound("ambient/creatures/town_child_scream1.wav", true);

}

public OnGameFrame()
{
	if(g_Timer < GetGameTime() - GetConVarInt(g_CvarBotPingInterval))
	{
		g_Timer = GetGameTime();
		if(g_GameManagerOffset == -1 || g_PingOffset == -1 || !GetConVarBool(g_CvarBotPingEnable))
		return;
		for(new i = 1; i <= g_MaxClients; i++)
		{
			if(!IsValidEdict(i) || !IsClientInGame(i) || !IsFakeClient(i))
			continue;
			SetEntData(g_GameManagerOffset, g_PingOffset + (i * 4), GetRandomInt(GetConVarInt(g_CvarBotPingMinimum), GetConVarInt(g_CvarBotPingMaximum)));
		}
	}
}

public OnConfigsExecuted()
{
	new String:Path[256];
	Format(Path, sizeof(Path), "cfg/sourcemod/BotsManager.cfg");
	if(!FileExists(Path))
	{
		PrintToServer("BotsManager configuration autocreated... in (%s)", Path);
		BmConfig();
	}
	else if(FileExists(Path))
	{
		ServerCommand("exec sourcemod/BotsManager.cfg");
	}
}

public OnSettingChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(convar == g_CvarPrefixEnable)
	{
		if(newValue[0] == '0')
		{
			for (new i = 1; i <= g_MaxClients; i++)
			{
				if(!IsValidEdict(i) || !IsClientInGame(i) || !IsFakeClient(i))
				{
					continue;
				}
    
				new TeamId;
				new String:Names[31];

				GetClientInfo(i, "name", Names, 31);
				TeamId = GetClientTeam(i);

				if(TeamId == BOT_TEAM_TR)
				{
					SetClientInfo(i, "name", Names[g_TRPrefixLen]);
					g_TRNamesDefault = true;
				}
				else if(TeamId == BOT_TEAM_CT)
				{
					SetClientInfo(i, "name", Names[g_CTPrefixLen]);
					g_CTNamesDefault = true;
				}
			}

			g_CTPrefixLen = 0;
			g_TRPrefixLen = 0;

		}
		else
		{
			for (new i = 1; i <= g_MaxClients; i++)
			{
				if(!IsValidEdict(i) || !IsClientInGame(i) || !IsFakeClient(i))
				{
					continue;
				}

				new TeamId;
				new String:Name[31];
				new String:TR_SetPrefixes[31];
				new String:CT_SetPrefixes[31];
				new String:TR_GetPrefixes[31];
				new String:CT_GetPrefixes[31];

				TeamId = GetClientTeam(i);
				GetClientName(i, Name, 31);
				GetConVarString(g_CvarPrefixTR, TR_GetPrefixes, sizeof(TR_GetPrefixes));
				GetConVarString(g_CvarPrefixCT, CT_GetPrefixes, sizeof(CT_GetPrefixes));
				Format(TR_SetPrefixes, sizeof(TR_SetPrefixes), "%s%s", TR_GetPrefixes, Name);
				Format(CT_SetPrefixes, sizeof(CT_SetPrefixes), "%s%s", CT_GetPrefixes, Name);

				if(TeamId == BOT_TEAM_TR)
				{
					SetClientInfo(i, "name", TR_SetPrefixes);
					g_TRPrefixLen = strlen(TR_GetPrefixes);
					g_TRNamesDefault = false;
				}
  
				else if(TeamId == BOT_TEAM_CT)
				{
					SetClientInfo(i, "name", CT_SetPrefixes);
					g_CTPrefixLen = strlen(CT_GetPrefixes);
					g_CTNamesDefault = false;
				}
			}
		}
	}
	BmConfig();
}

public bool:FlipBool(bool:current)
{
	if(current)
		return false;
	else
		return true;
}

public Action:TR_SetDeFName(client, args)
{
	if(g_TRNamesDefault == false)
	{
		for (new i = 1; i <= g_MaxClients; i++)
		{
			if(!IsValidEdict(i) || !IsClientInGame(i) || !IsFakeClient(i))
			{
				continue;
			}
    
			new TeamId;
			new String:Names[31];

			GetClientInfo(i, "name", Names, 31);
			TeamId = GetClientTeam(i);

			if(TeamId == BOT_TEAM_TR)
			{
				SetClientInfo(i, "name", Names[g_TRPrefixLen]);
				g_TRNamesDefault = true;
				TRPrefixMenu(client, 0);
			}
		}
		
		g_TRPrefixLen = 0;
	}
}

public Action:CT_SetDeFName(client, args)
{
	if(g_CTNamesDefault == false)
	{
		for (new i = 1; i <= g_MaxClients; i++)
		{
			if(!IsValidEdict(i) || !IsClientInGame(i) || !IsFakeClient(i))
			{
				continue;
			}

			new TeamId;
			new String:Names[31];

			GetClientInfo(i, "name", Names, 31);
			TeamId = GetClientTeam(i);

			if(TeamId == BOT_TEAM_CT)
			{
				SetClientInfo(i, "name", Names[g_CTPrefixLen]);
				g_CTNamesDefault = true;
				CTPrefixMenu(client, 0);
			}
		}
		
		g_CTPrefixLen = 0;
	}
}

public Action:SayTeamCmd(client, args)
{
	if(g_CTItemSelected == true)
	{
		if(g_CTNamesDefault == true)
		{
			new String:CTStringArg[31];
			GetCmdArgString(CTStringArg, sizeof(CTStringArg));
			StripQuotes(CTStringArg);
			g_CTPrefixLen = strlen(CTStringArg);

			if(g_CTPrefixLen >= MAX_PREFIX_LEN)
			{
				PrintToChat(client, "\x04(\x03Bots Manager\x04) %t", "ChatPrefixInChatLong", g_CTPrefixLen, MAX_PREFIX_LEN);
				EmitSoundToClient(client, "ambient/misc/metal6.wav", SNDCHAN_WEAPON, SNDLEVEL_LIBRARY);
				g_CTPrefixLen = 0;
				CTPrefixMenu(client, 0);
				return Plugin_Handled;
			}
			else if(g_iBotCt == 0)
			{
				PrintToChat(client, "\x04(\x03Bots Manager\x04) БОТОВ [КТ] НЕ ОБНАРУЖЕНО/BOTS [CT] NOT FOUND!");
				EmitSoundToClient(client, "ambient/misc/metal6.wav", SNDCHAN_WEAPON, SNDLEVEL_LIBRARY);

				return Plugin_Handled;
			}

			else
			{
				for (new i = 1; i <= g_MaxClients; i++)
				{
					if(!IsValidEdict(i) || !IsClientInGame(i) || !IsFakeClient(i))
					{
						continue;
					}

					new BotTeamId;
					new String:CT_BotNames[31];
					new String:CT_BotPrefixes[31];

					BotTeamId = GetClientTeam(i);
					GetClientInfo(i, "name", CT_BotNames, 31);
					Format(CT_BotPrefixes, sizeof(CT_BotPrefixes), "%s%s", CTStringArg, CT_BotNames);

					if(BotTeamId == BOT_TEAM_CT)
					{
						SetClientInfo(i, "name", CT_BotPrefixes);
						SetConVarString(g_CvarPrefixCT, CTStringArg);
						g_CTNamesDefault = false;
						CTPrefixMenu(client, 0);
					}
				}
			}
		}

		g_CTItemSelected = false;
		return Plugin_Handled;

	}

	else if(g_TRItemSelected == true)
	{
		if(g_TRNamesDefault == true)
		{
			new String:TRStringArg[31];
			GetCmdArgString(TRStringArg, sizeof(TRStringArg));
			StripQuotes(TRStringArg);
			g_TRPrefixLen = strlen(TRStringArg);

			if(g_TRPrefixLen >= MAX_PREFIX_LEN)
			{
				PrintToChat(client, "\x04(\x03Bots Manager\x04) %t", "ChatPrefixInChatLong", g_TRPrefixLen, MAX_PREFIX_LEN);
				EmitSoundToClient(client, "ambient/misc/metal6.wav", SNDCHAN_WEAPON, SNDLEVEL_LIBRARY);
				g_TRPrefixLen = 0;
				TRPrefixMenu(client, 0);
				return Plugin_Handled;
			}
			else if(g_iBotTr == 0)
			{
				PrintToChat(client, "\x04(\x03Bots Manager\x04) БОТОВ [Т] НЕ ОБНАРУЖЕНО/BOTS [T] NOT FOUND!");
				EmitSoundToClient(client, "ambient/misc/metal6.wav", SNDCHAN_WEAPON, SNDLEVEL_LIBRARY);

				return Plugin_Handled;
			}

			else
			{
				for (new i = 1; i <= g_MaxClients; i++)
				{
					if(!IsValidEdict(i) || !IsClientInGame(i) || !IsFakeClient(i))
					{
						continue;
					}

					new BotTeamId;
					new String:TR_BotNames[31];
					new String:TR_BotPrefixes[31];

					BotTeamId = GetClientTeam(i);
					GetClientInfo(i, "name", TR_BotNames, 31);
					Format(TR_BotPrefixes, sizeof(TR_BotPrefixes), "%s%s", TRStringArg, TR_BotNames);

					if(BotTeamId == BOT_TEAM_TR)
					{
						SetClientInfo(i, "name", TR_BotPrefixes);
						SetConVarString(g_CvarPrefixTR, TRStringArg);
						g_TRNamesDefault = false;
						TRPrefixMenu(client, 0);
					}
				}
			}
		}

		g_TRItemSelected = false;
		return Plugin_Handled;
	}

	if(IsPlayerAlive(client) && IsClientInGame(client))
	{
		new String:text[192];
		GetCmdArgString(text, sizeof(text));
		new startidx = 0;
		
		if(text[strlen(text)-1] == '"')
		{
			text[strlen(text)-1] = '\0';
			startidx = 1;
		}
		if(StrEqual(text[startidx], "!bm"))
		{
			BotsMenu_show(client, args);
			return Plugin_Continue;
		}
		if(StrEqual(text[startidx], "!aboutbm"))
		{
			AboutPlugin();
			return Plugin_Continue;
		}
	}

	return Plugin_Continue;
}

public Action:SayCmd(client, args)
{
	if(g_CTItemSelected == true)
	{
		if(g_CTNamesDefault == true)
		{
			new String:CTStringArg[31];
			GetCmdArgString(CTStringArg, sizeof(CTStringArg));
			StripQuotes(CTStringArg);
			g_CTPrefixLen = strlen(CTStringArg);

			if(g_CTPrefixLen >= MAX_PREFIX_LEN)
			{
				PrintToChat(client, "\x04(\x03Bots Manager\x04) %t", "ChatPrefixInChatLong", g_CTPrefixLen, MAX_PREFIX_LEN);
				EmitSoundToClient(client, "ambient/misc/metal6.wav", SNDCHAN_WEAPON, SNDLEVEL_LIBRARY);
				g_CTPrefixLen = 0;
				CTPrefixMenu(client, 0);
				return Plugin_Handled;
			}
			else if(g_iBotCt == 0)
			{
				PrintToChat(client, "\x04(\x03Bots Manager\x04) БОТОВ [КТ] НЕ ОБНАРУЖЕНО/BOTS [CT] NOT FOUND!");
				EmitSoundToClient(client, "ambient/misc/metal6.wav", SNDCHAN_WEAPON, SNDLEVEL_LIBRARY);

				return Plugin_Handled;
			}

			else
			{
				for (new i = 1; i <= g_MaxClients; i++)
				{
					if(!IsValidEdict(i) || !IsClientInGame(i) || !IsFakeClient(i))
					{
						continue;
					}

					new BotTeamId;
					new String:CT_BotNames[31];
					new String:CT_BotPrefixes[31];

					BotTeamId = GetClientTeam(i);
					GetClientInfo(i, "name", CT_BotNames, 31);
					Format(CT_BotPrefixes, sizeof(CT_BotPrefixes), "%s%s", CTStringArg, CT_BotNames);

					if(BotTeamId == BOT_TEAM_CT)
					{
						SetClientInfo(i, "name", CT_BotPrefixes);
						SetConVarString(g_CvarPrefixCT, CTStringArg);
						g_CTNamesDefault = false;
						CTPrefixMenu(client, 0);
					}
				}
			}
		}

		g_CTItemSelected = false;
		return Plugin_Handled;

	}

	else if(g_TRItemSelected == true)
	{
		if(g_TRNamesDefault == true)
		{
			new String:TRStringArg[31];
			GetCmdArgString(TRStringArg, sizeof(TRStringArg));
			StripQuotes(TRStringArg);
			g_TRPrefixLen = strlen(TRStringArg);

			if(g_TRPrefixLen >= MAX_PREFIX_LEN)
			{
				PrintToChat(client, "\x04(\x03Bots Manager\x04) %t", "ChatPrefixInChatLong", g_TRPrefixLen, MAX_PREFIX_LEN);
				EmitSoundToClient(client, "ambient/misc/metal6.wav", SNDCHAN_WEAPON, SNDLEVEL_LIBRARY);
				g_TRPrefixLen = 0;
				TRPrefixMenu(client, 0);
				return Plugin_Handled;
			}
			else if(g_iBotTr == 0)
			{
				PrintToChat(client, "\x04(\x03Bots Manager\x04) БОТОВ [Т] НЕ ОБНАРУЖЕНО/BOTS [T] NOT FOUND!");
				EmitSoundToClient(client, "ambient/misc/metal6.wav", SNDCHAN_WEAPON, SNDLEVEL_LIBRARY);

				return Plugin_Handled;
			}

			else
			{
				for (new i = 1; i <= g_MaxClients; i++)
				{
					if(!IsValidEdict(i) || !IsClientInGame(i) || !IsFakeClient(i))
					{
						continue;
					}

					new BotTeamId;
					new String:TR_BotNames[31];
					new String:TR_BotPrefixes[31];

					BotTeamId = GetClientTeam(i);
					GetClientInfo(i, "name", TR_BotNames, 31);
					Format(TR_BotPrefixes, sizeof(TR_BotPrefixes), "%s%s", TRStringArg, TR_BotNames);

					if(BotTeamId == BOT_TEAM_TR)
					{
						SetClientInfo(i, "name", TR_BotPrefixes);
						SetConVarString(g_CvarPrefixTR, TRStringArg);
						g_TRNamesDefault = false;
						TRPrefixMenu(client, 0);
					}
				}
			}
		}

		g_TRItemSelected = false;
		return Plugin_Handled;
	}

	if(IsPlayerAlive(client) && IsClientInGame(client))
	{
		new String:text[192];
		GetCmdArgString(text, sizeof(text));
		new startidx = 0;
		
		if(text[strlen(text)-1] == '"')
		{
			text[strlen(text)-1] = '\0';
			startidx = 1;
		}
		if(StrEqual(text[startidx], "!bm"))
		{
			BotsMenu_show(client, args);
			return Plugin_Continue;
		}
		if(StrEqual(text[startidx], "!aboutbm"))
		{
			AboutPlugin();
			return Plugin_Continue;
		}
	}

	return Plugin_Continue;
}

public RoundStartEvent(Handle:event, const String:name[], bool:dontBroadcast) 
{
	for (new client = 1; client <= g_MaxClients; client++)
	{
		if(!IsValidEdict(client) || !IsClientInGame(client) || !IsFakeClient(client))
			continue;
		new Team = GetClientTeam(client);

		if(Team == BOT_TEAM_CT)
		{
			if(g_CurrnetCtModel == -1)
			{
				new RandomModel = GetRandomInt(0, 3);
				SetEntityModel(client, CtModels[RandomModel]);
			}
			else
			SetEntityModel(client, CtModels[g_CurrnetCtModel]);
		}
		else if(Team == BOT_TEAM_TR)
		{
			if(g_CurrnetTrModel == -1)
			{
				new RandomModel = GetRandomInt(0, 3);
				SetEntityModel(client, TrModels[RandomModel]);
			}		
			else
			SetEntityModel(client, TrModels[g_CurrnetTrModel]);
		}
	}
}

public PlayerTeamEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	new Client = GetClientOfUserId(GetEventInt(event, "userid"));
	new TeamId;
	new String:Name[31];
	new String:TR_SetPrefixes[31];
	new String:CT_SetPrefixes[31];
	new String:TR_GetPrefixes[31];
	new String:CT_GetPrefixes[31];

	TeamId = GetEventInt(event, "team");
	GetClientName(Client, Name, 31);
	GetConVarString(g_CvarPrefixTR, TR_GetPrefixes, sizeof(TR_GetPrefixes));
	GetConVarString(g_CvarPrefixCT, CT_GetPrefixes, sizeof(CT_GetPrefixes));
	Format(TR_SetPrefixes, sizeof(TR_SetPrefixes), "%s%s", TR_GetPrefixes, Name);
	Format(CT_SetPrefixes, sizeof(CT_SetPrefixes), "%s%s", CT_GetPrefixes, Name);

	if(Client != 0 && IsFakeClient(Client))
	{
		if (!GetConVarInt(g_CvarPrefixEnable))
		{
			if(TeamId == BOT_TEAM_TR)
			{
				g_iBotTr++;
			}

			else if(TeamId == BOT_TEAM_CT)
			{
				g_iBotCt++;
			}
			return;
		}

		if(TeamId == BOT_TEAM_TR)
		{
			SetClientInfo(Client, "name", TR_SetPrefixes);
			g_TRPrefixLen = strlen(TR_GetPrefixes);
			g_TRNamesDefault = false;
			g_iBotTr++;
		}
  
		else if(TeamId == BOT_TEAM_CT)
		{
			SetClientInfo(Client, "name", CT_SetPrefixes);
			g_CTPrefixLen = strlen(CT_GetPrefixes);
			g_CTNamesDefault = false;
			g_iBotCt++;
		}
	}
}

//Autokill additions by JPe
public Action:DeathEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!GetConVarBool(g_CvarAutoKill))
	return;

	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsFakeClient(victim))
	{
		new bool:AliveHumans = false;
		for (new i = 1; i < g_MaxClients; i++)
		{
			if(IsClientInGame(i) && !IsFakeClient(i) && Alive(i))
			{
				AliveHumans = true;
				break;
			}
		}
		
		if(!AliveHumans)
		{
			new victim_team = GetClientTeam(victim);
			new bool:isLastOnHisTeam = true;
			for (new i = 1; i <= g_MaxClients; i++)
			{
				if(IsClientInGame(i) && Alive(i) && GetClientTeam(i) == victim_team)
				{
					isLastOnHisTeam = false;
					break;
				}
			}
	    
			if(!isLastOnHisTeam && g_BombPlanted == false)
			{
				CreateTimer(GetConVarFloat(g_CvarAutoKillDelay), KillBotsTimer);
			}
			else if(!isLastOnHisTeam && g_BombPlanted == true)
			{
				if(GetConVarBool(g_CvarAutoKillBombPlanted))
				{
					CreateTimer(GetConVarFloat(g_CvarAutoKillDelay), KillBotsTimer);
				}
			}
		}
	}
}

public bool:Alive(client)
{
	if(g_LifeOffset != -1 && GetEntData(client, g_LifeOffset, 1) == 0)
	return true;
	return false;
}

public Action:KillBotsTimer(Handle:timer)
{
	ServerCommand("bot_kill");
	return Plugin_Handled;
}

public RoundEndEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_BombPlanted = false;
}

public BombPlantedEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_BombPlanted = true;
}

public Action:SpawnEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	new Client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(IsFakeClient(Client))
	{
		SetEntData(Client, g_HealthOffset, GetConVarInt(g_CvarBotRespHp), 4, true);
		SetEntData(Client, g_ArmorOffset, GetConVarInt(g_CvarBotRespArmr), 4, true);
		SetEntData(Client, g_HelmOffset, GetConVarInt(g_CvarBotRespHelmet), 1, true);
	}
	else if(IsClientInGame(Client))
	{
		SetEntData(Client, g_HealthOffset, GetConVarInt(g_CvarHumRespHp), 4, true);
	}
}

public Action:ItemPickUpEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	new Client = GetClientOfUserId(GetEventInt(event, "userid"));

	new String:pickedweap[64];
	GetEventString(event, "item", pickedweap, sizeof(pickedweap));

	if(StrEqual(pickedweap, "vesthelm") || StrEqual(pickedweap, "vest"))
	{
		if(IsFakeClient(Client))
		{
			if(StrEqual(pickedweap, "vesthelm"))
			{
				if(!GetConVarInt(g_CvarBotRespHelmet))
				{
					CreateTimer(0.1, BotsHelmDisableTimer, Client);
				}
				else if(GetConVarInt(g_CvarBotRespHelmet))
				{
					CreateTimer(0.1, BotsArmorChangedTimer, Client);
				}
			}
			else if(StrEqual(pickedweap, "vest"))
			{
				if(GetConVarInt(g_CvarBotRespArmr) < 100 || GetConVarInt(g_CvarBotRespArmr) > 100)
				{
					CreateTimer(0.1, BotsArmorChangedTimer, Client);
				}
			}
		}
		else if(IsClientInGame(Client))
		{
			if(StrEqual(pickedweap, "vesthelm"))
			{
				if(!GetConVarInt(g_CvarHumRespHelmet))
				{
					CreateTimer(0.1, HumansHelmDisableTimer, Client);
					PrintHintText(Client,"\x04(\x03Bots Manager\x04)%t", "HintHelmetDisabled");
					EmitSoundToClient(Client, "physics/glass/glass_cup_break2.wav", SNDCHAN_WEAPON, SNDLEVEL_LIBRARY);
				}
				else if(GetConVarInt(g_CvarHumRespHelmet))
				{
					CreateTimer(0.1, HumansArmorChangedTimer, Client);
				}
			}
			else if(StrEqual(pickedweap, "vest"))
			{
				if(GetConVarInt(g_CvarHumRespArmr) < 100 || GetConVarInt(g_CvarHumRespArmr) > 100)
				{
					CreateTimer(0.1, HumansArmorChangedTimer, Client);
				}
			}
		}
	}
}

public Action:HumansHelmDisableTimer(Handle:timer, any:client)
{
	SetEntData(client, g_HelmOffset, GetConVarInt(g_CvarHumRespHelmet), 1, false);
	SetEntData(client, g_ArmorOffset, GetConVarInt(g_CvarHumRespArmr), 4, true);
}

public Action:BotsHelmDisableTimer(Handle:timer, any:client)
{
	SetEntData(client, g_HelmOffset, GetConVarInt(g_CvarBotRespHelmet), 1, false);
	SetEntData(client, g_ArmorOffset, GetConVarInt(g_CvarBotRespArmr), 4, true);
}

public Action:HumansArmorChangedTimer(Handle:timer, any:client)
{
	SetEntData(client, g_ArmorOffset, GetConVarInt(g_CvarHumRespArmr), 4, true);
}

public Action:BotsArmorChangedTimer(Handle:timer, any:client)
{
	SetEntData(client, g_ArmorOffset, GetConVarInt(g_CvarBotRespArmr), 4, true);
}

public OnAdminMenuReady(Handle:topmenu)
{
	if (topmenu == hTopMenu)
	{
		return;
	}
	hTopMenu = topmenu;
	new TopMenuObject:server_commands = FindTopMenuCategory (hTopMenu, ADMINMENU_SERVERCOMMANDS);
	AddToTopMenu(hTopMenu, "BOTS", TopMenuObject_Item, Bots_Item, server_commands, "sm_bots", ADMFLAG_CONFIG);
}

public Bots_Item(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "%T", "BOTS" , param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		BotsMenu_show(param, 1);
	}
}

public Action:BotsMenu_show(client, args) 
{
	decl String:buffer[512];
	EmitSoundToClient(client, "ambient/misc/metal7.wav", SNDCHAN_WEAPON, SNDLEVEL_LIBRARY);

	new Handle:menu = CreateMenu(BotsMenuHandler);
	Format(buffer, sizeof(buffer), "BotsManager :: %T", "TitleMenuMain", client);
	SetMenuTitle(menu, buffer);

	Format(buffer, sizeof(buffer), "%T", "ItemAddRemoveBots", client);
	AddMenuItem(menu, "", buffer);

	Format(buffer, sizeof(buffer), "%T", "ItemSettings", client);
	AddMenuItem(menu, "", buffer);

	Format(buffer, sizeof(buffer), "%T", "ItemBotsExtraSettings", client);
	AddMenuItem(menu, "", buffer);

	Format(buffer, sizeof(buffer), "%T", "ItemHumansExtraSettings", client);
	AddMenuItem(menu, "", buffer);

	Format(buffer, sizeof(buffer), "%T", "ItemBotsPrefixes", client);
	AddMenuItem(menu, "", buffer);

	Format(buffer, sizeof(buffer), "%T", "ItemBotsRestrict", client);
	AddMenuItem(menu, "", buffer);

	Format(buffer, sizeof(buffer), "%T", "ItemAbout", client);
	AddMenuItem(menu,"", buffer);

	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

public BotsMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == 	MenuAction_Select)
	{
		switch(param2)
		{
			case 0:
				MenuBotAdd(param1, 0);
			case 1:
				MenuSettings(param1, 0);
			case 2:
				MenuExtraSettingsBots(param1, 0);
			case 3:
				MenuExtraSettingsHumans(param1, 0);
			case 4:
				PrefixMenu(param1, 0);
			case 5:
				MenuRestrict(param1, 0);
			case 6:
			{
				AboutPlugin();
				BotsMenu_show( param1, 0);
			}
		}
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack)
		{
			RedisplayAdminMenu(hTopMenu, param1);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Action:MenuBotAdd(client, args)
{
	decl String:buffer[512];
	EmitSoundToClient(client, "ambient/misc/metal6.wav", SNDCHAN_WEAPON, SNDLEVEL_LIBRARY);

	new Handle:submenu = CreateMenu(MenuHandlerBotAdd);
	Format(buffer, sizeof(buffer), "BotsManager :: %T", "TitleAddBots", client);
	SetMenuTitle(submenu, buffer);
	Format(buffer, sizeof(buffer), "%T", "ItemAddBotCT", client);
	AddMenuItem(submenu, "", buffer);
	Format(buffer, sizeof(buffer), "%T", "ItemAddBotT", client);
	AddMenuItem(submenu, "", buffer);
	Format(buffer, sizeof(buffer), "%T", "ItemBotCTKick", client);
	AddMenuItem(submenu, "", buffer);
	Format(buffer, sizeof(buffer), "%T", "ItemBotTKick", client);
	AddMenuItem(submenu, "", buffer);
	Format(buffer, sizeof(buffer), "%T", "ItemBotKill", client);
	AddMenuItem(submenu, "", buffer);
	Format(buffer, sizeof(buffer), "%T", "ItemBotKick", client);
	AddMenuItem(submenu, "", buffer);
	if(GetConVarBool(g_CvarBalance))
	Format(buffer, sizeof(buffer), "%T", "ItemAutoteamBalanceOff", client);
	else
	Format(buffer, sizeof(buffer), "%T", "ItemAutoteamBalanceOn", client);
	AddMenuItem(submenu, "", buffer);

	SetMenuExitBackButton(Handle:submenu, bool:true);
	DisplayMenu(submenu,client,MENU_TIME_FOREVER);

}


public MenuHandlerBotAdd(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select) 
	{
		switch(param2)
		{
			case 0:
			{
				ServerCommand("bot_add_ct");
				EmitSoundToClient(param1, "ambient/misc/metal6.wav", SNDCHAN_WEAPON, SNDLEVEL_LIBRARY);
			}
			case 1:
			{
				ServerCommand("bot_add_t");
				EmitSoundToClient(param1, "ambient/misc/metal6.wav", SNDCHAN_WEAPON, SNDLEVEL_LIBRARY);
			}
			case 2:
			{
				if(g_iBotCt != 0)
				{
					for (new i = 1; i <= g_MaxClients; i++)
					{
						if(!IsValidEdict(i) || !IsClientInGame(i) || !IsFakeClient(i))
						{
							continue;
						}

						new BotTeamId;
						BotTeamId = GetClientTeam(i);

						if(BotTeamId == BOT_TEAM_CT)
						{
							ServerCommand("bot_join_team CT");
							KickClient(i);
							MenuBotAdd(param1, 0);
						}
					}

					g_iBotCt = 0;
					PrintToChat(param1, "\x04(\x03Bots Manager\x04) %t", "ChatBotsCTKick");
					EmitSoundToClient(param1, "ambient/misc/metal6.wav", SNDCHAN_WEAPON, SNDLEVEL_LIBRARY);
				}
				else
				{
					PrintToChat(param1, "\x04(\x03Bots Manager\x04) %t", "ChatBotsCTKickNotFound");
				}
			}
			case 3:
			{
				if(g_iBotTr != 0)
				{
					for (new i = 1; i <= g_MaxClients; i++)
					{
						if(!IsValidEdict(i) || !IsClientInGame(i) || !IsFakeClient(i))
						{
							continue;
						}

						new BotTeamId;
						BotTeamId = GetClientTeam(i);

						if(BotTeamId == BOT_TEAM_TR)
						{
							ServerCommand("bot_join_team T");
							KickClient(i);
							MenuBotAdd(param1, 0);
						}
					}

					g_iBotTr = 0;
					PrintToChat(param1, "\x04(\x03Bots Manager\x04) %t", "ChatBotsTKick");
					EmitSoundToClient(param1, "ambient/misc/metal6.wav", SNDCHAN_WEAPON, SNDLEVEL_LIBRARY);
				}
				else
				{
					PrintToChat(param1, "\x04(\x03Bots Manager\x04) %t", "ChatBotsTKickNotFound");
				}
			}
			case 4:
			{
				ServerCommand("bot_kill");
				PrintToChat(param1, "\x04(\x03Bots Manager\x04) %t", "ChatBotsKill");
				EmitSoundToClient(param1, "ambient/creatures/town_child_scream1.wav", SNDCHAN_WEAPON, SNDLEVEL_LIBRARY);
			}
			case 5:
			{
				ServerCommand("bot_kick");
				g_iBotCt = 0;
				g_iBotTr = 0;
				PrintToChat(param1, "\x04(\x03Bots Manager\x04) %t", "ChatBotsKick");
				EmitSoundToClient(param1, "ambient/misc/metal6.wav", SNDCHAN_WEAPON, SNDLEVEL_LIBRARY);
			}
			case 6:
			{
				SetConVarBool(g_CvarBalance, FlipBool(GetConVarBool(g_CvarBalance)), true, true);

				if(GetConVarBool(g_CvarBalance) == true)
				{
					PrintToChat(param1, "\x04(\x03Bots Manager\x04) %t", "ChatBalanceOn");
					ServerCommand("mp_limitteams 4");
				}
				else if(GetConVarBool(g_CvarBalance) == false)
				{
					PrintToChat(param1, "\x04(\x03Bots Manager\x04) %t", "ChatBalanceOff");
					ServerCommand("mp_limitteams 0");
				}
			}
		}
		MenuBotAdd(param1, 0);
	}
	if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack)
		{
			BotsMenu_show(param1, 0);
			return;
		}
	}
}

public Action:MenuSettings(client, args)
{
	decl String:buffer[512];
	decl String:chat[128];
	EmitSoundToClient(client, "ambient/misc/metal6.wav", SNDCHAN_WEAPON, SNDLEVEL_LIBRARY);

	new Handle:submenu = CreateMenu(MenuHandlerSettings);
	Format(buffer, sizeof(buffer), "BotsManager :: %T", "ItemSettings", client);
	SetMenuTitle(submenu, buffer);
	if(GetConVarInt(g_CvarDifficulty) == 0)
		Format(buffer, sizeof(buffer), "%T", "ItemBotSkillsNoobs", client);
	else if(GetConVarInt(g_CvarDifficulty) == 1)
		Format(buffer, sizeof(buffer), "%T", "ItemBotSkillsNormal", client);
	else if(GetConVarInt(g_CvarDifficulty) == 2)
		Format(buffer, sizeof(buffer), "%T", "ItemBotSkillHard", client);
	else if(GetConVarInt(g_CvarDifficulty) == 3)
		Format(buffer, sizeof(buffer), "%T", "ItemBotSkillExperts", client);
	AddMenuItem(submenu, "", buffer);

	GetConVarString(g_CvarChat, chat, sizeof(chat));
	if(StrEqual(chat, "off"))
		Format(chat, sizeof(chat), "%T", "ItemBotChatOff", client);
	else if(StrEqual(chat, "radio"))
		Format(chat, sizeof(chat), "%T", "ItemBotChatRadio", client);
	else if(StrEqual(chat, "minimal"))
		Format(chat, sizeof(chat), "%T", "ItemBotChatMinimal", client);
	else if(StrEqual(chat, "normal"))
		Format(chat, sizeof(chat), "%T", "ItemBotChatNormal", client);
	AddMenuItem(submenu, "", chat);

	if(GetConVarBool(g_CvarBotPingEnable))
		Format(buffer, sizeof(buffer), "%T", "ItemBotPingOff", client);
	else
		Format(buffer, sizeof(buffer), "%T", "ItemBotPingOn", client);
	AddMenuItem(submenu, "", buffer);

	if(GetConVarBool(g_CvarAutoKill))
		Format(buffer, sizeof(buffer), "%T", "ItemBotAutokillOff", client);
	else
		Format(buffer, sizeof(buffer), "%T", "ItemBotAutokillOn", client);
	AddMenuItem(submenu, "", buffer);

	if(GetConVarBool(g_CvarAutoKillBombPlanted))
		Format(buffer, sizeof(buffer), "%T", "ItemBotAutokillBombPlantedOff", client);
	else
		Format(buffer, sizeof(buffer), "%T", "ItemBotAutokillBombPlantedOn", client);
	AddMenuItem(submenu, "", buffer);

	new String:Delay[4];
	GetConVarString(g_CvarAutoKillDelay, Delay, 4);

	Format(buffer, sizeof(buffer), "%T %s", "ItemBotAutokillDelay", client, Delay);
	AddMenuItem(submenu, "", buffer);

	Format(buffer, sizeof(buffer), "%T", "ItemModels",client);
	AddMenuItem(submenu, "", buffer);

	SetMenuExitBackButton(Handle:submenu,true);
	DisplayMenu(submenu, client, MENU_TIME_FOREVER);
}

public MenuHandlerSettings(Handle:menu, MenuAction:action, param1, param2)
{
	decl String:buffer[128];

	if (action == MenuAction_Select) 
	{
		if(param2 == 0)
		{
			if(GetConVarInt(g_CvarDifficulty) == 0)
			{
				SetConVarInt(g_CvarDifficulty, 1);
				PrintToChat(param1, "\x04(\x03Bots Manager\x04) %t" , "ChatBotDifficultyNormal");
				EmitSoundToClient(param1, "ambient/animal/cow.wav", SNDCHAN_WEAPON, SNDLEVEL_LIBRARY);
			}
			else if(GetConVarInt(g_CvarDifficulty) == 1)
			{
				SetConVarInt(g_CvarDifficulty, 2);
				PrintToChat(param1, "\x04(\x03Bots Manager\x04) %t" , "ChatBotDifficultyHard");
				EmitSoundToClient(param1, "ambient/animal/horse_6.wav", SNDCHAN_WEAPON, SNDLEVEL_LIBRARY);
			}
			else if(GetConVarInt(g_CvarDifficulty) == 2)
			{
				SetConVarInt(g_CvarDifficulty, 3);
				PrintToChat(param1, "\x04(\x03Bots Manager\x04) %t" , "ChatBotDifficultyExperts");
				EmitSoundToClient(param1, "ambient/animal/dog_growl_behind_wall_2.wav", SNDCHAN_WEAPON, SNDLEVEL_LIBRARY);
			}
			else if(GetConVarInt(g_CvarDifficulty) == 3)
			{
				SetConVarInt(g_CvarDifficulty, 0);
				PrintToChat(param1, "\x04(\x03Bots Manager\x04) %t" , "ChatBotDifficultyEasy");
				EmitSoundToClient(param1, "ambient/sheep.wav", SNDCHAN_WEAPON, SNDLEVEL_LIBRARY);
			}

			BmConfig();
			MenuSettings(param1, 0);
		}
		if(param2 == 1)
		{
			GetConVarString(g_CvarChat, buffer, sizeof(buffer));
			if(StrEqual(buffer, "off"))
			{
				SetConVarString(g_CvarChat, "radio");
			}
			else if(StrEqual(buffer, "radio"))
			{
				SetConVarString(g_CvarChat, "minimal");
			}
			else if(StrEqual(buffer, "minimal"))
			{
				SetConVarString(g_CvarChat, "normal");
			}
			else if(StrEqual(buffer, "normal"))
			{
				SetConVarString(g_CvarChat, "off");
			}
			BmConfig();
			MenuSettings(param1, 0);
		}
		if(param2 == 2)
		{
			SetConVarBool(g_CvarBotPingEnable, FlipBool(GetConVarBool(g_CvarBotPingEnable)), true, true);
			if(GetConVarBool(g_CvarBotPingEnable) == true)
			{
				PrintToChat(param1, "\x04(\x03Bots Manager\x04) %t", "ChatBotPingOn");
			}
			if(GetConVarBool(g_CvarBotPingEnable) == false)
			{
				PrintToChat(param1, "\x04(\x03Bots Manager\x04) %t", "ChatBotPingOff");
			}
			MenuSettings(param1, 0);
		}
		if(param2 == 3)
		{
			SetConVarBool(g_CvarAutoKill, FlipBool(GetConVarBool(g_CvarAutoKill)), true, true);
			if(GetConVarBool(g_CvarAutoKill) == true)
			{
				PrintToChat(param1, "\x04(\x03Bots Manager\x04) %t", "ChatBotAutokillOn");
			}
			if(GetConVarBool(g_CvarAutoKill) == false)
			{
				PrintToChat(param1, "\x04(\x03Bots Manager\x04) %t", "ChatBotAutokillOff");
			}
			MenuSettings(param1, 0);
		}
		if(param2 == 4)
		{
			SetConVarBool(g_CvarAutoKillBombPlanted, FlipBool(GetConVarBool(g_CvarAutoKillBombPlanted)), true, true);
			if(GetConVarBool(g_CvarAutoKillBombPlanted) == true)
			{
				PrintToChat(param1, "\x04(\x03Bots Manager\x04) %t", "ChatBotAutokillBombPlantedOn");
			}
			if(GetConVarBool(g_CvarAutoKillBombPlanted) == false)
			{
				PrintToChat(param1, "\x04(\x03Bots Manager\x04) %t", "ChatBotAutokillBotPlantedOff");
			}
			MenuSettings(param1, 0);
		}
		if(param2 == 5)
		{
			new String:CurrDelay[4];
			GetConVarString(g_CvarAutoKillDelay, CurrDelay, 4);
			new Float:Current = StringToFloat(CurrDelay);
			if(Current >= g_AutoKillDelayMax || Current < 0.5)
			{
				SetConVarFloat(g_CvarAutoKillDelay, 0.5);
			}
			else
			{
				SetConVarFloat(g_CvarAutoKillDelay, GetConVarFloat(g_CvarAutoKillDelay) + 0.5);
			}
			MenuSettings(param1, 0);
		}
		if(param2 == 6)
		{
			MenuModels(param1, 0);
		}
	}
	if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack)
		{
			BotsMenu_show( param1, 0);
			return;
		}
	}
}

public Action:MenuModels(client, args)
{
	decl String:buffer[512];
	EmitSoundToClient(client, "ambient/misc/metal6.wav", SNDCHAN_WEAPON, SNDLEVEL_LIBRARY);
	new Handle:submenu = CreateMenu(MenuModelsHandler);

	Format(buffer, sizeof(buffer), "BotsManager :: %T", "TitleModels", client);
	SetMenuTitle(submenu, buffer);

	if(g_CurrnetCtModel == 0)
		Format(buffer, sizeof(buffer), "%T :: URBAN", "ItemModelToCT", client);
	else if(g_CurrnetCtModel == 1)
		Format(buffer, sizeof(buffer), "%T :: GSG", "ItemModelToCT", client);
	else if(g_CurrnetCtModel == 2)
		Format(buffer, sizeof(buffer), "%T :: SAS", "ItemModelToCT", client);
	else if(g_CurrnetCtModel == 3)
		Format(buffer, sizeof(buffer), "%T :: GIGN", "ItemModelToCT", client);
	else if(g_CurrnetCtModel == -1)
		Format(buffer, sizeof(buffer), "%T :: RANDOM (СЛУЧАЙНО)", "ItemModelToCT", client);
	AddMenuItem(submenu, "", buffer);

	if(g_CurrnetTrModel == 0)
		Format(buffer, sizeof(buffer), "%T :: PHOENIX", "ItemModelToTR", client);
	else if(g_CurrnetTrModel == 1)
		Format(buffer, sizeof(buffer), "%T :: LEET", "ItemModelToTR", client);
	else if(g_CurrnetTrModel == 2)
		Format(buffer, sizeof(buffer), "%T :: ARCTIC", "ItemModelToTR", client);
	else if(g_CurrnetTrModel == 3)
		Format(buffer, sizeof(buffer), "%T :: GUERILLA", "ItemModelToTR", client);
	else if(g_CurrnetTrModel == -1)
		Format(buffer, sizeof(buffer), "%T :: RANDOM (СЛУЧАЙНО)", "ItemModelToTR", client);
	AddMenuItem(submenu, "", buffer);

	SetMenuExitBackButton(Handle:submenu,true);
	DisplayMenu(submenu,client,MENU_TIME_FOREVER);
}

public MenuModelsHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		switch(param2)
		{
			case 0:
			{
				if(g_CurrnetCtModel >= -1 || g_CurrnetCtModel <= 3)
					g_CurrnetCtModel++;
				if(g_CurrnetCtModel == 4)
					g_CurrnetCtModel = -1;
				
				for (new client = 1; client <= g_MaxClients; client++)
				{
					if(!IsValidEdict(client) || !IsClientInGame(client) || !IsFakeClient(client))
					{
						continue;
					}

					new Team = GetClientTeam(client);

					if(Team == BOT_TEAM_CT)
					{
						if(g_CurrnetCtModel == -1)
						{
							new RandomModel = GetRandomInt(0, 3);
							SetEntityModel(client, CtModels[RandomModel]);
						}
						else
						
						SetEntityModel(client, CtModels[g_CurrnetCtModel]);

					}
				}
				MenuModels(param1, 0);
			}
			case 1:
			{
				if(g_CurrnetTrModel >= -1 || g_CurrnetTrModel <= 3)
					g_CurrnetTrModel++;
				if(g_CurrnetTrModel == 4)
					g_CurrnetTrModel = -1;

				for (new client = 1; client <= g_MaxClients; client++)
				{
					if(!IsValidEdict(client) || !IsClientInGame(client) || !IsFakeClient(client))
					{
						continue;
					}
					new Team = GetClientTeam(client);

					if(Team == BOT_TEAM_TR)
					{
						if(g_CurrnetTrModel == -1)
						{
							new RandomModel = GetRandomInt(0, 3);
							SetEntityModel(client, TrModels[RandomModel]);
						}
						
						else

						SetEntityModel(client, TrModels[g_CurrnetTrModel]);
					}
				}
				MenuModels(param1, 0);
			}
		}
	}
	if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack)
		{
			MenuSettings(param1, 0);
			return;
		}
	}
}

public Action:MenuExtraSettingsBots(client, args)
{
	decl String:buffer[512];
	EmitSoundToClient(client, "ambient/misc/metal6.wav", SNDCHAN_WEAPON, SNDLEVEL_LIBRARY);
	new Handle:submenu = CreateMenu(MenuHandlerExtraSettingsBots);
	Format(buffer, sizeof(buffer), "BotsManager :: %T", "ItemBotsExtraSettings", client);
	SetMenuTitle(submenu, buffer);
	Format(buffer, sizeof(buffer), "%T:  %i", "ItemIncreaseBotsHp", client, GetConVarInt(g_CvarBotRespHp));
	AddMenuItem(submenu, "", buffer);
	Format(buffer, sizeof(buffer), "%T:  %i", "ItemDecreaseBotsHp", client, GetConVarInt(g_CvarBotRespHp));
	AddMenuItem(submenu, "", buffer);
	Format(buffer, sizeof(buffer), "%T:  %i", "ItemIncreaseBotsArmr", client, GetConVarInt(g_CvarBotRespArmr));
	AddMenuItem(submenu, "", buffer);
	Format(buffer, sizeof(buffer), "%T:  %i", "ItemDecreaseBotsArmr", client, GetConVarInt(g_CvarBotRespArmr));
	AddMenuItem(submenu, "", buffer);
	if(GetConVarInt(g_CvarBotRespHelmet) == 1)
	Format(buffer, sizeof(buffer), "%T", "ItemBotsHelmetOn", client);
	else if(GetConVarInt(g_CvarBotRespHelmet) == 0)
	Format(buffer, sizeof(buffer), "%T", "ItemBotsHelmetOff", client);
	AddMenuItem(submenu, "", buffer);

	SetMenuExitBackButton(Handle:submenu,true);
	DisplayMenu(submenu,client,MENU_TIME_FOREVER);
}

public MenuHandlerExtraSettingsBots(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select) 
	{
		switch(param2)
		{
			case 0:
			{
				if(GetConVarInt(g_CvarBotRespHp) <= 500)
				SetConVarInt(g_CvarBotRespHp, GetConVarInt(g_CvarBotRespHp) + 10, true, true);
				{
					PrintHintText(param1, "%t: %i" , "HintBotsHpAmount", GetConVarInt(g_CvarBotRespHp));
				}
			}
			case 1:
			{
				if(GetConVarInt(g_CvarBotRespHp) >= 10)
				SetConVarInt(g_CvarBotRespHp, GetConVarInt(g_CvarBotRespHp) - 10, true, true);
				{
					PrintHintText(param1, "%t: %i" , "HintBotsHpAmount", GetConVarInt(g_CvarBotRespHp));
				}
			}
			case 2:
			{
				if(GetConVarInt(g_CvarBotRespArmr) <= 100)
				SetConVarInt(g_CvarBotRespArmr, GetConVarInt(g_CvarBotRespArmr) + 10, true, true);
				{
					PrintHintText(param1, "%t: %i" , "HintBotsArmrAmount", GetConVarInt(g_CvarBotRespHp));
				}
			}
			case 3:
			{
				if(GetConVarInt(g_CvarBotRespArmr) >= 0)
				SetConVarInt(g_CvarBotRespArmr, GetConVarInt(g_CvarBotRespArmr) - 10, true, true);
				{
					PrintHintText(param1, "%t: %i" , "HintBotsArmrAmount", GetConVarInt(g_CvarBotRespArmr));
				}
			}
			case 4:
			{
				SetConVarInt(g_CvarBotRespHelmet, FlipBool(GetConVarBool(g_CvarBotRespHelmet)), true, true);
				if(GetConVarBool(g_CvarBotRespHelmet) == true)
					PrintToChat(param1, "\x04(\x03Bots Manager\x04) %t", "ChatBotHelmetOn");
				if(GetConVarBool(g_CvarBotRespHelmet) == false)
					PrintToChat(param1, "\x04(\x03Bots Manager\x04) %t", "ChatBotHelmetOff");
			}
		}
		MenuExtraSettingsBots(param1, 0);
	}
	if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack)
		{
			BotsMenu_show( param1, 0);
			return;
		}
	}
}

public Action:MenuExtraSettingsHumans(client, args)
{
	decl String:buffer[512];
	EmitSoundToClient(client, "ambient/misc/metal6.wav", SNDCHAN_WEAPON, SNDLEVEL_LIBRARY);

	new Handle:submenu = CreateMenu(MenuHandlerExtraSettingsHumans);
	Format(buffer, sizeof(buffer), "BotsManager :: %T", "ItemHumansExtraSettings", client);
	SetMenuTitle(submenu, buffer);
	Format(buffer, sizeof(buffer), "%T:  %i", "ItemIncreaseHumansHp", client, GetConVarInt(g_CvarHumRespHp));
	AddMenuItem(submenu, "", buffer);
	Format(buffer, sizeof(buffer), "%T:  %i", "ItemDecreaseHumansHp", client, GetConVarInt(g_CvarHumRespHp));
	AddMenuItem(submenu, "", buffer);
	Format(buffer, sizeof(buffer), "%T:  %i", "ItemIncreaseHumansArmr", client, GetConVarInt(g_CvarHumRespArmr));
	AddMenuItem(submenu, "", buffer);
	Format(buffer, sizeof(buffer), "%T:  %i", "ItemDecreaseHumansArmr", client, GetConVarInt(g_CvarHumRespArmr));
	AddMenuItem(submenu, "", buffer);
	if(GetConVarInt(g_CvarHumRespHelmet) == 1)
	Format(buffer, sizeof(buffer), "%T", "ItemHumansHelmetOn", client);
	else if(GetConVarInt(g_CvarHumRespHelmet) == 0)
	Format(buffer, sizeof(buffer), "%T", "ItemHumansHelmetOff", client);
	AddMenuItem(submenu, "", buffer);

	SetMenuExitBackButton(Handle:submenu,true);
	DisplayMenu(submenu,client,MENU_TIME_FOREVER);
}

public MenuHandlerExtraSettingsHumans(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select) 
	{
		switch(param2)
		{
			case 0:
			{
				if(GetConVarInt(g_CvarHumRespHp) <= 500)
				SetConVarInt(g_CvarHumRespHp, GetConVarInt(g_CvarHumRespHp) + 10, true, true);
				{
					PrintHintText(param1, "%t: %i" , "HintHumansHpAmount", GetConVarInt(g_CvarHumRespHp));
				}
			}
			case 1:
			{
				if(GetConVarInt(g_CvarHumRespHp) >= 10)
				SetConVarInt(g_CvarHumRespHp, GetConVarInt(g_CvarHumRespHp) - 10, true, true);
				{
					PrintHintText(param1, "%t: %i" , "HintHumansHpAmount", GetConVarInt(g_CvarHumRespHp));
				}
			}
			case 2:
			{
				if(GetConVarInt(g_CvarHumRespArmr) <= 100)
				SetConVarInt(g_CvarHumRespArmr, GetConVarInt(g_CvarHumRespArmr) + 10, true, true);
				{
					PrintHintText(param1, "%t: %i" , "HintHumansArmrAmount", GetConVarInt(g_CvarHumRespArmr));
				}
			}
			case 3:
			{
				if(GetConVarInt(g_CvarHumRespArmr) >= 0)
				SetConVarInt(g_CvarHumRespArmr, GetConVarInt(g_CvarHumRespArmr) - 10, true, true);
				{
					PrintHintText(param1, "%t: %i" , "HintHumansArmrAmount", GetConVarInt(g_CvarHumRespArmr));
				}
			}
			case 4:
			{
				SetConVarInt(g_CvarHumRespHelmet, FlipBool(GetConVarBool(g_CvarHumRespHelmet)), true, true);
				if(GetConVarBool(g_CvarHumRespHelmet) == true)
				{
					PrintToChat(param1, "\x04(\x03Bots Manager\x04) %t", "ChatHumansHelmetOn");
				}
				if(GetConVarBool(g_CvarHumRespHelmet) == false)
				{
					PrintToChat(param1, "\x04(\x03Bots Manager\x04) %t", "ChatHumansHelmetOff");
				}
			}
		}
		MenuExtraSettingsHumans(param1, 0);
	}
	if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack)
		{
			BotsMenu_show(param1, 0);
			return;
		}
	}
}

public Action:PrefixMenu(client, args)
{
	decl String:buffer[1024];
	new String:CurrentPrefixCT[32];
	GetConVarString(g_CvarPrefixCT, CurrentPrefixCT, 32);
	new String:CurrentPrefixTR[32];
	GetConVarString(g_CvarPrefixTR, CurrentPrefixTR, 32);
	EmitSoundToClient(client, "ambient/misc/metal6.wav", SNDCHAN_WEAPON, SNDLEVEL_LIBRARY);
	new Handle:menu = CreateMenu(PrefixMenuHandler);

	Format(buffer, sizeof(buffer), "BotsManager :: %T", "TitlePrefixes", client);
	SetMenuTitle(menu, buffer);

	Format(buffer, sizeof(buffer), "%T", "ItemBotsPrefixesAllCT", client);
	AddMenuItem(menu, "", buffer, ITEMDRAW_DEFAULT);
	
	Format(buffer, sizeof(buffer), "%T", "ItemBotsPrefixesAllTR", client);
	AddMenuItem(menu, "", buffer, ITEMDRAW_DEFAULT);

	AddMenuItem(menu, "", buffer, ITEMDRAW_SPACER);

	if(g_iBotTr == 0 || g_iBotCt == 0)
	{
		Format(buffer, sizeof(buffer), "%T", "ItemBotsPrefixOnOff", client);
		AddMenuItem(menu, "", buffer, ITEMDRAW_DISABLED);
	}
	else if(g_iBotTr != 0 || g_iBotCt != 0)
	{
		Format(buffer, sizeof(buffer), "%T", "ItemBotsPrefixOnOff", client);
		AddMenuItem(menu, "", buffer, ITEMDRAW_DEFAULT);
	}

	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public PrefixMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
	{
		switch(param2)
		{
			case 0:
			{
				EmitSoundToClient(param1, "ambient/misc/metal7.wav", SNDCHAN_WEAPON, SNDLEVEL_LIBRARY);
				CTPrefixMenu(param1, 0);
			}
			case 1:
			{
				EmitSoundToClient(param1, "ambient/misc/metal7.wav", SNDCHAN_WEAPON, SNDLEVEL_LIBRARY);
				TRPrefixMenu(param1, 0);
			}
			case 2:
			{
				PrefixMenu(param1, 0);
			}
			case 3:
			{
				if(GetConVarInt(g_CvarPrefixEnable) == 0)
				{
					SetConVarInt(g_CvarPrefixEnable, 1);
				}
				else
				{
					SetConVarInt(g_CvarPrefixEnable, 0);
				}
				PrefixMenu(param1, 0);
			}
		}
	}
	if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack)
		{
			BotsMenu_show(param1, 0);
			return;
		}
	}
}

public Action:CTPrefixMenu(client, args)
{
	decl String:buffer[1024];
	new String:CurrentPrefixCT[32];
	GetConVarString(g_CvarPrefixCT, CurrentPrefixCT, 32);
	new String:CurrentPrefixTR[32];
	GetConVarString(g_CvarPrefixTR, CurrentPrefixTR, 32);
	EmitSoundToClient(client, "ambient/misc/metal6.wav", SNDCHAN_WEAPON, SNDLEVEL_LIBRARY);
	new Handle:menu = CreateMenu(CTPrefixMenuHandler);

	Format(buffer, sizeof(buffer), "BotsManager :: %T", "TitlePrefixes", client);
	SetMenuTitle(menu, buffer);

	if(g_iBotCt == 0)
	{
		Format(buffer, sizeof(buffer), "%T", "ItemBotsPrefixCtNotFound", client);
		AddMenuItem(menu, "", buffer, ITEMDRAW_DISABLED);
	}
	else if(g_iBotCt != 0)
	{
		if(g_CTNamesDefault == false || !GetConVarInt(g_CvarPrefixEnable))
		{
			Format(buffer, sizeof(buffer), "%T", "ItemBotsPrefixCT", client);
			AddMenuItem(menu, "", buffer, ITEMDRAW_DISABLED);
		}
		else if(g_CTNamesDefault == true || GetConVarInt(g_CvarPrefixEnable))
		{
			Format(buffer, sizeof(buffer), "%T", "ItemBotsPrefixCT", client);
			AddMenuItem(menu, "", buffer, ITEMDRAW_DEFAULT);
		}
		if(g_CTNamesDefault == true || !GetConVarInt(g_CvarPrefixEnable))
		{
			Format(buffer, sizeof(buffer), "%T [%s]", "ItemBotsPrefixDeleteCT", client, CurrentPrefixCT);
			AddMenuItem(menu, "", buffer, ITEMDRAW_DISABLED);
		}
		else if(g_CTNamesDefault == false || GetConVarInt(g_CvarPrefixEnable))
		{
			Format(buffer, sizeof(buffer), "%T [%s]", "ItemBotsPrefixDeleteCT", client, CurrentPrefixCT);
			AddMenuItem(menu, "", buffer, ITEMDRAW_DEFAULT);
		}
	}

	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public CTPrefixMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
	{
		switch(param2)
		{
			case 0:
			{
				PrintToChat(param1, "\x04(\x03Bots Manager\x04) %t", "ChatPrefixInChatForCt");
				EmitSoundToClient(param1, "ambient/misc/metal7.wav", SNDCHAN_WEAPON, SNDLEVEL_LIBRARY);
				g_CTItemSelected = true;
				g_TRItemSelected = false;
				CTPrefixMenu(param1, 0);
			}
			case 1:
			{
				CT_SetDeFName(param1, 0);
				CTPrefixMenu(param1, 0);
			}
		}
	}
	if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack)
		{
			PrefixMenu(param1, 0);
			return;
		}
	}
}

public Action:TRPrefixMenu(client, args)
{
	decl String:buffer[1024];
	new String:CurrentPrefixCT[32];
	GetConVarString(g_CvarPrefixCT, CurrentPrefixCT, 32);
	new String:CurrentPrefixTR[32];
	GetConVarString(g_CvarPrefixTR, CurrentPrefixTR, 32);
	EmitSoundToClient(client, "ambient/misc/metal6.wav", SNDCHAN_WEAPON, SNDLEVEL_LIBRARY);
	new Handle:menu = CreateMenu(TRPrefixMenuHandler);

	Format(buffer, sizeof(buffer), "BotsManager :: %T", "TitlePrefixes", client);
	SetMenuTitle(menu, buffer);

	if(g_iBotTr == 0)
	{
		Format(buffer, sizeof(buffer), "%T", "ItemBotsPrefixTrNotFound", client);
		AddMenuItem(menu, "", buffer, ITEMDRAW_DISABLED);
	}
	else if(g_iBotTr != 0)
	{
		if(g_TRNamesDefault == false || !GetConVarInt(g_CvarPrefixEnable))
		{
			Format(buffer, sizeof(buffer), "%T", "ItemBotsPrefixTR", client);
			AddMenuItem(menu, "", buffer, ITEMDRAW_DISABLED);
		}
		else if(g_TRNamesDefault == true || GetConVarInt(g_CvarPrefixEnable))
		{
			Format(buffer, sizeof(buffer), "%T", "ItemBotsPrefixTR", client);
			AddMenuItem(menu, "", buffer, ITEMDRAW_DEFAULT);
		}
		if(g_TRNamesDefault == true || !GetConVarInt(g_CvarPrefixEnable))
		{
			Format(buffer, sizeof(buffer), "%T [ %s ]", "ItemBotsPrefixDeleteTR", client, CurrentPrefixTR);
			AddMenuItem(menu, "", buffer, ITEMDRAW_DISABLED);
		}
		else if(g_TRNamesDefault == false || GetConVarInt(g_CvarPrefixEnable))
		{
			Format(buffer, sizeof(buffer), "%T [ %s ]", "ItemBotsPrefixDeleteTR", client, CurrentPrefixTR);
			AddMenuItem(menu, "", buffer, ITEMDRAW_DEFAULT);
		}
	}

	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public TRPrefixMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
	{
		switch(param2)
		{
			case 0:
			{
				PrintToChat(param1, "\x04(\x03Bots Manager\x04) %t", "ChatPrefixInChatForT");
				EmitSoundToClient(param1, "ambient/misc/metal7.wav", SNDCHAN_WEAPON, SNDLEVEL_LIBRARY);
				g_TRItemSelected = true;
				g_CTItemSelected = false;
				TRPrefixMenu(param1, 0);
			}
			case 1:
			{
				TR_SetDeFName(param1, 0);
				TRPrefixMenu(param1, 0);
			}
		}
	}
	if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack)
		{
			PrefixMenu(param1, 0);
			return;
		}
	}
}

public Action:MenuRestrict(client, args)
{
	decl String:buffer[512];
	EmitSoundToClient(client, "ambient/misc/metal6.wav", SNDCHAN_WEAPON, SNDLEVEL_LIBRARY);
	new Handle:submenu = CreateMenu(MenuHandlerRestrict);
	Format(buffer, sizeof(buffer), "BotsManager :: %T", "TitleBotsWeaponRestrict", client);
	SetMenuTitle(submenu, buffer);
	if(GetConVarBool(g_CvarAllowPistols))
		Format(buffer, sizeof(buffer), "%T", "ItemBotsPistolsOn", client);
	else
		Format(buffer, sizeof(buffer), "%T", "ItemBotsPistolsOff", client);
	AddMenuItem(submenu, "", buffer);
	if(GetConVarBool(g_CvarAllowSMGS))
		Format(buffer, sizeof(buffer), "%T", "ItemBotsSMGSOn", client);
	else
		Format(buffer, sizeof(buffer), "%T", "ItemBotsSMGSOff", client);
	AddMenuItem(submenu, "", buffer);
	if(GetConVarBool(g_CvarAllowShotguns))
		Format(buffer, sizeof(buffer), "%T", "ItemBotsShotGunsOn", client);
	else
		Format(buffer, sizeof(buffer), "%T", "ItemBotsShotGunsOff", client);
	AddMenuItem(submenu, "", buffer);
	if(GetConVarBool(g_CvarAllowRifles))
		Format(buffer, sizeof(buffer), "%T", "ItemBotsRiflesOn", client);
	else
		Format(buffer, sizeof(buffer), "%T", "ItemBotsRiflesOff", client);
	AddMenuItem(submenu, "", buffer);
	if(GetConVarBool(g_CvarAllowMGS))
		Format(buffer, sizeof(buffer), "%T", "ItemBotsMGSOn", client);
	else
		Format(buffer, sizeof(buffer), "%T", "ItemBotsMGSOff", client);
	AddMenuItem(submenu, "", buffer);
	if(GetConVarBool(g_CvarAllowSnipers))
		Format(buffer, sizeof(buffer), "%T", "ItemBotsSnipersOn", client);
	else
		Format(buffer, sizeof(buffer), "%T", "ItemBotsSnipersOff", client);
	AddMenuItem(submenu, "", buffer);
	if(GetConVarBool(g_CvarAllowGrenades))
		Format(buffer, sizeof(buffer), "%T", "ItemBotsHeOn", client);
	else
		Format(buffer, sizeof(buffer), "%T", "ItemBotsHeOff", client);
	AddMenuItem(submenu, "", buffer);

	SetMenuExitBackButton(Handle:submenu,true);
	DisplayMenu(submenu,client,MENU_TIME_FOREVER);
}

public MenuHandlerRestrict(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		switch(param2)
		{
			case 0:
			{
				SetConVarBool(g_CvarAllowPistols, FlipBool(GetConVarBool(g_CvarAllowPistols)), true, true);
				if(GetConVarBool(g_CvarAllowPistols) == false)
					EmitSoundToClient(param1, "ambient/misc/metal7.wav", SNDCHAN_WEAPON, SNDLEVEL_LIBRARY);
				if(GetConVarBool(g_CvarAllowPistols) == true)
					EmitSoundToClient(param1, "ambient/misc/metal6.wav", SNDCHAN_WEAPON, SNDLEVEL_LIBRARY);
			}
			case 1:
			{
				SetConVarBool(g_CvarAllowSMGS, FlipBool(GetConVarBool(g_CvarAllowSMGS)), true, true);
				if(GetConVarBool(g_CvarAllowSMGS) == false)
					EmitSoundToClient(param1, "ambient/misc/metal7.wav", SNDCHAN_WEAPON, SNDLEVEL_LIBRARY);
				if(GetConVarBool(g_CvarAllowSMGS) == true)
					EmitSoundToClient(param1, "ambient/misc/metal6.wav", SNDCHAN_WEAPON, SNDLEVEL_LIBRARY);
			}
			case 2:
			{
				SetConVarBool(g_CvarAllowShotguns, FlipBool(GetConVarBool(g_CvarAllowShotguns)), true, true);
				if(GetConVarBool(g_CvarAllowShotguns) == false)
					EmitSoundToClient(param1, "ambient/misc/metal7.wav", SNDCHAN_WEAPON, SNDLEVEL_LIBRARY);
				if(GetConVarBool(g_CvarAllowShotguns) == true)
					EmitSoundToClient(param1, "ambient/misc/metal6.wav", SNDCHAN_WEAPON, SNDLEVEL_LIBRARY);
			}
			case 3:
			{
				SetConVarBool(g_CvarAllowRifles, FlipBool(GetConVarBool(g_CvarAllowRifles)), true, true);
				if(GetConVarBool(g_CvarAllowRifles) == false)
					EmitSoundToClient(param1, "ambient/misc/metal7.wav", SNDCHAN_WEAPON, SNDLEVEL_LIBRARY);
				if(GetConVarBool(g_CvarAllowRifles) == true)
					EmitSoundToClient(param1, "ambient/misc/metal6.wav", SNDCHAN_WEAPON, SNDLEVEL_LIBRARY);
			}
			case 4:
			{
				SetConVarBool(g_CvarAllowMGS, FlipBool(GetConVarBool(g_CvarAllowMGS)), true, true);
				if(GetConVarBool(g_CvarAllowMGS) == false)
					EmitSoundToClient(param1, "ambient/misc/metal7.wav", SNDCHAN_WEAPON, SNDLEVEL_LIBRARY);
				if(GetConVarBool(g_CvarAllowMGS) == true)
					EmitSoundToClient(param1, "ambient/misc/metal6.wav", SNDCHAN_WEAPON, SNDLEVEL_LIBRARY);
			}
			case 5:
			{
				SetConVarBool(g_CvarAllowSnipers, FlipBool(GetConVarBool(g_CvarAllowSnipers)), true, true);
				if(GetConVarBool(g_CvarAllowSnipers) == false)
					EmitSoundToClient(param1, "ambient/misc/metal7.wav", SNDCHAN_WEAPON, SNDLEVEL_LIBRARY);
				if(GetConVarBool(g_CvarAllowSnipers) == true)
					EmitSoundToClient(param1, "ambient/misc/metal6.wav", SNDCHAN_WEAPON, SNDLEVEL_LIBRARY);
			}
			case 6:
			{
				SetConVarBool(g_CvarAllowGrenades, FlipBool(GetConVarBool(g_CvarAllowGrenades)), true, true);
				if(GetConVarBool(g_CvarAllowGrenades) == false)
					EmitSoundToClient(param1, "ambient/misc/metal7.wav", SNDCHAN_WEAPON, SNDLEVEL_LIBRARY);
				if(GetConVarBool(g_CvarAllowGrenades) == true)
					EmitSoundToClient(param1, "ambient/misc/metal6.wav", SNDCHAN_WEAPON, SNDLEVEL_LIBRARY);
			}
		}
		MenuRestrict(param1, 0);
	}
	if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack)
		{
			BotsMenu_show( param1, 0);
			return;
		}
	}
}

public OnClientDisconnect(client)
{
	if (IsFakeClient(client))
	{
		new Handle:quota = FindConVar("bot_quota");
		SetConVarInt(quota, GetConVarInt(quota)-1);
	}
}

public Action:BmConfig()
{
	new String:Path[256];
	Format(Path, sizeof(Path), "cfg/sourcemod/BotsManager.cfg");
	new Handle:CfgFile = OpenFile(Path, "wt");

	WriteFileLine(CfgFile, "//////////////////////////////\n//\n//	BotsManager by tale*Quale\n//		version [%s]\n//\n//////////////////////////////\n", PLUGIN_VERSION);

	new String:chatmode[10];
	GetConVarString(g_CvarChat, chatmode, sizeof(chatmode));
	WriteFileLine(CfgFile, "\n//Разговоры ботов <...> (radio, minimal, normal, off)\n//Bots chatter <...> (radio, minimal, normal, off)\n//----------\nbot_chatter %s\n", chatmode);

	WriteFileLine(CfgFile, "\n//Сложность ботов <0|1|2|3> (0 - Лёгкие, 1 - Нормальные, 2 - Сложные, 3 - Эксперты)\n//Bots difficulty <0|1|2|3> (0 - Easy, 1 - Normal, 2 - Hard, 3 - Experts\n//----------\nbot_difficulty %i\n", GetConVarInt(g_CvarDifficulty));

	WriteFileLine(CfgFile, "\n//Изменять префикс у ботов, при добавлении на сервер? <1|0>\n//change bot prefix, at added on server? <1|0>\n//----------\nbm_prefix_enable %i\n", GetConVarInt(g_CvarPrefixEnable));

	new String:infCT[32];
	GetConVarString(g_CvarPrefixCT, infCT, sizeof(infCT));
	WriteFileLine(CfgFile, "\n//Префикс у ботов [КТ] <...>\n//[CT] bots prefix <...>\n//----------\nbm_prefix_ct %s\n", infCT);

	new String:infTR[32];
	GetConVarString(g_CvarPrefixTR, infTR, sizeof(infTR));
	WriteFileLine(CfgFile, "\n//Префикс у ботов [Т] <...>\n//[T] bots prefix <...>\n//----------\nbm_prefix_t %s\n", infTR);

	WriteFileLine(CfgFile, "\n//Включить/Выключить пинг Ботов <1|0>\n//oN/oFF Bots Ping <1|0>\n//----------\nbm_ping_enable %i\n", GetConVarInt(g_CvarBotPingEnable));
  
	WriteFileLine(CfgFile, "\n//Минимальный пинг Ботов <...>\n//Minimal Bots Ping <...>\n//----------\nbm_ping_min %i\n", GetConVarInt(g_CvarBotPingMinimum));
  
	WriteFileLine(CfgFile, "\n//Максимальный пинг Ботов <...>\n//Maximal Bots Ping <...>\n//----------\nbm_ping_max %i\n", GetConVarInt(g_CvarBotPingMaximum));

	WriteFileLine(CfgFile, "\n//Интервал в секундах между сменой пинга <...>\n//Interval Changed Bots ping (sec) <...>\n//----------\nbm_ping_interval %i\n", GetConVarInt(g_CvarBotPingInterval));

	WriteFileLine(CfgFile, "\n//Количество хп у Ботов (на каждом респе)<...>\n//Bots Health amount on spawn <...>\n//----------\nbm_bots_health %i\n", GetConVarInt(g_CvarBotRespHp));
  
	WriteFileLine(CfgFile, "\n//Количество Брони у Ботов (при покупке) <...>\n//Bots Armour amount (on buying) <...>\n//----------\nbm_bots_armr %i\n", GetConVarInt(g_CvarBotRespArmr));
  
	WriteFileLine(CfgFile, "\n//Запретить|Разрешить Ботам шлем (при покупке) <1|0>\n//Enable|Disable Bots helmet (on buying) <1|0>\n//----------\nbm_bots_helmet %i\n", GetConVarInt(g_CvarBotRespHelmet));

	WriteFileLine(CfgFile, "\n//Количество хп у Людей (на каждом респе)<...>\n//Humans Health amount on spawn <...>\n//----------\nbm_humans_health %i\n", GetConVarInt(g_CvarHumRespHp));
  
	WriteFileLine(CfgFile, "\n//Количество Брони у Людей (при покупке) <...>\n//Humans Armour amount (on buying) <...>\n//----------\nbm_humans_armr %i\n", GetConVarInt(g_CvarHumRespArmr));
  
	WriteFileLine(CfgFile, "\n//Запретить|Разрешить Людям шлем (при покупке) <1|0>\n//Enable|Disable Humans helmet (on buying) <1|0>\n//----------\nbm_humans_helmet %i\n", GetConVarInt(g_CvarHumRespHelmet));

	WriteFileLine(CfgFile, "\n//Убивать Ботов если все люди убиты? <1|0>\n//Auto Kill Bots if all humans died? <1|0>\n//----------\nbm_autokill %i\n", GetConVarInt(g_CvarAutoKill));

	WriteFileLine(CfgFile, "\n//Убивать Ботов если людей нет, но установлена бомба?\n//Auto Kill Bots if all humans dead but bomb planted? <1|0>\n//----------\nbm_autokill_bomb_planted %i\n", GetConVarInt(g_CvarAutoKillBombPlanted));

	new String:Inf[4];
	GetConVarString(g_CvarAutoKillDelay, Inf, 4);
	WriteFileLine(CfgFile, "\n//Задержка в секундах, перед тем как убить ботов (min 0.5 | max 9.0) <...>\n//Bots Auto Kill delay <...> (min 0.5 | max 9.0)\n//----------\nbm_autokill_delay %s\n", Inf);

	CloseHandle(CfgFile);
}

/************************************************************************
*	PS:																	*
*	ЕСЛИ ИЗМЕНИТЕ СДЕСЬ ИНФОРМАЦИЮ, ТО ПЛАГИН РАБОТАТЬ НЕ БУДЕТ! (=		*
*																		*
*	NOTE:																*
*	IF YOU CHANGE THIS INFO, PLUGIN WORK NOT WILL! (=					*
*																		*
*************************************************************************/

new Tick = 40;
public Action:AboutPlugin()
{
	CreateTimer(1.0, AboutPluginTimer, _, TIMER_REPEAT);
	EmitSoundToAll("music/HL2_song23_SuitSong3.mp3", SNDCHAN_WEAPON, SNDLEVEL_LIBRARY);
}

public Action:AboutPluginTimer(Handle:timer)
{
	Tick --;

	if(Tick == 39)
	{
		PrintHintTextToAll("***\nBo\n***");
		PrintToChatAll ("\x04|=========================");
	}
	if(Tick == 36)
	{
		PrintHintTextToAll("*****\nBots\n*****");
		PrintToChatAll ("\x04| \x03(̾●̮̮•̃̾)۶ Bots Manager by t*Q");
	}
	if(Tick == 33)
	{
		PrintHintTextToAll("*******\nBots Ma\n*******");
		PrintToChatAll ("\x04| \x03Version \x04%s", PLUGIN_VERSION);
	}
	if(Tick == 30)
	{
		PrintHintTextToAll("*********\nBots Manag\n*********");
		PrintToChatAll ("\x04| \x03Made in \x04Russia");
	}
	if(Tick == 27)
	{
		PrintHintTextToAll("***********\nBots Manager\n***********");
		PrintToChatAll ("\x04| \x04(©)\x03Thanks to website : \x04www.hlmod.ru");
	}
	if(Tick == 24)
	{
		PrintHintTextToAll("*************\nBots Manager by\n*************");
		PrintToChatAll ("\x04| \x03Visit this cool website \x04:)");
	}
	if(Tick == 21)
	{
		PrintHintTextToAll("***************\nBots Manager by t*Q\n***************");
		PrintToChatAll ("\x04|\x03Thanks to \x04JPe \x03autokill additions");
	}
	if(Tick == 18)
	{
		PrintHintTextToAll("***************\nBots Manager by t*Q\n***************");
		PrintToChatAll ("\x04|=========================");
	}
	if(Tick == 15)
	{
		PrintHintTextToAll("**************\nwww\n**************");
	}
	if(Tick == 12)
	{
		PrintHintTextToAll("**************\nwww.\n**************");
	}
	if(Tick == 9)
	{
		PrintHintTextToAll("**************\nwww.hlmod\n**************");
	}
	if(Tick == 6)
	{
		PrintHintTextToAll("**************\nwww.hlmod.\n**************");
	}
	if(Tick == 3)
	{
		PrintHintTextToAll("**************\nwww.hlmod.ru\n**************");
	}
	if(Tick == 0)
	{
		Tick = 40;
		EmitSoundToAll("ambient/misc/metal7.wav", SNDCHAN_WEAPON, SNDLEVEL_LIBRARY);
		PrintHintTextToAll(" \n(̾●̮̮•̃̾)۶\n ");
		PrintToChatAll ("\x03(̾●̮̮•̃̾)۶");

		return Plugin_Stop;
	}

	return Plugin_Continue;
}

//:D Пасиба за внимание
