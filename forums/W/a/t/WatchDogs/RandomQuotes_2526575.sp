#pragma semicolon 1

#include <sourcemod>
#include <multicolors>


#pragma newdecls required

Handle h_qInterval;
Handle h_Timer;
Handle h_qMode;
Handle h_Tag;

Handle ARRAY_Quotes;

int lastqID;

public Plugin myinfo = 
{
	name = "Random Message Printer",
	author = "[W]atch [D]ogs",
	description = "Prints random messages every X minutes from a config file",
	version = "1.0"
};

public void OnPluginStart()
{
	h_qMode = CreateConVar("sm_quotes_mode", "0", "Print message mode\n\n0 = Chat\n1 = Hint\n2 = Center", _, true, 0.0, true, 2.0);
	h_qInterval = CreateConVar("sm_quotes_interval", "5", "The time between printing quotes (Every X minutes)");
	h_Tag = CreateConVar("sm_quotes_tag", "{green}[Quotes]{default}", "The tag before quotes (Set empty for disable)");
	h_Timer = CreateTimer(GetConVarFloat(h_qInterval) * 60, Timer_Print, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	
	RegAdminCmd("sm_nextq", CMD_NextQ, ADMFLAG_CHAT, "Force print next quote");
	
	LoadQuotes();
	
	HookConVarChange(h_qInterval, qInterval_Changed);
	
	AutoExecConfig(true);
}

public Action CMD_NextQ(int client, int args)
{
	PrintQuote();
}

public void qInterval_Changed(Handle convar, char[] oldValue, char[] newValue)
{
	KillTimer(h_Timer);
	h_Timer = CreateTimer(GetConVarFloat(convar) * 60, Timer_Print, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public void OnConfigsExecuted()
{
	LoadQuotes();
}

public void LoadQuotes()
{
	char path[PLATFORM_MAX_PATH], sLine[255];
	
	ARRAY_Quotes = CreateArray(sizeof(sLine));
	BuildPath(Path_SM, path, PLATFORM_MAX_PATH, "configs/quotes.txt");
	
	if(FileExists(path))
	{
		Handle hFile = OpenFile(path, "r");
		while(!IsEndOfFile(hFile) && ReadFileLine(hFile, sLine, sizeof(sLine)))
			PushArrayString(ARRAY_Quotes, sLine);
			
		CloseHandle(hFile);
	}
	else
	{
		PushArrayString(ARRAY_Quotes, "Quotes config file missing.");
	}
}

public Action Timer_Print(Handle timer)
{
	PrintQuote();
}

public void PrintQuote()
{
	char sQuote[255], sTag[255];
	int qMode = GetConVarInt(h_qMode);
	int nextqID;
	nextqID = GetRandomInt(0, GetArraySize(ARRAY_Quotes) - 1);
	
	while(nextqID == lastqID) {
		nextqID = GetRandomInt(0, GetArraySize(ARRAY_Quotes) - 1);
	}
	
	GetArrayString(ARRAY_Quotes, nextqID, sQuote, sizeof(sQuote));
	GetConVarString(h_Tag, sTag, sizeof(sTag));
	lastqID = nextqID;
	
	if(qMode == 0)
	{
		if(StrEqual(sTag, "")) {
			CPrintToChatAll("%s", sQuote);
		} else {
			CPrintToChatAll("%s %s", sTag, sQuote);
		}
	} 
	else if(qMode == 1)
	{
		if(StrEqual(sTag, "")) {
			PrintHintTextToAll("%s", sQuote);
		} else {
			PrintHintTextToAll("%s %s", sTag, sQuote);
		}
	} 
	else
	{
		if(StrEqual(sTag, "")) {
			PrintCenterTextAll("%s", sQuote);
		} else {
			PrintCenterTextAll("%s %s", sTag, sQuote);
		}
	}
}
