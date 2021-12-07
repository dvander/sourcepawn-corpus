#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define VERSION "1.2"

public Plugin myinfo = 
{
	name = "Trigger_push Fix",
	author = "Mev, George, & Blacky",
	description = "Removes lag from trigger_push",
	version = VERSION,
	url = "http://steamcommunity.com/id/mevv/ & http://steamcommunity.com/profiles/76561197975854215/ & http://steamcommunity.com/id/blaackyy/"
}

ConVar g_hTriggerPushFixEnable;
bool   g_bTriggerPushFixEnable;

public void OnPluginStart()
{
	CreateConVar("triggerpushfix_version", VERSION, "Trigger push fix version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED);
	
	g_hTriggerPushFixEnable = CreateConVar("triggerpushfix_enable", "1", "Enables trigger push fix.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	HookConVarChange(g_hTriggerPushFixEnable, OnTriggerPushFixChanged);
	
	HookEvent("round_start", Event_RoundStart);
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	int entity = -1;
	while((entity = FindEntityByClassname(entity, "trigger_push")) != -1)
	{
		SDKHook(entity, SDKHook_Touch, OnTouch);
	}
}

public void OnConfigsExecuted()
{
	g_bTriggerPushFixEnable = GetConVarBool(g_hTriggerPushFixEnable);
}

public void OnTriggerPushFixChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bTriggerPushFixEnable = bool:StringToInt(newValue);
}

public void OnMapStart()
{
	int entity = -1;
	while((entity = FindEntityByClassname(entity, "trigger_push")) != -1)
	{
		SDKHook(entity, SDKHook_Touch, OnTouch);
	}
}

public Action OnTouch(int entity, int other)
{
	if(0 < other <= MaxClients && g_bTriggerPushFixEnable == true)
	{
		DoPush(entity, other);
		
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public void SinCos( float radians, float &sine, float &cosine)
{
	sine = Sine(radians);
	cosine = Cosine(radians);
}


void DoPush(int entity, int other)
{
	if(0 < other <= MaxClients)
	{
		if(!DoesClientPassFilter(entity, other))
		{
			return;
		}
		
		float m_vecPushDir[3], newVelocity[3], angRotation[3], fPushSpeed;
		
		fPushSpeed = GetEntPropFloat(entity, Prop_Data, "m_flSpeed");
		GetEntPropVector(entity, Prop_Data, "m_vecPushDir", m_vecPushDir);
		GetEntPropVector(entity, Prop_Data, "m_angRotation", angRotation);
		
		// Rotate vector according to world
		float sr, sp, sy, cr, cp, cy;
		float matrix[3][4]
		
		SinCos(DegToRad(angRotation[1]), sy, cy );
		SinCos(DegToRad(angRotation[0]), sp, cp );
		SinCos(DegToRad(angRotation[2]), sr, cr );
		
		matrix[0][0] = cp*cy;
		matrix[1][0] = cp*sy;
		matrix[2][0] = -sp;
		
		float crcy = cr*cy;
		float crsy = cr*sy;
		float srcy = sr*cy;
		float srsy = sr*sy;
		
		matrix[0][1] = sp*srcy-crsy;
		matrix[1][1] = sp*srsy+crcy;
		matrix[2][1] = sr*cp;
		
		matrix[0][2] = (sp*crcy+srsy);
		matrix[1][2] = (sp*crsy-srcy);
		matrix[2][2] = cr*cp;
		
		matrix[0][3] = angRotation[0];
		matrix[1][3] = angRotation[1];
		matrix[2][3] = angRotation[2];
		
		float vecAbsDir[3];
		vecAbsDir[0] = m_vecPushDir[0]*matrix[0][0] + m_vecPushDir[1]*matrix[0][1] + m_vecPushDir[2]*matrix[0][2];
		vecAbsDir[1] = m_vecPushDir[0]*matrix[1][0] + m_vecPushDir[1]*matrix[1][1] + m_vecPushDir[2]*matrix[1][2];
		vecAbsDir[2] = m_vecPushDir[0]*matrix[2][0] + m_vecPushDir[1]*matrix[2][1] + m_vecPushDir[2]*matrix[2][2];
		
		ScaleVector(vecAbsDir, fPushSpeed);
		
		// Apply the base velocity directly to abs velocity
		GetEntPropVector(other, Prop_Data, "m_vecVelocity", newVelocity);
		
		newVelocity[2] = newVelocity[2] + (vecAbsDir[2] * GetTickInterval());
		TeleportEntity(other, NULL_VECTOR, NULL_VECTOR, newVelocity);
		
		// Remove the base velocity z height so abs velocity can do it and add old base velocity if there is any
		vecAbsDir[2] = 0.0;
		if(GetEntityFlags(other) & FL_BASEVELOCITY)
		{
			float vecBaseVel[3];
			GetEntPropVector(other, Prop_Data, "m_vecBaseVelocity", vecBaseVel);
			AddVectors(vecAbsDir, vecBaseVel, vecAbsDir);
		}
		
		SetEntPropVector(other, Prop_Data, "m_vecBaseVelocity", vecAbsDir);
		SetEntityFlags(other, GetEntityFlags(other) | FL_BASEVELOCITY);
	}
}

void GetFilterTargetName(char[] filtername, char[] buffer, int maxlen)
{
	int filter = FindEntityByTargetname(filtername);
	if(filter != -1)
	{
		GetEntPropString(filter, Prop_Data, "m_iFilterName", buffer, maxlen);
	}
}

int FindEntityByTargetname(char[] targetname)
{
	int entity = -1;
	char sName[64];
	while ((entity = FindEntityByClassname(entity, "filter_activator_name")) != -1)
	{
		GetEntPropString(entity, Prop_Data, "m_iName", sName, 64);
		if (StrEqual(sName, targetname))
		{
			return entity;
		}
	}
	
	return -1;
}

bool DoesClientPassFilter(int entity, int client)
{
	char sPushFilter[64];
	GetEntPropString(entity, Prop_Data, "m_iFilterName", sPushFilter, sizeof sPushFilter);
	if(StrEqual(sPushFilter, ""))
	{
		return true;
	}
	char sFilterName[64];
	GetFilterTargetName(sPushFilter, sFilterName, sizeof sFilterName);
	char sClientName[64];
	GetEntPropString(client, Prop_Data, "m_iName", sClientName, sizeof sClientName);
	
	return StrEqual(sFilterName, sClientName, true);
}