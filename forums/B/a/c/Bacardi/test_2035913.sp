new Handle:mp_forcecamera = INVALID_HANDLE;
public OnPluginStart()
{
	if((mp_forcecamera = FindConVar("mp_forcecamera")) == INVALID_HANDLE)
	{
		SetFailState("Convar mp_forcecamera not found");
	}
	HookEvent("player_team", event);
	HookEvent("player_death",event);
}

public Action:event(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(1.0, timer_delay, GetEventInt(event, "userid"), TIMER_FLAG_NO_MAPCHANGE);
}

public Action:timer_delay(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if(client != 0 && IsClientInGame(client) && !IsFakeClient(client) && !IsPlayerAlive(client))
	{
		SendConVarValue(client, mp_forcecamera, "2");
	}
}