#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <left4downtown>

#define PLUGIN_VERSION			"1.0.0"
#define TEST_DEBUG				0
#define TEST_DEBUG_LOG			0

public Plugin:myinfo = 
{
	name = "L4D2 Difficulty Control",
	author = " AtomicStryker",
	description = " Adjust versus Difficulty ",
	version = PLUGIN_VERSION,
	url = ""
}

static DifficultyOverride = 1;

public OnPluginStart()
{
	//CreateConVar("l4d2_diffcontrol_version", PLUGIN_VERSION, " L4D2 Difficulty Control Plugin Version ", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	RegAdminCmd("sm_forcediff", cmd_ForceDifficulty, ADMFLAG_CHEATS, "sm_forcediff <setting>");
}

public Action:cmd_ForceDifficulty(client, args)
{
	if (!args)
	{
		ReplyToCommand(client, "Usage: sm_forcediff <setting>, where 0 is easy and 3 is expert, \x03current setting: %i", DifficultyOverride);
		return Plugin_Handled;
	}
	
	decl String:buffer[3];
	GetCmdArg(1, buffer, sizeof(buffer));
	
	DifficultyOverride = StringToInt(buffer);
	
	ReplyToCommand(client, "Difficulty Override set to \x03%i\x01 (0 is easy and 3 is expert)", DifficultyOverride);
	
	return Plugin_Handled;
}

public Action:L4D_OnGetDifficulty(&retVal)
{
	if (DifficultyOverride != 1)
	{
		retVal = DifficultyOverride;
		return Plugin_Handled;
	}
    // 0 is easy, 1 is normal (versus default), 2 is hard, 3 is expert
    
	return Plugin_Continue;
}

stock DebugPrintToAll(const String:format[], any:...)
{
	#if (TEST_DEBUG || TEST_DEBUG_LOG)
	decl String:buffer[256];
	
	VFormat(buffer, sizeof(buffer), format, 2);
	
	#if TEST_DEBUG
	PrintToChatAll("[DIFFCONTROL] %s", buffer);
	PrintToConsole(0, "[DIFFCONTROL] %s", buffer);
	#endif
	
	LogMessage("%s", buffer);
	#else
	//suppress "format" never used warning
	if(format[0])
		return;
	else
		return;
	#endif
}