#include <sourcemod>
#include <sdktools>   
static LaserCache;
static HaloSprite;

public Plugin:myinfo =
{
	name = "RP Tools",
	author = "Krim",
	description = "Tools for a good RPG Admin",
	version = "1.0.0.0",
	url = ""
};

//Map Start:
public OnMapStart()
{
	LaserCache = PrecacheModel("materials/sprites/laserbeam.vmt");
	HaloSprite = PrecacheModel("materials/sprites/halo01.vmt");
}
 
public OnPluginStart()
{
	RegAdminCmd("db_location", Command_getLoc, ADMFLAG_SLAY,"Returns the actual location");
    	RegAdminCmd("db_info", Command_getSkin, ADMFLAG_SLAY,"Returns everything you can know of an entity");   
    	RegAdminCmd("db_dublicate", Command_dublicate, ADMFLAG_SLAY,"Dublicates an Entity");
    	RegAdminCmd("db_create", Command_create, ADMFLAG_SLAY,"Creates an Entity"); 
    	RegAdminCmd("db_create_throw", Command_create_throw, ADMFLAG_SLAY,"Creates and Throw an entity"); 
    	RegAdminCmd("db_remove", Command_remove, ADMFLAG_SLAY,"Removes an entity");
	CreateConVar("rp_tools", "1.0", "RP Tools Version",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
}


public Action:Command_getLoc(Client,args)
{
    	decl Float:ClientOrigin[3];
    	GetClientAbsOrigin(Client, ClientOrigin); 
    	PrintToChat(Client, "[Actual Location] %f %f %f",ClientOrigin[0],ClientOrigin[1],ClientOrigin[2]);         
	return Plugin_Handled;
}

public Action:Command_getSkin(Client,args)
{
    decl String:modelname[128];
    decl String:name[128];
    decl Ent;
    Ent = GetClientAimTarget(Client, false);
    GetEdictClassname(Ent, name, sizeof(name));
    GetEntPropString(Ent, Prop_Data, "m_ModelName", modelname, 128);
    PrintToChat(Client, "[SKIN] %s [CLASS] %s [ID] %d",modelname,name,Ent);         
    return Plugin_Handled;
}

public Action:Command_dublicate(Client,args)
{
    decl String:modelname[128];
    decl Ent2;
    Ent2 = GetClientAimTarget(Client, false);
    GetEntPropString(Ent2, Prop_Data, "m_ModelName", modelname, 128);
    
    decl Ent,String:failsafe[255];
    GetCmdArg(1, failsafe, sizeof(failsafe)); 
     
    PrecacheModel(modelname,true);
    
    if(StringToInt(failsafe) == 1)
    	Ent = CreateEntityByName("prop_physics_override"); 
    else
    	Ent = CreateEntityByName("prop_physics"); 
    	 
    DispatchKeyValue(Ent, "physdamagescale", "0.0");
    DispatchKeyValue(Ent, "model", modelname);
    DispatchSpawn(Ent);
   
    decl Float:FurnitureOrigin[3];  
    decl Float:ClientOrigin[3];
    decl Float:EyeAngles[3];
    GetClientEyeAngles(Client, EyeAngles);
    GetClientAbsOrigin(Client, ClientOrigin); 
    FurnitureOrigin[0] = (ClientOrigin[0] + (50 * Cosine(DegToRad(EyeAngles[1]))));
    FurnitureOrigin[1] = (ClientOrigin[1] + (50 * Sine(DegToRad(EyeAngles[1]))));
    FurnitureOrigin[2] = (ClientOrigin[2] + 100);

    TeleportEntity(Ent, FurnitureOrigin, NULL_VECTOR, NULL_VECTOR);
    SetEntityMoveType(Ent, MOVETYPE_VPHYSICS);  
    //SetEntProp(Ent, Prop_Data, "m_fFlags", 1048576);   
    return Plugin_Handled;
}

public Action:Command_create_throw(Client,Args)
{
    if(Args < 1)
    {
        PrintToConsole(Client, "Usage: db_create <model> [FAILSAFE]");
        return Plugin_Handled;
    }
    decl String:modelname[255],String:failsafe[255];
    GetCmdArg(1, modelname, sizeof(modelname));
    GetCmdArg(2, failsafe, sizeof(failsafe));
    
    decl Ent;   
    PrecacheModel(modelname,true);
    if(StringToInt(failsafe) == 1)
    	Ent = CreateEntityByName("prop_physics_override"); 
    else
    	Ent = CreateEntityByName("prop_physics"); 
    DispatchKeyValue(Ent, "physdamagescale", "0.0");
    DispatchKeyValue(Ent, "model", modelname);
    DispatchSpawn(Ent);
    
    decl Float:FurnitureOrigin[3];  
    decl Float:ClientOrigin[3];
    decl Float:EyeAngles[3];
    decl Float:Push[3];
    
    GetClientEyeAngles(Client, EyeAngles);
    GetClientAbsOrigin(Client, ClientOrigin); 
    
    Push[0] = (5000.0 * Cosine(DegToRad(EyeAngles[1])));
    Push[1] = (5000.0 * Sine(DegToRad(EyeAngles[1])));
    Push[2] = (-12000.0 * Sine(DegToRad(EyeAngles[0])));
    
    FurnitureOrigin[0] = (ClientOrigin[0] + (50 * Cosine(DegToRad(EyeAngles[1]))));
    FurnitureOrigin[1] = (ClientOrigin[1] + (50 * Sine(DegToRad(EyeAngles[1]))));
    FurnitureOrigin[2] = (ClientOrigin[2]);
   
    new AltBeamColor[4] = {255, 100, 100, 200}; 
    TE_SetupBeamFollow(Ent, LaserCache, HaloSprite, 1.0, 8.0, 8.0, 1000, AltBeamColor);
    TE_SendToAll();
    
    PrintToChat(Client,"T: %f %f %f",Push[0],Push[1],Push[2]);            
    TeleportEntity(Ent, FurnitureOrigin, NULL_VECTOR, Push);
    IgniteEntity(Ent, 5.0);
    SetEntityMoveType(Ent, MOVETYPE_VPHYSICS);   
    //SetEntProp(Ent, Prop_Data, "m_fFlags", 1048576);  
    return Plugin_Handled;
}

public Action:Command_create(Client,Args)
{
    if(Args < 1)
    {
        PrintToConsole(Client, "Usage: db_create <model> [FAILSAFE]");
        return Plugin_Handled;
    }
    
    decl String:modelname[255],String:failsafe[255];
    GetCmdArg(1, modelname, sizeof(modelname));
    GetCmdArg(2, failsafe, sizeof(failsafe));
    
    decl Ent;   
    PrecacheModel(modelname,true);
    if(StringToInt(failsafe) == 1)
    	Ent = CreateEntityByName("prop_physics_override"); 
    else
    	Ent = CreateEntityByName("prop_physics"); 
    DispatchKeyValue(Ent, "physdamagescale", "0.0");
    DispatchKeyValue(Ent, "model", modelname);
    DispatchSpawn(Ent);
    
    decl Float:FurnitureOrigin[3];  
    decl Float:ClientOrigin[3];
    decl Float:EyeAngles[3];
    GetClientEyeAngles(Client, EyeAngles);
    GetClientAbsOrigin(Client, ClientOrigin); 
    FurnitureOrigin[0] = (ClientOrigin[0] + (50 * Cosine(DegToRad(EyeAngles[1]))));
    FurnitureOrigin[1] = (ClientOrigin[1] + (50 * Sine(DegToRad(EyeAngles[1]))));
    FurnitureOrigin[2] = (ClientOrigin[2] + 100);
                 
    TeleportEntity(Ent, FurnitureOrigin, NULL_VECTOR, NULL_VECTOR);
    SetEntityMoveType(Ent, MOVETYPE_VPHYSICS);   
    //SetEntProp(Ent, Prop_Data, "m_fFlags", 1048576);  
    return Plugin_Handled;
}

public Action:Command_remove(Client,args)
{
    decl Ent2
    Ent2 = GetClientAimTarget(Client, false); 
    if (IsValidEntity(Ent2))
    {
        RemoveEdict(Ent2);
    }
    return Plugin_Handled;
}