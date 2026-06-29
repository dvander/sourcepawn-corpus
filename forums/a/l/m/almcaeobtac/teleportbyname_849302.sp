#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.2"

static String:FileLoc[128];
static bool:FileIn;
static String:MapName[255];

public Plugin:myinfo = 
{
	name = "Teleport by Name",
	author = "Alm",
	description = "Save locations to teleport to by name, then teleport to them later.",
	version = PLUGIN_VERSION,
	url = "http://www.loners-gaming.com/ && http://www.iwuclan.com/"
}

public OnPluginStart()
{
	RegAdminCmd("sm_teleport", TeleportPlayer, ADMFLAG_CUSTOM6, "<name> <destination name> Teleports a player to a location.");
	RegAdminCmd("sm_maketeleport", NewTeleport, ADMFLAG_CUSTOM6, "<name> Creates a new teleport location where you are standing.");
	RegAdminCmd("sm_delteleport", DelTeleport, ADMFLAG_CUSTOM6, "<name> Removes a teleport location.");
	RegAdminCmd("sm_teleportinfo", ListTeleport, ADMFLAG_CUSTOM6, "<name> Returns the location of a teleport name.");
}

public OnMapStart()
{
	GetCurrentMap(MapName, 255);

	BuildPath(Path_SM, FileLoc, 128, "data/telelocs.txt");
	if(!FileExists(FileLoc))
	{
		PrintToServer("[SM] Error: Missing file: %s", FileLoc);
		FileIn = false;
	}
	else
	{
		FileIn = true;
	}
}

public Action:TeleportPlayer(Client, Args)
{
	if(!FileIn)
	{
		PrintToConsole(Client, "[SM] Error: Data file missing.");
		return Plugin_Handled;
	}

	if(Args < 2)
	{
		PrintToConsole(Client, "[SM] Usage: sm_teleport <name> <destination name>");
		return Plugin_Handled;
	}

	decl String:TargetName[32];
	decl String:TestName[32];
	decl String:TestString[64];
	decl Target;
	decl String:AdminName[32];
	decl String:LocName[64];

	GetCmdArg(1, TargetName, 32);
	GetCmdArg(2, LocName, 64);

	Target = -1;

	for(new Test = 1; Test <= GetMaxClients(); Test++)
	{
		if(IsClientInGame(Test) && Target == -1)
		{
			GetClientName(Test, TestName, 32);
			
			if(StrContains(TestName, TargetName, false) != -1)
			{
				TargetName = TestName;
				Target = Test;
			}
		}
	}

	if(Target == -1)
	{
		PrintToConsole(Client, "[SM] %s is not in-game.", TargetName);
		return Plugin_Handled;
	}

	if(!IsPlayerAlive(Target))
	{
		PrintToConsole(Client, "[SM] %s is not alive.", TargetName);
		return Plugin_Handled;
	}

	if(Client == 0)
	{
		AdminName = "Console";
	}
	else
	{
		GetClientName(Client, AdminName, 32);
	}
	
	decl Float:Loc[3];
	decl String:Buffer[3][64];
	decl Handle:Vault;

	Vault = CreateKeyValues("Vault");
	FileToKeyValues(Vault, FileLoc);

	KvJumpToKey(Vault, MapName, true);

	KvGetString(Vault, LocName, TestString, 64, "null");

	KvRewind(Vault);

	CloseHandle(Vault);

	if(StrEqual(TestString, "null"))
	{
		PrintToConsole(Client, "[SM] No teleport location for %s.", LocName);
		return Plugin_Handled;
	}
	
	ExplodeString(TestString, " ", Buffer, 3, 64);

	Loc[0] = StringToFloat(Buffer[0]);
        Loc[1] = StringToFloat(Buffer[1]);
        Loc[2] = StringToFloat(Buffer[2]);

	TeleportEntity(Target, Loc, NULL_VECTOR, NULL_VECTOR);

	if(Target != Client)
	{
		PrintToConsole(Client, "[SM] Teleported %s to %s.", TargetName, LocName);
		PrintToChat(Target, "[SM] %s teleported you!", AdminName);
	}
	else
	{
		PrintToChat(Client, "[SM] You teleport yourself!");
	}

	return Plugin_Handled;
}
	
public Action:NewTeleport(Client, Args)
{
	if(Client == 0)
	{
		PrintToConsole(Client, "[SM] You must be in-game.");
		return Plugin_Handled;
	}

	if(!FileIn)
	{
		PrintToConsole(Client, "[SM] Error: Data file missing.");
		return Plugin_Handled;
	}

	if(Args == 0)
	{
		PrintToConsole(Client, "[SM] Usage: sm_maketeleport <name>");
		return Plugin_Handled;
	}

	decl String:TestString[64];

	decl String:TeleName[64];
	GetCmdArgString(TeleName, 64);
	StripQuotes(TeleName);

	decl Float:ClientPosition[3];
	GetClientAbsOrigin(Client, ClientPosition);

	decl Handle:Vault;

	Vault = CreateKeyValues("Vault");
	FileToKeyValues(Vault, FileLoc);

	KvJumpToKey(Vault, MapName, true);

	KvGetString(Vault, TeleName, TestString, 64, "null");

	KvRewind(Vault);

	CloseHandle(Vault);

	if(!StrEqual(TestString, "null"))
	{
		PrintToConsole(Client, "[SM] A teleport location already exists with the name %s.", TeleName);
		return Plugin_Handled;
	}

	decl String:Buffer[3][64];
	decl String:ToSave[64];

	IntToString(RoundFloat(ClientPosition[0]), Buffer[0], 64);
	IntToString(RoundFloat(ClientPosition[1]), Buffer[1], 64);
	IntToString(RoundFloat(ClientPosition[2]), Buffer[2], 64);

	ImplodeStrings(Buffer, 3, " ", ToSave, 64);
	
	Vault = CreateKeyValues("Vault");
	FileToKeyValues(Vault, FileLoc);

	KvJumpToKey(Vault, MapName, true);

	KvSetString(Vault, TeleName, ToSave);

	KvRewind(Vault);

	KeyValuesToFile(Vault, FileLoc);

	CloseHandle(Vault);

	PrintToConsole(Client, "[SM] Created teleport location %s at (%f)(%f)(%f)", TeleName, ClientPosition[0], ClientPosition[1], ClientPosition[2]);

	return Plugin_Handled;
}

public Action:DelTeleport(Client, Args)
{
	if(!FileIn)
	{
		PrintToConsole(Client, "[SM] Error: Data file missing.");
		return Plugin_Handled;
	}

	if(Args == 0)
	{
		PrintToConsole(Client, "[SM] Usage: sm_delteleport <name>");
		return Plugin_Handled;
	}

	decl String:TestString[64];

	decl String:TeleName[64];
	GetCmdArgString(TeleName, 64);
	StripQuotes(TeleName);

	decl Handle:Vault;

	Vault = CreateKeyValues("Vault");
	FileToKeyValues(Vault, FileLoc);

	KvJumpToKey(Vault, MapName, true);

	KvGetString(Vault, TeleName, TestString, 64, "null");

	KvRewind(Vault);

	CloseHandle(Vault);

	if(StrEqual(TestString, "null"))
	{
		PrintToConsole(Client, "[SM] No teleport location called %s.", TeleName);
		return Plugin_Handled;
	}
	
	Vault = CreateKeyValues("Vault");
	FileToKeyValues(Vault, FileLoc);

	KvJumpToKey(Vault, MapName, true);

	KvDeleteKey(Vault, TeleName);

	KvRewind(Vault);

	KeyValuesToFile(Vault, FileLoc);

	CloseHandle(Vault);

	PrintToConsole(Client, "[SM] Deleted teleport location %s.", TeleName);

	return Plugin_Handled;
}

public Action:ListTeleport(Client, Args)
{
	if(!FileIn)
	{
		PrintToConsole(Client, "[SM] Error: Data file missing.");
		return Plugin_Handled;
	}

	if(Args == 0)
	{
		PrintToConsole(Client, "[SM] Usage: sm_teleportinfo <name>");
		return Plugin_Handled;
	}

	decl String:TestString[64];
	decl Float:Loc[3];
	decl String:Buffer[3][64];

	decl String:TeleName[64];
	GetCmdArgString(TeleName, 64);
	StripQuotes(TeleName);

	decl Handle:Vault;

	Vault = CreateKeyValues("Vault");
	FileToKeyValues(Vault, FileLoc);

	KvJumpToKey(Vault, MapName, true);

	KvGetString(Vault, TeleName, TestString, 64, "null");

	KvRewind(Vault);

	CloseHandle(Vault);

	if(StrEqual(TestString, "null"))
	{
		PrintToConsole(Client, "[SM] No teleport location called %s.", TeleName);
		return Plugin_Handled;
	}

	ExplodeString(TestString, " ", Buffer, 3, 64);

	Loc[0] = StringToFloat(Buffer[0]);
        Loc[1] = StringToFloat(Buffer[1]);
        Loc[2] = StringToFloat(Buffer[2]);

	PrintToConsole(Client, "[SM] %s: (%f)(%f)(%f)", TeleName, Loc[0], Loc[1], Loc[2]);

	return Plugin_Handled;
}