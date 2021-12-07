/*SHADoW93 Abilities Pack 
 by SHADoW NiNE TR3S
 
 with some code snippets from:
 -MasterOfTheXP
 -Friagram
 -WliU
 -EP
 -Otokiru
 -jfrog
 -Wolvan

  ALL BOSS RAGES: 
   
	rage_kritzkrieg = kritzkrieg effect
		arg0 = ability slot
		arg1 = duration

	rage_hidden_uber = hidden ubercharge
		arg0 = ability slot
		arg1 = duration

	rage_taunt_slide = the good old taunt sliding animation killed in FF2 1.10.x
		arg0 = ability slot

	rage_invisbility_spell = mode matters if you are a knife-based spy boss as mode 0 uncloaked when attacking, and mode 1 recloaks you.
		arg0 = ability slot
 		arg1 = type (0 = TFCond_Stealthed, 1 = TFCond_StealthedUserBuffFade)
		arg2 = duration

	rage_vaccinator = become resistant to bullet damage
		arg0 = ability slot
		arg1 = resistance type 
			-1 = Random
			0 = All Resistances
			1 = Bullet
			2 = Blast
			3 = Fire
			4 = Bullet + Blast
			5 = Bullet + Fire
			6 = Blast + Fire
		arg2 = duration

	effect_classreaction = voice reactions from non-boss team
		arg0 = ability slot

	rage_swimming_curse = Submerge everyone.
		arg0 =  ability slot
		arg1 =	Duration

	rage_minify = Minify Spell
		arg0 = Ability slot
		arg1 = 0 = Boss, 1 = Players, 2 = Boss & Players
		arg2 = Duration
		arg3 = Range (setting to 0 uses ragedist)

	rage_giants = Giant Spell
		arg0 = Ability slot
		arg1 = 0 = Boss, 1 = Players, 2 = Boss & Players
		arg2 = Duration
		arg3 = Range (setting to 0 uses ragedist)

	rage_summon = modified version of Otokiru's charge_salmon for use as rage, can be used for any boss however
		arg0 = ability slot
		arg1 = sound
		arg2 = summon per rage
			-1 = ratio
			0 = # of alive players
			above 0 = fixed amount
		arg3 = uber protection
		arg4 = notification
		arg5 = human/custom model or robots?
			0 = human / custom model
			1 = robot
		arg6 = model path (if using custom model, leave black for human models)
		arg7 = player class, leave blank to not change it
		arg8 = ratio, if arg2 is -1
		arg9 = remove wearables?
		arg10 = weapon mode 
			0 = normal loadout
			1 = user defined
			2 = no weapons
		arg11 = weapon classname (if arg10 is 1)
		arg12 = weapon index (if arg10 is 1)
		arg13 = weapon attributes (if arg10 is 1)
		arg14 = engy / spy accessories ( if arg10 is 1)
			1 = sapper (spy) / build tools (engineer)
			the following values below only apply for spy minions:
			2 = disguise kit
			3 = cloak
			4 = dead ringer
			5 = disguise + cloak
			6 = disguise + dead ringer
			7 = cloak + sapper
			8 = dead ringer + sapper
			9 = disguise + sapper
			10 = disguise + cloak + sapper
			11 = disguise + dead ringer + sapper
		arg15 = health
			-1 = health formula of ((bossmHP)/ bosslives)/minions spawned, or if single life, (bossmHP)/minions spawned.
			0 = no extra hp
			above 0 = constant health value (overheal)
		arg16 = teleport to summoner's location
		arg17 = minion's ammo
		arg18 = minion's clip size
		arg19 = minion voice lines?
			-1 = block voice lines
			0 = regular voice lines
			1 = robot voice lines
			2 = giant robot voice lines
		arg20 = pickups mode
			0 = none
			1 = health
			2 = ammo
			3 = health & ammo
			
	charge_summon = v2 of Otokiru's Salmon
		arg0 = 1
		arg1 = Charge Time
		arg2 = Cooldown Time
		arg3 = sound
		arg4 = summon per rage
			-1 = ratio
			0 = # of alive players
			above 0 = fixed amount
		arg5 = uber protection
		arg6 = RAGE cost, if applicable
		arg7 = notification
		arg8 = human/custom model or robots?
			0 = human / custom model
			1 = robot
		arg9 = model path (if using custom model, leave black for human models)
		arg10 = player class, leave blank to not change it
		arg11 = ratio, if arg2 is -1
		arg12 = remove wearables?
		arg13 = weapon mode 
			0 = normal loadout
			1 = user defined
			2 = no weapons
		arg14 = weapon classname (if arg10 is 1)
		arg15 = weapon index (if arg10 is 1)
		arg16 = weapon attributes (if arg10 is 1)
		arg17 = engy / spy accessories ( if arg10 is 1)
			1 = sapper (spy) / build tools (engineer)
			the following values below only apply for spy minions:
			2 = disguise kit
			3 = cloak
			4 = dead ringer
			5 = disguise + cloak
			6 = disguise + dead ringer
			7 = cloak + sapper
			8 = dead ringer + sapper
			9 = disguise + sapper
			10 = disguise + cloak + sapper
			11 = disguise + dead ringer + sapper
		arg18 = health
			-1 = health formula of ((bossmHP)/ bosslives)/minions spawned, or if single life, (bossmHP)/minions spawned.
			0 = no extra hp
			above 0 = constant health value (overheal)
		arg19 = teleport to summoner's location
		arg20 = minion's ammo
		arg21 = minion's clip size
		arg22 = minion voice lines?
			-1 = block voice lines
			0 = regular voice lines
			1 = robot voice lines
			2 = giant robot voice lines
		arg23 = pickups mode
			0 = none
			1 = health
			2 = ammo
			3 = health & ammo
	
	rage_thriller_taunt
		arg0 =  ability slot
		arg1 = # of dances
		arg2 = Range (0 to use ff2 default ragedist)

	rage_buildable
		arg0 = ability slot
		arg1 = buildable type index
		arg2 = Hint notification
		arg3 = Sound notification
		arg4 = Amount of metal given, if engineer build tools
		arg5 = Wrangler? if engineer build tools

	critboost
		No args. Passive on round start.
	giantboss
		No args. Passive on round start
	roboticize
		arg1: Robot voice lines mode
			0: Normal
			2: Giant
	intromusic
		arg1: Path to sound
	outtromusic
		arg1: Custom track or block round result track?
			0 = block track
			1 = custom track
		arg2: Path to boss victory track
			if arg3/arg4 is not specified, it will use arg2's track
		arg3: Path to boss defeat track
		arg4: Path to stalemate track
	save_me
		arg1 = how much damage required to teleport
		arg2 = how much RAGE to give
		arg3 = stun duration
*/


#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2items>
#include <tf2_stocks>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>
#define MB 3
#define ME 2048

#undef REQUIRE_PLUGIN
#tryinclude <updater>

#define MANN_SND "ambient/siren.wav"
#define BUILDABLE_SND "ui/message_update.wav"

// Class Reaction Lines
static const String:ScoutReact[][] = {
	"vo/scout_sf13_magic_reac03.wav",
	"vo/scout_sf13_magic_reac07.wav",
	"vo/scout_sf12_badmagic04.wav"
};

static const String:SoldierReact[][] = {
	"vo/soldier_sf13_magic_reac03.wav",
	"vo/soldier_sf12_badmagic07.wav",
	"vo/soldier_sf12_badmagic13.wav"
};

static const String:PyroReact[][] = {
	"vo/pyro_autodejectedtie01.wav",
	"vo/pyro_painsevere02.wav",
	"vo/pyro_painsevere04.wav"
};

static const String:DemoReact[][] = {
	"vo/demoman_sf13_magic_reac05.wav",
	"vo/demoman_sf13_bosses02.wav",
	"vo/demoman_sf13_bosses03.wav",
	"vo/demoman_sf13_bosses04.wav",
	"vo/demoman_sf13_bosses05.wav",
	"vo/demoman_sf13_bosses06.wav"
};

static const String:HeavyReact[][] = {
	"vo/heavy_sf13_magic_reac01.wav",
	"vo/heavy_sf13_magic_reac03.wav",
	"vo/heavy_cartgoingbackoffense02.wav",
	"vo/heavy_negativevocalization02.wav",
	"vo/heavy_negativevocalization06.wav"
};

static const String:EngyReact[][] = {
	"vo/engineer_sf13_magic_reac01.wav",
	"vo/engineer_sf13_magic_reac02.wav",
	"vo/engineer_specialcompleted04.wav",
	"vo/engineer_painsevere05.wav",
	"vo/engineer_negativevocalization12.wav"
};

static const String:MedicReact[][] = {
	"vo/medic_sf13_magic_reac01.wav",
	"vo/medic_sf13_magic_reac02.wav",
	"vo/medic_sf13_magic_reac03.wav",
	"vo/medic_sf13_magic_reac04.wav",
	"vo/medic_sf13_magic_reac07.wav"
};

static const String:SniperReact[][] = {
	"vo/sniper_sf13_magic_reac01.wav",
	"vo/sniper_sf13_magic_reac02.wav",
	"vo/sniper_sf13_magic_reac04.wav"
};

static const String:SpyReact[][] = {
	"vo/Spy_sf13_magic_reac01.wav",
	"vo/Spy_sf13_magic_reac02.wav",
	"vo/Spy_sf13_magic_reac03.wav",
	"vo/Spy_sf13_magic_reac04.wav",
	"vo/Spy_sf13_magic_reac05.wav",
	"vo/Spy_sf13_magic_reac06.wav"
};

// Version Number

#define MAJOR_REVISION "1"
#define MINOR_REVISION "10"
#define PATCH_REVISION "6"

#if !defined PATCH_REVISION
	#define PLUGIN_VERSION MAJOR_REVISION..."."...MINOR_REVISION
#else
	#define PLUGIN_VERSION MAJOR_REVISION..."."...MINOR_REVISION..."."...PATCH_REVISION
#endif

#if defined _updater_included
#define UPDATE_URL "http://www.shadow93.info/tf2/tf2plugins/abilityplugin/update.txt"
#endif


new sBoss, dances, affectuber;

// Charge Stuff
new Handle:jumpHUD, Handle:OnHaleJump = INVALID_HANDLE;
new bEnableSuperDuperJump[3];

// Salmon System / VO Tweaks
new SummonerIndex[MAXPLAYERS+1];
new bool:IsGiantRobot[MAXPLAYERS+1] = false, bool:IsRobot[MAXPLAYERS+1] = false, bool:HasNoVoice[MAXPLAYERS+1] = false;
new Float:mRatio, Float:rCost;
new String:mModel[PLATFORM_MAX_PATH], String:mClassname[64], String:mAttributes[768];
new mSound, bMinion, uDuration, mNotify, mMode, mClass, weMode, wMode, wIndex, mAcc, mHP, mTele, mAmmo, mClip, VOMode, mPickup;

// Reanimators
new decaytime;
new reviveMarker[MAXPLAYERS+1];
new bool:ChangeClass[MAXPLAYERS+1] = { false, ... };
new bool: revivemarkers = false;
new currentTeam[MAXPLAYERS+1] = {0, ... };
new Handle: decayTimers[MAXPLAYERS+1] = { INVALID_HANDLE, ... };


// Outtro Track Bool
new bool: HasOuttro = false;
new bool: NoMusic = false;
new String: VictoryTrack[PLATFORM_MAX_PATH];
new String: DefeatTrack[PLATFORM_MAX_PATH];
new String: StalemateTrack[PLATFORM_MAX_PATH];
public OnMapStart()
{
	// Notification Sounds
	PrecacheSound(MANN_SND,true);
	PrecacheSound(BUILDABLE_SND,true);
	// Class Voice Reaction Lines
	for (new i = 0; i < sizeof(ScoutReact); i++)
	{
		PrecacheSound(ScoutReact[i], true);
	}
	for (new i = 0; i < sizeof(SoldierReact); i++)
	{
		PrecacheSound(SoldierReact[i], true);
	}
	for (new i = 0; i < sizeof(PyroReact); i++)
	{
		PrecacheSound(PyroReact[i], true);
	}
	for (new i = 0; i < sizeof(DemoReact); i++)
	{
		PrecacheSound(DemoReact[i], true);
	}
	for (new i = 0; i < sizeof(HeavyReact); i++)
	{
		PrecacheSound(HeavyReact[i], true);
	}
	for (new i = 0; i < sizeof(EngyReact); i++)
	{
		PrecacheSound(EngyReact[i], true);
	}
	for (new i = 0; i < sizeof(MedicReact); i++)
	{
		PrecacheSound(MedicReact[i], true);
	}
	for (new i = 0; i < sizeof(SniperReact); i++)
	{
		PrecacheSound(SniperReact[i], true);
	}
	for (new i = 0; i < sizeof(SpyReact); i++)
	{
		PrecacheSound(SpyReact[i], true);
	}
	// Translations file
	LoadTranslations("ff2_shadow93.phrases");
	jumpHUD = CreateHudSynchronizer();
	// Ugh, y u no precache?
	PrecacheSound("mvm/giant_common/giant_common_step_01.wav", true);
	PrecacheSound("mvm/giant_common/giant_common_step_02.wav", true);
	PrecacheSound("mvm/giant_common/giant_common_step_03.wav", true);
	PrecacheSound("mvm/giant_common/giant_common_step_04.wav", true);
	PrecacheSound("mvm/giant_common/giant_common_step_05.wav", true);
	PrecacheSound("mvm/giant_common/giant_common_step_06.wav", true);
	PrecacheSound("mvm/giant_common/giant_common_step_07.wav", true);
	PrecacheSound("mvm/giant_common/giant_common_step_08.wav", true);
}


public Plugin:myinfo = {
	name = "Freak Fortress 2: SHADoW93's Abilities Pack",
	author = "SHADoW NiNE TR3S",
	description="SHADoW NiNE TR3S'S Abilities Pack",
	version=PLUGIN_VERSION,
};

public OnPluginStart2()
{
	HookEvent("teamplay_round_start", OnSetup, EventHookMode_PostNoCopy);
	HookEvent("arena_round_start", RoundStart, EventHookMode_PostNoCopy);
	HookEvent("arena_win_panel", RoundEnd, EventHookMode_Pre);
	HookEvent("player_death", PlayerDeath, EventHookMode_Pre);
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Pre);
	HookEvent("teamplay_broadcast_audio", OnAnnounce, EventHookMode_Pre);
	HookEvent("player_changeclass", OnChangeClass);
	AddNormalSoundHook(SoundHook);
	#if defined _updater_included
	if (LibraryExists("updater"))
    {
		Updater_AddPlugin(UPDATE_URL);
	}
	#endif
}

public OnLibraryAdded(const String:name[])
{
	#if defined _updater_included
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
	#endif
}

public OnLibraryRemoved(const String:name[])
{
	#if defined _updater_included
	if(StrEqual(name, "updater"))
	{
		Updater_RemovePlugin();
	}
	#endif
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	OnHaleJump = CreateGlobalForward("VSH_OnDoJump", ET_Hook, Param_CellByRef);
}


public Action:FF2_OnAbility2(index,const String:plugin_name[],const String:ability_name[],action)
{
	new slot=FF2_GetAbilityArgument(index, this_plugin_name, ability_name, 0);
	if (!strcmp(ability_name,"rage_kritzkrieg")) 	// KRITZKRIEG
	{								
		new Boss=GetClientOfUserId(FF2_GetBossUserId(index));
		TF2_AddCondition(Boss,TFCond_Kritzkrieged,FF2_GetAbilityArgumentFloat(index,this_plugin_name,ability_name,1,5.0)); // Kritzkrieg
	}
	else if (!strcmp(ability_name,"rage_hidden_uber")) 	// Hidden uber
	{			
		new Boss=GetClientOfUserId(FF2_GetBossUserId(index));
		TF2_AddCondition(Boss,TFCond_UberchargedHidden,FF2_GetAbilityArgumentFloat(index,this_plugin_name,ability_name,1,5.0)); // Hidden Uber
	}
	else if (!strcmp(ability_name,"rage_taunt_slide")) 	// Taunt Sliding!!!!!
	{
		new Boss=GetClientOfUserId(FF2_GetBossUserId(index));
		FakeClientCommand(Boss,"taunt");
		CreateTimer(0.1, TauntSliding);
	}
	else if(!strcmp(ability_name, "rage_invisibility_spell"))  // Mode matters if the boss is a spy-based boss using a knife (tested on Koishi)
	{
		new Boss=GetClientOfUserId(FF2_GetBossUserId(index));
		new cloakmode=FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 1); // Cloak type
		new Float: cloakduration=FF2_GetAbilityArgumentFloat(index,this_plugin_name,ability_name, 2); // Cloak Duration
		switch(cloakmode)
		{
			case 1:
				TF2_AddCondition(Boss, TFCond:TFCond_StealthedUserBuffFade, cloakduration);
			case 0:
				TF2_AddCondition(Boss, TFCond:TFCond_Stealthed, cloakduration);
		}
	}
	else if(!strcmp(ability_name, "rage_vaccinator"))  // Vaccinator resistances
	{
		new Boss=GetClientOfUserId(FF2_GetBossUserId(index));
		new vacmode=FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 1); // Resistance type
		if(vacmode==-1) // Random resistance
			vacmode=GetRandomInt(0,6);
		if(vacmode==0||vacmode==1||vacmode==4||vacmode==5) // Bullet Resistance
		{
			TF2_AddCondition(Boss, TFCond_UberBulletResist, FF2_GetAbilityArgumentFloat(index,this_plugin_name,ability_name,2,5.0)); // Bullet Resistance
			TF2_AddCondition(Boss, TFCond_BulletImmune, FF2_GetAbilityArgumentFloat(index,this_plugin_name,ability_name,2,5.0)); // Shield portion
		}
		if(vacmode==0||vacmode==2||vacmode==4||vacmode==6) // Blast Resistance
		{
			TF2_AddCondition(Boss, TFCond_UberBlastResist, FF2_GetAbilityArgumentFloat(index,this_plugin_name,ability_name,2,5.0)); //Blast Resistance
			TF2_AddCondition(Boss, TFCond_BlastImmune, FF2_GetAbilityArgumentFloat(index,this_plugin_name,ability_name,2,5.0)); //Shield Portion
		}
		if(vacmode==0||vacmode==3||vacmode==5||vacmode==6) // Fire Resistance
		{
			TF2_AddCondition(Boss, TFCond_UberFireResist, FF2_GetAbilityArgumentFloat(index,this_plugin_name,ability_name,2,5.0)); //Fire Resistance
			TF2_AddCondition(Boss, TFCond_FireImmune, FF2_GetAbilityArgumentFloat(index,this_plugin_name,ability_name,2,5.0)); //Shield Portion
		}	
	}
	else if (!strcmp(ability_name,"effect_classreaction"))
	{
		for(new i = 1; i <= MaxClients; i++ )
		{
			ClassResponses(i);
		}
	}
	else if (!strcmp(ability_name,"rage_giant"))
	{
		new Float:pos[3], Float:pos2[3], Float:distance;
		new Boss=GetClientOfUserId(FF2_GetBossUserId(index));
		new giantmode=FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 1); // mode
		new Float:eDuration=FF2_GetAbilityArgumentFloat(index,this_plugin_name,ability_name, 2); // Effect Duration
		new Float:range=FF2_GetAbilityArgumentFloat(index,this_plugin_name,ability_name, 3);	//range
		if(range<1.0)
			range=FF2_GetRageDist(index, this_plugin_name, ability_name); // Use Ragedist if range is not set
		if(giantmode == 0 || giantmode == 2)
		{
			if(IsClientInGame(Boss) && IsPlayerAlive(Boss))
			{
				TF2_AddCondition(Boss, TFCond_HalloweenGiant, eDuration);
			}
		}
		if(giantmode == 1 || giantmode == 2)
		{
			for(new i = 1; i <= MaxClients; i++ )
			{
				if(IsClientInGame(i) && IsPlayerAlive(i))
				{
					GetEntPropVector(i, Prop_Send, "m_vecOrigin", pos2);
					distance = GetVectorDistance( pos, pos2 );
					if (distance < range && GetClientTeam(i)!=FF2_GetBossTeam())
					{
						TF2_AddCondition(i, TFCond_HalloweenGiant, eDuration);
					}
				}
			}
		}
	}
	else if (!strcmp(ability_name,"rage_minify"))						// Minify Spell
	{
		new Float:pos[3], Float:pos2[3], Float:distance;
		new Boss=GetClientOfUserId(FF2_GetBossUserId(index));
		new shrinkmode=FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 1); // mode
		new Float:eDuration=FF2_GetAbilityArgumentFloat(index,this_plugin_name,ability_name, 2); // Effect Duration
		new Float:range=FF2_GetAbilityArgumentFloat(index,this_plugin_name,ability_name, 3);	//range
		if(range<1.0)
			range=FF2_GetRageDist(index, this_plugin_name, ability_name); // Use Ragedist if range is not set
		if(shrinkmode == 0 || shrinkmode == 2)
		{
			TF2_AddCondition(Boss, TFCond_HalloweenTiny, eDuration);
		}
		if(shrinkmode == 1 || shrinkmode == 2)
		{
			for(new i = 1; i <= MaxClients; i++ )
			{
				if(IsClientInGame(i) && IsPlayerAlive(i))
				{
					GetEntPropVector(i, Prop_Send, "m_vecOrigin", pos2);
					distance = GetVectorDistance( pos, pos2 );
					if (distance < range && GetClientTeam(i)!=FF2_GetBossTeam())
					{
						TF2_AddCondition(i, TFCond_HalloweenTiny, eDuration);
					}
				}
			}
		}
	}
	else if (!strcmp(ability_name,"rage_swimming_curse")) // Swimming Curse
	{
		new Float:eDuration=FF2_GetAbilityArgumentFloat(index,this_plugin_name,ability_name, 1); // Effect Duration
		for(new i = 1; i <= MaxClients; i++ )
		{
			if(IsClientInGame(i) && IsPlayerAlive(i))
			{
				TF2_AddCondition(i, TFCond_SwimmingCurse, eDuration);
			}
		}
	}
	else if (!strcmp(ability_name,"rage_salmon"))
	{
		new String:name[64];
		FF2_GetBossSpecial(index, name, sizeof(name));
		PrintToServer("[FF2] Warning: \"rage_salmon\" has been deprecated and will be removed soon! Please replace with \"rage_summon\" on %s's config", name);
		Rage_Salmon(ability_name, index);					// Deprecated, please use RAGE_SUMMON!
	}
	else if (!strcmp(ability_name,"rage_summon"))
		Rage_Salmon(ability_name, index);					// Otokiru's Charge_Salmon converted to normal rage.
	else if (!strcmp(ability_name,"charge_summon"))
		Charge_Salmon(ability_name,index,slot,action);			// Upgraded version of Otokiru's Charge_Salmon
	else if (!strcmp(ability_name,"rage_thriller_taunt"))
	{
		new Boss=GetClientOfUserId(FF2_GetBossUserId(index));
		new Float:pos[3], Float:pos2[3], Float:distance;
		dances=FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 1);        // Number of times
		affectuber=FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 2);        // Affect ubercharged players?
		new Float:range=FF2_GetAbilityArgumentFloat(index,this_plugin_name,ability_name, 3);	//range
		if(range<1)
			range=FF2_GetRageDist(index, this_plugin_name, ability_name); // Use Ragedist if range is not set
		GetEntPropVector(Boss, Prop_Send, "m_vecOrigin", pos);
		for(new i=1; i<=MaxClients; i++)
		{
			if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i)!= FF2_GetBossTeam())
			{
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", pos2);
				distance = GetVectorDistance( pos, pos2 );
				if (distance < range && GetClientTeam(i)!=FF2_GetBossTeam())
				{
					switch(affectuber)
					{
						case 1:
						{
							if(TF2_IsPlayerInCondition(i, TFCond_Taunting))
								TF2_RemoveCondition(i,TFCond_Taunting);
							TF2_AddCondition(i, TFCond:TFCond_HalloweenThriller, 3.0);
							FakeClientCommand(i, "taunt");
						}
						default:
						{
							if(!TF2_IsPlayerInCondition(i,TFCond_Ubercharged))
							{
								if(TF2_IsPlayerInCondition(i, TFCond_Taunting))
									TF2_RemoveCondition(i,TFCond_Taunting);
								SetVariantInt(0);
								AcceptEntityInput(i, "SetForcedTauntCam");
								TF2_AddCondition(i, TFCond:TFCond_HalloweenThriller, 3.0);
								FakeClientCommand(i, "taunt");
							}
						}
					}
					if(dances!=0)
					{
						if(dances>=1)
							CreateTimer(3.0, ThrillerTaunt);
						if(dances>1)
							CreateTimer(6.0, ThrillerTaunt);
						if(dances==3)
							CreateTimer(9.0, ThrillerTaunt);
					}
				}
			}
		}
	}
	else if (!strcmp(ability_name,"rage_buildable"))
	{
		new entity;
		new Boss=GetClientOfUserId(FF2_GetBossUserId(index));
		new buildable=FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 1); //buildable index
		new bSound=FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 2); //sound alert
		new bNotify=FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 3); //notification
		if(bSound!=0)
			EmitSoundToAll(BUILDABLE_SND);
		switch(buildable)
		{
			case 25, 26, 28, 737:
			{
				new metal=FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 4);	// Extra Metal?
				new wrangler=FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 5);	// Wrangler?
				SpawnWeapon(Boss, "tf_weapon_pda_engineer_build", 25, 101, 5, "292 ; 3 ; 293 ; 59 ; 391 ; 2 ; 495 ; 60"); // Build PDA
				SpawnWeapon(Boss, "tf_weapon_pda_engineer_destroy", 26, 101, 5, "391 ; 2"); // Destroy PDA
				entity = SpawnWeapon(Boss, "tf_weapon_builder", 28, 101, 5, "391 ; 2"); // Builder
				SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", 1, _, 0);
				SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", 1, _, 1);
				SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", 1, _, 2);
				SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", 0, _, 3);
				if(bNotify!=0)
					PrintHintText(Boss, "%t", "build_notification");
				if(metal)
					SetEntData(Boss, FindDataMapOffs(Boss, "m_iAmmo") + (3 * 4), metal, 4);
				if(wrangler)
				{
					TF2_RemoveWeaponSlot(Boss, TFWeaponSlot_Secondary);
					SpawnWeapon(Boss, "tf_weapon_laser_pointer", 1086, 101, 5, "292 ; 86"); // Wrangler
				}
			}
			case 735, 736, 810, 831, 933, 1080, 1102:
			{
				switch(buildable)
				{
					case 735, 736: // Sapper
						entity = SpawnWeapon(Boss, "tf_weapon_builder", 735, 101, 5, "391 ; 2");
					case 810, 831: // Red Tape Recorder
						entity = SpawnWeapon(Boss, "tf_weapon_sapper", 810, 101, 5, "426 ; 0 ; 433 ; 0.5 ; 391 ; 2");
					case 933: // Ap-sap
						entity = SpawnWeapon(Boss, "tf_weapon_sapper", 933, 101, 5, "451 ; 1 ; 452 ; 3 ; 391 ; 2");
					case 1080: // Festive Sapper
						entity = SpawnWeapon(Boss, "tf_weapon_sapper", 1080, 101, 5, "391 ; 2");
					case 1102: // Snack Attack
						entity = SpawnWeapon(Boss, "tf_weapon_sapper", 1102, 101, 5, "391 ; 2");
				}
				SetEntProp(entity, Prop_Send, "m_iObjectType", 3);
				SetEntProp(entity, Prop_Data, "m_iSubType", 3);
				SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", 0, _, 0);
				SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", 0, _, 1);
				SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", 0, _, 2);
				SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", 1, _, 3);
				if(bNotify!=0)
					PrintHintText(Boss, "%t", "sap_notification");
			}
		}
	}
}

// Taunt Slide
public Action:TauntSliding(Handle:hTimer,any:userid)
{
	new Boss=GetClientOfUserId(FF2_GetBossUserId(userid));
	if (!GetEntProp(Boss, Prop_Send, "m_bIsReadyToHighFive") && !IsValidEntity(GetEntPropEnt(Boss, Prop_Send, "m_hHighFivePartner")))
	{
		TF2_RemoveCondition(Boss,TFCond_Taunting);
		new Float:up[3];
		up[2]=220.0;
		TeleportEntity(Boss,NULL_VECTOR, NULL_VECTOR,up);
	}
	else if(TF2_IsPlayerInCondition(Boss, TFCond_Taunting))
	{
		TF2_RemoveCondition(Boss,TFCond_Taunting);
	}
	return Plugin_Continue;
}	


// Player Spawn
public Action:OnPlayerSpawn(Handle:event, const String:name[], bool:dontbroadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	CreateTimer(0.1, CheckIndex, client); // I know, it's a weird way to do this, but it is what it is.
	if(revivemarkers)
	{
		RemoveReanimator(client);
	}
	return Plugin_Continue;
}

public Action:CheckIndex(Handle:hTimer, any:client) // Checking Index
{
	CreateTimer(0.1, CheckAbility, client);
}

public Action:CheckAbility(Handle:hTimer, any: client) // Now we actually check for abilities
{
	new boss=GetClientOfUserId(FF2_GetBossUserId(client));
	new b0ss=FF2_GetBossIndex(client);
	
	if(FF2_HasAbility(b0ss, this_plugin_name, "intromusic"))
	{
		new String: INTRO[PLATFORM_MAX_PATH];
		FF2_GetAbilityArgumentString(boss, this_plugin_name, "intromusic", 1, INTRO, PLATFORM_MAX_PATH);
		if(INTRO[0] != '\0')
		{
			PrecacheSound(INTRO, true);
			EmitSoundToAll(INTRO);
		}
	}

	if(FF2_HasAbility(b0ss, this_plugin_name, "outtromusic"))
	{
		new type = FF2_GetAbilityArgument(boss,this_plugin_name,"outtromusic", 1);
		switch(type)
		{
			case 1:
			{
				FF2_GetAbilityArgumentString(boss,this_plugin_name,"outtromusic",2,VictoryTrack,PLATFORM_MAX_PATH);
				FF2_GetAbilityArgumentString(boss,this_plugin_name,"outtromusic",3,DefeatTrack,PLATFORM_MAX_PATH);
				FF2_GetAbilityArgumentString(boss,this_plugin_name,"outtromusic",4,StalemateTrack,PLATFORM_MAX_PATH);
				if(VictoryTrack[0] != '\0')
				{
					PrecacheSound(VictoryTrack, true);
				}
				
				if(DefeatTrack[0] != '\0')
				{
					PrecacheSound(DefeatTrack, true);
				}
				else
				{
					DefeatTrack = VictoryTrack;
					PrecacheSound(DefeatTrack, true);
				}
	
				if(StalemateTrack[0] != '\0')
				{
					PrecacheSound(StalemateTrack, true);
				}
				else
				{
					StalemateTrack = VictoryTrack;
					PrecacheSound(StalemateTrack, true);
				}
				HasOuttro = true;
			}
			
			default:
				NoMusic = true;
		}
	}
}


// Round Setup
public Action:OnSetup(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (FF2_IsFF2Enabled())
	{
		revivemarkers = false;
		HasOuttro = false;
		NoMusic = false;
		for(new i=1;i<MAXPLAYERS+1;i++)
		{
			if(IsClientInGame(i) && IsClientConnected(i))
			{
				SummonerIndex[i]=-1;
				bEnableSuperDuperJump[i]=false;
			}
		}
	}
}

public Action:RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (FF2_IsFF2Enabled())
	{
		sBoss = GetClientOfUserId(FF2_GetBossUserId());
		if(sBoss>0)
		{
			if (FF2_HasAbility(0, this_plugin_name, "critboost"))
			{	
				TF2_AddCondition(sBoss, TFCond_CritCanteen, TFCondDuration_Infinite);
			}

			if (FF2_HasAbility(0, this_plugin_name, "giantboss"))
			{	
				TF2_AddCondition(sBoss, TFCond_HalloweenGiant, TFCondDuration_Infinite);
			}
	
			if (FF2_HasAbility(0, this_plugin_name, "roboticize"))
			{	
				new botmode=FF2_GetAbilityArgument(0,this_plugin_name,"roboticize", 1);
				if(botmode)
					IsGiantRobot[sBoss] = true;
				else
					IsRobot[sBoss] = true;
			}
	
			if(FF2_HasAbility(0, this_plugin_name, "revive_markers"))
			{
				revivemarkers = true;
				decaytime=FF2_GetAbilityArgument(0,this_plugin_name,"revive_markers", 1); // Reanimator decay time
			}
		}
	}
}

// Round End
public Action:RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (IsValidClient(sBoss))
	{
		if(TF2_IsPlayerInCondition(sBoss, TFCond_CritCanteen) &&  IsPlayerAlive(sBoss))
			TF2_RemoveCondition(sBoss, TFCond_CritCanteen);
	}
	for(new i = 1; i <= MaxClients; i++ )
	{
		if(IsClientInGame(i))
		{
			if(IsGiantRobot[i] || IsRobot[i] || HasNoVoice[i])
			{
				IsGiantRobot[i] = false;
				IsRobot[i] =false;
				HasNoVoice[i] = false;
			}
			if(IsPlayerAlive(i))
			{
				if(TF2_IsPlayerInCondition(i, TFCond_HalloweenGiant))
					TF2_RemoveCondition(i, TFCond_HalloweenGiant);
				if(TF2_IsPlayerInCondition(i, TFCond_HalloweenTiny))
					TF2_RemoveCondition(i, TFCond_HalloweenTiny);
			}
		}
	}
	if(HasOuttro)
	{
		if (GetEventInt(event, "winning_team") == FF2_GetBossTeam())
			EmitSoundToAll(VictoryTrack);
		else if (GetEventInt(event, "winning_team") != FF2_GetBossTeam())
			EmitSoundToAll(DefeatTrack);
		else
			EmitSoundToAll(StalemateTrack);
	}
}

public Action:OnAnnounce(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(HasOuttro || NoMusic)
	{
		new String:strAudio[PLATFORM_MAX_PATH];
		GetEventString(event, "sound", strAudio, sizeof(strAudio));
		if(strncmp(strAudio, "Game.Your", 9) == 0 || strcmp(strAudio, "Game.Stalemate") == 0)
		{
			return Plugin_Handled;
		}
		return Plugin_Continue;
	}
	return Plugin_Continue;
}


// Thriller Taunt
public Action:ThrillerTaunt(Handle:hTimer,any:userid)
{
	new Boss=GetClientOfUserId(FF2_GetBossUserId(userid));
	new Float:range=FF2_GetAbilityArgumentFloat(userid,this_plugin_name,"rage_thriller_taunt", 3);	//range
	new Float:pos[3], Float:pos2[3], Float:distance;
	distance = GetVectorDistance( pos, pos2 );
	GetEntPropVector(Boss, Prop_Send, "m_vecOrigin", pos);
	for(new i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i)!=FF2_GetBossTeam())
		{
			GetEntPropVector(i, Prop_Send, "m_vecOrigin", pos2);
			distance = GetVectorDistance( pos, pos2 );
			if (distance < range && GetClientTeam(i)!=FF2_GetBossTeam())
			{
				switch(affectuber)
				{
					case 1:
					{
						SetVariantInt(0);
						AcceptEntityInput(i, "SetForcedTauntCam");
						if(TF2_IsPlayerInCondition(i, TFCond_Taunting))
							TF2_RemoveCondition(i,TFCond_Taunting);
						if(TF2_IsPlayerInCondition(i, TFCond_HalloweenThriller))
							TF2_RemoveCondition(i,TFCond_Taunting);
						TF2_AddCondition(i, TFCond:TFCond_HalloweenThriller, 3.0);
						FakeClientCommand(i, "taunt");
					}
					case 0:
					{
						if(!TF2_IsPlayerInCondition(i,TFCond_Ubercharged))
						{
							SetVariantInt(0);
							AcceptEntityInput(i, "SetForcedTauntCam");
							if(TF2_IsPlayerInCondition(i, TFCond_Taunting))
								TF2_RemoveCondition(i,TFCond_Taunting);
							if(TF2_IsPlayerInCondition(i, TFCond_HalloweenThriller))
								TF2_RemoveCondition(i,TFCond_Taunting);
							TF2_AddCondition(i, TFCond:TFCond_HalloweenThriller, 3.0);
							FakeClientCommand(i, "taunt");
						}
					}
				}
			}
		}
	}    
	return Plugin_Continue;
}


// Death Event
public Action:PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new String:weapon[50], String:oldweapon[64], String:newweapon[64];
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	new attacker=GetClientOfUserId(GetEventInt(event, "attacker"));
	new client=GetClientOfUserId(GetEventInt(event, "userid"));
	new boss=FF2_GetBossIndex(client);
	new b0ss=FF2_GetBossIndex(attacker);
	
	if((attacker!=client || attacker==client)&& !(GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER))
	{
		IsGiantRobot[client] =  false;
		IsRobot[client] = false; 
		HasNoVoice[client] = false;
		if(revivemarkers && boss == -1)
			DropReanimator(client);
		if(GetClientTeam(client) == FF2_GetBossTeam())
			ChangeClientTeam(client, (FF2_GetBossTeam()==_:TFTeam_Blue) ? (_:TFTeam_Red) : (_:TFTeam_Blue));
	}
	
	if(boss!=-1 || b0ss!=-1)
	{
		if(FF2_HasAbility(b0ss, this_plugin_name, "killfeed_icon"))
		{
			FF2_GetAbilityArgumentString(b0ss, this_plugin_name, "killfeed_icon", 1, oldweapon, sizeof(oldweapon));
			FF2_GetAbilityArgumentString(b0ss, this_plugin_name, "killfeed_icon", 2, newweapon, sizeof(newweapon));
			if(StrEqual(weapon, oldweapon, false))
				SetEventString(event, "weapon", newweapon);
		}
		
		if(!(GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER))
		{
			for(new clone=1; clone<=MaxClients; clone++)
			{
				if((attacker==boss || attacker!=boss) && SummonerIndex[clone]==boss && IsClientInGame(clone) && IsPlayerAlive(clone) && GetClientTeam(clone)==FF2_GetBossTeam())
				{
					IsGiantRobot[client] =  false;
					IsRobot[client] = false; 
					HasNoVoice[client] = false;
					SummonerIndex[clone]=-1;
					ChangeClientTeam(clone, (FF2_GetBossTeam()==_:TFTeam_Blue) ? (_:TFTeam_Red) : (_:TFTeam_Blue));
				}
			}
		}
	}
}

// Revive Marker stocks from Wolvan's revive markers plugin //

stock DropReanimator(client) 
{
	new clientTeam = GetClientTeam(client);
	reviveMarker[client] = CreateEntityByName("entity_revive_marker");
	if (reviveMarker[client] != -1)
	{
		SetEntPropEnt(reviveMarker[client], Prop_Send, "m_hOwner", client); // client index 
		SetEntProp(reviveMarker[client], Prop_Send, "m_nSolidType", 2); 
		SetEntProp(reviveMarker[client], Prop_Send, "m_usSolidFlags", 8); 
		SetEntProp(reviveMarker[client], Prop_Send, "m_fEffects", 16); 	
		SetEntProp(reviveMarker[client], Prop_Send, "m_iTeamNum", clientTeam); // client team 
		SetEntProp(reviveMarker[client], Prop_Send, "m_CollisionGroup", 1); 
		SetEntProp(reviveMarker[client], Prop_Send, "m_bSimulatedEveryTick", 1); 
		SetEntProp(reviveMarker[client], Prop_Send, "m_nBody", _:TF2_GetPlayerClass(client) - 1); 
		SetEntProp(reviveMarker[client], Prop_Send, "m_nSequence", 1); 
		SetEntPropFloat(reviveMarker[client], Prop_Send, "m_flPlaybackRate", 1.0);  
		SetEntProp(reviveMarker[client], Prop_Data, "m_iInitialTeamNum", clientTeam);
		SetEntDataEnt2(client, FindSendPropInfo("CTFPlayer", "m_nForcedSkin")+4, reviveMarker[client]);
		if(GetClientTeam(client) == 3)
			SetEntityRenderColor(reviveMarker[client], 0, 0, 255); // make the BLU Revive Marker distinguishable from the red one
		DispatchSpawn(reviveMarker[client]);
		CreateTimer(0.1, MoveMarker, GetClientUserId(client));
		if(decayTimers[client] == INVALID_HANDLE) 
		{
			decayTimers[client] = CreateTimer(float(decaytime), TimeBeforeRemoval, GetClientUserId(client));
		}
	} 
}

public Action:MoveMarker(Handle:timer, any:userid) 
{
	new client = GetClientOfUserId(userid);
	new Float:position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	TeleportEntity(reviveMarker[client], position, NULL_VECTOR, NULL_VECTOR);
}

stock RemoveReanimator(client)
{
	currentTeam[client] = GetClientTeam(client);
	ChangeClass[client] = false;
	if (IsValidMarker(reviveMarker[client])) 
	{
		AcceptEntityInput(reviveMarker[client], "Kill");
	} 
	if (decayTimers[client] != INVALID_HANDLE) 
	{
		KillTimer(decayTimers[client]);
		decayTimers[client] = INVALID_HANDLE;
	}
}

public bool:IsValidMarker(marker) 
{
	if (IsValidEntity(marker)) 
	{
		decl String:buffer[128];
		GetEntityClassname(marker, buffer, sizeof(buffer));
		if (strcmp(buffer,"entity_revive_marker",false) == 0)
		{
			return true;
		}
	}
	return false;
}

public Action:TimeBeforeRemoval(Handle:timer, any:userid) 
{
	new client = GetClientOfUserId(userid);
	if(!IsValidMarker(reviveMarker[client]) || !IsClientInGame(client)) 
		return Plugin_Handled;
	RemoveReanimator(client);
	if(decayTimers[client] != INVALID_HANDLE)
	{
		KillTimer(decayTimers[client]);
		decayTimers[client] = INVALID_HANDLE;
	}
	return Plugin_Continue;
}

public Action:OnChangeClass(Handle:event, const String:name[], bool:dontbroadcast) 
{
	if(revivemarkers)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		ChangeClass[client] = true;
	}
	return Plugin_Continue;
}

public OnClientDisconnect(client) 
{
	if(revivemarkers)
	{
		RemoveReanimator(client);
		currentTeam[client] = 0;
		ChangeClass[client] = false;
	}
}

// Stock

stock SpawnWeapon(client,String:name[],index,level,qual,String:att[])
{
	new Handle:hWeapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
	TF2Items_SetClassname(hWeapon, name);
	TF2Items_SetItemIndex(hWeapon, index);
	TF2Items_SetLevel(hWeapon, level);
	TF2Items_SetQuality(hWeapon, qual);
	new String:atts[32][32];
	new count = ExplodeString(att, " ; ", atts, 32, 32);
	if (count > 0)
	{
		TF2Items_SetNumAttributes(hWeapon, count/2);
		new i2 = 0;
		for (new i = 0; i < count; i+=2)
		{
			TF2Items_SetAttribute(hWeapon, i2, StringToInt(atts[i]), StringToFloat(atts[i+1]));
			i2++;
		}
	}
	else
		TF2Items_SetNumAttributes(hWeapon, 0);
	if (hWeapon==INVALID_HANDLE)
		return -1;
	new entity = TF2Items_GiveNamedItem(client, hWeapon);
	CloseHandle(hWeapon);
	EquipPlayerWeapon(client, entity);
	return entity;
}

stock SetAmmo(client, slot, ammo)
{
	new weapon = GetPlayerWeaponSlot(client, slot);
	if (IsValidEntity(weapon))
	{
		new iOffset = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1)*4;
		new iAmmoTable = FindSendPropInfo("CTFPlayer", "m_iAmmo");
		SetEntData(client, iAmmoTable+iOffset, ammo, 4, true);
	}
}

stock bool:IsValidClient(client)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	return true;
}

/////   RAGES	 /////

// Generic Class-Specific reaction lines for rage/death effect similar to rare spell reactions from Helltower


ClassResponses(client)
{
	if(IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client)!=FF2_GetBossTeam())
	{
		new String:Reaction[PLATFORM_MAX_PATH];
		switch(TF2_GetPlayerClass(client))
		{
			case TFClass_Scout: // Scout
			{
				strcopy(Reaction, PLATFORM_MAX_PATH, ScoutReact[GetRandomInt(0, sizeof(ScoutReact)-1)]);
				EmitSoundToAll(Reaction, client);
			}
			case TFClass_Soldier: // Soldier
			{
				strcopy(Reaction, PLATFORM_MAX_PATH, SoldierReact[GetRandomInt(0, sizeof(SoldierReact)-1)]);
				EmitSoundToAll(Reaction, client);
			}
			case TFClass_Pyro: // Pyro
			{
				strcopy(Reaction, PLATFORM_MAX_PATH, PyroReact[GetRandomInt(0, sizeof(PyroReact)-1)]);
				EmitSoundToAll(Reaction, client);
			}
			case TFClass_DemoMan: // DemoMan
			{
				strcopy(Reaction, PLATFORM_MAX_PATH, DemoReact[GetRandomInt(0, sizeof(DemoReact)-1)]);
				EmitSoundToAll(Reaction, client);
			}
			case TFClass_Heavy: // Heavy
			{
				strcopy(Reaction, PLATFORM_MAX_PATH, HeavyReact[GetRandomInt(0, sizeof(HeavyReact)-1)]);
				EmitSoundToAll(Reaction, client);
			}
			case TFClass_Engineer: // Engineer
			{
				strcopy(Reaction, PLATFORM_MAX_PATH, EngyReact[GetRandomInt(0, sizeof(EngyReact)-1)]);
				EmitSoundToAll(Reaction, client);
			}	
			case TFClass_Medic: // Medic
			{
				strcopy(Reaction, PLATFORM_MAX_PATH, MedicReact[GetRandomInt(0, sizeof(MedicReact)-1)]);
				EmitSoundToAll(Reaction, client);
			}
			case TFClass_Sniper: // Sniper
			{
				strcopy(Reaction, PLATFORM_MAX_PATH, SniperReact[GetRandomInt(0, sizeof(SniperReact)-1)]);
				EmitSoundToAll(Reaction, client);
			}
			case TFClass_Spy: // Spy
			{
				strcopy(Reaction, PLATFORM_MAX_PATH, SpyReact[GetRandomInt(0, sizeof(SpyReact)-1)]);
				EmitSoundToAll(Reaction, client);
			}
		}
	}
}

// Teleport Boss
Teleport_Me(client)
{
	new Float:pos_2[3], target, teleportme, bool:AlivePlayers;
	for(new ii=1;ii<=MaxClients;ii++)
	if(IsValidEdict(ii) && IsClientInGame(ii) && IsPlayerAlive(ii) && GetClientTeam(ii)!=FF2_GetBossTeam())
	{
		AlivePlayers=true;
		break;
	}
	do
	{
		teleportme++;
		target=GetRandomInt(1,MaxClients);
		if (teleportme==100)
			return;
	}
	while (AlivePlayers && (!IsValidEdict(target) || (target==client) || !IsPlayerAlive(target)));
	
	if (IsValidEdict(target))
	{
		GetEntPropVector(target, Prop_Data, "m_vecOrigin", pos_2);
		GetEntPropVector(target, Prop_Send, "m_vecOrigin", pos_2);
		if(GetEntProp(target, Prop_Send, "m_bDucked"))
		{
			new Float:temp[3]={24.0, 24.0, 62.0};
			SetEntPropVector(client, Prop_Send, "m_vecMaxs", temp);
			SetEntProp(client, Prop_Send, "m_bDucked", 1);
			SetEntityFlags(client, GetEntityFlags(client)|FL_DUCKING);
		}
		TeleportEntity(client, pos_2, NULL_VECTOR, NULL_VECTOR);
	}
}

// Modified version of Otokiru's Charge_Salmon

Rage_Salmon(const String:ability_name[],index)
{
	GetClientOfUserId(FF2_GetBossUserId(index));
	mSound=FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 1);	//sound
	bMinion=FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 2);	// Summon per rage if greater than 0, Summon by # of alive players if 0, Summon by ratio if -1
	uDuration=FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 3); // Spawn Protection
	mNotify=FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 4);	// notification alert
	mMode=FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 5);	// Model mode (Human/Custom model or bot models)
	FF2_GetAbilityArgumentString(index, this_plugin_name, ability_name, 6, mModel, sizeof(mModel)); // Human or custom model?
	mClass=FF2_GetAbilityArgument(index, this_plugin_name, ability_name, 7); // class name, if changing
	mRatio=FF2_GetAbilityArgumentFloat(index, this_plugin_name, ability_name, 8, 0.0);
	weMode=FF2_GetAbilityArgument(index, this_plugin_name, ability_name, 9); // wearable
	wMode=FF2_GetAbilityArgument(index, this_plugin_name, ability_name, 10); // weapon mode
	FF2_GetAbilityArgumentString(index, this_plugin_name, ability_name, 11, mClassname, sizeof(mClassname));
	wIndex=FF2_GetAbilityArgument(index, this_plugin_name, ability_name, 12);
	FF2_GetAbilityArgumentString(index, this_plugin_name, ability_name, 13, mAttributes, sizeof(mAttributes));
	mAcc=FF2_GetAbilityArgument(index, this_plugin_name, ability_name, 14);
	mHP=FF2_GetAbilityArgument(index, this_plugin_name, ability_name, 15, 0); // mHP
	mTele=FF2_GetAbilityArgument(index, this_plugin_name, ability_name, 16); // Teleport Minion?	
	mAmmo=FF2_GetAbilityArgument(index, this_plugin_name, ability_name, 17); // Ammo
	mClip=FF2_GetAbilityArgument(index, this_plugin_name, ability_name, 18); // Clip
	VOMode = FF2_GetAbilityArgument(index, this_plugin_name, ability_name, 19);	 // Voice lines
	mPickup = FF2_GetAbilityArgument(index, this_plugin_name, ability_name, 20); // mPickup?
	Salmon(index);
}

Charge_Salmon(const String:ability_name[],index,slot,action)
{
	new Float:charge=FF2_GetBossCharge(index,slot);
	new Float:bCharge = FF2_GetBossCharge(index,0);
	new Boss=GetClientOfUserId(FF2_GetBossUserId(index));
	mSound=FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 3);	//sound
	bMinion=FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 4);	// Summon per rage if greater than 0, Summon by # of alive players if 0, Summon by ratio if -1
	uDuration=FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 5); // Spawn Protection
	rCost = FF2_GetAbilityArgumentFloat(index, this_plugin_name, ability_name, 6);
	mNotify=FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 7);	// notification alert
	mMode=FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 8);	// Model mode (Human/Custom model or bot models)
	FF2_GetAbilityArgumentString(index, this_plugin_name, ability_name, 9, mModel, sizeof(mModel)); // Human or custom model?
	mClass=FF2_GetAbilityArgument(index, this_plugin_name, ability_name, 10); // class name, if changing
	mRatio=FF2_GetAbilityArgumentFloat(index, this_plugin_name, ability_name, 11, 0.0);
	weMode=FF2_GetAbilityArgument(index, this_plugin_name, ability_name, 12); // wearable
	wMode=FF2_GetAbilityArgument(index, this_plugin_name, ability_name, 13); // weapon mode
	FF2_GetAbilityArgumentString(index, this_plugin_name, ability_name, 14, mClassname, sizeof(mClassname));
	wIndex=FF2_GetAbilityArgument(index, this_plugin_name, ability_name, 15);
	FF2_GetAbilityArgumentString(index, this_plugin_name, ability_name, 16, mAttributes, sizeof(mAttributes));
	mAcc=FF2_GetAbilityArgument(index, this_plugin_name, ability_name, 17);
	mHP=FF2_GetAbilityArgument(index, this_plugin_name, ability_name, 18, 0); // mHP
	mTele=FF2_GetAbilityArgument(index, this_plugin_name, ability_name, 19); // Teleport Minion?	
	mAmmo=FF2_GetAbilityArgument(index, this_plugin_name, ability_name, 20); // Ammo
	mClip=FF2_GetAbilityArgument(index, this_plugin_name, ability_name, 21); // Clip
	VOMode = FF2_GetAbilityArgument(index, this_plugin_name, ability_name, 22);	 // Voice lines
	mPickup = FF2_GetAbilityArgument(index, this_plugin_name, ability_name, 23); // mPickup?
	if(rCost && !bEnableSuperDuperJump[index])
	{
		if(bCharge<rCost)
		{
			return;
		}
	}
	switch (action)
	{
		case 1:
		{
			switch(slot)
			{
				case 1:
					SetHudTextParams(-1.0, 0.88, 0.15, 255, 255, 255, 255);
				case 2:
					SetHudTextParams(-1.0, 0.93, 0.15, 255, 255, 255, 255);
			}
			ShowSyncHudText(Boss, jumpHUD, "%t","summon_status_2",-RoundFloat(charge));
		}	
		case 2:
		{
			switch(slot)
			{
				case 1:
					SetHudTextParams(-1.0, 0.88, 0.15, 255, 255, 255, 255);
				case 2:
					SetHudTextParams(-1.0, 0.93, 0.15, 255, 255, 255, 255);
			}
			if (bEnableSuperDuperJump[index])
			{
				SetHudTextParams(-1.0, 0.88, 0.15, 255, 64, 64, 255);
				ShowSyncHudText(Boss, jumpHUD,"%t","super_duper_jump");
			}	
			else
			{	
				ShowSyncHudText(Boss, jumpHUD, "%t","summon_status",RoundFloat(charge));
			}
		}
		case 3:
		{
			new Action:act = Plugin_Continue;
			new super = bEnableSuperDuperJump[index];
			Call_StartForward(OnHaleJump);
			Call_PushCellRef(super);
			Call_Finish(act);
			if (act != Plugin_Continue && act != Plugin_Changed)
				return;
			if (act == Plugin_Changed) bEnableSuperDuperJump[index] = super;
			
			if (bEnableSuperDuperJump[index])
			{
				new Float:vel[3];
				new Float:rot[3];
				GetEntPropVector(Boss, Prop_Data, "m_vecVelocity", vel);
				GetClientEyeAngles(Boss, rot);
				vel[2]=750.0+500.0*charge/70+2000;
				vel[0]+=Cosine(DegToRad(rot[0]))*Cosine(DegToRad(rot[1]))*500;
				vel[1]+=Cosine(DegToRad(rot[0]))*Sine(DegToRad(rot[1]))*500;
				bEnableSuperDuperJump[index]=false;
				TeleportEntity(Boss, NULL_VECTOR, NULL_VECTOR, vel);
			}
			else
			{
				if(charge<100)
				{
					CreateTimer(0.1, ResetCharge, index*10000+slot);
					return;					
				}
				if(rCost)
				{
					FF2_SetBossCharge(index,0,bCharge-rCost);
				}
				Salmon(index);
				new Float:position[3];
				new String:sound[PLATFORM_MAX_PATH];
				if(FF2_RandomSound("sound_ability", sound, PLATFORM_MAX_PATH, Boss, slot))
				{
					EmitSoundToAll(sound, Boss, _, _, _, _, _, Boss, position);
					EmitSoundToAll(sound, Boss, _, _, _, _, _, Boss, position);
					for(new enemy=1; enemy<=MaxClients; enemy++)
					{
						if(IsClientInGame(enemy) && enemy!=Boss)
						{
							EmitSoundToClient(enemy, sound, Boss, _, _, _, _, _, Boss, position);
							EmitSoundToClient(enemy, sound, Boss, _, _, _, _, _, Boss, position);
						}
					}
				}
			}			
		}
		default:
		{
			if(rCost && charge<=0.2 && !bEnableSuperDuperJump[index])
			{
				SetHudTextParams(-1.0, 0.93, 0.15, 255, 255, 255, 255);
				ShowSyncHudText(Boss, jumpHUD, "%t","summon_ready");
			}
		}
	}
	
}

public Action:ResetCharge(Handle:timer, any:index)
{
	new slot=index%10000;
	index/=1000;
	FF2_SetBossCharge(index, slot, 0.0);
}


Salmon(index) // Originally coded by Otokiru, upgraded by SHADoW93
{
	new weapon, Float:position[3], Float:velocity[3];
	new Boss=GetClientOfUserId(FF2_GetBossUserId(index));
	if(mSound!=0)
		EmitSoundToAll(MANN_SND);
	if(FF2_GetAlivePlayers()<bMinion || !bMinion) // Attempt to match # of Minions spawned with # of alive players if alive players are below the max # of bMinion boss can summon
		bMinion=FF2_GetAlivePlayers();
	if(bMinion==-1)
		bMinion=(mRatio ? RoundToCeil(FF2_GetAlivePlayers()*mRatio) : MaxClients);
	new ii;
	GetEntPropVector(Boss, Prop_Data, "m_vecOrigin", position);
	for (new i=0; i<bMinion; i++)
	{
		ii = GetRandomDeadPlayer();
		if(ii != -1)
		{
			FF2_SetFF2flags(ii,FF2_GetFF2flags(ii)|FF2FLAG_ALLOWSPAWNINBOSSTEAM);
			if(mPickup)
			{
				if(mPickup==1 || mPickup==3)
					FF2_SetFF2flags(ii,FF2_GetFF2flags(ii)|FF2FLAG_ALLOW_HEALTH_PICKUPS); // HP Pickup
				if(mPickup==2 || mPickup==3)
					FF2_SetFF2flags(ii,FF2_GetFF2flags(ii)|FF2FLAG_ALLOW_AMMO_PICKUPS); // Ammo Pickup
			}
			ChangeClientTeam(ii,FF2_GetBossTeam());
			TF2_RespawnPlayer(ii);
			SummonerIndex[ii]=index;
			if(mTele)
			{
				if(GetEntProp(Boss, Prop_Send, "m_bDucked"))
				{
					new Float:temp[3]={24.0, 24.0, 62.0};
					SetEntPropVector(ii, Prop_Send, "m_vecMaxs", temp);
					SetEntProp(ii, Prop_Send, "m_bDucked", 1);
					SetEntityFlags(ii, GetEntityFlags(ii)|FL_DUCKING);
				}
				TeleportEntity(ii, position, NULL_VECTOR, velocity);
			}
			if(mClass)
				TF2_SetPlayerClass(ii, TFClassType:mClass);
			switch(wMode)
			{
				case 2: // No weapons
					TF2_RemoveAllWeapons(ii);
				case 1: // User-Specified
				{
					TF2_RemoveAllWeapons(ii);
					weapon=SpawnWeapon(ii, mClassname, wIndex, 101, 0, mAttributes);
					if(mAmmo)
						SetAmmo(ii, weapon, mAmmo);
					if(mClip)
						SetEntProp(weapon, Prop_Send, "m_iClip1", mClip);
					if(mAcc!=0)
					{
						switch(TF2_GetPlayerClass(ii))
						{
							case TFClass_Engineer:
							{
								SpawnWeapon(ii, "tf_weapon_pda_engineer_build", 25, 101, 5, "292 ; 3 ; 293 ; 59 ; 391 ; 2 ; 495 ; 60"); // Build PDA
								SpawnWeapon(ii, "tf_weapon_pda_engineer_destroy", 26, 101, 5, "391 ; 2"); // Destroy PDA
								weapon = SpawnWeapon(Boss, "tf_weapon_builder", 28, 101, 5, "391 ; 2"); // Builder
								SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 1, _, 0);
								SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 1, _, 1);
								SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 1, _, 2);
								SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 3);
							}
							case TFClass_Spy:
							{
								if(mAcc==4 || mAcc==6 || mAcc==8 || mAcc==11) // Dead Ringer
									SpawnWeapon(ii, "tf_weapon_invis", 59, 1, 0, "33 ; 1 ; 34 ; 1.6 ; 35 ; 1.8 ; 292 ; 9 ; 391 ; 2");
								if(mAcc==3 || mAcc==5 || mAcc==7 || mAcc==10) // Invis Watch
									SpawnWeapon(ii, "tf_weapon_invis", 30, 1, 0, "391 ; 2");
								if(mAcc==2|| mAcc==5 || mAcc == 6 || mAcc>=9) // Disguise kit
									SpawnWeapon(ii, "tf_weapon_pda_spy", 27, 1, 0, "391 ; 2");
								if(mAcc==1 || mAcc==7 || mAcc>=7) // Sapper
								{
									weapon = SpawnWeapon(ii, "tf_weapon_builder", 735, 101, 5, "391 ; 2");
									SetEntProp(weapon, Prop_Send, "m_iObjectType", 3);
									SetEntProp(weapon, Prop_Data, "m_iSubType", 3);
									SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 0);
									SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 1);
									SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 2);
									SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 1, _, 3);
								}
							}
						}
					}
				}
			}
			if(weMode)
			{
				new wearables, owner;
				while((wearables=FindEntityByClassname(wearables, "tf_wearable"))!=-1)
					if((owner=GetEntPropEnt(wearables, Prop_Send, "m_hOwnerEntity"))<=MaxClients && owner>0 && GetClientTeam(owner)==FF2_GetBossTeam())
						TF2_RemoveWearable(owner, wearables);
				while((wearables=FindEntityByClassname(wearables, "tf_wearable_demoshield"))!=-1)
					if((owner=GetEntPropEnt(wearables, Prop_Send, "m_hOwnerEntity"))<=MaxClients && owner>0 && GetClientTeam(owner)==FF2_GetBossTeam())
						TF2_RemoveWearable(owner, wearables);
				while((wearables=FindEntityByClassname(wearables, "tf_powerup_bottle"))!=-1)
					if((owner=GetEntPropEnt(wearables, Prop_Send, "m_hOwnerEntity"))<=MaxClients && owner>0 && GetClientTeam(owner)==FF2_GetBossTeam())
						TF2_RemoveWearable(owner, wearables);
			}
			switch(mMode)
			{
				case 1:
				{
					new String:classname[10];
					TF2_GetNameOfClass(TF2_GetPlayerClass(ii), classname, sizeof(classname));
					Format(mModel, sizeof(mModel), "models/bots/%s/bot_%s.mdl", classname, classname);
					ReplaceString(mModel, sizeof(mModel), "demoman", "demo", false);
					PrecacheModel(mModel);
					SetVariantString(mModel);
					IsRobot[ii] =  true;
					if(uDuration)
						TF2_AddCondition(ii, TFCond_UberchargedHidden, Float:uDuration);
					AcceptEntityInput(ii, "SetCustomModel");
					SetEntProp(ii, Prop_Send, "m_bUseClassAnimations", 1);
				}
				default:
				{
					if(mModel[0] != '\0') // Custom Model
						PrecacheModel(mModel);
					SetVariantString(mModel);
					AcceptEntityInput(ii, "SetCustomModel");
					SetEntProp(ii, Prop_Send, "m_bUseClassAnimations", 1);
					if(uDuration)
						TF2_AddCondition(ii, TFCond_Ubercharged, Float:uDuration);
					if(VOMode)
					{
						switch(VOMode)
						{
							case 1: // Robot Voice Lines
								IsRobot[ii] = true;
							case 2: // Giant Robot Voice Lines
								IsGiantRobot[ii] = true;
							case -1: // Mute Voice Lines
								HasNoVoice[ii] = true;
						}
					}
				}
			}
			if(mNotify!=0)
			{
				new String:spcl[768];
				FF2_GetBossSpecial(index, spcl, sizeof(spcl));
				PrintHintText(Boss, "%t", "minion_summoner");
				PrintHintText(ii, "%t", "minion_summoned", spcl);
			}
			if(mHP==-1)
			{
				switch(FF2_GetBossLives(index))
				{
					case 1:
					{
						if(FF2_GetBossHealth(index)<2000)
							mHP=(FF2_GetBossHealth(index));
						else if(FF2_GetBossHealth(index)>4000)
							mHP=(((FF2_GetBossHealth(index))/2)/bMinion);
						else
							mHP=((FF2_GetBossHealth(index))/bMinion);
					}
					default:	
						mHP=((FF2_GetBossHealth(index))/FF2_GetBossLives(index))/bMinion;
				}
			}
			if(mHP)
			{
				SetEntProp(ii, Prop_Data, "m_iMaxHealth", mHP);
				SetEntProp(ii, Prop_Data, "m_iHealth", mHP);
				SetEntProp(ii, Prop_Send, "m_iHealth", mHP);
			}	
		}
	}
}	

	
stock GetRandomDeadPlayer()
{
	new clients[MaxClients+1], clientCount;
	for(new i=1;i<=MaxClients;i++)
	{
		if(IsValidEdict(i) && IsClientConnected(i) && IsClientInGame(i) && !IsPlayerAlive(i) && (GetClientTeam(i) > 1))
		{
			clients[clientCount++] = i;
		}
	}
	return (clientCount == 0) ? -1 : clients[GetRandomInt(0, clientCount-1)];
}

public Action:SoundHook(clients[64], &numClients, String:vl[PLATFORM_MAX_PATH], &Ent, &channel, &Float:volume, &level, &pitch, &flags)
{
	new client = Ent;
	if(client <=  MAXPLAYERS && client > 0)
	{
		if(IsRobot[client]) // Robot voice lines & footsteps
		{
			if (StrContains(vl, "player/footsteps/", false) != -1 && TF2_GetPlayerClass(client) != TFClass_Medic)
			{
				new rand = GetRandomInt(1,18);
				Format(vl, sizeof(vl), "mvm/player/footsteps/robostep_%s%i.wav", (rand < 10) ? "0" : "", rand);
				pitch = GetRandomInt(95, 100);
				EmitSoundToAll(vl, client, _, _, _, 0.25, pitch);
				return Plugin_Changed;
			}
			if (StrContains(vl, "vo/", false) == -1) return Plugin_Continue;
			if (volume == 0.99997) return Plugin_Continue;
			ReplaceString(vl, sizeof(vl), "vo/", "vo/mvm/norm/", false);
			ReplaceString(vl, sizeof(vl), ".wav", ".mp3", false);
			new String:classname[10], String:classname_mvm[15];
			TF2_GetNameOfClass(TF2_GetPlayerClass(client), classname, sizeof(classname));
			Format(classname_mvm, sizeof(classname_mvm), "%s_mvm", classname);
			ReplaceString(vl, sizeof(vl), classname, classname_mvm, false);
			new String:nSnd[PLATFORM_MAX_PATH];
			Format(nSnd, sizeof(nSnd), "sound/%s", vl);
			PrecacheSound(vl);
			return Plugin_Changed;
		}
		if(IsGiantRobot[client]) // Giant robot voice lines & footsteps
		{
			if (StrContains(vl, "player/footsteps/", false) != -1 && TF2_GetPlayerClass(client) != TFClass_Medic)
			{
				Format(vl, sizeof(vl), "mvm/giant_common/giant_common_step_0%i.wav", GetRandomInt(1,8));
				pitch = GetRandomInt(95, 100);
				EmitSoundToAll(vl, client, _, _, _, 0.25, pitch);
				return Plugin_Changed;
			}
			if (StrContains(vl, "vo/", false) == -1) return Plugin_Continue;
			if (volume == 0.99997) return Plugin_Continue;
			ReplaceString(vl, sizeof(vl), "vo/", "vo/mvm/mght/", false);
			ReplaceString(vl, sizeof(vl), ".wav", ".mp3", false);
			new String:classname[10], String:classname_mvm_m[20];
			TF2_GetNameOfClass(TF2_GetPlayerClass(client), classname, sizeof(classname));
			Format(classname_mvm_m, sizeof(classname_mvm_m), "%s_mvm_m", classname);
			ReplaceString(vl, sizeof(vl), classname, classname_mvm_m, false);
			new String:gSnd[PLATFORM_MAX_PATH];
			Format(gSnd, sizeof(gSnd), "sound/%s", vl);
			PrecacheSound(vl);
			return Plugin_Changed;
		}
		if(HasNoVoice[client]) // Block voice lines.
		{
			if (StrContains(vl, "vo/", false) == -1) 
				return Plugin_Stop;
			else if (!(StrContains(vl, "vo/", false) == -1)) // Just in case
				return Plugin_Stop;
			return Plugin_Continue;
		}
	}
	return Plugin_Continue;
}

stock TF2_GetNameOfClass(TFClassType:class, String:name[], maxlen)
{
	switch (class)
	{
		case TFClass_Scout: Format(name, maxlen, "scout");
		case TFClass_Soldier: Format(name, maxlen, "soldier");
		case TFClass_Pyro: Format(name, maxlen, "pyro");
		case TFClass_DemoMan: Format(name, maxlen, "demoman");
		case TFClass_Heavy: Format(name, maxlen, "heavy");
		case TFClass_Engineer: Format(name, maxlen, "engineer");
		case TFClass_Medic: Format(name, maxlen, "medic");
		case TFClass_Sniper: Format(name, maxlen, "sniper");
		case TFClass_Spy: Format(name, maxlen, "spy");
	}
}

// Misc

public Action:FF2_OnTriggerHurt(userid,triggerhurt,&Float:damage)
{
	new Boss=GetClientOfUserId(FF2_GetBossUserId(userid));
	if(FF2_HasAbility(userid, this_plugin_name, "save_me"))
	{
		damage=FF2_GetAbilityArgumentFloat(userid,this_plugin_name,"save_me", 1);
		PrintHintText(Boss, "%t", "boss_saved");
		if(damage)
		{
			new Float: rageamnt=FF2_GetAbilityArgumentFloat(userid,this_plugin_name,"save_me", 2);
			new Float: stunlength=FF2_GetAbilityArgumentFloat(userid,this_plugin_name,"save_me", 3);
			Teleport_Me(Boss);
			FF2_SetBossCharge(Boss, 0, rageamnt);
			TF2_StunPlayer(Boss, stunlength, 0.0, TF_STUNFLAGS_LOSERSTATE, Boss);
			SetEntProp(Boss, Prop_Data, "m_takedamage", 0);
			CreateTimer(stunlength, UnInvun, Boss);
		}
		else
		{
			Teleport_Me(Boss);
			TF2_StunPlayer(Boss, 4.0, 0.0, TF_STUNFLAGS_LOSERSTATE, Boss);
			SetEntProp(Boss, Prop_Data, "m_takedamage", 0);
			CreateTimer(4.0, UnInvun, Boss);
		}
	}
	bEnableSuperDuperJump[userid]=true;
	if (FF2_GetBossCharge(userid,1)<0)
		FF2_SetBossCharge(userid,1,0.0);
	return Plugin_Continue;
}

public Action:UnInvun(Handle:hTimer,any:userid)
{
	new Boss=GetClientOfUserId(FF2_GetBossUserId(userid));
	SetEntProp(Boss, Prop_Data, "m_takedamage", 2);
	return Plugin_Continue;
}