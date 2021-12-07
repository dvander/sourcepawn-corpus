#pragma semicolon 1
#include <sourcemod> 
#include <sdkhooks> 
#include <l4d_stocks>
#include <defibfix>

#define PLUGIN_VERSION "1.4" 
#define PLUGIN_NAME "[L4D2] Death Animations Restore" 

static const String:MODEL_NICK[] = "models/survivors/survivor_gambler.mdl";
static const String:MODEL_ROCHELLE[] = "models/survivors/survivor_producer.mdl";
static const String:MODEL_COACH[] = "models/survivors/survivor_coach.mdl";
static const String:MODEL_ELLIS[] = "models/survivors/survivor_mechanic.mdl";
static const String:MODEL_BILL[] = "models/survivors/survivor_namvet.mdl";
static const String:MODEL_ZOEY[] = "models/survivors/survivor_teenangst.mdl";
static const String:MODEL_FRANCIS[] = "models/survivors/survivor_biker.mdl";
static const String:MODEL_LOUIS[] = "models/survivors/survivor_manager.mdl";

static bool:g_bIsRagdollDeathEnabled;
static bool:g_bIsSurvivorInDeathAnimation[MAXPLAYERS+1] = false;

public Plugin:myinfo =  
{ 
    name = PLUGIN_NAME, 
    author = "DeathChaos25", 
    description = "Restores Death Animations Of All Survivors.", 
    version = PLUGIN_VERSION, 
    url = "https://forums.alliedmods.net/showthread.php?t=247488", 
};

public OnPluginStart() 
{ 
    SetConVarInt(FindConVar("survivor_death_anims"), 1);
    
    CreateTimer(0.1, TimerUpdate, _, TIMER_REPEAT);
	
    new Handle:RagdollDeathEnabled = CreateConVar("death_animations_restore-l4d2_ragdolls", "1", "Enable/Disable Ragdolls", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    HookConVarChange(RagdollDeathEnabled, ConVarRagdollDeathEnabled);
    g_bIsRagdollDeathEnabled = GetConVarBool(RagdollDeathEnabled);
    
    AutoExecConfig(true, "death_animations_restore-l4d2");
	
	HookEvent("defibrillator_begin", OnDefibrillatorBegin);
    HookEvent("weapon_fire", OnWeaponFire);
} 

public OnClientPutInServer(client)
{
    SDKHook(client, SDKHook_WeaponSwitch, OnWeaponSwitch);
}

public OnAllPluginsLoaded()
{
    for (new client = 1; client <= MaxClients; client++)
    {
        if (IsClientInGame(client) && GetClientTeam(client) == 2)
        {
            SDKHook(client, SDKHook_WeaponSwitch, OnWeaponSwitch);
        }
    }
}  

public Action:TimerUpdate(Handle:timer)
{
    if (!IsServerProcessing())
	{
		return Plugin_Continue;
	}
    
    for (new i=1; i<=MaxClients; i++)
    {
        if (IsSurvivor(i) && IsPlayerAlive(i) && !g_bIsSurvivorInDeathAnimation[i])
        {
            new i_CurrentAnimation = GetEntProp(i, Prop_Send, "m_nSequence");
            decl String:model[PLATFORM_MAX_PATH];
            GetClientModel(i, model, sizeof(model));
			
            if(i_CurrentAnimation == 555 && (StrEqual(model, MODEL_FRANCIS, false) || StrEqual(model, MODEL_ZOEY, false)) || i_CurrentAnimation == 552 && (StrEqual(model, MODEL_BILL, false) || StrEqual(model, MODEL_LOUIS, false)) || i_CurrentAnimation == 644 && StrEqual(model, MODEL_NICK, false) || i_CurrentAnimation == 649 && StrEqual(model, MODEL_ELLIS, false) || i_CurrentAnimation == 638 && StrEqual(model, MODEL_COACH, false) || i_CurrentAnimation ==  652 && StrEqual(model, MODEL_ROCHELLE, false))
            {
				g_bIsSurvivorInDeathAnimation[i] = true;
				CreateTimer(3.03, ForcePlayerSuicideTimer, GetClientUserId(i), TIMER_FLAG_NO_MAPCHANGE);
                return Plugin_Continue;
            }
        }
    }
	
	decl String:class[64];
	new count = 0;
	for(new i=MaxClients+1; i<=GetMaxEntities(); i++)
	{
		if(i > 0 && IsValidEntity(i) && IsValidEdict(i))
		{
			GetEdictClassname(i, class, sizeof(class));
			if(StrEqual(class, "prop_ragdoll"))
			{
				AcceptEntityInput(i, "Kill");
				count++;
			}
		}
	}
	count = 0;
	
    return Plugin_Continue;
}

public Action:ForcePlayerSuicideTimer(Handle:timer, any:userid) 
{ 
    new client = GetClientOfUserId(userid); 
    if (client > MaxClients || !IsClientInGame(client)) 
    {
		return Plugin_Continue;
	}
    
    if (g_bIsRagdollDeathEnabled == true)
	{
        SetEntProp(client, Prop_Send, "m_isFallingFromLedge", 1);
        
        new weapon = GetPlayerWeaponSlot(client, 1);
        if (weapon > 0 && IsValidEntity(weapon))
		{ 
            SDKHooks_DropWeapon(client, weapon);
        }
		
        new entity;
        new String:modelname[128];
        GetEntPropString(client, Prop_Data, "m_ModelName", modelname, 128);
        
        entity = CreateEntityByName("survivor_death_model");
        SetEntityModel(entity, modelname);
        
        new Float:g_Origin[3];
        new Float:g_Angle[3];
        
        GetClientAbsOrigin(client, g_Origin);
        GetClientAbsAngles(client, g_Angle);
        
        TeleportEntity(entity, g_Origin, g_Angle, NULL_VECTOR);
        DispatchSpawn(entity);
        SetEntityRenderMode(entity, RENDER_NONE);
        DefibFix_AssignPlayerDeathModel(client, entity);
        new character_type = GetEntProp(client, Prop_Send, "m_survivorCharacter");
        SetEntProp(entity, Prop_Send, "m_nCharacterType", character_type);
    }
    
    ForcePlayerSuicide(client);
    g_bIsSurvivorInDeathAnimation[client] = false;
    
    return Plugin_Continue;
} 

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:ang[3], &weapon)
{
    if (!IsClientInGame(client) || L4DTeam:GetClientTeam(client) != L4DTeam_Survivor || !IsPlayerAlive(client) || !g_bIsSurvivorInDeathAnimation[client]) 
    {
		return Plugin_Continue;
	}
    return Plugin_Handled;
}  

public ConVarRagdollDeathEnabled(Handle:convar, const String:oldValue[], const String:newValue[]) 
{ 
    g_bIsRagdollDeathEnabled = GetConVarBool(convar);
}

stock bool:IsSurvivor(client)
{
    new maxclients = GetMaxClients();
    if (client > 0 && client < maxclients && IsClientInGame(client) && GetClientTeam(client) == 2)
    {
        return true;
    }
    return false;
}

public Action:OnWeaponSwitch(client, weapon)
{
    if (IsSurvivor(client) && IsPlayerAlive(client))
    {
        if (g_bIsSurvivorInDeathAnimation[client])
        {
            return Plugin_Handled;
        }
    }
    return Plugin_Continue;
}

public Action:OnDefibrillatorBegin(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    new subject = GetClientOfUserId(GetEventInt(event, "subject"));
}

public Action:OnWeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{        
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (!IsSurvivor(client))
    {
        return Plugin_Continue;
    }
    
    if (g_bIsSurvivorInDeathAnimation[client])
    {
        return Plugin_Handled;
    }    
    return Plugin_Continue;
}

