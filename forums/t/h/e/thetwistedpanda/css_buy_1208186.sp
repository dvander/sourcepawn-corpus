/*
	Revisions 2.0.3
	- Fixed an issue where players could buy weapons/equipment belonging to the other team outside of the buyzone / after the buytime.
	- Changing css_buy_buytime now correctly updates the in-game buytime counter.
	- The in-game buytime counter now sets itself correctly if there is a late load.
	- Cleaned up logic for the buy hook so that the plugin always reverts to the internal buy command whenever possible.
	- Added optional flag support for restricting purchases of weapons belonging to opposing team to only those individuals with the specified flag.
*/

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <colors>

#define PLUGIN_VERSION "2.0.3"

//The slot of a client's knife, since it is missing in cstrike.inc
#define CS_SLOT_KNIFE 2
//The ammo indexes for GetGrenadeCount
#define CS_HE_GRENADE 11
#define CS_FB_GRENADE 12
#define CS_SM_GRENADE 13
//The maximum amount of chat commands allowed
#define MAX_CHAT_COMMANDS 16
//The maximum length of each chat command
#define MAX_COMMAND_LENGTH 16
//The maximum number of weapons to consider
#define MAX_EQUIP_SIZE 40
//The maximum number of menu options to consider
#define MAX_MENU_OPTIONS 24

new g_iTeam[MAXPLAYERS + 1];
new g_iOriginal[MAXPLAYERS + 1];
new bool:g_bAlive[MAXPLAYERS + 1];

new Handle:g_hEnabled = INVALID_HANDLE;
new Handle:g_hBuyZone = INVALID_HANDLE;
new Handle:g_hBuyTime = INVALID_HANDLE;
new Handle:g_hBuyMenu = INVALID_HANDLE;
new Handle:g_hWelcome = INVALID_HANDLE;
new Handle:g_hBuyCommand = INVALID_HANDLE;
new Handle:g_hMessageMode = INVALID_HANDLE;
new Handle:g_hRestrictConvar = INVALID_HANDLE;
new Handle:g_hCvarBuyTime = INVALID_HANDLE;
new Handle:g_hCvarAmmoFlashes = INVALID_HANDLE;
new Handle:g_hCvarAmmoSmokes = INVALID_HANDLE;
new Handle:g_hCvarAmmoGrenades = INVALID_HANDLE;
new Handle:g_hTrie_Equipment = INVALID_HANDLE;

new g_iEquipSlot[MAX_EQUIP_SIZE];
new g_iEquipTeam[MAX_EQUIP_SIZE];
new g_iEquipCost[MAX_EQUIP_SIZE];
new CSWeaponID:g_iEquipIndex[MAX_EQUIP_SIZE];
new g_iEquipOriginal[MAX_EQUIP_SIZE];
new g_iEquipFlag[MAX_EQUIP_SIZE];
new String:g_sEquipName[MAX_EQUIP_SIZE][32];
new String:g_sEquipMenu[MAX_EQUIP_SIZE][32];
new String:g_sMenuOptions[MAX_MENU_OPTIONS][32];

new bool:g_bRestrictedWeapon[2][MAX_EQUIP_SIZE];
new Handle:g_hRestrictedWeapon[2][MAX_EQUIP_SIZE] = { { INVALID_HANDLE, ... }, { INVALID_HANDLE, ... } };

new bool:g_bEnabled, bool:g_bBuyZone, bool:g_bBuyTime, bool:g_bBuyMenu, bool:g_bRestrictLoaded, bool:g_bLateLoad, bool:g_bRestrictEnabled;
new Float:g_fWelcome;
new g_iNumMenuOptions, g_iNumEquips, g_iBuyLeft = -1, g_iMessageMode, g_iNumCommands, g_iCvarBuyTime, g_iCvarAmmoFlashes, g_iCvarAmmoSmokes, g_iCvarAmmoGrenades, g_iOriginalTime;
new String:g_sBuyCommands[MAX_CHAT_COMMANDS][MAX_COMMAND_LENGTH], String:g_sPrefixChat[32], String:g_sPrefixConsole[32], String:g_sPrefixHint[32], String:g_sPrefixCenter[32], String:g_sPrefixKey[32];

public Plugin:myinfo =
{
	name = "CSS Buy Command",
	author = "Twisted|Panda",
	description = "Provides an advance purchasing method capable of overriding game defaults.",
	version = PLUGIN_VERSION,
	url = "http://ominousgaming.com"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	g_bLateLoad = late;
	return APLRes_Success;
}

public OnPluginStart()
{	
	LoadTranslations("common.phrases");
	LoadTranslations("css_buy.phrases");

	CreateConVar("sm_buying_version", PLUGIN_VERSION, "CSS Buy Command: Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hEnabled = CreateConVar("css_buy_enabled", "1", "Enable/disables all features of the plugin. (0 = Disabled, 1 = Enabled)", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hEnabled, OnSettingsChange);
	g_hBuyZone = CreateConVar("css_buy_buyzone", "1", "If enabled, clients must be within a buyzone to purchase equipment, otherwise clients can purchase from anywhere. (0 = Disabled, 1 = Enabled)", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hBuyZone, OnSettingsChange);
	g_hBuyTime = CreateConVar("css_buy_buytime", "1", "If enabled, clients cannot access any purchase feature after mp_buytime expires, otherwise clients can purchase at any time. (0 = Disabled, 1 = Enabled)", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hBuyTime, OnSettingsChange);
	g_hBuyMenu = CreateConVar("css_buy_buymenu", "1", "If enabled, a buy menu becomes available by using a chat trigger with no parameters for purchasing weapons in addition to the purchase commands. (0 = Disabled, 1 = Enabled)", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hBuyMenu, OnSettingsChange);
	g_hWelcome = CreateConVar("css_buy_welcome", "5.0", "The number of seconds after a player joins their first team to send the welcoming advert. (-1.0 = Disabled, 0.0 = Instant, #.# = Delay)", FCVAR_NONE, true, -1.0);
	HookConVarChange(g_hWelcome, OnSettingsChange);
	g_hBuyCommand = CreateConVar("css_buy_commands", "!buy, /buy, !guns, /guns", "The chat triggers available to clients to purchase equipment. If css_buy_buymenu is enabled, the buy menu will open if no item is provided to purchase.", FCVAR_NONE);
	HookConVarChange(g_hBuyCommand, OnSettingsChange);
	g_hMessageMode = CreateConVar("css_buy_messages", "0", "Determines printing functionality (-1 = Disabled, 0 = Chat, 1 = Hint, 2 = Center, 3 = Key Hint)", FCVAR_NONE, true, -1.0, true, 3.0);
	HookConVarChange(g_hMessageMode, OnSettingsChange);
	AutoExecConfig(true, "css_buy");

	g_hCvarBuyTime = FindConVar("mp_buytime");
	HookConVarChange(g_hCvarBuyTime, OnSettingsChange);
	g_hCvarAmmoFlashes = FindConVar("ammo_flashbang_max");
	HookConVarChange(g_hCvarAmmoFlashes, OnSettingsChange);
	g_hCvarAmmoSmokes = FindConVar("ammo_smokegrenade_max");
	HookConVarChange(g_hCvarAmmoSmokes, OnSettingsChange);
	g_hCvarAmmoGrenades = FindConVar("ammo_hegrenade_max");
	HookConVarChange(g_hCvarAmmoGrenades, OnSettingsChange);

	AddCommandListener(Command_Say, "say");
	AddCommandListener(Command_Say, "say_team");

	HookEvent("player_team", Event_OnPlayerTeam);
	HookEvent("player_spawn", Event_OnPlayerSpawn);
	HookEvent("player_death", Event_OnPlayerDeath);
	HookEvent("round_start", Event_OnRoundStart);
	HookEvent("round_freeze_end", Event_OnFreezeEnd);
	
	Void_SetDefaults();
	Void_DefineEquips();
}

public OnAllPluginsLoaded()
{
	g_hRestrictConvar = FindConVar("sm_weaponrestrict_version");
	g_bRestrictEnabled = (g_hRestrictConvar != INVALID_HANDLE) ? true : false;
	if(g_bRestrictEnabled && !g_bRestrictLoaded)
	{
		decl String:_sBuffer[40];
		new String:_sRed[] =  "sm_restrict_*_t";
		new String:_sBlue[] =  "sm_restrict_*_ct";

		g_bRestrictLoaded = true;
		for(new i = 0; i < g_iNumEquips; i++)
		{
			strcopy(_sBuffer, 40, _sRed);
			ReplaceString(_sBuffer, 40, "*", g_sEquipName[i]);
			g_hRestrictedWeapon[0][i] = FindConVar(_sBuffer);
			if(g_hRestrictedWeapon[0][i] != INVALID_HANDLE)
			{
				HookConVarChange(g_hRestrictedWeapon[0][i], OnRestrictChange);
				g_bRestrictedWeapon[0][i] = GetConVarInt(g_hRestrictedWeapon[0][i]) == -1 ? false : true;
			}
		
			strcopy(_sBuffer, 40, _sBlue);
			ReplaceString(_sBuffer, 40, "*", g_sEquipName[i]);
			g_hRestrictedWeapon[1][i] = FindConVar(_sBuffer);
			if(g_hRestrictedWeapon[1][i] != INVALID_HANDLE)
			{
				HookConVarChange(g_hRestrictedWeapon[1][i], OnRestrictChange);
				g_bRestrictedWeapon[1][i] = GetConVarInt(g_hRestrictedWeapon[1][i]) == -1 ? false : true;
			}
		}
	}
}

public OnConfigsExecuted()
{
	if(g_bEnabled)
	{
		Format(g_sPrefixChat, sizeof(g_sPrefixChat), "%T", "Prefix_Chat", LANG_SERVER);
		Format(g_sPrefixHint, sizeof(g_sPrefixHint), "%T", "Prefix_Hint", LANG_SERVER);
		Format(g_sPrefixCenter, sizeof(g_sPrefixCenter), "%T", "Prefix_Center", LANG_SERVER);
		Format(g_sPrefixKey, sizeof(g_sPrefixKey), "%T", "Prefix_Key", LANG_SERVER);
		Format(g_sPrefixConsole, sizeof(g_sPrefixConsole), "%T", "Prefix_Console", LANG_SERVER);

		if(g_bLateLoad)
		{
			for(new i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i))
				{
					g_iTeam[i] = GetClientTeam(i);
					g_bAlive[i] = IsPlayerAlive(i) ? true : false;
					
					SDKHook(i, SDKHook_PostThinkPost, Hook_PostThinkPost);
				}	
			}

			g_iBuyLeft = GetTime() + (g_iCvarBuyTime * 60);
			g_bLateLoad = false;
		}
	}
}

public OnClientPutInServer(client)
{
	if(g_bEnabled)
	{
		if(IsClientInGame(client))
		{
			SDKHook(client, SDKHook_PostThinkPost, Hook_PostThinkPost);
		}
	}
}


public Hook_PostThinkPost(entity)
{
	if(g_bEnabled)
	{
		if(!g_bBuyZone)
			SetEntProp(entity, Prop_Send, "m_bInBuyZone", 1);
	}
}

public Action:CS_OnBuyCommand(client, const String:weapon[])
{
	if(g_bEnabled)
	{
		if(client && g_bAlive[client] && g_iTeam[client] >= CS_TEAM_T)
		{
			decl String:_sBuffer[16];
			strcopy(_sBuffer, sizeof(_sBuffer), weapon);
			new _iIndex = strlen(_sBuffer);
			for(new i = 0; i < _iIndex; i++)
				if(IsCharAlpha(_sBuffer[i]) && IsCharUpper(_sBuffer[i]))
					_sBuffer[i] = CharToLower(_sBuffer[i]);

			if(GetTrieValue(g_hTrie_Equipment, _sBuffer, _iIndex))
			{
				if(g_bRestrictedWeapon[GetTeamIndex(g_iTeam[client])][_iIndex])
					return Plugin_Continue;		
				
				decl String:_sDisplay[32];
				Format(_sDisplay, sizeof(_sDisplay), "%T", _sBuffer, client);
				if(!g_iEquipTeam[_iIndex] || g_iTeam[client] == g_iEquipTeam[_iIndex])
				{
					new _iCost = (g_iEquipCost[_iIndex] == -1) ? CS_GetWeaponPrice(client, g_iEquipIndex[_iIndex]) : g_iEquipCost[_iIndex];
					new _iCash = GetEntProp(client, Prop_Send, "m_iAccount");
					if(_iCash < _iCost)
					{
						PrintToClient(client, "%T", "Insufficient_Funds", client, _sDisplay);
						return Plugin_Handled;
					}

					new bool:_bPurchase;				
					decl String:_sLong[32];
					Format(_sLong, sizeof(_sLong), "%s%s", ((_iIndex < 0) ? "item_" : "weapon_"), _sBuffer);

					new bool:_bOrig = (g_iEquipOriginal[_iIndex] && g_iTeam[client] != g_iEquipOriginal[_iIndex]) ? true : false;
					if((!_bOrig && (!g_bBuyTime && GetTime() >= g_iBuyLeft)) || (_bOrig && ((!g_bBuyZone || GetEntProp(client, Prop_Send, "m_bInBuyZone")) && (!g_bBuyTime || GetTime() < g_iBuyLeft))))
					{
						if(_bOrig && g_iEquipFlag[_iIndex] && !(GetUserFlagBits(client) & g_iEquipFlag[_iIndex]))
						{
							PrintToClient(client, "%T", "Insufficient_Admin_Flags", client, _sDisplay);
							return Plugin_Handled;
						}

						switch(g_iEquipSlot[_iIndex])
						{
							case -1:
							{
								if(GetEntProp(client, Prop_Send, "m_ArmorValue") < 100)
								{
									_bPurchase = true;
									SetEntProp(client, Prop_Send, "m_ArmorValue", 100, 1);
								}
							}
							case -2:
							{
								if(!GetEntProp(client, Prop_Send, "m_bHasHelmet") || GetEntProp(client, Prop_Send, "m_ArmorValue") < 100)
								{
									_bPurchase = true;
									SetEntProp(client, Prop_Send, "m_ArmorValue", 100, 1);
									SetEntProp(client, Prop_Send, "m_bHasHelmet", 1, 1);
								}
							}
							case -3:
							{
								if((!g_iEquipOriginal[_iIndex] || g_iTeam[client] == g_iEquipOriginal[_iIndex]) && !GetEntProp(client, Prop_Send, "m_bHasDefuser"))
								{
									_bPurchase = true;
									SetEntProp(client, Prop_Send, "m_bHasDefuser", 1, 1);
								}
							}
							case -4:
							{
								if(!GetEntProp(client, Prop_Send, "m_bHasNightVision"))
								{
									_bPurchase = true;
									SetEntProp(client, Prop_Send, "m_bHasNightVision", 1, 1);
								}
							}
							case 0, 1:
							{
								new _iEnt = GetPlayerWeaponSlot(client, g_iEquipSlot[_iIndex]);
								if(_iEnt == -1)
								{
									_bPurchase = true;
									GivePlayerItem(client, _sLong);
								}
								else
								{
									decl String:_sClassname[32];
									GetEdictClassname(_iEnt, _sClassname, sizeof(_sClassname));
									if(StrEqual(_sClassname, _sLong, false))
										return Plugin_Continue;
									else
									{
										_bPurchase = true;
										CS_DropWeapon(client, _iEnt, true, true);

										new Handle:_hPack = INVALID_HANDLE;
										CreateDataTimer(0.1, Timer_PurchaseWeapon, _hPack);
										WritePackCell(_hPack, GetClientUserId(client));
										WritePackString(_hPack, _sLong);
									}
								}
							}
							case 2:
							{
								new _iEnt = GetPlayerWeaponSlot(client, g_iEquipSlot[_iIndex]);
								if(_iEnt == -1)
								{
									_bPurchase = true;
									GivePlayerItem(client, _sLong);
								}
							}
							case 3:
							{
								if(StrEqual(_sBuffer, "hegrenade"))
								{
									if(GetGrenadeCount(client, CS_HE_GRENADE) < g_iCvarAmmoGrenades)
									{
										_bPurchase = true;
										GivePlayerItem(client, _sLong);
									}
								}
								else if(StrEqual(_sBuffer, "flashbang"))
								{
									if(GetGrenadeCount(client, CS_FB_GRENADE) < g_iCvarAmmoFlashes)
									{
										_bPurchase = true;
										GivePlayerItem(client, _sLong);
									}							
								}
								else if(StrEqual(_sBuffer, "smokegrenade"))
								{
									if(GetGrenadeCount(client, CS_SM_GRENADE) < g_iCvarAmmoSmokes)
									{
										_bPurchase = true;
										GivePlayerItem(client, _sLong);
									}							
								}
							}
							case 4:
							{
								if((!g_iEquipOriginal[_iIndex] || g_iTeam[client] == g_iEquipOriginal[_iIndex]) && !GetEntProp(client, Prop_Send, "m_bHasDefuser"))
								{
									new _iEnt = GetPlayerWeaponSlot(client, g_iEquipSlot[_iIndex]);
									if(_iEnt == -1)
									{
										_bPurchase = true;
										GivePlayerItem(client, _sLong);
									}
								}
							}
						}

						if(_bPurchase)
						{
							_iCash -= _iCost;
							SetEntProp(client, Prop_Send, "m_iAccount", _iCash);
						}

						return Plugin_Handled;
					}
					else
						return Plugin_Continue;
				}
				else
				{
					decl String:_sTemp[32];
					if(g_iEquipTeam[_iIndex] == CS_TEAM_T)
						Format(_sTemp, sizeof(_sTemp), "%T", "Buy_Team_Red", client);
					else
						Format(_sTemp, sizeof(_sTemp), "%T", "Buy_Team_Blue", client);

					PrintToClient(client, "%T", "Equip_Restricted", client, _sDisplay, _sTemp);
					return Plugin_Handled;
				}
			}
		}
	}
	
	return Plugin_Continue;
}

public Action:Timer_PurchaseWeapon(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new userid = ReadPackCell(pack);
	new client = GetClientOfUserId(userid);
	if(client > 0 && IsClientInGame(client))
	{
		decl String:_sWeapon[32];
		ReadPackString(pack, _sWeapon, 32);
		GivePlayerItem(client, _sWeapon);
	}
}

public Action:Command_Say(client, const String:command[], argc)
{
	if(g_bEnabled)
	{
		if(!client || !IsClientInGame(client))
			return Plugin_Continue;

		decl String:_sString[192];
		if(!GetCmdArgString(_sString, sizeof(_sString)))
			return Plugin_Continue;
		StripQuotes(_sString);
		
		new String:_sBuffer[2][32];
		ExplodeString(_sString, " ", _sBuffer, 2, 32);
		for(new i = 0; i < g_iNumCommands; i++)
		{
			if(StrEqual(_sBuffer[0], g_sBuyCommands[i], false))
			{
				if(!strlen(_sBuffer[1]))
				{
					if(g_bBuyMenu && g_iNumMenuOptions && (g_bAlive[client] && g_iTeam[client] >= CS_TEAM_T))
					{
						if(!g_bBuyZone || GetEntProp(client, Prop_Send, "m_bInBuyZone"))
							if(!g_bBuyTime || GetTime() < g_iBuyLeft)
								Menu_Main(client);
							else
								PrintCenterText(client, "%t", "Purchase_After_Buytime", g_iCvarBuyTime);
						else
							PrintCenterText(client, "%t", "Purchase_Outside_Buyzone");
					}
					else
					{
						decl String:_sCommand[24];
						strcopy(_sCommand, 24, g_sBuyCommands[(GetRandomInt(0, (g_iNumCommands - 1)))]);
						PrintToClient(client, "%T", "Command_Display_Gear", client, _sCommand);
						
						new String:_sTemp[1024];
						Format(_sTemp, sizeof(_sTemp), "%s\n=-=-=-=-=-\n", g_sPrefixConsole);
						for(new j = 0; j < g_iNumEquips; j++)
							Format(_sTemp, sizeof(_sTemp), "%s%s\n", _sTemp, g_sEquipName[j]);
							
						PrintToConsole(client, _sTemp);
					}
				}
				else if(g_bAlive[client] && g_iTeam[client] >= CS_TEAM_T)
				{
					ReplaceString(_sBuffer[1], 32, "weapon_", "", false);
					ReplaceString(_sBuffer[1], 32, "item_", "", false);
					if(!g_bBuyZone || GetEntProp(client, Prop_Send, "m_bInBuyZone"))
						if(!g_bBuyTime || GetTime() < g_iBuyLeft)
							FakeClientCommandEx(client, "buy %s", _sBuffer[1]);
						else
							PrintCenterText(client, "%t", "Purchase_After_Buytime", g_iCvarBuyTime);
					else
						PrintCenterText(client, "%t", "Purchase_Outside_Buyzone");
				}

				return Plugin_Handled;
			}
		}
	}
	
	return Plugin_Continue;
}

public OnClientDisconnect(client)
{
	if(g_bEnabled)
	{
		if(IsClientInGame(client))
		{
			g_iTeam[client] = 0;
			g_bAlive[client] = false;
		}
	}
}

public Action:Event_OnPlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		new userid = GetEventInt(event, "userid");
		new client = GetClientOfUserId(userid);
		if(client <= 0 || !IsClientInGame(client))
			return Plugin_Continue;
			
		g_iTeam[client] = GetEventInt(event, "team");
		if(g_iTeam[client] == CS_TEAM_SPECTATOR)
			g_bAlive[client] = false;

		if(GetEventInt(event, "oldteam") == CS_TEAM_NONE && g_fWelcome >= 0.0)
			CreateTimer(g_fWelcome, Timer_Announce, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}

	return Plugin_Continue;
}

public Action:Event_OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(client <= 0 || !IsClientInGame(client) || g_iTeam[client] <= CS_TEAM_SPECTATOR)
			return Plugin_Continue;
			
		g_bAlive[client] = true;
	}
	
	return Plugin_Continue;
}

public Action:Event_OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(client <= 0 || !IsClientInGame(client))
			return Plugin_Continue;
			
		g_bAlive[client] = false;
	}
	
	return Plugin_Continue;
}

public Action:Event_OnRoundStart(Handle:p_hEvent, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		g_iBuyLeft = -1;
	}
	
	return Plugin_Continue;
}

public Action:Event_OnFreezeEnd(Handle:p_hEvent, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		if(g_bBuyTime)
			g_iBuyLeft = GetTime() + (g_iCvarBuyTime * 60);
	}
	
	return Plugin_Continue;
}

public Action:Timer_Announce(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if(client > 0 && IsClientInGame(client))
	{
		if(g_iNumCommands)
		{
			decl String:_sTemp[24];
			strcopy(_sTemp, 24, g_sBuyCommands[(GetRandomInt(0, (g_iNumCommands - 1)))]);
			CPrintToChat(client, "%s%t", g_sPrefixChat, "Welcome_Advert_Commands", _sTemp);
		}
		else
			CPrintToChat(client, "%s%t", g_sPrefixChat, "Welcome_Advert");
	}
}

Menu_Main(client, index = 0)
{
	decl String:_sBuffer[128];
	Format(_sBuffer, sizeof(_sBuffer), "%T", "Menu_Main_Title", client);
	
	new Handle:_hMenu = CreateMenu(MenuHandler_Main);
	SetMenuTitle(_hMenu, _sBuffer);
	SetMenuExitButton(_hMenu, true);
	SetMenuExitBackButton(_hMenu, false);
	
	for(new i = 0; i < g_iNumMenuOptions; i++)
	{
		Format(_sBuffer, sizeof(_sBuffer), "%d", i);
		AddMenuItem(_hMenu, _sBuffer, g_sMenuOptions[i]);
	}

	DisplayMenuAtItem(_hMenu, client, index, MENU_TIME_FOREVER);
}

public MenuHandler_Main(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_End:
			CloseHandle(menu);
		case MenuAction_Select:
		{
			decl String:_sOption[4];
			GetMenuItem(menu, param2, _sOption, 4);
			
			g_iOriginal[param1] = GetMenuSelectionPosition();
			Menu_Buy(param1, StringToInt(_sOption));
		}
	}
}

Menu_Buy(client, type)
{
	decl String:_sBuffer[128], String:_sTemp[32], String:_sSlot[8];
	Format(_sBuffer, sizeof(_sBuffer), "%T", "Menu_Buy_Title", client, g_sMenuOptions[type]);
	
	new Handle:_hMenu = CreateMenu(MenuHandler_Buy);
	SetMenuTitle(_hMenu, _sBuffer);
	SetMenuExitButton(_hMenu, true);
	SetMenuExitBackButton(_hMenu, false);
	
	strcopy(_sTemp, 32, g_sMenuOptions[type]);
	new _iState = ITEMDRAW_DEFAULT, _iCash = GetEntProp(client, Prop_Send, "m_iAccount");
	for(new i = 0; i < g_iNumEquips; i ++)
	{
		if(StrEqual(_sTemp, g_sEquipMenu[i]))
		{
			new _iTeam = GetTeamIndex(g_iTeam[client]);
			if(g_iEquipTeam[i] != 1 && !g_bRestrictedWeapon[_iTeam][i])
			{
				Format(_sSlot, sizeof(_sSlot), "%d %d", i, type);
				Format(_sBuffer, sizeof(_sBuffer), "%T", g_sEquipName[i], client);

				new _iCost = (g_iEquipCost[i] == -1) ? CS_GetWeaponPrice(client, g_iEquipIndex[i]) : g_iEquipCost[i];
				if(g_iEquipTeam[i] && g_iTeam[client] != g_iEquipTeam[i] || _iCash < _iCost)
					_iState = ITEMDRAW_DISABLED;

				Format(_sBuffer, sizeof(_sBuffer), "%s, $%d", _sBuffer, _iCost);
				AddMenuItem(_hMenu, _sSlot, _sBuffer, _iState);
			}
		}
	}

	DisplayMenu(_hMenu, client, MENU_TIME_FOREVER);
}

public MenuHandler_Buy(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_End:
			CloseHandle(menu);
		case MenuAction_Cancel:
		{
			if(param2 <= MenuCancel_Exit)
				Menu_Main(param1, g_iOriginal[param1]);
		}
		case MenuAction_Select:
		{
			decl String:_sOption[8], String:_sBuffer[2][4];
			GetMenuItem(menu, param2, _sOption, 8);
			ExplodeString(_sOption, " ", _sBuffer, 2, 4);

			if(!g_bBuyZone || GetEntProp(param1, Prop_Send, "m_bInBuyZone"))
				if(!g_bBuyTime || GetTime() < g_iBuyLeft)
				{
					FakeClientCommandEx(param1, "buy %s", g_sEquipName[StringToInt(_sBuffer[0])]);
					Menu_Buy(param1, StringToInt(_sBuffer[1]));
				}
				else
					PrintCenterText(param1, "%t", "Purchase_After_Buytime", g_iCvarBuyTime);
			else
				PrintCenterText(param1, "%t", "Purchase_Outside_Buyzone");
		}
	}
}

GetGrenadeCount(client, type)
{
	new offsAmmo = FindDataMapOffs(client, "m_iAmmo") + (type * 4);
	return GetEntData(client, offsAmmo);
}

GetTeamIndex(team)
{
	return (team == CS_TEAM_T) ? 0 : 1;
}

PrintToClient(client, const String:_sMessage[], any:...)
{
	if(g_iMessageMode != -1)
	{
		decl String:_sBuffer[192];
		VFormat(_sBuffer, sizeof(_sBuffer), _sMessage, 3);

		switch(g_iMessageMode)
		{
			case 0:
				CPrintToChat(client, "%s%s", g_sPrefixChat, _sBuffer);
			case 1:
				PrintHintText(client, "%s%s", g_sPrefixHint, _sBuffer);
			case 2:
				PrintCenterText(client, "%s%s", g_sPrefixCenter, _sBuffer);
			case 3:
			{
				Format(_sBuffer, sizeof(_sBuffer), "%s%s", g_sPrefixKey, _sBuffer);

				new Handle:_hMessage = StartMessageOne("KeyHintText", client);
				BfWriteByte(_hMessage, 1);
				BfWriteString(_hMessage, _sBuffer); 
				EndMessage();
			}
		}
	}
}

Void_DefineEquips()
{
	g_hTrie_Equipment = CreateTrie();

	g_iNumEquips = g_iNumMenuOptions = 0;
	decl String:_sPath[256];
	new Handle:_hKV = CreateKeyValues("CSSBuy_Weapons");
	BuildPath(Path_SM, _sPath, 256, "configs/css_buy.weapons.txt");
	if(FileToKeyValues(_hKV, _sPath))
	{
		KvGotoFirstSubKey(_hKV);
		do
		{
			KvGetSectionName(_hKV, g_sEquipName[g_iNumEquips], 32);
			SetTrieValue(g_hTrie_Equipment, g_sEquipName[g_iNumEquips], g_iNumEquips);
			g_iEquipCost[g_iNumEquips] = KvGetNum(_hKV, "cost");
			g_iEquipSlot[g_iNumEquips] = KvGetNum(_hKV, "slot");
			g_iEquipTeam[g_iNumEquips] = KvGetNum(_hKV, "team");
			g_iEquipIndex[g_iNumEquips] = CSWeaponID:KvGetNum(_hKV, "index");
			g_iEquipOriginal[g_iNumEquips] = KvGetNum(_hKV, "orig");
			KvGetString(_hKV, "flag", _sPath, sizeof(_sPath));
			g_iEquipFlag[g_iNumEquips] = strlen(_sPath) == 0 ? 0 : ReadFlagString(_sPath);
			
			new bool:_bFound = false;
			KvGetString(_hKV, "menu", g_sEquipMenu[g_iNumEquips], 32);
			if(strlen(g_sEquipMenu[g_iNumEquips]) > 0)
			{
				for(new i = 0; i < g_iNumMenuOptions; i++)
				{
					if(StrEqual(g_sEquipMenu[g_iNumEquips], g_sMenuOptions[i]))
					{
						_bFound = true;
						break;
					}
				}
				
				if(!_bFound)
				{
					strcopy(g_sMenuOptions[g_iNumMenuOptions], 32, g_sEquipMenu[g_iNumEquips]);
					g_iNumMenuOptions++;
				}
			}

			g_iNumEquips++;
		}
		while (KvGotoNextKey(_hKV));
		CloseHandle(_hKV);
	}
	else
	{
		CloseHandle(_hKV);
		SetFailState("CSSBuy: Could not locate \"configs/css_buy.weapons.txt\"");
	}
}

Void_SetDefaults()
{
	g_bEnabled = GetConVarInt(g_hEnabled) ? true : false;
	g_bBuyZone = GetConVarInt(g_hBuyZone) ? true : false;
	g_bBuyTime = GetConVarInt(g_hBuyTime) ? true : false;
	g_bBuyMenu = GetConVarInt(g_hBuyMenu) ? true : false;
	g_fWelcome = GetConVarFloat(g_hWelcome);
	g_iMessageMode = GetConVarInt(g_hMessageMode);

	decl String:_sTemp[192];
	GetConVarString(g_hBuyCommand, _sTemp, sizeof(_sTemp));
	g_iNumCommands = ExplodeString(_sTemp, ", ", g_sBuyCommands, MAX_CHAT_COMMANDS, MAX_COMMAND_LENGTH);
	
	g_iCvarBuyTime = g_iOriginalTime = GetConVarInt(g_hCvarBuyTime);
	g_iCvarAmmoFlashes = GetConVarInt(g_hCvarAmmoFlashes);
	g_iCvarAmmoSmokes = GetConVarInt(g_hCvarAmmoSmokes);
	g_iCvarAmmoGrenades = GetConVarInt(g_hCvarAmmoGrenades);

	if(g_bBuyTime)
		g_iBuyLeft = GetTime() + (g_iCvarBuyTime * 60);
}

public OnSettingsChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	if(cvar == g_hEnabled)
		g_bEnabled = StringToInt(newvalue) ? true : false;
	else if(cvar == g_hBuyZone)
		g_bBuyZone = StringToInt(newvalue) ? true : false;
	else if(cvar == g_hBuyTime)
	{
		g_bBuyTime = StringToInt(newvalue) ? true : false;
		if(!g_bBuyTime)
			SetConVarInt(g_hCvarBuyTime, 2629743);
		else if(GetConVarInt(g_hCvarBuyTime) != g_iOriginalTime)
			SetConVarInt(g_hCvarBuyTime, g_iOriginalTime);
			
		g_iBuyLeft = GetTime() + (g_iCvarBuyTime * 60);
	}
	else if(cvar == g_hBuyMenu)
		g_bBuyMenu = StringToInt(newvalue) ? true : false;
	else if(cvar == g_hWelcome)
		g_fWelcome = StringToFloat(newvalue);
	else if(cvar == g_hBuyCommand)
		g_iNumCommands = ExplodeString(newvalue, ", ", g_sBuyCommands, MAX_CHAT_COMMANDS, MAX_COMMAND_LENGTH);
	else if(cvar == g_hMessageMode)
		g_iMessageMode = StringToInt(newvalue);
	else if(cvar == g_hCvarBuyTime)
		g_iCvarBuyTime = StringToInt(newvalue);
	else if(cvar == g_hCvarAmmoFlashes)
		g_iCvarAmmoFlashes = StringToInt(newvalue);
	else if(cvar == g_hCvarAmmoSmokes)
		g_iCvarAmmoSmokes = StringToInt(newvalue);
	else if(cvar == g_hCvarAmmoGrenades)
		g_iCvarAmmoGrenades = StringToInt(newvalue);
}

public OnRestrictChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	for(new i = 0; i <= 1; i++)
	{
		for(new j = 0; j < g_iNumEquips; j++)
		{
			if(cvar == g_hRestrictedWeapon[i][j])
			{
				g_bRestrictedWeapon[i][j] = StringToInt(newvalue) == -1 ? false : true;
				return;
			}
		}
	}
}