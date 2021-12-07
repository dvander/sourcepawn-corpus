#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#tryinclude <lastrequest>
#tryinclude <cssthrowingknives>

#pragma semicolon 1


#if defined _cssthrowingknives_included_

new bool:lanzando[MAXPLAYERS+1] = {false, ...};

#endif


#define EXPLODE_SOUND	"physics/glass/glass_bottle_impact_hard3.wav"
#define EXPLODE_SOUND2	"ambient/fire/mtov_flame2.wav"

public Plugin:myinfo =
{
	name = "SM CSS Molotov Cocktails",
	author = "Franc1sco steam: franug",
	description = "Use a molotov cocktails",
	version = "b1.1",
	url = "http://servers-cfg.foroactivo.com/"
};

public OnPluginStart()
{
	CreateConVar("sm_cssmolotov_version", "b1.1", _, FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	

}

public OnConfigsExecuted()
{
	PrecacheModel("models/props_junk/garbage_glassbottle003a.mdl");
	PrecacheSound(EXPLODE_SOUND, true);
	PrecacheSound(EXPLODE_SOUND2, true);
}


public OnEntityCreated(entity, const String:classname[])
{
	if (!strcmp(classname, "flashbang_projectile"))
	{
		SDKHook(entity, SDKHook_SpawnPost, ProjectileSpawned);
	}
}



public ProjectileSpawned(entity)
{

	new client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");

#if defined _cssthrowingknives_included_

	if(lanzando[client])
		return;

#endif


#if defined _LastRequest_Included_

	if(IsClientInLastRequest(client))
		return;

#endif





	decl Float:origin2[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origin2);
	SetEntityModel(entity, "models/props_junk/garbage_glassbottle003a.mdl");
	EmitAmbientSound( EXPLODE_SOUND2, origin2, entity, SNDLEVEL_NORMAL );
	IgniteEntity(entity, 1.2);
	CreateTimer(1.3, Creando, entity, TIMER_FLAG_NO_MAPCHANGE);


}

public Action:Creando(Handle:timer, any:entity)
{
	if (!IsValidEdict(entity))
	{
		return Plugin_Stop;
	}
		
	decl String:g_szClassname[64];
	GetEdictClassname(entity, g_szClassname, sizeof(g_szClassname));
	if (!strcmp(g_szClassname, "flashbang_projectile", false))
	{
		decl Float:origin[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origin);
		//origin[2] += 50.0;
		Fuego(origin);
		AcceptEntityInput(entity, "kill");
	}
	
	return Plugin_Stop;
}

Fuego(Float:pos[3])   
{
	    new fire = CreateEntityByName("env_fire");
            DispatchKeyValue(fire, "firesize", "220");
            //DispatchKeyValue(fire, "fireattack", "5");
            DispatchKeyValue(fire, "health", "5");
            DispatchKeyValue(fire, "firetype", "Normal");
            DispatchKeyValueFloat(fire, "damagescale", 0.0);
            DispatchKeyValue(fire, "spawnflags", "256");  //Used to controll flags
	    SetVariantString("WaterSurfaceExplosion");
	    AcceptEntityInput(fire, "DispatchEffect"); 
            DispatchSpawn(fire);
            TeleportEntity(fire, pos, NULL_VECTOR, NULL_VECTOR);
            AcceptEntityInput(fire, "StartFire");
	    EmitAmbientSound( EXPLODE_SOUND, pos, fire, SNDLEVEL_NORMAL );
	    
	
}

public OnClientPutInServer(client)
{
   SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{

	decl String:arma[64];
	GetEdictClassname(inflictor, arma, sizeof(arma));
	//PrintToChatAll("%s",arma);
	if (!strcmp(arma, "env_fire", false))
	{
		IgniteEntity(victim, 4.0);
	}
	return Plugin_Continue;
}


#if defined _cssthrowingknives_included_

public Action:OnKnifeThrow(client)
{
    	lanzando[client] = true;
	CreateTimer(0.5, Pasado, client);
}

public Action:Pasado(Handle:timer, any:client)
{
 if (IsClientInGame(client))
 {
   lanzando[client] = false;
 }
}

#endif

