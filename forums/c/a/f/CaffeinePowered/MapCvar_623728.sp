/*------------------------------------------------------------------------------
Map Cvar Automator
By: CaffeinePowered

The purpose of this plugin is to build on previous map config chooser plugins, but
to do so in a bit more clean way by placing all of the cvars and maps in one file
rather than having to have seperate config files for every map.

------------------------------------------------------------------------------*/

//------------------------------------------------------------------------------
#include <sourcemod>

#pragma semicolon 1
public Plugin:myinfo =
{
	name = "Map Cvar Automator",
	author = "CaffeinePowered",
	description = "Automated Map Cvar Executer",
	version = "1.0",
	url = "http://brbuninstalling.com"
}
//------------------------------------------------------------------------------

//Global Vars
//------------------------------------------------------------------------------
new Handle:Default_Cvars;
new Handle:Map_Cvars;
new loaded_default = 0;
new map_loaded = 0;
new numDefaults = 0;
new numCvars = 0;
//------------------------------------------------------------------------------

//OnPluginStart (Use: called when the plugin is loaded)
//------------------------------------------------------------------------------
public OnPluginStart()
{
	//Debug message
	LogToGame("Map Cvar Config Running");
	numDefaults = 0;
	loaded_default = 0; 
	Default_Cvars = CreateArray(ByteCountToCells(80));
	Map_Cvars = CreateArray(ByteCountToCells(80));	
}
//------------------------------------------------------------------------------

//OnMapStart (Use: Called when a map loads)
//------------------------------------------------------------------------------
public OnMapStart()
{
	map_loaded = 0;
	numCvars = 0;
	ClearArray(Map_Cvars);
	LoadCvarList();
}
//------------------------------------------------------------------------------

public OnConfigsExecuted( )
{
	if(map_loaded == 1)
	{
		load_map_cvars();
	}
	else if(loaded_default == 1)
	{
		load_defaults();
	}
	else
	{
		LogToGame("No Default or Map Config Detected!");
	}

}

//Loads the Cvars list for a particular Map
//-------------------------------------------------------------------------------
public Action:LoadCvarList()
{
	LogToGame("Loading Cvars");
	new Handle:CvarList_File = OpenFile("addons/sourcemod/configs/mapcvarlist.cfg","rt");

	decl String:MapName[40];
	GetCurrentMap(MapName, 40);

	decl String:defaults[8];
	defaults = "default";
	decl String:current_line[80];

	while(!IsEndOfFile(CvarList_File) && !map_loaded)
	{
		//Read the line
		ReadFileLine(CvarList_File, current_line, sizeof(current_line));
		if((current_line[0] != '/') && (current_line[1] != '/') && (current_line[0] != '\0'))
		{
			//Trim the line and check for the default config
			TrimString(current_line);
			if(loaded_default == 0)
			{
				if(StrContains(current_line,defaults,false) == 0)
				{
					while(!loaded_default)
					{
						ReadFileLine(CvarList_File, current_line, sizeof(current_line));
						TrimString(current_line);
						if((current_line[0] != '/') && (current_line[1] != '/') && (current_line[0] != '\0') && (current_line[0] != '{'))
						{
							TrimString(current_line);
							if(current_line[0] != '}')
							{
								PushArrayString(Default_Cvars,current_line);
								numDefaults++;
							}
							else
							{
								loaded_default = 1;
							}
						}
					}
				}
			}
			else
			{
				//Check to see if map name matches
				if(StrContains(current_line,MapName,false) == 0)
				{
					while(!map_loaded)
					{
						ReadFileLine(CvarList_File, current_line, sizeof(current_line));
						TrimString(current_line);
						if((current_line[0] != '/') && (current_line[1] != '/') && (current_line[0] != '\0') && (current_line[0] != '{'))
						{
							TrimString(current_line);
							if(current_line[0] != '}')
							{
								PushArrayString(Map_Cvars,current_line);
								numCvars++;
							}
							else
							{
								map_loaded = 1;
							}
						}
					}		
				}
				else if(StrContains(current_line,"*",false) != -1)
				{
					if((current_line[0] == MapName[0]) && (current_line[1] == MapName[1]))
					{
						while(!map_loaded)
						{
							ReadFileLine(CvarList_File, current_line, sizeof(current_line));
							TrimString(current_line);
							if((current_line[0] != '/') && (current_line[1] != '/') && (current_line[0] != '\0') && (current_line[0] != '{'))
							{
								TrimString(current_line);
								if(current_line[0] != '}')
								{
									PushArrayString(Map_Cvars,current_line);
									numCvars++;
								}
								else
								{
									map_loaded = 1;
								}
							}
						}
					}		
				}
				
			}
		}
	}
 
	//Close the handle
	CloseHandle(CvarList_File);
}
//-------------------------------------------------------------------------------

//Loads the Cvars for a particular Map
//-------------------------------------------------------------------------------
public Action:load_map_cvars()
{
	new i = 0;
	decl String:command[80];
	while(i < numCvars)
	{
		GetArrayString(Map_Cvars, i, command, 80);	
		ServerCommand(command);
		i++;
	}
}
//--------------------------------------------------------------------------------

//Loads the default Cvars if the map does not exist
//-------------------------------------------------------------------------------
public Action:load_defaults()
{
	new i = 0;
	decl String:command[80];
	while(i < numDefaults)
	{
		GetArrayString(Map_Cvars, i, command, 80);	
		ServerCommand(command);
		i++;
	}
}
//-------------------------------------------------------------------------------