//
// SourceMod Script
//
// Developed by <eVa>Dog
// October 2008
// http://www.theville.org
//

//
// DESCRIPTION:
// This plugin is a port of my Flamethrower plugin
// originally created using EventScripts

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.102"

#define ADMIN_LEVEL ADMFLAG_SLAY

new flameAmount[MAXPLAYERS+1];
new g_flameEnabled[MAXPLAYERS+1];

new Handle:g_Cvar_FlameAmount = INVALID_HANDLE;
new Handle:g_Cvar_Admins = INVALID_HANDLE;
new Handle:g_Cvar_Enable = INVALID_HANDLE;
new Handle:g_Cvar_Delay  = INVALID_HANDLE;
new Handle:g_Cvar_SpawnDelay  = INVALID_HANDLE;

new String:GameName[64];

public Plugin:myinfo = 
{
	name = "Flamethrower",
	author = "<eVa>Dog",
	description = "Flamethrower plugin",
	version = PLUGIN_VERSION,
	url = "http://www.theville.org"
};

public OnPluginStart()
{
	RegConsoleCmd("sm_flame", Flame, " -  Use the flamethrower");
	
	CreateConVar("sm_flame_version", PLUGIN_VERSION, "Version of Flamethrower on this server", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_Cvar_FlameAmount = CreateConVar("sm_flame_amount", "5", " Number of flamethrower cells per player at spawn", FCVAR_PLUGIN);
	g_Cvar_Admins      = CreateConVar("sm_flame_admins", "0", " Allow Admins only to use the Flamethrower", FCVAR_PLUGIN);
	g_Cvar_Enable      = CreateConVar("sm_flame_enabled", "1", " Enable/Disable the Flamethrower plugin", FCVAR_PLUGIN);
	g_Cvar_Delay       = CreateConVar("sm_flame_delay", "3.0", " Delay between flamethrower blasts", FCVAR_PLUGIN);
	g_Cvar_SpawnDelay  = CreateConVar("sm_flame_spawndelay", "5.0", " Delay before flamethrower is available (0.0 disables)", FCVAR_PLUGIN);
	
	GetGameFolderName(GameName, sizeof(GameName));
}

public OnMapStart()
{
	if (GetConVarInt(g_Cvar_Enable))
	{		
		HookEvent("player_spawn", PlayerSpawnEvent);
		HookEvent("player_death", PlayerDeathEvent);
		
		PrecacheSound("weapons/rpg/rocketfire1.wav", true);
		PrecacheSound("weapons/ar2/ar2_empty.wav", true);
	}
}

public OnEventShutdown()
{
	UnhookEvent("player_spawn", PlayerSpawnEvent);
	UnhookEvent("player_death", PlayerDeathEvent);
}

public PlayerSpawnEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(g_Cvar_Enable))
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		
		if (GetConVarInt(g_Cvar_Admins) == 1)
		{
			if (GetUserFlagBits(client) & ADMIN_LEVEL)
			{
				flameAmount[client] = GetConVarInt(g_Cvar_FlameAmount);
			}
			else
			{
				flameAmount[client] = 0;
			}
		}
		else
		{
			flameAmount[client] = GetConVarInt(g_Cvar_FlameAmount);
		}
		
		if (GetConVarFloat(g_Cvar_SpawnDelay) > 0.0)
		{
			CreateTimer(GetConVarFloat(g_Cvar_SpawnDelay), SetFlame, client);
		}
		else
		{
			g_flameEnabled[client] = 1;
		}
	}
}

public PlayerDeathEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(g_Cvar_Enable))
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		
		if (client > 0 && IsClientInGame(client))
		{
			flameAmount[client] = 0;
			g_flameEnabled[client] = 0;
			ExtinguishEntity(client);
		}
	}
}

public Action:SetFlame(Handle:timer, any:client)
{
	g_flameEnabled[client] = 1;
}

public Action:Flame(client, args)
{
	if (GetConVarInt(g_Cvar_Enable))
	{
		if (client)
		{ 
			if (IsPlayerAlive(client))
			{
				if (flameAmount[client] > 0)
				{
					if (g_flameEnabled[client])
					{						
						new Float:vAngles[3];
						new Float:vOrigin[3];
						new Float:aOrigin[3];
						new Float:EndPoint[3];
						new Float:AnglesVec[3];
						new Float:targetOrigin[3];
						new Float:pos[3];
						
						flameAmount[client]--;
						PrintToChat(client, "[SM] Number of cells left: %i", flameAmount[client]);
						
						new String:tName[128];
						
						new Float:distance = 600.0;
						
						GetClientEyePosition(client, vOrigin);
						GetClientAbsOrigin(client, aOrigin);
						GetClientEyeAngles(client, vAngles);
						
						// A little routine developed by Sollie and Crimson to find the endpoint of a traceray
						// Very useful!
						GetAngleVectors(vAngles, AnglesVec, NULL_VECTOR, NULL_VECTOR);
						
						EndPoint[0] = vOrigin[0] + (AnglesVec[0]*distance);
						EndPoint[1] = vOrigin[1] + (AnglesVec[1]*distance);
						EndPoint[2] = vOrigin[2] + (AnglesVec[2]*distance);
												
						new Handle:trace = TR_TraceRayFilterEx(vOrigin, EndPoint, MASK_SHOT, RayType_EndPoint, TraceEntityFilterPlayer, client)	;
						
						// Ident the player
						Format(tName, sizeof(tName), "target%i", client);
						DispatchKeyValue(client, "targetname", tName);
						
						EmitSoundToClient(client, "weapons/rpg/rocketfire1.wav", _, _, _, _, 0.7);
						
						// Create the Flame
						new String:flame_name[128];
						Format(flame_name, sizeof(flame_name), "Flame%i", client);
						new flame = CreateEntityByName("env_steam");
						DispatchKeyValue(flame,"targetname", flame_name);
						DispatchKeyValue(flame, "parentname", tName);
						DispatchKeyValue(flame,"SpawnFlags", "1");
						DispatchKeyValue(flame,"Type", "0");
						DispatchKeyValue(flame,"InitialState", "1");
						DispatchKeyValue(flame,"Spreadspeed", "10");
						DispatchKeyValue(flame,"Speed", "800");
						DispatchKeyValue(flame,"Startsize", "10");
						DispatchKeyValue(flame,"EndSize", "250");
						DispatchKeyValue(flame,"Rate", "15");
						DispatchKeyValue(flame,"JetLength", "400");
						DispatchKeyValue(flame,"RenderColor", "180 71 8");
						DispatchKeyValue(flame,"RenderAmt", "180");
						DispatchSpawn(flame);
						TeleportEntity(flame, aOrigin, AnglesVec, NULL_VECTOR);
						SetVariantString(tName);
						AcceptEntityInput(flame, "SetParent", flame, flame, 0);
						
						if (StrEqual(GameName, "dod") || StrEqual(GameName, "insurgency"))
						{
							SetVariantString("anim_attachment_RH");
						}
						else
						{
							SetVariantString("forward");
						}
						
						AcceptEntityInput(flame, "SetParentAttachment", flame, flame, 0);
						AcceptEntityInput(flame, "TurnOn");
						
						// Create the Heat Plasma
						new String:flame_name2[128];
						Format(flame_name2, sizeof(flame_name2), "Flame2%i", client);
						new flame2 = CreateEntityByName("env_steam");
						DispatchKeyValue(flame2,"targetname", flame_name2);
						DispatchKeyValue(flame2, "parentname", tName);
						DispatchKeyValue(flame2,"SpawnFlags", "1");
						DispatchKeyValue(flame2,"Type", "1");
						DispatchKeyValue(flame2,"InitialState", "1");
						DispatchKeyValue(flame2,"Spreadspeed", "10");
						DispatchKeyValue(flame2,"Speed", "600");
						DispatchKeyValue(flame2,"Startsize", "50");
						DispatchKeyValue(flame2,"EndSize", "400");
						DispatchKeyValue(flame2,"Rate", "10");
						DispatchKeyValue(flame2,"JetLength", "500");
						DispatchSpawn(flame2);
						TeleportEntity(flame2, aOrigin, AnglesVec, NULL_VECTOR);
						SetVariantString(tName);
						AcceptEntityInput(flame2, "SetParent", flame2, flame2, 0);
						
						if (StrEqual(GameName, "dod") || StrEqual(GameName, "insurgency"))
						{
							SetVariantString("anim_attachment_RH");
						}
						else
						{
							SetVariantString("forward");
						}
						
						AcceptEntityInput(flame2, "SetParentAttachment", flame2, flame2, 0);
						AcceptEntityInput(flame2, "TurnOn");
						
						new Handle:flamedata = CreateDataPack();
						CreateTimer(1.0, KillFlame, flamedata);
						WritePackCell(flamedata, flame);
						WritePackCell(flamedata, flame2);
								
						if(TR_DidHit(trace))
						{							
							TR_GetEndPosition(pos, trace);
						}
						CloseHandle(trace);
												
						for (new i = 1; i <= GetMaxClients(); i++)
						{
							if (i == client)
								continue;
							
							if (IsClientInGame(i) && IsPlayerAlive(i))
							{
								new ff_on = GetConVarInt(FindConVar("mp_friendlyfire"));
								
								if (ff_on)
								{
									GetClientAbsOrigin(i, targetOrigin);
									
									if ((GetVectorDistance(targetOrigin, pos) < 200)  && (GetVectorDistance(targetOrigin, vOrigin) < 600))
									{
										IgniteEntity(i, 5.0, false, 1.5, false);
									}
								}
								else
								{
									if (GetClientTeam(i) == GetClientTeam(client))
										continue;
										
									GetClientAbsOrigin(i, targetOrigin);
									
									if ((GetVectorDistance(targetOrigin, pos) < 200)  && (GetVectorDistance(targetOrigin, vOrigin) < 600))
									{
										IgniteEntity(i, 5.0, false, 1.5, false);
									}
								}
							}
						}
					}
					else
					{
						PrintToChat(client, "[SM] Flamethrower recharging.  Please wait....");
					}
				}
				else
				{
					PrintToChat(client, "[SM] Flamethrower out of fuel");
					EmitSoundToClient(client, "weapons/ar2/ar2_empty.wav", _, _, _, _, 0.8);
				}
			}
		}
	}
	
	g_flameEnabled[client] = 0;
	CreateTimer(GetConVarFloat(g_Cvar_Delay), SetFlame, client);
	return Plugin_Handled;
}

public bool:TraceEntityFilterPlayer(entity, contentsMask, any:data)
{
	return data != entity;
} 

public Action:KillFlame(Handle:timer, Handle:flamedata)
{
	ResetPack(flamedata);
	new ent1 = ReadPackCell(flamedata);
	new ent2 = ReadPackCell(flamedata);
	CloseHandle(flamedata);
	
	new String:classname[256];
	
	if (IsValidEntity(ent1))
    {
		AcceptEntityInput(ent1, "TurnOff");
		GetEdictClassname(ent1, classname, sizeof(classname));
		if (StrEqual(classname, "env_steam", false))
        {
            RemoveEdict(ent1);
        }
    }
	
	if (IsValidEntity(ent2))
    {
		AcceptEntityInput(ent2, "TurnOff");
		GetEdictClassname(ent2, classname, sizeof(classname));
		if (StrEqual(classname, "env_steam", false))
        {
            RemoveEdict(ent2);
        }
    }
}