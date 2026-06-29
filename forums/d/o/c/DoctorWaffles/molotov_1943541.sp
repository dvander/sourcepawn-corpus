#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#undef REQUIRE_PLUGIN

/* delete "//" and recompile if you use hosties */
#include <hosties>
#include <lastrequest>


#include <cssthrowingknives>
#define REQUIRE_PLUGIN


#if defined _cssthrowingknives_included_

new bool:lanzando[MAXPLAYERS+1] = {false, ...};

#endif


#define EXPLODE_SOUND	"physics/glass/glass_bottle_impact_hard3.wav"
#define EXPLODE_SOUND2	"ambient/fire/mtov_flame2.wav"

new Handle:cvar_ignite = INVALID_HANDLE;
new Handle:cvar_ignite_time = INVALID_HANDLE;
new Handle:cvar_damage = INVALID_HANDLE;
new Handle:cvar_ff = INVALID_HANDLE;
new Handle:cvar_amount = INVALID_HANDLE;
new Handle:cvar_msg = INVALID_HANDLE;


new Handle:hBuyZone = INVALID_HANDLE;
new Handle:preciomolotov = INVALID_HANDLE;

new molotovnumero[MAXPLAYERS+1];

new Handle:g_CVarAdmFlag;
new g_AdmFlag;


public Plugin:myinfo =
{
	name = "SM CSS Molotov Cocktails",
	author = "Franc1sco steam: franug",
	description = "Use a molotov cocktails",
	version = "v2.1",
	url = "http://servers-cfg.foroactivo.com/"
};

public OnPluginStart()
{
	CreateConVar("sm_cssmolotov_version", "v2.1", _, FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	cvar_ignite = CreateConVar("sm_cssmolotov_ignite", "1", "Enable/Disable ignite player");

	cvar_ignite_time = CreateConVar("sm_cssmolotov_ignite_time", "4.0", "Time in seconds for ignite player (require sm_cssmolotov_ignite enable)");

	cvar_damage = CreateConVar("sm_cssmolotov_damage", "0.0", "Fire damage on touch, per second (0.0 = no damage)");

	cvar_ff = CreateConVar("sm_cssmolotov_ff", "0", "Enable/Disable friendly fire");

	cvar_msg = CreateConVar("sm_cssmolotov_msg", "1", "Enable/Disable message of number of molotov that you have");

	cvar_amount = CreateConVar("sm_cssmolotov_amount", "1", "Amount of molotov in spawn (required a flashbang for make a molotov)");

	hBuyZone = CreateConVar("sm_cssmolotov_buyzone", "0", "1 players can only buy while in buyzone, 0 players can buy anywhere");

	preciomolotov = CreateConVar("sm_cssmolotov_price", "0", "Price to buy a molotov, 0 for free");



	HookEvent("player_spawn", Event_PlayerSpawn);

	RegConsoleCmd("sm_koopmolotov", Comprar);

	g_CVarAdmFlag = CreateConVar("sm_cssmolotov_adminflag", "0", "Admin flag required to use molotov. 0 = No flag needed. Can use a b c ....");

	HookConVarChange(g_CVarAdmFlag, CVarChange);
	

}

public CVarChange(Handle:convar, const String:oldValue[], const String:newValue[]) {

	g_AdmFlag = ReadFlagString(newValue);
}

public OnConfigsExecuted()
{
	PrecacheModel("models/props_junk/garbage_glassbottle003a.mdl");
	PrecacheSound(EXPLODE_SOUND, true);
	PrecacheSound(EXPLODE_SOUND2, true);
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	molotovnumero[client] = GetConVarInt(cvar_amount);
}

public Action:Comprar(client, argc)
{

		if(client == 0)
			return Plugin_Continue;

		if ((g_AdmFlag > 0) && !CheckCommandAccess(client, "sm_koopmolotov", g_AdmFlag, true))		
        	{
			PrintToChat(client, "\x03[DIMENSION]\x01 Deze functie is enkel beschikbaar voor donaters.");
			return Plugin_Handled;
		}



		if ((!GetEntProp(client, Prop_Send, "m_bInBuyZone")) && GetConVarInt(hBuyZone) != 0)
		{
			PrintToChat(client, "\x03[DIMENSION]\x01 You aren't in a buyzone");
			return Plugin_Handled;
		}
		else
		{
			new dinero = GetEntProp(client, Prop_Send, "m_iAccount");
			new preciomolotov2 = GetConVarInt(preciomolotov);
			
			if (dinero < preciomolotov2)
			{
				PrintToChat(client, "\x03[DIMENSION]\x01 Je hebt niet genoeg geld om een molotov te kopen.", preciomolotov2);
			}
			else
			{
				if(preciomolotov2 != 0)
				{
					dinero -= preciomolotov2;
					SetEntProp(client, Prop_Send, "m_iAccount", dinero);
				}
				molotovnumero[client]++;

				if(GetConVarInt(cvar_msg) != 0)
					PrintToChat(client, "\x04[[DIMENSION]]\x05 Molotov left = %i", molotovnumero[client]);
				
				GivePlayerItem(client, "weapon_flashbang");
			}
		}
		return Plugin_Handled;
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

	if(0 >= molotovnumero[client])
		return;

	molotovnumero[client]--;
	decl Float:origin2[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origin2);
	SetEntityModel(entity, "models/props_junk/garbage_glassbottle003a.mdl");
	EmitAmbientSound( EXPLODE_SOUND2, origin2, entity, SNDLEVEL_NORMAL );
	IgniteEntity(entity, 1.2);
	CreateTimer(1.3, Creando, entity, TIMER_FLAG_NO_MAPCHANGE);

	if(GetConVarInt(cvar_msg) != 0)
		PrintToChat(client, "\x04[SM_CSSMolotov]\x05 Molotov left = %i", molotovnumero[client]);


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

		new client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
		Fuego(origin, client);
		AcceptEntityInput(entity, "kill");
	}
	
	return Plugin_Stop;
}

Fuego(Float:pos[3], client)   
{
	    new fire = CreateEntityByName("env_fire");

	    SetEntPropEnt(fire, Prop_Send, "m_hOwnerEntity", client);
            DispatchKeyValue(fire, "firesize", "220");
            //DispatchKeyValue(fire, "fireattack", "5");
            DispatchKeyValue(fire, "health", "5");
            DispatchKeyValue(fire, "firetype", "Normal");

            DispatchKeyValueFloat(fire, "damagescale", GetConVarFloat(cvar_damage));
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
		new client = GetEntPropEnt(inflictor, Prop_Send, "m_hOwnerEntity");
		if(!IsValidClient(client))
			return Plugin_Continue;


		if(GetConVarInt(cvar_ff) != 0)
		{
				
			if(GetClientTeam(client) == GetClientTeam(victim))
				return Plugin_Handled;
		}

		if(GetConVarInt(cvar_ignite) != 1)
			return Plugin_Continue;
		

		IgniteEntity(victim, GetConVarFloat(cvar_ignite_time));
	}
	return Plugin_Continue;
	
}

public IsValidClient( client ) 
{ 
    if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) ) 
        return false; 
     
    return true; 
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

