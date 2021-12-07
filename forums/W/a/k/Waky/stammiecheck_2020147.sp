#include <sourcemod>
#include <colors>
#include <stamm>
#include <sdktools>

//------------Defines------------
#define PLUGIN_VERSION "1.0"
#define URL "www.area-community.net"
#define AUTOR "Waky"
#define NAME "Stammiecheck"
#define DESCRIPTION "Shows an admin the stammpoints of one player"
#define MAX_FILE_LEN 80

public Plugin:myinfo = 
{
	name = NAME,
	author = AUTOR,
	description = DESCRIPTION,
	version = PLUGIN_VERSION,
	url = URL
}

public OnPluginStart()
{
	RegAdminCmd("sm_stammwho",STAMMWHO ,ADMFLAG_KICK);
	LoadTranslations("stammiecheck.phrases");
}
//############################# on !stammwho ##############################
public Action:STAMMWHO(client, args)
{
	if(args != 1)
	{
		CPrintToChat(client,"%T","HINT",LANG_SERVER);
		return Plugin_Handled;
	}
	
	new String:Target[64];
	GetCmdArg(1, Target, sizeof(Target));
	
	new String:targetName[MAX_TARGET_LENGTH];
	new targetList[MAXPLAYERS], targetCount;
	new bool:b1;
	
	
	targetCount = ProcessTargetString(Target, client, targetList, sizeof(targetList), COMMAND_FILTER_ALIVE, targetName, sizeof(targetName), b1);
	
	if(targetCount == 0) 
	{
		CPrintToChat(client,"%T","MORE_TARGETS")
		ReplyToTargetError(client, COMMAND_TARGET_NONE);
	} 
	else 
	{	for (new i=0; i<targetCount; i++) 
		{
			GetLevel(client, targetList[i]);
		}
	}
	return Plugin_Continue;
}
//################################ Shows Level #############################
public GetLevel(client, target)
{
	new Rounds = GetClientStammPoints(target);
	CPrintToChat(client, "%T","PRINT",LANG_SERVER,target ,Rounds);
}
