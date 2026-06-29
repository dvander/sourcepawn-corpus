/*
 * Admin Buy Plugin
 * @description Plugin is used to provide admins, subscribers, donors, vips, etc the ability to buy weapons beyond the limitations of cost and/or team
 * @author brizad
 * @bug Fix the issue with 'buy' triggering on client even when its regisered as sm_buy when calling '!buy'
 * @todo Support counting of how many a team has for weapon restrictions
 * @todo Translations Config and strings
 * v1.04 - Change Restrict vars to use YouzAMenace version
 * v1.03 - Fixed Famas with wrong default team
 * v1.02 - Moved Foriegn CVars to OnPluginsLoaded to fix restricted weapons in buy menu
 * v1.01 - Fixed incorrect return value on from BuyAllowed
 */

#include <sourcemod.inc>
#include <sdktools.inc>

#pragma semicolon 1

#define PLUGIN_VERSION "1.04"
#define MAX_BUYWEAPONS 10

new g_iBuyZone = -1;
new g_iAccount = -1;
new Float:g_fBuyTimeEnd;
new Handle:g_hAdminBuyEnabled = INVALID_HANDLE;
new Handle:g_hAdminBuyDeny = INVALID_HANDLE;
new Handle:g_hAdminBuyFlags = INVALID_HANDLE;
new Handle:g_hRestrictPlugin = INVALID_HANDLE;
new Handle:g_hBuyTimeCvar = INVALID_HANDLE;

static String:g_szWeapons[MAX_BUYWEAPONS][5][ ] = 
{
	// Weapon key // Weapon Name // Slot # // Cost // Original Limited Team
	{"weapon_elite", "Dual Elites", "1", "800", "2"},
	{"weapon_fiveseven", "FiveSeven", "1", "750", "3"},
	{"weapon_galil", "IDF Defender Galil", "2", "2000", "2"},
	{"weapon_ak47", "AK-47", "2", "2500", "2"},
	{"weapon_sg552", "Krieg 552", "2", "3500", "2"},
	{"weapon_famas", "Clarion Famas", "2", "2250", "3"},
	{"weapon_m4a1", "Maverick M4A1 Carbine", "2", "3100", "3"},
	{"weapon_aug", "Bullpup AUG", "2", "3500", "3"},
	{"weapon_mac10", "Ingram Mac-10", "2", "1400", "2"},
	{"weapon_tmp", "TMP Schmidt Machine Pistol", "2", "1250", "3"}
	// Others primammo, secammo, vest, vesthelm, defuser, nvgs, flashbang, hegrenade
};

// Plugin definitions
public Plugin:myinfo = 
{
	name = "Admin Buy",
	author = "brizad",
	description = "Allows Admins or VIPs to buy Opposing Team Weapons.",
	version = PLUGIN_VERSION,
	url = "http://www.doopalliance.com"
};

public OnPluginStart()
{
	// Get offsets
	g_iBuyZone = FindSendPropOffs("CCSPlayer", "m_bInBuyZone");
	g_iAccount = FindSendPropOffs("CCSPlayer", "m_iAccount");

	if (g_iAccount == -1)
	{
		PrintToServer("[SM] Admin Buy: Unable to start, used for Counter Stike Source Only!");
		return;
	}

	CreateConVar("sm_buy_version", PLUGIN_VERSION, "SM Admin Buy Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED);
	g_hAdminBuyEnabled = CreateConVar("sm_buy_enabled", "1", "Enables/Disabled the Admin Buy Command <0=Off | 1=On with cost | 2=On Without Cost>", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hAdminBuyDeny = CreateConVar("sm_buy_denymsg", "This Buy feature is limited to server supportors only.  Please visit website for details.", "Message to reply when player isn't a subscriber/vip/admin.", FCVAR_PLUGIN|FCVAR_SPONLY);
	g_hAdminBuyFlags = CreateConVar("sm_buy_adminflags", "r", "Admin Flag(s) to allow changing cash. o=CustomFlag_1 p=CustomFlag_2 etc.", FCVAR_PLUGIN|FCVAR_SPONLY);

	// Exec Config and Save defaults
	AutoExecConfig(true, "adminbuy");

	RegConsoleCmd("sm_buy", eventBuy, "Admin Buy Menu or select weapon.");

	RegConsoleCmd("say", eventSay);
	RegConsoleCmd("say_team", eventSay);

	HookEvent("round_start", eventRoundStart);
	HookEvent("round_freeze_end", eventRoundFreezeEnd);
}

public OnAllPluginsLoaded()
{
	// Check other Plugin/CVars
	g_hRestrictPlugin = FindConVar("sm_weaponrestrict_version");
	g_hBuyTimeCvar = FindConVar("mp_buytime");
}

public Action:eventSay(p_iClient, p_szArgs)
{
	new String:szSayText[192];
	new String:szSayTrig[15];

	GetCmdArgString(szSayText, sizeof(szSayText));
	StripQuotes(szSayText);

	BreakString(szSayText, szSayTrig, sizeof(szSayTrig));

	if (strcmp(szSayTrig, "!buy", false) == 0)
	{
		FakeClientCommand(p_iClient, "sm_buy %s", szSayText[5]);
		return Plugin_Stop;
	}

	return Plugin_Continue;
}

public Action:eventBuy(p_iClient, p_szArgs)
{
	if (p_iClient <= 0)
		return Plugin_Handled;
	
	if (!BuyAllowed())
	{
		PrintToChat(p_iClient, "\x04[SM] Admin Buy: Buy time has exceeded.");
		return Plugin_Handled;
	}

	new iBuyEnabled = GetConVarInt(g_hAdminBuyEnabled);

	if(iBuyEnabled != 0)
	{
		// Delare vars I will need
		new String:szAdminFlags[32] = "";
		new String:szArgGun[32];
		new String:szGun[32];
		new iDropSlot = -1;
		new iMyBalance = GetMoney(p_iClient);
		new iWeaponCost = 0;

		GetConVarString(g_hAdminBuyFlags, szAdminFlags, sizeof(szAdminFlags));
	
		// Check Admin Flag, blank mean everyone
		if (strlen(szAdminFlags) > 0)
		{
			new String:szDenyMsg[192] = "";
			GetConVarString(g_hAdminBuyDeny, szDenyMsg, sizeof(szDenyMsg));

			if (GetUserFlagBits(p_iClient) & ReadFlagString(szAdminFlags) <= 0 && !(GetUserFlagBits(p_iClient) & ADMFLAG_CUSTOM5))
			{
				if (strlen(szDenyMsg) > 0)
					PrintToChat(p_iClient, "\x04[SM] Admin Buy: %s", szDenyMsg);

				return Plugin_Handled;
			}
		}

		if (!GetEntData(p_iClient, g_iBuyZone, 1))
		{
			PrintToChat(p_iClient, "\x04[SM] Admin Buy: You must be in buy zone!");
			return Plugin_Handled;
		}

		GetCmdArg(1, szArgGun, sizeof(szArgGun));

		if (strlen(szArgGun) <= 0)
		{
			// Setup menu
			new Handle:hBuyMenu = CreateMenu(eventBuyMenu);
			SetMenuTitle(hBuyMenu, "Select to buy Op-Team Weapon:");

			for (new lp; lp < MAX_BUYWEAPONS; lp++)
			{
				if (!IsGunRestricted(g_szWeapons[lp][0], GetClientTeam(p_iClient)) && iMyBalance >= StringToInt(g_szWeapons[lp][3]) &&
					(StringToInt(g_szWeapons[lp][4]) == 0 || (StringToInt(g_szWeapons[lp][4]) != GetClientTeam(p_iClient))))
					AddMenuItem(hBuyMenu, g_szWeapons[lp][0], g_szWeapons[lp][1]);
			}

			SetMenuExitButton(hBuyMenu, true);
			DisplayMenu(hBuyMenu, p_iClient, 20);

			return Plugin_Handled;
		}

		for (new lp; lp < strlen(szArgGun); lp++)
			szArgGun[lp] = CharToLower(szArgGun[lp]);

		if (StrContains(szArgGun, "weapon_") == -1)
		{
			szGun = "weapon_";
			StrCat(szGun, sizeof(szGun), szArgGun);
		}
		else
			strcopy(szGun, sizeof(szGun), szArgGun);

		if (IsGunRestricted(szGun, GetClientTeam(p_iClient)))
		{
			PrintToChat(p_iClient, "\x04[SM] Admin Buy: So Sorry, this weapon is restricted!");
			return Plugin_Handled;
		}

		for (new lp; lp < MAX_BUYWEAPONS; lp++)
			if (strcmp(g_szWeapons[lp][0], szGun) == 0)
			{
				iDropSlot = StringToInt(g_szWeapons[lp][2]);
				iWeaponCost = StringToInt(g_szWeapons[lp][3]);
				break;
			}
	
		if (iDropSlot != -1)
		{
			new fCurrentWeapon = GetPlayerWeaponSlot(p_iClient, iDropSlot);
			new String:szCurrentWeapon[32] = "";

			if (iBuyEnabled == 1)
			{
				if ((iMyBalance - iWeaponCost) < 0)
				{
					PrintToChat(p_iClient, "\x04[SM] Admin Buy: You have insufficient funds!");
					return Plugin_Handled;
				}

				SetMoney(p_iClient, iWeaponCost, '-');
			}	

			if (fCurrentWeapon != -1 && GetEdictClassname(fCurrentWeapon, szCurrentWeapon, sizeof(szCurrentWeapon)))
			{
				FakeClientCommand(p_iClient, "use %s", szCurrentWeapon);
				FakeClientCommand(p_iClient, "drop");
			}

			GivePlayerItem(p_iClient, szGun);
			FakeClientCommand(p_iClient, "use %s", szGun);
		}
		else
			PrintToChat(p_iClient, "\x04[SM] Admin Buy: Weapon/Equipment not supported in Admin Buy system!");
	}

	return Plugin_Handled;
}

public eventBuyMenu(Handle:p_hBuyMenu, MenuAction:p_oAction, p_iParam1, p_iParam2)
{
	/* If an option was selected, tell the client about the item. */
	if (p_oAction == MenuAction_Select)
	{
		new String:szMenuItem[32];

		if (GetMenuItem(p_hBuyMenu, p_iParam2, szMenuItem, sizeof(szMenuItem)))
			FakeClientCommand(p_iParam1, "sm_buy %s", szMenuItem);
	}
	else if (p_oAction == MenuAction_End)
		CloseHandle(p_hBuyMenu);
}

public eventRoundStart(Handle:p_hEvent,const String:p_szName[],bool:p_bDontBroadcast)
{
	g_fBuyTimeEnd = -1.0;
}

public eventRoundFreezeEnd(Handle:p_hEvent,const String:p_szName[],bool:p_bDontBroadcast)
{
	g_fBuyTimeEnd = GetEngineTime() + GetConVarFloat(g_hBuyTimeCvar) * 60;
}

public bool:BuyAllowed()
{
	if (g_fBuyTimeEnd == -1.0)
		return true;

	return (GetEngineTime() < g_fBuyTimeEnd ? true : false);
}

public bool:IsGunRestricted(const String:p_szWeapon[], const p_iTeam)
{
	if (g_hRestrictPlugin == INVALID_HANDLE)
		return false;

	// Find convar 
	new String:szCvar[32] = "";
	new String:szCurrTeam[3] = "";

	switch (p_iTeam)
	{
		case 2:
			szCurrTeam = "t";
		case 3:
			szCurrTeam = "ct";
		default:
			return false;
	}

	Format(szCvar, sizeof(szCvar), "sm_restrict_%s_%s", p_szWeapon[7], szCurrTeam);
	new Handle:hWeaponCvar = FindConVar(szCvar);

	if (hWeaponCvar != INVALID_HANDLE)
	{
		// Need to do weapon counts here
		new iWeaponLimit = GetConVarInt(hWeaponCvar);

		if (iWeaponLimit == 0)
			return true;
	}

	return false;
}

public SetMoney(p_iClient, p_iAmount, p_cModifier)
{
	if (p_cModifier == '+')
		p_iAmount = GetMoney(p_iClient) + p_iAmount;

	if (p_cModifier == '-')
		p_iAmount = GetMoney(p_iClient) - p_iAmount;

	if (p_iAmount > 16000)
		p_iAmount = 16000;

	if (p_iAmount < 0)
		p_iAmount = 0;

	if (g_iAccount != -1)
		SetEntData(p_iClient, g_iAccount, p_iAmount);
}

public GetMoney(p_iClient)
{
	if (g_iAccount != -1)
		return GetEntData(p_iClient, g_iAccount);

	return 0;
}
