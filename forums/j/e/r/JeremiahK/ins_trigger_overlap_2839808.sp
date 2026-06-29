// vim: ts=8 syntax=cpp
#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_NAME	"[INS] Trigger Overlap"
public Plugin myinfo = {
	name =		PLUGIN_NAME,
	version =	"1.12.1.0",
	description =	"Fixes collision bug with overlapping triggers.",
	author =	"JeremiahK (RedDeathOfMe)",
	url =		"https://forums.alliedmods.net/member.php?u=347772"
}

#define CFG_FILE		"configs/ins_trigger_overlap.txt"
#define MAX_FILENAME_LEN	2048
#define MAX_ENTPROPDATA_LEN	32
#define MAX_PLAYERS		49
#define MAX_EDICTS		2048
#define MAX_TRIGGER_GROUPS	32

int gNumTriggerGroups;
char gTriggerGroups[MAX_PLAYERS][MAX_TRIGGER_GROUPS];	// array of 1-byte ints
char gGroupIDsForTriggerEnts[MAX_EDICTS];		// array of 1-byte ints

// Make sure the game is Insurgency.
public APLRes AskPluginLoad2(Handle handle, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() != Engine_Insurgency) {
		strcopy(error, err_max, "Only compatible with Insurgency");
		return APLRes_SilentFailure;
	}
}

public void OnPluginStart()
{
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Pre);
}

public void OnMapStart()
{
	gNumTriggerGroups = 0;
	ParseConfigFile();
}

public void OnMapEnd()
{
}

// Find and create trigger groups for map using config file to match triggers.
static void ParseConfigFile()
{
	// Find full path to config file. Open as KeyValues.
	char configFile[MAX_FILENAME_LEN];
	BuildPath(Path_SM, configFile, sizeof(configFile), CFG_FILE);
	KeyValues kv = CreateKeyValues("ins_trigger_overlap");
	kv.ImportFromFile(configFile);

	if (!kv.GotoFirstSubKey(false)) {
		PrintToServer("%s: Config file is empty.", PLUGIN_NAME);
		CloseHandle(kv);
		return;
	}

	// Loop through keys in root node.
	// These are classnames of triggers to check for multiples.
	do {
		// Get classname of trigger to check.
		char className[MAX_ENTPROPDATA_LEN];
		kv.GetSectionName(className, sizeof(className));
		if (!kv.GotoFirstSubKey(false)) {
			PrintToServer("%s: Config file has broken classname key `%s`. Skipping.", PLUGIN_NAME, className);
			continue;
		}
		kv.GoBack();

		// Get entity property to use for matching multiple triggers.
		// Triggers that share this prop's value are considered multiples.
		if (!kv.JumpToKey("match")) {
			PrintToServer("%s: Config file has no `match` key under classname `%s`. Skipping.", PLUGIN_NAME, className);
			continue;
		}
		char matchProp[MAX_ENTPROPDATA_LEN];
		kv.GetString(NULL_STRING, matchProp, sizeof(matchProp));
		kv.GoBack();
		
		// If trigger has no forced props, check by className and matchProp only.
		if (!(kv.JumpToKey("force") && kv.GotoFirstSubKey(false))) {
			CheckTriggers(className, matchProp);
			continue;
		}

		// ...Else, trigger DOES have forced props.
		// Get number of entity props to force.
		kv.SavePosition();
		int numForceProps = 1;
		while (kv.GotoNextKey(false))
		{
			++numForceProps;
		}
		kv.GoBack();

		// Create array of entity props with forced values.
		// Triggers without these prop-values will be ignored.
		char[][][] forceProps = new char[numForceProps][2][MAX_ENTPROPDATA_LEN];
		for (int i = 0; i < numForceProps; i++)
		{
			char buffer[MAX_ENTPROPDATA_LEN];

			kv.GetSectionName(buffer, sizeof(buffer));
			strcopy(forceProps[i][0], MAX_ENTPROPDATA_LEN, buffer);

			kv.GetString(NULL_STRING, buffer, sizeof(buffer));
			strcopy(forceProps[i][1], MAX_ENTPROPDATA_LEN, buffer);

			kv.GotoNextKey(false);
		}
		kv.GoBack();
		kv.GoBack();

		CheckTriggers(className, matchProp, forceProps, numForceProps);
	} while (kv.GotoNextKey(false));

	// Make sure we haven't overflowed past MAX_TRIGGER_GROUPS.
	if (gNumTriggerGroups > MAX_TRIGGER_GROUPS) {
		PrintToServer("%s: MAX_TRIGGER_GROUPS=%i isn't enough! Ignoring %i TriggerGroup(s).", PLUGIN_NAME, MAX_TRIGGER_GROUPS, gNumTriggerGroups - MAX_TRIGGER_GROUPS);
		gNumTriggerGroups = MAX_TRIGGER_GROUPS;
	}

	CloseHandle(kv);
}

// Check all entities of specific trigger type to find its multiples.
// - className		classname of entities to search
// - matchProp		triggers are grouped by this EntProp's string value
// - forceProps		ignore entities that don't match these EntProp's values
// - numForceProps	sizeof(forceProps); number of EntProp values to force
static void CheckTriggers(const char[] className, const char[] matchProp, const char[][][] forceProps={}, int numForceProps=0)
{
	ArrayList ents = CreateArray(1);	// all matching entities
	StringMap propValues = CreateTrie();	// unique values of matchProp : hit counts
	StringMap groupIDs = CreateTrie();	// multi-values of matchProp : trigger group ID

	int matchCount;				// tempvar: number of ents matched
	int intVal;				// tempvar: int prop buffer
	float floatVal;				// tempvar: float prop buffer
	char propBuf[MAX_ENTPROPDATA_LEN];	// tempvar: string prop buffer

	// Search through all entities matching className.
	int ent = INVALID_ENT_REFERENCE;
	while((ent = FindEntityByClassname(ent, className)) != INVALID_ENT_REFERENCE)
	{
		// Loop through forced entity properties.
		for (int i = 0; i < numForceProps; i++)
		{
			if (!HasEntProp(ent, Prop_Data, forceProps[i][0])) {
				break;
			}

			// If forceProp is int, but doesn't match ent's prop value, skip ent.
			if (strlen(forceProps[i][1]) == StringToIntEx(forceProps[i][1], intVal)) {
				if (GetEntProp(ent, Prop_Data, forceProps[i][0]) != StringToInt(forceProps[i][1])) {
					break;
				}
				IntToString(intVal, propBuf, sizeof(propBuf));
			}

			// If forceProp is float, but doesn't match ent's prop value, skip ent.
			else if (strlen(forceProps[i][1]) == StringToFloatEx(forceProps[i][1], floatVal)) {
				if (GetEntPropFloat(ent, Prop_Data, forceProps[i][0]) != StringToFloat(forceProps[i][1])) {
					break;
				}
				FloatToString(floatVal, propBuf, sizeof(propBuf));
			}

			// If forceProp is string, but doesn't match ent's prop value, skip ent.
			else {
				GetEntPropString(ent, Prop_Data, forceProps[i][0], propBuf, sizeof(propBuf));
				if (!StrEqual(propBuf, forceProps[i][1])) {
					break;
				}
			}

			// All forceProps match this entity! Save ent to list.
			ents.Push(ent);

			// Check matchProp's value; keep count of multiples.
			GetEntPropString(ent, Prop_Data, matchProp, propBuf, sizeof(propBuf));
			propValues.SetValue(propBuf, 0, false);
			propValues.GetValue(propBuf, matchCount);
			propValues.SetValue(propBuf, ++matchCount, true);
			if (matchCount == 2) {
				groupIDs.SetValue(propBuf, gNumTriggerGroups++, false);
			}
		}
	}

	for (int i = 0; i < ents.Length; i++)
	{
		ent = ents.Get(i);
		GetEntPropString(ent, Prop_Data, matchProp, propBuf, sizeof(propBuf));

		// Get number of matching ents. Skip if only 1.
		propValues.GetValue(propBuf, matchCount);
		if (matchCount == 1) {
			continue;
		}

		// Get and remember groupID of this ent.
		int groupID;
		groupIDs.GetValue(propBuf, groupID);
		if (groupID >= MAX_TRIGGER_GROUPS) {
			continue;
		}
		gGroupIDsForTriggerEnts[ent] = groupID & 0xFF;	// int to char

		// Hook start and end touch on this ent.
		SDKHook(ent, SDKHook_StartTouch, Trigger_StartTouch);
		SDKHook(ent, SDKHook_EndTouch, Trigger_EndTouch);
	}

	CloseHandle(ents);
	CloseHandle(propValues);
	CloseHandle(groupIDs);
}

// Reset player's TriggerGroups counters on spawn.
static Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	for (int i = 0; i < gNumTriggerGroups; i++)
	{
		gTriggerGroups[client-1][i] = 0;
	}
	return Plugin_Continue;
}

// Block StartTouch if TriggerGroup has been entered but not left.
static Action Trigger_StartTouch(int ent, int other)
{
	if (++gTriggerGroups[other-1][gGroupIDsForTriggerEnts[ent]] == 1) {
		return Plugin_Continue;
	}
	return Plugin_Handled;
}

// Block EndTouch if TriggerGroup has been entered but not left.
static Action Trigger_EndTouch(int ent, int other)
{
	if (--gTriggerGroups[other-1][gGroupIDsForTriggerEnts[ent]] == 0) {
		return Plugin_Continue;
	}
	return Plugin_Handled;
}
