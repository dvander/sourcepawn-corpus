#pragma semicolon 1
#pragma newdecls required

#include <geoip>
#include <sdktools_functions>

static const char
	PL_NAME[]	= "Country Nick",
	PL_VER[]	= "1.2.4_21.11.2021",

	SEPARATOR[]	= "--+-+---+-----------------+---------------+----+-------------------------------";

static const int
	HOOKS[]		= {'[', ']'};

bool
	bLate,
	bLongTag,
	bMsg;

public Plugin myinfo =
{
	name		= PL_NAME,
	version		= PL_VER,
	description	= "Add country of the player near his nick",
	author		= "Antoine LIBERT aka AeN0 (rewrited by Grey83)",
	url			= "https://forums.alliedmods.net/showthread.php?p=738756"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	bLate = late;
}

public void OnPluginStart()
{
	LoadTranslations("countrynick.phrases");

	CreateConVar("countrynick_version", PL_VER, PL_NAME, FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_SPONLY);

	ConVar cvar;
	cvar = CreateConVar("sm_countrynick_tagsize", "3", "Size of the country tag", _, true, 2.0, true, 3.0);
	cvar.AddChangeHook(CVarChanged_Size);
	bLongTag = cvar.IntValue == 3;

	cvar = CreateConVar("sm_countrynick_msg", "1", "1/0 - Switch On/Off announcement connecting of a players (and error logging)", _, true, _, true, 1.0);
	cvar.AddChangeHook(CVarChanged_Msg);
	bMsg = cvar.BoolValue;

	RegAdminCmd("list", Cmd_List, ADMFLAG_GENERIC, "Show info about players (Admin or  non-admin, UserID, IP, Country, SteamID, Nick) on the server");

	HookEvent("player_changename", Event_PlayerChangename, EventHookMode_Pre);

	AutoExecConfig(true, "countrynick");

	if(bLate)
	{
		RefreshNames();
		bLate = false;
	}
}

public void CVarChanged_Size(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	if(bLongTag != (bLongTag = cvar.IntValue == 3)) RefreshNames();
}

stock void RefreshNames()
{
	char name[MAX_NAME_LENGTH];
	for(int i = 1; i <= MaxClients; i++) if(IsClientInGame(i) && !IsFakeClient(i) && GetClientName(i, name, sizeof(name)))
		SetNewName(i, name);
}

public void CVarChanged_Msg(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	bMsg = cvar.BoolValue;
}

public Action Cmd_List(int client, int args)
{
	PrintToConsole(client, SEPARATOR);
	PrintToConsole(client, " # A %-3.3s %-17.17s %-15.15s %-4.4s %s", "UID", "SteamID", "IP", "From", "Nick");
	PrintToConsole(client, SEPARATOR);

	bool find;
	char IP[16], SId[18], name[29], code[4];
	for(int i = 1, admin, num; i <= MaxClients; i++) if(IsClientInGame(i))
	{
		num++;
		if(!IsFakeClient(i))
		{
			admin = GetUserAdmin(i) == INVALID_ADMIN_ID ? '-' : 'A';
			GetClientIP(i, IP, sizeof(IP));
			find = GeoipCode3(IP, code);
			GetClientAuthId(i, AuthId_SteamID64, SId, sizeof(SId));
		}
		else
		{
			admin = ' ';
			strcopy(IP, 16, "Bot");
			find = true;
			code[0] = 0;
			SId[0] = 0;
		}
		GetClientName(i, name, sizeof(name));
		PrintToConsole(client, "%2.2d %c %3.3d %-17.17s %-15.15s %-4.4s %-30.30s", num, admin, GetClientUserId(i), SId, IP, find ? code : "-?-", name[GetPos(name)]);
	}

	PrintToConsole(client, SEPARATOR);
}

public void OnClientPutInServer(int client)
{
	if(!client || IsFakeClient(client))
		return;

	char name[MAX_NAME_LENGTH];
	if(GetClientName(client, name, sizeof(name))) SetNewName(client, name);

	if(!bMsg)
		return;

	char ip[16], country[45];
	GetClientIP(client, ip, sizeof(ip)); 
	if(GeoipCountry(ip, country, sizeof(country)))
		PrintToChatAll("\x03%t", "Announcer country found", client, country);
	else
	{
		PrintToChatAll("\x03%t", "Announcer country not found", client);
		LogError("[Country Nick] Warning : %L uses %s that is not listed in GEOIP database", client, ip);
	}
}

public Action Event_PlayerChangename(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!client || IsFakeClient(client))
		return Plugin_Continue;

	char new_name[MAX_NAME_LENGTH];
	GetEventString(event, "newname", new_name, sizeof(new_name));
	SetNewName(client, new_name);

	return Plugin_Changed;	// avoid printing the change to the chat
}

stock void SetNewName(int client, char[] name)
{
	static char ip[16];
	if(!GetClientIP(client, ip, sizeof(ip)))
		return;

	static char code[4];
	if(!(bLongTag ? GeoipCode3(ip, code) : GeoipCode2(ip, code)))
		FormatEx(code, sizeof(code), "-%s-", bLongTag ? "?" : "");

	Format(name, MAX_NAME_LENGTH, "%c%s%c%s", HOOKS[0], code, HOOKS[1], name[GetPos(name)]);
	SetClientInfo(client, "name", name);
}

stock int GetPos(char[] name)
{
	static int pos;
	pos = 0;
	if(name[0] == HOOKS[0])
	{
		if(name[3] == HOOKS[1])
			pos = 4;
		else if(name[4] == HOOKS[1])
			pos = 5;
	}

	return pos;
}