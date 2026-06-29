#pragma semicolon 1
#include <sourcemod>
#pragma newdecls required

char    id_player[32];
Handle  tank_dead = null, witch_dead = null, finale_tank_dead = null, finale_witch_dead = null, message_tank = null, message_witch = null, sm_draw_population = null;
bool    final_tank_dead,  final_witch_dead;


public Plugin myinfo = 
{
	name = "[L4D] Penalty for murder",
	author = "AlexMy",
	description = "The punishment for killing the boss",
	version = "1.3",
	url = "https://forums.alliedmods.net/showthread.php?p=2538810#post2538810"
};

public void OnPluginStart()
{
	tank_dead          = CreateConVar("tank_dead",   "1", "Caused a panic wave, if the tank killed?         0:Off. 1:On.", FCVAR_NOTIFY);
	witch_dead         = CreateConVar("witch_dead",  "1", "Caused a panic wave, if the witch was killed?    0:Off. 1:On.", FCVAR_NOTIFY);
	
	finale_tank_dead   = CreateConVar("finale_tank_dead",  "1", "Caused a panic wave, if the tank killed the final?     1:Off. 0:On.", FCVAR_NOTIFY);
	finale_witch_dead  = CreateConVar("finale_witch_dead", "1", "Caused a panic wave, if the witch killed the final?    1:Off. 0:On.", FCVAR_NOTIFY);
	
	message_tank       = CreateConVar("message_tank",  "1", "Players will get the message who killed the tank?     0:Off. 1:On.", FCVAR_NOTIFY);
	message_witch      = CreateConVar("message_witch", "1", "Players will get the message who killed the witch?    0:Off. 1:On.", FCVAR_NOTIFY);
	
	sm_draw_population = CreateConVar("sm_attract_population_infected", "0", "Take resources from the zombie population?    0:Off. 1:On.", FCVAR_NOTIFY);
	
	HookEvent("tank_killed",   Event_TankKilled,   EventHookMode_Post);
	HookEvent("witch_killed",  Event_WitchKilled,  EventHookMode_Post);
	
	HookEvent("finale_start",  Event_FinaleStart,  EventHookMode_Post);
	
	HookEvent("round_start",   Event_ResetBool,    EventHookMode_Post);
	HookEvent("round_end",     Event_ResetBool,    EventHookMode_Post);
	
	AutoExecConfig(true, "l4d_penalty for murder");
}
public void OnMapStart()
{
	SetConVarInt(FindConVar("z_no_cull"), GetConVarInt(sm_draw_population), false, false);
}
public void Event_TankKilled(Event event, const char[] name, bool dontBroadcast)
{
	if(!GetConVarInt(tank_dead) || (final_tank_dead))return;
	{
		int attacker = GetClientOfUserId(event.GetInt("attacker"));
		{
			if(attacker) GetClientName(attacker, id_player, sizeof(id_player));
			{
				PanicEvent();
				if(!GetConVarInt(message_tank))return;
				{
					PrintToChat(GetAnyClient(), "\x05%s \x03killer the character of the \x05Tank, \x03thereby causing a panic wave!", id_player);
				}
			}
		}
	}
}
public void Event_WitchKilled(Event event, const char[] name, bool dontBroadcast)
{
	if(!GetConVarInt(witch_dead) || (final_witch_dead))return;
	{
		int attacker = GetClientOfUserId(event.GetInt("userid"));
		{
			if(attacker) GetClientName(attacker, id_player, sizeof(id_player));
			{
				PanicEvent();
				if(!GetConVarInt(message_witch))return;
				{
					PrintToChat(GetAnyClient(), "\x05%s \x03killer the character of the \x05Witch, \x03thereby causing a panic wave!", id_player);
				}
			}
		}
	}
}
public void Event_FinaleStart(Event event, const char[] name, bool dontBroadcast)
{
	if(!GetConVarInt(finale_tank_dead))return;
	{
		final_tank_dead = true;
	}
	if(!GetConVarInt(finale_witch_dead))return;
	{
		final_witch_dead = true;
	}
}
public void Event_ResetBool(Event event, const char[] name, bool dontBroadcast)
{
	final_tank_dead = false, final_witch_dead = false;
}
public void PanicEvent()
{
	int anyclient = GetAnyClient();
	if(anyclient == -1)return;
	{
		CheatCommand(anyclient, "z_spawn", "mob", "auto");
		CheatCommand(anyclient, "director_force_panic_event");
	}
}
stock int GetAnyClient()
{
	int i;
	for (i = 1; i <= GetMaxClients(); i++) 
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i))
			return i;
	}
	return 0;
}
stock void CheatCommand(int client, char [] command, char arguments[]="", char arguments1[]="")
{
	if(client)
	{
		int userflags = GetUserFlagBits(client);
		SetUserFlagBits(client, ADMFLAG_ROOT);
		int flags = GetCommandFlags(command);
		SetCommandFlags(command, flags & ~FCVAR_CHEAT);
		FakeClientCommand(client, "%s %s %s", command, arguments, arguments1);
		SetCommandFlags(command, flags);
		SetUserFlagBits(client, userflags);
	}
}