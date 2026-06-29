#pragma semicolon 1
#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>

#define SOUND_LAUNCH    "misc/doomsday_missile_launch.wav"
#define SOUND_EXPLODE    "misc/doomsday_missile_explosion.wav"

new Handle:g_hCvarNDmg,    Float:g_flCvarNDmg;
new Handle:g_hCvarNRadius,    Float:g_flCvarNRadius;
new Handle:g_hCvarNDelay,    Float:g_flCvarNDelay;
new Handle:g_hCvarRadDam,    Float:g_flCvarRadDam;
new Handle:g_hCvarRadRadius,    Float:g_flCvarRadRadius;

public OnPluginStart()
{
    RegAdminCmd("sm_nuke", Command_Nuke, ADMFLAG_ROOT);
    
    g_hCvarNDmg = CreateConVar("sm_nuke_damage", "9999999.0", "Damage of the nuke.", FCVAR_PLUGIN, true, 0.0);
    g_flCvarNDmg = GetConVarFloat(g_hCvarNDmg);
    HookConVarChange(g_hCvarNDmg, OnConVarChange);
    
    g_hCvarNRadius = CreateConVar("sm_nuke_radius", "1200.0", "Radius of the nuke.", FCVAR_PLUGIN, true, 0.0);
    g_flCvarNRadius = GetConVarFloat(g_hCvarNRadius);
    HookConVarChange(g_hCvarNRadius, OnConVarChange);
    
    g_hCvarNDelay = CreateConVar("sm_nuke_delay", "6.1", "How long does it take for the nuke to go boom? (Seconds)", FCVAR_PLUGIN, true, 0.0);
    g_flCvarNDelay = GetConVarFloat(g_hCvarNDelay);
    HookConVarChange(g_hCvarNDelay, OnConVarChange);
    
    g_hCvarRadDam = CreateConVar("sm_nuke_radiation_damage", "10.0", "How much damage to take from the radiation? (Seconds)", FCVAR_PLUGIN, true, 0.0);
    g_flCvarRadDam = GetConVarFloat(g_hCvarRadDam);
    HookConVarChange(g_hCvarRadDam, OnConVarChange);
    
    g_hCvarRadRadius = CreateConVar("sm_nuke_radiation_radius", "1200.0", "How much damage to take from the radiation? (Seconds)", FCVAR_PLUGIN, true, 0.0);
    g_flCvarRadRadius = GetConVarFloat(g_hCvarRadRadius);
    HookConVarChange(g_hCvarRadRadius, OnConVarChange);
    
    AutoExecConfig(true, "dd_nuke");
}

public OnConVarChange(Handle:hConvar, const String:strOldValue[], const String:strNewValue[])
{
    g_flCvarNDmg = GetConVarFloat(g_hCvarNDmg);
    g_flCvarNRadius = GetConVarFloat(g_hCvarNRadius);
    g_flCvarNDelay = GetConVarFloat(g_hCvarNDelay);
    g_flCvarRadDam = GetConVarFloat(g_hCvarRadDam);
    g_flCvarRadRadius = GetConVarFloat(g_hCvarRadRadius);
}

public Plugin:myinfo = 
{
    name = "[TF2] Doomsday nuke",
    author = "Pelipoika (main) & Orion (lil' option)",
    description = "The nuke from sd_doomsday",
    version = "1.3",
    url = "http://www.sourcemod.net/"
}

public OnMapStart()
{
    PrecacheSound(SOUND_LAUNCH);
    PrecacheSound(SOUND_EXPLODE);
    
    PrecacheGeneric("dooms_nuke_collumn");
    PrecacheGeneric("base_destroyed_smoke_doomsday");
    PrecacheGeneric("flash_doomsday");
    PrecacheGeneric("ping_circle");
    PrecacheGeneric("mvm_path_marker");
}

public Action:Command_Nuke(client, args)
{
    decl Float:Position[3];
    if(!SetTeleportEndPoint(client, Position))
    {
        PrintToChat(client, "Could not find place.");
        return Plugin_Handled;
    }
    
    //PrintCenterTextAll("A nuke will go off at %.0f%, %.0f%, %.0f% in %.1f% seconds.", Position[0], Position[1], Position[2], g_flCvarNDelay);
    
    new shaker = CreateEntityByName("env_shake");
    if(shaker != -1)
    {
        DispatchKeyValue(shaker, "amplitude", "16");
        DispatchKeyValue(shaker, "radius", "8000");
        DispatchKeyValue(shaker, "duration", "2.0");
        DispatchKeyValue(shaker, "frequency", "20");
        DispatchKeyValue(shaker, "spawnflags", "4");
        
        TeleportEntity(shaker, Position, NULL_VECTOR, NULL_VECTOR);
        
        DispatchSpawn(shaker);
        AcceptEntityInput(shaker, "StartShake");
        CreateTimer(10.0, Timer_Delete, EntIndexToEntRef(shaker)); 
    }
    
    EmitSoundToAll(SOUND_LAUNCH);
    ShowParticle(Position, "ping_circle", 5.0);
    ShowParticle(Position, "mvm_path_marker", 5.0);
    
    new Handle:pack;
    CreateDataTimer(g_flCvarNDelay, Timer_NukeHitsHere, pack);
    WritePackFloat(pack, Position[0]); //Position of effects
    WritePackFloat(pack, Position[1]); //Position of effects
    WritePackFloat(pack, Position[2]); //Position of effects

    return Plugin_Handled;
}

public Action:Timer_NukeHitsHere(Handle:timer, any:pack)
{
    ResetPack(pack);

    decl Float:pos[3], Float:Flash[3], Float:Collumn[3];
    pos[0] = ReadPackFloat(pack);
    pos[1] = ReadPackFloat(pack);
    pos[2] = ReadPackFloat(pack);
    
    Flash[0] = pos[0];
    Flash[1] = pos[1];
    Flash[2] = pos[2];
    
    Collumn[0] = pos[0];
    Collumn[1] = pos[1];
    Collumn[2] = pos[2];
    
    pos[2] += 6.0;
    Flash[2] += 236.0;
    Collumn[2] += 1652.0;

    EmitSoundToAll(SOUND_EXPLODE);

    ShowParticle(pos, "base_destroyed_smoke_doomsday", 30.0);
    ShowParticle(Flash, "flash_doomsday", 10.0);
    ShowParticle(Collumn, "dooms_nuke_collumn", 30.0);

    new shaker = CreateEntityByName("env_shake");
    if(shaker != -1)
    {
        DispatchKeyValue(shaker, "amplitude", "50");
        DispatchKeyValue(shaker, "radius", "1.6 * g_flCvarNRadius");
        DispatchKeyValue(shaker, "duration", "6.0");
        DispatchKeyValue(shaker, "frequency", "50");
        DispatchKeyValue(shaker, "spawnflags", "4");

        TeleportEntity(shaker, pos, NULL_VECTOR, NULL_VECTOR);
        AcceptEntityInput(shaker, "StartShake");
        DispatchSpawn(shaker);
        
        CreateTimer(10.0, Timer_Delete, EntIndexToEntRef(shaker)); 
    }
    
    for (new i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i)) continue;
        if (!IsPlayerAlive(i)) continue;
        new Float:zPos[3];
        GetClientAbsOrigin(i, zPos);
        new Float:Dist = GetDistanceTotal(pos, zPos);
		if (Dist > g_flCvarNRadius) continue;
		SDKHooks_TakeDamage(i, i, i, g_flCvarNDmg, DMG_BLAST|DMG_RADIATION|DMG_ALWAYSGIB);
    }
    
	if(GetConVarFloat(g_hCvarRadDam) != 0.0)
    {
        new Handle:radiation;
        CreateDataTimer(0.2, Timer_PerformRadiation, radiation, TIMER_REPEAT); // the timer will repeat each 1.0 second until it returns Plugin_Stop
        WritePackFloat(radiation, pos[0]);    //Position of radiation
        WritePackFloat(radiation, pos[1]);    //Position of radiation
        WritePackFloat(radiation, pos[2]);    //Position of radiation
        WritePackCell(radiation, 18);         //Remaining repeats
    }
}

public Action:Timer_PerformRadiation(Handle:timer, Handle:radiation) 
{
    ResetPack(radiation);
    
    decl Float:pos[3];
    new repeats = ReadPackCell(radiation);
    
    pos[0] = ReadPackFloat(radiation);
    pos[1] = ReadPackFloat(radiation);
    pos[2] = ReadPackFloat(radiation);
    
    if (repeats == 0) return Plugin_Stop; // return Plugin_Stop if we've finished radiating
    repeats -= 1;

    for (new i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i)) continue;
        if (!IsPlayerAlive(i)) continue;
        new Float:zPos[3];
        GetClientAbsOrigin(i, zPos);
        new Float:Dist = GetDistanceTotal(pos, zPos);
		if (Dist > g_flCvarRadRadius) continue;
		SDKHooks_TakeDamage(i, i, i, g_flCvarRadDam, DMG_PREVENT_PHYSICS_FORCE|DMG_RADIATION);
    }
    
    ResetPack(radiation, true);
    WritePackFloat(radiation, pos[0]);    //Position of radiation
    WritePackFloat(radiation, pos[1]);    //Position of radiation
    WritePackFloat(radiation, pos[2]);    //Position of radiation
    WritePackCell(radiation, repeats);

    return Plugin_Continue;
}

public ShowParticle(Float:pos[3], String:particlename[], Float:time)
{
    new particle = CreateEntityByName("info_particle_system");
    if (IsValidEdict(particle))
    {
        TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
        DispatchKeyValue(particle, "effect_name", particlename);
        ActivateEntity(particle);
        AcceptEntityInput(particle, "start");
        CreateTimer(time, DeleteParticles, EntIndexToEntRef(particle));
    }
}

public Action:DeleteParticles(Handle:timer, any:particle)
{
    new ent = EntRefToEntIndex(particle);

    if (ent != INVALID_ENT_REFERENCE)
    {
        new String:classname[64];
        GetEdictClassname(ent, classname, sizeof(classname));
        if (StrEqual(classname, "info_particle_system", false))
            AcceptEntityInput(ent, "kill");
    }
}

public Action:Timer_Delete(Handle:hTimer, any:iRefEnt) 
{ 
    new iEntity = EntRefToEntIndex(iRefEnt); 
    if(iEntity > MaxClients) 
    {
        AcceptEntityInput(iEntity, "Kill"); 
        AcceptEntityInput(iEntity, "StopShake");
    }
     
    return Plugin_Handled; 
}

stock Float:GetDistanceTotal(Float:vec1[3], Float:vec2[3])
{
    new Float:vec[3];
    for (new i = 0; i < 3; i++)
    {
        vec[i] = (vec1[i] > vec2[i]) ? vec1[i] - vec2[i] : vec2[i] - vec1[i];
    }
    return SquareRoot(Pow(vec[0], 2.0) + Pow(vec[1], 2.0) + Pow(vec[2], 2.0));
}

bool:SetTeleportEndPoint(client, Float:Position[3])
{
    decl Float:vAngles[3];
    decl Float:vOrigin[3];
    decl Float:vBuffer[3];
    decl Float:vStart[3];
    decl Float:Distance;
    
    GetClientEyePosition(client,vOrigin);
    GetClientEyeAngles(client, vAngles);
    
    //get endpoint for teleport
    new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer2);

    if(TR_DidHit(trace))
    {        
            TR_GetEndPosition(vStart, trace);
		GetVectorDistance(vOrigin, vStart, false);
		Distance = -35.0;
			GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
		Position[0] = vStart[0] + (vBuffer[0]*Distance);
        Position[1] = vStart[1] + (vBuffer[1]*Distance);
        Position[2] = vStart[2] + (vBuffer[2]*Distance);
    }
    else
    {
        CloseHandle(trace);
        return false;
    }
    
    CloseHandle(trace);
    return true;
}

public bool:TraceEntityFilterPlayer2(entity, contentsMask)
{
    return entity > GetMaxClients() || !entity;
}