public Plugin:myinfo = 
{
	name = "Hide Hude",
	author = "Mitchell",
	description = "Hide specefic bit flags",
	version	 = "1.0.0",
	url = "snbx.info"
}

new Handle:cHideElements = INVALID_HANDLE;

public OnPluginStart() {
	cHideElements = CreateConVar("sm_hidehud_elements", "4096", "Bitflags to decimal.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	AutoExecConfig();
	HookEvent("player_spawn", Player_Spawn);
}

public Player_Spawn(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	CreateTimer(0.0, RemoveRadar, client);
}

public Action:RemoveRadar(Handle:timer, any:client) {
	SetEntProp(client, Prop_Send, "m_iHideHUD", GetEntProp(client, Prop_Send, "m_iHideHUD") | GetConVarInt(cHideElements));
}