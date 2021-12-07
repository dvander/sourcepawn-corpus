#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0" 
#define PLUGIN_AUTHOR "Exploit"

#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_SPONLY

public Plugin myinfo = 
{
	name = "ZombieSpawner",
	author = PLUGIN_AUTHOR,
	description = "My first plugin",
	version = PLUGIN_VERSION,
	url = ""
};

public OnPluginStart()
{
	RegConsoleCmd("sm_spawner", Menu4);
}

public Action:Menu4(client, args){
	new Handle:menu = CreateMenu(Menu4Handler); 
	SetMenuTitle(menu, "ZombieSpawner Menu"); 
	AddMenuItem(menu, "option1", "Charger");
	AddMenuItem(menu, "option2", "Hunter");
	AddMenuItem(menu, "option3", "Boomer");
	AddMenuItem(menu, "option4", "Smoker");
	AddMenuItem(menu, "option5", "Jockey");
	AddMenuItem(menu, "option6", "Spitter");
	AddMenuItem(menu, "option7", "Tank");
	AddMenuItem(menu, "option8", "Witch");
	SetMenuExitButton(menu, true); 
	DisplayMenu(menu, client, MENU_TIME_FOREVER); 

	return Plugin_Handled; 
}


public Menu4Handler(Handle:menu, MenuAction:action, client, itemNum) 
{ 
	
	new flagszspawn = GetCommandFlags("z_spawn");	
	SetCommandFlags("z_spawn", flagszspawn & ~FCVAR_CHEAT);	

	if ( action == MenuAction_Select ) { 

		switch (itemNum) 
		{ 
			case 0: 
			{ 
				FakeClientCommand(client, "z_spawn charger");
			} 
			
			case 1:
			{
				FakeClientCommand(client, "z_spawn hunter");
			}
			
			case 2:
			{
				FakeClientCommand(client, "z_spawn boomer");

			}
			
			case 3:
			{
				FakeClientCommand(client, "z_spawn smoker");

			}
			
			case 4:
			{
				FakeClientCommand(client, "z_spawn jockey");

			}
			
			case 5:
			{
				FakeClientCommand(client, "z_spawn spitter");

			}
			
			case 6:
			{
				FakeClientCommand(client, "z_spawn tank");

			}
			
			case 7:
			{
				FakeClientCommand(client, "z_spawn witch");

			}
		} 
	} 
	SetCommandFlags("z_spawn", flagszspawn|FCVAR_CHEAT);
}  