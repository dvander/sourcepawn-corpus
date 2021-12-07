#include <sourcemod>
#include <sdktools>
#include <sdktools_functions>
 
 
new Handle: UpdateTimer=INVALID_HANDLE;
 
new Handle:l4d_recovery_hp_add;
new Handle:l4d_recovery_hp_duration;
new Handle:l4d_recovery_hp_upgrade;
new Handle:l4d_recovery_hp_limit; 
 
 
public Plugin:myinfo = 
{
	name = "Health Recovery",
	author = "XiaoHai",
	description = " ",
	version = "1.0",
	url = ""
}
new GameMode; 
public OnPluginStart()
{ 
	new Handle:h_GameMode = FindConVar("mp_gamemode");
	decl String:GameName[16];
	GetConVarString(h_GameMode, GameName, sizeof(GameName));
	if (StrEqual(GameName, "survival", false))
		GameMode = 3;
	else if (StrEqual(GameName, "versus", false) || StrEqual(GameName, "teamversus", false) || StrEqual(GameName, "scavenge", false) || StrEqual(GameName, "teamscavenge", false))
		GameMode = 2;
	else if (StrEqual(GameName, "coop", false) || StrEqual(GameName, "realism", false))
		GameMode = 1;
	else
	{
		GameMode = 0;
 	}
	if(GameMode==2)return;
	
	l4d_recovery_hp_add =		CreateConVar("l4d_recovery_hp_add", "5", "hp recovery amount" );
	l4d_recovery_hp_duration = CreateConVar("l4d_recovery_hp_duration", "10", "hp recovery for every 10 seconds" );
	l4d_recovery_hp_upgrade =	CreateConVar("l4d_recovery_hp_upgrade", "1", "0:disable health upgrade, 1:enable" );
	l4d_recovery_hp_limit =		CreateConVar("l4d_recovery_hp_limit", "80", "hp limit" ); 
	
 	AutoExecConfig(true, "l4d_recovery");
	HookEvent("player_use", player_use);  
	HookEvent("round_end", round_end); 
	HookEvent("map_transition", round_end);	
}
public Action:player_use(Handle:event, const String:name[], bool:dontBroadcast)
{  
	if(GameMode==2)return;  
	if(UpdateTimer==INVALID_HANDLE)
	{
		//PrintToChatAll("health recovery system enabled");
		UpdateTimer=CreateTimer(GetConVarFloat(l4d_recovery_hp_duration), HPTimer, 0, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
	}
	
}
public Action:round_end(Handle:event, const String:name[], bool:dontBroadcast)
{  
	if(GameMode==2)return;  
	if(UpdateTimer!=INVALID_HANDLE)
	{
		new Handle:h=UpdateTimer;
		UpdateTimer=INVALID_HANDLE;
		KillTimer(h);
	}
} 
 
 
public Action:HPTimer(Handle:timer, any:hp)
{
	new hp_add=GetConVarInt(l4d_recovery_hp_add);
	new hp_limit=GetConVarInt(l4d_recovery_hp_limit);
	new hp_upgrade=GetConVarInt(l4d_recovery_hp_upgrade);
	if(hp_add<=0)return;
	for(new client = 1; client <= MaxClients; client++)
	{
		if( IsClientInGame(client) && GetClientTeam(client)==2 && IsPlayerAlive(client) && !IsPlayerIncapped(client))
		{
			AddHealth(client,hp_add, hp_limit,hp_upgrade  );
		}
	}
}

bool:IsPlayerIncapped(client)
{
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1)) return true;
	return false;
}
AddHealth(client, hp_add,hp_limit, hp_upgrade)
{ 
 
	new hardhp = GetClientHealth(client) + 0; 
	if(hardhp+hp_add>=hp_limit)
	{
		if(hp_upgrade==0)return;
		new count = GetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_currentReviveCount"), 1);
		
		if(count==1)
		{ 
			
			count--;

			new userflags = GetUserFlagBits(client);
			SetUserFlagBits(client, ADMFLAG_ROOT);
			new iflags=GetCommandFlags("give");
			SetCommandFlags("give", iflags & ~FCVAR_CHEAT);
			FakeClientCommand(client,"give health");
			SetCommandFlags("give", iflags);
			SetUserFlagBits(client, userflags);
			new rhp=RoundFloat(GetConVarFloat(FindConVar("pain_pills_health_value")));
			SetEntityHealth(client, rhp);
			//PrintToChatAll("\x04%N \x03's health recovered to normal", client);
			 
		}
		if(count>=2)
		{		 
			count--;
			new userflags = GetUserFlagBits(client);
			SetUserFlagBits(client, ADMFLAG_ROOT);
			new iflags=GetCommandFlags("give");
			SetCommandFlags("give", iflags & ~FCVAR_CHEAT);
			FakeClientCommand(client,"give health");
			SetCommandFlags("give", iflags);
			SetUserFlagBits(client, userflags);

			SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_currentReviveCount"), count, 1);
			new Handle:revivehealth = FindConVar("pain_pills_health_value");
			new temphpoffset = FindSendPropOffs("CTerrorPlayer","m_healthBuffer");
			SetEntDataFloat(client, temphpoffset, GetConVarFloat(revivehealth), true);
			SetEntityHealth(client, 1);
			//PrintToChatAll("\x04%N \x03's health recovered", client);
		}
	}
	else 
	{
		SetEntityHealth(client,  hardhp+hp_add);
		//PrintCenterText(client, "hp + %d  = %d", hp_add, hardhp+hp_add);
	}
 
	return;
} 