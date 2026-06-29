/*

	Tech Demo to showoff a way to Vocalize EVERYTHING L4D2 contains

	Unfortunately cannot be integrated with vocalize, since Valve blocked the Console Callback, and the scene- and vocalizestrings mismatch aswell
	(Using an Extension you actually can get the Callback, but it fires on ALL Vocalizes, even the ones not blocked)
	
	Note Valves scene file naming is inconsistant, the automatic approach sm_voc only covers the most common one [scenefile01 ... 70]
	If there's an uber vocalize youre just DYING to use, you can specify the complete name with sm_voc_this
	
	
	examples for use:
	
	sm_voc miscdirectional
	will cause you to say random directional stuff like "through here"
	
	sm_voc seeclowns
	KILL EVERY CLOWN YOU SEE!!
	
	
	sm_voc_this survivormourngamblerc101
	vocalize things that do not follow the [scenefile01 ... 70] naming convention
	
	
	Credit for this approach and first coding goes to DJ_WEST of Alliedmodders forums
	
	
	
	- AtomicStryker

*/


#define PLUGIN_VERSION    "1.0.0"
#define PLUGIN_NAME       "L4D2 Custom Vocalize"

#include <sourcemod>
#include <sdktools>

#define TEST_DEBUG 0
#define TEST_DEBUG_LOG 0


public OnPluginStart()
{
	RegConsoleCmd("sm_voc", Cmd_Vocalize_Random);
	RegConsoleCmd("sm_voc_this", Cmd_Vocalize_Specified);
}

public Action:Cmd_Vocalize_Random(client, args)
{
	if (!client || !args || !IsClientInGame(client))
	{
		ReplyToCommand(client, "Must be Ingame for command to work, and dont forget the argument");
		return Plugin_Handled;
	}
	
	decl String:arg[256];
	GetCmdArg(1, arg, sizeof(arg));
	
	DebugPrintToAll("SM Vocalize caught by %N, command: %s", client, arg);
	
	// STEP 1: FIGURE OUT WHICH SURVIVOR WERE DEALING WITH
	
	decl String:model[256];
	GetEntPropString(client, Prop_Data, "m_ModelName", model, sizeof(model));
	
	if (StrContains(model, "gambler") != -1)
	{
		FormatEx(model, sizeof(model), "gambler");
	}
	else if (StrContains(model, "coach") != -1)
	{
		FormatEx(model, sizeof(model), "coach");
	}
	else if (StrContains(model, "mechanic") != -1)
	{
		FormatEx(model, sizeof(model), "mechanic");
	}
	else if (StrContains(model, "producer") != -1)
	{
		FormatEx(model, sizeof(model), "producer");
	}
	
	// STEP 2: SCAN SCENES FOLDER WITH VOCALIZE ARGUMENT AND NUMBERS FOR FILES
	
	decl String:scenefile[256], String:checknumber[3];
	new foundfilescounter;
	decl validfiles[71];
	
	for (new i = 1; i <= 70; i++)
	{
		if (i < 10)
		{
			FormatEx(checknumber, sizeof(checknumber), "0%i", i);
		}
		else
		{
			FormatEx(checknumber, sizeof(checknumber), "%i", i);
		}
		
		FormatEx(scenefile, sizeof(scenefile), "scenes/%s/%s%s.vcd", model, arg, checknumber); // example "scenes/mechanic/grenade01.vcd"
		
		if (!FileExists(scenefile)) continue;
		
		foundfilescounter++;
		validfiles[foundfilescounter] = i;
		
		DebugPrintToAll("Found valid file at %s, index:%i", scenefile, foundfilescounter);
	}
	
	if (!foundfilescounter)
	{
		DebugPrintToAll("No valid files found for arg %s", arg);
		return Plugin_Handled;
	}
	
	// STEP 3: SELECT ONE OF THE FOUND SCENE FILES
	
	new randomint = GetRandomInt(1, foundfilescounter);
	DebugPrintToAll("Valid Files Count: %i, randomly chosen index: %i", foundfilescounter, randomint);
	
	if (validfiles[randomint] < 10)
	{
		FormatEx(checknumber, sizeof(checknumber), "0%i", validfiles[randomint]);
	}
	else
	{
		FormatEx(checknumber, sizeof(checknumber), "%i", validfiles[randomint]);
	}
	FormatEx(scenefile, sizeof(scenefile), "scenes/%s/%s%s.vcd", model, arg, checknumber);
	
	DebugPrintToAll("Chose Scenefile: %s, attempting to vocalize now", scenefile);
	
	// STEP 4: CALL SCENE AND THUS VOCALIZE
	
	new tempent = CreateEntityByName("instanced_scripted_scene");
	DispatchKeyValue(tempent, "SceneFile", scenefile);
	DispatchSpawn(tempent);
	SetEntPropEnt(tempent, Prop_Data, "m_hOwner", client);
	ActivateEntity(tempent);
	AcceptEntityInput(tempent, "Start", client, client);
	HookSingleEntityOutput(tempent, "OnCompletion", EntityOutput:OnSceneCompletion, true);

	return Plugin_Handled;
}

public Action:Cmd_Vocalize_Specified(client, args)
{
	if (!client || !args || !IsClientInGame(client))
	{
		ReplyToCommand(client, "Must be Ingame for command to work, and dont forget the argument");
		return Plugin_Handled;
	}
	
	decl String:arg[256];
	GetCmdArg(1, arg, sizeof(arg));
	
	DebugPrintToAll("SM Vocalize caught by %N, command: %s", client, arg);
	
	// STEP 1: FIGURE OUT WHICH SURVIVOR WERE DEALING WITH
	
	decl String:model[256];
	GetEntPropString(client, Prop_Data, "m_ModelName", model, sizeof(model));
	
	if (StrContains(model, "gambler") != -1)
	{
		FormatEx(model, sizeof(model), "gambler");
	}
	else if (StrContains(model, "coach") != -1)
	{
		FormatEx(model, sizeof(model), "coach");
	}
	else if (StrContains(model, "mechanic") != -1)
	{
		FormatEx(model, sizeof(model), "mechanic");
	}
	else if (StrContains(model, "producer") != -1)
	{
		FormatEx(model, sizeof(model), "producer");
	}
	
	// STEP 2: INPUT CHOSEN SCENE IN MASK
	
	decl String:scenefile[256];
	FormatEx(scenefile, sizeof(scenefile), "scenes/%s/%s.vcd", model, arg);
	
	if (!FileExists(scenefile))
	{
		DebugPrintToAll("Specified Scenefile: %s does not exist, aborting", scenefile);
		return Plugin_Handled;
	}
	
	DebugPrintToAll("Specified Scenefile: %s, attempting to vocalize now", scenefile);
	
	// STEP 3: CALL SCENE AND THUS VOCALIZE
	
	new tempent = CreateEntityByName("instanced_scripted_scene");
	DispatchKeyValue(tempent, "SceneFile", scenefile);
	DispatchSpawn(tempent);
	SetEntPropEnt(tempent, Prop_Data, "m_hOwner", client);
	ActivateEntity(tempent);
	AcceptEntityInput(tempent, "Start", client, client);
	HookSingleEntityOutput(tempent, "OnCompletion", EntityOutput:OnSceneCompletion, true);

	return Plugin_Handled;
}

public OnSceneCompletion(const String:s_Output[], i_Caller, i_Activator, Float:f_Delay)
{
	RemoveEdict(i_Caller);
}

stock DebugPrintToAll(const String:format[], any:...)
{
	#if TEST_DEBUG	|| TEST_DEBUG_LOG
	decl String:buffer[192];
	
	VFormat(buffer, sizeof(buffer), format, 2);
	
	#if TEST_DEBUG
	PrintToChatAll("[TEST] %s", buffer);
	PrintToConsole(0, "[TEST] %s", buffer);
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