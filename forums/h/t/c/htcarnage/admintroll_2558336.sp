#include <sourcemod>
#include <adminmenu>
#include <sdkhooks>
#include <sdktools>

#define PLUGIN_VERSION "1.1.4a"
#define lGreen 0x03

#undef REQUIRE_PLUGIN
#include <sourcebans>

new Handle:BanTime;
new bool:SourceBans = false;
new Handle:Message;
new Handle:Version;

enum Punishments
{
	None = 0,
	Kick,
	Ban,
	Hide,
	Damage,
	Mirror
};

new Punishments:Punishment[MAXPLAYERS + 1];


public Plugin:myinfo =
{
	name = "Admin Troll",
	author = "BB",
	description = "Troll douchebag players",
	version = PLUGIN_VERSION,
};

/************************
**Plugin Initialization**
************************/
public OnPluginStart()
{
	Version = CreateConVar("admintroll_version", PLUGIN_VERSION, "Version CVar", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	RegAdminCmd("sm_troll", OpenTrollMenu, ADMFLAG_BAN, "Open the troll player menu");
	RegAdminCmd("sm_untroll", UntrollPlayer, ADMFLAG_BAN, "Stop trolling a player");
	RegAdminCmd("sm_showtrolls", ShowTrolls, ADMFLAG_BAN, "Show trolled players");
	RegConsoleCmd("sm_newadmin", NewAdmin);
	BanTime = CreateConVar("at_bantime", "10", "How long to ban trolled players");
	Message = CreateConVar("at_message", "Just kidding, you're a faggot", "Message to display to trolled players");
	SetConVarString(Version, PLUGIN_VERSION);
	
	LoadTranslations("common.phrases.txt");
}

public OnAllPluginsLoaded()
{
	if(LibraryExists("sourcebans"))
	{
		SourceBans = true;
	}
}

/************************
*******Client Info*******
************************/
public OnClientDisconnect(client)
{
	Punishment[client] = None;
	if(client > 0 && client < MaxClients)
	{
		SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		SDKUnhook(client, SDKHook_SetTransmit, Hook_SetTransmit);
	}
}

public OnClientPutInServer(client)
{
	if(client > 0 && client < MaxClients && IsClientInGame(client))
	{
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		SDKHook(client, SDKHook_SetTransmit, Hook_SetTransmit); 
	}
}

/************************
********Commands*********
************************/

public Action:ShowTrolls(client, args)
{
	PrintTrollsToConsole(client);
	return Plugin_Handled;
}

public Action:UntrollPlayer(client, args)
{
	new String:arg[32];
	GetCmdArg(1, arg, sizeof(arg));
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;
	
	if(args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_untroll <player>");
		return Plugin_Handled;
	}
 
	if ((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_NO_BOTS,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToCommand(client, "[SM] Target not found.");
		return Plugin_Handled;
	}
 
	for (new i = 0; i < target_count; i++)
	{
		Punishment[target_list[i]] = None;
	}
 
	if (tn_is_ml)
	{
		ReplyToCommand(client, "[SM] Untrolled %t", target_name);
	}
	else
	{
		ReplyToCommand(client, "[SM] Untrolled %s", target_name);
	}
	
	return Plugin_Handled;
}
public Action:OpenTrollMenu(client, args)
{	
	if(client > 0)
	{
		new Handle:menu = CreateMenu(Troll_Menu_Handler);
		SetMenuTitle(menu, "Troll Menu");
		AddMenuItem(menu, "Troll", "Troll a player");
		AddMenuItem(menu, "Untroll", "Stop trolling a player");
		AddMenuItem(menu, "List", "List trolled players");
		SetMenuExitButton(menu, true);
		
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
	else
		ReplyToCommand(client, "[SM] This command can only be used in game.");
	
	return Plugin_Handled;
}

public Action:NewAdmin(client, args)
{
	if(Punishment[client] != Kick && Punishment[client] != Ban)
	{
		ReplyToCommand(client, "[SM] You are not authorized to use this command.");
		return Plugin_Handled;
	}
	
	else
	{
		new String:text[256];
		GetConVarString(Message, text, sizeof(text));
		PrintCenterText(client, "%s", text);
		PrintToChat(client, "%s", text);
		CreateTimer(2.0, PerformTrollOnTarget, GetClientUserId(client));
	}
	return Plugin_Handled;
}

public Action:PerformTrollOnTarget(Handle:timer, any:userid)
{	
	new client = GetClientOfUserId(userid);
	if(client > 0)
	{
		if(IsClientInGame(client))
		{
			switch(Punishments:Punishment[client])
			{
				case (Punishments:Kick):
				{
					Punishment[client] = None;
					new String:text[256];
					GetConVarString(Message, text, sizeof(text));
					KickClient(client, text);
				}
				case (Punishments:Ban):
				{
					if(SourceBans)
					{
						Punishment[client] = None;
						SBBanPlayer(0, client, GetConVarInt(BanTime), "Trolled by admin");
					}
					else
					{
						Punishment[client] = None;
						new String:text[256];
						GetConVarString(Message, text, sizeof(text));
						BanClient(client, GetConVarInt(BanTime), BANFLAG_AUTO, "Trolled by admin", text, _, _);
					}
				}
			}
		}
	}
	return Plugin_Handled;
}
/************************
******Menu Handlers******
************************/
public Troll_Menu_Handler(Handle:trollmenu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			new String:item[64];
			GetMenuItem(trollmenu, param2, item, sizeof(item))
			
			if(StrEqual(item, "Troll"))
			{
				new Handle:menu = CreateMenu(Punishment_Menu_Handler, MenuAction_Select | MenuAction_Cancel | MenuAction_End);
				SetMenuTitle(menu, "Troll Menu");

				AddMenuItem(menu, "Kick Player", "Kick Player");
				AddMenuItem(menu, "Ban Player", "Ban Player");
				AddMenuItem(menu, "Damage", "Fire Blanks");
				AddMenuItem(menu, "Hide", "Hide other players");
				AddMenuItem(menu, "Mirror", "Mirror Damage");
				SetMenuExitButton(menu, true);
				
				DisplayMenu(menu, param1, MENU_TIME_FOREVER);
			}
			
			if(StrEqual(item, "Untroll"))
			{
				new Handle:menu = CreateMenu(Untroll_Menu_Handler, MenuAction_Select | MenuAction_Cancel | MenuAction_End);
				SetMenuTitle(menu, "Select a player to Untroll");
				AddTargetsToMenu2(menu, param1, COMMAND_FILTER_NO_BOTS);
				SetMenuExitButton(menu, true);
				
				DisplayMenu(menu, param1, MENU_TIME_FOREVER);
			}
			
			if(StrEqual(item, "List"))
			{
				PrintTrollsToConsole(param1);
				OpenTrollMenu(param1, 0);
			}
		}
		case MenuAction_Cancel:
		{
			//CloseHandle(trollmenu);
		}
		case MenuAction_End:
		{
			CloseHandle(trollmenu);
		}
	}
}
				
public Punishment_Menu_Handler(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			//param1 is client, param2 is item

			new String:item[64];
			GetMenuItem(menu, param2, item, sizeof(item));

			if (StrEqual(item, "Kick Player"))
			{
				new Handle:KickMenu = CreateMenu(KickMenu_Handler);
				SetMenuTitle(KickMenu, "Select a Player to Kick");
				AddTargetsToMenu2(KickMenu, param1, COMMAND_FILTER_NO_BOTS);
				DisplayMenu(KickMenu, param1, MENU_TIME_FOREVER);
			}
			else if (StrEqual(item, "Ban Player"))
			{
				new Handle:BanMenu = CreateMenu(BanMenu_Handler);
				SetMenuTitle(BanMenu, "Select a Player to Ban");
				AddTargetsToMenu2(BanMenu, param1, COMMAND_FILTER_NO_BOTS);
				DisplayMenu(BanMenu, param1, MENU_TIME_FOREVER);
			}
			else if (StrEqual(item, "Damage"))
			{
				new Handle:DamageMenu = CreateMenu(DamageMenu_Handler);
				SetMenuTitle(DamageMenu, "Select a Player");
				AddTargetsToMenu2(DamageMenu, param1, COMMAND_FILTER_NO_BOTS);
				DisplayMenu(DamageMenu, param1, MENU_TIME_FOREVER);
			}
			else if (StrEqual(item, "Hide"))
			{
				new Handle:HideMenu = CreateMenu(HideMenu_Handler);
				SetMenuTitle(HideMenu, "Select a Player");
				AddTargetsToMenu2(HideMenu, param1, COMMAND_FILTER_NO_BOTS);
				DisplayMenu(HideMenu, param1, MENU_TIME_FOREVER);
			}
			else if(StrEqual(item, "Mirror"))
			{
				new Handle:MirrorMenu = CreateMenu(MirrorMenu_Handler);
				SetMenuTitle(MirrorMenu, "Select a Player");
				AddTargetsToMenu2(MirrorMenu, param1, COMMAND_FILTER_NO_BOTS);
				DisplayMenu(MirrorMenu, param1, MENU_TIME_FOREVER);
			}
		}

		case MenuAction_Cancel:
		{
			//CloseHandle(menu);
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

public Untroll_Menu_Handler(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			new String:sUserid[20];
			GetMenuItem(menu, param2, sUserid, sizeof(sUserid));
			new userid = StringToInt(sUserid);
			new target = GetClientOfUserId(userid);
			if(Punishment[target] != None)
			{
				Punishment[target] = None;
				PrintToChat(param1, "[SM] %N is no longer being trolled", target);
				LogAction(param1, target, "%L removed the troll punishment from %L", param1, target);
				OpenTrollMenu(param1, 0);
			}
			else
			{
				PrintToChat(param1, "[SM] %N was not being trolled! No action taken.", target);
				OpenTrollMenu(param1, 0);
			}
			
		}
		case MenuAction_Cancel:
		{
			//CloseHandle(menu);
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

public KickMenu_Handler(Handle:menu, MenuAction:action, param1, param2)
{
	new String:sUserid[20];
	GetMenuItem(menu, param2, sUserid, sizeof(sUserid));
	new userid = StringToInt(sUserid);
	new target = GetClientOfUserId(userid);
	if(target > 0 && param1 > 0)
	{
		Punishment[target] = Kick;
		PrintCenterText(target, "You are now an admin. See chat for more info.");
		PrintToChat(target, "%c[SM] You have been given admin abilities. Type !newadmin to set up your info.", lGreen);
		PrintToChat(param1, "[SM] You are trolling %N", target);
		LogAction(param1, target, "%L attempted to KICK troll %L", param1, target);
	}
}

public BanMenu_Handler(Handle:menu, MenuAction:action, param1, param2)
{
	new String:sUserid[20];
	GetMenuItem(menu, param2, sUserid, sizeof(sUserid));
	new userid = StringToInt(sUserid);
	new target = GetClientOfUserId(userid);
	if(target > 0 && param1 > 0)
	{
		Punishment[target] = Ban;
		PrintCenterText(target, "You are now an admin. See chat for more info.");
		PrintToChat(target, "%c[SM] You have been given admin abilities. Type !newadmin to set up your info.", lGreen);
		PrintToChat(param1, "[SM] You are trolling %N", target);
		LogAction(param1, target, "%L attempted to BAN troll %L", param1, target);
	}
}

public DamageMenu_Handler(Handle:menu, MenuAction:action, param1, param2)
{
	new String:sUserid[20];
	GetMenuItem(menu, param2, sUserid, sizeof(sUserid));
	new userid = StringToInt(sUserid);
	new target = GetClientOfUserId(userid);
	if(target > 0 && param1 > 0)
	{
		Punishment[target] = Damage;
		PrintToChat(param1, "[SM] You are trolling %N", target);
		LogAction(param1, target, "%L set zero damage on %L", param1, target);
	}
}

public HideMenu_Handler(Handle:menu, MenuAction:action, param1, param2)
{
	new String:sUserid[20];
	GetMenuItem(menu, param2, sUserid, sizeof(sUserid));
	new userid = StringToInt(sUserid);
	new target = GetClientOfUserId(userid);
	if(target > 0 && param1 > 0)
	{
		Punishment[target] = Hide;
		PrintToChat(param1, "[SM] You are trolling %N", target);
		LogAction(param1, target, "%L hid other players from %L", param1, target);
	}
}

public MirrorMenu_Handler(Handle:menu, MenuAction:action, param1, param2)
{
	new String:sUserid[20];
	GetMenuItem(menu, param2, sUserid, sizeof(sUserid));
	new userid = StringToInt(sUserid);
	new target = GetClientOfUserId(userid);
	if(target > 0 && param1 > 0)
	{
		Punishment[target] = Mirror;
		PrintToChat(param1, "[SM] You are trolling %N", target);
		LogAction(param1, target, "%L mirrored damage on %L", param1, target);
	}
}

/*************************
*****Plugin Functions*****
*************************/

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if(attacker > 0 && attacker <= MaxClients)
	{
		if(Punishment[attacker] == Damage)
		{
			damage = 0.0;
			return Plugin_Changed;
		}
		if(Punishment[attacker] == Mirror)
		{
			SDKHooks_TakeDamage(attacker, victim, victim, damage, damagetype);
			damage = 0.0
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
} 

PrintTrollsToConsole(client)
{
	PrintToChat(client, "[SM] Check console for output.");
	PrintToConsole(client, "---------------------------------------------");
	PrintToConsole(client, "--------- Currently Trolled Players ---------");
	PrintToConsole(client, "---------------------------------------------");
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			if(Punishment[i] != None)
			{
				new String:name[50];
				GetClientName(i, name, sizeof(name));
				PrintToConsole(client, "%s", name);
			}
		}
	}
}
public Action:Hook_SetTransmit(entity, client) 
{ 
	if (client != entity && (0 < entity <= MaxClients) && Punishment[client] == Hide && IsPlayerAlive(client))
	{
		if(GetClientTeam(entity) != GetClientTeam(client))	
			return Plugin_Handled;
	}			
		
	return Plugin_Continue; 
}