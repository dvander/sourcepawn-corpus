#include <sourcemod>
#include <timer>
#include <timer-config_loader.sp>

public Plugin:myinfo =
{
    name        = "[Timer] Main Menu",
    author      = "Zipcore",
    description = "Main menu component for [Timer]",
    version     = PL_VERSION,
    url         = "zipcore#googlemail.com"
};

new GameMod:mod;
new String:g_sCurrentMap[PLATFORM_MAX_PATH];

public OnPluginStart()
{
	LoadPhysics();
	LoadTimerSettings();
	
	RegConsoleCmd("sm_menu", Command_Menu);
	RegConsoleCmd("sm_help", Command_Timer);		
	RegConsoleCmd("sm_timer", Command_Timer);
	RegConsoleCmd("sm_mapinfo", Command_MapInfo);
	
	mod = GetGameMod();
}

public OnMapStart()
{
	LoadPhysics();
	LoadTimerSettings();
	
	GetCurrentMap(g_sCurrentMap, sizeof(g_sCurrentMap));
}

public Action:Command_Menu(client, args)
{
	Menu(client);
	
	return Plugin_Handled;
}

public Action:Command_Timer(client, args)
{
	HelpPanel(client);
	
	return Plugin_Handled;
}

// ----------- Page 1 -------------------------------------------
public HelpPanel(client)
{
	new Handle:panel = CreatePanel();
	SetPanelTitle(panel, "- DMT|Timer Help Menu - \nby Zipcore");
	
	if(mod == MOD_CSGO) SetPanelCurrentKey(panel, 8);
	else SetPanelCurrentKey(panel, 9);
	
	DrawPanelText(panel, "         -- Page 1/4 --");
	DrawPanelText(panel, " ");
	DrawPanelText(panel, "!timer - Displays this menu");
	DrawPanelText(panel, "!menu - Displays a main menu");
	DrawPanelText(panel, " ");
	DrawPanelText(panel, "!start - Teleport to startzone (or !r)");
	DrawPanelText(panel, "!bonusstart - Teleport to bonus startzone (or !b)");
	if(g_Settings[PauseEnable])
	{
		DrawPanelText(panel, "!pause - Pause the timer");
		DrawPanelText(panel, "!resume - Resume the timer");
	}
	else
	{
		DrawPanelText(panel, " ");
		DrawPanelText(panel, " ");
	}
	DrawPanelText(panel, " ");
	if(g_Settings[BhopEnable])
		DrawPanelText(panel, "!tauto - Toggle auto bhop");
	else 
		DrawPanelText(panel, " ");
	DrawPanelItem(panel, "- Next -");
	DrawPanelItem(panel, "- Exit -");
	SendPanelToClient(panel, client, PanelHandler1, MENU_TIME_FOREVER);

	CloseHandle(panel);
}
public PanelHandler1 (Handle:menu, MenuAction:action,param1, param2)
{
    if ( action == MenuAction_Select )
    {
		if(mod == MOD_CSGO) 
		{
			switch (param2)
			{
				case 8:
				{
					HelpPanel2(param1);
				}
			}
		}
		else
		{
			switch (param2)
			{
				case 9:
				{
					HelpPanel2(param1);
				}
			}
		}
    }
}

// ---------------------------------- Page 2 -------------------------------

public HelpPanel2(client)
{
	new Handle:panel = CreatePanel();
	SetPanelTitle(panel, "- DMT|Timer Help Menu - \nby Zipcore");
	
	if(mod == MOD_CSGO) SetPanelCurrentKey(panel, 7);
	else SetPanelCurrentKey(panel, 8);
	
	DrawPanelText(panel, "         -- Page 2/4 --");
	DrawPanelText(panel, " ");
	DrawPanelText(panel, "!spectate - Go to spectators");
	if(g_Settings[LevelTeleportEnable])
	{
		DrawPanelText(panel, "!stage - Teleport to any Stage");
		DrawPanelText(panel, "!stage <number> - Teleport to a stage (not finished)");
	}
	else
	{
		DrawPanelText(panel, "!stage - Server Disabled");
		DrawPanelText(panel, "!stage <number> - Server Disabled");
	}
	if(g_Settings[PlayerTeleportEnable])
	{
		DrawPanelText(panel, "!tpto - Teleport to another player");
	}
	else
	{
		DrawPanelText(panel, "!tpto - Server Disabled");
	}
	DrawPanelText(panel, "!hide - Hide other players");
	if(g_Settings[NoclipEnable])
	{
		DrawPanelText(panel, "!noclipme - Turn On/Off noclip mode");
	}
	else
	{
		DrawPanelText(panel, "!noclipme - Server Disabled");
	}
	if(PluginEnabled("timer-hud.smx"))
	{
		DrawPanelText(panel, "!hud - Customize your HUD");
	}
	else
	{
		DrawPanelText(panel, "!hud - Server Disabled");
	}
	DrawPanelText(panel, " ");
	DrawPanelItem(panel, "- Back -");
	DrawPanelItem(panel, "- Next -");
	DrawPanelItem(panel, "- Exit -");
	SendPanelToClient(panel, client, PanelHandler2, MENU_TIME_FOREVER);

	CloseHandle(panel);
}

public PanelHandler2 (Handle:menu, MenuAction:action,param1, param2)
{
    if ( action == MenuAction_Select )
    {
		if(mod == MOD_CSGO) 
		{
			switch (param2)
			{
				case 7:
				{
					HelpPanel(param1);
				}
				case 8:
				{
					HelpPanel3(param1);
				}
			}
		}
		else
		{
			switch (param2)
			{
				case 8:
				{
					HelpPanel(param1);
				}
				case 9:
				{
					HelpPanel3(param1);
				}
			}
		}
    }
}

//------------------------- Page 3 -----------------------------------------
public HelpPanel3(client)
{
	new Handle:panel = CreatePanel();
	SetPanelTitle(panel, "- DMT|Timer Help Menu - \nby Zipcore");
	
	if(mod == MOD_CSGO) SetPanelCurrentKey(panel, 7);
	else SetPanelCurrentKey(panel, 8);
	
	DrawPanelText(panel, "         -- Page 3/4 --");
	DrawPanelText(panel, " ");
	if(g_Settings[ChallengeEnable])
	{
		DrawPanelText(panel, "!challenge - Challenge another player [Steal points] (not finished)");
	}
	else
	{
		DrawPanelText(panel, "!challenge - Server Disabled");
	}
	
	if(g_Settings[CoopEnable])
	{
		DrawPanelText(panel, "!coop - Do it together [Extra points] (not finished)");
	}
	else
	{
		DrawPanelText(panel, "!coop - Server Disabled");
	}
	
	if(g_Settings[RaceEnable])
	{
		DrawPanelText(panel, "!race - Displays race manager [Extra points] (not finished)");
	}
	else
	{
		DrawPanelText(panel, "!race - Server Disabled");
	}
	DrawPanelText(panel, "!rank - Displays your rank");
	DrawPanelText(panel, "!top - Displays top10 of this map");
	DrawPanelText(panel, "!mtop <mapname> - Displays a maps top10 (not finished)");
	DrawPanelText(panel, "!btop - Displays bonus top10 of this map");
	DrawPanelText(panel, "!mbtop <mapname> - Displays a maps bonus top10 (not finished)");
	DrawPanelText(panel, " ");
	DrawPanelItem(panel, "- Back -");
	DrawPanelItem(panel, "- Next -");
	DrawPanelItem(panel, "- Exit -");
	SendPanelToClient(panel, client, PanelHandler3, MENU_TIME_FOREVER);

	CloseHandle(panel);
}
public PanelHandler3 (Handle:menu, MenuAction:action,param1, param2)
{
    if ( action == MenuAction_Select )
    {
		if(mod == MOD_CSGO) 
		{
			switch (param2)
			{
				case 7:
				{
					HelpPanel2(param1);
				}
				case 8:
				{
					HelpPanel4(param1);
				}
			}
		}
		else
		{
			switch (param2)
			{
				case 8:
				{
					HelpPanel2(param1);
				}
				case 9:
				{
					HelpPanel4(param1);
				}
			}
		}
    }
}

//------------------------- Page 4 -----------------------------------------
public HelpPanel4(client)
{
	new Handle:panel = CreatePanel();
	SetPanelTitle(panel, "- DMT|Timer Help Menu - \nby Zipcore ");
	
	if(mod == MOD_CSGO) SetPanelCurrentKey(panel, 7);
	else SetPanelCurrentKey(panel, 8);
	
	DrawPanelText(panel, "         -- Page 4/4 --");
	DrawPanelText(panel, " ");
	DrawPanelText(panel, "!prank - Displays your point rank");
	DrawPanelText(panel, "!ptop - Displays top10 by pointrank");
	DrawPanelText(panel, "!mapinfo - Displays Mapinfo (not finished) (not finished)");
	DrawPanelText(panel, "!viewranks - View all ranks (not finished)");
	DrawPanelText(panel, "!viewrecords - View all records (not finished)");
	DrawPanelText(panel, "!playerinfo <partial playername> - Displays Playerinfos [WEB] (not finished)");
	if(PluginEnabled("timer-physicsinfo.smx"))
	{
		DrawPanelText(panel, "!styleinfo - Displays Styleinfo");
	}
	else
	{
		DrawPanelText(panel, "!styleinfo - Server Disabled");
	}
	DrawPanelText(panel, "!credits - Displays Credits");
	DrawPanelText(panel, " ");
	DrawPanelItem(panel, "- Back -");
	DrawPanelItem(panel, "- Next -", ITEMDRAW_SPACER);
	DrawPanelItem(panel, "- Exit -");
	SendPanelToClient(panel, client, PanelHandler4, MENU_TIME_FOREVER);

	CloseHandle(panel);
}
public PanelHandler4 (Handle:menu, MenuAction:action,param1, param2)
{
    if ( action == MenuAction_Select )
    {
		if(mod == MOD_CSGO) 
		{
			switch (param2)
			{
				case 7:
				{
					HelpPanel3(param1);
				}
			}
		}
		else
		{
			switch (param2)
			{
				case 8:
				{
					HelpPanel3(param1);
				}
			}
		}
    }
}

Menu(client)
{
	if (0 < client < MaxClients)
	{
		new Handle:menu = CreateMenu(Handle_Menu);
		SetMenuTitle(menu, "DMT|Timer - Main Menu \nby Zipcore");		
			
		AddMenuItem(menu, "mode", "Change Style");			
		if(PluginEnabled("timer-physicsinfo.smx"))
		{
			AddMenuItem(menu, "info", "Mode Settings Info");
		}
		if(g_Settings[ChallengeEnable])
		{
			AddMenuItem(menu, "challenge", "Challenge");
		}
		if(PluginEnabled("timer-cpmod.smx") || g_Settings[LevelTeleportEnable] || g_Settings[PlayerTeleportEnable])
		{
			AddMenuItem(menu, "tele", "Teleport Menu");
		}
		AddMenuItem(menu, "wrm", "World Record Menu");
		if(PluginEnabled("timer-hud.smx"))
		{
			AddMenuItem(menu, "hud", "Custom HUD Settings");
		}
		AddMenuItem(menu, "credits", "Credits");
		
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
}
	
public Handle_Menu(Handle:menu, MenuAction:action, client, itemNum)
{
	if ( action == MenuAction_Select )
	{
		decl String:info[100], String:info2[100];
		new bool:found = GetMenuItem(menu, itemNum, info, sizeof(info), _, info2, sizeof(info2));
		if(found)
		{
			if(StrEqual(info, "mode"))
			{
				FakeClientCommand(client, "sm_style");
			}
			else if(StrEqual(info, "info"))
			{
				FakeClientCommand(client, "sm_physicinfo");
			}
			else if(StrEqual(info, "wrm"))
			{
				WorldRecordMenu(client);
			}
			else if(StrEqual(info, "tele"))
			{
				TeleportMenu(client);
			}
			else if(StrEqual(info, "challenge"))
			{
				if(IsClientInGame(client)) FakeClientCommand(client, "sm_challenge"); 
			}
			else if(StrEqual(info, "hud"))
			{
				if(IsClientInGame(client)) FakeClientCommand(client, "sm_hud"); 
			}
			else if(StrEqual(info, "credits"))
			{
				FakeClientCommand(client, "sm_credits");
			}
		}
	}
}

WorldRecordMenu(client)
{
	if (0 < client < MaxClients)
	{
		new Handle:menu = CreateMenu(Handle_WorldRecordMenu);
				
		SetMenuTitle(menu, "World Record Menu");
		
		AddMenuItem(menu, "wr", "World Record");
		AddMenuItem(menu, "bwr", "Bonus World Record");
		AddMenuItem(menu, "swr", "Short World Record");
		AddMenuItem(menu, "main", "Back");
		
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
}
	
public Handle_WorldRecordMenu(Handle:menu, MenuAction:action, client, itemNum)
{
	if ( action == MenuAction_Select )
	{
		decl String:info[100], String:info2[100];
		new bool:found = GetMenuItem(menu, itemNum, info, sizeof(info), _, info2, sizeof(info2));
		if(found)
		{
			if(StrEqual(info, "wr"))
			{
				FakeClientCommand(client, "sm_top");
			}
			else if(StrEqual(info, "bwr"))
			{
				FakeClientCommand(client, "sm_btop");
			}
			else if(StrEqual(info, "swr"))
			{
				FakeClientCommand(client, "sm_stop");
			}
			else if(StrEqual(info, "main"))
			{
				FakeClientCommand(client, "sm_menu");
			}
		}
	}
}

TeleportMenu(client)
{
	if (0 < client < MaxClients)
	{
		new Handle:menu = CreateMenu(Handle_TeleportMenu);
				
		SetMenuTitle(menu, "Teleport Menu");
		
		if(g_Settings[PlayerTeleportEnable])
		{
			AddMenuItem(menu, "teleme", "Teleport to Player");
		}
		if(g_Settings[LevelTeleportEnable])
		{
			AddMenuItem(menu, "levels", "Teleport to Level");
		}
		if(PluginEnabled("timer-cpmod.smx"))
		{
			AddMenuItem(menu, "checkpoint", "Teleport to Checkpoint");
		}
		AddMenuItem(menu, "main", "Back");
		
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
}
	
public Handle_TeleportMenu(Handle:menu, MenuAction:action, client, itemNum)
{
	if ( action == MenuAction_Select )
	{
		decl String:info[100], String:info2[100];
		new bool:found = GetMenuItem(menu, itemNum, info, sizeof(info), _, info2, sizeof(info2));
		if(found)
		{
			if(StrEqual(info, "teleme"))
			{
				FakeClientCommand(client, "sm_tpto");
			}
			else if(StrEqual(info, "levels"))
			{
				FakeClientCommand(client, "sm_stage");
			}
			else if(StrEqual(info, "checkpoint"))
			{
				FakeClientCommand(client, "sm_cphelp");
			}
			else if(StrEqual(info, "main"))
			{
				FakeClientCommand(client, "sm_menu");
			}
		}
	}
}

public Action:Command_MapInfo(client, args)
{
	MapInfoMenu(client);
	
	return Plugin_Handled;
}

//Tier, stages/linear, obs bonus hat, wieviele rekorde, welche punkte du bekommen kannst, vllt den WR

MapInfoMenu(client)
{
	if (0 < client < MaxClients)
	{
		new Handle:menu = CreateMenu(Handle_MapInfoMenu);
		
		SetMenuTitle(menu, "MapInfo for %s", g_sCurrentMap);
		
		new String:buffer[128];
		
		new stages, bonusstages;
		
		stages = Timer_GetMapzoneCount(ZtLevel)+1;
		bonusstages = Timer_GetMapzoneCount(ZtBonusLevel)+1;
		
		new tier = Timer_GetTier();
		
		Format(buffer, sizeof(buffer), "Tier: %d", tier);
		AddMenuItem(menu, "tier", buffer);
		
		if(Timer_GetMapzoneCount(ZtStart) > 0)
		{
			if(stages == 1)
				Format(buffer, sizeof(buffer), "Level: Linear");
			else
				Format(buffer, sizeof(buffer), "Stages: %d", stages);
				
			AddMenuItem(menu, "stages", buffer);
		}
		
		if(Timer_GetMapzoneCount(ZtBonusStart) > 0)
		{
			if(bonusstages == 1)
				Format(buffer, sizeof(buffer), "Bonus-Level: Linear");
			else
				Format(buffer, sizeof(buffer), "Bonus-Stages: %d", stages);
			AddMenuItem(menu, "bonusstages", buffer);
		}
		
		if(Timer_GetMapzoneCount(ZtShortEnd) > 0)
		{
			Format(buffer, sizeof(buffer), "Short-End: Enabled");
			AddMenuItem(menu, "shortend", buffer);
		}
		
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
}
	
public Handle_MapInfoMenu(Handle:menu, MenuAction:action, client, itemNum)
{
	if ( action == MenuAction_Select )
	{
		decl String:info[100], String:info2[100];
		new bool:found = GetMenuItem(menu, itemNum, info, sizeof(info), _, info2, sizeof(info2));
		if(found)
		{
			if(StrEqual(info, "teleme"))
			{
				FakeClientCommand(client, "sm_tpto");
			}
			else if(StrEqual(info, "levels"))
			{
				FakeClientCommand(client, "sm_stage");
			}
		}
	}
}

bool:PluginEnabled(const String:pluginNane[])
{
	decl String: pluginPath[PLATFORM_MAX_PATH + 1];
	BuildPath(Path_SM, pluginPath, sizeof(pluginPath), "plugins/%s", pluginNane);
	if(FileExists(pluginPath))
	{
		return true;
	}
	return false;
}