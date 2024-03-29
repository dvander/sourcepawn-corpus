//TF2 Gore v2.0 by Joe 'Pinkfairie' Maley:                                                                                                                                           //TF2 Gore v1.0 by Joe 'Pinkfairie' Maley:

//Terminate:
#pragma semicolon 1

//Includes:
#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

//Global:
static Health[33];
static Float:PrethinkBuffer;

//Weapons:
static String:GibWeapons[6][32] = {"sniper", "knife", "shotgun", "scattergun", "minigun", "flame"};
static String:MeleeWeapons[8][32] = {"club", "bat", "shovel", "axe", "bottle", "fists", "wrench", "bonesaw"};

//Write:
WriteParticle(Ent, String:ParticleName[])
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
		Angles[1] = GetRandomFloat(0.0, 15.0);
		Angles[2] = GetRandomFloat(0.0, 15.0);

		//Origin:
        	GetEntPropVector(Ent, Prop_Send, "m_vecOrigin", Position);
		Position[2] += GetRandomFloat(35.0, 65.0);
        	TeleportEntity(Particle, Position, Angles, NULL_VECTOR);

		//Properties:
		GetEntPropString(Ent, Prop_Data, "m_iName", tName, sizeof(tName));
		DispatchKeyValue(Particle, "targetname", "TF2Particle");
		DispatchKeyValue(Particle, "parentname", tName);
		DispatchKeyValue(Particle, "effect_name", ParticleName);

		//Spawn:
		DispatchSpawn(Particle);
	
		//Parent:		
		SetVariantString(tName);
		AcceptEntityInput(Particle, "SetParent", -1, -1, 0);
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

//Bleed:
public Action:Bleed(Handle:Timer, any:Client)
{

	//Bleed:
	WriteParticle(Client, "blood_spray_red_01_far");
	WriteParticle(Client, "blood_impact_red_01");
}

//Spawn:
public Action:player_spawn(Handle:event, const String:Name[], bool:Broadcast)
{

	//Declare:
	//decl Client;

	//Initialize:
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!client || !IsClientInGame(client)) return;
	//Save HP:
	CreateTimer(0.1, UpdateHealth, client);
}

//Update Health:
public Action:UpdateHealth(Handle:Timer, any:client)
{
    if (!client || !IsClientInGame(client)) return;
	//Save:
    Health[client] = GetClientHealth(client);
}

//Damage:
public Action:player_hurt(Handle:event, const String:Name[], bool:Broadcast)
{

	//Declare:
	//decl Attacker;

	//Initialize:
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	//World:
	if(attacker != 0 && attacker != client)
	{

		//In-Game:
		if(IsClientInGame(client) && IsClientInGame(attacker))
		{

			//Declare:
			decl String:WeaponName[64];

			//Initialize:
			GetClientWeapon(attacker, WeaponName, sizeof(WeaponName));

			//Loop:
			for(new X = 0; X < 8; X++)
			{

				//Compare:
				if(StrContains(WeaponName, MeleeWeapons[X], false) != -1)
				{

					//Write:
					WriteParticle(client, "blood_impact_red_01_chunk");
				}
			}
		}
	}
}

//Death:
public Action:player_death(Handle:event, const String:Name[], bool:Broadcast)
{
	
	//Declare:
	//decl Client, Attacker;
	decl Float:ClientOrigin[3];

	//Initialize:
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	GetClientAbsOrigin(client, ClientOrigin);

	//World:
	if(attacker != 0 && attacker != client)
	{

		//In-Game:
		if(IsClientInGame(client) && IsClientInGame(attacker))
		{

			//Declare:
			decl String:WeaponName[64];

			//Initialize:
			GetClientWeapon(attacker, WeaponName, sizeof(WeaponName));

			//Loop:
			for(new X = 0; X < 6; X++)
			{

				//Compare:
				if(StrContains(WeaponName, GibWeapons[X], false) != -1)
				{
	
					//Declare:
					decl Ent;
 
					//Initialize:
					Ent = CreateEntityByName("tf_ragdoll");
 
					//Write:
					SetEntPropVector(Ent, Prop_Send, "m_vecRagdollOrigin", ClientOrigin); 
					SetEntProp(Ent, Prop_Send, "m_iPlayerIndex", client); 
					SetEntPropVector(Ent, Prop_Send, "m_vecForce", NULL_VECTOR);
					SetEntPropVector(Ent, Prop_Send, "m_vecRagdollVelocity", NULL_VECTOR);
					SetEntProp(Ent, Prop_Send, "m_bGib", 1);
 
					//Send:
					DispatchSpawn(Ent);

					//Remove Body:
					CreateTimer(0.1, RemoveBody, client);
					CreateTimer(15.0, RemoveGibs, Ent);
				}
			}
		}
	}
}

//Remove Body:
public Action:RemoveBody(Handle:Timer, any:client)
{

	//Declare:
	decl BodyRagdoll;

	//Initialize:
	BodyRagdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");

	//Remove:
	if(IsValidEdict(BodyRagdoll)) RemoveEdict(BodyRagdoll);
}

//Remove Gibs:
public Action:RemoveGibs(Handle:Timer, any:Ent)
{

	//Validate:
	if(IsValidEntity(Ent))
	{

		//Declare:
		decl String:Classname[64];

		//Initialize:
		GetEdictClassname(Ent, Classname, sizeof(Classname));

		//Is a Particle:
		if(StrEqual(Classname, "tf_ragdoll", false))
		{

			//Delete:
			RemoveEdict(Ent);
		}
	}
}

//Pre-Think:
public OnGameFrame()
{

	//Think Overflow:
	if(PrethinkBuffer <= (GetGameTime() - 10))
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

					//Declare:
					decl HP;

					//Initialize:
					HP = GetClientHealth(Client);

					//Bleed:
					if(HP < Health[Client]) CreateTimer(GetRandomFloat(0.0, 10.0), Bleed, Client);
				}
			}
		}
	}
}

//Information:
public Plugin:myinfo =
{

	//Initialize:
	name = "TF2 Goremod",
	author = "Joe 'Pinkfairie' Maley",
	description = "Adds Blood & Gore",
	version = "2.0",
	url = "hiimjoemaley@hotmail.com"
}

//Initation:
public OnPluginStart()
{

	//Register:
	PrintToConsole(0, "[SM] TF2 Gore v2.0 by Pinkfairie loaded successfully!");

	//Events:
	HookEvent("player_hurt", player_hurt);
	HookEvent("player_death", player_death);
	HookEvent("player_spawn", player_spawn);

	//Server Variable:
	CreateConVar("tf2gore_version", "2.0", "TF2 Gore Version", 0|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
}