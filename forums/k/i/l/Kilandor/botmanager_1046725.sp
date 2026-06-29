#include <sourcemod>
#include <sdktools>
//#include <tf2>
//#include <tf2_stocks>

#define PLUGIN_VERSION "1.1"

new Handle:hCvarBots, Handle:hCvarReserveSlots;
new cvarBots=2;
new botCount=0;
new botAddCount=0;
new bots[MAXPLAYERS+1] = {false,...};
public Plugin:myinfo = {
	name = "TF2 Bot Manager",
	author = "Matheus28",
	description = "",
	version = PLUGIN_VERSION,
	url = ""
}
/* Modified by Kilandor
   http://www.kilandor.com/
*/
public OnPluginStart(){
	//Commands
	RegAdminCmd("sm_botadd", Command_BotAdd, ADMFLAG_GENERIC, "[num] [blue/red] [class] - Spawns a Intelligent bot");
	RegAdminCmd("sm_botkick", Command_BotKick, ADMFLAG_GENERIC, "[num/all] - Kicks bot(s) from the server");
	
	CreateConVar("sm_bm_version",PLUGIN_VERSION,"Version of TF2 Bot Manager",FCVAR_PLUGIN+FCVAR_SPONLY);
	hCvarBots=CreateConVar("sm_bm_slotsfree","1","How many slots the bots should not use (Doesn't count reserved slots)",FCVAR_PLUGIN,true,1.0,true, float(MAXPLAYERS));
	HookConVarChange(hCvarBots,eCvarBots);
	hCvarReserveSlots = FindConVar("sm_reserved_slots");
	if(hCvarReserveSlots != INVALID_HANDLE)
	{
		HookConVarChange(FindConVar("sm_reserved_slots"),eCvarBots);
	}
	
	HookEvent("player_connect",Event_PlayerConnect);
	
	CreateTimer(1.0,Timer_CheckBots,_,TIMER_REPEAT);
	
	ProcessBotsVars();
}
public Action:Event_PlayerConnect(Handle:event, const String:name[], bool:dontBroadcast){
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	decl String:type[32];
	GetEventString(event,"networkid",type,sizeof(type));
	if(StrEqual(type,"BOT",false)){
		bots[client]=true;
	}
}
public OnMapStart(){
	botCount=0;
	botAddCount=0;
	decl flags
	flags=GetCommandFlags("nav_generate")
	if(flags&FCVAR_CHEAT){
		SetCommandFlags("nav_generate",flags^FCVAR_CHEAT);
	}
	flags=GetCommandFlags("tf_bot_add")
	if(flags&FCVAR_CHEAT){
		SetCommandFlags("tf_bot_add",flags^FCVAR_CHEAT);
	}
}
public ProcessBotsVars(){
	new iReservedSlots;
	if(hCvarReserveSlots != INVALID_HANDLE)
	{
		iReservedSlots = GetConVarInt(FindConVar("sm_reserved_slots"));
	}
	cvarBots=GetConVarInt(hCvarBots)+iReservedSlots
}
public eCvarBots(Handle:convar, const String:oldValue[], const String:newValue[]){
	ProcessBotsVars();
}

public KickRandomBot(){
	for(new i=1;i<=MaxClients;i++){
		if(IsClientInGame(i)&&bots[i]){
			KickClient(i);
			bots[i]=false;
			return;
		}
	}
}
public KickAllBots(){
	for(new i=1;i<=MaxClients;i++){
		if(IsClientInGame(i)&&bots[i]){
			KickClient(i);
			bots[i]=false;
		}
	}
}
public CheckBots(){
	for(new i=1;i<=MaxClients;i++){
		if(IsClientConnected(i)&&IsFakeClient(i)){
			bots[i]=true;
		}else{
			bots[i]=false;
		}
	}
}

public Action:Timer_CheckBots(Handle:timer){
	if(MaxClients==0){
		return Plugin_Continue;
	}
	CheckBots();
	new count=0;
	for(new i=1;i<=MaxClients;i++){
		if(IsClientConnected(i)){
			count++;
		}
	}
	
	new num_total=count;
	new remaining = MaxClients-num_total+botAddCount;
	if(remaining>cvarBots){
		ServerCommand("tf_bot_add");
		botCount++;
		PrintToChatAll("\x04[\x03BotMan\x04]\x01 Not Enough Players Adding a Bot.");
	}else if(remaining<cvarBots){
		if(botCount<=0){
			return Plugin_Continue;
		}
		botCount--;
		KickRandomBot();
		PrintToChatAll("\x04[\x03BotMan\x04]\x01 Enough Players Removing a Bot.");
	}
	return Plugin_Continue
}

public Action:Command_BotAdd(client, args)
{
	new String:botadd_args[64];
	GetCmdArgString(botadd_args, sizeof(botadd_args));
	if(GetCmdArgs() >= 1)
	{
		ServerCommand("tf_bot_add %s", botadd_args);
		new String:botadd_num[64];
		GetCmdArg(1, botadd_num, sizeof(botadd_num));
		new botadd_num2 = StringToInt(botadd_num);
		botAddCount += botadd_num2;
		PrintToChatAll("\x04[\x03BotMan\x04]\x01 Adding %d Bots.", botadd_num2);
	}
	else
	{
		botAddCount++;
		ServerCommand("tf_bot_add");
		PrintToChatAll("\x04[\x03BotMan\x04]\x01 Adding a Bot.");
	}
	return Plugin_Handled;
}

public Action:Command_BotKick(client, args)
{
	new String:botkick_num[64];
	GetCmdArg(1, botkick_num, sizeof(botkick_num));
	if(strcmp(botkick_num, "all", false) == 0)
	{
		KickAllBots();
		botCount=0;
		botAddCount=0;
		PrintToChatAll("\x04[\x03BotMan\x04]\x01 Kicking all Bots.");
	}
	else
	{
		new botkick_num2 = StringToInt(botkick_num);
		if(botkick_num2 > 0)
		{
			for(new i=1;i<=botkick_num2;i++)
			{
				botCount -= botkick_num2;
				botAddCount -= botkick_num2;
				KickRandomBot();
				PrintToChatAll("\x04[\x03BotMan\x04]\x01 Kicking %d Bots.", botkick_num2);
			}
		}
		else
		{
				botCount--;
				botAddCount--;
				KickRandomBot();
				PrintToChatAll("\x04[\x03BotMan\x04]\x01 Kicking a Bot.");
		}
	}
	return Plugin_Handled;
}