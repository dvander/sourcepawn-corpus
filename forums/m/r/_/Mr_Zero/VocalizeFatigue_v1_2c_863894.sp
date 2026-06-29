/*
* Vocalize Fatigue
* 
* Description and readme @ http://forums.alliedmods.net/showthread.php?t=96349
* 
* Mr. Zero
*/

#pragma semicolon 1
// ***********************************************************************
// INCLUDES
// ***********************************************************************
#include <sourcemod>
#include <sdktools>
// ***********************************************************************
// CONSTANTS
// ***********************************************************************
#define PLUGIN_VERSION		"1.2c"
#define CVAR_FLAGS			FCVAR_PLUGIN|FCVAR_SPONLY
#define BLACKLIST_MAXWORDS	64
#define BLACKLIST_WORDSIZE	64
#define BLACKLIST_MAXSIZE	((BLACKLIST_MAXWORDS * BLACKLIST_WORDSIZE) + BLACKLIST_MAXWORDS)
// 							Maxwords * Wordsize + comma sperator for each word (= maxwords)
// ***********************************************************************
// VARIABLES
// ***********************************************************************
// /////////////////////
// Convar handles
// /////////////////////
new Handle:g_hEnable;
// Repetition
new Handle:g_hRepeatThreshold;
new Handle:g_hRepeatDelay;
new Handle:g_hRepeatPenalty;
new Handle:g_hRepeatImmunity;
// Spam
new Handle:g_hSpamThreshold;
new Handle:g_hSpamDelay;
new Handle:g_hSpamPenalty;
new Handle:g_hSpamImmunity;
// Blacklist
new Handle:g_hBlackList;
new Handle:g_hBlackListImmunity;
// /////////////////////
// Player data
// /////////////////////
new String:	g_sLastVocalArg		[MAXPLAYERS+1][BLACKLIST_WORDSIZE];
new Float: 	g_fLastVocalTime	[MAXPLAYERS+1];
new 		g_iVocalCount		[MAXPLAYERS+1];
new bool:	g_bVocalGag			[MAXPLAYERS+1];

public Plugin:myinfo =
{
	name 		= "Vocalize Fatigue",
	author 		= "Mr. Zero",
	description = "Enables a fatigue funtion to the vocalize command, and disables the vocalize command for short period of time after excessive use from a single player.",
	version 	= PLUGIN_VERSION,
	url 		= "http://forums.alliedmods.net/showthread.php?t=96349"
};

public OnPluginStart()
{
	g_hEnable 				= CreateConVar("l4d_vf_enable"				, "1"			, "Sets whether Vocalize Fatigue plugin is enabled"																				, CVAR_FLAGS);
	g_hRepeatThreshold		= CreateConVar("l4d_vf_repeat_threshold"	, "3"			, "Amount of times a command can be used before it is player is flaged for repeation."											, CVAR_FLAGS);
	g_hRepeatDelay 			= CreateConVar("l4d_vf_repeat_delay"		, "2.0"			, "Amount of time that has to pass before you can repeat (in seconds)."															, CVAR_FLAGS, true, 0.0);
	g_hRepeatPenalty 		= CreateConVar("l4d_vf_repeat_penalty"		, "2.0"			, "Amount of time to add, to the repeat fatigue, if players keep using vocalize commands while fatigue is active (in seconds)."	, CVAR_FLAGS, true, 0.0);
	g_hRepeatImmunity		= CreateConVar("l4d_vf_repeat_immunity"		, "0"			, "Sets the level of immunity users need, to be able to bypass being flagged for repetition (0 - disabled)."					, CVAR_FLAGS);
	g_hSpamThreshold 		= CreateConVar("l4d_vf_spam_threshold"		, "5"			, "Sets the amount of vocalize commands can be used before fatigue starts within the threshold time"							, CVAR_FLAGS);
	g_hSpamDelay 			= CreateConVar("l4d_vf_spam_delay"			, "2.0"			, "Sets the amount of time within the vocalize threshold is valid (in seconds)"													, CVAR_FLAGS);
	g_hSpamPenalty 			= CreateConVar("l4d_vf_spam_penalty"		, "1.0"			, "Amount of time to add, to the spam fatigue, if players keep using vocalize commands while fatigue is active (in seconds)."	, CVAR_FLAGS, true, 0.0);
	g_hSpamImmunity			= CreateConVar("l4d_vf_spam_immunity"		, "0"			, "Sets the level of immunity users need, to be able to bypass being flagged for spamming (0 - disabled)."						, CVAR_FLAGS);
	g_hBlackList 			= CreateConVar("l4d_vf_blacklist"			, ""			, "Defines which vocalize commands that are not allowed to be used. Separate each command with a comma (,)."					, CVAR_FLAGS);
	g_hBlackListImmunity	= CreateConVar("l4d_vf_blacklist_immunity"	, "0"			, "Sets the level of immunity users need, to be able to bypass the blacklist filter (0 - disabled)."							, CVAR_FLAGS);
	CreateConVar("l4d_vf_version", PLUGIN_VERSION, "Vocalize Fatigue Version", CVAR_FLAGS|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	AutoExecConfig(true,"VocalizeFatigue");
	
	RegConsoleCmd("vocalize", VocalizeFatigue);
	RegAdminCmd("sm_vocalgag", Command_VocalGag, ADMFLAG_GENERIC, "Used to disable/enable vocalize command for the target player. Usage: sm_vocalgag <#userid|name> [time].");
}

public OnClientConnected(client)
{
	if(client == 0){return;}
	
	g_sLastVocalArg[client]		= "";
	g_fLastVocalTime[client] 	= 0.0;
	g_iVocalCount[client] 		= 0;
	g_bVocalGag[client] 		= false;
}

public Action:VocalizeFatigue(client, arg)
{	
	if(!GetConVarBool(g_hEnable)){return Plugin_Continue;}
	
	if(g_bVocalGag[client] == true)	{return Plugin_Handled;}
	
	new String:sArg[BLACKLIST_WORDSIZE];
	
	GetCmdArgString(sArg,sizeof(sArg));
	
	if(IsBlackListed(sArg) && !IsImmune(client,GetConVarInt(g_hBlackListImmunity)))
	{
		return Plugin_Handled;
	}
	
	decl iReqImmunLvl;
	decl iThreshold;
	decl iDelay;
	decl iPenalty;
	
	if(StrEqual(g_sLastVocalArg[client],sArg,false))
	{
		iReqImmunLvl	= GetConVarInt(g_hRepeatImmunity);
		iThreshold 		= GetConVarInt(g_hRepeatThreshold);
		iDelay 			= GetConVarInt(g_hRepeatDelay);
		iPenalty 		= GetConVarInt(g_hRepeatPenalty);
	}
	else
	{
		iThreshold 		= GetConVarInt(g_hSpamThreshold);
		iDelay 			= GetConVarInt(g_hSpamDelay);
		iPenalty		= GetConVarInt(g_hSpamPenalty);
		iReqImmunLvl 	= GetConVarInt(g_hSpamImmunity);
		g_sLastVocalArg[client] = sArg;
	}
	
	if(IsImmune(client,iReqImmunLvl)){return Plugin_Continue;}
	
	new Float:fCurrentTime = GetEngineTime();
	
	if(g_iVocalCount[client] >= iThreshold)
	{
		if(g_fLastVocalTime[client] >= (fCurrentTime - iDelay))
		{
			g_fLastVocalTime[client] = (fCurrentTime + iPenalty);
			return Plugin_Handled;
		}
		g_iVocalCount[client] = 0;
	}
	g_iVocalCount[client]++;
	g_fLastVocalTime[client] = fCurrentTime;
	return Plugin_Continue;
}

public Action:Command_VocalGag(client, args)
{
	if (args < 1 || args > 2) {ReplyToCommand(client, "[SM] Usage: sm_vocalgag <#userid|name> [time]");	return Plugin_Handled;}
	
	decl String:arg[65];
	GetCmdArg(1, arg, sizeof(arg));
	
	new any:time = 0;
	if (args == 2){
		decl String:arg2[20];
		GetCmdArg(2, arg2, sizeof(arg2));
		StringToFloatEx(arg2, time);
		if (time < 0) {ReplyToCommand(client, "[SM] Invalid Amount");	return Plugin_Handled;}
	}
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	
	if ((target_count = ProcessTargetString(arg,client,target_list,MAXPLAYERS,COMMAND_FILTER_ALIVE,target_name,sizeof(target_name),	tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	decl String:name[MAX_NAME_LENGTH];
	
	for (new i = 0; i < target_count; i++){
		GetClientName(target_list[i], name, sizeof(name));
		if(time == 0)
		{
			g_bVocalGag[target_list[i]] = !g_bVocalGag[target_list[i]];
			
			if(g_bVocalGag[target_list[i]])	
				ShowActivity(client, " \x01The vocalize command is now disabled for %s", name);
			else
				ShowActivity(client, " \x01The vocalize command is now enabled for %s", name);
		} 
		else
		{
			g_bVocalGag[target_list[i]] = true;
			CreateTimer(time,UnGag,client,TIMER_FLAG_NO_MAPCHANGE);
			new itime = RoundToNearest(time);
			ShowActivity(client, " \x01The vocalize command is now disabled for %s in the next %i seconds", name, itime);
		}
	}
	return Plugin_Handled;
}

public Action:UnGag(Handle:timer, any:client){g_bVocalGag[client] = false;}

bool:IsBlackListed(String:arg[BLACKLIST_WORDSIZE])
{
	decl String: sRawBlackList[BLACKLIST_MAXSIZE];
	decl String: sBlackList[BLACKLIST_MAXWORDS][BLACKLIST_WORDSIZE];
	
	GetConVarString(g_hBlackList,sRawBlackList,sizeof(sRawBlackList));
	
	if(strlen(sRawBlackList)>0){
		ExplodeString(sRawBlackList,",",sBlackList,BLACKLIST_MAXWORDS,BLACKLIST_WORDSIZE);
		for(new i=0;i<BLACKLIST_MAXWORDS;i++){
			if(StrEqual(sBlackList[i],arg,false)){return true;}
		}
	}
	return false;
}

bool:IsImmune(client,iReqImmunLvl)
{
	new any:Id = GetUserAdmin(client);
	
	if(Id == INVALID_ADMIN_ID)
		return false;
	
	new iClientImmunLvl	= GetAdminImmunityLevel(Id);
	
	if(iReqImmunLvl == 0 || iClientImmunLvl == 0)
		return false;
	
	if(iReqImmunLvl > iClientImmunLvl)
		return false;
	
	return true;
}