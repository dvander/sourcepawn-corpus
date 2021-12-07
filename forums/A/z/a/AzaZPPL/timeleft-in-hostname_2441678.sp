#pragma semicolon 1

#include <sourcemod>

public Plugin myinfo = 
{
	name = "Timeleft-in-Hostname", 
	author = "AzaZPPL", 
	description = "Timeleft in server title or hostname", 
	version = "1.5", 
	url = "https://github.com/AzaZPPL/Timeleft-in-Hostname"
};

Handle g_Timer;

ConVar gCV_Hostname;
ConVar gCV_UpdateTime;
ConVar gCV_Timelimit;

char gC_OldHostname[250];
char gC_NewHostname[250];

int gI_Timeleft;
int gI_OldTimeleft = -1;
char gC_Minutes[5];
char gC_Seconds[5];

public void OnPluginStart()
{
	gCV_UpdateTime = CreateConVar("tih_update", "5.0", "Updates the hostname every x.x seconds.", 0, true, 1.0);
	
	AutoExecConfig(true);
}

public void OnConfigsExecuted()
{
	// Check if its empty.
	if(!gC_OldHostname[0]) {
		GetConvars();
		SetHostnameTime(INVALID_HANDLE);
	}
	
	g_Timer = CreateTimer(gCV_UpdateTime.FloatValue, SetHostnameTime, INVALID_HANDLE, TIMER_REPEAT);
}

public Action SetHostnameTime(Handle h_timer)
{
	GetMapTimeLeft(gI_Timeleft);
	
	// Check if the time isnt going into minus. This can happen when the map has yet to change and the timeleft keeps counting down
	if (gI_Timeleft <= -1) {
		if (gI_Timeleft == gI_OldTimeleft) {
			FormatEx(gC_Minutes, sizeof(gC_Minutes), "%i", gCV_Timelimit.IntValue);
		} else {
			gC_Minutes = "00";
		}
		
		gC_Seconds = "00";
	} else {
		// Set time. If time is less than 10 add a 0.
		FormatEx(gC_Minutes, sizeof(gC_Minutes), "%s%i", ((gI_Timeleft / 60) < 10)? "0" : "", gI_Timeleft / 60);
		FormatEx(gC_Seconds, sizeof(gC_Seconds), "%s%i", ((gI_Timeleft % 60) < 10)? "0" : "", gI_Timeleft % 60);
	}
	
	// Check if {{timeleft}} is filled in and replace it with time
	if (StrContains(gC_OldHostname, "{{timeleft}}") >= 0) {
		char C_Time[10];
		
		FormatEx(C_Time, sizeof(C_Time), "%s:%s", gC_Minutes, gC_Seconds);
		gC_NewHostname = gC_OldHostname;
		
		ReplaceString(gC_NewHostname, sizeof(gC_NewHostname), "{{timeleft}}", C_Time);
	} else {
		// Making the new hostname
		FormatEx(gC_NewHostname, sizeof(gC_NewHostname), "%s %s:%s", gC_OldHostname, gC_Minutes, gC_Seconds);
	}
	
	// Set the new hostname
	gCV_Hostname.SetString(gC_NewHostname);
	
	// Set the old timeleft
	gI_OldTimeleft = gI_Timeleft;
	
	return Plugin_Continue;
}

public Action GetConvars ()
{
	gCV_Hostname = FindConVar("hostname");
	gCV_Hostname.GetString(gC_OldHostname, 250);
	
	gCV_Timelimit = FindConVar("mp_timelimit");
}

public void OnMapEnd()
{
	// Set the old hostname without anything in the title.
	gCV_Hostname.SetString(gC_OldHostname);
	gCV_Hostname.Close();
	
	gI_OldTimeleft = -1;
	
	KillTimer(g_Timer);
}

public void OnPluginEnd()
{
	gCV_Hostname.SetString(gC_OldHostname);
	gCV_Hostname.Close();
	
	KillTimer(g_Timer);
} 