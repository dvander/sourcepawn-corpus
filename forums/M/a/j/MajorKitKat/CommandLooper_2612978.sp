#include <sourcemod>
#include <sdktools>

//Global variables, Cause you know. I'm bad with names.
bool loopEnd = false;
char Usercommand[32];
float timeM = 0.0;

public Plugin:myinfo = 
{
	name = "Timed Command Looper",
	author = "?~Kit-kats Hershey~?",
	description = "Loops a given command every given time until told to stop.",
	version = "0.0.1",
	url = "https://steamcommunity.com/groups/Majors-Fun-Servers"
}

public OnPluginStart()
{
	//Start command.
	RegAdminCmd("sm_loop", GetCommand, ADMFLAG_ROOT);
	//Various Stop commands incase you need to do it manually in a pinch.
	RegAdminCmd("sm_sl", EndLoop, ADMFLAG_ROOT);
	RegAdminCmd("sm_loopstop", EndLoop, ADMFLAG_ROOT);
	RegAdminCmd("sm_ls", EndLoop, ADMFLAG_ROOT);
	RegAdminCmd("sm_endloop", EndLoop, ADMFLAG_ROOT);
	RegAdminCmd("sm_loopend", EndLoop, ADMFLAG_ROOT);
	RegAdminCmd("sm_noloop", EndLoop, ADMFLAG_ROOT);
	RegAdminCmd("sm_loopno", EndLoop, ADMFLAG_ROOT);
	RegAdminCmd("sm_stoploop", EndLoop, ADMFLAG_ROOT);
}

public Action:EndLoop(client, args)
{
	//Sets LoopEnd to true so it can be stopped later on in the timer.
	loopEnd = true;
	return Plugin_Handled;
}
public Action:GetCommand(client, args)
{
	//Checks to make sure you guys are putting in the right number of arguments.
	if(args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_loop <Time in minutes> \"Command Args\"");
		return Plugin_Handled;	
	}
	//Grabs the arguments revieved from the command and stores them.
	char time_S[25];
	GetCmdArg(1, time_S, sizeof(time_S));
	GetCmdArg(2, Usercommand, sizeof(Usercommand));
	//If you need to use "" in your commands, this ensures it works.
	ReplaceString(Usercommand, sizeof(Usercommand), "'","\"")
	//Converts time in seconds to minutes.
	timeM = StringToFloat(time_S)*60;
	
	//Calls the loop void and returns the plugin handled.
	loop(timeM);
	
	return Plugin_Handled;
}
//I used a void so I didn't have to return any values.
void loop(float timeF)
{
	//The time was passed in the float of time in minutes now as timeF and sends it to ExecuteCommand Action every *timeF
	CreateTimer(timeF, ExecuteCommand, _, TIMER_REPEAT);
}

public Action ExecuteCommand(Handle timer)
{
	//Checks to see if LoopEnd now equals true, if so it stops the loop.
	if(loopEnd == true)
	{
		return Plugin_Stop;
	}
	//Executes the command and returns to the timer.
	ServerCommand("%s", Usercommand)
	return Plugin_Continue;
}