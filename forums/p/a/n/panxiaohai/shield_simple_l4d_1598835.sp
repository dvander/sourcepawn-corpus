/* Plugin Template generated by Pawn Studio */
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdktools_functions> 
#include <sdkhooks>

#define Pai 3.14159265358979323846 

#define ShieldMode_None 0 
#define ShieldMode_Front 2
#define ShieldMode_Back 4


new g_sprite;
new ZOMBIECLASS_TANK=	5;
#define ArraySize MAXPLAYERS+1


new ShieldMode[ArraySize];
new ShieldWeaopn[ArraySize];
new MeleeEnt[ArraySize];
new MeleeEnt2[ArraySize];
new LastButton[ArraySize];
 
new GameMode;
new L4D2Version;
public Plugin:myinfo = 
{
	name = "Shield",
	author = "Pan XiaoHai",
	description = "l4d2",
	version = "1.2",
	url = "<- URL ->"
}
new Handle:l4d_shield_enabled;  

new Handle:l4d_shield_damage_from_ci; 
new Handle:l4d_shield_damage_from_si; 
new Handle:l4d_shield_damage_from_tankrock; 
new Handle:l4d_shield_damage_from_witch;
new Handle:l4d_shield_damage_from_back; 
new Handle:l4d_shield_password; 
public OnPluginStart()
{
	GameCheck();  
	//if(GameMode==2)return;
	if(!L4D2Version)return;
 
  	l4d_shield_enabled = CreateConVar("l4d_shield_enabled", "1", "0: diable shield, 1:enable shield");
  	l4d_shield_damage_from_ci = CreateConVar("l4d_shield_damage_from_ci", "0", "0: can not hurt from common infected, 1:normal");
  	l4d_shield_damage_from_si = CreateConVar("l4d_shield_damage_from_si", "0", "0: can not hurt from special infected " );
  	l4d_shield_damage_from_tankrock = CreateConVar("l4d_shield_damage_from_tankrock", "0", "0: can not hurt from tankrock " );
  	l4d_shield_damage_from_witch = CreateConVar("l4d_shield_damage_from_witch", "0", "0: can not hurt from witch " );
  	l4d_shield_damage_from_back = CreateConVar("l4d_shield_damage_from_back", "0", "0: can not hurt from back if if it's on the survivor's back, 1:normal" );
	l4d_shield_password = CreateConVar("l4d_shield_password", "1234", "give me a shield !shield + password" );

	AutoExecConfig(true, "l4d_shield_simple"); 
	
	HookEvent("player_spawn", player_spawn);
	HookEvent("player_use", player_use);
	 
	HookEvent("player_death", player_death); 
	HookEvent("player_bot_replace", player_bot_replace );	  
	HookEvent("bot_player_replace", bot_player_replace );	
	
	HookEvent("round_start", round_end);
	HookEvent("round_end", round_end); 
	HookEvent("map_transition", round_end);	 
	RegConsoleCmd("sm_shield", sm_shield);  
	ResetAllState();
 
}
public Action:sm_shield(client,args)
{  
	
	if(client>0 && GetClientTeam(client)==2 && IsPlayerAlive(client))
	{ 
		decl String:password[20]="";
		decl String:arg[20];
		GetConVarString(l4d_shield_password, password, sizeof(password));
		GetCmdArg(1, arg, sizeof(arg));
		//PrintToChatAll("arg %s, password %s", arg, password);
		if(StrEqual(arg, password))
		{
			new ent=CreateEntityByName("weapon_melee"); 
			DispatchKeyValue( ent, "melee_script_name", "riotshield"); 
			DispatchSpawn(ent);
			decl String:item[64];
			GetEdictClassname(ent,  item, sizeof(item));
			if(StrEqual(item, "weapon_melee"))
			{	
				new Float:pos[3];
				new Float:angle[3];
				GetClientEyePosition(client, pos);
				GetClientAbsAngles(client, angle);
			 
				TeleportEntity(ent, pos, angle, NULL_VECTOR);		 
			}
		}
 	}  
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
	GameMode=GameMode+0;
	GetGameFolderName(GameName, sizeof(GameName));
	if (StrEqual(GameName, "left4dead2", false))
	{
 
		L4D2Version=true;
		ZOMBIECLASS_TANK=8;
	}	
	else
	{
 
		L4D2Version=false;
		ZOMBIECLASS_TANK=5;
	}
 
}
 
public Action:player_use(Handle:hEvent, const String:strName[], bool:DontBroadcast)
{ 
	if(GetConVarInt(l4d_shield_enabled)==0)return;
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid")); 
	new ent=GetEventInt(hEvent, "targetid"); 
	if(client>0)
	{	
		if(IsFakeClient(client))return; 
		decl String:item[64];
		GetEdictClassname(ent,  item, sizeof(item));
		if(StrEqual(item, "weapon_melee"))
		{			 
			GetEntPropString(ent, Prop_Data, "m_ModelName", item, sizeof(item));
			if(StrContains(item, "shield")>0)
			{
				//PrintToChatAll("player_use shield");
				ShieldMode[client] = ShieldMode_None;
				BuildShieldMenu(client );	
				return;
			}
		}
		if(HaveShieldWeapon(client)<=0)
		{
			//ShieldMode[client] = ShieldMode[client] & ~ShieldMode_Front;
		}
	} 
	 
}
 
public Action:BuildShieldMenu( client )
{	 
	new Handle:menu = CreateMenu(MenuSelector1);
	SetMenuTitle(menu, "Do you want to build a shield?"); 
	AddMenuItem(menu, "Yes", "Yes");
	AddMenuItem(menu, "No", "No");  
	SetMenuExitButton(menu, true); 
	DisplayMenu(menu, client, 5); 
}
 
 
public MenuSelector1(Handle:menu, MenuAction:action, client, param2)
{
	if(client>0 && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client)==2)
	{
		if (action == MenuAction_Select)
		{ 
			decl String:item[256], String:display[256];		
			GetMenuItem(menu, param2, item, sizeof(item), _, display, sizeof(display));		
			if (StrEqual(item, "Yes"))
			{
				CreateShield_Front(client);
			}
			else if(StrEqual(item, "No"))
			{
				DeleteShield(client); 
			}
		}
	}
}
 

public Action:player_spawn(Handle:hEvent, const String:strName[], bool:DontBroadcast)
{ 
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));   
	if(client>0)
	{		
		DeleteShield(client);
		ResetClientState(client); 
	}
}

 
public Action:player_death(Handle:hEvent, const String:strName[], bool:DontBroadcast)
{ 
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid")); 
	if(client>0 && client<=MaxClients)
	{
 
		DeleteShield(client);
		ResetClientState(client);
	}
	 
}
public player_bot_replace(Handle:Spawn_Event, const String:Spawn_Name[], bool:Spawn_Broadcast)
{
 	new client = GetClientOfUserId(GetEventInt(Spawn_Event, "player"));
	new bot = GetClientOfUserId(GetEventInt(Spawn_Event, "bot"));   
	 
	if(client>0)
	{
		DeleteShield(client);	
		ResetClientState(client);
	}

}
public bot_player_replace(Handle:Spawn_Event, const String:Spawn_Name[], bool:Spawn_Broadcast)
{
 	new client = GetClientOfUserId(GetEventInt(Spawn_Event, "player"));
	new bot = GetClientOfUserId(GetEventInt(Spawn_Event, "bot"));   
	 
	if(bot>0)
	{ 
		ResetClientState(bot);
	}
	if(client>0)
	{
		 DeleteShield(client);
		 ResetClientState(client);
	}

} 

DeleteShield(client)
{ 
	ShieldMode[client] = ShieldMode_None; 
	SDKUnhook(client, SDKHook_OnTakeDamage,  PlayerOnTakeDamage);  
}
 
public Action:OnPlayerRunCmd(client, &buttons, &impuls, Float:vel[3], Float:angles[3], &weapon)
{
    if(ShieldMode[client] != ShieldMode_None && ShieldWeaopn[client]>0)
	{ 
		new b=buttons;
		if((b & IN_ATTACK) && (ShieldWeaopn[client]==GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon" )))
		{
			
			buttons &=~IN_ATTACK;
			//buttons &=~IN_ATTACK2;
		}
		LastButton[client]=b;
	} 
}
public Action:PlayerOnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if(victim<=0)return Plugin_Continue;
 
	new ent=ShieldWeaponInfo(victim);
	//PrintToChatAll("ent %d",ent);
	if(ent==0)
	{
		ShieldMode[victim] =ShieldMode_None;
		ShieldWeaopn[victim]=0;
		return Plugin_Continue;
	} 
	else if(ent>0)
	{
		ShieldWeaopn[victim]=ent;
		ShieldMode[victim] =ShieldMode_Front;
	}
	else if(GetConVarFloat(l4d_shield_damage_from_back)==0.0)
	{
		ShieldWeaopn[victim]=0;
		ShieldMode[victim] = ShieldMode_Back;
	}
	else 
	{
		ShieldMode[victim] =ShieldMode_None;
		ShieldWeaopn[victim]=0;
		return Plugin_Continue;
	}
	   
	if(ShieldMode[victim]==ShieldMode_None)return Plugin_Continue;
	
	decl Float:attackerPos[3];
	new Float:damageFactor=1.0;
	if(attacker>0 && attacker<=MaxClients)
	{
		GetClientAbsOrigin(attacker, attackerPos); 
		damageFactor=GetConVarFloat(l4d_shield_damage_from_si);
		//PrintToChatAll("si");
	}
	else 
	{ 
		decl String:name[64];
		GetEdictClassname(attacker, name, 64);
		if(StrEqual(name, "infected"))
		{
			GetEntPropVector(attacker, Prop_Send, "m_vecOrigin", attackerPos);
			damageFactor=GetConVarFloat(l4d_shield_damage_from_ci);
			//PrintToChatAll("ci");
		} 
		else if(StrEqual(name, "witch"))
		{
			GetEntPropVector(attacker, Prop_Send, "m_vecOrigin", attackerPos);
			damageFactor=GetConVarFloat(l4d_shield_damage_from_witch);
			//PrintToChatAll("witch");
		} 
		else if(StrEqual(name, "tank_rock"))
		{
			GetEntPropVector(attacker, Prop_Send, "m_vecOrigin", attackerPos);
			damageFactor=GetConVarFloat(l4d_shield_damage_from_tankrock);
			//PrintToChatAll("rock");
		} 		
		else return Plugin_Continue;
	}
	if(damageFactor>0.0)return Plugin_Continue;
	decl Float:playerPos[3];
	decl Float:playerAngle[3];
		
	GetClientAbsOrigin(victim, playerPos);
	GetClientEyeAngles(victim, playerAngle);
	playerAngle[0]=0.0;
	 
		
	decl Float:front[3]; 
	decl Float:dir[3];

	SubtractVectors(playerPos, attackerPos, dir); 
	NormalizeVector(dir, dir);
	GetAngleVectors(playerAngle, front, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(front,front); 
			
	new Float:a=GetAngle(dir, front)*180.0/Pai; 
	if((ShieldMode[victim] == ShieldMode_Back) && a<90.0)
	{ 
		//damage =damage*damageFactor; 
		//PrintToChatAll("damage %f factor %f  ",damage, damageFactor );
		return Plugin_Handled;
	} 
	if((ShieldMode[victim] == ShieldMode_Front) && a>90.0)
	{ 
		//damage=damage*damageFactor; 	 
		//PrintToChatAll("damage %f factor %f ",damage, damageFactor );
		
		return Plugin_Handled;
	} 
	 
	return Plugin_Continue;
}
Float:GetAngle(Float:x1[3], Float:x2[3])
{
	return ArcCosine(GetVectorDotProduct(x1, x2)/(GetVectorLength(x1)*GetVectorLength(x2)));
}
CopyVector(Float:source[3], Float:target[3])
{
	target[0]=source[0];
	target[1]=source[1];
	target[2]=source[2];
}
 
CreateShield_Front(client )
{
	new ent =HaveShieldWeapon(client);
	if(ent>0)
	{
		ShieldMode[client]=ShieldMode_Front;
		ShieldWeaopn[client]=ent;
		SDKUnhook(client, SDKHook_OnTakeDamage,  PlayerOnTakeDamage);
		SDKHook(client, SDKHook_OnTakeDamage,  PlayerOnTakeDamage);
		PrintToChat(client, "You will not be hurt from front if you hold a shield");
	} 
}

public Action:round_end(Handle:event, const String:name[], bool:dontBroadcast)
{
	ResetAllState();
}
ResetAllState()
{
	for(new i=1; i<=MaxClients; i++)
	{
		ResetClientState(i);
	}
}
ResetClientState(i)
{ 
	MeleeEnt[i]=0;
	MeleeEnt2[i]=0;
	ShieldMode[i]=ShieldMode_None;
	ShieldWeaopn[i]=0;
}
bool:IsMelee(ent)
{
	if(ent>0 && IsValidEdict(ent) && IsValidEntity(ent))
	{
		return true;
	}
	else return false;
}
HaveShieldWeapon(client)
{
	new ent=GetPlayerWeaponSlot(client, 1);
	if(ent>0)
	{
		decl String:item[64];
		GetEdictClassname(ent,  item, sizeof(item));
		if(StrEqual(item, "weapon_melee"))
		{			 
			GetEntPropString(ent, Prop_Data, "m_ModelName", item, sizeof(item));
			if(StrContains(item, "shield")>0)
			{
				return ent;
			}
		}
	}
	return 0;
}
HoldShieldWeapon(client)
{
	new ent=GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if(ent>0)
	{
		decl String:item[64];
		GetEdictClassname(ent,  item, sizeof(item));
		if(StrEqual(item, "weapon_melee"))
		{			 
			GetEntPropString(ent, Prop_Data, "m_ModelName", item, sizeof(item));
			if(StrContains(item, "shield")>0)
			{
				return ent;
			}
		}
	}
	return 0;
}
ShieldWeaponInfo(client)
{
	new ent=GetPlayerWeaponSlot(client, 1); 
	new active=GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if(ent>0)
	{
		decl String:item[64];
		GetEdictClassname(ent,  item, sizeof(item));
		if(StrEqual(item, "weapon_melee"))
		{			 
			GetEntPropString(ent, Prop_Data, "m_ModelName", item, sizeof(item));
			if(StrContains(item, "shield")>0)
			{
				if(ent==active)return ent;
				else return -ent;
			}
		}
	}
	return 0;
}
 

 
SetVector(Float:target[3], Float:x, Float:y, Float:z)
{
	target[0]=x;
	target[1]=y;
	target[2]=z;
}
IsInfected(client, type)
{
	new class = GetEntProp(client, Prop_Send, "m_zombieClass");
	if(type==class)return true;
	else return false;
}
public OnMapStart()
{  
	 
	PrecacheModel("models/weapons/melee/v_riotshield.mdl", true );
	PrecacheModel("models/weapons/melee/w_riotshield.mdl",true); 
	 
	PrecacheGeneric( "scripts/melee/riotshield.txt", true ); 
	
	g_sprite = PrecacheModel("materials/sprites/laserbeam.vmt");	
}

 