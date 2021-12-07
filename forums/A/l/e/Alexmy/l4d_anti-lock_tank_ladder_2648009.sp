#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

static int tank;
int i_client[MAXPLAYERS+1];

public Plugin myinfo = 
{
	name = "[L4D] Anti-Lock Tank Ladder", 
	author = "AlexMy", 
	description = "", 
	version = "1.0",
	url = ":р :)"
};

public void OnPluginStart()
{
	HookEvent("player_jump_apex", eventPlayerJumpApex);
	
	HookEvent("tank_spawn",  eventTank);
	HookEvent("tank_killed", eventTank);
}

public void eventTank(Event event, const char[] name, bool dontBroadcast)
{
	if((tank = GetClientOfUserId(event.GetInt("userid"))) && tank && IsClientInGame(tank) && i_GamePlayers(tank)) 
		i_client[tank] = 0;
}

public Action eventPlayerJumpApex(Event event, const char[] name, bool dontBroadcast)
{
	if((tank = GetClientOfUserId(event.GetInt("userid"))) && tank && IsClientInGame(tank) && i_GamePlayers(tank) && i_GameMove(tank)) 
	{
		i_client[tank]++;
		if(i_client[tank] == 5) //Небольшая отсрочка для точной проверки.
		{
			i_client[tank] = 0;
			for(int i = 1; i <= MaxClients; i++) if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
			{
				float pos[3];
				GetClientAbsOrigin(i, pos);
				TeleportEntity(tank, pos, NULL_VECTOR,NULL_VECTOR);
				PrintToChatAll("\x05%N \x04Застрял на Лестнице. Телепортнём Его к \x05%N.", tank, i);
				break;
			} 
		}
	}
}

int i_GameMove(int hulk)
{
	return (GetEntProp(hulk, Prop_Data, "m_MoveType") == 9);
}

int i_GamePlayers(int hulk)
{
	return (GetEntProp(hulk, Prop_Send, "m_zombieClass") == 5);
}