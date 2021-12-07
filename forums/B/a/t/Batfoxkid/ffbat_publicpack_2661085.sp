#pragma semicolon 1

#define DDCOMPILE true

#include <sourcemod>
#include <tf2_stocks>
#include <tf2items>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>
#if DDCOMPILE
#include <ff2_dynamic_defaults>
#endif
#undef REQUIRE_PLUGIN
#tryinclude <ff2_ams>
#tryinclude <sdkhooks>
#if defined _sdkhooks_included
#tryinclude <goomba>
#endif
#tryinclude <tf2attributes>
#define REQUIRE_PLUGIN

#pragma newdecls required

#define MAJOR_REVISION	"1"
#define MINOR_REVISION	"6"
#define STABLE_REVISION	"2"
#define PLUGIN_VERSION MAJOR_REVISION..."."...MINOR_REVISION..."."...STABLE_REVISION

#define FAR_FUTURE	100000000.0
#define MAXTF2PLAYERS	36
#define MAXSOUNDPATH	80
#define MAXMODELPATH	128
#define MAXMATERIALPATH 128

#define INTRO		"special_introoverlay"
#define LASTBACKUP	"special_lastmanbackup"
#define NOKNOCKBACK	"special_noplayerknockback"
#define TEAMWEAPON	"rage_teamnewweapon"
#define TEAMWEAPONAMS	"ams_teamnewweapon"
#define WEIGHDOWN	"special_weighdown"
#define BLOCKRAGE	"rage_preventrage"

#define SOUNDBACKUP	"sound_backup"
#define SOUNDBACKVO	"sound_backup_vo"
#define SOUNDLIGHT	"sound_weighdown"
#define SOUNDHEAVY	"sound_weighdown_slam"

Handle OnHaleRage;
Handle OnHaleWeighdown;
float OFF_THE_MAP[3] = {16383.0, 16383.0, -16383.0};

#if defined _tf2attributes_included
bool tf2attributes = false;
bool NoKnockback = false;
#endif

/*#if defined _ff2_ams_included
int Players;
int Bosses;
#endif*/

int LastMannBackup[MAXTF2PLAYERS];
bool IsBackup[MAXTF2PLAYERS];
float WeighdownTime[MAXTF2PLAYERS];
float RageBlockTimer[MAXTF2PLAYERS];
float RageBlockCurrent[MAXTF2PLAYERS];

#if defined _goomba_included_
bool TempGoomba;
#endif
bool TempSlam;

enum Operators
{
	Operator_None = 0,
	Operator_Add,
	Operator_Subtract,
	Operator_Multiply,
	Operator_Divide,
	Operator_Exponent,
};

public Plugin myinfo =
{
	name		=	"Freak Fortress 2: Bat's Public Pack",
	author		=	"Batfoxkid",
	description	=	"Various small and public requested abilities",
	version		=	PLUGIN_VERSION
};

// SourceMod Events

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	OnHaleRage = CreateGlobalForward("VSH_OnDoRage", ET_Hook, Param_FloatByRef);
	OnHaleWeighdown = CreateGlobalForward("VSH_OnDoWeighdown", ET_Hook);
	return APLRes_Success;
}

public void OnPluginStart2()
{
	int version[3];
	FF2_GetFF2Version(version);
	if(version[0]==1 && (version[1]<10 || (version[1]==10 && version[2]<3)))
		SetFailState("This subplugin requires at least FF2 v1.10.3!");

	AddCommandListener(OnVoiceline, "voicemenu");

	HookEvent("teamplay_round_start", OnRoundSetup, EventHookMode_PostNoCopy);
	HookEvent("object_deflected", OnObjectDeflected, EventHookMode_Pre);
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("teamplay_round_win", OnRoundEnd);
	HookEvent("arena_round_start", OnRoundStart);

	#if defined _tf2attributes_included
	tf2attributes = LibraryExists("tf2attributes");
	#endif

	if(FF2_IsFF2Enabled() && FF2_GetRoundState()==1)
		OnRoundStart(INVALID_HANDLE, "plugin_lateload", false);
}

#if defined _tf2attributes_included
public void OnLibraryAdded(const char[] name)
{
	if(!strcmp(name, "tf2attributes", false))
		tf2attributes = true;
}

public void OnLibraryRemoved(const char[] name)
{
	if(!strcmp(name, "tf2attributes", false))
		tf2attributes = false;
}
#endif

public void OnPluginEnd()
{
	OnRoundEnd(INVALID_HANDLE, "plugin_end", false);
}

// TF2 Events

public Action OnRoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	if(!FF2_IsFF2Enabled() || !tf2attributes)
		return Plugin_Continue;

	for(int client=1; client<=MaxClients; client++)
	{
		if(!IsValidClient(client))
			continue;

		int boss = FF2_GetBossIndex(client);
		if(boss < 0)
			continue;

		#if defined _tf2attributes_included
		if(FF2_HasAbility(boss, this_plugin_name, NOKNOCKBACK) && tf2attributes)
		{
			for(int target=1; target<=MaxClients; target++)
			{
				if(!IsValidClient(client))
					continue;

				if(!IsPlayerAlive(client))
					continue;

				boss = FF2_GetBossIndex(client);
				if(boss >= 0)
					continue;

				TF2Attrib_SetByDefIndex(target, 252, 0.0);
			}
			NoKnockback = true;
		}
		#endif

		#if defined _ff2_ams_included
		if(FF2_HasAbility(boss, this_plugin_name, TEAMWEAPONAMS))
		{
			if(AMS_IsSubabilityReady(boss, this_plugin_name, TEAMWEAPONAMS))
				AMS_InitSubability(boss, client, this_plugin_name, TEAMWEAPONAMS, "TNW");
		}
		#endif
	}
	return Plugin_Continue;
}

public Action OnRoundSetup(Handle event, const char[] name, bool dontBroadcast)
{
	CreateTimer(0.3, CheckAbility, _, TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}

public Action CheckAbility(Handle timer)
{
	if(!FF2_IsFF2Enabled())
		return Plugin_Continue;

	for(int client=0; client<=MaxClients; client++)
	{
		LastMannBackup[client] = 0;

		if(!IsValidClient(client))
			continue;

		int boss = FF2_GetBossIndex(client);
		if(boss < 0)
			continue;

		if(FF2_HasAbility(boss, this_plugin_name, INTRO))
			CreateTimer(FF2_GetAbilityArgumentFloat(boss, this_plugin_name, INTRO, 4, 3.25), Apply_Overlay, boss, TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Continue;
}

public Action OnRoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	for(int client=1; client<=MaxClients; client++)
	{
		IsBackup[client] = false;
		RageBlockTimer[client] = 0.0;
		RageBlockCurrent[client] = 0.0;
	}

	#if defined _tf2attributes_included
	if(!NoKnockback || !tf2attributes)
	{
		NoKnockback = false;
		return Plugin_Continue;
	}

	for(int client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client))
			TF2Attrib_RemoveByDefIndex(client, 252);
	}
	#endif
	return Plugin_Continue;
}

public Action OnPlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	IsBackup[GetClientOfUserId(GetEventInt(event, "userid"))] = false;

	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(!attacker)
		return Plugin_Continue;

	int boss = FF2_GetBossIndex(attacker);
	if(boss < 0)
		return Plugin_Continue;

	if(!FF2_HasAbility(boss, this_plugin_name, WEIGHDOWN))
		return Plugin_Continue;

	if(TempGoomba)
	{
		SetEventString(event, "weapon", "mantreads");
		SetEventString(event, "weapon_logclassname", "slam");
		return Plugin_Continue;
	}

	if(TempSlam)
	{
		SetEventString(event, "weapon", "firedeath");
		SetEventString(event, "weapon_logclassname", "slam");
		return Plugin_Continue;
	}
	return Plugin_Continue;
}

public Action OnObjectDeflected(Handle event, const char[] name, bool dontBroadcast)
{
	if(GetEventInt(event, "weaponid"))  //0 means that the client was airblasted, which is what we want
		return Plugin_Continue;

	int client = GetClientOfUserId(GetEventInt(event, "ownerid"));
	int boss = FF2_GetBossIndex(client);
	if(boss < 0)
		return Plugin_Continue;

	if(!FF2_HasAbility(boss, this_plugin_name, WEIGHDOWN))
		return Plugin_Continue;

	SetEntityGravity(client, FF2_GetAbilityArgumentFloat(boss, this_plugin_name, WEIGHDOWN, 3, 1.0));
	return Plugin_Continue;
}

public Action OnVoiceline(int client, const char[] command, int args)
{
	if(!IsPlayerAlive(client) || FF2_GetRoundState()!=1 || !IsBackup[client])
		return Plugin_Continue;

	char arg1[4], arg2[4];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	if(!StringToInt(arg1) || !StringToInt(arg2))
		return Plugin_Continue;

	char sound[MAXSOUNDPATH];
	if(FF2_RandomSound(SOUNDBACKVO, sound, MAXSOUNDPATH, 0))
	{
		float position[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
		EmitSoundToAll(sound, client, _, _, _, _, _, client, position);
	}
	return Plugin_Handled;
}

public void RageBlockThink(int client)
{
	if(!IsValidClient(client) || !IsPlayerAlive(client))
		return;

	FF2_SetBossCharge(FF2_GetBossIndex(client), 0, RageBlockCurrent[client]);

	if(GetEngineTime() >= RageBlockTimer[client])
		SDKUnhook(client, SDKHook_PreThink, RageBlockThink);
}

// FF2 Events

public Action FF2_OnAbility2(int boss, const char[] plugin_name, const char[] ability_name, int status)
{
	int client = GetClientOfUserId(FF2_GetBossUserId(boss));
	int slot = FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, 0);
	if(!slot)  //Rage
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

	if(!strcmp(ability_name, TEAMWEAPON))
	{
		int bossTeam = GetClientTeam(client);
		for(int target=1; target<=MaxClients; target++)
		{
			if(!IsValidClient(target))
				continue;

			if(IsPlayerAlive(target) && GetClientTeam(target)==bossTeam)
				Rage_New_Weapon(target, boss, TEAMWEAPON);
		}
	}
	else if(!strcmp(ability_name, WEIGHDOWN))
	{
		if((GetEntityFlags(client) & FL_ONGROUND))
		{
			if(GetEntityGravity(client) == 6.0)
			{
				char sound[MAXTF2PLAYERS];
				static float ang[3];
				GetClientEyeAngles(client, ang);
				if(WeighdownTime[client]<GetGameTime() &&
				  !TF2_IsPlayerInCondition(client, TFCond_Slowed) &&
				  !TF2_IsPlayerInCondition(client, TFCond_Parachute) &&
				   ang[0] > 60.0)
				{
					PeformSlam(client);
					if(FF2_RandomSound(SOUNDHEAVY, sound, MAXTF2PLAYERS, boss))
					{
						EmitSoundToAll(sound, client, _, _, _, _, _, client);
					}
					else if(FF2_RandomSound(SOUNDLIGHT, sound, MAXTF2PLAYERS, boss))
					{
						EmitSoundToAll(sound, client, _, _, _, _, _, client);
					}
				}
				else if(FF2_RandomSound(SOUNDLIGHT, sound, MAXTF2PLAYERS, boss))
				{
					EmitSoundToAll(sound, client, _, _, _, _, _, client);
				}
			}

			SetEntityGravity(client, FF2_GetAbilityArgumentFloat(boss, this_plugin_name, WEIGHDOWN, 3, 1.0));
			return Plugin_Continue;
		}

		#if DDCOMPILE
		if(FF2_GetAbilityArgumentFloat(boss, this_plugin_name, WEIGHDOWN, 4, -1.0)>0 && DD_GetMobilityCooldown(client)>FF2_GetAbilityArgumentFloat(boss, this_plugin_name, WEIGHDOWN, 4))
			return Plugin_Continue;
		#endif

		if(GetEntityGravity(client)==6.0 ||
		 !(GetClientButtons(client) & IN_DUCK) ||
		   FF2_GetAbilityArgument(boss, this_plugin_name, WEIGHDOWN, 1) ||
		   TF2_IsPlayerInCondition(client, TFCond_Slowed) ||
		   TF2_IsPlayerInCondition(client, TFCond_Parachute) ||
		   TF2_IsPlayerInCondition(client, TFCond_AirCurrent))
			return Plugin_Continue;

		Action action = Plugin_Continue;
		Call_StartForward(OnHaleWeighdown);
		Call_Finish(action);
		if(action!=Plugin_Continue && action!=Plugin_Changed)
			return Plugin_Continue;

		float velocity[3];
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);
		velocity[2] = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, WEIGHDOWN, 2, -1000.0);
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);
		SetEntityGravity(client, 6.0);
		WeighdownTime[client] = GetEngineTime()+FF2_GetAbilityArgumentFloat(boss, this_plugin_name, WEIGHDOWN, 5, 0.2);
	}
	else if(!strcmp(ability_name, BLOCKRAGE))
	{
		RageBlockCurrent[client] = FF2_GetBossCharge(boss, slot);
		CreateTimer(0.1, Timer_RageBlock, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Continue;
}

public void FF2_OnAlivePlayersChanged(int players, int bosses)
{
	if(!FF2_IsFF2Enabled() || !bosses || !players || FF2_GetRoundState()!=1)
		return;

	/*#if defined _ff2_ams_included
	Players = players;
	Bosses = bosses;
	#endif*/

	int boss;
	for(int client=1; client<=MaxClients; client++)
	{
		if(!IsValidClient(client))
			continue;

		boss = FF2_GetBossIndex(client);
		if(boss < 0)
			continue;

		if(!FF2_HasAbility(boss, this_plugin_name, LASTBACKUP))
			continue;

		if(LastMannBackup[boss] >= FF2_GetAbilityArgument(boss, this_plugin_name, LASTBACKUP, 2, 1))
			continue;

		if(GetClientTeam(client) == FF2_GetBossTeam())
		{
			if(players > FF2_GetAbilityArgument(boss, this_plugin_name, LASTBACKUP, 1, 1))
				continue;
		}
		else if(bosses > FF2_GetAbilityArgument(boss, this_plugin_name, LASTBACKUP, 1, 1))
		{
			continue;
		}
		CreateTimer(FF2_GetAbilityArgumentFloat(boss, this_plugin_name, LASTBACKUP, 3, 0.05), Timer_Backup, boss, TIMER_FLAG_NO_MAPCHANGE);
	}
	return;
}

public void FF2_PreAbility(int boss, const char[] pluginName, const char[] abilityName, int slot, bool &enabled)
{
	if(!slot && GetEngineTime()<RageBlockTimer[GetClientOfUserId(FF2_GetBossUserId(boss))])
		enabled = false;
}

// Goomba Events

#if defined _goomba_included_
public Action OnStomp(int attacker, int victim, float &damageMult, float &damageBonus, float &jumpPower)
{
	if(!IsPlayerAlive(attacker))
		return Plugin_Continue;

	if(GetEntityGravity(attacker) != 6.0)
		return Plugin_Continue;

	if(!IsPlayerAlive(victim) || FF2_GetBossIndex(victim)>=0)
		return Plugin_Continue;

	int boss = FF2_GetBossIndex(attacker);
	if(boss < 0)
		return Plugin_Continue;

	if(!FF2_HasAbility(boss, this_plugin_name, WEIGHDOWN))
		return Plugin_Continue;

	TempGoomba = true;
	SDKHooks_TakeDamage(victim, attacker, attacker, damageMult*GetClientHealth(victim)+damageBonus, DMG_PREVENT_PHYSICS_FORCE|DMG_CRUSH|DMG_ALWAYSGIB, -1);
	TempGoomba = false;
	WeighdownTime[attacker] = GetGameTime()+(FF2_GetAbilityArgumentFloat(boss, this_plugin_name, WEIGHDOWN, 5, 0.2)/2.0);
	return Plugin_Handled;
}
#endif

// AMS Events

#if defined _ff2_ams_included
public bool TNW_CanInvoke(int client)
{
	/*int clones = GetClientTeam(client)==FF2_GetBossTeam() ? Bosses : Players;
	return clones>1;*/
	return true;
}

public void TNW_Invoke(int client)
{
	int bossTeam = GetClientTeam(client);
	for(int target=1; target<=MaxClients; target++)
	{
		if(!IsValidClient(target))
			continue;

		if(IsPlayerAlive(target) && GetClientTeam(target)==bossTeam)
			Rage_New_Weapon(target, FF2_GetBossIndex(client), TEAMWEAPONAMS);
	}
}
#endif

// Intro Overlay

public Action Apply_Overlay(Handle timer, int boss)
{
	int bossTeam = GetClientTeam(GetClientOfUserId(FF2_GetBossUserId(boss)));
	char overlay[MAXMATERIALPATH];
	FF2_GetAbilityArgumentString(boss, this_plugin_name, INTRO, 1, overlay, MAXMATERIALPATH);
	Format(overlay, MAXMATERIALPATH, "r_screenoverlay \"%s\"", overlay);
	SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & ~FCVAR_CHEAT);
	for(int target=1; target<=MaxClients; target++)
	{
		if(IsClientInGame(target) && IsPlayerAlive(target) && (GetClientTeam(target)!=bossTeam || FF2_GetAbilityArgument(boss, this_plugin_name, INTRO, 2, 0)))
			ClientCommand(target, overlay);
	}
	SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & FCVAR_CHEAT);
	CreateTimer(FF2_GetAbilityArgumentFloat(boss, this_plugin_name, INTRO, 3, 3.25), Remove_Overlay, boss, TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}

public Action Remove_Overlay(Handle timer, int boss)
{
	int bossTeam = GetClientTeam(GetClientOfUserId(FF2_GetBossUserId(boss)));
	SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & ~FCVAR_CHEAT);
	for(int target=1; target<=MaxClients; target++)
	{
		if(IsClientInGame(target) && IsPlayerAlive(target) && (GetClientTeam(target)!=bossTeam || FF2_GetAbilityArgument(boss, this_plugin_name, INTRO, 2, 0)))
			ClientCommand(target, "r_screenoverlay \"\"");
	}
	SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & FCVAR_CHEAT);
	return Plugin_Continue;
}

// Clone Attack

public Action Timer_Backup(Handle timer, int boss)
{
	if(!FF2_IsFF2Enabled() || FF2_GetRoundState()!=1)
		return Plugin_Continue;

	if(LastMannBackup[boss] >= FF2_GetAbilityArgument(boss, this_plugin_name, LASTBACKUP, 2, 1))
		return Plugin_Continue;

	int client = GetClientOfUserId(FF2_GetBossUserId(boss));
	int weaponMode=FF2_GetAbilityArgument(boss, this_plugin_name, LASTBACKUP, 4, 2);
	char model[MAXMODELPATH];
	FF2_GetAbilityArgumentString(boss, this_plugin_name, LASTBACKUP, 5, model, sizeof(model));
	int class=FF2_GetAbilityArgument(boss, this_plugin_name, LASTBACKUP, 6);
	float ratio=FF2_GetAbilityArgumentFloat(boss, this_plugin_name, LASTBACKUP, 7, 0.0);
	char classname[64];
	FF2_GetAbilityArgumentString(boss, this_plugin_name, LASTBACKUP, 8, classname, sizeof(classname));
	int index=FF2_GetAbilityArgument(boss, this_plugin_name, LASTBACKUP, 9, 191);
	char attributes[256];
	FF2_GetAbilityArgumentString(boss, this_plugin_name, LASTBACKUP, 10, attributes, sizeof(attributes));
	int ammo=FF2_GetAbilityArgument(boss, this_plugin_name, LASTBACKUP, 11, -1);
	int clip=FF2_GetAbilityArgument(boss, this_plugin_name, LASTBACKUP, 12, -1);
	char healthformula[768];
	FF2_GetAbilityArgumentString(boss, this_plugin_name, LASTBACKUP, 13, healthformula, sizeof(healthformula));

	int alive, dead, total;
	Handle players=CreateArray();
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
				else if(FF2_GetBossIndex(target)==-1)  //Don't let dead bosses become clones
				{
					PushArrayCell(players, target);
					dead++;
				}
				total++;
			}
		}
	}

	int health = ParseFormula(boss, healthformula, 0, total);
	int totalMinions = (ratio<1 ? RoundToCeil(total*ratio) : RoundToCeil(ratio));
	int clone, temp, entity;
	bool HasSummoned = false;
	for(int i=1; i<=dead && i<=totalMinions; i++)
	{
		temp = GetRandomInt(0, GetArraySize(players)-1);
		clone = GetArrayCell(players, temp);
		RemoveFromArray(players, temp);

		TF2_RespawnPlayer(clone);

		if(class)
			TF2_SetPlayerClass(clone, view_as<TFClassType>(class), _, false);

		IsBackup[clone] = true;
		HasSummoned = true;

		if(strlen(model))
		{
			SetVariantString(model);
			AcceptEntityInput(clone, "SetCustomModel");
			SetEntProp(clone, Prop_Send, "m_bUseClassAnimations", 1);

			Handle data;
			CreateDataTimer(0.1, Timer_EquipModel, data, TIMER_FLAG_NO_MAPCHANGE);
			WritePackCell(data, GetClientUserId(clone));
			WritePackString(data, model);
		}

		switch(weaponMode)
		{
			case 0:
			{
				TF2_RemoveAllWeapons(clone);
			}
			case 1:
			{
				TF2_RemoveAllWeapons(clone);
				if(!strlen(classname))
					strcopy(classname, sizeof(classname), "tf_weapon_bottle");

				if(!strlen(attributes))
					strcopy(attributes, sizeof(attributes), "68 ; -1");

				int weapon = SpawnWeapon(clone, classname, index, 101, 5, attributes);
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

				FF2_SetAmmo(clone, weapon, ammo, clip);
			}
		}

		if(health)
		{
			SetEntProp(clone, Prop_Data, "m_iMaxHealth", health);
			SetEntProp(clone, Prop_Data, "m_iHealth", health);
			SetEntProp(clone, Prop_Send, "m_iHealth", health);
		}

		entity = -1;
		while((entity=FindEntityByClassname2(entity, "tf_wear*")) != -1)
		{
			if(clone == GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity"))
			{
				switch(GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"))
				{
					case 493, 233, 234, 241, 280, 281, 282, 283, 284, 286, 288, 362, 364, 365, 536, 542, 577, 599, 673, 729, 791, 839, 5607:  //Action slot items
					{
						//NOOP
					}
					default:
					{
						TF2_RemoveWearable(clone, entity);
					}
				}
			}
		}

		entity = -1;
		while((entity=FindEntityByClassname2(entity, "tf_powerup_bottle")) != -1)
		{
			if(clone == GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity"))
				TF2_RemoveWearable(clone, entity);
		}
	}
	CloseHandle(players);

	LastMannBackup[boss]++;

	if(!HasSummoned)
		return Plugin_Continue;

	char message[128];
	FF2_GetAbilityArgumentString(boss, this_plugin_name, LASTBACKUP, 14, message, sizeof(message));
	if(strlen(message))
	{
		char icon[64];
		FF2_GetAbilityArgumentString(boss, this_plugin_name, LASTBACKUP, 15, icon, sizeof(icon));
		int color = FF2_GetAbilityArgument(boss, this_plugin_name, LASTBACKUP, 16, view_as<int>(TFTeam_Red));
		if(strlen(icon))
		{
			ShowGameText(0, icon, color, message);
		}
		else
		{
			ShowGameText(0, _, color, message);
		}
	}

	char sound[MAXSOUNDPATH];
	if(!FF2_RandomSound(SOUNDBACKUP, sound, MAXSOUNDPATH, boss))
		return Plugin_Continue;

	EmitSoundToAll(sound);

	/*int version[3];
	FF2_GetFF2Version(version);
	if(version[0]!=1 || version[1]<11)
	{
		EmitSoundToAll(sound);
		EmitSoundToAll(sound);
		return Plugin_Continue;
	}
	else
	{
		FF2_GetForkVersion(version);
		if(version[0]!=1 || version[1]<18 || (version[1]==18 && version[2]<5))
		{
			EmitSoundToAll(sound);
			EmitSoundToAll(sound);
			return Plugin_Continue;
		}
	}

	FF2_EmitVoiceToAll(sound);*/
	return Plugin_Continue;
}

public Action Timer_EquipModel(Handle timer, any pack)
{
	ResetPack(pack);
	int client=GetClientOfUserId(ReadPackCell(pack));
	if(client && IsClientInGame(client) && IsPlayerAlive(client))
	{
		char model[MAXMODELPATH];
		ReadPackString(pack, model, MAXMODELPATH);
		SetVariantString(model);
		AcceptEntityInput(client, "SetCustomModel");
		SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
	}
}

stock int Operate(Handle sumArray, int &bracket, float value, Handle _operator)
{
	float sum=GetArrayCell(sumArray, bracket);
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
				LogError("[Boss] Detected a divide by 0 for rage_clone!");
				bracket=0;
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

public int ParseFormula(int boss, const char[] key, int defaultValue, int playing)
{
	char formula[1024], bossName[64];
	FF2_GetBossSpecial(boss, bossName, sizeof(bossName));
	strcopy(formula, sizeof(formula), key);
	int size=1;
	int matchingBrackets;
	for(int i; i<=strlen(formula); i++)  //Resize the arrays once so we don't have to worry about it later on
	{
		if(formula[i]=='(')
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
		else if(formula[i]==')')
		{
			matchingBrackets++;
		}
	}

	Handle sumArray=CreateArray(_, size), _operator=CreateArray(_, size);
	int bracket;  //Each bracket denotes a separate sum (within parentheses).  At the end, they're all added together to achieve the actual sum
	SetArrayCell(sumArray, 0, 0.0);  //TODO:  See if these can be placed naturally in the loop
	SetArrayCell(_operator, bracket, Operator_None);

	char character[2], value[16];
	for(int i; i<=strlen(formula); i++)
	{
		character[0]=formula[i];  //Find out what the next char in the formula is
		switch(character[0])
		{
			case ' ', '\t':  //Ignore whitespace
			{
				continue;
			}
			case '(':
			{
				bracket++;  //We've just entered a new parentheses so increment the bracket value
				SetArrayCell(sumArray, bracket, 0.0);
				SetArrayCell(_operator, bracket, Operator_None);
			}
			case ')':
			{
				OperateString(sumArray, bracket, value, sizeof(value), _operator);
				if(GetArrayCell(_operator, bracket)!=Operator_None)  //Something like (5*)
				{
					LogError("[Boss] %s's %s formula for rage_clone has an invalid operator at character %i", bossName, key, i+1);
					CloseHandle(sumArray);
					CloseHandle(_operator);
					return defaultValue;
				}

				if(--bracket<0)  //Something like (5))
				{
					LogError("[Boss] %s's %s formula for rage_clone has an unbalanced parentheses at character %i", bossName, key, i+1);
					CloseHandle(sumArray);
					CloseHandle(_operator);
					return defaultValue;
				}

				Operate(sumArray, bracket, GetArrayCell(sumArray, bracket+1), _operator);
			}
			case '\0':  //End of formula
			{
				OperateString(sumArray, bracket, value, sizeof(value), _operator);
			}
			case '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '.':
			{
				StrCat(value, sizeof(value), character);  //Constant?  Just add it to the current value
			}
			case 'n', 'x':  //n and x denote player variables
			{
				Operate(sumArray, bracket, float(playing), _operator);
			}
			case '+', '-', '*', '/', '^':
			{
				OperateString(sumArray, bracket, value, sizeof(value), _operator);
				switch(character[0])
				{
					case '+':
						SetArrayCell(_operator, bracket, Operator_Add);

					case '-':
						SetArrayCell(_operator, bracket, Operator_Subtract);

					case '*':
						SetArrayCell(_operator, bracket, Operator_Multiply);

					case '/':
						SetArrayCell(_operator, bracket, Operator_Divide);

					case '^':
						SetArrayCell(_operator, bracket, Operator_Exponent);
				}
			}
		}
	}

	int result=RoundFloat(GetArrayCell(sumArray, 0));
	CloseHandle(sumArray);
	CloseHandle(_operator);
	if(result<=0)
	{
		LogError("[Boss] %s has an invalid %s formula for rage_clone, using default health!", bossName, key);
		return defaultValue;
	}
	return result;
}

// Team New Weapon

void Rage_New_Weapon(int client, int boss, const char[] ability_name)
{
	if(!client || !IsClientInGame(client) || !IsPlayerAlive(client))
		return;

	char classname[64], attributes[256];
	FF2_GetAbilityArgumentString(boss, this_plugin_name, ability_name, 1, classname, sizeof(classname));
	FF2_GetAbilityArgumentString(boss, this_plugin_name, ability_name, 3, attributes, sizeof(attributes));

	int slot = FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, 4);
	TF2_RemoveWeaponSlot(client, slot);

	int index = FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, 2);
	int weapon = SpawnWeapon(client, classname, index, 101, 7, attributes);
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

	if(FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, 6))
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);

	int ammo = FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, 5, 0);
	int clip = FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, 7, 0);
	if(ammo || clip)
		FF2_SetAmmo(client, weapon, ammo, clip);
}

// Weighdown

public void PeformSlam(int client)
{
	if(client <= 0)
		return;

	int boss = FF2_GetBossIndex(client);
	if(!FF2_HasAbility(boss, this_plugin_name, WEIGHDOWN))
		return;

	char particle[48];
	FF2_GetAbilityArgumentString(boss, this_plugin_name, WEIGHDOWN, 11, particle, sizeof(particle));
	if(strlen(particle))
	{
		int index = -1;
		char attachment[48];
		FF2_GetAbilityArgumentString(boss, this_plugin_name, WEIGHDOWN, 12, attachment, sizeof(attachment));
		if(strlen(attachment))
		{
			index = AttachParticleToAttachment(client, particle, attachment);
		}
		else
		{
			index = AttachParticle(client, particle, 70.0, true);
		}

		if(IsValidEntity(index))
			CreateTimer(FF2_GetAbilityArgumentFloat(boss, this_plugin_name, WEIGHDOWN, 13, 1.0), Timer_RemoveEntity, EntIndexToEntRef(index), TIMER_FLAG_NO_MAPCHANGE);
	}

	float distance = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, WEIGHDOWN, 20, FF2_GetRageDist(boss, this_plugin_name, WEIGHDOWN));
	if(distance <= 0)
		return;

	#if defined _sdkhooks_included
	float initialDamage = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, WEIGHDOWN, 21)/3.0;
	float damage;
	#endif
	bool friendlyFire = view_as<bool>(FF2_GetAbilityArgument(boss, this_plugin_name, WEIGHDOWN, 22, GetConVarInt(FindConVar("mp_friendlyfire"))));

	char tempString[256];
	FF2_GetAbilityArgumentString(boss, this_plugin_name, WEIGHDOWN, 23, tempString, sizeof(tempString));
	if(strlen(tempString))
		SetCondition(client, tempString);

	float tempFloat = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, WEIGHDOWN, 24);
	if(tempFloat > 0)
		TF2_StunPlayer(client, tempFloat, 1.0, TF_STUNFLAGS_NORMALBONK, client);

	tempFloat = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, WEIGHDOWN, 25);
	if(tempFloat > 0)
	#if SOURCEMOD_V_MAJOR==1 && SOURCEMOD_V_MINOR<=9
		TF2_IgnitePlayer(client, client);
	#else
		TF2_IgnitePlayer(client, client, tempFloat);
	#endif

	FF2_GetAbilityArgumentString(boss, this_plugin_name, WEIGHDOWN, 26, tempString, sizeof(tempString));
	float stunTime = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, WEIGHDOWN, 27);
	tempFloat = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, WEIGHDOWN, 28);
	float knockback = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, WEIGHDOWN, 29);

	float bossPosition[3], targetPosition[3], vectorDistance;
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", bossPosition);

	TempSlam = true;
	for(int target=1; target<=MaxClients; target++)
	{
		if(IsClientInGame(target) && IsPlayerAlive(target) && (friendlyFire || GetClientTeam(target)!=GetClientTeam(client)) && target!=client && !IsInvuln(target))
		{
			GetEntPropVector(target, Prop_Send, "m_vecOrigin", targetPosition);
			vectorDistance = GetVectorDistance(bossPosition, targetPosition);
			if(vectorDistance <= distance)
			{
				if(!IsInvuln(target))
				{
					if(tempFloat > 0)
					#if SOURCEMOD_V_MAJOR==1 && SOURCEMOD_V_MINOR<=9
						TF2_IgnitePlayer(target, client);
					#else
						TF2_IgnitePlayer(target, client, tempFloat);
					#endif

					#if defined _sdkhooks_included
					if(initialDamage > 0)
					{
						if(vectorDistance <= 0)
						{
							SDKHooks_TakeDamage(target, client, client, 9001.0, DMG_PREVENT_PHYSICS_FORCE|DMG_CRUSH, -1);
						}
						else
						{
							damage = distance/vectorDistance*initialDamage;
							if(damage > 0)
								SDKHooks_TakeDamage(target, client, client, damage, DMG_PREVENT_PHYSICS_FORCE|DMG_CRUSH, -1);
						}
					}

					if(!IsPlayerAlive(client))
						continue;
					#endif

					TF2_RemoveCondition(target, TFCond_Parachute);

					if(strlen(tempString))
						SetCondition(target, tempString);

					if(stunTime > 0)
						TF2_StunPlayer(target, stunTime, 1.0, TF_STUNFLAGS_NORMALBONK, client);
				}
			}

			if(knockback!=0 && !TF2_IsPlayerInCondition(target, TFCond_MegaHeal))
			{
				static float angles[3];
				static float velocity[3];
				GetVectorAnglesTwoPoints(bossPosition, targetPosition, angles);
				GetAngleVectors(angles, velocity, NULL_VECTOR, NULL_VECTOR);
				ScaleVector(velocity, knockback);
				velocity[2] = 300.0;
				TeleportEntity(target, NULL_VECTOR, NULL_VECTOR, velocity);
			}
		}
	}
	TempSlam = false;
}

// Prevent Rage

public Action Timer_RageBlock(Handle timer, int client)
{
	if(IsValidClient(client))
	{
		RageBlockTimer[client] = GetEngineTime()+FF2_GetAbilityArgumentFloat(FF2_GetBossIndex(client), this_plugin_name, BLOCKRAGE, 1, 10.0);
		SDKHook(client, SDKHook_PreThink, RageBlockThink);
	}
	return Plugin_Continue;
}

// Stocks

stock bool ShowGameText(int client, const char[] icon="ico_notify_flag_moving_alt", int color=0, const char[] buffer, any ...)
{
	Handle bf;
	if(!client)
	{
		bf = StartMessageAll("HudNotifyCustom");
	}
	else
	{
		bf = StartMessageOne("HudNotifyCustom", client);
	}

	if(bf == null)
		return false;

	char message[512];
	SetGlobalTransTarget(client);
	VFormat(message, sizeof(message), buffer, 5);
	ReplaceString(message, sizeof(message), "\n", "");

	BfWriteString(bf, message);
	BfWriteString(bf, icon);
	BfWriteByte(bf, color);
	EndMessage();
	return true;
}

stock int SpawnWeapon(int client, char[] name, int index, int level, int quality, char[] attribute)
{
	Handle weapon=TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
	TF2Items_SetClassname(weapon, name);
	TF2Items_SetItemIndex(weapon, index);
	TF2Items_SetLevel(weapon, level);
	TF2Items_SetQuality(weapon, quality);
	char attributes[32][32];
	int count=ExplodeString(attribute, ";", attributes, 32, 32);
	if(count%2!=0)
		count--;

	if(count>0)
	{
		TF2Items_SetNumAttributes(weapon, count/2);
		int i2=0;
		for(int i=0; i<count; i+=2)
		{
			int attrib=StringToInt(attributes[i]);
			if(!attrib)
			{
				LogError("[Boss] Bad weapon attribute passed: %s ; %s", attributes[i], attributes[i+1]);
				return -1;
			}
			TF2Items_SetAttribute(weapon, i2, attrib, StringToFloat(attributes[i+1]));
			i2++;
		}
	}
	else
	{
		TF2Items_SetNumAttributes(weapon, 0);
	}

	if(weapon==INVALID_HANDLE)
		return -1;

	int entity=TF2Items_GiveNamedItem(client, weapon);
	CloseHandle(weapon);
	EquipPlayerWeapon(client, entity);
	return entity;
}

stock int FindEntityByClassname2(int startEnt, const char[] classname)
{
	while(startEnt>-1 && !IsValidEntity(startEnt))
	{
		startEnt--;
	}
	return FindEntityByClassname(startEnt, classname);
}

stock void SetCondition(int client, char[] cond)
{
	char conds[32][32];
	int count = ExplodeString(cond, " ; ", conds, sizeof(conds), sizeof(conds));
	if(count <= 0)
		return;

	for(int i=0; i<count; i+=2)
	{
		TF2_AddCondition(client, view_as<TFCond>(StringToInt(conds[i])), StringToFloat(conds[i+1]));
	}
}

stock bool IsInvuln(int client)
{
	if(!IsValidClient(client))	
		return true;

	return (TF2_IsPlayerInCondition(client, TFCond_Ubercharged) ||
		TF2_IsPlayerInCondition(client, TFCond_UberchargedCanteen) ||
		TF2_IsPlayerInCondition(client, TFCond_UberchargedHidden) ||
		TF2_IsPlayerInCondition(client, TFCond_UberchargedOnTakeDamage) ||
		TF2_IsPlayerInCondition(client, TFCond_Bonked) ||
		TF2_IsPlayerInCondition(client, TFCond_HalloweenGhostMode) ||
		!GetEntProp(client, Prop_Data, "m_takedamage"));
}

stock bool IsValidClient(int client, bool replaycheck=true)
{
	if(client<=0 || client>MaxClients)
		return false;

	if(!IsClientInGame(client))
		return false;

	if(GetEntProp(client, Prop_Send, "m_bIsCoaching"))
		return false;

	if(replaycheck && (IsClientSourceTV(client) || IsClientReplay(client)))
		return false;

	return true;
}

// Sarysa Stocks

stock int AttachParticle(int entity, const char[] particleType, float offset=0.0, bool attach=true)
{
	int particle = CreateEntityByName("info_particle_system");
	
	if(!IsValidEntity(particle))
		return -1;

	char targetName[128];
	float position[3];
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

stock int AttachParticleToAttachment(int entity, const char[] particleType, const char[] attachmentPoint) // m_vecAbsOrigin. you're welcome.
{
	int particle = CreateEntityByName("info_particle_system");
	
	if(!IsValidEntity(particle))
		return -1;

	char targetName[128];
	float position[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", position);
	TeleportEntity(particle, position, NULL_VECTOR, NULL_VECTOR);

	Format(targetName, sizeof(targetName), "target%i", entity);
	DispatchKeyValue(entity, "targetname", targetName);

	DispatchKeyValue(particle, "targetname", "tf2particle");
	DispatchKeyValue(particle, "parentname", targetName);
	DispatchKeyValue(particle, "effect_name", particleType);
	DispatchSpawn(particle);
	SetVariantString(targetName);
	AcceptEntityInput(particle, "SetParent", particle, particle, 0);
	SetEntPropEnt(particle, Prop_Send, "m_hOwnerEntity", entity);
	
	SetVariantString(attachmentPoint);
	AcceptEntityInput(particle, "SetParentAttachment");

	if(strlen(particleType))
	{
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
	}
	return particle;
}

public Action Timer_RemoveEntity(Handle timer, any entid)
{
	int entity = EntRefToEntIndex(entid);
	if(IsValidEdict(entity) && entity>MaxClients)
	{
		TeleportEntity(entity, OFF_THE_MAP, NULL_VECTOR, NULL_VECTOR); // send it away first in case it feels like dying dramatically
		AcceptEntityInput(entity, "Kill");
	}
}

stock float GetVectorAnglesTwoPoints(const float startPos[3], const float endPos[3], float angles[3])
{
	static float tmpVec[3];
	//tmpVec[0] = startPos[0] - endPos[0];
	//tmpVec[1] = startPos[1] - endPos[1];
	//tmpVec[2] = startPos[2] - endPos[2];
	tmpVec[0] = endPos[0] - startPos[0];
	tmpVec[1] = endPos[1] - startPos[1];
	tmpVec[2] = endPos[2] - startPos[2];
	GetVectorAngles(tmpVec, angles);
}

#file "FF2 Subplugin: Bat's Public Pack"