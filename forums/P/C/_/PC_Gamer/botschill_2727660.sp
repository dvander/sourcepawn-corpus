#include <sourcemod>
#include <tf2_stocks> 

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.0"

public Plugin myinfo = 
{
	name = "Bots Chill/Attack",
	author = "PC Gamer",
	description = "Prevents Bots from moving or attacking",
	version = PLUGIN_VERSION,
	url = "https://www.alliedmods.net"
}

public void OnPluginStart() 
{	
	RegAdminCmd("sm_botschill", Command_BotsChill, ADMFLAG_SLAY, "Make Bots Chill");
	RegAdminCmd("sm_botsattack", Command_BotsAttack, ADMFLAG_SLAY, "Make Bots Attack");	
}

public Action Command_BotsChill(int client, int args)
{
	ReplyToCommand(client, "Bots are now Chill and won't move or attack.");
	ReplyToCommand(client, "Use sm_botsattack to make them move/attack again");	
	PrintToChatAll("Bots have been forced to Chill. They no longer move or attack");
	
	int i;
	for (i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsFakeClient(i))
		{
			SetEntityMoveType(i, MOVETYPE_NONE);
			TF2_RemoveWeaponSlot(i, 0);
			TF2_RemoveWeaponSlot(i, 1);			
			TF2_RemoveWeaponSlot(i, 2);	
			SetEntPropEnt(i, Prop_Send, "m_hActiveWeapon", -1);
		}
	}

	return Plugin_Handled;
}

public Action Command_BotsAttack(int client, int args)
{
	ReplyToCommand(client, "Bots are now moving and attacking.");
	ReplyToCommand(client, "Use sm_botschill to make them stop attacking again");
	PrintToChatAll("Bots are no longer Chill.  They will now move and attack");

	int i;
	for (i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsFakeClient(i))
		{
			SetEntityMoveType(i, MOVETYPE_WALK);
			TF2_RegeneratePlayer(i);			
		}
	}

	return Plugin_Handled;
}