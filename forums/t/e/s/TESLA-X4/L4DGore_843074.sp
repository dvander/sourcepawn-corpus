//Left 4 Dead Gore v2.1.2 by Pinkfairie:

//Include:
#include <sourcemod>
#include <sdktools>

//Terminate:
#pragma semicolon 1

//Variables:
static GlobalEnt[20000];
static Float:Headshot[20000];

//Config:
static Handle:Config;
static String:ConfigPath[128];
static BloodConfig[12];

//Write:
WriteParticle(Ent, String:ParticleName[])
{
	//Declare:
	decl Particle;
	decl String:tName[64];

	//Initialize:
	Particle = CreateEntityByName("info_particle_system");
	
	//Validate:
	if (IsValidEdict(Particle) && IsValidEntity(Ent))
	{
		//Declare:
		decl Float:Position[3], Float:Angles[3];
		
		//Initialize:
		Angles[0] = GetRandomFloat(0.0, 360.0);
		Angles[1] = GetRandomFloat(-15.0, 15.0);
		Angles[2] = GetRandomFloat(-15.0, 15.0);
		
		//Origin:
		GetEntPropVector(Ent, Prop_Send, "m_vecOrigin", Position);
		Position[2] += GetRandomFloat(15.0, 65.0);
		TeleportEntity(Particle, Position, Angles, NULL_VECTOR);
		
		//Properties:
		GetEntPropString(Ent, Prop_Data, "m_iName", tName, sizeof(tName));
		DispatchKeyValue(Particle, "targetname", "L4DParticle");
		DispatchKeyValue(Particle, "parentname", tName);
		DispatchKeyValue(Particle, "effect_name", ParticleName);
		
		//Spawn:
		DispatchSpawn(Particle);
			
		//Parent:		
		SetVariantString(tName);
		AcceptEntityInput(Particle, "SetParent", Particle, Particle, 0);
		ActivateEntity(Particle);
		AcceptEntityInput(Particle, "start");
		
		//Delete:
		CreateTimer(1.5, DeleteParticle, Particle, TIMER_FLAG_NO_MAPCHANGE);
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

		//Blood:
		Roll = GetRandomInt(1, 100);
		if(Roll <= BloodConfig[0]) WriteParticle(Ent, "blood_impact_headshot_01c");

		//Chunks:
		Roll = GetRandomInt(1, 100);
		if(Roll <= BloodConfig[1]) WriteParticle(Ent, "boomer_explode_D");

		//Mist:
		Roll = GetRandomInt(1, 100);
		if(Roll <= BloodConfig[2]) WriteParticle(Ent, "boomer_explode_C");

		//Arterial:
		Roll = GetRandomInt(1, 100);
		if(Roll <= BloodConfig[3]) WriteParticle(Ent, "blood_impact_arterial_spray_cheap");

		//Tank:
		Roll = GetRandomInt(1, 100);
		if(Roll <= BloodConfig[4]) WriteParticle(Ent, "blood_impact_tank_01_cheap");

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
	if (FloatAbs(Headshot[Attacker] - GetGameTime()) < 1.0)
	{
		//Enabled:
		if(BloodConfig[5] == 1)
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
	if(Roll <= BloodConfig[11]) WriteParticle(Ent, "blood_impact_headshot_01b");
}


//Damage (P):
public EventDamagePlayer(Handle:Event, const String:Name[], bool:Broadcast)
{
	//Declare:
	decl Client;

	//Initialize Id's:
	Client = GetClientOfUserId(GetEventInt(Event, "userid"));

	//World:
	if(Client != 0)
	{
		//Declare:
		decl Roll;

		//Blood:
		Roll = GetRandomInt(1, 100);
		if(Roll <= BloodConfig[6]) WriteParticle(Client, "blood_impact_headshot_01c");

		//Chunks:
		Roll = GetRandomInt(1, 100);
		if(Roll <= BloodConfig[7]) WriteParticle(Client, "boomer_explode_D");

		//Arterial:
		Roll = GetRandomInt(1, 100);
		if(Roll <= BloodConfig[8]) WriteParticle(Client, "blood_impact_arterial_spray_cheap");

		//Tank:
		Roll = GetRandomInt(1, 100);
		if(Roll <= BloodConfig[9]) WriteParticle(Client, "blood_impact_tank_01_cheap");
	}
}

//Death (P):
public EventDeathPlayer(Handle:Event, const String:Name[], bool:Broadcast)
{
	//Declare:
	decl Client, Roll;

	//Initialize Id's:
	Client = GetClientOfUserId(GetEventInt(Event, "userid"));

	//World:
	if(Client != 0)
	{
		//Roll:
		Roll = GetRandomInt(1, 100);

		//Check:
		if(Roll <= BloodConfig[10])
		{
			//Blood:
			WriteParticle(Client, "blood_impact_headshot_01c");
			WriteParticle(Client, "boomer_explode_D");

			//Arterial:
			for(new X = 0; X < 10; X++) WriteParticle(Client, "blood_impact_arterial_spray_cheap");
		}
	}
}

//Shove (P):
public EventShovePlayer(Handle:Event, const String:Name[], bool:Broadcast)
{
	//Declare:
	decl Client, Roll;

	//Initialize:
	Client = GetEventInt(Event, "userid");

	//Tissue:
	Roll = GetRandomInt(1, 100);
	if(Roll == 1) WriteParticle(Client, "blood_impact_headshot_01b");
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

//Map Start:
public OnMapStart()
{
	//Load:
	BloodConfig[0] = LoadInteger(Config, "Infected Damage", "Blood Chance", 25);
	BloodConfig[1] = LoadInteger(Config, "Infected Damage", "Chunks Chance", 25);
	BloodConfig[2] = LoadInteger(Config, "Infected Damage", "Mist Chance", 5);
	BloodConfig[3] = LoadInteger(Config, "Infected Damage", "Arterial Chance", 25);
	BloodConfig[4] = LoadInteger(Config, "Infected Damage", "Dark Blood Chance", 20);
	BloodConfig[5] = LoadInteger(Config, "Infected Death", "Extra Headshots", 1);
	BloodConfig[6] = LoadInteger(Config, "Human Player Damage", "Blood Chance", 25);
	BloodConfig[7] = LoadInteger(Config, "Human Player Damage", "Chunks Chance", 25);
	BloodConfig[8] = LoadInteger(Config, "Human Player Damage", "Arterial Chance", 25);
	BloodConfig[9] = LoadInteger(Config, "Human Player Damage", "Dark Blood Chance", 20);
	BloodConfig[10] = LoadInteger(Config, "Human Player Death", "Spray Chance", 100);
	BloodConfig[11] = LoadInteger(Config, "Melee", "Tissue Chance", 75);
	
	//Force Precache:
	ForcePrecache("blood_impact_headshot_01b");
	ForcePrecache("blood_impact_headshot_01c");
	ForcePrecache("blood_impact_arterial_spray_cheap");
	ForcePrecache("boomer_explode_C");
	ForcePrecache("boomer_explode_D");
	ForcePrecache("blood_impact_tank_01_cheap");
}

//Information:
public Plugin:myinfo = 
{
	//Initialize:
	name = "L4D Gore",
	author = "Pinkfairie",
	description = "Adds blood and gore",
	version = "2.1.2",
	url = "hiimjoemaley@hotmail.com"
};

//Initialization:
public OnPluginStart()
{
	//Register:
	PrintToServer("[SM] L4D Gore v2.1.2 by Pinkfairie loaded Successfully!");
	
	//Events:
	HookEvent("infected_hurt", EventDamageInfected);
	HookEvent("infected_death", EventDeathInfected);
	HookEvent("player_hurt", EventDamagePlayer);
	HookEvent("player_death", EventDeathPlayer);
	HookEvent("player_shoved", EventShovePlayer);
	HookEvent("entity_shoved", EventShoveEntity);
	
	//Build:
	BuildPath(Path_SM, ConfigPath, 128, "data/gore_config.txt");
	
	//Config:
	Config = CreateKeyValues("Config");
	if(!FileToKeyValues(Config, ConfigPath))
		PrintToServer("[SM] ERROR: Missing file or incorrectly formated, '%s'", ConfigPath);
	
	//Tracking:
	CreateConVar("l4dgore_version", "2.1.2", "Base L4DGore Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
}

ForcePrecache(String:ParticleName[])
{
	// The whole point of this is to start the precaching immediately upon map start,
	// instead of when the first zombie is killed
	// As such, it's position isn't really important, as long as it spawns, activates,
	// and removes itself
	
	//Declare:
	decl Particle;
	
	//Initialize:
	Particle = CreateEntityByName("info_particle_system");
	
	//Validate:
	if (IsValidEdict(Particle))
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