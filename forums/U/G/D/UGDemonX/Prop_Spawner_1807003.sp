#include <sourcemod>

public Plugin:myinfo = {
name = "Prop Spawner",
author = "-[UG]- DemonX and -[CMX]- Reloaded ",
description = "Chat trigger to spawn a prop",
version = "1.2.1",
url = "www.union-gamers.com"
};

public OnPluginStart()
{
	RegConsoleCmd("say", Commandsay, "say hook");
}
public Action:Commandsay(client, args)
{
new String:prop[32];
GetCmdArg(1, prop, sizeof(prop));


	if(StrEqual(prop,"!blastdoor3"))
	{
		FakeClientCommand(client,"Prop_dynamic_create props_lab/blastdoor001c.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!blastdoor1"))
	{
		FakeClientCommand(client,"Prop_dynamic_create props_lab/blastdoor001a.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!combinedoor1"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_combine/combine_door01.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!combinedoor2"))
	{
		FakeClientCommand(client,"prop_dynamic_create combine_gate_citizen.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!combinedoor3"))
	{
		FakeClientCommand(client,"prop_dynamic_create combine_gate_Vehicle.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!elevatordoor"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_lab/elevatordoor.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!doorlab"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_doors/doorklab01.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!antlionhill"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_wasteland/antlionhill.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!archgate1"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_wasteland/prison_archgate001.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!archgate2"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_wasteland/prison_archgate002a.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!archwindow"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_wasteland/prison_archwindow001.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!armchair"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_c17/furniturearmchair001a.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!awning1"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_c17/awning001a.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!awning2"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_c17/awning002a.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!barricade1"))
	{
		FakeClientCommand(client,"prop_physics_create props_wasteland/barricade001a.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!barricade2"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_wasteland/barricade002a.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!bars1"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_building_details/storefront_template001a_bars.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!bars2"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_canal/canal_bars002.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!bars3"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_canal/canal_bars004.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!bathtub1"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_c17/furniturebathtub001a.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!bathtub2"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_interiors/bathtub01a.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!bedframe1"))
	{
		FakeClientCommand(client,"prop_physics_create props_c17/furniturebed001a.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!bedframe2"))
	{
		FakeClientCommand(client,"prop_physics_create props_wasteland/prison_bedframe001a.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled

	}
	if(StrEqual(prop,"!bench1"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_trainstation/bench_indoor001a.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!bench2"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_trainstation/benchoutdoor01a.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!bike"))
	{
		FakeClientCommand(client,"prop_physics_create props_junk/bicycle01a.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!bluebarrel"))
	{
		FakeClientCommand(client,"prop_physics_create props_borealis/bluebarrel001.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!boat1"))
	{
		FakeClientCommand(client,"prop_physics_create props_canal/boat001b.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!boat2"))
	{
		FakeClientCommand(client,"prop_physics_create props_canal/boat002b.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!boiler"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_c17/furnitureboiler001a.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!breenbust"))
	{
		FakeClientCommand(client,"prop_physics_create props_combine/breenbust.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!breenchair"))
	{
		FakeClientCommand(client,"prop_physics_create props_combine/breenchair.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!breendesk"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_combine/breendesk.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!breenglobe"))
	{
		FakeClientCommand(client,"prop_physics_create props_combine/breenglobe.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!breenpod"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_combine/breenpod_inner.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!briefcase"))
	{
		FakeClientCommand(client,"prop_physics_create props_c17/briefcase001a.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!buoy"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_wasteland/buoy01.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!car1"))
	{
		FakeClientCommand(client,"prop_physics_create props_vehicles/car005a_physics.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!car2"))
	{
		FakeClientCommand(client,"prop_physics_create props_vehicles/car004a_physics.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!couch1"))
	{
		FakeClientCommand(client,"prop_physics_create props_c17/furniturecouch001a.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!couch2"))
	{
		FakeClientCommand(client,"prop_physics_create props_c17/furniturecouch002a.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!dogsign"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_lab/bewaredog.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!explosivebarrel"))
	{
		FakeClientCommand(client,"prop_physics_create props_c17/oildrum001_explosive.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!fence1"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_c17/fence01a.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!fence2"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_c17/fence01b.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!fence3"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_c17/fence03a.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!fence4"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_c17/fence04a.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!fountain"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_c17/fountain_01.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!fridge"))
	{
		FakeClientCommand(client,"prop_physics_create props_c17/furniturefridge001a.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!grave1"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_c17/gravestone001a.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!grave2"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_c17/gravestone002a.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!grave3"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_c17/gravestone003a.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!grave4"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_c17/gravestone004a.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!gravecross"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_c17/gravestone_cross001a.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!gravestatue"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_c17/gravestone_statue001a.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!harpoon"))
	{
		FakeClientCommand(client,"prop_physics_create props_junk/harpoon002a.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!helibomb"))
	{
		FakeClientCommand(client,"prop_physics_create combine_helicopter/helicopter_bomb01.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!keypad"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_lab/keypad.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!labconsole"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_lab/generatorconsole.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!labgenerator"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_lab/generator.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!lablight"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_lab/lab_flourescentlight002b.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!ladder"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_c17/metalladder001.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!lamppost"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_c17/lamppost03a_off.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!lightcluster"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_wasteland/lights_industrialcluster01a.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!lockers"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_c17/lockers001a.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!magnifyinglamp"))
	{
		FakeClientCommand(client,"prop_physics_create props_c17/light_magnifyinglamp02.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!masterinterface"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_combine/masterinterface.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!mattress"))
	{
		FakeClientCommand(client,"prop_physics_create props_c17/furnituremattress001a.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!melon"))
	{
		FakeClientCommand(client,"prop_physics_create props_junk/watermelon01.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!miniteleport"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_lab/miniteleport.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!monitor1"))
	{
		FakeClientCommand(client,"prop_physics_create props_lab/monitor01a.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!monitor2"))
	{
		FakeClientCommand(client,"prop_physics_create props_lab/monitor02.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!newspaper"))
	{
		FakeClientCommand(client,"prop_physics_create props_junk/garbage_newspaper001a.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!oildrum"))
	{
		FakeClientCommand(client,"prop_physics_create props_c17/oildrum001.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!padlock"))
	{
		FakeClientCommand(client,"prop_physics_create props_wasteland/prison_padlock001a.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!paintcan"))
	{
		FakeClientCommand(client,"prop_physics_create props_junk/metal_paintcan001a.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!paper"))
	{
		FakeClientCommand(client,"prop_physics_create props_c17/paper01.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!payphone"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_trainstation/payphone001a.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!pillar"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_canal/bridge_pillar02.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!pliers"))
	{
		FakeClientCommand(client,"prop_physics_create props_c17/tools_pliers01a.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!powertower"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_wasteland/powertower01.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!pushcart"))
	{
		FakeClientCommand(client,"prop_physics_create props_junk/pushcart01a.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!propane"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_c17/canister_propane01a.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!propanebottle"))
	{
		FakeClientCommand(client,"prop_physics_create props_junk/propanecanister001a.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!propanetank"))
	{
		FakeClientCommand(client,"prop_physics_create props_junk/propane_tank001a.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!radiator"))
	{
		FakeClientCommand(client,"prop_physics_create props_interiors/radiator01a.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!satelite"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_rooftop/roof_dish001.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!sawblade"))
	{
		FakeClientCommand(client,"prop_physics_create props_junk/sawblade001a.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!secuirtybank"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_lab/securitybank.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!servers"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_lab/servers.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!shovel"))
	{
		FakeClientCommand(client,"prop_physics_create props_junk/shovel01a.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!thumper1"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_combine/combinethumper001a.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!thumper2"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_combine/combinethumper002.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!toilet1"))
	{
		FakeClientCommand(client,"prop_physics_create props_wasteland/prison_toilet01.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!toilet2"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_c17/furnituretoilet001a.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!trafficlights"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_c17/traffic_light001a.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!train"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_trainstation/train001.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!trainseat"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_trainstation/traincar_seats001.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!trapblade"))
	{
		FakeClientCommand(client,"prop_physics_create props_c17/trappropeller_blade.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!trapengine"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_c17/trappropeller_engine.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!trashbin1"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_junk/trashbin01a.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!trashbin2"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_trainstation/trashcan_indoor001a.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!trashbin3"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_trainstation/trashcan_indoor001b.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!tree"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_foliage/tree_deciduous_01a-lod.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!treeoak"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_foliage/oak_tree01.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!van"))
	{
		FakeClientCommand(client,"prop_physics_create props_vehicles/van001a_physics.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!vendingmachine"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_interiors/vendingmachinesoda01a.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!weaponstripper"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_combine/weaponstripper.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!woodcrate1"))
	{
		FakeClientCommand(client,"prop_physics_create props_junk/wood_crate001a.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!woodcrate2"))
	{
		FakeClientCommand(client,"prop_physics_create props_junk/wood_crate002a.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!wrench"))
	{
		FakeClientCommand(client,"prop_physics_create props_c17/tools_wrench01a.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!turret"))
	{
		FakeClientCommand(client,"prop_physics_create combine_turrets/floor_turret.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!breentp"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_combine/breentp_rings.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!bunkergun"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_combine/bunker_gun01.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!cbarricade1"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_combine/combine_barricade_med01a.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!cbarricade2"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_combine/combine_barricade_med01b.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!cbarricade3"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_combine/combine_barricade_med03b.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!cbarricade4"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_combine/combine_barricade_med04b.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!shortbarricade1"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_combine/combine_barricade_short01a.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!shortbarricade2"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_combine/combine_barricade_short02a.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!shortbarricade3"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_combine/combine_barricade_short03a.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!binocular"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_combine/combine_binocular01.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!booth1"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_combine/combine_booth_med01a.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!booth2"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_combine/combine_booth_short01a.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!bridge1"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_combine/combine_bridge.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!bridge2"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_combine/combine_bridge_b.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!dispenser"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_combine/combine_dispenser.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!emitter"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_combine/combine_emitter01.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!cfence1"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_combine/combine_fence01a.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!cfence2"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_combine/combine_fence01b.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!interface1"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_combine/combine_interface001.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!interface2"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_combine/combine_interface002.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!interface3"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_combine/combine_interface003.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!intmonitor1"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_combine/combine_intmonitor001.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!intmonitor2"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_combine/combine_intmonitor003.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!clight"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_combine/combine_light001a.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!cmine"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_combine/combine_mine01.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!monitorbay"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_combine/combine_monitorbay.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!mortar1"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_combine/combine_mortar01a.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!mortar2"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_combine/combine_mortar01b.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!teleportplatform"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_combine/combine_teleportplatform.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!ctrain1"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_combine/combine_train02a.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!ctrain2"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_combine/combine_train02b.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!cwindow"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_combine/combine_window001.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!cbutton"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_combine/combinebutton.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!thumper1"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_combine/combinethumper001a.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!thumper2"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_combine/combinethumper002.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!cwatchtower"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_combine/combinetower001.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!ctrain3"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_combine/combinetrain01a.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!cheadcrabcanister"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_combine/combinetrain01a.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!masterinterface"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_combine/masterinterface.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!crail1"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_combine/railing_128.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!crail2"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_combine/railing_256.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!crail3"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_combine/railing_512.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	if(StrEqual(prop,"!crailcornerin"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_combine/railing_corner_inside.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}	
	if(StrEqual(prop,"!crailcornerout"))
	{
		FakeClientCommand(client,"prop_dynamic_create props_combine/railing_corner_outside.mdl");
		PrintToChat(client, "\x04[Prop Spawner]\x01 Your prop has been created.");return Plugin_Handled
	}
	return Plugin_Continue;
}