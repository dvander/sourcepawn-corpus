#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "2.0"

new Handle:Enable;
new Handle:TimeStampFormat;
new Handle:LogTriggers;
new Handle:SayEnable;
new Handle:ChatEnable;
new Handle:CSayEnable;
new Handle:TSayEnable;
new Handle:MSayEnable;
new Handle:HSayEnable;
new Handle:PSayEnable;
new Handle:Path;
new String:Name[256];
new String:Chat[256];
new String:Time[256];
new String:TName[MAX_NAME_LENGTH];
new String:Print[512];
new String:format1[256];
new String:path[PLATFORM_MAX_PATH];

public Plugin:myinfo = 
{
	name = "Chat Logger",
	author = "McFlurry",
	description = "Logs chat from all players and rcon",
	version = PLUGIN_VERSION,
	url = "N/A"
}

public OnPluginStart()
{
	CreateConVar("chat_log_version", PLUGIN_VERSION, "Chat Logging version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	Enable = CreateConVar("chat_log_enable", "1", "Enable Chat Logging", FCVAR_PLUGIN);
	TimeStampFormat = CreateConVar("chat_log_timeformat", "%b %d |%H:%M:%S| %Y", "Format for time stamp in files", FCVAR_PLUGIN);
	LogTriggers = CreateConVar("chat_log_triggers", "1", "Log triggers?", FCVAR_PLUGIN);
	SayEnable = CreateConVar("chat_log_sm_say", "1", "Log sm_say in chat log?", FCVAR_PLUGIN);
	ChatEnable = CreateConVar("chat_log_sm_chat", "1", "Log sm_chat in chat log?", FCVAR_PLUGIN);
	CSayEnable = CreateConVar("chat_log_sm_csay", "1", "Log sm_csay in chat log?", FCVAR_PLUGIN);
	TSayEnable = CreateConVar("chat_log_sm_tsay", "1", "Log sm_tsay in chat log?", FCVAR_PLUGIN);
	MSayEnable = CreateConVar("chat_log_sm_msay", "1", "Log sm_msay in chat log?", FCVAR_PLUGIN);
	HSayEnable = CreateConVar("chat_log_sm_hsay", "1", "Log sm_hsay in chat log?", FCVAR_PLUGIN);
	PSayEnable = CreateConVar("chat_log_sm_psay", "1", "Log sm_psay in chat log?", FCVAR_PLUGIN);
	RegConsoleCmd("say", SayP);
	RegConsoleCmd("say_team", SayT);
	RegConsoleCmd("sm_say", SMSay);
	RegConsoleCmd("sm_chat", SMChat);
	RegConsoleCmd("sm_csay", SMCSay);
	RegConsoleCmd("sm_tsay", SMTSay);
	RegConsoleCmd("sm_msay", SMMSay);
	RegConsoleCmd("sm_hsay", SMHSay);
	RegConsoleCmd("sm_psay", SMPSay);
	FormatTime(Time, sizeof(Time), "%Y%m%d");
	Format(Time, sizeof(Time), "logs/chat_%s.txt", Time);
	BuildPath(Path_SM, path, sizeof(path), Time);
	AutoExecConfig(true, "chat_logger");
}

public OnMapStart()
{
	CreateTimer(15.0, NewFCheck, _, TIMER_REPEAT);
}

public Action:NewFCheck(Handle:Timer, any:Client)
{
	FormatTime(Time, sizeof(Time), "%Y%m%d");
	Format(Time, sizeof(Time), "logs/chat_%s.txt", Time);
	BuildPath(Path_SM, path, sizeof(path), Time);
}	

public Action:SayP(client, args)
{
	if(GetConVarInt(Enable) == 0) return;
	FormatTimeChat();
	if(strlen(Chat) == 0) return;
	Path = OpenFile(path, "a+");
	if(client > 0)
	{
		GetClientName(client, Name, sizeof(Name));
		Format(Name, sizeof(Name), "[%s] %s", Time, Name);
	}
	else Format(Name, sizeof(Name), "[%s] Console", Time);
	Format(Print, sizeof(Print), "%s: %s", Name, Chat);
	if(IsChatTrigger() && GetConVarInt(LogTriggers) == 1) WriteFileLine(Path, Print);
	else if(!IsChatTrigger()) WriteFileLine(Path, Print);
	FlushFile(Path);
	CloseHandle(Path);
}

public Action:SayT(client, args)
{
	if(GetConVarInt(Enable) == 0) return;
	FormatTimeChat();
	if(strlen(Chat) == 0) return;
	Path = OpenFile(path, "a+");
	if(client > 0)
	{
		new Team = GetClientTeam(client);
		GetClientName(client, Name, sizeof(Name));
		GetTeamName(Team, TName, sizeof(TName));
		Format(Name, sizeof(Name), "[%s] %s(%s)", Time, Name, TName);
	}
	Format(Print, sizeof(Print), "%s: %s", Name, Chat);
	if(IsChatTrigger() && GetConVarInt(LogTriggers) == 1) WriteFileLine(Path, Print);
	else if(!IsChatTrigger()) WriteFileLine(Path, Print);
	FlushFile(Path);
	CloseHandle(Path);
}

public Action:SMSay(client, args)
{
	if(GetConVarInt(Enable) == 0 || GetConVarInt(SayEnable) == 0) return;
	FormatTimeChat();
	if(strlen(Chat) == 0) return;
	Path = OpenFile(path, "a+");
	if(client > 0)
	{
		GetClientName(client, Name, sizeof(Name));
		Format(Name, sizeof(Name), "[%s] (ALL)%s", Time, Name);
	}	
	else Format(Name, sizeof(Name), "[%s] (ALL)Console", Time);
	Format(Print, sizeof(Print), "%s: %s", Name, Chat);
	WriteFileLine(Path, Print);
	FlushFile(Path);
	CloseHandle(Path);
}

public Action:SMChat(client, args)
{
	if(GetConVarInt(Enable) == 0 || GetConVarInt(ChatEnable) == 0) return;
	FormatTimeChat();
	if(strlen(Chat) == 0) return;
	Path = OpenFile(path, "a+");
	if(client > 0)
	{
		GetClientName(client, Name, sizeof(Name));
		Format(Name, sizeof(Name), "[%s] (ADMINS)%s", Time, Name);
	}	
	else Format(Name, sizeof(Name), "[%s] (ADMINS)Console", Time);
	Format(Print, sizeof(Print), "%s: %s", Name, Chat);
	WriteFileLine(Path, Print);
	FlushFile(Path);
	CloseHandle(Path);
}

public Action:SMCSay(client, args)
{
	if(GetConVarInt(Enable) == 0 || GetConVarInt(CSayEnable) == 0) return;
	FormatTimeChat();
	if(strlen(Chat) == 0) return;
	Path = OpenFile(path, "a+");
	if(client > 0)
	{
		GetClientName(client, Name, sizeof(Name));
		Format(Name, sizeof(Name), "[%s] (Center-Text)%s", Time, Name);
	}	
	else Format(Name, sizeof(Name), "[%s] (Center-Text)Console", Time);
	Format(Print, sizeof(Print), "%s: %s", Name, Chat);
	WriteFileLine(Path, Print);
	FlushFile(Path);
	CloseHandle(Path);
}

public Action:SMTSay(client, args)
{
	if(GetConVarInt(Enable) == 0 || GetConVarInt(TSayEnable) == 0) return;
	FormatTimeChat();
	if(strlen(Chat) == 0) return;
	Path = OpenFile(path, "a+");
	if(client > 0)
	{
		GetClientName(client, Name, sizeof(Name));
		Format(Name, sizeof(Name), "[%s] (Corner)%s", Time, Name);
	}	
	else Format(Name, sizeof(Name), "[%s] (Corner)Console", Time);
	Format(Print, sizeof(Print), "%s: %s", Name, Chat);
	WriteFileLine(Path, Print);
	FlushFile(Path);
	CloseHandle(Path);
}

public Action:SMMSay(client, args)
{
	if(GetConVarInt(Enable) == 0 || GetConVarInt(MSayEnable) == 0) return;
	FormatTimeChat();
	if(strlen(Chat) == 0) return;
	Path = OpenFile(path, "a+");
	if(client > 0)
	{
		GetClientName(client, Name, sizeof(Name));
		Format(Name, sizeof(Name), "[%s] (Panel)%s", Time, Name);
	}	
	else Format(Name, sizeof(Name), "[%s] (Panel)Console", Time);
	Format(Print, sizeof(Print), "%s: %s", Name, Chat);
	WriteFileLine(Path, Print);
	FlushFile(Path);
	CloseHandle(Path);
}

public Action:SMHSay(client, args)
{
	if(GetConVarInt(Enable) == 0 || GetConVarInt(HSayEnable) == 0) return;
	FormatTimeChat();
	if(strlen(Chat) == 0) return;
	Path = OpenFile(path, "a+");
	if(client > 0)
	{
		GetClientName(client, Name, sizeof(Name));
		Format(Name, sizeof(Name), "[%s] (Hint)%s", Time, Name);
	}	
	else Format(Name, sizeof(Name), "[%s] (Hint)Console", Time);
	Format(Print, sizeof(Print), "%s: %s", Name, Chat);
	WriteFileLine(Path, Print);
	FlushFile(Path);
	CloseHandle(Path);
}

public Action:SMPSay(client, args)
{
	if(GetConVarInt(Enable) == 0 || GetConVarInt(PSayEnable) == 0) return;
	FormatTimeChat();
	if(strlen(Chat) == 0) return;
	Path = OpenFile(path, "a+");
	new String:Target[MAX_NAME_LENGTH];
	if(args == 2)
	{
		GetCmdArg(1, Target, sizeof(Target));
	}
	if(client > 0)
	{
		GetClientName(client, Name, sizeof(Name));
		Format(Name, sizeof(Name), "[%s] (Private: %s)%s", Time, Target, Name);
	}	
	else Format(Name, sizeof(Name), "[%s] (Private: %s)Console", Time, Target);
	Format(Print, sizeof(Print), "%s: %s", Name, Chat);
	WriteFileLine(Path, Print);
	FlushFile(Path);
	CloseHandle(Path);
}

public FormatTimeChat()
{
	GetConVarString(TimeStampFormat, format1, sizeof(format1));
	FormatTime(Time, sizeof(Time), format1);
	GetCmdArgString(Chat, sizeof(Chat));
}