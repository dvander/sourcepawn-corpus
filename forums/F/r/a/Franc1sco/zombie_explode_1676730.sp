#include <sourcemod>
#include <sdktools>
#include <sdktools_sound>
#include <sdkhooks>
#include <zombiereloaded>

#pragma semicolon 1


#define DATA "1.0"

new bool:g_ZombieExplode[MAXPLAYERS+1] = {false, ...};



#define EXPLODE_SOUND	"ambient/explosions/explode_8.wav"

new g_ExplosionSprite;
new g_SmokeSprite;
new Float:iNormal[ 3 ] = { 0.0, 0.0, 1.0 };

public Plugin:myinfo =
{
    name = "SM Zombie Explode",
    author = "Franc1sco steam: franug",
    description = "Kill zombies with knife",
    version = DATA,
    url = "http://servers-cfg.foroactivo.com/"
};

public OnPluginStart()
{
    CreateConVar("sm_zombiexplode_version", DATA, "version", FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

    HookEvent("player_spawn", PlayerSpawn);

}

public OnConfigsExecuted()
{
	PrecacheSound(EXPLODE_SOUND, true);
	g_ExplosionSprite = PrecacheModel( "sprites/blueglow2.vmt" );
	g_SmokeSprite = PrecacheModel( "sprites/steam1.vmt" );
}

public OnClientPutInServer(client)
{
     SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:OnTakeDamage(client, &attacker, &inflictor, &Float:damage, &damagetype)
{
	
	if (!IsClientInGame(attacker))
		return;

	if (IsPlayerAlive(attacker) && ZR_IsClientHuman(attacker) && ZR_IsClientZombie(client))
	{
             decl String:sWeapon[32];
             GetEdictClassname(inflictor, sWeapon, sizeof(sWeapon));
    
             if(StrEqual(sWeapon, "weapon_knife"))
             {
                        g_ZombieExplode[client] = true;

                        CreateTimer(3.0, ByeZM, client);
             }

        }
}

public Action:ByeZM(Handle:timer, any:client)
{
 if (IsClientInGame(client) && IsPlayerAlive(client) && ZR_IsClientZombie(client) && g_ZombieExplode[client])
 {
                        g_ZombieExplode[client] = false;

            		new Float:iVec[ 3 ];
		        GetClientAbsOrigin( client, Float:iVec );

			TE_SetupExplosion( iVec, g_ExplosionSprite, 5.0, 1, 0, 50, 40, iNormal );
			TE_SendToAll();
			
			TE_SetupSmoke( iVec, g_SmokeSprite, 10.0, 3 );
			TE_SendToAll();
	
			EmitAmbientSound( EXPLODE_SOUND, iVec, client, SNDLEVEL_NORMAL );

                        ForcePlayerSuicide(client);
 }
}

public PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
  new client = GetClientOfUserId(GetEventInt(event, "userid"));

  g_ZombieExplode[client] = false;

}


public Action:ZR_OnClientInfect(&client, &attacker, &bool:motherInfect, &bool:respawnOverride, &bool:respawn)
{
                if(g_ZombieExplode[attacker])
                        return Plugin_Handled;

                return Plugin_Continue;
}

