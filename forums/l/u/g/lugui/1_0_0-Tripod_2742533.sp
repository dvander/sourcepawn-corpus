#include <sourcemod>
#include <sdktools>

public Plugin myinfo = {
	name = "Tripod",
	author = "lugui",
	description = "Holds the camera for you.",
	version = "1.0.0",
}


bool freeCamEnabled[MAXPLAYERS + 1];
int clientCameraRef[MAXPLAYERS + 1];
float cameraPos[MAXPLAYERS + 1][3];
float cameraAng[MAXPLAYERS + 1][3];

char cameraModelStr[] = "models/props_spytech/security_camera.mdl";

public OnPluginStart() {
    PrecacheModel(cameraModelStr, true);

    RegAdminCmd("sm_tripod", Command_FreeCam, ADMFLAG_ROOT, "Enables the tripod");

    for(int i = 1; i < MaxClients; i ++){
        clientCameraRef[i] = -1;
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
        createCamera(client);
    } else {
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

    SetEntityMoveType(camera, MOVETYPE_NOCLIP);


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
        if(freeCamEnabled[client]){
            int camera = EntRefToEntIndex(clientCameraRef[client]);
            GetClientEyePosition(client, cameraPos[client]);
            GetClientEyeAngles(client, cameraAng[client]);
            TeleportEntity(camera, cameraPos[client], NULL_VECTOR, NULL_VECTOR);
        }
	}
}

void disableFreecam(int client) {
    freeCamEnabled[client] = false;
    CreateTimer(0.1, Timer_RevertTPCamera, EntIndexToEntRef(client));
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
}

stock bool isValidClient(int client, bool allowBot = false) {
	if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) || IsClientSourceTV(client) || (!allowBot && IsFakeClient(client) ) ){
		return false;
	}
	return true;
}
