#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.0"
new Handle:gCvarRocket;
new Handle:runspeed = INVALID_HANDLE;
new ammo_offset;
int VerifRun[MAXPLAYERS + 1] = 0;
new redColor[4] = {255, 25, 25, 150};
new greenColor[4] = {0, 255, 80, 150};

new g_BeamSprite;

static const String:g_szGrenadeTypes[][] =
{
	"rocket_bazooka",
	"rocket_pschreck",
};

public Plugin:myinfo = 
{
	name = "Rock n Speed Run for DoDS", 
	author = "Micmacx", 
	description = "Mode Rocket and Speed Run for DoDS", 
	version = PLUGIN_VERSION, 
	url = "https://dods.neyone.fr/"
};

public OnPluginStart()
{
	CreateConVar("dod_rock_n_speed_version", PLUGIN_VERSION, "DoD Weapon Manager Version", FCVAR_DONTRECORD | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
	gCvarRocket = CreateConVar("dod_rock_n_speed_run", "0", " Enable/Disable Rocket", FCVAR_NOTIFY);
	runspeed = CreateConVar("sm_dods_runspeed", "1.2", "Speed when RunSpeed is enabled", FCVAR_NOTIFY, true, 0.8, true, 2.0);
	HookEvent("player_spawn", SpawnEvent);
	HookEvent("player_death", DeathEvent);
	AutoExecConfig(true, "dod_rock_n_speed_run", "dod_rock_n_speed_run");
	ammo_offset = FindSendPropInfo("CDODPlayer", "m_iAmmo");
}

public OnEventShutdown()
{
	UnhookEvent("player_spawn", SpawnEvent);
}

public OnMapStart()
{
	g_BeamSprite = PrecacheModel("materials/sprites/crystal_beam1.vmt");
}

public SpawnEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarBool(gCvarRocket))
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		RemoveWeapons(client);
		CreateTimer(0.1, GiveRocket, client);
	}
}

public DeathEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarBool(gCvarRocket))
	{
		new gagnant = GetClientOfUserId(GetEventInt(event, "attacker"));
		if (gagnant != 0)
		{
			if (IsClientInGame(gagnant))
			{
				if (IsPlayerAlive(gagnant))
				{
					decl String:weaponhold[32];
					GetClientWeapon(gagnant, weaponhold, 32);
					if ((StrEqual(weaponhold, "weapon_spade")) || (StrEqual(weaponhold, "weapon_amerknife")))
					{
						SetEntityHealth(gagnant, GetClientHealth(gagnant) + 25);
						PrintToChat(gagnant, "\x04[DoD Rock and Speed]\x01 25 hp de bonus");
					}
					else
					{
						SetEntityHealth(gagnant, GetClientHealth(gagnant) + 10);
						PrintToChat(gagnant, "\x04[DoD Rock and Speed]\x01 10 hp de bonus");
					}
				}
			}
		}
	}
}

public OnClientPutInServer(client)
{
	VerifRun[client] = 0;
}

public Action:RemoveWeapons(any:client)
{
	for (new i = 0; i < 4; i++)
	{
		new entity = GetPlayerWeaponSlot(client, i);
		
		if (entity != -1)
		{
			RemovePlayerItem(client, entity);
			RemoveEdict(entity);
		}
	}
}

public Action:GiveRocket(Handle:timer, any:client)
{
	if (IsClientInGame(client) && IsPlayerAlive(client))
	{
		new team = GetClientTeam(client);
		if (team == 2)
		{
			GivePlayerItem(client, "weapon_bazooka");
			SetEntData(client, ammo_offset + 48, 200, 4, true);
			GivePlayerItem(client, "weapon_amerknife");
		}
		else
		{
			if (team == 3)
			{
				GivePlayerItem(client, "weapon_pschreck");
				SetEntData(client, ammo_offset + 48, 200, 4, true);
				GivePlayerItem(client, "weapon_spade");
			}
		}
	}
	return Plugin_Handled;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (GetConVarBool(gCvarRocket))
	{
		if (buttons & IN_SPEED && buttons & IN_FORWARD)
		{
			decl String:weaponhold[32];
			GetClientWeapon(client, weaponhold, 32);
			if ((StrEqual(weaponhold, "weapon_spade")) || (StrEqual(weaponhold, "weapon_amerknife")))
			{
				SetEntPropFloat(client, Prop_Send, "m_flStamina", 1000.0);
				SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", GetConVarFloat(runspeed));
				VerifRun[client]++;
			}
		}
		else
		{
			if (VerifRun[client] > 0)
			{
				SetEntPropFloat(client, Prop_Send, "m_flStamina", 100.0);
				SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 1.0);
				VerifRun[client] = 0;
			}
		}
	}
}

public OnEntityCreated(iEntity, const String:szEntityName[])
{
	if(GetConVarBool(gCvarRocket))
	{
		for (new i = 0; i < sizeof(g_szGrenadeTypes); i++)
		{
			if (StrEqual(szEntityName, g_szGrenadeTypes[i]))
			{
				SDKHook(iEntity, SDKHook_Spawn, OnEntitySpawn);
				
				break;
			}
		}
	}	
}

public OnEntitySpawn(iEntity)
{
	decl String:Classname[256];
	GetEdictClassname(iEntity, Classname, sizeof(Classname));
	
	if(GetConVarBool(gCvarRocket))
	{
		if(StrEqual(Classname, "rocket_bazooka", false))
		{
			TE_SetupBeamFollow(iEntity, g_BeamSprite,	0, Float:2.0, Float:10.0, Float:10.0, 10, greenColor);
			TE_SendToAll();
		}
		else if(StrEqual(Classname, "rocket_pschreck", false))
		{
			TE_SetupBeamFollow(iEntity, g_BeamSprite,	0, Float:2.0, Float:10.0, Float:10.0, 10, redColor);
			TE_SendToAll();
		}
	}
	
}