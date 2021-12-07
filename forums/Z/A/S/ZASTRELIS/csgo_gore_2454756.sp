public Plugin:myinfo =
{
	name = "CS:GO Goremod",
	author = "Joe 'DiscoBBQ' Maley",
	description = "Enhances Blood and Gore",
	version = "1.3",
	url = "jmaley@clemson.edu"
}

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

new bloodDecal[13];
new Float:overflow[MAXPLAYERS + 1];
int g_iParticleSystem[MAXPLAYERS + 1] = {INVALID_ENT_REFERENCE, ...};
Handle i_Timers[MAXPLAYERS + 1];

char bleeding_particle[][] = {
"blood_impact_basic",
"blood_impact_basic_fallback",
"blood_impact_light_headshot",
"blood_impact_goop_heavy"
};

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

		//origin[2] += GetRandomFloat(0.0, 5.0);

		TeleportEntity(particle, origin, NULL_VECTOR, NULL_VECTOR);

		Format(targetName, sizeof(targetName), "Client%d", client);
		DispatchKeyValue(client, "targetname", targetName);
		GetEntPropString(client, Prop_Data, "m_iName", targetName, sizeof(targetName));

		DispatchKeyValue(particle, "targetname", "CSGOParticle");
		//SetVariantString( "!activator" );
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
				
				SetVariantString( "!activator" );
				
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
		//origin[0] += GetRandomFloat(-25.0, 25.0);
		//origin[1] += GetRandomFloat(-25.0, 25.0);
	
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
	ForcePrecache("blood_impact_basic_fallback");
	ForcePrecache("blood_impact_light_headshot");
	ForcePrecache("blood_impact_goop_heavy");
	ForcePrecache("blood_impact_medium");
	ForcePrecache("blood_impact_red_01_goop_a");
	ForcePrecache("blood_impact_red_01_goop_b");
	ForcePrecache("blood_impact_goop_medium");
	ForcePrecache("blood_impact_red_01_goop_c");
	ForcePrecache("blood_impact_red_01_drops");
	ForcePrecache("blood_impact_drops1");
	ForcePrecache("blood_impact_red_01_backspray");
	
	bloodDecal[0] = PrecacheDecal("decals/blood_splatter.vtf");
	bloodDecal[1] = PrecacheDecal("decals/bloodstain_003.vtf");
	bloodDecal[2] = PrecacheDecal("decals/bloodstain_101.vtf");
	bloodDecal[3] = PrecacheDecal("decals/bloodstain_002.vtf");
	bloodDecal[4] = PrecacheDecal("decals/bloodstain_001.vtf");
	bloodDecal[5] = PrecacheDecal("decals/blood8.vtf");
	bloodDecal[6] = PrecacheDecal("decals/blood7.vtf");
	bloodDecal[7] = PrecacheDecal("decals/blood6.vtf");
	bloodDecal[8] = PrecacheDecal("decals/blood5.vtf");
	bloodDecal[9] = PrecacheDecal("decals/blood4.vtf");
	bloodDecal[10] = PrecacheDecal("decals/blood3.vtf");
	bloodDecal[11] = PrecacheDecal("decals/blood2.vtf");
	bloodDecal[12] = PrecacheDecal("decals/blood1.vtf");
	
	for (new i = 1; i < MaxClients; i++)
		overflow[i] = 0.0;
}

public Action LowHPDetector(Handle timer, any:data)
{
	int client=GetClientOfUserId(data);
	
	if(IsClientConnected(client))
	{
		if(!IsFakeClient(client))
		{
			if(IsValidEntity(client))
			{
				if(GetClientHealth(client)<=25)
					Create_Low_HP_Particle(client);

				//PrintToServer("TIMER HAS BEEN STARTED!");
			}
		}
	}
	
	if(i_Timers[client]!=INVALID_HANDLE)
	{
		KillTimer( i_Timers[client] );
		i_Timers[client]=INVALID_HANDLE;
	}
	
	i_Timers[client]=CreateTimer(2.5, LowHPDetector, GetClientUserId(client));
	
	return Plugin_Continue;
}

public OnPluginStart()
{
	for (int i = 0; i <= MAXPLAYERS; i++)
	{
		g_iParticleSystem[i] = INVALID_ENT_REFERENCE;
	}
	
	HookEvent("player_hurt", EventDamage, EventHookMode_Pre);
	HookEvent("player_death", EventDeath, EventHookMode_Pre);
	
	CreateConVar("csgogore_version", "1.5", "Goremod Version", FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	HookEvent( "player_death", Event_PlayerDeath, EventHookMode_Post );
}

public Create_Low_HP_Particle(int client)
{
	//PrintToServer("ATTEMT TIMER TO WORK!")
	if(!IsValidEntity(client))
		return 3;
	
	if(!IsClientConnected(client))
		return 3;	
	
	if(IsFakeClient(client))
		return 3;
		
	if(!IsPlayerAlive(client))
		return 3;
	
	
	//PrintToServer("%s", particle[ 0 ])
	int ent = EntRefToEntIndex(g_iParticleSystem[client]);
	
	if(ent && ent != INVALID_ENT_REFERENCE)
	{
		AcceptEntityInput(ent, "Stop");
		AcceptEntityInput(ent, "Kill");
	}
	
	ent = CreateEntityByName("info_particle_system");
	
	float particleOrigin[3];
	
	GetClientEyePosition(client, particleOrigin);
	
	int random_number = GetRandomInt(0,3);
	
	DispatchKeyValue(ent , "start_active", "0");
	DispatchKeyValue(ent, "effect_name", bleeding_particle[random_number]);
	DispatchSpawn(ent);
	
	TeleportEntity(ent , particleOrigin, NULL_VECTOR,NULL_VECTOR);
	
	
	SetVariantString("!activator");
	AcceptEntityInput(ent, "SetParent", client, ent, 0);
	
	ActivateEntity(ent);
	AcceptEntityInput(ent, "Start");
	
	g_iParticleSystem[client] = EntIndexToEntRef(ent);
	
	//PrintToChat(client, " \x04[CS:GO Particles] \x01Particle system created (\x03'%s'\x01)!", particle[random_number]);
	//PrintToServer("%s", particle[random_number]);
	
	return 1;
}

public OnClientPutInServer(client)
{
	if(i_Timers[client]!=INVALID_HANDLE)
	{
		KillTimer( i_Timers[client] );
		i_Timers[client]=INVALID_HANDLE;
	}
	
	SDKHook( client, SDKHook_SpawnPost, Hook_SpawnPost );
}

public void OnClientDisconnect(int client)
{
	if(IsValidEntity(g_iParticleSystem[client]))
		AcceptEntityInput(g_iParticleSystem[client], "Kill");
		
	g_iParticleSystem[client] = INVALID_ENT_REFERENCE;
	
	if(i_Timers[client]!=INVALID_HANDLE)
	{
		KillTimer( i_Timers[client] );
		i_Timers[client]=INVALID_HANDLE;
	}
	
	SDKUnhook( client, SDKHook_SpawnPost, Hook_SpawnPost );
}

public Hook_SpawnPost( client )
{
	if(i_Timers[client]!=INVALID_HANDLE)
	{
		KillTimer( i_Timers[client] );
		i_Timers[client]=INVALID_HANDLE;
	}
	
	i_Timers[client]=CreateTimer(2.5, LowHPDetector, GetClientUserId(client));
}

public Action Event_PlayerDeath( Handle event, const char[] name, bool dontBroadcast )
{
	int i_vicId = GetClientOfUserId( GetEventInt( event, "userid" ) );
	
	if(i_Timers[i_vicId]!=INVALID_HANDLE)
	{
		KillTimer( i_Timers[i_vicId] );
		i_Timers[i_vicId]=INVALID_HANDLE;
	}
}