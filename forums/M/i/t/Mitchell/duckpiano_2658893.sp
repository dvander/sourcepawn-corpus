#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

ConVar cvPianoPitch;
ConVar cvPianoMax;

char sndPiano[256] = "ambient/bumper_car_quack1.wav";

ArrayList alPianos;

public Plugin myinfo = {
	name        = "Duck Piano",
	author      = "Firewolf, Mitch",
	description = "Now you can play your favourite Quackhoven pieces in TF2 (sort of)!",
	version     = "1.1.2",
	url         = ""
};

public void OnPluginStart() {
    cvPianoPitch = CreateConVar("sm_piano_pitch", "40", "Sets the pitch range");
    cvPianoMax   = CreateConVar("sm_piano_max", "16", "Sets the max amount of pianos at one time.");
    AutoExecConfig();

    RegAdminCmd("sm_piano", Command_PlacePiano, ADMFLAG_SLAY, "Spawns a piano");
    RegAdminCmd("sm_pianosound", Command_ChangeSound, ADMFLAG_SLAY, "sm_pianosound <path/to/sound.wav> - Sets a custom sound for the piano");
    RegAdminCmd("sm_clearpianos", Command_RemoveAllPianos, ADMFLAG_SLAY, "Removes all pianos");
}

public void OnPluginEnd() {
    RemoveAllPianos();
}

public void OnMapStart() {
    PrecacheSound(sndPiano);
}

public void OnMapEnd() {
    if(alPianos != null) {
        delete alPianos;
    }
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2]) {
    static lastButtons[MAXPLAYERS+1];
    if(alPianos != null && IsClientInGame(client) && IsPlayerAlive(client) && !IsFakeClient(client)) {
        if(buttons & IN_ATTACK2 && !(lastButtons[client] & IN_ATTACK2)) {
            int iEnt = GetClientAimTarget(client, false);
            if(iEnt > MaxClients && alPianos.FindValue(EntIndexToEntRef(iEnt)) != -1) {
                PlayPiano(iEnt, angles);
            }
        }
        lastButtons[client] = buttons;
    }
    return Plugin_Continue;
}

public Action Command_ChangeSound(int client, int args) {
    if(args < 1) {
        ReplyToCommand(client, "No argument supplied. Usage: sm_pianosound <path/to/sound.wav>");
        return Plugin_Handled;
    }
    GetCmdArg(1, sndPiano, sizeof(sndPiano));
    PrecacheSound(sndPiano);
    return Plugin_Handled;
}

public Action Command_PlacePiano(int client, int args) {
    if(!IsClientInGame(client)) {
        ReplyToCommand(client, "Command can only be used in-game");
        return Plugin_Handled;
    }
    if(!CleanPianoList(cvPianoMax.IntValue)) {
        ReplyToCommand(client, "Piano limit reached");
        return Plugin_Handled;
    }

    float fPos[3], fAng[3];
    GetClientEyePosition(client, fPos);
    GetClientEyeAngles(client, fAng);
    Handle hTrace = TR_TraceRayFilterEx(fPos, fAng, MASK_SHOT, RayType_Infinite, Trace_Filter);
    if(hTrace == null) {
        return Plugin_Handled;
    }

    TR_GetEndPosition(fPos, hTrace);
    delete hTrace;

    int iPiano = CreateEntityByName("prop_dynamic");
    if(iPiano <= MaxClients) {
        return Plugin_Handled;
    }

    DispatchKeyValue(iPiano, "targetname", "prop_duckpiano");
    DispatchKeyValue(iPiano, "model", "models/props_manor/baby_grand_01.mdl");
    AcceptEntityInput(iPiano, "EnableCollision");
    SetEntProp(iPiano, Prop_Send, "m_nSolidType", 6);
    //SetEntPropEnt(iPiano, Prop_Send, "m_hOwner", client);
    DispatchSpawn(iPiano);

    fAng[1] += 180.0; // Flip the piano around so the keys face the player
    TeleportEntity(iPiano, fPos, fAng, NULL_VECTOR);
    EmitSoundToAll("weapons/loose_cannon_ball_impact.wav", iPiano);
    
    AddToPianos(iPiano);
    return Plugin_Handled;
}

public Action Command_RemoveAllPianos(int client, int args) {
    RemoveAllPianos();
    return Plugin_Handled;
}

public bool Trace_Filter(int iEnt, int iContentMask, any data){
	return (iEnt == 0 || iEnt > MaxClients);
}

public int GetPianoPitch(float fPianoZrot, float fPlayerZrot) {
    return RoundFloat(100.0 + cvPianoPitch.FloatValue * ((fPlayerZrot - fPianoZrot) / -50.0));
}

public void PlayPiano(int iEnt, float fAng[3]) {
    float fPianoAng[3];
    GetEntPropVector(iEnt, Prop_Data, "m_angAbsRotation", fPianoAng);
    EmitSoundToAll(sndPiano, iEnt, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, GetPianoPitch(fPianoAng[1]-180.0, fAng[1]));
}

public void RemoveAllPianos() {
    int index;
    for(int i=0; i < alPianos.Length; i++) {
        index = EntRefToEntIndex(alPianos.Get(i));
        //Reference can only point to a valid entity, or goes to -1 etc. So if this returns an entity that isn't a Piano prop then a critical bug has been found within the Source Engine.
        if(index != -1) {
            AcceptEntityInput(index, "Kill");
        }
    }
    delete alPianos;
}

public void AddToPianos(int index) {
    if(alPianos == null) {
        alPianos = new ArrayList();
    }
    //Add this entity to the list as an Reference.
    alPianos.Push(EntIndexToEntRef(index));
}

public bool CleanPianoList(int max) {
    //Returns if another piano can be created.
    int count = alPianos != null ? alPianos.Length : 0;
    if(count <= max) {
        //Return fast as we haven't hit max yet, avoiding the hard 'cpu intensive' for later.
        return true;
    }
    //Clear old invalid refs..
    ArrayList tempPianos = new ArrayList();
    int ref;
    for(int i=0; i < count; i++) {
        ref = alPianos.Get(i);
        if(EntRefToEntIndex(ref) != -1) {
            tempPianos.Push(ref);
        }
    }
    delete alPianos;
    alPianos = tempPianos;
    //We could check to see if tempPianos's list is also empty then delete the handle, but we will end up creating the list again when adding the prop to the list at the end.
    return alPianos.Length <= max;
}