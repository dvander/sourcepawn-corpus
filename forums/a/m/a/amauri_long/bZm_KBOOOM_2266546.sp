#include <cstrike>
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <sdktools_sound>
#include <morecolors>
#include <sdktools_functions>
#include <zombiereloaded>


#define EFL_NO_PHYSCANNON_INTERACTION (1<<30)

#pragma semicolon 1

#define WEAPONS_MAX_LENGTH 32
#define DATA "3.1"

new bool:g_ZombieExplode[MAXPLAYERS+1] = false;
new Handle:tiempo;

#define EXPLODE_SOUND	"ambient/explosions/explode_8.wav"
#define PLAYER_ONFIRE (1 << 24)

new g_ExplosionSprite;

#define SOUND_THUNDER "ambient/explosions/explode_9.wav"
#define SOUND_END "zombie_plague/survivor1.wav"

#define zr_facosa "zr_facosa/normal4.mp3"

#define zr_facosa1 "zr_facosa/rambo1.mp3"
#define zr_facosa2 "zr_facosa/rambo2.mp3"
#define zr_facosa3 "zr_facosa/chuck_norris1.mp3"
#define zr_facosa4 "zr_facosa/chuck_norris2.mp3"

#define zr_punishment1 "zr_punishment/punishment1.mp3"
#define zr_punishment2 "zr_punishment/punishment2.mp3"
#define zr_punishment3 "zr_punishment/punishment3.mp3"
#define zr_punishment4 "zr_punishment/punishment4.mp3"

new orange;
new g_HaloSprite;
new contar = 0;
new g_LightningSprite;
new g_SmokeSprite;

#define MAX_FILE_LEN 80
new Handle:g_CvarSoundName = INVALID_HANDLE;
new String:g_soundName[MAX_FILE_LEN];

new g_Time = 3;

enum PropTypeCheck{
    
    PROP_NONE = 0,
    PROP_RIGID = 1,
    PROP_PHYSBOX = 2,
    PROP_WEAPON = 3,
    PROP_TF2OBJ = 4,//tf2 buildings
    PROP_RAGDOLL = 5,
    PROP_TF2PROJ = 6//tf2 projectiles
    
};

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
    AddFileToDownloadsTable("sound/zombie_plague/MUTLEY.mp3");
    AddFileToDownloadsTable("zombie_plague/survivor1.wav");
    AddFileToDownloadsTable("sound/zr_facosa/normal4.mp3");
    AddFileToDownloadsTable("sound/zr_facosa/chuck_norris1.mp3");
    AddFileToDownloadsTable("sound/zr_facosa/chuck_norris2.mp3");
    AddFileToDownloadsTable("sound/zr_facosa/rambo1.mp3");
    AddFileToDownloadsTable("sound/zr_facosa/rambo2.mp3");
    AddFileToDownloadsTable("sound/zr_punishment/punishment1.mp3");
    AddFileToDownloadsTable("sound/zr_punishment/punishment2.mp3");
    AddFileToDownloadsTable("sound/zr_punishment/punishment3.mp3");
    AddFileToDownloadsTable("sound/zr_punishment/punishment4.mp3");
    orange=PrecacheModel("materials/sprites/fire2.vmt");
    g_HaloSprite = PrecacheModel("materials/sprites/halo01.vmt");
    g_ExplosionSprite = PrecacheModel("sprites/sprite_fire01.vmt");
    g_LightningSprite = PrecacheModel("sprites/lgtning.vmt");
    g_SmokeSprite = PrecacheModel("sprites/steam1.vmt");
    PrecacheSound(SOUND_THUNDER, true);
    PrecacheSound(SOUND_END, true);
    
    PrecacheSound(zr_facosa, true);
    PrecacheSound(zr_facosa1, true);
    PrecacheSound(zr_facosa2, true);
    PrecacheSound(zr_facosa3, true);
    PrecacheSound(zr_facosa4, true);
    PrecacheSound(zr_punishment1, true);
    PrecacheSound(zr_punishment2, true);
    PrecacheSound(zr_punishment3, true);
    PrecacheSound(zr_punishment4, true);
    PrecacheSound("zombie_plague/MUTLEY.mp3", true);
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
    ServerCommand("mp_roundtime 10");
    EmitSoundToAll("bZm/alertsound.mp3");
}

public EventRoundEnd(Handle:event, const String:name[], bool:dontBroadcast) {
    contar = 0;
    new ev_winner = GetEventInt(event, "winner");
    if(ev_winner == 2) {
    EmitSoundToAll(SOUND_END);
    }
    
}

public IsValidClient( client )
{
    if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) )
        return false;
    
    return true;
}

public OnClientDisconnect( id )

{
    new String:nome[MAX_NAME_LENGTH];
    GetClientName(id, nome, sizeof(nome));
    
    if (contar<=1)
    {
        contar=contar-1;
        CPrintToChatAll("{WHITE} that bag %s {LIME} left the game because fastdownload ta shit or because losing this same!", nome);
        EmitSoundToAll(zr_punishment3);
    }
}

public PlayerDeathEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
    new	victim   = GetClientOfUserId(GetEventInt(event,"userid"));contar++;
    decl Float:vecOrigin[3];
    GetClientAbsOrigin(victim, vecOrigin);
    if(IsValidClient(victim) && GetClientTeam(victim) == 2)
    {
        EmitAmbientSound("zombie_plague/MUTLEY.mp3", vecOrigin, victim, _, _, 1.0);
    }
}

public EnDamage(Handle:event, const String:name[], bool:dontBroadcast)
{
    
    new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
    new String:nome[MAX_NAME_LENGTH];
    GetClientName(attacker, nome, sizeof(nome));
    
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
                CPrintToChat(client, "{BLACK}[{GREEN}B{LIME}z{GREEN}M{BLACK}_{RED}K{WHITE}BOOM TIMER{BLACK}]{WHITE}Was stabbed by {LIME}%s :) {WHITE}you have %d seconds to pick up any human being or you will die!",nome,g_Time);
                new Handle:pack;
                new rnd_sound = GetRandomInt(1, 6);
                if(rnd_sound == 1) {
                    EmitSoundToAll(g_soundName);
                    CPrintToChat(attacker, "{BLACK}[{GREEN}B{LIME}z{GREEN}M{BLACK}_{RED}K{WHITE}BOOM {ORANGE}TIMER{BLACK}]{WHITE}Congratulations {LIME}%s :) {WHITE} Kill zombie!",nome);
                }
                
                else if(rnd_sound == 2) {
                    EmitSoundToAll(zr_facosa);
                    CPrintToChat(attacker, "{BLACK}[{GREEN}B{LIME}z{GREEN}M{BLACK} %s{RED} ashashash {WHITE} you, and fuck even!",nome);
                }
                else if(rnd_sound == 3) {
                    EmitSoundToAll(zr_facosa1);
                    CPrintToChat(attacker, "{BLACK}[{GREEN}B{LIME}z{GREEN}M{BLACK}_{RED}YOU LIKE RAMBO stabbed ATTACK YOUR OPPONENT %s !",nome);
                }
                else if(rnd_sound == 4) {
                    EmitSoundToAll(zr_facosa2);
                    CPrintToChat(attacker, "{RED}crazy {WHITE} Rambo you very cool es %s !",nome);
                }
                else if(rnd_sound == 5) {
                    EmitSoundToAll(zr_facosa3);
                    CPrintToChat(attacker, "{WHITE} putz was that %s!",nome);
                }
                else if(rnd_sound == 6) {
                    EmitSoundToAll(zr_facosa4);
                    CPrintToChat(attacker, "{GREEN}Congratulations you are Chuck Norris %s",nome);
                }
                CreateTimer(0.5, Timer_Beacon, client, TIMER_REPEAT);
                CreateDataTimer(GetConVarFloat(tiempo), ByeZM, pack);
                WritePackCell(pack, client);
                WritePackCell(pack, attacker);
            }
            
        }else if(ZR_IsClientHuman(attacker) && ZR_IsClientZombie(client) && StrEqual(weapon, "knife", false)){
            EmitSoundToAll(zr_punishment1);
            contar++;
            CPrintToChatAll("{RED} punishment {WHITE}%s{RED} was punished by stabbing the first zombie!",nome);
            IgniteEntity(attacker,12.0);
            ZR_InfectClient(attacker);
            new playerstate = GetEntProp ( attacker , Prop_Send , "m_nPlayerCond" );
            if (( playerstate & PLAYER_ONFIRE ) != 0 )
            {
                SetEntProp ( attacker , Prop_Send , "m_nPlayerCond" , ( playerstate & (~ PLAYER_ONFIRE )));
            }
            
        }else if(ZR_IsClientHuman(attacker) && ZR_IsClientZombie(client) && contar == 0)
        {
            EmitSoundToAll(zr_punishment4);
            ZR_InfectClient(attacker);
            CPrintToChatAll("{WHITE}%s{VIOLET} was possessed by an evil spirit to help the zombie!",nome);
            PrintHintTextToAll("was possessed by an evil spirit to help the zombie!!", nome);
            contar++;
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
        CPrintToChat(attacker, "{BLACK}[{GREEN}B{LIME}z{GREEN}M{BLACK}_{RED}K{WHITE}BOOM {ORANGE}TIMER{BLACK}] %s :) {WHITE}you took the human who stabs you then you saved himself from death stab!",nome);
        EmitSoundToAll(zr_punishment2);
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
        new ent = CreateEntityByName("env_explosion");
        SetEntProp(ent, Prop_Data, "m_iMagnitude", 300);
        SetEntProp(ent, Prop_Data, "m_iRadiusOverride", 350);
        SetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity", client);
        DispatchSpawn(ent);
        TeleportEntity(ent, location, NULL_VECTOR, NULL_VECTOR);
        AcceptEntityInput(ent, "explode");
        new Float:vec2[3];
        vec2 = location;
        vec2[2] = location[2] + 300.0;
        Lightning(location);
        spark(location);
        Explode1(location);
        Explode2(location);
        EmitAmbientSound( EXPLODE_SOUND, vec2, client, SNDLEVEL_NORMAL );

        if (IsValidClient(attacker)){
            DealDamage(client,999999,attacker,DMG_GENERIC," "); // enemy down ;)
        }
        else ForcePlayerSuicide(client);
    }
}

public Lightning(Float:vec1[3])
{
    new g_lightning     = PrecacheModel("materials/sprites/tp_beam001.vmt");
    new Float:toppos[3];toppos[0] = vec1[0];toppos[1] = vec1[1];toppos[2] = vec1[2]+1000;new lightningcolor[4];
    lightningcolor[0]               = 255;
    lightningcolor[1]               = 255;
    lightningcolor[2]               = 255;
    lightningcolor[3]               = 255;
    new Float:lightninglife         = 0.1;
    new Float:lightningwidth        = 40.0;
    new Float:lightningendwidth     = 10.0;
    new lightningstartframe         = 0;
    new lightningframerate          = 20;
    new lightningfadelength         = 1;
    new Float:lightningamplitude    = 20.0;
    new lightningspeed              = 250;
    
    
    
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
    TE_SetupBeamPoints(toppos, vec1, g_lightning, g_lightning, lightningstartframe, lightningframerate, lightninglife, lightningwidth, lightningendwidth, lightningfadelength, lightningamplitude, lightningcolor, lightningspeed);
    
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
            TE_SetupBeamRingPoint(vec, 10.0, 60.0, modelindex, haloindex, 0, 15, 0.6, 10.0, 0.5, beaconColor, 10, 0);
            TE_SendToAll();
            TE_SetupBeamRingPoint(vec, 10.0, 400.0, haloindex, modelindex, 1, 1, 0.5, 100.0, 1.0, beaconColor, 0, 0);
            TE_SendToAll();
            //Red
            beaconColor[0] = 255;
            beaconColor[1] = 0;
            beaconColor[2] = 0;
            beaconColor[3] = 500;
            TE_SetupBeamRingPoint(vec, 210.0, 60.0, g_beamsprite, g_halosprite, 0, 15, 0.5, 10.0, 0.5, beaconColor, 100, 0);
            TE_SendToAll();
            TE_SetupBeamRingPoint(vec, 10.0, 400.0, haloindex, modelindex, 1, 1, 0.5, 100.0, 1.0, beaconColor, 0, 0);
            TE_SendToAll();
            //Green
            beaconColor[0] = 0;
            beaconColor[1] = 255;
            beaconColor[2] = 0;
            beaconColor[3] = 500;
            TE_SetupBeamRingPoint(vec, 10.0, 60.0, modelindex, haloindex, 0, 15, 0.4, 10.0, 0.5, beaconColor, 10, 0);
            TE_SendToAll();
            TE_SetupBeamRingPoint(vec, 10.0, 400.0, haloindex, modelindex, 1, 1, 0.5, 100.0, 1.0, beaconColor, 0, 0);
            TE_SendToAll();
            EmitAmbientSound("buttons/blip1.wav", vec, client, SNDLEVEL_RAIDSIREN);
            times++;
            PrintCenterTextAll("Zombie exploded in %s second.", g_Time);
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

public spark(Float:vec[3])
{
    new Float:dir[3]={10.0,1.0,600.5000};//0.0,0.0,0.0
    TE_SetupSparks(vec, dir, 500, 50);
    TE_SendToAll();
}

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



