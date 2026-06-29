#pragma semicolon 1
#pragma newdecls required

#include <sdktools> 

static const char PLUGIN_NAME[]		= "Fix angles";
static const char PLUGIN_VERSION[]	= "1.0.2";

bool bEnable,
	bMsg;
float fTime;

Handle AngTimer;

public Plugin myinfo = 
{
	name		= PLUGIN_NAME,
	author		= "Grey83",
	description	= "Fixes error 'Bad SetLocalAngles' in server console",
	version		= PLUGIN_VERSION,
	url			= "https://forums.alliedmods.net/showthread.php?t=285750"
}

public void OnPluginStart()
{
	CreateConVar("sm_fix_angles_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	ConVar CVar;
	(CVar = CreateConVar("sm_fix_angles_enable","0",	"Enables/disables the plugin", FCVAR_DONTRECORD, true, 0.0, true, 1.0)).AddChangeHook(CVarChanged_Enable);
	bEnable = CVar.BoolValue;
	(CVar = CreateConVar("sm_fix_angles_msg",	"0",	"Enables/disables messages in the server console", _, true, 0.0, true, 1.0)).AddChangeHook(CVarChanged_Msg);
	bMsg = CVar.BoolValue;
	(CVar = CreateConVar("sm_fix_angles_time",	"30",	"The time between inspections of entities angles", _, true, 10.0, true, 120.0)).AddChangeHook(CVarChanged_Time);
	fTime = CVar.FloatValue;

	AutoExecConfig(true, "fix_angles");
}

public void CVarChanged_Enable(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	bEnable = CVar.BoolValue;
	if(bEnable && AngTimer == null) AngTimer = CreateTimer(fTime, CheckAngles, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	else if(!bEnable && AngTimer != null) KillAngTimer();
}

public void CVarChanged_Msg(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	bMsg = CVar.BoolValue;
}

public void CVarChanged_Time(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	fTime = CVar.FloatValue;
	if(AngTimer != null)
	{
		KillAngTimer();
		AngTimer = CreateTimer(fTime, CheckAngles, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}

void KillAngTimer()
{
	KillTimer(AngTimer);
	AngTimer = null;
}

public void OnMapStart()
{
	if(bEnable) AngTimer = CreateTimer(fTime, CheckAngles, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action CheckAngles(Handle timer)
{
	static int MaxEnt;
	MaxEnt = GetMaxEntities();
	for(int i = MaxClients + 1; i <= MaxEnt; i++)
	{
		if(!IsValidEntity(i) || !HasEntProp(i, Prop_Send, "m_angRotation")) continue;

		static bool wrongAngle;
		static float ang[3], old_ang[3];
		GetEntPropVector(i, Prop_Send, "m_angRotation", ang);
		old_ang = ang;
		wrongAngle = false;
		for(int j; j < 3; j++)
		{
			if(FloatAbs(ang[j]) > 360)
			{
				wrongAngle = true;
				ang[j] = FloatFraction(ang[j]) + RoundToZero(ang[j]) % 360;
			}
		}
		if(!wrongAngle) continue;

		SetEntPropVector(i, Prop_Send, "m_angRotation", ang);
		if(!bMsg) continue;

		static char class[64], name[64];
		class[0] = name[0] = 0;
		GetEdictClassname(i, class, 64);
		GetEntPropString(i, Prop_Data, "m_iName", name, 64);
		PrintToServer(">	Wrong angles of the prop '%s' (#%d, '%s'):\n	%.2f, %.2f, %.2f (fixed to: %.2f, %.2f, %.2f)", class, i, name, old_ang[0], old_ang[1], old_ang[2], ang[0], ang[1], ang[2]);
	}
	return Plugin_Continue;
}