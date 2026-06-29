#include <sourcemod>
#include <sdktools>

bool bCanUseMedic[MAXPLAYERS+1];

ConVar sm_medic_round_limit;
ConVar sm_medic_bonus_hp;

public Plugin myinfo =
{
	name = "!medic or !medkit gives 50 hp",
	author = "XeroX",
	description = "Gives players with the S flag the ability to use !medkit or !medic to gain 50 hp",
	version = "1.0.0",
	url = "https://forums.alliedmods.net/showthread.php?t=337145"
}

public void OnPluginStart()
{
    RegAdminCmd("sm_medic", Command_Medic, ADMFLAG_CUSTOM5, "Gives you 50 hp");
    RegAdminCmd("sm_medkit", Command_Medic, ADMFLAG_CUSTOM5, "Gives you 50 hp");

    HookEvent("round_start", Event_RoundStart);

    sm_medic_round_limit = CreateConVar("sm_medic_round_limit", "1", "Should the command only be used once per round", FCVAR_NONE, true, 0.0, true, 1.0);
    sm_medic_bonus_hp = CreateConVar("sm_medic_bonus_hp", "50", "How much HP should be gained from using !medic or !medkit", FCVAR_NONE, true, 0.0, true, 100.0);
    
}

public Action Command_Medic(int client, int args)
{
    if(sm_medic_round_limit.BoolValue && !bCanUseMedic[client])
    {
        ReplyToCommand(client, "[SM]: You can only use this once per round!");
        return Plugin_Handled;
    }
    if(!IsPlayerAlive(client))
    {
        ReplyToCommand(client, "[SM]: You are already dead!");
        return Plugin_Handled
    }

    bCanUseMedic[client] = false;

    int hp = GetClientHealth(client);
    if((hp + sm_medic_bonus_hp.IntValue) >= 100)
    {
        SetEntityHealth(client, 100);
    }
    else
    {
        SetEntityHealth(client, hp + sm_medic_bonus_hp.IntValue);
    }
    PrintToChat(client, "[SM]: You gained %d HP!", sm_medic_bonus_hp.IntValue);
    
    return Plugin_Handled;
}

public void OnClientPutInServer(int client)
{
    bCanUseMedic[client] = true;
}

public void Event_RoundStart(Event event, const char[] szName, bool dontBroadcast)
{
    if(sm_medic_round_limit.BoolValue == false)
        return;
    for(int i = 1; i<= MaxClients; i++)
    {
        if(!IsClientInGame(i)) continue;
        bCanUseMedic[i] = true;
    }
}