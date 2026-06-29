#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#define MAX_ID			32

public Plugin:myinfo = 
{
	name		= "[HL2DM]Hrcbotmenu",
	author	  = "HL2gamer",
	description = "Hrcbot menu bots control hl2dm",
	version	 = "0.8beta",
	url		 = "https://forums.alliedmods.net/index.php"
}

new bool:g_bLog = false;
new Handle:g_Cvar_Enabled = INVALID_HANDLE;
new Handle: g_T_playaddbot;
new Handle: g_handicap;
new Handle: g_servermode;
new Handle: g_TNoTarget;
new Handle: g_TN_playautobot;
new Handle: g_servertuning;
new Handle: g_hrcbot_enabled;
new Handle: g_spawnweapon;
new Handle: g_Hrc1;
new g_Hrc1_position[MAXPLAYERS + 1];
new g_spawnweapon_position[MAXPLAYERS + 1];
Handle Timer_BotAd[MAXPLAYERS+1];

public OnPluginStart()
{
	g_Cvar_Enabled = CreateConVar("sm_allweapons", "0", "0 = Off | 1 = On -- spawn_allweapons Enabled",FCVAR_NOTIFY|FCVAR_SERVER_CAN_EXECUTE);
	AutoExecConfig(true, "HRCBOTMENU");
	HookEvent("player_spawn", playerSpawn, EventHookMode_Post);
	ServerCommand("sv_tags HRC_deathmath");
	ServerCommand("hrcbot_crowbarmaniacs 0");
	ServerCommand("mp_teamplay 0");
	ServerCommand("hrcbot_preferredcount 4");
	
	// RegAdminCmd("sm_4", Command_OpenMenu_T_playaddbot, ADMFLAG_GENERIC);
	// RegAdminCmd("sm_7", Command_OpenMenu_handicap, ADMFLAG_GENERIC);
	// RegAdminCmd("sm_1", Command_OpenMenu_servermode, ADMFLAG_GENERIC);
	// RegAdminCmd("sm_8", Command_OpenMenu_TNoTarget, ADMFLAG_GENERIC);
	// RegAdminCmd("sm_5", Command_OpenMenu_TN_playautobot, ADMFLAG_GENERIC);
	// RegAdminCmd("sm_2", Command_OpenMenu_servertuning, ADMFLAG_GENERIC);
	// RegAdminCmd("sm_3", Command_OpenMenu_hrcbot_enabled, ADMFLAG_GENERIC);
	// RegAdminCmd("sm_6", Command_OpenMenu_spawnweapon, ADMFLAG_GENERIC);
	RegAdminCmd("sm_hrc", Command_OpenMenu_Hrc1, ADMFLAG_GENERIC);
	RegAdminCmd("sm_sreload", Command_Reload, ADMFLAG_ROOT, "Reload server");
	RegAdminCmd("sm_remap",Command_Level, ADMFLAG_CHANGEMAP,"Reloads the current map");

	g_T_playaddbot = CreateMenu(Handler_T_playaddbot);
	SetMenuTitle(g_T_playaddbot, "1 ■ manual add bot team 2 \n( beware of robots full server - another player will not join the server / example 16/16 bad  15/16 ok)\n2 ■ manual kick bot team 2")
	AddMenuItem(g_T_playaddbot, "1", "hrcbot_add*")
	AddMenuItem(g_T_playaddbot, "2", "hrcbot_kick*")
	SetMenuExitBackButton(g_T_playaddbot, true);

	g_handicap = CreateMenu(Handler_handicap);
	SetMenuTitle(g_handicap, "■ *** bot handicap - 5 bot great aim >>>>>>>> 100 wrong aim")
	AddMenuItem(g_handicap, "1", "handicap 5")
	AddMenuItem(g_handicap, "2", "handicap 20")
	AddMenuItem(g_handicap, "3", "handicap 50")
	AddMenuItem(g_handicap, "4", "handicap 75")
	AddMenuItem(g_handicap, "5", "handicap 100")
	SetMenuExitBackButton(g_handicap, true);

	g_servermode = CreateMenu(Handler_servermode);
	SetMenuTitle(g_servermode, "1 ■ normal play deathmatch - only bot_preferredcount\n2 ■ team play - player vs bot - auto add join player count + manual add/kick bot\n3 ■ team play mix teams - only bot_preferredcount\n4 ■ team play FUN - player vs botZombie crowbar - auto add join player count + manual add/kick bot\n\n\n\n\n\n\n\n Hrcbotmenu v 0.8/beta\n forums.alliedmods.net")
	AddMenuItem(g_servermode, "1", "mp_teamplay 0")
	AddMenuItem(g_servermode, "2", "mp_teamplay 1")
	AddMenuItem(g_servermode, "3", "mp_teamplay 1 mix")
	AddMenuItem(g_servermode, "4", "mp_teamplay 1 fun")
	SetMenuExitBackButton(g_servermode, true);

	g_TNoTarget = CreateMenu(Handler_TNoTarget);
	SetMenuTitle(g_TNoTarget, "1 ■ bots shoot \n2 ■ bots not shoot*")
	AddMenuItem(g_TNoTarget, "1", "shoot")
	AddMenuItem(g_TNoTarget, "2", "don't shoot*")
	SetMenuExitBackButton(g_TNoTarget, true);

	g_TN_playautobot = CreateMenu(Handler_TN_playautobot);
	SetMenuTitle(g_TN_playautobot, "■ ***bot_preferredcount 1 >>>>> 15 \n(beware of robots full server - another player will not join the server / example *16/16 bad  *15/16 ok)")
	AddMenuItem(g_TN_playautobot, "1", "bot_count 1")
	AddMenuItem(g_TN_playautobot, "2", "bot_count 4")
	AddMenuItem(g_TN_playautobot, "3", "bot_count 8")
	AddMenuItem(g_TN_playautobot, "4", "bot_count 12")
	AddMenuItem(g_TN_playautobot, "5", "bot_count 15")
	SetMenuExitBackButton(g_TN_playautobot, true);

	g_servertuning = CreateMenu(Handler_servertuning);
	SetMenuTitle(g_servertuning, "1 ■ all_weapon_spawn - only players (no bot)**\n2 ■ physcanon max force + speed")
	AddMenuItem(g_servertuning, "1", "all_weapon_spawn**")
	AddMenuItem(g_servertuning, "2", "physcanon max")
	SetMenuExitBackButton(g_servertuning, true);

	g_hrcbot_enabled = CreateMenu(Handler_hrcbot_enabled);
	SetMenuTitle(g_hrcbot_enabled, "1 ■ manual bot_enabled /default -auto to new map...\n2 ■ manual bot_disabled")
	AddMenuItem(g_hrcbot_enabled, "1", "enabled ")
	AddMenuItem(g_hrcbot_enabled, "2", "disabled ")
	SetMenuExitBackButton(g_hrcbot_enabled, true);

	g_spawnweapon = CreateMenu(Handler_spawnweapon);
	SetMenuTitle(g_spawnweapon, "■ >>>> bot_spawnweapon /default smg1 - auto to next map...")
	AddMenuItem(g_spawnweapon, "1", "smg1")
	AddMenuItem(g_spawnweapon, "2", "AR2*")
	AddMenuItem(g_spawnweapon, "3", "rpg*")
	AddMenuItem(g_spawnweapon, "4", "357*")
	AddMenuItem(g_spawnweapon, "5", "frag*")
	AddMenuItem(g_spawnweapon, "6", "shotgun*")
	AddMenuItem(g_spawnweapon, "7", "crowbarmaniacs 1*")
	AddMenuItem(g_spawnweapon, "8", "crowbarmaniacs 0")
	SetMenuExitBackButton(g_spawnweapon, true);

	g_Hrc1 = CreateMenu(Handler_Hrc1);
	SetMenuTitle(g_Hrc1, "1 ■ mp_teamplay 0 / mp_teamplay 1 / mp_teamplay mix / mp_teamplay FUN BotZombie\n2 ■ all weapon spawn player(no bots) / physscanon max\n3 ■ bot enabled 1/0\n4 ■ Team add_bot/kick* - only mode mp_teamplay 1 / mp_teamplay 1 fun\n5 ■ bot_preferredcount - has this number of bots playing - only mode mp_teamplay 0 / mp_teamplay mix\n\n7 ■ >> ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■\n\n1 ■ bot spawn weapon - Sets the default spawn weapon of the bot\n2 ■ bot handicap - the bot strenght (aim accuracy) can now be reduced with this\n3 ■ bot shoot 1/0 - bot either shoots or doesn't shoot / walks\n4 ■ restart + retry - in 5 seconds restart the server and auto retry the connection of players\n\n  *//manually adding the number does not remember in the next map\n  **//member in the next map manually cvar 0/1 hl2mp/cfg/sourcemod/HRCBOTMENU.cfg")
	AddMenuItem(g_Hrc1, "1", "server mode")
	AddMenuItem(g_Hrc1, "2", "weapons_tuning**")
	AddMenuItem(g_Hrc1, "3", "bot_enabled 1/0*")
	AddMenuItem(g_Hrc1, "4", "Team add bot*")
	AddMenuItem(g_Hrc1, "5", "bot_preferredcount")
	AddMenuItem(g_Hrc1, "6", "bot spawnweapon*")
	AddMenuItem(g_Hrc1, "7", "bot handicap*")
	AddMenuItem(g_Hrc1, "8", "bots shoot 1/0*")
	AddMenuItem(g_Hrc1, "9", "[restart + retry]")
}
//-------------------------------------------------------------------------------------------
// default config settings start load map start omit server.cfg
public OnMapStart()
{
				PrecacheSound("buttons/blip1.wav", true);
				PrecacheSound("npc/roller/remote_yes.wav", true)
				
				ServerCommand("hrcbot_enabled 1");
				ServerCommand("hrcbot_autoweaponswitch 1");
				//ServerCommand("hrcbot_crowbarmaniacs 0");
				ServerCommand("hrcbot_minplayers 0");
				ServerCommand("hrcbot_maxplayers 14");
				//ServerCommand("hrcbot_preferredcount 4");
				ServerCommand("hrcbot_handicap 30");
				//ServerCommand("hrcbot_clan []");
				ServerCommand("hrcbot_dialogmsg 0");
				ServerCommand("hrcbot_mute 1");
				ServerCommand("hrcbot_motd 0");
				ServerCommand("hrcbot_player_spawnweapon smg1");
				ServerCommand("hrcbot_spawnprotectedhealth 500");
				ServerCommand("hrcbot_spawnprotectionseconds 1");
//	sm_parachute_msg		for all servers as a precaution against errors - optional
				ServerCommand("sm_parachute_msgtype 0");
				ServerCommand("sm_parachute_welcome 0");
				ServerCommand("sm_parachute_roundmsg 0");
//	set hostname start map - omit server.cfg hostname - optional
			//ServerCommand("hostname HL2DMgamer[HrcbotTest]");
	}

public OnClientPutInServer(client)
{
	CreateTimer(5.0, Timer_DelayConnectCommand, GetClientUserId(client));
}

public Action:Timer_DelayConnectCommand(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (client > 0 && client <= MaxClients && IsClientInGame(client))
	{
		FakeClientCommand(client, "sm_hrc");
	}
}

public Action:Command_OpenMenu_T_playaddbot(client, argc)
{
	DisplayMenu(g_T_playaddbot, client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}
public Action:Command_OpenMenu_handicap(client, argc)
{
	DisplayMenu(g_handicap, client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}
public Action:Command_OpenMenu_servermode(client, argc)
{
	DisplayMenu(g_servermode, client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}
public Action:Command_OpenMenu_TNoTarget(client, argc)
{
	DisplayMenu(g_TNoTarget, client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}
public Action:Command_OpenMenu_TN_playautobot(client, argc)
{
	DisplayMenu(g_TN_playautobot, client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}
public Action:Command_OpenMenu_servertuning(client, argc)
{
	DisplayMenu(g_servertuning, client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}
public Action:Command_OpenMenu_hrcbot_enabled(client, argc)
{
	DisplayMenu(g_hrcbot_enabled, client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}
public Action:Command_OpenMenu_spawnweapon(client, argc)
{
	DisplayMenu(g_spawnweapon, client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}
public Action:Command_OpenMenu_Hrc1(client, argc)
{
	DisplayMenu(g_Hrc1, client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public Handler_T_playaddbot(Handle:menu, MenuAction:action, client, slot)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			decl String:info[64];
			GetMenuItem(menu, slot, info, sizeof(info));
			
			if (StrEqual(info, "1"))
			{
				ServerCommand("hrcbot_add 2  ");
				DisplayMenu(g_T_playaddbot, client, MENU_TIME_FOREVER);
				EmitSoundToAll("npc/roller/remote_yes.wav");
			}
			else if (StrEqual(info, "2"))
			{
				ServerCommand("hrcbot_kick 2");
				DisplayMenu(g_T_playaddbot, client, MENU_TIME_FOREVER);
				EmitSoundToAll("npc/roller/remote_yes.wav");
			}
		}
		case MenuAction_Cancel:
		{
			if (slot == MenuCancel_ExitBack)
			{
				DisplayMenuAtItem(g_Hrc1, client, g_Hrc1_position[client], MENU_TIME_FOREVER);
			}
		}
	}
}

public Handler_handicap(Handle:menu, MenuAction:action, client, slot)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			decl String:info[64];
			GetMenuItem(menu, slot, info, sizeof(info));
			
			if (StrEqual(info, "1"))
			{
				ServerCommand("hrcbot_handicap 5");
				DisplayMenu(g_handicap, client, MENU_TIME_FOREVER);
			}
			else if (StrEqual(info, "2"))
			{
				ServerCommand("hrcbot_handicap 20");
				DisplayMenu(g_handicap, client, MENU_TIME_FOREVER);
			}
			else if (StrEqual(info, "3"))
			{
				ServerCommand("hrcbot_handicap 50");
				DisplayMenu(g_handicap, client, MENU_TIME_FOREVER);
			}
			else if (StrEqual(info, "4"))
			{
				ServerCommand("hrcbot_handicap 75");
				DisplayMenu(g_handicap, client, MENU_TIME_FOREVER);
			}
			else if (StrEqual(info, "5"))
			{
				ServerCommand("hrcbot_handicap 100");
				DisplayMenu(g_handicap, client, MENU_TIME_FOREVER);
			}
		}
		case MenuAction_Cancel:
		{
			if (slot == MenuCancel_ExitBack)
			{
				DisplayMenuAtItem(g_Hrc1, client, g_Hrc1_position[client], MENU_TIME_FOREVER);
			}
		}
	}
}

public Handler_servermode(Handle:menu, MenuAction:action, client, slot)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			decl String:info[64];
			GetMenuItem(menu, slot, info, sizeof(info));
			
			if (StrEqual(info, "1"))
			{
				ServerCommand("mp_teamplay 0; sm_remap; hrcbot_autobalancebots 1; hrcbot_enabled 1; hrcbot_crowbarmaniacs 0");
			}
			else if (StrEqual(info, "2"))
			{
				ServerCommand("mp_teamplay 1; sm_remap; hrcbot_autobalancebots 0; hrcbot_enabled 1; hrcbot_crowbarmaniacs 0");
			}
			else if (StrEqual(info, "3"))
			{
				ServerCommand("mp_teamplay 1; sm_remap; hrcbot_autobalancebots 1; hrcbot_enabled 1; hrcbot_crowbarmaniacs 0");
			}
			else if (StrEqual(info, "4"))
			{
				ServerCommand("mp_teamplay 1; sm_remap; hrcbot_autobalancebots 0; hrcbot_enabled 1; hrcbot_crowbarmaniacs 1");
			}
		}
		case MenuAction_Cancel:
		{
			if (slot == MenuCancel_ExitBack)
			{
				DisplayMenuAtItem(g_Hrc1, client, g_Hrc1_position[client], MENU_TIME_FOREVER);
			}
		}
	}
}


public Handler_TNoTarget(Handle:menu, MenuAction:action, client, slot)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			decl String:info[64];
			GetMenuItem(menu, slot, info, sizeof(info));
			
			if (StrEqual(info, "1"))
			{
				ServerCommand("hrcbot_spawnprotectedhealth 500 ");
				DisplayMenu(g_TNoTarget, client, MENU_TIME_FOREVER);
				PrintToChatAll("bots shoot all")
				EmitSoundToAll("buttons/blip1.wav");
				
			}
			else if (StrEqual(info, "2"))
			{
				ServerCommand("hrcbot_spawnprotectedhealth 1");
				DisplayMenu(g_TNoTarget, client, MENU_TIME_FOREVER);
				PrintToChatAll("bots don't shoot all")
				EmitSoundToAll("buttons/blip1.wav");
				

			}
		}
		case MenuAction_Cancel:
		{
			if (slot == MenuCancel_ExitBack)
			{
				DisplayMenuAtItem(g_Hrc1, client, g_Hrc1_position[client], MENU_TIME_FOREVER);
			}
		}
	}
}

public Handler_TN_playautobot(Handle:menu, MenuAction:action, client, slot)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			decl String:info[64];
			GetMenuItem(menu, slot, info, sizeof(info));
			
			if (StrEqual(info, "1"))
			{
				ServerCommand("hrcbot_preferredcount 1");
				DisplayMenu(g_TN_playautobot, client, MENU_TIME_FOREVER);
			}
			else if (StrEqual(info, "2"))
			{
				ServerCommand("hrcbot_preferredcount 4");
				DisplayMenu(g_TN_playautobot, client, MENU_TIME_FOREVER);
			}
			else if (StrEqual(info, "3"))
			{
				ServerCommand("hrcbot_preferredcount 8");
				DisplayMenu(g_TN_playautobot, client, MENU_TIME_FOREVER);
			}
			else if (StrEqual(info, "4"))
			{
				ServerCommand("hrcbot_preferredcount 12");
				DisplayMenu(g_TN_playautobot, client, MENU_TIME_FOREVER);
			}
			else if (StrEqual(info, "5"))
			{
				ServerCommand("hrcbot_preferredcount 15");
				DisplayMenu(g_TN_playautobot, client, MENU_TIME_FOREVER);
			}
		}
		case MenuAction_Cancel:
		{
			if (slot == MenuCancel_ExitBack)
			{
				DisplayMenuAtItem(g_Hrc1, client, g_Hrc1_position[client], MENU_TIME_FOREVER);
			}
		}
	}
}

public Handler_servertuning(Handle:menu, MenuAction:action, client, slot)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			decl String:info[64];
			GetMenuItem(menu, slot, info, sizeof(info));
			
			if (StrEqual(info, "1"))
			{
				ServerCommand("sm_allweapons 1; sm_cvar sv_hl2mp_item_respawn_time 5; sm_cvar sv_hl2mp_weapon_respawn_time 5");
				DisplayMenu(g_servertuning, client, MENU_TIME_FOREVER);
				PrintToChatAll("(((( all weapon spawn player ))))")
				PrintCenterTextAll("(((( all weapon spawn player ))))")
				EmitSoundToAll("npc/roller/remote_yes.wav");
			}
			else if (StrEqual(info, "2"))
			{
				ServerCommand("sm_cvar physcannon_maxforce 900000; sm_cvar physcannon_maxmass 9000; sm_cvar physcannon_tracelength 9000");
				DisplayMenu(g_servertuning, client, MENU_TIME_FOREVER);
				PrintToChatAll("(((( physcannon max all players ))))")
				PrintCenterTextAll("(((( physcannon max all players ))))")
				EmitSoundToAll("npc/roller/remote_yes.wav");
			}
		}
		case MenuAction_Cancel:
		{
			if (slot == MenuCancel_ExitBack)
			{
				DisplayMenuAtItem(g_Hrc1, client, g_Hrc1_position[client], MENU_TIME_FOREVER);
			}
		}
	}
}

public Handler_hrcbot_enabled(Handle:menu, MenuAction:action, client, slot)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			decl String:info[64];
			GetMenuItem(menu, slot, info, sizeof(info));
			
			if (StrEqual(info, "1"))
			{
				ServerCommand("hrcbot_enabled 1");
				DisplayMenu(g_hrcbot_enabled, client, MENU_TIME_FOREVER);
				PrintToChatAll("(((( bots enabled ))))")
				PrintCenterTextAll("(((( bots enabled ))))")
				EmitSoundToAll("npc/roller/remote_yes.wav");
			}
			else if (StrEqual(info, "2"))
			{
				ServerCommand("hrcbot_enabled 0");
				DisplayMenu(g_hrcbot_enabled, client, MENU_TIME_FOREVER);
				PrintToChatAll("(((( bots disabled ))))")
				PrintCenterTextAll("(((( bots disabled ))))")
				EmitSoundToAll("npc/roller/remote_yes.wav");
			}
		}
		case MenuAction_Cancel:
		{
			if (slot == MenuCancel_ExitBack)
			{
				DisplayMenuAtItem(g_Hrc1, client, g_Hrc1_position[client], MENU_TIME_FOREVER);
			}
		}
	}
}

public Handler_spawnweapon(Handle:menu, MenuAction:action, client, slot)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			decl String:info[64];
			GetMenuItem(menu, slot, info, sizeof(info));
			
			if (StrEqual(info, "1"))
			{
				ServerCommand("hrcbot_player_spawnweapon smg1");
				g_spawnweapon_position[client] = GetMenuSelectionPosition();
				DisplayMenu(g_spawnweapon, client, MENU_TIME_FOREVER);
			}
			else if (StrEqual(info, "2"))
			{
				ServerCommand("hrcbot_player_spawnweapon AR2");
				g_spawnweapon_position[client] = GetMenuSelectionPosition();
				DisplayMenu(g_spawnweapon, client, MENU_TIME_FOREVER);
			}
			else if (StrEqual(info, "3"))
			{
				ServerCommand("hrcbot_player_spawnweapon rpg");
				g_spawnweapon_position[client] = GetMenuSelectionPosition();
				DisplayMenu(g_spawnweapon, client, MENU_TIME_FOREVER);
			}
			else if (StrEqual(info, "4"))
			{
				ServerCommand("hrcbot_player_spawnweapon 357");
				g_spawnweapon_position[client] = GetMenuSelectionPosition();
				DisplayMenu(g_spawnweapon, client, MENU_TIME_FOREVER);
			}
			else if (StrEqual(info, "5"))
			{
				ServerCommand("hrcbot_player_spawnweapon frag");
				g_spawnweapon_position[client] = GetMenuSelectionPosition();
				DisplayMenu(g_spawnweapon, client, MENU_TIME_FOREVER);
			}
			else if (StrEqual(info, "6"))
			{
				ServerCommand("hrcbot_player_spawnweapon shotgun");
				g_spawnweapon_position[client] = GetMenuSelectionPosition();
				DisplayMenu(g_spawnweapon, client, MENU_TIME_FOREVER);
			}
			else if (StrEqual(info, "7"))
			{
				ServerCommand("hrcbot_crowbarmaniacs 1");
				g_spawnweapon_position[client] = GetMenuSelectionPosition();
				DisplayMenu(g_spawnweapon, client, MENU_TIME_FOREVER);
			}
			else if (StrEqual(info, "8"))
			{
				ServerCommand("hrcbot_crowbarmaniacs 0");
				g_spawnweapon_position[client] = GetMenuSelectionPosition();
				DisplayMenu(g_spawnweapon, client, MENU_TIME_FOREVER);
			}
		}
		case MenuAction_Cancel:
		{
			if (slot == MenuCancel_ExitBack)
			{
				DisplayMenuAtItem(g_Hrc1, client, g_Hrc1_position[client], MENU_TIME_FOREVER);
			}
		}
	}
}

public Handler_Hrc1(Handle:menu, MenuAction:action, client, slot)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			decl String:info[64];
			GetMenuItem(menu, slot, info, sizeof(info));
			
			if (StrEqual(info, "1"))
			{
				g_Hrc1_position[client] = GetMenuSelectionPosition();
				DisplayMenu(g_servermode, client, MENU_TIME_FOREVER);
			}
			else if (StrEqual(info, "2"))
			{
				g_Hrc1_position[client] = GetMenuSelectionPosition();
				DisplayMenu(g_servertuning, client, MENU_TIME_FOREVER);
			}
			else if (StrEqual(info, "3"))
			{
				g_Hrc1_position[client] = GetMenuSelectionPosition();
				DisplayMenu(g_hrcbot_enabled, client, MENU_TIME_FOREVER);
			}
			else if (StrEqual(info, "4"))
			{
				g_Hrc1_position[client] = GetMenuSelectionPosition();
				DisplayMenu(g_T_playaddbot, client, MENU_TIME_FOREVER);
			}
			else if (StrEqual(info, "5"))
			{
				g_Hrc1_position[client] = GetMenuSelectionPosition();
				DisplayMenu(g_TN_playautobot, client, MENU_TIME_FOREVER);
			}
			else if (StrEqual(info, "6"))
			{
				g_Hrc1_position[client] = GetMenuSelectionPosition();
				DisplayMenu(g_spawnweapon, client, MENU_TIME_FOREVER);
			}
			else if (StrEqual(info, "7"))
			{
				g_Hrc1_position[client] = GetMenuSelectionPosition();
				DisplayMenu(g_handicap, client, MENU_TIME_FOREVER);
			}
			else if (StrEqual(info, "8"))
			{
				g_Hrc1_position[client] = GetMenuSelectionPosition();
				DisplayMenu(g_TNoTarget, client, MENU_TIME_FOREVER);
			}
			else if (StrEqual(info, "9"))
			{
				FakeClientCommand(client, "sm_sreload");
				EmitSoundToAll("npc/roller/remote_yes.wav");
			}
		}
	}
}
//--------------------------------------------------------------------------------------------------------------------------
// add weapons players /timer
public Action:playerSpawn(Handle:event, const String:name[], bool:dontBroadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsClientInGame(client) && IsClientAuthorized(client) && IsPlayerAlive(client) && !IsFakeClient(client))
	CreateTimer(2.0, giveItems, client);
	CloseHandle(event);
	return Plugin_Continue;
}

public Action:giveItems(Handle:timer, any:client)
{
	if (GetConVarFloat(g_Cvar_Enabled))
	{
	GivePlayerItem(client, "weapon_357");
	GivePlayerItem(client, "weapon_shotgun");
	GivePlayerItem(client, "weapon_crossbow");
	GivePlayerItem(client, "weapon_ar2");
	GivePlayerItem(client, "weapon_rpg");
	GivePlayerItem(client, "weapon_frag");
	GivePlayerItem(client, "item_ammo_ar2_altfire");
	GivePlayerItem(client, "item_ammo_smg1_grenade");
	GivePlayerItem(client, "weapon_slam");
	}
	return Plugin_Handled;
}
//-----------------------------------------------------------------------------------------------------------------------
// bot add - kick
public void OnClientPostAdminCheck(int client)
{
	//if(!IsFakeClient(client))
	//ServerCommand("hrcbot_add 2");
	ClientCommand(client, "jointeam 3");
	if(!IsFakeClient(client))
	Timer_BotAd[client] = CreateTimer(3.0, BotAd, client);
}

public Action BotAd(Handle timer, int client)
{
	if(!IsFakeClient(client))
	ServerCommand("hrcbot_add 2");
	if(!IsFakeClient(client))
	Timer_BotAd[client] = null;
}

public void OnClientDisconnect(int client)
{
	if(!IsFakeClient(client))
	delete Timer_BotAd[client];
	if(!IsFakeClient(client))
	ServerCommand("hrcbot_kick 2");
}

public Action:Command_Level(client, args)
{
	new String:map[128]; 
	GetCurrentMap(map, sizeof(map));
	
	ForceChangeLevel(map, "sm_remap Command");
	
	return Plugin_Handled;
}
//-------------------------------------------------------------------------------------------------------------------------
//restart server 5 s				author = 3sigma", // aka X@IDER
public Action:Command_Reload(client, args)
{
	new Float:to = 5.0;
	if (args)
	{
		decl String:ax[MAX_ID];
		GetCmdArg(1, ax, sizeof(ax));
		to = StringToFloat(ax);
	}
	PrintToChatAll("(((( server restart in 5 seconds ))))");
	PrintCenterTextAll("(((( server restart in 5 seconds ))))");
	if (g_bLog) LogAction(client, -1, "\"%L\" shuts down the server in %.1f seconds", client, to);
	CreateTimer(to, Reload);
	return Plugin_Handled;
}
//------------------------------------------------------------------------------------------------------------------------------------
public Action:Reload(Handle:timer)
{
	for (new i = 1; i <= MaxClients; i++)
	if (IsClientInGame(i) && !IsFakeClient(i)) ClientCommand(i, "retry; retry; retry; retry");
	
	InsertServerCommand("quit");
	ServerExecute();
	return Plugin_Handled;
}