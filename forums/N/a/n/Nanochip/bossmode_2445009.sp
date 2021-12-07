#pragma semicolon 1
#include <sourcemod>
#include <freak_fortress_2>
#include <morecolors>
#include <clientprefs>

#define PLUGIN_VERSION "1.0"

new Handle:cvarEnable;

new Handle:cBossMode;
new bossMode[MAXPLAYERS+1]; // Boss Modes: 0 = Normal, 1 = Hard, 2 = Insane.
new bool:PreventRage[MAXPLAYERS+1] = {false, ...};
new bool:bossLastLife[MAXPLAYERS+1] = {false, ...};
new bool:bossLastLifeLeg[MAXPLAYERS+1] = {false, ...};

public Plugin:myinfo = {
	name = "FF2 Boss Mode",
	author = "Nanochip",
	description = "Choose what difficulty you would like to play when you are the boss.",
	version = PLUGIN_VERSION,
	url = "lolme.me"
};

public OnPluginStart()
{
	CreateConVar("sm_ff2bossmode_version", PLUGIN_VERSION, "FF2 Boss Mode Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvarEnable = CreateConVar("sm_ff2bossmode_enable", "1", "Enable the plugin? 1 = Yes, 0 = No.", 0, true, 0.0, true, 1.0);
	
	RegConsoleCmd("sm_halemode", Cmd_BossMode, "Choose your boss difficulty.");
	RegConsoleCmd("sm_bossmode", Cmd_BossMode, "Choose your boss difficulty.");
	RegConsoleCmd("sm_ff2mode", Cmd_BossMode, "Choose your boss difficulty.");
	
	cBossMode = RegClientCookie("sm_ff2bossmode_cookie", "Choose your boss mode, 0, 1, 2", CookieAccess_Private);
	SetCookieMenuItem(BossModeSettingsMenu, 0, "FF2 Boss Mode");
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			bossMode[i] = 0;
			if(AreClientCookiesCached(i)) OnClientCookiesCached(i);
		}
	}
	
	HookEvent("arena_round_start", Event_RoundStart, EventHookMode_Post);
}

public BossModeSettingsMenu(client, CookieMenuAction:action, any:info, String:buffer[], maxlen)
{
    if (action == CookieMenuAction_SelectOption)
    {
        CreateBossModeMenu(client);
    }
}

public Action:Cmd_BossMode(client, args)
{
	CreateBossModeMenu(client);
	return Plugin_Handled;
}

CreateBossModeMenu(client)
{
	new Handle:menu = CreateMenu(BossModeMenuCallback, MENU_ACTIONS_ALL);
	SetMenuTitle(menu, "FF2 Boss Mode - Choose your boss difficulty");
	switch (bossMode[client])
	{
		case 0:
		{
			AddMenuItem(menu, "normal", "Normal (Current)\n    - Default mode. Normal health, and normal rage.\n", ITEMDRAW_DISABLED);
			AddMenuItem(menu, "hard", "Hard\n    - Half your normal health/lives.\n");
			AddMenuItem(menu, "insane", "Insane\n    - Half your normal health/lives and no rage ability. Good luck!");
			AddMenuItem(menu, "legendary", "Legendary\n    - One-third your normal health/lives and no rage ability. You're going to die XD");
		}
			
		case 1:
		{
			AddMenuItem(menu, "normal", "Normal\n    - Default mode. Normal health, and normal rage.\n");
			AddMenuItem(menu, "hard", "Hard (Current)\n    - Half your normal health/lives.\n", ITEMDRAW_DISABLED);
			AddMenuItem(menu, "insane", "Insane\n    - Half your normal health/lives and no rage ability. Good luck!");
			AddMenuItem(menu, "legendary", "Legendary\n    - One-third your normal health/lives and no rage ability. You're going to die XD");
		}
		
		case 2:
		{
			AddMenuItem(menu, "normal", "Normal\n    - Default mode. Normal health, and normal rage.\n");
			AddMenuItem(menu, "hard", "Hard\n    - Half your normal health/lives.\n");
			AddMenuItem(menu, "insane", "Insane (Current)\n    - Half your normal health/lives and no rage ability. Good luck!", ITEMDRAW_DISABLED);
			AddMenuItem(menu, "legendary", "Legendary\n    - One-third your normal health/lives and no rage ability. You're going to die XD");
		}
		
		case 3:
		{
			AddMenuItem(menu, "normal", "Normal\n    - Default mode. Normal health, and normal rage.\n");
			AddMenuItem(menu, "hard", "Hard\n    - Half your normal health/lives.\n");
			AddMenuItem(menu, "insane", "Insane\n    - Half your normal health/lives and no rage ability. Good luck!");
			AddMenuItem(menu, "legendary", "Legendary (Current)\n    - One-third your normal health/lives and no rage ability. You're going to die XD", ITEMDRAW_DISABLED);
		}
	}
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public BossModeMenuCallback(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_End) CloseHandle(menu);
	
	if (action == MenuAction_Select)
	{
		decl String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		SetClientCookie(client, cBossMode, info);
		
		if (StrEqual(info, "normal"))
		{
			bossMode[client] = 0;
			PrintToChat(client, "[SM] Activated \"Normal\" mode on yourself.");
		}
		if (StrEqual(info, "hard"))
		{
			bossMode[client] = 1;
			PrintToChat(client, "[SM] Activated \"Hard\" mode on yourself.");
		}
		if (StrEqual(info, "insane"))
		{
			bossMode[client] = 2;
			PrintToChat(client, "[SM] Activated \"Insane\" mode on yourself. Good luck!");
		}
		if (StrEqual(info, "legendary"))
		{
			bossMode[client] = 3;
			PrintToChat(client, "[SM] Activated \"Legendary\" mode on yourself. You're going to die XD");
		}
	}
}

public OnClientAuthorized(client, const String:auth[])
{
	if (!GetConVarBool(cvarEnable)) return;
	bossMode[client] = 0;
}

public OnClientCookiesCached(client)
{
	if (!GetConVarBool(cvarEnable)) return;
	decl String:info[32];
	GetClientCookie(client, cBossMode, info, sizeof(info));
	if (StrEqual(info, "normal")) bossMode[client] = 0;
	if (StrEqual(info, "hard")) bossMode[client] = 1;
	if (StrEqual(info, "insane")) bossMode[client] = 2;
	if (StrEqual(info, "legendary")) bossMode[client] = 3;
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		new boss = FF2_GetBossIndex(i);
		if (boss != -1)
		{
			new bossHealth = FF2_GetBossMaxHealth(boss);
			new bossLives = FF2_GetBossMaxLives(boss);
			if (bossMode[i] == 0 && (PreventRage[boss] || bossLastLife[boss])) 
			{
				if (bossLastLifeLeg[boss]) bossLastLifeLeg[boss] = false;
				PreventRage[boss] = false;
				bossLastLife[boss] = false;
			}
			if (bossMode[i] == 1)
			{
				CPrintToChatAll("{olive}[FF2] {default}%N is now playing in Boss Mode: {red}Hard", i);
				if (bossLastLifeLeg[boss]) bossLastLifeLeg[boss] = false;
				if (bossLives == 1)
				{
					bossHealth /= 2;
					FF2_SetBossHealth(boss, bossHealth);
					if (bossLastLife[boss]) bossLastLife[boss] = false;
				} else {
					new even = bossLives % 2;
					bossLives /= 2;
					FF2_SetBossLives(boss, bossLives);
					if (even != 0)
					{
						bossLastLife[boss] = true;
					} else {
						bossLastLife[boss] = false;
					}
				}
				if (PreventRage[boss]) PreventRage[boss] = false;
			}
			if (bossMode[i] == 2)
			{
				CPrintToChatAll("{olive}[FF2] {default}%N is now playing in Boss Mode: {darkred}Insane{default}. GOOD LUCK!", i);
				if (bossLastLifeLeg[boss]) bossLastLifeLeg[boss] = false;
				if (bossLives == 1)
				{
					bossHealth /= 2;
					FF2_SetBossHealth(boss, bossHealth);
					if (bossLastLife[boss]) bossLastLife[boss] = false;
				} else {
					new even = bossLives % 2;
					bossLives /= 2;
					FF2_SetBossLives(boss, bossLives);
					if (even != 0)
					{
						bossLastLife[boss] = true;
					} else {
						bossLastLife[boss] = false;
					}
				}
				PreventRage[boss] = true;
			}
			if (bossMode[i] == 3)
			{
				CPrintToChatAll("{olive}[FF2] {default}%N is now playing in Boss Mode: {darkred}L{cyan}E{fullblue}G{fuchsia}E{lime}N{orange}D{aqua}A{darkgreen}R{navy}Y{default}!", i);
				if (bossLastLife[boss]) bossLastLife[boss] = false;
				if (bossLives == 1)
				{
					bossHealth /= 3;
					FF2_SetBossHealth(boss, bossHealth);
					if (bossLastLifeLeg[boss]) bossLastLifeLeg[boss] = false;
				} else if (bossLives == 2)
				{
					bossLives /= 2;
					FF2_SetBossLives(boss, bossLives);
					if (bossLastLifeLeg[boss]) bossLastLifeLeg[boss] = false;
					bossHealth /= 3;
					bossHealth += bossHealth;
					FF2_SetBossHealth(boss, bossHealth);
				} else {
					new even = bossLives % 2;
					bossLives /= 2;
					FF2_SetBossLives(boss, bossLives);
					if (even != 0)
					{
						bossLastLifeLeg[boss] = true;
					} else {
						bossLastLifeLeg[boss] = false;
					}
				}
				PreventRage[boss] = true;
			}
		}
	}
}

public Action:FF2_OnLoseLife(boss, &lives, maxLives)
{
	if (bossLastLife[boss] && lives == 1)
	{
		new bossHealth = FF2_GetBossHealth(boss) / 2;
		FF2_SetBossHealth(boss, bossHealth);
	}
	if (bossLastLifeLeg[boss] && lives == 1)
	{
		new bossHealth = FF2_GetBossHealth(boss) / 3;
		FF2_SetBossHealth(boss, bossHealth);
	}
}

public FF2_PreAbility(boss, const String:pluginName[], const String:abilityName[], slot, &bool:enabled)
{
	if (slot == 0 && PreventRage[boss])
	{
		enabled = false;
	}
}