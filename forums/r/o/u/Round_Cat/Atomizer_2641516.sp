#include <sourcemod>
#include <tf2items>
#include <tf2_stocks>
#include <tf2attributes>

#define	IsValidClient(%1)		(1 <= %1 <= MaxClients)

new dashoffset;
new jumpcount[MAXPLAYERS+1]=0;
new Handle:cvarEnabled;

public Plugin:myinfo = {
	name	= "The old atomizer is back!",
	author	= "RoundCat",
	version = "1.0",
};


public OnPluginStart()
{
	dashoffset = FindSendPropInfo("CTFPlayer", "m_iAirDash");
	cvarEnabled = CreateConVar("sm_atomizer_enabled", "1", "Is this mod enabled?");
	HookConVarChange(cvarEnabled, CvarChange);
}

public CvarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(convar==cvarEnabled)
	{
		for (int client = 1; client <= MaxClients; client++)
		{
			if (!IsValidClient(client) || !IsClientInGame(client)) 
			{
				return;
			}
			new weapon=GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
			if(weapon>MaxClients && IsValidEntity(weapon))
			{
				if(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex")==450)
				{
					StringToInt(newValue) ? (TF2Attrib_SetByDefIndex(weapon, 250, 0.0)) : (TF2Attrib_SetByDefIndex(weapon, 250, 1.0));
				}
			}
		}
	}
}
public void OnGameFrame()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if(GetConVarBool(cvarEnabled))
		{
			if (!IsClientInGame(client) || !IsPlayerAlive(client)) 
			{
				return;
			}
			
			new weapon=GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
			if(weapon>MaxClients && IsValidEntity(weapon))
			{
				if(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex")==450)
				{
					TF2Attrib_SetByDefIndex(weapon, 250, 0.0);
				}
			}
		}
	}
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(buttons & IN_JUMP)
	{			
		if(GetIndexOfWeaponSlot(client, TFWeaponSlot_Melee)==450)
		{	
			if(GetConVarBool(cvarEnabled))
			{
				if(IsClientInGame(client) && IsPlayerAlive(client))
				{
					if(GetEntityFlags(client) & FL_ONGROUND)
					{
						SetEntData(client, dashoffset, -1);
						jumpcount[client]++;
						CreateTimer(0.1, Timer_OnGround, client);
					}
					else
					{
						if(jumpcount[client]==0)
						{
							SetEntData(client, dashoffset, -1);
							jumpcount[client]++;
						}
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action:Timer_OnGround(Handle:hTimer, any:client)
{
	if(IsClientInGame(client))
	{
		if(IsPlayerAlive(client))
		{
			if(GetEntityFlags(client) & FL_ONGROUND)
			{
				jumpcount[client]=0;
				return Plugin_Stop;
			}
		}
		CreateTimer(0.05, Timer_OnGround, client);
	}
	return Plugin_Continue;
}

stock GetIndexOfWeaponSlot(client, slot)
{
	new weapon=GetPlayerWeaponSlot(client, slot);
	return (weapon>MaxClients && IsValidEntity(weapon) ? GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") : -1);
}