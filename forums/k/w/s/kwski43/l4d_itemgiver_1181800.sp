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
	name = "L4D Round Start Items Giver",
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
new Handle:cvarDelayMelee;

//Selectable items cvars
new Handle:cvarPrimWeapon;
new Handle:cvarSecoWeapon;
new Handle:cvarGranade;
new Handle:cvarHealth;
new Handle:cvarSupply;
new Handle:cvarMelee;

//Random items cvars
new Handle:cvarRandomPrimWeapon;
new Handle:cvarRandomSecoWeapon;
new Handle:cvarRandomGranade;
new Handle:cvarRandomHealth;
new Handle:cvarRandomSupply;
new Handle:cvarRandomMelee;

//Others
new String:currentmap[64];

public OnPluginStart()
{
	CreateConVar("l4d2_itemgiver_version", PLUGIN_VERSION, "Start Round Items Giver Version", FCVAR_DONTRECORD|FCVAR_NOTIFY);
	
	LoadTranslations("l4d_itemgiver.phrases");
	
	decl String:s_Game[12];
	GetGameFolderName(s_Game, sizeof(s_Game));
	if (StrEqual(s_Game, "left4dead")) {
		//Main Cvars
		cvarAdvertDelay = CreateConVar("l4d_ig_adsdelay", "15.0", "Advertisements after round start delay? 0-disable",FCVAR_PLUGIN, true, 0.0, true, 60.0);
		cvarGiveInfo = CreateConVar("l4d_ig_giveinfo", "1", "Enables info for players at round start about items they get. 0-disable, 1-chat, 2-hint",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 2.0);
		//Giving items delay cvars 
		cvarDelayPrimWeapon = CreateConVar("l4d_ig_delay_primweapon", "30.0", "Primary Weapon Item give delay from round start. Float in Seconds.",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 60.0);
		cvarDelaySecoWeapon = CreateConVar("l4d_ig_delay_secweapon", "34.0", "Secondary Weapon Item give delay from round start. Float in Seconds.",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 60.0);
		cvarDelayGranade = CreateConVar("l4d_ig_delay_granade", "37.0", "Granade Item give delay from round start. Float in Seconds.",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 60.0);
		cvarDelayHealth = CreateConVar("l4d_ig_delay_health", "40.0", "Health Item give delay from round start. Float in Seconds.",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 60.0);
		cvarDelaySupply = CreateConVar("l4d_ig_delay_supply", "43.0", "Supply Item give delay from round start. Float in Seconds.",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 60.0);
		cvarDelayMelee = CreateConVar("l4d_ig_delay_melee", "46.0", "Melee Item give delay from round start. Float in Seconds.",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 60.0);
		//Giving items cvars
		cvarPrimWeapon = CreateConVar("l4d_ig_give_primweapon", "0", "What Primary Weapon item should We give to survivors? 0-disable, 1-smg, 2-rifle, 3-pumpshotgun, 4-hunting_rifle, 5-autoshotgun",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 3.0);
		cvarSecoWeapon = CreateConVar("l4d_ig_give_secweapon", "1", "What Secondary Weapon item should We give to survivors? 0-disable, 1-pistol",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		cvarGranade = CreateConVar("l4d_ig_give_granade", "1", "What Granade item should We give to survivors? 0-disable, 1-pipe, 2-molotov",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 2.0);
		cvarHealth = CreateConVar("l4d_ig_give_health", "0", "What Health item should We give to survivors? 0-disable, 1-medkit",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		cvarSupply = CreateConVar("l4d_ig_give_supply", "1", "What Supply item should We give to survivors? 0-disable, 1-pills",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		cvarMelee = CreateConVar("l4d_ig_give_melee", "0", "What Melee item should We give to survivors? 0-disable, 1-oxygentank, 2-gascan, 3-propanetank",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 3.0);
		//Giving random items cvars
		cvarRandomPrimWeapon = CreateConVar("l4d_ig_random_primweapon", "0", "Should We give random Primary Weapon item to survivors? Overrides previous item settings.",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		cvarRandomSecoWeapon = CreateConVar("l4d_ig_random_secweapon", "0", "Should We give random Secondary Weapon item to survivors? Overrides previous item settings.",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		cvarRandomGranade = CreateConVar("l4d_ig_random_granade", "0", "Should We give random Granade item to survivors? Overrides previous item settings.",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		cvarRandomHealth = CreateConVar("l4d_ig_random_health", "0", "Should We give random Health item to survivors? Overrides previous item settings.",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		cvarRandomSupply = CreateConVar("l4d_ig_random_supply", "0", "Should We give random Supply item to survivors? Overrides previous item settings.",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		cvarRandomMelee = CreateConVar("l4d_ig_random_melee", "0", "Should We give random Melee item to survivors? Overrides previous item settings.",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		
		AutoExecConfig(true, "l4d_itemgiver");
		
		HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
	}
	else
	{
		SetFailState("This plugin works only with Left 4 Dead!");
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
			switch(GetRandomInt(0, 4)) {
				case 0: {
					GiveItem(client, "smg");
				}
				case 1: {
					GiveItem(client, "rifle");
				}
				case 2: {
					GiveItem(client, "pumpshotgun");
				}
				case 3: {
					GiveItem(client, "hunting_rifle");
				}
				case 4: {
					GiveItem(client, "autoshotgun");
				}
			}
		}
		else
		{
			if (GetConVarInt(cvarPrimWeapon)!=0) {
				if (GetConVarInt(cvarPrimWeapon)==1) { 
					GiveItem(client, "smg");
				}
				else	if (GetConVarInt(cvarPrimWeapon)==2) { 
					GiveItem(client, "rifle");
				}
				
				else	if (GetConVarInt(cvarPrimWeapon)==3) { 
					GiveItem(client, "pumpshotgun");
				}
				
				else	if (GetConVarInt(cvarPrimWeapon)==4) { 
					GiveItem(client, "hunting_rifle");
				}
				
				else	if (GetConVarInt(cvarPrimWeapon)==5) { 
					GiveItem(client, "autoshotgun");
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
			switch(GetRandomInt(0, 0)) {
				case 0: {
					GiveItem(client, "pistol");
				}
			}
		}
		else
		{
			if (GetConVarInt(cvarSecoWeapon)!=0) {
				if (GetConVarInt(cvarSecoWeapon)==1) { 
					GiveItem(client, "pistol");
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
			switch(GetRandomInt(0, 1)) {
				case 0: {
					GiveItem(client, "pipe_bomb");
				}
				case 1: {
					GiveItem(client, "molotov");
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
			switch(GetRandomInt(0, 0)) 
			{
				case 0: {
					GiveItem(client, " first_aid_kit");
				}
			}
		}
		else
		{
			if (GetConVarInt(cvarHealth)!=0) { 
				if (GetConVarInt(cvarHealth)==1){ 
					GiveItem(client, " first_aid_kit");
				}
			}
		}
	}
}

public GiveSupplyItem(client)
{
	if (IsClientInGame(client) && GetClientTeam(client)==2)
	{
		//Random Supply Items
		if (GetConVarInt(cvarRandomSupply)==1){
			switch(GetRandomInt(0, 0)) 
			{
				case 0: {
					GiveItem(client, "pain_pills");
				}
			}
		}
		else
		{
			if (GetConVarInt(cvarSupply)!=0) { 
				if (GetConVarInt(cvarSupply)==1){ 
					GiveItem(client, "pain_pills");
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
			switch(GetRandomInt(0, 2)) {
				case 0: {
					GiveItem(client, "oxygentank");
				}
				case 1: {
					GiveItem(client, "gascan");
				}
				case 2: {
					GiveItem(client, "propanetank");
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
