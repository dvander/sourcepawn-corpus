#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

public Plugin: myinfo =
{
	name = "Raining money",
	author = "PeEzZ",
	description = "You can drop your cash.",
	version = "1.0",
	url = ""
};

#define MODEL_MONEY "models/props/cs_assault/money.mdl"
#define SOUND_MONEY "ui/item_paper_pickup.wav"

#define MAX_DISTANCE 50.0 //Auto-pickup disatance between the player and the money

new Handle: CVAR_MONEY_VALUE = INVALID_HANDLE,
	Handle: CVAR_MONEY_GROUND = INVALID_HANDLE,
	Handle: CVAR_MONEY_TIME = INVALID_HANDLE;

new MONEY_ONGROUND = 0;

public OnPluginStart()
{
	CVAR_MONEY_VALUE = CreateConVar("sm_rainingmoney_value", "100", "The value of one money.",  _, true, 100.0);
	CVAR_MONEY_GROUND = CreateConVar("sm_rainingmoney_ground", "100", "Max number of money on the ground. 0 - Disable.",  _, true, 0.0);
	CVAR_MONEY_TIME = CreateConVar("sm_rainingmoney_time", "60.0", "Time, after the dropped money will be removed. 0 - Disable.",  _, true, 0.0);
	
	RegConsoleCmd("sm_dropmoney", CMD_DropMoney);
	RegConsoleCmd("sm_rainingmoney", CMD_DropMoney);
	RegConsoleCmd("sm_dm", CMD_DropMoney);
	RegConsoleCmd("sm_rm", CMD_DropMoney);
	
	HookEvent("round_start", OnRoundStart);
	
	LoadTranslations("rainingmoney.phrases");
}

public OnMapStart()
{
	PrecacheModel(MODEL_MONEY, true);
	PrecacheSound(SOUND_MONEY, true);
}

//-----EVENTS-----//
public Action: OnRoundStart(Handle: event, const String: name[], bool: dontBroadcast)
{
	MONEY_ONGROUND = 0;
}

//-----COMMANDS-----//
public Action: CMD_DropMoney(client, args)
{
	if(!IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	if(!IsPlayerAlive(client))
	{
		PrintToChat(client, "%t", "AliveOnly");
		return Plugin_Handled;
	}
	
	new account = GetEntProp(client, Prop_Send, "m_iAccount");
	if(account <= 0)
	{
		PrintToChat(client, "%t", "NoMoney");
		return Plugin_Handled;
	}
	
	new max = GetConVarInt(CVAR_MONEY_GROUND);
	if((MONEY_ONGROUND >= max) && (max != 0))
	{
		PrintToChat(client, "%t", "TooManyOnGround");
		return Plugin_Handled;
	}
	
	new Float: eye_pos[3],
		Float: eye_angles[3];
	
	GetClientEyePosition(client, eye_pos);
	GetClientEyeAngles(client, eye_angles);
	
	new Handle: trace = TR_TraceRayFilterEx(eye_pos, eye_angles, MASK_SOLID, RayType_Infinite, Filter_ExcludeStarter, client);
	if(!TR_DidHit(trace))
	{
		return Plugin_Handled;
	}
	
	new entity = CreateEntityByName("prop_physics_override");
	if(!IsValidEntity(entity))
	{
		return Plugin_Handled;
	}
	
	DispatchKeyValue(entity, "model", MODEL_MONEY);
	DispatchKeyValue(entity, "rendercolor", "150 255 150"); //The color of the money
	DispatchKeyValue(entity, "spawnflags", "4358"); //No phys dmg, Debris, +USE, Debris trigger
	DispatchSpawn(entity);
	
	new String: buffer[16],
		value = GetConVarInt(CVAR_MONEY_VALUE);
	
	if(account < value)
	{
		value = account;
	}
	SetEntProp(client, Prop_Send, "m_iAccount", account - value);
	
	Format(buffer, sizeof(buffer), "%i", value);
	SetEntPropString(entity, Prop_Data, "m_iName", buffer);
	
	new Float: end_pos[3];
	TR_GetEndPosition(end_pos, trace);
	
	SubtractVectors(end_pos, eye_pos, end_pos);
	NormalizeVector(end_pos, end_pos);
	ScaleVector(end_pos, 300.0);
	
	new Float: velocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);
	AddVectors(end_pos, velocity, velocity);
	velocity[2] = velocity[2] + 100.0;
	
	eye_pos[2] = eye_pos[2] - 6.0;
	eye_angles[0] = eye_angles[2] = 0.0;
	eye_angles[1] = eye_angles[1] + 90.0;
	
	TeleportEntity(entity, eye_pos, eye_angles, velocity);
	EmitSoundToAll(SOUND_MONEY, entity);
	
	SDKHook(entity, SDKHook_Use, OnUse);
	CreateTimer(0.5, Timer_Money, EntIndexToEntRef(entity));
	
	new Float: remove = GetConVarFloat(CVAR_MONEY_TIME);
	if(remove > 0.0)
	{
		CreateTimer(remove, Timer_Remove, EntIndexToEntRef(entity));
	}
	
	MONEY_ONGROUND ++;
	
	PrintToChat(client, "%t", "MoneyDropped", value);
	return Plugin_Handled;
}

//-----TIMERS-----//
public Action: Timer_Money(Handle: timer, any: reference)
{
	new entity = EntRefToEntIndex(reference);
	if((entity != INVALID_ENT_REFERENCE) && IsValidEntity(entity))
	{
		new Float: money_pos[3],
			Float: client_pos[3];
		
		GetEntPropVector(entity, Prop_Data, "m_vecOrigin", money_pos);
		for(new client = 1; client <= MaxClients; client++)
		{
			if(IsClientInGame(client) && IsPlayerAlive(client))
			{
				GetClientAbsOrigin(client, client_pos);
				client_pos[2] = client_pos[2] +  32.0;
				if(GetVectorDistance(client_pos, money_pos) <= MAX_DISTANCE)
				{
					PickUpMoney(client, entity);
				}
			}
		}
		CreateTimer(0.2, Timer_Money, EntIndexToEntRef(entity));
	}
}
public Action: Timer_Remove(Handle: timer, any: reference)
{
	new entity = EntRefToEntIndex(reference);
	if((entity != INVALID_ENT_REFERENCE) && IsValidEntity(entity))
	{
		AcceptEntityInput(entity, "Kill");
		MONEY_ONGROUND --;
	}
}

//-----SDKHOOKS-----//
public Action: OnUse(entity, pusher)
{
	if(IsClientInGame(pusher) && IsPlayerAlive(pusher))
	{
		PickUpMoney(pusher, entity);
	}
}

//-----STOCKS-----//
PickUpMoney(client, entity)
{
	new String: buffer[8];
	GetEntPropString(entity, Prop_Data, "m_iName", buffer, sizeof(buffer));
	
	new value = StringToInt(buffer);
	SetEntProp(client, Prop_Send, "m_iAccount", GetEntProp(client, Prop_Send, "m_iAccount") + value);
	
	EmitSoundToAll(SOUND_MONEY, entity);
	AcceptEntityInput(entity, "Kill");
	
	MONEY_ONGROUND --;
	
	PrintToChat(client, "%t", "MoneyCollected", value);
}

//-----FILTERS------//
public bool: Filter_ExcludeStarter(entity, contentsMask, any: data)
{
	return (data != entity);
}