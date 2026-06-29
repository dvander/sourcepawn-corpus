#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#undef REQUIRE_EXTENSIONS
#include <sdkhooks>
#define REQUIRE_EXTENSIONS

#define PLUGIN_VERSION "1.1.1"

public Plugin:myinfo =
{
    name 		=		"[TF2] Resize Players",
    author		=		"11530",
    description	=		"Tiny!",
    version		=		PLUGIN_VERSION,
    url			=		"http://www.sourcemod.net"
};

new Handle:g_hVersion = INVALID_HANDLE;
new Handle:g_hEnabled = INVALID_HANDLE;
new Handle:g_hDefaultScale = INVALID_HANDLE;
new Handle:g_hJoinStatus = INVALID_HANDLE;
new Handle:g_hMenu = INVALID_HANDLE;
new Handle:g_hVoicesChanged = INVALID_HANDLE;
new Handle:g_hDamage = INVALID_HANDLE;

new bool:g_bEnabled;
new g_iJoinStatus;
new Float:g_fDefaultScale;
new Float:g_fClientCurrentScale[MAXPLAYERS+1] = {1.0, ... };
new Float:g_fClientLastScale[MAXPLAYERS+1] = {1.0, ... };
new bool:g_bMenu;
new g_iVoicesChanged;
new bool:g_bDamage;

public OnPluginStart()
{
	g_hVersion = CreateConVar("sm_resize_version", PLUGIN_VERSION, "\"Resize Players\" Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	g_hEnabled = CreateConVar("sm_resize_enabled", "1", "0 = Disable plugin, 1 = Enable plugin", 0, true, 0.0, true, 1.0);
	HookConVarChange(g_hEnabled, ConVarEnabledChanged);
	g_bEnabled = GetConVarBool(g_hEnabled);
	
	g_hDefaultScale = CreateConVar("sm_resize_defaultresize", "0.7", "Scale of models", 0, true, 0.0);
	HookConVarChange(g_hDefaultScale, ConVarScaleChanged);
	g_fDefaultScale = GetConVarFloat(g_hDefaultScale);
	
	g_hJoinStatus = CreateConVar("sm_resize_joinstatus", "1", "0 = No one's resized upon joining, 1 = Everyone's resized upon joining, 2 = Admins Only", 0, true, 0.0, true, 2.0);
	HookConVarChange(g_hJoinStatus, ConVarStatusChanged);
	g_iJoinStatus = GetConVarInt(g_hJoinStatus);
	
	g_hMenu = CreateConVar("sm_resize_menu", "0", "0 = Disable menus, 1 = Enable menus when no parameters are given", 0, true, 0.0, true, 1.0);
	HookConVarChange(g_hMenu, ConVarMenuChanged);
	g_bMenu = GetConVarBool(g_hMenu);
	
	g_hVoicesChanged = CreateConVar("sm_resize_voices", "0", "0 = Normal voices, 1 = Voice pitch scales with size, 2 = No low-pitched voices, 3 = No high-pitched voices", 0, true, 0.0, true, 3.0);
	HookConVarChange(g_hVoicesChanged, ConVarVoicesChanged);
	g_iVoicesChanged = GetConVarInt(g_hVoicesChanged);
	
	g_hDamage = CreateConVar("sm_resize_damage", "0", "0 = Normal damage, 1 = Damage scales with size", 0, true, 0.0, true, 1.0);
	HookConVarChange(g_hDamage, ConVarDamageChanged);
	g_bDamage = GetConVarBool(g_hDamage);
	
	LoadTranslations("common.phrases.txt");
	AddNormalSoundHook(SoundCallback);
	
	RegAdminCmd("sm_resize", OnResizeCmd, ADMFLAG_CHEATS, "Toggles a client's size");
	RegAdminCmd("sm_scale", OnResizeCmd, ADMFLAG_CHEATS, "Toggles a client's size");
	RegAdminCmd("sm_resizeme", OnResizeMeCmd, 0, "Toggles a client's size");
	RegAdminCmd("sm_scaleme", OnResizeMeCmd, 0, "Toggles a client's size");
}

public OnConfigsExecuted()
{
	if (g_bEnabled)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			g_fClientLastScale[i] = g_fDefaultScale;
			if (IsClientInGame(i) && IsClientAuthorized(i))
			{
				SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
				if (g_iJoinStatus == 1 || (g_iJoinStatus == 2  && CheckCommandAccess(i, "sm_resize", ADMFLAG_CHEATS)))
				{
					ResizePlayer(i, g_fDefaultScale);
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

ResizePlayer(client, Float:fScale = 0.0)
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
			SetEntPropFloat(client, Prop_Send, "m_flStepSize", 18.0 * g_fClientLastScale[client]);
			g_fClientCurrentScale[client] = g_fClientLastScale[client];
		}
		else
		{
			SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.0);
			SetEntPropFloat(client, Prop_Send, "m_flStepSize", 18.0);
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
		SetEntPropFloat(client, Prop_Send, "m_flStepSize", 18.0 * fScale);
		g_fClientCurrentScale[client] = fScale;
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
				//ShowActivity2(client, "\x05[SM]\x01 ","%N was \x05resized\x01!", client);
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
				//ShowActivity2(client, "\x05[SM]\x01 ", "%N \x05resized\x01 %t!", client, sTargetName);
			}
			else
			{
				//ShowActivity2(client, "\x05[SM]\x01 ", "%N \x05resized\x01 %s!", client, sTargetName);
			}
			
			new Float:fScale = 0.0;
			if (args == 2)
			{
				decl String:sScale[128];
				GetCmdArg(2, sScale, sizeof(sScale));
				if ((fScale = StringToFloat(sScale)) <= 0.0)
				{
					fScale = 1.0;
				}
			}
			
			for (new i = 0; i < target_count; i++)
			{
				if (iTargetList[i] != 0)
				{
					ResizePlayer(iTargetList[i], fScale);
				}
			}
		}
	}
	return Plugin_Handled;
}

ShowResizeMenu(client)
{
	new Handle:hMenu = CreateMenu(ResizeMenuHandler);
	SetMenuTitle(hMenu, "Choose a size:");
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
			//ShowActivity2(param1, "\x05[SM]\x01 ","%N was \x05resized\x01!", param1);
		}
	}
}

public ConVarEnabledChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
	g_bEnabled = (StringToInt(newvalue) == 0 ? false : true);
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if (g_bEnabled && (g_iJoinStatus == 1 || (g_iJoinStatus == 2 && CheckCommandAccess(i, "sm_resize", ADMFLAG_CHEATS))))
			{
				ResizePlayer(i, g_fDefaultScale);
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

public ConVarDamageChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])
{	
	g_bDamage = (StringToInt(newvalue) == 0 ? false : true);
}

public ConVarMenuChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])
{	
	g_bMenu = (StringToInt(newvalue) == 0 ? false : true);
}

public OnClientPutInServer(client)
{
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (g_bEnabled && g_bDamage && attacker > 0 && attacker <= MaxClients)
	{
		if (IsValidEdict(inflictor))
		{
			new String:sClassName[64];
			GetEdictClassname(inflictor, sClassName, sizeof(sClassName));
			//Remove if/when buildings are added
			if (strcmp(sClassName, "obj_sentrygun") != 0)
			{
				damage *= g_fClientCurrentScale[attacker];
				return Plugin_Changed;
			}
		}
	}
	return Plugin_Continue;
}

public OnClientPostAdminCheck(client)
{
	if (g_iJoinStatus == 1 || (g_iJoinStatus == 2 && CheckCommandAccess(client, "sm_resize", ADMFLAG_CHEATS)))
	{	
		ResizePlayer(client, g_fDefaultScale);
	}
}

public Action:SoundCallback(clients[64], &numClients, String:sSample[PLATFORM_MAX_PATH], &entity, &iChannel, &Float:fVolume, &iLevel, &iPitch, &iFlags)
{
	if (g_bEnabled && g_iVoicesChanged > 0)
	{
		if (entity > 0 && entity <= MaxClients && iChannel == SNDCHAN_VOICE)
		{
			new iOldPitch = iPitch;
			//Next expression is (175/(1+6x)+75) so results stay between 75 and 250 with 100 pitch at normal size.
			iPitch = RoundToNearest((175 / (1 + (6 * g_fClientCurrentScale[entity]))) + 75);
			if ((g_iVoicesChanged == 2  && iPitch < 100) || (g_iVoicesChanged == 3  && iPitch > 100))
			{
				iPitch = iOldPitch;
			}
			iFlags |= SND_CHANGEPITCH;
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

public OnClientDisconnect_Post(client)
{
	g_fClientLastScale[client] = g_fDefaultScale;
}

public OnPluginEnd()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			ResizePlayer(i, 1.0);
		}
	}
}