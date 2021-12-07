#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
//#include <zr_tools>
#include <zombieplague>

#define PLUGIN_VERSION "2.0.2"

#define FLASHLIGHT_ONOFF "items/flashlight1.wav"

#define EF_DIMLIGHT 4

new pEntity[MAXPLAYERS+1] = {-1, ...};
new bool:Light[MAXPLAYERS+1];
new bool:flash[MAXPLAYERS+1];

new Handle:HumansFlashLights, bool:humanflash,
Handle:HumansLightsOff, bool:humanoff;

public Plugin:myinfo = {
	name = "[ZR] Lights",
	author = "FrozDark (HLModders LLC)",
	description = "Lights",
	version = PLUGIN_VERSION,
	url = "http://www.hlmod.ru"
};

public OnPluginStart()
{
	CreateConVar("zr_lights_version", PLUGIN_VERSION, "The plugin's version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_CHEAT|FCVAR_DONTRECORD);
	HumansFlashLights = CreateConVar("zr_flashlights_humans", "1", "Turn on/off the humans' flashlights");
	HumansLightsOff = CreateConVar("zr_lights_humans_off", "1", "Allow humans to turn on/off their light by button \"N\"(console - [B]nightvision[/B])");
	
	humanflash = GetConVarBool(HumansFlashLights);
	humanoff = GetConVarBool(HumansLightsOff);
	
	HookConVarChange(HumansFlashLights, ConVarChanges);
	HookConVarChange(HumansLightsOff, ConVarChanges);
	
	AutoExecConfig(true, "zombiereloaded/lights");
	
	AddCommandListener(Command_Light, "nightvision");
	
	HookEvent("round_start", OnRoundStart);
	HookEvent("player_spawn", OnPlayerSpawn);
	HookEvent("player_death", OnPlayerDeath);
}

public OnMapEnd()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		OnClientDisconnect_Post(i);
	}
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (!IsPlayerAlive(client))
	{
		if (flash[client])
		{
			flash[client] = false;
		}
		return Plugin_Continue;
	}
	new bool:restrict = ZP_IsPlayerZombie(int clientIndex) || (!humanflash && ZP_IsPlayerHuman(int clientIndex)));
	switch (impulse)
	{
		case 100 :
		{
			if (restrict)
			{
				if (!flash[client])
				{
					impulse = 0;
				}
			}
			else
			{
				flash[client] = !flash[client];
			}
		}
	}
	if (flash[client] && restrict)
	{
		impulse = 100;
		flash[client] = false;
	}
	return Plugin_Continue;
}

public Action:Command_Light(client, const String:command[], args)
{
	if (!IsPlayerAlive(client) || ZP_IsPlayerZombie(client) || !humanoff || pEntity[client] == -1 || !IsValidEdict(pEntity[client]))
	{
		return Plugin_Handled;
	}
		
	if (Light[client])
	{
		AcceptEntityInput(pEntity[client], "TurnOff");
	}
	else
	{
		AcceptEntityInput(pEntity[client], "TurnOn");
	}
	Light[client] = !Light[client];
	EmitSoundToAll(FLASHLIGHT_ONOFF, client, SNDCHAN_ITEM);
	
	return Plugin_Handled;
}
	
public ConVarChanges(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == HumansFlashLights)
		humanflash = bool:StringToInt(newValue); else
	if (convar == HumansLightsOff)
		humanoff = bool:StringToInt(newValue);
}
	
public ZP_OnClientInfected(int clientIndex, int attackerIndex)
{
	if (!IsFakeClient(client) && pEntity[client] > MaxClients && IsValidEdict(pEntity[client]))
	{
		if (DispatchDistanceAndColor(client))
		{
			AcceptEntityInput(pEntity[client], "TurnOn");
			Light[client] = true;
		}
		else
		{
			AcceptEntityInput(pEntity[client], "TurnOff");
		}
	}
}

public ZP_IsPlayerHuman(int clientIndex)
{
	if (pEntity[client] > MaxClients && IsValidEdict(pEntity[client]))
	{
		if (DispatchDistanceAndColor(client))
		{
			Light[client] = true;
			AcceptEntityInput(pEntity[client], "TurnOn");
		}
		else
		{
			AcceptEntityInput(pEntity[client], "TurnOff");
		}
	}
}

public OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			OnClientDisconnect_Post(i);
			flash[i] = false;
			CreateLight(i);
		}
	}
}

public OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsPlayerAlive(client) && (2 <= GetClientTeam(client) <= 3))
	{
		flash[client] = false;
		if (pEntity[client] == -1 && !IsValidEdict(pEntity[client]))
		{
			CreateLight(client);
		}
		else
		{
			DispatchDistanceAndColor(client);
			AcceptEntityInput(pEntity[client], "TurnOn");
			Light[client] = true;
		}
	}
}

public OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (pEntity[client] > MaxClients && IsValidEdict(pEntity[client]))
	{
		AcceptEntityInput(pEntity[client], "TurnOff");
		Light[client] = false;
	}
}

public OnClientDisconnect_Post(client)
{
	Light[client] = false;
	SDKUnhook(pEntity[client], SDKHook_SetTransmit, OnTransmitEntity);
	if (pEntity[client] > MaxClients && IsValidEdict(pEntity[client]))
	{
		AcceptEntityInput(pEntity[client], "kill");
	}
	pEntity[client] = -1;
}

public Action:OnTransmitEntity(entity, client)
{
	if (!IsPlayerAlive(client) || pEntity[client] == entity || ZP_IsPlayerZombie(client))
	{
		return Plugin_Continue;
	}
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && ZR_IsClientHuman(i) && pEntity[i] == entity)
		{
			return Plugin_Continue;
		}
	}
	
	return Plugin_Handled;
}

CreateLight(client)
{
	decl Float:ClientsPos[3];
	GetClientAbsOrigin(client, ClientsPos);
	//ClientsPos[2] += 10.0;
	
	decl String:tName[128];
	Format(tName, sizeof(tName), "target_%i", client);
	DispatchKeyValue(client, "targetname", tName);
	
	decl String:light_name[128];
	Format(light_name, sizeof(light_name), "light_%i", client);
	
	pEntity[client] = CreateEntityByName("light_dynamic");
	DispatchKeyValue(pEntity[client],"targetname", light_name);
	DispatchKeyValue(pEntity[client], "parentname", tName);
	DispatchKeyValue(pEntity[client], "inner_cone", "0");
	DispatchKeyValue(pEntity[client], "cone", "80");
	DispatchKeyValue(pEntity[client], "brightness", "0");
	DispatchKeyValueFloat(pEntity[client], "spotlight_radius", 150.0);
	DispatchKeyValue(pEntity[client], "pitch", "90");
	DispatchKeyValue(pEntity[client], "style", "5");
	DispatchSpawn(pEntity[client]);
	
	SDKHook(pEntity[client], SDKHook_SetTransmit, OnTransmitEntity);
	
	TeleportEntity(pEntity[client], ClientsPos, NULL_VECTOR, NULL_VECTOR);
	
	SetVariantString(tName);
	AcceptEntityInput(pEntity[client], "SetParent", pEntity[client], pEntity[client], 0);
	
	SetEntProp(pEntity[client], Prop_Data, "m_Flags", 2);
	SetEntPropEnt(pEntity[client], Prop_Data, "m_hOwnerEntity", client);
	
	if (DispatchDistanceAndColor(client))
	{
		AcceptEntityInput(pEntity[client], "TurnOn");
		Light[client] = true;
	}
	else
	{
		AcceptEntityInput(pEntity[client], "TurnOff");
		Light[client] = false;
	}
}

bool:DispatchDistanceAndColor(client)
{
	new Float:distance = ZRT_GetClientAttributeValueFloat(client, "light_distance", 0.0);
	
	decl String:color[24];
	ZRT_GetClientAttributeString(client, "light_color", color, sizeof(color), "255 255 255 255");
	
	DispatchKeyValueFloat(pEntity[client], "distance", distance);
	DispatchKeyValue(pEntity[client], "_light", color);
	
	return distance != 0.0;
}