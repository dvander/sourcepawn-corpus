#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
//#include <sdkhooks>

#define INFO_NAME "Left 4 Dead 1 & 2 Cheat Survivor Bot"
#define INFO_AUTHOR "Randerion(HaoJun0823)"
#define INFO_DESCRIPTION "Modify survivor bot ability."
#define INFO_VERSION "0.1f"
#define INFO_URL "https://github.com/HaoJun0823/l4d_cheat_bot"

//Author's note: Love my son Okami Yuuki forever!

//#define INFO_URL "https://blog.haojun0823.xyz/"
//#define INFO_GITHUB "https://github.com/HaoJun0823/l4d_cheat_bot"

#define TEAM_SPECTATORS 1
#define TEAM_SURVIVORS 2
#define TEAM_INFECTED 3

/* Thanks for Peace-Maker address:https://forums.alliedmods.net/showthread.php?t=289217 */
#define L4D2_WEPUPGFLAG_NONE            (0 << 0) // 0
#define L4D2_WEPUPGFLAG_INCENDIARY      (1 << 0) // 1
#define L4D2_WEPUPGFLAG_EXPLOSIVE       (1 << 1) // 2
#define L4D2_WEPUPGFLAG_LASER (1 << 2) // 4

//Get from IPVE:https://www.ipve.com/bbs/redirect.php?fid=526&tid=444018&goto=nextoldset
//#define FCVAR_FLAGS FCVAR_PLUGIN|FCVAR_NOTIFY
#define IsValidClient(%1) (1 <= %1 <= MaxClients && IsClientInGame(%1))
#define PluginDebug GetConVarInt(SurvivorBotPluginDebug)!=0?true:false

//This is my method.
#define IsValidSurvivorBot(%1) (IsValidClient(%1) && IsFakeClient(%1) && GetClientTeam(%1) == TEAM_SURVIVORS)


static String:Ent_Slot0[][] = { "smg_silenced", "smg", "pumpshotgun", "shotgun_chrome", "autoshotgun", "shotgun_spas", "hunting_rifle", "sniper_military", "rifle", "rifle_ak47", "rifle_desert", "grenade_launcher", "rifle_m60", "rifle_sg552", "smg_mp5", "sniper_awp", "sniper_scout" };
static String:Ent_Slot1[][] = { "pistol", "pistol_magnum", "baseball_bat", "cricket_bat", "crowbar", "electric_guitar", "fireaxe", "frying_pan", "golfclub", "katana", "hunting_knife", "machete", "riotshield", "tonfa", "chainsaw" };
//static String:Ent_Slot2[][] = { "molotov", "vomitjar", "pipe_bomb" };

static String:Ent_Slot3[][] = { "first_aid_kit", "defibrillator", "upgradepack_explosive", "upgradepack_incendiary" };
//static String:Ent_Slot4[][] = { "adrenaline", "pain_pills" };



static String:PrimaryWeaponList[][] = { "smg" , "pumpshotgun" , "autoshotgun" , "hunting_rifle" , "rifle" , "shotgun_chrome" , "smg_silenced" , "shotgun_spas" ,"sniper_military" , "rifle_ak47" , "rifle_desert" , "grenade_launcher"};
//Where is Glock?
static String:SecondaryWeaponList[][] = {"pistol_magnum" , "pistol" };
static String:GrenadeList[][] = {"pipe_bomb" , "vomitjar" , "molotov" };


static String:OldPrimaryWeaponList[][] = {  "pumpshotgun" , "autoshotgun" , "hunting_rifle" , "rifle" , "smg" };
static String:OldGrenadeList[][] = {"pipe_bomb" , "molotov" };

//static String:HealItemList[][] = {"first_aid_kit"};
//static String:ExtraItemList[][] = {"pain_pills" , "adrenaline"};
//static String:OldExtraItemList[][] = {"pain_pills"};

new GameVersion;
//new PluginDebug;
//new RandomItemId;

/*
//When i want to finsihed that.
new PrimaryWeaponPool;
new SecondaryWeaponPool;
new HealItemPool;
new ExtraItemPool;
new GrenadeItemPool;

new OldPrimaryWeaponPool;
new OldGrenadePool;
new OldExtraItemPool;
*/
//For Weapon Speed.
new WeaponReload[MAXPLAYERS + 1];
new WeaponReloadCount;

new MaxPlayerHealth[MAXPLAYERS +1];
new PlayerHealTimer[MAXPLAYERS +1];

new PlayerParticleSpitter[MAXPLAYERS + 1];
new PlayerParticleRight[MAXPLAYERS + 1];
new PlayerParticleLeft[MAXPLAYERS + 1];

//new ParticlePlayerGroup[MAXPLAYERS + 1];

new PlayerOriginalHealth[MAXPLAYERS +1];
new Float:PlayerOriginalGravity[MAXPLAYERS +1];
new Float:PlayerOriginalSpeed[MAXPLAYERS +1];

//new Handle:ParticleTimer;

new Handle:SurvivorBotPluginSwitch = INVALID_HANDLE;
new Handle:SurvivorBotPluginDebug = INVALID_HANDLE;
new Handle:SurvivorBotParticle = INVALID_HANDLE;
new Handle:SurvivorBotHealthMul = INVALID_HANDLE;
new Handle:SurvivorBotInfiniteAmmo = INVALID_HANDLE;
new Handle:SurvivorBotFullHeal = INVALID_HANDLE;
new Handle:SurvivorBotWeaponSpeedMul = INVALID_HANDLE;
//Merge to Weapon
//new Handle:SurvivorBotMeleeSpeedMul = INVALID_HANDLE;
new Handle:SurvivorBotMoveSpeedMul = INVALID_HANDLE;
new Handle:SurvivorBotGravity = INVALID_HANDLE;

new Handle:SurvivorBotLaserSight = INVALID_HANDLE;
new Handle:SurvivorBotSpecialAmmo = INVALID_HANDLE;
new Handle:SurvivorBotExtraItem = INVALID_HANDLE;
new Handle:SurvivorBotHealItem = INVALID_HANDLE;
new Handle:SurvivorBotGrenade = INVALID_HANDLE;


new Handle:SurvivorBotPrimaryWeapon = INVALID_HANDLE;
new Handle:SurvivorBotSecondaryWeapon = INVALID_HANDLE;
new Handle:SurvivorBotReflectDamage = INVALID_HANDLE;
new Handle:SurvivorBotExtraAttackDamage = INVALID_HANDLE;
new Handle:SurvivorBotHealTimer = INVALID_HANDLE;
new Handle:SurvivorBotNoFriendlyDamage = INVALID_HANDLE;
new Handle:SurvivorBotSufferDamage = INVALID_HANDLE;

new Handle:SurvivorBotReset = INVALID_HANDLE;

/*
new Handle:SurvivorBotAlwaysExtraItem = INVALID_HANDLE;
new Handle:SurvivorBotAlwaysHealItem = INVALID_HANDLE;
new Handle:SurvivorBotAlwaysGrenade = INVALID_HANDLE;


*/

/*
//With Custom Weapons List.

new Handle:SurvivorBotPrimaryWeaponList = INVALID_HANDLE;
new Handle:SurvivorBotSecondaryWeaponList = INVALID_HANDLE;
new Handle:SurvivorBotHealItemList = INVALID_HANDLE;
new Handle:SurvivorBotExtraItemList = INVALID_HANDLE;
new Handle:SurvivorBotGrenadeList = INVALID_HANDLE;
new Handle:SurvivorBotSpecialAmmoList = INVALID_HANDLE;
new Handle:SurvivorBotWeaponUpgradeList = INVALID_HANDLE;


new Handle:SurvivorBotOldSecondaryWeapon = INVALID_HANDLE;
new Handle:SurvivorBotOldSpecialAmmo = INVALID_HANDLE;
new Handle:SurvivorBotOldLaserSight = INVALID_HANDLE;


new Handle:SurvivorBotOldPrimaryWeaponList = INVALID_HANDLE;
new Handle:SurvivorBotOldSecondaryWeaponList = INVALID_HANDLE;
new Handle:SurvivorBotOldHealItemList = INVALID_HANDLE;
new Handle:SurvivorBotOldExtraItemList = INVALID_HANDLE;
new Handle:SurvivorBotOldGrenadeList = INVALID_HANDLE;
new Handle:SurvivorBotOldSpecialAmmoList = INVALID_HANDLE;
new Handle:SurvivorBotOldWeaponUpgradeList = INVALID_HANDLE;
*/

public Plugin:myinfo =
{
	name = INFO_NAME,
	author = INFO_AUTHOR,
	description = INFO_DESCRIPTION,
	version = INFO_VERSION,
	url = INFO_URL
};

public OnPluginStart()
{
	//LogMessage("%s Start running, current map will be make modifies.",INFO_NAME);
	
	GameVersion = GetGameVersion();
	if(GameVersion==0){SetFailState("Stop Plugin Start!");return ;}
	AutoExecConfig(true, "l4d_survivor_cheat_bot");

	SurvivorBotPluginSwitch = CreateConVar("randerion_l4d_survivor_bot_plugin_switch", "1", "Whether the plugin is started.(default:1,on:1;off:0)", 0, true, 0.0);
	SurvivorBotPluginDebug = CreateConVar("randerion_l4d_survivor_bot_plugin_debug", "0", "Logging Plugin's information.(default:0,on:1;off:0)", 0, true, 0.0);
	SurvivorBotReset = CreateConVar("randerion_l4d_survivor_bot_reset", "0", "When player join or replace bot, everything will be normal.[Maybe effects other plugins].(default:0,on:1;off:0)", 0, true, 0.0);
	SurvivorBotParticle = CreateConVar("randerion_l4d2_survivor_bot_particle", "0", "Add Spitter Particle for Bot.[Just Particle, Not effect GameData, Only Left Dead 2].(default:0,mouth:1;off:0;eye+mouth:2)", 0, true, 0.0);
	//Health
	SurvivorBotHealthMul = CreateConVar("randerion_l4d_survivor_bot_health_mul", "5.0", "Set survivor bot's life multiple.(default:5.0;normal:1.0;more:>1.0;less:<1.0)", 0, true, 0.01);
	SurvivorBotFullHeal = CreateConVar("randerion_l4d_survivor_bot_full_heal", "1", "When the value is 1, the healing of the survivor bot will restore all health.(default:1;normal:0;on:1;off:0)", 0, true, 0.0);
	

	//Weapons
	SurvivorBotWeaponSpeedMul = CreateConVar("randerion_l4d_survivor_bot_weapon_speed_mul", "0.5", "Set survivor bot's weapon shot speed.(default:0.5;normal:1.0;faster:<1.0;slower:>1.0)", 0, true, 0.0);
	
	//Merge to Weapon
	//SurvivorBotMeleeSpeedMul = CreateConVar("randerion_l4d_survivor_bot_melee_speed_mul", "0.5", "Set survivor bot's melee attack speed.(default:0.5;normal:1.0;faster:<1.0;slower:>1.0)", 0, true, 0.0);
	
	//Enities
	SurvivorBotMoveSpeedMul = CreateConVar("randerion_l4d_survivor_bot_move_speed_mul", "1.5", "Set survivor bot's move speed multiple.(default:1.5;normal:1.0;faster:>1.0;slower:<1.0)", 0, true, 0.1);
	SurvivorBotGravity = CreateConVar("randerion_l4d_survivor_bot_gravity", "0.5", "Set survivor bot's gravity.(default:0.5;normal:1.0;lighter:<1.0;heavier:>1.0)", 0, true, 0.0);
	SurvivorBotSufferDamage = CreateConVar("randerion_l4d_survivor_bot_suffer_damage", "0.5", "Set survivor bot suffer damage.(default:0.5;normal:0.0;off:=0.0;on:>0.0)", 0, true, 0.0);
	SurvivorBotReflectDamage = CreateConVar("randerion_l4d_survivor_bot_reflect_damage", "0.5", "Set survivor bot can reflect damage to enemy.(default:0.5;normal:0.0;off:=0.0;on:>0.0)", 0, true, 0.0);
	SurvivorBotExtraAttackDamage = CreateConVar("randerion_l4d_survivor_bot_extra_attack_damage", "0.25", "Set survivor bot extra attack damage.(default:0.25;normal:0.0;off:=0.0;on:>0.0)", 0, true, 0.0);
	
	//Ammo And Upgrade
	SurvivorBotInfiniteAmmo = CreateConVar("randerion_l4d_survivor_bot_infinite_ammo", "1", "When the value is 1, make survivor bot have infinite ammo.(default:1;normal:0;on:1;off:0)", 0, true, 0.0);
	
	
	SurvivorBotHealTimer = CreateConVar("randerion_l4d2_survivor_bot_timer_heal", "1", "Set survivor bot will get heal regen every second.(default:1;normal:0;on:>=1;off:0)", 0, true, 0.0);
	SurvivorBotNoFriendlyDamage = CreateConVar("randerion_l4d2_survivor_bot_no_friendly_damage", "1", "Set survivor bot will not get any hurt from friend.(default:1;normal:0;on:1;off:0)", 0, true, 0.0);

	// Left dead 2!
	SurvivorBotSpecialAmmo = CreateConVar("randerion_l4d2_survivor_bot_special_ammo", "3", "Set survivor bot auto get special ammo[Only Left Dead 2].(default:3;normal:0;off:0;incendiary:1,explosive:2,random_both_ammo:3)", 0, true, 0.0);	
	SurvivorBotLaserSight = CreateConVar("randerion_l4d2_survivor_bot_weapon_upgrade", "1", "Set survivor bot auto get laser sight[Only Left Dead 2].(default:1;normal:0;on:1;off:0)", 0, true, 0.0);
	
	//Custom Item Supports.
	//SurvivorBotLaserSight = CreateConVar("randerion_l4d2_survivor_bot_weapon_upgrade", "1", "Set survivor bot auto get lazer sight.(default:1;on:1;off:0;random_list_upgrade:2)", 0, true, 0.0);
	//SurvivorBotSpecialAmmo = CreateConVar("randerion_l4d2_survivor_bot_special_ammo", "3", "Set survivor bot auto get special ammo.(default:3;off:0;incendiary:1,explosive:2,random_both_ammo:3,random_list_ammo:4)", 0, true, 0.0);	
	
	//If Left Dead 1 Support.
	//SurvivorBotOldLaserSight = CreateConVar("randerion_l4d1_survivor_bot_weapon_upgrade", "0", "Set survivor bot auto get lazer sight[If Left Dead 1 Support this feature!].(default:1;on:1;off:0;random_list_upgrade:2)", 0, true, 0.0);
	//SurvivorBotOldSpecialAmmo = CreateConVar("randerion_l4d1_survivor_bot_special_ammo", "0", "Set survivor bot auto get special ammo [If Left Dead 1 Support this feature!].(default:3;off:0;incendiary:1,explosive:2,random_both_ammo:3,random_list_ammo:4)", 0, true, 0.0);	
	
	
	
	/*
	Old Code.
	SurvivorBotExtraItem = CreateConVar("randerion_l4d_survivor_bot_extra_heal_item", "3", "Set survivor bot auto get pill or adrenaline.(default:3;off:0;pill:1,adrenaline:2,random_both_item:3)", 0, true, 0.0);
	//SurvivorBotHealItem = CreateConVar("randerion_l4d_survivor_bot_heal_or_upgrade_item", "1", "Set survivor bot auto get first aid kit or defibrillator or explosive upgradepack or incendiary upgradepack.(default:1;off:0;first_aid_kit:1,defibrillator:2,explosive:4,incendiary:8,1+2+4+8=15=Random_All)", 0, true, 0.0);
	SurvivorBotHealItem = CreateConVar("randerion_l4d_survivor_bot_heal_or_upgrade_item", "1", "Set survivor bot auto get first aid kit.(default:1;off:0;first_aid_kit:1)", 0, true, 0.0);
	SurvivorBotPrimaryWeapon = CreateConVar("randerion_l4d_survivor_bot_primary_weapon", "1", "Set survivor bot auto get pumpshotgun.(default:1;off:0;pumpshotgun:1)", 0, true, 0.0);
	SurvivorBotSecondaryWeapon = CreateConVar("randerion_l4d2_survivor_bot_secondary_weapon", "1", "Set survivor bot auto get pistol magnum.(default:1;off:0;pistol_magnum:1)", 0, true, 0.0);
	SurvivorBotGrenade = CreateConVar("randerion_l4d_survivor_bot_grenade_item", "1", "Set survivor bot auto get pipe bomb.(default:1;off:0;pipe_bomb:1)", 0, true, 0.0);
	*/


	SurvivorBotExtraItem = CreateConVar("randerion_l4d_survivor_bot_extra_heal_item", "3", "Set survivor bot auto get extra item forever[2 or 3 Only Left Dead 2].(default:3;nomral:0;off:0;pill:1,adrenaline:2,random_both_item:3)", 0, true, 0.0);
	SurvivorBotHealItem = CreateConVar("randerion_l4d_survivor_bot_heal_or_upgrade_item", "1", "Set survivor bot auto get first aid kit forever[All:Only Left Dead 2 Bot Can't Use them Beside First Aid Kit].(default:1;normal:0;off:0;first_aid_kit:1;all:2)", 0, true, 0.0);
	SurvivorBotGrenade = CreateConVar("randerion_l4d_survivor_bot_grenade_item", "1", "Set survivor bot auto get random grenade forever.(default:1;normal:0;on:1;off:0)", 0, true, 0.0);
	
	/*
	SurvivorBotAlwaysExtraItem = CreateConVar("randerion_l4d_survivor_bot_always_get_extra_heal_item", "1", "Set survivor bot always auto get extra item.(default:1;off:0;on:1)", 0, true, 0.0);
	SurvivorBotAlwaysHealItem = CreateConVar("randerion_l4d_survivor_bot_always_get_heal_or_upgrade_item", "1", "Set survivor always bot auto get heal or upgrade item.(default:1;off:0;on:1)", 0, true, 0.0);
	SurvivorBotAlwaysGrenade = CreateConVar("randerion_l4d_survivor_bot_always_get_grenade_item", "1", "Set survivor bot always auto get grenade.(default:1;off:0;on:1)", 0, true, 0.0);
	*/
	
	SurvivorBotPrimaryWeapon = CreateConVar("randerion_l4d_survivor_bot_primary_weapon", "1", "Set survivor bot auto get random primary weapon forever[On:Left Dead 2 No M60;All:Including All & Sercret Need Unlock Otherwise No damage].(default:1;normal:0;off:0;on:1;all:2)", 0, true, 0.0);
	SurvivorBotSecondaryWeapon = CreateConVar("randerion_l4d2_survivor_bot_secondary_weapon", "1", "Set survivor bot auto get random secondary weapon forever[On:No Melee Weapon;All:Including All & Sercret Need Unlock Otherwise No damage].(default:1;normal:0;off:0;on:1;all:2)", 0, true, 0.0);
	//SurvivorBotOldSecondaryWeapon = CreateConVar("randerion_l4d1_survivor_bot_secondary_weapon", "0", "Set survivor bot auto get secondary weapon[If Left Dead 1 Support this feature!].(default:1;off:0;on:1)", 0, true, 0.0);


	//SurvivorBotPrimaryWeaponList = CreateConVar("randerion_l4d2_survivor_bot_primary_weapon_list","smg,pumpshotgun,autoshotgun,hunting_rifle,rifle,shotgun_chrome,smg_silenced,shotgun_spas,sniper_military,rifle_ak47,rifle_desert,grenade_launcher","Which primary weapons can the bot get randomly?(comma separated, only item Id)",0,true,0.0);
	//SurvivorBotSecondaryWeaponList = CreateConVar("randerion_l4d2_survivor_bot_secondary_weapon_list","pistol,pistol_magnum","Which secondary weapons can the bot get randomly?(comma separated, only item Id)",0,true,0.0);


	/*
	SurvivorBotHealItemList = CreateConVar("randerion_l4d2_survivor_bot_heal_or_upgrade_item_list","first_aid_kit","Which heal or upgrade items can the bot get randomly?(comma separated, only item Id)",0,true,0.0);
	SurvivorBotExtraItemList = CreateConVar("randerion_l4d2_survivor_bot_extra_item_list","pain_pills,adrenaline","Which extra items can the bot get randomly?(comma separated, only item Id)",0,true,0.0);
	SurvivorBotGrenadeList = CreateConVar("randerion_l4d2_survivor_bot_grenade_list","molotov,pipe_bomb,vomitjar","Which grenades can the bot get randomly?(comma separated, only item Id)",0,true,0.0);
	SurvivorBotSpecialAmmoList = CreateConVar("randerion_l4d2_survivor_bot_special_ammo_list","INCENDIARY_AMMO,EXPLOSIVE_AMMO","Which special ammos can the bot get randomly?(comma separated, only item Id)",0,true,0.0);
	SurvivorBotWeaponUpgradeList = CreateConVar("randerion_l4d2_survivor_bot_weapon_upgrade_list","LASER_SIGHT","Which weapon upgrades can the bot get randomly?(comma separated, only item Id)",0,true,0.0);
	*/
	
	//Left Dead 1
	/*
	SurvivorBotOldPrimaryWeaponList = CreateConVar("randerion_l4d1_survivor_bot_primary_weapon_list","smg,pumpshotgun,autoshotgun,hunting_rifle,rifle","Which primary weapons can the bot get randomly?(comma separated, only item Id)",0,true,0.0);
	SurvivorBotOldSecondaryWeaponList = CreateConVar("randerion_l4d1_survivor_bot_secondary_weapon_list","null","Which secondary weapons can the bot get randomly?(comma separated, only item Id)",0,true,0.0);


	SurvivorBotOldHealItemList = CreateConVar("randerion_l4d1_survivor_bot_heal_or_upgrade_item_list","first_aid_kit","Which heal or upgrade items can the bot get randomly?(comma separated, only item Id)",0,true,0.0);
	SurvivorBotOldExtraItemList = CreateConVar("randerion_l4d1_survivor_bot_extra_item_list","pain_pills","Which extra items can the bot get randomly?(comma separated, only item Id)",0,true,0.0);
	SurvivorBotOldGrenadeList = CreateConVar("randerion_l4d1_survivor_bot_grenade_list","molotov,pipe_bomb","Which grenades can the bot get randomly?(comma separated, only item Id)",0,true,0.0);
	SurvivorBotOldSpecialAmmoList = CreateConVar("randerion_l4d1_survivor_bot_special_ammo_list","null","Which special ammos can the bot get randomly?(comma separated, only item Id)",0,true,0.0);
	SurvivorBotOldWeaponUpgradeList = CreateConVar("randerion_l4d1_survivor_bot_weapon_upgrade_list","null","Which weapon upgrades can the bot get randomly?(comma separated, only item Id)",0,true,0.0);
	*/

	RegConsoleCmd("sm_l4d_cheat_survivor_bot_version", PrintVersion, "Print Plugins Version.");
	//RegConsoleCmd("sm_l4d_cheat_survivor_bot_information", PrintData, "Print Plugins Config[Need In Game].");

	CreateTimer(0.0, OnPluginRunningDelayed);

}

public Action:PlayerFirstSpawnParticle(Handle:event, String:event_name[], bool:dontBroadcast) {

	new target = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(IsValidSurvivorBot(target)){
	
	//ParticlePlayerGroup[target]= target;
	
	if(GameVersion >=2){
	CreateParticle(target);
	if(GetConVarInt(SurvivorBotParticle)==2){
	CreateParticleEye(target);
	}
	}

	
	}
	


	return Plugin_Continue;
	
	
	
}

public Action:PlayerReplaceBotParticle(Handle:event, String:event_name[], bool:dontBroadcast) {

	new target = GetClientOfUserId(GetEventInt(event, "player"));
	new client = GetClientOfUserId(GetEventInt(event, "client"));
	
	if(IsValidSurvivorBot(client)){
	
	//ParticlePlayerGroup[target]= target;
	
	if(GameVersion >=2){
	RemoveParticle(target);
	if(GetConVarInt(SurvivorBotParticle)==2){
	RemoveParticleEye(target);
	}
	}

	

	
	}
	


	return Plugin_Continue;
	
	
	
}

public Action:BotReplacePlayerParticle(Handle:event, String:event_name[], bool:dontBroadcast) {

	new target = GetClientOfUserId(GetEventInt(event, "player"));
	//new client = GetClientOfUserId(GetEventInt(event, "client"));
	
	if(IsValidSurvivorBot(target)){
	
	//ParticlePlayerGroup[target]= target;
	
	if(GameVersion >=2){
	CreateParticle(target);
	if(GetConVarInt(SurvivorBotParticle)==2){
	CreateParticleEye(target);
	}
	}
	
	
	

	
	}
	


	return Plugin_Continue;
	
	
	
}


public Action:OnPluginRunningDelayed(Handle:timer)
{

	if (GetConVarInt(SurvivorBotPluginSwitch) == 1) {
	if(PluginDebug){LogMessage("Enabled!");}
	if(PluginDebug){LogMessage("Hook:0:Information");}
	HookEvent("player_first_spawn", PlayerFirstSpawn);
		
		//Need optimization when some feature closed, we can unhook correspond event.

	//if((GetConVarFloat(SurvivorBotWeaponSpeedMul)!= 1.0 && GetConVarFloat(SurvivorBotWeaponSpeedMul) > 0.0) || (GetConVarFloat(SurvivorBotMeleeSpeedMul) != 1.0 && GetConVarFloat(SurvivorBotMeleeSpeedMul) > 0.0)){
	if((GetConVarFloat(SurvivorBotWeaponSpeedMul)!= 1.0 && GetConVarFloat(SurvivorBotWeaponSpeedMul) > 0.0)){
	if(PluginDebug){LogMessage("Hook:1:WeaponFire");}
	HookEvent("weapon_fire", WeaponFire);
	}
	
	
	if(GetConVarInt(SurvivorBotFullHeal) >= 1){
	if(PluginDebug){LogMessage("Hook:2:FullHeal");}

	HookEvent("heal_success", PlayerHealSuccess);
	}

	if(GetConVarInt(SurvivorBotPrimaryWeapon) > 0 || GetConVarInt(SurvivorBotGrenade) > 0 || GetConVarInt(SurvivorBotSecondaryWeapon) > 0 || GetConVarInt(SurvivorBotExtraItem) > 0 || GetConVarInt(SurvivorBotHealItem) > 0 || GetConVarInt(SurvivorBotSpecialAmmo) > 0 || GetConVarInt(SurvivorBotLaserSight) > 0)
	{
	if(GameVersion >= 2 ){
	HookEvent("adrenaline_used", PlayerAdrenalineUsed);
	HookEvent("defibrillator_used", PlayerDefibrillatorUsed);
	if(PluginDebug){LogMessage("Hook:3:L4D2WeaponRandom");}
	}else{
	if(PluginDebug){LogMessage("Hook:3:L4D1WeaponRandom");}
	}
		
	HookEvent("heal_success", PlayerHealSuccessItem);
	HookEvent("pills_used", PlayerPillsUsed);
	HookEvent("grenade_bounce", PlayerGrenadeBounce);
	HookEvent("hegrenade_detonate", PlayerGrenadeDetonate);
	HookEvent("player_spawn", PlayerSpawnItem);
	HookEvent("respawning", PlayerReSpawnItem);
	HookEvent("player_first_spawn", PlayerFirstSpawnItem);
		
	HookEvent("upgrade_pack_used", PlayerUpgradeUsed);
	HookEvent("grenade_bounce", PlayerGrenadeUsed);
	HookEvent("hegrenade_detonate", PlayerGrenadeUsed);
	HookEvent("respawning", PlayerRespawning);
	
	HookEvent("item_pickup", PlayerPickupItem);
	HookEvent("ammo_pickup", PlayerPickupAmmo);
	HookEvent("player_bot_replace", PlayerReplaceBotItem);
	}

	if(GetConVarFloat(SurvivorBotHealthMul) !=1.0 || GetConVarFloat(SurvivorBotGravity) != 1.0 || GetConVarFloat(SurvivorBotMoveSpeedMul) != 1.0){
	if(PluginDebug){LogMessage("Hook:4:EnitiyProp");}
	HookEvent("player_spawn", PlayerSpawn);
	HookEvent("player_bot_replace", PlayerReplace);
	HookEvent("respawning", PlayerRespawningHealth);
	HookEvent("player_first_spawn", PlayerFirstSpawnHealth);
	//HookEvent("player_bot_replace", PlayerReplaceBot);
	}
		
	if(GetConVarInt(SurvivorBotNoFriendlyDamage) == 1) {
	if(PluginDebug){LogMessage("Hook:5:FirendlyFire");}
	HookEvent("player_hurt", PlayerHurtFriendly);
	}

	if(GetConVarFloat(SurvivorBotSufferDamage) > 0.0){
	if(PluginDebug){LogMessage("Hook:6:SufferDamage");}
	HookEvent("player_hurt", PlayerHurtSuffer);
	}
				
		
	if(GetConVarInt(SurvivorBotHealTimer) >= 1){
	if(PluginDebug){LogMessage("Hook:7:HealTimer");}
	HookEvent("player_hurt", PlayerHurtHealTimer);
	}
		
		
	if(GetConVarFloat(SurvivorBotReflectDamage)>0.0){
	if(PluginDebug){LogMessage("Hook:8:ReflectDamage");}
	HookEvent("player_hurt", PlayerHurt);
		
	}
		
	if(GetConVarFloat(SurvivorBotExtraAttackDamage)>0.0){
	if(PluginDebug){LogMessage("Hook:9:ExtraDamage");}
	HookEvent("player_hurt", PlayerHurtExtra);
		
	}
		
	//HookEvent("weapon_drop", PlayeWeaponDrop); //Very Complicated!

	if(GetConVarInt(SurvivorBotInfiniteAmmo) >= 1)
	{
	if(PluginDebug){LogMessage("Hook:10:WeaponFireAmmo");}
	HookEvent("weapon_fire", WeaponFireAmmo);
	}
	
	
	
	
	


	if(GetConVarInt(SurvivorBotReset) != 0){
	
	if(PluginDebug){LogMessage("Hook:11:PlayerReplaceBot");}
	HookEvent("player_bot_replace", BotReplacePlayer);
	}
	
	if(GetConVarInt(SurvivorBotParticle) != 0){
	
	if(PluginDebug){LogMessage("Hook:12:PlayerParticleBot");}
	
	if(GameVersion>=2){
	for(new i=0;i<sizeof(PlayerParticleSpitter);i++){
		PlayerParticleSpitter[i]=-1;
	}
	}
	
	for(new i=0;i<sizeof(PlayerParticleLeft);i++){
		PlayerParticleLeft[i]=-1;
	}
	
	for(new i=0;i<sizeof(PlayerParticleRight);i++){
		PlayerParticleRight[i]=-1;
	}
	
	HookEvent("player_spawn", PlayerFirstSpawnParticle);
	}

	}else{
	if(PluginDebug){LogMessage("Disabled!");}
	}


	

}

/*
public Action:PrintData(int client, int args)
{
	PrintChat(client);
	return Plugin_Continue;
}
*/
public Action:PrintVersion(int client, int args)
{
	PrintInformation(client);
	return Plugin_Continue;
}


public Action:PlayerReplaceBotItem(Handle:event, String:event_name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "bot"));
	if (IsValidSurvivorBot(client)) {GiveItemsByCvars(client);}
	

	return Plugin_Continue;
	
	
}



public Action:PlayerDefibrillatorUsed(Handle:event, String:event_name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new subject = GetClientOfUserId(GetEventInt(event, "subject"));
	
	if (IsValidSurvivorBot(client)) {GiveItemsByCvars(client);}
	if (IsValidSurvivorBot(subject) && client != subject) {GiveItemsByCvars(subject);}
	
}


/*
public Action:SpawnerGiveItem(Handle:event, String:event_name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
}
*/

/*
// I think i don't need do this.
public Action:PlayerWeaponDrop(Handle:event, String:event_name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsValidSurvivorBot(client)) {
		
		
		new entity = GetEventInt(event, "propid");
		GiveItemsByCvars(client);
	}
	
}

*/

public Action:PlayerRespawning(Handle:event, String:event_name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsValidSurvivorBot(client)) {GiveItemsByCvars(client);}
	

	return Plugin_Continue;
	
	
}

public Action:BotReplacePlayer(Handle:event, String:event_name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "bot"));
	if(IsValidClient(client) && GetClientTeam(client) == TEAM_SURVIVORS && !IsFakeClient(client)){
	
		if (HasEntProp(client, Prop_Data, "m_iMaxHealth") && HasEntProp(client, Prop_Data, "m_iHealth")) {
			SetEntProp(client, Prop_Data, "m_iHealth", RoundToNearest((GetEntProp(client, Prop_Data, "m_iHealth") * GetConVarFloat(SurvivorBotHealthMul) )));
			SetEntProp(client, Prop_Data, "m_iMaxHealth", PlayerOriginalHealth[client]);
			MaxPlayerHealth[client] = GetEntProp(client, Prop_Data, "m_iMaxHealth");
		}

		if (HasEntProp(client, Prop_Data, "m_flLaggedMovementValue")) {
			SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", PlayerOriginalSpeed[client]);
		}
		SetEntityGravity(client, PlayerOriginalGravity[client]);
	
	}
	

	return Plugin_Continue;
	
	
}

public Action:PlayerFirstSpawnHealth(Handle:event, String:event_name[], bool:dontBroadcast) {

	new target = GetClientOfUserId(GetEventInt(event, "userid"));

	if(IsValidClient(target) && GetClientTeam(target) == TEAM_SURVIVORS){
	
	if (HasEntProp(target, Prop_Data, "m_iMaxHealth") && HasEntProp(target, Prop_Data, "m_iHealth")) {
	PlayerOriginalHealth[target] =  GetEntProp(target, Prop_Data, "m_iMaxHealth");
	}
	
	if (HasEntProp(target, Prop_Data, "m_flLaggedMovementValue")) {
	PlayerOriginalSpeed[target] =  GetEntPropFloat(target, Prop_Data, "m_flLaggedMovementValue");
	}
	PlayerOriginalGravity[target] =  GetEntityGravity(target);
	}

	if (IsValidSurvivorBot(target)) {
		
		if (HasEntProp(target, Prop_Data, "m_iMaxHealth") && HasEntProp(target, Prop_Data, "m_iHealth")) {
			SetEntProp(target, Prop_Data, "m_iMaxHealth", RoundToNearest(GetEntProp(target, Prop_Data, "m_iMaxHealth")*GetConVarFloat(SurvivorBotHealthMul)));
			SetEntProp(target, Prop_Data, "m_iHealth", RoundToNearest(GetEntProp(target, Prop_Data, "m_iHealth")*GetConVarFloat(SurvivorBotHealthMul)));
			MaxPlayerHealth[target] = GetEntProp(target, Prop_Data, "m_iMaxHealth");
		}

		if (HasEntProp(target, Prop_Data, "m_flLaggedMovementValue")) {
			SetEntPropFloat(target, Prop_Data, "m_flLaggedMovementValue", GetEntPropFloat(target, Prop_Data, "m_flLaggedMovementValue")*GetConVarFloat(SurvivorBotMoveSpeedMul));
		}
		SetEntityGravity(target, GetConVarFloat(SurvivorBotGravity));

	}

	return Plugin_Continue;
	
	
}

public Action:PlayerRespawningHealth(Handle:event, String:event_name[], bool:dontBroadcast) {

	new target = GetClientOfUserId(GetEventInt(event, "userid"));

	if (IsValidSurvivorBot(target)) {

		if (HasEntProp(target, Prop_Data, "m_iMaxHealth") && HasEntProp(target, Prop_Data, "m_iHealth")) {
			SetEntProp(target, Prop_Data, "m_iMaxHealth", RoundToNearest(GetEntProp(target, Prop_Data, "m_iMaxHealth")*GetConVarFloat(SurvivorBotHealthMul)));
			SetEntProp(target, Prop_Data, "m_iHealth", RoundToNearest(GetEntProp(target, Prop_Data, "m_iHealth")*GetConVarFloat(SurvivorBotHealthMul)));
			MaxPlayerHealth[target] = GetEntProp(target, Prop_Data, "m_iMaxHealth");
		}

		if (HasEntProp(target, Prop_Data, "m_flLaggedMovementValue")) {
			SetEntPropFloat(target, Prop_Data, "m_flLaggedMovementValue", GetEntPropFloat(target, Prop_Data, "m_flLaggedMovementValue")*GetConVarFloat(SurvivorBotMoveSpeedMul));
		}

		SetEntityGravity(target, GetConVarFloat(SurvivorBotGravity));

	}

	return Plugin_Continue;
	
	
}

public Action:PlayerSpawn(Handle:event, String:event_name[], bool:dontBroadcast)
{

	new target = GetClientOfUserId(GetEventInt(event, "userid"));

	if (IsValidSurvivorBot(target)) {
			
		if (HasEntProp(target, Prop_Data, "m_iMaxHealth") && HasEntProp(target, Prop_Data, "m_iHealth")) {
			SetEntProp(target, Prop_Data, "m_iMaxHealth", RoundToNearest(GetEntProp(target, Prop_Data, "m_iMaxHealth")*GetConVarFloat(SurvivorBotHealthMul)));
			SetEntProp(target, Prop_Data, "m_iHealth", RoundToNearest(GetEntProp(target, Prop_Data, "m_iHealth")*GetConVarFloat(SurvivorBotHealthMul)));
			MaxPlayerHealth[target] = GetEntProp(target, Prop_Data, "m_iMaxHealth");
		}

		if (HasEntProp(target, Prop_Data, "m_flLaggedMovementValue")) {
			SetEntPropFloat(target, Prop_Data, "m_flLaggedMovementValue", GetEntPropFloat(target, Prop_Data, "m_flLaggedMovementValue")*GetConVarFloat(SurvivorBotMoveSpeedMul));
		}

		SetEntityGravity(target, GetConVarFloat(SurvivorBotGravity));

	}

	return Plugin_Continue;

}

public Action:PlayerReplace(Handle:event, String:event_name[], bool:dontBroadcast)
{

	new target = GetClientOfUserId(GetEventInt(event, "bot"));

	if (IsValidSurvivorBot(target)) {
			
		if (HasEntProp(target, Prop_Data, "m_iMaxHealth") && HasEntProp(target, Prop_Data, "m_iHealth")) {
			SetEntProp(target, Prop_Data, "m_iMaxHealth", RoundToNearest(GetEntProp(target, Prop_Data, "m_iMaxHealth")*GetConVarFloat(SurvivorBotHealthMul)));
			SetEntProp(target, Prop_Data, "m_iHealth", RoundToNearest(GetEntProp(target, Prop_Data, "m_iHealth")*GetConVarFloat(SurvivorBotHealthMul)));
			MaxPlayerHealth[target] = GetEntProp(target, Prop_Data, "m_iMaxHealth");
		}

		if (HasEntProp(target, Prop_Data, "m_flLaggedMovementValue")) {
			SetEntPropFloat(target, Prop_Data, "m_flLaggedMovementValue", GetEntPropFloat(target, Prop_Data, "m_flLaggedMovementValue")*GetConVarFloat(SurvivorBotMoveSpeedMul));
		}

		SetEntityGravity(target, GetConVarFloat(SurvivorBotGravity));

	}

	return Plugin_Continue;

}

public Action:PlayerGrenadeUsed(Handle:event, String:event_name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsValidSurvivorBot(client)) {GiveItemsByCvars(client);}
	return Plugin_Continue;
}

public Action:PlayerUpgradeUsed(Handle:event, String:event_name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsValidSurvivorBot(client)) {GiveItemsByCvars(client);}
	return Plugin_Continue;
}

public Action:PlayerPillsUsed(Handle:event, String:event_name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsValidSurvivorBot(client)) {GiveItemsByCvars(client);}
	return Plugin_Continue;
}

public Action:PlayerGrenadeBounce(Handle:event, String:event_name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsValidSurvivorBot(client)) {GiveItemsByCvars(client);}
	return Plugin_Continue;
}

public Action:PlayerGrenadeDetonate(Handle:event, String:event_name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsValidSurvivorBot(client)) {GiveItemsByCvars(client);}
	return Plugin_Continue;
}

public Action:PlayerAdrenalineUsed(Handle:event, String:event_name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsValidSurvivorBot(client)) {GiveItemsByCvars(client);}
	return Plugin_Continue;
}

public Action:PlayerReload(Handle:event, String:event_name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsValidSurvivorBot(client)) {GiveItemsByCvars(client);}
	return Plugin_Continue;

}

public Action:PlayerFireOnEmpty(Handle:event, String:event_name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsValidSurvivorBot(client)) {GiveItemsByCvars(client);}
	return Plugin_Continue;

}

public Action:PlayerPickupItem(Handle:event, String:event_name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsValidSurvivorBot(client)) {GiveItemsByCvars(client);}
	return Plugin_Continue;


}

public Action:PlayerPickupAmmo(Handle:event, String:event_name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsValidSurvivorBot(client)) {GiveItemsByCvars(client);}
	return Plugin_Continue;

}

public Action:PlayerSpawnItem(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsValidSurvivorBot(client)) {GiveItemsByCvars(client);}
	return Plugin_Continue;
}


public Action:PlayerReSpawnItem(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsValidSurvivorBot(client)) {GiveItemsByCvars(client);}
	return Plugin_Continue;
}

public Action:PlayerFirstSpawnItem(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsValidSurvivorBot(client)) {GiveItemsByCvars(client);}
	return Plugin_Continue;
}


public Action:PlayerHealSuccess(Handle:event, String:event_name[], bool:dontBroadcast) {

	if (GetConVarInt(SurvivorBotFullHeal) == 1) {

		
		new subject = GetClientOfUserId(GetEventInt(event, "subject"));
		/*
		new health_restored = GetClientOfUserId(GetEventInt(event,"health_restored"));
		*/

		if (IsValidSurvivorBot(subject)) {

			if (HasEntProp(subject, Prop_Data, "m_iHealth") && HasEntProp(subject, Prop_Data, "m_iMaxHealth")) {

				/*
						new before_health = GetEntProp(subject,Prop_Data,"m_iHealth") - health_restored;
						new health_mul = health_restored * GetConVarFloat(SurvivorBotHealthMul);
				*/

				SetEntProp(subject, Prop_Data, "m_iHealth", GetEntProp(subject, Prop_Data, "m_iMaxHealth"));

			}

		}
	}
	return Plugin_Continue;
}

public Action:PlayerHealSuccessItem(Handle:event, String:event_name[], bool:dontBroadcast) {

	if (GetConVarInt(SurvivorBotFullHeal) == 1) {

		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		new subject = GetClientOfUserId(GetEventInt(event, "subject"));
		/*
		new health_restored = GetClientOfUserId(GetEventInt(event,"health_restored"));
		*/

		if (IsValidSurvivorBot(client)) {
		
			GiveItemsByCvars(client);
		
		}

		if (IsValidSurvivorBot(subject) && client != subject) {

			GiveItemsByCvars(client);

			}



		}
	
	return Plugin_Continue;
}

public Action:PlayerFirstSpawn(Handle:event, String:event_name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	PrintInformation(client);
	PrintChat(client);
	return Plugin_Continue;
}

public Action:WeaponFireAmmo(Handle:event, String:event_name[], bool:dontBroadcast)
{

	new target = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsValidSurvivorBot(target)) {
	new ent = GetEntPropEnt(target, Prop_Send, "m_hActiveWeapon");
	//		if (GetConVarInt(SurvivorBotInfiniteAmmo) == 1) {

	if (HasEntProp(ent, Prop_Send, "m_iClip1")) {
	SetEntProp(ent, Prop_Send, "m_iClip1", GetEntProp(ent, Prop_Send, "m_iClip1") + 1);
	}
	}
}

public Action:WeaponFire(Handle:event, String:event_name[], bool:dontBroadcast)
{

	new target = GetClientOfUserId(GetEventInt(event, "userid"));

	if (IsValidSurvivorBot(target)) {


		new ent = GetEntPropEnt(target, Prop_Send, "m_hActiveWeapon");
		decl String:entclass[64];
		GetEdictClassname(ent, entclass, sizeof(entclass));

		WeaponReload[WeaponReloadCount] = ent;
		WeaponReloadCount++;


	




		//if (GameVersion >= 1 && ent == GetPlayerWeaponSlot(target, 1) && StrContains(entclass, "melee",false) != -1)
		/*


		

		if (GameVersion >= 1)
		{

			WeaponReload[WeaponReloadCount] = ent;
			WeaponReloadCount++;
		}
		else if (ent == GetPlayerWeaponSlot(target, 0) || (ent == GetPlayerWeaponSlot(target, 1) && StrContains(entclass, "melee",false) < 0))
		{

			WeaponReload[WeaponReloadCount] = ent;
			WeaponReloadCount++;

			if (GetConVarInt(SurvivorBotInfiniteAmmo) == 1) {

				if (HasEntProp(ent, Prop_Send, "m_iClip1")) {
					SetEntProp(ent, Prop_Send, "m_iClip1", GetEntProp(ent, Prop_Send, "m_iClip1") + 1);
				}

				
				if(HasEntProp(ent,Prop_Send,"m_iClip2")){
				SetEntProp(ent, Prop_Send, "m_iClip2", GetEntProp(ent, Prop_Send, "m_iClip2")+1);
				}
				
			}



		}
		*/

	}

	return Plugin_Continue;

}


public Action:PlayerHurt(Handle:event, String:event_name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new Float:mul = GetConVarFloat(SurvivorBotReflectDamage);
	new damage = GetEventInt(event, "dmg_health");
	if (mul > 0.0 && IsValidSurvivorBot(client) && IsValidClient(attacker) && GetClientTeam(attacker) != GetClientTeam(client)){
	DealDamage( client, attacker, RoundToNearest(mul * damage), 0, "damage_reflect");
	}
	return Plugin_Continue;
	
}

public Action:PlayerHurtSuffer(Handle:event, String:event_name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new Float:mul = GetConVarFloat(SurvivorBotSufferDamage);
	new damage = GetEventInt(event, "dmg_health");
	if (mul > 0.0 && IsValidSurvivorBot(client) && IsValidClient(attacker) && GetClientTeam(attacker) != GetClientTeam(client)){
		
				if (HasEntProp(client, Prop_Data, "m_iHealth") && HasEntProp(client, Prop_Data, "m_iMaxHealth")) {

				SetEntProp(client, Prop_Data, "m_iHealth", GetEntProp(client, Prop_Data, "m_iHealth") + (damage * mul));

			}
	}
	return Plugin_Continue;
	
}

public Action:PlayerHurtFriendly(Handle:event, String:event_name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new damage = GetEventInt(event, "dmg_health");
	if (IsValidSurvivorBot(client) && IsValidClient(attacker) && GetClientTeam(attacker) == GetClientTeam(client)){
	
			if (HasEntProp(client, Prop_Data, "m_iHealth") && HasEntProp(client, Prop_Data, "m_iMaxHealth")) {

				SetEntProp(client, Prop_Data, "m_iHealth", GetEntProp(client, Prop_Data, "m_iHealth") + damage);

			}
	
	
	
	}
	return Plugin_Continue;
	
}


public Action:PlayerHurtHealTimer(Handle:event, String:event_name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(!PlayerHealTimer[client] && IsValidSurvivorBot(client) && HasEntProp(client, Prop_Data, "m_iHealth") && HasEntProp(client, Prop_Data, "m_iMaxHealth")){
	
	PlayerHealTimer[client] = true;
	CreateTimer(1.0, TimerRegenTick, client, TIMER_REPEAT);
	
	}
	
	return Plugin_Continue;
	
}

public Action:TimerRegenTick( Handle:timer, any:client)
{
	/*
	Dangerous!
	new health = GetEntData(client, FindDataMapOffs(client, "m_iHealth"));
	new maxhealth = GetEntData(client, FindDataMapOffs(client, "m_iMaxHealth"));
	*/
	new health = GetEntProp(client, Prop_Data, "m_iHealth");
	new regen = GetConVarInt(SurvivorBotHealTimer);
	
	if((health + regen) <= MaxPlayerHealth[client]){
	
	
		SetEntProp(client, Prop_Data, "m_iHealth", health + regen);
		/*
		Dangerous!
		SetEntData(client, FindDataMapOffs(client, "m_iMaxHealth"), health + regen, 4, true);
		*/
	
	}else{
	
		KillTimer(timer);
		timer = INVALID_HANDLE;
		PlayerHealTimer[client] = false;
	}
	
	return Plugin_Continue;
	
	
}


public Action:PlayerHurtExtra(Handle:event, String:event_name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new Float:mul = GetConVarFloat(SurvivorBotExtraAttackDamage);
	new damage = GetEventInt(event, "dmg_health");
	if (mul > 0.0 && IsValidSurvivorBot(attacker) && IsValidClient(client) && GetClientTeam(client) != GetClientTeam(attacker)){
	DealDamage( attacker, client, RoundToNearest(mul * damage), 0, "damage_extra_attack");
	}
	return Plugin_Continue;
	
}
/*
public Action:WeaponFire(Handle:event, String:event_name[], bool:dontBroadcast)
{

	new target = GetClientOfUserId(GetEventInt(event, "userid"));

	if (IsValidSurvivorBot(target)) {


		new ent = GetEntPropEnt(target, Prop_Send, "m_hActiveWeapon");
		decl String:entclass[64];
		GetEdictClassname(ent, entclass, sizeof(entclass));

		WeaponReload[WeaponReloadCount] = ent;
		WeaponReloadCount++;
		
	}

	return Plugin_Continue;

}
*/

//With game but no action.

public OnMapStart(){

/*
	if(GetConVarInt(SurvivorBotParticle)>0){
	
	//ParticleTimer = CreateTimer(10.0, PlayerParticleTimer, 0, TIMER_REPEAT);
	
	}
*/
}

public OnMapEnd(){
	
	/*
	KillTimer(ParticleTimer);
	ParticleTimer =INVALID_HANDLE;
*/
	
	for(new i=0;i<sizeof(PlayerHealTimer);i++){
		PlayerHealTimer[i] = false;
	}
	
	

}

public OnPluginEnd(){

	//LogMessage("%s Stop running, next map or restart will be restart or finllay close.",INFO_NAME);

}

public OnGameFrame()
{
	
	//I really don't know why this method can do that.
	if (WeaponReloadCount > 0) {

		decl ent;

		for (new i = 0; i < WeaponReloadCount; i++)
		{
			ent = WeaponReload[i];
			if (IsValidEdict(ent))
			{
				//decl String:entclass[64];
				//GetEdictClassname(ent, entclass, sizeof(entclass));

				//if (StrContains(entclass, "weapon") >= 0 || StrContains(entclass, "melee") >= 0)
				
				new Float:Mul = GetConVarFloat(SurvivorBotWeaponSpeedMul);
				Mul = Mul>0.00?Mul:0.000001;
					/*
					if (StrContains(entclass, "melee") >= 0) {

						Mul = GetConVarFloat(SurvivorBotMeleeSpeedMul);

					}
					*/
				
				new Float:ETime = GetGameTime();
				decl Float:LPTime;
				decl Float:LSTime;
				if (HasEntProp(ent, Prop_Send, "m_flPlaybackRate")) {
					SetEntPropFloat(ent, Prop_Send, "m_flPlaybackRate", Mul);
				}

				if (HasEntProp(ent, Prop_Send, "m_flNextPrimaryAttack")) {
					LPTime = (GetEntPropFloat(ent, Prop_Send, "m_flNextPrimaryAttack") - ETime)*Mul;
					LPTime = LPTime>0?LPTime:0.000001;
					//LogMessage("LPTIME:%f",LPTime);
					SetEntPropFloat(ent, Prop_Send, "m_flNextPrimaryAttack", LPTime + ETime);
				}

				if (HasEntProp(ent, Prop_Send, "m_flNextSecondaryAttack")) {
					LSTime = (GetEntPropFloat(ent, Prop_Send, "m_flNextSecondaryAttack") - ETime)*Mul;
					LPTime = LSTime>0?LSTime:0.000001;
					//LogMessage("LSTIME:%f",LSTime);
					SetEntPropFloat(ent, Prop_Send, "m_flNextSecondaryAttack", LSTime + ETime);
				}

				CreateTimer(LPTime>LSTime?LSTime:LPTime, NormalWeaponSpeed, ent);
				
			}
		}

		WeaponReloadCount = 0;

	}
}
/*
public Action:PlayerParticleTimer(Handle:timer, any:data)
{
	
	LogMessage("Create Particle!");
	for(new i=0;i<(MAXPLAYERS + 1);i++){
	LogMessage("Particle Check:%d",i);
	if (IsValidSurvivorBot(ParticlePlayerGroup[i]) && PlayerParticle[0][i] != -1) {
	LogMessage("Pass Check:%d",i);
*/
	/*
	decl P_mouth = PlayerParticle[0][i];
	decl P_leye = PlayerParticle[1][i];
	decl P_reye = PlayerParticle[2][i];
	*/
/*
	int entity = CreateEntityByName("info_particle_system");
	DispatchKeyValue(entity, "effect_name", "spitter_slime_trail");	
	DispatchSpawn(entity);
	ActivateEntity(entity);
	AcceptEntityInput(entity, "Start");
	SetVariantString("!activator");
	AcceptEntityInput(entity, "SetParent", ParticlePlayerGroup[i]);
	SetVariantString("mouth");
	AcceptEntityInput(entity, "SetParentAttachment");
	
	new Float:vPos[3];
	
	//vPos[1] = -2.0;
	vPos[3] = 4.0;
	
	TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);
	
	PlayerParticle[0][i] = entity;
	
	LogMessage("Added Enitiy:%d",i);
	
	}else{
	
	LogMessage("Unpass Check:%d",i);
	if(IsValidEntity(PlayerParticle[0][i])){
	LogMessage("Remove Enitiy:%d",i);
	
	RemoveEntity(PlayerParticle[0][i]);
	PlayerParticle[0][i] = -1;
	
	}
	
	
	}		
		
		
	}
	
	




}
*/
public Action:NormalWeaponSpeed(Handle:timer, any:ent)
{
	KillTimer(timer);
	timer = INVALID_HANDLE;

	if (IsValidEdict(ent))
	{
		decl String:entclass[64];
		GetEdictClassname(ent, entclass, sizeof(entclass));
		if (StrContains(entclass, "weapon") >= 0 || StrContains(entclass, "melee") >= 0)
		{
			if (HasEntProp(ent, Prop_Send, "m_flPlaybackRate")) {
				SetEntPropFloat(ent, Prop_Send, "m_flPlaybackRate", 1.0);
			}
		}
	}
	return Plugin_Continue;
}



stock DealDamage(attacker=0,victim,damage,dmg_type=0,String:weapon[]="")
{
	if(IsValidEdict(victim) && damage>0)
	{
		decl String:victimid[64];
		decl String:dmg_type_str[32];
		IntToString(dmg_type,dmg_type_str,32);
		new PointHurt = CreateEntityByName("point_hurt");
		if(PointHurt)
		{
			Format(victimid, 64, "victim%d", victim);
			DispatchKeyValue(victim,"targetname",victimid);
			DispatchKeyValue(PointHurt,"DamageTarget",victimid);
			DispatchKeyValueFloat(PointHurt,"Damage",float(damage));
			DispatchKeyValue(PointHurt,"DamageType",dmg_type_str);
			if(!StrEqual(weapon,""))
			{
				DispatchKeyValue(PointHurt,"classname",weapon);
			}
			DispatchSpawn(PointHurt);
			if(IsValidClient(attacker))
				AcceptEntityInput(PointHurt, "Hurt", attacker);
			else 	
				AcceptEntityInput(PointHurt, "Hurt", -1);
				
			RemoveEdict(PointHurt);
		}
	}
}


stock GetSpecialAmmoTypeOfClient(client)
{
    new gunent = GetPlayerWeaponSlot(client, 0);
    if (IsValidEdict(gunent) && HasEntProp(gunent, Prop_Send, "m_upgradeBitVec"))
        return GetEntProp(gunent, Prop_Send, "m_upgradeBitVec");
    return 0;
}


stock SetWeaponUpgrades(client)
{
	if(GameVersion <= 1 || GetConVarInt(SurvivorBotLaserSight)<=0){return ;}
	
	new specialammo = GetSpecialAmmoTypeOfClient(client);
	/*
    if (specialammo & L4D2_WEPUPGFLAG_INCENDIARY) //1B 
    {
        
    }
    if (specialammo & L4D2_WEPUPGFLAG_EXPLOSIVE) // 10B
    {
        
    }
	*/
	//if (specialammo != 4)
		// 100B 100 & 100 = 100
	if (specialammo & L4D2_WEPUPGFLAG_LASER) {return ;}
	
	
	CheatCommand(client, "upgrade_add", "LASER_SIGHT");
	
}  

stock SetWeaponSpeicalAmmo(client)
{
	new specialammo = GetSpecialAmmoTypeOfClient(client);
	
	if(GameVersion <= 1 || ((specialammo & L4D2_WEPUPGFLAG_INCENDIARY)||(specialammo & L4D2_WEPUPGFLAG_EXPLOSIVE)) || GetConVarInt(SurvivorBotSpecialAmmo)<=0 ){return ;}
	
	if(GetURandomInt()%2==1){
	CheatCommand(client, "upgrade_add", "INCENDIARY_AMMO");
	}else{
	CheatCommand(client, "upgrade_add", "EXPLOSIVE_AMMO");
	}
	
}


/* Thanks for AtomicStryker address:http://forums.alliedmods.net/showthread.php?t=114210 */
stock CheatCommand(client, String:command[], String:arguments[]="")
{
	decl String:name[64];
	GetClientName(client,name,sizeof(name));
	if(PluginDebug){LogMessage("DoCommand:%s %s for %s[ID:%d]",command, arguments, name, client);}
	new userflags = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arguments);
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, userflags);
}

stock GetGameVersion(){

	decl String:game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));
	if (StrEqual(game_name, "left4dead", false)){return 1;}
	if (StrEqual(game_name, "left4dead2", false)){return 2;}
	SetFailState("This plugin only supports Left 4 Dead Game!(1 or 2)");
	return 0;
	
}	

stock GetRandomNumberFromArray(size){
	
	new random = GetURandomInt()%size;

	return random;
}

stock GiveItemsByCvars(client){

	if(GetPlayerWeaponSlot(client, 0) == -1){
	
	if(GetConVarInt(SurvivorBotPrimaryWeapon)>=1){
	//CheatCommand(client, "give", "pumpshotgun");	
	
		switch(GameVersion){
			case 1:{
				CheatCommand(client, "give", OldPrimaryWeaponList[GetRandomNumberFromArray(sizeof(OldPrimaryWeaponList))]);	
				}
			case 2:{
				if(GetConVarInt(SurvivorBotPrimaryWeapon)==2){
				CheatCommand(client, "give", Ent_Slot0[GetRandomNumberFromArray(sizeof(Ent_Slot0))]);	
				}
				else{
				CheatCommand(client, "give", PrimaryWeaponList[GetRandomNumberFromArray(sizeof(PrimaryWeaponList))]);					
				}
				}
			}
	
	}

	}

	if(GameVersion > 1 && GetPlayerWeaponSlot(client, 1) == -1){
	
	if(GetConVarInt(SurvivorBotSecondaryWeapon)>=1){
	//CheatCommand(client, "give", "pistol_magnum");	

	if(GetConVarInt(SurvivorBotPrimaryWeapon)==2){
	CheatCommand(client, "give", Ent_Slot1[GetRandomNumberFromArray(sizeof(Ent_Slot1))]);	
	}
	else{
	CheatCommand(client, "give", SecondaryWeaponList[GetRandomNumberFromArray(sizeof(SecondaryWeaponList))]);					
	}
	
	}
	}
	
	if(GetPlayerWeaponSlot(client, 2) == -1){
	
	if(GetConVarInt(SurvivorBotGrenade)==1){
	//CheatCommand(client, "give", "pipe_bomb");	
	
			switch(GameVersion){
			case 1:{
				CheatCommand(client, "give", OldGrenadeList[GetRandomNumberFromArray(sizeof(OldGrenadeList))]);	
				}
			case 2:{
				CheatCommand(client, "give", GrenadeList[GetRandomNumberFromArray(sizeof(GrenadeList))]);	
				}
			}
	
	}
	}
	
	

	if(GetPlayerWeaponSlot(client, 3) == -1){
	
		if(GetConVarInt(SurvivorBotHealItem)>=1){
		
			//Don't need random from list beacause bots don't know use them.
			//CheatCommand(client, "give", "first_aid_kit"); //weapon_upgradepack_explosive  weapon_upgradepack_incendiary  first_aid_kit defibrillator 
		
			if(GetConVarInt(SurvivorBotHealItem)==2 && GameVersion >= 2){
			CheatCommand(client, "give", Ent_Slot3[GetRandomNumberFromArray(sizeof(Ent_Slot3))]);	
			}
			else{
			CheatCommand(client, "give", "first_aid_kit");
			}
		
		
		}
	
	}

	if(GetPlayerWeaponSlot(client, 4) == -1){
	
	
	new choice = GetConVarInt(SurvivorBotExtraItem);
	
	if(GameVersion <= 1){
	
		choice = 1;
	
	}
	
	
	switch(choice){
	case 1:{
		
		CheatCommand(client, "give", "pain_pills");
		
	}
	case 2:{
		
		CheatCommand(client, "give", "adrenaline");
		
	}
	case 3:{
		
		if(GetURandomInt()%2==1){
		CheatCommand(client, "give", "pain_pills");
		}else{
		CheatCommand(client, "give", "adrenaline");
		}
		
	}
	}
	
	

	
	}
	
	
	SetWeaponUpgrades(client);
	SetWeaponSpeicalAmmo(client);
	

}

stock PrintChat(client){
	
	
	
	if (!IsFakeClient(client))
	{
		
		if(!IsClientInGame(client)){
			ReplyToCommand(client,"Not In Game!");
		}
		
		PrintToChat(client, "=====[CheatBot]=====");
		PrintToChat(client, "%s %s has been enabled.\nCreate by %s.", INFO_NAME, INFO_VERSION, INFO_AUTHOR);
		PrintToChat(client, "Github Page:%s", INFO_URL);
		
		switch(GameVersion){
			case 1:
			PrintToChat(client, "This Game is Left 4 Dead 1.");
			case 2:
			PrintToChat(client, "This Game is Left 4 Dead 2.");
			default:
			PrintToChat(client, "This Game is Not Left 4 Dead.");
		}
		
		//PrintToChat(client, "\nSurvivor Bot Status:\nHealth:%d\nWeapon Speed:%.2f%%\nMelee Speed:%.2f%%\nMove Speed:%.2f%%\nGravity:%.2f%%\nReflectDamage:%.2f%%\nExtraAttackDamage:%.2f%%\nSufferDamage:%.2f%%\n", 100 * GetConVarInt(SurvivorBotHealthMul), 1.0 / GetConVarFloat(SurvivorBotWeaponSpeedMul) * 100, 1.0 / GetConVarFloat(SurvivorBotMeleeSpeedMul) * 100, 100 * GetConVarFloat(SurvivorBotMoveSpeedMul), 100* GetConVarFloat(SurvivorBotGravity), 100 * GetConVarFloat(SurvivorBotReflectDamage), 100 * GetConVarFloat(SurvivorBotExtraAttackDamage), 100 * GetConVarFloat(SurvivorBotSufferDamage));
		PrintToChat(client, "\nSurvivor Bot Status:\nHealth:%d\nWeapon Speed:%.2f%%\nMove Speed:%.2f%%\nGravity:%.2f%%\nReflectDamage:%.2f%%\nExtraAttackDamage:%.2f%%\nSufferDamage:%.2f%%\n", 100 * GetConVarInt(SurvivorBotHealthMul), 1.0 / GetConVarFloat(SurvivorBotWeaponSpeedMul) * 100, 100 * GetConVarFloat(SurvivorBotMoveSpeedMul), 100* GetConVarFloat(SurvivorBotGravity), 100 * GetConVarFloat(SurvivorBotReflectDamage), 100 * GetConVarFloat(SurvivorBotExtraAttackDamage), 100 * GetConVarFloat(SurvivorBotSufferDamage));
		if (GetConVarInt(SurvivorBotInfiniteAmmo) == 1)
		{
			PrintToChat(client, "Survivor Bot have infinite ammo forever.");
		}
		else
		{
			PrintToChat(client, "Survivor Bot don't have infinite ammo.");
		}
		if (GetConVarInt(SurvivorBotFullHeal) == 1)
		{
			PrintToChat(client, "Survivor Bot have fully heal forever when use first aid kit.");
		}
		else
		{
			PrintToChat(client, "Survivor Bot don't have fully heal when use first aid kit.");
		}
		if (GetConVarInt(SurvivorBotLaserSight) == 1)
		{
			PrintToChat(client, "Survivor Bot will auto get laser sight forever.");
		}
		else
		{
			PrintToChat(client, "Survivor Bot will not auto get laser sight .");
		}
		switch(GetConVarInt(SurvivorBotSpecialAmmo)){
			case 1:
			PrintToChat(client, "Survivor Bot will auto get incendiary ammo forever.");
			case 2:
			PrintToChat(client, "Survivor Bot will auto get explosive ammo forever.");
			case 3:
			PrintToChat(client, "Survivor Bot will auto get incendiary or explosive ammo forever.");
			default:
			PrintToChat(client, "Survivor Bot will not auto get special ammo.");
			
		}
		switch(GetConVarInt(SurvivorBotHealItem)){
			case 1:
			PrintToChat(client, "Survivor Bot will auto get first aid kit forever.");
			case 2:
			PrintToChat(client, "Survivor Bot will auto get heal or upgrade item forever.");
			default:
			PrintToChat(client, "Survivor Bot will not auto get any heal or upgrade item.");
			
		}
		switch(GetConVarInt(SurvivorBotNoFriendlyDamage)){
			case 1:
			PrintToChat(client, "Survivor Bot will not get friendly damage.");
			default:
			PrintToChat(client, "Survivor Bot will get friendly damage.");
			
		}
		switch(GetConVarInt(SurvivorBotHealTimer)){
			case 0:
			PrintToChat(client, "Survivor Bot will not get hp regen every second.");
			default:
			PrintToChat(client, "Survivor Bot will get %d hp regen every second.",GetConVarInt(SurvivorBotHealTimer));
			
		}
		switch(GameVersion<=1 && GetConVarInt(SurvivorBotExtraItem)>0 ? 1 : GetConVarInt(SurvivorBotExtraItem)){
			case 1:
			PrintToChat(client, "Survivor Bot will auto get pill forever.");
			case 2:
			PrintToChat(client, "Survivor Bot will auto get adrenaline forever.");
			case 3:
			PrintToChat(client, "Survivor Bot will auto get pill or adrenaline forever.");
			default:
			PrintToChat(client, "Survivor Bot will not auto get pill or adrenaline.");
			
		}
		
		if (GetConVarInt(SurvivorBotPrimaryWeapon) == 1)
		{
		
			if(GetConVarInt(SurvivorBotPrimaryWeapon) >= 2){
			PrintToChat(client, "Survivor Bot will auto get all primary weapon forever.");
			}else{
			PrintToChat(client, "Survivor Bot will auto get primary weapon forever.");
			}
		}
		else
		{

			PrintToChat(client, "Survivor Bot will not auto get primary weapon.");
		}
		
		if (GameVersion<=1 ? false : GetConVarInt(SurvivorBotSecondaryWeapon) == 1 ? true : false)
		{
			if(GetConVarInt(SurvivorBotSecondaryWeapon) >= 2){
			PrintToChat(client, "Survivor Bot will auto get all secondary weapon forever.");
			}else{
			PrintToChat(client, "Survivor Bot will auto get secondary weapon forever.");
			}
		}
		else
		{
			PrintToChat(client, "Survivor Bot will not auto get secondary weapon.");
		}	
		if (GetConVarInt(SurvivorBotGrenade) == 1)
		{
			PrintToChat(client, "Survivor Bot will auto get grenade forever.");
		}
		else
		{
			PrintToChat(client, "Survivor Bot will not auto get grenade.");
		}
		
	}
	PrintToChat(client, "Have Fun\n:)");
	PrintToChat(client, "=====[CheatBot]=====");

	
}

stock PrintInformation(client){
	ReplyToCommand(client,"%s %s By %s\n%s\nAny More Infomation:%s",INFO_NAME,INFO_VERSION,INFO_AUTHOR,INFO_DESCRIPTION,INFO_URL);
}

stock RemoveParticle(client){
	
	if(PlayerParticleSpitter[client] != -1 && IsValidEntity(PlayerParticleSpitter[client])){
	
	
	RemoveEntity(PlayerParticleSpitter[client]);
	PlayerParticleSpitter[client] = -1;
	
	}
}

stock RemoveParticleEye(client){
	
	if((PlayerParticleLeft[client] != -1  ) && IsValidEntity(PlayerParticleLeft[client])){
	
	
	RemoveEntity(PlayerParticleLeft[client]);
	PlayerParticleLeft[client] = -1;
	
	}
	
	if((PlayerParticleRight[client] != -1  ) && IsValidEntity(PlayerParticleRight[client])){
	
	
	RemoveEntity(PlayerParticleRight[client]);
	PlayerParticleRight[client] = -1;
	
	}
}

stock CreateParticle(target){
	
	RemoveParticle(target);
	
	int entity = CreateEntityByName("info_particle_system");
	DispatchKeyValue(entity, "effect_name", "spitter_slime_trail");	
	DispatchSpawn(entity);
	ActivateEntity(entity);
	AcceptEntityInput(entity, "Start");
	SetVariantString("!activator");
	AcceptEntityInput(entity, "SetParent", target);
	SetVariantString("mouth");
	AcceptEntityInput(entity, "SetParentAttachment");	
	
	PlayerParticleSpitter[target] = entity;
		
	new Float:vPos[3];
		
	//vPos[1] = -2.0;
	vPos[0] = -4.0;
	vPos[2] = 3.0;
	
	TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);	
	
	
}

stock CreateParticleEye(target){
	
	RemoveParticleEye(target);
	{
	int entity = CreateEntityByName("info_particle_system");
	DispatchKeyValue(entity, "effect_name", "spitter_slime_trail");	
	DispatchSpawn(entity);
	ActivateEntity(entity);
	AcceptEntityInput(entity, "Start");
	SetVariantString("!activator");
	AcceptEntityInput(entity, "SetParent", target);
	SetVariantString("eyes");
	AcceptEntityInput(entity, "SetParentAttachment");	
	
	PlayerParticleLeft[target] = entity;
		
	new Float:vPos[3];
		
	//vPos[1] = -2.0;
	vPos[0] = -2.0;
	vPos[1] = 1.5;
	vPos[2] = 4.0;
	
	TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);	
	}

	{
	int entity = CreateEntityByName("info_particle_system");
	DispatchKeyValue(entity, "effect_name", "spitter_slime_trail");	
	DispatchSpawn(entity);
	ActivateEntity(entity);
	AcceptEntityInput(entity, "Start");
	SetVariantString("!activator");
	AcceptEntityInput(entity, "SetParent", target);
	SetVariantString("eyes");
	AcceptEntityInput(entity, "SetParentAttachment");	
	
	PlayerParticleRight[target] = entity;
		
	new Float:vPos[3];
		
	//vPos[1] = -2.0;
	vPos[0] = -2.0;
	vPos[1] = -1.5;
	vPos[2] = 4.0;
	
	TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);	
	}
	
}
