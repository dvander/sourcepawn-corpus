#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.0"


public Plugin myinfo =
{
	name = "L4D1 l4d_hospital03_sewers_pimp",
	author = "finishlast",
	description = "",
	version = PLUGIN_VERSION,
	url = ""
};

public void OnMapStart()
{
	PrecacheModel("models/props_vehicles/cara_69sedan.mdl");
}

public void OnPluginStart()
{
	CreateConVar("l4d_hospital03_sewers_pimp_version", PLUGIN_VERSION, "", FCVAR_DONTRECORD|FCVAR_NOTIFY);
	HookEvent("round_freeze_end", event_round_freeze_end, EventHookMode_PostNoCopy);
	HookEntityOutput("logic_relay", "OnTrigger", OnTrigger); 
}

public void event_round_freeze_end(Event event, const char[] name, bool dontBroadcast)
{
	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));
	if (StrEqual(sMap, "l4d_hospital03_sewers", false) || StrEqual(sMap, "l4d_vs_hospital03_sewers", false) )
	{
		float vPos[3], vAng[3];
		int entity = INVALID_ENT_REFERENCE;

		entity = CreateEntityByName("prop_physics");
		if( entity != -1 )
		{
			SetEntityModel(entity, "models/props_vehicles/cara_69sedan.mdl");
			DispatchKeyValue(entity, "solid", "6");
			DispatchSpawn(entity);
			vPos[0] = 12280.221680;
			vPos[1] = 6220.920410;
			vPos[2] = 78.031250;
			vAng[0] = 0.0;
			vAng[1] = 90.0;
			vAng[2] = 0.0;
			TeleportEntity(entity, vPos, vAng, NULL_VECTOR);
		}
	}
}

public void OnTrigger(const char[] output, int caller, int activator, float delay)
{
	float vPos[3], vAng[3], vDir[3];
	char m_iName[MAX_NAME_LENGTH];
        GetEntPropString(caller, Prop_Data, "m_iName", m_iName, sizeof(m_iName));
	if(StrEqual(m_iName, "gasstation_explosion_relay", false)){
		int target = -1;
		while((target = FindEntityByClassname(target, "prop_physics")) > -1)
		{
			if(IsValidEntity(target))
			{
				char sModel[64];
				GetEntPropString(target, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
				if(StrContains(sModel, "cara_69sedan") > -1)

				{
					GetEntPropVector(target, Prop_Data, "m_vecAbsOrigin", vPos);
					GetEntPropVector(target, Prop_Send, "m_angRotation", vAng);
					vPos[0] -= 300;
					vPos[1] += 500;
					vPos[2] += 250;
					vAng[0] = 90.0;
					vAng[1] = 90.0;
					//vAng[2] = 90.0;
					vDir[0] = 0.0;
					vDir[1] = 200.0;
					vDir[2] = 0.0;
					TeleportEntity(target, vPos, vAng, vDir);
					
					

					CreateTimer(6.0, changecar);
					
					char command[] = "director_force_panic_event";
					char flags = GetCommandFlags(command);
					SetCommandFlags(command, flags & ~FCVAR_CHEAT);
					FakeClientCommand(activator, command);
					SetCommandFlags(command, flags);
					break;
				}
			}
		}
	}
}
 
public Action changecar(Handle timer)
{
	int target = -1;
	while((target = FindEntityByClassname(target, "prop_physics")) > -1)
		{
			if(IsValidEntity(target))
			{
				char sModel[64];
				GetEntPropString(target, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
				if(StrContains(sModel, "cara_69sedan") > -1)

				{
	
					float vPos[3], vAng[3], vDir[3];
					vDir[0] = 0.0;
					vDir[1] = 0.0;
					vDir[2] = 0.0;

					GetEntPropVector(target, Prop_Data, "m_vecAbsOrigin", vPos);
					GetEntPropVector(target, Prop_Send, "m_angRotation", vAng);
	
					TeleportEntity(target, vPos, vAng, vDir);
					break;
				}
			}
		}
}



