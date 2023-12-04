#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

public Plugin myinfo = {
	name = "Simple Speed Meter",
	author = "SHUFEN from POSSESSION.tokyo",
	description = "",
	version = "1.0",
	url = "https://possession.tokyo"
};

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3],
								int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2]) {
	if (!IsClientInGame(client)) return;
	float vVel[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVel);
	float fVelocity = SquareRoot(Pow(vVel[0], 2.0) + Pow(vVel[1], 2.0));
	SetHudTextParamsEx(0.65, 0.95, 0.1, {255, 255, 255, 255}, {0, 0, 0, 255}, 0, 0.0, 0.0, 0.0);
	ShowHudText(client, 3, "%.2f", fVelocity);
}