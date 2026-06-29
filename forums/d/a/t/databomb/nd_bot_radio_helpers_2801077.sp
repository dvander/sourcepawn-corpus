/*  [ND] Bot Radio Helpers
    Copyright (C) 2023 by databomb

    ***************************************************************************
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.
    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
    ***************************************************************************

    Description:
    When a player calls for a medic using the built-in radio commands, this
    plugin will check if there's a nearby teammate bot who's a medic. If one is
    found then this changes the bot's behavior to travel towards the player
    requesting medical attention and throw a medpack. Similar behavior was added
    for a bot engineer to throw an ammopack to teammates requesting supplies.

    Special Thanks:
    The team who perfected the [TF2] Bot Combat Improvements plugin were a great
    help with this plugin. Many of the functions towards the tail end of this
    plugin are based on or wholly adopted from the TF2 plugin.
    - EfeDursun125
    - enderandrew
    - Marqueritte
    - Showin'
    - Crasher_3637
*/

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#tryinclude <nd_ammo>
#tryinclude <nd_classes>

#define PLUGIN_VERSION "1.0.5"

#if !defined _nd_ammo_included_

    #define ND_AMMO_OFFSET_AMMOPACK         26

    // returns the ammo quantity given one of the ND_AMMO_OFFSET values supplied as the type
    stock int ND_GetAmmoByType(int client, int type)
    {
        if (!client || client > MaxClients || !IsClientInGame(client) || !IsPlayerAlive(client))
        {
            return 0;
        }

        int iAmmoOffset = FindDataMapInfo(client, "m_iAmmo");
        if (iAmmoOffset == -1)
        {
            return 0;
        }

        return GetEntData(client, iAmmoOffset + type*4);
    }

#endif

#if !defined _nd_classes_included_

    #define MAX_NEARBY_DISTANCE     300.0
    #define ALL_TEAMS               -1

    #define MAIN_CLASS_ASSAULT      0
    #define MAIN_CLASS_EXO          1
    #define MAIN_CLASS_STEALTH      2
    #define	MAIN_CLASS_SUPPORT      3

    #define ASSAULT_CLASS_INFANTRY  0
    #define ASSAULT_CLASS_GRENADIER 1
    #define	ASSAULT_CLASS_SNIPER    2

    #define EXO_CLASS_SUPRESSION    0
    #define EXO_CLASS_SEIGE_KIT     1

    #define	STEALTH_CLASS_ASSASSIN  0
    #define	STEALTH_CLASS_SNIPER    1
    #define STEALTH_CLASS_SABATEUR  2

    #define SUPPORT_CLASS_MEDIC     0
    #define SUPPORT_CLASS_ENGINEER  1
    #define SUPPORT_CLASS_BBQ       2

    enum eNDClass
    {
        eNDClass_AssaultInfantry = 0,
        eNDClass_AssaultGrenadier,
        eNDClass_AssaultSniper,
        eNDClass_ExoSuppression,
        eNDClass_ExoSiege,
        eNDClass_StealthAssassin,
        eNDClass_StealthSniper,
        eNDClass_StealthSabateur,
        eNDClass_SupportMedic,
        eNDClass_SupportEngineer,
        eNDClass_SupportBBQ,
        eNDClass_Count
    }

    stock int ND_GetMainClass(int client)
    {
        return GetEntProp(client, Prop_Send, "m_iPlayerClass");
    }

    stock int ND_GetSubClass(int client)
    {
        return GetEntProp(client, Prop_Send, "m_iPlayerSubclass");
    }

    stock eNDClass ND_GetPlayerClass(int client)
    {
        int classtype = ND_GetMainClass(client);
        int subclass  = ND_GetSubClass(client);
        switch (classtype)
        {
            case MAIN_CLASS_ASSAULT:
            {
                switch (subclass)
                {
                    case ASSAULT_CLASS_INFANTRY:
                    {
                        return eNDClass_AssaultInfantry;
                    }
                    case ASSAULT_CLASS_GRENADIER:
                    {
                        return eNDClass_AssaultGrenadier;
                    }
                    case ASSAULT_CLASS_SNIPER:
                    {
                        return eNDClass_AssaultSniper;
                    }
                }
            }
            case MAIN_CLASS_EXO:
            {
                switch (subclass)
                {
                    case EXO_CLASS_SUPRESSION:
                    {
                        return eNDClass_ExoSuppression;
                    }
                    case EXO_CLASS_SEIGE_KIT:
                    {
                        return eNDClass_ExoSiege;
                    }
                }
            }
            case MAIN_CLASS_STEALTH:
            {
                switch (subclass)
                {
                    case STEALTH_CLASS_ASSASSIN:
                    {
                        return eNDClass_StealthAssassin;
                    }
                    case STEALTH_CLASS_SNIPER:
                    {
                        return eNDClass_StealthSniper;
                    }
                    case STEALTH_CLASS_SABATEUR:
                    {
                        return eNDClass_StealthSabateur;
                    }
                }
            }
            case MAIN_CLASS_SUPPORT:
            {
                switch (subclass)
                {
                    case SUPPORT_CLASS_MEDIC:
                    {
                        return eNDClass_SupportMedic;
                    }
                    case SUPPORT_CLASS_ENGINEER:
                    {
                        return eNDClass_SupportEngineer;
                    }
                    case SUPPORT_CLASS_BBQ:
                    {
                        return eNDClass_SupportBBQ;
                    }
                }
            }
        }

        return eNDClass_Count;
    }

    stock int ND_GetNearbyTeammateInClass(int client, eNDClass class, bool botsonly = false)
    {
        float fClientPosition[3];
        GetClientEyePosition(client, fClientPosition);
        float fTeammatePosition[3];
        float fClosestDistance = MAX_NEARBY_DISTANCE;
        float fDistance;
        int iClosestInClass = 0;

        for (int index = 1; index <= MaxClients; index++)
        {
            if (index == client || \
                !IsClientInGame(index) || \
                !IsPlayerAlive(index) || \
                (GetClientTeam(index) != GetClientTeam(client)) || \
                (ND_GetPlayerClass(index) != class) || \
                (botsonly && !IsFakeClient(index)))
            {
                continue;
            }
            GetClientEyePosition(index, fTeammatePosition);
            fDistance = GetVectorDistance(fClientPosition, fTeammatePosition);

            if (fDistance < fClosestDistance)
            {
                iClosestInClass = index;
                fClosestDistance = fDistance;
            }
        }

        return iClosestInClass;
    }

    stock int ND_GetCountInClass(eNDClass class, int team = ALL_TEAMS)
    {
        int number = 0;
        for (int index = 1; index <= MaxClients; index++)
        {
            if (IsClientInGame(index) && IsPlayerAlive(index) && ND_GetPlayerClass(index) == class)
            {
                if (team == ALL_TEAMS)
                {
                    number++;
                }
                else if (GetClientTeam(index) == team)
                {
                    number++;
                }
            }
        }
        return number;
    }

#endif

public Plugin myinfo =
{
    name = "[ND] Bot Medic/Engineer Radio Helper",
    author = "databomb",
    description = "Adds bot ability to drop medkits/ammopacks when players radio for support",
    version = PLUGIN_VERSION,
    url = "https://forums.alliedmods.net/member.php?u=54648"
};

bool g_bMedpackThrown[MAXPLAYERS+1];
bool g_bAmmopackThrown[MAXPLAYERS+1];
int g_iAmmopackRequested[MAXPLAYERS+1];
int  g_iMedpackRequested[MAXPLAYERS+1];
float g_fEquipTime[MAXPLAYERS+1];
float g_fFollowTime[MAXPLAYERS+1];
eNDClass g_eNDClass[MAXPLAYERS+1];

public OnPluginStart()
{
    CreateConVar("sm_nd_botradiohelpers_version", PLUGIN_VERSION, "ND Bot Radio Helpers Version", FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);

    UserMsg hSayTextTwo = GetUserMessageId("SayText2");
    if (hSayTextTwo == INVALID_MESSAGE_ID)
    {
        SetFailState("Failed to find user message SayText2");
    }

    HookUserMessage(hSayTextTwo, MessageHook_SayTextTwo);
    HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
    HookEvent("player_death", Event_CheckActiveRequests, EventHookMode_Post);
    HookEvent("player_disconnect", Event_CheckActiveRequests, EventHookMode_Post);
    HookEvent("player_changeclass", Event_CheckActiveRequests, EventHookMode_Post);
    HookEvent("round_win", Event_CheckAllActiveRequests, EventHookMode_Post);

    // Account for late loading
    for (int iClient = 1; iClient <= MaxClients ; iClient++)
    {
        if (IsClientInGame(iClient) && IsFakeClient(iClient))
        {
            SDKHook(iClient, SDKHook_WeaponCanSwitchTo, OnWeaponCanSwitchTo);
            g_eNDClass[iClient] = ND_GetPlayerClass(iClient);
        }
    }
}

public OnClientPutInServer(client)
{
    if (IsFakeClient(client))
    {
        SDKHook(client, SDKHook_WeaponCanSwitchTo, OnWeaponCanSwitchTo);
    }
}

public Action OnWeaponCanSwitchTo(client, weapon)
{
    if (!IsFakeClient(client))
    {
        return Plugin_Continue;
    }

    switch (g_eNDClass[client])
    {
        case eNDClass_SupportMedic:
        {
            if (g_iMedpackRequested[client])
            {
                char sWeaponName[32];
                GetEdictClassname(weapon, sWeaponName, sizeof(sWeaponName));
                if (!StrEqual(sWeaponName, "weapon_medpack"))
                {
                    return Plugin_Handled;
                }
            }
        }
        case eNDClass_SupportEngineer:
        {
            if (g_iAmmopackRequested[client])
            {
                char sWeaponName[32];
                GetEdictClassname(weapon, sWeaponName, sizeof(sWeaponName));
                if (!StrEqual(sWeaponName, "weapon_ammopack"))
                {
                    return Plugin_Handled;
                }
            }
        }
    }

    return Plugin_Continue;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3])
{
    if(client && IsClientInGame(client) && IsFakeClient(client) && IsPlayerAlive(client))
    {
        switch (g_eNDClass[client])
        {
            case eNDClass_SupportMedic:
            {
                if (g_iMedpackRequested[client])
                {
                    int iMedicWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
                    char sClassname[64];
                    GetEntityClassname(iMedicWeapon, sClassname, sizeof(sClassname));
                    bool bMedpackEquipped = StrEqual(sClassname, "weapon_medpack");

                    // check if we should abort because the target is no longer valid
                    int target = GetClientOfUserId(g_iMedpackRequested[client]);
                    if (!target)
                    {
                        if (bMedpackEquipped)
                        {
                            // change weapon back to primary for bot
                            CreateTimer(1.1, Timer_MedicChangeWeapon, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
                        }
                        // mark request completed
                        g_iMedpackRequested[client] = 0;
                    }

                    if (!bMedpackEquipped)
                    {
                        FakeClientCommand(client, "use weapon_medpack");
                        g_fEquipTime[client] = GetGameTime() + 1.0;
                    }

                    // check if we are facing the target and have medpack equipped
                    if (CanClientSeeTarget(client, target, 0.0, 0.90) && g_fEquipTime[client] < GetGameTime() && !g_bMedpackThrown[client])
                    {
                        // throw medpack
                        buttons |= IN_ATTACK;
                        g_bMedpackThrown[client] = true;
                        // set time to follow-through and keep facing the target
                        g_fFollowTime[client] = GetGameTime() + 1.2;
                    }
                    else if (g_bMedpackThrown[client])
                    {
                        // keep looking towards the target
                        ND_ClientLookAtTarget(client, target);

                        if (g_fFollowTime[client] < GetGameTime())
                        {
                            // medpack request completed
                            g_iMedpackRequested[client] = 0;
                            g_bMedpackThrown[client] = false;
                            // change weapon back to primary for bot
                            CreateTimer(1.1, Timer_MedicChangeWeapon, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
                        }
                    }
                    else
                    {
                        // look towards the target
                        ND_ClientLookAtTarget(client, target);

                        // move closer if we're too far away
                        ND_MoveCloserToTarget(client, target, angles, vel);
                    }
                }
            }
            case eNDClass_SupportEngineer:
            {
                if (g_iAmmopackRequested[client])
                {
                    int iEngineerWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
                    char sClassname[64];
                    GetEntityClassname(iEngineerWeapon, sClassname, sizeof(sClassname));
                    bool bAmmopackEquipped = StrEqual(sClassname, "weapon_ammopack");

                    int target = GetClientOfUserId(g_iAmmopackRequested[client]);
                    if (!target)
                    {
                        if (bAmmopackEquipped)
                        {
                            // change weapon back to primary for bot
                            CreateTimer(1.1, Timer_EngineerChangeWeapon, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
                        }
                        // supplies request completed
                        g_iAmmopackRequested[client] = 0;
                    }

                    if (!bAmmopackEquipped)
                    {
                        // check if we have ammopack ammo left
                        int iAmmoPacks = ND_GetAmmoByType(client, ND_AMMO_OFFSET_AMMOPACK);
                        if (iAmmoPacks)
                        {
                            FakeClientCommand(client, "use weapon_ammopack");
                            g_fEquipTime[client] = GetGameTime() + 1.0;
                        }
                        else
                        {
                            // cancel the request
                            g_iAmmopackRequested[client] = 0;
                        }
                    }

                    // check if we are facing the target and have ammopack equipped
                    if (CanClientSeeTarget(client, target, 0.0, 0.90) && g_fEquipTime[client] < GetGameTime() && !g_bAmmopackThrown[client])
                    {
                        // throw ammopack
                        buttons |= IN_ATTACK;
                        g_bAmmopackThrown[client] = true;
                        // set time to follow-through and keep facing the target
                        g_fFollowTime[client] = GetGameTime() + 1.2;
                    }
                    else if (g_bAmmopackThrown[client])
                    {
                        // keep looking towards the target
                        ND_ClientLookAtTarget(client, target);

                        if (g_fFollowTime[client] < GetGameTime())
                        {
                            // supplies request completed
                            g_iAmmopackRequested[client] = 0;
                            g_bAmmopackThrown[client] = false;
                            // change weapon back to primary for bot
                            CreateTimer(1.1, Timer_EngineerChangeWeapon, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
                        }
                    }
                    else
                    {
                        // look towards the target
                        ND_ClientLookAtTarget(client, target);

                        // move closer if we're too far away
                        ND_MoveCloserToTarget(client, target, angles, vel);
                    }
                }
            }
        }
    }

    return Plugin_Continue;
}

public Action Event_CheckAllActiveRequests(Event event, const char[] sName, bool bDontBroadcast)
{
    for (int iClient = 1; iClient <= MaxClients ; iClient++)
    {
        if (IsClientInGame(iClient))
        {
            ClearActiveRequests(iClient);
        }
    }

    return Plugin_Continue;
}

public Action Event_CheckActiveRequests(Event event, const char[] sName, bool bDontBroadcast)
{
    int iClient = GetClientOfUserId(event.GetInt("userid"));
    ClearActiveRequests(iClient);

    return Plugin_Continue;
}

void ClearActiveRequests(int iClient)
{
    if (g_iAmmopackRequested[iClient])
    {
        // supplies request completed
        g_iAmmopackRequested[iClient] = 0;
        g_bAmmopackThrown[iClient] = false;
    }

    if (g_iMedpackRequested[iClient])
    {
        g_iMedpackRequested[iClient] = 0;
        g_bMedpackThrown[iClient] = false;
    }
}

public Action Event_PlayerSpawn(Event event, const char[] sName, bool bDontBroadcast)
{
    int iPlayerUserId = event.GetInt("userid");
    CreateTimer(0.2, Timer_AssignPlayerClass, iPlayerUserId, TIMER_FLAG_NO_MAPCHANGE);

    return Plugin_Continue;
}

public Action MessageHook_SayTextTwo(UserMsg hMessageId, BfRead hBitBuffer, const int[] iPlayers, int iTotalPlayers, bool bReliableMessage, bool bInitMessage)
{
    int iClient = BfReadByte(hBitBuffer);
    int iTeam = GetClientTeam(iClient);
    BfReadByte(hBitBuffer);
    char sMessage[128];
    BfReadString(hBitBuffer, sMessage, sizeof(sMessage), true);
    if (StrEqual(sMessage, "ND_Chat_Radio"))
    {
        BfReadString(hBitBuffer, sMessage, sizeof(sMessage), true); // ignore
        BfReadString(hBitBuffer, sMessage, sizeof(sMessage), true); // ignore
        BfReadString(hBitBuffer, sMessage, sizeof(sMessage), true); // param7

        int iHelper = 0;
        if (StrEqual(sMessage, "#radio_medic"))
        {
            // find if team has any medics
            if (ND_GetCountInClass(eNDClass_SupportMedic, iTeam))
            {
                // find if there's a nearby medic
                iHelper = ND_GetNearbyTeammateInClass(iClient, eNDClass_SupportMedic, true);
                // skip if we didn't find anyone nearby or closest medic is already servicing a request
                if (iHelper && !g_iMedpackRequested[iHelper])
                {
                    // find out if the requester can see this medic
                    float fRequesterPosition[3];
                    GetClientEyePosition(iClient, fRequesterPosition);
                    float fMedicPosition[3];
                    GetClientEyePosition(iHelper, fMedicPosition);
                    if (IsPointVisible(fRequesterPosition, fMedicPosition))
                    {
                        g_iMedpackRequested[iHelper] = GetClientUserId(iClient);
                    }
                }
            }
        }
        else if (StrEqual(sMessage, "#radio_requestingsupplies"))
        {
            // find if there are any engineers
            if (ND_GetCountInClass(eNDClass_SupportEngineer, iTeam))
            {
                // find if there's a nearby engineer
                iHelper = ND_GetNearbyTeammateInClass(iClient, eNDClass_SupportEngineer, true);
                // skip if we didn't find anyone nearby or closest engineer is already servicing a request
                if (iHelper && !g_iAmmopackRequested[iHelper])
                {
                    // find out if the requester can see this engineer
                    float fRequesterPosition[3];
                    GetClientEyePosition(iClient, fRequesterPosition);
                    float fEngineerPosition[3];
                    GetClientEyePosition(iHelper, fEngineerPosition);
                    if (IsPointVisible(fRequesterPosition, fEngineerPosition))
                    {
                        g_iAmmopackRequested[iHelper] = GetClientUserId(iClient);
                    }
                }
            }
        }
    }

    return Plugin_Continue;
}

public Action Timer_EngineerChangeWeapon(Handle hTimer, any iUserId)
{
    int iClient = GetClientOfUserId(iUserId);
    if (iClient && IsClientInGame(iClient))
    {
        FakeClientCommand(iClient, "use weapon_shotgun");
    }

    return Plugin_Handled;
}

public Action Timer_MedicChangeWeapon(Handle hTimer, any iUserId)
{
    int iClient = GetClientOfUserId(iUserId);
    if (iClient && IsClientInGame(iClient))
    {
        FakeClientCommand(iClient, "use weapon_mp7");
    }

    return Plugin_Handled;
}

public Action Timer_AssignPlayerClass(Handle hTimer, any iUserId)
{
    int iClient = GetClientOfUserId(iUserId);
    // we'll only need to store this for bots
    if (iClient && IsClientInGame(iClient) && IsPlayerAlive(iClient) && IsFakeClient(iClient))
    {
        g_eNDClass[iClient] = ND_GetPlayerClass(iClient);
    }

    return Plugin_Handled;
}

void ND_MoveCloserToTarget(client, target, float angles[3], float vel[3])
{
    float fPlayerPosition[3];
    float fTargetPosition[3];
    GetClientEyePosition(client, fPlayerPosition);
    GetClientEyePosition(target, fTargetPosition);
    float fDistance = GetVectorDistance(fPlayerPosition, fTargetPosition);

    if (fDistance > MAX_NEARBY_DISTANCE)
    {
        // steer the player closer to the target
        float fVector[3];
        MakeVectorFromPoints(fPlayerPosition, fTargetPosition, fVector);
        float fDesiredAngles[3];
        GetVectorAngles(fVector, fDesiredAngles);
        angles[0] = fDesiredAngles[0];
        angles[1] = fDesiredAngles[1];
        vel[0] = 400.0;
        vel[1] = 0.0;
        vel[2] = 0.0;
    }
}

void ND_ClientLookAtTarget(int client, int target)
{
    float fGoalPosition[3];
    GetClientEyePosition(target, fGoalPosition);

    float fPosition[3];
    GetClientEyePosition(client, fPosition);

    // get normalised direction from target to client
    float fVector[3];
    MakeVectorFromPoints(fPosition, fGoalPosition, fVector);
    float fDesiredAngles[3];
    GetVectorAngles(fVector, fDesiredAngles);

    // ease the current direction to the target direction
    fDesiredAngles[0] = AngleNormalize(fDesiredAngles[0]);
    fDesiredAngles[1] = AngleNormalize(fDesiredAngles[1]);
    fDesiredAngles[2] = AngleNormalize(fDesiredAngles[2]);

    TeleportEntity(client, NULL_VECTOR, fDesiredAngles, NULL_VECTOR);
}

bool CanClientSeeTarget(int Viewer, int Target, float fMaxDistance=0.0, float fThreshold=0.70)
{
    // Retrieve view and target eyes position
    float fViewPos[3];
    GetClientEyePosition(Viewer, fViewPos);
    float fViewAng[3];
    GetClientEyeAngles(Viewer, fViewAng);
    float fViewDir[3];
    float fTargetPos[3];
    GetClientEyePosition(Target, fTargetPos);
    float fTargetDir[3];
    float fDistance[3];

    // Calculate view direction
    fViewAng[0] = fViewAng[2] = 0.0;
    GetAngleVectors(fViewAng, fViewDir, NULL_VECTOR, NULL_VECTOR);

    // Calculate distance to viewer to see if it can be seen.
    fDistance[0] = fTargetPos[0] - fViewPos[0];
    fDistance[1] = fTargetPos[1] - fViewPos[1];
    fDistance[2] = 0.0;
    if (fMaxDistance != 0.0)
    {
        if (((fDistance[0] * fDistance[0]) + (fDistance[1] * fDistance[1])) >= (fMaxDistance * fMaxDistance))
        {
            return false;
        }
    }

    // Check dot product. If it's negative, that means the viewer is facing backwards to the target.
    NormalizeVector(fDistance, fTargetDir);
    if (GetVectorDotProduct(fViewDir, fTargetDir) < fThreshold)
    {
        return false;
    }

    return IsThereObstacleBetweenPoints(fViewPos, fTargetPos);
}

bool IsThereObstacleBetweenPoints(float fViewPos[3], float fTargetPos[3])
{
    // check if there are no obstacles in between through raycasting
    Handle hTrace = TR_TraceRayFilterEx(fViewPos, fTargetPos, MASK_PLAYERSOLID_BRUSHONLY, RayType_EndPoint, ClientViewsFilter);
    if (TR_DidHit(hTrace))
    {
        CloseHandle(hTrace);
        return false;
    }

    // visible
    CloseHandle(hTrace);
    return true;
}

public bool ClientViewsFilter(int Entity, int Mask, any Junk)
{
    if (Entity >= 1 && Entity <= MaxClients)
    {
        return false;
    }

    return true;
}

bool IsPointVisible(float start[3], float end[3])
{
	TR_TraceRayFilter(start, end, MASK_PLAYERSOLID, RayType_EndPoint, TraceEntityFilterStuff);
	return TR_GetFraction() >= 0.9;
}

public bool TraceEntityFilterStuff(int entity, int mask)
{
	return entity > MaxClients;
}

float fmodf(float number, float denom)
{
    return number - RoundToFloor(number / denom) * denom;
}

float AngleNormalize(float angle)
{
    angle = fmodf(angle, 360.0);
    if (angle > 180)
    {
        angle -= 360;
    }
    if (angle < -180)
    {
        angle += 360;
    }

    return angle;
}
