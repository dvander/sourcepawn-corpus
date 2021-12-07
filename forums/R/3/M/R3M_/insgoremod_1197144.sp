#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define NAME "Insurgency GoreMod"
#define VERSION "1.0"

static Handle:GoreSignatures;
static Handle:BloodDrips;
static Handle:BloodSpray;

static Float:PrethinkBuffer;

//Weapons:
static String:CSWeapon[2][32] = {"toz", "m1014"};

new bool:g_bNextDeathHeadshot[MAXPLAYERS+1] = false;

//Information:
public Plugin:myinfo =
{
	name = NAME,
	author = "Pinkfairie, port by R3M, sigs by psychonic",
	description = "Adds Blood & Gore",
	version = VERSION,
	url = "http://www.econsole.de/"
}

//Initation:
public OnPluginStart()
{
	//Register:
	PrintToConsole(0, "[SM] Insurgency GoreMod by R3M loaded successfully!");

	//Events:
	HookEvent("player_hurt", EventDamage);
	HookEvent("player_death", EventDeath);

	//Server Variable:
	CreateConVar("ins_goremod_version", VERSION, NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
}

//Map Start:
public OnMapStart()
{
	//Gibs:
	PrecacheModel("models/gibs/hgibs.mdl", true);
	PrecacheModel("models/gibs/hgibs_rib.mdl", true);
	PrecacheModel("models/gibs/hgibs_spine.mdl", true);
	PrecacheModel("models/gibs/hgibs_scapula.mdl", true);

	//Load Signatures:
	GoreSignatures = LoadGameConfigFile("goremod.signatures");

	//Check:
	if(GoreSignatures == INVALID_HANDLE)
	{

		//Print:
		PrintToServer("ERROR: Missing goremod.signatures! Please install it into your gamedata folder!");
		LogError("ERROR: Missing goremod.signatures! Please install it into your gamedata folder!");

		//Unhook:
		UnhookEvent("player_hurt", EventDamage);
		UnhookEvent("player_death", EventDeath);
	}

	//Prepare Call (Blood Drips):
	StartPrepSDKCall(SDKCall_Static);
	PrepSDKCall_SetFromConf(GoreSignatures, SDKConf_Signature, "UTIL_BloodDrips");
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	BloodDrips = EndPrepSDKCall();

	//Prepare Call (Blood Spray):
	StartPrepSDKCall(SDKCall_Static);
	PrepSDKCall_SetFromConf(GoreSignatures, SDKConf_Signature, "UTIL_BloodSpray");
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	BloodSpray = EndPrepSDKCall();
}

//Map End:
public OnMapEnd()
{
	//Close:
	CloseHandle(GoreSignatures);
	CloseHandle(BloodDrips);
	CloseHandle(BloodSpray);
}

//Decal:
stock Decal(Client, Float:Direction[3])
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
    
		//Emit:
		AcceptEntityInput(Blood, "EmitBlood", Client);
	}

	//Detatch:
	RemoveEdict(Blood);
}

//Blood Drips:
stock Drip(Float:Origin[3], Float:Direction[3])
{
	//Send:
	SDKCall(BloodDrips, Origin, Direction, 247);
}

//Blood Spray:
stock Spray(Float:Origin[3], Float:Direction[3], Size, Flags)
{
	//Send:
	SDKCall(BloodSpray, Origin, Direction, 247, Size, Flags);
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
	decl Ent;
	decl Float:MaxEnts;

	//Initialize:
	Ent = CreateEntityByName("prop_physics");
	MaxEnts = (0.9 * GetMaxEntities());
		
	//Anti-Crash:
	if(Ent < MaxEnts)
	{
		//Properties:
		DispatchKeyValue(Ent, "model", Model);
		SetEntProp(Ent, Prop_Send, "m_CollisionGroup", 1); 

		//Spawn:
		DispatchSpawn(Ent);
		
		//Send:
		TeleportEntity(Ent, Origin, Direction, Direction);

		//Delete:
		CreateTimer(GetRandomFloat(15.0, 30.0), RemoveGib, Ent);
	}
}


//Random Gib:
stock RandomGib(Float:Origin[3], String:Model[])
{
	//Declare:
	decl Float:Direction[3];

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
			decl Float:Origin[3], Float:Direction[3];

			//Initialize:
			GetClientAbsOrigin(Client, Origin);
			Origin[2] += 35.0;
	
			//Initialize:
			Direction[0] = GetRandomFloat(-1.0, 1.0);
			Direction[1] = GetRandomFloat(-1.0, 1.0);
			Direction[2] = GetRandomFloat(0.0, 75.0);

			//Bleed:
			Spray(Origin, Direction, 5, 1);

			//Drips:
			Drip(Origin, Direction);

			//Decal:
			Direction[2] = -1.0;
			Decal(Client, Direction);
		}
	}
}

//Damage:
public EventDamage(Handle:Event, const String:Name[], bool:Broadcast)
{
	//Declare:
	decl Client, Roll;
	decl Float:Origin[3], Float:Direction[3];

	//Initialize:
	Client = GetClientOfUserId(GetEventInt(Event, "userid"));
	GetClientAbsOrigin(Client, Origin);
	Origin[2] += 35.0;
	
	if (GetEventInt(Event, "hitgroup") == 1)
	{
		// next death is headshot
		g_bNextDeathHeadshot[Client] = true;
	}

	//Stringy:
	Roll = GetRandomInt(1, 3);
	if(Roll == 1)
	{

		//Randomize:
		Direction[0] = GetRandomFloat(-1.0, 1.0);
		Direction[1] = GetRandomFloat(-1.0, 1.0);
		Direction[2] = GetRandomFloat(0.0, 75.0);

		//Send:
		Spray(Origin, Direction, 10, 1);
	}

	//Drips:
	Roll = GetRandomInt(1, 3);
	if(Roll == 1)
	{

		//Randomize:
		Direction[0] = GetRandomFloat(-1.0, 1.0);
		Direction[1] = GetRandomFloat(-1.0, 1.0);
		Direction[2] = GetRandomFloat(0.0, 75.0);

		//Send:
		Drip(Origin, Direction);
	}	

	//Gib:
	Roll = GetRandomInt(1, 5);
	if(Roll == 1)
	{
	
		//Initialize:
		Roll = GetRandomInt(1, 3);

		//Find:
		if(Roll == 1) RandomGib(Origin, "models/gibs/hgibs_rib.mdl");
		if(Roll == 2) RandomGib(Origin, "models/gibs/hgibs_spine.mdl");
		if(Roll == 3) RandomGib(Origin, "models/gibs/hgibs_scapula.mdl");
	}
}	

//Death:
public EventDeath(Handle:Event, const String:Name[], bool:Broadcast)
{
	//Declare:
	decl Client, Attacker;
	decl String:Weapon[64];

	//Initialize:
	Client = GetClientOfUserId(GetEventInt(Event, "userid"));
	Attacker = GetClientOfUserId(GetEventInt(Event, "attacker"));
	GetEventString(Event, "weapon", Weapon, sizeof(Weapon));

	//Weapons:
	for(new X = 0; X < 2; X++)
	{

		//Check:
		if(StrContains(Weapon, CSWeapon[X], false) != -1)
		{

			//Fake Attacker:
			Attacker = 0;
		}
	}

	//Legit Attacker:
	if(Attacker != 0 && Attacker != Client)
	{
		//Headshot:
		if(g_bNextDeathHeadshot[Client])
		{
			//Declare:
			decl Float:Origin[3], Float:AttackerOrigin[3], Float:Direction[3], Float:RandomOrigin[3];

			//Origin:
			new Float:BlankVector[3];
			GetClientAbsOrigin(Client, Origin);
			GetClientAbsOrigin(Attacker, AttackerOrigin);

			//Direction:
			CalculateDirection(Origin, AttackerOrigin, Direction);
			Direction[2] = GetRandomFloat(150.0, 200.0);
			
			//Skull:
			Gib(Origin, Direction, "models/gibs/hgibs.mdl");

			//Puff:
			Spray(Origin, BlankVector, 10, 4);

			//Spray:
			for(new X = 0; X < 3; X++)
			{

				//Copy:
				RandomOrigin = Origin;

				//Randomize:
				RandomOrigin[0] += GetRandomFloat(-15.0, 15.0);
				RandomOrigin[1] += GetRandomFloat(-15.0, 15.0);
				RandomOrigin[2] += GetRandomFloat(-30.0, 10.0);

				//Send:
				Spray(RandomOrigin, BlankVector, 10, 1);
			}
			
			//Decals:
			for(new X = 0; X < 20; X++)
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
	else
	{
		//Declare:
		decl Float:Origin[3], Float:RandomOrigin[3];

		//Origin:
		new Float:BlankVector[3];
		GetClientAbsOrigin(Client, Origin);
			
		//Skull:
		RandomGib(Origin, "models/gibs/hgibs.mdl");
		RandomGib(Origin, "models/gibs/hgibs_rib.mdl");
		RandomGib(Origin, "models/gibs/hgibs_spine.mdl");
		RandomGib(Origin, "models/gibs/hgibs_scapula.mdl");

		//Puff:
		Spray(Origin, BlankVector, 10, 4);
		
		//Puff:
		for(new X = 0; X < 5; X++)
		{
			//Copy:
			RandomOrigin = Origin;

			//Randomize:
			RandomOrigin[0] += GetRandomFloat(-30.0, 30.0);
			RandomOrigin[1] += GetRandomFloat(-30.0, 30.0);
			RandomOrigin[2] += GetRandomFloat(-60.0, 30.0);

			//Write:
			Spray(RandomOrigin, BlankVector, 10, 4);
		}
	}

	g_bNextDeathHeadshot[Client] = false;
}

//Pre-Think:
public OnGameFrame()
{
	//Think Overflow:
	if (PrethinkBuffer > (GetGameTime() - 5))
	{
		return;
	}
	
	//Refresh:
	PrethinkBuffer = GetGameTime();

	//Loop:
	for(new Client = 1; Client <= MaxClients; Client++)
	{
		//Connected:
		if (!IsClientInGame(Client) || IsPlayerAlive(Client) || GetClientHealth(Client) >= 100)
		{
			continue;
		}
		
		//Bleed:
		CreateTimer(GetRandomFloat(0.0, 5.0), Bleed, Client);
	}
}