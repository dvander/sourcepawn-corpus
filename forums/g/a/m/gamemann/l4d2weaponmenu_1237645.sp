#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = {
	name = "l4d2 weapon menu",
	author = "kingdom for hearts",
	description = "type in the chatbox !wm to have a menu",
	version = "1.0",
	url = ""
};

public OnPluginStart()
{
	RegConsoleCmd("sm_wm", Menu);
}

public Action:Menu(client, args) {
	new Handle:menu = CreateMenu(wmenu);
	SetMenuTitle(menu, "weapon menu");
	AddMenuItem(menu, "option0", "rifle");
	AddMenuItem(menu, "option1", "sniper_militarty");
	AddMenuItem(menu, "option2", "hunting_rifle");
	AddMenuItem(menu, "option3", "rifle_ak_47");
	AddMenuItem(menu, "option4", "rifle_desert");
	AddMenuItem(menu, "option5", "smg");
	AddMenuItem(menu, "option6", "smg_slienced");
	AddMenuItem(menu, "option7", "autoshotgun");
	AddMenuItem(menu, "option8", "pumpshotgun");
	AddMenuItem(menu, "option9", "shotgun Chrome");
	AddMenuItem(menu, "option10", "upgrade pack fire");
	AddMenuItem(menu, "option11", "upgrade pack Explosive");
	AddMenuItem(menu, "option12", "sniper_awp");
	AddMenuItem(menu, "option13", "sniper scout");
	AddMenuItem(menu, "option14", "SMG mp5");
	AddMenuItem(menu, "option15", "Grenade launcher");
	AddMenuItem(menu, "option16", "fireworkcreate");
	AddMenuItem(menu, "option17", "vomit jar");
	AddMenuItem(menu, "option18", "molotov");
	AddMenuItem(menu, "option19", "pipe bomb");
	AddMenuItem(menu, "option20", "gascan");
	AddMenuItem(menu, "option21", "propane tank");
	AddMenuItem(menu, "option22", "oxygen tank");
	AddMenuItem(menu, "option23", "Gnome");
	AddMenuItem(menu, "option24", "shotgun Spas");
	AddMenuItem(menu, "option25", "rifle Sg");
	AddMenuItem(menu, "option26", "machete * only if the level can have it!!!");
	AddMenuItem(menu, "option27", "fireaxe * only if the level can have it!!!");
	AddMenuItem(menu, "option28", "katana * only if the level can have it!!!");
	AddMenuItem(menu, "option29", "frying pan * only if the level can have it!!!");
	AddMenuItem(menu, "option30", "Electric Guitar * only if the level can have it!!!");
	AddMenuItem(menu, "option31", "Cricket Bat * only if the level can have it!!!");
	AddMenuItem(menu, "option32", "Crow Bar * only if the level can have it!!!");
	AddMenuItem(menu, "option33", "Tonfa * only if the level can have it!!!");
	AddMenuItem(menu, "option34", "chainsaw");
	AddMenuItem(menu, "option35", "knife");
	AddMenuItem(menu, "option36", "rifle_pack");
	AddMenuItem(menu, "option37", "SMG_pack");
	AddMenuItem(menu, "option38", "sniperPack");
	AddMenuItem(menu, "option39", "shotgunPack");
	AddMenuItem(menu, "option40", "first_aid_kit");
	AddMenuItem(menu, "option41", "pills");
	AddMenuItem(menu, "option42", "other");
	AddMenuItem(menu, "option434", "other");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	//return Plugin_Handled
}

public wmenu(Handle:menu, MenuAction:action, client, itemNum)
{
	new flags = GetCommandFlags("give");
	new flagsi1 = GetCommandFlags("add_upgrade");
	SetCommandFlags("add_upgrade", flagsi1 & ~FCVAR_CHEAT);
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);
	if(action == MenuAction_Select)
	{
		switch (itemNum)
		{
			case 0: //rifle
			{

					//gives a rifle
					FakeClientCommand(client, "give rifle");
			}
			
			case 1: //sniper_military
			{
				//gives a sniper_military
				FakeClientCommand(client, "give sniper_military");
			}
			
			case 2: //hunting_rifle
			{
				//gives a hunting rifle
				FakeClientCommand(client, "give hunting_rifle");
			}

			case 3: //Ak 47
			{
				//gives a ak_47
					FakeClientCommand(client, "give rifle_ak47");
			}
		
			case 4: //rifle desert
			{
				FakeClientCommand(client, "give rifle_desert");
			}
			case 5: //smg
			{
				FakeClientCommand(client, "give smg");
			}
		
			case 6: //smg silenced
			{
				FakeClientCommand(client, "give smg_silenced");
			}
		
			case 7: // autoshotgun
			{
				FakeClientCommand(client, "give autoshotgun");
			}
		
			case 8: //pumpshotgun
			{
				FakeClientCommand(client, "give pumpshotgun");
			}

			case 9: //shotgun CHROME
			{
				FakeClientCommand(client, "give shotgun_chrome");
			}
			case 10: // upgradePack incendiary
			{
				FakeClientCommand(client, "give upgradepack_incendiary");
			}
			
			case 11: // upgradePack explosive
			{
				FakeClientCommand(client, "give upgradepack_explosive");
			}
			
			case 12: // sniper_awp
			{
				FakeClientCommand(client, "give sniper_awp");
			}
		
			case 13: //sniper_scout
			{
				FakeClientCommand(client, "give sniper_scout");
			}
			
			case 14: //smg_mp5
			{
				FakeClientCommand(client, "give smg_mp5");
			}

			case 15: //grenade launcher
			{
				FakeClientCommand(client, "give grenade_launcher");
			}

			case 16: //fireworkcrate
			{
				FakeClientCommand(client, "give fireworkcrate");
			}
			
			case 17: //vomit jar
			{
				FakeClientCommand(client, "give vomitjar");
			}

			case 18: //MOLOTOV
			{
				FakeClientCommand(client, "give molotov");
			}
	
			case 19: // PIPEBOMB
			{
				FakeClientCommand(client, "give pipe_bomb");
			}
		
			case 20: // GASCAN
			{
				FakeClientCommand(client, "give gascan");
			}

			case 21: //PROPANETANK
			{
				FakeClientCommand(client, "give propanetank");
			}
	
			case 22: //OXYGENTANK
			{
				FakeClientCommand(client, "give oxygentank");
			}

			case 23: // GNOME
			{
				FakeClientCommand(client, "give gnome");
			}

			case 24: //shotgun SPAS
			{
				FakeClientCommand(client, "give shotgun_spas");
			}

			case 25: // rifle_sg552
			{
				FakeClientCommand(client, "give rifle_sg552");
			}

			case 26: // machete
			{
				FakeClientCommand(client, "give machete");
			}
			
			case 27: // fireaxe
			{
				FakeClientCommand(client, "give fire_axe");
			}
		
			case 28: // katana
			{
				FakeClientCommand(client, "give katana");
			}
		
			case 29: //frying pan
			{
				FakeClientCommand(client, "give frying_pan");
			}
	
			case 30: // electric guitar
			{
				FakeClientCommand(client, "give electric_guitar");
			}

			case 31: // cricket bat
			{
				FakeClientCommand(client, "give cricket_bat");
			}

			case 32: //crow bar
			{
				FakeClientCommand(client, "give crow_bar");
			}

			case 33: // tonfa
			{
				FakeClientCommand(client, "give tonfa");
			}

			case 34: // chainsaw
			{
				FakeClientCommand(client, "give chainsaw");
			}
			
			case 35: // knife
			{
				FakeClientCommand(client, "give knife");
			}
	
			case 36: // rifle pack
			{
				FakeClientCommand(client, "give upgradepack_explosive");
				FakeClientCommand(client, "add_upgrade laser_sight");
				FakeClientCommand(client, "give rifle");
				FakeClientCommand(client, "give first_aid_kit");
			}
		
			case 37: //smg pack
			{
				FakeClientCommand(client, "give upgradepack_incendiary");
				FakeClientCommand(client, "give first_aid_kit");
				FakeClientCommand(client, "add_upgrade laser_sight");
				FakeClientCommand(client, "give smg");
				FakeClientCommand(client, "give first_aid_kit");
			}
			
			case 38: //sniper pack
			{
				FakeClientCommand(client, "give sniper_military");
				FakeClientCommand(client, "give pills");
				FakeClientCommand(client, "give first_aid_kit");
				FakeClientCommand(client, "add_upgrade laser_sight");
			}
		
			case 39: //shotgun pack
			{
				FakeClientCommand(client, "give shotgun_spas");
				FakeClientCommand(client, "add_upgrade laser_sight");
				FakeClientCommand(client, "first_aid_kit");
			}

			case 40: // first_aid_kit
			{
				FakeClientCommand(client, "give first_aid_kit");
			}

			case 41: // pain pills
			{
				FakeClientCommand(client, "give pain_pills");
			}
			
			case 42: //other
			{
				FakeClientCommand(client, "give smg");
				FakeClientCommand(client, "give katana");
			}	
		}
	}
}





