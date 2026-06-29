//Left 4 Dead Gore v2.3 by DiscoBBQ:

//Include:
#include <sourcemod>
#include <sdktools>

//Terminate:
#pragma semicolon 1

//Variables:
static bool:PlayerIncapped[33];
static GlobalEnt[2000];
static Float:Headshot[2000];

//Config:
static Handle:Config;
static String:ConfigPath[128];
static BloodConfig[24];

//Write:
WriteParticle(Ent, String:ParticleName[], bool:Incapped = false)
{

	//Declare:
	decl Particle;
	decl String:tName[64];

	//Initialize:
	Particle = CreateEntityByName("info_particle_system");
	
	//Validate:
	if(IsValidEdict(Particle))
	{

		//Declare:
		decl Float:Position[3], Float:Angles[3];

		//Initialize:
		Angles[0] = GetRandomFloat(0.0, 360.0);
		Angles[1] = GetRandomFloat(-15.0, 15.0);
		Angles[2] = GetRandomFloat(-15.0, 15.0);

		//Origin:
        	GetEntPropVector(Ent, Prop_Send, "m_vecOrigin", Position);

		//Z Axis:
		if(!Incapped) Position[2] += GetRandomFloat(15.0, 65.0);
		else 
		{

			//Lower:
			Position[2] += GetRandomFloat(5.0, 45.0);

			//Randomize:
			Position[0] += GetRandomFloat(-15.0, 15.0);
			Position[1] += GetRandomFloat(-15.0, 15.0);
		}

		//Send:
        	TeleportEntity(Particle, Position, Angles, NULL_VECTOR);

		//Target Name:
		Format(tName, sizeof(tName), "Entity%d", Ent);
		DispatchKeyValue(Ent, "targetname", tName);
		GetEntPropString(Ent, Prop_Data, "m_iName", tName, sizeof(tName));

		//Properties:
		DispatchKeyValue(Particle, "targetname", "L4DParticle");
		DispatchKeyValue(Particle, "parentname", tName);
		DispatchKeyValue(Particle, "effect_name", ParticleName);

		//Spawn:
		DispatchSpawn(Particle);
	
		//Parent:		
		SetVariantString(tName);
		AcceptEntityInput(Particle, "SetParent", Particle, Particle);
		ActivateEntity(Particle);
		AcceptEntityInput(Particle, "start");

		//Delete:
		if(!Incapped) CreateTimer(1.5, DeleteParticle, Particle);
		else CreateTimer(0.5, DeleteParticle, Particle);
	}
}

//Delete:
public Action:DeleteParticle(Handle:Timer, any:Particle)
{

	//Validate:
	if(IsValidEntity(Particle))
	{

		//Declare:
		decl String:Classname[64];

		//Initialize:
		GetEdictClassname(Particle, Classname, sizeof(Classname));

		//Is a Particle:
		if(StrEqual(Classname, "info_particle_system", false))
		{

			//Delete:
			RemoveEdict(Particle);
		}
	}
}

//Damage (I):
public EventDamageInfected(Handle:Event, const String:Name[], bool:Broadcast)
{
	
	//Declare:
	decl Ent, Attacker, HitGroup;	

	//Initialize:
	Ent = GetEventInt(Event, "entityid");
	Attacker = GetEventInt(Event, "attacker");
	HitGroup = GetEventInt(Event, "hitgroup");

	//World:
	if(Ent != 0)
	{

		//Declare:
		decl Roll;

		//Blood #1:
		Roll = GetRandomInt(1, 100);
		if(Roll <= BloodConfig[1]) WriteParticle(Ent, "blood_impact_survivor_01");

		//Blood #2:
		Roll = GetRandomInt(1, 100);
		if(Roll <= BloodConfig[2]) WriteParticle(Ent, "blood_impact_headshot_01c");

		//Blood #3:
		Roll = GetRandomInt(1, 100);
		if(Roll <= BloodConfig[3]) WriteParticle(Ent, "blood_impact_infected_01_shotgun");

		//Blood #4:
		Roll = GetRandomInt(1, 100);
		if(Roll <= BloodConfig[4]) WriteParticle(Ent, "blood_impact_tank_02");

		//Blood #5:
		Roll = GetRandomInt(1, 100);
		if(Roll <= BloodConfig[5]) WriteParticle(Ent, "blood_impact_infected_01");

		//Chunks:
		Roll = GetRandomInt(1, 100);
		if(Roll <= BloodConfig[6]) WriteParticle(Ent, "boomer_explode_D");

		//Arterial:
		Roll = GetRandomInt(1, 100);
		if(Roll <= BloodConfig[7]) WriteParticle(Ent, "blood_impact_arterial_spray_cheap");

		//Tank:
		Roll = GetRandomInt(1, 100);
		if(Roll <= BloodConfig[8]) WriteParticle(Ent, "blood_impact_tank_01_cheap");

		//Headshot:
		if(HitGroup == 1)
		{

			//Save:
			GlobalEnt[Attacker] = Ent;
			Headshot[Attacker] = GetGameTime();
		}
	}
}

//Death (I):
public EventDeathInfected(Handle:Event, const String:Name[], bool:Broadcast)
{

	//Declare:
	decl Attacker;

	//Initialize:
	Attacker = GetEventInt(Event, "attacker");

	//Headshot:
	if(FloatAbs(Headshot[Attacker] - GetGameTime()) < 1.0)
	{

		//Enabled:
		if(BloodConfig[9] == 1)
		{

			//Gib:
			SetEntProp(GlobalEnt[Attacker], Prop_Send, "m_nBody", 19);
			SetEntProp(GlobalEnt[Attacker], Prop_Send, "m_gibbedLimbs", 16);
		}
	}
}

//Shove (I):
public EventShoveEntity(Handle:Event, const String:Name[], bool:Broadcast)
{

	//Declare:
	decl Ent, Roll;

	//Initialize:
	Ent = GetEventInt(Event, "entityid");

	//Tissue:
	Roll = GetRandomInt(1, 100);
	if(Roll <= BloodConfig[21]) WriteParticle(Ent, "blood_impact_headshot_01b");

	//Blood:
	Roll = GetRandomInt(1, 100);
	if(Roll <= BloodConfig[22]) WriteParticle(Ent, "blood_impact_survivor_01");

	//Blood #2:
	Roll = GetRandomInt(1, 100);
	if(Roll <= BloodConfig[23]) WriteParticle(Ent, "blood_impact_boomer_01");
}

//Damage (P):
public EventDamagePlayer(Handle:Event, const String:Name[], bool:Broadcast)
{

	//Declare:
	decl Client, Team;

	//Initialize Id's:
	Client = GetClientOfUserId(GetEventInt(Event, "userid"));
	Team = GetClientTeam(Client);

	//World:
	if(Client != 0)
	{

		//Declare:
		decl Roll;

		//Blood #1:
		Roll = GetRandomInt(1, 100);
		if(Roll <= BloodConfig[10]) WriteParticle(Client, "blood_impact_headshot_01c");

		//Blood #2:
		Roll = GetRandomInt(1, 100);
		if(Roll <= BloodConfig[11]) WriteParticle(Client, "blood_impact_infected_01_shotgun");

		//Blood #3:
		Roll = GetRandomInt(1, 100);
		if(Roll <= BloodConfig[12]) WriteParticle(Client, "blood_impact_boomer_01");

		//Blood #4:
		Roll = GetRandomInt(1, 100);
		if(Roll <= BloodConfig[13]) WriteParticle(Client, "blood_impact_tank_02");

		//Blood #5:
		Roll = GetRandomInt(1, 100);
		if(Roll <= BloodConfig[14]) WriteParticle(Client, "blood_impact_infected_01");

		//Chunks:
		Roll = GetRandomInt(1, 100);
		if(Roll <= BloodConfig[15]) WriteParticle(Client, "boomer_explode_D");

		//Arterial:
		Roll = GetRandomInt(1, 100);
		if(Roll <= BloodConfig[16]) WriteParticle(Client, "blood_impact_arterial_spray_cheap");

		//Tank:
		Roll = GetRandomInt(1, 100);
		if(Roll <= BloodConfig[17]) WriteParticle(Client, "blood_impact_tank_01_cheap");

		//Infected:
		if(Team == 3)
		{

			//Yellow:
			Roll = GetRandomInt(1, 100);
			if(Roll <= BloodConfig[18]) WriteParticle(Client, "blood_impact_yellow_01");

			//Green:
			Roll = GetRandomInt(1, 100);
			if(Roll <= BloodConfig[19]) WriteParticle(Client, "blood_impact_smoker_01");
		}
	}
}

//Incap (P):
public EventIncapPlayer(Handle:Event, const String:Name[], bool:Broadcast)
{

	//Declare:
	decl Client;

	//Initialize Id's:
	Client = GetClientOfUserId(GetEventInt(Event, "userid"));

	//World:
	if(Client != 0)
	{

		//Save:
		PlayerIncapped[Client] = true;
	}
}

//Revive (P):
public EventRevivePlayer(Handle:Event, const String:Name[], bool:Broadcast)
{

	//Declare:
	decl Client;

	//Initialize Id's:
	Client = GetClientOfUserId(GetEventInt(Event, "subject"));

	//World:
	if(Client != 0)
	{

		//Save:
		PlayerIncapped[Client] = false;
	}
}

//Round End:
public EventRoundEnd(Handle:Event, const String:Name[], bool:Broadcast)
{

	//Loop:
	for(new X = 1; X <= GetMaxClients(); X++)
	{
		//Alive:
		PlayerIncapped[X] = false;
	}
}

//Pre-Think:
public OnGameFrame()
{

	//Loop:
	for(new X = 1; X <= GetMaxClients(); X++)
	{

		//Declare:
		decl Roll;

		//Incapped:
		if(PlayerIncapped[X] && IsClientInGame(X))
		{

			//Initialize:
			Roll = GetRandomInt(1, 100);

			//Spray:
			if(Roll <= BloodConfig[21]) WriteParticle(X, "blood_impact_arterial_spray_cheap", true);
		}
		else if(IsClientInGame(X))
		{

			//Declare:
			decl Health;

			//Initialize:
			Health = GetClientHealth(X);

			//Bleed:
			if(Health <= 80 && IsPlayerAlive(X))
			{

				//Initialize:
				Roll = GetRandomInt(1, (Health * 5));

				//Continue:
				if(Roll == 1)
				{

					//Initialize:
					Roll = GetRandomInt(1, 100);

					//Spray:
					if(Roll <= BloodConfig[21]) WriteParticle(X, "blood_impact_arterial_spray_cheap", true);
				}
			}
		}
	}
}

//Integer Loading:
LoadInteger(Handle:Vault, const String:Key[32], const String:SaveKey[255], DefaultValue)
{

	//Declare:
	decl Variable;

	//Jump:
	KvJumpToKey(Vault, Key, false);

	//Money:
	Variable = KvGetNum(Vault, SaveKey, DefaultValue);

	//Rewind:
	KvRewind(Vault);

	//Return:
	return Variable;
}

//Precache:
ForcePrecache(String:ParticleName[])
{

	//Declare:
	decl Particle;
	
	//Initialize:
	Particle = CreateEntityByName("info_particle_system");
	
	//Validate:
	if(IsValidEdict(Particle))
	{

		//Properties:
		DispatchKeyValue(Particle, "effect_name", ParticleName);
		
		//Spawn:
		DispatchSpawn(Particle);
		ActivateEntity(Particle);
		AcceptEntityInput(Particle, "start");
		
		//Delete:
		CreateTimer(0.3, DeleteParticle, Particle, TIMER_FLAG_NO_MAPCHANGE);
	}
}

//Map Start:
public OnMapStart()
{

	//Load NPC Gore:
	BloodConfig[1] = LoadInteger(Config, "Infected Damage", "Blood1 Chance", 20);
	BloodConfig[2] = LoadInteger(Config, "Infected Damage", "Blood2 Chance", 20);
	BloodConfig[3] = LoadInteger(Config, "Infected Damage", "Blood3 Chance", 20);
	BloodConfig[4] = LoadInteger(Config, "Infected Damage", "Blood4 Chance", 20);
	BloodConfig[5] = LoadInteger(Config, "Infected Damage", "Blood5 Chance", 20);
	BloodConfig[6] = LoadInteger(Config, "Infected Damage", "Chunks Chance", 25);
	BloodConfig[7] = LoadInteger(Config, "Infected Damage", "Arterial Chance", 25);
	BloodConfig[8] = LoadInteger(Config, "Infected Damage", "Dark Blood Chance", 20);
	BloodConfig[9] = LoadInteger(Config, "Infected Death", "Extra Headshots", 1);

	//Load Player Gore:
	BloodConfig[10] = LoadInteger(Config, "Human Player Damage", "Blood1 Chance", 20);
	BloodConfig[11] = LoadInteger(Config, "Human Player Damage", "Blood2 Chance", 20);
	BloodConfig[12] = LoadInteger(Config, "Human Player Damage", "Blood3 Chance", 20);
	BloodConfig[13] = LoadInteger(Config, "Human Player Damage", "Blood4 Chance", 20);
	BloodConfig[14] = LoadInteger(Config, "Human Player Damage", "Blood5 Chance", 20);
	BloodConfig[15] = LoadInteger(Config, "Human Player Damage", "Chunks Chance", 25);
	BloodConfig[16] = LoadInteger(Config, "Human Player Damage", "Arterial Chance", 25);
	BloodConfig[17] = LoadInteger(Config, "Human Player Damage", "Dark Blood Chance", 20);
	BloodConfig[18] = LoadInteger(Config, "Human Player Damage", "Yellow Chance", 35);
	BloodConfig[19] = LoadInteger(Config, "Human Player Damage", "Green Chance", 35);
	BloodConfig[20] = LoadInteger(Config, "Human Player Incap", "Spray Chance", 2);

	//Load Melee Gore:
	BloodConfig[21] = LoadInteger(Config, "Melee", "Tissue Chance", 75);
	BloodConfig[22] = LoadInteger(Config, "Melee", "Red Chance", 75);
	BloodConfig[23] = LoadInteger(Config, "Melee", "Pink Chance", 75);

	//Force Precache:
	ForcePrecache("blood_impact_headshot_01b");
	ForcePrecache("blood_impact_headshot_01c");
	ForcePrecache("blood_impact_arterial_spray_cheap");
	ForcePrecache("boomer_explode_C");
	ForcePrecache("boomer_explode_D");
	ForcePrecache("blood_impact_tank_01_cheap");
	ForcePrecache("blood_impact_survivor_0");
	ForcePrecache("blood_impact_infected_01_shotgun");
	ForcePrecache("blood_impact_tank_02");
	ForcePrecache("blood_impact_infected_01");
	ForcePrecache("blood_impact_boomer_01");
	ForcePrecache("blood_impact_yellow_01");
	ForcePrecache("blood_impact_smoker_01");
}

//Information:
public Plugin:myinfo = 
{

	//Initialize:
	name = "L4D Gore",
	author = "DiscoBBQ",
	description = "Adds blood and gore",
	version = "2.3",
	url = "hiimjoemaley@hotmail.com"
};

//Initialization:
public OnPluginStart()
{

	//Register:
	PrintToServer("[SM] L4D Gore v2.3 by DiscoBBQ loaded Successfully!");

	//Events:
	HookEvent("infected_hurt", EventDamageInfected);
	HookEvent("infected_death", EventDeathInfected);
	HookEvent("player_hurt", EventDamagePlayer);
	HookEvent("entity_shoved", EventShoveEntity);
	HookEvent("player_incapacitated_start", EventIncapPlayer);
	HookEvent("revive_success", EventRevivePlayer);
	HookEvent("player_death", EventRevivePlayer);
	HookEvent("round_end_message", EventRoundEnd);
	HookEvent("round_start_pre_entity", EventRoundEnd);
	HookEvent("round_start_post_nav", EventRoundEnd);

	//Build:
	BuildPath(Path_SM, ConfigPath, 128, "data/gore_config.txt");

	//Config:
	Config = CreateKeyValues("Config");
	if(!FileToKeyValues(Config, ConfigPath))
		PrintToServer("[SM] ERROR: Missing file or incorrectly formated, '%s'", ConfigPath);

	//Tracking:
	CreateConVar("l4dgore_version", "2.3", "Base L4DGore Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
}
