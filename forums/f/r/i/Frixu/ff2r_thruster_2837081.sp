/*
	"thruster_ability"																						// Ability name can't use suffixes
	{	
		"button"							"3"																// Activation button (1 = IN_ATTACK3, 2 = IN_RELOAD, 3 = IN_ATTACK2)
    	"cooldown"              			"7.5"      														// How long it takes to regain a charge in seconds
    	"cost"                  			"0.0"      														// The amount of rage consumed and required on use (0.0 will disable this)
   		"charges_max"           			"2"         													// How many charges that can be stored
   		"charges"							"1"																// How many charges to be given at the start of the round
   		"air_dashes"						"0.0"															// How many times this ability can be used before touching the (ground (0.0 = infinite use) (1 = once) 
   		
   		"diminish_rate"						"-600.0"														// Diminish rate of launch force when used repeatedly in midair
   		"diminish_min"						"450.0"															// If the vertical launch force gets lower than this from, Diminishing returns then the thruster becomes unusable (until touching the ground) (less than 0 disables this)
    	"vert_power"            			"1100.0"     													// The vertical launching force of the thruster
    	"hori_power"            			"700.0"     													// The horizontal launching force of the thruster
    	"small_power"           			"400.0"     													// The initial launch's vertical force
    	"e_mult"                			"1.35"       													// Emergency thruster mode velocity multiplier
    	
    	"stun_type"             			"0"         													// Stun type (0 = none, 1 = slowdown, 2 = stunned walk, 3 = fully stunned)
    	"stun_dur"              			"0.0"       													// Stun duration in seconds
    	"conditions"            			"28 ; 1.5" 														// Applies conditions
    	
    	"aoe_flags"             			"3"         													// AOE effects mid-air (1 = ignite, 2 = extinguish, 4 = knockback)
    	"aoe_dmg"               			"0.0"      														// AOE damage mid-air
    	"aoe_range"             			"275.0"     													// AOE range mid-air
    	
    	"land_aoe_flags"        			"4"         													// AOE effects on landing (1 = ignite, 2 = extinguish, 4 = knockback)
    	"land_aoe_dmg"          			"50.0"      													// Landing AOE damage
    	"land_aoe_range"        			"200.0"     													// Landing AOE range
    	
    	"small_sound"           			"weapons/rocket_pack_boosters_charge.wav"   					// Sound file to use for the initial blast
    	"large_sound"           			"weapons/rocket_pack_boosters_fire.wav"   						// Sound file to use for the blast off
   		"blast_effect"         				"heavy_ring_of_fire"	   										// Mid-air blast visual effect
    	"exhaust_effect"        			"rockettrail"            										// Trail effect from thrust
   		"effect_style"          			"2"         													// Visual effect style (0 = none, 1 = single effect, 2 = double effect)
    	"effect_offset"         			"0.9"       													// Vertical offset for visual effects
    	
    	"hud_style"             			"1"        														// HUD style (0 = no HUD, 1 = shows charges)
    	"hud_offset"            			"0.75"      													// Offset for HUD position
    	"hud_x"                				"-1.0"       													// HUD X position (0.0 - 1.0 screen space)
    	"hud_y"                 			"0.85"      													// HUD Y position (0.0 - 1.0 screen space)
    
    	"strings_unavailable"           	"Thruster(%i) Unavailable (rage %.0f)"             				// Message when not ready
    	"strings_ready"                 	"Thruster(%i) Ready (rage %.0f)\nPress ATTACK2!"   				// Message when ready
    	"strings_unavailable_partial"   	"Thruster(%i) %.0f%% Unavailable (rage %.0f)"      				// Message when partially unavailable
    	"strings_ready_partial"         	"Thruster(%i) %.0f%% Ready (rage %.0f)\nPress ATTACK2!" 		// Message when partially ready
    	"strings_emergency_unavailable" 	"EMERGENCY Thruster %.0f%% Unavailable"           				// Emergency message (unavailable)
    	"strings_emergency_ready"       	"EMERGENCY Thruster Ready\nPress ATTACK2!"        				// Emergency message (ready)
		
		"plugin_name"	        			"ff2r_thruster"
	}	
*/

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#include <cfgmap>
#include <ff2r>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_NAME 	"Freak Fortress 2 Rewrite: Thruster"
#define PLUGIN_AUTHOR 	"kking117"
#define PLUGIN_DESC 	"Adds a thermal thruster like ability for FF2R bosses."

#define MAJOR_REVISION 	"1"
#define MINOR_REVISION 	"1"
#define STABLE_REVISION "1"
#define PLUGIN_VERSION 	MAJOR_REVISION..."."...MINOR_REVISION..."."...STABLE_REVISION

#define MAXTF2PLAYERS	MAXPLAYERS+1

bool RoundActive;

int FF2ThrustAOEFlags[MAXTF2PLAYERS];
float FF2ThrustAOEDmg[MAXTF2PLAYERS];
float FF2ThrustAOE[MAXTF2PLAYERS];
int FF2LandAOEFlags[MAXTF2PLAYERS];
float FF2LandAOEDmg[MAXTF2PLAYERS];
float FF2LandAOE[MAXTF2PLAYERS];
int FF2DmgFix[MAXTF2PLAYERS];

int FF2ThrustStunType[MAXTF2PLAYERS];
float FF2ThrustStunDur[MAXTF2PLAYERS];
char FF2ThrustCond[MAXTF2PLAYERS][128];

int FF2ThrustAir[MAXTF2PLAYERS];
float FF2ThrustDiminishRate[MAXTF2PLAYERS];
float FF2ThrustDiminishMin[MAXTF2PLAYERS];
float FF2ThrustVertPower[MAXTF2PLAYERS];
float FF2ThrustHoriPower[MAXTF2PLAYERS];
float FF2ThrustSmalPower[MAXTF2PLAYERS];
float FF2ThrustEMult[MAXTF2PLAYERS];

float FF2ThrustCooldown[MAXTF2PLAYERS];
float FF2ThrustCost[MAXTF2PLAYERS];
int FF2ThrustCharges[MAXTF2PLAYERS];
int FF2ThrustChargesMax[MAXTF2PLAYERS];

char FF2ThrustSmallSound[MAXTF2PLAYERS][128];
char FF2ThrustLargeSound[MAXTF2PLAYERS][128];
char FF2ThrustBlastEffect[MAXTF2PLAYERS][128];
char FF2ThrustExhaustEffect[MAXTF2PLAYERS][128];
int FF2ThrustEffectStyle[MAXTF2PLAYERS];
float FF2ThrustEffectOffset[MAXTF2PLAYERS];

bool FF2ThrustEnable[MAXTF2PLAYERS];
int FF2ThrustButton[MAXTF2PLAYERS];

int HUDThrustStyle[MAXTF2PLAYERS];
float HUDThrustOffset[MAXTF2PLAYERS];

float NextThrust[MAXTF2PLAYERS];
float HUD_X[MAXTF2PLAYERS];
float HUD_Y[MAXTF2PLAYERS];
float NextCharge[MAXTF2PLAYERS];
float GraceTimer[MAXTF2PLAYERS];
float PanicMode[MAXTF2PLAYERS];
float WorldDmg[MAXTF2PLAYERS];
int AirDashCount[MAXTF2PLAYERS];
int LastButtons[MAXTF2PLAYERS];
bool AddcondAirList[MAXTF2PLAYERS][128];

char StringsUnavailable[128];
char StringsReady[128];
char StringsUnavailablePartial[128];
char StringsReadyPartial[128];
char StringsEmergencyUnavailable[128];
char StringsEmergencyReady[128];

bool TrailActive[MAXTF2PLAYERS];
int RT_EntRef[MAXTF2PLAYERS][2];
float LastFallSpeed[MAXTF2PLAYERS];
Handle JetPackHUD;
Handle hTrace;

public Plugin myinfo = 
{
	name 		= PLUGIN_NAME,
	author 		= PLUGIN_AUTHOR,
	description	= PLUGIN_DESC,
	version 	= PLUGIN_VERSION,
};

public void OnPluginStart()
{
    HookEvent("arena_round_start", OnRoundStart, EventHookMode_PostNoCopy);
    HookEvent("arena_win_panel", OnRoundEnd, EventHookMode_PostNoCopy);
    HookEvent("player_hurt", OnPlayerHurt, EventHookMode_Pre);
    JetPackHUD = CreateHudSynchronizer();
}

public void OnClientPutInServer(int client)
{
    ClearVariables(client);
}

public Action OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
    RoundActive = true;
    for (int client = 1; client <= MaxClients; client++)
    {
        if (IsValidClient(client))
        {
            BossData cfg = FF2R_GetBossData(client);
            if (cfg != null && cfg.GetAbility("thruster_ability").IsMyPlugin())
            {
                FF2R_OnBossCreated(client, cfg, false);
            }
            else
            {
                ClearVariables(client);
            }
        }
    }
    CreateTimer(0.2, ClientTimer, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
    return Plugin_Continue;
}

public Action OnRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    RoundActive = false;
    for (int client = 1; client <= MaxClients; client++)
    {
        if (IsValidClient(client))
        {
            ClearVariables(client);
        }
    }
    return Plugin_Continue;
}

public void FF2R_OnBossCreated(int client, BossData cfg, bool setup)
{
    if (!setup || FF2R_GetGamemodeType() != 2)
    {
        if (cfg.GetAbility("thruster_ability").IsMyPlugin())
        {
            AbilityData ability = cfg.GetAbility("thruster_ability");

            FF2ThrustEnable[client] = true;
            FF2ThrustButton[client] = ability.GetInt("button", 1);
            FF2ThrustCooldown[client] = ability.GetFloat("cooldown", 15.0);
            if (FF2ThrustCooldown[client] < 1.5)
            {
                FF2ThrustCooldown[client] = 1.5;
            }
            NextCharge[client] = FF2ThrustCooldown[client];
            FF2ThrustCost[client] = ability.GetFloat("cost", 5.0);
            FF2ThrustChargesMax[client] = ability.GetInt("charges_max", 1);
            FF2ThrustCharges[client] = ability.GetInt("charges", 0) - 1;
            FF2ThrustAir[client] = ability.GetInt("air_dashes", 0);

            FF2ThrustDiminishRate[client] = ability.GetFloat("diminish_rate", 0.0);
            FF2ThrustDiminishMin[client] = ability.GetFloat("diminish_min", 450.0);
            FF2ThrustVertPower[client] = ability.GetFloat("vert_power", 900.0);
            FF2ThrustHoriPower[client] = ability.GetFloat("hori_power", 600.0);
            FF2ThrustSmalPower[client] = ability.GetFloat("small_power", 400.0);
            FF2ThrustEMult[client] = ability.GetFloat("e_mult", 2.0);

            FF2ThrustStunType[client] = ability.GetInt("stun_type", 0);
            FF2ThrustStunDur[client] = ability.GetFloat("stun_dur", 0.0);

            ability.GetString("conditions", FF2ThrustCond[client], 128);
            FF2ThrustAOEFlags[client] = ability.GetInt("aoe_flags", 0);
            FF2LandAOEFlags[client] = ability.GetInt("land_aoe_flags", 0);
            FF2ThrustAOEDmg[client] = ability.GetFloat("aoe_dmg", 0.0);
            FF2LandAOEDmg[client] = ability.GetFloat("land_aoe_dmg", 0.0);
            FF2DmgFix[client] = ability.GetInt("dmg_fix", 1);
            FF2ThrustAOE[client] = ability.GetFloat("aoe_range", 300.0);
            FF2LandAOE[client] = ability.GetFloat("land_aoe_range", 300.0);

            ability.GetString("small_sound", FF2ThrustSmallSound[client], 128);
            ability.GetString("large_sound", FF2ThrustLargeSound[client], 128);
            ability.GetString("blast_effect", FF2ThrustBlastEffect[client], 128);
            ability.GetString("exhaust_effect", FF2ThrustExhaustEffect[client], 128);
            FF2ThrustEffectStyle[client] = ability.GetInt("effect_style", 0);
            FF2ThrustEffectOffset[client] = ability.GetFloat("effect_offset", 1.0);

            HUDThrustStyle[client] = ability.GetInt("hud_style", 0);
            HUDThrustOffset[client] = ability.GetFloat("hud_offset", 0.77);
            HUD_X[client] = ability.GetFloat("hud_x", 0.7);      
            HUD_Y[client] = ability.GetFloat("hud_y", 0.85); 
            
            ability.GetString("strings_unavailable", StringsUnavailable, sizeof(StringsUnavailable));
            ability.GetString("strings_ready", StringsReady, sizeof(StringsReady));
            ability.GetString("strings_unavailable_partial", StringsUnavailablePartial, sizeof(StringsUnavailablePartial));
            ability.GetString("strings_ready_partial", StringsReadyPartial, sizeof(StringsReadyPartial));
            ability.GetString("strings_emergency_unavailable", StringsEmergencyUnavailable, sizeof(StringsEmergencyUnavailable));
            ability.GetString("strings_emergency_ready", StringsEmergencyReady, sizeof(StringsEmergencyReady));
        }
    }
}

public Action ClientTimer(Handle timer)
{
    if (!RoundActive)
    {
        return Plugin_Stop;
    }

    for (int client = 1; client <= MaxClients; client++)
    {
        if (IsValidClient(client) && FF2ThrustEnable[client])
        {
            BossData cfg = FF2R_GetBossData(client);
            float rage = cfg.GetCharge(0); 
            float chargePercent = (float(FF2ThrustCharges[client]) / float(FF2ThrustChargesMax[client])) * 100.0;

            int chargeStatus = 0;  
            if (CanThrust(client) != 0)
            {
                chargeStatus = 2;  
            }
            else if (rage < FF2ThrustCost[client])
            {
                chargeStatus = 0;  
            }
            else if (FF2ThrustCharges[client] < FF2ThrustChargesMax[client])
            {
                chargeStatus = 3;  
            }

            DisplayHUDMessage(client, chargeStatus, rage, chargePercent);
        }
    }

    return Plugin_Continue;
}

void DisplayHUDMessage(int client, int chargeStatus, float rage, float chargePercent)
{
    if(HUDThrustStyle[client] == 0)  
        return;
        
    char message[128];
    
    switch(chargeStatus)
    {
        case 0: Format(message, sizeof(message), StringsUnavailable, FF2ThrustCharges[client], rage);
        case 1: Format(message, sizeof(message), StringsReady, FF2ThrustCharges[client], rage);
        case 2: Format(message, sizeof(message), StringsUnavailablePartial, FF2ThrustCharges[client], chargePercent, rage);
        case 3: Format(message, sizeof(message), StringsReadyPartial, FF2ThrustCharges[client], chargePercent, rage);
        case 4: Format(message, sizeof(message), StringsEmergencyUnavailable, chargePercent);
        case 5: Format(message, sizeof(message), StringsEmergencyReady);
    }
    
    SetHudTextParams(
        HUD_X[client], 
        HUD_Y[client], 
        0.2,            
        255, 255, 255,  
        255,            
        2,                    
         0.0, 0.0, 0.0          
    );
    
    ShowSyncHudText(client, JetPackHUD, message);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
    if (IsValidClient(client) && FF2R_GetBossData(client) != null)
    {
        if (IsPlayerAlive(client))
        {
            if (FF2ThrustEnable[client])
            {
                if (FF2ThrustCharges[client] < FF2ThrustChargesMax[client])
                {
                    if (NextCharge[client] <= GetGameTime())
                    {
                        FF2ThrustCharges[client] += 1;
                        if (FF2ThrustCharges[client] < FF2ThrustChargesMax[client])
                        {
                            NextCharge[client] = GetGameTime() + FF2ThrustCooldown[client];
                        }
                    }
                }
                if (CanThrust(client) == 0)
                {
                    BossData cfg = FF2R_GetBossData(client);
                    float currentCharge = cfg.GetCharge(0);  
                    cfg.SetCharge(0, currentCharge - FF2ThrustCost[client]);  

                    if (FF2ThrustButton[client] == 1)
                    {
                        if ((LastButtons[client] & IN_ATTACK3) == 0 && (buttons & IN_ATTACK3))
                        {
                            if (PanicMode[client] >= GetGameTime())
                            {
                                TTLaunchBig(client);
                            }
                            else
                            {
                                TTLaunchSmall(client);
                            }
                        }
                    }
                    else if (FF2ThrustButton[client] == 2)
                    {
                        if ((LastButtons[client] & IN_RELOAD) == 0 && (buttons & IN_RELOAD))
                        {
                            if (PanicMode[client] >= GetGameTime())
                            {
                                TTLaunchBig(client);
                            }
                            else
                            {
                                TTLaunchSmall(client);
                            }
                        }
                    }
                    else
                    {
                        if ((LastButtons[client] & IN_ATTACK2) == 0 && (buttons & IN_ATTACK2))
                        {
                            if (PanicMode[client] >= GetGameTime())
                            {
                                TTLaunchBig(client);
                            }
                            else
                            {
                                TTLaunchSmall(client);
                            }
                        }
                    }
                }
                if (TrailActive[client])
                {
                    if ((GetEntityFlags(client) & FL_ONGROUND))
                    {
                        if (GraceTimer[client] <= GetGameTime())
                        {
                            KillRocketTrails(client);
                            AirDashCount[client] = 0;
                            RemoveAddconds(client);
                            if (FF2LandAOEFlags[client] > 0 && LastFallSpeed[client] < -550.0)
                            {
                                TTBlastAOE(client, LastFallSpeed[client] * -1.0, FF2LandAOE[client], FF2LandAOEFlags[client], FF2LandAOEDmg[client]);
                            }
                        }
                    }
                    else
                    {
                        float vPos[3];
                        float velocity[3];
                        GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);
                        GetEntPropVector(client, Prop_Send, "m_vecOrigin", vPos);
                        int trail1 = EntRefToEntIndex(RT_EntRef[client][0]);
                        int trail2 = EntRefToEntIndex(RT_EntRef[client][1]);
                        TF2_AddCondition(client, TFCond_RocketPack, 0.5);
                        if (FF2ThrustEffectStyle[client] == 1)
                        {
                            if (IsValidEntity(trail1))
                            {
                                float vAng[3];
                                GetEntPropVector(client, Prop_Send, "m_vecOrigin", vPos);
                                GetEntPropVector(client, Prop_Send, "m_angRotation", vAng);
                                GetAngleVectors(vAng, vAng, NULL_VECTOR, NULL_VECTOR);
                                vPos[0] -= vAng[0] * 7.5;
                                vPos[1] -= vAng[1] * 7.5;
                                vPos[2] += GetEntityHeight(client, FF2ThrustEffectOffset[client]);
                                TeleportEntity(trail1, vPos, NULL_VECTOR, NULL_VECTOR);
                            }
                        }
                        else if (FF2ThrustEffectStyle[client] == 2)
                        {
                            if (IsValidEntity(trail1))
                            {
                                float vAng[3];
                                GetEntPropVector(client, Prop_Send, "m_vecOrigin", vPos);
                                GetEntPropVector(client, Prop_Send, "m_angRotation", vAng);
                                vAng[0] = 0.0;
                                vAng[1] += 90.0;
                                GetAngleVectors(vAng, vAng, NULL_VECTOR, NULL_VECTOR);
                                vPos[0] += vAng[0] * 10.0;
                                vPos[1] += vAng[1] * 10.0;
                                vPos[2] += vAng[2] * 10.0;
                                GetEntPropVector(client, Prop_Send, "m_angRotation", vAng);
                                GetAngleVectors(vAng, vAng, NULL_VECTOR, NULL_VECTOR);
                                vPos[0] -= vAng[0] * 7.5;
                                vPos[1] -= vAng[1] * 7.5;
                                vPos[2] += GetEntityHeight(client, FF2ThrustEffectOffset[client]);
                                TeleportEntity(trail1, vPos, NULL_VECTOR, NULL_VECTOR);

                                if (IsValidEntity(trail2))
                                {
                                    GetEntPropVector(client, Prop_Send, "m_vecOrigin", vPos);
                                    GetEntPropVector(client, Prop_Send, "m_angRotation", vAng);
                                    vAng[0] = 0.0;
                                    vAng[1] -= 90.0;
                                    GetAngleVectors(vAng, vAng, NULL_VECTOR, NULL_VECTOR);
                                    vPos[0] += vAng[0] * 10.0;
                                    vPos[1] += vAng[1] * 10.0;
                                    vPos[2] += vAng[2] * 10.0;
                                    GetEntPropVector(client, Prop_Send, "m_angRotation", vAng);
                                    GetAngleVectors(vAng, vAng, NULL_VECTOR, NULL_VECTOR);
                                    vPos[0] -= vAng[0] * 7.5;
                                    vPos[1] -= vAng[1] * 7.5;
                                    vPos[2] += GetEntityHeight(client, FF2ThrustEffectOffset[client]);
                                    TeleportEntity(trail2, vPos, NULL_VECTOR, NULL_VECTOR);
                                }
                            }
                        }
                        LastFallSpeed[client] = velocity[2];
                    }
                }
                LastButtons[client] = buttons;
            }
        }
        else if (TrailActive[client])
        {
            KillRocketTrails(client);
        }
    }
    
    return Plugin_Changed;
}


public Action OnPlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    int damage = event.GetInt("damageamount");
    if (FF2R_GetBossData(client) != null)
    {
        if (!IsValidClient(attacker) && FF2ThrustEMult[client] != 0.0)
        {
            WorldDmg[client] += damage * 1.0;
        }
    }
    
    return Plugin_Continue;  
}

void TTLaunchSmall(int client)
{
	float vLoc[3];
	float vVel[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVel);
	if ((GetEntityFlags(client) & FL_ONGROUND))
	{
		if (GetDiminishForce(client, 2) >= 0.0)
		{
			vVel[2] = GetDiminishForce(client, 2);
		}
	}
	else
	{
		if (GetDiminishForce(client, 2) >= 0.0)
		{
			vVel[2] = GetDiminishForce(client, 2) * 0.75;
		}
		CreateTimer(0.1, Timer_DeployParachute, GetClientUserId(client));
	}
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vVel);
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", vLoc);
	vLoc[2] += GetEntityHeight(client, 0.25);
	EmitSoundToAll(FF2ThrustSmallSound[client], client, _, _, _, 0.65);
	CreateParticleBlast(client, FF2ThrustBlastEffect[client], vLoc);
	if (PanicMode[client] < GetGameTime())
	{
		FF2ThrustCharges[client] -= 1;
		NextCharge[client] = GetGameTime() + FF2ThrustCooldown[client];
	}
	NextThrust[client] = GetGameTime() + 1.5;
	GraceTimer[client] = GetGameTime() + 0.9;
	CreateTimer(0.65, Timer_BigBlast, GetClientUserId(client));
	if (FF2ThrustAOEFlags[client] > 0)
	{
		TTBlastAOE(client, GetDiminishForce(client, 0) * 0.5, FF2ThrustAOE[client], FF2ThrustAOEFlags[client], FF2ThrustAOEDmg[client]);
	}
}

public Action Timer_DeployParachute(Handle timer, int client)
{
    client = GetClientOfUserId(client);
    if (IsValidClient(client) && IsPlayerAlive(client))
    {
        TF2_AddCondition(client, TFCond_Parachute, 0.5);
    }
  
    return Plugin_Continue;  
}

public Action Timer_BigBlast(Handle timer, int client)
{
    client = GetClientOfUserId(client);
    if (IsValidClient(client) && IsPlayerAlive(client))
    {
        TTLaunchBig(client);
    }
    
    return Plugin_Continue;  
}

void TTLaunchBig(int client)
{
	float vLoc[3];
	float vAng[3];
	float vVel[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", vLoc);
	vLoc[2] += GetEntityHeight(client, 0.25);
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVel);
	GetClientEyeAngles(client, vAng);
	GetAngleVectors(vAng, vAng, NULL_VECTOR, NULL_VECTOR);
	if ((LastButtons[client] & IN_FORWARD) == 0 && (LastButtons[client] & IN_BACK))
	{
		if (GetDiminishForce(client, 1) >= 0.0)
		{
			vVel[0] = (vAng[0] * GetDiminishForce(client, 1)) * -1.0;
			vVel[1] = (vAng[1] * GetDiminishForce(client, 1)) * -1.0;
		}
		if (PanicMode[client] >= GetGameTime())
		{
			vVel[2] = (vAng[2] * (GetDiminishForce(client, 0) + GetDiminishForce(client, 2))) * -1.0;
		}
		else
		{
			if (GetDiminishForce(client, 0) >= 0.0)
			{
				vVel[2] = (vAng[2] * GetDiminishForce(client, 0)) * -1.0;
			}
		}
	}
	else
	{
		if (GetDiminishForce(client, 1) >= 0.0)
		{
			vVel[0] = vAng[0] * GetDiminishForce(client, 1);
			vVel[1] = vAng[1] * GetDiminishForce(client, 1);
		}
		if (PanicMode[client] >= GetGameTime())
		{
			vVel[2] = vAng[2] * (GetDiminishForce(client, 0) + GetDiminishForce(client, 2));
		}
		else
		{
			if (GetDiminishForce(client, 0) >= 0.0)
			{
				vVel[2] = vAng[2] * GetDiminishForce(client, 0);
			}
		}
	}
	LastFallSpeed[client] = vVel[2];
	if (PanicMode[client] >= GetGameTime())
	{
		NextThrust[client] = GetGameTime() + 1.5;
		GraceTimer[client] = GetGameTime() + 0.62;
		AirDashCount[client] = 0;
	}
	else
	{
		if ((GetEntityFlags(client) & FL_ONGROUND) == 0)
		{
			AirDashCount[client] += 1;
		}
	}
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vVel);
	KillRocketTrails(client);
	if (FF2ThrustEffectStyle[client] == 1)
	{
		CreateRocketTrail(client, FF2ThrustExhaustEffect[client], false);
	}
	else if (FF2ThrustEffectStyle[client] == 2)
	{
		CreateRocketTrail(client, FF2ThrustExhaustEffect[client], true);
	}
	else
	{
		CreateParticleBlast(client, FF2ThrustExhaustEffect[client], vLoc);
	}
	TrailActive[client] = true;
	EmitSoundToAll(FF2ThrustLargeSound[client], client, _, _, _, 0.7);
	float stundur = FF2ThrustStunDur[client];
	if (FF2ThrustStunType[client] > 0)
	{
		if (stundur < 0.0)
		{
			stundur *= -1.0;
		}
		else if (stundur == 0.0)
		{
			stundur = 9999.0;
		}
		if (FF2ThrustStunType[client] == 4)
		{
			TF2_StunPlayer(client, stundur, 0.0, TF_STUNFLAG_CHEERSOUND | TF_STUNFLAG_BONKSTUCK, client);
		}
		else if (FF2ThrustStunType[client] == 3)
		{
			TF2_StunPlayer(client, stundur, 0.0, TF_STUNFLAG_THIRDPERSON | TF_STUNFLAG_SLOWDOWN, client);
		}
		else if (FF2ThrustStunType[client] == 2)
		{
			TF2_StunPlayer(client, stundur, 0.0, TF_STUNFLAG_SLOWDOWN | TF_STUNFLAG_NOSOUNDOREFFECT | TF_STUNFLAG_THIRDPERSON, client);
		}
		else if (FF2ThrustStunType[client] == 1)
		{
			TF2_StunPlayer(client, stundur, 0.0, TF_STUNFLAG_SLOWDOWN | TF_STUNFLAG_NOSOUNDOREFFECT, client);
		}
		AddcondAirList[client][TFCond_Dazed] = true;
	}
	
	SetPlayerCondition(client, FF2ThrustCond[client]);
}

void TTBlastAOE(int client, float power, float dist, int aoeflags, float dmg)
{
	float clientPosition[3];
	float targetPosition[3];
	float buffer[3];
	if (power > 3500.0)
	{
		power = 3500.0;
	}
	else if (power < 0.0)
	{
		power = 0.0;
	}
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", clientPosition);
	clientPosition[2] += GetEntityHeight(client, 0.5);
	for (int target = 1; target <= MaxClients; target++)
	{
		if (IsValidClient(target) && IsPlayerAlive(target) && client != target)
		{
			GetEntPropVector(target, Prop_Send, "m_vecOrigin", targetPosition);
			targetPosition[2] += GetEntityHeight(client, 0.5);
			if (GetVectorDistance(clientPosition, targetPosition) <= dist && InClearView(clientPosition, targetPosition, target))
			{
				float DistDif = GetVectorDistance(clientPosition, targetPosition);
				if ((aoeflags & 1) && GetClientTeam(target) != GetClientTeam(client))
				{
					TF2_IgnitePlayer(target, client);
				}
				if ((aoeflags & 2) && GetClientTeam(target) == GetClientTeam(client))
				{
					TF2_RemoveCondition(target, TFCond_OnFire);
				}
				if ((GetEntityFlags(target) & FL_ONGROUND) && (aoeflags & 4))
				{
					float kb = ((75.0 + power) * 50.0) / (100.0 + (DistDif * 0.5));
					TF2_AddCondition(target, TFCond_LostFooting, 1.0, client);

					SubtractVectors(targetPosition, clientPosition, buffer);
					NormalizeVector(buffer, buffer);
					buffer[0] *= kb;
					buffer[1] *= kb;
					buffer[2] = 225.0 + (kb * 0.5);
					TeleportEntity(target, NULL_VECTOR, NULL_VECTOR, buffer);
				}
				if (dmg > 0.0 && GetClientTeam(target) != GetClientTeam(client))
				{
					float FallOff = ((DistDif + (dist * 0.25)) / dist) * 0.5;
					if (FallOff > 0.5)
					{
						FallOff = 0.5;
					}
					FallOff = 1.0 - FallOff;
					float aoedmg = dmg * FallOff;
					if (FF2DmgFix[client] != 0)
					{
						if (aoedmg <= 160.0)
						{
							aoedmg *= 0.34;
						}
					}
					
					DamageEntity(target, client, aoedmg, DMG_PLASMA);
				}
			}
		}
	}
}

void DamageEntity(int client, int attacker = 0, float dmg, int dmg_type = DMG_GENERIC)
{
	if (IsValidClient(client) || IsValidEntity(client))
	{
		int damage = RoundToNearest(dmg);
		char dmg_str[16];
		IntToString(damage, dmg_str, 16);
		char dmg_type_str[32];
		IntToString(dmg_type, dmg_type_str, 32);
		int pointHurt = CreateEntityByName("point_hurt");
		if (pointHurt)
		{
			DispatchKeyValue(client, "targetname", "targetsname");
			DispatchKeyValue(pointHurt, "DamageTarget", "targetsname");
			DispatchKeyValue(pointHurt, "Damage", dmg_str);
			DispatchKeyValue(pointHurt, "DamageType", dmg_type_str);
			DispatchSpawn(pointHurt);
			if (IsValidEntity(attacker))
			{
				float AttackLocation[3];
				GetEntPropVector(attacker, Prop_Send, "m_vecOrigin", AttackLocation);
				TeleportEntity(pointHurt, AttackLocation, NULL_VECTOR, NULL_VECTOR);
			}
			AcceptEntityInput(pointHurt, "Hurt", (attacker > 0) ? attacker : -1);
			DispatchKeyValue(pointHurt, "classname", "point_hurt");
			DispatchKeyValue(client, "targetname", "war3_donthurtme");
			RemoveEdict(pointHurt);
		}
	}
}

void SetPlayerCondition(int client, const char[] cond)
{
    char conds[32][32];
    int count = ExplodeString(cond, " ; ", conds, sizeof(conds), sizeof(conds[]));
    if (count > 0)
    {
        float dur;
        int id;
        for (int i = 0; i < count; i += 2)
        {
            if (!TF2_IsPlayerInCondition(client, view_as<TFCond>(StringToInt(conds[i]))))
            {
                dur = StringToFloat(conds[i + 1]);
                id = StringToInt(conds[i]);
                if (dur <= 0.0)
                {
                    AddcondAirList[client][id] = true;
                }
                if (dur < 0.0)
                {
                    dur *= -1.0;
                }
                else if (dur == 0.0)
                {
                    dur = 9999.0;
                }
                
                TF2_AddCondition(client, view_as<TFCond>(id), dur);  
            }
        }
    }
}

void KillRocketTrails(int client)
{
	if (RT_EntRef[client][0] != 0)
	{
		int trail1 = EntRefToEntIndex(RT_EntRef[client][0]);
		if (IsValidEntity(trail1))
		{
			AcceptEntityInput(trail1, "Kill");
			TrailActive[client] = false;
		}
		RT_EntRef[client][0] = 0;
	}
	if (RT_EntRef[client][1] != 0)
	{
		int trail2 = EntRefToEntIndex(RT_EntRef[client][1]);
		if (IsValidEntity(trail2))
		{
			AcceptEntityInput(trail2, "Kill");
			TrailActive[client] = false;
		}
		RT_EntRef[client][1] = 0;
	}
	
	TrailActive[client] = false;
}

void CreateRocketTrail(int client, const char[] particlename, bool dotwo)
{
	if (IsValidClient(client))
	{
		int particle = CreateEntityByName("info_particle_system");
		if (IsValidEdict(particle))
		{
			DispatchKeyValue(particle, "targetname", "tf2particle");
			DispatchKeyValue(particle, "effect_name", particlename);
			DispatchKeyValue(particle, "angles", "-90.0, 0.0, 0.0");
			DispatchSpawn(particle);
			ActivateEntity(particle);
			AcceptEntityInput(particle, "start");
			RT_EntRef[client][0] = EntIndexToEntRef(particle);
		}
		if (dotwo)
		{
			particle = CreateEntityByName("info_particle_system");
			if (IsValidEdict(particle))
			{
				DispatchKeyValue(particle, "targetname", "tf2particle");
				DispatchKeyValue(particle, "effect_name", particlename);
				DispatchKeyValue(particle, "angles", "-90.0, 0.0, 0.0");
				DispatchSpawn(particle);
				ActivateEntity(particle);
				AcceptEntityInput(particle, "start");
				RT_EntRef[client][1] = EntIndexToEntRef(particle);
			}
		}
	}
}

void CreateParticleBlast(int entity, const char[] particlename, float vloc[3])
{
	int particle = CreateEntityByName("info_particle_system");
	char tName[128];
	if (IsValidEdict(particle))
	{
		Format(tName, sizeof(tName), "target%i", entity);
		DispatchKeyValue(particle, "effect_name", particlename);
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		TeleportEntity(particle, vloc, NULL_VECTOR, NULL_VECTOR);
		CreateTimer(15.0, Timer_RemoveParticle, EntIndexToEntRef(particle));
	}
}

public Action Timer_RemoveParticle(Handle timer, int entity)
{
    entity = EntRefToEntIndex(entity);
    if (IsValidEntity(entity))
    {
        AcceptEntityInput(entity, "Kill");
    }
    
    return Plugin_Continue;  
}

void ClearVariables(int client)
{
	FF2ThrustAOEFlags[client] = 0;
	FF2ThrustAOEDmg[client] = 0.0;
	FF2ThrustAOE[client] = 300.0;

	FF2LandAOEFlags[client] = 0;
	FF2LandAOEDmg[client] = 0.0;
	FF2LandAOE[client] = 300.0;

	FF2DmgFix[client] = 1;

	FF2ThrustStunType[client] = 0;
	FF2ThrustStunDur[client] = 0.0;

	FF2ThrustChargesMax[client] = 1;
	FF2ThrustCharges[client] = 0;
	FF2ThrustAir[client] = 0;
	FF2ThrustDiminishRate[client] = 0.0;
	FF2ThrustDiminishMin[client] = 450.0;
	FF2ThrustVertPower[client] = 900.0;
	FF2ThrustHoriPower[client] = 600.0;
	FF2ThrustSmalPower[client] = 325.0;
	FF2ThrustEMult[client] = 2.0;

	FF2ThrustCooldown[client] = 15.0;
	FF2ThrustCost[client] = 5.0;

	FF2ThrustEnable[client] = false;
	FF2ThrustButton[client] = 1;
	FF2ThrustEffectStyle[client] = 0;
	FF2ThrustEffectOffset[client] = 1.0;

	HUDThrustStyle[client] = 0;
	HUDThrustOffset[client] = 0.77;

	NextCharge[client] = 0.0;
	NextThrust[client] = 0.0;
	PanicMode[client] = 0.0;
	WorldDmg[client] = 0.0;
	AirDashCount[client] = 0;
	LastButtons[client] = 0;

	KillRocketTrails(client);
	TrailActive[client] = false;
	ClearAddcondList(client);
}

void ClearAddcondList(int client)
{
	for (int id = 0; id <= 127; id++)
	{
		AddcondAirList[client][id] = false;
	}
}

void RemoveAddconds(int client)
{
    for (int id = 0; id <= 127; id++)
    {
        if (AddcondAirList[client][id] == true)
        {
            TF2_RemoveCondition(client, view_as<TFCond>(id));  
        }
        
        AddcondAirList[client][id] = false;
    }
}

int CanThrust(int client)
{
    if (FF2ThrustCharges[client] > 0)
    {
        BossData cfg = FF2R_GetBossData(client);
        if (PanicMode[client] < GetGameTime() && cfg.GetCharge(0) < FF2ThrustCost[client])
        {
            return 3;
        }
        else if (NextThrust[client] > GetGameTime())
        {
            return 5;
        }
        else
        {
            if (FF2ThrustAir[client] > 0)
            {
                if (AirDashCount[client] < FF2ThrustAir[client])
                {
                    return 0;
                }
                else
                {
                    return 2;
                }
            }
            else if (FF2ThrustDiminishRate[client] != 0.0 || FF2ThrustDiminishMin[client] >= 0.0)
            {
                if (GetDiminishForce(client, 0) < FF2ThrustDiminishMin[client])
                {
                    return 4;
                }
            }
        }
        return 0;
    }
    else
    {
        if (PanicMode[client] < GetGameTime())
        {
            return 1;
        }
        else
        {
            if (NextThrust[client] > GetGameTime())
            {
                return 5;
            }
            else
            {
                return 0;
            }
        }
    }
}

float GetDiminishForce(int client, int type)
{
	float Reduce = FF2ThrustDiminishRate[client] * AirDashCount[client];
	float ForceTotalOG = FF2ThrustVertPower[client] + FF2ThrustHoriPower[client] + FF2ThrustSmalPower[client];
	float ForceTotal = ForceTotalOG;
	float EMult = FF2ThrustEMult[client];
	if (PanicMode[client] < GetGameTime())
	{
		EMult = 1.0;
	}
	else if (EMult == 0.0)
	{
		EMult = 1.0;
	}
	ForceTotal -= Reduce;
	switch (type)
	{
		case 0:
		{
			return EMult * (ForceTotalOG * (FF2ThrustVertPower[client] / ForceTotal));
		}
		case 1:
		{
			return EMult * (ForceTotalOG * (FF2ThrustHoriPower[client] / ForceTotal));
		}
		case 2:
		{
			return EMult * (ForceTotalOG * (FF2ThrustSmalPower[client] / ForceTotal));
		}
	}
	
	return 0.0;
}

float GetEntityHeight(int entity, float mult)
{
	if (IsValidEntity(entity))
	{
		if (HasEntProp(entity, Prop_Send, "m_vecMaxs"))
		{
			float height[3];
			GetEntPropVector(entity, Prop_Send, "m_vecMaxs", height);
			return height[2] * mult;
		}
	}
	
	return -1.0;
}



bool IsValidClient(int client, bool replaycheck = true)
{
	if (client <= 0 || client > MaxClients)
	{
		return false;
	}

	if (!IsClientInGame(client))
	{
		return false;
	}

	if (GetEntProp(client, Prop_Send, "m_bIsCoaching"))
	{
		return false;
	}

	if (replaycheck)
	{
		if (IsClientSourceTV(client) || IsClientReplay(client))
		{
			return false;
		}
	}
	
	return true;
}

bool InClearView(float pos2[3], float pos[3], int entity)
{
	hTrace = TR_TraceRayFilterEx(pos2, pos, MASK_SOLID, RayType_EndPoint, TraceFilterThroughNpc, entity);
	if (hTrace != INVALID_HANDLE)
	{
		if (TR_DidHit(hTrace))
		{
			CloseHandle(hTrace);
			return false;
		}
		else
		{
			CloseHandle(hTrace);
			return true;
		}
	}
	
	return false;
}

bool TraceFilterThroughNpc(int entity, int contentsMask, any ent)
{
	if (entity == ent)
	{
		return false;
	}
	else if (IsValidClient(entity))
	{
		return false;
	}
	else if (IsValidEntity(entity))
	{
		char entname[256];
		GetEntityClassname(entity, entname, sizeof(entname));
		if (StrEqual(entname, "tank_boss", false) || StrEqual(entname, "tf_zombie", false) || StrEqual(entname, "tf_robot_destruction_robot", false) || StrEqual(entname, "merasmus", false) || StrEqual(entname, "headless_hatman", false) || StrEqual(entname, "eyeball_boss", false))
		{
			return false;
		}
		else if (StrEqual(entname, "obj_sentrygun", false) || StrEqual(entname, "obj_dispenser", false) || StrEqual(entname, "obj_teleporter", false))
		{
			return false;
		}
		else if (StrContains(entname, "tf_projectile") >= 0)
		{
			return false;
		}
	}
	
	return true;
}