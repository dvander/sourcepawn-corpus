#pragma semicolon 1

// shadow93_bosses - proc_samu_s93explosion
// A standalone version of the human sentry buster rage from shadow93_bosses.
// Includes 3 new args:
// arg3 = Delay before the explosion upon use.
// arg4 = Mapwide sound to play when the ability is activated. Can be left blank to not use.
// arg5:
// 1 = Upon using this ability, the boss will get stuck on position until explosion.
// 0 = The boss can move freely after using this ability.
#include <tf2_stocks>
#include <tf2items>
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

#pragma newdecls required // when it h

#define PLUGIN_NAME 	"Freak Fortress 2: Sentry Buster Rage"
#define PLUGIN_AUTHOR 	"OG HSB Rage by shadow93, standalone by Procustes and samuu"
#define PLUGIN_DESC 	"Makes the boss explode, dealing AOE damage."

#define MAJOR_REVISION 	"1"
#define MINOR_REVISION 	"0"
#define STABLE_REVISION "0"
#define PLUGIN_VERSION 	MAJOR_REVISION..."."...MINOR_REVISION..."."...STABLE_REVISION

#define PLUGIN_URL "servilive.cl" // xd

#define MAX_PLAYERS_ARRAY 36
#define MAX_PLAYERS (MAX_PLAYERS_ARRAY < (MaxClients + 1) ? MAX_PLAYERS_ARRAY : (MaxClients + 1))
#define MAX_SOUND_FILE_LENGTH 80

// Ints
int bDmg;
int StuckOrFree;
int toggleExplosionSound;

// floats
float bRange;
float DelayBeforeBoom;

// Handles
Handle statusHUD;

enum Operators
{
	Operator_None = 0,
	Operator_Add,
	Operator_Subtract,
	Operator_Multiply,
	Operator_Divide,
	Operator_Exponent,
};

/*
 *	Define as "test_ability"
 */
#define EXPLOSION_RAGE "rage_s93explosion"
#define HSB_EXPLODE "mvm/sentrybuster/mvm_sentrybuster_explode.wav"


public Plugin myinfo = 
{
	name 		= PLUGIN_NAME,
	author 		= PLUGIN_AUTHOR,
	description	= PLUGIN_DESC,
	version 	= PLUGIN_VERSION,
	url			= PLUGIN_URL,
};

public void OnMapStart()
{
	statusHUD = CreateHudSynchronizer();
	
	/*
     PLEASE
     FOR THE LOVE OF GOD
     NEVER FORGET ABOUT PRECACHING SOUNDS
     I FUCKING HATE WHEN I USE AN ABILITY AND THE SOUND DOESN'T PLAY
     SO PLEASE
     N E V E R  F O R G E T !
    */
	PrecacheSound(HSB_EXPLODE,true);
}

public void OnPluginStart2()
{		
	HookEvent("arena_round_start", Event_RoundStart, EventHookMode_Pre);
	HookEvent("teamplay_round_active", Event_RoundStart, EventHookMode_PostNoCopy); // for non-arena maps
}

public Action FF2_OnAbility2(int boss, const char[] plugin_name, const char[] ability_name, int action)
{	
	
	int client=GetClientOfUserId(FF2_GetBossUserId(boss));
	
	if (!strcmp(ability_name, EXPLOSION_RAGE)) 
	{
		Rage_Explosion(ability_name, boss, client); // !!!!
	}
	
}

void Rage_Explosion(const char[] ability_name, int boss, int client)
{
	
		bRange = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, ability_name, 1);	// Range, arg1
		bDmg = FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, 2); // Damage, arg2
		DelayBeforeBoom = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, ability_name, 3, 2.0);	// Delay before boom, arg3
		static char soundFile[MAX_SOUND_FILE_LENGTH];
		ReadSound(boss, ability_name, 4, soundFile); // Sound upon activation
		if (strlen(soundFile) > 3)
		    EmitSoundToAll(soundFile);
		int StuckOrFreeDefiner = FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, 5, 1); // Stuck or free selector
		if (StuckOrFreeDefiner == 1)
		{
            StuckOrFree = 1;
            CreateTimer(0.1, SentryBustPrepare, client); // If 1, boss won't move during the ability
		}
		else if (StuckOrFreeDefiner == 0)
        {
            StuckOrFree = 0; // If 0, boss can move freely during the ability
        }
		else
        {
            PrintCenterText(client, "[SBRS] Invalid Key, you can move during explosions now");
            StuckOrFree = 0; // 0 is set by default
        }
        
		int ExpSoundToggler = FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, 6, 1); // Toggles the explosion sound
		if (ExpSoundToggler == 1)
		{
			toggleExplosionSound = 1; // If 1, plays the default sentry buster explosion sound upon exploding
		}
		else if (ExpSoundToggler == 0)
		{
			toggleExplosionSound = 0; // If 0, doesn't play it
		}
		else
		{
           PrintToServer("[SBRS] Invalid key. Explosion Sound Enabled.");
           toggleExplosionSound = 1; // 1 is set by default
		}
		CreateTimer(DelayBeforeBoom, SentryBusting, client);
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	// amogus
}

/*
     sentry busting a nut aaaaaaaaa
*/
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
	if(toggleExplosionSound == 1)
	{
	    EmitSoundToAll(HSB_EXPLODE, bClient);
	}
    else
    {
           PrintToServer(".sugoma");
    }
	AttachParticle(bClient, "fluidSmokeExpl_ring_mvm");
	SDKUnhook(bClient, SDKHook_OnTakeDamage, BlockDamage);
	if(TF2_IsPlayerInCondition(bClient, TFCond_Taunting))
	    TF2_RemoveCondition(bClient,TFCond_Taunting);
	SetEntityMoveType(bClient, MOVETYPE_WALK);
	
	if(StuckOrFree == 0)
	    PrintToServer("amogus.");
	// i did this because when i left StuckOrFree in 0 it threw a warning
	return Plugin_Continue;
}

/*
	b l o c c . 
*/
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



public Action DeleteParticle(Handle timer, int ref) // delet
{
	int Ent = EntRefToEntIndex(ref);
	if(IsValidEntity(Ent))
		RemoveEntity(Ent);
}

/*
	stacks- i mean i mean stocks
*/

stock void DoDamage(int client, int target, int amount) // Originally from Goomba Stomp
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

stock bool AttachParticle(int Ent, char[] particleType, bool cache=false) // Originally from L4D Achievement Trophy - took from shadow93_bosses
{
	int particle = CreateEntityByName("info_particle_system");
	if (!IsValidEntity(particle)) return false;
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
	CreateTimer(10.0, DeleteParticle, EntIndexToEntRef(particle));
	return true;
}

stock void ReadSound(int bossIdx, const char[] ability_name, int argInt, char soundFile[MAX_SOUND_FILE_LENGTH]) // Took from sarysapub3
{
	FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, ability_name, argInt, soundFile, MAX_SOUND_FILE_LENGTH);
	if (strlen(soundFile) > 3)
	PrecacheSound(soundFile);
}

/*
	Timers
*/

public Action SentryBustPrepare(Handle timer, any bClient)
{
	if(!TF2_IsPlayerInCondition(bClient, TFCond_Taunting))
		FakeClientCommand(bClient, "taunt");
	SetEntityMoveType(bClient, MOVETYPE_NONE);
	SDKHook(bClient, SDKHook_OnTakeDamage, BlockDamage);
}




stock bool IsValidClient(int client, bool replaycheck=true)
{
	// From Batfoxkid >///<
	
	if(client <= 0 || client > MaxClients)
		return false;

	if(!IsClientInGame(client) || !IsClientConnected(client))
		return false;

	if(GetEntProp(client, Prop_Send, "m_bIsCoaching"))
		return false;

	if(replaycheck && (IsClientSourceTV(client) || IsClientReplay(client)))
		return false;

	return true;
}