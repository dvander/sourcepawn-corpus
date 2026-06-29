#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_VERSION "1.0"

new Handle:g_hEvents;
new String:g_sLogFile[PLATFORM_MAX_PATH];
new Handle:g_hIgnore;

public Plugin:myinfo = 
{
	name = "Generic event output and logging",
	author = "Jannik \"Peace-Maker\" Hartung",
	description = "Hooks all events and logs them with data",
	version = PLUGIN_VERSION,
	url = "http://www.wcfan.de/"
}

public OnPluginStart()
{
	BuildPath(Path_SM, g_sLogFile, sizeof(g_sLogFile), "logs/event_log.log");
	
	g_hEvents = CreateTrie();
	g_hIgnore = CreateTrie();
	
	decl String:sPath[PLATFORM_MAX_PATH];
	Format(sPath, sizeof(sPath), "resource/gameevents.res");
	if(FileExists(sPath, true))
		ParseEventKV(sPath);
	else
		LogToFile(g_sLogFile, "Can't find resource/gameevents.res.");
	Format(sPath, sizeof(sPath), "resource/serverevents.res");
	if(FileExists(sPath, true))
		ParseEventKV(sPath);
	else
		LogToFile(g_sLogFile, "Can't find resource/serverevents.res.");
	Format(sPath, sizeof(sPath), "resource/hltvevents.res");
	if(FileExists(sPath, true))
		ParseEventKV(sPath);
	else
		LogToFile(g_sLogFile, "Can't find resource/hltvevents.res.");
	Format(sPath, sizeof(sPath), "resource/replayevents.res");
	if(FileExists(sPath, true))
		ParseEventKV(sPath);
	else
		LogToFile(g_sLogFile, "Can't find resource/replayevents.res.");
	
	// Overwrite with mods own defines
	Format(sPath, sizeof(sPath), "resource/modevents.res");
	if(!FileExists(sPath))
		SetFailState("Can't find resource/modevents.res");
	ParseEventKV(sPath);
	
	RegServerCmd("sm_event_ignore", Cmd_Ignore, "Ignores an event in the output.");
}

stock ParseEventKV(const String:sPath[PLATFORM_MAX_PATH])
{
	new Handle:kv = CreateKeyValues("whatever");
	FileToKeyValues(kv, sPath);
	KvRewind(kv);
	KvGotoFirstSubKey(kv);
	decl String:sBuffer[64], String:sEvent[32];
	new Handle:hArray;
	do
	{
		KvGetSectionName(kv, sEvent, sizeof(sEvent));
		if(!HookEventEx(sEvent, Event_Callback))
		{
			LogToFile(g_sLogFile, "Unable to hook event \"%s\".", sEvent);
			continue;
		}
		
		// Overwrite this event with the newer one!
		if(GetTrieValue(g_hEvents, sEvent, hArray))
			CloseHandle(hArray);
		hArray = CreateArray(ByteCountToCells(64));
		SetTrieValue(g_hEvents, sEvent, hArray);
		
		if(KvGotoFirstSubKey(kv, false))
		{
			do
			{
				GetTrieValue(g_hEvents, sEvent, hArray);
				KvGetSectionName(kv, sBuffer, sizeof(sBuffer));
				PushArrayString(hArray, sBuffer);
				KvGetString(kv, NULL_STRING, sBuffer, sizeof(sBuffer));
				PushArrayString(hArray, sBuffer);
				
			} while (KvGotoNextKey(kv, false));
			KvGoBack(kv);
		}
	} while (KvGotoNextKey(kv));
	CloseHandle(kv);
}

public Action:Cmd_Ignore(args)
{
	if(GetCmdArgs() < 1)
	{
		PrintToServer("Usage: sm_event_ignore event_name");
		return Plugin_Handled;
	}
	
	decl String:sEvent[32];
	GetCmdArg(1, sEvent, sizeof(sEvent));
	
	new iBuffer;
	if(!GetTrieValue(g_hEvents, sEvent, iBuffer))
	{
		PrintToServer("No event hooked named %s.", sEvent);
		return Plugin_Handled;
	}
	
	if(GetTrieValue(g_hIgnore, sEvent, iBuffer))
	{
		PrintToServer("Unignored event %s.", sEvent);
		LogToFile(g_sLogFile, "Unignored event %s.", sEvent);
		RemoveFromTrie(g_hIgnore, sEvent);
	}
	else
	{
		PrintToServer("Ignoring event %s.", sEvent);
		LogToFile(g_sLogFile, "Ignoring event %s.", sEvent);
		SetTrieValue(g_hIgnore, sEvent, 0);
	}
	
	return Plugin_Handled;
}

public Event_Callback(Handle:event, const String:name[], bool:dontBroadcast)
{
	new Handle:hEvent;
	
	if(GetTrieValue(g_hIgnore, name, hEvent))
		return;
	
	GetTrieValue(g_hEvents, name, hEvent);
	
	decl String:sOutput[512];
	Format(sOutput, sizeof(sOutput), "Fired event \"%s\"", name);
	
	decl String:sProperty[64], String:sType[64];
	new iBuffer, bool:bBuffer, Float:fBuffer, String:sBuffer[128];
	new iSize = GetArraySize(hEvent);
	for(new i=0;i<iSize;i++)
	{
		GetArrayString(hEvent, i, sProperty, sizeof(sProperty));
		GetArrayString(hEvent, ++i, sType, sizeof(sType));
		
		if(StrEqual(sProperty, "local"))
		{
			Format(sOutput, sizeof(sOutput), "%s (\"%s\" (not networked))", sOutput, sProperty);
			continue;
		}
		else if(StrEqual(sProperty, "unreliable"))
		{
			Format(sOutput, sizeof(sOutput), "%s (\"%s\" (networked, but unreliable))", sOutput, sProperty);
			continue;
		}
		// Stupid, but as it's in the file...
		else if(StrEqual(sProperty, "suppress"))
		{
			Format(sOutput, sizeof(sOutput), "%s (\"%s\" (never fire this event))", sOutput, sProperty);
			continue;
		}
		else if(StrEqual(sProperty, "time"))
		{
			Format(sOutput, sizeof(sOutput), "%s (\"%s\" (firing server time))", sOutput, sProperty);
			continue;
		}
		else if(StrEqual(sProperty, "eventid"))
		{
			Format(sOutput, sizeof(sOutput), "%s (\"%s\")", sOutput, sProperty);
			continue;
		}
		
		if(StrEqual(sType, "byte") || StrEqual(sType, "short") || StrEqual(sType, "long"))
		{
			iBuffer = GetEventInt(event, sProperty);
			Format(sOutput, sizeof(sOutput), "%s (\"%s\"(%s) = \"%d\")", sOutput, sProperty, sType, iBuffer);
		}
		else if(StrEqual(sType, "bool"))
		{
			bBuffer = GetEventBool(event, sProperty);
			Format(sOutput, sizeof(sOutput), "%s (\"%s\"(%s) = \"%s\")", sOutput, sProperty, sType, (bBuffer?"true":"false"));
		}
		else if(StrEqual(sType, "float"))
		{
			fBuffer = GetEventFloat(event, sProperty);
			Format(sOutput, sizeof(sOutput), "%s (\"%s\"(%s) = \"%f\")", sOutput, sProperty, sType, fBuffer);
		}
		else if(StrEqual(sType, "string"))
		{
			GetEventString(event, sProperty, sBuffer, sizeof(sBuffer));
			Format(sOutput, sizeof(sOutput), "%s (\"%s\"(%s) = \"%s\")", sOutput, sProperty, sType, sBuffer);
		}
	}
	
	LogToFile(g_sLogFile, sOutput);
}