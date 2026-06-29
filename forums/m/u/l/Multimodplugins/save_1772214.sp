#include <sourcemod>
#include <sdktools> 
#define MAXNPCS    3000 

static String:NPCPath[128];
static lastID = 0;
static Entys[3000];
public Plugin:myinfo =
{
	name = "Entity Saver",
	author = "Mulitimod",
	description = "Saves Entitys",
	version = "1.1",
	url = ""
};

  
public OnPluginStart()
{
	RegAdminCmd("sm_save", Command_Save, ADMFLAG_SLAY,"Point and Go :)");
	RegAdminCmd("sm_changeskin", Command_Skin, ADMFLAG_SLAY, "Change Skin of a prop");
	RegAdminCmd("sm_changecolor", Command_Color, ADMFLAG_SLAY, "Change Color of a prop");
    	RegAdminCmd("sm_remove", CommandRemoveEnt, ADMFLAG_SLAY,"Point and Go :)");
    	RegAdminCmd("sm_walkthru", Command_walkthru, ADMFLAG_SLAY,"Point and Go :)");

     	PrintToServer("SAVE: Initializing Multimods Entity Saver");
	CreateConVar("save_version", "1.1", "Multimods Entity Saver",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
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
	decl String:MapName[128], String:FinalPathF[128];
	GetCurrentMap(MapName, 128);
	Format(FinalPathF, sizeof(FinalPathF), "data/roleplay/%s/furni.txt", MapName);

    	BuildPath(Path_SM, NPCPath, 128, FinalPathF);
    	if(FileExists(NPCPath) == false) PrintToConsole(0, "[SM] ERROR: Missing file '%s'", NPCPath);

	//Clear Data From Previous Maps:
	for(new X = 0; X < 3000; X++)
	{
		Entys[X] = 0;
	}

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

public Action:Command_Save(Client,args)
{
    decl Ent;
    Ent = GetClientAimTarget(Client, false);
    
    if(Ent != -1 && Ent > GetMaxClients())
    {
        decl String:modelname[128];
        decl String:Buffers[7][128];    
        decl Float:Origin[3];
        decl Float:Angels[3]; 
        decl String:SaveBuffer[255];
        
        GetEntPropString(Ent, Prop_Data, "m_ModelName", modelname, 128);
        if(strlen(modelname) < 5)
        {
        	PrintToChat(Client,"[SAVE]: Model doesnt seem to be correct: %s",modelname);
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
        
	lastID++;

        ImplodeStrings(Buffers, 7, " ", SaveBuffer, 255);

        decl String:NPCId[255];
        IntToString(lastID, NPCId, 255);
	
        decl String:NPCType[32];
        NPCType = "Furn";

	decl String:Props[255];

	decl Handle:Vault;
	Vault = CreateKeyValues("Vault");
	FileToKeyValues(Vault, NPCPath);
        LoadString(Vault, NPCType, NPCId, "Null", Props);

        if(StrEqual(Props, "Null", false))
        {
	        SaveString(Vault, "Furn", NPCId, SaveBuffer);
        	KeyValuesToFile(Vault, NPCPath);
	        CloseHandle(Vault);

        	SetEntProp(Ent, Prop_Data, "m_takedamage", 0, 1);  
		AcceptEntityInput(Ent, "DisableMotion");
        
        	Entys[Ent] = lastID;
		PrintToChat(Client,"[SAVE]: Save #%i: Properties: %s",lastID,SaveBuffer);
		return Plugin_Handled;
	}
	//PrintToChat(Client, "[SAVE] Detected Already Used ID. Finding another open ID.");
	CloseHandle(Vault);
	WriteID(Client, SaveBuffer, Ent);
	return Plugin_Handled;
    }
    PrintToChat(Client, "[SAVE] Error. Invalid Entity.");
    return Plugin_Handled;
}

stock WriteID(Client, String:SaveBuffer2[255], Ent)
{
	lastID++;
        decl String:NPCId[255];
        IntToString(lastID, NPCId, 255);
	
        decl String:NPCType[32];
        NPCType = "Furn";

	decl String:Props[255];

	decl Handle:Vault;
	Vault = CreateKeyValues("Vault");
	FileToKeyValues(Vault, NPCPath);
        LoadString(Vault, NPCType, NPCId, "Null", Props);

        if(StrEqual(Props, "Null", false))
        {
	        SaveString(Vault, "Furn", NPCId, SaveBuffer2);
        	KeyValuesToFile(Vault, NPCPath);
	        CloseHandle(Vault);

        	SetEntProp(Ent, Prop_Data, "m_takedamage", 0, 1);
		AcceptEntityInput(Ent, "DisableMotion");
        
        	Entys[Ent] = lastID;
		PrintToChat(Client, "[SAVE]: Save #%i: Properties: %s",lastID,SaveBuffer2);
	}
	else
	{
		CloseHandle(Vault);
		WriteID(Client, SaveBuffer2, Ent);
	}
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
    
    PrintToServer("SAVE: new lastID: #%d",lastID);
    CloseHandle(Vault);
    return true;
}

public Action:Command_drawItems(Handle:Timer, any:Value)
{
    PrintToServer("SAVE: Loading Entities...");
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
    
    PrintToServer("SAVE: Found %d Entities",Y-1);
    KvRewind(Vault);
		
    //Load:
    for(new X = 0; X < Y; X++)
    {
    	if(loadArray[X] == 0)
    	{
    		PrintToServer("SAVE: Error at Entity #%d",X);
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
	            SetEntProp(Ent, Prop_Data, "m_takedamage", 0, 1);
	            AcceptEntityInput(Ent, "DisableMotion");
		    SetEntProp(Ent, Prop_Data, "m_CollisionGroup", 0);
	            
	            Entys[Ent] = loadArray[X];

		    //Skins Addition:
		    decl SkinNumber;
		    KvJumpToKey(Vault, "Skins", false);
		    SkinNumber = KvGetNum(Vault, NPCId, 0);
		    decl String:SkinString[25];
		    IntToString(SkinNumber, SkinString, 25);
		    DispatchKeyValue(Ent, "skin", SkinString);
		    KvRewind(Vault);

		    //Color Addition:
		    decl String:RGBAString[255], String:RGBAparts[4][25];
		    LoadString(Vault, "Color", NPCId, "Null", RGBAString);
        	    if(StrContains(RGBAString, "Null", false) == -1)
	            {
			ExplodeString(RGBAString, " ", RGBAparts, 4, 25);
			decl Red, Green, Blue, Alpha;
			Red = StringToInt(RGBAparts[0]);
			Green = StringToInt(RGBAparts[1]);
			Blue = StringToInt(RGBAparts[2]);
			Alpha = StringToInt(RGBAparts[3]);
			SetEntityRenderMode(Ent, RENDER_GLOW);
			SetEntityRenderColor(Ent, Red, Green, Blue, Alpha);
		    }
            } else
            {
            	PrintToServer("SAVE: Entry %d can not be a valid model",loadArray[X]);
            } 
        }
    }
    PrintToServer("SAVE: All Entities loaded");
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

            decl String:Buffer[20];
            IntToString(Entys[Ent],Buffer,20);
            
            //Delete:
            KvJumpToKey(Vault, "Furn", false);
            Deleted = KvDeleteKey(Vault, Buffer); 
            KvRewind(Vault);

            KvJumpToKey(Vault, "Skins", false);
            KvDeleteKey(Vault, Buffer);
            KvRewind(Vault);

            KvJumpToKey(Vault, "Color", false);
            KvDeleteKey(Vault, Buffer);
            KvRewind(Vault);

            //Store:
            KeyValuesToFile(Vault, NPCPath);

            //Print:
            if(!Deleted) PrintToConsole(Client, "[SAVE] Failed to remove Entity %d from the database", Entys[Ent]);
            else 
            {
                //Print:
                PrintToConsole(Client, "[SAVE] Removed Entity %d from the database", Entys[Ent]);
		Entys[Ent] = 0;
                RemoveEdict(Ent);
            }

            //Close:
            CloseHandle(Vault);
        }
    }

    //Return:
    return Plugin_Handled;
}

public Action:Command_Skin(Client,args)
{
	if(Client == 0) return Plugin_Handled;

	if(args < 1)
	{
		PrintToConsole(Client, "[SAVE] Usage: sm_changeskin <skin number> <opt 0|1 save>");
		return Plugin_Handled;
	}
	else if(args == 1)
	{
		decl String:Arg1[25];

		GetCmdArg(1, Arg1, sizeof(Arg1));

		decl Var;
		Var = StringToInt(Arg1);
		if(Var < 0)
		{
			PrintToChat(Client, "[SAVE] Usage: sm_changeskin <skin number> <opt 0|1 save>");
			return Plugin_Handled;
		}
		decl Ent;
		Ent = GetClientAimTarget(Client, false);
    
		if(Ent != -1 && Ent > 0 && Ent > GetMaxClients())
		{
			DispatchKeyValue(Ent, "skin", Arg1);
			PrintToChat(Client, "[SAVE] Changed Skin temporarily to #%s", Arg1);
			return Plugin_Handled;
		}
		PrintToChat(Client, "[SAVE] Could not locate a prop.");
		return Plugin_Handled;
	}
	else if(args > 1)
	{
		decl String:Arg1[25], String:Arg2[25];

		GetCmdArg(1, Arg1, sizeof(Arg1));
		GetCmdArg(2, Arg2, sizeof(Arg2));

		decl Var, Var2;
		Var = StringToInt(Arg1);
		Var2 = StringToInt(Arg2);
		if(Var < 0)
		{
			PrintToChat(Client, "[SAVE] Usage: sm_changeskin <skin number> <opt 0|1 save>");
			return Plugin_Handled;
		}
		decl Ent;
		Ent = GetClientAimTarget(Client, false);
    
		if(Ent != -1 && Ent > 0 && Ent > GetMaxClients())
		{
			DispatchKeyValue(Ent, "skin", Arg1);
			if(Var2 > 0)
			{
				if(Entys[Ent] < 1)
				{
					PrintToChat(Client, "[SAVE] This prop must be saved first before you save its skin");
					return Plugin_Handled;
				}
				DispatchKeyValue(Ent, "skin", Arg1);
				PrintToChat(Client, "[SAVE] Changed Skin to #%s and is saved", Arg1);
				decl Handle:Vault;
				Vault = CreateKeyValues("Vault");
				FileToKeyValues(Vault, NPCPath);
				KvJumpToKey(Vault, "Skins", true);

				decl String:EntyString[25];
				IntToString(Entys[Ent], EntyString, 25);
				if(Var == 0)
				{
					KvDeleteKey(Vault, EntyString);
				}
				else if(Var > 0)
				{
					KvSetNum(Vault, EntyString, Var);
				}
				KvRewind(Vault);
				KeyValuesToFile(Vault, NPCPath);
				CloseHandle(Vault);
				return Plugin_Handled;
			}
			else
			{
				DispatchKeyValue(Ent, "skin", Arg1);
				PrintToChat(Client, "[SAVE] Changed Skin temporarily to #%s", Arg1);
				return Plugin_Handled;
			}
		}
		PrintToChat(Client, "[SAVE] Could not locate a prop.");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action:Command_Color(Client,args)
{
	if(Client == 0) return Plugin_Handled;

	if(args < 4)
	{
		PrintToConsole(Client, "[SAVE] Usage: sm_changecolor <Red 0-255> <Green 0-255> <Blue 0-255> <Alpha 0-255> <opt 0|1 save>");
		return Plugin_Handled;
	}
	else if(args == 4)
	{
		decl String:Arg1[25], String:Arg2[25], String:Arg3[25], String:Arg4[25];

		GetCmdArg(1, Arg1, sizeof(Arg1));
		GetCmdArg(2, Arg2, sizeof(Arg2));
		GetCmdArg(3, Arg3, sizeof(Arg3));
		GetCmdArg(4, Arg4, sizeof(Arg4));

		decl Var, Var2, Var3, Var4;
		Var = StringToInt(Arg1);
		Var2 = StringToInt(Arg2);
		Var3 = StringToInt(Arg3);
		Var4 = StringToInt(Arg4);
		if(Var < 0 || Var > 255 || Var2 < 0 || Var2 > 255 || Var3 < 0 || Var3 > 255 || Var4 < 0 || Var4 > 255)
		{
			PrintToChat(Client, "[SAVE] Usage: sm_changecolor <Red 0-255> <Green 0-255> <Blue 0-255> <Alpha 0-255> <opt 0|1 save>");
			return Plugin_Handled;
		}
		decl Ent;
		Ent = GetClientAimTarget(Client, false);
    
		if(Ent != -1 && Ent > 0 && Ent > GetMaxClients())
		{
			SetEntityRenderMode(Ent, RENDER_GLOW);
			SetEntityRenderColor(Ent, Var, Var2, Var3, Var4);
			PrintToChat(Client, "[SAVE] Changed Color temporarily to Red=%d Green=%d Blue=%d Alpha=%d", Var, Var2, Var3, Var4);
			return Plugin_Handled;
		}
		PrintToChat(Client, "[SAVE] Could not locate a prop.");
		return Plugin_Handled;
	}
	else if(args > 4)
	{
		decl String:Arg1[25], String:Arg2[25], String:Arg3[25], String:Arg4[25], String:Arg5[25];

		GetCmdArg(1, Arg1, sizeof(Arg1));
		GetCmdArg(2, Arg2, sizeof(Arg2));
		GetCmdArg(3, Arg3, sizeof(Arg3));
		GetCmdArg(4, Arg4, sizeof(Arg4));
		GetCmdArg(5, Arg5, sizeof(Arg5));

		decl Var, Var2, Var3, Var4, Var5;
		Var = StringToInt(Arg1);
		Var2 = StringToInt(Arg2);
		Var3 = StringToInt(Arg3);
		Var4 = StringToInt(Arg4);
		Var5 = StringToInt(Arg5);

		if(Var < 0 || Var > 255 || Var2 < 0 || Var2 > 255 || Var3 < 0 || Var3 > 255 || Var4 < 0 || Var4 > 255)
		{
			PrintToChat(Client, "[SAVE] Usage: sm_changecolor <Red 0-255> <Green 0-255> <Blue 0-255> <Alpha 0-255> <opt 0|1 save>");
			return Plugin_Handled;
		}
		decl Ent;
		Ent = GetClientAimTarget(Client, false);
    
		if(Ent != -1 && Ent > 0 && Ent > GetMaxClients())
		{
			DispatchKeyValue(Ent, "skin", Arg1);
			if(Var5 > 0)
			{
				if(Entys[Ent] < 1)
				{
					PrintToChat(Client, "[SAVE] This prop must be saved first before you save its color/alpha");
					return Plugin_Handled;
				}
				SetEntityRenderMode(Ent, RENDER_GLOW);
				SetEntityRenderColor(Ent, Var, Var2, Var3, Var4);
				PrintToChat(Client, "[SAVE] Changed Color to Red=%d Green=%d Blue=%d Alpha=%d and is saved.", Var, Var2, Var3, Var4);
				decl Handle:Vault;
				Vault = CreateKeyValues("Vault");
				FileToKeyValues(Vault, NPCPath);
				KvJumpToKey(Vault, "Color", true);

				decl String:EntyString[25];
				IntToString(Entys[Ent], EntyString, 25);

				decl String:RGBA[255];
				Format(RGBA, 255, "%d %d %d %d", Var, Var2, Var3, Var4);

				if(Var == 255 && Var2 == 255 && Var3 == 255 && Var4 == 255)
				{
					KvDeleteKey(Vault, EntyString);
				}
				else if(Var < 255 || Var2 < 255 || Var3 < 255 || Var4 < 255)
				{
					KvSetString(Vault, EntyString, RGBA);
				}
				KvRewind(Vault);
				KeyValuesToFile(Vault, NPCPath);
				CloseHandle(Vault);
				return Plugin_Handled;
			}
			else
			{
				SetEntityRenderMode(Ent, RENDER_GLOW);
				SetEntityRenderColor(Ent, Var, Var2, Var3, Var4);
				PrintToChat(Client, "[SAVE] Changed Color temporarily to Red=%d Green=%d Blue=%d Alpha=%d", Var, Var2, Var3, Var4);
				return Plugin_Handled;
			}
		}
		PrintToChat(Client, "[SAVE] Could not locate a prop.");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}