#include <sourcemod>
#include <sdktools>
#include <zombiereloaded>

public Plugin myinfo = 
{
	name = " [ZE] - Bhop Speed Limiter ",
	author = "1NutWunDeR & maoling ( xQy )",
	description = "",
	version = "1.0",
	url = "http://steamcommunity.com/id/_xQy_/"
};

bool g_bIsClientOnGround[MAXPLAYERS+1];

float g_fBhopSpeedZombie;
float g_fBhopSpeedHumans;

Handle g_cvarSpeedZombie;
Handle g_cvarSpeedHumans;

public void OnPluginStart()
{
	g_cvarSpeedZombie = CreateConVar("zr_bhopspeed_zombie", "300.0", "Max speed of zombie.");
	g_cvarSpeedHumans = CreateConVar("zr_bhopspeed_humans", "300.0", "Max speed of  human.");
	
	HookConVarChange(g_cvarSpeedZombie, OnSettingChanged);
	HookConVarChange(g_cvarSpeedHumans, OnSettingChanged);
	
	AutoExecConfig(true, "BhopSpeed", "sourcemod/zombiereloaded");
}

public void OnConfigsExecuted()
{
	g_fBhopSpeedZombie = GetConVarFloat(g_cvarSpeedZombie);
	g_fBhopSpeedHumans = GetConVarFloat(g_cvarSpeedHumans);
}

public void OnSettingChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	g_fBhopSpeedZombie = GetConVarFloat(g_cvarSpeedZombie);
	g_fBhopSpeedHumans = GetConVarFloat(g_cvarSpeedHumans);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if(!IsPlayerAlive(client))
		return Plugin_Continue;	

	if(GetEntityFlags(client) & FL_ONGROUND)
		g_bIsClientOnGround[client] = true;
	else
		g_bIsClientOnGround[client] = false;


	CheckSpeed(client);

	return Plugin_Continue;
}

public void CheckSpeed(int client)
{
	static bool m_bIsOnGround[MAXPLAYERS+1]; 

	float m_fCurrentVec[3];

	if(ZR_IsClientHuman(client))
	{
		if(g_bIsClientOnGround[client])
		{
			if(!m_bIsOnGround[client])
			{
				m_bIsOnGround[client] = true;    
				if(GetVectorLength(m_fCurrentVec) > g_fBhopSpeedZombie)
				{
					m_bIsOnGround[client] = true;
					NormalizeVector(m_fCurrentVec, m_fCurrentVec);
					ScaleVector(m_fCurrentVec, g_fBhopSpeedZombie);
					TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, m_fCurrentVec);
				}
			}
		}
		else
			m_bIsOnGround[client] = false;
	}
	else if(ZR_IsClientZombie(client))
	{
		if(g_bIsClientOnGround[client])
		{
			if(!m_bIsOnGround[client])
			{
				m_bIsOnGround[client] = true;    
				if(GetVectorLength(m_fCurrentVec) > g_fBhopSpeedHumans)
				{
					m_bIsOnGround[client] = true;
					NormalizeVector(m_fCurrentVec, m_fCurrentVec);
					ScaleVector(m_fCurrentVec, g_fBhopSpeedHumans);
					TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, m_fCurrentVec);
				}
			}
		}
		else
			m_bIsOnGround[client] = false;
	}
}