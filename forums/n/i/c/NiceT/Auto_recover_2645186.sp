#include <sourcemod>
#include <sdktools>
#include <sdktools_functions>

 
new Handle: UpdateTimer=INVALID_HANDLE;
 
new Handle:l4d_recovery_hp_add1;
new Handle:l4d_recovery_hp_add2;
new Handle:l4d_recovery_hp_add3;
new Handle:l4d_recovery_hp_duration;
new Handle:l4d_recovery_hp_enable;
new Handle:l4d_recovery_hp_limit1; 
new Handle:l4d_recovery_hp_limit2;
new Handle:l4d_recovery_hp_limit3;
new Handle:l4d_recovery_hp_max;
 
 
public Plugin:myinfo = 
{
	name = "Health Recovery",
	author = "NiceT",
	description = "I guess there are someone need some cola and rest",
	version = "1.0",
	url = ""
}

public OnPluginStart()
{ 
	l4d_recovery_hp_enable 		=		CreateConVar("l4d_recovery_hp_enable", "1", "0:disable health upgrade, 1:enable" );
	l4d_recovery_hp_add1 		=		CreateConVar("l4d_recovery_hp_add1", "5", "when hp lower than l4d_recovery_hp_limit1,hp recovery, 0:disable" );
	l4d_recovery_hp_add2 		=		CreateConVar("l4d_recovery_hp_add2", "2", "when hp lower than l4d_recovery_hp_limit2,hp recovery, 0:disable" );
	l4d_recovery_hp_add3 		=		CreateConVar("l4d_recovery_hp_add3", "1", "when hp lower than l4d_recovery_hp_limit3,hp recovery, 0:disable" );
	l4d_recovery_hp_duration 	= 		CreateConVar("l4d_recovery_hp_duration", "10", "hp recovery for every 10 seconds" );
	l4d_recovery_hp_limit1 		=		CreateConVar("l4d_recovery_hp_limit1", "25", "hp limit1" ); 
	l4d_recovery_hp_limit2 		=		CreateConVar("l4d_recovery_hp_limit2", "45", "hp limit2" ); 
	l4d_recovery_hp_limit3 		=		CreateConVar("l4d_recovery_hp_limit3", "85", "hp limit3" );
	l4d_recovery_hp_max			= 		CreateConVar("l4d_recovery_hp_max", "100", "if survivors' hp more than this, plugin stop.");
	
 	AutoExecConfig(true, "l4d_recovery");
 
}
public OnMapStart()
{ 
	UpdateTimer=CreateTimer(GetConVarFloat(l4d_recovery_hp_duration), HPTimer, 0, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
}
 
public OnMapEnd()
{
 	CloseHandle(UpdateTimer);
} 
 

public Action:HPTimer(Handle:timer, any:hp)
{
	new hp_add1=GetConVarInt(l4d_recovery_hp_add1);
	new hp_add2=GetConVarInt(l4d_recovery_hp_add2);
	new hp_add3=GetConVarInt(l4d_recovery_hp_add3);
	new hp_limit1=GetConVarInt(l4d_recovery_hp_limit1);
	new hp_limit2=GetConVarInt(l4d_recovery_hp_limit2);
	new hp_limit3=GetConVarInt(l4d_recovery_hp_limit3);
	new hp_enable=GetConVarInt(l4d_recovery_hp_enable);
	if(hp_add1<=0 || hp_add2<=0 || hp_add3<=0)return;
	
	for(new client = 1; client <= MaxClients; client++)
	{
		if( IsClientInGame(client) && GetClientTeam(client)==2 && IsPlayerAlive(client) && !IsPlayerIncapped(client))
		{
			new nowhp = GetClientHealth(client);
			if(nowhp>0 && nowhp<=hp_limit1) 
				AddHealth(client,hp_add1, hp_limit1,hp_enable );
			else if(nowhp>hp_limit1 && nowhp <=hp_limit2)
				AddHealth(client,hp_add2, hp_limit2,hp_enable );
			else
				AddHealth(client,hp_add3, hp_limit3,hp_enable );
		}
	}
}

bool:IsPlayerIncapped(client)
{
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1)) return true;
	return false;
}
AddHealth(client, hp_add,hp_limit, hp_enable)
{ 
	new hardhp = GetClientHealth(client) + 0; 
	new maxhp = GetConVarInt(l4d_recovery_hp_max);
	if(hardhp+hp_add<maxhp && hardhp+hp_add<hp_limit && hp_enable)
	{
		SetEntityHealth(client,  hardhp+hp_add);
		PrintCenterText(client, "%d + %d  = %d", hardhp, hp_add, hardhp+hp_add);
	}
	return;
} 