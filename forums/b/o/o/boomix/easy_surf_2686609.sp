#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "boomix"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
//#include <sdkhooks>

#pragma newdecls required

int iUsed[MAXPLAYERS + 1][3];

public Plugin myinfo = 
{
	name = "Easy surf",
	author = PLUGIN_AUTHOR,
	description = "Makes surfing easier",
	version = PLUGIN_VERSION,
	url = "https://identy.lv"
};


public Action OnPlayerRunCmd(int client, int &iButtons, int &iImpulse, float fVelocity2[3], float fAngles[3], int &iWeapon) 
{
	if (iButtons & IN_ATTACK || iButtons & IN_ATTACK2) {
		
		float fVelocity[3];
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVelocity);
		float speed = SquareRoot(Pow(fVelocity[0], 2.0) + Pow(fVelocity[1], 2.0));
		
		//Check default speed
		if (speed < 250.0)
			return Plugin_Continue;
		
		//Get eye direction speed
		float playerangle[3], vecfwr[3], newvel[3];	
		GetClientEyeAngles(client, playerangle);
		GetAngleVectors(playerangle, vecfwr, NULL_VECTOR, NULL_VECTOR);		
		NormalizeVector(vecfwr, newvel);
		
		//Fix few bugs
		bool x = (fVelocity[0] * newvel[0]) < 0.0 ? false : true;
		bool y = (fVelocity[1] * newvel[1]) < 0.0 ? false : true;
		float scale = (iButtons & IN_ATTACK || !(x && y)) ? 10.0 : -30.0;
		ScaleVector(newvel, scale);
		newvel[2] = 0.0;
		
		//Put vectors together
		AddVectors(fVelocity, newvel, newvel);
		
		//Teleport client
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, newvel);
		
		//Count
		if (iButtons & IN_ATTACK)
			iUsed[client][0]++;
		else if (iButtons & IN_ATTACK2)
			iUsed[client][1]++;
		
	}
	
	return Plugin_Continue;
}