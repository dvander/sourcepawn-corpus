#pragma semicolon 1
#pragma newdecls required

#include <sdktools_functions>

#define PL_VER "1.4 (rewritten by Grey83)"

static const float
	CHECK			= 10.0;
static const char
	PREFIX_HINT[]	= "[RegionZ]",
	PREFIX_CHAT[]	= "\x04[\x05AFK Manager\x04] \x01",
	PREFIX_CON[]	= "[AFK Manager] ";

Handle
	hTimer[MAXPLAYERS+1];
int
	iMsg,
	iTime[MAXPLAYERS+1];
float
	fAdvCD,
	fJoinTip,
	fWarning,
	fSpec[MAXPLAYERS+1],
	fAfk[MAXPLAYERS+1];

public Plugin myinfo =
{
	name = "[L4D] AFK Manager",
	version = PL_VER,
	author = "DarkWob",
	url = "http://www.regionz.ml"
}

public void OnPluginStart()
{
	CreateConVar("l4d_afkmanager_version", PL_VER, "[L4D(2)] AFK Manager", FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	ConVar cvar;
	cvar = CreateConVar("afk_adinterval", "300.0", "Interval in which the plugin will advertise the 'idle' command (x < 10.0 - disable).", _, true);
	cvar.AddChangeHook(CVarChange_Adv);
	CVarChange_Adv(cvar, NULL_STRING, NULL_STRING);

	cvar = CreateConVar("afk_spectime", "40.0", "AFK time after which you will be moved to the Spectator team.", _, true, 30.0);
	cvar.AddChangeHook(CVarChange_SpecTime);
	fAfk[0] = cvar.FloatValue;

	cvar = CreateConVar("afk_kicktime", "480.0", "AFK time after which you will be kicked.", _, true, 60.0);
	cvar.AddChangeHook(CVarChange_KickTime);
	fSpec[0] = cvar.FloatValue;

	cvar = CreateConVar("afk_messages", "3", "Control spec/kick messages. (0 = disable, 1 = spec, 2 = kick, 3 = spec + kick", _, true, _, true, 3.0);
	cvar.AddChangeHook(CVarChange_Msg);
	iMsg = cvar.IntValue;

	cvar = CreateConVar("afk_joinmsg_time", "60.0", _, _, true);
	cvar.AddChangeHook(CVarChange_JoinTip);
	fJoinTip = cvar.FloatValue;

	cvar = CreateConVar("afk_warning_time", "5.0", _, _, true);
	cvar.AddChangeHook(CVarChange_Warning);
	fWarning = cvar.FloatValue;

	HookEvent("player_team", Event_PlayerTeam);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);

	CreateTimer(CHECK, Timer_Check, _, TIMER_REPEAT);

//	AutoExecConfig(true, "l4d_afkmanager");

	RegConsoleCmd("sm_idle", Cmd_Idle, "Switches yourself to spectate mode if you are alive");
	RegConsoleCmd("sm_afk", Cmd_Idle, "Switches yourself to spectate mode if you are alive");
}

public void CVarChange_Adv(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	fAdvCD = cvar.FloatValue;
	ResetAdv();
}

public void CVarChange_SpecTime(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	fAfk[0] = cvar.FloatValue;
}

public void CVarChange_KickTime(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	fSpec[0] = cvar.FloatValue;
}

public void CVarChange_Msg(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	iMsg = cvar.IntValue;
}

public void CVarChange_JoinTip(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	fJoinTip = cvar.FloatValue;
}

public void CVarChange_Warning(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	fWarning = cvar.FloatValue;
}

public void OnMapStart()
{
	iTime[0] = GetTime();
	ResetAdv();
}

stock void ResetAdv()
{
	if(hTimer[0]) delete hTimer[0];
	if(fAdvCD >= 10.0) hTimer[0] = CreateTimer(fAdvCD, Timer_Adv, _, TIMER_REPEAT);
}

public void OnMapEnd()
{
	for(int i; i <= MaxClients; i++) OnClientDisconnect(i);
}

public void OnClientDisconnect(int client)
{
	if(hTimer[client]) delete hTimer[client];
}

public Action Cmd_Idle(int client, int args)
{
	if(!client || !IsClientValid(client))
		return Plugin_Handled;

	if(!IsPlayerAlive(client))
	{
		PrintToChat(client, "%sYou cannot use the \x04!idle \x01command while dead.", PREFIX_CHAT, client);
		return Plugin_Handled;
	}

	if(!hTimer[client])
	{
		iTime[client] = GetTime() + 15;
		hTimer[client] = CreateTimer(1.0, Timer_Idle, GetClientUserId(client), TIMER_REPEAT);
		PrintHintText(client, "%s\n After 15 seconds you will be afk.", PREFIX_HINT);
	}
	else PrintToChat(client, "%sBe patient, you have already used the \x04!idle \x01command.", PREFIX_CHAT, client);

	return Plugin_Handled;
}

public Action Timer_Idle(Handle timer, int uid)
{
	int client = GetClientUserId(uid);
	if(!client)
		return Plugin_Stop;

	if(GetClientTeam(client) < 2)
	{
		hTimer[client] = null;
		return Plugin_Stop;
	}

	int time = iTime[client] - GetTime();
	if(time > 0)
	{
		PrintHintText(client, "%s\nAfter %i seconds you will be afk.", PREFIX_CHAT, time);
		return Plugin_Continue;
	}

	Move2Spec(client);
	hTimer[client] = null;
	return Plugin_Stop;
}

public Action Timer_Adv(Handle timer)
{
	PrintToChatAll("\x04[\x05AFK Manager\x04]\x01 Use \x05!idle \x01if you plan to go AFK for a while.");
	return Plugin_Continue;
}

public Action Timer_Check(Handle timer)
{
	bool isAFK;
	for(int i = 1, j, team; i <= MaxClients; i++) if(IsClientInGame(i) && (team = IsClientValid(i)))
	{
		static float vec[3];
		if(team == 1)
		{
			fSpec[i] += CHECK;
			if(fSpec[i] >= fSpec[0])
			{
				if(GetRealClientCount() > 25 && !IsVip(i) || GetClientCount(false) > 29 && !IsRoot(i))
				{
					KickClient(i, "You were AFK for too long.");
					if(iMsg > 1) PrintToChatAll("\x04[\x05AFK Manager\x04]\x01 Player \x04'%N'\x01 was kicked.", i);
				}
				else fSpec[i] -= CHECK + 1;
			}
			else if(!IsRoot(i))
			{
				static float msg[MAXPLAYERS+1];
				vec[0] = GetClientTime(i);
				if(vec[0] - msg[i] >= fWarning)
				{
					PrintToChat(i, "%sYou can spectate for \x04%d\x01 more seconds before you will be kicked.", PREFIX_CHAT, RoundToFloor(fSpec[0] - fSpec[i]));
					msg[i] = vec[0];
				}

				if(vec[0] - msg[i] >= fJoinTip)
				{
					PrintToChat(i, "%sSay \x05!join\x01 to join game.", PREFIX_CHAT);
					msg[i] = vec[0];
				}
			}
		}
		else if(IsPlayerAlive(i))
		{
			static float pos[MAXPLAYERS+1][3], ang[MAXPLAYERS+1][3];
			isAFK = true;
			GetClientAbsOrigin(i, vec);
			for(j = 0; j < 3; j++) if(vec[j] != pos[i][j])
			{
				isAFK = false;
				pos[i] = vec;
				break;
			}

			GetClientAbsAngles(i, vec);
			if(isAFK) for(j = 0; j < 3; j++) if(vec[j] != ang[i][j])
			{
				isAFK = false;
				ang[i] = vec;
				break;
			}

			if(isAFK && (fAfk[i] += CHECK) >= fAfk[0])
			{
				if(GetClientCount(false) > 29)
				{
					KickClient(i, "Sorry, no open slots for spectators.");
					if(iMsg > 1) PrintToChatAll("%sPlayer \x04%N\x01 was kicked. No open slots for spectators.", PREFIX_CHAT, i);
				}
				else ClientAFK(i);
			}
			else fAfk[i] = 0.0;
		}
	}
	return Plugin_Continue;
}

stock void ClientAFK(int client)
{
	if(IsClientInGame(client) && IsClientValid(client))
		CreateTimer(GetRandomFloat(0.1, 5.1), Timer_Afk, GetClientUserId(client));
}

public Action Timer_Afk(Handle timer, int uid)
{
	int client = GetClientOfUserId(uid);
	if(!client || GetClientTeam(client) > 1)
		return Plugin_Stop;

	int afktime = GetTime() - iTime[0];
	if(afktime < 50)
		fAfk[client] -= CHECK + 1;
	else
	{
		if(GetClientCount(false) >= 30)
		{
			KickClient(client, "Sorry, no open slots for spectators.");
			if(iMsg > 1)
				PrintToChatAll("\x04[\x05AFK Manager\x04]\x01 Player \x04'%N'\x01 was kicked. No open slots for spectators.", client);
			return Plugin_Stop;
		}

		Move2Spec(client);
		iTime[0] = GetTime();
	}

	return Plugin_Stop;
}

stock int GetRealClientCount()
{
	int clients = 0;
	for(int i = 1; i <= MaxClients; i++) if(IsClientInGame(i) && !IsFakeClient(i)) clients++;
	return clients;
}

public Action Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int team = GetEventInt(event, "team");
	switch(team)
	{
		case 1:		fSpec[client] = 0.0;
		case 2, 3:	fAfk[client] = 0.0;
	}
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	int i = 1;
	while (i <= MaxClients)
	{
		if(IsClientInGame(i)) fAfk[i] = 0.0;
		i++;
	}
}

stock int IsClientValid(int client)
{
	if(IsFakeClient(client))
		return 0;

	int i;
	return (i = GetClientTeam(client)) > 1 ? i : 0;
}

stock bool IsVip(int client)
{
	AdminId admin = GetUserAdmin(client);
	return admin != INVALID_ADMIN_ID && GetAdminFlag(admin, Admin_Reservation);
}

stock bool IsRoot(int client)
{
	AdminId admin = GetUserAdmin(client);
	return admin != INVALID_ADMIN_ID && (GetAdminFlag(admin, Admin_Root) || GetAdminFlag(admin, Admin_Password));
}

stock void Move2Spec(int client)
{
	if(iMsg & 1) PrintToChatAll("Player \x04'%N'\x01 was moved to Spectator team.", PREFIX_CHAT, client);
	PrintToServer("%sPlayer '%N' was moved to Spectator team.", PREFIX_CON, client);
	ChangeClientTeam(client, 1);
	ForcePlayerSuicide(client);
}