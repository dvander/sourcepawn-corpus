/* SCSkins.sp

Description: custom player skins.

*/

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "2.0.1"
#define MAX_FILE_LEN 256

public Plugin:myinfo = 
{
    name = "simplecustomskins",
    author = "Meng",
    version = "PLUGIN_VERSION",
    description = "Simple Skin Changer",
    url = ""
};

new Handle:g_enabled = INVALID_HANDLE;
new Handle:g_skinpublic = INVALID_HANDLE;
new Handle:g_adminonly = INVALID_HANDLE;
new Handle:g_customctskin_pub = INVALID_HANDLE;
new Handle:g_customctskin_adm = INVALID_HANDLE;
new Handle:g_customtskin_pub = INVALID_HANDLE;
new Handle:g_customtskin_adm = INVALID_HANDLE;
new String:g_ctskin_pub[MAX_FILE_LEN];
new String:g_ctskin_adm[MAX_FILE_LEN];
new String:g_tskin_pub[MAX_FILE_LEN];
new String:g_tskin_adm[MAX_FILE_LEN];

public OnPluginStart()
{
    CreateConVar("simplecustomskins_version", PLUGIN_VERSION, "simplecustomskins Version",         FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

    g_enabled = CreateConVar("scs_enabled", "1", "Set to 1 to enable custom skins");
    g_skinpublic = CreateConVar("scs_pubskins", "1", "Set to 1 to enable custom public skins");
    g_adminonly = CreateConVar("scs_admskins", "1", "Set to 1 to enable admin only skins");
    g_customctskin_pub = CreateConVar("scs_pub_ct", "models/player/ct_urban.mdl", "public ct model");
    g_customctskin_adm = CreateConVar("scs_adm_ct", "models/player/ct_gign.mdl", "admin ct model");
    g_customtskin_pub = CreateConVar("scs_pub_t", "models/player/t_phoenix.mdl", "public t model");
    g_customtskin_adm = CreateConVar("scs_adm_t", "models/player/t_arctic.mdl", "admin t model");

    AutoExecConfig(true, "scs_config");

    HookEvent("player_spawn", EventPlayerSpawn, EventHookMode_Post);
}

public OnMapStart()
{
    decl String:buffer[MAX_FILE_LEN];
    new String:file[256]
    BuildPath(Path_SM, file, 255, "configs/scs_downloads.ini")
    new Handle:fileh = OpenFile(file, "r")
    while (ReadFileLine(fileh, buffer, sizeof(buffer)))
    {
        new len = strlen(buffer)
        if (buffer[len-1] == '\n')
            buffer[--len] = '\0'
        if (FileExists(buffer))
        {
            AddFileToDownloadsTable(buffer)
        }
        if (IsEndOfFile(fileh))
            break
    }
}

public OnConfigsExecuted()
{
    decl String:buffer[MAX_FILE_LEN];
    GetConVarString(g_customctskin_pub, g_ctskin_pub, sizeof(g_ctskin_pub));
    Format(buffer, MAX_FILE_LEN, "%s", g_ctskin_pub);
    PrecacheModel(g_ctskin_pub, true);

    GetConVarString(g_customctskin_adm, g_ctskin_adm, sizeof(g_ctskin_adm));
    Format(buffer, MAX_FILE_LEN, "%s", g_ctskin_adm);
    PrecacheModel(g_ctskin_adm, true);

    GetConVarString(g_customtskin_pub, g_tskin_pub, sizeof(g_tskin_pub));
    Format(buffer, MAX_FILE_LEN, "%s", g_tskin_pub);
    PrecacheModel(g_tskin_pub, true);

    GetConVarString(g_customtskin_adm, g_tskin_adm, sizeof(g_tskin_adm));
    Format(buffer, MAX_FILE_LEN, "%s", g_tskin_adm);
    PrecacheModel(g_tskin_adm, true);
}

SetPublicModel(client)
{
    new team = GetClientTeam(client);
    if (team == 3)
    {
        SetEntityModel(client,g_ctskin_pub);
    }
    else if (team == 2)
    {
        SetEntityModel(client,g_tskin_pub);
    }
}

SetAdminModel(client)
{       
    new team = GetClientTeam(client);
    if (team == 3)
    {
        SetEntityModel(client,g_ctskin_adm);
    }
    else if (team == 2)
    {
        SetEntityModel(client,g_tskin_adm);
    }
}

public Action:EventPlayerSpawn(Handle:event,const String:name[],bool:dontBroadcast)
{       
    if (GetConVarInt(g_enabled))
    {
        new client = GetClientOfUserId(GetEventInt(event, "userid"));
        if (GetConVarInt(g_skinpublic) && GetConVarInt(g_adminonly))
        {
            if (GetUserFlagBits(client) & ADMFLAG_CUSTOM5)
            {
                SetAdminModel(client);
            }
            else
            {
                SetPublicModel(client);
            }
        }    
        else if (!GetConVarInt(g_skinpublic) && GetConVarInt(g_adminonly) && GetUserFlagBits(client) & ADMFLAG_CUSTOM5)
        {
            SetAdminModel(client);    
        }
        else if (GetConVarInt(g_skinpublic) && !GetConVarInt(g_adminonly))
        {
            SetPublicModel(client);
        }
    }
}  