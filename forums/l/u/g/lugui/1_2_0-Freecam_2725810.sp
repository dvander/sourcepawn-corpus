#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>

#undef REQUIRE_PLUGIN
#include <smac>

public Plugin myinfo = {
	name = "Free Cam",
	author = "lugui",
	description = "Allows you to Position a camera outside of your player model.",
	version = "1.2.0",
}

int beamSprite;
int beamHalo;

bool freeCamEnabled[MAXPLAYERS + 1];
bool cameraControllEnabled[MAXPLAYERS + 1];
int lastButtons[MAXPLAYERS + 1];
int clientCameraRef[MAXPLAYERS + 1];
float cameraPos[MAXPLAYERS + 1][3];
float cameraForce[MAXPLAYERS + 1][3];
float cameraAng[MAXPLAYERS + 1][3];
float lastClientAngle[MAXPLAYERS + 1][3];

char cameraModelStr[] = "models/props_spytech/security_camera.mdl";

ConVar fc_maxCameraDistance;
ConVar fc_cameraSpeed;
ConVar fc_displayBoundary;
ConVar fc_collide;

public OnPluginStart() {
    PrecacheModel(cameraModelStr, true);
    beamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
    beamHalo = PrecacheModel("materials/sprites/halo.vmt");

    RegAdminCmd("sm_fc", Command_FreeCam, ADMFLAG_ROOT, "FreeCam");
    RegAdminCmd("sm_freecam", Command_FreeCam, ADMFLAG_ROOT, "FreeCam");

    fc_maxCameraDistance = CreateConVar("fc_maxCameraDistance", "300", "Max distance of the camera from the player.");
    fc_cameraSpeed = CreateConVar("fc_cameraSpeed", "300", "Speed of the camera movement.");
    fc_displayBoundary = CreateConVar("fc_displayBoundary", "0", "How many rings should the Boundary display have.");
    fc_collide = CreateConVar("fc_collide", "0", "Should the camera collide with walls? This can be glitchy.");

    for(int i = 1; i < MaxClients; i ++){
        clientCameraRef[i] = -1;
    }

    HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
}

public void OnAllPluginsLoaded() {
   if(LibraryExists("smac")){
       MarkNativeAsOptional("SMAC_CheatDetected");
   }
}

public void OnPluginEnd() {
    for(int i = 1; i < MaxClients; i ++){
       deleteCamera(i);
    }
}

public OnMapEnd() {
    for(int i = 1; i < MaxClients; i ++){
       disableFreecam(i);
    }
}

public Action Command_FreeCam(client, args){
    if(!IsPlayerAlive(client)){
        ReplyToCommand(client, "You must be alive to use this command!");
        return Plugin_Handled;
    }

    int team = GetClientTeam(client);
    if(team < 2){
        ReplyToCommand(client, "You must be on a team use this command!");
        return Plugin_Handled;
    }

    freeCamEnabled[client] = !freeCamEnabled[client];

    if(freeCamEnabled[client]){
        PrintHintText(client, "[Free Cam] Press Reload to control camera.");
        PrintToChat(client, "[Free Cam] Enabled. Press Reload to control camera.");
        createCamera(client);
    } else {
        PrintToChat(client, "FreeCam disabled.");
        disableFreecam(client);
    }
    return Plugin_Handled;
}

public OnClientPutInServer(client) {
    freeCamEnabled[client] = false;
}

public void OnClientDisconnect (int client) {
    disableFreecam(client);
}

bool createCamera(int client){
    if(clientCameraRef[client] > -1) {
        SetFailState("Unable to create camera. Camera already exists for client %d", client);
        return false;
    }

    int camera = CreateEntityByName("generic_actor");
    if(!IsValidEntity(camera)){
        SetFailState("Unable to create camera. Camera already exists for client %d", client);
        return false;
    }

    DispatchKeyValue(camera, "model", cameraModelStr);
    DispatchKeyValue(camera, "targetname", "freecam");
    SetEntPropEnt(camera, Prop_Send, "m_hOwnerEntity", client);
    if(!DispatchSpawn(camera)) {
        SetFailState("Unable to create camera. Can't DispatchSpawn", client);
        return false;
    }
    if(fc_collide.BoolValue){
        SetEntityMoveType(camera, MOVETYPE_FLY);
    } else {
        SetEntityMoveType(camera, MOVETYPE_NOCLIP);
    }

    SetEntityRenderMode(camera, RENDER_TRANSCOLOR);
    SetEntityRenderColor(camera, 255, 255 ,255, 0);

    RequestFrame(Frame_CameraSpawnPost, EntIndexToEntRef(client));
    SetEntProp(client, Prop_Send, "m_iObserverMode", 1);

    TeleportEntity(camera, cameraPos[client], cameraAng[client], NULL_VECTOR);

    clientCameraRef[client] = EntIndexToEntRef(camera);

    SetClientViewEntity(client, camera);

    return true;
}

public void Frame_CameraSpawnPost(int cRef){
    int client = EntRefToEntIndex(cRef)
    if(isValidClient(client, true)){
        SetVariantInt(1);
        AcceptEntityInput(client, "SetForcedTauntCam");
        int camera = EntRefToEntIndex(clientCameraRef[client]);
        GetClientEyePosition(client, cameraPos[client]);
        GetClientEyeAngles(client, cameraAng[client]);
        TeleportEntity(camera, cameraPos[client], cameraAng[client], NULL_VECTOR);
        CreateTimer(0.1, Timer_RevertTPCamera, EntIndexToEntRef(client));
	}
}

public Action Timer_RevertTPCamera(Handle timer, int cRef){
    int client = EntRefToEntIndex(cRef)
    if(isValidClient(client, true)){
        SetVariantInt(0);
        AcceptEntityInput(client, "SetForcedTauntCam");

        int camera = EntRefToEntIndex(clientCameraRef[client]);
        GetClientEyePosition(client, cameraPos[client]);
        GetClientEyeAngles(client, cameraAng[client]);
        TeleportEntity(camera, cameraPos[client], cameraAng[client], NULL_VECTOR);
	}
}

public Event_PlayerDeath(Handle event, const char[] name, bool dontBroadcast) {
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    disableFreecam(client);
}

void disableFreecam(int client) {
    if(freeCamEnabled[client]){
        PrintToChat(client, "FreeCam disabled");
    }
    freeCamEnabled[client] = false;
    deleteCamera(client);
}

void deleteCamera(int client){
    int camera = EntRefToEntIndex(clientCameraRef[client]);
    if(!IsValidEntity(camera)){
        // SetFailState("Unable to delete camera. Camera Ref %d doesn't exist", clientCameraRef[client]);
        return;
    }
    SetEntProp(client, Prop_Send, "m_iObserverMode", 0);
    SetClientViewEntity(client, client);
    RemoveEntity(camera);

    clientCameraRef[client] = -1;
    cameraControllEnabled[client] = false;
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2]) {
    if(freeCamEnabled[client]){

        if(buttons & IN_RELOAD && !(lastButtons[client] & IN_RELOAD)) {
            cameraControllEnabled[client] = !cameraControllEnabled[client];
            PrintHintText(client, "Camera Control %s.", cameraControllEnabled[client]? "enabled" : "disabled");
        }

        int camera = EntRefToEntIndex(clientCameraRef[client]);

        float newPos[3];
        GetEntPropVector(camera, Prop_Send, "m_vecOrigin", cameraPos[client]);
        newPos = cameraPos[client];

        float clientPos[3];
        GetClientEyePosition(client, clientPos);

        float newForce[3];
        newForce = NULL_VECTOR;

        if(cameraControllEnabled[client]) {
            // PrintToChat(client, "%d, %d", mouse[0], mouse[1]);
            cameraAng[client][0] += mouse[1] / 30;
            cameraAng[client][1] -= mouse[0] / 30;

            // PrintToChat(client, "%016b, %d", buttons, camera);
        
            if(buttons & IN_FORWARD) {
                getDirectionVector(cameraPos[client], cameraAng[client], newForce, 300.0, fc_cameraSpeed.FloatValue);
            }
            if(buttons & IN_BACK) {
                getDirectionVector(cameraPos[client], cameraAng[client], newForce, -300.0, fc_cameraSpeed.FloatValue);
            }
            if(buttons & IN_MOVELEFT) {
                float tmpAng[3];
                tmpAng = cameraAng[client];
                tmpAng[0] = 0.0;
                tmpAng[1] += 90;
                tmpAng[2] = 0.0;
                getDirectionVector(cameraPos[client], tmpAng, newForce, 300.0, fc_cameraSpeed.FloatValue);
            }
            if(buttons & IN_MOVERIGHT) {
                float tmpAng[3];
                tmpAng = cameraAng[client];
                tmpAng[0] = 0.0;
                tmpAng[1] += -90;
                tmpAng[2] = 0.0;
                getDirectionVector(cameraPos[client], tmpAng, newForce, 300.0, fc_cameraSpeed.FloatValue);
            }
            if(buttons & IN_JUMP) {
                float tmpAng[3];
                tmpAng = cameraAng[client];
                tmpAng[0] = -90.0;
                getDirectionVector(cameraPos[client], tmpAng, newForce, 150.0, fc_cameraSpeed.FloatValue);
            }
            if(buttons & IN_DUCK) {
                float tmpAng[3];
                tmpAng = cameraAng[client];
                tmpAng[0] = 90.0;
                getDirectionVector(cameraPos[client], tmpAng, newForce, 150.0, fc_cameraSpeed.FloatValue);
            }

            TeleportEntity(client, NULL_VECTOR, lastClientAngle[client], NULL_VECTOR);
        }

        float distance = GetVectorDistance(clientPos, newPos, false);
        if(fc_maxCameraDistance.FloatValue > 0 && distance > fc_maxCameraDistance.FloatValue ) {
            float newVec[3];
            SubtractVectors(clientPos, newPos, newVec);
            NormalizeVector(newVec, newVec);

            float ang[3];
            GetVectorAngles(newVec, ang);

            float desiredForce[3];
            getDirectionVector(cameraPos[client], ang, desiredForce, 300.0, fc_cameraSpeed.FloatValue);

            float clientVelocityVec[3];
            GetEntPropVector(client, Prop_Data, "m_vecVelocity", clientVelocityVec);

            float CameraDistance = GetVectorDistance(clientPos, cameraPos[client]);
            ScaleVector(desiredForce, CameraDistance / GetVectorLength(clientVelocityVec));

            getAngleToTarget(client, clientPos, cameraAng[client]);

            newForce = desiredForce;
            if(fc_displayBoundary.FloatValue > 0){
                buildSphere(client, fc_maxCameraDistance.FloatValue, clientPos, fc_displayBoundary.FloatValue, {255, 0, 0, 255});
            }
        }

        if (distance > fc_maxCameraDistance.FloatValue + 200) {
            disableFreecam(client);
        }
        cameraForce[client] = newForce;

        if(cameraControllEnabled[client]) {
            lastButtons[client] = buttons;
            return Plugin_Handled;
        }
    } else {
        cameraControllEnabled[client] = false;
    }
    lastButtons[client] = buttons;
    return Plugin_Continue;
}

getAngleToTarget(int client, float clientPos[3], float newAng[3]) {
	clientPos[2] += 30 + Pow(GetVectorDistance(cameraPos[client], clientPos), 2.0) / 10000;

	float newVec[3];
	SubtractVectors(clientPos, cameraPos[client], newVec);
	NormalizeVector(newVec, newVec);

	GetVectorAngles(newVec, newAng);

}

public OnGameFrame() {
    for(int client = 1; client < MaxClients; client++){
        int camera = EntRefToEntIndex(clientCameraRef[client]);
        if(!IsValidEntity(camera) || !freeCamEnabled[client]){
            continue;
        }

        float clientPos[3];
        GetClientEyePosition(client, clientPos);

        TeleportEntity(camera, NULL_VECTOR, cameraAng[client], cameraForce[client]);


        if(TF2_IsPlayerInCondition(client, TFCond_Taunting)) {
           disableFreecam(client);
        }

        GetClientEyeAngles(client, lastClientAngle[client]);
    }
}

stock GetForward(float vPos[3], float vAng[3], float vReturn[3], float fDistance) {
    float vDir[3];
    GetAngleVectors(vAng, vDir, NULL_VECTOR, NULL_VECTOR);
    ScaleVector(vDir, fDistance);
    AddVectors(vPos, vDir, vReturn);
}

void getDirectionVector(float pos1[3], float angle[3], float rVec[3], float distance, float force) {
	float endPos[3];
	GetForward(pos1, angle, endPos, distance);

	MakeVectorFromPoints(pos1, endPos, rVec);
	NormalizeVector(rVec, rVec);

	ScaleVector(rVec, force);
}

#if defined _smac_included
public Action SMAC_OnCheatDetected(int client, const char[] module, DetectionType type, Handle info) {
	return ( type == Detection_Speedhack && freeCamEnabled[client] && cameraControllEnabled[client] ) ? Plugin_Stop : Plugin_Continue;
}
#endif


stock bool isValidClient(int client, bool allowBot = false) {
	if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) || IsClientSourceTV(client) || (!allowBot && IsFakeClient(client) ) ){
		return false;
	}
	return true;
}

stock int buildCircle(int client, float origin[3], float radius, float time, int color[4]){
    TE_SetupBeamRingPoint(origin, radius * 2, radius * 2 + 0.1, beamSprite, beamHalo, 0, 0, time, 5.0, 0.0, color, 1, 0);
    TE_SendToClient (client);
    return 0;
}


stock void buildSphere(int client, float r, float center[3], float stepDiv, int color[4]) {
    float div = (stepDiv / 2);
    if(div <= 1){
        div = 1.0;
    }
    float step = r / div;
    float h = 0.0;
    
    float coord[3];
    coord = center;
    coord[2] -= r;
    
    while (h < r){
        float sectionRadius = SquareRoot(h * (2 * r - h));
        sectionRadius + 3.0;
        buildCircle(client, coord, sectionRadius, 0.2, color);
        coord[2] += step;
        h += step;
    }
    h = r;
    coord = center;
    while (h > 0){
        float sectionRadius = SquareRoot(h * (2 * r - h));
        sectionRadius + 3.0;
        buildCircle(client, coord, sectionRadius, 0.2, color);
        coord[2] += step;
        h -= step;
    }
}
