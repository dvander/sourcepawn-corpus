#define PLUGIN_VERSION		"1.1.0"

#define CVAR_FLAGS          FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
#include <sourcemod>
#include <sdktools>
#include <left4downtown>

public Plugin:myinfo = {
	name = "L4D2 Finale UnBlocker",
	author = "AtomicStryker",
	description = "",
	version = PLUGIN_VERSION,
	url = ""
}

new Handle:MySDKCall = INVALID_HANDLE;
new bool:isFinale = false;
new bool:triggerRunning = false;

public OnPluginStart()
{
	PrepSDKCall();
	HookEntityOutput("func_button", "OnPressed", OnEntityOutput);
	
	HookEvent("finale_start", FinaleBegins);
	HookEvent("round_start", RoundStart);
	HookEvent("round_end", RoundEnd);
}

public Action:FinaleBegins(Handle:event, const String:name[], bool:dontBroadcast)
{
	LogAction(-1, -1, "[FUnlock] event finale_start");
	isFinale = true;
}

public Action:RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	isFinale = false;
	triggerRunning = false;
}

public Action:RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	isFinale = false;
	triggerRunning = false;
}

public OnEntityOutput(const String:name[], caller, activator, Float:delay)
{
	// PrintToChatAll("Output name: [%s], caller %i, activator %i, delay %f", name, caller, activator, delay);
	
	if (isFinale || triggerRunning) return;
	
	decl String:map[128];
	GetCurrentMap(map, sizeof(map));
	
	if (StrContains(map, "c12m5", false) != -1)
	{
		// c12m5: func_button OnPressed, delay 8
		if (StrEqual(name, "OnPressed"))
		{
			CreateTimer(9.0, StartFinaleDelayed);
			triggerRunning = true;
		}
	}
	
	else if (StrContains(map, "c3m4", false) != -1)
	{
		// c3m4: func_button OnPressed, delay 5
		if (StrEqual(name, "OnPressed"))
		{
			CreateTimer(6.0, StartFinaleDelayed);
			triggerRunning = true;
		}
	}
	
	else if (StrContains(map, "c8m5", false) != -1)
	{
		// c8m5: logic_choreographed_scene OnCompletion, no idea how long
		if (StrEqual(name, "OnPressed"))
		{
			// PrintToChatAll("Firing c8m5 finale timer, 20 seconds");
			CreateTimer(20.0, StartFinaleDelayed);
			triggerRunning = true;
		}
	}
	
	
	if (StrContains(map, "c10m5", false) != -1)
	{
		// c10m5: func_button OnPressed, delay 12 to unlock finale button (add 5?)
		if (StrEqual(name, "OnPressed"))
		{
			CreateTimer(17.0, StartFinaleDelayed);
			triggerRunning = true;
		}
	}
}

public Action:StartFinaleDelayed(Handle:timer)
{
	if (!isFinale)
	{
		TriggerFinale();
		LogAction(-1, -1, "[FUnlock] TriggerFinale()");
	}
}

public Action:StartFinaleRelayOnlyDelayed(Handle:timer)
{
	TriggerFinaleRelayOnly();
	LogAction(-1, -1, "[FUnlock] TriggerFinaleRelayOnly()");
}

public Action:teleportBack(Handle:timer, Handle:posdata)
{
	ResetPack(posdata);
	decl Float:position[3];
	new client = ReadPackCell(posdata);
	position[0] = ReadPackFloat(posdata);
	position[1] = ReadPackFloat(posdata);
	position[2] = ReadPackFloat(posdata);
	CloseHandle(posdata);
	TeleportEntity(client, position, NULL_VECTOR, NULL_VECTOR);
}

PrepSDKCall()
{
	new Handle:ConfigFile = LoadGameConfigFile("l4d2finaleunblocker");
	if (ConfigFile == INVALID_HANDLE)
	{
		SetFailState("Cant read l4d2finaleunblocker gamedata file");
		return;
	}
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(ConfigFile, SDKConf_Signature, "CFinaleTrigger_StartFinale");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	MySDKCall = EndPrepSDKCall();
	CloseHandle(ConfigFile);
	
	if (MySDKCall == INVALID_HANDLE)
	{
		SetFailState("Cant initialize CFinaleTrigger_StartFinale SDKCall");
	}
}

TriggerFinaleRelayOnly()
{
	new client = GetAnyValidClient();
	if (client == -1)
	{
		// LogError("Cant find a valid player to trigger the finale with");
		return;
	}
	UnflagAndExecuteCommand(client, "ent_fire", "trigger_finale");
}

TriggerFinale()
{
	new client = GetAnyValidClient();
	if (client == -1)
	{
		// LogError("Cant find a valid player to trigger the finale with");
		return;
	}

	new triggerEnt = FindEntityByClassname(-1, "trigger_finale");
	if (triggerEnt == -1)
	{
		LogError("Cant find a trigger_finale entity to trigger the finale with");
		return;
	}
	
	UnflagAndExecuteCommand(client, "ent_fire", "trigger_finale");
	SDKCall(MySDKCall, FindEntityByClassname(-1, "trigger_finale"), client);
}

stock UnflagAndExecuteCommand(client = -1, String:command[], String:parameters[]="")
{
	if (client < 1 || !IsClientInGame(client)) client = GetAnyValidClient();
	if (client < 1 || !IsClientInGame(client)) return;
	
	new userflags = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, parameters)
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, userflags);
}

stock GetAnyValidClient()
{
	for (new target = 1; target <= MaxClients; target++)
	{
		if (IsClientInGame(target)) return target;
	}
	return -1;
}