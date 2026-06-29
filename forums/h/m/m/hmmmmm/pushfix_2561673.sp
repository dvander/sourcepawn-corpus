#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define VERSION "1.5"

public Plugin myinfo = 
{
	name = "Trigger_push Fix",
	author = "Mev, George, & Blacky | Slidy & rio Edit",
	description = "Removes lag from trigger_push",
	version = VERSION,
	url = "http://steamcommunity.com/id/mevv/ & http://steamcommunity.com/profiles/76561197975854215/ & http://steamcommunity.com/id/blaackyy/"
}

enum
{
	SF_TRIGGER_ALLOW_CLIENTS				= 0x01,		// Players can fire this trigger
	SF_TRIGGER_ALLOW_NPCS					= 0x02,		// NPCS can fire this trigger
	SF_TRIGGER_ALLOW_PUSHABLES				= 0x04,		// Pushables can fire this trigger
	SF_TRIGGER_ALLOW_PHYSICS				= 0x08,		// Physics objects can fire this trigger
	SF_TRIGGER_ONLY_PLAYER_ALLY_NPCS		= 0x10,		// *if* NPCs can fire this trigger, this flag means only player allies do so
	SF_TRIGGER_ONLY_CLIENTS_IN_VEHICLES		= 0x20,		// *if* Players can fire this trigger, this flag means only players inside vehicles can 
	SF_TRIGGER_ALLOW_ALL					= 0x40,		// Everything can fire this trigger EXCEPT DEBRIS!
	SF_TRIGGER_ONLY_CLIENTS_OUT_OF_VEHICLES	= 0x200,	// *if* Players can fire this trigger, this flag means only players outside vehicles can 
	SF_TRIG_PUSH_ONCE						= 0x80,		// trigger_push removes itself after firing once
	SF_TRIG_PUSH_AFFECT_PLAYER_ON_LADDER	= 0x100,	// if pushed object is player on a ladder, then this disengages them from the ladder (HL2only)
	SF_TRIG_TOUCH_DEBRIS 					= 0x400,	// Will touch physics debris objects
	SF_TRIGGER_ONLY_NPCS_IN_VEHICLES		= 0x800,	// *if* NPCs can fire this trigger, only NPCs in vehicles do so (respects player ally flag too)
	SF_TRIGGER_PUSH_USE_MASS				= 0x1000,	// Correctly account for an entity's mass (CTriggerPush::Touch used to assume 100Kg)
};

ConVar g_hTriggerPushFixEnable;
bool   g_bTriggerPushFixEnable;
Handle g_hPassesTriggerFilters;

public void OnPluginStart()
{
	Handle hFiltersConf = LoadGameConfigFile("pushfix.games");

	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hFiltersConf, SDKConf_Virtual, "CBaseTrigger::PassesTriggerFilters");
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hPassesTriggerFilters = EndPrepSDKCall();

	delete hFiltersConf;

	CreateConVar("triggerpushfix_version", VERSION, "Trigger push fix version", FCVAR_NOTIFY|FCVAR_REPLICATED);
	
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
	g_bTriggerPushFixEnable = view_as<bool>(StringToInt(newValue));
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
		if(!PassesTriggerFilters(entity, other))
		{
			return;
		}
		
		int spawnflags = GetEntProp(entity, Prop_Data, "m_spawnflags");
		
		// dont move player if they're on ladder
		if(GetEntityMoveType(other) == MOVETYPE_LADDER && !(spawnflags & SF_TRIG_PUSH_AFFECT_PLAYER_ON_LADDER))
		{
			return;
		}
		
		float fPushSpeed = GetEntPropFloat(entity, Prop_Data, "m_flSpeed");
		
		float m_vecPushDir[3];
		GetEntPropVector(entity, Prop_Data, "m_vecPushDir", m_vecPushDir);
		float angRotation[3];
		GetEntPropVector(entity, Prop_Data, "m_angAbsRotation", angRotation);
		
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
		
		matrix[0][1] = sp*srcy - crsy;
		matrix[1][1] = sp*srsy + crcy;
		matrix[2][1] = sr*cp;
		
		matrix[0][2] = (sp*crcy + srsy);
		matrix[1][2] = (sp*crsy - srcy);
		matrix[2][2] = cr*cp;
		
		matrix[0][3] = angRotation[0];
		matrix[1][3] = angRotation[1];
		matrix[2][3] = angRotation[2];
		
		float vecAbsDir[3];
		vecAbsDir[0] = m_vecPushDir[0]*matrix[0][0] + m_vecPushDir[1]*matrix[0][1] + m_vecPushDir[2]*matrix[0][2];
		vecAbsDir[1] = m_vecPushDir[0]*matrix[1][0] + m_vecPushDir[1]*matrix[1][1] + m_vecPushDir[2]*matrix[1][2];
		vecAbsDir[2] = m_vecPushDir[0]*matrix[2][0] + m_vecPushDir[1]*matrix[2][1] + m_vecPushDir[2]*matrix[2][2];
		
		ScaleVector(vecAbsDir, fPushSpeed);
		
		if(spawnflags & SF_TRIG_PUSH_ONCE)
		{
			float newVelocity[3];
			GetEntPropVector(other, Prop_Data, "m_vecAbsVelocity", newVelocity);
			AddVectors(newVelocity, vecAbsDir, newVelocity);
			
			TeleportEntity(other, NULL_VECTOR, NULL_VECTOR, newVelocity);
			
			if(vecAbsDir[2] > 0.0)
			{
				SetEntPropEnt(other, Prop_Data, "m_hGroundEntity", -1);
			}
			
			RemoveEdict(entity); // remove the trigger so it only applies once
			
			return;
		}
		
		if(GetEntityFlags(other) & FL_BASEVELOCITY)
		{
			float vecBaseVel[3];
			GetEntPropVector(other, Prop_Data, "m_vecBaseVelocity", vecBaseVel);
			AddVectors(vecAbsDir, vecBaseVel, vecAbsDir);
		}
		
		float newVelocity[3];
		GetEntPropVector(other, Prop_Data, "m_vecAbsVelocity", newVelocity);
		newVelocity[2] += vecAbsDir[2] * GetTickInterval() * GetEntPropFloat(other, Prop_Data, "m_flLaggedMovementValue"); // frametime = tick_interval * laggedmovementvalue
		
		TeleportEntity(other, NULL_VECTOR, NULL_VECTOR, newVelocity);
		
		// apply x, y as a base velocity so we travel at constant speed on conveyors
		vecAbsDir[2] = 0.0;
		
		SetEntPropVector(other, Prop_Data, "m_vecBaseVelocity", vecAbsDir);
		SetEntityFlags(other, GetEntityFlags(other) | FL_BASEVELOCITY);
	}
}

stock bool PassesTriggerFilters(int entity, int client)
{
	return SDKCall(g_hPassesTriggerFilters, entity, client);
}