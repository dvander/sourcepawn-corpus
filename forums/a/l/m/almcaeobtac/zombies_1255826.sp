#include <sourcemod>
#include <sdktools>

static String:ZombieSpawn[1001][128];
new Handle:CanSpawn;
new Handle:Population;
new Handle:Frequency;

public Plugin:myinfo = 
{
    name = "Dynamic NPC Spawner",
    author = "Alm",
    description = "Spawns NPCs randomly around the map.",
    version = "1.1",
    url = "http://www.roflservers.com/"
};

stock PrepFile(const String:FileName[])
{
	if(!FileExists(FileName))
	{
		decl Handle:File;
		File = OpenFile(FileName, "w+");
		CloseHandle(File);
	}
}

public OnPluginStart()
{
	PrepFile("cfg/zombiepopulations.cfg");
	PrepFile("cfg/zombiefrequencies.cfg");

	RegAdminCmd("z_addspawn", AddSpawn, ADMFLAG_CHEATS, "Creates a new zombie spawn where you stand.");
	
	CanSpawn = CreateConVar("z_enabled", "1", "Determines if zombies will be spawned.");
	Population = CreateConVar("z_population", "default", "Determines which zombie population to spawn.");
	Frequency = CreateConVar("z_frequency", "default", "Determines how often zombies will spawn.");

	new Refire = GetRefire();
	CreateTimer(float(Refire), PluginLifeTimer);

	HookEntityOutput("npc_zombie", "OnDeath", ZombieDeath);
}

public ZombieDeath(const String:output[], NPC, Killer, Float:Delay)
{
	CreateTimer(0.1, HeadcrabAI);
}

public Action:HeadcrabAI(Handle:Timer)
{
	decl String:Class[128];

	for(new NPC = 1; NPC < 3000; NPC++)
	{
		if(IsValidEdict(NPC) && IsValidEntity(NPC))
		{
			GetEdictClassname(NPC, Class, 128);
			
			if(StrEqual(Class, "npc_headcrab", false))
			{
				SetVariantString("player D_HT");
				AcceptEntityInput(NPC, "setrelationship");
			}
		}
	}
}

enum dirMode 
{ 
    o=777, 
    g=777, 
    u=777 
} 

public OnMapStart()
{
	for(new Reset = 1; Reset <= 1000; Reset++)
	{
		ZombieSpawn[Reset] = "null";
	}

	decl String:DirMap[128];
	GetCurrentMap(DirMap, 128);

	decl String:TryDir[255];
	Format(TryDir, 255, "cfg/%s", DirMap);

	if(!DirExists(TryDir))
	{
		CreateDirectory(TryDir, dirMode);
	}
		
	new GotCount = 0;
	decl String:EntClass[128];
	decl Float:EntOrg[3];

	for(new Ents = 1; Ents < 3000; Ents++)
	{
		if(IsValidEdict(Ents) && IsValidEntity(Ents) && GotCount < 1000)
		{
			GetEdictClassname(Ents, EntClass, 128);

			if(StrEqual(EntClass, "info_npc_spawn_destination", false))
			{
				GotCount++;
				GetEntPropVector(Ents, Prop_Data, "m_vecOrigin", EntOrg);
				Format(ZombieSpawn[GotCount], 128, "%f %f %f", EntOrg[0], EntOrg[1], EntOrg[2]);
				RemoveEdict(Ents);
			}
		}
	}

	if(GotCount < 1000)
	{
		decl String:MapName[128];
		GetCurrentMap(MapName, 128);

		decl String:WatFile[128];
		Format(WatFile, 128, "cfg/%s/zombiespawns.cfg", MapName);
		PrepFile(WatFile);

		AddSpawnsFromFile(MapName);
	}
}

stock GetSpawnCount()
{
	new ValidSpawns = 0;

	for(new Count = 1; Count <= 1000; Count++)
	{
		if(!StrEqual(ZombieSpawn[Count], "null", false))
		{
			ValidSpawns++;
		}
	}

	return ValidSpawns;
}

public GetRefire()
{
	decl Handle:File;
	File = OpenFile("cfg/zombiefrequencies.cfg", "r");

	decl String:SectionName[128];
	GetConVarString(Frequency, SectionName, 128);

	new bool:RightSection = false;
	new bool:FoundLine = false;

	decl String:FileLine[128];
	FileSeek(File, 0, SEEK_SET);

	while(!IsEndOfFile(File) && ReadFileLine(File, FileLine, 128))
	{
		TrimString(FileLine);

		if(StrEqual(FileLine, "}", false))
		{
			RightSection = false;
			continue;
		}

		if(StrEqual(FileLine, "{", false) || StrEqual(FileLine, "", false) || StrEqual(FileLine, " ", false))
		{
			continue;
		}

		if(!RightSection && StrEqual(FileLine, SectionName, false))
		{
			RightSection = true;
			continue;
		}

		if(RightSection && StrContains(FileLine, "refire", false) == 0)
		{
			FoundLine = true;
			break;
		}
	}

	CloseHandle(File);

	if(!FoundLine)
	{
		return 60;
	}

	decl String:Exploded[2][128];
	ExplodeString(FileLine, "=", Exploded, 2, 128);

	if(StrContains(Exploded[1], "-", false) == -1)
	{
		return StringToInt(Exploded[1]);
	}

	decl String:RandomPicks[2][128];
	ExplodeString(Exploded[1], "-", RandomPicks, 2, 128);

	return GetRandomInt(StringToInt(RandomPicks[0]), StringToInt(RandomPicks[1]));
}

public AddSpawnsFromFile(const String:MapName[])
{
	new SpawnCount = GetSpawnCount();

	decl String:WatFile[128];
	Format(WatFile, 128, "cfg/%s/zombiespawns.cfg", MapName);

	decl Handle:File;
	File = OpenFile(WatFile, "r");

	decl String:FileLine[128];
	FileSeek(File, 0, SEEK_SET);

	while(!IsEndOfFile(File) && ReadFileLine(File, FileLine, 128))
	{
		TrimString(FileLine);

		SpawnCount++;
		strcopy(ZombieSpawn[SpawnCount], 128, FileLine);

		if(SpawnCount >= 1000)
		{
			CloseHandle(File);
			return;
		}
	}

	CloseHandle(File);
	return;
}

public Action:AddSpawn(Client, Args)
{
	if(Client == 0)
	{
		ReplyToCommand(Client, "[SM] Can't create new spawns from RCON.");
		return Plugin_Handled;
	}

	if(GetSpawnCount() >= 1000)
	{
		ReplyToCommand(Client, "[SM] Spawn limit has been reached. (1000)");
		return Plugin_Handled;
	}

	decl Float:ClientPos[3];
	GetClientAbsOrigin(Client, ClientPos);

	decl String:MapName[128];
	GetCurrentMap(MapName, 128);

	decl String:WatFile[128];
	Format(WatFile, 128, "cfg/%s/zombiespawns.cfg", MapName);

	new SpawnCount = GetSpawnCount();
	SpawnCount++;

	Format(ZombieSpawn[SpawnCount], 128, "%f %f %f", ClientPos[0], ClientPos[1], ClientPos[2]);

	decl Handle:File;
	File = OpenFile(WatFile, "a");

	FileSeek(File, 0, SEEK_END);
	WriteFileLine(File, "%f %f %f", ClientPos[0], ClientPos[1], ClientPos[2]);
	CloseHandle(File);
			
	ReplyToCommand(Client, "[SM] Added new zombie spawn. (%s)", ZombieSpawn[SpawnCount]);

	return Plugin_Handled;
}

public GetSpawnAmount()
{
	decl Handle:File;
	File = OpenFile("cfg/zombiefrequencies.cfg", "r");

	decl String:SectionName[128];
	GetConVarString(Frequency, SectionName, 128);

	new bool:RightSection = false;
	new bool:FoundLine = false;

	decl String:FileLine[128];
	FileSeek(File, 0, SEEK_SET);

	while(!IsEndOfFile(File) && ReadFileLine(File, FileLine, 128))
	{
		TrimString(FileLine);

		if(StrEqual(FileLine, "}", false))
		{
			RightSection = false;
			continue;
		}

		if(StrEqual(FileLine, "{", false) || StrEqual(FileLine, "", false) || StrEqual(FileLine, " ", false))
		{
			continue;
		}

		if(!RightSection && StrEqual(FileLine, SectionName, false))
		{
			RightSection = true;
			continue;
		}

		if(RightSection && StrContains(FileLine, "spawns", false) == 0)
		{
			FoundLine = true;
			break;
		}
	}

	CloseHandle(File);

	if(!FoundLine)
	{
		return 1;
	}

	decl String:Exploded[2][128];
	ExplodeString(FileLine, "=", Exploded, 2, 128);

	if(StrContains(Exploded[1], "-", false) == -1)
	{
		return StringToInt(Exploded[1]);
	}

	decl String:RandomPicks[2][128];
	ExplodeString(Exploded[1], "-", RandomPicks, 2, 128);

	return GetRandomInt(StringToInt(RandomPicks[0]), StringToInt(RandomPicks[1]));
}

public GetMaxNPCS()
{
	decl Handle:File;
	File = OpenFile("cfg/zombiefrequencies.cfg", "r");

	decl String:SectionName[128];
	GetConVarString(Frequency, SectionName, 128);

	new bool:RightSection = false;
	new bool:FoundLine = false;

	decl String:FileLine[128];
	FileSeek(File, 0, SEEK_SET);

	while(!IsEndOfFile(File) && ReadFileLine(File, FileLine, 128))
	{
		TrimString(FileLine);

		if(StrEqual(FileLine, "}", false))
		{
			RightSection = false;
			continue;
		}

		if(StrEqual(FileLine, "{", false) || StrEqual(FileLine, "", false) || StrEqual(FileLine, " ", false))
		{
			continue;
		}

		if(!RightSection && StrEqual(FileLine, SectionName, false))
		{
			RightSection = true;
			continue;
		}

		if(RightSection && StrContains(FileLine, "max", false) == 0)
		{
			FoundLine = true;
			break;
		}
	}

	CloseHandle(File);

	if(!FoundLine)
	{
		return 1000;
	}

	decl String:Exploded[2][128];
	ExplodeString(FileLine, "=", Exploded, 2, 128);

	return StringToInt(Exploded[1]);
}

public GetNPCCount()
{
	decl String:CurPop[128];
	GetConVarString(Population, CurPop, 128);

	decl Handle:File;
	File = OpenFile("cfg/zombiepopulations.cfg", "r");

	new bool:RightSection = false;

	new TypeCount = 0;

	decl String:Exploded[2][128];

	decl String:FileLine[128];
	FileSeek(File, 0, SEEK_SET);

	while(!IsEndOfFile(File) && ReadFileLine(File, FileLine, 128))
	{
		TrimString(FileLine);

		if(StrEqual(FileLine, "}", false))
		{
			RightSection = false;
			continue;
		}

		if(StrEqual(FileLine, "{", false) || StrEqual(FileLine, "", false) || StrEqual(FileLine, " ", false))
		{
			continue;
		}

		if(!RightSection && StrEqual(FileLine, CurPop, false))
		{
			RightSection = true;
			continue;
		}

		if(RightSection)
		{
			TypeCount++;
		}
	}

	if(TypeCount == 0)
	{
		return 0;
	}

	decl String:NPCType[TypeCount+1][128];

	new TypeCount2 = 0;
	FileSeek(File, 0, SEEK_SET);

	while(!IsEndOfFile(File) && ReadFileLine(File, FileLine, 128))
	{
		TrimString(FileLine);

		if(StrEqual(FileLine, "}", false))
		{
			RightSection = false;
			continue;
		}

		if(StrEqual(FileLine, "{", false) || StrEqual(FileLine, "", false) || StrEqual(FileLine, " ", false))
		{
			continue;
		}

		if(!RightSection && StrEqual(FileLine, CurPop, false))
		{
			RightSection = true;
			continue;
		}

		if(RightSection)
		{
			TypeCount2++;
			ExplodeString(FileLine, "=", Exploded, 2, 128);
			strcopy(NPCType[TypeCount2], 128, Exploded[0]);
		}
	}

	CloseHandle(File);

	new FinalCount = 0;
	new TestClass = 0;
	decl String:EntClass[128];

	for(new Ents = 1; Ents < 3000; Ents++)
	{
		if(IsValidEdict(Ents) && IsValidEntity(Ents))
		{
			GetEdictClassname(Ents, EntClass, 128);

			if(StrContains(EntClass, "npc_", false) == 0)
			{
				ReplaceString(EntClass, 128, "npc_", " ", false);

				TrimString(EntClass);
				
				for(TestClass = 1; TestClass <= TypeCount; TestClass++)
				{
					if(StrEqual(EntClass, NPCType[TestClass], false))
					{
						FinalCount++;
					}
				}
			}
		}
	}

	return FinalCount;
}

public GetRandomZombieType(String:ZombieType[], stringlength)
{
	decl String:CurPop[128];
	GetConVarString(Population, CurPop, 128);

	decl Handle:File;
	File = OpenFile("cfg/zombiepopulations.cfg", "r");

	new bool:RightSection = false;

	new TypeCount = 0;

	decl String:FileLine[128];
	FileSeek(File, 0, SEEK_SET);

	while(!IsEndOfFile(File) && ReadFileLine(File, FileLine, 128))
	{
		TrimString(FileLine);

		if(StrEqual(FileLine, "}", false))
		{
			RightSection = false;
			continue;
		}

		if(StrEqual(FileLine, "{", false) || StrEqual(FileLine, "", false) || StrEqual(FileLine, " ", false))
		{
			continue;
		}

		if(!RightSection && StrEqual(FileLine, CurPop, false))
		{
			RightSection = true;
			continue;
		}

		if(RightSection)
		{
			TypeCount++;
		}
	}

	if(TypeCount == 0)
	{
		return;
	}

	decl String:NPCType[TypeCount+1][128];

	new TypeCount2 = 0;
	FileSeek(File, 0, SEEK_SET);

	while(!IsEndOfFile(File) && ReadFileLine(File, FileLine, 128))
	{
		TrimString(FileLine);

		if(StrEqual(FileLine, "}", false))
		{
			RightSection = false;
			continue;
		}

		if(StrEqual(FileLine, "{", false) || StrEqual(FileLine, "", false) || StrEqual(FileLine, " ", false))
		{
			continue;
		}

		if(!RightSection && StrEqual(FileLine, CurPop, false))
		{
			RightSection = true;
			continue;
		}

		if(RightSection)
		{
			TypeCount2++;
			strcopy(NPCType[TypeCount2], 128, FileLine);
		}
	}

	CloseHandle(File);

	new GotType = GetRandomInt(1, TypeCount);

	strcopy(ZombieType, stringlength, NPCType[GotType]);
	return;
}

public Occupied(Node)
{
	decl String:NodePoints[3][128];
	ExplodeString(ZombieSpawn[Node], " ", NodePoints, 3, 128);

	decl Float:NodeOrg[3];
	NodeOrg[0] = StringToFloat(NodePoints[0]);
	NodeOrg[1] = StringToFloat(NodePoints[1]);
	NodeOrg[2] = StringToFloat(NodePoints[2]);

	decl Float:EntOrg[3];
	decl String:EntClass[128];
	
	for(new Ents = 1; Ents < 3000; Ents++)
	{
		if(IsValidEdict(Ents) && IsValidEntity(Ents))
		{
			GetEdictClassname(Ents, EntClass, 128);

			if(StrContains(EntClass, "npc_", false) == 0)
			{
				GetEntPropVector(Ents, Prop_Send, "m_vecOrigin", EntOrg);
			}
			else
			{
				GetEntPropVector(Ents, Prop_Data, "m_vecOrigin", EntOrg);
			}

			if(Ents <= GetMaxClients())
			{
				if(GetVectorDistance(EntOrg, NodeOrg) <= 200)
				{
					return true;
				}
			}
			else
			{
				if(GetVectorDistance(EntOrg, NodeOrg) <= 100)
				{
					return true;
				}
			}
		}
	}

	return false;
}

public SpawnZombie()
{
	decl String:ZombieType[128];
	GetRandomZombieType(ZombieType, 128);
	decl String:SpawnZombieType[128];
	Format(SpawnZombieType, 128, "npc_%s", ZombieType);

	new NodeCount = 0;
	new CurrentNode = 1;

	while(CurrentNode <= GetSpawnCount())
	{
		if(!Occupied(CurrentNode))
		{
			NodeCount++;
		}
		CurrentNode++;
	}

	if(NodeCount == 0)
	{
		return;
	}

	decl ChooseNode[NodeCount+1];
	
	NodeCount = 0;
	CurrentNode = 1;

	while(CurrentNode <= GetSpawnCount())
	{
		if(!Occupied(CurrentNode))
		{
			NodeCount++;
			ChooseNode[NodeCount] = CurrentNode;
		}
		CurrentNode++;
	}

	new RandomNode = ChooseNode[GetRandomInt(1,NodeCount)];

	new Zombie = CreateEntityByName(SpawnZombieType);

	decl String:NodePoints[3][128];
	ExplodeString(ZombieSpawn[RandomNode], " ", NodePoints, 3, 128);

	decl Float:NodeOrg[3];
	NodeOrg[0] = StringToFloat(NodePoints[0]);
	NodeOrg[1] = StringToFloat(NodePoints[1]);
	NodeOrg[2] = StringToFloat(NodePoints[2]);

	NodeOrg[2] += 15.0;

	decl String:OrgString[128];
	Format(OrgString, 128, "%f %f %f", NodeOrg[0], NodeOrg[1], NodeOrg[2]);
	
	DispatchKeyValue(Zombie, "origin", OrgString);

	new Float:Angle = GetRandomFloat(0.0, 359.9);
	
	decl String:AngleString[128];
	Format(AngleString, 128, "0 %f 0", Angle);

	DispatchKeyValue(Zombie, "angles", AngleString);

	DispatchSpawn(Zombie);

	SetVariantString("player D_HT");
	AcceptEntityInput(Zombie, "setrelationship");

	return;
}

public Action:PluginLifeTimer(Handle:Timer)
{
	if(GetConVarBool(CanSpawn))
	{
		new NewSpawns = GetSpawnAmount();

		while((NewSpawns+GetNPCCount()) > GetMaxNPCS())
		{
			NewSpawns--;
			
			if(NewSpawns == 0)
			{
				break;
			}
		}

		if(NewSpawns > 0)
		{
			for(new DoSpawn = 1; DoSpawn <= NewSpawns; DoSpawn++)
			{
				SpawnZombie();
			}
		}
	}

	new Refire = GetRefire();
	CreateTimer(float(Refire), PluginLifeTimer);
}