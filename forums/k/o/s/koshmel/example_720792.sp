// example for the socket extension

#include <sourcemod>
#include <socket>

new String:UploadFileName[30]=""; 
new SendTime=0;
new String:Result[50]="";
public Plugin:myinfo = {
	name = "Test",
	author = "koshmel",
	description = "NULL",
	version = "HORROR",
	url = "koshmel@gmail.com"
};
 
public UploadFile(String:FileName[30]) {
	SendTime=GetTime();
	UploadFileName=FileName
	new Handle:socket = SocketCreate(SOCKET_TCP, OnSocketError);
	// open a file handle for writing the result
	new Handle:SFile = OpenFile("result.txt", "wb");
	// pass the file handle to the callbacks
	SocketSetArg(socket, SFile);
	// connect the socket
	SocketConnect(socket, OnSocketConnected, OnSocketReceive, OnSocketDisconnected, "rs180cg.rapidshare.com", 80)
}
public OnSocketConnected(Handle:socket, any:SFile) {
	// socket is connected, send the http request
	decl Buff[1001];
	decl String:head[500];
	decl String:strend[500];
	new ContentL=0;
	new String:Bou[30]="--------111008170141884";
	new Handle:OFile = OpenFile(UploadFileName, "rb");
	//Do not Change strend and head
	Format(strend, sizeof(strend), "\r\n--%s\r\nContent-Disposition: form-data; name=\"freeaccountid\"\r\n\r\n3518657\r\n--%s\r\nContent-Disposition: form-data; name=\"password\"\r\n\r\n54321\r\n--%s--\r\n",Bou,Bou,Bou);
	ContentL=454+FileSize(UploadFileName)+strlen(UploadFileName);
	Format(head, sizeof(head), "POST /cgi-bin/upload.cgi HTTP/1.0\r\nContent-Type: multipart/form-data; boundary=%s\r\nContent-Length: %i\r\n\r\n--%s\r\nContent-Disposition: form-data; name=\"toolmode2\"\r\n\r\n1\r\n--%s\r\nContent-Disposition: form-data; name=\"filecontent\"; filename=\"%s\"\r\nContent-Type: multipart/form-data\r\nContent-Transfer-Encoding: binary\r\n\r\n",Bou,ContentL,Bou,Bou,UploadFileName);
	SocketSend(socket,head);
	PrintToServer("Upload:%s",UploadFileName);
	new BuffL=0;
	while (!IsEndOfFile(OFile))
		{
			BuffL=ReadFile(OFile, Buff, 1000,4);
			if (BuffL<1000)
				{BuffL=FileSize(UploadFileName)%4000;}
				else{BuffL=4000;}
			SocketSend(socket,Buff,BuffL);
		}
	SocketSend(socket,strend);
	CloseHandle(OFile);
}

public OnSocketReceive(Handle:socket, String:receiveData[], const dataSize, any:SFile) {
	new DelPos=-1;
	DelPos=StrContains(receiveData,"http://");
	if DelPos==-1
	{
		Result="Error";
	}
	else {
			
			SplitString(receiveData,"\r\n", Result,50);
		}
	
	// receive another chunk and write it to <modfolder>/dl.htm
	// we could strip the http response header here, but for example's sake we'll leave it in
	PrintToServer("<<incoming %i bytes>>",dataSize);
	SendTime=GetTime()-SendTime;
	PrintToServer("<<SendTime %i sec>>",SendTime);
	WriteFileString(SFile, receiveData, false);
	StrContains(receiveData,"http://");
}

public OnSocketDisconnected(Handle:socket, any:SFile) {
	// Connection: close advises the webserver to close the connection when the transfer is finished
	// we're done here

	CloseHandle(SFile);
	CloseHandle(socket);
}
public SendBinaryFile(Handle:socket,OFile) {

}

public OnSocketError(Handle:socket, const errorType, const errorNum, any:SFile) {
	// a socket error occured

	LogError("socket error %d (errno %d)", errorType, errorNum);
	CloseHandle(SFile);
	CloseHandle(socket);
}


public OnPluginStart() {
	UploadFile("test.dem")
}
