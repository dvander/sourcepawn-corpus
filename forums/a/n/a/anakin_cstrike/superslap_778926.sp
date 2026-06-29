#include <sourcemod>
#include <sdktools>
 
new g_Count[ 33 ];

public Plugin:myinfo =
{
	name = "SuperSlap",
	author = "aNNakin",
	description = "Slap players rapidly",
	version = "2.0",
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	RegAdminCmd("sm_superslap", superslap_cmd, ADMFLAG_SLAY)
}

public Action:superslap_cmd(client, args)
{
	if (  GetCmdArgs() < 4 )
	{
		ReplyToCommand(client, "sm_superslap <target> <power> <interval> <times>");
		return Plugin_Handled;
	}
		
	new String:arg[32], String:arg2[32], String:arg3[6], String:arg4[7];
	new damage,times;
	GetCmdArg(1, arg, sizeof(arg));
	GetCmdArg(2, arg2, sizeof(arg2));
	GetCmdArg(3, arg3, sizeof(arg3));
	GetCmdArg(4, arg4, sizeof(arg4));
	
	new target = FindTarget(client, arg);
	if (target == -1)
		return Plugin_Handled;
	
	new String:s_Admin[ 32 ], String:s_Target[ 32 ];
	GetClientName(client, s_Admin, 31 );
	GetClientName(target, s_Target, 31 );
	
	damage = StringToInt(arg2);
	new Float:interval = StringToFloat(arg3);
	times = StringToInt(arg4);

	new Handle:data = CreateDataPack();
	
	WritePackCell(data,target);
	WritePackCell(data,damage);
	WritePackCell(data,times);
	
	g_Count[ target ] = 0;
	CreateTimer(interval,superslap_task,data,TIMER_REPEAT);
	
	ShowActivity(client,"%s superslaped %s", s_Admin, s_Target);
	PrintToChatAll("%s superslaped %s", s_Admin, s_Target);
	return Plugin_Handled;
}

public Action:superslap_task(Handle:timer, Handle:data)
{
	ResetPack(Handle:data);

	new index = ReadPackCell(Handle:data);
	new damage = ReadPackCell(Handle:data);
	new times = ReadPackCell(Handle:data);

	if(IsPlayerAlive(index))
		SlapPlayer(index, damage);
	else
		KillTimer(timer);

	if(g_Count[index] >= times)
	{
		g_Count[index] = 0;
		return Plugin_Stop;
	}
	
	g_Count[index]++;
	return Plugin_Continue;
}