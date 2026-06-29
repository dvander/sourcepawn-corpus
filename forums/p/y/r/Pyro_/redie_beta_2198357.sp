#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION	 "2.5b"
#define LIFE_ALIVE		0
#define LIFE_DYING		1
#define LIFE_DEAD		2
#define LIFE_RESPAWNABLE 	3

//Defining ConVars
ConVar cCvar_adverts;
ConVar cCvar_bhop;
ConVar cCvar_dm;
ConVar cCvar_hurt;
ConVar cCvar_door;
ConVar cCvar_unredie;
ConVar cCvar_cooldown;

//Defining local ConVar values that get changed when the convars do.
bool bCvar_adverts = true;
bool bCvar_bhop = false;
bool bCvar_dm = false;
bool bCvar_hurt = true;
bool bCvar_door = true;
bool bCvar_unredie = false;
int  iCvar_cooldown = 2;

bool g_bBlockCommand; //Block sm_redie. Is set to true in between rounds
int g_iCollision; //Collision group property offset

bool g_bIsGhost[MAXPLAYERS+1]; //Array of all clients defining if they are currently in redie
bool g_bDMredie[MAXPLAYERS+1]; //Array of all clients defining if they are currently waiting for their next death to be respawned in redie
int g_iLastCalled[MAXPLAYERS+1]; //Array of all clients defining when they last used !redie
bool g_bHurtCooldown[MAXPLAYERS+1]; //Stops multiple redies being called from trigger_hurt

//Allows other plugins to check if a client is in redie
forward bool redieIsGhost(int client);
public bool redieIsGhost(int client)
{
	return g_bIsGhost[client];
}

public Plugin myinfo =
{
	name = "CS:GO Redie",
	author = "Pyro",
	description = "Return as a ghost after you died.",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/profiles/76561198051084603"
};

public void OnPluginStart()
{
	//Event hooks
	HookEvent("round_start", Event_Round_Start, EventHookMode_Pre);	
	HookEvent("round_end", Event_Round_End, EventHookMode_Pre);
	HookEvent("player_spawn", Event_Player_Spawn);
	HookEvent("player_death", Event_Player_Death);
	HookEvent("player_death", Event_Player_Death_Pre, EventHookMode_Pre);

	//Commands
	RegConsoleCmd("sm_redie", Command_Redie); //Respawns player as ghost (or if sm_redie_dm, puts them in the queue)
	RegConsoleCmd("sm_unredie", Command_UnRedie); //Puts player back into spectator mode

	//ConVars
	CreateConVar("sm_redie_version", PLUGIN_VERSION, "Redie Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cCvar_adverts = CreateConVar("sm_redie_adverts", "1", "If enabled, redie will produce an advert every 2 minutes.");
	cCvar_bhop = CreateConVar("sm_redie_bhop", "0", "If enabled, ghosts will be able to autobhop by holding space.");
	cCvar_dm = CreateConVar("sm_redie_dm", "0", "If enabled, using redie while alive will make you a ghost next time you die.");
	cCvar_hurt = CreateConVar("sm_redie_hurt", "1", "Trigger_hurt. 0: Ghosts unaffected. 1: Ghosts instantly respawn.");
	cCvar_door = CreateConVar("sm_redie_door", "1", "Func_door. 0: Ghosts can block it. 1: Ghosts instantly respawn when they block a door.");
	cCvar_unredie = CreateConVar("sm_redie_unredie", "0", "Enables !unredie. This is a patch fix for !unredie and can be buggy.");
	cCvar_cooldown = CreateConVar("sm_redie_cooldown", "2", "Cooldown time of !redie (in seconds).");

	//Hook ConVar changes
	cCvar_adverts.AddChangeHook(CvarHook_Adverts);
	cCvar_bhop.AddChangeHook(CvarHook_Bhop);
	cCvar_dm.AddChangeHook(CvarHook_DM);
	cCvar_hurt.AddChangeHook(CvarHook_Hurt);
	cCvar_door.AddChangeHook(CvarHook_Door);
	cCvar_unredie.AddChangeHook(CvarHook_Unredie);
	cCvar_cooldown.AddChangeHook(CvarHook_Cooldown);

	//Setting collision property offset
	g_iCollision = FindSendPropInfo("CBaseEntity", "m_CollisionGroup");

	//Advertisement timer of redie
	CreateTimer(120.0, Timer_Advert, _,TIMER_REPEAT);

	//Silences "!redie"
	AddCommandListener(OnSay, "say");
	AddCommandListener(OnSay, "say_team");

	//Hooks normal sounds
	AddNormalSoundHook(OnNormalSoundPlayed);

	//Hooks doors getting blocked
	HookEntityOutput("func_door", "OnBlockedOpening", EntityOutput_DoorBlocked);
	HookEntityOutput("func_door", "OnBlockedClosing", EntityOutput_DoorBlocked);
}

public void OnConfigsExecuted()
{
	//Set current cvars
	bCvar_adverts = GetConVarBool(cCvar_adverts);
	bCvar_bhop = GetConVarBool(cCvar_bhop);
	bCvar_dm = GetConVarBool(cCvar_dm);
	bCvar_hurt = GetConVarBool(cCvar_hurt);
	bCvar_door = GetConVarBool(cCvar_door);
	bCvar_unredie = GetConVarBool(cCvar_unredie);
	iCvar_cooldown = GetConVarInt(cCvar_cooldown);
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
}

public void OnClientPostAdminCheck(int client)
{
	//Reset all arrays for the new player
	g_bIsGhost[client] = false;
	g_bDMredie[client] = false;
	g_iLastCalled[client] = 0;
	g_bHurtCooldown[client] = false;
}

public Action Event_Round_Start(Event event, const char[] name, bool dontBroadcast) 
{
	g_bBlockCommand = false;
	int ent = MaxClients + 1;
	while((ent = FindEntityByClassname(ent, "trigger_multiple")) != -1)
	{
		SDKHookEx(ent, SDKHook_EndTouch, ignoreCollision);
		SDKHookEx(ent, SDKHook_StartTouch, ignoreCollision);
		SDKHookEx(ent, SDKHook_Touch, ignoreCollision);
	}
	ent = MaxClients + 1;
	while((ent = FindEntityByClassname(ent, "func_door")) != -1)
	{
		SDKHookEx(ent, SDKHook_EndTouch, ignoreCollision);
		SDKHookEx(ent, SDKHook_StartTouch, ignoreCollision);
		SDKHookEx(ent, SDKHook_Touch, ignoreCollision);
	}
	ent = MaxClients + 1;
	while((ent = FindEntityByClassname(ent, "func_button")) != -1)
	{
		SDKHookEx(ent, SDKHook_EndTouch, ignoreCollision);
		SDKHookEx(ent, SDKHook_StartTouch, ignoreCollision);
		SDKHookEx(ent, SDKHook_Touch, ignoreCollision);
	}
	ent = MaxClients + 1;
	while((ent = FindEntityByClassname(ent, "trigger_once")) != -1)
	{
		SDKHookEx(ent, SDKHook_EndTouch, ignoreCollision);
		SDKHookEx(ent, SDKHook_StartTouch, ignoreCollision);
		SDKHookEx(ent, SDKHook_Touch, ignoreCollision);
	}
	ent = MaxClients + 1;
	while((ent = FindEntityByClassname(ent, "trigger_hurt")) != -1)
	{
		SDKHookEx(ent, SDKHook_EndTouch, handleHurtCollision);
		SDKHookEx(ent, SDKHook_StartTouch, handleHurtCollision);
		SDKHookEx(ent, SDKHook_Touch, handleHurtCollision);
	}
	for(int i = 1; i < MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			SDKHook(i, SDKHook_TraceAttack, OnTraceAttack);
		}
	}
}

public Action Event_Round_End(Event event, const char[] name, bool dontBroadcast) 
{
	g_bBlockCommand = true;
}

public Action Event_Player_Spawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	SDKHook(client, SDKHook_SetTransmit, Hook_SetTransmit);
	if(g_bIsGhost[client])
	{
		g_bIsGhost[client] = false;
	}
}

public Action Event_Player_Death(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(g_bDMredie[client])
	{
		g_bDMredie[client] = false;
		CreateTimer(0.1, Timer_BringBack, client);
	}
	else
	{
		PrintToChat(client, "\x01[\x03Redie\x01] \x04Type !redie into chat to respawn as a ghost.");

		if(GetClientTeam(client) == 3)
		{
			int ent = -1;
			while((ent = FindEntityByClassname(ent, "item_defuser")) != -1)
			{
				if(IsValidEntity(ent))
				{
					AcceptEntityInput(ent, "kill");
				}
			}
		}
	}
}

//Block pre-event if they are !unredie-ing, this stops the notification and such.
public Action Event_Player_Death_Pre(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(bCvar_unredie)
	{
		if(g_bIsGhost[client])
		{
			g_bIsGhost[client] = false;
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public Action Command_Redie(int client, int args)
{
	int time = GetTime();
	if(time - g_iLastCalled[client] < iCvar_cooldown)
	{
		PrintToChat(client, "\x01[\x03Redie\x01] \x04You have to wait another \x02%i \x04seconds before you can use that!", iCvar_cooldown - (time - g_iLastCalled[client]));
	}
	else
	{
		g_iLastCalled[client] = time;
		Redie(client);
	}
	return Plugin_Handled;
}

public Action Command_UnRedie(int client, int args)
{
	int time = GetTime();
	if(time - g_iLastCalled[client] < iCvar_cooldown)
	{
		PrintToChat(client, "\x01[\x03Redie\x01] \x04You have to wait another \x02%i \x04seconds before you can use that!", iCvar_cooldown - (time - g_iLastCalled[client]));
	}
	else
	{
		g_iLastCalled[client] = time;
		UnRedie(client);
	}
	return Plugin_Handled;
}

public void Redie(int client)
{
	if (!IsPlayerAlive(client))
	{
		if(!g_bBlockCommand)
		{
			if (GetClientTeam(client) > 1)
			{
				g_bIsGhost[client] = false; //Allows them to pick up knife and gun to then have it removed from them
				CS_RespawnPlayer(client);
				g_bIsGhost[client] = true;
				int weaponIndex;
				for (int i = 0; i <= 3; i++)
				{
					if ((weaponIndex = GetPlayerWeaponSlot(client, i)) != -1)
					{
						RemovePlayerItem(client, weaponIndex);
						RemoveEdict(weaponIndex);
					}
				}
				SetEntProp(client, Prop_Send, "m_lifeState", LIFE_DYING);
				SetEntData(client, g_iCollision, 2, 4, true);
				SetEntProp(client, Prop_Data, "m_ArmorValue", 0);
				SetEntProp(client, Prop_Send, "m_bHasDefuser", 0);
				PrintToChat(client, "\x01[\x03Redie\x01] \x04You are now a ghost.");
			}
			else
			{
				PrintToChat(client, "\x01[\x03Redie\x01] \x04You must be on a team.");
			}
		}
		else
		{
			PrintToChat(client, "\x01[\x03Redie\x01] \x04Please wait for the new round to begin.");
		}
	}
	else
	{
		if(bCvar_dm)
		{
			if(g_bDMredie[client])
			{
				PrintToChat(client, "\x01[\x03Redie\x01] \x04You will no longer be brought back as a ghost next time you die.");
			}
			else
			{
				PrintToChat(client, "\x01[\x03Redie\x01] \x04You will be brought back as a ghost next time you die.");
			}
			g_bDMredie[client] = !g_bDMredie[client];
		}
		else
		{
			PrintToChat(client, "\x01[\x03Redie\x01] \x04You must be dead to use !redie.");
		}
	}
}

//Patch-fix, I tried to do it a nicer way; but was unsuccessful. 'specgui' wouldn't stay.
public void UnRedie(int client)
{
	if(bCvar_unredie)
	{
		if(g_bIsGhost[client])
		{
			if(!g_bBlockCommand)
			{
				if (GetClientTeam(client) > 1)
				{
					SetEntProp(client, Prop_Send, "m_lifeState", LIFE_ALIVE);
					ForcePlayerSuicide(client);
					PrintToChat(client, "\x01[\x03Redie\x01] \x04You are no longer a ghost.");
				}
				else
				{
					PrintToChat(client, "\x01[\x03Redie\x01] \x04You must be on a team.");
				}
			}
			else
			{
				PrintToChat(client, "\x01[\x03Redie\x01] \x04Please wait for the new round to begin.");
			}
		}
		else
		{
			PrintToChat(client, "\x01[\x03Redie\x01] \x04You must be a ghost to use !unredie.");
		}
	}
	else
	{
		PrintToChat(client, "\x01[\x03Redie\x01] \x04The server has disabled this feature.");
	}
}

public void CvarHook_Adverts(ConVar convar, char[] oldVal, char[] newVal)
{
	if(StringToInt(newVal) > 0)
	{
		bCvar_adverts = true;
	}
	else
	{
		bCvar_adverts = false;
	}
}

public void CvarHook_Bhop(ConVar convar, char[] oldVal, char[] newVal)
{
	if(StringToInt(newVal) > 0)
	{
		bCvar_bhop = true;
	}
	else
	{
		bCvar_bhop = false;
	}
}

public void CvarHook_DM(ConVar convar, char[] oldVal, char[] newVal)
{
	if(StringToInt(newVal) > 0)
	{
		bCvar_dm = true;
	}
	else
	{
		bCvar_dm = false;
	}
}

public void CvarHook_Hurt(ConVar convar, char[] oldVal, char[] newVal)
{
	if(StringToInt(newVal) > 0)
	{
		bCvar_hurt = true;
	}
	else
	{
		bCvar_hurt = false;
	}
}

public void CvarHook_Door(ConVar convar, char[] oldVal, char[] newVal)
{
	if(StringToInt(newVal) > 0)
	{
		bCvar_door = true;
	}
	else
	{
		bCvar_door = false;
	}
}

public void CvarHook_Unredie(ConVar convar, char[] oldVal, char[] newVal)
{
	if(StringToInt(newVal) > 0)
	{
		bCvar_unredie = true;
	}
	else
	{
		bCvar_unredie = false;
	}
}

public void CvarHook_Cooldown(ConVar convar, char[] oldVal, char[] newVal)
{
	iCvar_cooldown = StringToInt(newVal); //No error checking needed as 0 on error.
}

public Action ignoreCollision(int entity, int other)
{
	if
	(
		(0 < other && other <= MaxClients) &&
		(g_bIsGhost[other]) &&
		(IsClientInGame(other))
	)
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action handleHurtCollision(int entity, int other)
{
	if
	(
		(0 < other && other <= MaxClients) &&
		(g_bIsGhost[other]) &&
		(IsClientInGame(other))
	)
	{
		if(bCvar_hurt)
		{
			if(!g_bHurtCooldown[other])
			{
				PrintToChat(other, "\x01[\x03Redie\x01] \x04You were respawned due to trigger_hurt!");
				g_bHurtCooldown[other] = true;
				CreateTimer(0.1, Timer_HurtCooldown, other);
				Redie(other);
			}

		}
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action Timer_Advert(Handle timer)
{
	if(bCvar_adverts)
	{
		PrintToChatAll("\x01[\x03Redie\x01] \x04This server is running !redie.");
	}
	return Plugin_Continue;
}

public Action OnSay(int client, const char[] command, int args)
{
	char messageText[200];
	GetCmdArgString(messageText, sizeof(messageText));
	
	if(strcmp(messageText, "\"!redie\"", false) == 0)
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action OnNormalSoundPlayed(int clients[64], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags)
{
	if(entity && entity <= MaxClients && g_bIsGhost[entity])
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}


public Action OnTraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{
	if(IsValidEntity(victim))
	{
		if(g_bIsGhost[victim])
		{
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public Action Hook_SetTransmit(int entity, int client)
{
	if(g_bIsGhost[entity] && entity != client)
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action Timer_BringBack(Handle timer, any client)
{
	Redie(client);
}

public Action Timer_HurtCooldown(Handle timer, any client)
{
	g_bHurtCooldown[client] = false;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if(g_bIsGhost[client])
	{
		buttons &= ~IN_USE;
		if(bCvar_bhop)
		{
			//Based off AbNeR's bhop code
			if(buttons & IN_JUMP)
			{
				if(GetEntProp(client, Prop_Data, "m_nWaterLevel") <= 1 && !(GetEntityMoveType(client) & MOVETYPE_LADDER) && !(GetEntityFlags(client) & FL_ONGROUND))
				{
					SetEntPropFloat(client, Prop_Send, "m_flStamina", 0.0);
					buttons &= ~IN_JUMP;
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action OnWeaponCanUse(int client, int weapon)
{
	if(g_bIsGhost[client])
		return Plugin_Handled;
	
	return Plugin_Continue;
}

public void EntityOutput_DoorBlocked(const char[] output, int caller, int activator, float delay)
{
	if(bCvar_door)
	{
		if(activator > 0 && activator < MAXPLAYERS)
		{
			if(g_bIsGhost[activator])
			{
				PrintToChat(activator, "\x01[\x03Redie\x01] \x04You were respawned because you weere blocking a door!");
				Redie(activator);
			}
		}
	}
}
