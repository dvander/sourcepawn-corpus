#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#define PLUGIN_VERSION "1.2.0"

public Plugin myinfo =
{
	name = "L4D2 Monster Bots",
	author = "Machine, Modified by Fwoosh",
	description = "Automated Special Infected Creator",
	version = PLUGIN_VERSION,
	url = "www.AlliedMods.net"
};

//////////////////////////////////////////////////////////
//Monster Types
//
//0 = Random (Smoker,Boomer,Hunter,Spitter,Jockey,Charger)
//1 = Smoker
//2 = Boomer
//3 = Hunter
//4 = Spitter
//5 = Jockey
//6 = Charger
//7 = Witch
//8 = Tank
//////////////////////////////////////////////////////////

int nummonsters;
ConVar monstermaxbots;
ConVar monstertype;

ConVar ASDCon;
ConVar diffcontbase;
ConVar diffcontmult;

ConVar monsterbotson;
ConVar monsterinterval;
ConVar monsternodirector;
ConVar monsterwitchrange;
Handle mTimer = null;
int timertick;
int numoutrange;
int numsurvivors;

float diffmult = 1.0;

public void OnPluginStart()
{
	CreateConVar("monsterbots_version", PLUGIN_VERSION, "L4D Monster Bots Version", FCVAR_NOTIFY|FCVAR_SPONLY|FCVAR_DONTRECORD);
	monstermaxbots = CreateConVar("monsterbots_maxbots", "4", "The maximum amount of monster bots", FCVAR_NOTIFY, true, 0.0);
	monstertype = CreateConVar("monsterbots_type", "0", "The first kind of special infected to spawn. Set to 6 to disable.", FCVAR_NOTIFY, true, 0.0);
	
	ASDCon = CreateConVar("monsterbots_ASDCon", "1", "Automatic Scaling Difficulty Controller On/Off.", FCVAR_NOTIFY, true, 0.0);
	diffcontbase = CreateConVar("monsterbots_diff_base", "1.0", "Base time scale for difficulty controller.", FCVAR_NOTIFY, true, 0.0);
	diffcontmult = CreateConVar("monsterbots_diff_mult", "1.0", "Multiplication tuning for difficulty controller.", FCVAR_NOTIFY, true, 0.0);
	
	monsterbotson = CreateConVar("monsterbots_on", "1", "Is monster bots on?", FCVAR_NOTIFY, true, 0.0);
	monsterinterval = CreateConVar("monsterbots_interval", "10", "How many seconds till another monster spawns", FCVAR_NOTIFY, true, 0.0);
	monsternodirector = CreateConVar("monsterbots_nodirector", "0", "Shutdown the director?", FCVAR_NOTIFY, true, 0.0);
	monsterwitchrange = CreateConVar("monsterbots_witchrange", "0", "The range from survivors that witch should be recycled", FCVAR_NOTIFY, true, 0.0);

	monsterbotson.AddChangeHook(MonsterBots_Switch);

	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("map_transition", Event_RoundEnd);
	HookEvent("round_start_pre_entity", Event_RoundEnd);
	HookEvent("round_start_post_nav", Event_RoundEnd);
	HookEvent("infected_death", Game_Start);
	
	AutoExecConfig(true, "l4d2_monsterbots_config");
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	int flags = GetConVarFlags(FindConVar("z_max_player_zombies"));
	SetConVarBounds(FindConVar("z_max_player_zombies"), ConVarBound_Upper, false);
	SetConVarFlags(FindConVar("z_max_player_zombies"), flags & ~FCVAR_NOTIFY);
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	if(mTimer)
	{
		delete mTimer;
	}

	if(monsterbotson.IntValue == 1)
	{
		for(int i = 1; i <= MaxClients; i++)
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
    if(!mTimer)
    {
        mTimer = CreateTimer(3.0, TimerUpdate, _, TIMER_REPEAT);
    }
}

public Action TimerUpdate(Handle timer)
{
	if (!IsServerProcessing()) return;

	if (monsterbotson.IntValue == 1)
	{
		if (monsternodirector.IntValue == 1)
		{
			int anyclient = GetAnyClient();
			if (anyclient > 0)
			{
				DirectorCommand(anyclient, "director_stop");
			}
			FindConVar("director_no_bosses").SetInt(1);
			FindConVar("director_no_specials").SetInt(1);
			FindConVar("director_no_mobs").SetInt(1);
		}

		FindConVar("z_max_player_zombies").SetInt(8);

		if(ASDCon.IntValue == 1)
		{
			UpdateDifficulty();
			timertick += RoundToFloor(3 * (diffcontbase.FloatValue + diffmult * diffcontmult.FloatValue));
		}
		else
		{
			timertick += 3;
		}

		if (timertick >= monsterinterval.IntValue)
		{
			CountMonsters();
			if (nummonsters < monstermaxbots.IntValue)
			{
				int bot = CreateFakeClient("Monster");
				if (bot > 0)
				{
					int monster = monstertype.IntValue;
					switch(monster)
					{
						case 0:
						{
							int random = GetRandomInt(1, 6);
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
						case 7:
							SpawnCommand(bot, "z_spawn_old", "witch auto");
						case 8:
							SpawnCommand(bot, "z_spawn_old", "tank auto");
					}
				}
			}
			timertick = 0;
		}
	}
}

public void MonsterBots_Switch(ConVar hVariable, const char[] strOldValue, const char[] strNewValue)
{
    if (monsterbotson.IntValue == 0)
	{
		if (monsternodirector.IntValue == 1)
		{
			FindConVar("director_no_bosses").SetInt(0);
			FindConVar("director_no_specials").SetInt(0);
			FindConVar("director_no_mobs").SetInt(0);

			int anyclient = GetAnyClient();
			if (anyclient > 0)
			{
				DirectorCommand(anyclient, "director_start");
			}
		}
	}
}

public Action Kickbot(Handle timer, any client)
{
	if (IsClientInGame(client) && IsFakeClient(client)) 
		KickClient(client);
}

void CountMonsters()
{
	nummonsters = 0;
	char classname[32];
	int monster = monstertype.IntValue;

	if (monster != 7)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && IsFakeClient(i) && GetClientTeam(i) == 3)
			{
				GetClientModel(i, classname, sizeof(classname));
				switch(monster)
				{
					case 0:
					{
						if (StrContains(classname, "smoker") 
						||  StrContains(classname, "boomer") 
						||  StrContains(classname, "hunter") 
						||  StrContains(classname, "spitter") 
						||  StrContains(classname, "jockey") 
						|| 	StrContains(classname, "charger")
						)
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
					case 8:
					{
						if (StrContains(classname, "hulk"))
						{
							nummonsters++;
						}
					}
				}
			}
		}
	}
	else if (monster == 7)
	{
		int entitycount = GetMaxEntities();
		for (int j = 1; j <= entitycount; j++)
		{
			if (IsValidEdict(j) && IsValidEntity(j))
			{
				GetEdictClassname(j, classname, sizeof(classname));
				if (StrEqual(classname, "witch"))
				{
					nummonsters++;
					if (nummonsters == monstermaxbots.IntValue)
					{
						float WitchPos[3], PlayerPos[3];
						GetEntPropVector(j, Prop_Send, "m_vecOrigin", WitchPos);
						for (int i = 1; i <= MaxClients; i++)
						{
							if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
							{
								GetClientAbsOrigin(i, PlayerPos);
								float distance = GetVectorDistance(WitchPos, PlayerPos);
								if (distance > monsterwitchrange.FloatValue)
								{
									numoutrange++;
									CountSurvivors();
									if (numoutrange == numsurvivors)
									{
										numoutrange = 0;
										RemoveEdict(j);
									}
								}
							}
						}
					}
				}
			}
		}
	}
}

void CountSurvivors()
{
	numsurvivors = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
		{
			numsurvivors++;
		}
	}
}

void UpdateDifficulty()
{
	float health = 0.0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
		{
			health += GetClientHealth(i);
		}
	}
	diffmult = health / 400.0;
}

bool IsTank(int i)
{
	char classname[32];
	GetClientModel(i, classname, sizeof(classname));
	if (StrContains(classname, "hulk", false) != -1)
		return true;
	return false;
}

stock int GetAnyClient()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && (!IsFakeClient(i)))
		{
			return i;
		}
	}
	return 0;
}

stock void SpawnCommand(int client, char[] command, char[] arguments = "")
{
	if (client)
	{
		ChangeClientTeam(client, 3);
		int flags = GetCommandFlags(command);
		SetCommandFlags(command, flags & ~FCVAR_CHEAT);
		FakeClientCommand(client, "%s %s", command, arguments);
		SetCommandFlags(command, flags | FCVAR_CHEAT);
		CreateTimer(0.1, Kickbot, client);
	}
}

stock void DirectorCommand(int client, char[] command)
{
	if (client)
	{
		int flags = GetCommandFlags(command);
		SetCommandFlags(command, flags & ~FCVAR_CHEAT);
		FakeClientCommand(client, "%s", command);
		SetCommandFlags(command, flags | FCVAR_CHEAT);
	}
}