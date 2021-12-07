public void OnPluginStart()
{
    HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Pre);
}

public Action Event_PlayerHurt(Handle event, char [] name, bool dontBroadcast)
{
    int victim = GetClientOfUserId(GetEventInt(event, "userid"));
    int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
    int dhealth = GetEventInt(event, "dmg_health");

    if (attacker != victim && victim != 0)
    {
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsValidClient(i) && CheckCommandAccess(i, "sm_map", ADMFLAG_CHANGEMAP, true))
            {
                PrintToChat(i, "%N team damaged %N for %i points!", attacker, victim, dhealth);
            }
        }
    }
    return Plugin_Handled;
}


stock bool IsValidClient(int client)
{
	if (!(0 < client <= MaxClients)) return false;
	if (!IsClientInGame(client)) return false;
	return true;
}