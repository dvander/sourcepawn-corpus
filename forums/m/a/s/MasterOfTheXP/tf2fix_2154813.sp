#pragma semicolon 1
#include <tf2_stocks>
#undef REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN
#include <sdkhooks>
#include <tf2items>
#include <tf2attributes>
#define REQUIRE_PLUGIN
#define REQUIRE_EXTENSIONS

#define PLUGIN_VERSION	"1.4.8_01"
public Plugin:myinfo = {
	name = "TF2Fix",
	author = "MasterOfTheXP",
	description = "Fixes various bugs, exploits, and more in Team Fortress 2.",
	version = PLUGIN_VERSION,
	url = "http://mstr.ca/"
};

enum { // TF2_IsPlayerInCondition seems to be a little bit expensive, so we track these conditions internally.
	Condition_Taunting,
	Condition_Cloaked,
	Condition_Slowed,
	Condition_Kritz,
	Condition_CritCandy,
	Condition_UberCharged,
	Condition_WinCrits,
	Condition_Charging
}
#define MaxConds Condition_Charging

/* Declare cvar handle for each fix */
new	Handle:cvarEnabled, Handle:cvarLogClassName;
new	Handle:cvarNonCritBackstabs, Handle:cvarWaterDoves, Handle:cvarDeadRingerTaunt,
	Handle:cvarPomsonSound, Handle:cvarIconManglerDeflect, Handle:cvarHypeMeterSwitch, Handle:cvarRageMeterSwitch,
	Handle:cvarBazaarHeadsSteal, Handle:cvarBazaarHeadsMeter, Handle:cvarEyelanderHeadsMeter, Handle:cvarYourEternalIntelligence, Handle:cvarCowManglerSlowdown,
	Handle:cvarDeadTaunts, Handle:cvarHomeRunBoost, Handle:cvarTomislavAnnounce, Handle:cvarGunslinger,
	Handle:cvarHuntsmanIcons, Handle:cvarHuntsmanWater, Handle:cvarScorchTaunt, Handle:cvarFanOResupply, Handle:cvarOriginalDraw,
	Handle:cvarBasherSuicide, Handle:cvarTeleporterThanks, Handle:cvarSydneyHeadshot, Handle:cvarPhlogAmmo, Handle:cvarTeleRecharge,
	/*Handle:cvarItemCooldown,*/ Handle:cvarEscapeMedic, Handle:cvarUberCrits, Handle:cvarBotTaunts, Handle:cvarEurekaDestroy,
	Handle:cvarVitaRounding, Handle:cvarBoostMeter, Handle:cvarPomsonPenetration, Handle:cvarBazookaHumiliation, Handle:cvarDeadRingerIndicator,
	Handle:cvarCraftMetal, Handle:cvarBonkWasted, Handle:cvarQuickFixSound, Handle:cvarSandmanReflectIcon, Handle:cvarDemoGuaranteeCrit,
	Handle:cvarCleaverReflectIcon, Handle:cvarPreroundMove, Handle:cvarChargeSound, Handle:cvarPomsonHitbox, Handle:cvarDecalRespawn,
	Handle:cvarWrangledRocketIcon, Handle:cvarCleaverCritBleed, Handle:cvarTankDestroySound, Handle:cvarInvulnDiamondback, Handle:cvarIconReflectDetonator,
	Handle:cvarBonkTaunt, Handle:cvarBazaarNoCrit, Handle:cvarSpecialTaunts, Handle:cvarTeleporterTaunt, Handle:cvarEurekaSapped,
	Handle:cvarEngiHighFive, Handle:cvarDetonatorCritSound;

/* Handles for the game's cvars */
new Handle:cvarWeaponCrits, Handle:cvarHypeMax, Handle:cvarSlidingTaunt;

/* Cached cvar values, for cvars that would otherwise be checked extremely often */
new bool:Enabled = true, bool:TomislavAnnounce = true, bool:Gunslinger = true, bool:OriginalDraw = true,
	bool:TeleporterThanks = true, bool:PhlogAmmo = true, bool:BotTaunts = true, bool:PomsonPenetration = true, bool:BazookaHumiliation = true,
	bool:QuickFixSound = true, bool:DemoGuaranteeCrit = true, bool:PreroundMove = false, bool:ChargeSound = false, bool:PomsonHitbox = true,
	bool:DecalRespawn = true, bool:CleaverCritBleed = true, bool:TankDestroySound = true, bool:InvulnDiamondback = true, bool:TeleporterTaunt,
	bool:DetonatorCritSound = true;

/* For checking if extensions are loaded */
new bool:extSDKHooks, bool:extTF2Attributes;

/* Client variables */
new bool:InCond[MAXPLAYERS + 1][MaxConds+1];
new PrevWeapons[MAXPLAYERS + 1][6];
new Float:RageMeter[MAXPLAYERS + 1];
new Float:DeathTime[MAXPLAYERS + 1];
new HitCount[MAXPLAYERS + 1];
new Float:LastHitTime[MAXPLAYERS + 1];
new bool:TookOwnTele[MAXPLAYERS + 1];
new Float:LastForceTauntTime[MAXPLAYERS + 1];
new Float:TomislavVoiceCommandTime[MAXPLAYERS + 1];
new Float:ChargeBeginTime[MAXPLAYERS + 1];
new Float:NextDecalTime[MAXPLAYERS + 1];
new bool:BackstabValidated[MAXPLAYERS + 1][MAXPLAYERS + 1]; // Is reset when used
new bool:ForceAttack[MAXPLAYERS + 1];
new Handle:hStopHighFiveTimer[MAXPLAYERS + 1];

/* Entity variables */
new bool:IsSentryRocketWrangled[2049];

/* HUD Text */
new Handle:hudDeadRinger, Handle:hudHeads;

/* Arrays */
new Handle:aBuildings;

/* "That's gotta hurt" */
new const String:CritReceiveSounds[][] = {
	"player/crit_received1.wav",
	"player/crit_received2.wav",
	"player/crit_received3.wav"
};

#define STABFIX_ANIMATION (1 << 0)
#define STABFIX_CRIT (1 << 1)
#define STABFIX_SOUND (1 << 2)

#define FIX_CONVAR_FLAGS FCVAR_NONE
public OnPluginStart()
{
	CreateConVar("sm_tf2fix_version", PLUGIN_VERSION, "Plugin version smoke! Don't touch this!", FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY);
	cvarEnabled = CreateConVar("tf_fix_enable","1","Enable or disable TF2Fix entirely.", FIX_CONVAR_FLAGS, true, 0.0, true, 1.0);
	cvarLogClassName = CreateConVar("tf_fix_killicon_logclassname", "0", "When TF2Fix fixes a weapon's kill icon, it will also update that weapon's logged console name.", FIX_CONVAR_FLAGS, true, 0.0, true, 1.0);
	
	/* Create cvar for each fix */
	cvarNonCritBackstabs = CreateConVar("tf_fix_spy_backstab_noncrit", "7", "Fix backstabs not behaving properly when tf_weapon_criticals is 0.\nAdd up the numbers to fix the various elements of it:\n1 = Animation\n2 = Crit status/damage\n4 = Sound", FIX_CONVAR_FLAGS, true, 0.0, true, 7.0);
	cvarWaterDoves = CreateConVar("tf_fix_taunt_medic_doves", "1", "Fix Taunt: The Meet the Medic spawning doves in water, where they made loud sounds.", FIX_CONVAR_FLAGS, true, 0.0, true, 1.0);
	cvarDeadRingerTaunt = CreateConVar("tf_fix_taunt_spy_feign", "1", "Fix taunting Dead Ringer Spies not getting their cloak activated when hit.", FIX_CONVAR_FLAGS, true, 0.0, true, 1.0);
	cvarPomsonSound = CreateConVar("tf_fix_engineer_pomson_sound", "1", "Fix Spies not hearing the \"resource drain\" sound when being hit with the Pomson 6000 while cloaked.", FIX_CONVAR_FLAGS, true, 0.0, true, 1.0);
	cvarIconManglerDeflect = CreateConVar("tf_fix_killicon_mangler_deflect", "1", "Fix deflected Cow Mangler lasers not having a kill icon.", FIX_CONVAR_FLAGS, true, 0.0, true, 1.0);
	cvarHypeMeterSwitch = CreateConVar("tf_fix_scout_hypeswitch", "1", "Fix Soda Popper and Baby Face Blaster meters being interchangeable.", FIX_CONVAR_FLAGS, true, 0.0, true, 1.0);
	cvarRageMeterSwitch = CreateConVar("tf_fix_soldier_rageswitch", "1", "Fix the Rage meter not being reset when switching banners.", FIX_CONVAR_FLAGS, true, 0.0, true, 1.0);
	cvarBazaarHeadsSteal = CreateConVar("tf_fix_demoman_heads_steal", "1", "Fix Demomen using the Eyelander collecting the heads of Bazaar Bargain Snipers that they killed.", FIX_CONVAR_FLAGS, true, 0.0, true, 1.0);
	cvarBazaarHeadsMeter = CreateConVar("tf_fix_sniper_heads_meter", "1", "Fix the Bazaar Bargain's Heads meter not rising above 6.", FIX_CONVAR_FLAGS, true, 0.0, true, 1.0);
	cvarEyelanderHeadsMeter = CreateConVar("tf_fix_demoman_heads_meter", "1", "Fix the Eyelander's Heads meter showing an incorrect value above 127 heads.", FIX_CONVAR_FLAGS, true, 0.0, true, 1.0);
	cvarYourEternalIntelligence = CreateConVar("tf_fix_spy_intelpickup", "1", "Fix Spies being able to pick up Intelligence while disguised using Your Eternal Reward.", FIX_CONVAR_FLAGS, true, 0.0, true, 1.0);
	cvarCowManglerSlowdown = CreateConVar("tf_fix_soldier_mangler_slowdown", "1", "Fix Soldiers who swapped away from the Cow Mangler while it was charging being slowed down.", FIX_CONVAR_FLAGS, true, 0.0, true, 1.0);
	cvarDeadTaunts = CreateConVar("tf_fix_taunt_dead", "1", "Fix taunting players completing their taunts while dead (e.g. Bat taunt, Minigun taunt).", FIX_CONVAR_FLAGS, true, 0.0, true, 1.0);
	cvarHomeRunBoost = CreateConVar("tf_fix_taunt_homerunboost", "1", "Fix the Scout's Home Run taunt kill not filling the Baby Face's Blaster's Boost meter.", FIX_CONVAR_FLAGS, true, 0.0, true, 1.0);
	cvarTomislavAnnounce = CreateConVar("tf_fix_heavy_tomislavannounce", "1", "Fix Tomislav Heavies blowing their own cover (\"I HAVE NEW WEAPON!\").", FIX_CONVAR_FLAGS, true, 0.0, true, 1.0);
	cvarGunslinger = CreateConVar("tf_fix_engineer_gunslinger", "1", "Fix an exploit with the Gunslinger where the user could store combo-punches.", FIX_CONVAR_FLAGS, true, 0.0, true, 1.0);
	cvarHuntsmanIcons = CreateConVar("tf_fix_killicon_huntsman", "1", "Fix some Huntsman kill icons not showing.", FIX_CONVAR_FLAGS, true, 0.0, true, 1.0);
	cvarHuntsmanWater = CreateConVar("tf_fix_sniper_huntsman_water", "1", "Fix lit Huntsman arrows not being extinguished by water.", FIX_CONVAR_FLAGS, true, 0.0, true, 1.0);
	cvarScorchTaunt = CreateConVar("tf_fix_taunt_pyro_flaregun", "1", "Fix Pyros not being able to hear their Scorch Shot's firing sound while taunting.", FIX_CONVAR_FLAGS, true, 0.0, true, 1.0);
	cvarFanOResupply = CreateConVar("tf_fix_scout_warfan_resupply", "1", "Fix the Fan O'War's marked for death status not being removed by resupply lockers.", FIX_CONVAR_FLAGS, true, 0.0, true, 1.0);
	cvarOriginalDraw = CreateConVar("tf_fix_soldier_original_draw", "1", "Fix the Original's draw sound not playing to the client using it.", FIX_CONVAR_FLAGS, true, 0.0, true, 1.0);
	cvarBasherSuicide = CreateConVar("tf_fix_killicon_scout_suicide", "1", "Fix the Boston Basher's and Three-Rune Blade's kill icons not showing for suicides.", FIX_CONVAR_FLAGS, true, 0.0, true, 1.0);
	cvarTeleporterThanks = CreateConVar("tf_fix_engineer_tele_thanks", "1", "Fix Engineers saying thanks when taking their own Teleporter.", FIX_CONVAR_FLAGS, true, 0.0, true, 1.0);
	cvarSydneyHeadshot = CreateConVar("tf_fix_killicon_sniper_sydneyheadshot", "1", "Fix the Sydney Sleeper being able to score headshot kills while crit-boosted.", FIX_CONVAR_FLAGS, true, 0.0, true, 1.0);
	cvarPhlogAmmo = CreateConVar("tf_fix_pyro_phlog_ammo", "1", "Fix the Phlogistinator's Mmmph not being useable with less than 20 ammo.", FIX_CONVAR_FLAGS, true, 0.0, true, 1.0);
	cvarTeleRecharge = CreateConVar("tf_fix_engineer_tele_upcharge", "1", "Fix Teleporters' recharge times being reset when upgraded.", FIX_CONVAR_FLAGS, true, 0.0, true, 1.0);
//	cvarItemCooldown = CreateConVar("tf_fix_item_cooldown", "1", "Fix items' (Jarate, Sandvich, etc.) cooldown times not being reset properly by resupply lockers.", FIX_CONVAR_FLAGS, true, 0.0, true, 1.0);
	cvarEscapeMedic = CreateConVar("tf_fix_item_pickaxe_callmedic", "1", "Fix players being able to call for MEDIC! with the Equalizer/Escape Plan active as a class other than Soldier.", FIX_CONVAR_FLAGS, true, 0.0, true, 1.0);
	cvarUberCrits = CreateConVar("tf_fix_medic_ubercrits", "1", "Fix hits on UberCharged players being labeled as Critical Hits.", FIX_CONVAR_FLAGS, true, 0.0, true, 1.0);
	cvarBotTaunts = CreateConVar("tf_fix_bot_taunt", "1", "Fix bots sometimes being able to move while taunting.", FIX_CONVAR_FLAGS, true, 0.0, true, 1.0);
	cvarEurekaDestroy = CreateConVar("tf_fix_engineer_eurekadestroy", "1", "Fix an exploit where Engineers using the Eureka Effect could teleport faster than usual.", FIX_CONVAR_FLAGS, true, 0.0, true, 1.0);
	cvarVitaRounding = CreateConVar("tf_fix_medic_vitasaw_rounding", "1", "Fix a rounding error in the Vitasaw's Uber-maintaining.", FIX_CONVAR_FLAGS, true, 0.0, true, 1.0);
	cvarBoostMeter = CreateConVar("tf_fix_scout_boost_meter", "0", "Fix the Baby Face's Blaster Boost meter never reaching 100%.", FIX_CONVAR_FLAGS, true, 0.0, true, 1.0);
	cvarPomsonPenetration = CreateConVar("tf_fix_engineer_pomson_penetration", "1", "Fix the Pomson's projectiles passing through buildings and becoming invisible.", FIX_CONVAR_FLAGS, true, 0.0, true, 1.0);
	cvarBazookaHumiliation = CreateConVar("tf_fix_soldier_bazooka_humiliation", "1", "Fix the Beggar's Bazooka being able to be overloaded during Humiliation.", FIX_CONVAR_FLAGS, true, 0.0, true, 1.0);
	cvarDeadRingerIndicator = CreateConVar("tf_fix_spy_deadringer_thirdperson", "1", "Fix Dead Ringer status being unknown in thirdperson or with viewmodels disabled.", FIX_CONVAR_FLAGS, true, 0.0, true, 1.0);
	cvarCraftMetal = CreateConVar("tf_fix_chat_craftmetal", "1", "Fix players being able to send metal craft notices to the server, to prevent \"PLAYER has crafted: Scrap Metal\" spam.", FIX_CONVAR_FLAGS, true, 0.0, true, 1.0);
	cvarBonkWasted = CreateConVar("tf_fix_scout_drink_unuse", "0", "Fix Bonk! being unusable for half of a minute if the user failed to complete the drink animation (ledges, airblasted, etc.).", FIX_CONVAR_FLAGS, true, 0.0, true, 1.0);
	cvarQuickFixSound = CreateConVar("tf_fix_medic_quickfix_sound", "1", "Fix an exploit where a Medic could keep the Quick-Fix Uber sound playing on a patient.", FIX_CONVAR_FLAGS, true, 0.0, true, 1.0);
	cvarSandmanReflectIcon = CreateConVar("tf_fix_killicon_deflect_ball", "1", "Fix a missing kill icon for deflecting baseballs.", FIX_CONVAR_FLAGS, true, 0.0, true, 1.0);
	cvarDemoGuaranteeCrit = CreateConVar("tf_fix_demoman_guaranteecrit", "0", "Fix Demomen being able to guarantee a melee crit at any range.", FIX_CONVAR_FLAGS, true, 0.0, true, 1.0);
	cvarCleaverReflectIcon = CreateConVar("tf_fix_killicon_deflect_cleaver", "1", "Fix a missing kill icon for deflecting cleavers.", FIX_CONVAR_FLAGS, true, 0.0, true, 1.0);
	cvarPreroundMove = CreateConVar("tf_fix_preroundjump", "0", "Fix being able to move using self-damage right before a round starts.", FIX_CONVAR_FLAGS, true, 0.0, true, 1.0);
	cvarChargeSound = CreateConVar("tf_fix_demoman_chargesound", "0", "Fix Demoman charge sounds being cut off by the crit boost sound.", FIX_CONVAR_FLAGS, true, 0.0, true, 1.0);
	cvarPomsonHitbox = CreateConVar("tf_fix_engineer_pomson_hitbox", "1", "Fix the Pomson 6000's projectiles having ridiculously large hitboxes.", FIX_CONVAR_FLAGS, true, 0.0, true, 1.0);
	cvarDecalRespawn = CreateConVar("tf_fix_spray_respawn", "1", "Fix players being able to spray their spraypaint image immediately after respawning.", FIX_CONVAR_FLAGS, true, 0.0, true, 1.0);
	cvarWrangledRocketIcon = CreateConVar("tf_fix_killicon_sentryrocket_wrangled", "1", "Fix the kill icon for a Wrangler-controlled Sentry's rocket being that of a level 3 Sentry.", FIX_CONVAR_FLAGS, true, 0.0, true, 1.0);
	cvarCleaverCritBleed = CreateConVar("tf_fix_scout_cleaver_bleedcrits", "1", "Fix the Flying Guillotine's bleed damage being able to critically hit.", FIX_CONVAR_FLAGS, true, 0.0, true, 1.0);
	cvarTankDestroySound = CreateConVar("tf_fix_tank_destroy_sound", "1", "Fix Mann vs. Machine Tanks continuing to play their bomb deploy sound after being destroyed.", FIX_CONVAR_FLAGS, true, 0.0, true, 1.0);
	cvarInvulnDiamondback = CreateConVar("tf_fix_spy_diamondback_invuln", "1", "Fix the Diamondback awarding guaranteed crits for backstabbing invulnerable players.", FIX_CONVAR_FLAGS, true, 0.0, true, 1.0);
	cvarIconReflectDetonator = CreateConVar("tf_fix_killicon_deflect_detonator", "1", "Fix a missing kill icon for the Detonator when the user detonates a deflected flare on themselves.", FIX_CONVAR_FLAGS, true, 0.0, true, 1.0);
	cvarBonkTaunt = CreateConVar("tf_fix_scout_drink_taunt", "1", "Fix Bonk! not being useable by taunting.", FIX_CONVAR_FLAGS, true, 0.0, true, 1.0);
	cvarBazaarNoCrit = CreateConVar("tf_fix_sniper_bazaar_nocrit", "0", "Fix the Bazaar Bargain falsely incrementing the Heads meter when tf_weapon_criticals is 0.", FIX_CONVAR_FLAGS, true, 0.0, true, 1.0);
	cvarSpecialTaunts = CreateConVar("tf_fix_taunt_thriller", "1", "Fix the Halloween taunt override being applied (or not applied) to some weapons incorrectly.", FIX_CONVAR_FLAGS, true, 0.0, true, 1.0);
	cvarTeleporterTaunt = CreateConVar("tf_fix_taunt_teleporter", "0", "Fix an exploit where players could taunt on top of a Teleporter which was then destroyed, continuing their taunt while being able to move.", FIX_CONVAR_FLAGS, true, 0.0, true, 1.0);
	cvarEurekaSapped = CreateConVar("tf_fix_engineer_eurekasapped", "1", "Fix being able to teleport to a sapped Teleporter Exit using the Eureka Effect.", FIX_CONVAR_FLAGS, true, 0.0, true, 1.0);
	cvarEngiHighFive = CreateConVar("tf_fix_taunt_engineer_highfive", "1", "Fix Engineers being stuck momentarily after high fiving.", FIX_CONVAR_FLAGS, true, 0.0, true, 1.0);
	cvarDetonatorCritSound = CreateConVar("tf_fix_pyro_detonator_critsound", "1", "Fix the Detonator sounding like the Flare Gun when firing crits.", FIX_CONVAR_FLAGS, true, 0.0, true, 1.0);
	
	// We only hook cvars if their values would otherwise be checked extremely often. Unfortunately, there are quite a few in this plugin.
	HookConVarChange(cvarEnabled, OnConVarChanged);
	HookConVarChange(cvarTomislavAnnounce, OnConVarChanged);
	HookConVarChange(cvarGunslinger, OnConVarChanged);
	HookConVarChange(cvarOriginalDraw, OnConVarChanged);
	HookConVarChange(cvarTeleporterThanks, OnConVarChanged);
	HookConVarChange(cvarPhlogAmmo, OnConVarChanged);
	HookConVarChange(cvarBotTaunts, OnConVarChanged);
	HookConVarChange(cvarPomsonPenetration, OnConVarChanged);
	HookConVarChange(cvarBazookaHumiliation, OnConVarChanged);
	HookConVarChange(cvarQuickFixSound, OnConVarChanged);
	HookConVarChange(cvarDemoGuaranteeCrit, OnConVarChanged);
	HookConVarChange(cvarPreroundMove, OnConVarChanged);
	HookConVarChange(cvarChargeSound, OnConVarChanged);
	HookConVarChange(cvarPomsonHitbox, OnConVarChanged);
	HookConVarChange(cvarDecalRespawn, OnConVarChanged);
	HookConVarChange(cvarCleaverCritBleed, OnConVarChanged);
	HookConVarChange(cvarTankDestroySound, OnConVarChanged);
	HookConVarChange(cvarInvulnDiamondback, OnConVarChanged);
	HookConVarChange(cvarTeleporterTaunt, OnConVarChanged);
	HookConVarChange(cvarDetonatorCritSound, OnConVarChanged);
	
	new String:CfgPath[PLATFORM_MAX_PATH];
	Format(CfgPath, sizeof(CfgPath), "./cfg/sourcemod/tf2fix.cfg");
	if (FileExists(CfgPath)) ServerCommand("exec sourcemod/tf2fix");
	
	AutoExecConfig(false, "tf2fix");
	
	Enabled = GetConVarBool(cvarEnabled);
	TomislavAnnounce = GetConVarBool(cvarTomislavAnnounce);
	Gunslinger = GetConVarBool(cvarGunslinger);
	OriginalDraw = GetConVarBool(cvarOriginalDraw);
	TeleporterThanks = GetConVarBool(cvarTeleporterThanks);
	PhlogAmmo = GetConVarBool(cvarPhlogAmmo);
	BotTaunts = GetConVarBool(cvarBotTaunts);
	PomsonPenetration = GetConVarBool(cvarPomsonPenetration);
	BazookaHumiliation = GetConVarBool(cvarBazookaHumiliation);
	QuickFixSound = GetConVarBool(cvarQuickFixSound);
	DemoGuaranteeCrit = GetConVarBool(cvarDemoGuaranteeCrit);
	PreroundMove = GetConVarBool(cvarPreroundMove);
	ChargeSound = GetConVarBool(cvarChargeSound);
	PomsonHitbox = GetConVarBool(cvarPomsonHitbox);
	DecalRespawn = GetConVarBool(cvarDecalRespawn);
	CleaverCritBleed = GetConVarBool(cvarCleaverCritBleed);
	TankDestroySound = GetConVarBool(cvarTankDestroySound);
	InvulnDiamondback = GetConVarBool(cvarInvulnDiamondback);
	TeleporterTaunt = GetConVarBool(cvarTeleporterTaunt);
	DetonatorCritSound = GetConVarBool(cvarDetonatorCritSound);
	
	HookEvent("player_hurt", Event_Hurt, EventHookMode_Pre);
	HookEvent("player_death", Event_Death, EventHookMode_Pre);
	HookEvent("player_spawn", Event_Spawn, EventHookMode_Pre);
	HookEvent("post_inventory_application", Event_Inventory, EventHookMode_Pre);
	HookEvent("teamplay_flag_event", Event_Intelligence, EventHookMode_Pre);
	HookEvent("player_teleported", Event_Teleport, EventHookMode_Pre);
	HookEvent("player_upgradedobject", Event_Upgrade, EventHookMode_Pre);
	HookEvent("item_found", Event_Item, EventHookMode_Pre);
	
	AddCommandListener(Listener_voicemenu, "voicemenu");
	AddCommandListener(Listener_destroy, "destroy");
	AddCommandListener(Listener_taunt, "taunt");
	AddCommandListener(Listener_taunt, "+taunt");
	AddCommandListener(Listener_eurekaeffect, "eureka_teleport");
	
	HookUserMessage(GetUserMessageId("SpawnFlyingBird"), UserMsg_SpawnBird, true);
	
	AddNormalSoundHook(SoundHook);
	
	CreateTimer(0.5, Timer_EveryHalfSecond, _, TIMER_REPEAT);
	CreateTimer(0.1, Timer_EveryDeciSecond, _, TIMER_REPEAT);

	hudDeadRinger = CreateHudSynchronizer();
	hudHeads = CreateHudSynchronizer();
	
	aBuildings = CreateArray();
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i)) continue;
		InCond[i][Condition_Taunting] = TF2_IsPlayerInCondition(i, TFCond_Taunting);
		InCond[i][Condition_Cloaked] = TF2_IsPlayerInCondition(i, TFCond_Cloaked);
		InCond[i][Condition_Slowed] = TF2_IsPlayerInCondition(i, TFCond_Slowed);
		InCond[i][Condition_Kritz] = TF2_IsPlayerInCondition(i, TFCond_Kritzkrieged);
		InCond[i][Condition_CritCandy] = TF2_IsPlayerInCondition(i, TFCond_HalloweenCritCandy);
		InCond[i][Condition_UberCharged] = TF2_IsPlayerInCondition(i, TFCond_Ubercharged);
		InCond[i][Condition_WinCrits] = TF2_IsPlayerInCondition(i, TFCond_CritOnWin);
	}
	
	extSDKHooks = LibraryExists("sdkhooks");
	extTF2Attributes = LibraryExists("tf2attributes");
	
	if (extSDKHooks)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i)) continue;
			SDKHook(i, SDKHook_TraceAttack, OnTraceAttack);
			SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
		}
	}
}

public OnMapStart()
{
	IsMedieval(true);
	PrecacheSound("weapons/knife_swing_crit.wav", true);
	PrecacheSound("weapons/doom_flare_gun.wav", true);
	PrecacheSound("weapons/flare_detonator_launch.wav", true);
	PrecacheSound("weapons/flaregun_shoot.wav", true);
	for (new i = 0; i < sizeof(CritReceiveSounds); i++)
		PrecacheSound(CritReceiveSounds[i], true);
	PrecacheSound("weapons/demo_charge_windup1.wav", true);
	PrecacheSound("weapons/demo_charge_windup2.wav", true);
	PrecacheSound("weapons/demo_charge_windup3.wav", true);
	PrecacheSound("weapons/flare_detonator_launch.wav", true);
}

public OnConfigsExecuted()
{
	cvarWeaponCrits = FindConVar("tf_weapon_criticals");
	cvarHypeMax = FindConVar("tf_scout_hype_pep_max");
	cvarSlidingTaunt = FindConVar("tf_allow_sliding_taunt");
}

public OnClientPutInServer(client)
{
	for (new i = 0; i <= MaxConds; i++)
		InCond[client][i] = false;
	for (new i = 0; i < 6; i++)
		PrevWeapons[client][i] = -1;
	
	RageMeter[client] = 0.0;
	DeathTime[client] = 0.0;
	HitCount[client] = 0;
	LastHitTime[client] = 0.0;
	TookOwnTele[client] = false;
	LastForceTauntTime[client] = 0.0;
	TomislavVoiceCommandTime[client] = 0.0;
	NextDecalTime[client] = 0.0;
	ForceAttack[client] = false;
	hStopHighFiveTimer[client] = INVALID_HANDLE;
	
	if (extSDKHooks)
	{
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}

public OnLibraryAdded(const String:name[])
{
	extSDKHooks = !extSDKHooks ? StrEqual(name, "sdkhooks", false) : extSDKHooks;
	extTF2Attributes = !extTF2Attributes ? StrEqual(name, "tf2attributes", false) : extTF2Attributes;
}

public OnLibraryRemoved(const String:name[])
{
	extSDKHooks = extSDKHooks ? !StrEqual(name, "sdkhooks", false) : extSDKHooks;
	extTF2Attributes = extTF2Attributes ? !StrEqual(name, "tf2attributes", false) : extTF2Attributes;
}

public Action:Event_Hurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!Enabled) return Plugin_Continue;
	new Action:action;
	new victim = GetClientOfUserId(GetEventInt(event, "userid")), attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new custom = GetEventInt(event, "custom");
	new damage = GetEventInt(event, "damageamount");
	
	new stabfix = GetConVarInt(cvarNonCritBackstabs);
	if (attacker && custom == TF_CUSTOM_BACKSTAB && !GetConVarBool(cvarWeaponCrits) && stabfix)
	{
		if (stabfix & STABFIX_CRIT)
		{
			SetEventInt(event, "damageamount", damage*3); // Cosmetic, does not affect actual damage
			SetEventBool(event, "crit", true);
		}
		if (stabfix & STABFIX_SOUND)
		{
			EmitSoundToAll("weapons/knife_swing_crit.wav", attacker);
			EmitSoundToClient(victim, CritReceiveSounds[ GetRandomInt(0, sizeof(CritReceiveSounds) - 1) ]);
		}
		if (stabfix & STABFIX_ANIMATION)
		{
			new sequence = -1;
			switch (GetPlayerWeaponIndex(attacker, TFWeaponSlot_Melee))
			{
				case 4, 194, 665, 794, 803, 883, 892, 901, 910, 959, 968:	sequence = 6;
				case 225, 356, 461, 574, 649:								sequence = 12;
				case 638:													sequence = 28;
				case 727:													sequence = 38;
			}
			SetViewmodelAnimation(attacker, sequence);
		}
//		action = Plugin_Changed; // Breaks it? O.o
	}
	
	if (GetEntProp(victim, Prop_Send, "m_bFeignDeathReady") && GetConVarBool(cvarDeadRingerTaunt) && InCond[victim][Condition_Taunting])
	{
		TF2_RemoveCondition(victim, TFCond_Taunting);
		TF2_AddCondition(victim, TFCond_DeadRingered, -1.0);
		new Handle:fakeEvent = CreateEvent("player_death", true);
		SetEventInt(fakeEvent, "userid", GetClientUserId(victim));
		SetEventInt(fakeEvent, "attacker", GetClientUserId(attacker));
		SetEventInt(fakeEvent, "weaponid", GetEventInt(event, "weaponid"));
		SetEventInt(fakeEvent, "customkill", custom);
		SetEventInt(fakeEvent, "death_flags", TF_DEATHFLAG_DEADRINGER);
		FireEvent(fakeEvent);
		new intel = GetEntPropEnt(victim, Prop_Send, "m_hItem");
		if (IsValidEntity(intel)) AcceptEntityInput(intel, "ForceDrop");
	}
	if (attacker && custom == TF_CUSTOM_PLASMA)
	{
		if (InCond[victim][Condition_Cloaked] && GetConVarBool(cvarPomsonSound))
			EmitSoundToClient(victim, "weapons/drg_pomson_drain_01.wav", _, _, _, _, _, 110);
	}
	if (attacker && custom == TF_CUSTOM_TAUNT_GRAND_SLAM && GetConVarBool(cvarHomeRunBoost))
	{
		if (772 == GetPlayerWeaponIndex(attacker, 0))
		{
			SetEntPropFloat(attacker, Prop_Send, "m_flHypeMeter", GetConVarFloat(cvarHypeMax));
			TF2_RecalculateSpeed(attacker);
		}
	}
	if (attacker && InCond[victim][Condition_UberCharged] && (GetEventBool(event, "crit") || GetEventBool(event, "minicrit")) && GetConVarBool(cvarUberCrits))
	{
		SetEventBool(event, "crit", false);
		SetEventBool(event, "minicrit", false);
	}
	if (attacker && GetConVarBool(cvarBoostMeter))
	{
		if (772 == GetPlayerWeaponIndex(attacker, 0))
		{
			new Float:max = GetConVarFloat(cvarHypeMax);
			if (RoundFloat(GetEntPropFloat(attacker, Prop_Send, "m_flHypeMeter")) == RoundFloat(max))
			{
				SetEntPropFloat(attacker, Prop_Send, "m_flHypeMeter", max*1.0102);
				TF2_RecalculateSpeed(attacker);
			}
		}
	}
	return action;
}

// This callback is a bit of a mess, sorry :c
public Action:Event_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!Enabled) return Plugin_Continue;
	new Action:action;
	new victim = GetClientOfUserId(GetEventInt(event, "userid")), attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new custom = GetEventInt(event, "customkill");
	new String:weapon[33];
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	if (custom == TF_CUSTOM_BACKSTAB && !GetConVarBool(cvarWeaponCrits) && GetConVarInt(cvarNonCritBackstabs) & STABFIX_CRIT)
	{
		SetEventInt(event, "damagebits", GetEventInt(event, "damagebits") | DMG_CRIT); // Adds red glow to the kill icon
//		action = Plugin_Changed;
	}
	if (GetConVarBool(cvarIconManglerDeflect) && StrEqual(weapon, "tf_projectile_energy_ball"))
		SetDeathWeapon(event, "deflect_rocket");
	if (Gunslinger && extSDKHooks && StrEqual(weapon, "robot_arm"))
	{
		if (HitCount[attacker] == -1)
		{
			SetDeathWeapon(event, "robot_arm_combo_kill", true);
			SetEventInt(event, "customkill", TF_CUSTOM_COMBO_PUNCH);
			SetEventInt(event, "weaponid", 0);
			SetEventInt(event, "damagebits", GetEventInt(event, "damagebits") | DMG_CRIT);
			HitCount[attacker] = 0;
			new wep = GetPlayerWeaponSlot(attacker, TFWeaponSlot_Melee);
			if (wep <= MaxClients || !IsValidEntity(wep)) return Plugin_Continue;
			if (!GetEntityNetClass(wep, weapon, sizeof(weapon))) return Plugin_Continue;
			if (!StrEqual(weapon, "CTFRobotArm", false)) return Plugin_Continue;
			SetEntData(wep, FindSendPropInfo("CTFRobotArm", "m_hRobotArm")+8, 1);
		}
	}
	if (GetConVarBool(cvarHuntsmanIcons))
	{
		if (StrEqual(weapon, "huntsman"))
		{
			new damagebits = GetEventInt(event, "damagebits");
			if (custom == 1 && damagebits & DMG_PLASMA)
			{
				SetDeathWeapon(event, "huntsman_flyingburn_headshot");
				SetEventInt(event, "customkill", 0);
			}
		}
		else if (StrEqual(weapon, "deflect_arrow"))
		{
			if (custom == 1)
			{
				SetDeathWeapon(event, "deflect_huntsman_headshot");
				SetEventInt(event, "customkill", 0);
			}
		}
		else if (StrEqual(weapon, "deflect_huntsman_flyingburn"))
		{
			new damagebits = GetEventInt(event, "damagebits");
			if (custom == 1 && damagebits & DMG_PLASMA)
			{
				SetDeathWeapon(event, "deflect_huntsman_headshot"); // deflect_huntsman_flyingburn_headshot no worky
				SetEventInt(event, "customkill", 0);
			}
		}
	}
	if (GetConVarBool(cvarSydneyHeadshot))
	{
		if (custom == 1 && StrEqual(weapon, "sydney_sleeper"))
			SetEventInt(event, "customkill", 0);
	}
	if (attacker == victim && GetConVarBool(cvarBasherSuicide))
	{
		new damagebits = GetEventInt(event, "damagebits");
		if (damagebits & DMG_CLUB && damagebits & DMG_BLAST_SURFACE && StrEqual(weapon, "world"))
		{
			if (PrevWeapons[victim][2] == 325) SetDeathWeapon(event, "boston_basher");
			else if (PrevWeapons[victim][2] == 452) SetDeathWeapon(event, "scout_sword");
		}
	}
	if (GetConVarBool(cvarSandmanReflectIcon) && StrEqual(weapon, "ball"))
	{
		new attacker_primary = GetPlayerWeaponSlot(attacker, 0);
		if (attacker_primary > -1)
		{
			new String:attacker_primary_class[24];
			GetEdictClassname(attacker_primary, attacker_primary_class, sizeof(attacker_primary_class));
			if (StrEqual(attacker_primary_class, "tf_weapon_flamethrower", false))
				SetDeathWeapon(event, "deflect_ball");
		}
	}
	if (GetConVarBool(cvarCleaverReflectIcon) && StrEqual(weapon, "cleaver"))
		SetDeathWeapon(event, "guillotine");
	if (GetConVarBool(cvarWrangledRocketIcon) && StrEqual(weapon, "obj_sentrygun3"))
	{
		new inflictor = GetEventInt(event, "inflictor_entindex");
		if (inflictor > MaxClients)
		{
			new String:cls[32];
			GetEdictClassname(inflictor, cls, sizeof(cls));
			if (StrEqual(cls, "tf_projectile_sentryrocket", false))
			{
				if (IsSentryRocketWrangled[inflictor])
					SetDeathWeapon(event, "wrangler_kill", true);
			}
		}
	}
	if (GetConVarBool(cvarIconReflectDetonator) && StrEqual(weapon, "deflect_flare_detonator"))
		SetDeathWeapon(event, "deflect_flare");
	if (!(GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER))
	{
		for (new i = 0; i <= MaxConds; i++)
			InCond[victim][i] = false;
		DeathTime[victim] = GetTickedTime();
		
		if (attacker && GetConVarBool(cvarBazaarHeadsSteal) && 402 == GetPlayerWeaponIndex(victim, 0) && (StrEqual(weapon, "sword") || StrEqual(weapon, "headtaker") || StrEqual(weapon, "nessieclub")))
			SetEntProp(attacker, Prop_Send, "m_iDecapitations", GetEntProp(attacker, Prop_Send, "m_iDecapitations") - GetEntProp(victim, Prop_Send, "m_iDecapitations"));
		
		if (InvulnDiamondback && attacker)
		{
			if (GetEventInt(event, "damagebits") & (DMG_CLUB|DMG_NEVERGIB|DMG_CRIT|DMG_BLAST_SURFACE) == (DMG_CLUB|DMG_NEVERGIB|DMG_CRIT|DMG_BLAST_SURFACE))
				BackstabValidated[attacker][victim] = true;
		}
	}
	return action;
}

stock SetDeathWeapon(Handle:event, const String:weapon[], bool:force = false)
{
	SetEventString(event, "weapon", weapon);
	if (force || GetConVarBool(cvarLogClassName)) SetEventString(event, "weapon_logclassname", weapon);
}

public Action:Event_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!Enabled) return;
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	for (new i = 0; i <= MaxConds; i++)
		InCond[client][i] = false;
	
	RageMeter[client] = 0.0;
	hStopHighFiveTimer[client] = INVALID_HANDLE;
	
	if (GetConVarBool(cvarVitaRounding))
	{
		if (173 == GetPlayerWeaponIndex(client, 2))
		{
			new sec = GetPlayerWeaponSlot(client, 1);
			if (sec > -1)
			{
				new offs = GetEntSendPropOffs(sec, "m_flChargeLevel");
				if (offs > -1) SetEntDataFloat(sec, offs, GetEntDataFloat(sec, offs)+0.000001, true);
			}
		}
	}
	if (DecalRespawn)
		SetEntPropFloat(client, Prop_Data, "m_flNextDecalTime", NextDecalTime[client]);
}

public Action:Event_Inventory(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!Enabled) return;
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new NewWeapons[6];
	for (new i = 0; i < 6; i++)
		NewWeapons[i] = GetPlayerWeaponIndex(client, i);
	
	if (PrevWeapons[client][0] != NewWeapons[0] && GetConVarBool(cvarHypeMeterSwitch))
		SetEntPropFloat(client, Prop_Send, "m_flHypeMeter", 0.0);
	if (PrevWeapons[client][1] != NewWeapons[1] && NewWeapons[0] != 594 && GetConVarBool(cvarRageMeterSwitch))
		SetEntPropFloat(client, Prop_Send, "m_flRageMeter", 0.0);
	if (PrevWeapons[client][0] == 441 && NewWeapons[0] != 441 && InCond[client][Condition_Slowed] && GetConVarBool(cvarCowManglerSlowdown))
	{
		TF2_RemoveCondition(client, TFCond_Slowed);
		TF2_RecalculateSpeed(client);
	}
	
	if (GetConVarBool(cvarFanOResupply)) TF2_RemoveCondition(client, TFCond_MarkedForDeath);
	
	/*if (GetConVarBool(cvarItemCooldown))
	{
		new Float:time = GetGameTime();
		for (new i = 0; i <= 2; i++)
		{
			new weapon = GetPlayerWeaponSlot(client, i);
			if (weapon == -1) continue;
			new offs = GetEntSendPropOffs(weapon, "m_flEffectBarRegenTime");
			if (offs == -1) continue;
			if (404 == GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex")) continue;
			SetEntDataFloat(weapon, offs, time, true);
		}
	}*/
}

public Action:Event_Intelligence(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!Enabled) return;
	if (GetConVarBool(cvarYourEternalIntelligence))
	{
		if (1 != GetEventInt(event, "eventtype")) return;
		new client = GetEventInt(event, "player");
		CreateTimer(0.1, Timer_RemoveDisguise, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:Timer_RemoveDisguise(Handle:timer, any:uid)
{
	new client = GetClientOfUserId(uid);
	if (!client) return;
	TF2_RemoveCondition(client, TFCond_Disguised);
}

public Action:Event_Teleport(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!Enabled) return;
	new client = GetClientOfUserId(GetEventInt(event, "userid")), builder = GetClientOfUserId(GetEventInt(event, "builderid"));
	if (TeleporterThanks)
	{
		new disguise = GetEntProp(client, Prop_Send, "m_iDisguiseTargetIndex");
		TookOwnTele[client] = (!disguise ? client : disguise) == builder;
	}
}

public Action:Event_Upgrade(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!Enabled) return;
	new type = GetEventInt(event, "object"), ent = GetEventInt(event, "index");
	if (type == 1 && GetConVarBool(cvarTeleRecharge))
	{
		if (GetEntProp(ent, Prop_Send, "m_iObjectMode"))
		{
			new entrance = -1, builder = GetEntPropEnt(ent, Prop_Send, "m_hBuilder");
			if (builder > -1)
			{
				while ((entrance = FindEntityByClassname(entrance, "obj_teleporter")) != -1)
				{
					if (GetEntProp(entrance, Prop_Send, "m_iObjectMode")) continue;
					if (builder != GetEntPropEnt(entrance, Prop_Send, "m_hBuilder")) continue;
					ent = entrance;
					break;
				}
			}
		}
		new Handle:data;
		CreateDataTimer(1.6, Timer_RestoreTeleChargeTime, data, TIMER_FLAG_NO_MAPCHANGE);
		WritePackCell(data, EntIndexToEntRef(ent));
		WritePackFloat(data, GetEntPropFloat(ent, Prop_Send, "m_flRechargeTime"));
		ResetPack(data);
	}
}

public Action:Timer_RestoreTeleChargeTime(Handle:timer, Handle:data)
{
	new ent = EntRefToEntIndex(ReadPackCell(data));
	if (ent <= MaxClients) return;
	new Float:time = ReadPackFloat(data);
	if (time > GetGameTime())
	{
		SetEntProp(ent, Prop_Send, "m_iState", 6);
		SetEntPropFloat(ent, Prop_Send, "m_flRechargeTime", time);
	}
}

public Action:Event_Item(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!Enabled) return;
	if (GetConVarBool(cvarCraftMetal))
	{
		new idx = GetEventInt(event, "itemdef");
		if ((idx == 5000 || idx == 5001 || idx == 5002) &&
		GetEventInt(event, "method") == 1 &&
		!GetEventBool(event, "isfake")) SetEventBroadcast(event, true);
	}
}

public Action:Listener_voicemenu(client, const String:command[], args)
{
	if (!Enabled) return Plugin_Continue;
	if (GetConVarBool(cvarEscapeMedic))
	{
		new String:arg1[2], String:arg2[2], active;
		GetCmdArg(1, arg1, sizeof(arg1));
		GetCmdArg(2, arg2, sizeof(arg2));
		active = GetPlayerWeaponIndex(client, -1);
		if (!StringToInt(arg1) && !StringToInt(arg2) && (128 == active || 775 == active))
			return Plugin_Stop;
	}
	if (TomislavAnnounce)
	{
		new wep = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if (wep > MaxClients)
		{
			if (424 == GetEntProp(wep, Prop_Send, "m_iItemDefinitionIndex") && GetEntProp(wep, Prop_Send, "m_iWeaponState"))
			{
				TomislavVoiceCommandTime[client] = GetTickedTime();
			}
		}
	}
	return Plugin_Continue;
}

public Action:Listener_destroy(client, const String:command[], args)
{
	if (!Enabled) return Plugin_Continue;
	if (GetConVarBool(cvarEurekaDestroy))
	{
		if (InCond[client][Condition_Taunting] && 589 == GetPlayerWeaponIndex(client, -1))
		{
			new ground = GetEntPropEnt(client, Prop_Send, "m_hGroundEntity");
			if (IsValidEdict(ground))
			{
				new offs = GetEntSendPropOffs(ground, "m_hBuilder");
				if (offs != -1)
				{
					if (client == GetEntDataEnt2(ground, offs))
						return Plugin_Stop;
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action:Listener_taunt(client, const String:command[], args)
{
	if (!Enabled) return Plugin_Continue;
	if (!GetConVarBool(cvarBonkTaunt)) return Plugin_Continue; // shusdivhivdshvsdudvshuidvsuhivsduihdvshuisdvhuihuidvisdvuhihdvu // <- .....Why did I put this again? Because Valve is silly? Probably.
	
	new active = GetPlayerWeaponIndex(client, -1);
	if (46 == active || 163 == active)
		ForceAttack[client] = true;
	
	return Plugin_Continue;
}

public Action:Listener_eurekaeffect(client, const String:command[], args)
{
	if (!Enabled) return Plugin_Continue;
	if (!GetConVarBool(cvarEurekaSapped)) return Plugin_Continue;
	
	new i = -1;
	while ((i = FindEntityByClassname(i, "obj_teleporter")) != -1)
	{
		if (client != GetEntPropEnt(i, Prop_Send, "m_hBuilder")) continue;
		if (!GetEntProp(i, Prop_Send, "m_iObjectMode")) continue;
		if (!GetEntProp(i, Prop_Send, "m_bHasSapper")) continue;
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

public Action:UserMsg_SpawnBird(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	if (!Enabled) return Plugin_Continue;
	if (GetConVarBool(cvarWaterDoves))
	{
		new Float:Pos[3];
		BfReadVecCoord(bf, Pos);
		new closestPlayer, Float:closestDist;
		for (new i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i)) continue;
			if (!IsPlayerAlive(i)) continue;
			decl Float:iPos[3];
			GetEntPropVector(i, Prop_Send, "m_vecOrigin", iPos);
			new Float:dist = GetVectorDistance(Pos, iPos);
			if (closestPlayer && dist > closestDist) continue;
			closestPlayer = i, closestDist = dist;
		}
		if (closestPlayer)
		{
			if (GetEntityFlags(closestPlayer) & FL_INWATER) return Plugin_Stop;
		}
	}
	return Plugin_Continue;
}

public Action:SoundHook(clients[64], &numClients, String:sound[PLATFORM_MAX_PATH], &client, &channel, &Float:volume, &level, &pitch, &flags)
{
	if (!Enabled) return Plugin_Continue;
	if (client > MaxClients || client <= 0) return Plugin_Continue;
	if (!IsClientInGame(client)) return Plugin_Continue;
	new Action:action;
	switch (channel)
	{
		case SNDCHAN_VOICE:
		{
			if (StrContains(sound, "vo/", false) > -1 || StrContains(sound, "vo\\", false) > -1)
			{
				if (!IsPlayerAlive(client) && GetTickedTime()-0.2 > DeathTime[client] && GetTickedTime()-5.0 < DeathTime[client] && GetConVarBool(cvarDeadTaunts)) return Plugin_Stop;
				if (TomislavAnnounce)
				{
					new wep = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
					if (wep > -1)
					{
						if (424 == GetEntProp(wep, Prop_Send, "m_iItemDefinitionIndex") && GetEntProp(wep, Prop_Send, "m_iWeaponState") && GetTickedTime() > TomislavVoiceCommandTime[client]+0.2 && StrContains(sound, "pain", false) == -1)
							action = Plugin_Stop;
					}
				}
				if (TeleporterThanks && TookOwnTele[client])
				{
					if (StrContains(sound, "engineer_thanksfortheteleporter", false) > -1)
						action = Plugin_Stop;
				}
			}
		}
		case SNDCHAN_WEAPON:
		{
			if (OriginalDraw && StrContains(sound, "quake_ammo_pickup_remastered", false) > -1)
				EmitSoundToClient(client, sound);
			if (DetonatorCritSound && 351 == GetPlayerWeaponIndex(client, 1) && StrContains(sound, "flaregun_shoot_crit", false) > -1)
				EmitSoundToAll("weapons/flare_detonator_launch.wav", client, SNDCHAN_STREAM, level, flags, volume, pitch);
		}
		case SNDCHAN_ITEM:
		{
			if (ChargeSound && StrContains(sound, "demo_charge_hit", false) > -1)
			{
				StopSound(client, SNDCHAN_AUTO, "weapons/demo_charge_windup1.wav");
				StopSound(client, SNDCHAN_AUTO, "weapons/demo_charge_windup2.wav");
				StopSound(client, SNDCHAN_AUTO, "weapons/demo_charge_windup3.wav");
			}
		}
	}
	return action;
}

public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
	if (!Enabled) return Plugin_Continue;
	new Action:action;
	if (GetConVarBool(cvarScorchTaunt) && StrEqual(weaponname, "tf_weapon_flaregun", false) && InCond[client][Condition_Taunting])
	{
		switch (GetPlayerWeaponIndex(client, 1))
		{
			case 740: EmitSoundToClient(client, "weapons/doom_flare_gun.wav", _, SNDCHAN_WEAPON);
			case 351: EmitSoundToClient(client, "weapons/flare_detonator_launch.wav", _, SNDCHAN_WEAPON);
			default: EmitSoundToClient(client, "weapons/flaregun_shoot.wav", _, SNDCHAN_WEAPON);
		}
	}
	if (Gunslinger && extSDKHooks && StrEqual(weaponname, "tf_weapon_robot_arm", false) && !InCond[client][Condition_Kritz] && !InCond[client][Condition_CritCandy])
	{
		new Float:time = GetGameTime();
		if (time < LastHitTime[client]+0.85 && HitCount[client] == 2)
		{
			SetEntData(weapon, FindSendPropInfo("CTFRobotArm", "m_hRobotArm")+4, HitCount[client]);
			result = true;
			HitCount[client] = -2;
		}
		else
		{
			SetEntData(weapon, FindSendPropInfo("CTFRobotArm", "m_hRobotArm")+4, (HitCount[client] < 0 || time >= LastHitTime[client]+0.85) ? 0 : HitCount[client]);
			result = false;
		}
		action = Plugin_Changed;
	}
	if (DemoGuaranteeCrit && GetTickedTime()-1.0 < ChargeBeginTime[client])
		SetEntProp(client, Prop_Send, "m_iNextMeleeCrit", 0);
	return action;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:ang[3], &weapon)
{
	if (!Enabled) return Plugin_Continue;
	new Action:action;
	
	if (PhlogAmmo)
	{
		if (buttons & IN_ATTACK2)
		{
			new active = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if (active > -1)
			{
				if (20 > GetAmmo_Weapon(active) && 594 == GetEntProp(active, Prop_Send, "m_iItemDefinitionIndex") && 99.9 < GetEntPropFloat(client, Prop_Send, "m_flRageMeter"))
				{
					new Float:time = GetTickedTime();
					if (time-0.2 > LastForceTauntTime[client])
					{
						FakeClientCommand(client, "taunt");
						LastForceTauntTime[client] = time;
					}
				}
			}
		}
	}
	
	if (BazookaHumiliation)
	{
		if (buttons & IN_ATTACK && !InCond[client][Condition_WinCrits])
		{
			if (RoundState_TeamWin == GameRules_GetRoundState())
			{
				new active = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
				if (active > -1)
				{
					if (730 == GetEntProp(active, Prop_Send, "m_iItemDefinitionIndex"))
					{
						buttons &= ~IN_ATTACK;
						SetClip_Weapon(active, 0);
						action = Plugin_Changed;
					}
				}
			}
		}
	}
	
	if (BotTaunts && InCond[client][Condition_Taunting] && IsFakeClient(client))
		SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 1.0);
	
	if (DecalRespawn && (impulse == 201 || impulse == 202))
		CreateTimer(0.0, Timer_CheckDecalTime, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	
	if (ForceAttack[client])
	{
		buttons |= IN_ATTACK;
		action = Plugin_Changed;
		ForceAttack[client] = false;
	}
	
	return action;
}

public Action:Timer_CheckDecalTime(Handle:timer, any:uid)
{
	new client = GetClientOfUserId(uid);
	if (!client) return;
	NextDecalTime[client] = GetEntPropFloat(client, Prop_Data, "m_flNextDecalTime");
}

public OnEntityCreated(ent, const String:cls[])
{
	if (!Enabled) return;
	if (ent <= MaxClients || ent > 2048) return;
	
	if (StrEqual(cls, "tf_flame", false))
		SDKHook(ent, SDKHook_Spawn, OnPomsonShotSpawned);
	else if (StrEqual(cls, "tf_projectile_sentryrocket", false))
		SDKHook(ent, SDKHook_Spawn, OnSentryRocketSpawned);
}

public OnEntityDestroyed(ent)
{
	if (ent <= MaxClients || ent > 2048) return;
	if (GetGameTime() <= 1.5) return;
	
	IsSentryRocketWrangled[ent] = false;
	
	if (TankDestroySound)
	{
		new String:cls[6];
		GetEdictClassname(ent, cls, sizeof(cls));
		if (!StrContains(cls, "tank", false))
			StopSound(ent, SNDCHAN_STATIC, "mvm/mvm_tank_deploy.wav");
	}
	
	if (extTF2Attributes && TeleporterTaunt)
	{
		new String:cls[5];
		GetEdictClassname(ent, cls, sizeof(cls));
		if (!StrContains(cls, "obj_", false))
		{
			if (!GetConVarBool(cvarSlidingTaunt))
			{
				for (new i = 1; i <= MaxClients; i++)
				{
					if (!IsClientInGame(i)) continue;
					if (!IsPlayerAlive(i)) continue;
					if (GetEntProp(i, Prop_Send, "m_bIsReadyToHighFive")) continue; // inb4 tons more ~~press-and-hold~~ toggle taunts that won't have an easy way to detect them like this
					if (ent != GetEntPropEnt(i, Prop_Send, "m_hGroundEntity")) continue;
					if (!TF2_IsPlayerInCondition(i, TFCond_Taunting)) continue;
					
					new Address:aSpeed = TF2Attrib_GetByName(i, "gesture speed increase");
					
					new bool:hadOldValue = aSpeed != Address_Null, Float:oldSpeed;
					if (hadOldValue) oldSpeed = TF2Attrib_GetValue(aSpeed);
					
					TF2Attrib_SetByName(i, "gesture speed increase", 1000.0);
					
					new Handle:data;
					CreateDataTimer(0.1, Timer_UndoGestureSpeed, data, TIMER_FLAG_NO_MAPCHANGE);
					WritePackCell(data, GetClientUserId(i));
					WritePackCell(data, hadOldValue);
					WritePackFloat(data, oldSpeed);
					ResetPack(data);
				}
			}
		}
	}
}

public Action:Timer_UndoGestureSpeed(Handle:timer, Handle:data)
{
	new client = GetClientOfUserId(ReadPackCell(data));
	if (!client) return;
	if (!ReadPackCell(data))
	{
		TF2Attrib_RemoveByName(client, "gesture speed increase");
		return;
	}
	TF2Attrib_SetByName(client, "gesture speed increase", ReadPackFloat(data));
}

public Action:OnPomsonShotSpawned(ent)
{
	new launcher = GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");
	if (launcher <= MaxClients) return;
	decl String:cls[21];
	GetEntityClassname(launcher, cls, sizeof(cls));
	if (!StrEqual(cls, "tf_weapon_drg_pomson", false)) return;
	if (PomsonPenetration) SDKHook(ent, SDKHook_Think, OnPomsonShotThink_Penetration);
	if (PomsonHitbox) SDKHook(ent, SDKHook_Think, OnPomsonShotThink_Hitbox);
}

public Action:OnSentryRocketSpawned(ent)
{
	new launcher = GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");
	if (launcher <= MaxClients) return;
	IsSentryRocketWrangled[ent] = bool:GetEntProp(launcher, Prop_Send, "m_bPlayerControlled");
}

public OnPomsonShotThink_Penetration(ent)
{
	new count = GetArraySize(aBuildings), Float:pos[3], team;
	GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
	new launcher = GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");
	if (launcher == -1) return;
	new owner = GetEntPropEnt(launcher, Prop_Send, "m_hOwnerEntity");
	if (owner == -1) return;
	team = GetClientTeam(owner);
	for (new i = 0; i < count; i++)
	{
		new build = EntRefToEntIndex(GetArrayCell(aBuildings, i));
		if (build <= MaxClients) continue;
		if (team != GetEntProp(build, Prop_Send, "m_iTeamNum")) continue;
		decl Float:buildpos[3], Float:buildmins[3], Float:buildmaxs[3];
		GetEntPropVector(build, Prop_Send, "m_vecOrigin", buildpos);
		GetEntPropVector(build, Prop_Send, "m_vecMins", buildmins);
		GetEntPropVector(build, Prop_Send, "m_vecMaxs", buildmaxs);
		new bool:skipbuild;
		for (new j = 0; j <= 2; j++)
		{
			if (pos[j] < buildpos[j]+buildmins[j] || pos[j] > buildpos[j]+buildmaxs[j])
			{
				skipbuild = true;
				break;
			}
		}
		if (skipbuild) continue;
		AcceptEntityInput(ent, "Kill");
	}
}

public OnPomsonShotThink_Hitbox(ent)
{
	new launcher = GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");
	if (launcher == -1) return;
	
	new owner = GetEntPropEnt(launcher, Prop_Send, "m_hOwnerEntity");
	if (owner == -1) return;
	
	new Float:mins[3], Float:maxs[3];
	GetEntPropVector(ent, Prop_Send, "m_vecMins", mins);
	GetEntPropVector(ent, Prop_Send, "m_vecMaxs", maxs);
	
	for (new i = 0; i <= 2; i++)
	{
		mins[i] *= 0.2;
		maxs[i] *= 0.2;
	}
	
	SetEntPropVector(ent, Prop_Send, "m_vecMins", mins);
	SetEntPropVector(ent, Prop_Send, "m_vecMaxs", maxs);
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	if (!Enabled) return Plugin_Continue;
	new Action:action;
	
	if (attacker > 0 && attacker <= MaxClients)
	{
		if (Gunslinger && inflictor == attacker && weapon > MaxClients && weapon != 4095 && IsValidEntity(weapon))
		{
			new String:wepclass[24];
			GetEdictClassname(weapon, wepclass, sizeof(wepclass));
			if (StrEqual(wepclass, "tf_weapon_robot_arm", false))
			{
				new Float:time = GetGameTime();
				if (time < LastHitTime[attacker]+0.86 && HitCount[attacker] == -2)
				{
					HitCount[attacker] = -1;
				}
				else
				{
					if (time < LastHitTime[attacker]+0.86) HitCount[attacker]++;
					else HitCount[attacker] = 1;
					if (HitCount[attacker] < 1) HitCount[attacker] = 1;
					
					if (!InCond[attacker][Condition_Kritz] && !InCond[attacker][Condition_CritCandy])
					{
						damagetype &= ~DMG_CRIT;
						action = Plugin_Changed;
					}
				}
				LastHitTime[attacker] = time;
			}
		}
		if (CleaverCritBleed && weapon > MaxClients)
		{
			new String:cls[24];
			GetEdictClassname(weapon, cls, sizeof(cls));
			if (StrEqual(cls, "tf_weapon_cleaver", false))
			{
				if (damagetype == DMG_SLASH && TF2_IsPlayerInCondition(victim, TFCond_Dazed) && damage == 4.0)
				{
					weapon = -1; // Hopefully, doing this won't cause too much trouble.   ┬─┬ノ( º _ ºノ)
					action = Plugin_Changed;
				}
			}
		}
		if (InvulnDiamondback && weapon > MaxClients && (damagetype & (DMG_CLUB|DMG_NEVERGIB|DMG_CRIT|DMG_BLAST_SURFACE) == (DMG_CLUB|DMG_NEVERGIB|DMG_CRIT|DMG_BLAST_SURFACE)))
		{
			new String:wpncls[16];
			GetEdictClassname(weapon, wpncls, sizeof(wpncls));
			if (GetClientHealth(victim)*2.0 == damage && StrEqual(wpncls, "tf_weapon_knife", false))
			{
				BackstabValidated[attacker][victim] = false;
				
				new Handle:data;
				CreateDataTimer(0.1, Timer_CheckBackstab, data, TIMER_FLAG_NO_MAPCHANGE);
				WritePackCell(data, GetClientUserId(attacker));
				WritePackCell(data, GetClientUserId(victim));
				ResetPack(data);
			}
		}
	}
	return action;
}

public Action:Timer_CheckBackstab(Handle:timer, Handle:data)
{
	new attacker = GetClientOfUserId(ReadPackCell(data));
	if (!attacker) return;
	new victim = GetClientOfUserId(ReadPackCell(data));
	if (!victim) return;
	
	if (!BackstabValidated[attacker][victim])
		SetEntProp(attacker, Prop_Send, "m_iRevengeCrits", GetEntProp(attacker, Prop_Send, "m_iRevengeCrits") - 1);
}

public Action:OnTraceAttack(victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup)
{
	if (!Enabled) return;
	if (attacker <= 0 || attacker > MaxClients) return;
	if (GetClientTeam(victim) == GetClientTeam(attacker)) return;
	
	new weapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
	if (weapon == -1) return;
	
	if (GetConVarBool(cvarWeaponCrits) || !GetConVarBool(cvarBazaarNoCrit)) return;
	
	new String:cls[15];
	GetEdictClassname(weapon, cls, sizeof(cls));
	if (StrContains(cls, "tf_weapon_snip", false)) return;
	
	if ((hitbox || hitgroup != 1) || !GetEntPropFloat(weapon, Prop_Send, "m_flChargedDamage"))
	{
		new heads = GetEntProp(attacker, Prop_Send, "m_iDecapitations");
		if (heads > 0) SetEntProp(attacker, Prop_Send, "m_iDecapitations", heads-2);
	}
}

public TF2Items_OnGiveNamedItem_Post(client, String:classname[], index, level, quality, entity)
{
	if (!Enabled) return;
	if (!extTF2Attributes) return;
	if (!GetConVarBool(cvarSpecialTaunts)) return;
	
	switch (index)
	{
		case 12, // Pyro's Shotgun
		351, // Detonator
		5, // Fists
		4, // Knife
		665, // Festive Knife
		794, 803, 883, 892, 901, 910, 959, 968: // Botkiller Knives
		{
			TF2Attrib_SetByName(entity, "special taunt", 1.0);
		}
		case 199, 415: // Unique Shotgun, Reserve Shooter
		{
			if (TF2_GetPlayerClass(client) != TFClass_Pyro)
				TF2Attrib_SetByName(entity, "special taunt", 0.0);
		}
		case 357: // Half-Zatoichi
		{
			if (TF2_GetPlayerClass(client) != TFClass_DemoMan)
				TF2Attrib_SetByName(entity, "special taunt", 0.0);
		}
		case 423, 1071: // Saxxy, Golden Frying Pan
		{
			new TFClassType:class = TF2_GetPlayerClass(client);
			if (class != TFClass_Heavy && class != TFClass_Spy)
				TF2Attrib_SetByName(entity, "special taunt", 0.0);
		}
	}
}

public Action:Timer_EveryHalfSecond(Handle:timer)
{
	if (!Enabled) return;
	new bool:BazaarHeadsMeter = GetConVarBool(cvarBazaarHeadsMeter), bool:EyelanderHeadsMeter = GetConVarBool(cvarEyelanderHeadsMeter), bool:HuntsmanWater = GetConVarBool(cvarHuntsmanWater),
	bool:DeadRingerIndicator = GetConVarBool(cvarDeadRingerIndicator);
	for (new client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client)) continue;
		new activeWeapon = GetPlayerWeaponIndex(client, -1);
		
		for (new i = 0; i < 6; i++)
			PrevWeapons[client][i] = GetPlayerWeaponIndex(client, i);
		RageMeter[client] = GetEntPropFloat(client, Prop_Send, "m_flRageMeter");
		
		if (BazaarHeadsMeter || EyelanderHeadsMeter)
		{
			new heads = GetEntProp(client, Prop_Send, "m_iDecapitations"), melee = PrevWeapons[client][2], bool:showMeter;
			if (heads > 6 && 402 == PrevWeapons[client][0]) showMeter = true;
			else if (heads > 127 && (melee == 132 || melee == 266 || melee == 482)) showMeter = true;
			
			if (showMeter && IsPlayerAlive(client))
			{
				SetHudTextParams(1.0, 1.0, 0.7, 255, 255, 255, 255);
				ShowSyncHudText(client, hudHeads, "%i Heads", heads);
			}
		}
		if (HuntsmanWater)
		{
			if (activeWeapon == 56 && GetEntityFlags(client) & FL_INWATER)
				SetEntProp(GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon"), Prop_Send, "m_bArrowAlight", 0);
		}
		if (DeadRingerIndicator && !IsFakeClient(client) && GetEntProp(client, Prop_Send, "m_bFeignDeathReady"))
		{	
			if (GetEntProp(client, Prop_Send, "m_nForceTauntCam"))
				ShowDeadRingerNotice(client);
			QueryClientConVar(client, "r_drawviewmodel", Query_Viewmodel);
			QueryClientConVar(client, "cl_first_person_uses_world_model", Query_MedievalThirdperson);
			if (IsMedieval()) QueryClientConVar(client, "tf_medieval_thirdperson", Query_MedievalThirdperson);
		}
	}
	
	if (PomsonPenetration)
	{
		ClearArray(aBuildings);
		new ent = -1;
		while ((ent = FindEntityByClassname(ent, "obj_*")) != -1)
		{
			if (PomsonPenetration) PushArrayCell(aBuildings, EntIndexToEntRef(ent));
		}
	}
}

public Action:Timer_EveryDeciSecond(Handle:timer)
{
	if (!Enabled) return;
	if (!PreroundMove) return; // Might as well. Having the timer not repeat while this cvar is off would be better, but meh. More fixes using this timer will probably be implemented Soon™
	static RoundState:prevState;
	new RoundState:roundState = GameRules_GetRoundState();
	if (prevState != roundState)
	{
		for (new client = 1; client <= MaxClients; client++)
		{
			if (!IsClientInGame(client)) continue;
			SetEntityMoveType(client, roundState != RoundState_Preround ? MOVETYPE_WALK : MOVETYPE_NONE);
		}
	}
	prevState = roundState;
}

public Action:Timer_ChangeSoundVolume(Handle:timer, Handle:data)
{
	new client = GetClientOfUserId(ReadPackCell(data));
	if (!InCond[client][Condition_Charging]) return;
	new String:sound[PLATFORM_MAX_PATH];
	ReadPackString(data, sound, sizeof(sound));
	EmitSoundToAll(sound, client, _, _, SND_CHANGEVOL, 1.0);
}

public Query_Viewmodel(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[])
{
	if (!IsClientInGame(client) || result != ConVarQuery_Okay || StringToInt(cvarValue)) return;
	if (GetEntProp(client, Prop_Send, "m_nForceTauntCam")) return;
	ShowDeadRingerNotice(client);
}

public Query_MedievalThirdperson(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[])
{
	if (!IsClientInGame(client) || result != ConVarQuery_Okay || !StringToInt(cvarValue)) return;
	if (GetEntProp(client, Prop_Send, "m_nForceTauntCam")) return;
	ShowDeadRingerNotice(client);
}

public TF2_OnConditionAdded(client, TFCond:cond)
{
	switch (cond)
	{
		case TFCond_Taunting:
		{
			InCond[client][Condition_Taunting] = true;
			TomislavVoiceCommandTime[client] = GetTickedTime(); // Prevents action slot taunts from being muted by the TomislavAnnounce fix
		}
		case TFCond_Cloaked: InCond[client][Condition_Cloaked] = true;
		case TFCond_Slowed: InCond[client][Condition_Slowed] = true;
		case TFCond_Kritzkrieged: InCond[client][Condition_Kritz] = true;
		case TFCond_HalloweenCritCandy: InCond[client][Condition_CritCandy] = true;
		case TFCond_Ubercharged: InCond[client][Condition_UberCharged] = true;
		case TFCond_CritOnWin: InCond[client][Condition_WinCrits] = true;
		case TFCond_Charging:
		{
			InCond[client][Condition_Charging] = true;
			ChargeBeginTime[client] = GetTickedTime();
		}
	}
	if (!Enabled) return;
	
	switch (cond)
	{
		case TFCond_Taunting:
		{
			if (IsFakeClient(client) && BotTaunts)
				SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 1.0);
			if (GetConVarBool(cvarBonkWasted))
			{
				new concept = GetEntProp(client, Prop_Send, "m_iTauntConcept"), active = GetPlayerWeaponIndex(client, -1);
				if (11 == concept && (46 == active || 163 == active))
				{
					new wep = GetPlayerWeaponSlot(client, 1);
					SetEntPropFloat(wep, Prop_Send, "m_flEffectBarRegenTime", GetGameTime());
				}
			}
			if (GetConVarBool(cvarEngiHighFive))
			{
				new players[2];
				players[0] = GetEntPropEnt(client, Prop_Send, "m_hHighFivePartner"); // Initiator
				if (players[0] > -1)
				{
					players[1] = client; // Partner
					
					for (new i = 0; i <= 1; i++)
					{
						new player = players[i];
						if (!IsClientInGame(player)) continue; // ???????????????
						if (!IsPlayerAlive(player)) continue;
						if (TFClass_Engineer != TF2_GetPlayerClass(player)) continue;
						if (!extTF2Attributes)
						{
							if (Address_Null != TF2Attrib_GetByName(player, "gesture speed increase")) continue; // Don't mess with it
						}
						hStopHighFiveTimer[player] = CreateTimer(4.2, Timer_StopHighFive, GetClientUserId(player), TIMER_FLAG_NO_MAPCHANGE);
					}
				}
			}
			if (GetConVarBool(cvarDeadRingerTaunt))
			{ // This fixes an issue caused by the Dead Ringer taunt fix. What exactly is it? I...forget.
				if (GetEntProp(client, Prop_Send, "m_bIsReadyToHighFive") && 59 == GetPlayerWeaponIndex(client, 4))
					SetEntPropEnt(client, Prop_Send, "m_bFeignDeathReady", 0);
			}
		}
		case TFCond_Bonked:
		{
			if (GetConVarBool(cvarBonkWasted))
			{
				if (46 == GetPlayerWeaponIndex(client, -1))
				{
					new wep = GetPlayerWeaponSlot(client, 1);
					SetAmmo_Weapon(wep, 0);
					SetEntPropFloat(wep, Prop_Send, "m_flEffectBarRegenTime", GetGameTime()+29.0);
				}
			}
		}
		case TFCond_CritCola:
		{
			if (163 == GetPlayerWeaponIndex(client, -1))
			{
				new wep = GetPlayerWeaponSlot(client, 1);
				SetAmmo_Weapon(wep, 0);
				SetEntPropFloat(wep, Prop_Send, "m_flEffectBarRegenTime", GetGameTime()+29.0);
			}
		}
		case TFCond_Charging:
		{
			if (ChargeSound)
			{
				new String:sound[40];
				Format(sound, sizeof(sound), "weapons/demo_charge_windup%i.wav", GetRandomInt(1,3));
				EmitSoundToAll(sound, client, _, _, _, 0.3);
				new Handle:data;
				CreateDataTimer(0.3, Timer_ChangeSoundVolume, data, TIMER_FLAG_NO_MAPCHANGE);
				WritePackCell(data, GetClientUserId(client));
				WritePackString(data, sound);
				ResetPack(data);
			}
		}
	}
}

public Action:Timer_StopHighFive(Handle:timer, any:uid)
{
	new client = GetClientOfUserId(uid);
	if (!client) return;
	if (timer != hStopHighFiveTimer[client]) return;
	if (!IsPlayerAlive(client)) return;
	if (TFClass_Engineer != TF2_GetPlayerClass(client)) return; // It can happen...I guess...
	if (extTF2Attributes)
	{
		if (Address_Null != TF2Attrib_GetByName(client, "gesture speed increase")) return;
	}
	SetEntPropEnt(client, Prop_Send, "m_hHighFivePartner", -1);
	TF2_RemoveCondition(client, TFCond_Taunting);
}

public TF2_OnConditionRemoved(client, TFCond:cond)
{
	switch (cond)
	{
		case TFCond_Taunting:
		{
			InCond[client][Condition_Taunting] = false;
			hStopHighFiveTimer[client] = INVALID_HANDLE;
		}
		case TFCond_Cloaked: InCond[client][Condition_Cloaked] = false;
		case TFCond_Slowed: InCond[client][Condition_Slowed] = false;
		case TFCond_Kritzkrieged: InCond[client][Condition_Kritz] = false;
		case TFCond_HalloweenCritCandy: InCond[client][Condition_CritCandy] = false;
		case TFCond_Ubercharged: InCond[client][Condition_UberCharged] = false;
		case TFCond_CritOnWin: InCond[client][Condition_WinCrits] = false;
		case TFCond_Charging: InCond[client][Condition_Charging] = false;
	}
	if (!Enabled) return;
	if (BotTaunts && cond == TFCond_Taunting && IsFakeClient(client))
		TF2_RecalculateSpeed(client);
	if (QuickFixSound && cond == TFCond_MegaHeal)
		StopSound(client, SNDCHAN_STATIC, "player/quickfix_invulnerable_on.wav");
}

public OnConVarChanged(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	if (cvar == cvarEnabled) Enabled = GetConVarBool(cvar);
	else if (cvar == cvarTomislavAnnounce) TomislavAnnounce = GetConVarBool(cvar);
	else if (cvar == cvarGunslinger) Gunslinger = GetConVarBool(cvar);
	else if (cvar == cvarOriginalDraw) OriginalDraw = GetConVarBool(cvar);
	else if (cvar == cvarTeleporterThanks) TeleporterThanks = GetConVarBool(cvar);
	else if (cvar == cvarPhlogAmmo) PhlogAmmo = GetConVarBool(cvar);
	else if (cvar == cvarBotTaunts) BotTaunts = GetConVarBool(cvar);
	else if (cvar == cvarPomsonPenetration) PomsonPenetration = GetConVarBool(cvar);
	else if (cvar == cvarBazookaHumiliation) BazookaHumiliation = GetConVarBool(cvar);
	else if (cvar == cvarQuickFixSound) QuickFixSound = GetConVarBool(cvar);
	else if (cvar == cvarDemoGuaranteeCrit) DemoGuaranteeCrit = GetConVarBool(cvar);
	else if (cvar == cvarPreroundMove) PreroundMove = GetConVarBool(cvar);
	else if (cvar == cvarChargeSound) ChargeSound = GetConVarBool(cvar);
	else if (cvar == cvarPomsonHitbox) PomsonHitbox = GetConVarBool(cvar);
	else if (cvar == cvarDecalRespawn) DecalRespawn = GetConVarBool(cvar);
	else if (cvar == cvarCleaverCritBleed) CleaverCritBleed = GetConVarBool(cvar);
	else if (cvar == cvarTankDestroySound) TankDestroySound = GetConVarBool(cvar);
	else if (cvar == cvarInvulnDiamondback) InvulnDiamondback = GetConVarBool(cvar);
	else if (cvar == cvarTeleporterTaunt) TeleporterTaunt = GetConVarBool(cvar);
	else if (cvar == cvarDetonatorCritSound) DetonatorCritSound = GetConVarBool(cvar);
}

stock GetPlayerWeaponIndex(client, slot)
{
	new ent = slot > -1 ? GetPlayerWeaponSlot(client, slot) : GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (!IsValidEdict(ent)) return -1;
	return GetEntProp(ent, Prop_Send, "m_iItemDefinitionIndex");
}

stock SetViewmodelAnimation(client, sequence)
{
	new ent = GetEntPropEnt(client, Prop_Send, "m_hViewModel");
	if (!IsValidEdict(ent)) return;
	SetEntProp(ent, Prop_Send, "m_nSequence", sequence);
}

stock GetAmmo_Weapon(weapon)
	return GetEntData(GetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity"), FindSendPropInfo("CTFPlayer", "m_iAmmo")+GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1)*4, 4);
stock SetClip_Weapon(weapon, value)
	SetEntData(weapon, FindSendPropInfo("CTFWeaponBase", "m_iClip1"), value, 4, true);
stock SetAmmo_Weapon(weapon, newAmmo)
{
	new owner = GetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity");
	if (owner == -1) return;
	SetEntData(owner, FindSendPropInfo("CTFPlayer", "m_iAmmo")+GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1)*4, newAmmo, 4, true);
}

stock ShowDeadRingerNotice(client)
{
	SetHudTextParams(1.0, 0.9, 0.7, 255, 255, 255, 255);
	ShowSyncHudText(client, hudDeadRinger, "Dead Ringer Active");
}

stock GetHealingTarget(client)
{
	new sec = GetPlayerWeaponSlot(client, 1);
	if (sec == -1) return -1;
	if (sec != GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon")) return -1;
	new offs = GetEntSendPropOffs(sec, "m_hHealingTarget");
	if (offs == -1) return -1;
	return GetEntDataEnt2(sec, offs);
}

stock IsMedieval(bool:bForceRecalc = false)
{
	static found = false;
	static bIsMedieval = false;
	if (bForceRecalc)
	{
		found = false;
		bIsMedieval = false;
	}
	if (!found)
	{
		found = true;
		if (FindEntityByClassname(-1, "tf_logic_medieval") != -1) bIsMedieval = true;
	}
	return bIsMedieval;
}

stock TF2_RecalculateSpeed(client)
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.01);