#include <sourcemod>
#include <sdkhooks>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.1.2"

new Handle:v_Enabled = INVALID_HANDLE;
new Handle:v_Mode = INVALID_HANDLE;
new Handle:v_Flag = INVALID_HANDLE;
new Handle:v_HowHoly = INVALID_HANDLE;
new Handle:v_ArrowType = INVALID_HANDLE;
new Handle:v_Particle = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "[TF2] Holy Arrows",
	author = "DarthNinja",
	description = "I heard their powerlevel is over 9000",
	version = PLUGIN_VERSION,
	url = "DarthNinja.com"
}

public OnPluginStart()
{
	CreateConVar("sm_holyarrows_version", PLUGIN_VERSION, "Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	v_Enabled = CreateConVar("sm_holyarrows_enabled", "1", "Enable/Disable Holy Arrows plugin (1/0)", 0, true, 0.0, true, 1.0);
	v_Mode = CreateConVar("sm_holyarrows_mode", "1", "1 = All players, 2 = Admins with correct flag", 0, true, 1.0, true, 2.0);
	v_Flag = CreateConVar("sm_holyarrows_adminflag", "b", "Admin flag to use if mode is set to \"2\".");
	v_HowHoly = CreateConVar("sm_holyarrows_holyness", "1", "How many beam clusters to attach", 0, true, 0.0, true, 500.0);
	v_ArrowType = CreateConVar("sm_holyarrows_arrowtype", "3", "1 = Huntsman, 2 = Medic, 3 = Both", 0, true, 1.0, true, 3.0);
	v_Particle = CreateConVar("sm_holyarrows_particle", "superrare_beams1", "Particle to use (advanced setting)");
}

//This gets called once per arrow
public OnEntityCreated(entity, const String:classname[])
{
	new iArrowType = GetConVarInt(v_ArrowType);
	if (iArrowType == 1 || iArrowType == 3)
	{
		if(StrEqual(classname, "tf_projectile_arrow") && GetConVarBool(v_Enabled))
		{
			SDKHook(entity, SDKHook_Spawn, Arrow);
		}
	}
	
	if (iArrowType == 2 || iArrowType == 3)
	{
		if(StrEqual(classname, "tf_projectile_healing_bolt") && GetConVarBool(v_Enabled))
		{
			SDKHook(entity, SDKHook_Spawn, Arrow);
		}
	}
	
}

//This gets called twice per arrow
public Arrow(entity)
{
	new client = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
	
	if(client < 1)
	{
		return; //Not valid client
	}
	
	//Get mode
	new iMode = GetConVarInt(v_Mode);
	
	switch(iMode)
	{
		case 1:
		{
			//Enabled for all players
			HolyArrow(entity);
		}
		case 2:
		{
			//Enabled for admins
			new String:Flags[32];
			GetConVarString(v_Flag, Flags, sizeof(Flags));
			if(IsValidAdmin(client, Flags))
			{
				HolyArrow(entity);
			}
		}
	}
	//Unhook to prevent being called twice
	SDKUnhook(entity, SDKHook_Spawn, Arrow);
}

HolyArrow(entity)
{
	new iHolyness = GetConVarInt(v_HowHoly);
	new String:sParticles[64];
	GetConVarString(v_Particle, sParticles, sizeof(sParticles));
	for(new i=1; i <= iHolyness; i++)
	{
		CreateParticle(entity, sParticles, true);
	}
	
	// Particle dies shortly after arrow lands, so we dont need this:
	/*
	new Float:Time = 20.0;

	new Handle:pack
	CreateDataTimer(Time, Timer_KillParticle, pack)
	WritePackCell(pack, client);
	WritePackCell(pack, iParticle);
	*/
}

/*
public Action:Timer_KillParticle(Handle:timer, Handle:pack)
{
	ResetPack(pack)
	new client = ReadPackCell(pack)
	new entity = ReadPackCell(pack)
	
	if (IsValidEdict(entity))
	{
		PrintToChat(client, "Removing particle");
		RemoveEdict(entity);
	}
	return Plugin_Stop;
}
*/

//---------------------------

stock bool:IsValidAdmin(client, const String:flags[])
{
	if(!IsClientConnected(client))
	return false;
	
	new ibFlags = ReadFlagString(flags);
	if(!StrEqual(flags, ""))
	{
		if((GetUserFlagBits(client) & ibFlags) == ibFlags)
		{
			return true;
		}
	}
	
	if(GetUserFlagBits(client) & ADMFLAG_ROOT) 
	{
		return true;
	}
	
	return false;
}

// ------------------------------------------------------------------------
// CreateParticle()
// ------------------------------------------------------------------------
// >> Original code by J-Factor
// ------------------------------------------------------------------------
stock CreateParticle(iEntity, String:strParticle[], bool:bAttach = false, String:strAttachmentPoint[]="", Float:fOffset[3]={0.0, 0.0, 0.0})
{
    new iParticle = CreateEntityByName("info_particle_system");
    if (IsValidEdict(iParticle))
    {
        decl Float:fPosition[3];
        decl Float:fAngles[3];
        decl Float:fForward[3];
        decl Float:fRight[3];
        decl Float:fUp[3];
        
        // Retrieve entity's position and angles
        //GetClientAbsOrigin(iClient, fPosition);
        //GetClientAbsAngles(iClient, fAngles);
        GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fPosition)
		
        // Determine vectors and apply offset
        GetAngleVectors(fAngles, fForward, fRight, fUp);    // I assume 'x' is Right, 'y' is Forward and 'z' is Up
        fPosition[0] += fRight[0]*fOffset[0] + fForward[0]*fOffset[1] + fUp[0]*fOffset[2];
        fPosition[1] += fRight[1]*fOffset[0] + fForward[1]*fOffset[1] + fUp[1]*fOffset[2];
        fPosition[2] += fRight[2]*fOffset[0] + fForward[2]*fOffset[1] + fUp[2]*fOffset[2];
        
        // Teleport and attach to client
        //TeleportEntity(iParticle, fPosition, fAngles, NULL_VECTOR);
        TeleportEntity(iParticle, fPosition, NULL_VECTOR, NULL_VECTOR);
        DispatchKeyValue(iParticle, "effect_name", strParticle);

        if (bAttach == true)
        {
            SetVariantString("!activator");
            AcceptEntityInput(iParticle, "SetParent", iEntity, iParticle, 0);            
            
            if (StrEqual(strAttachmentPoint, "") == false)
            {
                SetVariantString(strAttachmentPoint);
                AcceptEntityInput(iParticle, "SetParentAttachmentMaintainOffset", iParticle, iParticle, 0);                
            }
        }

        // Spawn and start
        DispatchSpawn(iParticle);
        ActivateEntity(iParticle);
        AcceptEntityInput(iParticle, "Start");
    }

    return iParticle;
}