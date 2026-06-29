#pragma semicolon 1
#pragma newdecls required

#include <cstrike>

enum
{
	F_Admin,
	F_Reserve,
	F_None,

	F_Total
}

bool bEnable;
char sTag[F_Total][MAX_NAME_LENGTH];

public Plugin myinfo = 
{
	name		= "Custom Clan Tag",
	version		= "1.0.1",
	author		= "Munoon",
	description	= "Plugin switch player clan tag Ddepending on his role"
};

public void OnPluginStart()
{
	EngineVersion g_Game = GetEngineVersion();
	if(g_Game != Engine_CSGO && g_Game != Engine_CSS) SetFailState("This plugin is for CSGO/CSS only.");

	ConVar CVar;
	(CVar = CreateConVar("custom_clantag_enable", "1", "On/Off plugin", _, true, _, true, 1.0)).AddChangeHook(CVarChanged_Enable);
	CVarChanged_Enable(CVar, "", "");

	(CVar = CreateConVar("custom_clantag_admin", "ADMIN", "Clan tag to be set for admin", FCVAR_PRINTABLEONLY)).AddChangeHook(CVarChanged_Admin);

	(CVar = CreateConVar("custom_clantag_reserve", "RESERVE", "Clan tag to be set for player with reserve slot", FCVAR_PRINTABLEONLY)).AddChangeHook(CVarChanged_Reserve);

	(CVar = CreateConVar("custom_clantag_base", "PLAYER", "Clan tag to be set for other players", FCVAR_PRINTABLEONLY)).AddChangeHook(CVarChanged_Base);

	AutoExecConfig(true, "custom_clantag");
}

public void CVarChanged_Enable(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	bEnable = CVar.BoolValue;

	static bool hooked;
	if(hooked == bEnable) return;

	if((hooked = !hooked))
		HookEvent("player_team", Event_Team);
	else UnhookEvent("player_team", Event_Team);
}

public void CVarChanged_Admin(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	CVar.GetString(sTag[F_Admin], sizeof(sTag[]));
}

public void CVarChanged_Reserve(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	CVar.GetString(sTag[F_Reserve], sizeof(sTag[]));
}

public void CVarChanged_Base(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	CVar.GetString(sTag[F_None], sizeof(sTag[]));
}

public void Event_Team(Event event, const char[] name, bool dontBroadcast)
{
	static int client, tag;
	if(event.GetBool("disconnect") || !(client = GetClientOfUserId(event.GetInt("userid"))))
		return;

	tag = GetUserFlagBits(client);
	if(tag & ADMFLAG_GENERIC)
		tag = F_Admin;
	else if(tag & ADMFLAG_RESERVATION)
		tag = F_Reserve;
	else tag = F_None;

	CS_SetClientClanTag(client, sTag[tag]);
}