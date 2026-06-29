#pragma semicolon 1
#include <sourcemod>
#define PLUGIN_VERSION "1.1.2"

public Plugin:myinfo =
{
	name = "L4D2 Monster Bots",
	author = "Machine",
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

new nummonsters;
new Handle:monstermaxbots;
new Handle:monstertype;
new Handle:monstertype2;
new Handle:monsterbotson;
new Handle:monsterinterval;
new Handle:monsternodirector;
new Handle:monsterwitchrange;
new timertick;
new numoutrange;
new numsurvivors;

public OnPluginStart()
{
	CreateConVar("monsterbots_version", PLUGIN_VERSION, "L4D2 Monster Bots Version", FCVAR_PLUGIN|FCVAR_DONTRECORD);
	monstermaxbots = CreateConVar("monsterbots_maxbots", "8", "The maximum amount of monster bots", FCVAR_PLUGIN, true, 0.0);
	monstertype2 = CreateConVar("monsterbots_type2", "0", "the of monsters 2", FCVAR_PLUGIN, true, 0.0);
	monstertype = CreateConVar("monsterbots_type", "0", "The type of monsters", FCVAR_PLUGIN, true, 0.0);
	monsterbotson = CreateConVar("monsterbots_on","0", "Is monster bots on?", FCVAR_PLUGIN, true, 0.0);
	monsterinterval = CreateConVar("monsterbots_interval","7", "How many seconds till another monster spawns", FCVAR_PLUGIN, true, 0.0);
	monsternodirector = CreateConVar("monsterbots_nodirector","0", "Shutdown the director?", FCVAR_PLUGIN, true, 0.0);
	monsterwitchrange = CreateConVar("monsterbots_witchrange","1500", "The range from survivors that witch should be recycled", FCVAR_PLUGIN, true, 0.0);

	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	HookConVarChange(monsterbotson, MonsterBots_Switch);

	CreateTimer(1.0,TimerUpdate, _, TIMER_REPEAT);

	AutoExecConfig(true, "l4d2_monsterbots_config");
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	new flags = GetConVarFlags(FindConVar("z_max_player_zombies"));
	SetConVarBounds(FindConVar("z_max_player_zombies"), ConVarBound_Upper, false);
	SetConVarFlags(FindConVar("z_max_player_zombies"), flags & ~FCVAR_NOTIFY);
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
    	if (GetConVarInt(monsterbotson) == 1) 
	{
		for (new i=1; i<=MaxClients; i++)
		{
			if (IsClientInGame(i) && IsFakeClient(i) && GetClientTeam(i) == 3 && !IsTank(i))
			{
				KickClient(i);
			}
		}
	}
}

public Action:TimerUpdate(Handle:timer)
{
	if (!IsServerProcessing()) return;

    	if (GetConVarInt(monsterbotson) == 1)
	{
		if (GetConVarBool(monsternodirector))
		{
			new anyclient = GetAnyClient();
			if (anyclient > 0)
			{
				DirectorCommand(anyclient, "director_stop");
			}
			SetConVarInt(FindConVar("director_no_bosses"), 1);
			SetConVarInt(FindConVar("director_no_specials"), 1);
			SetConVarInt(FindConVar("director_no_mobs"), 1);
			SetConVarInt(FindConVar("z_common_limit"), 0);
		}
		SetConVarInt(FindConVar("z_max_player_zombies"), 32);
		
		timertick += 1;
		if (timertick >= GetConVarInt(monsterinterval))
		{
			CountMonsters();
			if (nummonsters < GetConVarInt(monstermaxbots))
			{
				new bot = CreateFakeClient("Monster");
				if (bot > 0)
				{
					
					new monster = GetConVarInt(monstertype);
					switch(monster)
					{
						case 0:
						{
							new random = GetRandomInt(1,6);
							switch(random)
							{
								case 1:
								SpawnCommand(bot, "z_spawn", "smoker auto");
								case 2:
								SpawnCommand(bot, "z_spawn", "boomer auto");
								case 3:
								SpawnCommand(bot, "z_spawn", "hunter auto");
								case 4:
								SpawnCommand(bot, "z_spawn", "spitter auto");
								case 5:
								SpawnCommand(bot, "z_spawn", "jockey auto");
								case 6:
								SpawnCommand(bot, "z_spawn", "charger auto");
							}

						}
						case 1:
						SpawnCommand(bot, "z_spawn", "smoker auto");
						case 2:
						SpawnCommand(bot, "z_spawn", "boomer auto");
						case 3:
						SpawnCommand(bot, "z_spawn", "hunter auto");
						case 4:
						SpawnCommand(bot, "z_spawn", "spitter auto");
						case 5:
						SpawnCommand(bot, "z_spawn", "jockey auto");
						case 6:
						SpawnCommand(bot, "z_spawn", "charger auto");
						case 7:
						SpawnCommand(bot, "z_spawn", "witch auto");
						case 8:
						SpawnCommand(bot, "z_spawn", "tank auto");
					}
					
					
					//second monster type
					new bot2 = CreateFakeClient("Monster");
					if (bot2 > 0)
					{
						new monster2 = GetConVarInt(monstertype2);
						switch(monster2)
						{
							case 0:
							{
								new random1 = GetRandomInt(1,6);
								switch(random1)
								{
								case 1:
								SpawnCommand(bot2, "z_spawn", "smoker auto");
								case 2:
								SpawnCommand(bot2, "z_spawn", "boomer auto");
								case 3:
								SpawnCommand(bot2, "z_spawn", "hunter auto");
								case 4:
								SpawnCommand(bot2, "z_spawn", "spitter auto");
								case 5:
								SpawnCommand(bot2, "z_spawn", "jockey auto");
								case 6:
								SpawnCommand(bot2, "z_spawn", "charger auto");
								}
							}
							case 1:
							SpawnCommand(bot2, "z_spawn", "smoker auto");
							case 2:
							SpawnCommand(bot2, "z_spawn", "boomer auto");
							case 3:
							SpawnCommand(bot2, "z_spawn", "hunter auto");
							case 4:
							SpawnCommand(bot2, "z_spawn", "spitter auto");
							case 5:
							SpawnCommand(bot2, "z_spawn", "jockey auto");
							case 6:
							SpawnCommand(bot2, "z_spawn", "charger auto");
							case 7:
							SpawnCommand(bot2, "z_spawn", "witch auto");
							case 8:
							SpawnCommand(bot2, "z_spawn", "tank auto");
						}
						
					}
				}
			}
			timertick = 0;
		}
	}
}

public MonsterBots_Switch(Handle:hVariable, const String:strOldValue[], const String:strNewValue[])
{
    	if (GetConVarInt(monsterbotson) == 0) 
	{
		if (GetConVarBool(monsternodirector))
		{
			SetConVarInt(FindConVar("director_no_bosses"), 0);
			SetConVarInt(FindConVar("director_no_specials"), 0);
			SetConVarInt(FindConVar("director_no_mobs"), 0);
			SetConVarInt(FindConVar("z_common_limit"), 30);

			new anyclient = GetAnyClient();
			if (anyclient > 0)
			{
				DirectorCommand(anyclient, "director_start");
			}
		}
	}
}

public Action:Kickbot(Handle:timer, any:client)
{
	if (IsClientInGame(client) && IsFakeClient(client)) 
		KickClient(client);
}

CountMonsters()
{
	nummonsters = 0;
	decl String: classname[32];
	new monster = GetConVarInt(monstertype);
	new monster2 = GetConVarInt(monstertype2);

	if (monster != 7)
	{
		for (new i=1; i<=MaxClients; i++)
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
		new entitycount = GetMaxEntities();

		for (new j=1; j<=entitycount; j++)
		{
			if (IsValidEdict(j) && IsValidEntity(j))
			{
				GetEdictClassname(j, classname, sizeof(classname));
				if (StrEqual(classname, "witch"))
				{
					nummonsters++;
					if (nummonsters == GetConVarInt(monstermaxbots))
					{
						decl Float:WitchPos[3], Float:PlayerPos[3];
						GetEntPropVector(j, Prop_Send, "m_vecOrigin", WitchPos);
						for (new i=1; i<= MaxClients; i++)
                				{
                    					if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
                    					{
                        					GetClientAbsOrigin(i, PlayerPos);
                        					new Float:distance = GetVectorDistance(WitchPos, PlayerPos);
                        					if (distance > GetConVarFloat(monsterwitchrange))
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
		for (new i=1; i<=MaxClients; i++)
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
		new entitycount = GetMaxEntities();

		for (new j=1; j<=entitycount; j++)
		{
			if (IsValidEdict(j) && IsValidEntity(j))
			{
				GetEdictClassname(j, classname, sizeof(classname));
				if (StrEqual(classname, "witch"))
				{
					nummonsters++;
					if (nummonsters == GetConVarInt(monstermaxbots))
					{
						decl Float:WitchPos[3], Float:PlayerPos[3];
						GetEntPropVector(j, Prop_Send, "m_vecOrigin", WitchPos);
						for (new i=1; i<= MaxClients; i++)
                				{
                    					if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
                    					{
                        					GetClientAbsOrigin(i, PlayerPos);
                        					new Float:distance = GetVectorDistance(WitchPos, PlayerPos);
                        					if (distance > GetConVarFloat(monsterwitchrange))
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

CountSurvivors()
{
	numsurvivors = 0;

	for (new i=1; i<=MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
		{
			numsurvivors++;
		}
	}
}

bool:IsTank(i)
{
	decl String: classname[32];
	GetClientModel(i, classname, sizeof(classname));
	if (StrContains(classname, "hulk", false) != -1)
		return true;
	return false;
}

stock GetAnyClient()
{
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsClientInGame(i) && (!IsFakeClient(i)))
		{
			return i;
		}
	}
	return 0;
}

stock SpawnCommand(client, String:command[], String:arguments[] = "")
{
	if (client)
	{
		ChangeClientTeam(client,3);
		new flags = GetCommandFlags(command);
		SetCommandFlags(command, flags & ~FCVAR_CHEAT);
		FakeClientCommand(client, "%s %s", command, arguments);
		SetCommandFlags(command, flags);
		CreateTimer(0.1,Kickbot,client);
	}
}

stock DirectorCommand(client, String:command[])
{
	if (client)
	{
		new flags = GetCommandFlags(command);
		SetCommandFlags(command, flags & ~FCVAR_CHEAT);
		FakeClientCommand(client, "%s", command);
		SetCommandFlags(command, flags);
	}
}