#include <sourcemod>
#include <sdktools>
#pragma semicolon 1
#pragma newdecls required

public void OnPluginStart()
{
	RegConsoleCmd("sm_giveknife", GiveKnife);
	
}
public Action GiveKnife(int client, int args)
{
	if(client == 0)
		return;
	
	int knife = GivePlayerItem(client, "weapon_knife");
	EquipPlayerWeapon(client, knife);
}
