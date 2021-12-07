#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define VERSION "1.1"

#define DOORMODEL "models/props_interiors/door_sliding_breakable01.mdl"
#define DOOR_REGEN_PERIOD 2.0

new Handle:cvarDoor = INVALID_HANDLE;
new hookedRS;

new doorEntity;
new doorHealth;

public Plugin:myinfo =
{
	name = "L4D NM3 Door Bug Fix",
	author = "Fyren (trimmed by B-Man, maintained by Downtown1)",
	description = "Stops the door bug in NM3",
	version = VERSION,
	url = ""
};

public OnPluginStart()
{
	CreateConVar("l4de_version", VERSION, "L4D Door Fix version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);

	cvarDoor = CreateConVar("l4de_door", "1", "Make the NM3 exploit door unbreakable", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	HookConVarChange(cvarDoor, cvarCallback);

	AutoExecConfig(true, "l4de");

	if (GetConVarInt(cvarDoor)) 
	{
		hookedRS = 1;
		HookEvent("round_start", eventRSDoor);
	}
}

public cvarCallback(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == cvarDoor)
		if (StringToInt(newValue) && !hookedRS)
		{
			hookedRS = 1;
			HookEvent("round_start", eventRSDoor);
		}
		else if (!StringToInt(newValue) && hookedRS)
		{
			hookedRS = 0;
			UnhookEvent("round_start", eventRSDoor);
		}
}

public eventRSDoor(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:map[64];
	GetCurrentMap(map, sizeof(map));

	if (StrContains(map, "hospital03_sewers") == -1) return;

	new ent, found;
	decl String:model[256];
	while (!found && ((ent = FindEntityByClassname(ent, "prop_dynamic")) != -1))
	{
		GetEntPropString(ent, Prop_Data, "m_ModelName", model, sizeof(model));
		if (StrEqual(model, DOORMODEL)) found = 1;
	}

	if (found) 
	{
		doorHealth = GetEntProp(ent, Prop_Data, "m_iHealth");
		
		//regenerate door hp every 2 secs (it has 200 hp)
		//note survivors do about 4 dps normal melee, 16 dps fast melee to the door
		CreateTimer(DOOR_REGEN_PERIOD, timerRegenerateDoor, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		
		doorEntity = ent;
	}
	else LogError("Couldn't find the exploit door!");
}

//repeatedly regenerate the door health to full every 5 seconds
public Action:timerRegenerateDoor(Handle:timer)
{
	if(doorEntity) 
	{
		if(IsValidEntity(doorEntity)) 
		{
			new currentHealth = GetEntProp(doorEntity, Prop_Data, "m_iHealth");
			if(currentHealth != doorHealth) 
			{
				PrintToChatAll("[SM] Detected and blocked door bashing exploit attempt.");
			}
			
			//regenerate door so survivors can't break it down
			SetEntProp(doorEntity, Prop_Data, "m_iHealth", doorHealth);
		}
		else
		{
			//door has been destroyed by tank
			doorEntity = 0;
			KillTimer(timer);
		}
	}
}
