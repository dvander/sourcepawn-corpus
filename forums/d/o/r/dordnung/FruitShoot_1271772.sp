/*

Name: FruitShoot
Version: 1.1
Author: Popoklopsi

*/

/* Includes */

#include <sourcemod>
#include <sdktools>

/* Use Semi Colon */

#pragma semicolon 1

/* Global Handles */

new Handle:Fruits[501];

new Handle:cvar_LifeTime;
new Handle:cvar_MaxFruits;
new Handle:cvar_ModelID;
new Handle:cvar_Chance;
new Handle:cvar_ChanceType;

/* Global Strings */

new String:ModelName[35];

/* Global Ints */

new Bullets[MAXPLAYERS + 1];
new FruitList[501];

new LifeTime;
new MaxFruits;
new ModelID;
new Chance;
new ChanceType;
new FruitCount;

/* SM Standard Blocks */

public Plugin:myinfo =
{
	name = "FruitShoot",
	author = "Popoklopsi",
	version = "1.1",
	description = "Shoot with Fruits",
	url = "http://pup-board.de"
};

public OnPluginStart()
{
	for (new i=0; i <= MaxFruits; i++) FruitList[i] = 0;
	
	FruitCount = 0;

	CreateConVar("fruit_shoot", "1.1", "FruitShoot Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	cvar_LifeTime = CreateConVar("fruit_LifeTime", "20", "How long should the fruits live (0 = Until next Round)");
	cvar_MaxFruits = CreateConVar("fruit_MaxFruits", "100", "Max. number of fruits in the world (Max. 500, because of laags)");
	cvar_ModelID = CreateConVar("fruit_Model", "4", "1 = Orange, 2 = Banana, 3 = Watermelon, 4 = Random");
	cvar_ChanceType = CreateConVar("fruit_ChanceType", "30", "Chance type 1 = Procent 2 = Bullets");
	cvar_Chance = CreateConVar("fruit_Chance", "30", "Chance to shoot with a fruit (Procent or Bullets)");
	
	HookConVarChange(cvar_LifeTime, OnConVarChanged);
	HookConVarChange(cvar_MaxFruits, OnConVarChanged);
	HookConVarChange(cvar_ModelID, OnConVarChanged);
	HookConVarChange(cvar_Chance, OnConVarChanged);
	HookConVarChange(cvar_ChanceType, OnConVarChanged);
	
	AutoExecConfig(true, "FruitShoot_config");
	
	HookEvent("bullet_impact", BulletImpact);
	HookEvent("round_start", RoundStart);
}

public OnConfigsExecuted()
{
	LifeTime = GetConVarInt(cvar_LifeTime);
	MaxFruits = GetConVarInt(cvar_MaxFruits);
	ModelID = GetConVarInt(cvar_ModelID);
	Chance = GetConVarInt(cvar_Chance);
	ChanceType = GetConVarInt(cvar_ChanceType);
	
	if (ModelID == 1) Format(ModelName, sizeof(ModelName), "models/props/cs_italy/orange.mdl");
	if (ModelID == 2) Format(ModelName, sizeof(ModelName), "models/props/cs_italy/bananna.mdl");
	if (ModelID == 3) Format(ModelName, sizeof(ModelName), "models/props_junk/watermelon01.mdl");
}

public OnConVarChanged(Handle:hCvar, const String:oldValue[], const String:newValue[])
{
	if (hCvar == cvar_LifeTime) LifeTime = StringToInt(newValue);
	
	if (hCvar == cvar_Chance) Chance = StringToInt(newValue);
	
	if (hCvar == cvar_ChanceType) ChanceType = StringToInt(newValue);
	
	if (hCvar == cvar_ModelID)
	{
		ModelID = StringToInt(newValue);
		
		if (ModelID == 1) Format(ModelName, sizeof(ModelName), "models/props/cs_italy/orange.mdl");
		if (ModelID == 2) Format(ModelName, sizeof(ModelName), "models/props/cs_italy/bananna.mdl");
		if (ModelID == 3) Format(ModelName, sizeof(ModelName), "models/props_junk/watermelon01.mdl");
	}
	
	if (hCvar == cvar_MaxFruits)
	{
		MaxFruits = StringToInt(newValue);
		DeleteAllFruits();
	}
}

public OnClientPostAdminCheck(client)
{
	Bullets[client] = 0;
}

/* Event Handler */

public RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i=0; i <= MaxFruits; i++) 
	{
		FruitList[i] = 0;
		Fruits[i] = INVALID_HANDLE;
	}
	
	FruitCount = 0;
}

public BulletImpact(Handle:event, const String:name[], bool:dontBroadcast)
{
	new PropEnt;
	new bool:ShootWith = true;
	new client;
	
	if (ChanceType == 1 && Chance < 100)
	{
		new ChanceInt = GetRandomInt(1, 100);
		
		if (ChanceInt > Chance) ShootWith = false;
	}
	
	if (ChanceType == 2)
	{
		if (Bullets[client] < Chance) 
		{
			ShootWith = false;
		}
		else
		{
			Bullets[client] = 0;
		}
		
		Bullets[client]++;
	}
	
	if (ShootWith)
	{
		decl Float:eye[3], Float:Pos[3], Float:ang[3], Float:ang2[3], Float:speed, Float:velocity[3];
		
		client = GetClientOfUserId(GetEventInt(event, "userid"));
		
		Pos[0] = GetEventFloat(event, "x");
		Pos[1] = GetEventFloat(event, "y");
		Pos[2] = GetEventFloat(event, "z");
		
		PropEnt = CreateEntityByName("prop_physics");
		
		if (ModelID == 4) 
		{
			new ModelReplace = GetRandomInt(1, 3);
			
			if (ModelReplace == 1) Format(ModelName, sizeof(ModelName), "models/props/cs_italy/orange.mdl");
			if (ModelReplace == 2) Format(ModelName, sizeof(ModelName), "models/props/cs_italy/bananna.mdl");
			if (ModelReplace == 3) Format(ModelName, sizeof(ModelName), "models/props_junk/watermelon01.mdl");
		}
		
		DispatchKeyValue(PropEnt, "model", ModelName);
		DispatchKeyValue(PropEnt, "minhealthdmg", "5000000"); 
		DispatchKeyValue(PropEnt, "spawnflags", "1542");
		DispatchSpawn( PropEnt );
		
		if (FruitCount >= MaxFruits)
		{
			DeleteAllFruits();
		}
		
		FruitCount++;

		for (new i=0; i <= MaxFruits; i++) 
		{
			if (FruitList[i] == 0)
			{
				FruitList[i] = PropEnt;
				
				if (LifeTime > 0) Fruits[i] = CreateTimer(float(LifeTime), DeleteFruit, PropEnt);
				
				break;
			}
		}
		
		GetClientEyePosition(client, eye);
		GetClientEyeAngles(client, ang2);
		
		ang2[1] = ang2[1] - 90;
		eye[2] = eye[2] - 15;

		TeleportEntity(PropEnt, eye, ang2, NULL_VECTOR);
		
		speed = GetVectorDistance(Pos, eye, true);
		
		GetClientEyeAngles(client, ang);
		
		ang[0] *= -1.0;
		ang[0] = DegToRad(ang[0]);
		ang[1] = DegToRad(ang[1]);
		
		velocity[0] = speed * Cosine(ang[0]) * Cosine(ang[1]);
		velocity[1] = speed * Cosine(ang[0]) * Sine(ang[1]);
		velocity[2] = speed * Sine(ang[0]);
		
		TeleportEntity(PropEnt, NULL_VECTOR, NULL_VECTOR, velocity);
	}
}

/* Timer Handler */

public Action:DeleteFruit(Handle:timer, any:FruitIndex)
{
	if (IsValidEntity(FruitIndex)) 
	{
		RemoveEdict(FruitIndex);
		FruitCount--;
	}
	
	for (new i=0; i <= MaxFruits; i++) 
	{
		if (FruitList[i] == FruitIndex)
		{
			FruitList[i] = 0;
			Fruits[i] = INVALID_HANDLE;
			
			break;
		}
	}
}

/* Own Function */

DeleteAllFruits()
{
	FruitCount = 0;
	
	for (new i=0; i <= MaxFruits; i++) 
	{
		if (FruitList[i] != 0)
		{
			if (Fruits[i] != INVALID_HANDLE)
			{
				KillTimer(Fruits[i]);
			}
			
			RemoveEdict(FruitList[i]);
		}
		
		Fruits[i] = INVALID_HANDLE;
		FruitList[i] = 0;
	}
}