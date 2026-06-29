#include <sdkhooks>
#include <sdktools>

Handle g_hDestinationLookup = null;
float g_vecPlayerRotations[MAXPLAYERS+1][3];

public Plugin myinfo =
{
	name = "Force Landmark Angles",
	author = "Neuro Toxin",
	description = "Forces trigger teleports to use Landmark Angles",
	version = "1.1.0",
}

public void OnMapStart()
{
	if (g_hDestinationLookup == null)
		g_hDestinationLookup = CreateTrie();
	else
		ClearTrie(g_hDestinationLookup);
		
	// Late load
	if (MaxClients > 0)
	{
		int entity = -1;
		while ((entity = FindEntityByClassname(entity, "trigger_teleport")) > -1)
		{
			OnEntitySpawned(entity);
		}
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (!StrEqual(classname, "trigger_teleport"))
		return;

	SDKHook(entity, SDKHook_Spawn, OnEntitySpawned);
}

public void OnEntitySpawned(int entity)
{
	SDKUnhook(entity, SDKHook_Spawn, OnEntitySpawned);
	
	SetEntProp(entity, Prop_Data, "m_bUseLandmarkAngles", 0);
	if (SetTeleportTarget(entity))
	{
		HookSingleEntityOutput(entity, "OnStartTouch", OnEntityStartTouch);
		HookSingleEntityOutput(entity, "OnEndTouch", OnEntityEndTouch);
	}
}

public OnEntityStartTouch(const char[] output, int caller, int activator, float delay)
{
	int target = GetTeleportTarget(caller);
	if (target == -1)
		return;
		
	float m_vecOrigin[3]; float m_angRotation_player[3]; float m_angRotation[3]; float m_vecAbsVelocity[3];
	GetEntPropVector(target, Prop_Send, "m_vecOrigin", m_vecOrigin);
	GetEntPropVector(activator, Prop_Data, "m_angRotation", m_angRotation_player);
	GetEntPropVector(target, Prop_Data, "m_angRotation", m_angRotation);
	GetEntPropVector(activator, Prop_Data, "m_vecAbsVelocity", m_vecAbsVelocity);
	
	m_vecAbsVelocity[2] = 0.0; // remove fall speed
	
	float speed = GetVectorLength(m_vecAbsVelocity);
	float fwvec[3];
	GetAngleVectors(m_angRotation, fwvec, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(fwvec, fwvec);
	ScaleVector(fwvec, speed);
	
	g_vecPlayerRotations[activator][0] = m_angRotation_player[0];
	g_vecPlayerRotations[activator][1] = m_angRotation[1];
	g_vecPlayerRotations[activator][2] = m_angRotation[2];
	
	//fwvec[2] = 0.0; // remove fall speed
	TeleportEntity(activator, m_vecOrigin, g_vecPlayerRotations[activator], fwvec);
}

public OnEntityEndTouch(const char[] output, int caller, int activator, float delay)
{
	TeleportEntity(activator, NULL_VECTOR, g_vecPlayerRotations[activator], NULL_VECTOR);
}

stock bool SetTeleportTarget(int trigger_teleport)
{
	char m_target[128];
	GetEntPropString(trigger_teleport, Prop_Data, "m_target", m_target, sizeof(m_target))
	
	int target = FindTeleportTarget(m_target);
	if (target == -1)
		return false;
	
	SetTrieValue(g_hDestinationLookup, m_target, target);
	return true;
}

stock int FindTeleportTarget(const char[] targetname)
{
	char buffer[128];
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, "info_teleport_destination")) > -1)
	{
		GetEntPropString(entity, Prop_Data, "m_iName", buffer, sizeof(buffer));
		if (StrEqual(targetname, buffer))
			return entity;	
	}
	
	return -1;
}

stock int GetTeleportTarget(int trigger_teleport)
{
	char m_target[128];
	GetEntPropString(trigger_teleport, Prop_Data, "m_target", m_target, sizeof(m_target))
	
	int target;
	if (GetTrieValue(g_hDestinationLookup, m_target, target))
		return target;
		
	return -1;	
}