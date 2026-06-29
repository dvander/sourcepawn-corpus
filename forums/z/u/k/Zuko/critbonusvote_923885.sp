/*
 * Crit Bonus Vote  
 *
 * Plugin ask players if they want crit bonus on CTF maps.
 *
 * Version 1.0
 * - Initial release 
 *
 * Zuko / #hlds.pl @ Qnet / zuko.isports.pl /
 *
 */
 
#include <sourcemod>
#include <colors>

#define PLUGIN_VERSION "1.0"

new String:g_MapName[128];
new bool:anyplayerconnected = false
new bool:isactfmap = false

public Plugin:myinfo = 
{
	name = "[TF2] Crit Bonus Vote",
	author = "Zuko",
	description = "Ask players if they want crit bonus.",
	version = PLUGIN_VERSION,
	url = "http://zuko.isports.pl"
}

public OnPluginStart()
{
	CreateConVar("critbonusvote_version", PLUGIN_VERSION, "[TF2] Crit Bonus Vote Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	LoadTranslations("critbonusvote.phrases");
}

public OnMapStart()
{
	anyplayerconnected = false
	
	GetCurrentMap(g_MapName, sizeof(g_MapName));
	if (StrContains(g_MapName,"ctf_",false) == -1)
	{
		isactfmap = false
		
	}
	else
	{
		isactfmap = true
	}
}

public OnClientPostAdminCheck()
{
	if ((!anyplayerconnected) && (isactfmap))
	{
		CreateTimer(30.0, StartVote)
		anyplayerconnected = true
	}
}

public Action:StartVote(Handle:timer)
{
	if (IsVoteInProgress())
	{
		return;
	}
 
	new Handle:menu = CreateMenu(Handle_VoteMenu)
	
	decl String:title[100], String:menuitem1[100], String:menuitem2[100], String:menuitem3[100];
	Format(title, sizeof(title),"%t", "VoteMenuTitle", LANG_SERVER)
	SetMenuTitle(menu, title)
	Format(menuitem1, sizeof(menuitem1),"%t", "MenuItem01", LANG_SERVER)
	AddMenuItem(menu, "no", menuitem1)
	Format(menuitem2, sizeof(menuitem2),"%t", "MenuItem02", LANG_SERVER)
	AddMenuItem(menu, "5sec", menuitem2)
	Format(menuitem3, sizeof(menuitem3),"%t", "MenuItem03", LANG_SERVER)
	AddMenuItem(menu, "10sec", menuitem3)
	SetMenuExitButton(menu, false)
	VoteMenuToAll(menu, 30);
}

public Handle_VoteMenu(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	} 
	else if (action == MenuAction_VoteEnd) 
	{
		switch(param1)
		{
			case 0:
			{
				ServerCommand("tf_ctf_bonus_time 0");
				CPrintToChatAll("{lightgreen}[SM] %t", "VoteEnd01", LANG_SERVER);
			}
			case 1:
			{
				ServerCommand("tf_ctf_bonus_time 5");
				CPrintToChatAll("{lightgreen}[SM] %t", "VoteEnd02", LANG_SERVER);
			}
			case 2:
			{
				ServerCommand("tf_ctf_bonus_time 10");
				CPrintToChatAll("{lightgreen}[SM] %t", "VoteEnd03", LANG_SERVER);
			}
		}
	}
}
