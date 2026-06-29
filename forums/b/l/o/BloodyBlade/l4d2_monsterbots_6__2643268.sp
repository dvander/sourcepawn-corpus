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

int nummonsters, timertick, numoutrange, numsurvivors;
ConVar monstermaxbots, monstertype, monstertype2, monstertype3, monstertype4, monstertype5, monstertype6;
ConVar monsterbotson, monsterinterval, monsternodirector, monsterwitchrange;
Handle mTimer = null;

public void OnPluginStart()
{
	CreateConVar("monsterbots_version", PLUGIN_VERSION, "L4D2 Monster Bots Version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	monstermaxbots = CreateConVar("monsterbots_maxbots", "6", "The maximum amount of monster bots", FCVAR_NOTIFY, true, 0.0);
	monstertype6 = CreateConVar("monsterbots_type6", "0", "The second kind of special infected to spawn. Set to 9 to disable.", FCVAR_NOTIFY, true, 0.0);
	monstertype5 = CreateConVar("monsterbots_type5", "0", "The second kind of special infected to spawn. Set to 9 to disable.", FCVAR_NOTIFY, true, 0.0);
	monstertype4 = CreateConVar("monsterbots_type4", "0", "The second kind of special infected to spawn. Set to 9 to disable.", FCVAR_NOTIFY, true, 0.0);
	monstertype3 = CreateConVar("monsterbots_type3", "0", "The second kind of special infected to spawn. Set to 9 to disable.", FCVAR_NOTIFY, true, 0.0);
	monstertype2 = CreateConVar("monsterbots_type2", "0", "The second kind of special infected to spawn. Set to 9 to disable.", FCVAR_NOTIFY, true, 0.0);
	monstertype = CreateConVar("monsterbots_type", "0", "The first kind of special infected to spawn. Set to 9 to disable.", FCVAR_NOTIFY, true, 0.0);
	
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
			SetConVarInt(FindConVar("director_no_bosses"), 1);
			SetConVarInt(FindConVar("director_no_specials"), 1);
			SetConVarInt(FindConVar("director_no_mobs"), 1);
			SetConVarInt(FindConVar("z_common_limit"), 0);
		}
		SetConVarInt(FindConVar("z_max_player_zombies"), 8);

		timertick += 3;
		if (timertick >= monsterinterval.IntValue)
		{
			CountMonsters();
			if (nummonsters < monstermaxbots.IntValue)
			{
//				int bot = CreateFakeClient("Monster");
//				if (bot > 0)
//				{
				if (monstertype.IntValue != 9)
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
				if (monstertype2.IntValue != 9)
    			{
    			    int bot = CreateFakeClient("Monster");
    			    if (bot > 0)
    				{
    					int monster2 = monstertype2.IntValue;
    					switch(monster2)
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
				if (monstertype3.IntValue != 9)
    			{
    			    int bot = CreateFakeClient("Monster");
    			    if (bot > 0)
    				{
    					int monster3 = monstertype3.IntValue;
    					switch(monster3)
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
				if (monstertype4.IntValue != 9)
    			{
    			    int bot = CreateFakeClient("Monster");
    			    if (bot > 0)
    				{
    					int monster4 = monstertype4.IntValue;
    					switch(monster4)
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
				if (monstertype5.IntValue != 9)
    			{
    			    int bot = CreateFakeClient("Monster");
    			    if (bot > 0)
    				{
    					int monster5 = monstertype5.IntValue;
    					switch(monster5)
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
				if (monstertype6.IntValue != 9)
    			{
    			    int bot = CreateFakeClient("Monster");
    			    if (bot > 0)
    				{
    					int monster6 = monstertype6.IntValue;
    					switch(monster6)
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
//			    }
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
			SetConVarInt(FindConVar("director_no_bosses"), 0);
			SetConVarInt(FindConVar("director_no_specials"), 0);
			SetConVarInt(FindConVar("director_no_mobs"), 0);
			SetConVarInt(FindConVar("z_common_limit"), 20);

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
	int monster2 = monstertype2.IntValue;
	int monster3 = monstertype3.IntValue;
	int monster4 = monstertype4.IntValue;
	int monster5 = monstertype5.IntValue;
	int monster6 = monstertype6.IntValue;

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
	//monster 2
	if (monster2 != 7)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && IsFakeClient(i) && GetClientTeam(i) == 3)
			{
				GetClientModel(i, classname, sizeof(classname));
				switch(monster2)
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
					case 8:
					{
						if (StrContains(classname, "hulk"))
						{
							nummonsters++;
						}
					}
					case 9:
					{
						return;
					}
				}
			}
		}
	}
	else if (monster2 == 7)
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
	//monster 3
	if (monster3 != 7)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && IsFakeClient(i) && GetClientTeam(i) == 3)
			{
				GetClientModel(i, classname, sizeof(classname));
				switch(monster2)
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
					case 8:
					{
						if (StrContains(classname, "hulk"))
						{
							nummonsters++;
						}
					}
					case 9:
					{
						return;
					}
				}
			}
		}
	}
	else if (monster3 == 7)
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
	//monster 4
	if (monster4 != 7)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && IsFakeClient(i) && GetClientTeam(i) == 3)
			{
				GetClientModel(i, classname, sizeof(classname));
				switch(monster2)
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
					case 8:
					{
						if (StrContains(classname, "hulk"))
						{
							nummonsters++;
						}
					}
					case 9:
					{
						return;
					}
				}
			}
		}
	}
	else if (monster4 == 7)
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
	//monster 5
	if (monster5 != 7)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && IsFakeClient(i) && GetClientTeam(i) == 3)
			{
				GetClientModel(i, classname, sizeof(classname));
				switch(monster2)
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
					case 8:
					{
						if (StrContains(classname, "hulk"))
						{
							nummonsters++;
						}
					}
					case 9:
					{
						return;
					}
				}
			}
		}
	}
	else if (monster5 == 7)
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
	//monster 6
	if (monster6 != 7)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && IsFakeClient(i) && GetClientTeam(i) == 3)
			{
				GetClientModel(i, classname, sizeof(classname));
				switch(monster2)
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
					case 8:
					{
						if (StrContains(classname, "hulk"))
						{
							nummonsters++;
						}
					}
					case 9:
					{
						return;
					}
				}
			}
		}
	}
	else if (monster6 == 7)
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