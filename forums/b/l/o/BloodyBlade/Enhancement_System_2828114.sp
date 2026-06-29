#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "2.1"
#define CVAR_FLAGS FCVAR_NOTIFY

#define ENABLE_AUTOEXEC true
 
#define ZOMBIECLASS_SMOKER      1
#define ZOMBIECLASS_BOOMER      2
#define ZOMBIECLASS_HUNTER      3
#define ZOMBIECLASS_SPITTER     4
#define ZOMBIECLASS_JOCKEY      5
#define ZOMBIECLASS_CHARGER     6
#define ZOMBIECLASS_TANK        8

#define BloodPatch		"blood_bleedout_3"

#define SmokerBlood1	"blood_impact_smoker_01"
#define SmokerBlood2	"blood_impact_smoker_01_smoke"

#define LongLightGore1	"hunter_claw_child_spray"
#define LongLightGore2	"gore_entrails"

#define LongMedGore1	"gore_wound_fullbody_4"
#define LongMedGore2	"blood_impact_arterial_spray"
#define LongMedGore3	"blood_impact_arterial_spray_6"
#define LongMedGore4	"blood_impact_arterial_spray_drippy"

#define LightGore1		"gore_wound_belly_right_goop"
#define LightGore2		"gore_wound_belly_right_spurt"
#define LightGore3		"hunter_claw_child_goop"
#define LightGore4		"gore_goop_generic"
#define LightGore5		"gore_blood_spurt_generic"
#define LightGore6		"blood_impact_red_01_goop_backspray"

#define MedGore1		"hunter_claw"
#define MedGore2		"hunter_claw_child_goop2"
#define MedGore3		"gore_wound_arterial_spray_fallback"
#define MedGore4		"gore_blood_spurt_generic_2"
#define MedGore5		"blood_impact_tank_02"
#define MedGore6		"blood_impact_headshot_01c"
#define MedGore7		"blood_chainsaw_constant_b"
#define MedGore8		"blood_chainsaw_constant_tp"
#define MedGore9		"gore_wound_belly_left_spurt"

#define HeavyGore1		"gore_wound_fullbody_1b"
#define HeavyGore2		"gore_wound_arterial_spray_1"
#define HeavyGore3		"boomer_explode_D"
#define HeavyGore4		"gore_wound_brain"

#define ExpGore1		"boomer_explode_C"
#define ExpGore2		"boomer_explode_K"
#define ExpGore3		"blood_atomized_d"

#define HeadShotOnly1	"gore_entrails_cluster"
#define HeadShotOnly2	"blood_atomized"
#define HeadShotOnly3	"blood_atomized_c"
#define HeadShotOnly4	"blood_atomized_fallback"
#define HeadShotOnly5	"blood_atomized_fallback_3"
#define HeadShotOnly6	"boomer_explode_G"

#define ExtraBoomerFX	"boomer_explode_I"
#define BoomerDefaultFX	"boomer_explode"

#define SpitterBlood1	"spitter_projectile_explode_2"
#define SpitterBlood2	"spitter_projectile_trail"

#define RandomJockeyPart	GetRandomFloat(15.0, 18.5)
#define RandomHunterPart	GetRandomFloat(20.0, 66.0)
#define RandomSmokerPart	GetRandomFloat(30.0, 75.0)
#define RandomSpitterPart	GetRandomFloat(30.0, 73.0)
#define RandomTankPart		GetRandomFloat(18.0, 70.0)
#define RandomChargerPart	GetRandomFloat(22.0, 70.0)
#define RandomCommonPart	GetRandomFloat(20.0, 65.0)

#define ParticleKappaCap	if(iCount > 0)iCount -= 1;else	return

static int iCount = 0;

static ConVar hCvar_EnhanceMe;
static ConVar hCvar_KappaCount;
static ConVar hCvar_BloodIndexing;
static ConVar hCvar_BloodPool;
static ConVar hCvar_PoolRefresh;
static ConVar hCvar_PoolBoomer;
static ConVar hCvar_BloodParticles;
static ConVar hCvar_BoomerDecals;
static ConVar hCvar_PrecacheWorkAround;
static ConVar hCvar_Decals;
static ConVar hCvar_KappaTimer;
static Handle hTimer_Kappa = null;

static bool g_bBloodIndexing = false;
static int g_iBloodPool = 15;
static float g_fPoolRefresh = 0.7;
static bool g_bPoolBoomer = true;
static bool g_bBloodParticles = false;
static bool g_bBoomerDecals = false;
static bool g_bPrecacheWorkAround = false;
static bool g_bDecals = false;
static int g_iKappaCount = 1;
static float g_fKappaTimer = 0.1;

static bool PrecacheClientList[MAXPLAYERS + 1] = {false, ...};
bool g_bHooked = false;

public Plugin myinfo =
{
    name = "EnhanceGore",
    author = "Lux",
    description = "L4D2 Gore Enhancement System",
    version = PLUGIN_VERSION,
    url = "https://forums.alliedmods.net/showthread.php?p=2412026#post2412026"
};
 
public void OnPluginStart()
{
	CreateConVar("EnhanceGore_Version", PLUGIN_VERSION, "Enhancement System Version", CVAR_FLAGS|FCVAR_SPONLY|FCVAR_DONTRECORD);

	hCvar_EnhanceMe = CreateConVar("enhance_gore", "1", "EnableMe = 1 for EnhanceMents (Blood/Gore)", CVAR_FLAGS, true, 0.0, true, 1.0);
	hCvar_KappaCount = CreateConVar("enhance_particle_cap", "20", "Upper Limit to Particles at once", CVAR_FLAGS, true, 1.0, true, 100.0);
	hCvar_KappaTimer = CreateConVar("enhance_refresh_timer", "0.07", "TimeBefore Another Particle slot is Free (effective change happens on NextRound), e.g. cap is 20 to particles(Default) at once and particle slot refeshes every 0.1 secs(Default value) for +1 slot so if cap is at 0 it will be 2 seconds until 20 slots are free again", CVAR_FLAGS, true, 0.0, true, 1.0);
	hCvar_BloodIndexing = CreateConVar("enhance_blood_indexing", "1", "Save blood pool locations until its gone to create another pool at the same location Better for Client Perf[0 = disable]", CVAR_FLAGS, true, 0.0, true, 1.0);
	hCvar_BloodPool = CreateConVar("enhance_blood_pool", "4", "BloodPool Cap Until refresh period [0 = disable bloodpools]", CVAR_FLAGS, true, 0.0, true, 100.0);
	hCvar_PoolRefresh = CreateConVar("enhance_blood_pool_refresh", "1.0", "BloodPool Refresh Period [0.0 = disable refresh Period Unlimied blood pools]", CVAR_FLAGS, true, 0.0, true, 5.0);
	hCvar_PoolBoomer = CreateConVar("enhance_blood_pool_boomer", "1", "Enable boomer blood pool (Its much bigger than standard) [0 = disable]", CVAR_FLAGS, true, 0.0, true, 5.0);
	hCvar_BloodParticles = CreateConVar("enhance_blood_particles", "1", "Enhance Blood & Gore [0 = disable]", CVAR_FLAGS, true, 0.0, true, 1.0);
	hCvar_BoomerDecals = CreateConVar("enhance_boomer_decals", "0", "EnhanceBoomer Pop with decals, but the clientsided particle system does not show boomerexplode particles, this will add them back in server side", CVAR_FLAGS, true, 0.0, true, 1.0); 
	hCvar_PrecacheWorkAround = CreateConVar("precache_work_around", "1", "If you have stutter due to latepreacaching particles enable this, altho they should already precache OnMapStart", CVAR_FLAGS, true, 0.0, true, 1.0); 
	hCvar_Decals = CreateConVar("enhance_decals", "1", "Enchance Decals to produce more blood splatter on the walls boomer pop decals wont work if this is disabled Autodisabled on(c3m2_swamp & c8m2_subway) Prevent lag", CVAR_FLAGS, true, 0.0, true, 1.0); 
	
	
	hCvar_EnhanceMe.AddChangeHook(eConvarAllowChanged);
	hCvar_KappaCount.AddChangeHook(eConvarChanged);
	hCvar_BloodIndexing.AddChangeHook(eConvarChanged);
	hCvar_BloodPool.AddChangeHook(eConvarChanged);
	hCvar_PoolRefresh.AddChangeHook(eConvarChanged);
	hCvar_PoolBoomer.AddChangeHook(eConvarChanged);
	hCvar_BloodParticles.AddChangeHook(eConvarChanged);
	hCvar_BoomerDecals.AddChangeHook(eConvarChanged);
	hCvar_PrecacheWorkAround.AddChangeHook(eConvarChanged);
	hCvar_Decals.AddChangeHook(eConvarChanged);
	hCvar_KappaTimer.AddChangeHook(eConvarChanged);

	#if ENABLE_AUTOEXEC
	AutoExecConfig(true, "EnhancementGore_V2");
	#endif
}

public void OnMapStart()
{
	if(!IsParticleSystemPrecached(BloodPatch)) 
		PrecacheParticleSystem(BloodPatch);
	if(!IsParticleSystemPrecached(SmokerBlood1)) 
		PrecacheParticleSystem(SmokerBlood1);
	if(!IsParticleSystemPrecached(SmokerBlood2)) 
		PrecacheParticleSystem(SmokerBlood2);
	if(!IsParticleSystemPrecached(LongLightGore1)) 
		PrecacheParticleSystem(LongLightGore1);
	if(!IsParticleSystemPrecached(LongLightGore2)) 
		PrecacheParticleSystem(LongLightGore2);
	if(!IsParticleSystemPrecached(LongMedGore1)) 
		PrecacheParticleSystem(LongMedGore1);
	if(!IsParticleSystemPrecached(LongMedGore2)) 
		PrecacheParticleSystem(LongMedGore2);
	if(!IsParticleSystemPrecached(LongMedGore3)) 
		PrecacheParticleSystem(LongMedGore3);
	if(!IsParticleSystemPrecached(LongMedGore4)) 
		PrecacheParticleSystem(LongMedGore4);
	if(!IsParticleSystemPrecached(LightGore1)) 
		PrecacheParticleSystem(LightGore1);
	if(!IsParticleSystemPrecached(LightGore2)) 
		PrecacheParticleSystem(LightGore2);
	if(!IsParticleSystemPrecached(LightGore3)) 
		PrecacheParticleSystem(LightGore3);
	if(!IsParticleSystemPrecached(LightGore4)) 
		PrecacheParticleSystem(LightGore4);
	if(!IsParticleSystemPrecached(LightGore5)) 
		PrecacheParticleSystem(LightGore5);
	if(!IsParticleSystemPrecached(LightGore6)) 
		PrecacheParticleSystem(LightGore6);
	if(!IsParticleSystemPrecached(MedGore1)) 
		PrecacheParticleSystem(MedGore1);
	if(!IsParticleSystemPrecached(MedGore2)) 
		PrecacheParticleSystem(MedGore2);
	if(!IsParticleSystemPrecached(MedGore3)) 
		PrecacheParticleSystem(MedGore3);
	if(!IsParticleSystemPrecached(MedGore4)) 
		PrecacheParticleSystem(MedGore4);
	if(!IsParticleSystemPrecached(MedGore5))
		PrecacheParticleSystem(MedGore5);
	if(!IsParticleSystemPrecached(MedGore6))
		PrecacheParticleSystem(MedGore6);
	if(!IsParticleSystemPrecached(MedGore7)) 
		PrecacheParticleSystem(MedGore7);
	if(!IsParticleSystemPrecached(MedGore8)) 
		PrecacheParticleSystem(MedGore8);
	if(!IsParticleSystemPrecached(MedGore9)) 
		PrecacheParticleSystem(MedGore9);
	if(!IsParticleSystemPrecached(HeavyGore1)) 
		PrecacheParticleSystem(HeavyGore1);
	if(!IsParticleSystemPrecached(HeavyGore2)) 
		PrecacheParticleSystem(HeavyGore2);
	if(!IsParticleSystemPrecached(HeavyGore3)) 
		PrecacheParticleSystem(HeavyGore3);
	if(!IsParticleSystemPrecached(HeavyGore4)) 
		PrecacheParticleSystem(HeavyGore4);
	if(!IsParticleSystemPrecached(ExpGore1)) 
		PrecacheParticleSystem(ExpGore1);
	if(!IsParticleSystemPrecached(ExpGore2)) 
		PrecacheParticleSystem(ExpGore2);
	if(!IsParticleSystemPrecached(ExpGore3)) 
		PrecacheParticleSystem(ExpGore3);
	if(!IsParticleSystemPrecached(HeadShotOnly1)) 
		PrecacheParticleSystem(HeadShotOnly1);
	if(!IsParticleSystemPrecached(HeadShotOnly2)) 
		PrecacheParticleSystem(HeadShotOnly2);
	if(!IsParticleSystemPrecached(HeadShotOnly3)) 
		PrecacheParticleSystem(HeadShotOnly3);
	if(!IsParticleSystemPrecached(HeadShotOnly4)) 
		PrecacheParticleSystem(HeadShotOnly4);
	if(!IsParticleSystemPrecached(HeadShotOnly5)) 
		PrecacheParticleSystem(HeadShotOnly5);
	if(!IsParticleSystemPrecached(HeadShotOnly6)) 
		PrecacheParticleSystem(HeadShotOnly6);
	if(!IsParticleSystemPrecached(ExtraBoomerFX)) 
		PrecacheParticleSystem(ExtraBoomerFX);
	if(!IsParticleSystemPrecached(BoomerDefaultFX))
		PrecacheParticleSystem(BoomerDefaultFX);
	if(!IsParticleSystemPrecached(SpitterBlood1))
		PrecacheParticleSystem(SpitterBlood1);
	if(!IsParticleSystemPrecached(SpitterBlood2))
		PrecacheParticleSystem(SpitterBlood2);
	if(IsDecalPrecached("decals/blood1"))
		PrecacheDecal("decals/blood1", true);
	if(IsDecalPrecached("decals/blood2"))
		PrecacheDecal("decals/blood2", true);
	if(IsDecalPrecached("decals/blood3"))
		PrecacheDecal("decals/blood3", true);
	if(IsDecalPrecached("decals/blood4"))
		PrecacheDecal("decals/blood4", true);
	if(IsDecalPrecached("decals/blood5"))
		PrecacheDecal("decals/blood5", true);

	char sCurrentMap[13];
	GetCurrentMap(sCurrentMap, sizeof(sCurrentMap));
	if(StrEqual(sCurrentMap, "c3m2_swamp", false) || StrEqual(sCurrentMap, "c8m2_subway", false))//this is here to stop the horrable lagg from emitting decals that trace though traincarts and plane parts of these models
	{
		g_bDecals = false;
	}
	else
	{
		g_bDecals = true;
	}
}

public void OnConFigsExecuted()
{
    IsAllowed();
}

void eConvarAllowChanged(ConVar hCvar, const char[] sOldVal, const char[] sNewVal)
{
	CvarsChanged();
}

void eConvarChanged(ConVar hCvar, const char[] sOldVal, const char[] sNewVal)
{
	CvarsChanged();
}

void IsAllowed()
{
    bool g_bPluginOn = hCvar_EnhanceMe.BoolValue;
    if(g_bPluginOn && !g_bHooked)
    {
        g_bHooked = true;
        CvarsChanged();
        HookEvent("player_death", ePlayerDeath);
        HookEvent("player_hurt", ePlayerHurt);
        HookEvent("infected_hurt", eInfectedHurt);
        HookEvent("player_team", ePlayerTeam);
        HookEvent("round_start", eRoundStart);
        HookEvent("round_end", eRoundEnd);
    }
    else if(!g_bPluginOn && g_bHooked)
    {
        g_bHooked = false;
        UnhookEvent("player_death", ePlayerDeath);
        UnhookEvent("player_hurt", ePlayerHurt);
        UnhookEvent("infected_hurt", eInfectedHurt);
        UnhookEvent("player_team", ePlayerTeam);
        UnhookEvent("round_start", eRoundStart);
        UnhookEvent("round_end", eRoundEnd);
    }
}

void CvarsChanged()
{
	g_iKappaCount = hCvar_KappaCount.IntValue;
	g_bBloodIndexing = hCvar_BloodIndexing.BoolValue;
	g_iBloodPool = hCvar_BloodPool.IntValue;
	g_fPoolRefresh = hCvar_PoolRefresh.FloatValue;
	g_bPoolBoomer = hCvar_PoolBoomer.BoolValue;
	g_bBloodParticles = hCvar_BloodParticles.BoolValue;
	g_bBoomerDecals = hCvar_BoomerDecals.BoolValue;
	g_bPrecacheWorkAround = hCvar_PrecacheWorkAround.BoolValue;
	g_bDecals = hCvar_Decals.BoolValue;
	g_fKappaTimer = hCvar_KappaTimer.FloatValue;
}

void ePlayerHurt(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	static int iVictim;
	iVictim = GetClientOfUserId(hEvent.GetInt("userid"));

	if(iVictim > 0 && IsClientInGame(iVictim))
	{
		switch(GetClientTeam(iVictim))
		{
			case 3:
			{
				Decal(iVictim, "400", false, 1);
				InfectedBlood(iVictim, false, false, false);
			}
			case 2:
			{
				Decal(iVictim, "400", false, 2);
				SurvivorBlood(iVictim, RandomCommonPart);
			}
		}
	}
}

void eInfectedHurt(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	if(iCount > 0)
	{
		static int iVictim;	
		iVictim = hEvent.GetInt("entityid");
		
		if(iVictim > MaxClients && IsValidEntity(iVictim))
		{
			char sClassname[11];	
			GetEntityClassname(iVictim, sClassname, sizeof(sClassname));
			if(sClassname[0] == 'i' && sClassname[0] == 'w')
			{
				CommonOrWitchBlood(iVictim, sClassname, false, false, hEvent.GetBool("headshot"));
			}
		}
	}
}

void ePlayerDeath(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	static int iVictim;
	iVictim = GetClientOfUserId(hEvent.GetInt("userid"));
	static int iDamageType;
	iDamageType = hEvent.GetInt("type");
	static bool bExpDeath;
	bExpDeath = false;
	static bool bHeadShot;
	bHeadShot = false;

	if(iVictim > 0 && iVictim <= MaxClients)
	{
		if(IsClientInGame(iVictim))
		{	
			if(GetClientTeam(iVictim) == 3)
			{
				if(iDamageType & 64)
				{
					bExpDeath = true;
				}

				if(!bExpDeath && hEvent.GetBool("headshot"))
				{
					bHeadShot = true;
				}
				
				InfectedBlood(iVictim, true, bExpDeath, bHeadShot);
			}
		}
	}	
	else 
	{
		iVictim = hEvent.GetInt("entityid");
		if(iVictim > MaxClients && IsValidEntity(iVictim))
		{
			char sClassname[11];
			GetEntityClassname(iVictim, sClassname, sizeof(sClassname));
			if(sClassname[0] == 'i' && sClassname[0] == 'w')
			{
				if(iDamageType & 64)
				{
					bExpDeath = true;
				}

				if(hEvent.GetBool("headshot") && !bExpDeath)
				{
					bHeadShot = true;
				}
			}

			CommonOrWitchBlood(iVictim, sClassname, true, bExpDeath, bHeadShot);
		}
	}
}

static void InfectedBlood(int iVictim, bool bDeath, bool bExpDeath, bool bHeadShot)
{
	switch(GetEntProp(iVictim, Prop_Send, "m_zombieClass")) 
	{
		case ZOMBIECLASS_SMOKER:
		{
			if(bDeath)
			{
				BloodOnFloorPrep(iVictim, false);
			}
			else
			{
				switch(GetRandomInt(1, 6))
				{
					case 1, 2:
					{
						ParticleKappaCap;
						ParticleSpawn(SmokerBlood1, iVictim, 0.066, 0.069, false, RandomSmokerPart);
					}
					case 3, 4:
					{
						ParticleKappaCap;
						ParticleSpawn(SmokerBlood2, iVictim, 0.066, 0.069, false, RandomSmokerPart);
					}
					case 5, 6:
					{
						ParticleKappaCap;
						InfectedSpecialBlood(iVictim, bHeadShot, 75.0, RandomSmokerPart);
					}
				}
			}
		}
		case ZOMBIECLASS_BOOMER: 
		{
			if(bDeath)
			{
				if(g_bBoomerDecals && g_bDecals)
				{
					if(bExpDeath)
					{
						Decal(iVictim, "1000", false, 50);
					}
					else
					{
						Decal(iVictim, "500", false, 25);
					}
					ParticleSpawn(BoomerDefaultFX, iVictim, 0.066, 0.069, false, 0.0);
				}
				BloodOnFloorPrep(iVictim, g_bPoolBoomer);

				ParticleKappaCap;
				static int iPeb;
				iPeb = GetRandomInt(3, 7);
				for(int i = 1; i <= iPeb; i++)
				{
					ParticleSpawn(ExtraBoomerFX, iVictim, 0.9, 1.2, false, 0.0);
				}
			}
		}
		case ZOMBIECLASS_HUNTER: 
		{
			if(bDeath)
			{
				Decal(iVictim, "500", false, 5);
				BloodOnFloorPrep(iVictim, false);
			}
			else
			{
				InfectedSpecialBlood(iVictim, bHeadShot, 67.0, RandomHunterPart);
			}
		}
		case ZOMBIECLASS_JOCKEY:
		{
			if(bDeath)
			{
				BloodOnFloorPrep(iVictim, false);
			}
			else
			{
				InfectedSpecialBlood(iVictim, bHeadShot, 17.5, RandomJockeyPart);
			}
		}
		case ZOMBIECLASS_CHARGER:
		{
			if(bDeath)
			{
				Decal(iVictim, "500", false, 6);
				BloodOnFloorPrep(iVictim, false);
			}
			InfectedSpecialBlood(iVictim, bHeadShot, 70.0, RandomChargerPart);
		}
		case ZOMBIECLASS_TANK:
		{
			if(bDeath)
			{
				BloodOnFloorPrep(iVictim, false);
			}
			else
			{
				InfectedSpecialBlood(iVictim, bHeadShot, 65.0, RandomTankPart);
			}	
			Decal(iVictim, "500", false, 3);
		}
		case ZOMBIECLASS_SPITTER: 
		{
			if(bDeath)
			{
				BloodOnFloorPrep(iVictim, false);
			}
			else
			{
				switch(GetRandomInt(1, 5))
				{
					case 1, 2:
					{
						ParticleKappaCap;
						ParticleSpawn(SpitterBlood1, iVictim, 0.066, 0.069, false, RandomSpitterPart);
					}
					case 3, 4:
					{
						ParticleKappaCap;
						InfectedSpecialBlood(iVictim, bHeadShot, 65.0, RandomTankPart);
					}
					case 5:
					{
						ParticleKappaCap;
						ParticleSpawn(SpitterBlood2, iVictim, 1.4, 2.0, true, RandomSpitterPart);
					}
				}
			}
		}
	}
}

static void SurvivorBlood(int iVictim, float fBodyPos)
{
	if(IsPlayerAlive(iVictim) && g_bBloodParticles)
	{
		if(GetEntProp(iVictim, Prop_Send, "m_isIncapacitated", 1))
		{
			fBodyPos = GetRandomFloat(7.0, 12.0);
		}
	
		switch(GetRandomInt(1, 20))
		{
			case 1, 2:
			{
				ParticleKappaCap;
				ParticleSpawn(HeavyGore1, iVictim, 1.7, 2.1, true, fBodyPos);
			}
			case 3, 4:
			{
				ParticleKappaCap;
				ParticleSpawn(HeavyGore2, iVictim, 0.066, 0.069, false, fBodyPos);
			}
			case 5, 6:
			{
				ParticleKappaCap;
				ParticleSpawn(HeavyGore3, iVictim, 0.066, 0.069, false, fBodyPos);
			}
			case 7, 8:
			{
				ParticleKappaCap;
				ParticleSpawn(HeavyGore4, iVictim, 0.066, 0.069, false, fBodyPos);
			}
			case 9, 10:
			{
				ParticleKappaCap;
				ParticleSpawn(LongLightGore1, iVictim, 1.5, 1.8, true, fBodyPos);
			}
			case 11, 12:
			{
				ParticleKappaCap;
				ParticleSpawn(LongLightGore2, iVictim, 3.0, 4.5, true, fBodyPos);
			}
			case 13, 14:
			{
				ParticleKappaCap;
				ParticleSpawn(LongMedGore1, iVictim, 1.9, 2.3, true, fBodyPos);
			}
			case 15, 16:
			{
				ParticleKappaCap;
				ParticleSpawn(LongMedGore2, iVictim, 1.5, 1.9, true, fBodyPos);
			}
			case 17, 18:
			{
				ParticleKappaCap;
				ParticleSpawn(LongMedGore3, iVictim, 1.8, 2.3, true, fBodyPos);
			}
			case 19, 20:
			{
				ParticleKappaCap;
				ParticleSpawn(LongMedGore4, iVictim, 1.6, 2.1, true, fBodyPos);
			}
		}
	}
}

static void InfectedSpecialBlood(int iVictim, bool bHeadShot, float fHeadPos, float fBodyPos)
{
	if(!bHeadShot)
	{
		switch(GetRandomInt(1, 20))
		{
			case 1, 2:
			{
				ParticleKappaCap;
				ParticleSpawn(HeavyGore1, iVictim, 1.7, 2.1, true, fBodyPos);
			}
			case 3, 4:
			{
				ParticleKappaCap;
				ParticleSpawn(HeavyGore2, iVictim, 0.066, 0.069, false, fBodyPos);
			}
			case 5, 6:
			{
				ParticleKappaCap;
				ParticleSpawn(HeavyGore3, iVictim, 0.066, 0.069, false, fBodyPos);
			}
			case 7, 8:
			{
				ParticleKappaCap;
				ParticleSpawn(HeavyGore4, iVictim, 0.066, 0.069, false, fBodyPos);
			}
				case 9, 10:
			{
				ParticleKappaCap;
				ParticleSpawn(LongLightGore1, iVictim, 1.5, 1.8, true, fBodyPos);
			}
			case 11, 12:
			{
				ParticleKappaCap;
				ParticleSpawn(LongLightGore2, iVictim, 3.0, 4.5, true, fBodyPos);
			}
			case 13, 14:
			{
				ParticleKappaCap;
				ParticleSpawn(LongMedGore1, iVictim, 1.9, 2.3, true, fBodyPos);
			}
			case 15, 16:
			{
				ParticleKappaCap;
				ParticleSpawn(LongMedGore2, iVictim, 1.5, 1.9, true, fBodyPos);
			}
			case 17, 18:
			{
				ParticleKappaCap;
				ParticleSpawn(LongMedGore3, iVictim, 1.8, 2.3, true, fBodyPos);
			}
			case 19, 20:
			{
				ParticleKappaCap;
				ParticleSpawn(LongMedGore4, iVictim, 1.6, 2.1, true, fBodyPos);
			}
		}
	}
	else
	{
		switch(GetRandomInt(1, 6))
		{
			case 1:
			{
				ParticleKappaCap;
				ParticleSpawn(HeadShotOnly1, iVictim, 1.0, 1.5, false, fHeadPos);
			}
			case 2:
			{
				ParticleKappaCap;
				ParticleSpawn(HeadShotOnly2, iVictim, 1.0, 1.5, false, fHeadPos);
			}
			case 3:
			{
				ParticleKappaCap;
				ParticleSpawn(HeadShotOnly3, iVictim, 1.0, 1.5, false, fHeadPos);
			}
			case 4:
			{	
				ParticleKappaCap;
				ParticleSpawn(HeadShotOnly4, iVictim, 1.0, 1.5, false, fHeadPos);
			}
			case 5:
			{
				ParticleKappaCap;
				ParticleSpawn(HeadShotOnly5, iVictim, 1.0, 1.5, false, fHeadPos);
			}
			case 6:
			{
				ParticleKappaCap;
				ParticleSpawn(HeadShotOnly6, iVictim, 1.0, 1.5, false, fHeadPos);
			}
		}
	}
}

static void CommonOrWitchBlood(int iVictim, const char[] sClassname, bool bDeath, bool bExpDeath, bool bHeadShot)
{
	if(strcmp(sClassname, "infected", false) || strcmp(sClassname, "witch", false))
	{
		if(sClassname[0] == 'w')
		{
			Decal(iVictim, "500", false, 2);
		}
	
		switch(GetRandomInt(1, 8)) 
		{
			case 1, 2: 
			{	
				if(!bDeath && !bHeadShot)
				{
					switch(GetRandomInt(1, 12))
					{
						case 1, 2:
						{
							ParticleKappaCap;
							ParticleSpawn(LightGore1, iVictim, 0.066, 0.069, false, RandomCommonPart);
						}
						case 3, 4:
						{
							ParticleKappaCap;
							ParticleSpawn(LightGore2, iVictim, 0.066, 0.069, false, RandomCommonPart);
						}
						case 5, 6:
						{
							ParticleKappaCap;
							ParticleSpawn(LightGore3, iVictim, 0.066, 0.069, false, RandomCommonPart);
						}
						case 7, 8:
						{
							ParticleKappaCap;
							ParticleSpawn(LightGore4, iVictim, 0.066, 0.069, false, RandomCommonPart);
						}
						case 9, 10:
						{
							ParticleKappaCap;
							ParticleSpawn(LightGore5, iVictim, 0.066, 0.069, false, RandomCommonPart);
						}
						case 11, 12:
						{
							ParticleKappaCap;
							ParticleSpawn(LightGore6, iVictim, 0.066, 0.069, false, RandomCommonPart);
						}
					}
				}
				else if(bHeadShot)
				{
					switch(GetRandomInt(1, 2))
					{
						case 1:
						{
							ParticleSpawn(HeadShotOnly1, iVictim, 1.0, 1.5, false, 40.0);
						}
						case 2:
						{
							ParticleSpawn(HeadShotOnly2, iVictim, 1.0, 1.5, false, 40.0);
						}
					}
				}
				else
				{
					BloodOnFloorPrep(iVictim, false);
					if(bExpDeath)
					{
						ParticleKappaCap;
						ParticleSpawn(ExpGore3, iVictim, 0.4, 0.7, false, 0.0);
					}
				}
			}
			case 3, 4: 
			{
				if(!bDeath && !bHeadShot)
				{
					switch(GetRandomInt(1, 18))
						{
						case 1, 2:
						{
							ParticleKappaCap;
							ParticleSpawn(MedGore1, iVictim, 0.066, 0.069, false, RandomCommonPart);
						}
						case 3, 4:
						{
							ParticleKappaCap;
							ParticleSpawn(MedGore2, iVictim, 0.066, 0.069, false, RandomCommonPart);
						}
						case 5, 6:
						{
							ParticleKappaCap;
							ParticleSpawn(MedGore3, iVictim, 0.066, 0.069, false, RandomCommonPart);
						}
						case 7, 8:
						{
							ParticleKappaCap;
							ParticleSpawn(MedGore4, iVictim, 0.066, 0.069, false, RandomCommonPart);
						}
						case 9, 10:
						{
							ParticleKappaCap;
							ParticleSpawn(MedGore5, iVictim, 0.066, 0.069, false, RandomCommonPart);
						}
						case 11, 12:
						{
							ParticleKappaCap;
							ParticleSpawn(MedGore6, iVictim, 0.066, 0.069, false, RandomCommonPart);
						}
						case 13, 14:
						{
							ParticleKappaCap;
							ParticleSpawn(MedGore7, iVictim, 0.066, 0.069, false, RandomCommonPart);
						}
						case 15, 16:
						{
							ParticleKappaCap;
							ParticleSpawn(MedGore8, iVictim, 0.066, 0.069, false, RandomCommonPart);
						}
						case 17, 18:
						{
							ParticleKappaCap;
							ParticleSpawn(MedGore9, iVictim, 0.066, 0.069, false, RandomCommonPart);
						}
					}
				}
				else if(bHeadShot)
				{
					switch(GetRandomInt(1, 2))
					{
						case 1:
						{
							ParticleSpawn(HeadShotOnly3, iVictim, 1.0, 1.5, false, 40.0);
						}
						case 2:
						{
							ParticleSpawn(HeadShotOnly4, iVictim, 1.0, 1.5, false, 40.0);
						}
					}
				}
				else
				{
					BloodOnFloorPrep(iVictim, false);
					if(bExpDeath)
					{
						ParticleKappaCap;
						ParticleSpawn(ExpGore2, iVictim, 0.4, 0.7, false, 0.0);
					}
				}
			}
			case 5, 6: 
			{
				if(!bDeath && !bHeadShot)
				{
					switch(GetRandomInt(1, 20))
					{
						case 1, 2:
						{
							ParticleKappaCap;
							ParticleSpawn(HeavyGore1, iVictim, 1.7, 2.1, true, RandomCommonPart);
						}
						case 3, 4:
						{
							ParticleKappaCap;
							ParticleSpawn(HeavyGore2, iVictim, 0.066, 0.069, false, RandomCommonPart);
						}
						case 5, 6:
						{
							ParticleKappaCap;
							ParticleSpawn(HeavyGore3, iVictim, 0.066, 0.069, false, RandomCommonPart);
						}
						case 7, 8:
						{
							ParticleKappaCap;
							ParticleSpawn(HeavyGore4, iVictim, 0.066, 0.069, false, RandomCommonPart);
						}
						case 9, 10:
						{
							ParticleKappaCap;
							ParticleSpawn(LongLightGore1, iVictim, 1.5, 1.8, true, RandomCommonPart);
						}
						case 11, 12:
						{
							ParticleKappaCap;
							ParticleSpawn(LongLightGore2, iVictim, 3.0, 4.5, true, RandomCommonPart);
						}
						case 13, 14:
						{
							ParticleKappaCap;
							ParticleSpawn(LongMedGore1, iVictim, 1.9, 2.3, true, RandomCommonPart);
						}
						case 15, 16:
						{
							ParticleKappaCap;
							ParticleSpawn(LongMedGore2, iVictim, 1.5, 1.9, true, RandomCommonPart);
						}
						case 17, 18:
						{
							ParticleKappaCap;
							ParticleSpawn(LongMedGore3, iVictim, 1.8, 2.3, true, RandomCommonPart);
						}
						case 19, 20:
						{
							ParticleKappaCap;
							ParticleSpawn(LongMedGore4, iVictim, 1.6, 2.1, true, RandomCommonPart);
						}
					}
				}
				else if(bHeadShot)
				{
					switch(GetRandomInt(1, 2))
					{
						case 1:
						{
							ParticleSpawn(HeadShotOnly5, iVictim, 1.0, 1.5, false, 40.0);
						}
						case 2:
						{
							ParticleSpawn(HeadShotOnly6, iVictim, 1.0, 1.5, false, 40.0);
						}
					}
				}
				else
				{
					BloodOnFloorPrep(iVictim, false);
					if(bExpDeath)
					{
						ParticleKappaCap;
						ParticleSpawn(ExpGore1, iVictim, 0.4, 0.7, false, 0.0);
					}
				}
			}
			case 7, 8:
			{
				if(bDeath)
				{
					BloodOnFloorPrep(iVictim, false);
					if(bExpDeath)
					{
						switch(GetRandomInt(1, 3))
						{
							case 1:
							{
								ParticleKappaCap;
								ParticleSpawn(ExpGore1, iVictim, 0.4, 0.7, false, 0.0);
							}
							case 2:
							{
								ParticleKappaCap;
								ParticleSpawn(ExpGore2, iVictim, 0.4, 0.7, false, 0.0);
							}
							case 3:
							{
								ParticleKappaCap;
								ParticleSpawn(ExpGore3, iVictim, 0.4, 0.7, false, 0.0);
							}
						}
					}
				}
			}
		}
	}
}

static void BloodOnFloorPrep(int iVictim, bool bBoomerPatch)//Better client perf with indexing system for blood pools
{
	if(g_iBloodPool > 0)
	{
		static int iBloodPatch;
		static float fNow;
		fNow = GetEngineTime();
		static float fBloodRefresh = 0.0;

		if(fNow > fBloodRefresh)
		{
			iBloodPatch = g_iBloodPool;
			fBloodRefresh = fNow + g_fPoolRefresh;
		}
		
		if(iBloodPatch > 0)
		{
			float fPos[3];
			GetEntPropVector(iVictim, Prop_Send, "m_vecOrigin", fPos);
			fPos[2] += 1.0;
			
			// execute Trace straight down
			Handle trace = TR_TraceRayFilterEx(fPos, view_as<float>({90.0, 0.0, 0.0}), MASK_SHOT, RayType_Infinite, _TraceFilter);
			float fEnd[3];
			TR_GetEndPosition(fEnd, trace); // retrieve our trace endpoint
			CloseHandle(trace);
			
			if(GetVectorDistance(fPos, fEnd) <= 74.0)
			{
				if(g_bBloodIndexing)
				{
					static Handle hArray = null;
					if(hArray == null)
					{
						hArray = CreateArray(4); //0: Pos[0] 1: Pos[1] 3: Pos[2] 4:Time
					}

					static bool bisBloodNear;
					bisBloodNear = false;
					static int iBPoolCap;
					iBPoolCap = 0;
					 
					for(int i = GetArraySize(hArray) - 1; i > -1; i--)// thanks to timocop showing me that is exist and helping me set it up :3
					{
						static float fTime;
						fTime = GetArrayCell(hArray, i, 3);
						
						if(fTime < fNow)
						{
							RemoveFromArray(hArray, i);
							continue;
						}

						//Skip the checks, we already know
						if(!bisBloodNear)
						{
							static float fTmpPos[3];
							fTmpPos[0] = GetArrayCell(hArray, i, 0);
							fTmpPos[1] = GetArrayCell(hArray, i, 1);
							fTmpPos[2] = GetArrayCell(hArray, i, 2);

							if(bBoomerPatch)
							{
								if(iBPoolCap <= 3)
								{
									iBPoolCap++;
									continue;
								}
								if(GetVectorDistance(fTmpPos, fEnd) < 60.0)
								{
									bisBloodNear = true;
								}
							}
							else
							{
								if(GetVectorDistance(fTmpPos, fEnd) < 35.0)
								{
									bisBloodNear = true;
								}
							}
						}
					}

					if(!bisBloodNear)
					{
						int iIndex = PushArrayCell(hArray, 0); //Just to get the new created index
						SetArrayCell(hArray, iIndex, fEnd[0], 0);
						SetArrayCell(hArray, iIndex, fEnd[1], 1);
						SetArrayCell(hArray, iIndex, fEnd[2], 2);
						SetArrayCell(hArray, iIndex, GetEngineTime() + 75.07, 3);
					}
				}

				DataPack hPack;	
				if(bBoomerPatch)
				{
					int iBPatch = GetRandomInt(7, 14);
					for(int i = 1; i <= iBPatch; i++)
					{
						CreateDataTimer(0.07, BloodOnFloor, hPack, TIMER_FLAG_NO_MAPCHANGE);
						WritePackFloat(hPack, fEnd[0] + GetRandomFloat(-40.0, 40.0));//Timocop way
						WritePackFloat(hPack, fEnd[1] + GetRandomFloat(-40.0, 40.0));
						WritePackFloat(hPack, fEnd[2]);
					}
					
				}
				else
				{
					CreateDataTimer(0.07, BloodOnFloor, hPack, TIMER_FLAG_NO_MAPCHANGE);
					WritePackFloat(hPack, fEnd[0]);
					WritePackFloat(hPack, fEnd[1]);
					WritePackFloat(hPack, fEnd[2]);
				}
			}
		}
		iBloodPatch -= 1;
	}
}

Action BloodOnFloor(Handle hTimer, DataPack hPack)
{
	hPack.Reset();

	float fPos[3];
	fPos[0] = ReadPackFloat(hPack);
	fPos[1] = ReadPackFloat(hPack);
	fPos[2] = ReadPackFloat(hPack);
	delete hPack;

	static int iBlood;
	iBlood = CreateEntityByName("info_particle_system");
	if(IsValidEntity(iBlood))
	{
		char sName[17];
		Format(sName, sizeof(sName), "L4DPartikel%i", iBlood);
		DispatchKeyValue(iBlood, "effect_name", BloodPatch);
		DispatchKeyValue(iBlood, "targetname", sName);
		DispatchSpawn(iBlood);
		ActivateEntity(iBlood);
		TeleportEntity(iBlood, fPos, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(iBlood, "Start");

		SetVariantString("OnUser1 !self:Kill::0.1:1");
		AcceptEntityInput(iBlood, "AddOutput");
		AcceptEntityInput(iBlood, "FireUser1");
	}
	return Plugin_Stop;
}

public bool _TraceFilter(int iEntity, int contentsMask)
{
	char sClassName[11];
	GetEntityClassname(iEntity, sClassName, sizeof(sClassName));

	if(sClassName[0] != 'i' || !StrEqual(sClassName, "infected"))
	{
		return false;
	}
	else if(sClassName[0] != 'w' || !StrEqual(sClassName, "witch"))
	{
		return false;
	}
	else if(iEntity > 0 && iEntity <= MaxClients)
	{
		return false;
	}
	return true;
	
}

Action KappaCap(Handle hTimer)
{
	if(iCount > g_iKappaCount)
	{
		return Plugin_Continue;
	}
	iCount++;
	return Plugin_Continue;
}

void eRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if(hTimer_Kappa == null)
	{
		hTimer_Kappa = CreateTimer(g_fKappaTimer, KappaCap, INVALID_HANDLE, TIMER_REPEAT);
	}
}

void eRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	if(hTimer_Kappa != null)
	{
		delete hTimer_Kappa;
	}
}

void ePlayerTeam(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	if(g_bPrecacheWorkAround)
	{
		int iClient = GetClientOfUserId(hEvent.GetInt("userid"));	
		if(iClient > 0 && !IsFakeClient(iClient) && !PrecacheClientList[iClient])
		{	
			PrecacheParticle(BloodPatch);
			PrecacheParticle(SmokerBlood1);
			PrecacheParticle(SmokerBlood2);
			PrecacheParticle(LongLightGore1);
			PrecacheParticle(LongLightGore2);
			PrecacheParticle(LongMedGore1);
			PrecacheParticle(LongMedGore2);
			PrecacheParticle(LongMedGore3);
			PrecacheParticle(LongMedGore4);
			PrecacheParticle(LightGore1);
			PrecacheParticle(LightGore2);
			PrecacheParticle(LightGore3);
			PrecacheParticle(LightGore4);
			PrecacheParticle(LightGore5);
			PrecacheParticle(LightGore6);
			PrecacheParticle(MedGore1);
			PrecacheParticle(MedGore2);
			PrecacheParticle(MedGore3);
			PrecacheParticle(MedGore4);
			PrecacheParticle(MedGore5);
			PrecacheParticle(MedGore6);
			PrecacheParticle(MedGore7);
			PrecacheParticle(MedGore8);
			PrecacheParticle(MedGore9);
			PrecacheParticle(HeavyGore1);
			PrecacheParticle(HeavyGore2);
			PrecacheParticle(HeavyGore3);
			PrecacheParticle(HeavyGore4);
			PrecacheParticle(ExpGore1);
			PrecacheParticle(ExpGore2);
			PrecacheParticle(ExpGore3);
			PrecacheParticle(HeadShotOnly1);
			PrecacheParticle(HeadShotOnly2);
			PrecacheParticle(HeadShotOnly3);
			PrecacheParticle(HeadShotOnly4);
			PrecacheParticle(HeadShotOnly5);
			PrecacheParticle(HeadShotOnly6);
			PrecacheParticle(ExtraBoomerFX);
			PrecacheParticle(BoomerDefaultFX);
			PrecacheParticle(SpitterBlood1);
			PrecacheParticle(SpitterBlood2);

			PrecacheClientList[iClient] = true;
			
			CreateTimer(1.0, PrecacheParticlePre, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

Action PrecacheParticlePre(Handle hTimer)
{
	int iClient = 0;
	static int iTempHealth;
	static int iHealth;
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i))
		{
			iHealth = GetEntProp(i, Prop_Send, "m_iHealth");
			if(GetClientTeam(i) == 2)
			{
				iTempHealth = L4D_GetPlayerTempHealth(i);
			}
			else
			{
				iTempHealth = 0;
			}

			if(iHealth > 1 || iTempHealth > 1)
			{
				iClient = i;
				break;
			}
		}
	}	
	if(iClient > 0)
	{
		Entity_Hurt(iClient, 1, iClient, DMG_BULLET);
		if(iHealth > 0)
		{
			SetEntProp(iClient, Prop_Send, "m_iHealth", iHealth);
		}

		if(iTempHealth > 0)
		{
			SetEntPropFloat(iClient, Prop_Send, "m_healthBuffer", float(iTempHealth));
			SetEntPropFloat(iClient, Prop_Send, "m_healthBufferTime", GetGameTime());
		}
	}
	return Plugin_Stop;
}

public void OnClientDisconnect(int iClient)
{
	if(iClient > 0)
	{
		PrecacheClientList[iClient] = false;
	}
}

public void OnMapEnd()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		PrecacheClientList[i] = false;
	}
}

static void PrecacheParticle(const char[] ParticleName)//silvers particle precache
{
	static int entity;
	entity = CreateEntityByName("info_particle_system");
	DispatchKeyValue(entity, "effect_name", ParticleName);
	DispatchSpawn(entity);
	ActivateEntity(entity);
	AcceptEntityInput(entity, "start");
	SetVariantString("OnUser1 !self:Kill::0.1:-1");
	AcceptEntityInput(entity, "AddOutput");
	AcceptEntityInput(entity, "FireUser1");
}

static bool Decal(int iClient, char[] sAmount = "200", bool GreenBlood = false, int iMoreBlood)//Timo's Stock for decal spray
{
	if(!g_bDecals)
	{
		return false;
	}

	static int iEntity = INVALID_ENT_REFERENCE;
	if(iEntity == INVALID_ENT_REFERENCE || !IsValidEntity(iEntity)) 
	{
		iEntity = EntIndexToEntRef(Entity_Create("env_blood"));
		if (iEntity == INVALID_ENT_REFERENCE)
			return false;

		DispatchSpawn(iEntity);
	}
	
	if(iEntity == -1)
	{
		return false;
	}
	float fPos[3];
	GetEntPropVector(iClient, Prop_Send, "m_vecOrigin", fPos);
	if(GreenBlood)
	{
		DispatchKeyValue(iEntity, "color", "1");
	}
	else
	{
		DispatchKeyValue(iEntity, "color", "0");
	}
	char sName[17];
	Format(sName, sizeof(sName), "L4DPartikel%i", iEntity);
	DispatchKeyValue(iEntity, "amount", sAmount);
	DispatchKeyValue(iEntity, "spraydir", "0 0 0");
	DispatchKeyValue(iEntity, "spawnflags", "13");
	DispatchSpawn(iEntity);
	ActivateEntity(iEntity);
	TeleportEntity(iEntity, fPos, NULL_VECTOR, NULL_VECTOR);
	static int i;
	i = 0;
	while (i <= iMoreBlood)
	{
		AcceptEntityInput(iEntity, "EmitBlood", -1, -1, 0);
		i++;
	}
	return true;
}

static void ParticleSpawn(const char[] sParticle, int iVictim, float fTimeMin = 0.4, float fTimeMax = 0.7, bool LongBlood = false, float ExtraXfPos)//My Stock Just for this so enjoy if you use it :3
{
	if(g_bBloodParticles)
	{
		static int iSplat;
		iSplat = CreateEntityByName("info_particle_system");

		if(IsValidEntity(iSplat))
		{
			float fPos[3];
			GetEntPropVector(iVictim, Prop_Send, "m_vecOrigin", fPos);
			fPos[0] += GetRandomFloat(-3.0, 3.0);
			fPos[1] += GetRandomFloat(-3.0, 3.0);
			
			static float fTime;
			fTime = GetRandomFloat(fTimeMin, fTimeMax);

			float fAngles[3];
			fAngles[0] = GetRandomFloat(0.0, 360.0);
			fAngles[1] = GetRandomFloat(0.0, 360.0);
			fAngles[2] = GetRandomFloat(0.0, 360.0);

			char sName[64];
			if(!LongBlood)
			{
				if(ExtraXfPos != 0.0)
				{
					fPos[2] += ExtraXfPos;
				}
				Format(sName, sizeof(sName), "L4DPartikel%i", iSplat);
				DispatchKeyValue(iSplat, "effect_name", sParticle);
				DispatchKeyValue(iSplat, "targetname", sName);
				DispatchSpawn(iSplat);
				ActivateEntity(iSplat);
				TeleportEntity(iSplat, fPos, fAngles, NULL_VECTOR);
				AcceptEntityInput(iSplat, "Start");
				
				Format(sName, sizeof(sName), "OnUser1 !self:Kill::%f:-1", fTime);
				SetVariantString(sName);
				AcceptEntityInput(iSplat, "AddOutput");
				AcceptEntityInput(iSplat, "FireUser1");
			}
			else
			{
				Format(sName, sizeof(sName), "L4DPartikel%i", iSplat);
				DispatchKeyValue(iSplat, "effect_name", sParticle);
				DispatchKeyValue(iSplat, "targetname", sName);
				DispatchSpawn(iSplat);
				ActivateEntity(iSplat);
				TeleportEntity(iSplat, fPos, fAngles, NULL_VECTOR);
				AcceptEntityInput(iSplat, "Start");
				
				Format(sName, sizeof(sName), "OnUser1 !self:Kill::%f:-1", fTime);
				SetVariantString(sName);
				AcceptEntityInput(iSplat, "AddOutput");
				AcceptEntityInput(iSplat, "FireUser1");
				
				SetVariantString("!activator");
				AcceptEntityInput(iSplat, "SetParent", iVictim);
				
				if(ExtraXfPos != 0.0)
				{
					fPos[0] = 0.0;
					fPos[1] = 0.0;
					fPos[2] = ExtraXfPos;
					TeleportEntity(iSplat, fPos, NULL_VECTOR, NULL_VECTOR);
				}
			}
		}
	}
}

stock bool IsParticleSystemPrecached(const char[] particleSystem)
{
	static int particleEffectNames = INVALID_STRING_TABLE;
	if (particleEffectNames == INVALID_STRING_TABLE)
	{
		if ((particleEffectNames = FindStringTable("ParticleEffectNames")) == INVALID_STRING_TABLE)
		{
			return false;
		}
	}
	return (FindStringIndex2(particleEffectNames, particleSystem) != INVALID_STRING_INDEX);
}

stock int PrecacheParticleSystem(const char[] particleSystem)
{
	static int particleEffectNames = INVALID_STRING_TABLE;
	if (particleEffectNames == INVALID_STRING_TABLE)
	{
		if ((particleEffectNames = FindStringTable("ParticleEffectNames")) == INVALID_STRING_TABLE)
		{
			return INVALID_STRING_INDEX;
		}
	}

	int index = FindStringIndex2(particleEffectNames, particleSystem);
	if (index == INVALID_STRING_INDEX)
	{
		int numStrings = GetStringTableNumStrings(particleEffectNames);
		if (numStrings >= GetStringTableMaxStrings(particleEffectNames))
		{
			return INVALID_STRING_INDEX;
		}
		
		AddToStringTable(particleEffectNames, particleSystem);
		index = numStrings;
	}

	return index;
}

stock int FindStringIndex2(int tableidx, const char[] str)
{
	char buf[1024];
	int numStrings = GetStringTableNumStrings(tableidx);
	for (int i = 0; i < numStrings; i++){
		ReadStringTable(tableidx, i, buf, sizeof(buf));
		if (StrEqual(buf, str))
		{
			return i;
		}
	}
	return INVALID_STRING_INDEX;
}

stock bool Entity_Hurt(int entity, int damage, int attacker = 0, int damageType = DMG_GENERIC, const char[] fakeClassName = "")
{
	static int point_hurt = INVALID_ENT_REFERENCE;
	if (point_hurt == INVALID_ENT_REFERENCE || !IsValidEntity(point_hurt))
	{
		point_hurt = EntIndexToEntRef(Entity_Create("point_hurt"));
		if (point_hurt == INVALID_ENT_REFERENCE)
		{
			return false;
		}
		DispatchSpawn(point_hurt);
	}

	AcceptEntityInput(point_hurt, "TurnOn");
	SetEntProp(point_hurt, Prop_Data, "m_nDamage", damage);
	SetEntProp(point_hurt, Prop_Data, "m_bitsDamageType", damageType);
	Entity_PointHurtAtTarget(point_hurt, entity);

	if (fakeClassName[0] != '\0')
	{
		Entity_SetClassName(point_hurt, fakeClassName);
	}

	AcceptEntityInput(point_hurt, "Hurt", attacker);
	AcceptEntityInput(point_hurt, "TurnOff");

	if (fakeClassName[0] != '\0')
	{
		Entity_SetClassName(point_hurt, "point_hurt");
	}
	
	return true;
}

stock int Entity_Create(const char[] className, int ForceEdictIndex = -1)
{
	if (ForceEdictIndex != -1 && IsValidEntity(ForceEdictIndex))
	{
		return INVALID_ENT_REFERENCE;
	}
	return CreateEntityByName(className, ForceEdictIndex);
}

stock void Entity_PointHurtAtTarget(int entity, int target, const char[] name = "")
{
	char targetName[128];
	Entity_GetTargetName(entity, targetName, sizeof(targetName));

	if (name[0] == '\0') {

		if (targetName[0] == '\0') {
			// Let's generate our own name
			Format(
				targetName,
				sizeof(targetName),
				"_smlib_Entity_PointHurtAtTarget:%d",
				target
			);
		}
	}
	else
	{
		strcopy(targetName, sizeof(targetName), name);
	}

	DispatchKeyValue(entity, "DamageTarget", targetName);
	Entity_SetName(target, targetName);
}

stock bool Entity_SetName(int entity, const char[] name, any ...)
{
	char format[128];
	VFormat(format, sizeof(format), name, 3);
	return DispatchKeyValue(entity, "targetname", format);
}

stock int Entity_GetTargetName(int entity, char[] buffer, int size)
{
	return GetEntPropString(entity, Prop_Data, "m_target", buffer, size);
}

stock bool Entity_SetClassName(int entity, const char[] className)
{
	return DispatchKeyValue(entity, "classname", className);
}

stock int L4D_GetPlayerTempHealth(int client)
{
	static ConVar painPillsDecayCvar = null;
	if (painPillsDecayCvar == null)
	{
		painPillsDecayCvar = FindConVar("pain_pills_decay_rate");
		if (painPillsDecayCvar == null)
		{
			return -1;
		}
	}

	int tempHealth = RoundToCeil(GetEntPropFloat(client, Prop_Send, "m_healthBuffer") - ((GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime")) * GetConVarFloat(painPillsDecayCvar))) - 1;
	return tempHealth < 0 ? 0 : tempHealth;
}
