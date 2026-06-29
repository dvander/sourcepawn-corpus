/**
 * ====================
 *     PunchShot
 *   File: punchshot.sp
 *   Author: Greyscale
 * ==================== 
 */

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define VERSION "1.0"

enum PSHitGroups
{
    HITGROUP_GENERIC = 0,
    HITGROUP_HEAD = 1,
    HITGROUP_UPPERCHEST = 2,
    HITGROUP_LOWERCHEST = 3,
    HITGROUP_LEFTARM = 4,
    HITGROUP_RIGHTARM = 5,
    HITGROUP_LEFTLEG = 6,
    HITGROUP_RIGHTLEG = 7,
}

#define PUNCH_MAX 6.0

new offsPunchAngle;

new Handle:kvPunchData = INVALID_HANDLE;

new Float:arrayPunchData[PSHitGroups][3];

public Plugin:myinfo =
{
    name = "PunchShot", 
    author = "Greyscale", 
    description = "Punches player's vision when shot in certain places", 
    version = VERSION, 
    url = ""
};

public OnPluginStart()
{
    offsPunchAngle = FindSendPropInfo("CBasePlayer", "m_vecPunchAngle");
    if (offsPunchAngle == -1)
    {
        SetFailState("Couldn't find \"m_vecPunchAngle\"!");
    }
    
    // ======================================================================
    
    HookEvent("player_hurt", PlayerHurt);
    
    // ======================================================================
    
    CreateConVar("gs_punchshot_version", VERSION, "[PunchShot] Current version of this plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
}

public OnMapStart()
{
    if (kvPunchData != INVALID_HANDLE)
    {
        CloseHandle(kvPunchData);
    }
    
    kvPunchData = CreateKeyValues("punchdata");
    
    decl String:path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, sizeof(path), "configs/punchdata.cfg");
    
    if (!FileToKeyValues(kvPunchData, path))
    {
        SetFailState("\"%s\" missing from server", path);
    }
    
    KvRewind(kvPunchData);
    if (!KvGotoFirstSubKey(kvPunchData))
    {
        SetFailState("No punch data defined in \"%s\"", path);
    }
    
    decl String:section[8];
    new PSHitGroup:hitgroup;
    
    do
    {
        KvGetSectionName(kvPunchData, section, sizeof(section));
        
        hitgroup = PSHitGroup:StringToInt(section);
        
        arrayPunchData[hitgroup][0] = KvGetFloat(kvPunchData, "pitch");
        arrayPunchData[hitgroup][1] = KvGetFloat(kvPunchData, "yaw");
        arrayPunchData[hitgroup][2] = KvGetFloat(kvPunchData, "roll");
    } while (KvGotoNextKey(kvPunchData));
}

public Action:PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
    new index = GetClientOfUserId(GetEventInt(event, "userid"));
    new PSHitGroups:hitgroup = PSHitGroups:GetEventInt(event, "hitgroup");
    
    new Float:vecPunch[3];
    GetEntDataVector(index, offsPunchAngle, vecPunch);
    
    new Float:fPunch = FloatAbs(vecPunch[0]) + FloatAbs(vecPunch[1]) + FloatAbs(vecPunch[2]);
    if (fPunch <= PUNCH_MAX)
    {
        GetPunchData(hitgroup, vecPunch);

        SetEntDataVector(index, offsPunchAngle, vecPunch);
    }
}

GetPunchData(PSHitGroups:hitgroup, Float:vec[3])
{
    for (new x = 0; x <= 2; x++)
    {
        vec[x] = arrayPunchData[hitgroup][x];
    }
}