/*  [ND] King of the Hill Gamemode
    Copyright (C) 2023 by databomb

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

*/

#include <sourcemod>
#include <sdktools>
#include <dhooks>
#include <sdkhooks>

#tryinclude <nd_commander_build>
#tryinclude <nd_structures>
#tryinclude <nd_ammo>
#tryinclude <nd_classes>

#pragma semicolon 1

//#define DEBUG 1

#define RELAY_TOWER_COST        1750
#define WIRELESS_REPEATER_COST  2000
#define TRANSPORT_GATE_COST     1500
#define CAPTURE_REWARD          5000
#define TRICKLE_CREDIT          200
#define KILL_REWARD             500
#define ABILITY_COST            2000

#define MAX_ABILITY_DISTANCE_FROM_PRIMARY 900.0
#define MAX_STRUCT_DISTANCE_FROM_PRIMARY 1300.0

#define GET_ENTITY_OFFSET 6

enum eNDResourceTransactionType
{
    eNDTransaction_PlayerSpawn = 0,
    eNDTransaction_Structure,
    eNDTransaction_type2,
    eNDTransaction_type3,
    eNDTransaction_Extraction,
    eNDTransaction_type5,
    eNDTransaction_Commander,
    eNDTransaction_Support,
    eNDTransaction_type8
}

enum eNDResourcePoint
{
    eNDPoint_Primary = 0,
    eNDPoint_Secondary,
    eNDPoint_Tertiary
}

enum eNDCommanderAbility
{
    eNDAbility_GroupHeal = 0,
    eNDAbility_GroupDamage,
    eNDAbility_GroupHinder
}

enum eNDRoundEndReason
{
    eNDRoundEnd_BunkerDestroyed = 0,
    eNDRoundEnd_Eliminated,
    eNDRoundEnd_Stalemate,
    eNDRoundEnd_Surrendered
}

#if !defined TEAM_CONSORT
    #define TEAM_CONSORT    2
#endif

#if !defined TEAM_EMPIRE
    #define TEAM_EMPIRE     3
#endif

#if !defined _nd_commmander_build_included_

    /**
     * Allows a plugin to block a structure form being built by returning Plugin_Stop.
     *
     * @param client                    client index of the Commander who attempted to build the structures
     * @param ND_Structures structure   type of structure being built
     * @param float position[3]         x,y,z coordinate of where structure is being built
     * @return                          Action that should be taken (Plugin_Stop to prevent building)
     */
    forward Action ND_OnCommanderBuildStructure(client, ND_Structures &structure, float position[3]);

    // This helper function will display red text and a failed sound to the commander
    stock void UTIL_Commander_FailureText(int iClient, char sMessage[64])
    {
        ClientCommand(iClient, "play buttons/button7");

        Handle hBfCommanderText;
        hBfCommanderText = StartMessageOne("CommanderNotice", iClient, USERMSG_BLOCKHOOKS);
        BfWriteString(hBfCommanderText, sMessage);
        EndMessage();

        // clear other messages from notice area
        hBfCommanderText = StartMessageOne("CommanderNotice", iClient, USERMSG_BLOCKHOOKS);
        BfWriteString(hBfCommanderText, "");
        EndMessage();
    }

#endif

#if !defined _nd_structures_included

    enum ND_Structures: {
        ND_Command_Bunker,
        ND_MG_Turret,
        ND_Transport_Gate,
        ND_Power_Plant,
        ND_Wireless_Repeater,
        ND_Relay_Tower,
        ND_Supply_Station,
        ND_Assembler,
        ND_Armory,
        ND_Artillery,
        ND_Radar_Station,
        ND_FT_Turret,
        ND_Sonic_Turret,
        ND_Rocket_Turret,
        ND_Wall,
        ND_Barrier,
        ND_StructCount
    }

#endif

#if !defined _nd_ammo_included_

    #define ND_AMMO_OFFSET_HYPOSPRAY        2
    #define ND_AMMO_OFFSET_BAG90            4
    #define ND_AMMO_OFFSET_ASSAULT_CONSORT  6
    #define ND_AMMO_OFFSET_ASSAULT_EMPIRE   7
    #define ND_AMMO_OFFSET_MP500            8
    #define ND_AMMO_OFFSET_SP5              9
    #define ND_AMMO_OFFSET_MP7              10
    #define ND_AMMO_OFFSET_SNIPERRIFLE      12
    #define ND_AMMO_OFFSET_EXOGAU           14
    #define ND_AMMO_OFFSET_FLAMETHROWER     15
    #define ND_AMMO_OFFSET_SHOTGUN          16
    #define ND_AMMO_OFFSET_GRENADETHROWER   19
    #define ND_AMMO_OFFSET_RED              21
    #define ND_AMMO_OFFSET_EMP              22
    #define ND_AMMO_OFFSET_FRAG             23
    #define ND_AMMO_OFFSET_DAISYCUTTER      25
    #define ND_AMMO_OFFSET_AMMOPACK         26
    #define ND_AMMO_OFFSET_X01SEIGE         27
    #define ND_AMMO_OFFSET_POISONGAS        29

    // sets the ammo quantity given one of the ND_AMMO_OFFSET values supplied as the type
    stock bool ND_SetAmmoByType(int client, int type, int ammo)
    {
        if (!client || client > MaxClients || !IsClientInGame(client) || !IsPlayerAlive(client))
        {
            return false;
        }

        int iAmmoOffset = FindDataMapInfo(client, "m_iAmmo");
        if (iAmmoOffset == -1)
        {
            return false;
        }

        SetEntData(client, iAmmoOffset + type*4, ammo);
        return true;
    }

#endif

#if !defined _nd_classes_included_

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

#endif

#define MAYCAPTURE_PARAM_TEAM               1
#define MAYCAPTURE_PARAM_RESOURCE_POINT     2

#define COMMANDER_ABILITY_PARAM_CNDPLAYER   1
#define COMMANDER_ABILITY_PARAM_POSITION    2

#define FIRE_ARTILLERY_PARAM_POSITION       1
#define FIRE_ARTILLERY_PARAM_CNDPLAYER      2

#define RUNABILITY_PARAM_CNDPLAYER          1
#define RUNABILITY_PARAM_ORIGIN             2

#define PLUGIN_VERSION "1.0.11"

ConVar g_cRoundTime;
bool g_bLateLoad = false;
bool g_bGameStarted = false;
int g_iKingOfTheHillTeam = 0;
int g_iScore[2] = {0, 0};
int g_iTeamEntity[2] = {-1, -1};
int g_iPrimaryPointEntityRef = INVALID_ENT_REFERENCE;
Handle g_hSDKCall_ReceiveResources = INVALID_HANDLE;
Handle g_hSDKCall_SpendResources = INVALID_HANDLE;
Handle g_hSDKCall_SetRoundWinner = INVALID_HANDLE;
Handle g_hSDKCall_GetEntity = INVALID_HANDLE;
Handle g_hTimer_TerminateRound = INVALID_HANDLE;
float g_fPrimaryPointPosition[3] = {-1.0, -1.0, -1.0};
float g_fBunkerEmpirePosition[3] = {-1.0, -1.0, -1.0};
float g_fBunkerConsortPosition[3] = {-1.0, -1.0, -1.0};

public Plugin myinfo =
{
    name = "[ND] King of the Hill Gamemmode",
    author = "databomb",
    description = "Gamemode for a king of the hill battle over the primary resource point",
    version = PLUGIN_VERSION,
    url = "https://forums.alliedmods.net/member.php?u=54648"
};

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iMaxErrors)
{
    if (bLate)
    {
        g_bLateLoad = true;
    }

    return APLRes_Success;
}

// check for dependency on nd_structure_intercept
public void OnAllPluginsLoaded()
{
    if (!LibraryExists("nd_structure_intercept"))
    {
        SetFailState("Failed to find plugin dependency nd_structure_intercept");
    }
}

public void OnPluginStart()
{
    CreateConVar("nd_koth_version", PLUGIN_VERSION, "ND King of the Hill Version", FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);

    GameData hGameDataResource = new GameData("resource-points.games");
    if (!hGameDataResource)
    {
        SetFailState("Failed to find gamedata/resource-points.games.txt");
    }

    DynamicDetour detourPlayerBuildStructure = DynamicDetour.FromConf(hGameDataResource, "CNuclearDawn::TeamMayCapturePoint");
    if (!detourPlayerBuildStructure)
    {
        SetFailState("Failed to find signature CNuclearDawn::TeamMayCapturePoint");
    }

    detourPlayerBuildStructure.Enable(Hook_Pre, Detour_TeamMayCapturePoint);
    delete detourPlayerBuildStructure;

    DynamicDetour detourSelectPointToCapture = DynamicDetour.FromConf(hGameDataResource, "CNDPlayerBot::SelectResourcePointToCapture");
    if (!detourSelectPointToCapture)
    {
        SetFailState("Failed to find signature CNDPlayerBot::SelectResourcePointToCapture");
    }

    detourSelectPointToCapture.Enable(Hook_Post, Detour_SelectCapturePoint);
    delete detourSelectPointToCapture;

    DynamicDetour detourSelectPointToDefend = DynamicDetour.FromConf(hGameDataResource, "CNDPlayerBot::SelectResourcePointToDefend");
    if (!detourSelectPointToDefend)
    {
        SetFailState("Failed to find signature CNDPlayerBot::SelectResourcePointToDefend");
    }

    detourSelectPointToDefend.Enable(Hook_Post, Detour_SelectDefensePoint);
    delete detourSelectPointToDefend;

    GameData hGameDataAbilities = new GameData("commander-abilities.games");
    if (!hGameDataAbilities)
    {
        SetFailState("Failed to find gamedata/commander-abilities.games.txt");
    }

    DynamicDetour detourRunDamageAbility = DynamicDetour.FromConf(hGameDataAbilities, "CNDCommanderDamageAbility::RunAbility");
    if (!detourRunDamageAbility)
    {
        SetFailState("Failed to find signature CNDCommanderDamageAbility::RunAbility");
    }

    detourRunDamageAbility.Enable(Hook_Pre, Detour_RunCommanderAbility);
    delete detourRunDamageAbility;

    DynamicDetour detourRunHealAbility = DynamicDetour.FromConf(hGameDataAbilities, "CNDCommanderHealAbility::RunAbility");
    if (!detourRunHealAbility)
    {
        SetFailState("Failed to find signature CNDCommanderHealAbility::RunAbility");
    }

    detourRunHealAbility.Enable(Hook_Pre, Detour_RunCommanderAbility);
    delete detourRunHealAbility;

    DynamicDetour detourRunHinderAbility = DynamicDetour.FromConf(hGameDataAbilities, "CNDCommanderHinderAbility::RunAbility");
    if (!detourRunHinderAbility)
    {
        SetFailState("Failed to find signature CNDCommanderHinderAbility::RunAbility");
    }

    detourRunHinderAbility.Enable(Hook_Pre, Detour_RunCommanderAbility);
    delete detourRunHinderAbility;

    DynamicDetour detourFireArtillery = DynamicDetour.FromConf(hGameDataAbilities, "CNDBaseArtillery::FireAtPosition");
    if (!detourFireArtillery)
    {
        SetFailState("Failed to find signature CNDBaseArtillery::FireAtPosition");
    }

    detourFireArtillery.Enable(Hook_Pre, Detour_FireArtilleryAtPosition);
    delete detourFireArtillery;

    // prep a call to give a team resources
    StartPrepSDKCall(SDKCall_GameRules);
    bool bSuccess = PrepSDKCall_SetFromConf(hGameDataResource, SDKConf_Signature, "CNuclearDawn::ReceiveResources");
    if (!bSuccess)
    {
        SetFailState("Failed to find signature CNuclearDawn::ReceiveResources");
    }
    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
    g_hSDKCall_ReceiveResources = EndPrepSDKCall();

    if (!g_hSDKCall_ReceiveResources)
    {
        SetFailState("Failed to establish SDKCall for CNuclearDawn::ReceiveResources");
    }

    // prep a call to take resources away
    StartPrepSDKCall(SDKCall_GameRules);
    bSuccess = PrepSDKCall_SetFromConf(hGameDataResource, SDKConf_Signature, "CNuclearDawn::SpendResources");
    if (!bSuccess)
    {
        SetFailState("Failed to find signature CNuclearDawn::SpendResources");
    }
    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
    g_hSDKCall_SpendResources = EndPrepSDKCall();

    if (!g_hSDKCall_SpendResources)
    {
        SetFailState("Failed to establish SDKCall for CNuclearDawn::SpendResources");
    }

    GameData hTerminateRound = new GameData("terminate-round.games");
    if (!hTerminateRound)
    {
        SetFailState("Failed to find gamedata/terminate-round.games.txt");
    }

    // prep a call to set the winner and end the round
    StartPrepSDKCall(SDKCall_GameRules);
    bSuccess = PrepSDKCall_SetFromConf(hTerminateRound, SDKConf_Signature, "CNuclearDawn::SetRoundWin");
    if (!bSuccess)
    {
        SetFailState("Failed to find signature CNuclearDawn::SetRoundWin");
    }
    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
    g_hSDKCall_SetRoundWinner = EndPrepSDKCall();

    if (!g_hSDKCall_SetRoundWinner)
    {
        SetFailState("Failed to establish SDKCall for CNuclearDawn::SetRoundWin");
    }

    delete hGameDataAbilities;
    delete hGameDataResource;
    delete hTerminateRound;

    UserMsg hReceiveMessage = GetUserMessageId("RecieveResources");
    if (hReceiveMessage == INVALID_MESSAGE_ID)
    {
        SetFailState("Failed to find user message RecieveResources");
    }

    HookUserMessage(hReceiveMessage, MessageHook_RecieveResources);

    // prepare a call to receive an entity from a base pointer address
    StartPrepSDKCall(SDKCall_Raw);
    PrepSDKCall_SetVirtual(GET_ENTITY_OFFSET);
    PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
    g_hSDKCall_GetEntity = EndPrepSDKCall();

    if (!g_hSDKCall_GetEntity)
    {
        SetFailState("Failed to establish SDKCall for x::GetEntity");
    }

    g_cRoundTime = FindConVar("mp_roundtime");
    if (!g_cRoundTime)
    {
        SetFailState("Unable to find mp_roundtime");
    }

    HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
    HookEvent("resource_captured", Event_ResourceCaptured, EventHookMode_Post);
    HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
    HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
    HookEvent("player_changeclass", Event_PlayerClass, EventHookMode_Post);
    HookEvent("round_win", Event_RoundWin, EventHookMode_Post);

    if (g_bLateLoad)
    {
        ND_FindMapEntities();
    }

}

void KingOfTheHill_EndRound()
{
    // determine winner
    if (g_iScore[TEAM_CONSORT-2] == g_iScore[TEAM_EMPIRE-2])
    {
        // stalemate
        SDKCall(g_hSDKCall_SetRoundWinner, 0, view_as<int>(eNDRoundEnd_Stalemate));
    }
    else
    {
        int iWinningTeam = (g_iScore[TEAM_CONSORT-2] > g_iScore[TEAM_EMPIRE-2] ? TEAM_CONSORT : TEAM_EMPIRE);
        // other team "eliminated"
        SDKCall(g_hSDKCall_SetRoundWinner, iWinningTeam, view_as<int>(eNDRoundEnd_Eliminated));
    }
}

public Action Event_PlayerSpawn(Event event, const char[] sName, bool bDontBroadcast)
{
    int iPlayer = GetClientOfUserId(event.GetInt("userid"));
    ND_LimitNadesForLeader(iPlayer);

    return Plugin_Continue;
}

public Action Event_PlayerClass(Event event, const char[] sName, bool bDontBroadcast)
{
    int iPlayer = GetClientOfUserId(event.GetInt("userid"));
    ND_LimitNadesForLeader(iPlayer);

    return Plugin_Continue;
}

stock void ND_LimitNadesForLeader(int iPlayer)
{
    int iTeam = GetClientTeam(iPlayer);

    if (iTeam == g_iKingOfTheHillTeam)
    {
        CreateTimer(0.1, Timer_LimitNades, GetClientUserId(iPlayer), TIMER_FLAG_NO_MAPCHANGE);
    }
}

public Action Timer_LimitNades(Handle hTimer, any iPlayerUserId)
{
    int iPlayer = GetClientOfUserId(iPlayerUserId);
    if (iPlayer && IsPlayerAlive(iPlayer))
    {
        eNDClass ePlayerClass = ND_GetPlayerClass(iPlayer);
        // limit the grenades if the team is winning
        switch (ePlayerClass)
        {
            case eNDClass_SupportMedic:
            {
                ND_SetAmmoByType(iPlayer, ND_AMMO_OFFSET_POISONGAS, 1);
            }
            case eNDClass_SupportBBQ:
            {
                ND_SetAmmoByType(iPlayer, ND_AMMO_OFFSET_POISONGAS, 2);
            }
            case eNDClass_AssaultInfantry:
            {
                ND_SetAmmoByType(iPlayer, ND_AMMO_OFFSET_FRAG, 1);
            }
            case eNDClass_AssaultGrenadier:
            {
                ND_SetAmmoByType(iPlayer, ND_AMMO_OFFSET_FRAG, 2);
            }
            case eNDClass_StealthSabateur:
            {
                ND_SetAmmoByType(iPlayer, ND_AMMO_OFFSET_RED, 2);
            }
            case eNDClass_AssaultSniper:
            {
                ND_SetAmmoByType(iPlayer, ND_AMMO_OFFSET_DAISYCUTTER, 1);
            }
            case eNDClass_SupportEngineer:
            {
                ND_SetAmmoByType(iPlayer, ND_AMMO_OFFSET_DAISYCUTTER, 1);
                ND_SetAmmoByType(iPlayer, ND_AMMO_OFFSET_AMMOPACK, 1);
            }
        }
    }

    return Plugin_Continue;
}

public Action Event_PlayerDeath(Event event, const char[] sName, bool bDontBroadcast)
{
    int iVictim = GetClientOfUserId(event.GetInt("userid"));
    int iTeam = GetClientTeam(iVictim);

    if (iTeam == g_iKingOfTheHillTeam)
    {
        // reward opposite team
        int iRewardTeam = (iTeam == TEAM_EMPIRE ? TEAM_CONSORT : TEAM_EMPIRE);
        SDKCall(g_hSDKCall_ReceiveResources, iRewardTeam, KILL_REWARD, eNDTransaction_Support);
    }

    return Plugin_Continue;
}

public Action Event_ResourceCaptured(Event event, const char[] sName, bool bDontBroadcast)
{
    eNDResourcePoint eType = view_as<eNDResourcePoint>(event.GetInt("type"));
    int iTeam = event.GetInt("team");

    // opposing team has taken the primary point
    if ((eType == eNDPoint_Primary) && iTeam && (g_iKingOfTheHillTeam != iTeam))
    {
        g_iKingOfTheHillTeam = iTeam;
        SDKCall(g_hSDKCall_ReceiveResources, iTeam, CAPTURE_REWARD, eNDTransaction_Support);
    }
    // someone has taken it back to neutral but not claimed it for themselves yet
    else if ((eType == eNDPoint_Primary) && !iTeam)
    {
        g_iKingOfTheHillTeam = 0;
    }

    return Plugin_Continue;
}

public Action Event_RoundWin(Event event, const char[] sName, bool bDontBroadcast)
{
    g_bGameStarted = false;
    g_iKingOfTheHillTeam = 0;

    PrintToChatAll("Consort score: %d", g_iScore[TEAM_CONSORT-2]);
    PrintToChatAll("Empire score:  %d", g_iScore[TEAM_EMPIRE-2]);
    return Plugin_Continue;
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    g_bGameStarted = true;
    g_iKingOfTheHillTeam = 0;
    g_iScore = {0, 0};

    // change default starting resources
    CreateTimer(5.0, Timer_SetResources);

    if (g_hTimer_TerminateRound != INVALID_HANDLE)
    {
        CloseHandle(g_hTimer_TerminateRound);
    }

    // check for an invalid round time and provides default 15 min roundtime
    if (g_cRoundTime.IntValue < 0)
    {
        g_cRoundTime.SetInt(15, true, true);
    }

    // determine when to end the round
    g_hTimer_TerminateRound = CreateTimer(60.0*float(g_cRoundTime.IntValue)-1.0, Timer_TerminateRound, _, TIMER_FLAG_NO_MAPCHANGE);
    // calculate time needed (in seconds) to clinch victory
    int iClinchTime = (60 * g_cRoundTime.IntValue)/2 + 1;

    #if defined DEBUG
    PrintToServer("Clinch time set to %d seconds.", iClinchTime);
    #endif

    ND_FindMapEntities();

    // keep track of the score
    CreateTimer(1.0, Timer_UpdateScore, iClinchTime, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);

    // protect all starting structures from damage
    char sEntityName[32];
    int iMaxEntities = GetMaxEntities();
    int iTeamNum;
    for (int iEntityIndex = MaxClients; iEntityIndex < iMaxEntities; iEntityIndex++)
    {
        if (IsValidEntity(iEntityIndex) && IsValidEdict(iEntityIndex))
        {
            GetEdictClassname(iEntityIndex, sEntityName, sizeof(sEntityName));
            if (!strncmp(sEntityName, "struct_", 7))
            {
                #if defined DEBUG
                PrintToServer("Hooked %s (%d) for damage protection", sEntityName, iEntityIndex);
                #endif

                SDKHook(iEntityIndex, SDKHook_OnTakeDamage, Starting_Structure_Protection);

                // save command bunkers for later
                if (!strcmp(sEntityName, "struct_command_bunker"))
                {
                    iTeamNum = GetEntProp(iEntityIndex, Prop_Send, "m_iTeamNum", 4);
                    if (iTeamNum == TEAM_EMPIRE)
                    {
                        GetEntPropVector(iEntityIndex, Prop_Data, "m_vecOrigin", g_fBunkerEmpirePosition);
                    }
                    else if (iTeamNum == TEAM_CONSORT)
                    {
                        GetEntPropVector(iEntityIndex, Prop_Data, "m_vecOrigin", g_fBunkerConsortPosition);
                    }
                }
            }
        }
    }

    return Plugin_Continue;
}

public OnMapEnd()
{
    g_bGameStarted = false;
    g_iKingOfTheHillTeam = 0;
}

public OnMapStart()
{
    g_bGameStarted = false;
    g_iKingOfTheHillTeam = 0;
}

public Action Starting_Structure_Protection(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& weapon, float damageForce[3], float damagePosition[3])
{
    if ((victim != attacker) && (victim > 0) && (attacker > 0) && (attacker <= MaxClients))
    {
        damage = 0.0;
        return Plugin_Changed;
    }

    return Plugin_Continue;
}

public void OnEntityCreated(int iEntityIndex, const char[] sClassName)
{
    if (g_bGameStarted && !strncmp(sClassName, "struct_", 7))
    {
        #if defined DEBUG
        PrintToServer("Hooked %s (%d) for damage attenuation", sClassName, iEntityIndex);
        #endif

        SDKHook(iEntityIndex, SDKHook_OnTakeDamage, Structure_Damage_Attenuation);
    }
}


public Action Structure_Damage_Attenuation(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& weapon, float damageForce[3], float damagePosition[3])
{
    if ((victim != attacker) && (victim > 0) && (attacker > 0) && (attacker <= MaxClients))
    {
        damage = damage * 0.86;
        return Plugin_Changed;
    }

    return Plugin_Continue;
}

public Action ND_OnCommanderBuildStructure(client, ND_Structures &structure, float position[3])
{
    float fDistanceFromPrimaryPoint = GetVectorDistance(position, g_fPrimaryPointPosition);
    if (fDistanceFromPrimaryPoint < MAX_STRUCT_DISTANCE_FROM_PRIMARY)
    {
        UTIL_Commander_FailureText(client, "BUILDING TOO CLOSE TO PRIMARY POINT.");

        #if defined DEBUG
        PrintToServer("blocked building %d too near primary point", structure);
        #endif

        return Plugin_Stop;
    }

    float fDistanceToEmpireBunker = GetVectorDistance(position, g_fBunkerEmpirePosition);
    float fDistanceToConsortBunker = GetVectorDistance(position, g_fBunkerConsortPosition);
    int iTeam = GetClientTeam(client);

    if (iTeam == TEAM_EMPIRE && fDistanceToEmpireBunker > fDistanceToConsortBunker)
    {
        UTIL_Commander_FailureText(client, "BUILDING TOO CLOSE TO ENEMY BUNKER.");

        #if defined DEBUG
        PrintToServer("blocked empire building %d too far away from bunker", structure);
        #endif

        return Plugin_Stop;
    }
    else if (iTeam == TEAM_CONSORT && fDistanceToConsortBunker > fDistanceToEmpireBunker)
    {
        UTIL_Commander_FailureText(client, "BUILDING TOO CLOSE TO ENEMY BUNKER.");

        #if defined DEBUG
        PrintToServer("blocked consort building %d too far away form bunker", structure);
        #endif

        return Plugin_Stop;
    }

    #if defined DEBUG
    PrintToServer("distance to empire %2.f distance to consort %2.f", fDistanceToEmpireBunker, fDistanceToConsortBunker);
    #endif

    return Plugin_Continue;
}

MRESReturn Detour_SelectDefensePoint(DHookReturn hReturn, DHookParam hParams)
{
    int iResourcePoint = DHookGetReturn(hReturn);

    if (iResourcePoint != 0)
    {
        int iPrimaryPoint = EntRefToEntIndex(g_iPrimaryPointEntityRef);
        DHookSetReturn(hReturn, iPrimaryPoint);
        return MRES_Override;
    }

    return MRES_Ignored;
}

MRESReturn Detour_SelectCapturePoint(DHookReturn hReturn, DHookParam hParams)
{
    int iResourcePoint = DHookGetReturn(hReturn);

    if (iResourcePoint != 0)
    {
        int iPrimaryPoint = EntRefToEntIndex(g_iPrimaryPointEntityRef);
        DHookSetReturn(hReturn, iPrimaryPoint);
        return MRES_Override;
    }

    return MRES_Ignored;
}

MRESReturn Detour_TeamMayCapturePoint(DHookReturn hReturn, DHookParam hParams)
{
    //int iTeam = DHookGetParam(hParams, MAYCAPTURE_PARAM_TEAM);
    Address pBaseResourcePoint = DHookGetParamAddress(hParams, MAYCAPTURE_PARAM_RESOURCE_POINT);
    int iEntity = SDKCall(g_hSDKCall_GetEntity, pBaseResourcePoint);

    // determine if we're primary, secondary, or tertiary
    eNDResourcePoint eResourcePoint = eNDPoint_Primary;
    if (IsValidEntity(iEntity))
    {
        eResourcePoint = view_as<eNDResourcePoint>(GetEntProp(iEntity, Prop_Send, "m_iNetResourcePointType", 4));
    }

    if (eResourcePoint != eNDPoint_Primary)
    {
        DHookSetReturn(hReturn, false);
        return MRES_Supercede;
    }

    return MRES_Ignored;
}

MRESReturn Detour_FireArtilleryAtPosition(DHookParam hParams)
{
    Address pPlayer = DHookGetParamAddress(hParams, FIRE_ARTILLERY_PARAM_CNDPLAYER);
    int iPlayer = SDKCall(g_hSDKCall_GetEntity, pPlayer);

    float fPosition[3];
    DHookGetParamVector(hParams, FIRE_ARTILLERY_PARAM_POSITION, fPosition);

    #if defined DEBUG
    PrintToServer("Artillery position x %2.f y %2.f z %2.f", fPosition[0], fPosition[1], fPosition[2]);
    #endif

    float fDistanceFromPrimaryPoint = GetVectorDistance(fPosition, g_fPrimaryPointPosition);

    #if defined DEBUG
    PrintToServer("artillery distance from primary point %2.f", fDistanceFromPrimaryPoint);
    #endif

    if (fDistanceFromPrimaryPoint < MAX_ABILITY_DISTANCE_FROM_PRIMARY)
    {
        // communicate to player who called artillery
        if (iPlayer)
        {
            // was it a player callable strike or chair-directed strike
            int iTeam = GetClientTeam(iPlayer);
            bool bIsCommander = (GameRules_GetPropEnt("m_hCommanders", iTeam-2) == iPlayer);
            // determine if commander is in the chair or not
            MoveType eMoveType = GetEntityMoveType(iPlayer);
            if (bIsCommander && (eMoveType == MOVETYPE_ISOMETRIC))
            {
                UTIL_Commander_FailureText(iPlayer, "STRIKE TOO CLOSE TO PRIMARY POINT.");
            }
            else
            {
                PrintToChat(iPlayer, "[ND] Cannot call artillery that close to primary point.");
            }
        }

        return MRES_Supercede;
    }

    return MRES_Ignored;
}

MRESReturn Detour_RunCommanderAbility(DHookParam hParams)
{
    Address pPlayer = DHookGetParamAddress(hParams, COMMANDER_ABILITY_PARAM_CNDPLAYER);
    int iPlayer = SDKCall(g_hSDKCall_GetEntity, pPlayer);

    float fPosition[3];
    DHookGetParamVector(hParams, COMMANDER_ABILITY_PARAM_POSITION, fPosition);

    #if defined DEBUG
    PrintToServer("Ability position x %2.f y %2.f z %2.f", fPosition[0], fPosition[1], fPosition[2]);
    #endif

    float fDistanceFromPrimaryPoint = GetVectorDistance(fPosition, g_fPrimaryPointPosition);

    #if defined DEBUG
    PrintToServer("ability distance from primary point %2.f", fDistanceFromPrimaryPoint);
    #endif

    if (fDistanceFromPrimaryPoint < MAX_ABILITY_DISTANCE_FROM_PRIMARY)
    {
        // communicate to only the commander
        UTIL_Commander_FailureText(iPlayer, "ABILITY TOO CLOSE TO PRIMARY POINT.");

        // refund cost without corrupting resource/minute data
        int iTeam = GetClientTeam(iPlayer);
        SDKCall(g_hSDKCall_ReceiveResources, iTeam, ABILITY_COST, eNDTransaction_Commander);

        return MRES_Supercede;
    }

    return MRES_Ignored;
}

public Action MessageHook_RecieveResources(UserMsg hMessageId, BfRead hBitBuffer, const int[] iPlayers, int iTotalPlayers, bool bReliableMessage, bool bInitMessage)
{
    int iTeam = BfReadShort(hBitBuffer);
    int iResources = BfReadShort(hBitBuffer);
    eNDResourceTransactionType eType = view_as<eNDResourceTransactionType>(BfReadShort(hBitBuffer));

    if (eType == eNDTransaction_Extraction && (iTeam == TEAM_EMPIRE || iTeam == TEAM_CONSORT))
    {
        DataPack hReceiveData = new DataPack();
        hReceiveData.WriteCell(iTeam);
        hReceiveData.WriteCell(iResources);
        hReceiveData.Reset(false);

        // increase trickle credits but take back resource point extraction credits
        if (iResources > 100)
        {
            CreateTimer(0.0, Timer_IssueDebit, hReceiveData, TIMER_FLAG_NO_MAPCHANGE);
        }
        else
        {
            CreateTimer(0.0, Timer_IncreaseCredit, hReceiveData, TIMER_FLAG_NO_MAPCHANGE);
        }

        return Plugin_Handled;
    }

    return Plugin_Continue;
}

public Action Timer_IssueDebit(Handle hTimer, DataPack hReceiveData)
{
    int iTeam = hReceiveData.ReadCell();
    int iResources = hReceiveData.ReadCell();
    delete hReceiveData;
    SDKCall(g_hSDKCall_SpendResources, iTeam, iResources, eNDTransaction_Extraction);

    return Plugin_Stop;
}

public Action Timer_IncreaseCredit(Handle hTimer, DataPack hReceiveData)
{
    int iTeam = hReceiveData.ReadCell();
    delete hReceiveData;
    SDKCall(g_hSDKCall_ReceiveResources, iTeam, TRICKLE_CREDIT, eNDTransaction_Support);

    return Plugin_Stop;
}

public Action Timer_SetResources(Handle hTimer)
{
    int iEmpireStartingResources = 2*TRANSPORT_GATE_COST + 2*RELAY_TOWER_COST + 1000;
    int iConsortiumStartingResources = 2*TRANSPORT_GATE_COST + 2*WIRELESS_REPEATER_COST + 1000;

    SetEntProp(g_iTeamEntity[TEAM_EMPIRE-2], Prop_Send, "m_iResourcePoints", iEmpireStartingResources);
    SetEntProp(g_iTeamEntity[TEAM_CONSORT-2], Prop_Send, "m_iResourcePoints", iConsortiumStartingResources);

    return Plugin_Stop;
}

public Action Timer_TerminateRound(Handle hTimer)
{
    KingOfTheHill_EndRound();
    g_hTimer_TerminateRound = INVALID_HANDLE;
    return Plugin_Stop;
}

public Action Timer_UpdateScore(Handle hTimer, any iClinchTime)
{
    if (g_iKingOfTheHillTeam == TEAM_CONSORT)
    {
        g_iScore[TEAM_CONSORT-2]++;
    }
    else if (g_iKingOfTheHillTeam == TEAM_EMPIRE)
    {
        g_iScore[TEAM_EMPIRE-2]++;
    }

    // evaluate if either team has clinched victory
    if (g_iScore[TEAM_CONSORT-2] >= iClinchTime || g_iScore[TEAM_EMPIRE-2] >= iClinchTime)
    {
        KingOfTheHill_EndRound();
    }

    if (!g_bGameStarted)
    {
        return Plugin_Stop;
    }

    return Plugin_Continue;
}

stock void ND_FindMapEntities()
{
    // find and save the single primary resource point for the map
    int iPrimaryPointEntity = FindEntityByClassname(-1, "nd_info_primary_resource_point");
    g_iPrimaryPointEntityRef = EntIndexToEntRef(iPrimaryPointEntity);
    GetEntPropVector(iPrimaryPointEntity, Prop_Data, "m_vecOrigin", g_fPrimaryPointPosition);

    #if defined DEBUG
    PrintToServer("primary point position is %2.f %2.f %2.f", g_fPrimaryPointPosition[0], g_fPrimaryPointPosition[1], g_fPrimaryPointPosition[2]);
    #endif

    // find and save team entities
    g_iTeamEntity[TEAM_CONSORT-2] = FindEntityByClassname(-1, "nd_team_consortium");
    g_iTeamEntity[TEAM_EMPIRE-2] = FindEntityByClassname(-1, "nd_team_empire");
}
