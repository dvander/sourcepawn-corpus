#include <sourcemod>
#include <sdktools>
#pragma semicolon 1
#define VERSION "0.9"

public Plugin:myinfo = {
	name = "ASW Speedtimer",
	author = "Voiderest",
	description = "Shows a timer.",
	version = VERSION,
	url = "N/A"
}

new Handle:showdefault=INVALID_HANDLE;
new Handle:showwelcome=INVALID_HANDLE;
new showtimer[MAXPLAYERS+1];
new Float:timeStart;
new PrevTime;

public OnPluginStart() {
	showdefault = CreateConVar("asw_speedtimer_default", "1", "Default setting for players.",FCVAR_REPLICATED|FCVAR_GAMEDLL|FCVAR_NOTIFY,true,0.0,true,1.0);
	showwelcome = CreateConVar("asw_speedtimer_welcome", "1", "Show welcome message.",FCVAR_REPLICATED|FCVAR_GAMEDLL|FCVAR_NOTIFY,true,0.0,true,1.0);

	RegConsoleCmd("say", Command_Say);
	AddCommandListener(Command_Start, "cl_start");
	AddCommandListener(Command_Start, "cl_forceready");
	AddCommandListener(Command_Start, "cl_ready");
	
	AutoExecConfig(true,"asw_speedtimer");
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
	new String:sTime[]="";
	if(secs < 10)
	{
		FormatEx(sTime, 32, "%d:0%d", mins, secs);
	}
	else
	{
		FormatEx(sTime, 32, "%d:%d", mins, secs);
	}
	//PrintToServer("Time: %s", sTime);
	for (new i = 0; i < MAXPLAYERS+1; i++)
	{
		if(showtimer[i])
		{
			PrintCenterText(i, sTime);
		}
	}
	return Plugin_Continue;
}

public OnClientPostAdminCheck(client) {
	if (GetConVarInt(showwelcome) == 1)
	{
		CreateTimer(10.0, WelcomePlayer, client);
	}
}

public OnClientDisconnect(client){
	showtimer[client]=0;
}

public OnMapStart() {
	timeStart = GetGameTime();
	PrevTime = 0;
}

public OnMapEnd() {
	//PrintToServer("Start: %f",timeStart);
	//PrintToServer("Ended: %f",GetGameTime());
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
 
	if (StrEqual(text[startidx], "!showtimer"))
	{
		if (showtimer[client])
		{
			showtimer[client] = 0;
			PrintToChat(client, "Speedtimer is disabled, say '!showtimer' to toggle.");
		} else {
			showtimer[client] = 1;
			PrintToChat(client, "Speedtimer is enabled, say '!showtimer' to toggle.");
		}
		/* Block the client's messsage from broadcasting */
		return Plugin_Handled;
	}
 
	/* Let say continue normally */
	return Plugin_Continue;
}

public Action:Command_Start(client, const String:command[], argc)
{
	//PrintToServer("+++Start Timer");
	new Float:offset=0.5;
	if(StrEqual(command, "cl_forceready"))
	{
		//PrintToServer("+++cl_forceready");
		offset=5.5;
	}
	/*else
	{
		PrintToServer("+++%s", command);
	}*/
	
	timeStart = GetGameTime()+offset;
	PrevTime = 0;
	CreateTimer(0.9, PrintTime, _, TIMER_REPEAT);
}

public Action:WelcomePlayer(Handle:timer, any:client)
{
	if (GetConVarInt(showdefault) == 1)
	{
		showtimer[client] = 1;
		PrintToChat(client, "Speedtimer is enabled, say '!showtimer' to toggle.");
	}
	else
	{
		showtimer[client] = 0;
		PrintToChat(client, "Speedtimer is disabled, say '!showtimer' to toggle.");
	}
}