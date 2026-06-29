// http://steamcommunity.com/id/heme3ic it is my steamid, feel free to contact me if something important happened.

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#define NULL_VALUE 9001
#define upgr_default "16-33"
#define status_taunting 1
#define status_taunting_upgr 2
#define status_finished 3
#define status_finished_upgr 4
#define status_interrupted 42



#define PLUGIN_VERSION "2.1"

public Plugin:myinfo = 
{
	name = "Taunt Crits",
	author = "HeMe3iC",
	description = "Crits(or another award) for few seconds after taunting.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=137220"
};

new Handle:cvarVersion;
new Handle:cvarScout;
new Handle:cvarSoldier;
new Handle:cvarPyro;
new Handle:cvarDemoman;
new Handle:cvarHeavy;
new Handle:cvarEngineer;
new Handle:cvarMedic;
new Handle:cvarSniper;
new Handle:cvarSpy;
new Handle:cvarAward;
new Handle:cvarSwitch;
new Handle:cvarNotify;
new Handle:cvarHPcheck;
new Handle:cvarBuffUpg;

new Float:g_Scout;
new Float:g_Soldier;
new Float:g_Pyro;
new Float:g_Demoman;
new Float:g_Heavy;
new Float:g_Engineer;
new Float:g_Medic;
new Float:g_Sniper;
new Float:g_Spy;
new g_Mode;
//new g_cFlags[34];
//new g_Ticks[34];
new bool:g_bSwitch;
new Float:g_Notify;
new bool:g_bHPcheck;
new g_iPlayers[34][2];//[client][0-userid 1-status]

//weapons list can be found here: http://forums.alliedmods.net/showthread.php?p=1337899 (TF2 Give Weapon plugin)
new NoAwardWeapons[64]={42,46,159,163,311,433,NULL_VALUE}; //scout bonk(46) and cola(163) and HWG food
//open tf\addons\sourcemod\scripting\include\tf2.inc for TFConds list
new TFCond:NoAwardConds[64]={TFCond_Bonked, TFCond_Dazed,TFCond:NULL_VALUE};

public OnPluginStart()
{
	cvarVersion = CreateConVar("tauntcrits_version","","Plugin version");
	SetConVarString(cvarVersion,PLUGIN_VERSION);

	cvarScout = CreateConVar("tauntcrits_scout","2.0","Award duration(after finishing the taunt) for scout",_,true,0.00,true,360.00);
	cvarSoldier = CreateConVar("tauntcrits_soldier","1.4","Award duration(after finishing the taunt) for soldier",_,true,0.00,true,360.00);
	cvarPyro = CreateConVar("tauntcrits_pyro","1.8","Award duration(after finishing the taunt) for pyro",_,true,0.00,true,360.00);
	cvarDemoman = CreateConVar("tauntcrits_demoman","1.5","Award duration(after finishing the taunt) for demoman",_,true,0.00,true,360.00);
	cvarHeavy = CreateConVar("tauntcrits_heavy","2.0","Award duration(after finishing the taunt) for heavy",_,true,0.00,true,360.00);
	cvarEngineer = CreateConVar("tauntcrits_engineer","2","Award duration(after finishing the taunt) for engineer",_,true,0.00,true,360.00);
	cvarMedic = CreateConVar("tauntcrits_medic","2.0","Award duration(after finishing the taunt) for medic",_,true,0.00,true,360.00);
	cvarSniper = CreateConVar("tauntcrits_sniper","1.1","Award duration(after finishing the taunt) for sniper",_,true,0.00,true,360.00);
	cvarSpy = CreateConVar("tauntcrits_spy","2.0","Award duration(after finishing the taunt) for spy",_,true,0.00,true,360.00);
	cvarAward = CreateConVar("tauntcrits_award","1.0","Award for taunting. 1=crits 2=mini-crits 3=ubercharge 4=upgradable buff",_,true,1.0,true,4.0);
	cvarSwitch = CreateConVar("tauntcrits_switch","1.0","Taunt Crits plugin status  0.0=off else on",_,true,0.0,true,1.0);
	cvarNotify = CreateConVar("tauntcrits_notify","0.0","Delay between notifcations in chat about this plugin. 0.0=off ",_,true,0.0,true,2048.0);
	cvarHPcheck = CreateConVar("tauntcrits_hpcheck","1.0","Whether to check target hp or not.  If the targets max health(m_iMaxHealth) is below 500 then there will be no award for target. Useful for plugins like VS Saxton Hale.0.0=off else on",_,true,0.0,true,1.0);
	cvarBuffUpg = CreateConVar("tauntcrits_buffupgr","0","Two condition numbers with '-' between them, first condition will be upgraded to the second on taunt if tauntcrits_award==4; If is equal to 0 it will upgrade from minicrits to full crits(16-33). ");
	
	
	HookConVarChange(cvarScout, CvarChange);
	HookConVarChange(cvarSoldier, CvarChange);
	HookConVarChange(cvarPyro, CvarChange);
	HookConVarChange(cvarDemoman, CvarChange);
	HookConVarChange(cvarHeavy, CvarChange);
	HookConVarChange(cvarEngineer, CvarChange);
	HookConVarChange(cvarMedic, CvarChange);
	HookConVarChange(cvarSniper, CvarChange);
	HookConVarChange(cvarSpy, CvarChange);
	HookConVarChange(cvarAward, CvarChange);
	HookConVarChange(cvarSwitch, CvarChange);
	HookConVarChange(cvarNotify, CvarChange);
	HookConVarChange(cvarHPcheck, CvarChange);

	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("object_deflected", Event_Deflected, EventHookMode_Pre);

	
	RegConsoleCmd("tauntcrits_help", help);
	RegConsoleCmd("tauntcrits_info", help);
	
	readCvars();
}

public OnMapStart()
{
	if (g_Notify>0.0)
		CreateTimer(g_Notify, ChatNotify,_,TIMER_FLAG_NO_MAPCHANGE);
	else
		CreateTimer(3.0, ChatNotify,_,TIMER_FLAG_NO_MAPCHANGE);
}


public TF2_OnConditionAdded(client, TFCond:condition){ //detecting taunt start
	if(g_bSwitch && condition==TFCond_Taunting){

		if(g_Mode==4){
			decl cond[2];
			GetCondNums(cond);
			if(TF2_IsPlayerInCondition(client, TFCond:cond[0]) || TF2_IsPlayerInCondition(client, TFCond:cond[1]))
				g_iPlayers[client][1]=status_taunting_upgr;
			else
				g_iPlayers[client][1]=status_taunting;
		}
		else
			g_iPlayers[client][1]=status_taunting; 
		CreateTimer(0.5, CheckCond,client,TIMER_FLAG_NO_MAPCHANGE);
	}
}
public Action:CheckCond(Handle:hTimer, any:client){//checking if player still taunting. If player slides over the edge taont condition stiil will be added and removed.
	if(TF2_IsPlayerInCondition(client, TFCond_Taunting)){
		if(g_iPlayers[client][1]==status_taunting){
			g_iPlayers[client][1]=status_finished;}
		else if(g_iPlayers[client][1]==status_taunting_upgr){
			g_iPlayers[client][1]=status_finished_upgr;}
	}
	else
		g_iPlayers[client][1]=status_interrupted;
}

public TF2_OnConditionRemoved(client, TFCond:condition){ //detecting taunt end
	if(condition==TFCond_Taunting && (g_iPlayers[client][1]==status_finished_upgr || g_iPlayers[client][1]==status_finished) && IsValidEdict(client) && IsClientInGame(client) && IsPlayerAlive(client)){
		Award(client);
		g_iPlayers[client][1]=0; 
	}
}

public Action:Award(client)
{
	if (!(client > 0 && IsValidEdict(client) && IsClientInGame(client) && IsPlayerAlive(client) && (GetEntProp(client, Prop_Data, "m_iMaxHealth")<500|| !g_bHPcheck)))
		return Plugin_Stop;

	new Float:dur=2.0;
	new class=view_as<int>(TF2_GetPlayerClass(client));
	switch(class)
	{
		case TFClass_Scout:
			dur=g_Scout;
		case TFClass_Soldier:
			dur=g_Soldier; 
		case TFClass_Pyro:
			dur=g_Pyro; 
		case TFClass_DemoMan:
			dur=g_Demoman; 
		case TFClass_Heavy:
			dur=g_Heavy; 
		case TFClass_Engineer:
			dur=g_Engineer; 
		case TFClass_Medic:
			dur=g_Medic; 
		case TFClass_Sniper:
			dur=g_Sniper; 
		case TFClass_Spy:
			dur=g_Spy; 
	}
	
	if (dur>0.0 && ValidConds(client) && ValidWeapons(client))
	{
		switch(g_Mode)
		{
			case 1:		
				TF2_AddCondition(client, TFCond_HalloweenCritCandy, dur);
			case 2:
				TF2_AddCondition(client, TFCond_Buffed, dur);
			case 3:
				TF2_AddCondition(client, TFCond_Ubercharged, dur);
			case 4:{
				decl cond[2];
				GetCondNums(cond);
				UpgradeBuff(client,dur,cond[0],cond[1]);
				}
			default:
				LogMessage("TauntCrits ERROR: g_Mode have a wrong value. It never really was on your side.Ahem.");
		}
	}
	
	return Plugin_Stop;
}
UpgradeBuff(client,Float:dur,CondA,CondB){//for tauntcrits_award == 4
	if(g_iPlayers[client][1]==status_finished_upgr)
		TF2_AddCondition(client, TFCond:CondB, dur);
	else if(g_iPlayers[client][1]==status_finished)
		TF2_AddCondition(client, TFCond:CondA,dur);
}

/////////////////////////////////////////////////
///////////////ADDITIONAL FUNCIONS///////////////
/////////////////////////////////////////////////
public Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	
	new client=GetClientOfUserId(GetEventInt(event, "userid"));
	//PrintToChat(client,"dmg taken status=%i",g_iPlayers[client][1]);
	if(g_iPlayers[client][1]!=0)
	{
		//PrintToChat(client,"interrupted by dmg");
		g_iPlayers[client][1]=status_interrupted;
	}
}
public Event_Deflected(Handle:event, const String:name[], bool:dontBroadcast){
	new client=GetClientOfUserId(GetEventInt(event, "ownerid"));
	if(GetEventInt(event, "weaponid")==0 && g_iPlayers[client][1]!=0)
		g_iPlayers[client][1]=status_interrupted;
}
public Action:help(client, args)
{
	decl String:award[64];
	switch(g_Mode)
	{
		case 1:		
			award="crits";
		case 2:
			award="mini-crits";
		case 3:
			award="ubercharge";
		case 4:{
			decl String:s[8];
			decl String:s2[3][3];
			GetConVarString(cvarBuffUpg,s,8);
			if(StrEqual(s,"0")){
				award="mini-crits, upgradable to full crits";}
			else{
				ExplodeString(s, "-", s2, 3,3);
				Format(award, 64, "upgradable conds '%s-%s'",s2[0],s2[1]);
				}
			}
		default:
			award="nothing. Someone broke the plugin.";
	}
	decl String:status[10];
	if(g_bSwitch)
		status="enabled";
	else
		status="disabled";

	PrintToConsole(client, "############################");
	PrintToConsole(client, "       Taunt Crits info     ");
	PrintToConsole(client, "############################");
	PrintToConsole(client, "Plugin version:%s",PLUGIN_VERSION);
	PrintToConsole(client, "Plugin status:%s",status);
	PrintToConsole(client, "Award:%s",award);
	PrintToConsole(client, "Durations:");
	PrintToConsole(client, "     Scout:%f, Soldier:%f, Pyro:%f",g_Scout,g_Soldier,g_Pyro);
	PrintToConsole(client, "     Demoman:%f, Heavy:%f, Engineer:%f",g_Demoman,g_Heavy,g_Engineer);
	PrintToConsole(client, "     Medic:%f, Sniper:%f, Spy:%f",g_Medic,g_Sniper,g_Spy);
	PrintToConsole(client, "cvar list: tauntcrits_[classname], tauntcrits_award, tauntcrits_switch, tauntcrits_notify, tauntcrits_hpcheck, tauntcrits_buffupgr");
	PrintToConsole(client, "############################");
}

public CvarChange(Handle:convar, const String:oldValue[], const String:newValue[]){
	if (convar==cvarScout)
		g_Scout=StringToFloat(newValue);
		
	if (convar==cvarSoldier)
		g_Soldier=StringToFloat(newValue);
	
	if (convar==cvarPyro)
		g_Pyro=StringToFloat(newValue); 
	
	if (convar==cvarDemoman)
		g_Demoman=StringToFloat(newValue); 
	
	if (convar==cvarHeavy)
		g_Heavy=StringToFloat(newValue); 
	
	if (convar==cvarEngineer)
		g_Engineer=StringToFloat(newValue); 
	
	if (convar==cvarMedic)
		g_Medic=StringToFloat(newValue); 
	
	if (convar==cvarSniper)
		g_Sniper=StringToFloat(newValue); 
	
	if (convar==cvarSpy)
		g_Spy=StringToFloat(newValue);
	
	if (convar==cvarAward)
	{ 	
		if(StringToInt(newValue)!=1 && StringToInt(newValue)!=2 && StringToInt(newValue)!=3 && StringToInt(newValue)!=4) 
		{
			SetConVarInt(convar,StringToInt(oldValue));
			LogMessage("tauntcrits_award set to wrong value. Changing it back to %i..",StringToInt(oldValue));//im not sure it can happen at all, but...
			g_Mode=StringToInt(oldValue);
		}
		else {
			g_Mode=StringToInt(newValue);
		}
	}
	if (convar==cvarSwitch)
	{ 
		if(StringToFloat(newValue)==0.0)
			g_bSwitch=bool:false;
		else 
			g_bSwitch=bool:true;
	}
	
	if (convar==cvarNotify)
		g_Notify=StringToFloat(newValue);
	
	if (convar==cvarHPcheck)
	{ 
		if(StringToFloat(newValue)==0.0)
			g_bHPcheck=bool:false;
		else
			g_bHPcheck=bool:true;
	}
}

readCvars()
{
	g_Scout=GetConVarFloat(cvarScout);
	g_Soldier=GetConVarFloat(cvarSoldier);
	g_Pyro=GetConVarFloat(cvarPyro); 
	g_Demoman=GetConVarFloat(cvarDemoman); 
	g_Heavy=GetConVarFloat(cvarHeavy);
	g_Engineer=GetConVarFloat(cvarEngineer);
	g_Medic=GetConVarFloat(cvarMedic); 	
	g_Sniper=GetConVarFloat(cvarSniper);
	g_Spy=GetConVarFloat(cvarSpy);
	g_Mode=GetConVarInt(cvarAward);
	g_bSwitch=GetConVarBool(cvarSwitch);
	g_Notify=GetConVarFloat(cvarNotify);
	g_bHPcheck=GetConVarBool(cvarHPcheck);
}
public Action:ChatNotify(Handle:timer)
{
	if (g_Notify>0.0 && g_bSwitch)
	{
		decl String:award[64];
		switch(g_Mode)
			{
				case 1:		
					award="crits";
				case 2:
					award="mini-crits";
				case 3:
					award="ubercharge";
				case 4:{
					decl String:s[8];
					decl String:s2[3][3];
					GetConVarString(cvarBuffUpg,s,8);
					if(StrEqual(s,"0")){
						award="mini-crits, upgradable to full crits";}
					else{
						ExplodeString(s, "-", s2, 3,3);
						Format(award, 64, "upgradable conds '%s-%s'",s2[0],s2[1]);
						}
					}
				default:
					award="nothing. Someone broke the plugin.";
			}
		PrintToChatAll("[Taunt Crits] Taunting will be awarded with few seconds of %s",award);
		CreateTimer(g_Notify, ChatNotify,_,TIMER_FLAG_NO_MAPCHANGE);
		return Plugin_Stop;
	}
	else
	{
		CreateTimer(3.0, ChatNotify,_,TIMER_FLAG_NO_MAPCHANGE); //timer idle mode
		return Plugin_Stop;
	}
}

/////////////////////////////////////////////////
///////////////PROCESSING FUNCIONS///////////////
/////////////////////////////////////////////////

GetCondNums(output[2]){
	decl String:s[8];
	GetConVarString(cvarBuffUpg,s,8);
	if(StrEqual(s,"0"))
		s=upgr_default;
	decl String:s2[3][3];
	ExplodeString(s, "-", s2, 3,3);
	output[0]=StringToInt(s2[0]); output[1]=StringToInt(s2[1]);
}

stock bool:ValidConds(client)
{
	for (new i=0;i<=64;i++)
	{
		if (NoAwardConds[i]==TFCond:NULL_VALUE)
			return bool:true;
		if (TF2_IsPlayerInCondition(client, NoAwardConds[i]))
			return bool:false;
	}
	return bool:true;
}

stock bool:ValidWeapons(client)
{	
	if (!(client > 0 && IsValidEdict(client) && IsClientInGame(client) && IsPlayerAlive(client)))
		return bool:false;
		
	new weaponent=GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (!(weaponent> MaxClients && IsValidEdict(weaponent)))
		return bool:false;
		
	new weaponind=GetEntProp(weaponent, Prop_Send, "m_iItemDefinitionIndex");
	for (new i=0;i<=64;i++)
	{
		if (NoAwardWeapons[i]==NULL_VALUE)
			return bool:true;
		if (weaponind == NoAwardWeapons[i])
			return bool:false;
	}
	return bool:true;
}

////taunt interrupted
