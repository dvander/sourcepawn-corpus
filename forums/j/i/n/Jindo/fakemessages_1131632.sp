#include <sourcemod>
#include <sdktools>
#include <sdktools_sound>
#include <tf2>
#include <tf2_stocks>
#include <menus>
#include <topmenus>
#include <adminmenu>

#define ACHIEVEMENT_SOUND	"misc/achievement_earned.wav"
#define ITEM_LOSE			"player/crit_hit_mini.wav"

#define PL_VERSION			"2.0"

#define CVAR_VERSION		0
#define CVAR_ITEMS			1
#define MAXCVARS			2

new g_Target			[MAXPLAYERS + 1];
new g_Ent				[MAXPLAYERS + 1];
new g_menuTarget = 0;
new g_quality = 3;
new g_type = 0;
new Handle:g_cvars[MAXCVARS];
new String:g_Item[128];
new Handle:hTopMenu = INVALID_HANDLE;

public Plugin:myinfo = 
{
	
	name = "False Items + Achievements",
	author = "Jindo",
	description = "Can display false messages for finding/losing items and earning achievements.",
	version = PL_VERSION,
	url = "http://www.topaz-games.com"
	
}

public OnPluginStart()
{
	
	LoadTranslations("common.phrases");
	LoadTranslations("fakemessages.phrases");
	
	RegAdminCmd("sm_fakeitem", Command_FakeItem, ADMFLAG_RESERVATION);
	RegAdminCmd("sm_fakeitem2", Command_FakeItem2, ADMFLAG_RESERVATION);
	RegAdminCmd("sm_fakecraft", Command_FakeCraft, ADMFLAG_RESERVATION);
	RegAdminCmd("sm_fakeachievement", Command_FakeAchievement, ADMFLAG_RESERVATION);
	RegAdminCmd("sm_fakelose", Command_FakeLose, ADMFLAG_RESERVATION);
	RegAdminCmd("sm_vo", Command_Voice, ADMFLAG_RESERVATION);
	RegAdminCmd("sm_voice", Command_Voice, ADMFLAG_RESERVATION);
	
	HookEvent("item_found", Event_Item_Found);
	
	g_cvars[CVAR_VERSION] = CreateConVar("fakemessages_version", PL_VERSION, "Version of the plugin.", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_cvars[CVAR_ITEMS] = CreateConVar("fm_item_fireworks", "1", "Enables/disables the use of the firework effects when a real and/or fake item is found.", FCVAR_PLUGIN);
	
}

public OnMapStart()
{
	
	InitPrecache();
	
}

InitPrecache()
{
	
	PrecacheSound(ACHIEVEMENT_SOUND, true);
	PrecacheSound(ITEM_LOSE, true);
	
}

StartLooper(client)
{
	if (client > 0 && client <= MaxClients)
	{
	
		if (IsPlayerAlive(client) && IsClientConnected(client) && IsClientInGame(client))
		{
			
			if (TF2_GetPlayerClass(client) == TF2_GetClass("spy"))
			{
				//Do a more advanced check to see if the spy is cloaked or disguised.
				return;
			}
			
			CreateTimer(0.01, Timer_Particles, client, TIMER_FLAG_NO_MAPCHANGE);
			CreateTimer(0.5, Timer_Trophy, client, TIMER_FLAG_NO_MAPCHANGE);
			CreateTimer(2.0, Timer_Particles, client, TIMER_FLAG_NO_MAPCHANGE);
			CreateTimer(10.0, Timer_Delete, client, TIMER_FLAG_NO_MAPCHANGE);
			
		}
	}
	
	return;
}

public MenuHandler_ItemRarity(Handle:menu, MenuAction:action, param1, param2)
{
	
	if (action == MenuAction_End)
	{
		
		CloseHandle(menu);
		
	} else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
		}
	} else if (action == MenuAction_Select)
	{
		decl String:info[32];
		
		GetMenuItem(menu, param2, info, sizeof(info));
		g_quality = StringToInt(info);
		DisplayInventoryType(param1);
	}
}

public MenuHandler_ItemType(Handle:menu, MenuAction:action, param1, param2)
{
	
	if (action == MenuAction_End)
	{
		
		CloseHandle(menu);
		
	} else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
		}
	} else if (action == MenuAction_Select)
	{
		decl String:info[32];
		
		GetMenuItem(menu, param2, info, sizeof(info));
		g_type = StringToInt(info);
		DisplayInventory(param1);
	}
}


public MenuHandler_ItemChoice(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
		}
	} else if (action == MenuAction_Select)
	{
		
		decl String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		strcopy(g_Item, sizeof(g_Item), info);
		
		new Handle:event = CreateEvent("item_found", true);
		
		SetEventInt(event, "player", g_menuTarget);
		SetEventString(event, "item", g_Item);
		SetEventInt(event, "quality", g_quality);
		FireEvent(event);
	}
}

DisplayInventoryType(client)
{
	new Handle:menu = CreateMenu(MenuHandler_ItemType);
	
	decl String:title[100], String:mitem[100];
	Format(title, sizeof(title), "%N: %t", client, "Item choice");
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	Format(mitem, sizeof(mitem), "%t", "Normal weapons");
	AddMenuItem(menu, "0", mitem);
	Format(mitem, sizeof(mitem), "%t", "Unique weapons");
	AddMenuItem(menu, "1", mitem);
	Format(mitem, sizeof(mitem), "%t", "Hats");
	AddMenuItem(menu, "2", mitem);
	Format(mitem, sizeof(mitem), "%t", "Crafts");
	AddMenuItem(menu, "3", mitem);
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

DisplayInventoryMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_ItemRarity);
	
	decl String:title[100], String:mitem[100];
	Format(title, sizeof(title), "%N: %t", client, "Item choice");
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	
	Format(mitem, sizeof(mitem), "%t", "Unique");
	AddMenuItem(menu, "3", mitem);
	Format(mitem, sizeof(mitem), "%t", "Community");
	AddMenuItem(menu, "7", mitem);
	Format(mitem, sizeof(mitem), "%t", "Valve");
	AddMenuItem(menu, "8", mitem);
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

DisplayInventory(client)
{
	new Handle:menu = CreateMenu(MenuHandler_ItemChoice);
	
	decl String:title[100];
	Format(title, sizeof(title), "%N: %t", client, "Item choice");
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	
	switch (g_type)
	{
		case 0:
		{				// Translations? For this? Good one. <3
			AddMenuItem(menu, "TF_Weapon_Bat", "Bat");
			AddMenuItem(menu, "TF_Weapon_Bottle", "Bottle");
			AddMenuItem(menu, "TF_Weapon_FireAxe", "Fire Axe");
			AddMenuItem(menu, "TF_Weapon_Club", "Kukri");
			AddMenuItem(menu, "TF_Weapon_Bonesaw", "Bonesaw");
			AddMenuItem(menu, "TF_Weapon_FlameThrower", "Flame Thrower");
			AddMenuItem(menu, "TF_Weapon_PipebombLauncher", "Pipebomb Launcher");
			AddMenuItem(menu, "TF_Weapon_Knife", "Knife");
			AddMenuItem(menu, "TF_Weapon_Minigun", "Minigun");
			AddMenuItem(menu, "TF_Weapon_Pistol", "Pistol");
			AddMenuItem(menu, "TF_Weapon_Fists", "Fists");
			AddMenuItem(menu, "TF_Weapon_Revolver", "Revolver");
			AddMenuItem(menu, "TF_Weapon_RocketLauncher", "RocketLauncher");
			AddMenuItem(menu, "TF_Weapon_Shotgun", "Shotgun");
			AddMenuItem(menu, "TF_Weapon_Shovel", "Shovel");
			AddMenuItem(menu, "TF_Weapon_SMG", "SMG");
			AddMenuItem(menu, "TF_Weapon_SniperRifle", "Sniper Rifle");
			AddMenuItem(menu, "TF_Weapon_StickbombLauncher", "Stickybomb Launcher");
			AddMenuItem(menu, "TF_Weapon_Wrench", "Wrench");
			AddMenuItem(menu, "TF_Weapon_ObjectSelection", "Build");
			AddMenuItem(menu, "TF_Weapon_PDA_Engineer", "PDA");
			AddMenuItem(menu, "TF_Weapon_Medigun", "Medi Gun");
			AddMenuItem(menu, "TF_Weapon_Scattergun", "Scattergun");
			AddMenuItem(menu, "TF_Weapon_SyringeGun", "Syringe Gun");
			AddMenuItem(menu, "TF_Weapon_Watch", "Invis Watch");
		}
		case 1:
		{
			AddMenuItem(menu, "TF_Unique_Achievement_Medigun1", "The Kritzkrieg");
			AddMenuItem(menu, "TF_Unique_Achievement_Syringegun1", "The Blutsauger");
			AddMenuItem(menu, "TF_Unique_Achievement_Bonesaw1", "The Ubersaw");
			AddMenuItem(menu, "TF_Unique_Achievement_RocketLauncher", "The Direct Hit");
			AddMenuItem(menu, "TF_Unique_Achievement_SoldierBuff", "The Buffer Banner");
			AddMenuItem(menu, "TF_Unique_Achievement_Pickaxe", "The Equalizer");
			AddMenuItem(menu, "TF_Unique_Achievement_FireAxe1", "The Axtinguisher");
			AddMenuItem(menu, "TF_Unique_Achievement_FlareGun", "The Flare Gun");
			AddMenuItem(menu, "TF_Unique_Achievement_Flamethrower", "The Backburner");
			AddMenuItem(menu, "TF_Unique_Achievement_StickyLauncher", "The Scottish Resistance");
			AddMenuItem(menu, "TF_Unique_Achievement_Shield", "The Chargin' Target");
			AddMenuItem(menu, "TF_Unique_Achievement_Sword", "The Eyelander");
			AddMenuItem(menu, "TF_Unique_Achievement_LunchBox", "The Sandvich");
			AddMenuItem(menu, "TF_Unique_Achievement_Minigun", "Natascha");
			AddMenuItem(menu, "TF_Unique_Achievement_Fists", "The Killing Gloves of Boxing");
			AddMenuItem(menu, "TF_Unique_Achievement_Bat", "The Sandman");
			AddMenuItem(menu, "TF_Unique_Achievement_Scattergun_Double", "The Force-A-Nature");
			AddMenuItem(menu, "TF_Unique_Achievement_EnergyDrink", "Bonk! Atomic Punch");
			AddMenuItem(menu, "TF_Unique_Achievement_CloakWatch", "The Cloak and Dagger");
			AddMenuItem(menu, "TF_Unique_Achievement_FeignWatch", "The Dead Ringer");
			AddMenuItem(menu, "TF_Unique_Achievement_Revolver", "The Ambassador");
			AddMenuItem(menu, "TF_Unique_Backstab_Shield", "The Razorback");
			AddMenuItem(menu, "TF_Unique_Achievement_Jar", "Jarate");
			AddMenuItem(menu, "TF_Unique_Achievement_CompoundBow", "The Huntsman");
		}
		case 2:
		{
			AddMenuItem(menu, "TF_Scout_Hat_1", "Batter's Helmet");
			AddMenuItem(menu, "TF_Sniper_Hat_1", "Trophy Belt");
			AddMenuItem(menu, "TF_Soldier_Hat_1", "Soldier's Stash");
			AddMenuItem(menu, "TF_Demo_Hat_1", "Demoman's Fro");
			AddMenuItem(menu, "TF_Medic_Hat_1", "Prussian Pickelhaube");
			AddMenuItem(menu, "TF_Pyro_Hat_1", "Pyro's Beanie");
			AddMenuItem(menu, "TF_Heavy_Hat_1", "Football Helmet");
			AddMenuItem(menu, "TF_Engineer_Hat_1", "Mining Light");
			AddMenuItem(menu, "TF_Spy_Hat_1", "Fancy Fedora");
			AddMenuItem(menu, "TF_Engineer_Cowboy_Hat", "Batter's Helmet");
			AddMenuItem(menu, "TF_Heavy_Ushanka_Hat", "Officer's Ushanka");
			AddMenuItem(menu, "TF_Soldier_Pot_Hat", "Stainless Pot");
			AddMenuItem(menu, "TF_Demo_Scott_Hat", "Glengarry Bonnet");
			AddMenuItem(menu, "TF_Medic_Tyrolean_Hat", "Vintage Tyrolean");
			AddMenuItem(menu, "TF_Pyro_Chicken_Hat", "Respectless Rubber Glove");
			AddMenuItem(menu, "TF_Spy_Camera_Beard", "Camera Beard");
			AddMenuItem(menu, "TF_Scout_Bonk_Helmet", "Bonk Helm");
			AddMenuItem(menu, "TF_Sniper_Straw_Hat", "Professional's Panama");
			AddMenuItem(menu, "TF_Engineer_Train_Hat", "Batter's Helmet");
			AddMenuItem(menu, "TF_Heavy_Stocking_cap", "Tough Guy's Toque");
			AddMenuItem(menu, "TF_Soldier_Viking_Hat", "Tyrant's Helm");
			AddMenuItem(menu, "TF_Demo_Top_Hat", "Scotsman's Stove Pipe");
			AddMenuItem(menu, "TF_Medic_Mirror_Hat", "Otolaryngologist's Mirror");
			AddMenuItem(menu, "TF_Pyro_Fireman_Helmet", "Brigade Helm");
			AddMenuItem(menu, "TF_Spy_Derby_Hat", "Backbiter's Billycock");
			AddMenuItem(menu, "TF_Sniper_Jarate_Headband", "Master's Yellow Belt");
			AddMenuItem(menu, "TF_Scout_Newsboy_Cap", "Ye Olde Baker Boy");
			AddMenuItem(menu, "TF_Hatless_Scout", "Baseball Bill's Sports Shine");
			AddMenuItem(menu, "TF_Hatless_Sniper", "Ritzy Rick's Hair Fixative");
			AddMenuItem(menu, "TF_Hatless_Engineer", "Texas Slim's Dome Shine");
			AddMenuItem(menu, "TF_HonestyHalo", "Cheater's Lament");
			AddMenuItem(menu, "TF_Soldier_Medal_Web_Sleuth", "Gentle Manne's Service Medal");
			AddMenuItem(menu, "TF_Halloween_Hat", "Mildly Disturbing Halloween Mask");
			AddMenuItem(menu, "TF_Domination_Hat", "Ghastly Gibus");
			AddMenuItem(menu, "TF_L4DHat", "Bill's Hat");
		}
		case 3:
		{
			AddMenuItem(menu, "CI_Bar_A", "Scrap Metal");
			AddMenuItem(menu, "CI_Bar_B", "Reclaimed Metal");
			AddMenuItem(menu, "CI_Bar_C", "Refined Metal");
			AddMenuItem(menu, "CI_T_C_1", "Class Token - Scout");
			AddMenuItem(menu, "CI_T_C_2", "Class Token - Sniper");
			AddMenuItem(menu, "CI_T_C_3", "Class Token - Soldier");
			AddMenuItem(menu, "CI_T_C_4", "Class Token - Demoman");
			AddMenuItem(menu, "CI_T_C_5", "Class Token - Heavy");
			AddMenuItem(menu, "CI_T_C_6", "Class Token - Medic");
			AddMenuItem(menu, "CI_T_C_7", "Class Token - Pyro");
			AddMenuItem(menu, "CI_T_C_8", "Class Token - Spy");
			AddMenuItem(menu, "CI_T_C_9", "Class Token - Engineer");
			AddMenuItem(menu, "CI_T_S_1", "Slot Token - Primary");
			AddMenuItem(menu, "CI_T_S_2", "Slot Token - Secondary");
			AddMenuItem(menu, "CI_T_S_3", "Slot Token - Melee");
			AddMenuItem(menu, "CI_T_S_4", "Slot Token - Grenade");
			AddMenuItem(menu, "CI_T_S_5", "Slot Token - Building");
			AddMenuItem(menu, "CI_T_S_6", "Slot Token - PDA");
			AddMenuItem(menu, "CI_T_S_7", "Slot Token - PDA2");
			AddMenuItem(menu, "CI_T_S_8", "Slot Token - Head");
		}
	}
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	
}

//////////////////////////////////////////
//////////////////////////////////////////
//////////////////////////////////////////

public Action:Event_Item_Found(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_cvars[CVAR_ITEMS])
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if (!client)
		{
			return Plugin_Continue;
		}
		if (client > 0 && client <= MaxClients)
		{
			if (IsClientConnected(client) && IsClientInGame(client) && IsPlayerAlive(client) && TF2_GetPlayerClass(client) != TF2_GetClass("spy"))
			{
				StartLooper(client);
				new Float:playerPos[3] ;
				GetClientAbsOrigin(client, playerPos);
				EmitAmbientSound(ACHIEVEMENT_SOUND, playerPos, SOUND_FROM_WORLD, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, 0.0);
			}
		}
	}
	return Plugin_Continue;
}

public Action:Timer_Particles(Handle:timer, any:client)
{
	
	if (IsPlayerAlive(client) && IsClientConnected(client) && IsClientInGame(client))
	{
		
		AttachParticle(client, "mini_fireworks");
		
	}
	
	return Plugin_Handled;
}

public Action:Timer_Trophy(Handle:timer, any:client)
{
	
	if (IsPlayerAlive(client) && IsClientConnected(client) && IsClientInGame(client))
	{
		
		AttachParticle(client, "achieved");
		
	}
	
	return Plugin_Handled;
}

public Action:Timer_Delete(Handle:timer, any:client)
{
	
	DeleteParticle(g_Ent[client]);
	g_Ent[client] = 0;
	g_Target[client] = 0;
	
}

public Action:Command_FakeItem(client, args)
{
	
	if(args < 1)
	{
		
		g_menuTarget = client;
		
	}
	
	decl String:player[64];
	GetCmdArg(1, player, sizeof(player));	
	
	new String:target_name[MAX_TARGET_LENGTH]
	new target_list[MAXPLAYERS], target_count
	new bool:tn_is_ml
 
	if ((target_count = ProcessTargetString(
			player,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_CONNECTED,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
		
	}

	for (new i=0; i<target_count; i++)
	{
		
		g_menuTarget = target_list[i];
		
	}
	
	DisplayInventoryMenu(client);
	
	return Plugin_Handled;
}

public Action:Command_FakeItem2(client, args)
{
	
	if(args < 2)
	{
		
		ReplyToCommand(client, "[SM] Usage: sm_fakeitem2 <client> \"Item Name in Quotes\"");
		
	}
	
	decl String:player[64];
	GetCmdArg(1, player, sizeof(player));	
	
	decl String:item[64];
	GetCmdArg(2, item, sizeof(item));
	
	new String:target_name[MAX_TARGET_LENGTH]
	new target_list[MAXPLAYERS], target_count
	new bool:tn_is_ml
 
	if ((target_count = ProcessTargetString(
			player,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_CONNECTED,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
		
	}

	for (new i=0; i<target_count; i++)
	{
		
		ItemMessage(item, target_list[i]);
		
	}
	
	return Plugin_Handled;
}

public Action:Command_FakeCraft(client, args)
{
	
	if(args < 2)
	{
		
		ReplyToCommand(client, "[SM] Usage: sm_fakecraft <client> \"Item Name in Quotes\"");
		
	}
	
	decl String:player[64];
	GetCmdArg(1, player, sizeof(player));	
	
	decl String:item[64];
	GetCmdArg(2, item, sizeof(item));
	
	new String:target_name[MAX_TARGET_LENGTH]
	new target_list[MAXPLAYERS], target_count
	new bool:tn_is_ml
 
	if ((target_count = ProcessTargetString(
			player,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_CONNECTED,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
		
	}

	for (new i=0; i<target_count; i++)
	{
		
		CraftMessage(item, target_list[i]);
		
	}
	
	return Plugin_Handled;
}

public Action:Command_FakeLose(client, args)
{
	
	if(args < 2)
	{
		
		ReplyToCommand(client, "\x04[SM]\x01 Usage: sm_fakelose <target> <weapon_name>");
		return Plugin_Handled;
		
	}
	
	new String:player[64];
	GetCmdArg(1, player, sizeof(player));	
	new String:weapon[64];
	GetCmdArg(2, weapon, sizeof(weapon));
	
	new String:target_name[MAX_TARGET_LENGTH]
	new target_list[MAXPLAYERS], target_count
	new bool:tn_is_ml
 
	if ((target_count = ProcessTargetString(
			player,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_CONNECTED,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
		
	}

	for(new i=0; i<target_count; i++)
	{
		
		LoseMessage(target_list[i], weapon);
		
	}
	
	return Plugin_Handled;
}

public Action:Command_FakeAchievement(client, args)
{
	
	if(args < 2)
	{
		
		ReplyToCommand(client, "\x04[SM]\x01 Usage: sm_fakeachievement <target> <achievement_name>");
		return Plugin_Handled;
		
	}
	
	new String:player[64];
	GetCmdArg(1, player, sizeof(player));	
	new String:achieve[64];
	GetCmdArg(2, achieve, sizeof(achieve));
	
	new String:target_name[MAX_TARGET_LENGTH]
	new target_list[MAXPLAYERS], target_count
	new bool:tn_is_ml
 
	if ((target_count = ProcessTargetString(
			player,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_CONNECTED,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
		
	}

	for(new i=0; i<target_count; i++)
	{
		
		AchievementMessage(target_list[i], achieve);
		
	}
	
	return Plugin_Handled;
}

public Action:Command_Voice(client, args)
{
	
	if(args < 1)
	{
		
		ReplyToCommand(client, "\x04[SM]\x01 Usage: sm_vo <message>");
		return Plugin_Handled;
		
	}
		
	new String:message[128];
	GetCmdArgString(message, sizeof(message));
	
	VoiceMessage(client, message);
	
	return Plugin_Handled;
}

stock VoiceMessage(client, String:vmessage[128])
{
	
	if (client < 1 || client > MaxClients)
	{
		return;
	}
	
	new String:mssage[200];
	Format(mssage, sizeof(mssage), "\x03(%t) %N\x01: %s", "Voice", client, vmessage);
	SayText2(client, mssage);
	
	return;
}

stock ItemMessage(String:weapon[64], client)
{
	
	if (client < 1 || client > MaxClients)
	{
		return;
	}
	
	new String:message[200];
	Format(message, sizeof(message), "\x03%N\x01 %t \x06%s\x01", client, "Found item", weapon);
	SayText2(client, message);
	
	if (GetConVarInt(g_cvars[CVAR_ITEMS]))
	{
		if (IsPlayerAlive(client) && IsClientConnected(client) && IsClientInGame(client))
		{
			StartLooper(client);
			new Float:playerPos[3] ;
			GetClientAbsOrigin(client, playerPos);
			EmitAmbientSound(ACHIEVEMENT_SOUND, playerPos, SOUND_FROM_WORLD, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, 0.0);
		}
	}
	
	return;
}

stock CraftMessage(String:weapon[64], client)
{
	
	if (client < 1 || client > MaxClients)
	{
		return;
	}
	
	new String:message[200];
	Format(message, sizeof(message), "\x03%N\x01 %t \x06%s\x01", client, "Craft item", weapon);
	SayText2(client, message);
	
	if (GetConVarInt(g_cvars[CVAR_ITEMS]) && IsPlayerAlive(client) && IsClientConnected(client) && IsClientInGame(client))
	{
		
		StartLooper(client);
		new Float:playerPos[3] ;
		GetClientAbsOrigin(client, playerPos);
		EmitAmbientSound(ACHIEVEMENT_SOUND, playerPos, SOUND_FROM_WORLD, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, 0.0);
		
	}
	
	return;
}

stock LoseMessage(client, String:weapon[64])
{
	
	if (client < 1 || client > MaxClients)
	{
		return;
	}
	
	new String:message[200];
	Format(message, sizeof(message), "\x03%N\x01 %t \x06%s\x01", client, "Lost item", weapon);
	SayText2(client, message);
	
	if (IsPlayerAlive(client) && IsClientConnected(client) && IsClientInGame(client))
	{
		
		new Float:playerPos[3] ;
		GetClientAbsOrigin(client, playerPos);
		EmitAmbientSound(ITEM_LOSE, playerPos, SOUND_FROM_WORLD, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, 0.0);
		
	}
	
	return;
}

stock AchievementMessage(client, String:achievement[64])
{
	
	if (client < 1 || client > MaxClients)
	{
		return;
	}
	
	new String:message[200];
	Format(message, sizeof(message), "\x03%N\x01 %t \x05%s\x01", client, "Achievement", achievement);
	SayText2(client, message);
	if (IsPlayerAlive(client) && IsClientConnected(client) && IsClientInGame(client))
	{
		
		StartLooper(client);
		new Float:playerPos[3] ;
		GetClientAbsOrigin(client, playerPos);
		EmitAmbientSound(ACHIEVEMENT_SOUND, playerPos, SOUND_FROM_WORLD, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, 0.0);
		
	}
	
	return;
}

stock SayText2(author_index , const String:message[] ) {
	
    new Handle:buffer = StartMessageAll("SayText2");
	
    if (buffer != INVALID_HANDLE) {
		
        BfWriteByte(buffer, author_index);
        BfWriteByte(buffer, true);
        BfWriteString(buffer, message);
		
        EndMessage();
		
    }
	
}

AttachParticle(ent, String:particleType[])
{
	new particle = CreateEntityByName("info_particle_system");
	
	new String:tName[128];
	
	if (IsValidEdict(particle))
	{
		
		new Float:pos[3] ;
		
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
		pos[2] += 74
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		
		Format(tName, sizeof(tName), "target%i", ent);
		
		DispatchKeyValue(ent, "targetname", tName);
		DispatchKeyValue(particle, "targetname", "tf2particle");
		DispatchKeyValue(particle, "parentname", tName);
		DispatchKeyValue(particle, "effect_name", particleType);
		DispatchSpawn(particle);
		
		SetVariantString(tName);
		AcceptEntityInput(particle, "SetParent", particle, particle, 0);
		SetVariantString("flag");
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		
		g_Ent[ent] = particle;
		g_Target[ent] = 1;
		
	}
	
}

DeleteParticle(any:particle)
{
    if (IsValidEntity(particle))
    {
		
        new String:classname[256];
        GetEdictClassname(particle, classname, sizeof(classname));
		
        if (StrEqual(classname, "info_particle_system", false))
        {
			
            RemoveEdict(particle);
			
        }
		
    }
	
}