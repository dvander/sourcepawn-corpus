#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdktools_functions> 
#include <sdkhooks>

#define Model_Witch "models/infected/witch.mdl"
#define MODEL_W_MOLOTOV "models/w_models/weapons/w_eq_molotov.mdl"
#define DEBUG 0

int Anim[90];
int AnimCount=2;
int WitchEnt[MAXPLAYERS+1];
float PressTime[MAXPLAYERS+1];
float LastTime[MAXPLAYERS+1];
int WeaponFireEnt[MAXPLAYERS+1];
bool WitchViewOff[MAXPLAYERS+1];
bool bThirdPersonFix[MAXPLAYERS+1];
bool bThirdPerson[MAXPLAYERS+1];
float OffSets[100][3];

/*
	Fork by Dragokas.
	
	ChangeLog:
	
	1.4 (Dragokas)
	 - Witch with 128,0,0,255 color will not be a guard (for special purposes)
	
	1.3 (Dragokas)
	 - Moved to a new syntax and methodmaps
	 - Removed witch as soon as player die (it's previously cause annoing bug when witch is appear in front of another player who are observed).
	 - Added ability to see witch on spine when you toggle third person view (thanks to Lux)
	 - Added translation into Russian
	
*/

int GameMode;
int L4D2Version;

public Plugin myinfo = 
{
	name = "Witch Guard",
	author = "Pan XiaoHai (fork by Dragokas)",
	description = "<- Description ->",
	version = "1.4",
	url = "<- URL ->"
}
ConVar l4d_witch_onback_bestpose;
ConVar l4d_witch_guard_damage;
ConVar l4d_witch_guard_range;
ConVar l4d_witch_guard_gun_count; 
ConVar l4d_witch_guard_shotonback; 

int WitchGaurdDummy[MAXPLAYERS+1]; 
int WitchGaurdButton[MAXPLAYERS+1]; 
int WitchGaurdEnt[MAXPLAYERS+1]; 
float WitchGaurdScanTime[MAXPLAYERS+1]; 
int WitchGaurdWeaponEnt[MAXPLAYERS+1][21]; 
int WitchGaurdCount=0;

public void OnPluginStart()
{
	LoadTranslations("witch_guard.phrases");

	GameCheck(); 	
	if(L4D2Version)SetAnimL4d2();
	else SetAnimL4d1();
	if(GameMode!=1)return;
	l4d_witch_onback_bestpose = CreateConVar("l4d_witch_onback_bestpose", "0", "0: random pose, 1: best pose");
	l4d_witch_guard_damage = CreateConVar("l4d_witch_guard_damage", "0.5", "attack dmage, 1.0: normal [0.1, 1.0]");
	l4d_witch_guard_range = CreateConVar("l4d_witch_guard_range", "600.0", "attack range");
	l4d_witch_guard_gun_count = CreateConVar("l4d_witch_guard_gun_count", "3", "gun count [0, 6]"); 
	l4d_witch_guard_shotonback = CreateConVar("l4d_witch_guard_shotonback", "0", "0: do not shot on back, 1: shot"); 
	
	#if DEBUG
		RegConsoleCmd("sm_w", CmdTest); //,		ADMFLAG_ROOT);
	#endif
	
	AutoExecConfig(true, "witch_guard_l4d");  
 
 	HookEvent("witch_killed", witch_killed, EventHookMode_Pre );  
	HookEvent("player_bot_replace", player_bot_replace );	 
	HookEvent("round_start", round_end);
	HookEvent("round_end", round_end);
	HookEvent("finale_win", round_end);
	HookEvent("mission_lost", round_end);
	HookEvent("map_transition", round_end);	 
	HookEvent("player_death", player_death);
	HookEvent("player_team", eTeamChange);
	HookEvent("survivor_rescued", eSurvivorRescued);
 	
	RegConsoleCmd("sm_witch", sm_witch); 
	RegConsoleCmd("sm_witchpose", sm_witchpose);  
	ResetAllState();
}

public Action CmdTest(int client, int args)
{
	PrintToChat(client, "Enumerating witches");
	
	char sName[256];
	int ent = -1;
	while (-1 != (ent = FindEntityByClassname(ent, "prop_dynamic"))) {
	
		GetEntPropString(ent, Prop_Data, "m_ModelName", sName, sizeof(sName));
		if (StrEqual(sName, Model_Witch, false)) {
			PrintToChat(client, "find the witch guard: %i, owner: %i", ent, GetWitchOwner(ent));
		}
	}
	
	return Plugin_Handled;
}

stock int GetWitchOwner(int entity)
{
	for (int i = 1; i <= MaxClients; i++)
		if (WitchGaurdEnt[i] == entity)
			return i;
	
	for (int i = 1; i <= MaxClients; i++)
		if (WitchEnt[i] == entity)
			return i;
	
	return 0;
}

void GameCheck()
{
	char GameName[16];
	FindConVar("mp_gamemode").GetString(GameName, sizeof(GameName));
	
	
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
	PrecacheModel(MODEL_W_MOLOTOV);
	CreateTimer(1.0, tThirdPersonCheck, INVALID_HANDLE, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public Action tThirdPersonCheck(Handle hTimer)
{
	static int i;
	for(i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i) && !IsFakeClient(i))
		{
			QueryClientConVar(i, "c_thirdpersonshoulder", QueryClientConVarCallback);
		}
	}
}

public void QueryClientConVarCallback(QueryCookie sCookie, int iClient, ConVarQueryResult sResult, const char[] sCvarName, const char[] sCvarValue)
{
	if(GameMode == 2) // versus
	{
		bThirdPerson[iClient] = true;
		return;
	}
	
	//THIRDPERSON
	if(!StrEqual(sCvarValue, "0"))
	{
		if(bThirdPersonFix[iClient])
		{
			bThirdPerson[iClient] = false;
		}
		else
			bThirdPerson[iClient] = true;
	}
	//FIRSTPERSON
	else
	{
		bThirdPerson[iClient] = false;
		bThirdPersonFix[iClient] = false;
	}
}

int best_amin=0;
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
	best_amin=77;
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
	OffSets[72]=view_as<float>({-9.0,18.0,-100.0});
	AnimCount=0;
	for(int i=0;i<90; i++)
	{
		if(OffSets[i][2]==-100.0)
		{		
			Anim[AnimCount]=i;
			AnimCount++;
		}
	}	
	best_amin=69;
}
 
public Action  sm_witchpose(int client, int args)
{
	for(int i=1; i<=MaxClients; i++)
	{
			
		if( IsWitch(WitchEnt[i]) )
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
				
				//PrintToChatAll("pose m_nSequence %d ", anim);

				
			}
		}
	} 
	return Plugin_Continue;
	
}
 
// new g_testanim=0;
public Action sm_witch(int client, int args)
{
	if(client>0)
	{
		WitchViewOff[client]=!WitchViewOff[client];
		if(!WitchViewOff[client]) CPrintToChat(client, "%t", "View_On"); // \x04witch \x03view is \x04on");
		else CPrintToChat(client, "%t", "View_Off"); // \x04witch \x03view is \x04off, \x03but others still can see it on your back");
		
		/*
		g_testanim++;
		SetEntProp(WitchGaurdEnt[0], Prop_Send, "m_nSequence", g_testanim);
		PrintToChatAll("anim %d", g_testanim);
		SetEntPropFloat(WitchGaurdEnt[0], Prop_Send, "m_flPlaybackRate", 1.0);		 
		*/
		

	}
}
 
public Action player_death(Event hEvent, const char[] strName, bool DontBroadcast)
{ 
	int victim = GetClientOfUserId(hEvent.GetInt("userid")); 
	if(victim>0 && victim<=MaxClients && IsClientInGame(victim) && GetClientTeam(victim) == 2)
	{
		DeleteDecoration(victim);
		SDKUnhook(victim, SDKHook_PreThink,  PreThinkClient);  
		
		if (!IsFakeClient(victim))
			bThirdPersonFix[victim] = true;
	}
	return Plugin_Continue;	 
}
public void player_bot_replace(Event Spawn_Event, const char[] Spawn_Name, bool Spawn_Broadcast)
{
 	int client = GetClientOfUserId(Spawn_Event.GetInt("player"));
	int bot = GetClientOfUserId(Spawn_Event.GetInt("bot"));   
	if(client>0)
	{
		if(WitchEnt[client]>0)DeleteDecoration(client);
		SDKUnhook(client, SDKHook_PreThink,  PreThinkClient);  
	}
	if(bot>0)
	{
		if(WitchEnt[bot]>0)DeleteDecoration(bot);
		SDKUnhook(client, SDKHook_PreThink,  PreThinkClient);  
	}
}
public Action witch_killed(Event hEvent, const char[] strName, bool DontBroadcast)
{
	static int r,g,b,a;

	int witch = hEvent.GetInt("witchid");
	if (witch != 0 && IsValidEntity(witch)) {
		GetEntityRenderColor(witch, r,g,b,a);
		if (!(r == 128 && g == 0 && b == 0)) {

			int attacker = GetClientOfUserId(hEvent.GetInt("userid")); 
			if(attacker>0 && attacker<=MaxClients)
			{
				if(IsClientInGame(attacker) && IsPlayerAlive(attacker) && GetClientTeam(attacker)==2)
				{ 
					CreateDecoration(attacker);
					char sName[32];
					GetClientName(attacker, sName, sizeof(sName));
					switch (GetRandomInt(0, 4)) {
						case 0: CPrintToChatAll("%t", "Witch_on_back0", sName); // \x04%N \x03put witch on his back", attacker);
						case 1: CPrintToChatAll("%t", "Witch_on_back1", sName); // 
						case 2: CPrintToChatAll("%t", "Witch_on_back2", sName); // 
						case 3: CPrintToChatAll("%t", "Witch_on_back3", sName); // 
						case 4: CPrintToChatAll("%t", "Witch_on_back4", sName); // 
					}
					
					CPrintToChat(attacker, "%t", "Keys1"); // "\x03press\x04!use button \x03to put witch down");
					//CPrintToChat(attacker, "%t", "Keys2"); // "\x04!witch \x03 - toggle to see or hide your own witch");
				}
			}
		}
	}
	return Plugin_Continue;	 
}
public Action round_end(Event event, const char[] name, bool dontBroadcast)
{
	ResetAllState();
}
void ResetAllState()
{
	WitchGaurdCount=0;
	for(int i=0; i<=MaxClients; i++)
	{
		WitchEnt[i]=0;
		WeaponFireEnt[i]=0;
		//WitchViewOn[i]=false;
		WitchGaurdButton[i]=0; 
		WitchGaurdDummy[i]=0;
		for(int j=0 ; j<21; j++)
		{
		 	WitchGaurdWeaponEnt[i][j]=0;
		}
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
	int witchent=	WitchEnt[client] ;
	int fireent=WeaponFireEnt[client];

	WitchEnt[client]=0;
	WeaponFireEnt[client]=0;
	
	if(IsWitch(witchent))
	{  
		//PrintToChatAll("Removing: %i", witchent);
		AcceptEntityInput(witchent, "kill"); 
	}
	if(fireent>0 && IsValidEdict(fireent) && IsValidEntity(fireent))
	{
		AcceptEntityInput(fireent, "kill");
	} 
	if(client>0 && IsClientInGame(client))
	{
		SDKUnhook(client, SDKHook_PreThink,  PreThinkClient); 
	}
}
void CreateDecoration(int client)
{
	if(IsWitch(WitchEnt[client]) )return;
	//PrintToChatAll("create decoration");
		
	int witch=CreateEntityByName("prop_dynamic_override"); 
	DispatchKeyValue(witch, "model", Model_Witch);  
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
	if(l4d_witch_onback_bestpose.IntValue==0)anim=Anim[ GetRandomInt(0,AnimCount-1) ];
	else anim=best_amin;
	
	float pos[3];
	float ang[3];
	SetVector(pos, -5.0, 32.0, 0.0); 
	pos[0]=OffSets[anim][0];
	pos[1]=OffSets[anim][1]; 
	SetVector(ang, 0.0, 00.0, 90.0);
 	
	TeleportEntity(witch, pos, ang, NULL_VECTOR);
	//SetEntityRenderMode(witch, RENDER_TRANSCOLOR);
	//SetEntityRenderColor(witch, 255,0,0,255);
	SetEntProp(witch, Prop_Send, "m_CollisionGroup", 2);   


	SetEntProp(witch, Prop_Send, "m_nSequence", anim);
	SetEntPropFloat(witch, Prop_Send, "m_flPlaybackRate", 1.0);		
	
	
	WitchEnt[client]= witch ; 
 	if(l4d_witch_onback_bestpose.IntValue==0)CreateTimer(30.0, TimerAnimWitch, client, TIMER_FLAG_NO_MAPCHANGE| TIMER_REPEAT);
	SDKHook(WitchEnt[client], SDKHook_SetTransmit, Hook_SetTransmit);
	 
	 
	int ent=CreateEntityByName("env_weaponfire"); 
 
	float eye[3];
	GetClientEyePosition(client, eye); 
	DispatchSpawn(ent);
	
	
	
	char tName[128];
	Format(tName, sizeof(tName), "target%d",client );
	DispatchKeyValue(client , "targetname", tName);
	
	DispatchKeyValueFloat(ent, "targetarc", 360.0);
	DispatchKeyValueFloat(ent, "targetrange", l4d_witch_guard_range.FloatValue);
	if(GetClientButtons(client) & IN_DUCK)DispatchKeyValue(ent, "weapontype", "1");
	else DispatchKeyValue(ent, "weapontype", "3");
	DispatchKeyValue(ent, "targetteam", "3");
	DispatchKeyValueFloat(ent, "damagemod", l4d_witch_guard_damage.FloatValue);
	 	  
	DispatchKeyValue(ent, "parentname", tName);
	SetVariantString(tName);
	AcceptEntityInput(ent, "SetParent", ent, ent, 0); 
	SetVariantString("eyes"); //muzzle_flash
	AcceptEntityInput(ent, "SetParentAttachment");

	SetVector(eye, 0.0, 0.0, 15.0);
	TeleportEntity(ent, eye,NULL_VECTOR, NULL_VECTOR); 
	if(l4d_witch_guard_shotonback.IntValue==1)AcceptEntityInput(ent, "Enable" ); 
	else AcceptEntityInput(ent, "Disable" ); 
	WeaponFireEnt[client]=ent;
	
	PressTime[client]=GetEngineTime();
	LastTime[client]=GetEngineTime();
	SDKUnhook(client, SDKHook_PreThink,  PreThinkClient);  	
	SDKHook( client, SDKHook_PreThink,  PreThinkClient);   
	
	#if DEBUG
	PrintToChatAll("Created witch decoration: %i", witch);
	#endif
}
void CreateWitchGuard(int client)
{ 
	int dummy = CreateEntityByName("molotov_projectile");	 
	SetEntityModel(dummy, "models/w_models/weapons/w_eq_pipebomb.mdl"); 
	DispatchSpawn(dummy);
	SetEntityRenderMode(dummy, RENDER_TRANSCOLOR);
	SetEntityRenderColor(dummy, 0, 0, 0, 0);
	SetEntityMoveType(dummy, MOVETYPE_NONE);
	SetEntProp(dummy, Prop_Data, "m_CollisionGroup", 2);  
	
	int anim=1;
	if(L4D2Version)anim=3;
	float pos[3];
	float ang[3];
	float t[3];
	GetClientAbsOrigin(client, pos);
	GetClientEyeAngles(client, ang);
	ang[0]=0.0;
	GetAngleVectors(ang, t, NULL_VECTOR,NULL_VECTOR);
	NormalizeVector(t, t);
	ScaleVector(t, 20.0);
	AddVectors(pos, t, pos);
	
 	
	GetClientEyeAngles(client, t);
	t[0]=0.0;
	t[1]+=90.0;
	TeleportEntity(dummy, pos, ang, NULL_VECTOR);
	
	
	int witch=CreateEntityByName("prop_dynamic_override");  
	DispatchKeyValue(witch, "model", Model_Witch);  
	DispatchSpawn(witch);     
	SetEntProp(witch, Prop_Send, "m_nSequence", anim);
	SetEntPropFloat(witch, Prop_Send, "m_flPlaybackRate", 1.0);	 
	
	DispatchKeyValueFloat(witch, "fademindist", 10000.0);
	DispatchKeyValueFloat(witch, "fademaxdist", 20000.0);
	DispatchKeyValueFloat(witch, "fadescale", 0.0); 
 
	//RENDER_NORMAL
	//SetEntityRenderMode(witch, RENDER_TRANSCOLOR);
	//SetEntityRenderColor(witch, 255, 0, 0, 255);
 
	if(L4D2Version)
	{
		SetEntProp(witch, Prop_Send, "m_iGlowType", 3);
		SetEntProp(witch, Prop_Send, "m_nGlowRange", 0);
		SetEntProp(witch, Prop_Send, "m_nGlowRangeMin", 600);
		int red=0;
		int gree=151;
		int blue=0;
		SetEntProp(witch, Prop_Send, "m_glowColorOverride", red + (gree * 256) + (blue* 65536)); 
	}	
	//TeleportEntity(witch, Float:{0.0, 0.0, 0.0}, NULL_VECTOR, NULL_VECTOR);
	TeleportEntity(witch, pos, ang, NULL_VECTOR);
	char tName[128];
	Format(tName, sizeof(tName), "target%d",dummy );
	DispatchKeyValue(dummy , "targetname", tName);	
	
	DispatchKeyValue(witch, "parentname", tName);
	SetVariantString(tName);
	AcceptEntityInput(witch, "SetParent", witch, witch, 0);  	
	
	
	float pos2[3];
	float front=0.0;
	float up=35.0;
	float side=25.0;
	int count=l4d_witch_guard_gun_count.IntValue;
	if(count<1)count=1;
	if(count>21)count=21;
	for(int i=0; i<count; i++)
	{ 
		int ent=CreateEntityByName("env_weaponfire"); 
		DispatchSpawn(ent);  
		DispatchKeyValueFloat(ent, "targetarc", 360.0);
		DispatchKeyValueFloat(ent, "targetrange", l4d_witch_guard_range.FloatValue);
		if(GetClientButtons(client) & IN_DUCK)DispatchKeyValue(ent, "weapontype", "1");
		else DispatchKeyValue(ent, "weapontype", "3");
		DispatchKeyValue(ent, "targetteam", "3");
		DispatchKeyValueFloat(ent, "damagemod", l4d_witch_guard_damage.FloatValue);
		
		float p[3];
		p[0]=p[1]=p[2]=0.0;
		
		/*
		if(i%3==0)CalcOffset(p, ang, 0.0,55.0, 0.0, pos2);
		else if(i%3==1)CalcOffset(p, ang, front, up, side, pos2);
		else if(i%3==2)CalcOffset(p, ang, front, up, 0.0-side, pos2);
		*/
		if(i%3==0)SetVector(pos2, 0.0,0.0, 55.0);
		else if(i%3==1)SetVector(pos2, front,  side,up);
		else if(i%3==2)SetVector(pos2, front, 0.0- side,up);	
		
		//pos2[0]+=GetRandomFloat(-2.0, 2.0);
		//pos2[1]+=GetRandomFloat(-2.0, 2.0);
		//pos2[2]+=GetRandomFloat(-2.0, 2.0);
		
		DispatchKeyValue(ent, "parentname", tName);
		SetVariantString(tName);
		AcceptEntityInput(ent, "SetParent", ent, ent, 0);  
		
		TeleportEntity(ent, pos2,NULL_VECTOR, NULL_VECTOR); 
		AcceptEntityInput(ent, "Enable" ); 
		
		WitchGaurdWeaponEnt[WitchGaurdCount][i]=ent;
	}
	CalcOffset(pos, ang, 0.0,50.0, 0.0, pos2);
	int b=CreateButton(pos2);
	WitchGaurdButton[WitchGaurdCount]=b;
	WitchGaurdEnt[WitchGaurdCount]=witch;
	WitchGaurdDummy[WitchGaurdCount]=dummy;
	WitchGaurdScanTime[WitchGaurdCount]=0.0;
	WitchGaurdCount++;  
	 
	#if DEBUG
	PrintToChatAll("Created witch guard: %i", witch);
	#endif
}

/*
public void OnGameFrame()
{
	for(new index=0; index<WitchGaurdCount; index++)
	{
		new dummy=WitchGaurdDummy[index];
		new Float:ang[3];
		GetEntPropVector(dummy, Prop_Send, "m_angRotation", ang);
		ang[1]+=10.0;
		TeleportEntity(dummy, NULL_VECTOR, ang,NULL_VECTOR);
	}
}
*/

int CreateButton(float pos[3])
{ 
	char sTemp[16];
	int button;
	bool type=false;
	if(type)button = CreateEntityByName("func_button");
	else button = CreateEntityByName("func_button_timed"); 
 
	DispatchKeyValue(button, "rendermode", "3");
 
	if(type )
	{
		DispatchKeyValue(button, "spawnflags", "1025");
		DispatchKeyValue(button, "wait", "1");
	}
	else
	{
		DispatchKeyValue(button, "spawnflags", "0");
		DispatchKeyValue(button, "auto_disable", "1");
		Format(sTemp, sizeof(sTemp), "%f", 1.5);
		DispatchKeyValue(button, "use_time", sTemp);
	}
	DispatchSpawn(button);
	AcceptEntityInput(button, "Enable");
	ActivateEntity(button);
 
	TeleportEntity(button, pos, NULL_VECTOR, NULL_VECTOR);

	SetEntProp(button, Prop_Send, "m_nSolidType", 0, 1);
	SetEntProp(button, Prop_Send, "m_usSolidFlags", 4, 2);

	float vMins[3] = {-5.0, -5.0, -5.0}, vMaxs[3] = {10.0, 10.0, 10.0};
	SetEntPropVector(button, Prop_Send, "m_vecMins", vMins);
	SetEntPropVector(button, Prop_Send, "m_vecMaxs", vMaxs);

	if( L4D2Version )
	{
		SetEntProp(button, Prop_Data, "m_CollisionGroup", 1);
		SetEntProp(button, Prop_Send, "m_CollisionGroup", 1);
	}
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
public void OnPressed(const char[] output, int caller, int activator, float delay)
{ 
	
	if(activator>0 && activator<=MaxClients && IsClientInGame(activator) )
	{ 
		if(IsWitch(WitchEnt[activator]) )return;
		AcceptEntityInput(caller, "kill");  
		int find=-1;
		for(int i=0; i<WitchGaurdCount; i++)
		{
			if(WitchGaurdButton[i]==caller)
			{
				find=i;
				break;
			}
		}
		if(find==-1)return;
		for(int i=0 ; i<21; i++)
		{
			if (WitchGaurdWeaponEnt[find][i] > 0 && IsValidEntity(WitchGaurdWeaponEnt[find][i]))
				AcceptEntityInput(WitchGaurdWeaponEnt[find][i], "kill"); 

			WitchGaurdWeaponEnt[find][i]=0;
		}

		if (IsValidEntity(WitchGaurdEnt[find])) AcceptEntityInput(WitchGaurdEnt[find], "kill"); 
		if (IsValidEntity(WitchGaurdDummy[find])) AcceptEntityInput(WitchGaurdDummy[find], "kill"); 

		for(int i=find; i<WitchGaurdCount; i++)
		{
			WitchGaurdEnt[i]=WitchGaurdEnt[i+1];
			WitchGaurdButton[i]=WitchGaurdButton[i+1];
			WitchGaurdDummy[i]=WitchGaurdDummy[i+1]; 
			WitchGaurdScanTime[i]=WitchGaurdScanTime[i+1];
			for(int j=0 ; j<21; j++)
			{
				WitchGaurdWeaponEnt[i][j]=WitchGaurdWeaponEnt[i+1][j];
			}
		}
		WitchGaurdCount--;
		CreateDecoration(activator);	
		PrintHintText(activator, "%t", "Put_back"); // "you put witch on back" ); 
	}
}
 
void CalcOffset(float pos[3], float ang[3], float front, float up, float right, float ret[3])
{
	float t[3];
	GetAngleVectors(ang, t, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(t, t);
	ScaleVector(t, front);
	AddVectors(pos, t, ret);
	
	GetAngleVectors(ang, NULL_VECTOR,t, NULL_VECTOR);
	NormalizeVector(t, t);
	ScaleVector(t, right);
	AddVectors(ret, t, ret);	
	
	GetAngleVectors(ang, NULL_VECTOR,NULL_VECTOR, t);
	NormalizeVector(t, t);
	ScaleVector(t, up);
	AddVectors(ret, t, ret);		
}

public void PreThinkClient(int client)
{
	if(WitchEnt[client]==0)return;
	int button=GetClientButtons(client); 
	
	if(button & IN_USE)
	{
		if(GetEngineTime()-PressTime[client]>1.0)
		{
			if(!(GetEntityFlags(client) & FL_ONGROUND))return;	 
			DeleteDecoration(client);
			CreateWitchGuard(client);
			PrintHintText(client, "%t", "Put_down"); // "you put witch down" ); 
		}
	}
	else
	{
		PressTime[client]=GetEngineTime(); 
	}
	
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
		if (bThirdPerson[client] && !WitchViewOff[client])
			return Plugin_Continue;
		else
			return Plugin_Handled;
	
		/*
		if(WitchViewOn[client])return Plugin_Continue;
		else return Plugin_Handled;
		*/
	}
	return Plugin_Continue;
}
void SetVector(float target[3], float x, float y, float z)
{
	target[0]=x;
	target[1]=y;
	target[2]=z;
}

public void OnClientPutInServer(int iClient)
{
	bThirdPersonFix[iClient] = true;
}

public void eSurvivorRescued(Event hEvent, char[] sName, bool bDontBroadcast)
{
	static int iClient;
	iClient = GetClientOfUserId(hEvent.GetInt("victim"));
	
	if(!IsValidClient(iClient) || IsFakeClient(iClient))
		return;
	
	bThirdPersonFix[iClient] = true;
}

public void eTeamChange(Event hEvent, char[] sName, bool bDontBroadcast)
{
	static int iClient;
	iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	
	if(!IsValidClient(iClient) || IsFakeClient(iClient))
		return;
	
	bThirdPersonFix[iClient] = true;
}

bool IsValidClient(int iClient)
{
	return (iClient > 0 && iClient <= MaxClients && IsClientInGame(iClient));
}

stock void CPrintToChat(int client, const char[] format, any ...)
{
	char buffer[192];
	SetGlobalTransTarget(client);
	VFormat(buffer, sizeof(buffer), format, 3);
	ReplaceColor(buffer, sizeof(buffer));
	PrintToChat(client, "\x01%s", buffer);
}

stock void CPrintToChatAll(const char[] format, any ...)
{
	char buffer[192];
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && !IsFakeClient(i) )
		{
			SetGlobalTransTarget(i);
			VFormat(buffer, sizeof(buffer), format, 2);
			ReplaceColor(buffer, sizeof(buffer));
			PrintToChat(i, "\x01%s", buffer);
		}
	}
}

stock void ReplaceColor(char[] message, int maxLen)
{
    ReplaceString(message, maxLen, "{white}", "\x01", false);
    ReplaceString(message, maxLen, "{cyan}", "\x03", false);
    ReplaceString(message, maxLen, "{orange}", "\x04", false);
    ReplaceString(message, maxLen, "{green}", "\x05", false);
}