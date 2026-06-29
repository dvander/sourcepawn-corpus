#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#define PLUGIN_VERSION "1.3"

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) 
{
	EngineVersion test = GetEngineVersion();
	
	if( test != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}
	
	return APLRes_Success; 
}


public Plugin myinfo =
{
	name = "L4D2 Automatic Scaling Difficulty Controller(ASDC)",
	author = "Fwoosh/harryhecanada, Harry remake code",
	description = "Difficulty Controller for the L4D2 AI director, automatically spawns extra zombies to increase difficulty.",
	version = PLUGIN_VERSION,
	url = "www.AlliedMods.net"
};

//Default limits for maximum tanks and witches, with seperate counters for each
#define MAX_WITCHES 4
#define MAX_TANKS 4

//Counting Variables
int nummonsters;
int witchcount=0;
int tankcount=0;

//Max amount of bots
ConVar ASDCbots=null;

//Handles for type selection
ConVar ASDCtype0=null;
ConVar ASDCtype1=null;
ConVar ASDCtype2=null;
ConVar ASDCtype3=null;
ConVar ASDCtypeMOB=null;
ConVar ASDCtypetank=null;
ConVar ASDCtypewitch=null;

//Tick per Time base and multiplier
ConVar ASDCbase=null;
ConVar ASDCmult=null;
ConVar ASDCCImult=null;

//Common infected amount handlers
ConVar ASDCcommons = null;
ConVar ASDCcommonsbackground = null;
ConVar ASDCmob = null;

//Intervals
ConVar ASDCMOBinterval=null;
ConVar ASDCSIinterval=null;
ConVar ASDCTankinterval=null;
ConVar ASDCWitchinterval=null;

//base Tick timer
Handle mTimer=null;

//Ticks for each type of spawn
float SItick=0.0;
float MOBtick=0.0;
float Tanktick=0.0;
float Witchtick=0.0;

//Array to store monster type spawned
int monster[4];

int l4d2flag=0;


public void OnPluginStart()
{
	CreateConVar("ASDCversion", PLUGIN_VERSION, "L4D2 Monster Bots Version", FCVAR_NOTIFY);
	//Get control variables
	ASDCbots = CreateConVar("ASDCmaxbots", "8", "The maximum amount of monster bots", FCVAR_NOTIFY, true, 0.0);
	
	//Type Enables
	ASDCtype0 = CreateConVar("ASDCtype0", "0", "The first kind of special infected to spawn. Set to 9 to disable.", FCVAR_NOTIFY, true, 0.0, true, 9.0);
	ASDCtype1 = CreateConVar("ASDCtype1", "0", "The second kind of special infected to spawn. Set to 9 to disable.", FCVAR_NOTIFY, true, 0.0, true, 9.0);
	ASDCtype2 = CreateConVar("ASDCtype2", "0", "The third kind of special infected to spawn. Set to 9 to disable.", FCVAR_NOTIFY, true, 0.0, true, 9.0);
	ASDCtype3 = CreateConVar("ASDCtype3", "0", "The fourth kind of special infected to spawn. Set to 9 to disable.", FCVAR_NOTIFY, true, 0.0, true, 9.0);
	ASDCtypeMOB = CreateConVar("ASDCtypeMOB", "1", "Is Mobs of Common Infected wave spawn on (1/0). Set to 0 to disable.", FCVAR_NOTIFY, true, 0.0);
	ASDCtypetank = CreateConVar("ASDCtypetank", "1", "Is tank spawn on (1/0). Set to 0 to disable.", FCVAR_NOTIFY, true, 0.0);
	ASDCtypewitch = CreateConVar("ASDCtypewitch", "1", "Is tank spawn on (1/0). Set to 0 to disable.", FCVAR_NOTIFY, true, 0.0);
	
	//Math
	ASDCbase = CreateConVar("ASDCbase", "1", "Base time scale for difficulty controller. Set base and mult to 0 to turn off ASDC.", FCVAR_NOTIFY, true, 0.0);
	ASDCmult = CreateConVar("ASDCmult", "1", "Multiplication tuning for difficulty controller. Set base and mult to 0 to turn off ASDC.", FCVAR_NOTIFY, true, 0.0);
	ASDCCImult = CreateConVar("ASDCCImult", "1", "Multiplication tuning for CI difficulty controller. Set base and mult to 0 to turn off CI part of ASDC.", FCVAR_NOTIFY, true, 0.0);
	
	//Base Intervals
	ASDCSIinterval = CreateConVar("ASDCSIinterval","30", "How many ticks(unmodified seconds) till another SI spawns", FCVAR_NOTIFY, true, 0.0);
	ASDCMOBinterval = CreateConVar("ASDCMOBinterval","200", "How many ticks(unmodified seconds) till another Mob of CI spawns", FCVAR_NOTIFY, true, 0.0);
	ASDCTankinterval = CreateConVar("ASDCtankinterval","180", "How many ticks(unmodified seconds) till another tank spawns", FCVAR_NOTIFY, true, 0.0);
	ASDCWitchinterval = CreateConVar("ASDCwitchinterval","120", "How many ticks(unmodified seconds) till another witch spawns", FCVAR_NOTIFY, true, 0.0);
	
	//CI Controls
	ASDCcommons = CreateConVar("ASDCcommons", "10", "Number of CI per person in a CI zombie wave.", FCVAR_NOTIFY, true, 0.0);
	ASDCcommonsbackground = CreateConVar("ASDCcommonsbackground", "15", "Number of CI per person in a CI zombie wave.", FCVAR_NOTIFY, true, 0.0);
	ASDCmob = CreateConVar("ASDCmob", "15", "Number of CI per person in a Mega CI zombie wave.", FCVAR_NOTIFY, true, 0.0);
	
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("map_transition", Event_RoundEnd);
	HookEvent("round_start_pre_entity", Event_RoundEnd);
	HookEvent("round_start_post_nav", Event_RoundEnd);
	HookEvent("infected_death", Game_Start);
	
	AutoExecConfig(true, "l4d2_ASDCconfig");
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast) 
{
	//Set amount of SI that can be spawned. By machine from monsterbots.
	int flags = GetConVarFlags(FindConVar("z_max_player_zombies"));
		
	char mapname[30];
	
	SetConVarBounds(FindConVar("z_max_player_zombies"), ConVarBound_Upper, false);
	SetConVarFlags(FindConVar("z_max_player_zombies"), flags & ~FCVAR_NOTIFY);
	SetConVarInt(FindConVar("z_max_player_zombies"), 32);
	
	//Increase default limits to match spawns
	SetConVarInt(FindConVar("z_mob_min_notify_count"), ASDCcommons.IntValue);
	
	//Get map name
	GetCurrentMap(mapname, sizeof(mapname));

	//Due to buggy nature of l4d1, we disable the mob spawn feature entirely.
	if (StrEqual(mapname,"c1m1_hotel")==true||
	StrEqual(mapname,"c7m1_docks")||
	StrEqual(mapname,"c6m1_riverbank")||
	StrEqual(mapname,"c2m1_highway")||
	StrEqual(mapname,"c3m1_plankcountry")||
	StrEqual(mapname,"c4m1_milltown_a")||
	StrEqual(mapname,"c5m1_waterfront")||
	StrEqual(mapname,"c13m1_alpinecreek"))
	{
		l4d2flag=1;
	}
	else if (StrEqual(mapname,"c7m1_docks.bsp")||
	StrEqual(mapname,"c8m1_apartment.bsp")||
	StrEqual(mapname,"c9m1_alleys.bsp")||
	StrEqual(mapname,"c10m1_caves.bsp")||
	StrEqual(mapname,"c11m1_greenhouse.bsp")||
	StrEqual(mapname,"c12m1_hilltop.bsp")
	)
	{
		l4d2flag=0;
	}
	
	if(l4d2flag==1)
	{
		SetConVarInt(FindConVar("z_mob_spawn_min_size"), ASDCcommons.IntValue);
		SetConVarInt(FindConVar("z_mob_spawn_max_size"), ASDCmob.IntValue*5);
		SetConVarInt(FindConVar("z_mob_spawn_finale_size"), ASDCmob.IntValue*5);
	}
	else
	{
		//Close to default l4d2 values. stop spawning witches and tanks.
		SetConVarInt(ASDCcommons,8);
		SetConVarInt(ASDCmob,8);
		SetConVarInt(ASDCtypeMOB,0);
		SetConVarInt(ASDCtypewitch,0);
		SetConVarInt(ASDCtypetank,0);
		//SetConVarInt(FindConVar("director_force_tank"), 1);
		//SetConVarInt(FindConVar("director_force_witch"), 1);	
	}
	
	//Not sure about ASDCing background limit, seemed to crash client game in certain situations.
	SetConVarInt(FindConVar("z_background_limit"), ASDCcommonsbackground.IntValue*4);
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast) 
{
	//Kill timer to prevent spawn during load screen
	if(mTimer)
	{
		KillTimer(mTimer);
		mTimer=null;
	}
	if(ASDCmult.FloatValue>0 && ASDCbase.IntValue>0) 
	{
		for(int i=1; i<=MaxClients; i++)
		{
			if(IsClientInGame(i) && IsFakeClient(i) && GetClientTeam(i) == 3 && !IsTank(i))
			{
				KickClient(i);
			}
		}
	}
}

public Action Game_Start(Event event, const char[] name, bool dontBroadcast) 
{
	//create tick timer when a zombie dies, had to be this way because other event hooks not reliable.
    if(!mTimer)
    {
        mTimer=CreateTimer(3.0,TimerUpdate, _, TIMER_REPEAT);
    }
}

public Action TimerUpdate(Handle timer)
{
	//put control vars in array for easier spawning
	monster[0]=ASDCtype0.IntValue;
	monster[1]=ASDCtype1.IntValue;
	monster[2]=ASDCtype2.IntValue;
	monster[3]=ASDCtype3.IntValue;

	if (!IsServerProcessing()) return;
	
	//Calculate tick/sec based on player health
	float temp=3*(ASDCbase.FloatValue+ASDC(2)*ASDCmult.FloatValue);
	
	//Increment ticks
	SItick += temp;
	if(ASDCtypetank)
	{
		Tanktick += temp;
	}
	if(ASDCtypewitch)
	{
		Witchtick += temp;
	}
	if(ASDCtypeMOB)
	{
		MOBtick += temp;
	}
	//Spawn SI
	if (Tanktick >= ASDCTankinterval.FloatValue)
	{
		CountMonsters();
		if(tankcount<MAX_TANKS)
		{
			int tankbot = CreateFakeClient("Tank");
			if (tankbot > 0)
			{
				//PrintToServer("Spawning Tank.");
				SpawnCommand(tankbot, "z_spawn_old", "tank auto");
				tankcount++;
			}
		}
		Tanktick = 0.0;
	}
	if (Witchtick >= ASDCWitchinterval.FloatValue)
	{
		CountMonsters();
		if(witchcount<MAX_WITCHES)
		{
			int witchbot = CreateFakeClient("Witch");
			if (witchbot > 0)
			{
				//PrintToServer("Spawning Witch.");
				SpawnCommand(witchbot, "z_spawn_old", "witch auto");
				witchcount++;
			}
		}
		Witchtick = 0.0;
	}
	
	if (MOBtick >= ASDCMOBinterval.FloatValue)
	{
		int spawnbot=CreateFakeClient("Mob");
		SpawnCommand(spawnbot, "z_spawn", "mob");
		MOBtick=0.0;
	}
	
	if (SItick >= ASDCSIinterval.FloatValue)
	{
		CountMonsters();
		int i=4;
		while(i)
		{
			if (nummonsters < ASDCbots.IntValue && monster[i-1]<7)
			{	
				int bot = CreateFakeClient("Monster");
				//PrintToServer("int Monster.");
				if (bot > 0)
				{
					switch(monster[i-1])
					{
						case 0:
						{
							int random = GetRandomInt(1,6);
							switch(random)
							{
								case 1:
								SpawnCommand(bot, "z_spawn_old", "smoker auto");
								case 2:
								SpawnCommand(bot, "z_spawn_old", "boomer auto");
								case 3:
								SpawnCommand(bot, "z_spawn_old", "hunter auto");
								case 4:
								SpawnCommand(bot, "z_spawn_old", "spitter auto");
								case 5:
								SpawnCommand(bot, "z_spawn_old", "jockey auto");
								case 6:
								SpawnCommand(bot, "z_spawn_old", "charger auto");
							}
						}
						case 1:
						SpawnCommand(bot, "z_spawn_old", "smoker auto");
						case 2:
						SpawnCommand(bot, "z_spawn_old", "boomer auto");
						case 3:
						SpawnCommand(bot, "z_spawn_old", "hunter auto");
						case 4:
						SpawnCommand(bot, "z_spawn_old", "spitter auto");
						case 5:
						SpawnCommand(bot, "z_spawn_old", "jockey auto");
						case 6:
						SpawnCommand(bot, "z_spawn_old", "charger auto");
					}
				}
				bot=0;
			}
			i--;
		}
		SItick = 0.0;
	}
}

public Action Kickbot(Handle timer, any client)
{
	if (IsFakeClient(client)) 
		KickClientEx(client);
}

void CountMonsters()
{
	nummonsters = 0;
	witchcount = 0;
	tankcount = 0;
	char classname[32];
	int n=4;
	while(n)
	{
		for (int i=1; i<=MaxClients; i++)
		{
			if (IsClientInGame(i) && IsFakeClient(i) && GetClientTeam(i) == 3)
			{
				GetClientModel(i, classname, sizeof(classname));
				switch(monster[n-1])
				{
					case 0:
					{
						if (StrContains(classname, "smoker") || StrContains(classname, "boomer") || StrContains(classname, "hunter") || StrContains(classname, "spitter") || StrContains(classname, "jockey") || StrContains(classname, "charger"))
						{
							nummonsters++;
						}
					}
					case 1:
					{
						if (StrContains(classname, "smoker"))
						{
							nummonsters++;
						}
					}
					case 2:
					{
						if (StrContains(classname, "boomer"))
						{
							nummonsters++;
						}
					}
					case 3:
					{
						if (StrContains(classname, "hunter"))
						{
							nummonsters++;
						}
					}
					case 4:
					{
						if (StrContains(classname, "spitter"))
						{
							nummonsters++;
						}
					}
					case 5:
					{
						if (StrContains(classname, "jockey"))
						{
							nummonsters++;
						}
					}
					case 6:
					{
						if (StrContains(classname, "charger"))
						{
							nummonsters++;
						}
					}
					
				}
				//Special cases for counting tank and witch
				if (StrContains(classname, "witch") && ASDCtypetank)
				{
					witchcount++;
				}
				if (StrContains(classname, "hulk") && ASDCtypewitch)
				{
					tankcount++;
				}
			}
		}
		n--;
	}
}

float ASDC(int TeamValue)
{
	float health=0.0;
	int temp=0;
	float ASDCout=0.0;
	
	for (int i=1; i<=MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == TeamValue)
		{
			health += GetClientHealth(i);
			temp++;
		}
	}
	
	ASDCout=health/(100.0*float(temp));
	
	//Sets CI density to 1% of ASDC output.
	temp=RoundToCeil(0.01*2*(ASDCcommons.FloatValue*ASDCout*ASDCCImult.FloatValue+ASDCcommons.FloatValue));
	SetConVarInt(FindConVar("z_wandering_density"), temp);
	SetConVarInt(FindConVar("z_mob_population_density"), temp);
	
	//Set Amount of zombies to spawn in a waves
	temp=temp*100;
	SetConVarInt(FindConVar("z_common_limit"), temp);
	SetConVarInt(FindConVar("z_background_limit"), temp);
	temp=RoundToCeil(2*(ASDCmob.FloatValue*ASDCout*ASDCCImult.FloatValue+ASDCmob.FloatValue));
	SetConVarInt(FindConVar("z_mega_mob_size"), temp);
	
	
	return ASDCout;
}

bool IsTank(int i)
{
	char classname[32];
	GetClientModel(i, classname, sizeof(classname));
	if (StrContains(classname, "hulk", false) != -1)
		return true;
	return false;
}

stock void SpawnCommand(int client, char[] command, char[] arguments = "")
{
	if (client)
	{
		ChangeClientTeam(client,3);
		int flags = GetCommandFlags(command);
		SetCommandFlags(command, flags & ~FCVAR_CHEAT);
		FakeClientCommand(client, "%s %s", command, arguments);
		SetCommandFlags(command, flags | FCVAR_CHEAT);
		CreateTimer(0.1,Kickbot,client);
	}
}