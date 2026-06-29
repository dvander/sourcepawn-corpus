/*
PLUGIN_NAME:		L4D2_WEAPONS
PLUGIN_AUTHOR:		GAMEMANN
PLUGIN_DESCRIPTION:	when you type in the chat !<weapon> such as !rifle or !pipebomb it gives you weapons
PLUGIN_VERSION:		1.7
PLUGIN_URL			http://forums.alliedmods.net/showthread.php?t=112694

CONVARS:
survivorlimmit,
infectedlimmit,
botkickertime,

Helpers:
{NONE}

VERSIONS:
* version 1.0.0:
*		{}

defines:
#define PLUGIN_VERSION    "1"
#define PLUGIN_NAME       "L4D2 weapons"
#define L4D_TEAM_SPECTATOR 3
#define L4D_TEAM_INFECTED 1
#define L4D_TEAM_SURVIVOR 2

includes:
#include <sourcemod>
#include <sdktools_functions>
#include <sdktools>
#include <colors>
*/











#define PLUGIN_VERSION    "1"
#define PLUGIN_NAME       "L4D2 weapons"
#define L4D_TEAM_SPECTATOR 1
#define L4D_TEAM_INFECTED 2	
#define L4D_TEAM_SURVIVOR 3


#include <sourcemod>
#include <sdktools_functions>
#include <sdktools>
#include <colors>


new bool:bHasLaser[MAXPLAYERS+1];
new bool:Ammo[MAXPLAYERS+1];
new bool:bHasUpgrade[MAXPLAYERS+1];

public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = "gamemann",
	description = "tpye in the chat !<weapon> then u get it.",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/",
};

//notes
//public Action:Refill(client,args)
//{
//	RefillFunc(client);
//	
//	return Plugin_Handled;
//}
//
//public Action:RefillFunc(clientId)
//{
//	new flags3 = GetCommandFlags("give");
//	SetCommandFlags("give", flags3 & ~FCVAR_CHEAT);
//	
//	//Give player ammo
//	FakeClientCommand(clientId, "give ammo");
//	
//	SetCommandFlags("give", flags3|FCVAR_CHEAT);
//	
//	return Plugin_Handled;
//}


//melee weapons can only be used for some maps
//make sure to read the description
//1.1: 
//- release
//1.2:
//* 
//- added some weapons
//- fixed !rifle from having to be !Rifle
//- fixed spelling errors
//1.3:
//*
//- added much more
//- fixed alot of them not showing
//- made another list of weapons
//1.4:
//*
//- added packs
//- added new shortcuts
//1.5:
//*
//- added melee weapons AND now works!
//- added new things
//1.6:
//*
//- fixed some things
//- added some commands
//- added a difficulty thing

public OnPluginStart()
{
	//Requires l4d2
	decl String:game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));
	if (!StrEqual(game_name, "left4dead2", false))
		SetFailState("Plugin supports Left 4 Dead 2 only.");
	////
	//config
	////
	CreateConVar("l4d2_weapon_version", "1", "weapon_version plugin version",
FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	//////
	//hooking events
	//////
	//hooking convarchanges

//////
//convar bounds
//////

	//RegConsoleCmds
	RegConsoleCmd("sm_upgradef", CmdUpgradef);
	RegConsoleCmd("sm_upgradee", CmdUpgradee);
	RegConsoleCmd("sm_details", CmdDetails);
	RegConsoleCmd("sm_laseron", CmdLaserOn);
	RegConsoleCmd("sm_laseroff", CmdLaserOff);
	RegConsoleCmd("sm_laser", CmdLaserToggle);
	RegConsoleCmd("sm_redot", CmdLaser);
	RegConsoleCmd("sm_grenade_launcher", CmdGivegrenade_launcher);
	RegAdminCmd("sm_health", CmdHealth, ADMFLAG_ROOT, "gives you more health ONLY FOR AMIN ONLY");
	RegConsoleCmd("sm_autoshotgun", CmdAutoShotgun);
	RegConsoleCmd("sm_adrenaline", CmdAdrenaline);
	RegConsoleCmd("sm_chainsaw", CmdChainsaw);
	RegConsoleCmd("sm_defibrillator", CmdDefibrillator);
	RegConsoleCmd("sm_sniper_military", CmdSniper_military);
	RegConsoleCmd("sm_molotov", CmdMolotov);
	RegConsoleCmd("sm_smg_silenced", CmdSmg_silenced);
	RegConsoleCmd("sm_ammo", CmdAmmo);
	RegConsoleCmd("sm_pills", CmdPills);
	RegConsoleCmd("sm_first_aid_kit", CmdFirst_Aid_Kit);
	RegConsoleCmd("sm_smg", CmdSmg);
	RegConsoleCmd("sm_hunting_rifle", CmdHunting_Rifle);
	RegConsoleCmd("sm_rifle", CmdRifle);
	RegConsoleCmd("sm_shotgun_spas", CmdShotgun_Spas);
	RegConsoleCmd("sm_shotgun_chrome", CmdShotgun_Chrome);
	RegConsoleCmd("sm_rifle_desert", CmdRifle_Desert);
	RegConsoleCmd("sm_rifle_ak47", CmdRifle_Ak47);
	RegConsoleCmd("sm_pistol_magnum", CmdPistol_Magnum);
	RegConsoleCmd("sm_pumpshotgun", CmdPumpShotgun);
	RegConsoleCmd("sm_pipebomb", CmdPipeBomb);
	RegConsoleCmd("sm_pistol", CmdPistol);
	RegConsoleCmd("sm_ammo_pack", CmdAmmo_Pack);
	RegConsoleCmd("sm_fireammo", CmdFireAmmoPack);
	RegConsoleCmd("sm_explodeammo", CmdExplodeAmmoPack);
	RegConsoleCmd("sm_upgradepack_explosive", CmdExplodeAmmo);
	RegConsoleCmd("sm_upgradepack_incendiary", CmdFireAmmo);
	RegConsoleCmd("sm_boom", CmdBoom);
	RegConsoleCmd("sm_fire", CmdFire);
	RegConsoleCmd("sm_player_death", CmdPlayerDeath);
	RegConsoleCmd("sm_dash", CmdDash);
	RegConsoleCmd("sm_gun1", CmdGun01);
	RegConsoleCmd("sm_gun2", CmdGun02);
	RegConsoleCmd("sm_gun3", CmdGun03);
	RegConsoleCmd("sm_gun4", CmdGun04);
	RegConsoleCmd("sm_gun5", CmdGun05);
	RegConsoleCmd("sm_gun6", CmdGun06);
	RegConsoleCmd("sm_gun7", CmdGun07);
	RegConsoleCmd("sm_gun8", CmdGun08);
	RegConsoleCmd("sm_gun9", CmdGun09);
	RegConsoleCmd("sm_gun10", CmdGun10);
	RegConsoleCmd("sm_gun11", CmdGun11);
	RegConsoleCmd("sm_weapon1", CmdWeapon01);
	RegConsoleCmd("sm_kill", CmdKill);
	RegConsoleCmd("sm_run", CmdRun);
	RegConsoleCmd("sm_runoff", CmdRunOff);
	RegConsoleCmd("sm_win", CmdWin);
	RegConsoleCmd("sm_random", CmdRandom);
	RegConsoleCmd("sm_sniper_pack", CmdSniperPack);
	RegConsoleCmd("sm_rifle_pack", CmdRiflePack);
	RegConsoleCmd("sm_smg_pack", CmdSmgPack);
	RegConsoleCmd("sm_fire_pack", CmdFirePack);
	RegConsoleCmd("sm_incendiary_ammo", CmdIncendiaryAmmo);
	RegConsoleCmd("sm_shotgun_pack", CmdShotgunPack);
	RegConsoleCmd("sm_ga", CmdGa);
	RegConsoleCmd("sm_machete", CmdMachete);
	RegConsoleCmd("sm_fireaxe", CmdFireaxe);
	RegConsoleCmd("sm_tonfa", CmdTonfa);
	RegConsoleCmd("sm_electric_guitar", CmdGuitar);
	RegConsoleCmd("sm_katana", CmdKantana);
	RegConsoleCmd("sm_frying_pan", CmdFryingPan);
	RegConsoleCmd("sm_crowbar", CmdCrowbar);
	RegConsoleCmd("sm_cricket_bat", CmdCricketBat);
	RegConsoleCmd("sm_baseball_bat", CmdBaseballBat);
	RegConsoleCmd("sm_explode_pack_1", CmdExplodePack01);
	RegConsoleCmd("sm_gg", CmdGg);
	RegConsoleCmd("sm_mapvote", CmdMapVote);
	RegConsoleCmd("sm_a", CmdA);
	RegConsoleCmd("sm_shot", CmdShot);
	RegConsoleCmd("sm_tankhelp", CmdTankHelp);
	RegConsoleCmd("sm_witchhelp", CmdWitchHelp);
	RegConsoleCmd("sm_quit", CmdQuit);
	RegConsoleCmd("sm_bbat", CmdBat);
	RegConsoleCmd("sm_axe", CmdAxe);
	RegConsoleCmd("sm_cbat", CmdCBat);
	RegConsoleCmd("sm_weapon2", CmdWeapon2);
	RegConsoleCmd("sm_weapon3", CmdWeapon3);
	RegConsoleCmd("sm_weapon4", CmdWeapon4);
	RegConsoleCmd("sm_weapon5", CmdWeapon5);
	RegConsoleCmd("sm_weapon6", CmdWeapon6);
	RegConsoleCmd("sm_weapon7", CmdWeapon7);
	RegConsoleCmd("sm_weapon8", CmdWeapon8);
	RegConsoleCmd("sm_weapon9", CmdWeapon9);
	RegConsoleCmd("sm_weapon10", CmdWeapon10);
	RegConsoleCmd("sm_help", CmdHelp);
	RegConsoleCmd("sm_*", CmdStar);
	RegConsoleCmd("sm_difficulty2", CmdDifficulty2);
	RegConsoleCmd("sm_difficulty3", CmdDifficulty3);
	RegConsoleCmd("sm_difficulty4", CmdDifficulty4);
	RegConsoleCmd("sm_l4d1", CmdL4d1);
	RegConsoleCmd("sm_mod1", CmdMod1);
	RegConsoleCmd("sm_mod2", CmdMod2);
	RegConsoleCmd("sm_mod3", CmdMod3);
	RegConsoleCmd("sm_mod4", CmdMod4);
	RegConsoleCmd("sm_moreA", CmdMoreA);
	RegConsoleCmd("sm_morecrouch", CmdCrouch);
	RegConsoleCmd("sm_quitgame", CmdQuitGame);
	RegConsoleCmd("sm_server", CmdServerRules);
	RegConsoleCmd("sm_idle", CmdIdle);
	RegConsoleCmd("sm_serverhelp", CmdServerHelp);
	RegConsoleCmd("sm_adminname", CmdAdminName);
	RegAdminCmd("sm_sv_cheat1", CmdSvCheats, ADMFLAG_ROOT);
	RegAdminCmd("sm_addbot", CmdAddBot, ADMFLAG_ROOT);
	RegConsoleCmd("sm_contact", CmdContact);
	RegAdminCmd("sm_refill", CmdRefill, ADMFLAG_ROOT);
	RegConsoleCmd("sm_l4dweapons", CmdMenu2);
	RegAdminCmd("sm_adminmenu2", CmdAdminMenu2, ADMFLAG_ROOT);

	AutoExecConfig(true, "l4d2_sm_weapons");
}

public Action:CmdUpgradef(client, args)
{
	CheatCommand(client, "upgrade_add", "INCENDIARY_AMMO");
	bHasUpgrade[client] = true;
	if(bHasUpgrade[client] == false)
	{
		PrintToChat(client, "you can not have this upgrade");
	}
	else
	{
		PrintToChat(client, "you can not have this upgrade");
	}
	return Plugin_Handled;
}

public Action:CmdUpgradee(client, args)
{
	CheatCommand(client, "upgrade_add", "EXPLOSIVE_AMMO");
	bHasUpgrade[client] = true;
	if(bHasUpgrade[client] == false)
	{
		PrintToChat(client, "you can not have this upgrade");
	}
	else
	{
		PrintToChat(client, "you can not have this upgrade");
	}
	return Plugin_Handled;
}

/*
here is another menu part but with admins!!
here it is...!
*/

public Action:CmdAdminMenu2(client, args)
{
	new Handle:menu = CreateMenu(L4dAdminMenu2);
	SetMenuTitle(menu, "l4d2 admin menu 2");
	AddMenuItem(menu, "option1", "sv_cheats 1");
	AddMenuItem(menu, "option2", "plugins");
	AddMenuItem(menu, "option3", "health");
	AddMenuItem(menu, "option4", "refill");
	AddMenuItem(menu, "option5", "spawn witch");
	AddMenuItem(menu, "option6", "spawn tank");
	AddMenuItem(menu, "option7", "spawn hunter");
	AddMenuItem(menu, "option8", "spawn spitter");
	AddMenuItem(menu, "option9", "spawn boomer");
	AddMenuItem(menu, "option10", "spawn smoker");
	AddMenuItem(menu, "option11", "spawn charger");
	AddMenuItem(menu, "option12", "spawn jockey");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	//return Plugin_Handled;
}

public L4dAdminMenu2(Handle:menu, MenuAction:action, client, itemNum)
{
	new flags = GetCommandFlags("give");
	new flags1 = GetCommandFlags("z_spawn");
	new flags2 = GetCommandFlags("sv_cheats");
	SetCommandFlags("z_spawn", flags1 & ~FCVAR_CHEAT);
	SetCommandFlags("sv_cheats", flags2 & ~FCVAR_CHEAT);
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);
	if(action == MenuAction_Select)
	{
		switch (itemNum)
		{
			case 0: //sv_cheats 1
			{
				//sv_cheats 1 enabled
				FakeClientCommand(client, "sv_cheats 1");
			}

			case 1: //plugins "sm_plugins"
			{
				FakeClientCommand(client, "sm plugins");
			}

			case 2: //health
			{
				FakeClientCommand(client, "give health");
			}

			case 3: //refill ammo
			{
				FakeClientCommand(client, "give ammo");
			}

			case 4: //spawning a witch
			{
				FakeClientCommand(client, "z_spawn witch");
			}

			case 5: //spawning a tank
			{
				FakeClientCommand(client, "z_spawn tank");
			}

			case 6: //spawning a hunter
			{
				FakeClientCommand(client, "z_spawn hunter");
			}

			case 7: //spawning a spitter
			{
				FakeClientCommand(client, "z_spawn spitter");
			}

			case 8: //spawning a boomer
			{
				FakeClientCommand(client, "z_spawn boomer");
			}

			case 9: //spawning a smoker
			{
				FakeClientCommand(client, "z_spawn smoker");
			}

			case 10: //spawning a charger
			{
				FakeClientCommand(client, "z_spawn charger");
			}

			case 11: //spawning a jockey
			{
				FakeClientCommand(client, "z_spawn jockey");
			}
		}
	}
}
				


/*
here is the menus part!!!!
here it is!!!
*/

public Action:CmdMenu2(client, args) {
	new Handle:menu = CreateMenu(L4dWeaponshandler);
	SetMenuTitle(menu, "L4d2 weapons menu picker");
	AddMenuItem(menu, "option0", "rifle");
	AddMenuItem(menu, "option1", "sniper_militarty");
	AddMenuItem(menu, "option2", "hunting_rifle");
	AddMenuItem(menu, "option3", "rifle_ak_47");
	AddMenuItem(menu, "option4", "rifle_desert");
	AddMenuItem(menu, "option5", "smg");
	AddMenuItem(menu, "option6", "smg_slienced");
	AddMenuItem(menu, "option7", "autoshotgun");
	AddMenuItem(menu, "option8", "pumpshotgun");
	AddMenuItem(menu, "option9", "shotgun Chrome");
	AddMenuItem(menu, "option10", "upgrade pack fire");
	AddMenuItem(menu, "option11", "upgrade pack Explosive");
	AddMenuItem(menu, "option12", "sniper_awp");
	AddMenuItem(menu, "option13", "sniper scout");
	AddMenuItem(menu, "option14", "SMG mp5");
	AddMenuItem(menu, "option15", "Grenade launcher");
	AddMenuItem(menu, "option16", "fireworkcreate");
	AddMenuItem(menu, "option17", "vomit jar");
	AddMenuItem(menu, "option18", "molotov");
	AddMenuItem(menu, "option19", "pipe bomb");
	AddMenuItem(menu, "option20", "gascan");
	AddMenuItem(menu, "option21", "propane tank");
	AddMenuItem(menu, "option22", "oxygen tank");
	AddMenuItem(menu, "option23", "Gnome");
	AddMenuItem(menu, "option24", "shotgun Spas");
	AddMenuItem(menu, "option25", "rifle Sg");
	AddMenuItem(menu, "option26", "machete * only if the level can have it!!!");
	AddMenuItem(menu, "option27", "fireaxe * only if the level can have it!!!");
	AddMenuItem(menu, "option28", "katana * only if the level can have it!!!");
	AddMenuItem(menu, "option29", "frying pan * only if the level can have it!!!");
	AddMenuItem(menu, "option30", "Electric Guitar * only if the level can have it!!!");
	AddMenuItem(menu, "option31", "Cricket Bat * only if the level can have it!!!");
	AddMenuItem(menu, "option32", "Crow Bar * only if the level can have it!!!");
	AddMenuItem(menu, "option33", "Tonfa * only if the level can have it!!!");
	AddMenuItem(menu, "option34", "chainsaw");
	AddMenuItem(menu, "option35", "knife");
	AddMenuItem(menu, "option36", "rifle_pack");
	AddMenuItem(menu, "option37", "SMG_pack");
	AddMenuItem(menu, "option38", "sniperPack");
	AddMenuItem(menu, "option39", "shotgunPack");
	AddMenuItem(menu, "option40", "first_aid_kit");
	AddMenuItem(menu, "option41", "pills");
	AddMenuItem(menu, "option42", "other");
	AddMenuItem(menu, "option434", "other");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	//return Plugin_Handled
}

public L4dWeaponshandler(Handle:menu, MenuAction:action, client, itemNum)
{
	new flags = GetCommandFlags("give");
	new flagsi1 = GetCommandFlags("add_upgrade");
	SetCommandFlags("add_upgrade", flagsi1 & ~FCVAR_CHEAT);
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);
	if(action == MenuAction_Select)
	{
		switch (itemNum)
		{
			case 0: //rifle
			{

					//gives a rifle
					FakeClientCommand(client, "give rifle");
			}
			
			case 1: //sniper_military
			{
				//gives a sniper_military
				FakeClientCommand(client, "give sniper_military");
			}
			
			case 2: //hunting_rifle
			{
				//gives a hunting rifle
				FakeClientCommand(client, "give hunting_rifle");
			}

			case 3: //Ak 47
			{
				//gives a ak_47
					FakeClientCommand(client, "give rifle_ak47");
			}
		
			case 4: //rifle desert
			{
				FakeClientCommand(client, "give rifle_desert");
			}
			case 5: //smg
			{
				FakeClientCommand(client, "give smg");
			}
		
			case 6: //smg silenced
			{
				FakeClientCommand(client, "give smg_silenced");
			}
		
			case 7: // autoshotgun
			{
				FakeClientCommand(client, "give autoshotgun");
			}
		
			case 8: //pumpshotgun
			{
				FakeClientCommand(client, "give pumpshotgun");
			}

			case 9: //shotgun CHROME
			{
				FakeClientCommand(client, "give shotgun_chrome");
			}
			case 10: // upgradePack incendiary
			{
				FakeClientCommand(client, "give upgradepack_incendiary");
			}
			
			case 11: // upgradePack explosive
			{
				FakeClientCommand(client, "give upgradepack_explosive");
			}
			
			case 12: // sniper_awp
			{
				FakeClientCommand(client, "give sniper_awp");
			}
		
			case 13: //sniper_scout
			{
				FakeClientCommand(client, "give sniper_scout");
			}
			
			case 14: //smg_mp5
			{
				FakeClientCommand(client, "give smg_mp5");
			}

			case 15: //grenade launcher
			{
				FakeClientCommand(client, "give grenade_launcher");
			}

			case 16: //fireworkcrate
			{
				FakeClientCommand(client, "give fireworkcrate");
			}
			
			case 17: //vomit jar
			{
				FakeClientCommand(client, "give vomitjar");
			}

			case 18: //MOLOTOV
			{
				FakeClientCommand(client, "give molotov");
			}
	
			case 19: // PIPEBOMB
			{
				FakeClientCommand(client, "give pipe_bomb");
			}
		
			case 20: // GASCAN
			{
				FakeClientCommand(client, "give gascan");
			}

			case 21: //PROPANETANK
			{
				FakeClientCommand(client, "give propanetank");
			}
	
			case 22: //OXYGENTANK
			{
				FakeClientCommand(client, "give oxygentank");
			}

			case 23: // GNOME
			{
				FakeClientCommand(client, "give gnome");
			}

			case 24: //shotgun SPAS
			{
				FakeClientCommand(client, "give shotgun_spas");
			}

			case 25: // rifle_sg552
			{
				FakeClientCommand(client, "give rifle_sg552");
			}

			case 26: // machete
			{
				FakeClientCommand(client, "give machete");
			}
			
			case 27: // fireaxe
			{
				FakeClientCommand(client, "give fire_axe");
			}
		
			case 28: // katana
			{
				FakeClientCommand(client, "give katana");
			}
		
			case 29: //frying pan
			{
				FakeClientCommand(client, "give frying_pan");
			}
	
			case 30: // electric guitar
			{
				FakeClientCommand(client, "give electric_guitar");
			}

			case 31: // cricket bat
			{
				FakeClientCommand(client, "give cricket_bat");
			}

			case 32: //crow bar
			{
				FakeClientCommand(client, "give crow_bar");
			}

			case 33: // tonfa
			{
				FakeClientCommand(client, "give tonfa");
			}

			case 34: // chainsaw
			{
				FakeClientCommand(client, "give chainsaw");
			}
			
			case 35: // knife
			{
				FakeClientCommand(client, "give knife");
			}
	
			case 36: // rifle pack
			{
				FakeClientCommand(client, "give upgradepack_explosive");
				FakeClientCommand(client, "add_upgrade laser_sight");
				FakeClientCommand(client, "give rifle");
				FakeClientCommand(client, "give first_aid_kit");
			}
		
			case 37: //smg pack
			{
				FakeClientCommand(client, "give upgradepack_incendiary");
				FakeClientCommand(client, "give first_aid_kit");
				FakeClientCommand(client, "add_upgrade laser_sight");
				FakeClientCommand(client, "give smg");
				FakeClientCommand(client, "give first_aid_kit");
			}
			
			case 38: //sniper pack
			{
				FakeClientCommand(client, "give sniper_military");
				FakeClientCommand(client, "give pills");
				FakeClientCommand(client, "give first_aid_kit");
				FakeClientCommand(client, "add_upgrade laser_sight");
			}
		
			case 39: //shotgun pack
			{
				FakeClientCommand(client, "give shotgun_spas");
				FakeClientCommand(client, "add_upgrade laser_sight");
				FakeClientCommand(client, "first_aid_kit");
			}

			case 40: // first_aid_kit
			{
				FakeClientCommand(client, "give first_aid_kit");
			}

			case 41: // pain pills
			{
				FakeClientCommand(client, "give pain_pills");
			}
			
			case 42: //other
			{
				FakeClientCommand(client, "give smg");
				FakeClientCommand(client, "give katana");
			}	
		}
	}
}

			


/*
ok here is all the actions and stuff for the plugin...
so public Action:<>(client, args) command will make it so there we go...
*/


public Action:CmdRefill(client, args)
{
	CheatCommand(client, "give", "ammo");
	Ammo[client] = true;
	return Plugin_Handled;
}

public Action:CmdContact(client, args)
{
	CPrintToChatAll("{red}hello my e-mail address is {blue}christiandeacon@aol.com{green}to contact me if there is any problems on the server!");
	return Plugin_Handled;
}

public Action:CmdDetails(client, args)
{
	CPrintToChatAll("{green}you can type in the chatbox !<weapon> to get weapons such as !rifle you will get a rifle or !molotov{blue}and more! {green}Also to contact me please tpye in the chatbox !contact");
	return Plugin_Handled;
}

	
public Action:CmdAddBot(client, args)
{
	new bot = CreateFakeClient("bot");
	ChangeClientTeam(bot,2);
	DispatchKeyValue(bot,"classname","SurvivorBot");
	DispatchSpawn(bot);
	CreateTimer(1.0,KickFakeClient,bot);
}

public Action:KickFakeClient(Handle:timer, any:value)
{
	KickClient(value,"fake player");
	return Plugin_Handled;
}

public Action:CmdSvCheats(client, args)
{
	CheatCommand(client, "sv_cheats", "1");
	bHasLaser[client] = true;
	return Plugin_Handled;
}	

public Action:CmdAdminName(client, args)
{
	PrintHintText(client, "left4deadtank is the admin!");
	return Plugin_Handled;
}

public Action:CmdServerHelp(client, args)
{
	PrintHintText(client, "please tpye in !<weapon> to get weapons such as !rifle will give you a rifle");
	return Plugin_Handled;
}

public Action:CmdIdle(client, args)
{
	ChangeClientTeam(client, L4D_TEAM_SPECTATOR);
	return Plugin_Handled;
}


public Action:CmdServerRules(client, args)
{
	PrintHintText(client, "server rules are no rules!!!");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdQuitGame(client, args)
{
	CheatCommand(client, "", "quit");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdCrouch(client, args)
{
	FakeClientCommand(client, "survivor_crouch_speed 800");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdMoreA(client, args)
{
	CheatCommand(client, "survivor_accuracy_upgrade_factor", "3.0");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdMod4(client, args)
{
	CheatCommand(client, "give", " sniper_scout");
	bHasLaser[client] = true;
	return Plugin_Handled;
}


public Action:CmdMod3(client, args)
{
	CheatCommand(client, "give", " sniper_awp");
	bHasLaser[client] = true;
	return Plugin_Handled;
}


public Action:CmdMod2(client, args)
{
	CheatCommand(client, "give", " smg_mp5");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdMod1(client, args)
{
	CheatCommand(client, "give", "rifle_sg552");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdL4d1(client, args)
{
	CheatCommand(client, "give", "pumpshotgun");
	CheatCommand(client, "give", "smg");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdDifficulty4(client, args)
{
	CheatCommand(client, "z_difficulty", "Impossible");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdDifficulty3(client, args)
{
	CheatCommand(client, "z_difficulty", "Hard");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdDifficulty2(client, args)
{
	CheatCommand(client, "z_difficulty", "Normal");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdStar(client, args)
{
	CheatCommand(client, "give", "first_aid_kit");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdHelp(client, args)
{
	CheatCommand(client, "give", "health");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdWeapon6(client, args)
{
	CheatCommand(client, "give", "frying_pan");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdWeapon10(client, args)
{
	CheatCommand(client, "give", "katana");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdWeapon9(client, args)
{
	CheatCommand(client, "give", "electric_guitar");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdWeapon8(client, args)
{
	CheatCommand(client, "give", "tonfa");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdWeapon7(client, args)
{
	CheatCommand(client, "give", "fireaxe");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdWeapon5(client, args)
{
	CheatCommand(client, "give", "baseball_bat");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdWeapon4(client, args)
{
	CheatCommand(client, "give", "cricket_bat");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdWeapon3(client, args)
{
	CheatCommand(client, "give", "crowbar");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdWeapon2(client, args)
{
	CheatCommand(client, "give", "machete");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdCBat(client, args)
{
	CheatCommand(client, "give", "cricket_bat");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdAxe(client, args)
{
	CheatCommand(client, "give", "fireaxe");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdBat(client, args)
{
	CheatCommand(client, "give", "baseball_bat");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdQuit(client, args)
{
	CheatCommand(client, "", "disconnect");
	bHasLaser[client] = true;
	return Plugin_Handled;
}


public Action:CmdA(client, args)
{
	CheatCommand(client, "give", "ammo");
	bHasLaser[client] = true;
	return Plugin_Handled;
}


public Action:CmdShot(client, args)
{
	CheatCommand(client, "give", "ammo");
	bHasLaser[client] = true;
	return Plugin_Handled;
}


public Action:CmdWitchHelp(client, args)
{
	CheatCommand(client, "give", "autoshotgun");
	CheatCommand(client, "give", "health");
	bHasLaser[client] = true;
	return Plugin_Handled;
}


public Action:CmdTankHelp(client, args)
{
	CheatCommand(client, "give", "grenade_launcher");
	CheatCommand(client, "give", "first_aid_kit");
	bHasLaser[client] = true;
	return Plugin_Handled;
}


public Action:CmdMapVote(client, args)
{
	CheatCommand(client, "map", "vote");
	bHasLaser[client] = true;
	return Plugin_Handled;
}


public Action:CmdGg(client, args)
{
	CheatCommand(client, "give", "ANY");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdExplodePack01(client, args)
{
	CheatCommand(client, "give", "grenade_launcher");
	CheatCommand(client, "give", "ammo");
	CheatCommand(client, "give", "first_aid_kit");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdBaseballBat(client, args)
{
	CheatCommand(client, "give", "baseball_bat");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdCricketBat(client, args)
{
	CheatCommand(client, "give", "cricket_bat");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdCrowbar(client, args)
{
	CheatCommand(client, "give", "crowbar");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdFryingPan(client, args)
{
	CheatCommand(client, "give", "frying_pan");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdKantana(client, args)
{
	CheatCommand(client, "give", "katana");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdGuitar(client, args)
{
	CheatCommand(client, "give", "electric_guitar");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdTonfa(client, args)
{
	CheatCommand(client, "give", "tonfa");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdFireaxe(client, args)
{
	CheatCommand(client, "give", "fireaxe");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdMachete(client, args)
{
	CheatCommand(client, "give", "machete");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdGa(client, args)
{
	CheatCommand(client, "give", "ammo");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdShotgunPack(client, args)
{
	CheatCommand(client, "give", "shotgun_spas");
	CheatCommand(client, "give", "first_aid_kit");
	CheatCommand(client, "upgrade_add", "laser_sight");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdIncendiaryAmmo(client, args)
{
	CheatCommand(client, "upgrade_add", "INCENDIARY_AMMO");
	bHasLaser[client] = true;
	return Plugin_Handled;
}


public Action:CmdFirePack(client, args)
{
	CheatCommand(client, "add_upgrade", "INCENDIARY_AMMO");
	CheatCommand(client, "give", "molotov");
	CheatCommand(client, "give", "upgradepack_incendiary");
	CheatCommand(client, "give", "rifle");
	CheatCommand(client, "give", "machete");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdSmgPack(client, args)
{
	CheatCommand(client, "give", "smg");
	CheatCommand(client, "give", "first_aid_kit");
	CheatCommand(client, "upgrade_add", "laser_sight");
	CheatCommand(client, "give", "upgradepack_explosive");
	CheatCommand(client, "give", "upgradepack_incendiary"); 
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdRiflePack(client, args)
{
	CheatCommand(client, "give", "rifle");
	CheatCommand(client, "give", "first_aid_kit");
	CheatCommand(client, "upgrade_add", "laser_sight");
	CheatCommand(client, "give", "upgradepack_explosive");
	CheatCommand(client, "give", "upgradepack_explosive"); 
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdSniperPack(client, args)
{
	CheatCommand(client, "give", "sniper_military");
	CheatCommand(client, "give", "first_aid_kit");
	CheatCommand(client, "upgrade_add", "laser_sight");
	CheatCommand(client, "give", "pain_pills");
	
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdRandom(client, args)
{
	CheatCommand(client, "give", "ANY");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdWin(client, args)
{
	CheatCommand(client, "give", "ANY");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdRunOff(client, args)
{
	CheatCommand(client, "survivor_speed 210", "");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdRun(client, args)
{
	CheatCommand(client, "survivor_speed 1000", "");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdKill(client, args)
{
	CheatCommand(client, "kill", "");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdWeapon01(client, args)
{
	CheatCommand(client, "give", "chainsaw");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdGun11(client, args)
{
	CheatCommand(client, "give", "pistol");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdGun10(client, args)
{
	CheatCommand(client, "give", "pistol_magnum");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdGun09(client, args)
{
	CheatCommand(client, "give", "sniper_military");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdGun08(client, args)
{
	CheatCommand(client, "give", "hunting_rifle");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdGun07(client, args)
{
	CheatCommand(client, "give", "pumpshotgun");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdGun06(client, args)
{
	CheatCommand(client, "give", "shotgun_chrome");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdGun05(client, args)
{
	CheatCommand(client, "give", "shotgun_spas");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdGun04(client, args)
{
	CheatCommand(client, "give", "autoshotgun");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdGun03(client, args)
{
	CheatCommand(client, "give", "rifle_ak47");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdGun02(client, args)
{
	CheatCommand(client, "give", "rifle_desert");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdGun01(client, args)
{
	CheatCommand(client, "give", "rifle");
	bHasLaser[client] = true;
	return Plugin_Handled;
}


public Action:CmdDash(client, args)
{
	CheatCommand(client, "give", "adrenaline");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdPlayerDeath(client, args)
{
	CheatCommand(client, "give", "Defibrillator");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdFire(client, args)
{
	CheatCommand(client, "give", "molotov");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdBoom(client, args)
{
	CheatCommand(client, "give", "pipe_bomb");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdFireAmmoPack(client, args)
{
	CheatCommand(client, "give", "upgradepack_incendiary");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdExplodeAmmoPack(client, args)
{
	CheatCommand(client, "give", "upgradepack_explosive");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdFireAmmo(client, args)
{
	CheatCommand(client, "give", "upgradepack_incendiary");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdExplodeAmmo(client, args)
{
	CheatCommand(client, "give", "upgradepack_explosive");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdAmmo_Pack(client, args)
{
	CheatCommand(client, "give", "ammo_pack");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdPistol(client, args)
{
	CheatCommand(client, "give", "pistol");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdSmg(client, args)
{
	CheatCommand(client, "give", "smg");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdRifle(client, args)
{
	CheatCommand(client, "give", "rifle");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdPipeBomb(client, args)
{
	CheatCommand(client, "give", "pipe_bomb");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdAutoShotgun(client, args)
{
	CheatCommand(client, "give", "autoshotgun");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdAdrenaline(client, args)
{
	CheatCommand(client, "give", "adrenaline");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdChainsaw(client, args)
{
	CheatCommand(client, "give", "chainsaw");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdDefibrillator(client, args)
{
	CheatCommand(client, "give", "defibrillator");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdSniper_military(client, args)
{
	CheatCommand(client, "give", "sniper_military");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdMolotov(client, args)
{
	CheatCommand(client, "give", "molotov");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdSmg_silenced(client, args)
{
	CheatCommand(client, "give", "smg_silenced");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdAmmo(client, args)
{
	CheatCommand(client, "give", "ammo");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdPills(client, args)
{
	CheatCommand(client, "give", "pain_pills");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdFirst_Aid_Kit(client, args)
{
	CheatCommand(client, "give", "first_aid_kit");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdHunting_Rifle(client, args)
{
	CheatCommand(client, "give", "hunting_rifle");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdShotgun_Spas(client, args)
{
	CheatCommand(client, "give", "shotgun_spas");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdShotgun_Chrome(client, args)
{
	CheatCommand(client, "give", "shotgun_chrome");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdRifle_Desert(client, args)
{
	CheatCommand(client, "give", "rifle_desert");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdRifle_Ak47(client, args)
{
	CheatCommand(client, "give", "rifle_ak47");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdPistol_Magnum(client, args)
{
	CheatCommand(client, "give", "pistol_magnum");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdPumpShotgun(client, args)
{ 
	CheatCommand(client, "give", "pumpshotgun");
	bHasLaser[client] = true;
	return Plugin_Handled;
}


public Action:CmdLaserOn(client, args)
{ 
	CheatCommand(client, "upgrade_add", "LASER_SIGHT");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

public Action:CmdLaserOff(client, args)
{ 
	CheatCommand(client, "upgrade_remove", "LASER_SIGHT");
	bHasLaser[client] = false;
	return Plugin_Handled;
}

public Action:CmdLaser(client, args)
{
	CheatCommand(client, "upgrade_add", "LASER_SIGHT");
	bHasLaser[client] = true;
	return Plugin_Handled;
}


public Action:CmdGivegrenade_launcher(client, args)
{
	CheatCommand(client, "give", "grenade_launcher");
	bHasLaser[client] = true;
	return Plugin_Handled;
}


public Action:CmdHealth(client, args)
{
	CheatCommand(client, "give", "health");
	bHasLaser[client] = true;
	return Plugin_Handled;
}


public Action:CmdLaserToggle(client, args)
{
	if (bHasLaser[client])
	{
		CmdLaserOff(client, 0);
	}
	else
	{
		CmdLaserOn(client, 0);
	}
	{
		CmdLaser(client, 0);
	}
	{
		CmdGivegrenade_launcher(client, 0);
	}
	{
		CmdHealth(client, 0);
	}
	{
		CmdRifle(client, 0);
	}
	return Plugin_Handled;
}

CheatCommand(client, const String:command[], const String:arguments[])
{
    if (!client) return;
    new admindata = GetUserFlagBits(client);
    SetUserFlagBits(client, ADMFLAG_ROOT);
    new flags = GetCommandFlags(command);
    SetCommandFlags(command, flags & ~FCVAR_CHEAT);
    FakeClientCommand(client, "%s %s", command, arguments);
    SetCommandFlags(command, flags);
	//Add the CHEAT flag back to "give" command
    SetCommandFlags("give", flags|FCVAR_CHEAT);
    SetUserFlagBits(client, admindata);
}

public OnClientPutInServer(client)
{
	decl String:Name[64]
	GetClientName(client, Name, sizeof(Name))
	PrintHintText(client, "%s has joined the game", Name)
}