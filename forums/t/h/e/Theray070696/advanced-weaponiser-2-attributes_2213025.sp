#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>
#include <tf2items>
#include <tf2attributes>
#include <customweaponstf>

// Sounds
#define SOUND_EXPLOSION_BIG                 "ambient/explosions/explode_8.wav"
#define SOUND_1217_RELOAD                   "weapons/shotgun_reload.wav"
#define SOUND_FIRELEAK_OIL                "physics/flesh/flesh_bloody_impact_hard1.wav"
#define SOUND_FLAME_ENGULF                  "misc/flame_engulf.wav"

// Particles
#define PARTICLE_FIRE                       "buildingdamage_dispenser_fire1"
#define PARTICLE_AREA_FIRE_BLUE             "player_glowblue"

// Models
#define MODEL_DEFAULTPHYSICS                "models/props_2fort/coffeepot.mdl"
#define MODEL_FIRELEAK                  "models/props_farm/haypile001.mdl"

// Teams
#define TEAM_SPEC    0
#define TEAM_RED    2
#define TEAM_BLUE   3

#define SLOTS_MAX               7

// Damage Types
#define TF_DMG_BULLET                       (1 << 1) // 2
#define TF_DMG_BLEED                        (1 << 2) // 4
#define TF_DMG_CRIT                         (1 << 20) // 1048576
#define TF_DMG_UNKNOWN_1                    (1 << 11) // 2048
#define TF_DMG_FIRE                         (1 << 24) // 16777216
#define TF_DMG_AFTERBURN                    TF_DMG_UNKNOWN_1 | (1 << 3) // 2048 + 8 = 2056

#define    MAX_EDICT_BITS    11
#define    MAX_EDICTS        (1 << MAX_EDICT_BITS)

// Attribute Stuff
#define ATTRIBUTE_1026_DISTANCE_LIMIT               600.0
#define ATTRIBUTE_1026_PUSHSCALE                    0.03
#define ATTRIBUTE_1026_PUSHMAX                      3.0
#define ATTRIBUTE_1026_COOLDOWN                     3.5

#define ATTRIBUTE_FIRELEAK_TIME         0.2
#define ATTRIBUTE_FIRELEAK_COST         10

new Float:fAttribute_1034_Time[MAXPLAYERS+1] = 0.0;

new Float:g_fOilLeakDelay[MAXPLAYERS+1] = 0.0;
new g_iOilLeakStatus[MAX_EDICTS + 1] = 0;
new g_iOilLeakDamage[MAXPLAYERS+1] = 0;
new g_iOilLeakDamageOwner[MAXPLAYERS+1] = 0;
new Float:g_fOilLeakLife[MAX_EDICTS + 1] = 0.0;

new Handle:g_hOilLeakEntities = INVALID_HANDLE;

new g_iAchBoilerTimer1193[MAXPLAYERS+1] = 0;
new g_iAchBoilerBurner1193[MAXPLAYERS+1] = 0;

new Float:g_fTotalDamage1296[MAXPLAYERS+1] = 0.0;

new bool:g_bFastCloaked[MAXPLAYERS+1] = false;
new g_iEntitySlot[MAX_EDICTS+1] = -1;
new Float:g_fEntityCreateTime[MAX_EDICTS+1] = 0.0;
new g_iLastButtons[MAXPLAYERS+1] = 0;
new bool:g_bRocketJumping[MAXPLAYERS+1] = false;
new bool:g_bWasDisguised[MAXPLAYERS+1] = false;

new bool:g_bHiddenEntities[MAX_EDICTS+1] = false;

new g_teamColorSoft[4][4];

new Handle:g_hAllowDownloads = INVALID_HANDLE;
new Handle:g_hDownloadUrl = INVALID_HANDLE;

new g_iExplosionSprite;
new g_iHaloSprite;
new g_iWhite;

#define PLUGIN_VERSION "1.0.3a"

public Plugin:myinfo =
{
    name = "Custom Weapons: Advanced Weaponiser 2 Attributes",
    author = "MechaTheSlag (Attributes) Theray070696 (Porting to CW2)",
    description = "Advanced Weaponiser 2's attributes, ported to Custom Weapons 2!",
    version = PLUGIN_VERSION,
    url = ""
};

/* *** Attributes In This Plugin ***
  !  "fastcloak on backstab"
       Instant cloak upon backstab.
  -> "projectiles bounce"
        "bounce count"
       Projectiles bounce on walls, grounds and ceilings.
  -> "earthquake on rocket jump land"
        Performs an earthquake upon landing after a Rocket Jump.
        This weapon is pretty heavy.
  -> "reload clip on damage" // Kinda working, might not shoot
       "max clip size"
       On hit, reloads secondary weapon for every 50 damage dealt up to max clip size.
  -> "alt fire is oil"
       Instead of alt-fire doing what it normally would, it drops oil that can be ignited.
  -> "attack while cloaked"
       Can attack while cloaked.
  -> "reset afterburn"
       Resets afterburn on somebody that is on fire.
  -> "controllable projectiles"
      "how controllable"
      Projectiles are controllable.
      0.25 is low control, 1.0 is full control
  -> "item is heavy"
      "force"
       While this item is out and the person holding it is in the air, he/she moves down with the provided force.
  -> "no reloading"
       Prevents reloading from happening.
*/

// HasAttribute[2049] causes a super-marginal performance boost. Don't touch it.
new bool:HasAttribute[2049];
new bool:FastcloakOnBackstab[2049];
new bool:ProjectilesBounce[2049];
new Float:ProjectilesBounce_Count[2049];
new bool:Earthquake[2049];
new bool:DamageReloads[2049];
new Float:DamageReloads_Max[2049];
new bool:AltFireIsOil[2049];
new bool:AttackWhileCloaked[2049];
new bool:ResetAfterburn[2049];
new bool:ControllableProjectiles[2049];
new Float:ControllableProjectiles_Control[2049];
new bool:ItemIsHeavy[2049];
new Float:ItemIsHeavy_Force[2049];
new bool:NoReloading[2049];

public OnPluginStart()
{
    HookEvent("rocket_jump", Attributes_RocketJump);
    HookEvent("rocket_jump_landed", Attributes_RocketJumpLand);
    
    for(new i = 1; i <= MaxClients; i++)
    {
        if(!IsClientInGame(i)) continue;
        OnClientPutInServer(i);
    }
    
    AttributesInit();
}

public OnPluginEnd()
{
    AttributesStop();
}

public OnMapStart()
{
    Attributes_Precache();
}

Attributes_Precache()
{
    // Particles
    PrecacheParticle(PARTICLE_FIRE);
    PrecacheParticle(PARTICLE_AREA_FIRE_BLUE);
    
    // Models
    SuperPrecacheModel(MODEL_FIRELEAK);
    SuperPrecacheModel(MODEL_DEFAULTPHYSICS, true);
    
    // Sounds
    SuperPrecacheSound(SOUND_EXPLOSION_BIG);
    SuperPrecacheSound(SOUND_FIRELEAK_OIL);
    SuperPrecacheSound(SOUND_FLAME_ENGULF);
}

stock bool:IsValidClient(client)
{
    if(client <= 0) return false;
    if(client > MaxClients) return false;
    if(!IsClientConnected(client)) return false;
    return IsClientInGame(client);
}

stock bool:IsValidTeam(client)
{
    new team = GetClientTeam(client);
    if(team == TEAM_RED) return true;
    if(team == TEAM_BLUE) return true;
    return false;
}

public AttributesInit()
{
    Attribute_1056_Init();
}

Attribute_1056_Init()
{
    g_hOilLeakEntities = CreateArray();
}

public AttributesStop()
{
    FastCloakRemoveAll();
    Attributes_1056_Think(true);
}

public FastCloak(client)
{
    if(g_bFastCloaked[client]) return;
    
    HideClientWearables(client, true);
    HideEntity(client, true);
    TF2_AddCondition(client, TFCond_Cloaked, 999.0);
    g_bFastCloaked[client] = true;
}

public FastCloakThink(client)
{
    if(TF2_IsPlayerInCondition(client, TFCond_Cloaked)) return;
    if(!g_bFastCloaked[client]) return;
    
    HideClientWearables(client, false);
    HideEntity(client, false);
    g_bFastCloaked[client] = false;
}

public FastCloakRemove(client)
{
    if(IsValidClient(client))
    {
        HideClientWearables(client, false);
        HideEntity(client, false);
        g_bFastCloaked[client] = false;
    }
}

public FastCloakRemoveAll()
{
    for(new i = 1; i <= MaxClients; i++)
    {
        FastCloakRemove(i);
    }
}

stock bool:HideClientWearables(client, bool:bHide)
{
    for(new i = 0; i <= 5; i++)
    {
        new weapon = GetPlayerWeaponSlot(client, i);
        if(weapon > 0 && IsValidEdict(weapon))
        {
            if(!IsHiddenEntity(weapon)) HideEntity(weapon, bHide);
        }
    }

    new String:strEntities[][255] = {"tf_wearable", "tf_wearable_demoshield"};
    for(new i = 0; i < sizeof(strEntities); i++)
    {
        new entity = -1;
        while((entity = FindEntityByClassname(entity, strEntities[i])) != -1)
        {
            if(IsClassname(entity, strEntities[i]) && GetOwner(entity) == client && !IsHiddenEntity(entity)) HideEntity(entity, bHide);
        }
    }
}

stock bool:SubtractWeaponAmmo(client, slot, ammo)
{
    new weapon = GetPlayerWeaponSlot(client, slot);
    if(IsValidEntity(weapon))
    {
        new realammo = GetEntData(client, FindSendPropOffs("CTFPlayer", "m_iAmmo")+4);
        realammo -= ammo;
        if(realammo < 0) return false;
        SetEntData(client, FindSendPropOffs("CTFPlayer", "m_iAmmo")+4, realammo);
        return true;
    }
    return false;
}

stock HideEntity(entity, bool:bHide)
{
    if(bHide)
    {
        SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
        SetEntityRenderColor(entity, 255, 255, 255, 0);
    } else
    {
        SetEntityRenderColor(entity, 255, 255, 255, 255);
        SetEntityRenderMode(entity, RENDER_NORMAL);
    }
}

bool:IsHiddenEntity(entity)
{
    return g_bHiddenEntities[entity];
}

stock bool:IsDisguised(client)
{
    if(!IsValidClient(client)) return false;
    new class = GetEntProp(client, Prop_Send, "m_nDisguiseClass");
    return (class != 0);
}

Action:ActionApply(Action:aPrevious, Action:aNew)
{
    if(aNew != Plugin_Continue) aPrevious = aNew;
    return aPrevious;
}

stock GetClientPointPosition(client, Float:fEyePos[3], mask = MASK_PLAYERSOLID)
{
    decl Float:fEyeAngle[3];
    GetClientEyePosition(client, fEyePos);
    GetClientEyeAngles(client, fEyeAngle);
    TR_TraceRayFilter(fEyePos, fEyeAngle, MASK_PLAYERSOLID, RayType_Infinite, TraceRayDontHitEntity, client);
    
    if(TR_DidHit(INVALID_HANDLE))
    {
        TR_GetEndPosition(fEyePos);
    }
}

stock Float:GetEntityLife(entity)
{
    return GetEngineTime() - g_fEntityCreateTime[entity];
}

stock any:AttachParticle(ent, String:particleType[], Float:time = 0.0, Float:addPos[3]=NULL_VECTOR, Float:addAngle[3]=NULL_VECTOR, bool:bShow = true, String:strVariant[] = "", bool:bMaintain = false)
{
    new particle = CreateEntityByName("info_particle_system");
    if(IsValidEdict(particle))
    {
        new Float:pos[3];
        new Float:ang[3];
        decl String:tName[32];
        GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
        AddVectors(pos, addPos, pos);
        GetEntPropVector(ent, Prop_Send, "m_angRotation", ang);
        AddVectors(ang, addAngle, ang);

        Format(tName, sizeof(tName), "target%i", ent);
        DispatchKeyValue(ent, "targetname", tName);

        TeleportEntity(particle, pos, ang, NULL_VECTOR);
        DispatchKeyValue(particle, "targetname", "tf2particle");
        DispatchKeyValue(particle, "parentname", tName);
        DispatchKeyValue(particle, "effect_name", particleType);
        DispatchSpawn(particle);
        SetEntPropEnt(particle, Prop_Send, "m_hOwnerEntity", ent);
        if(bShow)
        {
            SetVariantString(tName);
        } else
        {
            SetVariantString("!activator");
        }
        AcceptEntityInput(particle, "SetParent", ent, particle, 0);
        if(!StrEqual(strVariant, ""))
        {
            SetVariantString(strVariant);
            if(bMaintain) AcceptEntityInput(particle, "SetParentAttachmentMaintainOffset", ent, particle, 0);
            else AcceptEntityInput(particle, "SetParentAttachment", ent, particle, 0);
        }
        ActivateEntity(particle);
        AcceptEntityInput(particle, "start");
        if(time > 0.0) CreateTimer(time, RemoveParticle, particle);
    }
    else LogError("AttachParticle: could not create info_particle_system");
    return particle;
}

public Action:RemoveParticle(Handle:timer, any:particle)
{
    if(particle >= 0 && IsValidEntity(particle))
    {
        new String:classname[32];
        GetEdictClassname(particle, classname, sizeof(classname));
        if(StrEqual(classname, "info_particle_system", false))
        {
            AcceptEntityInput(particle, "Stop");
            AcceptEntityInput(particle, "Kill");
            AcceptEntityInput(particle, "Deactivate");
            particle = -1;
        }
    }
}

stock bool:IsClassname(entity, String:strClassname[])
{
    if(entity <= 0) return false;
    if(!IsValidEdict(entity)) return false;
    
    decl String:strClassname2[32];
    GetEdictClassname(entity, strClassname2, sizeof(strClassname2));
    if(!StrEqual(strClassname, strClassname2, false)) return false;
    
    return true;
}

stock AnglesToVelocity(Float:fAngle[3], Float:fVelocity[3], Float:fSpeed = 1.0)
{
    fVelocity[0] = Cosine(DegToRad(fAngle[1]));
    fVelocity[1] = Sine(DegToRad(fAngle[1]));
    fVelocity[2] = Sine(DegToRad(fAngle[0])) * -1.0;
    
    NormalizeVector(fVelocity, fVelocity);
    
    ScaleVector(fVelocity, fSpeed);
}

public bool:TraceRayDontHitEntity(entity, contentsMask, any:data)
{
    return (entity != data);
}

public bool:TraceRayDontHitPlayers(entity, mask)
{
    if(IsValidClient(entity)) return false;
    
    return true;
}

stock bool:IsEntityBuilding(entity)
{
    if(entity <= 0) return false;
    if(!IsValidEdict(entity)) return false;
    if(IsClassname(entity, "obj_sentrygun")) return true;
    if(IsClassname(entity, "obj_dispenser")) return true;
    if(IsClassname(entity, "obj_teleporter")) return true;
    return false;
}

stock bool:IsAfterDamage(damageType)
{
    if(damageType == TF_DMG_BLEED) return true;
    if(damageType == TF_DMG_AFTERBURN) return true;
    
    return false;
}

stock bool:IsDamageTypeCrit(damageType)
{
    return (damageType & TF_DMG_CRIT == TF_DMG_CRIT);
}

stock bool:HasFastDownload()
{
    // if for whatever reason these are invalid, its pretty certain the fastdl isn't working
    if(g_hAllowDownloads == INVALID_HANDLE || g_hDownloadUrl == INVALID_HANDLE)
    {
        return false;
    }
    
    // if sv_allowdownload 0, fastdl is disabled
    if(!GetConVarBool(g_hAllowDownloads))
    {
        return false;
    }
    
    // if sv_downloadurl isn't set, the fastdl isn't enabled properly
    decl String:strUrl[PLATFORM_MAX_PATH];
    GetConVarString(g_hDownloadUrl, strUrl, sizeof(strUrl));
    if(StrEqual(strUrl, ""))
    {
        return false;
    }
    
    return true;
}

stock GetOwner(entity)
{
    if(IsClassname(entity, "tf_projectile_pipe")) return GetEntPropEnt(entity, Prop_Send, "m_hThrower");
    if(IsClassname(entity, "tf_projectile_pipe_remote")) return GetEntPropEnt(entity, Prop_Send, "m_hThrower");
    return GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
}

stock GetFlamethrowerStrength(client)
{
    if(!IsValidClient(client)) return 0;
    if(!IsPlayerAlive(client)) return 0;
    new iEntity = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
    if(!IsClassname(iEntity, "tf_weapon_flamethrower")) return 0;
    
    new strength = GetEntProp(iEntity, Prop_Send, "m_iActiveFlames");
    return strength;
}

stock GetVelocity(client, Float:vVector[3])
{
    GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVector);
}

stock GetClientSlot(client)
{
    if(!IsValidClient(client)) return -1;
    if(!IsPlayerAlive(client)) return -1;
    
    decl String:strActiveWeapon[32];
    GetClientWeapon(client, strActiveWeapon, sizeof(strActiveWeapon));
    new slot = GetWeaponSlot(strActiveWeapon);
    return slot;
}

public Action:OnWeaponReload(weapon)
{
    if(!HasAttribute[weapon]) return Plugin_Continue;
    if(!NoReloading[weapon]) return Plugin_Continue;
    
    return Plugin_Handled;
}

public OnEntityCreated(entity, const String:strClassname[])
{
    if(!IsValidEntity(entity)) return;
    
    Attributes_EntityCreated(entity, String:strClassname);
}

public Attributes_EntityCreated(entity, const String:strClassname[])
{
    if(entity <= 0) return;
    if(!IsValidEdict(entity)) return;
    
    g_iEntitySlot[entity] = -1;
    g_fEntityCreateTime[entity] = GetEngineTime();
    
    SDKHookEx(entity, SDKHook_Reload, OnWeaponReload);
    
    if(StrContains(strClassname, "tf_projectile_", false) >= 0 && !StrEqual(strClassname, "tf_projectile_syringe"))
    {
        SDKHook(entity, SDKHook_StartTouch, ProjectileStartTouch);
        SDKHook(entity, SDKHook_Think, ProjectilePreThink);
        
        CreateTimer(0.0, Attributes_ProjCreatedPost, entity);
    }
    
    Attribute_1040_EntityCreated(entity);
}

stock PrecacheParticle(String:strName[])
{
    if(IsValidEntity(0))
    {
        new particle = CreateEntityByName("info_particle_system");
        if(IsValidEdict(particle))
        {
            new String:tName[32];
            GetEntPropString(0, Prop_Data, "m_iName", tName, sizeof(tName));
            DispatchKeyValue(particle, "targetname", "tf2particle");
            DispatchKeyValue(particle, "parentname", tName);
            DispatchKeyValue(particle, "effect_name", strName);
            DispatchSpawn(particle);
            SetVariantString(tName);
            AcceptEntityInput(particle, "SetParent", 0, particle, 0);
            ActivateEntity(particle);
            AcceptEntityInput(particle, "start");
            CreateTimer(0.01, RemoveParticle, particle);
        }
    }
}

stock SuperPrecacheSound(String:strPath[], String:strPluginName[] = "")
{
    if(strlen(strPath) == 0) return;
    
    PrecacheSound(strPath, true);
    decl String:strBuffer[PLATFORM_MAX_PATH];
    Format(strBuffer, sizeof(strBuffer), "sound/%s", strPath);
    AddFileToDownloadsTable(strBuffer);

    if(!FileExists(strBuffer) && !FileExists(strBuffer, true))
    {
        if(StrEqual(strPluginName, "")) LogError("PRECACHE ERROR: Unable to precache sound at '%s'. No fastdl service detected, and file is not on the server.", strPath);
        else LogError("PRECACHE ERROR: Unable to precache sound at '%s'. No fastdl service detected, and file is not on the server. It was required by the plugin '%s'", strPath, strPluginName);
    }
}

stock SuperPrecacheModel(String:strModel[], bool:bRequiredOnServer = false, bool:bMdlOnly = false)
{
    decl String:strBase[PLATFORM_MAX_PATH];
    decl String:strPath[PLATFORM_MAX_PATH];
    Format(strBase, sizeof(strBase), strModel);
    SplitString(strBase, ".mdl", strBase, sizeof(strBase));
    
    if(!bMdlOnly)
    {
        Format(strPath, sizeof(strPath), "%s.phy", strBase);
        if(FileExists(strPath)) AddFileToDownloadsTable(strPath);
        
        Format(strPath, sizeof(strPath), "%s.sw.vtx", strBase);
        if(FileExists(strPath)) AddFileToDownloadsTable(strPath);
        
        Format(strPath, sizeof(strPath), "%s.vvd", strBase);
        if(FileExists(strPath)) AddFileToDownloadsTable(strPath);
        
        Format(strPath, sizeof(strPath), "%s.dx80.vtx", strBase);
        if(FileExists(strPath)) AddFileToDownloadsTable(strPath);
        
        Format(strPath, sizeof(strPath), "%s.dx90.vtx", strBase);
        if(FileExists(strPath)) AddFileToDownloadsTable(strPath);
    }
    
    AddFileToDownloadsTable(strModel);
    
    if(HasFastDownload())
    {
        if(bRequiredOnServer && !FileExists(strModel) && !FileExists(strModel, true))
        {
            LogError("PRECACHE ERROR: Unable to precache REQUIRED model '%s'. File is not on the server.", strModel);
        }
    }
    
    return PrecacheModel(strModel, true);
}

new g_iProjectileBounces[MAX_EDICTS+1] = 0;

Attribute_1040_EntityCreated(entity)
{
    g_iProjectileBounces[entity] = 0;
}

public Action:ProjectileStartTouch(entity, other)
{
    new owner = GetOwner(entity);
    if(!IsValidClient(owner)) return Plugin_Continue;
    
    new Action:aReturn = Plugin_Continue;
    
    aReturn = ActionApply(aReturn, Attribute_1040_PStartTouch(entity, other, owner, g_iEntitySlot[entity]));

    return aReturn;
}

public Action:Attributes_ProjCreatedPost(Handle:hTimer, any:entity)
{
    if(!IsValidEdict(entity)) return Plugin_Continue;
    
    decl String:strClassname[255];
    GetEdictClassname(entity, strClassname, sizeof(strClassname));
    if(StrEqual(strClassname, "tf_projectile_syringe")) return Plugin_Continue;
    if(StrContains(strClassname, "tf_projectile_", false) < 0) return Plugin_Continue;
    
    new owner = GetOwner(entity);
    if(IsValidClient(owner))
    {
        new slot = GetClientSlot(owner);
        g_iEntitySlot[entity] = slot;
    }
    
    return Plugin_Continue;
}

public Action:Attribute_1040_PStartTouch(entity, other, owner, slot)
{
    new weapon = GetPlayerWeaponSlot(owner, slot);
    if(weapon == -1) return Plugin_Continue;
    if(!HasAttribute[weapon]) return Plugin_Continue;
    if(!ProjectilesBounce[weapon]) return Plugin_Continue;
    if(IsValidClient(other)) return Plugin_Continue;
    if(IsEntityBuilding(other)) return Plugin_Continue;
    
    new total = RoundFloat(ProjectilesBounce_Count[weapon]);
    if(g_iProjectileBounces[entity] >= total) return Plugin_Continue;
    SDKHook(entity, SDKHook_Touch, Attribute_1040_OnTouchBounce);
    g_iProjectileBounces[entity]++;
    
    return Plugin_Handled;
}

public Action:Attribute_1040_OnTouchBounce(entity, other)
{    
    decl Float:vOrigin[3];
    GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vOrigin);
    
    decl Float:vAngles[3];
    GetEntPropVector(entity, Prop_Data, "m_angRotation", vAngles);
    
    decl Float:vVelocity[3];
    GetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", vVelocity);
    
    new Handle:hTrace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceRayDontHitEntity, entity);
    
    if(!TR_DidHit(hTrace))
    {
        CloseHandle(hTrace);
        return Plugin_Continue;
    }
    
    decl Float:vNormal[3];
    TR_GetPlaneNormal(hTrace, vNormal);
    
    CloseHandle(hTrace);
    
    new Float:dotProduct = GetVectorDotProduct(vNormal, vVelocity);
    
    ScaleVector(vNormal, dotProduct);
    ScaleVector(vNormal, 2.0);
    
    decl Float:vBounceVec[3];
    SubtractVectors(vVelocity, vNormal, vBounceVec);
    
    decl Float:vNewAngles[3];
    GetVectorAngles(vBounceVec, vNewAngles);
    
    TeleportEntity(entity, NULL_VECTOR, vNewAngles, vBounceVec);

    SDKUnhook(entity, SDKHook_Touch, Attribute_1040_OnTouchBounce);
    return Plugin_Handled;
}

public Action:Attributes_RocketJump(Handle:hEvent, String:strName[], bool:bDontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
    if(!IsValidClient(client)) return Plugin_Continue;
    if(!IsValidTeam(client)) return Plugin_Continue;
    if(!IsPlayerAlive(client)) return Plugin_Continue;
    if(g_bRocketJumping[client]) return Plugin_Continue;
    
    g_bRocketJumping[client] = true;
    
    return Plugin_Continue;
}

public Action:Attributes_RocketJumpLand(Handle:hEvent, String:strName[], bool:bDontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
    if(!IsValidClient(client)) return Plugin_Continue;
    if(!IsValidTeam(client)) return Plugin_Continue;
    if(!IsPlayerAlive(client)) return Plugin_Continue;
    if(!g_bRocketJumping[client]) return Plugin_Continue;
    
    new slot = GetClientSlot(client);
    
    Attribute_1026_RocketJumpLand(client, slot);
    
    g_bRocketJumping[client] = false;
    
    return Plugin_Continue;
}

stock GetWeaponSlot(String:strWeapon[])
{
    // Scout
    if(StrEqual(strWeapon, "soda_popper")) return 0;
    if(StrEqual(strWeapon, "tf_weapon_soda_popper")) return 0;
    if(StrEqual(strWeapon, "tf_weapon_scattergun")) return 0;
    if(StrEqual(strWeapon, "scattergun")) return 0;
    if(StrEqual(strWeapon, "force_a_nature")) return 0;
    if(StrEqual(strWeapon, "tf_weapon_handgun_scout_primary")) return 0;
    if(StrEqual(strWeapon, "tf_weapon_pep_brawler_blaster")) return 0;
    if(StrEqual(strWeapon, "handgun_scout_secondary")) return 1;
    if(StrEqual(strWeapon, "tf_weapon_handgun_scout_secondary")) return 1;
    if(StrEqual(strWeapon, "tf_weapon_pistol_scout")) return 1;
    if(StrEqual(strWeapon, "pistol_scout")) return 1;
    if(StrEqual(strWeapon, "tf_weapon_lunchbox_drink")) return 1;
    if(StrEqual(strWeapon, "tf_weapon_jar_milk")) return 1;
    if(StrEqual(strWeapon, "tf_weapon_bat_wood")) return 2;
    if(StrEqual(strWeapon, "tf_weapon_bat_giftwrap")) return 2;
    if(StrEqual(strWeapon, "bat_giftwrap")) return 2;
    if(StrEqual(strWeapon, "ball")) return 2;
    if(StrEqual(strWeapon, "bat_wood")) return 2;
    if(StrEqual(strWeapon, "bat")) return 2;
    if(StrEqual(strWeapon, "tf_weapon_bat")) return 2;
    if(StrEqual(strWeapon, "taunt_scout")) return 2;
    if(StrEqual(strWeapon, "tf_weapon_bat_fish")) return 2;
    if(StrEqual(strWeapon, "bat_fish")) return 2;
    if(StrEqual(strWeapon, "saxxy")) return 2;
    if(StrEqual(strWeapon, "tf_weapon_bat_giftwrap")) return 2;
    
    // Soldier
    if(StrEqual(strWeapon, "tf_weapon_rocketlauncher")) return 0;
    if(StrEqual(strWeapon, "tf_weapon_particle_cannon")) return 0;
    if(StrEqual(strWeapon, "particle_cannon")) return 0;
    if(StrEqual(strWeapon, "tf_projectile_energy_ring")) return 0;
    if(StrEqual(strWeapon, "energy_ring")) return 0;
    if(StrEqual(strWeapon, "tf_projectile_rocket")) return 0;
    if(StrEqual(strWeapon, "tf_weapon_rocketlauncher_directhit")) return 0;
    if(StrEqual(strWeapon, "rocketlauncher_directhit")) return 0;
    if(StrEqual(strWeapon, "tf_projectile_energy_ball")) return 1;
    if(StrEqual(strWeapon, "energy_ball")) return 1;
    if(StrEqual(strWeapon, "tf_weapon_shotgun_soldier")) return 1;
    if(StrEqual(strWeapon, "tf_weapon_raygun")) return 1;
    if(StrEqual(strWeapon, "raygun")) return 1;
    if(StrEqual(strWeapon, "shotgun_soldier")) return 1;
    if(StrEqual(strWeapon, "tf_weapon_buff_item")) return 1;
    if(StrEqual(strWeapon, "tf_weapon_shovel")) return 2;
    if(StrEqual(strWeapon, "shovel")) return 2;
    if(StrEqual(strWeapon, "pickaxe")) return 2;
    if(StrEqual(strWeapon, "tf_weapon_katana")) return 2;
    if(StrEqual(strWeapon, "demokatana")) return 2;
    if(StrEqual(strWeapon, "katana")) return 2;
    if(StrEqual(strWeapon, "taunt_soldier")) return 2;
    
    // Pyro
    if(StrEqual(strWeapon, "tf_weapon_drg_pomson")) return 0;
    if(StrEqual(strWeapon, "drg_pomson")) return 0;
    if(StrEqual(strWeapon, "tf_weapon_flamethrower")) return 0;
    if(StrEqual(strWeapon, "flamethrower")) return 0;
    if(StrEqual(strWeapon, "tf_weapon_flaregun_revenge")) return 1;
    if(StrEqual(strWeapon, "flaregun_revenge")) return 1;
    if(StrEqual(strWeapon, "tf_weapon_flaregun")) return 1;
    if(StrEqual(strWeapon, "flaregun")) return 1;
    if(StrEqual(strWeapon, "taunt_pyro")) return 1;
    if(StrEqual(strWeapon, "shotgun_pyro")) return 1;
    if(StrEqual(strWeapon, "tf_weapon_shotgun_pyro")) return 1;
    if(StrEqual(strWeapon, "tf_weapon_fireaxe")) return 2;
    if(StrEqual(strWeapon, "fireaxe")) return 2;
    if(StrEqual(strWeapon, "axtinguisher")) return 2;
    if(StrEqual(strWeapon, "firedeath")) return -2;
    if(StrEqual(strWeapon, "tf_weapon_flaregun_revenge")) return 1;
    
    // Demoman
    if(StrEqual(strWeapon, "tf_projectile_pipe")) return 0;
    if(StrEqual(strWeapon, "tf_weapon_grenadelauncher")) return 0;
    if(StrEqual(strWeapon, "tf_weapon_cannon")) return 0;
    if(StrEqual(strWeapon, "loose_cannon_impact")) return 0;
    if(StrEqual(strWeapon, "loose_cannon")) return 0;
    if(StrEqual(strWeapon, "tf_weapon_pipebomblauncher")) return 1;
    if(StrEqual(strWeapon, "tf_projectile_pipe_remote")) return 1;
    if(StrEqual(strWeapon, "sticky_resistance")) return 1;
    if(StrEqual(strWeapon, "tf_wearable_demoshield")) return 1;
    if(StrEqual(strWeapon, "wearable_demoshield")) return 1;
    if(StrEqual(strWeapon, "demoshield")) return 1;
    if(StrEqual(strWeapon, "tf_weapon_bottle")) return 2;
    if(StrEqual(strWeapon, "bottle")) return 2;
    if(StrEqual(strWeapon, "tf_weapon_sword")) return 2;
    if(StrEqual(strWeapon, "tf_weapon_stickbomb")) return 2;
    if(StrEqual(strWeapon, "stickbomb")) return 2;
    if(StrEqual(strWeapon, "sword")) return 2;
    if(StrEqual(strWeapon, "taunt_demoman")) return 2;
    
    // Heavy
    if(StrEqual(strWeapon, "tf_weapon_minigun")) return 0;
    if(StrEqual(strWeapon, "minigun")) return 0;
    if(StrEqual(strWeapon, "natascha")) return 0;
    if(StrEqual(strWeapon, "brass_beast")) return 0;
    if(StrEqual(strWeapon, "tf_weapon_shotgun_hwg")) return 1;
    if(StrEqual(strWeapon, "shotgun_hwg")) return 1;
    if(StrEqual(strWeapon, "tf_weapon_lunchbox")) return 1;
    if(StrEqual(strWeapon, "tf_weapon_fists")) return 2;
    if(StrEqual(strWeapon, "fists")) return 2;
    if(StrEqual(strWeapon, "taunt_heavy")) return 2;
    if(StrEqual(strWeapon, "gloves")) return 2;
    
    // Engineer
    if(StrEqual(strWeapon, "tf_weapon_shotgun_primary")) return 0;
    if(StrEqual(strWeapon, "shotgun_primary")) return 0;
    if(StrEqual(strWeapon, "taunt_guitar_kill")) return 0;
    if(StrEqual(strWeapon, "frontier_kill")) return 0;
    if(StrEqual(strWeapon, "tf_weapon_sentry_revenge")) return 0;
    if(StrEqual(strWeapon, "tf_weapon_shotgun_building_rescue")) return 0;
    if(StrEqual(strWeapon, "the_rescue_ranger")) return 0;
    if(StrEqual(strWeapon, "tf_weapon_laser_pointer")) return 1;
    if(StrEqual(strWeapon, "wrangler_kill")) return 1;
    if(StrEqual(strWeapon, "tf_weapon_pistol")) return 1;
    if(StrEqual(strWeapon, "tf_weapon_mechanical_arm")) return 1;
    if(StrEqual(strWeapon, "mechanical_arm")) return 1;
    if(StrEqual(strWeapon, "pistol")) return 1;
    if(StrEqual(strWeapon, "tf_weapon_wrench")) return 2;
    if(StrEqual(strWeapon, "wrench")) return 2;
    if(StrEqual(strWeapon, "tf_weapon_robot_arm")) return 2;
    if(StrEqual(strWeapon, "robot_arm_combo_kill")) return 2;
    if(StrEqual(strWeapon, "robot_arm_kill")) return 2;
    if(StrEqual(strWeapon, "robot_arm_blender_kill")) return 2;
    if(StrEqual(strWeapon, "tf_weapon_pda_engineer_build")) return 3;
    if(StrEqual(strWeapon, "tf_weapon_pda_engineer_destroy")) return 4;
    if(StrEqual(strWeapon, "tf_weapon_drg_pomson")) return 0;
    
    if(StrEqual(strWeapon, "obj_sentrygun")) return 9;
    if(StrEqual(strWeapon, "sentrygun")) return 9;
    
    // Medic
    if(StrEqual(strWeapon, "tf_weapon_syringegun_medic")) return 0;
    if(StrEqual(strWeapon, "syringegun_medic")) return 0;
    if(StrEqual(strWeapon, "tf_weapon_medigun")) return 1;
    if(StrEqual(strWeapon, "tf_weapon_bonesaw")) return 2;
    if(StrEqual(strWeapon, "bonesaw")) return 2;
    if(StrEqual(strWeapon, "ubersaw")) return 2;
    if(StrEqual(strWeapon, "tf_weapon_crossbow")) return 0;
    
    // Sniper
    if(StrEqual(strWeapon, "tf_weapon_compound_bow")) return 0;
    if(StrEqual(strWeapon, "tf_projectile_arrow")) return 0;
    if(StrEqual(strWeapon, "projectile_arrow")) return 0;
    if(StrEqual(strWeapon, "arrow")) return 0;
    if(StrEqual(strWeapon, "taunt_sniper")) return 0;
    if(StrEqual(strWeapon, "huntsman")) return 0;
    if(StrEqual(strWeapon, "tf_weapon_sniperrifle")) return 0;
    if(StrEqual(strWeapon, "sniperrifle")) return 0;
    if(StrEqual(strWeapon, "tf_weapon_smg")) return 1;
    if(StrEqual(strWeapon, "smg")) return 1;
    if(StrEqual(strWeapon, "tf_weapon_jar")) return 1;
    if(StrEqual(strWeapon, "tf_weapon_club")) return 2;
    if(StrEqual(strWeapon, "club")) return 2;
    
    // Spy
    if(StrEqual(strWeapon, "tf_weapon_revolver", false)) return 0;
    if(StrEqual(strWeapon, "revolver", false)) return 0;
    if(StrEqual(strWeapon, "ambassador", false)) return 0;
    if(StrEqual(strWeapon, "tf_weapon_pda_spy", false)) return 1;
    if(StrEqual(strWeapon, "tf_weapon_knife", false)) return 2;
    if(StrEqual(strWeapon, "knife", false)) return 2;
    if(StrEqual(strWeapon, "taunt_spy", false)) return 2;
    if(StrEqual(strWeapon, "tf_weapon_invis", false)) return 4;
    
    return -2;
}

stock bool:OnGround(client)
{
    return (GetEntityFlags(client) & FL_ONGROUND == FL_ONGROUND);
}

#define CONTROLLABLE_PROJECTILE_DELAY               0.05

Attribute_1018_OnProjectile(entity, &client, &slot)
{
    if(!IsValidClient(client)) return;
    
    new weapon = GetPlayerWeaponSlot(client, slot);
    if(weapon == -1) return;
    if(!HasAttribute[weapon]) return;
    if(!ControllableProjectiles[weapon]) return;
    
    new Float:fLife = GetEntityLife(entity);
    fLife -= CONTROLLABLE_PROJECTILE_DELAY;
    if(fLife < 0.0) return;
    
    decl Float:vRocketOrigin[3];
    GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vRocketOrigin);
    decl Float:vTargetOrigin[3];
    GetClientPointPosition(client, vTargetOrigin, MASK_VISIBLE);
    
    decl Float:vRocketVelocity[3];
    GetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", vRocketVelocity);
    new Float:fRocketSpeed = GetVectorLength(vRocketVelocity);
    
    decl Float:vDifference[3];
    SubtractVectors(vTargetOrigin, vRocketOrigin, vDifference);
    
    // middle += velocity
    // (aka becomes less accurate)
    new Float:fBase = ControllableProjectiles_Control[weapon];
    new Float:fInaccuracy = fBase - fLife*150.0;
    if(fInaccuracy < 0.0) fInaccuracy = 0.0;
    if(fInaccuracy > 400.0) fInaccuracy = 400.0;
    NormalizeVector(vDifference, vDifference);
    ScaleVector(vDifference, fInaccuracy);
    
    AddVectors(vRocketVelocity, vDifference, vDifference);
    NormalizeVector(vDifference, vDifference);
    
    decl Float:fRocketAngle[3];
    GetVectorAngles(vDifference, fRocketAngle);
    SetEntPropVector(entity, Prop_Data, "m_angRotation", fRocketAngle);
    
    ScaleVector(vDifference, fRocketSpeed);
    SetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", vDifference);
}

Attribute_1056_OnProjectile(entity, &client, &slot)
{
    if(!IsClassname(entity, "tf_projectile_flare")) return;
    
    decl Float:vOrigin[3];
    GetEntityOrigin(entity, vOrigin);
    
    Attribute_1056_IgniteLeak(vOrigin);
}

stock DealDamage(victim, damage, attacker=0,iDmgType=TF_DMG_BULLET, String:strWeapon[]="")
{
    if(IsValidClient(victim) && damage > 0)
    {
        decl String:strDamage[16];
        IntToString(damage, strDamage, 16);
        decl String:strDamageType[32];
        IntToString(iDmgType, strDamageType, 32);
        new hurt = CreateEntityByName("point_hurt");
        if(hurt > 0)
        {
            DispatchKeyValue(victim,"targetname","infectious_hurtme");
            DispatchKeyValue(hurt,"DamageTarget","infectious_hurtme");
            DispatchKeyValue(hurt,"Damage",strDamage);
            DispatchKeyValue(hurt,"DamageType",strDamageType);
            if(!StrEqual(strWeapon, ""))
            {
                DispatchKeyValue(hurt,"classname", strWeapon);
            }
            DispatchSpawn(hurt);
            AcceptEntityInput(hurt,"Hurt", attacker);
            DispatchKeyValue(hurt,"classname","point_hurt");
            DispatchKeyValue(victim,"targetname","infectious_donthurtme");
            RemoveEdict(hurt);
        }
    }
}

stock GetEntityOrigin(entity, Float:vVector[3])
{
    GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vVector);
}

stock Shake(client)
{    
    new flags = GetCommandFlags("shake") & (~FCVAR_CHEAT);
    SetCommandFlags("shake", flags);

    FakeClientCommand(client, "shake");
    
    flags = GetCommandFlags("shake") | (FCVAR_CHEAT);
    SetCommandFlags("shake", flags);
}

stock EmitSoundFromOrigin(const String:sound[],const Float:orig[3])
{
    EmitSoundToAll(sound,SOUND_FROM_WORLD,SNDCHAN_AUTO,SNDLEVEL_NORMAL,SND_NOFLAGS,SNDVOL_NORMAL,SNDPITCH_NORMAL,-1,orig,NULL_VECTOR,true,0.0);
}

new Float:g_f1026LastLand[MAXPLAYERS+1] = 0.0;

Attribute_1026_RocketJumpLand(client, slot)
{
    new weapon = GetPlayerWeaponSlot(client, slot);
    if(weapon == -1) return;
    if(!HasAttribute[weapon]) return;
    if(!Earthquake[weapon]) return;
    
    new Float:fPushMax = ATTRIBUTE_1026_PUSHMAX;
    
    new Float:fDistance;
    
    decl Float:vClientPos[3];
    GetClientAbsOrigin(client, vClientPos);
    decl Float:vVictimPos[3];
    decl Float:vPush[3];
    
    new team = GetClientTeam(client);
    
    EmitSoundFromOrigin(SOUND_EXPLOSION_BIG, vClientPos);
    TE_SetupExplosion(vClientPos, g_iExplosionSprite, 10.0, 1, 0, 0, 750);
    TE_SendToAll();
    TE_SetupBeamRingPoint(vClientPos, 10.0, ATTRIBUTE_1026_DISTANCE_LIMIT, g_iWhite, g_iHaloSprite, 0, 10, 0.2, 10.0, 0.5, g_teamColorSoft[team], 50, 0);
    TE_SendToAll();
    
    Shake(client);
    
    for(new iVictim = 0; iVictim <= MaxClients; iVictim++)
    {
        if(IsValidClient(iVictim) && IsPlayerAlive(iVictim) && team != GetClientTeam(iVictim) && OnGround(iVictim))
        {
            GetClientAbsOrigin(iVictim, vVictimPos);
            fDistance = GetVectorDistance(vVictimPos, vClientPos);
            if(fDistance <= ATTRIBUTE_1026_DISTANCE_LIMIT)
            {
                if(GetEngineTime() <= g_f1026LastLand[client] + ATTRIBUTE_1026_COOLDOWN) return;
                SubtractVectors(vVictimPos, vClientPos, vPush);
                new Float:fPushScale = (ATTRIBUTE_1026_DISTANCE_LIMIT - fDistance)*ATTRIBUTE_1026_PUSHSCALE;
                if(fPushScale > fPushMax) fPushScale = fPushMax;
                ScaleVector(vPush, fPushScale);
                Shake(iVictim);
                if(vPush[2] < 400.0) vPush[2] = 400.0;
                TeleportEntity(iVictim, NULL_VECTOR, NULL_VECTOR, vPush);
                g_f1026LastLand[client] = GetEngineTime();
            }
        }
    }
}

Attribute_1087_Prethink(client, &buttons, &slot, &buttonsLast)
{
    new weapon = GetPlayerWeaponSlot(client, slot);
    if(weapon == -1) return buttons;
    if(!HasAttribute[weapon]) return buttons;
    if(AttackWhileCloaked[weapon] && (buttons & IN_ATTACK == IN_ATTACK))
    {
        new Float:flTime = GetGameTime();
        if(TF2_IsPlayerInCondition(client, TFCond_Cloaked))
        {
            TF2_RemoveCondition(client, TFCond_Cloaked);
            SetEntPropFloat(client, Prop_Send, "m_flNextAttack", flTime);
        }
        SetEntPropFloat(client, Prop_Send, "m_flStealthNoAttackExpire", flTime);
        SetEntPropFloat(client, Prop_Send, "m_flInvisChangeCompleteTime", flTime);
    }

    return buttons;
}

public OnClientPutInServer(client)
{
    SDKHook(client, SDKHook_OnTakeDamage, Attributes_OnTakeDamage);
    SDKHook(client, SDKHook_PreThink, OnClientPreThink);
}

public Attributes_PreThink(client)
{
    if(!IsPlayerAlive(client)) return;
    
    new buttonsLast = g_iLastButtons[client];
    new buttons = GetClientButtons(client);
    new buttons2 = buttons;
    
    new Handle:hArray = CreateArray();
    new slot = GetClientSlot(client);
    if(slot >= 0) PushArrayCell(hArray, slot);
    PushArrayCell(hArray, 4);
    
    new slot2;
    for(new i = 0; i < GetArraySize(hArray); i++)
    {
        slot2 = GetArrayCell(hArray, i);
        buttons = Attribute_1034_Prethink(client, buttons, slot2, buttonsLast);
        buttons = Attribute_1056_Prethink(client, buttons, slot2, buttonsLast);
        buttons = Attribute_1087_Prethink(client, buttons, slot2, buttonsLast);
    }
    CloseHandle(hArray);
    
    slot2 = -1;
    
    for(slot2 = 0; slot2 <= SLOTS_MAX; slot2++)
    {
        
    }

    if(buttons != buttons2) SetEntProp(client, Prop_Data, "m_nButtons", buttons);    
    g_iLastButtons[client] = buttons;
    
    g_bWasDisguised[client] = IsDisguised(client);
}

public OnClientPreThink(client)
{
    Attributes_PreThink(client);
    FastCloakThink(client);
}

stock bool:CanRecieveDamage(client)
{
    if(!IsValidClient(client)) return false;
    if(!IsValidTeam(client)) return false;
    if(TF2_IsPlayerInCondition(client, TFCond_Ubercharged)) return false;
    
    return true;
}

public ProjectilePreThink(entity)
{
    if(!IsValidEdict(entity)) return;
    
    new client = GetOwner(entity);
    new slot = g_iEntitySlot[entity];
    
    Attribute_1018_OnProjectile(entity, client, slot);
    Attribute_1056_OnProjectile(entity, client, slot);
}

Attribute_1056_Prethink(client, &buttons, &slot, &buttonsLast)
{
    new weapon = GetPlayerWeaponSlot(client, slot);
    if(weapon == -1) return buttons;
    if(!HasAttribute[weapon]) return buttons;
    if(AltFireIsOil[weapon])
    {
        if(buttons & IN_ATTACK2 == IN_ATTACK2)
        {
            Attribute_1056_OilLeak(client, slot);
            if(GetClientTeam(client) == TEAM_SPEC)
            {
                return buttons;
            }
        }
    }
    
    if(GetFlamethrowerStrength(client) >= 2)
    {
        decl Float:vOrigin[3];
        GetClientAbsOrigin(client, vOrigin);
        Attribute_1056_IgniteLeak(vOrigin);
    }
    
    new attacker = g_iOilLeakDamageOwner[client];
    if(IsValidClient(attacker))
    {
        DealDamage(client, 2 + RoundFloat(g_iOilLeakDamage[client] * 1.5), attacker, TF_DMG_FIRE, "firedeath");
        g_iOilLeakDamage[client] += 2;
    } else
    {
        g_iOilLeakDamage[client] -= 4;
        if(g_iOilLeakDamage[client] < 0) g_iOilLeakDamage[client] = 0;
    }
    g_iOilLeakDamageOwner[client] = -1;
    
    return buttons;
}

Attribute_1056_OilLeak(client, slot)
{
    if(g_fOilLeakDelay[client] >= GetEngineTime() - ATTRIBUTE_FIRELEAK_TIME) return;
    if(!SubtractWeaponAmmo(client, slot, ATTRIBUTE_FIRELEAK_COST)) return;
    
    g_fOilLeakDelay[client] = GetEngineTime();
    if(GetPlayerWeaponSlot(client, slot) == -1) return;
    new weapon = GetPlayerWeaponSlot(client, slot);
    if(!HasAttribute[weapon]) return;
    if(AltFireIsOil[weapon])
        EmitSoundToAll(SOUND_FIRELEAK_OIL, client, SNDCHAN_WEAPON, _, SND_CHANGEVOL|SND_CHANGEPITCH, 1.0, GetRandomInt(60, 140));
    
    if(g_hOilLeakEntities == INVALID_HANDLE) g_hOilLeakEntities = CreateArray();
    
    new entity = CreateEntityByName("prop_physics_override");
    if(IsValidEdict(entity))
    {
        SetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity", client);
        SetEntityModel(entity, MODEL_DEFAULTPHYSICS);
        DispatchSpawn(entity);
        
        AcceptEntityInput(entity, "DisableCollision");
        SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
        SetEntityRenderColor(entity, _, _, _, 0);
        
        decl String:strName[64];
        Format(strName, sizeof(strName), "tf2leak");
        DispatchKeyValue(entity, "targetname", strName);
        
        decl Float:fAngles[3], Float:fVelocity[3], Float:fOrigin[3];
        GetClientEyePosition(client, fOrigin);
        GetClientEyeAngles(client, fAngles);
        AnglesToVelocity(fAngles, fVelocity, 600.0);
        
        TeleportEntity(entity, fOrigin, fAngles, fVelocity);
        
        if(GetClientTeam(client) == TEAM_BLUE)
        {
            AttachParticle(entity, "peejar_trail_blu");
            AttachParticle(entity, "peejar_trail_blu");
            AttachParticle(entity, "peejar_trail_blu");
            AttachParticle(entity, "peejar_trail_blu");
            AttachParticle(entity, "peejar_trail_blu");
            AttachParticle(entity, "peejar_trail_blu");
            AttachParticle(entity, "peejar_trail_blu");
        }
        if(GetClientTeam(client) == TEAM_RED)
        {
            AttachParticle(entity, "peejar_trail_red");
            AttachParticle(entity, "peejar_trail_red");
            AttachParticle(entity, "peejar_trail_red");
            AttachParticle(entity, "peejar_trail_red");
            AttachParticle(entity, "peejar_trail_red");
            AttachParticle(entity, "peejar_trail_red");
            AttachParticle(entity, "peejar_trail_red");
        }
        
        g_fOilLeakLife[entity] = GetEngineTime() + 15.0;
        g_iOilLeakStatus[entity] = 0;
        
        PushArrayCell(g_hOilLeakEntities, entity);
    }
}

Attribute_1056_IgniteLeak(Float:vPos[3])
{
    decl Float:vOrigin[3];
    decl Float:vFire[3];
    for(new i = GetArraySize(g_hOilLeakEntities)-1; i >= 0; i--)
    {
        new iEntity = GetArrayCell(g_hOilLeakEntities, i);
        
        if(IsClassname(iEntity, "prop_physics"))
        {
            GetEntityOrigin(iEntity, vOrigin);
            new owner = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity");
            if(g_iOilLeakStatus[iEntity] == 1 && GetVectorDistance(vOrigin, vPos) / 50.0 <= 3.0)
            {
                g_iOilLeakStatus[iEntity] = 2;
                g_fOilLeakLife[iEntity] = GetEngineTime() + 5.0;
                Attribute_1056_IgniteLeak(vOrigin);
                vFire[2] = 5.0;
                
                vFire[0] = 22.0;
                vFire[1] = 22.0;
                AttachParticle(iEntity, PARTICLE_FIRE, _, vFire);
                
                vFire[0] = 22.0;
                vFire[1] = -22.0;
                AttachParticle(iEntity, PARTICLE_FIRE, _, vFire);
                
                vFire[0] = -22.0;
                vFire[1] = 22.0;
                AttachParticle(iEntity, PARTICLE_FIRE, _, vFire);
                
                vFire[0] = -22.0;
                vFire[1] = -22.0;
                AttachParticle(iEntity, PARTICLE_FIRE, _, vFire);
                
                vFire[0] = 0.0;
                vFire[1] = 0.0;
                AttachParticle(iEntity, PARTICLE_FIRE, _, vFire);
                
                new String:strParticle[255];
                if(GetClientTeam(owner) == TEAM_BLUE) Format(strParticle, sizeof(strParticle), "%s", PARTICLE_AREA_FIRE_BLUE);
                if(!StrEqual(strParticle, "")) AttachParticle(iEntity, strParticle, _, vFire);
            }
        }
    }
}

Attributes_1056_Think(bool:bTerminate = false)
{
    if(g_hOilLeakEntities == INVALID_HANDLE) return;
    
    new iClientLeaks[MAXPLAYERS+1] = 0;
    
    for(new i = GetArraySize(g_hOilLeakEntities)-1; i >= 0; i--)
    {
        new iEntity = GetArrayCell(g_hOilLeakEntities, i);
        new owner = Attribute_1056_OilThink(iEntity);
        if(bTerminate || owner < 0 || iClientLeaks[owner] > 15)
        {
            if(IsClassname(iEntity, "prop_physics")) AcceptEntityInput(iEntity, "kill");
            RemoveFromArray(g_hOilLeakEntities, i);
        } else
        {
            iClientLeaks[owner]++;
        }
    }
    
    if(bTerminate) CloseHandle(g_hOilLeakEntities);
}

Attribute_1056_OilThink(entity)
{
    if(!IsClassname(entity, "prop_physics")) return -1;
    
    new owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
    if(!IsValidClient(owner)) return -1;
    
    new Float:fLife = g_fOilLeakLife[entity];
    if(GetEngineTime() >= fLife) return -1;
    
    
    decl Float:vOrigin[3];
    GetEntityOrigin(entity, vOrigin);
    
    if(g_iOilLeakStatus[entity] == 0)
    {
        new Float:vAngleDown[3];
        vAngleDown[0] = 90.0;
        new Handle:hTrace = TR_TraceRayFilterEx(vOrigin, vAngleDown, MASK_PLAYERSOLID, RayType_Infinite, TraceRayDontHitPlayers);
        if(TR_DidHit(hTrace))
        {
            decl Float:vEnd[3];
            TR_GetEndPosition(vEnd, hTrace);
            if(GetVectorDistance(vEnd, vOrigin) / 50.0 <= 0.4)
            {
                new Float:vStop[3];
                SetEntityMoveType(entity, MOVETYPE_NONE);
                TeleportEntity(entity, vEnd, NULL_VECTOR, vStop);
                
                SetEntityRenderColor(entity, _, _, _, 255);
                SetEntityRenderMode(entity, RENDER_NONE);
                SetEntityModel(entity, MODEL_FIRELEAK);
                g_iOilLeakStatus[entity] = 1;
            }
        }
        CloseHandle(hTrace);
    }
    if(g_iOilLeakStatus[entity] == 2)
    {
        decl Float:vClientOrigin[3];
        for(new client = 0; client <= MaxClients; client++)
        {
            if(IsValidClient(client) && IsPlayerAlive(client) && (GetClientTeam(client) != GetClientTeam(owner) || client == owner))
            {
                GetClientAbsOrigin(client, vClientOrigin);
                if(GetVectorDistance(vOrigin, vClientOrigin) / 50.0 <= 1.5)
                {
                    g_iOilLeakDamageOwner[client] = owner;
                }
            }
        }
    }
    
    return owner;
}

Attribute_1034_Prethink(client, &buttons, slot, &buttonsLast)
{    
    new weapon = GetPlayerWeaponSlot(client, slot);
    if(weapon == -1) return buttons;
    
    if(!ItemIsHeavy[weapon]) return buttons;
    
    if(OnGround(client))
    {
        fAttribute_1034_Time[client] = 0.0;
    }
    if(GetEntityMoveType(client) != MOVETYPE_WALK) return buttons;
    
    decl Float:vVelocity[3];
    GetVelocity(client, vVelocity);
    
    fAttribute_1034_Time[client] += 0.1;
    if(fAttribute_1034_Time[client] > 1.0) fAttribute_1034_Time[client] = 1.0;
    
    new Float:fPush = ItemIsHeavy_Force[weapon] * fAttribute_1034_Time[client];
    
    if(vVelocity[2] > 0)
    {
        vVelocity[2] -= fPush * 0.3;
    } else
    {
        vVelocity[2] -= fPush * 1.0;
    }
    
    TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vVelocity);
    
    return buttons;
}

public OnGameFrame()
{
    Attributes_OnGameFrame();
}

Attributes_OnGameFrame()
{
    Attributes_1056_Think();
}

public Action:CustomWeaponsTF_OnAddAttribute(weapon, client, const String:attrib[], const String:plugin[], const String:value[])
{
    if(!StrEqual(plugin, "advanced-weaponiser-2-attributes")) return Plugin_Continue;
    
    new Action:action;
    
    if(StrEqual(attrib, "fastcloak on backstab"))
    {
        FastcloakOnBackstab[weapon] = true;
        action = Plugin_Handled;
    } else if(StrEqual(attrib, "projectiles bounce"))
    {
        ProjectilesBounce[weapon] = true;
        ProjectilesBounce_Count[weapon] = StringToFloat(value);
        
        action = Plugin_Handled;
    } else if(StrEqual(attrib, "earthquake on rocket jump land"))
    {
        Earthquake[weapon] = true;
        action = Plugin_Handled;
    } else if(StrEqual(attrib, "reload clip on damage"))
    {
        DamageReloads[weapon] = true;
        DamageReloads_Max[weapon] = StringToFloat(value);
        
        g_fTotalDamage1296[client] = 0.0;
        
        action = Plugin_Handled;
    } else if(StrEqual(attrib, "alt fire is oil"))
    {
        AltFireIsOil[weapon] = true;
        action = Plugin_Handled;
    } else if(StrEqual(attrib, "attack while cloaked"))
    {
        AttackWhileCloaked[weapon] = true;
        action = Plugin_Handled;
    } else if(StrEqual(attrib, "reset afterburn"))
    {
        ResetAfterburn[weapon] = true;
        action = Plugin_Handled;
    } else if(StrEqual(attrib, "controllable projectiles"))
    {
        ControllableProjectiles[weapon] = true;
        
        ControllableProjectiles_Control[weapon] = StringToFloat(value) * 1000.0;
        
        action = Plugin_Handled;
    } else if(StrEqual(attrib, "item is heavy"))
    {
        ItemIsHeavy[weapon] = true;
        
        ItemIsHeavy_Force[weapon] = StringToFloat(value);
        
        action = Plugin_Handled;
    } else if(StrEqual(attrib, "no reloading"))
    {
        NoReloading[weapon] = true;
        
        TF2Attrib_SetByName(weapon, "reload time increased hidden", 1001.0);
        
        action = Plugin_Handled;
    }
    
    if(!HasAttribute[weapon]) HasAttribute[weapon] = bool:action;
    
    return action;
}

// Returns true when it finds the first weapon with an attribute, returns false if it can't find one
public bool:EntityHasAttributes(&entity)
{
    if(!IsValidClient(entity)) return false;
    
    for(new slot = 0; slot <= 4; slot++)
    {
        if(GetPlayerWeaponSlot(entity, slot) == -1) continue;
        if(HasAttribute[GetPlayerWeaponSlot(entity, slot)])
        {
            return HasAttribute[GetPlayerWeaponSlot(entity, slot)];
        }
    }
    
    return false;
}

public Action:Attribute_1062_OnTakeDamage(victim, &attacker, slot, &Float:damage, &damagetype, Float:damageForce[3], Float:damagePosition[3], bool:bBuilding)
{
    if(!IsValidClient(attacker)) return Plugin_Continue;
    if(attacker == victim) return Plugin_Continue;
    if(damage <= 0.0) return Plugin_Continue;
    if(!IsDamageTypeCrit(damagetype)) return Plugin_Continue;
    
    new weapon = GetPlayerWeaponSlot(attacker, slot);
    if(weapon == -1) return Plugin_Continue;
    if(!FastcloakOnBackstab[weapon]) return Plugin_Continue;
    
    FastCloak(attacker);
    
    return Plugin_Continue;
}

public Action:Attribute_1193_OnTakeDamage(victim, &attacker, slot, &Float:damage, &damagetype, Float:damageForce[3], Float:damagePosition[3], bool:bBuilding)
{
    if(bBuilding) return Plugin_Continue;
    if(!IsValidClient(attacker)) return Plugin_Continue;
    if(attacker == victim) return Plugin_Continue;
    if(damage <= 0.0) return Plugin_Continue;
    
    new bool:weaponvalid = true;
    
    if(GetPlayerWeaponSlot(attacker, slot) == -1) weaponvalid = false;
    
    if(!weaponvalid || !ResetAfterburn[GetPlayerWeaponSlot(attacker, slot)])
    {
        new bool:weapon2valid = true;
        
        if(GetPlayerWeaponSlot(attacker, 2) == -1) weapon2valid = false;
        
        if(ResetAfterburn[GetPlayerWeaponSlot(attacker, 2)] && weapon2valid)
        {
            if(g_iAchBoilerBurner1193[victim] == attacker && IsAfterDamage(damagetype) ) g_iAchBoilerTimer1193[victim] = 0;
        }
        if(IsAfterDamage(damagetype))
        {
            if(g_iAchBoilerBurner1193[victim] != attacker)
            {
                g_iAchBoilerBurner1193[victim] = 0;
                g_iAchBoilerTimer1193[victim] = 0;
            }
        }
        return Plugin_Continue;
    }
    if(!TF2_IsPlayerInCondition(victim, TFCond_OnFire)) return Plugin_Continue;
    if(IsAfterDamage(damagetype))
    {
        if(g_iAchBoilerBurner1193[victim] != attacker)
        {
            g_iAchBoilerBurner1193[victim] = 0;
            g_iAchBoilerTimer1193[victim] = 0;
        } else
        {
            g_iAchBoilerTimer1193[victim] += 1;
            return Plugin_Continue;
        }
        
        TF2_IgnitePlayer(victim, attacker);
        EmitSoundToAll(SOUND_FLAME_ENGULF, victim, _, _, SND_CHANGEVOL, SNDVOL_NORMAL*1.5);
        
        g_iAchBoilerBurner1193[victim] = attacker;
        
        return Plugin_Continue;
    }
    
    return Plugin_Continue;
}

public Action:Attribute_1296_OnTakeDamage(victim, &attacker, slot, &Float:damage, &damagetype, Float:damageForce[3], Float:damagePosition[3], bool:bBuilding)
{
    if(!IsValidClient(attacker)) return Plugin_Continue;
    if(GetClientTeam(attacker) == GetClientTeam(victim)) return Plugin_Continue;
    if(attacker == victim) return Plugin_Continue;
    if(damage <= 0.0) return Plugin_Continue;
    if(slot == 1) return Plugin_Continue;
    
    new weapon = GetPlayerWeaponSlot(attacker, 1);
    if(weapon == -1) return Plugin_Continue;
    if(!DamageReloads[weapon]) return Plugin_Continue;
    
    g_fTotalDamage1296[attacker] += damage;
    
    if(g_fTotalDamage1296[attacker] >= 50.0)
    {
        EmitSoundToClient(attacker, SOUND_1217_RELOAD);
    }
    
    while(g_fTotalDamage1296[attacker] >= 50.0)
    {
        g_fTotalDamage1296[attacker] -= 50.0;
        new clip = GetEntProp(weapon, Prop_Send, "m_iClip1");
        if(clip >= DamageReloads_Max[weapon]) return Plugin_Continue;
        SetClip(weapon, clip+1);
    }
    
    return Plugin_Continue;
}

public Action:Attributes_OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
    if(victim <= 0) return Plugin_Continue;
    if(attacker <= 0) return Plugin_Continue;
    if(IsValidClient(attacker) && IsValidClient(victim) && attacker != victim && GetClientTeam(attacker) == GetClientTeam(victim)) return Plugin_Continue;
    if(GetClientTeam(attacker) == GetClientTeam(victim)) return Plugin_Continue;
    
    new bool:bBuilding = IsEntityBuilding(victim);
    if(!bBuilding && !CanRecieveDamage(victim)) return Plugin_Continue;
    
    // Set up return
    new Action:aReturn = Plugin_Continue;
    
    // Get the slot
    new slot = GetClientSlot(attacker);
    decl String:strClassname[PLATFORM_MAX_PATH];
    if(weapon > 0 && IsValidEdict(weapon))
    {
        GetEdictClassname(weapon, strClassname, sizeof(strClassname));
        slot = GetWeaponSlot(strClassname);
    } else
    {
        if(inflictor > 0 && !IsValidClient(inflictor) && IsValidEdict(inflictor))
        {
            GetEdictClassname(inflictor, strClassname, sizeof(strClassname));
            slot = GetWeaponSlot(strClassname);
        }
    }
    
    new oldtype = damagetype;
    
    if(IsDamageTypeCrit(oldtype) && !bBuilding) damage *= 3.0;
    
    // Attributes go here
    aReturn = ActionApply(aReturn, Attribute_1062_OnTakeDamage(victim, attacker, slot, damage, damagetype, damageForce, damagePosition, bBuilding));
    aReturn = ActionApply(aReturn, Attribute_1193_OnTakeDamage(victim, attacker, slot, damage, damagetype, damageForce, damagePosition, bBuilding));
    aReturn = ActionApply(aReturn, Attribute_1296_OnTakeDamage(victim, attacker, slot, damage, damagetype, damageForce, damagePosition, bBuilding));
    
    if(IsDamageTypeCrit(oldtype)) damage /= 3.0;
    
    return aReturn;
}

public OnEntityDestroyed(Ent)
{
    if(Ent <= 0 || Ent > 2048) return;
    HasAttribute[Ent] = false;
    FastcloakOnBackstab[Ent] = false;
    ProjectilesBounce[Ent] = false;
    ProjectilesBounce_Count[Ent] = 0.0;
    Earthquake[Ent] = false;
    DamageReloads[Ent] = false;
    DamageReloads_Max[Ent] = 0.0;
    AltFireIsOil[Ent] = false;
    AttackWhileCloaked[Ent] = false;
    ResetAfterburn[Ent] = false;
    ControllableProjectiles[Ent] = false;
    ControllableProjectiles_Control[Ent] = 0.0;
    ItemIsHeavy[Ent] = false;
    ItemIsHeavy_Force[Ent] = 0.0;
    NoReloading[Ent] = false;
}

// Sets reserve ammo
stock SetAmmo(client, weapon, ammo)
{
    new iAmmoType = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
    if(iAmmoType != -1) SetEntProp(client, Prop_Data, "m_iAmmo", ammo, _, iAmmoType);
}

// Gets reserve ammo
stock GetAmmo(client, slot)
{
    if(!IsValidClient(client)) return 0;
    new weapon = GetPlayerWeaponSlot(client, slot);
    if(IsValidEntity(weapon))
    {   
        new iOffset = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1)*4;
        new iAmmoTable = FindSendPropInfo("CTFPlayer", "m_iAmmo");
        return GetEntData(client, iAmmoTable+iOffset);
    }
    return 0;
}

// Sets ammo in clip
stock SetClip(weapon, clip)
{
    SetEntProp(weapon, Prop_Data, "m_iClip1", clip);
    ChangeEdictState(weapon, FindSendPropInfo("CTFWeaponBase", "m_iClip1"));
}

// Sets shots remaining for energy weapons (Bison, Pomson, etc.)
stock SetEnergyAmmo(weapon, Float:flEnergyAmmo)
{
    SetEntPropFloat(weapon, Prop_Send, "m_flEnergy", flEnergyAmmo);
}