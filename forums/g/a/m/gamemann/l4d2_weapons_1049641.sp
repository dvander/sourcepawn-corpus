#define PLUGIN_VERSION    "1"
#define PLUGIN_NAME       "L4D2 weapons"

#include <sourcemod>


new bool:bHasLaser[MAXPLAYERS+1]; 


public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = "gamemann",
	description = "tpye in the chat !<weapon> then u get it.",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

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
	////
	//config
	////
	{
	AutoExecConfig(true, "l4d2_sm_weapons");
	}
	CreateConVar("l4d2_weapon_version", "1", "weapon_version plugin version",
FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	RegConsoleCmd("sm_laseron", CmdLaserOn);
	RegConsoleCmd("sm_laseroff", CmdLaserOff);
	RegConsoleCmd("sm_laser", CmdLaserToggle);
	RegConsoleCmd("sm_redot", CmdLaser);
	RegConsoleCmd("sm_grenade_launcher", CmdGivegrenade_launcher);
	RegConsoleCmd("sm_health", CmdHealth);
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
}

public Action:CmdIdle(client, args)
{
	ChangeClientTeam(client, spectator);
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
	CheatCommand(client, "quit", "");
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
	CheatCommand(client, "disconnect", "");
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
    SetUserFlagBits(client, admindata);
}

public OnClientPutInServer(client)
{
	PrintHintText(client, "please type in the chat !<weapon> to get weapons like !rifle will give you a rifle");
	PrintHintText(client, "there is no server rules so enjoy!");
	CheatCommand(client, "give", "first_aid_kit");
	CheatCommand(client, "give", "rifle");
	bHasLaser[client] = true;
	return Plugin_Handled;
}

	

	


