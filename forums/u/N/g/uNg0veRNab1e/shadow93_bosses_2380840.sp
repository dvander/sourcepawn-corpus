/*
	SHADoW93 Boss Abilities Pack:
	
	By SHADoW NiNE TR3S
	
	With some code snippets from:
	-Otokiru
	-Friagram
	-WliU
	-EP
	
	usage:
	
		"name"			"boss_config"
			arg0		ability slot
			arg1		boss ability
			arg2-arg12	boss-specific args listed below
		"plugin_name"	"shadow93_bosses"

	Abilities pack for:
	
	Reimu Hakurei (arg1 = 1)
		arg2 = Invun duration
		arg3 = Allow clone?
		arg4 = Clone HP (Setting to 0 uses HP formula of (bossHP)/bossLives, or (bossHP)/4

	Human Sentry Buster (arg1 = 2)
		arg2 = Range
		arg3 = Damage
		
	Handsome Jack (arg1 = 4)
		arg2 = machina ammo
		arg3 = SMG clip
		arg4 = rocket launcher ammo
		arg5 = pistol clip
		arg6 = grenade launcher ammo
		arg7 = cloak duration
		arg8 = bullet resistance duration
		arg9 = blast resistance duration
		arg10 = fire resistance duration
		arg11 = uber duration
		arg12 = # of clones
		
	FemHeavy (arg1 = 6)
		arg2 = minigun ammo
		arg3 = shotgun ammo
		arg4 = melee duration
		arg5 = uber duration

	Eirin Yagokoro (arg1 = 8)
		arg2 = primary cooldown
		arg3 = additional cooldown after 1st cooldown
	
*/

#pragma semicolon 1
#include <tf2>
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2items>
#include <tf2_stocks>
#include <ff2_dynamic_defaults>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

#if SOURCEMOD_V_MINOR > 7
  #pragma newdecls required
#endif

#define BOSSRAGE "boss_config"

#define EIRIN_UBER_DEPLOYED "freak_fortress_2/eirin/eirin_uber_deployed.mp3"
#define HSB_EXPLODE "mvm/sentrybuster/mvm_sentrybuster_explode.wav"
#define JACK_ROCKET "freak_fortress_2/hjack/jack_rocketlauncher.mp3"
#define JACK_CLOAK "freak_fortress_2/hjack/jack_cloaked.mp3"
#define JACK_BULLET "freak_fortress_2/hjack/jack_bulletresist.mp3"
#define JACK_BLAST "freak_fortress_2/hjack/jack_blastresist.mp3"
#define JACK_FIRE "freak_fortress_2/hjack/jack_fireresist.mp3"
#define HEAVY_MELEE "freak_fortress_2/tffems/taunt/heavy_r1.mp3"


// Version Number

#define MAJOR_REVISION "1"
#define MINOR_REVISION "15"
//#define PATCH_REVISION ""

#if !defined PATCH_REVISION
	#define PLUGIN_VERSION MAJOR_REVISION..."."...MINOR_REVISION
#else
	#define PLUGIN_VERSION MAJOR_REVISION..."."...MINOR_REVISION..."."...PATCH_REVISION
#endif


#define JACK_MINION_SPAWN "hj_spawnclone"
#define JACK_RANDOM_BUFF "hj_randombuff"
#define FEMHEAVY_BABIFY "fh_babify"
#define BABIFY_STUCKDMG 10
float EndBabifyAt[MAXPLAYERS+1];

#define INACTIVE 100000000.0

// Ints
int bDmg, SummonerIndex[MAXPLAYERS+1], addtime[MAXPLAYERS+1], timeleft[MAXPLAYERS+1], liveplayers, livebosses;
	
// floats
float bRange;
	
// Handles
Handle cooldownHUD, statusHUD, DelayElixir[MAXPLAYERS+1];

// Bools
bool disableclone, LostLife[MAXPLAYERS+1], DenyElixir[MAXPLAYERS+1];

public void OnMapStart()
{
	PrecacheSound(EIRIN_UBER_DEPLOYED,true);
	PrecacheSound(HSB_EXPLODE,true);
	PrecacheSound(JACK_CLOAK,true);
	PrecacheSound(JACK_BULLET,true);
	PrecacheSound(JACK_BLAST,true);
	PrecacheSound(JACK_FIRE,true);
	PrecacheSound(HEAVY_MELEE, true);
	cooldownHUD = CreateHudSynchronizer();
	statusHUD = CreateHudSynchronizer();
	LoadTranslations("ff2_shadow93_bosses.phrases");
}

public Plugin myinfo = {
	name = "Freak Fortress 2: SHADoW93's Boss Abilities",
	author = "SHADoW NiNE TR3S",
	description="Ability Pack for SHADoW NiNE TR3S's Bosses",
	version=PLUGIN_VERSION,
};

void OnPluginStart2()
{
	int version[3];
	FF2_GetFF2Version(version);
	if(version[0]==1 && (version[1]<10 || (version[1]==10 && version[2]<4)))
	{
		SetFailState("This subplugin (shadow93_bosses.ff2) depends on at least FF2 v1.10.4!");
	}
	
	if(FF2_GetRoundState()==1)
	{
		HookAbilities();
	}
	HookEvent("arena_round_start", Event_RoundStart, EventHookMode_Pre);
	HookEvent("arena_win_panel", OnRoundEnd, EventHookMode_Pre);
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
	HookEvent("player_chargedeployed", OnUberDeploy, EventHookMode_Pre);
}

// A B I L I T I E S
public void FF2_OnAbility2(int boss, const char[] plugin_name, const char[] ability_name, int action)
{
	if(FF2_GetRoundState()==1 && livebosses)
	{
		int client = GetClientOfUserId(FF2_GetBossUserId(boss));
		if(!strcmp(ability_name, BOSSRAGE))
		{
			int Rage = FF2_GetAbilityArgument(boss,this_plugin_name,ability_name, 1); // mode
			Boss_Abilities(ability_name, boss, Rage, client);	 // RAGE & Death EffectS			
		}
	}
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	HookAbilities();
	return Plugin_Continue;
}

public void HookAbilities()
{
	for(int client=1;client<=MaxClients;client++)
	{	
		if(!IsValidClient(client))
			continue;
		LostLife[client] = false;		
		addtime[client] = 0;
		DenyElixir[client] = false;
		SummonerIndex[client] = -1;
		EndBabifyAt[client]=INACTIVE;
		int boss=FF2_GetBossIndex(client);
		if(boss>=0)
		{
			if(FF2_HasAbility(boss, this_plugin_name, JACK_MINION_SPAWN))
			{
				AMS_InitSubability(boss, client, this_plugin_name, JACK_MINION_SPAWN, "JMS"); // Important function to tell AMS that this subplugin supports it
			}
			if(FF2_HasAbility(boss, this_plugin_name, JACK_RANDOM_BUFF))
			{
				AMS_InitSubability(boss, client, this_plugin_name, JACK_RANDOM_BUFF, "JRB"); // Important function to tell AMS that this subplugin supports it
			}
			if(FF2_HasAbility(boss, this_plugin_name, FEMHEAVY_BABIFY))
			{
				AMS_InitSubability(boss, client, this_plugin_name, FEMHEAVY_BABIFY, "FHB"); // Important function to tell AMS that this subplugin supports it
			}			
		}
	}
	disableclone = false;

}
// Minion Spawn

public bool JMS_CanInvoke(int client)
{
	if(TF2_IsPlayerInCondition(client, TFCond_Ubercharged)) return false;
	if(TF2_IsPlayerInCondition(client, TFCond_StealthedUserBuffFade)) return false;
	if(TF2_IsPlayerInCondition(client, TFCond_UberBulletResist) || TF2_IsPlayerInCondition(client, TFCond_BulletImmune)) return false;
	if(TF2_IsPlayerInCondition(client, TFCond_UberBlastResist) || TF2_IsPlayerInCondition(client, TFCond_BlastImmune)) return false;
	if(TF2_IsPlayerInCondition(client, TFCond_UberFireResist) || TF2_IsPlayerInCondition(client, TFCond_FireImmune)) return false;
	return true;
}

public void JMS_Invoke(int client)
{
	int boss=FF2_GetBossIndex(client);
	EmitSoundToAll(JACK_CLOAK, client);
	Multiplier_Rage(JACK_MINION_SPAWN,boss, 4);
}

// Random Buff

public bool JRB_CanInvoke(int client)
{
	if(TF2_IsPlayerInCondition(client, TFCond_Ubercharged)) return false;
	if(TF2_IsPlayerInCondition(client, TFCond_StealthedUserBuffFade)) return false;
	if(TF2_IsPlayerInCondition(client, TFCond_UberBulletResist) || TF2_IsPlayerInCondition(client, TFCond_BulletImmune)) return false;
	if(TF2_IsPlayerInCondition(client, TFCond_UberBlastResist) || TF2_IsPlayerInCondition(client, TFCond_BlastImmune)) return false;
	if(TF2_IsPlayerInCondition(client, TFCond_UberFireResist) || TF2_IsPlayerInCondition(client, TFCond_FireImmune)) return false;
	return true;
}

public void JRB_Invoke(int client)
{
	int boss=FF2_GetBossIndex(client);
	switch(GetRandomInt(1,4))
	{
		case 1: EmitSoundToAll(JACK_BULLET, client), TF2_AddCondition(client, TFCond_UberBulletResist, FF2_GetAbilityArgumentFloat(boss,this_plugin_name,JACK_RANDOM_BUFF,1,10.0)), TF2_AddCondition(client, TFCond_BulletImmune, FF2_GetAbilityArgumentFloat(boss,this_plugin_name,JACK_RANDOM_BUFF,2,10.0));
		case 2:	EmitSoundToAll(JACK_BLAST, client), TF2_AddCondition(client, TFCond_UberBlastResist, FF2_GetAbilityArgumentFloat(boss,this_plugin_name,JACK_RANDOM_BUFF,2,10.0)), TF2_AddCondition(client, TFCond_BlastImmune, FF2_GetAbilityArgumentFloat(boss,this_plugin_name,JACK_RANDOM_BUFF,3,10.0));
		case 3: EmitSoundToAll(JACK_FIRE, client), TF2_AddCondition(client, TFCond_UberFireResist, FF2_GetAbilityArgumentFloat(boss,this_plugin_name,JACK_RANDOM_BUFF,3,10.0)), TF2_AddCondition(client, TFCond_FireImmune, FF2_GetAbilityArgumentFloat(boss,this_plugin_name,JACK_RANDOM_BUFF,4,10.0)); 
		case 4: EmitSoundToAll(JACK_FIRE, client), TF2_AddCondition(client, TFCond_Ubercharged, FF2_GetAbilityArgumentFloat(boss,this_plugin_name,JACK_RANDOM_BUFF,4,10.0));
	}
}

// Babify

public bool FHB_CanInvoke(int client)
{
	if(TF2_IsPlayerInCondition(client, TFCond_Ubercharged)) return false;
	if(TF2_IsPlayerInCondition(client, TFCond_MeleeOnly)) return false;
	return true;
}

public void FHB_Invoke(int client)
{
	int boss=FF2_GetBossIndex(client);
	EmitSoundToAll(HEAVY_MELEE,client);
	float babifylength=FF2_GetAbilityArgumentFloat(boss, this_plugin_name, FEMHEAVY_BABIFY, 1);
	TF2_RemoveWeaponSlot(client, TFWeaponSlot_Melee);
	SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", SpawnWeapon(client, "tf_weapon_fists", 43, 103, 5, "68 ; 2 ; 2 ; 9 ; 205 ; 0 ; 206 ; 4 ; 275 ; 1 ; 2025 ; 2 ; 2014 ; 1"));
	SDKHook(client, SDKHook_PreThink, Babify_PreThink);
	DSM_SetOverrideSpeed(client, 520.0);
	EndBabifyAt[client]=GetEngineTime()+babifylength;
	for(int i=1; i<=MaxClients; i++)
	{
		if(IsValidClient(i) && IsPlayerAlive(i))
			TF2_AddCondition(i, TFCond_MeleeOnly, babifylength);
	}
}

public void Babify_PreThink(int client)
{
	Babify_Counter(client, GetEngineTime());
}

public void Babify_Counter(int client, float gTime)
{
	if(gTime>=EndBabifyAt[client])
	{
		TF2_RemoveWeaponSlot(client, TFWeaponSlot_Melee);
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", SpawnWeapon(client, "tf_weapon_fists", 5, 103, 5, "2 ; 3.1 ; 68 ; 2 ; 205 ; 0.7 ; 206 ; 1.5 ; 275 ; 1 ; 2025 ; 2 ; 2014 ; 1"));
		EndBabifyAt[client]=INACTIVE;
		DSM_SetOverrideSpeed(client, -1.0);
		SDKUnhook(client, SDKHook_PreThink, Babify_PreThink);		
		/* - added - */
		SetEntPropFloat(client, Prop_Send, "m_flModelScale", 0.5); // i just don't know the size
		CheckResize(INVALID_HANDLE, GetClientUserId(client));
	}
}

public Action CheckResize(Handle Timer, int userId)
{
	int clientIdx=GetClientOfUserId(userId);
	if(IsValidClient(clientIdx) && IsPlayerAlive(clientIdx))
	{
		float curPos[3];
		GetEntPropVector(clientIdx, Prop_Data, "m_vecOrigin", curPos);
		if(IsSpotSafe(clientIdx, curPos, 1.0)) // no stuck, resize
		{
			SetEntPropFloat(clientIdx, Prop_Send, "m_flModelScale", 1.0);
			PrintCenterText(clientIdx, "");
		}
		else // stuck, no resize, try it later
		{
			CreateTimer(0.2, CheckResize, userId);
			SDKHooks_TakeDamage(clientIdx, 0, 0, float(BABIFY_STUCKDMG), DMG_DROWN/*DMG_PREVENT_PHYSICS_FORCE*/);
			PrintCenterText(clientIdx, "You are stuck in the wall or floor!");
		}
	}
}

/*
	sarysa's safe resizing code
*/

// i just copied it

bool ResizeTraceFailed;
public bool Resize_TracePlayersAndBuildings(int entity, any contentsMask)
{
	if (IsValidEntity(entity))
	{
		static char classname[64];
		GetEntityClassname(entity, classname, sizeof(classname));
		if ((strcmp(classname, "obj_sentrygun") == 0) || (strcmp(classname, "obj_dispenser") == 0) || (strcmp(classname, "obj_teleporter") == 0)
			|| (strcmp(classname, "prop_dynamic") == 0) || (strcmp(classname, "func_physbox") == 0) || (strcmp(classname, "func_breakable") == 0))
		{
			ResizeTraceFailed = true;
		}
	}

	return false;
}

bool Resize_OneTrace(const float startPos[3], const float endPos[3])
{
	static float result[3];
	TR_TraceRayFilter(startPos, endPos, MASK_PLAYERSOLID, RayType_EndPoint, Resize_TracePlayersAndBuildings);
	if (ResizeTraceFailed)
	{
		return false;
	}
	TR_GetEndPosition(result);
	if (endPos[0] != result[0] || endPos[1] != result[1] || endPos[2] != result[2])
	{
		return false;
	}
	
	return true;
}

// the purpose of this method is to first trace outward, upward, and then back in.
bool Resize_TestResizeOffset(const float bossOrigin[3], float xOffset, float yOffset, float zOffset)
{
	static float tmpOrigin[3];
	tmpOrigin[0] = bossOrigin[0];
	tmpOrigin[1] = bossOrigin[1];
	tmpOrigin[2] = bossOrigin[2];
	static float targetOrigin[3];
	targetOrigin[0] = bossOrigin[0] + xOffset;
	targetOrigin[1] = bossOrigin[1] + yOffset;
	targetOrigin[2] = bossOrigin[2];
	
	if (!(xOffset == 0.0 && yOffset == 0.0))
		if (!Resize_OneTrace(tmpOrigin, targetOrigin))
			return false;
		
	tmpOrigin[0] = targetOrigin[0];
	tmpOrigin[1] = targetOrigin[1];
	tmpOrigin[2] = targetOrigin[2] + zOffset;

	if (!Resize_OneTrace(targetOrigin, tmpOrigin))
		return false;
		
	targetOrigin[0] = bossOrigin[0];
	targetOrigin[1] = bossOrigin[1];
	targetOrigin[2] = bossOrigin[2] + zOffset;
		
	if (!(xOffset == 0.0 && yOffset == 0.0))
		if (!Resize_OneTrace(tmpOrigin, targetOrigin))
			return false;
		
	return true;
}

bool Resize_TestSquare(const float bossOrigin[3], float xmin, float xmax, float ymin, float ymax, float zOffset)
{
	static float pointA[3];
	static float pointB[3];
	for (int phase = 0; phase <= 7; phase++)
	{
		// going counterclockwise
		if (phase == 0)
		{
			pointA[0] = bossOrigin[0] + 0.0;
			pointA[1] = bossOrigin[1] + ymax;
			pointB[0] = bossOrigin[0] + xmax;
			pointB[1] = bossOrigin[1] + ymax;
		}
		else if (phase == 1)
		{
			pointA[0] = bossOrigin[0] + xmax;
			pointA[1] = bossOrigin[1] + ymax;
			pointB[0] = bossOrigin[0] + xmax;
			pointB[1] = bossOrigin[1] + 0.0;
		}
		else if (phase == 2)
		{
			pointA[0] = bossOrigin[0] + xmax;
			pointA[1] = bossOrigin[1] + 0.0;
			pointB[0] = bossOrigin[0] + xmax;
			pointB[1] = bossOrigin[1] + ymin;
		}
		else if (phase == 3)
		{
			pointA[0] = bossOrigin[0] + xmax;
			pointA[1] = bossOrigin[1] + ymin;
			pointB[0] = bossOrigin[0] + 0.0;
			pointB[1] = bossOrigin[1] + ymin;
		}
		else if (phase == 4)
		{
			pointA[0] = bossOrigin[0] + 0.0;
			pointA[1] = bossOrigin[1] + ymin;
			pointB[0] = bossOrigin[0] + xmin;
			pointB[1] = bossOrigin[1] + ymin;
		}
		else if (phase == 5)
		{
			pointA[0] = bossOrigin[0] + xmin;
			pointA[1] = bossOrigin[1] + ymin;
			pointB[0] = bossOrigin[0] + xmin;
			pointB[1] = bossOrigin[1] + 0.0;
		}
		else if (phase == 6)
		{
			pointA[0] = bossOrigin[0] + xmin;
			pointA[1] = bossOrigin[1] + 0.0;
			pointB[0] = bossOrigin[0] + xmin;
			pointB[1] = bossOrigin[1] + ymax;
		}
		else if (phase == 7)
		{
			pointA[0] = bossOrigin[0] + xmin;
			pointA[1] = bossOrigin[1] + ymax;
			pointB[0] = bossOrigin[0] + 0.0;
			pointB[1] = bossOrigin[1] + ymax;
		}

		for (int shouldZ = 0; shouldZ <= 1; shouldZ++)
		{
			pointA[2] = pointB[2] = shouldZ == 0 ? bossOrigin[2] : (bossOrigin[2] + zOffset);
			if (!Resize_OneTrace(pointA, pointB))
				return false;
		}
	}
		
	return true;
}

public bool IsSpotSafe(int clientIdx, float playerPos[3], float sizeMultiplier)
{
	ResizeTraceFailed = false;
	static float mins[3];
	static float maxs[3];
	mins[0] = -24.0 * sizeMultiplier;
	mins[1] = -24.0 * sizeMultiplier;
	mins[2] = 0.0;
	maxs[0] = 24.0 * sizeMultiplier;
	maxs[1] = 24.0 * sizeMultiplier;
	maxs[2] = 82.0 * sizeMultiplier;

	// the eight 45 degree angles and center, which only checks the z offset
	if (!Resize_TestResizeOffset(playerPos, mins[0], mins[1], maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, mins[0], 0.0, maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, mins[0], maxs[1], maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, 0.0, mins[1], maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, 0.0, 0.0, maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, 0.0, maxs[1], maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, maxs[0], mins[1], maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, maxs[0], 0.0, maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, maxs[0], maxs[1], maxs[2])) return false;

	// 22.5 angles as well, for paranoia sake
	if (!Resize_TestResizeOffset(playerPos, mins[0], mins[1] * 0.5, maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, mins[0], maxs[1] * 0.5, maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, maxs[0], mins[1] * 0.5, maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, maxs[0], maxs[1] * 0.5, maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, mins[0] * 0.5, mins[1], maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, maxs[0] * 0.5, mins[1], maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, mins[0] * 0.5, maxs[1], maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, maxs[0] * 0.5, maxs[1], maxs[2])) return false;

	// four square tests
	if (!Resize_TestSquare(playerPos, mins[0], maxs[0], mins[1], maxs[1], maxs[2])) return false;
	if (!Resize_TestSquare(playerPos, mins[0] * 0.75, maxs[0] * 0.75, mins[1] * 0.75, maxs[1] * 0.75, maxs[2])) return false;
	if (!Resize_TestSquare(playerPos, mins[0] * 0.5, maxs[0] * 0.5, mins[1] * 0.5, maxs[1] * 0.5, maxs[2])) return false;
	if (!Resize_TestSquare(playerPos, mins[0] * 0.25, maxs[0] * 0.25, mins[1] * 0.25, maxs[1] * 0.25, maxs[2])) return false;
	
	return true;
}

// BOSSRAGE / Death Effects
void Boss_Abilities(const char[] ability_name, int boss, int rType, int bClient)
{
	switch(rType)
	{
		case 1: // Reimu Hakurei
		{
			TF2_AddCondition(bClient, TFCond_UberBulletResist, FF2_GetAbilityArgumentFloat(boss,this_plugin_name,ability_name,2,5.0));
			TF2_AddCondition(bClient, TFCond_BulletImmune, FF2_GetAbilityArgumentFloat(boss,this_plugin_name,ability_name,2,5.0));
			TF2_AddCondition(bClient, TFCond_UberBlastResist, FF2_GetAbilityArgumentFloat(boss,this_plugin_name,ability_name,2,5.0));
			TF2_AddCondition(bClient, TFCond_BlastImmune, FF2_GetAbilityArgumentFloat(boss,this_plugin_name,ability_name,2,5.0));
			TF2_AddCondition(bClient, TFCond_UberFireResist, FF2_GetAbilityArgumentFloat(boss,this_plugin_name,ability_name,2,5.0));
			TF2_AddCondition(bClient, TFCond_FireImmune, FF2_GetAbilityArgumentFloat(boss,this_plugin_name,ability_name,2,5.0));
			int clonespawn=FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, 3, 0); // Spawn Clone? Ability Becomes Instant Dimensional Rift
			if(clonespawn != 0)
			{
				if(!disableclone)
					Multiplier_Rage(ability_name, boss, rType);
				else
					PrintHintText(bClient, "%t", "reimu_clone_disable");
			}		
			Teleport_Me(bClient);
		}
		case 2: // Human Sentry Buster
		{
			// Because doing the commands directly seem to kick the boss, hence timers.
			bRange = FF2_GetAbilityArgumentFloat(boss,this_plugin_name,ability_name, 2);	//range
			bDmg = FF2_GetAbilityArgument(boss,this_plugin_name,ability_name, 3); // Damage
			CreateTimer(0.1, SentryBustPrepare, bClient);
			CreateTimer(2.1, SentryBusting, bClient);
		}
	}
	if(rType!=2)
		CreateTimer(0.1, PreventTaunt,boss);	//Remove taunt condition from boss if using pre-1.10.x versions of FF2
}

// Clone Events for Handsome Jack & Reimu Hakurei, and Summon for Blutarch
void Multiplier_Rage(const char[] ability_name, int boss, int rType)
{
	int bClient=GetClientOfUserId(FF2_GetBossUserId(boss));
	int minions, clone, spawnhealth;
	float position[3], velocity[3];
	switch(rType)
	{
		case 1: // Reimu
			minions=1;
		case 4: // Jack
			minions=3;
	}
	if(rType==4)
	{
		if(liveplayers < minions|| !minions) 
			minions=liveplayers;
	}
	GetEntPropVector(bClient, Prop_Data, "m_vecOrigin", position);
	for (int i=0; i<minions; i++)
	{
		clone = GetRandomDeadPlayer();
		if(clone  != -1)
		{
			FF2_SetFF2flags(clone,FF2_GetFF2flags(clone)|FF2FLAG_ALLOWSPAWNINBOSSTEAM);
			ChangeClientTeam(clone,FF2_GetBossTeam());
			TF2_RespawnPlayer(clone);
			SummonerIndex[clone]=boss;
			switch(rType)
			{
				case 1: // Reimu
				{
					disableclone = true;
					TF2_SetPlayerClass(clone, TFClass_Soldier, _, false);
				}
				case 4: // Jack
				{
					switch (GetRandomInt(0,3))
					{
					case 0:
						TF2_SetPlayerClass(clone, TFClass_Soldier, _, false);
					case 1:
						TF2_SetPlayerClass(clone, TFClass_DemoMan, _, false);
					case 2:
						TF2_SetPlayerClass(clone, TFClass_Sniper, _, false);
					case 3:
						TF2_SetPlayerClass(clone, TFClass_Spy, _, false);
					}
				}
			}
			TF2_RemoveAllWeapons(clone);
			int wearables, owner;
			while((wearables=FindEntityByClassname(wearables, "tf_wearable"))!=-1)
				if((owner=GetEntPropEnt(wearables, Prop_Send, "m_hOwnerEntity"))<=MaxClients && owner>0 && GetClientTeam(owner)==FF2_GetBossTeam())
					TF2_RemoveWearable(owner, wearables);
			while((wearables=FindEntityByClassname(wearables, "tf_wearable_demoshield"))!=-1)
				if((owner=GetEntPropEnt(wearables, Prop_Send, "m_hOwnerEntity"))<=MaxClients && owner>0 && GetClientTeam(owner)==FF2_GetBossTeam())
					TF2_RemoveWearable(owner, wearables);
			while((wearables=FindEntityByClassname(wearables, "tf_powerup_bottle"))!=-1)
				if((owner=GetEntPropEnt(wearables, Prop_Send, "m_hOwnerEntity"))<=MaxClients && owner>0 && GetClientTeam(owner)==FF2_GetBossTeam())
					TF2_RemoveWearable(owner, wearables);
			switch(rType)
			{
				case 1: // Reimu
				{
					SetEntPropEnt(clone, Prop_Send, "m_hActiveWeapon", SpawnWeapon(clone, "tf_weapon_katana", 357, 102, 5, "235 ; 1 ; 68 ; -1 ; 26 ; 7100 ; 2 ; 99 ; 226 ; 1 ; 236 ; 1 ; 1005 ; 8208497 ; 259 ; 1"));
					spawnhealth=FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, 4, 0);
					int cloneprotect=FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, 5, 0); // Protect Clone at spawn?
					if(cloneprotect!=0)
					{
						TF2_AddCondition(clone, TFCond_UberBulletResist, float(cloneprotect));
						TF2_AddCondition(clone, TFCond_BulletImmune, float(cloneprotect));
						TF2_AddCondition(clone, TFCond_UberBlastResist, float(cloneprotect));
						TF2_AddCondition(clone, TFCond_BlastImmune, float(cloneprotect));
						TF2_AddCondition(clone, TFCond_UberFireResist, float(cloneprotect));
						TF2_AddCondition(clone, TFCond_FireImmune, float(cloneprotect));
					}
					SetVariantString("models/player/reimu.mdl");
					AcceptEntityInput(clone, "SetCustomModel");
					SetEntProp(clone, Prop_Send, "m_bUseClassAnimations", 1);
					if(!spawnhealth)
					{
						switch(FF2_GetBossLives(boss))
						{
							case 1:
							{
								if(FF2_GetBossHealth(boss)<2000)
									spawnhealth=(FF2_GetBossHealth(boss));
								else
									spawnhealth=((FF2_GetBossHealth(boss))/4);
							}
							default:	
								spawnhealth=(FF2_GetBossHealth(boss))/FF2_GetBossLives(boss);
							
						}
					}
				}
				case 4: // Jack
				{
					switch(TF2_GetPlayerClass(clone))
					{
						case TFClass_Soldier:
						{
							switch (GetRandomInt(0,3))
							{
								case 0:
									SetEntPropEnt(clone, Prop_Send, "m_hActiveWeapon", SpawnWeapon(clone, "tf_weapon_rocketlauncher_airstrike", 1104, 102, 5, "112 ; 9 ; 1 ; 0.75 ; 3 ; 0.75 ; 15 ; 1 ; 68 ; -1 ; 100 ; 0.85 ; 288 ; 1 ; 621 ; 0.35 ; 642 ; 1 ; 643 ; 0.75 ; 644 ; 5 ; 2025 ; 2 ; 2014 ; 1 ; 259 ; 1"));
								case 1:
									SetEntPropEnt(clone, Prop_Send, "m_hActiveWeapon", SpawnWeapon(clone, "tf_weapon_shovel", 128, 102, 5, "15 ; 1 ; 68 ; -1 ; 259 ; 1 ; 288 ; 1 ; 179 ; 1 ; 2025 ; 2 ; 2014 ; 1"));
								case 2:
									SetEntPropEnt(clone, Prop_Send, "m_hActiveWeapon", SpawnWeapon(clone, "tf_weapon_shovel", 474, 102, 5, "15 ; 1 ; 68 ; -1 ; 259 ; 1 ; 288 ; 1 ; 408 ; 1 ; 2025 ; 2 ; 2014 ; 1"));
								case 3:
									SetEntPropEnt(clone, Prop_Send, "m_hActiveWeapon", SpawnWeapon(clone, "tf_weapon_shovel", 154, 102, 5, "15 ; 1 ; 68 ; -1 ; 259 ; 1 ; 288 ; 1 ; 341 ; 1 ; 2025 ; 2 ; 2014 ; 1"));
							}
						}
						case TFClass_DemoMan:
						{
							switch (GetRandomInt(0,3))
							{
								case 0:
									SetEntPropEnt(clone, Prop_Send, "m_hActiveWeapon", SpawnWeapon(clone, "tf_weapon_grenadelauncher", 1151, 102, 5, " 259 ; 1 ; 112 ; 9 ; 1 ; 0.5 ; 15 ; 1 ; 68 ; -1 ; 288 ; 1 ; 2025 ; 2 ; 2014 ; 1"));
								case 1:
									SetEntPropEnt(clone, Prop_Send, "m_hActiveWeapon", SpawnWeapon(clone, "tf_weapon_cannon", 996, 102, 5, " 259 ; 1 ; 112 ; 9 ; 1 ; 0.5 ; 15 ; 1 ; 68 ; -1 ; 288 ; 1 ; 466 ; 1 ; 477 ; 1 ; 2025 ; 2 ; 2014 ; 1"));
								case 2:
									SetEntPropEnt(clone, Prop_Send, "m_hActiveWeapon", SpawnWeapon(clone, "tf_weapon_stickbomb", 307, 102, 5, "259 ; 1 ; 15 ; 1 ; 68 ; -1 ; 288 ; 1 ; 408 ; 1 ; 414 ; 1 ; 2025 ; 2 ; 2014 ; 1"));
								case 3:
									SetEntPropEnt(clone, Prop_Send, "m_hActiveWeapon", SpawnWeapon(clone, "tf_weapon_shovel", 154, 102, 5, " 259 ; 1 ; 15 ; 1 ; 68 ; -1 ; 288 ; 1 ; 341 ; 1 ; 2025 ; 2 ; 2014 ; 1"));	
							}
						}
						case TFClass_Sniper:
						{
							switch (GetRandomInt(0,2))
							{
								case 0:
									SetEntPropEnt(clone, Prop_Send, "m_hActiveWeapon", SpawnWeapon(clone, "tf_weapon_club", 401, 102, 5, "259 ; 1 ; 15 ; 1 ; 68 ; -1 ; 288 ; 1 ; 408 ; 1 ; 414 ; 1 ; 2025 ; 2 ; 2014 ; 1"));
								case 1:
									SetEntPropEnt(clone, Prop_Send, "m_hActiveWeapon", SpawnWeapon(clone, "tf_weapon_club", 401, 102, 5, "259 ; 1 ; 15 ; 1 ; 68 ; -1 ; 179 ; 1 ; 218 ; 1 ; 288 ; 1 ; 2025 ; 2 ; 2014 ; 1"));
								case 2:
									SetEntPropEnt(clone, Prop_Send, "m_hActiveWeapon", SpawnWeapon(clone, "tf_weapon_club", 401, 102, 5, "259 ; 1 ; 15 ; 1 ; 68 ; -1 ; 288 ; 1 ; 402 ; 1 ; 2025 ; 2 ; 2014 ; 1"));
								case 3:
									SetEntPropEnt(clone, Prop_Send, "m_hActiveWeapon", SpawnWeapon(clone, "tf_weapon_club", 401, 102, 5, "259 ; 1 ; 15 ; 1 ; 68 ; -1 ; 288 ; 1 ; 341 ; 1 ; 2025 ; 2 ; 2014 ; 1"));
							}
						}
						case TFClass_Spy:
						{
							switch (GetRandomInt(0,2))
							{
								case 0:
									SetEntPropEnt(clone, Prop_Send, "m_hActiveWeapon", SpawnWeapon(clone, "tf_weapon_knife", 638, 102, 5, "259 ; 1 ; 15 ; 1 ; 68 ; -1 ; 156 ; 1 ; 288 ; 1 ; 328 ; 1 ; 2025 ; 2 ; 2014 ; 1")), SpawnWeapon(clone, "tf_weapon_invis", 59, 102, 5, "33 ; 1 ; 35 ; 1.1 ; 292 ; 1");
								case 1:
									SetEntPropEnt(clone, Prop_Send, "m_hActiveWeapon", SpawnWeapon(clone, "tf_weapon_knife", 638, 102, 5, "259 ; 1 ; 15 ; 1 ; 68 ; -1 ; 154 ; 1 ; 155 ; 1 ; 156 ; 1 ; 288 ; 1 ; 328 ; 1 ; 2025 ; 2 ; 2014 ; 1")), SpawnWeapon(clone, "tf_weapon_invis", 947, 102, 5, "253 ; 4 ; 292 ; 1");
								case 2:
									SetEntPropEnt(clone, Prop_Send, "m_hActiveWeapon", SpawnWeapon(clone, "tf_weapon_knife", 638, 102, 5, "259 ; 1 ; 15 ; 1 ; 68 ; -1 ; 154 ; 1 ; 155 ; 1 ; 288 ; 1 ; 328 ; 1 ; 2025 ; 2 ; 2014 ; 1")), SpawnWeapon(clone, "tf_weapon_invis", 297, 102, 5, "253 ; 1 ; 292 ; 1");
							}
						}
					}
					if(FF2_GetBossHealth(boss)<2000)
						spawnhealth=600;
					else
						spawnhealth=((FF2_GetBossHealth(boss))/minions);
					SetVariantString("models/freak_fortress_2/handsome_jack/jack.mdl");
					AcceptEntityInput(clone, "SetCustomModel");
					SetEntProp(clone, Prop_Send, "m_bUseClassAnimations", 1);
				}	
			}
			SetEntProp(clone, Prop_Data, "m_iMaxHealth", spawnhealth);
			SetEntProp(clone, Prop_Data, "m_iHealth", spawnhealth);
			SetEntProp(clone, Prop_Send, "m_iHealth", spawnhealth);
			if(GetEntProp(bClient, Prop_Send, "m_bDucked"))
			{
				float temp[3]={24.0, 24.0, 62.0};
				SetEntPropVector(clone, Prop_Send, "m_vecMaxs", temp);
				SetEntProp(clone, Prop_Send, "m_bDucked", 1);
				SetEntityFlags(clone, GetEntityFlags(clone)|FL_DUCKING);
			}
			TeleportEntity(clone, position, NULL_VECTOR, velocity);
		}
	}
}

// A C T I O N S

public Action FF2_OnAlivePlayersChanged(int players, int bosses)
{
	liveplayers = players;
	livebosses =  bosses;
}

// Modified from Eggman's Skeleton King reincarnation code.
public Action FF2_OnLoseLife(int boss)
{
	int userid = FF2_GetBossUserId(boss);
	int client = GetClientOfUserId(userid);
	int rType = FF2_GetAbilityArgument(boss,this_plugin_name,BOSSRAGE, 1);
	if(boss==-1 || !IsValidEdict(client) || !FF2_HasAbility(boss, this_plugin_name, BOSSRAGE))
	{
			return Plugin_Continue;
	}
	if (DenyElixir[boss])
	{
		{
		//ForcePlayerSuicide(client);
		}
	}
	else
	{
		if (rType==8) // Eirin's Hourai Elixir's Life Renegeration Ability (Can be fitted to Mokou, Kaguya and Chang'e since they also have consumed the Hourai Elixir)
		{
			LostLife[boss] = true;
			DenyElixir[boss] = true;
			timeleft[boss]=FF2_GetAbilityArgument(boss, this_plugin_name, BOSSRAGE, 2, 60)+addtime[boss];
			addtime[boss]+=FF2_GetAbilityArgument(boss, this_plugin_name, BOSSRAGE, 3, 60);
			if (DelayElixir[boss] != null)
				delete DelayElixir[boss];
			DelayElixir[boss]=CreateTimer(1.0, GainLife, boss, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			FF2_SetBossLives(boss,2);
			FF2_SetBossHealth(boss,FF2_GetBossMaxHealth(boss));
			SetHudTextParams(-1.0, 0.35, 10.0, 255, 255, 255, 255);
			char charname[256];
			FF2_GetBossSpecial(boss,charname,256,0);
			char text[5120];
			Format(text,5120,"%t","delay_info",timeleft[boss],charname);
			GetClientOfUserId(FF2_GetBossUserId(boss));
			for(int i = 1; i <= MaxClients; i++ )
			if(IsValidClient(i) && IsPlayerAlive(i) && GetClientTeam(i)!=FF2_GetBossTeam())
				ShowSyncHudText(i, cooldownHUD, text);
		}
	}
	return Plugin_Continue;
}

public Action BlockDamage(int client, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	char spcl[64];
	int bClient = FF2_GetBossIndex(client);
	if(bClient != -1)
	{
		if(GetClientTeam(client) != FF2_GetBossTeam())
		{
			FF2_GetBossSpecial(bClient,spcl,64,0);
			SetHudTextParams(-1.0, 0.45, 4.0, 255, 255, 255, 255);
			ShowSyncHudText(attacker, statusHUD, "%t","time_to_kaboom",spcl);
		}	
		return Plugin_Stop;
	}
	return Plugin_Continue;
}	

void Teleport_Me(int client)
{
	float pos_2[3];
	int target;
	int teleportme;
	bool AlivePlayers;
	for(int ii=1;ii<=MaxClients;ii++)
	if(IsValidEdict(ii) && IsValidClient(ii) && IsPlayerAlive(ii) && GetClientTeam(ii)!=FF2_GetBossTeam())
	{
		AlivePlayers = true;
		break;
	}
	do
	{
		teleportme++;
		target = GetRandomInt(1,MaxClients);
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
			float temp[3]={24.0, 24.0, 62.0};
			SetEntPropVector(client, Prop_Send, "m_vecMaxs", temp);
			SetEntProp(client, Prop_Send, "m_bDucked", 1);
			SetEntityFlags(client, GetEntityFlags(client)|FL_DUCKING);
		}
		TeleportEntity(client, pos_2, NULL_VECTOR, NULL_VECTOR);
	}
}

/*void ForceTeamWin(int team)
{
	int entity=FindEntityByClassname(-1, "team_control_point_master");
	if(entity==-1)
	{
		entity = CreateEntityByName("team_control_point_master");
		DispatchSpawn(entity);
		AcceptEntityInput(entity, "Enable");
	}
	SetVariantInt(team);
	AcceptEntityInput(entity, "SetWinner");
}*/

// call AMS from epic scout's subplugin via reflection:
stock Handle FindPlugin(char[] pluginName)
{
	char buffer[256];
	char path[PLATFORM_MAX_PATH];
	Handle iter = GetPluginIterator();
	Handle pl = null;
	
	while (MorePlugins(iter))
	{
		pl = ReadPlugin(iter);
		Format(path, sizeof(path), "%s.ff2", pluginName);
		GetPluginFilename(pl, buffer, sizeof(buffer));
		if (StrContains(buffer, path, false) >= 0)
			break;
		else
			pl = null;
	}
	
	delete iter;

	return pl;
}

#define MAX_STR_LENGTH 256
// this will tell AMS that the abilities listed on PrepareAbilities() supports AMS
stock void AMS_InitSubability(int bossIdx, int clientIdx, const char[] pluginName, const char[] abilityName, const char[] prefix)
{
	Handle plugin = FindPlugin("ff2_sarysapub3");
	if (plugin != null)
	{
		Function func = GetFunctionByName(plugin, "AMS_InitSubability");
		if (func != INVALID_FUNCTION)
		{
			
			Call_StartFunction(plugin, func);
			Call_PushCell(bossIdx);
			Call_PushCell(clientIdx);
			Call_PushString(pluginName);
			Call_PushString(abilityName);
			Call_PushString(prefix);
			Call_Finish();
		}
		else
			LogError("ERROR: Unable to initialize ff2_sarysapub3:AMS_InitSubability()");
	}
	else
		LogError("ERROR: Unable to initialize ff2_sarysapub3:AMS_InitSubability(). Make sure this plugin exists!");

}


// S T O C K S
stock bool IsValidClient(int client)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client) || !IsClientConnected(client)) return false;
	if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	return true;
}

stock bool IsValidBoss(int client)
{
	if (FF2_GetBossIndex(client) == -1) return false;
	return true;
}

stock bool IsValidMinion(int client)
{
	if (GetClientTeam(client)!=FF2_GetBossTeam()) return false;
	if (FF2_GetBossIndex(client) != -1) return false;
	return true;

}

stock int SetClip(int client, int slot, int clip)
{
	int weapon = GetPlayerWeaponSlot(client, slot);
	if (IsValidEntity(weapon))
	{
		SetEntProp(weapon, Prop_Send, "m_iClip1", clip);
	}
}

stock int SetAmmo(int client, int slot, int ammo)
{
	int weapon = GetPlayerWeaponSlot(client, slot);
	if (IsValidEntity(weapon))
	{
		int iOffset = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1)*4;
		int iAmmoTable = FindSendPropInfo("CTFPlayer", "m_iAmmo");
		SetEntData(client, iAmmoTable+iOffset, ammo, 4, true);
	}
}

stock int SpawnWeapon(int client, char[] name, int index, int level, int qual, char[] att)
{
	Handle hWeapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
	TF2Items_SetClassname(hWeapon, name);
	TF2Items_SetItemIndex(hWeapon, index);
	TF2Items_SetLevel(hWeapon, level);
	TF2Items_SetQuality(hWeapon, qual);
	char atts[32][32];
	int count = ExplodeString(att, " ; ", atts, 32, 32);
	if (count > 0)
	{
		TF2Items_SetNumAttributes(hWeapon, count/2);
		int i2 = 0;
		for (int i = 0; i < count; i+=2)
		{
			TF2Items_SetAttribute(hWeapon, i2, StringToInt(atts[i]), StringToFloat(atts[i+1]));
			i2++;
		}
	}
	else
		TF2Items_SetNumAttributes(hWeapon, 0);
	if (hWeapon==null)
		return -1;
	int entity = TF2Items_GiveNamedItem(client, hWeapon);
	delete hWeapon;
	EquipPlayerWeapon(client, entity);
	return entity;
}

stock int GetRandomDeadPlayer()
{
	int[] clients = new int[MaxClients+1];
	int clientCount;
	for(int i=1;i<=MaxClients;i++)
	{
		if(IsValidEdict(i) && IsValidClient(i) && !IsValidBoss(i) && !IsPlayerAlive(i) && (GetClientTeam(i) > 1))
		{
			clients[clientCount++] = i;
		}
	}
	return (clientCount == 0) ? -1 : clients[GetRandomInt(0, clientCount-1)];
}

stock void DoDamage(int client, int target, int amount) // from Goomba Stomp.
{
	int pointHurt = CreateEntityByName("point_hurt");
	if (pointHurt)
	{
		DispatchKeyValue(target, "targetname", "explodeme");
		DispatchKeyValue(pointHurt, "DamageTarget", "explodeme");
		char dmg[15];
		Format(dmg, 15, "%i", amount);
		DispatchKeyValue(pointHurt, "Damage", dmg);
		DispatchKeyValue(pointHurt, "DamageType", "0");

		DispatchSpawn(pointHurt);
		AcceptEntityInput(pointHurt, "Hurt", client);
		DispatchKeyValue(pointHurt, "classname", "point_hurt");
		DispatchKeyValue(target, "targetname", "");
		RemoveEdict(pointHurt);
	}
}

stock bool AttachParticle(int Ent, char[] particleType, bool cache=false) // from L4D Achievement Trophy
{
	int particle = CreateEntityByName("info_particle_system");
	if (!IsValidEdict(particle)) return false;
	char tName[128];
	float f_pos[3];
	if (cache) f_pos[2] -= 3000;
	else
	{
		GetEntPropVector(Ent, Prop_Send, "m_vecOrigin", f_pos);
		f_pos[2] += 60;
	}
	TeleportEntity(particle, f_pos, NULL_VECTOR, NULL_VECTOR);
	Format(tName, sizeof(tName), "target%i", Ent);
	DispatchKeyValue(Ent, "targetname", tName);
	DispatchKeyValue(particle, "effect_name", particleType);
	DispatchSpawn(particle);
	SetVariantString(tName);
	AcceptEntityInput(particle, "SetParent", particle, particle, 0);
	ActivateEntity(particle);
	AcceptEntityInput(particle, "start");
	CreateTimer(10.0, DeleteParticle, particle);
	return true;
}


public Action OnRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	for(int client=1;client<=MaxClients;client++)
	{	
		if(!IsValidClient(client))
			continue;
		LostLife[client] = false;		
		addtime[client] = 0;
		DenyElixir[client] = false;
		SummonerIndex[client] = -1;
		EndBabifyAt[client]=INACTIVE;
	}
	return Plugin_Continue;
}

public Action OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	char weapon[50];
	event.GetString("weapon", weapon, sizeof(weapon));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int client = GetClientOfUserId(event.GetInt("userid"));
	int b0ss = FF2_GetBossIndex(attacker);
	int boss = FF2_GetBossIndex(client);
	
	if(IsValidMinion(client) && !(event.GetInt("death_flags") & TF_DEATHFLAG_DEADRINGER))
	{
		if(disableclone)
		{
			disableclone = false;
		}
		SummonerIndex[client] = -1;
		ChangeClientTeam(client, (FF2_GetBossTeam()==view_as<int>(TFTeam_Blue)) ? (view_as<int>(TFTeam_Red)) : (view_as<int>(TFTeam_Blue)));
	}
	
	if(b0ss != -1 && FF2_HasAbility(b0ss, this_plugin_name, BOSSRAGE))
	{
		switch(FF2_GetAbilityArgument(b0ss,this_plugin_name,BOSSRAGE, 1))
		{
			case 3: // miku
			{
				if(StrEqual(weapon, "guillotine", false))
				{
					SetEventString(event, "weapon", "taunt_scout");
					SetEventString(event, "weapon_logclassname", "leek");
				}
			}
			case 7: // Spyper
			{
				if(StrEqual(weapon, "knife", false))
				{
					SetEventString(event, "weapon", "club");
					SetEventString(event, "weapon_logclassname", "club");
				}
			}
		}
	}
	
	if(boss!=-1 && !(event.GetInt("death_flags") & TF_DEATHFLAG_DEADRINGER))
	{
		switch(FF2_GetAbilityArgument(b0ss,this_plugin_name,BOSSRAGE, 1))
		{
			case 1, 4: // Reimu & Handsome Jack
			{
				for(int clone=1; clone<=MaxClients; clone++)
				{
					if(SummonerIndex[clone]==boss && IsValidClient(clone) && IsValidMinion(clone) && IsPlayerAlive(clone))
					{
						SummonerIndex[clone]=-1;
						ChangeClientTeam(clone, (FF2_GetBossTeam()==view_as<int>(TFTeam_Blue)) ? (view_as<int>(TFTeam_Red)) : (view_as<int>(TFTeam_Blue)));
					}
				}
			}
		}
	}
}	

public Action OnUberDeploy(Event event, const char[] name, bool dontBroadcast)
{
	int uberuser = GetClientOfUserId(event.GetInt("userid"));
	int selfhealer = FF2_GetBossIndex(uberuser);
	if(selfhealer!=-1)
	{
		if(FF2_HasAbility(selfhealer, this_plugin_name, BOSSRAGE))
		{
			if (FF2_GetAbilityArgument(selfhealer,this_plugin_name,BOSSRAGE, 1) == 8)
			{
				EmitSoundToAll(EIRIN_UBER_DEPLOYED, uberuser);
			}
		}
	}
}
	
		
// T I M E R S

public Action PreventTaunt(Handle timer,any userid)
{
	int bClient = GetClientOfUserId(FF2_GetBossUserId(userid));
	if (!GetEntProp(bClient, Prop_Send, "m_bIsReadyToHighFive") && !IsValidEntity(GetEntPropEnt(bClient, Prop_Send, "m_hHighFivePartner")))
	{
		TF2_RemoveCondition(bClient,TFCond_Taunting);
		float up[3];
		up[2]=220.0;
		TeleportEntity(bClient,NULL_VECTOR, NULL_VECTOR,up);
	}
	else if(TF2_IsPlayerInCondition(bClient, TFCond_Taunting))
		TF2_RemoveCondition(bClient,TFCond_Taunting);
	return Plugin_Continue;
}

public Action StopInvun(Handle timer, any userid)
{
	SetEntProp(GetClientOfUserId(FF2_GetBossUserId(userid)), Prop_Data, "m_takedamage", 2);
	return Plugin_Continue;
}

public Action GainLife(Handle timer, any boss)
{
	timeleft[boss]--;
	int bClient=GetClientOfUserId(FF2_GetBossUserId(boss));
	if (FF2_GetRoundState()!=1)
	{
		delete DelayElixir[boss];
		DelayElixir[boss]= null;	
	}
	else if (timeleft[boss]<=0)
	{	
		PrintHintText(bClient, "%t", "regenerated_life");
		FF2_SetBossLives(boss,2);
		FF2_SetBossHealth(boss,FF2_GetBossHealth(boss)+FF2_GetBossMaxHealth(boss));
		DenyElixir[boss] = false;
		delete DelayElixir[boss];
		DelayElixir[boss] = null;	
	}
	else
	{
		SetHudTextParams(-1.0, 0.42, 1.0, 255, 255, 255, 255);
		ShowSyncHudText(bClient, cooldownHUD, "%t","life_regeneration",timeleft[boss]);
	}
}

public Action ResetCharge(Handle timer, any boss)
{
	int slot=boss%10000;
	boss/=1000;
	FF2_SetBossCharge(boss, slot, 0.0);
}

public Action SentryBustPrepare(Handle timer, any bClient)
{
	if(!TF2_IsPlayerInCondition(bClient, TFCond_Taunting))
		FakeClientCommand(bClient, "taunt");
	SetEntityMoveType(bClient, MOVETYPE_NONE);
	SDKHook(bClient, SDKHook_OnTakeDamage, BlockDamage);
}

public Action SentryBusting(Handle timer, any bClient)
{
	int explosion = CreateEntityByName("env_explosion");
	float clientPos[3];
	GetClientAbsOrigin(bClient, clientPos);
	if (explosion)
	{
		DispatchSpawn(explosion);
		TeleportEntity(explosion, clientPos, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(explosion, "Explode", -1, -1, 0);
		RemoveEdict(explosion);
	}
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i) || !IsPlayerAlive(i)) 
			continue;
		float zPos[3];
		GetClientAbsOrigin(i, zPos);
		float Dist = GetVectorDistance(clientPos, zPos);
		if (Dist < bRange)
			DoDamage(bClient, i, bDmg);
	}
	for (int i = MaxClients + 1; i <= 2048; i++)
	{
		if (!IsValidEntity(i)) continue;
		char cls[20];
		GetEntityClassname(i, cls, sizeof(cls));
		if (!StrEqual(cls, "obj_sentrygun", false) &&
		!StrEqual(cls, "obj_dispenser", false) &&
		!StrEqual(cls, "obj_teleporter", false)) continue;
		float zPos[3];
		GetEntPropVector(i, Prop_Send, "m_vecOrigin", zPos);
		float Dist = GetVectorDistance(clientPos, zPos);
		if (Dist < bRange)
		{
			SetVariantInt(bDmg);
			AcceptEntityInput(i, "RemoveHealth");
		}
	}
	EmitSoundToAll(HSB_EXPLODE, bClient);
	AttachParticle(bClient, "fluidSmokeExpl_ring_mvm");
	SDKUnhook(bClient, SDKHook_OnTakeDamage, BlockDamage);
	if(TF2_IsPlayerInCondition(bClient, TFCond_Taunting))
		TF2_RemoveCondition(bClient,TFCond_Taunting);
	SetEntityMoveType(bClient, MOVETYPE_WALK);
	return Plugin_Continue;
}

public Action DeleteParticle(Handle timer, any Ent)
{
	if (!IsValidEntity(Ent)) return;
	char cls[25];
	GetEdictClassname(Ent, cls, sizeof(cls));
	if (StrEqual(cls, "info_particle_system", false)) AcceptEntityInput(Ent, "Kill");
	return;
}
