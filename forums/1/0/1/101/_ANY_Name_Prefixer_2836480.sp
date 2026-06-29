#include <sdktools_functions>

int ROWS;
char logo[MAXPLAYERS+1][8];
char prefixRules[][][] =
{
	// default logo for all users :
    {"Prefixer_SERVERLOGO"		,"☭"},	

	//remove this from players names (Black List)
	{"Prefixer_Restricted1"		,".com"},
	{"Prefixer_Restricted2"		,".org"},	
	{"Prefixer_Restricted3"		,".net"},
	{"Prefixer_Restricted4"		,"dick"},
	{"Prefixer_Restricted5"		,"pussy"},
	{"Prefixer_Restricted6"		,"fuck"},

	// custom logo for a specific steam-Id (SF list):
    {"STEAM_1:0:xxxxxxxx1"		,"❄"},
	{"STEAM_1:0:xxxxxxxx2"		,"❄"},
	{"STEAM_1:0:xxxxxxxx3"		,"❄"}
}

public Plugin myinfo ={
    name = "[ANY] Name Prefixer",
	author = "101",
	description = "Assign Name Prefix Based on Steam ID",
    version = "1.0",
    url = "https://forums.alliedmods.net"
}

public void OnPluginStart() {
	ROWS = sizeof(prefixRules);
    AddCommandListener(Command_Setinfo, "setinfo");
}

public Action:Command_Setinfo(client, const String:command[], args){
    static char Text[64];
    GetCmdArgString(Text, 64);
    if (StrContains(Text, "name", false) != -1){
		NameEdit( client ? client : 1 , Text[5]);
        return Plugin_Handled;
	}return Plugin_Continue;
}

public OnClientAuthorized(int client, const char[] auth){
	static char name[32];
	FormatEx(logo[client], 8 , prefixRules[0][1]);
	for (int i=1 ; i< ROWS ; i++){
		if (StrContains(prefixRules[i][0], auth ,false) != -1){
			FormatEx(logo[client], 8 , prefixRules[i][1]);
			break;
		}
	}
	GetClientName(client, name, 32);
	NameEdit(client , name);
}

NameEdit(client , char CName[32]){
	for (int i=0 ; i< ROWS ; i++)
		ReplaceString(CName, 32 , prefixRules[i][1], "", false);
	TrimString(CName);
	Format(CName , 32 , "%s %s" , logo[client] , CName);
	SetClientName(client, CName);
}