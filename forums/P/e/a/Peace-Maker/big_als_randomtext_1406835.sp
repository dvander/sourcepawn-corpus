#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.1"

// Increase this one, if you want to add more random words to the list
#define PART_LIMIT 3

new Handle:g_hConfig = INVALID_HANDLE;
new g_iOptionCount[PART_LIMIT] = {0,...};

public Plugin:myinfo = 
{
	name = "Big Al's Random Text Generator!",
	author = "Jannik 'Peace-Maker' Hartung",
	description = "Generates random output defined in a config file on button push.",
	version = PLUGIN_VERSION,
	url = "http://www.wcfan.de/"
}

public OnPluginStart()
{
	new Handle:hVersion = CreateConVar("sm_randomtext_version", PLUGIN_VERSION, "Big Al's Random Text Generator version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	if(hVersion != INVALID_HANDLE)
		SetConVarString(hVersion, PLUGIN_VERSION);
}

public OnMapStart()
{
	// Parse the config
	g_hConfig = CreateKeyValues("RandomText");
	decl String:sFile[256];
	BuildPath(Path_SM, sFile, sizeof(sFile), "configs/big_als_randomtext.cfg");
	FileToKeyValues(g_hConfig, sFile);
	
	if (!KvGotoFirstSubKey(g_hConfig))
	{
		CloseHandle(g_hConfig);
		SetFailState("Can't find configs/big_als_randomtext.cfg.");
		return;
	}
	
	decl String:sBuffer[35], String:sSecondBuffer[256];
	new iOptionType, i;
	do
	{
		i = 1;
		KvGetSectionName(g_hConfig, sBuffer, sizeof(sBuffer));
		iOptionType = StringToInt(sBuffer);
		if(iOptionType < 1 || iOptionType > PART_LIMIT)
		{
			CloseHandle(g_hConfig);
			SetFailState("Invalid part count. Only %d parts supported, starting from 1 to %d.", PART_LIMIT, PART_LIMIT);
			return;
		}
		
		IntToString(i, sBuffer, sizeof(sBuffer));
		KvGetString(g_hConfig, sBuffer, sSecondBuffer, sizeof(sSecondBuffer), "xXx");
		while(!StrEqual(sSecondBuffer, "xXx"))
		{
			g_iOptionCount[iOptionType-1]++;
			i++;
			
			PrintToServer("Cat %d: %d %s", iOptionType, i, sSecondBuffer);
			
			IntToString(i, sBuffer, sizeof(sBuffer));
			KvGetString(g_hConfig, sBuffer, sSecondBuffer, sizeof(sSecondBuffer), "xXx");
		}
	} while (KvGotoNextKey(g_hConfig));

	KvRewind(g_hConfig);
	
	// Hook the button
	new iMaxEntities = GetMaxEntities();
	decl String:sClassName[64];
	for(i=MaxClients;i<iMaxEntities;i++)
	{
		if(IsValidEntity(i)
		&& IsValidEdict(i)
		&& GetEdictClassname(i, sClassName, sizeof(sClassName))
		&& StrContains(sClassName, "func_button") != -1
		&& GetEntPropString(i, Prop_Data, "m_iName", sClassName, sizeof(sClassName))
		&& StrEqual(sClassName, "courtbutton"))
		{
			HookSingleEntityOutput(i, "OnPressed", EntOut_OnPressed);
		}
	}
}

public OnMapEnd()
{
	if(g_hConfig != INVALID_HANDLE)
	{
		CloseHandle(g_hConfig);
		g_hConfig = INVALID_HANDLE;
	}
}

public EntOut_OnPressed(const String:output[], caller, activator, Float:delay)
{
	new String:sOutput[256], String:sRandom[10], String:sBuffer[64];
	new iRandom;
	
	Format(sOutput, sizeof(sOutput), "");
	
	for(new i=1;i<=PART_LIMIT;i++)
	{
		// Get random option
		IntToString(i, sBuffer, sizeof(sBuffer));
		if(!KvJumpToKey(g_hConfig, sBuffer))
			return;
		
		iRandom = GetURandomIntRange(1, g_iOptionCount[i-1]);
		IntToString(iRandom, sRandom, sizeof(sRandom));
		KvGetString(g_hConfig, sRandom, sBuffer, sizeof(sBuffer));
		
		if(strlen(sOutput) == 0)
			Format(sOutput, sizeof(sOutput), "%s", sBuffer);
		else
			Format(sOutput, sizeof(sOutput), "%s %s", sOutput, sBuffer);
			
		KvRewind(g_hConfig);
	}
	
	PrintToChatAll(sOutput);
}

stock GetURandomIntRange(min, max)
{
    return RoundToNearest((GetURandomFloat() * (max-min))+min);
}  