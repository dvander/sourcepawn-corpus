#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = 
{
	name		= "[TF2] Fix cl_interp exploit",
	author		= "01Pollux",
	url			= "no"
};

public void ValidateLagCompensation(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue, any value)
{
	float ActualLerp = GetEntPropFloat(client, Prop_Data, "m_fLerpTime");
	
	if(StringToFloat(cvarValue) != ActualLerp) {
		SetEntPropFloat(client, Prop_Data, "m_fLerpTime", StringToFloat(cvarValue));
	}
}

Action LoopClients(Handle timer)
{
	static int i;
	for(i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i)) {
			QueryClientConVar(i, "cl_interp", ValidateLagCompensation);
		}
	}
}

public void OnPluginStart()
{
	CreateTimer(2.0, LoopClients, .flags = TIMER_REPEAT);
}