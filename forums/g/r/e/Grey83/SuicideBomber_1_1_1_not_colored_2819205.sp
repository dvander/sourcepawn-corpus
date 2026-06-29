#pragma semicolon 1
#pragma newdecls required

#include <sdkhooks>
#include <sdktools_engine>
#include <sdktools_entinput>
#include <sdktools_functions>

Handle
	repeater;
bool
	i_enabled;
char
	s_class[MAXPLAYERS+1][64],
	s_damage[16];
float
	f_detonate_range,
	f_resist,
	f_delay;

public Plugin myinfo =
{
	name		= "SuicideBomber",
	version		= "1.1.1_not_colored (rewritten by Grey83)",
	author		= "rrrfffrrr",
	description	= "Make suicide bomber",
	url			= "https://github.com/rrrfffrrr/Insurgency-server-plugins/blob/master/scripting/SuicideBomber.sp"
}

public void OnPluginStart()
{
	ConVar cvar;
	cvar = CreateConVar("sm_suicide_enabled", "1", "Let bot suicide", FCVAR_NOTIFY, true, _, true, 1.0);
	cvar.AddChangeHook(CVarChange_Enable);
	i_enabled = cvar.BoolValue;

	cvar = CreateConVar("sm_suicide_bomber", "sharpshooter", "Let bot suicide", FCVAR_NOTIFY|FCVAR_PRINTABLEONLY);
	cvar.AddChangeHook(CVarChange_Class);
	CVarChange_Class(cvar, NULL_STRING, NULL_STRING);

	cvar = CreateConVar("sm_suicide_detonate_range", "600", "Detonate range", FCVAR_NOTIFY, true);
	cvar.AddChangeHook(CVarChange_Range);
	f_detonate_range = cvar.FloatValue;

	cvar = CreateConVar("sm_suicide_resist", "20", "Damage resistance", FCVAR_NOTIFY, true, 1.0);
	cvar.AddChangeHook(CVarChange_Resist);
	CVarChange_Resist(cvar, NULL_STRING, NULL_STRING);

	cvar = CreateConVar("sm_suicide_delay", "0.01", "Detonate delay", FCVAR_NOTIFY, true);
	cvar.AddChangeHook(CVarChange_Delay);
	f_delay = cvar.FloatValue;

	AutoExecConfig(true, "suicide_bomber");

	HookEvent("player_pick_squad", Event_PlayerPickSquad);
	HookEvent("round_start", Event_Start, EventHookMode_PostNoCopy);

	IntToString(DMG_BLAST, s_damage, sizeof(s_damage));
}

public void CVarChange_Enable(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	i_enabled = cvar.BoolValue;
}

public void CVarChange_Class(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	cvar.GetString(s_class[0], sizeof(s_class[]));

	for(int i = 1; i < MaxClients + 1; ++i) if(IsClientInGame(i))
		PrintToServer("%i is %s, and %s", i, IsFakeClient(i) ? "bot" : "player", s_class[i]);
}

public void CVarChange_Range(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	f_detonate_range = cvar.FloatValue;
}

public void CVarChange_Resist(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	f_resist = 1.0 / cvar.FloatValue;
	PrintToServer("Resist is now %f", f_resist);
}

public void CVarChange_Delay(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	f_delay = cvar.FloatValue;
}

public void OnMapStart()
{
	PrecacheModel("models/weapons/w_ied.mdl", true);
	PrecacheSound("weapons/IED/handling/IED_throw.wav", true);
	PrecacheSound("weapons/IED/handling/IED_trigger_ins.wav", true);
	PrecacheSound("weapons/IED/water/IED_water_detonate_01.wav", true);
	PrecacheSound("weapons/IED/water/IED_water_detonate_02.wav", true);
	PrecacheSound("weapons/IED/water/IED_water_detonate_03.wav", true);
	PrecacheSound("weapons/IED/water/IED_water_detonate_dist_01.wav", true);
	PrecacheSound("weapons/IED/water/IED_water_detonate_dist_02.wav", true);
	PrecacheSound("weapons/IED/water/IED_water_detonate_dist_03.wav", true);
	PrecacheSound("weapons/IED/IED_bounce_01.wav", true);
	PrecacheSound("weapons/IED/IED_bounce_02.wav", true);
	PrecacheSound("weapons/IED/IED_bounce_03.wav", true);
	PrecacheSound("weapons/IED/IED_detonate_01.wav", true);
	PrecacheSound("weapons/IED/IED_detonate_02.wav", true);
	PrecacheSound("weapons/IED/IED_detonate_03.wav", true);
	PrecacheSound("weapons/IED/IED_detonate_dist_01.wav", true);
	PrecacheSound("weapons/IED/IED_detonate_dist_02.wav", true);
	PrecacheSound("weapons/IED/IED_detonate_dist_03.wav", true);
	PrecacheSound("weapons/IED/IED_detonate_far_dist_01.wav", true);
	PrecacheSound("weapons/IED/IED_detonate_far_dist_02.wav", true);
	PrecacheSound("weapons/IED/IED_detonate_far_dist_03.wav", true);
}

public void Event_Start(Event event, const char[] name, bool dontBroadcast)
{
	if(repeater) CloseHandle(repeater);
	repeater = CreateTimer(1.0, FFrame, _, TIMER_REPEAT);
}

// make bomber more tank
public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_TraceAttack, FTraceAttack);
}

public Action FTraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{
	if(i_enabled && IsFakeClient(victim) && StrContains(s_class[victim], s_class[0], true) != -1)
	{
		damage *= f_resist;
		return Plugin_Changed;
	}

	return Plugin_Continue;
}

public void Event_PlayerPickSquad(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(!client || !IsClientInGame(client))
		return;

	char cls[64];
	GetEventString(event, "class_template", cls, sizeof(cls));
	if(strlen(cls) > 1) strcopy(s_class[client], sizeof(s_class[]), cls);
}

public Action FFrame(Handle timer)
{
	if(!i_enabled)
		return Plugin_Continue;

	bool check;
	float vecOrigin[3], vecAngles[3];
	for(int i = 1, j, ent, pointHurt; i <= MaxClients; i++)
		if(IsClientInGame(i) && IsFakeClient(i) && IsPlayerAlive(i) && StrContains(s_class[i], s_class[0], false) != -1)
		{
			GetClientEyePosition(i, vecOrigin);

			for(j = 1; j <= MaxClients; j++) if(i != j && IsClientInGame(j) && !IsFakeClient(j) && IsPlayerAlive(j))
			{
				GetClientEyePosition(j, vecAngles);
				if(GetVectorDistance(vecAngles, vecOrigin) < f_detonate_range)
				{
					check = true;
					break;
				}
			}

			if(!check)
				continue;

			PrintToChatAll("Bot %N detonated!", i);

			// by jaredballou
			if((ent = CreateEntityByName("grenade_ied")) == -1)
				continue;

			vecAngles[0] = vecAngles[1] = vecAngles[2] = 0.0;
			TeleportEntity(ent, vecOrigin, vecAngles, vecAngles);
			SetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity", i);
			SetEntProp(ent, Prop_Data, "m_nNextThinkTick", f_delay); //for smoke
			SetEntProp(ent, Prop_Data, "m_takedamage", 2);
			SetEntProp(ent, Prop_Data, "m_iHealth", 1);
			if(!DispatchSpawn(ent))
				continue;

			ActivateEntity(ent);

			if((pointHurt = CreateEntityByName("point_hurt")) == -1)
				continue;

			DispatchKeyValue(ent, "targetname", "hurtme");
			DispatchKeyValue(pointHurt, "DamageTarget", "hurtme");
			DispatchKeyValue(pointHurt, "Damage", "380");
			DispatchKeyValue(pointHurt, "DamageType", s_damage);
			DispatchKeyValue(pointHurt, "classname", "weapon_c4_ied");
			if(!DispatchSpawn(pointHurt))
				continue;
		
			AcceptEntityInput(pointHurt, "Hurt", i);
			DispatchKeyValue(pointHurt, "classname", "point_hurt");
			DispatchKeyValue(ent, "targetname", "donthurtme");
			RemoveEdict(pointHurt);
		}

	return Plugin_Continue;
}