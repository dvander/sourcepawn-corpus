#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

ConVar convar_Default;

int g_Poured;
int g_TotalCans;

public Plugin myinfo = 
{
	name = "[L4D2] Total Cans", 
	author = "Keith The Corgi", 
	description = "Sets the total amount of gas cans required by default and adds a command to set them.", 
	version = "1.0.0", 
	url = "https://github.com/keiththecorgi"
};

public void OnPluginStart()
{
	convar_Default = CreateConVar("sm_totalcans_default", "6", "How many cans should the display bar require by default?", FCVAR_NOTIFY, true, 1.0);
	g_TotalCans = convar_Default.IntValue;

	RegAdminCmd("sm_totalcans", Command_TotalCans, ADMFLAG_ROOT, "Sets total cans required currently.");

	HookEvent("gascan_pour_completed", Event_OnGasCanPoured);
	HookEvent("round_start", Event_OnRoundStart);
}

public void OnMapStart()
{
	g_Poured = 0;
	g_TotalCans = 0;
}

public void OnConfigsExecuted()
{
	g_TotalCans = convar_Default.IntValue;
}

public Action Command_TotalCans(int client, int args)
{
	char sValue[32];
	GetCmdArgString(sValue, sizeof(sValue));

	int value = StringToInt(sValue);

	if (value < 1)
	{
		ReplyToCommand(client, "Total cans must be 1 or more.");
		return Plugin_Handled;
	}

	Ent_Fire("progress_display", "SetTotalItems", value);
	ReplyToCommand(client, "Total cans set to: %i", value);

	g_TotalCans = value;

	return Plugin_Handled;
}

void Ent_Fire(const char[] sName, const char[] sInput, int Params = -1)
{
	char sEntName[64];

	for (int i = 0; i < 4096; i++)
	{
		if (IsValidEntity(i))
		{
			GetEntPropString(i, Prop_Data, "m_iName", sEntName, sizeof(sEntName));
			
			if (StrEqual(sEntName, sName))
			{
				if (Params != -1)
					SetVariantInt(Params);

				AcceptEntityInput(i, sInput);
				break;
			}
		}
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (StrEqual(classname, "game_scavenge_progress_display", false))
		SDKHook(entity, SDKHook_SpawnPost, OnSpawnPost);
}

public void OnSpawnPost(int entity)
{
	char sName[64];
	GetEntPropString(entity, Prop_Data, "m_iName", sName, sizeof(sName));

	if (StrEqual(sName, "progress_display"))
		CreateTimer(3.0, Timer_SetCans, EntIndexToEntRef(entity));
}

public Action Timer_SetCans(Handle timer, any data)
{
	int entity = EntRefToEntIndex(data);

	if (!IsValidEntity(entity))
		return Plugin_Stop;
	
	SetVariantInt(convar_Default.IntValue);
	AcceptEntityInput(entity, "SetTotalItems");

	g_TotalCans = convar_Default.IntValue;

	return Plugin_Stop;
}

public void Event_OnGasCanPoured(Event event, const char[] name, bool dontBroadcast)
{
	g_Poured++;

	if (g_Poured >= g_TotalCans)
		Ent_Fire("relay_car_ready", "trigger");
}

public void Event_OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_Poured = 0;
}