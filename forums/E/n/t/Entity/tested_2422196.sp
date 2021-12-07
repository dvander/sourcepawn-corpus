#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public OnPluginStart()
{
	HookEvent("player_spawn", player_spawn);
}

public Action:player_spawn(Handle:event, const String:name[], bool:dontBroadcast)
{	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	CreateTimer(0.01, icon, GetClientUserId(client));
}

public Action: icon(Handle:timer, any:userid)
{		
	new client = GetClientOfUserId(userid);
	
	if (client && IsPlayerAlive(client))
	{	
		
		decl Float:fPos[3];
		GetClientAbsOrigin(client, fPos); 
		decl Float:fAng[3]; 
		GetClientAbsAngles(client, fAng);

		//new g_StringTable = FindStringTable("ParticleEffectNames"); 
		//new particle = FindStringIndex(g_StringTable, "bomb_explosion_huge");
		
		new particle = GetEffectIndex("bomb_explosion_huge")
		
		DispatchParticleEffectToAll(particle, fPos, fAng, INVALID_ENT_REFERENCE, 0.0)
	}
}

stock DispatchParticleEffectToAll(p_ParticleType, const Float:p_Origin[3], const Float:p_Angle[3], p_Parent = INVALID_ENT_REFERENCE, Float:p_Delay = 0.0)
{
    TE_Start("EffectDispatch");
    
    TE_WriteNum("m_nHitBox", p_ParticleType);
    TE_WriteFloat("m_vOrigin.x", p_Origin[0]);
    TE_WriteFloat("m_vOrigin.y", p_Origin[1]);
    TE_WriteFloat("m_vOrigin.z", p_Origin[2]);
    TE_WriteFloat("m_vStart.x", p_Origin[0]);
    TE_WriteFloat("m_vStart.y", p_Origin[1]);
    TE_WriteFloat("m_vStart.z", p_Origin[2]);
    TE_WriteVector("m_vAngles", p_Angle);
    
    if(p_Parent == INVALID_ENT_REFERENCE)
        TE_WriteNum("entindex", 0);
    else
        TE_WriteNum("entindex", p_Parent);
        
    TE_SendToAll(p_Delay);
}

stock GetEffectIndex(const String:sEffectName[])
{
	static table = INVALID_STRING_TABLE;
	
	if (table == INVALID_STRING_TABLE)
	{
		table = FindStringTable("EffectDispatch");
	}
	
	new iIndex = FindStringIndex(table, sEffectName);
	if(iIndex != INVALID_STRING_INDEX)
		return iIndex;
	
	// This is the invalid string index
	return 0;
}