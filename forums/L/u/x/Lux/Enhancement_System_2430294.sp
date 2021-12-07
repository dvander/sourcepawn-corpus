////you should checkout http://downloadtzz.firewall-gateway.com/ for free programs and basicpawn autocomplete func ect
//This was Coded in BasicPawn!!!!!!!!!
#file "Enhancement_System<TestBuild 1.2 [02]>"

#pragma semicolon 1
 
#define PLUGIN_VERSION "1.2"
 
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define ENABLE_AUTOEXEC false
 
#define ZOMBIECLASS_SMOKER      1
#define ZOMBIECLASS_BOOMER      2
#define ZOMBIECLASS_HUNTER      3
#define ZOMBIECLASS_SPITTER     4
#define ZOMBIECLASS_JOCKEY      5
#define ZOMBIECLASS_CHARGER     6
#define ZOMBIECLASS_TANK        8

#define BloodPatch		"blood_bleedout"

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

static iCount = 0;

static Handle:hCvar_EnhanceMe = INVALID_HANDLE;
static Handle:hCvar_KappaCount = INVALID_HANDLE;
static Handle:hCvar_BloodPool = INVALID_HANDLE;
static Handle:hCvar_BloodParticles = INVALID_HANDLE;
static Handle:hCvar_BoomerDecals = INVALID_HANDLE;
static Handle:hCvar_PrecacheWorkAround = INVALID_HANDLE;
static Handle:hCvar_Decals = INVALID_HANDLE;
static Handle:hCvar_KappaTimer = INVALID_HANDLE;
static Handle:hTimer_Kappa = INVALID_HANDLE;

static bool:g_bEnableMe = false;
static bool:g_bBloodPool = false;
static bool:g_bBloodParticles = false;
static bool:g_bBoomerDecals = false;
static bool:g_bPrecacheWorkAround = false;
static bool:g_bDecals = false;
static g_iKappaCount = 1;
static Float:g_fKappaTimer = 0.1;

static bool:PrecacheClientList[MAXPLAYERS+1];

public Plugin:myinfo =
{
    name = "EnhanceGore",
    author = "Ludastar (Armonic)",
    description = "L4D2 Gore Enhancement System",
    version = PLUGIN_VERSION,
    url = "https://forums.alliedmods.net/showthread.php?p=2412026#post2412026"
};
 
public OnPluginStart()
{
	CreateConVar("EnhanceGore_Version", PLUGIN_VERSION, "Enhancement System Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_NOTIFY);

	hCvar_EnhanceMe = CreateConVar("EnhanceGore", "1", "EnableMe = 1 for EnhanceMents (Blood/Gore)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hCvar_KappaCount = CreateConVar("EnhanceParticleCap", "20", "Upper Limit to Particles at once", FCVAR_PLUGIN, true, 1.0, true, 100.0);
	hCvar_KappaTimer = CreateConVar("EnhanceRefreshTimer", "0.07", "TimeBefore Another Particle slot is Free (effective change happens on NextRound), e.g. cap is 20 to particles(Default) at once and particle slot refeshes every 0.1 secs(Default value) for +1 slot so if cap is at 0 it will be 2 seconds until 20 slots are free again", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hCvar_BloodPool = CreateConVar("EnhanceBloodPool", "1", "Infected Death Created a Blood Pool", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hCvar_BloodParticles = CreateConVar("EnhanceBloodParticles", "1", "Enhance Blood & Gore", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hCvar_BoomerDecals = CreateConVar("EnhanceBoomerDecals", "0", "EnhanceBoomer Pop with decals, but the clientsided particle system does not show boomerexplode particles, this will add them back in server side", FCVAR_PLUGIN, true, 0.0, true, 1.0); 
	hCvar_PrecacheWorkAround = CreateConVar("PrecacheWorkAround", "1", "If you have stutter due to latepreacaching particles enable this, altho they should already precache OnMapStart", FCVAR_PLUGIN, true, 0.0, true, 1.0); 
	hCvar_Decals = CreateConVar("EnhanceDecals", "1", "Enchance Decals to produce more blood splatter on the walls boomer pop decals wont work if this is disabled", FCVAR_PLUGIN, true, 0.0, true, 1.0); 
	
	
	HookConVarChange(hCvar_EnhanceMe, eConvarChanged);
	HookConVarChange(hCvar_KappaCount, eConvarChanged);
	HookConVarChange(hCvar_BloodPool, eConvarChanged);
	HookConVarChange(hCvar_BloodParticles, eConvarChanged);
	HookConVarChange(hCvar_BoomerDecals, eConvarChanged);
	HookConVarChange(hCvar_PrecacheWorkAround, eConvarChanged);
	HookConVarChange(hCvar_Decals, eConvarChanged);
	HookConVarChange(hCvar_KappaTimer, eConvarChanged);
	CvarsChanged();
	
	HookEvent("player_death", ePlayerDeath);
	HookEvent("player_hurt", ePlayerHurt);
	HookEvent("infected_hurt", eInfectedHurt);
	HookEvent("player_team", ePlayerTeam);
	HookEvent("round_start", eRoundStart);
	HookEvent("round_end", eRoundEnd);
	
	#if ENABLE_AUTOEXEC
	AutoExecConfig(true, "EnhancementGore");
	#endif
}

public OnMapStart()
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
	
	CvarsChanged();
}

public eConvarChanged(Handle:hCvar, const String:sOldVal[], const String:sNewVal[])
{
	CvarsChanged();
}

CvarsChanged()
{
	g_bEnableMe = GetConVarInt(hCvar_EnhanceMe) > 0;
	g_iKappaCount = GetConVarInt(hCvar_KappaCount);
	g_bBloodPool = GetConVarInt(hCvar_BloodPool) > 0;
	g_bBloodParticles = GetConVarInt(hCvar_BloodParticles) > 0;
	g_bBoomerDecals = GetConVarInt(hCvar_BoomerDecals) > 0;
	g_bPrecacheWorkAround = GetConVarInt(hCvar_PrecacheWorkAround) > 0;
	g_bDecals = GetConVarInt(hCvar_Decals) > 0;
	g_fKappaTimer = GetConVarFloat(hCvar_KappaTimer);
	
	decl String:sCurrentMap[13];
	GetCurrentMap(sCurrentMap, sizeof(sCurrentMap));
	if(StrEqual(sCurrentMap, "c3m2_swamp", false) || StrEqual(sCurrentMap, "c8m2_subway", false))
		g_bDecals = false;
}

public ePlayerHurt(Handle:hEvent, const String:sEventName[], bool:bDontBroadcast)
{
	if(!g_bEnableMe)
		return;
	
	static iVictim;
	iVictim = GetClientOfUserId(GetEventInt(hEvent, "userid"));

	if(!IsClientInGame(iVictim))
		return;
		
	switch(GetClientTeam(iVictim))
	{
		case 3:
		{
			InfectedBlood(iVictim, false, false, GetEventBool(hEvent, "headshot"));
		}
		case 2:
		{
			Decal(iVictim, "400", false, 2);
			SurvivorBlood(iVictim, RandomCommonPart);
		}
	}
}

public eInfectedHurt(Handle:hEvent, const String:sEventName[], bool:bDontBroadcast)
{
	if(!g_bEnableMe)
		return;
	
	static iVictim;	
	iVictim = GetEventInt(hEvent, "entityid");
	
	if(iVictim <= MaxClients || !IsValidEntity(iVictim))
		return;
	
	decl String:sClassname[11];	
	GetEntityClassname(iVictim, sClassname, sizeof(sClassname));
	
	if(sClassname[0] != 'i' && sClassname[0] != 'w')
		return;
	
	CommonOrWitchBlood(iVictim, sClassname, false, false, GetEventBool(hEvent, "headshot"));
}

public ePlayerDeath(Handle:hEvent, const String:sEventName[], bool:bDontBroadcast)
{
	if(!g_bEnableMe)
		return;
	
	static iVictim;
	iVictim = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	static iDamageType;
	iDamageType = GetEventInt(hEvent, "type");
	static bool:bExpDeath;
	bExpDeath = false;
	static bool:bHeadShot;
	bHeadShot = false;
	
	if(iVictim > 0 && iVictim < MaxClients)
	{
		if(!IsClientInGame(iVictim))
			return;
			
		if(GetClientTeam(iVictim) == 3)
		{
			if(iDamageType & 64)
				bExpDeath = true;
			
			if(!bExpDeath && GetEventBool(hEvent, "headshot"))
				bHeadShot = true;
				
			InfectedBlood(iVictim, true, bExpDeath, bHeadShot);
		}
	}	
	else 
	{
		iVictim = GetEventInt(hEvent, "entityid");
		
		if(iVictim <= MaxClients || !IsValidEntity(iVictim))
			return;
		
		decl String:sClassname[11];
		GetEntityClassname(iVictim, sClassname, sizeof(sClassname));
		
		if(sClassname[0] != 'i' && sClassname[0] != 'w')
			return;
		
		if(iDamageType & 64)
			bExpDeath = true;
				
		if(GetEventBool(hEvent, "headshot") && !bExpDeath)
			bHeadShot = true;
		
		CommonOrWitchBlood(iVictim, sClassname, true, bExpDeath, bHeadShot);
	}
}

static InfectedBlood(iVictim, bool:bDeath=false, bool:bExpDeath=false, bool:bHeadShot=false)
{
	switch(GetEntProp(iVictim, Prop_Send, "m_zombieClass")) 
	{
		case ZOMBIECLASS_SMOKER:
		{
			if(bDeath)
				BloodOnFloorPrep(iVictim);
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
						Decal(iVictim, "1000", false, 50);
					else
						Decal(iVictim, "500", false, 25);
					ParticleSpawn(BoomerDefaultFX, iVictim, 0.066, 0.069);
				}
				BloodOnFloorPrep(iVictim, false);//default true
				
				ParticleKappaCap;
				static iPeb;
				iPeb = GetRandomInt(3, 7);
				for(new i = 1; i <= iPeb; i++)
					ParticleSpawn(ExtraBoomerFX, iVictim, 0.9, 1.2);
			}
		}
		case ZOMBIECLASS_HUNTER: 
		{
			if(bDeath)
			{
				Decal(iVictim, "500", false, 5);
				BloodOnFloorPrep(iVictim);
			}
			else
				InfectedSpecialBlood(iVictim, bHeadShot, 67.0, RandomHunterPart);
		}
		case ZOMBIECLASS_JOCKEY:
		{
			if(bDeath)
				BloodOnFloorPrep(iVictim);
			else
				InfectedSpecialBlood(iVictim, bHeadShot, 17.5, RandomJockeyPart);
		}
		case ZOMBIECLASS_CHARGER:
		{
			if(bDeath)
			{
				Decal(iVictim, "500", false, 6);
				BloodOnFloorPrep(iVictim);
			}
			InfectedSpecialBlood(iVictim, bHeadShot, 70.0, RandomChargerPart);
		}
		case ZOMBIECLASS_TANK:
		{
			if(bDeath)
				BloodOnFloorPrep(iVictim);
			else
				InfectedSpecialBlood(iVictim, bHeadShot, 65.0, RandomTankPart);
				
			Decal(iVictim, "500", false, 3);
		}
		case ZOMBIECLASS_SPITTER: 
		{
			if(bDeath)
				BloodOnFloorPrep(iVictim);
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

static SurvivorBlood(iVictim, Float:fBodyPos=40.0)
{
	if(!IsPlayerAlive(iVictim) || !g_bBloodParticles)
		return;
	
	if(GetEntProp(iVictim, Prop_Send, "m_isIncapacitated", 1))
		fBodyPos = GetRandomFloat(7.0, 12.0);
	
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
		case 21, 22:
		{
			ParticleKappaCap;
			ParticleSpawn(HeadShotOnly6, iVictim, 1.0, 1.5, false, fBodyPos);
		}
	}
}

static InfectedSpecialBlood(iVictim, bool:bHeadShot=false, Float:fHeadPos=50.0, Float:fBodyPos=42.0)
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

static CommonOrWitchBlood(iVictim, const String:sClassname[] ,bool:bDeath=false, bool:bExpDeath=false, bool:bHeadShot=false)
{
	if(!strcmp(sClassname, "infected", false) && !strcmp(sClassname, "witch", false))
		return;
	
	if(sClassname[0] == 'w')
		Decal(iVictim, "500", false, 2);
	
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
				BloodOnFloorPrep(iVictim);
				if(bExpDeath)
				{
					ParticleKappaCap;
					ParticleSpawn(ExpGore3, iVictim);
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
				BloodOnFloorPrep(iVictim);
				if(bExpDeath)
				{
					ParticleKappaCap;
					ParticleSpawn(ExpGore2, iVictim);
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
				BloodOnFloorPrep(iVictim);
				if(bExpDeath)
				{
					ParticleKappaCap;
					ParticleSpawn(ExpGore1, iVictim);
				}
			}
		}
		case 7, 8:
		{
			if(bDeath)
			{
				BloodOnFloorPrep(iVictim);
				if(bExpDeath)
				{
					switch(GetRandomInt(1, 3))
					{
						case 1:
						{
							ParticleKappaCap;
							ParticleSpawn(ExpGore1, iVictim);
						}
						case 2:
						{
							ParticleKappaCap;
							ParticleSpawn(ExpGore2, iVictim);
						}
						case 3:
						{
							ParticleKappaCap;
							ParticleSpawn(ExpGore3, iVictim);
						}
					}
				}
			}
		}
	}
}

static BloodOnFloorPrep(iVictim, bool:bBoomerPatch=false)
{
	if(!g_bBloodPool)
		return;
	
	decl Float:fPos[3];
	GetEntPropVector(iVictim, Prop_Send, "m_vecOrigin", fPos);
	
	new Handle:hPack;	
	if(bBoomerPatch)
	{
		new iBPatch = GetRandomInt(7, 14);
		for(new i = 1; i <= iBPatch; i++)
		{
			CreateDataTimer(0.07, BloodOnFloor, hPack, TIMER_FLAG_NO_MAPCHANGE);
			WritePackFloat(hPack, fPos[0] + GetRandomFloat(-40.0, 40.0));//Timocop way
			WritePackFloat(hPack, fPos[1] + GetRandomFloat(-40.0, 40.0));
			WritePackFloat(hPack, fPos[2]);
		}
		
	}
	else
	{
		CreateDataTimer(0.07, BloodOnFloor, hPack, TIMER_FLAG_NO_MAPCHANGE);
		WritePackFloat(hPack, fPos[0]);
		WritePackFloat(hPack, fPos[1]);
		WritePackFloat(hPack, fPos[2]);
	}
}

public Action:BloodOnFloor(Handle:hTimer, any:hPack)
{
	ResetPack(hPack);
	
	decl Float:fPos[3];
	fPos[0] = ReadPackFloat(hPack);
	fPos[1] = ReadPackFloat(hPack);
	fPos[2] = ReadPackFloat(hPack);
	
	fPos[2] += 1.0;
	
	// execute Trace straight down
	new Handle:trace;
	trace = TR_TraceRayFilterEx(fPos, Float:{90.0, 0.0, 0.0}, MASK_SHOT, RayType_Infinite, _TraceFilter);
	
	decl Float:fEnd[3];
	TR_GetEndPosition(fEnd, trace); // retrieve our trace endpoint
	
	static Float:fDist;
	fDist = GetVectorDistance(fPos, fEnd);
	
	CloseHandle(trace);
	
	if(fDist > 74.0)
		return Plugin_Stop;
	
	static iBlood;
	iBlood = CreateEntityByName("info_particle_system");
	if(!IsValidEntity(iBlood))
		return Plugin_Continue;
	
	decl String:sName[17];
	Format(sName, sizeof(sName), "L4DPartikel%i", iBlood);
	DispatchKeyValue(iBlood, "effect_name", BloodPatch);
	DispatchKeyValue(iBlood, "targetname", sName);
	DispatchSpawn(iBlood);
	ActivateEntity(iBlood);
	TeleportEntity(iBlood, fEnd, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(iBlood, "Start");
	
	SetVariantString("OnUser1 !self:Kill::0.1:1");
	AcceptEntityInput(iBlood, "AddOutput");
	AcceptEntityInput(iBlood, "FireUser1");
	
	return Plugin_Stop;
}
//Wait no i made the trace filter xD with timo
public bool:_TraceFilter(iEntity, contentsMask)
{
	decl String:sClassName[11];
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

public Action:KappaCap(Handle:hTimer)
{
	if(iCount > g_iKappaCount)
		return Plugin_Continue;
	
	iCount++;
	return Plugin_Continue;
}

public eRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(hTimer_Kappa == INVALID_HANDLE)
		CreateTimer(g_fKappaTimer, KappaCap, hTimer_Kappa, TIMER_REPEAT);
}

public eRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(hTimer_Kappa != INVALID_HANDLE)
	{
		KillTimer(hTimer_Kappa);
		hTimer_Kappa = INVALID_HANDLE;
	}
}

public ePlayerTeam(Handle:hEvent, const String:sEventName[], bool:bDontBroadcast)
{
	if(!g_bPrecacheWorkAround)
		return;
		
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));	
	if(IsFakeClient(iClient) || PrecacheClientList[iClient])
		return;
		
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

public Action:PrecacheParticlePre(Handle:hTimer)
{
	new iClient = 0;
	
	static iTempHealth;
	static iHealth;
	for(new i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i) || !IsPlayerAlive(i))
		 continue;
		
		iHealth = GetEntProp(i, Prop_Send, "m_iHealth");
		if(GetClientTeam(i) == 2)
			iTempHealth = L4D_GetPlayerTempHealth(i);
		else
			iTempHealth = 0;
		
		if(iHealth > 1 || iTempHealth > 1)
		{	
			iClient = i;
			break;
		}
	}	
	if(iClient < 1)
		return Plugin_Stop;
	
	Entity_Hurt(iClient, 1, iClient, DMG_BULLET);
	if(iHealth != 0)
		SetEntProp(iClient, Prop_Send, "m_iHealth", iHealth);
	
	if(iTempHealth != 0)
	{
		SetEntPropFloat(iClient, Prop_Send, "m_healthBuffer", float(iTempHealth));
		SetEntPropFloat(iClient, Prop_Send, "m_healthBufferTime", GetGameTime());
	}	
	return Plugin_Stop;
}



public OnClientDisconnect(iClient)
{
	PrecacheClientList[iClient] = false;
}

public OnMapEnd()
{
	for(new i = 1; i <= MaxClients; i++)
		PrecacheClientList[i] = false;
}

static PrecacheParticle(const String:ParticleName[])//silvers particle precache
{
	static entity;
	entity = CreateEntityByName("info_particle_system");
	DispatchKeyValue(entity, "effect_name", ParticleName);
	DispatchSpawn(entity);
	ActivateEntity(entity);
	AcceptEntityInput(entity, "start");
	SetVariantString("OnUser1 !self:Kill::0.1:-1");
	AcceptEntityInput(entity, "AddOutput");
	AcceptEntityInput(entity, "FireUser1");
}

static bool:Decal(iClient, String:sAmount[]="200", bool:GreenBlood=false, iMoreBlood=2)//Timo's Stock for decal spray
{
	if(!g_bDecals)
		return false;
	
	static iEntity = INVALID_ENT_REFERENCE;
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
	decl Float:fPos[3];
	GetEntPropVector(iClient, Prop_Send, "m_vecOrigin", fPos);
	if(GreenBlood)
	{
		DispatchKeyValue(iEntity, "color", "1");
	}
	else
	{
		DispatchKeyValue(iEntity, "color", "0");
	}
	decl String:sName[17];
	Format(sName, sizeof(sName), "L4DPartikel%i", iEntity);
	DispatchKeyValue(iEntity, "amount", sAmount);
	DispatchKeyValue(iEntity, "spraydir", "0 0 0");
	DispatchKeyValue(iEntity, "spawnflags", "13");
	DispatchSpawn(iEntity);
	ActivateEntity(iEntity);
	TeleportEntity(iEntity, fPos, NULL_VECTOR, NULL_VECTOR);
	static i;
	i = 0;
	while (i <= iMoreBlood)
	{
		AcceptEntityInput(iEntity, "EmitBlood", -1, -1, 0);
		i++;
	}
	return true;
}

static ParticleSpawn(const String:sParticle[], iVictim, Float:fTimeMin=0.4, Float:fTimeMax= 0.7, bool:LongBlood=false, Float:ExtraXfPos=0.0)//My Stock Just for this so enjoy if you use it :3
{
	if(!g_bBloodParticles)
		return;
	
	static iSplat;
	iSplat = CreateEntityByName("info_particle_system");
	
	if(!IsValidEntity(iSplat))
		return;
		
	decl Float:fPos[3];
	GetEntPropVector(iVictim, Prop_Send, "m_vecOrigin", fPos);
	
	static Float:fTime;
	fTime = GetRandomFloat(fTimeMin, fTimeMax);
	decl String:sName[17];
	if(!LongBlood)
	{
		if(ExtraXfPos != 0.0)
			fPos[2] += ExtraXfPos;
		
		Format(sName, sizeof(sName), "L4DPartikel%i", iSplat);
		DispatchKeyValue(iSplat, "effect_name", sParticle);
		DispatchKeyValue(iSplat, "targetname", sName);
		DispatchSpawn(iSplat);
		ActivateEntity(iSplat);
		TeleportEntity(iSplat, fPos, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(iSplat, "Start");
		
		Format(sName, 64, "OnUser1 !self:Kill::%f:1", fTime);
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
		TeleportEntity(iSplat, fPos, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(iSplat, "Start");
		
		Format(sName, sizeof(sName), "OnUser1 !self:Kill::%f:1", fTime);
		SetVariantString(sName);
		AcceptEntityInput(iSplat, "AddOutput");
		AcceptEntityInput(iSplat, "FireUser1");
		
		TeleportEntity(iSplat, fPos, NULL_VECTOR, NULL_VECTOR);
		
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

stock bool:IsParticleSystemPrecached(const String:particleSystem[])
{
	static particleEffectNames = INVALID_STRING_TABLE;

	if (particleEffectNames == INVALID_STRING_TABLE) {
		if ((particleEffectNames = FindStringTable("ParticleEffectNames")) == INVALID_STRING_TABLE) {
			return false;
		}
	}
	
	return (FindStringIndex2(particleEffectNames, particleSystem) != INVALID_STRING_INDEX);
}

stock PrecacheParticleSystem(const String:particleSystem[])
{
	static particleEffectNames = INVALID_STRING_TABLE;

	if (particleEffectNames == INVALID_STRING_TABLE) {
		if ((particleEffectNames = FindStringTable("ParticleEffectNames")) == INVALID_STRING_TABLE) {
			return INVALID_STRING_INDEX;
		}
	}

	new index = FindStringIndex2(particleEffectNames, particleSystem);
	if (index == INVALID_STRING_INDEX) {
		new numStrings = GetStringTableNumStrings(particleEffectNames);
		if (numStrings >= GetStringTableMaxStrings(particleEffectNames)) {
			return INVALID_STRING_INDEX;
		}
		
		AddToStringTable(particleEffectNames, particleSystem);
		index = numStrings;
	}
	
	return index;
}

stock FindStringIndex2(tableidx, const String:str[])
{
	decl String:buf[1024];

	new numStrings = GetStringTableNumStrings(tableidx);
	for (new i=0; i < numStrings; i++) {
		ReadStringTable(tableidx, i, buf, sizeof(buf));
		
		if (StrEqual(buf, str)) {
			return i;
		}
	}
	
	return INVALID_STRING_INDEX;
}

stock bool:Entity_Hurt(entity, damage, attacker=0, damageType=DMG_GENERIC, const String:fakeClassName[]="")
{
	static point_hurt = INVALID_ENT_REFERENCE;
	
	if (point_hurt == INVALID_ENT_REFERENCE || !IsValidEntity(point_hurt)) {
		point_hurt = EntIndexToEntRef(Entity_Create("point_hurt"));
		
		if (point_hurt == INVALID_ENT_REFERENCE) {
			return false;
		}
		
		DispatchSpawn(point_hurt);
	}
	
	AcceptEntityInput(point_hurt, "TurnOn");
	SetEntProp(point_hurt, Prop_Data, "m_nDamage", damage);
	SetEntProp(point_hurt, Prop_Data, "m_bitsDamageType", damageType);
	Entity_PointHurtAtTarget(point_hurt, entity);
	
	if (fakeClassName[0] != '\0') {
		Entity_SetClassName(point_hurt, fakeClassName);
	}
	
	AcceptEntityInput(point_hurt, "Hurt", attacker);
	AcceptEntityInput(point_hurt, "TurnOff");
	
	if (fakeClassName[0] != '\0') {
		Entity_SetClassName(point_hurt, "point_hurt");
	}
	
	return true;
}

stock Entity_Create(const String:className[], ForceEdictIndex=-1)
{
	if (ForceEdictIndex != -1 && Entity_IsValid(ForceEdictIndex)) {
		return INVALID_ENT_REFERENCE;
	}
	
	return CreateEntityByName(className, ForceEdictIndex);
}

stock Entity_PointHurtAtTarget(entity, target, const String:name[]="")
{
	decl String:targetName[128];
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
	else {
		strcopy(targetName, sizeof(targetName), name);
	}

	DispatchKeyValue(entity, "DamageTarget", targetName);
	Entity_SetName(target, targetName);
}

stock Entity_IsValid(entity)
{
	return IsValidEntity(entity);
}

stock Entity_SetName(entity, const String:name[], any:...)
{
	decl String:format[128];
	VFormat(format, sizeof(format), name, 3);

	return DispatchKeyValue(entity, "targetname", format);
}

stock Entity_GetTargetName(entity, String:buffer[], size)
{
	return GetEntPropString(entity, Prop_Data, "m_target", buffer, size);
}

stock Entity_SetClassName(entity, const String:className[])
{
	return DispatchKeyValue(entity, "classname", className);
}

stock L4D_GetPlayerTempHealth(client)
{
	static Handle:painPillsDecayCvar = INVALID_HANDLE;
	if (painPillsDecayCvar == INVALID_HANDLE)
	{
		painPillsDecayCvar = FindConVar("pain_pills_decay_rate");
		if (painPillsDecayCvar == INVALID_HANDLE)
		{
			return -1;
		}
	}
	
	new tempHealth = RoundToCeil(GetEntPropFloat(client, Prop_Send, "m_healthBuffer") - ((GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime")) * GetConVarFloat(painPillsDecayCvar))) - 1;
	return tempHealth < 0 ? 0 : tempHealth;
}