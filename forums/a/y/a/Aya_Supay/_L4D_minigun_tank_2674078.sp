
/*=======================================================================================
	Change Log:
	
1.0 (25-06-2019)
	- First commit by Joshe Gatito
	
========================================================================================
	Commands:
	
	nothing
	
========================================================================================
	Credits:
	
	Alexmy - for the original idea https://forums.alliedmods.net/showthread.php?t=316433

========================================================================================*/

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#pragma newdecls required

public Plugin myinfo =
{
	name = "[L4D] Minigun Tank",
	author = "Joshe Gatito",
	description = "Minigun Tank fix",
	version = "1.0",
	url = "https://github.com/JosheGatitoSpartankii09"
};

// ====================================================================================================
//					OnPlayerRunCmd
// ====================================================================================================

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{	
	if( IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2 )
	{
		if ((buttons & IN_USE))
		{
			int entity = GetEntPropEnt(client, Prop_Send, "m_hUseEntity");
			if (!IsValidEdict(entity)) return Plugin_Continue;
			char sClass[32];
			GetEdictClassname(entity, sClass, sizeof(sClass));
			if (StrEqual(sClass, "prop_minigun"))
			{
			    SetEntProp(client, Prop_Send, "m_usingMinigun", 0);
			}			
		}
	}
	
	return Plugin_Continue;
}