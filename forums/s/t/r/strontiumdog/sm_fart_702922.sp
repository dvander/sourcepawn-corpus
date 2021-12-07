//
// SourceMod Script
//
// Developed by <eVa>Dog
// September 2008
// http://www.theville.org
//


#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <adminmenu>

#define PLUGIN_VERSION "1.0.102"

new Handle:g_Fart[MAXPLAYERS+1]
new Handle:hAdminMenu = INVALID_HANDLE
new Handle:hTopMenu = INVALID_HANDLE

static const String:fart_msg[][] = {"Phew! I think I have sprung a leak!",
 "Oh man! My eyes are burning!", "Mmmm....I love Pepto Bismol!", "Man! Talk about planting a bomb! Pheeeew!", "Oops...Excuse me!",  
 "Pheeew!!! I shouldn't have eaten those Burritos!", "Silent but deadly...that's the way I like it!",  "Gah! That one didn't even smell!",
 "Anyone gotta a match?  I got one coming!", "Chewy...I think I could eat that one!", "Whoops! Just contributed to Global Warming...!",
 "Pull my finger!"}

static const String:fart_sound[][] = {"misc/anxious.wav", "misc/blower.wav",  "misc/common.wav"}


public Plugin:myinfo = 
{
	name = "Fart",
	author = "<eVa>Dog",
	description = "Makes players fart",
	version = PLUGIN_VERSION,
	url = "http://www.theville.org"
}

public OnPluginStart()
{
	CreateConVar("sm_fart_version", PLUGIN_VERSION, "Version of Fart", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	RegAdminCmd("sm_fart", admin_fart, ADMFLAG_BAN, " - farts a player")
	
	new Handle:topmenu
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu)
	}
}

public OnMapStart()
{
	AddFileToDownloadsTable("sound/misc/anxious.wav")
	AddFileToDownloadsTable("sound/misc/blower.wav")
	AddFileToDownloadsTable("sound/misc/common.wav")
	PrecacheSound("misc/anxious.wav", true)
	PrecacheSound("misc/blower.wav", true)
	PrecacheSound("misc/common.wav", true)
}

public Action:admin_fart(client, args)
{
	decl String:target[65]
	decl String:target_name[MAX_TARGET_LENGTH]
	decl target_list[MAXPLAYERS]
	decl target_count
	decl bool:tn_is_ml
	
	if (args < 1)
	{
		PrintToConsole(client, "[SM] Usage: sm_fart <#userid|name>")
		return Plugin_Handled
	}
	else
	{
		GetCmdArg(1, target, sizeof(target))
				
		if ((target_count = ProcessTargetString(
				target,
				client,
				target_list,
				MAXPLAYERS,
				0,
				target_name,
				sizeof(target_name),
				tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count)
			return Plugin_Handled
		}
		
		for (new i = 0; i < target_count; i++)
		{
			if (IsClientInGame(target_list[i]) && IsPlayerAlive(target_list[i]))
			{
				PerformFart(client, target_list[i])
			}
		}
		
		return Plugin_Handled
	}
}


PerformFart(client, target)
{
	if (g_Fart[target] == INVALID_HANDLE)
	{
		CreateFart(target)
		LogAction(client, target, "\"%L\" set a Fart on \"%L\"", client, target)
		new String:clientname[64]
		GetClientName(client, clientname, sizeof(clientname)) 
		new String:targetname[64]
		GetClientName(target, targetname, sizeof(targetname)) 
		PrintToChatAll("\x01[SM] \x03%s \x01fed \x04%s \x01a fat Burrito!", clientname, targetname)
	}
	else
	{
		KillFart(target)
		LogAction(client, target, "\"%L\" removed a Fart from \"%L\"", client, target)
		new String:clientname[64]
		GetClientName(client, clientname, sizeof(clientname)) 
		new String:targetname[64]
		GetClientName(target, targetname, sizeof(targetname)) 
		PrintToChatAll("\x01[SM] \x03%s \x01gave \x04%s \x01a some Pepto Bismol!", clientname, targetname)
	}			
}

CreateFart(client)
{
	g_Fart[client] = CreateTimer(10.0, Timer_Fart, client, TIMER_REPEAT)
}

KillFart(client)
{
	KillTimer(g_Fart[client])
	g_Fart[client] = INVALID_HANDLE
}


public Action:Timer_Fart(Handle:timer, any:client)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
	{
		KillFart(client)
		return Plugin_Handled
	}
	
	new choose_msg = GetRandomInt(0, 11)
	new choose_sound = GetRandomInt(0, 2)
	
	new String:Name[64]
	GetClientName(client, Name, sizeof(Name)) 
		
	new String:buffermsg[256]
	Format(buffermsg, 256, "\x01\x03%s\x01: %s", Name, fart_msg[choose_msg])
	SayText2(client, client, buffermsg)
	EmitSoundToClient(client, fart_sound[choose_sound], _, _, _, _, 1.0);
			
	return Plugin_Handled
}

stock SayText2(client_index, author_index, const String:message[] ) 
{
    new Handle:buffer = StartMessageAll("SayText2")
    if (buffer != INVALID_HANDLE) 
	{
        BfWriteByte(buffer, author_index)
        BfWriteByte(buffer, true)
        BfWriteString(buffer, message)
        EndMessage()
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
			"sm_fart",
			TopMenuObject_Item,
			AdminMenu_Fart, 
			player_commands,
			"sm_fart",
			ADMFLAG_SLAY)
	}
}
 
public AdminMenu_Fart( Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength )
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format( buffer, maxlength, "Fart player" )
	}
	else if( action == TopMenuAction_SelectOption)
	{
		DisplayFartMenu( param )
	}
}

DisplayFartMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_Fart)
	
	decl String:title[100]
	Format(title, sizeof(title), "Fart a Player:")
	SetMenuTitle(menu, title)
	SetMenuExitBackButton(menu, true)
	
	AddTargetsToMenu(menu, client, true, true)
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER)
}

public MenuHandler_Fart(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu)
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
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
			PerformFart(param1, target)
		}
		
		/* Re-draw the menu if they're still valid */
		if (IsClientInGame(param1) && !IsClientInKickQueue(param1))
		{
			DisplayFartMenu(param1);
		}
	}
}

