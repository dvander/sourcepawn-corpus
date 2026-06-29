#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_NAME "Donations Control Plugin"
#define PLUGIN_VERSION "1.0.0"

new Handle:hConVars[6] = {INVALID_HANDLE, ...};

new bool:cv_bEnabled, String:cv_sURL[255], bool:cv_bFullScreen, bool:cv_bAdvertStatus, Float:cv_fAdvertTime, cv_iMinimumAmount;

new Handle:hDisplayMenu = INVALID_HANDLE;
new Handle:hAdvertTimer = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = "Keith Warren (Drixevel) & NineteenEleven",
	description = "Allows clients to donate via the Donations Control Panel script in-game.",
	version = PLUGIN_VERSION,
	url = "http://www.drixevel.com/"
}

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("donationcontrol.phrases");

	CreateConVar("donations_control_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_DONTRECORD);
	hConVars[0] = CreateConVar("sm_kpanel_enable", "1", "Enable or disable plugin", 0, true, 0.0, true, 1.0);
	hConVars[1] = CreateConVar("sm_kpanel_url", "https://website.com/donations", "URL to your Donations Control installation.");
	hConVars[2] = CreateConVar("sm_kpanel_fullscreen", "1", "Enable or disable fullscreen windows", 0, true, 0.0, true, 1.0);
	hConVars[3] = CreateConVar("sm_kpanel_advertisement", "1", "Display plugin creator advertisement: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hConVars[4] = CreateConVar("sm_kpanel_advertisement_time", "120.0", "Timer between messages: (1.0 + )", FCVAR_PLUGIN, true, 1.0);
	hConVars[5] = CreateConVar("sm_kpanel_minimum", "4", "Minimum amount to donate: (Default: 4, Less than or equal to)", FCVAR_PLUGIN, true, 1.0);

	for (new i = 0; i < sizeof(hConVars); i++)
	{
		HookConVarChange(hConVars[i], HandleCvars);
	}

	RegConsoleCmd("sm_donate", DonatePanel);

	AutoExecConfig(true, "plugin.donation.control");
}

public OnConfigsExecuted()
{
	cv_bEnabled = GetConVarBool(hConVars[0]);
	GetConVarString(hConVars[1], cv_sURL, sizeof(cv_sURL));
	cv_bFullScreen = GetConVarBool(hConVars[2]);
	cv_bAdvertStatus = GetConVarBool(hConVars[3]);
	cv_fAdvertTime = GetConVarFloat(hConVars[4]);
	cv_iMinimumAmount = GetConVarInt(hConVars[5]);

	if (cv_bEnabled)
	{
		if (cv_bAdvertStatus && cv_fAdvertTime > 1.0)
		{
			ClearTimer(hAdvertTimer);
			hAdvertTimer = CreateTimer(cv_fAdvertTime, TimerAdvertisement, INVALID_HANDLE, TIMER_REPEAT);
		}

		hDisplayMenu = CreateMenu(MenuHandle);

		SetMenuTitle(hDisplayMenu, "%s", "Menu Title");

		AddMenuItem(hDisplayMenu, "5", "5");
		AddMenuItem(hDisplayMenu, "10", "10");
		AddMenuItem(hDisplayMenu, "15", "15");
		AddMenuItem(hDisplayMenu, "20", "20");

		SetMenuExitButton(hDisplayMenu, true);
	}
}

public HandleCvars (Handle:cvar, const String:sOldValue[], const String:sNewValue[])
{
	if (StrEqual(sOldValue, sNewValue, true)) return;

	new iNewValue = StringToInt(sNewValue);

	if (cvar == hConVars[0])
	{
		cv_bEnabled = bool:iNewValue;
		switch (cv_bEnabled)
		{
			case true: hAdvertTimer = CreateTimer(cv_fAdvertTime, TimerAdvertisement, _, TIMER_REPEAT);
			case false: ClearTimer(hAdvertTimer);
		}
	}
	if (cvar == hConVars[1])
	{
		strcopy(cv_sURL, sizeof(cv_sURL), sNewValue);
	}
	if (cvar == hConVars[2])
	{
		cv_bFullScreen = bool:iNewValue;
	}
	if (cvar == hConVars[3])
	{
		cv_bAdvertStatus = bool:iNewValue;
		switch (cv_bAdvertStatus)
		{
			case true: hAdvertTimer = CreateTimer(cv_fAdvertTime, TimerAdvertisement, _, TIMER_REPEAT);
			case false: ClearTimer(hAdvertTimer);
		}
	}
	if (cvar == hConVars[4])
	{
		cv_fAdvertTime = StringToFloat(sNewValue);
		ClearTimer(hAdvertTimer);
		hAdvertTimer = CreateTimer(cv_fAdvertTime, TimerAdvertisement, _, TIMER_REPEAT);
	}
}

public Action: DonatePanel(client, args)
{
	if (!cv_bEnabled || !IsClientInGame(client)) return Plugin_Handled;

	if (!args)
	{
		DisplayMenu(hDisplayMenu, client, 30);
	}
	else
	{
		new String:sArg[32];
		GetCmdArg(1, sArg, sizeof(sArg));
		OpenDonationWindow(client, StringToInt(sArg));
	}
	return Plugin_Handled;
}

public MenuHandle(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			decl String:sInfo[32];
			GetMenuItem(hDisplayMenu, param2, sInfo, sizeof(sInfo));
			OpenDonationWindow(param1, StringToInt(sInfo));
		}
	}
}

OpenDonationWindow(client, amount)
{
	if (cv_iMinimumAmount <= amount)
	{
		new String:SteamID[32];
		GetClientAuthId(client, AuthId_SteamID64, SteamID, sizeof(SteamID));
		ReplaceString(SteamID, sizeof(SteamID), ":", "%3A");

		decl String:donateamount[5];
		IntToString(amount, donateamount, sizeof(donateamount));

		decl String:donateurl[128];
		GetConVarString(hConVars[1], donateurl, sizeof(donateurl));
		Format(donateurl, sizeof(donateurl), "%s/donate.php?&amount=%s&tier=1&steamid_user=%s", donateurl, donateamount, SteamID);

		new Handle:Kv = CreateKeyValues("motd");
		KvSetString(Kv, "title", "Backpack");
		KvSetNum(Kv, "type", MOTDPANEL_TYPE_URL);
		KvSetString(Kv, "msg", donateurl);
		if (cv_bFullScreen) KvSetNum(Kv, "customsvr", 1);

		ShowVGUIPanel(client, "info", Kv);
		CloseHandle(Kv);
	}
	else
	{
		PrintToChat(client, "Minimum amount is 5 dollars");
	}
}

stock ClearTimer(&Handle:hTimer)
{
	if (hTimer != INVALID_HANDLE)
	{
		KillTimer(hTimer);
		hTimer = INVALID_HANDLE;
	}
}

public Action:TimerAdvertisement (Handle:hTimer)
{
	PrintToChatAll("%s", "Advertisement Message");
}