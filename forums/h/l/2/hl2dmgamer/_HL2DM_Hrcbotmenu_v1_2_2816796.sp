#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <entity>
#include <clients>
#define MAX_ID			32

//--------ver.09beta add sound spawn bots, add map menu buton
//--------ver.1.0  add mod high kill, no suicide dead frags - function
//--------ver.1.1  notify clear
//--------ver.1.2  fix high kill chat spam

public Plugin:myinfo = 
{
	name		= "[HL2DM]Hrcbotmenu",
	author	  = "HL2gamer",
	description = "Hrcbot menu bots control - weapons hl2dm",
	version	 = "1.2",
	url		 = "https://forums.alliedmods.net/index.php"
}

new bool:g_bLog = false;
new Handle:g_Cvar_Enabled = INVALID_HANDLE;
new Handle:g_Cvar_Enabled1 = INVALID_HANDLE;
//new Handle:g_cvar_Enabled3 = INVALID_HANDLE;
//new Handle:g_cvar_Enabled4 = INVALID_HANDLE;
new Handle: g_T_playaddbot;
new Handle: g_handicap;
new Handle: g_servermode;
new Handle: g_TNoTarget;
new Handle: g_TN_playautobot;
new Handle: g_servertuning;
new Handle: g_hrcbot_enabled;
new Handle: g_spawnweapon;
new Handle: g_Hrc1;
Menu g_MapMenu = null;
new g_Hrc1_position[MAXPLAYERS + 1];
new g_spawnweapon_position[MAXPLAYERS + 1];
Handle Timer_BotAd[MAXPLAYERS+1];

public OnPluginStart()
{
	g_Cvar_Enabled = CreateConVar("sm_allweapons", "0", "0 = Off | 1 = On -- spawn_allweapons Enabled",FCVAR_SERVER_CAN_EXECUTE);
	g_Cvar_Enabled1= CreateConVar("sm_hrcmenu_autoshow", "1", "0 = Off | 1 = On -- hrcmenu_auto Enabled",FCVAR_SERVER_CAN_EXECUTE);
	
	AutoExecConfig(true, "HRCBOTMENU 1.2");
	HookEvent("player_spawn", playerSpawn, EventHookMode_Post);
	if(!HookEventEx("player_death", Event_Death)){
	SetFailState("Can't hook event 'player_death'. This game/mod doesn't support it");
	}
	RegConsoleCmd("rtv1", Command_ChangeMap);
	
	ServerCommand("sv_tags HRC_deathmath");
	ServerCommand("hrcbot_crowbarmaniacs 0");
	ServerCommand("mp_teamplay 0");
	ServerCommand("hrcbot_preferredcount 4");
	
	RegAdminCmd("sm_hrc", Command_OpenMenu_Hrc1, ADMFLAG_GENERIC);
	RegAdminCmd("sm_sreload", Command_Reload, ADMFLAG_ROOT, "Reload server");
	RegAdminCmd("sm_remap",Command_Level, ADMFLAG_CHANGEMAP,"Reloads the current map");
	RegAdminCmd("sm_highkill",High_Kill, ADMFLAG_GENERIC,"highkill");
	RegAdminCmd("sm_killdefault",High_Kill1, ADMFLAG_GENERIC,"killdefault");

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
	SetMenuTitle(g_servermode, "1 ■ normal play deathmatch - only bot_preferredcount\n2 ■ team play - player vs bot - auto add join player count + manual add/kick bot\n3 ■ team play mix teams - only bot_preferredcount\n4 ■ team play FUN - player vs botZombie crowbar - auto add join player count + manual add/kick bot\n\n\n\n\n\n\n\n Hrcbotmenu v 1.1\n forums.alliedmods.net")
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
	AddMenuItem(g_servertuning, "3", "high kill /1")
	AddMenuItem(g_servertuning, "4", "high kill /0")
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
	SetMenuTitle(g_Hrc1, "1 ■ mp_teamplay 0 / mp_teamplay 1 / mp_teamplay mix / mp_teamplay FUN BotZombie\n2 ■ all weapon spawn player(no bots) / physscanon max\n3 ■ bot enabled 1/0\n4 ■ Team add_bot/kick* - only mode mp_teamplay 1 / mp_teamplay 1 fun\n5 ■ bot_preferredcount - has this number of bots playing - only mode mp_teamplay 0 / mp_teamplay mix\n\n7 ■ >> ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■\n\n1 ■ bot spawn weapon - Sets the default spawn weapon of the bot\n2 ■ bot handicap - the bot strenght (aim accuracy) can now be reduced with this\n3 ■ bot shoot 1/0 - bot either shoots or doesn't shoot / walks\n4 ■ restart + retry - in 5s restart the server+auto retry\n5 ■ map_menu - mapcycle.txt /root\n\n  *//manually adding the number does not remember in the next map\n  **//member in the next map manually cvar 0/1 hl2mp/cfg/sourcemod/HRCBOTMENU.cfg")
	AddMenuItem(g_Hrc1, "1", "server mode")
	AddMenuItem(g_Hrc1, "2", "weapons_tuning**")
	AddMenuItem(g_Hrc1, "3", "bot_enabled 1/0*")
	AddMenuItem(g_Hrc1, "4", "Team add bot*")
	AddMenuItem(g_Hrc1, "5", "bot_preferredcount")
	AddMenuItem(g_Hrc1, "6", "bot spawnweapon*")
	AddMenuItem(g_Hrc1, "7", "bot handicap*")
	AddMenuItem(g_Hrc1, "8", "bots shoot 1/0*")
	AddMenuItem(g_Hrc1, "9", "[restart + retry]")
	AddMenuItem(g_Hrc1, "10", "[map_menu]")
}

// default config settings start load map start omit server.cfg ---------------------------------------

public OnMapStart()
{
				g_MapMenu = BuildMapMenu();
				PrecacheSound("buttons/blip1.wav", true);
				PrecacheSound("npc/roller/remote_yes.wav", true)
				PrecacheSound("weapons/explode3.wav", true)
				PrecacheSound("ambient/alarms/klaxon1.wav", true);
				PrecacheSound("npc/combine_soldier/vo/off1.wav", true);

				//all
				ServerCommand("hrcbot_enabled 1");
				ServerCommand("hrcbot_autoweaponswitch 1");
				//ServerCommand("hrcbot_crowbarmaniacs 0");
				ServerCommand("hrcbot_minplayers 1");
				ServerCommand("hrcbot_maxplayers 9");
				//ServerCommand("hrcbot_preferredcount 4");
				ServerCommand("hrcbot_handicap 30");
				//ServerCommand("hrcbot_clan []");
				ServerCommand("hrcbot_dialogmsg 0");
				ServerCommand("hrcbot_mute 1");
				ServerCommand("hrcbot_motd 0");
				ServerCommand("hrcbot_player_spawnweapon smg1");
				ServerCommand("hrcbot_spawnprotectedhealth 500");
				ServerCommand("hrcbot_spawnprotectionseconds 1");

			//sm_parachute_msg		for all servers as a precaution against errors - optional
				ServerCommand("sm_parachute_msgtype 0");
				ServerCommand("sm_parachute_welcome 0");
				ServerCommand("sm_parachute_roundmsg 0");

			//set hostname start map - omit server.cfg hostname - optional
			//ServerCommand("hostname HL2DMgamer[HrcbotTest]");
	}

public void OnMapEnd()
{
	delete g_MapMenu;
}

public Action:OnMapVoteStarted()
{
	EmitSoundToAll("ambient/alarms/klaxon1.wav");
}

public OnClientPutInServer(client)
{
	CreateTimer(5.0, Timer_DelayConnectCommand, GetClientUserId(client));
}

public Action:Timer_DelayConnectCommand(Handle:timer, any:userid)
{
	if (GetConVarFloat(g_Cvar_Enabled1))
	{
	new client = GetClientOfUserId(userid);
	if (client > 0 && client <= MaxClients && IsClientInGame(client))
		{
		FakeClientCommand(client, "sm_hrc");
		}
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
				EmitSoundToAll("weapons/explode3.wav");
			}
			else if (StrEqual(info, "2"))
			{
				ServerCommand("hrcbot_kick 2");
				DisplayMenu(g_T_playaddbot, client, MENU_TIME_FOREVER);
				EmitSoundToAll("npc/roller/remote_yes.wav");
				EmitSoundToAll("weapons/explode3.wav");
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
				ServerCommand(" mp_teamplay 1; sm_remap; hrcbot_autobalancebots 0; hrcbot_enabled 1; hrcbot_crowbarmaniacs 1");
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
				ServerCommand("sm_allweapons 1");
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
			else if (StrEqual(info, "3"))
			{
				ClientCommand(client,"sm_highkill");
				DisplayMenu(g_servertuning, client, MENU_TIME_FOREVER);
				PrintToChatAll("(((( high kill enabled ))))")
				PrintCenterTextAll("(((( high kill enabled ))))")
				EmitSoundToAll("npc/roller/remote_yes.wav");
			}
			else if (StrEqual(info, "4"))
			{
				ClientCommand(client,"sm_killdefault");
				DisplayMenu(g_servertuning, client, MENU_TIME_FOREVER);
				PrintToChatAll("(((( high kill disabled ))))")
				PrintCenterTextAll("(((( high kill disabled ))))")
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
			else if (StrEqual(info, "10"))
			{
				FakeClientCommand(client, "rtv1");
				PrintToChatAll("(((( selected next map ))))")
				EmitSoundToAll("ambient/alarms/klaxon1.wav");
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
	CreateTimer(1.0, giveItems, client);
	CloseHandle(event);
	return Plugin_Continue;
}

public Action:giveItems(Handle:timer, any:client)
{
	if (GetConVarFloat(g_Cvar_Enabled))
	{
	if(IsClientInGame(client) && IsClientAuthorized(client) && IsPlayerAlive(client) && !IsFakeClient(client))
	GivePlayerItem(client, "weapon_physcannon");
	GivePlayerItem(client, "weapon_stunstick");
	GivePlayerItem(client, "weapon_357");
	GivePlayerItem(client, "weapon_shotgun");
	GivePlayerItem(client, "weapon_crossbow");
	GivePlayerItem(client, "weapon_ar2");
	GivePlayerItem(client, "weapon_rpg");
	GivePlayerItem(client, "weapon_frag");
	GivePlayerItem(client, "item_ammo_ar2_altfire");
	GivePlayerItem(client, "item_ammo_ar2_altfire");
	GivePlayerItem(client, "item_ammo_smg1_grenade");
	GivePlayerItem(client, "item_ammo_smg1_grenade");
	GivePlayerItem(client, "weapon_slam");
	GivePlayerItem(client, "weapon_pistol");
	}
	return Plugin_Handled;
}

//-----------------------------------------------------------------------------------------------------------------------
// bot add - kick

public void OnClientPostAdminCheck(int client)
{
	ClientCommand(client, "jointeam 3");
	if(!IsFakeClient(client))
	Timer_BotAd[client] = CreateTimer(3.0, BotAd, client);
}

public void OnClientConnected(int client)
{
	if(IsFakeClient(client))
	EmitSoundToAll("npc/roller/remote_yes.wav");
	if(IsFakeClient(client))
	EmitSoundToAll("weapons/explode3.wav");
	if(!IsFakeClient(client))
	EmitSoundToAll("npc/combine_soldier/vo/off1.wav");
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

public Action:Reload(Handle:timer)
{
	for (new i = 1; i <= MaxClients; i++)
	if (IsClientInGame(i) && !IsFakeClient(i)) ClientCommand(i, "retry");
	
	InsertServerCommand("quit");
	ServerExecute();
	return Plugin_Handled;
}

// -----Map Menu-------------------------------------------------------------------------------

Menu BuildMapMenu()
{
	/* Open the file */
	File file = OpenFile("mapcycle.txt", "rt");
	if (file == null)
	{
		return null;
	}

	/* Create the menu Handle */
	Menu menu = new Menu(Menu_ChangeMap);
	char mapname[255];
	while (!file.EndOfFile() && file.ReadLine(mapname, sizeof(mapname)))
	{
		if (mapname[0] == ';' || !IsCharAlpha(mapname[0]))
		{
			continue;
		}

		/* Cut off the name at any whitespace */
		int len = strlen(mapname);
		for (int i = 0; i < len; i++)
		{
			if (IsCharSpace(mapname[i]))
			{
				mapname[i] = '\0';
				break;
			}
		}

		/* Check if the map is valid */
		if (!IsMapValid(mapname))
		{
			continue;
		}

		/* Add it to the menu */
		menu.AddItem(mapname, mapname);
	}

	/* Make sure we close the file! */
	file.Close();

	/* Finally, set the title */
	menu.SetTitle("Please select a map:");
 
	return menu;
}

public int Menu_ChangeMap(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[32];

		/* Get item info */
		bool found = menu.GetItem(param2, info, sizeof(info));

		/* Tell the client */
		PrintToConsole(param1, "You selected item: %d (found? %d info: %s)", param2, found, info);
 
		/* Change the map */
		ServerCommand("changelevel %s", info);
	}
}

public Action Command_ChangeMap(int client, int args)
{
	if (g_MapMenu == null)
	{
		PrintToConsole(client, "The mapcycle.txt file was not found!");
		return Plugin_Handled;
	} 

	g_MapMenu.Display(client, MENU_TIME_FOREVER);

	return Plugin_Handled;
}

//highkill--------------------------------------------------------------------------------------------------

public Action:High_Kill(int client, int args)
	{
	//if(IsClientInGame(client) && IsClientAuthorized(client) && IsPlayerAlive(client))
	ClientCommand(client, "sm_cvar sk_player_head 20; sm_cvar sk_player_chest 20; sm_cvar sk_player_stomach 20; sm_cvar sk_player_arm 20; sm_cvar sk_player_leg 20; sk_suitcharger_citadel 500; sk_suitcharger_citadel_maxarmor 500");
}

public Action:High_Kill1(int client, int args)
{
	//if(IsClientInGame(client) && IsClientAuthorized(client) && IsPlayerAlive(client))
	ClientCommand(client, "sm_cvar sk_player_head 3; sm_cvar sk_player_chest 1; sm_cvar sk_player_stomach 1; sm_cvar sk_player_arm 1; sm_cvar sk_player_leg 1; sk_suitcharger_citadel 200; sk_suitcharger_citadel_maxarmor 200");
}


//no dead frags----------------------------------------------------------------------------------------

public Event_Death(Handle:event, const String:name[], bool:broadcast){

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (client == attacker || attacker == 0)
	{
	SetEntProp(client, Prop_Data, "m_iFrags", GetClientFrags(client)+1);
	SetEntProp(client, Prop_Data, "m_iDeaths", GetClientDeaths(client)-1);
	}
}