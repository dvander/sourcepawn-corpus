#include <sourcemod>
#include <colors>
#include <tf2>

new Handle:Tempo[MAXPLAYERS+1] = INVALID_HANDLE;
new Ligado[MAXPLAYERS+1];
new Handle:T_DEFINED = INVALID_HANDLE;

public Plugin:myinfo = {
	name = "Regeneration",
	author = "Nescau",
	description = "Regenerates the target at every defined time",
	version = "2.0",
	url = "http://www.kvkserver.com"
};

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	RegConsoleCmd("sm_regen", REGEN, "");
	T_DEFINED = CreateConVar("sm_regentime", "2.0", "Defines the time of each regen loop", FCVAR_NOTIFY|FCVAR_DONTRECORD);
}

public Action:REGEN(client, args)
{
	if(args == 2)
	{
		new String:argumento[64];
		new String:argumento2[64];
		GetCmdArg(1, argumento, sizeof(argumento));
		GetCmdArg(2, argumento2, sizeof(argumento2));
		new target = FindTarget(client, argumento, true, false);
		if(target == -1)
		{
			return Plugin_Handled;
		}
		new Float:TIME = GetConVarFloat(T_DEFINED);
			
		new valor = StringToInt(argumento2);
		if(valor == 1)
		{
			if(Ligado[client] == 1)
			{
				CPrintToChat(client, "{green}[SM]{default} The player already have regeneration!");
				return Plugin_Handled;
			} else {
				Tempo[target] = CreateTimer(TIME, H_TIMER, target, TIMER_REPEAT);
				Ligado[target] = 1;
				CPrintToChat(target, "{green}[SM]{default} You are regenerating!");
			}
		}
		if(valor != 1)
		{
			if(Ligado[target] == 0)
			{
				CPrintToChat(client, "{green}[SM]{default} The player don't have regeneration!");
				return Plugin_Handled;
			}
			if(Ligado[target] == 1)
			{
				CloseHandle(Tempo[target]);
				Ligado[target] = 0;
				CPrintToChat(target, "{green}[SM]{default} Regeneration off.");
				return Plugin_Handled;
			}
		}
			
	} else {
		CPrintToChat(client, "{green}[SM]{default} Incorrect syntax! Usage: sm_regen <player>."); 
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action:H_TIMER(Handle:timer, any:target)
{
	TF2_RegeneratePlayer(target);
}

public OnClientDisconnect(client)
{
	if(Ligado[client] == 1)
	{
		Ligado[client]=0;
		CloseHandle(Tempo[client]);
	}
}
