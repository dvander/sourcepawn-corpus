#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

public Plugin:myinfo = {
	name = "TF2Fix",
	author = "MasterOfTheXP",
	description = "Fixes various glitches, bugs, and more in Team Fortress 2.",
	version = "1.2.3",
	url = "http://mstr.ca/"
};

/* CVARS (1) */
new Handle:cvarEnabled;
new Handle:cvarBazaar;
new Handle:cvarUbersaw;
new Handle:cvarBackstab;
new Handle:cvarManmelterTimer;
new Handle:cvarEyelander;
new Handle:cvarCowMangler;
new Handle:cvarOverdose;
new Handle:cvarQuickFix;
new Handle:cvarKunai;
new Handle:cvarBushwacka;
new Handle:cvarYERIntelligence;
new Handle:cvarDeadRingerTaunt;
new Handle:cvarBostonBasher;
new Handle:cvarBattalionsBackup;
new Handle:cvarCloakedForDeath;
new Handle:cvarTFWeapon;
new Handle:cvarMiniCrits;
new Handle:cvarUberJarate;
new Handle:cvarMadMilk;
new Handle:cvarHighFive;
new Handle:cvarIFeelGood;
new Handle:cvarLeeroyJenkins;
new Handle:cvarTeamworkIsForPussiesYouKnow;
new Handle:cvarIncoming;
new Handle:cvarPomson;
new Handle:cvarPomsonSound;
new Handle:cvarCowManglerReflectIcon;
new Handle:cvarDedTaunts;
new Handle:cvarNPCBlackBox;
new Handle:cvarNPCCritSounds;
new Handle:cvarArenaMove;
new Handle:cvarArenaRegen;
new Handle:cvarBotTaunts;
new Handle:cvarThanksForRide;
new Handle:cvarOriginal;
new Handle:cvarDeadRingerIndicator;
new Handle:cvarEurekaCrits;
new Handle:cvarEyelanderOverflow;
new Handle:cvarPhlogRegen;
new Handle:cvarHuntsmanWater;
new Handle:cvarSpyCicleSpawn;
new Handle:cvarBannerSwitch;
new Handle:cvarUberCupcake;
new Handle:cvarUberCrits;
new Handle:cvarEurekaMarkedForDeath;

/* HUD TEXT (1) */
new Handle:headsHUD;
new Handle:drHUD;

/* TIMERS */
new Handle:NotVeryMuchTimer;
new Handle:QuarterSecondTimer;

new Handle:hMaxHealth;

/* CVARS (2) */
new bool:Enabled = true;
new bool:Bazaar = true;
new bool:Ubersaw = true;
new bool:Backstab = true;
new bool:ManmelterTimer = true;
new bool:Eyelander = true;
new bool:CowMangler = true;
new bool:Overdose = true;
new bool:QuickFix = true;
new bool:Kunai = true;
new bool:Bushwacka = true;
new bool:YERIntelligence = true;
new bool:DeadRingerTaunt = true;
new bool:BostonBasher = true;
new bool:BattalionsBackup = true;
new bool:CloakedForDeath = true;
new bool:TFWeapon = true;
new bool:MiniCrits = true;
new bool:UberJarate = true;
new bool:MadMilk = true;
new bool:HighFive = true;
new bool:IFeelGood = true;
new bool:LeeroyJenkins = true; /* Named so because I love this mod, and this bug completely breaks it */
new bool:TeamworkIsForPussiesYouKnow = true;
new bool:Incoming = true;
new bool:Pomson = true;
new bool:PomsonSound = true;
new bool:CowManglerReflectIcon = true;
new bool:DedTaunts = true;
new bool:NPCBlackBox = true;
new bool:NPCCritSounds = true;
new bool:ArenaMove = true;
new bool:ArenaRegen = false;
new bool:BotTaunts = true;
new bool:ThanksForRide = true;
new bool:Original = true;
new bool:DeadRingerIndicator = true;
new bool:EurekaCrits = true;
new bool:EyelanderOverflow = true;
new bool:PhlogRegen = true;
new bool:HuntsmanWater = true;
new bool:SpyCicleSpawn = true;
new bool:BannerSwitch = true;
new bool:UberCupcake = true;
new bool:UberCrits = true;
new bool:EurekaMarkedForDeath = true;

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
	cvarEnabled = CreateConVar("sm_tf2fix_enabled","1","Enables/disables TF2Fix plugin.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarBazaar = CreateConVar("sm_tf2fix_bazaar","1","If on, Bazaar Bargain users who have more than 7 heads will see their real head count.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarUbersaw = CreateConVar("sm_tf2fix_ubersaw","1","If on, Ubersaw taunt kills display their unused icon.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarBackstab = CreateConVar("sm_tf2fix_backstab","1","If on, backstabs appear smoother on servers with random critical hits turned off.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarManmelterTimer = CreateConVar("sm_tf2fix_manmelter_timer","1","If on, Manmelter users get a timer in the bottom of their screen showing when they can fire again, since in most peoples' opinions, it's extremely hard to tell without a reload animation.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarEyelander = CreateConVar("sm_tf2fix_eyelander","1","If on, Eyelander kills on Bazaar Bargain Snipers won't steal that Sniper's heads.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarCowMangler = CreateConVar("sm_tf2fix_cowmangler_icon_suicide","1","If on, Cow Mangler afterburn suicides show the Cow Mangler kill icon.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarOverdose = CreateConVar("sm_tf2fix_overdose","1","If on, the Overdose's speed boost is updated live, not on weapon switch.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarQuickFix = CreateConVar("sm_tf2fix_quickfix","1","If on, the Quick-Fix gives a 3% speed boost when healing Pyros who are using the Attendant.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarKunai = CreateConVar("sm_tf2fix_kunai","1","If on, Spies who have over 185 HP will get their health set to 125, fixing a Conniver's Kunai exploit. Disable this if you have any plugin that gives Spies loads of health, like Boss Battles.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarBushwacka = CreateConVar("sm_tf2fix_bushwacka","1","If on, the Bushwacka will not occasionally spam crit sounds to all players.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarYERIntelligence = CreateConVar("sm_tf2fix_intelligence","1","If on, disguised Spies drop the Intelligence in Capture the Flag.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarDeadRingerTaunt = CreateConVar("sm_tf2fix_deadringer_taunt","1","If on, Spies that are hit while taunting with Dead Ringer active will cloak.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarBostonBasher = CreateConVar("sm_tf2fix_bostonbasher","1","If on, Boston Basher/Three-Rune Blade suicides will show their respective weapon kill icons instead of the skull and bones.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarBattalionsBackup = CreateConVar("sm_tf2fix_battalionsbackup","1","If on, the Battalion's Backup does not award rage for taking environmental damage.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarCloakedForDeath = CreateConVar("sm_tf2fix_fow_spies","1","If on, cloaked and marked for death Spies do not show a skull and bones symbol.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarTFWeapon = CreateConVar("sm_tf2fix_tf_weapon","1","If on, server admins don't need to type in 'tf_weapon_' when setting bot_forcefireweapon.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarMiniCrits = CreateConVar("sm_tf2fix_minicrits","1","If on, mini-crit sounds do not play for all players.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarUberJarate = CreateConVar("sm_tf2fix_uberjarate","1","If on, Snipers using the Sydney Sleeper are unable to coat UberCharged enemies in Jarate.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarMadMilk = CreateConVar("sm_tf2fix_madmilk","1","If on, Spies covered in Mad Milk will give off different responses than the Jarate ones.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarHighFive = CreateConVar("sm_tf2fix_highfive","1","If on, Pyros and Spies who high-five can use unused voice lines.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarIFeelGood = CreateConVar("sm_tf2fix_tresbon","1","If on, Spies gain the ability to feel tres bon!", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarLeeroyJenkins = CreateConVar("sm_tf2fix_democharge","1","If on, Demoman charge sounds will not be cut off.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarTeamworkIsForPussiesYouKnow = CreateConVar("sm_tf2fix_demodidntneedyourhelp","1","If on, prevents Demomen from saying 'I didn't need your help ya know'", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarIncoming = CreateConVar("sm_tf2fix_sniperincoming","1","If on, prevents Snipers from whispering 'Incoming...' because no one can hear you when you whisper.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarPomson = CreateConVar("sm_tf2fix_pomson","1","If on, the Pomson drains the usual 20 percent of cloak from Spies, instead of the glitched 60+ percent drain.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarPomsonSound = CreateConVar("sm_tf2fix_pomsonsound","1","If on, cloaked Spies will hear the Pomson's 'resource drain' sound when hit by it.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarCowManglerReflectIcon = CreateConVar("sm_tf2fix_cowmangler_icon_deflect","1","If on, the kill icon of a deflected Cow Mangler shot will be that of a deflected rocket, rather than the skull and bones.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarDedTaunts = CreateConVar("sm_tf2fix_deadtaunts","1","If on, players who die during certain taunts will not complete them while dead. (e.g. Scout: 'Hey knucklehead!' *dies* '...Bonk.'", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarNPCBlackBox = CreateConVar("sm_tf2fix_bossonhit","1","If on, 'on hit' effects trigger when attacking boss characters.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarNPCCritSounds = CreateConVar("sm_tf2fix_bosscrits","1","If on, crit sounds will play when attacking boss characters with critical hits.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarArenaMove = CreateConVar("sm_tf2fix_arenamove","1","If on, players can't move at all during Setup time in Arena Mode.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarArenaRegen = CreateConVar("sm_tf2fix_arenaregen","0","If on, when an Arena round starts, all players are regenerated. (Might not play nicely with VSH/FF2/Boss)", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarBotTaunts = CreateConVar("sm_tf2fix_bottaunts","1","If on, bots cannot move while being forced to taunt (e.g. by Holiday Punch hits, Fake and Force, etc.)", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarThanksForRide = CreateConVar("sm_tf2fix_teleporterthanks","1","If on, Engineers won't thank themselves for their own Teleporters.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarOriginal = CreateConVar("sm_tf2fix_original","1","If on, the Original's draw sound will play to the client using the weapon, like it does for everyone around them.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarDeadRingerIndicator = CreateConVar("sm_tf2fix_drindicator","1","If on, clients with viewmodels off will have a notification that they have a Dead Ringer out.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarEurekaCrits = CreateConVar("sm_tf2fix_eurekacrits","1","If on, Engineers who have Frontier Justice revenge crits and taunt with the Eureka Effect will not lose them upon teleporting to spawn.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarEyelanderOverflow = CreateConVar("sm_tf2fix_eyelanderoverflow","1","If on, Demomen with the Eyelander who have more than 127 heads will get the correct amount of heads they have displayed to them.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarPhlogRegen = CreateConVar("sm_tf2fix_phlogregen","1","If on, Phlogistinator Pyros will not lose their Mmmph when touching a resupply locker.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarHuntsmanWater = CreateConVar("sm_tf2fix_firearrows","1","If on, lit Huntsman arrows are extinguished when the user enters water.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarSpyCicleSpawn = CreateConVar("sm_tf2fix_spyciclespawn","1","If on, and a Spy loses his Spy-cicle and quickly respawns, he won't have to wait to get it back.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarBannerSwitch = CreateConVar("sm_tf2fix_bannerswitch","1","If on, Soldiers who switch banners will have their rage cleared.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarUberCupcake = CreateConVar("sm_tf2fix_uberkamikaze","1","If on, Soldiers cannot avoid Kamikaze's damage by getting UberCharged.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarUberCrits = CreateConVar("sm_tf2fix_ubercrits","1","If on, crits against UberCharged players will NOT play a crit sound and display 'CRITICAL HIT!!!'", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarEurekaMarkedForDeath = CreateConVar("sm_tf2fix_eurekafanowar","1","If on, fixes Eureka Effect Engineers losing the marked for death status upon teleporting.", FCVAR_NONE, true, 0.0, true, 1.0);
	
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	HookEvent("player_hurt", Event_Hurt, EventHookMode_Pre);
	HookEvent("player_highfive_start", Event_Brofist_Start, EventHookMode_Pre); /* why brofist? because shameless self-plug for mstr.ca/brofist */
	HookEvent("npc_hurt", Event_NpcHurt, EventHookMode_Post); /* when the Horseless Headless Horsemann or MONOCULUS! are attacked */
	HookEvent("teamplay_round_start", Event_RoundStart);
	HookEvent("player_teleported", Event_Teleport, EventHookMode_Pre);
	HookEvent("post_inventory_application", Event_Inventory, EventHookMode_Pre);
	
	AddCommandListener(Command_taunt, "taunt");
	AddCommandListener(Command_taunt, "+taunt");
	
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
	HookConVarChange(cvarLeeroyJenkins, CvarChange);
	HookConVarChange(cvarTeamworkIsForPussiesYouKnow, CvarChange);
	HookConVarChange(cvarIncoming, CvarChange);
	HookConVarChange(cvarPomson, CvarChange);
	HookConVarChange(cvarPomsonSound, CvarChange);
	HookConVarChange(cvarCowManglerReflectIcon, CvarChange);
	HookConVarChange(cvarDedTaunts, CvarChange);
	HookConVarChange(cvarNPCBlackBox, CvarChange);
	HookConVarChange(cvarNPCCritSounds, CvarChange);
	HookConVarChange(cvarArenaMove, CvarChange);
	HookConVarChange(cvarArenaRegen, CvarChange);
	HookConVarChange(cvarBotTaunts, CvarChange);
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
	HookConVarChange(cvarEurekaMarkedForDeath, CvarChange);
	
	AddNormalSoundHook(SoundHook);
	
	new String:disGaem[10];
	GetGameFolderName(disGaem, 10);
	if (strncmp(disGaem, "tf", 2, false) != 0) SetFailState("TF2Fix, a plugin that fixes Team Fotress 2, doesn't work on any game except, um, Super Mario 64!");
	
	AutoExecConfig(true, "tf2fix");
	
	new Handle:GameConf = LoadGameConfigFile("tf2fix");
	if (GameConf == INVALID_HANDLE)
	{
		SetFailState("tf2fix.txt is missing from tf/addons/sourcemod/gamedata");
		return;
	}
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(GameConf, SDKConf_Virtual, "CTFPlayer_GetMaxHealth");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	hMaxHealth = EndPrepSDKCall();
	if (hMaxHealth == INVALID_HANDLE)
	{
		SetFailState("Could not initialize call for CTFPlayer::GetMaxHealth");
		CloseHandle(GameConf);
		return;
	}
	CloseHandle(GameConf);
	
	OnBothStart();
}

public OnMapStart()
{
	OnBothStart();
	IsMedieval(true);
	NotVeryMuchTimer = CreateTimer(0.15, timer_NotVeryMuchOfASecond, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	QuarterSecondTimer = CreateTimer(0.25, timer_Quartersecond, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

new wepEnt;
new wepIndex;
new sniperHeads[MAXPLAYERS + 1];
new Float:markedForDeath[MAXPLAYERS + 1];
new bool:isPlayingPomsonSound[MAXPLAYERS + 1];
new rand;
new bool:arenaModeSetupTime = false;
new bool:isTaunting[MAXPLAYERS + 1] = false;
new bool:didTakeOwnTeleporter[MAXPLAYERS + 1] = false;
new bool:hasDeadRingerMessage[MAXPLAYERS + 1] = false;
new revengeCrits[MAXPLAYERS + 1] = 0;
new Float:phlog[MAXPLAYERS + 1] = 0.0;
new bool:justRegenerated[MAXPLAYERS + 1] = false;
new equippedBanner[MAXPLAYERS + 1] = 0;

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
		
		new TFClassType:class = TF2_GetPlayerClass(z);
		new activeWeapon;
		new primaryWeapon;
		new secondaryWeapon;
		new meleeWeapon;
		if (GetPlayerWeaponSlot(z, TFWeaponSlot_Primary) == GetEntPropEnt(z, Prop_Send, "m_hActiveWeapon")) activeWeapon = 0;
		if (GetPlayerWeaponSlot(z, TFWeaponSlot_Secondary) == GetEntPropEnt(z, Prop_Send, "m_hActiveWeapon")) activeWeapon = 1;
		if (GetPlayerWeaponSlot(z, TFWeaponSlot_Melee) == GetEntPropEnt(z, Prop_Send, "m_hActiveWeapon")) activeWeapon = 2;
		if ((wepEnt = GetPlayerWeaponSlot(z, 0))!=-1) primaryWeapon = GetEntProp(wepEnt, Prop_Send, "m_iItemDefinitionIndex");
		if ((wepEnt = GetPlayerWeaponSlot(z, 1))!=-1) secondaryWeapon = GetEntProp(wepEnt, Prop_Send, "m_iItemDefinitionIndex");
		if ((wepEnt = GetPlayerWeaponSlot(z, 2))!=-1) meleeWeapon = GetEntProp(wepEnt, Prop_Send, "m_iItemDefinitionIndex");
		if (IsFakeClient(z) && Enabled && BotTaunts && isTaunting[z])
		{
			if (TF2_IsPlayerInCondition(z, TFCond_Taunting)) SetEntityMoveType(z, MOVETYPE_NONE);
			if (!TF2_IsPlayerInCondition(z, TFCond_Taunting) && GetEntityMoveType(z) == MOVETYPE_NONE) SetEntityMoveType(z, MOVETYPE_WALK);
		}
		if (arenaModeSetupTime && ArenaMove && (GetClientTeam(z) == 2 || GetClientTeam(z) == 3) && GetEntityMoveType(z) != MOVETYPE_NOCLIP) SetEntityMoveType(z, MOVETYPE_NONE);
		if (TF2_IsPlayerInCondition(z, TFCond_Ubercharged) && TF2_IsPlayerInCondition(z, TFCond_Jarated) && UberJarate) TF2_RemoveCondition(z, TFCond_Jarated);
		if (secondaryWeapon == 595 /* The Manmelter */ && ManmelterTimer)
		{
			new Float:nextAttackFloat = (GetEntPropFloat(wepEnt, Prop_Send, "m_flNextPrimaryAttack") - GetGameTime())
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
						new Float:newSpeed = 320.0 + (32.0 * GetEntPropFloat(wepEnt2, Prop_Send, "m_flChargeLevel") / 1.0)
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
			if (GetClientHealth(z) > 185 && TF2_GetMaxHealth(z) < 200 && Kunai) SetEntityHealth(z, 125);
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
			}
		}
		else if (hasDeadRingerMessage[z])
		{
			ClearSyncHud(z, drHUD);
			hasDeadRingerMessage[z] = false;
		}
	}
	return Plugin_Continue;
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
	new playeruid = GetEventInt(event, "userid")
	new victim = GetClientOfUserId(playeruid)
	new playeruid2 = GetEventInt(event, "attacker")
	new attacker = GetClientOfUserId(playeruid2)
	new String:weapon[128];
	GetEventString(event, "weapon_logclassname", weapon, 128);
	new customkill = GetEventInt(event, "customkill");
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
	if (StrEqual(weapon, "cow_mangler", true))
	{
		if (attacker == victim && customkill == 3 && CowMangler) SetEventInt(event, "customkill", 46);
	}
	if (StrEqual(weapon, "tf_projectile_energy_ball", true) && CowManglerReflectIcon) SetEventString(event, "weapon", "deflect_rocket");
	if (Eyelander && (StrEqual(weapon, "sword", true) || StrEqual(weapon, "headtaker", true) || StrEqual(weapon, "nessieclub", true) || StrEqual(weapon, "taunt_demoman", true)))
	{
		if ((wepEnt = GetPlayerWeaponSlot(attacker, 2))!=-1)
		{
			wepIndex = GetEntProp(wepEnt, Prop_Send, "m_iItemDefinitionIndex");
			if (wepIndex == 132 || wepIndex == 266 || wepIndex == 482) /* Double check to make sure it's an Eyelander, since Demoman taunt kills can be made with almost any melee */
			{
				if (sniperHeads[victim] > 0)
				{
					SetEntProp(attacker, Prop_Send, "m_iDecapitations", (GetEntProp(attacker, Prop_Send, "m_iDecapitations") - sniperHeads[victim]));
				}
			}
		}
	}
	if (StrEqual(weapon, "ubersaw", true) && customkill == 29 && Ubersaw) SetEventString(event, "weapon", "taunt_medic");
	return Plugin_Continue;
}

public Action:Event_Hurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!Enabled) return Plugin_Continue;
	new playeruid = GetEventInt(event, "userid")
	new victim = GetClientOfUserId(playeruid)
	new playeruid2 = GetEventInt(event, "attacker")
	new attacker = GetClientOfUserId(playeruid2)
	new custom = GetEventInt(event, "custom");
	new damage = GetEventInt(event, "damageamount");
	if (GetEventBool(event, "minicrit") && MiniCrits) SetEventBool(event, "allseecrit", false);
	if (custom == TF_CUSTOM_BACKSTAB && GetConVarInt(FindConVar("tf_weapon_criticals")) == 0 && Backstab)
	{
		SetEventInt(event, "damageamount", GetEventInt(event, "damageamount") * 3); /* Cosmetic change. Crit backstabs deal 6x victim's HP, non-crit deals 2x, this ramps it to 6x */
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
	if (custom == TF_CUSTOM_TAUNT_GRENADE && victim == attacker && TF2_IsPlayerInCondition(victim, TFCond_Ubercharged) && UberCupcake)
	{
		FakeClientCommand(victim, "explode");
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
		if (TF2_GetPlayerClass(victim) == TFClass_Spy && TF2_IsPlayerInCondition(victim, TFCond_Cloaked))
		{
			if (Pomson)
			{
				new Float:newCloak = (GetEntPropFloat(victim, Prop_Send, "m_flCloakMeter") + 13.3); /* Restore 66% of lost cloak since it drains 40% too much... */
				if (newCloak > 100.0) newCloak = 100.0;												/* ...or something. I'm bad at math and totally didn't do trial and error here. */
				if (newCloak < 0.0) newCloak = 0.0;
				SetEntPropFloat(victim, Prop_Send, "m_flCloakMeter", newCloak);
			}
			if (PomsonSound)
			{
				if (!isPlayingPomsonSound[victim]) EmitSoundToClient(victim, "weapons/drg_pomson_drain_01.wav");
				isPlayingPomsonSound[victim] = true;
			}
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
			if (wepIndex == 228 /* The Black Box */) SetEntityHealth(client, GetClientHealth(client) + 15);
			if (GetClientHealth(client) > TF2_GetMaxHealth(client)) SetEntityHealth(client, TF2_GetMaxHealth(client));
		}
	}
	if (weapon == 20 || damage == 10 || damage == 30)
	{
		if ((wepEnt = GetPlayerWeaponSlot(client, 0))!=-1)
		{
			wepIndex = GetEntProp(wepEnt, Prop_Send, "m_iItemDefinitionIndex");
			if (wepIndex == 36 /* The Blutsauger */) SetEntityHealth(client, GetClientHealth(client) + 3);
			if (GetClientHealth(client) > TF2_GetMaxHealth(client)) SetEntityHealth(client, TF2_GetMaxHealth(client));
		}
	}
	if (weapon == 12)
	{
		if ((wepEnt = GetPlayerWeaponSlot(client, 0))!=-1)
		{
			wepIndex = GetEntProp(wepEnt, Prop_Send, "m_iItemDefinitionIndex");
			if (wepIndex == 527 /* The Widowmaker */)
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
	
	return Plugin_Continue;	
}

public Action:Command_taunt(client, const String:command[], args)
{
	if (!IsFakeClient(client)) return Plugin_Continue;
	if (!Enabled || !BotTaunts) return Plugin_Continue;
	isTaunting[client] = true;
	return Plugin_Continue;
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (Enabled)
	{
		new Ent = -1;
		while ((Ent = FindEntityByClassname(Ent, "tf_logic_arena")) != -1)
		{
			arenaModeSetupTime = true;
		}
		CreateTimer(GetConVarFloat(FindConVar("tf_arena_preround_time")), Timer_ArenaStart);
	}
	return Plugin_Continue;
}

public Action:Timer_ArenaStart(Handle:timer)
{
	if (Enabled)
	{
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
					if (ArenaRegen) TF2_RegeneratePlayer(z);
				}
			}
		}
	}
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
	CreateTimer(0.1, Timer_LateRegen, client);
	return Plugin_Continue;	
}

public Action:Timer_LateRegen(Handle:timer, any:client)
{
	justRegenerated[client] = false;
	new primaryWeapon;
	new secondaryWeapon;
	if ((wepEnt = GetPlayerWeaponSlot(client, 0))!=-1) primaryWeapon = GetEntProp(wepEnt, Prop_Send, "m_iItemDefinitionIndex");
	if ((wepEnt = GetPlayerWeaponSlot(client, 1))!=-1) secondaryWeapon = GetEntProp(wepEnt, Prop_Send, "m_iItemDefinitionIndex");
	if (EurekaCrits && primaryWeapon == 141) /* The Frontier Justice */ SetEntProp(client, Prop_Send, "m_iRevengeCrits", revengeCrits[client]);
	if (PhlogRegen && primaryWeapon == 594) /* The Phlogistinator */ SetEntPropFloat(client, Prop_Send, "m_flRageMeter", phlog[client]);
	if ((secondaryWeapon == 129 || secondaryWeapon == 226 || secondaryWeapon == 354) && BannerSwitch)
	{
		if (secondaryWeapon != equippedBanner[client]) SetEntPropFloat(client, Prop_Send, "m_flRageMeter", 0.0);
		equippedBanner[client] = secondaryWeapon;
	}
	if (EurekaMarkedForDeath && markedForDeath[client] > 0.0 && !TF2_IsPlayerInCondition(client, TFCond_MarkedForDeath) && !TF2_IsPlayerInCondition(client, TFCond_Cloaked)) TF2_AddCondition(client, TFCond_MarkedForDeath, markedForDeath[client]);
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

stock TF2_GetMaxHealth(client) /* Stolen from FlaminSarge at the request of...uh...him */
{
	if (hMaxHealth != INVALID_HANDLE)
		return SDKCall(hMaxHealth, client);
	else return GetEntProp(client, Prop_Data, "m_iMaxHealth");
}

public Action:SoundHook(clients[64], &numClients, String:sound[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	if (!Enabled) return Plugin_Continue;
	if (entity <= 0 || entity > MaxClients) return Plugin_Continue;
	if (!IsClientInGame(entity)) return Plugin_Continue;
	if (!IsPlayerAlive(entity) && DedTaunts)
	{
		new bool:shouldStopTaunt = false; /* blegh... */
		if (StrContains(sound, "scout_autocappedintelligence02", false) != -1) shouldStopTaunt = true;
		if (StrContains(sound, "scout_beingshotinvincible15", false) != -1) shouldStopTaunt = true;
		if (StrContains(sound, "scout_cheers01", false) != -1) shouldStopTaunt = true;
		if (StrContains(sound, "scout_specialcompleted02", false) != -1) shouldStopTaunt = true;
		if (StrContains(sound, "scout_specialcompleted03", false) != -1) shouldStopTaunt = true;
		if (StrContains(sound, "scout_taunts01", false) != -1) shouldStopTaunt = true;
		if (StrContains(sound, "scout_thanksfortheheal01", false) != -1) shouldStopTaunt = true;
		if (StrContains(sound, "soldier_taunts01", false) != -1) shouldStopTaunt = true;
		if (StrContains(sound, "soldier_specialcompleted01", false) != -1) shouldStopTaunt = true;
		if (StrContains(sound, "soldier_specialcompleted04", false) != -1) shouldStopTaunt = true;
		if (StrContains(sound, "soldier_cheers05", false) != -1) shouldStopTaunt = true;
		if (StrContains(sound, "soldier_pickaxetaunt04", false) != -1) shouldStopTaunt = true;
		if (StrContains(sound, "soldier_positivevocalization01", false) != -1) shouldStopTaunt = true;
		if (StrContains(sound, "soldier_kaboomalts03", false) != -1) shouldStopTaunt = true;
		if (StrContains(sound, "pyro_headright01", false) != -1) shouldStopTaunt = true;
		if (StrContains(sound, "pyro_highfive", false) != -1) shouldStopTaunt = true;
		if (StrContains(sound, "demoman_laughshort03", false) != -1) shouldStopTaunt = true;
		if (StrContains(sound, "taunt_bottle_ah", false) != -1) shouldStopTaunt = true;
		if (StrContains(sound, "heavy_goodjob03", false) != -1) shouldStopTaunt = true;
		if (StrContains(sound, "heavy_specialcompleted-assistedkill01", false) != -1) shouldStopTaunt = true;
		if (StrContains(sound, "heavy_generic01", false) != -1) shouldStopTaunt = true;
		if (StrContains(sound, "heavy_taunts01", false) != -1) shouldStopTaunt = true;
		if (StrContains(sound, "sandwicheat09", false) != -1) shouldStopTaunt = true;
		if (StrContains(sound, "heavy_niceshot02", false) != -1) shouldStopTaunt = true;
		if (StrContains(sound, "heavy_cheers02", false) != -1) shouldStopTaunt = true;
		if (StrContains(sound, "engineer_cheers02", false) != -1) shouldStopTaunt = true;
		if (StrContains(sound, "medic_cheers01", false) != -1) shouldStopTaunt = true;
		if (StrContains(sound, "sniper_battlecry03", false) != -1) shouldStopTaunt = true;
		if (StrContains(sound, "sniper_battlecry05", false) != -1) shouldStopTaunt = true;
		if (StrContains(sound, "sniper_goodjob03", false) != -1) shouldStopTaunt = true;
		if (StrContains(sound, "spy_battlecry04", false) != -1) shouldStopTaunt = true;
		if (StrContains(sound, "spy_specialcompleted07", false) != -1) shouldStopTaunt = true;
		if (StrContains(sound, "spy_jeers02", false) != -1) shouldStopTaunt = true;
		if (StrContains(sound, "spy_specialcompleted11", false) != -1) shouldStopTaunt = true;
		if (StrContains(sound, "spy_taunts09", false) != -1) shouldStopTaunt = true;
		if (StrContains(sound, "spy_negativevocalization", false) != -1) shouldStopTaunt = true;
		if (StrContains(sound, "spy_goodjob02", false) != -1) shouldStopTaunt = true;
		if (StrContains(sound, "spy_laughshort", false) != -1) shouldStopTaunt = true;
		if (StrContains(sound, "spy_autocappedintelligence03", false) != -1) shouldStopTaunt = true;
		if (StrContains(sound, "spy_highfive", false) != -1) shouldStopTaunt = true;
		if (shouldStopTaunt) return Plugin_Stop;
	}
	if (IsFakeClient(entity) && BotTaunts)
	{
		if (StrContains(sound, "scout_laughlong02", false) != -1) isTaunting[entity] = true;
		if (StrContains(sound, "soldier_laughlong03", false) != -1) isTaunting[entity] = true;
		if (StrContains(sound, "pyro_laugh_addl04", false) != -1) isTaunting[entity] = true;
		if (StrContains(sound, "demoman_laughlong02", false) != -1) isTaunting[entity] = true;
		if (StrContains(sound, "heavy_laugherbigsnort01", false) != -1) isTaunting[entity] = true;
		if (StrContains(sound, "engineer_laughlong02", false) != -1) isTaunting[entity] = true;
		if (StrContains(sound, "medic_laughlong01", false) != -1) isTaunting[entity] = true;
		if (StrContains(sound, "sniper_laughlong02", false) != -1) isTaunting[entity] = true;
		if (StrContains(sound, "spy_laughlong01", false) != -1) isTaunting[entity] = true;
	}
	if (StrContains(sound, "weapons/demo_charge_windup", false) != -1 && LeeroyJenkins && volume == 1.0 && !TF2_IsPlayerInCondition(entity, TFCond_Kritzkrieged))
	{
		new String:newSound[128];
		Format(newSound, 128, "weapons/demo_charge_windup%i.wav", GetRandomInt(1,3));
		PrecacheSound(newSound);
		EmitSound(clients, numClients, newSound, entity, SNDCHAN_AUTO, _, _, 0.5);
		return Plugin_Stop;
	}
	if (StrContains(sound, "engineer_thanksfortheteleporter", false) != -1 && ThanksForRide)
	{
		if (didTakeOwnTeleporter[entity]) return Plugin_Stop;
	}
	if (StrContains(sound, "quake_ammo_pickup_remastered", false) != -1 && Original)
	{
		PrecacheSound(sound);
		EmitSoundToClient(entity, sound);
	}
	if (volume > 0.99996) return Plugin_Continue; // should filter out most playsounds plugins
	if (StrContains(sound, "vo/spy_jaratehit", false) != -1 && !TF2_IsPlayerInCondition(entity, TFCond_Jarated) && MadMilk)
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
		if (rand == 4) Format(sound, 128, "vo/taunts/spy_feelgood01.wav"); /* GOOD LORD */
		PrecacheSound(sound);
		return Plugin_Changed;
	}
	if (StrContains(sound, "vo/demoman_specialcompleted-assistedkill02", false) != -1 && TeamworkIsForPussiesYouKnow)
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

stock SetViewmodelAnimation(client, Sequence)
{
	new Ent = -1;
	while ((Ent = FindEntityByClassname(Ent, "tf_viewmodel")) != -1)
	{
		if (GetEntPropEnt(Ent, Prop_Send, "m_hOwner") == client)
			SetEntProp(Ent, Prop_Send, "m_nSequence", Sequence);
	}
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
	else if (convar == cvarLeeroyJenkins) LeeroyJenkins = bool:StringToInt(newValue);
	else if (convar == cvarTeamworkIsForPussiesYouKnow) TeamworkIsForPussiesYouKnow = bool:StringToInt(newValue);
	else if (convar == cvarIncoming) Incoming = bool:StringToInt(newValue);
	else if (convar == cvarPomson) Pomson = bool:StringToInt(newValue);
	else if (convar == cvarPomsonSound) PomsonSound = bool:StringToInt(newValue);
	else if (convar == cvarCowManglerReflectIcon) CowManglerReflectIcon = bool:StringToInt(newValue);
	else if (convar == cvarDedTaunts) DedTaunts = bool:StringToInt(newValue);
	else if (convar == cvarNPCBlackBox) NPCBlackBox = bool:StringToInt(newValue);
	else if (convar == cvarNPCCritSounds) NPCCritSounds = bool:StringToInt(newValue);
	else if (convar == cvarArenaMove) ArenaMove = bool:StringToInt(newValue);
	else if (convar == cvarArenaRegen) ArenaRegen = bool:StringToInt(newValue);
	else if (convar == cvarBotTaunts) BotTaunts = bool:StringToInt(newValue);
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
	else if (convar == cvarEurekaMarkedForDeath) EurekaMarkedForDeath = bool:StringToInt(newValue);
}