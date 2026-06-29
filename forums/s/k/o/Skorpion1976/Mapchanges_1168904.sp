#include <sourcemod>
#include <sdktools> 
#define MAXNPCS    3000 

static String:NPCPath[128];
static Entys[3000];
new String:MapName[100];

public Plugin:myinfo =
{
	name = "MapChanges",
	author = "Krim, Skorpion1976 & Xx_Faxe_xX",
	description = "Saves Entities",
	version = "1.0",
	url = ""
};

  
public OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart);
     	//PrintToServer("KER: Initializing Krims Entity Restorer");
	CreateConVar("MapChanges_version", "1.0", "MapChanges Version",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
}

stock LoadString(Handle:Vault, const String:Key[32], const String:SaveKey[255], const String:DefaultValue[255], String:Reference[255])
{

	//Jump:
	KvJumpToKey(Vault, Key, false);
	
	//Load:
	KvGetString(Vault, SaveKey, Reference, 255, DefaultValue);

	//Rewind:
	KvRewind(Vault);
}

stock SaveString(Handle:Vault, const String:Key[32], const String:SaveKey[255], const String:Variable[255])
{

	//Jump:
	KvJumpToKey(Vault, Key, true);

	//Save:
	KvSetString(Vault, SaveKey, Variable);

	//Rewind:
	KvRewind(Vault);
}

//Round Start
public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(0.5, items);
}

public Action:items(Handle:timer)
{
	// We define the path + filename
	new client=client;
	GetCurrentMap(MapName, sizeof(MapName));  	// Load current Map name
	BuildPath (Path_SM, NPCPath, sizeof(NPCPath), "data/Maps/%s.txt", MapName);
	CreateTimer(1.0, Command_drawItems);      	// Draw the items
	return;
}

public Action:Command_drawItems(Handle:Timer, any:Value)
{
    //PrintToServer("KER: Loading Entities...");
    decl Handle:Vault;
    decl String:Props[255];

    //Initialize:
    Vault = CreateKeyValues("Vault");

    //Retrieve:
    FileToKeyValues(Vault, NPCPath);
    
    new loadArray[2000] = 0;
    decl String:Temp[15];
    
    //Select Loader
    new Y = 0;
    KvJumpToKey(Vault, "Furn", true);
    KvGotoFirstSubKey(Vault,false);
    do
    {
	KvGetSectionName(Vault, Temp, 15);
	loadArray[Y] = StringToInt(Temp);	
	Y++;

    } while (KvGotoNextKey(Vault,false));
    
    //PrintToServer("KER: Found %d Entities",Y-1);
    KvRewind(Vault);
		
    //Load:
    for(new X = 0; X < Y; X++)
    {
    	if(loadArray[X] == 0)
    	{
    		//PrintToServer("KER: Error at Entity #%d",X);
    		CloseHandle(Vault);
    		return Plugin_Handled;
    	}
    		
        //Declare:
        decl String:NPCId[255];
				
        //Convert:
        IntToString(loadArray[X], NPCId, 255);
        
        //Declare:
        decl String:NPCType[32];

        //Convert:
        NPCType = "Furn";

        //Extract:
        LoadString(Vault, NPCType, NPCId, "Null", Props);
        
        //Found in DB:
        if(StrContains(Props, "Null", false) == -1)
        {
            decl Ent; 
            decl String:Buffer[7][255];
            decl Float:FurnitureOrigin[3];
            decl Float:Angels[3];
            
             //Explode:
            ExplodeString(Props, " ", Buffer, 7, 255);
            
            FurnitureOrigin[0] = StringToFloat(Buffer[0]);
            FurnitureOrigin[1] = StringToFloat(Buffer[1]);
            FurnitureOrigin[2] = StringToFloat(Buffer[2]);
            Angels[0] = StringToFloat(Buffer[4]);
            Angels[1] = StringToFloat(Buffer[5]);
            Angels[2] = StringToFloat(Buffer[6]);
           
            if(strlen(Buffer[3]) > 5) 
            {
	            //PrintToChat(Client,"[IMPORT]: %i %s",X,Buffer[3]);  
	            PrecacheModel(Buffer[3],true);
	            Ent = CreateEntityByName("prop_physics_override"); 
	            DispatchKeyValue(Ent, "model", Buffer[3]);
	            DispatchSpawn(Ent);
	            
	           	//PrintToServer("KER: Loaded %d",loadArray[X]);
	            TeleportEntity(Ent, FurnitureOrigin, Angels, NULL_VECTOR);
	            SetEntProp(Ent, Prop_Data, "m_takedamage", 0, 1)        
	            AcceptEntityInput(Ent, "DisableMotion");
		    //SetEntityMoveType(Ent, MOVETYPE_NONE);
		    SetEntProp(Ent, Prop_Data, "m_CollisionGroup", 0);
	            
	            Entys[Ent] = loadArray[X];
            } else
            {
            	//PrintToServer("KER: Entry %d can not be a valid model",loadArray[X]);
            } 
        }
    }
    //PrintToServer("KER: All Entities loaded");
    CloseHandle(Vault);
    return Plugin_Handled;
}