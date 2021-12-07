//CS:S Goremod v5.3.2 by Joe 'DiscoBBQ' Maley:

//Terminate:
#pragma semicolon 1

//Includes:
#include <sourcemod>
#include <sdktools>

//Overflow:
static Float:PrethinkBuffer;

//Weapons:
static String:CSWeapon[7][32] = {"m3", "xm1014", "hegrenade", "g3sg1", "sg550", "awp", "scout"};

//Convars:
new Handle:hGibs;
new Handle:hBleedingHp;
new Handle:hBleedingFreq;
new Handle:hImpactBlood;
new Handle:hHeadshotBlood;
new Handle:hDeathBlood;

//Misc:
new BloodClient[2000];

//Information:
public Plugin:myinfo =
{

	//Initialize:
	name = "Goremod",
	author = "Joe 'Pinkfairie' Maley",
	description = "Adds Blood & Gore",
	version = "5.3.2",
	url = "hiimjoemaley@hotmail.com"
}

//Parent to Dead Body:
ParentToBody(Client, Particle, bool:Headshot = true)
{

	//Client:
	if(IsClientConnected(Client))
	{

		//Declare:
		decl Body;
		decl String:tName[64], String:Classname[64], String:ModelPath[64];

		//Initialize:
		Body = GetEntPropEnt(Client, Prop_Send, "m_hRagdoll");

		//Edict:
		if(IsValidEdict(Body))
		{

			//Target Name:
			Format(tName, sizeof(tName), "Body%d", Body);

			//Find:
			GetEdictClassname(Body, Classname, sizeof(Classname));

			//Model:
			GetClientModel(Client, ModelPath, 64);

			//Body Exists:
			if(IsValidEntity(Body) && StrEqual(Classname, "cs_ragdoll", false))
			{

				//Properties:
				DispatchKeyValue(Body, "targetname", tName);
				GetEntPropString(Body, Prop_Data, "m_iName", tName, sizeof(tName));

				//Parent:
				SetVariantString(tName);
				AcceptEntityInput(Particle, "SetParent", Particle, Particle, 0);
				if(Headshot)
				{
			
					//Work-Around:
					if(StrContains(ModelPath, "sas", false) != -1 || StrContains(ModelPath, "gsg", false) != -1)
					{

						//Back:
						SetVariantString("primary");
					}
					else
					{

						//Head:
						SetVariantString("forward");
					}

				}
				else
				{
			
					//Back:
					SetVariantString("primary");
				}

				//Parent:
				AcceptEntityInput(Particle, "SetParentAttachment", Particle, Particle, 0);
			}
		}
	}
}

//Write:
WriteParticle(Ent, String:ParticleName[], bool:Death = false, bool:Headshot = false)
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

		//Z Axis:f
		if(Death) Position[2] += GetRandomFloat(0.0, 5.0);
		else Position[2] += GetRandomFloat(15.0, 35.0);

		//Send:
        	TeleportEntity(Particle, Position, Angles, NULL_VECTOR);

		//Target Name:
		Format(tName, sizeof(tName), "Entity%d", Ent);
		DispatchKeyValue(Ent, "targetname", tName);
		GetEntPropString(Ent, Prop_Data, "m_iName", tName, sizeof(tName));

		//Properties:
		DispatchKeyValue(Particle, "targetname", "CSSParticle");
		DispatchKeyValue(Particle, "parentname", tName);
		DispatchKeyValue(Particle, "effect_name", ParticleName);

		//Spawn:
		DispatchSpawn(Particle);
	
		//Parent:
		if(Death)
		{
	
			//Headshot:
			if(Headshot)
				ParentToBody(Ent, Particle);
			else
				ParentToBody(Ent, Particle, false);
		}
		else
		{

			//Parent:
			SetVariantString(tName);
			AcceptEntityInput(Particle, "SetParent", Particle, Particle, 0);
		}

		ActivateEntity(Particle);
		AcceptEntityInput(Particle, "start");

		//Delete:
		CreateTimer(3.0, DeleteParticle, Particle);
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

//Decal:
stock Decal(Client, Float:Direction[3], bool:Bleeding = false)
{

	//Declare:
	decl Blood;
	decl String:Angles[128];

	//Format:
	Format(Angles, 128, "%f %f %f", Direction[0], Direction[1], Direction[2]);

	//Blood:
	Blood = CreateEntityByName("env_blood");

	//Create:
	if(IsValidEdict(Blood))
	{

		//Spawn:
		DispatchSpawn(Blood);

		//Properties:
		DispatchKeyValue(Blood, "color", "0");
		DispatchKeyValue(Blood, "amount", "1000");
		DispatchKeyValue(Blood, "spraydir", Angles);
		DispatchKeyValue(Blood, "spawnflags", "12");

		//Timer:
		if(!Bleeding)
		{

			//Save & Send:
			BloodClient[Blood] = Client;
			CreateTimer(GetRandomFloat(0.1, 1.0), EmitBlood, Blood);
		} 
		else AcceptEntityInput(Blood, "EmitBlood", Client);
	}

	//Detatch:
	if(Bleeding && IsValidEdict(Blood)) RemoveEdict(Blood);
}

//Emit Blood:
public Action:EmitBlood(Handle:Timer, any:Blood)
{

	//Emit:
	if(IsValidEdict(Blood) && IsClientConnected(BloodClient[Blood]))
		AcceptEntityInput(Blood, "EmitBlood", BloodClient[Blood]);

	//Detatch:
	if(IsValidEdict(Blood)) 
		RemoveEdict(Blood);
}

//Direction:
stock CalculateDirection(Float:ClientOrigin[3], Float:AttackerOrigin[3], Float:Direction[3])
{

	//Declare:
	decl Float:RatioDiviser, Float:Diviser, Float:MaxCoord;

	//X, Y, Z:
	Direction[0] = (ClientOrigin[0] - AttackerOrigin[0]) + GetRandomFloat(-25.0, 25.0);
	Direction[1] = (ClientOrigin[1] - AttackerOrigin[1]) + GetRandomFloat(-25.0, 25.0);
	Direction[2] = (GetRandomFloat(-125.0, -75.0));

	//Greatest Coordinate:
	if(FloatAbs(Direction[0]) >= FloatAbs(Direction[1])) MaxCoord = FloatAbs(Direction[0]);
	else MaxCoord = FloatAbs(Direction[1]);

	//Calculate:
	RatioDiviser = GetRandomFloat(100.0, 250.0);
	Diviser = MaxCoord / RatioDiviser;
	Direction[0] /= Diviser;
	Direction[1] /= Diviser;

	//Close:
	return;
}

//Gib:
stock Gib(Float:Origin[3], Float:Direction[3], String:Model[])
{

	//Declare:
	decl Ent, Roll;
	decl Float:MaxEnts;
	decl Float:Velocity[3];

	//Initialize:
	Ent = CreateEntityByName("prop_physics");
	MaxEnts = (0.9 * GetMaxEntities());
	Velocity[0] = Direction[0] * 400.0;
	Velocity[1] = Direction[0] * 400.0;
	Velocity[2] = Direction[0] * 400.0;
		
	//Anti-Crash:
	if(Ent < MaxEnts)
	{

		//Properties:
		DispatchKeyValue(Ent, "model", Model);
		SetEntProp(Ent, Prop_Send, "m_CollisionGroup", 1); 

		//Spawn:
		DispatchSpawn(Ent);
		
		//Send:
		TeleportEntity(Ent, Origin, Direction, Velocity);

		//Blood:
		Roll = GetRandomInt(1, 5);

		//blood_advisor_pierce_spray:
		if(Roll == 1) WriteParticle(Ent, "blood_advisor_pierce_spray");

		//blood_advisor_pierce_spray_b:
		if(Roll == 2) WriteParticle(Ent, "blood_advisor_pierce_spray_b");

		//blood_advisor_pierce_spray_c:
		if(Roll == 3) WriteParticle(Ent, "blood_advisor_pierce_spray_c");

		//blood_zombie_split_spray:
		if(Roll == 4) WriteParticle(Ent, "blood_zombie_split_spray");

		//blood_advisor_pierce_spray:
		if(Roll == 5) WriteParticle(Ent, "blood_advisor_pierce_spray");

		//Delete:
		CreateTimer(GetRandomFloat(15.0, 30.0), RemoveGib, Ent);
	}
}


//Random Gib:
stock RandomGib(Float:Origin[3], String:Model[])
{

	//Declare:
	decl Float:Direction[3];

	//Origin:
	Origin[0] += GetRandomFloat(-10.0, 10.0);
	Origin[1] += GetRandomFloat(-10.0, 10.0);
	Origin[2] += GetRandomFloat(-20.0, 20.0);

	//Direction:
	Direction[0] = GetRandomFloat(-1.0, 1.0);
	Direction[1] = GetRandomFloat(-1.0, 1.0);
	Direction[2] = GetRandomFloat(150.0, 200.0);

	//Gib:
	Gib(Origin, Direction, Model);
}

//Remove Gib:
public Action:RemoveGib(Handle:Timer, any:Ent)
{

	//Declare:
	decl String:Classname[64];

	//Initialize:
	if(IsValidEdict(Ent))
	{

		//Find:
		GetEdictClassname(Ent, Classname, sizeof(Classname)); 

		//Kill:
		if(StrEqual(Classname, "prop_physics", false)) RemoveEdict(Ent);
	}
}

//Body:
stock RemoveBody(Client)
{

	//Declare:
	decl BodyRagdoll;
	decl String:Classname[64];

	//Initialize:
	BodyRagdoll = GetEntPropEnt(Client, Prop_Send, "m_hRagdoll");
	if(IsValidEdict(BodyRagdoll))
	{
	
		//Find:
		GetEdictClassname(BodyRagdoll, Classname, sizeof(Classname)); 

		//Remove:
		if(StrEqual(Classname, "cs_ragdoll", false)) RemoveEdict(BodyRagdoll);
	}
}

//Bleed:
public Action:Bleed(Handle:Timer, any:Client)
{

	//Connected:
	if(IsClientInGame(Client))
	{

		//Still Hurt:
		if(GetClientHealth(Client) < 100 && IsPlayerAlive(Client))
		{

			//Declare:
			decl Roll;
			decl Float:Origin[3], Float:Direction[3];

			//Initialize:
			Roll = GetRandomInt(1, 2);
			GetClientAbsOrigin(Client, Origin);
			Origin[2] += 10.0;
	
			//Initialize:
			Direction[0] = GetRandomFloat(-1.0, 1.0);
			Direction[1] = GetRandomFloat(-1.0, 1.0);

			//Bleed:
			if(Roll == 1) WriteParticle(Client, "blood_zombie_split_spray_tiny");
			if(Roll == 2) WriteParticle(Client, "blood_zombie_split_spray_tiny2");

			//Drips #1:
			Roll = GetRandomInt(1, 2);
			if(Roll == 1) WriteParticle(Client, "blood_impact_red_01_droplets");

			//Drips #2:
			Roll = GetRandomInt(1, 2);
			if(Roll == 1) WriteParticle(Client, "blood_impact_red_01_smalldroplets");

			//Decal:
			Direction[2] = -1.0;
			Decal(Client, Direction, true);
		}
	}
}

//Damage:
public EventDamage(Handle:Event, const String:Name[], bool:Broadcast)
{

	//Declare:
	decl Client, Roll;
	decl Float:Origin[3];

	//Initialize:
	Client = GetClientOfUserId(GetEventInt(Event, "userid"));
	GetClientAbsOrigin(Client, Origin);
	Origin[2] += 35.0;

	//Multiplier:
	for(new X = 0; X < GetConVarInt(hImpactBlood); X++)
	{

		//blood_impact_red_01:
		Roll = GetRandomInt(1, 6);
		if(Roll == 1) WriteParticle(Client, "blood_impact_red_01");

		//blood_impact_red_01_droplets:
		Roll = GetRandomInt(1, 6);
		if(Roll == 2) WriteParticle(Client, "blood_impact_red_01_droplets");

		//blood_impact_red_01_smalldroplets:
		Roll = GetRandomInt(1, 6);
		if(Roll == 3) WriteParticle(Client, "blood_impact_red_01_smalldroplets");

		//blood_impact_red_01_goop:
		Roll = GetRandomInt(1, 6);
		if(Roll == 4) WriteParticle(Client, "blood_impact_red_01_goop");

		//blood_impact_red_01_mist:
		Roll = GetRandomInt(1, 6);
		if(Roll == 5) WriteParticle(Client, "blood_impact_red_01_mist");

		//blood_advisor_puncture:
		Roll = GetRandomInt(1, 6);
		if(Roll == 6) WriteParticle(Client, "blood_advisor_puncture");

		//blood_advisor_pierce_spray:
		Roll = GetRandomInt(1, 15);
		if(Roll == 1) WriteParticle(Client, "blood_advisor_pierce_spray");

		//blood_advisor_pierce_spray_b:
		Roll = GetRandomInt(1, 15);
		if(Roll == 2) WriteParticle(Client, "blood_advisor_pierce_spray_b");

		//blood_advisor_pierce_spray_c:
		Roll = GetRandomInt(1, 15);
		if(Roll == 3) WriteParticle(Client, "blood_advisor_pierce_spray_c");

		//blood_zombie_split_spray:
		Roll = GetRandomInt(1, 15);
		if(Roll == 4) WriteParticle(Client, "blood_zombie_split_spray");
	}
}	

//Death:
public EventDeath(Handle:Event, const String:Name[], bool:Broadcast)
{

	//Declare:
	decl bool:Headshot;
	decl Client, Attacker;
	decl String:Weapon[64];

	//Initialize:
	Headshot = GetEventBool(Event, "headshot");
	Client = GetClientOfUserId(GetEventInt(Event, "userid"));
	Attacker = GetClientOfUserId(GetEventInt(Event, "attacker"));
	GetEventString(Event, "weapon", Weapon, sizeof(Weapon));

	//Weapons:
	if(GetConVarBool(hGibs)) 
	{

		//Loop:
		for(new X = 0; X < 7; X++)
		{

			//Check:
			if(StrContains(Weapon, CSWeapon[X], false) != -1)
			{

				//Fake Attacker:
				Attacker = 0;
			}
		}
	}

	//Legit Attacker:
	if(Attacker != 0 && Attacker != Client)
	{

		//Headshot:
		if(Headshot)
		{

			//Declare:
			decl Float:Origin[3], Float:AttackerOrigin[3], Float:Direction[3];

			//Origin:
			GetClientAbsOrigin(Client, Origin);
			GetClientAbsOrigin(Attacker, AttackerOrigin);
			Origin[2] += 8.5;

			//Multiplier:
			for(new Y = 0; Y < GetConVarInt(hHeadshotBlood); Y++)
			{

				//Strings:
				WriteParticle(Client, "blood_advisor_puncture_withdraw", true, true);
				WriteParticle(Client, "blood_antlionguard_injured_heavy_tiny", true, true);

				//Droplets:
				WriteParticle(Client, "blood_impact_red_01_smalldroplets", true, true);
			}

			//Decals:
			for(new X = 0; X < (10 * GetConVarInt(hHeadshotBlood)); X++)
			{

				//Direction:
				Direction[0] = GetRandomFloat(-1.0, 1.0);
				Direction[1] = GetRandomFloat(-1.0, 1.0);
				Direction[2] = -1.0;

				//Send:
				Decal(Client, Direction, true);
			}
		}
		else
		{

			//Multiplier:
			for(new Y = 0; Y < GetConVarInt(hDeathBlood); Y++)
			{

				//Declare:
				decl Roll;

				//Initialize:
				Roll = GetRandomInt(1, 4);

				//blood_advisor_pierce_spray:
				if(Roll == 1) for(new X = 0; X < 3; X++) WriteParticle(Client, "blood_advisor_pierce_spray", true);

				//blood_advisor_pierce_spray_b:
				if(Roll == 2) for(new X = 0; X < 3; X++) WriteParticle(Client, "blood_advisor_pierce_spray_b", true);

				//blood_advisor_pierce_spray_c:
				if(Roll == 3) for(new X = 0; X < 3; X++) WriteParticle(Client, "blood_advisor_pierce_spray_c", true);

				//blood_zombie_split_spray:
				if(Roll == 4) for(new X = 0; X < 3; X++) WriteParticle(Client, "blood_zombie_split_spray", true);
			}
		}
	}
	else
	{

		//Declare:
		decl Float:Origin[3];

		//Origin:
		GetClientAbsOrigin(Client, Origin);
		Origin[2] += 8.5;
			
		//Gibbies:
		if(GetConVarBool(hGibs)) 
		{

			//Animate:
			RandomGib(Origin, "models/Gibs/HGIBS.mdl");
			RandomGib(Origin, "models/Gibs/HGIBS_rib.mdl");
			RandomGib(Origin, "models/Gibs/HGIBS_spine.mdl");
			RandomGib(Origin, "models/Gibs/HGIBS_scapula.mdl");

			//Remove Body:
			if(GetConVarBool(hGibs)) RemoveBody(Client);

			//Declare:
			decl Float:Direction[3];

			//Decals:
			for(new X = 0; X < 10; X++)
			{

				//Direction:
				Direction[0] = GetRandomFloat(-1.0, 1.0);
				Direction[1] = GetRandomFloat(-1.0, 1.0);
				Direction[2] = -1.0;

				//Send:
				Decal(Client, Direction);
			}
		}
	}

	//Close:
	CloseHandle(Event);
}

//Pre-Think:
public OnGameFrame()
{

	//Think Overflow:
	if(PrethinkBuffer <= (GetGameTime() - GetConVarInt(hBleedingFreq)))
	{

		//Refresh:
		PrethinkBuffer = GetGameTime();

		//Declare:
		decl MaxPlayers;

		//Initialize:
		MaxPlayers = GetMaxClients();
	
		//Loop:
		for(new Client = 1; Client <= MaxPlayers; Client++)
		{

			//Connected:
			if(IsClientInGame(Client))
			{

				//Alive:
				if(IsPlayerAlive(Client))
				{
					
					//Damaged:
					if(GetClientHealth(Client) <= GetConVarInt(hBleedingHp))
					{

							//Bleed:
							CreateTimer(1.0, Bleed, Client);
					}
				}
			}
		}
	}
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

	//Gibs:
	PrecacheModel("models/Gibs/HGIBS.mdl", true);
	PrecacheModel("models/Gibs/HGIBS_rib.mdl", true);
	PrecacheModel("models/Gibs/HGIBS_spine.mdl", true);
	PrecacheModel("models/Gibs/HGIBS_scapula.mdl", true);

	//Precache:
	ForcePrecache("blood_impact_red_01_droplets");
	ForcePrecache("blood_impact_red_01_smalldroplets");
	ForcePrecache("blood_zombie_split_spray_tiny");
	ForcePrecache("blood_zombie_split_spray_tiny2");
	ForcePrecache("blood_impact_red_01");
	ForcePrecache("blood_impact_red_01_goop");
	ForcePrecache("blood_impact_red_01_mist");
	ForcePrecache("blood_advisor_puncture");
	ForcePrecache("blood_advisor_puncture_withdraw");
	ForcePrecache("blood_antlionguard_injured_heavy_tiny");
	ForcePrecache("blood_advisor_pierce_spray");
	ForcePrecache("blood_advisor_pierce_spray_b");
	ForcePrecache("blood_advisor_pierce_spray_c");
	ForcePrecache("blood_zombie_split_spray");
}

//Initation:
public OnPluginStart()
{

	//Register:
	PrintToConsole(0, "[SM] Goremod v5.3.2 by Joe 'DiscoBBQ' Maley loaded successfully!");

	//Events:
	HookEvent("player_hurt", EventDamage);
	HookEvent("player_death", EventDeath);

	//Server Variable:
	CreateConVar("cssgore_version", "5.3.2", "Goremod Version",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);

	//Convars:
	hGibs =  CreateConVar("sm_gibs_enabled", "1", "Enable/disable skull/limbs/bones/etc.");
	hBleedingFreq = CreateConVar("sm_bleeding_frequency", "15", "Time between bleeding.");
	hBleedingHp = CreateConVar("sm_bleeding_health", "99", "HP required to start bleeding.");
	hImpactBlood = CreateConVar("sm_impact_blood_multiplier", "2", "Multiplier for amount of extra blood on normal impact damage.");
	hHeadshotBlood = CreateConVar("sm_headshot_blood_multiplier", "1", "Multiplier for amount of extra blood on headshot kills.");
	hDeathBlood = CreateConVar("sm_death_blood_multiplier", "1", "Multiplier for amount of extra blood on normal deaths.");
}