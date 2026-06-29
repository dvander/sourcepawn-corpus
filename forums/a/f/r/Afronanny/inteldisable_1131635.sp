#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION	"0.2.1"

new Handle:hCvarEnabled;
new Handle:hCvarMinimumPlayers;
new Handle:hCvarDisableOverride;

new iClientCount;
new iMinimumClientCount;

new bool:bIsEnabled;

public Plugin:myinfo = 
{
	name = "Disable the Intelligence",
	author = "Afronanny",
	description = "Disable the Intelligence until player count reaches a certain number",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=122604"
}

public OnPluginStart()
{
	
	hCvarEnabled = CreateConVar("sm_intel_enabled", "1", "Enable the plugin", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hCvarMinimumPlayers = CreateConVar("sm_intel_minimumplayers", "6", "Minimum amount of players before intelligence is enabled", FCVAR_PLUGIN, true, 0.0, true, float(MaxClients));
	hCvarDisableOverride = CreateConVar("sm_intel_disabled", "0", "Override the system and disable no matter the playercount", FCVAR_PLUGIN);
	
	HookConVarChange(hCvarDisableOverride, ConVarChanged_Override);
	HookConVarChange(hCvarEnabled, ConVarChanged_Enabled);
	HookConVarChange(hCvarMinimumPlayers, ConVarChanged_MinimumClients);
	
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i))
			iClientCount++;
	}
	
	AutoExecConfig(true);
}
public OnMapStart()
{
	DoMinimumClientCheck();
}
public OnClientPutInServer(client)
{
	iClientCount++;
	if (bIsEnabled)
		DoMinimumClientCheck();
}

public OnClientDisconnect(client)
{
	//make sure we don't go below zero
	if (iClientCount > 0)
		iClientCount--;
	if (bIsEnabled)
		DoMinimumClientCheck();
}

public ConVarChanged_Override(Handle:convar, const String:oldValue[], const String:newValue[])
{
	GetConVarBool(convar);
	if (GetConVarBool(convar))
	{
		DisableAllFlags();
		bIsEnabled = false;
	} else {
		DoMinimumClientCheck();
		bIsEnabled = true;
	}
	
}

public ConVarChanged_Enabled(Handle:convar, const String:oldValue[], const String:newValue[])
{
	bIsEnabled = GetConVarBool(convar);
	if (!bIsEnabled)
		EnableAllFlags();
}

public ConVarChanged_MinimumClients(Handle:convar, const String:oldValue[], const String:newValue[])
{
	iMinimumClientCount = StringToInt(newValue);
}

public EnableAllFlags()
{
	new ent;
	while ((ent = FindEntityByClassname(-1, "item_teamflag")) != 1)
	{
		AcceptEntityInput(ent, "Enable");
	}
}

public DisableAllFlags()
{
	new ent;
	while ((ent = FindEntityByClassname(-1, "item_teamflag")) != 1)
	{
		AcceptEntityInput(ent, "Disable");
	}
}

public DoMinimumClientCheck()
{
	new ent;
	if (iClientCount < iMinimumClientCount)
	{
		while ((ent = FindEntityByClassname(-1, "item_teamflag")) != 1)
		{
			AcceptEntityInput(ent, "Disable");
		}
	} else {
		while ((ent = FindEntityByClassname(-1, "item_teamflag")) != 1)
		{
			AcceptEntityInput(ent, "Disable");
		}
	}
}

