#include <sourcemod>
#include <sdktools>
#include <colors>
#include <left4dhooks>

bool 
	g_bIsL4D2;
	g_bDebugModeEnabled = false;
	g_bIsInfiniteHordeActive = false;
	g_bIsInfiniteHordePaused = false;

int 
	g_iEventsCount = 0,
	g_iCurrentEventNum = 0;

char
	g_sDefaultScript[32][32],
	g_sOverrideScript[32][32],
	g_sOverrideEventType[32][32],
	g_sShutdownTrigger[32][32],
	g_sShutdownTriggerName[32][32],
	g_sShutdownTriggerOutput[32][32];

Handle
	g_h_OnInfiniteHordeStart = INVALID_HANDLE,
	g_h_OnInfiniteHordeEnd = INVALID_HANDLE,
	g_h_OnInfiniteHordeBlock = INVALID_HANDLE,
	g_h_OnInfiniteHordeOverride = INVALID_HANDLE,
	g_h_OnInfiniteHordePause = INVALID_HANDLE,
	g_h_OnInfiniteHordeUnpause = INVALID_HANDLE,
	g_h_UnpauseInfiniteHordeTimer = INVALID_HANDLE;

ConVar
	g_cvGameMode,
	g_cvDebugMode;

public Plugin myinfo =
{
	name = "[L4D2] Infinite Horde Control",
	author = "B[R]UTUS",
	description = "Hooks and controls all infinite horde events",
	version = "1.0.0",
	url = ""
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion engine = GetEngineVersion();
	if (engine == Engine_Left4Dead2) 
		g_bIsL4D2 = true;
	else
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}

	g_h_OnInfiniteHordeStart = CreateGlobalForward("OnInfiniteHordeStart", ET_Ignore);
	g_h_OnInfiniteHordeEnd = CreateGlobalForward("OnInfiniteHordeEnd", ET_Ignore);
	g_h_OnInfiniteHordeBlock = CreateGlobalForward("OnInfiniteHordeBlock", ET_Ignore);
	g_h_OnInfiniteHordeOverride = CreateGlobalForward("OnInfiniteHordeOverride", ET_Ignore, Param_String, Param_String);
	g_h_OnInfiniteHordePause = CreateGlobalForward("OnInfiniteHordePause", ET_Ignore, Param_Float, Param_Float);
	g_h_OnInfiniteHordeUnpause = CreateGlobalForward("OnInfiniteHordeUnpause", ET_Ignore, Param_Float);
	//----------------------------------------------------------------------------------------
	CreateNative("IsInfiniteHordeActive", Native_IsInfiniteHordeActive);
	CreateNative("IsInfiniteHordePaused", Native_IsInfiniteHordePaused);
	CreateNative("PauseInfiniteHorde", Native_PauseInfiniteHorde);
	CreateNative("UnpauseInfiniteHorde", Native_UnpauseInfiniteHorde);
	//----------------------------------------------------------------------------------------
	RegPluginLibrary("l4d2_infinite_horde_control");

	return APLRes_Success;
}

public void OnPluginStart()
{
	if (!g_bIsL4D2)
		SetFailState("Plugin doesn't support this game!");

	g_cvDebugMode = CreateConVar("l4d2_ihc_debug_mode", "0", "0 = disable debug mode | 1 = enabled debug mode");
	AutoExecConfig(true, "l4d_infinite_horde_control");

	g_cvGameMode = FindConVar("mp_gamemode");
	g_cvGameMode.AddChangeHook(Change_ConVar);
	g_cvDebugMode.AddChangeHook(Change_ConVar);

	if (IsAllowedGamemode())
		Process_Hooks();

	RegAdminCmd("sm_info", CMD_DebugInfo, ADMFLAG_KICK, "Show debug map info");
	RegAdminCmd("sm_horde_pause", CMD_InfiniteHordePause, ADMFLAG_KICK, "Pause/Unpause infinite horde");
}

void Change_ConVar(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (convar == g_cvGameMode)
	{
		if (StrEqual(newValue, "survival", true) || StrEqual(newValue, "mutation15", true))
			Process_Unhooks();
		else
			Process_Hooks();
	}
	else if (convar == g_cvDebugMode)
	{
		if (StringToInt(newValue) == 0 || StringToInt(newValue) == 1)
			g_bDebugModeEnabled = view_as<bool>(StringToInt(newValue));
		else
			LogError("Wrong value for ConVar <l4d2_ihc_debug_mode>");
	}
}

void Process_Hooks()
{
	HookEvent("round_end", Event_RoundEnd);
	HookEntityOutput("point_prop_use_target", "OnUseFinished", point_prop_use_target);
	HookEntityOutput("func_button", "OnPressed", func_button);
}

void Process_Unhooks()
{
	UnhookEvent("round_end", Event_RoundEnd);
	UnhookEntityOutput("point_prop_use_target", "OnUseFinished", point_prop_use_target);
	UnhookEntityOutput("func_button", "OnPressed", func_button);
}

void Process_ClearMapData()
{
	for (int i = 1; i <= 31; i++)
	{
		g_sDefaultScript[i] = "\0";
		g_sOverrideScript[i] = "\0";
		g_sOverrideEventType[i] = "\0";
		g_sShutdownTrigger[i] = "\0";
		g_sShutdownTriggerName[i] = "\0";
		g_sShutdownTriggerOutput[i] = "\0";
	}
}

//=========================================== FUNCTIONS BLOCK ===========================================
bool IsAllowedGamemode()
{
	char cGamemode[32];
	g_cvGameMode.GetString(cGamemode, sizeof(cGamemode));

	if (StrEqual(cGamemode, "survival", true) || StrEqual(cGamemode, "mutation15", true))
		return false;
	else
		return true;
}

bool IsDebugModeEnabled()
{
	return view_as<bool>(g_bDebugModeEnabled);
}

bool IsDefaultScriptOverridden(int eventNumber)
{
	if (strcmp(g_sOverrideScript[eventNumber], "block") == 0 || strcmp(g_sOverrideScript[eventNumber], "") == 1)
		return true;

	return false;
}

bool IsDefaultScriptBlocked(int eventNumber)
{
	if (strcmp(g_sOverrideScript[eventNumber], "block") == 0)
		return true;

	return false;
}

bool IsDefaultScriptReplaced(int eventNumber)
{
	if (strcmp(g_sOverrideScript[eventNumber], "") == 1)
		return true;

	return false;
}

bool IsOverrideScriptWithInfiniteHorde(int eventNumber)
{
	if (strcmp(g_sOverrideEventType[eventNumber], "infinite") == 0)
		return true;

	return false;
}

bool IsInfiniteHordeStopByEntity(int eventNumber)
{
	if (strcmp(g_sShutdownTrigger[eventNumber], "entity_output") == 0)
		return true;

	return false;
}

bool IsInfiniteHordeStopByScript(int eventNumber)
{
	if (strcmp(g_sShutdownTrigger[eventNumber], "vscript") == 0)
		return true;

	return false;
}

stock char[] GetDefaultScriptName(int eventNumber)
{
	return g_sDefaultScript[eventNumber];
}

stock char[] GetOverrideScriptName(int eventNumber)
{
	return g_sOverrideScript[eventNumber];
}

stock char[] GetShutdownTriggerName(int eventNumber)
{
	return g_sShutdownTriggerName[eventNumber];
}

stock char[] GetShutdownTriggerOutput(int eventNumber)
{
	return g_sShutdownTriggerOutput[eventNumber];
}

//Functions for natives
void Function_ChangeCurrentInfiniteHordeStatus(bool status)
{
	g_bIsInfiniteHordeActive = status;

	if (status)
	{
		Call_StartForward(g_h_OnInfiniteHordeStart);
		Call_Finish();
	}
	else
	{
		if (Function_IsInfiniteHordePaused())
			Function_UnpauseCurrentInfiniteHorde();

		Call_StartForward(g_h_OnInfiniteHordeEnd);
		Call_Finish();
	}
}

int Function_GetCurrentInfiniteHordeEventNumber()
{
	return g_iCurrentEventNum;
}

stock void Function_PauseCurrentInfiniteHorde(float pause_duration = 0.0)
{
	g_bIsInfiniteHordePaused = true;
	Call_StartForward(g_h_OnInfiniteHordePause);
	Call_PushFloat(pause_duration);
	Call_PushFloat(GetGameTime());
	Call_Finish();

	if (pause_duration > 0.0)
		g_h_UnpauseInfiniteHordeTimer = CreateTimer(pause_duration, Timer_UnpauseInfiniteHorde, _, TIMER_FLAG_NO_MAPCHANGE);
}

void Function_UnpauseCurrentInfiniteHorde()
{
	g_bIsInfiniteHordePaused = false;
	Call_StartForward(g_h_OnInfiniteHordeUnpause);
	Call_PushFloat(GetGameTime());
	Call_Finish();
}

bool Function_IsInfiniteHordeActive()
{
	return view_as<bool>(g_bIsInfiniteHordeActive);
}

bool Function_IsInfiniteHordePaused()
{
	return view_as<bool>(g_bIsInfiniteHordePaused);
}
//end
//========================================= FUNCTIONS BLOCK END =========================================

//============================================ NATIVES BLOCK ============================================
any Native_IsInfiniteHordeActive(Handle plugin, int numParams)
{
	return view_as<bool>(Function_IsInfiniteHordeActive());
}

any Native_IsInfiniteHordePaused(Handle plugin, int numParams)
{
	return view_as<bool>(Function_IsInfiniteHordePaused());
}

any Native_PauseInfiniteHorde(Handle plugin, int numParams)
{
	Function_PauseCurrentInfiniteHorde(float(GetNativeCell(1)));
	return 0;
}

any Native_UnpauseInfiniteHorde(Handle plugin, int numParams)
{
	Function_UnpauseCurrentInfiniteHorde();
	return 0;
}
//========================================== NATIVES BLOCK END ==========================================

public void OnMapStart()
{
	Process_ClearMapData();
	Timer_Stop();
	Function_ChangeCurrentInfiniteHordeStatus(false);

	if (IsAllowedGamemode())
	{
		char mapName[32];
		GetCurrentMap(mapName, sizeof(mapName));
		Process_GetMapData(mapName);
	}
}

public void Event_RoundEnd(Handle event, char[] name, bool dontBroadcast)
{
	if (IsAllowedGamemode())
	if (Function_IsInfiniteHordeActive())
		Function_ChangeCurrentInfiniteHordeStatus(false);
		
	g_iCurrentEventNum = 0;
	Timer_Stop();
}

void Timer_Stop()
{
	if (g_h_UnpauseInfiniteHordeTimer != null)
	{
		KillTimer(g_h_UnpauseInfiniteHordeTimer)
		g_h_UnpauseInfiniteHordeTimer = null;
	}
}

public Action OnVScriptExecuted(const char[] sScript, char sOverride[PLATFORM_MAX_PATH], bool bOverride)
{
	if (IsAllowedGamemode())
	{
		for (int i = 0; i <= g_iEventsCount; i++)
		{
			if (StrEqual(sScript, GetDefaultScriptName(i), true))
			{
				if (!IsDefaultScriptOverridden(i))
				{
					if (Function_IsInfiniteHordeActive())
						Function_ChangeCurrentInfiniteHordeStatus(false);

					Function_ChangeCurrentInfiniteHordeStatus(true);
					g_iCurrentEventNum++;
				}
				else
				{
					if (IsDefaultScriptBlocked(i))
					{
						Call_StartForward(g_h_OnInfiniteHordeBlock);
						Call_Finish();
						g_iCurrentEventNum++;
						return Plugin_Handled;
					}
					else if (IsDefaultScriptReplaced(i))
					{
						Call_StartForward(g_h_OnInfiniteHordeOverride);
						Call_PushString(GetDefaultScriptName(i))
						Call_PushString(GetOverrideScriptName(i))
						Call_Finish();

						if (IsOverrideScriptWithInfiniteHorde(i))
							Function_ChangeCurrentInfiniteHordeStatus(true);

						sOverride = GetOverrideScriptName(i);
						g_iCurrentEventNum++;
						return Plugin_Changed;
					}
				}
			}
		}

		if (Function_IsInfiniteHordeActive())
		{
			if (IsInfiniteHordeStopByScript(Function_GetCurrentInfiniteHordeEventNumber()))
			{
				if (StrEqual(sScript, GetShutdownTriggerName(Function_GetCurrentInfiniteHordeEventNumber()), true))
					Function_ChangeCurrentInfiniteHordeStatus(false);
			}
		}
	}

	return Plugin_Continue;
}

void point_prop_use_target(const char[] output, int caller, int activator, float delay)
{
	if (IsDebugModeEnabled())
		CPrintToChatAll("{green}[{default}point_prop_use_target{green}]{default}: {green}OnUseFinished{default} -> Output({olive}%s{default}) | Activator({blue}%i{default})", output, activator);

	if (IsAllowedGamemode())
	{
		if (Function_IsInfiniteHordeActive())
		{
			if (IsInfiniteHordeStopByEntity(Function_GetCurrentInfiniteHordeEventNumber()))
			{
				if (StrEqual(GetShutdownTriggerName(Function_GetCurrentInfiniteHordeEventNumber()), "point_prop_use_target", true))
				{
					if (StrEqual(GetShutdownTriggerOutput(Function_GetCurrentInfiniteHordeEventNumber()), "OnUseFinished", true))
						Function_ChangeCurrentInfiniteHordeStatus(false);
				}
			}
		}
	}
}

void func_button(const char[] output, int caller, int activator, float delay)
{
	if (IsDebugModeEnabled())
		CPrintToChatAll("{green}[{default}func_button{green}]{default}: {green}OnPressed{default} -> Output({olive}%s{default}) | Activator({blue}%i{default})", output, activator);

	if (IsAllowedGamemode())
	{
		if (Function_IsInfiniteHordeActive())
		{
			if (IsInfiniteHordeStopByEntity(Function_GetCurrentInfiniteHordeEventNumber()))
			{
				if (StrEqual(GetShutdownTriggerName(Function_GetCurrentInfiniteHordeEventNumber()), "func_button", true))
				{
					if (StrEqual(GetShutdownTriggerOutput(Function_GetCurrentInfiniteHordeEventNumber()), "OnPressed", true))
						Function_ChangeCurrentInfiniteHordeStatus(false);
				}
			}
		}
	}
}

bool Process_GetMapData(const char[] mapName)
{
	char count[3];
	char szPath[256];
	BuildPath(Path_SM, szPath, sizeof(szPath), "configs/l4d2_infinite_horde_control.cfg");

	KeyValues kv = new KeyValues("InfiniteHordeControl");
	if (kv.ImportFromFile(szPath))
	{
		kv.Rewind();

		if (kv.JumpToKey(mapName))
		{
			if (kv.JumpToKey("infinite_horde_script"))
			{
				kv.GetString("count", count, sizeof(count));
				g_iEventsCount = StringToInt(count);

				for (int i = 0; i <= g_iEventsCount; i++)
				{
					if (i == 1)
					{
						if (kv.GotoFirstSubKey())
						{
							kv.GetString("default_script", g_sDefaultScript[i], sizeof(g_sDefaultScript));
							kv.GetString("override_script", g_sOverrideScript[i], sizeof(g_sDefaultScript));
							kv.GetString("override_event_type", g_sOverrideEventType[i], sizeof(g_sOverrideEventType));
							kv.GetString("shutdown_trigger", g_sShutdownTrigger[i], sizeof(g_sShutdownTrigger));
							kv.GetString("shutdown_trigger_name", g_sShutdownTriggerName[i], sizeof(g_sDefaultScript));
							kv.GetString("shutdown_trigger_output", g_sShutdownTriggerOutput[i], sizeof(g_sDefaultScript));

							if (strcmp(g_sDefaultScript[i], "") == 1)
								LogMessage("[%s]: <default_script> is '%s'", mapName, g_sDefaultScript[i]);
							else if (strcmp(g_sDefaultScript[i], "") == 0)
								LogMessage("[%s]: <default_script> is empty!", mapName);

							if (strcmp(g_sOverrideScript[i], "") == 1)
								LogMessage("[%s]: <override_script> is '%s'", mapName, g_sOverrideScript[i]);
							else if (strcmp(g_sOverrideScript[i], "") == 0)
								LogMessage("[%s]: <override_script> is empty!", mapName);

							if (strcmp(g_sOverrideEventType[i], "") == 1)
								LogMessage("[%s]: <override_event_type> is '%s'", mapName, g_sOverrideEventType[i]);
							else if (strcmp(g_sOverrideEventType[i], "") == 0)
								LogMessage("[%s]: <override_event_type> is empty!", mapName);

							if (strcmp(g_sShutdownTrigger[i], "") == 1)
								LogMessage("[%s]: <shutdown_trigger> is '%s'", mapName, g_sShutdownTrigger[i]);
							else if (strcmp(g_sShutdownTrigger[i], "") == 0)
								LogMessage("[%s]: <shutdown_trigger> is empty!", mapName);

							if (strcmp(g_sShutdownTriggerName[i], "") == 1)
								LogMessage("[%s]: <shutdown_trigger_name> is '%s'", mapName, g_sShutdownTriggerName[i]);
							else if (strcmp(g_sShutdownTriggerName[i], "") == 0)
								LogMessage("[%s]: <shutdown_trigger_name> is empty!", mapName);

							if (strcmp(g_sShutdownTriggerOutput[i], "") == 1)
								LogMessage("[%s]: <shutdown_trigger_output> is '%s'", mapName, g_sShutdownTriggerOutput[i]);
							else if (strcmp(g_sShutdownTriggerOutput[i], "") == 0)
								LogMessage("[%s]: <shutdown_trigger_output> is empty!", mapName);
						}
					}
					else if (i > 1)
					{
						if (kv.GotoNextKey())
						{
							kv.GetString("default_script", g_sDefaultScript[i], sizeof(g_sDefaultScript));
							kv.GetString("override_script", g_sOverrideScript[i], sizeof(g_sDefaultScript));
							kv.GetString("override_event_type", g_sOverrideEventType[i], sizeof(g_sOverrideEventType));
							kv.GetString("shutdown_trigger", g_sShutdownTrigger[i], sizeof(g_sShutdownTrigger));
							kv.GetString("shutdown_trigger_name", g_sShutdownTriggerName[i], sizeof(g_sDefaultScript));
							kv.GetString("shutdown_trigger_output", g_sShutdownTriggerOutput[i], sizeof(g_sDefaultScript));

							if (strcmp(g_sDefaultScript[i], "") == 1)
								LogMessage("[%s]: <default_script> is '%s'", mapName, g_sDefaultScript[i]);
							else if (strcmp(g_sDefaultScript[i], "") == 0)
								LogMessage("[%s]: <default_script> is empty!", mapName);

							if (strcmp(g_sOverrideScript[i], "") == 1)
								LogMessage("[%s]: <override_script> is '%s'", mapName, g_sOverrideScript[i]);
							else if (strcmp(g_sOverrideScript[i], "") == 0)
								LogMessage("[%s]: <override_script> is empty!", mapName);

							if (strcmp(g_sOverrideEventType[i], "") == 1)
								LogMessage("[%s]: <override_event_type> is '%s'", mapName, g_sOverrideEventType[i]);
							else if (strcmp(g_sOverrideEventType[i], "") == 0)
								LogMessage("[%s]: <override_event_type> is empty!", mapName);

							if (strcmp(g_sShutdownTrigger[i], "") == 1)
								LogMessage("[%s]: <shutdown_trigger> is '%s'", mapName, g_sShutdownTrigger[i]);
							else if (strcmp(g_sShutdownTrigger[i], "") == 0)
								LogMessage("[%s]: <shutdown_trigger> is empty!", mapName);

							if (strcmp(g_sShutdownTriggerName[i], "") == 1)
								LogMessage("[%s]: <shutdown_trigger_name> is '%s'", mapName, g_sShutdownTriggerName[i]);
							else if (strcmp(g_sShutdownTriggerName[i], "") == 0)
								LogMessage("[%s]: <shutdown_trigger_name> is empty!", mapName);

							if (strcmp(g_sShutdownTriggerOutput[i], "") == 1)
								LogMessage("[%s]: <shutdown_trigger_output> is '%s'", mapName, g_sShutdownTriggerOutput[i]);
							else if (strcmp(g_sShutdownTriggerOutput[i], "") == 0)
								LogMessage("[%s]: <shutdown_trigger_output> is empty!", mapName);
						}
					}
				}
			}
		}
		else
		{
			g_iEventsCount = 0;
			delete kv;
			return false;
		}

		delete kv;
		return true;
	}
	else
	{
		LogError("Couldn't find a <l4d2_infinite_horde_control.txt> file!");
		delete kv;
		return false;
	}
}

public Action L4D_OnSpawnMob(int &amount)
{
	if (IsAllowedGamemode())
	if (Function_IsInfiniteHordeActive())
	{
		if (Function_IsInfiniteHordePaused())
			return Plugin_Handled;
	}
		
	return Plugin_Continue;
}

Action Timer_UnpauseInfiniteHorde(Handle timer)
{
	if (IsAllowedGamemode())
	if (Function_IsInfiniteHordePaused())
		Function_UnpauseCurrentInfiniteHorde();
		
	Timer_Stop();
	return Plugin_Stop;
}

// ================================= COMMANDS TEST BLOCK =================================
Action CMD_DebugInfo(int client, int args)
{
	if (IsAllowedGamemode())
	{
		char mapName[32];
		GetCurrentMap(mapName, sizeof(mapName));

		for (int i = 0; i <= g_iEventsCount; i++)
		{
			if (i > 0)
			{
				CPrintToChatAll("Infinite Event #{olive}%i{default}:", i);
				CPrintToChatAll("[{green}%s{default}]: <{olive}default_script{default}[{green}%i{default}]> = '{blue}%s{default}'", mapName, i, g_sDefaultScript[i]);
				CPrintToChatAll("[{green}%s{default}]: <{olive}override_script{default}[{green}%i{default}]> = '{blue}%s{default}'", mapName, i, g_sOverrideScript[i]);
				CPrintToChatAll("[{green}%s{default}]: <{olive}override_event_type{default}[{green}%i{default}]> = '{blue}%s{default}'", mapName, i, g_sOverrideEventType[i]);
				CPrintToChatAll("[{green}%s{default}]: <{olive}shutdown_trigger{default}[{green}%i{default}]> = '{blue}%s{default}'", mapName, i, g_sShutdownTrigger[i]);
				CPrintToChatAll("[{green}%s{default}]: <{olive}shutdown_trigger_name{default}[{green}%i{default}]> = '{blue}%s{default}'", mapName, i, g_sShutdownTriggerName[i]);
				CPrintToChatAll("[{green}%s{default}]: <{olive}shutdown_trigger_output{default}[{green}%i{default}]> = '{blue}%s{default}'", mapName, i, g_sShutdownTriggerOutput[i]);
			}
			else
				CPrintToChatAll("[{green}%s{default}]: Infinite horde events not found on this map!", mapName);
		}
	}
	else
		CPrintToChatAll("{green}[{default}Infinite Horde Control{green}]{default}: Current gamemode doesn't supported!");

	return Plugin_Handled;
}

Action CMD_InfiniteHordePause(int client, int args)
{
	if (IsAllowedGamemode())
	{
		if (Function_IsInfiniteHordeActive())
		{
			if (!Function_IsInfiniteHordePaused())
			{
				if (args == 1)
				{
					char argument[32];
					GetCmdArg(1, argument, sizeof(argument));
					float arg = StringToFloat(argument);
					Function_PauseCurrentInfiniteHorde(arg);
					return Plugin_Handled;
				}
				else
				{
					Function_PauseCurrentInfiniteHorde();
					return Plugin_Handled;
				}
			}
			else
			{
				Function_UnpauseCurrentInfiniteHorde();
				return Plugin_Handled;
			}
		}
		else
		{
			CPrintToChatAll("{green}[{default}Infinite Horde Control{green}]{default}: Infinite horde is currently not active!");
			return Plugin_Handled;
		}
	}
	else
		return Plugin_Handled;
}
// =============================== COMMANDS TEST BLOCK END ===============================

// ================================= FORWARD TEST BLOCK =================================
public void OnInfiniteHordeStart()
{
	if (IsDebugModeEnabled())
		CPrintToChatAll("{green}[{default}Infinite Horde Control{green}]{default}: {olive}Infinite horde{default} event has started!");
}

public void OnInfiniteHordeEnd()
{
	if (IsDebugModeEnabled())
		CPrintToChatAll("{green}[{default}Infinite Horde Control{green}]{default}: {olive}Infinite horde{default} event has ended!");

	Timer_Stop();
}

public void OnInfiniteHordeBlock()
{
	if (IsDebugModeEnabled())
		CPrintToChatAll("{green}[{default}Infinite Horde Control{green}]{default}: Infinite horde script blocked!");
}

public void OnInfiniteHordeOverride(char[] defaultScript, char[] overrideScript)
{
	if (IsDebugModeEnabled())
		CPrintToChatAll("{green}[{default}Infinite Horde Control{green}]{default}: Infinite horde script ({green}%s{default}) has been overriden by {olive}%s{default} script!", defaultScript, overrideScript);
}

public void OnInfiniteHordePause(float pause_duration, float pause_start_time)
{
	if (IsDebugModeEnabled())
	{
		if (pause_duration > 0.0)
			CPrintToChatAll("{green}[{default}Infinite Horde Control{green}]{default}: Infinite horde will return in {olive}%.2f{default} seconds!", pause_duration);
		else
			CPrintToChatAll("{green}[{default}Infinite Horde Control{green}]{default}: Infinite horde paused!");
	}
}

public void OnInfiniteHordeUnpause(float pause_end_time)
{
	if (IsDebugModeEnabled())
		CPrintToChatAll("{green}[{default}Infinite Horde Control{green}]{default}: Infinite horde was unpaused! Unpause time: {olive}%.2f", pause_end_time);
}
// =============================== FORWARD TEST BLOCK END ===============================
