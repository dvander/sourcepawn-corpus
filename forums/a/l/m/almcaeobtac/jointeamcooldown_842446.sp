#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION	"1.1"

public Plugin:myinfo = 
{
    name = "Jointeam cooldown",
    author = "Alm",
    description = "Enables a cooldown between Jointeam commands",
    version = PLUGIN_VERSION,
};

static CoolDownAmount;
static CoolDownTimer[65];

public OnPluginStart()
{
	CreateConVar("jointeam_cooldown_v", PLUGIN_VERSION, "Plugin version.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	RegServerCmd("jointeam_cooldown", CoolDownChange, "<Minutes> Cooldown time in minutes.");

	RegConsoleCmd("jointeam", JoinTeam);

	CoolDownAmount = 3;
}

public Action:CoolDownChange(Args)
{
	if(Args == 0)
	{
		PrintToServer("jointeam_cooldown = %d", CoolDownAmount);
		return Plugin_Handled;
	}

	decl String:Arg[32];
	GetCmdArg(1, Arg, 32);

	decl Test;
	Test = StringToInt(Arg);

	if(Test <= 0)
	{
		PrintToServer("jointeam_cooldown: invalid number");
		return Plugin_Handled;
	}

	CoolDownAmount = Test;

	PrintToServer("jointeam_cooldown has changed to %d", CoolDownAmount);
	return Plugin_Handled;
}

public OnClientPutInServer(Client)
{
	CoolDownTimer[Client] = 0;
}

public PrintTimeLeft(Client)
{
	new Alltime = CoolDownTimer[Client];
	new Minutes = (Alltime / 60);
	new Seconds = (Alltime - (Minutes*60));
	PrintToChat(Client, "[SM] You must still wait %d minutes and %d seconds to switch.", Minutes, Seconds);
	return;
}

public Action:JoinTeam(Client, Args)
{
	if(Client == 0)
	{
		return Plugin_Handled;
	}

	if(CoolDownTimer[Client] > 0)
	{
		PrintTimeLeft(Client);
		return Plugin_Handled;
	}

	decl TimeToWait;
	TimeToWait = (CoolDownAmount * 60);

	CoolDownTimer[Client] = TimeToWait;

	CreateTimer(1.0, SecondTick, Client);

	return Plugin_Continue;
}

public Action:SecondTick(Handle:Timer, any:Client)
{
	if(CoolDownTimer[Client] == 0)
	{
		return Plugin_Handled;
	}

	CoolDownTimer[Client] -= 1;
	
	CreateTimer(1.0, SecondTick, Client);

	return Plugin_Handled;
}