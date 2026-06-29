
new bool:hasBoosted[MAXPLAYERS+1];
new Handle:cBoostTime;
new Handle:cBoostSpeed;
public OnPluginStart()
{
	RegConsoleCmd("sm_boost", Boost);
	cBoostTime = CreateConVar("sm_boost_time", "5.0", "Boost time", FCVAR_PLUGIN|FCVAR_NOTIFY);
	cBoostSpeed = CreateConVar("sm_boost_speed", "1.5", "Boost Speed", FCVAR_PLUGIN|FCVAR_NOTIFY);
	AutoExecConfig();
	HookEvent("player_spawn", Event_Spawn);

}
public Action:Boost( client, args ) {
	if(!client) {
		ReplyToCommand(client, "[Boost] You must be in-game to use this command");
		return Plugin_Handled;
	}
	if(hasBoosted[client]) {
		ReplyToCommand(client, "[Boost] You have already used this once this round!");
		return Plugin_Handled;
	}
	if(!IsPlayerAlive(client) || GetClientTeam(client) == 2) {
		ReplyToCommand(client, "[Boost] Only humans can use this command.");
		return Plugin_Handled;
	}
	new Float:fTime = GetConVarFloat(cBoostTime);
	new Float:fSpeed = GetConVarFloat(cBoostSpeed);
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", fSpeed);
	hasBoosted[client] = true;
	CreateTimer(fTime, Timer_RemoveSpeed, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Handled;
}

public Event_Spawn(Handle:hEvent, const String:sName[], bool:bNoBroadcast) {
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if (IsClientInGame(client) && IsPlayerAlive(client)) {
		hasBoosted[client] = false;
	}
}

public Action:Timer_RemoveSpeed(Handle:timer, any:userid) {
	new client = GetClientOfUserId(userid);
	if(!client || !IsClientInGame(client)) {
		return Plugin_Stop;
	}
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
	return Plugin_Stop;
}