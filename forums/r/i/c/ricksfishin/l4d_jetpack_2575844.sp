#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdktools_functions>
#include <sdkhooks>

 
#define Pai 3.14159265358979323846 
#define DEBUG false
 
#define State_Fly 2
#define State_OnAir 1

//#define SOUND_FLAME		"weapons/molotov/fire_loop_1.wav"  
#define SOUND_FLAME		"ambient/gas/steam2.wav"  
new Handle:l4d_fly_enable ;   
new Handle:l4d_fly_msg ; 
new Handle:l4d_fly_fuel ; 
new Handle:l4d_fly_speed ; 
new Handle:l4d_fly_infected ;
new Handle:l4d_fly_password ;
new Handle:l4d_fly_controlmode ;
new Handle:l4d_fly_tongue_grab ;
new Handle:l4d_fly_drop_tank ;
new Handle:l4d_fly_drop_witch ;

new GameMode;
new L4D2Version;
 
new DummyEnt[MAXPLAYERS+1];  
new bool:HaveJetPack[MAXPLAYERS+1]; 
new FlyState[MAXPLAYERS+1]; 
new Suspend[MAXPLAYERS+1]; 
new JetPackB1Ent[MAXPLAYERS+1];
new JetPackB2Ent[MAXPLAYERS+1];
new JetPackB1Flame[MAXPLAYERS+1][3];
new JetPackB2Flame[MAXPLAYERS+1][3];
new Started[MAXPLAYERS+1]; 
new bool:Broken[MAXPLAYERS+1]; 
new LastButton[MAXPLAYERS+1]; 
new Float:LastTime[MAXPLAYERS+1]; 
new Float:Gravity[MAXPLAYERS+1];
new Float:Fuel[MAXPLAYERS+1]; 
new Float:TimerIndicator[MAXPLAYERS+1];
new Float:LostPos[MAXPLAYERS+1][3];
new JetPackDropEnt[MAXPLAYERS+1];
new JetPackDropButton[MAXPLAYERS+1];
new Float:JetPackDropFuel[MAXPLAYERS+1];
new DropCount=0;
new ShowMsg[MAXPLAYERS+1]; 
 
new g_sprite;
new g_iVelocity ;
new g_iOffsetGlow;
public Plugin:myinfo = 
{
	name = "Jet Pack",
	author = "Pan Xiaohai",
	description = "",
	version = "1.06",	
}
 
public OnPluginStart()
{
	GameCheck(); 	
 	l4d_fly_enable = CreateConVar("l4d_fly_enable", "2", "  0:disable, 1:enable in coop mode, 2: enable in all mode ", FCVAR_SPONLY);
	l4d_fly_msg=CreateConVar("l4d_fly_msg", "1", "how many times to display usage information , 0 disable  ", FCVAR_SPONLY);	
	l4d_fly_fuel=CreateConVar("l4d_fly_fuel", "120.0", "the fuel of jet pack [seconds]", FCVAR_SPONLY);	
	l4d_fly_speed=CreateConVar("l4d_fly_speed", "100.0", "max speed of jet pack", FCVAR_SPONLY);	
	l4d_fly_infected=CreateConVar("l4d_fly_infected", "1", "infected use 0:disable, 1:enable  ", FCVAR_SPONLY);
	l4d_fly_password=CreateConVar("l4d_fly_password", "", " !jetpack + password to build a jet pack", FCVAR_SPONLY);
	l4d_fly_controlmode=CreateConVar("l4d_fly_controlmode", "1", "0: good for host but bad for player, 1: control by gravity, it is good for high ping player", FCVAR_SPONLY);
	l4d_fly_tongue_grab=CreateConVar("l4d_fly_tongue_grab", "1", "0:do not fall when tongue grab, 1: fall", FCVAR_SPONLY);

	l4d_fly_drop_tank=CreateConVar("l4d_fly_drop_tank", "20.0", "chance of drop from tank", FCVAR_SPONLY);
	l4d_fly_drop_witch=CreateConVar("l4d_fly_drop_witch", "60.0", "chance of drop from witch", FCVAR_SPONLY);
	
 	AutoExecConfig(true, "l4d_jetpack");   
	g_iVelocity = FindSendPropInfo("CBasePlayer", "m_vecVelocity[0]");
	HookEvent("player_bot_replace", player_bot_replace );	 
	HookEvent("player_jump", player_jump);
	if(L4D2Version)
	{
		HookEvent("jockey_ride", infected_ablility);
		HookEvent("charger_carry_start", infected_ablility);
		g_iOffsetGlow = FindSendPropInfo("prop_physics", "m_nGlowRange");
	}
	HookEvent("tongue_grab",  tongue_grab);
	HookEvent("player_ledge_grab",  player_ledge_grab);
	HookEvent("lunge_pounce", infected_ablility);
	HookEvent("player_incapacitated_start", player_incapacitated_start); 	
	HookEvent("player_death", player_death);
	HookEvent("player_spawn", player_spawn);
	
	HookEvent("witch_killed", witch_killed ); 
	HookEvent("tank_killed", tank_killed );
	
	HookEvent("round_start", round_end);
	HookEvent("round_end", round_end);
	HookEvent("finale_win", round_end);
	HookEvent("mission_lost", round_end);
	HookEvent("map_transition", round_end);	
	HookEvent("player_use", player_use);  
	RegConsoleCmd("sm_jetpack", sm_jetpack);
	
	
	//RegConsoleCmd("sm_givejetpack", sm_givejetpack);
	ResetAllState();
} 
public Action:player_use(Handle:hEvent, const String:strName[], bool:DontBroadcast)
{
	
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(!CanUse(client))return;
	new ent=GetEventInt(hEvent, "targetid"); 
	if(HaveOxygentank(client))
	{	
		if(HaveJetPack[client]==false )
		{
			BuildJetPackMenu(client, ent);				 
		}		 
		else
		{
			FillFuelMenu(client, ent);
		}		
	}
	else if((HavePropanetank(client) || HaveGascan(client))&& HaveJetPack[client]!=false )
	{
		FillFuelMenu(client, ent);
	}
 
}
public Action:BuildJetPackMenu( client , ent)
{	 
	new Handle:menu = CreateMenu(MenuSelector1);
	SetMenuTitle(menu, "Do you want to build a jet pack?"); 
	AddMenuItem(menu, "Yes", "Yes");
	AddMenuItem(menu, "No", "No"); 
	SetMenuExitButton(menu, true);
	 
	DisplayMenu(menu, client, 2); 
}
public Action:FillFuelMenu( client , ent)
{
 	new Handle:menu = CreateMenu(MenuSelector2);
	SetMenuTitle(menu, "Do you want to fuel your jet pack?"); 
	AddMenuItem(menu, "Yes", "Yes");
	AddMenuItem(menu, "No", "No"); 
	SetMenuExitButton(menu, true); 
	DisplayMenu(menu, client, 2); 
}
public MenuSelector1(Handle:menu, MenuAction:action, client, param2)
{
	
	if (action == MenuAction_Select)
	{ 
		decl String:item[256], String:display[256];		
		GetMenuItem(menu, param2, item, sizeof(item), _, display, sizeof(display));		
		if (StrEqual(item, "Yes"))
		{
			if( HaveJetPack[client]==false)
			{
				if(L4D2Version)SetupProgressBar(client, 5.0);
				 
				TimerIndicator[client]=GetEngineTime()+5.0;
				CreateTimer(0.1, BuildJetPackTimer, client, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
			}
		}
		else if(StrEqual(item, "No"))
		{
		}
	}
	 
}

public Action:BuildJetPackTimer(Handle:timer, any:client)
{
	if(!(IsClientInGame(client) && IsPlayerAlive(client)))
	{
		return Plugin_Stop;
	}
	if(HaveOxygentank(client) && HaveJetPack[client]==false)
	{
		if(GetEngineTime()>=TimerIndicator[client])
		{
			PrintHintText(client, "Build jet pack successfully");
			SetupJetPack(client);
			RemoveOxygenPropaneTank(client);
			return Plugin_Stop;
		}
		if(!L4D2Version)PrintCenterText(client, "build progress %d ", RoundFloat((5.0-(TimerIndicator[client]-GetEngineTime()))/5.0*100.0 ));
	}
	else
	{
		
		if(L4D2Version)KillProgressBar(client);
		return Plugin_Stop;
	}
	return Plugin_Continue;
}
 
public MenuSelector2(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
	 
		decl String:item[256], String:display[256];		
		GetMenuItem(menu, param2, item, sizeof(item), _, display, sizeof(display));		
		if (StrEqual(item, "Yes"))
		{
			if( HaveJetPack[client]!=false )
			{	 
				if(L4D2Version)SetupProgressBar(client, 5.0);				 
				TimerIndicator[client]=GetEngineTime()+5.0;
				CreateTimer(0.1, FuelJetPackTimer, client, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);				
			}
		}
		else if(StrEqual(item, "No"))
		{
		}
	}
}
public Action:FuelJetPackTimer(Handle:timer, any:client)
{
	if(!(IsClientInGame(client) && IsPlayerAlive(client)))
	{
		return Plugin_Stop;
	}
	if( HaveJetPack[client]!=false && ( HaveOxygentank(client) || HavePropanetank(client) || HaveGascan(client)))
	{
		if(GetEngineTime()>=TimerIndicator[client])
		{
			Fuel[client]=GetConVarFloat(l4d_fly_fuel);	
			PrintHintText(client, "Fuel jet pack successfully");
			RemoveOxygenPropaneTank(client);
			return Plugin_Stop;
		}
		if(!L4D2Version)PrintCenterText(client, "fuel progress %d ", RoundFloat((5.0-(TimerIndicator[client]-GetEngineTime()))/5.0*100.0 ));
	}
	else
	{
		
		if(L4D2Version)KillProgressBar(client);
		return Plugin_Stop;
	}
	return Plugin_Continue;
}
public Action:sm_jetpack(client,args)
{
	if(client>0 && IsClientInGame(client) && IsPlayerAlive(client))
	{
		if(HaveJetPack[client]!=false)RemoveJetPack(client, true);
		else
		{
			decl String:password[20]="";
			decl String:arg[20];
			GetConVarString(l4d_fly_password, password, sizeof(password));
			GetCmdArg(1, arg, sizeof(arg));
			//PrintToChatAll("arg %s, password %s", arg, password);
			if(StrEqual(arg, password))SetupJetPack(client);
			else PrintToChat(client, "Your password is incorrect");
		}
	}
}
public Action:sm_givejetpack(client,args)
{
	if(client>0 && IsClientInGame(client) && IsPlayerAlive(client))
	{
		if(HaveJetPack[client]!=false) 
		{
			 PrintToChat(client, "Your already have a jet pack");
		}
		else
		{
			SetupJetPack(client);
		}
	}
}
HaveOxygentank(client)
{
	decl String:name[50];
	GetClientWeapon(client, name, 50);
	if(StrEqual( name, "weapon_oxygentank") )	return 1;
	return 0;
}
HavePropanetank(client)
{
	decl String:name[50];
	GetClientWeapon(client, name, 50);
	if(StrEqual( name, "weapon_propanetank") )	return 1;
	return 0;
}
HaveGascan(client)
{
	decl String:name[50];
	GetClientWeapon(client, name, 50);
	if(StrEqual( name, "weapon_gascan") )	return 1;
	return 0;
}
RemoveOxygenPropaneTank( client)
{
	if(HaveOxygentank(client) || HavePropanetank(client)|| HaveGascan(client))
	{
		new ent=GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
		RemoveEdict(ent);
		//RemovePlayerItem(client, ent);
	}
}
public tongue_grab(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(l4d_fly_enable)==0)return;
	if(GetConVarInt(l4d_fly_tongue_grab)==0)return;
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));  
	StopFly(victim);
}
public infected_ablility(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(l4d_fly_enable)==0)return;
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));  
	EndJump(victim);
}
public player_ledge_grab(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(l4d_fly_enable)==0)return;
	new victim = GetClientOfUserId(GetEventInt(event, "userid")); 
	EndJump(victim);
}
public player_incapacitated_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(l4d_fly_enable)==0)return; 
	new victim = GetClientOfUserId(GetEventInt(event, "userid")); 
	EndJump(victim);
}
public player_bot_replace(Handle:Spawn_Event, const String:Spawn_Name[], bool:Spawn_Broadcast)
{
	if(GetConVarInt(l4d_fly_enable)==0)return; 
	new client = GetClientOfUserId(GetEventInt(Spawn_Event, "player"));
	new bot = GetClientOfUserId(GetEventInt(Spawn_Event, "bot")); 
	RemoveJetPack(client, true);
	RemoveJetPack(bot); 

}
public Action:player_jump(Handle:hEvent, const String:name[], bool:dontBroadcast)
{ 
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid")); 
	if(IsFakeClient(client))return;   
	if(!CanUse(client))return;
	if( HaveJetPack[client]==true || GetClientTeam(client)==2)
	{	
		StartJump(client); 
		return;
	}	
	if(HaveJetPack[client]==false &&  GetClientTeam(client)==3 && GetConVarInt(l4d_fly_infected)==1)
	{
		new button=GetClientButtons(client);
		if( ( button & IN_DUCK ) && ! ( button & IN_ATTACK ))
		{
			new ent= GetOxygentank(client);	 
			if(ent>0)
			{
				SetupJetPack(client);
				new find=-1;
				for(new i=0; i<DropCount; i++)
				{ 
					if(ent==JetPackDropEnt[i])
					{
						find=i;
						break;
					}
				}
				if(find >=0)
				{ 
					Fuel[client]=JetPackDropFuel[find];
					if(JetPackDropEnt[find]>0 && IsValidEntity(JetPackDropEnt[find]) && IsValidEdict(JetPackDropEnt[find]))
					{
						AcceptEntityInput(JetPackDropEnt[find], "kill"); 
					}
					for(new i=find; i<DropCount; i++)
					{
						JetPackDropFuel[i]=JetPackDropFuel[i+1];
						JetPackDropEnt[i]=JetPackDropEnt[i+1];
						JetPackDropButton[i]=JetPackDropButton[i+1];
					}
					DropCount--;
				}
				else AcceptEntityInput(ent, "kill"); 	
			}
					
		}		
	}
	 
	return;
 }
public Action:player_death(Handle:hEvent, const String:strName[], bool:DontBroadcast)
{
	if(GetConVarInt(l4d_fly_enable)==0)return;
	new victim = GetClientOfUserId(GetEventInt(hEvent, "userid"));  
	RemoveJetPack(victim, true); 
}
public Action:witch_killed(Handle:h_Event, const String:s_Name[], bool:b_DontBroadcast)
{ 
	new witchid = GetEventInt(h_Event, "witchid");
	if(witchid>0)
	{
		if(GetRandomFloat(0.0, 100.0)<GetConVarFloat(l4d_fly_drop_witch))
		{
			new Float:pos[3];
			GetEntPropVector(witchid, Prop_Send, "m_vecOrigin", pos);  
			//pos[2]+=50.0;
			DropJetpack(pos, 1);
		}
	}
	return Plugin_Handled;
}
public Action:tank_killed(Handle:hEvent, const String:strName[], bool:DontBroadcast)
{ 
	new victim = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(victim>0)
	{
		if(GetRandomFloat(0.0, 100.0)<GetConVarFloat(l4d_fly_drop_tank))
		{
			new Float:pos[3];
			GetEntPropVector(victim, Prop_Send, "m_vecOrigin", pos);  
			//pos[2]+=50.0;
			DropJetpack(pos, 0);
		}
	} 
}
DropJetpack(Float:pos[3], flag)
{
	new client=0; 
	CopyVector(pos, LostPos[client]);
	new ent=CreateJetPackDrop(client);
	AttachFlame(client, ent, JetPackB1Flame[client]);
	AcceptEntityInput(JetPackB1Flame[client][1], "TurnOn");
	new button=CreateButton(ent);
	JetPackDropButton[DropCount]=button;
	JetPackDropEnt[DropCount]=ent;
	JetPackDropFuel[DropCount]=GetConVarFloat(l4d_fly_fuel);
	DropCount++;
	if(flag==0)PrintToChatAll("A jet pack was dropped from tank");
	if(flag==1)PrintToChatAll("A jet pack was dropped from witch");
}
public Action:player_spawn(Handle:hEvent, const String:strName[], bool:DontBroadcast)
{
	if(GetConVarInt(l4d_fly_enable)==0)return;
	new victim = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	SetEntityGravity(victim, 1.0);
	SetEntityMoveType(victim, MOVETYPE_WALK); 
}
 
bool:CanUse(client)
{
	client=client+1-1;
 	new mode=GetConVarInt(l4d_fly_enable);
	if(mode==0)return false;
	if(mode==1 && GameMode==2)return false;
	return true; 
}
RemoveJetPack(client, bool:drop=false)
{
	if(HaveJetPack[client]==false)return; 
	HaveJetPack[client]=false;
	SDKUnhook( client, SDKHook_PreThink,  PreThink); 	
	StopSound(JetPackB1Ent[client], SNDCHAN_WEAPON, SOUND_FLAME); 	  
	new b=IsVilidPlayer(client);	
	if(b)SetEntityGravity(client, 1.0);   
	if(b)SetEntityMoveType(client, MOVETYPE_WALK);
		 
	if(JetPackB1Ent[client]>0 && IsValidEdict(JetPackB1Ent[client]) && IsValidEntity(JetPackB1Ent[client]) )  // remove dummy body
	{
		AcceptEntityInput(JetPackB1Ent[client], "ClearParent");
		AcceptEntityInput(JetPackB1Ent[client], "kill"); 
	}
	if(JetPackB2Ent[client]>0 && IsValidEdict(JetPackB2Ent[client]) && IsValidEntity(JetPackB2Ent[client]) )  // remove dummy body
	{
		AcceptEntityInput(JetPackB2Ent[client], "ClearParent");
		AcceptEntityInput(JetPackB2Ent[client], "kill"); 
	}	 
	JetPackB1Ent[client]=0;
	JetPackB2Ent[client]=0;
	if(drop)
	{
		new ent=0; 
		ent=CreateJetPackDrop(client);
		AttachFlame(client, ent, JetPackB1Flame[client]);
		AcceptEntityInput(JetPackB1Flame[client][1], "TurnOn");
		new button=CreateButton(ent);
		JetPackDropButton[DropCount]=button;
		JetPackDropEnt[DropCount]=ent;
		JetPackDropFuel[DropCount]=Fuel[client];
		DropCount++;
		PrintToChatAll("A jet pack was dropped");
	}	
}
 
SetupJetPack(client)
{  
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		
		new jetpackb1=CreateJetPackB1(client);
		new jetpackb2=CreateJetPackB2(client);  
		JetPackB1Ent[client]=jetpackb1;
		JetPackB2Ent[client]=jetpackb2; 
		AttachFlame(client, jetpackb1, JetPackB1Flame[client]);
		AttachFlame(client, jetpackb2, JetPackB2Flame[client]);
		Fuel[client]=GetConVarFloat(l4d_fly_fuel);
		HaveJetPack[client]=true; 
		CreateTimer(1.0, ShowInfo,client); 
	}
}
CreateJetPackDrop(client )
{
	
	new Float:pos[3];
	new Float:vel[3]; 
	new jetpack=CreateEntityByName("prop_dynamic_override"); 
	DispatchKeyValue(jetpack, "model", "models/props_equipment/oxygentank01.mdl");   
	DispatchSpawn(jetpack); 
	SetEntProp(jetpack, Prop_Data, "m_takedamage", 0, 1);  
	if(client>0 && IsClientInGame(client) && IsPlayerAlive(client))GetClientAbsOrigin(client, pos);
	else CopyVector(LostPos[client], pos);
	SetVector(vel, GetRandomFloat(-20.0, 20.0),  GetRandomFloat(-20.0, 20.0), 100.0);
	TeleportEntity(jetpack, pos, NULL_VECTOR, vel);  
	
	if(L4D2Version)
	{
		SetEntProp(jetpack, Prop_Send, "m_iGlowType", 3 ); //3
		SetEntProp(jetpack, Prop_Send, "m_nGlowRange", 0 ); //0
		SetEntProp(jetpack, Prop_Send, "m_glowColorOverride", 1); //1	
	}
	DispatchKeyValueFloat(jetpack, "fademindist", 10000.0);
	DispatchKeyValueFloat(jetpack, "fademaxdist", 20000.0);
	DispatchKeyValueFloat(jetpack, "fadescale", 0.0); 
	return 	jetpack;
}

CreateJetPackB1(client)
{
	new Float:pos[3];
	new Float:ang[3];
	GetClientEyePosition(client, pos);
	GetClientAbsAngles(client, ang);
	new jetpack=CreateEntityByName("prop_dynamic_override"); 
	DispatchKeyValue(jetpack, "model", "models/props_equipment/oxygentank01.mdl");  
	DispatchSpawn(jetpack); 
	SetEntProp(jetpack, Prop_Data, "m_takedamage", 0, 1);  
	SetEntityMoveType(jetpack, MOVETYPE_NOCLIP);    
	SetEntProp(jetpack, Prop_Data, "m_CollisionGroup", 2); 
	if(GetClientTeam(client)==2)AttachJetPack(jetpack, client, 0); 	
	else AttachJetPack(jetpack, client, 1); 	
	decl Float:ang3[3];
	SetVector(ang3, 0.0, 0.0, 1.0); 
	GetVectorAngles(ang3, ang3); 
	CopyVector(ang,ang3);
	if( GetClientTeam(client)==2)
	{
		ang3[2]+=270.0; 
		ang3[1]-=10.0; 
		SetVector(pos,  0.0,  -5.0,  4.0);
	}
	else
	{
		ang3[2]+=90.0; 
		SetVector(pos,  0.0,  30.0,  -4.0);
	}
	DispatchKeyValueVector(jetpack, "origin", pos);  
	DispatchKeyValueVector(jetpack, "Angles", ang3); 
	TeleportEntity(jetpack, pos, NULL_VECTOR, ang3); 	
 
	
	if(L4D2Version)
	{
		SetEntProp(jetpack, Prop_Send, "m_iGlowType", 3 ); //3
		SetEntProp(jetpack, Prop_Send, "m_nGlowRange", 0 ); //0
		SetEntProp(jetpack, Prop_Send, "m_glowColorOverride", 1); //1	
	}	
	return 	jetpack;
}
CreateJetPackB2(client )
{
	new Float:pos[3];
	new Float:ang[3];
	GetClientEyePosition(client, pos);
	GetClientAbsAngles(client, ang);
	new jetpack=CreateEntityByName("prop_dynamic_override"); 
	DispatchKeyValue(jetpack, "model", "models/props_equipment/oxygentank01.mdl");  
	DispatchSpawn(jetpack); 
	SetEntProp(jetpack, Prop_Data, "m_takedamage", 0, 1); 	 
	SetEntityMoveType(jetpack, MOVETYPE_NOCLIP);    
	SetEntProp(jetpack, Prop_Data, "m_CollisionGroup", 2); 
	if(GetClientTeam(client)==2)AttachJetPack(jetpack, client, 0); 	
	else AttachJetPack(jetpack, client, 2); 
	
	decl Float:ang3[3];
	SetVector(ang3, 0.0, 0.0, 1.0);
	GetVectorAngles(ang3, ang3); 
	CopyVector(ang,ang3);
	if( GetClientTeam(client)==2)
	{
		ang3[2]+=270.0; 
		ang3[1]-=10.0; 
		SetVector(pos,  0.0,  -5.0,  -4.0);
	}
	else
	{
		ang3[2]+=90.0; 
		SetVector(pos,  0.0,  30.0,  4.0);
	} 
	
	DispatchKeyValueVector(jetpack, "origin", pos);  
	DispatchKeyValueVector(jetpack, "Angles", ang3); 
	TeleportEntity(jetpack, pos, NULL_VECTOR, ang3); 	 
	
	if(L4D2Version)
	{
		SetEntProp(jetpack, Prop_Send, "m_iGlowType", 3 ); //3
		SetEntProp(jetpack, Prop_Send, "m_nGlowRange", 0 ); //0
		SetEntProp(jetpack, Prop_Send, "m_glowColorOverride", 1); //1	
	}
	
	return 	jetpack;
}
 
GetOxygentank(client)
{
	decl Float:pos[3];
	decl Float:angle[3];
	GetClientEyePosition(client, pos);
	GetClientEyeAngles(client, angle); 
	
	new Handle:trace= TR_TraceRayFilterEx(pos, angle, MASK_SHOT, RayType_Infinite, TraceRayDontHitSelf, client); 
	new ent=0; 
	if(TR_DidHit(trace))
	{			
	 
		new ent2=TR_GetEntityIndex(trace); 
		TR_GetEndPosition(angle, trace);
		if(ent2>0)
		{			
			decl String:classname[64];
			GetEdictClassname(ent2, classname, 64);	
			 
			if(StrEqual(classname, "prop_physics"))
			{
				GetEntPropString(ent2, Prop_Data, "m_ModelName", classname, 64); 
				if(StrEqual(classname, "models/props_equipment/oxygentank01.mdl"))
				{
					ent=ent2;
				}
			}
			else if(StrEqual(classname, "weapon_oxygentank"))
			{			 
				ent=ent2;				 
			}
		} 
	}
	CloseHandle(trace);
	if(ent>0)
	{
		 
		new Float:pos2[3];
	 
		for(new i=1; i<=MaxClients; i++)
		{
			if(HaveJetPack[i]!=false)
			{
				if(IsClientInGame(i) && IsPlayerAlive(i))
				{
					GetClientEyePosition(i, pos2); 
					if(GetVectorDistance(pos, pos2)<200.0)
					{
						ent=0;
						break;
					}
				}
			}			
		}	
	}
	return ent;
}
public bool:TraceRayDontHitSelf(entity, mask, any:data)
{
	if(entity<=0)return false;
	if(entity == data) 
	{
		return false; 
	} 
	return true;
}
AttachJetPack(ent, owner, position)
{
	 
	if(owner>0 && ent>0)
	{
		if(owner<MaxClients)
		{
			decl String:sTemp[16];
			Format(sTemp, sizeof(sTemp), "target%d", owner);
			DispatchKeyValue(owner, "targetname", sTemp);
			SetVariantString(sTemp);
			AcceptEntityInput(ent, "SetParent", ent, ent, 0);
			if(position==0)SetVariantString("medkit");
			if(position==1)SetVariantString("lfoot");  
			if(position==2)SetVariantString("rfoot"); 
			AcceptEntityInput(ent, "SetParentAttachment");
		}
	}
	 
}
AttachFlame( client, ent, flames[3] )
{
	client=client+0;
	decl String:flame_name[128];
	Format(flame_name, sizeof(flame_name), "target%d", ent);
	new flame = CreateEntityByName("env_steam");
	DispatchKeyValue( ent,"targetname", flame_name);
	DispatchKeyValue(flame,"parentname", flame_name);
	DispatchKeyValue(flame,"SpawnFlags", "1");
	DispatchKeyValue(flame,"Type", "0");
 
	DispatchKeyValue(flame,"InitialState", "1");
	DispatchKeyValue(flame,"Spreadspeed", "1");
	DispatchKeyValue(flame,"Speed", "250");
	DispatchKeyValue(flame,"Startsize", "2");
	DispatchKeyValue(flame,"EndSize", "4");
	DispatchKeyValue(flame,"Rate", "555");
	DispatchKeyValue(flame,"RenderColor", "10 52 99"); 
	DispatchKeyValue(flame,"JetLength", "20"); 
	DispatchKeyValue(flame,"RenderAmt", "180");
	
	DispatchSpawn(flame);	 
	SetVariantString(flame_name);
	AcceptEntityInput(flame, "SetParent", flame, flame, 0);
	
	new Float:origin[3];
	SetVector(origin,  -2.0, 0.0,  26.0);
	decl Float:ang[3];
	SetVector(ang, 0.0, 0.0, 1.0); 
	GetVectorAngles(ang, ang); 
	TeleportEntity(flame, origin, ang,NULL_VECTOR);	
	AcceptEntityInput(flame, "TurnOn");
	
 
	new flame2 = CreateEntityByName("env_steam");
	DispatchKeyValue( ent,"targetname", flame_name);
	DispatchKeyValue(flame2,"parentname", flame_name);
	DispatchKeyValue(flame2,"SpawnFlags", "1");
	DispatchKeyValue(flame2,"Type", "0");
 
	DispatchKeyValue(flame2,"InitialState", "1");
	DispatchKeyValue(flame2,"Spreadspeed", "1");
	DispatchKeyValue(flame2,"Speed", "300");
	DispatchKeyValue(flame2,"Startsize", "3");
	DispatchKeyValue(flame2,"EndSize", "10");
	DispatchKeyValue(flame2,"Rate", "555");
	DispatchKeyValue(flame2,"RenderColor", "50 30 255");//"16 85 160" 
	DispatchKeyValue(flame2,"JetLength", "50"); 
	DispatchKeyValue(flame2,"RenderAmt", "180");
	
	DispatchSpawn(flame2);	 
	SetVariantString(flame_name);
	AcceptEntityInput(flame2, "SetParent", flame2, flame2, 0);
	TeleportEntity(flame2, origin, ang,NULL_VECTOR);
	AcceptEntityInput(flame2, "TurnOff");
	
	new flame3 = CreateEntityByName("env_steam");
	DispatchKeyValue( ent,"targetname", flame_name);
	DispatchKeyValue(flame3,"SpawnFlags", "1");
	DispatchKeyValue(flame3,"Type", "0");
	DispatchKeyValue(flame3,"InitialState", "1");
	DispatchKeyValue(flame3,"Spreadspeed", "10");
	DispatchKeyValue(flame3,"Speed", "350");
	DispatchKeyValue(flame3,"Startsize", "5");
	DispatchKeyValue(flame3,"EndSize", "15");
	DispatchKeyValue(flame3,"Rate", "555");
	DispatchKeyValue(flame3,"RenderColor", "242 55 55"); 
	DispatchKeyValue(flame3,"JetLength", "70"); 
	DispatchKeyValue(flame3,"RenderAmt", "180");
	
	DispatchSpawn(flame3);	 
	SetVariantString(flame_name);
	AcceptEntityInput(flame3, "SetParent", flame2, flame2, 0);
	TeleportEntity(flame3, origin, ang,NULL_VECTOR);
	AcceptEntityInput(flame3, "TurnOff");	
	
	flames[0]=flame;
	flames[1]=flame2; 
	flames[2]=flame3; 
}
StartJump(client)
{
	if(client>0 && HaveJetPack[client]==true)
	{
		if(Fuel[client]>0.0)
		{
			FlyState[client]=State_OnAir;
			LastButton[client]=0;
			Started[client]=0;
			LastTime[client]=GetEngineTime(); 
			Broken[client]=false;
			Suspend[client]=0;
			if(GetConVarInt(l4d_fly_controlmode)==0)
			{
				DummyEnt[client]=0;
			}
			SDKUnhook( client, SDKHook_PreThink,  PreThink); 
			SDKHook( client, SDKHook_PreThink,  PreThink);  
			if(ShowMsg[client]<GetConVarInt(l4d_fly_msg) && HaveJetPack[client]!=false)
			{
				if(CanUse(client))CreateTimer(1.0, ShowInfo2,client); 
				ShowMsg[client]++;
			}
		}
		else
		{
			PrintHintText(client, "You jet pack is short of fuel , please look for oxygentank,propanetank or gascan");
		}
	}
}
EndJump(client)
{
	if(HaveJetPack[client]==false)return;   
	SDKUnhook( client, SDKHook_PreThink,  PreThink);  
	new b=IsVilidPlayer(client); 
	if(b)SetEntityGravity(client, 1.0);   
	if(b)SetEntityMoveType(client, MOVETYPE_WALK); 
	StopSound(JetPackB1Ent[client], SNDCHAN_WEAPON, SOUND_FLAME);
	AcceptEntityInput(JetPackB1Flame[client][1], "TurnOff");	
	AcceptEntityInput(JetPackB1Flame[client][2], "TurnOff");	
	AcceptEntityInput(JetPackB2Flame[client][1], "TurnOff");	
	AcceptEntityInput(JetPackB2Flame[client][2], "TurnOff");
}

StartFly(client)
{
	FlyState[client]=State_Fly;
	Started[client]=0;
	Broken[client]=false;
}
StopFly(client)
{
	FlyState[client]=State_OnAir;
	SetEntityGravity(client, 1.0);
}

public PreThink(client)
{
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		new Float:time=GetEngineTime( );
		new Float:intervual=time-LastTime[client]; 
		new button=GetClientButtons(client); 
		if(FlyState[client]==State_Fly)	OnFly(client,button , intervual); 
		else OnAir(client,button , intervual); 
		LastTime[client]=time; 
		LastButton[client]=button;	
	}
	else
	{
		RemoveJetPack(client,true);
	}

}
OnAir(client, button, Float:Interval)
{
	new flag=GetEntityFlags(client);  //FL_ONGROUND
	if(flag & FL_ONGROUND)  
	{		
		EndJump(client);
		return  ;
	}
	if((button & IN_ZOOM ))
	{
		StartFly(client);
	}
}
OnFly(client, button, Float:intervual)
{
	
	new bool:ok=false;
	if(JetPackB1Ent[client]>0 && IsValidEdict(JetPackB1Ent[client]) && IsValidEntity(JetPackB1Ent[client]) )   ok=true;
	else ok=false;
	if(ok && JetPackB2Ent[client]>0 && IsValidEdict(JetPackB2Ent[client]) && IsValidEntity(JetPackB2Ent[client]) ) 	ok=true;
	else ok=false;
	if(ok==false || Broken[client])
	{
		RemoveJetPack(client);
		PrintHintText(client, "Your jet pack was broke");
		return  ;
	}
	Broken[client]=true;
	new flag=GetEntityFlags(client);  //FL_ONGROUND
	
	if(flag & FL_ONGROUND)  
	{		
		EndJump(client);
		return  ;
	}
	if((button & IN_USE))  
	{	
		Broken[client]=false;
		SetEntityGravity(client, 1.0);
		return  ;
	}  
	if(Started[client]==0)
	{ 
		Started[client]=1;  
		Gravity[client]=0.01;
		AcceptEntityInput(JetPackB1Flame[client][1], "TurnOn");	 
		AcceptEntityInput(JetPackB2Flame[client][1], "TurnOn");	 
		new Float:vecPos[3];
		GetClientAbsOrigin(client, vecPos);
		EmitSoundToAll(SOUND_FLAME, JetPackB1Ent[client], SNDCHAN_WEAPON, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.5, SNDPITCH_NORMAL, -1, vecPos, NULL_VECTOR, true, 0.0);
		SetEntityMoveType(client, MOVETYPE_FLYGRAVITY); 
	}
	if(Started[client]==1)
	{
		
		decl Float:clientAngle[3]; 
		decl Float:clientPos[3];  
		decl Float:temp[3]; 
		decl Float:volicity[3]; 
		decl Float:pushForce[3]; 
		decl Float:pushForceVertical[3]; 
		new Float:liftForce=50.0; 
		new Float:speedLimit=GetConVarFloat(l4d_fly_speed);
		new Float:fuelUsed=intervual;
		new Float:gravity=0.001;
		new Float:gravityNormal=0.01;
		GetEntDataVector(client, g_iVelocity, volicity);
		GetClientEyeAngles(client, clientAngle);
		GetClientAbsOrigin(client, clientPos);
		CopyVector(clientPos,LostPos[client]);
		clientAngle[0]=0.0;
		
		SetVector(pushForce, 0.0, 0.0, 0.0);
		SetVector(pushForceVertical, 0.0, 0.0,  0.0);
		new bool:up=false;
		new bool:down=false;
		new bool:speed=false;
		new bool:speedStart=false;
		new bool:move=false;
		new controlmode=GetConVarInt(l4d_fly_controlmode);
		new flame=0;
		if((button & IN_JUMP) ) 
		{ 
			SetVector(pushForceVertical, 0.0, 0.0, 1.5);
			up=true;
			if(!(LastButton[client] & IN_JUMP))
			{
				flame=1; 
			}
			if(gravity>0.0)gravity=-0.01;
			gravity=Gravity[client]-1.0*intervual; 
		}
		else
		{
			if((LastButton[client] & IN_JUMP))
			{
				flame=2;				
			}
		}
		if((button & IN_DUCK) && !up) 
		{ 
			SetVector(pushForceVertical, 0.0, 0.0, -2.0);
			down=true; 
			if(gravity<0.0)gravity=0.01;
			gravity=Gravity[client]+1.0*intervual;  
		}

		if(button & IN_FORWARD)
		{ 
			GetAngleVectors(clientAngle, temp, NULL_VECTOR, NULL_VECTOR);
			NormalizeVector(temp,temp); 
			AddVectors(pushForce,temp,pushForce); 
			move=true;
		}
		else if(button & IN_BACK)
		{
			GetAngleVectors(clientAngle, temp, NULL_VECTOR, NULL_VECTOR);
			NormalizeVector(temp,temp); 
			SubtractVectors(pushForce, temp, pushForce); 
			move=true;
		}
		if(button & IN_MOVELEFT)
		{ 
			GetAngleVectors(clientAngle, NULL_VECTOR, temp, NULL_VECTOR);
			NormalizeVector(temp,temp); 
			SubtractVectors(pushForce,temp,pushForce);
			move=true;
		}
		else if(button & IN_MOVERIGHT)
		{
			GetAngleVectors(clientAngle, NULL_VECTOR, temp, NULL_VECTOR);
			NormalizeVector(temp,temp); 
			AddVectors(pushForce,temp,pushForce);
			move=true;
		}
		if((button & IN_SPEED))
		{
			if(!(LastButton[client] & IN_SPEED))
			{
				flame=1; 
				speedStart=true;
			}
			speed=true;
		}
		else
		{
			if((LastButton[client] & IN_SPEED))
			{
				flame=2;				
			}
		}
		if(move && up)
		{
			ScaleVector(pushForceVertical, 0.3);
			ScaleVector(pushForce, 1.5);
		}
		//NormalizeVector(pushForce, pushForce); 
		if(speed || up || down)
		{ 
			fuelUsed*=3.0;
			speedLimit*=1.5;
			liftForce*=2.0;
		}
		 
		AddVectors(pushForceVertical,pushForce,pushForce);
		NormalizeVector(pushForce, pushForce);
		//ShowDir(client, clientPos, pushForce, 0.06);
		//PrintToChatAll("v %f", GetVectorLength(volicity));
		ScaleVector(pushForce,liftForce*intervual);
		if(!(up || down))
		{			 
			if(FloatAbs(volicity[2])>40.0)gravity=volicity[2]*intervual;
			else gravity=gravityNormal;
			
			if(controlmode==0)
			{
				if(volicity[2] >30.0)volicity[2]-=200.0*intervual; 
				else if(volicity[2] <-10.0)volicity[2]+=200.0*intervual; 
			}
			
		}
		new Float:v=GetVectorLength(volicity);
		if(controlmode==0)
		{
			
			if(v>speedLimit)
			{
				NormalizeVector(volicity,volicity);
				ScaleVector(volicity, speedLimit);
			}
			AddVectors(volicity,pushForce,volicity);
			SetEntityGravity(client, 0.01);
			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, volicity);
		}
		else 
		{
			if(gravity>0.5)gravity=0.5;
			if(gravity<-0.5)gravity=-0.5; 
			
			
			if( speedStart && v<speedLimit )
			{ 
				ScaleVector(volicity, 1.5);			  
				TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, volicity);
			}
			else if(v>speedLimit)
			{
				NormalizeVector(volicity,volicity);
				ScaleVector(volicity, speedLimit);
				TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, volicity);
				gravity=gravityNormal ;
			}
		
			//PrintToChatAll("g %f ", gravity);
			SetEntityGravity(client, gravity);
			Gravity[client]=gravity;
		}
		Fuel[client]-=fuelUsed;		
		if(Fuel[client]<=0.0)
		{
			StopFly(client);
			PrintHintText(client, "You jet pack is short of fuel , please look for oxygentank, propanetank or gascan");
		}
		else 
		{
			PrintCenterText(client, "fuel left\n    %d  ", RoundFloat(Fuel[client]));
		}
		if(flame==1)
		{
			AcceptEntityInput(JetPackB1Flame[client][1], "TurnOn");	
			AcceptEntityInput(JetPackB1Flame[client][2], "TurnOn");	
			AcceptEntityInput(JetPackB2Flame[client][1], "TurnOn");	
			AcceptEntityInput(JetPackB2Flame[client][2], "TurnOn");	
			new Float:vecPos[3];
			GetClientAbsOrigin(client, vecPos);
			StopSound(JetPackB1Ent[client], SNDCHAN_WEAPON, SOUND_FLAME);
			EmitSoundToAll(SOUND_FLAME, JetPackB1Ent[client], SNDCHAN_WEAPON, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, SNDPITCH_NORMAL, -1, vecPos, NULL_VECTOR, true, 0.0);
				
		}
		else if(flame==2)
		{
			AcceptEntityInput(JetPackB1Flame[client][2], "TurnOff");
			AcceptEntityInput(JetPackB2Flame[client][2], "TurnOff");
			new Float:vecPos[3];
			GetClientAbsOrigin(client, vecPos);
			StopSound(JetPackB1Ent[client], SNDCHAN_WEAPON, SOUND_FLAME);
			EmitSoundToAll(SOUND_FLAME, JetPackB1Ent[client], SNDCHAN_WEAPON, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.5, SNDPITCH_NORMAL, -1, vecPos, NULL_VECTOR, true, 0.0);
		}  
	}
	Broken[client]=false;
	return;
}
 
 
bool:IsVilidPlayer(client)
{
	if(client>0 && IsClientInGame(client) && IsPlayerAlive(client))return true;
	else return false;
}

CopyVector(Float:source[3], Float:target[3])
{
	target[0]=source[0];
	target[1]=source[1];
	target[2]=source[2];
}
SetVector(Float:target[3], Float:x, Float:y, Float:z)
{
	target[0]=x;
	target[1]=y;
	target[2]=z;
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
		L4D2Version=true;
	}	
	else
	{
		L4D2Version=false;
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
		SDKUnhook( i, SDKHook_PreThink,  PreThink);  
		HaveJetPack[i]=false;
		ShowMsg[i]=0;
		JetPackB1Ent[i]=0;
		JetPackB2Ent[i]=0;
		if(IsClientInGame(i) && IsPlayerAlive(i))SetEntityGravity(i, 1.0);
	}
	DropCount=0;
} 
public OnMapStart()
{
	PrecacheSound(SOUND_FLAME, true);
	if(L4D2Version)
	{
		g_sprite = PrecacheModel("materials/sprites/laserbeam.vmt");		 
	}
	else
	{
		g_sprite = PrecacheModel("materials/sprites/laser.vmt");		 
	}
	g_sprite=g_sprite-0;
}
public Action:ShowInfo2(Handle:timer, any:client)
{
	PrintToChat(client, "\x03Press \x04duck, jump, zoom \x03to control you jetpack, \x04!jetpack \x03to drop jetpack");
} 
public Action:ShowInfo(Handle:timer, any:client)
{
	if(L4D2Version )DisplayHint(INVALID_HANDLE, client);
	else PrintToChat(client, "\x03Press \x04 Jump + Zoom\x03 use \x04jet pack \x03");
}
//code from "DJ_WEST"

public Action:DisplayHint(Handle:h_Timer, any:i_Client)
{ 
	if ( IsClientInGame(i_Client))	ClientCommand(i_Client, "gameinstructor_enable 1");
	CreateTimer(1.0, DelayDisplayHint, i_Client);
}
public Action:DelayDisplayHint(Handle:h_Timer, any:i_Client)
{
 
	DisplayInstructorHint(i_Client, "Jump and press zoom to use jet pack", "+zoom");
	 
}
public DisplayInstructorHint(i_Client, String:s_Message[256], String:s_Bind[])
{
	decl i_Ent, String:s_TargetName[32], Handle:h_RemovePack;
	
	i_Ent = CreateEntityByName("env_instructor_hint");
	FormatEx(s_TargetName, sizeof(s_TargetName), "hint%d", i_Client);
	ReplaceString(s_Message, sizeof(s_Message), "\n", " ");
	DispatchKeyValue(i_Client, "targetname", s_TargetName);
	DispatchKeyValue(i_Ent, "hint_target", s_TargetName);
	DispatchKeyValue(i_Ent, "hint_timeout", "5");
	DispatchKeyValue(i_Ent, "hint_range", "0.01");
	DispatchKeyValue(i_Ent, "hint_color", "255 255 255");
	DispatchKeyValue(i_Ent, "hint_icon_onscreen", "use_binding");
	DispatchKeyValue(i_Ent, "hint_caption", s_Message);
	DispatchKeyValue(i_Ent, "hint_binding", s_Bind);
	DispatchSpawn(i_Ent);
	AcceptEntityInput(i_Ent, "ShowHint");
	
	h_RemovePack = CreateDataPack();
	WritePackCell(h_RemovePack, i_Client);
	WritePackCell(h_RemovePack, i_Ent);
	CreateTimer(5.0, RemoveInstructorHint, h_RemovePack);
}
	
public Action:RemoveInstructorHint(Handle:h_Timer, Handle:h_Pack)
{
	decl i_Ent, i_Client;
	
	ResetPack(h_Pack, false);
	i_Client = ReadPackCell(h_Pack);
	i_Ent = ReadPackCell(h_Pack);
	CloseHandle(h_Pack);
	
	if (!i_Client || !IsClientInGame(i_Client))
		return Plugin_Handled;
	
	if (IsValidEntity(i_Ent))
			RemoveEdict(i_Ent);
	
	ClientCommand(i_Client, "gameinstructor_enable 0");
		
	DispatchKeyValue(i_Client, "targetname", "");
		
	return Plugin_Continue;
}
stock SetupProgressBar(client, Float:time)
{
	//KillProgressBar(client);
	//SetEntPropEnt(client, Prop_Send, "m_reviveOwner", -1);
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", time);
	//SetEntPropEnt(client, Prop_Send, "m_reviveOwner", client);
	//SetEntPropEnt(client, Prop_Send, "m_reviveTarget", client);

}

stock KillProgressBar(client)
{
	//SetEntPropEnt(client, Prop_Send, "m_reviveOwner", -1);
	//SetEntityMoveType(client, MOVETYPE_WALK);
	//SetEntPropEnt(client, Prop_Send, "m_reviveTarget", 0);
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", 0.0);
	//SetEntPropEnt(client, Prop_Send, "m_reviveOwner", 0);
}
//code modify from  "[L4D & L4D2] Extinguisher and Flamethrower", SilverShot;
CreateButton(entity )
{ 
	decl String:sTemp[16];
	new button;
	new bool:type=false;
	if(type)button = CreateEntityByName("func_button");
	else button = CreateEntityByName("func_button_timed"); 

	Format(sTemp, sizeof(sTemp), "target%d",  button );
	DispatchKeyValue(entity, "targetname", sTemp);
	DispatchKeyValue(button, "glow", sTemp);
	DispatchKeyValue(button, "rendermode", "3");

	if(L4D2Version )
	{
		SetEntProp(entity, Prop_Send, "m_nGlowRange",  11);
		SetEntProp(entity, Prop_Send, "m_iGlowType", 3);
		SetEntProp(entity, Prop_Send, "m_glowColorOverride", 1);
		ChangeEdictState(entity, g_iOffsetGlow);
		AcceptEntityInput(entity, "StartGlowing");
	}
 
	if(type )
	{
		DispatchKeyValue(button, "spawnflags", "1025");
		DispatchKeyValue(button, "wait", "1");
	}
	else
	{
		DispatchKeyValue(button, "spawnflags", "0");
		DispatchKeyValue(button, "auto_disable", "1");
		Format(sTemp, sizeof(sTemp), "%f", 5.0);
		DispatchKeyValue(button, "use_time", sTemp);
	}
	DispatchSpawn(button);
	AcceptEntityInput(button, "Enable");
	ActivateEntity(button);

	Format(sTemp, sizeof(sTemp), "ft%d", button);
	DispatchKeyValue(entity, "targetname", sTemp);
	SetVariantString(sTemp);
	AcceptEntityInput(button, "SetParent", button, button, 0);
	TeleportEntity(button, Float:{0.0, 0.0, 0.0}, NULL_VECTOR, NULL_VECTOR);

	SetEntProp(button, Prop_Send, "m_nSolidType", 0, 1);
	SetEntProp(button, Prop_Send, "m_usSolidFlags", 4, 2);

	new Float:vMins[3] = {-5.0, -5.0, -5.0}, Float:vMaxs[3] = {5.0, 5.0, 5.0};
	SetEntPropVector(button, Prop_Send, "m_vecMins", vMins);
	SetEntPropVector(button, Prop_Send, "m_vecMaxs", vMaxs);

	if( L4D2Version )
	{
		SetEntProp(button, Prop_Data, "m_CollisionGroup", 1);
		SetEntProp(button, Prop_Send, "m_CollisionGroup", 1);
	}
	 
	//SetEntProp(entity, Prop_Data, "m_iMinHealthDmg", 99999);
	//HookSingleEntityOutput(entity, "OnHealthChanged", OnHealthChanged, true);

	if( type )
	{	
		HookSingleEntityOutput(button, "OnPressed", OnPressed);
	}
	else
	{
		SetVariantString("OnTimeUp !self:Enable::1:-1");
		AcceptEntityInput(button, "AddOutput");
		HookSingleEntityOutput(button, "OnTimeUp", OnPressed);
	}
	return button;
}
public OnPressed(const String:output[], caller, activator, Float:delay)
{
	new find=-1;
	if(HaveJetPack[activator]!=false)return;
	for(new i=0; i<DropCount; i++)
	{ 
		if(caller==JetPackDropButton[i])
		{
			find=i;
			break;
		}
	}
	if(find >=0)
	{
		SetupJetPack(activator);
		Fuel[activator]=JetPackDropFuel[find];
		if(JetPackDropEnt[find]>0 && IsValidEntity(JetPackDropEnt[find]) && IsValidEdict(JetPackDropEnt[find]))
		{
			AcceptEntityInput(JetPackDropEnt[find], "kill"); 
		}
		for(new i=find; i<DropCount; i++)
		{
			JetPackDropFuel[i]=JetPackDropFuel[i+1];
			JetPackDropEnt[i]=JetPackDropEnt[i+1];
			JetPackDropButton[i]=JetPackDropButton[i+1];
		}
		DropCount--;
	}
}