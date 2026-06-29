public Plugin:myinfo =
{
	name = "CS:GO Goremod",
	author = "Joe 'DiscoBBQ' Maley, Mr. EMINEM (Alien version)",
	description = "Enhances Alien Green Blood and Gore",
	version = "1.3.1",
	url = "jmaley@clemson.edu"
}

#include <sourcemod>
#include <sdktools>

new bloodDecal[13];
new Float:overflow[MAXPLAYERS + 1];

ChanceParticle(client, chance, String:particleName[], bool:dead = false, bool:headshot = false)
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

		CreateTimer(1.0, DeleteParticle, particle);
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

GoreDecal(client, count)
{
	new decal;
	new Float:origin[3];
	
	GetClientAbsOrigin(client, origin);
	
	for (new i = 0; i < count; i++)
	{
		origin[0] += GetRandomFloat(-50.0, 50.0);
		origin[1] += GetRandomFloat(-50.0, 50.0);
	
		if (GetRandomInt(1, 20) == 20)
			decal = GetRandomInt(2, 4);
		else
			decal = GetRandomInt(5, 12);
	
		TE_Start("World Decal");
		TE_WriteVector("m_vecOrigin", origin);
		TE_WriteNum("m_nIndex", bloodDecal[decal]);
		TE_SendToAll();
	}
}

public EventDamage(Handle:event, const String:name[], bool:broadcast)
{
	new client, damage, health;
	
	client = GetClientOfUserId(GetEventInt(event, "userid"));
	damage = GetEventInt(event, "dmg_health");
	health = GetEventInt(event, "health");
	
	if (overflow[client] > GetGameTime() - 0.1)
		return;
	
	overflow[client] = GetGameTime();
	
	for (new i = 0; i < 3; i++)
	{
		ChanceParticle(client, damage, "blood_impact_red_01_backspray");
		ChanceParticle(client, damage, "blood_impact_drops1");
		ChanceParticle(client, damage, "blood_impact_red_01_drops");
	}

	ChanceParticle(client, damage, "blood_impact_red_01_goop_c");
	ChanceParticle(client, damage, "blood_impact_goop_medium");
	ChanceParticle(client, damage, "blood_impact_red_01_goop_b");
	ChanceParticle(client, damage, "blood_impact_red_01_goop_a");
	ChanceParticle(client, damage, "blood_impact_medium");
	ChanceParticle(client, damage, "blood_impact_basic");
	
	if (health > 0)
		GoreDecal(client, (damage / 20));
	else
		GoreDecal(client, 30);
}	

public EventDeath(Handle:event, const String:name[], bool:broadcast)
{
	new client;
	new bool:headshot;
	
	client = GetClientOfUserId(GetEventInt(event, "userid"));
	headshot = GetEventBool(event, "headshot");

	ChanceParticle(client, 75, "blood_impact_heavy", true);
	ChanceParticle(client, 75, "blood_impact_goop_heavy", true);
	ChanceParticle(client, 75, "blood_impact_mist_heavy", true);
		
	if (headshot)
	{
		ChanceParticle(client, 100, "blood_impact_headshot_01c", true, true);
		ChanceParticle(client, 100, "blood_impact_red_01_chunk", true, true);
		ChanceParticle(client, 100, "blood_impact_headshot_01b", true, true);
		ChanceParticle(client, 100, "blood_impact_headshot_01d", true, true);
	}
	else
	{
		ChanceParticle(client, 50, "blood_impact_red_01_goop_c");
		ChanceParticle(client, 50, "blood_impact_goop_medium");
		ChanceParticle(client, 50, "blood_impact_red_01_goop_b");
		ChanceParticle(client, 50, "blood_impact_red_01_goop_a");
		ChanceParticle(client, 50, "blood_impact_medium");
		ChanceParticle(client, 50, "blood_impact_basic");
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
		
		CreateTimer(1.0, DeleteParticle, particle, TIMER_FLAG_NO_MAPCHANGE);
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
	
	bloodDecal[0] = PrecacheDecal("decals/alien/blood_splatter.vtf");
	bloodDecal[1] = PrecacheDecal("decals/alien/bloodstain_003.vtf");
	bloodDecal[2] = PrecacheDecal("decals/alien/bloodstain_101.vtf");
	bloodDecal[3] = PrecacheDecal("decals/alien/bloodstain_002.vtf");
	bloodDecal[4] = PrecacheDecal("decals/alien/bloodstain_001.vtf");
	bloodDecal[5] = PrecacheDecal("decals/alien/blood8.vtf");
	bloodDecal[6] = PrecacheDecal("decals/alien/blood7.vtf");
	bloodDecal[7] = PrecacheDecal("decals/alien/blood6.vtf");
	bloodDecal[8] = PrecacheDecal("decals/alien/blood5.vtf");
	bloodDecal[9] = PrecacheDecal("decals/alien/blood4.vtf");
	bloodDecal[10] = PrecacheDecal("decals/alien/blood3.vtf");
	bloodDecal[11] = PrecacheDecal("decals/alien/blood2.vtf");
	bloodDecal[12] = PrecacheDecal("decals/alien/blood1.vtf");
	
	for (new i = 1; i < MaxClients; i++)
		overflow[i] = 0.0;
}

public OnPluginStart()
{
	HookEvent("player_hurt", EventDamage);
	HookEvent("player_death", EventDeath);
	
	CreateConVar("csgogore_version", "1.3", "Goremod Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
}