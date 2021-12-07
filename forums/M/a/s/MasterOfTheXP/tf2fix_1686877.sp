#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

public Plugin:myinfo = {
	name = "{MSTR} TF2Fix",
	author = "MasterOfTheXP",
	description = "Fixes various glitches, bugs, and more in Team Fortress 2.",
	version = "1.1.1",
	url = "http://mstr.ca/"
};

/* CVARS (1) */
new Handle:cvarEnabled; /* Rougly 25% of this plugin's lines of code are cvars */
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

/* HUD TEXT (1) */
new Handle:headsHUD;

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

public Action:OnBothStart()
{
	PrecacheSound("weapons/knife_swing_crit.wav");
	PrecacheSound("player/crit_received1.wav");
	PrecacheSound("player/crit_received2.wav");
	PrecacheSound("player/crit_received3.wav");
	PrecacheSound("player/crit_hit.wav");
	PrecacheSound("player/crit_hit2.wav");
	PrecacheSound("player/crit_hit3.wav");
	PrecacheSound("player/crit_hit4.wav");
	PrecacheSound("player/crit_hit5.wav");
}

public OnPluginStart()
{
	/* CVARS (3) */
	cvarEnabled = CreateConVar("sm_tf2fix_enabled","1","Enables/disables TF2Fix plugin.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarBazaar = CreateConVar("sm_tf2fix_bazaar","1","If on, Bazaar Bargain users who have more than 7 heads will see their real head count.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarUbersaw = CreateConVar("sm_tf2fix_ubersaw","1","If on, Ubersaw taunt kills display their unused icon.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarBackstab = CreateConVar("sm_tf2fix_backstab","1","If on, backstabs appear smoother on servers with random critical hits turned off.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarManmelterTimer = CreateConVar("sm_tf2fix_manmelter_timer","1","If on, Manmelter users get a timer in the bottom of their screen showing when they can fire again, since in most peoples' opinions, it's extremely hard to tell without a reload animation.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarEyelander = CreateConVar("sm_tf2fix_eyelander","1","If on, Eyelander kills on Bazaar Bargain Snipers won't steal that Sniper's heads.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarCowMangler = CreateConVar("sm_tf2fix_cowmangler_icon_suicide","1","If on, Cow Mangler afterburn suicides show the Cow Mangler kill icon.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarOverdose = CreateConVar("sm_tf2fix_overdose","1","If on, the Overdose's speed boost is updated live, not on weapon switch.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarQuickFix = CreateConVar("sm_tf2fix_quickfix","1","If on, the Quick-Fix gives a 3% speed boost when healing Pyros who are using the Attendant.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarKunai = CreateConVar("sm_tf2fix_kunai","1","If on, Spies who have over 185 HP will get their health set to 125, fixing a Conniver's Kunai exploit. Disable this if you have any plugin that gives Spies loads of health, like Boss Battles.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarBushwacka = CreateConVar("sm_tf2fix_bushwacka","1","If on, the Bushwacka will not occasionally spam crit sounds to all players.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarYERIntelligence = CreateConVar("sm_tf2fix_intelligence","1","If on, disguised Spies drop the Intelligence in Capture the Flag.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarDeadRingerTaunt = CreateConVar("sm_tf2fix_deadringer_taunt","1","If on, Spies that are hit while taunting with Dead Ringer active will cloak.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarBostonBasher = CreateConVar("sm_tf2fix_bostonbasher","1","If on, Boston Basher/Three-Rune Blade suicides will show their respective weapon kill icons instead of the skull and bones.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarBattalionsBackup = CreateConVar("sm_tf2fix_battalionsbackup","1","If on, the Battalion's Backup does not award rage for taking environmental damage.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarCloakedForDeath = CreateConVar("sm_tf2fix_fow_spies","1","If on, cloaked and marked for death Spies do not show a skull and bones symbol.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarTFWeapon = CreateConVar("sm_tf2fix_tf_weapon","1","If on, server admins don't need to type in 'tf_weapon_' when setting bot_forcefireweapon.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarMiniCrits = CreateConVar("sm_tf2fix_minicrits","1","If on, mini-crit sounds do not play for all players.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarUberJarate = CreateConVar("sm_tf2fix_uberjarate","1","If on, Snipers using the Sydney Sleeper are unable to coat UberCharged enemies in Jarate.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarMadMilk = CreateConVar("sm_tf2fix_madmilk","1","If on, Spies covered in Mad Milk will give off different responses than the Jarate ones.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarHighFive = CreateConVar("sm_tf2fix_highfive","1","If on, Pyros and Spies who high-five can use unused voice lines.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarIFeelGood = CreateConVar("sm_tf2fix_tresbon","1","If on, Spies gain the ability to feel tres bon!", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarLeeroyJenkins = CreateConVar("sm_tf2fix_democharge","1","If on, Demoman charge sounds will not be cut off.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarTeamworkIsForPussiesYouKnow = CreateConVar("sm_tf2fix_demodidntneedyourhelp","1","If on, prevents Demomen from saying 'I didn't need your help ya know'", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarIncoming = CreateConVar("sm_tf2fix_sniperincoming","1","If on, prevents Snipers from whispering 'Incoming...' because no one can hear you when you whisper.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarPomson = CreateConVar("sm_tf2fix_pomson","1","If on, the Pomson drains the usual 20 percent of cloak from Spies, instead of the glitched 60+ percent drain.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarPomsonSound = CreateConVar("sm_tf2fix_pomsonsound","1","If on, cloaked Spies will hear the Pomson's 'resource drain' sound when hit by it.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarCowManglerReflectIcon = CreateConVar("sm_tf2fix_cowmangler_icon_deflect","1","If on, the kill icon of a deflected Cow Mangler shot will be that of a deflected rocket, rather than the skull and bones.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarDedTaunts = CreateConVar("sm_tf2fix_deadtaunts","1","If on, players who die during certain taunts will not complete them while dead. (e.g. Scout: 'Hey knucklehead!' *dies* '...Bonk.'", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarNPCBlackBox = CreateConVar("sm_tf2fix_bossonhit","1","If on, 'on hit' effects trigger when attacking boss characters.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarNPCCritSounds = CreateConVar("sm_tf2fix_bosscrits","1","If on, crit sounds will play when attacking boss characters with critical hits.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	CreateTimer(0.15, timer_NotVeryMuchOfASecond);
	CreateTimer(0.25, timer_Quartersecond);
	
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	HookEvent("player_hurt", Event_Hurt, EventHookMode_Pre);
	HookEvent("player_highfive_start", Event_Brofist_Start, EventHookMode_Pre); /* why brofist? because shameless self-plug for mstr.ca/brofist */
	HookEvent("npc_hurt", Event_NpcHurt, EventHookMode_Post); /* when the Horseless Headless Horsemann or MONOCULUS! are attacked */
	
	/* HUD TEXT (2) */
	headsHUD = CreateHudSynchronizer();
	
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
	
	AddNormalSoundHook(SoundHook);
	
	new String:disGaem[10];
	GetGameFolderName(disGaem, 10);
	if (!StrEqual(disGaem, "tf")) SetFailState("TF2Fix, a plugin that fixes Team Fotress 2, doesn't work on any game except, um, Pac-Man: Source!");
	
	AutoExecConfig(true, "tf2fix");
	
	new Handle:GameConf = LoadGameConfigFile("tf2fix");
	if (GameConf == INVALID_HANDLE)
	{
		SetFailState("tf2fix.txt is missing from tf/gamedata");
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
}

new wepEnt;
new wepIndex;
new sniperHeads[MAXPLAYERS + 1];
new Float:markedForDeath[MAXPLAYERS + 1];
new bool:isPlayingPomsonSound[MAXPLAYERS + 1];
new rand;

public Action:timer_NotVeryMuchOfASecond(Handle:timer)
{
	if (!Enabled)
	{
		CreateTimer(0.15, timer_NotVeryMuchOfASecond);
		return Plugin_Handled;
	}
	rand = -1;
	for (new z = 1; z <= GetMaxClients(); z++)
	{
		if (IsClientInGame(z))
		{
			if (TF2_IsPlayerInCondition(z, TFCond_Ubercharged) && TF2_IsPlayerInCondition(z, TFCond_Jarated) && UberJarate) TF2_RemoveCondition(z, TFCond_Jarated);
			new TFClassType:class = TF2_GetPlayerClass(z);
			if (class == TFClass_Pyro && (wepEnt = GetPlayerWeaponSlot(z, 1))!=-1)
			{
				wepIndex = GetEntProp(wepEnt, Prop_Send, "m_iItemDefinitionIndex");
				if (wepIndex == 595 /* The Manmelter */ && ManmelterTimer)
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
			}
			if (class == TFClass_Medic && GetPlayerWeaponSlot(z, TFWeaponSlot_Primary) == GetEntPropEnt(z, Prop_Send, "m_hActiveWeapon"))
			{
				if ((wepEnt = GetPlayerWeaponSlot(z, 0))!=-1)
				{
					wepIndex = GetEntProp(wepEnt, Prop_Send, "m_iItemDefinitionIndex");
					if (wepIndex == 412 /* The Overdose */ && Overdose)
					{
						new wepEnt2;
						if ((wepEnt2 = GetPlayerWeaponSlot(z, 1))!=-1)
						{
							new Float:newSpeed = 320.0 + (32.0 * GetEntPropFloat(wepEnt2, Prop_Send, "m_flChargeLevel") / 1.0)
							if (GetEntPropFloat(z, Prop_Send, "m_flMaxspeed") != newSpeed) SetEntPropFloat(z, Prop_Send, "m_flMaxspeed", newSpeed);
						}
					}
				}
			}
			if (class == TFClass_Medic && GetPlayerWeaponSlot(z, TFWeaponSlot_Secondary) == GetEntPropEnt(z, Prop_Send, "m_hActiveWeapon"))
			{
				if ((wepEnt = GetPlayerWeaponSlot(z, 1))!=-1)
				{
					wepIndex = GetEntProp(wepEnt, Prop_Send, "m_iItemDefinitionIndex");
					if (wepIndex == 411 /* The Quick-Fix */ && QuickFix && GetEntPropFloat(z, Prop_Send, "m_flMaxspeed") > 0.0)
					{
						if (GetHealingTarget(z) != -1 && GetEntPropFloat(GetHealingTarget(z), Prop_Send, "m_flMaxspeed") > 320.0)
						SetEntPropFloat(z, Prop_Send, "m_flMaxspeed", GetEntPropFloat(GetHealingTarget(z), Prop_Send, "m_flMaxspeed"));
						if ((GetHealingTarget(z) != -1 && GetEntPropFloat(GetHealingTarget(z), Prop_Send, "m_flMaxspeed") <= 320.0) || GetHealingTarget(z) == -1)
						SetEntPropFloat(z, Prop_Send, "m_flMaxspeed", 320.0);
					}
				}
			}
			if (class == TFClass_Sniper && (wepEnt = GetPlayerWeaponSlot(z, 0))!=-1)
			{
				wepIndex = GetEntProp(wepEnt, Prop_Send, "m_iItemDefinitionIndex");
				if (wepIndex == 402) /* The Bazaar Bargain */
				{
					if (Bazaar && GetEntProp(z, Prop_Send, "m_iDecapitations") > 7)
					{
						SetHudTextParams(1.0, 1.0, 0.2, 255, 255, 255, 255);
						SetGlobalTransTarget(z);
						ShowSyncHudText(z, headsHUD, "%i Heads", GetEntProp(z, Prop_Send, "m_iDecapitations"));
					}
					if (IsPlayerAlive(z)) sniperHeads[z] = GetEntProp(z, Prop_Send, "m_iDecapitations");
				}
				if (wepIndex != 402 && Eyelander) sniperHeads[z] = 0;
			}
			if (class == TFClass_Spy)
			{
				if (GetClientHealth(z) > 185 && TF2_GetMaxHealth(z) < 200 && Kunai) SetEntityHealth(z, 125);
				if (TF2_IsPlayerInCondition(z, TFCond_Disguised) && YERIntelligence && GetEntProp(z, Prop_Send, "m_hItem") != -1) TF2_RemovePlayerDisguise(z);
				if (markedForDeath[z] > 0.0) 
				{
					markedForDeath[z] = (markedForDeath[z] - 0.1);
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
				if (markedForDeath[z] < 0.1 && TF2_IsPlayerInCondition(z, TFCond_MarkedForDeath)) TF2_RemoveCondition(z, TFCond_MarkedForDeath);
				if (markedForDeath[z] < 0.1 && TF2_IsPlayerInCondition(z, TFCond_CritCola)) TF2_RemoveCondition(z, TFCond_CritCola);
			}
			if (class != TFClass_Sniper && Eyelander) sniperHeads[z] = 0;
		}
	}
	
	if (TFWeapon)
	{
		new String:oldValue[128];
		GetConVarString(FindConVar("bot_forcefireweapon"), oldValue, 128);
		if (StrContains(oldValue, "tf_weapon_", false) == -1)
		{
			new String:newValue[128];
			Format(newValue, 128, "tf_weapon_%s", oldValue);
			SetConVarString(FindConVar("bot_forcefireweapon"), newValue);
		}
	}
	
	CreateTimer(0.15, timer_NotVeryMuchOfASecond);
	return Plugin_Handled;
}

public Action:timer_Quartersecond(Handle:timer)
{
	if (!Enabled)
	{
		CreateTimer(0.25, timer_Quartersecond);
		return Plugin_Handled;
	}
	for (new z = 1; z <= GetMaxClients(); z++)
	{
		if (IsClientInGame(z)) isPlayingPomsonSound[z] = false;
	}
	CreateTimer(0.25, timer_Quartersecond);
	return Plugin_Handled;
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
	}
	if (attacker != 0 && TF2_GetPlayerClass(attacker) == TFClass_Scout)
	{
		if (TF2_GetPlayerClass(victim) == TFClass_Spy)
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
	}
	if (TF2_GetPlayerClass(victim) == TFClass_Soldier)
	{
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
	}
	if (attacker != 0 && TF2_GetPlayerClass(attacker) == TFClass_Engineer && custom == TF_CUSTOM_PLASMA)
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
	if (attacker != 0 && TF2_GetPlayerClass(attacker) == TFClass_Sniper)
	{
		if ((wepEnt = GetPlayerWeaponSlot(attacker, 2))!=-1)
		{
			wepIndex = GetEntProp(wepEnt, Prop_Send, "m_iItemDefinitionIndex");
			if (wepIndex == 232 /* The Bushwacka */ && Bushwacka) SetEventBool(event, "allseecrit", false); /* That's literally all you have to do to fix this, apparently. */
		}
	}
	if (TF2_GetPlayerClass(victim) == TFClass_Spy)
	{
		if (DeadRingerTaunt && GetEntPropEnt(victim, Prop_Send, "m_bFeignDeathReady") == 1 && TF2_IsPlayerInCondition(victim, TFCond_Taunting))
		{
			TF2_RemoveCondition(victim, TFCond_Taunting);
			TF2_AddCondition(victim, TFCond_DeadRingered, 0.01);
			new Handle:fakeEvent = CreateEvent("player_death", true); /* I totally didn't learn how to use this from Hale Mode */
			SetEventInt(fakeEvent, "userid", GetClientUserId(victim));
			SetEventInt(fakeEvent, "attacker", GetClientUserId(attacker));
			SetEventInt(fakeEvent, "weaponid", GetEventInt(event, "weaponid"));
			SetEventInt(fakeEvent, "death_flags", TF_DEATHFLAG_DEADRINGER); /* ded is misspelt but w/e :| */
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
	if (!IsPlayerAlive(entity) && StrContains(sound, "vo", false) != -1 && StrContains(sound, "pain", false) == -1 && StrContains(sound, "death", false) == -1 && DedTaunts) return Plugin_Stop;
	if (StrContains(sound, "weapons/demo_charge_windup", false) != -1 && LeeroyJenkins && volume == 1.0)
	{
		new String:newSound[128];
		Format(newSound, 128, "weapons/demo_charge_windup%i.wav", GetRandomInt(1,3));
		PrecacheSound(newSound);
		EmitSound(clients, numClients, newSound, entity, _, _, _, 0.999999); /* 0.9999 because, look above, this fix checks for charge sounds at 1.000, if this one's */
		return Plugin_Stop;															/* 1.0, the space-time continuum would most likely shred itself into little pieces */
	}
	if (volume > 0.99996) return Plugin_Continue; // should filter out most playsounds plugins
	if (StrContains(sound, "vo/spy_jaratehit", false) != -1 && IsClientInGame(entity) && !TF2_IsPlayerInCondition(entity, TFCond_Jarated) && MadMilk)
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
	if (IsClientInGame(entity) && StrContains(sound, "vo/taunts/spy_highfive01", false) != -1 && HighFive) /* slap my ass */
	{
		if (rand == -1) rand = GetRandomInt(1,14);
		if (rand < 10) Format(sound, 128, "vo/taunts/spy_highfive0%i.wav", rand);
		if (rand > 9) Format(sound, 128, "vo/taunts/spy_highfive%i.wav", rand);
		PrecacheSound(sound);
		return Plugin_Changed;
	}
	if (IsClientInGame(entity) && StrContains(sound, "vo/taunts/spy_highfive_success", false) != -1 && HighFive)
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
	if (IsClientInGame(entity) && StrContains(sound, "vo/taunts/pyro_highfive01", false) != -1 && HighFive)
	{
		if (rand == -1) rand = GetRandomInt(1,2);
		Format(sound, 128, "vo/taunts/pyro_highfive0%i.wav", rand);
		PrecacheSound(sound);
		return Plugin_Changed;
	}
	if (IsClientInGame(entity) && StrContains(sound, "vo/taunts/pyro_highfive_success02", false) != -1 && HighFive)
	{
		Format(sound, 128, "vo/taunts/pyro_highfive_success0%i.wav", GetRandomInt(1,2));
		PrecacheSound(sound);
		return Plugin_Changed;
	}
	if (IsClientInGame(entity) && StrContains(sound, "vo/spy_thanksfortheheal", false) != -1 && IFeelGood)
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

public CvarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	/* CVARS (5) */
	if (convar == cvarEnabled) Enabled = bool:StringToInt(newValue);
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
	else if (convar == cvarNPCCritSounds) NPCBlackBox = bool:StringToInt(newValue);
}