#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>



#define PLUGIN_VERSION "1.2"

public Plugin:myinfo = 
{
	name = "Taunt Crits",
	author = "HeMe3iC",
	description = "Crits for few seconds cased by taunt.",
	version = PLUGIN_VERSION,
};
new Handle:cvarScout;
new Handle:cvarSoldier;
new Handle:cvarPyro;
new Handle:cvarDemoman;
new Handle:cvarHeavy;
new Handle:cvarEngineer;
new Handle:cvarMedic;
new Handle:cvarSniper;
new Handle:cvarSpy;
new Handle:cvarMode;
new Handle:cvarSwitch;

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


public OnPluginStart()
{
	
	
	cvarScout = CreateConVar("tc_scout","2.0","How long scout will have crits after taunting",_,true,0.00,true,360.00);
	cvarSoldier = CreateConVar("tc_soldier","1.4","How long soldier will have crits after taunting",_,true,0.00,true,360.00);
	cvarPyro = CreateConVar("tc_pyro","1.8","How long pyro will have crits after taunting",_,true,0.00,true,360.00);
	cvarDemoman = CreateConVar("tc_demoman","1.5","How long demoman will have crits after taunting",_,true,0.00,true,360.00);
	cvarHeavy = CreateConVar("tc_heavy","2.0","How long heavy will have crits after taunting",_,true,0.00,true,360.00);
	cvarEngineer = CreateConVar("tc_engineer","2","How long engineer will have crits after taunting",_,true,0.00,true,360.00);
	cvarMedic = CreateConVar("tc_medic","2.0","How long medic will have crits after taunting",_,true,0.00,true,360.00);
	cvarSniper = CreateConVar("tc_sniper","1.1","How long sniper will have crits after taunting",_,true,0.00,true,360.00);
	cvarSpy = CreateConVar("tc_spy","2.0","How long spy will have crits after taunting",_,true,0.00,true,360.00);
	cvarMode = CreateConVar("tc_mode","1.0","1=crits 2=buff 3=ubercharge",_,true,1.0,true,3.0);
	cvarSwitch = CreateConVar("tc_switch","1.0","1.0=on 0.0=off",_,true,0.0,true,1.0);

	HookConVarChange(cvarScout, CvarChange);
	HookConVarChange(cvarSoldier, CvarChange);
	HookConVarChange(cvarPyro, CvarChange);
	HookConVarChange(cvarDemoman, CvarChange);
	HookConVarChange(cvarHeavy, CvarChange);
	HookConVarChange(cvarEngineer, CvarChange);
	HookConVarChange(cvarMedic, CvarChange);
	HookConVarChange(cvarSniper, CvarChange);
	HookConVarChange(cvarSpy, CvarChange);
	HookConVarChange(cvarMode, CvarChange);
	HookConVarChange(cvarSwitch, CvarChange);

	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_changeclass", Event_ClassChange);
	
	CreateTimer(1.0, Hook_taunt,_, TIMER_REPEAT);
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client=GetClientOfUserId(GetEventInt(event, "userid"));
	if(g_cFlags[client]==1)
	{
		g_cFlags[client]=10;
	} 
}

public Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client=GetClientOfUserId(GetEventInt(event, "userid"));
	if(g_cFlags[client]==1)
	{
		g_cFlags[client]=10;
	}
}

public Event_ClassChange(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client=GetClientOfUserId(GetEventInt(event, "userid"));
	if(g_cFlags[client]==1)
	{
		g_cFlags[client]=10;
	} 	
}

public OnClientDisconnect(client)
{
	if(g_cFlags[client]==1)
	{
		g_cFlags[client]=10;
	} 
}

public Action:Hook_taunt(Handle:hTimer)
{	
	new players;
	//PrintToChatAll("taunt hooking...");
	if(g_bSwitch==bool:true)
	{
		for (new client=1;client<=MaxClients;client++)
		{
			if (IsValidEdict(client) && IsClientInGame(client) && IsPlayerAlive(client) && TF2_HasCond(client,7) && g_cFlags[client]==0 &&ValidWeapons(client) )
			{
				for (new i = 1; i <= MaxClients; i++) {
					if (IsClientInGame(i)){
						if ((GetClientTeam(i) == GetClientTeam(client)) && (IsPlayerAlive(i))){
							players++;
						}
					}
				}
				if (players > 1){
					g_cFlags[client]=1;
					g_Ticks[client]=0;
					//PrintToChatAll("SOMEONE taunting...");
					//LogMessage("SOMEONE taunting...");
					CreateTimer(0.2, HookTauntEnd,client, TIMER_REPEAT);
				}
			}
		}
	}
}

public Action:HookTauntEnd(Handle:hTimer, any:client)
{
	
	if(g_Ticks[client]<256)
	{
		if (g_Ticks[client]<=5 && IsValidEdict(client) && IsClientInGame(client) && !TF2_HasCond(client,7))
		{
			g_cFlags[client]=10;
			//PrintToChatAll("client failed taunt");
		}
		
		if (g_Ticks[client]>5 && IsValidEdict(client) && IsClientInGame(client) && !TF2_HasCond(client,7) && g_cFlags[client]!=0) 
		{	
			//PrintToChatAll("switch(g_cFlags[client]) checking");
			switch(g_cFlags[client])
			{
			case 1:
			{
				KillTimer(hTimer);
				g_Ticks[client]=0;
				g_cFlags[client]=0;
				//PrintToChatAll("SOMEONE stopped taunting");
				Check(hTimer, client);
			}
			case 2:
			{
				KillTimer(hTimer);
				g_cFlags[client]=0;
				//PrintToChatAll("SOMEONE died while taunting");
			}
			case 3:
			{
				KillTimer(hTimer);
				g_cFlags[client]=0;
				//PrintToChatAll("SOMEONE hurted while taunting");
			}
			case 4:
			{
				KillTimer(hTimer);
				g_cFlags[client]=0;
				//PrintToChatAll("SOMEONE disconnected while taunting");
			}
			case 5:
			{
				KillTimer(hTimer);
				g_cFlags[client]=0;
				//PrintToChatAll("SOMEONE changed class");
			}
			case 10:
			{
				KillTimer(hTimer);
				g_Ticks[client]=0;
				g_cFlags[client]=0;
				//PrintToChatAll("Timer stopped.");
			}
			default:
			{
				PrintToChatAll("TauntCrits ERROR: g_cFlags defined wrong! Please, report to AM thread.");
				LogMessage("TauntCrits ERROR: g_cFlags defined wrong! Please, report to AM thread. value:,%i",g_cFlags[client]);
				KillTimer(hTimer);
			}
			}
		}
	}else {
		//PrintToChatAll("TauntCrits WARNING: g_Ticks limit reached!");
		LogMessage("TauntCrits WARNING: g_Ticks limit reached!");
		g_cFlags[client]=0;
		g_Ticks[client]=0;
		KillTimer(hTimer);
	}
	g_Ticks[client]++;
}

public OnMapStart()
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
	g_Mode=GetConVarInt(cvarMode);
	g_bSwitch=GetConVarBool(cvarSwitch);
	
	for (new client=1;client<=MaxClients;client++)
	{
		g_cFlags[client]=0;
		g_Ticks[client]=0;
	}
}

public CvarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar==cvarScout)
	{ 
		g_Scout=StringToFloat(newValue);
	}
	
	if (convar==cvarSoldier)
	{
		g_Soldier=StringToFloat(newValue);
	}
	if (convar==cvarPyro)
	{ 
		g_Pyro=StringToFloat(newValue); 
	}
	
	if (convar==cvarDemoman)
	{ 
		g_Demoman=StringToFloat(newValue); 
	}
	
	if (convar==cvarHeavy)
	{ 
		g_Heavy=StringToFloat(newValue); 
	}
	
	if (convar==cvarEngineer)
	{ 
		g_Engineer=StringToFloat(newValue); 
	}
	
	if (convar==cvarMedic)
	{ 
		g_Medic=StringToFloat(newValue); 
	}
	
	if (convar==cvarSniper)
	{ 
		g_Sniper=StringToFloat(newValue); 
	}
	
	if (convar==cvarSpy)
	{ 
		g_Spy=StringToFloat(newValue);
	}
	if (convar==cvarMode)
	{ 	
		if(StringToInt(newValue)!=1 && StringToInt(newValue)!=2 && StringToInt(newValue)!=3)
		{
		PrintToServer("WARNING:tc_mode set to wrong value. Setting it to 2.");
		LogMessage("TauntCrits WARNING:tc_mode set to wrong value. Setting it to 2");
		ResetConVar(cvarMode,false,false);
		g_Mode=2;
		}
		else {
		g_Mode=StringToInt(newValue);
		}
	}
	if (convar==cvarSwitch)
	{ 
		if(StringToFloat(newValue)==0.0)
		{
			g_bSwitch=bool:false;
		}
		else {
			g_bSwitch=bool:true;
		}
	}
}


public Action:Check(Handle:hTimer, any:client)
{
	//PrintToChatAll("Action:Check started");
	if (IsValidEdict(client) && IsClientInGame(client) && IsPlayerAlive(client)) 
	{
		new Float:dur=2.0;
		new class=int:TF2_GetPlayerClass(client);
		switch(class)
		{
			case TFClass_Scout:
			{ 
				dur=g_Scout;
			}
			case TFClass_Soldier:
			{ 
				dur=g_Soldier; 
			}
			case TFClass_Pyro:
			{ 
				dur=g_Pyro; 
			}
			case TFClass_DemoMan:
			{ 
				dur=g_Demoman; 
			}
			case TFClass_Heavy:
			{ 
				dur=g_Heavy; 
			}
			case TFClass_Engineer:
			{ 
				dur=g_Engineer; 
			}
			case TFClass_Medic:
			{ 
				dur=g_Medic; 
			}
			case TFClass_Sniper:
			{ 
				dur=g_Sniper; 
			}
			case TFClass_Spy:
			{ 
				dur=g_Spy; 
			}
		}
				
		//new weaponind=GetEntProp(GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon"), Prop_Send, "m_iItemDefinitionIndex");
				
		//if (dur!=0 && weaponind!=42 && weaponind!=46 && weaponind!=159 && weaponind!=163)
		if (dur>0.0 && TF2_HasCond(client,13)==bool:false && TF2_HasCond(client,14)==bool:false && TF2_HasCond(client,15)==bool:false && ValidWeapons(client))
		{
			//PrintToChatAll("Action:Check chosing taunt award");
			switch(g_Mode)
			{
			case 1:		
			{
				TF2_AddCondition(client, TFCond_Kritzkrieged, dur);
			}
			case 2:
			{
				TF2_AddCondition(client, TFCond_Buffed, dur);
			}
			case 3:
			{
				TF2_AddCondition(client, TFCond_Ubercharged, dur);
			}
			default:
			{
				PrintToChatAll("TauntCrits ERROR: g_Mode defined wrong! Please, report to AM thread.");
				LogMessage("TauntCrits ERROR: g_Mode defined wrong! Please, report to AM thread.");
			}
			}
		}
	}
}
/////////////////////////////////////////////////
///////////////END OF MAIN PART//////////////////
////////////////////////////////////////////////

stock bool:TF2_HasCond(client,i)
{
    new pcond = GetEntProp(client, Prop_Send, "m_nPlayerCond");
    return pcond >= 0 ? ((pcond & (1 << i)) != 0) : false;
}

stock bool:ValidWeapons(client)
{	
	new weaponind=GetEntProp(GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon"), Prop_Send, "m_iItemDefinitionIndex");
	if(weaponind==42 || weaponind==46 || weaponind==159 || weaponind==163)
	{
		return bool:false;
	}
	return bool:true;
}