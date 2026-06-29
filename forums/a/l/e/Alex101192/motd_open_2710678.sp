public OnClientPutInServer(client) 
{
    CreateTimer(5.0, Timer_AutoShow, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_AutoShow(Handle:timer, any:userid)
{
    new client = GetClientOfUserId(userid);
    if(client > 0 && IsClientInGame(client) && !IsFakeClient(client))
    {
        FakeClientCommandEx(client, "motd");
    }
    return Plugin_Handled;
}