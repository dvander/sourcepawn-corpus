#include <sourcemod>
#include <sdktools>
#include <cstrike>

ConVar mp_autoteambalance;
ConVar sm_kst_respawndelay;
ConVar sm_kst_message;

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
    
    HookEvent("player_death", Event_PlayerDeath);

    mp_autoteambalance = FindConVar("mp_autoteambalance");

    mp_autoteambalance.SetBool(false, false, true);

    mp_autoteambalance.AddChangeHook(OnAutoBalancedChanged);

    sm_kst_respawndelay = CreateConVar("sm_kst_respawndelay", "5", "How much time (in seconds) should pass before the killed player is switched over to the attackers team and respawned");
    sm_kst_message = CreateConVar("sm_kst_message", "1", "Toggle whether the killed player gets a chat notification that they have been switched to the killers team");
}

public void OnAutoBalancedChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if(StringToInt(newValue) != 0)
    {
        mp_autoteambalance.SetBool(false, false, true);
    }
}

public void Event_PlayerDeath(Event event, const char[] szName, bool dontBroadcast)
{
    DataPack dp;
    CreateDataTimer(sm_kst_respawndelay.FloatValue, t_RespawnPlayer, dp, TIMER_FLAG_NO_MAPCHANGE);
    dp.WriteCell(event.GetInt("userid"));
    dp.WriteCell(event.GetInt("attacker"));
}

public Action t_RespawnPlayer(Handle timer, any datapack)
{
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
            if(sm_kst_message.BoolValue)
            {
                PrintToChat(victim, "You have been moved to team of your killer");
            }
        }
    }
}