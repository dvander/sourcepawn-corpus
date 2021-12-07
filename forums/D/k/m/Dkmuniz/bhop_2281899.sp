#include <sourcemod>
#include <sdktools>
#include <cstrike>

new bool:bhop[MAXPLAYERS+1] = {false, ...};

public Plugin:myinfo =
{
	name = "Bhop Do Cipop",
	author = "Cipop",
	description = "Bhop do Cipop",
	version = "1.0",
	url = "http://www.sourcemod.net/"
};
 
public OnPluginStart()
{
	RegConsoleCmd("sm_bhop", sm_bhop, "Liga o BHop");
	RegConsoleCmd("sm_bhopoff", sm_bhopoff, "Desliga o BHop");
}

public Action:sm_bhop(client, args) { 
	if(IsClientInGame(client) && GetClientTeam(client) == 3)
	{
		PrintToChat(client, "Voce ativou seu bhop");
		bhop[client] = true;
	}
	else
	{
		PrintToChat(client, "Comando so para vivos ou Ct's");
	}
	
}

public Action:sm_bhopoff(client, args) { 

	if(IsClientInGame(client) && GetClientTeam(client) == 3)
	{
		PrintToChat(client, "Voce ativou seu bhop");
		bhop[client] = false;
	}
	else
	{
		PrintToChat(client, "Comando so para vivos ou Ct's");
	}
   
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	new water = GetEntProp(client, Prop_Data, "m_nWaterLevel");
	if (IsPlayerAlive(client))
	{
		if (buttons & IN_JUMP)
		{
			if (water <= 1)
			{
				if (!(GetEntityMoveType(client) & MOVETYPE_LADDER))
				{
					SetEntPropFloat(client, Prop_Send, "m_flStamina", 0.0);
					if (!(GetEntityFlags(client) & FL_ONGROUND))
					{
						if(bhop[client] == true)
						{
							buttons &= ~IN_JUMP;	
						}
					}
				}
			}
		}
	}
	
	return Plugin_Continue;
}
