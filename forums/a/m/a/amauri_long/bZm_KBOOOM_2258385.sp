#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <sdktools_sound>
#include <morecolors>
#include <zombiereloaded>

#pragma semicolon 1

#define WEAPONS_MAX_LENGTH 32
#define DATA "2.0 beta"

new bool:g_ZombieExplode[MAXPLAYERS+1] = false;
new Handle:tiempo;

#define EXPLODE_SOUND	"ambient/explosions/explode_8.wav"

new g_ExplosionSprite;

#define MSG_STOP_TK_BAN "Disconnected from the server with 2 zombies and do not finish the move! ban 1h"
#define SOUND_THUNDER "ambient/explosions/explode_9.wav"

new orange;
new g_HaloSprite;
new contar = 0;
new g_LightningSprite;
new g_SmokeSprite;

#define MAX_FILE_LEN 80
new Handle:g_CvarSoundName = INVALID_HANDLE;
new String:g_soundName[MAX_FILE_LEN];

new g_Time = 2;

#define DMG_GENERIC 0

public Plugin:myinfo =
{
    name = "KBOOOM",
    author = "Amauri Bueno dos Santos",
    description = "Kill zombies with knife",
    version = DATA,
    url = "www.sourcemod.com"
};

public OnPluginStart()
{
CreateConVar("sm_zombiexplode3_version", DATA, "version", FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
HookEvent("player_spawn", PlayerSpawn);
HookEvent("player_hurt", EnDamage);
HookEvent("player_death", PlayerDeathEvent);
HookEvent("round_start", eventRoundStart);
HookEvent("round_end", EventRoundEnd);
tiempo = CreateConVar("sm_zombiexplode3_time", "3.0", "Seconds that zombie have for catch to humans");
g_CvarSoundName = CreateConVar("sm_knife_sound", "zombie_plague/facadazm.mp3", "Stab victory");
}

public OnMapStart()
{
    orange=PrecacheModel("materials/sprites/fire2.vmt");
    g_HaloSprite = PrecacheModel("materials/sprites/halo01.vmt");
    g_ExplosionSprite = PrecacheModel("sprites/sprite_fire01.vmt");
    g_LightningSprite = PrecacheModel("sprites/lgtning.vmt");
    g_SmokeSprite = PrecacheModel("sprites/steam1.vmt");
    PrecacheSound(SOUND_THUNDER, true);
    PrecacheSound( "ambient/explosions/explode_8.wav", true);
    AutoExecConfig();
}

public OnConfigsExecuted()
{
	PrecacheSound(EXPLODE_SOUND, true);
	GetConVarString(g_CvarSoundName, g_soundName, MAX_FILE_LEN);
	decl String:buffer[MAX_FILE_LEN];
	PrecacheSound(g_soundName, true);
	Format(buffer, sizeof(buffer), "sound/%s", g_soundName);
	AddFileToDownloadsTable(buffer);
	
	AddFileToDownloadsTable("sound/bZm/alertsound.mp3");
	PrecacheSound("bZm/alertsound.mp3", true);

}

public Action:eventRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{ 
contar = 0;
EmitSoundToAll("bZm/alertsound.mp3");
}

public EventRoundEnd(Handle:event, const String:name[], bool:dontBroadcast) {
contar = 0;

}

public IsValidClient( client ) 
{ 
    if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) ) 
        return false; 
     
    return true; 
}

public OnClientDisconnect( id )

{
	new tempo = 10;
	new String:nome[MAX_NAME_LENGTH];
	GetClientName(id, nome, sizeof(nome));
	
	if (contar<=1)
	{
		contar=contar-1;
		CPrintToChatAll("{WHITE}%s {RED}BY banned %d SEG LEFT THE SERVER FOR POWER stab ZM FIRST!", nome, tempo);//60 = 1 e 1440 e igual a 1 dia
		ServerCommand("sm_ban %s %d Disconnected from the server with 2 zombies and do not finish the move! ban 1h", nome, tempo);
		//ServerCommand("sm_ban \"%N\" %d \"%s\"", id, tempo, MSG_STOP_TK_BAN);
	}
}

public PlayerDeathEvent(Handle:event, const String:name[], bool:dontBroadcast)
{	
	contar++;
}

public EnDamage(Handle:event, const String:name[], bool:dontBroadcast)
{

        new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	if (!IsValidClient(attacker))
		return;

	if (IsPlayerAlive(attacker))
	{
           new client = GetClientOfUserId(GetEventInt(event, "userid"));
           decl String:weapon[WEAPONS_MAX_LENGTH];
           GetEventString(event, "weapon", weapon, sizeof(weapon));
           
           if(ZR_IsClientHuman(attacker) && ZR_IsClientZombie(client) && contar > 0)
           {

    
             if(StrEqual(weapon, "knife", false))
             {
                 g_ZombieExplode[client] = true;
                 CPrintToChat(client, "{BLACK}[{GREEN}B{LIME}z{GREEN}M{BLACK}_{RED}K{WHITE}BOOM TIMER{BLACK}]{WHITE}Was stabbed by {LIME}%s :) {WHITE}You have %d seconds to pick up any human being or you will die!",ZR_IsClientHuman(attacker),g_Time);
                 CPrintToChat(attacker, "{BLACK}[{GREEN}B{LIME}z{GREEN}M{BLACK}_{RED}K{WHITE}BOOM {ORANGE}TIMER{BLACK}]{WHITE}Congratulations {LIME}%s :) {WHITE}You have %d seconds to escape the zombie or you will die!",ZR_IsClientHuman(attacker),g_Time);
                 new Handle:pack;
                 EmitSoundToAll(g_soundName);
                 SetClientShake( client, 10.0, 9000.0, 10.0, 40.0 );
                 CreateTimer(0.5, Timer_Beacon, client, TIMER_REPEAT);
                 CreateDataTimer(GetConVarFloat(tiempo), ByeZM, pack);
                 WritePackCell(pack, client);
                 WritePackCell(pack, attacker);
             }

			}else if(ZR_IsClientHuman(attacker) && ZR_IsClientZombie(client) && StrEqual(weapon, "knife", false)){

				
				new String:nome[MAX_NAME_LENGTH];
				GetClientName(attacker, nome, sizeof(nome));
				ZR_InfectClient(attacker);contar++;
				CPrintToChatAll("{RED} Now {WHITE}%s{RED} is because phaco the first zombie zombie!",nome);
				
            }
        }

}

public Action:ZR_OnClientInfect(&client, &attacker, &bool:motherInfect, &bool:respawnOverride, &bool:respawn)
{
    new String:nome[MAX_NAME_LENGTH];
    GetClientName(attacker, nome, sizeof(nome));
    
    if (!IsValidClient(attacker))
		      return Plugin_Continue;
    if(g_ZombieExplode[attacker])
            {
                        g_ZombieExplode[attacker] = false;contar++;
                        CPrintToChat(attacker, "{BLACK}[{GREEN}B{LIME}z{GREEN}M{BLACK}_{RED}K{WHITE}BOOM {ORANGE}TIMER{BLACK}]{WHITE}Crazy {LIME}%s :) {WHITE}you took the human that phaco you, then you saved from death stab!",nome);
            }
    return Plugin_Continue;
}

public Action:ByeZM(Handle:timer, Handle:pack)
{

   new client;
   new attacker;



   ResetPack(pack);
   client = ReadPackCell(pack);
   attacker = ReadPackCell(pack);

   if (IsClientInGame(client) && IsPlayerAlive(client) && ZR_IsClientZombie(client) && g_ZombieExplode[client])
   {
                        g_ZombieExplode[client] = false;
						
			decl Float:location[3];
			GetClientAbsOrigin(client, location);
			new Float:vec2[3];
			vec2 = location;
			vec2[2] = location[2] + 300.0;
			Lightning(location);
			spark(location);
			Explode1(location);
			Explode2(location);
	
			EmitAmbientSound( EXPLODE_SOUND, vec2, client, SNDLEVEL_NORMAL );

                        if (IsValidClient(attacker))
                           DealDamage(client,999999,attacker,DMG_GENERIC," "); // enemy down ;)
                        else
                           ForcePlayerSuicide(client);
   }
}

public Lightning(Float:vec1[3])
{
    new Float:toppos[3];toppos[0] = vec1[0];toppos[1] = vec1[1];toppos[2] = vec1[2]+1000;
 
    
    //raios
    
    new color[4] = {255, 255, 255, 255};
    
    // define the direction of the sparks
    new Float:dir[3] = {0.0, 0.0, 0.0};
    
    TE_SetupBeamPoints(toppos, vec1, g_LightningSprite, 0, 0, 0, 0.2, 20.0, 10.0, 0, 1.0, color, 3);
    TE_SendToAll();
    
    TE_SetupSparks(vec1, dir, 5000, 1000);
    TE_SendToAll();
    
    TE_SetupEnergySplash(vec1, dir, false);
    TE_SendToAll();
    
    TE_SetupSmoke(vec1, g_SmokeSprite, 5.0, 10);
    TE_SendToAll();
    
    TE_SendToAll(0.0);
}

public PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
  new client = GetClientOfUserId(GetEventInt(event, "userid"));

  g_ZombieExplode[client] = false;
  if (ZR_IsClientZombie(client))
		{
		contar++;
		}
}

public Action:Timer_Beacon(Handle:timer, any:client)
{
	static times = 0;
	
	if (times < g_Time)
	{
		if (IsClientInGame(client))
		{
			new Float:vec[3];
			GetClientAbsOrigin(client, vec);
			new beaconColor[4];
			new modelindex = PrecacheModel("sprites/laser.vmt");
			new haloindex = PrecacheModel("sprites/glow02.vmt");
			
			new g_beamsprite = PrecacheModel("materials/sprites/lgtning.vmt");
			new g_halosprite = PrecacheModel("materials/sprites/halo01.vmt");
			
			beaconColor[0] = 255;
			beaconColor[1] = 255;
			beaconColor[2] = 255;
			beaconColor[3] = 500;
			TE_SetupBeamRingPoint(vec, 10.0, 80.0, modelindex, haloindex, 0, 15, 0.6, 10.0, 0.5, beaconColor, 10, 0);
			TE_SendToAll();
			TE_SetupBeamRingPoint(vec, 10.0, 400.0, haloindex, modelindex, 1, 1, 0.2, 100.0, 1.0, beaconColor, 0, 0);
			TE_SendToAll();
			//Red
			beaconColor[0] = 255;
			beaconColor[1] = 0;
			beaconColor[2] = 0;
			beaconColor[3] = 500;
			TE_SetupBeamRingPoint(vec, 210.0, 70.0, g_beamsprite, g_halosprite, 0, 15, 0.5, 10.0, 0.5, beaconColor, 100, 0);
			TE_SendToAll();
			TE_SetupBeamRingPoint(vec, 10.0, 400.0, haloindex, modelindex, 1, 1, 0.2, 100.0, 1.0, beaconColor, 0, 0);
			TE_SendToAll();
			//Green
			beaconColor[0] = 0;
			beaconColor[1] = 255;
			beaconColor[2] = 0;
			beaconColor[3] = 500;
			TE_SetupBeamRingPoint(vec, 10.0, 60.0, modelindex, haloindex, 0, 15, 0.4, 10.0, 0.5, beaconColor, 10, 0);
			TE_SendToAll();
			TE_SetupBeamRingPoint(vec, 10.0, 400.0, haloindex, modelindex, 1, 1, 0.2, 100.0, 1.0, beaconColor, 0, 0);
			TE_SendToAll();
			EmitAmbientSound("buttons/blip1.wav", vec, client, SNDLEVEL_RAIDSIREN);
			times++;

			PrintCenterTextAll("Zombie explodira em %s segundos.", g_Time);
		}
	}
	else
	{
		times = 0;
		return Plugin_Stop;
	}

	return Plugin_Continue;
}
public Explode1(Float:vec1[3])
{
	new color[4]={0,255,0,500};
	Boom("ambient/explosions/explode_8.wav", vec1);
	TE_SetupExplosion(vec1, g_ExplosionSprite, 10.0, 1, 0, 600, 5000);
	TE_SendToAll();
	TE_SetupBeamRingPoint(vec1, 10.0, 500.0, orange, g_HaloSprite, 0, 10, 0.6, 10.0, 0.5, color, 10, 0);
  	TE_SendToAll();
}

public Explode2(Float:vec1[3])
{
	vec1[2] += 10;
	Boom("ambient/explosions/explode_8.wav", vec1);
	TE_SetupExplosion(vec1, g_ExplosionSprite, 10.0, 1, 0, 600, 5000);
	TE_SendToAll();
}
//eFECTS FIREWORKS
public spark(Float:vec[3])
{
	new Float:dir[3]={0.0,0.0,0.0};
	TE_SetupSparks(vec, dir, 500, 50);
	TE_SendToAll();
}
//FIM DE FIREWORKS

public Boom(const String:sound[],const Float:orig[3])
{
	EmitSoundToAll(sound,SOUND_FROM_WORLD,SNDCHAN_AUTO,SNDLEVEL_NORMAL,SND_NOFLAGS,SNDVOL_NORMAL,SNDPITCH_NORMAL,-1,orig,NULL_VECTOR,true,0.0);
}

stock DealDamage(nClientVictim, nDamage, nClientAttacker = 0, nDamageType = DMG_GENERIC, String:sWeapon[] = "")
{
	if(	nClientVictim > 0 &&
			IsValidEdict(nClientVictim) &&
			IsClientInGame(nClientVictim) &&
			IsPlayerAlive(nClientVictim) &&
			nDamage > 0)
	{
		new EntityPointHurt = CreateEntityByName("point_hurt");
		if(EntityPointHurt != 0)
		{
			new String:sDamage[16];
			IntToString(nDamage, sDamage, sizeof(sDamage));

			new String:sDamageType[32];
			IntToString(nDamageType, sDamageType, sizeof(sDamageType));

			DispatchKeyValue(nClientVictim,			"targetname",		"war3_hurtme");
			DispatchKeyValue(EntityPointHurt,		"DamageTarget",	"war3_hurtme");
			DispatchKeyValue(EntityPointHurt,		"Damage",				sDamage);
			DispatchKeyValue(EntityPointHurt,		"DamageType",		sDamageType);
			if(!StrEqual(sWeapon, ""))
				DispatchKeyValue(EntityPointHurt,	"classname",		sWeapon);
			DispatchSpawn(EntityPointHurt);
			AcceptEntityInput(EntityPointHurt,	"Hurt",					(nClientAttacker != 0) ? nClientAttacker : -1);
			DispatchKeyValue(EntityPointHurt,		"classname",		"point_hurt");
			DispatchKeyValue(nClientVictim,			"targetname",		"war3_donthurtme");

			RemoveEdict(EntityPointHurt);
		}
	}
}

stock SetClientShake( index, Float:Amplitude, Float:Radius, Float:Duration, Float:Frequency )
{
    decl Float:ClientOrigin[ 3 ];
    new Ent = CreateEntityByName( "env_shake" );
    
    if( DispatchSpawn( Ent ) )
    {
        DispatchKeyValueFloat( Ent, "amplitude", Amplitude );
        DispatchKeyValueFloat( Ent, "radius", Radius );
        DispatchKeyValueFloat( Ent, "duration", Duration );
        DispatchKeyValueFloat( Ent, "frequency", Frequency );
        
        SetVariantString( "spawnflags 8" );
        AcceptEntityInput( Ent, "AddOutput" );
        AcceptEntityInput( Ent, "StartShake", index );
        GetClientAbsOrigin( index, ClientOrigin );
        TeleportEntity( Ent, ClientOrigin, NULL_VECTOR, NULL_VECTOR );
    }
}


