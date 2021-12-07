#pragma semicolon  1

#include <sourcemod>
#include <regex>
#include <socket>
#include <md5>
#include <curl>

new String:g_sServer[]	= "messenger.hotmail.com";
new g_Port = 1863;
new step;
new String:g_sProtocol[] = "MSNP8";
//new String:g_sPassport_url[] = "https://nexus.passport.com/rdr/pprdr.asp";
new String:g_sBuildver[] = "6.0.0602";
//new String:g_sProd_key[] = "Q1P7W2E4J9R8U3S5";
//new String:g_sProd_id[] = "msmsgs@msnmsgr.com";
new String:g_sLogin_method[] = "TWN";

new String:g_sUser[] = ""; // Your username
new String:g_sPassword[] = ""; // Your password
new String:g_sContactTest[] = ""; // A contact to test starting a chat

new String:g_sPassport_policy[] = "";
new String:g_sNonce[200] = "";

new timeout = 15;
new Handle:g_hSocket;
new Handle:g_hSocket1;
new String:address[2][100];
new String:g_sTicketBufferFile[50];

new Handle:g_hGroups;
new Handle:g_hContacts;
public OnPluginStart(){
	
	RegConsoleCmd("testmsn",CMD_Test);
	g_hGroups = CreateTrie();
	g_hContacts = CreateTrie();
	RegConsoleCmd("send",CMD_Send);
	RegConsoleCmd("send1",CMD_Send1);
	RegConsoleCmd("out",CMD_Out);
	RegConsoleCmd("out1",CMD_Out1);
	BuildPath(Path_SM,g_sTicketBufferFile,sizeof(g_sTicketBufferFile),"data/sm_msn_ticket_temp.txt");

}

public Action:CMD_Send(client,args){
	new String:sBuffer[300];
	GetCmdArg(1,sBuffer,sizeof(sBuffer));
	ReplaceString(sBuffer,sizeof(sBuffer),"\\r\\n","\r\n");
	PrintToServer("Sent: %s",sBuffer);
	SocketSend(g_hSocket,sBuffer);
}

public Action:CMD_Send1(client,args){
	new String:sBuffer[300];
	GetCmdArg(1,sBuffer,sizeof(sBuffer));
	ReplaceString(sBuffer,sizeof(sBuffer),"\\r\\n","\r\n");
	PrintToServer("Sent: %s",sBuffer);
	SocketSend(g_hSocket1,sBuffer);
}
public Action:CMD_Out(client,args){
	SocketSend(g_hSocket,"OUT\r\n"); // Set online status
}

public Action:CMD_Out1(client,args){
	SocketSend(g_hSocket1,"OUT\r\n"); // Set online status
	//SocketDisconnect(g_hSocket1);
}

public Action:CMD_Test(client,args){

	Connect();
	
}
public Connect(){
	step = 0;
	g_hSocket = SocketCreate(SOCKET_TCP, OnSocketError);
	g_hSocket1 = SocketCreate(SOCKET_TCP, OnSocketError);
	SocketSetOption(g_hSocket,SocketKeepAlive,1);
	SocketSetOption(g_hSocket, SocketReceiveTimeout, timeout);
	SocketSetOption(g_hSocket1, SocketReceiveTimeout, timeout);
	SocketConnect(g_hSocket, OnSocketNSConnected, OnSocketNSReceive, OnSocketNSDisconnected, g_sServer, g_Port);
	
}


public OnSocketNSConnected(Handle:socket, any:client) {
	
	PrintToServer("Connected");
	new String:requestStr[1000];
	if(socket == g_hSocket){
	
		Format(requestStr,sizeof(requestStr),"VER 1 %s CVR0\r\n",g_sProtocol);
		
	} else {
		if(step == 2)
			Format(requestStr,sizeof(requestStr),"GET /rdr/pprdr.asp HTTP/1.0\r\n\r\n");
		else if(step == 3){
		
		}	
	}
	SocketSend(socket, requestStr);
	PrintToServer("Sent: %s",requestStr);
}

public OnSocketNSDisconnected(Handle:socket, any:client) {
	// Connection: close advises the webserver to close the connection when the transfer is finished
	// we"re done here
	
	PrintToServer("Disconnected");
	if(step == 1){
		
		SocketConnect(socket, OnSocketNSConnected, OnSocketNSReceive, OnSocketNSDisconnected, address[0], StringToInt(address[1]));
	} else if(step == 3){
		new String:requestStr[600];
		new String:sUserEncoded[100];
		strcopy(sUserEncoded,sizeof(sUserEncoded),g_sUser);
		ReplaceString(sUserEncoded,sizeof(sUserEncoded),"%","%25");
		ReplaceString(sUserEncoded,sizeof(sUserEncoded),"@","%40");
		ReplaceString(sUserEncoded,sizeof(sUserEncoded),".","%2E");
		ReplaceString(sUserEncoded,sizeof(sUserEncoded),"+","%2B");
		ReplaceString(sUserEncoded,sizeof(sUserEncoded),":","%3A");
		ReplaceString(sUserEncoded,sizeof(sUserEncoded),"/","%2F");
		ReplaceString(sUserEncoded,sizeof(sUserEncoded),"!","%21");
		ReplaceString(sUserEncoded,sizeof(sUserEncoded),"*","%2A");
		ReplaceString(sUserEncoded,sizeof(sUserEncoded),"'","%27");
		ReplaceString(sUserEncoded,sizeof(sUserEncoded),"(","%28");
		ReplaceString(sUserEncoded,sizeof(sUserEncoded),")","%29");
		ReplaceString(sUserEncoded,sizeof(sUserEncoded),";","%3B");
		ReplaceString(sUserEncoded,sizeof(sUserEncoded),"=","%3D");
		ReplaceString(sUserEncoded,sizeof(sUserEncoded),"&","%26");
		ReplaceString(sUserEncoded,sizeof(sUserEncoded),"$","%24");
		ReplaceString(sUserEncoded,sizeof(sUserEncoded),",","%2C");
		ReplaceString(sUserEncoded,sizeof(sUserEncoded),"?","%3F");
		ReplaceString(sUserEncoded,sizeof(sUserEncoded),"#","%23");
		ReplaceString(sUserEncoded,sizeof(sUserEncoded),"[","%5B");
		ReplaceString(sUserEncoded,sizeof(sUserEncoded),"]","%5D");
		new String:sPasswordEncoded[100];
		strcopy(sPasswordEncoded,sizeof(sPasswordEncoded),g_sPassword);
		ReplaceString(sPasswordEncoded,sizeof(sPasswordEncoded),"%","%25");
		ReplaceString(sPasswordEncoded,sizeof(sPasswordEncoded),"+","%2B");
		ReplaceString(sPasswordEncoded,sizeof(sPasswordEncoded),":","%3A");
		ReplaceString(sPasswordEncoded,sizeof(sPasswordEncoded),"/","%2F");
		ReplaceString(sPasswordEncoded,sizeof(sPasswordEncoded),"!","%21");
		ReplaceString(sPasswordEncoded,sizeof(sPasswordEncoded),"*","%2A");
		ReplaceString(sPasswordEncoded,sizeof(sPasswordEncoded),"'","%27");
		ReplaceString(sPasswordEncoded,sizeof(sPasswordEncoded),"(","%28");
		ReplaceString(sPasswordEncoded,sizeof(sPasswordEncoded),")","%29");
		ReplaceString(sPasswordEncoded,sizeof(sPasswordEncoded),";","%3B");
		ReplaceString(sPasswordEncoded,sizeof(sPasswordEncoded),"=","%3D");
		ReplaceString(sPasswordEncoded,sizeof(sPasswordEncoded),"@","%40");
		ReplaceString(sPasswordEncoded,sizeof(sPasswordEncoded),"&","%26");
		ReplaceString(sPasswordEncoded,sizeof(sPasswordEncoded),"$","%24");
		ReplaceString(sPasswordEncoded,sizeof(sPasswordEncoded),",","%2C");
		ReplaceString(sPasswordEncoded,sizeof(sPasswordEncoded),"?","%3F");
		ReplaceString(sPasswordEncoded,sizeof(sPasswordEncoded),"#","%23");
		ReplaceString(sPasswordEncoded,sizeof(sPasswordEncoded),"[","%5B");
		ReplaceString(sPasswordEncoded,sizeof(sPasswordEncoded),"]","%5D");
		
		new String:sTicketEncoded[300];
		strcopy(sTicketEncoded,sizeof(sTicketEncoded),g_sNonce);
		Format(requestStr,sizeof(requestStr),"Authorization: Passport1.4 OrgVerb=GET,OrgURL=http%%3A%%2F%%2Fmessenger%%2Emsn%%2Ecom,sign-in=%s,pwd=%s,%s\r\n\r\n",sUserEncoded,sPasswordEncoded,sTicketEncoded);
		new Handle:curl = curl_easy_init();
		
		new CURL_Default_opt[][2] = {
			{_:CURLOPT_NOSIGNAL,		1},
			{_:CURLOPT_NOPROGRESS,		1},
			{_:CURLOPT_TIMEOUT,			30},
			{_:CURLOPT_CONNECTTIMEOUT,	60},
			{_:CURLOPT_VERBOSE,			0}
		};
		new Handle:headers = curl_slist();
		curl_slist_append(headers, requestStr);
		curl_easy_setopt_int_array(curl, CURL_Default_opt, sizeof(CURL_Default_opt));
		//curl_easy_setopt_int(curl, CURLOPT_VERBOSE,1);
		curl_easy_setopt_int(curl, CURLOPT_USE_SSL, 0);
		new Handle:hFile = curl_OpenFile(g_sTicketBufferFile, "w");
		curl_easy_setopt_handle(curl, CURLOPT_WRITEDATA, hFile);
		curl_easy_setopt_string(curl, CURLOPT_URL, "https://login.live.com:443/login2.srf");
		curl_easy_setopt_handle(curl, CURLOPT_HTTPHEADER, headers);//
		curl_easy_setopt_int(curl, CURLOPT_HEADER, 1);
		curl_easy_setopt_int(curl, CURLOPT_SSL_VERIFYPEER, false);
		curl_easy_perform_thread(curl,OnComplete,hFile);
		
		
	} else
		CloseHandle(socket);
}

public OnSocketNSReceive(Handle:socket, String:receiveData[], const dataSize, any:client) {
	
	new String:requestStr[500];
	new String:sPieces[10][300];
	new String:code[4];
	new String:sAddress[2][100];
	static String:sReadingSYN[50000] = "\0";
	new String:sreceiveData[ByteCountToCells(dataSize)];
	strcopy(sreceiveData,dataSize,receiveData);
	static bool:readingSYN;
	strcopy(code,sizeof(code),receiveData);
	
	PrintToServer("Receive: %s",receiveData);
	if(StrContains("QNG",code) != -1){ // Ping answer
		
		if(readingSYN){ // We were reading the data, this is the end of the sync
		
			readingSYN = false;
		
			new pos;
			
			pos = StrContains(sReadingSYN,"LSG");
			new String:part[300];
			new p1;
			
			while(pos != -1){
				p1 = SplitString(sReadingSYN[pos],"\r\n",part,sizeof(part));
				ReplaceString(part,sizeof(part),"\n","");
				ReplaceString(part,sizeof(part),"\r","");
				
				if(StrContains(part,"LSG") != -1){ // List Group
					sPieces[0] = "\0";
					sPieces[1] = "\0";
					sPieces[2] = "\0";
					sPieces[3] = "\0";
					ExplodeString(part," ",sPieces,4,200);
					
					PrintToServer("-- Group received: %s Num: %d",sPieces[2],StringToInt(sPieces[1]));
				} else if(StrContains(part,"LST") != -1){ // List Contacts
					sPieces[0] = "\0";
					sPieces[1] = "\0";
					sPieces[2] = "\0";
					sPieces[3] = "\0";
					sPieces[4] = "\0";
					ExplodeString(part," ",sPieces,5,200);

					PrintToServer("-- Contact received: %s (%s) Groups: %s",sPieces[2],sPieces[1],sPieces[4]);
				}
				
				if(p1 == -1){ // Last One
					
					break;
					
				}
					
				pos += p1;
					
			}
			
			SocketSend(g_hSocket,"CHG 3 NLN 32\r\n"); // Set online status
			
		}
		
	} else if(readingSYN){ // Let's keep buffering
	
		ReplaceString(sreceiveData,dataSize,"\r\n","\r");
		ReplaceString(sreceiveData,dataSize,"\r","\r\n");
		StrCat(sReadingSYN,sizeof(sReadingSYN),sreceiveData);
		
	} else if(StrContains("SYN",code,false) != -1){ // The server will send the data, we gotta buffer then before reading it, as strings maybe in differents packets
		readingSYN = true;
		SocketSend(g_hSocket, "PNG\r\n"); // Ping the server, when we get the response, the sync is done
		
	} else if(StrContains("VER",code,false) != -1){
		Format(requestStr,sizeof(requestStr),"CVR 2 0x0409 winnt 5.1 i386 MSMSGS %s msmsgs %s\r\n",g_sBuildver,g_sUser);
		PrintToServer("Sent: %s",requestStr);
		SocketSend(socket,requestStr);
	}
	else if(StrContains("CVR",code) != -1){
		Format(requestStr,sizeof(requestStr),"USR 3 %s I %s\r\n",g_sLogin_method,g_sUser);
		PrintToServer("Sent: %s",requestStr);
		SocketSend(socket,requestStr);
	}	
	else if(StrContains("XFR",code) != -1){
		if(step == 0){
			ExplodeString(receiveData," ",sPieces,6,200);
			
			PrintToServer("Connect to: %s",sPieces[3]);
			ExplodeString(sPieces[3],":",address,2,100);
			step = 1;
			
			SocketDisconnect(socket);
		} else if (step == 4){
			
			ExplodeString(receiveData," ",sPieces,6,200);
			PrintToServer("Connect to: %s",sPieces[3]);
			ExplodeString(sPieces[3],":",sAddress,2,100);
			ReplaceString(sPieces[5],200,"\r\n","");
			g_hSocket1 = SocketCreate(SOCKET_TCP, OnSocketError);
			new Handle:hPack = CreateDataPack();
			WritePackCell(hPack,1);
			WritePackString(hPack,"0");
			WritePackString(hPack,sPieces[5]);
			SocketSetOption(g_hSocket1,SocketKeepAlive,1);
			SocketSetArg(g_hSocket1, hPack);
			SocketConnect(g_hSocket1,OnSocketSBConnected, OnSocketSBReceive, OnSocketSBDisconnected, sAddress[0], StringToInt(sAddress[1]));
		}
	} else if(StrContains("USR",code) != -1){
		if(step == 1){ // We need to made the TWN auth
			ExplodeString(receiveData," ",sPieces,5,200);
			step = 2;
			
			strcopy(g_sPassport_policy,50,sPieces[2]);
			strcopy(g_sNonce,sizeof(g_sNonce),sPieces[4][StrContains(sPieces[4],"lc")]);
			ReplaceString(g_sNonce,sizeof(g_sNonce),"\r","");
			ReplaceString(g_sNonce,sizeof(g_sNonce),"\n","");
		
			SocketConnect(g_hSocket1, OnSocketNSConnected, OnSocketNSReceive, OnSocketNSDisconnected, "nexus.passport.com", 80);
		} else if(step == 4){ // We've succeded getting connected
			
			SocketSend(g_hSocket,"SYN 1 0\r\n"); // Sync Contacts

		}
			
	} else if(StrContains("CHL",code) != -1){ // Challenges, answer or get disconneted.
		
		ReplaceString(receiveData,dataSize,"\r\n","");
		ExplodeString(receiveData," ",sPieces,3,200);
		
		new String:ChallengeString[100];
		Format(ChallengeString,sizeof(ChallengeString),"%sQ1P7W2E4J9R8U3S5",sPieces[2]);
		
		TrimString(ChallengeString);
		
		new String:MD5ChallengeString[50];
		MD5String(ChallengeString, MD5ChallengeString, sizeof(MD5ChallengeString));
		Format(requestStr,sizeof(requestStr),"QRY 1049 msmsgs@msnmsgr.com 32\r\n%s",MD5ChallengeString);
		PrintToServer("Sent: %s",requestStr);
		SocketSend(g_hSocket,requestStr);
		
	} else if(StrContains("QRY",code) != -1){ // QRY commnand
		
		ExplodeString(receiveData," ",sPieces,2,200);
		
		if(StringToInt(sPieces[1]) == 1049)
			PrintToServer("-- Passed the Challenge");
		
	} else if(StrContains("CHG",code) != -1){ // Your status
	
		ExplodeString(receiveData," ",sPieces,4,200);
		
		PrintToServer("-- Your status is set to: %s",sPieces[2]);

	} else if(StrContains("ILN",code) != -1){ //  Contacts connected status
	
		ExplodeString(receiveData," ",sPieces,6,200);
		
		PrintToServer("-- Contact info: %s (%s) Client ID: %s Status:%s",sPieces[4],sPieces[3],sPieces[5],sPieces[2]);
	
	} else if(StrContains("NLN",code) != -1){ // Contact changed status
		
		ExplodeString(receiveData," ",sPieces,5,200);
		
		PrintToServer("-- Contact changed status: %s (%s) Client ID: %d Status:%s",sPieces[2],sPieces[3],StringToInt(sPieces[4]),sPieces[1]);
	
	} else if(StrContains("FLN",code) != -1){ // Contact changed status
		
		ExplodeString(receiveData," ",sPieces,2,200);
		
		PrintToServer("-- Contact disconnected: %s",sPieces[1]);
	
	} else if(StrContains("RNG",code) != -1){ // Received chat invite
		
		ExplodeString(receiveData," ",sPieces,7,200);
		ReplaceString(sPieces[6],200,"\r\n","");
		PrintToServer("-- Contact invited to chat: %s (%s) IP: %s SB session: %s AuthString: %s",sPieces[6],sPieces[5],sPieces[2],sPieces[1],sPieces[4]);
		
		ExplodeString(sPieces[2],":",sAddress,2,100);
		new Handle:hPack = CreateDataPack();
		WritePackCell(hPack,0);
		WritePackString(hPack,sPieces[1]);
		WritePackString(hPack,sPieces[4]);
		new Handle:hSocket = SocketCreate(SOCKET_TCP, OnSocketError);
		SocketSetArg(hSocket, hPack);
		SocketConnect(hSocket, OnSocketSBConnected, OnSocketSBReceive, OnSocketSBDisconnected, sAddress[0], StringToInt(sAddress[1]));
		
	} else if(StrContains("HTT",code) != -1){
		
		step++;
		SocketDisconnect(g_hSocket1);
	}
	return;
}

public OnSocketSBConnected(Handle:socket, any:hPack) {
	
	PrintToServer("SB Connected");
	
	ResetPack(hPack);
	new type = ReadPackCell(hPack);
	new String:requestStr[1000];
	
	new String:sSessionID[100];
	ReadPackString(hPack,sSessionID,sizeof(sSessionID));
	
	new String:sAuthString[100];
	ReadPackString(hPack,sAuthString,sizeof(sAuthString));
	
	if(type == 0){ // Received the invite
	
		Format(requestStr,sizeof(requestStr),"ANS 1 %s %s %s\r\n",g_sUser,sAuthString,sSessionID);
	
	} else { // Creating the session
	
		Format(requestStr,sizeof(requestStr),"USR 1 %s %s\r\n",g_sUser,sAuthString);
		
	}
	
	SocketSend(socket, requestStr);
	PrintToServer("Sent: %s",requestStr);
}

public OnSocketSBDisconnected(Handle:socket, any:hPack) {

	if(hPack != INVALID_HANDLE)
		CloseHandle(hPack);
		
	PrintToServer("--SB disconnected");
}

public OnSocketSBReceive(Handle:socket, String:receiveData[], const dataSize, any:hPack) {

	PrintToServer("Receive: %s",receiveData);
	new String:requestStr[500];
	new String:sPieces[6][300];
	new String:code[4];
	static msg = 5;
	static bool:receivingMSG;
	strcopy(code,sizeof(code),receiveData);

	if(StrContains("IRO",code,false) != -1){
		
		ExplodeString(receiveData," ",sPieces,6,200);
		
		ReplaceString(sPieces[5],200,"\r\n","");
		
		PrintToServer("-- Contact on the chat (%s/%s): %s (%s)",sPieces[2],sPieces[3],sPieces[5],sPieces[4]);
		
	} else if(StrContains("ANS",code,false) != -1){
		
		PrintToServer("-- Now sending and receiving messages",sPieces[2],sPieces[3],sPieces[5],sPieces[4]);
		
	} else if(receivingMSG || StrContains("MSG",code,false) != -1){
		
		if(receivingMSG || StrContains(receiveData,"Typing") == -1){
			
			static String:sMessageReading[1000] = "\0";
			static size =0;
			static written = 0;
			static String:sPieces2[4][200];
			if(size == 0){
				ExplodeString(receiveData,"\r\n",sPieces,2,200);
				ExplodeString(sPieces[0]," ",sPieces2,4,200);
				size = StringToInt(sPieces2[3]);
				receivingMSG = true;
			}
			if(written == 0){
				StrCat(sMessageReading,size+1,receiveData[StrContains(receiveData,"\r\n")+2]);
				written += strlen(receiveData[StrContains(receiveData,"\r\n")+2]);
				
			} else {
				StrCat(sMessageReading,size+1,receiveData);
				
				written += strlen(receiveData[0]);
			}
			
			PrintToServer("-- Reading message %d/%d",written,size);
			if(written == size){ //Finished reading the message
				
				
				PrintToServer("-- Received message from %s (%s): %s",sPieces2[2],sPieces2[1],sMessageReading);
				sMessageReading = "\0";
				receivingMSG = false;
				written = 0;
				size = 0;
			}
		}
		/*
		PrintToServer("-- Sending received message (%d)",msg);
		
		Format(requestStr,sizeof(requestStr),"MSG %d N 133\r\n  MIME-Version: 1.0\r\n
    Content-Type: text/plain; charset=UTF-8\r\n
    X-MMS-IM-Format: FN=Arial; EF=I; CO=0; CS=0; PF=22\r\n"
		msg++;*/
		//SocketSend(socket,requestStr);
	} else if(StrContains("USR",code,false) != -1){
		Format(requestStr,sizeof(requestStr),"CAL 1 %s\r\n",g_sContactTest);
		SocketSend(socket,requestStr);
	} else if(StrContains("JOI",code,false) != -1){
		
		ExplodeString(receiveData," ",sPieces,3,200);
		
		ReplaceString(sPieces[2],200,"\r\n","");
		
		PrintToServer("-- Contact %s (%s) joined the chat",sPieces[2],sPieces[1]);
		
		new String:sMessageSending[300];
		Format(sMessageSending,sizeof(sMessageSending),"MIME-Version: 1.0\r\nContent-Type: text/plain; charset=UTF-8\r\nX-MMS-IM-Format: FN=MS%20Sans%20Serif; EF=; CO=0; CS=0; PF=0\r\n\r\nI like turtles.");
		Format(requestStr,sizeof(requestStr),"MSG %d U %d\r\n%s",msg,strlen(sMessageSending),sMessageSending);
		
		SocketSend(socket,requestStr);
		msg++;
	}
	
}

public OnSocketError(Handle:socket, const errorType, const errorNum, any:ary) {
	// a socket error occured

	LogError("socket error %d (errno %d)", errorType, errorNum);
	CloseHandle(socket);
}

public OnComplete(Handle:hndl, CURLcode: code,any:data){

	CloseHandle(data);
	
	new String:buffer[1000];
	new Handle:hFile = OpenFile(g_sTicketBufferFile,"r");
	new Handle:hRegex = CompileRegex("\'t=.*\'");
	new matches;
	while(ReadFileLine(hFile,buffer,sizeof(buffer))){
		
		matches =MatchRegex(hRegex,buffer);
		if(matches)
			break;
		
	}
	new String:ticket[1000];
	GetRegexSubString(hRegex,0,ticket,sizeof(ticket));
	//PrintToServer("Ticket Secret = %s",ticket);
	step++;
	TrimString(ticket);
	ReplaceString(ticket,sizeof(ticket),"'","");
	new String:requestStr[1000];
	Format(requestStr,sizeof(requestStr),"USR 4 %s S %s\r\n",g_sLogin_method,ticket);
	PrintToServer("Sent: %s",requestStr);
	SocketSend(g_hSocket,requestStr);
	
}
