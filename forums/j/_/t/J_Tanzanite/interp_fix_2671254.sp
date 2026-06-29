#include <sourcemod>


public Plugin:myinfo = {
	name = "Interp Exploit Fix",
	version = "1.0.0",
	description = "Kicks players who attempt to exploit interpolation.",
	author = "J_Tanzanite",
	url = ""
}


public void OnPluginStart()
{
	CreateTimer(10.0, Timer_CheckClients, _, TIMER_REPEAT);
}

public Action Timer_CheckClients(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsClientConnected(i)
			|| !IsClientInGame(i)
			|| IsFakeClient(i))
			continue;

		float lerp = GetEntPropFloat(i, Prop_Data, "m_fLerpTime");

		if (lerp < 0.110) /*110ms max, 100ms is default lerp in TF2 (and other source games afaik). Slight buffer of 10ms is used just in case. */
			continue;

		KickClient(i, "Your interp is too high (%.3f / 0.100 Max)", lerp);
	}
}
