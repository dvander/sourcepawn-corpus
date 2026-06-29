#include <sdkhooks> 
#include <sdktools> 
#include <sourcemod> 

public Action OnPlayerRunCmd(int client, int &buttons)
{	
	if (IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
	{	
		if (buttons & IN_ATTACK && GetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration") > 0.0 && GetCurrentWeaponSlot(client) == 3)
		{
			ClientCommand(client, "+attack");
			if (buttons & IN_ATTACK2 || buttons & IN_JUMP)
			{
				ClientCommand(client, "-attack");
			}
		}
		else if (buttons & IN_USE && GetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration") > 0.0)
		{
			ClientCommand(client, "+use");
			if (buttons & IN_ATTACK2 || buttons & IN_JUMP)
			{
				ClientCommand(client, "-use");
			}
		}
	}
}
	
GetCurrentWeaponSlot(int client)
{
	int slot = -1; 
	
	if (GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon") == GetPlayerWeaponSlot(client, 0))
		slot = 0;
	else if (GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon") == GetPlayerWeaponSlot(client, 1))
		slot = 1;
	else if (GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon") == GetPlayerWeaponSlot(client, 2))
		slot = 2;
	else if (GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon") == GetPlayerWeaponSlot(client, 3))
		slot = 3;
	else if (GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon") == GetPlayerWeaponSlot(client, 4))
		slot = 4;
	else if (GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon") == GetPlayerWeaponSlot(client, 5))
		slot = 5;		
		
	if(slot < 0)
	{ 
		for(int i = 0; i < 5; i++)
		{
			int s = GetPlayerWeaponSlot(client, i);
			if(s > 0)
			{
				slot=i;
				break;
			}
		} 
	}
	return slot;
}
