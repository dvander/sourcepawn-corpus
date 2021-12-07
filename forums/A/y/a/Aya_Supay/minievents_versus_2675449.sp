
//#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include "spawnpoints.inc"

#define BAR_MDL  "models/props_unique/wooden_barricade.mdl"
#define CAN_MDL  "models/props_unique/wooden_barricade_gascans.mdl"

Handle BURN_TIME;
Handle EVENT_TIME;
Handle CANS_GLOW;
Handle EVENTS_ON;

int event_count;

float barOne[3];
float barTwo[3];
float barThree[3];
float barAngOne[3];
float barAngTwo[3];
float barAngThree[3];

public void OnMapStart()
{
	PrecacheModel(BAR_MDL,true);
	PrecacheModel(CAN_MDL,true);
	
	SC_LoadMapConfig();
	event_count = GetRandomInt(1,3);
	for ( int i;i <= event_count; i++)
	{
		if (i == 1)SC_GetRandomSpawn(barOne,barAngOne);
		if (i == 2)SC_GetRandomSpawn(barTwo,barAngTwo);
		if (i == 3)SC_GetRandomSpawn(barThree,barAngThree);
	}
	//events_spawned = false;
}
public void OnMapEnd() 
{
    SC_SaveMapConfig();
}
public Action Save(int client, int args)
{
	 SC_SaveMapConfig();
	 PrintToChat(client,"positions saved");
}
public void OnPluginStart()
{
	RegAdminCmd("sm_testbar", testbar, ADMFLAG_GENERIC, "spawn test baricade");
		
	BURN_TIME = CreateConVar("mini_event_burn_time", "60.0", "how long until baricade dispears");
	EVENT_TIME = CreateConVar("mini_event_hoard_time", "180.0", "how long until hoard stops");
	CANS_GLOW = CreateConVar("mini_event_can_glow","1","do cans glow, 1 for yes");
	EVENTS_ON = CreateConVar("mini_event_on","1","turn events on, 1 for yes");
	
	HookEvent("player_left_start_area",Event_LeftStartArea);

//	AutoExecConfig(true, "minievents");

	SC_Initialize("minievent",
				  "minievent_menu", ADMFLAG_GENERIC, 
				  "minievent_add", ADMFLAG_GENERIC, 
				  "minievent_del", ADMFLAG_GENERIC, 
				  "minieventshow", ADMFLAG_GENERIC, 
				  "configs/minievent",
				  10);	
				  
	RegConsoleCmd("sm_savebar",Save, "save config");				
	//RegAdminCmd("sc_test_dump", DumpSpawnsInfo, ADMFLAG_GENERIC);
}

public Action Event_LeftStartArea(Handle event, const char[] name, bool dontBroadcast)
{
	if(GetConVarInt(EVENTS_ON)==1)
	{
		PrintToChatAll("\x05[MiniEvents]\x01 Spawning %d Event's",event_count);
		for ( int i;i <= event_count; i++)
		{
			if (i == 1)	CreateBar(barOne,barAngOne);
			if (i == 2)	CreateBar(barTwo,barAngTwo);
			if (i == 3)	CreateBar(barThree,barAngThree);
		}
	}
}

void CreateBar(float pos[3], float ang[3])
{
	ang[1]+=90
	int bar_sp = CreateEntityByName("prop_physics_override"); 
	DispatchKeyValue( bar_sp, "model", BAR_MDL);
	SetEntityModel(bar_sp,BAR_MDL);
	DispatchKeyValue( bar_sp, "Solid", "6");
	DispatchKeyValueVector( bar_sp, "Origin", pos);
	DispatchSpawn(bar_sp);
	SetEntityMoveType(bar_sp, MOVETYPE_NONE);
	TeleportEntity(bar_sp,pos,ang, NULL_VECTOR);

	SDKHook(bar_sp, SDKHook_OnTakeDamagePost, OnTakeDamagePost);	
	
	float canpos[3];
	float direction[3];

	int can = CreateEntityByName("prop_physics"); 
	DispatchKeyValue( can, "Solid", "6");
	SetEntityModel(can,CAN_MDL);
	SetEntityMoveType(can, MOVETYPE_NONE);
	ang[0] = 0.0;
	ang[1] = ang[1]-90;
	ang[2] = 0.0;
	GetAngleVectors(ang, direction, NULL_VECTOR, NULL_VECTOR);
	ScaleVector(direction, 100.0);
	AddVectors(pos, direction, canpos);
	DispatchKeyValueVector( can, "Origin", canpos );
	DispatchSpawn(can);
	AcceptEntityInput(can,"DisableMotion");
	if (GetConVarInt(CANS_GLOW) ==1 )
	{
		if ( EngineL4D2 ) SetGlowRed(can);
	}
	//PrintToChatAll("Barricade Spawned Sucessfully!!");
}
public Action testbar(int client, int args)
{
	float vPos[3];
	float vAng[3];
	float nPos[3];
	
	GetClientEyePosition(client,vPos);
	GetClientEyeAngles(client,vAng);
	
	Handle trace = TR_TraceRayFilterEx(vPos, vAng, MASK_PLAYERSOLID, RayType_Infinite, TraceFilter, client);

	if (TR_DidHit(trace))
	{
		vAng[0]=0.0;
		//vAng[1]+=90; 
		vAng[2]=0.0;

		TR_GetEndPosition(nPos, trace);
		CreateBar(nPos,vAng);
	}			
}
public void OnTakeDamagePost(int victim, int attacker, int inflictor, float damage, int damagetype)
{
	//PrintToChatAll("barrier took damage type = %d",damagetype);
	if (damagetype == 8)
	{
		PrintToChatAll("Event Has Started,Hold Out For %.01f seconds",GetConVarFloat(BURN_TIME));
		ForcePanicEvent(true);
		CreateTimer(GetConVarFloat(BURN_TIME),DeleteEnt,victim,TIMER_FLAG_NO_MAPCHANGE);
		
		SDKUnhook(victim, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
	}
	else
	{
		PrintHintTextToAll("Shoot The Cans To Burn The Barricade!!!");
	}
}
public Action DeleteEnt(Handle hTimer, any TmpEnt)
{	//destroy barricade
	AcceptEntityInput(TmpEnt, "Kill"); 
	PrintToChatAll("Path Is Clear, Zombies Are Still Coming For You");
	return Plugin_Stop;
}
stock void ForcePanicEvent(int Forever)//bool Forever = true)
{
	if(Forever)
	{ 
		SetConVarInt(FindConVar("director_panic_forever"), 1); 
	}
	
	int TmpEnt = CreateEntityByName("info_director");
	
	if(!IsValidEntity(TmpEnt))
	{ 
		return; 
	}
	DispatchSpawn(TmpEnt); 
	if ( EngineL4D2 ) AcceptEntityInput(TmpEnt, "ForcePanicEvent");
	else AcceptEntityInput(TmpEnt, "PanicEvent"); 	
	CreateTimer(GetConVarFloat(EVENT_TIME),endhoard,TmpEnt,TIMER_FLAG_NO_MAPCHANGE);
}

public Action endhoard(Handle hTimer, any TmpEnt)
{	
	SetConVarInt(FindConVar("director_panic_forever"), 0); 
	AcceptEntityInput(TmpEnt, "Kill");
	PrintToChatAll("Hoard Has Ended");
	return Plugin_Stop;
}

public bool TraceFilter(int entity, int contentsMask, any client)
{
	if( entity == client )return false;
	return true;
}

void SetGlowRed(int gun)
{
	SetEntProp(EntRefToEntIndex(gun), Prop_Send, "m_iGlowType", 3);
	SetEntProp(EntRefToEntIndex(gun), Prop_Send, "m_nGlowRange", 0);
	SetEntProp(EntRefToEntIndex(gun), Prop_Send, "m_nGlowRangeMin", 1);
	int red=0;
	int gree=0;
	int blue=0;
	red=200;
	gree=0;
	blue=0;
	
	SetEntProp(EntRefToEntIndex(gun), Prop_Send, "m_glowColorOverride", red + (gree * 256) + (blue* 65536));	
}
stock void UnloadMyself() 
{
	char map[64];
	GetCurrentMap(map, sizeof map);
	if(StrContains(map,"mall",false) != -1)
	{
		char filename[256];
		GetPluginFilename(INVALID_HANDLE, filename, sizeof(filename));
		ServerCommand("sm plugins unload %s", filename);
	}
} 

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if (test == Engine_Left4Dead2) {
		EngineL4D2 = true;		
	}
	else if (test != Engine_Left4Dead) {
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public Plugin myinfo = 
{
	name = "Mini Events",
	author = "spirit",
	description = "spawn mini cresendo events",
	version = "1.0",
	url = ""
}
