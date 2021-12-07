
/********************************************
* 
* Remove Map Text Version "1.1.4"
* 
* Description:
* Removes on mapstart all game_text entitys that shows a text near the crosshair
* 
* Install:
* put the removemaptext.smx into your plugin folder.
* you dont need to configure anything.
* 
* Changelog:
* v1.1.4 Only removes now game_text entitys near crosshair
* v1.0.0 First Public Release
* 
* 
* Thank you Berni, Manni, Mannis FUN House Community and SourceMod-Team
* 
* *************************************************/

/****************************************************************
P R E C O M P I L E R   D E F I N I T I O N S
*****************************************************************/

// enforce semicolons after each code statement
#pragma semicolon 1

/****************************************************************
I N C L U D E S
*****************************************************************/

#include <sourcemod>
#include <sdktools>


/****************************************************************
P L U G I N   C O N S T A N T S
*****************************************************************/

#define PLUGIN_VERSION "1.1.4"
#define PLUGIN_NAME "Remove Map Text"
#define MIN 0.2
#define MAX 0.8

/*****************************************************************
P L U G I N   I N F O
*****************************************************************/

public Plugin:myinfo = 
{
	name = "Remove Map Text",
	author = "Chanz",
	description = "Removes on mapstart all game_text entitys that shows a text near the crosshair",
	version = PLUGIN_VERSION,
	url = "www.mannisfunhouse.eu"
}

/*****************************************************************
G L O B A L   V A R S
*****************************************************************/

new Handle:sm_removemaptext_version = INVALID_HANDLE;


/*****************************************************************
F O R W A R D   P U B L I C S
*****************************************************************/

public OnPluginStart(){
	sm_removemaptext_version = CreateConVar("sm_removemaptext_version", PLUGIN_VERSION, "Remove Map Text Version", FCVAR_PLUGIN|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
}

public OnConfigsExecuted(){
	
	SetConVarString(sm_removemaptext_version, PLUGIN_VERSION);
}

public OnMapStart(){
	
	new i=0;
	new Float:x;
	new Float:y;
	
	new ent = -1;
	new prev = 0;
	
	while ((ent = FindEntityByClassname(ent, "game_text")) != -1)
	{
		if (prev) {
			
			x=GetEntPropFloat(prev, Prop_Data, "m_textParms.x");
			y=GetEntPropFloat(prev, Prop_Data, "m_textParms.y");
			
			if(((x == -1.0) && (y == -1.0)) || ((x > MIN) && (x < MAX)) || ((y > MIN) && (y < MAX))){
			
				RemoveEdict(prev);
				PrintToServer("[%s] Deleted maptext (%d) x: %f y: %f",PLUGIN_NAME, prev,x,y);
				i++;
			}	
		}
		prev = ent;
	}
	
	if (prev) {
		
		x=GetEntPropFloat(prev, Prop_Data, "m_textParms.x");
		y=GetEntPropFloat(prev, Prop_Data, "m_textParms.y");
		
		if((x == -1.0) || (y == -1.0) || ((x > MIN) && (x < MAX)) || ((y > MIN) && (y < MAX))){
		
			RemoveEdict(prev);
			PrintToServer("[%s] Deleted maptext (%d) x: %f y: %f",PLUGIN_NAME, prev,x,y);
			i++;
		}	
	}
	
	PrintToServer("[%s] Deleted %i maptext entitys",PLUGIN_NAME,i);
}













