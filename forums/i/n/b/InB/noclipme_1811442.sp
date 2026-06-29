public OnPluginStart()
{
    RegAdminCmd("sm_noclipme",NoclipMe,ADMFLAG_RESERVATION);
}

public Action:NoclipMe(client, args)
{
    if(client<1||!IsClientInGame(client)||!IsPlayerAlive(client))
        return;

    if (GetEntityMoveType(client) != MOVETYPE_NOCLIP)
    {
        SetEntityMoveType(client, MOVETYPE_NOCLIP);
    }
    else
    {
        SetEntityMoveType(client, MOVETYPE_WALK);
    }
}  