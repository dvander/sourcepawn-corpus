//INCLUDES
#include <sourcemod>
#include <sdktools>
#include <tf2jail>
#include <colorvariables>

//DEFINES
#define VERSION "1.4.0"
#define PLUGIN_TAG "{dodgerblue}[{valve}JL{dodgerblue}]\x01 "

//PRAGMAS
#pragma semicolon 1
#pragma newdecls required

//PLUGIN INFO
public Plugin myinfo =
{
    name = "JailLazer",
    author = "MitchDizzle_/FliX",
    description = "Allows warden to draw on walls.",
    version = VERSION,
    url = "http://forums.alliedmods.net/showthread.php?t=189956"
}

//GLOBAL VARIABLES
int g_DefaultColors_c[7][4] = { {255,255,255,255}, {255,0,0,255}, {0,255,0,255}, {0,0,255,255}, {255,255,0,255}, {0,255,255,255}, {255,0,255,255} };
int g_sprite;

float LastLaser[MAXPLAYERS+1][3];
float maxGrantTime = 120.0;

bool LaserE[MAXPLAYERS+1] = {false, ...};
bool WardenTest[MAXPLAYERS + 1] = false;
bool GrantTest[MAXPLAYERS + 1] = false;

Handle GrantedTimers[MAXPLAYERS + 1];

public void OnPluginStart() {
	//CONVARS
    CreateConVar("sm_jaillazer_version", VERSION, "Current Plugin Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
    
    //COMMANDS
    RegConsoleCmd("+laser", CMD_laser_p);
    RegConsoleCmd("-laser", CMD_laser_m);
    RegConsoleCmd("sm_wgrant", CMD_laser_wardengrant);
    RegConsoleCmd("sm_wardengrant", CMD_laser_wardengrant);
    RegAdminCmd("sm_grant", CMD_laser_grant, ADMFLAG_BAN);
    RegAdminCmd("sm_revoke", CMD_laser_revoke, ADMFLAG_BAN);
    RegAdminCmd("sm_checklazers", GrantedUsers, ADMFLAG_GENERIC);
}

public void OnMapStart() 
{
    g_sprite = PrecacheModel("materials/sprites/laserbeam.vmt");
    CreateTimer(0.1, Timer_Pay, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public void OnClientPutInServer(int client)
{
    LaserE[client] = false;
    LastLaser[client][0] = 0.0;
    LastLaser[client][1] = 0.0;
    LastLaser[client][2] = 0.0;
}
public Action Timer_Pay(Handle timer)
{
    float pos[3];
    int Color = GetRandomInt(0,6);
    for(int Y = 1; Y <= MaxClients; Y++) 
    {
        if(IsClientInGame(Y) && LaserE[Y])
        {
            TraceEye(Y, pos);
            if(GetVectorDistance(pos, LastLaser[Y]) > 6.0) {
                LaserP(LastLaser[Y], pos, g_DefaultColors_c[Color]);
                LastLaser[Y][0] = pos[0];
                LastLaser[Y][1] = pos[1];
                LastLaser[Y][2] = pos[2];
            }
        } 
    }
}
public Action CMD_laser_p(int client, int args) 
{
	//Check if client is warden and if client has been granted permission to user lasers.
	if (!TF2Jail_IsWarden(client) && !GrantTest[client])
	{
			CReplyToCommand(client, "%sYou must be warden or have been granted permission to use this feature", PLUGIN_TAG);
			return Plugin_Handled;
	}
	TraceEye(client, LastLaser[client]);
	LaserE[client] = true;
	return Plugin_Handled;
}

public Action CMD_laser_m(int client, int args) {
    LastLaser[client][0] = 0.0;
    LastLaser[client][1] = 0.0;
    LastLaser[client][2] = 0.0;
    LaserE[client] = false;
    return Plugin_Handled;
}
void LaserP(float start[3], float end[3], int color[4]) {
    TE_SetupBeamPoints(start, end, g_sprite, 0, 0, 0, 25.0, 2.0, 2.0, 10, 0.0, color, 0);
    TE_SendToAll();
}
void TraceEye(int client, float pos[3]) {
    float vAngles[3];
    float vOrigin[3];
    GetClientEyePosition(client, vOrigin);
    GetClientEyeAngles(client, vAngles);
    TR_TraceRayFilter(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
    if(TR_DidHit(INVALID_HANDLE)) TR_GetEndPosition(pos, INVALID_HANDLE);
    return;
}
public bool TraceEntityFilterPlayer(int entity, int contentsMask) {
    return (entity > GetMaxClients() || !entity);
}
public Action CMD_laser_grant(int client, int args)
{
    //Check command entered correctly
    if(args < 1)
    {
        CReplyToCommand(client, "%sUsage: sm_grant <name>", PLUGIN_TAG);
        return Plugin_Handled;
    }
    char arg1[32];
    GetCmdArg(1, arg1, sizeof(arg1));
    int target = FindTarget(client, arg1, true, false);
    if(target == -1)
    {
        return Plugin_Handled;
    }
    GrantTest[target] = true;
    char targetname[MAX_NAME_LENGTH];
    char clientname[MAX_NAME_LENGTH];
    GetClientName(target, targetname, sizeof(targetname));
    GetClientName(client, clientname, sizeof(clientname));
    CPrintToChatAll("%s%s has allowed %s to use 'lazers'", PLUGIN_TAG, clientname, targetname);
    return Plugin_Handled;   
}
public Action CMD_laser_revoke(int client, int args)
{
    char arg1[32];
    /*Check if no user to look for*/
    if(args < 1)
    {
        CReplyToCommand(client, "%sUsage: sm_revoke <name>", PLUGIN_TAG);
        return Plugin_Handled;
    }
    GetCmdArg(1, arg1, sizeof(arg1));
    int target = FindTarget(client, arg1, true, false);
    if(target == -1)
    {
        return Plugin_Handled;
    }
    GrantTest[target] = false;
    char targetname[MAX_NAME_LENGTH];
    char clientname[MAX_NAME_LENGTH];
    GetClientName(target, targetname, sizeof(targetname));
    GetClientName(client, clientname, sizeof(clientname));
    CPrintToChatAll("%s%s has revoked %s's permission to use 'lazers'", PLUGIN_TAG, clientname, targetname);
    return Plugin_Handled;
    
}
public Action CMD_laser_wardengrant(int client, int args)
{
    WardenTest[client] = TF2Jail_IsWarden(client);
    if(WardenTest[client] == false)
    { 
        CReplyToCommand(client, "%sYou must be warden to use this command", PLUGIN_TAG);
        return Plugin_Handled;
    }
    
    char arg1[32];
    char arg2[32];
    /*Check if no user to look for*/
    if(args < 2)
    {
        CReplyToCommand(client, "%sUsage: sm_wardengrant <name> [duration]", PLUGIN_TAG);
        return Plugin_Handled;
    }
    GetCmdArg(1, arg1, sizeof(arg1));
    GetCmdArg(2, arg2, sizeof(arg2));
    int target = FindTarget(client, arg1, true, false);
    if(target == -1)
    {
        return Plugin_Handled;
    }
    int lazer_timer = StringToInt(arg2);
    if(lazer_timer > maxGrantTime)
    {
        CReplyToCommand(client, "%sMaximum time allowed is %.0f seconds.", PLUGIN_TAG, maxGrantTime);
        return Plugin_Handled;
    }
    
    GrantTest[target] = true;
    GrantedTimers[target] = CreateTimer(float(lazer_timer), wardenrevoke, target);
    char targetname[MAX_NAME_LENGTH];
    char clientname[MAX_NAME_LENGTH];
    GetClientName(target, targetname, sizeof(targetname));
    GetClientName(client, clientname, sizeof(clientname));
    CPrintToChatAll("%s%s has allowed %s to use 'lazers' for %d seconds", PLUGIN_TAG, clientname, targetname, lazer_timer);
    return Plugin_Handled;
    
}
public void OnClientDisconnect(int client)
{
    if(GrantTest[client])
    {
        KillTimer(GrantedTimers[client]);
        GrantedTimers[client] = null;
    }
}
public Action wardenrevoke(Handle timer, any target)
{
    GrantTest[target] = false;
    GrantedTimers[target] = null;
    CPrintToChat(target, "%sYour permission to use 'lazers' has been revoked automatically", PLUGIN_TAG);
}

public Action GrantedUsers(int client, int args)
{
    CReplyToCommand(client, "{powderblue}--------------------------------");
    CReplyToCommand(client, "{dodgerblue}All Users with permission to user lazers:");
    for(int i = 0; i < MAXPLAYERS; i++)
    {
        if(GrantTest[i])
        {
            ReplyToCommand(client,"%s{darkorchid}%N",PLUGIN_TAG, i);
		}
        
    }
    CReplyToCommand(client, "{powderblue}--------------------------------");
    return Plugin_Handled; 
}

