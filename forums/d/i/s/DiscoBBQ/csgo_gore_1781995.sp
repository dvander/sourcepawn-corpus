// Title: CS:GO Goremod
// Author: Joe 'DiscoBBQ' Maley
// Version: 1.2

#include <sourcemod>
#include <sdktools>

new bloodSprite[13];
new Float:overflow[MAXPLAYERS + 1];

public Plugin:myinfo =
{
	name = "CS:GO Goremod",
	author = "Joe 'DiscoBBQ' Maley",
	description = "Enhances Blood and Gore",
	version = "1.2",
	url = "jmaley@clemson.edu"
}

CreateGoreParticle(client, chance, String:particleName[], bool:dead = false, bool:headshot = false)
{
	new roll;
	
	roll = GetRandomInt(1, 100);
	
	if (roll <= chance)
		CreateParticle(client, particleName, dead, headshot);
}

CreateParticle(client, String:particleName[], bool:dead, bool:headshot)
{
	new particle;
		
	particle = CreateEntityByName("info_particle_system");
	
	if (IsValidEdict(particle) && IsValidEdict(client))
	{	
		new Float:origin[3];
		new String:targetName[64];

		GetEntPropVector(client, Prop_Send, "m_vecOrigin", origin);

		origin[2] += GetRandomFloat(25.0, 75.0);

		TeleportEntity(particle, origin, NULL_VECTOR, NULL_VECTOR);

		Format(targetName, sizeof(targetName), "Client%d", client);
		DispatchKeyValue(client, "targetname", targetName);
		GetEntPropString(client, Prop_Data, "m_iName", targetName, sizeof(targetName));

		DispatchKeyValue(particle, "targetname", "CSGOParticle");
		DispatchKeyValue(particle, "parentname", targetName);
		DispatchKeyValue(particle, "effect_name", particleName);

		DispatchSpawn(particle);
		
		if(dead)
		{
			ParentToBody(client, particle, headshot);
		}
		else
		{
			SetVariantString(targetName);
			AcceptEntityInput(particle, "SetParent", particle, particle, 0);
		}

		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");

		CreateTimer(3.0, DeleteParticle, particle);
	}
}

public Action:DeleteParticle(Handle:Timer, any:particle)
{
	if (IsValidEdict(particle))
	{	
		new String:className[64];

		GetEdictClassname(particle, className, sizeof(className));

		if(StrEqual(className, "info_particle_system", false))
			RemoveEdict(particle);
	}
}

ParentToBody(client, particle, bool:headshot = false)
{
	if (IsValidEdict(client))
	{
		new body;
		new String:targetName[64], String:className[64];

		body = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
		
		if (IsValidEdict(body))
		{
			Format(targetName, sizeof(targetName), "Body%d", body);

			GetEdictClassname(body, className, sizeof(className));

			if (IsValidEdict(body) && StrEqual(className, "cs_ragdoll", false))
			{
				DispatchKeyValue(body, "targetname", targetName);
				GetEntPropString(body, Prop_Data, "m_iName", targetName, sizeof(targetName));
				
				SetVariantString(targetName);
				AcceptEntityInput(particle, "SetParent", particle, particle, 0);

				if (headshot)
					SetVariantString("forward");
				else	
					SetVariantString("primary");

				AcceptEntityInput(particle, "SetParentAttachment", particle, particle, 0);
			}
		}
	}
}

GoreDecal(client)
{
	new decal;
	new Float:dist, Float:angle;
	new Float:origin[3], Float:direction[3];
	
	dist = GetRandomFloat(0.0, 60.0);
	
	/*
	for (new i = 0; i < 3; i++)
	{
		GetClientAbsOrigin(client, origin);
		
		origin[0] += GetRandomFloat(-10.0, 10.0);
		origin[1] += GetRandomFloat(-10.0, 10.0);
		origin[2] += GetRandomFloat(15.0, 100.0);
		
		direction[0] = 0.0;
		direction[1] = GetRandomFloat(0.0, 360.0);
		direction[2] = 0.0;
		
		decal = GetRandomInt(2, 11);
		
		TE_Start("Projected Decal");
		TE_WriteVector("m_vecOrigin", origin);
		TE_WriteVector("m_angRotation", direction);
		TE_WriteFloat("m_flDistance", 75.0);
		TE_WriteNum("m_nIndex", bloodSprite[decal]);
		TE_SendToAll();
	}*/
	
	GetClientAbsOrigin(client, origin);
	
	angle = DegToRad(GetRandomFloat(0.0, 360.0));

	origin[0] += dist * Cosine(angle);
	origin[1] += dist * Sine(angle);
	
	decal = RoundToNearest(SquareRoot(GetRandomFloat(4.0, 144.0)));
	
	TE_Start("World Decal");
	TE_WriteVector("m_vecOrigin", origin);
	TE_WriteNum("m_nIndex", bloodSprite[decal]);
	TE_SendToAll();
}

public EventDamage(Handle:event, const String:name[], bool:broadcast)
{	
	new client, damage;
	
	client = GetClientOfUserId(GetEventInt(event, "userid"));
	damage = GetEventInt(event, "dmg_health");

	if (overflow[client] > GetGameTime() - 0.1)
		return;
	
	overflow[client] = GetGameTime();
	
	for (new i = 0; i < 4; i++)
	{
		CreateGoreParticle(client, damage, "blood_impact_red_01_backspray");
		CreateGoreParticle(client, damage, "blood_impact_drops1");
		CreateGoreParticle(client, damage, "blood_impact_red_01_drops");
	}

	CreateGoreParticle(client, damage, "blood_impact_red_01_goop_c");
	CreateGoreParticle(client, damage, "blood_impact_goop_medium");
	CreateGoreParticle(client, damage, "blood_impact_red_01_goop_b");
	CreateGoreParticle(client, damage, "blood_impact_red_01_goop_a");
	CreateGoreParticle(client, damage, "blood_impact_medium");
	CreateGoreParticle(client, damage, "blood_impact_basic");
		
	for (new i = 0; i < 1 + (damage / 3); i++)
		GoreDecal(client);
}	

public EventDeath(Handle:event, const String:name[], bool:broadcast)
{
	new client;
	new bool:headshot;
	
	client = GetClientOfUserId(GetEventInt(event, "userid"));
	headshot = GetEventBool(event, "headshot");

	for (new i = 0; i < 3; i++)
	{
		CreateGoreParticle(client, 33, "blood_impact_heavy", true);
		CreateGoreParticle(client, 33, "blood_impact_goop_heavy", true);
		CreateGoreParticle(client, 33, "blood_impact_mist_heavy", true);
	
		CreateGoreParticle(client, 33, "blood_impact_red_01_goop_c");
		CreateGoreParticle(client, 33, "blood_impact_goop_medium");
		CreateGoreParticle(client, 33, "blood_impact_red_01_goop_b");
		CreateGoreParticle(client, 33, "blood_impact_red_01_goop_a");
		CreateGoreParticle(client, 33, "blood_impact_medium");
		CreateGoreParticle(client, 33, "blood_impact_basic");
	}
		
	if (headshot)
	{
		CreateGoreParticle(client, 100, "blood_impact_headshot_01c", true, true);
		CreateGoreParticle(client, 100, "blood_impact_red_01_chunk", true, true);
		CreateGoreParticle(client, 100, "blood_impact_headshot_01b", true, true);
		CreateGoreParticle(client, 100, "blood_impact_headshot_01d", true, true);
	}
}

ForcePrecache(String:particleName[])
{
	new particle;

	particle = CreateEntityByName("info_particle_system");
	
	if(IsValidEdict(particle))
	{
		DispatchKeyValue(particle, "effect_name", particleName);
		
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		
		CreateTimer(0.3, DeleteParticle, particle, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public OnMapStart()
{
	ForcePrecache("blood_impact_heavy");
	ForcePrecache("blood_impact_goop_heavy");
	ForcePrecache("blood_impact_red_01_chunk");
	ForcePrecache("blood_impact_headshot_01c");
	ForcePrecache("blood_impact_headshot_01b");
	ForcePrecache("blood_impact_headshot_01d");
	ForcePrecache("blood_impact_basic");
	ForcePrecache("blood_impact_medium");
	ForcePrecache("blood_impact_red_01_goop_a");
	ForcePrecache("blood_impact_red_01_goop_b");
	ForcePrecache("blood_impact_goop_medium");
	ForcePrecache("blood_impact_red_01_goop_c");
	ForcePrecache("blood_impact_red_01_drops");
	ForcePrecache("blood_impact_drops1");
	ForcePrecache("blood_impact_red_01_backspray");
	
	bloodSprite[0] = PrecacheDecal("decals/blood_splatter.vtf");
	bloodSprite[1] = PrecacheDecal("decals/bloodstain_003.vtf");
	bloodSprite[2] = PrecacheDecal("decals/bloodstain_101.vtf");
	bloodSprite[3] = PrecacheDecal("decals/bloodstain_002.vtf");
	bloodSprite[4] = PrecacheDecal("decals/bloodstain_001.vtf");
	bloodSprite[5] = PrecacheDecal("decals/blood8.vtf");
	bloodSprite[6] = PrecacheDecal("decals/blood7.vtf");
	bloodSprite[7] = PrecacheDecal("decals/blood6.vtf");
	bloodSprite[8] = PrecacheDecal("decals/blood5.vtf");
	bloodSprite[9] = PrecacheDecal("decals/blood4.vtf");
	bloodSprite[10] = PrecacheDecal("decals/blood3.vtf");
	bloodSprite[11] = PrecacheDecal("decals/blood2.vtf");
	bloodSprite[12] = PrecacheDecal("decals/blood1.vtf");

	for (new i = 1; i < MaxClients; i++)
		overflow[i] = 0.0;
}

public OnPluginStart()
{
	HookEvent("player_hurt", EventDamage);
	HookEvent("player_death", EventDeath);
	
	CreateConVar("csgogore_version", "1.2", "Goremod Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
}