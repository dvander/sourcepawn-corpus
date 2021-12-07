#include <tf2_stocks>

new LastGroundEnt[MAXPLAYERS + 1];

public OnGameFrame()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i)) continue;
		if (!IsPlayerAlive(i)) continue;
		new ent = GetEntPropEnt(i, Prop_Send, "m_hGroundEntity");
		if (LastGroundEnt[i] == ent) continue;
		LastGroundEnt[i] = ent;
		if (!TF2_IsPlayerInCondition(i, TFCond_Taunting)) continue;
		if (GetEntProp(i, Prop_Send, "m_bIsReadyToHighFive")) continue;
		TF2_RemoveCondition(i, TFCond_Taunting);
	}
}