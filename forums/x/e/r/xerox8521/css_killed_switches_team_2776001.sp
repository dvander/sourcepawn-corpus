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

bool bShouldSwitchTeam;

DynamicDetour ddOnPlayerJoinTeam;

GameData g_pGameConfig;

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

    HookEvent("player_death", Event_PlayerDeath);
    HookEvent("round_end", Event_RoundEnd);
    HookEvent("round_freeze_end", Event_FreezeEnd);

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
    
    GetClientAbsOrigin(victim, vecDeathOrigin[victim]);

    DataPack dp;
    CreateDataTimer(sm_kst_respawndelay.FloatValue, t_RespawnPlayer, dp, TIMER_FLAG_NO_MAPCHANGE);
    
    dp.WriteCell(userid);
    dp.WriteCell(event.GetInt("attacker"));
}

public Action t_RespawnPlayer(Handle timer, any datapack)
{
    if(!bShouldSwitchTeam)
        return;
    
    DataPack dp = view_as<DataPack>(datapack);
    dp.Reset();
    int victim = GetClientOfUserId(dp.ReadCell());
    int attacker = GetClientOfUserId(dp.ReadCell());
    if(attacker > 0 && attacker < MaxClients && IsClientInGame(attacker))
    {
        if(victim > 0 && victim < MaxClients && IsClientInGame(victim))
        {
            CS_SwitchTeam(victim, GetClientTeam(attacker));
            CS_RespawnPlayer(victim);
            // Respawn at the position where the player died.
            if(sm_kst_respawn_spot.BoolValue) 
            {
                RequestFrame(Frame_TeleportPlayer, GetClientUserId(victim));
            }
            if(sm_kst_message.BoolValue)
            {
                PrintToChat(victim, "You have been moved to team of your killer");
            }
        }
    }
}

public void Frame_TeleportPlayer(any userid)
{
    int client = GetClientOfUserId(userid);
    if(!client || !IsClientInGame(client))
        return;
    
    TeleportEntity(client, vecDeathOrigin[client], NULL_VECTOR, NULL_VECTOR);
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
        }
    }
}