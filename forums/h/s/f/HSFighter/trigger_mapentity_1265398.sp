//////////////////////////////////////////////////////////////////
// Trigger Mapentity By HSFighter /// www.hsfighter.net			//
//////////////////////////////////////////////////////////////////

#include <sourcemod>
#include <sdktools>

#undef REQUIRE_PLUGIN
#include <updater>

#define PLUGIN_VERSION "1.1.1"
#define UPDATE_URL	"http://update.hsfighter.net/sourcemod/trigger_mapentity/trigger_mapentity.txt"

//////////////////////////////////////////////////////////////////
// Delcare Variables and Handles
//////////////////////////////////////////////////////////////////

new Handle:CvarEnable;
new Handle:CvarTriggeracces;
new Handle:CvarTriggeraccesCS;
new taccess;
new taccesscs;

//////////////////////////////////////////////////////////////////
// Plugin Info
//////////////////////////////////////////////////////////////////

public Plugin:myinfo = 
{
	name = "Trigger Mapentity",
	author = "HSFighter",
	description = "Trigger mapentitys",
	version = PLUGIN_VERSION,
	url = "http://www.hsfighter.net"
}

//////////////////////////////////////////////////////////////////
// Start Plugin
//////////////////////////////////////////////////////////////////

public OnPluginStart()
{
	
	CreateConVar("sm_trigger_mapentity_version", PLUGIN_VERSION, "Trigger mapentity version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	CvarEnable = CreateConVar("sm_trigger_mapentity_enable", "1", "Enable/Disable the trigger function");
	
	CvarTriggeracces = CreateConVar("sm_trigger_mapentity_access", "1", "Trigger Access (1 = Ingame, 2 = Extern, 3= Both)", FCVAR_PLUGIN, true, 1.00, true, 3.00);		
	/*	
	1 = Igame Only
	2 = Extern only (Rcon)
	3 = Both
	*/
	
	CvarTriggeraccesCS = CreateConVar("sm_trigger_mapentity_access_cs", "15", "Trigger Access Counter-Strike:\n1 = Teamless, 2 = Spectator, 4 = Terrorists, 8 = Counter Terrorists\n(e.g. 12 = T and CT)", FCVAR_PLUGIN, true, 1.00, true, 15.00);	
	/*		
	1 = Teamless
	2 = Spectator
	4 = Terrorists	
	8 = Counter Terrorists 
	*/
	
	RegAdminCmd("sm_trigger_mapentity", Command_Trigger,ADMFLAG_CUSTOM1, "sm_trigger_mapentity <class> <name> <input>");
	RegAdminCmd("sm_trigger_mapentity_list", List_Entitys,ADMFLAG_CUSTOM1, "List all available entitys in the map to console");	
	
	taccesscs = GetConVarInt(CvarTriggeraccesCS);
	taccess = GetConVarInt(CvarTriggeracces);
	
	HookConVarChange(CvarTriggeraccesCS, convar_change);
	HookConVarChange(CvarTriggeracces, convar_change);
	
	
	// Create config
	AutoExecConfig(true, "plugin.trigger_mapentity")
	
	// Updater
	if(LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

//////////////////////////////////////////////////////////////////
// Convar Chnage
//////////////////////////////////////////////////////////////////

public convar_change(Handle:convar, const String:oldValue[], const String:newValue[])
{
	taccesscs = GetConVarInt(CvarTriggeraccesCS);
	taccess = GetConVarInt(CvarTriggeracces);
}

//////////////////////////////////////////////////////////////////
// Updater Stuff
//////////////////////////////////////////////////////////////////

public OnLibraryAdded(const String:name[])
{	
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

//////////////////////////////////////////////////////////////////
// Start Map
//////////////////////////////////////////////////////////////////

public OnMapStart() 
{ 

}

//////////////////////////////////////////////////////////////////
// Trigger Mapentity
//////////////////////////////////////////////////////////////////

public Action:Command_Trigger(client, args){
	
	
	decl String:ModName[21];
	GetGameFolderName(ModName, sizeof(ModName));
	
	if ((!StrEqual(ModName, "cstrike", false)) && (!StrEqual(ModName, "csgo", false)))
	{
		taccesscs = 0;
	}
	
	new Classfound = 0;
	new Namefound = 0;
	
	
	// Check if Plugin is enabled
	if(GetConVarInt(CvarEnable) != 1)
	{
		ReplyToCommand(client, "[Trigger Entity] Sorry, but the trigger is currently disabled!");
		return Plugin_Handled;
	}
	
		
	// Check access to trigger
	if (client != 0)
	{	
		
		if (!((taccess & 1) && ((taccesscs == 0) || ((taccesscs & 1) && (GetClientTeam(client) == 0)) || ((taccesscs & 2) && (GetClientTeam(client) == 1)) || ((taccesscs & 4) && (GetClientTeam(client) == 2)) || ((taccesscs & 8) && (GetClientTeam(client) == 3)))))
		{		
			ReplyToCommand(client, "[Trigger Entity] Sorry, no access to the trigger!");
			return Plugin_Handled;
		}
	}
	else
	{
		if (!((client == 0) && (taccess & 2)))
		{		
			ReplyToCommand(client, "[Trigger Entity] Sorry, access only ingame!");
			return Plugin_Handled;
		}
	}
	
	// Check if "class" and "name" are set
	if (args < 2)
	{
		ReplyToCommand(client, "[Trigger Entity] Usage: sm_trigger_mapentity <class> <name> <input>");
		return Plugin_Handled;
	}
	
	// Get arg string from command
	decl String:arg_string[256];
	GetCmdArgString(arg_string, sizeof(arg_string));
	
	new len, total_len;
	
	// Get entity "class" from arg
	new String:class[128];
	if ((len = BreakString(arg_string, class, sizeof(class))) == -1)
	{
		ReplyToCommand(client, "[Trigger Entity] Usage: sm_trigger_mapentity <class> <name> <input>");
		return Plugin_Handled;
	}	
	total_len += len;
	
	// Get entity "name" and input from arg
	new String:name[128];
	if ((len = BreakString(arg_string[total_len], name, sizeof(name))) != -1)
	{
		total_len += len;
	}
	else
	{
		total_len = 0;
		arg_string[0] = '\0';
	}
	
	
	
	
	// Debug
	// PrintToChatAll("Class: %s",class); //debug command class
	// PrintToChatAll("Name: %s",name);   //debug command name
	// PrintToChatAll("Input: %s",arg_string[total_len]); //debug command input
	
	// List all map entitys 
	new EntCount = GetEntityCount();
	new String:EdictName[128];
	for (new i = 0; i <= EntCount; i++)
	{
		if (IsValidEntity(i))
		{
			// Get classname from entity
			GetEdictClassname(i, EdictName, sizeof(EdictName));
						
			// Check if classname is simalar to the trigger command
			if (StrContains(EdictName, class, false) != -1)
			{
				Classfound = 1;
				// Get name of entity 				
				decl String:namebuf[32];
				namebuf[0] = '\0';
				GetEntPropString(i, Prop_Data, "m_iName", namebuf, sizeof(namebuf));
				
				// Check if name is simalar to the trigger command
				if(strcmp(namebuf, name) == 0) 
				{
					Namefound = 1;
					AcceptEntityInput(i, arg_string[total_len]);
				}	
				
				continue;
			}
		}
	}	

	if (Classfound == 0)
	{
		if (client != 0)
		{	
			PrintToChat(client, "[Trigger Entity] Entityclass %s not found!", class);
		}
		else
		{
			PrintToConsole(client, "[Trigger Entity] Entityclass %s not found!", class);
		}
	}
	else if (Namefound == 0)
	{
		if (client != 0)
		{	
			PrintToChat(client, "[Trigger Entity] Entityname %s not found!", name);
		}
		else
		{
			PrintToConsole(client, "[Trigger Entity] Entityname %s not found!", name);
		}
	}	
	


	return Plugin_Handled;
}

//////////////////////////////////////////////////////////////////
// List Mapentitys
//////////////////////////////////////////////////////////////////

public Action:List_Entitys(client, args){
	
	decl String:sBuffer[256];
	GetCurrentMap(sBuffer, sizeof(sBuffer))
	
	// List all map entitys 
	new EntCount = GetEntityCount();
	new String:EdictName[128];
	
	// Print header to console
	PrintToConsole(client, "-=[Trigger Entity]=-");
	PrintToConsole(client, "Map: %s", sBuffer);
	PrintToConsole(client, "Found %i entitys", EntCount);
	PrintToConsole(client, "");
	PrintToConsole(client, "# id | class | name");
	
	
	for (new i = 0; i <= EntCount; i++)
	{
		if (IsValidEntity(i))
		{
			// Get classname from entity
			GetEdictClassname(i, EdictName, sizeof(EdictName));
			
			// Get name of entity 				
			decl String:namebuf[32];
			namebuf[0] = '\0';
			GetEntPropString(i, Prop_Data, "m_iName", namebuf, sizeof(namebuf));
			
			// If no name available set name to <no name>
			if(strcmp(namebuf, "") == 0) namebuf = "<no name>";
			
			// Print mapentity-infos to console
			PrintToConsole(client, "# %i | %s | %s",i, EdictName, namebuf);
					
			continue;
		}
	}
	
	return Plugin_Handled;	
}

//////////////////////////////////////////////////////////////////
// End Plugin
//////////////////////////////////////////////////////////////////