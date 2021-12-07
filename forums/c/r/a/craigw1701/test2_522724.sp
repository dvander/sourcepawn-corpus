#pragma semicolon 1
#include <sockets>
#include <sourcemod>

public Plugin:myinfo = 
{
    name = "SocketTest",
    author = "Olly",
    description = "Sockets test",
    version = "1.0",
    url = "http://www.gameconnect.info/"
};

new String:Sdata[4096];
new socket;
new Bool:socketConnected = false;
new int:result2 = 0;

public SocketReceive(size)
{
 PrintToServer("=====[Received]=====\n=====[Size: %d]=====\n=====%s=====\n\n",size,Sdata);
		SetDataString(socket, Sdata);

}              

public SocketError(id, detail)
{
    // Error ID's for Windows: http://msdn2.microsoft.com/en-us/library/ms740668.aspx
    if(id == EMPTY_HOST)
    {
        PrintToServer("Error: Missing Host");
    }
    else if(id == NO_HOST)
    {
        PrintToServer("Error: Could not resolve domain name");
    }
    else if(id == CONNECT_ERROR)
    {
        PrintToServer("Error during connection. Error ID: %d", detail);
    }
    else if(id == SEND_ERROR)
    {
        PrintToServer("Error sending data. Error ID: %d", detail);
    }
    else if(id == BIND_ERROR)
    {
        PrintToServer("Error binding address. Error ID: %d", detail);
    }
    else if(id == RECV_ERROR)
    {
        PrintToServer("Error receiving data. Error ID: %d", detail);
    }
	else
	{
		LogMessage("ERROR, HELP! eeek!");	
	}
	
}

public Action:Command_Disconnect(client, args)
{
		
	//if(SocketSend(socket, "PING") == 0)
	if(socketConnected)
	{
		PrintToServer("Disconnected from Server");
		LogMessage("Close Socket: %d", result2++);
		
		new Bool:result3 =  SocketClose(socket);
			
		
		if(result3)
		{
				PrintToServer("Closed!");
		}
		
		
	}	
	socketConnected = false;
}

public OnPluginStart()
{
	RegAdminCmd("Serv_Send", Command_ServSend, ADMFLAG_CHAT, "Serv_Send <message> - sends message to Server");
	RegAdminCmd("Serv_Connect", Command_Connect, ADMFLAG_CHAT, "Serv_Connect - Connects to server");
	RegAdminCmd("Serv_Disconnect", Command_Disconnect, ADMFLAG_CHAT, "Serv_Disconnect - Disconnects to server");
	
	}

public Action:Command_Connect(client, args)
{
	if(socketConnected == false)
	{
		// Create the new socket, and set the protocol to TCP
	    socket = CreateSocket(SOCKET_TCP);
	    
	    // Set the callbacks
	    SetErrorCallback(socket, SocketError);
	    SetReceiveCallback(socket, SocketReceive);
		//SetDisconnectCallback(socket, SocketDisconnect);
	    
	    // Set the output data string (must be 4096 bytes)
	    SetDataString(socket, Sdata);
	    
	    // Connect the socket to irc.gamesurge.net, on port 6667
	    //new Bool:result = ConnectSocket(socket, "irc.gamesurge.net", 6667);
	    new Bool:result = ConnectSocket(socket, "127.0.0.1", 9050);
		
		if(result)
		{
	    
		    // Send a command to the irc server
		    //SocketSend(socket, "PING");  
			socketConnected = true;
		}
		else
		{
			LogMessage("ERROR, Server not connected!");	
		}
	}
	else
	{
		LogMessage("ERROR, Server Already Connected!");		
	}
}

/*public Action:Command_Disconnect(client, args)
{
	SocketDisconnect();
}*/

public Action:Command_ServSend(client, args)
{
	if(socketConnected == true)
	{
		decl String:text[192];
		GetCmdArgString(text, sizeof(text));

		new String:name[64];
		GetClientName(client, name, sizeof(name));
		
		
		// Set the output data string (must be 4096 bytes)
	    SetDataString(socket, Sdata);
	    
		
	    // Connect the socket to irc.gamesurge.net, on port 6667
	    //ConnectSocket(socket, "irc.gamesurge.net", 6667);
	    //ConnectSocket(socket, "127.0.0.1", 9050);
		
		SocketSend(socket, text);  
		LogMessage("%L triggered sm_test1 (text %s)", client, text);
		
	}
	else
	{
		LogMessage("ERROR, Server not connected!");
	}
	return Plugin_Handled;		
}
/*
public OnPluginEnd()
{		
	socketConnected = false;	
	//SocketDisconnect();
	LogMessage("Close Socket 5: %d", result2++);
}*/
