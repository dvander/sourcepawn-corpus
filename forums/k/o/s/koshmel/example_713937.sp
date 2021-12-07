// example for the socket extension

#include <sourcemod>
#include <socket>

new String:UploadFileName[30]=""; 
public Plugin:myinfo = {
	name = "Test",
	author = "koshmel",
	description = "NULL",
	version = "HORROR",
	url = "koshmel@gmail.com"
};
 
public UploadFile(String:FileName[30]) {
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
	decl String:Buff[1005];
	decl String:head[500];
	decl String:strend[50];
	new ContentL=0;
	new Handle:OFile = OpenFile(UploadFileName, "rb");
	//при пустом файле и имени 277 размер
	Format(strend, sizeof(strend), "\r\n--------111008170141884--\r\n\r\n");
	ContentL=277+FileSize(UploadFileName)+strlen(UploadFileName);
	Format(head, sizeof(head), "POST /cgi-bin/upload.cgi HTTP/1.0\r\nContent-Type: multipart/form-data; boundary=--------111008170141884\r\nContent-Length: %i\r\n\r\n----------111008170141884\r\nContent-Disposition: form-data; name=\"toolmode2\"\r\n\r\n1\r\n----------111008170141884\r\nContent-Disposition: form-data; name=\"filecontent\"; filename=\"%s\"\r\nContent-Type: multipart/form-data\r\nContent-Transfer-Encoding: binary\r\n\r\n",ContentL,UploadFileName);
	SocketSend(socket,head);
	PrintToServer("Content-Length: %i(277+%i+%i)",ContentL,FileSize(UploadFileName),strlen(UploadFileName));
	PrintToServer("Upload:%s",UploadFileName);
	new BuffL=0;
	while (!IsEndOfFile(OFile))
		{
			BuffL=ReadFileString(OFile,Buff,1000)
			//BuffL=ReadFile(OFile, Buff, 1000,2);
			//PrintToServer("Sending %i bytes",BuffL);
			SocketSend(socket,data,1);
		}
	SocketSend(socket,strend);
	
	
	CloseHandle(OFile);
}

public OnSocketReceive(Handle:socket, String:receiveData[], const dataSize, any:SFile) {
	// receive another chunk and write it to <modfolder>/dl.htm
	// we could strip the http response header here, but for example's sake we'll leave it in
	PrintToServer("<<incoming data>>");
	WriteFileString(SFile, receiveData, false);
}

public OnSocketDisconnected(Handle:socket, any:SFile) {
	// Connection: close advises the webserver to close the connection when the transfer is finished
	// we're done here

	CloseHandle(SFile);
	CloseHandle(socket);
}

public OnSocketError(Handle:socket, const errorType, const errorNum, any:SFile) {
	// a socket error occured

	LogError("socket error %d (errno %d)", errorType, errorNum);
	CloseHandle(SFile);
	CloseHandle(socket);
}


public OnPluginStart() {
	UploadFile("test.txt")
}
