// Plugin made for leaderboard equality and less silly bans against innocent players
public Plugin:myinfo =
{
	name = "High Score Resetter",
	author = "Mel",
	description = "A stupid plugin that prevents someone from having much higher points than everyone else.",
	version = "1.0.0",
    url = ""
}

#include <sdkhooks>
ConVar MaxFragsConVar, AlertPlayersConVar;
bool stopSpam = false;

public void OnPluginStart()
{
    MaxFragsConVar = CreateConVar("SR_MaxFrags", "10", "Max allowed frags above all players before their score is automatically reset.", FCVAR_NOTIFY | FCVAR_SERVER_CAN_EXECUTE);
    AlertPlayersConVar = CreateConVar("SR_Announce", "1", "If on 1 tells everyone on the server when a player's score reset, if off only informs the attacker.", FCVAR_SERVER_CAN_EXECUTE);
    HookEvent("player_death", SRPlyDied);
}

public Action:SRPlyDied(Event event, const char[] name, bool dontBroadcast)
{
    int attacker = GetClientOfUserId(event.GetInt("attacker", -1));
    int secHighPoints = 0;

    for (int i = 1; i <= GetMaxClients(); i++)
    {
        if (IsValidEntity(i) && IsClientConnected(i) && i != attacker)
        {
            int curPoints = GetEntProp(i, Prop_Data, "m_iFrags");
            if (curPoints > secHighPoints)
            {
                secHighPoints = curPoints;
            }
        }
    }

    int MaxAllowed = secHighPoints + GetConVarInt(MaxFragsConVar);
    int Current = GetClientFrags(attacker) + 1;

    if (Current >= MaxAllowed) // They are too good apparently :P
    {
        CreateTimer(0.3, ResetScore, attacker);
    }
}

public Action:ResetScore(Handle:timer, client)
{
    if (stopSpam == false)
    {
        stopSpam = true;
        if (IsValidEntity(client))
        {
            if (GetConVarInt(AlertPlayersConVar) >= 1)
            {
                char ClientName[32];
                GetClientName(client, ClientName, 32);    
                PrintToChatAll("%s's score was auto reset for having %i points above everyone else.", ClientName, GetConVarInt(MaxFragsConVar));
            }
            else
            {
                PrintToChat(client, "Your score was auto reset for having %i points above everyone else.", GetConVarInt(MaxFragsConVar));
            }

            SetEntProp(client, Prop_Data, "m_iFrags", 0);
            stopSpam = false;
        }
        else
        {
            stopSpam = false;
        }
    }
}