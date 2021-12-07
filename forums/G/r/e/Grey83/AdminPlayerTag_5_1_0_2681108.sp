#pragma semicolon 1
#pragma newdecls required

#include <cstrike>

static const char
	PL_NAME[]	= "Admin & PlayerTags",
	PL_VER[]	= "5.1.0";

bool
	bEnable,
	bTeam;

public Plugin myinfo =
{
	name		= PL_NAME,
	description	= "Define player tags in stats with translation",
	author		= "shanapu (rewritten by Grey83)",
	version		= PL_VER,
	url			= "https://steamcommunity.com/groups/grey83ds"
}

public void OnPluginStart()
{
	EngineVersion ev = GetEngineVersion();
	if(ev != Engine_CSS && ev != Engine_CSGO) SetFailState("Plugin for CS:S & CS:GO only!");

	LoadTranslations("AdminPlayerTags.phrases");

	CreateConVar("sm_admintag_version", PL_VER, PL_NAME, FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	ConVar cvar;
	cvar = CreateConVar("sm_admintag_enable", "1", "0 - disabled, 1 - enable plugin", _, true, _, true, 1.0);
	cvar.AddChangeHook(CVarChanged_Enable);
	bEnable = cvar.BoolValue;

	cvar = CreateConVar("sm_admintag_team", "1", "0 - disabled, 1 - overwrite/remove Tags for non admin(CT/T)", _, true, _, true, 1.0);
	cvar.AddChangeHook(CVarChanged_Team);
	bTeam = cvar.BoolValue;

	HookEvent("player_connect", Event_CheckTag, EventHookMode_PostNoCopy);
	HookEvent("player_team", Event_CheckTag, EventHookMode_PostNoCopy);
	HookEvent("player_spawn", Event_CheckTag, EventHookMode_PostNoCopy);
	HookEvent("round_start", Event_CheckTag, EventHookMode_PostNoCopy);
}

public void CVarChanged_Enable(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	bEnable = cvar.BoolValue;
}

public void CVarChanged_Team(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	bTeam = cvar.BoolValue;
}

public void OnClientPutInServer(int client)
{
	if(bEnable) HandleTag(client);
}

public Action Event_CheckTag(Event event, char[] name, bool dontBroadcast)
{
	if(bEnable) CreateTimer(0.1, DelayCheck, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action DelayCheck(Handle timer) 
{
	for(int i = 1; i <= MaxClients; i++) if(IsClientInGame(i)) HandleTag(i);
}

public void HandleTag(int client)
{
	if(!bTeam && IsFakeClient(client))
		return;

	static char tag[128];
	tag[0] = 0;

	if(GetUserFlagBits(client) & ADMFLAG_ROOT)
		FormatEx(tag, sizeof(tag), "%t" ,"tags_HADM", LANG_SERVER);
	else if(GetUserFlagBits(client) & ADMFLAG_BAN)
		FormatEx(tag, sizeof(tag), "%t" ,"tags_CADM", LANG_SERVER);
	else if(GetUserFlagBits(client) & ADMFLAG_GENERIC)
		FormatEx(tag, sizeof(tag), "%t" ,"tags_ADM", LANG_SERVER);
	else if(GetUserFlagBits(client) & ADMFLAG_CUSTOM4)
		FormatEx(tag, sizeof(tag), "%t" ,"tags_UVIP", LANG_SERVER);
	else if(GetUserFlagBits(client) & ADMFLAG_CUSTOM5)
		FormatEx(tag, sizeof(tag), "%t" ,"tags_SVIP", LANG_SERVER);
	else if(GetUserFlagBits(client) & ADMFLAG_RESERVATION)
		FormatEx(tag, sizeof(tag), "%t" ,"tags_VIP", LANG_SERVER);
	else if(bTeam)
	{
		switch(GetClientTeam(client))
		{
			case CS_TEAM_T:		FormatEx(tag, sizeof(tag), "%t" ,"tags_T", LANG_SERVER);
			case CS_TEAM_CT:	FormatEx(tag, sizeof(tag), "%t" ,"tags_CT", LANG_SERVER);
		}
	}
	else return;

	CS_SetClientClanTag(client, tag);
}