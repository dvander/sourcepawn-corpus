///////////////////////////////////////////////////////
//
// License information
//
// Creative Commons Zero
// Public Domain Dedication
//
// CC0 1.0 Universal
// https://creativecommons.org/publicdomain/zero/1.0
//
///////////////////////////////////////////////////////

#include <clientprefs>
#include <sdktools_sound>
#include <sdktools_stringtables>

static const char
	PL_NAME[]	= "Hit & Kill Sounds",
	PL_VER[]	= "1.3.0_25.11.2022",

	SOUND[][]	= {"buttons/button15.wav", "buttons/button17.wav"},
	STATE[][]	= {"☐", "☑"};	// disabled/enabled setting icon

enum
{
	T_Hurt,
	T_Kill,

	T_Total,

	SPECMODE_FIRSTPERSON = 4,
	SPECMODE_3RDPERSON
};

Handle
	hCookies;
Menu
	hMenu;
bool
	bLoaded[MAXPLAYERS+1],
	bEnable[MAXPLAYERS+1],
	bSnd[T_Total][MAXPLAYERS+1];
int
	iVol[T_Total][MAXPLAYERS+1];
char
	sPath[T_Total][PLATFORM_MAX_PATH];

public Plugin myinfo =
{
	name		= PL_NAME,
	version		= PL_VER,
	description	= "Hit and kill sounds with extended features",
	author		= "Fred, Grey83",
	url			= "https://forums.alliedmods.net/showthread.php?t=298169"
}

public void OnPluginStart()
{
	CreateConVar("sm_hks_version", PL_VER, PL_NAME, FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_SPONLY);

	ConVar cvar;
	cvar = CreateConVar("sm_hks_enabled", "1", "Enable/Disable plugin", _, true, _, true, 1.0);
	cvar.AddChangeHook(CVarChange_Enable);
	CVarChange_Enable(cvar, NULL_STRING, NULL_STRING);

	cvar = CreateConVar("sm_hks_hit", "1", "Toggle hit sound", _, true, _, true, 1.0);
	cvar.AddChangeHook(CVarChange_Hurt);
	bSnd[T_Hurt][0] = cvar.BoolValue;

	cvar = CreateConVar("sm_hks_hit_path", SOUND[T_Hurt], "Hit sound file (not valid or empty = default sound)", FCVAR_PRINTABLEONLY);
	cvar.AddChangeHook(CVarChange_SndHurt);
	CVarChange_SndHurt(cvar, NULL_STRING, NULL_STRING);

	cvar = CreateConVar("sm_hks_hit_volume", "80", "Hit sound volume", _, true, 1.0, true, 100.0);
	cvar.AddChangeHook(CVarChange_VolHurt);
	SetVolume(T_Hurt, cvar.IntValue, 0);

	cvar = CreateConVar("sm_hks_kill", "1", "Toggle kill sound", _, true, _, true, 1.0);
	cvar.AddChangeHook(CVarChange_Kill);
	bSnd[T_Kill][0] = cvar.BoolValue;

	cvar = CreateConVar("sm_hks_kill_path", SOUND[T_Kill], "Kill sound file (not valid or empty = default sound)", FCVAR_PRINTABLEONLY);
	cvar.AddChangeHook(CVarChange_SndKill);
	CVarChange_SndKill(cvar, NULL_STRING, NULL_STRING);

	cvar = CreateConVar("sm_hks_kill_volume", "80", "Kill sound volume", _, true, 1.0, true, 100.0);
	cvar.AddChangeHook(CVarChange_VolKill);
	SetVolume(T_Kill, cvar.IntValue, 0);

	cvar = CreateConVar("sm_hks_observe", "1", "Can the player hear the sounds of the player they are spectating", _, true, _, true, 1.0);
	cvar.AddChangeHook(CVarChange_Observe);
	bLoaded[0] = cvar.BoolValue;

	AutoExecConfig(true, "hitkillsounds");

	hCookies = RegClientCookie("hitkillsounds", "Hit & Kill Sounds clients settings", CookieAccess_Private);
	SetCookieMenuItem(Cookie_Settings, 0, PL_NAME);
	RegConsoleCmd("sm_hks", Cmd_Menu, "Show 'Hit & Kill Sounds' settings menu");
}

public void CVarChange_Enable(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	bEnable[0] = cvar.BoolValue;

	static bool hooked[T_Total];
	if(bEnable[0])
	{
		if(!hooked[T_Hurt]) hooked[T_Hurt] = HookEventEx("player_hurt", Event_Attack);
		if(!hooked[T_Kill]) hooked[T_Kill] = HookEventEx("player_death", Event_Attack);
	}
	else if(hooked[T_Hurt] || hooked[T_Kill])
	{
		hooked[T_Hurt] = hooked[T_Kill] = false;
		UnhookEvent("player_hurt", Event_Attack);
		UnhookEvent("player_death", Event_Attack);
	}
}

public void CVarChange_Hurt(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	bSnd[T_Hurt][0] = cvar.BoolValue;
}

public void CVarChange_SndHurt(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	PrepareSound(cvar, T_Hurt);
}

public void CVarChange_VolHurt(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	SetVolume(T_Hurt, cvar.IntValue, 0);
}

public void CVarChange_Kill(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	bSnd[T_Kill][0] = cvar.BoolValue;
}

public void CVarChange_SndKill(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	PrepareSound(cvar, T_Kill);
}

public void CVarChange_VolKill(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	SetVolume(T_Kill, cvar.IntValue, 0);
}

public void CVarChange_Observe(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	bLoaded[0] = cvar.BoolValue;
}

stock void PrepareSound(ConVar cvar, const int type)
{
	cvar.GetString(sPath[type], sizeof(sPath[]));

	int len = strlen(sPath[type]) - 4;
	if(len < 1 || strcmp(sPath[type][len], ".mp3", false) && strcmp(sPath[type][len], ".wav", false))
		FormatEx(sPath[type], sizeof(sPath[]), SOUND[type]);

	if(!PrecacheSound(sPath[type])) LogError("Can't precache sound \"%s\"", sPath[type]);

	char path[PLATFORM_MAX_PATH];
	FormatEx(path, sizeof(path), "sound/%s", sPath[type]);
	AddFileToDownloadsTable(path);
}

stock void SetVolume(int type, int val, int client)
{
	if(client)
	{
		if(val > 100) val = 100;
		else if(val < 0) val = 0;
	}

	iVol[type][client] = val;
}

public void Event_Attack(Event event, const char[] name, bool dontBroadcast)
{
	int type = name[7] == 'h' ? T_Hurt : T_Kill;
	if(type == T_Hurt && event.GetInt("health") < 1)
		return;

	int client = GetClientOfUserId(event.GetInt("attacker"));
	if(!client || !IsClientInGame(client) || GetClientTeam(client) < 2)
		return;

	int id = bLoaded[client] ? client : 0;
	if(!IsFakeClient(client) && bSnd[type][id])
		EmitSoundToClient(client, sPath[type], _, SNDCHAN_BODY, _, _, (iVol[type][id] * 0.01));
	if(!IsPlayerAlive(client))
		return;

	for(int i = 1, mode; i <= MaxClients; i++)
		if(i != client && IsClientInGame(i) && CanHear(i, type) && IsClientObserver(i)
		&& ((mode = GetEntProp(i, Prop_Send, "m_iObserverMode")) == SPECMODE_FIRSTPERSON || mode == SPECMODE_3RDPERSON)
		&& GetEntPropEnt(i, Prop_Send, "m_hObserverTarget") == client)
		{
			id = bLoaded[client] ? client : 0;
			EmitSoundToClient(client, sPath[type], _, SNDCHAN_BODY, _, _, (iVol[type][id] * 0.01));
		}
}

stock bool CanHear(int client, int type)
{
	return !bLoaded[client] && bLoaded[0] && bSnd[type][0] || bLoaded[client] && bEnable[client] && bSnd[type][client];
}

public void OnClientDisconnect(int client)
{
	bLoaded[client] = false;
}

public void OnClientCookiesCached(int client)
{
	if(!client || IsFakeClient(client))
		return;

	static char buffer[12], cell[5][4];	// "1;64;1;64;1" 0x64 = 100
	GetClientCookie(client, hCookies, buffer, sizeof(buffer));
	if(strlen(buffer) != 11 || buffer[1] != ';' || buffer[4] != ';' || buffer[6] != ';' || buffer[9] != ';'
	|| ExplodeString(buffer, ";", cell, sizeof(cell), sizeof(cell[])) != 5
	|| strlen(cell[0]) != 1 || strlen(cell[1]) != 2 || strlen(cell[2]) != 1 || strlen(cell[3]) != 2 || strlen(cell[4]) != 1)
	{
		SetClientCookie(client, hCookies, "");
		return;
	}

	bLoaded[client] = true;

	bSnd[T_Hurt][client] = cell[0][0] != '0';
	SetVolume(T_Hurt, StringToInt(cell[1], 16)+1, client);
	bSnd[T_Kill][client] = cell[2][0] != '0';
	SetVolume(T_Kill, StringToInt(cell[3], 16)+1, client);
	bEnable[client] = cell[4][0] != '0';
}

public void Cookie_Settings(int client, CookieMenuAction action, any info, char[] buffer, int maxlen)
{
	if(action == CookieMenuAction_SelectOption) SendMenu(client);
}

public Action Cmd_Menu(int client, int args)
{
	if(bEnable[0]) SendMenu(client);
	return Plugin_Handled;
}

stock void SendMenu(int client)
{
	if(!client || !IsClientInGame(client) || IsFakeClient(client))
		return;

	if(!hMenu)
	{
		hMenu = new Menu(Menu_Settings, MENU_ACTIONS_ALL);
		hMenu.SetTitle("%s\n \n    Hit:", PL_NAME);
		hMenu.AddItem("", "Sound");
		hMenu.AddItem("", "+5\n    Volume:");
		hMenu.AddItem("", "-5\n \n    Kill:");
		hMenu.AddItem("", "Sound");
		hMenu.AddItem("", "+5\n    Volume:");
		hMenu.AddItem("", "-5\n");
		hMenu.AddItem("", "Observe");
		hMenu.ExitBackButton = true;
	}
	hMenu.Display(client, MENU_TIME_FOREVER);
}

public int Menu_Settings(Menu menu, MenuAction action, int client, int param)
{
	if(!bLoaded[client])
	{
		bLoaded[client] = true;

		bSnd[T_Hurt][client] = bSnd[T_Hurt][0];
		iVol[T_Hurt][client] = iVol[T_Hurt][0];
		bSnd[T_Kill][client] = bSnd[T_Kill][0];
		iVol[T_Kill][client] = iVol[T_Kill][0];
		bEnable[client] = bLoaded[0];
	}

	static char txt[PLATFORM_MAX_PATH];
	switch(action)
	{
		case MenuAction_DisplayItem:
		{
			switch(param)
			{
				case 0: FormatEx(txt, sizeof(txt), "Sound %s", STATE[view_as<int>(bSnd[T_Hurt][client])]);
				case 1: FormatEx(txt, sizeof(txt), "+5\n    Volume: %i", iVol[T_Hurt][client]);
				case 3: FormatEx(txt, sizeof(txt), "Sound %s", STATE[view_as<int>(bSnd[T_Kill][client])]);
				case 4: FormatEx(txt, sizeof(txt), "+5\n    Volume: %i", iVol[T_Kill][client]);
				case 6: FormatEx(txt, sizeof(txt), "Observe %s", STATE[view_as<int>(bEnable[client])]);
			}
			return RedrawMenuItem(txt);
		}
		case MenuAction_DrawItem:
			return !bEnable[0]
				|| (param == 1 || param == 2) && !bSnd[T_Hurt][client]
				|| (param == 4 || param == 5) && !bSnd[T_Kill][client] ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT;
		case MenuAction_Select:
		{
			switch(param)
			{
				case 0,3:	bSnd[param ? T_Kill : T_Hurt][client] ^= true;
				case 1:		SetVolume(T_Hurt, iVol[T_Hurt][client] + 5, client);
				case 2:		SetVolume(T_Hurt, iVol[T_Hurt][client] - 5, client);
				case 4:		SetVolume(T_Hurt, iVol[T_Kill][client] + 5, client);
				case 5:		SetVolume(T_Hurt, iVol[T_Kill][client] - 5, client);
				case 6:		bEnable[client] ^= true;
			}
			FormatEx(txt, sizeof(txt), "%b;%02x;%b;%02x;%b", bSnd[T_Hurt][client], iVol[T_Hurt][client], bSnd[T_Kill][client], iVol[T_Kill][client], bEnable[client]);
			SetClientCookie(client, hCookies, txt);
			SendMenu(client);
		}
		case MenuAction_Cancel: if(param == MenuCancel_ExitBack) ShowCookieMenu(client);
	}
	return 0;
}