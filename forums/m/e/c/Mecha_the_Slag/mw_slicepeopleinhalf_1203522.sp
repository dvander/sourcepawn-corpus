// Plugin by Mecha the Slag (http://MechaWare.net/)
// Models and belonging textures by Valve, modified by Mecha the Slag
// Meat texture by NeoDement (http://www.tf2items.com/id/neodement)

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

// Definitions
#define PLUGIN_VERSION      "1.31"
#define DF_CRITS            1048576     //crits = DAMAGE_ACID
#define DF_NO_CRITS         65536       //nocrit

new bool:g_bSliced[MAXPLAYERS+1];
static const String:g_strWeapons[][]={"sword", "axtinguisher", "fireaxe", "battleaxe", "headtaker"};
new Handle:g_hChance;
new Handle:g_hIcon;
new Handle:g_hSuicide;

public Plugin:myinfo = {
    name = "Slice People In Half",
    author = "Mecha the Slag",
    description = "Slice people in two halves with sharp melee weapons!",
    version = PLUGIN_VERSION,
    url = "http://mechaware.net/"
};

public OnPluginStart() {
    CreateConVar("slice_version", PLUGIN_VERSION, "Plugin version", FCVAR_DONTRECORD|FCVAR_PLUGIN|FCVAR_NOTIFY);
    g_hChance = CreateConVar("slice_chance", "1.0", "Chance for the slice to happen. 1.0 = always, 0.0 = never", FCVAR_PLUGIN);
    g_hIcon = CreateConVar("slice_icon", "2", "1: Always changes the slice icon to sawblade, 2: Only on sm_slice or sm_sliceme", FCVAR_PLUGIN);
    g_hSuicide = CreateConVar("slice_suicide", "0", "If on, allows sm_sliceme suicides", FCVAR_PLUGIN);

    HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
    HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Pre);
    
    RegAdminCmd("sm_slice", Command_Slice, ADMFLAG_SLAY, "sm_slice <#userid|name>");
    RegConsoleCmd("sm_sliceme", Command_SliceMe, "Slice Yourself in Half!");
}

public Action:Event_PlayerSpawn(Handle:hEvent, const String:strName[], bool:bNoBroadcast) {
    new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
    g_bSliced[iClient] = false;
    return Plugin_Continue; 
}

public Action:Event_PlayerDeath(Handle:hEvent, const String:strName[], bool:bNoBroadcast) { 
    new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid")); 
    new iDamage = GetEventInt(hEvent, "damagebits");
    decl String:strWeapon[PLATFORM_MAX_PATH];
    GetEventString(hEvent, "weapon", strWeapon, sizeof(strWeapon));
    new bool:bAcceptable = false;
    
    for (new iLoop = 0; iLoop < sizeof(g_strWeapons); iLoop++) {
        if (StrEqual(strWeapon, g_strWeapons[iLoop], false)) bAcceptable = true;
    }
    
    new Float:fRandom = GetRandomFloat();
    
    if (IsValidClient(iClient) && ((iDamage & DF_CRITS && bAcceptable && (GetConVarFloat(g_hChance) >= fRandom)) || g_bSliced[iClient])) {
        decl String:strClassname[52];
        Format(strClassname, sizeof(strClassname), "");
        new TFClassType:iClass = TF2_GetPlayerClass(iClient);
        if (iClass == TFClassType:TFClass_DemoMan) Format(strClassname, sizeof(strClassname), "demo");
        if (iClass == TFClassType:TFClass_Pyro) Format(strClassname, sizeof(strClassname), "pyro");
        if (iClass == TFClassType:TFClass_Heavy) Format(strClassname, sizeof(strClassname), "heavy");
        if (!(StrEqual(strClassname, ""))) {
            decl String:strModel[PLATFORM_MAX_PATH];
            Format(strModel, sizeof(strModel), "models/decapitation/%s_left2.mdl", strClassname);
            CreateGib(iClient, strModel, -1.0);
            Format(strModel, sizeof(strModel), "models/decapitation/%s_right2.mdl", strClassname);
            CreateGib(iClient, strModel, 1.0);
            WriteParticle(iClient, "env_sawblood");
            WriteParticle(iClient, "env_sawblood");
            WriteParticle(iClient, "env_sawblood");
            WriteParticle(iClient, "env_sawblood_chunk");
            WriteParticle(iClient, "env_sawblood_chunk");
            WriteParticle(iClient, "env_sawblood_chunk");
            WriteParticle(iClient, "env_sawblood_goop");
            WriteParticle(iClient, "env_sawblood_goop");
            CreateTimer(0.01, RemoveBody, iClient);
            if (GetConVarInt(g_hIcon) == 1 || (GetConVarInt(g_hIcon) == 2 && g_bSliced[iClient])) {
                new iDamage2 = DF_NO_CRITS;
                if(iDamage & DF_CRITS)
                {
                    iDamage2 += DF_CRITS;
                }
                SetEventInt(hEvent, "damagebits", iDamage2);
            }
        }
    }
    
    g_bSliced[iClient] = false;
    
    return Plugin_Continue; 
}

public Action:RemoveBody(Handle:hTimer, any:iClient) {
    new iRagdoll;
    iRagdoll = GetEntPropEnt(iClient, Prop_Send, "m_hRagdoll");
    if(IsValidEdict(iRagdoll)) {
        RemoveEdict(iRagdoll);
        SetEntPropEnt(iClient, Prop_Send, "m_hRagdoll", -1);
    }
}

public OnMapStart() {
    PrecacheModel("models/decapitation/demo_left2.mdl", true);
    PrecacheModel("models/decapitation/demo_right2.mdl", true);
    AddToDownloadModel("models/decapitation/demo_left2");
    AddToDownloadModel("models/decapitation/demo_right2");
    
    PrecacheModel("models/decapitation/pyro_left2.mdl", true);
    PrecacheModel("models/decapitation/pyro_right2.mdl", true);
    AddToDownloadModel("models/decapitation/pyro_left2");
    AddToDownloadModel("models/decapitation/pyro_right2");
    
    PrecacheModel("models/decapitation/heavy_left2.mdl", true);
    PrecacheModel("models/decapitation/heavy_right2.mdl", true);
    AddToDownloadModel("models/decapitation/heavy_left2");
    AddToDownloadModel("models/decapitation/heavy_right2");
    
    AddFileToDownloadsTable("materials/models/decapitation/meat.vtf");
    AddFileToDownloadsTable("materials/models/decapitation/meat.vmt");
}

AddToDownloadModel(String:strPath[PLATFORM_MAX_PATH]) {
    decl String:strModel[PLATFORM_MAX_PATH];
    Format(strModel, sizeof(strModel), "%s.mdl", strPath);
    AddFileToDownloadsTable(strModel);
    Format(strModel, sizeof(strModel), "%s.dx80.vtx", strPath);
    AddFileToDownloadsTable(strModel);
    Format(strModel, sizeof(strModel), "%s.dx90.vtx", strPath);
    AddFileToDownloadsTable(strModel);
    Format(strModel, sizeof(strModel), "%s.phy", strPath);
    AddFileToDownloadsTable(strModel);
    Format(strModel, sizeof(strModel), "%s.sw.vtx", strPath);
    AddFileToDownloadsTable(strModel);
    Format(strModel, sizeof(strModel), "%s.vvd", strPath);
    AddFileToDownloadsTable(strModel);
}

CreateGib(any:iClient, String:strModel[PLATFORM_MAX_PATH], Float:fDir) {
    decl Float:fOrigin[3];
    decl Float:fAngle[3];
    decl Float:fVel[3];
    GetClientAbsOrigin(iClient, fOrigin);
    GetClientEyeAngles(iClient, fAngle);
    
    fAngle[0] = 0.0;
    fAngle[1] += 90.0;
    fAngle[2] = 90.0;
    
    new Float:fOffset1 = Cosine(fAngle[1]*0.0174532925);
    new Float:fOffset2 = Sine(fAngle[1]*0.0174532925);
    new Float:fStrength = GetRandomFloat(100.0, 1000.0);
    
    fVel[0] += fOffset1*fDir*fStrength;
    fVel[1] += fOffset2*fDir*fStrength;
    fVel[2] += fStrength;
    
    fOrigin[0] += fOffset1*5.0;
    fOrigin[1] += fOffset2*5.0;
    fOrigin[2] += 40.0;

    new iEntity = CreateEntityByName("prop_ragdoll");
    DispatchKeyValue(iEntity, "model", strModel);
    if (GetClientTeam(iClient) == 3) DispatchKeyValue(iEntity, "skin", "1"); 
    DispatchSpawn(iEntity);
    SetEntProp(iEntity, Prop_Data, "m_CollisionGroup", 1);
    SetEdictFlags(iEntity, 4);
    TeleportEntity(iEntity, fOrigin, fAngle, fVel);
    CreateTimer(15.0, RemoveGibs, iEntity);
}

public Action:RemoveGibs(Handle:hTimer, any:iEntity) {
    if(IsValidEntity(iEntity)) {
        decl String:strClassname[64];
        GetEdictClassname(iEntity, strClassname, sizeof(strClassname));
        if (StrEqual(strClassname, "prop_ragdoll", false)) {
            AcceptEntityInput(iEntity, "Kill" );
        }
    }
}

WriteParticle(iEntity, String:strParticle[]) {

    //Declare:
    decl String:strName[64];

    //Initialize:
    new iParticle = CreateEntityByName("info_particle_system");
    
    //Validate:
    if(IsValidEdict(iParticle)) {

        //Declare:
        decl Float:fPos[3], Float:fAngle[3];

        //Initialize:
        fAngle[0] = GetRandomFloat(0.0, 360.0);
        fAngle[1] = GetRandomFloat(0.0, 15.0);
        fAngle[2] = GetRandomFloat(0.0, 15.0);

        //Origin:
        GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fPos);
        fPos[2] += GetRandomFloat(35.0, 65.0);
        TeleportEntity(iParticle, fPos, fAngle, NULL_VECTOR);

        //Properties:
        GetEntPropString(iEntity, Prop_Data, "m_iName", strName, sizeof(strName));
        DispatchKeyValue(iParticle, "targetname", "TF2Particle");
        DispatchKeyValue(iParticle, "parentname", strName);
        DispatchKeyValue(iParticle, "effect_name", strParticle);

        //Spawn:
        DispatchSpawn(iParticle);
    
        //Parent:        
        SetVariantString(strName);
        AcceptEntityInput(iParticle, "SetParent", -1, -1, 0);
        ActivateEntity(iParticle);
        AcceptEntityInput(iParticle, "start");

        //Delete:
        CreateTimer(3.0, DeleteParticle, iParticle);
    }
}

public Action:DeleteParticle(Handle:hTimer, any:iParticle) {
    //Validate:
    if(IsValidEntity(iParticle)) {
        //Declare:
        decl String:strClassname[64];
        //Initialize:
        GetEdictClassname(iParticle, strClassname, sizeof(strClassname));
        //Is a Particle:
        if(StrEqual(strClassname, "info_particle_system", false)) {
            //Delete:
            RemoveEdict(iParticle);
        }
    }
}

stock bool:IsValidClient(iClient) {
    if (iClient <= 0) return false;
    if (iClient > MaxClients) return false;
    if (!IsClientConnected(iClient)) return false;
    return IsClientInGame(iClient);
}

public Action:Command_SliceMe(iClient, iArgs) {
    if (GetConVarBool(g_hSuicide)) {
        g_bSliced[iClient] = true;
        ForcePlayerSuicide(iClient);
    }
}

public Action:Command_Slice(iClient, iArgs) {
    if (iArgs < 1) {
        ReplyToCommand(iClient, "[SM] Usage: sm_slice <#userid|name>");
        return Plugin_Handled;
    }

    decl String:strArg[65];
    GetCmdArgString(strArg, sizeof(strArg));
    
    decl String:target_name[MAX_TARGET_LENGTH];
    decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
    
    if ((target_count = ProcessTargetString(
            strArg,
            iClient,
            target_list,
            MAXPLAYERS,
            COMMAND_FILTER_ALIVE,
            target_name,
            sizeof(target_name),
            tn_is_ml)) <= 0)
    {
        ReplyToTargetError(iClient, target_count);
        return Plugin_Handled;
    }
    
    for (new iLoop = 0; iLoop < target_count; iLoop++) {
        g_bSliced[target_list[iLoop]] = true;
        ForcePlayerSuicide(target_list[iLoop]);
    }

    return Plugin_Handled;
}