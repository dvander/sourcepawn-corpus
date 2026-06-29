#include <sourcemod>
#include <sdktools>

#pragma newdecls required
#pragma semicolon 1

/* CVars */

ConVar gCV_PluginEnable = null;
ConVar gCV_BonusVelocity = null;
ConVar gCV_MaxJumpVelocity = null;
ConVar gCV_MaxVelocity = null;
ConVar gCV_MinVelocity = null;
ConVar gCV_Velocity_Multiplier = null;

/* Cached CVars */

bool gB_PluginEnable = true;
float gF_BonusVelocity = 0.0;
float gF_MaxJumpVelocity = 0.0;
float gF_MaxVelocity = 0.0;
float gF_MinVelocity = 0.0;
float gF_Velocity_Multiplier = 1.0;

public Plugin myinfo = 
{
	name = "Velocities",
	author = "Nickelony", // Special thanks to Zipcore for fixing some stuff. :)
	description = "Adds custom velocity settings such as 'sm_bonusvelocity', 'sm_velocity_multiplier' and more.",
	version = "2.2",
	url = "http://steamcommunity.com/id/nickelony/"
};

public void OnPluginStart()
{
	HookEvent("player_jump", PlayerJumpEvent);
	
	gCV_PluginEnable = CreateConVar("velocities_enable", "1", "Enable or Disable all features of the plugin.", 0, true, 0.0, true, 1.0);
	gCV_BonusVelocity = CreateConVar("sm_bonusvelocity", "0.0", "Adds a fixed amount of bonus velocity every time you jump.", FCVAR_NOTIFY);
	gCV_MaxJumpVelocity = CreateConVar("sm_maxjumpvelocity", "0.0", "Maximum amount of velocity to keep per jump.", FCVAR_NOTIFY, true, 0.0);
	gCV_MaxVelocity = CreateConVar("sm_maxvelocity", "0.0", "Replacement for sv_maxvelocity, but this one can be client-sided.", FCVAR_NOTIFY, true, 0.0);
	gCV_MinVelocity = CreateConVar("sm_minvelocity", "0.0", "Minimum amount of velocity to keep per jump.", FCVAR_NOTIFY, true, 0.0);
	gCV_Velocity_Multiplier = CreateConVar("sm_velocity_multiplier", "1.0", "Multiplies your current velocity every time you jump.", FCVAR_NOTIFY);
	
	gCV_PluginEnable.AddChangeHook(OnConVarChanged);
	gCV_BonusVelocity.AddChangeHook(OnConVarChanged);
	gCV_MaxJumpVelocity.AddChangeHook(OnConVarChanged);
	gCV_MaxVelocity.AddChangeHook(OnConVarChanged);
	gCV_MinVelocity.AddChangeHook(OnConVarChanged);
	gCV_Velocity_Multiplier.AddChangeHook(OnConVarChanged);
	
	AutoExecConfig();
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	gB_PluginEnable = gCV_PluginEnable.BoolValue;
	gF_BonusVelocity = gCV_BonusVelocity.FloatValue;
	gF_MaxJumpVelocity = gCV_MaxJumpVelocity.FloatValue;
	gF_MaxVelocity = gCV_MaxVelocity.FloatValue;
	gF_MinVelocity = gCV_MinVelocity.FloatValue;
	gF_Velocity_Multiplier = gCV_Velocity_Multiplier.FloatValue;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if(!gB_PluginEnable)
	{
		return Plugin_Continue;
	}
	
	/* "sm_maxvelocity" */
	
	if(gF_MaxVelocity > 0.0)
	{
		float fAbsVelocity[3];
		GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", fAbsVelocity);
		
		float fCurrentSpeed = SquareRoot(Pow(fAbsVelocity[0], 2.0) + Pow(fAbsVelocity[1], 2.0));
		
		if(fCurrentSpeed > 0.0)
		{
			float fMax = gF_MaxVelocity;
			
			if(fCurrentSpeed > fMax)
			{
				float x = fCurrentSpeed / fMax;
				fAbsVelocity[0] /= x;
				fAbsVelocity[1] /= x;
				
				TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fAbsVelocity);
			}
		}
	}
	
	return Plugin_Continue;
}

public void PlayerJumpEvent(Event event, const char[] name, bool dontBroadcast)
{
	if(!gB_PluginEnable)
	{
		return;
	}
	
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if(gF_BonusVelocity != 0.0)
	{
		RequestFrame(BonusVelocity, GetClientUserId(client));
	}
	
	if(gF_MaxJumpVelocity > 0.0)
	{
		RequestFrame(MaxJumpVelocity, GetClientUserId(client));
	}
	
	if(gF_MinVelocity > 0.0)
	{
		RequestFrame(MinVelocity, GetClientUserId(client));
	}
	
	if(gF_Velocity_Multiplier != 1.0)
	{
		RequestFrame(Velocity_Multiplier, GetClientUserId(client));
	}
}

void BonusVelocity(any data)
{
	int client = GetClientOfUserId(data);
	
	if(data != 0)
	{
		float fAbsVelocity[3];
		GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", fAbsVelocity);
		
		float fCurrentSpeed = SquareRoot(Pow(fAbsVelocity[0], 2.0) + Pow(fAbsVelocity[1], 2.0));
		
		if(fCurrentSpeed > 0.0)
		{
			float fBonus = gF_BonusVelocity;
			
			float x = fCurrentSpeed / (fCurrentSpeed + fBonus);
			fAbsVelocity[0] /= x;
			fAbsVelocity[1] /= x;
			
			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fAbsVelocity);
		}
	}
}

void MaxJumpVelocity(any data)
{
	int client = GetClientOfUserId(data);
	
	if(data != 0)
	{
		float fAbsVelocity[3];
		GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", fAbsVelocity);
		
		float fCurrentSpeed = SquareRoot(Pow(fAbsVelocity[0], 2.0) + Pow(fAbsVelocity[1], 2.0));
		
		if(fCurrentSpeed > 0.0)
		{
			float fMax = gF_MaxJumpVelocity;
			
			if(fCurrentSpeed > fMax)
			{
				float x = fCurrentSpeed / fMax;
				fAbsVelocity[0] /= x;
				fAbsVelocity[1] /= x;
				
				TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fAbsVelocity);
			}
		}
	}
}

void MinVelocity(any data)
{
	int client = GetClientOfUserId(data);
	
	if(data != 0)
	{
		float fAbsVelocity[3];
		GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", fAbsVelocity);
		
		float fCurrentSpeed = SquareRoot(Pow(fAbsVelocity[0], 2.0) + Pow(fAbsVelocity[1], 2.0));
		
		if(fCurrentSpeed > 0.0)
		{
			float fMin = gF_MinVelocity;
			
			if(fCurrentSpeed < fMin)
			{
				float x = fCurrentSpeed / fMin;
				fAbsVelocity[0] /= x;
				fAbsVelocity[1] /= x;
				
				TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fAbsVelocity);
			}
		}
	}
}

void Velocity_Multiplier(any data)
{
	int client = GetClientOfUserId(data);
	
	if(data != 0)
	{
		float fAbsVelocity[3];
		GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", fAbsVelocity);
		
		fAbsVelocity[0] *= gF_Velocity_Multiplier;
		fAbsVelocity[1] *= gF_Velocity_Multiplier;
		
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fAbsVelocity);
	}
}
