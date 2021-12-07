#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#define CT_TEAM 3
#define TR_TEAM 2

ConVar sm_playermodel_color_red_ct;
ConVar sm_playermodel_color_green_ct;
ConVar sm_playermodel_color_blue_ct;
ConVar sm_playermodel_color_alpha_ct;

ConVar sm_playermodel_color_red_tr;
ConVar sm_playermodel_color_green_tr;
ConVar sm_playermodel_color_blue_tr;
ConVar sm_playermodel_color_alpha_tr;

ConVar sm_playermodel_onstart_ct;
ConVar sm_playermodel_onstart_tr;


public Plugin: myinfo = {
        name = "[CS:GO] Team Colors",
        author = "spy",
        description = "Colorize playermodel and your color depending on which team.",
        version = "1.0",
        url = "spy#4948"
};

public OnPluginStart()
{
    
    HookEvent("player_spawn", Event_PlayerSpawn)

    sm_playermodel_onstart_ct = CreateConVar("sm_playermodel_onstart_ct", "models/your_path/example-ct.mdl", "Path a ct's playermodel on round start");
    sm_playermodel_onstart_tr = CreateConVar("sm_playermodel_onstart_tr", "models/your_path/example-ts.mdl", "Path a ts's playermodel on round start");
    
    sm_playermodel_color_red_ct   = CreateConVar("sm_playermodel_color_red_ct",    "0",   "Choose a ct's RED color on round start");
    sm_playermodel_color_green_ct = CreateConVar("sm_playermodel_color_green_ct",  "0",   "Choose a ct's GREEN color on round start");
    sm_playermodel_color_blue_ct  = CreateConVar("sm_playermodel_color_blue_ct",   "255", "Choose a ct's BLUE color on round start");
    sm_playermodel_color_alpha_ct = CreateConVar("sm_playermodel_color_alpha_ct",  "255", "Choose a ct's ALPHA color on round start");
    
    sm_playermodel_color_red_tr   = CreateConVar("sm_playermodel_color_red_tr",    "255", "Choose a ts's RED color on round start");
    sm_playermodel_color_green_tr = CreateConVar("sm_playermodel_color_green_tr",  "0",   "Choose a ts's GREEN color on round start");
    sm_playermodel_color_blue_tr  = CreateConVar("sm_playermodel_color_blue_tr",   "0",   "Choose a ts's BLUE color on round start");
    sm_playermodel_color_alpha_tr = CreateConVar("sm_playermodel_color_alpha_tr",  "255", "Choose a ts's ALPHA color on round start");

    char ctPreModel[PLATFORM_MAX_PATH];
    char trPreModel[PLATFORM_MAX_PATH];
    GetConVarString(sm_playermodel_onstart_ct, ctPreModel, sizeof(ctPreModel));
    GetConVarString(sm_playermodel_onstart_tr, trPreModel, sizeof(trPreModel));

    PrecacheModel(ctPreModel, true);
    PrecacheModel(trPreModel, true);
    AutoExecConfig(true, "TeamColors-1.0");
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
    char ctModel[PLATFORM_MAX_PATH];
    char trModel[PLATFORM_MAX_PATH];
    
    int ctColorRED   = GetConVarInt(sm_playermodel_color_red_ct);
    int ctColorGREEN = GetConVarInt(sm_playermodel_color_green_ct);
    int ctColorBLUE  = GetConVarInt(sm_playermodel_color_blue_ct);
    int ctColorALPHA = GetConVarInt(sm_playermodel_color_alpha_ct);
    
    int trColorRED   = GetConVarInt(sm_playermodel_color_red_tr);
    int trColorGREEN = GetConVarInt(sm_playermodel_color_green_tr);
    int trColorBLUE  = GetConVarInt(sm_playermodel_color_blue_tr);
    int trColorALPHA = GetConVarInt(sm_playermodel_color_alpha_tr);
   
    GetConVarString(sm_playermodel_onstart_ct, ctModel, sizeof(ctModel));
    GetConVarString(sm_playermodel_onstart_tr, trModel, sizeof(trModel));

    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if(IsPlayerAlive(client))
    {
      switch (GetClientTeam(client))
      {
         case CT_TEAM: SetEntityModel(client, ctModel), SetEntityRenderColor(client, ctColorRED, ctColorGREEN, ctColorBLUE, ctColorALPHA);
         case TR_TEAM: SetEntityModel(client, trModel), SetEntityRenderColor(client, trColorRED, trColorGREEN, trColorBLUE, trColorALPHA);
      }
   }
}