#include <sourcemod>
#include <adminmenu>

new Handle:SlapCV = INVALID_HANDLE;


#define Ban "ban"
#define Kick "kick"
#define Slap "slap"
#define Slay "slay"
#define Mute "mute"
#define Swapteam "swapteam"
#define PLUGIN_NAME "Donor Mod"
#define PLUGIN_AUTHOR "Dark Goku"
#define PLUGIN_DESCRIPTION "A Donor Mod For Communities"
#define PLUGIN_URL "http://sourcemod.net"
#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = 
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL,
}

public OnPluginStart()
{
	RegConsoleCmd("sm_vip", VipMenu);
	PrintToServer("Vip Plugin Loaded - Ready For Use");
	SlapCV = CreateConVar("slapcv", "25", "How much to slap a player");
}

public Action:VipMenu(client, args)
{
	if (GetUserFlagBits(client) & ADMFLAG_CUSTOM1)
	{
		new Handle:menu = CreateMenu(MenuCallBack);
		SetMenuTitle(menu, "Vip Menu");
		AddMenuItem(menu, Slap, "Slaps a player");
		AddMenuItem(menu, Slay, "Slays a player");
		AddMenuItem(menu, Mute, "Mutes a player");
		AddMenuItem(menu, Swapteam, "Swaps you to the opposite team.");
		DisplayMenu(menu, client, 30);
	}
}

public MenuCallBack(Handle:menu, MenuAction:action, client, param2)
{	
	if(action == MenuAction_Select)
	{
		decl String:Item[20];
		GetMenuItem(menu, param2, Item, sizeof(Item));
		
		if(StrEqual(Item, Kick))
		{
			new Handle:KickMenu = CreateMenu(kickmenu);
			AddTargetsToMenu2(KickMenu, client, COMMAND_FILTER_ALIVE|COMMAND_FILTER_NO_BOTS);
			DisplayMenu(KickMenu, client, 20);
		}		
	}
	
	if(action == MenuAction_Select)
	{
		decl String:Item[20];
		GetMenuItem(menu, param2, Item, sizeof(Item));
		
		if(StrEqual(Item, Slap))
		{
			new Handle:SlapMenu = CreateMenu(slapmenu);
			AddTargetsToMenu2(SlapMenu, client, COMMAND_FILTER_ALIVE|COMMAND_FILTER_NO_BOTS);
			DisplayMenu(SlapMenu, client, 20);
		}		
	}
	
	if(action == MenuAction_Select)
	{
		decl String:Item[20];
		GetMenuItem(menu, param2, Item, sizeof(Item));
		
		if(StrEqual(Item, Slay))
		{
			new Handle:SlayMenu = CreateMenu(slaymenu);
			AddTargetsToMenu2(SlayMenu, client, COMMAND_FILTER_ALIVE|COMMAND_FILTER_NO_BOTS);
			DisplayMenu(SlayMenu, client, 20);	
		}		
	}
	
	if(action == MenuAction_Select)
	{
		decl String:Item[20];
		GetMenuItem(menu, param2, Item, sizeof(Item));
		
		if(StrEqual(Item, Mute))
		{
			new Handle:MuteMenu = CreateMenu(mutemenu);
			AddTargetsToMenu2(MuteMenu, 0, COMMAND_FILTER_ALIVE|COMMAND_FILTER_NO_BOTS);
			DisplayMenu(MuteMenu, client, 20);
		}		
	}
	
	if(action == MenuAction_Select)
	{
		decl String:Item[20];
		GetMenuItem(menu, param2, Item, sizeof(Item));
		
		if(StrEqual(Item, Swapteam))
		{
			if(GetClientTeam(client) == 2)
			{
				ChangeClientTeam(client, 3);
			}
			else if(GetClientTeam(client) == 3)
			{
				ChangeClientTeam(client, 2);
			}
			else if(GetClientTeam(client) == 1)
			{
				ChangeClientTeam(client, 2);
			}
		}		
	}
	
}


public slapmenu(Handle:SlapMenu, MenuAction:action, Client, param2)
{
	if(action == MenuAction_Select)
	{
		new String:targetname[MAX_NAME_LENGTH];
		GetMenuItem(SlapMenu, param2, targetname, sizeof(targetname));
		ServerCommand("sm_slap #%s %d", targetname, GetConVarInt(SlapCV));	
	}
}

public slaymenu(Handle:SlayMenu, MenuAction:action, Client, param2)
{
	if(action == MenuAction_Select)
	{
		new String:targetname[MAX_NAME_LENGTH];
		GetMenuItem(SlayMenu, param2, targetname, sizeof(targetname));
		ServerCommand("sm_slay #%s %d", targetname, GetConVarInt(SlapCV));
	}
}

public mutemenu(Handle:MuteMenu, MenuAction:action, Client, param2)
{
	if(action == MenuAction_Select)
	{
		new String:targetname[MAX_NAME_LENGTH];
		GetMenuItem(MuteMenu, param2, targetname, sizeof(targetname));
		ServerCommand("sm_mute #%s", targetname);	
	}
}

public kickmenu(Handle:KickMenu, MenuAction:action, Client, param2)
{
	if(action == MenuAction_Select)
	{
		new String:targetname[MAX_NAME_LENGTH];
		GetMenuItem(KickMenu, param2, targetname, sizeof(targetname));
		ServerCommand("sm_kick #%s", targetname);	
	}
}