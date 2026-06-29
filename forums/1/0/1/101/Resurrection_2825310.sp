ConVar cvar;

public void OnPluginStart()
{
    cvar = CreateConVar("sm_nodmg_time", "10.0", "The time after spawn during which the player is invulnerable [0.0 = Disable]", _, true, _, true, 10.0);
    HookEvent("player_spawn", Event_Spawn);
    
    //AutoExecConfig(true, "Resurrection");
    HookConVarChange(cvar, X_ConVarChanged);

}

public X_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    float oldv = StringToFloat(oldValue);
    float newv = StringToFloat(newValue);
    if (newv > 0 >= oldv)    HookEvent("player_spawn", Event_Spawn);
    if (newv <= 0 < oldv)    UnhookEvent("player_spawn", Event_Spawn);
}

public void Event_Spawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(!client)	return;
	
	SetUp(client,0,100);
	CreateTimer(cvar.FloatValue , Timer_EnableDmg , client);
}

public Action Timer_EnableDmg(Handle timer, int client)
{
	if (IsClientInGame(client))	SetUp(client,2,255);
	return Plugin_Handled;
}

SetUp(int client ,int DmgType ,int Alpha)
{
    SetEntProp(client, Prop_Data, "m_takedamage", DmgType, 1);
    SetEntityRenderColor(client, 255, 255, 255, Alpha);
} 