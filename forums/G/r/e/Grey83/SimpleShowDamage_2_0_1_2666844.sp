#pragma semicolon 1
#pragma newdecls required

#include <sdkhooks>
#include <sdktools_entinput>
#include <sdktools_functions>
#include <sdktools_stringtables>
#if SOURCEMOD_V_MINOR >= 9
	#include <sdktools_variant_t>
#endif

enum
{
	HG_Generic = 0,
	HG_Head,
	HG_Chest,
	HG_Stomach,
	HG_Leftarm,
	HG_Rightarm,
	HG_Leftleg,
	HG_Rightleg
};

bool
	bCSGO,
	bEnable,
	bMode,
	g_bIsFired[MAXPLAYERS+1],
	g_bIsCrit[MAXPLAYERS+1][MAXPLAYERS+1],
	g_bState[MAXPLAYERS+1];
int
	iType,
	g_iTotalSGDamage[MAXPLAYERS+1][MAXPLAYERS+1];
float
	fDist,
	g_fPlayerPosLate[MAXPLAYERS+1][3];

public Plugin myinfo =
{
	name		= "Show Damage [Multi methods]",
	version		= "2.0.1",
	description	= "Show damage in hint message, HUD and Particle",
	author		= "TheBΦ$$♚#2967 (rewritten by Grey83)",
	url			= "http://sourcemod.net"
};

public void OnPluginStart()
{
	EngineVersion ev = GetEngineVersion();
	if(ev == Engine_CSGO) bCSGO = true;
	else if(ev != Engine_CSS) SetFailState("Plugin for CSS and CSGO only!");

	LoadTranslations("Simple_Show_Damage.phrases");

	ConVar cvar;
	cvar = CreateConVar("sm_show_damage_enable", "1", "Enable/Disable plugin?", _, true, _, true, 1.0);
	cvar.AddChangeHook(CVarChanged_Enable);
	bEnable = cvar.BoolValue;

	cvar = CreateConVar("sm_show_damage_type", "0", "0 = Show damage in Hint message\n1 = Show damage in HUD message\n2 = Show damage as particle", _, true, _, true, bCSGO ? 2.0 : 1.0);
	cvar.AddChangeHook(CVarChanged_Type);
	iType = cvar.IntValue;

	cvar = CreateConVar("sm_show_damage_mode", "1", "0 = Show damage to victim only\n1 = Show damage and remaining health of victim", _, true, _, true, 2.0);
	cvar.AddChangeHook(CVarChanged_Mode);
	bMode = cvar.BoolValue;

	if(bCSGO)
	{
		cvar = CreateConVar("sm_show_damage_hit_distance", "50.0", "Distance between victim player and damage numbers (NOTE: Make that value lower to prevent numbers show up through the walls)", _, true, 0.0);
		cvar.AddChangeHook(CVarChanged_Dist);
		fDist = cvar.FloatValue;
	}

	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Pre);
	AutoExecConfig(true, "Simple_Show_Damage");
}

public void CVarChanged_Enable(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	bEnable = cvar.BoolValue;
}

public void CVarChanged_Type(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	iType = cvar.IntValue;
}

public void CVarChanged_Mode(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	bMode = cvar.BoolValue;
}

public void CVarChanged_Dist(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	fDist = cvar.FloatValue;
}

public void OnMapStart()
{
	if(!bCSGO) return;

	AddFileToDownloadsTable("particles/gammacase/hit_nums.pcf");
	AddFileToDownloadsTable("materials/gammacase/fortnite/hitnums/nums_bw.vmt");
	AddFileToDownloadsTable("materials/gammacase/fortnite/hitnums/nums_bw.vtf");
	PrecacheGeneric("particles/gammacase/hit_nums.pcf", true);
}

public void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	if(!bEnable)
		return;

	static int victim, attacker, health, dmg;
	if(!(attacker = GetClientOfUserId(event.GetInt("attacker"))) || !(victim = GetClientOfUserId(event.GetInt("userid")))
	|| attacker == victim)
		return;

	health = event.GetInt("health");
	dmg = event.GetInt("dmg_health");

	switch(iType)
	{
		case 0:
		{
			if(!bCSGO)
			{
				if(!bMode)
					PrintHintText(attacker, "%t %i %t %N", "Damage Giver", dmg, "Damage Taker", victim);
				else PrintHintText(attacker, "%t  %t %N\n %t %i", "Damage Giver", dmg, "Damage Taker", victim, "Health Remaining", health);
				return;
			}

			if(!bMode)
				PrintHintText(attacker, "%t <font color='#FF0000'>%i</font> %t <font color='#3DB1FF'>%N", "Damage Giver", dmg, "Damage Taker", victim);
			else PrintHintText(attacker, "%t <font color='#FF0000'>%i</font> %t <font color='#3DB1FF'>%N</font>\n %t <font color='#00FF00'>%i</font>", "Damage Giver", dmg, "Damage Taker", victim, "Health Remaining", health);
		}
		case 1:
		{
			if(!bMode)
			{
				if(health > 50)
					SetHudTextParams(-1.0, 0.45, 1.3, 0, 253, 30, 200, 1);	// green
				else if(health > 20)
					SetHudTextParams(-1.0, 0.45, 1.3, 253, 229, 0, 200, 1);	// yellow
				else SetHudTextParams(-1.0, 0.45, 1.3, 255, 0, 0, 200, 1);	// red
				ShowHudText(attacker, -1, "%i", dmg);
			}
			else
			{
				if(health > 50)
					SetHudTextParams(0.43, 0.45, 1.3, 0, 253, 30, 200, 1);	// green
				else if(health > 20)
					SetHudTextParams(0.43, 0.45, 1.3, 253, 229, 0, 200, 1);	// yellow
				else SetHudTextParams(0.43, 0.45, 1.3, 255, 0, 0, 200, 1);	// red
				ShowHudText(attacker, -1, "%i", health);

				SetHudTextParams(0.57, 0.45, 1.3, 255, 255, 255, 200, 1);	// white
				ShowHudText(attacker, -1, "%i", dmg);
			}
		}
		case 2:
		{
			static bool headshot;
			headshot = event.GetInt("hitgroup") == HG_Head;
			static char wpn[16];
			event.GetString("weapon", wpn, sizeof(wpn));
			if(!strcmp(wpn, "xm1014") || !strcmp(wpn, "nova") || !strcmp(wpn, "mag7") || !strcmp(wpn, "sawedoff"))
			{
				if(!g_bIsFired[attacker])
				{
					g_bIsFired[attacker] = true;
					g_iTotalSGDamage[attacker][victim] = dmg;

					CreateTimer(0.1, TimerHit_CallBack, GetClientUserId(attacker), TIMER_FLAG_NO_MAPCHANGE);
				}
				else g_iTotalSGDamage[attacker][victim] += dmg;

				if(headshot) g_bIsCrit[attacker][victim] = true;
				GetClientAbsOrigin(victim, g_fPlayerPosLate[victim]);
			}
			else ShowPRTDamage(attacker, victim, dmg, headshot);
		}
	}
}

public Action TimerHit_CallBack(Handle timer, int userid)
{
	static int attacker;
	if(!(attacker = GetClientOfUserId(userid)))
		return Plugin_Stop;

	g_bIsFired[attacker] = false;
	for(int i = 1; i <= MaxClients; i++) if(IsClientInGame(i) && g_iTotalSGDamage[attacker][i])
	{
		ShowPRTDamage(attacker, i, g_iTotalSGDamage[attacker][i], g_bIsCrit[attacker][i], true);
		g_iTotalSGDamage[attacker][i] = 0;
		g_bIsCrit[attacker][i] = false;
	}

	return Plugin_Continue;
}

stock void ShowPRTDamage(int attacker, int victim, int damage, bool crit, bool late = false)
{
	static float pos[3], pos2[3], ang[3], fwd[3], right[3], temppos[3], dist, d;
	static int ent, l, count, dmgnums[8];
	static char buff[16];

	count = 0;

	while(damage > 0)
	{
		dmgnums[count++] = damage % 10;
		damage /= 10;
	}

	GetClientEyeAngles(attacker, ang);
	GetClientAbsOrigin(attacker, pos2);

	if(late)
		pos = g_fPlayerPosLate[victim];
	else
		GetClientAbsOrigin(victim, pos);

	GetAngleVectors(ang, fwd, right, NULL_VECTOR);

	l = RoundToCeil(float(count) / 2.0);

	dist = GetVectorDistance(pos2, pos);
	if(dist > 700.0)
		d = dist / 700.0 * 6.0;
	else d = 6.0;

	pos[0] += right[0] * d * l * GetRandomFloat(-0.5, 1.0);
	pos[1] += right[1] * d * l * GetRandomFloat(-0.5, 1.0);
	if(GetEntProp(victim, Prop_Send, "m_bDucked"))
		if(crit)
			pos[2] += 45.0 + GetRandomFloat(0.0, 10.0);
		else pos[2] += 25.0 + GetRandomFloat(0.0, 20.0);
	else
		if(crit)
			pos[2] += 60.0 + GetRandomFloat(0.0, 10.0);
		else pos[2] += 35.0 + GetRandomFloat(0.0, 20.0);

	for(int i = count - 1; i >= 0; i--)
	{
		temppos = pos;

		temppos[0] -= fwd[0] * fDist + right[0] * d * l;
		temppos[1] -= fwd[1] * fDist + right[1] * d * l;

		ent = CreateEntityByName("info_particle_system");
		if(ent == -1)
			SetFailState("Error creating \"info_particle_system\" entity!");

		TeleportEntity(ent, temppos, ang, NULL_VECTOR);

		FormatEx(buff, sizeof(buff), "%s_num%i_f%s", crit ? "crit" : "def", dmgnums[i], l-- > 0 ? "l" : "r");

		DispatchKeyValue(ent, "effect_name", buff);
		DispatchKeyValue(ent, "start_active", "1");
		DispatchSpawn(ent);
		ActivateEntity(ent);

		SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", attacker);
		SDKHook(ent, SDKHook_SetTransmit, SetTransmit_Hook);

		SetVariantString("OnUser1 !self:kill::3:-1");
		AcceptEntityInput(ent, "AddOutput");
		AcceptEntityInput(ent, "FireUser1");
	}
}

public Action SetTransmit_Hook(int entity, int client)
{
	static int buffer;
	if((buffer = GetEdictFlags(entity)) & FL_EDICT_ALWAYS)
		SetEdictFlags(entity, (buffer ^ FL_EDICT_ALWAYS));

	if(g_bState[client] && (client == (buffer = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity"))
	|| (buffer == GetEntPropEnt(client, Prop_Send, "m_hObserverTarget")
	&& ((buffer = GetEntProp(client, Prop_Send, "m_iObserverMode")) == 4 || buffer == 5))))
		return Plugin_Continue;

	return Plugin_Stop;
}