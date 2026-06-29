//                          =======================================================================
//	                    |     Plugin By Tair Azoulay                                          |
//                          |                                                                     |
//                          |     Profile : http://steamcommunity.com/profiles/76561198013150925/ |                                         |
//                          |                                                                     |
//	                    |     Name : Admin Message                                            |
//                          |                                                                     |
//	                    |     Version : 1.0                                                   |
//                          |                                                                     |
//	                    |     Description : Send Message To Admins                            |     
//                          =======================================================================




#include <sourcemod>

public Plugin:myinfo = 
{
	name = "Admin Message",
	author = "Tair",
	description = "Send Message to online admins.",
	version = "1.0",
	url = "http://www.sourcemod.net/"
}

public OnPluginStart(){

	RegConsoleCmd("sm_adminmsg", Command_AdminMSG);
	RegConsoleCmd("sm_amsg", Command_AdminMSG);
	RegConsoleCmd("sm_am", Command_AdminMSG);

}

public Action:Command_AdminMSG(client, args){

	if (args < 1)
	{
		ReplyToCommand(client, " \x07[SM] \x04Usage: \x06sm_adminmsg <Text>");
		return Plugin_Handled;
	}


	for(new i = 1; i <= MaxClients; i++){
	new String:Msg[256];
	new String:Name[MAX_NAME_LENGTH];
	GetClientName(client, Name, sizeof(Name));
	GetCmdArgString(Msg, sizeof(Msg));
	Msg[strlen(Msg)-0] = '\0';

	if(IsClientInGame(i) && CheckCommandAccess(i, "sm_admin", ADMFLAG_GENERIC))
{

			PrintToChat(i, " \x07[AdminMsg] \x04%s : \x06%s", Name, Msg);


		}

	}
	PrintToChat(client, " \x07[AdminMsg] \x04Your message was sent to online admins.");
        return Plugin_Handled;
}