#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <dhooks>

ConVar mp_autoteambalance;
ConVar sm_kst_respawndelay;
ConVar sm_kst_message;
ConVar sm_kst_respawn_spot;

int playerSelectedTeam[MAXPLAYERS+1];
float vecDeathOrigin[MAXPLAYERS+1][3];
bool bShouldRespawnAtDeathPosition[MAXPLAYERS+1];

bool bShouldSwitchTeam;

DynamicDetour ddOnPlayerJoinTeam;

GameData g_pGameConfig;

bool bIsWindowsOS;

public Plugin myinfo =
{
	name = "[CSS] Killed player joins attacker team",
	author = "XeroX",
	description = "Player that is killed joins the killers team",
	version = "1.0.0",
	url = "https://forums.alliedmods.net/showthread.php?t=337171"
}

public void OnPluginStart()
{
    g_pGameConfig = new GameData("css_killed_switches_team");
    if(g_pGameConfig == null)
    {
        SetFailState("css_killed_switches_team.txt is missing in the gamedata folder!");
        return;
    }

    bIsWindowsOS = (g_pGameConfig.GetOffset("OS") == 1);

    HookEvent("player_death", Event_PlayerDeath);
    HookEvent("round_end", Event_RoundEnd);
    HookEvent("round_freeze_end", Event_FreezeEnd);

    HookEvent("player_falldamage", Event_PlayerFallDamage);

    mp_autoteambalance = FindConVar("mp_autoteambalance");

    mp_autoteambalance.SetBool(false, false, true);

    mp_autoteambalance.AddChangeHook(OnAutoBalancedChanged);

    sm_kst_respawndelay = CreateConVar("sm_kst_respawndelay", "5", "How much time (in seconds) should pass before the killed player is switched over to the attackers team and respawned");
    sm_kst_message = CreateConVar("sm_kst_message", "1", "Toggle whether the killed player gets a chat notification that they have been switched to the killers team", FCVAR_NONE, true, 0.0, true, 1.0);
    sm_kst_respawn_spot = CreateConVar("sm_kst_respawn_spot", "0", "Determine where the respawned player will spawn. 0 = default spawn point. 1 = Where the player previously died", FCVAR_NONE, true, 0.0, true, 1.0);

    AutoExecConfig();

    ddOnPlayerJoinTeam = DynamicDetour.FromConf(g_pGameConfig, "OnPlayerJoinTeam");
    ddOnPlayerJoinTeam.Enable(Hook_Post, Detour_OnPlayerJoinTeam);
}

public void OnAutoBalancedChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if(StringToInt(newValue) != 0)
    {
        mp_autoteambalance.SetBool(false, false, true);
    }
}

public void OnClientPutInServer(int client)
{
    playerSelectedTeam[client] = CS_TEAM_NONE;

    vecDeathOrigin[client][0] = 0.0;
    vecDeathOrigin[client][1] = 0.0;
    vecDeathOrigin[client][2] = 0.0;

    bShouldRespawnAtDeathPosition[client] = true;
}

public void Event_PlayerFallDamage(Event event, const char[] szName, bool dontBroadcast)
{
    int victim = GetClientOfUserId(event.GetInt("userid"));
    float flDamage = event.GetFloat("damage");

    // Fatal Fall damage.
    if(RoundToNearest(flDamage) >= GetClientHealth(victim))
    {
        bShouldRespawnAtDeathPosition[victim] = false;
    }
}

public void Event_FreezeEnd(Event event, const char[] szName, bool dontBroadcast)
{
    bShouldSwitchTeam = true;
}
public void Event_PlayerDeath(Event event, const char[] szName, bool dontBroadcast)
{
    int userid = event.GetInt("userid");
    int victim = GetClientOfUserId(userid);

    if(!IsClientInGame(victim))
        return;
    
    if(bShouldRespawnAtDeathPosition[victim])
    {
        GetClientAbsOrigin(victim, vecDeathOrigin[victim]);

        float vecOrigin[3];

        vecOrigin[0] = vecDeathOrigin[victim][0];
        vecOrigin[1] = vecDeathOrigin[victim][1];
        vecOrigin[2] = vecDeathOrigin[victim][2];

        float vecDown[3];

        vecDown[0] = 0.0;
        vecDown[1] = 0.0;
        vecDown[2] = 500.0;

        SubtractVectors(vecOrigin, vecDown, vecDown);
        Handle tr;
        tr = TR_TraceRayEx(vecDeathOrigin[victim], vecDown, MASK_SHOT, RayType_EndPoint);
        if(TR_DidHit(tr))
        {
            if(TR_GetEntityIndex(tr) == 0)
            {
                TR_GetEndPosition(vecDeathOrigin[victim], tr);
                vecDeathOrigin[victim][2] += 0.5;
            }
        }
    }

    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    int attackerTeam = CS_TEAM_SPECTATOR;
    if(attacker > 0 && attacker < MaxClients)
    {
        if(IsClientInGame(attacker))
        {
            attackerTeam = GetClientTeam(attacker);
        }
    }
    else
    {
        attackerTeam = GetOppositeTeam(victim);
    }
    

    DataPack dp;
    CreateDataTimer(sm_kst_respawndelay.FloatValue, t_RespawnPlayer, dp, TIMER_FLAG_NO_MAPCHANGE);
    
    dp.WriteCell(userid);
    dp.WriteCell(attackerTeam);
}

public Action t_RespawnPlayer(Handle timer, any datapack)
{
    if(!bShouldSwitchTeam)
        return;
    
    DataPack dp = view_as<DataPack>(datapack);
    dp.Reset();
    int victim = GetClientOfUserId(dp.ReadCell());
    int team = dp.ReadCell();
    if(victim > 0 && IsClientInGame(victim))
    {
        CS_SwitchTeam(victim, team);
        CS_RespawnPlayer(victim);
        // Respawn at the position where the player died.
        if(sm_kst_respawn_spot.BoolValue && bShouldRespawnAtDeathPosition[victim]) 
        {
            RequestFrame(Frame_TeleportPlayer, GetClientUserId(victim));
        }
        if(sm_kst_message.BoolValue)
        {
            PrintToChat(victim, "You have been moved to team of your killer");
        }
    }
}

int GetOppositeTeam(int client)
{
    int team = GetClientTeam(client);
    if(team == CS_TEAM_CT)
        return CS_TEAM_T;
    if(team == CS_TEAM_T)
        return CS_TEAM_CT;
    return GetRandomInt(CS_TEAM_T, CS_TEAM_CT);
}

bool EntityPlacementTest(int entity, float vecOrigin[3], float vecPosOut[3], bool bDropToGround)
{
    if(!bIsWindowsOS)
    {
        static Handle hSDKCall = null;
        if(hSDKCall == null)
        {
            StartPrepSDKCall(SDKCall_Static);
            PrepSDKCall_SetFromConf(g_pGameConfig, SDKConf_Signature, "EntityPlacementTest");
            PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer); // pMainEnt
            PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_Plain); // vecOrigin
            PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_Pointer, 0, VENCODE_FLAG_COPYBACK); // vecPosOut
            PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain); // bDropToGround
            PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain); // success or fail

            hSDKCall = EndPrepSDKCall();
            if(hSDKCall == null)
            {
                SetFailState("Failed to setup SDKCall for EntityPlacementTest");
                return false;
            }
            else
            {
                return SDKCall(hSDKCall, entity, vecOrigin, vecPosOut, bDropToGround);
            }
        }
        else
        {
            return SDKCall(hSDKCall, entity, vecOrigin, vecPosOut, bDropToGround);
        }
    }
    return false;
}

public void Frame_TeleportPlayer(any userid)
{
    int client = GetClientOfUserId(userid);
    if(!client || !IsClientInGame(client))
        return;
    
    if(EntityPlacementTest(client, vecDeathOrigin[client], vecDeathOrigin[client], true))
    {
        TeleportEntity(client, vecDeathOrigin[client], NULL_VECTOR, NULL_VECTOR);
        return;
    }
    else
    {
        TeleportEntity(client, vecDeathOrigin[client], NULL_VECTOR, NULL_VECTOR);
    }
}


public MRESReturn Detour_OnPlayerJoinTeam(int pThis, DHookReturn hReturn, DHookParam hParam)
{
    if(IsClientInGame(pThis))
    {
        playerSelectedTeam[pThis] = hParam.Get(1);
    }
    return MRES_Ignored;
}

public void Event_RoundEnd(Event event, const char[] szName, bool dontBroadcast)
{
    bShouldSwitchTeam = false;
    for(int i = 1; i<= MaxClients; i++)
    {
        if(!IsClientInGame(i)) continue;
        if(GetClientTeam(i) != playerSelectedTeam[i])
        {
            CS_SwitchTeam(i, playerSelectedTeam[i]);
            CS_UpdateClientModel(i);
        }
    }
}
