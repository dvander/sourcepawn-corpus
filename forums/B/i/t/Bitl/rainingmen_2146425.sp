/* Plugin Template generated by Pawn Studio */

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION			"0.1"

#define CVAR_ENABLE				0
#define CVAR_RADIUS				1
#define CVAR_HEIGHT				2
#define CVAR_BURN				3
#define CVAR_ELEC				4
#define CVAR_FREQUENCY			5
#define CVAR_REMOVE				6
#define CVAR_VERSION			7
#define CVAR_MESSAGE			8
#define CVAR_GOLD				9
#define CVAR_ICE				10
#define CVAR_TEAM				11
#define CVAR_CLASS				12
#define NUM_CVARS				13

new Handle:g_cvars[NUM_CVARS] = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "It's Raining Men",
	author = "Jindo (Modified by Bitl)",
	description = "Spawn ragdolls from the sky based on a target.",
	version = PLUGIN_VERSION,
	url = "http://www.topaz-games.com/"
}

public OnPluginStart()
{
	RegAdminCmd("sm_rainmen", cRainMenOn, ADMFLAG_ROOT);
	RegAdminCmd("sm_rm_panic", cPanicButton, ADMFLAG_ROOT);
	RegAdminCmd("sm_rm_stop", cStopRM, ADMFLAG_ROOT);
	// generic cvars
	g_cvars[CVAR_VERSION] = CreateConVar("rainingmen_version", PLUGIN_VERSION, "Current version of the plugin.", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_cvars[CVAR_MESSAGE] = CreateConVar("rm_message_enable", "1", "Disable the \"It's Raining Men\" message.", FCVAR_PLUGIN);
	// map-specific cvars
	g_cvars[CVAR_ENABLE] = CreateConVar("sm_rainmen_enable", "1", "Enable the plugin", FCVAR_PLUGIN);
	g_cvars[CVAR_RADIUS] = CreateConVar("sm_rainmen_radius", "100.0", "Radius around the player to spawn ragdolls.", FCVAR_PLUGIN);
	g_cvars[CVAR_HEIGHT] = CreateConVar("sm_rainmen_height", "500.0", "Height above the player to spawn ragdolls.", FCVAR_PLUGIN);
	g_cvars[CVAR_BURN] = CreateConVar("sm_rainmen_burn", "2", "0 = no burn, 1 = all burn, 2 = random", FCVAR_PLUGIN);
	g_cvars[CVAR_ELEC] = CreateConVar("sm_rainmen_elec", "0", "0 = no electrocuted, 1 = all electrocuted, 2 = random", FCVAR_PLUGIN);
	g_cvars[CVAR_FREQUENCY] = CreateConVar("sm_rainmen_frequency", "1", "Frequency to spawn the ragdolls (higher than 10 may be unsafe)", FCVAR_PLUGIN);
	g_cvars[CVAR_REMOVE] = CreateConVar("sm_rainmen_remove", "6.0", "Time (in seconds) the ragdoll lasts before it is removed.", FCVAR_PLUGIN);
	g_cvars[CVAR_GOLD] = CreateConVar("sm_rainmen_gold", "0", "0 = no gold 1 = all gold, 2 = random", FCVAR_PLUGIN);
	g_cvars[CVAR_ICE] = CreateConVar("sm_rainmen_ice", "0", "0 = no ice, 1 = all ice, 2 = random", FCVAR_PLUGIN);
	g_cvars[CVAR_TEAM] = CreateConVar("sm_rainmen_team", "0", "0 = random team 1 = red, 2 = blue", FCVAR_PLUGIN);
	g_cvars[CVAR_CLASS] = CreateConVar("sm_rainmen_class", "0", "0 = random class, 1 = Scout, 2 = Soldier, 3 = Pyro, 4 = Demoman, 5 = Heavy, 6 = Engineer, 7 = Medic, 8 = Sniper, 9 = Spy", FCVAR_PLUGIN);
	AutoExecConfig(true, "plugin.rainingmen");
}

public Action:cPanicButton(client, args)
{
	new ent = -1;
	while ((ent = FindEntityByClassname(ent, "tf_ragdoll")) != -1)
	{
		AcceptEntityInput(ent, "Kill");
	}
	SetConVarInt(g_cvars[CVAR_ENABLE], 0);
	CreateTimer(5.0, tResetValue);
}

public Action:cStopRM(client, args)
{
	SetConVarInt(g_cvars[CVAR_ENABLE], 0);
	CreateTimer(2.0, tResetValue);
}

public Action:cRainMenOn(client, args)
{
	
	new enableMessage = GetConVarBool(g_cvars[CVAR_MESSAGE]);
	if (enableMessage)
	{
		PrintCenterTextAll("It's Raining Men!");
	}
	
	if (args > 0)
	{
		new String:player[64];
		GetCmdArg(1, player, 64);
		new String:target_name[MAX_TARGET_LENGTH]
		new target_list[MAXPLAYERS], target_count
		new bool:tn_is_ml
	 
		if ((target_count = ProcessTargetString(
				player,
				client,
				target_list,
				MAXPLAYERS,
				COMMAND_FILTER_CONNECTED,
				target_name,
				sizeof(target_name),
				tn_is_ml)) <= 0)
		{
			
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
			
		}

		for(new i=0; i<target_count; i++)
		{
			
			CreateTimer(1.5, tSpawnRD, target_list[i]);
			
		}
		return Plugin_Handled;
	}
	
	if (IsValidClient(client))
	{
		CreateTimer(1.5, tSpawnRD, client);
	}
	
	return Plugin_Handled;
	
}

public Action:tResetValue(Handle:timer, any:client)
{
	SetConVarInt(g_cvars[CVAR_ENABLE], 1);
}

public Action:tSpawnRD(Handle:timer, any:client)
{
	
	if (!IsValidClient(client))
	{
		return Plugin_Handled;
	}
	
	new Float:remove = GetConVarFloat(g_cvars[CVAR_REMOVE]);
	new Float:radius = GetConVarFloat(g_cvars[CVAR_RADIUS]);
	new Float:height = GetConVarFloat(g_cvars[CVAR_HEIGHT]);
	new Float:freq = GetConVarFloat(g_cvars[CVAR_FREQUENCY]);
	new Float:choices[2];
	choices[0] = GetRandomFloat(-1.0, 1.0)*radius;
	choices[1] = GetRandomFloat(-1.0, 1.0)*radius;
	new burn = GetConVarInt(g_cvars[CVAR_BURN]);
	new elec = GetConVarInt(g_cvars[CVAR_ELEC]);
	new gold = GetConVarInt(g_cvars[CVAR_GOLD]);
	new ice = GetConVarInt(g_cvars[CVAR_ICE]);
	new class = GetConVarInt(g_cvars[CVAR_CLASS]);
	new team = GetConVarInt(g_cvars[CVAR_TEAM]);
	
	new ent = CreateEntityByName("tf_ragdoll");
	new Float:vOrigin[3];
	
	GetClientAbsOrigin(client, vOrigin);
	
	vOrigin[0] += choices[0];
	vOrigin[1] += choices[1];
	vOrigin[2] += height;
	
	SetEntPropVector(ent, Prop_Send, "m_vecRagdollOrigin", vOrigin);
	
	if (team == 1)
	{
		SetEntProp(ent, Prop_Send, "m_iTeam", 2);
	}
	else  if (team == 2)
	{
		SetEntProp(ent, Prop_Send, "m_iTeam", 3);
	}
	else
	{
		SetEntProp(ent, Prop_Send, "m_iTeam", GetRandomInt(2, 3));
	}
	
	if (class == 1)
	{
		SetEntProp(ent, Prop_Send, "m_iClass", 1);
	}
	else if (class == 2)
	{
		SetEntProp(ent, Prop_Send, "m_iClass", 2);
	}
	else if (class == 3)
	{
		SetEntProp(ent, Prop_Send, "m_iClass", 3);
	}
	else if (class == 4)
	{
		SetEntProp(ent, Prop_Send, "m_iClass", 4);
	}
	else if (class == 5)
	{
		SetEntProp(ent, Prop_Send, "m_iClass", 5);
	}
	else if (class == 6)
	{
		SetEntProp(ent, Prop_Send, "m_iClass", 6);
	}
	else if (class == 7)
	{
		SetEntProp(ent, Prop_Send, "m_iClass", 7);
	}
	else if (class == 8)
	{
		SetEntProp(ent, Prop_Send, "m_iClass", 8);
	}
	else if (class == 9)
	{
		SetEntProp(ent, Prop_Send, "m_iClass", 9);
	}
	else
	{
		SetEntProp(ent, Prop_Send, "m_iClass", GetRandomInt(1, 9));
	}
	
	if (burn > 1)
	{
		SetEntProp(ent, Prop_Send, "m_bBurning", GetRandomInt(0, 1));
	} 
	else
	{
		SetEntProp(ent, Prop_Send, "m_bBurning", burn);
	}
	
	if (elec > 1)
	{
		SetEntProp(ent, Prop_Send, "m_bElectrocuted", GetRandomInt(0, 1));
	} 
	else
	{
		SetEntProp(ent, Prop_Send, "m_bElectrocuted", elec);
	}
	
	if (gold > 1)
	{
		SetEntProp(ent, Prop_Send, "m_bGoldRagdoll", GetRandomInt(0, 1));
	} 
	else
	{
		SetEntProp(ent, Prop_Send, "m_bGoldRagdoll", gold);
	}
	
	if (ice > 1)
	{
		SetEntProp(ent, Prop_Send, "m_bIceRagdoll", GetRandomInt(0, 1));
	} 
	else
	{
		SetEntProp(ent, Prop_Send, "m_bIceRagdoll", ice);
	}
	
	CreateTimer(remove, tRemoveRD, ent);
	
	if (GetConVarBool(g_cvars[CVAR_ENABLE]))
	{
		if (IsValidClient(client))
		{
			CreateTimer(1.0/freq, tSpawnRD, client);
		}
	}
	
	return Plugin_Handled;
}

public Action:tRemoveRD(Handle:timer, any:ent)
{
	AcceptEntityInput(ent, "Kill");
}

stock IsValidClient(client)
{
	if (client == 0)
	{
		return false;
	}
	if (!IsClientConnected(client))
	{
		return false;
	}
	if (!IsClientInGame(client))
	{
		return false;
	}
	if (!IsPlayerAlive(client))
	{
		return false;
	}
	return true;
}