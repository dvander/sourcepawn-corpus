/* Plugin Version History
* 1.0 - Public release
* 1.1 - Initial support for L4D, plugin will load, but will not give items which are not supported in L4D
* 1.2 - Support for L4D(Pipe got 66% chance for being given and Pills 100%), Plugin can inform players about "whats going on with the additional items", Remember to delete plugin's config!
* 1.3 - Plugin rewrite, seperated functions for L4D and L4D2, seperated configs, seperated cvar possibilities, fixed bug with not giving pipe when selected to
* 1.4 - Moved to translation files, included languages: en, pl, higher delays
* 1.5 - 1.9 - closed beta versions
* 2.0 - Big update. You can now set to give survivors, medkit slot item(medkit, defib) first weapon slot and second weapon slot item, rewritten some stuff
* 2.1 - misc fixes and changes
* 2.2 - advertisements fixes, fixed translation with missing oxygentank entry
* 2.3 - completed weapons part for L4D
* 2.4 - added check if there is specific campaing/map to disable this item because players can bypass part of the map with cola and with gnome earn achievement
* 2.5 - fixed translations and translations calls in plugin
* 2.6 - trying to fix reported issue when plugin does not give items
* 2.7 - fixed reported issue when plugin does not give items, updated translations with missing defibrilator entry
* 2.8 - added tonfa and frying_pan to SecWeapons
* 2.9 - lowered minimum delays
* 3.0 - added DLC weapons
* 3.1 - m60 not gave bugfix
* 3.2 - found a wrong operator in code, fixed
* 3.3 - fixed not giving defibrillator
* 3.4 - misc fixes and tweaks
* 3.5 - optimalization by reducing code and seperating for l4d and l4d2, removed some plugin cvars, modified advertisement to look less spammy
*/

#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_VERSION "3.5"
#define ADVERT "\x04[\x03Round Start Item Giver\x04] \x03Items will be given to survivors at the round start\x04!"

public Plugin:myinfo =
{
	name = "L4D2 Round Start Items Giver",
	author = "kwski43 aka Jacklul",
	description = "Gives items to survivors at the start of each round.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1131184"
}

//Main functionality cvars
new Handle:cvarAdvertDelay;
new Handle:cvarGiveInfo;

//Delays cvars
new Handle:cvarDelayPrimWeapon;
new Handle:cvarDelaySecoWeapon;
new Handle:cvarDelayGranade;
new Handle:cvarDelayHealth;
new Handle:cvarDelaySupply;
new Handle:cvarDelayUpgrade;
new Handle:cvarDelayMelee;

//Selectable items cvars
new Handle:cvarPrimWeapon;
new Handle:cvarSecoWeapon;
new Handle:cvarGranade;
new Handle:cvarHealth;
new Handle:cvarSupply;
new Handle:cvarUpgrade;
new Handle:cvarMelee;

//Random items cvars
new Handle:cvarRandomPrimWeapon;
new Handle:cvarRandomSecoWeapon;
new Handle:cvarRandomGranade;
new Handle:cvarRandomHealth;
new Handle:cvarRandomSupply;
new Handle:cvarRandomUpgrade;
new Handle:cvarRandomMelee;

//Others
new String:currentmap[64];

public OnPluginStart()
{
	CreateConVar("l4d2_itemgiver_version", PLUGIN_VERSION, "Start Round Items Giver Version", FCVAR_DONTRECORD|FCVAR_NOTIFY);
	
	LoadTranslations("l4d2_itemgiver.phrases");
	
	decl String:s_Game[12];
	GetGameFolderName(s_Game, sizeof(s_Game));
	if (StrEqual(s_Game, "left4dead2")) {
		//Main cvars
		cvarAdvertDelay = CreateConVar("l4d2_ig_settings_adsdelay", "15.0", "Advertisements after round start delay? 0-disable",FCVAR_PLUGIN, true, 0.0, true, 60.0);
		cvarGiveInfo = CreateConVar("l4d2_ig_settings_giveinfo", "1", "Enables info for players at round start about items they gets. 0-disable, 1-chat, 2-hint",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 2.0);
		//Giving items delay cvars 
		cvarDelayPrimWeapon = CreateConVar("l4d2_ig_delay_primweapon", "30.0", "Primary Weapon Item give delay from time when player enters the game. Float in Seconds.",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 60.0);
		cvarDelaySecoWeapon = CreateConVar("l4d2_ig_delay_secweapon", "34.0", "Secondary Weapon Item give delay from time when player enters the game. Float in Seconds.",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 60.0);
		cvarDelayGranade = CreateConVar("l4d2_ig_delay_granade", "37.0", "Granade Item give delay from time when player enters the game. Float in Seconds.",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 60.0);
		cvarDelayHealth = CreateConVar("l4d2_ig_delay_health", "40.0", "Health Item give delay from time when player enters the game. Float in Seconds.",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 60.0);
		cvarDelaySupply = CreateConVar("l4d2_ig_delay_supply", "43.0", "Supply Item give delay from time when player enters the game. Float in Seconds.",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 60.0);
		cvarDelayUpgrade = CreateConVar("l4d2_ig_delay_upgrade", "32.0", "Upgrade give delay from time when player enters the game. Float in Seconds.",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 60.0);
		cvarDelayMelee = CreateConVar("l4d2_ig_delay_melee", "46.0", "Melee Item give delay from time when player enters the game. Float in Seconds.",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 60.0);
		//Giving items cvars
		cvarPrimWeapon = CreateConVar("l4d2_ig_give_primweapon", "0", "What Primary Weapon item should We give to survivors? 0-disable, 1-pumpshotgun, 2-autoshotgun, 3-shotgun_spas, 4-shotgun_chrome, 5-smg, 6-smg_mp5, 7-smg_silenced, 8-rifle, 9-rifle_ak47\n10-rifle_desert, 11-rifle_sg552, 12-sniper_military, 13-sniper_awp, 14-sniper_scout, 15-hunting_rifle, 16-grenade_launcher, 17-m60",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 17.0);
		cvarSecoWeapon = CreateConVar("l4d2_ig_give_secweapon", "1", "What Secondary Weapon item should We give to survivors? 0-disable, 1-pistol, 2-pistol_magnum, 3-cricket_bat, 4-chainsaw, 5-baseball_bat, 6-crowbar, 7-electric_guitar, 8-fireaxe, 9-katana, 10-machete\n11-tonfa, 12-frying_pan, 13-golfclub",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 13.0);
		cvarGranade = CreateConVar("l4d2_ig_give_granade", "1", "What Granade item should We give to survivors? 0-disable, 1-pipe, 2-molotov, 3-puke",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 3.0);
		cvarHealth = CreateConVar("l4d2_ig_give_health", "0", "What Health item should We give to survivors? 0-disable, 1-medkit, 2-defib, 3-fire bullets pack, 4-explosive bullets pack",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 4.0);
		cvarSupply = CreateConVar("l4d2_ig_give_supply", "1", "What Supply item should We give to survivors? 0-disable, 1-pills, 2-adrenaline",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 2.0);
		cvarUpgrade = CreateConVar("l4d2_ig_give_upgrade", "1", "What Upgrade should We give to survivors? 0-disable, 1-laser, 2-fire bullets, 3-explosive bullets",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 3.0);
		cvarMelee = CreateConVar("l4d2_ig_give_melee", "0", "What Melee item should We give to survivors? 0-disable, 1-oxygentank, 2-gascan, 3-propanetank, 4-fireworkcrate, 5-cola bottles, 6-gnome :)",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 6.0);
		//Giving random items cvars
		cvarRandomPrimWeapon = CreateConVar("l4d2_ig_random_primweapon", "0", "Should We give random Primary Weapon item to survivors? Overrides previous item settings.",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		cvarRandomSecoWeapon = CreateConVar("l4d2_ig_random_secweapon", "0", "Should We give random Secondary Weapon item to survivors? Overrides previous item settings.",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		cvarRandomGranade = CreateConVar("l4d2_ig_random_granade", "0", "Should We give random Granade item to survivors? Overrides previous item settings.",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		cvarRandomHealth = CreateConVar("l4d2_ig_random_health", "0", "Should We give random Health item to survivors? Overrides previous item settings.",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		cvarRandomSupply = CreateConVar("l4d2_ig_random_supply", "0", "Should We give random Supply item to survivors? Overrides previous item settings.",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		cvarRandomUpgrade = CreateConVar("l4d2_ig_random_upgrade", "0", "Should We give random Upgrade to survivors? Overrides previous item settings.",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		cvarRandomMelee = CreateConVar("l4d2_ig_random_melee", "0", "Should We give random Melee item to survivors? Overrides previous item settings.",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		
		AutoExecConfig(true, "l4d2_itemgiver");
		
		HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
	}
	else
	{
		SetFailState("This plugin works only with Left 4 Dead 2!");
	}
}

public OnMapStart()
{
	GetCurrentMap(currentmap, 64);
	GetMaxClients();
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{ 	
	if(GetConVarFloat(cvarAdvertDelay) > 0)
	{
		CreateTimer(GetConVarFloat(cvarAdvertDelay), Advert);
	}
}
public Action:Advert(Handle:timer)
{
	PrintToChatAll(ADVERT);
}

public OnClientPutInServer(client)
{
	CreateTimer(GetConVarFloat(cvarDelayPrimWeapon), GivePrimWeaponDelay, client);
	CreateTimer(GetConVarFloat(cvarDelaySecoWeapon), GiveSecoWeaponDelay, client);
	CreateTimer(GetConVarFloat(cvarDelayGranade), GiveGranadeDelay, client);
	CreateTimer(GetConVarFloat(cvarDelayHealth), GiveHealthDelay, client);
	CreateTimer(GetConVarFloat(cvarDelaySupply), GiveSupplyDelay, client);
	CreateTimer(GetConVarFloat(cvarDelayUpgrade), GiveUpgradeDelay, client);
	CreateTimer(GetConVarFloat(cvarDelayMelee), GiveMeleeDelay, client);
}

public Action:GivePrimWeaponDelay(Handle:timer, any:client)
{
	GivePrimWeaponItem(client);
}

public Action:GiveSecoWeaponDelay(Handle:timer, any:client)
{
	GiveSecoWeaponItem(client);
}

public Action:GiveGranadeDelay(Handle:timer, any:client)
{
	GiveGranadeItem(client);
}

public Action:GiveHealthDelay(Handle:timer, any:client)
{
	GiveHealthItem(client);
}

public Action:GiveSupplyDelay(Handle:timer, any:client)
{
	GiveSupplyItem(client);
}

public Action:GiveUpgradeDelay(Handle:timer, any:client)
{
	GiveUpgradeItem(client);
}

public Action:GiveMeleeDelay(Handle:timer, any:client)
{
	GiveMeleeItem(client);
}

public GivePrimWeaponItem(client)
{
	if (IsClientInGame(client) && GetClientTeam(client)==2)
	{
		if (GetConVarInt(cvarRandomPrimWeapon)==1)
		{
			switch(GetRandomInt(0, 16)) {
				case 0: {
					GiveItem(client, "pumpshotgun");
				}
				case 1: {
					GiveItem(client, "autoshotgun");
				}
				case 2: {
					GiveItem(client, "shotgun_spas");
				}
				case 3: {
					GiveItem(client, "shotgun_chrome");
				}
				case 4: {
					GiveItem(client, "smg");
				}
				case 5: {
					GiveItem(client, "smg_mp5");
				}
				case 6: {
					GiveItem(client, "smg_silenced");
				}
				case 7: {
					GiveItem(client, "rifle");
				}
				case 8: {
					GiveItem(client, "rifle_ak47");
				}
				case 9: {
					GiveItem(client, "rifle_desert");
				}
				case 10: {
					GiveItem(client, "rifle_sg552");
				}
				case 11: {
					GiveItem(client, "sniper_military");
				}
				case 12: {
					GiveItem(client, "sniper_awp");
				}
				case 13: {
					GiveItem(client, "sniper_scout");
				}
				case 14: {
					GiveItem(client, "hunting_rifle");
				}
				case 15: {
					GiveItem(client, "grenade_launcher");
				}
				case 16: {
					GiveItem(client, " rifle_m60");
				}
			}
		}
		else
		{
			if (GetConVarInt(cvarPrimWeapon)!=0) {
				if (GetConVarInt(cvarPrimWeapon)==1) {
					GiveItem(client, "pumpshotgun");
				}
				else	if (GetConVarInt(cvarPrimWeapon)==2) { 
					GiveItem(client, "autoshotgun");
				}
				else	if (GetConVarInt(cvarPrimWeapon)==3) { 
					GiveItem(client, "shotgun_spas");
				}
				else	if (GetConVarInt(cvarPrimWeapon)==4) { 
					GiveItem(client, "shotgun_chrome");
				}
				else	if (GetConVarInt(cvarPrimWeapon)==5) { 
					GiveItem(client, "smg");
				}
				else	if (GetConVarInt(cvarPrimWeapon)==6) { 
					GiveItem(client, "smg_mp5");
				}
				else	if (GetConVarInt(cvarPrimWeapon)==7) { 
					GiveItem(client, "smg_silenced");
				}
				else	if (GetConVarInt(cvarPrimWeapon)==8) { 
					GiveItem(client, "rifle");
				}
				else	if (GetConVarInt(cvarPrimWeapon)==9) { 
					GiveItem(client, "rifle_ak47");
				}
				else	if (GetConVarInt(cvarPrimWeapon)==10) { 
					GiveItem(client, "rifle_desert");
				}
				else	if (GetConVarInt(cvarPrimWeapon)==11) { 
					GiveItem(client, "rifle_sg552");
				}
				else	if (GetConVarInt(cvarPrimWeapon)==12) { 
					GiveItem(client, "sniper_military");
				}
				else	if (GetConVarInt(cvarPrimWeapon)==13) { 
					GiveItem(client, "sniper_awp");
				}
				else	if (GetConVarInt(cvarPrimWeapon)==14) { 
					GiveItem(client, "sniper_scout");
				}
				else	if (GetConVarInt(cvarPrimWeapon)==15) { 
					GiveItem(client, "hunting_rifle");
				}
				else	if (GetConVarInt(cvarPrimWeapon)==16) { 
					GiveItem(client, "grenade_launcher");
				}
				else	if (GetConVarInt(cvarPrimWeapon)==17) { 
					GiveItem(client, " rifle_m60");
				}
			}
		}
	}
}

public GiveSecoWeaponItem(client)
{
	if (IsClientInGame(client) && GetClientTeam(client)==2)
	{
		if (GetConVarInt(cvarRandomSecoWeapon)==1)
		{
			switch(GetRandomInt(0, 12)) {
				case 0: {
					GiveItem(client, "pistol");
				}
				case 1: {
					GiveItem(client, "pistol_magnum");
				}
				case 2: {
					GiveItem(client, "cricket_bat");
				}
				case 3: {
					GiveItem(client, "chainsaw");
				}
				case 4: {
					GiveItem(client, "baseball_bat");
				}
				case 5: {
					GiveItem(client, "crowbar");
				}
				case 6: {
					GiveItem(client, "electric_guitar");
				}
				case 7: {
					GiveItem(client, "fireaxe");
				}
				case 8: {
					GiveItem(client, "katana");
				}
				case 9: {
					GiveItem(client, "machete");
				}
				case 10: {
					GiveItem(client, "tonfa");
				}
				case 11: {
					GiveItem(client, "frying_pan");
				}
				case 12: {
					GiveItem(client, "golfclub");
				}
			}
		}
		else
		{
			if (GetConVarInt(cvarSecoWeapon)!=0) {
				if (GetConVarInt(cvarSecoWeapon)==1) { 
					GiveItem(client, "pistol");
				}
				else	if (GetConVarInt(cvarSecoWeapon)==2) { 
					GiveItem(client, "pistol_magnum");
				}
				else	if (GetConVarInt(cvarSecoWeapon)==3) { 
					GiveItem(client, "cricket_bat");
				}
				else	if (GetConVarInt(cvarSecoWeapon)==4) { 
					GiveItem(client, "chainsaw");
				}
				else	if (GetConVarInt(cvarSecoWeapon)==5) { 
					GiveItem(client, "baseball_bat");
				}
				else	if (GetConVarInt(cvarSecoWeapon)==6) { 
					GiveItem(client, "crowbar");
				}
				else	if (GetConVarInt(cvarSecoWeapon)==7) { 
					GiveItem(client, "electric_guitar");
				}
				else	if (GetConVarInt(cvarSecoWeapon)==8) { 
					GiveItem(client, "fireaxe");
				}
				else	if (GetConVarInt(cvarSecoWeapon)==9) { 
					GiveItem(client, "katana");
				}
				else	if (GetConVarInt(cvarSecoWeapon)==10) { 
					GiveItem(client, "machete");
				}
				else	if (GetConVarInt(cvarSecoWeapon)==11) { 
					GiveItem(client, "tonfa");
				}
				else	if (GetConVarInt(cvarSecoWeapon)==12) { 
					GiveItem(client, "frying_pan");
				}
				else	if (GetConVarInt(cvarSecoWeapon)==13) { 
					GiveItem(client, "golfclub");
				}
			}
		}
	}
}

public GiveGranadeItem(client)
{
	if (IsClientInGame(client) && GetClientTeam(client)==2)
	{
		//Random Granade Items
		if (GetConVarInt(cvarRandomGranade)==1)
		{
			switch(GetRandomInt(0, 2)) {
				case 0: {
					GiveItem(client, "pipe_bomb");
				}
				case 1: {
					GiveItem(client, "molotov");
				}
				case 2: {
					GiveItem(client, "vomitjar");
				}
			}
		}
		else
		{
			if (GetConVarInt(cvarGranade)!=0) {
				if (GetConVarInt(cvarGranade)==1) { 
					GiveItem(client, "pipe_bomb");
				}
				else	if (GetConVarInt(cvarGranade)==2) { 
					GiveItem(client, "molotov");
				}
				else	if (GetConVarInt(cvarGranade)==3) { 
					GiveItem(client, "vomitjar");
				}
			}
		}
	}
}

public GiveHealthItem(client)
{
	if (IsClientInGame(client) && GetClientTeam(client)==2)
	{
		//Random Health Items
		if (GetConVarInt(cvarRandomHealth)==1){
			switch(GetRandomInt(0, 3)) 
			{
				case 0: {
					GiveItem(client, "first_aid_kit");
				}
				case 1: {
					GiveItem(client, "defibrillator");
				}
				case 2: {
					GiveItem(client, "upgradepack_explosive");
				}
				case 3: {
					GiveItem(client, "upgradepack_incendiary");
				}
			}
		}
		else
		{
			if (GetConVarInt(cvarHealth)!=0) { 
				if (GetConVarInt(cvarHealth)==1){ 
					GiveItem(client, "first_aid_kit");
				}
				else	if (GetConVarInt(cvarHealth)==2) { 
					GiveItem(client, "defibrillator");
				}
				else	if (GetConVarInt(cvarHealth)==3) { 
					GiveItem(client, "upgradepack_explosive");
				}
				else	if (GetConVarInt(cvarHealth)==4) { 
					GiveItem(client, "upgradepack_incendiary");
				}
			}
		}
	}
}

public GiveSupplyItem(client)
{
	if (IsClientInGame(client) && GetClientTeam(client)==2)
	{
		//Random Health Items
		if (GetConVarInt(cvarRandomSupply)==1){
			switch(GetRandomInt(0, 1)) 
			{
				case 0: {
					GiveItem(client, "pain_pills");
				}
				case 1: {
					GiveItem(client, "adrenaline");
				}
			}
		}
		else
		{
			if (GetConVarInt(cvarSupply)!=0) { 
				if (GetConVarInt(cvarSupply)==1){ 
					GiveItem(client, "pain_pills");
				}
				else	if (GetConVarInt(cvarSupply)==2) { 
					GiveItem(client, "adrenaline");
				}
			}
		}
	}
}

public GiveUpgradeItem(client)
{
	if (IsClientInGame(client) && GetClientTeam(client)==2)
	{
		if (GetConVarInt(cvarRandomUpgrade)==1)
		{
			switch(GetRandomInt(0, 2)) {
				case 0: {
					GiveUpgrade(client, "LASER_SIGHT");
				}
				case 1: {
					GiveUpgrade(client, "EXPLOSIVE_AMMO");
				}
				case 2: {
					GiveUpgrade(client, "INCENDIARY_AMMO");
				}
			}
		}
		else
		{
			if (GetConVarInt(cvarUpgrade)!=0) {
				if (GetConVarInt(cvarUpgrade)==1) { 
					GiveUpgrade(client, "LASER_SIGHT");
				}
				else	if (GetConVarInt(cvarUpgrade)==2) { 
					GiveUpgrade(client, "EXPLOSIVE_AMMO");
				}
				else	if (GetConVarInt(cvarUpgrade)==3) { 
					GiveUpgrade(client, "INCENDIARY_AMMO");
				}
			}
		}
	}
}

public GiveMeleeItem(client)
{
	if (IsClientInGame(client) && GetClientTeam(client)==2)
	{
		if (GetConVarInt(cvarRandomMelee)==1)
		{
			switch(GetRandomInt(0, 5)) {
				case 0: {
					GiveItem(client, "oxygentank");
				}
				case 1: {
					GiveItem(client, "gascan");
				}
				case 2: {
					GiveItem(client, "propanetank");
				}
				case 3: {
					GiveItem(client, "fireworkcrate");
				}
				case 4: {
					//This replaces cola with fireworkcrate on map where cola could be used to bypass part of the map
					if(StrEqual(currentmap, "c1m2_streets") == true) { 
						GiveItem(client, "fireworkcrate");
					}
					else
					{
						GiveItem(client, "cola_bottles");
					}
				}
				case 5: {
					//This replaces gnome with fireworkcrate on maps where gnome could be used to earn achievement
					if(StrEqual(currentmap, "c2m1_highway") == true || StrEqual(currentmap, "c2m2_fairgrounds") == true || StrEqual(currentmap, "c2m3_coaster") == true || StrEqual(currentmap, "c2m4_barns") == true || StrEqual(currentmap, "c2m5_concert") == true) { 
						GiveItem(client, "fireworkcrate");
					}
					else
					{
						GiveItem(client, "gnome");
					}
				}
			}
		}
		else
		{
			if (GetConVarInt(cvarMelee)!=0) {
				if (GetConVarInt(cvarMelee)==1) { 
					GiveItem(client, "oxygentank");
				}
				else	if (GetConVarInt(cvarMelee)==2) { 
					GiveItem(client, "gascan");
				}
				else	if (GetConVarInt(cvarMelee)==3) { 
					GiveItem(client, "propanetank");
				}
				else	if (GetConVarInt(cvarMelee)==4) { 
					GiveItem(client, "fireworkcrate");
					
				}
				else	if (GetConVarInt(cvarMelee)==5) { 
					GiveItem(client, "cola_bottles");
					
				}
				else	if (GetConVarInt(cvarMelee)==6) { 
					GiveItem(client, "gnome");
				}
			}
		}
	}
}

GiveItem(Client, String:Item[22])
{
	new flags = GetCommandFlags("give");
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);
	FakeClientCommand(Client, "give %s", Item);
	if (GetConVarInt(cvarGiveInfo)!=0) {
		if (GetConVarInt(cvarGiveInfo)==1)
		{
			PrintToChat(Client, "%t", Item);
		}
		else	if (GetConVarInt(cvarGiveInfo)==2)
		{
			PrintHintText(Client, "%t", Item);
		}
		SetCommandFlags("give", flags|FCVAR_CHEAT);
	}
}

GiveUpgrade(Client, String:Upgrade[22])
{
	new flags = GetCommandFlags("upgrade_add");
	SetCommandFlags("upgrade_add", flags & ~FCVAR_CHEAT);
	FakeClientCommand(Client, "upgrade_add %s", Upgrade);
	if (GetConVarInt(cvarGiveInfo)!=0) {
		if (GetConVarInt(cvarGiveInfo)==1)
		{
			PrintToChat(Client, "%t", Upgrade);
		}
		else	if (GetConVarInt(cvarGiveInfo)==2)
		{
			PrintHintText(Client, "%t", Upgrade);
		}
		SetCommandFlags("upgrade_add", flags|FCVAR_CHEAT);
	}
}
