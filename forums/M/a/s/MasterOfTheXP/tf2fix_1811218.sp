#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#undef REQUIRE_PLUGIN
#include <updater>
#define REQUIRE_PLUGIN

#define PLUGIN_VERSION	"1.3"
#define UPDATE_URL    "http://mstr.ca/updates/tf2fix.txt"

public Plugin:myinfo = {
	name = "TF2Fix",
	author = "MasterOfTheXP",
	description = "Fixes various glitches, bugs, and more in Team Fortress 2.",
	version = PLUGIN_VERSION,
	url = "http://mstr.ca/"
};

/* CVARS (1) */
new Handle:cvarEnabled, Handle:cvarBazaar, Handle:cvarUbersaw, Handle:cvarBackstab, Handle:cvarManmelterTimer, Handle:cvarEyelander,
Handle:cvarCowMangler, Handle:cvarOverdose, Handle:cvarQuickFix, Handle:cvarKunai, Handle:cvarBushwacka, Handle:cvarYERIntelligence,
Handle:cvarDeadRingerTaunt, Handle:cvarBostonBasher, Handle:cvarBattalionsBackup, Handle:cvarCloakedForDeath, Handle:cvarTFWeapon, Handle:cvarMiniCrits,
Handle:cvarUberJarate, Handle:cvarMadMilk, Handle:cvarHighFive, Handle:cvarIFeelGood, Handle:cvarCharginTarge, Handle:cvarDidntNeedYourHelp,
Handle:cvarIncoming, Handle:cvarPomsonSound, Handle:cvarCowManglerReflectIcon, Handle:cvarDedTaunts, Handle:cvarNPCBlackBox,
Handle:cvarNPCCritSounds, Handle:cvarArenaMove, Handle:cvarArenaRegen, /*Handle:cvarBotTaunts,*/ Handle:cvarThanksForRide, Handle:cvarOriginal,
Handle:cvarDeadRingerIndicator, Handle:cvarEurekaCrits, Handle:cvarEyelanderOverflow, Handle:cvarPhlogRegen, Handle:cvarHuntsmanWater, Handle:cvarSpyCicleSpawn,
Handle:cvarBannerSwitch, Handle:cvarUberCupcake, Handle:cvarUberCrits, Handle:cvarMarkedForDeathResupply, Handle:cvarCowManglerSlowdown,
Handle:cvarCrossbow, Handle:cvarCritJarate, Handle:cvarDalokohsBar, Handle:cvarEurekaTaunt, Handle:cvarNPCRage,
Handle:cvarNEWWEAPON, Handle:cvarCraftMetal, Handle:cvarScorchTaunt, Handle:cvarEscapePlanHealing, Handle:cvarJumperCupcake,
Handle:cvarManmelterAttacking, Handle:cvarMedicCalls, Handle:cvarSandvichTauntSwitch, Handle:cvarBannerExploit, Handle:cvarWaterDoves,
Handle:cvarHeavyStun, Handle:cvarNPCSounds;

new Handle:tf_allow_taunt_switch;

/* HUD TEXT (1) */
new Handle:headsHUD;
new Handle:drHUD;

/* TIMERS */
new Handle:NotVeryMuchTimer;
new Handle:QuarterSecondTimer;

/* CVARS (2) */
new bool:Enabled = true, bool:Bazaar = true, bool:Ubersaw = true, bool:Backstab = true, bool:ManmelterTimer = true, bool:Eyelander = true,
bool:CowMangler = true, bool:Overdose = true, bool:QuickFix = true, bool:Kunai = true, bool:Bushwacka = true, bool:YERIntelligence = true,
bool:DeadRingerTaunt = true, bool:BostonBasher = true, bool:BattalionsBackup = true, bool:CloakedForDeath = true, bool:TFWeapon = true, bool:MiniCrits = true,
bool:UberJarate = true, bool:MadMilk = true, bool:HighFive = true, bool:IFeelGood = true, bool:CharginTarge = true, bool:DidntNeedYourHelp = true,
bool:Incoming = true, bool:PomsonSound = true, bool:CowManglerReflectIcon = true, bool:DedTaunts = true, bool:NPCBlackBox = true,
bool:NPCCritSounds = true, bool:ArenaMove = true, bool:ArenaRegen = true, /*bool:BotTaunts = true,*/ bool:ThanksForRide = true, bool:Original = true,
bool:DeadRingerIndicator = true, bool:EurekaCrits = true, bool:EyelanderOverflow = true, bool:PhlogRegen = true, bool:HuntsmanWater = true, bool:SpyCicleSpawn = true,
bool:BannerSwitch = true, bool:UberCupcake = true, bool:UberCrits = true, bool:MarkedForDeathResupply = true, bool:CowManglerSlowdown = true,
bool:Crossbow = true, bool:CritJarate = true, bool:DalokohsBar = true, bool:EurekaTaunt = true, bool:NPCRage = true,
bool:NEWWEAPON = true, bool:CraftMetal = true, bool:ScorchTaunt = true, bool:EscapePlanHealing = true, bool:JumperCupcake = true,
bool:ManmelterAttacking = true, bool:MedicCalls = true, bool:SandvichTauntSwitch = true, bool:BannerExploit = true, bool:WaterDoves = true,
bool:HeavyStun = true, bool:NPCSounds = true;

public Action:OnBothStart()
{
	PrecacheSound("weapons/knife_swing_crit.wav", true);
	PrecacheSound("player/crit_received1.wav", true);
	PrecacheSound("player/crit_received2.wav", true);
	PrecacheSound("player/crit_received3.wav", true);
	PrecacheSound("player/crit_hit.wav", true);
	PrecacheSound("player/crit_hit2.wav", true);
	PrecacheSound("player/crit_hit3.wav", true);
	PrecacheSound("player/crit_hit4.wav", true);
	PrecacheSound("player/crit_hit5.wav", true);
}

public OnPluginStart()
{
	/* CVARS (3) */
	new Flags = FCVAR_NONE;
	cvarEnabled = CreateConVar("sm_tf2fix_enabled","1","Enables/disables TF2Fix plugin.", Flags, true, 0.0, true, 1.0);
	CreateConVar("sm_tf2fix_version",PLUGIN_VERSION,"Plugin version.", FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY);
	cvarBazaar = CreateConVar("sm_tf2fix_bazaar","1","If on, Bazaar Bargain users who have more than 7 heads will see their real head count.", Flags, true, 0.0, true, 1.0);
	cvarUbersaw = CreateConVar("sm_tf2fix_ubersaw","1","If on, Ubersaw taunt kills display their unused icon.", Flags, true, 0.0, true, 1.0);
	cvarBackstab = CreateConVar("sm_tf2fix_backstab","1","If on, backstabs appear smoother on servers with random critical hits turned off.", Flags, true, 0.0, true, 1.0);
	cvarManmelterTimer = CreateConVar("sm_tf2fix_manmelter_timer","1","If on, Manmelter users get a timer in the bottom of their screen showing when they can fire again, since in most peoples' opinions, it's extremely hard to tell without a reload animation.", Flags, true, 0.0, true, 1.0);
	cvarEyelander = CreateConVar("sm_tf2fix_eyelander","1","If on, Eyelander kills on Bazaar Bargain Snipers won't steal that Sniper's heads.", Flags, true, 0.0, true, 1.0);
	cvarCowMangler = CreateConVar("sm_tf2fix_cowmangler_icon_suicide","1","If on, Cow Mangler afterburn suicides show the Cow Mangler kill icon.", Flags, true, 0.0, true, 1.0);
	cvarOverdose = CreateConVar("sm_tf2fix_overdose","1","If on, the Overdose's speed boost is updated live, not on weapon switch.", Flags, true, 0.0, true, 1.0);
	cvarQuickFix = CreateConVar("sm_tf2fix_quickfix","1","If on, the Quick-Fix gives a 3% speed boost when healing Pyros who are using the Attendant.", Flags, true, 0.0, true, 1.0);
	cvarKunai = CreateConVar("sm_tf2fix_kunai","1","If on, Spies who have over 185 HP will get their health set to 125, fixing a Conniver's Kunai exploit. Disable this if you have any plugin that gives Spies loads of health, like Boss Battles.", Flags, true, 0.0, true, 1.0);
	cvarBushwacka = CreateConVar("sm_tf2fix_bushwacka","1","If on, the Bushwacka will not occasionally spam crit sounds to all players.", Flags, true, 0.0, true, 1.0);
	cvarYERIntelligence = CreateConVar("sm_tf2fix_intelligence","1","If on, disguised Spies drop the Intelligence in Capture the Flag.", Flags, true, 0.0, true, 1.0);
	cvarDeadRingerTaunt = CreateConVar("sm_tf2fix_deadringer_taunt","1","If on, Spies that are hit while taunting with Dead Ringer active will cloak.", Flags, true, 0.0, true, 1.0);
	cvarBostonBasher = CreateConVar("sm_tf2fix_bostonbasher","1","If on, Boston Basher/Three-Rune Blade suicides will show their respective weapon kill icons instead of the skull and bones.", Flags, true, 0.0, true, 1.0);
	cvarBattalionsBackup = CreateConVar("sm_tf2fix_battalionsbackup","1","If on, the Battalion's Backup does not award rage for taking environmental damage.", Flags, true, 0.0, true, 1.0);
	cvarCloakedForDeath = CreateConVar("sm_tf2fix_fow_spies","1","If on, cloaked and marked for death Spies do not show a skull and bones symbol.", Flags, true, 0.0, true, 1.0);
	cvarTFWeapon = CreateConVar("sm_tf2fix_tf_weapon","1","If on, server admins don't need to type in 'tf_weapon_' when setting bot_forcefireweapon.", Flags, true, 0.0, true, 1.0);
	cvarMiniCrits = CreateConVar("sm_tf2fix_minicrits","1","If on, mini-crit sounds do not play for all players.", Flags, true, 0.0, true, 1.0);
	cvarUberJarate = CreateConVar("sm_tf2fix_uberjarate","1","If on, Snipers using the Sydney Sleeper are unable to coat UberCharged enemies in Jarate.", Flags, true, 0.0, true, 1.0);
	cvarMadMilk = CreateConVar("sm_tf2fix_madmilk","1","If on, Spies covered in Mad Milk will give off different responses than the Jarate ones.", Flags, true, 0.0, true, 1.0);
	cvarHighFive = CreateConVar("sm_tf2fix_highfive","1","If on, Pyros and Spies who high-five can use unused voice lines.", Flags, true, 0.0, true, 1.0);
	cvarIFeelGood = CreateConVar("sm_tf2fix_tresbon","1","If on, Spies gain the ability to feel tres bon!", Flags, true, 0.0, true, 1.0);
	cvarCharginTarge = CreateConVar("sm_tf2fix_democharge","1","If on, Demoman charge sounds will not be cut off.", Flags, true, 0.0, true, 1.0);
	cvarDidntNeedYourHelp = CreateConVar("sm_tf2fix_demodidntneedyourhelp","1","If on, prevents Demomen from saying 'I didn't need your help ya know'", Flags, true, 0.0, true, 1.0);
	cvarIncoming = CreateConVar("sm_tf2fix_sniperincoming","1","If on, prevents Snipers from whispering 'Incoming...' because no one can hear you when you whisper.", Flags, true, 0.0, true, 1.0);
	cvarPomsonSound = CreateConVar("sm_tf2fix_pomsonsound","1","If on, cloaked Spies will hear the Pomson's 'resource drain' sound when hit by it.", Flags, true, 0.0, true, 1.0);
	cvarCowManglerReflectIcon = CreateConVar("sm_tf2fix_cowmangler_icon_deflect","1","If on, the kill icon of a deflected Cow Mangler shot will be that of a deflected rocket, rather than the skull and bones.", Flags, true, 0.0, true, 1.0);
	cvarDedTaunts = CreateConVar("sm_tf2fix_deadtaunts","1","If on, players who die during certain taunts will not complete them while dead. (e.g. Scout: 'Hey knucklehead!' *dies* '...Bonk.'", Flags, true, 0.0, true, 1.0);
	cvarNPCBlackBox = CreateConVar("sm_tf2fix_bossonhit","1","If on, 'on hit' effects trigger when attacking boss characters.", Flags, true, 0.0, true, 1.0);
	cvarNPCCritSounds = CreateConVar("sm_tf2fix_bosscrits","1","If on, crit sounds will play when attacking boss characters with critical hits.", Flags, true, 0.0, true, 1.0);
	cvarArenaMove = CreateConVar("sm_tf2fix_arenamove","1","If on, players can't move at all during Setup time in Arena Mode.", Flags, true, 0.0, true, 1.0);
	cvarArenaRegen = CreateConVar("sm_tf2fix_arenaregen","1","If on, when an Arena round starts, all players are regenerated.", Flags, true, 0.0, true, 1.0);
//	cvarBotTaunts = CreateConVar("sm_tf2fix_bottaunts","1","If on, bots cannot move while being forced to taunt (e.g. by Holiday Punch hits, Fake and Force, etc.)", Flags, true, 0.0, true, 1.0);
	cvarThanksForRide = CreateConVar("sm_tf2fix_teleporterthanks","1","If on, Engineers won't thank themselves for their own Teleporters.", Flags, true, 0.0, true, 1.0);
	cvarOriginal = CreateConVar("sm_tf2fix_original","1","If on, the Original's draw sound will play to the client using the weapon, like it does for everyone around them.", Flags, true, 0.0, true, 1.0);
	cvarDeadRingerIndicator = CreateConVar("sm_tf2fix_drindicator","1","If on, clients with viewmodels off will have a notification that they have a Dead Ringer out.", Flags, true, 0.0, true, 1.0);
	cvarEurekaCrits = CreateConVar("sm_tf2fix_eurekacrits","1","If on, Engineers who have Frontier Justice revenge crits and taunt with the Eureka Effect will not lose them upon teleporting to spawn.", Flags, true, 0.0, true, 1.0);
	cvarEyelanderOverflow = CreateConVar("sm_tf2fix_eyelanderoverflow","1","If on, Demomen with the Eyelander who have more than 127 heads will get the correct amount of heads they have displayed to them.", Flags, true, 0.0, true, 1.0);
	cvarPhlogRegen = CreateConVar("sm_tf2fix_phlogregen","1","If on, Phlogistinator Pyros will not lose their Mmmph when touching a resupply locker.", Flags, true, 0.0, true, 1.0);
	cvarHuntsmanWater = CreateConVar("sm_tf2fix_firearrows","1","If on, lit Huntsman arrows are extinguished when the user enters water.", Flags, true, 0.0, true, 1.0);
	cvarSpyCicleSpawn = CreateConVar("sm_tf2fix_spyciclespawn","1","If on, and a Spy loses his Spy-cicle and quickly respawns, he won't have to wait to get it back.", Flags, true, 0.0, true, 1.0);
	cvarBannerSwitch = CreateConVar("sm_tf2fix_bannerswitch","1","If on, Soldiers who switch banners will have their rage cleared.", Flags, true, 0.0, true, 1.0);
	cvarUberCupcake = CreateConVar("sm_tf2fix_uberkamikaze","1","If on, Soldiers cannot avoid Kamikaze's damage by getting UberCharged.", Flags, true, 0.0, true, 1.0);
	cvarUberCrits = CreateConVar("sm_tf2fix_ubercrits","1","If on, crits against UberCharged players will NOT play a crit sound and display 'CRITICAL HIT!!!'", Flags, true, 0.0, true, 1.0);
	cvarMarkedForDeathResupply = CreateConVar("sm_tf2fix_markedfordeathresupply","1","If on, fixes the Fan O'War's marked for death status being sustained by resupply lockers.", Flags, true, 0.0, true, 1.0);
	cvarCowManglerSlowdown = CreateConVar("sm_tf2fix_cowmanglerslowdown","1","If on, fixes Cow Mangler Soldiers being slowed down permanently if they swapped weapons while charging.", Flags, true, 0.0, true, 1.0);
	cvarCrossbow = CreateConVar("sm_tf2fix_crossbow","1","If on, fixes the Crusader's Crossbow team-swap griefing exploit.", Flags, true, 0.0, true, 1.0);
	cvarCritJarate = CreateConVar("sm_tf2fix_critjarate","1","If on, fixes the Jarate and Mad Milk having critical glows.", Flags, true, 0.0, true, 1.0);
	cvarDalokohsBar = CreateConVar("sm_tf2fix_dalokohsbar","1","If on, Dispensers and Quick-Fix Medics will be able to heal Dalokohs Bar Heavies up to 350 HP.", Flags, true, 0.0, true, 1.0);
	cvarEurekaTaunt = CreateConVar("sm_tf2fix_eurekataunt","1","If on, prevents Engineers from using the 'destroy' console command while taunting with the Eureka Effect.", Flags, true, 0.0, true, 1.0);
	cvarNPCRage = CreateConVar("sm_tf2fix_bossrage","1","If on, hits on the Horsemann or MONOCULUS! will award rage (if using a banner or Phlogistinator).", Flags, true, 0.0, true, 1.0);
	cvarNEWWEAPON = CreateConVar("sm_tf2fix_tomislavnewweapon","1","If on, Heavies can't yell 'I HAVE NEW WEAPON' when using the Tomislav.", Flags, true, 0.0, true, 1.0);
	cvarCraftMetal = CreateConVar("sm_tf2fix_craftmetal","1","If on, 'PLAYER has crafted: Scrap Metal' notices are blocked.", Flags, true, 0.0, true, 1.0);
	cvarScorchTaunt = CreateConVar("sm_tf2fix_scorchtaunt","1","If on, Pyros will be able to hear the Scorch Shot's fire sound during their taunt.", Flags, true, 0.0, true, 1.0);
	cvarEscapePlanHealing = CreateConVar("sm_tf2fix_escapeplanhealing","1","If on, Soldiers who have the Escape Plan out can't be healed by Crusader's Crossbow-holding Medics.", Flags, true, 0.0, true, 1.0);
	cvarJumperCupcake = CreateConVar("sm_tf2fix_jumperkamikaze","1","If on, Soldiers with the Rocket Jumper equipped will not survive their own Equalizer's taunt.", Flags, true, 0.0, true, 1.0);
	cvarManmelterAttacking = CreateConVar("sm_tf2fix_manmelterattacking","1","If on, Pyros with the Manmelter cannot attack and extinguish at the same time.", Flags, true, 0.0, true, 1.0);
	cvarMedicCalls = CreateConVar("sm_tf2fix_mediccalls","1","If on, players cannot call for MEDIC! with the Equalizer/Escape Plan active (while not a Soldier)", Flags, true, 0.0, true, 1.0);
	cvarSandvichTauntSwitch = CreateConVar("sm_tf2fix_sandvichtauntswitch","1","If on, switching weapons while eating the Sandvich applies the healing that it's supposed to.", Flags, true, 0.0, true, 1.0);
	cvarBannerExploit = CreateConVar("sm_tf2fix_bannersaverage","1","If on, Soldiers can't hold down primare fire with a banner to sustain the rage.", Flags, true, 0.0, true, 1.0);
	cvarWaterDoves = CreateConVar("sm_tf2fix_waterdoves","1","If on, fixes doves spawned by Taunt: The Meet the Medic spawning in water. Doves that are spawned in water make loud splash sounds.", Flags, true, 0.0, true, 1.0);
	cvarHeavyStun = CreateConVar("sm_tf2fix_heavystun","1","If on, fixes Heavies being able to use Fists and jump while stunned.", Flags, true, 0.0, true, 1.0);
	cvarNPCSounds = CreateConVar("sm_tf2fix_bosssounds","1","If on, fixes Horsemann/MONOCULUS! spawn/defeat/escape sounds being cut off by voices.", Flags, true, 0.0, true, 1.0);
	
	tf_allow_taunt_switch = FindConVar("tf_allow_taunt_switch");
	
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	HookEvent("player_hurt", Event_Hurt, EventHookMode_Pre);
	HookEvent("player_highfive_start", Event_Brofist_Start, EventHookMode_Pre); /* why brofist? because shameless self-plug for mstr.ca/brofist */
	HookEvent("npc_hurt", Event_NpcHurt, EventHookMode_Post); /* when the Horseless Headless Horsemann or MONOCULUS! are attacked */
	HookEvent("teamplay_round_start", Event_RoundStart);
	HookEvent("player_teleported", Event_Teleport, EventHookMode_Pre); /* waaarp zooone */
	HookEvent("post_inventory_application", Event_Inventory, EventHookMode_Pre);
	HookEvent("player_team", Event_Team, EventHookMode_Pre);
	HookEvent("item_found", Event_Item, EventHookMode_Pre);
	HookEvent("player_healed", Event_Healing, EventHookMode_Pre);
	HookEvent("player_builtobject", Event_ErectingASapper, EventHookMode_Post);
	HookEvent("pumpkin_lord_summoned", Event_NpcSpawn, EventHookMode_Post);
	HookEvent("pumpkin_lord_killed", Event_NpcDed, EventHookMode_Post);
	HookEvent("eyeball_boss_summoned", Event_NpcSpawn, EventHookMode_Post);
	HookEvent("eyeball_boss_killed", Event_NpcDed, EventHookMode_Post);
	HookEvent("eyeball_boss_escaped", Event_NpcEscaped, EventHookMode_Post);
	
	HookUserMessage(GetUserMessageId("SpawnFlyingBird"), UserMsg_SpawnBird, true);
	
	AddCommandListener(Command_destroy, "destroy");
	AddCommandListener(Command_voicemenu, "voicemenu");
	
	/* HUD TEXT (2) */
	headsHUD = CreateHudSynchronizer();
	drHUD = CreateHudSynchronizer();
	
	/* CVARS (4) */
	HookConVarChange(cvarEnabled, CvarChange);
	HookConVarChange(cvarBazaar, CvarChange);
	HookConVarChange(cvarUbersaw, CvarChange);
	HookConVarChange(cvarBackstab, CvarChange);
	HookConVarChange(cvarManmelterTimer, CvarChange);
	HookConVarChange(cvarEyelander, CvarChange);
	HookConVarChange(cvarCowMangler, CvarChange);
	HookConVarChange(cvarOverdose, CvarChange);
	HookConVarChange(cvarQuickFix, CvarChange);
	HookConVarChange(cvarKunai, CvarChange);
	HookConVarChange(cvarBushwacka, CvarChange);
	HookConVarChange(cvarYERIntelligence, CvarChange);
	HookConVarChange(cvarDeadRingerTaunt, CvarChange);
	HookConVarChange(cvarBostonBasher, CvarChange);
	HookConVarChange(cvarBattalionsBackup, CvarChange);
	HookConVarChange(cvarCloakedForDeath, CvarChange);
	HookConVarChange(cvarTFWeapon, CvarChange);
	HookConVarChange(cvarMiniCrits, CvarChange);
	HookConVarChange(cvarUberJarate, CvarChange);
	HookConVarChange(cvarMadMilk, CvarChange);
	HookConVarChange(cvarHighFive, CvarChange);
	HookConVarChange(cvarIFeelGood, CvarChange);
	HookConVarChange(cvarCharginTarge, CvarChange);
	HookConVarChange(cvarDidntNeedYourHelp, CvarChange);
	HookConVarChange(cvarIncoming, CvarChange);
	HookConVarChange(cvarPomsonSound, CvarChange);
	HookConVarChange(cvarCowManglerReflectIcon, CvarChange);
	HookConVarChange(cvarDedTaunts, CvarChange);
	HookConVarChange(cvarNPCBlackBox, CvarChange);
	HookConVarChange(cvarNPCCritSounds, CvarChange);
	HookConVarChange(cvarArenaMove, CvarChange);
	HookConVarChange(cvarArenaRegen, CvarChange);
//	HookConVarChange(cvarBotTaunts, CvarChange);
	HookConVarChange(cvarThanksForRide, CvarChange);
	HookConVarChange(cvarOriginal, CvarChange);
	HookConVarChange(cvarDeadRingerIndicator, CvarChange);
	HookConVarChange(cvarEurekaCrits, CvarChange);
	HookConVarChange(cvarEyelanderOverflow, CvarChange);
	HookConVarChange(cvarPhlogRegen, CvarChange);
	HookConVarChange(cvarHuntsmanWater, CvarChange);
	HookConVarChange(cvarSpyCicleSpawn, CvarChange);
	HookConVarChange(cvarBannerSwitch, CvarChange);
	HookConVarChange(cvarUberCupcake, CvarChange);
	HookConVarChange(cvarUberCrits, CvarChange);
	HookConVarChange(cvarMarkedForDeathResupply, CvarChange);
	HookConVarChange(cvarCowManglerSlowdown, CvarChange);
	HookConVarChange(cvarCrossbow, CvarChange);
	HookConVarChange(cvarCritJarate, CvarChange);
	HookConVarChange(cvarDalokohsBar, CvarChange);
	HookConVarChange(cvarEurekaTaunt, CvarChange);
	HookConVarChange(cvarNPCRage, CvarChange);
	HookConVarChange(cvarNEWWEAPON, CvarChange);
	HookConVarChange(cvarCraftMetal, CvarChange);
	HookConVarChange(cvarScorchTaunt, CvarChange);
	HookConVarChange(cvarEscapePlanHealing, CvarChange);
	HookConVarChange(cvarJumperCupcake, CvarChange);
	HookConVarChange(cvarManmelterAttacking, CvarChange);
	HookConVarChange(cvarMedicCalls, CvarChange);
	HookConVarChange(cvarSandvichTauntSwitch, CvarChange);
	HookConVarChange(cvarBannerExploit, CvarChange);
	HookConVarChange(cvarWaterDoves, CvarChange);
	HookConVarChange(cvarHeavyStun, CvarChange);
	HookConVarChange(cvarNPCSounds, CvarChange);
	
	AddNormalSoundHook(SoundHook);
	
	new String:disGaem[10];
	GetGameFolderName(disGaem, 10);
	if (strncmp(disGaem, "tf", 2, false) != 0) SetFailState("TF2Fix, a plugin that fixes Team Fotress 2, doesn't work on any game except, um, Braid!");
	
	AutoExecConfig(true, "tf2fix");
	
	if (LibraryExists("updater"))
		Updater_AddPlugin(UPDATE_URL)
	
	OnBothStart();
}

public OnMapStart()
{
	OnBothStart();
	IsMedieval(true);
	NotVeryMuchTimer = CreateTimer(0.15, timer_NotVeryMuchOfASecond, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	QuarterSecondTimer = CreateTimer(0.25, timer_Quartersecond, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	PrecacheSound("ui/halloween_boss_summoned_fx.wav");
	PrecacheSound("ui/halloween_boss_defeated_fx.wav");
	PrecacheSound("ui/halloween_boss_escape.wav");
}

public OnLibraryAdded(const String:name[])
{
    if (StrEqual(name, "updater"))
		Updater_AddPlugin(UPDATE_URL)
}

new wepEnt, wepIndex, rand, bool:arenaModeSetupTime = false,
sniperHeads[MAXPLAYERS + 1], Float:markedForDeath[MAXPLAYERS + 1], bool:isPlayingPomsonSound[MAXPLAYERS + 1],
bool:didTakeOwnTeleporter[MAXPLAYERS + 1] = false, bool:hasDeadRingerMessage[MAXPLAYERS + 1] = { false, ... },
revengeCrits[MAXPLAYERS + 1], Float:phlog[MAXPLAYERS + 1] = { 0.0, ... }, bool:justRegenerated[MAXPLAYERS + 1] = { false, ... },
equippedBanner[MAXPLAYERS + 1], bool:hasCowMangler[MAXPLAYERS + 1], bool:IsTaunting[MAXPLAYERS + 1] = { false, ... },
bool:dontAttack[MAXPLAYERS + 1] = { false, ... }, MonoSpawns;

public Action:timer_NotVeryMuchOfASecond(Handle:timer)
{
	if (!Enabled)
	{
		NotVeryMuchTimer = INVALID_HANDLE;
		return Plugin_Stop;
	}
	rand = -1;
	for (new z = 1; z <= MaxClients; z++)
	{
		if (!IsClientInGame(z)) continue;
		new TFClassType:class = TF2_GetPlayerClass(z), activeWeapon, primaryWeapon, secondaryWeapon, meleeWeapon, HP = GetClientHealth(z), MaxHP = TF2_GetPlayerResourceData(z, TFResource_MaxHealth);
		if (GetPlayerWeaponSlot(z, TFWeaponSlot_Primary) == GetEntPropEnt(z, Prop_Send, "m_hActiveWeapon")) activeWeapon = 0;
		if (GetPlayerWeaponSlot(z, TFWeaponSlot_Secondary) == GetEntPropEnt(z, Prop_Send, "m_hActiveWeapon")) activeWeapon = 1;
		if (GetPlayerWeaponSlot(z, TFWeaponSlot_Melee) == GetEntPropEnt(z, Prop_Send, "m_hActiveWeapon")) activeWeapon = 2;
		if ((wepEnt = GetPlayerWeaponSlot(z, 0))!=-1) primaryWeapon = GetEntProp(wepEnt, Prop_Send, "m_iItemDefinitionIndex");
		if ((wepEnt = GetPlayerWeaponSlot(z, 1))!=-1) secondaryWeapon = GetEntProp(wepEnt, Prop_Send, "m_iItemDefinitionIndex");
		if ((wepEnt = GetPlayerWeaponSlot(z, 2))!=-1) meleeWeapon = GetEntProp(wepEnt, Prop_Send, "m_iItemDefinitionIndex");
		/*if (primaryWeapon == 752 && activeWeapon != 0)
			SetEntPropFloat(GetPlayerWeaponSlot(z, 0), Prop_Send, "m_flChargedDamage", 0.0);*/
		if (TF2_IsPlayerInCondition(z, TFCond_Taunting) && !IsTaunting[z] && SandvichTauntSwitch)
		{	// Client starts taunting
			IsTaunting[z] = true;
			if (secondaryWeapon == 42 && GetConVarInt(tf_allow_taunt_switch) > 0)
			{
				new uid = GetClientUserId(z);
				CreateTimer(1.0, SandvichTauntFix, uid);
				CreateTimer(1.92, SandvichTauntFix, uid);
				CreateTimer(2.95, SandvichTauntFix, uid);
				CreateTimer(4.0, SandvichTauntFix, uid);
			}
		}
		if (!TF2_IsPlayerInCondition(z, TFCond_Taunting) && IsTaunting[z])
		{	// Client stops taunting
			IsTaunting[z] = false;
		}
		if (MaxHP > 329 && DalokohsBar)
		{
			if (GetMedicCount(z, false) != GetEntProp(z, Prop_Send, "m_nNumHealers"))
			{
				if (HP >= MaxHP - 50) HealPlayer(z, 2, 0, 0);
			}
		}
		if (arenaModeSetupTime && ArenaMove && (GetClientTeam(z) == 2 || GetClientTeam(z) == 3) && GetEntityMoveType(z) != MOVETYPE_NOCLIP) SetEntityMoveType(z, MOVETYPE_NONE);
		if (TF2_IsPlayerInCondition(z, TFCond_Ubercharged) && TF2_IsPlayerInCondition(z, TFCond_Jarated) && UberJarate) TF2_RemoveCondition(z, TFCond_Jarated);
		if (secondaryWeapon == 595 /* The Manmelter */ && ManmelterTimer)
		{
			wepEnt = GetPlayerWeaponSlot(z, 1);
			new Float:nextAttackFloat = (GetEntPropFloat(wepEnt, Prop_Send, "m_flNextPrimaryAttack") - GetGameTime());
			if (nextAttackFloat > 0.0)
			{
				SetHudTextParams(1.0, 1.0, 0.2, 255, 255, 255, 255);
				new String:nextAttack[4];
				FloatToString(nextAttackFloat, nextAttack, 4);
				ShowSyncHudText(z, headsHUD, "%s", nextAttack);
			}
		}
		if (primaryWeapon == 412 /* The Overdose */ && Overdose && activeWeapon == 0)
		{
			new wepEnt2;
			if ((wepEnt2 = GetPlayerWeaponSlot(z, 1))!=-1)
			{
				if (IsValidEntity(wepEnt2)) // "is weapon a medigun" check from VSH
				{
					new String:s[64];
					GetEdictClassname(wepEnt2, s, sizeof(s));
					if (!strcmp(s,"tf_weapon_medigun"))
					{
						new Float:newSpeed = 320.0 + (32.0 * GetEntPropFloat(wepEnt2, Prop_Send, "m_flChargeLevel") / 1.0);
						if (GetEntPropFloat(z, Prop_Send, "m_flMaxspeed") != newSpeed) SetEntPropFloat(z, Prop_Send, "m_flMaxspeed", newSpeed);
					}
				}
			}
		}
		if (secondaryWeapon == 411 /* The Quick-Fix */ && QuickFix && activeWeapon == 1 && !arenaModeSetupTime && GetEntPropFloat(z, Prop_Send, "m_flMaxspeed") > 0.0)
		{
			if (GetHealingTarget(z) != -1 && GetEntPropFloat(GetHealingTarget(z), Prop_Send, "m_flMaxspeed") > 320.0)
			SetEntPropFloat(z, Prop_Send, "m_flMaxspeed", GetEntPropFloat(GetHealingTarget(z), Prop_Send, "m_flMaxspeed"));
			if ((GetHealingTarget(z) != -1 && GetEntPropFloat(GetHealingTarget(z), Prop_Send, "m_flMaxspeed") <= 320.0) || GetHealingTarget(z) == -1)
			SetEntPropFloat(z, Prop_Send, "m_flMaxspeed", 320.0);
		}
		if (primaryWeapon == 141 && EurekaCrits && !justRegenerated[z]) /* The Frontier Justice */ revengeCrits[z] = GetEntProp(z, Prop_Send, "m_iRevengeCrits");
		if (primaryWeapon != 141) revengeCrits[z] = 0;
		if (primaryWeapon == 594 && PhlogRegen && !justRegenerated[z]) /* The Phlogistinator */ phlog[z] = GetEntPropFloat(z, Prop_Send, "m_flRageMeter");
		if (primaryWeapon != 594) phlog[z] = 0.0;
		if (primaryWeapon == 56 && HuntsmanWater) /* The Huntsman */
		{
			new wepEnt2;
			wepEnt2 = GetPlayerWeaponSlot(z, 0);
			if (GetEntityFlags(z) & FL_INWATER && GetEntProp(wepEnt2, Prop_Send, "m_bArrowAlight") == 1) SetEntProp(wepEnt2, Prop_Send, "m_bArrowAlight", 0);
		}
		if (primaryWeapon == 402 && Bazaar) /* The Bazaar Bargain */
		{
			if (TF2_GetPlayerClass(z) != TFClass_Sniper || GetEntProp(z, Prop_Send, "m_iDecapitations") > 7)
			{
				SetHudTextParams(1.0, 1.0, 0.2, 255, 255, 255, 255);
				SetGlobalTransTarget(z);
				ShowSyncHudText(z, headsHUD, "%i Heads", GetEntProp(z, Prop_Send, "m_iDecapitations"));
			}
			if (IsPlayerAlive(z)) sniperHeads[z] = GetEntProp(z, Prop_Send, "m_iDecapitations");
		}
		if (primaryWeapon != 402 && Eyelander) sniperHeads[z] = 0;
		if (meleeWeapon == 132 && EyelanderOverflow) /* The Eyelander */
		{
			if (GetEntProp(z, Prop_Send, "m_iDecapitations") > 127)
			{
				SetHudTextParams(1.0, 1.0, 0.2, 255, 255, 255, 255);
				SetGlobalTransTarget(z);
				ShowSyncHudText(z, headsHUD, "%i Heads", GetEntProp(z, Prop_Send, "m_iDecapitations"));
			}
		}
		if (markedForDeath[z] > 0.0) markedForDeath[z] = (markedForDeath[z] - 0.1);
		if (markedForDeath[z] > 0.0 && (class == TFClass_Spy || meleeWeapon == 589)) 
		{
			if (TF2_IsPlayerInCondition(z, TFCond_Cloaked) && TF2_IsPlayerInCondition(z, TFCond_MarkedForDeath))
			{
				TF2_RemoveCondition(z, TFCond_MarkedForDeath);
				TF2_AddCondition(z, TFCond_CritCola, markedForDeath[z]);
			}
			if (!TF2_IsPlayerInCondition(z, TFCond_Cloaked) && TF2_IsPlayerInCondition(z, TFCond_CritCola))
			{
				TF2_RemoveCondition(z, TFCond_CritCola);
				TF2_AddCondition(z, TFCond_MarkedForDeath, markedForDeath[z]);
			}
		}
		if (class == TFClass_Spy || meleeWeapon == 589)
		{
			if (markedForDeath[z] < 0.1 && TF2_IsPlayerInCondition(z, TFCond_CritCola)) TF2_RemoveCondition(z, TFCond_CritCola);
			if (markedForDeath[z] < 0.1 && TF2_IsPlayerInCondition(z, TFCond_MarkedForDeath)) TF2_RemoveCondition(z, TFCond_MarkedForDeath);
		}
		if (class == TFClass_Spy)
		{
			if (TF2_IsPlayerInCondition(z, TFCond_Disguised) && YERIntelligence && GetEntProp(z, Prop_Send, "m_hItem") != -1) TF2_RemovePlayerDisguise(z);
		}
	}
	
	if (TFWeapon)
	{
		new String:oldValue[128];
		GetConVarString(FindConVar("bot_forcefireweapon"), oldValue, 128);
		if (StrContains(oldValue, "tf_weapon_", false) == -1 && StrContains(oldValue, "saxxy", false) == -1)
		{
			new String:newValue[128];
			Format(newValue, 128, "tf_weapon_%s", oldValue);
			SetConVarString(FindConVar("bot_forcefireweapon"), newValue);
		}
	}
	return Plugin_Handled;
}

public Action:SandvichTauntFix(Handle:timer, any:uid)
{
	new client = GetClientOfUserId(uid);
	if (!IsValidClient(client)) return Plugin_Handled;
	if (!IsPlayerAlive(client)) return Plugin_Handled;
	new activeWep = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	new idx = GetEntProp(activeWep, Prop_Send, "m_iItemDefinitionIndex");
	if (idx == 42) return Plugin_Handled;
	new HP = GetClientHealth(client), MaxHP = TF2_GetPlayerResourceData(client, TFResource_MaxHealth);
	if (HP >= MaxHP) return Plugin_Handled;
	new newHP = HP + 75;
	if (newHP > MaxHP) newHP = MaxHP;
	SetEntityHealth(client, newHP);
	return Plugin_Handled;
}

public Action:timer_Quartersecond(Handle:timer)
{
	if (!Enabled)
	{
		QuarterSecondTimer = INVALID_HANDLE;
		return Plugin_Stop;
	}
	for (new z = 1; z <= MaxClients; z++)
	{
		if (!IsClientInGame(z)) continue;
		isPlayingPomsonSound[z] = false;
		didTakeOwnTeleporter[z] = false;
		if (DeadRingerIndicator && IsPlayerAlive(z) && GetEntProp(z, Prop_Send, "m_bFeignDeathReady"))
		{
			if (!hasDeadRingerMessage[z])
			{
				QueryClientConVar(z, "r_drawviewmodel", ClientConVar_Viewmodels);
				if (IsMedieval()) QueryClientConVar(z, "tf_medieval_thirdperson", ClientConVar_ThirdPerson);
				if (GetEntProp(z, Prop_Send, "m_nForceTauntCam") > 0)
				{
					SetHudTextParams(1.0, 0.9, 0.3, 255, 255, 255, 255);
					ShowSyncHudText(z, drHUD, "Dead Ringer Active");
				}
			}
		}
		else if (hasDeadRingerMessage[z])
		{
			ClearSyncHud(z, drHUD);
			hasDeadRingerMessage[z] = false;
		}
	}
	MonoSpawns = 0;
	return Plugin_Continue;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (!Enabled) return Plugin_Continue;
	if (ManmelterAttacking)
	{
		if (TF2_GetClientActiveWeaponIndex(client) == 595 /* The Manmelter */ && buttons & IN_ATTACK2)
		{
			buttons &= ~IN_ATTACK;
			return Plugin_Changed;
		}
	}
	if (HeavyStun)
	{
		if (TF2_IsPlayerInCondition(client, TFCond_Dazed))
		{
			buttons &= ~IN_JUMP;
			if (GetPlayerWeaponSlot(client, TFWeaponSlot_Melee) == GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon"))
			{
				buttons &= ~IN_ATTACK;
				buttons &= ~IN_ATTACK2;
			}
		}
	}
	if (dontAttack[client] && buttons & IN_ATTACK)
	{
		buttons &= ~IN_ATTACK;
		return Plugin_Changed;
	}
	/*if (BotTaunts && IsFakeClient(client))
	{
		if (TF2_IsPlayerInCondition(client, TFCond_Taunting))
		{
			buttons &= ~IN_FORWARD;
			buttons &= ~IN_BACK;
			buttons &= ~IN_LEFT;
			buttons &= ~IN_RIGHT;
			buttons &= ~IN_JUMP;
			buttons &= ~IN_ATTACK;
			buttons &= ~IN_ATTACK2;
		}
	}*/
	return Plugin_Continue;
}

stock TF2_GetClientActiveWeaponIndex(client)
{
	new Ent = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (!IsValidEntity(Ent)) return -1;
	decl String:cls[25];
	GetEntityClassname(Ent, cls, sizeof(cls));
	if (StrContains(cls, "tf_weapon_", false) == 0) return GetEntProp(Ent, Prop_Send, "m_iItemDefinitionIndex");
	return -1;
}

public Action:Unattack(Handle:timer, any:uid)
{
	new client = GetClientOfUserId(uid);
	if (!IsValidClient(client)) return Plugin_Handled;
	CreateTimer(0.25, Reattack, uid);
	dontAttack[client] = true;
	return Plugin_Handled;
}

public Action:Reattack(Handle:timer, any:uid)
{
	new client = GetClientOfUserId(uid);
	if (!IsValidClient(client)) return Plugin_Handled;
	dontAttack[client] = false;
	return Plugin_Handled;
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

stock IsBoss(bool:bForceRecalc = false) /* unrelated to IsBoss(client) in Boss 1.2/FF2 */
{
	static found = false;
	static bIsBoss = false;
	if (bForceRecalc)
	{
		found = false;
		bIsBoss = false;
	}
	if (!found)
	{
		found = true;
		new iBB, iFF2, iVSH, iPH,
		Handle:BB = FindConVar("sm_boss_auto"), Handle:FF2 = FindConVar("ff2_enabled"),
		Handle:VSH = FindConVar("hale_enabled"), Handle:PH = FindConVar("ph_enable");
		if (BB != INVALID_HANDLE) iBB = GetConVarInt(BB);
		if (FF2 != INVALID_HANDLE) iFF2 = GetConVarInt(FF2);
		if (VSH != INVALID_HANDLE) iVSH = GetConVarInt(VSH);
		if (PH != INVALID_HANDLE) iPH = GetConVarInt(PH);
		if (iBB > 0 || iFF2 > 0 || iVSH > 0 || iPH > 0) bIsBoss = true;
	}
	return bIsBoss;
}

public ClientConVar_Viewmodels(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[])
{
	if (!IsClientInGame(client)) return;
	if (result != ConVarQuery_Okay) return;
	if (bool:StringToInt(cvarValue)) return;
	if (hasDeadRingerMessage[client]) return;
	hasDeadRingerMessage[client] = true;
	SetHudTextParams(1.0, 0.9, 1000.0, 255, 255, 255, 255);
	ShowSyncHudText(client, drHUD, "Dead Ringer Active");
}

public ClientConVar_ThirdPerson(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[])
{
	if (!IsClientInGame(client)) return;
	if (result != ConVarQuery_Okay) return;
	if (!bool:StringToInt(cvarValue)) return;
	if (hasDeadRingerMessage[client]) return;
	hasDeadRingerMessage[client] = true;
	SetHudTextParams(1.0, 0.9, 1000.0, 255, 255, 255, 255);
	ShowSyncHudText(client, drHUD, "Dead Ringer Active");
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!Enabled) return Plugin_Continue;
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new String:weapon[128];
	GetEventString(event, "weapon_logclassname", weapon, 128);
	new customkill = GetEventInt(event, "customkill");
	new deathflags = GetEventInt(event, "death_flags");
	if (StrEqual(weapon, "ubersaw", true) && customkill == 29 && Ubersaw) SetEventString(event, "weapon", "taunt_medic");
	if (StrEqual(weapon, "cow_mangler", true))
	{
		if (attacker == victim && customkill == 3 && CowMangler) SetEventInt(event, "customkill", 46);
	}
	if (deathflags & TF_DEATHFLAG_DEADRINGER) return Plugin_Continue;
	revengeCrits[victim] = 0;
	if (StrEqual(weapon, "world", true))
	{
		if (BostonBasher && attacker == victim && TF2_GetPlayerClass(victim) == TFClass_Scout)
		{
			if ((wepEnt = GetPlayerWeaponSlot(attacker, 2))!=-1)
			{
				wepIndex = GetEntProp(wepEnt, Prop_Send, "m_iItemDefinitionIndex");
				if (wepIndex == 325) /* The Boston Basher */ SetEventString(event, "weapon", "boston_basher");
				if (wepIndex == 452) /* The Three-Rune Blade */ SetEventString(event, "weapon", "scout_sword");
			}
		}
	}
	if (StrEqual(weapon, "tf_projectile_energy_ball", true) && CowManglerReflectIcon) SetEventString(event, "weapon", "deflect_rocket");
	if (Eyelander && IsValidClient(attacker) && (StrEqual(weapon, "sword", true) || StrEqual(weapon, "headtaker", true)
										|| StrEqual(weapon, "nessieclub", true) || StrEqual(weapon, "taunt_demoman", true)))
	{
		if ((wepEnt = GetPlayerWeaponSlot(attacker, 2))!=-1)
		{
			wepIndex = GetEntProp(wepEnt, Prop_Send, "m_iItemDefinitionIndex");
			if (wepIndex == 132 || wepIndex == 266 || wepIndex == 482) /* Double check to make sure it's an Eyelander, since Demoman taunt kills can be made with almost any melee */
			{
				if (sniperHeads[victim] > 0)
					SetEntProp(attacker, Prop_Send, "m_iDecapitations", (GetEntProp(attacker, Prop_Send, "m_iDecapitations") - sniperHeads[victim]));
			}
		}
	}
	return Plugin_Continue;
}

public Action:Event_Hurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!Enabled) return Plugin_Continue;
	new victim = GetClientOfUserId(GetEventInt(event, "userid")), victimPrimary;
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if ((wepEnt = GetPlayerWeaponSlot(victim, 0))!=-1) victimPrimary = GetEntProp(wepEnt, Prop_Send, "m_iItemDefinitionIndex");
	new custom = GetEventInt(event, "custom");
	new damage = GetEventInt(event, "damageamount");
	if (GetEventBool(event, "minicrit") && MiniCrits) SetEventBool(event, "allseecrit", false);
	if (custom == TF_CUSTOM_BACKSTAB && GetConVarInt(FindConVar("tf_weapon_criticals")) == 0 && Backstab)
	{
		SetEventInt(event, "damageamount", GetEventInt(event, "damageamount") * 3); /* Cosmetic change. Crit backstabs deal 6x victim's HP, non-crit deals 2x, this 'ramps' (not really) it to 6x */
		SetEventBool(event, "crit", true);
		EmitSoundToClient(victim, "weapons/knife_swing_crit.wav");
		EmitSoundToClient(attacker, "weapons/knife_swing_crit.wav");
		rand = GetRandomInt(1,3);
		if (rand == 1) EmitSoundToClient(victim, "player/crit_received1.wav");
		if (rand == 2) EmitSoundToClient(victim, "player/crit_received2.wav");
		if (rand == 3) EmitSoundToClient(victim, "player/crit_received3.wav");
		new meleeWeapon;
		if ((wepEnt = GetPlayerWeaponSlot(attacker, 2))!=-1) meleeWeapon = GetEntProp(wepEnt, Prop_Send, "m_iItemDefinitionIndex");
		if (meleeWeapon == 4 || meleeWeapon == 194 || meleeWeapon == 665)
			SetViewmodelAnimation(attacker, 6);
		if (meleeWeapon == 225 || meleeWeapon == 356 || meleeWeapon == 461 || meleeWeapon == 574 || meleeWeapon == 649)
			SetViewmodelAnimation(attacker, 11);
		if (meleeWeapon == 423) SetViewmodelAnimation(attacker, 11);
		if (meleeWeapon == 638) SetViewmodelAnimation(attacker, 27);
		if (meleeWeapon == 727) SetViewmodelAnimation(attacker, 37);
	}
	if (TF2_IsPlayerInCondition(victim, TFCond_Ubercharged) && (GetEventBool(event, "crit") || GetEventBool(event, "minicrit")) && UberCrits)
	{
		SetEventBool(event, "crit", false);
		SetEventBool(event, "minicrit", false);
	}
	if (custom == TF_CUSTOM_TAUNT_GRENADE && victim == attacker)
	{
		if ((TF2_IsPlayerInCondition(victim, TFCond_Ubercharged) && UberCupcake) || (victimPrimary == 237 && JumperCupcake))
			CreateTimer(0.1, Explode, victim);
	}
	if (attacker != 0)
	{
		if ((wepEnt = GetPlayerWeaponSlot(attacker, 2))!=-1)
		{
			wepIndex = GetEntProp(wepEnt, Prop_Send, "m_iItemDefinitionIndex");
			if (wepIndex == 355 /* The Fan o'War */ && CloakedForDeath)
			{
				markedForDeath[victim] = 15.0;
			}
		}
	}
	if ((wepEnt = GetPlayerWeaponSlot(victim, 1))!=-1)
	{
		wepIndex = GetEntProp(wepEnt, Prop_Send, "m_iItemDefinitionIndex");
		if (wepIndex == 226 /* The Battalion's Backup */ && attacker == 0 && GetEntPropEnt(victim, Prop_Send, "m_bRageDraining") == 0 && BattalionsBackup)
		{
			new Float:newRage = (GetEntPropFloat(victim, Prop_Send, "m_flRageMeter") - (damage / 3.5));
			if (newRage < 0.0) newRage = 0.0;
			SetEntPropFloat(victim, Prop_Send, "m_flRageMeter", newRage);
		}
	}
	if (attacker != 0 && custom == TF_CUSTOM_PLASMA)
	{
		if (TF2_GetPlayerClass(victim) == TFClass_Spy && TF2_IsPlayerInCondition(victim, TFCond_Cloaked) && PomsonSound)
		{
			if (!isPlayingPomsonSound[victim]) EmitSoundToClient(victim, "weapons/drg_pomson_drain_01.wav");
			isPlayingPomsonSound[victim] = true;
		}
	}
	if (attacker != 0 && (wepEnt = GetPlayerWeaponSlot(attacker, 2))!=-1)
	{
		wepIndex = GetEntProp(wepEnt, Prop_Send, "m_iItemDefinitionIndex");
		if (wepIndex == 232 /* The Bushwacka */ && Bushwacka) SetEventBool(event, "allseecrit", false); /* That's literally all you have to do to fix this, apparently. */
	}
	if (TF2_GetPlayerClass(victim) == TFClass_Spy)
	{
		if (DeadRingerTaunt && GetEntPropEnt(victim, Prop_Send, "m_bFeignDeathReady") == 1 && TF2_IsPlayerInCondition(victim, TFCond_Taunting))
		{
			TF2_RemoveCondition(victim, TFCond_Taunting);
			TF2_AddCondition(victim, TFCond_DeadRingered, 6.5);
			new Handle:fakeEvent = CreateEvent("player_death", true);
			SetEventInt(fakeEvent, "userid", GetClientUserId(victim));
			SetEventInt(fakeEvent, "attacker", GetClientUserId(attacker));
			SetEventInt(fakeEvent, "weaponid", GetEventInt(event, "weaponid"));
			SetEventInt(fakeEvent, "death_flags", TF_DEATHFLAG_DEADRINGER);
			FireEvent(fakeEvent);
			
		}
	}
	return Plugin_Continue;
}

public Action:Explode(Handle:timer, any:uid)
{
	new client = GetClientOfUserId(uid);
	if (!IsValidClient(client)) return Plugin_Handled;
	FakeClientCommand(client, "explode");
	return Plugin_Handled;
}

public Action:Event_Brofist_Start(Handle:event, const String:name[], bool:dontBroadcast) /* Fixes an exploit introduced by the Dead Ringer Taunt fix that allows Spies with the highfive taunt */
{																						/*	to move around while in thirdperson/highfive mode, and highfive themselves */
	if (!Enabled) return Plugin_Continue;
	if (!DeadRingerTaunt) return Plugin_Continue;
	new initiator	= GetEventInt(event, "entindex");
	if (TF2_GetPlayerClass(initiator) == TFClass_Spy && (wepEnt = GetPlayerWeaponSlot(initiator, 4))!=-1)
	{
		wepIndex = GetEntProp(wepEnt, Prop_Send, "m_iItemDefinitionIndex");
		if (wepIndex == 59) /* The Ded Ringer */ SetEntPropEnt(initiator, Prop_Send, "m_bFeignDeathReady", 0);
	}
	return Plugin_Continue;
}

public Action:Event_NpcHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "attacker_player"));
	if (!IsValidClient(client)) return Plugin_Continue;
	new damage = GetEventInt(event, "damageamount");
	new weapon = GetEventInt(event, "weaponid");
	new bool:crit = GetEventBool(event, "crit");
	if (crit && NPCCritSounds)
	{
		rand = GetRandomInt(1,5);
		new String:sound[128];
		if (rand == 1) Format(sound, 128, "player/crit_hit.wav");
		if (rand != 1) Format(sound, 128, "player/crit_hit%i.wav", rand);
		EmitSoundToClient(client, sound);
		rand = -1;
	}
	if (!NPCBlackBox) return Plugin_Continue;
	if (damage == 90 || damage == 180 || damage == 270 || weapon == 22)
	{
		if ((wepEnt = GetPlayerWeaponSlot(client, 0))!=-1)
		{
			wepIndex = GetEntProp(wepEnt, Prop_Send, "m_iItemDefinitionIndex");
			if (wepIndex == 228) /* The Black Box */ HealPlayer(client, 15, 0, 2);
		}
	}
	if (weapon == 20 || damage == 10 || damage == 30)
	{
		if ((wepEnt = GetPlayerWeaponSlot(client, 0))!=-1)
		{
			wepIndex = GetEntProp(wepEnt, Prop_Send, "m_iItemDefinitionIndex");
			if (wepIndex == 36) /* The Blutsauger */ HealPlayer(client, 3, 0, 2);
		}
	}
	if ((wepEnt = GetPlayerWeaponSlot(client, 0))!=-1)
	{
		wepIndex = GetEntProp(wepEnt, Prop_Send, "m_iItemDefinitionIndex");
		if (wepIndex == 527 /* The Widowmaker */ && damage > 4)
		{
			new iOffset = FindDataMapOffs(client, "m_iAmmo") + (3 * 4);
			if (iOffset != -1)
			{
				new iNewMetal = damage + (GetEntData(client, iOffset));
				if (iNewMetal <= 200) SetEntData(client, iOffset, iNewMetal, 4, true);
				if (iNewMetal > 200) SetEntData(client, iOffset, 200, 4, true);
			}
		}
	}
	if (weapon == 11)
	{
		if ((wepEnt = GetPlayerWeaponSlot(client, 2))!=-1)
		{
			wepIndex = GetEntProp(wepEnt, Prop_Send, "m_iItemDefinitionIndex");
			if (wepIndex == 37 /* The Ubersaw */)
			{
				SetEntPropFloat(GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary), Prop_Send, "m_flChargeLevel", GetEntPropFloat(GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary), Prop_Send, "m_flChargeLevel") + 0.25);
				if (GetEntPropFloat(GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary), Prop_Send, "m_flChargeLevel") > 1.0) SetEntPropFloat(GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary), Prop_Send, "m_flChargeLevel", 1.0);
			}
		}
	}
	if (weapon == 43)
	{
		if ((wepEnt = GetPlayerWeaponSlot(client, 0))!=-1)
		{
			wepIndex = GetEntProp(wepEnt, Prop_Send, "m_iItemDefinitionIndex");
			if (wepIndex == 224 /* L'Etranger */) SetEntDataFloat(client, FindSendPropInfo("CTFPlayer", "m_flCloakMeter"), (GetEntDataFloat(client, FindSendPropInfo("CTFPlayer", "m_flCloakMeter")) + 15.0));
		}
	}
	if (!GetEntProp(client, Prop_Send, "m_bRageDraining") && NPCRage)
	{
		if ((wepEnt = GetPlayerWeaponSlot(client, 0))!=-1)
		{
			if (weapon == 25 || weapon == 58 || weapon == 84)
			{
				wepIndex = GetEntProp(wepEnt, Prop_Send, "m_iItemDefinitionIndex");
				new Float:Rage = GetEntPropFloat(client, Prop_Send, "m_flRageMeter"), Float:dmg = float(damage);
				if (wepIndex == 594) Rage += (dmg/225)*100;
				if (Rage > 100.0) Rage = 100.0;
				if (wepIndex == 594)
					SetEntPropFloat(client, Prop_Send, "m_flRageMeter", Rage);
			}
		}
		if ((wepEnt = GetPlayerWeaponSlot(client, 1))!=-1)
		{
			wepIndex = GetEntProp(wepEnt, Prop_Send, "m_iItemDefinitionIndex");
			new Float:Rage = GetEntPropFloat(client, Prop_Send, "m_flRageMeter"), Float:dmg = float(damage);
			if (wepIndex == 129) Rage += (dmg/600)*100;
			if (wepIndex == 354) Rage += (dmg/480)*100;
			if (Rage > 100.0) Rage = 100.0;
			if (wepIndex == 129 || wepIndex == 354)
				SetEntPropFloat(client, Prop_Send, "m_flRageMeter", Rage);
		}
	}
		
	
	return Plugin_Continue;	
}

stock HealPlayer(client, healing, overheal = 0, visual = 1)
{ /* OVERHEAL: 0=No  1=Yes, 150%  2=Unlimited      VISUAL: 0=No  1=Yes, if healing successful  2=Yes, always */
	if (!IsValidClient(client)) return -1;
	if (!IsPlayerAlive(client)) return -1;
	new HP = GetClientHealth(client), MaxHP = TF2_GetPlayerResourceData(client, TFResource_MaxHealth);
	if (visual == 2) ShowHealing(client, healing);
	if (HP >= MaxHP && overheal == 0) return HP;
	HP += healing;
	if (overheal == 0 && HP > MaxHP) HP = MaxHP;
	if (overheal == 1 && HP > MaxHP * RoundFloat(1.5)) HP = MaxHP * RoundFloat(1.5);
	SetEntityHealth(client, HP);
	if (visual == 1) ShowHealing(client, healing);
	return HP;
}

stock ShowHealing(client, healing)
{
	new Handle:event = CreateEvent("player_healonhit");
	SetEventInt(event, "entindex", client);
	SetEventInt(event, "amount", healing);
	FireEvent(event);
}

stock GetMedicCount(client, quickfix = true)
{
	new count = 0;
	for (new z = 1; z <= MaxClients; z++)
	{
		if (!IsClientInGame(z)) continue;
		if (!quickfix)
		{
			new secondaryWeapon;
			if ((wepEnt = GetPlayerWeaponSlot(z, 1))!=-1) secondaryWeapon = GetEntProp(wepEnt, Prop_Send, "m_iItemDefinitionIndex");
			if (secondaryWeapon == 411) continue;
		}
		if (GetHealingTarget(z) == client) count += 1;
	}
	return count;
}

public Action:Command_destroy(client, const String:command[], args)
{
	if (!Enabled || !EurekaTaunt) return Plugin_Continue;
	if (!IsValidClient(client)) return Plugin_Continue;
	if (!IsPlayerAlive(client)) return Plugin_Continue;
	new meleeWeapon;
	if ((wepEnt = GetPlayerWeaponSlot(client, 2))!=-1) meleeWeapon = GetEntProp(wepEnt, Prop_Send, "m_iItemDefinitionIndex");
	if (meleeWeapon == 589 /* The Eureka Effect */ && TF2_IsPlayerInCondition(client, TFCond_Taunting)) return Plugin_Handled;
	return Plugin_Continue;
}

public Action:Command_voicemenu(client, const String:command[], args)
{
	if (!Enabled || !MedicCalls) return Plugin_Continue;
	if (!IsValidClient(client)) return Plugin_Continue;
	if (!IsPlayerAlive(client)) return Plugin_Continue;
	new meleeWeapon;
	if ((wepEnt = GetPlayerWeaponSlot(client, 2))!=-1) meleeWeapon = GetEntProp(wepEnt, Prop_Send, "m_iItemDefinitionIndex");
	if (meleeWeapon != 128 /* The Equalizer */ && meleeWeapon != 775 /* Escape Plan */) return Plugin_Continue;
	if (wepEnt != GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon")) return Plugin_Continue;
	new String:arg1[4];
	GetCmdArgString(arg1, sizeof(arg1));
	if (!StrEqual(arg1, "0 0")) return Plugin_Continue;
	return Plugin_Handled;
}

public OnClientDisconnect(client)
{
	revengeCrits[client] = 0;
	phlog[client] = 0.0;
	IsTaunting[client] = false;
	dontAttack[client] = false;
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!Enabled) return Plugin_Continue;
	for (new z = 1; z <= MaxClients; z++)
	{
		revengeCrits[z] = 0;
		phlog[z] = 0.0;
	}
	new Ent = -1;
	while ((Ent = FindEntityByClassname(Ent, "tf_logic_arena")) != -1)
	{
		arenaModeSetupTime = true;
	}
	CreateTimer(GetConVarFloat(FindConVar("tf_arena_preround_time")), Timer_ArenaStart);
	return Plugin_Continue;
}

public Action:Timer_ArenaStart(Handle:timer)
{
	if (!Enabled) return Plugin_Handled;
	new Ent = -1;
	while ((Ent = FindEntityByClassname(Ent, "tf_logic_arena")) != -1)
	{
		arenaModeSetupTime = false;
		if (ArenaMove)
		{
			for (new z = 1; z <= MaxClients; z++)
			{
				if (!IsClientInGame(z)) continue;
				if (GetClientTeam(z) <= _:TFTeam_Spectator) continue;
				if (ArenaMove && GetEntityMoveType(z) != MOVETYPE_NOCLIP) SetEntityMoveType(z, MOVETYPE_WALK);
				if (ArenaRegen && !IsBoss()) TF2_RegeneratePlayer(z);
			}
		}
	}
	return Plugin_Handled;
}

public Action:Event_Teleport(Handle:event, const String:name[], bool:dontBroadcast) /* WAAAARP ZOOOONE! */
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new builder = GetClientOfUserId(GetEventInt(event, "builderid"));
	
	if (client == builder) didTakeOwnTeleporter[client] = true;
	
	return Plugin_Continue;	
}

public Action:Event_Inventory(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	justRegenerated[client] = true;
	if ((wepEnt = GetPlayerWeaponSlot(client, 2))!=-1 && SpyCicleSpawn)
	{
		if (IsValidEntity(wepEnt) && GetEntProp(wepEnt, Prop_Send, "m_iItemDefinitionIndex") == 649)
			SetEntPropFloat(wepEnt, Prop_Send, "m_flKnifeMeltTimestamp", GetGameTime() - GetEntPropFloat(wepEnt, Prop_Send, "m_flKnifeRegenerateDuration"));
	}
	CreateTimer(0.1, Timer_LateRegen, GetClientUserId(client));
	return Plugin_Continue;	
}

public Action:Timer_LateRegen(Handle:timer, any:uid)
{
	new client = GetClientOfUserId(uid);
	if (!IsValidClient(client)) return Plugin_Handled;
	justRegenerated[client] = false;
	new primaryWeapon, secondaryWeapon, TFClassType:class = TF2_GetPlayerClass(client);
	if ((wepEnt = GetPlayerWeaponSlot(client, 0))!=-1) primaryWeapon = GetEntProp(wepEnt, Prop_Send, "m_iItemDefinitionIndex");
	if ((wepEnt = GetPlayerWeaponSlot(client, 1))!=-1) secondaryWeapon = GetEntProp(wepEnt, Prop_Send, "m_iItemDefinitionIndex");
	if (EurekaCrits && primaryWeapon == 141) /* The Frontier Justice */ SetEntProp(client, Prop_Send, "m_iRevengeCrits", revengeCrits[client]);
	if (PhlogRegen && primaryWeapon == 594) /* The Phlogistinator */ SetEntPropFloat(client, Prop_Send, "m_flRageMeter", phlog[client]);
	if ((secondaryWeapon == 129 || secondaryWeapon == 226 || secondaryWeapon == 354) && BannerSwitch)
	{
		if (secondaryWeapon != equippedBanner[client]) SetEntPropFloat(client, Prop_Send, "m_flRageMeter", 0.0);
		equippedBanner[client] = secondaryWeapon;
	}
	if (MarkedForDeathResupply) TF2_RemoveCondition(client, TFCond_MarkedForDeath);
	if (primaryWeapon == 441) hasCowMangler[client] = true;
	if (hasCowMangler[client] && primaryWeapon != 441 && CowManglerSlowdown)
	{
		TF2_RemoveCondition(client, TFCond_Slowed);
		hasCowMangler[client] = false;
		ClientCommand(client, "slot2");
	}
	if (class == TFClass_Spy && GetClientHealth(client) > 185 && TF2_GetPlayerResourceData(client, TFResource_MaxHealth) < 200 && Kunai) SetEntityHealth(client, 125);
	return Plugin_Handled;
}

public Action:Event_Team(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!Enabled) return Plugin_Continue;
	if (!Crossbow) return Plugin_Continue;
	new client = GetClientOfUserId(GetEventInt(event, "userid")), Ent = -1;
	while ((Ent = FindEntityByClassname(Ent, "tf_projectile_healing_bolt")) != -1)
	{
		if (IsValidEntity(Ent))
		{
			if (client == GetEntPropEnt(Ent, Prop_Send, "m_hOwnerEntity"))
				AcceptEntityInput(Ent, "Kill");
		}
	}
	return Plugin_Continue;
}

public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
	if (!Enabled) return Plugin_Continue;
	if (CritJarate && StrContains(weaponname, "tf_weapon_jar", false) == 0)
	{
		result = false;
		return Plugin_Changed;
	}
	if (ScorchTaunt && StrEqual(weaponname, "tf_weapon_flaregun", false) && TF2_IsPlayerInCondition(client, TFCond_Taunting))
	{
		PrecacheSound("weapons/doom_flare_gun.wav");
		EmitSoundToClient(client, "weapons/doom_flare_gun.wav");
		return Plugin_Changed;
	}
	else return Plugin_Continue;
}

stock GetHealingTarget(client) /* from VS Saxton Hale Mode */
{
	new String:s[64];
	new medigun = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
	if (medigun <= MaxClients || !IsValidEdict(medigun))
	return -1;
	GetEdictClassname(medigun, s, sizeof(s));
	if (strcmp(s, "tf_weapon_medigun", false) == 0)
	{
		if (GetEntProp(medigun, Prop_Send, "m_bHealing"))
		return GetEntPropEnt(medigun, Prop_Send, "m_hHealingTarget");
	}
	return -1;
}

public Action:SoundHook(clients[64], &numClients, String:sound[PLATFORM_MAX_PATH], &client, &channel, &Float:volume, &level, &pitch, &flags)
{
	if (!Enabled) return Plugin_Continue;
	if (!IsValidClient(client)) return Plugin_Continue;
	new TFClassType:class = TF2_GetPlayerClass(client);
	if (StrContains(sound, "buff_banner_horn", false) != -1 || StrContains(sound, "TF_conch", false) != -1 && BannerExploit)
		CreateTimer(2.5, Unattack, GetClientOfUserId(client));
	if (!IsPlayerAlive(client) && DedTaunts)
	{
		if (StrContains(sound, "scout_autocappedintelligence02", false) != -1 || StrContains(sound, "scout_beingshotinvincible15", false) != -1 ||
StrContains(sound, "scout_cheers01", false) != -1 || StrContains(sound, "scout_specialcompleted02", false) != -1 ||
StrContains(sound, "scout_specialcompleted03", false) != -1 || StrContains(sound, "scout_taunts01", false) != -1 ||
StrContains(sound, "scout_thanksfortheheal01", false) != -1 || StrContains(sound, "soldier_taunts01", false) != -1 ||
StrContains(sound, "soldier_specialcompleted01", false) != -1 || StrContains(sound, "soldier_specialcompleted04", false) != -1 ||
StrContains(sound, "soldier_cheers05", false) != -1 || StrContains(sound, "soldier_pickaxetaunt04", false) != -1 ||
StrContains(sound, "soldier_positivevocalization01", false) != -1 || StrContains(sound, "soldier_kaboomalts03", false) != -1 ||
StrContains(sound, "pyro_headright01", false) != -1 || StrContains(sound, "pyro_highfive", false) != -1 ||
StrContains(sound, "demoman_laughshort03", false) != -1 || StrContains(sound, "taunt_bottle_ah", false) != -1 ||
StrContains(sound, "heavy_goodjob03", false) != -1 || StrContains(sound, "heavy_specialcompleted-assistedkill01", false) != -1 ||
StrContains(sound, "heavy_generic01", false) != -1 || StrContains(sound, "heavy_taunts01", false) != -1 ||
StrContains(sound, "sandwicheat09", false) != -1 || StrContains(sound, "heavy_niceshot02", false) != -1 ||
StrContains(sound, "heavy_cheers02", false) != -1 || StrContains(sound, "engineer_cheers02", false) != -1 ||
StrContains(sound, "medic_cheers01", false) != -1 || StrContains(sound, "sniper_battlecry03", false) != -1 ||
StrContains(sound, "sniper_battlecry05", false) != -1 || StrContains(sound, "sniper_goodjob03", false) != -1 ||
StrContains(sound, "spy_battlecry04", false) != -1 || StrContains(sound, "spy_specialcompleted07", false) != -1 ||
StrContains(sound, "spy_jeers02", false) != -1 || StrContains(sound, "spy_specialcompleted11", false) != -1 ||
StrContains(sound, "spy_taunts09", false) != -1 || StrContains(sound, "spy_negativevocalization", false) != -1 ||
StrContains(sound, "spy_goodjob02", false) != -1 || StrContains(sound, "spy_laughshort", false) != -1 ||
StrContains(sound, "spy_autocappedintelligence03", false) != -1 || StrContains(sound, "spy_highfive", false) != -1)
		return Plugin_Stop; /* blegh... */
	}
	if (class == TFClass_Heavy && NEWWEAPON)
	{
		new primaryWeapon;
		wepEnt = GetPlayerWeaponSlot(client, 0);
		if (wepEnt != -1)
		{
			primaryWeapon = GetEntProp(wepEnt, Prop_Send, "m_iItemDefinitionIndex");
			if (primaryWeapon == 424 /* Tomislav */ &&
			wepEnt == GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon") &&
			StrContains(sound, "specialweapon", false) != -1) return Plugin_Stop;
		}
	}
	if (StrContains(sound, "weapons/demo_charge_windup", false) != -1 && CharginTarge && volume == 1.0 && !TF2_IsPlayerInCondition(client, TFCond_Kritzkrieged) && !TF2_IsPlayerInCondition(client, TFCond_HalloweenCritCandy))
	{
		new String:newSound[128];
		Format(newSound, 128, "weapons/demo_charge_windup%i.wav", GetRandomInt(1,3));
		PrecacheSound(newSound);
		EmitSound(clients, numClients, newSound, client, SNDCHAN_AUTO, _, _, 0.5);
		return Plugin_Stop;
	}
	if (StrContains(sound, "engineer_thanksfortheteleporter", false) != -1 && ThanksForRide)
	{
		if (didTakeOwnTeleporter[client]) return Plugin_Stop;
	}
	if (StrContains(sound, "quake_ammo_pickup_remastered", false) != -1 && Original)
	{
		PrecacheSound(sound);
		EmitSoundToClient(client, sound);
	}
	if (volume > 0.99996) return Plugin_Continue; // should filter out most playsounds plugins
	if (StrContains(sound, "vo/spy_jaratehit", false) != -1 && !TF2_IsPlayerInCondition(client, TFCond_Jarated) && MadMilk)
	{ /* http://wiki.teamfortress.com/w/images/4/49/Spy_jaratehit01_fr.wav */
		if (rand == -1) rand = GetRandomInt(1,6);
		if (rand == 1) Format(sound, 128, "vo/spy_jaratehit01.wav");
		if (rand == 2) Format(sound, 128, "vo/spy_jaratehit03.wav");
		if (rand == 3) Format(sound, 128, "vo/spy_jaratehit04.wav");
		if (rand == 4) Format(sound, 128, "vo/spy_jaratehit06.wav");
		if (rand == 5) Format(sound, 128, "vo/spy_negativevocalization09.wav");
		if (rand == 6) Format(sound, 128, "vo/spy_autodejectedtie03.wav");
		PrecacheSound(sound);
		return Plugin_Changed;
	}
	if (StrContains(sound, "vo/taunts/spy_highfive01", false) != -1 && HighFive) /* slap my ass */
	{
		if (rand == -1) rand = GetRandomInt(1,14);
		if (rand < 10) Format(sound, 128, "vo/taunts/spy_highfive0%i.wav", rand);
		if (rand > 9) Format(sound, 128, "vo/taunts/spy_highfive%i.wav", rand);
		PrecacheSound(sound);
		return Plugin_Changed;
	}
	if (StrContains(sound, "vo/taunts/spy_highfive_success", false) != -1 && HighFive)
	{
		if (!IFeelGood)
		{
			if (rand == -1) rand = GetRandomInt(1,5);
			Format(sound, 128, "vo/taunts/spy_highfive_success0%i.wav", rand);
			PrecacheSound(sound);
			return Plugin_Changed;
		}
		if (IFeelGood)
		{
			if (rand == -1) rand = GetRandomInt(1,6);
			if (rand != 6) Format(sound, 128, "vo/taunts/spy_highfive_success0%i.wav", rand);
			if (rand == 6) Format(sound, 128, "vo/taunts/spy_feelgood01.wav");
			PrecacheSound(sound);
			return Plugin_Changed;
		}
	}
	if (StrContains(sound, "vo/taunts/pyro_highfive01", false) != -1 && HighFive)
	{
		if (rand == -1) rand = GetRandomInt(1,2);
		Format(sound, 128, "vo/taunts/pyro_highfive0%i.wav", rand);
		PrecacheSound(sound);
		return Plugin_Changed;
	}
	if (StrContains(sound, "vo/taunts/pyro_highfive_success02", false) != -1 && HighFive)
	{
		Format(sound, 128, "vo/taunts/pyro_highfive_success0%i.wav", GetRandomInt(1,2));
		PrecacheSound(sound);
		return Plugin_Changed;
	}
	if (StrContains(sound, "vo/spy_thanksfortheheal", false) != -1 && IFeelGood)
	{
		if (rand == -1) rand = GetRandomInt(1,4);
		if (rand != 4) return Plugin_Continue;
		Format(sound, 128, "vo/taunts/spy_feelgood01.wav"); /* GOOD LORD */
		PrecacheSound(sound);
		return Plugin_Changed;
	}
	if (StrContains(sound, "vo/demoman_specialcompleted-assistedkill02", false) != -1 && DidntNeedYourHelp)
	{
		if (rand == -1) rand = GetRandomInt(1,2);
		if (rand == 1) Format(sound, 128, "vo/demoman_specialcompleted-assistedkill01.wav");
		if (rand == 2) Format(sound, 128, "vo/demoman_autocappedintelligence03.wav");
		PrecacheSound(sound);
		return Plugin_Changed;
	}
	if (StrContains(sound, "vo/sniper_incoming04", false) != -1 && Incoming)
	{
		Format(sound, 128, "vo/sniper_incoming0%i.wav", GetRandomInt(1,3));
		PrecacheSound(sound);
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action:Event_Item(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!Enabled || !CraftMetal) return Plugin_Continue;
	new idx = GetEventInt(event, "itemdef"), method = GetEventInt(event, "method");
	if ((idx == 5000 || idx == 5001 || idx == 5002) && method == 1 && !GetEventBool(event, "isfake")) return Plugin_Handled;
	return Plugin_Continue;
}

public Action:Event_Healing(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!Enabled || !EscapePlanHealing) return Plugin_Continue;
	new patient = GetClientOfUserId(GetEventInt(event, "patient")), healer = GetClientOfUserId(GetEventInt(event, "healer")), amount = GetEventInt(event, "amount");
	if (!IsValidClient(patient) || !IsValidClient(healer)) return Plugin_Continue;
	new meleeWep = GetPlayerWeaponSlot(patient, TFWeaponSlot_Melee);
	if (!IsValidEntity(meleeWep)) return Plugin_Continue;
	if (meleeWep != GetEntPropEnt(patient, Prop_Send, "m_hActiveWeapon")) return Plugin_Continue;
	new idx = GetEntProp(meleeWep, Prop_Send, "m_iItemDefinitionIndex");
	if (idx != 128 && idx != 775) return Plugin_Continue;
	new activeWep = GetEntPropEnt(healer, Prop_Send, "m_hActiveWeapon");
	if (!IsValidEntity(activeWep)) return Plugin_Continue;
	idx = GetEntProp(activeWep, Prop_Send, "m_iItemDefinitionIndex");
	if (idx != 305) return Plugin_Continue;
	SetEntityHealth(patient, GetClientHealth(patient) - amount);
	return Plugin_Stop;
}

public Action:Event_ErectingASapper(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!Enabled || !EscapePlanHealing) return Plugin_Continue;
	new sapper = GetEventInt(event, "index"), type = GetEventInt(event, "object");
	if (type != 3) return Plugin_Continue;
	new targetbuilding = GetEntPropEnt(sapper, Prop_Send, "m_hBuiltOnEntity");
	SetEntProp(targetbuilding, Prop_Send, "m_bDisabled", 1);
	return Plugin_Continue;
}

public Action:UserMsg_SpawnBird(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	if (!Enabled || !WaterDoves) return Plugin_Continue;
	new Float:Pos[3];
	BfReadVecCoord(bf, Pos);
	new ClosestPlayer, Float:ClosestDist;
	for (new z = 1; z <= MaxClients; z++)
	{
		if (!IsValidClient(z)) continue;
		if (!IsPlayerAlive(z)) continue;
		decl Float:ClientPos[3];
		GetEntPropVector(z, Prop_Send, "m_vecOrigin", ClientPos);
		new Float:Dist = GetVectorDistance(Pos, ClientPos);
		if (ClosestPlayer > 0 && Dist > ClosestDist) continue;
		ClosestPlayer = z, ClosestDist = Dist;
	}
	if (IsValidClient(ClosestPlayer))
	{
		if (GetEntityFlags(ClosestPlayer) & FL_INWATER) return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action:Event_NpcSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!Enabled || !NPCSounds) return Plugin_Continue;
	MonoSpawns++;
	if (MonoSpawns > 1) return Plugin_Continue;
	EmitSoundToAll("ui/halloween_boss_summoned_fx.wav");
	return Plugin_Continue;
}

public Action:Event_NpcDed(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!Enabled || !NPCSounds) return Plugin_Continue;
	EmitSoundToAll("ui/halloween_boss_defeated_fx.wav");
	return Plugin_Continue;
}

public Action:Event_NpcEscaped(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!Enabled || !NPCSounds) return Plugin_Continue;
	EmitSoundToAll("ui/halloween_boss_escape.wav");
	return Plugin_Continue;
}

stock SetViewmodelAnimation(client, Sequence)
{
	new Ent = -1;
	while ((Ent = FindEntityByClassname(Ent, "tf_viewmodel")) != -1)
	{
		if (GetEntPropEnt(Ent, Prop_Send, "m_hOwner") == client)
			SetEntProp(Ent, Prop_Send, "m_nSequence", Sequence);
	}
}

stock bool:IsValidClient(client)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	return true;
}

public CvarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	/* CVARS (5) */
	if (convar == cvarEnabled)
	{
		Enabled = bool:StringToInt(newValue);
		if (Enabled)
		{
			if (NotVeryMuchTimer != INVALID_HANDLE) KillTimer(NotVeryMuchTimer);
			NotVeryMuchTimer = CreateTimer(0.15, timer_NotVeryMuchOfASecond, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			if (QuarterSecondTimer != INVALID_HANDLE) KillTimer(QuarterSecondTimer);
			QuarterSecondTimer = CreateTimer(0.25, timer_Quartersecond, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	else if (convar == cvarBazaar) Bazaar = bool:StringToInt(newValue);
	else if (convar == cvarUbersaw) Ubersaw = bool:StringToInt(newValue);
	else if (convar == cvarBackstab) Backstab = bool:StringToInt(newValue);
	else if (convar == cvarManmelterTimer) ManmelterTimer = bool:StringToInt(newValue);
	else if (convar == cvarCowMangler) CowMangler = bool:StringToInt(newValue);
	else if (convar == cvarOverdose) Overdose = bool:StringToInt(newValue);
	else if (convar == cvarQuickFix) QuickFix = bool:StringToInt(newValue);
	else if (convar == cvarKunai) Kunai = bool:StringToInt(newValue);
	else if (convar == cvarBushwacka) Bushwacka = bool:StringToInt(newValue);
	else if (convar == cvarYERIntelligence) YERIntelligence = bool:StringToInt(newValue);
	else if (convar == cvarDeadRingerTaunt) DeadRingerTaunt = bool:StringToInt(newValue);
	else if (convar == cvarBostonBasher) BostonBasher = bool:StringToInt(newValue);
	else if (convar == cvarBattalionsBackup) BattalionsBackup = bool:StringToInt(newValue);
	else if (convar == cvarCloakedForDeath) CloakedForDeath = bool:StringToInt(newValue);
	else if (convar == cvarTFWeapon) TFWeapon = bool:StringToInt(newValue);
	else if (convar == cvarMiniCrits) MiniCrits = bool:StringToInt(newValue);
	else if (convar == cvarUberJarate) UberJarate = bool:StringToInt(newValue);
	else if (convar == cvarMadMilk) MadMilk = bool:StringToInt(newValue);
	else if (convar == cvarHighFive) HighFive = bool:StringToInt(newValue);
	else if (convar == cvarIFeelGood) IFeelGood = bool:StringToInt(newValue);
	else if (convar == cvarCharginTarge) CharginTarge = bool:StringToInt(newValue);
	else if (convar == cvarDidntNeedYourHelp) DidntNeedYourHelp = bool:StringToInt(newValue);
	else if (convar == cvarIncoming) Incoming = bool:StringToInt(newValue);
	else if (convar == cvarPomsonSound) PomsonSound = bool:StringToInt(newValue);
	else if (convar == cvarCowManglerReflectIcon) CowManglerReflectIcon = bool:StringToInt(newValue);
	else if (convar == cvarDedTaunts) DedTaunts = bool:StringToInt(newValue);
	else if (convar == cvarNPCBlackBox) NPCBlackBox = bool:StringToInt(newValue);
	else if (convar == cvarNPCCritSounds) NPCCritSounds = bool:StringToInt(newValue);
	else if (convar == cvarArenaMove) ArenaMove = bool:StringToInt(newValue);
	else if (convar == cvarArenaRegen) ArenaRegen = bool:StringToInt(newValue);
//	else if (convar == cvarBotTaunts) BotTaunts = bool:StringToInt(newValue);
	else if (convar == cvarThanksForRide) ThanksForRide = bool:StringToInt(newValue);
	else if (convar == cvarOriginal) Original = bool:StringToInt(newValue);
	else if (convar == cvarDeadRingerIndicator) DeadRingerIndicator = bool:StringToInt(newValue);
	else if (convar == cvarEurekaCrits) EurekaCrits = bool:StringToInt(newValue);
	else if (convar == cvarEyelanderOverflow) EyelanderOverflow = bool:StringToInt(newValue);
	else if (convar == cvarPhlogRegen) PhlogRegen = bool:StringToInt(newValue);
	else if (convar == cvarHuntsmanWater) HuntsmanWater = bool:StringToInt(newValue);
	else if (convar == cvarSpyCicleSpawn) SpyCicleSpawn = bool:StringToInt(newValue);
	else if (convar == cvarBannerSwitch) BannerSwitch = bool:StringToInt(newValue);
	else if (convar == cvarUberCupcake) UberCupcake = bool:StringToInt(newValue);
	else if (convar == cvarUberCrits) UberCrits = bool:StringToInt(newValue);
	else if (convar == cvarMarkedForDeathResupply) MarkedForDeathResupply = bool:StringToInt(newValue);
	else if (convar == cvarCowManglerSlowdown) CowManglerSlowdown = bool:StringToInt(newValue);
	else if (convar == cvarCrossbow) Crossbow = bool:StringToInt(newValue);
	else if (convar == cvarCritJarate) CritJarate = bool:StringToInt(newValue);
	else if (convar == cvarDalokohsBar) DalokohsBar = bool:StringToInt(newValue);
	else if (convar == cvarEurekaTaunt) EurekaTaunt = bool:StringToInt(newValue);
	else if (convar == cvarNPCRage) NPCRage = bool:StringToInt(newValue);
	else if (convar == cvarNEWWEAPON) NEWWEAPON = bool:StringToInt(newValue);
	else if (convar == cvarCraftMetal) CraftMetal = bool:StringToInt(newValue);
	else if (convar == cvarScorchTaunt) ScorchTaunt = bool:StringToInt(newValue);
	else if (convar == cvarEscapePlanHealing) EscapePlanHealing = bool:StringToInt(newValue);
	else if (convar == cvarJumperCupcake) JumperCupcake = bool:StringToInt(newValue);
	else if (convar == cvarManmelterAttacking) ManmelterAttacking = bool:StringToInt(newValue);
	else if (convar == cvarMedicCalls) MedicCalls = bool:StringToInt(newValue);
	else if (convar == cvarSandvichTauntSwitch) SandvichTauntSwitch = bool:StringToInt(newValue);
	else if (convar == cvarBannerExploit) BannerExploit = bool:StringToInt(newValue);
	else if (convar == cvarWaterDoves) WaterDoves = bool:StringToInt(newValue);
	else if (convar == cvarHeavyStun) HeavyStun = bool:StringToInt(newValue);
	else if (convar == cvarNPCSounds) NPCSounds = bool:StringToInt(newValue);
}