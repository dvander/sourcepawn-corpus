#include <sourcemod>
#include <zombiereloaded>
#include <cstrike>

public Plugin:myinfo =
{
	name = "[ZP] Force Humans join CT",
	author = "ZR, Zombie Paradise",
	description = "",
	version = "1.0",
	url = ""
};

public OnPluginStart()
{
	HookEvent("round_start", Event_Round_Start, EventHookMode_Pre);
	AddCommandListener(Command_JoinTeam, "jointeam");	
}

public Event_Round_Start(Event event, const String:name[], bool:dontBroadcast)
{
	swap_teams()
}

public Action:Command_JoinTeam(client, const String:command[], argc) 
{
	if(!client) return Plugin_Continue;

	decl String:arg1[255];
	GetCmdArg(1, arg1, sizeof(arg1));
	
	// 스펙참여 가능하게~
	// Allow players to join into spectator~
	new desiredteam = StringToInt(arg1);
	if (desiredteam == 1)
	{
		// 1 = Spec
		ChangeClientTeam(client, 1);
	}
	else 
	{
		// CT에 묶어놈
		CS_SwitchTeam(client, CS_TEAM_CT);
		SetEntProp(client, Prop_Send, "m_iCoachingTeam", 3)
		return Plugin_Handled;
	}
	
	return Plugin_Stop;
}  

public swap_teams()
{
    new Handle:arrayEligibleClients = INVALID_HANDLE;
    new eligibleclients = ZRCreateEligibleClientList(arrayEligibleClients, true);
    
    if (!eligibleclients)
    {
        CloseHandle(arrayEligibleClients);
        return;
    }
	
    new client;
    for (new x = 0; x < eligibleclients; x++)
    {
        client = GetArrayCell(arrayEligibleClients, x);
        CS_SwitchTeam(client, CS_TEAM_CT);
		SetEntProp(client, Prop_Send, "m_iCoachingTeam", 3)
    }	
	
	CloseHandle(arrayEligibleClients);
}

stock ZRCreateEligibleClientList(&Handle:arrayEligibleClients, bool:team = false, bool:alive = false, bool:human = false)
{
    arrayEligibleClients = CreateArray();
    for (new x = 1; x <= MaxClients; x++)
    {
        if (!IsClientInGame(x))
        {
            continue;
        }
        
        if (team && !ZRIsClientOnTeam(x))
        {
            continue;
        }
        
        if (alive && !IsPlayerAlive(x))
        {
            continue;
        }
        
        if (human && !InfectIsClientHuman(x))
        {
            continue;
        }
        
        PushArrayCell(arrayEligibleClients, x);
    }
    
    return GetArraySize(arrayEligibleClients);
}

stock bool:ZRIsClientOnTeam(client, team = -1)
{
    if (!ZRIsClientValid(client))
    {
        return false;
    }
    
    new clientteam = GetClientTeam(client);
    
    if (team == -1)
    {
        return (clientteam == CS_TEAM_T || clientteam == CS_TEAM_CT);
    }
    
    return (clientteam == team);
}

bool:InfectIsClientHuman(client)
{
    if (!ZRIsClientValid(client))
    {
        return true;
    }
    
    return !ZR_IsClientZombie(client);
}

stock bool:ZRIsClientValid(client, bool:console = false)
{
    if (client > MaxClients)
    {
        return false;
    }
    
    return console ? (client >= 0) : (client > 0);
}

// From zombie_plague40.sma
// Thanks to credit MercyLezz
/*
fnGetZombies()
{
	static iZombies, id
	iZombies = 0
	
	for (id = 1; id <= MaxClients; id++)
	{
		if(!IsClientInGame(id) || !IsClientConnected(id)) continue;
		
		if (IsPlayerAlive(id) && ZR_IsClientZombie(id))
			iZombies++
	}
	
	return iZombies;	
}*/