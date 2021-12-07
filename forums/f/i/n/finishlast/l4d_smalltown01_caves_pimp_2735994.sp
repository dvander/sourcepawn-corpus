#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#pragma newdecls required

Handle g_timer = INVALID_HANDLE;

int ent_dynamic_block1;
int ent_dynamic_block2;
int ent_dynamic_base;
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
	if (StrEqual(sMap, "l4d_smalltown01_caves", false) || StrEqual(sMap, "l4d_vs_smalltown01_caves", false))
	{

 	float pos[3], ang[3], fwd[3]; 

	pos[0] = -12825.0;
	pos[1] = -5525.0;
	pos[2] = -220.0;

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

	pos[0] = -12715.0;
	pos[1] = -5600.0;
	pos[2] = -282.0;
	ang[0] = 0.0;
	ang[1] = 0.0;
	ang[2] = 0.0;

	PrecacheModel("models/props_interiors/door_sliding_breakable01.mdl",true);
	PrecacheModel("models/props_doors/roll-up_door_open.mdl",true);

	//pos[2] -= 25.0;
	ent_dynamic_base = CreateEntityByName("prop_dynamic"); 
 
	DispatchKeyValue(ent_dynamic_base, "model", "models/props_doors/roll-up_door_open.mdl");
	DispatchKeyValue(ent_dynamic_base, "spawnflags", "264");
	DispatchKeyValue(ent_dynamic_base, "disableshadows", "1");

	DispatchSpawn(ent_dynamic_base);
	TeleportEntity(ent_dynamic_base, pos, ang, NULL_VECTOR);

	pos[1] += 40;
	pos[2] += 25.0;

	ent_dynamic_block1 = CreateEntityByName("prop_physics_override"); 
 
	DispatchKeyValue(ent_dynamic_block1, "model", "models/props_interiors/door_sliding_breakable01.mdl");
	DispatchKeyValue(ent_dynamic_block1, "spawnflags", "264");
	DispatchKeyValue(ent_dynamic_block1, "disableshadows", "1");
	DispatchSpawn(ent_dynamic_block1);
	TeleportEntity(ent_dynamic_block1, pos, ang, NULL_VECTOR);
	SDKHook(ent_dynamic_block1, SDKHook_Touch, OnTouch);
	pos[1] -= 79;
	
	ent_dynamic_block2 = CreateEntityByName("prop_physics_override"); 
 
	DispatchKeyValue(ent_dynamic_block2, "model", "models/props_interiors/door_sliding_breakable01.mdl");
	DispatchKeyValue(ent_dynamic_block2, "spawnflags", "264");
	DispatchKeyValue(ent_dynamic_block2, "disableshadows", "1");
	DispatchSpawn(ent_dynamic_block2);
	TeleportEntity(ent_dynamic_block2, pos, ang, NULL_VECTOR);
	SDKHook(ent_dynamic_block2, SDKHook_Touch, OnTouch);
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
	float pos2[3], ang2[3], dir2[3];
	GetEntPropVector(ent_dynamic_block2, Prop_Data, "m_vecAbsOrigin", pos2);
	GetEntPropVector(ent_dynamic_block2, Prop_Send, "m_angRotation", ang2);
	pos2[2] += 0.3;
	dir2[0] = 0.0;
	dir2[1] = 0.0;
	dir2[2] = 0.0;

	if (numlift >= 340) 
	{
		numlift = 0;
		SetConVarInt(FindConVar("sb_unstick"), 1);
		return Plugin_Stop;
	}
 
    	TeleportEntity(ent_dynamic_block1, pos, ang, dir);
    	TeleportEntity(ent_dynamic_block2, pos2, ang2, dir2);

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

