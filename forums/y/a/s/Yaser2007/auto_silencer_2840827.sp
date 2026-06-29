#include <clientprefs>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_NAME "Auto Silencer"

Cookie g_cookieAutoSilencer;

bool g_bAutoSilencer[MAXPLAYERS+1];
char g_sSavedValue[5];

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = "Yaser2007",
	description = "Auto silencer for M4A1 and USP weapon.",
	version = "1.1",
	url = "https://www.sourcemod.net/plugins.php?cat=0&mod=-1&title=&author=Yaser2007&description=&search=1"
};

public void OnPluginStart()
{
	g_cookieAutoSilencer = RegClientCookie(PLUGIN_NAME, "Silencer Cookie", CookieAccess_Private);
	SetCookieMenuItem(AutoSilencerCallback, 0, PLUGIN_NAME);

	RegConsoleCmd("as", Cmd_CookieAutoSilencer);

	for(int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i) || IsFakeClient(i))
		{
			continue;
		}

		OnClientPutInServer(i);
	}
}

public void AutoSilencerCallback(int client, CookieMenuAction action, any info, char[] buffer, int maxlen)
{
	if(action == CookieMenuAction_DisplayOption)
	{
		FormatEx(buffer, maxlen, PLUGIN_NAME ... ": %s", g_bAutoSilencer[client] == true ? "Enable" : "Disable", client);
	}
	else
	{
		g_bAutoSilencer[client] = g_bAutoSilencer[client] != false ? true : false;

		IntToString(view_as<bool>(g_bAutoSilencer[client]), g_sSavedValue, sizeof(g_sSavedValue));
		SetClientCookie(client, g_cookieAutoSilencer, g_sSavedValue);

		ShowCookieMenu(client);
	}
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_WeaponEquip, Hook_OnWeaponEquip);

	OnClientCookiesCached(client);
}

public void OnClientCookiesCached(int client)
{
	if(AreClientCookiesCached(client) && IsClientInGame(client) && !IsFakeClient(client))
	{
		LoadAutoSilencerCookie(client);
	}
}

void LoadAutoSilencerCookie(int client)
{
	char buffer[5];
	GetClientCookie(client, g_cookieAutoSilencer, buffer, sizeof(buffer));
	g_bAutoSilencer[client] = !StrEqual(buffer, NULL_STRING) ? view_as<bool>(StringToInt(buffer)) : true;
}

public Action Cmd_CookieAutoSilencer(int client, int args)
{
	if(g_bAutoSilencer[client] != false)
	{
		g_bAutoSilencer[client] = false;
		ReplyToCommand(client, "\x04" ... PLUGIN_NAME ... " disabled");
	}
	else
	{
		g_bAutoSilencer[client] = true;
		ReplyToCommand(client, "\x04" ... PLUGIN_NAME ... " enabled");
	}

	IntToString(view_as<bool>(g_bAutoSilencer[client]), g_sSavedValue, sizeof(g_sSavedValue));
	SetClientCookie(client, g_cookieAutoSilencer, g_sSavedValue);

	return Plugin_Handled;
}

public Action Hook_OnWeaponEquip(int client, int weapon)
{
	char sWeapon[16];
	GetEdictClassname(weapon, sWeapon, sizeof(sWeapon));
	if(StrEqual(sWeapon, "weapon_m4a1") || StrEqual(sWeapon, "weapon_usp"))
	{
		if(g_bAutoSilencer[client] != false)
		{
			SetEntProp(weapon, Prop_Send, "m_bSilencerOn", 1);
			SetEntProp(weapon, Prop_Send, "m_weaponMode", 1);
		}
	}

	return Plugin_Continue;
}