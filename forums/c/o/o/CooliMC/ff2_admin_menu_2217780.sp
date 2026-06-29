#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <adminmenu>
#include <freak_fortress_2>
#include <clientprefs>

new currentTarget[MAXPLAYERS+1];
new Handle:hAdminMenu = INVALID_HANDLE;
new Handle:FF2MenuCookies;
new Handle:FF2Cookies;
new bosson = 0;

#define PLUGIN_VERSION "1.0.1"

public Plugin:myinfo = 
{
	name 		= "Freak Fortress 2 AdminMenu",
	author		= "CooliMC",
	description = "Admin Menu for Freak Fortress 2 plugin.",
	version 	= PLUGIN_VERSION,
	url 		= "http://google.de"
}

public OnPluginStart()
{
	HookEvent("teamplay_round_win", OnRoundEnd);
	
	FF2MenuCookies=RegClientCookie("ff2_menu_cookies", "", CookieAccess_Protected);
	FF2Cookies=RegClientCookie("ff2_cookies_mk2", "", CookieAccess_Protected);
	
	new Handle:topmenu;
	if ( LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE) )
	{
		OnAdminMenuReady(topmenu);
	}
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "adminmenu"))
	{
		hAdminMenu = INVALID_HANDLE;
	}
}

public Action:OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	new String:buffer[2];
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && (!IsFakeClient(i)))
		{
			GetClientCookie(i, FF2MenuCookies, buffer, sizeof(buffer));
			
			if(StringToInt(buffer) == 0)
			{	
				for(new j = 1; j <=100; j++)
				{
					CreateTimer(float(j)*0.05, SetPointBack, i);
				}
			}
		}
	}  
}

public Action:SetPointBack(Handle:timer, any:user)
{
	decl String:cookies[24], String:values[8][5];
	
	GetClientCookie(user, FF2Cookies, cookies, sizeof(cookies));
	ExplodeString(cookies, " ", values, 8, 5);
	Format(cookies, sizeof(cookies), "%i %s %s %s %s %s %s %s", 0, values[1], values[2], values[3], values[4], values[5], values[6], values[7]);
	SetClientCookie(user, FF2Cookies, cookies);
}

public OnAdminMenuReady(Handle:topmenu)
{
	if (topmenu == hAdminMenu)
	{
		return;
	}
	
	hAdminMenu = topmenu;
	new TopMenuObject:server_commands = FindTopMenuCategory(hAdminMenu, ADMINMENU_SERVERCOMMANDS);
	if (server_commands != INVALID_TOPMENUOBJECT)
	{
		AddToTopMenu(hAdminMenu, "sm_ff2admin", TopMenuObject_Item, AdminMenuFF2, server_commands, "sm_ff2admin", ADMFLAG_KICK);
	}
}

public AdminMenuFF2(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "FreakFortress 2 Menu");
	}
	else if (action == TopMenuAction_SelectOption)
	{
		DisplayFF2Options(param);
	}
}

public OnClientPutInServer(client)
{
	if(!AreClientCookiesCached(client))
	{
		PrintToChatAll("KP");
		return;
	}

	new String:buffer[2];
	GetClientCookie(client, FF2MenuCookies, buffer, sizeof(buffer));
	if(!buffer[0])
	{
		SetClientCookie(client, FF2MenuCookies, "1");
	}
}

DisplayFF2Options(client)
{
	if (client && IsClientInGame(client) && !IsFakeClient(client))
	{
		new Handle:MainMenu = CreateMenu(MenuHandler_FF2);

		SetMenuTitle(MainMenu, "FF2 Menu - Choose Option:");
		
		AddMenuItem(MainMenu, "ff2_select", "Select Next Bossplayer");
		AddMenuItem(MainMenu, "ff2_Stringset", "Select Bosspack");
		AddMenuItem(MainMenu, "ff2_addpoints", "Add Queue Points");
		AddMenuItem(MainMenu, "ff2_get_bosses", "Select Next Character");
		AddMenuItem(MainMenu, "ff2_set_glow", "Let A Player Glowing");
		AddMenuItem(MainMenu, "ff2_toggle_queue","Toggle Bossbecoming");
		AddMenuItem(MainMenu, "ff2_stop_music", "Stop Boss' Music");
		
		DisplayMenu(MainMenu, client, MENU_TIME_FOREVER);
	}
}

public MenuHandler_FF2(Handle:MainMenu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		decl String:admName[64];
		GetClientName(param1, admName, sizeof(admName));
		switch (param2)
		{
			case 0 :
			{
				MenuChooseNext(param1, -1);
			}
			case 1 :
			{
				MenuChooseBosspack(param1, -1);
			}
			case 2 :
			{
				MenuPreAddPoints(param1, -1);
			}
			case 3 :
			{
				MenuSetCharacter(param1, -1);
			}
			case 4 :
			{
				MenuSetGlow(param1, -1);
			}
			case 5 :
			{
				MenuToggleBoss(param1, -1);
			}
			case 6 :
			{
				FF2_StopMusic(0);
				PrintToChatAllEx(param1, "\x04FF2-Menu\x05 |\x03 %s\x01 stops the\x04 Boss\'\x01 music.", admName);
				if (hAdminMenu != INVALID_HANDLE)
				{
					DisplayFF2Options(param1);
				}
			}
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(MainMenu);
	}
}

public Action:MenuToggleBoss(client, args)
{
	if (client && IsClientInGame(client) && !IsFakeClient(client))
	{
		new Handle:menuToggle = CreateMenu(MenuHandler_HaleToggle);
		
		SetMenuTitle(menuToggle, "Select Player for Bosstoggle:");
		SetMenuExitBackButton(menuToggle, true);
		AddTargetsToMenu2(menuToggle, client, COMMAND_FILTER_NO_BOTS|COMMAND_FILTER_CONNECTED);
		
		DisplayMenu(menuToggle, client, MENU_TIME_FOREVER);
	}
}

public MenuHandler_HaleToggle(Handle:menuToggle, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		decl String:info[32];
		new userid, target;
		
		GetMenuItem(menuToggle, param2, info, sizeof(info));
		userid = StringToInt(info);

		target = GetClientOfUserId(userid);
		
		if (AreClientCookiesCached(target))
		{
			if(IsClientInGame(target))
			{
				currentTarget[param1] = target;
				ToggleBoss(param1, -1);
			}
		}
		else
		{
			MenuToggleBoss(param1, -1);
		}
	}
	else if (param2 == MenuCancel_ExitBack)
	{
		DisplayFF2Options(param1);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menuToggle);
	}
}

public Action:ToggleBoss(client, args)
{
	if (IsClientInGame(client))
	{
		new String:buffer[2];
		new String:s[45];
		new String:g[12];
		new String:b[2];
		GetClientCookie(client, FF2MenuCookies, buffer, sizeof(buffer));
		
		if(StringToInt(buffer) == 0)
		{
			Format(s,sizeof(s),"At the moment you won't become the Boss!");
			Format(g,sizeof(g),"Toggle ON");
			Format(b,sizeof(b),"1");
		}
		else
		{
			Format(s,sizeof(s),"At the moment you will become the Boss!");
			Format(g,sizeof(g),"Toggle OFF");
			Format(b,sizeof(b),"0");
		}
		
		if(client && IsClientInGame(client) && !IsFakeClient(client))
		{
			new Handle:menuBossToggle = CreateMenu(MenuHandler_BossToggle);
	
			SetMenuTitle(menuBossToggle, s);
			SetMenuExitBackButton(menuBossToggle, true);
			
			AddMenuItem(menuBossToggle, b, g);
			
			DisplayMenu(menuBossToggle, client, MENU_TIME_FOREVER);
		}
	}
}

public MenuHandler_BossToggle(Handle:menuBossToggle, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		decl String:admName[64];
		decl String:pName[64];
		
		GetClientName(param1, admName, sizeof(admName));
		GetClientName(currentTarget[param1], pName, sizeof(pName));
		
		decl String:info[2];
		GetMenuItem(menuBossToggle, param2, info, sizeof(info));

		SetClientCookie(currentTarget[param1], FF2MenuCookies, info);

		ToggleBoss(param1, -1);
	}
	else if (param2 == MenuCancel_ExitBack)
	{
		DisplayFF2Options(param1);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menuBossToggle);
	}
}

public Action:MenuSetCharacter(client, args)
{
	decl String:Special_Name[64];
	decl Handle:BossKV;
	
	if(client && IsClientInGame(client) && !IsFakeClient(client))
	{
		new Handle:menuCharacter = CreateMenu(MenuHandler_CharacterSelect);
	
		SetMenuTitle(menuCharacter, "Select the next Character:");
		SetMenuExitBackButton(menuCharacter, true);
		
		for (new i = 0; (BossKV=FF2_GetSpecialKV(i,true)); i++)
		{
			if (KvGetNum(BossKV, "blocked",0)) 
			{
				continue;
			}
			KvGetString(BossKV, "name", Special_Name, 64);
			AddMenuItem(menuCharacter, Special_Name ,Special_Name);
		}
		DisplayMenu(menuCharacter, client, MENU_TIME_FOREVER);
	}
	return Plugin_Handled;
}

public MenuHandler_CharacterSelect(Handle:menuCharacter, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		decl String:info[64];
		decl String:admName[64];
	
		GetClientName(param1, admName, sizeof(admName));
		GetMenuItem(menuCharacter, param2, info, sizeof(info));
	
		ServerCommand("ff2_special %s", info);
		PrintToChatAllEx(param1, "\x04FF2-Menu\x05 |\x03 %s\x01 set \x05 %s\x01 as the next Character!", admName, info);
		
		MenuSetCharacter(param1, -1);
	}
	else if (param2 == MenuCancel_ExitBack)
	{
		DisplayFF2Options(param1);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menuCharacter);
	}
}

public Action:MenuSetGlow(client, args)
{
	if(client && IsClientInGame(client) && !IsFakeClient(client))
	{
		new Handle:menuSelect = CreateMenu(MenuHandler_GlowSelect);
		
		SetMenuTitle(menuSelect, "Select a player:");
		SetMenuExitBackButton(menuSelect, true);
		
		AddTargetsToMenu(menuSelect, client, true, true);
		
		DisplayMenu(menuSelect, client, MENU_TIME_FOREVER);
	}
}

public MenuHandler_GlowSelect(Handle:menuSelect, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		decl String:info[32];
		new userid, target;
		
		GetMenuItem(menuSelect, param2, info, sizeof(info));
		userid = StringToInt(info);

		target = GetClientOfUserId(userid);
		
		if ( IsClientInGame(target) )
		{
			currentTarget[param1] = target;
			GlowSelect(param1, -1);
		}
	}
	else if (param2 == MenuCancel_ExitBack)
	{
		DisplayFF2Options(param1);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menuSelect);
	}
}

public Action:GlowSelect(client, args)
{
	if (client && IsClientInGame(client) && !IsFakeClient(client))
	{
		new Handle:menuAddGlowTime = CreateMenu(MenuHandler_AddGlowTime);

		SetMenuTitle(menuAddGlowTime, "Select Glowing Time:");
		SetMenuExitBackButton(menuAddGlowTime, true);
		
		AddMenuItem(menuAddGlowTime, "-1", "Forever");
		AddMenuItem(menuAddGlowTime, "0", "Stop Glowing");
		AddMenuItem(menuAddGlowTime, "1", "1 Second");
		AddMenuItem(menuAddGlowTime, "5", "5 Seconds");
		AddMenuItem(menuAddGlowTime, "10", "10 Seconds");
		AddMenuItem(menuAddGlowTime, "30", "30 Seconds");
		AddMenuItem(menuAddGlowTime, "60", "60 Seconds");
		AddMenuItem(menuAddGlowTime, "120", "2 Minutes");
		AddMenuItem(menuAddGlowTime, "180", "3 Minutes");
		AddMenuItem(menuAddGlowTime, "240", "4 Minutes");
		AddMenuItem(menuAddGlowTime, "300", "5 Minutes");
		
		DisplayMenu(menuAddGlowTime, client, MENU_TIME_FOREVER);
	}
}

public MenuHandler_AddGlowTime(Handle:menuAddGlowTime, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		decl String:admName[64];
		decl String:pName[64];
		
		GetClientName(param1, admName, sizeof(admName));
		GetClientName(currentTarget[param1], pName, sizeof(pName));
		
		decl String:info[32];
		GetMenuItem(menuAddGlowTime, param2, info, sizeof(info));

		if(FF2_GetBossIndex(currentTarget[param1]) != -1) bosson = 1;
		if(StringToInt(info)==0)
		{
			SetEntProp(currentTarget[param1], Prop_Send, "m_bGlowEnabled", 0);
			if(FF2_GetBossIndex(currentTarget[param1]) != -1) bosson = 0;
		}
		else
		{
			SetEntProp(currentTarget[param1], Prop_Send, "m_bGlowEnabled", 1);
			if(bosson == 1) BossGlow(currentTarget[param1], -1);
			if(StringToInt(info)>=0)
			{
				CreateTimer(StringToFloat(info), EndGlow, currentTarget[param1]);
				PrintToChatAllEx(param1, "\x04FF2-Menu\x05 |\x03 %s\x01 let\x05 %s\x01 glow for\x04 %s\x01 seconds!", admName, pName, info);
			}
			else
			{
				PrintToChatAllEx(param1, "\x04FF2-Menu\x05 |\x03 %s\x01 let\x05 %s\x01 glow!", admName, pName, info);
			}
		}
		MenuSetGlow(param1, -1);
	}
	else if (param2 == MenuCancel_ExitBack)
	{
		DisplayFF2Options(param1);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menuAddGlowTime);
	}
}

public Action:EndGlow(Handle:timer, any:userid)
{
	SetEntProp(userid, Prop_Send, "m_bGlowEnabled", 0);
	if(FF2_GetBossIndex(userid) != -1) bosson = 0;
}

public Action:BossGlow(client, args)
{
	if(bosson == 1&&FF2_GetBossIndex(client) != -1)
	{
		SetEntProp(client, Prop_Send, "m_bGlowEnabled", 1);
		//Critical Time ;D
		CreateTimer(0.01, BossGlowTimer, client);
	}
}

public Action:BossGlowTimer(Handle:timer, any:user)
{
	BossGlow(user, -1);
}

public Action:MenuChooseNext(client, args)
{
	if (client && IsClientInGame(client) && !IsFakeClient(client))
	{
		new Handle:menuSelect = CreateMenu(MenuHandler_HaleSelect);
		
		SetMenuTitle(menuSelect, "Select the next Bossplayer:");
		SetMenuExitBackButton(menuSelect, true);
		
		AddTargetsToMenu2(menuSelect, client, COMMAND_FILTER_NO_BOTS|COMMAND_FILTER_CONNECTED);
		
		DisplayMenu(menuSelect, client, MENU_TIME_FOREVER);
	}
}

public MenuHandler_HaleSelect(Handle:menuSelect, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		decl String:admName[64];
		decl String:info[32];
		decl String:pName[64];
		
		GetMenuItem(menuSelect, param2, info, sizeof(info));
		GetClientName(param1, admName, sizeof(admName));
		GetClientName(GetClientOfUserId(StringToInt(info)), pName, sizeof(pName));
		
		FF2_SetQueuePoints(GetClientOfUserId(StringToInt(info)), 500);
		PrintToChatAllEx(param1, "\x04FF2-Menu\x05 |\x03 %s\x01 selected\x05 %s\x01 as the next\x04 Boss", admName, pName);
		
		MenuChooseNext(param1, -1);
	}
	else if (param2 == MenuCancel_ExitBack)
	{
		DisplayFF2Options(param1);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menuSelect);
	}
}

public Action:MenuChooseBosspack(client, args)
{
	static String:config[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, config, PLATFORM_MAX_PATH, "configs/freak_fortress_2/characters.cfg");
	new Handle:Kv=CreateKeyValues("");
	FileToKeyValues(Kv, config);
	
	if (client && IsClientInGame(client) && !IsFakeClient(client))
	{
		new Handle:menuChooseBosspack = CreateMenu(MenuHandler_FF2Bosspack);

		SetMenuTitle(menuChooseBosspack, "Choose Next Bosspack:");
		SetMenuExitBackButton(menuChooseBosspack, true);
		for(new i; ; i++)
		{
			static String:argu[32];
			IntToString(i, argu, sizeof(argu));
		
			KvGetSectionName(Kv, config, sizeof(config));
			
			AddMenuItem(menuChooseBosspack, config, config);
			
			if(!KvGotoNextKey(Kv))
			{
				break;
			}
		}
		DisplayMenu(menuChooseBosspack, client, MENU_TIME_FOREVER);
	}
}

public MenuHandler_FF2Bosspack(Handle:menuSelect, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		decl String:admName[64];
		GetClientName(param1, admName, sizeof(admName));
		
		decl String:Bosspack[32];
		GetMenuItem(menuSelect, param2, Bosspack, sizeof(Bosspack));
		
		ServerCommand("ff2_Stringset %s", Bosspack);
		PrintToChatAllEx(param1, "\x04FF2-Menu\x05 |\x03 %s\x01 sets\x05 %s \x01as the next\x04 Bosspack", admName, Bosspack);
		MenuChooseBosspack(param1, -1);
	}
	else if (param2 == MenuCancel_ExitBack)
	{
		DisplayFF2Options(param1);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menuSelect);
	}
}

public Action:MenuPreAddPoints(client, args)
{
	if (client && IsClientInGame(client) && !IsFakeClient(client))
	{
		new Handle:menuPreAddPoints = CreateMenu(MenuHandler_PreAddPoints);
		
		SetMenuTitle(menuPreAddPoints, "Choose player to add points:");
		SetMenuExitBackButton(menuPreAddPoints, true);
		
		AddTargetsToMenu2(menuPreAddPoints, client, COMMAND_FILTER_NO_BOTS|COMMAND_FILTER_CONNECTED);
		
		DisplayMenu(menuPreAddPoints, client, MENU_TIME_FOREVER);
	}
}

public MenuHandler_PreAddPoints(Handle:menuPreAddPoints, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		decl String:info[32];
		new userid, target;
		
		GetMenuItem(menuPreAddPoints, param2, info, sizeof(info));
		userid = StringToInt(info);

		target = GetClientOfUserId(userid);
		
		if ( IsClientInGame(target) )
		{
			currentTarget[param1] = target;
			MenuAddPoint(param1, -1);
		}
	}
	else if (param2 == MenuCancel_ExitBack)
	{
		DisplayFF2Options(param1);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menuPreAddPoints);
	}
}

public Action:MenuAddPoint(client, args)
{
	if (client && IsClientInGame(client) && !IsFakeClient(client))
	{
		new Handle:menuAddPoints = CreateMenu(MenuHandler_AddPoints);

		SetMenuTitle(menuAddPoints, "Choose amount of Points:");
		SetMenuExitBackButton(menuAddPoints, true);
		
		AddMenuItem(menuAddPoints, "10", "10 Points");
		AddMenuItem(menuAddPoints, "20", "20 Points");
		AddMenuItem(menuAddPoints, "30", "30 Points");
		AddMenuItem(menuAddPoints, "40", "40 Points");
		AddMenuItem(menuAddPoints, "50", "50 Points");
		AddMenuItem(menuAddPoints, "100", "100 Points");
		AddMenuItem(menuAddPoints, "150", "150 Points");
		AddMenuItem(menuAddPoints, "200", "200 Points");
		
		DisplayMenu(menuAddPoints, client, MENU_TIME_FOREVER);
	}
	
	return Plugin_Handled;
}

public MenuHandler_AddPoints(Handle:menuAddPoints, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		decl String:admName[64];
		decl String:pName[64];
		decl String:info[32];
		
		GetClientName(param1, admName, sizeof(admName));
		GetClientName(currentTarget[param1], pName, sizeof(pName));
		GetMenuItem(menuAddPoints, param2, info, sizeof(info));
		
		FF2_SetQueuePoints(currentTarget[param1], (StringToInt(info)+FF2_GetQueuePoints(currentTarget[param1])));
		PrintToChatAllEx(param1, "\x04FF2-Menu\x05 |\x03 %s\x01 added\x05 %s Points\x01 to:\x04 %s", admName, info, pName);
		MenuPreAddPoints(param1, -1);
	}
	else if (param2 == MenuCancel_ExitBack)
	{
		MenuPreAddPoints(param1, -1);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menuAddPoints);
	}
}


public PrintToChatAllEx(from, const String:format[], any:...)
{
	decl String:message[512];
	VFormat(message, sizeof(message), format, 3);

	new Handle:hBf = StartMessageAll("SayText2");
	if (hBf != INVALID_HANDLE)
	{
		BfWriteByte(hBf, from);
		BfWriteByte(hBf, true);
		BfWriteString(hBf, message);
	
		EndMessage();
	}
}