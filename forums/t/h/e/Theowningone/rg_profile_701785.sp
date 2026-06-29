#include <sourcemod>
#include <sdktools>

public Plugin:myinfo ={
    name = "RG Profile",
    author = "Theowningone",
    description = "RG Profile",
    version = "1.11",
    url = "http://www.theowningone.info/"
};


public OnPluginStart(){
	RegConsoleCmd("sm_profile",id,"Takes a steam id, converts it to a steam community link and sends you to it!");
	CreateConVar("rg_profile_ver","1.11","RG Profile Version",FCVAR_REPLICATED|FCVAR_NOTIFY);
}

public Action:id(client,args){
	if(args==0){
		PrintToChat(client,"Proper Usage: !profile<steamid, userid, playername>");
		PrintToChat(client,"Proper Usage: sm_profile <steamid, userid, playername>");
		return Plugin_Handled;
	}
	decl String:arg[128],String:link[256],String:ID[256];
	GetCmdArgString(arg,128);
	new Targ=FindTarget(client,arg,true,false);
	
	if(Targ<=0){
		Format(ID,sizeof(ID),"%s",arg);
	}else{
		GetClientAuthString(Targ,ID,256);
	}
	AuthIDToFriendID(ID,link,256);
	if(client!=0){
		ShowMOTDPanel(client,"ID",link,MOTDPANEL_TYPE_URL);
	}else{
		PrintToServer("%s",link);
	}
	return Plugin_Handled;
}

AuthIDToFriendID(String:AuthID[],String:FriendID[],size){
    ReplaceString(AuthID,strlen(AuthID),"STEAM_","");
    if(StrEqual(AuthID,"ID_LAN")){
        FriendID[0]='\0';
        return;
    }
    decl String:toks[3][16];
    ExplodeString(AuthID,":",toks,3,16);
    new iServer=StringToInt(toks[1]);
    new iAuthID=StringToInt(toks[2]);
    new iFriendID=(iAuthID*2)+60265728+iServer;
    Format(FriendID,size,"http://steamcommunity.com/profiles/765611979%d",iFriendID);
}