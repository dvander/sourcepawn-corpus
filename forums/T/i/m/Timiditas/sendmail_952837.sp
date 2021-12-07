#include <sourcemod>
#include <sdktools>

#include <base64>

//#undef REQUIRE_EXTENSIONS
#include <socket>

new bool:socket_available = false;
new Handle:Stuff, Handle:msg_data;
new Handle:gsocket = INVALID_HANDLE;
new Status = 0;
/*
public bool:AskPluginLoad(Handle:myself, bool:late, String:error[], err_max)
{
	MarkNativeAsOptional("SocketSend");
	MarkNativeAsOptional("SocketCreate");
	MarkNativeAsOptional("SocketSetArg");
	MarkNativeAsOptional("SocketConnect");
	return true;
}

public Action:cmd_reload(client, args)
{
	new String:myFile[255];
	GetPluginFilename(INVALID_HANDLE, myFile, sizeof(myFile));
	ServerCommand("sm plugins reload %s", myFile);
}

public OnLibraryRemoved(const String:name[]) {	socket_available = (GetExtensionFileStatus("socket.ext") == 1); }
public OnLibraryAdded(const String:name[]) {	socket_available = (GetExtensionFileStatus("socket.ext") == 1); }
*/
public OnPluginStart()
{
	//socket_available = (GetExtensionFileStatus("socket.ext") == 1);
	RegConsoleCmd("smsendmail", sOpen);
	//RegAdminCmd("smreload", cmd_reload, ADMFLAG_BAN, "Reload plugin"); //<- for testing during development. this is faster than "sm plugins reload sendmail" :)
}
public Action:sOpen(client, args)
{

	if (args != 8)
	{
		ReplyToCommand(client, "usage: smsendmail \"SMTP hostname/IP\" port \"username\" \"password\" \"sender email\" \"recipient email\" \"subject\" \"message text\"");
		ReplyToCommand(client, "enclose every string in quotation marks");
	}
	else
	{
		new String:cmd[8][255], String:cData[1024];
		for(new i=1;i<8;i++)
		{
			GetCmdArg(i, cmd[i], 255);
		}
		GetCmdArg(8, cData, sizeof(cData));
		SendSMTPMail(cmd[1], StringToInt(cmd[2]), cmd[3], cmd[4], cmd[5], cmd[6], cmd[7], cData);
	}
	return Plugin_Handled;
}
SendSMTPMail(String:Host[255], Port, String:Username[255], String:Password[255], String:From[255], String:To[255], String:Subject[255], String:MessageData[1024])
{
	if(!socket_available)
	{
		LogError("Socket extension not found");
		return;
	}
	if(Status > 0)
	{
		LogError("Sendmail already in progress");
		return;
	}
	Stuff = CreateArray(ByteCountToCells(255));
	msg_data = CreateArray(ByteCountToCells(1024));
	new String:strBuffer[255];
	EncodeBase64(strBuffer, sizeof(strBuffer), Username);
	PushArrayString(Stuff, strBuffer);
	EncodeBase64(strBuffer, sizeof(strBuffer), Password);
	PushArrayString(Stuff, strBuffer);
	PushArrayString(Stuff, From);
	PushArrayString(Stuff, To);
	PushArrayString(Stuff, Subject);
	PushArrayString(msg_data, MessageData);
	gsocket = SocketCreate(SOCKET_TCP, OnSocketError);
	SocketSetOption(gsocket, SocketSendTimeout, 10000);
	SocketConnect(gsocket, OnSocketConnected, OnSocketReceive, OnSocketDisconnected, Host, Port);
}

public OnSocketConnected(Handle:socket, any:arg)
{
	PrintToServer("Socket connected");
}

public OnSocketReceive(Handle:socket, String:receiveData[], const dataSize, any:hFile) {
	new String:cOut[2048];
	new String:s_ret[4];
	Format(s_ret, (4), receiveData);
	new h_ret = StringToInt(s_ret);
	decl String:requestStr[100];
	
	switch (Status)
	{
		case 0:
		{
			if(h_ret != 220)
			{
				SMTPError(h_ret);
				return;
			}
			new Handle:CV_hostip = FindConVar("hostip"), String:Client[255];
			GetConVarString(CV_hostip, Client, sizeof(Client));
			CloseHandle(CV_hostip);
			Format(requestStr, sizeof(requestStr), "EHLO %s\r\n", Client);
			Status = 1;
			SocketSend(socket, requestStr);
		}
		case 1:
		{
			if(h_ret != 250)
			{
				SMTPError(h_ret);
				return;
			}
			Format(requestStr, sizeof(requestStr), "AUTH LOGIN\r\n");
			Status = 2;
			SocketSend(socket, requestStr);
		}
		case 2:
		{
			if(h_ret != 334)
			{
				SMTPError(h_ret);
				return;
			}
			GetArrayString(Stuff, 0, cOut, sizeof(cOut));
			Format(requestStr, sizeof(requestStr), "%s\r\n", cOut);
			Status = 3;
			SocketSend(socket, requestStr);
		}
		case 3:
		{
			if(h_ret != 334)
			{
				SMTPError(h_ret);
				return;
			}
			GetArrayString(Stuff, 1, cOut, sizeof(cOut));
			Format(requestStr, sizeof(requestStr), "%s\r\n", cOut);
			Status = 4;
			SocketSend(socket, requestStr);
		}
		case 4:
		{
			if(h_ret != 235)
			{
				SMTPError(h_ret);
				return;
			}
			GetArrayString(Stuff, 2, cOut, sizeof(cOut));
			Format(requestStr, sizeof(requestStr), "MAIL FROM: <%s>\r\n", cOut);
			Status = 5;
			SocketSend(socket, requestStr);
		}
		case 5:
		{
			if(h_ret != 250)
			{
				SMTPError(h_ret);
				return;
			}
			GetArrayString(Stuff, 3, cOut, sizeof(cOut));
			Format(requestStr, sizeof(requestStr), "RCPT TO: <%s>\r\n", cOut);
			Status = 6;
			SocketSend(socket, requestStr);
		}
		case 6:
		{
			if(h_ret != 250)
			{
				SMTPError(h_ret);
				return;
			}
			Format(requestStr, sizeof(requestStr), "DATA\r\n", cOut);
			Status = 7;
			SocketSend(socket, requestStr);
		}
		case 7:
		{
			if(h_ret != 354)
			{
				SMTPError(h_ret);
				return;
			}
			new String:sFrom[255], String:sTo[255], String:sSubject[255], String:msg_text[1024], String:BigQuery[1800];
			GetArrayString(Stuff, 2, sFrom, sizeof(sFrom));
			GetArrayString(Stuff, 3, sTo, sizeof(sTo));
			GetArrayString(Stuff, 4, sSubject, sizeof(sSubject));
			GetArrayString(msg_data, 0, msg_text, sizeof(msg_text));
			Format(BigQuery, sizeof(BigQuery), "FROM: <%s>\r\nTo: <%s>\r\nSubject: %s\r\n\r\n%s\r\n.\r\n", sFrom, sTo, sSubject, msg_text);
			Status = 8;
			SocketSend(socket, BigQuery);
		}
		case 8:
		{
			if(h_ret != 250)
			{
				SMTPError(h_ret);
				return;
			}
			Format(requestStr, sizeof(requestStr), "QUIT\r\n");
			Status = 9;
			SocketSend(socket, requestStr);
		}
		case 9:
		{
			LogMessage("Mail sent!");
			Finish();
		}
	}
}

public OnSocketDisconnected(Handle:socket, any:hFile)
{
	PrintToServer("socket closed");
	Finish();
}

public OnSocketError(Handle:socket, const errorType, const errorNum, any:hFile)
{
	PrintToServer("socket error %d (errno %d)", errorType, errorNum);
	Finish();
}
Finish()
{
	CloseHandle(gsocket);
	CloseHandle(Stuff);
	CloseHandle(msg_data);
	Status = 0;
}
SMTPError(errnum)
{
	LogError("Error sending mail: %i", errnum);
	Finish();
}