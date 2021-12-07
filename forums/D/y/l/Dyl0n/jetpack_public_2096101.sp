#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <morecolors>

#define PLUGIN_VERSION "1.1.0"

#define MOVETYPE_WALK            2
#define MOVETYPE_FLYGRAVITY        5
#define MOVECOLLIDE_DEFAULT        0
#define MOVECOLLIDE_FLY_BOUNCE    1

#define LIFE_ALIVE    0

// ConVars
new Handle:sm_jetpack            = INVALID_HANDLE;
new Handle:sm_jetpack_sound        = INVALID_HANDLE;
new Handle:sm_jetpack_speed        = INVALID_HANDLE;
new Handle:sm_jetpack_volume    = INVALID_HANDLE;

// SendProp Offsets
new g_iLifeState    = -1;
new g_iMoveCollide    = -1;
new g_iMoveType        = -1;
new g_iVelocity        = -1;

// Soundfile
new String:g_sSound[255]    = "vehicles/airboat/fan_blade_fullthrottle_loop1.wav";

// Is Jetpack Enabled
new bool:g_bJetpacks[MAXPLAYERS + 1]    = {false,...};
new bool:jetpackOn[MAXPLAYERS + 1]    = {false,...};

// Timer For GameFrame
new Float:g_fTimer    = 0.0;

// MaxClients
new g_iMaxClients    = 0;

public Plugin:myinfo = 
{ 
    name = "Jetpack", 
    author = "Knagg0 and Dyl0n", 
    description = "", 
    version = PLUGIN_VERSION, 
    url = "http://www.mfzb.de" 
}; 

#define EFFECT_TRAIL            "rockettrail_!"
new g_JetpackParticle[MAXPLAYERS + 1][3];
new g_JetpackLight[MAXPLAYERS + 1]  = { INVALID_ENT_REFERENCE, ... };

/**
 * Description: Functions to show TF2 particles
 */
#tryinclude "particle"
#if !defined _particle_included
    // Particle Attachment Types  -------------------------------------------------
    enum ParticleAttachmentType
    {
        NoAttach = 0,
        Attach,
        AttachMaintainOffset
    };

    // Particles ------------------------------------------------------------------

    /* CreateParticle()
    **
    ** Creates a particle at an entity's position. Attach determines the attachment
    ** type (0 = not attached, 1 = normal attachment, 2 = head attachment). Allows
    ** offsets from the entity's position.
    ** ------------------------------------------------------------------------- */
    stock CreateParticle(const String:particleType[], Float:time=5.0, entity=0,
                         ParticleAttachmentType:attach=Attach,
                         const String:attachToBone[]="head",
                         const Float:pos[3]=NULL_VECTOR,
                         const Float:ang[3]=NULL_VECTOR,
                         Timer:deleteFunc=Timer:0,
                         &Handle:timerHandle=INVALID_HANDLE)
    {
        new particle = CreateEntityByName("info_particle_system");
        if (particle > 0 && IsValidEdict(particle))
        {
            decl String:tName[32];
            Format(tName, sizeof(tName), "target%i", entity);
            DispatchKeyValue(entity, "targetname", tName);

            DispatchKeyValue(particle, "targetname", "sc2particle");
            DispatchKeyValue(particle, "parentname", tName);
            DispatchKeyValue(particle, "effect_name", particleType);

            if (attach > NoAttach)
            {
                SetVariantString("!activator");
                AcceptEntityInput(particle, "SetParent", entity, particle, 0);

                if (attachToBone[0] != '\0')
                {
                    SetVariantString(attachToBone);
                    AcceptEntityInput(particle, (attach >= AttachMaintainOffset)
                                                ? "SetParentAttachmentMaintainOffset"
                                                : "SetParentAttachment",
                                      particle, particle, 0);
                }
            }

            DispatchSpawn(particle);
            ActivateEntity(particle);

            TeleportEntity(particle, pos, ang, NULL_VECTOR);
            AcceptEntityInput(particle, "start");

            if (time > 0.0)
            {
                timerHandle = CreateTimer(time, deleteFunc ? deleteFunc : DeleteParticles,
                                          EntIndexToEntRef(particle));
            }
        }
        else
            LogError("CreateParticle: could not create info_particle_system");

        return particle;
    }

    stock DeleteParticle(&particleRef)
    {
        if (particleRef != INVALID_ENT_REFERENCE)
        {
            new particle = EntRefToEntIndex(particleRef);
            if (particle > 0 && IsValidEntity(particle))
                AcceptEntityInput(particle, "kill");

            particleRef = INVALID_ENT_REFERENCE;
        }
    }

    public Action:DeleteParticles(Handle:timer, any:particleRef)
    {
        DeleteParticle(particleRef);
        return Plugin_Stop;
    }
#endif 

public OnPluginStart() 
{ 
    AutoExecConfig(); 
     
    // Create ConVars 
    CreateConVar("sm_jetpack_version", PLUGIN_VERSION, "", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY); 
    sm_jetpack = CreateConVar("sm_jetpack", "1", "", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY); 
    sm_jetpack_sound = CreateConVar("sm_jetpack_sound", g_sSound, "", FCVAR_PLUGIN); 
    sm_jetpack_speed = CreateConVar("sm_jetpack_speed", "100", "", FCVAR_PLUGIN); 
    sm_jetpack_volume = CreateConVar("sm_jetpack_volume", "0.5", "", FCVAR_PLUGIN); 

    RegConsoleCmd("sm_jp", OnToggleJetpack, "Toggles jetpack on/off");
    RegConsoleCmd("sm_jetpack", OnToggleJetpack, "Toggles jetpack on/off");

    // Find SendProp Offsets
    if((g_iLifeState = FindSendPropOffs("CBasePlayer", "m_lifeState")) == -1)
        LogError("Could not find offset for CBasePlayer::m_lifeState");
        
    if((g_iMoveCollide = FindSendPropOffs("CBaseEntity", "movecollide")) == -1)
        LogError("Could not find offset for CBaseEntity::movecollide");
        
    if((g_iMoveType = FindSendPropOffs("CBaseEntity", "movetype")) == -1)
        LogError("Could not find offset for CBaseEntity::movetype");
        
    if((g_iVelocity = FindSendPropOffs("CBasePlayer", "m_vecVelocity[0]")) == -1)
        LogError("Could not find offset for CBasePlayer::m_vecVelocity[0]");
} 

public Action:OnToggleJetpack(client, args)
{
    if (jetpackOn[client]) {
            JetpackM(client,0);
        jetpackOn[client] = false;
        CPrintToChat(client, "{green}Jetpack Disabled!");
    }
    else {
    jetpackOn[client] = true;
    CPrintToChat(client, "{green}Jetpack Enabled! Hold [spacebar] to use it.");
    }

    return Plugin_Handled;
}

public OnMapStart() 
{ 
    g_fTimer = 0.0; 
    g_iMaxClients = GetMaxClients(); 
} 

public OnConfigsExecuted() 
{ 
    GetConVarString(sm_jetpack_sound, g_sSound, sizeof(g_sSound)); 
    PrecacheSound(g_sSound, true); 
} 

public OnGameFrame()
{
    if(GetConVarBool(sm_jetpack) && g_fTimer < GetGameTime() - 0.075)
    {
        g_fTimer = GetGameTime();
        
        for(new i = 1; i <= g_iMaxClients; i++)
        {
            if(g_bJetpacks[i])
            {
                if(!IsAlive(i)) StopJetpack(i);
                else AddVelocity(i, GetConVarFloat(sm_jetpack_speed));
            }
        }
    }
} 

public Action:jumped(Handle:timer, any:client) 
{ 
    if(IsClientInGame(client) && GetClientButtons(client) & IN_JUMP)
    { 
        JetpackP(client,0); 
        CreateTimer(0.0,jumped,client); 
    } 
    else 
    { 
        JetpackM(client,0); 
    } 
} 

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon) 
{ 
    if(buttons & IN_JUMP && !g_bJetpacks[client] && jetpackOn[client]) 
    { 
        CreateTimer(0.2,jumped,client); 
    } 
} 

public OnClientDisconnect(client)
{
    StopJetpack(client);
    StopSound(client, SNDCHAN_AUTO, g_sSound);
    jetpackOn[client] = false;
}

public Action:JetpackP(client, args)
{
    if(GetConVarBool(sm_jetpack) && !g_bJetpacks[client] && IsAlive(client))
    {
        new Float:vecPos[3];
            static const Float:pos[3] = {   0.0, 10.0, 1.0 };
            static const Float:ang[3] = { -25.0, 90.0, 0.0 };
        GetClientAbsOrigin(client, vecPos);
        EmitSoundToAll(g_sSound, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, GetConVarFloat(sm_jetpack_volume), SNDPITCH_NORMAL, -1, vecPos, NULL_VECTOR, true, 0.0);
        SetMoveType(client, MOVETYPE_FLYGRAVITY, MOVECOLLIDE_FLY_BOUNCE);
        g_bJetpacks[client] = true;
            if (g_JetpackParticle[client][1] == INVALID_ENT_REFERENCE)
            {
                      g_JetpackParticle[client][1] = EntIndexToEntRef(CreateParticle(EFFECT_TRAIL, 0.0,
                                                                     client, Attach, "flag",
                                                                     pos, ang));
            }

            if (g_JetpackLight[client] == INVALID_ENT_REFERENCE)
            {
                      g_JetpackLight[client] = EntIndexToEntRef(CreateLightEntity(client));
            }
    }
    
    return Plugin_Continue;
}

public Action:JetpackM(client, args)
{
    StopJetpack(client);
        DeleteLightEntity(g_JetpackLight[client]);
        for (new j = 0; j < sizeof(g_JetpackParticle[]); j++)
            DeleteParticle(g_JetpackParticle[client][j]);

    return Plugin_Continue;
}

StopJetpack(client)
{
    if(g_bJetpacks[client])
    {
        if(IsAlive(client)) SetMoveType(client, MOVETYPE_WALK, MOVECOLLIDE_DEFAULT);
        StopSound(client, SNDCHAN_AUTO, g_sSound);
        g_bJetpacks[client] = false;
    }
}

SetMoveType(client, movetype, movecollide)
{
    if(g_iMoveType == -1) return;
    SetEntData(client, g_iMoveType, movetype);
    if(g_iMoveCollide == -1) return;
    SetEntData(client, g_iMoveCollide, movecollide);
}

AddVelocity(client, Float:speed)
{
    if(g_iVelocity == -1) return;
    
    new Float:vecVelocity[3];
    GetEntDataVector(client, g_iVelocity, vecVelocity);
    
    vecVelocity[2] += speed;

    TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vecVelocity);
}

bool:IsAlive(client)
{
    if(g_iLifeState != -1 && GetEntData(client, g_iLifeState, 1) == LIFE_ALIVE)
        return true;

    return false;
}

CreateLightEntity(client)
{
    new entity = CreateEntityByName("light_dynamic");
    if (IsValidEntity(entity))
    {
        DispatchKeyValue(entity, "inner_cone", "0");
        DispatchKeyValue(entity, "cone", "80");
        DispatchKeyValue(entity, "brightness", "6");
        DispatchKeyValueFloat(entity, "spotlight_radius", 240.0);
        DispatchKeyValueFloat(entity, "distance", 250.0);
        DispatchKeyValue(entity, "_light", "255 100 10 41");
        DispatchKeyValue(entity, "pitch", "-90");
        DispatchKeyValue(entity, "style", "5");
        DispatchSpawn(entity);

        decl Float:fAngle[3];
        GetClientEyeAngles(client, fAngle);

        decl Float:fAngle2[3];
        fAngle2[0] = 0.0;
        fAngle2[1] = fAngle[1];
        fAngle2[2] = 0.0;

        decl Float:fForward[3];
        GetAngleVectors(fAngle2, fForward, NULL_VECTOR, NULL_VECTOR);
        ScaleVector(fForward, -50.0);
        fForward[2] = 0.0;

        decl Float:fPos[3];
        GetClientEyePosition(client, fPos);

        decl Float:fOrigin[3];
        AddVectors(fPos, fForward, fOrigin);

        fAngle[0] += 90.0;
        fOrigin[2] -= 120.0;
        TeleportEntity(entity, fOrigin, fAngle, NULL_VECTOR);

        decl String:strName[32];
        Format(strName, sizeof(strName), "target%i", client);
        DispatchKeyValue(client, "targetname", strName);

        DispatchKeyValue(entity, "parentname", strName);
        SetVariantString("!activator");
        AcceptEntityInput(entity, "SetParent", client, entity, 0);
        SetVariantString("head");
        AcceptEntityInput(entity, "SetParentAttachmentMaintainOffset", client, entity, 0);
        AcceptEntityInput(entity, "TurnOn");
    }
    return entity;
}


DeleteLightEntity(&entityRef)
{
    if (entityRef != INVALID_ENT_REFERENCE)
    {
        new entity = EntRefToEntIndex(entityRef);
        if (entity > 0 && IsValidEntity(entity))
        {
            AcceptEntityInput(entity, "kill");
        }
        entityRef = INVALID_ENT_REFERENCE;
    }
} 