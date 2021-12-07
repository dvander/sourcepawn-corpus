#pragma semicolon 1
#include <sourcemod>
#include <left4downtown>
#define PLUGIN_VERSION "1.3.1"

public Plugin myinfo={
	name="L4D2 Automatic Scaling Difficulty Controller(ASDC)",
	author="Fwoosh/harryhecanada/hjhee",
	description="Difficulty Controller for the L4D2 AI director, automatically spawns extra zombies to increase difficulty.",
	version=PLUGIN_VERSION,
	url="https://forums.alliedmods.net/showthread.php?p=2007433"
}

//Default limits for maximum tanks and witches, with seperate counters for each
#define MAX_WITCHES 2
#define MAX_TANKS 1

//Counting Variables
int g_WitchCount=0;
int g_TankCount=0;

//Handles for type selection
Handle cv_ASDCtypeMOB=null;
Handle cv_ASDCtypetank=null;
Handle cv_ASDCtypewitch=null;

//Tick per Time base and multiplier
Handle cv_ASDCbase=null;
Handle cv_ASDCmult=null;
Handle cv_ASDCCImult=null;
Handle cv_ASDCFINmult=null;
Handle cv_ASDCCLmult=null;

//Common infected amount handlers
Handle cv_ASDCcommons=null;
Handle cv_ASDCcommonsbackground=null;
Handle cv_ASDCmob=null;

//Intervals
Handle cv_ASDCMOBinterval=null;
Handle cv_ASDCTankinterval=null;
Handle cv_ASDCWitchinterval=null;

//base Tick timer
Handle mTimer=null;

//Ticks for each type of spawn
float g_MOBtick=0.0;
float g_Tanktick=0.0;
float g_Witchtick=0.0;

// convar value storage
int g_ReservedCommon;
int g_FlowTravel;
bool g_FlagUpdateReservedCommon;

// convars
Handle cv_DirectorRelaxMaxFlowTravel=null;
Handle cv_ReservedCommon=null;
Handle cv_PainPillsDecayRate=null;
Handle cv_CommonLimit=null;
Handle cv_BackgroundLimit=null;
Handle cv_WanderingDensity=null;
Handle cv_MobPopulationDensity=null;
Handle cv_MegaMobSize=null;
Handle cv_MobSpawnMaxSize=null;
Handle cv_MobSpawnFinaleSize=null;

// flags
bool g_TypeMob;
bool g_TypeTank;
bool g_TypeWitch;
int g_FinaleEnable=0;
int g_FinaleFlag=0;

// tick intervals
float g_IntervalMob;
float g_IntervalTank;
float g_IntervalWitch;

// asdc variables
float g_ASDCBase;
float g_ASDCMult;
float g_ASDCCIMult;
float g_ASDCFINMult;
float g_ASDCCommons;
float g_ASDCCommonsBackground;
float g_ASDCMob;
float g_ASDCCLMult;
int g_Alive=4;

// mob size
int g_MegaMobSize;
int g_MobSpawnMaxSize;
int g_MobSpawnFinaleSize;

public void OnPluginStart(){
	CreateConVar("ASDCversion", PLUGIN_VERSION, "L4D2 Monster Bots Version", FCVAR_NOTIFY|FCVAR_DONTRECORD);

	//Type Enables
	cv_ASDCtypeMOB=CreateConVar("ASDCtypeMOB", "1", "Is Mobs of Common Infected wave spawn on (1/0). Set to 0 to disable.", FCVAR_NOTIFY|FCVAR_DONTRECORD, true, 0.0);
	cv_ASDCtypetank=CreateConVar("ASDCtypetank", "0", "Is tank spawn on (1/0). Set to 0 to disable.", FCVAR_NOTIFY|FCVAR_DONTRECORD, true, 0.0);
	cv_ASDCtypewitch=CreateConVar("ASDCtypewitch", "1", "Is witch spawn on (1/0). Set to 0 to disable.", FCVAR_NOTIFY|FCVAR_DONTRECORD, true, 0.0);

	//Math
	cv_ASDCbase=CreateConVar("ASDCbase", "1", "Base time scale for difficulty controller. Set base and mult to 0 to turn off ASDC.", FCVAR_NOTIFY|FCVAR_DONTRECORD, true, 0.0);
	cv_ASDCmult=CreateConVar("ASDCmult", "1", "Multiplication tuning for difficulty controller. Set base and mult to 0 to turn off ASDC.", 0, true, 0.0);
	cv_ASDCCImult=CreateConVar("ASDCCImult", "1.0", "Multiplication tuning for CI difficulty controller. Set base and mult to 0 to turn off CI part of ASDC.", FCVAR_NOTIFY|FCVAR_DONTRECORD, true, 0.0);
	cv_ASDCFINmult=CreateConVar("ASDCFINmult", "1.3", "Multiplication tuning for CI finale difficulty controller. Set base and mult to 0 to turn off CI finale part of ASDC.", FCVAR_NOTIFY|FCVAR_DONTRECORD, true, 0.0);
	cv_ASDCCLmult=CreateConVar("ASDCCLmult", "4", "Multiplication tuning for CommonLimit difficulty controller. Set base and mult to 0 to turn off ASDC.", FCVAR_NOTIFY|FCVAR_DONTRECORD, true, 0.0);

	//Base Intervals
	cv_ASDCMOBinterval=CreateConVar("ASDCMOBinterval", "200", "How many ticks(unmodified seconds) till another Mob of CI spawns", FCVAR_NOTIFY|FCVAR_DONTRECORD, true, 0.0);
	cv_ASDCTankinterval=CreateConVar("ASDCtankinterval", "180", "How many ticks(unmodified seconds) till another tank spawns", FCVAR_NOTIFY|FCVAR_DONTRECORD, true, 0.0);
	cv_ASDCWitchinterval=CreateConVar("ASDCwitchinterval", "120", "How many ticks(unmodified seconds) till another witch spawns", FCVAR_NOTIFY|FCVAR_DONTRECORD, true, 0.0);

	//CI Controls
	cv_ASDCcommons=CreateConVar("ASDCcommons", "6", "Number of CI per person in a CI zombie wave.", FCVAR_NOTIFY|FCVAR_DONTRECORD, true, 0.0);
	cv_ASDCcommonsbackground=CreateConVar("ASDCcommonsbackground", "10", "Number of CI per person in a CI zombie wave.", FCVAR_NOTIFY|FCVAR_DONTRECORD, true, 0.0);
	cv_ASDCmob=CreateConVar("ASDCmob", "10", "Number of CI per person in a Mega CI zombie wave.", FCVAR_NOTIFY|FCVAR_DONTRECORD, true, 0.0);

	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("map_transition", Event_RoundEnd);
	HookEvent("round_start_pre_entity", Event_RoundEnd);
	HookEvent("round_start_post_nav", Event_RoundEnd);

	g_FlagUpdateReservedCommon=true;
	ConVar_GetValue();

	AutoExecConfig(true, "l4d2_ASDCconfig");
}

stock void ConVar_GetValue(){
	cv_ReservedCommon=FindConVar("z_reserved_wanderers");
	cv_PainPillsDecayRate=FindConVar("pain_pills_decay_rate");
	cv_CommonLimit=FindConVar("z_common_limit");
	cv_BackgroundLimit=FindConVar("z_background_limit");
	cv_WanderingDensity=FindConVar("z_wandering_density");
	cv_MobPopulationDensity=FindConVar("z_mob_population_density");
	cv_MegaMobSize=FindConVar("z_mega_mob_size");
	cv_MobSpawnMaxSize=FindConVar("z_mob_spawn_max_size");
	cv_MobSpawnFinaleSize=FindConVar("z_mob_spawn_finale_size");
	cv_DirectorRelaxMaxFlowTravel=FindConVar("director_relax_max_flow_travel");

	g_ReservedCommon=GetConVarInt(cv_ReservedCommon);
	g_FlowTravel=GetConVarInt(cv_DirectorRelaxMaxFlowTravel);
	g_ASDCBase=GetConVarFloat(cv_ASDCbase);
	g_ASDCMult=GetConVarFloat(cv_ASDCmult);
	g_ASDCCIMult=GetConVarFloat(cv_ASDCCImult);
	g_ASDCFINMult=GetConVarFloat(cv_ASDCFINmult);
	g_ASDCCLMult=GetConVarFloat(cv_ASDCCLmult);
	g_ASDCCommons=GetConVarFloat(cv_ASDCcommons);
	g_ASDCCommonsBackground=GetConVarFloat(cv_ASDCcommonsbackground);
	g_ASDCMob=GetConVarFloat(cv_ASDCmob);

	g_TypeMob=GetConVarBool(cv_ASDCtypeMOB);
	g_TypeTank=GetConVarBool(cv_ASDCtypetank);
	g_TypeWitch=GetConVarBool(cv_ASDCtypewitch);

	g_IntervalMob=GetConVarFloat(cv_ASDCMOBinterval);
	g_IntervalTank=GetConVarFloat(cv_ASDCTankinterval);
	g_IntervalWitch=GetConVarFloat(cv_ASDCWitchinterval);

	HookConVarChange(cv_ReservedCommon, OnReservedCommonChanged);
	HookConVarChange(cv_DirectorRelaxMaxFlowTravel, OnFlowTravelChanged);
	HookConVarChange(cv_ASDCbase, OnConVarChanged);
	HookConVarChange(cv_ASDCmult, OnConVarChanged);
	HookConVarChange(cv_ASDCCImult, OnConVarChanged);
	HookConVarChange(cv_ASDCFINmult, OnConVarChanged);
	HookConVarChange(cv_ASDCCLmult, OnConVarChanged);
	HookConVarChange(cv_ASDCcommons, OnConVarChanged);
	HookConVarChange(cv_ASDCcommonsbackground, OnConVarChanged);
	HookConVarChange(cv_ASDCmob, OnConVarChanged);
	HookConVarChange(cv_ASDCtypeMOB, OnConVarChanged);
	HookConVarChange(cv_ASDCtypetank, OnConVarChanged);
	HookConVarChange(cv_ASDCtypewitch, OnConVarChanged);
	HookConVarChange(cv_ASDCMOBinterval, OnConVarChanged);
	HookConVarChange(cv_ASDCTankinterval, OnConVarChanged);
	HookConVarChange(cv_ASDCWitchinterval, OnConVarChanged);
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue){
	g_ASDCBase=GetConVarFloat(cv_ASDCbase);
	g_ASDCMult=GetConVarFloat(cv_ASDCmult);
	g_ASDCCIMult=GetConVarFloat(cv_ASDCCImult);
	g_ASDCFINMult=GetConVarFloat(cv_ASDCFINmult);
	g_ASDCCLMult=GetConVarFloat(cv_ASDCCLmult);
	g_ASDCCommons=GetConVarFloat(cv_ASDCcommons);
	g_ASDCCommonsBackground=GetConVarFloat(cv_ASDCcommonsbackground);
	g_ASDCMob=GetConVarFloat(cv_ASDCmob);
	g_TypeMob=GetConVarBool(cv_ASDCtypeMOB);
	g_TypeTank=GetConVarBool(cv_ASDCtypetank);
	g_TypeWitch=GetConVarBool(cv_ASDCtypewitch);
	g_IntervalMob=GetConVarFloat(cv_ASDCMOBinterval);
	g_IntervalTank=GetConVarFloat(cv_ASDCTankinterval);
	g_IntervalWitch=GetConVarFloat(cv_ASDCWitchinterval);
}

public void OnReservedCommonChanged(ConVar convar, const char[] oldValue, const char[] newValue){
	if(g_FlagUpdateReservedCommon)
		g_ReservedCommon=StringToInt(newValue);
}

public void OnFlowTravelChanged(ConVar convar, const char[] oldValue, const char[] newValue){
	g_FlowTravel=StringToInt(newValue);
}

public Action Event_RoundStart(Handle event, const char[] name, bool dontBroadcast){
	char mapname[30];
	//Get map name
	GetCurrentMap(mapname, sizeof(mapname));

	g_FlagUpdateReservedCommon=true;
	g_FinaleFlag=0;
	if (StrEqual(mapname,"c8m5_rooftop", false)
		||StrEqual(mapname,"c9m2_lots", false)
		||StrEqual(mapname,"c10m5_houseboat", false)
		||StrEqual(mapname,"c11m5_runway", false)
		||StrEqual(mapname,"c12m5_cornfield", false)
		||StrEqual(mapname,"c7m3_port", false)
		||StrEqual(mapname,"c1m4_atrium", false)
		||StrEqual(mapname,"c6m3_port", false)
		||StrEqual(mapname,"c2m5_concert", false)
		||StrEqual(mapname,"c3m4_plantation", false)
		||StrEqual(mapname,"c4m5_milltown_escape", false)
		||StrEqual(mapname,"c5m5_bridge", false)
		||StrEqual(mapname,"c13m4_cutthroatcreek")
	){
		g_FinaleFlag=1;
	}

	g_FinaleEnable=1;
	if (StrEqual(mapname,"c1m4_atrium")
		// StrEqual(mapname,"c6m3_port")
		// StrEqual(mapname,"c3m4_plantation")
	){	
		g_FinaleEnable=0;
	}

	//Increase default limits to match spawns
	SetConVarInt(FindConVar("z_mob_min_notify_count"), RoundToCeil(g_ASDCCommons));
	SetConVarInt(FindConVar("z_mob_spawn_min_size"), RoundToCeil(g_ASDCCommons));
}

stock float ASDC(int TeamValue){
	float health=0.0;
	int temp=0;
	int alive=0, cnt=0;
	float ASDCout=0.0;

	for(int i=1; i<=MaxClients; i++){
		if(IsClientInGame(i)&&GetClientTeam(i)==TeamValue){
			if(IsPlayerAlive(i)&&!IsPlayerIncapped(i)){
				health+=GetClientRealHealth(i);
				alive++;
			}
			cnt++;
		}
	}

	if(alive==0)
		alive=4;
	g_Alive=alive;

	ASDCout=health/(100.0*float(cnt));

	SetConVarInt(cv_CommonLimit, (g_FinaleEnable?RoundToCeil(g_ASDCCLMult*alive):RoundToCeil(g_ASDCCLMult*alive/1.5))+g_ReservedCommon);
	
	//Set Amount of zombies to spawn in a waves
	SetConVarInt(cv_BackgroundLimit, RoundToCeil(g_ASDCCommonsBackground*ASDCout));
	//Sets CI density to 1% of ASDC output.
	health=(g_ASDCCommons*ASDCout*g_ASDCCIMult+g_ASDCCommons)*0.1;
	SetConVarFloat(cv_WanderingDensity, health);
	SetConVarFloat(cv_MobPopulationDensity, health);

	if(!g_FinaleEnable){
		temp=RoundToCeil((g_ASDCMob*alive*alive*ASDCout/cnt*g_ASDCFINMult+g_ASDCMob));
		SetConVarInt(cv_MegaMobSize, temp);
		g_MegaMobSize=temp;
		SetConVarInt(cv_MobSpawnFinaleSize, temp);
		g_MobSpawnFinaleSize=temp;
		SetConVarInt(cv_MobSpawnMaxSize, temp);
		g_MobSpawnMaxSize=temp;
	}else{
		temp=RoundToCeil(g_ASDCMob*alive*ASDCout*g_ASDCCIMult+g_ASDCMob);
		SetConVarInt(cv_MegaMobSize, temp);
		g_MegaMobSize=temp;
		temp=RoundToCeil(g_ASDCMob*alive*ASDCout*g_ASDCFINMult+g_ASDCMob);
		SetConVarInt(cv_MobSpawnFinaleSize, temp);
		g_MobSpawnFinaleSize=temp;
		temp=RoundToCeil(g_ASDCCommons*1*alive*g_ASDCCIMult*ASDCout+g_ASDCCommons);
		SetConVarInt(cv_MobSpawnMaxSize, temp);
		g_MobSpawnMaxSize=temp;
	}

	return ASDCout;
}

public Action L4D_OnGetScriptValueInt(const char[] key, int &retVal){
	int val=retVal;
	if(g_FinaleFlag==1){
		if(StrEqual(key, "CommonLimit")){
			if(g_FinaleEnable)
				val=RoundToCeil(g_ASDCCLMult*g_Alive)+g_ReservedCommon;
			else
				val=RoundToCeil(g_ASDCCLMult*g_Alive/1.5)+g_ReservedCommon;

			retVal=val;
			return Plugin_Handled;
		}
	}

	if(StrEqual(key, "WanderingZombieDensityModifier"))
		val*=10;
	// else if(StrEqual(key, "ShouldIgnoreClearStateForSpawn"))
	// 	val=1;
	else if(StrEqual(key, "AlwaysAllowWanderers"))
		val=1;
	// else if(StrEqual(key, "ClearedWandererRespawnChance")) 
	// 	val=50;
	else if(StrEqual(key, "EnforceFinaleNavSpawnRules")) 
		val=0;
	else if(StrEqual(key, "RelaxMaxFlowTravel")) 
		val=g_FlowTravel;
	else if(StrEqual(key, "PreferredMobDirection"))
		val=7; // SPAWN_IN_FRONT_OF_SURVIVORS
	// else if (StrEqual(key, "ZombieDontClear")) val = 0;
	else if(StrEqual(key, "NumReservedWanderers"))
		val=g_ReservedCommon*(1-g_FinaleFlag);
	else if(StrEqual(key, "PreferredSpecialDirection"))
		val=6; // SPAWN_ABOVE_SURVIVORS
	else if(StrEqual(key, "MegaMobSize"))
		val=g_MegaMobSize;
	else if(StrEqual(key, "MobMaxSize"))
		val=g_FinaleFlag?g_MobSpawnFinaleSize:g_MobSpawnMaxSize;

	if (val!=retVal){
		retVal=val;
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Action Event_RoundEnd(Handle event, const char[] name, bool dontBroadcast){
	//Kill timer to prevent spawn during load screen
	if(mTimer){
		KillTimer(mTimer);
		mTimer=null;
	}
}

public void OnClientPostAdminCheck(int client){
	// create tick timer when client loaded
	if(!mTimer){
		mTimer=CreateTimer(3.0, TimerUpdate, _, TIMER_REPEAT);

		// disable reserved_common in finale
		if(g_FinaleFlag==1){
			g_FlagUpdateReservedCommon=false;
			SetConVarInt(cv_ReservedCommon, 0);
			g_FlagUpdateReservedCommon=true;
		}else{
			g_FlagUpdateReservedCommon=false;
			SetConVarInt(cv_ReservedCommon, g_ReservedCommon);
			g_FlagUpdateReservedCommon=true;
		}
	}
}

public Action TimerUpdate(Handle timer){
	if(!IsServerProcessing())
		return;

	//Calculate tick/sec based on player health
	float temp=3.0*(g_ASDCBase+ASDC(2)*g_ASDCMult);

	//Increment ticks
	if(g_TypeTank){
		g_Tanktick+=temp;
	}
	if(g_TypeWitch){
		g_Witchtick+=temp;
	}
	if(g_TypeMob){
		g_MOBtick+=temp;
	}
	CountMonsters();
	//Spawn
	if(g_TypeTank&&g_Tanktick>=g_IntervalTank){
		if(g_TankCount<MAX_TANKS){
			int tankbot=CreateFakeClient("Tank");
			if(tankbot>0){
				//PrintToServer("Spawning Tank.");
				SpawnCommand(tankbot, "z_spawn_old", "tank auto");
				g_TankCount++;
			}
		}
		g_Tanktick=0.0;
	}

	if(g_TypeWitch&&g_Witchtick>=g_IntervalWitch){
		if(g_WitchCount<MAX_WITCHES){
			int witchbot=CreateFakeClient("Witch");
			if(witchbot>0){
				//PrintToServer("Spawning Witch.");
				SpawnCommand(witchbot, "z_spawn_old", "witch auto");
				g_WitchCount++;
			}
		}
		g_Witchtick=0.0;
	}

	if(g_TypeMob&&g_MOBtick>=g_IntervalMob){
		int spawnbot=CreateFakeClient("Mob");
		SpawnCommand(spawnbot, "z_spawn_old", "mob auto");
		g_MOBtick=0.0;
	}
}

public Action Kickbot(Handle timer, any client){
	if(IsFakeClient(client))
		KickClientEx(client);
}

stock void CountMonsters(){
	g_WitchCount=0;
	g_TankCount=0;
	char classname[32];
	for(int i=1; i<=MaxClients; i++){
		if(IsClientInGame(i)&&IsFakeClient(i)&&GetClientTeam(i)==3){
			GetClientModel(i, classname, sizeof(classname));

			if(g_TypeWitch&&StrContains(classname, "witch")){
				g_WitchCount++;
			}
			if(g_TypeTank&&StrContains(classname, "hulk")){
				g_TankCount++;
			}
		}
	}
}

stock bool IsTank(int client){
    char classname[32];
	GetClientModel(client, classname, sizeof(classname));
	if(StrContains(classname, "hulk", false)!=-1)
		return true;
	return false;
}

stock void SpawnCommand(int client, const char[] command, const char[] arguments=""){
	if(client){
		ChangeClientTeam(client, 3);
		int flags=GetCommandFlags(command);
		SetCommandFlags(command, flags&~FCVAR_CHEAT);
		FakeClientCommand(client, "%s %s", command, arguments);
		SetCommandFlags(command, flags|FCVAR_CHEAT);
		CreateTimer(0.1, Kickbot, client);
	}
}

stock bool IsPlayerIncapped(Client){
	if(GetEntProp(Client, Prop_Send, "m_isIncapacitated")==1)
		return true;
	else
		return false;
}

// From: https://forums.alliedmods.net/showthread.php?t=144780
stock int GetClientRealHealth(int client){
	//First, we get the amount of temporal health the client has
	float buffer=GetEntPropFloat(client, Prop_Send, "m_healthBuffer");

	//We declare the permanent and temporal health variables
	float TempHealth;
	int PermHealth=GetClientHealth(client);

	//In case the buffer is 0 or less, we set the temporal health as 0, because the client has not used any pills or adrenaline yet
	if(buffer<=0.0){
		TempHealth=0.0;
	}

	//In case it is higher than 0, we proceed to calculate the temporl health
	else{
		//This is the difference between the time we used the temporal item, and the current time
		float difference=GetGameTime()-GetEntPropFloat(client, Prop_Send, "m_healthBufferTime");

		//We get the decay rate from this convar (Note: Adrenaline uses this value)
		float decay=GetConVarFloat(cv_PainPillsDecayRate);

		//This is a constant we create to determine the amount of health. This is the amount of time it has to pass
		//before 1 Temporal HP is consumed.
		float constant=1.0/decay;

		//Then we do the calcs
		TempHealth=buffer-(difference/constant);
	}

	//If the temporal health resulted less than 0, then it is just 0.
	if(TempHealth<0.0){
		TempHealth=0.0;
	}

	//Return the value
	return RoundToFloor(PermHealth+TempHealth);
}
