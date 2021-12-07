#include <sourcemod>
#include <sdktools>

new bool:g_bSmoked[MAXPLAYERS+1];
new ParticleEnt[MAXPLAYERS+1];
new Handle:h_playerParticleEffect = INVALID_HANDLE;
char playerParticleEffect[128];

public Plugin myinfo = {
	name        = "Attach Particle",
	author      = "LordOfPixels",
	description = "Can attach particles to client",
	version     = "1.1",
	url         = ""
};

public void OnPluginStart()
{
	h_playerParticleEffect = CreateConVar("sm_attachparticle_type", "ambient_smokestack", "What particle system to attach to players", FCVAR_PLUGIN);	
	playerParticleEffect = "ambient_smokestack";
	HookConVarChange(h_playerParticleEffect, ConVarChanged);

    RegAdminCmd("sm_attachparticle", Command_AttachParticle, ADMFLAG_SLAY, "Attach a particle system to a player");	
}

public ConVarChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if(cvar == h_playerParticleEffect)
	{
		GetConVarString(h_playerParticleEffect, playerParticleEffect, sizeof(playerParticleEffect));
		PrintToConsole(0, "Particle type is now %s", playerParticleEffect);
	}
}

public Action:Command_AttachParticle(iClient, args)
{

	if(iClient == 0)
	{
	PrintToServer("Command In-game Only!");
	}
	if (args != 2)
	{
		ReplyToCommand(iClient, "Usage:sm_attachparticle <client> <0/1>");
		return Plugin_Handled;
	}
	
    decl String:szTarget[MAX_NAME_LENGTH+1];
    GetCmdArg(1, szTarget, sizeof(szTarget));

    decl String:szTargetName[MAX_TARGET_LENGTH+1];
    decl iTargetList[MAXPLAYERS+1], iTargetCount, bool:bTnIsMl;

    if ((iTargetCount = ProcessTargetString(
            szTarget,
            iClient,
            iTargetList,
            MAXPLAYERS,
            COMMAND_FILTER_CONNECTED,
            szTargetName,
            sizeof(szTargetName),
            bTnIsMl)) <= 0) {
        ReplyToTargetError(iClient, iTargetCount);
        return Plugin_Handled;
    }

    decl String:szEnable[2];
    GetCmdArg(2, szEnable, sizeof(szEnable));

    new bool:bEnable = !!StringToInt(szEnable);
    for (new i = 0; i < iTargetCount; i++) {
        g_bSmoked[iTargetList[i]] = bEnable;
		if (bEnable == true) {
			CreateParticle(iTargetList[i], playerParticleEffect);
			ShowActivity2(iClient, "[SM] ", "%s has a particle system attached", szTargetName);
			ReplyToCommand(iClient, "[SM] %s has a particle system attached", szTargetName);
		} else {
			DeleteParticle(iTargetList[i]);
			ShowActivity2(iClient, "[SM] ", "%s no longer has a particle system attached", szTargetName);
			ReplyToCommand(iClient, "[SM] %s no longer has a particle system attached", szTargetName);
		}
    }
	return Plugin_Handled;
}

stock CreateParticle(client, String:particleType[])
{
    ParticleEnt[client] = CreateEntityByName("info_particle_system");

	decl String:name[64];

    if (IsValidEdict(ParticleEnt[client]))
    {
        new Float:position[3];
        GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
		position[2] += 50;
        TeleportEntity(ParticleEnt[client], position, NULL_VECTOR, NULL_VECTOR);
        GetEntPropString(client, Prop_Data, "m_iName", name, sizeof(name));
        DispatchKeyValue(ParticleEnt[client], "targetname", "attachedParticle");
        DispatchKeyValue(ParticleEnt[client], "parentname", name);
        DispatchKeyValue(ParticleEnt[client], "effect_name", particleType);
        DispatchSpawn(ParticleEnt[client]);
        SetVariantString(name);
		
		decl String:Buffer[64];
		Format(Buffer, sizeof(Buffer), "Client%d", client);
		DispatchKeyValue(client, "targetname", Buffer);
		SetVariantString(Buffer);
		
        AcceptEntityInput(ParticleEnt[client], "SetParent", client, ParticleEnt[client], 0);
        ActivateEntity(ParticleEnt[client]);
        AcceptEntityInput(ParticleEnt[client], "start");
    }
}

public Action:DeleteParticle(client)
{
    if (IsValidEntity(ParticleEnt[client]))
    {
        new String:classN[64];
        GetEdictClassname(ParticleEnt[client], classN, sizeof(classN));
        if (StrEqual(classN, "info_particle_system", false))
        {
            RemoveEdict(ParticleEnt[client]);
        }
    }
}