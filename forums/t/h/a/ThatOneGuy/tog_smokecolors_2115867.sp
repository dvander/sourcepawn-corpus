#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <clientprefs>
#include <autoexecconfig>
#include <morecolors>

#define PLUGIN_VERSION "1.0"

//client data indexes for g_iSmokeData
#define INDEX_COLOR 0
#define INDEX_MODE 1
#define INDEX_TOTAL 2

//mode indexes
#define MODE_TEAM 0
#define MODE_RANDOM 1
#define MODE_MULTI 2
#define MODE_SELECTED 3

//cvar handles
new Handle:g_hMainEnabled = INVALID_HANDLE;
new Handle:g_hTColor = INVALID_HANDLE;
new Handle:g_hCTColor = INVALID_HANDLE;
new Handle:g_hDefaultEnable = INVALID_HANDLE;
new Handle:g_hDefaultColor = INVALID_HANDLE;
new Handle:g_hDefaultMode = INVALID_HANDLE;
new Handle:g_hAccessFlag = INVALID_HANDLE;
new Handle:g_hChatCommands = INVALID_HANDLE;

//cookies
new Handle:g_hCookieEnabled = INVALID_HANDLE;
new Handle:g_hCookieColor = INVALID_HANDLE;
new Handle:g_hCookieMode = INVALID_HANDLE;

//client info
new g_iSmokeData[MAXPLAYERS + 1][INDEX_TOTAL];
new g_iTeam[MAXPLAYERS + 1];
new bool:g_bLoaded[MAXPLAYERS + 1];
new bool:g_bValid[MAXPLAYERS + 1];
new bool:g_bFake[MAXPLAYERS + 1];
new g_iClientEnabled[MAXPLAYERS + 1];
new g_iColors[MAXPLAYERS + 1][4];

//color loading and listing variables
new g_iNumColors;
new String:g_sColorSchemes[128][32];
new String:g_sColorNames[128][64];
new g_iLoadColors;

//other stuff
new g_iDefaultEnable, g_iDefaultColor, g_iDefaultMode, g_iAccessFlag, g_iNumCommands;
new bool:g_bMainEnabled, bool:g_bLateLoad;
new String:g_sPrefixChat[32], String:g_sPrefixSelect[16], String:g_sPrefixEmpty[16], String:g_sChatCommands[16][32];
new Float:g_HSV_Temp = 0.0;

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	g_bLateLoad = late;
	return APLRes_Success;
}

public Plugin:myinfo = 
{
	name = "TOGs Smoke Colors",
	author = "That One Guy",
	description = "Adds color setups to grenade smoke via client prefs for donators",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net"
}

//////////////////////////////////////////////////////////////////
// Start plugin
//////////////////////////////////////////////////////////////////

public OnPluginStart()
{
	AutoExecConfig_SetFile("tog_smokecolors");
	AutoExecConfig_CreateConVar("tsm_version", PLUGIN_VERSION, "TOGs Smoke Color Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	LoadTranslations("common.phrases");
	LoadTranslations("tog_smokecolors.phrases");
	
	g_hMainEnabled = AutoExecConfig_CreateConVar("tsm_mainenable", "1", "Enable/Disable Plugin.", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hMainEnabled, OnCVarChange);
	
	g_hTColor = AutoExecConfig_CreateConVar("tsm_color_t",   "255 0 0", "The default terrorist team smoke color? Format: \"red green blue\" from 0 - 255.", FCVAR_PLUGIN);	
	HookConVarChange(g_hTColor, OnCVarChange);
	
	g_hCTColor = AutoExecConfig_CreateConVar("tsm_color_ct",  "0 0 255", "The default counter-terrorist team smoke color? Format: \"red green blue\" from 0 - 255.", FCVAR_PLUGIN);
	HookConVarChange(g_hCTColor, OnCVarChange);
	
	g_hDefaultEnable = CreateConVar("tsm_defaultstatus", "0", "The default smoke colors status that is set to new clients (0 = Disabled, 1 = Enabled).", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hDefaultEnable, OnCVarChange);
	
	g_hDefaultColor = CreateConVar("tsm_defaultcolor", "-1", "The default color index to be applied to new players. Format: \"red green blue\" from 0 - 255 (-1 = random).", FCVAR_NONE, true, -1.0);
	HookConVarChange(g_hDefaultColor, OnCVarChange);
	
	g_hDefaultMode = CreateConVar("tsm_defaultmode", "0", "The default mode applied to new players (0 = Team Colors, 1 = Random Colors, 2 = Multi-Colors, 3 = Selected Color).", FCVAR_NONE, true, 0.0, true, 3.0);
	HookConVarChange(g_hDefaultMode, OnCVarChange);
	
	g_hAccessFlag = CreateConVar("tsm_flag", "o", "If \"\", everyone can use smoke colors, otherwise, only players with this flag or the \"Smoke_Access\" override can access.", FCVAR_NONE);
	HookConVarChange(g_hAccessFlag, OnCVarChange);
	
	g_hChatCommands = CreateConVar("tsm_chatcommands", "!smoke, !smokes, !smokecolors, /SMOKE, /SMOKES, !SMOKECOLORS", "The chat triggers available to clients to open the smoke colors menu.", FCVAR_NONE);
	HookConVarChange(g_hChatCommands, OnCVarChange);
	
	// Hook events
	AddCommandListener(Command_Say, "say");
	AddCommandListener(Command_Say, "say_team");
	HookEvent("player_team", Event_OnPlayerTeam, EventHookMode_Pre);
	HookEvent("smokegrenade_detonate", smokegrenade_detonate);
	
	//client prefs and cookies	
	SetCookieMenuItem(Menu_ClientPrefs, 0, "Smoke Colors");
	g_hCookieEnabled = RegClientCookie("Smoke On/Off", "Enable smoke colors", CookieAccess_Protected);
	g_hCookieMode = RegClientCookie("Smoke Color Mode", "Smoke color mode", CookieAccess_Protected);
	g_hCookieColor = RegClientCookie("Smoke Color", "Smoke color if mode is set to Selected", CookieAccess_Protected);
	
	//setep color setups and defaults
	DefineColors();
	SetDefaults();

	//overwrite cookies if they are cached
	new iMaxClients = GetMaxClients();
	for(new k = 1; k <= iMaxClients; k++) 
	{			
		if(IsClientInGame(k) && AreClientCookiesCached(k))
		{
			LoadClientData(k);
		}
	}

	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
}

public OnMapStart()
{
	if(g_bMainEnabled)
	{
		DefineColors();
	}
}

public OnConfigsExecuted()
{
	if(g_bMainEnabled)
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
					g_bFake[i] = IsFakeClient(i) ? true : false;

					if(!g_iAccessFlag || CheckCommandAccess(i, "Smoke_Access", g_iAccessFlag))
					{
						g_bValid[i] = true;
						if(!g_bFake[i])
						{
							if(!g_bLoaded[i] && AreClientCookiesCached(i))
								LoadClientData(i);
						}
						else
						{
							g_bLoaded[i] = true;
							g_iClientEnabled[i] = g_iDefaultEnable;

							g_iSmokeData[i][INDEX_COLOR] = g_iDefaultColor == -1 ? GetRandomInt(0, g_iNumColors) : g_iDefaultColor;
							g_iSmokeData[i][INDEX_MODE] = g_iDefaultMode;
							
							decl String:sBuffer[3][8];	//array of 3 string - 1 for each RGB value
							ExplodeString(g_sColorSchemes[g_iSmokeData[i][INDEX_COLOR]], " ", sBuffer, 3, 8);
							for(new j = 0; j <= 2; j++)
								g_iColors[i][j] = StringToInt(sBuffer[j]);
						}
					}
					else
						g_iClientEnabled[i] = g_iDefaultEnable;
				}
			}
			
			g_bLateLoad = false;
		}
	}
}

public OnClientPutInServer(client)
{
	if(g_bMainEnabled)
	{
		g_bFake[client] = IsFakeClient(client) ? true : false;
	}
}

public OnClientPostAdminCheck(client)
{
	if(g_bMainEnabled && IsClientInGame(client))
	{
		if(!g_iAccessFlag || CheckCommandAccess(client, "Smoke_Access", g_iAccessFlag))
		{
			g_bValid[client] = true;
			if(!g_bFake[client])
			{
				if(!g_bLoaded[client] && AreClientCookiesCached(client))
					LoadClientData(client);
			}
			else
			{
				g_bLoaded[client] = true;
				g_iClientEnabled[client] = g_iDefaultEnable;

				g_iSmokeData[client][INDEX_COLOR] = g_iDefaultColor == -1 ? GetRandomInt(0, g_iNumColors) : g_iDefaultColor;
				g_iSmokeData[client][INDEX_MODE] = g_iDefaultMode;
				
				decl String:sBuffer[3][8];
				ExplodeString(g_sColorSchemes[g_iSmokeData[client][INDEX_COLOR]], " ", sBuffer, 3, 8);
				for(new i = 0; i <= 2; i++)
					g_iColors[client][i] = StringToInt(sBuffer[i]);
			}
		}
		else
			g_iClientEnabled[client] = g_iDefaultEnable;
	}
}

public bool:IsValidClient(client)
{
	if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) || IsFakeClient(client) )
	{
		return false;
	}
	return true;
}

public OnClientDisconnect(client)
{
	if(g_bMainEnabled)
	{
		g_iTeam[client] = 0;
		g_bLoaded[client] = false;
		g_bValid[client] = false;
		g_iClientEnabled[client] = false;
	}
}

public Action:Event_OnPlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bMainEnabled)
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
	if(g_bMainEnabled)
	{
		if(!client || !IsClientInGame(client) || !g_bValid[client])
			return Plugin_Continue;

		decl String:_sText[192];
		GetCmdArgString(_sText, sizeof(_sText));
		StripQuotes(_sText);

		for(new i = 0; i < g_iNumCommands; i++)
		{
			if(StrEqual(_sText, g_sChatCommands[i], false))
			{
				Menu_Smoke(client);
				return Plugin_Stop;
			}
		}
	}

	return Plugin_Continue;
}

SetDefaults()
{
	g_bMainEnabled = GetConVarInt(g_hMainEnabled) ? true : false;
	g_iDefaultEnable = GetConVarInt(g_hDefaultEnable);
	g_iDefaultColor = GetConVarInt(g_hDefaultColor);
	g_iDefaultMode = GetConVarInt(g_hDefaultMode);

	decl String:sTemp[192];
	GetConVarString(g_hChatCommands, sTemp, sizeof(sTemp));
	g_iNumCommands = ExplodeString(sTemp, ", ", g_sChatCommands, 16, 32);
	GetConVarString(g_hAccessFlag, sTemp, sizeof(sTemp));
	g_iAccessFlag = ReadFlagString(sTemp);
	
	if(g_iDefaultColor < 0 || g_iDefaultColor > g_iNumColors)
		g_iDefaultColor = GetRandomInt(0, g_iNumColors);
}

DefineColors()
{
	decl String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/smoke_colors.txt");
	
	new iCurrent = GetFileTime(sPath, FileTime_LastChange);
	if(iCurrent < g_iLoadColors)
		return;
	else
		g_iLoadColors = iCurrent;

	g_iNumColors = 0;
	new Handle:_hKV = CreateKeyValues("Smoke_Colors");
	if(FileToKeyValues(_hKV, sPath))
	{
		KvGotoFirstSubKey(_hKV);
		do
		{
			KvGetSectionName(_hKV, g_sColorNames[g_iNumColors], sizeof(g_sColorNames[]));
			KvGetString(_hKV, "Color", g_sColorSchemes[g_iNumColors], sizeof(g_sColorSchemes[]));
			g_iNumColors++;
		}
		while (KvGotoNextKey(_hKV));
	}
	else
		SetFailState("configs/smoke_colors.txt doesn't appear to exist or is invalid.");
	
	if(g_iNumColors)
		g_iNumColors--;
	
	CloseHandle(_hKV);
}

public OnCVarChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	if(cvar == g_hMainEnabled)
		g_bMainEnabled = bool:StringToInt(newvalue);
	else if(cvar == g_hAccessFlag)
		g_iAccessFlag = ReadFlagString(newvalue);
	else if(cvar == g_hDefaultEnable)
		g_iDefaultEnable = StringToInt(newvalue);
	else if(cvar == g_hChatCommands)
		g_iNumCommands = ExplodeString(newvalue, ", ", g_sChatCommands, 16, 32);
	else if(cvar == g_hDefaultColor)
	{
		g_iDefaultColor = StringToInt(newvalue);
		if(g_iDefaultColor < 0 || g_iDefaultColor > g_iNumColors)
			g_iDefaultColor = GetRandomInt(0, g_iNumColors);
	}
	else if(cvar == g_hDefaultMode)
		g_iDefaultMode = StringToInt(newvalue);
}

//////////////////////////////////////////////////////////////////
// Hook event grenade detonate and color the smoke
//////////////////////////////////////////////////////////////////

public smokegrenade_detonate(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Check if plugin is enabled
	if(GetConVarInt(g_hMainEnabled) != 1) return;
	
	// Get client ID of this event
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!IsValidClient(client)) return;
	if (!CheckCommandAccess(client, "Smoke_Access", g_iAccessFlag)) return;
	if (!g_iClientEnabled[client]) return;
	
	// Get coordinates of this event
	new Float:a[3], Float:b[3];
	a[0] = GetEventFloat(event, "x");
	a[1] = GetEventFloat(event, "y");
	a[2] = GetEventFloat(event, "z");
	
	new checkok = 0;
	new ent = -1;
	
	// List all entitys by classname
	while((ent = FindEntityByClassname(ent, "env_particlesmokegrenade")) != -1)
	{
		// Get entity coordinates
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", b);
		
		// If entity same coordinates some event coordinates
		if(a[0] == b[0] && a[1] == b[1] && a[2] == b[2])
		{		
			checkok = 1;
			break;
		}
	}
    
	if (checkok == 1)
	{
		// Create light
		new iEntity = CreateEntityByName("light_dynamic");
		
		if (iEntity != -1)
		{
			// Retrieve entity
			new iRef = EntIndexToEntRef(iEntity);
			
			
			decl String:sBuffer[64];
			// Select Action Mode
			switch (g_iSmokeData[client][INDEX_MODE])
			{
				// Team Color
				case 0:
				{
					// Get client team
					new player_team_index = GetClientTeam(client);
					
					new String: game_folder[64];
					GetGameFolderName(game_folder, 64);
					
					switch (player_team_index) 
					{	
						case 1:
						{
							IntToString(g_iSmokeData[client][INDEX_COLOR], sBuffer, sizeof(sBuffer));
						}
						case 2:
						{
							GetConVarString(g_hTColor, sBuffer, sizeof(sBuffer));
						}
						case 3:
						{
							GetConVarString(g_hCTColor, sBuffer, sizeof(sBuffer));
						}
					}
					
					DispatchKeyValue(iEntity, "_light", sBuffer);
				}
				// Random Color
				case 1:
				{
					g_HSV_Temp = GetRandomFloat(1.0, 360.0);
					
					new Float:flRed, Float:flGreen, Float:flBlue;
					HSVtoRGB(g_HSV_Temp, 1.0, 1.0, flRed, flGreen, flBlue );	
					Format(sBuffer, sizeof(sBuffer), "%i %i %i", RoundFloat(flRed*255.0), RoundFloat(flGreen*255.0), RoundFloat(flBlue*255.0));
					DispatchKeyValue(iEntity, "_light", sBuffer);
				}			
				// Multi color change
				case 2:
				{					
					new Float:rand = GetRandomFloat(0.1, 0.2);
					CreateTimer(rand, Checktime, iRef, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				}
				// Selected color
				case 3:
				{
					Format(sBuffer, sizeof(sBuffer), "%i %i %i", g_iColors[client][0], g_iColors[client][1], g_iColors[client][2]);
					DispatchKeyValue(iEntity, "_light", sBuffer);
				}
			}	
			
			Format(sBuffer, sizeof(sBuffer), "smokelight_%d", iEntity);
			DispatchKeyValue(iEntity,"targetname", sBuffer);
			Format(sBuffer, sizeof(sBuffer), "%f %f %f", a[0], a[1], a[2]);
			DispatchKeyValue(iEntity, "origin", sBuffer);
			DispatchKeyValue(iEntity, "iEntity", "-90 0 0");
			DispatchKeyValue(iEntity, "pitch","-90");
			DispatchKeyValue(iEntity, "distance","256");
			DispatchKeyValue(iEntity, "spotlight_radius","96");
			DispatchKeyValue(iEntity, "brightness","3");
			DispatchKeyValue(iEntity, "style","6");
			DispatchKeyValue(iEntity, "spawnflags","1");
			DispatchSpawn(iEntity);
			AcceptEntityInput(iEntity, "DisableShadow");
			
			AcceptEntityInput(iEntity, "TurnOn");
			
			CreateTimer(20.0, Delete, iRef, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

//////////////////////////////////////////////////////////////////
// Multi color change timer
//////////////////////////////////////////////////////////////////

public Action:Checktime(Handle:colortimer, any:ref){

	new entity= EntRefToEntIndex(ref);
	
	if (!IsValidEntity(entity)) return Plugin_Stop;

	if (entity != -1)
	{
		
		decl String:sBuffer[64];
		g_HSV_Temp = g_HSV_Temp + 3.0;	
		new Float:flRed, Float:flGreen, Float:flBlue;
		HSVtoRGB(g_HSV_Temp, 1.0, 1.0, flRed, flGreen, flBlue );	
		//PrintHintTextToAll ("Debug: %i -->> r=%i g=%i b=%i", RoundFloat(g_HSV_Temp), RoundFloat(flRed*255.0), RoundFloat(flGreen*255.0), RoundFloat(flBlue*255.0));
		Format(sBuffer, sizeof(sBuffer), "%i %i %i", RoundFloat(flRed*255.0), RoundFloat(flGreen*255.0), RoundFloat(flBlue*255.0));
		if (g_HSV_Temp >= 360.0) g_HSV_Temp = 0.0;
		DispatchKeyValue(entity, "_light", sBuffer);
	}
	
	return Plugin_Continue;
}

//////////////////////////////////////////////////////////////////
// HSV to RGB color
//////////////////////////////////////////////////////////////////

HSVtoRGB(&Float:h, Float:s, Float:v, &Float:r, &Float:g, &Float:b){

	if (s == 0)
	{
		r = v;  g = v;  b = v;
	} else {
		
		new Float:fHue, Float:fValue, Float:fSaturation;
		new Float:f;  new Float:p,Float:q,Float:t;
		if (h == 360.0) h = 0.0;
		fHue = h / 60.0;
		new i = RoundToFloor(fHue);
		f = fHue - i;
		fValue = v;
		fSaturation = s;
		p = fValue * (1.0 - fSaturation);
		q = fValue * (1.0 - (fSaturation * f));
		t = fValue * (1.0 - (fSaturation * (1.0 - f)));
		switch (i) 
		{
			case 1: 
			{
				r = q; g = fValue; b = p; 
			}
			case 2: 
			{
				r = p; g = fValue; b = t;
			}
			case 3: 
			{
				r = p; g = q; b = fValue;
			}
			case 4:
			{
				r = t; g = p; b = fValue;
			}
			case 5:
			{
				r = fValue; g = p; b = q; 
			}
			default:
			{
				r = fValue; g = t; b = p; 
			}	
		}
	}
}

//////////////////////////////////////////////////////////////////
// Delete entitys
//////////////////////////////////////////////////////////////////

public Action:Delete(Handle:timer, any:iRef)
{
	
	new entity= EntRefToEntIndex(iRef);
	
	if (entity != INVALID_ENT_REFERENCE)
	{
		if (IsValidEdict(entity)) AcceptEntityInput(entity, "kill");
	}
}

//////////////////////////////////////////////////////////////////
// Client Prefs Menu
//////////////////////////////////////////////////////////////////

public Menu_ClientPrefs(client, CookieMenuAction:action, any:info, String:buffer[], maxlen)
{
	if (action == CookieMenuAction_SelectOption)
	{
		Menu_Smoke(client);
	}
}

Menu_Smoke(client)
{
	decl String:sBuffer[128];
	new _iOptions, Handle:_hMenu = CreateMenu(MenuHandler_MenuSmoke);
	Format(sBuffer, sizeof(sBuffer), "%T", "Menu_Title_Main", client);
	SetMenuTitle(_hMenu, sBuffer);
	SetMenuPagination(_hMenu, MENU_NO_PAGINATION);
	SetMenuExitButton(_hMenu, true);
	
	new _iState = g_bValid[client] ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED;
	
	if(CheckCommandAccess(client, "Smoke_Access", g_iAccessFlag))
	{
		if(!g_iClientEnabled[client])
		{
			Format(sBuffer, sizeof(sBuffer), "Enable smoke colors", client);
		}
		else
		{
			Format(sBuffer, sizeof(sBuffer), "Disable smoke colors", client);
		}
	}
	else
	{
		Format(sBuffer, sizeof(sBuffer), "Enable smoke colors", client);
	}
	AddMenuItem(_hMenu, "0", sBuffer);
					
	_iOptions++;
	Format(sBuffer, sizeof(sBuffer), "%T", "Menu_Option_Mode", client);
	AddMenuItem(_hMenu, "1", sBuffer, _iState);
	
	if(g_iNumColors > 0)
	{
		_iOptions++;
		Format(sBuffer, sizeof(sBuffer), "%T", "Menu_Option_Color", client);
		AddMenuItem(_hMenu, "2", sBuffer, _iState);
	}
	
	if(_iOptions)
		DisplayMenu(_hMenu, client, MENU_TIME_FOREVER);
		
	return _iOptions;
}

public MenuHandler_MenuSmoke(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
			CloseHandle(menu);
		case MenuAction_Cancel: 
		{
			if(param2 == MenuCancel_ExitBack)
				ShowCookieMenu(param1);
		}
		case MenuAction_Select:
		{
			decl String:sTemp[8];
			GetMenuItem(menu, param2, sTemp, sizeof(sTemp));

			switch(StringToInt(sTemp))
			{
				case 0:
				{
					if(CheckCommandAccess(param1, "Smoke_Access", g_iAccessFlag))
					{
						if(!g_iClientEnabled[param1])
						{
							g_iClientEnabled[param1] = true;
							CPrintToChat(param1, "%s%t", g_sPrefixChat, "Phrase_Enable");
							SetClientCookie(param1, g_hCookieEnabled, "1");
						}
						else
						{
							g_iClientEnabled[param1] = false;
							CPrintToChat(param1, "%s%t", g_sPrefixChat, "Phrase_Disable");
							SetClientCookie(param1, g_hCookieEnabled, "0");
						}
					}
					else
					{
						CPrintToChat(param1, "%s%t", g_sPrefixChat, "Phrase_Restricted");
					}
					
					Menu_Smoke(param1);
				}
				case 1:
					Menu_Mode(param1);
				case 2:
					Menu_Colors(param1);
			}
		}
	}
	
	return;
}

Menu_Colors(client, index = 0)
{
	decl String:sTemp[8], String:sBuffer[128];
	new Handle:_hMenu = CreateMenu(MenuHandler_MenuColors);
	Format(sBuffer, sizeof(sBuffer), "%T", "Menu_Title_Color", client);
	SetMenuTitle(_hMenu, sBuffer);
	SetMenuExitButton(_hMenu, true);
	SetMenuExitBackButton(_hMenu, true);

	for(new i = 0; i <= g_iNumColors; i++)
	{
		Format(sBuffer, sizeof(sBuffer), "%s%s", (g_iSmokeData[client][INDEX_COLOR] == i) ? g_sPrefixSelect : g_sPrefixEmpty, g_sColorNames[i]);
		IntToString(i, sTemp, sizeof(sTemp));
		AddMenuItem(_hMenu, sTemp, sBuffer);
	}

	DisplayMenuAtItem(_hMenu, client, index, MENU_TIME_FOREVER);
}

public MenuHandler_MenuColors(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
			CloseHandle(menu);
		case MenuAction_Cancel:
			Menu_Smoke(param1);
		case MenuAction_Select:
		{
			decl String:sTemp[8], String:sBuffer[3][8];
			GetMenuItem(menu, param2, sTemp, sizeof(sTemp));
			g_iSmokeData[param1][INDEX_COLOR] = StringToInt(sTemp);
			
			ExplodeString(g_sColorSchemes[g_iSmokeData[param1][INDEX_COLOR]], " ", sBuffer, 3, 8);
			for(new i = 0; i <= 2; i++)
				g_iColors[param1][i] = StringToInt(sBuffer[i]);
			
			CPrintToChat(param1, "%s%t", g_sPrefixChat, "Phrase_Change_Color", g_sColorNames[g_iSmokeData[param1][INDEX_COLOR]]);
			SetClientCookie(param1, g_hCookieColor, sTemp);
			Menu_Colors(param1, GetMenuSelectionPosition());
		}
	}

	return;
}

Menu_Mode(client)
{
	decl String:sBuffer[128];
	new Handle:_hMenu = CreateMenu(MenuHandler_MenuMode);
	Format(sBuffer, sizeof(sBuffer), "%T", "Menu_Title_Mode", client);
	SetMenuTitle(_hMenu, sBuffer);
	SetMenuExitButton(_hMenu, true);
	SetMenuExitBackButton(_hMenu, true);

	Format(sBuffer, sizeof(sBuffer), "%T", "Menu_Option_Mode_Team", client, (g_iSmokeData[client][INDEX_MODE] == MODE_TEAM) ? g_sPrefixSelect : g_sPrefixEmpty);
	AddMenuItem(_hMenu, "0", sBuffer);

	Format(sBuffer, sizeof(sBuffer), "%T", "Menu_Option_Mode_Random", client, (g_iSmokeData[client][INDEX_MODE] == MODE_RANDOM) ? g_sPrefixSelect : g_sPrefixEmpty);
	AddMenuItem(_hMenu, "1", sBuffer);
	
	Format(sBuffer, sizeof(sBuffer), "%T", "Menu_Option_Mode_Multi", client, (g_iSmokeData[client][INDEX_MODE] == MODE_MULTI) ? g_sPrefixSelect : g_sPrefixEmpty);
	AddMenuItem(_hMenu, "2", sBuffer);
	
	Format(sBuffer, sizeof(sBuffer), "%T", "Menu_Option_Mode_Selected", client, (g_iSmokeData[client][INDEX_MODE] == MODE_SELECTED) ? g_sPrefixSelect : g_sPrefixEmpty);
	AddMenuItem(_hMenu, "3", sBuffer);
	
	DisplayMenu(_hMenu, client, MENU_TIME_FOREVER);
}

public MenuHandler_MenuMode(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
			CloseHandle(menu);
		case MenuAction_Cancel:
			Menu_Smoke(param1);
		case MenuAction_Select:
		{
			decl String:sTemp[8];
			GetMenuItem(menu, param2, sTemp, sizeof(sTemp));
			new _iTemp = StringToInt(sTemp);

			if(_iTemp != g_iSmokeData[param1][INDEX_MODE])
			{
				g_iSmokeData[param1][INDEX_MODE] = _iTemp;
				switch(g_iSmokeData[param1][INDEX_MODE])
				{
					case MODE_TEAM:
						CPrintToChat(param1, "%s%t", g_sPrefixChat, "Phrase_Change_Mode_Team");
					case MODE_RANDOM:
						CPrintToChat(param1, "%s%t", g_sPrefixChat, "Phrase_Change_Mode_Random");
					case MODE_MULTI:
						CPrintToChat(param1, "%s%t", g_sPrefixChat, "Phrase_Change_Mode_Multi");
					case MODE_SELECTED:
						CPrintToChat(param1, "%s%t", g_sPrefixChat, "Phrase_Change_Mode_Selected");
				}
				
				SetClientCookie(param1, g_hCookieMode, sTemp);
			}

			Menu_Mode(param1);
		}
	}

	return;
}

//////////////////////////////////////////////////////////////////
// Cookies
//////////////////////////////////////////////////////////////////

public OnClientCookiesCached(client)
{
	if(IsClientInGame(client) && !g_bLoaded[client] && !g_bFake[client])
	{
		LoadClientData(client);
	}
}

LoadClientData(client)
{
	decl String:buffer[4] = "";
	GetClientCookie(client, g_hCookieEnabled, buffer, sizeof(buffer));

	if(StrEqual(buffer, "", false))	//if cookie contents are blank
	{
		buffer = g_iDefaultEnable ? "1" : "0";
		g_iClientEnabled[client] = StringToInt(buffer) ? true : false;
		SetClientCookie(client, g_hCookieEnabled, buffer);

		g_iSmokeData[client][INDEX_COLOR] = g_iDefaultColor == -1 ? GetRandomInt(0, g_iNumColors) : g_iDefaultColor;
		IntToString(g_iSmokeData[client][INDEX_COLOR], buffer, 4);
		SetClientCookie(client, g_hCookieColor, buffer);
		
		g_iSmokeData[client][INDEX_MODE] = g_iDefaultMode;
		IntToString(g_iSmokeData[client][INDEX_MODE], buffer, 4);
		SetClientCookie(client, g_hCookieMode, buffer);
	}
	else
	{
		g_iClientEnabled[client] = (StringToInt(buffer)) ? true : false;

		GetClientCookie(client, g_hCookieColor, buffer, 4);
		g_iSmokeData[client][INDEX_COLOR] = StringToInt(buffer);
		if(g_iSmokeData[client][INDEX_COLOR] > g_iNumColors || g_iSmokeData[client][INDEX_COLOR] < 0)
		{
			g_iSmokeData[client][INDEX_COLOR] = g_iDefaultColor;
			IntToString(g_iSmokeData[client][INDEX_COLOR], buffer, 4);
			SetClientCookie(client, g_hCookieColor, buffer);
		}

		GetClientCookie(client, g_hCookieMode, buffer, 4);
		g_iSmokeData[client][INDEX_MODE] = StringToInt(buffer);

	}

	decl String:sBuffer[3][8];
	ExplodeString(g_sColorSchemes[g_iSmokeData[client][INDEX_COLOR]], " ", sBuffer, 3, 8);
	for(new i = 0; i <= 2; i++)
		g_iColors[client][i] = StringToInt(sBuffer[i]);
	
	g_bLoaded[client] = true;
}