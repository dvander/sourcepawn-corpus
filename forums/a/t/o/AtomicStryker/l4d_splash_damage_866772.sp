#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"
#define CVAR_FLAGS          FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY


new Handle:SplashEnabled = INVALID_HANDLE;
new Handle:SplashRadius = INVALID_HANDLE;
new Handle:SplashDamage = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "L4D_Splash_Damage",
	author = " AtomicStryker",
	description = "Left 4 Dead Boomer Splash Damage",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=96665"
}


public OnPluginStart()
{
	HookEvent("player_death", PlayerDeath, EventHookMode_Pre);
	
	CreateConVar("l4d_splash_damage_version", PLUGIN_VERSION, " Version of L4D Boomer Splash Damage on this server ", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	SplashEnabled = CreateConVar("l4d_splash_damage_enabled", "1", " Enable/Disable the Splash Damage plugin ", CVAR_FLAGS);
	SplashDamage = CreateConVar("l4d_splash_damage_damage", "10.0", " Amount of damage the Boomer Explosion deals ", CVAR_FLAGS);
	SplashRadius = CreateConVar("l4d_splash_damage_radius", "200", " Radius of Splash damage ", CVAR_FLAGS);
	
	
	// Autoexec config
	AutoExecConfig(true, "L4D_Splash_Damage");
	
}

public Action:PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	
	// We get the client id
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	// If client is valid
	if (client == 0) return Plugin_Continue;
	if (!IsClientConnected(client)) return Plugin_Handled;
	if (!IsClientInGame(client)) return Plugin_Handled;
	
	// If player wasn't on infected team, we ignore this ...
	if (GetClientTeam(client)!=3)
		return Plugin_Handled;
	
	// Victim classtype ...
	new String:class[100];
	GetClientModel(client, class, sizeof(class));
	
	if (StrContains(class, "boomer", false) != -1)
	{
		
		if (GetConVarInt(SplashEnabled))
		{
			//PrintToChatAll("Boomerdeath caught, Plugin running");
			new Float:g_pos[3];
			GetClientAbsOrigin(client,g_pos);
					
					
			for (new target = 1; target <= GetMaxClients(); target++)
			{
			if (IsClientInGame(target))
			{
				if (IsPlayerAlive(target))
				{
					if (GetClientTeam(client) != GetClientTeam(target))
					{
						new Float:targetVector[3];
						GetClientAbsOrigin(target, targetVector);

						new Float:distance = GetVectorDistance(targetVector, g_pos);
					
							if (distance < GetConVarFloat(SplashRadius))
							{							
						
								//PrintCenterText(target, "You've taken Damage from a Boomer Splash!");
								new damage = GetConVarInt(SplashDamage);
								new hardhp = GetEntProp(target, Prop_Data, "m_iHealth");
								////PrintToChatAll("HardHP: %i", GetEntProp(target, Prop_Data, "m_iHealth"));
								////PrintToChatAll("HardHP2: %i", hardhp);
								if (damage < hardhp)
								{
									////PrintToChatAll("Hard Damage IF applied, applying hard damage");
									SetEntProp(target, Prop_Send, "m_iHealth", (hardhp-damage));
									SetEntProp(target, Prop_Data, "m_iHealth", (hardhp-damage));
								}
								if (damage > hardhp)
								{
									new Float:temphp = GetEntPropFloat(target, Prop_Send, "m_healthBuffer");
									////PrintToChatAll("TempHP: %f", temphp);
									if (damage < temphp)
									{
										////PrintToChatAll("Temp Damage IF applied, applying temp damage");
										SetEntPropFloat(target, Prop_Send, "m_healthBuffer", (temphp - 10.0));
										//SetEntityHealth(target, (temphp - 10.0));
									}
								}
							}
						}
					}
				}
			}
		}
	}
	return Plugin_Continue;
}


