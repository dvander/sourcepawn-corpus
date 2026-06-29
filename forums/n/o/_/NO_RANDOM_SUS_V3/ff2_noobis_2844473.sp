#pragma semicolon 1

#include <tf2_stocks>
#include <sdkhooks>
#include <tf2items>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>
#include <ff2_ams>

 #undef MAXPLAYERS // Cause why not
#define MAXPLAYERS 33

public Plugin myinfo = {
	name = "Freak Fortress 2: Noobis' Requested Abilities",
	author = "Deathreus",
	version = "1.0",
};

#define INACTIVE 100000000.0

int BossTeam = view_as<int>(TFTeam_Blue);

int CloneOwnerIndex[MAXPLAYERS];

UserMsg g_FadeUserMsgId;
bool g_bIsBlind[MAXPLAYERS] = false;
int g_iBoss;

//--------
bool PKStarStorm_TriggerAMS[MAXPLAYERS] = false;

float PKSS_Damage[MAXPLAYERS];
float PKSS_Speed[MAXPLAYERS];
float PKSS_Radius[MAXPLAYERS];
float PKSS_BlastRadius[MAXPLAYERS];
float PKSS_Delay[MAXPLAYERS];
int PKSS_MaxSpawns[MAXPLAYERS];
bool PKSS_FreezeMovement[MAXPLAYERS];

int PKSS_Shots[MAXPLAYERS]; // Internal

//--------
bool PKThunder_TriggerAMS[MAXPLAYERS];

float PKT_Damage[MAXPLAYERS];
float PKT_Speed[MAXPLAYERS];
float PKT_Duration[MAXPLAYERS];
float PKT_Size[MAXPLAYERS];
int PKT_TurnSens[MAXPLAYERS];
bool PKT_FreezeMovement[MAXPLAYERS];
char PKT_Particle[MAXPLAYERS][64];

int PKT_LifeTime; // Internal
Handle g_hRocketTouch;

//--------
bool PKFire_TriggerAMS[MAXPLAYERS];

float PKF_Damage[MAXPLAYERS];
float PKF_Delay[MAXPLAYERS];
float PKF_Speed[MAXPLAYERS];
float PKF_AngleDev[MAXPLAYERS];
float PKF_AfterburnDur[MAXPLAYERS];

//--------
bool Noclip_TriggerAMS[MAXPLAYERS];
bool Noclip_CanUse[MAXPLAYERS];

float NC_Speed[MAXPLAYERS];

//--------
char HotSwapModel[MAXPLAYERS][3][PLATFORM_MAX_PATH];

//--------
bool ExplosiveMinion_TriggerAMS[MAXPLAYERS] = false;

char EM_Model[MAXPLAYERS][PLATFORM_MAX_PATH];
int EM_Health[MAXPLAYERS];
int EM_Class[MAXPLAYERS];
float EM_Speed[MAXPLAYERS];
float EM_Damage[MAXPLAYERS];
float EM_Radius[MAXPLAYERS];
float EM_Ratio[MAXPLAYERS];

int EM_Minions[MAXPLAYERS][MAXPLAYERS]; // Internal
int EM_MinionCount[MAXPLAYERS]; // Internal

//--------
int PP_RageAmount[MAXPLAYERS][12];
char PP_HealthFormula[MAXPLAYERS][12][64];

//--------
bool Volcano_TriggerAMS[MAXPLAYERS];

int VLCN_MaxSpawns[MAXPLAYERS];
float VLCN_Damage[MAXPLAYERS];
float VLCN_BlastRadius[MAXPLAYERS];
float VLCN_Speed[MAXPLAYERS];
float VLCN_Radius[MAXPLAYERS];
float VLCN_SpawnDelay[MAXPLAYERS];
float VLCN_FuseTime[MAXPLAYERS];
char VLCN_Model[MAXPLAYERS][PLATFORM_MAX_PATH];

int VLCN_Shots[MAXPLAYERS]; // Internal

//--------
bool Prop_TriggerAMS[MAXPLAYERS];

float PRP_SpawnDelay[MAXPLAYERS];
char PRP_Model[MAXPLAYERS][PLATFORM_MAX_PATH];

//--------
#define BOMBMODEL "models/props_lakeside_event/bomb_temp.mdl"

bool Bomb_TriggerAMS[MAXPLAYERS];

float BMB_Radius[MAXPLAYERS];
float BMB_Damage[MAXPLAYERS];

//--------
float BH_Radius[MAXPLAYERS];
float BH_Damage[MAXPLAYERS];
float BH_Duration[MAXPLAYERS];
float BH_Force[MAXPLAYERS];

//--------
float GRN_FireDelay[MAXPLAYERS];
float GRN_Damage[MAXPLAYERS];
float GRN_Speed[MAXPLAYERS];

float GRN_NextShot[MAXPLAYERS];		// Internal

//--------
float SMS_Damage[MAXPLAYERS];

//--------
bool PowerStar_TriggerAMS[MAXPLAYERS] = false;

float PS_ShootTime[MAXPLAYERS];
float PS_ShotDamage[MAXPLAYERS];
float PS_HomingChance[MAXPLAYERS];
float PS_Duration[MAXPLAYERS];
float PS_Speed[MAXPLAYERS];
char PS_PropModel[MAXPLAYERS][PLATFORM_MAX_PATH];
char PS_ProjModel[MAXPLAYERS][PLATFORM_MAX_PATH];
char PS_ProjTrail[MAXPLAYERS][96];

new Handle:g_hArrayHoming;

public void OnPluginStart2()
{
	HookEvent("arena_round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("arena_win_panel", Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	
	new Handle:hGameData = LoadGameConfigFile("homingrocket.gamedata");
	if(hGameData != INVALID_HANDLE)
	{
		StartPrepSDKCall(SDKCall_Entity);
		PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, "RocketTouch");
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer, VDECODE_FLAG_ALLOWWORLD);
		g_hRocketTouch = EndPrepSDKCall();
	}
	CloseHandle(hGameData);
	
	g_FadeUserMsgId = GetUserMessageId("Fade");
	
	PrecacheModel(BOMBMODEL, true);
	
	if(FF2_GetRoundState() == 1) // Late-load
	{
		BossTeam = FF2_GetBossTeam();
		HookAbilities();
	}
	
	g_hArrayHoming = CreateArray(3);
}

public void Event_RoundStart(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	BossTeam = FF2_GetBossTeam();
	HookAbilities();
}

public void Event_RoundEnd(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	for(int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if(IsValidClient(iClient))
		{
			SDKUnhook(iClient, SDKHook_WeaponCanSwitchToPost, OnWeaponSwitch);
			SDKUnhook(iClient, SDKHook_OnTakeDamageAlive, OnTakeDamage);
			SDKUnhook(iClient, SDKHook_PreThink, StarStorm_Think);
			SDKUnhook(iClient, SDKHook_PreThink, Minion_Think);
			SetEntityMoveType(iClient, MOVETYPE_WALK);
		}
		
		PKSS_Shots[iClient] = 0;
		PKT_LifeTime = 0;
		EM_Minions[iClient][iClient] = -1;
		EM_MinionCount[iClient] = 0;
		VLCN_Shots[iClient] = 0;
	}
}

public void HookAbilities()
{
	for(int iIndex, iBoss=GetClientOfUserId(FF2_GetBossUserId(iIndex)); iIndex < MAXPLAYERS; iIndex++)
	{
		if(FF2_HasAbility(iIndex, this_plugin_name, "rage_starstorm"))
		{
			if((PKStarStorm_TriggerAMS[iBoss]=FF2_GetAbilityArgumentBool(iIndex, this_plugin_name, "rage_starstorm", 1))) // If true, this will trigger AMS_InitSubability.
			{
				AMS_InitSubability(iIndex, iBoss, this_plugin_name, "rage_starstorm", "STRM"); // Important function to tell AMS that this subplugin supports it
			}
			
			PKSS_Damage[iBoss] = FF2_GetAbilityArgumentFloat(iIndex, this_plugin_name, "rage_starstorm", 2);
			PKSS_Speed[iBoss] = FF2_GetAbilityArgumentFloat(iIndex, this_plugin_name, "rage_starstorm", 3);
			PKSS_Radius[iBoss] = FF2_GetAbilityArgumentFloat(iIndex, this_plugin_name, "rage_starstorm", 4);
			PKSS_BlastRadius[iBoss] = FF2_GetAbilityArgumentFloat(iIndex, this_plugin_name, "rage_starstorm", 5);
			PKSS_Delay[iBoss] = FF2_GetAbilityArgumentFloat(iIndex, this_plugin_name, "rage_starstorm", 6);
			PKSS_MaxSpawns[iBoss] = FF2_GetAbilityArgument(iIndex, this_plugin_name, "rage_starstorm", 7);
			PKSS_FreezeMovement[iBoss] = FF2_GetAbilityArgumentBool(iIndex, this_plugin_name, "rage_starstorm", 8);
			
			g_iBoss = iBoss;
		}
		
		if(FF2_HasAbility(iIndex, this_plugin_name, "rage_pkthunder"))
		{
			if((PKThunder_TriggerAMS[iBoss]=FF2_GetAbilityArgumentBool(iIndex, this_plugin_name, "rage_pkthunder", 1)))
			{
				AMS_InitSubability(iIndex, iBoss, this_plugin_name, "rage_pkthunder", "THND");
			}
			
			PKT_Damage[iBoss] = FF2_GetAbilityArgumentFloat(iIndex, this_plugin_name, "rage_pkthunder", 2);
			PKT_Speed[iBoss] = FF2_GetAbilityArgumentFloat(iIndex, this_plugin_name, "rage_pkthunder", 3);
			PKT_Duration[iBoss] = FF2_GetAbilityArgumentFloat(iIndex, this_plugin_name, "rage_pkthunder", 4);
			PKT_Size[iBoss] = FF2_GetAbilityArgumentFloat(iIndex, this_plugin_name, "rage_pkthunder", 5);
			PKT_TurnSens[iBoss] = FF2_GetAbilityArgument(iIndex, this_plugin_name, "rage_pkthunder", 6);
			PKT_FreezeMovement[iBoss] = FF2_GetAbilityArgumentBool(iIndex, this_plugin_name, "rage_pkthunder", 7);
			FF2_GetAbilityArgumentString(iIndex, this_plugin_name, "rage_pkthunder", 8, PKT_Particle[iBoss], sizeof(PKT_Particle[]));
		}
		
		if(FF2_HasAbility(iIndex, this_plugin_name, "rage_pkfire"))
		{
			if((PKFire_TriggerAMS[iBoss]=FF2_GetAbilityArgumentBool(iIndex, this_plugin_name, "rage_pkfire", 1)))
			{
				AMS_InitSubability(iIndex, iBoss, this_plugin_name, "rage_pkfire", "FRBL");
			}
			
			PKF_Damage[iBoss] = FF2_GetAbilityArgumentFloat(iIndex, this_plugin_name, "rage_pkfire", 3);
			PKF_Delay[iBoss] = FF2_GetAbilityArgumentFloat(iIndex, this_plugin_name, "rage_pkfire", 4);
			PKF_Speed[iBoss] = FF2_GetAbilityArgumentFloat(iIndex, this_plugin_name, "rage_pkfire", 5);
			PKF_AngleDev[iBoss] = FF2_GetAbilityArgumentFloat(iIndex, this_plugin_name, "rage_pkfire", 6);
			PKF_AfterburnDur[iBoss] = FF2_GetAbilityArgumentFloat(iIndex, this_plugin_name, "rage_pkfire", 7);
			
			g_iBoss = iBoss;
			for(int iClient = MaxClients; iClient; iClient--)
			{
				SDKHook(iClient, SDKHook_OnTakeDamageAlive, OnTakeDamage);
			}
		}
		
		if((Noclip_CanUse[iBoss]=FF2_HasAbility(iIndex, this_plugin_name, "rage_noclip")))
		{
			if((Noclip_TriggerAMS[iBoss]=FF2_GetAbilityArgumentBool(iIndex, this_plugin_name, "rage_noclip", 1)))
			{
				AMS_InitSubability(iIndex, iBoss, this_plugin_name, "rage_noclip", "NCLP");
			}
			
			NC_Speed[iBoss] = FF2_GetAbilityArgumentFloat(iIndex, this_plugin_name, "rage_noclip", 2, 360.0);
		}
		if((Noclip_CanUse[iBoss]=FF2_HasAbility(iIndex, this_plugin_name, "special_noclip")))
		{
			SetEntityMoveType(iBoss, MOVETYPE_NOCLIP);
			SetEntProp(iBoss, Prop_Send, "m_CollisionGroup", 5);
			NC_Speed[iBoss] = FF2_GetAbilityArgumentFloat(iIndex, this_plugin_name, "special_noclip", 1, 360.0);
		}
		
		if(FF2_HasAbility(iIndex, this_plugin_name, "special_modelhotswap"))
		{
			// Leave any of these blank to do nothing
			FF2_GetAbilityArgumentString(iIndex, this_plugin_name, "special_modelhotswap", 1, HotSwapModel[iBoss][0], PLATFORM_MAX_PATH);
			FF2_GetAbilityArgumentString(iIndex, this_plugin_name, "special_modelhotswap", 2, HotSwapModel[iBoss][1], PLATFORM_MAX_PATH);
			FF2_GetAbilityArgumentString(iIndex, this_plugin_name, "special_modelhotswap", 3, HotSwapModel[iBoss][2], PLATFORM_MAX_PATH);
			
			SDKHook(iBoss, SDKHook_WeaponCanSwitchToPost, OnWeaponSwitch);
		}
		
		if(FF2_HasAbility(iIndex, this_plugin_name, "rage_explosiveminion"))
		{
			if((ExplosiveMinion_TriggerAMS[iBoss]=FF2_GetAbilityArgumentBool(iIndex, this_plugin_name, "rage_explosiveminion", 1)))
			{
				AMS_InitSubability(iIndex, iBoss, this_plugin_name, "rage_explosiveminion", "EM");
			}
			
			EM_Health[iBoss] = FF2_GetAbilityArgument(iIndex, this_plugin_name, "rage_explosiveminion", 2, 200);
			EM_Speed[iBoss] = FF2_GetAbilityArgumentFloat(iIndex, this_plugin_name, "rage_explosiveminion", 3, 480.0);
			EM_Class[iBoss] = FF2_GetAbilityArgument(iIndex, this_plugin_name, "rage_explosiveminion", 4, -1);
			FF2_GetAbilityArgumentString(iIndex, this_plugin_name, "rage_explosiveminion", 5, EM_Model[iBoss], sizeof(EM_Model[]));
			EM_Damage[iBoss] = FF2_GetAbilityArgumentFloat(iIndex, this_plugin_name, "rage_explosiveminion", 6, 300.0);
			EM_Radius[iBoss] = FF2_GetAbilityArgumentFloat(iIndex, this_plugin_name, "rage_explosiveminion", 7, 600.0);
			EM_Ratio[iBoss] = FF2_GetAbilityArgumentFloat(iIndex, this_plugin_name, "rage_explosiveminion", 8, 0.5);
			
			g_iBoss = iBoss;
		}
		
		if(FF2_HasAbility(iIndex, this_plugin_name, "special_porkypassive_health"))
		{
			int maxLives = FF2_GetBossMaxLives(iIndex);
			for(int i = 1; i <= maxLives; i++)
				FF2_GetAbilityArgumentString(iIndex, this_plugin_name, "special_porkypassive_health", i, PP_HealthFormula[iBoss][i], 64);
			
			int iPlaying;
			for(int i = 1; i < MAXPLAYERS; i++)
			{
				if(IsClientConnected(i) && IsClientInGame(i))
					iPlaying++;
			}
			
			int iStartingHealth = ParseFormula(iIndex, PP_HealthFormula[iBoss][maxLives], RoundFloat((((768.0 + float(iPlaying))* float(iPlaying))^ 1.034)/ maxLives), iPlaying);
			FF2_SetBossMaxHealth(iIndex, iStartingHealth);
			FF2_SetBossHealth(iIndex, iStartingHealth);
		}
		
		if(FF2_HasAbility(iIndex, this_plugin_name, "special_porkypassive_rage"))
		{
			int maxLives = FF2_GetBossMaxLives(iIndex);
			for(int i = 1; i <= maxLives; i++)
				PP_RageAmount[iBoss][i] = FF2_GetAbilityArgument(iIndex, this_plugin_name, "special_porkypassive_rage", i);
			
			FF2_SetBossRageDamage(iIndex, PP_RageAmount[iBoss][maxLives]);
		}
		
		if(FF2_HasAbility(iIndex, this_plugin_name, "rage_volcano"))
		{
			if((Volcano_TriggerAMS[iBoss]=FF2_GetAbilityArgumentBool(iIndex, this_plugin_name, "rage_volcano", 1)))
			{
				AMS_InitSubability(iIndex, iBoss, this_plugin_name, "rage_volcano", "VLCN");
			}
			
			VLCN_Damage[iBoss] = FF2_GetAbilityArgumentFloat(iIndex, this_plugin_name, "rage_volcano", 2, 75.0);
			VLCN_Speed[iBoss] = FF2_GetAbilityArgumentFloat(iIndex, this_plugin_name, "rage_volcano", 3, 800.0);
			VLCN_BlastRadius[iBoss] = FF2_GetAbilityArgumentFloat(iIndex, this_plugin_name, "rage_volcano", 4, 400.0);
			VLCN_Radius[iBoss] = FF2_GetAbilityArgumentFloat(iIndex, this_plugin_name, "rage_volcano", 5, 1200.0);
			VLCN_MaxSpawns[iBoss] = FF2_GetAbilityArgument(iIndex, this_plugin_name, "rage_volcano", 6, 10);
			VLCN_SpawnDelay[iBoss] = FF2_GetAbilityArgumentFloat(iIndex, this_plugin_name, "rage_volcano", 7, 1.2);
			VLCN_FuseTime[iBoss] = FF2_GetAbilityArgumentFloat(iIndex, this_plugin_name, "rage_volcano", 8, 1.5);
			FF2_GetAbilityArgumentString(iIndex, this_plugin_name, "rage_volcano", 9, VLCN_Model[iBoss], PLATFORM_MAX_PATH);
		}
		
		if(FF2_HasAbility(iIndex, this_plugin_name, "rage_propspawn"))
		{
			if((Prop_TriggerAMS[iBoss]=FF2_GetAbilityArgumentBool(iIndex, this_plugin_name, "rage_propspawn", 1)))
			{
				AMS_InitSubability(iIndex, iBoss, this_plugin_name, "rage_propspawn", "PRP");
			}
			
			FF2_GetAbilityArgumentString(iIndex, this_plugin_name, "rage_propspawn", 1, PRP_Model[iBoss], PLATFORM_MAX_PATH);
			PRP_SpawnDelay[iBoss] = FF2_GetAbilityArgumentFloat(iIndex, this_plugin_name, "rage_propspawn", 2);
			
			g_iBoss = iBoss;
		}
		
		if(FF2_HasAbility(iIndex, this_plugin_name, "rage_bombs"))
		{
			if((Bomb_TriggerAMS[iBoss]=FF2_GetAbilityArgumentBool(iIndex, this_plugin_name, "rage_bombs", 1)))
			{
				AMS_InitSubability(iIndex, iBoss, this_plugin_name, "rage_bombs", "BMB");
			}
			
			BMB_Damage[iBoss] = FF2_GetAbilityArgumentFloat(iIndex, this_plugin_name, "rage_bombs", 2, 65.0);
			BMB_Radius[iBoss] = FF2_GetAbilityArgumentFloat(iIndex, this_plugin_name, "rage_bombs", 3, 400.0);
			
			g_iBoss = iBoss;
		}
		
		if(FF2_HasAbility(iIndex, this_plugin_name, "special_blackholerockets"))
		{
			BH_Damage[iBoss] = FF2_GetAbilityArgumentFloat(iIndex, this_plugin_name, "special_blackholerockets", 1, 5.0);
			BH_Radius[iBoss] = FF2_GetAbilityArgumentFloat(iIndex, this_plugin_name, "special_blackholerockets", 2, 800.0);
			BH_Duration[iBoss] = FF2_GetAbilityArgumentFloat(iIndex, this_plugin_name, "special_blackholerockets", 3, 8.0);
			BH_Force[iBoss] = FF2_GetAbilityArgumentFloat(iIndex, this_plugin_name, "special_blackholerockets", 4, -200.0);
		}
		
		if(FF2_HasAbility(iIndex, this_plugin_name, "special_rocktoss"))
		{
			GRN_FireDelay[iBoss] = FF2_GetAbilityArgumentFloat(iIndex, this_plugin_name, "special_grenades", 1, 2.0);
			GRN_Damage[iBoss] = FF2_GetAbilityArgumentFloat(iIndex, this_plugin_name, "special_grenades", 2, 120.0);
			GRN_Speed[iBoss] = FF2_GetAbilityArgumentFloat(iIndex, this_plugin_name, "special_grenades", 3, 800.0);
			
			g_iBoss = iBoss;
		}
		
		if(FF2_HasAbility(iIndex, this_plugin_name, "rage_electric"))
		{
			SMS_Damage[iBoss] = FF2_GetAbilityArgumentFloat(iIndex, this_plugin_name, "rage_electric", 2, 30.0);
		}
		
		if(FF2_HasAbility(iIndex, this_plugin_name, "rage_powerstar"))
		{
			if((PowerStar_TriggerAMS[iBoss]=FF2_GetAbilityArgumentBool(iIndex, this_plugin_name, "rage_powerstar", 1)))
			{
				AMS_InitSubability(iIndex, iBoss, this_plugin_name, "rage_powerstar", "PS");
			}
			
			PS_ShootTime[iBoss] = FF2_GetAbilityArgumentFloat(iIndex, this_plugin_name, "rage_powerstar", 2, 0.0);
			PS_ShotDamage[iBoss] = FF2_GetAbilityArgumentFloat(iIndex, this_plugin_name, "rage_powerstar", 3, 75.0);
			PS_HomingChance[iBoss] = FF2_GetAbilityArgumentFloat(iIndex, this_plugin_name, "rage_powerstar", 4, 1.0);
			PS_Duration[iBoss] = FF2_GetAbilityArgumentFloat(iIndex, this_plugin_name, "rage_powerstar", 5, 5.0);
			FF2_GetAbilityArgumentString(iIndex, this_plugin_name, "rage_powerstar", 6, PS_PropModel[iBoss], PLATFORM_MAX_PATH);
			FF2_GetAbilityArgumentString(iIndex, this_plugin_name, "rage_powerstar", 7, PS_ProjModel[iBoss], PLATFORM_MAX_PATH);
			FF2_GetAbilityArgumentString(iIndex, this_plugin_name, "rage_powerstar", 8, PS_ProjTrail[iBoss], 96);
			PS_Speed[iBoss] = FF2_GetAbilityArgumentFloat(iIndex, this_plugin_name, "rage_powerstar", 9);
			
			g_iBoss = iBoss;
		}
	}
}

public void Event_PlayerDeath(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	for(int i = EM_MinionCount[g_iBoss]; i >= 0 ; i--)
	{
		if(iClient == EM_Minions[g_iBoss][i])
		{
			int iExplosion = CreateEntityByName("env_explosion");
			DispatchKeyValueFloat(iExplosion, "DamageForce", 180.0);
			SetEntProp(iExplosion, Prop_Data, "m_iMagnitude", EM_Damage[g_iBoss], 4);
			SetEntProp(iExplosion, Prop_Data, "m_iRadiusOverride", EM_Radius[g_iBoss], 4);
			SetEntPropEnt(iExplosion, Prop_Data, "m_hOwnerEntity", g_iBoss);
			DispatchSpawn(iExplosion);
			
			float vPos[3];
			GetEntPropVector(iClient, Prop_Data, "m_vecAbsOrigin", vPos);
			TeleportEntity(iExplosion, vPos, NULL_VECTOR, NULL_VECTOR);
			
			AcceptEntityInput(iExplosion, "Explode");
			AcceptEntityInput(iExplosion, "Kill");
			
			EM_Minions[g_iBoss][i] = -1;
			EM_MinionCount[g_iBoss]--;
			break;
		}
	}
	
	int iBoss = FF2_GetBossIndex(iClient);
	if(iBoss != -1 && FF2_HasAbility(iBoss, this_plugin_name, "rage_explosiveminion") && !(GetEventInt(hEvent, "death_flags") & TF_DEATHFLAG_DEADRINGER))
	{
		for(int iTarget = 1; iTarget <= MaxClients; iTarget++)
		{
			if(CloneOwnerIndex[iTarget] == iClient)
			{
				CloneOwnerIndex[iTarget] = -1;
				if(IsClientInGame(iTarget) && GetClientTeam(iTarget) == BossTeam)
				{
					FF2_SetFF2flags(iTarget, FF2_GetFF2flags(iTarget) & ~FF2FLAG_CLASSTIMERDISABLED);
					ChangeClientTeam(iTarget, (BossTeam==_:TFTeam_Blue) ? (_:TFTeam_Red) : (_:TFTeam_Blue));
				}
			}
		}
	}
	
	if(CloneOwnerIndex[iClient] != -1 && GetClientTeam(iClient) == BossTeam)  //Switch clones back to the other team after they die
	{
		CloneOwnerIndex[iClient] = -1;
		FF2_SetFF2flags(iClient, FF2_GetFF2flags(iClient) & ~FF2FLAG_CLASSTIMERDISABLED);
		ChangeClientTeam(iClient, (BossTeam==_:TFTeam_Blue) ? (_:TFTeam_Red) : (_:TFTeam_Blue));
	}
}

public void OnEntityCreated(int iEntity, const char[] sClassName)
{
	if(!strcmp(sClassName, "tf_spell_meteorshowerspawner"))
	{
		if(g_iBoss && FF2_HasAbility(FF2_GetBossIndex(g_iBoss), this_plugin_name, "rage_pkfire"))
			AcceptEntityInput(iEntity, "Kill");
	}
	
	if(StrEqual(sClassName, "tf_projectile_jar", true))
	{
		SDKHook(iEntity, SDKHook_SpawnPost, BombThrow);
	}
}

public void OnEntityDestroyed(int iEntity)
{
	if(!IsValidEntity(iEntity))
		return;
	char sClassName[96];
	if(GetEntityClassname(iEntity, sClassName, sizeof(sClassName)))
	{
		if(!strcmp(sClassName, "tf_projectile_spellfireball"))
		{
			float vEntOrigin[3], vClientOrigin[3];
			GetEntPropVector(iEntity, Prop_Data, "m_vecAbsOrigin", vEntOrigin);
			for(int iClient = MaxClients; iClient; iClient--)
			{
				if(IsClientInGame(iClient) && IsPlayerAlive(iClient) && GetClientTeam(iClient) != BossTeam)
				{
					GetClientAbsOrigin(iClient, vClientOrigin);
					if(GetVectorDistance(vEntOrigin, vClientOrigin) <= PKSS_BlastRadius[g_iBoss])
					{
						SDKHooks_TakeDamage(iClient, iEntity, g_iBoss, PKSS_Damage[g_iBoss], DMG_GENERIC);
						TF2_IgnitePlayer(iClient, g_iBoss);
					}
				}
			}
		}
		
		if(!strcmp(sClassName, "tf_projectile_rocket"))
		{
			int iClient = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity");
			int iBoss = FF2_GetBossIndex(iClient);
			if(iBoss >= 0 && FF2_HasAbility(iBoss, this_plugin_name, "special_blackholerockets"))
			{
				char sOutput[64];
				int iParticle;
				float vPos[3];
				
				GetEntPropVector(iEntity, Prop_Data, "m_vecOrigin", vPos);
				
				iParticle = CreateEntityByName("info_particle_system");
				TeleportEntity(iParticle, vPos, NULL_VECTOR, NULL_VECTOR);
				DispatchKeyValue(iParticle, "effect_name", "eb_tp_vortex01");
				DispatchSpawn(iParticle);
				ActivateEntity(iParticle);
				AcceptEntityInput(iParticle, "Start");
				Format(sOutput, sizeof(sOutput), "OnUser1 !self:Kill::%.1f:1", BH_Duration[iClient]);
				SetVariantString(sOutput);
				AcceptEntityInput(iParticle, "AddOutput"); 
				AcceptEntityInput(iParticle, "FireUser1");
				
				iParticle = CreateEntityByName("info_particle_system");
				TeleportEntity(iParticle, vPos, NULL_VECTOR, NULL_VECTOR);
				DispatchKeyValue(iParticle, "effect_name", "raygun_projectile_blue_crit");
				DispatchSpawn(iParticle);
				ActivateEntity(iParticle);
				AcceptEntityInput(iParticle, "Start");
				Format(sOutput, sizeof(sOutput), "OnUser1 !self:Kill::%.1f:1", BH_Duration[iClient]);
				SetVariantString(sOutput);
				AcceptEntityInput(iParticle, "AddOutput"); 
				AcceptEntityInput(iParticle, "FireUser1");
				
				iParticle = CreateEntityByName("info_particle_system");
				TeleportEntity(iParticle, vPos, NULL_VECTOR, NULL_VECTOR);
				DispatchKeyValue(iParticle, "effect_name", "eyeboss_vortex_blue");
				DispatchSpawn(iParticle);
				ActivateEntity(iParticle);
				AcceptEntityInput(iParticle, "Start");
				Format(sOutput, sizeof(sOutput), "OnUser1 !self:Kill::%.1f:1", BH_Duration[iClient]);
				SetVariantString(sOutput);
				AcceptEntityInput(iParticle, "AddOutput"); 
				AcceptEntityInput(iParticle, "FireUser1");
				
				DataPack hPack;
				CreateDataTimer(0.1, Timer_Pull, hPack, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
				hPack.WriteFloat(GetEngineTime() + BH_Duration[iClient]);
				hPack.WriteFloat(vPos[0]);
				hPack.WriteFloat(vPos[1]);
				hPack.WriteFloat(vPos[2]);
				hPack.WriteCell(GetClientUserId(iClient));
			}
		}
	}
}

public void BombThrow(entity)
{
	int parent = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
	if(parent == g_iBoss)
	{
		float pos[3], vec[3], ang[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
		GetClientEyeAngles(parent, ang);
		float tempvec[3];
		GetAngleVectors(ang, tempvec, NULL_VECTOR, NULL_VECTOR);
		ScaleVector(tempvec, 20.0);
		AddVectors(pos, tempvec, pos);
		
		int ent2 = CreateEntityByName("prop_physics_override");
		AcceptEntityInput(entity, "Kill");
		if(IsValidEntity(ent2))
		{					
			DispatchKeyValue(ent2, "model", BOMBMODEL);
			DispatchKeyValue(ent2, "solid", "6");
			DispatchKeyValue(ent2, "renderfx", "0");
			DispatchKeyValue(ent2, "rendercolor", "255 255 255");
			DispatchKeyValue(ent2, "renderamt", "255");
			SetEntPropEnt(ent2, Prop_Data, "m_hOwnerEntity", parent);
			DispatchSpawn(ent2);
			GetAngleVectors(ang, vec, NULL_VECTOR, NULL_VECTOR);
			ScaleVector(vec, 2000.0);

			TeleportEntity(ent2, pos, ang, vec);
		
			CreateTimer((GetURandomFloat() + 0.1) / 1.75 + 0.5, ExplodeBomblet, ent2, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public Action:ExplodeBomblet(Handle:timer, any:ent)
{
	if (IsValidEntity(ent))
	{
		decl Float:pos[3];
		GetEntPropVector(ent, Prop_Data, "m_vecOrigin", pos);
		pos[2] += 32.0;

		new client = GetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity");
		new team = GetEntProp(client, Prop_Send, "m_iTeamNum");

		AcceptEntityInput(ent, "Kill");
		new BombMagnitude = BMB_Damage[client];
		new explosion = CreateEntityByName("env_explosion");
		if (explosion != -1)
		{
			decl String:tMag[8];
			IntToString(BombMagnitude, tMag, sizeof(tMag));
			DispatchKeyValue(explosion, "iMagnitude", tMag);
			DispatchKeyValue(explosion, "spawnflags", "0");
			DispatchKeyValue(explosion, "rendermode", "5");
			SetEntProp(explosion, Prop_Send, "m_iTeamNum", team);
			SetEntPropEnt(explosion, Prop_Data, "m_hOwnerEntity", client);
			DispatchSpawn(explosion);
			ActivateEntity(explosion);

			TeleportEntity(explosion, pos, NULL_VECTOR, NULL_VECTOR);				
			AcceptEntityInput(explosion, "Explode");
			AcceptEntityInput(explosion, "Kill");
		}		
	}
}

public Action OnTakeDamage(int iClient, int &iAttacker, int &iInflictor, float &flDamage, int &iDmgType, int &iWep, float flDmgForce[3], float flDmgPos[3], int iDmgCstm)
{
	if (!IsValidClient(iAttacker) || !IsValidClient(iClient))
		return Plugin_Continue;	
	int iBoss = FF2_GetBossIndex(iAttacker);
	if(iBoss >= 0)
	{
		if(!IsValidEntity(iInflictor))
			return Plugin_Continue;
		char sClassName[96];
		if(GetEntityClassname(iInflictor, sClassName, sizeof(sClassName)))
		{
			if(FF2_HasAbility(iBoss, this_plugin_name, "rage_pkfire"))
			{
				if(StrEqual(sClassName, "tf_projectile_spellmeteorshower"))
				{
					flDamage = PKF_Damage[iAttacker];
					if(PKF_AfterburnDur[iAttacker])
					{
						TF2_IgnitePlayer(iClient, iAttacker);
						CreateTimer(PKF_AfterburnDur[iAttacker], ExtinguishPlayer, iClient, TIMER_FLAG_NO_MAPCHANGE);
					}
					return Plugin_Changed;
				}
			}
			
			if(FF2_HasAbility(iBoss, this_plugin_name, "rage_electric"))
			{
				if(StrEqual(sClassName, "tf_projectile_lightningorb"))
				{
					flDamage = SMS_Damage[iAttacker];
					return Plugin_Changed;
				}
			}
		}
	}
	
	iBoss = FF2_GetBossIndex(iClient);
	if(iBoss >= 0 && FF2_HasAbility(iBoss, this_plugin_name, "rage_dmgreflect"))
	{
		SDKHooks_TakeDamage(iAttacker, iClient, iClient, flDamage, DMG_GENERIC);
	}
	return Plugin_Continue;
}

public void OnWeaponSwitch(int iClient, int iWeapon)
{
	if(iWeapon == GetPlayerWeaponSlot(iClient, TFWeaponSlot_Primary))
	{
		if(strlen(HotSwapModel[iClient][0]) > 5)
		{
			SetVariantString(HotSwapModel[iClient][0]);
			AcceptEntityInput(iClient, "SetCustomModel");
			SetEntProp(iClient, Prop_Send, "m_bUseClassAnimations", 1, 1);
		}
	}
	else if (iWeapon == GetPlayerWeaponSlot(iClient, TFWeaponSlot_Secondary))
	{
		if(strlen(HotSwapModel[iClient][1]) > 5)
		{
			SetVariantString(HotSwapModel[iClient][1]);
			AcceptEntityInput(iClient, "SetCustomModel");
			SetEntProp(iClient, Prop_Send, "m_bUseClassAnimations", 1, 1);
		}
	}
	else if (iWeapon == GetPlayerWeaponSlot(iClient, TFWeaponSlot_Melee))
	{
		if(strlen(HotSwapModel[iClient][2]) > 5)
		{
			SetVariantString(HotSwapModel[iClient][2]);
			AcceptEntityInput(iClient, "SetCustomModel");
			SetEntProp(iClient, Prop_Send, "m_bUseClassAnimations", 1, 1);
		}
	}
}

public Action OnPlayerRunCmd(int iClient, int &iButtons, int &iImpulse, float vVel[3], float vAng[3], int &iWeapon, int &iIndex, int &iSlot)
{	
	if(!IsValidClient(iClient, true, true))
		return Plugin_Continue;
	
	if(!FF2_IsFF2Enabled() || FF2_GetRoundState() != 1)
		return Plugin_Continue;
	
	if(Noclip_CanUse[iClient])
	{
		if(GetEntityMoveType(iClient) == MOVETYPE_NOCLIP)
		{
			new Float:flFallVel = GetEntPropFloat(iClient, Prop_Send, "m_flFallVelocity") * -1.0;

			if(iButtons & IN_JUMP)
			{
				if (flFallVel <= NC_Speed[iClient] * -1 + 20)
					vVel[2] = NC_Speed[iClient] / 2;
				else
					vVel[2] = NC_Speed[iClient];
			}

			if(iButtons & IN_DUCK)
			{
				if (flFallVel >= NC_Speed[iClient] - 20)
					vVel[2] = NC_Speed[iClient] / -2;
				else
					vVel[2] = NC_Speed[iClient] * -1;
			}
			
			if(vVel[0] > NC_Speed[iClient]) vVel[0] = NC_Speed[iClient];
			if(vVel[1] > NC_Speed[iClient]) vVel[1] = NC_Speed[iClient];
			
			return Plugin_Changed;
		}
	}
	
	int iBoss = FF2_GetBossIndex(iClient);
	if(iBoss >= 0 && FF2_HasAbility(iBoss, this_plugin_name, "special_rocktoss"))
	{
		if(iButtons & IN_ATTACK)
		{
			if(GetEngineTime() >= GRN_NextShot[iClient])
			{
				int iGrenade = CreateEntityByName("tf_projectile_pipe");
				if(IsValidEntity(iGrenade) && IsValidEdict(iGrenade))
				{
					SetEntPropEnt(iGrenade, Prop_Send, "m_hOwnerEntity", iClient);
			
					SetVariantInt(BossTeam);
					AcceptEntityInput(iGrenade, "TeamNum", -1, -1);
					SetVariantInt(BossTeam);
					AcceptEntityInput(iGrenade, "SetTeam", -1, -1); 
					
					float vOrigin[3], vAngles[3], vVelocity[3];
					GetClientEyePosition(iClient, vOrigin);
					GetClientEyeAngles(iClient, vAngles);
					
					GetAngleVectors(vAngles, vVelocity, NULL_VECTOR, NULL_VECTOR);
					NormalizeVector(vVelocity, vVelocity);
					ScaleVector(vVelocity, GRN_Speed[iClient]);
					
					TeleportEntity(iGrenade, vOrigin, vAngles, vVelocity);
					DispatchSpawn(iGrenade);
					
					SDKHook(iGrenade, SDKHook_StartTouch, OnRockTouch);
					
					SetEntPropFloat(iGrenade, Prop_Data, "m_flDamage", GRN_Damage[iClient]);
					SetEntPropFloat(iGrenade, Prop_Data, "m_DmgRadius", 20.0);
					SetEntPropFloat(iGrenade, Prop_Data, "m_flDetonateTime", 99.0);
					
					char sound[PLATFORM_MAX_PATH];
					if (FF2_RandomSound("sound_ability", sound, PLATFORM_MAX_PATH, iBoss, 4))
					{
						EmitSoundToAll(sound, iClient, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, iClient, vOrigin, NULL_VECTOR, true, 0.0);
						EmitSoundToAll(sound, iClient, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, iClient, vOrigin, NULL_VECTOR, true, 0.0);

						for (int enemy = 1; enemy < MaxClients; enemy++)
						{
							if (IsClientInGame(enemy) && enemy != iClient)
							{
								EmitSoundToClient(enemy, sound, iClient, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, iClient, vOrigin, NULL_VECTOR, true, 0.0);
								EmitSoundToClient(enemy, sound, iClient, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, iClient, vOrigin, NULL_VECTOR, true, 0.0);
							}
						}
					}
				}
				
				GRN_NextShot[iClient] = (GetEngineTime() + GRN_FireDelay[iClient]);
			}
			else iButtons &= ~IN_ATTACK;
		}
	}
	
	return Plugin_Continue;
}

public Action OnRockTouch(int iEntity, int iOther)
{
	if(iOther <= 0 || iOther >= MAXPLAYERS)
	{
		AcceptEntityInput(iEntity, "Kill");
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

public Action FF2_OnAbility2(int iBoss, const char[] pluginName, const char[] abilityName, int iStatus)
{
	int iClient = GetClientOfUserId(FF2_GetBossUserId(iBoss));
	if(!strcmp(abilityName, "rage_starstorm"))
		Rage_StarStorm(iClient);
	else if(!strcmp(abilityName, "rage_pkthunder"))
		Rage_Thunder(iClient);
	else if(!strcmp(abilityName, "rage_pkfire"))
		Rage_Fire(iClient);
	else if (!strcmp(abilityName, "rage_blind"))
		Rage_Blind(iBoss, pluginName, abilityName);
	else if (!strcmp(abilityName, "rage_noclip"))
		Rage_Noclip(iClient);
	else if (!strcmp(abilityName, "rage_explosiveminion"))
		Rage_Minion(iClient);
	else if(!strcmp(abilityName, "rage_volcano"))
		Rage_Volcano(iClient);
	else if(!strcmp(abilityName, "rage_propspawn"))
		Rage_PropSpawn(iClient);
	else if(!strcmp(abilityName, "rage_bombs"))
		Rage_Bombs(iClient);
	else if(!strcmp(abilityName, "rage_dmgreflect"))
		Rage_Reflect(iBoss, pluginName, abilityName);
	else if(!strcmp(abilityName, "rage_electric"))
		Rage_Electric(iBoss, pluginName, abilityName);
	else if(!strcmp(abilityName, "rage_powerstar"))
		Rage_PowerStar(iClient);
	return Plugin_Continue;
}

public Action FF2_OnLoseLife(int iBoss, int &iLives, int maxLives)
{
	int iClient = GetClientOfUserId(FF2_GetBossUserId(iBoss));
	if(FF2_HasAbility(iBoss, this_plugin_name, "special_porkypassive_health"))
	{
		int iPlaying;
		for(int i = 1; i < MAXPLAYERS; i++)
		{
			if(IsClientConnected(i) && IsClientInGame(i))
				iPlaying++;
		}
		
		int iNewHealth = ParseFormula(iBoss, PP_HealthFormula[iClient][iLives], RoundFloat((((768.0 + float(iPlaying))* float(iPlaying))^ 1.034)/ maxLives), iPlaying);
		FF2_SetBossMaxHealth(iBoss, iNewHealth);
		FF2_SetBossHealth(iBoss, iNewHealth);
	}
	
	if(FF2_HasAbility(iBoss, this_plugin_name, "special_porkypassive_rage"))
	{
		FF2_SetBossRageDamage(iBoss, PP_RageAmount[iClient][iLives]);
		FF2_SetBossCharge(iBoss, 0, 0.0);
	}
}

public bool STRM_CanInvoke(int iClient) {
	return true;
}

public void Rage_StarStorm(int iClient)
{
	if(PKStarStorm_TriggerAMS[iClient])
		return;
	
	STRM_Invoke(iClient);
}

public void STRM_Invoke(int iClient)
{
	SDKHook(iClient, SDKHook_PreThink, StarStorm_Think);
	if(PKSS_FreezeMovement[iClient])
		SetEntityMoveType(iClient, MOVETYPE_NONE);
	
	int iBoss = FF2_GetBossIndex(iClient);
	char sSound[PLATFORM_MAX_PATH]; float vPos[3];
	GetClientAbsOrigin(iClient, vPos);
	if (FF2_RandomSound("sound_ability", sSound, PLATFORM_MAX_PATH, iBoss, 5))
	{
		EmitSoundToAll(sSound, iClient, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, iClient, vPos, NULL_VECTOR, true, 0.0);

		for (int iEnemy=MaxClients; iEnemy>0 ; iEnemy--)
		{
			if (IsClientInGame(iEnemy) && iEnemy != iClient)
			{
				EmitSoundToClient(iEnemy, sSound, iClient, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, iClient, vPos, NULL_VECTOR, true, 0.0);
			}
		}
	}
}

public void StarStorm_Think(int iClient)
{
	if(!FF2_IsFF2Enabled() || FF2_GetRoundState() != 1)
		SDKUnhook(iClient, SDKHook_PreThink, StarStorm_Think);
	
	if(PKSS_Shots[iClient] >= PKSS_MaxSpawns[iClient])
	{
		PKSS_Shots[iClient] = 0;
		SDKUnhook(iClient, SDKHook_PreThink, StarStorm_Think);
		if(PKSS_FreezeMovement[iClient])
			SetEntityMoveType(iClient, MOVETYPE_WALK);
	}
	
	static float flShootAt;
	if(PKSS_Delay[iClient] <= 0.0 || GetEngineTime() >= flShootAt)
	{
		new iRocket = CreateEntityByName("tf_projectile_spellfireball");
		if(IsValidEdict(iRocket))
		{
			SetEntPropEnt(iRocket, Prop_Send, "m_hOwnerEntity", iClient);
			
			SetVariantInt(BossTeam);
			AcceptEntityInput(iRocket, "TeamNum", -1, -1, 0);
			SetVariantInt(BossTeam);
			AcceptEntityInput(iRocket, "SetTeam", -1, -1, 0); 
			
			float vOrigin[3], vAngles[3], vVelocity[3];
			GetClientAbsOrigin(iClient, vOrigin);
			vOrigin[0] += GetRandomFloat(-PKSS_Radius[iClient], PKSS_Radius[iClient]);
			vOrigin[1] += GetRandomFloat(-PKSS_Radius[iClient], PKSS_Radius[iClient]);
			vOrigin[2] += 800.0;
			
			vAngles[0] = GetRandomFloat(50.0, 89.5);
			vAngles[1] = GetRandomFloat(-179.9, 179.9);
			vAngles[2] = 0.0;
			
			GetAngleVectors(vAngles, vVelocity, NULL_VECTOR, NULL_VECTOR);
			NormalizeVector(vVelocity, vVelocity);
			ScaleVector(vVelocity, PKSS_Speed[iClient]);
			
			TeleportEntity(iRocket, vOrigin, vAngles, vVelocity);
			DispatchSpawn(iRocket);
			
			PKSS_Shots[iClient]++;
		}
		
		if(PKSS_Delay[iClient] > 0.0)
			flShootAt = GetEngineTime()+PKSS_Delay[iClient];
	}
}

public bool THND_CanInvoke(int iClient) {
	return true;
}

public void Rage_Thunder(int iClient)
{
	if(PKThunder_TriggerAMS[iClient])
		return;
	
	THND_Invoke(iClient);
}

public void THND_Invoke(int iClient)
{
	if(IsValidClient(iClient, true, true))
	{
		if(PKT_FreezeMovement[iClient])
			SetEntityMoveType(iClient, MOVETYPE_NONE);
		
		PKT_LifeTime = 0;
		
		float vOrigin[3], vAngles[3], vVelocity[3];
		GetClientEyePosition(iClient, vOrigin);
		GetClientEyeAngles(iClient, vAngles);
		
		int iProj = CreateEntityByName("tf_projectile_energy_ball");
		SetVariantInt(BossTeam);
		AcceptEntityInput(iProj, "TeamNum", -1, -1, 0);
		SetVariantInt(BossTeam);
		AcceptEntityInput(iProj, "SetTeam", -1, -1, 0); 
		SetEntPropEnt(iProj, Prop_Send, "m_hOwnerEntity", iClient);
		
		vVelocity[0] = Cosine(DegToRad(vAngles[0]))*Cosine(DegToRad(vAngles[1]))*PKT_Speed[iClient];
		vVelocity[1] = Cosine(DegToRad(vAngles[0]))*Sine(DegToRad(vAngles[1]))*PKT_Speed[iClient];
		vVelocity[2] = Sine(DegToRad(vAngles[0]))*PKT_Speed[iClient];
		vVelocity[2]*=-1;
		
		TeleportEntity(iProj, vOrigin, vAngles, vVelocity);
		SetEntDataFloat(iProj, FindSendPropInfo("CTFProjectile_Rocket", "m_iDeflected") + 4, PKT_Damage[iClient], true);
		DispatchSpawn(iProj);
		
		if(strlen(PKT_Particle[iClient]) > 2)
			CreateTimer(15.0, RemoveEnt, EntIndexToEntRef(AttachParticle(iProj, PKT_Particle[iClient], _, true)));
		
		CreateTimer(0.01, Timer_RocketTurn, EntIndexToEntRef(iProj), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(1.0, Timer_RocketLife, EntIndexToEntRef(iProj), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		
		int iBoss = FF2_GetBossIndex(iClient);
		char sSound[PLATFORM_MAX_PATH]; float vPos[3];
		GetClientAbsOrigin(iClient, vPos);
		if (FF2_RandomSound("sound_ability", sSound, PLATFORM_MAX_PATH, iBoss, 6))
		{
			EmitSoundToAll(sSound, iClient, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, iClient, vPos, NULL_VECTOR, true, 0.0);

			for (int iEnemy=MaxClients; iEnemy; iEnemy--)
			{
				if (IsClientInGame(iEnemy) && iEnemy != iClient)
				{
					EmitSoundToClient(iEnemy, sSound, iClient, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, iClient, vPos, NULL_VECTOR, true, 0.0);
				}
			}
		}
	}
}

public bool FRBL_CanInvoke(int iClient) {
	return true;
}

public void Rage_Fire(int iClient)
{
	if(PKFire_TriggerAMS[iClient])
		return;
	
	FRBL_Invoke(iClient);
}

public void FRBL_Invoke(int iClient)
{
	CreateTimer(PKF_Delay[iClient], FireFireball, iClient, TIMER_FLAG_NO_MAPCHANGE);
	
	int iBoss = FF2_GetBossIndex(iClient);
	char sSound[PLATFORM_MAX_PATH]; float vPos[3];
	GetClientAbsOrigin(iClient, vPos);
	if (FF2_RandomSound("sound_ability", sSound, PLATFORM_MAX_PATH, iBoss, 7))
	{
		EmitSoundToAll(sSound, iClient, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, iClient, vPos, NULL_VECTOR, true, 0.0);

		for (int iEnemy=MaxClients; iEnemy; iEnemy--)
		{
			if (IsClientInGame(iEnemy) && iEnemy != iClient)
			{
				EmitSoundToClient(iEnemy, sSound, iClient, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, iClient, vPos, NULL_VECTOR, true, 0.0);
			}
		}
	}
}

public bool NCLP_CanInvoke(int iClient)
{
	return true;
}

public void Rage_Noclip(int iClient)
{
	if(Noclip_TriggerAMS[iClient])
		return;
	
	NCLP_Invoke(iClient);
}

public void NCLP_Invoke(int iClient)
{
	float flDuration = FF2_GetAbilityArgumentFloat(FF2_GetBossIndex(iClient), this_plugin_name, "rage_noclip", 3, 8.0);
	SetEntityMoveType(iClient, MOVETYPE_NOCLIP);
	SetEntProp(iClient, Prop_Send, "m_CollisionGroup", 5);
	CreateTimer(flDuration, ResetClient, iClient, TIMER_FLAG_NO_MAPCHANGE);
}

public void Minion_Think(int iClient)
{
	if(GetClientButtons(iClient) & IN_ATTACK)
	{
		FakeClientCommand(iClient, "explode");	// Event_PlayerDeath should handle the explosion
		SDKUnhook(iClient, SDKHook_PreThink, Minion_Think);
		return;
	}
	
	SetEntPropFloat(iClient, Prop_Data, "m_flMaxspeed", EM_Speed[g_iBoss]);
}

public bool EM_CanInvoke(int iClient) {
	return true;
}

public void Rage_Minion(int iClient)
{
	if(ExplosiveMinion_TriggerAMS[iClient])
		return;
	
	EM_Invoke(iClient);
}

public void EM_Invoke(int iClient)
{
	int iAlive, iDead;
	ArrayList hArray = new ArrayList(1);
	for(int iTarget = 1; iTarget <= MaxClients; iTarget++)
	{
		if(IsValidClient(iTarget))
		{
			if(view_as<TFTeam>(GetClientTeam(iTarget)) != TFTeam_Spectator)
			{
				if(IsPlayerAlive(iTarget))
				{
					iAlive++;
				}
				else if(FF2_GetBossIndex(iTarget) == -1)
				{
					hArray.Push(iTarget);
					iDead++;
				}
			}
		}
	}
	
	int iTotal = (EM_Ratio[iClient] ? RoundToCeil(iAlive * EM_Ratio[iClient]) : MaxClients);
	int iMinion, iTemp;
	for(int i = 1; i <= iDead && i <= iTotal; i++)
	{
		iTemp = GetRandomInt(0, hArray.Length - 1);
		iMinion = hArray.Get(iTemp);
		hArray.Erase(iTemp);
		
		FF2_SetFF2flags(iMinion, FF2_GetFF2flags(iMinion)|FF2FLAG_ALLOWSPAWNINBOSSTEAM|FF2FLAG_CLASSTIMERDISABLED);
		
		TFClassType iClass = (EM_Class[iClient] == -1) ? view_as<TFClassType>(GetRandomInt(1, 9)) : view_as<TFClassType>(EM_Class[iClient]);
		TF2_SetPlayerClass(iMinion, iClass, _, false);
		ChangeClientTeam(iMinion, BossTeam);
		TF2_RespawnPlayer(iMinion);
		
		CloneOwnerIndex[iMinion] = iClient;
		
		TF2_RemoveWeaponSlot(iMinion, TFWeaponSlot_Primary);
		TF2_RemoveWeaponSlot(iMinion, TFWeaponSlot_Secondary);
		
		if(strlen(EM_Model[iClient]) > 5)
		{
			SetVariantString(EM_Model[iClient]);
			AcceptEntityInput(iMinion, "SetCustomModel");
			SetEntProp(iMinion, Prop_Send, "m_bUseClassAnimations", 1, 1);
		}
		
		if(EM_Health[iClient])
		{
			SetEntProp(iMinion, Prop_Data, "m_iMaxHealth", EM_Health[iClient]);
			SetEntProp(iMinion, Prop_Data, "m_iHealth", EM_Health[iClient]);
			SetEntProp(iMinion, Prop_Send, "m_iHealth", EM_Health[iClient]);
		}
		
		float vPos[3], vVel[3];
		GetClientAbsOrigin(iClient, vPos);
		for(int x = 0; x < 3; x++) vVel[x] = GetRandomFloat(-500.0, 500.0);
		TeleportEntity(iMinion, vPos, NULL_VECTOR, vVel);
		TF2_AddCondition(iMinion, TFCond_UberchargedHidden, 5.0);
		SDKHook(iMinion, SDKHook_PreThink, Minion_Think);
		
		PrintCenterText(iMinion, "You are an explosive minion, die or press Attack to explode!");
		EM_Minions[iClient][EM_MinionCount[iClient]++] = iMinion;
	}
	delete hArray;
	
	int iEntity, iOwner;
	while((iEntity=FindEntityByClassname(iEntity, "tf_wearable*"))!=-1)
	{
		if((iOwner=GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity"))<=MaxClients && iOwner>0 && GetClientTeam(iOwner)==BossTeam)
		{
			TF2_RemoveWearable(iOwner, iEntity);
		}
	}
	iEntity = -1;
	while((iEntity=FindEntityByClassname(iEntity, "tf_powerup_bottle"))!=-1)
	{
		if((iOwner=GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity"))<=MaxClients && iOwner>0 && GetClientTeam(iOwner)==BossTeam)
		{
			TF2_RemoveWearable(iOwner, iEntity);
		}
	}
}

public bool VLCN_CanInvoke(int iClient) {
	return true;
}

public void Rage_Volcano(int iClient)
{
	if(Volcano_TriggerAMS[iClient])
		return;
	
	VLCN_Invoke(iClient);
}

public void VLCN_Invoke(int iClient)
{
	SDKHook(iClient, SDKHook_PreThink, Volcano_Think);
	
	int iBoss = FF2_GetBossIndex(iClient);
	char sSound[PLATFORM_MAX_PATH]; float vPos[3];
	GetClientAbsOrigin(iClient, vPos);
	if (FF2_RandomSound("sound_ability", sSound, PLATFORM_MAX_PATH, iBoss, 5))
	{
		EmitSoundToAll(sSound, iClient, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, iClient, vPos, NULL_VECTOR, true, 0.0);

		for (int iEnemy=MaxClients; iEnemy>0 ; iEnemy--)
		{
			if (IsClientInGame(iEnemy) && iEnemy != iClient)
			{
				EmitSoundToClient(iEnemy, sSound, iClient, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, iClient, vPos, NULL_VECTOR, true, 0.0);
			}
		}
	}
}

public void Volcano_Think(int iClient)
{
	if(!FF2_IsFF2Enabled() || FF2_GetRoundState() != 1)
		SDKUnhook(iClient, SDKHook_PreThink, Volcano_Think);
	
	if(VLCN_Shots[iClient] >= VLCN_MaxSpawns[iClient])
	{
		VLCN_Shots[iClient] = 0;
		SDKUnhook(iClient, SDKHook_PreThink, Volcano_Think);
	}
	
	static float flShootAt;
	if(VLCN_SpawnDelay[iClient] <= 0.0 || GetEngineTime() >= flShootAt)
	{
		new iGrenade = CreateEntityByName("tf_projectile_pipe");
		if(IsValidEdict(iGrenade))
		{
			SetEntPropEnt(iGrenade, Prop_Send, "m_hOwnerEntity", iClient);
			
			SetVariantInt(BossTeam);
			AcceptEntityInput(iGrenade, "TeamNum", -1, -1, 0);
			SetVariantInt(BossTeam);
			AcceptEntityInput(iGrenade, "SetTeam", -1, -1, 0); 
			
			float vOrigin[3], vAngles[3], vVelocity[3];
			GetClientAbsOrigin(iClient, vOrigin);
			vOrigin[0] += GetRandomFloat(-VLCN_Radius[iClient], VLCN_Radius[iClient]);
			vOrigin[1] += GetRandomFloat(-VLCN_Radius[iClient], VLCN_Radius[iClient]);
			vOrigin[2] += 10.0;
			
			vAngles[0] = -90.0;
			vAngles[1] = 0.0;
			vAngles[2] = 0.0;
			
			GetAngleVectors(vAngles, vVelocity, NULL_VECTOR, NULL_VECTOR);
			NormalizeVector(vVelocity, vVelocity);
			ScaleVector(vVelocity, VLCN_Speed[iClient]);
			
			TeleportEntity(iGrenade, vOrigin, vAngles, vVelocity);
			DispatchSpawn(iGrenade);
			
			SetEntityModel(iGrenade, VLCN_Model[iClient]);
			
			SetEntPropFloat(iGrenade, Prop_Data, "m_flDamage", VLCN_Damage[iClient]);
			SetEntPropFloat(iGrenade, Prop_Data, "m_DmgRadius", VLCN_BlastRadius[iClient]);
			SetEntPropFloat(iGrenade, Prop_Data, "m_flDetonateTime", VLCN_FuseTime[iClient]);
			
			VLCN_Shots[iClient]++;
		}
		
		if(VLCN_SpawnDelay[iClient] > 0.0)
			flShootAt = GetEngineTime()+VLCN_SpawnDelay[iClient];
	}
}

public bool PRP_CanInvoke(int iClient) {
	return true;
}

public void Rage_PropSpawn(int iClient)
{
	if(Prop_TriggerAMS[iClient])
		return;
	
	PRP_Invoke(iClient);
}

public void PRP_Invoke(int iClient)
{
	int iProp = CreateEntityByName("prop_dynamic");
	if(IsValidEntity(iProp))
	{
		SetEntityModel(iProp, PRP_Model[iClient]);
		
		float vTargetPos[3];
		GetPlayerEye(iClient, vTargetPos);
		vTargetPos[2] -= 128.0;
		
		TeleportEntity(iProp, vTargetPos, NULL_VECTOR, NULL_VECTOR);
		
		CreateTimer(0.1, Timer_PropPopup, EntIndexToEntRef(iProp), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(7.5, RemoveEnt, EntIndexToEntRef(iProp), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public bool BMB_CanInvoke(int iClient) {
	return true;
}

public void Rage_Bombs(int iClient)
{
	if(Bomb_TriggerAMS[iClient])
		return;
	
	BMB_Invoke(iClient);
}

public void BMB_Invoke(int iClient)
{
	if(GetPlayerWeaponSlot(iClient, 1) <= 0)
	{
		new Handle:hWeapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
		if (hWeapon != INVALID_HANDLE)
		{
			TF2Items_SetClassname(hWeapon, "tf_weapon_jar");
			TF2Items_SetItemIndex(hWeapon, 58);
			TF2Items_SetLevel(hWeapon, 100);
			TF2Items_SetQuality(hWeapon, 5);
			TF2Items_SetNumAttributes(hWeapon, 1); // Atrib Number Total
			
			TF2Items_SetAttribute(hWeapon, 0, 134, 4.0);
			
			new iWeapon = TF2Items_GiveNamedItem(iClient, hWeapon);
			EquipPlayerWeapon(iClient, iWeapon);
			CloseHandle(hWeapon);
			SetEntProp(iWeapon, Prop_Send, "m_iWorldModelIndex", 0);
		}
	}
	
	SetJarAmmo(iClient, 50);
	SetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon", GetPlayerWeaponSlot(iClient, 1));
}

stock SetJarAmmo(iClient, newAmmo)
{
	new iWeapon = GetPlayerWeaponSlot(iClient, 1);
	if (IsValidEntity(iWeapon))
	{
		if (GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex") == 58)
		{    
			new iOffset = GetEntProp(iWeapon, Prop_Send, "m_iPrimaryAmmoType", 1)*4;
			new iAmmoTable = FindSendPropInfo("CTFPlayer", "m_iAmmo");
			SetEntData(iClient, iAmmoTable+iOffset, newAmmo, 4, true);
		}
	}
}

public bool PS_CanInvoke(int iClient) {
	return true;
}

public void Rage_PowerStar(int iClient)
{
	if(PowerStar_TriggerAMS[iClient])
		return;
	
	PS_Invoke(iClient);
}

public void PS_Invoke(int iClient)
{	
	int iProp = CreateEntityByName("prop_dynamic");
	if(IsValidEntity(iProp))
	{
		float vOrigin[3];
		GetClientEyePosition(iClient, vOrigin);
		vOrigin[2] += 128.0;
		
		DispatchKeyValue(iProp, "model", PS_PropModel[iClient]);
		
		DispatchSpawn(iProp);
		TeleportEntity(iProp, vOrigin, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(iProp, "Start");
		
		SetEntityMoveType(iProp, MOVETYPE_NONE);
		
		CreateTimer(PS_ShootTime[iClient], Timer_PowerStarFire, EntIndexToEntRef(iProp), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		
		char sOutput[32];
		Format(sOutput, sizeof(sOutput), "OnUser1 !self:Kill::%f:1", PS_Duration[iClient] + 1.0);
		SetVariantString(sOutput);
		AcceptEntityInput(iProp, "AddOutput"); 
		AcceptEntityInput(iProp, "FireUser1");
	}
}

public Action Timer_PowerStarFire(Handle hTimer, any iRef)
{
	if(!FF2_IsFF2Enabled() || FF2_GetRoundState() != 1)
		return Plugin_Stop;
	
	int iProp = EntRefToEntIndex(iRef);
	if(!IsValidEntity(iProp) || !IsValidEdict(iProp))
		return Plugin_Stop;
	
	int iRocket = CreateEntityByName("tf_projectile_rocket");
	if(IsValidEdict(iRocket))
	{
		SetEntPropEnt(iRocket, Prop_Send, "m_hOwnerEntity", g_iBoss);
		SetEntPropEnt(iRocket, Prop_Send, "m_hLauncher", g_iBoss);
		SetEntDataFloat(iRocket, FindSendPropInfo("CTFProjectile_Rocket", "m_iDeflected")+4, PS_ShotDamage[g_iBoss], true);

		DispatchSpawn(iRocket);
		
		SetVariantInt(BossTeam);
		AcceptEntityInput(iRocket, "TeamNum", -1, -1, 0);
		SetVariantInt(BossTeam);
		AcceptEntityInput(iRocket, "SetTeam", -1, -1, 0); 
		
		float vOrigin[3], vAngles[3], vVelocity[3], flMult;
		GetEntPropVector(iProp, Prop_Data, "m_vecAbsOrigin", vOrigin);
		vAngles[0] = GetRandomFloat(-179.9, 179.9);
		vAngles[1] = GetRandomFloat(-179.9, 179.9);
		vAngles[2] = GetRandomFloat(-89.9, -16.5);
		
		flMult = 56.0;
		vOrigin[0] += flMult * Cosine(DegToRad(vAngles[1]));
		vOrigin[1] += flMult * Sine(DegToRad(vAngles[1]));
		vOrigin[2] += 72.0 - flMult * Sine(DegToRad(vAngles[0]));
		
		flMult = 1100.0;
		GetAngleVectors(vAngles, vVelocity, NULL_VECTOR, NULL_VECTOR);
		NormalizeVector(vVelocity, vVelocity);
		ScaleVector(vVelocity, flMult);
		
		TeleportEntity(iRocket, vOrigin, vAngles, vVelocity);
		
		if(PS_ProjModel[g_iBoss][0])
			SetEntityModel(iRocket, PS_ProjModel[g_iBoss]);
		
		if(PS_ProjTrail[g_iBoss][0])
			AttachParticle(iRocket, PS_ProjTrail[g_iBoss], 0.0);
		
		decl Float:playerpos[3], Float:targetvector[3];
		decl playerarray[MAXPLAYERS+1];
		new playercount;
		for(new player = 1; player <= MaxClients; player++)
		{
			if(player != g_iBoss && IsClientInGame(player) && IsPlayerAlive(player))
			{
				GetClientEyePosition(player, playerpos);
				playerpos[2] -= 30.0;
				if(CanSeeTarget(vOrigin, playerpos, player, BossTeam))
				{
					playerarray[playercount] = player;
					playercount++;
				}
			}
		}

		if(playercount)
		{
			new ptarget = GetRandomInt(0, playercount-1);
			new target = playerarray[ptarget];
			if(GetRandomFloat(0.0, 1.0) <= PS_HomingChance[g_iBoss])
			{
	//			CreateTimer(0.01, Timer_Homing, EntIndexToEntRef(iRocket), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				MakeProjectileHoming(EntIndexToEntRef(iRocket), target, false, PS_Speed[g_iBoss]);
			}
		}
	}
	
	return Plugin_Continue;
}

public OnGameFrame()
{
	for(new i=GetArraySize(g_hArrayHoming)-1; i>=0; i--)
	{
		decl iData[3];
		GetArrayArray(g_hArrayHoming, i, iData);

		new iProjectile = EntRefToEntIndex(iData[0]);
		if(iProjectile != INVALID_ENT_REFERENCE)
		{
			HomingProjectile_Think(iProjectile, iData[1], i, Float:(iData[2]));
		}
		else
		{
			RemoveFromArray(g_hArrayHoming, i);
		}
	}
}

public HomingProjectile_Think(iProjectile, homing, index, Float:speed)
{   
    new iCurrentTarget = GetEntProp(iProjectile, Prop_Send, "m_nForceBone");

    if(!HomingProjectile_IsValidTarget(iCurrentTarget, iProjectile, GetEntProp(iProjectile, Prop_Send, "m_iTeamNum")))
    {
        if(homing)
        {
            HomingProjectile_FindTarget(iProjectile, speed);
        }
        else
        {
            RemoveFromArray(g_hArrayHoming, index);
        }
    }
    else
    {
        HomingProjectile_TurnToTarget(iCurrentTarget, iProjectile, speed);
    }
}

bool:HomingProjectile_IsValidTarget(client, iProjectile, iTeam)
{
    if(client > 0 && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) != iTeam)
    {
        if( TF2_IsPlayerInCondition(client, TFCond_Cloaked) ||
                (TF2_IsPlayerInCondition(client, TFCond_Disguised) && GetEntProp(client, Prop_Send, "m_nDisguiseTeam") == iTeam))
        {
            return false;
        }
        
        decl Float:flStart[3];
        GetClientEyePosition(client, flStart);
        decl Float:flEnd[3];
        GetEntPropVector(iProjectile, Prop_Send, "m_vecOrigin", flEnd);
        
        new Handle:hTrace = TR_TraceRayFilterEx(flStart, flEnd, MASK_SOLID, RayType_EndPoint, TraceFilterHoming, iProjectile);
        if(hTrace != INVALID_HANDLE)
        {
            if(TR_DidHit(hTrace))
            {
                CloseHandle(hTrace);
                return false;
            }
            
            CloseHandle(hTrace);
            return true;
        }
    }
    
    return false;
}

public bool:TraceFilterHoming(entity, contentsMask, any:iProjectile)
{
    if(entity == iProjectile || (entity >= 1 && entity <= MaxClients))
    {
        return false;
    }
    
    return true;
}

HomingProjectile_FindTarget(iProjectile, Float:speed)
{
    decl Float:flPos1[3];
    GetEntPropVector(iProjectile, Prop_Send, "m_vecOrigin", flPos1);
    
    new iBestTarget;
    new Float:flBestLength = 99999.9;
    for(new i=1; i<=MaxClients; i++)
    {
        if(HomingProjectile_IsValidTarget(i, iProjectile, GetEntProp(iProjectile, Prop_Send, "m_iTeamNum")))
        {
            decl Float:flPos2[3];
            GetClientEyePosition(i, flPos2);
            
            new Float:flDistance = GetVectorDistance(flPos1, flPos2);           
            if(flDistance < flBestLength)
            {
                iBestTarget = i;
                flBestLength = flDistance;
            }
        }
    }
    
    if(iBestTarget > 0 && iBestTarget <= MaxClients)
    {
        SetEntProp(iProjectile, Prop_Send, "m_nForceBone", iBestTarget);
        HomingProjectile_TurnToTarget(iBestTarget, iProjectile, speed);
    }
    else
    {
        SetEntProp(iProjectile, Prop_Send, "m_nForceBone", 0);
    }
}

HomingProjectile_TurnToTarget(client, iProjectile, Float:speed)					// update projectile position
{
    new Float:flTargetPos[3];
    GetClientAbsOrigin(client, flTargetPos);
    new Float:flRocketPos[3];
    GetEntPropVector(iProjectile, Prop_Send, "m_vecOrigin", flRocketPos);

    //flTargetPos[2] += 30 + Pow(GetVectorDistance(flTargetPos, flRocketPos), 2.0) / 10000;
    flTargetPos[2] += 30;
    
    new Float:flNewVec[3];
    SubtractVectors(flTargetPos, flRocketPos, flNewVec);
    NormalizeVector(flNewVec, flNewVec);
    
    new Float:flAng[3];
    GetVectorAngles(flNewVec, flAng);

    if(speed)
    {
        ScaleVector(flNewVec, speed);
    }
    else
    {
        decl Float:flRocketVel[3];
        GetEntPropVector(iProjectile, Prop_Data, "m_vecAbsVelocity", flRocketVel);
/**     // should not need smooth velocity implementation here
        if(flRocketVel[0] == 0.0 && gb_SV)
        {
            SDKCall(g_hSDKGetSmoothedVelocity, iProjectile, flRocketVel);
        }
**/
    
        ScaleVector(flNewVec, GetVectorLength(flRocketVel));
    }
    
    TeleportEntity(iProjectile, NULL_VECTOR, flAng, flNewVec);
}

public MakeProjectileHoming(int iProjectile, int target, bool lockon, float newspeed)
{
	SetEntProp(iProjectile, Prop_Send, "m_nForceBone", target);       // target to seek

	decl array[3];
	array[0] = EntIndexToEntRef(iProjectile);
	array[1] = lockon;
	array[2] = _:newspeed;
	PushArrayArray(g_hArrayHoming, array);                          // add to homing array
}

/*public Action Timer_Homing(Handle hTimer, any iProjectile)
{
//	int iProjectile = EntRefToEntIndex(iRef);
	if(!IsValidEntity(iProjectile) || FF2_GetRoundState() != 1)
		return Plugin_Stop;
	
	float vRocketDirection[3];
	float vOrigin[3], vAngles[3], vVelocity[3];
	GetEntPropVector(iProjectile, Prop_Send, "m_vecOrigin", vOrigin);
	GetEntPropVector(iProjectile, Prop_Send, "m_angRotation", vAngles);
	GetAngleVectors(vAngles, vRocketDirection, NULL_VECTOR, NULL_VECTOR);
		
	static int iTarget = -1;
	static float fTargetDist = -1.0;
	for(int iClient=MaxClients; iClient > 0; iClient--)
	{
		if(IsValidClient(iClient, true) && GetClientTeam(iClient) != BossTeam)
		{
			float vOrigin2[3];
			GetClientAbsOrigin(iClient, vOrigin2);
			
			float fDistance = GetVectorDistance(vOrigin, vOrigin2);
			if((fDistance <= fTargetDist) || fTargetDist == -1.0)
			{
				iTarget = iClient;
				fTargetDist = fDistance;
			}
		}
	}
	
	if(IsValidClient(iTarget, true))
	{
		float vTarget[3], vTargetVec[3];
		GetClientEyePosition(iTarget, vTarget);
		
		MakeVectorFromPoints(vOrigin, vTarget, vTargetVec);
		NormalizeVector(vTargetVec, vTargetVec);
		
		LerpVector(vRocketDirection, vTargetVec, vRocketDirection, 0.15);
		
		GetVectorAngles(vRocketDirection, vAngles);
		
		CopyVector(vRocketDirection, vVelocity);
		ScaleVector(vVelocity, PS_Speed[g_iBoss]);
		
		TeleportEntity(iProjectile, vOrigin, vAngles, vVelocity);
//		SetEntPropVector(iProjectile, Prop_Data, "m_vecAbsVelocity", vVelocity);
//		SetEntPropVector(iProjectile, Prop_Send, "m_angRotation", vAngles);
	}
	
	return Plugin_Continue;
}*/

public void Rage_Blind(int iBoss, const char[] abilityName, const char[] pluginName)
{
	int iClient = GetClientOfUserId(FF2_GetBossUserId(iBoss));
	float flDuration = FF2_GetAbilityArgumentFloat(iBoss, pluginName, abilityName, 1);
	float flDistance = FF2_GetAbilityArgumentFloat(iBoss, pluginName, abilityName, 3, FF2_GetRageDist(iBoss, pluginName, abilityName));
	int bBlindAll = FF2_GetAbilityArgument(iBoss, pluginName, abilityName, 2, 1);
	int iBlindAmount = FF2_GetAbilityArgument(iBoss, pluginName, abilityName, 4, 255);
	float bossPosition[3], clientPosition[3];

	GetEntPropVector(iClient, Prop_Send, "m_vecOrigin", bossPosition);
	for(int target = 1; target <= MaxClients; target++)
	{
		if(target != iClient && IsPlayerAlive(target) && !TF2_IsPlayerInCondition(target, TFCond_Ubercharged))
		{
			GetEntPropVector(target, Prop_Send, "m_vecOrigin", clientPosition);
			if(((GetVectorDistance(bossPosition, clientPosition) <= flDistance) || bBlindAll>=1))
			{
				BlindPlayer(target, iBlindAmount);
				g_bIsBlind[target] = true;
				CreateTimer(flDuration, ResetClient, target);
			}
		}
	}
}

stock void BlindPlayer(int iClient, int iAmount)
{
	int iTargets[1];
	iTargets[0] = iClient;

	Handle message = StartMessageEx(g_FadeUserMsgId, iTargets, 1);
	BfWrite bf = UserMessageToBfWrite(message);
	bf.WriteShort(1536);
	bf.WriteShort(1536);

	if(iAmount == 0)
	{
		bf.WriteShort((0x0001 | 0x0010));
	}
	else
	{
		bf.WriteShort((0x0002 | 0x0008));
	}

	bf.WriteByte(0);
	bf.WriteByte(0);
	bf.WriteByte(0);
	bf.WriteByte(iAmount);

	EndMessage();
}

public Action ResetClient(Handle hTimer, any iClient)
{
	if (IsValidClient(iClient))
	{
		if(g_bIsBlind[iClient])
		{
			BlindPlayer(iClient, 0);
			g_bIsBlind[iClient] = false;
		}
		
		SetEntityMoveType(iClient, MOVETYPE_WALK);
	}
}

public void Rage_Reflect(int iIndex, const char[] pluginName, const char[] abilityName)
{
	int iBoss = GetClientOfUserId(FF2_GetBossUserId(iIndex));
	float fDuration = FF2_GetAbilityArgumentFloat(iIndex, pluginName, abilityName, 1, 8.0);
	
	TF2_AddCondition(iBoss, TFCond_UberchargedHidden, fDuration);
	SDKHook(iBoss, SDKHook_OnTakeDamageAlive, OnTakeDamage);
	CreateTimer(fDuration, Timer_Unhook, iBoss, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_Unhook(Handle hTimer, any iClient)
{
	SDKUnhook(iClient, SDKHook_OnTakeDamageAlive, OnTakeDamage);
	return Plugin_Continue;
}

public void Rage_Electric(int iIndex, const char[] pluginName, const char[] abilityName)
{
	float fFireDelay = FF2_GetAbilityArgumentFloat(iIndex, pluginName, abilityName, 1, 1.0);
	int iMaxShots = FF2_GetAbilityArgument(iIndex, pluginName, abilityName, 3, 4);
	float fSpeed = FF2_GetAbilityArgumentFloat(iIndex, pluginName, abilityName, 4, 800.0);
	
	for(int iClient=MaxClients; iClient > 0; iClient--) if(IsValidClient(iClient))
		SDKHook(iClient, SDKHook_OnTakeDamageAlive, OnTakeDamage);
	
	DataPack hData;
	CreateDataTimer(fFireDelay, Timer_Electric, hData, TIMER_FLAG_NO_MAPCHANGE);
	hData.WriteCell(iIndex);
	hData.WriteFloat(fFireDelay);
	hData.WriteCell(0);
	hData.WriteCell(iMaxShots);
	hData.WriteFloat(fSpeed);
}

public Action Timer_Electric(Handle hTimer, DataPack hData)
{
	hData.Reset();
	
	int iBoss = hData.ReadCell();
	float fFireDelay = hData.ReadFloat();
	int iShots = hData.ReadCell();
	int iMaxShots = hData.ReadCell();
	float fSpeed = hData.ReadFloat();
	
	int iClient = GetClientOfUserId(FF2_GetBossUserId(iBoss));
	
	if(iShots < iMaxShots)
	{
		int iProj = CreateEntityByName("tf_projectile_lightningorb");
		if(IsValidEntity(iProj))
		{
			float flAng[3], flPos[3];
			GetClientEyeAngles(iClient, flAng);
			GetClientEyePosition(iClient, flPos);
			
			int iTeam = GetClientTeam(iClient);
	
			float flVel1[3], flVel2[3];
			GetAngleVectors(flAng, flVel2, NULL_VECTOR, NULL_VECTOR);
			
			flVel1[0] = flVel2[0]*fSpeed;
			flVel1[1] = flVel2[1]*fSpeed;
			flVel1[2] = flVel2[2]*fSpeed;
			
			SetEntPropEnt(iProj, Prop_Send, "m_hOwnerEntity", iClient);
			SetEntProp(iProj, Prop_Send, "m_iTeamNum", iTeam, 1);
			SetEntProp(iProj, Prop_Send, "m_nSkin", (iTeam-2));
			
			TeleportEntity(iProj, flPos, flAng, NULL_VECTOR);
			
			SetVariantInt(iTeam);
			AcceptEntityInput(iProj, "TeamNum", -1, -1, 0);
			SetVariantInt(iTeam);
			AcceptEntityInput(iProj, "SetTeam", -1, -1, 0); 
			
			DispatchSpawn(iProj);
			TeleportEntity(iProj, NULL_VECTOR, NULL_VECTOR, flVel1);
			
			iShots++;
		}
		
		DataPack hData2;
		CreateDataTimer(fFireDelay, Timer_Electric, hData2, TIMER_FLAG_NO_MAPCHANGE);
		hData2.WriteCell(iBoss);
		hData2.WriteFloat(fFireDelay);
		hData2.WriteCell(iShots);
		hData2.WriteCell(iMaxShots);
		hData2.WriteFloat(fSpeed);
	}
	
	return Plugin_Continue;
}

public Action Timer_Pull(Handle timer, DataPack hPack)
{
	hPack.Reset();
	
	if(GetEngineTime() >= hPack.ReadFloat())
		return Plugin_Stop;
	
	if(FF2_GetRoundState() != 1)
		return Plugin_Stop;
	
	float vPos[3];
	vPos[0] = hPack.ReadFloat();
	vPos[1] = hPack.ReadFloat();
	vPos[2] = hPack.ReadFloat();
	
	int iAttacker = GetClientOfUserId(hPack.ReadCell());
	
	for (int i = 1; i <= MaxClients; i++) 
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i)) 
			continue;
			
		if (iAttacker == i)
			continue;
		
		float vPos2[3];
		GetClientAbsOrigin(i, vPos2);
		
		float fDistance = GetVectorDistance(vPos, vPos2);
			
		if (fDistance <= BH_Radius[iAttacker]) 
		{
			float vVelocity[3];
			MakeVectorFromPoints(vPos, vPos2, vVelocity);
			NormalizeVector(vVelocity, vVelocity);
			ScaleVector(vVelocity, BH_Force[iAttacker]);
			TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, vVelocity);
			
			SDKHooks_TakeDamage(i, iAttacker, iAttacker, BH_Damage[iAttacker], DMG_SHOCK); //dmg_removenoragdoll dont work?
			
			if (!IsPlayerAlive(i))
			{
				int iRagdoll = GetEntPropEnt(i, Prop_Send, "m_hRagdoll");
				
				if (!IsValidEntity(iRagdoll))
					continue;
					
				AcceptEntityInput(iRagdoll, "Kill");
			}
		}
	}
	return Plugin_Continue;
}

public Action FireFireball(Handle hTimer, any iClient)
{
	if(IsValidClient(iClient, true, true))
	{
		int iProj = CreateEntityByName("tf_projectile_spellmeteorshower");
		if (IsValidEdict(iProj))
		{
			float vOrigin[3], vAngles[3], vVelocity[3];
			GetClientEyePosition(iClient, vOrigin);
			GetClientEyeAngles(iClient, vAngles);
			
			SetEntPropEnt(iProj, Prop_Send, "m_hOwnerEntity", iClient);
			SetEntPropEnt(iProj, Prop_Send, "m_hThrower", iClient);
			
			SetEntPropFloat(iProj, Prop_Data, "m_flDamage", PKF_Damage[iClient]);
			
			SetEntProp(iProj, Prop_Send, "m_nSkin", 2);
			
			vVelocity[0] = Cosine(DegToRad(vAngles[0]))*Cosine(DegToRad(vAngles[1]))*PKT_Speed[iClient];
			vVelocity[1] = Cosine(DegToRad(vAngles[0]))*Sine(DegToRad(vAngles[1]))*PKT_Speed[iClient];
			vVelocity[2] = Sine(DegToRad(vAngles[0]))*PKT_Speed[iClient];
			vVelocity[2]*=-1;
			
			TeleportEntity(iProj, vOrigin, vAngles, vVelocity);
			DispatchSpawn(iProj);
		}
	}
	return Plugin_Stop;
}

public Action Timer_RocketTurn(Handle hTiemr, any iRef)
{
	int iProj = EntRefToEntIndex(iRef);
	if(IsValidEntity(iProj) && IsValidEdict(iProj))
	{
		new iOwner = GetEntPropEnt(iProj, Prop_Send, "m_hOwnerEntity");
		new Float:RocketPos[3];
		new Float:RocketAng[3];
		new Float:RocketVec[3];
		new Float:TargetPos[3];
		new Float:TargetVec[3];
		new Float:MiddleVec[3];
		
		GetPlayerEye(iOwner, TargetPos);
		
		GetEntPropVector(iProj, Prop_Data, "m_vecAbsOrigin", RocketPos);
		GetEntPropVector(iProj, Prop_Data, "m_angRotation", RocketAng);
		GetEntPropVector(iProj, Prop_Data, "m_vecAbsVelocity", RocketVec);

		new Float:RocketSpeed = GetVectorLength(RocketVec);
		SubtractVectors(TargetPos, RocketPos, TargetVec);
		
		if (PKT_TurnSens[iOwner] <= 0) // negative values
			NormalizeVector(TargetVec, RocketVec);
		else
		{
			if (PKT_TurnSens[iOwner] == 1)
				AddVectors(RocketVec, TargetVec, RocketVec);
			else if (PKT_TurnSens[iOwner] == 2)
			{
				AddVectors(RocketVec, TargetVec, MiddleVec);
				AddVectors(RocketVec, MiddleVec, RocketVec);
			}
			else
			{
				AddVectors(RocketVec, TargetVec, MiddleVec);
				for(new j=0; j < PKT_TurnSens[iOwner]-2; j++)
					AddVectors(RocketVec, MiddleVec, MiddleVec);
				AddVectors(RocketVec, MiddleVec, RocketVec);
			}
			NormalizeVector(RocketVec, RocketVec);
		}
		
		GetVectorAngles(RocketVec, RocketAng);
		SetEntPropVector(iProj, Prop_Data, "m_angRotation", RocketAng);

		ScaleVector(RocketVec, RocketSpeed);
		SetEntPropVector(iProj, Prop_Data, "m_vecAbsVelocity", RocketVec);
	}
	else
		return Plugin_Stop;
	
	return Plugin_Continue;
}

public Action Timer_RocketLife(Handle hTimer, any iRef)
{
	int iProj = EntRefToEntIndex(iRef);
	if(IsValidEntity(iProj) && IsValidEdict(iProj))
	{
		new iOwner = GetEntPropEnt(iProj, Prop_Send, "m_hOwnerEntity");
		if(++PKT_LifeTime > PKT_Duration[iOwner])
		{
			SDKCall(g_hRocketTouch, iProj, 0);
			CreateTimer(0.1, DoExplodeRocket, EntIndexToEntRef(iProj));
			SetEntityMoveType(iOwner, MOVETYPE_WALK);
		}
	}
	else
	{
		SetEntityMoveType(g_iBoss, MOVETYPE_WALK);
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

public Action Timer_PropPopup(Handle hTimer, any iRef)
{
	int iProp = EntRefToEntIndex(iRef);
	if(IsValidEntity(iProp))
	{
		float vOrigin[3];
		GetEntPropVector(iProp, Prop_Data, "m_vecAbsOrigin", vOrigin);
		
		for(int iClient = MaxClients; iClient > 0; iClient--)
		{
			float vOrigin2[3];
			GetClientAbsOrigin(iClient, vOrigin2);
			
			if(GetVectorDistance(vOrigin, vOrigin2) < 64.0)
				SDKHooks_TakeDamage(iClient, iProp, g_iBoss, 9999.0, DMG_BLAST);
		}
		
		float vTarget[3];
		for(int x=0; x<3; x++)
			vTarget[x] = vOrigin[x];
		
		FindFloor(vTarget);
		
		if(GetVectorDistance(vOrigin, vTarget) > 8.0)	// A small amount of leeway
		{
			vOrigin[2] += 1.5;
			TeleportEntity(iProp, vOrigin, NULL_VECTOR, NULL_VECTOR);
		}
		else return Plugin_Stop;
	}
	else return Plugin_Stop;
	
	return Plugin_Continue;
}

public Action ExtinguishPlayer(Handle hTimer, any iClient)
{
	if(IsValidClient(iClient, true))
		TF2_RemoveCondition(iClient, TFCond_OnFire);
}

public Action DoExplodeRocket(Handle hTimer, any iRef)
{
	new iProj = EntRefToEntIndex(iRef);
	if(!IsValidEntity(iProj))
		return Plugin_Stop;
	
	AcceptEntityInput(iProj, "Kill");
	return Plugin_Stop;
}

public Action RemoveEnt(Handle hTimer, any entid)
{
	int iEntity = EntRefToEntIndex(entid);
	if (IsValidEdict(iEntity))
	{
		if (iEntity > MaxClients)
			AcceptEntityInput(iEntity, "Kill");
	}
}

stock bool IsValidClient(int iClient, bool bAlive = false, bool bTeam = false)
{
	if(iClient < 1 || iClient > MaxClients || !IsClientInGame(iClient))
		return false;

	if(IsClientSourceTV(iClient) || IsClientReplay(iClient))
		return false;
	
	if(bAlive && !IsPlayerAlive(iClient))
		return false;
	
	if(bTeam && GetClientTeam(iClient) != BossTeam)
		return false;

	return true;
}

stock CopyVector(Float:fFrom[3], Float:fTo[3])
{
	fTo[0] = fFrom[0];
	fTo[1] = fFrom[1];
	fTo[2] = fFrom[2];
}

stock LerpVector(Float:fA[3], Float:fB[3], Float:fC[3], Float:t)
{
	if (t < 0.0) t = 0.0;
	if (t > 1.0) t = 1.0;
	
	fC[0] = fA[0] + (fB[0] - fA[0]) * t;
	fC[1] = fA[1] + (fB[1] - fA[1]) * t;
	fC[2] = fA[2] + (fB[2] - fA[2]) * t;
}

public void FindFloor(float vPos[3])
{
	vPos[2] += 200.0;
	Handle hTrace = TR_TraceRayEx(vPos, view_as<float>({90.0, 0.0, 0.0}), MASK_SHOT, RayType_Infinite);
	
	if (TR_DidHit(hTrace))
	{
		TR_GetEndPosition(vPos, hTrace);
		delete hTrace;
	}
	else // If it didn't hit, the position is somehow underneath the floor
	{
		vPos[2] += 600.0;
		hTrace = TR_TraceRayEx(vPos, view_as<float>({90.0, 0.0, 0.0}), MASK_SHOT, RayType_Infinite);
		
		if (TR_DidHit(hTrace)) // This is pretty liberal and won't likely need another check or a fail-else
		{
			TR_GetEndPosition(vPos, hTrace);
			delete hTrace;
		}
	}
}

stock int AttachParticle(int iEntity, char[] sParticleType, float flOffset = 0.0, bool bAttach = true)
{
	int iParticle = CreateEntityByName("info_particle_system");

	char sName[128];
	float flPos[3];
	GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", flPos);
	flPos[2] += flOffset;
	TeleportEntity(iParticle, flPos, NULL_VECTOR, NULL_VECTOR);

	Format(sName, sizeof(sName), "target%i", iEntity);
	DispatchKeyValue(iEntity, "targetname", sName);

	DispatchKeyValue(iParticle, "targetname", "tf2particle");
	DispatchKeyValue(iParticle, "parentname", sName);
	DispatchKeyValue(iParticle, "effect_name", sParticleType);
	DispatchSpawn(iParticle);
	if (bAttach)
	{
		SetVariantString(sName);
		AcceptEntityInput(iParticle, "SetParent", iParticle, iParticle, 0);
		SetEntPropEnt(iParticle, Prop_Send, "m_hOwnerEntity", iEntity);
	}
	ActivateEntity(iParticle);
	AcceptEntityInput(iParticle, "Start");
	return iParticle;
}

public bool FF2_GetAbilityArgumentBool(int iBoss, const char[] pluginName, const char[] abilityName, int iArg) {
	return FF2_GetAbilityArgument(iBoss, pluginName, abilityName, iArg, 1) == 1;
}

bool:GetPlayerEye(client, Float:pos[3])
{
	new Float:vAngles[3], Float:vOrigin[3];
	GetClientEyePosition(client, vOrigin);
	GetClientEyeAngles(client, vAngles);
	
	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer, client);
	
	if(TR_DidHit(trace))
	{
		TR_GetEndPosition(pos, trace);
		CloseHandle(trace);
		return true;
	}
	CloseHandle(trace);
	return false;
}
public bool:TraceEntityFilterPlayer(entity, contentsMask, any:data)
{
	if (entity <= 0) return true;
	if (entity == data) return false;
	
	decl String:sClassname[128];
	GetEdictClassname(entity, sClassname, sizeof(sClassname));
	if(StrEqual(sClassname, "func_respawnroomvisualizer", false))
		return false;
	else
		return true;
}

enum Operators
{
	Operator_None = 0,
	Operator_Add,
	Operator_Subtract,
	Operator_Multiply,
	Operator_Divide,
	Operator_Exponent,
};

stock void Operate(Handle sumArray, int &iBracket, float flValue, Handle _operator)
{
	float flSum = GetArrayCell(sumArray, iBracket);
	switch(GetArrayCell(_operator, iBracket))
	{
		case Operator_Add:
		{
			SetArrayCell(sumArray, iBracket, flSum+flValue);
		}
		case Operator_Subtract:
		{
			SetArrayCell(sumArray, iBracket, flSum-flValue);
		}
		case Operator_Multiply:
		{
			SetArrayCell(sumArray, iBracket, flSum*flValue);
		}
		case Operator_Divide:
		{
			if(!flValue)
			{
				LogError("[ff2_noobis] Detected a divide by 0!");
				iBracket=0;
				return;
			}
			SetArrayCell(sumArray, iBracket, flSum/flValue);
		}
		case Operator_Exponent:
		{
			SetArrayCell(sumArray, iBracket, Pow(flSum, flValue));
		}
		default:
		{
			SetArrayCell(sumArray, iBracket, flValue);	 //This means we're dealing with a constant
		}
	}
	SetArrayCell(_operator, iBracket, Operator_None);
}

stock void OperateString(Handle sumArray, int &iBracket, char[] sValue, int iSize, Handle _operator)
{
	if(!StrEqual(sValue, ""))  //Make sure 'value' isn't blank
	{
		Operate(sumArray, iBracket, StringToFloat(sValue), _operator);
		strcopy(sValue, iSize, "");
	}
}

public int ParseFormula(int iBoss, const char[] sKey, int iDefaultValue, int iPlaying)
{
	char sFormula[1024], bossName[64];
	FF2_GetBossSpecial(iBoss, bossName, sizeof(bossName));
	strcopy(sFormula, sizeof(sFormula), sKey);
	int iSize = 1;
	int matchingBrackets;
	for(int i; i <= strlen(sFormula); i++)	 //Resize the arrays once so we don't have to worry about it later on
	{
		if(sFormula[i]=='(')
		{
			if(!matchingBrackets)
			{
				iSize++;
			}
			else
			{
				matchingBrackets--;
			}
		}
		else if(sFormula[i]==')')
		{
			matchingBrackets++;
		}
	}

	Handle sumArray = CreateArray(_, iSize), _operator = CreateArray(_, iSize);
	int iBracket;  //Each bracket denotes a separate sum (within parentheses).  At the end, they're all added together to achieve the actual sum
	SetArrayCell(sumArray, 0, 0.0);	 //TODO:  See if these can be placed naturally in the loop
	SetArrayCell(_operator, iBracket, Operator_None);

	char sCharacter[2], sValue[16];	//We don't decl value because we directly append characters to it and there's no point in decl'ing character
	for(int i; i <= strlen(sFormula); i++)
	{
		sCharacter[0] = sFormula[i];  //Find out what the next char in the formula is
		switch(sCharacter[0])
		{
			case ' ', '\t':	 //Ignore whitespace
			{
				continue;
			}
			case '(':
			{
				iBracket++;	//We've just entered a new parentheses so increment the bracket value
				SetArrayCell(sumArray, iBracket, 0.0);
				SetArrayCell(_operator, iBracket, Operator_None);
			}
			case ')':
			{
				OperateString(sumArray, iBracket, sValue, sizeof(sValue), _operator);
				if(GetArrayCell(_operator, iBracket) != Operator_None)	 //Something like (5*)
				{
					LogError("[cd_abilities] %s's %s formula has an invalid operator at character %i", bossName, sKey, i+1);
					CloseHandle(sumArray);
					CloseHandle(_operator);
					return iDefaultValue;
				}

				if(--iBracket < 0)	 //Something like (5))
				{
					LogError("[cd_abilities] %s's %s formula has an unbalanced parentheses at character %i", bossName, sKey, i+1);
					CloseHandle(sumArray);
					CloseHandle(_operator);
					return iDefaultValue;
				}

				Operate(sumArray, iBracket, GetArrayCell(sumArray, iBracket+1), _operator);
			}
			case '\0':	//End of formula
			{
				OperateString(sumArray, iBracket, sValue, sizeof(sValue), _operator);
			}
			case '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '.':
			{
				StrCat(sValue, sizeof(sValue), sCharacter);  //Constant?  Just add it to the current value
			}
			case 'n', 'x':	//n and x denote player variables
			{
				Operate(sumArray, iBracket, float(iPlaying), _operator);
			}
			case '+', '-', '*', '/', '^':
			{
				OperateString(sumArray, iBracket, sValue, sizeof(sValue), _operator);
				switch(sCharacter[0])
				{
					case '+':
					{
						SetArrayCell(_operator, iBracket, Operator_Add);
					}
					case '-':
					{
						SetArrayCell(_operator, iBracket, Operator_Subtract);
					}
					case '*':
					{
						SetArrayCell(_operator, iBracket, Operator_Multiply);
					}
					case '/':
					{
						SetArrayCell(_operator, iBracket, Operator_Divide);
					}
					case '^':
					{
						SetArrayCell(_operator, iBracket, Operator_Exponent);
					}
				}
			}
		}
	}

	new iResult = RoundFloat(GetArrayCell(sumArray, 0));
	CloseHandle(sumArray);
	CloseHandle(_operator);
	if(iResult <= 0)
	{
		LogError("[cd_abilities] %s has an invalid %s formula for minions, using default health!", bossName, sKey);
		return iDefaultValue;
	}
	LogError("[cd_abilities] %s has an health of %f using formula for minions", bossName, iResult);
	return iResult;
}

bool:CanSeeTarget(Float:startpos[3], Float:targetpos[3], target, bossteam)		// Tests to see if vec1 > vec2 can "see" target
{
    TR_TraceRayFilter(startpos, targetpos, MASK_SOLID, RayType_EndPoint, TraceRayFilterClients, target);

    if(TR_GetEntityIndex() == target)
    {
        if(TF2_GetPlayerClass(target) == TFClass_Spy)							// if they are a spy, do extra tests (coolrocket stuff?)
        {
            if(TF2_IsPlayerInCondition(target, TFCond_Cloaked))				// if they are cloaked
            {
                if(TF2_IsPlayerInCondition(target, TFCond_CloakFlicker)		// check if they are partially visible
                        || TF2_IsPlayerInCondition(target, TFCond_OnFire)
                        || TF2_IsPlayerInCondition(target, TFCond_Jarated)
                        || TF2_IsPlayerInCondition(target, TFCond_Milked)
                        || TF2_IsPlayerInCondition(target, TFCond_Bleeding))
                {
                    return true;
                }
                
                return false;
            }
            if(TF2_IsPlayerInCondition(target, TFCond_Disguised) && GetEntProp(target, Prop_Send, "m_nDisguiseTeam") == bossteam)
            {
                return false;
            }

            return true;
        }

        return true;
    }

    return false;
}

public bool:TraceRayFilterClients(entity, mask, any:data)
{
    if(entity > 0 && entity <=MaxClients)					// only hit the client we're aiming at
    {
        if(entity == data)
        {
            return true;
        }
        else
        {
            return false;
        }
    }

    return true;
}
