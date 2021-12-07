/*
	Removed unnecessary (and incorrect) usage of void: from newbie days.
	Fixed a case where late-loading state was never disabled.
	Modified a few cases to ensure handles are detected and closed, even if redundant.
	Changed version cvar to sm_speedometer_version rather than sm_surfing_meter_version.
	Removed cvars sm_speedometer_format, sm_speedometer_message, and sm_speedometer_accuracy.
	Added translations support.
	Optimized several areas of code.
*/

#pragma semicolon 1
#include <sourcemod>
#include <clientprefs>

#define PLUGIN_VERSION "1.0.6"

new Handle:g_hMethod = INVALID_HANDLE;
new Handle:g_hFactor = INVALID_HANDLE;
new Handle:g_hDisplay = INVALID_HANDLE;
new Handle:g_hFastest = INVALID_HANDLE;
new Handle:g_hDefault = INVALID_HANDLE;
new Handle:g_hCookie = INVALID_HANDLE;

new g_iTeam[MAXPLAYERS + 1];
new bool:g_bLoaded[MAXPLAYERS + 1];
new bool:g_bAlive[MAXPLAYERS + 1];
new bool:g_bShowDisplay[MAXPLAYERS + 1];
new Handle:g_hTimer_Display[MAXPLAYERS + 1] = { INVALID_HANDLE, ... };

new bool:g_bEnabled, bool:g_bLateLoad, bool:g_bUseOnFrame, bool:g_bUseTimer, bool:g_bEnding, bool:g_bShowFastest, bool:g_bDefault;
new g_iDisplayMethod, g_iFastestClient;
new Float:g_fTimerRate, Float:g_fVelocityFactor, Float:g_fFastestVelocity;

public Plugin:myinfo =
{
	name = "Speedometer",
	author = "Twisted|Panda",
	description = "Plugin that provides a few options for displaying a user's current velocity for surfing.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/index.php"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	g_bLateLoad = late;
	return APLRes_Success;
}

public OnPluginStart()
{	
	LoadTranslations("common.phrases");
	LoadTranslations("sm_speedometer.phrases");

	CreateConVar("sm_speedometer_version", PLUGIN_VERSION, "Speedometer: Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hMethod = CreateConVar("sm_speedometer_method", "0.1", "Determines plugin functionality. (-1.0 = OnGameFrame(), 0.0 = Disabled, 0.1 <-> 2.0 = Refresh Rate)", FCVAR_NONE, true, -1.0, true, 2.0);
	HookConVarChange(g_hMethod, Action_OnSettingsChange);
	g_hFactor = CreateConVar("sm_speedometer_factor", "0.0", "Optional numerical value that can be used to derive real world units from in-game velocity.", FCVAR_NONE, true, 0.0);
	HookConVarChange(g_hFactor, Action_OnSettingsChange);
	g_hDisplay = CreateConVar("sm_speedometer_area", "0", "Determines printing area functionality. (0 = Hint, 1 = Center, 2 = Hud Hint)", FCVAR_NONE, true, 0.0, true, 2.0);
	HookConVarChange(g_hDisplay, Action_OnSettingsChange);
	g_hFastest = CreateConVar("sm_speedometer_fastest", "1", "If enabled, the player with the highest velocity will be displayed at the end of the round.", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hFastest, Action_OnSettingsChange);
	g_hDefault = CreateConVar("sm_speedometer_default", "1", "If enabled, new clients will start with the speedometer enabled.", FCVAR_NONE);
	HookConVarChange(g_hDefault, Action_OnSettingsChange);
	AutoExecConfig(true, "sm_speedometer");

	RegConsoleCmd("sm_meter", Command_Meter);
	RegConsoleCmd("sm_speedometer", Command_Meter);

	HookEvent("player_team", Event_OnPlayerTeam);
	HookEvent("player_spawn", Event_OnPlayerSpawn);
	HookEvent("player_death", Event_OnPlayerDeath);
	HookEvent("round_start", Event_OnRoundStart);
	HookEvent("round_end", Event_OnRoundEnd);

	g_hCookie = RegClientCookie("Cookie_Speedometer", "The client's setting for speedometer.", CookieAccess_Protected);
	SetCookieMenuItem(Menu_Status, 0, "Speedometer");

	Define_Defaults();
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
					g_bAlive[i] = IsPlayerAlive(i) ? true : false;
					if(!IsFakeClient(i))
					{
						if(AreClientCookiesCached(i))
							LoadCookies(i);
							
						if(g_bUseTimer && !g_bEnding && g_fTimerRate)
							g_hTimer_Display[i] = CreateTimer(g_fTimerRate, Timer_Display, i, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
					}
				}
			}
			
			g_bLateLoad = false;
		}
	}
}

public OnClientConnected(client)
{
	if(g_bEnabled)
	{
		g_bShowDisplay[client] = g_bDefault;
		if(AreClientCookiesCached(client) && !g_bLoaded[client] && !IsFakeClient(client))
			LoadCookies(client);
	}
}

public OnClientDisconnect(client)
{
	if(g_bEnabled)
	{
		g_iTeam[client] = 0;
		g_bAlive[client] = g_bLoaded[client] = g_bShowDisplay[client] = false;

		if(g_iFastestClient == client)
			g_iFastestClient = 0;

		if(g_bUseTimer && g_hTimer_Display[client] != INVALID_HANDLE && CloseHandle(g_hTimer_Display[client]))
			g_hTimer_Display[client] = INVALID_HANDLE;
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
		if(g_iTeam[client] <= 1)
		{
			g_bAlive[client] = false;
			if(g_bUseTimer && g_hTimer_Display[client] != INVALID_HANDLE && CloseHandle(g_hTimer_Display[client]))
				g_hTimer_Display[client] = INVALID_HANDLE;
		}
	}
	
	return Plugin_Continue;
}

public Action:Event_OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(!client || !IsClientInGame(client) || g_iTeam[client] <= 1)
			return Plugin_Continue;
		
		g_bAlive[client] = true;
		if(g_bUseTimer && g_bShowDisplay[client] && !g_bEnding && !IsFakeClient(client))
			g_hTimer_Display[client] = CreateTimer(g_fTimerRate, Timer_Display, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
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
		if(g_bUseTimer && g_hTimer_Display[client] != INVALID_HANDLE && CloseHandle(g_hTimer_Display[client]))
			g_hTimer_Display[client] = INVALID_HANDLE;
	}

	return Plugin_Continue;
}

public Action:Event_OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		g_bEnding = false;

		if(g_bShowFastest)
		{
			g_iFastestClient = 0;
			g_fFastestVelocity = 0.0;
		}
	}
	
	return Plugin_Continue;
}

public Action:Event_OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		g_bEnding = true;

		if(g_bUseTimer)
		{
			for(new i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i))
				{
					if(g_hTimer_Display[i] != INVALID_HANDLE && CloseHandle(g_hTimer_Display[i]))
						g_hTimer_Display[i] = INVALID_HANDLE;
				}
			}
		}

		if(g_bShowFastest)
		{
			decl String:sName[MAX_NAME_LENGTH];
			if(IsClientInGame(g_iFastestClient))
				GetClientName(g_iFastestClient, sName, sizeof(sName));
			else
				Format(sName, sizeof(sName), "%T", "Phrase_Mystery_Winner", LANG_SERVER);

			PrintToChatAll("%t%t", "Prefix_Chat", "Phrase_Highest_Velocity", sName, g_fFastestVelocity);
		}
	}
	
	return Plugin_Continue;
}

public Action:Command_Meter(client, args)
{
	if(g_bEnabled && client)
	{
		if(g_bShowDisplay[client])
		{
			SetClientCookie(client, g_hCookie, "0");
			PrintToChat(client, "%t%t", "Prefix_Chat", "Phrase_Disable_Speedometer");
	
			if(g_bUseTimer && g_hTimer_Display[client] != INVALID_HANDLE && CloseHandle(g_hTimer_Display[client]))
				g_hTimer_Display[client] = INVALID_HANDLE;
				
			switch(g_iDisplayMethod)
			{
				case 0:
					PrintHintText(client, "");
				case 1:
					PrintCenterText(client, "");
				case 2:
				{
					new Handle:hTemp = StartMessageOne("KeyHintText", client);
					BfWriteByte(hTemp, 1); 
					BfWriteString(hTemp, ""); 
					EndMessage();
				}
			}
		}
		else
		{
			SetClientCookie(client, g_hCookie, "1");
			PrintToChat(client, "%t%t", "Prefix_Chat", "Phrase_Enable_Speedometer");

			if(g_bUseTimer)
				g_hTimer_Display[client] = CreateTimer(g_fTimerRate, Timer_Display, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}

		g_bShowDisplay[client] = !g_bShowDisplay[client];
	}
	
	return Plugin_Handled;
}

public Action:Timer_Display(Handle:timer, any:client)
{
	if(!g_bAlive[client] || g_iTeam[client] <= 1 || !g_bShowDisplay[client])
	{
		g_hTimer_Display[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	decl Float:_fTemp[3], Float:_fVelocity;
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", _fTemp);
	for(new i = 0; i <= 2; i++)
		_fTemp[i] *= _fTemp[i];

	_fVelocity = SquareRoot(_fTemp[0] + _fTemp[1] + _fTemp[2]);
	if(g_fVelocityFactor)
		_fVelocity /= g_fVelocityFactor;

	switch(g_iDisplayMethod)
	{
		case 0:
			PrintHintText(client, "%t", "Phrase_Velocity_Display", _fVelocity);
		case 1:
			PrintCenterText(client, "%t", "Phrase_Velocity_Display", _fVelocity);
		case 2:
		{
			decl String:sBuffer[128];
			Format(sBuffer, sizeof(sBuffer), "%T", "Phrase_Velocity_Display", client, _fVelocity);
			new Handle:hTemp = StartMessageOne("KeyHintText", client);
			BfWriteByte(hTemp, 1); 
			BfWriteString(hTemp, sBuffer); 
			EndMessage();
		}
	}

	if(g_bShowFastest && _fVelocity > g_fFastestVelocity)
	{
		g_fFastestVelocity = _fVelocity;
		g_iFastestClient = client;
	}

	return Plugin_Continue;
}

public OnGameFrame()
{
	if(g_bUseOnFrame)
	{
		decl String:sBuffer[128];
		decl Float:_fTemp[3], Float:_fVelocity;
		for(new i = 1; i <= MaxClients; i++)
		{
			if(g_bAlive[i] && g_iTeam[i] >= 2 && g_bShowDisplay[i])
			{
				GetEntPropVector(i, Prop_Data, "m_vecVelocity", _fTemp);
				for(new j = 0; j <= 2; j++)
					_fTemp[j] *= _fTemp[j];

				_fVelocity = SquareRoot(_fTemp[0] + _fTemp[1] + _fTemp[2]);
				if(g_fVelocityFactor)
					_fVelocity /= g_fVelocityFactor;

				switch(g_iDisplayMethod)
				{
					case 0:
						PrintHintText(i, "%t", "Phrase_Velocity_Display", _fVelocity);
					case 1:
						PrintCenterText(i, "%t", "Phrase_Velocity_Display", _fVelocity);
					case 2:
					{
						Format(sBuffer, sizeof(sBuffer), "%T", "Phrase_Velocity_Display", i, _fVelocity);
						new Handle:hTemp = StartMessageOne("KeyHintText", i);
						BfWriteByte(hTemp, 1); 
						BfWriteString(hTemp, sBuffer); 
						EndMessage();
					}
				}
				
				if(g_bShowFastest && _fVelocity > g_fFastestVelocity)
				{
					g_fFastestVelocity = _fVelocity;
					g_iFastestClient = i;
				}
			}
		}
	}
}

public OnClientCookiesCached(client)
{
	if(g_bEnabled)
	{
		if(!g_bLoaded[client])
			LoadCookies(client);
	}
}

LoadCookies(client)
{
	new String:sCookie[2];
	GetClientCookie(client, g_hCookie, sCookie, sizeof(sCookie));

	if(StrEqual(sCookie, "", false))
	{
		if(g_bDefault)
			SetClientCookie(client, g_hCookie, "1");
		else
			SetClientCookie(client, g_hCookie, "0");
	}
	else
		g_bShowDisplay[client] = StrEqual(sCookie, "0") ? false : true;
		
	g_bLoaded[client] = true;
}

public Menu_Status(client, CookieMenuAction:action, any:info, String:buffer[], maxlen) 
{
	switch(action)
	{
		case CookieMenuAction_DisplayOption:
			Format(buffer, maxlen, "%T", "Menu_Cookie_Display", client);
		case CookieMenuAction_SelectOption:
		{
			if(!g_bEnabled)
				PrintToChat(client, "%t%t", "Prefix_Chat", "Phrase_Plugin_Disabled");
			else
				Menu_Cookies(client);
		}
	}
}

Menu_Cookies(client)
{
	decl String:sBuffer[128];
	Format(sBuffer, sizeof(sBuffer), "%T", "Menu_Cookie_Title", client);
	new Handle:hMenu = CreateMenu(MenuHandler_CookieMenu);
	SetMenuExitBackButton(hMenu, true);
	SetMenuExitButton(hMenu, true);
	SetMenuTitle(hMenu, sBuffer);

	if(g_bShowDisplay[client])
	{
		Format(sBuffer, sizeof(sBuffer), "%T", "Menu_Cookie_Disable", client);
		AddMenuItem(hMenu, "0", sBuffer);
	}
	else
	{
		Format(sBuffer, sizeof(sBuffer), "%T", "Menu_Cookie_Enable", client);
		AddMenuItem(hMenu, "1", sBuffer);
	}

	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
}

public MenuHandler_CookieMenu(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
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
			if(g_bShowDisplay[param1])
			{
				SetClientCookie(param1, g_hCookie, "0");
				PrintToChat(param1, "%t%t", "Prefix_Chat", "Phrase_Disable_Speedometer");

				if(g_bUseTimer && g_hTimer_Display[param1] != INVALID_HANDLE && CloseHandle(g_hTimer_Display[param1]))
					g_hTimer_Display[param1] = INVALID_HANDLE;

				switch(g_iDisplayMethod)
				{
					case 0:
						PrintHintText(param1, "");
					case 1:
						PrintCenterText(param1, "");
					case 2:
					{
						new Handle:hTemp = StartMessageOne("KeyHintText", param1);
						BfWriteByte(hTemp, 1); 
						BfWriteString(hTemp, ""); 
						EndMessage();
					}
				}
			}
			else
			{
				SetClientCookie(param1, g_hCookie, "1");
				PrintToChat(param1, "%t%t", "Prefix_Chat", "Phrase_Enable_Speedometer");

				if(g_bUseTimer)
					g_hTimer_Display[param1] = CreateTimer(g_fTimerRate, Timer_Display, param1, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			}

			g_bShowDisplay[param1] = !g_bShowDisplay[param1];
			Menu_Cookies(param1);
		}
	}
}

Define_Defaults()
{
	new Float:_fTemp = GetConVarFloat(g_hMethod);
	if(!_fTemp)
	{
		g_bEnabled = false;
		g_bUseOnFrame = false;
		g_bUseTimer = false;
	}
	else
	{
		g_bEnabled = true;
		g_bUseOnFrame = _fTemp < 0.0 ? true : false;
		g_bUseTimer = _fTemp < 0.0 ? false : true;
		g_fTimerRate = _fTemp < 0.0 ? 0.0 : _fTemp;
	}

	g_fVelocityFactor = GetConVarFloat(g_hFactor);
	g_iDisplayMethod = GetConVarInt(g_hDisplay);
	g_bShowFastest =  GetConVarBool(g_hFastest);
	g_bDefault = GetConVarBool(g_hDefault);
}

public Action_OnSettingsChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	if(cvar == g_hMethod)
	{
		new Float:_fTemp = StringToFloat(newvalue);
		if(_fTemp == 0.0)
		{
			g_bEnabled = false;
			g_bUseOnFrame = false;
			g_bUseTimer = false;
		}
		else
		{
			g_bEnabled = true;
			g_bUseOnFrame = _fTemp < 0.0 ? true : false;
			g_bUseTimer = _fTemp < 0.0 ? false : true;
			g_fTimerRate = _fTemp < 0.0 ? 0.0 : _fTemp;

			for(new i = 1; i <= MaxClients; i++)
			{
				if(g_hTimer_Display[i] != INVALID_HANDLE && CloseHandle(g_hTimer_Display[i]))
					g_hTimer_Display[i] = INVALID_HANDLE;

				g_bAlive[i] = IsPlayerAlive(i) ? true : false;
				if(!g_bEnding && g_bUseTimer && IsClientInGame(i)) 
				{
					if(g_fTimerRate && !IsFakeClient(i))
						g_hTimer_Display[i] = CreateTimer(g_fTimerRate, Timer_Display, i, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				}
			}
		}
	}
	else if(cvar == g_hFactor)
		g_fVelocityFactor = StringToFloat(newvalue);
	else if(cvar == g_hDisplay)
		g_iDisplayMethod = StringToInt(newvalue);
	else if(cvar == g_hFastest)
		g_bShowFastest = StringToInt(newvalue) ? true : false;
	else if(cvar == g_hDefault)
		g_bDefault = StringToInt(newvalue) ? true : false;
}