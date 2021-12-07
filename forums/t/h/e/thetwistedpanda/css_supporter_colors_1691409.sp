/*
	Revision 1.0.6
	---
	Removed an infinite reoccuring timer initated by css_colors_reapply_time.
*/
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <colors>
#include <clientprefs>
#include <cstrike>

#define PLUGIN_VERSION "1.0.5"

//Array Indexes for g_bColorData
#define INDEX_MODEL 0
#define INDEX_WEAPON 1
#define INDEX_TOTAL 2

#define COLOR_RED 0
#define COLOR_GREEN 1
#define COLOR_BLUE 2
#define COLOR_TOTAL 3

new Handle:g_hEnabled = INVALID_HANDLE;
new Handle:g_hFlag = INVALID_HANDLE;
new Handle:g_hChatCommands = INVALID_HANDLE;
new Handle:g_hApplyDelay = INVALID_HANDLE;
new Handle:g_hEnableModels = INVALID_HANDLE;
new Handle:g_hEnableWeapons = INVALID_HANDLE;
new Handle:g_hRedModels = INVALID_HANDLE;
new Handle:g_hBlueModels = INVALID_HANDLE;
new Handle:g_hRedWeapons = INVALID_HANDLE;
new Handle:g_hBlueWeapons = INVALID_HANDLE;
new Handle:g_cModelEnabled = INVALID_HANDLE;
new Handle:g_cWeaponEnabled = INVALID_HANDLE;
new Handle:g_cModelRedColor = INVALID_HANDLE;
new Handle:g_cModelBlueColor = INVALID_HANDLE;
new Handle:g_cWeaponRedColor = INVALID_HANDLE;
new Handle:g_cWeaponBlueColor = INVALID_HANDLE;

new bool:g_bColored[2048];

new g_iTeam[MAXPLAYERS + 1];
new bool:g_bAlive[MAXPLAYERS + 1];
new bool:g_bLoaded[MAXPLAYERS + 1];
new bool:g_bAccess[MAXPLAYERS + 1];
new bool:g_bFake[MAXPLAYERS + 1];
new g_iPlayerModelsRed[MAXPLAYERS + 1][COLOR_TOTAL];
new g_iPlayerModelsBlue[MAXPLAYERS + 1][COLOR_TOTAL];
new g_iPlayerWeaponsRed[MAXPLAYERS + 1][COLOR_TOTAL];
new g_iPlayerWeaponsBlue[MAXPLAYERS + 1][COLOR_TOTAL];
new bool:g_bColorData[MAXPLAYERS + 1][INDEX_TOTAL];

new bool:g_bEnabled, bool:g_bLateLoad, bool:g_bEnableModels, bool:g_bEnableWeapons;
new String:g_sChatCommands[16][32], String:g_sRedModels[12], String:g_sBlueModels[12], String:g_sRedWeapons[12], String:g_sBlueWeapons[12], String:g_sPrefixChat[32], String:g_sPrefixSelect[16], String:g_sPrefixEmpty[16];
new Float:g_fApplyDelay;
new g_iNumCommands, g_iAccessFlag, g_iRedModels[3], g_iBlueModels[3], g_iRedWeapons[3], g_iBlueWeapons[3];

public Plugin:myinfo =
{
	name = "CSS Supporter: Colors", 
	author = "Twisted|Panda", 
	description = "Provides functionality for modifying weapon and model colors.", 
	version = PLUGIN_VERSION, 
	url = "http://ominousgaming.com"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	g_bLateLoad = late;
	return APLRes_Success;
}

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("css_supporter_colors.phrases");

	CreateConVar("css_colors_version", PLUGIN_VERSION, "Supporter Colors: Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hEnabled = CreateConVar("css_colors_enabled", "1", "Enables/disables all features of this plugin.", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hEnabled, OnSettingsChange);
	g_hFlag = CreateConVar("css_colors_flag", "r", "If \"\", everyone can use Supporter Colors, otherwise, only players with this flag or the \"Colors_Access\" override can access.", FCVAR_NONE);
	HookConVarChange(g_hFlag, OnSettingsChange);
	g_hChatCommands = CreateConVar("css_colors_commands", "!colors, /colors, !glow, /glow", "The chat triggers available to clients to access trail features.", FCVAR_NONE);
	HookConVarChange(g_hChatCommands, OnSettingsChange);
	g_hApplyDelay = CreateConVar("css_colors_reapply_time", "10", "The number of seconds after a player spawns for their model color to be reapplied, in case another plugin removes it.", FCVAR_NONE, true, 0.0);
	HookConVarChange(g_hApplyDelay, OnSettingsChange);
	
	g_hEnableModels = CreateConVar("css_colors_enable_models", "1", "Controls the model coloring portion of the plugin. (0 = Disabled, 1 = Enabled)", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hEnableModels, OnSettingsChange);
	g_hRedModels = CreateConVar("css_colors_default_red_models", "250 250 250", "The default model colors for new clients, for the Terrorist team.", FCVAR_NONE);
	HookConVarChange(g_hRedModels, OnSettingsChange);
	g_hBlueModels = CreateConVar("css_colors_default_blue_models", "250 250 250", "The default model colors for new clients, for the Counter-Terrorist team.", FCVAR_NONE);
	HookConVarChange(g_hBlueModels, OnSettingsChange);
	g_hEnableWeapons = CreateConVar("css_colors_enable_weapons", "1", "Controls the weapon/projectile coloring portion of the plugin. (0 = Disabled, 1 = Enabled)", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hEnableWeapons, OnSettingsChange);
	g_hRedWeapons = CreateConVar("css_colors_default_red_weapons", "250 250 250", "The default weapon colors for new clients, for the Terrorist team.", FCVAR_NONE);
	HookConVarChange(g_hRedWeapons, OnSettingsChange);
	g_hBlueWeapons = CreateConVar("css_colors_default_blue_weapons", "250 250 250", "The default weapon colors for new clients, for the Counter-Terrorist team.", FCVAR_NONE);
	HookConVarChange(g_hBlueWeapons, OnSettingsChange);
	AutoExecConfig(true, "css_supporter_colors");

	AddCommandListener(Command_Say, "say");
	AddCommandListener(Command_Say, "say_team");
	HookEvent("player_team", Event_OnPlayerTeam, EventHookMode_Pre);
	HookEvent("player_spawn", Event_OnPlayerSpawn, EventHookMode_Post);
	HookEvent("player_death", Event_OnPlayerDeath, EventHookMode_Pre);

	SetCookieMenuItem(Menu_Cookies, 0, "Color Settings");
	g_cModelEnabled = RegClientCookie("SupporterColors_Models", "Supporter Colors: The client's model color status.", CookieAccess_Private);
	g_cModelRedColor = RegClientCookie("SupporterColors_RedModel", "Supporter Colors: The client's model color for Terrorist team. ", CookieAccess_Private);
	g_cModelBlueColor = RegClientCookie("SupporterColors_BlueModel", "Supporter Colors: The client's model color for Counter-Terrorist team.", CookieAccess_Private);
	g_cWeaponEnabled = RegClientCookie("SupporterColors_Weapons", "Supporter Colors: The client's weapon color status.", CookieAccess_Private);
	g_cWeaponRedColor = RegClientCookie("SupporterColors_RedWeapon", "Supporter Colors: The client's weapon color for Counter-Terrorist team.", CookieAccess_Private);
	g_cWeaponBlueColor = RegClientCookie("SupporterColors_BlueWeapon", "Supporter Colors: The client's weapon color for Counter-Terrorist team.", CookieAccess_Private);

	Void_SetDefaults();
}

public OnConfigsExecuted()
{
	if(g_bEnabled)
	{
		Format(g_sPrefixChat, 32, "%T", "Prefix_Chat", LANG_SERVER);
		Format(g_sPrefixSelect, 16, "%T", "Menu_Option_Selected", LANG_SERVER);
		Format(g_sPrefixEmpty, 16, "%T", "Menu_Option_Empty", LANG_SERVER);

		if(g_bLateLoad)
		{
			for(new i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i))
				{
					g_iTeam[i] = GetClientTeam(i);
					g_bAlive[i] = IsPlayerAlive(i) ? true : false;
					g_bFake[i] = IsFakeClient(i) ? true : false;
					g_bAccess[i] = CheckCommandAccess(i, "Colors_Access", g_iAccessFlag);
					
					SDKHook(i, SDKHook_WeaponSwitch, Hook_OnWeaponSwitch);
					SDKHook(i, SDKHook_WeaponDrop, Hook_OnWeaponDrop);

					if(g_bAccess[i])
					{
						if(!g_bFake[i])
						{
							if(!g_bLoaded[i] && AreClientCookiesCached(i))
								Void_LoadCookies(i);
						}
						else
						{
							g_bLoaded[i] = true;
							g_bColorData[i][INDEX_MODEL] = g_bEnableModels;
							if(g_bEnableModels)
							{
								g_iPlayerModelsRed[i] = g_iRedModels;
								g_iPlayerModelsBlue[i] = g_iBlueModels;
							}
							g_bColorData[i][INDEX_WEAPON] = g_bEnableWeapons;
							if(g_bEnableWeapons)
							{
								g_iPlayerWeaponsRed[i] = g_iRedWeapons;
								g_iPlayerWeaponsBlue[i] = g_iBlueWeapons;
							}
						}
					}
				}
			}
			
			g_bLateLoad = false;
		}
	}
}

public OnEntityCreated(entity, const String:classname[])
{
	if(g_bEnabled && entity > 0)
	{
		if(g_bEnableWeapons && StrContains(classname, "_projectile", false) != -1)
			CreateTimer(0.1, Timer_ColorEntity, EntIndexToEntRef(entity));
	}
}

public Action:Timer_ColorEntity(Handle:timer, any:ref)
{
	new entity = EntRefToEntIndex(ref);
	if(entity != INVALID_ENT_REFERENCE)
	{
		new client = GetEntPropEnt(entity, Prop_Send, "m_hThrower");
		if(client > 0 && IsClientInGame(client) && g_bAccess[client] && g_bColorData[client][INDEX_WEAPON])
		{
			g_bColored[entity] = true;

			switch(g_iTeam[client])
			{
				case CS_TEAM_T:
					SetEntityRenderColor(entity, g_iPlayerModelsRed[client][0], g_iPlayerModelsRed[client][1], g_iPlayerModelsRed[client][2], 255);
				case CS_TEAM_CT:
					SetEntityRenderColor(entity, g_iPlayerModelsBlue[client][0], g_iPlayerModelsBlue[client][1], g_iPlayerModelsBlue[client][2], 255);
			}			
			SetEntityRenderMode(entity, RenderMode:1);
		}
	}
}

public OnClientConnected(client)
{
	if(g_bEnabled)
	{
		g_bFake[client] = IsFakeClient(client) ? true : false;
	}
}

public OnClientPutInServer(client)
{
	if(g_bEnabled)
	{
		SDKHook(client, SDKHook_WeaponSwitch, Hook_OnWeaponSwitch);
		SDKHook(client, SDKHook_WeaponDrop, Hook_OnWeaponDrop);
	}
}

public OnEntityDestroyed(entity)
{
	if(entity > 0)
	{
		if(g_bColored[entity])
			g_bColored[entity] = false;
	}
}

public OnClientPostAdminCheck(client)
{
	if(g_bEnabled && IsClientInGame(client))
	{
		g_bAccess[client] = CheckCommandAccess(client, "Colors_Access", g_iAccessFlag);

		if(g_bAccess[client])
		{
			if(!g_bFake[client])
			{
				if(!g_bLoaded[client] && AreClientCookiesCached(client))
					Void_LoadCookies(client);
			}
			else
			{
				g_bLoaded[client] = true;
				g_bColorData[client][INDEX_MODEL] = g_bEnableModels;
				if(g_bEnableModels)
				{
					g_iPlayerModelsRed[client] = g_iRedModels;
					g_iPlayerModelsBlue[client] = g_iBlueModels;
				}
				g_bColorData[client][INDEX_WEAPON] = g_bEnableWeapons;
				if(g_bEnableWeapons)
				{
					g_iPlayerWeaponsRed[client] = g_iRedWeapons;
					g_iPlayerWeaponsBlue[client] = g_iBlueWeapons;
				}
			}
		}
	}
}

public OnClientDisconnect(client)
{
	if(g_bEnabled)
	{
		g_iTeam[client] = 0;
		g_bAlive[client] = false;
		g_bLoaded[client] = false;
		g_bAccess[client] = false;
	}
}

public OnClientCookiesCached(client)
{
	if(g_bEnabled)
	{
		if(g_bAccess[client] && !g_bLoaded[client] && !g_bFake[client])
		{
			Void_LoadCookies(client);

			if(g_bAlive[client] && g_iTeam[client] >= CS_TEAM_T)
			{
				if(g_bEnableModels && g_bColorData[client][INDEX_MODEL])
				{
					switch(g_iTeam[client])
					{
						case CS_TEAM_T:
							SetEntityRenderColor(client, g_iPlayerModelsRed[client][0], g_iPlayerModelsRed[client][1], g_iPlayerModelsRed[client][2], 255);
						case CS_TEAM_CT:
							SetEntityRenderColor(client, g_iPlayerModelsBlue[client][0], g_iPlayerModelsBlue[client][1], g_iPlayerModelsBlue[client][2], 255);
					}			
					SetEntityRenderMode(client, RenderMode:1);
				}

				if(g_bEnableWeapons && g_bColorData[client][INDEX_WEAPON])
				{
					new _iWeapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
					if(_iWeapon > 0 && IsValidEdict(_iWeapon))
					{
						g_bColored[_iWeapon] = true;

						switch(g_iTeam[client])
						{
							case CS_TEAM_T:
								SetEntityRenderColor(_iWeapon, g_iPlayerWeaponsRed[client][0], g_iPlayerWeaponsRed[client][1], g_iPlayerWeaponsRed[client][2], 255);
							case CS_TEAM_CT:
								SetEntityRenderColor(_iWeapon, g_iPlayerWeaponsBlue[client][0], g_iPlayerWeaponsBlue[client][1], g_iPlayerWeaponsBlue[client][2], 255);
						}
						SetEntityRenderMode(_iWeapon, RenderMode:1);
					}
				}
			}
		}
	}
}

public Action:Event_OnPlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		new userid = GetEventInt(event, "userid");
		new client = GetClientOfUserId(userid);
		if(!client || !IsClientInGame(client))
			return Plugin_Continue;

		g_iTeam[client] = GetEventInt(event, "team");
		if(g_iTeam[client] <= 1)
			g_bAlive[client] = false;
		else if(g_bEnableModels && g_bAlive[client] && g_bAccess[client] && g_bColorData[client][INDEX_MODEL])
			CreateTimer(0.1, Timer_ColorModel, userid, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	return Plugin_Continue;
}

public Action:Event_OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		new userid = GetEventInt(event, "userid");
		new client = GetClientOfUserId(userid);
		if(!client || !IsClientInGame(client) || g_iTeam[client] <= CS_TEAM_SPECTATOR)
			return Plugin_Continue;
		
		g_bAlive[client] = true;
		if(g_bEnableModels && g_bAccess[client] && g_bColorData[client][INDEX_MODEL])
			CreateTimer(0.1, Timer_ColorModel, userid, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	return Plugin_Continue;
}

public Action:Event_OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(!client || !IsClientInGame(client))
			return Plugin_Continue;
		
		g_bAlive[client] = false;
	}
	
	return Plugin_Continue;
}

public Action:Command_Say(client, const String:command[], argc)
{
	if(g_bEnabled)
	{
		if(!client || !IsClientInGame(client) || !g_bAccess[client])
			return Plugin_Continue;

		decl String:_sText[192];
		GetCmdArgString(_sText, 192);
		StripQuotes(_sText);

		for(new i = 0; i < g_iNumCommands; i++)
		{
			if(StrEqual(_sText, g_sChatCommands[i], false))
			{
				Menu_Colors(client);
				return Plugin_Stop;
			}
		}
	}

	return Plugin_Continue;
}

public Action:Hook_OnWeaponSwitch(client, weapon)
{
	if(g_bEnabled && g_bEnableWeapons && weapon > 0 && IsValidEntity(weapon))
	{
		if(g_bAccess[client] && g_bColorData[client][INDEX_WEAPON])
		{
			switch(g_iTeam[client])
			{
				case CS_TEAM_T:
					SetEntityRenderColor(weapon, g_iPlayerWeaponsRed[client][0], g_iPlayerWeaponsRed[client][1], g_iPlayerWeaponsRed[client][2], 255);
				case CS_TEAM_CT:
					SetEntityRenderColor(weapon, g_iPlayerWeaponsBlue[client][0], g_iPlayerWeaponsBlue[client][1], g_iPlayerWeaponsBlue[client][2], 255);
			}			
			SetEntityRenderMode(weapon, RenderMode:1);
			g_bColored[weapon] = true;
		}
	}

	return Plugin_Continue;
}

public Action:Hook_OnWeaponDrop(client, weapon)
{
	if(g_bEnabled && g_bEnableWeapons && weapon > 0 && IsValidEntity(weapon))
	{
		if(g_bAccess[client] && g_bColored[weapon])
		{
			SetEntityRenderColor(weapon, 255, 255, 255, 255);
			g_bColored[weapon] = false;
		}
	}

	return Plugin_Continue;
}

public Action:Timer_ColorModel(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if(client && IsClientInGame(client) && g_bAlive[client])
	{
		switch(g_iTeam[client])
		{
			case CS_TEAM_T:
				SetEntityRenderColor(client, g_iPlayerModelsRed[client][0], g_iPlayerModelsRed[client][1], g_iPlayerModelsRed[client][2], 255);
			case CS_TEAM_CT:
				SetEntityRenderColor(client, g_iPlayerModelsBlue[client][0], g_iPlayerModelsBlue[client][1], g_iPlayerModelsBlue[client][2], 255);
		}			
		SetEntityRenderMode(client, RenderMode:1);

		if(g_fApplyDelay)
			CreateTimer(g_fApplyDelay, Timer_ReColorModel, userid, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:Timer_ReColorModel(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if(client && IsClientInGame(client) && g_bAlive[client])
	{
		switch(g_iTeam[client])
		{
			case CS_TEAM_T:
				SetEntityRenderColor(client, g_iPlayerModelsRed[client][0], g_iPlayerModelsRed[client][1], g_iPlayerModelsRed[client][2], 255);
			case CS_TEAM_CT:
				SetEntityRenderColor(client, g_iPlayerModelsBlue[client][0], g_iPlayerModelsBlue[client][1], g_iPlayerModelsBlue[client][2], 255);
		}			
		SetEntityRenderMode(client, RenderMode:1);
	}
}

SplitColorString(const String:colors[])
{
	decl _iColors[3], String:_sBuffer[3][4];
	ExplodeString(colors, " ", _sBuffer, 3, 4);
	for(new i = 0; i <= 2; i++)
		_iColors[i] = StringToInt(_sBuffer[i]);
	
	return _iColors;
}

Void_SetDefaults()
{
	g_bEnabled = GetConVarInt(g_hEnabled) ? true : false;
	g_bEnableModels = GetConVarInt(g_hEnableModels) ? true : false;
	g_bEnableWeapons = GetConVarInt(g_hEnableWeapons) ? true : false;
	g_fApplyDelay = GetConVarFloat(g_hApplyDelay);

	decl String:_sTemp[192];
	GetConVarString(g_hChatCommands, _sTemp, sizeof(_sTemp));
	g_iNumCommands = ExplodeString(_sTemp, ", ", g_sChatCommands, 16, 32);
	GetConVarString(g_hFlag, _sTemp, sizeof(_sTemp));
	g_iAccessFlag = ReadFlagString(_sTemp);
	
	GetConVarString(g_hRedModels, g_sRedModels, sizeof(g_sRedModels));
	g_iRedModels = SplitColorString(g_sRedModels);
	GetConVarString(g_hBlueModels, g_sBlueModels, sizeof(g_sBlueModels));
	g_iBlueModels = SplitColorString(g_sBlueModels);
	GetConVarString(g_hRedWeapons, g_sRedWeapons, sizeof(g_sRedWeapons));
	g_iRedWeapons = SplitColorString(g_sRedWeapons);
	GetConVarString(g_hBlueWeapons, g_sBlueWeapons, sizeof(g_sBlueWeapons));
	g_iBlueWeapons = SplitColorString(g_sBlueWeapons);
}

public OnSettingsChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	if(cvar == g_hEnabled)
		g_bEnabled = StringToInt(newvalue) ? true : false;
	else if(cvar == g_hFlag)
		g_iAccessFlag = ReadFlagString(newvalue);
	else if(cvar == g_hChatCommands)
		g_iNumCommands = ExplodeString(newvalue, ", ", g_sChatCommands, 16, 32);
	else if(cvar == g_hEnableModels)
		g_bEnableModels = StringToInt(newvalue) ? true : false;
	else if(cvar == g_hEnableWeapons)
		g_bEnableWeapons = StringToInt(newvalue) ? true : false;
	else if(cvar == g_hApplyDelay)
		g_fApplyDelay = StringToFloat(newvalue);
	else if(cvar == g_hRedModels)
	{
		Format(g_sRedModels, sizeof(g_sRedModels), "%s", newvalue);
		g_iRedModels = SplitColorString(g_sRedModels);
	}
	else if(cvar == g_hBlueModels)
	{
		Format(g_sBlueModels, sizeof(g_sBlueModels), "%s", newvalue);
		g_iBlueModels = SplitColorString(g_sBlueModels);
	}
	else if(cvar == g_hRedWeapons)
	{
		Format(g_sRedWeapons, sizeof(g_sRedWeapons), "%s", newvalue);
		g_iRedWeapons = SplitColorString(g_sRedWeapons);
	}
	else if(cvar == g_hBlueWeapons)
	{
		Format(g_sBlueWeapons, sizeof(g_sBlueWeapons), "%s", newvalue);
		g_iBlueWeapons = SplitColorString(g_sBlueWeapons);
	}
}

Void_LoadCookies(client)
{
	new String:_sCookie[12];
	GetClientCookie(client, g_cModelEnabled, _sCookie, sizeof(_sCookie));

	if(StrEqual(_sCookie, "", false))
	{
		g_bColorData[client][INDEX_MODEL] = g_bEnableModels;
		IntToString(g_bColorData[client][INDEX_MODEL], _sCookie, sizeof(_sCookie));
		SetClientCookie(client, g_cModelEnabled, _sCookie);

		g_bColorData[client][INDEX_WEAPON] = g_bEnableWeapons;
		IntToString(g_bColorData[client][INDEX_WEAPON], _sCookie, sizeof(_sCookie));
		SetClientCookie(client, g_cWeaponEnabled, _sCookie);

		g_iPlayerModelsRed[client] = g_iRedModels;
		SetClientCookie(client, g_cModelRedColor, g_sRedModels);
		g_iPlayerModelsBlue[client] = g_iBlueWeapons;
		SetClientCookie(client, g_cModelBlueColor, g_sBlueModels);
		g_iPlayerWeaponsRed[client] = g_iRedWeapons;
		SetClientCookie(client, g_cWeaponRedColor, g_sRedWeapons);
		g_iPlayerWeaponsBlue[client] = g_iBlueWeapons;
		SetClientCookie(client, g_cWeaponBlueColor, g_sBlueWeapons);
	}
	else
	{
		g_bColorData[client][INDEX_MODEL] = StringToInt(_sCookie) ? true : false;
		
		GetClientCookie(client, g_cWeaponEnabled, _sCookie, sizeof(_sCookie));
		g_bColorData[client][INDEX_WEAPON] = StringToInt(_sCookie) ? true : false;

		if(g_bEnableModels)
		{
			GetClientCookie(client, g_cModelRedColor, _sCookie, sizeof(_sCookie));
			g_iPlayerModelsRed[client] = SplitColorString(_sCookie);

			GetClientCookie(client, g_cModelBlueColor, _sCookie, sizeof(_sCookie));
			g_iPlayerModelsBlue[client] = SplitColorString(_sCookie);
		}

		if(g_bEnableWeapons)
		{
			GetClientCookie(client, g_cWeaponRedColor, _sCookie, sizeof(_sCookie));
			g_iPlayerWeaponsRed[client] = SplitColorString(_sCookie);

			GetClientCookie(client, g_cWeaponBlueColor, _sCookie, sizeof(_sCookie));
			g_iPlayerWeaponsBlue[client] = SplitColorString(_sCookie);
		}
	}

	g_bLoaded[client] = true;
}

public Menu_Cookies(client, CookieMenuAction:action, any:info, String:buffer[], maxlen) 
{
	switch(action)
	{
		case CookieMenuAction_DisplayOption:
			Format(buffer, maxlen, "%t", "Cookie_Title", client);
		case CookieMenuAction_SelectOption:
		{
			if(g_bEnabled)
				Menu_Colors(client);
		}
	}
}

Menu_Colors(client)
{
	decl String:_sBuffer[128];
	new _iTemp, Handle:_hMenu = CreateMenu(MenuHandler_MenuColors);
	Format(_sBuffer, sizeof(_sBuffer), "%T", "Menu_Title_Main", client);
	SetMenuTitle(_hMenu, _sBuffer);
	SetMenuPagination(_hMenu, MENU_NO_PAGINATION);
	SetMenuExitButton(_hMenu, true);

	_iTemp = (g_bEnableModels && g_bAccess[client]) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED;
	if(g_bColorData[client][INDEX_MODEL])
		Format(_sBuffer, sizeof(_sBuffer), "%T", "Menu_Model_Disable", client);
	else
		Format(_sBuffer, sizeof(_sBuffer), "%T", "Menu_Model_Enable", client);
	AddMenuItem(_hMenu, "0", _sBuffer, _iTemp);
	
	Format(_sBuffer, sizeof(_sBuffer), "%T", "Menu_Model_Modify", client);
	AddMenuItem(_hMenu, "1", _sBuffer, _iTemp);
	
	_iTemp = (g_bEnableWeapons && g_bAccess[client]) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED;
	if(g_bColorData[client][INDEX_WEAPON])
		Format(_sBuffer, sizeof(_sBuffer), "%T", "Menu_Weapon_Disable", client);
	else
		Format(_sBuffer, sizeof(_sBuffer), "%T", "Menu_Weapon_Enable", client);
	AddMenuItem(_hMenu, "2", _sBuffer, _iTemp);	
	
	Format(_sBuffer, sizeof(_sBuffer), "%T", "Menu_Weapon_Modify", client);
	AddMenuItem(_hMenu, "3", _sBuffer, _iTemp);
	
	DisplayMenu(_hMenu, client, MENU_TIME_FOREVER);
}

public MenuHandler_MenuColors(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
			CloseHandle(menu);
		case MenuAction_Select:
		{
			decl String:_sTemp[8];
			GetMenuItem(menu, param2, _sTemp, sizeof(_sTemp));

			switch(StringToInt(_sTemp))
			{
				case 0:
				{
					if(!g_bColorData[param1][INDEX_MODEL])
					{
						CPrintToChat(param1, "%s%t", g_sPrefixChat, "Phrase_Model_Enable");
						SetClientCookie(param1	, g_cModelEnabled, "1");
					}
					else
					{
						CPrintToChat(param1, "%s%t", g_sPrefixChat, "Phrase_Model_Disable");
						SetClientCookie(param1, g_cModelEnabled, "0");
					}
					
					g_bColorData[param1][INDEX_MODEL] = !g_bColorData[param1][INDEX_MODEL];
					Menu_Colors(param1);
				}
				case 1:
					Menu_ColorModels(param1);
				case 2:	
				{
					if(!g_bColorData[param1][INDEX_WEAPON])
					{
						g_bColorData[param1][INDEX_WEAPON] = true;
						CPrintToChat(param1, "%s%t", g_sPrefixChat, "Phrase_Weapon_Enable");
						SetClientCookie(param1	, g_cWeaponEnabled, "1");
					}
					else
					{
						g_bColorData[param1][INDEX_WEAPON] = false;
						CPrintToChat(param1, "%s%t", g_sPrefixChat, "Phrase_Weapon_Disable");
						SetClientCookie(param1, g_cWeaponEnabled, "0");
					}
					
					Menu_Colors(param1);
				}
				case 3:
					Menu_ColorWeapons(param1);
			}
		}
	}
	
	return;
}

Menu_ColorModels(client)
{
	decl String:_sBuffer[128];
	new Handle:_hMenu = CreateMenu(MenuHandler_MenuColorModels);
	Format(_sBuffer, sizeof(_sBuffer), "%T", "Menu_Models_Title", client);
	SetMenuTitle(_hMenu, _sBuffer);
	SetMenuPagination(_hMenu, MENU_NO_PAGINATION);
	SetMenuExitButton(_hMenu, true);
	SetMenuExitBackButton(_hMenu, true);

	Format(_sBuffer, sizeof(_sBuffer), "%T", "Option_Setting_T", client);
	AddMenuItem(_hMenu, "", _sBuffer, ITEMDRAW_DISABLED);
	
	Format(_sBuffer, sizeof(_sBuffer), "%T", "Option_Setting_Red", client, g_iPlayerModelsRed[client][0]);
	AddMenuItem(_hMenu, "0", _sBuffer);

	Format(_sBuffer, sizeof(_sBuffer), "%T", "Option_Setting_Green", client, g_iPlayerModelsRed[client][1]);
	AddMenuItem(_hMenu, "1", _sBuffer);
	
	Format(_sBuffer, sizeof(_sBuffer), "%T", "Option_Setting_Blue", client, g_iPlayerModelsRed[client][2]);
	AddMenuItem(_hMenu, "2", _sBuffer);
	
	Format(_sBuffer, sizeof(_sBuffer), "%T", "Option_Setting_CT", client);
	AddMenuItem(_hMenu, "", _sBuffer, ITEMDRAW_DISABLED);
	
	Format(_sBuffer, sizeof(_sBuffer), "%T", "Option_Setting_Red", client, g_iPlayerModelsBlue[client][0]);
	AddMenuItem(_hMenu, "3", _sBuffer);

	Format(_sBuffer, sizeof(_sBuffer), "%T", "Option_Setting_Green", client, g_iPlayerModelsBlue[client][1]);
	AddMenuItem(_hMenu, "4", _sBuffer);
	
	Format(_sBuffer, sizeof(_sBuffer), "%T", "Option_Setting_Blue", client, g_iPlayerModelsBlue[client][2]);
	AddMenuItem(_hMenu, "5", _sBuffer);

	DisplayMenu(_hMenu, client, MENU_TIME_FOREVER);
}

public MenuHandler_MenuColorModels(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
			CloseHandle(menu);
		case MenuAction_Cancel:
			Menu_Colors(param1);
		case MenuAction_Select:
		{
			decl String:_sTemp[8];
			GetMenuItem(menu, param2, _sTemp, sizeof(_sTemp));
			Menu_ColorDisplays(param1, INDEX_MODEL, StringToInt(_sTemp));
		}
	}

	return;
}

Menu_ColorWeapons(client)
{
	decl String:_sBuffer[128];
	new Handle:_hMenu = CreateMenu(MenuHandler_MenuColorWeapons);
	Format(_sBuffer, sizeof(_sBuffer), "%T", "Menu_Weapons_Title", client);
	SetMenuTitle(_hMenu, _sBuffer);
	SetMenuPagination(_hMenu, MENU_NO_PAGINATION);
	SetMenuExitButton(_hMenu, true);
	SetMenuExitBackButton(_hMenu, true);

	Format(_sBuffer, sizeof(_sBuffer), "%T", "Option_Setting_T", client);
	AddMenuItem(_hMenu, "", _sBuffer, ITEMDRAW_DISABLED);
	
	Format(_sBuffer, sizeof(_sBuffer), "%T", "Option_Setting_Red", client, g_iPlayerWeaponsRed[client][0]);
	AddMenuItem(_hMenu, "0", _sBuffer);

	Format(_sBuffer, sizeof(_sBuffer), "%T", "Option_Setting_Green", client, g_iPlayerWeaponsRed[client][1]);
	AddMenuItem(_hMenu, "1", _sBuffer);
	
	Format(_sBuffer, sizeof(_sBuffer), "%T", "Option_Setting_Blue", client, g_iPlayerWeaponsRed[client][2]);
	AddMenuItem(_hMenu, "2", _sBuffer);
	
	Format(_sBuffer, sizeof(_sBuffer), "%T", "Option_Setting_CT", client);
	AddMenuItem(_hMenu, "", _sBuffer, ITEMDRAW_DISABLED);
	
	Format(_sBuffer, sizeof(_sBuffer), "%T", "Option_Setting_Red", client, g_iPlayerWeaponsBlue[client][0]);
	AddMenuItem(_hMenu, "3", _sBuffer);

	Format(_sBuffer, sizeof(_sBuffer), "%T", "Option_Setting_Green", client, g_iPlayerWeaponsBlue[client][1]);
	AddMenuItem(_hMenu, "4", _sBuffer);
	
	Format(_sBuffer, sizeof(_sBuffer), "%T", "Option_Setting_Blue", client, g_iPlayerWeaponsBlue[client][2]);
	AddMenuItem(_hMenu, "5", _sBuffer);

	DisplayMenu(_hMenu, client, MENU_TIME_FOREVER);
}

public MenuHandler_MenuColorWeapons(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
			CloseHandle(menu);
		case MenuAction_Cancel:
			Menu_Colors(param1);
		case MenuAction_Select:
		{
			decl String:_sTemp[8];
			GetMenuItem(menu, param2, _sTemp, sizeof(_sTemp));

			Menu_ColorDisplays(param1, INDEX_WEAPON, StringToInt(_sTemp));
		}
	}

	return;
}

Menu_ColorDisplays(client, index, color)
{
	decl String:_sBuffer[128], String:_sTemp[16];
	new Handle:_hMenu = CreateMenu(MenuHandler_MenuColorDisplays);
	switch(color)
	{
		case 0:
			Format(_sBuffer, sizeof(_sBuffer), "%T", "Option_Current_Red", client, (index == INDEX_MODEL ? g_iPlayerModelsRed[client][COLOR_RED] : g_iPlayerWeaponsRed[client][COLOR_RED]));
		case 1:
			Format(_sBuffer, sizeof(_sBuffer), "%T", "Option_Current_Green", client, (index == INDEX_MODEL ? g_iPlayerModelsRed[client][COLOR_GREEN] : g_iPlayerWeaponsRed[client][COLOR_GREEN]));
		case 2:
			Format(_sBuffer, sizeof(_sBuffer), "%T", "Option_Current_Blue", client, (index == INDEX_MODEL ? g_iPlayerModelsRed[client][COLOR_BLUE] : g_iPlayerWeaponsRed[client][COLOR_BLUE]));
		case 3:
			Format(_sBuffer, sizeof(_sBuffer), "%T", "Option_Current_Red", client, (index == INDEX_MODEL ? g_iPlayerModelsBlue[client][COLOR_RED] : g_iPlayerWeaponsBlue[client][COLOR_RED]));
		case 4:
			Format(_sBuffer, sizeof(_sBuffer), "%T", "Option_Current_Green", client, (index == INDEX_MODEL ? g_iPlayerModelsBlue[client][COLOR_GREEN] : g_iPlayerWeaponsBlue[client][COLOR_GREEN]));
		case 5:
			Format(_sBuffer, sizeof(_sBuffer), "%T", "Option_Current_Blue", client, (index == INDEX_MODEL ? g_iPlayerModelsBlue[client][COLOR_BLUE] : g_iPlayerWeaponsBlue[client][COLOR_BLUE]));
	}

	SetMenuTitle(_hMenu, _sBuffer);
	SetMenuExitButton(_hMenu, true);
	SetMenuExitBackButton(_hMenu, true);

	for(new i = 250; i >= 0; i -= 10)
	{
		Format(_sBuffer, sizeof(_sBuffer), "%d", i);
		Format(_sTemp, sizeof(_sTemp), "%d %d %d", i, index, color);
		AddMenuItem(_hMenu, _sTemp, _sBuffer);
	}

	DisplayMenu(_hMenu, client, MENU_TIME_FOREVER);
}

public MenuHandler_MenuColorDisplays(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
			CloseHandle(menu);
		case MenuAction_Cancel:
			Menu_Colors(param1);
		case MenuAction_Select:
		{
			decl String:_sTemp[32], String:_sBuffer[3][8];
			GetMenuItem(menu, param2, _sTemp, sizeof(_sTemp));

			ExplodeString(_sTemp, " ", _sBuffer, 3, 8);
			new _iTemp = StringToInt(_sBuffer[0]);
			new _iColor = StringToInt(_sBuffer[2]);

			if(StringToInt(_sBuffer[1]) == INDEX_MODEL)
			{
				if(_iColor <= 2)
				{
					g_iPlayerModelsRed[param1][_iColor] = _iTemp;
					Format(_sTemp, sizeof(_sTemp), "%d %d %d", g_iPlayerModelsRed[param1][COLOR_RED], g_iPlayerModelsRed[param1][COLOR_GREEN], g_iPlayerModelsRed[param1][COLOR_BLUE]);
					SetClientCookie(param1, g_cModelRedColor, _sTemp);

					if(g_bColorData[param1][INDEX_MODEL])
					{
						SetEntityRenderColor(param1, g_iPlayerModelsRed[param1][0], g_iPlayerModelsRed[param1][1], g_iPlayerModelsRed[param1][2], 255);
						SetEntityRenderMode(param1, RenderMode:1);
					}
				}
				else
				{
					_iColor -= 3;
					g_iPlayerModelsBlue[param1][_iColor] = _iTemp;
					Format(_sTemp, sizeof(_sTemp), "%d %d %d", g_iPlayerModelsBlue[param1][COLOR_RED], g_iPlayerModelsBlue[param1][COLOR_GREEN], g_iPlayerModelsBlue[param1][COLOR_BLUE]);
					SetClientCookie(param1, g_cModelBlueColor, _sTemp);

					if(g_bColorData[param1][INDEX_MODEL])
					{
						SetEntityRenderColor(param1, g_iPlayerModelsBlue[param1][0], g_iPlayerModelsBlue[param1][1], g_iPlayerModelsBlue[param1][2], 255);
						SetEntityRenderMode(param1, RenderMode:1);
					}
				}
				
				Menu_ColorModels(param1);
			}
			else
			{
				if(_iColor <= 2)
				{
					g_iPlayerWeaponsRed[param1][_iColor] = _iTemp;
					Format(_sTemp, sizeof(_sTemp), "%d %d %d", g_iPlayerWeaponsRed[param1][COLOR_RED], g_iPlayerWeaponsRed[param1][COLOR_GREEN], g_iPlayerWeaponsRed[param1][COLOR_BLUE]);
					SetClientCookie(param1, g_cWeaponRedColor, _sTemp);

					new _iWeapon = GetEntPropEnt(param1, Prop_Data, "m_hActiveWeapon");
					if(g_bColorData[param1][INDEX_WEAPON] && IsValidEdict(_iWeapon))
					{
						SetEntityRenderColor(_iWeapon, g_iPlayerWeaponsRed[param1][0], g_iPlayerWeaponsRed[param1][1], g_iPlayerWeaponsRed[param1][2], 255);
						SetEntityRenderMode(_iWeapon, RenderMode:1);
						g_bColored[_iWeapon] = true;
					}
				}
				else
				{
					_iColor -= 3;
					g_iPlayerWeaponsBlue[param1][_iColor] = _iTemp;
					Format(_sTemp, sizeof(_sTemp), "%d %d %d", g_iPlayerWeaponsBlue[param1][COLOR_RED], g_iPlayerWeaponsBlue[param1][COLOR_GREEN], g_iPlayerWeaponsBlue[param1][COLOR_BLUE]);
					SetClientCookie(param1, g_cWeaponBlueColor, _sTemp);

					new _iWeapon = GetEntPropEnt(param1, Prop_Data, "m_hActiveWeapon");
					if(g_bColorData[param1][INDEX_WEAPON] && _iWeapon > 0 && IsValidEdict(_iWeapon))
					{
						SetEntityRenderColor(_iWeapon, g_iPlayerWeaponsBlue[param1][0], g_iPlayerWeaponsBlue[param1][1], g_iPlayerWeaponsBlue[param1][2], 255);
						SetEntityRenderMode(_iWeapon, RenderMode:1);
						g_bColored[_iWeapon] = true;
					}
				}
				
				Menu_ColorWeapons(param1);
			}
		}
	}

	return;
}