/**
* Copyright (C) 2026 LuxLuma
*
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program.  If not, see <https://www.gnu.org/licenses/>.
**/


#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <smlib>
#include <left4dhooks>

#pragma newdecls required
#pragma semicolon 1

#define HWR_VERSION "1.666"

#define FLOAT_(%1) view_as<float>(%1)
#define INT_(%1) view_as<int>(%1)
#define BOOL_(%1) view_as<bool>(%1)

#define ZOMBIECLASS_TANK 8

ConVar g_CvarWitchPose;
bool g_bWitchPose;

ConVar g_CvarWitchSoul_Max;
int g_iWitchSoul_Max = 7; //souls required to spawn greater witch

ConVar g_CvarWitchSoul_GainChance;
int g_iWitchSoul_GainChance = 2; //1 to 1000 chance each second

ConVar g_CvarWitchSoul_GainDeathChance;
int g_iWitchSoul_GainDeathChance = 20; //chance to gain witch soul for greater witch spawning

ConVar g_CvarHellMob_Spawn_Interval;
float g_flHellMob_Spawn_Interval = 12.0; //hell spawn delay between waves

ConVar g_CvarHellMob_Spawn_Interval_WitchDeath;
float g_flHellMob_Spawn_Interval_WitchDeath = 6.5; //hell spawn delay between waves

ConVar g_CvarHPDivision_For_Spawning;
int g_iHPDivision_For_Spawning = 100;

ConVar g_CvarMaxSlots_Reserve;
int g_iMaxSlots_Reserve = 4; // don't spawn anything if there are this many slots left

ConVar g_CvarAllowEscapeWitch_PortalCall;
bool g_bAllowEscapeWitch_PortalCall;

bool g_bLateLoad;


#define GREATERWITCH_PENTAGRAM_SIZE 96.0
#define GREATERWITCH_PENTAGRAM_REDRAW_INTERVAL 15.0 //no above 20~

#define HELLSPAWN_PITCH_LOWEST 55
#define HELLSPAWN_PITCH_HIGHEST 65

#define GREATERWITCH_PITCH_LOWEST 70
#define GREATERWITCH_PITCH_HIGHEST 75

#define LOWER_HELLSPAWN_SOUNDS_MAX 3


#define LOWER_HELLSPAWN_TANK_SND_1 ")player/tank/voice/attack/tank_attack_01.wav"
#define LOWER_HELLSPAWN_TANK_SND_2 ")player/tank/voice/attack/tank_attack_02.wav"
#define LOWER_HELLSPAWN_TANK_SND_3 ")player/tank/voice/attack/tank_attack_05.wav"
#define LOWER_HELLSPAWN_TANK_SND_4 ")player/tank/voice/attack/tank_attack_08.wav"
#define LOWER_HELLSPAWN_TANK_SND_5 ")player/tank/voice/die/tank_death_01.wav"
#define LOWER_HELLSPAWN_TANK_SND_6 ")player/tank/voice/growl/tank_climb_01.wav"
#define LOWER_HELLSPAWN_TANK_SND_7 ")player/tank/voice/yell/tank_yell_02.wav"
#define LOWER_HELLSPAWN_TANK_SND_8 ")player/tank/voice/pain/tank_fire_06.wav"

#define LOWER_HELLSPAWN_BOOMER_SND_1 ")player/boomer/voice/warn/male_boomer_warning_01.wav"
#define LOWER_HELLSPAWN_BOOMER_SND_2 ")player/boomer/voice/warn/male_boomer_warning_12.wav"
#define LOWER_HELLSPAWN_BOOMER_SND_3 ")player/boomer/voice/warn/male_boomer_warning_13.wav"
#define LOWER_HELLSPAWN_BOOMER_SND_4 ")player/boomer/voice/warn/male_boomer_warning_14.wav"
#define LOWER_HELLSPAWN_BOOMER_SND_5 ")player/boomer/voice/warn/male_boomer_warning_15.wav"
#define LOWER_HELLSPAWN_BOOMER_SND_6 ")player/boomer/voice/warn/male_boomer_warning_16.wav"
#define LOWER_HELLSPAWN_BOOMER_SND_7 ")player/boomer/voice/warn/male_boomer_warning_17.wav"
#define LOWER_HELLSPAWN_BOOMER_SND_8 ")player/boomer/voice/warn/female_boomer_warning_17.wav"

#define LOWER_HELLSPAWN_SMOKER_SND_1 ")player/smoker/voice/warn/smoker_warn_01.wav"
#define LOWER_HELLSPAWN_SMOKER_SND_2 ")player/smoker/voice/warn/smoker_warn_03.wav"
#define LOWER_HELLSPAWN_SMOKER_SND_3 ")player/smoker/voice/warn/smoker_warn_04.wav"
#define LOWER_HELLSPAWN_SMOKER_SND_4 ")player/smoker/voice/warn/smoker_warn_05.wav"
#define LOWER_HELLSPAWN_SMOKER_SND_5 ")player/smoker/voice/warn/smoker_warn_06.wav"

#define LOWER_HELLSPAWN_HUNTER_SND_1 ")player/hunter/voice/warn/hunter_warn_10.wav"
#define LOWER_HELLSPAWN_HUNTER_SND_2 ")player/hunter/voice/warn/hunter_warn_14.wav"
#define LOWER_HELLSPAWN_HUNTER_SND_3 ")player/hunter/voice/warn/hunter_warn_16.wav"
#define LOWER_HELLSPAWN_HUNTER_SND_4 ")player/hunter/voice/warn/hunter_warn_17.wav"
#define LOWER_HELLSPAWN_HUNTER_SND_5 ")player/hunter/voice/warn/hunter_warn_18.wav"

#define LOWER_HELLSPAWN_JOCKEY_SND_1 ")player/jockey/voice/alert/jockey_02.wav"
#define LOWER_HELLSPAWN_JOCKEY_SND_2 ")player/jockey/voice/alert/jockey_04.wav"
#define LOWER_HELLSPAWN_JOCKEY_SND_3 ")player/jockey/voice/warn/jockey_06.wav"
#define LOWER_HELLSPAWN_JOCKEY_SND_4 ")player/jockey/voice/idle/jockey_lurk03.wav"
#define LOWER_HELLSPAWN_JOCKEY_SND_5 ")player/jockey/voice/idle/jockey_lurk06.wav"

#define LOWER_HELLSPAWN_CHARGER_SND_1 ")player/charger/voice/alert/charger_alert_01.wav"
#define LOWER_HELLSPAWN_CHARGER_SND_2 ")player/charger/voice/alert/charger_alert_02.wav"
#define LOWER_HELLSPAWN_CHARGER_SND_3 ")player/charger/voice/warn/charger_warn_03.wav"
#define LOWER_HELLSPAWN_CHARGER_SND_4 ")player/charger/voice/idle/charger_spotprey_03.wav"
#define LOWER_HELLSPAWN_CHARGER_SND_5 ")player/charger/voice/attack/charger_melee01.wav"

#define LOWER_HELLSPAWN_SPITTER_SND_1 ")player/spitter/voice/idle/spitter_spotprey_01.wav"
#define LOWER_HELLSPAWN_SPITTER_SND_2 ")player/spitter/voice/idle/spitter_spotprey_02.wav"
#define LOWER_HELLSPAWN_SPITTER_SND_3 ")player/spitter/voice/idle/spitter_spotprey_03.wav"
#define LOWER_HELLSPAWN_SPITTER_SND_4 ")player/spitter/voice/idle/spitter_spotprey_04.wav"
#define LOWER_HELLSPAWN_SPITTER_SND_5 ")player/spitter/voice/idle/spitter_spotprey_05.wav"
#define LOWER_HELLSPAWN_SPITTER_SND_6 ")player/spitter/voice/idle/spitter_spotprey_06.wav"

#define HELLWITCH_DEATHSOUND_MAX 1
#define HELLWITCH_DEATHSOUND_FAR_MAX 2

#define HELLWITCH_DEATHSOUND_1 ")npc/witch/voice/die/female_death_1.wav"

#define HELLWITCH_DEATHSOUND_FARAWAY ")npc/witch/voice/attack/female_distantscream1.wav"
#define HELLWITCH_DEATHSOUND_FARAWAY_DIST 1000.0
#define HELLWITCH_ESCAPE_PORTAL_CALL_VOL 3


#define GREATER_ELECTRIC_EFFECT_MIN 0.2
#define GREATER_ELECTRIC_EFFECT_MAX 0.5
#define GREATER_WITCH_DEATH_VOL 4
#define GREATER_WITCH_DEATH_SND ")npc/witch/voice/die/female_death_1.wav"

#define HELLPORTAL_EMERGE_RANGE 1800.0
#define HELLPORTAL_EMERGE_BANG_VOL 4
#define HELLPORTAL_EMERGE_BANG ")player/footsteps/tank/walk/tank_walk01.wav"
#define HELLPORTAL_EMERGE_BANG_PARTICLE "tank_survivor_pound"
#define HELLPORTAL_ROCK_DEBRIS "models/props_debris/concrete_chunk08a.mdl"

#define HELLPORTAL_EMERGE_DELAY 8.0
#define HELLPORTAL_EMERGE_VOL 2
#define HELLPORTAL_EMERGE_SND ")ambient/explosions/explode_1.wav"
#define HELLPORTAL_EMERGE_SND_2 ")animation/plane_dist_explosion.wav" //l4d2 only
#define HELLPORTAL_EMERGE_PARTICLE "gas_explosion_l"
#define HELLPORTAL_AFTERDUST_PARTICLE "pillardust"

#define HELLPORTAL_CLOSE_VOL 3
#define HELLPORTAL_CLOSE_SND ")player/tank/attack/rip_up_rock_1.wav"
#define HELLPORTAL_CLOSE_SHAKEAMP 5.0
#define HELLPORTAL_CLOSE_SHAKE 60.0
#define HELLPORTAL_CLOSE_SHAKERANGE 800.0

#define HELLPORTAL_AMBIANT_DELAY 2.0

#define HELLPORTAL_IDLE_VOL 2
#define HELLPORTAL_DEMONS_INTERVAL 3.5 //portal ambiant growls and fire delay

#define HELLPORTAL_FIRE "fire_large_01"

char g_sDemonsSounds[][] = 
{
	")npc/infected/alert/becomeenraged/alert24.wav", 
	")npc/infected/alert/becomeenraged/become_enraged01.wav", 
	")npc/infected/alert/becomeenraged/become_enraged02.wav", 
	")npc/infected/alert/becomeenraged/become_enraged03.wav", 
	")npc/infected/alert/becomeenraged/become_enraged06.wav", 
	")npc/infected/alert/becomeenraged/become_enraged07.wav", 
	")npc/infected/alert/becomeenraged/become_enraged09.wav", 
	")npc/infected/alert/becomeenraged/become_enraged10.wav", 
	")npc/infected/alert/becomeenraged/become_enraged11.wav", 
	")npc/infected/alert/becomeenraged/become_enraged30.wav", 
	")npc/infected/alert/becomeenraged/become_enraged50.wav", 
	")npc/infected/alert/becomeenraged/become_enraged51.wav", 
	")npc/infected/alert/becomeenraged/become_enraged52.wav", 
	")npc/infected/alert/becomeenraged/become_enraged53.wav", 
	")npc/infected/alert/becomeenraged/become_enraged54.wav", 
	")npc/infected/alert/becomeenraged/become_enraged55.wav", 
	")npc/infected/alert/becomeenraged/become_enraged56.wav", 
	")npc/infected/alert/becomeenraged/become_enraged57.wav", 
	")npc/infected/alert/becomeenraged/become_enraged58.wav"
};
int g_DemonsSoundSize = sizeof(g_sDemonsSounds);



ConVar g_CvarHellPortal_Timeout;
float g_flHellPortal_Timeout = 75.0;

ConVar g_CvarHellPortal_Delay_Spawn;
float g_flHellPortal_Delay_Spawn = 20.0;

ConVar g_CvarHellPortal_Commons_Max;
int g_iHellPortal_Commons_Max = 300;

ConVar g_CvarHellPortal_Commons_Max_Exist;
int g_iHellPortal_Commons_Max_Exist = 40;

ConVar g_CvarHellPortal_Common_Spawn_Interval;
float g_flHellPortal_Common_Spawn_Interval = 0.1;

ConVar g_CvarHellPortal_Wave_Spawn_Interval;
float g_flHellPortal_Wave_Spawn_Interval = 2.5;

ConVar g_CvarHellPortal_Tanks_Max;
int g_iHellPortal_Tanks_Max = 5;

ConVar g_CvarHellPortal_Chargers_Max;
int g_iHellPortal_Chargers_Max = 6;

ConVar g_CvarHellPortal_Smokers_Max;
int g_iHellPortal_Smokers_Max = 6;

ConVar g_CvarHellPortal_Hunters_Max;
int g_iHellPortal_Hunters_Max = 8;

ConVar g_CvarHellPortal_Boomers_Max;
int g_iHellPortal_Boomers_Max = 5;

ConVar g_CvarHellPortal_Jockeys_Max;
int g_iHellPortal_Jockeys_Max = 4;

ConVar g_CvarHellPortal_Witches_Max;
int g_iHellPortal_Witches_Max = 1;

ConVar g_CvarHellPortal_Spitters_Max;
int g_iHellPortal_Spitters_Max;

ConVar g_CvarWaveSpawn_Ignore_Multiply;
bool g_bWaveSpawn_Ignore_Multiply;

ConVar g_CvarWaveSpawn_HP_Multiply_Tanks;
float g_flWaveSpawn_HP_Multiply_Tanks;

ConVar g_CvarWaveSpawn_HP_Multiply_Chargers;
float g_flWaveSpawn_HP_Multiply_Chargers;

ConVar g_CvarWaveSpawn_HP_Multiply_Smokers;
float g_flWaveSpawn_HP_Multiply_Smokers;

ConVar g_CvarWaveSpawn_HP_Multiply_Hunters;
float g_flWaveSpawn_HP_Multiply_Hunters;

ConVar g_CvarWaveSpawn_HP_Multiply_Boomers;
float g_flWaveSpawn_HP_Multiply_Boomers;

ConVar g_CvarWaveSpawn_HP_Multiply_Jockeys;
float g_flWaveSpawn_HP_Multiply_Jockeys;

ConVar g_CvarWaveSpawn_HP_Multiply_Witches;
float g_flWaveSpawn_HP_Multiply_Witches;

ConVar g_CvarWaveSpawn_HP_Multiply_Spitters;
float g_flWaveSpawn_HP_Multiply_Spitters;

ConVar g_CvarHellMob_ImmuneToBurn;
bool g_bHellMob_ImmuneToBurn;

ConVar g_CvarHellWave_Tanks_Max;
int g_iHellWave_Tanks_Max;
ConVar g_CvarHellWave_Chargers_Max;
int g_iHellWave_Chargers_Max;
ConVar g_CvarHellWave_Smokers_Max;
int g_iHellWave_Smokers_Max;
ConVar g_CvarHellWave_Hunters_Max;
int g_iHellWave_Hunters_Max;
ConVar g_CvarHellWave_Boomers_Max;
int g_iHellWave_Boomers_Max;
ConVar g_CvarHellWave_Jockeys_Max;
int g_iHellWave_Jockeys_Max;
ConVar g_CvarHellWave_Spitters_Max;
int g_iHellWave_Spitters_Max;
ConVar g_CvarHellWave_Witches_Max;
int g_iHellWave_Witches_Max;


char g_sGreaterElectric[][] = 
{
	"ambient/energy/spark5.wav", 
	"ambient/energy/spark6.wav", 
	"ambient/energy/zap1.wav", 
	"ambient/energy/zap2.wav", 
	"ambient/energy/zap3.wav", 
};
int g_GreaterElectricSize = sizeof(g_sGreaterElectric);

char g_sOneShotDeathCry[][] = 
{
	"npc/witch/voice/die/headshot_death_1.wav", 
	"npc/witch/voice/die/headshot_death_2.wav", 
	"npc/witch/voice/die/headshot_death_3.wav"
};
int g_OneShotDeathCrySize = sizeof(g_sOneShotDeathCry);

int g_iWitchSouls;

int g_DebrisModel;

ArrayList g_PentaGramLineArt;

ArrayList g_HellSpawnQueue;
float g_flNextHellSpawnMob;
bool g_bCatchSpawning;
bool g_bDidAnythingSpawn;
float g_vecSpawnOriginHack[3];
bool g_bPortalSpawning;
int g_iHellPortalSpawnAmount;
int g_iWitchTargetIndex = 1;
float g_flWitchTargetNextTargetTime;

ConVar g_CvarTimeOfDay;
int g_iTimeOfDay;
bool g_bIgnoreTimeOfDayChange;
float g_flRevertTimeOfDayChange;

ConVar g_CvarNB_Update_Interval;
float g_flMinUpdate_TimeCvar;

int g_LaserSprite;

int g_PentagamFires;
int g_HellEmbers;
int g_Electrics;

int g_SpawnFireBall;

int g_BangParticle;
int g_EmergeParticle;
int g_AfterDustParticle;
//int g_HellFireParticle;


ConVar g_CvarCommonLimit;
int g_iCommonLimit = 100;


float g_flTickInterval;
bool g_bMapRunning;

enum ZombieSpawns
{
	ZombieSpawns_None = 0, 
	ZombieSpawns_Smoker, 
	ZombieSpawns_Boomer, 
	ZombieSpawns_Hunter, 
	ZombieSpawns_Jockey, 
	ZombieSpawns_Charger, 
	ZombieSpawns_Spitter, 
	ZombieSpawns_Tank, 
	ZombieSpawns_Witch, 
	ZombieSpawns_Max, 
}

enum struct HellSpawnWitch
{
	int m_iEntIndex;
	int m_iEntRef;
	
	bool m_bGreaterHellWitch;
	bool m_bHellSpawn;
	int m_iPitch;
	float m_flNextElectricTime;
	bool m_bNonSpecialWitch;
	bool m_bWasKilled;
	bool m_bWasStartled;
	
	bool SetupHellCry(bool bDidOneShot)
	{
		if (!this.IsValidWitch())
			return false;
		
		this.m_bWasKilled = true;
		
		float vecOrigin[3];
		GetAbsOrigin(this.m_iEntIndex, vecOrigin, true);
		
		if (bDidOneShot || this.m_bNonSpecialWitch)
		{
			EmitSoundToAll(g_sOneShotDeathCry[GetRandomInt(0, g_OneShotDeathCrySize)], SOUND_FROM_WORLD, SNDCHAN_STATIC, 100, _, _, this.m_iPitch, _, vecOrigin);
			return false;
		}
		
		if (this.m_bGreaterHellWitch)
		{
			for (int i; i < GREATER_WITCH_DEATH_VOL; ++i)
			{
				EmitSoundToAll(GREATER_WITCH_DEATH_SND, SOUND_FROM_WORLD, SNDCHAN_STATIC, 140, _, _, 25, _, vecOrigin);
			}
			this.StopAllEffects();
			return true;
		}
		else
		{
			if (GetRandomInt(1, 100) <= g_iWitchSoul_GainDeathChance)
			{
				++g_iWitchSouls;
				DataPack dp;
				CreateDataTimer(4.0, SoulQueueDeath, dp, TIMER_FLAG_NO_MAPCHANGE);
				dp.WriteFloat(vecOrigin[0]);
				dp.WriteFloat(vecOrigin[1]);
				dp.WriteFloat(vecOrigin[2]);
			}
			
			g_flNextHellSpawnMob = GetGameTime() + g_flHellMob_Spawn_Interval_WitchDeath;
			EmitWitchDeath_SFK(vecOrigin);
			AlertAllCommons();
			
			ZombieSpawns random = this.PickRandomSpecial();
			if (random == ZombieSpawns_None)
				return false;
			
			g_HellSpawnQueue.Push(INT_(random));
		}
		return false;
	}
	bool IsValidWitch()
	{
		return IsValidEntRef(this.m_iEntRef);
	}
	bool IsGreaterWitch()
	{
		return (this.IsValidWitch() && this.m_bGreaterHellWitch);
	}
	bool IsNonSpecialWitch()
	{
		return (this.IsValidWitch() && this.m_bNonSpecialWitch);
	}
	void DeleteWitch()
	{
		if (this.IsValidWitch())
		{
			RemoveEntity(this.m_iEntRef);
			this.StopAllEffects();
		}
	}
	void StopAllEffects()
	{
		TE_SetupStopAllParticles(this.m_iEntIndex);
		TE_SendToAll();
	}
	void InitWitch(bool bNonSpecialWitch = false)
	{
		this.m_iEntRef = EntIndexToEntRef(this.m_iEntIndex);
		this.m_bGreaterHellWitch = false;
		this.m_bNonSpecialWitch = false;
		this.m_bWasKilled = false;
		this.m_bWasStartled = false;
		
		if (bNonSpecialWitch)
		{
			this.m_bNonSpecialWitch = true;
			this.m_iPitch = GetRandomInt(GREATERWITCH_PITCH_LOWEST, GREATERWITCH_PITCH_HIGHEST);
			SDKHook(this.m_iEntRef, SDKHook_OnTakeDamage, ConvertFireDamage);
			CreateTimer(0.1, TriggerWitchAttack, this.m_iEntRef, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
			this.ForceSittingWitch(true);
			return;
		}
		
		if (g_iWitchSouls >= g_iWitchSoul_Max)
		{
			g_iWitchSouls -= g_iWitchSoul_Max;
			if (g_iWitchSouls < 0)
				g_iWitchSouls = 0;
			
			this.ForceSittingWitch(true);
			this.GreaterSpawning();
		}
	}
	void GreaterSpawning()
	{
		this.m_bGreaterHellWitch = true;
		this.m_iPitch = GetRandomInt(GREATERWITCH_PITCH_LOWEST, GREATERWITCH_PITCH_HIGHEST);
		this.m_flNextElectricTime = GetGameTime() + GetRandomFloat(GREATER_ELECTRIC_EFFECT_MIN, GREATER_ELECTRIC_EFFECT_MAX);
		
		//pentagram no idea if there is a right way
		//TODO 360 / 5 = 72 -> 5 points of a star
		float vecOrigin[3];
		float vecAnges[3];
		float vecPentagramPoints[5][3];
		GetAbsOrigin(this.m_iEntIndex, vecOrigin, false);
		
		for (int i; i < 5; ++i)
		{
			OriginMove(vecOrigin, vecAnges, vecPentagramPoints[i], GREATERWITCH_PENTAGRAM_SIZE);
			vecAnges[1] += 72.0;
		}
		
		//it is what it is pentagrams are only 5 points
		
		int index = g_PentaGramLineArt.Push(GetGameTime() + 1.0);
		this.PentagramQueueLines(index, vecPentagramPoints[0], vecPentagramPoints[2], 0);
		this.PentagramQueueLines(index, vecPentagramPoints[2], vecPentagramPoints[4], 1);
		this.PentagramQueueLines(index, vecPentagramPoints[4], vecPentagramPoints[1], 2);
		this.PentagramQueueLines(index, vecPentagramPoints[1], vecPentagramPoints[3], 3);
		this.PentagramQueueLines(index, vecPentagramPoints[3], vecPentagramPoints[0], 4);
		
		TE_SetupParticleFollowEntity(g_HellEmbers, this.m_iEntIndex);
		TE_SendToAll();
		
		for (int i; i < 5; ++i) //trickle the fires down netchan 
		{
			TE_SetupParticle(g_PentagamFires, vecPentagramPoints[i]);
			TE_SendToAll((g_flTickInterval * i) + 1);
		}
		
		SDKHook(this.m_iEntIndex, SDKHook_Think, GreaterElectric);
		SDKHook(this.m_iEntRef, SDKHook_OnTakeDamage, ConvertFireDamage);
	}
	void PentagramQueueLines(int index, float vecStart[3], float vecEnd[3], int iLineCount)
	{
		g_PentaGramLineArt.Set(index, vecStart[0], 1 + (6 * iLineCount));
		g_PentaGramLineArt.Set(index, vecStart[1], 2 + (6 * iLineCount));
		g_PentaGramLineArt.Set(index, vecStart[2], 3 + (6 * iLineCount));
		
		g_PentaGramLineArt.Set(index, vecEnd[0], 4 + (6 * iLineCount));
		g_PentaGramLineArt.Set(index, vecEnd[1], 5 + (6 * iLineCount));
		g_PentaGramLineArt.Set(index, vecEnd[2], 6 + (6 * iLineCount));
	}
	void DoGreaterWitchEffects()
	{
		float flTime = GetGameTime();
		if (this.m_flNextElectricTime > flTime)
			return;
		
		float vecOrigin[3];
		GetAbsOrigin(this.m_iEntIndex, vecOrigin, true);
		TE_SetupParticle_ControlPoints(g_Electrics, this.m_iEntIndex, vecOrigin);
		TE_SendToAllInRange(vecOrigin, RangeType_Visibility);
		TE_SetupDynamicLight(vecOrigin, view_as<int>( { 0, 200, 200 } ), 75.0, 0.3, 0.1, 3);
		TE_SendToAllInRange(vecOrigin, RangeType_Visibility);
		
		EmitSoundToAll(g_sGreaterElectric[GetRandomInt(0, g_GreaterElectricSize)], this.m_iEntIndex, SNDCHAN_STATIC, 70, _, _, 200);
		
		this.m_flNextElectricTime = flTime + GetRandomFloat(GREATER_ELECTRIC_EFFECT_MIN, GREATER_ELECTRIC_EFFECT_MAX);
	}
	void ForceSittingWitch(bool bHookThink)
	{
		g_bIgnoreTimeOfDayChange = true;
		g_CvarTimeOfDay.SetInt(0);
		g_bIgnoreTimeOfDayChange = false;
		g_flRevertTimeOfDayChange = GetGameTime() + g_flMinUpdate_TimeCvar;
		if (bHookThink)
		{
			SDKHook(this.m_iEntRef, SDKHook_ThinkPost, TimeOfDayRevert);
		}
	}
	ZombieSpawns PickRandomSpecial()
	{
		int MaxRetry;
		ZombieSpawns SpawnType = ZombieSpawns_None;
		while (SpawnType == ZombieSpawns_None)
		{
			++MaxRetry;
			
			SpawnType = view_as<ZombieSpawns>(GetRandomInt(INT_(ZombieSpawns_Smoker), INT_(ZombieSpawns_Witch)));
			switch (SpawnType)
			{
				case ZombieSpawns_Smoker:
				{
					if (g_iHellWave_Smokers_Max < 1)
					{
						SpawnType = ZombieSpawns_None;
					}
				}
				case ZombieSpawns_Boomer:
				{
					if (g_iHellWave_Boomers_Max < 1)
					{
						SpawnType = ZombieSpawns_None;
					}
				}
				case ZombieSpawns_Hunter:
				{
					if (g_iHellWave_Hunters_Max < 1)
					{
						SpawnType = ZombieSpawns_None;
					}
				}
				case ZombieSpawns_Jockey:
				{
					if (g_iHellWave_Jockeys_Max < 1)
					{
						SpawnType = ZombieSpawns_None;
					}
				}
				case ZombieSpawns_Charger:
				{
					if (g_iHellWave_Chargers_Max < 1)
					{
						SpawnType = ZombieSpawns_None;
					}
				}
				case ZombieSpawns_Tank:
				{
					if (g_iHellWave_Tanks_Max < 1)
					{
						SpawnType = ZombieSpawns_None;
					}
				}
				case ZombieSpawns_Witch:
				{
					if (g_iHellWave_Witches_Max < 1)
					{
						SpawnType = ZombieSpawns_None;
					}
				}
				case ZombieSpawns_Spitter:
				{
					if (g_iHellWave_Spitters_Max < 1)
					{
						SpawnType = ZombieSpawns_None;
					}
				}
			}
			
			if (SpawnType != ZombieSpawns_None || MaxRetry >= 500)
			{
				return SpawnType;
			}
		}
		return SpawnType;
	}
}

enum struct HellPortal
{
	int m_iEntIndex;
	int m_iEntRef;
	float m_flLifetime;
	float m_vecOrigin[3];
	
	int m_iTanks;
	int m_iChargers;
	int m_iHunters;
	int m_iJockeys;
	int m_iSmokers;
	int m_iBoomers;
	int m_iCommons;
	int m_iWitches;
	int m_iSpitters;
	
	float m_flNextCommonSpawn;
	float m_flNextWaveSpawn;
	
	float m_flHellKnocking_time_1;
	float m_flHellKnocking_time_2;
	float m_flEmergeDelay;
	
	float m_flAmbientHell;
	
	bool PortalLogic()
	{
		if (this.m_flLifetime < GetGameTime() || !this.CanAnythingSpawn())
		{
			this.DeletePortal();
			return false;
		}
		this.PortalSpawn();
		this.PortalAmbientEffects();
		return true;
	}
	void PortalAmbientEffects()
	{
		float flTime = GetGameTime();
		
		if (this.m_flEmergeDelay < flTime)
		{
			this.m_flEmergeDelay = flTime + (g_flHellPortal_Timeout * 2);
			for (int i; i < HELLPORTAL_EMERGE_VOL; ++i)
			{
				EmitSoundToAll(HELLPORTAL_EMERGE_SND, this.m_iEntIndex, SNDCHAN_STATIC, 120, _, _, 60);
				
			}
			for (int i; i < HELLPORTAL_EMERGE_VOL; ++i)
			{
				EmitSoundToAll(HELLPORTAL_EMERGE_SND_2, this.m_iEntIndex, SNDCHAN_STATIC, 140, _, _, 50);
			}
			
			this.m_flAmbientHell = flTime + HELLPORTAL_AMBIANT_DELAY;
			TE_SetupParticleFollowEntity(g_EmergeParticle, this.m_iEntIndex);
			TE_SendToAll();
			ShakeClientScreenAll(this.m_vecOrigin, HELLPORTAL_EMERGE_RANGE, 5.0, 120.0, 3.0);
			
			float vecOrigin[3];
			vecOrigin = this.m_vecOrigin;
			vecOrigin[2] -= 20.0;
			
			PhysicsExplode(vecOrigin, 100, HELLPORTAL_EMERGE_RANGE * 0.5, true, HELLPORTAL_EMERGE_RANGE * 0.25);
			TE_SetupExplodeForce(this.m_vecOrigin, HELLPORTAL_EMERGE_RANGE, 100.0);
			TE_SendToAllInRange(this.m_vecOrigin, RangeType_Visibility);
			
			TE_SetupBreakModel(this.m_vecOrigin, _, _, g_DebrisModel, 300, 30, g_flHellPortal_Timeout * 2);
			TE_SendToAll(0.5);
			
			this.HellPortal_Hint();
		}
		if (this.m_flAmbientHell < flTime)
		{
			int iAmbiantSND = GetRandomInt(0, g_DemonsSoundSize);
			for (int i; i < HELLPORTAL_IDLE_VOL; ++i)
			{
				EmitSoundToAll(g_sDemonsSounds[iAmbiantSND], this.m_iEntIndex, SNDCHAN_STATIC, 90, _, _, 25);
			}
			this.m_flAmbientHell = flTime + HELLPORTAL_DEMONS_INTERVAL;
			//TE_SetupStopAllParticles(this.m_iEntIndex);
			//TE_SendToAll();
			AcceptEntityInput(this.m_iEntIndex, "Start"); //saves me the hassle of having to send tempent to clients who join late
			
		}
		if (this.m_flHellKnocking_time_1 < flTime)
		{
			this.m_flHellKnocking_time_1 = flTime + (g_flHellPortal_Timeout * 2);
			this.FloorBang();
			TE_SetupExplodeForce(this.m_vecOrigin, 300.0, 100.0);
			TE_SendToAllInRange(this.m_vecOrigin, RangeType_Visibility);
		}
		if (this.m_flHellKnocking_time_2 < flTime)
		{
			this.m_flHellKnocking_time_2 = flTime + (g_flHellPortal_Timeout * 2);
			this.FloorBang();
			TE_SetupExplodeForce(this.m_vecOrigin, 300.0, 100.0);
			TE_SendToAllInRange(this.m_vecOrigin, RangeType_Visibility);
		}
		
	}
	void FloorBang(bool debris = false)
	{
		for (int i; i < HELLPORTAL_EMERGE_BANG_VOL; ++i)
		{
			EmitSoundToAll(HELLPORTAL_EMERGE_BANG, this.m_iEntIndex, SNDCHAN_STATIC, 100, _, _, 50);
		}
		
		TE_SetupParticleFollowEntity(g_BangParticle, this.m_iEntIndex);
		TE_SendToAllInRange(this.m_vecOrigin, RangeType_Visibility);
		ShakeClientScreenAll(this.m_vecOrigin, 400.0, 7.0, 70.0, 2.0);
		
		float vecOrigin[3];
		vecOrigin = this.m_vecOrigin;
		vecOrigin[2] -= 20.0;
		
		PhysicsExplode(vecOrigin, 300, 30.0);
		// don't uncomment this if you don't want clients to have cpu benchmark 
		//TE_SetupExplodeForce(this.m_vecOrigin, 300.0, 100.0);
		//TE_SendToAllInRange(this.m_vecOrigin, RangeType_Visibility);
		
		if (debris)
		{
			TE_SetupBreakModel(this.m_vecOrigin, _, _, g_DebrisModel, 300, 30, 60.0);
			TE_SendToAll();
		}
	}
	void PortalSpawn()
	{
		float flTime = GetGameTime();
		g_bPortalSpawning = true;
		if (this.m_flNextWaveSpawn < flTime && this.AnySpecialsLeft())
		{
			ZombieSpawns SpawnType = this.PickRandomSpecial();
			if (SpawnType != ZombieSpawns_None && SpawnPortalMob(SpawnType, this.m_iEntIndex))
			{
				
				this.m_flNextWaveSpawn = flTime + g_flHellPortal_Wave_Spawn_Interval;
				this.RemoveSpawnTickets(SpawnType);
				
				TE_SetupParticle(g_SpawnFireBall, this.m_vecOrigin);
				TE_SendToAllInRange(this.m_vecOrigin, RangeType_Visibility);
				this.FloorBang();
			}
		}
		if (this.m_flNextCommonSpawn < flTime && this.AnyCommonsLeft())
		{
			this.m_flAmbientHell = flTime + HELLPORTAL_DEMONS_INTERVAL; //save some sound channels
			if (this.CanAnyPortalCommonsSpawn())
			{
				--this.m_iCommons;
				g_bCatchSpawning = true;
				this.SpawnCommon();
				g_bCatchSpawning = false;
			}
			this.m_flNextCommonSpawn = flTime + g_flHellPortal_Common_Spawn_Interval;
		}
		
		g_bPortalSpawning = false;
	}
	void HellPortal_Hint()
	{
		char buf[32];
		
		FormatEx(buf, sizeof(buf), "HellPortal_%i", this.m_iEntIndex);
		int entity = CreateEntityByName("env_instructor_hint");
		TeleportEntity(entity, this.m_vecOrigin, NULL_VECTOR, NULL_VECTOR);
		
		DispatchKeyValue(this.m_iEntIndex, "targetname", buf);
		DispatchKeyValue(entity, "hint_target", buf);
		
		FormatEx(buf, sizeof(buf), "%f", g_flHellPortal_Delay_Spawn);
		DispatchKeyValue(entity, "hint_timeout", buf);
		DispatchKeyValue(entity, "hint_range", "99999.0");
		DispatchKeyValue(entity, "hint_icon_onscreen", "icon_skull");
		DispatchKeyValue(entity, "hint_caption", "Hell Portal prepare!");
		DispatchKeyValue(entity, "hint_color", "175 100 175");
		DispatchKeyValue(entity, "hint_nooffscreen", "0");
		DispatchKeyValue(entity, "hint_allow_nodraw_target", "1");
		DispatchKeyValue(entity, "hint_forcecaption", "1");
		DispatchSpawn(entity);
		AcceptEntityInput(entity, "ShowHint");
		
		FormatEx(buf, sizeof(buf), "OnUser1 !self:Kill::%f:-1", g_flHellPortal_Delay_Spawn);
		SetVariantString(buf);
		AcceptEntityInput(entity, "AddOutput");
		AcceptEntityInput(entity, "FireUser1");
	}
	void InitPortal(float vecOrigin[3])
	{
		float flTime = GetGameTime();
		this.m_iEntRef = EntIndexToEntRef(this.m_iEntIndex);
		this.m_flLifetime = flTime + g_flHellPortal_Timeout + g_flHellPortal_Delay_Spawn;
		this.m_vecOrigin = vecOrigin;
		
		this.m_iTanks = g_iHellPortal_Tanks_Max;
		this.m_iChargers = g_iHellPortal_Chargers_Max;
		this.m_iHunters = g_iHellPortal_Hunters_Max;
		this.m_iJockeys = g_iHellPortal_Jockeys_Max;
		this.m_iSmokers = g_iHellPortal_Smokers_Max;
		this.m_iBoomers = g_iHellPortal_Boomers_Max;
		this.m_iCommons = g_iHellPortal_Commons_Max;
		this.m_iWitches = g_iHellPortal_Witches_Max;
		this.m_iSpitters = g_iHellPortal_Spitters_Max;
		
		
		this.m_flNextCommonSpawn = flTime + g_flHellPortal_Delay_Spawn + g_flHellPortal_Common_Spawn_Interval;
		this.m_flNextWaveSpawn = flTime + g_flHellPortal_Delay_Spawn + g_flHellPortal_Wave_Spawn_Interval;
		
		this.m_flHellKnocking_time_1 = flTime + (HELLPORTAL_EMERGE_DELAY - 2.0);
		this.m_flHellKnocking_time_2 = flTime + (HELLPORTAL_EMERGE_DELAY - 1.0);
		
		this.m_flEmergeDelay = flTime + HELLPORTAL_EMERGE_DELAY;
		
		this.m_flAmbientHell = flTime + g_flHellPortal_Delay_Spawn;
		
		RequestFrame(HellPortalLogic, this.m_iEntRef);
	}
	bool CanAnythingSpawn()
	{
		return (this.AnySpecialsLeft() || this.AnyCommonsLeft());
	}
	bool AnySpecialsLeft()
	{
		if (this.m_iTanks > 0 || 
			this.m_iChargers > 0 || 
			this.m_iHunters > 0 || 
			this.m_iJockeys > 0 || 
			this.m_iSmokers > 0 || 
			this.m_iBoomers > 0 || 
			this.m_iWitches > 0 || 
			this.m_iSpitters)
		{
			return true;
		}
		return false;
	}
	bool AnyCommonsLeft()
	{
		return this.m_iCommons > 0;
	}
	bool CanAnyPortalCommonsSpawn()
	{
		return (GetAllPortalSpawnedCommons() < g_iHellPortal_Commons_Max_Exist);
	}
	void SpawnCommon()
	{
		int iEntity = CreateEntityByName("infected");
		
		TeleportEntity(iEntity, this.m_vecOrigin, NULL_VECTOR, NULL_VECTOR);
		
		DispatchSpawn(iEntity);
		ActivateEntity(iEntity);
		
		SetEntProp(iEntity, Prop_Send, "m_mobRush", 1);
		
		SDKHook(iEntity, SDKHook_OnTakeDamage, ConvertFireDamage);
	}
	ZombieSpawns PickRandomSpecial()
	{
		int MaxRetry;
		ZombieSpawns SpawnType = ZombieSpawns_None;
		while (SpawnType == ZombieSpawns_None)
		{
			++MaxRetry;
			
			SpawnType = view_as<ZombieSpawns>(GetRandomInt(INT_(ZombieSpawns_Smoker), INT_(ZombieSpawns_Witch)));
			switch (SpawnType)
			{
				case ZombieSpawns_Smoker:
				{
					if (this.m_iSmokers < 1)
					{
						SpawnType = ZombieSpawns_None;
					}
				}
				case ZombieSpawns_Boomer:
				{
					if (this.m_iBoomers < 1)
					{
						SpawnType = ZombieSpawns_None;
					}
				}
				case ZombieSpawns_Hunter:
				{
					if (this.m_iHunters < 1)
					{
						SpawnType = ZombieSpawns_None;
					}
				}
				case ZombieSpawns_Jockey:
				{
					if (this.m_iJockeys < 1)
					{
						SpawnType = ZombieSpawns_None;
					}
				}
				case ZombieSpawns_Charger:
				{
					if (this.m_iChargers < 1)
					{
						SpawnType = ZombieSpawns_None;
					}
				}
				case ZombieSpawns_Tank:
				{
					if (this.m_iTanks < 1)
					{
						SpawnType = ZombieSpawns_None;
					}
				}
				case ZombieSpawns_Witch:
				{
					if (this.m_iWitches < 1)
					{
						SpawnType = ZombieSpawns_None;
					}
				}
				case ZombieSpawns_Spitter:
				{
					if (this.m_iSpitters < 1)
					{
						SpawnType = ZombieSpawns_None;
					}
				}
			}
			
			if (SpawnType != ZombieSpawns_None || MaxRetry >= 500)
			{
				return SpawnType;
			}
		}
		return SpawnType;
	}
	void RemoveSpawnTickets(ZombieSpawns SpawnType)
	{
		switch (SpawnType)
		{
			case ZombieSpawns_Smoker:
			{
				this.m_iSmokers -= g_iHellPortalSpawnAmount;
			}
			case ZombieSpawns_Boomer:
			{
				this.m_iBoomers -= g_iHellPortalSpawnAmount;
			}
			case ZombieSpawns_Hunter:
			{
				this.m_iHunters -= g_iHellPortalSpawnAmount;
			}
			case ZombieSpawns_Jockey:
			{
				this.m_iJockeys -= g_iHellPortalSpawnAmount;
			}
			case ZombieSpawns_Charger:
			{
				this.m_iChargers -= g_iHellPortalSpawnAmount;
			}
			case ZombieSpawns_Tank:
			{
				this.m_iTanks -= g_iHellPortalSpawnAmount;
			}
			case ZombieSpawns_Witch:
			{
				this.m_iWitches -= g_iHellPortalSpawnAmount;
			}
			case ZombieSpawns_Spitter:
			{
				this.m_iSpitters -= g_iHellPortalSpawnAmount;
			}
		}
	}
	void DeletePortal()
	{
		if (this.IsValidPortal())
		{
			for (int i; i < HELLPORTAL_CLOSE_VOL; ++i)
			{
				EmitSoundToAll(HELLPORTAL_CLOSE_SND, SOUND_FROM_WORLD, SNDCHAN_STATIC, SNDLEVEL_GUNFIRE, _, _, 25, _, this.m_vecOrigin);
			}
			
			for (int i = 1; i <= 10; ++i)
			{
				TE_SetupParticle(g_BangParticle, this.m_vecOrigin);
				TE_SendToAll(1.0 * i);
			}
			TE_SetupParticle(g_AfterDustParticle, this.m_vecOrigin);
			TE_SendToAll(7.5);
			
			
			for (int i = 1; i <= MaxClients; ++i)
			{
				if (!IsClientInGame(i) || IsFakeClient(i))
					continue;
				
				ShakeClientScreen(i, this.m_vecOrigin, HELLPORTAL_CLOSE_SHAKERANGE, HELLPORTAL_CLOSE_SHAKEAMP, HELLPORTAL_CLOSE_SHAKE, 5.0);
			}
			
			TE_SetupStopAllParticles(this.m_iEntIndex);
			TE_SendToAll();
			RemoveEntity(this.m_iEntIndex);
		}
	}
	bool IsValidPortal()
	{
		return IsValidEntRef(this.m_iEntRef);
	}
}

enum struct HellSpawn
{
	int m_client;
	int m_iUserID;
	int m_iPitch;
	
	bool m_bConvertFireHooked;
	
	bool m_bIsPortalSpawn;
	
	void InitHellSpawn(bool IsPortalSpawn = false)
	{
		this.m_iUserID = GetClientUserId(this.m_client);
		this.m_iPitch = GetRandomInt(HELLSPAWN_PITCH_LOWEST, HELLSPAWN_PITCH_HIGHEST);
		this.m_bConvertFireHooked = SDKHookEx(this.m_client, SDKHook_OnTakeDamage, ConvertFireDamage);
		this.m_bIsPortalSpawn = IsPortalSpawn;
	}
	void ClearHellSpawnData()
	{
		this.m_iPitch = 100;
		this.m_bIsPortalSpawn = false;
		
		if (this.m_bConvertFireHooked)
		{
			this.m_bConvertFireHooked = false;
			SDKUnhook(this.m_client, SDKHook_OnTakeDamage, ConvertFireDamage);
		}
		
		
	}
	bool IsHellSpawn()
	{
		if (this.m_client == GetClientOfUserId(this.m_iUserID))
		{
			return true;
		}
		return false;
	}
}

enum struct HellSpawnCommon
{
	int m_iEntIndex;
	int m_iEntRef;
	int m_iPitch;
	
	bool m_bIsPortalSpawn;
	
	void InitHellSpawn(bool IsPortalSpawn = false)
	{
		this.m_iEntRef = EntIndexToEntRef(this.m_iEntIndex);
		this.m_iPitch = GetRandomInt(HELLSPAWN_PITCH_LOWEST, HELLSPAWN_PITCH_HIGHEST);
		this.m_bIsPortalSpawn = IsPortalSpawn;
	}
	void ClearHellSpawnData()
	{
		this.m_iPitch = 100;
		this.m_bIsPortalSpawn = false;
	}
	bool IsPortalSpawn()
	{
		if (this.IsHellSpawn())
		{
			return this.m_bIsPortalSpawn;
		}
		return false;
	}
	bool IsHellSpawn()
	{
		return IsValidEntRef(this.m_iEntRef);
	}
}

HellSpawnWitch g_HellSpawnWitch[2048 + 1];
HellSpawnCommon g_HellSpawnCommon[2048 + 1];
HellSpawn g_HellSpawn[MAXPLAYERS + 1];
HellPortal g_HellPortal[2048 + 1]; //this is a shitty way of using memory for no reason FIXME or don't


public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_bLateLoad = late;
	return APLRes_Success;
}

public Plugin myinfo = 
{
	name = "Hellwitch_redo", 
	author = "Lux", 
	description = "Screams that come from hell.", 
	version = HWR_VERSION, 
	url = "https://forums.alliedmods.net/showthread.php?p=2844826"
};

public void OnPluginStart()
{
	RegAdminCmd("sm_greaterwitch", SpawnGreaterWitch, ADMFLAG_CHEATS, "spawn greater witch where you look?"); //dev cmd have fun
	
	CreateConVar("hwr_hellwitchredo_version", HWR_VERSION, _, FCVAR_NOTIFY | FCVAR_DONTRECORD);
	
	g_CvarHellPortal_Timeout = CreateConVar("hwr_hellportal_timeout", "90.0", "how long a portal can live for.", FCVAR_NOTIFY, true, 30.0);
	g_CvarHellPortal_Delay_Spawn = CreateConVar("hwr_hellportal_delay_spawn", "20.0", "how long survivors have to prepare until portal starts spawning mobs", FCVAR_NOTIFY);
	g_CvarHellPortal_Commons_Max = CreateConVar("hwr_hellportal_commons_max", "140", "how many commons portal can spawn in it's lifetime", FCVAR_NOTIFY);
	g_CvarHellPortal_Commons_Max_Exist = CreateConVar("hwr_hellportal_comnmons_max_exist", "40", "how many common infected can exist at once (respects spawning rules)", FCVAR_NOTIFY, _, _, true, 100.0);
	g_CvarHellPortal_Common_Spawn_Interval = CreateConVar("hwr_hellportal_common_spawn_interval", "0.1", "portal spawn interval for common infected", _, true, 0.030);
	g_CvarHellPortal_Wave_Spawn_Interval = CreateConVar("hwr_hellportal_wave_spawn_interval", "4.0", "how long between portal special infected wave spawns", FCVAR_NOTIFY, true, 1.0);
	g_CvarHellPortal_Tanks_Max = CreateConVar("hwr_hellportal_tank_max", "1", "how many tanks can spawn from portal");
	g_CvarHellPortal_Chargers_Max = CreateConVar("hwr_hellportal_charger_max", "3", "how many chargers total can spawn from portal", FCVAR_NOTIFY);
	g_CvarHellPortal_Smokers_Max = CreateConVar("hwr_hellportal_smoker_max", "2", "how many smokers total can spawn from portal", FCVAR_NOTIFY);
	g_CvarHellPortal_Hunters_Max = CreateConVar("hwr_hellportal_hunter_max", "3", "how many hunters total can spawn from portal", FCVAR_NOTIFY);
	g_CvarHellPortal_Boomers_Max = CreateConVar("hwr_hellportal_boomer_max", "2", "how many boomers total can spawn from portal", FCVAR_NOTIFY);
	g_CvarHellPortal_Jockeys_Max = CreateConVar("hwr_hellportal_jockey_max", "1", "how many jockeys total can spawn from portal", FCVAR_NOTIFY);
	g_CvarHellPortal_Witches_Max = CreateConVar("hwr_hellportal_witch_max", "1", "how many witchs total can spawn from portal", FCVAR_NOTIFY);
	g_CvarHellPortal_Spitters_Max = CreateConVar("hwr_hellportal_spitter_max", "2", "how many spitters total can spawn from portal", FCVAR_NOTIFY);
	
	g_CvarWitchPose = CreateConVar("hwr_witch_poses", "1", "alternate witchspawns between sitting and standing idle state(before startle)", FCVAR_NOTIFY);
	g_CvarWitchSoul_Max = CreateConVar("hwr_witchsouls", "3", "how many witch souls needed for greater hellwitch to spawn", FCVAR_NOTIFY);
	g_CvarWitchSoul_GainChance = CreateConVar("hwr_witchsoul_gainchance", "2", "chance out of 1000 to passively gain a witch soul each second 0 = disable", FCVAR_NOTIFY);
	g_CvarWitchSoul_GainDeathChance = CreateConVar("hwr_witchsoul_gaindeathchance", "20", "chance out of 100 to gain a witch soul on non crown(1 shot) witch death = 0 disable", FCVAR_NOTIFY);
	g_CvarHellMob_Spawn_Interval = CreateConVar("hwr_hellmob_spawn_interval", "12.0", "time between waves of hell mob spawning in queue after more than 1 witch death", FCVAR_NOTIFY);
	g_CvarHellMob_Spawn_Interval_WitchDeath = CreateConVar("hwr_hellmob_spawn_interval_witchdeath", "6.5", "time after with death non crown(1 shot) will next mob spawn, will bypass hwr_hellmob_spawn_interval", FCVAR_NOTIFY);
	g_CvarHPDivision_For_Spawning = CreateConVar("hwr_hp_divison_for_spawning", "100", "divide total max hp of all surivors by this amount 4 survivors at 50hp = 2 special mobs spawning in a wave at value 100", FCVAR_NOTIFY, true, 1.0);
	g_CvarMaxSlots_Reserve = CreateConVar("hwr_maxslots_reserve", "4", "how many client slots to reserve usually for going idle and player joining so a slot exists for them", FCVAR_NOTIFY);
	g_CvarAllowEscapeWitch_PortalCall = CreateConVar("hwr_escaped_witch_portalcall", "1", "should we allow escaped witches to call for portal (non portal/non hell wave witches)", FCVAR_NOTIFY);
	
	g_CvarHellWave_Tanks_Max = CreateConVar("hwr_hellwave_tank_max", "1", "maximum tanks can spawn for a hellwave nonportal spawn", FCVAR_NOTIFY);
	g_CvarHellWave_Chargers_Max = CreateConVar("hwr_hellwave_charger_max", "3", "maximum chargers can spawn for a hellwave nonportal spawn", FCVAR_NOTIFY);
	g_CvarHellWave_Smokers_Max = CreateConVar("hwr_hellwave_smoker_max", "2", "maximum smokers can spawn for a hellwave nonportal spawn", FCVAR_NOTIFY);
	g_CvarHellWave_Hunters_Max = CreateConVar("hwr_hellwave_hunters_max", "3", "maximum hunters can spawn for a hellwave nonportal spawn", FCVAR_NOTIFY);
	g_CvarHellWave_Boomers_Max = CreateConVar("hwr_hellwave_boomers_max", "2", "maximum boomers can spawn for a hellwave nonportal spawn", FCVAR_NOTIFY);
	g_CvarHellWave_Jockeys_Max = CreateConVar("hwr_hellwave_jockeys_max", "1", "maximum jockeys can spawn for a hellwave nonportal spawn", FCVAR_NOTIFY);
	g_CvarHellWave_Witches_Max = CreateConVar("hwr_hellwave_witches_max", "0", "maximum witches can spawn for a hellwave nonportal spawn", FCVAR_NOTIFY);
	g_CvarHellWave_Spitters_Max = CreateConVar("hwr_hellwave_spitters_max", "2", "maximum spitters can spawn for a hellwave nonportal spawn", FCVAR_NOTIFY);
	
	g_CvarWaveSpawn_HP_Multiply_Tanks = CreateConVar("hwr_wavespawn_tank_hp_multiply", "0.33", "multiply total spawns from hp of survivor team happens after hwr_hp_divison_for_spawning formula(for portal waves and normal waves)", FCVAR_NOTIFY);
	g_CvarWaveSpawn_HP_Multiply_Chargers = CreateConVar("hwr_wavespawn_chargers_hp_multiply", "0.5", "multiply total spawns from total hp of survivor team happens after hwr_hp_divison_for_spawning formula(for portal waves and normal waves)", FCVAR_NOTIFY);
	g_CvarWaveSpawn_HP_Multiply_Smokers = CreateConVar("hwr_wavespawn_smokers_hp_multiply", "0.5", "multiply total spawns from total hp of survivor team happens after hwr_hp_divison_for_spawning formula(for portal waves and normal waves)", FCVAR_NOTIFY);
	g_CvarWaveSpawn_HP_Multiply_Hunters = CreateConVar("hwr_wavespawn_hunters_hp_multiply", "0.5", "multiply total spawns from total hp of survivor team happens after hwr_hp_divison_for_spawning formula(for portal waves and normal waves)", FCVAR_NOTIFY);
	g_CvarWaveSpawn_HP_Multiply_Boomers = CreateConVar("hwr_wavespawn_boomers_hp_multiply", "0.5", "multiply total spawns from total hp of survivor team happens after hwr_hp_divison_for_spawning formula(for portal waves and normal waves)", FCVAR_NOTIFY);
	g_CvarWaveSpawn_HP_Multiply_Jockeys = CreateConVar("hwr_wavespawn_jockeys_hp_multiply", "0.33", "multiply total spawns from total hp of survivor team happens after hwr_hp_divison_for_spawning formula(for portal waves and normal waves)", FCVAR_NOTIFY);
	g_CvarWaveSpawn_HP_Multiply_Witches = CreateConVar("hwr_wavespawn_witches_hp_multiply", "1.0", "multiply total spawns from total hp of survivor team happens after hwr_hp_divison_for_spawning formula(for portal waves and normal waves)", FCVAR_NOTIFY);
	g_CvarWaveSpawn_HP_Multiply_Spitters = CreateConVar("hwr_wavespawn_spitters_hp_multiply", "0.2", "multiply total spawns from total hp of survivor team happens after hwr_hp_divison_for_spawning formula(for portal waves and normal waves)", FCVAR_NOTIFY);
	g_CvarWaveSpawn_Ignore_Multiply = CreateConVar("hwr_wavespawn_ignore_multiply", "0", "should we ignore multiply scaling for non hell portal waves", FCVAR_NOTIFY);
	
	g_CvarHellMob_ImmuneToBurn = CreateConVar("hwr_hellmob_immune_to_burning", "1", "should hell spawns be immune to burning, they come from hell don't let them burn!", FCVAR_NOTIFY);
	
	g_CvarHellPortal_Timeout.AddChangeHook(eConVarChanged);
	g_CvarHellPortal_Delay_Spawn.AddChangeHook(eConVarChanged);
	g_CvarHellPortal_Commons_Max.AddChangeHook(eConVarChanged);
	g_CvarHellPortal_Commons_Max_Exist.AddChangeHook(eConVarChanged);
	g_CvarHellPortal_Common_Spawn_Interval.AddChangeHook(eConVarChanged);
	g_CvarHellPortal_Wave_Spawn_Interval.AddChangeHook(eConVarChanged);
	g_CvarHellPortal_Tanks_Max.AddChangeHook(eConVarChanged);
	g_CvarHellPortal_Chargers_Max.AddChangeHook(eConVarChanged);
	g_CvarHellPortal_Smokers_Max.AddChangeHook(eConVarChanged);
	g_CvarHellPortal_Hunters_Max.AddChangeHook(eConVarChanged);
	g_CvarHellPortal_Boomers_Max.AddChangeHook(eConVarChanged);
	g_CvarHellPortal_Jockeys_Max.AddChangeHook(eConVarChanged);
	g_CvarHellPortal_Witches_Max.AddChangeHook(eConVarChanged);
	g_CvarHellPortal_Spitters_Max.AddChangeHook(eConVarChanged);
	g_CvarWitchPose.AddChangeHook(eConVarChanged);
	g_CvarWitchSoul_Max.AddChangeHook(eConVarChanged);
	g_CvarWitchSoul_GainChance.AddChangeHook(eConVarChanged);
	g_CvarWitchSoul_GainDeathChance.AddChangeHook(eConVarChanged);
	g_CvarHellMob_Spawn_Interval.AddChangeHook(eConVarChanged);
	g_CvarHellMob_Spawn_Interval_WitchDeath.AddChangeHook(eConVarChanged);
	g_CvarHPDivision_For_Spawning.AddChangeHook(eConVarChanged);
	g_CvarMaxSlots_Reserve.AddChangeHook(eConVarChanged);
	g_CvarAllowEscapeWitch_PortalCall.AddChangeHook(eConVarChanged);
	
	g_CvarHellWave_Tanks_Max.AddChangeHook(eConVarChanged);
	g_CvarHellWave_Chargers_Max.AddChangeHook(eConVarChanged);
	g_CvarHellWave_Smokers_Max.AddChangeHook(eConVarChanged);
	g_CvarHellWave_Hunters_Max.AddChangeHook(eConVarChanged);
	g_CvarHellWave_Boomers_Max.AddChangeHook(eConVarChanged);
	g_CvarHellWave_Jockeys_Max.AddChangeHook(eConVarChanged);
	g_CvarHellWave_Witches_Max.AddChangeHook(eConVarChanged);
	g_CvarHellWave_Spitters_Max.AddChangeHook(eConVarChanged);
	
	g_CvarWaveSpawn_HP_Multiply_Tanks.AddChangeHook(eConVarChanged);
	g_CvarWaveSpawn_HP_Multiply_Chargers.AddChangeHook(eConVarChanged);
	g_CvarWaveSpawn_HP_Multiply_Smokers.AddChangeHook(eConVarChanged);
	g_CvarWaveSpawn_HP_Multiply_Hunters.AddChangeHook(eConVarChanged);
	g_CvarWaveSpawn_HP_Multiply_Boomers.AddChangeHook(eConVarChanged);
	g_CvarWaveSpawn_HP_Multiply_Jockeys.AddChangeHook(eConVarChanged);
	g_CvarWaveSpawn_HP_Multiply_Witches.AddChangeHook(eConVarChanged);
	g_CvarWaveSpawn_HP_Multiply_Spitters.AddChangeHook(eConVarChanged);
	g_CvarWaveSpawn_Ignore_Multiply.AddChangeHook(eConVarChanged);
	
	g_CvarHellMob_ImmuneToBurn.AddChangeHook(eConVarChanged);
	
	
	g_CvarCommonLimit = FindConVar("z_common_limit");
	g_CvarCommonLimit.AddChangeHook(eConVarChanged);
	g_CvarNB_Update_Interval = FindConVar("nb_update_frequency");
	g_CvarNB_Update_Interval.AddChangeHook(eConVarChanged);
	
	g_CvarTimeOfDay = FindConVar("sv_force_time_of_day");
	g_CvarTimeOfDay.AddChangeHook(eTimeOfDayConVarChanged);
	g_iTimeOfDay = g_CvarTimeOfDay.IntValue;
	
	
	for (int i; i <= 2048; ++i)
	{
		g_HellSpawnWitch[i].m_iEntIndex = i;
		g_HellSpawnCommon[i].m_iEntIndex = i;
		g_HellPortal[i].m_iEntIndex = i;
	}
	for (int i; i <= MAXPLAYERS; ++i)
	{
		g_HellSpawn[i].m_client = i;
	}
	
	--g_OneShotDeathCrySize;
	--g_DemonsSoundSize;
	--g_GreaterElectricSize;
	HookEvent("witch_killed", WitchKilled);
	HookEvent("witch_spawn", WitchSpawn);
	HookEvent("witch_harasser_set", WitchStartle);
	HookEvent("round_start", RoundStart);
	HookEvent("player_spawn", PlayerSpawn);
	
	//spawn type
	g_HellSpawnQueue = new ArrayList();
	g_PentaGramLineArt = new ArrayList(31); // time then vectors
	
	AddNormalSoundHook(HellSpawnSound);
	
	CreateTimer(1.0, LogicInterval, INVALID_HANDLE, TIMER_REPEAT);
	//AutoExecConfig(true, "Hellwitch_redo");
	CvarsChanged();
	
	if (g_bLateLoad)
	{
		for (int i = MaxClients + 1; i <= 2048; ++i)
		{
			if (IsValidEntity(i) && IsCommon(i))
				continue;
			
			char sClassname[32];
			if (IsValidEntity(i))
			{
				GetEntityClassname(i, sClassname, sizeof(sClassname));
				if (strcmp(sClassname, "witch", false) == 0)
				{
					g_HellSpawnWitch[i].InitWitch();
				}
			}
		}
	}
}

public void OnMapStart()
{
	g_flTickInterval = GetTickInterval();
	g_flWitchTargetNextTargetTime = 0.0;
	
	SetConVarBounds(FindConVar("z_max_player_zombies"), ConVarBound_Upper, true, 31.0);
	SetConVarBounds(FindConVar("z_minion_limit"), ConVarBound_Upper, true, 31.0);
	SetConVarBounds(FindConVar("survival_max_specials"), ConVarBound_Upper, true, 31.0);
	SetConVarString(FindConVar("sv_multiplayer_sounds"), "128"); //needed client side checks for this value to cull sounds :c
	
	
	g_flNextHellSpawnMob = 0.0;
	
	for (int i; i < sizeof(g_sOneShotDeathCry); ++i)
	{
		PrecacheSound(g_sOneShotDeathCry[i], true);
	}
	for (int i; i < sizeof(g_sDemonsSounds); ++i)
	{
		PrecacheSound(g_sDemonsSounds[i], true);
	}
	for (int i; i < sizeof(g_sGreaterElectric); ++i)
	{
		PrecacheSound(g_sGreaterElectric[i], true);
	}
	
	//yes this could be an array but who else is looking
	PrecacheSound(LOWER_HELLSPAWN_TANK_SND_1, true);
	PrecacheSound(LOWER_HELLSPAWN_TANK_SND_2, true);
	PrecacheSound(LOWER_HELLSPAWN_TANK_SND_3, true);
	PrecacheSound(LOWER_HELLSPAWN_TANK_SND_4, true);
	PrecacheSound(LOWER_HELLSPAWN_TANK_SND_5, true);
	PrecacheSound(LOWER_HELLSPAWN_TANK_SND_6, true);
	PrecacheSound(LOWER_HELLSPAWN_TANK_SND_7, true);
	PrecacheSound(LOWER_HELLSPAWN_TANK_SND_8, true);
	
	PrecacheSound(LOWER_HELLSPAWN_BOOMER_SND_1, true);
	PrecacheSound(LOWER_HELLSPAWN_BOOMER_SND_2, true);
	PrecacheSound(LOWER_HELLSPAWN_BOOMER_SND_3, true);
	PrecacheSound(LOWER_HELLSPAWN_BOOMER_SND_4, true);
	PrecacheSound(LOWER_HELLSPAWN_BOOMER_SND_5, true);
	PrecacheSound(LOWER_HELLSPAWN_BOOMER_SND_6, true);
	PrecacheSound(LOWER_HELLSPAWN_BOOMER_SND_7, true);
	PrecacheSound(LOWER_HELLSPAWN_BOOMER_SND_8, true);
	
	PrecacheSound(LOWER_HELLSPAWN_SMOKER_SND_1, true);
	PrecacheSound(LOWER_HELLSPAWN_SMOKER_SND_2, true);
	PrecacheSound(LOWER_HELLSPAWN_SMOKER_SND_3, true);
	PrecacheSound(LOWER_HELLSPAWN_SMOKER_SND_4, true);
	PrecacheSound(LOWER_HELLSPAWN_SMOKER_SND_5, true);
	
	PrecacheSound(LOWER_HELLSPAWN_HUNTER_SND_1, true);
	PrecacheSound(LOWER_HELLSPAWN_HUNTER_SND_2, true);
	PrecacheSound(LOWER_HELLSPAWN_HUNTER_SND_3, true);
	PrecacheSound(LOWER_HELLSPAWN_HUNTER_SND_4, true);
	PrecacheSound(LOWER_HELLSPAWN_HUNTER_SND_5, true);
	
	PrecacheSound(LOWER_HELLSPAWN_JOCKEY_SND_1, true);
	PrecacheSound(LOWER_HELLSPAWN_JOCKEY_SND_2, true);
	PrecacheSound(LOWER_HELLSPAWN_JOCKEY_SND_3, true);
	PrecacheSound(LOWER_HELLSPAWN_JOCKEY_SND_4, true);
	PrecacheSound(LOWER_HELLSPAWN_JOCKEY_SND_5, true);
	
	PrecacheSound(LOWER_HELLSPAWN_CHARGER_SND_1, true);
	PrecacheSound(LOWER_HELLSPAWN_CHARGER_SND_2, true);
	PrecacheSound(LOWER_HELLSPAWN_CHARGER_SND_3, true);
	PrecacheSound(LOWER_HELLSPAWN_CHARGER_SND_4, true);
	PrecacheSound(LOWER_HELLSPAWN_CHARGER_SND_5, true);
	
	PrecacheSound(LOWER_HELLSPAWN_SPITTER_SND_1, true);
	PrecacheSound(LOWER_HELLSPAWN_SPITTER_SND_2, true);
	PrecacheSound(LOWER_HELLSPAWN_SPITTER_SND_3, true);
	PrecacheSound(LOWER_HELLSPAWN_SPITTER_SND_4, true);
	PrecacheSound(LOWER_HELLSPAWN_SPITTER_SND_5, true);
	PrecacheSound(LOWER_HELLSPAWN_SPITTER_SND_6, true);
	
	PrecacheSound(HELLWITCH_DEATHSOUND_1, true);
	PrecacheSound(HELLWITCH_DEATHSOUND_FARAWAY, true);
	
	PrecacheSound(GREATER_WITCH_DEATH_SND, true);
	PrecacheSound(HELLPORTAL_EMERGE_SND, true);
	PrecacheSound(HELLPORTAL_EMERGE_SND_2, true);
	PrecacheSound(HELLPORTAL_EMERGE_BANG, true);
	PrecacheSound(HELLPORTAL_CLOSE_SND, true);
	
	g_DebrisModel = PrecacheModel(HELLPORTAL_ROCK_DEBRIS, true);
	g_LaserSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
	g_PentagamFires = Precache_Particle_System("fire_small_02");
	g_HellEmbers = Precache_Particle_System("embers_medium_03");
	g_Electrics = Precache_Particle_System("item_defibrillator_body");
	g_SpawnFireBall = Precache_Particle_System("gas_explosion_fireballsmoke");
	g_BangParticle = Precache_Particle_System(HELLPORTAL_EMERGE_BANG_PARTICLE);
	g_EmergeParticle = Precache_Particle_System(HELLPORTAL_EMERGE_PARTICLE);
	g_AfterDustParticle = Precache_Particle_System(HELLPORTAL_AFTERDUST_PARTICLE);
	Precache_Particle_System(HELLPORTAL_FIRE);
	g_bMapRunning = true;
}

public void OnMapEnd()
{
	g_bMapRunning = false;
}


public void WitchKilled(Event event, const char[] name, bool dontBroadcast)
{
	int witch = event.GetInt("witchid");
	bool bDidOneShot = event.GetBool("oneshot");
	
	if (witch < MaxClients)
		return;
	
	if (g_HellSpawnWitch[witch].SetupHellCry(bDidOneShot))
	{
		int iPortal = CreateEntityByName("info_particle_system");
		if (iPortal == -1)
			return;
		
		DispatchKeyValue(iPortal, "effect_name", HELLPORTAL_FIRE);
		DispatchSpawn(iPortal);
		ActivateEntity(iPortal);
		
		float vecOrigin[3];
		GetAbsOrigin(witch, vecOrigin);
		TeleportEntity(iPortal, vecOrigin, NULL_VECTOR, NULL_VECTOR);
		g_HellPortal[iPortal].InitPortal(vecOrigin);
	}
}

public void WitchSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int witch = event.GetInt("witchid");
	if (!IsValidEntity(witch))
		return;
	
	if (!g_bCatchSpawning && g_bWitchPose)
	{
		if (g_CvarTimeOfDay.IntValue == 3)
		{
			g_CvarTimeOfDay.SetInt(0);
		}
		else
		{
			g_CvarTimeOfDay.SetInt(3);
		}
	}
	
	if (g_bCatchSpawning)
	{
		g_bDidAnythingSpawn = true;
		if (g_bPortalSpawning)
		{
			++g_iHellPortalSpawnAmount;
		}
		
		if (g_vecSpawnOriginHack[0] == 0.0 && g_vecSpawnOriginHack[1] == 0.0 && g_vecSpawnOriginHack[2] == 0.0)
		{
			//this is a shit way of doing it why am i?
			GetAbsOrigin(witch, g_vecSpawnOriginHack);
			
			TE_SetupParticle(g_SpawnFireBall, g_vecSpawnOriginHack);
			TE_SendToAllInRange(g_vecSpawnOriginHack, RangeType_Visibility);
		}
		else
		{
			TeleportEntity(witch, g_vecSpawnOriginHack, NULL_VECTOR, NULL_VECTOR);
		}
		g_HellSpawnWitch[witch].InitWitch(true);
		return;
	}
	
	if (g_iWitchSouls >= g_iWitchSoul_Max)
	{
		g_HellSpawnWitch[witch].ForceSittingWitch(false);
	}
	CreateTimer(0.1, WitchConvertToHellSpawn, EntIndexToEntRef(witch), TIMER_FLAG_NO_MAPCHANGE); //help
	
}

public Action WitchConvertToHellSpawn(Handle timer, int witchRef)
{
	if (!IsValidEntRef(witchRef))
		return Plugin_Stop;
	
	g_HellSpawnWitch[EntRefToEntIndex(witchRef)].InitWitch();
	return Plugin_Stop;
}

public void GreaterElectric(int entity)
{
	if (GetEntProp(entity, Prop_Data, "m_iHealth") < 1)
	{
		SDKUnhook(entity, SDKHook_Think, GreaterElectric);
		return;
	}
	g_HellSpawnWitch[entity].DoGreaterWitchEffects();
}

public void TimeOfDayRevert(int entity)
{
	if (GetGameTime() <= g_flRevertTimeOfDayChange)
		return;
	
	g_bIgnoreTimeOfDayChange = true;
	g_CvarTimeOfDay.SetInt(g_iTimeOfDay);
	g_bIgnoreTimeOfDayChange = false;
	SDKUnhook(entity, SDKHook_Think, TimeOfDayRevert);
}

public void WitchStartle(Event event, const char[] name, bool dontBroadcast)
{
	int witch = event.GetInt("witchid");
	if (!IsValidEntity(witch))
		return;
	
	g_HellSpawnWitch[witch].m_bWasStartled = true;
}

public void OnEntityDestroyed(int witch)
{
	if (!g_bAllowEscapeWitch_PortalCall)
		return;
	
	if (witch <= MaxClients || witch > 2048)
		return;
	
	if (!g_bMapRunning || !IsServerProcessing())
		return;
	
	if (!g_HellSpawnWitch[witch].IsValidWitch())
		return;
	
	if (g_HellSpawnWitch[witch].m_bWasKilled)
		return;
	
	if (!g_HellSpawnWitch[witch].m_bWasStartled)
		return;
	
	if (g_HellSpawnWitch[witch].IsNonSpecialWitch())
		return;
	
	int iPortal = CreateEntityByName("info_particle_system");
	if (iPortal == -1)
		return;
	
	DispatchKeyValue(iPortal, "effect_name", HELLPORTAL_FIRE);
	DispatchSpawn(iPortal);
	ActivateEntity(iPortal);
	
	float vecOrigin[3];
	GetAbsOrigin(witch, vecOrigin);
	TeleportEntity(iPortal, vecOrigin, NULL_VECTOR, NULL_VECTOR);
	g_HellPortal[iPortal].InitPortal(vecOrigin);
	
	for (int i = 1; i <= HELLWITCH_ESCAPE_PORTAL_CALL_VOL; ++i)
	EmitSoundToAll(HELLWITCH_DEATHSOUND_FARAWAY, SOUND_FROM_WORLD, SNDCHAN_STATIC, 120, _, _, 30, _, vecOrigin);
	
}


public void PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client < 1 || client > MaxClients)
		return;
	
	g_HellSpawn[client].ClearHellSpawnData();
	
	if (!g_bCatchSpawning)
		return;
	
	if (!IsClientInGame(client) || !IsPlayerAlive(client) || GetClientTeam(client) == 2)
		return;
	
	if (g_bPortalSpawning)
	{
		++g_iHellPortalSpawnAmount;
	}
	
	g_HellSpawn[client].InitHellSpawn();
	if (GetEntProp(client, Prop_Send, "m_zombieClass", 2) == ZOMBIECLASS_TANK && IsFakeClient(client))
	{
		CreateTimer(0.1, TriggerTankAttack, event.GetInt("userid"), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
	
	if (g_vecSpawnOriginHack[0] == 0.0 && g_vecSpawnOriginHack[1] == 0.0 && g_vecSpawnOriginHack[2] == 0.0)
	{
		//this is a shit way of doing it why am i?
		GetAbsOrigin(client, g_vecSpawnOriginHack);
		
		TE_SetupParticle(g_SpawnFireBall, g_vecSpawnOriginHack);
		TE_SendToAllInRange(g_vecSpawnOriginHack, RangeType_Visibility);
	}
	else
	{
		TeleportEntity(client, g_vecSpawnOriginHack, NULL_VECTOR, NULL_VECTOR);
	}
	SetEntPropFloat(client, Prop_Send, "m_burnPercent", 1.0);
	g_bDidAnythingSpawn = true;
}

public void OnClientPutInServer(int client)
{
	g_HellSpawn[client].ClearHellSpawnData();
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (entity < 1 || entity > 2048)
		return;
	
	if (classname[0] != 'i' || strcmp(classname, "infected", false) != 0)
		return;
	
	if (g_bCatchSpawning || AnyPortalsExist())
	{
		g_HellSpawnCommon[entity].InitHellSpawn(g_bPortalSpawning);
	}
}

public void RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_HellSpawnQueue.Clear();
	g_PentaGramLineArt.Clear();
	g_iWitchSouls = 0;
}

public Action HellSpawnSound(int clients[64], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags)
{
	if (g_bCatchSpawning)
	{
		if (strcmp(sample, "common/null.wav", false) == 0)
			return Plugin_Continue;
		return Plugin_Handled;
	}
	
	if (entity < 1 || entity > 2048)
		return Plugin_Continue;
	
	if (entity < MaxClients + 1 && g_HellSpawn[entity].IsHellSpawn())
	{
		pitch = g_HellSpawn[entity].m_iPitch;
	}
	else if (g_HellSpawnCommon[entity].IsHellSpawn())
	{
		pitch = g_HellSpawnCommon[entity].m_iPitch;
	}
	else if (g_HellSpawnWitch[entity].IsGreaterWitch() || g_HellSpawnWitch[entity].IsNonSpecialWitch())
	{
		if (sample[0] == 'n' && strcmp(sample, "npc/witch/voice/die/female_death_1.wav", false) == 0)
			return Plugin_Handled;
		
		pitch = g_HellSpawnWitch[entity].m_iPitch;
	}
	else
	{
		return Plugin_Continue;
	}
	
	return Plugin_Changed;
}

public Action LogicInterval(Handle timer)
{
	if (GetAnyoneInGame() < 1)
		return Plugin_Continue;
	
	if (g_flWitchTargetNextTargetTime > GetGameTime())
		g_flWitchTargetNextTargetTime = 0.0;
	
	
	if (GetRandomInt(1, 1000) <= g_iWitchSoul_GainChance)
	{
		++g_iWitchSouls;
	}
	
	PentagramDrawAnyLines();
	
	if (AnyPortalsExist())
		return Plugin_Continue;
	
	float flTime = GetGameTime();
	if (g_flNextHellSpawnMob < flTime && g_HellSpawnQueue.Length > 0)
	{
		if (SpawnLowerHellMob(g_HellSpawnQueue.Get(0)))
		{
			g_HellSpawnQueue.Erase(0);
			g_flNextHellSpawnMob = flTime + g_flHellMob_Spawn_Interval;
		}
	}
	
	return Plugin_Continue;
}

public void HellPortalLogic(int iEntRef)
{
	if (!IsValidEntRef(iEntRef))
		return;
	
	int iPortal = EntRefToEntIndex(iEntRef);
	if (g_HellPortal[iPortal].PortalLogic())
	{
		RequestFrame(HellPortalLogic, iEntRef);
	}
}

public Action SoulQueueDeath(Handle timer, DataPack dp)
{
	float vecOrigin[3];
	dp.Reset();
	vecOrigin[0] = dp.ReadFloat();
	vecOrigin[1] = dp.ReadFloat();
	vecOrigin[2] = dp.ReadFloat();
	
	for (int i; i < HELLPORTAL_EMERGE_BANG_VOL; ++i)
	{
		EmitSoundToAll(HELLPORTAL_EMERGE_BANG, SOUND_FROM_WORLD, SNDCHAN_STATIC, 140, _, _, 50, _, vecOrigin);
	}
	
	EmitSoundToAll(g_sDemonsSounds[GetRandomInt(0, g_DemonsSoundSize)], SOUND_FROM_WORLD, SNDCHAN_STATIC, 90, _, _, 25, _, vecOrigin);
	TE_SetupParticle(g_BangParticle, vecOrigin);
	TE_SendToAllInRange(vecOrigin, RangeType_Visibility);
	ShakeClientScreenAll(vecOrigin, 400.0, 7.0, 70.0, 2.0);
	
	TE_SetupExplodeForce(vecOrigin, 300.0, 100.0);
	TE_SendToAllInRange(vecOrigin, RangeType_Visibility);
	
	vecOrigin[2] -= 20.0;
	PhysicsExplode(vecOrigin, 300, 30.0);
	
	return Plugin_Stop;
}

bool SpawnLowerHellMob(ZombieSpawns Type)
{
	int client = GetAnyoneInGame();
	if (client < 1)
		return false;
	
	int iTotalHp = GetTeamTotalHealth();
	iTotalHp = (iTotalHp / g_iHPDivision_For_Spawning) + 1;
	
	int iFreeSlots = (MaxClients - GetCurrentFreeSlots());
	if (Type != ZombieSpawns_Witch)
	{
		if (iFreeSlots < g_iMaxSlots_Reserve)
			return false;
	}
	
	g_bCatchSpawning = true; //catch spawning to spawn mobs in 1 place
	
	//g_vecSpawnOriginHack = FLOAT_({0.0, 0.0, 0.0});// medic
	g_vecSpawnOriginHack = view_as<float>( { 0.0, 0.0, 0.0 } );
	switch (Type)
	{
		case ZombieSpawns_Tank:
		{
			if (!g_bWaveSpawn_Ignore_Multiply)
				iTotalHp = RoundToNearest((iTotalHp * g_flWaveSpawn_HP_Multiply_Tanks));
			
			if (iFreeSlots < iTotalHp)
				iTotalHp = iFreeSlots;
			
			if (g_iHellWave_Tanks_Max < iTotalHp)
				iTotalHp = g_iHellWave_Tanks_Max;
			
			for (int i; i < iTotalHp; ++i)
			{
				ClientCheatCommand(client, "z_spawn_old", "tank auto");
			}
		}
		case ZombieSpawns_Smoker:
		{
			if (!g_bWaveSpawn_Ignore_Multiply)
				iTotalHp = RoundToNearest((iTotalHp * g_flWaveSpawn_HP_Multiply_Smokers));
			
			if (iFreeSlots < iTotalHp)
				iTotalHp = iFreeSlots;
			
			if (g_iHellWave_Smokers_Max < iTotalHp)
				iTotalHp = g_iHellWave_Smokers_Max;
			
			for (int i; i < iTotalHp; ++i)
			{
				ClientCheatCommand(client, "z_spawn_old", "smoker auto");
			}
		}
		case ZombieSpawns_Boomer:
		{
			if (!g_bWaveSpawn_Ignore_Multiply)
				iTotalHp = RoundToNearest((iTotalHp * g_flWaveSpawn_HP_Multiply_Boomers));
			
			if (iFreeSlots < iTotalHp)
				iTotalHp = iFreeSlots;
			
			if (g_iHellWave_Boomers_Max < iTotalHp)
				iTotalHp = g_iHellWave_Boomers_Max;
			
			for (int i; i < iTotalHp; ++i)
			{
				ClientCheatCommand(client, "z_spawn_old", "boomer auto");
			}
		}
		case ZombieSpawns_Hunter:
		{
			if (!g_bWaveSpawn_Ignore_Multiply)
				iTotalHp = RoundToNearest((iTotalHp * g_flWaveSpawn_HP_Multiply_Hunters));
			
			if (iFreeSlots < iTotalHp)
				iTotalHp = iFreeSlots;
			
			if (g_iHellWave_Hunters_Max < iTotalHp)
				iTotalHp = g_iHellWave_Hunters_Max;
			
			for (int i; i < iTotalHp; ++i)
			{
				ClientCheatCommand(client, "z_spawn_old", "hunter auto");
			}
		}
		case ZombieSpawns_Jockey:
		{
			if (!g_bWaveSpawn_Ignore_Multiply)
				iTotalHp = RoundToNearest((iTotalHp * g_flWaveSpawn_HP_Multiply_Jockeys));
			
			if (iFreeSlots < iTotalHp)
				iTotalHp = iFreeSlots;
			
			if (g_iHellWave_Jockeys_Max < iTotalHp)
				iTotalHp = g_iHellWave_Jockeys_Max;
			
			for (int i; i < iTotalHp; ++i)
			{
				ClientCheatCommand(client, "z_spawn_old", "jockey auto");
			}
		}
		case ZombieSpawns_Charger:
		{
			if (!g_bWaveSpawn_Ignore_Multiply)
				iTotalHp = RoundToNearest((iTotalHp * g_flWaveSpawn_HP_Multiply_Chargers));
			
			if (iFreeSlots < iTotalHp)
				iTotalHp = iFreeSlots;
			
			if (g_iHellWave_Chargers_Max < iTotalHp)
				iTotalHp = g_iHellWave_Chargers_Max;
			
			for (int i; i < iTotalHp; ++i)
			{
				ClientCheatCommand(client, "z_spawn_old", "charger auto");
			}
		}
		case ZombieSpawns_Witch:
		{
			if (!g_bWaveSpawn_Ignore_Multiply)
				iTotalHp = RoundToNearest((iTotalHp * g_flWaveSpawn_HP_Multiply_Witches));
			
			if (g_iHellWave_Witches_Max < iTotalHp)
				iTotalHp = g_iHellWave_Witches_Max;
			
			for (int i; i < iTotalHp; ++i)
			{
				ClientCheatCommand(client, "z_spawn_old", "witch auto");
			}
		}
		case ZombieSpawns_Spitter:
		{
			if (!g_bWaveSpawn_Ignore_Multiply)
				iTotalHp = RoundToNearest((iTotalHp * g_flWaveSpawn_HP_Multiply_Spitters));
			
			if (iFreeSlots < iTotalHp)
				iTotalHp = iFreeSlots;
			
			if (g_iHellWave_Spitters_Max < iTotalHp)
				iTotalHp = g_iHellWave_Spitters_Max;
			
			for (int i; i < iTotalHp; ++i)
			{
				ClientCheatCommand(client, "z_spawn_old", "spitter auto");
			}
		}
	}
	
	g_bCatchSpawning = false;
	
	if (!g_bDidAnythingSpawn)
		return false;
	
	EmitLowerHellSpawn_SFK(Type);
	
	g_bDidAnythingSpawn = false;
	return true;
}

bool SpawnPortalMob(ZombieSpawns Type, int iPortalIndex)
{
	int client = GetAnyoneInGame();
	if (client < 1)
		return false;
	
	int iTotalHp = GetTeamTotalHealth();
	iTotalHp = (iTotalHp / g_iHPDivision_For_Spawning) + 1;
	
	int iFreeSlots = (MaxClients - GetCurrentFreeSlots());
	if (Type != ZombieSpawns_Witch)
	{
		if (iFreeSlots < g_iMaxSlots_Reserve)
			return false;
	}
	
	g_bCatchSpawning = true; //catch spawning to spawn mobs in 1 place
	g_iHellPortalSpawnAmount = 0;
	
	g_vecSpawnOriginHack = g_HellPortal[iPortalIndex].m_vecOrigin; // i don't care
	switch (Type)
	{
		case ZombieSpawns_Tank:
		{
			iTotalHp = RoundToNearest((iTotalHp * g_flWaveSpawn_HP_Multiply_Tanks));
			if (iTotalHp < 1)
				iTotalHp = 1;
			
			if (iFreeSlots < iTotalHp)
				iTotalHp = iFreeSlots;
			
			if (g_HellPortal[iPortalIndex].m_iTanks < iTotalHp)
				iTotalHp = g_HellPortal[iPortalIndex].m_iTanks;
			
			for (int i; i < iTotalHp; ++i)
			{
				ClientCheatCommand(client, "z_spawn", "tank");
			}
		}
		case ZombieSpawns_Smoker:
		{
			iTotalHp = RoundToNearest((iTotalHp * g_flWaveSpawn_HP_Multiply_Smokers));
			if (iTotalHp < 1)
				iTotalHp = 1;
			
			if (iFreeSlots < iTotalHp)
				iTotalHp = iFreeSlots;
			
			if (g_HellPortal[iPortalIndex].m_iSmokers < iTotalHp)
				iTotalHp = g_HellPortal[iPortalIndex].m_iSmokers;
			
			for (int i; i < iTotalHp; ++i)
			{
				ClientCheatCommand(client, "z_spawn", "smoker");
			}
		}
		case ZombieSpawns_Boomer:
		{
			iTotalHp = RoundToNearest((iTotalHp * g_flWaveSpawn_HP_Multiply_Boomers));
			if (iTotalHp < 1)
				iTotalHp = 1;
			
			if (iFreeSlots < iTotalHp)
				iTotalHp = iFreeSlots;
			
			if (g_HellPortal[iPortalIndex].m_iBoomers < iTotalHp)
				iTotalHp = g_HellPortal[iPortalIndex].m_iBoomers;
			
			for (int i; i < iTotalHp; ++i)
			{
				ClientCheatCommand(client, "z_spawn", "boomer");
			}
		}
		case ZombieSpawns_Hunter:
		{
			iTotalHp = RoundToNearest((iTotalHp * g_flWaveSpawn_HP_Multiply_Hunters));
			if (iTotalHp < 1)
				iTotalHp = 1;
			
			if (iFreeSlots < iTotalHp)
				iTotalHp = iFreeSlots;
			
			if (g_HellPortal[iPortalIndex].m_iHunters < iTotalHp)
				iTotalHp = g_HellPortal[iPortalIndex].m_iHunters;
			
			for (int i; i < iTotalHp; ++i)
			{
				ClientCheatCommand(client, "z_spawn", "hunter");
			}
		}
		case ZombieSpawns_Jockey:
		{
			iTotalHp = RoundToNearest((iTotalHp * g_flWaveSpawn_HP_Multiply_Jockeys));
			if (iTotalHp < 1)
				iTotalHp = 1;
			
			if (iFreeSlots < iTotalHp)
				iTotalHp = iFreeSlots;
			
			if (g_HellPortal[iPortalIndex].m_iJockeys < iTotalHp)
				iTotalHp = g_HellPortal[iPortalIndex].m_iJockeys;
			
			for (int i; i < iTotalHp; ++i)
			{
				ClientCheatCommand(client, "z_spawn", "jockey");
			}
		}
		case ZombieSpawns_Charger:
		{
			iTotalHp = RoundToNearest((iTotalHp * g_flWaveSpawn_HP_Multiply_Chargers));
			if (iTotalHp < 1)
				iTotalHp = 1;
			
			if (iFreeSlots < iTotalHp)
				iTotalHp = iFreeSlots;
			
			if (g_HellPortal[iPortalIndex].m_iChargers < iTotalHp)
				iTotalHp = g_HellPortal[iPortalIndex].m_iChargers;
			
			for (int i; i < iTotalHp; ++i)
			{
				ClientCheatCommand(client, "z_spawn", "charger");
			}
		}
		case ZombieSpawns_Witch:
		{
			iTotalHp = RoundToNearest((iTotalHp * g_flWaveSpawn_HP_Multiply_Witches));
			if (iTotalHp < 1)
				iTotalHp = 1;
			
			if (g_HellPortal[iPortalIndex].m_iWitches < iTotalHp)
				iTotalHp = g_HellPortal[iPortalIndex].m_iWitches;
			
			for (int i; i < iTotalHp; ++i)
			{
				ClientCheatCommand(client, "z_spawn", "witch");
			}
		}
		case ZombieSpawns_Spitter:
		{
			iTotalHp = RoundToNearest((iTotalHp * g_flWaveSpawn_HP_Multiply_Spitters));
			if (iTotalHp < 1)
				iTotalHp = 1;
			
			if (iFreeSlots < iTotalHp)
				iTotalHp = iFreeSlots;
			
			if (g_HellPortal[iPortalIndex].m_iSpitters < iTotalHp)
				iTotalHp = g_HellPortal[iPortalIndex].m_iSpitters;
			
			for (int i; i < iTotalHp; ++i)
			{
				ClientCheatCommand(client, "z_spawn", "spitter");
			}
		}
	}
	
	g_bCatchSpawning = false;
	
	
	if (!g_bDidAnythingSpawn)
	{
		return false;
	}
	
	g_bDidAnythingSpawn = false;
	return true;
}

int GetAnyoneInGame()
{
	for (int i = 1; i <= MaxClients; ++i)
	{
		if (IsClientInGame(i))
			return i;
	}
	return -1;
}

int GetCurrentFreeSlots()
{
	int amount;
	for (int i = 1; i <= MaxClients; ++i)
	{
		if (IsClientConnected(i))
		{
			++amount;
		}
	}
	return amount;
}

int GetTeamTotalHealth()
{
	int iTotalHp;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || GetClientTeam(i) != 2 || !IsPlayerAlive(i))
			continue;
		
		if (GetEntProp(i, Prop_Send, "m_bIsOnThirdStrike", 1) > 0)
			continue;
		if (GetEntProp(i, Prop_Send, "m_isIncapacitated", 1) > 0)
			continue;
		
		iTotalHp += (L4D_GetPlayerTempHealth(i) / 2);
		iTotalHp += GetClientHealth(i);
	}
	return iTotalHp;
}

int GetAllPortalSpawnedCommons()
{
	int amount;
	int totalCommons;
	for (int i = MaxClients + 1; i <= 2048; ++i)
	{
		if (g_HellSpawnCommon[i].IsPortalSpawn())
		{
			++amount;
			++totalCommons;
		}
		else if (IsCommon(i))
		{
			++totalCommons;
		}
	}
	
	return (totalCommons >= g_iCommonLimit ? g_iHellPortal_Commons_Max_Exist : amount);
}

bool IsCommon(int iEntity)
{
	if (iEntity <= MaxClients)
	{
		return false;
	}
	
	if (!IsValidEntity(iEntity))
		return false;
	
	static char sClassName[9];
	GetEntPropString(iEntity, Prop_Data, "m_iClassname", sClassName, sizeof(sClassName));
	
	if (sClassName[0] != 'i')
	{
		return false;
	}
	
	if (strcmp(sClassName, "infected") != 0)
	{
		return false;
	}
	return true;
}

bool AnyPortalsExist()
{
	for (int i = MaxClients + 1; i <= 2048; ++i)
	{
		if (g_HellPortal[i].IsValidPortal())
			return true;
	}
	return false;
}

//yes i know it's shit you fix it
void EmitLowerHellSpawn_SFK(ZombieSpawns Type)
{
	switch (Type)
	{
		case ZombieSpawns_Tank:
		{
			switch (GetRandomInt(1, 8))
			{
				case 1:
				{
					for (int i; i <= LOWER_HELLSPAWN_SOUNDS_MAX; ++i)
					EmitSoundToAll(LOWER_HELLSPAWN_TANK_SND_1, SOUND_FROM_WORLD, SNDCHAN_STATIC, 140, _, _, 60, _, g_vecSpawnOriginHack);
				}
				case 2:
				{
					for (int i; i <= LOWER_HELLSPAWN_SOUNDS_MAX; ++i)
					EmitSoundToAll(LOWER_HELLSPAWN_TANK_SND_2, SOUND_FROM_WORLD, SNDCHAN_STATIC, 140, _, _, 60, _, g_vecSpawnOriginHack);
				}
				case 3:
				{
					for (int i; i <= LOWER_HELLSPAWN_SOUNDS_MAX; ++i)
					EmitSoundToAll(LOWER_HELLSPAWN_TANK_SND_3, SOUND_FROM_WORLD, SNDCHAN_STATIC, 140, _, _, 60, _, g_vecSpawnOriginHack);
				}
				case 4:
				{
					for (int i; i <= LOWER_HELLSPAWN_SOUNDS_MAX; ++i)
					EmitSoundToAll(LOWER_HELLSPAWN_TANK_SND_4, SOUND_FROM_WORLD, SNDCHAN_STATIC, 140, _, _, 60, _, g_vecSpawnOriginHack);
				}
				case 5:
				{
					for (int i; i <= LOWER_HELLSPAWN_SOUNDS_MAX; ++i)
					EmitSoundToAll(LOWER_HELLSPAWN_TANK_SND_5, SOUND_FROM_WORLD, SNDCHAN_STATIC, 140, _, _, 60, _, g_vecSpawnOriginHack);
				}
				case 6:
				{
					for (int i; i <= LOWER_HELLSPAWN_SOUNDS_MAX; ++i)
					EmitSoundToAll(LOWER_HELLSPAWN_TANK_SND_6, SOUND_FROM_WORLD, SNDCHAN_STATIC, 140, _, _, 60, _, g_vecSpawnOriginHack);
				}
				case 7:
				{
					for (int i; i <= LOWER_HELLSPAWN_SOUNDS_MAX; ++i)
					EmitSoundToAll(LOWER_HELLSPAWN_TANK_SND_7, SOUND_FROM_WORLD, SNDCHAN_STATIC, 140, _, _, 80, _, g_vecSpawnOriginHack);
				}
				case 8:
				{
					for (int i; i <= LOWER_HELLSPAWN_SOUNDS_MAX; ++i)
					EmitSoundToAll(LOWER_HELLSPAWN_TANK_SND_8, SOUND_FROM_WORLD, SNDCHAN_STATIC, 140, _, _, 80, _, g_vecSpawnOriginHack);
				}
			}
		}
		case ZombieSpawns_Smoker:
		{
			switch (GetRandomInt(1, 5))
			{
				case 1:
				{
					for (int i; i < LOWER_HELLSPAWN_SOUNDS_MAX; ++i)
					EmitSoundToAll(LOWER_HELLSPAWN_SMOKER_SND_1, SOUND_FROM_WORLD, SNDCHAN_STATIC, 140, _, _, 60, _, g_vecSpawnOriginHack);
				}
				case 2:
				{
					for (int i; i < LOWER_HELLSPAWN_SOUNDS_MAX; ++i)
					EmitSoundToAll(LOWER_HELLSPAWN_SMOKER_SND_2, SOUND_FROM_WORLD, SNDCHAN_STATIC, 140, _, _, 60, _, g_vecSpawnOriginHack);
				}
				case 3:
				{
					for (int i; i < LOWER_HELLSPAWN_SOUNDS_MAX; ++i)
					EmitSoundToAll(LOWER_HELLSPAWN_SMOKER_SND_3, SOUND_FROM_WORLD, SNDCHAN_STATIC, 140, _, _, 60, _, g_vecSpawnOriginHack);
				}
				case 4:
				{
					for (int i; i < LOWER_HELLSPAWN_SOUNDS_MAX; ++i)
					EmitSoundToAll(LOWER_HELLSPAWN_SMOKER_SND_4, SOUND_FROM_WORLD, SNDCHAN_STATIC, 140, _, _, 60, _, g_vecSpawnOriginHack);
				}
				case 5:
				{
					for (int i; i < LOWER_HELLSPAWN_SOUNDS_MAX; ++i)
					EmitSoundToAll(LOWER_HELLSPAWN_SMOKER_SND_5, SOUND_FROM_WORLD, SNDCHAN_STATIC, 140, _, _, 60, _, g_vecSpawnOriginHack);
				}
			}
		}
		case ZombieSpawns_Boomer:
		{
			switch (GetRandomInt(1, 8))
			{
				case 1:
				{
					for (int i; i < LOWER_HELLSPAWN_SOUNDS_MAX; ++i)
					EmitSoundToAll(LOWER_HELLSPAWN_BOOMER_SND_1, SOUND_FROM_WORLD, SNDCHAN_STATIC, 140, _, _, 60, _, g_vecSpawnOriginHack);
				}
				case 2:
				{
					for (int i; i < LOWER_HELLSPAWN_SOUNDS_MAX; ++i)
					EmitSoundToAll(LOWER_HELLSPAWN_BOOMER_SND_2, SOUND_FROM_WORLD, SNDCHAN_STATIC, 140, _, _, 60, _, g_vecSpawnOriginHack);
				}
				case 3:
				{
					for (int i; i < LOWER_HELLSPAWN_SOUNDS_MAX; ++i)
					EmitSoundToAll(LOWER_HELLSPAWN_BOOMER_SND_3, SOUND_FROM_WORLD, SNDCHAN_STATIC, 140, _, _, 60, _, g_vecSpawnOriginHack);
				}
				case 4:
				{
					for (int i; i < LOWER_HELLSPAWN_SOUNDS_MAX; ++i)
					EmitSoundToAll(LOWER_HELLSPAWN_BOOMER_SND_4, SOUND_FROM_WORLD, SNDCHAN_STATIC, 140, _, _, 60, _, g_vecSpawnOriginHack);
				}
				case 5:
				{
					for (int i; i < LOWER_HELLSPAWN_SOUNDS_MAX; ++i)
					EmitSoundToAll(LOWER_HELLSPAWN_BOOMER_SND_5, SOUND_FROM_WORLD, SNDCHAN_STATIC, 140, _, _, 60, _, g_vecSpawnOriginHack);
				}
				case 6:
				{
					for (int i; i < LOWER_HELLSPAWN_SOUNDS_MAX; ++i)
					EmitSoundToAll(LOWER_HELLSPAWN_BOOMER_SND_6, SOUND_FROM_WORLD, SNDCHAN_STATIC, 140, _, _, 60, _, g_vecSpawnOriginHack);
				}
				case 7:
				{
					for (int i; i < LOWER_HELLSPAWN_SOUNDS_MAX; ++i)
					EmitSoundToAll(LOWER_HELLSPAWN_BOOMER_SND_7, SOUND_FROM_WORLD, SNDCHAN_STATIC, 140, _, _, 60, _, g_vecSpawnOriginHack);
				}
				case 8:
				{
					for (int i; i < LOWER_HELLSPAWN_SOUNDS_MAX; ++i)
					EmitSoundToAll(LOWER_HELLSPAWN_BOOMER_SND_8, SOUND_FROM_WORLD, SNDCHAN_STATIC, 140, _, _, 50, _, g_vecSpawnOriginHack);
				}
			}
		}
		case ZombieSpawns_Hunter:
		{
			switch (GetRandomInt(1, 5))
			{
				case 1:
				{
					for (int i; i < LOWER_HELLSPAWN_SOUNDS_MAX; ++i)
					EmitSoundToAll(LOWER_HELLSPAWN_HUNTER_SND_1, SOUND_FROM_WORLD, SNDCHAN_STATIC, 140, _, _, 60, _, g_vecSpawnOriginHack);
				}
				case 2:
				{
					for (int i; i < LOWER_HELLSPAWN_SOUNDS_MAX; ++i)
					EmitSoundToAll(LOWER_HELLSPAWN_HUNTER_SND_2, SOUND_FROM_WORLD, SNDCHAN_STATIC, 140, _, _, 60, _, g_vecSpawnOriginHack);
				}
				case 3:
				{
					for (int i; i < LOWER_HELLSPAWN_SOUNDS_MAX; ++i)
					EmitSoundToAll(LOWER_HELLSPAWN_HUNTER_SND_3, SOUND_FROM_WORLD, SNDCHAN_STATIC, 140, _, _, 60, _, g_vecSpawnOriginHack);
				}
				case 4:
				{
					for (int i; i < LOWER_HELLSPAWN_SOUNDS_MAX; ++i)
					EmitSoundToAll(LOWER_HELLSPAWN_HUNTER_SND_4, SOUND_FROM_WORLD, SNDCHAN_STATIC, 140, _, _, 60, _, g_vecSpawnOriginHack);
				}
				case 5:
				{
					for (int i; i < LOWER_HELLSPAWN_SOUNDS_MAX; ++i)
					EmitSoundToAll(LOWER_HELLSPAWN_HUNTER_SND_5, SOUND_FROM_WORLD, SNDCHAN_STATIC, 140, _, _, 60, _, g_vecSpawnOriginHack);
				}
			}
		}
		case ZombieSpawns_Jockey:
		{
			switch (GetRandomInt(1, 5))
			{
				case 1:
				{
					for (int i; i < LOWER_HELLSPAWN_SOUNDS_MAX; ++i)
					EmitSoundToAll(LOWER_HELLSPAWN_JOCKEY_SND_1, SOUND_FROM_WORLD, SNDCHAN_STATIC, 140, _, _, 60, _, g_vecSpawnOriginHack);
				}
				case 2:
				{
					for (int i; i < LOWER_HELLSPAWN_SOUNDS_MAX; ++i)
					EmitSoundToAll(LOWER_HELLSPAWN_JOCKEY_SND_2, SOUND_FROM_WORLD, SNDCHAN_STATIC, 140, _, _, 60, _, g_vecSpawnOriginHack);
				}
				case 3:
				{
					for (int i; i < LOWER_HELLSPAWN_SOUNDS_MAX; ++i)
					EmitSoundToAll(LOWER_HELLSPAWN_JOCKEY_SND_3, SOUND_FROM_WORLD, SNDCHAN_STATIC, 140, _, _, 60, _, g_vecSpawnOriginHack);
				}
				case 4:
				{
					for (int i; i < LOWER_HELLSPAWN_SOUNDS_MAX; ++i)
					EmitSoundToAll(LOWER_HELLSPAWN_JOCKEY_SND_4, SOUND_FROM_WORLD, SNDCHAN_STATIC, 140, _, _, 60, _, g_vecSpawnOriginHack);
				}
				case 5:
				{
					for (int i; i < LOWER_HELLSPAWN_SOUNDS_MAX; ++i)
					EmitSoundToAll(LOWER_HELLSPAWN_JOCKEY_SND_5, SOUND_FROM_WORLD, SNDCHAN_STATIC, 140, _, _, 60, _, g_vecSpawnOriginHack);
				}
			}
		}
		case ZombieSpawns_Charger:
		{
			switch (GetRandomInt(1, 5))
			{
				case 1:
				{
					for (int i; i < LOWER_HELLSPAWN_SOUNDS_MAX; ++i)
					EmitSoundToAll(LOWER_HELLSPAWN_CHARGER_SND_1, SOUND_FROM_WORLD, SNDCHAN_STATIC, 140, _, _, 60, _, g_vecSpawnOriginHack);
				}
				case 2:
				{
					for (int i; i < LOWER_HELLSPAWN_SOUNDS_MAX; ++i)
					EmitSoundToAll(LOWER_HELLSPAWN_CHARGER_SND_2, SOUND_FROM_WORLD, SNDCHAN_STATIC, 140, _, _, 60, _, g_vecSpawnOriginHack);
				}
				case 3:
				{
					for (int i; i < LOWER_HELLSPAWN_SOUNDS_MAX; ++i)
					EmitSoundToAll(LOWER_HELLSPAWN_CHARGER_SND_3, SOUND_FROM_WORLD, SNDCHAN_STATIC, 140, _, _, 60, _, g_vecSpawnOriginHack);
				}
				case 4:
				{
					for (int i; i < LOWER_HELLSPAWN_SOUNDS_MAX; ++i)
					EmitSoundToAll(LOWER_HELLSPAWN_CHARGER_SND_4, SOUND_FROM_WORLD, SNDCHAN_STATIC, 140, _, _, 60, _, g_vecSpawnOriginHack);
				}
				case 5:
				{
					for (int i; i < LOWER_HELLSPAWN_SOUNDS_MAX; ++i)
					EmitSoundToAll(LOWER_HELLSPAWN_CHARGER_SND_5, SOUND_FROM_WORLD, SNDCHAN_STATIC, 140, _, _, 60, _, g_vecSpawnOriginHack);
				}
			}
		}
		case ZombieSpawns_Spitter:
		{
			switch (GetRandomInt(1, 6))
			{
				case 1:
				{
					for (int i; i < LOWER_HELLSPAWN_SOUNDS_MAX; ++i)
					EmitSoundToAll(LOWER_HELLSPAWN_SPITTER_SND_1, SOUND_FROM_WORLD, SNDCHAN_STATIC, 140, _, _, 60, _, g_vecSpawnOriginHack);
				}
				case 2:
				{
					for (int i; i < LOWER_HELLSPAWN_SOUNDS_MAX; ++i)
					EmitSoundToAll(LOWER_HELLSPAWN_SPITTER_SND_2, SOUND_FROM_WORLD, SNDCHAN_STATIC, 140, _, _, 60, _, g_vecSpawnOriginHack);
				}
				case 3:
				{
					for (int i; i < LOWER_HELLSPAWN_SOUNDS_MAX; ++i)
					EmitSoundToAll(LOWER_HELLSPAWN_SPITTER_SND_3, SOUND_FROM_WORLD, SNDCHAN_STATIC, 140, _, _, 60, _, g_vecSpawnOriginHack);
				}
				case 4:
				{
					for (int i; i < LOWER_HELLSPAWN_SOUNDS_MAX; ++i)
					EmitSoundToAll(LOWER_HELLSPAWN_SPITTER_SND_4, SOUND_FROM_WORLD, SNDCHAN_STATIC, 140, _, _, 60, _, g_vecSpawnOriginHack);
				}
				case 5:
				{
					for (int i; i < LOWER_HELLSPAWN_SOUNDS_MAX; ++i)
					EmitSoundToAll(LOWER_HELLSPAWN_SPITTER_SND_5, SOUND_FROM_WORLD, SNDCHAN_STATIC, 140, _, _, 60, _, g_vecSpawnOriginHack);
				}
				case 6:
				{
					for (int i; i < LOWER_HELLSPAWN_SOUNDS_MAX; ++i)
					EmitSoundToAll(LOWER_HELLSPAWN_SPITTER_SND_6, SOUND_FROM_WORLD, SNDCHAN_STATIC, 140, _, _, 60, _, g_vecSpawnOriginHack);
				}
			}
		}
	}
}

void EmitWitchDeath_SFK(float vecOrigin[3])
{
	float vecPlayerPos[3];
	int iPitch = GetRandomInt(30, 70);
	int iRngNum = GetRandomInt(1, 2);
	for (int i = 1; i <= MaxClients; ++i)
	{
		if (!IsClientInGame(i) || IsFakeClient(i))
			continue;
		
		GetClientEyePosition(i, vecPlayerPos);
		
		if (GetVectorDistance(vecOrigin, vecPlayerPos) < HELLWITCH_DEATHSOUND_FARAWAY_DIST)
		{
			switch (iRngNum)
			{
				case 1:
				{
					for (int ii; ii < HELLWITCH_DEATHSOUND_MAX; ++ii)
					EmitSoundToClient(i, HELLWITCH_DEATHSOUND_1, SOUND_FROM_WORLD, SNDCHAN_STATIC, 100, _, _, iPitch, _, vecOrigin);
				}
				case 2:
				{
					EmitSoundToClient(i, HELLWITCH_DEATHSOUND_1, SOUND_FROM_WORLD, SNDCHAN_STATIC, 70, _, _, 130, _, vecOrigin);
					EmitSoundToClient(i, HELLWITCH_DEATHSOUND_1, SOUND_FROM_WORLD, SNDCHAN_STATIC, 80, _, _, 120, _, vecOrigin);
					EmitSoundToClient(i, HELLWITCH_DEATHSOUND_1, SOUND_FROM_WORLD, SNDCHAN_STATIC, 90, _, _, 110, _, vecOrigin);
					EmitSoundToClient(i, HELLWITCH_DEATHSOUND_1, SOUND_FROM_WORLD, SNDCHAN_STATIC, 100, _, _, 100, _, vecOrigin);
				}
			}
		}
		else
		{
			for (int ii; ii <= HELLWITCH_DEATHSOUND_FAR_MAX; ++ii)
			EmitSoundToClient(i, HELLWITCH_DEATHSOUND_1, SOUND_FROM_WORLD, SNDCHAN_STATIC, 90, _, _, 30, _, vecOrigin);
		}
	}
}

void PentagramDrawAnyLines()
{
	int Len = g_PentaGramLineArt.Length;
	if (Len < 1)
		return;
	
	float flTime = GetGameTime();
	float vecStart[3];
	float vecEnd[3];
	
	for (int i; i < Len; ++i)
	{
		if (g_PentaGramLineArt.Get(i) > flTime)
			continue;
		
		
		g_PentaGramLineArt.Set(i, (flTime + GREATERWITCH_PENTAGRAM_REDRAW_INTERVAL));
		for (int x; x < 5; ++x)
		{
			// 2 vectors = 6 block per line 
			vecStart[0] = g_PentaGramLineArt.Get(i, 1 + (6 * x));
			vecStart[1] = g_PentaGramLineArt.Get(i, 2 + (6 * x));
			vecStart[2] = g_PentaGramLineArt.Get(i, 3 + (6 * x));
			
			vecEnd[0] = g_PentaGramLineArt.Get(i, 4 + (6 * x));
			vecEnd[1] = g_PentaGramLineArt.Get(i, 5 + (6 * x));
			vecEnd[2] = g_PentaGramLineArt.Get(i, 6 + (6 * x));
			
			//draw red lines
			static int colour[4] = { 255, 0, 0, 255 };
			TE_SetupBeamPoints(vecStart, vecEnd, g_LaserSprite, 0, 0, 0, (GREATERWITCH_PENTAGRAM_REDRAW_INTERVAL + 2), 1.0, 1.0, 1, 0.0, colour, 0);
			TE_SendToAll(g_flTickInterval * x);
		}
	}
}

void AlertAllCommons()
{
	for (int i = MaxClients + 1; i <= 2048; ++i)
	{
		if (IsCommon(i))
		{
			SetEntProp(i, Prop_Send, "m_mobRush", 1);
		}
	}
}

int GetAnyAliveClient()
{
	static int lastIndex = 1;
	for (int i = 1; i <= MaxClients; ++i)
	{
		if (lastIndex == i || !IsClientInGame(i) || GetClientTeam(i) != 2 || !IsPlayerAlive(i))
			continue;
		
		g_iWitchTargetIndex = i;
	}
	
	
	lastIndex = g_iWitchTargetIndex; //try not to pick same target
	return g_iWitchTargetIndex;
}

public void eConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	CvarsChanged();
}

public void eTimeOfDayConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (g_bIgnoreTimeOfDayChange)
		return;
	
	g_iTimeOfDay = g_CvarTimeOfDay.IntValue;
}

void CvarsChanged()
{
	g_iCommonLimit = g_CvarCommonLimit.IntValue;
	
	g_flHellPortal_Timeout = g_CvarHellPortal_Timeout.FloatValue;
	g_flHellPortal_Delay_Spawn = g_CvarHellPortal_Delay_Spawn.FloatValue;
	g_iHellPortal_Commons_Max = g_CvarHellPortal_Commons_Max.IntValue;
	g_iHellPortal_Commons_Max_Exist = g_CvarHellPortal_Commons_Max_Exist.IntValue;
	g_flHellPortal_Common_Spawn_Interval = g_CvarHellPortal_Common_Spawn_Interval.FloatValue;
	g_flHellPortal_Wave_Spawn_Interval = g_CvarHellPortal_Wave_Spawn_Interval.FloatValue;
	g_iHellPortal_Tanks_Max = g_CvarHellPortal_Tanks_Max.IntValue;
	g_iHellPortal_Chargers_Max = g_CvarHellPortal_Chargers_Max.IntValue;
	g_iHellPortal_Smokers_Max = g_CvarHellPortal_Smokers_Max.IntValue;
	g_iHellPortal_Hunters_Max = g_CvarHellPortal_Hunters_Max.IntValue;
	g_iHellPortal_Boomers_Max = g_CvarHellPortal_Boomers_Max.IntValue;
	g_iHellPortal_Jockeys_Max = g_CvarHellPortal_Jockeys_Max.IntValue;
	g_iHellPortal_Witches_Max = g_CvarHellPortal_Witches_Max.IntValue;
	g_iHellPortal_Spitters_Max = g_CvarHellPortal_Spitters_Max.IntValue;
	
	g_bWitchPose = g_CvarWitchPose.BoolValue;
	g_iWitchSoul_Max = g_CvarWitchSoul_Max.IntValue;
	g_iWitchSoul_GainChance = g_CvarWitchSoul_GainChance.IntValue;
	g_iWitchSoul_GainDeathChance = g_CvarWitchSoul_GainDeathChance.IntValue;
	g_flHellMob_Spawn_Interval = g_CvarHellMob_Spawn_Interval.FloatValue;
	g_flHellMob_Spawn_Interval_WitchDeath = g_CvarHellMob_Spawn_Interval_WitchDeath.FloatValue;
	g_iHPDivision_For_Spawning = g_CvarHPDivision_For_Spawning.IntValue;
	g_iMaxSlots_Reserve = g_CvarMaxSlots_Reserve.IntValue;
	g_bAllowEscapeWitch_PortalCall = g_CvarAllowEscapeWitch_PortalCall.BoolValue;
	
	g_flMinUpdate_TimeCvar = (g_flTickInterval >= g_CvarNB_Update_Interval.FloatValue ? g_flTickInterval : g_CvarNB_Update_Interval.FloatValue) * 4;
	
	g_iHellWave_Tanks_Max = g_CvarHellWave_Tanks_Max.IntValue;
	g_iHellWave_Chargers_Max = g_CvarHellWave_Chargers_Max.IntValue;
	g_iHellWave_Smokers_Max = g_CvarHellWave_Smokers_Max.IntValue;
	g_iHellWave_Hunters_Max = g_CvarHellWave_Hunters_Max.IntValue;
	g_iHellWave_Boomers_Max = g_CvarHellWave_Boomers_Max.IntValue;
	g_iHellWave_Jockeys_Max = g_CvarHellWave_Jockeys_Max.IntValue;
	g_iHellWave_Witches_Max = g_CvarHellWave_Witches_Max.IntValue;
	g_iHellWave_Spitters_Max = g_CvarHellWave_Spitters_Max.IntValue;
	
	g_flWaveSpawn_HP_Multiply_Tanks = g_CvarWaveSpawn_HP_Multiply_Tanks.FloatValue;
	g_flWaveSpawn_HP_Multiply_Chargers = g_CvarWaveSpawn_HP_Multiply_Chargers.FloatValue;
	g_flWaveSpawn_HP_Multiply_Smokers = g_CvarWaveSpawn_HP_Multiply_Smokers.FloatValue;
	g_flWaveSpawn_HP_Multiply_Hunters = g_CvarWaveSpawn_HP_Multiply_Hunters.FloatValue;
	g_flWaveSpawn_HP_Multiply_Boomers = g_CvarWaveSpawn_HP_Multiply_Boomers.FloatValue;
	g_flWaveSpawn_HP_Multiply_Jockeys = g_CvarWaveSpawn_HP_Multiply_Jockeys.FloatValue;
	g_flWaveSpawn_HP_Multiply_Witches = g_CvarWaveSpawn_HP_Multiply_Witches.FloatValue;
	g_flWaveSpawn_HP_Multiply_Spitters = g_CvarWaveSpawn_HP_Multiply_Spitters.FloatValue;
	g_bWaveSpawn_Ignore_Multiply = g_CvarWaveSpawn_Ignore_Multiply.BoolValue;
	
	g_bHellMob_ImmuneToBurn = g_CvarHellMob_ImmuneToBurn.BoolValue;
}

public Action SpawnGreaterWitch(int client, int args)
{
	if (client == 0)
		return Plugin_Handled;
	
	if (!IsClientInGame(client))
		return Plugin_Handled;
	
	g_iWitchSouls += g_iWitchSoul_Max;
	ClientCheatCommand(client, "z_spawn", "witch");
	
	return Plugin_Handled;
}

public Action TriggerWitchAttack(Handle timer, int witchEntRef)
{
	if (!IsValidEntRef(witchEntRef))
		return Plugin_Stop;
	
	float flTime = GetGameTime();
	if (g_flWitchTargetNextTargetTime < flTime)
	{
		g_iWitchTargetIndex = GetAnyAliveClient();
		if (g_iWitchTargetIndex < 1 || !IsClientInGame(g_iWitchTargetIndex) || !IsPlayerAlive(g_iWitchTargetIndex))
			return Plugin_Continue;
	}
	
	g_flWitchTargetNextTargetTime = flTime + 2.0;
	if (GetEntPropFloat(witchEntRef, Prop_Send, "m_rage") >= 0.91)
		return Plugin_Stop;
	
	static float vecPos[3];
	GetAbsOrigin(witchEntRef, vecPos, true);
	
	Entity_Hurt(witchEntRef, 0, g_iWitchTargetIndex, DMG_FULLGIB, _, vecPos);
	return Plugin_Continue;
}

public Action TriggerTankAttack(Handle timer, int iUserID)
{
	int client = GetClientOfUserId(iUserID);
	if (client < 1 || !IsClientInGame(client) || GetClientTeam(client) != 3 || !IsFakeClient(client) || !IsPlayerAlive(client))
		return Plugin_Stop;
	
	int target = GetTankTarget();
	if (target < 1)
		return Plugin_Continue;
	
	static float vecPos[3];
	GetAbsOrigin(client, vecPos, true);
	
	SetEntProp(client, Prop_Send, "m_hasVisibleThreats", 1, 1);
	SetEntProp(client, Prop_Data, "m_iHealth", GetEntProp(client, Prop_Data, "m_iHealth") + 1);
	Entity_Hurt(client, 0, target, DMG_FULLGIB, _, vecPos);
	return Plugin_Continue;
}

int GetTankTarget()
{
	for (int client = 1; client <= MaxClients; ++client)
	{
		if (!IsClientInGame(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client))
			continue;
		
		return client;
	}
	
	return 0;
}

public Action ConvertFireDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (g_bHellMob_ImmuneToBurn && damagetype & DMG_BURN)
	{
		damagetype = DMG_GENERIC;
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

stock bool IsValidEntRef(int iEntRef)
{
	return (iEntRef != 0 && EntRefToEntIndex(iEntRef) != INVALID_ENT_REFERENCE);
}

stock void ClientCheatCommand(int iClient, const char[] sArg1, const char[] sArg2 = "", const char[] sArg3 = "", const char[] sArg4 = "")
{
	int iCommandFlags = GetCommandFlags(sArg1);
	SetCommandFlags(sArg1, iCommandFlags & ~FCVAR_CHEAT);
	
	FakeClientCommand(iClient, "%s %s %s %s", sArg1, sArg2, sArg3, sArg4);
	
	SetCommandFlags(sArg1, iCommandFlags);
}

//credit zero l4dstocks
/**
* Returns player temporarily health.
*
* @param client		Client index.
* @return				Player's temporarily health, -1 if unable to get.
* @error				Invalid client index or unable to find
* 						pain_pills_decay_rate cvar.
*/
#if !defined _l4d_stocks_included
stock int L4D_GetPlayerTempHealth(int client)
{
	static Handle painPillsDecayCvar = INVALID_HANDLE;
	if (painPillsDecayCvar == INVALID_HANDLE)
	{
		painPillsDecayCvar = FindConVar("pain_pills_decay_rate");
		if (painPillsDecayCvar == INVALID_HANDLE)
		{
			return -1;
		}
	}
	
	int tempHealth = RoundToCeil(GetEntPropFloat(client, Prop_Send, "m_healthBuffer") - ((GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime")) * GetConVarFloat(painPillsDecayCvar))) - 1;
	return tempHealth < 0 ? 0 : tempHealth;
}
#endif

stock void OriginMove(float fStartOrigin[3], float fStartAngles[3], float EndOrigin[3], float fDistance)
{
	static float fDirection[3];
	GetAngleVectors(fStartAngles, fDirection, NULL_VECTOR, NULL_VECTOR);
	
	EndOrigin[0] = fStartOrigin[0] + fDirection[0] * fDistance;
	EndOrigin[1] = fStartOrigin[1] + fDirection[1] * fDistance;
	EndOrigin[2] = fStartOrigin[2] + fDirection[2] * fDistance;
} 