#include <sdktools>
#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

ConVar g_cvPianoPitch;

char g_sPianoSound[90] = "ambient/bumper_car_quack1.wav";

int g_iPianos[16] = {-1, ...},
    g_iLastButtons[MAXPLAYERS+1];

int g_iPianoId = 0;

public Plugin myinfo = {
	name        = "Duck Piano",
	author      = "Firewolf",
	description = "Now you can play your favourite Quackhoven pieces in TF2 (sort of)!",
	version     = "0.1",
	url         = ""
};

public void OnPluginStart()
{
    g_cvPianoPitch = CreateConVar("sm_piano_pitch", "40", "Sets the pitch range");

    RegAdminCmd("sm_piano", Command_PlacePiano, ADMFLAG_SLAY, "Spawns a piano");
    RegAdminCmd("sm_pianosound", Command_ChangeSound, ADMFLAG_SLAY, "sm_pianosound <path/to/sound.wav> - Sets a custom sound for the piano");
    RegAdminCmd("sm_clearpianos", Command_RemoveAllPianos, ADMFLAG_SLAY, "Removes all pianos");

    PrecacheSound(g_sPianoSound);
}

public void OnPluginEnd()
{
    RemoveAllPianos(0);
}

public void OnClientPutInServer(int client)
{
    PrecacheSound(g_sPianoSound);
}

public Action OnPlayerRunCmd(int i, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	int iEnt = GetClientAimTarget(i, false);

	if(buttons & IN_ATTACK2 && !(g_iLastButtons[i] & IN_ATTACK2)) // Rightclick by default
	{
		if(iEnt <= MaxClients || !IsValidEntity(iEnt)) {}
		else
		{
			char sName[32];
			GetEntPropString(iEnt, Prop_Data, "m_iName", sName, 32);
			if(StrEqual(sName, "prop_duckpiano"))
				PlayPiano(iEnt, angles);
		}
	}

	g_iLastButtons[i]	= buttons;

	return Plugin_Continue;
}

public Action Command_ChangeSound(int client, int args)
{
    if(args < 1)
    {
        ReplyToCommand(client, "No argument supplied. Usage: sm_pianosound <path/to/sound.wav>");
        return Plugin_Handled;
    }

    GetCmdArg(1, g_sPianoSound, 90);
    PrecacheSound(g_sPianoSound);

    return Plugin_Handled;
}

public Action Command_PlacePiano(int client, int args)
{
    if(!IsClientInGame(client))
    {
        ReplyToCommand(client, "Command can only be used in-game");
        return Plugin_Handled;
    }

    if(g_iPianoId >= 15)
    {
        ReplyToCommand(client, "Piano limit reached");
        return Plugin_Handled;
    }

    float fPos[3], fAng[3], fEndPos[3], fEndAng[3];
    GetClientEyePosition(client, fPos);
    GetClientEyeAngles(client, fAng);

    fEndAng[1] = fAng[1] + 180; // Flip the piano around so the keys face the player

    Handle hTrace = TR_TraceRayFilterEx(fPos, fAng, MASK_SHOT, RayType_Infinite, Trace_Filter);
    if(hTrace == INVALID_HANDLE)
        return Plugin_Handled;

    TR_GetEndPosition(fEndPos, hTrace);

    int iPiano = CreateEntityByName("prop_dynamic");
    if(iPiano <= MaxClients || !IsValidEntity(iPiano))
        return Plugin_Handled;

    g_iPianos[g_iPianoId++] = iPiano;

    DispatchKeyValue(iPiano, "targetname", "prop_duckpiano");
    DispatchKeyValue(iPiano, "model", "models/props_manor/baby_grand_01.mdl");

    AcceptEntityInput(iPiano, "EnableCollision");
    SetEntProp(iPiano, Prop_Send, "m_nSolidType", 6);
    DispatchSpawn(iPiano);

    TeleportEntity(iPiano, fEndPos, fEndAng, NULL_VECTOR);
    EmitSoundToAll("weapons/loose_cannon_ball_impact.wav", iPiano);

    return Plugin_Handled;
}

public Action Command_RemoveAllPianos(int client, int args)
{
    RemoveAllPianos(client);
    return Plugin_Handled;
}

public bool Trace_Filter			(int iEnt, int iContentMask, any data){
	return !(1 <= iEnt <= MaxClients);
}

int GetPianoPitch(float fPianoZrot, float fPlayerZrot)
{
    return RoundFloat(100 + g_cvPianoPitch.IntValue * ((fPlayerZrot - fPianoZrot) / -50));
}

public void PlayPiano(int iEnt, float fAng[3])
{
    float fPianoAng[3];
    GetEntPropVector(iEnt, Prop_Data, "m_angAbsRotation", fPianoAng);

    EmitSoundToAll(g_sPianoSound, iEnt, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, GetPianoPitch(fPianoAng[1]-180, fAng[1]));
}

void RemoveAllPianos(int client)
{
    for(int i = 0; i < g_iPianoId; i++)
    {
        if(g_iPianos[i] != -1)
            AcceptEntityInput(g_iPianos[i], "Kill", client);

        g_iPianos[i] = -1;
    }
    g_iPianoId = 0;
}