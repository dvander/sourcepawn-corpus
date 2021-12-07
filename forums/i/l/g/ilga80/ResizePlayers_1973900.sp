#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#undef REQUIRE_EXTENSIONS
#include <sdkhooks>
#define REQUIRE_EXTENSIONS

#define PLUGIN_VERSION "1.2.0"
#define SELF_ACCESS ADMFLAG_GENERIC
#define TARGET_ACCESS ADMFLAG_CHEATS

public Plugin:myinfo =
{
    name 		=		"Resize Players",
    author		=		"11530",
    description	=		"Tiny!",
    version		=		PLUGIN_VERSION,
    url			=		"http://www.sourcemod.net"
};

new Handle:g_hMenu = INVALID_HANDLE;
new Handle:g_hDamage = INVALID_HANDLE;
new Handle:g_hNotify = INVALID_HANDLE;
new Handle:g_hVersion = INVALID_HANDLE;
new Handle:g_hEnabled = INVALID_HANDLE;
new Handle:g_hJoinStatus = INVALID_HANDLE;
new Handle:g_hDefaultScale = INVALID_HANDLE;
new Handle:g_hVoicesChanged = INVALID_HANDLE;
new Handle:g_hDefaultHeadScale = INVALID_HANDLE;

new bool:g_bMenu;
new bool:g_bEnabled;
new Float:g_fDefaultScale;
new Float:g_fDefaultHeadScale;
new g_iVoicesChanged;
new g_iJoinStatus;
new g_iDamage;
new g_iNotify;

new Float:g_fClientLastScale[MAXPLAYERS+1] = {1.0, ... };
new Float:g_fClientCurrentScale[MAXPLAYERS+1] = {1.0, ... };
new Float:g_fClientLastHeadScale[MAXPLAYERS+1] = {1.0, ... };
new Float:g_fClientCurrentHeadScale[MAXPLAYERS+1] = {1.0, ... };
new Handle:g_hClientResizeTimers[MAXPLAYERS+1] = { INVALID_HANDLE, ... };
new Handle:g_hClientResizeHeadTimers[MAXPLAYERS+1] = { INVALID_HANDLE, ... };

public OnPluginStart()
{
	g_hVersion = CreateConVar("sm_resize_version", PLUGIN_VERSION, "\"Resize Players\" version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	g_hEnabled = CreateConVar("sm_resize_enabled", "1", "0 = Disable plugin, 1 = Enable plugin", 0, true, 0.0);
	HookConVarChange(g_hEnabled, ConVarEnabledChanged);
	g_bEnabled = GetConVarBool(g_hEnabled);
	
	g_hDefaultScale = CreateConVar("sm_resize_defaultresize", "0.4", "Default scale of players when resized", 0, true, 0.0);
	HookConVarChange(g_hDefaultScale, ConVarScaleChanged);
	g_fDefaultScale = GetConVarFloat(g_hDefaultScale);
	
	g_hDefaultHeadScale = CreateConVar("sm_resize_defaultheadresize", "2.5", "Default scale of players' heads when resized", 0, true, 0.0);
	HookConVarChange(g_hDefaultHeadScale, ConVarHeadScaleChanged);
	g_fDefaultHeadScale = GetConVarFloat(g_hDefaultHeadScale);
	
	g_hJoinStatus = CreateConVar("sm_resize_joinstatus", "0", "Resize upon joining: 0 = No one, 1 = Everyone's whole body, 3 = Everyone's head 5 = Everyone's head and whole body (Add 1 to any value for admin only)", 0, true, 0.0);
	HookConVarChange(g_hJoinStatus, ConVarStatusChanged);
	g_iJoinStatus = GetConVarInt(g_hJoinStatus);
	
	g_hMenu = CreateConVar("sm_resize_menu", "0", "0 = Disable menus, 1 = Enable menus when no command parameters are given", 0, true, 0.0);
	HookConVarChange(g_hMenu, ConVarMenuChanged);
	g_bMenu = GetConVarBool(g_hMenu);
	
	g_hVoicesChanged = CreateConVar("sm_resize_voices", "0", "0 = Normal voices, 1 = Voice pitch scales with size, 2 = No low-pitched voices, 3 = No high-pitched voices", 0, true, 0.0);
	HookConVarChange(g_hVoicesChanged, ConVarVoicesChanged);
	g_iVoicesChanged = GetConVarInt(g_hVoicesChanged);
	
	g_hDamage = CreateConVar("sm_resize_damage", "0", "0 = Normal damage, 1 = Damage given scales with size, 2 = No up-scaled damage, 3 = No down-scaled damage", 0, true, 0.0);
	HookConVarChange(g_hDamage, ConVarDamageChanged);
	g_iDamage = GetConVarInt(g_hDamage);
	
	g_hNotify = CreateConVar("sm_resize_notify", "1", "0 = No notifications, 1 = Respect sm_show_activity, 2 = Notify everyone", 0, true, 0.0);
	HookConVarChange(g_hNotify, ConVarNotifyChanged);
	g_iNotify = GetConVarInt(g_hNotify);
	
	LoadTranslations("core.phrases.txt");
	LoadTranslations("common.phrases.txt");
	AddNormalSoundHook(SoundCallback);
	
	RegAdminCmd("sm_resize", OnResizeCmd, TARGET_ACCESS, "Toggles a client's size");
	//RegAdminCmd("sm_scale", OnResizeCmd, TARGET_ACCESS, "Toggles a client's size");
	RegAdminCmd("sm_resizeme", OnResizeMeCmd, SELF_ACCESS, "Toggles a client's size");
	//RegAdminCmd("sm_scaleme", OnResizeMeCmd, SELF_ACCESS, "Toggles a client's size");
	RegAdminCmd("sm_resizehead", OnResizeHeadCmd, TARGET_ACCESS, "Toggles a client's head size");
	//RegAdminCmd("sm_scalehead", OnResizeHeadCmd, TARGET_ACCESS, "Toggles a client's head size");
	RegAdminCmd("sm_resizemyhead", OnResizeMyHeadCmd, SELF_ACCESS, "Toggles a client's head size");
	//RegAdminCmd("sm_scalemyhead", OnResizeMyHeadCmd, SELF_ACCESS, "Toggles a client's head size");
}

public OnConfigsExecuted()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		g_fClientLastScale[i] = g_fDefaultScale;
		g_fClientLastHeadScale[i] = g_fDefaultHeadScale;
		if (IsClientInGame(i) && IsClientAuthorized(i))
		{
#if defined _sdkhooks_included
			SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
#endif
			if (g_bEnabled)
			{
				if (g_iJoinStatus == 1 || (g_iJoinStatus == 2 && CheckCommandAccess(i, "sm_resize", TARGET_ACCESS)))
				{
					ResizePlayer(i, g_fDefaultScale);
				}
				else if (g_iJoinStatus == 3 || (g_iJoinStatus == 4 && CheckCommandAccess(i, "sm_resizehead", TARGET_ACCESS)))
				{
					ResizePlayerHead(i, g_fDefaultHeadScale);
				}
				else if (g_iJoinStatus == 5)
				{
					ResizePlayer(i, g_fDefaultScale);
					ResizePlayerHead(i, g_fDefaultHeadScale);
				}
				else if (g_iJoinStatus == 6)
				{
					if (CheckCommandAccess(i, "sm_resize", TARGET_ACCESS))
					{
						ResizePlayer(i, g_fDefaultScale);
					}
					if (CheckCommandAccess(i, "sm_resizehead", TARGET_ACCESS))
					{
						ResizePlayerHead(i, g_fDefaultHeadScale);
					}
				}
			}
		}
	}
}

public OnMapStart()
{
	// hax against valvefail
	if (GuessSDKVersion() == SOURCE_SDK_EPISODE2VALVE)
	{
		SetConVarString(g_hVersion, PLUGIN_VERSION);
	}
}

stock ResizePlayer(const client, const Float:fScale = 0.0)
{
	if (client == 0)
	{
		ReplyToCommand(client, "\x05[SM]\x01 %t", "Unable to target");
		return;
	}

	if (fScale == 0.0)
	{
		if (g_fClientCurrentScale[client] != g_fClientLastScale[client])
		{
			SetEntPropFloat(client, Prop_Send, "m_flModelScale", g_fClientLastScale[client]);
			//SetEntPropFloat(client, Prop_Send, "m_flStepSize", 18.0 * g_fClientLastScale[client]);
			g_fClientCurrentScale[client] = g_fClientLastScale[client];
		}
		else
		{
			SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.0);
			//SetEntPropFloat(client, Prop_Send, "m_flStepSize", 18.0);
			g_fClientCurrentScale[client] = 1.0;
		}
	}
	else
	{
		if (fScale != 1.0)
		{
			g_fClientLastScale[client] = fScale;
		}
		SetEntPropFloat(client, Prop_Send, "m_flModelScale", fScale);
		//SetEntPropFloat(client, Prop_Send, "m_flStepSize", 18.0 * fScale);
		g_fClientCurrentScale[client] = fScale;
	}
}

stock ResizePlayerHead(const client, const Float:fScale = 0.0)
{
	if (client == 0)
	{
		ReplyToCommand(client, "\x05[SM]\x01 %t", "Unable to target");
		return;
	}

	if (fScale == 0.0)
	{
		if (g_fClientCurrentHeadScale[client] != g_fClientLastHeadScale[client])
		{
			//SetEntPropFloat(client, Prop_Send, "m_flHeadScale", g_fClientLastHeadScale[client]);
			g_fClientCurrentHeadScale[client] = g_fClientLastHeadScale[client];
		}
		else
		{
			//SetEntPropFloat(client, Prop_Send, "m_flHeadScale", 1.0);
			g_fClientCurrentHeadScale[client] = 1.0;
		}
	}
	else
	{
		if (fScale != 1.0)
		{
			g_fClientLastHeadScale[client] = fScale;
		}
		//SetEntPropFloat(client, Prop_Send, "m_flHeadScale", fScale);
		g_fClientCurrentHeadScale[client] = fScale;
	}
}

public Action:OnResizeMeCmd(client, args)
{
	if (g_bEnabled)
	{
		if (client == 0)
		{
			ReplyToCommand(client, "\x05[SM]\x01 %t", "Unable to target");
			return Plugin_Handled;
		}
		
		if (args == 0)
		{
			if (g_bMenu)
			{
				ShowResizeMenu(client);
			}
			else
			{
				ResizePlayer(client);
			}
		}
		else
		{
			ReplyToCommand(client, "\x05[SM]\x01 Usage: sm_resizeme");
		}
	}
	return Plugin_Handled;
}

public Action:OnResizeMyHeadCmd(client, args)
{
	if (g_bEnabled)
	{
		if (client == 0)
		{
			ReplyToCommand(client, "\x05[SM]\x01 %t", "Unable to target");
			return Plugin_Handled;
		}
		
		if (args == 0)
		{
			if (g_bMenu)
			{
				ShowResizeHeadMenu(client);
			}
			else
			{
				ResizePlayerHead(client);
			}
		}
		else
		{
			ReplyToCommand(client, "\x05[SM]\x01 Usage: sm_resizemyhead");
		}
	}
	return Plugin_Handled;
}

public Action:OnResizeCmd(client, args)
{
	if (g_bEnabled)
	{
		if (args == 0)
		{
			if (g_bMenu)
			{
				ShowResizeMenu(client);				
			}
			else
			{
				ResizePlayer(client);
				if (g_iNotify == 1)
				{
					ShowActivity2(client, "\x05[SM]\x01 ","%N was \x05resized\x01!", client);
				}
				else if (g_iNotify == 2)
				{
					PrintToChatAll("\x05[SM]\x01 %N was \x05resized\x01!", client);
				}
			}
			return Plugin_Handled;
		}
		else
		{
			new target_count, bool:tn_is_ml;
			decl String:sTargetName[MAX_TARGET_LENGTH], iTargetList[MAXPLAYERS], String:sTarget[MAX_NAME_LENGTH];
			GetCmdArg(1, sTarget, sizeof(sTarget));
			if ((target_count = ProcessTargetString(sTarget, client, iTargetList, MAXPLAYERS, 0, sTargetName, sizeof(sTargetName), tn_is_ml)) <= 0)
			{
				ReplyToTargetError(client, target_count);
				return Plugin_Handled;
			}
			if (tn_is_ml)
			{
				if (g_iNotify == 1)
				{
					ShowActivity2(client, "\x05[SM]\x01 ", "%N \x05resized\x01 %t!", client, sTargetName);
				}
				else if (g_iNotify == 2)
				{
					PrintToChatAll("\x05[SM]\x01 %N \x05resized\x01 %t!", client, sTargetName);
				}
			}
			else
			{
				if (g_iNotify == 1)
				{
					ShowActivity2(client, "\x05[SM]\x01 ", "%N \x05resized\x01 %s!", client, sTargetName);
				}
				else if (g_iNotify == 2)
				{
					PrintToChatAll("\x05[SM]\x01 %N \x05resized\x01 %s!", client, sTargetName);
				}
			}
			
			new Float:fScale = 0.0, Float:fTime = 0.0;
			if (args > 1)
			{
				decl String:sScale[128];
				GetCmdArg(2, sScale, sizeof(sScale));
				if ((fScale = StringToFloat(sScale)) <= 0.0)
				{
					fScale = 1.0;
				}
			}
			
			if (args > 2)
			{
				decl String:szTime[128];
				GetCmdArg(3, szTime, sizeof(szTime));
				fTime = StringToFloat(szTime);
					
				for (new i = 0; i < target_count; i++)
				{					
					if (iTargetList[i] != 0)
					{
						ResizePlayer(iTargetList[i], fScale);
						
						if (g_hClientResizeTimers[iTargetList[i]] != INVALID_HANDLE)
						{
							CloseHandle(g_hClientResizeTimers[iTargetList[i]]);
							g_hClientResizeTimers[iTargetList[i]] = INVALID_HANDLE;
						}
						
						if (fTime > 0.0)
						{							
							g_hClientResizeTimers[iTargetList[i]] = CreateTimer(fTime, ResizeTimer, GetClientUserId(iTargetList[i]));
						}
						else
						{
							ReplyToCommand(client, "\x05[SM]\x01 %t", "Invalid Amount");
						}
					}
				}			
			}			
			else
			{
				for (new i = 0; i < target_count; i++)
				{
					if (iTargetList[i] != 0)
					{
						ResizePlayer(iTargetList[i], fScale);						
					}
				}			
			}
		}
	}
	return Plugin_Handled;
}

public Action:ResizeTimer(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (client > 0)
	{
		ResizePlayer(client);
	}
	g_hClientResizeTimers[client] = INVALID_HANDLE;
}

public Action:ResizeHeadTimer(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (client > 0)
	{
		ResizePlayerHead(client);
	}
	g_hClientResizeHeadTimers[client] = INVALID_HANDLE;
}

public Action:OnResizeHeadCmd(client, args)
{	
	if (g_bEnabled)
	{
		if (args == 0)
		{
			if (g_bMenu)
			{
				ShowResizeHeadMenu(client);				
			}
			else
			{
				ResizePlayerHead(client);
				if (g_iNotify == 1)
				{
					ShowActivity2(client, "\x05[SM]\x01 ","%N's head was \x05resized\x01!", client);
				}
				else if (g_iNotify == 2)
				{
					PrintToChatAll("\x05[SM]\x01 %N's head was \x05resized\x01!", client);
				}
			}
			return Plugin_Handled;
		}
		else
		{
			new target_count, bool:tn_is_ml;
			decl String:sTargetName[MAX_TARGET_LENGTH], iTargetList[MAXPLAYERS], String:sTarget[MAX_NAME_LENGTH];
			GetCmdArg(1, sTarget, sizeof(sTarget));
			if ((target_count = ProcessTargetString(sTarget, client, iTargetList, MAXPLAYERS, 0, sTargetName, sizeof(sTargetName), tn_is_ml)) <= 0)
			{
				ReplyToTargetError(client, target_count);
				return Plugin_Handled;
			}
			if (tn_is_ml)
			{
				if (g_iNotify == 1)
				{
					ShowActivity2(client, "\x05[SM]\x01 ", "%N \x05resized\x01 the head of %t!", client, sTargetName);
				}
				else if (g_iNotify == 2)
				{
					PrintToChatAll("\x05[SM]\x01 %N \x05resized\x01 the head of %t!", client, sTargetName);
				}
			}
			else
			{
				if (g_iNotify == 1)
				{
					ShowActivity2(client, "\x05[SM]\x01 ", "%N \x05resized\x01 the head of %s!", client, sTargetName);
				}
				else if (g_iNotify == 2)
				{
					PrintToChatAll("\x05[SM]\x01 %N \x05resized\x01 the head of %s!", client, sTargetName);
				}
			}
			
			new Float:fScale = 0.0, Float:fTime = 0.0;			
			if (args > 1)
			{
				decl String:sScale[128];
				GetCmdArg(2, sScale, sizeof(sScale));
				if ((fScale = StringToFloat(sScale)) <= 0.0)
				{
					fScale = 1.0;
				}
			}
			
			if (args > 2)
			{
				decl String:szTime[128];
				GetCmdArg(3, szTime, sizeof(szTime));
				fTime = StringToFloat(szTime);
					
				for (new i = 0; i < target_count; i++)
				{
					if (iTargetList[i] != 0)
					{
						ResizePlayerHead(iTargetList[i], fScale);
							
						if (g_hClientResizeHeadTimers[iTargetList[i]] != INVALID_HANDLE)
						{
							CloseHandle(g_hClientResizeHeadTimers[iTargetList[i]]);
							g_hClientResizeHeadTimers[iTargetList[i]] = INVALID_HANDLE;
						}
						
						if (fTime > 0.0)
						{
							g_hClientResizeHeadTimers[iTargetList[i]] = CreateTimer(fTime, ResizeHeadTimer, GetClientUserId(iTargetList[i]));
						}
						else
						{
							ReplyToCommand(client, "\x05[SM]\x01 %t", "Invalid Amount");
						}
					}
				}			
			}			
			else
			{
				for (new i = 0; i < target_count; i++)
				{
					if (iTargetList[i] != 0)
					{
						ResizePlayerHead(iTargetList[i], fScale);						
					}
				}			
			}
		}
	}
	return Plugin_Handled;
}

stock ShowResizeMenu(client)
{
	new Handle:hMenu = CreateMenu(ResizeMenuHandler);
	SetMenuTitle(hMenu, "Choose a Size:");
	AddMenuItem(hMenu, "0.10", "Smallest (10%)");
	AddMenuItem(hMenu, "0.25", "Smaller (25%)");
	AddMenuItem(hMenu, "0.50", "Small (50%)");
	AddMenuItem(hMenu, "1.00", "Normal (100%)");
	AddMenuItem(hMenu, "1.25", "Large (125%)");
	AddMenuItem(hMenu, "1.50", "Larger (150%)");
	AddMenuItem(hMenu, "2.00", "Largest (200%)");
	SetMenuExitBackButton(hMenu, true);
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
	return;
}

stock ShowResizeHeadMenu(client)
{
	new Handle:hMenu = CreateMenu(ResizeHeadMenuHandler);
	SetMenuTitle(hMenu, "Choose a Head Size:");
	AddMenuItem(hMenu, "0.50", "Smallest (50%)");
	AddMenuItem(hMenu, "0.75", "Small (75%)");
	AddMenuItem(hMenu, "1.00", "Normal (100%)");
	AddMenuItem(hMenu, "2.00", "Large (200%)");
	AddMenuItem(hMenu, "3.00", "Largest (300%)");
	SetMenuExitBackButton(hMenu, true);
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
	return;
}

public ResizeMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Select:
		{
			decl String:info[32];
			GetMenuItem(menu, param2, info, sizeof(info));
			new Float:fScale = StringToFloat(info);
			ResizePlayer(param1, fScale);
			if (g_iNotify == 1)
			{
				ShowActivity2(param1, "\x05[SM]\x01 ","%N was \x05resized\x01!", param1);
			}
			else if (g_iNotify == 2)
			{
				PrintToChatAll("\x05[SM]\x01 %N was \x05resized\x01!", param1);
			}
		}
	}
}

public ResizeHeadMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Select:
		{
			decl String:info[32];
			GetMenuItem(menu, param2, info, sizeof(info));
			new Float:fScale = StringToFloat(info);
			ResizePlayerHead(param1, fScale);
			if (g_iNotify == 1)
			{
				ShowActivity2(param1, "\x05[SM]\x01 ","%N's head was \x05resized\x01!", param1);
			}
			else if (g_iNotify == 2)
			{
				PrintToChatAll("\x05[SM]\x01 %N's head was \x05resized\x01!", param1);
			}
		}
	}
}

public ConVarEnabledChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
	g_bEnabled = (StringToInt(newvalue) != 0);
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if (g_bEnabled)
			{
				if (g_iJoinStatus == 1 || (g_iJoinStatus == 2 && CheckCommandAccess(i, "sm_resize", TARGET_ACCESS)))
				{
					ResizePlayer(i, g_fDefaultScale);
				}
				else if (g_iJoinStatus == 3 || (g_iJoinStatus == 4 && CheckCommandAccess(i, "sm_resizehead", TARGET_ACCESS)))
				{
					ResizePlayerHead(i, g_fDefaultHeadScale);
				}
				else if (g_iJoinStatus == 5)
				{
					ResizePlayer(i, g_fDefaultScale);
					ResizePlayerHead(i, g_fDefaultHeadScale);
				}
				else if (g_iJoinStatus == 6)
				{
					if (CheckCommandAccess(i, "sm_resize", TARGET_ACCESS))
					{
						ResizePlayer(i, g_fDefaultScale);
					}
					if (CheckCommandAccess(i, "sm_resizehead", TARGET_ACCESS))
					{
						ResizePlayerHead(i, g_fDefaultHeadScale);
					}
				}
				else
				{
					ResizePlayer(i, 1.0);
				}
			}
			else
			{
				ResizePlayer(i, 1.0);
			}
		}
	}
}

public ConVarStatusChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
	g_iJoinStatus = StringToInt(newvalue);
}

public ConVarVoicesChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
	g_iVoicesChanged = StringToInt(newvalue);
}

public ConVarScaleChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
	g_fDefaultScale = StringToFloat(newvalue);
	
	if (g_fDefaultScale <= 0.0)
	{
		g_fDefaultScale = 1.0;
	}
	
	for (new i = 1; i <= MaxClients; i++)
	{
		g_fClientLastScale[i] = g_fDefaultScale;
	}
}

public ConVarHeadScaleChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
	g_fDefaultHeadScale = StringToFloat(newvalue);
	
	if (g_fDefaultHeadScale <= 0.0)
	{
		g_fDefaultHeadScale = 1.0;
	}
	
	for (new i = 1; i <= MaxClients; i++)
	{
		g_fClientLastHeadScale[i] = g_fDefaultHeadScale;
	}
}

public ConVarDamageChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
	g_iDamage = StringToInt(newvalue);
}

public ConVarMenuChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])
{	
	g_bMenu = (StringToInt(newvalue) != 0);
}

public ConVarNotifyChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
	g_iNotify = StringToInt(newvalue);
}

#if defined _sdkhooks_included
public OnClientPutInServer(client)
{
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}
#endif

public OnGameFrame()
{
	if (g_bEnabled)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && g_fClientCurrentHeadScale[i] != 1.0)
			{
				SetEntPropFloat(i, Prop_Send, "m_flHeadScale", g_fClientCurrentHeadScale[i]);
			}
		}
	}
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (g_bEnabled && g_iDamage > 0 && attacker > 0 && attacker <= MaxClients)
	{
		if (IsValidEdict(inflictor))
		{
			new String:sClassName[64];
			GetEdictClassname(inflictor, sClassName, sizeof(sClassName));
			//Remove if/when buildings are added
			if (strcmp(sClassName, "obj_sentrygun") != 0)
			{
				if (g_iDamage == 1 || (g_iDamage == 2 && g_fClientCurrentScale[attacker] < 1.0) || (g_iDamage == 3 && g_fClientCurrentScale[attacker] > 1.0))
				{
					damage *= g_fClientCurrentScale[attacker];
					return Plugin_Changed;
				}
			}
		}
	}
	return Plugin_Continue;
}

public OnClientPostAdminCheck(client)
{
	if (g_bEnabled)
	{
		if (g_iJoinStatus == 1 || (g_iJoinStatus == 2 && CheckCommandAccess(client, "sm_resize", TARGET_ACCESS)))
		{
			ResizePlayer(client, g_fDefaultScale);
		}
		else if (g_iJoinStatus == 3 || (g_iJoinStatus == 4 && CheckCommandAccess(client, "sm_resizehead", TARGET_ACCESS)))
		{
			ResizePlayerHead(client, g_fDefaultHeadScale);
		}
		else if (g_iJoinStatus == 5)
		{
			ResizePlayer(client, g_fDefaultScale);
			ResizePlayerHead(client, g_fDefaultHeadScale);
		}
		else if (g_iJoinStatus == 6)
		{
			if (CheckCommandAccess(client, "sm_resize", TARGET_ACCESS))
			{
				ResizePlayer(client, g_fDefaultScale);
			}
			if (CheckCommandAccess(client, "sm_resizehead", TARGET_ACCESS))
			{
				ResizePlayerHead(client, g_fDefaultHeadScale);
			}
		}
	}
}

public Action:SoundCallback(clients[64], &numClients, String:sSample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	if (g_bEnabled && g_iVoicesChanged > 0)
	{
		if (entity > 0 && entity <= MaxClients && channel == SNDCHAN_VOICE)
		{
			if (g_iVoicesChanged == 1 || (g_iVoicesChanged == 2  && g_fClientCurrentScale[entity] < 1.0) || (g_iVoicesChanged == 3  && g_fClientCurrentScale[entity] > 1.0))
			{
				//Next expression is ((175/(1+6x))+75) so results stay between 75 and 250 with 100 pitch at normal size.
				pitch = RoundToNearest((175 / (1 + (6 * g_fClientCurrentScale[entity] * g_fClientCurrentHeadScale[entity]))) + 75);
				flags |= SND_CHANGEPITCH;
				return Plugin_Changed;
			}
		}
	}
	return Plugin_Continue;
}

public OnClientDisconnect_Post(client)
{
	g_fClientLastScale[client] = g_fDefaultScale;
	g_fClientLastHeadScale[client] = g_fDefaultHeadScale;
	g_fClientCurrentScale[client] = 1.0;
	g_fClientCurrentHeadScale[client] = 1.0;
	
	if (g_hClientResizeTimers[client] != INVALID_HANDLE)
	{
		CloseHandle(g_hClientResizeTimers[client]);
		g_hClientResizeTimers[client] = INVALID_HANDLE;
	}
}

public OnPluginEnd()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			ResizePlayer(i, 1.0);
			ResizePlayerHead(i, 1.0);
		}
	}
}

//Written by Steve "11530" Marchant.