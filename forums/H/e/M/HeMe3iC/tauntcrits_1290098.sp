// http://steamcommunity.com/id/heme3ic it is my steamid, feel free to contact me if something important.

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#define NULL_VALUE 9001



#define PLUGIN_VERSION "1.6"

public Plugin:myinfo = 
{
	name = "Taunt Crits",
	author = "HeMe3iC",
	description = "Crits(or another award) for few seconds cased by taunt.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=137220"
};
new Handle:cvarDebugMode;

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
new g_cFlags[34];
new g_Ticks[34];
new bool:g_bSwitch;
new Float:g_Notify;
new bool:g_bHPcheck;
new g_iPlayerID[64];

new debugMode;

//weapons list can be found here: http://forums.alliedmods.net/showthread.php?p=1337899 (TF2 Give Weapon plugin)
new NoAwardWeapons[64]={42,46,159,163,311,433,NULL_VALUE}; //scout bonk(46) and cola(163) and HWG food
//open tf\addons\sourcemod\scripting\include\tf2.inc for TFConds list
new TFCond:NoAwardConds[64]={TFCond_Bonked, TFCond_Dazed,TFCond:NULL_VALUE};



public DevMode(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar==cvarDebugMode)
		debugMode=StringToInt(newValue);
}


public OnPluginStart()
{
	cvarVersion = CreateConVar("tauntcrits_version","","Plugin version");
	SetConVarString(cvarVersion,PLUGIN_VERSION);
	
	cvarDebugMode = CreateConVar("tauntcrits_debug","0.0","plugin debug depth. 0=off",_,true,0.00,true,32.00);
	
	cvarScout = CreateConVar("tauntcrits_scout","2.0","Award duration(after finishing the taunt) for scout",_,true,0.00,true,360.00);
	cvarSoldier = CreateConVar("tauntcrits_soldier","1.4","Award duration(after finishing the taunt) for soldier",_,true,0.00,true,360.00);
	cvarPyro = CreateConVar("tauntcrits_pyro","1.8","Award duration(after finishing the taunt) for pyro",_,true,0.00,true,360.00);
	cvarDemoman = CreateConVar("tauntcrits_demoman","1.5","Award duration(after finishing the taunt) for demoman",_,true,0.00,true,360.00);
	cvarHeavy = CreateConVar("tauntcrits_heavy","2.0","Award duration(after finishing the taunt) for heavy",_,true,0.00,true,360.00);
	cvarEngineer = CreateConVar("tauntcrits_engineer","2","Award duration(after finishing the taunt) for engineer",_,true,0.00,true,360.00);
	cvarMedic = CreateConVar("tauntcrits_medic","2.0","Award duration(after finishing the taunt) for medic",_,true,0.00,true,360.00);
	cvarSniper = CreateConVar("tauntcrits_sniper","1.1","Award duration(after finishing the taunt) for sniper",_,true,0.00,true,360.00);
	cvarSpy = CreateConVar("tauntcrits_spy","2.0","Award duration(after finishing the taunt) for spy",_,true,0.00,true,360.00);
	cvarAward = CreateConVar("tauntcrits_award","1.0","Award for taunting. 1=crits 2=mini-crits 3=ubercharge",_,true,1.0,true,3.0);
	cvarSwitch = CreateConVar("tauntcrits_switch","1.0","Taunt Crits plugin status  0.0=off else on",_,true,0.0,true,1.0);
	cvarNotify = CreateConVar("tauntcrits_notify","600.0","Delay between notifcations in chat about this plugin. 0.0=off ",_,true,0.0,true,2048.0);
	cvarHPcheck = CreateConVar("tauntcrits_hpcheck","1.0","Whether to check target hp or not.  If the targets hp is below 500 then there will be no award for target. Useful for plugins like VS Saxton Hale.0.0=off else on",_,true,0.0,true,1.0);

	HookConVarChange(cvarDebugMode, DevMode);
	
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

	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_changeclass", Event_ClassChange);
	
	RegConsoleCmd("tauntcrits_help", help);
	RegConsoleCmd("tauntcrits_info", help);
	
	readCvars();
	
	ResetPlayersID();
	//CreateTimer(1.0, ResetPlayersIDList);

	if (debugMode>0)
		PrintToChatAll("[debug] public OnPluginStart()");
		
	if (debugMode==-1)
		UpdatePlayersID(); //get rid of "symbol is unused" warning
		

}

public OnMapStart()
{

	
	ResetPlayersID();
	
	//CreateTimer(3.0, ResetPlayersIDList,_, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(1.0, Hook_taunt,_,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	for (new client=1;client<=MaxClients;client++)
	{
		g_cFlags[client]=0;
		g_Ticks[client]=0;
	}

	if (g_Notify>0.0)
		CreateTimer(g_Notify, ChatNotify,_,TIMER_FLAG_NO_MAPCHANGE);
	else
		CreateTimer(3.0, ChatNotify,_,TIMER_FLAG_NO_MAPCHANGE);//timer idle mode
}

ResetPlayersID()
{	
	if (debugMode>0)
		PrintToChatAll("[debug] ResetPlayersID()");
	NullPlayersID();
	for (new i=1;i<=MaxClients;i++)
		if (IsValidEdict(i) && IsClientInGame(i))
			AddPlayerID(i);
	
}

NullPlayersID()
{
	//PrintToChatAll("NullPlayersID()");
	for (new i=1;i<=MaxClients;i++)
		g_iPlayerID[i]=NULL_VALUE;
}
AddPlayerID(client)
{
	for (new i=1;i<=MaxClients;i++)
		if(!PlayerIDExist(client) && g_iPlayerID[i]==NULL_VALUE)
		{
			g_iPlayerID[i]=GetClientUserId(client);
			return;
		}
	return;
}

UpdatePlayersID()
{
	for (new i=1;i<=MaxClients;i++)
		if (!(IsValidEdict(i) && IsClientInGame(i)))
			g_iPlayerID[i]=NULL_VALUE;
}

RemovePlayerID(client)
{
	new userid=GetClientUserId(client);
	for (new i=1;i<=MaxClients;i++)
		if(g_iPlayerID[i]==userid)
		{
			g_iPlayerID[i]=NULL_VALUE;
			return;
		}
	return;
}

stock GetPlayerID(userid)
{
	for (new i=1;i<=MaxClients;i++)
		if(g_iPlayerID[i]==userid)
			return i;
			
	return NULL_VALUE;
}

stock bool:PlayerIDExist(client)
{
	new userid=GetClientUserId(client);
	for (new i=1;i<=MaxClients;i++)
		if(g_iPlayerID[i]==userid)
			return true;

	return false;
}

stock bool:NoChecksIProgress()
{
	for (new i=1;i<=MaxClients;i++)
		if (!(g_cFlags[i]==0 && g_Ticks[i]==0))
			return false;
	return true;
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
	if (debugMode>0)
		PrintToConsole(client, "Debug Depth:%i",debugMode);
	PrintToConsole(client, "Award:%s",award);
	PrintToConsole(client, "Durations:");
	PrintToConsole(client, "     Scout:%f, Soldier:%f, Pyro:%f",g_Scout,g_Soldier,g_Pyro);
	PrintToConsole(client, "     Demoman:%f, Heavy:%f, Engineer:%f",g_Demoman,g_Heavy,g_Engineer);
	PrintToConsole(client, "     Medic:%f, Sniper:%f, Spy:%f",g_Medic,g_Sniper,g_Spy);
	PrintToConsole(client, "cvar list: tauntcrits_[classname], tauntcrits_award, tauntcrits_switch, tauntcrits_notify, tauntcrits_hpcheck");
	if (debugMode>0)
	{
		PrintToConsole(client, "____________________________");
		for (new i=1;i<=MaxClients;i++)
		{
			if (g_iPlayerID[i]!=NULL_VALUE)
				GetClientName(GetClientOfUserId(g_iPlayerID[i]),award,64);
			else
				award="-none-";
			PrintToConsole(client, "i:%i userid:%i name:%s",i,g_iPlayerID[i],award);
			PrintToConsole(client, "    g_cFlags:%i g_Ticks%i",g_cFlags[i],g_Ticks[i]);
		}
	}
	PrintToConsole(client, "############################");


}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client=GetClientOfUserId(GetEventInt(event, "userid"));
	if(g_cFlags[GetPlayerID(GetClientUserId(client))]==1)
	{
		g_cFlags[GetPlayerID(GetClientUserId(client))]=10;
	} 
}

public Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client=GetClientOfUserId(GetEventInt(event, "userid"));
	if(g_cFlags[GetPlayerID(GetClientUserId(client))]==1)
	{
		g_cFlags[GetPlayerID(GetClientUserId(client))]=10;
	}
}

public Event_ClassChange(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client=GetClientOfUserId(GetEventInt(event, "userid"));
	if(g_cFlags[GetPlayerID(GetClientUserId(client))]==1)
	{
		g_cFlags[GetPlayerID(GetClientUserId(client))]=10;
	} 	
}

public OnClientPutInServer(client)
{
	AddPlayerID(client);
	g_cFlags[GetPlayerID(GetClientUserId(client))]=0;
	g_Ticks[GetPlayerID(GetClientUserId(client))]=0;
}

public OnClientDisconnect(client)
{
	//if(g_cFlags[GetPlayerID(GetClientUserId(client))]==1)
	//{
	//	g_cFlags[GetPlayerID(GetClientUserId(client))]=10;
	//} 
	RemovePlayerID(client);
}

public Action:Hook_taunt(Handle:hTimer)
{	
	new bool:bElse=false;
	if(g_bSwitch==bool:true)
	{
		if (debugMode>1)
			PrintToChatAll("[debug]public Action:Hook_taunt(Handle:hTimer)");
		for (new i=1;i<=MaxClients;i++)
		{
			if (debugMode>1)
				PrintToChatAll("[debug]for #%i started",i);
			decl client;
			if (g_iPlayerID[i]!=NULL_VALUE)
				client=GetClientOfUserId(g_iPlayerID[i]);
				
			if (debugMode>1)
				PrintToChatAll("     [debug]got throught first 'if'",i);
			if (debugMode>1)	
			if (g_iPlayerID[i]!=NULL_VALUE)
			{
				PrintToChatAll("[debug]g_iPlayerID[%i]!=NULL_VALUE",i);
				if (IsValidEdict(client))
				{
					PrintToChatAll(" [debug]IsValidEdict(%i)+",client);
					if (IsPlayerAlive(client))
						PrintToChatAll(" [debug]IsPlayerAlive(%i)+",client);
					else
						PrintToChatAll(" [debug]IsPlayerAlive(%i)-",client);
				
					if (TF2_IsPlayerInCondition(client,TFCond_Taunting))
						PrintToChatAll(" [debug]TF2_IsPlayerInCondition(%i,TFCond_Taunting)+",client);
					else
						PrintToChatAll(" [debug]TF2_IsPlayerInCondition(%i,TFCond_Taunting)-",client);
				
					PrintToChatAll(" [debug]client health=%i",GetClientHealth(client));		
				
					if (ValidWeapons(client))
						PrintToChatAll(" [debug]ValidWeapons(%i)+",client);
					else
						PrintToChatAll(" [debug]ValidWeapons(%i)-",client);
				}
				else
					PrintToChatAll(" [debug]IsValidEdict(%i)-",client);				
			}
			else
				PrintToChatAll("[debug]g_iPlayerID[%i]==NULL_VALUE",i);
			if (g_iPlayerID[i]!=NULL_VALUE && client>0 && IsValidEdict(client) && IsPlayerAlive(client) && TF2_IsPlayerInCondition(client,TFCond_Taunting) && (GetClientHealth(client)<500 || !g_bHPcheck) && g_cFlags[i]==0 && ValidWeapons(client))
			{ //it seems, like player started taunting...
				if (debugMode>1)
					PrintToChatAll("     [debug]second 'if': result 1 start",i);
				g_cFlags[i]=1;
				g_Ticks[i]=0;
				CreateTimer(0.1, HookTauntEnd,i, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				if (debugMode>0)
				{
					decl String:nickname[64];
					GetClientName(GetClientOfUserId(g_iPlayerID[i]),nickname,64);
					PrintToChatAll("    [debug] %s started taunting",nickname);
				}
				if (debugMode>1)
					PrintToChatAll("     [debug]second 'if': result 1 end",i);
			}
			else if (g_cFlags[i]==10 && g_Ticks[i]==0)
			{
				if (debugMode>1)
					PrintToChatAll("     [debug]second 'if': result 2 start",i);
				if (debugMode>1)
					PrintToChatAll("    [debug]Hook_taunt: else if (g_cFlags[i]==10 && g_Ticks[i]==0) ");
				g_cFlags[i]=0;
				if (debugMode>0)
					{
						decl String:nickname[64];
						GetClientName(GetClientOfUserId(g_iPlayerID[i]),nickname,64);
						PrintToChatAll("    [debug] %s :g_cFlags[%i] set to 0",nickname,i);
					}
				if (debugMode>1)
					PrintToChatAll("     [debug]second 'if': result 2 end",i);
			}
			else
			{
				if (debugMode>1)
					PrintToChatAll("     [debug]second 'if': result 3 start",i);
				bElse=true;
				if (debugMode>4)
				{

					if (IsPlayerAlive(client))
						PrintToChatAll("    [debug]Player alive");
					else
						PrintToChatAll("    [debug]Player not alive");
					if (TF2_IsPlayerInCondition(client,TFCond_Taunting))
						PrintToChatAll("    [debug]TF2_IsPlayerInCondition passed");
					else
						PrintToChatAll("    [debug]TF2_IsPlayerInCondition not passed");
					if (ValidWeapons(client))
						PrintToChatAll("    [debug]Valid weapons");
					else 
						PrintToChatAll("    [debug]Invalid weapons");
				}
				if (debugMode>1)
					PrintToChatAll("     [debug]second 'if': result 3 end",i);
			}
			if (debugMode>2)
				PrintToChatAll("   [debug]for #%i ended",i);
		}
		if (debugMode>1)
			PrintToChatAll("[debug] got throught 'for'");
		if (debugMode>1 && bElse)
			PrintToChatAll("[debug]Hook_taunt: else");
	}
}

public Action:HookTauntEnd(Handle:hTimer, any:playerID)
{

	new clientID=GetPlayerID(g_iPlayerID[playerID]);
	new client=GetClientOfUserId(g_iPlayerID[playerID]);
	if (g_iPlayerID[playerID]==NULL_VALUE)
	{ //player left the game
		g_cFlags[clientID]=0;
		g_Ticks[clientID]=0;
		return Plugin_Stop;
	}
	if(g_Ticks[clientID]<256)
	{
		if (g_Ticks[clientID]<=8 && client>0 && IsValidEdict(client) && IsClientInGame(client) && !TF2_IsPlayerInCondition(client,TFCond_Taunting))
		{ //no award for interrupted taunt(by falling or something else)
			g_cFlags[clientID]=10;
			g_Ticks[clientID]=0;
			return Plugin_Stop;
		}
		
		if (g_Ticks[clientID]>8 && IsValidEdict(client) && IsClientInGame(client) && !TF2_IsPlayerInCondition(client,TFCond_Taunting) && g_cFlags[clientID]!=0) 
		{	
			switch(g_cFlags[clientID])
			{
				case 1: //taunt has ended succesfully
				{
					KillTimer(hTimer);
					Check(clientID); //final check, if successfull, then client will be awarded
					g_Ticks[clientID]=0;
					g_cFlags[clientID]=0;
					if (debugMode>0)
					{
						decl String:nickname[64];
						GetClientName(client,nickname,64);
						PrintToChatAll("[debug] %s : pre-award check",nickname);
					}
					return Plugin_Stop;
				}
				case 10: //taunt interrupted.
				{
					KillTimer(hTimer);
					g_Ticks[clientID]=0;
					g_cFlags[clientID]=0;
					if (debugMode>0)
					{
						decl String:nickname[64];
						GetClientName(client,nickname,64);
						PrintToChatAll("[debug] %s failed his taunt",nickname);
					}
					return Plugin_Stop;
				}
				default: //what?
				{
					LogMessage("TauntCrits ERROR: g_cFlags defined wrong! How could this happen? value:,%i",g_cFlags[client]);
					return Plugin_Stop;
				}
			}
		}
	}
	else
	{ //breaks infinite loop
		g_cFlags[clientID]=0;
		g_Ticks[clientID]=0;
		return Plugin_Stop; 
	}
	g_Ticks[clientID]++;
	return Plugin_Continue;
}

readCvars()
{
	debugMode=GetConVarInt(cvarDebugMode);
	
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


public Action:ResetPlayersIDList(Handle:timer)
{
	if(g_bSwitch && NoChecksIProgress)
		ResetPlayersID();
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

public CvarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
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
		if(StringToInt(newValue)!=1 && StringToInt(newValue)!=2 && StringToInt(newValue)!=3) 
		{
		LogMessage("tauntcrits_award set to wrong value. Setting it to %i",StringToInt(oldValue));//im not sure it can happen at all, but...
		ResetConVar(cvarAward,false,false);
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


public Action:Check(any:clientID)
{
	new client=GetClientOfUserId(g_iPlayerID[clientID]);
	if (!(client > 0 && IsValidEdict(client) && IsClientInGame(client) && IsPlayerAlive(client)))
		return Plugin_Stop;
	new Float:dur=2.0;
	new class=int:TF2_GetPlayerClass(client);
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
				TF2_AddCondition(client, TFCond_Kritzkrieged, dur);
			case 2:
				TF2_AddCondition(client, TFCond_Buffed, dur);
			case 3:
				TF2_AddCondition(client, TFCond_Ubercharged, dur);
			default:
				LogMessage("TauntCrits ERROR: g_Mode have a wrong value. It never really was on your side.Ahem.");
		}
		if (debugMode>0)
		{
			decl String:nickname[64];
			GetClientName(client,nickname,64);
			PrintToChatAll("[debug] %s awarded",nickname);
		}
	}
	
	return Plugin_Stop;
}
/////////////////////////////////////////////////
///////////////END OF MAIN PART//////////////////
////////////////////////////////////////////////

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