#define PLUGIN_VERSION "1.0"
#include <sourcemod>
#include <sdktools>
#pragma semicolon 1
#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY

new Handle:PauseIgnoreAccess;
new Handle:HordeAmount[3];
new Handle:CommandAccess;
new OldValue[3];
new String:sPauseIgnoreAccess[128];
new bool:IsGamePaused = false;

public Plugin:myinfo = 

{
	name = "L4D PAUSE",
	author = "Olj",
	description = "Stops all players and disables hordes unless unpaused.",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
}

public OnPluginStart()
	{
		HordeAmount[0] = FindConVar("z_mega_mob_size");
		HordeAmount[1] = FindConVar("z_mob_spawn_max_size");
		HordeAmount[2] = FindConVar("z_mob_spawn_min_size");
		CommandAccess = CreateConVar("l4d_pausecmd_access","z", "Access level needed to pause game",CVAR_FLAGS);
		decl String:cmdaccess[128];
		GetConVarString(CommandAccess, cmdaccess, sizeof(cmdaccess));
		PauseIgnoreAccess = CreateConVar("l4d_pauseignore_access","a", "Access level needed to be immune to pause",CVAR_FLAGS);
		HookEvent("player_hurt", PlayerHurt_Event, EventHookMode_Pre);
		RegAdminCmd("l4d_pausegame", PauseGame, ReadFlagString(cmdaccess), "Pauses game for awhile", "", FCVAR_PLUGIN|FCVAR_SPONLY);
	}

public OnConfigsExecuted()
	{
		OldValue[0] = GetConVarInt(HordeAmount[0]);
		OldValue[1] = GetConVarInt(HordeAmount[1]);
		OldValue[2] = GetConVarInt(HordeAmount[2]);
	}
	
public Action:PauseGame(client, args)
	{
		if (!IsGamePaused)
			{
				IsGamePaused = true;
				for (new i = 1; i <=MaxClients; i++)
					{
						if ((IsValidClient(i))&&(!IsClientAdmin(i)))
							{
								SetEntityMoveType(client, MOVETYPE_NONE);
							}
					}
					
				for (new i = 0; i < sizeof(HordeAmount); i++)
					{
						new String:var[256];
						GetConVarName(HordeAmount[i], var, 256);
						new flags = GetCommandFlags(var);
						SetCommandFlags(var, flags & ~FCVAR_CHEAT);
						SetConVarInt(HordeAmount[i], 0, false, false);
						SetCommandFlags(var, flags);
					}
				return Plugin_Handled;
			}
			
		if (IsGamePaused)
			{
				IsGamePaused = false;
				for (new i = 1; i <=MaxClients; i++)
					{
						if (IsValidClient(i))
							{
								SetEntityMoveType(client, MOVETYPE_CUSTOM);
							}
					}
					
				for (new i = 0; i < sizeof(HordeAmount); i++)
					{
						new String:var[256];
						GetConVarName(HordeAmount[i], var, 256);
						new flags = GetCommandFlags(var);
						SetCommandFlags(var, flags & ~FCVAR_CHEAT);
						SetConVarInt(HordeAmount[i], OldValue[i], false, false);
						SetCommandFlags(var, flags);
					}
				return Plugin_Handled;
			}
		return Plugin_Handled;
	}
	
public OnClientPostAdminCheck(client)
		{
			if ((IsGamePaused) && (IsValidClient(client))&&(!IsClientAdmin(client)))
				{
					SetEntityMoveType(client, MOVETYPE_NONE);
				}
			
		}
	
public Action:PlayerHurt_Event(Handle:event, const String:name[], bool:dontBroadcast)
	{
		if (IsGamePaused)
			{
				new victim = GetClientOfUserId(GetEventInt(event, "userid"));
				if (IsValidClient(victim))
					{
						SetEntityHealth(victim,(GetEventInt(event,"dmg_health")+ GetEventInt(event,"health")));
						return Plugin_Continue;
					}
			}
		return Plugin_Continue;
	}
		
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
	{
		if ((IsGamePaused)&&(!IsClientAdmin(client)))
			{
				buttons &= ~IN_ATTACK;
				buttons &= ~IN_ATTACK2;
				return Plugin_Continue;
			}
		return Plugin_Continue;
	}
	
public IsValidClient (client)
	{
		if (client == 0)
			return false;
		
		if (!IsClientConnected(client))
			return false;
		
		if (!IsClientInGame(client))
			return false;
			
		if (!IsPlayerAlive(client))
			return false;
		return true;
	}
	
bool:IsClientAdmin (client)
	{
		new AdminId:id = GetUserAdmin(client);
		if (id == INVALID_ADMIN_ID)
			return false;
		
		if (GetAdminFlag(id, Admin_Root))
			return true;
		
		GetConVarString(PauseIgnoreAccess, sPauseIgnoreAccess, sizeof(sPauseIgnoreAccess));
		new FLAG = ReadFlagString(sPauseIgnoreAccess);
		new AdminFlag:FlagsArray[21];
		FlagBitsToArray(FLAG, FlagsArray, sizeof(FlagsArray));
		
		for (new i = 1; i <=sizeof(FlagsArray); i++)
			{
				if (GetAdminFlag(id, FlagsArray[i]))
					{
						return true;
					}
			}
		return false;
	}


	
	
