#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.0.1"

#define ZOMBIECLASS_SMOKER	1
#define ZOMBIECLASS_BOOMER	2
#define ZOMBIECLASS_HUNTER	3
#define ZOMBIECLASS_SPITTER	4
#define ZOMBIECLASS_JOCKEY	5
#define ZOMBIECLASS_CHARGER	6

new ZOMBIECLASS_TANK=	5;

new String:bossname[9][10]=
{
	"",
	"smoker",
	"boomer",
	"hunter",
	"spitter",
	"jockey",
	"charger",
	"",
	"tank"
};
new Handle:l4d_super_probability[9];
new Handle:l4d_invisible_probability[9];
new Handle:l4d_super_HPmultiple[9]; 
new Handle:l4d_super_movemultiple[9];
new Handle:l4d_super_catchfire[9];
new Handle:l4d_invisible_alpha ; 

new Handle:l4d_superboss_print= INVALID_HANDLE;
new Handle:l4d_invisible_print= INVALID_HANDLE;
new Handle:l4d_superboss_enable= INVALID_HANDLE;
new Handle:l4d_invisible_enable= INVALID_HANDLE; 

new GameMode;
new L4D2Version;
public Plugin:myinfo = 
{
	name = "superBoss",
	author = "Pan Xiaohai",
	description = "superBoss",
	version = PLUGIN_VERSION,	
}

public OnPluginStart()
{
	
	GameCheck(); 	
	bossname[ZOMBIECLASS_TANK]="tank";
	
	l4d_superboss_enable = CreateConVar("l4d_superboss_enable", "1", "super infected 0:disable, 1:eanble ", FCVAR_PLUGIN);
	l4d_invisible_enable = CreateConVar("l4d_invisible_enable", "1", "invisible infected 0:disable, 1:eanble ", FCVAR_PLUGIN);
 
	
 	l4d_superboss_print = CreateConVar("l4d_superboss_print", "1", "print message when super infected spawn , 0:disable, 1:enable", FCVAR_PLUGIN);
	l4d_invisible_print = CreateConVar("l4d_invisible_print", "1", "print message when invisible infected spawn , 0:disable, 1:enable", FCVAR_PLUGIN);	

 	l4d_super_probability[ZOMBIECLASS_HUNTER]  = CreateConVar("l4d_super_probability_hunter", "8", "probalility of a hunter become a super hunter[0.0-100.0]", FCVAR_PLUGIN);
 	l4d_super_probability[ZOMBIECLASS_SMOKER]  = CreateConVar("l4d_super_probability_smoker", "8", "", FCVAR_PLUGIN);	
 	l4d_super_probability[ZOMBIECLASS_BOOMER]  = CreateConVar("l4d_super_probability_boomer", "8", "", FCVAR_PLUGIN);
 	l4d_super_probability[ZOMBIECLASS_JOCKEY]  = CreateConVar("l4d_super_probability_jockey", "8", "", FCVAR_PLUGIN);
 	l4d_super_probability[ZOMBIECLASS_SPITTER] = CreateConVar("l4d_super_probability_spitter", "8", "", FCVAR_PLUGIN);	
	l4d_super_probability[ZOMBIECLASS_CHARGER] = CreateConVar("l4d_super_probability_charger", "8", "", FCVAR_PLUGIN);
 	l4d_super_probability[ZOMBIECLASS_TANK   ] = CreateConVar("l4d_super_probability_tank", "5", "", FCVAR_PLUGIN);
 
  	l4d_invisible_probability[ZOMBIECLASS_HUNTER]  = CreateConVar("l4d_invisible_hunter", "25", "probalility of a hunter become a invisible hunter[0.0-100.0]", FCVAR_PLUGIN);
 	l4d_invisible_probability[ZOMBIECLASS_SMOKER]  = CreateConVar("l4d_invisible_smoker", "30", "", FCVAR_PLUGIN);	
 	l4d_invisible_probability[ZOMBIECLASS_BOOMER]  = CreateConVar("l4d_invisible_boomer", "20", "", FCVAR_PLUGIN);
 	l4d_invisible_probability[ZOMBIECLASS_JOCKEY]  = CreateConVar("l4d_invisible_jockey", "20", "", FCVAR_PLUGIN);
 	l4d_invisible_probability[ZOMBIECLASS_SPITTER] = CreateConVar("l4d_invisible_pitter", "50", "", FCVAR_PLUGIN);	
	l4d_invisible_probability[ZOMBIECLASS_CHARGER] = CreateConVar("l4d_invisible_charger", "20", "", FCVAR_PLUGIN);
 	l4d_invisible_probability[ZOMBIECLASS_TANK] =	 CreateConVar("l4d_invisible_tank", "4", "", FCVAR_PLUGIN);

	l4d_invisible_alpha  =	 CreateConVar("l4d_invisible_alpha", "90", "0,Completely invisible, 255, Completely visible [0, 255]", FCVAR_PLUGIN);
	
 
 	l4d_super_HPmultiple[ZOMBIECLASS_HUNTER]  =  CreateConVar("l4d_super_HPmultiple_hunter", "5", "health multiple of super hunter [0.5-20.0]", FCVAR_PLUGIN);
 	l4d_super_HPmultiple[ZOMBIECLASS_SMOKER]  =  CreateConVar("l4d_super_HPmultiple_smoker", "5", "", FCVAR_PLUGIN);	
 	l4d_super_HPmultiple[ZOMBIECLASS_BOOMER]  =  CreateConVar("l4d_super_HPmultiple_boomer", "5", "", FCVAR_PLUGIN);
 	l4d_super_HPmultiple[ZOMBIECLASS_JOCKEY]  =  CreateConVar("l4d_super_HPmultiple_jockey", "5", "", FCVAR_PLUGIN);
 	l4d_super_HPmultiple[ZOMBIECLASS_SPITTER]  = CreateConVar("l4d_super_HPmultiple_spitter", "5", "", FCVAR_PLUGIN);	
	l4d_super_HPmultiple[ZOMBIECLASS_CHARGER]  = CreateConVar("l4d_super_HPmultiple_charger", "5", "", FCVAR_PLUGIN);
	l4d_super_HPmultiple[ZOMBIECLASS_TANK   ]  = CreateConVar("l4d_super_HPmultiple_tank", "1.3", "", FCVAR_PLUGIN);

 	l4d_super_movemultiple[ZOMBIECLASS_HUNTER]  =  CreateConVar("l4d_super_movemultiple_hunter", "1.3", "movement multiple of super hunter [0.5-2.0]", FCVAR_PLUGIN);
 	l4d_super_movemultiple[ZOMBIECLASS_SMOKER]  =  CreateConVar("l4d_super_movemultiple_smoker", "1.3", "", FCVAR_PLUGIN);	
 	l4d_super_movemultiple[ZOMBIECLASS_BOOMER]  =  CreateConVar("l4d_super_movemultiple_boomer", "1.2", "", FCVAR_PLUGIN);
 	l4d_super_movemultiple[ZOMBIECLASS_JOCKEY]  =  CreateConVar("l4d_super_movemultiple_jockey", "1.3", "", FCVAR_PLUGIN);
 	l4d_super_movemultiple[ZOMBIECLASS_SPITTER]  = CreateConVar("l4d_super_movemultiple_spitter", "1.3", "", FCVAR_PLUGIN);	
	l4d_super_movemultiple[ZOMBIECLASS_CHARGER]  = CreateConVar("l4d_super_movemultiple_charger", "1.3", "", FCVAR_PLUGIN);
 	l4d_super_movemultiple[ZOMBIECLASS_TANK   ]  = CreateConVar("l4d_super_movemultiple_tank", "1.05", "", FCVAR_PLUGIN); 

 	l4d_super_catchfire[ZOMBIECLASS_HUNTER]  =  CreateConVar("l4d_super_catchfire_hunter", "10", "probalility of catch fire when super hunter spawn [0.00-100.0]", FCVAR_PLUGIN);
 	l4d_super_catchfire[ZOMBIECLASS_SMOKER]  =  CreateConVar("l4d_super_catchfire_smoker", "10", "", FCVAR_PLUGIN);	
 	l4d_super_catchfire[ZOMBIECLASS_BOOMER]  =  CreateConVar("l4d_super_catchfire_boomer", "10", "", FCVAR_PLUGIN);
 	l4d_super_catchfire[ZOMBIECLASS_JOCKEY]  =  CreateConVar("l4d_super_catchfire_jockey", "10", "", FCVAR_PLUGIN);
 	l4d_super_catchfire[ZOMBIECLASS_SPITTER]  = CreateConVar("l4d_super_catchfire_spitter", "10", "", FCVAR_PLUGIN);	
	l4d_super_catchfire[ZOMBIECLASS_CHARGER]  = CreateConVar("l4d_super_catchfire_charger", "10", "", FCVAR_PLUGIN);
 	l4d_super_catchfire[ZOMBIECLASS_TANK   ] =  CreateConVar("l4d_super_catchfire_tank", "0", "", FCVAR_PLUGIN); 
 	
	if(GameMode!=2)
	{
 
		HookEvent("player_spawn", Event_Player_Spawn);
 	
	}
	AutoExecConfig(true, "l4d_superboss_en_v11");
}
 
GameCheck()
{
	decl String:GameName[16];
	GetConVarString(FindConVar("mp_gamemode"), GameName, sizeof(GameName));
	
	
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
	
 
	GetGameFolderName(GameName, sizeof(GameName));
	if (StrEqual(GameName, "left4dead2", false))
	{
		ZOMBIECLASS_TANK=8;
		L4D2Version=true;
	}	
	else
	{
		ZOMBIECLASS_TANK=5;
		L4D2Version=false;
	}
	L4D2Version=!!L4D2Version;
} 
 
public Action:Event_Player_Spawn(Handle:event, String:event_name[], bool:dontBroadcast)
{
	
	if(GetConVarInt(l4d_superboss_enable)==0) return Plugin_Continue; 
	new client  = GetClientOfUserId(GetEventInt(event, "userid"));
 
  	if(GetClientTeam(client) == 3)
	{
		if(GetConVarInt(l4d_superboss_enable)!=0)
		{
			new class = GetEntProp(client, Prop_Send, "m_zombieClass");
			new Float:p=GetConVarFloat(l4d_super_probability[class]);
			new Float:r=GetRandomFloat(0.0, 100.0);
			if(r<p)	CreateTimer(5.0, CreatesuperBoss, client);
		}
		if(GetConVarInt(l4d_invisible_enable)!=0)
		{
			new class = GetEntProp(client, Prop_Send, "m_zombieClass");
			new Float:p=GetConVarFloat(l4d_invisible_probability[class]);
			new Float:r=GetRandomFloat(0.0, 100.0);
			if(r<p)	CreateTimer(7.0, CreateInvisibleBoss, client);
		}		
	}
  	return Plugin_Continue;
}

public Action:CreatesuperBoss(Handle:timer, any:client)
{
	if ( IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 3)
	{
	 
		new Float:hp=0.0;
		new Float:fire=0.0;
		new Float:move=0.0;
		new class = GetEntProp(client, Prop_Send, "m_zombieClass");
 

		hp=GetConVarFloat(l4d_super_HPmultiple[class]);
		move=GetConVarFloat(l4d_super_movemultiple[class]);
		fire=GetConVarFloat(l4d_super_catchfire[class]);
	  
		if(hp>0.0)
		{
			new HP = RoundFloat((GetEntProp(client, Prop_Send, "m_iHealth")*hp));
			if (HP > 65535)
			{
				HP = 65535;
			}
			SetEntProp(client, Prop_Send, "m_iHealth", HP);
			SetEntProp(client, Prop_Send, "m_iMaxHealth", HP);
		}
		if(move>0.0)
		{
			SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue",  move);
		}
		if(GetRandomFloat(0.0, 100.0)<fire)
		{
 			IgniteEntity(client, 360.0, false);
		}

		SetEntityRenderMode(client, RenderMode:3);
		new c1=GetRandomInt(0, 255);
		new c2=GetRandomInt(0, 255);
		new c3=GetRandomInt(0, 255);
		SetEntityRenderColor(client, c1, c2, c3, 255);			

		if(GetConVarInt(l4d_superboss_print)>0)
		{
			decl String:hintmsg[165];	
			Format(hintmsg, sizeof(hintmsg),  "\x03super\x04 %s \x03spawn", bossname[class] );	
			PrintToChatAll("%s ", hintmsg);
		}
	}
	return;
}
public Action:CreateInvisibleBoss(Handle:timer, any:client)
{
	if ( IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 3)
	{
 
		new class = GetEntProp(client, Prop_Send, "m_zombieClass");   
		SetEntityRenderMode(client, RenderMode:3); 
		SetEntityRenderColor(client, 255, 255, 255, GetConVarInt(l4d_invisible_alpha));			
		if(GetConVarInt(l4d_invisible_print)>0)
		{
			decl String:hintmsg[165];	
			Format(hintmsg, sizeof(hintmsg),  "\x03invisible\x04 %s \x03spawn", bossname[class] );	
			PrintToChatAll("%s ", hintmsg);
		}
	}
	return;
}