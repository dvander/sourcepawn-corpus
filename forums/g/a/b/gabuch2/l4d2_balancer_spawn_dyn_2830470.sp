#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

#define DEBUG									false

#define PLUGIN_NAME			    				"[L4D2] Infected Dynamic Balancer"
#define PLUGIN_AUTHOR		    				"gabuch2"
#define PLUGIN_DESCRIPTION	    				"Originally based on xZk's plugin, this plugin manages all the infected balance in 1 simple plugin"
#define PLUGIN_VERSION		    				"1.0.1"
#define PLUGIN_URL			    				"https://github.com/szGabu/L4D2_DynamicInfectedSpawnBalancer"

#define PLAYERS_BASE_COUNT						4

#define MODE_CHECK_IGNORE_BOTS					1
#define MODE_CHECK_IGNORE_DEAD					2
#define MODE_CHECK_DEAD_COUNT_AS_HALF			4
#define MODE_CHECK_IGNORE_CAMPAIGN_NPCS			8

char g_sDominatorLimit[4][]=
{
	"SmokerLimit",
	"HunterLimit",
	"JockeyLimit",
	"ChargerLimit"
};

ConVar g_cvarPluginEnable;
ConVar g_cvarCheckMode;
ConVar g_cvarCacheInterval;
ConVar g_cvarShouldBalanceTanks;
ConVar g_cvarIncreaseHealth;
ConVar g_cvarSpecialInfectedGeneralPower;
ConVar g_cvarSpecialInfectedDominatorPower;
ConVar g_cvarCommonInfectedPower;
ConVar g_cvarSpawnIntervalPower;
ConVar g_cvarDifficulty;
ConVar g_cvarGameMode;
ConVar g_cvarCommonLimit;
ConVar g_cvarVersusLike;

bool g_bPluginEnable = false;
bool g_bShouldBalanceTanks = false;
bool g_bBalancingTanks = false;
bool g_bIsInEscapeSequence = false;
bool g_bVersusLike = false;
bool g_bIsVersus = false;
int g_iCheckMode;
int g_iIncreaseHealthPercent;
int g_iCurrentSurvivorCount;
int g_iExtraSurvivorCount;
float g_fCacheInterval;
float g_fBaseTankHealth;
float g_fSpecialInfectedGeneralPower;
float g_fSpecialInfectedDominatorPower;
float g_fCommonInfectedPower;
float g_fSpawnIntervalPower;

Handle g_hCacheTimer = INVALID_HANDLE;
Handle g_hBalancingTanksTimer = INVALID_HANDLE;

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if( GetEngineVersion() != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}
	
	return APLRes_Success;
}

public void OnPluginStart()
{
	#if DEBUG
	PrintToServer("[DEBUG] l4d2_balancer_spawn_dyn::OnPluginStart() - Called");
	#endif
	CreateConVar("sm_infected_balancer_version", PLUGIN_VERSION, "Version of Survivor Infected Balancer Plus", FCVAR_DONTRECORD);

	//base cvars
	g_cvarPluginEnable = CreateConVar("sm_infected_balancer_enabled", "1", "Enables the plugin", FCVAR_NOTIFY, true, 0.0, true, 1.0 );
	g_cvarCheckMode = CreateConVar("sm_infected_balancer_check_mode", "4", "0: Check all survivors, 1: Do not check bots, 2: Not check dead survivors, 4: Dead survivors count as half (No effect if 2 is set), 8: Ignore campaign NPCs (like the ones in the Coldfront custom campaign, no effect is 1 is set) - This is an additive bitwise field", FCVAR_NOTIFY, true, 0.0, true, 15.0);	
	g_cvarCacheInterval = CreateConVar("sm_infected_balancer_cache_interval", "5.0", "float: Determines the interval in where the survivors are counted. Caching is done to prevent an expensive operation in each director vscript variable call. 0.1 is the minimum value which is virtually instantaneous but may cause overhead.", FCVAR_NOTIFY, true, 0.1);	

	//balance adjustement
	g_cvarShouldBalanceTanks = CreateConVar("sm_infected_balancer_tank_balance", "1", "Determines if the plugin should attempt to balance tanks.", FCVAR_NOTIFY, true, 0.0, true, 1.0);	
	g_cvarIncreaseHealth = CreateConVar("sm_infected_balancer_tank_increase_hp_percent", "2", "Increases each tank's HP by specified percent (%) per alive survivor. Maximum value is 50 but it's not recommended to put anything higher than 5, as it could create extremely damage sponge Tanks. 0 to disable.", FCVAR_NOTIFY, true, 0.0, true, 50.0);	
	g_cvarSpecialInfectedGeneralPower = CreateConVar("sm_infected_balancer_si_general_power", "0.456", "Determines how much the limit of the general special infected amount will increase according with each survivor alive. Default value is the recommended one but you can experiment. 0 to disable.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarSpecialInfectedDominatorPower = CreateConVar("sm_infected_balancer_si_dominator_power", "0.333", "Determines how much each category of dominator infected will increase according with each survivor alive. Default value is the recommended one but you can experiment. 0 to disable.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarCommonInfectedPower = CreateConVar("sm_infected_balancer_commons_power", "0.222", "Determines how much the limit of each common infected will increase according with each survivor alive. Default value is the recommended one but you can experiment. 0 to disable.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarSpawnIntervalPower = CreateConVar("sm_infected_balancer_spawn_interval_power", "0.018", "Determines how much the spawn interval of special infected will decrease according with each survivor alive, the minimum possible interval is 20 (Which is the Versus interval) no matter how much you increase this setting. Default value is the recommended one but you can experiment. 0 to disable.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarVersusLike = CreateConVar("sm_infected_balancer_versus_like", "0", "Increases special infected by one AFTER CALCULATIONS. For example, most of the time in campaigns you will be dealing with 3 SI at the same time, this would effectively increase it to 4. No effect on Versus.", FCVAR_NOTIFY, true, 0.0, true, 1.0);

	//game cvars
	g_cvarDifficulty = FindConVar("z_difficulty");
    g_cvarGameMode = FindConVar("mp_gamemode");
	g_cvarCommonLimit = FindConVar("z_common_limit"); //don't hook this, as it changes dynamically with the director

	AutoExecConfig(true, "l4d2_balancer_spawn_dyn");

	g_cvarPluginEnable.AddChangeHook(CvarsChanged);
	g_cvarCheckMode.AddChangeHook(CvarsChanged);
	g_cvarShouldBalanceTanks.AddChangeHook(CvarsChanged);
	g_cvarIncreaseHealth.AddChangeHook(CvarsChanged);
	g_cvarDifficulty.AddChangeHook(CvarsChanged);
	g_cvarGameMode.AddChangeHook(CvarsChanged);
	g_cvarSpecialInfectedGeneralPower.AddChangeHook(CvarsChanged);
	g_cvarSpecialInfectedDominatorPower.AddChangeHook(CvarsChanged);
	g_cvarCommonInfectedPower.AddChangeHook(CvarsChanged);
	g_cvarSpawnIntervalPower.AddChangeHook(CvarsChanged);
	g_cvarCacheInterval.AddChangeHook(CvarsChanged);

	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
	HookEvent("tank_spawn", Event_TankSpawn, EventHookMode_Post);
	HookEvent("tank_killed", Event_TankKilled, EventHookMode_Post);
	HookEvent("finale_escape_start", Event_FinaleEscapeStart, EventHookMode_Post);
}

public void OnMapStart()
{
	#if DEBUG
	PrintToServer("[DEBUG] l4d2_balancer_spawn_dyn::OnMapStart() - Called");
	#endif
	g_bIsVersus = L4D_IsVersusMode();
}

public void OnConfigsExecuted()
{	
	#if DEBUG
	PrintToServer("[DEBUG] l4d2_balancer_spawn_dyn::OnConfigsExecuted() - Called");
	#endif
	GetCvarsValues();
}

public void CvarsChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	#if DEBUG
	PrintToServer("[DEBUG] l4d2_balancer_spawn_dyn::CvarsChanged() - Called");
	#endif
	GetCvarsValues();
}

void GetCvarsValues()
{
	#if DEBUG
	PrintToServer("[DEBUG] l4d2_balancer_spawn_dyn::GetCvarsValues() - Called");
	#endif

	g_bPluginEnable = g_cvarPluginEnable.BoolValue;
	g_bShouldBalanceTanks = g_cvarShouldBalanceTanks.BoolValue;
	g_iCheckMode = g_cvarCheckMode.IntValue;
    g_iIncreaseHealthPercent = g_cvarIncreaseHealth.IntValue;
	g_fBaseTankHealth = GetBaseTankHealth();
	g_fSpecialInfectedGeneralPower = g_cvarSpecialInfectedGeneralPower.FloatValue;
	g_fSpecialInfectedDominatorPower = g_cvarSpecialInfectedDominatorPower.FloatValue;
	g_fCommonInfectedPower = g_cvarCommonInfectedPower.FloatValue;
	g_fSpawnIntervalPower = g_cvarSpawnIntervalPower.FloatValue;
	g_fCacheInterval = g_cvarCacheInterval.FloatValue;
	g_bVersusLike = g_cvarVersusLike.BoolValue;

	#if DEBUG
	PrintToServer("[DEBUG] l4d2_balancer_spawn_dyn::GetCvarsValues() - Value of g_bPluginEnable is %b", g_bPluginEnable);
	PrintToServer("[DEBUG] l4d2_balancer_spawn_dyn::GetCvarsValues() - Value of g_iCheckMode is %d", g_iCheckMode);
	PrintToServer("[DEBUG] l4d2_balancer_spawn_dyn::GetCvarsValues() - Value of g_iIncreaseHealthPercent is %d", g_iIncreaseHealthPercent);
	PrintToServer("[DEBUG] l4d2_balancer_spawn_dyn::GetCvarsValues() - Value of g_fBaseTankHealth is %f", g_fBaseTankHealth);
	PrintToServer("[DEBUG] l4d2_balancer_spawn_dyn::GetCvarsValues() - Value of g_fSpecialInfectedGeneralPower is %f", g_fSpecialInfectedGeneralPower);
	PrintToServer("[DEBUG] l4d2_balancer_spawn_dyn::GetCvarsValues() - Value of g_fSpecialInfectedDominatorPower is %f", g_fSpecialInfectedDominatorPower);
	PrintToServer("[DEBUG] l4d2_balancer_spawn_dyn::GetCvarsValues() - Value of g_fCommonInfectedPower is %f", g_fCommonInfectedPower);
	PrintToServer("[DEBUG] l4d2_balancer_spawn_dyn::GetCvarsValues() - Value of g_fSpawnIntervalPower is %f", g_fSpawnIntervalPower);
	PrintToServer("[DEBUG] l4d2_balancer_spawn_dyn::GetCvarsValues() - Value of g_fCacheInterval is %f", g_fCacheInterval);
	#endif

	if(g_bPluginEnable)
	{
		if(g_hCacheTimer == INVALID_HANDLE)
			g_hCacheTimer = CreateTimer(g_fCacheInterval, Timer_OptimizeVarsLoop, _, TIMER_REPEAT);
		#if DEBUG
		else
			PrintToServer("[DEBUG] l4d2_balancer_spawn_dyn::GetCvarsValues() - Unable to create timer because there was a timer active with the handle: %d", g_hCacheTimer);
		#endif
	}
	else 
	{
		if(g_hCacheTimer != INVALID_HANDLE)
			KillTimer(g_hCacheTimer);
		#if DEBUG
		else
			PrintToServer("[DEBUG] l4d2_balancer_spawn_dyn::GetCvarsValues() - Won't destroy timer because it was never initialized.");
		#endif
	}
}

public Action Timer_OptimizeVarsLoop(Handle timer)
{
	#if DEBUG
	PrintToServer("[DEBUG] Timer_OptimizeVarsLoop() - Called");
	#endif	

	g_iCurrentSurvivorCount	= GetSurvivorsCount();
	g_iExtraSurvivorCount = GetExtraPlayerCount();

	#if DEBUG
	PrintToServer("[DEBUG] Timer_OptimizeVarsLoop() - g_iCurrentSurvivorCount is %d", g_iCurrentSurvivorCount);
	PrintToServer("[DEBUG] Timer_OptimizeVarsLoop() - g_iExtraSurvivorCount is %d", g_iExtraSurvivorCount);
	#endif	

	return Plugin_Continue;
}


void TankInitialized(int iUserId)
{
	#if DEBUG
	PrintToServer("[DEBUG] l4d2_balancer_spawn_dyn::TankInitialized() - Called");
	PrintToServer("[DEBUG] l4d2_balancer_spawn_dyn::TankInitialized() - Value of g_bBalancingTanks is %b", g_bBalancingTanks);
	#endif

	//g_bShouldBalanceTanks is checked in the previous function, so it should be safe to not do the same check here

	if(iUserId)
	{
		if(!g_bBalancingTanks && GetDesiredTankAmount() > L4D2_GetTankCount()) 
		{
			g_bBalancingTanks = true;
			#if DEBUG
			PrintToServer("[DEBUG] l4d2_balancer_spawn_dyn::TankInitialized() - g_bBalancingTanks is false, requesting frame.");
			#endif
			RequestFrame(BalanceTanks, iUserId);
			//CreateTimer(3.0, BalanceTanks, iClient); //balance tanks after 3 seconds
		}
	}
}

void BalanceTanks(int iUserId)
{
    #if DEBUG
    PrintToServer("[DEBUG] l4d2_balancer_spawn_dyn::BalanceTanks() - Called");
    #endif

	//ditto TankInitialized 

	int iClient = GetClientOfUserId(iUserId);

	if(iClient)
	{
		if(GetDesiredTankAmount() > 1)
		{
			#if DEBUG
			PrintToServer("[DEBUG] l4d2_balancer_spawn_dyn::BalanceTanks() - Tank amount should be %d, creating extra tanks", GetDesiredTankAmount());
			#endif

			int iIgnoreAmount = 1;  // we ignore the tank who is currently spawned by the director

			if(g_bIsInEscapeSequence)  
				iIgnoreAmount++;		// we increase the threshold by 1, as spawning more tanks in the escape sequence is overkill

			//hook OnTakeDamage to see if they are engaging the tanks right now!
			SDKHook(iClient, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
			
			for(int x = 0; x < GetDesiredTankAmount()-iIgnoreAmount; x++) 
			{
				float fPos[3];
				
				// we try only once to get the position of the new tank
				// testing showed that trying multiple times increased the chances of tanks spawning in an invalid place
				// new plugin logic should still increase the tank's health should both cases happen
				if(!L4D_GetRandomPZSpawnPosition(0, view_as<int>(L4D2ZombieClass_Tank), 1, fPos))
					GetEntPropVector(iClient, Prop_Send, "m_vecOrigin", fPos);

				#if DEBUG
				PrintToServer("[DEBUG] l4d2_balancer_spawn_dyn::BalanceTanks() - Spawning tank on %f %f %f", fPos[0], fPos[1], fPos[2]);
				#endif
				int iTank = L4D2_SpawnTank(fPos, {0.0, 0.0, 0.0});


				SDKHook(iTank, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive); //ditto
			}   

			g_hBalancingTanksTimer = CreateTimer(10.0, BalanceTanksPost); //balance tanks after a while
		}
	}
}

public Action OnTakeDamageAlive(int iVictim, int &iAttacker, int &iInflictor, float &fDamage, int &iDamageType, int &iWeapon, float fDamageForce[3], float fDamagePosition[3], int iDamageCustom)
{
    if(g_hBalancingTanksTimer == INVALID_HANDLE || iVictim == 0 || iVictim > MaxClients || !IsClientInGame(iVictim) || GetClientTeam(iVictim) != L4D_TEAM_INFECTED || iAttacker == 0 || iAttacker > MaxClients || !IsClientInGame(iAttacker) || GetClientTeam(iAttacker) != L4D_TEAM_SURVIVOR || L4D2_GetPlayerZombieClass(iVictim) != L4D2ZombieClass_Tank)
        return Plugin_Continue;
	else
	{
		//tank got attacked by a player, remove task and balance now if we are waiting
		#if DEBUG
		PrintToServer("[DEBUG] l4d2_balancer_spawn_dyn::OnTakeDamageAlive() - Tank got hit and we got a timer running (%d), removing it and triggering it right now.", g_hBalancingTanksTimer);
		#endif
		KillTimer(g_hBalancingTanksTimer);
		BalanceTanksPost(INVALID_HANDLE); //we don't need it anyway
		return Plugin_Continue;
	}
} 

public Action BalanceTanksPost(Handle timer)
{
    #if DEBUG
    PrintToServer("[DEBUG] l4d2_balancer_spawn_dyn::BalanceTanksPost() - Called");
    #endif
    //how much health Tanks should have?
	float fHealthPool = GetTankHealthPool();
    float fHealthPerTank = fHealthPool/L4D2_GetTankCount();
    int iDesiredHealth = RoundToCeil(fHealthPerTank);
    int iAdditiveHealth = RoundToCeil((fHealthPerTank*(g_iIncreaseHealthPercent/100.0))*g_iCurrentSurvivorCount);
    #if DEBUG
	PrintToServer("[DEBUG] l4d2_balancer_spawn_dyn::BalanceTanksPost() - There are %d tanks", L4D2_GetTankCount());
	PrintToServer("[DEBUG] l4d2_balancer_spawn_dyn::BalanceTanksPost() - fHealthPool is %f", fHealthPool);
	PrintToServer("[DEBUG] l4d2_balancer_spawn_dyn::BalanceTanksPost() - fHealthPerTank is %f", fHealthPerTank);
	PrintToServer("[DEBUG] l4d2_balancer_spawn_dyn::BalanceTanksPost() - iDesiredHealth is %d", iDesiredHealth);
    PrintToServer("[DEBUG] l4d2_balancer_spawn_dyn::BalanceTanksPost() - iAdditiveHealth is %d", iAdditiveHealth);
	#endif
	for(int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if(IsClientInGame(iClient) && GetClientTeam(iClient) == L4D_TEAM_INFECTED && 
			IsPlayerAlive(iClient) && L4D2_GetPlayerZombieClass(iClient) == L4D2ZombieClass_Tank)
		{
			#if DEBUG
			PrintToServer("[DEBUG] l4d2_balancer_spawn_dyn::BalanceTanksPost() - Setting %N health to %d", iClient, iDesiredHealth+iAdditiveHealth);
			#endif

			SetEntProp(iClient, Prop_Send, "m_iMaxHealth", iDesiredHealth+iAdditiveHealth);
			SetEntProp(iClient, Prop_Send, "m_iHealth", iDesiredHealth+iAdditiveHealth);
		}
	}

	g_hBalancingTanksTimer = INVALID_HANDLE;
    return Plugin_Continue;
}


public Action L4D_OnGetScriptValueInt(const char[] sKey, int &iRetVal)
{
	if(g_bPluginEnable && g_iExtraSurvivorCount > 0)
	{
		if (strcmp(sKey, "MaxSpecials", false) == 0)
		{
			iRetVal += RoundToCeil(g_iExtraSurvivorCount * (iRetVal*g_fSpecialInfectedGeneralPower));

			if(iRetVal != 0 && !g_bIsVersus && g_bVersusLike)
				iRetVal++;
			
			return Plugin_Handled;
		}
		else if (strcmp(sKey, "DominatorLimit", false) == 0 && iRetVal != -1 && g_iExtraSurvivorCount >= 1)
		{
			// From Valve's Developer Wiki:
			// Maximum number of dominator SI types (Hunter, Smoker, Jockey or Charger) that can freely fill up their caps. 
			// The extra SI type (3rd by default) will be capped at 1 regardless of its individual limit or cm_BaseSpecialLimit. 
			// Therefore, if cm_BaseSpecialLimit = 2, MaxSpecials = 8 and DominatorLimit is unset, the maximum amount of 
			// dominators will be 2+2+1+0. The remaining 3 slots could only be filled with Boomers and Spitters. 
			// Its maximum effective value is 4 since there are only 4 dominator types. To block all dominators, set it to -1. 

			if(iRetVal > 0)
			{
				switch(g_iExtraSurvivorCount)
				{
					case 1:
					{
						if(iRetVal == 2)
							iRetVal += 1;
					}
					case 2:
					{
						if(iRetVal == 1)
							iRetVal += 1;
						else
							iRetVal += 2;
					}
					default:
					{
						iRetVal = 4;
					}
				}

				return Plugin_Handled;
			}
			else
				return Plugin_Continue;
		}
		else if (iRetVal != 0 && (strcmp(sKey, "Boomer", false) == 0 || strcmp(sKey, "Spitter", false) == 0))
		{
			iRetVal = g_iCurrentSurvivorCount;
			return Plugin_Handled;
		}
		else 
		{
			for(int i; i < sizeof(g_sDominatorLimit); i++)
			{
				if((strcmp(sKey, g_sDominatorLimit[i], false) == 0))
				{
					iRetVal += RoundToNearest(g_iExtraSurvivorCount * (iRetVal*g_fSpecialInfectedDominatorPower));
					return Plugin_Handled;
				}
			}
		}
	}
	
	return Plugin_Continue;
}

public Action L4D_OnGetScriptValueFloat(const char[] sKey, float &fRetVal)
{
	if(g_bPluginEnable)
	{
		if(strcmp(sKey, "SpecialRespawnInterval", false) == 0)
		{
			if(fRetVal <= 20.0)
				return Plugin_Continue;

			fRetVal -= g_iExtraSurvivorCount * (fRetVal*g_fSpawnIntervalPower);

			if(fRetVal < 20.0)
				fRetVal = 20.0;

			return Plugin_Handled;
		} else if (strcmp(sKey, "CommonLimit", false) == 0 || 
				strcmp(sKey, "MegaMobSize", false) == 0 || 
				strcmp(sKey, "MobMaxSize", false) == 0 || 
				strcmp(sKey, "MobMinSize", false) == 0 || 
				strcmp(sKey, "PreTankMobMax", false) == 0)
		{
			fRetVal += RoundToCeil(g_iExtraSurvivorCount * (fRetVal*g_fCommonInfectedPower));
			g_cvarCommonLimit.SetInt(RoundToCeil(fRetVal));

			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

public Action Event_TankSpawn(Event event, const char[] sEventName, bool db)
{
	#if DEBUG
	PrintToServer("[DEBUG] l4d2_balancer_spawn_dyn::Event_TankSpawn() - Called");
	#endif
	if(g_bPluginEnable && g_bShouldBalanceTanks)
	{
		RequestFrame(TankInitialized, GetEventInt(event, "userid"));
	}
	return Plugin_Continue;
}

public Action Event_FinaleEscapeStart(Event event, const char[] sEventName, bool db)
{
	if(g_bPluginEnable)
    	g_bIsInEscapeSequence = true;
    return Plugin_Continue;
}

public Action Event_RoundStart(Event event, const char[] sEventName, bool db)
{
	GetCvarsValues();
    g_bIsInEscapeSequence = false;

    return Plugin_Continue;
}

public Action Event_TankKilled(Event event, const char[] sEventName, bool db)
{
    #if DEBUG
	PrintToServer("[DEBUG] l4d2_balancer_spawn_dyn::Event_TankKilled() - Called");
	#endif
	if(g_bPluginEnable)
	{
		if(g_bBalancingTanks)
			g_bBalancingTanks = false; //a previously balancing process finished
	}

    return Plugin_Continue;
}

stock int GetExtraPlayerCount()
{
    int iReturnValue = GetSurvivorsCount() - PLAYERS_BASE_COUNT;
	
    if(iReturnValue < 0)
        iReturnValue = 0;

    return iReturnValue;
}

stock int GetSurvivorsCount()
{
	int iReturnValueAlive = 0;
	int iReturnValueDead = 0;

	for(int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if(!IsValidSurvivor(iClient))
			continue;

		if((g_iCheckMode & MODE_CHECK_IGNORE_BOTS) && IsFakeClient(iClient))
			continue;

		if((g_iCheckMode & MODE_CHECK_IGNORE_CAMPAIGN_NPCS) && IsBotCampaignNpc(iClient))
			continue;

		if (IsPlayerAlive(iClient))
			iReturnValueAlive++;
		else if (!(g_iCheckMode & MODE_CHECK_IGNORE_DEAD)) // Ensure proper flag check
			iReturnValueDead++;
	}

	return iReturnValueAlive+(g_iCheckMode & MODE_CHECK_DEAD_COUNT_AS_HALF ? iReturnValueDead/2 : iReturnValueDead);
}

stock int IsValidSurvivor(int iClient)
{
	return (IsValidClient(iClient) && GetClientTeam(iClient) == L4D_TEAM_SURVIVOR);
}

stock bool IsValidClient(int iClient)
{
	return (iClient > 0 && iClient <= MaxClients && IsClientInGame(iClient));
}

stock float GetTankHealthPool() 
{
	#if DEBUG
	PrintToServer("[DEBUG] l4d2_balancer_spawn_dyn::GetTankHealthPool() - Called");
	#endif
    float fHealth = g_fBaseTankHealth;
	float fHealthQuarter = fHealth / PLAYERS_BASE_COUNT;

	#if DEBUG
	PrintToServer("[DEBUG] l4d2_balancer_spawn_dyn::GetTankHealthPool() - g_fBaseTankHealth is %f", g_fBaseTankHealth);
	PrintToServer("[DEBUG] l4d2_balancer_spawn_dyn::GetTankHealthPool() - fHealthQuarter is %f", fHealthQuarter);
	PrintToServer("[DEBUG] l4d2_balancer_spawn_dyn::GetTankHealthPool() - Returning %f (g_fBaseTankHealth+(fHealthQuarter*g_iExtraSurvivorCount))", g_fBaseTankHealth+(fHealthQuarter*g_iExtraSurvivorCount));
	#endif

    return g_fBaseTankHealth+(fHealthQuarter*g_iExtraSurvivorCount);
}

stock float GetBaseTankHealth()
{
    static char szGameMode[64];
	g_cvarGameMode.GetString(szGameMode, sizeof(szGameMode));

    float fHealth = 0.0;

    if(strncmp(szGameMode, "Versus", sizeof(szGameMode), false) == 0)
    {
        fHealth = 6000.0;
    }
    else if(strncmp(szGameMode, "Survival", sizeof(szGameMode), false) == 0)
    {
        fHealth = 4000.0;
    }
    else
    {
        static char szBuffer[64];
	    g_cvarDifficulty.GetString( szBuffer, sizeof(szBuffer));
        if(strncmp(szBuffer, "Easy", sizeof(szBuffer), false) == 0) 
            fHealth = 3000.0;
        else if(strncmp(szBuffer,"Hard", sizeof(szBuffer), false) == 0 || strncmp(szBuffer,"Impossible", sizeof(szBuffer), false) == 0) 
            fHealth = 8000.0;
        else //normal
            fHealth = 4000.0;
    }

    return fHealth;
}

stock int GetDesiredTankAmount()
{
    return RoundToCeil(GetTankHealthPool()/g_fBaseTankHealth);
}

stock bool IsBotCampaignNpc(int iClient)
{
	if(IsClientInGame(iClient) && GetClientTeam(iClient) == L4D_TEAM_SURVIVOR && IsPlayerAlive(iClient))
	{
		char sTargetname[MAX_NAME_LENGTH];
		GetEntPropString(iClient, Prop_Data, "m_iName", sTargetname, sizeof(sTargetname));
		return StrContains(sTargetname, "npc_", false) == 0;
	}
	else
		return false;
}