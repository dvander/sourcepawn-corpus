/*
https://developer.valvesoftware.com/wiki/Func_rotating
Bug:
Func_rotating stops moving after some time and spams console with "Bad SetLocalAngles" error, for example with speed 3000 func_rotating entities will stop after 2min, 300speed - 20min etc (new CSGO game breaking bug for community maps); same bug still exists in CSS for years..
*/

#pragma semicolon 1
#pragma newdecls required

static const char	PL_NAME[]	= "Fix angles",
					PL_VER[]	= "1.0.4";

bool bEnable,
	bMsg;
float fTime;

Handle hTimer;

public Plugin myinfo = 
{
	name		= PL_NAME,
	author		= "Grey83",
	description	= "Fixes error 'Bad SetLocalAngles' in server console",
	version		= PL_VER,
	url			= "https://forums.alliedmods.net/showthread.php?t=285750"
}

public void OnPluginStart()
{
	CreateConVar("sm_fix_angles_version", PL_VER, PL_NAME, FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	ConVar CVar;
	(CVar = CreateConVar("sm_fix_angles_enable","1",	"Enables/disables the plugin", _, true, _, true, 1.0)).AddChangeHook(CVarChanged_Enable);
	bEnable = CVar.BoolValue;
	(CVar = CreateConVar("sm_fix_angles_msg",	"0",	"Enables/disables messages in the server console", _, true, _, true, 1.0)).AddChangeHook(CVarChanged_Msg);
	bMsg = CVar.BoolValue;
	(CVar = CreateConVar("sm_fix_angles_time",	"30",	"The time between inspections of entities angles", _, true, 10.0, true, 120.0)).AddChangeHook(CVarChanged_Time);
	fTime = CVar.FloatValue;

	AutoExecConfig(true, "fix_angles");
}

public void CVarChanged_Enable(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	bEnable = CVar.BoolValue;
	StartCheck();
}

public void CVarChanged_Msg(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	bMsg = CVar.BoolValue;
}

public void CVarChanged_Time(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	fTime = CVar.FloatValue;
	if(hTimer) StartCheck();
}

public void OnMapStart()
{
	if(bEnable) StartCheck();
}

public void OnMapEnd()
{
	if(hTimer) delete hTimer;
}

stock void StartCheck()
{
	OnMapEnd();
	if(bEnable) hTimer = CreateTimer(fTime, CheckAngles, _, TIMER_REPEAT);
}

public Action CheckAngles(Handle timer)
{
	static int i, max;
	for(i = MaxClients+1, max = GetMaxEntities(); i <= max; i++) if(IsValidEntity(i) && HasEntProp(i, Prop_Send, "m_angRotation"))
	{
		static bool wrongAngle;
		static float ang[3], old_ang[3];
		GetEntPropVector(i, Prop_Send, "m_angRotation", ang);
		old_ang = ang;
		wrongAngle = false;
		for(int j; j < 3; j++)
		{
			if(ang[j] != ang[j]) ang[j] = 0.0;	//	NAN
			else if(FloatAbs(ang[j]) > 360)
			{
				wrongAngle = true;
				ang[j] = FloatFraction(ang[j]) + RoundToFloor(ang[j]) % 360;
			}
		}
		if(!wrongAngle) continue;

		SetEntPropVector(i, Prop_Send, "m_angRotation", ang);
		if(!bMsg) continue;

		static char class[64], name[64];
		class[0] = name[0] = 0;
		GetEdictClassname(i, class, 64);
		GetEntPropString(i, Prop_Data, "m_iName", name, 64);
		PrintToServer("\nWrong angles of the prop '%s' (#%d, '%s'):\n%.2f, %.2f, %.2f (fixed to: %.2f, %.2f, %.2f)\n", class, i, name, old_ang[0], old_ang[1], old_ang[2], ang[0], ang[1], ang[2]);
	}
	return Plugin_Continue;
}