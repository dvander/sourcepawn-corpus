#include <sourcemod>
#include <tf2>
#include <tf2_stocks>

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon) 
{
	if(IsClientInGame(client) && IsPlayerAlive(client) && TF2_GetPlayerClass(client) == TFClass_Heavy && buttons & IN_ATTACK2)
	{
		if(buttons & IN_DUCK)
		{
			TF2_RemoveCondition(client, TFCond_Slowed);
			SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 140.0);
		}
		if(!(buttons & IN_DUCK))
		{
			TF2_AddCondition(client, TFCond_Slowed, 1.0);
			SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 80.0);
		}
	}
	return Plugin_Continue;
}