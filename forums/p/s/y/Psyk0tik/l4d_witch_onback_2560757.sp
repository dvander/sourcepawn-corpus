#include <sourcemod>
#include <sdktools>
#include <sdktools_functions> 
#include <sdkhooks>
#pragma semicolon 1
#pragma newdecls required
#define Model_Witch "models/infected/witch.mdl"
#define Model_Witch2 "models/infected/witch_bride.mdl"

int Anim[90];
int AnimCount=2;
int WitchEnt[MAXPLAYERS+1];
bool WitchViewOn[MAXPLAYERS+1];
float OffSets[100][3];
int GameMode;
int L4D2Version;
int best_anim=0;
Handle l4d_witch_onback_bestpose;

public Plugin myinfo = 
{
	name = "[L4D & L4D2] Witch On Back",
	author = "Pan XiaoHai and modified by Psykotik",
	description = "A Witch is attached to a player's back after killing her.",
	version = "1.2",
	url = "<- URL ->"
}

public void OnPluginStart()
{
	GameCheck(); 	
	if(L4D2Version)SetAnimL4d2();
	else SetAnimL4d1();
	l4d_witch_onback_bestpose = CreateConVar("l4d_witch_onback_bestpose", "1", "  0: random pose, 1: best pose");
	AutoExecConfig(true, "l4d_witch_onback");
 	HookEvent("witch_killed", witch_killed );
	HookEvent("player_bot_replace", player_bot_replace);
	HookEvent("round_start", round_end);
	HookEvent("round_end", round_end);
	HookEvent("finale_win", round_end);
	HookEvent("mission_lost", round_end);
	HookEvent("map_transition", round_end);
	RegConsoleCmd("sm_witch", sm_witch);
	ResetAllState();
}

void GameCheck()
{
	char GameName[16];
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
	}

	else
	{
		L4D2Version=false;
	}
}

public void OnMapStart()
{  
	PrecacheModel(Model_Witch);
	if(L4D2Version)PrecacheModel(Model_Witch2);
}

void SetAnimL4d2()
{
	OffSets[1]=view_as<float>({-5.000000,26.000000,-100.000000});
	OffSets[2]=view_as<float>({-3.000000,32.000000,-100.000000});
	OffSets[3]=view_as<float>({-1.000000,28.000000,-100.000000});
	OffSets[5]=view_as<float>({-1.000000,28.000000,-100.000000});
	OffSets[7]=view_as<float>({1.000000,26.000000,-100.000000});
	OffSets[8]=view_as<float>({-3.000000,26.000000,-100.000000});
	OffSets[10]=view_as<float>({-3.000000,24.000000,-100.000000});
	OffSets[16]=view_as<float>({1.000000,28.000000,-100.000000});
	OffSets[18]=view_as<float>({1.000000,32.000000,-100.000000}); 
	OffSets[35]=view_as<float>({-5.000000,4.000000,-100.000000});
	OffSets[37]=view_as<float>({1.000000,28.000000,-100.000000}); 
	OffSets[44]=view_as<float>({-1.000000,28.000000,-100.000000});
	OffSets[45]=view_as<float>({-1.000000,30.000000,-100.000000});
	OffSets[46]=view_as<float>({-1.000000,32.000000,-100.000000});
	OffSets[49]=view_as<float>({-3.000000,32.000000,-100.000000});
	OffSets[51]=view_as<float>({-1.000000,30.000000,-100.000000});
	OffSets[54]=view_as<float>({3.000000,32.000000,-100.000000});
	OffSets[55]=view_as<float>({-1.000000,30.000000,-100.000000});
	OffSets[59]=view_as<float>({-1.000000,28.000000,-100.000000});
	OffSets[61]=view_as<float>({-5.000000,24.000000,-100.000000});
	OffSets[62]=view_as<float>({-5.000000,22.000000,-100.000000});
	OffSets[66]=view_as<float>({-5.000000,30.000000,-100.000000});
	OffSets[73]=view_as<float>({-5.000000,0.000000,-100.000000});
	OffSets[74]=view_as<float>({1.000000,10.000000,-100.000000});
	OffSets[76]=view_as<float>({-5.000000,32.000000,-100.000000});
	OffSets[77]=view_as<float>({-5.000000,34.000000,-100.000000}); //best
	OffSets[79]=view_as<float>({-9.000000,20.000000,-100.000000});
	OffSets[80]=view_as<float>({-15.000000,18.000000,-100.000000});
	AnimCount=0;
	for(int i=0;i<90; i++)
	{
		if(OffSets[i][2]==-100.0)
		{		
			Anim[AnimCount]=i;
			AnimCount++;
		}
	}

	best_anim = 77;
}

void SetAnimL4d1()
{
	OffSets[1]=view_as<float>({1.000000,32.000000,-100.000000});
	OffSets[3]=view_as<float>({-1.000000,28.000000,-100.000000});
	OffSets[4]=view_as<float>({1.000000,28.000000,-100.000000});
	OffSets[5]=view_as<float>({1.000000,32.000000,-100.000000});
	OffSets[6]=view_as<float>({1.000000,22.000000,-100.000000});
	OffSets[9]=view_as<float>({3.000000,26.000000,-100.000000});
	OffSets[29]=view_as<float>({-1.000000,30.000000,-100.000000});
	OffSets[32]=view_as<float>({-1.000000,30.000000,-100.000000});
	OffSets[36]=view_as<float>({1.000000,32.000000,-100.000000});
	OffSets[37]=view_as<float>({-1.000000,32.000000,-100.000000});
	OffSets[41]=view_as<float>({-1.000000,32.000000,-100.000000});
	OffSets[43]=view_as<float>({-1.000000,32.000000,-100.000000});
	OffSets[46]=view_as<float>({1.000000,32.000000,-100.000000});
	OffSets[47]=view_as<float>({1.000000,26.000000,-100.000000});
	OffSets[51]=view_as<float>({1.000000,24.000000,-100.000000});
	OffSets[53]=view_as<float>({-1.000000,20.000000,-100.000000});
	OffSets[54]=view_as<float>({-5.000000,20.000000,-100.000000});
	OffSets[57]=view_as<float>({-3.000000,20.000000,-100.000000});
	OffSets[65]=view_as<float>({-9.000000,2.000000,-100.000000});
	OffSets[66]=view_as<float>({-1.000000,14.000000,-100.000000});
	OffSets[68]=view_as<float>({-1.000000,36.000000,-100.000000});
	OffSets[69]=view_as<float>({-3.000000,32.000000,-100.000000}); //best 
	OffSets[70]=view_as<float>({-1.000000,32.000000,-100.000000});
	OffSets[72]=view_as<float>({-9.000000,18.000000,-100.000000});
	AnimCount=0;
	for(int i=0;i<90; i++)
	{
		if(OffSets[i][2]==-100.0)
		{		
			Anim[AnimCount]=i;
			AnimCount++;
		}
	}

	best_anim = 69;
}

public Action  sm_witchpose(int client, int args)
{
	for(int i=1; i<=MaxClients; i++)
	{
		if(IsWitch(WitchEnt[i]))
		{
			client=i;
			if(client>0 && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client)==2)
			{
				int anim=Anim[ GetRandomInt(0,AnimCount-1) ];
				float ang[3];
				SetVector(ang, 0.0, 0.0, 90.0);
				float pos[3];
				pos[0]=OffSets[anim][0];
				pos[1]=OffSets[anim][1];
				TeleportEntity(WitchEnt[client], pos, ang, NULL_VECTOR);
				SetEntProp(WitchEnt[client], Prop_Send, "m_nSequence", anim);
				SetEntPropFloat(WitchEnt[client], Prop_Send, "m_flPlaybackRate", 1.0);
			}
		}
	}

	return Plugin_Continue;
}

public Action sm_witch(int client, int args)
{
	if(client>0)
	{
		WitchViewOn[client]=!WitchViewOn[client];
		if(WitchViewOn[client])PrintToChat(client, "\x04Witch \x03view is \x04on");
		else PrintToChat(client, "\x04Witch \x03view is \x04off, \x03but others can still see it on your back");
	}
}
 
public Action player_death(Handle hEvent, const char[] strName, bool DontBroadcast)
{ 
	int victim = GetClientOfUserId(GetEventInt(hEvent, "userid")); 
	if(victim>0 && victim<=MaxClients)
	{
		DeleteDecoration(victim);
	}

	return Plugin_Continue;	 
}

public void player_bot_replace(Handle Spawn_Event, const char[] Spawn_Name, bool Spawn_Broadcast)
{
 	int client = GetClientOfUserId(GetEventInt(Spawn_Event, "player"));
	int bot = GetClientOfUserId(GetEventInt(Spawn_Event, "bot"));   
	if(client>0)
	{
		DeleteDecoration(client);
	}

	if(bot>0)
	{
		DeleteDecoration(bot)		;
	}
}

public Action witch_killed(Handle hEvent, const char[] strName, bool DontBroadcast)
{ 
	int attacker = GetClientOfUserId(GetEventInt(hEvent, "userid")); 
	if(attacker>0 && attacker<=MaxClients)
	{
		if(IsClientInGame(attacker) && IsPlayerAlive(attacker) && GetClientTeam(attacker)==2)
		{ 
			CreateDecoration(attacker);
		}
	}

	return Plugin_Continue;	 
}

public Action round_end(Handle event, const char[] name, bool dontBroadcast)
{
	ResetAllState();
}

void ResetAllState()
{
	for(int i=1; i<=MaxClients; i++)
	{
		WitchEnt[i]=0;
	}
}

bool IsWitch(int ent)
{
	if(ent>0 && IsValidEdict(ent) && IsValidEntity(ent))
	{
		return true;
	}

	else return false;
}
 
void DeleteDecoration(int client)
{
	if(IsWitch(WitchEnt[client]))
	{
		AcceptEntityInput(WitchEnt[client], "ClearParent");
		AcceptEntityInput(WitchEnt[client], "kill");
		SDKUnhook(WitchEnt[client], SDKHook_SetTransmit, Hook_SetTransmit);
	}

	WitchEnt[client]=0;
}

void CreateDecoration(int client)
{
	if(IsWitch(WitchEnt[client]) )return;
	int witch=CreateEntityByName("prop_dynamic_override"); 
	if(L4D2Version)
	{
		if(GetRandomInt(0,1)==0)DispatchKeyValue(witch, "model", Model_Witch2); 
		else DispatchKeyValue(witch, "model", Model_Witch);  
	}

	else DispatchKeyValue(witch, "model", Model_Witch);  
	DispatchSpawn(witch); 
	char tname[60];
	Format(tname, sizeof(tname), "target%d", client);
	DispatchKeyValue(client, "targetname", tname); 		
	DispatchKeyValue(witch, "parentname", tname);
	SetVariantString(tname);
	AcceptEntityInput(witch, "SetParent",witch, witch, 0); 	
	SetVariantString("medkit"); 
	AcceptEntityInput(witch, "SetParentAttachment"); 
	int anim=0;
	if(GetConVarInt(l4d_witch_onback_bestpose)==0)anim=Anim[GetRandomInt(0,AnimCount-1)];
	else anim=best_anim;
	float pos[3];
	float ang[3];
	SetVector(pos, -5.0, 32.0, 0.0); 
	pos[0]=OffSets[anim][0];
	pos[1]=OffSets[anim][1]; 
	SetVector(ang, 0.0, 00.0, 90.0);
	TeleportEntity(witch, pos, ang, NULL_VECTOR);
	SetEntityRenderMode(witch, RENDER_TRANSCOLOR);
	SetEntityRenderColor(witch, 255,0,0,255);
	SetEntProp(witch, Prop_Send, "m_CollisionGroup", 2);   
	SetEntProp(witch, Prop_Send, "m_nSequence", anim);
	SetEntPropFloat(witch, Prop_Send, "m_flPlaybackRate", 1.0);		
	WitchEnt[client]= witch ; 
	if(GetConVarInt(l4d_witch_onback_bestpose)==0)CreateTimer(30.0, TimerAnimWitch, client, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
	SDKHook(WitchEnt[client], SDKHook_SetTransmit, Hook_SetTransmit);
	WitchViewOn[client]=false;
	PrintToChatAll("\x04%N \x03killed a Witch and put it on their back", client);
	PrintToChat(client, "\x03Type \x04!witch \x03to see or hide your own Witch");
}

public Action TimerAnimWitch(Handle timer, any client)
{
	if( IsWitch(WitchEnt[client]) )
	{
		if(client>0 && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client)==2)
		{
			int anim=Anim[ GetRandomInt(0,AnimCount-1) ]; 
			float ang[3]; 
			SetVector(ang, 0.0, 0.0, 90.0);
			float pos[3];
			pos[0]=OffSets[anim][0];
			pos[1]=OffSets[anim][1];
			TeleportEntity(WitchEnt[client], pos, ang, NULL_VECTOR);		
			SetEntProp(WitchEnt[client], Prop_Send, "m_nSequence", anim);
			SetEntPropFloat(WitchEnt[client], Prop_Send, "m_flPlaybackRate", 1.0);		 
			return Plugin_Continue;
		}

		else
		{
			DeleteDecoration(client);
		}
	}

	WitchEnt[client]=0;
	return Plugin_Stop;
}

public Action Hook_SetTransmit(int entity, int client)
{ 
	if(entity==WitchEnt[client])
	{
		if(WitchViewOn[client])return Plugin_Continue;
		else return Plugin_Handled;
	}

	return Plugin_Continue;
}

void SetVector(float target[3], float x, float y, float z)
{
	target[0]=x;
	target[1]=y;
	target[2]=z;
}