/*
Shutdown.sp

Description:
	Shutdown server at desired time after round end with waring in round start.
	Set cvar k_shutdown format hh:mm or -1 disable plugin.

Versions:
	1.0
*/
#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#define PLUGIN_VERSION "1.0"
#define PLUGIN_NAME  "Shutdown"
#define noDEBUG 1

//*****************************************************************************
public Plugin:myinfo = 
{
	name = PLUGIN_NAME,
	author = "fatallerror",
	description = "Shutdown server at desired time after round end",
	version = PLUGIN_VERSION,
	url = ""
};
//*****************************************************************************
new H_shutdown=24;
new status=2;//0=normal;1=shutdown;2=pause
new Handle:cvarTimeShutdown = INVALID_HANDLE;

public OnPluginStart(){	
//*****************************************************************************
	#if defined DEBUG 
	PrintToServer("***********************************************************************");
	PrintToServer("Plugin shutdown start");
	PrintToServer("***********************************************************************");
	#endif
	cvarTimeShutdown=CreateConVar("k_shutdown","-2", "Time to shutdown in format hh. Set k_shutdown=-1 and server will shutdown at the end of next round ");
	H_shutdown=GetConVarInt(cvarTimeShutdown);	
	HookEvent("round_start", EventRoundStart);
	RegConsoleCmd("shutdown", sStatus);
	HookConVarChange(cvarTimeShutdown, OncvarTimeShutdownChange);
}
//*****************************************************************************
public OncvarTimeShutdownChange(Handle:cvar, const String:oldVal[], const String:newVal[]){
//*****************************************************************************
#if defined DEBUG 
PrintToServer("***********************************************************************");
PrintToServer(PLUGIN_NAME);
PrintToServer("***********************************************************************");
PrintToServer("OncvarTimeShutdownChange");
#endif
new newValue;
newValue=StringToInt(newVal);
if (newValue==-2)
	status=2;
else if (newValue==-1)
	{
	status=1;
	PrintHintTextToAll("Server will be shutdown at the end of this round");	
	}
else if (!(0<=newValue &&	newValue<=23))
	SetConVarString(cvarTimeShutdown,oldVal);

H_shutdown=GetConVarInt(cvarTimeShutdown);
#if defined DEBUG 
PrintToServer("***********************************************************************");
PrintToServer("k_shutdown change to %d",H_shutdown);
PrintToServer("***********************************************************************");
#endif
if (status!=1)
	{
	if (GetHour()>=H_shutdown) 
		status=2;
	else
		status=0;
	}	
#if defined DEBUG 	
PrintToServer("status=%d",status);
#endif
}

//*****************************************************************************
public EventRoundStart(Handle:event, const String:name[], bool:dontBroadcast){
//*****************************************************************************
#if defined DEBUG 
PrintToServer("***********************************************************************");
PrintToServer(PLUGIN_NAME);
PrintToServer("***********************************************************************");
PrintToServer("RoundStart");
new String:time[12];
FormatTime(time, 9, "%H:%M:%S",GetTime());
PrintToServer("Curent time is %s",time);
PrintToChatAll("Curent time is %s",time);
PrintToServer("status before =%d",status);	
PrintToChatAll("status before =%d",status);
#endif
if (status==2) return;
if (status==1) 
	{
	PrintHintTextToAll("Server shutdown");	
	new i_max=GetMaxClients();
	for (new i = 1; i <i_max ; i++)
		if (IsClientInGame(i))
			if (!IsFakeClient(i))
				ClientCommand(i,"%s","quit");
	status=2;				
	ServerCommand("%s","quit");
	return;
	}
if (GetHour()>=H_shutdown)
	{
	status=1;
	PrintHintTextToAll("This is last round");
	}
#if defined DEBUG 
PrintToServer("status after =%d",status);	
PrintToChatAll("status after =%d",status);
#endif
	
}
//*****************************************************************************
public Action:sStatus(client, args){	
//*****************************************************************************
new String:time[12];
PrintToServer("plugin Shutdown status:");
PrintToServer("----------------");
PrintToServer("k_shutdown=%d",H_shutdown);
switch status do
	{
	 case 0:strcopy(time,12,"Normal");
	 case 1:strcopy(time,12,"Shutdown");
	 case 2:strcopy(time,12,"Paused");
	 default: strcopy(time,12,"Unknown"); 
	}
PrintToServer("Plugin status is %s",time);


FormatTime(time, 9, "%H:%M:%S",GetTime());
PrintToServer("Curent time is %s",time);
PrintToServer("----------------");
}

//*****************************************************************************
GetHour(){
//*****************************************************************************
decl String:Hour[3];
FormatTime(Hour, 3, "%H",GetTime());
return StringToInt(Hour);
}



/*
FormatTime
%a abbreviated weekday name (Sun) 
%A full weekday name (Sunday) 
%b abbreviated month name (Dec) 
%B full month name (December) 
%c date and time (Dec 2 06:55:15 1979) 
%d day of the month (02) 
%H hour of the 24-hour day (06) 
%I hour of the 12-hour day (06) 
%j day of the year, from 001 (335) 
%m month of the year, from 01 (12) 
%M minutes after the hour (55) 
%p AM/PM indicator (AM) 
%S seconds after the minute (15) 
%U Sunday week of the year, from 00 (48) 
%w day of the week, from 0 for Sunday (6) 
%W Monday week of the year, from 00 (47) 
%x date (Dec 2 1979) 
%X time (06:55:15) 
%y year of the century, from 00 (79) 
%Y year (1979) 
*/
