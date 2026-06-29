#pragma semicolon 1;
#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.4"
#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY

new D;
new Handle:TankHealth;
new Handle:h_MobControlEnabled;
new Handle:h_TankHealthBonusEnabled;
new Handle:TankHealthBonus;
new Handle:ZombiesPerSurvivor;
new Handle:h_IncludeBots;
new bool:IncludeBots;
new Handle:MobArray[3];
new bool:TankHealthBonusEnabled;
new bool:Plus;
new bool:Enabled;
public Plugin:myinfo = 
{
	name = "Mob Control",
	author = "Olj",
	description = "Controls mob sizes based on survivors' quantity",
	version = PLUGIN_VERSION,
	url = "<- URL ->"
}

public OnPluginStart()
{
TankHealth = FindConVar("z_tank_health");
MobArray[0] = FindConVar("z_mega_mob_size");
MobArray[1] = FindConVar("z_mob_spawn_max_size");
MobArray[2] = FindConVar("z_mob_spawn_min_size");
CreateConVar("l4d_mobcontrol_version", PLUGIN_VERSION, " Version of L4D Mob Control on this server ", CVAR_FLAGS);
ZombiesPerSurvivor = CreateConVar("l4d_mobcontrol_zombiestoadd", "8", "Sets how much zombies to add per survivor", CVAR_FLAGS);
TankHealthBonus = CreateConVar("l4d_mobcontrol_tank_bonushealth", "666", "Sets how much HP to add per survivor", CVAR_FLAGS);
h_TankHealthBonusEnabled = CreateConVar("l4d_mobcontrol_tank_bonushealth_enabled", "1", "Disables or enables tank bonus hp feature", CVAR_FLAGS);
h_MobControlEnabled = CreateConVar("l4d_mobcontrol_enabled", "1", "Enables or disables plugin", CVAR_FLAGS);
h_IncludeBots = CreateConVar("l4d_mobcontrol_includebots", "1", "Set to 1 if you want plugin to process bots too.", CVAR_FLAGS);
IncludeBots = GetConVarBool(h_IncludeBots);
Enabled = false;
TankHealthBonusEnabled = GetConVarBool(h_TankHealthBonusEnabled);
AutoExecConfig(true, "l4d_mob_control");
HookConVarChange(h_MobControlEnabled, ConVarEnabled);

}

public OnConfigsExecuted()
{
if (GetConVarBool(h_MobControlEnabled)==false) MobControl_Disable();
    else                                     MobControl_Enable();
}

public ConVarEnabled(Handle:convar, const String:oldValue[], const String:newValue[])
{
if (GetConVarBool(h_MobControlEnabled)==false) MobControl_Disable();
    else                                     MobControl_Enable();
}
public ConVarIncludeBots(Handle:convar, const String:oldValue[], const String:newValue[])
{
	IncludeBots = GetConVarBool(h_IncludeBots);
}

MobControl_Enable()
{
if (Enabled) return;
	HookEvent("player_team", Event_ChangeTeam, EventHookMode_Pre);
	HookConVarChange(h_IncludeBots, ConVarIncludeBots);
	HookConVarChange(h_TankHealthBonusEnabled, ConVarTankHealthBonusEnabled);
	IncludeBots = GetConVarBool(h_IncludeBots);
	TankHealthBonusEnabled = GetConVarBool(h_TankHealthBonusEnabled);
	Enabled = true;
	return;
}

MobControl_Disable()
{
if (!Enabled) return;
	UnhookEvent("player_team", Event_ChangeTeam, EventHookMode_Pre);
	UnhookConVarChange(h_IncludeBots, ConVarIncludeBots);
	UnhookConVarChange(h_TankHealthBonusEnabled, ConVarTankHealthBonusEnabled);
	Enabled = false;
	return;
}

public ConVarTankHealthBonusEnabled(Handle:convar, const String:oldValue[], const String:newValue[])
{
	TankHealthBonusEnabled = GetConVarBool(h_TankHealthBonusEnabled);
}

UnCheatAndChangeConVar()
{
    
	for (new i = 0; i < sizeof(MobArray); i++)
	{
		new value;
		new String:var[256];
		GetConVarName(MobArray[i], var, 256);
		D = GetConVarInt(MobArray[i]);
		new flags = GetCommandFlags(var);
		SetCommandFlags(var, flags & ~FCVAR_CHEAT);
			if (Plus)
				{
					value = D + GetConVarInt(ZombiesPerSurvivor);
				}
			if (!Plus)
				{
					value = D - GetConVarInt(ZombiesPerSurvivor);
				}
					SetConVarInt(MobArray[i], value, false, false);
					SetCommandFlags(var, flags);
	}
	if (TankHealthBonusEnabled)
		{
			new flags2 = GetCommandFlags("z_tank_health");
			SetCommandFlags("z_tank_health", flags2 & ~FCVAR_CHEAT);
				if (Plus) {
					SetConVarInt(TankHealth, GetConVarInt(TankHealth) + GetConVarInt(TankHealthBonus));
					}
				if (!Plus) {
					SetConVarInt(TankHealth, GetConVarInt(TankHealth) - GetConVarInt(TankHealthBonus));
					}
			SetCommandFlags("z_tank_health", flags2);
		}
	
}

public Action:Event_ChangeTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (Enabled)
		{
		new t = GetEventInt(Handle:event, "team");
		new o = GetEventInt(Handle:event, "oldteam");
		new bool:b = GetEventBool(Handle:event, "isbot");
		new bool:d = GetEventBool(Handle:event, "disconnect");

					if (b==true)
						{
							if (IncludeBots)
							{
								if (t == 2)
								{
								Plus = true;
								UnCheatAndChangeConVar();
								}
								if (t != 2 && o == 2 && !d)
								{
								Plus = false;
								UnCheatAndChangeConVar();
								}
								if (d && o == 2)
								{
								Plus = false;
								UnCheatAndChangeConVar();
								}
							}
							else 
							{
								if (d && o == 2)
								{
								Plus = false;
								UnCheatAndChangeConVar();
								}
							return Plugin_Continue;
							}
						}
						else
						{
								if (t == 2)
								{
								Plus = true;
								UnCheatAndChangeConVar();
								}
								if (t != 2 && o == 2 && !d)
								{
								Plus = false;
								UnCheatAndChangeConVar();
								}
								if (d && o == 2)
								{
								Plus = false;
								UnCheatAndChangeConVar();
											
								}
						}
		}				
return Plugin_Handled;
}	