#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#pragma newdecls required

Handle g_timer = INVALID_HANDLE;

int ent_dynamic_block1;
int ent_craneframe;
int ent_crane;
int ent_cranewindow;
int ent_cable;
int ent_cable2;
int ent_cable3;
int ent_cable4;
int ent_cable5;
int ent_cable6;
int ent_cable7;
int ent_cable8;
int ent_cable9;
int ent_cable10;
int ent_cable11;
int ent_cable12;
int ent_cable13;
int ent_cable14;
int ent_cable15;

//int ent_dynamic_base;
int dynamic_prop;
int dynamic_prop_button;
#define SOUND			"ambient/machines/wall_move4.wav"


public void OnPluginStart()
{
	HookEvent("round_freeze_end", event_round_freeze_end, EventHookMode_PostNoCopy);
	//HookEvent("round_end", Round_End_Hook);
}


public void OnMapEnd()
{
	/* Clean up timers */
	if (g_timer != INVALID_HANDLE) {
		delete(g_timer);
		g_timer = INVALID_HANDLE;
	}  
}

public void event_round_freeze_end(Event event, const char[] name, bool dontBroadcast)
{

	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));
	if (StrEqual(sMap, "l4d_river01_docks", false) || StrEqual(sMap, "c7m1_docks", false))
	{


 	float pos[3], ang[3], fwd[3]; 

	pos[0] = 12184.0;
	pos[1] = 37.0;
	pos[2] = 1.0;

	ang[0] = 0.0;
	ang[1] = 0.0;
	ang[2] = 0.0;

	GetAngleVectors(ang, fwd, NULL_VECTOR, NULL_VECTOR); 
	ScaleVector(fwd, 100.0); 
	AddVectors(fwd, pos, fwd); 

	char origin[100]; 
	Format(origin, sizeof(origin), "%0.1f %0.1f %0.1f", fwd[0], fwd[1], fwd[2]); 

	// Flip 180 
	float output[3]; 
	MakeVectorFromPoints(fwd, pos, output); 
	GetVectorAngles(output, ang); 
	ang[0] = 0.0; 

	char targetname[100]; 
	int tick = GetGameTickCount(); 
     
	Format(targetname, sizeof(targetname), "@glow_%i", tick); 

	CreateModel(fwd, ang, origin, targetname); 
	CreateButton(fwd, ang, origin, targetname); 

	// create doors and box

	//***************

	pos[0] = 12170.0;
	pos[1] = -80.0;
	pos[2] = -62.0;
	ang[0] = 0.0;
	ang[1] = 90.0;
	ang[2] = 0.0;

	PrecacheModel("models/props_equipment/cargo_container01.mdl",true);
	PrecacheModel("models/cranes/crane_frame.mdl",true);
	PrecacheModel("models/props_industrial/construction_crane.mdl",true);
	PrecacheModel("models/props_exteriors/lighthouserailing_03_break04.mdl",true);
	PrecacheModel("models/props_industrial/construction_crane_windows.mdl",true);


	ent_dynamic_block1 = CreateEntityByName("prop_dynamic"); 
 
	DispatchKeyValue(ent_dynamic_block1, "model", "models/props_equipment/cargo_container01.mdl");
	//DispatchKeyValue(ent_dynamic_block1, "spawnflags", "264");
	DispatchKeyValue(ent_dynamic_block1, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block1, "solid", "6");
	DispatchSpawn(ent_dynamic_block1);
	TeleportEntity(ent_dynamic_block1, pos, ang, NULL_VECTOR);
	SDKHook(ent_dynamic_block1, SDKHook_Touch, OnTouch);



	pos[2] = 95.0;
	ang[0] = 90.0;
	ent_cable = CreateEntityByName("prop_dynamic"); 
 
	DispatchKeyValue(ent_cable, "model", "models/props_exteriors/lighthouserailing_03_break04.mdl");
	DispatchKeyValue(ent_cable, "spawnflags", "264");
	DispatchKeyValue(ent_cable, "disableshadows", "1");
	DispatchSpawn(ent_cable);
	TeleportEntity(ent_cable, pos, ang, NULL_VECTOR);

	pos[2] += 64.0;
	ang[0] = 90.0;
	ent_cable2 = CreateEntityByName("prop_dynamic"); 
 
	DispatchKeyValue(ent_cable2, "model", "models/props_exteriors/lighthouserailing_03_break04.mdl");
	DispatchKeyValue(ent_cable2, "spawnflags", "264");
	DispatchKeyValue(ent_cable2, "disableshadows", "1");
	DispatchSpawn(ent_cable2);
	TeleportEntity(ent_cable2, pos, ang, NULL_VECTOR);

	pos[2] += 64.0;
	ang[0] = 90.0;
	ent_cable3 = CreateEntityByName("prop_dynamic"); 
 
	DispatchKeyValue(ent_cable3, "model", "models/props_exteriors/lighthouserailing_03_break04.mdl");
	DispatchKeyValue(ent_cable3, "spawnflags", "264");
	DispatchKeyValue(ent_cable3, "disableshadows", "1");
	DispatchSpawn(ent_cable3);
	TeleportEntity(ent_cable3, pos, ang, NULL_VECTOR);


	pos[2] += 64.0;
	ang[0] = 90.0;
	ent_cable4 = CreateEntityByName("prop_dynamic"); 
 
	DispatchKeyValue(ent_cable4, "model", "models/props_exteriors/lighthouserailing_03_break04.mdl");
	DispatchKeyValue(ent_cable4, "spawnflags", "264");
	DispatchKeyValue(ent_cable4, "disableshadows", "1");
	DispatchSpawn(ent_cable4);
	TeleportEntity(ent_cable4, pos, ang, NULL_VECTOR);

	pos[2] += 64.0;
	ang[0] = 90.0;
	ent_cable5 = CreateEntityByName("prop_dynamic"); 
 
	DispatchKeyValue(ent_cable5, "model", "models/props_exteriors/lighthouserailing_03_break04.mdl");
	DispatchKeyValue(ent_cable5, "spawnflags", "264");
	DispatchKeyValue(ent_cable5, "disableshadows", "1");
	DispatchSpawn(ent_cable5);
	TeleportEntity(ent_cable5, pos, ang, NULL_VECTOR);

	pos[2] += 64.0;
	ang[0] = 90.0;
	ent_cable6 = CreateEntityByName("prop_dynamic"); 
 
	DispatchKeyValue(ent_cable6, "model", "models/props_exteriors/lighthouserailing_03_break04.mdl");
	DispatchKeyValue(ent_cable6, "spawnflags", "264");
	DispatchKeyValue(ent_cable6, "disableshadows", "1");
	DispatchSpawn(ent_cable6);
	TeleportEntity(ent_cable6, pos, ang, NULL_VECTOR);

	pos[2] += 64.0;
	ang[0] = 90.0;
	ent_cable7 = CreateEntityByName("prop_dynamic"); 
 
	DispatchKeyValue(ent_cable7, "model", "models/props_exteriors/lighthouserailing_03_break04.mdl");
	DispatchKeyValue(ent_cable7, "spawnflags", "264");
	DispatchKeyValue(ent_cable7, "disableshadows", "1");
	DispatchSpawn(ent_cable7);
	TeleportEntity(ent_cable7, pos, ang, NULL_VECTOR);

	pos[2] += 64.0;
	ang[0] = 90.0;
	ent_cable8 = CreateEntityByName("prop_dynamic"); 
 
	DispatchKeyValue(ent_cable8, "model", "models/props_exteriors/lighthouserailing_03_break04.mdl");
	DispatchKeyValue(ent_cable8, "spawnflags", "264");
	DispatchKeyValue(ent_cable8, "disableshadows", "1");
	DispatchSpawn(ent_cable8);
	TeleportEntity(ent_cable8, pos, ang, NULL_VECTOR);

	pos[2] += 64.0;
	ang[0] = 90.0;
	ent_cable9 = CreateEntityByName("prop_dynamic"); 
 
	DispatchKeyValue(ent_cable9, "model", "models/props_exteriors/lighthouserailing_03_break04.mdl");
	DispatchKeyValue(ent_cable9, "spawnflags", "264");
	DispatchKeyValue(ent_cable9, "disableshadows", "1");
	DispatchSpawn(ent_cable9);
	TeleportEntity(ent_cable9, pos, ang, NULL_VECTOR);

	pos[2] += 64.0;
	ang[0] = 90.0;
	ent_cable10 = CreateEntityByName("prop_dynamic"); 
 
	DispatchKeyValue(ent_cable10, "model", "models/props_exteriors/lighthouserailing_03_break04.mdl");
	DispatchKeyValue(ent_cable10, "spawnflags", "264");
	DispatchKeyValue(ent_cable10, "disableshadows", "1");
	DispatchSpawn(ent_cable10);
	TeleportEntity(ent_cable10, pos, ang, NULL_VECTOR);

	pos[2] += 64.0;
	ang[0] = 90.0;
	ent_cable11 = CreateEntityByName("prop_dynamic"); 
 
	DispatchKeyValue(ent_cable11, "model", "models/props_exteriors/lighthouserailing_03_break04.mdl");
	DispatchKeyValue(ent_cable11, "spawnflags", "264");
	DispatchKeyValue(ent_cable11, "disableshadows", "1");
	DispatchSpawn(ent_cable11);
	TeleportEntity(ent_cable11, pos, ang, NULL_VECTOR);

	pos[2] += 64.0;
	ang[0] = 90.0;
	ent_cable12 = CreateEntityByName("prop_dynamic"); 
 
	DispatchKeyValue(ent_cable12, "model", "models/props_exteriors/lighthouserailing_03_break04.mdl");
	DispatchKeyValue(ent_cable12, "spawnflags", "264");
	DispatchKeyValue(ent_cable12, "disableshadows", "1");
	DispatchSpawn(ent_cable12);
	TeleportEntity(ent_cable12, pos, ang, NULL_VECTOR);

	pos[2] += 64.0;
	ang[0] = 90.0;
	ent_cable13 = CreateEntityByName("prop_dynamic"); 
 
	DispatchKeyValue(ent_cable13, "model", "models/props_exteriors/lighthouserailing_03_break04.mdl");
	DispatchKeyValue(ent_cable13, "spawnflags", "264");
	DispatchKeyValue(ent_cable13, "disableshadows", "1");
	DispatchSpawn(ent_cable13);
	TeleportEntity(ent_cable13, pos, ang, NULL_VECTOR);

	pos[2] += 64.0;
	ang[0] = 90.0;
	ent_cable14 = CreateEntityByName("prop_dynamic"); 
 
	DispatchKeyValue(ent_cable14, "model", "models/props_exteriors/lighthouserailing_03_break04.mdl");
	DispatchKeyValue(ent_cable14, "spawnflags", "264");
	DispatchKeyValue(ent_cable14, "disableshadows", "1");
	DispatchSpawn(ent_cable14);
	TeleportEntity(ent_cable14, pos, ang, NULL_VECTOR);

	pos[2] += 64.0;
	ang[0] = 90.0;
	ent_cable15 = CreateEntityByName("prop_dynamic"); 
 
	DispatchKeyValue(ent_cable15, "model", "models/props_exteriors/lighthouserailing_03_break04.mdl");
	DispatchKeyValue(ent_cable15, "spawnflags", "264");
	DispatchKeyValue(ent_cable15, "disableshadows", "1");
	DispatchSpawn(ent_cable15);
	TeleportEntity(ent_cable15, pos, ang, NULL_VECTOR);






        pos[0] = 12577.0;
	pos[1] = -140.0;
	pos[2] = -362.0;
	ang[0] = 0.0;
	ang[1] = 0.0;
	ang[2] = 0.0;

	ent_craneframe = CreateEntityByName("prop_dynamic"); 
 
	DispatchKeyValue(ent_craneframe, "model", "models/cranes/crane_frame.mdl");
	//DispatchKeyValue(ent_craneframe, "spawnflags", "264");
	DispatchKeyValue(ent_craneframe, "disableshadows", "1");
	DispatchKeyValue(ent_craneframe, "solid", "6");
	DispatchSpawn(ent_craneframe);
	TeleportEntity(ent_craneframe, pos, ang, NULL_VECTOR);

	pos[2] = 436.0;
	ang[1] = 172.0;
	ent_crane = CreateEntityByName("prop_dynamic"); 
 
	DispatchKeyValue(ent_crane, "model", "models/props_industrial/construction_crane.mdl");
	//DispatchKeyValue(ent_crane, "spawnflags", "264");
	DispatchKeyValue(ent_crane, "disableshadows", "1");
	DispatchKeyValue(ent_crane, "solid", "6");
	DispatchSpawn(ent_crane);
	TeleportEntity(ent_crane, pos, ang, NULL_VECTOR);

	pos[2] = 436.0;
	ang[1] = 172.0;
	ent_cranewindow = CreateEntityByName("prop_dynamic"); 

	DispatchKeyValue(ent_cranewindow, "model", "models/props_industrial/construction_crane_windows.mdl");
	DispatchKeyValue(ent_cranewindow, "spawnflags", "264");
	DispatchKeyValue(ent_cranewindow, "disableshadows", "1");
	DispatchKeyValue(ent_cranewindow, "solid", "6");
	DispatchSpawn(ent_cranewindow);
	TeleportEntity(ent_cranewindow, pos, ang, NULL_VECTOR);
	
	//**********

	HookSingleEntityOutput(dynamic_prop_button, "OnPressed", OnPressed);
	}
}


// Create dynamic model 
void CreateModel(const float fwd[3], const float ang[3], const char[] origin, const char[] targetname) 
{ 
	PrecacheModel("models/props_lab/freightelevatorbutton.mdl"); 
     
	dynamic_prop = CreateEntityByName("prop_dynamic"); 
     
	if(dynamic_prop == -1) return; 

	DispatchKeyValue(dynamic_prop, "origin", origin); 
	DispatchKeyValue(dynamic_prop, "targetname", targetname); // important for func_button glow entity 

	DispatchKeyValue(dynamic_prop, "model", "models/props_lab/freightelevatorbutton.mdl"); 
	DispatchKeyValue(dynamic_prop, "spawnflags", "0"); 
	/* 
	16 = Break on Touch 
	32 = Break on Pressure 
	64 = Use Hitboxes for Renderbox 
	256 = Start with collision disabled 
	*/ 

	DispatchSpawn(dynamic_prop); 
     
	TeleportEntity(dynamic_prop, fwd, ang, NULL_VECTOR); 
} 



void CreateButton(const float fwd[3], const float ang[3], const char[] origin, const char[] targetname) 
{ 
	PrecacheModel("models/props_lab/freightelevatorbutton.mdl"); 

	dynamic_prop_button = CreateEntityByName("func_button"); 
     
	if(dynamic_prop_button == -1) return; 
     
	DispatchKeyValue(dynamic_prop_button, "origin", origin); // important or button start flying to 0, 0, 0 coordinates after press 
	DispatchKeyValue(dynamic_prop_button, "glow", targetname); 

	DispatchKeyValue(dynamic_prop_button, "wait", "-1");    // Default 3 sec, -1 stay. Glowing stop when button OnIn 
	DispatchKeyValue(dynamic_prop_button, "spawnflags", "1025"); // Don't move + Use Activates 
	/* 
	1 = Don't move 
	32 = Toggle 
	256 = Touch Activates 
	512 = Damage Activates 
	1024 = Use Activates 
	2048 = Starts Locked 
	4096 = Sparks 
	*/ 

	DispatchSpawn(dynamic_prop_button); 
	ActivateEntity(dynamic_prop_button); 
     
	TeleportEntity(dynamic_prop_button, fwd, ang, NULL_VECTOR); 

	SetEntityModel(dynamic_prop_button, "models/props_lab/freightelevatorbutton.mdl"); 

	float vMins[3] = {-30.0, -30.0, 0.0}, vMaxs[3] = {30.0, 30.0, 200.0}; 
	SetEntPropVector(dynamic_prop_button, Prop_Send, "m_vecMins", vMins); 
	SetEntPropVector(dynamic_prop_button, Prop_Send, "m_vecMaxs", vMaxs); 
     

	// This disable entity error 
	// ERROR:  Can't draw studio model models/props_lab/freightelevatorbutton.mdl because CBaseButton is not derived from C_BaseAnimating 

	int enteffects = GetEntProp(dynamic_prop_button, Prop_Send, "m_fEffects"); 
	enteffects |= 32; 
	SetEntProp(dynamic_prop_button, Prop_Send, "m_fEffects", enteffects); 
}  


public void OnPressed(const char[] output, int caller, int activator, float delay)
{
	//AcceptEntityInput(dynamic_prop_button, "Kill");
	EmitSoundToAll(SOUND, ent_dynamic_block1);
	char command[] = "director_force_panic_event";
	char flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(activator, command);
	SetCommandFlags(command, flags);
	// Remove glow entity from func_button
	SetEntProp(dynamic_prop_button, Prop_Send, "m_glowEntity", -1); 
	g_timer = CreateTimer(0.01, gate, _, TIMER_REPEAT);
	
}

public Action gate(Handle timer)
{
	// Create a global variable visible only in the local scope (this function).
	static int numlift = 0;
	static int numsound = 0;
	float pos[3], ang[3], dir[3];
	GetEntPropVector(ent_dynamic_block1, Prop_Data, "m_vecAbsOrigin", pos);
	GetEntPropVector(ent_dynamic_block1, Prop_Send, "m_angRotation", ang);
	pos[2] += 0.3;
	dir[0] = 0.0;
	dir[1] = 0.0;
	dir[2] = 0.0;

	if (numlift >= 340) 
	{
		numlift = 0;
		SetConVarInt(FindConVar("sb_unstick"), 1);
		return Plugin_Stop;
	}
 
    	TeleportEntity(ent_dynamic_block1, pos, ang, dir);


	numlift++;
	numsound++;

	if((numsound==23))
	{
		EmitSoundToAll(SOUND, ent_dynamic_block1);
		numsound = 0;
	}

	return Plugin_Continue;

}





public void OnTouch(int client, int other)
{
if(other>=0){
if(IsFakeClient(other) && GetClientTeam(other) == 2)
{
SetConVarInt(FindConVar("sb_unstick"), 0);
//PrintToChatAll ("touched");
SDKUnhook(ent_dynamic_block1, SDKHook_Touch, OnTouch);
}

}
}
