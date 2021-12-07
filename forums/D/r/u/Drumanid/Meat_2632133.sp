#include <sourcemod>
#include <sdkhooks>
#include <particles>

public Plugin myinfo =
{
	name = "Meat",
	author = "Drumanid",
	version = "1.0.0",
	url = "Discrod: Drumanid#9108 | Telegram: t.me/drumanid"
};

static const char g_sMeat[4][] =
{
	"blood_impact_headshot",
	"blood_impact_headshot_01b",
	"blood_pool",
	"blood_impact_light"
};

Handle	g_hTimer;

int		g_iBlood,
		g_iCvarBleeding;

bool	g_bEvent;
		g_bCvarHeadshot,
		g_bCvarBodyLimbs,
		g_bCvarPuddle,
		g_bCvarGibs;

#define CHOOK(%0,%1) %0.AddChangeHook(view_as<ConVarChanged>(%1))
public void OnPluginStart()
{
	ConVar hCvar = CreateConVar("meat_enabled", "1", "1 - meat mode on / 0 - off", _, true, 0.0, true, 1.0);
	CHOOK(hCvar, CvarHookMeat);
	hCvar = CreateConVar("meat_headshot", "1", "1 - effect when hit in the head on / 0 - off", _, true, 0.0, true, 1.0);
	CHOOK(hCvar, CvarHookHeadshot); g_bCvarHeadshot = hCvar.BoolValue;
	hCvar = CreateConVar("meat_bodylimbs", "1", "1 - effect upon contact with limbs (body) on / 0 - off", _, true, 0.0, true, 1.0);
	CHOOK(hCvar, CvarHookBodyLimbs); g_bCvarBodyLimbs = hCvar.BoolValue;
	hCvar = CreateConVar("meat_puddle", "1", "1 - effect of the 'pool of blood' on / 0 - off", _, true, 0.0, true, 1.0);
	CHOOK(hCvar, CvarHookPuddle); g_bCvarPuddle = hCvar.BoolValue;
	hCvar = CreateConVar("meat_bleeding", "25", "How much hp should a player have so that he starts bleeding / 0 - off", _, true, 0.0, true, 100.0);
	CHOOK(hCvar, CvarHookBleeding); g_iCvarBleeding = hCvar.IntValue;
	hCvar = CreateConVar("meat_gibs", "1", "1 - create skull when a grenade explodes / 0 - do not create", _, true, 0.0, true, 1.0);
	CHOOK(hCvar, CvarHookGibs); g_bCvarGibs = hCvar.BoolValue;
	AutoExecConfig(true, "meat");
}

#define LC(%0) for(int %0 = 1; %0 <= MaxClients; ++%0) if(IsClientInGame(%0))
#define SHOOK(%0,%1) %0(%1, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive)
#define SHOOKS(%0,%1) LC(%0) SHOOK(%1, %0)
#define PLAYERDEATH(%0) %0("player_death", view_as<EventHook>(PlayerDeath))
#define TIMER if(g_iCvarBleeding != 0) g_hTimer = CreateTimer(1.0, view_as<Timer>(TimerBleeding), _, TIMER_REPEAT)
#define DELETETIMER if(g_hTimer) KillTimer(g_hTimer); g_hTimer = null
void CvarHookMeat(ConVar hCvar)
{
	DELETETIMER;
	if(hCvar.BoolValue)
	{
		if(!g_bEvent)
		{
			PLAYERDEATH(HookEvent);
			g_bEvent = true;
		}

		TIMER;
		if(g_bCvarBodyLimbs) SHOOKS(iClient, SDKHook);
	}
	else
	{
		if(g_bEvent)
		{
			PLAYERDEATH(UnhookEvent);
			g_bEvent = false;
		}

		if(g_bCvarBodyLimbs) SHOOKS(iClient, SDKUnhook);
	}
}

void CvarHookHeadshot(ConVar hCvar)
{
	g_bCvarHeadshot = hCvar.BoolValue;
}

void CvarHookBodyLimbs(ConVar hCvar)
{
	g_bCvarBodyLimbs = hCvar.BoolValue;

	if(g_bCvarBodyLimbs)
	{
		SHOOKS(iClient, SDKHook);
	}
	else SHOOKS(iClient, SDKUnhook);
}

void CvarHookPuddle(ConVar hCvar)
{
	g_bCvarPuddle = hCvar.BoolValue;
}

void CvarHookBleeding(ConVar hCvar)
{
	g_iCvarBleeding = hCvar.IntValue;
	TIMER; else DELETETIMER;
}

void CvarHookGibs(ConVar hCvar)
{
	g_bCvarGibs = hCvar.BoolValue;
}

#define GIBS "models/gibs/hgibs.mdl"
public void OnConfigsExecuted()
{
	for(int iCount; iCount < 4; ++iCount)
		PrecacheEffect(g_sMeat[iCount]);

	g_iBlood = PrecacheDecal("decals/blood1.vtf", true);
	PrecacheModel(GIBS, true);

	CvarHookMeat(FindConVar("meat_enabled"));
}

public void OnClientPostAdminCheck(int iClient)
{
	if(g_bEvent && g_bCvarBodyLimbs) SHOOK(SDKHook, iClient);
}

void PlayerDeath(Event hEvent)
{
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));

	float fPosition[3];
	if(g_bCvarPuddle)
	{
		GetClientAbsOrigin(iClient, fPosition);
		CreateParticle(fPosition, g_sMeat[2], iClient, 10.0);
	}
	
	GetClientEyePosition(iClient, fPosition);
	if(g_bCvarHeadshot && hEvent.GetBool("headshot"))
		CreateParticle(fPosition, g_sMeat[0], iClient, 2.0);

	if(!g_bCvarGibs) return;
	char sWeapon[32]; hEvent.GetString("weapon", sWeapon, sizeof(sWeapon));
	if(StrEqual(sWeapon, "hegrenade") || StrEqual(sWeapon, "inferno"))
	{
		int iEntity = GetEntPropEnt(iClient, Prop_Send, "m_hRagdoll");
		if(iEntity != -1) AcceptEntityInput(iEntity, "Kill");
		
		if((iEntity = CreateEntityByName("prop_physics_override")) != -1)
		{
			DispatchKeyValue(iEntity, "model", GIBS);
			DispatchKeyValueVector(iEntity, "origin", fPosition);
			DispatchSpawn(iEntity);
			SetEntProp(iEntity, Prop_Data, "m_CollisionGroup", 1);
		}
	}
}

Action OnTakeDamageAlive(int iVictim, int &iAttacker, int &iInflictor, float &fDamage,
int &iDamageType,int &iWeapon, float fDamageForce[3], float fDamagePosition[3])
{
	CreateParticle(fDamagePosition, g_sMeat[1], iVictim, 2.0);
}

void TimerBleeding()
{
	float fPosition[3];
	LC(iClient)
	{
		if(!IsPlayerAlive(iClient) || GetClientHealth(iClient) > g_iCvarBleeding)
			continue;
		
		GetClientEyePosition(iClient, fPosition);
		CreateParticle(fPosition, g_sMeat[3], iClient, 2.0);

		GetClientAbsOrigin(iClient, fPosition);
		fPosition[0] += GetRandomFloat(-30.0, 30.0);
		fPosition[1] += GetRandomFloat(-30.0, 30.0);
		TE_Start("World Decal");
		TE_WriteVector("m_vecOrigin", fPosition);
		TE_WriteNum("m_nIndex", g_iBlood);
		TE_SendToAll();
	}
}