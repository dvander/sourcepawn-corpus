public void OnPluginStart()
{
	HookEvent("bomb_beginplant", Event_Plant);
}

public void Event_Plant(Event event, char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	CreateTimer(0.1, Timer_Plant, GetClientUserId(client));
}

public Action Timer_Plant(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (!client)
		return Plugin_Handled;

	int bomb = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	char sBuffer[16];
	GetEntityClassname(bomb, sBuffer, sizeof(sBuffer));

	if (!StrEqual(sBuffer, "weapon_c4"))
		return Plugin_Handled;

	SetEntPropFloat(bomb, Prop_Send, "m_fArmedTime", GetGameTime());

	return Plugin_Handled;
}

