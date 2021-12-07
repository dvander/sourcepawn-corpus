#pragma semicolon 1
#include <sourcemod>
#include <morecolors>
#include <clientprefs>
#include <zombiereloaded>
#include <sdkhooks>

#define PLUGIN_VERSION "1.0.0"

#define LOCATION_CENTER 0
#define LOCATION_HINT 1
#define LOCATION_KEY_HINT 2

new Handle:g_cHealthEnabled = INVALID_HANDLE;
new Handle:g_cHealthLocation = INVALID_HANDLE;
new Handle:g_hEnabled = INVALID_HANDLE;
new Handle:g_hChatCommands = INVALID_HANDLE;
new Handle:g_hDefaultStatus = INVALID_HANDLE;
new Handle:g_hDefaultLocation = INVALID_HANDLE;

new g_iTeam[MAXPLAYERS + 1];
new bool:g_bFake[MAXPLAYERS + 1];
new bool:g_bLoaded[MAXPLAYERS + 1];
new g_iHealthLocation[MAXPLAYERS + 1];
new bool:g_bHealthDisplay[MAXPLAYERS + 1];

new g_iNumCommands, g_iDefaultLocation;
new bool:g_bEnabled, bool:g_bLateLoad, bool:g_bDefaultStatus;
new String:g_sChatCommands[16][32];

public Plugin:myinfo =
{
	name = "[ZR] Display", 
	author = "Panda", 
	description = "Provides various displays for Zombie: Reloaded.", 
	version = PLUGIN_VERSION, 
	url = "https://forums.alliedmods.net/"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	g_bLateLoad = late;
	return APLRes_Success;
}

public OnPluginStart()
{
	decl String:sTemp[192];
	LoadTranslations("common.phrases");
	LoadTranslations("zr_display.phrases");

	CreateConVar("zr_display_version", PLUGIN_VERSION, "[ZR] Display: Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_CHEAT|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hEnabled = CreateConVar("zr_display_enabled", "1", "Enables/Disables all features of this plugin. (0 = Disabled, 1 = Enabled)", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hEnabled, OnSettingsChange);
	g_bEnabled = GetConVarInt(g_hEnabled) ? true : false;
	
	g_hChatCommands = CreateConVar("zr_display_commands", "!ddisplay, /ddisplay, !display, /display", "The chat triggers available to clients to access display features. (\"\" = only via !settings)", FCVAR_NONE);
	HookConVarChange(g_hChatCommands, OnSettingsChange);
	GetConVarString(g_hChatCommands, sTemp, sizeof(sTemp));
	g_iNumCommands = ExplodeString(sTemp, ", ", g_sChatCommands, sizeof(g_sChatCommands), sizeof(g_sChatCommands[]));
	
	g_hDefaultStatus = CreateConVar("zr_display_default_status", "1", "The default display status for new clients. (0 = Disabled, 1 = Enabled)", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hDefaultStatus, OnSettingsChange);
	g_bDefaultStatus = GetConVarInt(g_hDefaultStatus) ? true : false;
	
	g_hDefaultLocation = CreateConVar("zr_display_default_location", "1", "The default display location for new clients. (0 = Center, 1 = Hint, 2 = Key Hint)", FCVAR_NONE, true, 0.0, true, 2.0);
	HookConVarChange(g_hDefaultLocation, OnSettingsChange);
	g_iDefaultLocation = GetConVarInt(g_hDefaultLocation);
	AutoExecConfig(true, "zr_display");
	
	AddCommandListener(Command_Say, "say");
	AddCommandListener(Command_Say, "say_team");
	HookEvent("player_team", Event_OnPlayerTeam, EventHookMode_Pre);

	SetCookieMenuItem(Menu_Cookies, 0, "[ZR] Display");
	g_cHealthEnabled = RegClientCookie("ZR_Display_Status", "[ZR] Display: The client's display status.", CookieAccess_Protected);
	g_cHealthLocation = RegClientCookie("ZR_Display_Location", "[ZR] Display: The client's display location.", CookieAccess_Protected);
}

public OnSettingsChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	if(cvar == g_hEnabled)
		g_bEnabled = bool:StringToInt(newvalue);
	else if(cvar == g_hChatCommands)
		g_iNumCommands = ExplodeString(newvalue, ", ", g_sChatCommands, sizeof(g_sChatCommands), sizeof(g_sChatCommands[]));
	else if(cvar == g_hDefaultStatus)
		g_bDefaultStatus = bool:StringToInt(newvalue);
	else if(cvar == g_hDefaultLocation)
		g_iDefaultLocation = StringToInt(newvalue);
}

public OnConfigsExecuted()
{
	if(g_bEnabled)
	{
		if(g_bLateLoad)
		{
			for(new i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i))
				{
					g_iTeam[i] = GetClientTeam(i);
					g_bFake[i] = IsFakeClient(i);
					SDKHook(i, SDKHook_TraceAttack, Hook_OnTraceAttack);
					
					if(!g_bFake[i])
					{
						if(!g_bLoaded[i] && AreClientCookiesCached(i))
							LoadClientData(i);
					}
					else
					{
						g_bLoaded[i] = true;
						g_iHealthLocation[i] = g_iDefaultLocation;
						g_bHealthDisplay[i] = g_bDefaultStatus;
					}
				}
			}
			
			g_bLateLoad = false;
		}
	}
}

public OnClientPutInServer(client)
{
	if(g_bEnabled)
	{
		g_bFake[client] = IsFakeClient(client);
		SDKHook(client, SDKHook_TraceAttack, Hook_OnTraceAttack);
	}
}

public OnClientPostAdminCheck(client)
{
	if(g_bEnabled && IsClientInGame(client))
	{
		if(!g_bFake[client])
		{
			if(!g_bLoaded[client] && AreClientCookiesCached(client))
				LoadClientData(client);
		}
		else
		{
			g_bLoaded[client] = true;
			g_iHealthLocation[client] = g_iDefaultLocation;
			g_bHealthDisplay[client] = g_bDefaultStatus;
		}
	}
}

public OnClientDisconnect(client)
{
	if(g_bEnabled)
	{
		g_iTeam[client] = 0;
	}
}

public OnClientCookiesCached(client)
{
	if(g_bEnabled)
	{
		if(!g_bLoaded[client] && !g_bFake[client])
		{
			LoadClientData(client);
		}
	}
}

public Action:Event_OnPlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(!client || !IsClientInGame(client))
			return Plugin_Continue;

		g_iTeam[client] = GetEventInt(event, "team");
	}
	
	return Plugin_Continue;
}

public Action:Command_Say(client, const String:command[], argc)
{
	if(g_bEnabled)
	{
		if(!client || !IsClientInGame(client))
			return Plugin_Continue;

		decl String:sText[192], String:sBuffer[24];
		GetCmdArgString(sText, sizeof(sText));

		new iStart;
		if(sText[strlen(sText) - 1] == '"')
		{
			sText[strlen(sText) - 1] = '\0';
			iStart = 1;
		}

		BreakString(sText[iStart], sBuffer, sizeof(sBuffer));
		for(new i = 0; i < g_iNumCommands; i++)
		{
			if(StrEqual(sBuffer, g_sChatCommands[i], false))
			{
				Menu_Display(client);
				return Plugin_Stop;
			}
		}
	}

	return Plugin_Continue;
}

LoadClientData(client)
{
	decl String:sCookie[4] = "";
	GetClientCookie(client, g_cHealthEnabled, sCookie, sizeof(sCookie));

	if(StrEqual(sCookie, "", false))
	{
		sCookie = g_bDefaultStatus ? "1" : "0";
		g_bHealthDisplay[client] = bool:StringToInt(sCookie);
		SetClientCookie(client, g_cHealthEnabled, sCookie);

		g_iHealthLocation[client] = g_iDefaultLocation;
		IntToString(g_iHealthLocation[client], sCookie, 4);
		SetClientCookie(client, g_cHealthLocation, sCookie);
	}
	else
	{
		g_bHealthDisplay[client] = bool:StringToInt(sCookie);

		GetClientCookie(client, g_cHealthLocation, sCookie, 4);
		g_iHealthLocation[client] = StringToInt(sCookie);
	}

	g_bLoaded[client] = true;
}

public Menu_Cookies(client, CookieMenuAction:action, any:info, String:buffer[], maxlen) 
{
	switch(action)
	{
		case CookieMenuAction_DisplayOption:
			Format(buffer, maxlen, "%t", "Menu_Title_Cookie", client);
		case CookieMenuAction_SelectOption:
		{
			if(g_bEnabled)
				Menu_Display(client);
		}
	}
}

Menu_Display(client)
{
	decl String:sBuffer[128];
	new Handle:hMenu = CreateMenu(MenuHandler_MenuDisplay);
	Format(sBuffer, sizeof(sBuffer), "%T", "Menu_Title_Main", client);
	SetMenuTitle(hMenu, sBuffer);
	SetMenuPagination(hMenu, MENU_NO_PAGINATION);
	SetMenuExitButton(hMenu, true);

	if(g_bHealthDisplay[client])
		Format(sBuffer, sizeof(sBuffer), "%T", "Menu_Option_Disable_Damage", client);
	else
		Format(sBuffer, sizeof(sBuffer), "%T", "Menu_Option_Enable_Damage", client);
	AddMenuItem(hMenu, "0", sBuffer);

	Format(sBuffer, sizeof(sBuffer), "%T", "Menu_Option_Select_Location", client);
	AddMenuItem(hMenu, "1", sBuffer);

	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
}

public MenuHandler_MenuDisplay(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
			CloseHandle(menu);
		case MenuAction_Select:
		{
			decl String:sTemp[8];
			GetMenuItem(menu, param2, sTemp, sizeof(sTemp));

			switch(StringToInt(sTemp))
			{
				case 0:
				{
					if(!g_bHealthDisplay[param1])
					{
						g_bHealthDisplay[param1] = true;
						CPrintToChat(param1, "%t%t", "Prefix_Chat", "Phrase_Display_Health_Enable");
						SetClientCookie(param1, g_cHealthEnabled, "1");
					}
					else
					{
						g_bHealthDisplay[param1] = false;
						CPrintToChat(param1, "%t%t", "Prefix_Chat", "Phrase_Display_Health_Disable");
						SetClientCookie(param1, g_cHealthEnabled, "0");
					}
					
					Menu_Display(param1);
				}
				case 1:
					Menu_Locations(param1);
			}
		}
	}
	
	return;
}

Menu_Locations(client)
{
	decl String:sBuffer[128];
	new Handle:hMenu = CreateMenu(MenuHandler_MenuLocations);
	Format(sBuffer, sizeof(sBuffer), "%T", "Menu_Title_Location", client);
	SetMenuTitle(hMenu, sBuffer);
	SetMenuExitButton(hMenu, true);
	SetMenuExitBackButton(hMenu, true);
	
	decl String:sSelect[8], String:sEmpty[8];
	Format(sSelect, sizeof(sSelect), "%T", "Menu_Option_Selected", client);
	Format(sEmpty, sizeof(sEmpty), "%T", "Menu_Option_Empty", client);

	Format(sBuffer, sizeof(sBuffer), "%s%T", (g_iHealthLocation[client] == LOCATION_CENTER) ? sSelect : sEmpty, "Menu_Option_Location_Center", client);
	AddMenuItem(hMenu, "0", sBuffer);
	
	Format(sBuffer, sizeof(sBuffer), "%s%T", (g_iHealthLocation[client] == LOCATION_HINT) ? sSelect : sEmpty, "Menu_Option_Location_Hint", client);
	AddMenuItem(hMenu, "1", sBuffer);
	
	Format(sBuffer, sizeof(sBuffer), "%s%T", (g_iHealthLocation[client] == LOCATION_KEY_HINT) ? sSelect : sEmpty, "Menu_Option_Location_Key_Hint", client);
	AddMenuItem(hMenu, "2", sBuffer);
	
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
}

public MenuHandler_MenuLocations(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
			CloseHandle(menu);
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_Exit || param2 == MenuCancel_ExitBack)
				Menu_Display(param1);
		}
		case MenuAction_Select:
		{
			decl String:sTemp[4];
			GetMenuItem(menu, param2, sTemp, sizeof(sTemp));
			new iTemp = StringToInt(sTemp);

			if(iTemp != g_iHealthLocation[param1])
			{
				g_iHealthLocation[param1] = iTemp;
				switch(g_iHealthLocation[param1])
				{
					case LOCATION_CENTER:
					{
						CPrintToChat(param1, "%t%t", "Prefix_Chat", "Phrase_Health_Location_Center");
						PrintCenterText(param1, "%t", "Phrase_Display_Sample");
					}
					case LOCATION_HINT:
					{
						CPrintToChat(param1, "%t%t", "Prefix_Chat", "Phrase_Health_Location_Hint");
						PrintHintText(param1, "%t", "Phrase_Display_Sample");
					}
					case LOCATION_KEY_HINT:
					{
						CPrintToChat(param1, "%t%t", "Prefix_Chat", "Phrase_Health_Location_Key_Hint");
						decl String:sPhrase[32];
						Format(sPhrase, sizeof(sPhrase), "%T", "Phrase_Display_Sample", param1);
						new Handle:hMessage = StartMessageOne("KeyHintText", param1);
						BfWriteByte(hMessage, 1);
						BfWriteString(hMessage, sPhrase);
						EndMessage();
					}
				}

				SetClientCookie(param1, g_cHealthLocation, sTemp);
			}

			Menu_Locations(param1);
		}
	}

	return;
}

public Action:Hook_OnTraceAttack(victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup)
{
	if(attacker > 0 && attacker <= MaxClients && IsClientInGame(attacker))
	{
		if(victim > 0 && victim <= MaxClients && IsClientInGame(victim))
		{
			if(g_bHealthDisplay[attacker] && ZR_IsClientZombie(victim) && ZR_IsClientHuman(attacker))
			{
				new iHealth = GetClientHealth(victim);
				switch(g_iHealthLocation[attacker])
				{
					case LOCATION_CENTER:
					{
						PrintCenterText(attacker, "%t", "Phrase_Display_Remaining_Health", victim, iHealth);
					}
					case LOCATION_HINT:
					{
						PrintHintText(attacker, "%t", "Phrase_Display_Remaining_Health", victim, iHealth);
					}
					case LOCATION_KEY_HINT:
					{
						decl String:sPhrase[32];
						Format(sPhrase, sizeof(sPhrase), "%T", "Phrase_Display_Remaining_Health", attacker, victim, iHealth);
						new Handle:hMessage = StartMessageOne("KeyHintText", attacker);
						BfWriteByte(hMessage, 1);
						BfWriteString(hMessage, sPhrase);
						EndMessage();
					}
				}
			}
		}
	}
	
	return Plugin_Continue;
}