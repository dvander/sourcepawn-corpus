#pragma semicolon 1
#pragma newdecls required

#include <clientprefs>

#define SPECMODE_FIRSTPERSON	4
#define SPECMODE_3RDPERSON		5

#define UPDATE_INTERVAL 2.5

Handle
	hCookie,
	hTimer;
ArrayList
	hSpec;
bool
	bLate,
	speclist_stealth[MAXPLAYERS + 1];

public Plugin myinfo =
{
	name	= "[CS:GO] HintSpecList",
	version	= "7.0",
	author	= "cra88y, Grey83"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	bLate = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	hSpec = new ArrayList();

	RegConsoleCmd("sm_speclist", Cmd_SpecList);

	RegAdminCmd("sm_stealth", Cmd_Stealth, ADMFLAG_BAN);
	RegAdminCmd("sm_spec", Cmd_Stealth, ADMFLAG_BAN);

	hCookie = RegClientCookie("Speclist_Enabled", "Speclist on or off", CookieAccess_Protected);

	if(!bLate) return;

	for(int i = 1; i <= MaxClients; i++) if(IsClientInGame(i) && !IsFakeClient(i) && AreClientCookiesCached(i))
		OnClientCookiesCached(i);
}

public void OnMapStart()
{
	hSpec.Clear();
	hTimer = null;
}

public void OnClientPostAdminCheck(int client)
{
	if(IsFakeClient(client)) return;

	hSpec.Push(GetClientUserId(client));

	CreateHintTimer();
}

public void OnClientCookiesCached(int client)
{
	if(IsFakeClient(client)) return;

	static char buffer[4];
	GetClientCookie(client, hCookie, buffer, sizeof(buffer));
	int uid = GetClientUserId(client);
	if(buffer[0] != '0' && hSpec.FindValue(uid) == -1) hSpec.Push(uid);
}

public void OnClientDisconnect(int client)
{
	speclist_stealth[client] = false;

	int index;
	if(!IsFakeClient(client) && (index = hSpec.FindValue(GetClientUserId(client))) != -1) hSpec.Erase(index);
	RemoveTimer();
}

public Action Cmd_Stealth(int client, int args)
{
	if(!client || IsFakeClient(client))
		return Plugin_Handled;

	if((speclist_stealth[client] ^= true))
		ReplyToCommand(client, "\x01[\x02SpecList\x01] Zostaniesz teraz ukryty przed speclist.");
	else ReplyToCommand(client, "\x01[\x02SpecList\x01] Zostaniesz teraz pokazany na speclist.");

	return Plugin_Handled;
}

public Action Cmd_SpecList(int client, int args)
{
	if(!client || IsFakeClient(client))
		return Plugin_Handled;

	int uid = GetClientUserId(client), index = hSpec.FindValue(uid);
	if(index != -1)
	{
		hSpec.Erase(index);
		RemoveTimer();
		if(!IsPlayerAlive(client) && IsSpectator(client)) PrintHintText(client, "");

		ReplyToCommand(client, "\x01[\x02SpectList\x01] Spectator list disabled.");
		SetClientCookie(client, hCookie, "0");
	}
	else
	{
		hSpec.Push(uid);
		CreateHintTimer();
		SendHint(client);

		ReplyToCommand(client, "\x01[\x02SpecList\x01] Spectator list enabled.");
		SetClientCookie(client, hCookie, "1");
	}

	return Plugin_Handled;
}

stock void CreateHintTimer()
{
	if(!hTimer && hSpec.Length)
		hTimer = CreateTimer(UPDATE_INTERVAL, Timer_UpdateHint, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

stock void RemoveTimer()
{
	if(hTimer && !hSpec.Length) delete hTimer;
}

public Action Timer_UpdateHint(Handle timer)
{
	for(int i, client, num = hSpec.Length; i < num; i++) if((client = GetClientOfUserId(hSpec.Get(i)))) SendHint(client);

	return Plugin_Continue;
}

stock void SendHint(int client)
{
	static char szText[2048];
	szText[0] = 0;

	if(!IsPlayerAlive(client) && IsSpectator(client))
	{
		for(int i = 1, target = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget"); i <= MaxClients; i++)
			if(IsClientInGame(i) && !speclist_stealth[i] && IsClientObserver(i) && IsSpectator(i)
			&& GetEntPropEnt(i, Prop_Send, "m_hObserverTarget") == target)
			{
				if(CheckCommandAccess(i, "", ADMFLAG_UNBAN))		// IsPlayerAdmin
					Format(szText, sizeof(szText), "%s<font color='#21618C'>%N.</font> ", szText, i);
				else if(CheckCommandAccess(i, "", ADMFLAG_CUSTOM1))	// IsPlayerVip
					Format(szText, sizeof(szText), "%s<font color='#D4AC0D'>%N.</font> ", szText, i);
				else Format(szText, sizeof(szText), "%s%N. ", szText, i);
			}

		if(szText[0]) PrintHintText(client, "<font size='12'><u>Spectators:\n</u></font><font size='15'>%s</font>", szText);
	}
}

stock bool IsSpectator(int client)
{
	static int mode;
	return (mode = GetEntProp(client, Prop_Send, "m_iObserverMode")) == SPECMODE_FIRSTPERSON || mode == SPECMODE_3RDPERSON;
}