#pragma semicolon 1
#define PL_VERSION "1.1"

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define BANANA_MODEL "models/props/cs_italy/orange.mdl"

#define CLR_DEFAULT 1
#define CLR_GREEN   4

public Plugin:myinfo =
{
    name        = "Banana Bombs",
    author      = "Steell",
    description = "Replaces grenade model with a banana model.",
    version     = PL_VERSION,
    url         = ""
}

//Cvars
new Handle:g_CvarAdmin  = INVALID_HANDLE;
new Handle:g_CvarAdvert = INVALID_HANDLE;

//Array of booleans corresponding to each client's ability to use the plugin.
new bool:g_Clients[MAXPLAYERS+1];

public OnPluginStart()
{
    CreateConVar(
        "sm_bananabombs_version",
        PL_VERSION,
        "Replaces grenade model with a banana model.",
        FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_SPONLY
    );
    
    g_CvarAdmin = CreateConVar(
    	"sm_bananabombs_flags",
    	"",
    	"String of admin flags required for clients to use Banana Bombs. If empty, all clients are allowed."
    );
    
    g_CvarAdvert = CreateConVar(
    	"sm_bananabombs_advert",
    	"1",
    	"If enabled, an information message will be displayed at the start of each round.",
    	0, true, 0.0, true, 1.0
    );
    
    AutoExecConfig(true, "banana_bombs");
    
    HookEvent("round_start", Event_RoundStart);
}


public OnMapStart()
{
    PrecacheModel(BANANA_MODEL, true);
}


public OnClientPostAdminCheck(client)
{
	//Get the required flags.
	decl String:adminFlags[64];
	GetConVarString(g_CvarAdmin, adminFlags, sizeof(adminFlags));
	
	//Check if admin flag set
	if(adminFlags[0] != '\0')
	{
		g_Clients[client] = false;
		
		//Check if player has admin flag
		if(GetUserFlagBits(client) & ReadFlagString(adminFlags))
		{
			g_Clients[client] = true;
		}
	}
	else
	{
		g_Clients[client] = true;
	}
}


public OnEntityCreated(entity, const String:classname[])
{
    if (StrEqual(classname, "hegrenade_projectile"))
        CreateTimer(0.01, InitGrenade, entity, TIMER_FLAG_NO_MAPCHANGE);
}


public Action:InitGrenade(Handle:timer, any:grenade)
{
    if (!IsValidEntity(grenade))
        return;
        
    decl String:classname[32];
    GetEdictClassname(grenade, classname, sizeof(classname));
    
    if (!StrEqual(classname, "hegrenade_projectile"))
        return;
        
    new client = GetEntPropEnt(grenade, Prop_Send, "m_hOwnerEntity");
    
    if (client <= 0 || !g_Clients[client])
        return;
        
    SetEntityModel(grenade, BANANA_MODEL);
    SetEntProp(grenade, Prop_Send, "m_clrRender", -1);
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarBool(g_CvarAdvert))
	{
    	PrintToChatAll("%c[BananaBombs]%c All grenades have become banana bombs!",
        	           CLR_GREEN, CLR_DEFAULT);
    }
}