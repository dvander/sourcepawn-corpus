/*
	Default Abilities Pack:

	Rages:
	rage_cbs_bowrage
	rage_cloneattack
	rage_explosive_dance
	rage_instant_teleport
	rage_tradespam
	rage_matrix_attack
	rage_new_weapon
	rage_overlay
	rage_stun
	rage_stunsg
	rage_uber

	Charges:
	special_democharge

	Difficulties:
	health
	nocharge
	nohud
	nolives
	nopassive
	norage
	noslot
	outline
	rage
	tfcond

	Specials:
	model_projectile_replace
	spawn_many_objects_on_death
	spawn_many_objects_on_kill
	special_cbs_multimelee
	special_dissolve
	special_dropprop
	special_noanims
*/
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#include <morecolors>
#include <tf2items>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>
#undef REQUIRE_PLUGIN
#tryinclude <smac>
#define REQUIRE_PLUGIN

#pragma newdecls required

#define MAJOR_REVISION	"0"
#define MINOR_REVISION	"6"
#define STABLE_REVISION	"2"
#define PLUGIN_VERSION MAJOR_REVISION..."."...MINOR_REVISION..."."...STABLE_REVISION

#define PROJECTILE	"model_projectile_replace"
#define OBJECTS		"spawn_many_objects_on_kill"
#define OBJECTS_DEATH	"spawn_many_objects_on_death"

#define SPOOK "yikes_fx"

#define CBS_MAX_ARROWS 9
#define MAXTF2PLAYERS 36

#define SOUND_SLOW_MO_START	"replay/enterperformancemode.wav"	//Used when Ninja Spy enters slow mo
#define SOUND_SLOW_MO_END	"replay/exitperformancemode.wav"	//Used when Ninja Spy exits slow mo
#define SOUND_DEMOPAN_RAGE	"ui/notification_alert.wav"		//Used when Demopan rages

#define FLAG_ONSLOWMO		(1<<0)
#define FLAG_SLOWMOREADYCHANGE	(1<<1)

enum Operators
{
	Operator_None = 0,
	Operator_Add,
	Operator_Subtract,
	Operator_Multiply,
	Operator_Divide,
	Operator_Exponent,
};

//	ConVars
ConVar cvarBaseJumperStun;
ConVar cvarStrangeWep;
ConVar cvarSoloShame;
ConVar cvarTimeScale;
ConVar cvarCheats;

//	Global
Handle OnHaleRage = INVALID_HANDLE;
int FF2Flags[MAXTF2PLAYERS];
int Players;
int TotalPlayers;

//	Clone Attack
int CloneOwnerIndex[MAXTF2PLAYERS];

//	Difficulty
bool NoCharge[MAXTF2PLAYERS];
int NoSlot[MAXTF2PLAYERS];
bool NoPassive[MAXTF2PLAYERS];
bool NoRage[MAXTF2PLAYERS];
bool NoHud[MAXTF2PLAYERS];
bool Outline[MAXTF2PLAYERS];
TFCond Cond[MAXTF2PLAYERS];

//	Demo Charge
float Charged[MAXTF2PLAYERS];

//	Demo Overlay
int Demopan;

//	Explosive Dance
int ExpCount[MAXTF2PLAYERS] = 35;
float ExpDamage[MAXTF2PLAYERS] = 180.0;
int ExpRange[MAXTF2PLAYERS] = 350;

//	Instant Teleport
float Tslowdown;
float Tstun;
int TflagOverride;

//	Matrix Attack
Handle SlowMoTimer;
int oldTarget;
#if !defined _smac_included
bool smac = false;
#endif
bool HasSlowdown = false;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	OnHaleRage = CreateGlobalForward("VSH_OnDoRage", ET_Hook, Param_FloatByRef);
	return APLRes_Success;
}

public Plugin myinfo =
{
	name		=	"Unofficial Freak Fortress 2: Defaults",
	author		=	"Many many people",
	description	=	"FF2: Combined subplugin of default abilities",
	version		=	PLUGIN_VERSION
};

public void OnPluginStart2()
{
	int version[3];
	FF2_GetFF2Version(version);
	if(version[0]!=1 || version[1]<11)
		SetFailState("This subplugin depends on at least Unofficial FF2 v1.19.0");

	FF2_GetForkVersion(version);
	if(version[0]!=1 || version[1]<19)
		SetFailState("This subplugin depends on at least Unofficial FF2 v1.19.0");

	HookEvent("teamplay_round_start", OnRoundStart, EventHookMode_PostNoCopy);
	HookEvent("teamplay_round_win", OnRoundEnd, EventHookMode_PostNoCopy);
	HookEvent("player_death", OnPlayerDeath);

	cvarTimeScale = FindConVar("host_timescale");
	cvarCheats = FindConVar("sv_cheats");

	PrecacheSound("items/pumpkin_pickup.wav");
	LoadTranslations("freak_fortress_2.phrases");

	for(int boss; boss<=MaxClients; boss++)
	{
		Cond[boss] = TFCond_Slowed;
		NoSlot[boss] = -2;
	}

	if(FF2_GetRoundState() != 2)	// In case the plugin is loaded in late
		OnRoundStart(INVALID_HANDLE, "plugin_lateload", false);
}

public void OnMapStart()
{
	PrecacheSound(SOUND_SLOW_MO_START, true);
	PrecacheSound(SOUND_SLOW_MO_END, true);
	PrecacheSound(SOUND_DEMOPAN_RAGE, true);
}

public void OnAllPluginsLoaded()
{
	cvarBaseJumperStun = FindConVar("ff2_base_jumper_stun");
	cvarStrangeWep = FindConVar("ff2_strangewep");
	cvarSoloShame = FindConVar("ff2_solo_shame");
}

#if !defined _smac_included
public void OnLibraryAdded(const char[] name)
{
	if(!strcmp(name, "smac", false))
	{
		smac = true;
		FF2Dbg("Smac added");
	}
}

public void OnLibraryRemoved(const char[] name)
{
	if(!strcmp(name, "smac", false))
	{
		smac = false;
		FF2Dbg("Smac removed");
	}
}
#endif

bool IsSlowMoActive()
{
	for(int client=1; client<=MaxClients; client++)
	{
		if(FF2Flags[client] & FLAG_ONSLOWMO)
			return true;
	}
	return false;
}

public Action FF2_OnAbility2(int boss, const char[] plugin_name, const char[] ability_name, int status)
{
	if(!FF2_GetArgI(boss, this_plugin_name, ability_name, "slot", 0))  //Rage
	{
		if(!boss)
		{
			Action action = Plugin_Continue;
			Call_StartForward(OnHaleRage);
			float distance = FF2_GetRageDist(boss, this_plugin_name, ability_name);
			float newDistance = distance;
			Call_PushFloatRef(newDistance);
			Call_Finish(action);
			if(action!=Plugin_Continue && action!=Plugin_Changed)
			{
				return Plugin_Continue;
			}
			else if(action == Plugin_Changed)
			{
				distance = newDistance;
			}
		}
	}
    /*
       Rages
    */
	if(!StrContains(ability_name, "rage_new_weapon"))
	{
		Rage_New_Weapon(boss, ability_name);
	}
	else if(!StrContains(ability_name, "rage_overlay"))
	{
		Rage_Overlay(boss, ability_name);
	}
	else if(!StrContains(ability_name, "rage_uber"))
	{
		float duration = GetArgF(boss, ability_name, "duration", 1, 5.0, 2);
		if(duration <= 0)
			return Plugin_Continue;

		int client = GetClientOfUserId(FF2_GetBossUserId(boss));
		TF2_AddCondition(client, TFCond_Ubercharged, duration);
		SetEntProp(client, Prop_Data, "m_takedamage", 0);
		CreateTimer(duration, Timer_StopUber, boss, TIMER_FLAG_NO_MAPCHANGE);
	}
	else if(StrEqual(ability_name, "rage_stun"))
	{
		float delay = GetArgF(boss, ability_name, "delay", 10, 0.0, 1);
		if(delay > 0)
		{
			CreateTimer(delay, Timer_Rage_Stun, boss);
		}
		else
		{
			Timer_Rage_Stun(INVALID_HANDLE, boss);
		}
	}
	else if(!StrContains(ability_name, "rage_stunsg"))
	{
		Rage_StunBuilding(ability_name, boss);
	}
	else if(!StrContains(ability_name, "rage_instant_teleport"))
	{
		static float position[3];
		bool otherTeamIsAlive;
		char flagOverrideStr[12];
		static char particleEffect[48];

		Tstun = GetArgF(boss, ability_name, "stun", 1, 2.0, 2);
		//bool friendly = view_as<bool>(GetArgF(boss, ability_name, "friendly", 2, 1.0, 0));
		FF2_GetArgS(boss, this_plugin_name, ability_name, "flags", 3, flagOverrideStr, sizeof(flagOverrideStr));
		Tslowdown = GetArgF(boss, ability_name, "slowdown", 4, 0.0, 1);
		bool sounds = view_as<bool>(GetArgF(boss, ability_name, "sound", 5, 1.0, 0));
		FF2_GetArgS(boss, this_plugin_name, ability_name, "particle", 6, particleEffect, sizeof(particleEffect));

		TflagOverride = ReadHexOrDecInt(flagOverrideStr);
		if(TflagOverride == 0)
			TflagOverride = TF_STUNFLAGS_GHOSTSCARE|TF_STUNFLAG_NOSOUNDOREFFECT;

		int client = GetClientOfUserId(FF2_GetBossUserId(boss));
		for(int target=1; target<=MaxClients; target++)
		{
			if(IsClientInGame(target) && IsPlayerAlive(target) && target!=client && !(FF2_GetFF2flags(target) & FF2FLAG_ALLOWSPAWNINBOSSTEAM))
			{
				otherTeamIsAlive = true;
				break;
			}
		}

		if(!otherTeamIsAlive)
			return Plugin_Continue;

		int target, tries;
		do
		{
			tries++;
			target=GetRandomInt(1, MaxClients);
			if(tries == 100)
				return Plugin_Continue;
		}
		while(!IsValidEntity(target) || target==client || (FF2_GetFF2flags(target) & FF2FLAG_ALLOWSPAWNINBOSSTEAM) || !IsPlayerAlive(target));

		if(particleEffect[0])
		{
			CreateTimer(3.0, Timer_RemoveEntity, EntIndexToEntRef(AttachParticle(client, particleEffect)), TIMER_FLAG_NO_MAPCHANGE);
			CreateTimer(3.0, Timer_RemoveEntity, EntIndexToEntRef(AttachParticle(client, particleEffect, _, false)), TIMER_FLAG_NO_MAPCHANGE);
		}

		if(IsValidEntity(target))
		{
			GetEntPropVector(target, Prop_Send, "m_vecOrigin", position);
			SetEntPropFloat(client, Prop_Send, "m_flNextAttack", GetGameTime() + 2.0);
			if(GetEntProp(target, Prop_Send, "m_bDucked"))
			{
				static float temp[3] = {24.0, 24.0, 62.0};  //Compiler won't accept directly putting it into SEPV -.-
				SetEntPropVector(client, Prop_Send, "m_vecMaxs", temp);
				SetEntProp(client, Prop_Send, "m_bDucked", 1);
				SetEntityFlags(client, GetEntityFlags(client)|FL_DUCKING);
				CreateTimer(0.2, Timer_StunBoss, boss, TIMER_FLAG_NO_MAPCHANGE);
			}
			else
			{
				if(sounds)
				{
					TF2_StunPlayer(client, Tstun, Tslowdown, TflagOverride, target);
				}
				else
				{
					TF2_StunPlayer(client, Tstun, Tslowdown, TflagOverride, 0);
				}
			}
			TeleportEntity(client, position, NULL_VECTOR, NULL_VECTOR);
		}
	}
	else if(!StrContains(ability_name, "rage_cloneattack"))
	{
		Rage_Clone(ability_name, boss);
	}
	else if(!StrContains(ability_name, "rage_tradespam"))
	{
		CreateTimer(0.0, Timer_Demopan_Rage, 1, TIMER_FLAG_NO_MAPCHANGE);
		Demopan = GetClientTeam(GetClientOfUserId(FF2_GetBossUserId(boss)));
	}
	else if(StrEqual(ability_name, "rage_cbs_bowrage"))
	{
		Rage_Bow(boss);
	}
	else if(StrEqual(ability_name, "rage_explosive_dance"))
	{
		SetEntityMoveType(GetClientOfUserId(FF2_GetBossUserId(boss)), MOVETYPE_NONE);
		Handle data;
		CreateDataTimer(0.15, Timer_Prepare_Explosion_Rage, data);
		WritePackCell(data, boss);
		WritePackString(data, ability_name);
		ResetPack(data);
	}
	else if(StrEqual(ability_name, "rage_matrix_attack"))
	{
		Rage_Slowmo(boss);
	}
    /*
       Specials
    */
	else if(StrEqual(ability_name, "special_democharge"))
	{
		int client = GetClientOfUserId(FF2_GetBossUserId(boss));
		if(status<1 || Charged[client]>GetGameTime())
			return Plugin_Continue;

		float delay = GetArgF(boss, ability_name, "delay", 3, 0.0, 1);
		if(!delay)
		{
			Timer_DemoCharge(INVALID_HANDLE, boss);
		}
		else
		{
			Charged[client] = GetGameTime()+delay;
			CreateTimer(delay, Timer_DemoCharge, boss);
		}
	}
	return Plugin_Continue;
}

public void FF2_OnAlivePlayersChanged(int players, int bosses)
{
	if(!bosses || !players || FF2_GetRoundState()!=1)
		return;

	Players = players+bosses;
	if(TotalPlayers > players+bosses)
		TotalPlayers = players+bosses;
}

public void FF2_PreAbility(int boss, const char[] pluginName, const char[] abilityName, int slot, bool &enabled)
{
	if(NoSlot[boss] == slot)
	{
		enabled = false;
	}
	else if(!slot)
	{
		if(NoRage[boss])
			enabled = false;
	}
	else if(slot > 3)
	{
		if(NoPassive[boss])
			enabled = false;
	}
	else if(slot > 0)
	{
		if(NoCharge[boss])
			enabled = false;
	}
}

public void FF2_OnDifficulty(int boss, const char[] section, Handle kv)
{
	// "nocharge" determines if the boss can use charge abilities
	NoCharge[boss] = view_as<bool>(KvGetNum(kv, "nocharge", 0));

	// "noslot" determines the specific slot that won't be used
	NoSlot[boss] = KvGetNum(kv, "noslot", -2);

	// "nopassive" determines if the boss can use passive abilities
	NoPassive[boss] = view_as<bool>(KvGetNum(kv, "nopassive", 0));

	// "norage" determines if the boss can use rage abilities
	NoRage[boss] = view_as<bool>(KvGetNum(kv, "norage", 0));

	// "nohud" determines if the boss can see the HUD
	NoHud[boss] = view_as<bool>(KvGetNum(kv, "nohud", 0));

	// "outline" determines if the boss is always outlined
	Outline[boss] = view_as<bool>(KvGetNum(kv, "outline", 0));

	// "tfcond" determines if the boss always have a condition
	Cond[boss] = view_as<TFCond>(KvGetNum(kv, "tfcond", 0));

	int health = FF2_GetBossMaxHealth(boss);
	int lives = FF2_GetBossMaxLives(boss);

	// "nolives" determines if the boss has lives
	if(KvGetNum(kv, "nolives"))
	{
		health *= lives;
		lives = 1;
	}

	// "health" determines the ratio
	health = RoundFloat(health*KvGetFloat(kv, "health", 1.0));

	if(lives > 0)
	{
		FF2_SetBossMaxLives(boss, lives);
		FF2_SetBossLives(boss, lives);
	}

	if(health > 0)
	{
		FF2_SetBossMaxHealth(boss, health);
		FF2_SetBossHealth(boss, health*lives);
	}

	if(NoRage[boss])
	{
		FF2_SetBossRageDamage(boss, 99999);
	}
	else
	{
		// "rage" determines the ratio
		health = RoundFloat(FF2_GetBossRageDamage(boss)*KvGetFloat(kv, "rage", 1.0));
		if(health > 0)
			FF2_SetBossRageDamage(boss, health);
	}
}

public Action OnRoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	TotalPlayers = 0;
	int boss;
	for(int client; client<MaxClients; client++)
	{
		FF2Flags[client] = 0;
		CloneOwnerIndex[client] = 0;
		if(!client || !IsClientInGame(client))
			continue;

		if(GetClientTeam(client) > view_as<int>(TFTeam_Spectator))
			TotalPlayers++;

		#if defined _smac_included
		if(!HasSlowdown)
		#else
		if(smac && FindPluginByFile("smac_cvars.smx")!=INVALID_HANDLE && !HasSlowdown)
		#endif
		{
			boss = FF2_GetBossIndex(client);
			if(boss >= 0)
			{
				if(FF2_HasAbility(boss, this_plugin_name, "rage_matrix_attack"))
				{
					HasSlowdown = true;
					#if !defined _smac_included
					ServerCommand("smac_removecvar sv_cheats");
					ServerCommand("smac_removecvar host_timescale");
					#endif
				}
			}
		}
	}
	Players = TotalPlayers;

	CreateTimer(0.41, Timer_Disable_Anims, _, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(9.31, Timer_Disable_Anims, _, TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}

public Action OnRoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	if(SlowMoTimer)
	{
		TriggerTimer(SlowMoTimer);
		SlowMoTimer = INVALID_HANDLE;
	}

	#if defined _smac_included
	HasSlowdown = false;
	#else
	if(smac && FindPluginByFile("smac_cvars.smx")!=INVALID_HANDLE && HasSlowdown)
	{
		HasSlowdown = false;
		ServerCommand("smac_addcvar sv_cheats replicated ban 0 0");
		ServerCommand("smac_addcvar host_timescale replicated ban 1.0 1.0");
	}
	#endif

	for(int client; client<=MaxClients; client++)
	{
		Cond[client] = TFCond_Slowed;
		NoCharge[client] = false;
		NoHud[client] = false;
		NoPassive[client] = false;
		NoRage[client] = false;
		NoSlot[client] = -2;
		Outline[client] = false;

		if(client && IsClientInGame(client) && CloneOwnerIndex[client]!=0)  //FIXME: IsClientInGame() shouldn't be needed
		{
			CloneOwnerIndex[client] = 0;
			FF2_SetFF2flags(client, FF2_GetFF2flags(client) & ~FF2FLAG_CLASSTIMERDISABLED);
		}
	}

	for(int client=1; client<=MaxClients; client++)
	{
		if(FF2Flags[client] & FLAG_ONSLOWMO)
		{
			if(SlowMoTimer)
				KillTimer(SlowMoTimer);

			Timer_StopSlowMo(INVALID_HANDLE, -1);
		}
	}
	return Plugin_Continue;
}

#if defined _smac_included
public Action SMAC_OnCheatDetected(int client, const char[] module, DetectionType type, Handle info)
{
	FF2Dbg("SMAC: Cheat detected!");
	if(type == Detection_CvarViolation)
	{
		FF2Dbg("SMAC: Cheat was a cvar violation!");
		char cvar[PLATFORM_MAX_PATH];
		KvGetString(info, "cvar", cvar, sizeof(cvar));
		FF2Dbg("Cvar was %s", cvar);
		if(StrEqual(cvar, "sv_cheats") || StrEqual(cvar, "host_timescale"))
		{
			if(IsSlowMoActive())
			{
				FF2Dbg("SMAC: Ignoring violation");
				return Plugin_Stop;
			}
		}
	}
	return Plugin_Continue;
}
#endif

public void OnClientDisconnect(int client)
{
	FF2Flags[client] = 0;
	if(CloneOwnerIndex[client] != 0)
	{
		CloneOwnerIndex[client] = 0;
		FF2_SetFF2flags(client, FF2_GetFF2flags(client) & ~FF2FLAG_CLASSTIMERDISABLED);
	}
}

public int OnPlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(!client || !attacker || !IsClientInGame(client) || !IsClientInGame(attacker))
		return;

	int boss = FF2_GetBossIndex(attacker);
	if(boss >= 0)
	{
		if(FF2_HasAbility(boss, this_plugin_name, OBJECTS))
		{
			static char classname[PLATFORM_MAX_PATH], model[PLATFORM_MAX_PATH];
			FF2_GetArgS(boss, this_plugin_name, OBJECTS, "classname", 1, classname, PLATFORM_MAX_PATH);
			FF2_GetArgS(boss, this_plugin_name, OBJECTS, "model", 2, model, PLATFORM_MAX_PATH);
			SpawnManyObjects(classname, client, model, RoundFloat(GetArgF(boss, OBJECTS, "skin", 3, 0.0, 1)), RoundFloat(GetArgF(boss, OBJECTS, "amount", 4, 14.0, 2)), GetArgF(boss, OBJECTS, "distance", 5, 30.0, 1));
		}
		if(FF2_HasAbility(boss, this_plugin_name, "special_dissolve"))
		{
			CreateTimer(0.1, Timer_DissolveRagdoll, GetEventInt(event, "userid"), TIMER_FLAG_NO_MAPCHANGE);
		}
		if(FF2_HasAbility(boss, this_plugin_name, "special_cbs_multimelee"))
		{
			if(GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon") == GetPlayerWeaponSlot(attacker, TFWeaponSlot_Melee))
			{
				TF2_RemoveWeaponSlot(attacker, TFWeaponSlot_Melee);
				static char attributes[128];
				if(!FF2_GetArgS(boss, this_plugin_name, "special_cbs_multimelee", "attributes", 1, attributes, sizeof(attributes)))
					strcopy(attributes, sizeof(attributes), "68 ; 2 ; 2 ; 3.1 ; 275 ; 1");

				int weapon;
				switch(GetRandomInt(0, 2))
				{
					case 0:
					{
						weapon = FF2_SpawnWeapon(attacker, "tf_weapon_club", 171, 101, 5, attributes);
					}
					case 1:
					{
						weapon = FF2_SpawnWeapon(attacker, "tf_weapon_club", 193, 101, 5, attributes);
					}
					case 2:
					{
						weapon = FF2_SpawnWeapon(attacker, "tf_weapon_club", 232, 101, 5, attributes);
					}
				}
				SetEntPropEnt(attacker, Prop_Data, "m_hActiveWeapon", weapon);
			}
		}
		if(FF2_HasAbility(boss, this_plugin_name, "special_dropprop"))
		{
			static char model[PLATFORM_MAX_PATH];
			if(FF2_GetArgS(boss, this_plugin_name, "special_dropprop", "model", 1, model, PLATFORM_MAX_PATH))
			{
				if(!IsModelPrecached(model))	// Make sure the boss author precached the model (similar to above)
				{
					static char bossName[64];
					FF2_GetBossName(boss, bossName, sizeof(bossName));
					if(!FileExists(model, true))
					{
						FF2_ReportError(boss, "[Boss] Model '%s' doesn't exist!  Please check %s's config", model, bossName);
						return;
					}
					else
					{
						PrecacheModel(model);
					}
				}

				if(GetArgF(boss, "special_dropprop", "remove ragdolls", 3, 0.0, 0))
					CreateTimer(0.01, Timer_RemoveRagdoll, GetEventInt(event, "userid"), TIMER_FLAG_NO_MAPCHANGE);

				int prop = CreateEntityByName("prop_physics_override");
				if(IsValidEntity(prop))
				{
					SetEntityModel(prop, model);
					SetEntityMoveType(prop, MOVETYPE_VPHYSICS);
					SetEntProp(prop, Prop_Send, "m_CollisionGroup", 1);
					SetEntProp(prop, Prop_Send, "m_usSolidFlags", 16);
					DispatchSpawn(prop);

					static float position[3];
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
					position[2] += 20;
					TeleportEntity(prop, position, NULL_VECTOR, NULL_VECTOR);
					float duration = GetArgF(boss, "special_dropprop", "duration", 2, 0.0, 1);
					if(duration > 0.5)
						CreateTimer(duration, Timer_RemoveEntity, EntIndexToEntRef(prop), TIMER_FLAG_NO_MAPCHANGE);
				}
			}
		}
	}

	boss = FF2_GetBossIndex(client);
	if(boss >= 0)
	{
		if(FF2_HasAbility(boss, this_plugin_name, OBJECTS_DEATH))
		{
			static char classname[PLATFORM_MAX_PATH], model[PLATFORM_MAX_PATH];
			FF2_GetArgS(boss, this_plugin_name, OBJECTS_DEATH, "classname", 1, classname, PLATFORM_MAX_PATH);
			FF2_GetArgS(boss, this_plugin_name, OBJECTS_DEATH, "model", 2, model, PLATFORM_MAX_PATH);
			SpawnManyObjects(classname, client, model, RoundFloat(GetArgF(boss, OBJECTS_DEATH, "skin", 3, 0.0, 1)), RoundFloat(GetArgF(boss, OBJECTS_DEATH, "count", 4, 14.0, 2)), GetArgF(boss, OBJECTS_DEATH, "distance", 5, 30.0, 1));
		}

		if(FF2_HasAbility(boss, this_plugin_name, "rage_cloneattack") && GetArgF(boss, "rage_cloneattack", "die on boss death", 12, 1.0, 0) && !(GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER))
		{
			for(int target=1; target<=MaxClients; target++)
			{
				if(CloneOwnerIndex[target] == client)
				{
					CloneOwnerIndex[target] = 0;
					FF2_SetFF2flags(target, FF2_GetFF2flags(target) & ~FF2FLAG_CLASSTIMERDISABLED);
					if(IsClientInGame(target) && GetClientTeam(target)==GetClientTeam(client))
						ChangeClientTeam(target, (GetClientTeam(client)==view_as<int>(TFTeam_Blue)) ? (view_as<int>(TFTeam_Red)) : (view_as<int>(TFTeam_Blue)));
				}
			}
		}
	}

	if(CloneOwnerIndex[client]>0 && CloneOwnerIndex[client]<=MaxClients && IsClientInGame(CloneOwnerIndex[client]) && !(GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER))  //Switch clones back to the other team after they die
	{
		FF2_SetFF2flags(client, FF2_GetFF2flags(client) & ~FF2FLAG_CLASSTIMERDISABLED);
		ChangeClientTeam(client, (TF2_GetClientTeam(CloneOwnerIndex[client])==TFTeam_Blue) ? (view_as<int>(TFTeam_Red)) : (view_as<int>(TFTeam_Blue)));
		CloneOwnerIndex[client] = 0;
	}
}

/*	No Animations	*/

public Action Timer_Disable_Anims(Handle timer)
{
	int client;
	for(int boss; (client=GetClientOfUserId(FF2_GetBossUserId(boss)))>0; boss++)
	{
		if(FF2_HasAbility(boss, this_plugin_name, "special_noanims"))
		{
			SetEntProp(client, Prop_Send, "m_bUseClassAnimations", RoundFloat(GetArgF(boss, "special_noanims", "custom model animation", 2, 0.0, 1)));
			SetEntProp(client, Prop_Send, "m_bCustomModelRotates", RoundFloat(GetArgF(boss, "special_noanims", "custom model rotates", 1, 0.0, 1)));
		}
	}
	return Plugin_Continue;
}


/*	Easter  Abilities	*/

public void OnEntityCreated(int entity, const char[] classname)
{
	if(IsValidEntity(entity) && StrContains(classname, "tf_projectile")>=0)
		SDKHook(entity, SDKHook_SpawnPost, OnProjectileSpawned);
}

public void OnProjectileSpawned(int entity)
{
	int client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if(client>0 && client<=MaxClients && IsClientInGame(client))
	{
		int boss = FF2_GetBossIndex(client);
		if(boss>=0 && FF2_HasAbility(boss, this_plugin_name, PROJECTILE))
		{
			static char projectile[PLATFORM_MAX_PATH], classname[PLATFORM_MAX_PATH];
			FF2_GetArgS(boss, this_plugin_name, PROJECTILE, "projectile", 1, projectile, PLATFORM_MAX_PATH);
			GetEntityClassname(entity, classname, sizeof(classname));
			if(StrEqual(classname, projectile, false))
			{
				FF2_GetArgS(boss, this_plugin_name, PROJECTILE, "model", 2, classname, PLATFORM_MAX_PATH);
				if(!IsModelPrecached(classname))
				{
					if(FileExists(classname, true))
					{
						PrecacheModel(classname);
					}
					else
					{
						FF2_ReportError(boss, "[Boss] Model '%s' doesn't exist!  Please check config", classname);
						return;
					}
				}
				SetEntityModel(entity, classname);
			}
		}
	}
}

int SpawnManyObjects(char[] classname, int client, char[] model, int skin=0, int amount=14, float distance=30.0)
{
	if(!client || !IsClientInGame(client))
		return;

	static float position[3], velocity[3];
	static float angle[] = {90.0, 0.0, 0.0};
	GetClientAbsOrigin(client, position);
	position[2] += distance;
	for(int i; i<amount; i++)
	{
		velocity[0] = GetRandomFloat(-400.0, 400.0);
		velocity[1] = GetRandomFloat(-400.0, 400.0);
		velocity[2] = GetRandomFloat(300.0, 500.0);
		position[0] += GetRandomFloat(-5.0, 5.0);
		position[1] += GetRandomFloat(-5.0, 5.0);

		int entity = CreateEntityByName(classname);
		if(!IsValidEntity(entity))
		{
			FF2_ReportError(FF2_GetBossIndex(client), "[Boss] Invalid entity while spawning objects for %s-check your configs!", this_plugin_name);
			continue;
		}

		SetEntityModel(entity, model);
		DispatchKeyValue(entity, "OnPlayerTouch", "!self,Kill,,0,-1");
		SetEntProp(entity, Prop_Send, "m_nSkin", skin);
		SetEntProp(entity, Prop_Send, "m_nSolidType", 6);
		SetEntProp(entity, Prop_Send, "m_usSolidFlags", 152);
		SetEntProp(entity, Prop_Send, "m_triggerBloat", 24);
		SetEntProp(entity, Prop_Send, "m_CollisionGroup", 1);
		SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);
		SetEntProp(entity, Prop_Send, "m_iTeamNum", 2);
		DispatchSpawn(entity);
		TeleportEntity(entity, position, angle, velocity);
		SetEntProp(entity, Prop_Data, "m_iHealth", 900);
		int offs = GetEntSendPropOffs(entity, "m_vecInitialVelocity", true);
		SetEntData(entity, offs-4, 1, _, true);
	}
}

public Action Timer_RemoveRagdoll(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	int ragdoll;
	if(client>0 && (ragdoll=GetEntPropEnt(client, Prop_Send, "m_hRagdoll"))>MaxClients)
		AcceptEntityInput(ragdoll, "Kill");
}


/*	Overlay		*/

void Rage_Overlay(int boss, const char[] ability_name)
{
	static char overlay[PLATFORM_MAX_PATH];
	FF2_GetArgS(boss, this_plugin_name, ability_name, "path", 1, overlay, PLATFORM_MAX_PATH);
	float duration = GetArgF(boss, ability_name, "duration", 2, 6.0, 1);
	TFTeam bossTeam = TF2_GetClientTeam(GetClientOfUserId(FF2_GetBossUserId(boss)));

	Format(overlay, PLATFORM_MAX_PATH, "r_screenoverlay \"%s\"", overlay);
	SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & ~FCVAR_CHEAT);
	for(int target=1; target<=MaxClients; target++)
	{
		if(IsClientInGame(target) && IsPlayerAlive(target) && TF2_GetClientTeam(target)!=bossTeam)
			ClientCommand(target, overlay);
	}

	if(duration >= 0)
		CreateTimer(duration, Timer_Remove_Overlay, bossTeam, TIMER_FLAG_NO_MAPCHANGE);

	SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & FCVAR_CHEAT);
}

public Action Timer_Remove_Overlay(Handle timer, TFTeam bossTeam)
{
	SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & ~FCVAR_CHEAT);
	for(int target=1; target<=MaxClients; target++)
	{
		if(IsClientInGame(target) && IsPlayerAlive(target) && TF2_GetClientTeam(target)!=bossTeam)
			ClientCommand(target, "r_screenoverlay off");
	}
	SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & FCVAR_CHEAT);
	return Plugin_Continue;
}


/*	Demo Charge	*/

public Action Timer_DemoCharge(Handle timer, int boss)
{
	float duration = GetArgF(boss, "special_democharge", "duration", 1, 0.25, 0);
	if(duration<0 && duration!=TFCondDuration_Infinite)
		return Plugin_Continue;

	int client = GetClientOfUserId(FF2_GetBossUserId(boss));
	SetEntPropFloat(client, Prop_Send, "m_flChargeMeter", 100.0);
	TF2_AddCondition(client, TFCond_Charging, duration);

	float charge = FF2_GetBossCharge(boss, 0);
	if(charge>GetArgF(boss, "special_democharge", "minimum", 5, 10.0, 0) &&
	   charge<GetArgF(boss, "special_democharge", "maximum", 6, 90.0, 0))
		FF2_SetBossCharge(boss, 0, charge-GetArgF(boss, "special_democharge", "rage", 4, 0.4, 0));

	Charged[client] = GetGameTime()+GetArgF(boss, "special_democharge", "cooldown", 2, 0.0, 1);
	return Plugin_Continue;
}


/*	New Weapon	*/

int Rage_New_Weapon(int boss, const char[] ability_name)
{
	int client = GetClientOfUserId(FF2_GetBossUserId(boss));
	if(!client || !IsClientInGame(client) || !IsPlayerAlive(client))
		return;

	static char classname[64], attributes[256];
	FF2_GetArgS(boss, this_plugin_name, ability_name, "classname", 1, classname, sizeof(classname));
	FF2_GetArgS(boss, this_plugin_name, ability_name, "attributes", 3, attributes, sizeof(attributes));

	TF2_RemoveWeaponSlot(client, RoundFloat(GetArgF(boss, ability_name, "weapon slot", 4, 0.0, 1)));

	int index = RoundFloat(GetArgF(boss, ability_name, "index", 2, 0.0, 1));
	int weapon = FF2_SpawnWeapon(client, classname, index, RoundFloat(GetArgF(boss, ability_name, "level", 8, 101.0, 1)), RoundFloat(GetArgF(boss, ability_name, "quality", 9, 5.0, 1)), attributes);
	if(StrEqual(classname, "tf_weapon_builder") && index!=735)  //PDA, normal sapper
	{
		SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 1, _, 0);
		SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 1, _, 1);
		SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 1, _, 2);
		SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 3);
	}
	else if(StrEqual(classname, "tf_weapon_sapper") || index==735)  //Sappers, normal sapper
	{
		SetEntProp(weapon, Prop_Send, "m_iObjectType", 3);
		SetEntProp(weapon, Prop_Data, "m_iSubType", 3);
		SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 0);
		SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 1);
		SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 2);
		SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 1, _, 3);
	}

	if(GetArgF(boss, ability_name, "force switch", 6, 0.0, 0))
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);

	int ammo = RoundFloat(GetArgF(boss, ability_name, "ammo", 5, -1.0, 0));
	int clip = RoundFloat(GetArgF(boss, ability_name, "clip", 7, -1.0, 0));
	if(ammo>=0 || clip>=0)
		FF2_SetAmmo(client, weapon, ammo, clip);
}


/*	Stun	*/

public Action Timer_Rage_Stun(Handle timer, any boss)
{
	int client = GetClientOfUserId(FF2_GetBossUserId(boss));
	bool solorage = false;
	static float bossPosition[3], targetPosition[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", bossPosition);
 // Initial Duration
	float duration = GetArgF(boss, "rage_stun", "duration", 1, 5.0, 0);
 // Distance
	float distance = GetArgF(boss, "rage_stun", "distance", 2, 0.0, 0);
	if(distance <= 0)
		distance = FF2_GetRageDist(boss, this_plugin_name, "rage_stun");
 // Stun Flags
	char flagOverrideStr[12];
	FF2_GetArgS(boss, this_plugin_name, "rage_stun", "flags", 3, flagOverrideStr, sizeof(flagOverrideStr));
	int flagOverride = ReadHexOrDecInt(flagOverrideStr);
	if(!flagOverride)
		flagOverride = TF_STUNFLAGS_GHOSTSCARE|TF_STUNFLAG_NOSOUNDOREFFECT;
 // Slowdown
	float slowdown = GetArgF(boss, "rage_stun", "slowdown", 4, 0.0, 1);
 // Sound To Boss
	bool sounds = view_as<bool>(GetArgF(boss, "rage_stun", "sound", 5, 1.0, 0));
 // Particle Effect
	char particleEffect[48];
	FF2_GetArgS(boss, this_plugin_name, "rage_stun", "particle", 6, particleEffect, sizeof(particleEffect));
	if(!particleEffect[0])
		strcopy(particleEffect, sizeof(particleEffect), SPOOK);
 // Ignore
	int ignore = RoundFloat(GetArgF(boss, "rage_stun", "uber", 7, 0.0, 1));
 // Friendly Fire
	bool friendly = view_as<bool>(GetArgF(boss, "rage_stun", "friendly", 8, float(GetConVarInt(FindConVar("mp_friendlyfire"))), 0));
 // Remove Parachute
	bool removeBaseJumperOnStun = view_as<bool>(GetArgF(boss, "rage_stun", "basejumper", 9, float(GetConVarInt(cvarBaseJumperStun)), 0));
 // Max Duration
	float maxduration = GetArgF(boss, "rage_stun", "max", 11, 0.0, 1);
 // Add Duration
	float addduration = GetArgF(boss, "rage_stun", "add", 12, 0.0, 0);
	if(maxduration <= 0)
	{
		maxduration = duration;
		addduration = 0.0;
	}
 // Solo Rage Duration
	float soloduration = GetArgF(boss, "rage_stun", "solo", 13, 0.0, 0);
	if(soloduration <= 0)
		soloduration = duration;

	int[] victim = new int[MaxClients+1];
	int victims;
	if(addduration!=0 || soloduration!=duration)
	{
		for(int target=1; target<=MaxClients; target++)
		{
			if(IsClientInGame(target) && IsPlayerAlive(target) && target!=client && (friendly || GetClientTeam(target)!=GetClientTeam(client)))
			{
				GetEntPropVector(target, Prop_Send, "m_vecOrigin", targetPosition);
				if((!TF2_IsPlayerInCondition(target, TFCond_Ubercharged) || (ignore>0 && ignore!=2)) && (!TF2_IsPlayerInCondition(target, TFCond_MegaHeal) || ignore>1) && GetVectorDistance(bossPosition, targetPosition)<=distance)
				{
					victim[victims] = target;
					victims++;
				}
			}
		}
	}

	if(victims < 1)
		return Plugin_Continue;

	if(victims > 0)
	{
		if(victims<2 && (duration!=soloduration || GetConVarBool(cvarSoloShame)))
		{
			solorage = true;
			if(duration != soloduration)
				duration = soloduration;
		}
		else if(victims>1 && duration<maxduration)
		{
			duration += addduration*(victims-1);
			if(duration > maxduration)
				duration = maxduration;
		}
	}

	if(solorage)
	{
		static char bossName[64];
		for(int target=1; target<=MaxClients; target++)
		{
			if(IsClientInGame(target))
			{
				FF2_GetBossName(boss, bossName, sizeof(bossName), _, target);
				FPrintToChat(target, "%t", "Solo Rage", bossName);
			}
		}
		CreateTimer(duration, Timer_SoloRageResult, victim[victims-1]);
	}

	while(victims > 0)
	{
		victims--;
		if(removeBaseJumperOnStun)
			TF2_RemoveCondition(victim[victims], TFCond_Parachute);

		TF2_StunPlayer(victim[victims], duration, slowdown, flagOverride, sounds ? client : 0);
		if(particleEffect[0])
			CreateTimer(duration, Timer_RemoveEntity, EntIndexToEntRef(AttachParticle(victim[victims], particleEffect, 75.0)), TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Continue;
}

public Action Timer_SoloRageResult(Handle timer, any client)
{
	if(!IsClientInGame(client) || FF2_GetRoundState()!=1)
		return Plugin_Continue;

	if(IsPlayerAlive(client))
	{
		FPrintToChatAll("%t", "Solo Rage Fail");
	}
	else
	{
		FPrintToChatAll("%t", "Solo Rage Win");
	}

	return Plugin_Continue;
}

stock int ReadHexOrDecInt(char hexOrDecString[12])	// Credits to sarysa
{
	if(!StrContains(hexOrDecString, "0x"))
	{
		int result = 0;
		for(int i=2; i<10 && hexOrDecString[i]!=0; i++)
		{
			result = result<<4;
				
			if(hexOrDecString[i]>='0' && hexOrDecString[i]<='9')
			{
				result += hexOrDecString[i]-'0';
			}
			else if(hexOrDecString[i]>='a' && hexOrDecString[i]<='f')
			{
				result += hexOrDecString[i]-'a'+10;
			}
			else if(hexOrDecString[i]>='A' && hexOrDecString[i]<='F')
			{
				result += hexOrDecString[i]-'A'+10;
			}
		}
		return result;
	}
	else
	{
		return StringToInt(hexOrDecString);
	}
}


/*	Uber	*/

public Action Timer_StopUber(Handle timer, any boss)
{
	SetEntProp(GetClientOfUserId(FF2_GetBossUserId(boss)), Prop_Data, "m_takedamage", 2);
	return Plugin_Continue;
}


/*	Building Stun	*/

void Rage_StunBuilding(const char[] ability_name, int boss)
{
	int client = GetClientOfUserId(FF2_GetBossUserId(boss));
	static float bossPosition[3], sentryPosition[3];
	GetEntPropVector(GetClientOfUserId(FF2_GetBossUserId(boss)), Prop_Send, "m_vecOrigin", bossPosition);

 // Duration
	float duration = GetArgF(boss, ability_name, "duration", 1, 7.0, 2);
 // Distance
	float distance = GetArgF(boss, ability_name, "distance", 2, 0.0, 1);
	if(distance <= 0)
		distance = FF2_GetRageDist(boss, this_plugin_name, ability_name);
 // Building Health
 	bool destory = false;
	float health = GetArgF(boss, ability_name, "health", 3, 1.0, 0, true);
	if(health <= 0)
		destory = true;
 // Sentry Ammo
	float ammo = GetArgF(boss, ability_name, "ammo", 4, 1.0, 0);
 // Sentry Rockets
	float rockets = GetArgF(boss, ability_name, "rocket", 5, 1.0, 0);
 // Particle Effect
	char particleEffect[48];
	FF2_GetArgS(boss, this_plugin_name, ability_name, "particle", 6, particleEffect, sizeof(particleEffect));
	if(!particleEffect[0])
		particleEffect = SPOOK;
 // Buildings
	int buildings = RoundFloat(GetArgF(boss, ability_name, "building", 7, 1.0, 2));
	// 1: Sentry
	// 2: Dispenser
	// 3: Teleporter
	// 4: Sentry + Dispenser
	// 5: Sentry + Teleporter
	// 6: Dispenser + Teleporter
	// 7: ALL
 // Friendly Fire
	bool friendly = view_as<bool>(GetArgF(boss, ability_name, "friendly", 8, float(GetConVarInt(FindConVar("mp_friendlyfire"))), 0));

	if(buildings>0 && buildings!=2 && buildings!=3 && buildings!=6)
	{
		int sentry;
		while((sentry=FindEntityByClassname(sentry, "obj_sentrygun")) != -1)
		{
			if((((GetEntProp(sentry, Prop_Send, "m_nSkin") % 2)!=(GetClientTeam(client) % 2)) || friendly) && !GetEntProp(sentry, Prop_Send, "m_bCarried") && !GetEntProp(sentry, Prop_Send, "m_bPlacing"))
			{
				GetEntPropVector(sentry, Prop_Send, "m_vecOrigin", sentryPosition);
				if(GetVectorDistance(bossPosition, sentryPosition) <= distance)
				{
					if(destory)
					{
						SDKHooks_TakeDamage(sentry, client, client, 9001.0, DMG_GENERIC, -1);
					}
					else
					{
						if(health != 1)
							SDKHooks_TakeDamage(sentry, client, client, GetEntProp(sentry, Prop_Send, "m_iMaxHealth")*health, DMG_GENERIC, -1);

						if(ammo>=0 && ammo<=1 && ammo!=1)
							SetEntProp(sentry, Prop_Send, "m_iAmmoShells", GetEntProp(sentry, Prop_Send, "m_iAmmoShells")*ammo);

						if(rockets>=0 && rockets<=1 && rockets!=1)
							SetEntProp(sentry, Prop_Send, "m_iAmmoRockets", GetEntProp(sentry, Prop_Send, "m_iAmmoRockets")*rockets);

						if(duration > 0)
						{
							SetEntProp(sentry, Prop_Send, "m_bDisabled", 1);
							CreateTimer(duration, Timer_RemoveEntity, EntIndexToEntRef(AttachParticle(sentry, particleEffect, 75.0)), TIMER_FLAG_NO_MAPCHANGE);
							CreateTimer(duration, Timer_EnableBuilding, EntIndexToEntRef(sentry), TIMER_FLAG_NO_MAPCHANGE);
						}
					}
				}
			}
		}
	}

	if(buildings>1 && buildings!=3 && buildings!=5)
	{
		int dispenser;
		while((dispenser=FindEntityByClassname(dispenser, "obj_dispenser")) != -1)
		{
			if((((GetEntProp(dispenser, Prop_Send, "m_nSkin") % 2)!=(GetClientTeam(client) % 2)) || friendly) && !GetEntProp(dispenser, Prop_Send, "m_bCarried") && !GetEntProp(dispenser, Prop_Send, "m_bPlacing"))
			{
				GetEntPropVector(dispenser, Prop_Send, "m_vecOrigin", sentryPosition);
				if(GetVectorDistance(bossPosition, sentryPosition) <= distance)
				{
					if(destory)
					{
						SDKHooks_TakeDamage(dispenser, client, client, 9001.0, DMG_GENERIC, -1);
					}
					else
					{
						if(health != 1)
							SDKHooks_TakeDamage(dispenser, client, client, GetEntProp(dispenser, Prop_Send, "m_iMaxHealth")*health, DMG_GENERIC, -1);

						if(duration > 0)
						{
							SetEntProp(dispenser, Prop_Send, "m_bDisabled", 1);
							CreateTimer(duration, Timer_RemoveEntity, EntIndexToEntRef(AttachParticle(dispenser, particleEffect, 75.0)), TIMER_FLAG_NO_MAPCHANGE);
							CreateTimer(duration, Timer_EnableBuilding, EntIndexToEntRef(dispenser), TIMER_FLAG_NO_MAPCHANGE);
						}
					}
				}
			}
		}
	}

	if(buildings>2 && buildings!=4)
	{
		int teleporter;
		while((teleporter=FindEntityByClassname(teleporter, "obj_teleporter")) != -1)
		{
			if((((GetEntProp(teleporter, Prop_Send, "m_nSkin") % 2)!=(GetClientTeam(client) % 2)) || friendly) && !GetEntProp(teleporter, Prop_Send, "m_bCarried") && !GetEntProp(teleporter, Prop_Send, "m_bPlacing"))
			{
				GetEntPropVector(teleporter, Prop_Send, "m_vecOrigin", sentryPosition);
				if(GetVectorDistance(bossPosition, sentryPosition) <= distance)
				{
					if(destory)
					{
						SDKHooks_TakeDamage(teleporter, client, client, 9001.0, DMG_GENERIC, -1);
					}
					else
					{
						if(health != 1)
							SDKHooks_TakeDamage(teleporter, client, client, GetEntProp(teleporter, Prop_Send, "m_iMaxHealth")*health, DMG_GENERIC, -1);

						if(duration > 0)
						{
							SetEntProp(teleporter, Prop_Send, "m_bDisabled", 1);
							CreateTimer(duration, Timer_RemoveEntity, EntIndexToEntRef(AttachParticle(teleporter, particleEffect, 75.0)), TIMER_FLAG_NO_MAPCHANGE);
							CreateTimer(duration, Timer_EnableBuilding, EntIndexToEntRef(teleporter), TIMER_FLAG_NO_MAPCHANGE);
						}
					}
				}
			}
		}
	}
}

public Action Timer_EnableBuilding(Handle timer, any sentryid)
{
	int sentry = EntRefToEntIndex(sentryid);
	if(sentry > MaxClients)
		SetEntProp(sentry, Prop_Send, "m_bDisabled", 0);

	return Plugin_Continue;
}


/*	Instant Teleport	*/


public Action Timer_StunBoss(Handle timer, any boss)
{
	int client = GetClientOfUserId(FF2_GetBossUserId(boss));
	if(!IsValidEntity(client))
		return;

	TF2_StunPlayer(client, Tstun, Tslowdown, TflagOverride, 0);
}


/*	Dissolve	*/

public Action Timer_DissolveRagdoll(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	int ragdoll = -1;
	if(client && IsClientInGame(client))
		ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");

	if(IsValidEntity(ragdoll))
		DissolveRagdoll(ragdoll);
}

int DissolveRagdoll(int ragdoll)
{
	int dissolver = CreateEntityByName("env_entity_dissolver");
	if(dissolver == -1)
		return;

	DispatchKeyValue(dissolver, "dissolvetype", "0");
	DispatchKeyValue(dissolver, "magnitude", "200");
	DispatchKeyValue(dissolver, "target", "!activator");

	AcceptEntityInput(dissolver, "Dissolve", ragdoll);
	AcceptEntityInput(dissolver, "Kill");
}


/*	Clone Attack	*/

void Rage_Clone(const char[] ability_name, int boss)
{
	Handle bossKV[8];
	static char bossName[64];
	int client = GetClientOfUserId(FF2_GetBossUserId(boss));
	bool changeModel = view_as<bool>(GetArgF(boss, ability_name, "custom model", 1, 0.0, 0));
	int weaponMode = RoundFloat(GetArgF(boss, ability_name, "weapon mode", 2, 0.0, 0));
	static char model[PLATFORM_MAX_PATH];
	FF2_GetArgS(boss, this_plugin_name, ability_name, "model", 3, model, sizeof(model));
	int class = RoundFloat(GetArgF(boss, ability_name, "class", 4, 0.0, 0));
	float ratio = GetArgF(boss, ability_name, "ratio", 5, 0.0, 0);
	static char classname[64];
	FF2_GetArgS(boss, this_plugin_name, ability_name, "classname", 6, classname, sizeof(classname));
	int index = RoundFloat(GetArgF(boss, ability_name, "index", 7, 191.0, 1));
	static char attributes[128];
	FF2_GetArgS(boss, this_plugin_name, ability_name, "attributes", 8, attributes, sizeof(attributes));
	int ammo = RoundFloat(GetArgF(boss, ability_name, "ammo", 9, -1.0, 0));
	int clip = RoundFloat(GetArgF(boss, ability_name, "clip", 10, -1.0, 0));
	int health = RoundFloat(GetArgF(boss, ability_name, "health", 11, 0.0, 0, true));

	static float position[3], velocity[3];
	GetEntPropVector(GetClientOfUserId(FF2_GetBossUserId(boss)), Prop_Data, "m_vecOrigin", position);

	int maxKV;
	for(maxKV=0; maxKV<8; maxKV++)
	{
		if(!(bossKV[maxKV] = FF2_GetSpecialKV(maxKV)))
			break;
	}

	int alive, dead;
	Handle players = CreateArray();
	for(int target=1; target<=MaxClients; target++)
	{
		if(IsClientInGame(target))
		{
			TFTeam team = TF2_GetClientTeam(target);
			if(team>TFTeam_Spectator && team!=TF2_GetClientTeam(client))
			{
				if(IsPlayerAlive(target))
				{
					alive++;
				}
				else if(FF2_GetBossIndex(target) == -1)  //Don't let dead bosses become clones
				{
					PushArrayCell(players, target);
					dead++;
				}
			}
		}
	}

	int totalMinions = (ratio ? RoundToCeil(alive*ratio) : MaxClients);  //If ratio is 0, use MaxClients instead
	int config = GetRandomInt(0, maxKV-1);
	int clone, temp;
	for(int i=1; i<=dead && i<=totalMinions; i++)
	{
		temp = GetRandomInt(0, GetArraySize(players)-1);
		clone = GetArrayCell(players, temp);
		RemoveFromArray(players, temp);

		FF2_SetFF2flags(clone, FF2_GetFF2flags(clone)|FF2FLAG_ALLOWSPAWNINBOSSTEAM|FF2FLAG_CLASSTIMERDISABLED);
		ChangeClientTeam(clone, GetClientTeam(client));
		TF2_RespawnPlayer(clone);
		CloneOwnerIndex[clone] = client;
		TF2_SetPlayerClass(clone, (class ? (view_as<TFClassType>(class)) : (view_as<TFClassType>(KvGetNum(bossKV[config], "class", 0)))), _, false);

		if(changeModel)
		{
			if(model[0] == '\0')
				KvGetString(bossKV[config], "model", model, sizeof(model));

			SetVariantString(model);
			AcceptEntityInput(clone, "SetCustomModel");
			SetEntProp(clone, Prop_Send, "m_bUseClassAnimations", 1);
		}

		switch(weaponMode)
		{
			case 0:
			{
				TF2_RemoveAllWeapons(clone);
			}
			case 1:
			{
				int weapon;
				TF2_RemoveAllWeapons(clone);
				if(classname[0] == '\0')
					classname = "tf_weapon_bottle";

				if(attributes[0] == '\0')
					attributes = "68 ; -1";

				weapon = FF2_SpawnWeapon(clone, classname, index, 101, 6, attributes);
				if(StrEqual(classname, "tf_weapon_builder") && index!=735)  //PDA, normal sapper
				{
					SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 1, _, 0);
					SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 1, _, 1);
					SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 1, _, 2);
					SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 3);
				}
				else if(StrEqual(classname, "tf_weapon_sapper") || index==735)  //Sappers, normal sapper
				{
					SetEntProp(weapon, Prop_Send, "m_iObjectType", 3);
					SetEntProp(weapon, Prop_Data, "m_iSubType", 3);
					SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 0);
					SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 1);
					SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 2);
					SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 1, _, 3);
				}

				if(IsValidEntity(weapon))
				{
					SetEntPropEnt(clone, Prop_Send, "m_hActiveWeapon", weapon);
					SetEntProp(weapon, Prop_Send, "m_iWorldModelIndex", -1);
				}

				if(ammo>=0 || clip>=0)
					FF2_SetAmmo(clone, weapon, ammo, clip);
			}
		}

		if(health)
		{
			SetEntProp(clone, Prop_Data, "m_iMaxHealth", health);
			SetEntProp(clone, Prop_Data, "m_iHealth", health);
			SetEntProp(clone, Prop_Send, "m_iHealth", health);
		}

		velocity[0] = GetRandomFloat(300.0, 500.0)*(GetRandomInt(0, 1) ? 1:-1);
		velocity[1] = GetRandomFloat(300.0, 500.0)*(GetRandomInt(0, 1) ? 1:-1);
		velocity[2] = GetRandomFloat(300.0, 500.0);
		TeleportEntity(clone, position, NULL_VECTOR, velocity);

		FF2_GetBossName(boss, bossName, sizeof(bossName), 0, clone);
		PrintHintText(clone, "%t", "seeldier_rage_message", bossName);

		SDKHook(clone, SDKHook_OnTakeDamage, SaveMinion);
		CreateTimer(4.0, Timer_Enable_Damage, GetClientUserId(clone), TIMER_FLAG_NO_MAPCHANGE);

		Handle data;
		CreateDataTimer(0.1, Timer_EquipModel, data, TIMER_FLAG_NO_MAPCHANGE);
		WritePackCell(data, GetClientUserId(clone));
		WritePackString(data, model);
	}
	CloseHandle(players);

	int entity, owner;
	while((entity=FindEntityByClassname(entity, "tf_wearable")) != -1)
	{
		if((owner=GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity"))<=MaxClients && owner>0 && GetClientTeam(owner)==GetClientTeam(client))
			TF2_RemoveWearable(owner, entity);
	}

	while((entity=FindEntityByClassname(entity, "tf_wearable_razorback")) != -1)
	{
		if((owner=GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity"))<=MaxClients && owner>0 && GetClientTeam(owner)==GetClientTeam(client))
			TF2_RemoveWearable(owner, entity);
	}
	
	while((entity=FindEntityByClassname(entity, "tf_wearable_demoshield")) != -1)
	{
		if((owner=GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity"))<=MaxClients && owner>0 && GetClientTeam(owner)==GetClientTeam(client))
			TF2_RemoveWearable(owner, entity);
	}

	while((entity=FindEntityByClassname(entity, "tf_powerup_bottle")) != -1)
	{
		if((owner=GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity"))<=MaxClients && owner>0 && GetClientTeam(owner)==GetClientTeam(client))
			TF2_RemoveWearable(owner, entity);
	}
}

public Action Timer_EquipModel(Handle timer, any pack)
{
	ResetPack(pack);
	int client = GetClientOfUserId(ReadPackCell(pack));
	if(client && IsClientInGame(client) && IsPlayerAlive(client))
	{
		static char model[PLATFORM_MAX_PATH];
		ReadPackString(pack, model, PLATFORM_MAX_PATH);
		SetVariantString(model);
		AcceptEntityInput(client, "SetCustomModel");
		SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
	}
}

public Action Timer_Enable_Damage(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if(client)
	{
		FF2_SetFF2flags(client, FF2_GetFF2flags(client) & ~FF2FLAG_ALLOWSPAWNINBOSSTEAM);
		SDKUnhook(client, SDKHook_OnTakeDamage, SaveMinion);
	}
	return Plugin_Continue;
}

public Action SaveMinion(int client, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if(attacker > MaxClients)
	{
		static char edict[64];
		if(GetEntityClassname(attacker, edict, sizeof(edict)) && !strcmp(edict, "trigger_hurt", false))
		{
			int target;
			static float position[3];
			bool otherTeamIsAlive;
			for(int clone=1; clone<=MaxClients; clone++)
			{
				if(IsValidEntity(clone) && IsClientInGame(clone) && IsPlayerAlive(clone) && CloneOwnerIndex[clone]>0 && CloneOwnerIndex[clone]<=MaxClients && IsClientInGame(CloneOwnerIndex[clone]) && IsPlayerAlive(CloneOwnerIndex[clone]) && GetClientTeam(clone)!=GetClientTeam(CloneOwnerIndex[clone]))
				{
					otherTeamIsAlive = true;
					break;
				}
			}

			int tries;
			do
			{
				tries++;
				target = GetRandomInt(1, MaxClients);
				if(tries == 100)
					return Plugin_Continue;
			}
			while(otherTeamIsAlive && (!IsValidEntity(target) || GetClientTeam(target)==GetClientTeam(CloneOwnerIndex[target]) || !IsPlayerAlive(target)));

			GetEntPropVector(target, Prop_Data, "m_vecOrigin", position);
			TeleportEntity(client, position, NULL_VECTOR, NULL_VECTOR);
			TF2_StunPlayer(client, 2.0, 0.0, TF_STUNFLAGS_GHOSTSCARE|TF_STUNFLAG_NOSOUNDOREFFECT, client);
		}
	}
	return Plugin_Handled;
}


/*	Trade Spam	*/

public Action Timer_Demopan_Rage(Handle timer, any count)	//TODO: Make this rage configurable
{
	if(count == 13)  //Rage has finished-reset it in 6 seconds (trade_0 is 100% transparent apparently)
	{
		CreateTimer(6.0, Timer_Demopan_Rage, 0, TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		static char overlay[PLATFORM_MAX_PATH];
		Format(overlay, sizeof(overlay), "r_screenoverlay \"freak_fortress_2/demopan/trade_%i\"", count);

		SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & ~FCVAR_CHEAT);  //Allow normal players to use r_screenoverlay
		for(int client=1; client<=MaxClients; client++)
		{
			if(IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client)!=Demopan)
				ClientCommand(client, overlay);
		}
		SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & FCVAR_CHEAT);  //Reset the cheat permissions

		if(count)
		{
			EmitSoundToAll(SOUND_DEMOPAN_RAGE, _, _, _, _, _, _, _, _, _, false);
			CreateTimer(count==1 ? 1.0 : 0.5/float(count), Timer_Demopan_Rage, count+1, TIMER_FLAG_NO_MAPCHANGE);  //Give a longer delay between the first and second overlay for "smoothness"
		}
		else  //Stop the rage
		{
			return Plugin_Stop;
		}
	}
	return Plugin_Continue;
}


/*	CBS Bow Rage	*/

void Rage_Bow(int boss)
{
	int client = GetClientOfUserId(FF2_GetBossUserId(boss));
	TF2_RemoveWeaponSlot(client, TFWeaponSlot_Primary);
	static char attributes[64], classname[64];

	FF2_GetArgS(boss, this_plugin_name, "rage_cbs_bowrage", "attributes", 1, attributes, sizeof(attributes));
	if(!attributes[0])
	{
		if(GetConVarBool(cvarStrangeWep))
		{
			strcopy(attributes, sizeof(attributes), "6 ; 0.5 ; 37 ; 0.0 ; 214 ; 333 ; 280 ; 19");
		}
		else
		{
			strcopy(attributes, sizeof(attributes), "6 ; 0.5 ; 37 ; 0.0 ; 280 ; 19");
		}
	}

	int maximum = RoundFloat(GetArgF(boss, "rage_cbs_bowrage", "max", 2, 9.0, 2));
	float ammo = GetArgF(boss, "rage_cbs_bowrage", "ammo", 3, 1.0, 2);
	int clip = RoundFloat(GetArgF(boss, "rage_cbs_bowrage", "clip", 4, 1.0, 1));
	FF2_GetArgS(boss, this_plugin_name, "rage_cbs_bowrage", "classname", 5, classname, sizeof(classname));
	if(!classname[0])
		strcopy(classname, sizeof(classname), "tf_weapon_compound_bow");

	int index = RoundFloat(GetArgF(boss, "rage_cbs_bowrage", "index", 6, 1005.0, 1));
	int level = RoundFloat(GetArgF(boss, "rage_cbs_bowrage", "level", 7, 101.0, 1));
	int quality = RoundFloat(GetArgF(boss, "rage_cbs_bowrage", "quality", 8, 5.0, 1));
	int weapon = FF2_SpawnWeapon(client, classname, index, level, quality, attributes);
	if(GetArgF(boss, "rage_cbs_bowrage", "force switch", 9, 1.0, 0))
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);

	TFTeam team = (TF2_GetClientTeam(client)==TFTeam_Blue ? TFTeam_Red : TFTeam_Blue);

	int otherTeamAlivePlayers;
	for(int target=1; target<=MaxClients; target++)
	{
		if(IsClientInGame(target) && TF2_GetClientTeam(target)==team && IsPlayerAlive(target))
			otherTeamAlivePlayers++;
	}

	ammo *= otherTeamAlivePlayers;	// Ammo multiplied by alive players
	
	if(ammo > maximum)		// Maximum or lower ammo
		ammo = float(maximum);

	ammo -= clip;			// Ammo subtracted by clip

	while(ammo<0 && clip>=0)	// Remove clip until ammo or clip is zero
	{
		clip--;
		ammo++;
	}
					// If clip is positive or zero
	if(clip >= 0)
		FF2_SetAmmo(client, weapon, RoundToFloor(ammo), clip);
}


/*	Explosive Dance	*/

public Action Timer_Prepare_Explosion_Rage(Handle timer, Handle data)
{
	int boss = ReadPackCell(data);
	int client = GetClientOfUserId(FF2_GetBossUserId(boss));
	if(!client || !IsClientInGame(client))
		return Plugin_Continue;

	static char ability_name[64];
	ReadPackString(data, ability_name, sizeof(ability_name));

	ExpCount[client] = RoundFloat(GetArgF(boss, ability_name, "count", 3, 35.0, 2));
	ExpDamage[client] = GetArgF(boss, ability_name, "damage", 4, 180.0, 0);
	ExpRange[client] = RoundFloat(GetArgF(boss, ability_name, "distance", 5, 350.0, 1));

	if(GetArgF(boss, ability_name, "taunt", 6, 1.0, 0))
		ClientCommand(client, "+taunt");

	CreateTimer(GetArgF(boss, ability_name, "delay", 2, 0.12, 1), Timer_Rage_Explosive_Dance, boss, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

	static float position[3];
	GetEntPropVector(client, Prop_Data, "m_vecOrigin", position);

	static char sound[PLATFORM_MAX_PATH];
	FF2_GetArgS(boss, this_plugin_name, ability_name, "sound", 1, sound, PLATFORM_MAX_PATH);
	if(sound[0])
	{
		FF2_EmitVoiceToAll(sound, client, _, _, _, _, _, client, position);
		FF2_EmitVoiceToAll(sound, client, _, _, _, _, _, client, position);
		for(int target=1; target<=MaxClients; target++)
		{
			if(IsClientInGame(target) && target!=client)
			{
				EmitSoundToClient(target, sound, client, _, _, _, _, _, client, position);
				EmitSoundToClient(target, sound, client, _, _, _, _, _, client, position);
			}
		}
	}
	return Plugin_Continue;
}

public Action Timer_Rage_Explosive_Dance(Handle timer, any boss)
{
	static int count[MAXTF2PLAYERS];
	int client = GetClientOfUserId(FF2_GetBossUserId(boss));
	if(!client || !IsClientInGame(client))
	{
		count[client] = 0;
		return Plugin_Stop;
	}

	count[client]++;
	if(count[client]<=ExpCount[client] && IsPlayerAlive(client))
	{
		SetEntityMoveType(client, MOVETYPE_NONE);
		static float bossPosition[3], explosionPosition[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", bossPosition);
		explosionPosition[2] = bossPosition[2];
		int range;
		for(int i; i<5; i++)
		{
			int explosion = CreateEntityByName("env_explosion");
			DispatchKeyValueFloat(explosion, "DamageForce", ExpDamage[client]);

			SetEntProp(explosion, Prop_Data, "m_iMagnitude", 280, 4);
			SetEntProp(explosion, Prop_Data, "m_iRadiusOverride", 200, 4);
			SetEntPropEnt(explosion, Prop_Data, "m_hOwnerEntity", client);

			DispatchSpawn(explosion);

			explosionPosition[0] = bossPosition[0]+GetRandomInt((ExpRange[client]*-1), ExpRange[client]);
			explosionPosition[1] = bossPosition[1]+GetRandomInt((ExpRange[client]*-1), ExpRange[client]);
			if(!(GetEntityFlags(client) & FL_ONGROUND))
			{
				range = RoundToFloor(view_as<float>(ExpRange[client])*3.0/7.0);
				explosionPosition[2] = bossPosition[2]+GetRandomInt((range*-1), range);
			}
			else
			{
				range = RoundToFloor(view_as<float>(ExpRange[client])*2.0/7.0);
				explosionPosition[2] = bossPosition[2]+GetRandomInt(0, range);
			}
			TeleportEntity(explosion, explosionPosition, NULL_VECTOR, NULL_VECTOR);
			AcceptEntityInput(explosion, "Explode");
			AcceptEntityInput(explosion, "kill");
		}
	}
	else
	{
		SetEntityMoveType(client, MOVETYPE_WALK);
		count[client] = 0;
		return Plugin_Stop;
	}
	return Plugin_Continue;
}


/*	Matrix Attack	*/

void Rage_Slowmo(int boss)
{
	float duration = GetArgF(boss, "rage_matrix_attack", "duration", 1, 1.0, 2)+1.0;
	float timescale = GetArgF(boss, "rage_matrix_attack", "timescale", 2, 0.1, 2);

	FF2_SetFF2flags(boss, FF2_GetFF2flags(boss)|FF2FLAG_CHANGECVAR);
	cvarTimeScale.FloatValue = timescale;
	SlowMoTimer = CreateTimer(duration*timescale, Timer_StopSlowMo, boss, TIMER_FLAG_NO_MAPCHANGE);
	int client = GetClientOfUserId(FF2_GetBossUserId(boss));
	FF2Flags[client] |= FLAG_SLOWMOREADYCHANGE|FLAG_ONSLOWMO;
	UpdateClientCheatValue("1");

	if(client)
		CreateTimer(duration*timescale, Timer_RemoveEntity, EntIndexToEntRef(AttachParticle(client, GetClientTeam(client)==view_as<int>(TFTeam_Blue) ? "scout_dodge_blue" : "scout_dodge_red", 75.0)), TIMER_FLAG_NO_MAPCHANGE);

	if(timescale != 1)
	{
		EmitSoundToAll(SOUND_SLOW_MO_START, _, _, _, _, _, _, _, _, _, false);
		EmitSoundToAll(SOUND_SLOW_MO_START, _, _, _, _, _, _, _, _, _, false);
	}
}

public Action Timer_StopSlowMo(Handle timer, any boss)
{
	SlowMoTimer = INVALID_HANDLE;
	oldTarget = 0;
	float timescale = cvarTimeScale.FloatValue;
	cvarTimeScale.FloatValue = 1.0;
	UpdateClientCheatValue("0");
	if(boss != -1)
	{
		FF2_SetFF2flags(boss, FF2_GetFF2flags(boss) & ~FF2FLAG_CHANGECVAR);
		int client = GetClientOfUserId(FF2_GetBossUserId(boss));
		FF2Flags[client] &= ~FLAG_ONSLOWMO;
	}

	if(timescale != 1)
	{
		EmitSoundToAll(SOUND_SLOW_MO_END, _, _, _, _, _, _, _, _, _, false);
		EmitSoundToAll(SOUND_SLOW_MO_END, _, _, _, _, _, _, _, _, _, false);
	}
	return Plugin_Continue;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float velocity[3], float angles[3], int &weapon)
{
	int boss = FF2_GetBossIndex(client);
	if(boss < 0)
		return Plugin_Continue;

	if(NoHud[boss] || NoCharge[boss] || NoSlot[boss])
	{
		if(NoHud[boss])
			FF2_SetFF2flags(client, FF2_GetFF2flags(client)|FF2FLAG_HUDDISABLED);

		static char buffer[256];
		Handle iter = GetPluginIterator();
		Handle plugin;
		while(MorePlugins(iter))
		{
			plugin = ReadPlugin(iter);
			GetPluginFilename(plugin, buffer, sizeof(buffer));
			if(StrContains(buffer, "ff2_dynamic_defaults.ff2", false) == -1)
				continue;

			if(NoHud[boss])
			{
				Function func = GetFunctionByName(plugin, "DD_SetForceHUDEnabled");
				if(func != INVALID_FUNCTION)
				{
					Call_StartFunction(plugin, func);
					Call_PushCell(client);
					Call_PushCell(false);
					Call_Finish();
				}
			}

			if(NoCharge[boss] || NoSlot[boss])
			{
				Function func = GetFunctionByName(plugin, "DD_SetDisabled");
				if(func != INVALID_FUNCTION)
				{
					Call_StartFunction(plugin, func);
					Call_PushCell(client);
					Call_PushCell(NoCharge[boss] || NoSlot[boss]==1);
					Call_PushCell(NoCharge[boss] || NoSlot[boss]==1);
					Call_PushCell(NoCharge[boss] || NoSlot[boss]==2);
					Call_PushCell(NoCharge[boss] || NoSlot[boss]==3);
					Call_Finish();
				}
			}
			break;
		}
		delete iter;
	}

	if(Cond[boss] != TFCond_Slowed)
		TF2_AddCondition(client, Cond[boss]);

	if(Outline[boss])
		FF2_SetClientGlow(client, 12.0, 12.0);

	if(!(FF2Flags[client] & FLAG_ONSLOWMO))
		return Plugin_Continue;

	if(buttons & IN_ATTACK)
	{
		FF2Flags[client] &= ~FLAG_SLOWMOREADYCHANGE;
		CreateTimer(GetArgF(boss, "rage_matrix_attack", "delay", 3, 0.2, 1), Timer_SlowMoChange, boss, TIMER_FLAG_NO_MAPCHANGE);

		static float bossPosition[3], endPosition[3], eyeAngles[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", bossPosition);
		bossPosition[2] += 65;
		GetClientEyeAngles(client, eyeAngles);

		Handle trace = TR_TraceRayFilterEx(bossPosition, eyeAngles, MASK_SOLID, RayType_Infinite, TraceRayDontHitSelf);
		TR_GetEndPosition(endPosition, trace);
		endPosition[2] += 100;
		SubtractVectors(endPosition, bossPosition, velocity);
		NormalizeVector(velocity, velocity);
		ScaleVector(velocity, 2012.0);
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);
		int target = TR_GetEntityIndex(trace);
		if(target && target<=MaxClients)
		{
			Handle data;
			CreateDataTimer(0.15, Timer_Rage_SlowMo_Attack, data);
			WritePackCell(data, GetClientUserId(client));
			WritePackCell(data, GetClientUserId(target));
			ResetPack(data);
		}
		CloseHandle(trace);
	}
	return Plugin_Continue;
}

public Action Timer_Rage_SlowMo_Attack(Handle timer, Handle data)
{
	int client = GetClientOfUserId(ReadPackCell(data));
	int target = GetClientOfUserId(ReadPackCell(data));
	if(client && target && IsClientInGame(client) && IsClientInGame(target) && GetClientTeam(client)!=GetClientTeam(target))
	{
		static float clientPosition[3], targetPosition[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", clientPosition);
		GetEntPropVector(target, Prop_Send, "m_vecOrigin", targetPosition);
		if(GetVectorDistance(clientPosition, targetPosition)<=1500 && target!=oldTarget)
		{
			SetEntProp(client, Prop_Send, "m_bDucked", 1);
			SetEntityFlags(client, GetEntityFlags(client)|FL_DUCKING);
			SDKHooks_TakeDamage(target, client, client, 850.0);
			TeleportEntity(client, targetPosition, NULL_VECTOR, NULL_VECTOR);
			oldTarget = target;
		}
	}
}

public bool TraceRayDontHitSelf(int entity, int mask)
{
	if(!entity || entity>MaxClients)
		return true;

	return !(FF2Flags[entity] & FLAG_ONSLOWMO);
}

public Action Timer_SlowMoChange(Handle timer, any boss)
{
	int client = GetClientOfUserId(FF2_GetBossUserId(boss));
	FF2Flags[client] |= FLAG_SLOWMOREADYCHANGE;
	return Plugin_Continue;
}

stock void UpdateClientCheatValue(const char[] value)
{
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsClientInGame(client) && !IsFakeClient(client))
			cvarCheats.ReplicateToClient(client, value);
	}
}


/*	Extras	*/

float GetArgF(int boss, const char[] abilityName, const char[] argName, int argNumber, float defaultValue, int valueCheck, bool health = false)
{
	static char buffer[1024];
	FF2_GetArgS(boss, this_plugin_name, abilityName, argName, argNumber, buffer, sizeof(buffer));
	
	if(!health) {
		float val;
		return StringToFloatEx(buffer, val) ? val:defaultValue;
	}
	
	if(buffer[0])
	{
		return ParseFormula(boss, buffer, defaultValue, abilityName, argName, argNumber, valueCheck); 
	}
	else if((valueCheck==1 && defaultValue<0) || (valueCheck==2 && defaultValue<=0))
	{
		FF2_ReportError(boss, "[Boss] Formula at arg%i/%s for %s is not allowed to be blank.", argNumber, argName, abilityName);
		return 0.0;
	}
	return defaultValue;
}
stock int Operate(Handle sumArray, int &bracket, float value, Handle _operator)
{
	float sum = GetArrayCell(sumArray, bracket);
	switch(GetArrayCell(_operator, bracket))
	{
		case Operator_Add:
		{
			SetArrayCell(sumArray, bracket, sum+value);
		}
		case Operator_Subtract:
		{
			SetArrayCell(sumArray, bracket, sum-value);
		}
		case Operator_Multiply:
		{
			SetArrayCell(sumArray, bracket, sum*value);
		}
		case Operator_Divide:
		{
			if(!value)
			{
				FF2_ReportError(-1, "[Boss] Detected a divide by 0 in a boss with %s!", this_plugin_name);
				bracket = 0;
				return;
			}
			SetArrayCell(sumArray, bracket, sum/value);
		}
		case Operator_Exponent:
		{
			SetArrayCell(sumArray, bracket, Pow(sum, value));
		}
		default:
		{
			SetArrayCell(sumArray, bracket, value);  //This means we're dealing with a constant
		}
	}
	SetArrayCell(_operator, bracket, Operator_None);
}

stock void OperateString(Handle sumArray, int &bracket, char[] value, int size, Handle _operator)
{
	if(!StrEqual(value, ""))  //Make sure 'value' isn't blank
	{
		Operate(sumArray, bracket, StringToFloat(value), _operator);
		strcopy(value, size, "");
	}
}

public float ParseFormula(int boss, const char[] key, float defaultValue, const char[] abilityName, const char[] argName, int argNumber, int valueCheck)
{
	static char formula[1024];
	strcopy(formula, sizeof(formula), key);
	int size = 1;
	int matchingBrackets;
	for(int i; i<=strlen(formula); i++)  //Resize the arrays once so we don't have to worry about it later on
	{
		if(formula[i] == '(')
		{
			if(!matchingBrackets)
			{
				size++;
			}
			else
			{
				matchingBrackets--;
			}
		}
		else if(formula[i] == ')')
		{
			matchingBrackets++;
		}
	}

	ArrayList sumArray = CreateArray(_, size);
	ArrayList _operator = CreateArray(_, size);
	int bracket;
	sumArray.Set(0, 0.0);
	_operator.Set(bracket, Operator_None);

	char character[2], value[16];
	for(int i; i<=strlen(formula); i++)
	{
		character[0] = formula[i];
		switch(character[0])
		{
			case ' ', '\t':
			{
				continue;
			}
			case '(':
			{
				bracket++;
				sumArray.Set(bracket, 0.0);
				_operator.Set(bracket, Operator_None);
			}
			case ')':
			{
				OperateString(sumArray, bracket, value, sizeof(value), _operator);
				if(_operator.Get(bracket) != Operator_None)
				{
					FF2_ReportError(boss, "[Boss] Formula at arg%i/%s for %s has an invalid operator at character %i", argNumber, argName, abilityName, i+1);
					delete sumArray;
					delete _operator;
					return defaultValue;
				}

				if(--bracket < 0)
				{
					FF2_ReportError(boss, "[Boss] Formula at arg%i/%s for %s has an unbalanced parentheses at character %i", argNumber, argName, abilityName, i+1);
					delete sumArray;
					delete _operator;
					return defaultValue;
				}

				Operate(sumArray, bracket, sumArray.Get(bracket+1), _operator);
			}
			case '\0':
			{
				OperateString(sumArray, bracket, value, sizeof(value), _operator);
			}
			case '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '.':
			{
				StrCat(value, sizeof(value), character);
			}
			case 'n', 'x':
			{
				Operate(sumArray, bracket, float(TotalPlayers), _operator);
			}
			case 'a', 'y':
			{
				Operate(sumArray, bracket, float(Players), _operator);
			}
			case '+', '-', '*', '/', '^':
			{
				OperateString(sumArray, bracket, value, sizeof(value), _operator);
				switch(character[0])
				{
					case '+':
						_operator.Set(bracket, Operator_Add);

					case '-':
						_operator.Set(bracket, Operator_Subtract);

					case '*':
						_operator.Set(bracket, Operator_Multiply);

					case '/':
						_operator.Set(bracket, Operator_Divide);

					case '^':
						_operator.Set(bracket, Operator_Exponent);
				}
			}
		}
	}

	float result = sumArray.Get(0);
	delete sumArray;
	delete _operator;
	if((valueCheck==1 && result<0) || (valueCheck==2 && result<=0))
	{
		FF2_ReportError(boss, "[Boss] An invalid formula at arg%i/%s for %s!", argNumber, argName, abilityName);
		return defaultValue;
	}
	return result;
}

public Action Timer_RemoveEntity(Handle timer, any entid)
{
	int entity = EntRefToEntIndex(entid);
	if(IsValidEntity(entity) && entity>MaxClients)
		AcceptEntityInput(entity, "Kill");
}

stock int AttachParticle(int entity, char[] particleType, float offset=0.0, bool attach=true)
{
	int particle = CreateEntityByName("info_particle_system");

	static char targetName[128];
	static float position[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", position);
	position[2] += offset;
	TeleportEntity(particle, position, NULL_VECTOR, NULL_VECTOR);

	Format(targetName, sizeof(targetName), "target%i", entity);
	DispatchKeyValue(entity, "targetname", targetName);

	DispatchKeyValue(particle, "targetname", "tf2particle");
	DispatchKeyValue(particle, "parentname", targetName);
	DispatchKeyValue(particle, "effect_name", particleType);
	DispatchSpawn(particle);
	SetVariantString(targetName);
	if(attach)
	{
		AcceptEntityInput(particle, "SetParent", particle, particle, 0);
		SetEntPropEnt(particle, Prop_Send, "m_hOwnerEntity", entity);
	}
	ActivateEntity(particle);
	AcceptEntityInput(particle, "start");
	return particle;
}

#file "FF2 Unofficial Subplugin: Defaults"
