#pragma semicolon 1

// ====[ INCLUDES ]============================================================
#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <adminmenu>

// ====[ DEFINES ]=============================================================
#define PLUGIN_VERSION "1.3"

// ====[ HANDLES | CVARS ]=====================================================
new Handle:g_hCvarEnabled;
new Handle:g_hCvarAlpha;
new Handle:g_hAdminMenu;

// ====[ VARIABLES ]===========================================================
new g_iAlpha;
new bool:g_bEnabled;
new bool:g_bGameTF2;
new bool:g_bAlpha[MAXPLAYERS + 1];

// ====[ PLUGIN ]==============================================================
public Plugin:myinfo =
{
	name = "Alpha Extended",
	author = "ReFlexPoison",
	description = "Make players transparent",
	version = PLUGIN_VERSION,
	url = "http//www.sourcemod.net/"
}

// ====[ EVENTS ]==============================================================
public OnPluginStart()
{
	new Handle:hTopMenu;
	if(LibraryExists("adminmenu") && ((hTopMenu = GetAdminTopMenu()) != INVALID_HANDLE))
		OnAdminMenuReady(hTopMenu);

	decl String:strGame[64];
	GetGameFolderName(strGame, sizeof(strGame));
	g_bGameTF2 = StrEqual(strGame, "tf");

	CreateConVar("sm_alpha_version", PLUGIN_VERSION, "Alpha Extended Version", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);

	g_hCvarEnabled = CreateConVar("sm_alpha_enabled", "1", "Enable Alpha Extended\n0 = Disabled\n1 = Enabled", _, true, 0.0, true, 1.0);
	g_bEnabled = GetConVarBool(g_hCvarEnabled);
	HookConVarChange(g_hCvarEnabled, OnConVarChange);

	g_hCvarAlpha = CreateConVar("sm_alpha_value", "55", "Alpha value\n0 = Invisible\n255 = Normal", _, true, 0.0, true, 255.0);
	g_iAlpha = GetConVarInt(g_hCvarAlpha);
	HookConVarChange(g_hCvarAlpha, OnConVarChange);

	RegAdminCmd("sm_alpha", AlphaCmd, 0);

	if(g_bGameTF2)
		HookEvent("post_inventory_application", OnPlayerSpawn);
	else
		HookEvent("player_spawn", OnPlayerSpawn);

	LoadTranslations("core.phrases");
	LoadTranslations("common.phrases");
	LoadTranslations("alpha.phrases");
}

public OnConVarChange(Handle:hConvar, const String:strOldValue[], const String:strNewValue[])
{
	if(hConvar == g_hCvarEnabled)
		g_bEnabled = GetConVarBool(g_hCvarEnabled);
	if(hConvar == g_hCvarAlpha)
		g_iAlpha = GetConVarInt(g_hCvarAlpha);
}

public OnClientConnected(iClient)
{
	g_bAlpha[iClient] = false;
}

public OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(event, "userid"));
	if(g_bEnabled && g_bAlpha[iClient])
		Alpha(iClient, true);
	else
		Alpha(iClient, false);
}

// ====[ COMMANDS ]============================================================
public Action:AlphaCmd(iClient, iArgs)
{
	if(!g_bEnabled)
		return Plugin_Continue;

	if(iArgs == 0)
	{
		if(iClient == 0)
		{
			ReplyToCommand(iClient, "Usage: sm_alpha <#userid|name> <1/0>");
			return Plugin_Handled;
		}

		if(!g_bAlpha[iClient])
		{
			Alpha(iClient, true);
			g_bAlpha[iClient] = true;

			SetGlobalTransTarget(iClient);
			PrintToChat(iClient, "[SM] %t.", "Transparent");
			LogAction(iClient, iClient, "\"%L\" added transparency to \"%L\"", iClient, iClient);
		}
		else
		{
			Alpha(iClient, false);
			g_bAlpha[iClient] = false;

			SetGlobalTransTarget(iClient);
			PrintToChat(iClient, "[SM] %t.", "Visible");
			LogAction(iClient, iClient, "\"%L\" removed transparency from \"%L\"", iClient, iClient);
		}
		return Plugin_Handled;
	}
	if(iArgs == 1)
	{
		if(!CheckCommandAccess(iClient, "sm_alpha_target", ADMFLAG_GENERIC))
		{
			SetGlobalTransTarget(iClient);
			ReplyToCommand(iClient, "[SM] %t.", "No Access");
			return Plugin_Handled;
		}
		ReplyToCommand(iClient, "[SM] Usage: sm_alpha <#userid|name> <1/0>");
		return Plugin_Handled;
	}
	if(iArgs == 2)
	{
		if(!CheckCommandAccess(iClient, "sm_alpha_target", ADMFLAG_GENERIC))
		{
			SetGlobalTransTarget(iClient);
			ReplyToCommand(iClient, "[SM] %t.", "No Access");
			return Plugin_Handled;
		}

		decl String:strArg1[32];
		decl String:strArg2[32];
		GetCmdArg(1, strArg1, sizeof(strArg1));
		GetCmdArg(2, strArg2, sizeof(strArg2));

		new iToggle = StringToInt(strArg2);
		if(iToggle == 0 && !StrEqual(strArg2, "0") || (iToggle != 0 && iToggle != 1))
		{
			ReplyToCommand(iClient, "[SM] Usage: sm_alpha <#userid|name> <1/0>");
			return Plugin_Handled;
		}

		new String:strTargetName[MAX_TARGET_LENGTH];
		new iTargetList[MAXPLAYERS];
		new iTargetCount;
		new bool:bTnIsMl;
		if((iTargetCount = ProcessTargetString(strArg1, iClient, iTargetList, MAXPLAYERS, COMMAND_FILTER_ALIVE, strTargetName, sizeof(strTargetName), bTnIsMl)) <= 0)
		{
			ReplyToTargetError(iClient, iTargetCount);
			return Plugin_Handled;
		}

		if(iToggle == 0)
		{
			for(new i = 0; i < iTargetCount; i++) if(IsValidClient(iTargetList[i]))
			{
				Alpha(iTargetList[i], false);
				g_bAlpha[iTargetList[i]] = false;

				SetGlobalTransTarget(iTargetList[i]);
				PrintToChat(iTargetList[i], "[SM] %t.", "Visible");
				LogAction(iClient, iTargetList[i], "\"%L\" removed transparency from \"%L\"", iClient, iTargetList[i]);
			}
			ShowActivity2(iClient, "[SM] ", "%t.", "Made Visible", strTargetName);
		}
		if(iToggle == 1)
		{
			for(new i = 0; i < iTargetCount; i++) if(IsValidClient(iTargetList[i]))
			{
				Alpha(iTargetList[i], true);
				g_bAlpha[iTargetList[i]] = true;

				SetGlobalTransTarget(iTargetList[i]);
				PrintToChat(iTargetList[i], "[SM] %t.", "Transparent");
				LogAction(iClient, iTargetList[i], "\"%L\" added transparency to \"%L\"", iClient, iTargetList[i]);
			}
			ShowActivity2(iClient, "[SM] ", "%t.", "Made Transparent", strTargetName);
		}
	}
	return Plugin_Handled;
}

public OnLibraryRemoved(const String:strName[])
{
	if(StrEqual(strName, "adminmenu"))
		g_hAdminMenu = INVALID_HANDLE;
}

public OnAdminMenuReady(Handle:hTopMenu)
{
	if(hTopMenu == g_hAdminMenu)
		return;

	g_hAdminMenu = hTopMenu;
	new TopMenuObject:iPlayerCommands = FindTopMenuCategory(g_hAdminMenu, ADMINMENU_PLAYERCOMMANDS);
	if(iPlayerCommands != INVALID_TOPMENUOBJECT)
		AddToTopMenu(g_hAdminMenu, "sm_alpha", TopMenuObject_Item, AdminMenu_Alpha, iPlayerCommands, "sm_alpha_target", ADMFLAG_GENERIC);
}

// ====[ MENUS ]===============================================================
public AdminMenu_Alpha(Handle:hTopMenu, TopMenuAction:iAction, TopMenuObject:iObjectId, iParam, String:strBuffer[], iMaxLength)
{
	if(iAction == TopMenuAction_DisplayOption)
	{
		SetGlobalTransTarget(iParam);
		Format(strBuffer, iMaxLength, "%t", "Alpha player");
	}
	else if(iAction == TopMenuAction_SelectOption)
		DisplayAlphaMenu(iParam);
}

public DisplayAlphaMenu(iClient)
{
	if(!g_bEnabled || IsVoteInProgress() || IsClientInKickQueue(iClient))
		return;

	new Handle:hMenu = CreateMenu(MenuHandler_Alpha);
	SetGlobalTransTarget(iClient);
	SetMenuTitle(hMenu, "%t:", "Alpha Player");
	SetMenuExitBackButton(hMenu, true);

	AddTargetsToMenu(hMenu, iClient);
	DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}

public MenuHandler_Alpha(Handle:hMenu, MenuAction:iAction, iParam1, iParam2)
{
	if(iAction == MenuAction_End)
	{
		CloseHandle(hMenu);
		return;
	}

	if(iAction == MenuAction_Cancel)
	{
		if(iParam2 == MenuCancel_ExitBack && g_hAdminMenu != INVALID_HANDLE)
			DisplayTopMenu(g_hAdminMenu, iParam1, TopMenuPosition_LastCategory);
	}

	if(iAction == MenuAction_Select)
	{
		decl String:strInfo[32];
		GetMenuItem(hMenu, iParam2, strInfo, sizeof(strInfo));
		new iTarget = GetClientOfUserId(StringToInt(strInfo));
		if(!IsValidClient(iTarget))
		{
			SetGlobalTransTarget(iParam1);
			PrintToChat(iParam1, "[SM] %t", "Player no longer available");
			return;
		}

		if(!CanUserTarget(iParam1, iTarget))
		{
			SetGlobalTransTarget(iParam1);
			PrintToChat(iParam1, "[SM] %t", "Unable to target");
			return;
		}

		decl String:strName[MAX_NAME_LENGTH];
		GetClientName(iTarget, strName, sizeof(strName));
		if(!g_bAlpha[iTarget])
		{
			Alpha(iTarget, true);
			g_bAlpha[iTarget] = true;

			SetGlobalTransTarget(iTarget);
			PrintToChat(iTarget, "[SM] %t.", "Transparent");
			LogAction(iParam1, iTarget, "\"%L\" added transparency to \"%L\"", iParam1, iTarget);

			ShowActivity2(iParam1, "[SM] ", "%t.", "Made Transparent", strName);
		}
		else
		{
			Alpha(iTarget, false);
			g_bAlpha[iTarget] = false;

			SetGlobalTransTarget(iTarget);
			PrintToChat(iTarget, "[SM] %t.", "Visible");
			LogAction(iParam1, iTarget, "\"%L\" remove transparency from \"%L\"", iParam1, iTarget);

			ShowActivity2(iParam1, "[SM] ", "%t.", "Made Visible", strName);
		}
		DisplayAlphaMenu(iParam1);
	}
}

// ====[ STOCKS ]==============================================================
stock bool:IsValidClient(iClient, bool:bReplay = true)
{
	if(iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient))
		return false;
	if(bReplay && (IsClientSourceTV(iClient) || IsClientReplay(iClient)))
		return false;
	return true;
}

stock bool:IsValidEntityEx(iEntity)
{
	if(iEntity <= MaxClients || !IsValidEntity(iEntity))
		return false;
	return true;
}

stock Alpha(iClient, bool:bAdd)
{
	if(bAdd)
	{
		SetEntityRenderMode(iClient, RENDER_TRANSALPHA);
		SetEntityRenderColor(iClient, _, _, _, g_iAlpha);

		for(new i = 0; i <= 5 ; i++)
		{
			new iWeapon = GetPlayerWeaponSlot(iClient, i);
			if(IsValidEntityEx(iWeapon))
			{
				SetEntityRenderMode(iWeapon, RENDER_TRANSALPHA);
				SetEntityRenderColor(iWeapon, _, _, _, g_iAlpha);
			}
		}

		if(g_bGameTF2)
		{
			new iEntity = -1;
			while((iEntity = FindEntityByClassname(iEntity, "tf_wearable")) != -1)
			{
				if(IsValidEntityEx(iEntity) && GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity") == iClient)
				{
					SetEntityRenderMode(iEntity, RENDER_TRANSALPHA);
					SetEntityRenderColor(iEntity, _, _, _, g_iAlpha);
				}
			}
			while((iEntity = FindEntityByClassname(iEntity, "tf_wearable_demoshield")) != -1)
			{
				if(IsValidEntityEx(iEntity) && GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity") == iClient)
				{
					SetEntityRenderMode(iEntity, RENDER_TRANSALPHA);
					SetEntityRenderColor(iEntity, _, _, _, g_iAlpha);
				}
			}
			while((iEntity = FindEntityByClassname(iEntity, "tf_wearable_robot_arm")) != -1)
			{
				if(IsValidEntityEx(iEntity) && GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity") == iClient)
				{
					SetEntityRenderMode(iEntity, RENDER_TRANSALPHA);
					SetEntityRenderColor(iEntity, _, _, _, g_iAlpha);
				}
			}
			while((iEntity = FindEntityByClassname(iEntity, "tf_powerup_bottle")) != -1)
			{
				if(IsValidEntityEx(iEntity) && GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity") == iClient)
				{
					SetEntityRenderMode(iEntity, RENDER_TRANSALPHA);
					SetEntityRenderColor(iEntity, _, _, _, g_iAlpha);
				}
			}
		}
	}
	else
	{
		SetEntityRenderMode(iClient, RENDER_NORMAL);

		for(new i = 0; i <= 5 ; i++)
		{
			new iWeapon = GetPlayerWeaponSlot(iClient, i);
			if(IsValidEntityEx(iWeapon))
				SetEntityRenderMode(iWeapon, RENDER_NORMAL);
		}

		if(g_bGameTF2)
		{
			new iEntity = -1;
			while((iEntity = FindEntityByClassname(iEntity, "tf_wearable")) != -1)
			{
				if(IsValidEntityEx(iEntity) && GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity") == iClient)
					SetEntityRenderMode(iEntity, RENDER_NORMAL);
			}
			while((iEntity = FindEntityByClassname(iEntity, "tf_wearable_demoshield")) != -1)
			{
				if(IsValidEntityEx(iEntity) && GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity") == iClient)
					SetEntityRenderMode(iEntity, RENDER_NORMAL);
			}
			while((iEntity = FindEntityByClassname(iEntity, "tf_wearable_robot_arm")) != -1)
			{
				if(IsValidEntityEx(iEntity) && GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity") == iClient)
					SetEntityRenderMode(iEntity, RENDER_NORMAL);
			}
			while((iEntity = FindEntityByClassname(iEntity, "tf_powerup_bottle")) != -1)
			{
				if(IsValidEntityEx(iEntity) && GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity") == iClient)
					SetEntityRenderMode(iEntity, RENDER_NORMAL);
			}
		}
	}
}