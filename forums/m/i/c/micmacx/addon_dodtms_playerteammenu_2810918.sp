//////////////////////////////////////////////
//
// SourceMod Script
//
// [DoD TMS] Addon - Player / Team Commands Menu
//
// Developed by FeuerSturm
//
//////////////////////////////////////////////
#include <sourcemod>
#include <sdktools>
#include <dodtms_base>
#include <dodtms_plteamaccess>

#undef REQUIRE_PLUGIN
#include <adminmenu>

#define TMS_PlayerCommands 1
#define TMS_TeamCommands 2
#define TMS_PlayerSwapAllies 1
#define TMS_PlayerSwapAxis 2
#define TMS_PlayerSpec 3
#define TMS_PlayerEncourage 4
#define TMS_PlayerSlay 5

#define PLAYERCMD_ACCESS		ADMFLAG_GENERIC
#define TEAMCMD_ACCESS			ADMFLAG_GENERIC

public Plugin:myinfo = 
{
	name = "[DoD TMS] Addon - Player / Team Commands",
	author = "FeuerSturm, modif Micmacx",
	description = "Addon - Player / Team Commands for [DoD TMS]",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net"
}

new Handle:SlayFX = INVALID_HANDLE
new Handle:AnonymousAdmin = INVALID_HANDLE
new Handle:ClientImmunity = INVALID_HANDLE
new Handle:AdminAllowSelf = INVALID_HANDLE
new	Handle:SMRootMenu = INVALID_HANDLE
new TopMenuObject:DoDTMSMenu = INVALID_TOPMENUOBJECT
new String:TeamName[5][] = {"DISABLED", "Spectators", "U.S. Army", "Wehrmacht", "U.S. Army & Wehrmacht"}
new String:Encourage[4][] = {"", "", "player/american/us_gogogo.wav", "player/german/ger_gogogo2.wav"}
new g_adminteam = UNASSIGNED
new g_MenuPos[MAXPLAYERS+1]
new String:WLFeature[] = { "playerteammenu" }
new bool:IsWhiteListed[MAXPLAYERS+1]
new bool:IsBlackListed[MAXPLAYERS+1]

public OnPluginStart()
{
	SlayFX = CreateConVar("dod_tms_ptmenuslayfx", "1", "<1/0> = enable/disable explosion sound/effects for slaying players", _, true, 0.0, true, 1.0)
	AnonymousAdmin = CreateConVar("dod_tms_ptmenuanonymousadmin", "0", "<1/0> = enable/disable displaying admin names when performing actions", _, true, 0.0, true, 1.0)
	ClientImmunity = CreateConVar("dod_tms_ptmenuimmunity", "1", "<1/0> = enable/disable Admins being immune from almost all player directed actions",_, true, 0.0, true, 1.0)
	AdminAllowSelf = CreateConVar("dod_tms_ptmenuallowselfaction", "1", "<1/0> = enable/disable immune Admins being able to perform self-actions",_, true, 0.0, true, 1.0)
	AutoExecConfig(true,"addon_dodtms_playerteammenu", "dod_teammanager_source")
	LoadTranslations("dod_teammanager_source.txt")
	LoadTranslations("dodtms_playerteammenu.txt")
}

public OnAllPluginsLoaded()
{
	CreateTimer(0.6, DoDTMSRunning)
}

public OnClientPostAdminCheck(client)
{
	if(GetClientMenu(client))
	{
		CancelClientMenu(client)
	}
	if(TMSIsWhiteListed(client, WLFeature))
	{
		IsWhiteListed[client] = true
	}
	else
	{
		IsWhiteListed[client] = false
	}
	if(TMSIsBlackListed(client, WLFeature))
	{
		IsBlackListed[client] = true
	}
	else
	{
		IsBlackListed[client] = false
	}
}

public OnClientDisconnect(client)
{
	if(GetClientMenu(client))
	{
		CancelClientMenu(client)
	}
}

public Action:DoDTMSRunning(Handle:timer)
{
	if(!LibraryExists("DoDTeamManagerSource"))
	{
		SetFailState("[DoD TMS] Base Plugin not found!")
		return Plugin_Handled
	}
	TMSRegAddon("F")
	return Plugin_Handled
}

public OnDoDTMSDeleteCfg()
{
	decl String:configfile[256]
	Format(configfile, sizeof(configfile), "cfg/dod_teammanager_source/addon_dodtms_playerteammenu.cfg")
	if(FileExists(configfile))
	{
		DeleteFile(configfile)
	}
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
	AddToTopMenu(SMRootMenu, "TMSPlayerCommands", TopMenuObject_Item, Handle_TMSPlayerCommands, DoDTMSMenu, "TMSPlayerCommands", PLAYERCMD_ACCESS)
	AddToTopMenu(SMRootMenu, "TMSTeamCommands", TopMenuObject_Item, Handle_TMSTeamCommands, DoDTMSMenu, "TMSTeamCommands", TEAMCMD_ACCESS)
}

public Handle_TMSPlayerCommands(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, client, String:buffer[], maxlength)
{
	if(client < 1)
	{
		return
	}
	if(action == TopMenuAction_DisplayOption)
	{
		decl String:playercmds[256]
		Format(playercmds, sizeof(playercmds), "%T", "PlayerCmdMenu", client)
		Format( buffer, maxlength, playercmds)
	}
	else if( action == TopMenuAction_SelectOption)
	{
		if(GetClientMenu(client))
		{
			CancelClientMenu(client)
		}
		ShowDoDTMSCmds(client, TMS_PlayerCommands)
	}
}

public Handle_TMSTeamCommands(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, client, String:buffer[], maxlength)
{
	if(client < 1)
	{
		return
	}
	if(action == TopMenuAction_DisplayOption)
	{
		decl String:teamcmds[256]
		Format(teamcmds, sizeof(teamcmds), "%T", "TeamCmdMenu", client)
		Format(buffer, maxlength, teamcmds)
	}
	else if( action == TopMenuAction_SelectOption)
	{
		if(GetClientMenu(client))
		{
			CancelClientMenu(client)
		}		
		ShowDoDTMSCmds(client, TMS_TeamCommands)
	}
}

ShowDoDTMSCmds(client, SubMenu)
{
	if(client < 1)
	{
		return
	}
	new AdminId:admin = GetUserAdmin(client)
	new Handle:DoDTMSCmdMenu = INVALID_HANDLE
	if(SubMenu == TMS_PlayerCommands)
	{
		DoDTMSCmdMenu = CreateMenu(Handle_PlayerCommands)
		decl String:playercmds[256]
		Format(playercmds, sizeof(playercmds), "[DoD TMS] %T", "PlayerCmdMenu Title", client)
		SetMenuTitle(DoDTMSCmdMenu, playercmds)
		decl String:playermenuitem[256]
		Format(playermenuitem, sizeof(playermenuitem), "%T", "SwapToAllies", client)
		AddMenuItem(DoDTMSCmdMenu, "dod_tms_playerallies", playermenuitem, GetAdminFlag(admin, SWAPALLIESPL_ACCESS, Access_Effective) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED)
		Format(playermenuitem, sizeof(playermenuitem), "%T", "SwapToAxis", client)
		AddMenuItem(DoDTMSCmdMenu, "dod_tms_playeraxis", playermenuitem, GetAdminFlag(admin, SWAPAXISPL_ACCESS, Access_Effective) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED)
		Format(playermenuitem, sizeof(playermenuitem), "%T", "SwapToSpec", client)
		AddMenuItem(DoDTMSCmdMenu, "dod_tms_playerspec", playermenuitem, GetAdminFlag(admin, SWAPSPECPL_ACCESS, Access_Effective) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED)
		Format(playermenuitem, sizeof(playermenuitem), "%T", "Encourage Player", client)
		AddMenuItem(DoDTMSCmdMenu, "dod_tms_encourageplayer", playermenuitem, GetAdminFlag(admin, ENCOURAGEPL_ACCESS, Access_Effective) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED)
		Format(playermenuitem, sizeof(playermenuitem), "%T", "Slay Player", client)
		AddMenuItem(DoDTMSCmdMenu, "dod_tms_slayplayer", playermenuitem, GetAdminFlag(admin, SLAYPL_ACCESS, Access_Effective) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED)
	}
	else if(SubMenu == TMS_TeamCommands)
	{
		DoDTMSCmdMenu = CreateMenu(Handle_TeamCommands)
		decl String:teamcmds[256]
		Format(teamcmds, sizeof(teamcmds), "[DoD TMS] %T", "TeamCmdMenu Title", client)
		SetMenuTitle(DoDTMSCmdMenu, teamcmds)
		decl String:teammenuitem[256]
		Format(teammenuitem, sizeof(teammenuitem), "%T", "SwapTeamsItem", client)
		AddMenuItem(DoDTMSCmdMenu, "dod_tms_swapteams", teammenuitem, GetAdminFlag(admin, SWAPTEAMS_ACCESS, Access_Effective) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED)
		Format(teammenuitem, sizeof(teammenuitem), "%T", "MixTeamsItem", client)
		AddMenuItem(DoDTMSCmdMenu, "dod_tms_mixteams", teammenuitem, GetAdminFlag(admin, MIXTEAMS_ACCESS, Access_Effective) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED)
		Format(teammenuitem, sizeof(teammenuitem), "%T", "EncourageTeamsItem", client)
		AddMenuItem(DoDTMSCmdMenu, "dod_tms_encourage", teammenuitem, GetAdminFlag(admin, ENCOURAGETEAM_ACCESS, Access_Effective) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED)
		Format(teammenuitem, sizeof(teammenuitem), "%T", "AdminsvsPublicItem", client)
		AddMenuItem(DoDTMSCmdMenu, "dod_tms_adminteam", teammenuitem, GetAdminFlag(admin, ADMINTEAM_ACCESS, Access_Effective) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED)
	}
	SetMenuExitBackButton(DoDTMSCmdMenu, true)
	SetMenuExitButton(DoDTMSCmdMenu, true)
	DisplayMenu(DoDTMSCmdMenu, client, MENU_TIME_FOREVER)
}

public Handle_PlayerCommands(Handle:DoDTMSCmdMenu, MenuAction:action, client, itemNum)
{
	if(client < 1)
	{
		return
	}
	if(action == MenuAction_Select)
	{
		decl String:MenuChoice[256]
		GetMenuItem(DoDTMSCmdMenu, itemNum, MenuChoice, sizeof(MenuChoice))
		if(strcmp(MenuChoice, "dod_tms_playerallies", true) == 0)
		{
			PlayerListMenu(client, TMS_PlayerSwapAllies)
		}
		else if(strcmp(MenuChoice, "dod_tms_playeraxis", true) == 0)
		{
			PlayerListMenu(client, TMS_PlayerSwapAxis)
		}
		else if(strcmp(MenuChoice, "dod_tms_playerspec", true) == 0)
		{
			PlayerListMenu(client, TMS_PlayerSpec)
		}
		else if(strcmp(MenuChoice, "dod_tms_encourageplayer", true) == 0)
		{
			PlayerListMenu(client, TMS_PlayerEncourage)
		}
		else if(strcmp(MenuChoice, "dod_tms_slayplayer", true) == 0)
		{
			PlayerListMenu(client, TMS_PlayerSlay)
		}
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

public Handle_TeamCommands(Handle:DoDTMSCmdMenu, MenuAction:action, client, itemNum)
{
	if(client < 1)
	{
		return
	}
	if(action == MenuAction_Select)
	{
		decl String:MenuChoice[256]
		GetMenuItem(DoDTMSCmdMenu, itemNum, MenuChoice, sizeof(MenuChoice))
		if(strcmp(MenuChoice, "dod_tms_swapteams", true) == 0)
		{
			TMSSwapTeams()
			decl String:message[256]
			for(new i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i))
				{
					Format(message, sizeof(message), "%T", "Admin TeamSwap", i, client)
					if(GetConVarInt(AnonymousAdmin) == 1)
					{
						decl String:AdminName[32]
						GetClientName(client, AdminName, sizeof(AdminName))
						Format(AdminName, sizeof(AdminName), "%s ", AdminName)
						ReplaceStringEx(message, sizeof(message), AdminName, "")
					}
					TMSMessage(i, message)
				}
			}
			ShowDoDTMSCmds(client, TMS_TeamCommands)
			return
		}
		else if(strcmp(MenuChoice, "dod_tms_mixteams", true) == 0)
		{
			decl String:message[256]
			TMSMixTeams()
			for(new i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i))
				{
					Format(message, sizeof(message), "%T", "Admin MixTeams Success", i, client)
					if(GetConVarInt(AnonymousAdmin) == 1)
					{
						decl String:AdminName[32]
						GetClientName(client, AdminName, sizeof(AdminName))
						Format(AdminName, sizeof(AdminName), "%s ", AdminName)
						ReplaceStringEx(message, sizeof(message), AdminName, "")
					}
					TMSMessage(i, message)
				}
			}
			ShowDoDTMSCmds(client, TMS_TeamCommands)
			return
		}
		if(strcmp(MenuChoice, "dod_tms_encourage", true) == 0)
		{
			EncourageTeamMenu(client)
		}
		else if(strcmp(MenuChoice, "dod_tms_adminteam", true) == 0)
		{
			AdminTeamMenu(client)
		}
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

public Action:ReopenPlayerMenu(Handle:timer, any:client)
{
	PlayerListMenu(client, g_MenuPos[client])
	return Plugin_Handled
}

EncourageTeamMenu(client)
{
	if(client < 1)
	{
		return
	}
	new Handle:EncourageT = INVALID_HANDLE
	EncourageT = CreateMenu(Handle_Encourage)
	decl String:menutitle[256]
	Format(menutitle, sizeof(menutitle), "%T", "EncourageTeam Title", client)
	SetMenuTitle(EncourageT, menutitle)
	decl String:teammenuitem[256]
	Format(teammenuitem, sizeof(teammenuitem), "%T", "EncourageAllies Item", client)
	AddMenuItem(EncourageT,"Allies", teammenuitem)
	Format(teammenuitem, sizeof(teammenuitem), "%T", "EncourageAxis Item", client)
	AddMenuItem(EncourageT,"Axis", teammenuitem)
	Format(teammenuitem, sizeof(teammenuitem), "%T", "EncourageBoth Item", client)
	AddMenuItem(EncourageT,"All", teammenuitem)
	SetMenuExitButton(EncourageT, true)
	SetMenuExitBackButton(EncourageT, true)
	DisplayMenu(EncourageT, client, MENU_TIME_FOREVER)
}

AdminTeamMenu(client)
{
	if(client < 1)
	{
		return
	}
	new Handle:AdminT = INVALID_HANDLE
	AdminT = CreateMenu(Handle_AdminTeam)
	decl String:menutitle[256]
	Format(menutitle, sizeof(menutitle), "%T", "AdminsvsPublic Title", client)
	SetMenuTitle(AdminT, menutitle)
	decl String:teammenuitem[256]
	if(g_adminteam != ALLIES)
	{
		Format(teammenuitem, sizeof(teammenuitem), "%T", "AdminTeamAllies Item", client)
		AddMenuItem(AdminT,"Allies", teammenuitem)
	}
	else
	{
		Format(teammenuitem, sizeof(teammenuitem), "%T", "AdminTeamAllies Item", client)
		AddMenuItem(AdminT,"Allies", teammenuitem, ITEMDRAW_DISABLED)
	}
	if(g_adminteam != AXIS)
	{
		Format(teammenuitem, sizeof(teammenuitem), "%T", "AdminTeamAxis Item", client)
		AddMenuItem(AdminT,"Axis", teammenuitem)
	}
	else
	{
		Format(teammenuitem, sizeof(teammenuitem), "%T", "AdminTeamAxis Item", client)
		AddMenuItem(AdminT,"Axis", teammenuitem, ITEMDRAW_DISABLED)
	}
	if(g_adminteam != UNASSIGNED)
	{
		Format(teammenuitem, sizeof(teammenuitem), "%T", "AdminTeamNone Item", client)
		AddMenuItem(AdminT,"none", teammenuitem)
	}
	else
	{
		Format(teammenuitem, sizeof(teammenuitem), "%T", "AdminTeamNone Item", client)
		AddMenuItem(AdminT,"none", teammenuitem, ITEMDRAW_DISABLED)
	}
	SetMenuExitButton(AdminT, true)
	SetMenuExitBackButton(AdminT, true)
	DisplayMenu(AdminT, client, MENU_TIME_FOREVER)
}

public Handle_Encourage(Handle:EncourageT, MenuAction:action, client, itemNum)
{
	if(client < 1)
	{
		return
	}
	if(action == MenuAction_Select)
	{
		decl String:TeamStr[256]
		new team
		GetMenuItem(EncourageT, itemNum, TeamStr, sizeof(TeamStr))
		decl String:message[256]
		if(strcmp(TeamStr, "Allies", true) == 0)
		{
			team = ALLIES
			EncourageTeam(ALLIES)
		}
		else if(strcmp(TeamStr, "Axis", true) == 0)
		{
			team = AXIS
			EncourageTeam(AXIS)
		}
		if(strcmp(TeamStr, "All", true) == 0)
		{
			team = ALL
			if(EncourageTeam(ALLIES))
			{
				EncourageTeam(AXIS)
			}
		}
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				Format(message, sizeof(message), "%T", "Admin Encourage", i, client, TeamName[team])
				if(GetConVarInt(AnonymousAdmin) == 1)
				{
					decl String:AdminName[32]
					GetClientName(client, AdminName, sizeof(AdminName))
					Format(AdminName, sizeof(AdminName), "%s ", AdminName)
					ReplaceStringEx(message, sizeof(message), AdminName, "")
				}
				TMSMessage(i, message)
			}
		}
		EncourageTeamMenu(client)
		return
	}
	else if(action == MenuAction_Cancel)
	{
		if(itemNum == MenuCancel_ExitBack)
		{
			if(GetClientMenu(client))
			{
				CancelClientMenu(client)
			}			
			ShowDoDTMSCmds(client, TMS_TeamCommands)
		}
	}
}

public Handle_AdminTeam(Handle:AdminT, MenuAction:action, client, itemNum)
{
	if(client < 1)
	{
		return
	}
	if(action == MenuAction_Select)
	{
		decl String:TeamStr[256]
		new team
		GetMenuItem(AdminT, itemNum, TeamStr, sizeof(TeamStr))
		decl String:message[256]
		if(strcmp(TeamStr, "Allies", true) == 0)
		{
			team = ALLIES
		}
		else if(strcmp(TeamStr, "Axis", true) == 0)
		{
			team = AXIS
		}
		if(strcmp(TeamStr, "All", true) == 0)
		{
			team = UNASSIGNED
		}
		g_adminteam = team
		if(TMSAdminTeam(team))
		{
			for(new i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i))
				{
					Format(message, sizeof(message), "%T", "AdminTeam Set", i, client, TeamName[team])
					if(GetConVarInt(AnonymousAdmin) == 1)
					{
						decl String:AdminName[32]
						GetClientName(client, AdminName, sizeof(AdminName))
						Format(AdminName, sizeof(AdminName), "%s ", AdminName)
						ReplaceStringEx(message, sizeof(message), AdminName, "")
					}
					TMSMessage(i, message)
				}
			}
		}
		AdminTeamMenu(client)
		return
	}
	else if(action == MenuAction_Cancel)
	{
		if(itemNum == MenuCancel_ExitBack)
		{
			if(GetClientMenu(client))
			{
				CancelClientMenu(client)
			}			
			ShowDoDTMSCmds(client, TMS_TeamCommands)
		}
	}
}

PlayerListMenu(client, Type)
{
	if(client < 1)
	{
		return
	}
	new Handle:PlayerList = INVALID_HANDLE
	new playercount = 0
	if(Type == TMS_PlayerSwapAllies)
	{
		PlayerList = CreateMenu(Handle_SwapToAllies)
		decl String:menutitle[256]
		Format(menutitle, sizeof(menutitle), "%T", "SwapToAllies Title", client)
		SetMenuTitle(PlayerList, menutitle)
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				new currteam = GetClientTeam(i)
				if(currteam != ALLIES && currteam != UNASSIGNED)
				{
					decl String:TargetName[32]
					GetClientName(i, TargetName, sizeof(TargetName))
					decl String:DisplayItem[64]
					Format(DisplayItem, sizeof(DisplayItem), "%s (%s)", TargetName, TeamName[currteam])
					new userid = GetClientUserId(i)
					decl String:userid_str[32]
					IntToString(userid, userid_str, sizeof(userid_str))
					if(!IsClientImmune(i) || (IsClientImmune(i) && GetConVarInt(AdminAllowSelf) == 1 && i == client))
					{
						AddMenuItem(PlayerList, userid_str, DisplayItem)
					}
					else
					{
						AddMenuItem(PlayerList, userid_str, DisplayItem, ITEMDRAW_DISABLED)
					}
					playercount++
				}
			}
		}
	}
	else if(Type == TMS_PlayerSwapAxis)
	{
		PlayerList = CreateMenu(Handle_SwapToAxis)
		decl String:menutitle[256]
		Format(menutitle, sizeof(menutitle), "%T", "SwapToAxis Title", client)
		SetMenuTitle(PlayerList, menutitle)
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				new currteam = GetClientTeam(i)
				if(currteam != AXIS && currteam != UNASSIGNED)
				{
					decl String:TargetName[32]
					GetClientName(i, TargetName, sizeof(TargetName))
					decl String:DisplayItem[64]
					Format(DisplayItem, sizeof(DisplayItem), "%s (%s)", TargetName, TeamName[currteam])
					new userid = GetClientUserId(i)
					decl String:userid_str[32]
					IntToString(userid, userid_str, sizeof(userid_str))
					IntToString(userid, userid_str, sizeof(userid_str))
					if(!IsClientImmune(i) || (IsClientImmune(i) && GetConVarInt(AdminAllowSelf) == 1 && i == client))
					{
						AddMenuItem(PlayerList, userid_str, DisplayItem)
					}
					else
					{
						AddMenuItem(PlayerList, userid_str, DisplayItem, ITEMDRAW_DISABLED)
					}
					playercount++
				}
			}
		}
	}
	else if(Type == TMS_PlayerSpec)
	{
		PlayerList = CreateMenu(Handle_SwapToSpec)
		decl String:menutitle[256]
		Format(menutitle, sizeof(menutitle), "%T", "SwapToSpec Title", client)
		SetMenuTitle(PlayerList, menutitle)
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				new currteam = GetClientTeam(i)
				if(currteam != UNASSIGNED && currteam != SPEC)
				{
					decl String:TargetName[32]
					GetClientName(i, TargetName, sizeof(TargetName))
					decl String:DisplayItem[64]
					Format(DisplayItem, sizeof(DisplayItem), "%s (%s)", TargetName, TeamName[currteam])
					new userid = GetClientUserId(i)
					decl String:userid_str[32]
					IntToString(userid, userid_str, sizeof(userid_str))
					IntToString(userid, userid_str, sizeof(userid_str))
					if(!IsClientImmune(i) || (IsClientImmune(i) && GetConVarInt(AdminAllowSelf) == 1 && i == client))
					{
						AddMenuItem(PlayerList, userid_str, DisplayItem)
					}
					else
					{
						AddMenuItem(PlayerList, userid_str, DisplayItem, ITEMDRAW_DISABLED)
					}
					playercount++
				}
			}
		}
	}
	else if(Type == TMS_PlayerEncourage)
	{
		PlayerList = CreateMenu(Handle_EncouragePlayer)
		decl String:menutitle[256]
		Format(menutitle, sizeof(menutitle), "%T", "EncouragePlayer Title", client)
		SetMenuTitle(PlayerList, menutitle)
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				new currteam = GetClientTeam(i)
				if(currteam != UNASSIGNED && currteam != SPEC)
				{
					decl String:TargetName[32]
					GetClientName(i, TargetName, sizeof(TargetName))
					decl String:DisplayItem[64]
					Format(DisplayItem, sizeof(DisplayItem), "%s (%s)", TargetName, TeamName[currteam])
					new userid = GetClientUserId(i)
					decl String:userid_str[32]
					IntToString(userid, userid_str, sizeof(userid_str))
					IntToString(userid, userid_str, sizeof(userid_str))
					if(!IsClientImmune(i) || (IsClientImmune(i) && GetConVarInt(AdminAllowSelf) == 1 && i == client))
					{
						AddMenuItem(PlayerList, userid_str, DisplayItem)
					}
					else
					{
						AddMenuItem(PlayerList, userid_str, DisplayItem, ITEMDRAW_DISABLED)
					}
					playercount++
				}
			}
		}
	}
	else if(Type == TMS_PlayerSlay)
	{
		PlayerList = CreateMenu(Handle_Slay)
		decl String:menutitle[256]
		Format(menutitle, sizeof(menutitle), "%T", "Slay Title", client)
		SetMenuTitle(PlayerList, menutitle)
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				new currteam = GetClientTeam(i)
				if(currteam != UNASSIGNED && currteam != SPEC && IsPlayerAlive(i))
				{
					decl String:TargetName[32]
					GetClientName(i, TargetName, sizeof(TargetName))
					decl String:DisplayItem[64]
					Format(DisplayItem, sizeof(DisplayItem), "%s (%s)", TargetName, TeamName[currteam])
					new userid = GetClientUserId(i)
					decl String:userid_str[32]
					IntToString(userid, userid_str, sizeof(userid_str))
					IntToString(userid, userid_str, sizeof(userid_str))
					if(!IsClientImmune(i) || (IsClientImmune(i) && GetConVarInt(AdminAllowSelf) == 1 && i == client))
					{
						AddMenuItem(PlayerList, userid_str, DisplayItem)
					}
					else
					{
						AddMenuItem(PlayerList, userid_str, DisplayItem, ITEMDRAW_DISABLED)
					}
					playercount++
				}
			}
		}
	}
	if(playercount == 0)
	{
		AddMenuItem(PlayerList,"noplayersspacer", "", ITEMDRAW_SPACER)
	}
	SetMenuExitButton(PlayerList, true)
	SetMenuExitBackButton(PlayerList, true)
	DisplayMenu(PlayerList, client, MENU_TIME_FOREVER)
}

public Handle_Slay(Handle:PlayerList, MenuAction:action, client, itemNum)
{
	if(client < 1)
	{
		return
	}
	if(action == MenuAction_Select)
	{
		new String:userid[MAX_TARGET_LENGTH]
		GetMenuItem(PlayerList, itemNum, userid, sizeof(userid))
		new target = GetClientOfUserId(StringToInt(userid))
		if(target < 1)
		{
			return
		}
		if(IsPlayerAlive(target))
		{
			decl String:message[256]
			for(new i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i))
				{
					Format(message, sizeof(message), "%T", "Admin SlayPlayer", i, client, target)
					if(GetConVarInt(AnonymousAdmin) == 1)
					{
						decl String:AdminName[32]
						GetClientName(client, AdminName, sizeof(AdminName))
						Format(AdminName, sizeof(AdminName), "%s ", AdminName)
						ReplaceStringEx(message, sizeof(message), AdminName, "")
					}
					TMSMessage(i, message)
				}
			}
			TMSSlay(target, GetConVarInt(SlayFX))
		}
		g_MenuPos[client] = TMS_PlayerSlay
		CreateTimer(0.1, ReopenPlayerMenu, client, TIMER_FLAG_NO_MAPCHANGE)
	}
	else if(action == MenuAction_Cancel)
	{
		if(itemNum == MenuCancel_ExitBack)
		{
			if(GetClientMenu(client))
			{
				CancelClientMenu(client)
			}			
			ShowDoDTMSCmds(client, TMS_PlayerCommands)
		}
	}
}

public Handle_SwapToAllies(Handle:PlayerList, MenuAction:action, client, itemNum)
{
	if(client < 1)
	{
		return
	}
	if(action == MenuAction_Select)
	{
		new String:userid[MAX_TARGET_LENGTH]
		GetMenuItem(PlayerList, itemNum, userid, sizeof(userid))
		new target = GetClientOfUserId(StringToInt(userid))
		if(target < 1)
		{
			return
		}
		decl String:message[256]
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				Format(message, sizeof(message), "%T", "Admin SwitchPlayer", i, client, target, TeamName[ALLIES])
				if(GetConVarInt(AnonymousAdmin) == 1)
				{
					decl String:AdminName[32]
					GetClientName(client, AdminName, sizeof(AdminName))
					Format(AdminName, sizeof(AdminName), "%s ", AdminName)
					ReplaceStringEx(message, sizeof(message), AdminName, "")
				}
				TMSMessage(i, message)
			}
		}
		TMSChangeToTeam(target,ALLIES)
		g_MenuPos[client] = TMS_PlayerSwapAllies
		CreateTimer(0.1, ReopenPlayerMenu, client, TIMER_FLAG_NO_MAPCHANGE)
	}
	else if(action == MenuAction_Cancel)
	{
		if(itemNum == MenuCancel_ExitBack)
		{
			if(GetClientMenu(client))
			{
				CancelClientMenu(client)
			}			
			ShowDoDTMSCmds(client, TMS_PlayerCommands)
		}
	}
}

public Handle_SwapToAxis(Handle:PlayerList, MenuAction:action, client, itemNum)
{
	if(client < 1)
	{
		return
	}
	if(action == MenuAction_Select)
	{
		new String:userid[MAX_TARGET_LENGTH]
		GetMenuItem(PlayerList, itemNum, userid, sizeof(userid))
		new target = GetClientOfUserId(StringToInt(userid))
		if(target < 1)
		{
			return
		}
		decl String:message[256]
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				Format(message, sizeof(message), "%T", "Admin SwitchPlayer", i, client, target, TeamName[AXIS])
				if(GetConVarInt(AnonymousAdmin) == 1)
				{
					decl String:AdminName[32]
					GetClientName(client, AdminName, sizeof(AdminName))
					Format(AdminName, sizeof(AdminName), "%s ", AdminName)
					ReplaceStringEx(message, sizeof(message), AdminName, "")
				}
				TMSMessage(i, message)
			}
		}
		TMSChangeToTeam(target,AXIS)
		g_MenuPos[client] = TMS_PlayerSwapAxis
		CreateTimer(0.1, ReopenPlayerMenu, client, TIMER_FLAG_NO_MAPCHANGE)
	}
	else if(action == MenuAction_Cancel)
	{
		if(itemNum == MenuCancel_ExitBack)
		{
			if(GetClientMenu(client))
			{
				CancelClientMenu(client)
			}			
			ShowDoDTMSCmds(client, TMS_PlayerCommands)
		}
	}
}

public Handle_SwapToSpec(Handle:PlayerList, MenuAction:action, client, itemNum)
{
	if(client < 1)
	{
		return
	}
	if(action == MenuAction_Select)
	{
		new String:userid[MAX_TARGET_LENGTH]
		GetMenuItem(PlayerList, itemNum, userid, sizeof(userid))
		new target = GetClientOfUserId(StringToInt(userid))
		decl String:message[256]
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				Format(message, sizeof(message), "%T", "Admin SwitchPlayer", i, client, target, TeamName[SPEC])
				if(GetConVarInt(AnonymousAdmin) == 1)
				{
					decl String:AdminName[32]
					GetClientName(client, AdminName, sizeof(AdminName))
					Format(AdminName, sizeof(AdminName), "%s ", AdminName)
					ReplaceStringEx(message, sizeof(message), AdminName, "")
				}
				TMSMessage(i, message)
			}
		}
		TMSChangeToTeam(target,SPEC)
		g_MenuPos[client] = TMS_PlayerSpec
		CreateTimer(0.1, ReopenPlayerMenu, client, TIMER_FLAG_NO_MAPCHANGE)
	}
	else if(action == MenuAction_Cancel)
	{
		if(itemNum == MenuCancel_ExitBack)
		{
			if(GetClientMenu(client))
			{
				CancelClientMenu(client)
			}			
			ShowDoDTMSCmds(client, TMS_PlayerCommands)
		}
	}
}

public Handle_EncouragePlayer(Handle:PlayerList, MenuAction:action, client, itemNum)
{
	if(client < 1)
	{
		return
	}
	if(action == MenuAction_Select)
	{
		new String:userid[MAX_TARGET_LENGTH]
		GetMenuItem(PlayerList, itemNum, userid, sizeof(userid))
		new target = GetClientOfUserId(StringToInt(userid))
		if(target < 1)
		{
			return
		}
		decl String:message[256]
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				Format(message, sizeof(message), "%T", "Encouraged Player", i, client, target)
				if(GetConVarInt(AnonymousAdmin) == 1)
				{
					decl String:AdminName[32]
					GetClientName(client, AdminName, sizeof(AdminName))
					Format(AdminName, sizeof(AdminName), "%s ", AdminName)
					ReplaceStringEx(message, sizeof(message), AdminName, "")
				}
				TMSMessage(i, message)
			}
		}
		EncourageClient(target)
		g_MenuPos[client] = TMS_PlayerEncourage
		CreateTimer(0.1, ReopenPlayerMenu, client, TIMER_FLAG_NO_MAPCHANGE)
	}
	else if(action == MenuAction_Cancel)
	{
		if(itemNum == MenuCancel_ExitBack)
		{
			if(GetClientMenu(client))
			{
				CancelClientMenu(client)
			}			
			ShowDoDTMSCmds(client, TMS_PlayerCommands)
		}
	}
}

public EncourageTeam(team)
{
	decl String:message[256]
	decl String:sound[256]
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == team)
		{
			Format(sound, sizeof(sound), "%s", Encourage[team])
			if(IsPlayerAlive(i))
			{
				SlapPlayer(i, 0, true)
			}
			Format(message, sizeof(message), "%T", "Encourage Msg", i)
			TMSHintMessage(i, message)
			TMSSound(i, sound)
		}
	}
	return true
}

public EncourageClient(client)
{
	if(IsClientInGame(client))
	{
		new team = GetClientTeam(client)
		decl String:message[256]
		Format(message, sizeof(message), "%T", "EncouragePlayer Msg", client, client)
		decl String:sound[256]
		Format(sound, sizeof(sound), "%s", Encourage[team])
		if(IsPlayerAlive(client))
		{
			SlapPlayer(client, 0, true)
		}
		TMSHintMessage(client, message)
		TMSSound(client, sound)
	}
	return true
}

stock bool:IsClientImmune(client)
{
	if((GetUserAdmin(client) != INVALID_ADMIN_ID || IsWhiteListed[client]) && !IsBlackListed[client] && GetConVarInt(ClientImmunity) == 1)
	{
		return true
	}
	else
	{
		return false
	}
}