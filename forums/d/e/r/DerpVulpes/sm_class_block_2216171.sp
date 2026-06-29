//
// SourceMod Script
//
// Developed by <eVa>Dog
// December 2008
// http://www.theville.org
//

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#undef REQUIRE_PLUGIN
#include <adminmenu>

new Handle:hAdminMenu = INVALID_HANDLE
#define PLUGIN_VERSION "1.0.102"

new Handle:g_Cvar_Enable = INVALID_HANDLE 

new g_Class[MAXPLAYERS+1][10] 
new g_PreviousClass[MAXPLAYERS+1]
new g_Target[MAXPLAYERS+1]
new g_Action[MAXPLAYERS+1]

static const String:classname[][] = {"noclass", "Scout", "Sniper", "Soldier", "Demoman", "Medic", "Heavy", "Pyro", "Spy", "Engineer"}

public Plugin:myinfo = 
{
	name = "TF2 Class Block",
	author = "<eVa>Dog",
	description = "Blocks certain players from joining a particular class",
	version = PLUGIN_VERSION,
	url = "http://www.theville.org"
}

public OnPluginStart()
{
	CreateConVar("sm_class_block_version", PLUGIN_VERSION, "Version of TF2 Class Block", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	g_Cvar_Enable  = CreateConVar("sm_class_block_enabled", "1", "- Enables/Disables the plugin")
	
	RegAdminCmd("sm_blockclass", Admin_BlockClass, ADMFLAG_CHAT, " - sm_blockclass <#userid|name> <scout|sniper|soldier|demo|medic|heavy|pyro|spy|engineer>")
	
	RegAdminCmd("sm_unblockclass", Admin_UnblockClass, ADMFLAG_CHAT, " - sm_unblockclass <#userid|name> <scout|sniper|soldier|demo|medic|heavy|pyro|spy|engineer>")

	HookEvent("player_changeclass", ChangeClassEvent, EventHookMode_Pre)
	
	LoadTranslations("common.phrases")
	
	new Handle:topmenu
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu)
	}
}

public OnEventShutdown()
{
	UnhookEvent("player_changeclass", ChangeClassEvent)
}


public OnClientPostAdminCheck(client)
{
	if (GetConVarInt(g_Cvar_Enable))
	{
		for (new i = 1; i <= 9; i++)
		{
			g_Class[client][i] = 0
		}
		
		GetClassData(client)
	}
}

public Action:ChangeClassEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(g_Cvar_Enable))
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"))
		new class  = GetEventInt(event, "class")
		
		if (g_Class[client][class] == 1)
		{
			PrintCenterText(client, "%s Class Unavailable", classname[class])
			FakeClientCommandEx(client, "say_team @* tried to switch to %s class! *", classname[class]);
			for (new i = 1; i <= 10; i++)
			{
				if (i == 10)
				{
					KickClient(client, "There's no available class for you to play")
				}
				if (g_Class[client][i] == 0)
				{
					TF2_SetPlayerClass(client, TFClassType:i)
					break;
				}
			}
			//TF2_SetPlayerClass(client, TFClassType:g_PreviousClass[client])
			new team   = GetClientTeam(client)
			ShowVGUIPanel(client, team == 3 ? "class_blue" : "class_red")
		}
		else
		{
			g_PreviousClass[client] = class
		}
	}
	return Plugin_Continue
}


bool:GetClassData(client)
{
	new Handle:kv = CreateKeyValues("ClassData")
	new String:authid[64]
	
	decl String:datapath[PLATFORM_MAX_PATH]
	BuildPath(Path_SM, datapath, PLATFORM_MAX_PATH, "configs/sm_class_block.txt")
		
	FileToKeyValues(kv, datapath)
	
	GetClientAuthString(client, authid, sizeof(authid))
	if (!KvJumpToKey(kv, authid))
	{
		return false
	}
	
	g_Class[client][1] = KvGetNum(kv, "scout", 0)
	g_Class[client][2] = KvGetNum(kv, "sniper", 0)
	g_Class[client][3] = KvGetNum(kv, "soldier", 0)
	g_Class[client][4] = KvGetNum(kv, "demo", 0)
	g_Class[client][5] = KvGetNum(kv, "medic", 0)
	g_Class[client][6] = KvGetNum(kv, "heavy", 0)
	g_Class[client][7] = KvGetNum(kv, "pyro", 0)
	g_Class[client][8] = KvGetNum(kv, "spy", 0)
	g_Class[client][9] = KvGetNum(kv, "engineer", 0)
		
	CloseHandle(kv) 
	return true
}

bool:SetClassData(client, String:key[], any:value)
{
	new Handle:kv = CreateKeyValues("ClassData")
	new String:authid[64]

	decl String:datapath[PLATFORM_MAX_PATH]
	BuildPath(Path_SM, datapath, PLATFORM_MAX_PATH, "configs/sm_class_block.txt")

	FileToKeyValues(kv, datapath)
	
	GetClientAuthString(client, authid, sizeof(authid))
	if (!KvJumpToKey(kv, authid, true))
	{
		return false
	}

	KvSetNum(kv, key, value)

	KvRewind(kv)
	KeyValuesToFile(kv, datapath)

	CloseHandle(kv)
	return true
}

public Action:Admin_BlockClass(client, args)
{
	decl String:target[65], String:targetclass[32]
	decl String:target_name[MAX_TARGET_LENGTH]
	decl target_list[MAXPLAYERS]
	decl target_count
	decl bool:tn_is_ml
	
	if (args <= 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_blockclass <#userid|name> <scout|sniper|soldier|demo|medic|heavy|pyro|spy|engineer>");
		return Plugin_Handled
	}
	
	if (args > 1)
	{
		GetCmdArg(1, target, sizeof(target))
		GetCmdArg(2, targetclass, sizeof(targetclass))
	
		if ((target_count = ProcessTargetString(target, client, target_list, MAXPLAYERS, 0,	target_name, sizeof(target_name), tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count)
			return Plugin_Handled
		}
		
		for (new i = 0; i < target_count; i++)
		{
			DoBlock(client, target_list[i], targetclass)
		}
	}
	return Plugin_Handled
}

public DoBlock(any:client, any:target, String:targetclass[])
{
	if (StrEqual(targetclass, "scout", false))
	{
		SetClassData(target, "scout", 1)
		g_Class[target][1] = 1
		PrintToChat(target, "[SM] You have been blocked from using Scout")
		LogAction(client, target, "\"%L\" prevented \"%L\" using the Scout class", client, target)
		ShowActivity(client, "prevented %N using Scout class", target)
	}
	else if (StrEqual(targetclass, "sniper", false))
	{
		SetClassData(target, "sniper", 1)
		g_Class[target][2] = 1
		PrintToChat(target, "[SM] You have been blocked from using Sniper")
		LogAction(client, target, "\"%L\" prevented \"%L\" using the Sniper class", client, target)
		ShowActivity(client, "prevented %N using Sniper class", target)
	}
	else if (StrEqual(targetclass, "soldier", false))
	{
		SetClassData(target, "soldier", 1)
		g_Class[target][3] = 1
		PrintToChat(target, "[SM] You have been blocked from using Soldier")
		LogAction(client, target, "\"%L\" prevented \"%L\" using the Soldier class", client, target)
		ShowActivity(client, "prevented %N using Soldier class", target)
	}
	else if (StrEqual(targetclass, "demo", false))
	{
		SetClassData(target, "demo", 1)
		g_Class[target][4] = 1
		PrintToChat(target, "[SM] You have been blocked from using Demo")
		LogAction(client, target, "\"%L\" prevented \"%L\" using the Demo class", client, target)
		ShowActivity(client, "prevented %N using Demo class", target)
	}
	else if (StrEqual(targetclass, "medic", false))
	{
		SetClassData(target, "medic", 1)
		g_Class[target][5] = 1
		PrintToChat(target, "[SM] You have been blocked from using Medic")
		LogAction(client, target, "\"%L\" prevented \"%L\" using the Medic class", client, target)
		ShowActivity(client, "prevented %N using Medic class", target)
	}
	else if (StrEqual(targetclass, "heavy", false))
	{
		SetClassData(target, "heavy", 1)
		g_Class[target][6] = 1
		PrintToChat(target, "[SM] You have been blocked from using Heavy")
		LogAction(client, target, "\"%L\" prevented \"%L\" using the Heavy class", client, target)
		ShowActivity(client, "prevented %N using Heavy class", target)
	}
	else if (StrEqual(targetclass, "pyro", false))
	{
		SetClassData(target, "pyro", 1)
		g_Class[target][7] = 1
		PrintToChat(target, "[SM] You have been blocked from using Pyro")
		LogAction(client, target, "\"%L\" prevented \"%L\" using the Pyro class", client, target)
		ShowActivity(client, "prevented %N using Pyro class", target)
	}
	else if (StrEqual(targetclass, "spy", false))
	{
		SetClassData(target, "spy", 1)
		g_Class[target][8] = 1
		PrintToChat(target, "[SM] You have been blocked from using Spy")
		LogAction(client, target, "\"%L\" prevented \"%L\" using the Spy class", client, target)
		ShowActivity(client, "prevented %N using Spy class", target)
	}
	else if (StrEqual(targetclass, "engineer", false))
	{
		SetClassData(target, "engineer", 1)
		g_Class[target][9] = 1
		PrintToChat(target, "[SM] You have been blocked from using Engineer")
		LogAction(client, target, "\"%L\" prevented \"%L\" using the Engineer class", client, target)
		ShowActivity(client, "prevented %N using Engineer class", target)
	}
	else
	{	
		PrintToChat(client, "[SM] Unable to identify class name")
	}
	
	new class = integer:TF2_GetPlayerClass(target)
	
	if (g_Class[target][class] == 1)
	{
		ChangeClientTeam(target, 1);
		for (new i = 1; i <= 10; i++)
		{
			if (i == 10)
			{
				KickClient(target, "There's no available class for you to play")
			}
			if (g_Class[target][i] == 0)
			{
				TF2_SetPlayerClass(target, TFClassType:i)
				break;
			}
		}
	}
}

public Action:Admin_UnblockClass(client, args)
{
	decl String:target[65], String:targetclass[32]
	decl String:target_name[MAX_TARGET_LENGTH]
	decl target_list[MAXPLAYERS]
	decl target_count
	decl bool:tn_is_ml
	
	if (args <= 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_unblockclass <#userid|name> <scout|sniper|soldier|demo|medic|heavy|pyro|spy|engineer>");
		return Plugin_Handled
	}
	
	if (args > 1)
	{
		GetCmdArg(1, target, sizeof(target))
		GetCmdArg(2, targetclass, sizeof(targetclass))
	
		if ((target_count = ProcessTargetString(target, client, target_list, MAXPLAYERS, 0,	target_name, sizeof(target_name), tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count)
			return Plugin_Handled
		}
		
		for (new i = 0; i < target_count; i++)
		{
			DoUnBlock(client, target_list[i], targetclass)
		}
	}
	return Plugin_Handled
}

public DoUnBlock(any:client, any:target, String:targetclass[])
{
	if (StrEqual(targetclass, "scout", false))
	{
		SetClassData(target, "scout", 0)
		g_Class[target][1] = 0
		PrintToChat(target, "[SM] You have been unblocked from using Scout")
		LogAction(client, target, "\"%L\" allowed \"%L\" to use the Scout class", client, target)
		ShowActivity(client, "allowed %N to use Scout class", target)
	}
	else if (StrEqual(targetclass, "sniper", false))
	{
		SetClassData(target, "sniper", 0)
		g_Class[target][2] = 0
		PrintToChat(target, "[SM] You have been unblocked from using Sniper")
		LogAction(client, target, "\"%L\" allowed \"%L\" to use the Sniper class", client, target)
		ShowActivity(client, "allowed %N to use Sniper class", target)
	}
	else if (StrEqual(targetclass, "soldier", false))
	{
		SetClassData(target, "soldier", 0)
		g_Class[target][3] = 0
		PrintToChat(target, "[SM] You have been unblocked from using Soldier")
		LogAction(client, target, "\"%L\" allowed \"%L\" to use the Soldier class", client, target)
		ShowActivity(client, "allowed %N to use Soldier class", target)
	}
	else if (StrEqual(targetclass, "demo", false))
	{
		SetClassData(target, "demo", 0)
		g_Class[target][4] = 0
		PrintToChat(target, "[SM] You have been unblocked from using Demo")
		LogAction(client, target, "\"%L\" allowed \"%L\" to use the Demo class", client, target)
		ShowActivity(client, "allowed %N to use Demo class", target)
	}
	else if (StrEqual(targetclass, "medic", false))
	{
		SetClassData(target, "medic", 0)
		g_Class[target][5] = 0
		PrintToChat(target, "[SM] You have been unblocked from using Medic")
		LogAction(client, target, "\"%L\" allowed \"%L\" to use the Medic class", client, target)
		ShowActivity(client, "allowed %N to use Medic class", target)
	}
	else if (StrEqual(targetclass, "heavy", false))
	{
		SetClassData(target, "heavy", 0)
		g_Class[target][6] = 0
		PrintToChat(target, "[SM] You have been unblocked from using Heavy")
		LogAction(client, target, "\"%L\" allowed \"%L\" to use the Heavy class", client, target)
		ShowActivity(client, "allowed %N to use Heavy class", target)
	}
	else if (StrEqual(targetclass, "pyro", false))
	{
		SetClassData(target, "pyro", 0)
		g_Class[target][7] = 0
		PrintToChat(target, "[SM] You have been unblocked from using Pyro")
		LogAction(client, target, "\"%L\" allowed \"%L\" to use the Pyro class", client, target)
		ShowActivity(client, "allowed %N to use Pyro class", target)
	}
	else if (StrEqual(targetclass, "spy", false))
	{
		SetClassData(target, "spy", 0)
		g_Class[target][8] = 0
		PrintToChat(target, "[SM] You have been unblocked from using Spy")
		LogAction(client, target, "\"%L\" prevented \"%L\" to use the Spy class", client, target)
		ShowActivity(client, "prevented %N to use Spy class", target)
	}
	else if (StrEqual(targetclass, "engineer", false))
	{
		SetClassData(target, "engineer", 0)
		g_Class[target][9] = 0
		PrintToChat(target, "[SM] You have been unblocked from using Engineer")
		LogAction(client, target, "\"%L\" prevented \"%L\" to use the Engineer class", client, target)
		ShowActivity(client, "prevented %N to use Engineer class", target)
	}
	else
	{	
		PrintToChat(client, "[SM] Unable to identify class name")
	}
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "adminmenu")) 
	{
		hAdminMenu = INVALID_HANDLE;
	}
}

public OnAdminMenuReady(Handle:topmenu)
{
	if (topmenu == hAdminMenu)
	{
		return;
	}
	
	hAdminMenu = topmenu

	new TopMenuObject:player_commands = FindTopMenuCategory(hAdminMenu, ADMINMENU_PLAYERCOMMANDS)

	if (player_commands != INVALID_TOPMENUOBJECT)
	{
		AddToTopMenu(hAdminMenu,
			"sm_blockclass",
			TopMenuObject_Item,
			AdminMenu_Block, 
			player_commands,
			"sm_blockclass",
			ADMFLAG_CHAT)
			
		AddToTopMenu(hAdminMenu,
			"sm_unblockclass",
			TopMenuObject_Item,
			AdminMenu_UnBlock, 
			player_commands,
			"sm_unblockclass",
			ADMFLAG_CHAT)
	}
}
 
public AdminMenu_Block( Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength )
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Class - Block player")
	}
	else if( action == TopMenuAction_SelectOption)
	{
		g_Action[param] = 1
		DisplayPlayerMenu(param)
	}
}

public AdminMenu_UnBlock( Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength )
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Class - Unblock player")
	}
	else if( action == TopMenuAction_SelectOption)
	{
		g_Action[param] = 2
		DisplayPlayerMenu(param)
	}
}

DisplayPlayerMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_Players)
	
	decl String:title[100]
	Format(title, sizeof(title), "Choose Player:")
	SetMenuTitle(menu, title)
	SetMenuExitBackButton(menu, true)
	
	AddTargetsToMenu(menu, client, true, true)
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER)
}

public MenuHandler_Players(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu)
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hAdminMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(hAdminMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		decl String:info[32]
		new userid, target
		
		GetMenuItem(menu, param2, info, sizeof(info))
		userid = StringToInt(info)

		if ((target = GetClientOfUserId(userid)) == 0)
		{
			PrintToChat(param1, "[SM] %s", "Player no longer available")
		}
		else if (!CanUserTarget(param1, target))
		{
			PrintToChat(param1, "[SM] %s", "Unable to target")
		}
		else
		{			
			g_Target[param1] = target
			DisplayClassMenu(param1)
		}
	}
}

DisplayClassMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_Class)
	
	decl String:title[100]
	Format(title, sizeof(title), "Building")
	SetMenuTitle(menu, title)
	SetMenuExitBackButton(menu, true)
	
	AddMenuItem(menu, "scout", "Scout")
	AddMenuItem(menu, "sniper", "Sniper")
	AddMenuItem(menu, "soldier", "Soldier")
	AddMenuItem(menu, "demo", "Demoman")
	AddMenuItem(menu, "medic", "Medic")
	AddMenuItem(menu, "heavy", "Heavy Weapons")
	AddMenuItem(menu, "pyro", "Pyro")
	AddMenuItem(menu, "spy", "Spy")
	AddMenuItem(menu, "engineer", "Engineer")

	DisplayMenu(menu, client, MENU_TIME_FOREVER)
}

public MenuHandler_Class(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu)
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hAdminMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(hAdminMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		decl String:info[32]
		
		GetMenuItem(menu, param2, info, sizeof(info))
		
		if (g_Action[param1] == 1)
			DoBlock(param1, g_Target[param1], info)
		else if (g_Action[param1] == 2)
			DoUnBlock(param1, g_Target[param1], info)
	}
}