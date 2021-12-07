#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.3b"

new Handle:g_Force = INVALID_HANDLE;
new Handle:g_Distance = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "Push",
	author = "Zephyrus",
	description = "Privately coded plugin.",
	version = PLUGIN_VERSION,
	url = ""
}

public OnPluginStart()
{
	g_Force = CreateConVar("sm_push_force", "300.0");
	g_Distance = CreateConVar("sm_push_distance", "150.0")	
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(buttons & IN_USE)
	{
		new ent = GetClientAimTarget(client, false);
		if(ent > MaxClients)
		{
			new Float:m_fMass = 20.0;

			decl String:m_szClassname[64];
			if(GetEntityNetClass(ent, m_szClassname, sizeof(m_szClassname)))
				if(FindSendPropOffs("m_szClassname", "m_fMass")!=-1)
					m_fMass = GetEntPropFloat(ent, Prop_Send, "m_fMass");

			new Float:playerpos[3];
			GetClientAbsOrigin(client, playerpos);
			
			new Float:entpos[3];
			GetEntPropVector(ent, Prop_Send, "m_vecOrigin", entpos);
			
			if(GetVectorDistance(playerpos, entpos) < GetConVarFloat(g_Distance))
			{
				new Float:vangles[3];
				GetClientEyeAngles(client, vangles);
				
				new Float:velocity[3];
				GetAngleVectors(vangles, velocity, NULL_VECTOR, NULL_VECTOR);
				
				NormalizeVector(velocity, velocity);
				
				ScaleVector(velocity, (GetConVarFloat(g_Force)/(m_fMass/20)));
				if(buttons & IN_BACK)
					ScaleVector(velocity, -1.0);
				
				velocity[2] = 0.0;
				
				TeleportEntity(ent, NULL_VECTOR, NULL_VECTOR, velocity);
			}
		}
	}
}
