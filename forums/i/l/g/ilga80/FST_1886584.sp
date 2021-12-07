/**************************************************************************\
*****************************ИСТОРИЯ ИЗМЕНЕНИЙ*****************************
1.0 выход плагина
1.1 RegConsoleCmd заменено на AddCommandListener
1.2 Добавлен флаг ROOT для команды !ct (Чтобы не было дизбаланса на jail)
1.3 Упрощен код. Добавлена смена команды без потери фрагов.
1.4 Добавлен файл перевода
1.5 Добавлен конфиг, возможность установить иммунитет для админка через конфиг, 
проигрывание звука запрета, информирование о доступных командах
1.6 Добавлен квар отключения плагина. Файлы перевода en & ru отделены.
1.7 Теперь квар mp_limitteams учитывается.
1.8beta Убран morecolors. Фиксы и усложнение кода.
\**************************************************************************/
#include <sourcemod>
#include <sdktools_functions>
//#include <morecolors>

//Учет квара mp_limitteams
new Handle:limitteams;
//Сообщения о смене команды
new Handle:g_chat;
//Иммунитет админа для перехода за КТ
new Handle:g_CVarAdmFlag;
new g_AdmFlag;
//Информирование о доступных командах
new Handle:g_Advert;
//Включить/выключить плагин
new Handle:g_en;

#define PLUGIN_VERSION "1.8beta"

public Plugin:myinfo =
{
	name = "Fast change team",
	author = "ilga80",
	description = "Быстрая смена команды",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=207552"
}

public OnPluginStart()
{
	limitteams = FindConVar("mp_limitteams");
	g_en = CreateConVar("sm_fst_enable" , "1", "Включить/выключить плагин", FCVAR_PLUGIN, true, 0.0, true, 1.0)
	g_chat = CreateConVar("sm_fst_msg", "1", "Включить/Выключить сообщения о смене команды", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_CVarAdmFlag = CreateConVar("sm_fst_admflag", "0", "Учитывать иммунитет админа для перехода за КТ, 0=отключить, Чтобы включить впишите нужный флаг: a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t");
	g_Advert = CreateConVar("sm_fst_advert", "1", "Включить/Выключить информирование о доступных командах", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	AddCommandListener(Command_Changeteam, "say");
	AddCommandListener(Command_Changeteam, "say_team");
	
	LoadTranslations("fast_changeteam.phrases");
	AutoExecConfig(true, "fast_changeteam");
	
	HookEvent("round_start", round_start);
	HookConVarChange(g_CVarAdmFlag, OnCVarChange);
}

public round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(g_en) == 1)
	{
		if (GetConVarBool(g_Advert)) CreateTimer(10.0, advertise, TIMER_FLAG_NO_MAPCHANGE)
	}
}

public Action:advertise(Handle:timer)
{
	PrintToChatAll("%t", "advertise");
}

public OnCVarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_AdmFlag = ReadFlagString(newValue);
}

public Action:Command_Changeteam(client, const String:command[], args)
{
	decl String:Said[64];
	GetCmdArgString(Said, sizeof(Said) - 1);
	StripQuotes(Said);
	TrimString(Said);
	new teamT = GetTeamClientCount(2);
	new teamCT = GetTeamClientCount(3);
	if(GetConVarInt(g_en) == 1)
	{
		if (client > 0)
		{
			if( StrEqual( Said, "!t", false ) || StrEqual( Said, "t", false ))
			{
				if(teamT > 0 && teamCT > 0)
				{
					if (GetClientTeam(client) != 2)
					{
						if (GetConVarInt(limitteams) >= (teamT / teamCT))
						{
							ChangeClientTeam(client, 1);
							ChangeClientTeam(client, 2);
							if (GetConVarBool(g_chat)) PrintToChat(client, "%t", "teamT");
						}
						else if (GetConVarBool(g_chat)) PrintToChat(client, "%t", "LimitT");
					}
					else if (GetConVarBool(g_chat)) PrintToChat(client, "%t", "alreadyT");
				}
				else if (GetConVarBool(g_chat)) PrintToChat(client, "%t", "teamsEmpty");
			}
			if( StrEqual( Said, "!ct", false ) || StrEqual( Said, "ct", false ))   
			{
				if(teamT > 0 && teamCT > 0)
				{
					if (GetClientTeam(client) != 3)   
					{   
						if (g_AdmFlag == 0 || (g_AdmFlag > 0 && CheckCommandAccess(client, "sm_fst_override", g_AdmFlag, true)))   
						{
							if (GetConVarInt(limitteams) >= (teamCT / teamT))
							{
								ChangeClientTeam(client, 1);
								ChangeClientTeam(client, 3);
								if (GetConVarBool(g_chat)) PrintToChat(client, "%t", "teamCT");
							}
							else if (GetConVarBool(g_chat)) PrintToChat(client, "%t", "LimitCT");
						}   
						else if (GetConVarBool(g_chat))
						{
							ClientCommand(client, "play buttons/button11.wav");
							PrintToChat(client, "%t", "No_Permission");
							return Plugin_Handled;
						}
					}   
					else if (GetConVarBool(g_chat)) PrintToChat(client, "%t", "alreadyCT");
				}
				else if (GetConVarBool(g_chat)) PrintToChat(client, "%t", "teamsEmpty");
			}
			if( StrEqual( Said, "!spec", false ) || StrEqual( Said, "spec", false ))
			{
				if (GetClientTeam(client) != 1)
				{
					ChangeClientTeam(client, 1);
					if (GetConVarBool(g_chat)) PrintToChat(client, "%t", "teamSP");
				}
				else if (GetConVarBool(g_chat)) PrintToChat(client, "%t", "alreadySP");
			}
		}
	}
	return Plugin_Continue;
}