#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>

#define L4D2 Hulking Tank
#define PLUGIN_VERSION "1.11"

public Plugin myinfo = 
{
    name = "[L4D2] Hulking Tank",
    author = "Mortiegama",
    description = "Brings a set of psychotic abilities to the Hulking Tank.",
    version = PLUGIN_VERSION,
    url = "https://forums.alliedmods.net/showthread.php?p=2105537#post2105537"
}

//Special Thanks:
//Karma - Tank Skill Roar
//https://forums.alliedmods.net/showthread.php?t=126919

//panxiaohai - Tank's Burning Rock
//https://forums.alliedmods.net/showthread.php?t=139691

PluginData plugin;

enum struct PluginCvars
{
	ConVar cvarPluginOn;
	ConVar cvarBurningRage;
	ConVar cvarBurningRageFist;
	ConVar cvarBurningRageSpeed;
	ConVar cvarBurningRageDamage;
	ConVar cvarHibernation;
	ConVar cvarHibernationCooldown;
	ConVar cvarHibernationDamage;
	ConVar cvarHibernationDuration;
	ConVar cvarHibernationRegen;
	ConVar cvarPhantomTank;
	ConVar cvarPhantomTankDuration;
	ConVar cvarSmoulderingEarth;
	ConVar cvarSmoulderingEarthDamage;
	ConVar cvarSmoulderingEarthRange;
	ConVar cvarSmoulderingEarthPower;
	ConVar cvarSmoulderingEarthType;
	ConVar cvarTitanFist;
	ConVar cvarTitanFistIncap;
	ConVar cvarTitanFistCooldown;
	ConVar cvarTitanFistDamage;
	ConVar cvarTitanFistPower;
	ConVar cvarTitanFistRange;
	ConVar cvarTitanicBellow;
	ConVar cvarTitanicBellowCooldown;
	ConVar cvarTitanicBellowHealth;
	ConVar cvarTitanicBellowPower;
	ConVar cvarTitanicBellowDamage;
	ConVar cvarTitanicBellowRange;
	ConVar cvarTitanicBellowType;

	void Init()
	{
		CreateConVar("l4d_htm_version", PLUGIN_VERSION, "Hulking Tank Version", FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);

		this.cvarPluginOn = CreateConVar("l4d_htm_enable", "1", "Enable/Disable the plugin. (Def 1)", 0, true, 0.0, false, _);
		this.cvarBurningRage = CreateConVar("l4d_htm_burningrage", "1", "Enables the Burning Rage ability, Tank's movement speed increases when on fire. (Def 1)", 0, true, 0.0, false, _);
		this.cvarBurningRageFist = CreateConVar("l4d_htm_burningragefist", "1", "Enables the Burning Rage Fist ability, Tank deals extra damage when on fire. (Def 1)", 0, true, 0.0, false, _);
		this.cvarBurningRageSpeed = CreateConVar("l4d_htm_burningragespeed", "1.25", "How much of a speed boost does Burning Rage give. (Def 1.25)", 0, true, 0.0, false, _);
		this.cvarBurningRageDamage = CreateConVar("l4d_htm_burningragedamage", "3", "Amount of extra damage done to Survivors while Tank is on fire. (Def 3)", 0, true, 0.0, false, _);

		this.cvarHibernation = CreateConVar("l4d_htm_hibernation", "1", "Enables the Hibernation ability, Tank stops to hibernate and will regenerate health while taking extra damage. (Def 1)", 0, true, 0.0, false, _);
		this.cvarHibernationCooldown = CreateConVar("l4d_htm_hibernationcooldown", "120", "Amount of time before the Tank can Hibernate again. (Def 120)", 0, true, 0.0, false, _);
		this.cvarHibernationDamage = CreateConVar("l4d_htm_hibernationdamage", "2.0", "Multiplier for damage received by Tank while Hibernating. (Def 2.0)", 0, true, 0.0, false, _);
		this.cvarHibernationDuration = CreateConVar("l4d_htm_hibernationduration", "10.0", "Amount of time the Hibernation will take before completion. (Def 10.0)", 0, true, 0.0, false, _);
		this.cvarHibernationRegen = CreateConVar("l4d_htm_hibernationregen", "9000.0", "Amount of health the Tank will be set to once done Hibernating. (Def 6000.0)", 0, true, 0.0, false, _);

		this.cvarPhantomTank = CreateConVar("l4d_htm_phantomtank", "1", "Enables the Phanton Tank ability, when spawning the Tank will be immune to damage and fire until a player takes control. (Def 1)", 0, true, 0.0, false, _);
		this.cvarPhantomTankDuration = CreateConVar("l4d_htm_phantomtankduration", "3.0", "Amount of time after a player takes control of the Tank that the damage and fire immunity ends. (Def 3.0)", 0, true, 0.0, false, _);

		this.cvarSmoulderingEarth = CreateConVar("l4d_htm_SmoulderingEarth", "1", "Enables the Smouldering Earth ability, Tank is able to throw a burning rock that explodes when hitting the ground. (Def 1)", 0, true, 0.0, false, _);
		this.cvarSmoulderingEarthDamage = CreateConVar("l4d_htm_smoulderingearthdamage", "7", "Damage the exploding rock causes nearby Survivors. (Def 7)", 0, true, 0.0, false, _);
		this.cvarSmoulderingEarthRange = CreateConVar("l4d_htm_smoulderingearthrange", "300.0", "Area around the exploding rock that will reach Survivors. (Def 300.0)", 0, true, 0.0, false, _);
		this.cvarSmoulderingEarthPower = CreateConVar("l4d_htm_smoulderingearthpower", "200.0", "Amount of power behind the explosion. (Def 200.0)", 0, true, 0.0, false, _);
		this.cvarSmoulderingEarthType = CreateConVar("l4d_htm_smoulderingearthtype", "2", "Type of rock thrown, 1 = Rock is always on fire, 2 = Rock only on fire if Tank is on fire.", 0, true, 1.0, true, 2.0);

		this.cvarTitanFist = CreateConVar("l4d_htm_titanfist", "1", "Enables the Titan Fist ability, Tank is able to send out shockwaves through the air with its fist. (Def 1)", 0, true, 0.0, false, _);
		this.cvarTitanFistIncap = CreateConVar("l4d_htm_titanfistincap", "1", "Enables the Titan Fist Incap ability, if a Survivor is incapped by the Tank punch they will still be flung. (Def 1)", 0, true, 0.0, false, _);
		this.cvarTitanFistCooldown = CreateConVar("l4d_htm_titanfistcooldown", "15", "Amount of time before the Tank can send another Titan Fist shockwave. (Def 15)", 0, true, 0.0, false, _);
		this.cvarTitanFistDamage = CreateConVar("l4d_htm_titanfistdamage", "5", "Amount of damage done to Survivors hit by the Titan Fist shockwave. (Def 5)", 0, true, 0.0, false, _);
		this.cvarTitanFistPower = CreateConVar("l4d_htm_titanfistpower", "200.0", "Force behind the Titan Fist shockwave. (Def 200.0)", 0, true, 0.0, false, _);
		this.cvarTitanFistRange = CreateConVar("l4d_htm_titanfistrange", "700.0", "Distance the Titan Fist shockwave will travel. (Def 700.0)", 0, true, 0.0, false, _);

		this.cvarTitanicBellow = CreateConVar("l4d_htm_titanicbellow", "1", "Enables the Titanic Bellow ability, Tank is able to roar and send nearby Survivors flying or pull them to the Tank. (Def 1)", 0, true, 0.0, false, _);
		this.cvarTitanicBellowCooldown = CreateConVar("l4d_htm_titanicbellowcooldown", "5.0", "Amount of time between Titanic Bellows. (Def 5.0)", 0, true, 0.0, false, _);
		this.cvarTitanicBellowHealth = CreateConVar("l4d_htm_titanicbellowhealth", "0", "Amount of health the Tank must be at (or below) to use Titanic Belllow (0 = disabled). (Def 0)", 0, true, 0.0, false, _);
		this.cvarTitanicBellowPower = CreateConVar("l4d_htm_titanicbellowpower", "300.0", "Power behind the inner range of Methane Blast. (Def 300.0)", 0, true, 0.0, false, _);
		this.cvarTitanicBellowDamage = CreateConVar("l4d_htm_titanicbellowdamage", "10", "Damage the force of the roar causes to nearby survivors. (Def 10)", 0, true, 0.0, false, _);
		this.cvarTitanicBellowRange = CreateConVar("l4d_htm_titanicbellowrange", "700.0", "Area around the Tank the bellow will reach. (Def 700.0)", 0, true, 0.0, false, _);
		this.cvarTitanicBellowType = CreateConVar("l4d_htm_titanicbellowtype", "1", "Type of roar, 1 = Survivors are pushed away from Tank, 2 = Survivors are pulled towards Tank.", 0, true, 1.0, true, 2.0);

		AutoExecConfig(true, "plugin.L4D2.HulkingTank");
		
		this.cvarPluginOn.AddChangeHook(OnConVarPluginOnChange);
		this.cvarBurningRage.AddChangeHook(ConVarChanged_Cvars);
		this.cvarBurningRageFist.AddChangeHook(ConVarChanged_Cvars);
		this.cvarBurningRageSpeed.AddChangeHook(ConVarChanged_Cvars);
		this.cvarBurningRageDamage.AddChangeHook(ConVarChanged_Cvars);

		this.cvarHibernation.AddChangeHook(ConVarChanged_Cvars);
		this.cvarHibernationCooldown.AddChangeHook(ConVarChanged_Cvars);
		this.cvarHibernationDamage.AddChangeHook(ConVarChanged_Cvars);
		this.cvarHibernationDuration.AddChangeHook(ConVarChanged_Cvars);
		this.cvarHibernationRegen.AddChangeHook(ConVarChanged_Cvars);

		this.cvarPhantomTank.AddChangeHook(ConVarChanged_Cvars);
		this.cvarPhantomTankDuration.AddChangeHook(ConVarChanged_Cvars);

		this.cvarSmoulderingEarth.AddChangeHook(ConVarChanged_Cvars);
		this.cvarSmoulderingEarthDamage.AddChangeHook(ConVarChanged_Cvars);
		this.cvarSmoulderingEarthRange.AddChangeHook(ConVarChanged_Cvars);
		this.cvarSmoulderingEarthPower.AddChangeHook(ConVarChanged_Cvars);
		this.cvarSmoulderingEarthType.AddChangeHook(ConVarChanged_Cvars);

		this.cvarTitanFist.AddChangeHook(ConVarChanged_Cvars);
		this.cvarTitanFistIncap.AddChangeHook(ConVarChanged_Cvars);
		this.cvarTitanFistCooldown.AddChangeHook(ConVarChanged_Cvars);
		this.cvarTitanFistDamage.AddChangeHook(ConVarChanged_Cvars);
		this.cvarTitanFistPower.AddChangeHook(ConVarChanged_Cvars);
		this.cvarTitanFistRange.AddChangeHook(ConVarChanged_Cvars);

		this.cvarTitanicBellow.AddChangeHook(ConVarChanged_Cvars);
		this.cvarTitanicBellowCooldown.AddChangeHook(ConVarChanged_Cvars);
		this.cvarTitanicBellowHealth.AddChangeHook(ConVarChanged_Cvars);
		this.cvarTitanicBellowPower.AddChangeHook(ConVarChanged_Cvars);
		this.cvarTitanicBellowDamage.AddChangeHook(ConVarChanged_Cvars);
		this.cvarTitanicBellowRange.AddChangeHook(ConVarChanged_Cvars);
		this.cvarTitanicBellowType.AddChangeHook(ConVarChanged_Cvars);
	}
}

enum struct PluginData
{
	PluginCvars cvars;
	bool bHooked;
	bool bPluginOn;
	bool bBurningRage;
	bool bBurningRageFist;
	float fBurningRageSpeed;
	float fBurningRageDamage;
	int laggedMovementOffset;
	int frustrationOffset;
	bool bHibernation;
	float fHibernationCooldown;
	float fHibernationDamage;
	float fHibernationDuration;
	int iHibernationRegen;
	bool bPhantomTank;
	float fPhantomTankDuration;
	bool bSmoulderingEarth;
	int iSmoulderingEarthDamage;
	float fSmoulderingEarthRange;
	int iSmoulderingEarthRange;
	int iSmoulderingEarthPower;
	float fSmoulderingEarthPower;
	int iSmoulderingEarthType;
	bool bTitanFist;
	bool bTitanFistIncap;
	float fTitanFistCooldown;
	int iTitanFistDamage;
	float fTitanFistPower;
	int iTitanFistPower;
	float fTitanFistRange;
	int iTitanFistRange;
	bool bTitanicBellow;
	float fTitanicBellowCooldown;
	int iTitanicBellowHealth;
	float fTitanicBellowPower;
	int iTitanicBellowPower;
	int iTitanicBellowDamage;
	int iTitanicBellowRange;
	int iTitanicBellowType;
	float cooldownTitanFist[MAXPLAYERS + 1];
	float cooldownTitanicBellow[MAXPLAYERS + 1];
	bool isMapRunning;
	bool buttondelay[MAXPLAYERS + 1];
	bool isHibernationCooldown[MAXPLAYERS + 1];
	bool isHibernating[MAXPLAYERS + 1];
	bool isFrustrated;
	Handle cvarResetDelayTimer[MAXPLAYERS + 1];
	Handle cvarPhantomTankTimer;
	Handle cvarPhantomTankTimerAI;
	Handle cvarHibernationTimer[MAXPLAYERS + 1];
	Handle cvarHibernationCooldownTimer[MAXPLAYERS + 1];
	int aiTank;

	void Init()
	{
		this.cvars.Init();
		this.laggedMovementOffset = FindSendPropInfo("CTerrorPlayer", "m_flLaggedMovementValue");
		this.frustrationOffset = FindSendPropInfo("Tank","m_frustration");
	}

	void GetCvarValues()
	{
		this.bBurningRage = this.cvars.cvarBurningRage.BoolValue;
		this.bBurningRageFist = this.cvars.cvarBurningRageFist.BoolValue;
		this.fBurningRageSpeed = this.cvars.cvarBurningRageSpeed.FloatValue;
		this.fBurningRageDamage = this.cvars.cvarBurningRageDamage.FloatValue;

		this.bHibernation = this.cvars.cvarHibernation.BoolValue;
		this.fHibernationCooldown = this.cvars.cvarHibernationCooldown.FloatValue;
		this.fHibernationDamage = this.cvars.cvarHibernationDamage.FloatValue;
		this.fHibernationDuration = this.cvars.cvarHibernationDuration.FloatValue;
		this.iHibernationRegen = this.cvars.cvarHibernationRegen.IntValue;

		this.bPhantomTank = this.cvars.cvarPhantomTank.BoolValue;
		this.fPhantomTankDuration = this.cvars.cvarPhantomTankDuration.FloatValue;

		this.bSmoulderingEarth = this.cvars.cvarSmoulderingEarth.BoolValue;
		this.iSmoulderingEarthDamage = this.cvars.cvarSmoulderingEarthDamage.IntValue;
		this.fSmoulderingEarthRange = this.cvars.cvarSmoulderingEarthRange.FloatValue;
		this.iSmoulderingEarthRange = this.cvars.cvarSmoulderingEarthRange.IntValue;
		this.iSmoulderingEarthPower = this.cvars.cvarSmoulderingEarthPower.IntValue;
		this.fSmoulderingEarthPower = this.cvars.cvarSmoulderingEarthPower.FloatValue;
		this.iSmoulderingEarthType = this.cvars.cvarSmoulderingEarthType.IntValue;

		this.bTitanFist = this.cvars.cvarTitanFist.BoolValue;
		this.bTitanFistIncap = this.cvars.cvarTitanFistIncap.BoolValue;
		this.fTitanFistCooldown = this.cvars.cvarTitanFistCooldown.FloatValue;
		this.iTitanFistDamage = this.cvars.cvarTitanFistDamage.IntValue;
		this.fTitanFistPower = this.cvars.cvarTitanFistPower.FloatValue;
		this.iTitanFistPower = this.cvars.cvarTitanFistPower.IntValue;
		this.fTitanFistRange = this.cvars.cvarTitanFistRange.FloatValue;
		this.iTitanFistRange = this.cvars.cvarTitanFistRange.IntValue;

		this.bTitanicBellow = this.cvars.cvarTitanicBellow.BoolValue;
		this.fTitanicBellowCooldown = this.cvars.cvarTitanicBellowCooldown.FloatValue;
		this.iTitanicBellowHealth = this.cvars.cvarTitanicBellowHealth.IntValue;
		this.fTitanicBellowPower = this.cvars.cvarTitanicBellowPower.FloatValue;
		this.iTitanicBellowPower = this.cvars.cvarTitanicBellowPower.IntValue;
		this.iTitanicBellowDamage = this.cvars.cvarTitanicBellowDamage.IntValue;
		this.iTitanicBellowRange = this.cvars.cvarTitanicBellowRange.IntValue;
		this.iTitanicBellowType = this.cvars.cvarTitanicBellowType.IntValue;
	}

	void IsAllowed()
	{
		this.bPluginOn = this.cvars.cvarPluginOn.BoolValue;
		if(!this.bHooked && this.bPluginOn)
		{
			this.bHooked = true;
			HookEvent("player_incapacitated", Event_PlayerIncap);
			HookEvent("tank_frustrated", Event_TankFrustrated, EventHookMode_Pre);
		}
		else if(this.bHooked && !this.bPluginOn)
		{
			this.bHooked = false;
			UnhookEvent("player_incapacitated", Event_PlayerIncap);
			UnhookEvent("tank_frustrated", Event_TankFrustrated, EventHookMode_Pre);
		}
	}
}

public void OnPluginStart()
{	
	plugin.Init();
}

public void OnConfigsExecuted()
{
	plugin.IsAllowed();
	plugin.GetCvarValues();
}

void OnConVarPluginOnChange(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	plugin.IsAllowed();
}

void ConVarChanged_Cvars(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	plugin.GetCvarValues();
}

public void OnMapStart()
{
	PrecacheParticle("gas_explosion_pump");
	plugin.isMapRunning = true;
}

public void OnClientPostAdminCheck(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public void L4D_OnSpawnTank_Post(int tank, const float vecPos[3], const float vecAng[3])
{
	if (plugin.bPhantomTank && IsValidAliveInf(tank))
	{
		if (IsFakeClient(tank) && !plugin.isFrustrated)
		{
			SetEntityMoveType(tank, MOVETYPE_NONE);
			SetEntProp(tank, Prop_Data, "m_fFlags", GetEntProp(tank, Prop_Data, "m_fFlags") | FL_GODMODE);
			SetEntityRenderMode(tank, RENDER_TRANSCOLOR);
			SetEntityRenderColor(tank, 255, 255, 255, 0);
			plugin.cvarPhantomTankTimerAI = CreateTimer(6.0, Timer_PhantomTankAI);
			plugin.aiTank = tank;
		}

		if (!IsFakeClient(tank) && !plugin.isFrustrated)
		{
			SetEntityMoveType(tank, MOVETYPE_WALK);
			SetEntProp(tank, Prop_Data, "m_fFlags", GetEntProp(tank, Prop_Data, "m_fFlags") | FL_GODMODE);
			plugin.cvarPhantomTankTimer = CreateTimer(plugin.fPhantomTankDuration, Timer_PhantomTank);
			plugin.aiTank = 0;
		}
	}
	plugin.isFrustrated = false;
}

Action Event_TankFrustrated(Event event, const char[] name, bool dontBroadcast)
{
	plugin.isFrustrated = true;
	return Plugin_Continue;
}

Action Timer_PhantomTank(Handle timer) //extinguishes  a tank, and resets it's health
{
	PhantomTankRemoval();
	if (plugin.cvarPhantomTankTimer != null)
	{
		plugin.cvarPhantomTankTimer = null;
	}
	return Plugin_Stop;
}

Action Timer_PhantomTankAI(Handle timer) //Thaws an AI tank, it will only fire after 5 seconds which means it was not passed to a player.  Either because of no player infected, or being passed to AI
{
	if (!plugin.aiTank || !IsValidTank(plugin.aiTank) || !IsFakeClient(plugin.aiTank))
	{
		plugin.aiTank = 0;
		return Plugin_Stop;
	}

	PhantomTankRemoval();
	plugin.aiTank = 0;

	if (IsValidTank(plugin.aiTank))
	{
		SetEntityMoveType(plugin.aiTank, MOVETYPE_WALK);
	}

	if (plugin.cvarPhantomTankTimerAI != null)
	{
		plugin.cvarPhantomTankTimerAI = null;
	}	
	
	return Plugin_Stop;
}

static void PhantomTankRemoval()
{
	for (int tank = 1; tank <= MaxClients; tank++)
	{
		if (IsValidTank(tank))
		{
			SetEntityMoveType(plugin.aiTank, MOVETYPE_WALK);
			SetEntProp(tank, Prop_Data, "m_fFlags", GetEntProp(tank, Prop_Data, "m_fFlags") & ~FL_GODMODE);
			SetEntityRenderColor(tank, 255, 255, 255, 255);
			ExtinguishEntity(tank);
		}
	}
}

// ===========================================
// Tank Ability - Burning Rage
// ===========================================
// Description: When on fire the Tank can move faster and hit harder.

Action OnTakeDamage(int victim, int  &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (IsValidTank(victim))
	{
		if (plugin.bBurningRage)
		{
			if ((damagetype == 8 || damagetype == 2056 || damagetype == 268435464))
			{
				SDKUnhook(victim, SDKHook_OnTakeDamage, OnTakeDamage);
				PrintHintText(victim, "You're on fire, your Burning Rage has increased your speed!");
				SetEntDataFloat(victim, plugin.laggedMovementOffset, plugin.fBurningRageSpeed, true);
				return Plugin_Handled;
			}
		}

		if (plugin.isHibernating[victim])
		{
			if (FloatCompare(plugin.fHibernationDamage, 1.0) != 0)
			{
				damage = damage * plugin.fHibernationDamage;
			}
		}
	}

	if (plugin.bBurningRageFist && IsValidTank(attacker))
	{
		if (L4D_IsPlayerOnFire(attacker) && IsValidAliveSurv(victim))
		{
			if (FloatCompare(plugin.fBurningRageDamage, 1.0) != 0)
			{
				damage = damage + plugin.fBurningRageDamage;
			}
		}
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

Action Timer_Hibernation(Handle timer, int client)
{
	if(IsValidAliveClient(client))
	{
		Reset_Hibernation(client);
	}

	if (IsValidTank(client))
	{
		SetEntProp(client, Prop_Send, "m_iHealth", plugin.iHibernationRegen, 1);
	}

	if (plugin.cvarHibernationTimer[client] != null)
	{
		plugin.cvarHibernationTimer[client] = null;
	}

	return Plugin_Stop;
}

Action Timer_HibernationCooldown(Handle timer, int client)
{
	plugin.isHibernationCooldown[client] = false;
	if(plugin.cvarHibernationCooldownTimer[client] != null)
	{
		plugin.cvarHibernationCooldownTimer[client] = null;
	}
	return Plugin_Stop;	
}

void Reset_Hibernation(int client)
{
	if(IsValidAliveClient(client))
	{
		KillProgressBar(client);
		SetEntityMoveType(client, MOVETYPE_WALK);
		SetEntData(client, plugin.frustrationOffset, 1);
		plugin.isHibernating[client] = false;
	}
}

stock void SetupProgressBar(int client, float time)
{
	if(IsValidAliveClient(client))
	{
		SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
		SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", time);
	}
}

stock void KillProgressBar(int client)
{
	if(IsValidAliveClient(client))
	{
		SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
		SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", 0.0);
	}
}
				
// ===========================================
// Tank Ability - Titan Fist
// ===========================================
// Description: The Tank's swing will also hit int Survivors in range.

void Event_PlayerIncap(Event event, char[] event_name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("userid"));
	int client = GetClientOfUserId(event.GetInt("attacker"));

	char weapon[16];
	event.GetString("weapon", weapon, 16);
	if(!StrEqual(weapon, "tank_claw")) return;

	if(plugin.bTitanFistIncap && IsValidAliveClient(client))
	{
		if (IsValidAliveSurv(victim) && !L4D_IsPlayerPinned(victim))
		{
			float tankPos[3];
			float survivorPos[3];
			GetClientEyePosition(client, tankPos);
			GetClientEyePosition(victim, survivorPos);

			char sRadius[256], sPower[256];
			IntToString(plugin.iTitanFistRange, sRadius, sizeof(sRadius));
			IntToString(plugin.iTitanFistPower, sPower, sizeof(sPower));
			int exPhys = CreateEntityByName("env_physexplosion");

			//Set up physics movement explosion
			DispatchKeyValue(exPhys, "radius", sRadius);
			DispatchKeyValue(exPhys, "magnitude", sPower);
			DispatchSpawn(exPhys);
			TeleportEntity(exPhys, tankPos, NULL_VECTOR, NULL_VECTOR);
					
			//BOOM!
			AcceptEntityInput(exPhys, "Explode");

			float traceVec[3], ResultingVec[3], CurrentVelVec[3];
			MakeVectorFromPoints(tankPos, survivorPos, traceVec);				// draw a line from car to Survivor
			GetVectorAngles(traceVec, ResultingVec);							// get the angles of that line

			ResultingVec[0] = Cosine(DegToRad(ResultingVec[1])) * plugin.fTitanFistPower;	// use trigonometric magic
			ResultingVec[1] = Sine(DegToRad(ResultingVec[1])) * plugin.fTitanFistPower;
			ResultingVec[2] = plugin.fTitanFistPower * 1.5;

			GetEntPropVector(victim, Prop_Data, "m_vecVelocity", CurrentVelVec);		// add whatever the Survivor had before
			ResultingVec[0] += CurrentVelVec[0];
			ResultingVec[1] += CurrentVelVec[1];
			ResultingVec[2] += CurrentVelVec[2];

			L4D2_CTerrorPlayer_Fling(victim, client, ResultingVec);
			Damage_TitanFist(client, victim);
		}
	}
}

void Damage_TitanFist(int attacker, int victim)
{
	float victimPos[3];
	char StrDamage[16], StrDamageTarget[16];
			
	GetClientEyePosition(victim, victimPos);
	IntToString(plugin.iTitanFistDamage, StrDamage, sizeof(StrDamage));
	Format(StrDamageTarget, sizeof(StrDamageTarget), "hurtme%d", victim);
	
	int entPointHurt = CreateEntityByName("point_hurt");
	if(!entPointHurt) return;

	// Config, create point_hurt
	DispatchKeyValue(victim, "targetname", StrDamageTarget);
	DispatchKeyValue(entPointHurt, "DamageTarget", StrDamageTarget);
	DispatchKeyValue(entPointHurt, "Damage", StrDamage);
	DispatchKeyValue(entPointHurt, "DamageType", "0"); // DMG_GENERIC
	DispatchSpawn(entPointHurt);
	
	// Teleport, activate point_hurt
	TeleportEntity(entPointHurt, victimPos, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(entPointHurt, "Hurt", (attacker && attacker < MaxClients && IsClientInGame(attacker)) ? attacker : -1);
	
	// Config, delete point_hurt
	DispatchKeyValue(entPointHurt, "classname", "point_hurt");
	DispatchKeyValue(victim, "targetname", "null");
	RemoveEdict(entPointHurt);
	
	PrintHintText(attacker, "Your Titan Claw inflicted %i damage.", plugin.iTitanFistDamage);
	PrintHintText(victim, "You were hit with Titan Claw, causing %i damage and sending you flying.", plugin.iTitanFistDamage);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if(buttons & IN_ATTACK && IsValidTank(client))
	{
		if (plugin.bTitanFist && IsTitanFistReady(client) && !plugin.isHibernating[client])
		{
			plugin.cooldownTitanFist[client] = GetEngineTime();
			for (int victim = 1; victim <= MaxClients; victim++)
			{
				if (IsValidAliveSurv(victim) && !L4D_IsPlayerPinned(victim))
				{
					float tankPos[3], survivorPos[3], distance;
					GetClientEyePosition(client, tankPos);
					GetClientEyePosition(victim, survivorPos);
					distance = GetVectorDistance(survivorPos, tankPos);

					if (distance < plugin.fTitanFistRange)
					{
						char sRadius[256], sPower[256];
						IntToString(plugin.iTitanFistRange, sRadius, sizeof(sRadius));
						IntToString(plugin.iTitanFistPower, sPower, sizeof(sPower));
						int exPhys = CreateEntityByName("env_physexplosion");

						//Set up physics movement explosion
						DispatchKeyValue(exPhys, "radius", sRadius);
						DispatchKeyValue(exPhys, "magnitude", sPower);
						DispatchSpawn(exPhys);
						TeleportEntity(exPhys, tankPos, NULL_VECTOR, NULL_VECTOR);

						//BOOM!
						AcceptEntityInput(exPhys, "Explode");

						float traceVec[3], ResultingVec[3], CurrentVelVec[3];
						MakeVectorFromPoints(tankPos, survivorPos, traceVec);				// draw a line from car to Survivor
						GetVectorAngles(traceVec, ResultingVec);							// get the angles of that line

						ResultingVec[0] = Cosine(DegToRad(ResultingVec[1])) * plugin.fTitanFistPower;	// use trigonometric magic
						ResultingVec[1] = Sine(DegToRad(ResultingVec[1])) * plugin.fTitanFistPower;
						ResultingVec[2] = plugin.fTitanFistPower * 1.5;

						GetEntPropVector(victim, Prop_Data, "m_vecVelocity", CurrentVelVec);		// add whatever the Survivor had before
						ResultingVec[0] += CurrentVelVec[0];
						ResultingVec[1] += CurrentVelVec[1];
						ResultingVec[2] += CurrentVelVec[2];

						L4D2_CTerrorPlayer_Fling(victim, client, ResultingVec);
						Damage_TitanFist(client, victim);
					}
				}
			}
		}

		if (plugin.isHibernating[client])
		{
			buttons &= ~IN_ATTACK;
		}
	}

	if(buttons & IN_ATTACK2 && IsValidTank(client) && plugin.isHibernating[client])
	{
		buttons &= ~IN_ATTACK2;
	}

	if (buttons & IN_ATTACK2 && plugin.aiTank && client == plugin.aiTank && IsFakeClient(plugin.aiTank) && IsValidTank(plugin.aiTank))
	{
		buttons &= ~IN_ATTACK2;
	}

	if ((buttons & IN_ZOOM) && IsValidTank(client) && !plugin.isHibernating[client]) 
	{
		if (plugin.bTitanicBellow && IsTitanicBellowReady(client) && !plugin.isHibernating[client])
		{
			int HP = GetClientHealth(client);

			if (plugin.iTitanicBellowHealth > 0 && HP > plugin.iTitanicBellowHealth)
			{
				PrintHintText(client, "Your health must be below %i before you can use Titanic Bellow.", plugin.iTitanicBellowHealth);
				return Plugin_Continue;
			}

			plugin.cooldownTitanicBellow[client] = GetEngineTime();			
			for (int victim = 1; victim <= MaxClients; victim++)
			{
				if (IsValidAliveSurv(victim) && !L4D_IsPlayerPinned(victim))
				{
					float tankPos[3], survivorPos[3], distance;
					GetClientEyePosition(client, tankPos);
					GetClientEyePosition(victim, survivorPos);
					distance = GetVectorDistance(survivorPos, tankPos);

					if (distance < plugin.iTitanicBellowRange)
					{
						char sRadius[256], sPower[256];
						int magnitude = 0;
						if (plugin.iTitanicBellowType == 1) magnitude = plugin.iTitanicBellowPower;
						if (plugin.iTitanicBellowType == 2) magnitude = plugin.iTitanicBellowPower * -1;
						IntToString(plugin.iTitanicBellowRange, sRadius, sizeof(sRadius));
						IntToString(magnitude, sPower, sizeof(sPower));
						int exPhys = CreateEntityByName("env_physexplosion");

						//Set up physics movement explosion
						DispatchKeyValue(exPhys, "radius", sRadius);
						DispatchKeyValue(exPhys, "magnitude", sPower);
						DispatchSpawn(exPhys);
						TeleportEntity(exPhys, tankPos, NULL_VECTOR, NULL_VECTOR);
						
						//BOOM!
						AcceptEntityInput(exPhys, "Explode");
		
						float traceVec[3], ResultingVec[3], CurrentVelVec[3];
						MakeVectorFromPoints(tankPos, survivorPos, traceVec);				// draw a line from car to Survivor
						GetVectorAngles(traceVec, ResultingVec);							// get the angles of that line

						ResultingVec[0] = Cosine(DegToRad(ResultingVec[1])) * plugin.fTitanicBellowPower;	// use trigonometric magic
						ResultingVec[1] = Sine(DegToRad(ResultingVec[1])) * plugin.fTitanicBellowPower;
						ResultingVec[2] = plugin.fTitanicBellowPower * 1.5;

						GetEntPropVector(victim, Prop_Data, "m_vecVelocity", CurrentVelVec);		// add whatever the Survivor had before
						ResultingVec[0] += CurrentVelVec[0];
						ResultingVec[1] += CurrentVelVec[1];
						ResultingVec[2] += CurrentVelVec[2];
						
						if (plugin.iTitanicBellowType == 2)
						{
							ResultingVec[0] = ResultingVec[0] * -1;
							ResultingVec[1] = ResultingVec[1] * -1;
						}

						L4D2_CTerrorPlayer_Fling(victim, client, ResultingVec);
						Damage_TitanicBellow(client, victim);
					}
				}
			}
		}
	}
	
	if(buttons & IN_USE && plugin.bHibernation)
	{
		if (IsValidTank(client) && !plugin.isHibernating[client] && !plugin.buttondelay[client] && !plugin.isHibernationCooldown[client])
		{
			plugin.isHibernating[client] = true;
			plugin.isHibernationCooldown[client] = true;
			plugin.buttondelay[client] = true;

			SetEntityMoveType(client, MOVETYPE_NONE);
			SetEntData(client, plugin.frustrationOffset, 0);
			SetupProgressBar(client, plugin.fHibernationDuration);
					
			plugin.cvarHibernationCooldownTimer[client] = CreateTimer(plugin.fHibernationCooldown, Timer_HibernationCooldown, client);
			plugin.cvarHibernationTimer[client] = CreateTimer(plugin.fHibernationDuration, Timer_Hibernation, client);
			plugin.cvarResetDelayTimer[client] = CreateTimer(1.0, ResetDelay, client);
			
			PrintHintText(client, "You are Hibernating.");
		}
		
		if (IsValidTank(client) && plugin.isHibernating[client] && !plugin.buttondelay[client])
		{
			Reset_Hibernation(client);
			plugin.buttondelay[client] = true;
			plugin.cvarResetDelayTimer[client] = CreateTimer(1.0, ResetDelay, client);
		}
	}
	return Plugin_Continue;
}

Action ResetDelay(Handle timer, int client)
{
	plugin.buttondelay[client] = false;
	if (plugin.cvarResetDelayTimer[client] != null)
	{
		plugin.cvarResetDelayTimer[client] = null;
	}
	return Plugin_Stop;
}

void Damage_TitanicBellow(int client, int victim)
{
	float victimPos[3];
	char StrDamage[16], StrDamageTarget[16];

	GetClientEyePosition(victim, victimPos);
	IntToString(plugin.iTitanicBellowDamage, StrDamage, sizeof(StrDamage));
	Format(StrDamageTarget, sizeof(StrDamageTarget), "hurtme%d", victim);

	int entPointHurt = CreateEntityByName("point_hurt");
	if(!entPointHurt) return;

	// Config, create point_hurt
	DispatchKeyValue(victim, "targetname", StrDamageTarget);
	DispatchKeyValue(entPointHurt, "DamageTarget", StrDamageTarget);
	DispatchKeyValue(entPointHurt, "Damage", StrDamage);
	DispatchKeyValue(entPointHurt, "DamageType", "0"); // DMG_GENERIC
	DispatchSpawn(entPointHurt);

	// Teleport, activate point_hurt
	TeleportEntity(entPointHurt, victimPos, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(entPointHurt, "Hurt", (client && client < MaxClients && IsClientInGame(client)) ? client : -1);

	// Config, delete point_hurt
	DispatchKeyValue(entPointHurt, "classname", "point_hurt");
	DispatchKeyValue(victim, "targetname", "null");
	RemoveEdict(entPointHurt);
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if(plugin.bSmoulderingEarth && StrEqual(classname, "tank_rock", true))
	{
		if(IsValidEntity(entity) && IsValidEdict(entity))
		{
			switch(plugin.iSmoulderingEarthType)
			{
				case 1:
				{
					IgniteEntity(entity, 100.0);
				}
				case 2:
				{
					int tank = GetEntPropEnt(entity, Prop_Data, "m_hThrower");
					if (IsValidTank(tank) && L4D_IsPlayerOnFire(tank))
					{
						IgniteEntity(entity, 100.0);
					}
				}
			}
		}
	}
}

public void OnEntityDestroyed(int entity)
{	
	if(plugin.bSmoulderingEarth && plugin.isMapRunning)
	{	
		if(IsValidEntity(entity) && IsValidEdict(entity) && L4D_IsPlayerOnFire(entity))
		{
			char classname[24];
			GetEdictClassname(entity, classname, 24);

			if (StrEqual(classname, "tank_rock", false) == true)
			{
				float entityPos[3];
				GetEntPropVector(entity, Prop_Send, "m_vecOrigin", entityPos);
				ShowParticle(entityPos, "gas_explosion_pump", 3.0);
				//PrintToChatAll("Entity Position: %f.", entityPos);

				int tank = GetEntPropEnt(entity, Prop_Data, "m_hThrower");
				if (IsValidTank(tank))
				{
					for (int victim = 1; victim <= MaxClients; victim++)
			
					if (IsValidAliveSurv(victim))
					{
						float victimPos[3], distance = 0.0;
						GetClientEyePosition(victim, victimPos);
						distance = GetVectorDistance(entityPos, victimPos);
						//PrintToChatAll("Distance: %f attacker: %n", distance, victim);

						if (distance <= plugin.fSmoulderingEarthRange)
						{
							char sRadius[256], sPower[256];
							IntToString(plugin.iSmoulderingEarthRange, sRadius, sizeof(sRadius));
							IntToString(plugin.iSmoulderingEarthPower, sPower, sizeof(sPower));
							int exPhys = CreateEntityByName("env_physexplosion");

							//Set up physics movement explosion
							DispatchKeyValue(exPhys, "radius", sRadius);
							DispatchKeyValue(exPhys, "magnitude", sPower);
							DispatchSpawn(exPhys);
							TeleportEntity(exPhys, entityPos, NULL_VECTOR, NULL_VECTOR);
							
							//BOOM!
							AcceptEntityInput(exPhys, "Explode");
			
							float traceVec[3], resultingVec[3], currentVelVec[3];
							MakeVectorFromPoints(entityPos, victimPos, traceVec);				// draw a line from car to Survivor
							GetVectorAngles(traceVec, resultingVec);							// get the angles of that line

							resultingVec[0] = Cosine(DegToRad(resultingVec[1])) * plugin.fSmoulderingEarthPower;	// use trigonometric magic
							resultingVec[1] = Sine(DegToRad(resultingVec[1])) * plugin.fSmoulderingEarthPower;
							resultingVec[2] = plugin.fSmoulderingEarthPower * 1.5;

							GetEntPropVector(victim, Prop_Data, "m_vecVelocity", currentVelVec);		// add whatever the Survivor had before
							resultingVec[0] += currentVelVec[0];
							resultingVec[1] += currentVelVec[1];
							resultingVec[2] += currentVelVec[2];

							L4D2_CTerrorPlayer_Fling(victim, tank, resultingVec);
							Damage_SmoulderingEarth(tank, victim);
						}
					}
				}
			}
		}
	}
}

void Damage_SmoulderingEarth(int attacker, int victim)
{
	float victimPos[3];
	char strDamage[16], strDamageTarget[16];

	GetClientEyePosition(victim, victimPos);
	IntToString(plugin.iSmoulderingEarthDamage, strDamage, sizeof(strDamage));
	Format(strDamageTarget, sizeof(strDamageTarget), "hurtme%d", victim);
	
	int entPointHurt = CreateEntityByName("point_hurt");
	if(!entPointHurt) return;

	// Config, create point_hurt
	DispatchKeyValue(victim, "targetname", strDamageTarget);
	DispatchKeyValue(entPointHurt, "DamageTarget", strDamageTarget);
	DispatchKeyValue(entPointHurt, "Damage", strDamage);
	DispatchKeyValue(entPointHurt, "DamageType", "0"); // DMG_GENERIC
	DispatchSpawn(entPointHurt);
	
	// Teleport, activate point_hurt
	TeleportEntity(entPointHurt, victimPos, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(entPointHurt, "Hurt", (attacker && attacker < MaxClients && IsClientInGame(attacker)) ? attacker : -1);
	
	// Config, delete point_hurt
	DispatchKeyValue(entPointHurt, "classname", "point_hurt");
	DispatchKeyValue(victim, "targetname", "null");
	RemoveEdict(entPointHurt);
}

// ----------------------------------------------------------------------------
// ClientViews()
// ----------------------------------------------------------------------------
stock bool ClientViews(int Viewer, int Target, float fMaxDistance = 0.0, float fThreshold = 0.73)
{
	// Retrieve view and target eyes position
	float fViewPos[3];   GetClientEyePosition(Viewer, fViewPos);
	float fViewAng[3];   GetClientEyeAngles(Viewer, fViewAng);
	float fViewDir[3];
	float fTargetPos[3]; GetClientEyePosition(Target, fTargetPos);
	float fTargetDir[3];
	float fDistance[3];
	float fMinDistance = 100.0;

	// Calculate view direction
	fViewAng[0] = fViewAng[2] = 0.0;
	GetAngleVectors(fViewAng, fViewDir, NULL_VECTOR, NULL_VECTOR);
	
	// Calculate distance to viewer to see if it can be seen.
	fDistance[0] = fTargetPos[0] - fViewPos[0];
	fDistance[1] = fTargetPos[1] - fViewPos[1];
	fDistance[2] = 0.0;

	if (fMaxDistance != 0.0)
	{
		if (((fDistance[0] * fDistance[0]) + (fDistance[1] * fDistance[1])) >= (fMaxDistance * fMaxDistance))
			return false;
	}

	if (fMinDistance != -0.0)
	{
		if (((fDistance[0] * fDistance[0]) + (fDistance[1] * fDistance[1])) < (fMinDistance * fMinDistance))
			return false;
	}

	// Check dot product. If it's negative, that means the viewer is facing
	// backwards to the target.
	NormalizeVector(fDistance, fTargetDir);
	if (GetVectorDotProduct(fViewDir, fTargetDir) < fThreshold) return false;

	// Now check if there are no obstacles in between through raycasting
	Handle hTrace = TR_TraceRayFilterEx(fViewPos, fTargetPos, MASK_PLAYERSOLID_BRUSHONLY, RayType_EndPoint, ClientViewsFilter);
	if (TR_DidHit(hTrace))
	{
		delete hTrace;
		return false;
	}

	delete hTrace;

	// Done, it's visible
	return true;
}

// ----------------------------------------------------------------------------
// ClientViewsFilter()
// ----------------------------------------------------------------------------
stock bool ClientViewsFilter(int Entity, int Mask, int Junk)
{
	return !(Entity >= 1 && Entity <= MaxClients);
}
		
void ShowParticle(float victimPos[3], char[] particlename, float time)
{
	int particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle))
	{
		TeleportEntity(particle, victimPos, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(particle, "effect_name", particlename);
		DispatchKeyValue(particle, "targetname", "particle");
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(time, DeleteParticles, particle, TIMER_FLAG_NO_MAPCHANGE);
	} 
}
 
void PrecacheParticle(char[] particlename)
{
	int particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle))
	{
		DispatchKeyValue(particle, "effect_name", particlename);
		DispatchKeyValue(particle, "targetname", "particle");
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(0.01, DeleteParticles, particle, TIMER_FLAG_NO_MAPCHANGE);
	}
}

Action DeleteParticles(Handle timer, int particle)
{
	if (IsValidEntity(particle))
	{
		char classname[64];
		GetEdictClassname(particle, classname, sizeof(classname));
		if (StrEqual(classname, "info_particle_system", false))
		{
			AcceptEntityInput(particle, "stop");
			AcceptEntityInput(particle, "kill");
			RemoveEdict(particle);
		}
	}
	return Plugin_Stop;
}

public void OnMapEnd()
{
	plugin.isMapRunning = false;
}

stock bool IsValidAliveClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && IsPlayerAlive(client);
}

stock bool IsValidAliveSurv(int client)
{
	return IsValidAliveClient(client) && GetClientTeam(client) == 2;
}

stock bool IsValidAliveInf(int client)
{
	return IsValidAliveClient(client) && GetClientTeam(client) == 2;
}

stock bool IsValidTank(int client)
{
	return IsValidAliveInf(client) && GetClientTeam(client) == 3 && view_as<int>(GetEntProp(client, Prop_Send, "m_zombieClass")) == 8;
}

stock int IsTitanFistReady(int client)
{
	return ((GetEngineTime() - plugin.cooldownTitanFist[client]) > plugin.fTitanFistCooldown);
}

stock int IsTitanicBellowReady(int client)
{
	return ((GetEngineTime() - plugin.cooldownTitanicBellow[client]) > plugin.fTitanicBellowCooldown);
}
