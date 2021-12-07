// example for the socket extension

#include <sourcemod>
#include <socket>
new Handle:socketReceive;
new String:CHALLENGE[5];
new bool:truncate=false;
new bool:pariteImpair=false;
new String:RuleName[128];
new String:RuleValue[128];

public Plugin:myinfo = {
	name = "server details",
	author = "Player",
	description = "This example allow you to get information about source servers",
	version = "1.1.0",
	url = "moty.lesley@yahoo.fr"
};


public OnPluginStart(){
	RegConsoleCmd("sm_ping",Command_Say);
	RegConsoleCmd("sm_challenge",Command_Say1);
	RegConsoleCmd("sm_details",Command_Say2);
	RegConsoleCmd("sm_details2",Command_Say3);
	RegConsoleCmd("sm_ping2",Command_Say4);
	socketReceive = SocketCreate(SOCKET_UDP, OnSocketError);
	SocketConnect(socketReceive, OnSocketConnected, OnSocketReceive, OnSocketDisconnected,"192.168.0.12",27015);
}

public Handle:initialiseSocket(Handle:socket,String:AddrIP[],Port)
{	
	socket = SocketCreate(SOCKET_UDP, OnSocketError);
	SocketConnect(socket, OnSocketConnected, OnSocketReceive, OnSocketDisconnected,AddrIP,Port);
	return socket;
}

public Action:Command_Say4(client, args)
{
	
	new numcmd=GetCmdArgs(); 
	if(numcmd!=2)
	{
		PrintToServer("number argument isn't good!!!");
		return Plugin_Handled;
	}
	
	new String:AddrIP[20];
	new String:Port[20];
	GetCmdArg(1,AddrIP,sizeof(AddrIP));
	GetCmdArg(2,Port,sizeof(Port));
	new String:buffer[]="ÿÿÿÿi";
	SocketSendTo(socketReceive, buffer,sizeof(buffer),AddrIP,StringToInt(Port));
	return Plugin_Continue;
}

public Action:Command_Say(client, args)
{
	new numcmd=GetCmdArgs(); 
	if(numcmd!=2)
	{
		PrintToServer("number argument isn't good!!!");
		return Plugin_Handled;
	}
	
	new String:AddrIP[20];
	new String:Port[20];
	GetCmdArg(1,AddrIP,sizeof(AddrIP));
	GetCmdArg(2,Port,sizeof(Port));
	new String:buffer[]="ÿÿÿÿTSource Engine Query";
	SocketSendTo(socketReceive, buffer,sizeof(buffer),AddrIP,StringToInt(Port));
	return Plugin_Handled;
}

public Action:Command_Say1(client, args)
{
	new numcmd=GetCmdArgs(); 
	if(numcmd!=2)
	{
		PrintToServer("number argument isn't good!!!");
		return Plugin_Handled;
	}
	
	new String:AddrIP[20];
	new String:Port[20];
	GetCmdArg(1,AddrIP,sizeof(AddrIP));
	GetCmdArg(2,Port,sizeof(Port));
	new String:buffer[]="ÿÿÿÿUÿÿÿÿ";
	SocketSendTo(socketReceive, buffer,sizeof(buffer),AddrIP,StringToInt(Port));
	return Plugin_Continue;
}

public Action:Command_Say2(client, args)
{
	new numcmd=GetCmdArgs(); 
	if(numcmd!=2)
	{
		PrintToServer("number argument isn't good!!!");
		return Plugin_Handled;
	}
	
	new String:AddrIP[20];
	new String:Port[20];
	GetCmdArg(1,AddrIP,sizeof(AddrIP));
	GetCmdArg(2,Port,sizeof(Port));
	new String:buffer[20];
	strcopy(buffer,sizeof(buffer),"ÿÿÿÿU");
	StrCat(buffer,sizeof(buffer),CHALLENGE); 
	SocketSendTo(socketReceive, buffer,sizeof(buffer),AddrIP,StringToInt(Port));
	return Plugin_Handled;
}

public Action:Command_Say3(client, args)
{
	new numcmd=GetCmdArgs(); 
	if(numcmd!=2)
	{
		PrintToServer("number argument isn't good!!!");
		return Plugin_Handled;
	}
	
	new String:AddrIP[20];
	new String:Port[20];
	GetCmdArg(1,AddrIP,sizeof(AddrIP));
	GetCmdArg(2,Port,sizeof(Port));
	new String:buffer[20];
	strcopy(buffer,sizeof(buffer),"ÿÿÿÿV");
	StrCat(buffer,sizeof(buffer),CHALLENGE); 
	SocketSendTo(socketReceive, buffer,sizeof(buffer),AddrIP,StringToInt(Port));
	return Plugin_Handled;
}

public OnSocketConnected(Handle:socket, any:arg) {
	
}

public OnSocketError(Handle:socket, const errorType, const errorNum, any:hFile) {
	// a socket error occured
	LogError("socket error %d (errno %d)", errorType, errorNum);
	CloseHandle(socket);
}

public OnSocketReceive(Handle:socket, String:receiveData[], const dataSize, any:hFile) {
	// receive another chunk and write it to <modfolder>/dl.htm
	// we could strip the http response header here, but for example's sake we'll leave it in
	new index=4;
	new type=receiveData[index++];
	PrintToServer("type=%d",type);
	if(type==73)
	{
		new version=receiveData[index++];
		
		new String:ServerName[64];
		strcopy(ServerName,sizeof(ServerName),receiveData[index]);
		index+=strlen(ServerName)+1;
		
		new String:MapName[64];
		strcopy(MapName,sizeof(MapName),receiveData[index]);
		index+=strlen(MapName)+1;
		
		new String:GameDirectory[64];
		strcopy(GameDirectory,sizeof(GameDirectory),receiveData[index]);
		index+=strlen(GameDirectory)+1;
		
		new String:GameDescription[64];
		strcopy(GameDescription,sizeof(GameDescription),receiveData[index]);
		index+=strlen(GameDescription)+1;
		
		new AppID=ConvertByteToShort(receiveData[index],receiveData[index+1]);
		index+=2;
		
		new NumberOfPlayers=receiveData[index++];
		
		new MaximumPlayers=receiveData[index++];
		
		new NumberOfBots=receiveData[index++];
		
		new Dedicated=receiveData[index++];
		
		new OS=receiveData[index++];
		
		new Password=receiveData[index++];
		
		new Secure=receiveData[index++];
		
		new String:GameVersion[10];
		strcopy(GameVersion,sizeof(GameVersion),receiveData[index]);
		index+=strlen(GameVersion)+1;
		
		new extraDataFlag=receiveData[index++];
		
		new gamePort=0;
		if(extraDataFlag&0x80){
			gamePort=ConvertByteToShort(receiveData[index],receiveData[index+1]);
			index+=2;
		}
		
		new ServerSteamId;
		if(extraDataFlag&0x10)
		{
			index+=8;
		}
		
		
		decl String:SpectatorPort;
		if(extraDataFlag&0x40)
		{
			index+=2;
		}
		
		decl String:GameTagData[64];
		if(extraDataFlag&0x20)
		{
			strcopy(GameTagData,sizeof(GameTagData),receiveData[index]);
			index+=strlen(GameTagData)+1;
		}
		
		new SteamApplicationID2;
		if(extraDataFlag&0x01)
		{
			SteamApplicationID2=ConvertByteToShort(receiveData[index],receiveData[index+1]);
			index+=2;
		}
		
		PrintToServer("bytes received=%d\tbytes read=%d",dataSize,index);
		PrintToServer("Type : %d",type);
		PrintToServer("Version : %d",version);
		PrintToServer("Server name : %s",ServerName);
		PrintToServer("Curent map name : %s",MapName);
		PrintToServer("Game directory : %s",GameDirectory);
		PrintToServer("Game GameDescription : %s",GameDescription);
		PrintToServer("Steam application ID : %d",AppID);
		PrintToServer("Number of players : %d",NumberOfPlayers);
		PrintToServer("Maximum players : %d",MaximumPlayers);
		PrintToServer("Number of bots : %d",NumberOfBots);
		PrintToServer("Dedicated Server : %c",Dedicated);
		PrintToServer("Operating System : %c",OS);
		PrintToServer("Need password : %d",Password);
		PrintToServer("Secure Server : %d",Secure);
		PrintToServer("Game Version : %s",GameVersion);
		PrintToServer("Extra data flags : %d",extraDataFlag);
		PrintToServer("Game port : %d",gamePort);
		PrintToServer("Game tag Data : %s",GameTagData);
		PrintToServer("Steam application ID : %d",SteamApplicationID2);
		return ;
	}
	else if(type==65)
	{
		strcopy(CHALLENGE,sizeof(CHALLENGE),receiveData[index]);
		index+=strlen(CHALLENGE)+1;
		PrintToServer("Challenge number = %s",CHALLENGE);
		return ;
	}
	else if(type==68)
	{
		new numberPlayer=receiveData[index++];
		PrintToServer("number of player %d",numberPlayer);
		new slot;
		new String:PlayerName[64];
		new Kills;
		new Float:TimeConnected;
		new time;
		new hours;
		new minutes;
		new seconds;
		for(new i=0;i<numberPlayer;i++)
		{
			slot=receiveData[index++];
			strcopy(PlayerName,sizeof(PlayerName),receiveData[index]);
			index+=strlen(PlayerName)+1;
			Kills=ConvertByteToLong(receiveData[index],receiveData[index+1],receiveData[index+2],receiveData[index+3]);
			index+=4;
			TimeConnected=ConvertByteToFloat(receiveData[index],receiveData[index+1],receiveData[index+2],receiveData[index+3]);
			index+=4;
			time=RoundFloat(TimeConnected);
			hours=time/3600;
			time-=hours*3600;
			minutes=time/60;
			time-=minutes*60;
			seconds=time;
			PrintToServer("index:%d\tPlayer name:%s\tFrags:%d\ttime:%dh %dm %ds",slot,PlayerName,Kills,hours,minutes,seconds);
		}
		return ;
	}
	else if(type==106)
	{
		decl String:Content[20];
		strcopy(Content,sizeof(Content),receiveData[index]);
		index+=strlen(Content)+1;
		PrintToServer("Le serveur a repondu avec le message suivant:%s",Content);
	}
	else
	{
		index=9;
		new numPacket=receiveData[index++];
		if(numPacket==0)
		{
			index=17;
			new numRules=ConvertByteToShort(receiveData[index],receiveData[index+1]);
			index+=2;
			PrintToServer("number of rules=%d",numRules);
		}
		else
		{
			index=12;
		}
		
		do{
			if(!pariteImpair)
			{
				if(!truncate)
				{
					strcopy(RuleName,sizeof(RuleName),receiveData[index]);
					index+=strlen(RuleName)+1;
				}
				else
				{
					StrCat(RuleName,sizeof(RuleName),receiveData[index]);
					index+=strlen(receiveData[index])+1;
					truncate=!truncate;
				}
			}
			else
			{
				if(!truncate)
				{
					strcopy(RuleValue,sizeof(RuleValue),receiveData[index]);
					index+=strlen(RuleValue)+1;
				}
				else
				{
					StrCat(RuleValue,sizeof(RuleValue),receiveData[index]);
					index+=strlen(receiveData[index])+1;
					truncate=!truncate;
				}
				PrintToServer("%s %s",RuleName,RuleValue);
			}
			pariteImpair=!pariteImpair;
		}while(index<dataSize);
		if(receiveData[dataSize-1]=='\0')
		{
			truncate=false;
		}
		else
		{
			truncate=true;
			pariteImpair=!pariteImpair;
		}
	}
}

public ConvertByteToShort(byte1,byte2)
{
	new variable=0;
	variable=byte2;
	variable<<=8;
	variable&=0xFF00;
	variable|=byte1;
	return variable;
}

public ConvertByteToLong(byte1,byte2,byte3,byte4)
{
	new variable=0;
	variable|=byte4;
	variable<<=8;
	variable&=0xFFFFFF00;
	variable|=byte3;
	variable<<=8;
	variable&=0xFFFFFF00;
	variable|=byte2;
	variable<<=8;
	variable&=0xFFFFFF00;
	variable|=byte1;
	return variable;
}

public Float:ConvertByteToFloat(byte1,byte2,byte3,byte4)
{
	new Float:variable=0.0;
	variable|=byte4;
	variable<<=8;
	variable&=0xFFFFFF00;
	variable|=byte3;
	variable<<=8;
	variable&=0xFFFFFF00;
	variable|=byte2;
	variable<<=8;
	variable&=0xFFFFFF00;
	variable|=byte1;
	return variable;
}

public OnSocketDisconnected(Handle:socket, any:hFile) {
	// Connection: close advises the webserver to close the connection when the transfer is finished
	// we're done here
	PrintToServer("socket have been disconnected!!!");
	SocketDisconnect(socket);
	CloseHandle(socket);
}

public OnPluginEnd()
{
	CloseHandle(socketReceive);
}