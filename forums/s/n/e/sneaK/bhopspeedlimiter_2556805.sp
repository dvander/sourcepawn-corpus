#include <sourcemod>
#include <sdktools>

public Plugin myinfo = 
{
	name = " Bhop Speed Limiter ",
	author = "1NutWunDeR & maoling ( xQy )",
	description = "",
	version = "1.0",
	url = "http://steamcommunity.com/id/_xQy_/"
};

bool g_bIsClientOnGround[MAXPLAYERS+1];

float g_fBhopSpeed;

Handle g_cvarSpeed;

public void OnPluginStart()
{
	g_cvarSpeed = CreateConVar("sv_maxbhopspeed", "400.0", "Max speed.");
	
	HookConVarChange(g_cvarSpeed, OnSettingChanged);
	
	AutoExecConfig(true);
}

public void OnConfigsExecuted()
{
	g_fBhopSpeed = GetConVarFloat(g_cvarSpeed);
}

public void OnSettingChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	g_fBhopSpeed = GetConVarFloat(g_cvarSpeed);
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

	if(g_bIsClientOnGround[client])
	{
		if(!m_bIsOnGround[client])
		{
			m_bIsOnGround[client] = true;    
			if(GetVectorLength(m_fCurrentVec) > g_fBhopSpeed)
			{
				m_bIsOnGround[client] = true;
				NormalizeVector(m_fCurrentVec, m_fCurrentVec);
				ScaleVector(m_fCurrentVec, g_fBhopSpeed);
				TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, m_fCurrentVec);
			}
		}
	}
	else
		m_bIsOnGround[client] = false;
}