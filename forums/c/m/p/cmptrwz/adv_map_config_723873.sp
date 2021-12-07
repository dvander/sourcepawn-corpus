#include <sourcemod>

#pragma semicolon 1

#define PLUGIN_VERSION "1.0"

// Plugin definitions
public Plugin:myinfo = 
{
	name = "Advanced Map Configuration",
	author = "cmptrwz",
	description = "Server Based Map, Map Prefix, and Custom Mode Configurations",
	version = PLUGIN_VERSION
};

// We enabled?
new Handle:pluginEnabled;
// Char to use as a prefix separator
new Handle:prefixChar;
// Max depth to look for a prefix
new Handle:prefixDepth;
// Prefix execution mode
new Handle:prefixMode;
// Game Mode - Base folder to check
new Handle:gameMode;
// Do we include the port when looking for configs?
new Handle:includePort;
// Do we include the IP when looking for configs?
new Handle:includeIP;
// Cvar ip
new Handle:cvarIp;
// Cvar hostip
new Handle:cvarHostip;
// Cvar hostport
new Handle:cvarHostport;
// Are we currently processing configs?
new g_Running;

public OnPluginStart()
{
	pluginEnabled = CreateConVar("sm_mapconfig_enabled", "1", "Advanced Map Config Enabled");
	prefixChar = CreateConVar("sm_mapconfig_prefixchar", "_", "Character used as prefix separator for config launching");
	prefixDepth = CreateConVar("sm_mapconfig_prefixdepth", "3", "Max number of prefixes before we stop calling it a prefix");
	prefixMode = CreateConVar("sm_mapconfig_prefixmode", "3", "Prefix Mode bitmask. See plugin docs for info.");
	includePort = CreateConVar("sm_mapconfig_includeport", "1", "Include port when finding config files. See plugin docs for info.");
	includeIP = CreateConVar("sm_mapconfig_includeip", "6", "Include IP Bitmask. See plugin docs for info.");
	gameMode = CreateConVar("sm_mapconfig_gamemode", "", "Game Mode Directory to use");
	// Once this is there we don't really care about it all that much, honestly.
	CreateConVar("sm_mapconfig_version", PLUGIN_VERSION, "Advanced Map Config Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);  
	cvarIp = FindConVar("ip");
	cvarHostip = FindConVar("hostip");
	cvarHostport = FindConVar("hostport");
	HookConVarChange(gameMode, OnGameModeChange);
}

public OnConfigsExecuted()
{
	// If we are disabled we should probably not do anything.
	if(GetConVarInt(pluginEnabled) == 0)
		return;
	// We are running. Config changes should not restart us.
	// This is just incase a sm_mapconfig_gamemode change happens in one of the files we run
	// If that is the case, it will take effect on the next map change
	g_Running = 1;
	new myPrefixMode; // Prefix Mode when pulled from cvar
	new myPrefixDepth; // Prefix Depth when pulled from cvar
	new myIncludePort; // IncludePort when pulled from cvar
	new myIncludeIP; // IncludeIP when pulled from cvar
	// These three may never be set, so we need new instead of decl to play it safe.
	new String:myIp[128]; // As far as I can tell, this can be a hostname as well as an IP, hence the insane length
	new String:myHostip[12]; // 2^32 is 10 chars, +1 for the null, +1 for a trailing slash.
	new String:myHostport[7]; // 2^16 is 5 chars, +1 for the null, +1 for a trailing slash.
	decl String:myGameMode[32]; // I hope for sanity in the lengths of these
	decl String:mapname[64]; // Honestly, never questioned the definition of this at 64
	decl String:myPrefixChar[5]; // If you want to explode prefixes on more than 4 chars, I question your sanity.
	// First, the game mode, IncludePort, and IncludeIP settings
	// They are what we use to grab the default.cfg files
	GetConVarString(gameMode, myGameMode, sizeof(myGameMode));
	if(strlen(myGameMode) > 0) // We have a game mode?
		StrCat(myGameMode, sizeof(myGameMode), "/"); // Append trailing slash.
	myIncludePort = GetConVarInt(includePort);
	myIncludeIP = GetConVarInt(includeIP);
	if(myIncludeIP & 6) // We need to have bit 2 or 4 to be valid
	{
		if(myIncludeIP & 2 && cvarIp != INVALID_HANDLE) // We want it, and have a handle for it
			GetConVarString(cvarIp, myIp, sizeof(myIp));
		if(myIncludeIP & 4 && cvarHostip != INVALID_HANDLE) // Ditto
			GetConVarString(cvarHostip, myHostip, sizeof(myHostip));
		if(strlen(myIp) > 0) // We have something from ip?
			StrCat(myIp, sizeof(myIp), "/"); // Append trailing slash.
		if(strlen(myHostip) > 0) // We have something from hostip?
			StrCat(myHostip, sizeof(myHostip), "/"); // Append trailing slash.
	}
	if(myIncludePort > 0 && cvarHostport != INVALID_HANDLE)
	{
		GetConVarString(cvarHostport, myHostport, sizeof(myHostport));
		if(strlen(myHostport) > 0) // We have something for the port?
			StrCat(myHostport, sizeof(myHostport), "/"); // Append trailing slash.
	}
	// Go find, and if found run, all the default config files that may apply at this point.
	RunConfigSet(myIncludeIP, myIncludePort, myGameMode, myIp, myHostip, myHostport, "default");
	// Run the commands now, so that any default.cfg messing with the prefix options takes effect.
	ServerExecute();
	// Now we may need map/prefix stuff.
	myPrefixMode = GetConVarInt(prefixMode);
	myPrefixDepth = GetConVarInt(prefixDepth);
	// If just bit 8, or 8 with 4, then no prefix OR map level configs will run ANYWAY, so why waste the time it takes to get the map?
	GetCurrentMap(mapname, sizeof(mapname));
	if((myPrefixMode & 3) && (myPrefixDepth > 0)) // Prefix enabled (with at least 1 useful option) AND depth is greater than 0?
	{
		GetConVarString(prefixChar, myPrefixChar, sizeof(myPrefixChar));
		if(strlen(myPrefixChar) > 0) // Skip prefix mode if we don't have a prefix delimiter
		{
			decl String:prefixset[myPrefixDepth][16];
			new myPrefixCount;
			new i;
			myPrefixCount = ExplodeString(mapname, myPrefixChar, prefixset, myPrefixDepth, 16);
			if(myPrefixCount > 0) // We have something!
			{
				if(myPrefixMode & 2) // Individual files
				{
					if(myPrefixMode & 8) // Reverse order individual files?
					{ // These braces are not actually required. But the compiler throws a loose indentation warning without them.
						for(i = myPrefixCount-1; i>=0; i--)
							if(strlen(prefixset[i]) > 0)
								RunConfigSet(myIncludeIP, myIncludePort, myGameMode, myIp, myHostip, myHostport, prefixset[i]);
					}
					else // Normal order invidiual files?
					{ // These braces are not actually required, even to shut up the compiler. They are here to be consistent.
						for(i = 0; i<myPrefixCount; i++)
							if(strlen(prefixset[i]) > 0)
								RunConfigSet(myIncludeIP, myIncludePort, myGameMode, myIp, myHostip, myHostport, prefixset[i]);
					}
				}
				if(myPrefixMode & 1) // Combined prefixes (always normal order)?
				{
					decl String:implodePrefix[64]; // Temporary place to implode them to.
					for(i = 0; i<myPrefixCount; i++)
					{
						ImplodeStrings(prefixset, i+1, myPrefixChar, implodePrefix, sizeof(implodePrefix));
						if(myPrefixMode & 4) // Strip digits from end of last prefix?
						{
							new tempPos;
							while(strlen(implodePrefix) > 0) // While we have a string
							{
								tempPos = strlen(implodePrefix)-1; // Figure out where we are looking
								if(implodePrefix[tempPos] >= '0' && implodePrefix[tempPos] <= '9') // Is it in the range we want?
									implodePrefix[tempPos] = 0; // Null to shorten the string
								else // Isn't what we want?
									break; // We are done.
							}
						}
						if(strlen(implodePrefix)> 0)
						{
							StrCat(implodePrefix, sizeof(implodePrefix), myPrefixChar);
							RunConfigSet(myIncludeIP, myIncludePort, myGameMode, myIp, myHostip, myHostport, implodePrefix);
						}
					}
				}
			}
		}
	}
	if(!(myPrefixMode & 16)) // 8 is skip map specific configs.
		RunConfigSet(myIncludeIP, myIncludePort, myGameMode, myIp, myHostip, myHostport, mapname);
	// Lets force an execute of everything before we say we are done.
	ServerExecute();
	// We are done. Let sm_mapconfig_gamemode changes trigger this function again.
	g_Running = 0;
}

// This used to be in the previous function. I shouldn't have been coding half asleep when I did that.
RunConfigSet(myIncludeIP, myIncludePort, String:myGameMode[], String:myIp[], String:myHostip[], String:myHostport[], String:filename[])
{
	decl String:myScriptPath[PLATFORM_MAX_PATH]; // For the file we pass to exec
	decl String:myTempScriptPath[PLATFORM_MAX_PATH]; // For the file we pass to FileExists
	// Can we skip ip and port?
	if(!(myIncludeIP & 1) && (myIncludePort != 2))
	{
		Format(myScriptPath,sizeof(myScriptPath),"advmap/%s%s.cfg",myGameMode,filename);
		Format(myTempScriptPath,sizeof(myTempScriptPath),"cfg/%s",myScriptPath);
		if(FileExists(myTempScriptPath))
			ServerCommand("exec \"%s\"", myScriptPath);
	}
	// Are we using IP AND skipping port?
	if((myIncludeIP & 6) && (myIncludePort != 2))
	{
		if(myIncludeIP & 2)
		{
			Format(myScriptPath,sizeof(myScriptPath),"advmap/%s%s%s.cfg",myGameMode,myIp,filename);
			Format(myTempScriptPath,sizeof(myTempScriptPath),"cfg/%s",myScriptPath);
			if(FileExists(myTempScriptPath))
				ServerCommand("exec \"%s\"", myScriptPath);
		}
		if(myIncludeIP & 4)
		{
			Format(myScriptPath,sizeof(myScriptPath),"advmap/%s%s%s.cfg",myGameMode,myHostip,filename);
			Format(myTempScriptPath,sizeof(myTempScriptPath),"cfg/%s",myScriptPath);
			if(FileExists(myTempScriptPath))
				ServerCommand("exec \"%s\"", myScriptPath);
		}
	}
	// Are we using port AND skipping IP?
	if((myIncludePort > 0) && !(myIncludeIP & 1))
	{
		Format(myScriptPath,sizeof(myScriptPath),"advmap/%s%s%s.cfg",myGameMode,myHostport,filename);
		Format(myTempScriptPath,sizeof(myTempScriptPath),"cfg/%s",myScriptPath);
		if(FileExists(myTempScriptPath))
			ServerCommand("exec \"%s\"", myScriptPath);
	}
	// Are we using port AND IP?
	if((myIncludePort > 0) && (myIncludeIP & 6))
	{
		if(myIncludeIP & 2)
		{
			Format(myScriptPath,sizeof(myScriptPath),"advmap/%s%s%s%s.cfg",myGameMode,myIp,myHostport,filename);
			Format(myTempScriptPath,sizeof(myTempScriptPath),"cfg/%s",myScriptPath);
			if(FileExists(myTempScriptPath))
				ServerCommand("exec \"%s\"", myScriptPath);
		}
		if(myIncludeIP & 4)
		{
			Format(myScriptPath,sizeof(myScriptPath),"advmap/%s%s%s%s.cfg",myGameMode,myHostip,myHostport,filename);
			Format(myTempScriptPath,sizeof(myTempScriptPath),"cfg/%s",myScriptPath);
			if(FileExists(myTempScriptPath))
				ServerCommand("exec \"%s\"", myScriptPath);
		}
	}
}

public OnGameModeChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if(g_Running != 1) // Only if we aren't currently in our own exec configs loop
		OnConfigsExecuted();
}
