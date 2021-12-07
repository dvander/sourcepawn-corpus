/*
1.1 chg rename via admincmd
*/
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
 
public Plugin:myinfo ={
	name	= "test",
	author	= "[729]jetsam",
	description = "test prop SetClientInfo func",
	version = "1.1",
	url = ""
};

public OnPluginStart(){
	RegAdminCmd("test_setclientinfo",TestSetClientInfo,ADMFLAG_GENERIC);
}


/*
public OnClientPutInServer(client){
	if(!IsFakeClient(client) && client){
		decl String:newname[128];
		Format(newname, 127, "[test] %N",client);
		SetClientInfo(client, "name", newname);
	}
}
*/

public Action:TestSetClientInfo(client, args){

	if(client && args==1){
		decl String:NewName[128];
		GetCmdArg(1, NewName, 127);
		SetClientInfo(client, "name", NewName);
	}
	return Plugin_Handled;
}
