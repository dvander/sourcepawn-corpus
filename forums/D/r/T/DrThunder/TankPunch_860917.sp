#include <sourcemod>
#include <sdktools>

public OnPluginStart()
{
	HookEvent("player_incapacitated", PlayerIncap);
}
	
IncapTimer(client)
{	
	CreateTimer(0.4, IncapTimer_Function, client, TIMER_REPEAT)	
}

public Action:IncapTimer_Function(Handle:timer, any:client)
{
	SetEntProp(client, Prop_Send, "m_isIncapacitated", 1);
	SetEntityHealth(client, 300);
	return Plugin_Stop	
}

public Action:PlayerIncap(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new PlayerID = GetClientOfUserId(GetEventInt(event, "userid"));	
	new String:Weapon[256];	 
	GetEventString(event, "weapon", Weapon, 256);
	if ( StrEqual(Weapon, "tank_claw"))
	{
		SetEntProp(PlayerID, Prop_Send, "m_isIncapacitated", 0);
		SetEntityHealth(PlayerID, 1);
		IncapTimer(PlayerID);
	}

}
