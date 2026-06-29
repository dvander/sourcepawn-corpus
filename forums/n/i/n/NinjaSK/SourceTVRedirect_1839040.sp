#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

new String:bufferIP[32];
new String:bufferPort[32];
new String:IP[32];
new String:password[32];

public Plugin:myinfo =
{
	name = "SourceTV Redirect",
	author = "NinjaSK",
	description = "Type !stv | !sourcetv | /stv | /sourcetv in chat to redirect to your server's SourceTV",
	version = "1.1"
}

new Handle:cVar_ServerIP = INVALID_HANDLE;
new Handle:cVar_ServerPort = INVALID_HANDLE;
new Handle:cVar_ServerPassword = INVALID_HANDLE;

public OnPluginStart()
{	
	RegConsoleCmd("sm_stv", Command_Redirect);
	RegConsoleCmd("sm_sourcetv", Command_Redirect);
	cVar_ServerIP = CreateConVar("sm_stv_serverip", "-1", "Server IP");
	HookConVarChange(cVar_ServerIP, OnIpChange);	
	cVar_ServerPort = CreateConVar("sm_stv_serverport", "-1", "Server Port");
	HookConVarChange(cVar_ServerPort, OnPortChange);
	cVar_ServerPassword = CreateConVar("sm_stv_serverpassword", "-1", "Server Password");
	HookConVarChange(cVar_ServerPassword, OnPasswordChange);
	AutoExecConfig(true);
}
 
 public OnMapStart()
 {
 	GetConVarString(cVar_ServerIP,bufferIP,sizeof(bufferIP));
	GetConVarString(cVar_ServerPort,bufferPort,sizeof(bufferPort));
	Format(IP, sizeof(IP),"%s:%s", bufferIP, bufferPort);
}
 
public Action:Command_Redirect(client,args)
{
	if(!client)
		return Plugin_Handled;
	
	if(!strcmp(bufferIP,"-1",false)||!strcmp(bufferPort,"-1",false))
	{
		ReplyToCommand(client,"This Command Is Not Ready.");
		return Plugin_Handled;
	}
	
	SetClientInfo(client,"password",password);
	
	DisplayAskConnectBox(client, 30.0, IP);
	return Plugin_Handled;
}

public OnIpChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	strcopy(bufferIP,sizeof(bufferIP),newVal);
	Format(IP, sizeof(IP),"%s:%s", bufferIP, bufferPort);
}

public OnPortChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	strcopy(bufferPort,sizeof(bufferPort),newVal);
	Format(IP, sizeof(IP),"%s:%s", bufferIP, bufferPort);
}

public OnPasswordChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	strcopy(password,sizeof(password),newVal);
}