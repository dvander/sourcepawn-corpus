#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.2"

#define SAFEDOOR_MODEL_01 "models/props_doors/checkpoint_door_01.mdl"
#define SAFEDOOR_MODEL_02 "models/props_doors/checkpoint_door_-01.mdl"
#define SAFEDOOR_CLASS "prop_door_rotating_checkpoint"

int ent_safedoor, ent_safedoor_check;

public Plugin myinfo =
{
	name = "L4D2 Weak Door",
	author = "Glide Loading",
	description = "Saferoom door will be broken out at opening",
	version = PLUGIN_VERSION,
	url = "not supported"
};

public void OnPluginStart()
{
	CreateConVar("l4d2_weakdoor_version", PLUGIN_VERSION, "Plugin version", FCVAR_NOTIFY|FCVAR_SPONLY|FCVAR_DONTRECORD);

	HookEvent("round_start", WD_Event_RoundStart);
	HookEvent("door_open", WD_Event_DoorOpen);
}

void WD_Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	ent_safedoor = -1;
	CreateTimer(0.5, CheckDelay);
}

Action CheckDelay(Handle timer)
{
	CheckSafeRoomDoor();
}	

void CheckSafeRoomDoor()
{
	ent_safedoor_check = -1;
	while ((ent_safedoor_check = FindEntityByClassname(ent_safedoor_check, SAFEDOOR_CLASS)) != -1)
	{
		if (ent_safedoor_check > 0)
		{
			int spawn_flags;
			char model[255];
			GetEntPropString(ent_safedoor_check, Prop_Data, "m_ModelName", model, sizeof(model));
			spawn_flags = GetEntProp(ent_safedoor_check, Prop_Data, "m_spawnflags");

			if (((strcmp(model, SAFEDOOR_MODEL_01) == 0) && ((spawn_flags == 8192) || (spawn_flags == 0))) || ((strcmp(model, SAFEDOOR_MODEL_02) == 0) && ((spawn_flags == 8192) || (spawn_flags == 0))))
			{
				ent_safedoor = ent_safedoor_check;
			}
		}
	}
}

Action WD_Event_DoorOpen(Event event, const char[] name, bool dontBroadcast)
{
	if (ent_safedoor > 0)
	{
		if (event.GetBool("checkpoint"))
		{
			int client = GetClientOfUserId(event.GetInt("userid"));
			if(client)
			{
				ReplaceSafeDoor(client);
			}
		}
	}
	return Plugin_Continue;
}

void ReplaceSafeDoor(int client)
{
	int ent_brokendoor = CreateEntityByName("prop_physics");
	char model[255];
	float pos[3], ang[3], EyeAngles[3], Push[3], ang_fix[3];
	GetEntPropString(ent_safedoor, Prop_Data, "m_ModelName", model, sizeof(model));
	GetEntPropVector(ent_safedoor, Prop_Send, "m_vecOrigin", pos);
	GetEntPropVector(ent_safedoor, Prop_Send, "m_angRotation", ang);
	AcceptEntityInput(ent_safedoor, "Kill");
	DispatchKeyValue(ent_brokendoor, "model", model);
	DispatchKeyValue(ent_brokendoor, "spawnflags", "4");
	DispatchSpawn(ent_brokendoor);

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

Action FadeBrokenDoor(Handle timer, any ent_brokendoor)
{
	if (IsValidEntity(ent_brokendoor))
	{
		SetEntityRenderFx(ent_brokendoor, RENDERFX_FADE_FAST); //RENDERFX_FADE_SLOW 3.5
		CreateTimer(1.5, KillBrokenDoorEntity, ent_brokendoor);
	}
}

Action KillBrokenDoorEntity(Handle timer, any ent_brokendoor)
{
	if (IsValidEntity(ent_brokendoor))
	{
		AcceptEntityInput(ent_brokendoor, "Kill");
	}
	return Plugin_Stop;
}
