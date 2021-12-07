#pragma semicolon 1
#pragma newdecls required

static const char PLUGIN_NAME[]		= "Velocities";
static const char PLUGIN_VERSION[]	= "1.0.1";

bool bEnable;
float fBonus,
	fMin,
	fMult;

public Plugin myinfo = 
{
	name		= PLUGIN_NAME,
	author		= "Nickelony (rewritten by Grey83)", // Special thanks to Zipcore for fixing some stuff. :)
	description	= "Adds custom velocity settings, such as sv_minvelocity, sv_bonusvelocity etc.",
	version		= PLUGIN_VERSION,
	url			= "http://steamcommunity.com/id/nickelony/"
};

public void OnPluginStart()
{
	CreateConVar("sm_velocity_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	ConVar CVar;
	(CVar = CreateConVar("sm_velocity_enable","1",	"Enables/disables the plugin", FCVAR_NOTIFY, true, 0.0, true, 1.0)).AddChangeHook(CVarChanged_Enable);
	bEnable = CVar.BoolValue;
	(CVar = CreateConVar("sm_velocity_bonus", "0.0", "Adds a fixed amount of bonus velocity every time you jump.", FCVAR_NOTIFY, true)).AddChangeHook(CVarChanged_Bonus);
	fBonus = CVar.FloatValue;
	(CVar = CreateConVar("sm_velocity_min", "0.0", "Minimum amount of velocity to keep per jump.", FCVAR_NOTIFY, true)).AddChangeHook(CVarChanged_Min);
	fMin = CVar.FloatValue;
	(CVar = CreateConVar("sm_velocity_multiplier", "1.0", "Multiplies your current velocity every time you jump.", FCVAR_NOTIFY, true)).AddChangeHook(CVarChanged_Mult);
	fMult = CVar.FloatValue;

	HookToggle_Jump();

	AutoExecConfig();
}

public void CVarChanged_Enable(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	bEnable = CVar.BoolValue;
	HookToggle_Jump();
}

stock void HookToggle_Jump()
{
	static bool hooked;
	if(bEnable == hooked) return;

	if((hooked = !hooked)) HookEvent("player_jump", PlayerJumpEvent);
	else UnhookEvent("player_jump", PlayerJumpEvent);
}

public void CVarChanged_Bonus(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	fBonus = CVar.FloatValue;
}

public void CVarChanged_Min(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	fMin = CVar.FloatValue;
}

public void CVarChanged_Mult(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	fMult = CVar.FloatValue;
}

public void PlayerJumpEvent(Event event, const char[] name, bool dontBroadcast)
{
	if(fBonus || (fMin && fMin != 1.0) || (fMult && fMult != 1.0)) RequestFrame(SetSpeed, event.GetInt("userid"));
}

void SetSpeed(any userid)
{
	int client = GetClientOfUserId(userid);
	if(!client) return;

	static float vAbsVelocity[3], fCurrentSpeed;
	GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", vAbsVelocity);
	fCurrentSpeed = SquareRoot(Pow(vAbsVelocity[0], 2.0) + Pow(vAbsVelocity[1], 2.0));
	if(fCurrentSpeed > 0)			// Bonus
	{
		static float x;
		x = fCurrentSpeed / (fCurrentSpeed + fBonus);
		vAbsVelocity[0] /= x;
		vAbsVelocity[1] /= x;
		if(fCurrentSpeed < fMin)	// Min
		{
			x = fCurrentSpeed / fMin;
			vAbsVelocity[0] /= x;
			vAbsVelocity[1] /= x;
		}
		// ? => vAbsVelocity[] /= fCurrentSpeed * fCurrentSpeed / ((fCurrentSpeed + fBonus) * fMin)
	}
	if(fMult && fMult != 1.0)		// Mult
	{
		vAbsVelocity[0] *= fMult;
		vAbsVelocity[1] *= fMult;
	}
	SetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", vAbsVelocity);
}