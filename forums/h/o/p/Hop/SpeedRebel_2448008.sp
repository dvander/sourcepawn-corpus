#pragma semicolon 1

#include <sourcemod>
#include <lastrequest>
#include <sdktools>

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if(IsValidClient(client) && GetClientTeam(client) == 2 && (GetEntityFlags(client) & FL_ONGROUND))
		CheckSpeed(client);
}

public void CheckSpeed(int client)
{
	float fVel[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVel);
	float fSpeed = SquareRoot(Pow(fVel[0], 2.0) + Pow(fVel[1], 2.0));

	if(fSpeed > 350.0)
	{
		if(!IsClientRebel(client))
		{
			ChangeRebelStatus(client, true);
			PrintToChatAll("[SM] \x04%N has chosen to rebel!", client);
		}
	}
}

public bool IsValidClient(int client)
{
	if(1 > client > MaxClients)
		return false;
	if(IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client))
		return true;
	return false;
}