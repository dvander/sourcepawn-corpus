#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "2.0"
#undef REQUIRE_PLUGIN
#include <l4d_lib>

#define IS_BOOMER(%1) (GetPlayerClass(%1) == ZC_BOOMER)
#define IS_INFECTED(%1) (IsClient(%1) && IsInfected(%1))
#define IS_ALIVE_INFECTED(%1) (IS_INFECTED(%1) && IsPlayerAlive(%1) && !IsPlayerGhost(%1))

float gVomit_Range;
float gVomit_Duration;
Handle VomitTimer[MPS];
int gMessage_Type;
float gExtinguishRadius;
bool gSplash_Enabled;

public Plugin myinfo = 
{
	name = "[L4D & L4D2] Vomit extinguishing",
	author = "Olj, Visual77, asto, raziEiL [disawar1]",
	description = "Vomit or boomer explosion can extinguish burning special infected",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showpost.php?p=2715357&postcount=64"
}

public void OnPluginStart()
{
	LoadTranslations("l4d_vomitextinguish.phrases")
	CreateConVar("l4d_ve_version", PLUGIN_VERSION, "Version of Vomit Extinguishing plugin", FCVAR_NOTIFY|FCVAR_DONTRECORD);

	ConVar cVar;
	cVar = CreateConVar("l4d_ve_splash_enabled", "1", " Enable/Disable boomer explosion to extinguish also ", FCVAR_NOTIFY);
	gSplash_Enabled = cVar.BoolValue;
	cVar.AddChangeHook(Splash_EnabledChanged);
	
	cVar = CreateConVar("l4d_ve_splash_radius", "200", "Extinguish radius of boomer explosion", FCVAR_NOTIFY);
	gExtinguishRadius = cVar.FloatValue;
	cVar.AddChangeHook(ExtinguishRadiusChanged);

	cVar = CreateConVar("l4d_ve_message_type", "1", "Message type (0 - disable, 1 - chat, 2 - hint, 3 - instructor hint)", FCVAR_NOTIFY, true, 0.0, true, 3.0)
	gMessage_Type = cVar.IntValue;
	cVar.AddChangeHook(Vomit_MessageType);
	
	cVar = FindConVar("z_vomit_duration");
	gVomit_Duration = cVar.FloatValue;
	cVar.AddChangeHook(Vomit_DurationChanged);
	
	cVar = FindConVar("z_vomit_range");
	gVomit_Range = cVar.FloatValue;
	cVar.AddChangeHook(Vomit_RangeChanged);

	HookEvent("ability_use", Vomit_Event);
	HookEvent("player_death", Splash_Event);
	HookEvent("player_spawn", EventPlayerSpawn)
	
	AutoExecConfig(true, "l4d_vomitextinguishing");
}

public Action EventPlayerSpawn(Event h_Event, const char[] s_Name, bool b_DontBroadcast)
{
	int i_Client = GetClientOfUserId(h_Event.GetInt("userid"))
	
	if (IsInfected(i_Client) && !IsFakeClient(i_Client) && IS_BOOMER(i_Client))
	{
		switch (gMessage_Type)
		{
			case 1:
			{
				PrintToChat(i_Client, "\x03[%t]\x01 %t.", "Information", "Vomit players")
			}
			case 2: 
			{
				PrintHintText(i_Client, "%t", "Vomit players")
			}
			case 3:
			{
				char s_Message[256];
				FormatEx(s_Message, sizeof(s_Message), "%t", "Vomit players")
				DisplayInstructorHint(i_Client, s_Message, "+attack")
			}
		}
	}
}

public void DisplayInstructorHint(int i_Client, char s_Message[256], char[] s_Bind)
{
	char s_TargetName[32];
	int i_Ent = CreateEntityByName("env_instructor_hint")
	FormatEx(s_TargetName, sizeof(s_TargetName), "hint%d", i_Client)
	ReplaceString(s_Message, sizeof(s_Message), "\n", " ")
	DispatchKeyValue(i_Client, "targetname", s_TargetName)
	DispatchKeyValue(i_Ent, "hint_target", s_TargetName)
	DispatchKeyValue(i_Ent, "hint_timeout", "5")
	DispatchKeyValue(i_Ent, "hint_range", "0.01")
	DispatchKeyValue(i_Ent, "hint_color", "255 255 255")
	DispatchKeyValue(i_Ent, "hint_icon_onscreen", "use_binding")
	DispatchKeyValue(i_Ent, "hint_caption", s_Message)
	DispatchKeyValue(i_Ent, "hint_binding", s_Bind)
	DispatchSpawn(i_Ent)
	AcceptEntityInput(i_Ent, "ShowHint")
	
	DataPack h_RemovePack = new DataPack()
	h_RemovePack.WriteCell(UID(i_Client))
	h_RemovePack.WriteCell(EntIndexToEntRef(i_Ent))
	CreateTimer(5.0, RemoveInstructorHint, h_RemovePack, TIMER_FLAG_NO_MAPCHANGE)
}
	
public Action RemoveInstructorHint(Handle h_Timer, DataPack h_Pack)
{
	h_Pack.Reset(false)
	int i_Client = CID(h_Pack.ReadCell())
	int i_Ent = EntRefToEntIndex(h_Pack.ReadCell())
	delete h_Pack
	
	if (IsValidEntity(i_Ent))
		RemoveEntity(i_Ent)

	if (IsClientAndInGame(i_Client))
		DispatchKeyValue(i_Client, "targetname", "")
}

public void ExtinguishRadiusChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	gExtinguishRadius = convar.FloatValue;
}			
	
public void Splash_EnabledChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	gSplash_Enabled = convar.BoolValue;
}			
	
public void Vomit_RangeChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	gVomit_Range = convar.FloatValue;
}			

public void Vomit_DurationChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	gVomit_Duration = convar.FloatValue;
}

public void Vomit_MessageType(ConVar convar, const char[] oldValue, const char[] newValue)
{
	gMessage_Type = convar.IntValue;
}			

public void Splash_Event(Event event, const char[] name, bool dontBroadcast)
{
	if (!gSplash_Enabled) return;
	int victim = GetClientOfUserId(event.GetInt("userid"));
	if (!IS_INFECTED(victim)) return;
	if (IS_BOOMER(victim))
	{
		float Boomer_Position[3], Target_Position[3];
		GetClientAbsOrigin(victim,Boomer_Position);
		for (int target = 1; target <= MaxClients; target++)
		{
			if (IS_ALIVE_INFECTED(target) && IsOnFire(target))
			{			
				GetClientAbsOrigin(target, Target_Position);
				if (RoundToNearest(GetVectorDistance(Target_Position, Boomer_Position))<gExtinguishRadius)
				{
					ExtinguishEntity(target);
				}
			}
		}
	}
}
	
public void Vomit_Event(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid")); //we get client
	if (!IS_INFECTED(client)) return; //must be valid infected
	if (IS_BOOMER(client))
	{
		VomitTimer[client] = CreateTimer(0.1, VomitTimerFunction, client, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
		CreateTimer(gVomit_Duration,KillingVomitTimer, client,TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action VomitTimerFunction(Handle timer, any client)
{
	if (!IS_ALIVE_INFECTED(client))
	{
		VomitTimer[client] = null;
		return Plugin_Stop;
	}
	int target = GetClientAimTarget(client, true);
	if (!IS_ALIVE_INFECTED(target) || !IsOnFire(target)) return Plugin_Continue;
	float boomer_position[3], target_position[3];
	GetClientAbsOrigin(client,boomer_position);
	GetClientAbsOrigin(target,target_position);
	if ((RoundToNearest(GetVectorDistance(boomer_position, target_position))<gVomit_Range))
	{
		ExtinguishEntity(target);
	}
	return Plugin_Continue;
}

public Action KillingVomitTimer(Handle timer, any client)
{
	if (VomitTimer[client] != null)
	{	
		delete VomitTimer[client];
	}
}
