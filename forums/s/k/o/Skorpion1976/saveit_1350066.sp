#include <sourcemod>
#include <sdktools> 
#define MAXNPCS    3000 

static String:NPCPath[128];
static lastID = 0;
static Entys[3000];    
public Plugin:myinfo =
{
	name = "Entity Locker",
	author = "Krim",
	description = "Saves Entitys",
	version = "1.3.0.0",
	url = ""
};

  
public OnPluginStart()
{
	RegAdminCmd("sm_save", Command_Saveit, ADMFLAG_SLAY,"Point and Go :)");
    	RegAdminCmd("sm_delete", CommandRemoveEnt, ADMFLAG_SLAY,"Point and Go :)");
    	RegAdminCmd("sm_walkthru", Command_walkthru, ADMFLAG_SLAY,"Point and Go :)");
       
    	//NPC DB:
    	BuildPath(Path_SM, NPCPath, 64, "data/maps/map.txt");
    	if(FileExists(NPCPath) == false) PrintToConsole(0, "[SM] ERROR: Missing file '%s'", NPCPath);
     	PrintToServer("KER: Initializing Krims Entity Restorer");
	CreateConVar("ker_version", "1.3", "Krims Entity Restorer Version",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
    	Command_lastID();  
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

//Map Start:
public OnMapStart()
{
    CreateTimer(1.0, Command_drawItems);     
}

public Action:Command_walkthru(Client,args)
{
    decl Ent;
    Ent = GetClientAimTarget(Client, false);
    
    PrintToChat(Client,"Old Collision: %d",GetEntProp(Ent, Prop_Data, "m_CollisionGroup"));
    if(Ent != -1 && Ent < 0 && Ent > GetMaxClients())
    {
    	decl String:level[255];
    	GetCmdArg(1, level, sizeof(level));
    	SetEntProp(Ent, Prop_Data, "m_CollisionGroup", StringToInt(level));	
    }
    return Plugin_Handled;
}

public Action:Command_Saveit(Client,args)
{
    decl Ent;
    Ent = GetClientAimTarget(Client, false);
    
    if(Ent != -1 || Ent < 0 || Ent > GetMaxClients())
    {
        decl String:modelname[128];
        decl String:Buffers[7][128];    
        decl Float:Origin[3];
        decl Float:Angels[3]; 
        decl String:SaveBuffer[255], String:NPCId[255];
        decl Handle:Vault;   
        
        GetEntPropString(Ent, Prop_Data, "m_ModelName", modelname, 128);
        if(strlen(modelname) < 5)
        {
        	PrintToChat(Client,"[KER]: Model doesnt seem to be correct: %s",modelname);
        	return Plugin_Handled; 
        }
        
        GetEntPropVector(Ent, Prop_Data, "m_vecOrigin", Origin);
        GetEntPropVector(Ent, Prop_Data, "m_angRotation", Angels);
        
        
        IntToString(RoundFloat(Origin[0]), Buffers[0], 32);   
        IntToString(RoundFloat(Origin[1]), Buffers[1], 32);
        IntToString(RoundFloat(Origin[2]), Buffers[2], 32);
        IntToString(RoundFloat(Angels[0]), Buffers[4], 32);
        IntToString(RoundFloat(Angels[1]), Buffers[5], 32);
        IntToString(RoundFloat(Angels[2]), Buffers[6], 32);    
        Buffers[3] = modelname;
        
        ImplodeStrings(Buffers, 7, " ", SaveBuffer, 255);
        
        lastID++;
        
        PrintToChat(Client,"[KER]: Save #%i: Properties: %s",lastID,SaveBuffer);
        
        Vault = CreateKeyValues("Vault");

        IntToString(lastID,NPCId,32);
        FileToKeyValues(Vault, NPCPath); 
        SaveString(Vault, "Furn", NPCId, SaveBuffer);
        KeyValuesToFile(Vault, NPCPath);
        CloseHandle(Vault);
        
        SetEntProp(Ent, Prop_Data, "m_takedamage", 0, 1)        
        SetEntityMoveType(Ent, MOVETYPE_NONE); 
        
        Entys[Ent] = lastID; 
    }
    return Plugin_Handled;  
}

public bool:Command_lastID()
{
    decl Handle:Vault;

    //Initialize:
    Vault = CreateKeyValues("Vault");

    //Retrieve:
    FileToKeyValues(Vault, NPCPath);
    
    new Y = 0;
    decl String:Temp[15];
    
    KvJumpToKey(Vault, "Furn", true);
    KvGotoFirstSubKey(Vault,false);
    do
    {
	KvGetSectionName(Vault, Temp, 15);
	Y = StringToInt(Temp);
	if(Y > lastID) lastID = Y;
			
    } while (KvGotoNextKey(Vault,false));
    
    PrintToServer("KER: new lastID: #%d",lastID);
    CloseHandle(Vault);
    return true;
}

public Action:Command_drawItems(Handle:Timer, any:Value)
{
    PrintToServer("KER: Loading Entities...");
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
    
    PrintToServer("KER: Found %d Entities",Y-1);
    KvRewind(Vault);
		
    //Load:
    for(new X = 0; X < Y; X++)
    {
    	if(loadArray[X] == 0)
    	{
    		PrintToServer("KER: Error at Entity #%d",X);
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
	            SetEntityMoveType(Ent, MOVETYPE_NONE);
		    SetEntProp(Ent, Prop_Data, "m_CollisionGroup", 0);
	            
	            Entys[Ent] = loadArray[X];
            } else
            {
            	PrintToServer("KER: Entry %d can not be a valid model",loadArray[X]);
            } 
        }
    }
    PrintToServer("KER: All Entities loaded");
    CloseHandle(Vault);
    return Plugin_Handled;
}

public Action:CommandRemoveEnt(Client, Args)
{
    decl Ent;
    Ent = GetClientAimTarget(Client, false);
    
    if(Ent != -1 && Ent > 0 && Ent > GetMaxClients())
    {
        if(Entys[Ent])
        {
            //Vault:
            decl bool:Deleted; 
            decl Handle:Vault;
            Vault = CreateKeyValues("Vault");

            //Retrieve:
            FileToKeyValues(Vault, NPCPath);

            decl String:Buffer[20]
            IntToString(Entys[Ent],Buffer,20);
            
            //Delete:
            KvJumpToKey(Vault, "Furn", false);
            Deleted = KvDeleteKey(Vault, Buffer); 
            KvRewind(Vault);

            //Store:
            KeyValuesToFile(Vault, NPCPath);

            //Print:
            if(!Deleted) PrintToConsole(Client, "[KER] Failed to remove Entity %d from the database", Entys[Ent]);
            else 
            {
                //Print:
                PrintToConsole(Client, "[KER] Removed Entity %d from the database", Entys[Ent]);
                RemoveEdict(Ent);
            }

            //Close:
            CloseHandle(Vault);
        }
    }

    //Return:
    return Plugin_Handled;
}

