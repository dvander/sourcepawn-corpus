#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.2"

#define SAFEDOOR_MODEL_01 "models/props_doors/checkpoint_door_01.mdl"
#define SAFEDOOR_MODEL_02 "models/props_doors/checkpoint_door_-01.mdl"
#define SAFEDOOR_CLASS "prop_door_rotating_checkpoint"

new ent_safedoor;
new ent_safedoor_check;

public Plugin:myinfo =
{
	name = "L4D2 Weak Door",
	author = "Glide Loading",
	description = "Saferoom door will be broken out at opening",
	version = PLUGIN_VERSION,
	url = "not supported"
};

public OnPluginStart()
{
	CreateConVar("l4d2_weakdoor_version", PLUGIN_VERSION, "Plugin version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_REPLICATED);
	
	HookEvent("round_start", WD_Event_RoundStart);
	HookEvent("door_open", WD_Event_DoorOpen);
}

public WD_Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	ent_safedoor = -1;
	CreateTimer(0.5, CheckDelay)
}

public Action:CheckDelay(Handle:timer)
{
	CheckSafeRoomDoor()
}	
	
CheckSafeRoomDoor()
{
	ent_safedoor_check = -1;
	while ((ent_safedoor_check = FindEntityByClassname(ent_safedoor_check, SAFEDOOR_CLASS)) != -1)
	if (ent_safedoor_check > 0)
	{
		new spawn_flags;
		decl String:model[255];
		GetEntPropString(ent_safedoor_check, Prop_Data, "m_ModelName", model, sizeof(model));
		spawn_flags = GetEntProp(ent_safedoor_check, Prop_Data, "m_spawnflags");

		if (((strcmp(model, SAFEDOOR_MODEL_01) == 0) && ((spawn_flags == 8192) || (spawn_flags == 0))) || ((strcmp(model, SAFEDOOR_MODEL_02) == 0) && ((spawn_flags == 8192) || (spawn_flags == 0))))
		{
			ent_safedoor = ent_safedoor_check;
		}
	}
}

public Action: WD_Event_DoorOpen(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (ent_safedoor > 0)
	{
		if (GetEventBool(event, "checkpoint"))
		{
			new client = GetClientOfUserId(GetEventInt(event, "userid"));
			{
				ReplaceSafeDoor(client)
			}
		}
		
	}
}

ReplaceSafeDoor(client)
{
	new ent_brokendoor = CreateEntityByName("prop_physics");
	decl String:model[255];
	GetEntPropString(ent_safedoor, Prop_Data, "m_ModelName", model, sizeof(model));
	
	decl Float:pos[3], Float:ang[3];
	GetEntPropVector(ent_safedoor, Prop_Send, "m_vecOrigin", pos);
	GetEntPropVector(ent_safedoor, Prop_Send, "m_angRotation", ang);

	AcceptEntityInput(ent_safedoor, "Kill");

	DispatchKeyValue(ent_brokendoor, "model", model);
	DispatchKeyValue(ent_brokendoor, "spawnflags", "4");

	DispatchSpawn(ent_brokendoor);
	
	decl Float:EyeAngles[3];
	decl Float:Push[3];
	decl Float:ang_fix[3];
			
	ang_fix[0] = (ang[0] - 5.0);
	ang_fix[1] = (ang[1] + 5.0);
	ang_fix[2] = (ang[2]);
			
	GetClientEyeAngles(client, EyeAngles);
	Push[0] = (100.0 * Cosine(DegToRad(EyeAngles[1])));
	Push[1] = (100.0 * Sine(DegToRad(EyeAngles[1])));
	Push[2] = (15.0 * Sine(DegToRad(EyeAngles[0])));
	
	TeleportEntity(ent_brokendoor, pos, ang_fix, Push);
	CreateTimer(10.0, FadeBrokenDoor, ent_brokendoor);
}

public Action:FadeBrokenDoor(Handle:timer, any:ent_brokendoor)
{
	if (IsValidEntity(ent_brokendoor))
	{
		SetEntityRenderFx(ent_brokendoor, RENDERFX_FADE_FAST); //RENDERFX_FADE_SLOW 3.5
		CreateTimer(1.5, KillBrokenDoorEntity, ent_brokendoor);
	}
}

public Action:KillBrokenDoorEntity(Handle:timer, any:ent_brokendoor)
{
	if (IsValidEntity(ent_brokendoor))
	{
		AcceptEntityInput(ent_brokendoor, "Kill");
	}
}