ConVar gc_iTeamKillLimit;

int ga_iTeamKillCounter[MAXPLAYERS + 1] = {0, ...};

ArrayList ga_hPlayersKicked = null;

public void OnPluginStart()
{
    gc_iTeamKillLimit = CreateConVar("sm_teamkill_limit", "3", "The limit before of team kill before kicking the player", FCVAR_NONE, true, 0.0);
   
    HookEventEx("round_start", Event_RoundStart);
    HookEventEx("player_death", Event_PlayerDeath);
    HookEventEx("player_disconnect", Event_Disconnect);
	
    ga_hPlayersKicked = new ArrayList(32);
    ga_hPlayersKicked.Clear();
}

public void Event_Disconnect(Event hEvent, const char[] sName, bool bDontBroadcast)
{
    int client = GetClientOfUserId(hEvent.GetInt("userid"));
    ga_iTeamKillCounter[client] = 0;
}

public void Event_RoundStart(Event hEvent, const char[] sName, bool bDontBroadcast)
{
    for(int i = 1; i < MaxClients; i++)
    {
        ga_iTeamKillCounter[i] = 0;
    }
}

public void Event_PlayerDeath(Event hEvent, const char[] sName, bool bDontBroadcast)
{
    int victim = GetClientOfUserId(hEvent.GetInt("userid"));
    int attacker = GetClientOfUserId(hEvent.GetInt("attacker"));
    if(!attacker || attacker == victim || GetClientTeam(attacker) != GetClientTeam(victim))
    {
        return;
    }

    ga_iTeamKillCounter[attacker]++;
    PrintToChatAll("[SM] Player %N teamkilled Player %N (TK %i of %i).", attacker, victim, ga_iTeamKillCounter[attacker], gc_iTeamKillLimit.IntValue);

    if(ga_iTeamKillCounter[attacker] >= gc_iTeamKillLimit.IntValue && !IsClientInKickQueue(attacker))
    {
        char sSteamID[32];
        GetClientAuthId(attacker, AuthId_Steam2, sSteamID, sizeof(sSteamID));
        ga_hPlayersKicked.PushString(sSteamID);
        if (GetOccurenceAmmount(ga_hPlayersKicked, sSteamID) >= 3)
        {
            PrintToChatAll("[SM] Player %N was banned for teamilling.", attacker);
            BanClient(attacker, 60, BANFLAG_AUTO, "Banned for teamkilling", "Banned for teamkilling"); 
            RemoveEntriesFromArray(ga_hPlayersKicked, sSteamID); 
        }
		else
		{
		    KickClient(attacker, "You have been kicked. Too many team kills");
		}
    }
}

int GetOccurenceAmmount(ArrayList array, const char[] search)
{
    int iAmmount = 0;
    int index = array.FindString(search);

    while (index != -1)
    {
        iAmmount++;
        index = array.FindString(search);
    }

    return iAmmount;
}

void RemoveEntriesFromArray(ArrayList array, const char[] search)
{
    int index = array.FindString(search);
    while (index != -1)
    {
        array.Erase(index);
        index = array.FindString(search);
    }
}




