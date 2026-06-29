/*
This plugin is under GPL Licence
Author: Jérôme "Hackziner" Andrieu and Juba_PornBorn
email: hackziner@gmail.com
msn: hackziner@hotmail.com << I really answer to question, even if they are silly contrary to TS :)
site: http://www.ufbteam.com
*/
#pragma semicolon 1
#include <socket>
#include <sourcemod>

#define VERSION "2.8" 
#define PLUGIN_VERSION "1.0"
#define FFAC_MASTER_SERVER "82.232.102.55"

new Handle:g_Cvar_MsnAddress = INVALID_HANDLE;

public Plugin:myinfo = 
{
    name = "FFAC_MSN_CONTACT",
    author = "hackziner",
    description = "FFAC: Contact an admin on msn",
    version = PLUGIN_VERSION ,
    url = "http://www.ufbteam.com/"
};

new String:Sdata[4096];
new socket;           


public OnPluginStart()
{
    socket = SocketCreate(SOCKET_UDP, OnSocketError);
    CreateConVar("sm_ffac_msn_bot_version", PLUGIN_VERSION, "by hackziner", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
    //SetDataString(socket, Sdata);
    //ConnectSocket(socket, FFAC_MASTER_SERVER,19863);   
    SocketConnect(socket, OnSocketConnected, OnSocketReceive, OnSocketDisconnected, FFAC_MASTER_SERVER, 19863);
	RegConsoleCmd("say", Command_Say);
    RegConsoleCmd("say2", Command_Say);
    RegConsoleCmd("say_team", Command_Say);
    g_Cvar_MsnAddress=CreateConVar("ffac_msn_contact", "yourmsnadress@hotmail.com", "Contacts msn address");
   
}

public Action:Command_Say(client, args)
{
	decl String:text[192], String:command[64], String:cmd[192];
	GetCmdArgString(text, sizeof(text));
	GetCmdArg(0, command, sizeof(command));
	if (StrContains(text,"!admin",false)!=-1)
	{
		ReplaceString(text, 192, "\"", " ");
		GetConVarString(g_Cvar_MsnAddress, command, 64);
		Format(cmd, 191, "%s\"MSNADM!\"**\"MESS_ONLY\"%s\"%s\"",VERSION , command,text); 
		SocketSend(socket, cmd);
	}


}
public OnSocketConnected(Handle:socket, any:arg)
{   
}

public OnSocketReceive(Handle:socket, String:receiveData[], const dataSize, any:hFile)
{ 
}

public OnSocketDisconnected(Handle:socket, any:hFile) {

	CloseHandle(socket);
}

public OnSocketError(Handle:socket, const errorType, const errorNum, any:hFile) {
	// a socket error occured

	LogError("socket error %d (errno %d)", errorType, errorNum);
	CloseHandle(socket);
}