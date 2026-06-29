#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.1"
#define PLUGIN_NAME "[AS] Mission Timer"
#define PLUGIN_AUTHOR "kwski43 aka Jacklul"
#define PLUGIN_DESCRIPTION "Shows a mission timer."
#define PLUGIN_URL "http://forums.alliedmods.net/showthread.php?p=1409405"

#define MAXPLAYERS 4

public Plugin:myinfo = {
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
}

new Handle:showdefault=INVALID_HANDLE;
new Handle:showwelcome=INVALID_HANDLE;
new Handle:showad=INVALID_HANDLE;
new Handle:showfinishtime=INVALID_HANDLE;
new Handle:showstartmsg=INVALID_HANDLE;
new Handle:showeveryminute=INVALID_HANDLE;
new Handle:Timer=INVALID_HANDLE;
new showtimer[MAXPLAYERS+1];
new Float:timeStart;
new String:sTime[]="";
new PrevTime;
new finished=0;

public OnPluginStart() {
	CreateConVar("as_missiontimer_version", PLUGIN_VERSION, "Alien Swarm Mission Timer Version", FCVAR_DONTRECORD|FCVAR_NOTIFY);
	
	showdefault = CreateConVar("as_missiontimer_default", "1", "Default setting for players. 1- timer enabled, 0 - timer disabled",FCVAR_REPLICATED|FCVAR_GAMEDLL|FCVAR_NOTIFY,true,0.0,true,1.0);
	showwelcome = CreateConVar("as_missiontimer_welcome", "1", "Show welcome message.",FCVAR_REPLICATED|FCVAR_GAMEDLL|FCVAR_NOTIFY,true,0.0,true,1.0);
	showad = CreateConVar("as_missiontimer_ad", "1", "Show advertisement message.",FCVAR_REPLICATED|FCVAR_GAMEDLL|FCVAR_NOTIFY,true,0.0,true,1.0);
	showstartmsg = CreateConVar("as_missiontimer_showstartmsg", "1", "Show timer started message.",FCVAR_REPLICATED|FCVAR_GAMEDLL|FCVAR_NOTIFY,true,0.0,true,1.0);
	showfinishtime = CreateConVar("as_missiontimer_showfinish", "1", "Show finish time message.",FCVAR_REPLICATED|FCVAR_GAMEDLL|FCVAR_NOTIFY,true,0.0,true,1.0);
	showeveryminute = CreateConVar("as_missiontimer_everyminute", "1", "Show information in chat about every passed minute.",FCVAR_REPLICATED|FCVAR_GAMEDLL|FCVAR_NOTIFY,true,0.0,true,1.0);
	
	RegConsoleCmd("say", Command_Say);
	RegAdminCmd("sm_missiontimer_off", CmdDisableTimer, ADMFLAG_KICK, "Disable timer for all players");
	RegAdminCmd("sm_missiontimer_on", CmdEnableTimer, ADMFLAG_KICK, "Enable timer for all players");
	AddCommandListener(Command_Start, "cl_start");
	//AddCommandListener(Command_Start, "cl_forceready");
	
	HookEvent("mission_success", MissionEnd_PrintResult);
	
	AutoExecConfig(true,"as_missiontimer");
}

public OnMapStart() {
	timeStart = GetGameTime();
	PrevTime = 0;
	finished = 2;
}

public OnMapEnd() {
	KillTimer(Timer);
}

public OnClientPostAdminCheck(client) {
	if (showwelcome)
	{
		CreateTimer(7.0, WelcomePlayer, client);
	}
}

public OnClientDisconnect(client){
	showtimer[client]=0;
}

public Action:WelcomePlayer(Handle:timer, any:client)
{
	if(showad)
		PrintToChat(client, "This Server is running %s %s by %s", PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);
	if (showdefault)
	{
		showtimer[client] = 1;
		PrintToChat(client, "Mission timer is enabled, say '!timer' to disable it for you.");
	}
	else
	{
		showtimer[client] = 0;
		PrintToChat(client, "Mission timer is disabled, say '!timer' to enable it for you.");
	}
}

public Action:Command_Start(client, const String:command[], argc)
{
	if(finished==2)
	{
		new Float:offset=0.5;
		finished = 0;
		timeStart = GetGameTime()+offset;
		PrevTime = 0;
		CreateTimer(1.0, ShowStart);
		Timer = CreateTimer(0.9, PrintTime, _, TIMER_REPEAT);
	}
}

public Action:ShowStart(Handle:timer) {
	if(showstartmsg)
	{
		PrintToChatAll("Mission Timer has started!");
	}
}

public Action:PrintTime(Handle:timer)
{
	new time = RoundToNearest(GetGameTime() - timeStart);
	if(time == PrevTime)
	{
		PrevTime = time;
		return Plugin_Continue;
	}
	else
	{
		PrevTime = time;
	}
	new mins = time/60;
	new secs = time%60;
	if(showeveryminute)
	{
		if(mins==1 && secs==0)
		{
			PrintToChatAll("%d minute has passed!", mins);
		}
		else if(mins>1 && secs==0)
		{
			PrintToChatAll("%d minutes have passed!", mins);
		}
	}
	if(secs < 10)
	{
		FormatEx(sTime, 32, "%d:0%d", mins, secs);
	}
	else
	{
		FormatEx(sTime, 32, "%d:%d", mins, secs);
	}
	for (new i = 1; i <= MAXPLAYERS; i++)
	{
		if(showtimer[i] && IsClientInGame(i))
		{
			PrintCenterText(i, sTime);
		}
	}
	return Plugin_Continue;
}

public Action:CmdDisableTimer(client, args) {
	for (new i = 1; i <= MAXPLAYERS; i++)
	{
		if(IsClientInGame(i))
			showtimer[i]=0;
	}
	PrintToChatAll("Admin Disabled Mission Timer for all players, say '!timer' to enable it for you.");
	return Plugin_Continue;
}

public Action:CmdEnableTimer(client, args) {
	for (new i = 1; i <= MAXPLAYERS; i++)
	{
		if(IsClientInGame(i))
			showtimer[i]=1;
	}
	PrintToChatAll("Admin Enabled Mission Timer for all players, say '!timer' to disable it for you.");
	return Plugin_Continue;
}


public Action:MissionEnd_PrintResult(Handle:event, String:event_name[], bool:dontBroadcast) {
	KillTimer(Timer);
	CreateTimer(6.0, ShowResult);
}

public Action:ShowResult(Handle:timer) {
	if(showfinishtime)
	{
		PrintToChatAll("Mission completed in %s", sTime);
		finished = 1;
	}	
}

public Action:Command_Say(client, args)
{
	new String:text[192];
	GetCmdArgString(text, sizeof(text));
	
	new startidx = 0;
	if (text[0] == '"')
	{
		startidx = 1;
		/* Strip the ending quote, if there is one */
		new len = strlen(text);
		if (text[len-1] == '"')
		{
			text[len-1] = '\0';
		}
	}
	
	if (StrEqual(text[startidx], "!timer"))
	{
		if (showtimer[client])
		{
			showtimer[client] = 0;
			PrintToChat(client, "Mission Timer is disabled, say '!timer' to enable it for you.");
		} else {
			showtimer[client] = 1;
			PrintToChat(client, "Mission Timer is enabled, say '!timer' to disable it for you.");
		}
		/* Block the client's messsage from broadcasting */
		return Plugin_Handled;
	}
	
	/* Let say continue normally */
	return Plugin_Continue;
}