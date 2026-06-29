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
*/

#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_VERSION "3.3"
#define ADVERT "\x03This server runs \x04[\x03Round Start Item Giver\x04]\x03\nItems will be given to survivors at the round start!"

public Plugin:myinfo =
{
	name = "L4D2 Round Start Items Giver",
	author = "kwski43 aka Jacklul",
	description = "Gives items to survivors at the start of each round.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1131184"
}

//Main functionality cvars
new Handle:cvarPluginVersion;
new Handle:cvarPluginEnable;
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
	cvarPluginVersion = CreateConVar("l4d2_itemgiver_version", PLUGIN_VERSION, "Start Round Items Giver Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	LoadTranslations("l4d2_itemgiver.phrases");
	
	decl String:s_Game[12];
	GetGameFolderName(s_Game, sizeof(s_Game));
	if (StrEqual(s_Game, "left4dead")) {
	LogMessage("Detected L4D.");
	
	cvarPluginEnable = CreateConVar("l4d_ig_enable", "1", "Enables automatic item giving at the round start.", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarAdvertDelay = CreateConVar("l4d_ig_adsdelay", "15.0", "Advertisements after round start delay? 0-disable",FCVAR_PLUGIN, true, 0.0, true, 60.0);
	cvarGiveInfo = CreateConVar("l4d_ig_giveinfo", "1", "Enables info for players at round start about items they get. 0-disable, 1-chat, 2-hint",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 2.0);

	cvarDelayPrimWeapon = CreateConVar("l4d_ig_delay_primweapon", "30.0", "Primary Weapon Item give delay from round start. Float in Seconds.",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 60.0);
	cvarDelaySecoWeapon = CreateConVar("l4d_ig_delay_secweapon", "34.0", "Secondary Weapon Item give delay from round start. Float in Seconds.",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 60.0);
	cvarDelayGranade = CreateConVar("l4d_ig_delay_granade", "37.0", "Granade Item give delay from round start. Float in Seconds.",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 60.0);
	cvarDelayHealth = CreateConVar("l4d_ig_delay_health", "40.0", "Health Item give delay from round start. Float in Seconds.",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 60.0);
	cvarDelaySupply = CreateConVar("l4d_ig_delay_supply", "43.0", "Supply Item give delay from round start. Float in Seconds.",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 60.0);
	cvarDelayMelee = CreateConVar("l4d_ig_delay_melee", "46.0", "Melee Item give delay from round start. Float in Seconds.",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 60.0);

	cvarPrimWeapon = CreateConVar("l4d_ig_give_primweapon", "0", "What Primary Weapon item should We give to survivors? 0-disable, 1-smg, 2-rifle, 3-pumpshotgun, 4-hunting_rifle, 5-autoshotgun",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 3.0);
	cvarSecoWeapon = CreateConVar("l4d_ig_give_secweapon", "1", "What Secondary Weapon item should We give to survivors? 0-disable, 1-pistol",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarGranade = CreateConVar("l4d_ig_give_granade", "1", "What Granade item should We give to survivors? 0-disable, 1-pipe, 2-molotov",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 2.0);
	cvarHealth = CreateConVar("l4d_ig_give_health", "0", "What Health item should We give to survivors? 0-disable, 1-medkit",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarSupply = CreateConVar("l4d_ig_give_supply", "1", "What Supply item should We give to survivors? 0-disable, 1-pills",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarMelee = CreateConVar("l4d_ig_give_melee", "0", "What Melee item should We give to survivors? 0-disable, 1-oxygentank, 2-gascan, 3-propanetank",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 3.0);

	cvarRandomPrimWeapon = CreateConVar("l4d_ig_random_primweapon", "0", "Should We give random Primary Weapon item to survivors? Overrides previous item settings.",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarRandomSecoWeapon = CreateConVar("l4d_ig_random_secweapon", "0", "Should We give random Secondary Weapon item to survivors? Overrides previous item settings.",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarRandomGranade = CreateConVar("l4d_ig_random_granade", "0", "Should We give random Granade item to survivors? Overrides previous item settings.",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarRandomHealth = CreateConVar("l4d_ig_random_health", "0", "Should We give random Health item to survivors? Overrides previous item settings.",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarRandomSupply = CreateConVar("l4d_ig_random_supply", "0", "Should We give random Supply item to survivors? Overrides previous item settings.",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarRandomMelee = CreateConVar("l4d_ig_random_melee", "0", "Should We give random Melee item to survivors? Overrides previous item settings.",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		
	AutoExecConfig(true, "l4d_itemgiver");
	
	if (GetConVarInt(cvarPluginEnable))
	{
		HookEvent("round_start", EventGiveItemsL4D, EventHookMode_Post);
		RegAdminCmd("sm_giveitems", Command_GiveItemsL4D, ADMFLAG_KICK, "Gives items to survivors using config file rules.");
		LogMessage("Plugin is ready.");
	}
	}
	if (StrEqual(s_Game, "left4dead2")) {
	LogMessage("Detected L4D2.");
	
	cvarPluginEnable = CreateConVar("l4d2_ig_settings_enable", "1", "Enables automatic item giving at the round start.", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarAdvertDelay = CreateConVar("l4d2_ig_settings_adsdelay", "15.0", "Advertisements after round start delay? 0-disable",FCVAR_PLUGIN, true, 0.0, true, 60.0);
	cvarGiveInfo = CreateConVar("l4d2_ig_settings_giveinfo", "1", "Enables info for players at round start about items they gets. 0-disable, 1-chat, 2-hint",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 2.0);

	cvarDelayPrimWeapon = CreateConVar("l4d2_ig_delay_primweapon", "30.0", "Primary Weapon Item give delay from round start. Float in Seconds.",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 60.0);
	cvarDelaySecoWeapon = CreateConVar("l4d2_ig_delay_secweapon", "34.0", "Secondary Weapon Item give delay from round start. Float in Seconds.",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 60.0);
	cvarDelayGranade = CreateConVar("l4d2_ig_delay_granade", "37.0", "Granade Item give delay from round start. Float in Seconds.",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 60.0);
	cvarDelayHealth = CreateConVar("l4d2_ig_delay_health", "40.0", "Health Item give delay from round start. Float in Seconds.",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 60.0);
	cvarDelaySupply = CreateConVar("l4d2_ig_delay_supply", "43.0", "Supply Item give delay from round start. Float in Seconds.",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 60.0);
	cvarDelayUpgrade = CreateConVar("l4d2_ig_delay_upgrade", "32.0", "Upgrade give delay from round start. Float in Seconds.",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 60.0);
	cvarDelayMelee = CreateConVar("l4d2_ig_delay_melee", "46.0", "Melee Item give delay from round start. Float in Seconds.",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 60.0);

	cvarPrimWeapon = CreateConVar("l4d2_ig_give_primweapon", "0", "What Primary Weapon item should We give to survivors? 0-disable, 1-pumpshotgun, 2-autoshotgun, 3-shotgun_spas, 4-shotgun_chrome, 5-smg, 6-smg_mp5, 7-smg_silenced, 8-rifle, 9-rifle_ak47\n10-rifle_desert, 11-rifle_sg552, 12-sniper_military, 13-sniper_awp, 14-sniper_scout, 15-hunting_rifle, 16-grenade_launcher, 17-m60",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 17.0);
	cvarSecoWeapon = CreateConVar("l4d2_ig_give_secweapon", "1", "What Secondary Weapon item should We give to survivors? 0-disable, 1-pistol, 2-pistol_magnum, 3-cricket_bat, 4-chainsaw, 5-baseball_bat, 6-crowbar, 7-electric_guitar, 8-fireaxe, 9-katana, 10-machete\n11-tonfa, 12-frying_pan, 13-golfclub",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 13.0);
	cvarGranade = CreateConVar("l4d2_ig_give_granade", "1", "What Granade item should We give to survivors? 0-disable, 1-pipe, 2-molotov, 3-puke",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 3.0);
	cvarHealth = CreateConVar("l4d2_ig_give_health", "0", "What Health item should We give to survivors? 0-disable, 1-medkit, 2-defib, 3-fire bullets pack, 4-explosive bullets pack",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 4.0);
	cvarSupply = CreateConVar("l4d2_ig_give_supply", "1", "What Supply item should We give to survivors? 0-disable, 1-pills, 2-adrenaline",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 2.0);
	cvarUpgrade = CreateConVar("l4d2_ig_give_upgrade", "1", "What Upgrade should We give to survivors? 0-disable, 1-laser, 2-fire bullets, 3-explosive bullets",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 3.0);
	cvarMelee = CreateConVar("l4d2_ig_give_melee", "0", "What Melee item should We give to survivors? 0-disable, 1-oxygentank, 2-gascan, 3-propanetank, 4-fireworkcrate, 5-cola bottles, 6-gnome :)",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 6.0);

	cvarRandomPrimWeapon = CreateConVar("l4d2_ig_random_primweapon", "0", "Should We give random Primary Weapon item to survivors? Overrides previous item settings.",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarRandomSecoWeapon = CreateConVar("l4d2_ig_random_secweapon", "0", "Should We give random Secondary Weapon item to survivors? Overrides previous item settings.",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarRandomGranade = CreateConVar("l4d2_ig_random_granade", "0", "Should We give random Granade item to survivors? Overrides previous item settings.",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarRandomHealth = CreateConVar("l4d2_ig_random_health", "0", "Should We give random Health item to survivors? Overrides previous item settings.",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarRandomSupply = CreateConVar("l4d2_ig_random_supply", "0", "Should We give random Supply item to survivors? Overrides previous item settings.",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarRandomUpgrade = CreateConVar("l4d2_ig_random_upgrade", "0", "Should We give random Upgrade to survivors? Overrides previous item settings.",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarRandomMelee = CreateConVar("l4d2_ig_random_melee", "0", "Should We give random Melee item to survivors? Overrides previous item settings.",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);

	AutoExecConfig(true, "l4d2_itemgiver");
	
	if (GetConVarInt(cvarPluginEnable))
	{
		HookEvent("round_start", EventGiveItemsL4D2, EventHookMode_Post);
		RegAdminCmd("sm_giveitems", Command_GiveItemsL4D2, ADMFLAG_KICK, "Gives items to survivors with 2s delays between each.");
		LogMessage("Plugin is ready.");
	}
	}
	else
	{
	SetFailState("This plugin works only with Left 4 Dead or Left 4 Dead 2!");
	}
	
	SetConVarString(cvarPluginVersion, PLUGIN_VERSION);
}

public OnMapStart()
{
GetCurrentMap(currentmap, 64);
GetMaxClients();
}

public Action:Advert(Handle:timer)
{
	PrintToChatAll(ADVERT);
}

//Left 4 Dead
public EventGiveItemsL4D(Handle:event, const String:name[], bool:dontBroadcast)
{
	LogMessage("Round Start, started Timers.");
	if(GetConVarFloat(cvarAdvertDelay) > 0) {
		CreateTimer(GetConVarFloat(cvarAdvertDelay), Advert);  }
	CreateTimer(GetConVarFloat(cvarDelayPrimWeapon), GivePrimWeaponDelayL4D);
	CreateTimer(GetConVarFloat(cvarDelaySecoWeapon), GiveSecoWeaponDelayL4D);
	CreateTimer(GetConVarFloat(cvarDelayGranade), GiveGranadeDelayL4D);
	CreateTimer(GetConVarFloat(cvarDelayHealth), GiveHealthDelayL4D);
	CreateTimer(GetConVarFloat(cvarDelaySupply), GiveSupplyDelayL4D);
	CreateTimer(GetConVarFloat(cvarDelayMelee), GiveMeleeDelayL4D);
}

public Action:GivePrimWeaponDelayL4D(Handle:timer)
{
	GivePrimWeaponItemToAllL4D();
}

public Action:GiveSecoWeaponDelayL4D(Handle:timer)
{
	GiveSecoWeaponItemToAllL4D();
}

public Action:GiveGranadeDelayL4D(Handle:timer)
{
	GiveGranadeItemToAllL4D();
}

public Action:GiveHealthDelayL4D(Handle:timer)
{
	GiveHealthItemToAllL4D();
}

public Action:GiveSupplyDelayL4D(Handle:timer)
{
	GiveSupplyItemToAllL4D();
}

public Action:GiveMeleeDelayL4D(Handle:timer)
{
	GiveMeleeItemToAllL4D();
}

public Action:Command_GiveItemsL4D(client, args)
{
	CreateTimer(1.0, GivePrimWeaponDelayL4D);
	CreateTimer(3.0, GiveSecoWeaponDelayL4D);
	CreateTimer(5.0, GiveGranadeDelayL4D);
	CreateTimer(8.0, GiveHealthDelayL4D);
	CreateTimer(11.0, GiveSupplyDelayL4D);
	CreateTimer(13.0, GiveMeleeDelayL4D);
}

public GivePrimWeaponItemToAllL4D()
{
	new flags = GetCommandFlags("give");
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && GetClientTeam(client)==2)
		{
			if (GetConVarInt(cvarRandomPrimWeapon)==1)
			{
				switch(GetRandomInt(0, 4)) {
					case 0: {
						FakeClientCommand(client, "give smg");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
								PrintToChat(client, "%t", "smg");
								}
								else if (GetConVarInt(cvarGiveInfo)==2)
								{
								PrintHintText(client, "%t", "smg");
								}
							}
						}
					case 1: {
						FakeClientCommand(client, "give rifle");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
								PrintToChat(client, "%t", "rifle");
								}
								else if (GetConVarInt(cvarGiveInfo)==2)
								{
								PrintHintText(client, "%t", "rifle");
								}
							}
						}
					case 2: {
						FakeClientCommand(client, "give pumpshotgun");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
								PrintToChat(client, "%t", "pumpshotgun");
								}
								else if (GetConVarInt(cvarGiveInfo)==2)
								{
								PrintHintText(client, "%t", "pumpshotgun");
								}
							}
						}
					case 3: {
						FakeClientCommand(client, "give hunting_rifle");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
								PrintToChat(client, "%t", "hunting_rifle");
								}
								else if (GetConVarInt(cvarGiveInfo)==2)
								{
								PrintHintText(client, "%t", "hunting_rifle");
								}
							}
						}
					case 4: {
						FakeClientCommand(client, "give autoshotgun");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
								PrintToChat(client, "%t", "autoshotgun");
								}
								else if (GetConVarInt(cvarGiveInfo)==2)
								{
								PrintHintText(client, "%t", "autoshotgun");
								}
							}
						}
					}
				}
				else
				{
				if (GetConVarInt(cvarPrimWeapon)!=0) {
					if (GetConVarInt(cvarPrimWeapon)==1) { 
						FakeClientCommand(client, "give smg");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
							PrintToChat(client, "%t", "smg");
							}
							else if (GetConVarInt(cvarGiveInfo)==2)
							{
							PrintHintText(client, "%t", "smg");
							}
						}
					}
					else	if (GetConVarInt(cvarPrimWeapon)==2) { 
						FakeClientCommand(client, "give rifle");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
							PrintToChat(client, "%t", "rifle");
							}
							else if (GetConVarInt(cvarGiveInfo)==2)
							{
							PrintHintText(client, "%t", "rifle");
							}
						}
					}
					else	if (GetConVarInt(cvarPrimWeapon)==3) { 
						FakeClientCommand(client, "give pumpshotgun");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
							PrintToChat(client, "%t", "pumpshotgun");
							}
							else if (GetConVarInt(cvarGiveInfo)==2)
							{
							PrintHintText(client, "%t", "pumpshotgun");
							}
						}
					}
					else	if (GetConVarInt(cvarPrimWeapon)==4) { 
						FakeClientCommand(client, "give hunting_rifle");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
							PrintToChat(client, "%t", "hunting_rifle");
							}
							else if (GetConVarInt(cvarGiveInfo)==2)
							{
							PrintHintText(client, "%t", "hunting_rifle");
							}
						}
					}
					else	if (GetConVarInt(cvarPrimWeapon)==5) { 
						FakeClientCommand(client, "give autoshotgun");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
							PrintToChat(client, "%t", "autoshotgun");
							}
							else if (GetConVarInt(cvarGiveInfo)==2)
							{
							PrintHintText(client, "%t", "autoshotgun");
							}
						}
					}
				}
			}
		}
	}
	SetCommandFlags("give", flags|FCVAR_CHEAT);
}

public GiveSecoWeaponItemToAllL4D()
{
	new flags = GetCommandFlags("give");
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && GetClientTeam(client)==2)
		{
			if (GetConVarInt(cvarRandomSecoWeapon)==1)
			{
				switch(GetRandomInt(0, 4)) {
					case 0: {
						FakeClientCommand(client, "give pistol");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
								PrintToChat(client, "%t", "pistol");
								}
								else if (GetConVarInt(cvarGiveInfo)==2)
								{
								PrintHintText(client, "%t", "pistol");
								}
							}
						}
					}
				}
				else
				{
				if (GetConVarInt(cvarSecoWeapon)!=0) {
					if (GetConVarInt(cvarSecoWeapon)==1) { 
						FakeClientCommand(client, "give pistol");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
							PrintToChat(client, "%t", "pistol");
							}
							else if (GetConVarInt(cvarGiveInfo)==2)
							{
							PrintHintText(client, "%t", "pistol");
							}
						}
					}
				}
			}
		}
	}
	SetCommandFlags("give", flags|FCVAR_CHEAT);
}

public GiveGranadeItemToAllL4D()
{
	new flags = GetCommandFlags("give");	
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);	
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && GetClientTeam(client)==2)
		{
			//Random Granade Items
			if (GetConVarInt(cvarRandomGranade)==1)
			{
				switch(GetRandomInt(0, 1)) {
					case 0: {
						FakeClientCommand(client, "give pipe_bomb");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
								PrintToChat(client, "%t", "pipe");
							}
							else if (GetConVarInt(cvarGiveInfo)==2)
							{
								PrintHintText(client, "%t", "pipe");
							}
						}
					}
					case 1: {
						FakeClientCommand(client, "give molotov");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
								PrintToChat(client, "%t", "molotov");
							}
							else if (GetConVarInt(cvarGiveInfo)==2)
							{
								PrintHintText(client, "%t", "molotov");
							}
						}
					}
				}
			}
			else
			//or set by user
			{
				if (GetConVarInt(cvarGranade)!=0) { 
					if (GetConVarInt(cvarGranade)==1) { 
						FakeClientCommand(client, "give pipe_bomb");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
								PrintToChat(client, "%t", "pipe");
							}
							else if (GetConVarInt(cvarGiveInfo)==2)
							{
								PrintHintText(client, "%t", "pipe");
							}	
						}
					}
					else if (GetConVarInt(cvarGranade)==2) { 
						FakeClientCommand(client, "give molotov");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
								PrintToChat(client, "%t", "molotov");
							}
							else if (GetConVarInt(cvarGiveInfo)==2)
							{
								PrintHintText(client, "%t", "molotov");
							}
						}
					}
				}
			}
		}	
	}
	SetCommandFlags("give", flags|FCVAR_CHEAT);
}


public GiveHealthItemToAllL4D()
{
	new flags = GetCommandFlags("give");	
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);	
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && GetClientTeam(client)==2)
		{
			//Random Health Items
			if (GetConVarInt(cvarRandomHealth)==1)	{
				switch(GetRandomInt(0, 0)) 
				{
					case 0: {
						FakeClientCommand(client, "give  first_aid_kit");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
								PrintToChat(client, "%t", "first_aid_kit");
							}
							else if (GetConVarInt(cvarGiveInfo)==2)
							{
								PrintHintText(client, "%t", "first_aid_kit");
							}
						}
					}
				}
			}	
			else
			//or set by user
			{
				if (GetConVarInt(cvarHealth)!=0) { 
					if (GetConVarInt(cvarHealth)==1){ 
						FakeClientCommand(client, "give  first_aid_kit");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
								PrintToChat(client, "%t", "first_aid_kit");
							}
							else if (GetConVarInt(cvarGiveInfo)==2)
							{
								PrintHintText(client, "%t", "first_aid_kit");
							}
						}
					}
				}	
			}
		}
	}
	SetCommandFlags("give", flags|FCVAR_CHEAT);
}

public GiveSupplyItemToAllL4D()
{
	new flags = GetCommandFlags("give");	
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);	
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && GetClientTeam(client)==2)
		{
			//Random Supply Items
			if (GetConVarInt(cvarRandomSupply)==1)	{
				switch(GetRandomInt(0, 0)) 
				{
					case 0: {
						FakeClientCommand(client, "give pain_pills");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
								PrintToChat(client, "%t", "pills");
							}
							else if (GetConVarInt(cvarGiveInfo)==2)
							{
								PrintHintText(client, "%t", "pills");
							}
						}
					}
				}
			}	
			else
			//or set by user
			{
				if (GetConVarInt(cvarSupply)!=0) { 
					if (GetConVarInt(cvarSupply)==1){ 
						FakeClientCommand(client, "give pain_pills");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
								PrintToChat(client, "%t", "pills");
							}
							else if (GetConVarInt(cvarGiveInfo)==2)
							{
								PrintHintText(client, "%t", "pills");
							}
						}
					}
				}	
			}
		}
	}
	SetCommandFlags("give", flags|FCVAR_CHEAT);
}

public GiveMeleeItemToAllL4D()
{
	new flags = GetCommandFlags("give");
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && GetClientTeam(client)==2)
		{
			if (GetConVarInt(cvarRandomMelee)==1)
			{
				switch(GetRandomInt(0, 3)) {
					case 0: {
						FakeClientCommand(client, "give oxygentank");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
								PrintToChat(client, "%t", "oxygentank");
								}
								else if (GetConVarInt(cvarGiveInfo)==2)
								{
								PrintHintText(client, "%t", "oxygentank");
								}
							}
						}
					case 1: {
						FakeClientCommand(client, "give gascan");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
								PrintToChat(client, "%t", "gascan");
								}
								else if (GetConVarInt(cvarGiveInfo)==2)
								{
								PrintHintText(client, "%t", "gascan");
								}
							}
						}
					case 2: {
						FakeClientCommand(client, "give propanetank");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
								PrintToChat(client, "%t", "propanetank");
								}
								else if (GetConVarInt(cvarGiveInfo)==2)
								{
								PrintHintText(client, "%t", "propanetank");
								}
							}
						}
					}
				}
				else
				{
				if (GetConVarInt(cvarMelee)!=0) {
					if (GetConVarInt(cvarMelee)==1) { 
						FakeClientCommand(client, "give oxygentank");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
							PrintToChat(client, "%t", "oxygentank");
							}
							else if (GetConVarInt(cvarGiveInfo)==2)
							{
							PrintHintText(client, "%t", "oxygentank");
							}
						}
					}
					else	if (GetConVarInt(cvarMelee)==2) { 
						FakeClientCommand(client, "give gascan");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
							PrintToChat(client, "%t", "gascan");
							}
							else if (GetConVarInt(cvarGiveInfo)==2)
							{
							PrintHintText(client, "%t", "gascan");
							}
						}
					}
					else if (GetConVarInt(cvarMelee)==3) { 
						FakeClientCommand(client, "give propanetank");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
							PrintToChat(client, "%t", "propanetank");
							}
							else if (GetConVarInt(cvarGiveInfo)==2)
							{
							PrintHintText(client, "%t", "propanetank");
							}
						}
					}
				}
			}
		}
	}
	SetCommandFlags("give", flags|FCVAR_CHEAT);
	
}

//Left 4 Dead 2
public EventGiveItemsL4D2(Handle:event, const String:name[], bool:dontBroadcast)
{
	LogMessage("Round Start, started Timers.");
	CreateTimer(GetConVarFloat(cvarAdvertDelay), Advert); 
	CreateTimer(GetConVarFloat(cvarDelayPrimWeapon), GivePrimWeaponDelayL4D2);
	CreateTimer(GetConVarFloat(cvarDelaySecoWeapon), GiveSecoWeaponDelayL4D2);
	CreateTimer(GetConVarFloat(cvarDelayGranade), GiveGranadeDelayL4D2);
	CreateTimer(GetConVarFloat(cvarDelayHealth), GiveHealthDelayL4D2);
	CreateTimer(GetConVarFloat(cvarDelaySupply), GiveSupplyDelayL4D2);
	CreateTimer(GetConVarFloat(cvarDelayUpgrade), GiveUpgradeDelayL4D2);
	CreateTimer(GetConVarFloat(cvarDelayMelee), GiveMeleeDelayL4D2);
}

public Action:GivePrimWeaponDelayL4D2(Handle:timer)
{
	GivePrimWeaponItemToAllL4D2();
}

public Action:GiveSecoWeaponDelayL4D2(Handle:timer)
{
	GiveSecoWeaponItemToAllL4D2();
}

public Action:GiveGranadeDelayL4D2(Handle:timer)
{
	GiveGranadeItemToAllL4D2();
}

public Action:GiveHealthDelayL4D2(Handle:timer)
{
	GiveHealthItemToAllL4D2();
}

public Action:GiveSupplyDelayL4D2(Handle:timer)
{
	GiveSupplyItemToAllL4D2();
}

public Action:GiveUpgradeDelayL4D2(Handle:timer)
{
	GiveUpgradeItemToAllL4D2();
}

public Action:GiveMeleeDelayL4D2(Handle:timer)
{
	GiveMeleeItemToAllL4D2();
}

public Action:Command_GiveItemsL4D2(client, args)
{
	CreateTimer(1.0, GivePrimWeaponDelayL4D2);
	CreateTimer(4.0, GiveSecoWeaponDelayL4D2);
	CreateTimer(6.0, GiveGranadeDelayL4D2);
	CreateTimer(8.0, GiveHealthDelayL4D2);
	CreateTimer(10.0, GiveSupplyDelayL4D2);
	CreateTimer(2.0, GiveUpgradeDelayL4D2);
	CreateTimer(12.0, GiveMeleeDelayL4D2);
}

public GivePrimWeaponItemToAllL4D2()
{
	new flags = GetCommandFlags("give");
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && GetClientTeam(client)==2)
		{
			if (GetConVarInt(cvarRandomPrimWeapon)==1)
			{
				switch(GetRandomInt(0, 16)) {
					case 0: {
						FakeClientCommand(client, "give pumpshotgun");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
								PrintToChat(client, "%t", "pumpshotgun");
								}
								else if (GetConVarInt(cvarGiveInfo)==2)
								{
								PrintHintText(client, "%t", "pumpshotgun");
								}
							}
						}
					case 1: {
						FakeClientCommand(client, "give autoshotgun");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
								PrintToChat(client, "%t", "autoshotgun");
								}
								else if (GetConVarInt(cvarGiveInfo)==2)
								{
								PrintHintText(client, "%t", "autoshotgun");
								}
							}
						}
					case 2: {
						FakeClientCommand(client, "give shotgun_spas");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
								PrintToChat(client, "%t", "shotgun_spas");
								}
								else if (GetConVarInt(cvarGiveInfo)==2)
								{
								PrintHintText(client, "%t", "shotgun_spas");
								}
							}
						}
					case 3: {
						FakeClientCommand(client, "give shotgun_chrome");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
								PrintToChat(client, "%t", "shotgun_chrome");
								}
								else if (GetConVarInt(cvarGiveInfo)==2)
								{
								PrintHintText(client, "%t", "shotgun_chrome");
								}
							}
						}
					case 4: {
						FakeClientCommand(client, "give smg");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
								PrintToChat(client, "%t", "smg");
								}
								else if (GetConVarInt(cvarGiveInfo)==2)
								{
								PrintHintText(client, "%t", "smg");
								}
							}
						}
					case 5: {
						FakeClientCommand(client, "give smg_mp5");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
								PrintToChat(client, "%t", "smg_mp5");
								}
								else if (GetConVarInt(cvarGiveInfo)==2)
								{
								PrintHintText(client, "%t", "smg_mp5");
								}
							}
						}
					case 6: {
						FakeClientCommand(client, "give smg_silenced");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
								PrintToChat(client, "%t", "smg_silenced");
								}
								else if (GetConVarInt(cvarGiveInfo)==2)
								{
								PrintHintText(client, "%t", "smg_silenced");
								}
							}
						}
					case 7: {
						FakeClientCommand(client, "give rifle");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
								PrintToChat(client, "%t", "rifle");
								}
								else if (GetConVarInt(cvarGiveInfo)==2)
								{
								PrintHintText(client, "%t", "rifle");
								}
							}
						}
					case 8: {
						FakeClientCommand(client, "give rifle_ak47");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
								PrintToChat(client, "%t", "rifle_ak47");
								}
								else if (GetConVarInt(cvarGiveInfo)==2)
								{
								PrintHintText(client, "%t", "rifle_ak47");
								}
							}
						}
					case 9: {
						FakeClientCommand(client, "give rifle_desert");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
								PrintToChat(client, "%t", "rifle_desert");
								}
								else if (GetConVarInt(cvarGiveInfo)==2)
								{
								PrintHintText(client, "%t", "rifle_desert");
								}
							}
						}
					case 10: {
						FakeClientCommand(client, "give rifle_sg552");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
								PrintToChat(client, "%t", "rifle_sg552");
								}
								else if (GetConVarInt(cvarGiveInfo)==2)
								{
								PrintHintText(client, "%t", "rifle_sg552");
								}
							}
						}
					case 11: {
						FakeClientCommand(client, "give sniper_military");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
								PrintToChat(client, "%t", "sniper_military");
								}
								else if (GetConVarInt(cvarGiveInfo)==2)
								{
								PrintHintText(client, "%t", "sniper_military");
								}
							}
						}
					case 12: {
						FakeClientCommand(client, "give sniper_awp");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
								PrintToChat(client, "%t", "sniper_awp");
								}
								else if (GetConVarInt(cvarGiveInfo)==2)
								{
								PrintHintText(client, "%t", "sniper_awp");
								}
							}
						}
					case 13: {
						FakeClientCommand(client, "give sniper_scout");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
								PrintToChat(client, "%t", "sniper_scout");
								}
								else if (GetConVarInt(cvarGiveInfo)==2)
								{
								PrintHintText(client, "%t", "sniper_scout");
								}
							}
						}
					case 14: {
						FakeClientCommand(client, "give hunting_rifle");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
								PrintToChat(client, "%t", "hunting_rifle");
								}
								else if (GetConVarInt(cvarGiveInfo)==2)
								{
								PrintHintText(client, "%t", "hunting_rifle");
								}
							}
						}
					case 15: {
						FakeClientCommand(client, "give grenade_launcher");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
								PrintToChat(client, "%t", "grenade_launcher");
								}
								else if (GetConVarInt(cvarGiveInfo)==2)
								{
								PrintHintText(client, "%t", "grenade_launcher");
								}
							}
						}
					case 16: {
						FakeClientCommand(client, "give  rifle_m60");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
								PrintToChat(client, "%t", " rifle_m60");
								}
								else if (GetConVarInt(cvarGiveInfo)==2)
								{
								PrintHintText(client, "%t", " rifle_m60");
								}
							}
						}
					}
				}
				else
				{
				if (GetConVarInt(cvarPrimWeapon)!=0) {
					if (GetConVarInt(cvarPrimWeapon)==1) { 
						FakeClientCommand(client, "give pumpshotgun");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
							PrintToChat(client, "%t", "pumpshotgun");
							}
							else if (GetConVarInt(cvarGiveInfo)==2)
							{
							PrintHintText(client, "%t", "pumpshotgun");
							}
						}
					}
					else	if (GetConVarInt(cvarPrimWeapon)==2) { 
						FakeClientCommand(client, "give autoshotgun");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
							PrintToChat(client, "%t", "autoshotgun");
							}
							else if (GetConVarInt(cvarGiveInfo)==2)
							{
							PrintHintText(client, "%t", "autoshotgun");
							}
						}
					}
					else	if (GetConVarInt(cvarPrimWeapon)==3) { 
						FakeClientCommand(client, "give shotgun_spas");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
							PrintToChat(client, "%t", "shotgun_spas");
							}
							else if (GetConVarInt(cvarGiveInfo)==2)
							{
							PrintHintText(client, "%t", "shotgun_spas");
							}
						}
					}
					else	if (GetConVarInt(cvarPrimWeapon)==4) { 
						FakeClientCommand(client, "give shotgun_chrome");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
							PrintToChat(client, "%t", "shotgun_chrome");
							}
							else if (GetConVarInt(cvarGiveInfo)==2)
							{
							PrintHintText(client, "%t", "shotgun_chrome");
							}
						}
					}
					else	if (GetConVarInt(cvarPrimWeapon)==5) { 
						FakeClientCommand(client, "give smg");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
							PrintToChat(client, "%t", "smg");
							}
							else if (GetConVarInt(cvarGiveInfo)==2)
							{
							PrintHintText(client, "%t", "smg");
							}
						}
					}
					else	if (GetConVarInt(cvarPrimWeapon)==6) { 
						FakeClientCommand(client, "give smg_mp5");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
							PrintToChat(client, "%t", "smg_mp5");
							}
							else if (GetConVarInt(cvarGiveInfo)==2)
							{
							PrintHintText(client, "%t", "smg_mp5");
							}
						}
					}
					else	if (GetConVarInt(cvarPrimWeapon)==7) { 
						FakeClientCommand(client, "give smg_silenced");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
							PrintToChat(client, "%t", "smg_silenced");
							}
							else if (GetConVarInt(cvarGiveInfo)==2)
							{
							PrintHintText(client, "%t", "smg_silenced");
							}
						}
					}
					else	if (GetConVarInt(cvarPrimWeapon)==8) { 
						FakeClientCommand(client, "give rifle");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
							PrintToChat(client, "%t", "rifle");
							}
							else if (GetConVarInt(cvarGiveInfo)==2)
							{
							PrintHintText(client, "%t", "rifle");
							}
						}
					}
					else	if (GetConVarInt(cvarPrimWeapon)==9) { 
						FakeClientCommand(client, "give rifle_ak47");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
							PrintToChat(client, "%t", "rifle_ak47");
							}
							else if (GetConVarInt(cvarGiveInfo)==2)
							{
							PrintHintText(client, "%t", "rifle_ak47");
							}
						}
					}
					else	if (GetConVarInt(cvarPrimWeapon)==10) { 
						FakeClientCommand(client, "give rifle_desert");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
							PrintToChat(client, "%t", "rifle_desert");
							}
							else if (GetConVarInt(cvarGiveInfo)==2)
							{
							PrintHintText(client, "%t", "rifle_desert");
							}
						}
					}
					else	if (GetConVarInt(cvarPrimWeapon)==11) { 
						FakeClientCommand(client, "give rifle_sg552");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
							PrintToChat(client, "%t", "rifle_sg552");
							}
							else if (GetConVarInt(cvarGiveInfo)==2)
							{
							PrintHintText(client, "%t", "rifle_sg552");
							}
						}
					}
					else	if (GetConVarInt(cvarPrimWeapon)==12) { 
						FakeClientCommand(client, "give sniper_military");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
							PrintToChat(client, "%t", "sniper_military");
							}
							else if (GetConVarInt(cvarGiveInfo)==2)
							{
							PrintHintText(client, "%t", "sniper_military");
							}
						}
					}
					else	if (GetConVarInt(cvarPrimWeapon)==13) { 
						FakeClientCommand(client, "give sniper_awp");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
							PrintToChat(client, "%t", "sniper_awp");
							}
							else if (GetConVarInt(cvarGiveInfo)==2)
							{
							PrintHintText(client, "%t", "sniper_awp");
							}
						}
					}
					else	if (GetConVarInt(cvarPrimWeapon)==14) { 
						FakeClientCommand(client, "give sniper_scout");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
							PrintToChat(client, "%t", "sniper_scout");
							}
							else if (GetConVarInt(cvarGiveInfo)==2)
							{
							PrintHintText(client, "%t", "sniper_scout");
							}
						}
					}
					else	if (GetConVarInt(cvarPrimWeapon)==15) { 
						FakeClientCommand(client, "give hunting_rifle");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
							PrintToChat(client, "%t", "hunting_rifle");
							}
							else if (GetConVarInt(cvarGiveInfo)==2)
							{
							PrintHintText(client, "%t", "hunting_rifle");
							}
						}
					}
					else	if (GetConVarInt(cvarPrimWeapon)==16) { 
						FakeClientCommand(client, "give grenade_launcher");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
							PrintToChat(client, "%t", "grenade_launcher");
							}
							else if (GetConVarInt(cvarGiveInfo)==2)
							{
							PrintHintText(client, "%t", "grenade_launcher");
							}
						}
					}
					else	if (GetConVarInt(cvarPrimWeapon)==17) { 
						FakeClientCommand(client, "give  rifle_m60");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
							PrintToChat(client, "%t", " rifle_m60");
							}
							else if (GetConVarInt(cvarGiveInfo)==2)
							{
							PrintHintText(client, "%t", " rifle_m60");
							}
						}
					}
				}
			}
		}
	}
	SetCommandFlags("give", flags|FCVAR_CHEAT);
}

public GiveSecoWeaponItemToAllL4D2()
{
	new flags = GetCommandFlags("give");
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && GetClientTeam(client)==2)
		{
			if (GetConVarInt(cvarRandomSecoWeapon)==1)
			{
				switch(GetRandomInt(0, 12)) {
					case 0: {
						FakeClientCommand(client, "give pistol");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
								PrintToChat(client, "%t", "pistol");
								}
								else if (GetConVarInt(cvarGiveInfo)==2)
								{
								PrintHintText(client, "%t", "pistol");
								}
							}
						}
					case 1: {
						FakeClientCommand(client, "give pistol_magnum");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
								PrintToChat(client, "%t", "pistol_magnum");
								}
								else if (GetConVarInt(cvarGiveInfo)==2)
								{
								PrintHintText(client, "%t", "pistol_magnum");
								}
							}
						}
					case 2: {
						FakeClientCommand(client, "give cricket_bat");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
								PrintToChat(client, "%t", "cricket_bat");
								}
								else if (GetConVarInt(cvarGiveInfo)==2)
								{
								PrintHintText(client, "%t", "cricket_bat");
								}
							}
						}
					case 3: {
						FakeClientCommand(client, "give chainsaw");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
								PrintToChat(client, "%t", "chainsaw");
								}
								else if (GetConVarInt(cvarGiveInfo)==2)
								{
								PrintHintText(client, "%t", "chainsaw");
								}
							}
						}
					case 4: {
						FakeClientCommand(client, "give baseball_bat");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
								PrintToChat(client, "%t", "baseball_bat");
								}
								else if (GetConVarInt(cvarGiveInfo)==2)
								{
								PrintHintText(client, "%t", "baseball_bat");
								}
							}
						}
					case 5: {
						FakeClientCommand(client, "give crowbar");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
								PrintToChat(client, "%t", "crowbar");
								}
								else if (GetConVarInt(cvarGiveInfo)==2)
								{
								PrintHintText(client, "%t", "crowbar");
								}
							}
						}
					case 6: {
						FakeClientCommand(client, "give electric_guitar");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
								PrintToChat(client, "%t", "electric_guitar");
								}
								else if (GetConVarInt(cvarGiveInfo)==2)
								{
								PrintHintText(client, "%t", "electric_guitar");
								}
							}
						}
					case 7: {
						FakeClientCommand(client, "give fireaxe");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
								PrintToChat(client, "%t", "fireaxe");
								}
								else if (GetConVarInt(cvarGiveInfo)==2)
								{
								PrintHintText(client, "%t", "fireaxe");
								}
							}
						}
					case 8: {
						FakeClientCommand(client, "give katana");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
								PrintToChat(client, "%t", "katana");
								}
								else if (GetConVarInt(cvarGiveInfo)==2)
								{
								PrintHintText(client, "%t", "katana");
								}
							}
						}
					case 9: {
						FakeClientCommand(client, "give machete");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
								PrintToChat(client, "%t", "machete");
								}
								else if (GetConVarInt(cvarGiveInfo)==2)
								{
								PrintHintText(client, "%t", "machete");
								}
							}
						}
					case 10: {
						FakeClientCommand(client, "give tonfa");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
								PrintToChat(client, "%t", "tonfa");
								}
								else if (GetConVarInt(cvarGiveInfo)==2)
								{
								PrintHintText(client, "%t", "tonfa");
								}
							}
						}
					case 11: {
						FakeClientCommand(client, "give frying_pan");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
								PrintToChat(client, "%t", "frying_pan");
								}
								else if (GetConVarInt(cvarGiveInfo)==2)
								{
								PrintHintText(client, "%t", "frying_pan");
								}
							}
						}
					case 12: {
						FakeClientCommand(client, "give golfclub");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
								PrintToChat(client, "%t", "golfclub");
								}
								else if (GetConVarInt(cvarGiveInfo)==2)
								{
								PrintHintText(client, "%t", "golfclub");
								}
							}
						}
					}
				}
				else
				{
				if (GetConVarInt(cvarSecoWeapon)!=0) {
					if (GetConVarInt(cvarSecoWeapon)==1) { 
						FakeClientCommand(client, "give pistol");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
							PrintToChat(client, "%t", "pistol");
							}
							else if (GetConVarInt(cvarGiveInfo)==2)
							{
							PrintHintText(client, "%t", "pistol");
							}
						}
					}
					else	if (GetConVarInt(cvarSecoWeapon)==2) { 
						FakeClientCommand(client, "give pistol_magnum");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
							PrintToChat(client, "%t", "pistol_magnum");
							}
							else if (GetConVarInt(cvarGiveInfo)==2)
							{
							PrintHintText(client, "%t", "pistol_magnum");
							}
						}
					}
					else	if (GetConVarInt(cvarSecoWeapon)==3) { 
						FakeClientCommand(client, "give cricket_bat");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
							PrintToChat(client, "%t", "cricket_bat");
							}
							else if (GetConVarInt(cvarGiveInfo)==2)
							{
							PrintHintText(client, "%t", "cricket_bat");
							}
						}
					}
					else	if (GetConVarInt(cvarSecoWeapon)==4) { 
						FakeClientCommand(client, "give chainsaw");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
							PrintToChat(client, "%t", "chainsaw");
							}
							else if (GetConVarInt(cvarGiveInfo)==2)
							{
							PrintHintText(client, "%t", "chainsaw");
							}
						}
					}
					else	if (GetConVarInt(cvarSecoWeapon)==5) { 
						FakeClientCommand(client, "give baseball_bat");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
							PrintToChat(client, "%t", "baseball_bat");
							}
							else if (GetConVarInt(cvarGiveInfo)==2)
							{
							PrintHintText(client, "%t", "baseball_bat");
							}
						}
					}
					else	if (GetConVarInt(cvarSecoWeapon)==6) { 
						FakeClientCommand(client, "give crowbar");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
							PrintToChat(client, "%t", "crowbar");
							}
							else if (GetConVarInt(cvarGiveInfo)==2)
							{
							PrintHintText(client, "%t", "crowbar");
							}
						}
					}
					else	if (GetConVarInt(cvarSecoWeapon)==7) { 
						FakeClientCommand(client, "give electric_guitar");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
							PrintToChat(client, "%t", "electric_guitar");
							}
							else if (GetConVarInt(cvarGiveInfo)==2)
							{
							PrintHintText(client, "%t", "electric_guitar");
							}
						}
					}
					else	if (GetConVarInt(cvarSecoWeapon)==8) { 
						FakeClientCommand(client, "give fireaxe");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
							PrintToChat(client, "%t", "fireaxe");
							}
							else if (GetConVarInt(cvarGiveInfo)==2)
							{
							PrintHintText(client, "%t", "fireaxe");
							}
						}
					}
					else	if (GetConVarInt(cvarSecoWeapon)==9) { 
						FakeClientCommand(client, "give katana");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
							PrintToChat(client, "%t", "katana");
							}
							else if (GetConVarInt(cvarGiveInfo)==2)
							{
							PrintHintText(client, "%t", "katana");
							}
						}
					}
					else	if (GetConVarInt(cvarSecoWeapon)==10) { 
						FakeClientCommand(client, "give machete");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
							PrintToChat(client, "%t", "machete");
							}
							else if (GetConVarInt(cvarGiveInfo)==2)
							{
							PrintHintText(client, "%t", "machete");
							}
						}
					}
					else	if (GetConVarInt(cvarSecoWeapon)==11) { 
						FakeClientCommand(client, "give tonfa");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
							PrintToChat(client, "%t", "tonfa");
							}
							else if (GetConVarInt(cvarGiveInfo)==2)
							{
							PrintHintText(client, "%t", "tonfa");
							}
						}
					}
					else	if (GetConVarInt(cvarSecoWeapon)==12) { 
						FakeClientCommand(client, "give frying_pan");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
							PrintToChat(client, "%t", "frying_pan");
							}
							else if (GetConVarInt(cvarGiveInfo)==2)
							{
							PrintHintText(client, "%t", "frying_pan");
							}
						}
					}
					else	if (GetConVarInt(cvarSecoWeapon)==13) { 
						FakeClientCommand(client, "give golfclub");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
							PrintToChat(client, "%t", "golfclub");
							}
							else if (GetConVarInt(cvarGiveInfo)==2)
							{
							PrintHintText(client, "%t", "golfclub");
							}
						}
					}
				}
			}
		}
	}
	SetCommandFlags("give", flags|FCVAR_CHEAT);
}

public GiveGranadeItemToAllL4D2()
{
	new flags = GetCommandFlags("give");	
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);	
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && GetClientTeam(client)==2)
		{
			//Random Granade Items
			if (GetConVarInt(cvarRandomGranade)==1)
			{
				switch(GetRandomInt(0, 2)) {
					case 0: {
						FakeClientCommand(client, "give pipe_bomb");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
								PrintToChat(client, "%t", "pipe");
							}
							else if (GetConVarInt(cvarGiveInfo)==2)
							{
								PrintHintText(client, "%t", "pipe");
							}
						}
					}
					case 1: {
						FakeClientCommand(client, "give molotov");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
								PrintToChat(client, "%t", "molotov");
							}
							else if (GetConVarInt(cvarGiveInfo)==2)
							{
								PrintHintText(client, "%t", "molotov");
							}
						}
					}
					case 2: {
						FakeClientCommand(client, "give vomitjar");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
								PrintToChat(client, "%t", "vomitjar");
							}
							else if (GetConVarInt(cvarGiveInfo)==2)
							{
								PrintHintText(client, "%t", "vomitjar");
							}
						}
					}
				}
			}
			else
			//or set by user
			{
				if (GetConVarInt(cvarGranade)!=0) { 
					if (GetConVarInt(cvarGranade)==1) { 
						FakeClientCommand(client, "give pipe_bomb");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
								PrintToChat(client, "%t", "pipe");
							}
							else if (GetConVarInt(cvarGiveInfo)==2)
							{
								PrintHintText(client, "%t", "pipe");
							}	
						}
					}
					else if (GetConVarInt(cvarGranade)==2) { 
						FakeClientCommand(client, "give molotov");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
								PrintToChat(client, "%t", "molotov");
							}
							else if (GetConVarInt(cvarGiveInfo)==2)
							{
								PrintHintText(client, "%t", "molotov");
							}
						}
					}
					else if (GetConVarInt(cvarGranade)==3) { 
						FakeClientCommand(client, "give vomitjar");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
								PrintToChat(client, "%t", "vomitjar");
							}
							else if (GetConVarInt(cvarGiveInfo)==2)
							{
								PrintHintText(client, "%t", "vomitjar");
							}
						}
					}
				}
			}
		}	
	}
	SetCommandFlags("give", flags|FCVAR_CHEAT);
}


public GiveHealthItemToAllL4D2()
{
	new flags = GetCommandFlags("give");	
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);	
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && GetClientTeam(client)==2)
		{
			//Random Health Items
			if (GetConVarInt(cvarRandomHealth)==1)	{
				switch(GetRandomInt(0, 3)) 
				{
					case 0: {
						FakeClientCommand(client, "give first_aid_kit");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
								PrintToChat(client, "%t", "first_aid_kit");
							}
							else if (GetConVarInt(cvarGiveInfo)==2)
							{
								PrintHintText(client, "%t", "first_aid_kit");
							}
						}
					}
					case 1: {
						FakeClientCommand(client, "give defibrillator");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
								PrintToChat(client, "%t", "defibrilator");
							}
							else if (GetConVarInt(cvarGiveInfo)==2)
							{
								PrintHintText(client, "%t", "defibrilator");
							}
						}
					}
					case 2: {
						FakeClientCommand(client, "give upgradepack_explosive");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
								PrintToChat(client, "%t", "upgrade_explosive");
							}
							else if (GetConVarInt(cvarGiveInfo)==2)
							{
								PrintHintText(client, "%t", "upgrade_explosive");
							}
						}
					}	
					case 3: {
						FakeClientCommand(client, "give upgradepack_incendiary");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
								PrintToChat(client, "%t", "upgrade_incendiary");
							}
							else if (GetConVarInt(cvarGiveInfo)==2)
							{
								PrintHintText(client, "%t", "upgrade_incendiary");
							}
						}
					}
				}
			}	
			else
			//or set by user
			{
				if (GetConVarInt(cvarHealth)!=0) { 
					if (GetConVarInt(cvarHealth)==1){ 
						FakeClientCommand(client, "give first_aid_kit");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
								PrintToChat(client, "%t", "first_aid_kit");
							}
							else if (GetConVarInt(cvarGiveInfo)==2)
							{
								PrintHintText(client, "%t", "first_aid_kit");
							}
						}
					}
					else if (GetConVarInt(cvarHealth)==2) { 
						FakeClientCommand(client, "give defibrilator");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
								PrintToChat(client, "%t", "defibrilator");
							}
							else if (GetConVarInt(cvarGiveInfo)==2)
							{
								PrintHintText(client, "%t", "defibrilator");
							}
						}
					}
					else if (GetConVarInt(cvarHealth)==3) { 
						FakeClientCommand(client, "give upgradepack_explosive");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
								PrintToChat(client, "%t", "upgrade_explosive");
							}
							else if (GetConVarInt(cvarGiveInfo)==2)
							{
								PrintHintText(client, "%t", "upgrade_explosive");
							}
						}
					}
					else if (GetConVarInt(cvarHealth)==4) { 
						FakeClientCommand(client, "give upgradepack_incendiary");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
								PrintToChat(client, "%t", "upgrade_incendiary");
							}
							else if (GetConVarInt(cvarGiveInfo)==2)
							{
								PrintHintText(client, "%t", "upgrade_incendiary");
							}
						}
					}
				}	
			}
		}
	}
	SetCommandFlags("give", flags|FCVAR_CHEAT);

}

public GiveSupplyItemToAllL4D2()
{
	new flags = GetCommandFlags("give");	
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);	
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && GetClientTeam(client)==2)
		{
			//Random Health Items
			if (GetConVarInt(cvarRandomSupply)==1)	{
				switch(GetRandomInt(0, 1)) 
				{
					case 0: {
						FakeClientCommand(client, "give pain_pills");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
								PrintToChat(client, "%t", "pills");
							}
							else if (GetConVarInt(cvarGiveInfo)==2)
							{
								PrintHintText(client, "%t", "pills");
							}
						}
					}
					case 1: {
						FakeClientCommand(client, "give adrenaline");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
								PrintToChat(client, "%t", "adrenaline");
							}
							else if (GetConVarInt(cvarGiveInfo)==2)
							{
								PrintHintText(client, "%t", "adrenaline");
							}
						}
					}
				}
			}	
			else
			//or set by user
			{
				if (GetConVarInt(cvarSupply)!=0) { 
					if (GetConVarInt(cvarSupply)==1){ 
						FakeClientCommand(client, "give pain_pills");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
								PrintToChat(client, "%t", "pills");
							}
							else if (GetConVarInt(cvarGiveInfo)==2)
							{
								PrintHintText(client, "%t", "pills");
							}
						}
					}
					else if (GetConVarInt(cvarSupply)==2) { 
						FakeClientCommand(client, "give adrenaline");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
								PrintToChat(client, "%t", "adrenaline");
							}
							else if (GetConVarInt(cvarGiveInfo)==2)
							{
								PrintHintText(client, "%t", "adrenaline");
							}
						}
					}
				}	
			}
		}
	}
	SetCommandFlags("give", flags|FCVAR_CHEAT);
}

public GiveUpgradeItemToAllL4D2()
{
	new flags = GetCommandFlags("give");
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);
	SetCommandFlags("upgrade_add", flags & ~FCVAR_CHEAT);
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && GetClientTeam(client)==2)
		{
			if (GetConVarInt(cvarRandomUpgrade)==1)
			{
				switch(GetRandomInt(1, 3)) {
					case 0: {
						FakeClientCommand(client, "upgrade_add LASER_SIGHT");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
								PrintToChat(client, "%t", "upgrade_laser");
								}
								else if (GetConVarInt(cvarGiveInfo)==2)
								{
								PrintHintText(client, "%t", "upgrade_laser");
								}
							}
						}
					case 1: {
						FakeClientCommand(client, "upgrade_add EXPLOSIVE_AMMO");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
								PrintToChat(client, "%t", "upgrade_explosive");
								}
								else if (GetConVarInt(cvarGiveInfo)==2)
								{
								PrintHintText(client, "%t", "upgrade_explosive");
								}
							}
						}
					case 2: {
						FakeClientCommand(client, "upgrade_add INCENDIARY_AMMO");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
								PrintToChat(client, "%t", "upgrade_incendiary");
								}
								else if (GetConVarInt(cvarGiveInfo)==2)
								{
								PrintHintText(client, "%t", "upgrade_incendiary");
								}
							}
						}
					}
				}
				else
				{
					if (GetConVarInt(cvarUpgrade)!=0) {
					if (GetConVarInt(cvarUpgrade)==1) { 
						FakeClientCommand(client, "upgrade_add LASER_SIGHT");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
							PrintToChat(client, "%t", "upgrade_laser");
							}
							else if (GetConVarInt(cvarGiveInfo)==2)
							{
							PrintHintText(client, "%t", "upgrade_laser");
							}
						}
					}
					else if (GetConVarInt(cvarUpgrade)==2) { 
						FakeClientCommand(client, "upgrade_add EXPLOSIVE_AMMO");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
							PrintToChat(client, "%t", "upgrade_explosive");
							}
							else if (GetConVarInt(cvarGiveInfo)==2)
							{
							PrintHintText(client, "%t", "upgrade_explosive");
							}
						}
					}
					else	if (GetConVarInt(cvarUpgrade)==3) { 
						FakeClientCommand(client, "upgrade_add INCENDIARY_AMMO");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
							PrintToChat(client, "%t", "upgrade_incendiary");
							}
							else if (GetConVarInt(cvarGiveInfo)==2)
							{
							PrintHintText(client, "%t", "upgrade_incendiary");
							}
						}
					}					
				}
			}
		}
	}
	SetCommandFlags("give", flags|FCVAR_CHEAT);
	SetCommandFlags("upgrade_add", flags|FCVAR_CHEAT);
}
public GiveMeleeItemToAllL4D2()
{
	new flags = GetCommandFlags("give");
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && GetClientTeam(client)==2)
		{
			if (GetConVarInt(cvarRandomMelee)==1)
			{
				switch(GetRandomInt(0, 3)) {
					case 0: {
						FakeClientCommand(client, "give oxygentank");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
								PrintToChat(client, "%t", "oxygentank");
								}
								else if (GetConVarInt(cvarGiveInfo)==2)
								{
								PrintHintText(client, "%t", "oxygentank");
								}
							}
						}
					case 1: {
						FakeClientCommand(client, "give gascan");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
								PrintToChat(client, "%t", "gascan");
								}
								else if (GetConVarInt(cvarGiveInfo)==2)
								{
								PrintHintText(client, "%t", "gascan");
								}
							}
						}
					case 2: {
						FakeClientCommand(client, "give propanetank");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
								PrintToChat(client, "%t", "propanetank");
								}
								else if (GetConVarInt(cvarGiveInfo)==2)
								{
								PrintHintText(client, "%t", "propanetank");
								}
							}
						}
					case 3: {
						FakeClientCommand(client, "give fireworkcrate");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
								PrintToChat(client, "%t", "fireworkcrate");
								}
								else if (GetConVarInt(cvarGiveInfo)==2)
								{
								PrintHintText(client, "%t", "fireworkcrate");
								}
							}
						}
					case 4: {
						//This replaces cola with fireworkcrate on map where cola could be used to bypass part of the map
						if(StrEqual(currentmap, "c1m2_streets") == true) { 
						FakeClientCommand(client, "give fireworkcrate");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
								PrintToChat(client, "%t", "fireworkcrate");
								}
								else if (GetConVarInt(cvarGiveInfo)==2)
								{
								PrintHintText(client, "%t", "fireworkcrate");
								}
							}	
						}
						else
						{
							FakeClientCommand(client, "give cola_bottles");
							if (GetConVarInt(cvarGiveInfo)!=0) {
								if (GetConVarInt(cvarGiveInfo)==1)
								{
									PrintToChat(client, "%t", "cola_bottles");
									}
									else if (GetConVarInt(cvarGiveInfo)==2)
									{
									PrintHintText(client, "%t", "cola_bottles");
									}
								}
							}
						}
					case 5: {
						//This replaces gnome with fireworkcrate on maps where gnome could be used to earn achievement
						if(StrEqual(currentmap, "c2m1_highway") == true || StrEqual(currentmap, "c2m2_fairgrounds") == true || StrEqual(currentmap, "c2m3_coaster") == true || StrEqual(currentmap, "c2m4_barns") == true || StrEqual(currentmap, "c2m5_concert") == true) { 
						FakeClientCommand(client, "give fireworkcrate");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
								PrintToChat(client, "%t", "fireworkcrate");
								}
								else if (GetConVarInt(cvarGiveInfo)==2)
								{
								PrintHintText(client, "%t", "fireworkcrate");
								}
							}	
						}
						else
						{
							FakeClientCommand(client, "give gnome");
							if (GetConVarInt(cvarGiveInfo)!=0) {
								if (GetConVarInt(cvarGiveInfo)==1)
								{
									PrintToChat(client, "%t", "gnome");
									}
									else if (GetConVarInt(cvarGiveInfo)==2)
									{
									PrintHintText(client, "%t", "gnome");
									}
								}
							}
						}
					}
				}
				else
				{
				if (GetConVarInt(cvarMelee)!=0) {
					if (GetConVarInt(cvarMelee)==1) { 
						FakeClientCommand(client, "give oxygentank");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
							PrintToChat(client, "%t", "oxygentank");
							}
							else if (GetConVarInt(cvarGiveInfo)==2)
							{
							PrintHintText(client, "%t", "oxygentank");
							}
						}
					}
					else	if (GetConVarInt(cvarMelee)==2) { 
						FakeClientCommand(client, "give gascan");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
							PrintToChat(client, "%t", "gascan");
							}
							else if (GetConVarInt(cvarGiveInfo)==2)
							{
							PrintHintText(client, "%t", "gascan");
							}
						}
					}
					else if (GetConVarInt(cvarMelee)==3) { 
						FakeClientCommand(client, "give propanetank");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
							PrintToChat(client, "%t", "propanetank");
							}
							else if (GetConVarInt(cvarGiveInfo)==2)
							{
							PrintHintText(client, "%t", "propanetank");
							}
						}
					}
					else if (GetConVarInt(cvarMelee)==4) { 
						FakeClientCommand(client, "give fireworkcrate");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
							PrintToChat(client, "%t", "fireworkcrate");
							}
							else if (GetConVarInt(cvarGiveInfo)==2)
							{
							PrintHintText(client, "%t", "fireworkcrate");
							}
						}
					}
					else if (GetConVarInt(cvarMelee)==5) { 
						FakeClientCommand(client, "give cola_bottles");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
							PrintToChat(client, "%t", "cola_bottles");
							}
							else if (GetConVarInt(cvarGiveInfo)==2)
							{
							PrintHintText(client, "%t", "cola_bottles");
							}
						}
					}
					else if (GetConVarInt(cvarMelee)==6) { 
						FakeClientCommand(client, "give gnome");
						if (GetConVarInt(cvarGiveInfo)!=0) {
							if (GetConVarInt(cvarGiveInfo)==1)
							{
							PrintToChat(client, "%t", "gnome");
							}
							else if (GetConVarInt(cvarGiveInfo)==2)
							{
							PrintHintText(client, "%t", "gnome");
							}
						}
					}
				}
			}
		}
	}
	SetCommandFlags("give", flags|FCVAR_CHEAT);
}