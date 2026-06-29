#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

new Handle:ShowNoBlock;
new String:gMapName[64];

//l4d_hospital01_apartment
new Float:block_pos43[3] = {2048.0, 4608.0, 196.0};

//l4d_hospital03_sewers
new Float:block_pos1[3] = {12644.0, 7145.0, 111.0};
new Float:block_pos2[3] = {14271.0, 11647.0, -265.0};
new Float:block_pos3[3] = {14125.0, 8000.0, -288.0};
new Float:block_pos14[3] = {11408.0, 5415.0, 190.0};
new Float:block_pos34[3] = {11903.0, 8279.0, 261.0};
new Float:block_pos44[3] = {13265.0, 8543.0, -287.0};
new Float:block_pos45[3] = {14128.0, 8192.0, -432.0};

//l4d_hospital04_interior
new Float:block_pos15[3] = {12416.0, 13606.0, 152.0};

//l4d_hospital05_rooftop
new Float:block_pos4[3] = {7017.0, 9327.0, 5893.0};
new Float:block_pos5[3] = {7178.0, 9275.0, 6039.0};
new Float:block_pos6[3] = {6729.0, 8705.0, 6170.0};
new Float:block_pos7[3] = {6669.0, 8379.0, 6001.0};
new Float:block_pos8[3] = {5943.0, 8560.0, 6051.0};
new Float:block_pos35[3] = {6419.0, 9545.0, 5913.0};
new Float:block_pos36[3] = {5877.0, 7463.0, 5923.0};
new Float:block_pos37[3] = {5564.0, 8363.0, 6208.0};
new Float:block_pos46[3] = {7164.0, 8160.0, 5912.0};
new Float:block_pos47[3] = {7681.0, 8803.0, 5910.0};
new Float:block_pos48[3] = {6881.0, 9088.0, 5910.0};
new Float:block_pos49[3] = {6900.0, 9440.0, 5745.0};
new Float:block_pos50[3] = {6505.0, 9440.0, 5744.0};
new Float:block_pos51[3] = {5824.0, 8921.0, 5905.0};
new Float:block_pos52[3] = {5248.0, 8503.0, 5903.0};
new Float:block_pos53[3] = {5824.0, 8082.0, 5904.0};
new Float:block_pos54[3] = {6512.0, 7776.0, 5749.0};

//l4d_farm01_traintunnel
new Float:block_pos38[3] = {-8424.0, -8382.0, 53.0};
new Float:block_pos39[3] = {-8080.0, -8512.0, 50.0};
new Float:block_pos40[3] = {-6871.0, -8512.0, 61.0};
new Float:block_pos41[3] = {-7174.0, -8880.0, 136.0};
new Float:block_pos42[3] = {-8548.0, -8880.0, 131.0};

//l4d_farm02_traintunnel
new Float:block_pos16[3] = {-6746.0, -6458.0, 229.0};
new Float:block_pos65[3] = {-7554.0, -8261.0, 56.0};
new Float:block_pos66[3] = {-6801.0, -8384.0, 49.0};
new Float:block_pos67[3] = {-6479.0, -8260.0, 54.0};
new Float:block_pos68[3] = {-4675.0, -8394.0, 43.0};
new Float:block_pos69[3] = {-4603.0, -8260.0, 49.0};
new Float:block_pos70[3] = {-3819.0, -8429.0, 72.0};
new Float:block_pos71[3] = {-2043.0, -9239.0, 43.0};
new Float:block_pos72[3] = {-6850.0, -8800.0, 52.0};

//l4d_farm03_bridge
new Float:block_pos73[3] = {2103.0, -13604.0, 73.0};
new Float:block_pos74[3] = {4264.0, -13632.0, 77.0};
new Float:block_pos75[3] = {4610.0, -13645.0, 59.0};
new Float:block_pos76[3] = {6824.0, -13920.0, 65.0};
new Float:block_pos77[3] = {6824.0, -13792.0, 68.0};
new Float:block_pos78[3] = {4264.0, -13760.0, 79.0};

//l4d_farm04_barn
new Float:block_pos79[3] = {8358.0, -9218.0, 429.0};
new Float:block_pos80[3] = {10402.0, -8350.0, 25.0};
new Float:block_pos81[3] = {10321.0, -6226.0, 70.0};
new Float:block_pos82[3] = {10351.0, -5628.0, 71.0};
new Float:block_pos83[3] = {10478.0, -5638.0, 71.0};
new Float:block_pos84[3] = {10446.0, -6199.0, 68.0};
new Float:block_pos85[3] = {10504.0, -7002.0, 58.0};
new Float:block_pos86[3] = {10516.0, -4120.0, 74.0};
new Float:block_pos87[3] = {10410.0, -4048.0, 70.0};

//l4d_farm05_cornfield
new Float:block_pos17[3] = {7117.0, 870.0, 380.0};
new Float:block_pos18[3] = {7100.0, 2159.0, 355.0};
new Float:block_pos19[3] = {6523.0, 1513.0, 373.0};
new Float:block_pos20[3] = {6618.0, 875.0, 380.0};
new Float:block_pos88[3] = {10660.0, 3153.0, 59.0};
new Float:block_pos89[3] = {10764.0, 4192.0, 77.0};
new Float:block_pos90[3] = {6985.0, -275.0, 350.0};

//l4d_airport01_greenhouse
new Float:block_pos55[3] = {2979.0, 512.0, 576.0};
new Float:block_pos56[3] = {2875.0, 1280.0, 491.0};
new Float:block_pos57[3] = {2872.0, 1152.0, 586.0};

//l4d_airport02_offices
new Float:block_pos9[3] = {4903.0, 3333.0, 339.0};
new Float:block_pos10[3] = {8287.0, 3846.0, 674.0};
new Float:block_pos58[3] = {6053.0, 3793.0, 628.0};
new Float:block_pos59[3] = {6741.0, 3852.0, 610.0};
new Float:block_pos60[3] = {7951.0, 6265.0, 112.0};
new Float:block_pos127[3] = {6780.0, 3068.0, 484.0};

//l4d_airport03_garage
new Float:block_pos11[3] = {-5939.0, -1621.0, 201.0};
new Float:block_pos12[3] = {-6991.0, -1502.0, 200.0};
new Float:block_pos61[3] = {-5378.0, -2967.0, 112.0};
new Float:block_pos62[3] = {-1120.0, 5307.0, 202.0};

//l4d_airport04_terminal
new Float:block_pos63[3] = {-406.0, 3661.0, 377.0};

//l4d_airport05_runway
new Float:block_pos64[3] = {-6494.0, 8334.0, -75.0};

//l4d_smalltown01_caves
new Float:block_pos91[3] = {-12001.0, -11164.0, -240.0};
new Float:block_pos92[3] = {-12004.0, -11080.0, -87.0};
new Float:block_pos93[3] = {-12912.0, -11127.0, -238.0};
new Float:block_pos94[3] = {-12872.0, -5480.0, -283.0};

//l4d_smalltown02_drainage
new Float:block_pos13[3] = {-10240.0, -7280.0, -529.0};
new Float:block_pos21[3] = {-9872.0, -6906.0, -307.0};
new Float:block_pos22[3] = {-9499.0, -7280.0, -313.0};
new Float:block_pos23[3] = {-8943.0, -8557.0, -306.0};
new Float:block_pos24[3] = {-6687.0, -6879.0, 99.0};
new Float:block_pos25[3] = {-6687.0, -6484.0, 97.0};
new Float:block_pos26[3] = {-6666.0, -5966.0, 211.0};
new Float:block_pos95[3] = {-8322.0, -7760.0, -452.0};
new Float:block_pos96[3] = {-6560.0, -7216.0, -97.0};
new Float:block_pos97[3] = {-8915.0, -8352.0, -431.0};
new Float:block_pos98[3] = {-8712.0, -8714.0, -443.0};

//l4d_smalltown03_ranchhouse
new Float:block_pos27[3] = {-12730.0, -6482.0, 326.0};
new Float:block_pos28[3] = {-12551.0, -5645.0, 323.0};
new Float:block_pos99[3] = {-9006.0, -5743.0, 54.0};
new Float:block_pos100[3] = {-9104.0, -6750.0, 53.0};
new Float:block_pos101[3] = {-9599.0, -6657.0, 50.0};
new Float:block_pos102[3] = {-9814.0, -6288.0, 51.0};
new Float:block_pos103[3] = {-9728.0, -6635.0, 49.0};
new Float:block_pos104[3] = {-9512.0, -7005.0, 50.0};
new Float:block_pos105[3] = {-10672.0, -6096.0, 53.0};
new Float:block_pos106[3] = {-11031.0, -6090.0, 57.0};
new Float:block_pos107[3] = {-11538.0, -6769.0, 49.0};
new Float:block_pos108[3] = {-11623.0, -7169.0, 48.0};
new Float:block_pos109[3] = {-11722.0, -7076.0, 52.0};
new Float:block_pos110[3] = {-11256.0, -5977.0, 53.0};
new Float:block_pos111[3] = {-11012.0, -5887.0, 53.0};
new Float:block_pos112[3] = {-10448.0, -5841.0, 55.0};
new Float:block_pos113[3] = {-10017.0, -5841.0, 55.0};
new Float:block_pos114[3] = {-10363.0, -5743.0, 54.0};
new Float:block_pos115[3] = {-10793.0, -5743.0, 55.0};
new Float:block_pos116[3] = {-11036.0, -5801.0, 54.0};
new Float:block_pos117[3] = {-11605.0, -6064.0, 58.0};
new Float:block_pos118[3] = {-12309.0, -5253.0, 56.0};
new Float:block_pos119[3] = {-12211.0, -4908.0, 55.0};
new Float:block_pos120[3] = {-12214.0, -3917.0, 57.0};
new Float:block_pos121[3] = {-12303.0, -3916.0, 54.0};

//l4d_smalltown04_mainstreet
new Float:block_pos30[3] = {878.0, -2400.0, 171.0};
new Float:block_pos31[3] = {2718.0, -1716.0, 384.0};
new Float:block_pos32[3] = {2131.0, -2374.0, 211.0};
new Float:block_pos33[3] = {188.0, -3140.0, 150.0};
new Float:block_pos122[3] = {-2946.0, -184.0, 291.0};
new Float:block_pos123[3] = {-3198.0, -179.0, 293.0};
new Float:block_pos124[3] = {1894.0, -3584.0, 205.0};
new Float:block_pos125[3] = {-1258.0, -5327.0, 32.0};
new Float:block_pos126[3] = {-3155.0, 40.0, 300.0};

//l4d_smalltown05_houseboat
new Float:block_pos29[3] = {3580.0, -4385.0, 108.0};

//l4d_garage01_alleys
new Float:block_pos128[3] = {-5387.0, -9878.0, 93.0};
new Float:block_pos129[3] = {-2512.0, -5502.0, 97.0};
new Float:block_pos130[3] = {-2916.0, -5375.0, -25.0};

//l4d_garage02_lots
new Float:block_pos131[3] = {7168.0, 5730.0, 187.0};
new Float:block_pos132[3] = {7290.0, 6145.0, 190.0};

//l4d_river01_docks
new Float:block_pos133[3] = {3544.0, 1568.0, 146.0};

//l4d_river02_barge
new Float:block_pos134[3] = {2140.0, 1280.0, 318.0};
new Float:block_pos135[3] = {-511.0, 510.0, 140.0};
new Float:block_pos136[3] = {-3158.0, 887.0, 275.0};
new Float:block_pos137[3] = {-4903.0, -912.0, 168.0};

//#end#block_pos137

public Plugin:myinfo =
{
	name = "[L4D]Infected No Block On Ladder",
	description = "Removes blocking on the ladder.",
	author = "Figa",
	version = "1.1",
	url = "https://forums.alliedmods.net"
};

public OnPluginStart()
{
	HookEvent("round_freeze_end", round_freeze_end);
	ShowNoBlock = CreateConVar("fs_showblock", "0", "1 - Show in chat if you have touched blocking area; 0 - Hide message", FCVAR_PLUGIN|FCVAR_NOTIFY);
}

public round_freeze_end(Handle:event, const String:name[], bool:dontBroadcast)
{
	PrecacheModel("models/error.mdl", true);
	GetCurrentMap(gMapName, sizeof(gMapName));
	if(StrContains(gMapName, "hospital01", false) != -1)
	{
		new trigger_multiple43 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple43, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple43, "wait", "0");
		DispatchSpawn(trigger_multiple43);
		ActivateEntity(trigger_multiple43);
		TeleportEntity(trigger_multiple43, block_pos43, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple43, "models/error.mdl");
		SetEntPropVector(trigger_multiple43, Prop_Send, "m_vecMins", Float: {-40.0, -40.0, -50.0});
		SetEntPropVector(trigger_multiple43, Prop_Send, "m_vecMaxs", Float: {40.0, 40.0, 50.0});
		SetEntProp(trigger_multiple43, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple43, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple43, "OnEndTouch", OnEndTouch);
	}
	else if(StrContains(gMapName, "hospital03", false) != -1)
	{
		new trigger_multiple = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple, "wait", "0");
		DispatchSpawn(trigger_multiple);
		ActivateEntity(trigger_multiple);
		TeleportEntity(trigger_multiple, block_pos1, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple, "models/error.mdl");
		SetEntPropVector(trigger_multiple, Prop_Send, "m_vecMins", Float: {-40.0, -40.0, 0.0});
		SetEntPropVector(trigger_multiple, Prop_Send, "m_vecMaxs", Float: {40.0, 40.0, 200.0});
		SetEntProp(trigger_multiple, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple2 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple2, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple2, "wait", "0");
		DispatchSpawn(trigger_multiple2);
		ActivateEntity(trigger_multiple2);
		TeleportEntity(trigger_multiple2, block_pos2, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple2, "models/error.mdl");
		SetEntPropVector(trigger_multiple2, Prop_Send, "m_vecMins", Float: {-50.0, -50.0, 0.0});
		SetEntPropVector(trigger_multiple2, Prop_Send, "m_vecMaxs", Float: {50.0, 50.0, 300.0});
		SetEntProp(trigger_multiple2, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple2, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple2, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple3 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple3, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple3, "wait", "0");
		DispatchSpawn(trigger_multiple3);
		ActivateEntity(trigger_multiple3);
		TeleportEntity(trigger_multiple3, block_pos3, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple3, "models/error.mdl");
		SetEntPropVector(trigger_multiple3, Prop_Send, "m_vecMins", Float: {-50.0, -50.0, 0.0});
		SetEntPropVector(trigger_multiple3, Prop_Send, "m_vecMaxs", Float: {50.0, 50.0, 100.0});
		SetEntProp(trigger_multiple3, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple3, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple3, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple14 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple14, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple14, "wait", "0");
		DispatchSpawn(trigger_multiple14);
		ActivateEntity(trigger_multiple14);
		TeleportEntity(trigger_multiple14, block_pos14, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple14, "models/error.mdl");
		SetEntPropVector(trigger_multiple14, Prop_Send, "m_vecMins", Float: {-50.0, -50.0, -50.0});
		SetEntPropVector(trigger_multiple14, Prop_Send, "m_vecMaxs", Float: {50.0, 50.0, 100.0});
		SetEntProp(trigger_multiple14, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple14, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple14, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple34 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple34, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple34, "wait", "0");
		DispatchSpawn(trigger_multiple34);
		ActivateEntity(trigger_multiple34);
		TeleportEntity(trigger_multiple34, block_pos34, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple34, "models/error.mdl");
		SetEntPropVector(trigger_multiple34, Prop_Send, "m_vecMins", Float: {-50.0, -50.0, -50.0});
		SetEntPropVector(trigger_multiple34, Prop_Send, "m_vecMaxs", Float: {50.0, 50.0, 50.0});
		SetEntProp(trigger_multiple34, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple34, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple34, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple44 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple44, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple44, "wait", "0");
		DispatchSpawn(trigger_multiple44);
		ActivateEntity(trigger_multiple44);
		TeleportEntity(trigger_multiple44, block_pos44, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple44, "models/error.mdl");
		SetEntPropVector(trigger_multiple44, Prop_Send, "m_vecMins", Float: {-40.0, -40.0, -40.0});
		SetEntPropVector(trigger_multiple44, Prop_Send, "m_vecMaxs", Float: {40.0, 40.0, 40.0});
		SetEntProp(trigger_multiple44, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple44, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple44, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple45 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple45, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple45, "wait", "0");
		DispatchSpawn(trigger_multiple45);
		ActivateEntity(trigger_multiple45);
		TeleportEntity(trigger_multiple45, block_pos45, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple45, "models/error.mdl");
		SetEntPropVector(trigger_multiple45, Prop_Send, "m_vecMins", Float: {-40.0, -40.0, -40.0});
		SetEntPropVector(trigger_multiple45, Prop_Send, "m_vecMaxs", Float: {40.0, 40.0, 40.0});
		SetEntProp(trigger_multiple45, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple45, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple45, "OnEndTouch", OnEndTouch);
	}
	else if(StrContains(gMapName, "hospital04", false) != -1)
	{
		new trigger_multiple15 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple15, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple15, "wait", "0");
		DispatchSpawn(trigger_multiple15);
		ActivateEntity(trigger_multiple15);
		TeleportEntity(trigger_multiple15, block_pos15, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple15, "models/error.mdl");
		SetEntPropVector(trigger_multiple15, Prop_Send, "m_vecMins", Float: {-50.0, -50.0, -50.0});
		SetEntPropVector(trigger_multiple15, Prop_Send, "m_vecMaxs", Float: {50.0, 50.0, 370.0});
		SetEntProp(trigger_multiple15, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple15, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple15, "OnEndTouch", OnEndTouch);
	}
	else if(StrContains(gMapName, "hospital05", false) != -1)
	{
		new trigger_multiple4 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple4, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple4, "wait", "0");
		DispatchSpawn(trigger_multiple4);
		ActivateEntity(trigger_multiple4);
		TeleportEntity(trigger_multiple4, block_pos4, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple4, "models/error.mdl");
		SetEntPropVector(trigger_multiple4, Prop_Send, "m_vecMins", Float: {-25.0, -25.0, 0.0});
		SetEntPropVector(trigger_multiple4, Prop_Send, "m_vecMaxs", Float: {25.0, 25.0, 50.0});
		SetEntProp(trigger_multiple4, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple4, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple4, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple5 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple5, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple5, "wait", "0");
		DispatchSpawn(trigger_multiple5);
		ActivateEntity(trigger_multiple5);
		TeleportEntity(trigger_multiple5, block_pos5, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple5, "models/error.mdl");
		SetEntPropVector(trigger_multiple5, Prop_Send, "m_vecMins", Float: {-50.0, -50.0, 0.0});
		SetEntPropVector(trigger_multiple5, Prop_Send, "m_vecMaxs", Float: {50.0, 50.0, 200.0});
		SetEntProp(trigger_multiple5, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple5, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple5, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple6 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple6, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple6, "wait", "0");
		DispatchSpawn(trigger_multiple6);
		ActivateEntity(trigger_multiple6);
		TeleportEntity(trigger_multiple6, block_pos6, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple6, "models/error.mdl");
		SetEntPropVector(trigger_multiple6, Prop_Send, "m_vecMins", Float: {-25.0, -25.0, 0.0});
		SetEntPropVector(trigger_multiple6, Prop_Send, "m_vecMaxs", Float: {25.0, 25.0, 55.0});
		SetEntProp(trigger_multiple6, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple6, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple6, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple7 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple7, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple7, "wait", "0");
		DispatchSpawn(trigger_multiple7);
		ActivateEntity(trigger_multiple7);
		TeleportEntity(trigger_multiple7, block_pos7, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple7, "models/error.mdl");
		SetEntPropVector(trigger_multiple7, Prop_Send, "m_vecMins", Float: {-25.0, -25.0, 0.0});
		SetEntPropVector(trigger_multiple7, Prop_Send, "m_vecMaxs", Float: {25.0, 25.0, 80.0});
		SetEntProp(trigger_multiple7, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple7, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple7, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple8 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple8, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple8, "wait", "0");
		DispatchSpawn(trigger_multiple8);
		ActivateEntity(trigger_multiple8);
		TeleportEntity(trigger_multiple8, block_pos8, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple8, "models/error.mdl");
		SetEntPropVector(trigger_multiple8, Prop_Send, "m_vecMins", Float: {-40.0, -40.0, 0.0});
		SetEntPropVector(trigger_multiple8, Prop_Send, "m_vecMaxs", Float: {40.0, 40.0, 90.0});
		SetEntProp(trigger_multiple8, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple8, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple8, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple35 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple35, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple35, "wait", "0");
		DispatchSpawn(trigger_multiple35);
		ActivateEntity(trigger_multiple35);
		TeleportEntity(trigger_multiple35, block_pos35, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple35, "models/error.mdl");
		SetEntPropVector(trigger_multiple35, Prop_Send, "m_vecMins", Float: {-40.0, -40.0, -90.0});
		SetEntPropVector(trigger_multiple35, Prop_Send, "m_vecMaxs", Float: {40.0, 40.0, 90.0});
		SetEntProp(trigger_multiple35, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple35, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple35, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple36 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple36, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple36, "wait", "0");
		DispatchSpawn(trigger_multiple36);
		ActivateEntity(trigger_multiple36);
		TeleportEntity(trigger_multiple36, block_pos36, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple36, "models/error.mdl");
		SetEntPropVector(trigger_multiple36, Prop_Send, "m_vecMins", Float: {-40.0, -40.0, -90.0});
		SetEntPropVector(trigger_multiple36, Prop_Send, "m_vecMaxs", Float: {40.0, 40.0, 90.0});
		SetEntProp(trigger_multiple36, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple36, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple36, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple37 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple37, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple37, "wait", "0");
		DispatchSpawn(trigger_multiple37);
		ActivateEntity(trigger_multiple37);
		TeleportEntity(trigger_multiple37, block_pos37, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple37, "models/error.mdl");
		SetEntPropVector(trigger_multiple37, Prop_Send, "m_vecMins", Float: {-40.0, -40.0, -60.0});
		SetEntPropVector(trigger_multiple37, Prop_Send, "m_vecMaxs", Float: {40.0, 40.0, 20.0});
		SetEntProp(trigger_multiple37, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple37, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple37, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple46 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple46, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple46, "wait", "0");
		DispatchSpawn(trigger_multiple46);
		ActivateEntity(trigger_multiple46);
		TeleportEntity(trigger_multiple46, block_pos46, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple46, "models/error.mdl");
		SetEntPropVector(trigger_multiple46, Prop_Send, "m_vecMins", Float: {-50.0, -50.0, -60.0});
		SetEntPropVector(trigger_multiple46, Prop_Send, "m_vecMaxs", Float: {50.0, 50.0, 50.0});
		SetEntProp(trigger_multiple46, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple46, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple46, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple47 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple47, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple47, "wait", "0");
		DispatchSpawn(trigger_multiple47);
		ActivateEntity(trigger_multiple47);
		TeleportEntity(trigger_multiple47, block_pos47, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple47, "models/error.mdl");
		SetEntPropVector(trigger_multiple47, Prop_Send, "m_vecMins", Float: {-50.0, -50.0, -60.0});
		SetEntPropVector(trigger_multiple47, Prop_Send, "m_vecMaxs", Float: {50.0, 50.0, 50.0});
		SetEntProp(trigger_multiple47, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple47, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple47, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple48 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple48, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple48, "wait", "0");
		DispatchSpawn(trigger_multiple48);
		ActivateEntity(trigger_multiple48);
		TeleportEntity(trigger_multiple48, block_pos48, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple48, "models/error.mdl");
		SetEntPropVector(trigger_multiple48, Prop_Send, "m_vecMins", Float: {-50.0, -50.0, -60.0});
		SetEntPropVector(trigger_multiple48, Prop_Send, "m_vecMaxs", Float: {50.0, 50.0, 50.0});
		SetEntProp(trigger_multiple48, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple48, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple48, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple49 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple49, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple49, "wait", "0");
		DispatchSpawn(trigger_multiple49);
		ActivateEntity(trigger_multiple49);
		TeleportEntity(trigger_multiple49, block_pos49, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple49, "models/error.mdl");
		SetEntPropVector(trigger_multiple49, Prop_Send, "m_vecMins", Float: {-50.0, -50.0, -60.0});
		SetEntPropVector(trigger_multiple49, Prop_Send, "m_vecMaxs", Float: {50.0, 50.0, 50.0});
		SetEntProp(trigger_multiple49, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple49, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple49, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple50 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple50, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple50, "wait", "0");
		DispatchSpawn(trigger_multiple50);
		ActivateEntity(trigger_multiple50);
		TeleportEntity(trigger_multiple50, block_pos50, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple50, "models/error.mdl");
		SetEntPropVector(trigger_multiple50, Prop_Send, "m_vecMins", Float: {-50.0, -50.0, -60.0});
		SetEntPropVector(trigger_multiple50, Prop_Send, "m_vecMaxs", Float: {50.0, 50.0, 50.0});
		SetEntProp(trigger_multiple50, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple50, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple50, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple51 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple51, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple51, "wait", "0");
		DispatchSpawn(trigger_multiple51);
		ActivateEntity(trigger_multiple51);
		TeleportEntity(trigger_multiple51, block_pos51, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple51, "models/error.mdl");
		SetEntPropVector(trigger_multiple51, Prop_Send, "m_vecMins", Float: {-50.0, -50.0, -60.0});
		SetEntPropVector(trigger_multiple51, Prop_Send, "m_vecMaxs", Float: {50.0, 50.0, 50.0});
		SetEntProp(trigger_multiple51, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple51, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple51, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple52 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple52, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple52, "wait", "0");
		DispatchSpawn(trigger_multiple52);
		ActivateEntity(trigger_multiple52);
		TeleportEntity(trigger_multiple52, block_pos52, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple52, "models/error.mdl");
		SetEntPropVector(trigger_multiple52, Prop_Send, "m_vecMins", Float: {-50.0, -50.0, -60.0});
		SetEntPropVector(trigger_multiple52, Prop_Send, "m_vecMaxs", Float: {50.0, 50.0, 50.0});
		SetEntProp(trigger_multiple52, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple52, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple52, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple53 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple53, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple53, "wait", "0");
		DispatchSpawn(trigger_multiple53);
		ActivateEntity(trigger_multiple53);
		TeleportEntity(trigger_multiple53, block_pos53, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple53, "models/error.mdl");
		SetEntPropVector(trigger_multiple53, Prop_Send, "m_vecMins", Float: {-50.0, -50.0, -60.0});
		SetEntPropVector(trigger_multiple53, Prop_Send, "m_vecMaxs", Float: {50.0, 50.0, 50.0});
		SetEntProp(trigger_multiple53, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple53, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple53, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple54 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple54, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple54, "wait", "0");
		DispatchSpawn(trigger_multiple54);
		ActivateEntity(trigger_multiple54);
		TeleportEntity(trigger_multiple54, block_pos54, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple54, "models/error.mdl");
		SetEntPropVector(trigger_multiple54, Prop_Send, "m_vecMins", Float: {-50.0, -50.0, -60.0});
		SetEntPropVector(trigger_multiple54, Prop_Send, "m_vecMaxs", Float: {50.0, 50.0, 50.0});
		SetEntProp(trigger_multiple54, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple54, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple54, "OnEndTouch", OnEndTouch);
	}
	else if(StrContains(gMapName, "farm01", false) != -1)
	{
		new trigger_multiple38 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple38, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple38, "wait", "0");
		DispatchSpawn(trigger_multiple38);
		ActivateEntity(trigger_multiple38);
		TeleportEntity(trigger_multiple38, block_pos38, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple38, "models/error.mdl");
		SetEntPropVector(trigger_multiple38, Prop_Send, "m_vecMins", Float: {-40.0, -40.0, -50.0});
		SetEntPropVector(trigger_multiple38, Prop_Send, "m_vecMaxs", Float: {40.0, 40.0, 90.0});
		SetEntProp(trigger_multiple38, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple38, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple38, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple39 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple39, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple39, "wait", "0");
		DispatchSpawn(trigger_multiple39);
		ActivateEntity(trigger_multiple39);
		TeleportEntity(trigger_multiple39, block_pos39, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple39, "models/error.mdl");
		SetEntPropVector(trigger_multiple39, Prop_Send, "m_vecMins", Float: {-40.0, -40.0, -50.0});
		SetEntPropVector(trigger_multiple39, Prop_Send, "m_vecMaxs", Float: {40.0, 40.0, 90.0});
		SetEntProp(trigger_multiple39, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple39, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple39, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple40 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple40, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple40, "wait", "0");
		DispatchSpawn(trigger_multiple40);
		ActivateEntity(trigger_multiple40);
		TeleportEntity(trigger_multiple40, block_pos40, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple40, "models/error.mdl");
		SetEntPropVector(trigger_multiple40, Prop_Send, "m_vecMins", Float: {-40.0, -40.0, -50.0});
		SetEntPropVector(trigger_multiple40, Prop_Send, "m_vecMaxs", Float: {40.0, 40.0, 90.0});
		SetEntProp(trigger_multiple40, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple40, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple40, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple41 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple41, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple41, "wait", "0");
		DispatchSpawn(trigger_multiple41);
		ActivateEntity(trigger_multiple41);
		TeleportEntity(trigger_multiple41, block_pos41, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple41, "models/error.mdl");
		SetEntPropVector(trigger_multiple41, Prop_Send, "m_vecMins", Float: {-40.0, -40.0, -135.0});
		SetEntPropVector(trigger_multiple41, Prop_Send, "m_vecMaxs", Float: {40.0, 40.0, 185.0});
		SetEntProp(trigger_multiple41, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple41, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple41, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple42 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple42, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple42, "wait", "0");
		DispatchSpawn(trigger_multiple42);
		ActivateEntity(trigger_multiple42);
		TeleportEntity(trigger_multiple42, block_pos42, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple42, "models/error.mdl");
		SetEntPropVector(trigger_multiple42, Prop_Send, "m_vecMins", Float: {-40.0, -40.0, -135.0});
		SetEntPropVector(trigger_multiple42, Prop_Send, "m_vecMaxs", Float: {40.0, 40.0, 185.0});
		SetEntProp(trigger_multiple42, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple42, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple42, "OnEndTouch", OnEndTouch);
	}
	else if(StrContains(gMapName, "farm02", false) != -1)
	{
		new trigger_multiple16 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple16, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple16, "wait", "0");
		DispatchSpawn(trigger_multiple16);
		ActivateEntity(trigger_multiple16);
		TeleportEntity(trigger_multiple16, block_pos16, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple16, "models/error.mdl");
		SetEntPropVector(trigger_multiple16, Prop_Send, "m_vecMins", Float: {-40.0, -40.0, -50.0});
		SetEntPropVector(trigger_multiple16, Prop_Send, "m_vecMaxs", Float: {40.0, 40.0, 90.0});
		SetEntProp(trigger_multiple16, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple16, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple16, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple65 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple65, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple65, "wait", "0");
		DispatchSpawn(trigger_multiple65);
		ActivateEntity(trigger_multiple65);
		TeleportEntity(trigger_multiple65, block_pos65, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple65, "models/error.mdl");
		SetEntPropVector(trigger_multiple65, Prop_Send, "m_vecMins", Float: {-40.0, -40.0, -20.0});
		SetEntPropVector(trigger_multiple65, Prop_Send, "m_vecMaxs", Float: {40.0, 40.0, 45.0});
		SetEntProp(trigger_multiple65, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple65, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple65, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple66 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple66, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple66, "wait", "0");
		DispatchSpawn(trigger_multiple66);
		ActivateEntity(trigger_multiple66);
		TeleportEntity(trigger_multiple66, block_pos66, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple66, "models/error.mdl");
		SetEntPropVector(trigger_multiple66, Prop_Send, "m_vecMins", Float: {-40.0, -40.0, -20.0});
		SetEntPropVector(trigger_multiple66, Prop_Send, "m_vecMaxs", Float: {40.0, 40.0, 45.0});
		SetEntProp(trigger_multiple66, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple66, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple66, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple67 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple67, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple67, "wait", "0");
		DispatchSpawn(trigger_multiple67);
		ActivateEntity(trigger_multiple67);
		TeleportEntity(trigger_multiple67, block_pos67, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple67, "models/error.mdl");
		SetEntPropVector(trigger_multiple67, Prop_Send, "m_vecMins", Float: {-40.0, -40.0, -20.0});
		SetEntPropVector(trigger_multiple67, Prop_Send, "m_vecMaxs", Float: {40.0, 40.0, 45.0});
		SetEntProp(trigger_multiple67, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple67, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple67, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple68 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple68, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple68, "wait", "0");
		DispatchSpawn(trigger_multiple68);
		ActivateEntity(trigger_multiple68);
		TeleportEntity(trigger_multiple68, block_pos68, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple68, "models/error.mdl");
		SetEntPropVector(trigger_multiple68, Prop_Send, "m_vecMins", Float: {-40.0, -40.0, -20.0});
		SetEntPropVector(trigger_multiple68, Prop_Send, "m_vecMaxs", Float: {40.0, 40.0, 60.0});
		SetEntProp(trigger_multiple68, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple68, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple68, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple69 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple69, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple69, "wait", "0");
		DispatchSpawn(trigger_multiple69);
		ActivateEntity(trigger_multiple69);
		TeleportEntity(trigger_multiple69, block_pos69, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple69, "models/error.mdl");
		SetEntPropVector(trigger_multiple69, Prop_Send, "m_vecMins", Float: {-40.0, -40.0, -20.0});
		SetEntPropVector(trigger_multiple69, Prop_Send, "m_vecMaxs", Float: {40.0, 40.0, 45.0});
		SetEntProp(trigger_multiple69, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple69, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple69, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple70 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple70, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple70, "wait", "0");
		DispatchSpawn(trigger_multiple70);
		ActivateEntity(trigger_multiple70);
		TeleportEntity(trigger_multiple70, block_pos70, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple70, "models/error.mdl");
		SetEntPropVector(trigger_multiple70, Prop_Send, "m_vecMins", Float: {-40.0, -40.0, -20.0});
		SetEntPropVector(trigger_multiple70, Prop_Send, "m_vecMaxs", Float: {40.0, 40.0, 45.0});
		SetEntProp(trigger_multiple70, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple70, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple70, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple71 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple71, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple71, "wait", "0");
		DispatchSpawn(trigger_multiple71);
		ActivateEntity(trigger_multiple71);
		TeleportEntity(trigger_multiple71, block_pos71, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple71, "models/error.mdl");
		SetEntPropVector(trigger_multiple71, Prop_Send, "m_vecMins", Float: {-40.0, -40.0, -20.0});
		SetEntPropVector(trigger_multiple71, Prop_Send, "m_vecMaxs", Float: {40.0, 40.0, 60.0});
		SetEntProp(trigger_multiple71, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple71, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple71, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple72 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple72, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple72, "wait", "0");
		DispatchSpawn(trigger_multiple72);
		ActivateEntity(trigger_multiple72);
		TeleportEntity(trigger_multiple72, block_pos72, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple72, "models/error.mdl");
		SetEntPropVector(trigger_multiple72, Prop_Send, "m_vecMins", Float: {-40.0, -40.0, -20.0});
		SetEntPropVector(trigger_multiple72, Prop_Send, "m_vecMaxs", Float: {40.0, 40.0, 45.0});
		SetEntProp(trigger_multiple72, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple72, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple72, "OnEndTouch", OnEndTouch);
	}
	else if(StrContains(gMapName, "farm03", false) != -1)
	{
		new trigger_multiple73 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple73, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple73, "wait", "0");
		DispatchSpawn(trigger_multiple73);
		ActivateEntity(trigger_multiple73);
		TeleportEntity(trigger_multiple73, block_pos73, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple73, "models/error.mdl");
		SetEntPropVector(trigger_multiple73, Prop_Send, "m_vecMins", Float: {-40.0, -40.0, -20.0});
		SetEntPropVector(trigger_multiple73, Prop_Send, "m_vecMaxs", Float: {40.0, 40.0, 55.0});
		SetEntProp(trigger_multiple73, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple73, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple73, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple74 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple74, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple74, "wait", "0");
		DispatchSpawn(trigger_multiple74);
		ActivateEntity(trigger_multiple74);
		TeleportEntity(trigger_multiple74, block_pos74, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple74, "models/error.mdl");
		SetEntPropVector(trigger_multiple74, Prop_Send, "m_vecMins", Float: {-40.0, -40.0, -20.0});
		SetEntPropVector(trigger_multiple74, Prop_Send, "m_vecMaxs", Float: {40.0, 40.0, 55.0});
		SetEntProp(trigger_multiple74, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple74, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple74, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple75 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple75, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple75, "wait", "0");
		DispatchSpawn(trigger_multiple75);
		ActivateEntity(trigger_multiple75);
		TeleportEntity(trigger_multiple75, block_pos75, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple75, "models/error.mdl");
		SetEntPropVector(trigger_multiple75, Prop_Send, "m_vecMins", Float: {-40.0, -40.0, -20.0});
		SetEntPropVector(trigger_multiple75, Prop_Send, "m_vecMaxs", Float: {40.0, 40.0, 55.0});
		SetEntProp(trigger_multiple75, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple75, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple75, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple76 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple76, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple76, "wait", "0");
		DispatchSpawn(trigger_multiple76);
		ActivateEntity(trigger_multiple76);
		TeleportEntity(trigger_multiple76, block_pos76, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple76, "models/error.mdl");
		SetEntPropVector(trigger_multiple76, Prop_Send, "m_vecMins", Float: {-40.0, -40.0, -20.0});
		SetEntPropVector(trigger_multiple76, Prop_Send, "m_vecMaxs", Float: {40.0, 40.0, 55.0});
		SetEntProp(trigger_multiple76, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple76, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple76, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple77 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple77, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple77, "wait", "0");
		DispatchSpawn(trigger_multiple77);
		ActivateEntity(trigger_multiple77);
		TeleportEntity(trigger_multiple77, block_pos77, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple77, "models/error.mdl");
		SetEntPropVector(trigger_multiple77, Prop_Send, "m_vecMins", Float: {-40.0, -40.0, -20.0});
		SetEntPropVector(trigger_multiple77, Prop_Send, "m_vecMaxs", Float: {40.0, 40.0, 55.0});
		SetEntProp(trigger_multiple77, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple77, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple77, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple78 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple78, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple78, "wait", "0");
		DispatchSpawn(trigger_multiple78);
		ActivateEntity(trigger_multiple78);
		TeleportEntity(trigger_multiple78, block_pos78, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple78, "models/error.mdl");
		SetEntPropVector(trigger_multiple78, Prop_Send, "m_vecMins", Float: {-40.0, -40.0, -20.0});
		SetEntPropVector(trigger_multiple78, Prop_Send, "m_vecMaxs", Float: {40.0, 40.0, 55.0});
		SetEntProp(trigger_multiple78, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple78, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple78, "OnEndTouch", OnEndTouch);
	}
	else if(StrContains(gMapName, "farm04", false) != -1)
	{
		new trigger_multiple79 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple79, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple79, "wait", "0");
		DispatchSpawn(trigger_multiple79);
		ActivateEntity(trigger_multiple79);
		TeleportEntity(trigger_multiple79, block_pos79, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple79, "models/error.mdl");
		SetEntPropVector(trigger_multiple79, Prop_Send, "m_vecMins", Float: {-40.0, -40.0, -20.0});
		SetEntPropVector(trigger_multiple79, Prop_Send, "m_vecMaxs", Float: {40.0, 40.0, 65.0});
		SetEntProp(trigger_multiple79, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple79, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple79, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple80 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple80, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple80, "wait", "0");
		DispatchSpawn(trigger_multiple80);
		ActivateEntity(trigger_multiple80);
		TeleportEntity(trigger_multiple80, block_pos80, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple80, "models/error.mdl");
		SetEntPropVector(trigger_multiple80, Prop_Send, "m_vecMins", Float: {-40.0, -40.0, -20.0});
		SetEntPropVector(trigger_multiple80, Prop_Send, "m_vecMaxs", Float: {40.0, 40.0, 55.0});
		SetEntProp(trigger_multiple80, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple80, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple80, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple81 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple81, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple81, "wait", "0");
		DispatchSpawn(trigger_multiple81);
		ActivateEntity(trigger_multiple81);
		TeleportEntity(trigger_multiple81, block_pos81, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple81, "models/error.mdl");
		SetEntPropVector(trigger_multiple81, Prop_Send, "m_vecMins", Float: {-40.0, -40.0, -20.0});
		SetEntPropVector(trigger_multiple81, Prop_Send, "m_vecMaxs", Float: {40.0, 40.0, 55.0});
		SetEntProp(trigger_multiple81, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple81, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple81, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple82 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple82, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple82, "wait", "0");
		DispatchSpawn(trigger_multiple82);
		ActivateEntity(trigger_multiple82);
		TeleportEntity(trigger_multiple82, block_pos82, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple82, "models/error.mdl");
		SetEntPropVector(trigger_multiple82, Prop_Send, "m_vecMins", Float: {-40.0, -40.0, -20.0});
		SetEntPropVector(trigger_multiple82, Prop_Send, "m_vecMaxs", Float: {40.0, 40.0, 55.0});
		SetEntProp(trigger_multiple82, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple82, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple82, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple83 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple83, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple83, "wait", "0");
		DispatchSpawn(trigger_multiple83);
		ActivateEntity(trigger_multiple83);
		TeleportEntity(trigger_multiple83, block_pos83, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple83, "models/error.mdl");
		SetEntPropVector(trigger_multiple83, Prop_Send, "m_vecMins", Float: {-40.0, -40.0, -20.0});
		SetEntPropVector(trigger_multiple83, Prop_Send, "m_vecMaxs", Float: {40.0, 40.0, 55.0});
		SetEntProp(trigger_multiple83, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple83, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple83, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple84 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple84, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple84, "wait", "0");
		DispatchSpawn(trigger_multiple84);
		ActivateEntity(trigger_multiple84);
		TeleportEntity(trigger_multiple84, block_pos84, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple84, "models/error.mdl");
		SetEntPropVector(trigger_multiple84, Prop_Send, "m_vecMins", Float: {-40.0, -40.0, -20.0});
		SetEntPropVector(trigger_multiple84, Prop_Send, "m_vecMaxs", Float: {40.0, 40.0, 55.0});
		SetEntProp(trigger_multiple84, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple84, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple84, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple85 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple85, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple85, "wait", "0");
		DispatchSpawn(trigger_multiple85);
		ActivateEntity(trigger_multiple85);
		TeleportEntity(trigger_multiple85, block_pos85, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple85, "models/error.mdl");
		SetEntPropVector(trigger_multiple85, Prop_Send, "m_vecMins", Float: {-40.0, -40.0, -20.0});
		SetEntPropVector(trigger_multiple85, Prop_Send, "m_vecMaxs", Float: {40.0, 40.0, 55.0});
		SetEntProp(trigger_multiple85, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple85, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple85, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple86 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple86, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple86, "wait", "0");
		DispatchSpawn(trigger_multiple86);
		ActivateEntity(trigger_multiple86);
		TeleportEntity(trigger_multiple86, block_pos86, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple86, "models/error.mdl");
		SetEntPropVector(trigger_multiple86, Prop_Send, "m_vecMins", Float: {-40.0, -40.0, -20.0});
		SetEntPropVector(trigger_multiple86, Prop_Send, "m_vecMaxs", Float: {40.0, 40.0, 55.0});
		SetEntProp(trigger_multiple86, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple86, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple86, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple87 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple87, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple87, "wait", "0");
		DispatchSpawn(trigger_multiple87);
		ActivateEntity(trigger_multiple87);
		TeleportEntity(trigger_multiple87, block_pos87, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple87, "models/error.mdl");
		SetEntPropVector(trigger_multiple87, Prop_Send, "m_vecMins", Float: {-40.0, -40.0, -20.0});
		SetEntPropVector(trigger_multiple87, Prop_Send, "m_vecMaxs", Float: {40.0, 40.0, 55.0});
		SetEntProp(trigger_multiple87, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple87, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple87, "OnEndTouch", OnEndTouch);
	}
	else if(StrContains(gMapName, "farm05", false) != -1)
	{
		new trigger_multiple17 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple17, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple17, "wait", "0");
		DispatchSpawn(trigger_multiple17);
		ActivateEntity(trigger_multiple17);
		TeleportEntity(trigger_multiple17, block_pos17, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple17, "models/error.mdl");
		SetEntPropVector(trigger_multiple17, Prop_Send, "m_vecMins", Float: {-40.0, -40.0, -40.0});
		SetEntPropVector(trigger_multiple17, Prop_Send, "m_vecMaxs", Float: {40.0, 40.0, 90.0});
		SetEntProp(trigger_multiple17, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple17, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple17, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple18 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple18, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple18, "wait", "0");
		DispatchSpawn(trigger_multiple18);
		ActivateEntity(trigger_multiple18);
		TeleportEntity(trigger_multiple18, block_pos18, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple18, "models/error.mdl");
		SetEntPropVector(trigger_multiple18, Prop_Send, "m_vecMins", Float: {-40.0, -40.0, -40.0});
		SetEntPropVector(trigger_multiple18, Prop_Send, "m_vecMaxs", Float: {40.0, 40.0, 90.0});
		SetEntProp(trigger_multiple18, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple18, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple18, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple19 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple19, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple19, "wait", "0");
		DispatchSpawn(trigger_multiple19);
		ActivateEntity(trigger_multiple19);
		TeleportEntity(trigger_multiple19, block_pos19, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple19, "models/error.mdl");
		SetEntPropVector(trigger_multiple19, Prop_Send, "m_vecMins", Float: {-40.0, -40.0, -40.0});
		SetEntPropVector(trigger_multiple19, Prop_Send, "m_vecMaxs", Float: {40.0, 40.0, 90.0});
		SetEntProp(trigger_multiple19, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple19, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple19, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple20 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple20, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple20, "wait", "0");
		DispatchSpawn(trigger_multiple20);
		ActivateEntity(trigger_multiple20);
		TeleportEntity(trigger_multiple20, block_pos20, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple20, "models/error.mdl");
		SetEntPropVector(trigger_multiple20, Prop_Send, "m_vecMins", Float: {-40.0, -40.0, -40.0});
		SetEntPropVector(trigger_multiple20, Prop_Send, "m_vecMaxs", Float: {40.0, 40.0, 90.0});
		SetEntProp(trigger_multiple20, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple20, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple20, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple88 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple88, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple88, "wait", "0");
		DispatchSpawn(trigger_multiple88);
		ActivateEntity(trigger_multiple88);
		TeleportEntity(trigger_multiple88, block_pos88, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple88, "models/error.mdl");
		SetEntPropVector(trigger_multiple88, Prop_Send, "m_vecMins", Float: {-40.0, -40.0, -20.0});
		SetEntPropVector(trigger_multiple88, Prop_Send, "m_vecMaxs", Float: {40.0, 40.0, 55.0});
		SetEntProp(trigger_multiple88, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple88, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple88, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple89 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple89, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple89, "wait", "0");
		DispatchSpawn(trigger_multiple89);
		ActivateEntity(trigger_multiple89);
		TeleportEntity(trigger_multiple89, block_pos89, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple89, "models/error.mdl");
		SetEntPropVector(trigger_multiple89, Prop_Send, "m_vecMins", Float: {-40.0, -40.0, -20.0});
		SetEntPropVector(trigger_multiple89, Prop_Send, "m_vecMaxs", Float: {40.0, 40.0, 55.0});
		SetEntProp(trigger_multiple89, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple89, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple89, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple90 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple90, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple90, "wait", "0");
		DispatchSpawn(trigger_multiple90);
		ActivateEntity(trigger_multiple90);
		TeleportEntity(trigger_multiple90, block_pos90, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple90, "models/error.mdl");
		SetEntPropVector(trigger_multiple90, Prop_Send, "m_vecMins", Float: {-40.0, -40.0, -20.0});
		SetEntPropVector(trigger_multiple90, Prop_Send, "m_vecMaxs", Float: {40.0, 40.0, 65.0});
		SetEntProp(trigger_multiple90, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple90, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple90, "OnEndTouch", OnEndTouch);
	}
	else if(StrContains(gMapName, "airport01", false) != -1)
	{	
		new trigger_multiple55 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple55, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple55, "wait", "0");
		DispatchSpawn(trigger_multiple55);
		ActivateEntity(trigger_multiple55);
		TeleportEntity(trigger_multiple55, block_pos55, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple55, "models/error.mdl");
		SetEntPropVector(trigger_multiple55, Prop_Send, "m_vecMins", Float: {-50.0, -50.0, -60.0});
		SetEntPropVector(trigger_multiple55, Prop_Send, "m_vecMaxs", Float: {50.0, 50.0, 50.0});
		SetEntProp(trigger_multiple55, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple55, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple55, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple56 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple56, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple56, "wait", "0");
		DispatchSpawn(trigger_multiple56);
		ActivateEntity(trigger_multiple56);
		TeleportEntity(trigger_multiple56, block_pos56, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple56, "models/error.mdl");
		SetEntPropVector(trigger_multiple56, Prop_Send, "m_vecMins", Float: {-50.0, -50.0, -60.0});
		SetEntPropVector(trigger_multiple56, Prop_Send, "m_vecMaxs", Float: {50.0, 50.0, 50.0});
		SetEntProp(trigger_multiple56, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple56, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple56, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple57 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple57, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple57, "wait", "0");
		DispatchSpawn(trigger_multiple57);
		ActivateEntity(trigger_multiple57);
		TeleportEntity(trigger_multiple57, block_pos57, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple57, "models/error.mdl");
		SetEntPropVector(trigger_multiple57, Prop_Send, "m_vecMins", Float: {-50.0, -50.0, -60.0});
		SetEntPropVector(trigger_multiple57, Prop_Send, "m_vecMaxs", Float: {50.0, 50.0, 50.0});
		SetEntProp(trigger_multiple57, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple57, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple57, "OnEndTouch", OnEndTouch);
	}
	else if(StrContains(gMapName, "airport02", false) != -1)
	{
		new trigger_multiple9 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple9, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple9, "wait", "0");
		DispatchSpawn(trigger_multiple9);
		ActivateEntity(trigger_multiple9);
		TeleportEntity(trigger_multiple9, block_pos9, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple9, "models/error.mdl");
		SetEntPropVector(trigger_multiple9, Prop_Send, "m_vecMins", Float: {-25.0, -25.0, -40.0});
		SetEntPropVector(trigger_multiple9, Prop_Send, "m_vecMaxs", Float: {25.0, 25.0, 50.0});
		SetEntProp(trigger_multiple9, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple9, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple9, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple10 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple10, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple10, "wait", "0");
		DispatchSpawn(trigger_multiple10);
		ActivateEntity(trigger_multiple10);
		TeleportEntity(trigger_multiple10, block_pos10, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple10, "models/error.mdl");
		SetEntPropVector(trigger_multiple10, Prop_Send, "m_vecMins", Float: {-35.0, -30.0, 0.0});
		SetEntPropVector(trigger_multiple10, Prop_Send, "m_vecMaxs", Float: {35.0, 30.0, 25.0});
		SetEntProp(trigger_multiple10, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple10, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple10, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple58 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple58, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple58, "wait", "0");
		DispatchSpawn(trigger_multiple58);
		ActivateEntity(trigger_multiple58);
		TeleportEntity(trigger_multiple58, block_pos58, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple58, "models/error.mdl");
		SetEntPropVector(trigger_multiple58, Prop_Send, "m_vecMins", Float: {-40.0, -40.0, -40.0});
		SetEntPropVector(trigger_multiple58, Prop_Send, "m_vecMaxs", Float: {40.0, 40.0, 40.0});
		SetEntProp(trigger_multiple58, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple58, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple58, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple59 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple59, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple59, "wait", "0");
		DispatchSpawn(trigger_multiple59);
		ActivateEntity(trigger_multiple59);
		TeleportEntity(trigger_multiple59, block_pos59, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple59, "models/error.mdl");
		SetEntPropVector(trigger_multiple59, Prop_Send, "m_vecMins", Float: {-40.0, -40.0, -40.0});
		SetEntPropVector(trigger_multiple59, Prop_Send, "m_vecMaxs", Float: {40.0, 40.0, 40.0});
		SetEntProp(trigger_multiple59, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple59, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple59, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple60 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple60, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple60, "wait", "0");
		DispatchSpawn(trigger_multiple60);
		ActivateEntity(trigger_multiple60);
		TeleportEntity(trigger_multiple60, block_pos60, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple60, "models/error.mdl");
		SetEntPropVector(trigger_multiple60, Prop_Send, "m_vecMins", Float: {-40.0, -40.0, -40.0});
		SetEntPropVector(trigger_multiple60, Prop_Send, "m_vecMaxs", Float: {40.0, 40.0, 40.0});
		SetEntProp(trigger_multiple60, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple60, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple60, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple127 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple127, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple127, "wait", "0");
		DispatchSpawn(trigger_multiple127);
		ActivateEntity(trigger_multiple127);
		TeleportEntity(trigger_multiple127, block_pos127, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple127, "models/error.mdl");
		SetEntPropVector(trigger_multiple127, Prop_Send, "m_vecMins", Float: {-40.0, -40.0, -40.0});
		SetEntPropVector(trigger_multiple127, Prop_Send, "m_vecMaxs", Float: {40.0, 40.0, 80.0});
		SetEntProp(trigger_multiple127, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple127, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple127, "OnEndTouch", OnEndTouch);
	}
	else if(StrContains(gMapName, "airport03", false) != -1)
	{
		new trigger_multiple11 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple11, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple11, "wait", "0");
		DispatchSpawn(trigger_multiple11);
		ActivateEntity(trigger_multiple11);
		TeleportEntity(trigger_multiple11, block_pos11, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple11, "models/error.mdl");
		SetEntPropVector(trigger_multiple11, Prop_Send, "m_vecMins", Float: {-45.0, -25.0, -10.0});
		SetEntPropVector(trigger_multiple11, Prop_Send, "m_vecMaxs", Float: {25.0, 25.0, 50.0});
		SetEntProp(trigger_multiple11, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple11, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple11, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple12 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple12, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple12, "wait", "0");
		DispatchSpawn(trigger_multiple12);
		ActivateEntity(trigger_multiple12);
		TeleportEntity(trigger_multiple12, block_pos12, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple12, "models/error.mdl");
		SetEntPropVector(trigger_multiple12, Prop_Send, "m_vecMins", Float: {-35.0, -30.0, 0.0});
		SetEntPropVector(trigger_multiple12, Prop_Send, "m_vecMaxs", Float: {35.0, 40.0, 50.0});
		SetEntProp(trigger_multiple12, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple12, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple12, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple61 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple61, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple61, "wait", "0");
		DispatchSpawn(trigger_multiple61);
		ActivateEntity(trigger_multiple61);
		TeleportEntity(trigger_multiple61, block_pos61, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple61, "models/error.mdl");
		SetEntPropVector(trigger_multiple61, Prop_Send, "m_vecMins", Float: {-35.0, -35.0, -10.0});
		SetEntPropVector(trigger_multiple61, Prop_Send, "m_vecMaxs", Float: {35.0, 35.0, 50.0});
		SetEntProp(trigger_multiple61, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple61, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple61, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple62 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple62, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple62, "wait", "0");
		DispatchSpawn(trigger_multiple62);
		ActivateEntity(trigger_multiple62);
		TeleportEntity(trigger_multiple62, block_pos62, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple62, "models/error.mdl");
		SetEntPropVector(trigger_multiple62, Prop_Send, "m_vecMins", Float: {-50.0, -50.0, -70.0});
		SetEntPropVector(trigger_multiple62, Prop_Send, "m_vecMaxs", Float: {50.0, 50.0, 150.0});
		SetEntProp(trigger_multiple62, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple62, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple62, "OnEndTouch", OnEndTouch);
	}
	else if(StrContains(gMapName, "airport04", false) != -1)
	{
		new trigger_multiple63 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple63, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple63, "wait", "0");
		DispatchSpawn(trigger_multiple63);
		ActivateEntity(trigger_multiple63);
		TeleportEntity(trigger_multiple63, block_pos63, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple63, "models/error.mdl");
		SetEntPropVector(trigger_multiple63, Prop_Send, "m_vecMins", Float: {-40.0, -40.0, -20.0});
		SetEntPropVector(trigger_multiple63, Prop_Send, "m_vecMaxs", Float: {40.0, 40.0, 40.0});
		SetEntProp(trigger_multiple63, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple63, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple63, "OnEndTouch", OnEndTouch);
	}
	else if(StrContains(gMapName, "airport05", false) != -1)
	{
		new trigger_multiple64 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple64, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple64, "wait", "0");
		DispatchSpawn(trigger_multiple64);
		ActivateEntity(trigger_multiple64);
		TeleportEntity(trigger_multiple64, block_pos64, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple64, "models/error.mdl");
		SetEntPropVector(trigger_multiple64, Prop_Send, "m_vecMins", Float: {-40.0, -40.0, -20.0});
		SetEntPropVector(trigger_multiple64, Prop_Send, "m_vecMaxs", Float: {40.0, 40.0, 40.0});
		SetEntProp(trigger_multiple64, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple64, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple64, "OnEndTouch", OnEndTouch);
	}
	else if(StrContains(gMapName, "smalltown01", false) != -1)
	{
		new trigger_multiple91 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple91, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple91, "wait", "0");
		DispatchSpawn(trigger_multiple91);
		ActivateEntity(trigger_multiple91);
		TeleportEntity(trigger_multiple91, block_pos91, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple91, "models/error.mdl");
		SetEntPropVector(trigger_multiple91, Prop_Send, "m_vecMins", Float: {-40.0, -40.0, -120.0});
		SetEntPropVector(trigger_multiple91, Prop_Send, "m_vecMaxs", Float: {40.0, 40.0, 100.0});
		SetEntProp(trigger_multiple91, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple91, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple91, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple92 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple92, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple92, "wait", "0");
		DispatchSpawn(trigger_multiple92);
		ActivateEntity(trigger_multiple92);
		TeleportEntity(trigger_multiple92, block_pos92, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple92, "models/error.mdl");
		SetEntPropVector(trigger_multiple92, Prop_Send, "m_vecMins", Float: {-40.0, -40.0, -120.0});
		SetEntPropVector(trigger_multiple92, Prop_Send, "m_vecMaxs", Float: {40.0, 40.0, 100.0});
		SetEntProp(trigger_multiple92, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple92, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple92, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple93 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple93, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple93, "wait", "0");
		DispatchSpawn(trigger_multiple93);
		ActivateEntity(trigger_multiple93);
		TeleportEntity(trigger_multiple93, block_pos93, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple93, "models/error.mdl");
		SetEntPropVector(trigger_multiple93, Prop_Send, "m_vecMins", Float: {-40.0, -40.0, -120.0});
		SetEntPropVector(trigger_multiple93, Prop_Send, "m_vecMaxs", Float: {40.0, 40.0, 100.0});
		SetEntProp(trigger_multiple93, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple93, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple93, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple94 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple94, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple94, "wait", "0");
		DispatchSpawn(trigger_multiple94);
		ActivateEntity(trigger_multiple94);
		TeleportEntity(trigger_multiple94, block_pos94, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple94, "models/error.mdl");
		SetEntPropVector(trigger_multiple94, Prop_Send, "m_vecMins", Float: {-40.0, -40.0, -120.0});
		SetEntPropVector(trigger_multiple94, Prop_Send, "m_vecMaxs", Float: {40.0, 40.0, 100.0});
		SetEntProp(trigger_multiple94, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple94, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple94, "OnEndTouch", OnEndTouch);
	}	
	else if(StrContains(gMapName, "smalltown02", false) != -1)
	{
		new trigger_multiple13 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple13, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple13, "wait", "0");
		DispatchSpawn(trigger_multiple13);
		ActivateEntity(trigger_multiple13);
		TeleportEntity(trigger_multiple13, block_pos13, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple13, "models/error.mdl");
		SetEntPropVector(trigger_multiple13, Prop_Send, "m_vecMins", Float: {-40.0, -40.0, -50.0});
		SetEntPropVector(trigger_multiple13, Prop_Send, "m_vecMaxs", Float: {40.0, 40.0, 140.0});
		SetEntProp(trigger_multiple13, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple13, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple13, "OnEndTouch", OnEndTouch);
	
		new trigger_multiple21 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple21, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple21, "wait", "0");
		DispatchSpawn(trigger_multiple21);
		ActivateEntity(trigger_multiple21);
		TeleportEntity(trigger_multiple21, block_pos21, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple21, "models/error.mdl");
		SetEntPropVector(trigger_multiple21, Prop_Send, "m_vecMins", Float: {-25.0, -25.0, -25.0});
		SetEntPropVector(trigger_multiple21, Prop_Send, "m_vecMaxs", Float: {25.0, 25.0, 50.0});
		SetEntProp(trigger_multiple21, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple21, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple21, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple22 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple22, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple22, "wait", "0");
		DispatchSpawn(trigger_multiple22);
		ActivateEntity(trigger_multiple22);
		TeleportEntity(trigger_multiple22, block_pos22, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple22, "models/error.mdl");
		SetEntPropVector(trigger_multiple22, Prop_Send, "m_vecMins", Float: {-25.0, -25.0, -25.0});
		SetEntPropVector(trigger_multiple22, Prop_Send, "m_vecMaxs", Float: {25.0, 25.0, 50.0});
		SetEntProp(trigger_multiple22, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple22, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple22, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple23 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple23, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple23, "wait", "0");
		DispatchSpawn(trigger_multiple23);
		ActivateEntity(trigger_multiple23);
		TeleportEntity(trigger_multiple23, block_pos23, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple23, "models/error.mdl");
		SetEntPropVector(trigger_multiple23, Prop_Send, "m_vecMins", Float: {-25.0, -25.0, -25.0});
		SetEntPropVector(trigger_multiple23, Prop_Send, "m_vecMaxs", Float: {25.0, 25.0, 50.0});
		SetEntProp(trigger_multiple23, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple23, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple23, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple24 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple24, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple24, "wait", "0");
		DispatchSpawn(trigger_multiple24);
		ActivateEntity(trigger_multiple24);
		TeleportEntity(trigger_multiple24, block_pos24, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple24, "models/error.mdl");
		SetEntPropVector(trigger_multiple24, Prop_Send, "m_vecMins", Float: {-25.0, -25.0, -30.0});
		SetEntPropVector(trigger_multiple24, Prop_Send, "m_vecMaxs", Float: {25.0, 25.0, 50.0});
		SetEntProp(trigger_multiple24, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple24, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple24, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple25 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple25, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple25, "wait", "0");
		DispatchSpawn(trigger_multiple25);
		ActivateEntity(trigger_multiple25);
		TeleportEntity(trigger_multiple25, block_pos25, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple25, "models/error.mdl");
		SetEntPropVector(trigger_multiple25, Prop_Send, "m_vecMins", Float: {-25.0, -25.0, -30.0});
		SetEntPropVector(trigger_multiple25, Prop_Send, "m_vecMaxs", Float: {25.0, 25.0, 50.0});
		SetEntProp(trigger_multiple25, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple25, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple25, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple26 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple26, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple26, "wait", "0");
		DispatchSpawn(trigger_multiple26);
		ActivateEntity(trigger_multiple26);
		TeleportEntity(trigger_multiple26, block_pos26, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple26, "models/error.mdl");
		SetEntPropVector(trigger_multiple26, Prop_Send, "m_vecMins", Float: {-25.0, -30.0, -30.0});
		SetEntPropVector(trigger_multiple26, Prop_Send, "m_vecMaxs", Float: {25.0, 25.0, 50.0});
		SetEntProp(trigger_multiple26, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple26, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple26, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple95 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple95, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple95, "wait", "0");
		DispatchSpawn(trigger_multiple95);
		ActivateEntity(trigger_multiple95);
		TeleportEntity(trigger_multiple95, block_pos95, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple95, "models/error.mdl");
		SetEntPropVector(trigger_multiple95, Prop_Send, "m_vecMins", Float: {-25.0, -30.0, -30.0});
		SetEntPropVector(trigger_multiple95, Prop_Send, "m_vecMaxs", Float: {25.0, 25.0, 40.0});
		SetEntProp(trigger_multiple95, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple95, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple95, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple96 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple96, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple96, "wait", "0");
		DispatchSpawn(trigger_multiple96);
		ActivateEntity(trigger_multiple96);
		TeleportEntity(trigger_multiple96, block_pos96, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple96, "models/error.mdl");
		SetEntPropVector(trigger_multiple96, Prop_Send, "m_vecMins", Float: {-25.0, -30.0, -30.0});
		SetEntPropVector(trigger_multiple96, Prop_Send, "m_vecMaxs", Float: {25.0, 25.0, 40.0});
		SetEntProp(trigger_multiple96, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple96, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple96, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple97 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple97, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple97, "wait", "0");
		DispatchSpawn(trigger_multiple97);
		ActivateEntity(trigger_multiple97);
		TeleportEntity(trigger_multiple97, block_pos97, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple97, "models/error.mdl");
		SetEntPropVector(trigger_multiple97, Prop_Send, "m_vecMins", Float: {-25.0, -30.0, -30.0});
		SetEntPropVector(trigger_multiple97, Prop_Send, "m_vecMaxs", Float: {25.0, 25.0, 50.0});
		SetEntProp(trigger_multiple97, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple97, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple97, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple98 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple98, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple98, "wait", "0");
		DispatchSpawn(trigger_multiple98);
		ActivateEntity(trigger_multiple98);
		TeleportEntity(trigger_multiple98, block_pos98, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple98, "models/error.mdl");
		SetEntPropVector(trigger_multiple98, Prop_Send, "m_vecMins", Float: {-25.0, -30.0, -50.0});
		SetEntPropVector(trigger_multiple98, Prop_Send, "m_vecMaxs", Float: {25.0, 25.0, 70.0});
		SetEntProp(trigger_multiple98, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple98, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple98, "OnEndTouch", OnEndTouch);
	}
	else if(StrContains(gMapName, "smalltown03", false) != -1)
	{
		new trigger_multiple99 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple99, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple99, "wait", "0");
		DispatchSpawn(trigger_multiple99);
		ActivateEntity(trigger_multiple99);
		TeleportEntity(trigger_multiple99, block_pos99, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple99, "models/error.mdl");
		SetEntPropVector(trigger_multiple99, Prop_Send, "m_vecMins", Float: {-30.0, -30.0, -30.0});
		SetEntPropVector(trigger_multiple99, Prop_Send, "m_vecMaxs", Float: {30.0, 30.0, 50.0});
		SetEntProp(trigger_multiple99, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple99, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple99, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple100 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple100, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple100, "wait", "0");
		DispatchSpawn(trigger_multiple100);
		ActivateEntity(trigger_multiple100);
		TeleportEntity(trigger_multiple100, block_pos100, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple100, "models/error.mdl");
		SetEntPropVector(trigger_multiple100, Prop_Send, "m_vecMins", Float: {-30.0, -30.0, -30.0});
		SetEntPropVector(trigger_multiple100, Prop_Send, "m_vecMaxs", Float: {30.0, 30.0, 50.0});
		SetEntProp(trigger_multiple100, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple100, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple100, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple101 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple101, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple101, "wait", "0");
		DispatchSpawn(trigger_multiple101);
		ActivateEntity(trigger_multiple101);
		TeleportEntity(trigger_multiple101, block_pos101, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple101, "models/error.mdl");
		SetEntPropVector(trigger_multiple101, Prop_Send, "m_vecMins", Float: {-30.0, -30.0, -30.0});
		SetEntPropVector(trigger_multiple101, Prop_Send, "m_vecMaxs", Float: {30.0, 30.0, 50.0});
		SetEntProp(trigger_multiple101, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple101, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple101, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple102 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple102, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple102, "wait", "0");
		DispatchSpawn(trigger_multiple102);
		ActivateEntity(trigger_multiple102);
		TeleportEntity(trigger_multiple102, block_pos102, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple102, "models/error.mdl");
		SetEntPropVector(trigger_multiple102, Prop_Send, "m_vecMins", Float: {-30.0, -30.0, -30.0});
		SetEntPropVector(trigger_multiple102, Prop_Send, "m_vecMaxs", Float: {30.0, 30.0, 50.0});
		SetEntProp(trigger_multiple102, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple102, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple102, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple103 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple103, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple103, "wait", "0");
		DispatchSpawn(trigger_multiple103);
		ActivateEntity(trigger_multiple103);
		TeleportEntity(trigger_multiple103, block_pos103, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple103, "models/error.mdl");
		SetEntPropVector(trigger_multiple103, Prop_Send, "m_vecMins", Float: {-30.0, -30.0, -30.0});
		SetEntPropVector(trigger_multiple103, Prop_Send, "m_vecMaxs", Float: {30.0, 30.0, 50.0});
		SetEntProp(trigger_multiple103, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple103, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple103, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple104 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple104, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple104, "wait", "0");
		DispatchSpawn(trigger_multiple104);
		ActivateEntity(trigger_multiple104);
		TeleportEntity(trigger_multiple104, block_pos104, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple104, "models/error.mdl");
		SetEntPropVector(trigger_multiple104, Prop_Send, "m_vecMins", Float: {-30.0, -30.0, -30.0});
		SetEntPropVector(trigger_multiple104, Prop_Send, "m_vecMaxs", Float: {30.0, 30.0, 50.0});
		SetEntProp(trigger_multiple104, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple104, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple104, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple105 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple105, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple105, "wait", "0");
		DispatchSpawn(trigger_multiple105);
		ActivateEntity(trigger_multiple105);
		TeleportEntity(trigger_multiple105, block_pos105, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple105, "models/error.mdl");
		SetEntPropVector(trigger_multiple105, Prop_Send, "m_vecMins", Float: {-30.0, -30.0, -30.0});
		SetEntPropVector(trigger_multiple105, Prop_Send, "m_vecMaxs", Float: {30.0, 30.0, 50.0});
		SetEntProp(trigger_multiple105, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple105, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple105, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple106 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple106, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple106, "wait", "0");
		DispatchSpawn(trigger_multiple106);
		ActivateEntity(trigger_multiple106);
		TeleportEntity(trigger_multiple106, block_pos106, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple106, "models/error.mdl");
		SetEntPropVector(trigger_multiple106, Prop_Send, "m_vecMins", Float: {-30.0, -30.0, -30.0});
		SetEntPropVector(trigger_multiple106, Prop_Send, "m_vecMaxs", Float: {30.0, 30.0, 50.0});
		SetEntProp(trigger_multiple106, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple106, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple106, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple107 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple107, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple107, "wait", "0");
		DispatchSpawn(trigger_multiple107);
		ActivateEntity(trigger_multiple107);
		TeleportEntity(trigger_multiple107, block_pos107, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple107, "models/error.mdl");
		SetEntPropVector(trigger_multiple107, Prop_Send, "m_vecMins", Float: {-30.0, -30.0, -30.0});
		SetEntPropVector(trigger_multiple107, Prop_Send, "m_vecMaxs", Float: {30.0, 30.0, 50.0});
		SetEntProp(trigger_multiple107, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple107, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple107, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple108 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple108, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple108, "wait", "0");
		DispatchSpawn(trigger_multiple108);
		ActivateEntity(trigger_multiple108);
		TeleportEntity(trigger_multiple108, block_pos108, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple108, "models/error.mdl");
		SetEntPropVector(trigger_multiple108, Prop_Send, "m_vecMins", Float: {-30.0, -30.0, -30.0});
		SetEntPropVector(trigger_multiple108, Prop_Send, "m_vecMaxs", Float: {30.0, 30.0, 50.0});
		SetEntProp(trigger_multiple108, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple108, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple108, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple109 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple109, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple109, "wait", "0");
		DispatchSpawn(trigger_multiple109);
		ActivateEntity(trigger_multiple109);
		TeleportEntity(trigger_multiple109, block_pos109, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple109, "models/error.mdl");
		SetEntPropVector(trigger_multiple109, Prop_Send, "m_vecMins", Float: {-30.0, -30.0, -30.0});
		SetEntPropVector(trigger_multiple109, Prop_Send, "m_vecMaxs", Float: {30.0, 30.0, 50.0});
		SetEntProp(trigger_multiple109, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple109, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple109, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple110 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple110, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple110, "wait", "0");
		DispatchSpawn(trigger_multiple110);
		ActivateEntity(trigger_multiple110);
		TeleportEntity(trigger_multiple110, block_pos110, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple110, "models/error.mdl");
		SetEntPropVector(trigger_multiple110, Prop_Send, "m_vecMins", Float: {-30.0, -30.0, -30.0});
		SetEntPropVector(trigger_multiple110, Prop_Send, "m_vecMaxs", Float: {30.0, 30.0, 50.0});
		SetEntProp(trigger_multiple110, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple110, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple110, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple111 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple111, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple111, "wait", "0");
		DispatchSpawn(trigger_multiple111);
		ActivateEntity(trigger_multiple111);
		TeleportEntity(trigger_multiple111, block_pos111, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple111, "models/error.mdl");
		SetEntPropVector(trigger_multiple111, Prop_Send, "m_vecMins", Float: {-30.0, -30.0, -30.0});
		SetEntPropVector(trigger_multiple111, Prop_Send, "m_vecMaxs", Float: {30.0, 30.0, 50.0});
		SetEntProp(trigger_multiple111, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple111, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple111, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple112 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple112, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple112, "wait", "0");
		DispatchSpawn(trigger_multiple112);
		ActivateEntity(trigger_multiple112);
		TeleportEntity(trigger_multiple112, block_pos112, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple112, "models/error.mdl");
		SetEntPropVector(trigger_multiple112, Prop_Send, "m_vecMins", Float: {-30.0, -30.0, -30.0});
		SetEntPropVector(trigger_multiple112, Prop_Send, "m_vecMaxs", Float: {30.0, 30.0, 50.0});
		SetEntProp(trigger_multiple112, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple112, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple112, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple113 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple113, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple113, "wait", "0");
		DispatchSpawn(trigger_multiple113);
		ActivateEntity(trigger_multiple113);
		TeleportEntity(trigger_multiple113, block_pos113, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple113, "models/error.mdl");
		SetEntPropVector(trigger_multiple113, Prop_Send, "m_vecMins", Float: {-30.0, -30.0, -30.0});
		SetEntPropVector(trigger_multiple113, Prop_Send, "m_vecMaxs", Float: {30.0, 30.0, 50.0});
		SetEntProp(trigger_multiple113, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple113, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple113, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple114 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple114, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple114, "wait", "0");
		DispatchSpawn(trigger_multiple114);
		ActivateEntity(trigger_multiple114);
		TeleportEntity(trigger_multiple114, block_pos114, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple114, "models/error.mdl");
		SetEntPropVector(trigger_multiple114, Prop_Send, "m_vecMins", Float: {-30.0, -30.0, -30.0});
		SetEntPropVector(trigger_multiple114, Prop_Send, "m_vecMaxs", Float: {30.0, 30.0, 50.0});
		SetEntProp(trigger_multiple114, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple114, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple114, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple115 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple115, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple115, "wait", "0");
		DispatchSpawn(trigger_multiple115);
		ActivateEntity(trigger_multiple115);
		TeleportEntity(trigger_multiple115, block_pos115, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple115, "models/error.mdl");
		SetEntPropVector(trigger_multiple115, Prop_Send, "m_vecMins", Float: {-30.0, -30.0, -30.0});
		SetEntPropVector(trigger_multiple115, Prop_Send, "m_vecMaxs", Float: {30.0, 30.0, 50.0});
		SetEntProp(trigger_multiple115, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple115, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple115, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple116 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple116, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple116, "wait", "0");
		DispatchSpawn(trigger_multiple116);
		ActivateEntity(trigger_multiple116);
		TeleportEntity(trigger_multiple116, block_pos116, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple116, "models/error.mdl");
		SetEntPropVector(trigger_multiple116, Prop_Send, "m_vecMins", Float: {-30.0, -30.0, -30.0});
		SetEntPropVector(trigger_multiple116, Prop_Send, "m_vecMaxs", Float: {30.0, 30.0, 50.0});
		SetEntProp(trigger_multiple116, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple116, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple116, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple117 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple117, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple117, "wait", "0");
		DispatchSpawn(trigger_multiple117);
		ActivateEntity(trigger_multiple117);
		TeleportEntity(trigger_multiple117, block_pos117, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple117, "models/error.mdl");
		SetEntPropVector(trigger_multiple117, Prop_Send, "m_vecMins", Float: {-30.0, -30.0, -30.0});
		SetEntPropVector(trigger_multiple117, Prop_Send, "m_vecMaxs", Float: {30.0, 30.0, 50.0});
		SetEntProp(trigger_multiple117, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple117, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple117, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple118 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple118, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple118, "wait", "0");
		DispatchSpawn(trigger_multiple118);
		ActivateEntity(trigger_multiple118);
		TeleportEntity(trigger_multiple118, block_pos118, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple118, "models/error.mdl");
		SetEntPropVector(trigger_multiple118, Prop_Send, "m_vecMins", Float: {-30.0, -30.0, -30.0});
		SetEntPropVector(trigger_multiple118, Prop_Send, "m_vecMaxs", Float: {30.0, 30.0, 50.0});
		SetEntProp(trigger_multiple118, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple118, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple118, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple119 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple119, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple119, "wait", "0");
		DispatchSpawn(trigger_multiple119);
		ActivateEntity(trigger_multiple119);
		TeleportEntity(trigger_multiple119, block_pos119, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple119, "models/error.mdl");
		SetEntPropVector(trigger_multiple119, Prop_Send, "m_vecMins", Float: {-30.0, -30.0, -30.0});
		SetEntPropVector(trigger_multiple119, Prop_Send, "m_vecMaxs", Float: {30.0, 30.0, 50.0});
		SetEntProp(trigger_multiple119, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple119, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple119, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple120 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple120, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple120, "wait", "0");
		DispatchSpawn(trigger_multiple120);
		ActivateEntity(trigger_multiple120);
		TeleportEntity(trigger_multiple120, block_pos120, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple120, "models/error.mdl");
		SetEntPropVector(trigger_multiple120, Prop_Send, "m_vecMins", Float: {-30.0, -30.0, -30.0});
		SetEntPropVector(trigger_multiple120, Prop_Send, "m_vecMaxs", Float: {30.0, 30.0, 50.0});
		SetEntProp(trigger_multiple120, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple120, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple120, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple121 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple121, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple121, "wait", "0");
		DispatchSpawn(trigger_multiple121);
		ActivateEntity(trigger_multiple121);
		TeleportEntity(trigger_multiple121, block_pos121, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple121, "models/error.mdl");
		SetEntPropVector(trigger_multiple121, Prop_Send, "m_vecMins", Float: {-30.0, -30.0, -30.0});
		SetEntPropVector(trigger_multiple121, Prop_Send, "m_vecMaxs", Float: {30.0, 30.0, 50.0});
		SetEntProp(trigger_multiple121, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple121, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple121, "OnEndTouch", OnEndTouch);		
		
		new trigger_multiple27 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple27, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple27, "wait", "0");
		DispatchSpawn(trigger_multiple27);
		ActivateEntity(trigger_multiple27);
		TeleportEntity(trigger_multiple27, block_pos27, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple27, "models/error.mdl");
		SetEntPropVector(trigger_multiple27, Prop_Send, "m_vecMins", Float: {-40.0, -40.0, -50.0});
		SetEntPropVector(trigger_multiple27, Prop_Send, "m_vecMaxs", Float: {40.0, 40.0, 50.0});
		SetEntProp(trigger_multiple27, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple27, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple27, "OnEndTouch", OnEndTouch);
	
		new trigger_multiple28 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple28, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple28, "wait", "0");
		DispatchSpawn(trigger_multiple28);
		ActivateEntity(trigger_multiple28);
		TeleportEntity(trigger_multiple28, block_pos28, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple28, "models/error.mdl");
		SetEntPropVector(trigger_multiple28, Prop_Send, "m_vecMins", Float: {-25.0, -35.0, -40.0});
		SetEntPropVector(trigger_multiple28, Prop_Send, "m_vecMaxs", Float: {25.0, 25.0, 50.0});
		SetEntProp(trigger_multiple28, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple28, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple28, "OnEndTouch", OnEndTouch);
	}
	else if(StrContains(gMapName, "smalltown04", false) != -1)
	{
		new trigger_multiple30 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple30, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple30, "wait", "0");
		DispatchSpawn(trigger_multiple30);
		ActivateEntity(trigger_multiple30);
		TeleportEntity(trigger_multiple30, block_pos30, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple30, "models/error.mdl");
		SetEntPropVector(trigger_multiple30, Prop_Send, "m_vecMins", Float: {-40.0, -40.0, -50.0});
		SetEntPropVector(trigger_multiple30, Prop_Send, "m_vecMaxs", Float: {40.0, 40.0, 50.0});
		SetEntProp(trigger_multiple30, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple30, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple30, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple31 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple31, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple31, "wait", "0");
		DispatchSpawn(trigger_multiple31);
		ActivateEntity(trigger_multiple31);
		TeleportEntity(trigger_multiple31, block_pos31, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple31, "models/error.mdl");
		SetEntPropVector(trigger_multiple31, Prop_Send, "m_vecMins", Float: {-40.0, -40.0, -50.0});
		SetEntPropVector(trigger_multiple31, Prop_Send, "m_vecMaxs", Float: {40.0, 40.0, 50.0});
		SetEntProp(trigger_multiple31, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple31, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple31, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple32 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple32, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple32, "wait", "0");
		DispatchSpawn(trigger_multiple32);
		ActivateEntity(trigger_multiple32);
		TeleportEntity(trigger_multiple32, block_pos32, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple32, "models/error.mdl");
		SetEntPropVector(trigger_multiple32, Prop_Send, "m_vecMins", Float: {-40.0, -40.0, -50.0});
		SetEntPropVector(trigger_multiple32, Prop_Send, "m_vecMaxs", Float: {40.0, 40.0, 50.0});
		SetEntProp(trigger_multiple32, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple32, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple32, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple33 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple33, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple33, "wait", "0");
		DispatchSpawn(trigger_multiple33);
		ActivateEntity(trigger_multiple33);
		TeleportEntity(trigger_multiple33, block_pos33, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple33, "models/error.mdl");
		SetEntPropVector(trigger_multiple33, Prop_Send, "m_vecMins", Float: {-40.0, -40.0, -50.0});
		SetEntPropVector(trigger_multiple33, Prop_Send, "m_vecMaxs", Float: {40.0, 40.0, 50.0});
		SetEntProp(trigger_multiple33, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple33, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple33, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple122 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple122, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple122, "wait", "0");
		DispatchSpawn(trigger_multiple122);
		ActivateEntity(trigger_multiple122);
		TeleportEntity(trigger_multiple122, block_pos122, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple122, "models/error.mdl");
		SetEntPropVector(trigger_multiple122, Prop_Send, "m_vecMins", Float: {-25.0, -25.0, -25.0});
		SetEntPropVector(trigger_multiple122, Prop_Send, "m_vecMaxs", Float: {25.0, 25.0, 60.0});
		SetEntProp(trigger_multiple122, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple122, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple122, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple123 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple123, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple123, "wait", "0");
		DispatchSpawn(trigger_multiple123);
		ActivateEntity(trigger_multiple123);
		TeleportEntity(trigger_multiple123, block_pos123, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple123, "models/error.mdl");
		SetEntPropVector(trigger_multiple123, Prop_Send, "m_vecMins", Float: {-25.0, -25.0, -25.0});
		SetEntPropVector(trigger_multiple123, Prop_Send, "m_vecMaxs", Float: {25.0, 25.0, 60.0});
		SetEntProp(trigger_multiple123, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple123, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple123, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple124 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple124, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple124, "wait", "0");
		DispatchSpawn(trigger_multiple124);
		ActivateEntity(trigger_multiple124);
		TeleportEntity(trigger_multiple124, block_pos124, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple124, "models/error.mdl");
		SetEntPropVector(trigger_multiple124, Prop_Send, "m_vecMins", Float: {-25.0, -25.0, -25.0});
		SetEntPropVector(trigger_multiple124, Prop_Send, "m_vecMaxs", Float: {25.0, 25.0, 40.0});
		SetEntProp(trigger_multiple124, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple124, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple124, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple125 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple125, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple125, "wait", "0");
		DispatchSpawn(trigger_multiple125);
		ActivateEntity(trigger_multiple125);
		TeleportEntity(trigger_multiple125, block_pos125, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple125, "models/error.mdl");
		SetEntPropVector(trigger_multiple125, Prop_Send, "m_vecMins", Float: {-25.0, -25.0, -25.0});
		SetEntPropVector(trigger_multiple125, Prop_Send, "m_vecMaxs", Float: {25.0, 25.0, 40.0});
		SetEntProp(trigger_multiple125, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple125, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple125, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple126 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple126, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple126, "wait", "0");
		DispatchSpawn(trigger_multiple126);
		ActivateEntity(trigger_multiple126);
		TeleportEntity(trigger_multiple126, block_pos126, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple126, "models/error.mdl");
		SetEntPropVector(trigger_multiple126, Prop_Send, "m_vecMins", Float: {-25.0, -25.0, -25.0});
		SetEntPropVector(trigger_multiple126, Prop_Send, "m_vecMaxs", Float: {25.0, 25.0, 40.0});
		SetEntProp(trigger_multiple126, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple126, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple126, "OnEndTouch", OnEndTouch);
	}
	else if(StrContains(gMapName, "smalltown05", false) != -1)
	{
		new trigger_multiple29 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple29, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple29, "wait", "0");
		DispatchSpawn(trigger_multiple29);
		ActivateEntity(trigger_multiple29);
		TeleportEntity(trigger_multiple29, block_pos29, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple29, "models/error.mdl");
		SetEntPropVector(trigger_multiple29, Prop_Send, "m_vecMins", Float: {-40.0, -40.0, -50.0});
		SetEntPropVector(trigger_multiple29, Prop_Send, "m_vecMaxs", Float: {40.0, 40.0, 50.0});
		SetEntProp(trigger_multiple29, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple29, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple29, "OnEndTouch", OnEndTouch);
	}
	else if(StrContains(gMapName, "garage01", false) != -1)
	{
		new trigger_multiple128 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple128, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple128, "wait", "0");
		DispatchSpawn(trigger_multiple128);
		ActivateEntity(trigger_multiple128);
		TeleportEntity(trigger_multiple128, block_pos128, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple128, "models/error.mdl");
		SetEntPropVector(trigger_multiple128, Prop_Send, "m_vecMins", Float: {-40.0, -40.0, -50.0});
		SetEntPropVector(trigger_multiple128, Prop_Send, "m_vecMaxs", Float: {40.0, 40.0, 50.0});
		SetEntProp(trigger_multiple128, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple128, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple128, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple129 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple129, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple129, "wait", "0");
		DispatchSpawn(trigger_multiple129);
		ActivateEntity(trigger_multiple129);
		TeleportEntity(trigger_multiple129, block_pos129, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple129, "models/error.mdl");
		SetEntPropVector(trigger_multiple129, Prop_Send, "m_vecMins", Float: {-40.0, -40.0, -50.0});
		SetEntPropVector(trigger_multiple129, Prop_Send, "m_vecMaxs", Float: {40.0, 40.0, 50.0});
		SetEntProp(trigger_multiple129, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple129, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple129, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple130 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple130, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple130, "wait", "0");
		DispatchSpawn(trigger_multiple130);
		ActivateEntity(trigger_multiple130);
		TeleportEntity(trigger_multiple130, block_pos130, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple130, "models/error.mdl");
		SetEntPropVector(trigger_multiple130, Prop_Send, "m_vecMins", Float: {-40.0, -40.0, -100.0});
		SetEntPropVector(trigger_multiple130, Prop_Send, "m_vecMaxs", Float: {40.0, 40.0, 50.0});
		SetEntProp(trigger_multiple130, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple130, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple130, "OnEndTouch", OnEndTouch);
	}
	else if(StrContains(gMapName, "garage02", false) != -1)
	{
		new trigger_multiple131 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple131, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple131, "wait", "0");
		DispatchSpawn(trigger_multiple131);
		ActivateEntity(trigger_multiple131);
		TeleportEntity(trigger_multiple131, block_pos131, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple131, "models/error.mdl");
		SetEntPropVector(trigger_multiple131, Prop_Send, "m_vecMins", Float: {-40.0, -40.0, -70.0});
		SetEntPropVector(trigger_multiple131, Prop_Send, "m_vecMaxs", Float: {40.0, 40.0, 50.0});
		SetEntProp(trigger_multiple131, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple131, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple131, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple132 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple132, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple132, "wait", "0");
		DispatchSpawn(trigger_multiple132);
		ActivateEntity(trigger_multiple132);
		TeleportEntity(trigger_multiple132, block_pos132, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple132, "models/error.mdl");
		SetEntPropVector(trigger_multiple132, Prop_Send, "m_vecMins", Float: {-40.0, -40.0, -70.0});
		SetEntPropVector(trigger_multiple132, Prop_Send, "m_vecMaxs", Float: {40.0, 40.0, 50.0});
		SetEntProp(trigger_multiple132, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple132, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple132, "OnEndTouch", OnEndTouch);
	}
	else if(StrContains(gMapName, "river01", false) != -1)
	{
		new trigger_multiple133 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple133, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple133, "wait", "0");
		DispatchSpawn(trigger_multiple133);
		ActivateEntity(trigger_multiple133);
		TeleportEntity(trigger_multiple133, block_pos133, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple133, "models/error.mdl");
		SetEntPropVector(trigger_multiple133, Prop_Send, "m_vecMins", Float: {-40.0, -40.0, -70.0});
		SetEntPropVector(trigger_multiple133, Prop_Send, "m_vecMaxs", Float: {40.0, 40.0, 50.0});
		SetEntProp(trigger_multiple133, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple133, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple133, "OnEndTouch", OnEndTouch);
	}
	else if(StrContains(gMapName, "river02", false) != -1)
	{
		new trigger_multiple134 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple134, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple134, "wait", "0");
		DispatchSpawn(trigger_multiple134);
		ActivateEntity(trigger_multiple134);
		TeleportEntity(trigger_multiple134, block_pos134, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple134, "models/error.mdl");
		SetEntPropVector(trigger_multiple134, Prop_Send, "m_vecMins", Float: {-40.0, -40.0, -70.0});
		SetEntPropVector(trigger_multiple134, Prop_Send, "m_vecMaxs", Float: {40.0, 40.0, 50.0});
		SetEntProp(trigger_multiple134, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple134, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple134, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple135 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple135, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple135, "wait", "0");
		DispatchSpawn(trigger_multiple135);
		ActivateEntity(trigger_multiple135);
		TeleportEntity(trigger_multiple135, block_pos135, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple135, "models/error.mdl");
		SetEntPropVector(trigger_multiple135, Prop_Send, "m_vecMins", Float: {-40.0, -40.0, -40.0});
		SetEntPropVector(trigger_multiple135, Prop_Send, "m_vecMaxs", Float: {40.0, 40.0, 40.0});
		SetEntProp(trigger_multiple135, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple135, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple135, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple136 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple136, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple136, "wait", "0");
		DispatchSpawn(trigger_multiple136);
		ActivateEntity(trigger_multiple136);
		TeleportEntity(trigger_multiple136, block_pos136, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple136, "models/error.mdl");
		SetEntPropVector(trigger_multiple136, Prop_Send, "m_vecMins", Float: {-40.0, -40.0, -70.0});
		SetEntPropVector(trigger_multiple136, Prop_Send, "m_vecMaxs", Float: {40.0, 40.0, 50.0});
		SetEntProp(trigger_multiple136, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple136, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple136, "OnEndTouch", OnEndTouch);
		
		new trigger_multiple137 = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_multiple137, "spawnflags", "1");
		DispatchKeyValue(trigger_multiple137, "wait", "0");
		DispatchSpawn(trigger_multiple137);
		ActivateEntity(trigger_multiple137);
		TeleportEntity(trigger_multiple137, block_pos137, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_multiple137, "models/error.mdl");
		SetEntPropVector(trigger_multiple137, Prop_Send, "m_vecMins", Float: {-40.0, -40.0, -40.0});
		SetEntPropVector(trigger_multiple137, Prop_Send, "m_vecMaxs", Float: {40.0, 40.0, 40.0});
		SetEntProp(trigger_multiple137, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_multiple137, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple137, "OnEndTouch", OnEndTouch);
	}
}

public OnStartTouch(const String:output[], ent, client, Float:delay)
{
	if (client) SetEntProp(client, Prop_Data, "m_CollisionGroup", 2);
	if (GetConVarInt(ShowNoBlock)) PrintToChat(client, "Start Touch!");
}

public OnEndTouch(const String:output[], ent, client, Float:delay)
{
	if (client && IsClientInGame(client)) SetEntProp(client, Prop_Data, "m_CollisionGroup", 6);
	if (GetConVarInt(ShowNoBlock)) PrintToChat(client, "End Touch!");
}