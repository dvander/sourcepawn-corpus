#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define DEFAULT_SECONDS 0
#define DEFAULT_MINUTES 0
#define DEFAULT_HOURS 0
#define DEFAULT_DAYS 0

new Seconds[30];
new Minutes[30];
new Hours[30];
new Days[30];

new String:Path[64];

public Plugin:myinfo =
{
	name = "Official Timer",
	author = "[GR]Nick_6893{A}",
	description = "Official way of counting everyone's time in the server.",
	version = "1.12",
	url = "www.sourcemod.net"
}

public OnPluginStart()
{
	RegConsoleCmd("say", Command_ShowTime);
	BuildPath(Path_SM, Path, 64, "data/officialtimes.txt");
}

public OnClientPutInServer(Client)
{
	Seconds[Client] = 0;
	Minutes[Client] = 0;
	Hours[Client] = 0;
	Days[Client] = 0;

	CreateTimer(2.0, Timer_Load, Client);
	CreateTimer(2.5, Official_Timer_Function, Client);
	CreateTimer(10.0, Official_Timer_Save, Client);

	PrintToChat(Client, "[SM] Official Timer Enabled Successfully!");
}

public OnClientDisconnect(Client)
{
	Timer_Save(Client);
    
	Seconds[Client] = 0;
	Minutes[Client] = 0;
	Hours[Client] = 0;
	Days[Client] = 0;
}

public Action:Official_Timer_Function(Handle:Timer, any:Client)
{
	if(Client > 0 && IsClientInGame(Client))
	{
		if(Seconds[Client] == 59)
		{
			Minutes[Client] = (Minutes[Client] + 1);
			Seconds[Client] = 0;
			Timer_Save(Client);
		}
		if(Minutes[Client] == 60)
		{
			Hours[Client] = (Hours[Client] + 1);
			Minutes[Client] = 0;
			Timer_Save(Client);
		}
		if(Hours[Client] == 24)
		{
			Days[Client] = (Days[Client] + 1);
			Hours[Client] = 0;
			Timer_Save(Client);
		}
		Seconds[Client] = (Seconds[Client] + 1);
	}
	CreateTimer(1.0, Official_Timer_Function, Client);
	return Plugin_Handled;
}

public Action:Official_Timer_Save(Handle:Timer, any:Client)
{
	if(Client > 0 && IsClientInGame(Client))
	{
		Timer_Save(Client);
	}
	CreateTimer(15.0, Official_Timer_Save, Client);
	return Plugin_Handled; 
}

public Action:Command_ShowTime(Client, Arguments)
{
	new String:Full_Text[255], String:Argument_Buffers[2][255], String:Quote_Character[1];
	GetCmdArgString(Full_Text, sizeof(Full_Text));
	new Length = strlen(Full_Text);
	Quote_Character[0] = Full_Text[Length - 1];
	new bool:Alpha = IsCharAlpha(Quote_Character[0]);
	new bool:Numeric = IsCharNumeric(Quote_Character[0]);
	if(!Alpha && !Numeric)
		ReplaceString(Full_Text, 255, Quote_Character[0], " "); 
	TrimString(Full_Text);
	ExplodeString(Full_Text, " ", Argument_Buffers, 2, 32);	

	if(StrEqual(Argument_Buffers[0], "!time", false))
	{
		if(Client == 0)
			return Plugin_Continue;
		PrintToChat(Client, "[SM] [Official Timer] You have been in the server for:");
		PrintToChat(Client, "\x01\x04%d\x01 Days, \x01\x04%d\x01 Hours, \x01\x04%d\x01 Minutes, \x01\x04%d\x01 Seconds", Days[Client], Hours[Client], Minutes[Client], Seconds[Client]);
	}

	if(StrEqual(Argument_Buffers[0], "/time", false))
	{
		if(Client == 0)
			return Plugin_Continue;
		PrintToChat(Client, "[SM] [Official Timer] You have been in the server for:");
		PrintToChat(Client, "\x01\x04%d\x01 Days, \x01\x04%d\x01 Hours, \x01\x04%d\x01 Minutes, \x01\x04%d\x01 Seconds", Days[Client], Hours[Client], Minutes[Client], Seconds[Client]);
	}
	return Plugin_Continue;
}

public Timer_Save(Client)
{
	if(Client > 0 && IsClientInGame(Client))
	{
		new String:SteamID[32];
		GetClientAuthString(Client, SteamID, 32);
		decl Handle:Times;
		Times = CreateKeyValues("Times");
		if(FileExists(Path))
			FileToKeyValues(Times, Path);
		if(Seconds[Client] > 0)
		{
			KvJumpToKey(Times, "Seconds", true);
			KvSetNum(Times, SteamID, Seconds[Client]);
			KvRewind(Times);
		}
		if(Minutes[Client] > 0)
		{
			KvJumpToKey(Times, "Minutes", true);
			KvSetNum(Times, SteamID, Minutes[Client]);
			KvRewind(Times);
		}
		if(Hours[Client] > 0)
		{
			KvJumpToKey(Times, "Hours", true);
			KvSetNum(Times, SteamID, Hours[Client]);
			KvRewind(Times);
		}
		if(Days[Client] > 0)
		{
			KvJumpToKey(Times, "Days", true);
			KvSetNum(Times, SteamID, Days[Client]);
			KvRewind(Times);
		}
		KvRewind(Times);
		KeyValuesToFile(Times, Path);
		CloseHandle(Times);
	}
}

public Action:Timer_Load(Handle:Timer, any:Client)
{
	new String:SteamID[32];
	GetClientAuthString(Client, SteamID, 32);
	decl Handle:Times;
	Times = CreateKeyValues("Times");
	FileToKeyValues(Times, Path);

	KvJumpToKey(Times, "Seconds", false);
	Seconds[Client] = KvGetNum(Times, SteamID, DEFAULT_SECONDS);
	KvRewind(Times);

	KvJumpToKey(Times, "Minutes", false);
	Minutes[Client] = KvGetNum(Times, SteamID, DEFAULT_MINUTES);
	KvRewind(Times);

	KvJumpToKey(Times, "Hours", false);
	Hours[Client] = KvGetNum(Times, SteamID, DEFAULT_HOURS);
	KvRewind(Times);

	KvJumpToKey(Times, "Days", false);
	Days[Client] = KvGetNum(Times, SteamID, DEFAULT_DAYS);
	KvRewind(Times);

	CloseHandle(Times);
}

public OnMapEnd()
{
	ServerCommand("sm plugins reload OfficialTimer");
}