#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

public Plugin myinfo = 
{
	name = "Max Jump Speed",
	author = "m_bNightstalker",
	description = "Limits horizontal player speed when bhopping",
	version = "1.0",
	url = ""
};

public void OnPluginStart()
{
	HookEvent("player_jump", Event_PlayerJump);
}

public Action Event_PlayerJump(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	CreateTimer(0.0, CheckMaxSpeed, client);
}

public Action CheckMaxSpeed(Handle timer, any client)
{
	float fVelocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVelocity);
	float currentspeed = SquareRoot(Pow(fVelocity[0],2.0)+Pow(fVelocity[1],2.0));
	
	float maxspeed = 360.0;
	
	if (currentspeed > maxspeed)
	{
		float Multpl = currentspeed / maxspeed;
	
		if(Multpl != 0.0)
		{
			fVelocity[0] /= Multpl;
			fVelocity[1] /= Multpl;
			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fVelocity);
		}
	}
}