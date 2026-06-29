//////////////////////////////////////////////
//
// SourceMod Script
//
// [DoD TMS] Addon - SecretSpectate
//
// Developed by FeuerSturm
//
//////////////////////////////////////////////
#include <sourcemod>
#include <sdktools>
#include <dodtms_base>
#undef REQUIRE_PLUGIN
#include <adminmenu>

public Plugin:myinfo = 
{
	name = "[DoD TMS] Addon - Secret Spectate",
	author = "FeuerSturm, modif Micmacx",
	description = "Addon - Secret Spectate for [DoD TMS]",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net"
}

new	Handle:SMRootMenu = INVALID_HANDLE
new TopMenuObject:DoDTMSMenu = INVALID_TOPMENUOBJECT
new g_secretspec[MAXPLAYERS+1], g_secretoldteam[MAXPLAYERS+1]
new g_TeamOffset, g_AliveOffset, g_Scoreboard, g_InSecretSpectate

public OnPluginStart()
{
	HookEvent("player_team", Surpress_TeamMSG, EventHookMode_Pre)
	LoadTranslations("dodtms_secretspectate.txt")
	g_TeamOffset = FindSendPropInfo("CPlayerResource", "m_iTeam")
	g_AliveOffset = FindSendPropInfo("CPlayerResource", "m_bAlive")
}

public OnClientPutInServer(client)
{
	if(g_InSecretSpectate == client)
	{
		ResetSecretSpectate(client)
	}
}

public OnClientDisconnect(client)
{
	if(g_InSecretSpectate == client)
	{
		ResetSecretSpectate(client)
	}
}

public OnMapStart()
{
	g_Scoreboard = FindEntityByClassname(-1,"dod_player_manager")
	g_InSecretSpectate = 0
}

public OnMapEnd()
{
	g_InSecretSpectate = 0
}

public OnAllPluginsLoaded()
{
	CreateTimer(0.7, DoDTMSRunning)
}

public Action:DoDTMSRunning(Handle:timer)
{
	if(!LibraryExists("DoDTeamManagerSource"))
	{
		SetFailState("[DoD TMS] Base Plugin not found!")
		return Plugin_Handled
	}
	TMSRegAddon("G")
	return Plugin_Handled
}

public OnLibraryRemoved(const String:name[])
{
	if(StrEqual(name, "adminmenu"))
	{
		SMRootMenu = INVALID_HANDLE
	}
}

public OnDoDTMSMenuReady(Handle:SourceModMenu)
{	
	if(SourceModMenu == SMRootMenu )
	{
		return
	}
	SMRootMenu = SourceModMenu
	DoDTMSMenu = FindTopMenuCategory(SMRootMenu, "dod_tms_menu")	
	if(DoDTMSMenu == INVALID_TOPMENUOBJECT)
	{
		return
	}
	AddToTopMenu(SMRootMenu, "TMSSecretSpectate", TopMenuObject_Item, Handle_TMSSecretSpectate, DoDTMSMenu, "TMSSecretSpectate", ADMFLAG_BAN)
}

public Handle_TMSSecretSpectate(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if(action == TopMenuAction_DisplayOption)
	{
		decl String:servercmds[256]
		Format(servercmds, sizeof(servercmds), "%t", "SecretSpecMenu")
		Format(buffer, maxlength, servercmds)
	}
	else if(action == TopMenuAction_SelectOption)
	{
		ShowSecretSpecCmds(param)
	}
}

ShowSecretSpecCmds(client)
{
	new Handle:DoDTMSSecretSpectate = INVALID_HANDLE
	DoDTMSSecretSpectate = CreateMenu(Handle_SecretSpectate)
	decl String:sspeccmds[256]
	Format(sspeccmds, sizeof(sspeccmds), "[DoD TMS] %T", "SecretSpecMenu Title", client)
	SetMenuTitle(DoDTMSSecretSpectate, sspeccmds)
	decl String:menuitem[256]
	Format(menuitem, sizeof(menuitem), "%T", "GoSecretSpec Item", client)
	if(g_InSecretSpectate != 0)
	{
		AddMenuItem(DoDTMSSecretSpectate, "dod_tms_gosspec", menuitem, ITEMDRAW_DISABLED)
	}
	else
	{
		AddMenuItem(DoDTMSSecretSpectate, "dod_tms_gosspec", menuitem)
	}
	Format(menuitem, sizeof(menuitem), "%T", "LeaveSecretSpec Item", client)
	if(g_InSecretSpectate == 0 || g_InSecretSpectate != client)
	{
		AddMenuItem(DoDTMSSecretSpectate, "dod_tms_leavesspec", menuitem, ITEMDRAW_DISABLED)
	}
	else
	{
		AddMenuItem(DoDTMSSecretSpectate, "dod_tms_leavesspec", menuitem)
	}
	SetMenuExitBackButton(DoDTMSSecretSpectate, true)
	SetMenuExitButton(DoDTMSSecretSpectate, true)
	DisplayMenu(DoDTMSSecretSpectate, client, MENU_TIME_FOREVER)
}

public Handle_SecretSpectate(Handle:DoDTMSSecretSpectate, MenuAction:action, client, itemNum)
{
	if(client < 1)
	{
		return
	}
	if(action == MenuAction_Select)
	{
		SecretSpectate(client, 0)
		ShowSecretSpecCmds(client)
	}
	else if(action == MenuAction_Cancel)
	{
		if(itemNum == MenuCancel_ExitBack)
		{
			if(GetClientMenu(client))
			{
				CancelClientMenu(client)
			}			
			DisplayTopMenu(SMRootMenu, client, TopMenuPosition_LastCategory)
		}
	}
}

public Action:Surpress_TeamMSG(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	if(g_secretspec[client] == 1 && g_InSecretSpectate == client)
	{
		new team = GetEventInt(event, "team")
		if(team != SPEC)
		{
			ResetSecretSpectate(client)
		}
		dontBroadcast = true
		return Plugin_Changed
	}
	return Plugin_Continue
}

public Action:SecretSpectate(client, args)
{
	decl String:message[256]
	new currteam = GetClientTeam(client)
	if(currteam == ALLIES || currteam == AXIS)
	{
		g_TeamOffset = g_TeamOffset + (client * 4)
		g_AliveOffset = g_AliveOffset + (client * 4)
		g_secretoldteam[client] = currteam
		g_secretspec[client] = 1
		g_InSecretSpectate = client
		ChangeClientTeam(client,SPEC)
		Format(message, sizeof(message), "%T", "SecretSpec On", client)
		TMSMessage(client,message)
		return Plugin_Handled
	}
	else if(currteam == SPEC)
	{
		ChangeClientTeam(client,g_secretoldteam[client])
		Format(message, sizeof(message), "%T", "SecretSpec Off", client)
		TMSMessage(client,message)
		return Plugin_Handled
	}
	return Plugin_Handled
}

public Action:ResetSecretSpectate(client)
{
	g_secretspec[client] = 0
	g_InSecretSpectate = 0
	g_TeamOffset = FindSendPropInfo("CPlayerResource", "m_iTeam")
	g_AliveOffset = FindSendPropInfo("CPlayerResource", "m_bAlive")
	return Plugin_Handled
}

public OnGameFrame()
{
	if(g_InSecretSpectate != 0 && IsValidEntity(g_InSecretSpectate) && IsClientInGame(g_InSecretSpectate) && g_secretspec[g_InSecretSpectate] == 1)
	{
		SetEntData(g_Scoreboard, g_TeamOffset, g_secretoldteam[g_InSecretSpectate], 4, true)
		SetEntData(g_Scoreboard, g_AliveOffset, true, 4, true)
	}
}